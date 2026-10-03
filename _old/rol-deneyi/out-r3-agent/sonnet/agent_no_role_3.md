```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.WireProtocolRoot;
import org.traccar.GlyphBoundaryFrameSplitter;
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
import org.traccar.session.UnitSession;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;

import java.net.SocketAddress;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.TimeZone;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(R16hProtocol protocol) {
        super(protocol);
    }

    private static final DateFormat DATE_FORMAT = new SimpleDateFormat("yyyyMMddHHmmss");

    static {
        DATE_FORMAT.setTimeZone(TimeZone.getTimeZone("UTC"));
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;

        if (sentence.startsWith("@LINK,")) {

            String imei = sentence.substring("@LINK,".length());
            resolveUnitSession(channel, remoteAddress, imei);
            return null;

        } else if (sentence.startsWith("@GPSD,")) {

            String[] values = sentence.split(",", -1);

            UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, values[1]);
            if (deviceSession == null) {
                return null;
            }

            Position position = new Position(wireName());
            position.setDeviceId(deviceSession.getDeviceId());

            position.set(Position.KEY_BACKLOG, values[2].equals("S"));

            position.setTime(DATE_FORMAT.parse(values[3] + values[4]));

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
            position.setSpeed(UnitsConverter.nauticalFromMetricSpeed(Double.parseDouble(values[9])));
            position.setCourse(Double.parseDouble(values[10]));
            position.setAltitude(Double.parseDouble(values[11]));

            position.set(Position.KEY_BATTERY_LEVEL, Integer.parseInt(values[12]));
            position.set(Position.KEY_LOCK, values[13].equals("L"));

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

        assertFixDecoded(decoder, asciiFrame(
                "@GPSD,356823031235028,S,20260520,000233,01.34587,S,103.71993,W,12,271,-6,55,R,sos"));

    }

}

```
