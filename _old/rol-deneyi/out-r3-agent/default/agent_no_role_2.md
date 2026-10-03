```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import jakarta.inject.Inject;
import org.traccar.WireProtocolRoot;
import org.traccar.GlyphBoundaryFrameSplitter;
import org.traccar.HandlerChainAssembler;
import org.traccar.EndpointListener;
import org.traccar.config.Config;

public class R16hProtocol extends WireProtocolRoot {

    @Inject
    public R16hProtocol(Config config) {
        addServer(new EndpointListener(config, getName(), true) {
            @Override
            protected void installChainHandlers(HandlerChainAssembler pipeline, Config config) {
                pipeline.addLast(new GlyphBoundaryFrameSplitter(MAX_FRAME_LENGTH, '$'));
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
            .expression("[RS],")                 // archive
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
            .expression("(.*)")                  // alarm
            .compile();

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;

        if (sentence.startsWith("@LINK")) {

            FieldCursor parser = new FieldCursor(PATTERN_LOGIN, sentence);
            if (parser.matches()) {
                resolveUnitSession(channel, remoteAddress, parser.next());
            }
            return null;

        }

        FieldCursor parser = new FieldCursor(PATTERN_POSITION, sentence);
        if (!parser.matches()) {
            return null;
        }

        UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, parser.next());
        if (deviceSession == null) {
            return null;
        }

        Position position = new Position(wireName());
        position.setDeviceId(deviceSession.getDeviceId());

        position.setTime(parser.nextDateTime());
        position.setValid(true);
        position.setLatitude(parser.nextCoordinate(FieldCursor.CoordinateFormat.WHOLE_DEG_HEMI));
        position.setLongitude(parser.nextCoordinate(FieldCursor.CoordinateFormat.WHOLE_DEG_HEMI));
        position.setSpeed(UnitsConverter.nauticalFromMetricSpeed(parser.nextInt()));
        position.setCourse(parser.nextInt());
        position.setAltitude(parser.nextInt());

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
        position.set(Position.KEY_LOCK, parser.next().equals("L"));

        String alarm = parser.next();
        if (!alarm.isEmpty()) {
            position.addAlarm(alarm);
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
                "@GPSD,356823031235028,S,20260520,000233,01.34587,S,103.71993,W,12,90,-5,71,R,SOS"));

    }

}

```
