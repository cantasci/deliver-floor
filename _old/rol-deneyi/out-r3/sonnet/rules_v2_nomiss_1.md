```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.BaseFrameDecoder;
import org.traccar.EndpointListener;
import org.traccar.GlyphBoundaryFrameSplitter;
import org.traccar.PipelineBuilder;
import org.traccar.WireProtocolRoot;
import org.traccar.config.Config;

public class R16hProtocol extends WireProtocolRoot {

    public R16hProtocol() {
        addServer(new EndpointListener(this, getName(), true) {
            @Override
            protected void installChainHandlers(PipelineBuilder pipeline, Config config) {
                pipeline.addLast(new GlyphBoundaryFrameSplitter((byte) '$'));
                pipeline.addLast(new StringEncoder());
                pipeline.addLast(new StringDecoder());
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
import org.traccar.WireProtocolRoot;
import org.traccar.helper.DateBuilder;
import org.traccar.helper.FieldCursor;
import org.traccar.helper.PatternBuilder;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;
import org.traccar.session.UnitSession;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(WireProtocolRoot protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN_LOGIN = new PatternBuilder()
            .text("@LINK,")
            .number("(d+)")                     // imei
            .compile();

    private static final Pattern PATTERN_POSITION = new PatternBuilder()
            .text("@GPSD,")
            .number("(d+),")                    // imei
            .expression("([RS]),")              // type
            .number("(dddd)(dd)(dd),")          // date
            .number("(dd)(dd)(dd),")            // time
            .number("(dd.d+),([NS]),")          // latitude
            .number("(ddd.d+),([EW]),")         // longitude
            .number("(d+),")                    // speed
            .number("(d+),")                    // course
            .number("(-?d+),")                  // altitude
            .number("(d+),")                    // battery
            .expression("([LR]),")              // lock
            .expression("([^,]*)")              // alarm
            .compile();

    @Override
    protected Object decode(Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;

        if (sentence.startsWith("@LINK")) {

            FieldCursor parser = new FieldCursor(PATTERN_LOGIN, sentence);
            if (parser.matches()) {
                String imei = parser.next();
                resolveUnitSession(channel, remoteAddress, imei);
            }
            return null;

        } else if (sentence.startsWith("@GPSD")) {

            FieldCursor parser = new FieldCursor(PATTERN_POSITION, sentence);
            if (!parser.matches()) {
                return null;
            }

            String imei = parser.next();
            UnitSession unitSession = resolveUnitSession(channel, remoteAddress, imei);
            if (unitSession == null) {
                return null;
            }

            Position position = new Position(wireName());
            position.setDeviceId(unitSession.getDeviceId());

            position.set(Position.KEY_ARCHIVE, parser.next().equals("S"));

            DateBuilder dateBuilder = new DateBuilder()
                    .setDate(parser.nextInt(), parser.nextInt(), parser.nextInt())
                    .setTime(parser.nextInt(), parser.nextInt(), parser.nextInt());
            position.setTime(dateBuilder.getDate());

            position.setValid(true);
            position.setLatitude(parser.nextDouble());
            if (parser.next().equals("S")) {
                position.setLatitude(-position.getLatitude());
            }
            position.setLongitude(parser.nextDouble());
            if (parser.next().equals("W")) {
                position.setLongitude(-position.getLongitude());
            }

            position.setSpeed(UnitsConverter.nauticalFromMetricSpeed(parser.nextDouble()));
            position.setCourse(parser.nextInt());
            position.setAltitude(parser.nextInt());

            position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
            position.set("lock", parser.next().equals("L"));

            String alarm = parser.next();
            if (alarm != null && !alarm.isEmpty()) {
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

class R16hProtocolDecoderTest extends WireDecoderHarness {

    @Test
    void testDecode() throws Exception {

        var decoder = wireUp(new R16hProtocolDecoder(new R16hProtocol()));

        assertNoOutput(decoder, asciiFrame(
                "@LINK,356823031235028"));

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

    }

}
```
