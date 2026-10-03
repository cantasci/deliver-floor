```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.handler.codec.string.StringDecoder;
import org.traccar.EndpointListener;
import org.traccar.PipelineBuilder;
import org.traccar.WireProtocolRoot;
import org.traccar.config.Config;

import java.nio.charset.StandardCharsets;

public class R16hProtocol extends WireProtocolRoot {

    public R16hProtocol(Config config) {
        addServer(new EndpointListener(config, getName(), true) {
            @Override
            protected void installChainHandlers(PipelineBuilder pipeline, Config config) {
                pipeline.addLast(new StringDecoder(StandardCharsets.US_ASCII));
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
import org.traccar.session.UnitSession;
import org.traccar.Protocol;
import org.traccar.helper.FieldCursor;
import org.traccar.helper.GrammarComposer;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;

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

    private static final Pattern PATTERN = new GrammarComposer()
            .text("@GPSD,")
            .number("(d+)")                      // imei
            .text(",")
            .expression("([RS])")                // real-time or stored
            .text(",")
            .number("(dddd)(dd)(dd)")            // date (yyyymmdd)
            .text(",")
            .number("(dd)(dd)(dd)")              // time (hhmmss)
            .text(",")
            .number("(dd.ddddd)")                // latitude
            .text(",")
            .expression("([NS])")
            .text(",")
            .number("(ddd.ddddd)")               // longitude
            .text(",")
            .expression("([EW])")
            .text(",")
            .number("(d+)")                      // speed (kph)
            .text(",")
            .number("(d+)")                      // course
            .text(",")
            .expression("(-?\\d+)")              // altitude
            .text(",")
            .number("(d+)")                      // battery
            .text(",")
            .expression("([LR])")                // strap lock status
            .text(",")
            .expression("(.*)")                  // alarm
            .compile();

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;
        if (sentence.endsWith("$")) {
            sentence = sentence.substring(0, sentence.length() - 1);
        }

        if (sentence.startsWith("@LINK")) {
            FieldCursor parser = new FieldCursor(PATTERN_LOGIN, sentence);
            if (parser.matches()) {
                resolveUnitSession(channel, remoteAddress, parser.next());
            }
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

        position.set(Position.KEY_ARCHIVE, parser.next().equals("S"));

        position.setTime(parser.nextDateTime());

        double latitude = parser.nextDouble(0);
        if (parser.next().equals("S")) {
            latitude = -latitude;
        }
        position.setLatitude(latitude);

        double longitude = parser.nextDouble(0);
        if (parser.next().equals("W")) {
            longitude = -longitude;
        }
        position.setLongitude(longitude);

        position.setValid(true);
        position.setSpeed(UnitsConverter.knotsFromKph(parser.nextDouble(0)));
        position.setCourse(parser.nextDouble(0));

        position.setAltitude(parser.nextDouble(0));

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt(0));
        position.set(Position.KEY_LOCK, parser.next().equals("L"));

        String alarm = parser.next();
        if (!alarm.isEmpty()) {
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

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

    }

}
```
