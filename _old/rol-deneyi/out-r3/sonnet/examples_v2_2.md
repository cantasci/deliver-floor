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

import jakarta.inject.Inject;

public class R16hProtocol extends WireProtocolRoot {

    @Inject
    public R16hProtocol(Config config) {
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
import org.traccar.Protocol;
import org.traccar.session.UnitSession;
import org.traccar.helper.DateBuilder;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;

import java.net.SocketAddress;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = ((String) msg).trim();
        if (sentence.isEmpty()) {
            return null;
        }

        String[] values = sentence.split(",", -1);
        String type = values[0];
        String imei = values[1];

        UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, imei);
        if (deviceSession == null || !type.equals("@GPSD")) {
            return null;
        }

        Position position = new Position(getProtocolName());
        position.setDeviceId(deviceSession.getDeviceId());

        position.set(Position.KEY_ARCHIVE, values[2].equals("S"));

        String date = values[3];
        String time = values[4];
        DateBuilder dateBuilder = new DateBuilder()
                .setDate(
                        Integer.parseInt(date.substring(0, 4)),
                        Integer.parseInt(date.substring(4, 6)),
                        Integer.parseInt(date.substring(6, 8)))
                .setTime(
                        Integer.parseInt(time.substring(0, 2)),
                        Integer.parseInt(time.substring(2, 4)),
                        Integer.parseInt(time.substring(4, 6)));
        position.setTime(dateBuilder.getDate());

        double latitude = Double.parseDouble(values[5]);
        if (values[6].equals("S")) {
            latitude = -latitude;
        }
        position.setLatitude(latitude);

        double longitude = Double.parseDouble(values[7]);
        if (values[8].equals("W")) {
            longitude = -longitude;
        }
        position.setLongitude(longitude);

        position.setValid(true);
        position.setSpeed(UnitsConverter.knotsFromKph(Double.parseDouble(values[9])));
        position.setCourse(Double.parseDouble(values[10]));
        position.setAltitude(Double.parseDouble(values[11]));

        position.set(Position.KEY_BATTERY_LEVEL, Integer.parseInt(values[12]));
        position.set("lock", values[13].equals("L"));

        if (values.length > 14 && !values[14].isEmpty()) {
            position.set(Position.KEY_ALARM, values[14]);
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
                "@GPSD,356823031235028,S,20260520,000200,01.34590,N,103.71995,E,15,90,40,68,R,LOWBAT"));

    }

}
```
