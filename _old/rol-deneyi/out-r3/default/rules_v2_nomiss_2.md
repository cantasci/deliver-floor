```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import jakarta.inject.Inject;
import org.traccar.WireProtocolRoot;
import org.traccar.ChainBuilder;
import org.traccar.EndpointListener;
import org.traccar.config.Config;
import org.traccar.handler.GlyphBoundaryFrameSplitter;

public class R16hProtocol extends WireProtocolRoot {

    @Inject
    public R16hProtocol(Config config) {
        addServer(new EndpointListener(config, getName(), true) {
            @Override
            protected void installChainHandlers(ChainBuilder pipeline, Config config) {
                pipeline.addLast(new GlyphBoundaryFrameSplitter(1024, "$"));
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
import org.traccar.helper.DateBuilder;
import org.traccar.helper.FieldCursor;
import org.traccar.helper.PatternBuilder;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;
import org.traccar.session.DeviceSession;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN = new PatternBuilder()
            .text("@GPSD,")
            .number("(d+),")
            .expression("([RS]),")
            .number("(dddd)(dd)(dd),")
            .number("(dd)(dd)(dd),")
            .number("(d+.d+),")
            .expression("([NS]),")
            .number("(d+.d+),")
            .expression("([EW]),")
            .number("(d+.?d*),")
            .number("(d+.?d*),")
            .number("(-?d+),")
            .number("(d+),")
            .expression("([LR]),")
            .expression("(w*)")
            .any()
            .compile();

    private String decodeAlarm(String value) {
        return switch (value) {
            case "SOS" -> Position.ALARM_SOS;
            case "LB" -> Position.ALARM_LOW_BATTERY;
            case "RM" -> Position.ALARM_REMOVING;
            case "FL" -> Position.ALARM_FALL_DOWN;
            case "GF" -> Position.ALARM_GEOFENCE;
            default -> null;
        };
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = ((String) msg).trim();

        if (sentence.startsWith("@LINK,")) {
            resolveUnitSession(channel, remoteAddress, sentence.substring(6).trim());
            return null;
        }

        FieldCursor parser = new FieldCursor(PATTERN, sentence);
        if (!parser.matches()) {
            return null;
        }

        DeviceSession deviceSession = resolveUnitSession(channel, remoteAddress, parser.next());
        if (deviceSession == null) {
            return null;
        }

        Position position = new Position(wireName());
        position.setDeviceId(deviceSession.getDeviceId());

        if (parser.next().equals("S")) {
            position.set(Position.KEY_ARCHIVE, true);
        }

        DateBuilder dateBuilder = new DateBuilder()
                .setDate(parser.nextInt(), parser.nextInt(), parser.nextInt())
                .setTime(parser.nextInt(), parser.nextInt(), parser.nextInt());
        position.setTime(dateBuilder.getDate());

        double latitude = parser.nextDouble();
        position.setLatitude(parser.next().equals("S") ? -latitude : latitude);

        double longitude = parser.nextDouble();
        position.setLongitude(parser.next().equals("W") ? -longitude : longitude);

        position.setValid(true);
        position.setSpeed(UnitsConverter.nauticalFromMetricSpeed(parser.nextDouble()));
        position.setCourse(parser.nextDouble());
        position.setAltitude(parser.nextInt());

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
        position.set(Position.KEY_LOCK, parser.next().equals("L"));

        String alarm = parser.next();
        if (alarm != null && !alarm.isEmpty()) {
            position.set(Position.KEY_ALARM, decodeAlarm(alarm));
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

class R16hProtocolDecoderTest extends WireDecoderHarness {

    @Test
    void testDecode() throws Exception {

        var decoder = wireUp(new R16hProtocolDecoder(null));

        assertNoOutput(decoder, asciiFrame(
                "@LINK,356823031235028"));

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,S,20260520,000233,01.34587,S,103.71993,W,12,90,-5,68,R,SOS"));

    }

}
```
