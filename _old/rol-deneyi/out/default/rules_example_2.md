```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.BaseProtocol;
import org.traccar.PipelineBuilder;
import org.traccar.TrackerServer;
import org.traccar.config.Config;

public class R16hProtocol extends BaseProtocol {

    public R16hProtocol() {
        addServer(new TrackerServer(false, getName()) {
            @Override
            protected void addProtocolHandlers(PipelineBuilder pipeline, Config config) {
                pipeline.addLast(new DelimiterBasedFrameDecoder(1024, Unpooled.wrappedBuffer(new byte[] {'$'})));
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
import org.traccar.BaseProtocolDecoder;
import org.traccar.Protocol;
import org.traccar.helper.Parser;
import org.traccar.helper.PatternBuilder;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;
import org.traccar.session.DeviceSession;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends BaseProtocolDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN_LINK = new PatternBuilder()
            .text("@LINK,")
            .number("(d+)")                      // imei
            .compile();

    private static final Pattern PATTERN_POSITION = new PatternBuilder()
            .text("@GPSD,")
            .number("(d+),")                     // imei
            .expression("([RS]),")               // archive
            .number("(dddd)(dd)(dd),")           // date (yyyymmdd)
            .number("(dd)(dd)(dd),")             // time (hhmmss)
            .number("(d+.d+),([NS]),")           // latitude
            .number("(d+.d+),([EW]),")           // longitude
            .number("(d+.?d*),")                 // speed
            .number("(d+.?d*),")                 // course
            .number("(-?d+),")                   // altitude
            .number("(d+),")                     // battery
            .expression("([LR]),")               // lock
            .expression("([^,]*)")               // alarm
            .compile();

    private String decodeAlarm(String value) {
        return switch (value) {
            case "SOS" -> Position.ALARM_SOS;
            case "LOWPOWER" -> Position.ALARM_LOW_BATTERY;
            case "OPEN" -> Position.ALARM_TAMPERING;
            case "GEO" -> Position.ALARM_GEOFENCE;
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

        Position position = new Position(getProtocolName());

        DeviceSession deviceSession = getDeviceSession(channel, remoteAddress, parser.next());
        if (deviceSession == null) {
            return null;
        }
        position.setDeviceId(deviceSession.getDeviceId());

        position.set(Position.KEY_ARCHIVE, parser.next().equals("S") ? true : null);

        position.setTime(parser.nextDateTime(Parser.DateTimeFormat.YMD_HMS));

        position.setValid(true);
        position.setLatitude(parser.nextCoordinate(Parser.CoordinateFormat.DEG_HEM));
        position.setLongitude(parser.nextCoordinate(Parser.CoordinateFormat.DEG_HEM));
        position.setSpeed(UnitsConverter.knotsFromKph(parser.nextDouble(0)));
        position.setCourse(parser.nextDouble(0));
        position.setAltitude(parser.nextInt(0));

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt(0));
        position.set(Position.KEY_BLOCKED, parser.next().equals("L"));

        String alarm = parser.next();
        if (alarm != null && !alarm.isEmpty()) {
            String decoded = decodeAlarm(alarm);
            if (decoded != null) {
                position.set(Position.KEY_ALARM, decoded);
            } else {
                position.set(Position.KEY_EVENT, alarm);
            }
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
                "@GPSD,356823031235028,S,20260520,000233,01.34587,S,103.71993,W,42,90,-15,68,R,SOS"));

    }

}
```
