```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.WireProtocolRoot;
import org.traccar.HandlerChainAssembler;
import org.traccar.EndpointListener;
import org.traccar.config.Config;
import org.traccar.model.Command;

import java.nio.charset.StandardCharsets;

import jakarta.inject.Inject;

public class R16hProtocol extends WireProtocolRoot {

    @Inject
    public R16hProtocol(Config config) {
        setSupportedDataCommands(Command.TYPE_CUSTOM);
        addServer(new EndpointListener(config, getName(), true) {
            @Override
            protected void installChainHandlers(HandlerChainAssembler pipeline, Config config) {
                pipeline.addLast(new DelimiterBasedFrameDecoder(
                        MAX_FRAME_LENGTH, Unpooled.wrappedBuffer(new byte[]{'$'})));
                pipeline.addLast(new StringEncoder(StandardCharsets.ISO_8859_1));
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
import org.traccar.session.UnitSession;
import org.traccar.helper.DateBuilder;
import org.traccar.helper.Parser;
import org.traccar.helper.PatternBuilder;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN = new PatternBuilder()
            .text("@GPSD,")
            .number("(d+),")                    // imei
            .expression("([RS]),")               // type
            .number("(dddd)(dd)(dd),")           // date
            .number("(dd)(dd)(dd),")             // time
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

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;

        if (sentence.startsWith("@LINK")) {
            String imei = sentence.substring(sentence.indexOf(',') + 1).trim();
            resolveUnitSession(channel, remoteAddress, imei);
            return null;
        }

        Parser parser = new Parser(PATTERN, sentence);
        if (!parser.matches()) {
            return null;
        }

        String imei = parser.next();
        UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, imei);
        if (deviceSession == null) {
            return null;
        }

        Position position = new Position(getProtocolName());
        position.setDeviceId(deviceSession.getDeviceId());

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

        position.setSpeed(UnitsConverter.knotsFromKph(parser.nextInt()));
        position.setCourse(parser.nextInt());
        position.setAltitude(parser.nextInt());

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
        position.set(Position.KEY_LOCK, parser.next().equals("L"));

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

        assertNoOutput(decoder, asciiFrame(
                "@LINK,356823031235028"));

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

    }

}
```
