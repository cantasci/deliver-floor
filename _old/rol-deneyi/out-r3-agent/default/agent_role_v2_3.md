```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.WireProtocolRoot;
import org.traccar.GlyphBoundaryFrameSplitter;
import org.traccar.HandlerChainAssembler;
import org.traccar.EndpointListener;
import org.traccar.config.Config;

import jakarta.inject.Inject;

public class R16hProtocol extends WireProtocolRoot {

    @Inject
    public R16hProtocol(Config config) {
        addServer(new EndpointListener(config, getName(), true) {
            @Override
            protected void installChainHandlers(HandlerChainAssembler pipeline, Config config) {
                pipeline.addLast(new GlyphBoundaryFrameSplitter(MAX_FRAME_LENGTH, "$"));
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

    private static final Pattern PATTERN_LOGIN = new GrammarComposer()
            .text("@LINK,")
            .number("(d+)")                      // imei
            .compile();

    private static final Pattern PATTERN_POSITION = new GrammarComposer()
            .text("@GPSD,")
            .number("(d+),")                     // imei
            .expression("([RS]),")               // archive
            .number("(dddd)(dd)(dd),")           // date (yyyymmdd)
            .number("(dd)(dd)(dd),")             // time (hhmmss)
            .number("(d+.d+),")                  // latitude
            .expression("([NS]),")               // hemisphere
            .number("(d+.d+),")                  // longitude
            .expression("([EW]),")               // hemisphere
            .number("(d+.?d*),")                 // speed
            .number("(d+.?d*),")                 // course
            .number("(-?d+),")                   // altitude
            .number("(d+),")                     // battery
            .expression("([LR]),")               // lock
            .expression("(\\w*)")                // alarm
            .compile();

    private String decodeAlarm(String value) {
        return switch (value) {
            case "SOS" -> Position.ALARM_SOS;
            case "LB" -> Position.ALARM_LOW_BATTERY;
            case "RM" -> Position.ALARM_REMOVING;
            case "MV" -> Position.ALARM_MOVEMENT;
            case "GF" -> Position.ALARM_GEOFENCE;
            default -> null;
        };
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

        if (parser.next().equals("S")) {
            position.set(Position.KEY_BACKLOG, true);
        }

        position.setTime(parser.nextDateTime());

        position.setValid(true);
        position.setLatitude(parser.nextCoordinate(FieldCursor.CoordinateFormat.WHOLE_DEG_HEMI));
        position.setLongitude(parser.nextCoordinate(FieldCursor.CoordinateFormat.WHOLE_DEG_HEMI));
        position.setSpeed(UnitsConverter.nauticalFromMetricSpeed(parser.nextDouble(0)));
        position.setCourse(parser.nextDouble(0));
        position.setAltitude(parser.nextDouble(0));

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt(0));
        position.set(Position.KEY_LOCK, parser.next().equals("L"));

        if (parser.hasNext()) {
            position.set(Position.KEY_ALARM, decodeAlarm(parser.next()));
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
                "@GPSD,356823031235028,S,20260520,000233,01.34587,S,103.71993,W,12.5,111,-36,72,R,"),
                Position.KEY_BACKLOG, true);

        verifyAttribute(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000333,01.34587,N,103.71993,E,0,111,36,15,L,SOS"),
                Position.KEY_ALARM, Position.ALARM_SOS);

        verifyAttribute(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000433,01.34587,N,103.71993,E,0,111,36,15,R,"),
                Position.KEY_LOCK, false);

    }

}

```
