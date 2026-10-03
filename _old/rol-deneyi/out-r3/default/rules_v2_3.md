```java
// R16hProtocol.java
package org.traccar.protocol;

import jakarta.inject.Inject;
import org.traccar.WireProtocolRoot;
import org.traccar.HandlerChainAssembler;
import org.traccar.EndpointListener;
import org.traccar.config.Config;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.GlyphBoundaryFrameSplitter;

public class R16hProtocol extends WireProtocolRoot {

    @Inject
    public R16hProtocol(Config config) {
        addServer(new EndpointListener(config, getName(), true) {
            @Override
            protected void installChainHandlers(HandlerChainAssembler pipeline, Config config) {
                pipeline.addLast(new GlyphBoundaryFrameSplitter(1024, '$'));
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
import org.traccar.session.UnitSession;
import org.traccar.helper.FieldCursor;
import org.traccar.helper.GrammarComposer;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(WireProtocolRoot protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN_LOGIN = new GrammarComposer()
            .text("@LINK,")
            .number("(d+)")
            .any()
            .compile();

    private static final Pattern PATTERN = new GrammarComposer()
            .text("@GPSD,")
            .number("(d+),")
            .expression("([RS]),")
            .number("(dddd)(dd)(dd),")
            .number("(dd)(dd)(dd),")
            .number("(d+.d+),([NS]),")
            .number("(d+.d+),([EW]),")
            .number("(d+.?d*),")
            .number("(d+.?d*),")
            .number("(-?d+),")
            .number("(d+),")
            .expression("([LR]),")
            .expression("([^,]*)")
            .any()
            .compile();

    private String decodeAlarm(String value) {
        switch (value) {
            case "SOS":
                return Position.ALARM_SOS;
            case "LOW":
                return Position.ALARM_LOW_BATTERY;
            case "MOV":
                return Position.ALARM_MOVEMENT;
            case "TAM":
                return Position.ALARM_TAMPERING;
            default:
                return null;
        }
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;

        FieldCursor loginParser = new FieldCursor(PATTERN_LOGIN, sentence);
        if (loginParser.matches()) {
            resolveUnitSession(channel, remoteAddress, loginParser.next());
            return null;
        }

        FieldCursor parser = new FieldCursor(PATTERN, sentence);
        if (!parser.matches()) {
            return null;
        }

        UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, parser.next());
        if (deviceSession == null) {
            return null;
        }

        Position position = new Position(wireName());
        position.setDeviceId(deviceSession.getDeviceId());

        if (parser.next().equals("S")) {
            position.set("archive", true);
        }

        position.setTime(parser.nextDateTime());

        position.setValid(true);
        position.setLatitude(parser.nextCoordinate(FieldCursor.CoordinateFormat.WHOLE_DEG_HEMI));
        position.setLongitude(parser.nextCoordinate(FieldCursor.CoordinateFormat.WHOLE_DEG_HEMI));
        position.setSpeed(UnitsConverter.nauticalFromMetricSpeed(parser.nextDouble()));
        position.setCourse(parser.nextDouble());
        position.setAltitude(parser.nextInt());

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
        position.set(Position.KEY_BLOCKED, parser.next().equals("L"));

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

public class R16hProtocolDecoderTest extends WireDecoderHarness {

    @Test
    public void testDecode() throws Exception {

        var decoder = wireUp(new R16hProtocolDecoder(null));

        assertNoOutput(decoder, asciiFrame(
                "@LINK,356823031235028"));

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,S,20260520,000233,01.34587,N,103.71993,E,42,90,-12,68,R,SOS"));

    }

}
```
