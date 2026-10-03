```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.EndpointListener;
import org.traccar.PipelineBuilder;
import org.traccar.WireProtocolRoot;
import org.traccar.config.Config;

public class R16hProtocol extends WireProtocolRoot {

    public R16hProtocol() {
        addServer(new EndpointListener(this, getName(), true) {
            @Override
            protected void installChainHandlers(PipelineBuilder pipeline, Config config) {
                pipeline.addLast(new DelimiterBasedFrameDecoder(1024, Unpooled.wrappedBuffer(new byte[]{'$'})));
                pipeline.addLast(new StringDecoder());
                pipeline.addLast(new StringEncoder());
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
import org.traccar.session.UnitSession;

import java.net.SocketAddress;
import java.text.SimpleDateFormat;
import java.util.TimeZone;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    private final SimpleDateFormat dateFormat = createDateFormat();

    private static SimpleDateFormat createDateFormat() {
        SimpleDateFormat format = new SimpleDateFormat("yyyyMMddHHmmss");
        format.setTimeZone(TimeZone.getTimeZone("UTC"));
        return format;
    }

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;
        String[] values = sentence.trim().split(",", -1);

        if (values.length < 2) {
            return null;
        }

        if ("@LINK".equals(values[0])) {

            resolveUnitSession(channel, remoteAddress, values[1]);
            return null;

        } else if ("@GPSD".equals(values[0]) && values.length >= 15) {

            UnitSession session = resolveUnitSession(channel, remoteAddress, values[1]);
            if (session == null) {
                return null;
            }

            Position position = new Position(wireName());
            position.setDeviceId(session.getDeviceId());

            position.set(Position.KEY_ARCHIVE, "S".equals(values[2]));

            position.setTime(dateFormat.parse(values[3] + values[4]));

            double latitude = Double.parseDouble(values[5]);
            if ("S".equals(values[6])) {
                latitude = -latitude;
            }
            position.setLatitude(latitude);

            double longitude = Double.parseDouble(values[7]);
            if ("W".equals(values[8])) {
                longitude = -longitude;
            }
            position.setLongitude(longitude);

            position.setValid(true);
            position.setSpeed(UnitsConverter.knotsFromKph(Double.parseDouble(values[9])));
            position.setCourse(Double.parseDouble(values[10]));
            position.setAltitude(Double.parseDouble(values[11]));

            position.set(Position.KEY_BATTERY_LEVEL, Integer.parseInt(values[12]));
            position.set("strapLock", values[13]);
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

        var decoder = wireUp(new R16hProtocolDecoder(null));

        verifyNull(decoder, buffer(
                "@LINK,356823031235028"));

        verifyPosition(decoder, buffer(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

    }

}
```
