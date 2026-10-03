```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.EndpointListener;
import org.traccar.GlyphBoundaryFrameSplitter;
import org.traccar.HandlerChainAssembler;
import org.traccar.WireProtocolRoot;

public class R16hProtocol extends WireProtocolRoot {

    public R16hProtocol() {
        addServer(new EndpointListener(this, getName(), true) {
            @Override
            protected void installChainHandlers(HandlerChainAssembler pipeline) {
                pipeline.addLast(new GlyphBoundaryFrameSplitter(1024, "$"));
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
import org.traccar.helper.FieldCursor;
import org.traccar.helper.GrammarComposer;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;
import org.traccar.session.UnitSession;

import java.net.SocketAddress;
import java.util.Calendar;
import java.util.TimeZone;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(R16hProtocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN = new GrammarComposer()
            .expression("@GPSD,")
            .number("(d+),")                    // imei
            .expression("([RS]),")               // record type
            .number("(dddd)(dd)(dd),")           // date (yyyyMMdd)
            .number("(dd)(dd)(dd),")             // time (HHmmss)
            .number("(d+.d+),")                  // latitude
            .expression("([NS]),")
            .number("(d+.d+),")                  // longitude
            .expression("([EW]),")
            .number("(d+),")                     // speed
            .number("(d+),")                     // course
            .number("(-?d+),")                   // altitude
            .number("(d+),")                     // battery
            .expression("([LR]),")               // strap lock
            .expression("(.*)")                  // alarm
            .compile();

    @Override
    protected Object decode(Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;

        if (sentence.startsWith("@LINK,")) {
            String imei = sentence.substring(sentence.indexOf(',') + 1).trim();
            resolveUnitSession(channel, remoteAddress, imei);
            return null;
        }

        FieldCursor parser = new FieldCursor(PATTERN, sentence);
        if (!parser.matches()) {
            return null;
        }

        String imei = parser.next();
        UnitSession unitSession = resolveUnitSession(channel, remoteAddress, imei);
        if (unitSession == null) {
            return null;
        }

        Position position = new Position(wireName());
        position.setDeviceId(unitSession.getDeviceId());

        position.set("archive", parser.next().equals("S"));

        int year = parser.nextInt();
        int month = parser.nextInt();
        int day = parser.nextInt();
        int hour = parser.nextInt();
        int minute = parser.nextInt();
        int second = parser.nextInt();

        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.clear();
        calendar.set(year, month - 1, day, hour, minute, second);
        position.setTime(calendar.getTime());

        double latitude = parser.nextDouble();
        String latitudeHemisphere = parser.next();
        double longitude = parser.nextDouble();
        String longitudeHemisphere = parser.next();

        position.setValid(true);
        position.setLatitude(latitudeHemisphere.equals("S") ? -latitude : latitude);
        position.setLongitude(longitudeHemisphere.equals("W") ? -longitude : longitude);

        position.setSpeed(UnitsConverter.nauticalFromMetricSpeed(parser.nextInt()));
        position.setCourse(parser.nextInt());
        position.setAltitude(parser.nextInt());

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
        position.set(Position.KEY_BLOCKED, parser.next().equals("L"));

        if (parser.hasNext()) {
            String alarm = parser.next();
            if (alarm != null && !alarm.isEmpty()) {
                position.set(Position.KEY_ALARM, alarm);
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
import org.traccar.WireDecoderHarness;

public class R16hProtocolDecoderTest extends WireDecoderHarness {

    @Test
    public void testDecode() throws Exception {

        var decoder = wireUp(new R16hProtocolDecoder(new R16hProtocol()));

        assertNoOutput(decoder, asciiFrame(
                "@LINK,356823031235028"));

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

    }

}
```
