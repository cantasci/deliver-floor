```java
// R16hProtocol.java
package org.traccar.protocol;

import org.traccar.WireProtocolRoot;
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
import org.traccar.FieldCursor;
import org.traccar.GrammarComposer;
import org.traccar.Protocol;
import org.traccar.helper.DateBuilder;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;
import org.traccar.session.UnitSession;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN = new GrammarComposer()
            .text("@GPSD,")
            .number("(d+),")                    // imei
            .expression("([RS]),")               // type
            .number("(dddd)(dd)(dd),")           // date (yyyy)(mm)(dd)
            .number("(dd)(dd)(dd),")             // time (hh)(mm)(ss)
            .number("(d+.d+),")                  // latitude
            .expression("([NS]),")
            .number("(d+.d+),")                  // longitude
            .expression("([EW]),")
            .number("(d+.?d*),")                 // speed
            .number("(d+),")                     // course
            .number("(-?d+),")                   // altitude
            .number("(d+),")                     // battery
            .expression("([LR]),")               // lock status
            .expression("([^,]*)")               // alarm
            .compile();

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = ((String) msg).trim();
        if (sentence.endsWith("$")) {
            sentence = sentence.substring(0, sentence.length() - 1);
        }

        if (sentence.startsWith("@LINK")) {

            String imei = sentence.substring(sentence.indexOf(',') + 1).trim();
            resolveUnitSession(channel, remoteAddress, imei);
            return null;

        } else if (sentence.startsWith("@GPSD")) {

            FieldCursor parser = new FieldCursor(PATTERN, sentence);
            if (!parser.matches()) {
                return null;
            }

            String imei = parser.next();
            UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, imei);
            if (deviceSession == null) {
                return null;
            }

            Position position = new Position(wireName());
            position.setDeviceId(deviceSession.getDeviceId());

            position.set("archive", parser.next().equals("S"));

            DateBuilder dateBuilder = new DateBuilder()
                    .setDate(parser.nextInt(), parser.nextInt(), parser.nextInt())
                    .setTime(parser.nextInt(), parser.nextInt(), parser.nextInt());
            position.setTime(dateBuilder.getDate());

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

            position.setSpeed(UnitsConverter.nauticalFromMetricSpeed(parser.nextDouble()));
            position.setCourse(parser.nextInt());
            position.setAltitude(parser.nextInt());

            position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
            position.set("lock", parser.next());

            String alarm = parser.next();
            if (!alarm.isEmpty()) {
                position.set(Position.KEY_ALARM, alarm);
            }

            position.setValid(true);

            return position;

        }

        return null;
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
