```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.ChainBuilder;
import org.traccar.EndpointListener;
import org.traccar.GlyphBoundaryFrameSplitter;
import org.traccar.WireProtocolRoot;
import org.traccar.config.Config;

public class R16hProtocol extends WireProtocolRoot {

    public R16hProtocol() {
        addServer(new EndpointListener(this, getName(), true) {
            @Override
            protected void installChainHandlers(ChainBuilder pipeline, Config config) {
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
import org.traccar.UnitSession;
import org.traccar.WireProtocolRoot;
import org.traccar.helper.DateBuilder;
import org.traccar.helper.FieldCursor;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(WireProtocolRoot protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN_LOGIN = Pattern.compile("^@LINK,(\\d+)");

    private static final Pattern PATTERN_POSITION = Pattern.compile(
            "^@GPSD,(\\d+),([RS]),(\\d{4})(\\d{2})(\\d{2}),(\\d{2})(\\d{2})(\\d{2})," +
            "(\\d+\\.\\d+),([NS]),(\\d+\\.\\d+),([EW])," +
            "(\\d+),(-?\\d+),(-?\\d+),(\\d+),([LR]),(\\w*)");

    @Override
    protected Object decode(Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

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

        UnitSession unitSession = resolveUnitSession(channel, remoteAddress, parser.next());
        if (unitSession == null) {
            return null;
        }

        Position position = new Position(wireName());
        position.setDeviceId(unitSession.getDeviceId());

        position.set(Position.KEY_ARCHIVE, parser.next().equals("S"));

        DateBuilder dateBuilder = new DateBuilder()
                .setDate(parser.nextInt(), parser.nextInt(), parser.nextInt())
                .setTime(parser.nextInt(), parser.nextInt(), parser.nextInt());
        position.setTime(dateBuilder.getDate());

        position.setValid(true);
        position.setLatitude(parser.nextDouble() * (parser.next().equals("S") ? -1 : 1));
        position.setLongitude(parser.nextDouble() * (parser.next().equals("W") ? -1 : 1));

        position.setSpeed(UnitsConverter.nauticalFromMetricSpeed(parser.nextDouble()));
        position.setCourse(parser.nextDouble());
        position.setAltitude(parser.nextInt());

        position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
        position.set("strapLocked", parser.next().equals("L"));

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
