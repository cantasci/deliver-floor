```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import jakarta.inject.Inject;
import org.traccar.BaseProtocol;
import org.traccar.PipelineBuilder;
import org.traccar.TrackerServer;
import org.traccar.config.Config;

public class R16hProtocol extends BaseProtocol {

    @Inject
    public R16hProtocol(Config config) {
        addServer(new TrackerServer(config, getName(), true) {
            @Override
            protected void addProtocolHandlers(PipelineBuilder pipeline, Config config) {
                pipeline.addLast(new R16hFrameDecoder());
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
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;
import org.traccar.session.UnitSession;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN_LINK = new GrammarComposer()
            .text("@LINK,")
            .number("(d+)")                       // imei
            .any()
            .compile();

    private static final Pattern PATTERN_POSITION = new GrammarComposer()
            .text("@GPSD,")
            .number("(d+),")                      // imei
            .expression("([RS]),")                // archive
            .number("(dddd)(dd)(dd),")            // date (yyyymmdd)
            .number("(dd)(dd)(dd),")              // time (hhmmss)
            .number("(d+.d+),")                   // latitude
            .expression("([NS]),")
            .number("(d+.d+),")                   // longitude
            .expression("([EW]),")
            .number("(d+.?d*),")                  // speed
            .number("(d+.?d*),")                  // course
            .number("(-?d+),")                    // altitude
            .number("(d+),")                      // battery
            .expression("([LR]),")                // lock
            .expression("(w*)")                   // alarm
            .compile();

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = ((String) msg).trim();

        FieldCursor linkParser = new FieldCursor(PATTERN_LINK, sentence);
        if (linkParser.matches()) {
            resolveUnitSession(channel, remoteAddress, linkParser.next());
            return null;
        }

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

        position.set(Position.KEY_ARCHIVE, parser.next().equals("S") ? true : null);

        position.setTime(parser.nextDateTime());
        position.setValid(true);

        double latitude = parser.nextDouble(0);
        if (parser.next().equals("S")) {
            latitude = -latitude;
        }
        position.setLatitude(latitude);

        double longitude = parser.nextDouble(0);
        if (parser.next().equals("W")) {
            longitude = -longitude;
        }
        position.setLongitude(longitude);

        position.setSpeed(UnitsConverter.knotsFromKph(parser.nextDouble(0)));
        position.setCourse(parser.nextDouble(0));
        position.setAltitude(parser.nextInt(0));

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt(0));
        position.set(Position.KEY_BLOCKED, parser.next().equals("L"));

        String alarm = parser.next();
        if (alarm != null && !alarm.isEmpty()) {
            position.set(Position.KEY_ALARM, alarm);
        }

        return position;
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

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,S,20260520,001200,01.34590,S,103.71995,W,42,270,-15,68,R,SOS"));

    }

}
```
