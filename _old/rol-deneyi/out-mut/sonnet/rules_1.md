```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.EndpointListener;
import org.traccar.PipelineBuilder;
import org.traccar.TrackerServer;
import org.traccar.WireProtocolRoot;
import org.traccar.config.Config;

import java.nio.charset.StandardCharsets;

public class R16hProtocol extends WireProtocolRoot {

    public R16hProtocol(Config config) {
        addServer(new TrackerServer(config, getName(), true, new EndpointListener() {
            @Override
            public void installChainHandlers(PipelineBuilder pipeline, Config config) {
                pipeline.addLast(new DelimiterBasedFrameDecoder(1024, Unpooled.wrappedBuffer(new byte[]{'$'})));
                pipeline.addLast(new StringDecoder(StandardCharsets.US_ASCII));
                pipeline.addLast(new StringEncoder(StandardCharsets.US_ASCII));
                pipeline.addLast(new R16hProtocolDecoder(R16hProtocol.this));
            }
        }));
    }

}
```

```java
// R16hProtocolDecoder.java
package org.traccar.protocol;

import io.netty.channel.Channel;
import org.traccar.AbstractWireDecoder;
import org.traccar.Protocol;
import org.traccar.model.Position;
import org.traccar.model.UnitsConverter;
import org.traccar.session.DeviceSession;

import java.net.SocketAddress;
import java.text.SimpleDateFormat;
import java.util.TimeZone;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends AbstractWireDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN = Pattern.compile(
            "@GPSD,"
            + "(\\d+),"                    // imei
            + "([RS]),"                    // type
            + "(\\d{4})(\\d{2})(\\d{2}),"  // date
            + "(\\d{2})(\\d{2})(\\d{2}),"  // time
            + "(\\d+\\.\\d+),([NS]),"      // latitude
            + "(\\d+\\.\\d+),([EW]),"      // longitude
            + "(\\d+),"                    // speed
            + "(\\d+),"                    // course
            + "(-?\\d+),"                  // altitude
            + "(\\d+),"                    // battery
            + "([LR]),"                    // strap lock
            + "(.*)");                     // alarm

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;

        if (sentence.startsWith("@LINK,")) {
            String imei = sentence.substring(6).trim();
            resolveUnitSession(channel, remoteAddress, imei);
            return null;
        }

        Matcher parser = PATTERN.matcher(sentence);
        if (!parser.matches()) {
            return null;
        }

        DeviceSession deviceSession = resolveUnitSession(channel, remoteAddress, parser.group(1));
        if (deviceSession == null) {
            return null;
        }

        Position position = new Position(wireName());
        position.setDeviceId(deviceSession.getDeviceId());

        boolean history = parser.group(2).equals("S");

        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmmss");
        dateFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
        String date = parser.group(3) + parser.group(4) + parser.group(5);
        String time = parser.group(6) + parser.group(7) + parser.group(8);
        position.setTime(dateFormat.parse(date + time));

        position.setValid(true);

        double latitude = Double.parseDouble(parser.group(9));
        if (parser.group(10).equals("S")) {
            latitude = -latitude;
        }
        position.setLatitude(latitude);

        double longitude = Double.parseDouble(parser.group(11));
        if (parser.group(12).equals("W")) {
            longitude = -longitude;
        }
        position.setLongitude(longitude);

        position.setSpeed(UnitsConverter.knotsFromKph(Integer.parseInt(parser.group(13))));
        position.setCourse(Integer.parseInt(parser.group(14)));
        position.setAltitude(Integer.parseInt(parser.group(15)));

        position.set(Position.KEY_BATTERY_LEVEL, Integer.parseInt(parser.group(16)));
        position.set(Position.KEY_ARMED, parser.group(17).equals("L"));

        String alarm = parser.group(18);
        if (!alarm.isEmpty()) {
            position.set(Position.KEY_ALARM, alarm);
        }

        position.set(Position.KEY_ARCHIVE, history);

        return position;
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

        wireUp(decoder);

        verifyNull(decoder, buffer(
                "@LINK,356823031235028"));

        verifyPosition(decoder, buffer(
                "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,"));

        verifyPosition(decoder, buffer(
                "@GPSD,356823031235028,S,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,R,LOWBAT"));

    }

}
```
