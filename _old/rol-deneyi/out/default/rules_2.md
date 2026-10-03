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
        addServer(new TrackerServer(config, getName(), false) {
            @Override
            protected void addProtocolHandlers(PipelineBuilder pipeline, Config config) {
                pipeline.addLast(new DelimiterBasedFrameDecoder(
                        1024, Unpooled.wrappedBuffer(new byte[] {'$'})));
                pipeline.addLast(new StringDecoder(StandardCharsets.US_ASCII));
                pipeline.addLast(new StringEncoder(StandardCharsets.US_ASCII));
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

    private static final Pattern PATTERN = new PatternBuilder()
            .text("@GPSD,")
            .number("(d+),")                     // imei
            .expression("([RS]),")               // archive
            .number("(dddd)(dd)(dd),")           // date (yyyymmdd)
            .number("(dd)(dd)(dd),")             // time (hhmmss)
            .number("(d+.d+),")                  // latitude
            .expression("([NS]),")               // hemisphere
            .number("(d+.d+),")                  // longitude
            .expression("([EW]),")               // hemisphere
            .number("(d+),")                     // speed
            .number("(d+),")                     // course
            .number("(-?d+),")                   // altitude
            .number("(d+),")                     // battery
            .expression("([LR]),")               // lock
            .expression("(\\w*)")                // alarm
            .compile();

    private String decodeAlarm(String value) {
        switch (value) {
            case "SOS":
                return Position.ALARM_SOS;
            case "LP":
                return Position.ALARM_LOW_POWER;
            case "TP":
                return Position.ALARM_TAMPERING;
            default:
                return null;
        }
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = ((String) msg).trim();

        if (sentence.startsWith("@LINK,")) {
            getDeviceSession(channel, remoteAddress, sentence.substring("@LINK,".length()));
            return null;
        }

        Parser parser = new Parser(PATTERN, sentence);
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

        position.setValid(true);
        position.setSpeed(UnitsConverter.knotsFromKph(parser.nextInt()));
        position.setCourse(parser.nextInt());
        position.setAltitude(parser.nextInt());

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
        position.set(Position.KEY_LOCK, parser.next().equals("L"));
        position.set(Position.KEY_ALARM, decodeAlarm(parser.next()));

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
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"),
                position("2026-05-20 00:01:33.000", true, 1.34587, 103.71993));

        verifyPosition(decoder, text(
                "@GPSD,356823031235028,S,20260520,000233,01.34587,S,103.71993,W,42,90,-15,68,R,SOS"));

    }

}
```
