# Example decoder from the repository

```java
package org.traccar.protocol;

import io.netty.channel.Channel;
import org.traccar.AbstractWireDecoder;
import org.traccar.session.UnitSession;
import org.traccar.Protocol;
import org.traccar.helper.FieldCursor;
import org.traccar.helper.GrammarComposer;
import org.traccar.model.Position;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class TopflytechProtocolDecoder extends AbstractWireDecoder {

    public TopflytechProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN = new GrammarComposer()
            .text("(")
            .number("(d+)")                      // imei
            .any()
            .number("(dd)(dd)(dd)")              // date (yymmdd)
            .number("(dd)(dd)(dd)")              // time (hhmmss)
            .expression("([AV])")
            .number("(dd)(dd.dddd)([NS])")       // latitude
            .number("(ddd)(dd.dddd)([EW])")      // longitude
            .number("(ddd.d)")                   // speed
            .number("(d+.d+)")                   // course
            .compile();

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        FieldCursor parser = new FieldCursor(PATTERN, (String) msg);
        if (!parser.matches()) {
            return null;
        }

        Position position = new Position(wireName());

        UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, parser.next());
        if (deviceSession == null) {
            return null;
        }
        position.setDeviceId(deviceSession.getDeviceId());

        position.setTime(parser.nextDateTime());

        position.setValid(parser.next().equals("A"));
        position.setLatitude(parser.nextCoordinate());
        position.setLongitude(parser.nextCoordinate());
        position.setSpeed(parser.nextDouble(0));
        position.setCourse(parser.nextDouble(0));

        return position;
    }

}

```

# Example test

```java
package org.traccar.protocol;

import org.junit.jupiter.api.Test;
import org.traccar.WireDecoderHarness;

public class TopflytechProtocolDecoderTest extends WireDecoderHarness {

    @Test
    public void testDecode() throws Exception {

        var decoder = wireUp(new TopflytechProtocolDecoder(null));

        assertFixDecoded(decoder, asciiFrame(
                "(880316890094910BP00XG00b600000000L00074b54S00000000R0C0F0014000100f0130531152205A0706.1395S11024.0965E000.0251.25"));

    }

}

```
