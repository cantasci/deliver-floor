# Role: Traccar protocol developer (engine v2)

Follow these project conventions. Each rule was mined from the repository; the fraction shows how many files obey it.

## Conventions

- every *ProtocolEncoder has a matching *ProtocolDecoder  (57/58)
- every *ProtocolDecoder has a matching *Protocol  (267/273)
- every *FrameDecoder has a matching *ProtocolDecoder  (71/73)
- every *Protocol has a matching *ProtocolDecoder  (267/267)
- every *ProtocolDecoder has a test file  (266/273)
- *ProtocolDecoder extends/implements AbstractWireDecoder  (250/273)
- *FrameDecoder extends/implements BaseFrameDecoder  (68/73)
- *Protocol extends/implements WireProtocolRoot  (267/267)
- *ProtocolEncoder call getType()  (57/58)
- *ProtocolDecoder call resolveUnitSession()  (267/273)
- *ProtocolDecoder call Position()  (267/273)
- *ProtocolDecoder call wireName()  (267/273)
- *ProtocolDecoder call getDeviceId()  (267/273)
- *ProtocolDecoder call setDeviceId()  (267/273)
- *ProtocolDecoder call setLongitude()  (264/273)
- *ProtocolDecoder call setLatitude()  (264/273)
- *ProtocolDecoder call setValid()  (260/273)
- *ProtocolDecoder call set()  (249/273)
- *ProtocolDecoder call setSpeed()  (247/273)
- *FrameDecoder call readerIndex()  (69/73)
- *Protocol call getName()  (267/267)
- *Protocol call installChainHandlers()  (267/267)
- *Protocol call addLast()  (267/267)
- *Protocol call EndpointListener()  (266/267)
- *Protocol call addServer()  (266/267)
- *test:DecoderTest call wireUp()  (325/332)
- *test:DecoderTest call testDecode()  (321/332)
- *test:EncoderTest call setType()  (47/50)
- *test:EncoderTest call Command()  (47/50)
- *test:EncoderTest call setDeviceId()  (46/50)
- *test:EncoderTest call wireUp()  (46/50)
- *Protocol never use `switch\s*\(` (used in 206 files elsewhere)  (267/267)
- Test classes end with 'Test'  (425/426 test files)
- Tests use JUnit5  (425/426 test files)
- Indentation uses 4 spaces  (1470/1475 files)
- decode() returns null when the parser does not match  (134/139)
- Decoders never use Optional or streams; no generic catch(Exception); no System.out/printStackTrace  (344/346)
- Attribute keys use Position.KEY_* constants where a standard key exists  (247/249)

## Alternatives (patterns below the 90% bar but dominant within the family)

- *Protocol: addLast(…) argument 1: `new StringEncoder` 128/267, `new StringDecoder` 127/267, `new GlyphBoundaryFrameSplitter` 54/267
- *Protocol: EndpointListener(…) argument 3: `false` 244/266, `true` 56/266
- *ProtocolDecoder: readUnsignedByte() in 112/273 files, compile() in 144/273 files (rarely both: choose one style)
- *ProtocolDecoder: set(…) argument 1: `Position.KEY_SATELLITES` 149/246, `Position.KEY_BATTERY` 127/246, `Position.KEY_ODOMETER` 117/246, `"…"` 106/246, `Position.KEY_RSSI` 99/246, `Position.KEY_POWER` 94/246, `Position.KEY_IGNITION` 92/246, `Position.PREFIX_ADC` 90/246, `Position.KEY_EVENT` 77/246, `Position.KEY_HDOP` 72/246
- *ProtocolDecoder: set(…) argument 2: `parser.nextInt` 91/246, `buf.readUnsignedByte` 76/246, `parser.nextDouble` 68/246, `parser.next` 68/246, `BitUtil.check` 58/246
- *ProtocolDecoder: setSpeed(…) argument 1: `UnitsConverter.nauticalFromMetricSpeed` 145/245, `parser.nextDouble` 60/245
- *ProtocolDecoder: setTime(…) argument 1: `parser.nextDateTime` 89/242, `dateBuilder.getDate` 80/242, `new Date` 64/242
- *ProtocolDecoder: FieldCursor(…) argument 2: `(String) msg` 71/139, `sentence` 52/139
- *ProtocolDecoder: NetworkMessage(…) argument 2: `remoteAddress` 97/135, `channel.remoteAddress` 40/135
- *ProtocolDecoder: nextInt(…) argument 1: `(no argument)` 84/126, `<number>` 65/126
- *ProtocolDecoder: nextDouble(…) argument 1: `<number>` 82/123, `(no argument)` 75/123
- *ProtocolDecoder: toString(…) argument 1: `StandardCharsets.US_ASCII` 53/99, `(no argument)` 43/99
- *ProtocolDecoder: getLastLocation(…) argument 2: `null` 60/99, `position.getDeviceTime` 30/99
- *ProtocolDecoder: nextDateTime(…) argument 1: `(no argument)` 53/96, `FieldCursor.DateTimeFormat.DMY_HMS` 34/96
- *ProtocolDecoder: from(…) argument 2: `<number>` 30/77, `mnc` 28/77, `Integer.parseInt` 19/77
- *ProtocolDecoder: buffer(…) argument 1: `(no argument)` 54/71, `<number>` 20/71
- *ProtocolDecoder: setNetwork(…) argument 1: `new Network` 48/69, `network` 34/69
- *ProtocolDecoder: Network(…) argument 1: `(no argument)` 34/69, `CellTower.from` 29/69
- *ProtocolDecoder: writeByte(…) argument 1: `<number>` 42/61, `type` 23/61, `'C'` 13/61

## Test conventions

- *test:DecoderTest extends/implements WireDecoderHarness  (331/332)
- *test:DecoderTest commonly calls assertFixDecoded()  (206/332)
- *test:DecoderTest commonly calls binary()  (175/332)
- *test:DecoderTest commonly calls assertNoOutput()  (149/332)
- *test:DecoderTest commonly calls asciiFrame()  (126/332)
- *test:DecoderTest commonly calls position()  (76/332)
- *test:DecoderTest commonly calls verifyAttributes()  (68/332)
