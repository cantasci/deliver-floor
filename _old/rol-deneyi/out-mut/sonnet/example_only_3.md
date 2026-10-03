```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.PipelineBuilder;
import org.traccar.Protocol;
import org.traccar.TrackerServer;
import org.traccar.config.Config;

public class R16hProtocol extends Protocol {

    public R16hProtocol(Config config) {
        addServer(new TrackerServer(config, getName(), true) {
            @Override
            protected void addProtocolHandlers(PipelineBuilder pipeline, Config config) {
                pipeline.addLast(new DelimiterBasedFrameDecoder(1024, Unpooled.wrappedBuffer(new byte[]{'$'})));
                pipeline.addLast(new StringDecoder());
                pipeline.addLast(new StringEncoder());
                pipeline.addLast(new R16hProtocolDecoder(R16hProtocol.this));
            }
        });
    }

}
```

```java
// R16hProtocolDecoder.java
package org.traccar.protocol;

import io.netty.channel.Channel;
import org.traccar.AbstractWireDecoder;
import org.traccar.Protocol;
import org.traccar.helper.FieldCursor;
import org.traccar.helper.GrammarComposer;
import org.traccar.model.Position;
import org.traccar.session.UnitSession;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN_LOGIN = new GrammarComposer()
            .text("@LINK,")
            .number("(d+)")                      // imei
            .compile();

    private static final Pattern PATTERN_POSITION = new GrammarComposer()
            .text("@GPSD,")
            .number("(d+),")                     // imei
            .expression("([RS]),")                // record type
            .number("(dddd)(dd)(dd),")           // date (yyyymmdd)
            .number("(dd)(dd)(dd),")             // time (hhmmss)
            .number("(d+.d+),")                  // latitude
            .expression("([NS]),")
            .number("(d+.d+),")                  // longitude
            .expression("([EW]),")
            .number("(d+),")                     // speed
            .number("(d+),")                     // course
            .number("(-?d+),")                   // altitude
            .number("(d+),")                     // battery
            .expression("([LR]),")                // strap lock
            .expression("(.*)")                   // alarm
            .compile();

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;

        if (sentence.startsWith("@LINK,")) {

            FieldCursor parser = new FieldCursor(PATTERN_LOGIN, sentence);
            if (!parser.matches()) {
                return null;
            }

            resolveUnitSession(channel, remoteAddress, parser.next());

            return null;

        } else if (sentence.startsWith("@GPSD,")) {

            FieldCursor parser = new FieldCursor(PATTERN_POSITION, sentence);
            if (!parser.matches()) {
                return null;
            }

            Position position = new Position(wireName());

            UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, parser.next());
            if (deviceSession == null) {
                return null;
            }
            position.setDeviceId(deviceSession.getDeviceId());

            position.setOutdated(parser.next().equals("S"));

            position.setTime(parser.nextDateTime());

            position.setValid(true);

            double latitude = parser.nextDouble();
            if (parser.next().equals("S")) {
                latitude = -latitude;
            }
            position.setLatitude(latitude);

            double longitude = parser.nextDouble();
            if (parser.next().equals("W")) {
                longitude = -longitude;
            }
            position.setLongitude(longitude);

            position.setSpeed(parser.nextDouble(0));
            position.setCourse(parser.nextDouble(0));
            position.setAltitude(parser.nextDouble(0));

            position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
            position.set("lock", parser.next().equals("L"));

            String alarm = parser.next();
            if (!alarm.isEmpty()) {
                position.set(Position.KEY_ALARM, alarm);
            }

            return position;

        }

        return null;
    }

}
```

```java
// R16hProtocolDecoderTest.java
package org.traccar.protocol;

import org.junit.jupiter.api.Test;
import org.traccar.WireDecoderHarness;

public class R16hProtocolDecoderTest extends WireDecoderHarness {

    @Test
    public void testDecode() throws Exception {

        var decoder = wireUp(new R16hProtocolDecoder(null));

        verifyNull(decoder, asciiFrame(
                "@LINK,356823031235028"));

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

    }

}
```
