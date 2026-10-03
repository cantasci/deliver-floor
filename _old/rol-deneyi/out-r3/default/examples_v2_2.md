```java
// src/main/java/org/traccar/protocol/R16hProtocol.java
package org.traccar.protocol;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.WireProtocolRoot;
import org.traccar.HandlerChainAssembler;
import org.traccar.EndpointListener;
import org.traccar.config.Config;

import java.nio.charset.StandardCharsets;

import jakarta.inject.Inject;

public class R16hProtocol extends WireProtocolRoot {

    @Inject
    public R16hProtocol(Config config) {
        addServer(new EndpointListener(config, getName(), true) {
            @Override
            protected void installChainHandlers(HandlerChainAssembler pipeline, Config config) {
                pipeline.addLast(new DelimiterBasedFrameDecoder(
                        MAX_FRAME_LENGTH, Unpooled.wrappedBuffer(new byte[] {'$'})));
                pipeline.addLast(new StringEncoder(StandardCharsets.ISO_8859_1));
                pipeline.addLast(new StringDecoder(StandardCharsets.ISO_8859_1));
                pipeline.addLast(new R16hProtocolDecoder(R16hProtocol.this));
            }
        });
    }

}
```

```java
// src/main/java/org/traccar/protocol/R16hProtocolDecoder.java
package org.traccar.protocol;

import io.netty.channel.Channel;
import org.traccar.AbstractWireDecoder;
import org.traccar.Protocol;
import org.traccar.helper.Parser;
import org.traccar.helper.PatternBuilder;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;
import org.traccar.session.UnitSession;

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
            .expression("([^,]*)")
            .any()
            .compile();

    private String decodeAlarm(String value) {
        return switch (value) {
            case "SOS" -> Position.ALARM_SOS;
            case "LB" -> Position.ALARM_LOW_BATTERY;
            case "LP" -> Position.ALARM_LOW_POWER;
            case "VB" -> Position.ALARM_VIBRATION;
            case "GF" -> Position.ALARM_GEOFENCE;
            case "TP" -> Position.ALARM_TAMPERING;
            default -> value;
        };
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
            resolveUnitSession(channel, remoteAddress, parser.next());
            return null;

        } else if (sentence.startsWith("@GPSD")) {

            Parser parser = new Parser(PATTERN_POSITION, sentence);
            if (!parser.matches()) {
                return null;
            }

            UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, parser.next());
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

            position.setLatitude(parser.nextDouble() * (parser.next().equals("S") ? -1 : 1));
            position.setLongitude(parser.nextDouble() * (parser.next().equals("W") ? -1 : 1));

            position.setSpeed(UnitsConverter.knotsFromKph(parser.nextDouble()));
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

        return null;
    }

}
```

```java
// src/test/java/org/traccar/protocol/R16hProtocolDecoderTest.java
package org.traccar.protocol;

import org.junit.jupiter.api.Test;
import org.traccar.WireDecoderHarness;
import org.traccar.model.Position;

public class R16hProtocolDecoderTest extends WireDecoderHarness {

    @Test
    public void testDecode() throws Exception {

        var decoder = wireUp(new R16hProtocolDecoder(null));

        assertNoOutput(decoder, asciiFrame(
                "@LINK,356823031235028"));

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

        verifyAttribute(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000233,01.34587,S,103.71993,W,12,111,-36,71,R,SOS"),
                Position.KEY_ALARM, Position.ALARM_SOS);

        verifyAttribute(decoder, asciiFrame(
                "@GPSD,356823031235028,S,20260520,000333,01.34587,N,103.71993,E,5,90,36,70,L,"),
                Position.KEY_ARCHIVE, true);

    }

}
```
