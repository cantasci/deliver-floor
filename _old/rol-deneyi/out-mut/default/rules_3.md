```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import jakarta.inject.Inject;
import org.traccar.PipelineBuilder;
import org.traccar.WireProtocolRoot;
import org.traccar.EndpointListener;
import org.traccar.config.Config;

public class R16hProtocol extends WireProtocolRoot {

    @Inject
    public R16hProtocol(Config config) {
        super(config);
        addServer(new EndpointListener(true, getName()) {
            @Override
            protected void installChainHandlers(PipelineBuilder pipeline) {
                pipeline.addLast(new CharacterDelimiterFrameDecoder(1024, '$'));
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
import org.traccar.Protocol;
import org.traccar.helper.DateBuilder;
import org.traccar.helper.Parser;
import org.traccar.helper.PatternBuilder;
import org.traccar.model.Position;
import org.traccar.session.DeviceSession;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN_LOGIN = new PatternBuilder()
            .text("@LINK,")
            .number("(d+)")
            .any()
            .compile();

    private static final Pattern PATTERN_POSITION = new PatternBuilder()
            .text("@GPSD,")
            .number("(d+),")                     // imei
            .expression("([RS]),")               // archive
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
            .expression("([LR]),")               // lock
            .expression("([^,]*)")               // alarm
            .compile();

    private String decodeAlarm(String value) {
        switch (value) {
            case "SOS":
                return Position.ALARM_SOS;
            case "LB":
                return Position.ALARM_LOW_BATTERY;
            case "TP":
                return Position.ALARM_TAMPERING;
            case "GF":
                return Position.ALARM_GEOFENCE;
            default:
                return Position.ALARM_GENERAL;
        }
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = ((String) msg).trim();

        if (sentence.startsWith("@LINK")) {
            Parser parser = new Parser(PATTERN_LOGIN, sentence);
            if (!parser.matches()) {
                return null;
            }
            getDeviceSession(channel, remoteAddress, parser.next());
            return null;
        }

        Parser parser = new Parser(PATTERN_POSITION, sentence);
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

        position.setValid(true);
        position.setLatitude(parser.nextCoordinate(Parser.CoordinateFormat.DEG_HEM));
        position.setLongitude(parser.nextCoordinate(Parser.CoordinateFormat.DEG_HEM));
        position.setSpeed(UnitsConverter.knotsFromKph(parser.nextInt()));
        position.setCourse(parser.nextInt());
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
import org.traccar.ProtocolTest;

public class R16hProtocolDecoderTest extends ProtocolTest {

    @Test
    public void testDecode() throws Exception {

        var decoder = wireUp(new R16hProtocolDecoder(null));

        verifyNull(decoder, text(
                "@LINK,356823031235028"));

        verifyPosition(decoder, text(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

        verifyPosition(decoder, text(
                "@GPSD,356823031235028,S,20260520,000233,01.34587,S,103.71993,W,42,90,-12,65,R,SOS"));

    }

}
```
