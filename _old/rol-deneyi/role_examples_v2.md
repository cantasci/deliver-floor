# Example files from the repository (selected for this task)

## src/main/java/org/traccar/protocol/Xrb28Protocol.java

```java
package org.traccar.protocol;

import io.netty.handler.codec.LineBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import org.traccar.WireProtocolRoot;
import org.traccar.HandlerChainAssembler;
import org.traccar.EndpointListener;
import org.traccar.config.Config;
import org.traccar.model.Command;

import java.nio.charset.StandardCharsets;

import jakarta.inject.Inject;

public class Xrb28Protocol extends WireProtocolRoot {

    @Inject
    public Xrb28Protocol(Config config) {
        setSupportedDataCommands(
                Command.TYPE_CUSTOM,
                Command.TYPE_POSITION_SINGLE,
                Command.TYPE_POSITION_PERIODIC,
                Command.TYPE_ALARM_ARM,
                Command.TYPE_ALARM_DISARM);
        addServer(new EndpointListener(config, getName(), false) {
            @Override
            protected void installChainHandlers(HandlerChainAssembler pipeline, Config config) {
                pipeline.addLast(new LineBasedFrameDecoder(MAX_FRAME_LENGTH));
                pipeline.addLast(new StringEncoder(StandardCharsets.ISO_8859_1));
                pipeline.addLast(new StringDecoder());
                pipeline.addLast(new Xrb28ProtocolEncoder(Xrb28Protocol.this));
                pipeline.addLast(new Xrb28ProtocolDecoder(Xrb28Protocol.this));
            }
        });
    }

}
```

## src/main/java/org/traccar/protocol/ArnaviProtocolDecoder.java

```java
package org.traccar.protocol;

import com.google.inject.Injector;
import io.netty.buffer.ByteBuf;
import io.netty.channel.Channel;
import org.traccar.AbstractWireDecoder;
import org.traccar.Protocol;

import jakarta.inject.Inject;
import java.net.SocketAddress;

public class ArnaviProtocolDecoder extends AbstractWireDecoder {

    private final ArnaviTextProtocolDecoder textProtocolDecoder;
    private final ArnaviBinaryProtocolDecoder binaryProtocolDecoder;

    public ArnaviProtocolDecoder(Protocol protocol) {
        super(protocol);
        textProtocolDecoder = new ArnaviTextProtocolDecoder(protocol);
        binaryProtocolDecoder = new ArnaviBinaryProtocolDecoder(protocol);
    }

    @Inject
    public void setInjector(Injector injector) {
        injector.injectMembers(textProtocolDecoder);
        injector.injectMembers(binaryProtocolDecoder);
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        ByteBuf buf = (ByteBuf) msg;

        if (buf.getByte(buf.readerIndex()) == '$') {
            return textProtocolDecoder.decode(channel, remoteAddress, msg);
        } else {
            return binaryProtocolDecoder.decode(channel, remoteAddress, msg);
        }
    }

}
```

## src/test/java/org/traccar/protocol/BlueProtocolDecoderTest.java

```java
package org.traccar.protocol;

import org.junit.jupiter.api.Test;
import org.traccar.WireDecoderHarness;
import org.traccar.model.Position;

public class BlueProtocolDecoderTest extends WireDecoderHarness {

    @Test
    public void testDecode() throws Exception {

        var decoder = wireUp(new BlueProtocolDecoder(null));

        verifyAttribute(decoder, binary(
                "AA0056860080E3E79E0C811F80000114020207170520011F00407F8005EE1938113B270000000000000000140202071705005AC7A621121F0002000100B7000080110000000000001A3A0000000001F400000000000078"),
                Position.KEY_ALARM, Position.ALARM_SOS);

        verifyAttribute(decoder, binary(
                "AA004A860080E3E79E20015FBE40148005EE193B113B263700000000000000140202080C09005AC7A621125F0002000000BB000000000000000000001A3A0007000001F400000000000008"),
                Position.KEY_IGNITION, true);

        verifyAttribute(decoder, binary(
                "AA004A860080E3E79E200160BE40148005EE193B113B263700000000000000140202080C13005AC7A62112600002000000B7000000110000000000001A3A0007000001F400000000000012"),
                Position.KEY_STATUS, 0x11);

        assertFixDecoded(decoder, binary(
                "aa00550000813f6f840b840380001032000000002001030040008005ee1938113b26f300000000000000140114082833044d27602112030002000000b70000020000000000000000650000001601f4000000000000e4"));

        assertFixDecoded(decoder, binary(
                "aa0055860080e3e79e0b840f800010320000000020010f0040008005ee197f113b26e800000000000000130c11091a2b005ac7a621120f0002000000b7000002000000000000001a3a0000000001f40000000000003f"));

    }

}
```

## Edge case: a decoder whose non-position message returns null, and its test

### src/main/java/org/traccar/protocol/R12wProtocolDecoder.java

```java
package org.traccar.protocol;

import io.netty.channel.Channel;
import org.traccar.AbstractWireDecoder;
import org.traccar.session.UnitSession;
import org.traccar.NetworkMessage;
import org.traccar.Protocol;
import org.traccar.helper.Checksum;

import java.net.SocketAddress;

public class R12wProtocolDecoder extends AbstractWireDecoder {

    public R12wProtocolDecoder(Protocol protocol) {
        super(protocol);
    }

    private void sendResponse(Channel channel, String type, String id, String data) {
        if (channel != null) {
            String sentence = String.format("$HX,%s,%s,%s,#", type, id, data);
            sentence += String.format(",%02x,\r\n", Checksum.xor(sentence));
            channel.writeAndFlush(new NetworkMessage(sentence, channel.remoteAddress()));
        }
    }

    @Override
    protected Object decode(
            Channel channel, SocketAddress remoteAddress, Object msg) throws Exception {

        String sentence = (String) msg;
        String[] values = sentence.split(",");
        String type = values[1];
        String id = values[2];

        UnitSession deviceSession = resolveUnitSession(channel, remoteAddress, id);
        if (deviceSession == null) {
            return null;
        }

        if (type.equals("0001")) {
            sendResponse(channel, "1001", id, values[3] + ",OK");
        }

        return null;
    }

}
```

### src/test/java/org/traccar/protocol/R12wProtocolDecoderTest.java

```java
package org.traccar.protocol;

import org.junit.jupiter.api.Test;
import org.traccar.WireDecoderHarness;

public class R12wProtocolDecoderTest extends WireDecoderHarness {

    @Test
    public void testDecode() throws Exception {

        var decoder = wireUp(new R12wProtocolDecoder(null));

        assertNoOutput(decoder, asciiFrame(
                "$HX,0001,860721009104316,e92c,933402042499509,55792760080,12345678,01,a8d940a9,#,50,"));

    }

}
```
