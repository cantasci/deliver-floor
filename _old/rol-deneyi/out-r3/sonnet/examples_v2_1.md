```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import org.traccar.WireProtocolRoot;
import org.traccar.HandlerChainAssembler;
import org.traccar.EndpointListener;
import org.traccar.config.Config;
import org.traccar.model.Command;

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
import org.traccar.session.UnitSession;
import org.traccar.Protocol;
import org.traccar.model.Position;
import org.traccar.helper.UnitsConverter;

import java.net.SocketAddress;
import java.text.SimpleDateFormat;
import java.util.TimeZone;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    private final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmmss");

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
        dateFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;
        String[] values = sentence.split(",", -1);

        if (values[0].equals("@LINK")) {
            resolveUnitSession(channel, remoteAddress, values[1]);
            return null;
        } else if (values[0].equals("@GPSD")) {

            UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, values[1]);
            if (deviceSession == null) {
                return null;
            }

            Position position = new Position(getProtocolName());
            position.setDeviceId(deviceSession.getDeviceId());
            position.setValid(true);

            position.setTime(dateFormat.parse(values[3] + values[4]));

            double lat = Double.parseDouble(values[5]);
            if (values[6].equals("S")) {
                lat = -lat;
            }
            position.setLatitude(lat);

            double lon = Double.parseDouble(values[7]);
            if (values[8].equals("W")) {
                lon = -lon;
            }
            position.setLongitude(lon);

            position.setSpeed(UnitsConverter.knotsFromKph(Double.parseDouble(values[9])));
            position.setCourse(Double.parseDouble(values[10]));
            position.setAltitude(Double.parseDouble(values[11]));

            position.set(Position.KEY_BATTERY_LEVEL, Integer.parseInt(values[12]));

            if (values.length > 14 && !values[14].isEmpty()) {
                position.set(Position.KEY_ALARM, values[14]);
            }

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
