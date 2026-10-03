```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import jakarta.inject.Inject;
import org.traccar.BaseProtocol;
import org.traccar.PipelineBuilder;
import org.traccar.TrackerServer;
import org.traccar.config.Config;

import java.nio.charset.StandardCharsets;

public class R16hProtocol extends BaseProtocol {

    @Inject
    public R16hProtocol(Config config) {
        addServer(new TrackerServer(config, getName(), true) {
            @Override
            protected void addProtocolHandlers(PipelineBuilder pipeline, Config config) {
                pipeline.addLast(new DelimiterBasedFrameDecoder(
                        1024, Unpooled.copiedBuffer("$", StandardCharsets.US_ASCII)));
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
import org.traccar.BaseProtocolDecoder;
import org.traccar.session.DeviceSession;
import org.traccar.Protocol;
import org.traccar.helper.Parser;
import org.traccar.helper.PatternBuilder;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends BaseProtocolDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN_LINK = new PatternBuilder()
            .text("@LINK,")
            .number("(d+)")
            .any()
            .compile();

    private static final Pattern PATTERN_POSITION = new PatternBuilder()
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
            .number("(-?d+.?d*),")
            .number("(d+),")
            .expression("([LR]),")
            .expression("([^,]*)")
            .any()
            .compile();

    private String decodeAlarm(String value) {
        return switch (value) {
            case "SOS" -> Position.ALARM_SOS;
            case "LB" -> Position.ALARM_LOW_BATTERY;
            case "PO" -> Position.ALARM_POWER_OFF;
            case "FL" -> Position.ALARM_FALL_DOWN;
            case "GF" -> Position.ALARM_GEOFENCE;
            case "TP" -> Position.ALARM_TAMPERING;
            default -> null;
        };
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = ((String) msg).trim();

        Parser parser = new Parser(PATTERN_LINK, sentence);
        if (parser.matches()) {
            getDeviceSession(channel, remoteAddress, parser.next());
            return null;
        }

        parser = new Parser(PATTERN_POSITION, sentence);
        if (!parser.matches()) {
            return null;
        }

        DeviceSession deviceSession = getDeviceSession(channel, remoteAddress, parser.next());
        if (deviceSession == null) {
            return null;
        }

        Position position = new Position(getProtocolName());
        position.setDeviceId(deviceSession.getDeviceId());

        if (parser.next().equals("S")) {
            position.set(Position.KEY_ARCHIVE, true);
        }

        position.setTime(parser.nextDateTime(Parser.DateTimeFormat.YMD_HMS));

        position.setValid(true);
        double latitude = parser.nextDouble();
        position.setLatitude(parser.next().equals("S") ? -latitude : latitude);
        double longitude = parser.nextDouble();
        position.setLongitude(parser.next().equals("W") ? -longitude : longitude);

        position.setSpeed(UnitsConverter.knotsFromKph(parser.nextDouble()));
        position.setCourse(parser.nextDouble());
        position.setAltitude(parser.nextDouble());

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
        position.set("strap", parser.next().equals("L"));

        String alarm = parser.next();
        if (alarm != null && !alarm.isEmpty()) {
            position.set(Position.KEY_ALARM, decodeAlarm(alarm));
            position.set("alarmCode", alarm);
        }

        return position;
    }

}
```

```java
// R16hProtocolDecoderTest.java
package org.traccar.protocol;

import org.junit.jupiter.api.Test;
import org.traccar.ProtocolTest;

public class R16hProtocolDecoderTest extends ProtocolTest {

    @Test
    public void testDecode() throws Exception {

        var decoder = inject(new R16hProtocolDecoder(null));

        verifyNull(decoder, text(
                "@LINK,356823031235028"));

        verifyPosition(decoder, text(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

        verifyPosition(decoder, text(
                "@GPSD,356823031235028,S,20260520,000233,01.34587,S,103.71993,W,45,270,-12,68,R,SOS"));

    }

}
```
