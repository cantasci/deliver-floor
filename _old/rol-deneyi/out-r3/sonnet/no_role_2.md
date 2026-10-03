```java
// R16hProtocol.java
package org.traccar.protocol;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.BaseProtocol;
import org.traccar.PipelineBuilder;
import org.traccar.TrackerServer;
import org.traccar.config.Config;

public class R16hProtocol extends BaseProtocol {

    public R16hProtocol() {
        addServer(new TrackerServer(getName(), true) {
            @Override
            protected void addProtocolHandlers(PipelineBuilder pipeline, Config config) {
                pipeline.addLast(new DelimiterBasedFrameDecoder(1024, Unpooled.wrappedBuffer(new byte[]{'$'})));
                pipeline.addLast(new StringDecoder());
                pipeline.addLast(new StringEncoder());
                pipeline.addLast(new R16hProtocolDecoder(this));
            }
        });
    }

}
```

```java
// R16hProtocolDecoder.java
package org.traccar.protocol;

import io.netty.channel.Channel;
import org.traccar.BaseProtocolDecoder;
import org.traccar.Protocol;
import org.traccar.helper.DateBuilder;
import org.traccar.helper.Parser;
import org.traccar.helper.PatternBuilder;
import org.traccar.helper.UnitsConverter;
import org.traccar.model.Position;
import org.traccar.session.DeviceSession;

import java.net.SocketAddress;
import java.util.regex.Pattern;

public class R16hProtocolDecoder extends BaseProtocolDecoder {

    public R16hProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private static final Pattern PATTERN_LOGIN = new PatternBuilder()
            .text("@LINK,")
            .number("(d+)")                     // imei
            .compile();

    private static final Pattern PATTERN_POSITION = new PatternBuilder()
            .text("@GPSD,")
            .number("(d+),")                    // imei
            .expression("([RS]),")              // type
            .number("(dddd)(dd)(dd),")          // date (yyyy) (mm) (dd)
            .number("(dd)(dd)(dd),")            // time (hh) (mm) (ss)
            .number("(d+.d+),([NS]),")          // latitude
            .number("(d+.d+),([EW]),")          // longitude
            .number("(d+),")                    // speed
            .number("(d+),")                    // course
            .number("(-?d+),")                  // altitude
            .number("(d+),")                    // battery
            .expression("([LR]),")              // lock status
            .expression("([^,]*)")              // alarm
            .compile();

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;

        if (sentence.startsWith("@LINK")) {

            Parser parser = new Parser(PATTERN_LOGIN, sentence);
            if (parser.matches()) {
                getDeviceSession(channel, remoteAddress, parser.next());
            }
            return null;

        } else if (sentence.startsWith("@GPSD")) {

            Parser parser = new Parser(PATTERN_POSITION, sentence);
            if (!parser.matches()) {
                return null;
            }

            DeviceSession deviceSession = getDeviceSession(channel, remoteAddress, parser.next());
            if (deviceSession == null) {
                return null;
            }

            Position position = new Position(getProtocolName());
            position.setDeviceId(deviceSession.getDeviceId());

            position.set(Position.KEY_ARCHIVE, parser.next().equals("S"));

            DateBuilder dateBuilder = new DateBuilder()
                    .setDate(parser.nextInt(), parser.nextInt(), parser.nextInt())
                    .setTime(parser.nextInt(), parser.nextInt(), parser.nextInt());
            position.setTime(dateBuilder.getDate());

            position.setValid(true);
            position.setLatitude(parser.nextCoordinate(Parser.CoordinateFormat.DEG_HEM));
            position.setLongitude(parser.nextCoordinate(Parser.CoordinateFormat.DEG_HEM));

            position.setSpeed(UnitsConverter.knotsFromKph(parser.nextInt()));
            position.setCourse(parser.nextInt());
            position.setAltitude(parser.nextInt());

            position.set(Position.KEY_BATTERY_LEVEL, parser.nextInt());
            position.set("lock", parser.next().equals("L"));

            String alarm = parser.next();
            if (!alarm.isEmpty()) {
                position.set(Position.KEY_ALARM, alarm);
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

        verifyNull(decoder, "@LINK,356823031235028");

        verifyPosition(decoder, "@GPSD,356823031235028,R,20260520,000133,01.34587,N,103.71993,E,0,111,36,72,L,");

    }

}
```
