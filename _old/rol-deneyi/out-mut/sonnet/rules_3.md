```java
// R16hProtocol.java
package org.traccar.protocol;

import org.traccar.EndpointListener;
import org.traccar.PipelineBuilder;
import org.traccar.WireProtocolRoot;
import org.traccar.config.Config;

public class R16hProtocol extends WireProtocolRoot {

    public R16hProtocol(Config config) {
        addServer(new EndpointListener(config, getName(), true) {
            @Override
            protected void installChainHandlers(PipelineBuilder pipeline, Config config) {
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
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;
import org.traccar.session.DeviceSession;

import java.net.SocketAddress;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.TimeZone;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;
        if (sentence.endsWith("$")) {
            sentence = sentence.substring(0, sentence.length() - 1);
        }

        String[] values = sentence.split(",", -1);

        if (values[0].equals("@LINK")) {

            resolveUnitSession(channel, remoteAddress, values[1]);

            return null;

        } else if (values[0].equals("@GPSD")) {

            DeviceSession deviceSession = resolveUnitSession(channel, remoteAddress, values[1]);
            if (deviceSession == null) {
                return null;
            }

            Position position = new Position(wireName());
            position.setDeviceId(deviceSession.getDeviceId());

            position.set(Position.KEY_ARCHIVE, values[2].equals("S"));

            DateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmmss");
            dateFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
            position.setTime(dateFormat.parse(values[3] + values[4]));

            position.setValid(true);

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

            position.setSpeed(UnitsConverter.knotsFromKph(Double.parseDouble(values[9])));
            position.setCourse(Double.parseDouble(values[10]));
            position.setAltitude(Double.parseDouble(values[11]));

            position.set(Position.KEY_BATTERY_LEVEL, Integer.parseInt(values[12]));
            position.set(Position.KEY_LOCK, values[13].equals("L"));

            if (!values[14].isEmpty()) {
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
import org.traccar.ProtocolTest;

public class R16hProtocolDecoderTest extends ProtocolTest {

    @Test
    public void testDecode() throws Exception {

        var decoder = new R16hProtocolDecoder(null);

        verifyNull(decoder, wireUp(decoder,
                "@LINK,356823031235028"));

        verifyPosition(decoder, wireUp(decoder,
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

    }

}
```
