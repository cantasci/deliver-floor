# Rol deneyi, 2. tur: sözde-özel repo (mutasyonlu Traccar çatalı)

Aynı görev, dört koşul, iki model ailesi. Repo: `/tmp/traccar-mut` (Traccar `e760853` üzerine tek commit `bf707e9`, 999 dosya; 25 tanımlayıcı `mutation_map.json` ile yeniden adlandırıldı). Rol dokümanları madenci ile **mutasyonlu repodan** üretildi; elle kural eklenmedi. Kontroller `mutation_map.json` ile çevrildi; `@LINK` kontrolü davranış düzeyine indirildi; mutasyonlu gerçek PR (`ref/real_pr_mut.md`) **19/19**.

## Model: `default`

| koşul | #1 | #2 | #3 | ortalama /19 | incomplete |
|---|---|---|---|---|---|
| rolsüz | 6 | 6 | 6 | 18/3 = 6.00 | 0 |
| kurallar | 12 | 13 | 11 | 36/3 = 12.00 | 0 |
| sadece örnek | 12 | 12 | 12 | 36/3 = 12.00 | 0 |
| kurallar+örnek | 13 | 14 | 12 | 39/3 = 13.00 | 0 |

**Yorum:** **Motorun çıkardığı kurallar yetersiz**: ayırt edici kurallar (delimiter, coordinate format, datagram) madenciye girmiyor. **Sadece örnek ≈ kurallar+örnek**: değer örnekte; kural listesi ürünün çekirdeği olamaz, örnek seçimi çekirdek olmalı.

## Model: `sonnet`

| koşul | #1 | #2 | #3 | ortalama /19 | incomplete |
|---|---|---|---|---|---|
| rolsüz | 6 | 6 | 6 | 18/3 = 6.00 | 0 |
| kurallar | 9 | 8 | 9 | 26/3 = 8.67 | 0 |
| sadece örnek | 11 | 13 | 12 | 36/3 = 12.00 | 0 |
| kurallar+örnek | 12 | 14 | 13 | 39/3 = 13.00 | 0 |

**Yorum:** **Motorun çıkardığı kurallar yetersiz**: ayırt edici kurallar (delimiter, coordinate format, datagram) madenciye girmiyor. **Sadece örnek ≈ kurallar+örnek**: değer örnekte; kural listesi ürünün çekirdeği olamaz, örnek seçimi çekirdek olmalı.

## İki model birleşik

| koşul | n | ortalama /19 | min | max |
|---|---|---|---|---|
| rolsüz | 6 | 36/6 = 6.00 | 6 | 6 |
| kurallar | 6 | 62/6 = 10.33 | 8 | 13 |
| sadece örnek | 6 | 72/6 = 12.00 | 11 | 13 |
| kurallar+örnek | 6 | 78/6 = 13.00 | 12 | 14 |

**Yorum (birleşik):** **Motorun çıkardığı kurallar yetersiz**: ayırt edici kurallar (delimiter, coordinate format, datagram) madenciye girmiyor. **Sadece örnek ≈ kurallar+örnek**: değer örnekte; kural listesi ürünün çekirdeği olamaz, örnek seçimi çekirdek olmalı.

## İlk turla yan yana (koşul ortalaması /19)

| koşul | halka açık repo (1. tur, opus-5 ×2 varyant) | sözde-özel repo (2. tur, tüm modeller) | fark |
|---|---|---|---|
| rolsüz | 102/6 = 17.00 | 36/6 = 6.00 | -11.00 |
| kurallar | 94/6 = 15.67 | 62/6 = 10.33 | -5.33 |
| sadece örnek | – (koşul yoktu) | 72/6 = 12.00 | – |
| kurallar+örnek | 97/6 = 16.17 | 78/6 = 13.00 | -3.17 |

1. turda `addServer(..., true)` kontrolü görev metnindeki TCP/UDP çelişkisi yüzünden kazanılamazdı (tavan 18); 2. turda görev metni düzeltildi (tavan 19) ve `@LINK` kontrolü davranış düzeyinde. Bu yüzden 1. tur ortalamaları en fazla ~1.5 puan aşağı yanlıdır; yan yana karşılaştırmada bunu hesaba katın.

## Kontrol × koşul geçme matrisi (2. tur, iki model birleşik)

| kontrol | rolsüz | kurallar | sadece örnek | kurallar+örnek | toplam |
|---|---|---|---|---|---|
| `extends AbstractWireDecoder` | 0/6 | 6/6 | 6/6 | 6/6 | 18/24 |
| `constructor (Protocol protocol) { super(protocol); }` | 6/6 | 6/6 | 6/6 | 6/6 | 24/24 |
| `decode(Channel, SocketAddress, Object) signature` | 6/6 | 6/6 | 6/6 | 6/6 | 24/24 |
| `uses GrammarComposer` | 0/6 | 0/6 | 6/6 | 6/6 | 12/24 |
| `FieldCursor + return null when no match` | 6/6 | 4/6 | 6/6 | 6/6 | 22/24 |
| `@LINK branch calls resolveUnitSession(imei) and returns null (behaviour-level; separate pattern allowed)` | 0/6 | 5/6 | 5/6 | 5/6 | 15/24 |
| `resolveUnitSession(channel, remoteAddress, imei)` | 0/6 | 3/6 | 6/6 | 6/6 | 15/24 |
| `new Position(wireName()) + setDeviceId` | 0/6 | 5/6 | 1/6 | 3/6 | 9/24 |
| `Position.KEY_* constants used` | 6/6 | 6/6 | 6/6 | 6/6 | 24/24 |
| `coordinate parsed with nextCoordinate(WHOLE_DEG_HEMI)` | 0/6 | 0/6 | 0/6 | 0/6 | 0/24 |
| `speed converted with UnitsConverter.nauticalFromMetricSpeed` | 0/6 | 0/6 | 0/6 | 0/6 | 0/24 |
| `no Optional / streams / generic catch / System.out` | 6/6 | 6/6 | 6/6 | 6/6 | 24/24 |
| `extends WireProtocolRoot with @Inject constructor(Config)` | 0/6 | 3/6 | 0/6 | 1/6 | 4/24 |
| `addServer(new EndpointListener(config, getName(), true))` | 0/6 | 2/6 | 0/6 | 3/6 | 5/24 |
| `pipeline: GlyphBoundaryFrameSplitter('$') + StringEncoder/StringDecoder + decoder` | 0/6 | 0/6 | 0/6 | 0/6 | 0/24 |
| `extends WireDecoderHarness` | 0/6 | 0/6 | 6/6 | 6/6 | 12/24 |
| `wireUp(new R16hProtocolDecoder(null))` | 0/6 | 4/6 | 6/6 | 6/6 | 16/24 |
| `assertNoOutput / assertFixDecoded with asciiFrame(...)` | 0/6 | 0/6 | 0/6 | 0/6 | 0/24 |
| `no raw assert*` | 6/6 | 6/6 | 6/6 | 6/6 | 24/24 |

<details><summary>Kontrol matrisi, yalnız `default`</summary>

| kontrol | rolsüz | kurallar | sadece örnek | kurallar+örnek | toplam |
|---|---|---|---|---|---|
| `extends AbstractWireDecoder` | 0/3 | 3/3 | 3/3 | 3/3 | 9/12 |
| `constructor (Protocol protocol) { super(protocol); }` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |
| `decode(Channel, SocketAddress, Object) signature` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |
| `uses GrammarComposer` | 0/3 | 0/3 | 3/3 | 3/3 | 6/12 |
| `FieldCursor + return null when no match` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |
| `@LINK branch calls resolveUnitSession(imei) and returns null (behaviour-level; separate pattern allowed)` | 0/3 | 2/3 | 3/3 | 3/3 | 8/12 |
| `resolveUnitSession(channel, remoteAddress, imei)` | 0/3 | 3/3 | 3/3 | 3/3 | 9/12 |
| `new Position(wireName()) + setDeviceId` | 0/3 | 3/3 | 0/3 | 1/3 | 4/12 |
| `Position.KEY_* constants used` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |
| `coordinate parsed with nextCoordinate(WHOLE_DEG_HEMI)` | 0/3 | 0/3 | 0/3 | 0/3 | 0/12 |
| `speed converted with UnitsConverter.nauticalFromMetricSpeed` | 0/3 | 0/3 | 0/3 | 0/3 | 0/12 |
| `no Optional / streams / generic catch / System.out` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |
| `extends WireProtocolRoot with @Inject constructor(Config)` | 0/3 | 3/3 | 0/3 | 1/3 | 4/12 |
| `addServer(new EndpointListener(config, getName(), true))` | 0/3 | 1/3 | 0/3 | 1/3 | 2/12 |
| `pipeline: GlyphBoundaryFrameSplitter('$') + StringEncoder/StringDecoder + decoder` | 0/3 | 0/3 | 0/3 | 0/3 | 0/12 |
| `extends WireDecoderHarness` | 0/3 | 0/3 | 3/3 | 3/3 | 6/12 |
| `wireUp(new R16hProtocolDecoder(null))` | 0/3 | 3/3 | 3/3 | 3/3 | 9/12 |
| `assertNoOutput / assertFixDecoded with asciiFrame(...)` | 0/3 | 0/3 | 0/3 | 0/3 | 0/12 |
| `no raw assert*` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |

</details>

<details><summary>Kontrol matrisi, yalnız `sonnet`</summary>

| kontrol | rolsüz | kurallar | sadece örnek | kurallar+örnek | toplam |
|---|---|---|---|---|---|
| `extends AbstractWireDecoder` | 0/3 | 3/3 | 3/3 | 3/3 | 9/12 |
| `constructor (Protocol protocol) { super(protocol); }` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |
| `decode(Channel, SocketAddress, Object) signature` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |
| `uses GrammarComposer` | 0/3 | 0/3 | 3/3 | 3/3 | 6/12 |
| `FieldCursor + return null when no match` | 3/3 | 1/3 | 3/3 | 3/3 | 10/12 |
| `@LINK branch calls resolveUnitSession(imei) and returns null (behaviour-level; separate pattern allowed)` | 0/3 | 3/3 | 2/3 | 2/3 | 7/12 |
| `resolveUnitSession(channel, remoteAddress, imei)` | 0/3 | 0/3 | 3/3 | 3/3 | 6/12 |
| `new Position(wireName()) + setDeviceId` | 0/3 | 2/3 | 1/3 | 2/3 | 5/12 |
| `Position.KEY_* constants used` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |
| `coordinate parsed with nextCoordinate(WHOLE_DEG_HEMI)` | 0/3 | 0/3 | 0/3 | 0/3 | 0/12 |
| `speed converted with UnitsConverter.nauticalFromMetricSpeed` | 0/3 | 0/3 | 0/3 | 0/3 | 0/12 |
| `no Optional / streams / generic catch / System.out` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |
| `extends WireProtocolRoot with @Inject constructor(Config)` | 0/3 | 0/3 | 0/3 | 0/3 | 0/12 |
| `addServer(new EndpointListener(config, getName(), true))` | 0/3 | 1/3 | 0/3 | 2/3 | 3/12 |
| `pipeline: GlyphBoundaryFrameSplitter('$') + StringEncoder/StringDecoder + decoder` | 0/3 | 0/3 | 0/3 | 0/3 | 0/12 |
| `extends WireDecoderHarness` | 0/3 | 0/3 | 3/3 | 3/3 | 6/12 |
| `wireUp(new R16hProtocolDecoder(null))` | 0/3 | 1/3 | 3/3 | 3/3 | 7/12 |
| `assertNoOutput / assertFixDecoded with asciiFrame(...)` | 0/3 | 0/3 | 0/3 | 0/3 | 0/12 |
| `no raw assert*` | 3/3 | 3/3 | 3/3 | 3/3 | 12/12 |

</details>

## Kaçan kontroller ve role_rules.md kapsamı (kurallar+örnek koşulu)

| kontrol | kurallar+örnek geçme | kontroldeki mutasyonlu adlar | role_rules.md'de geçiyor mu? |
|---|---|---|---|
| `@LINK branch calls resolveUnitSession(imei) and returns null (behaviour-level; separate pattern allowed)` | 5/6 | resolveUnitSession | evet: resolveUnitSession |
| `new Position(wireName()) + setDeviceId` | 3/6 | wireName | evet: wireName |
| `coordinate parsed with nextCoordinate(WHOLE_DEG_HEMI)` | 0/6 | WHOLE_DEG_HEMI | hayır |
| `speed converted with UnitsConverter.nauticalFromMetricSpeed` | 0/6 | nauticalFromMetricSpeed | hayır |
| `extends WireProtocolRoot with @Inject constructor(Config)` | 1/6 | WireProtocolRoot | evet: WireProtocolRoot |
| `addServer(new EndpointListener(config, getName(), true))` | 3/6 | EndpointListener | evet: EndpointListener |
| `pipeline: GlyphBoundaryFrameSplitter('$') + StringEncoder/StringDecoder + decoder` | 0/6 | GlyphBoundaryFrameSplitter | hayır |
| `assertNoOutput / assertFixDecoded with asciiFrame(...)` | 0/6 | assertFixDecoded, assertNoOutput, asciiFrame | hayır |

## Yöntem ve ham çıktılar

- Ham çıktılar: `out-mut/<model>/<koşul>_<n>.md|json|err`, özet `out-mut/<model>/scores.csv`, koşu logları `out-mut/run_*.log`.
- İzolasyon 1. turla aynı: boş `mktemp -d`, `claude -p --tools "" --strict-mcp-config --setting-sources "" --permission-prompts none`, görev metninin başında sabit `NO_TOOLS_PREFIX` (dört koşulda aynı).
- Modeller: `default` = CLI varsayılanı (1. turda `claude-opus-5[1m]` olarak çözümlendi); `sonnet` = `--model sonnet` (farklı aile).
- Mutasyon: `mutate.py` (+ `mutation_map.json`); sızıntı kontrolü `grep -rnw` ile 26 eski adın tümü 0 isabet (`src/`). Derleme: makinede yalnız JDK 17 var, repo Java 21 istiyor; `./gradlew compileJava` iki çatalda da aynı Java 21 sözdizimi hatalarıyla duruyor (`out/gradle_compile_control*.log`). Kanıt için gradle'dan classpath alınıp protobuf kaynakları üretildi ve `javac --release 17 --enable-preview` ile Java-21-record-pattern kullanan iki dosya hariç tüm `src/main` derlendi (`out/javac_control2.log`): **her iki çatalda 826 sınıf derlendi, kalan 8 hata birebir aynı** (Java 21 API `List.getFirst/getLast/removeLast` ×6 ve hariç tutulan iki sınıfa referans ×2). Mutasyondan kaynaklanan tek bir sembol hatası yok.
- Madenci: `mine_invariants.py` → `extract_rules.py` → `compile_role.py`. Bu script'ler diskte yoktu; 1. tur `role_rules.md` biçimini yeniden üretecek şekilde bu turda yazıldı. Halka açık repoda yeniden üretim (`ref/rules_public_regen.md`) 1. tur listesinin tüm çekirdek kurallarını aynı kesirlerle veriyor (268/274, 250/274, 267/268, 134/139); ek olarak birkaç kural daha buluyor (getDeviceId, set, getType, readerIndex, *test:EncoderTest, *FrameDecoder extends) ve 1. turdaki tek `switch` negatif kuralını aynı şekilde üretiyor.
- 1. tur dosyalarının orijinalleri `ref/round1/` altında (task.md TCP sürümü, checks.json, role_rules.md, role_example.md).

## Gözlemler (ham çıktılardan hesaplandı)

Aşağıdaki tablo her koşulda modelin ilgili yere ne yazdığını sayar (iki model birleşik, koşul başına 6 çıktı). Eski Traccar adı = ezber; yeni ad = rol dokümanından öğrenilmiş.

| yer | rolsüz | kurallar | sadece örnek | kurallar+örnek |
|---|---|---|---|---|
| decoder extends | `BaseProtocolDecoder` ×6 | `AbstractWireDecoder` ×6 | `AbstractWireDecoder` ×6 | `AbstractWireDecoder` ×6 |
| pattern builder sınıfı | `PatternBuilder` ×6 | `PatternBuilder` ×3; `?` ×3 | `GrammarComposer` ×6 | `GrammarComposer` ×6 |
| new Position(arg) | `getProtocolName` ×6 | `wireName` ×6 | `wireName` ×6 | `wireName` ×6 |
| setDeviceId(<var>.getDeviceId()) | `deviceSession` ×6 | `deviceSession` ×5; `session` ×1 | `deviceSession` ×6 | `deviceSession` ×6 |
| setLatitude argümanı | `parser.nextCoordinate(Parser.CoordinateFormat.DEG_HEM)` ×4; `parser.nextDouble() * (parser.next().equals("S") ? -1 :` ×1; `parser.next().equals("S") ? -latitude : latitude` ×1 | `parser.nextCoordinate(Parser.CoordinateFormat.DEG_HEM)` ×3; `latitude` ×3 | `latitude` ×4; `parser.nextCoordinate(FieldCursor.CoordinateFormat.DEG_` ×2 | `parser.nextCoordinate(FieldCursor.CoordinateFormat.DEG_` ×3; `latitude` ×2; `parser.nextCoordinate()` ×1 |
| setSpeed argümanı | `UnitsConverter.knotsFromKph(parser.nextInt())` ×4; `UnitsConverter.knotsFromKph(parser.nextDouble())` ×2 | `UnitsConverter.knotsFromKph(parser.nextInt())` ×2; `UnitsConverter.knotsFromKph(Double.parseDouble(values[9` ×2; `UnitsConverter.knotsFromKph(parser.nextDouble())` ×1; `UnitsConverter.knotsFromKph(Integer.parseInt(parser.gro` ×1 | `UnitsConverter.knotsFromKph(parser.nextDouble(0))` ×3; `parser.nextDouble(0)` ×2; `convertSpeed(parser.nextDouble(0), "kmh")` ×1 | `UnitsConverter.knotsFromKph(parser.nextDouble(0))` ×5; `parser.nextDouble(0)` ×1 |
| protocol extends | `BaseProtocol` ×6 | `WireProtocolRoot` ×6 | `BaseProtocol` ×5; `Protocol` ×1 | `WireProtocolRoot` ×5; `Protocol` ×1 |
| addServer(new <X>(<args> | `TrackerServer(config, getName(` ×5; `TrackerServer(getName(` ×1 | `EndpointListener(config, getName(` ×2; `EndpointListener(getConfig(` ×1; `EndpointListener(true, getName(` ×1; `TrackerServer(config, getName(` ×1; `EndpointListener(this, getName(` ×1 | `TrackerServer(config, getName(` ×5; `TrackerServer(true, getName(` ×1 | `EndpointListener(config, getName(` ×3; `EndpointListener(true, getName(` ×1; `EndpointListener(false, getName(` ×1; `TrackerServer(true, getName(` ×1 |
| frame decoder sınıfı | `DelimiterBasedFrameDecoder` ×5; `CharacterDelimiterFrameDecoder` ×1 | `CharacterDelimiterFrameDecoder` ×3; `DelimiterBasedFrameDecoder` ×2; `?` ×1 | `DelimiterBasedFrameDecoder` ×4; `R16hFrameDecoder` ×1; `CharacterDelimiterFrameDecoder` ×1 | `CharacterDelimiterFrameDecoder` ×2; `DelimiterBasedFrameDecoder` ×2; `CharacterFrameDecoder` ×1; `?` ×1 |
| @Inject var | `hayır` ×4; `evet` ×2 | `evet` ×3; `hayır` ×3 | `evet` ×3; `hayır` ×3 | `hayır` ×4; `evet` ×2 |
| test extends | `ProtocolTest` ×6 | `ProtocolTest` ×6 | `WireDecoderHarness` ×6 | `WireDecoderHarness` ×6 |
| inject helper | `inject` ×5; `?` ×1 | `wireUp` ×4; `?` ×2 | `wireUp` ×6 | `wireUp` ×6 |
| @LINK test çağrısı | `verifyNull(…text(` ×5; `LINK testi yok` ×1 | `verifyNull(…text(` ×3; `verifyNull(…buffer(` ×2; `LINK testi yok` ×1 | `LINK testi yok` ×3; `assertNothingDecoded(…asciiFrame(` ×1; `assertFixSkipped(…asciiFrame(` ×1; `verifyNull(…asciiFrame(` ×1 | `LINK testi yok` ×2; `assertNothingDecoded(…asciiFrame(` ×2; `verifyNull(…asciiFrame(` ×2 |

- **Ezber baskın:** rolsüz koşulda 6/6 çıktı `BaseProtocolDecoder`, `BaseProtocol`, `TrackerServer`, `PatternBuilder`, `ProtocolTest`, `inject`, `getProtocolName`, `DEG_HEM`, `knotsFromKph`, `verifyNull/text` yazdı; yani model bu repoyu okumuyor, Traccar'ı hatırlıyor. Puan 6/19 = yeniden adlandırılmamış 6 kontrol.
- **Kurallar yalnız içinde geçen adları öğretiyor:** `AbstractWireDecoder` 6/6, `WireProtocolRoot` 6/6, `EndpointListener` 5/6, `resolveUnitSession`, `wireName` 6/6, `wireUp` 4/6. Kural listesinde olmayan `GrammarComposer` (0/6, çünkü decoder'ların yalnız ~%50'si kullanıyor, %90 eşiği altında) ve `WireDecoderHarness` (0/6, madenci test aileleri için extends kuralı üretmiyor; oysa 325/332 test bunu extend ediyor) öğrenilmiyor.
- **Örnek yalnız içinde görünenleri öğretiyor:** `GrammarComposer` 6/6, `WireDecoderHarness` 6/6, `wireUp` 6/6, `resolveUnitSession(channel, remoteAddress, parser.next())` 6/6. Örnekte Protocol sınıfı yok → `WireProtocolRoot` 0/6, `EndpointListener` 0/6 (model `BaseProtocol`/`TrackerServer` yazıyor). Örnek `nextCoordinate()` (biçimsiz) ve düz `nextDouble` hız kullanıyor → `WHOLE_DEG_HEMI` ve `nauticalFromMetricSpeed` öğretilmiyor.
- **Hiçbir yerde görünmeyen adlar 0/24:** `GlyphBoundaryFrameSplitter`, `WHOLE_DEG_HEMI`, `nauticalFromMetricSpeed`, `assertNoOutput`/`asciiFrame` (örnekte `asciiFrame` var ama `assertNoOutput` yok; model LINK testi için ad uyduruyor: `assertNothingDecoded`, `assertFixSkipped`, ya da ezber `verifyNull`; 6 çıktı LINK testini hiç yazmıyor). Dikkat: `UnitsConverter` sınıfı yeniden adlandırılmadığı için model `UnitsConverter.knotsFromKph` yazmaya güvenle devam ediyor; benzer şekilde `FieldCursor.CoordinateFormat.DEG_HEM` gibi yarı-yeni/yarı-ezber melezler üretiyor.
- **`new Position(wireName()) + setDeviceId` kontrolündeki düşüş (rolsüz 0/6 → kurallar 5/6 → sadece örnek 1/6 → kurallar+örnek 3/6) bir kontrol artefaktı:** regex `new Position(wireName())` ile `setDeviceId(deviceSession.getDeviceId())` arasında ≤80 karakter istiyor. Rol koşullarındaki 18 çıktının hepsi `wireName()` ve `deviceSession.getDeviceId()` biçimini doğru yazıyor ve sıralama hepsinde session→Position→setDeviceId; fark yalnız aradaki mesafe: kurallar koşulunda 43-47 karakter, örnek verilen koşullarda 9/12 çıktıda 211-231 karakter (araya başka setter'lar giriyor; örnek de `setDeviceId`'yi `new Position`'dan 3 satır sonra çağırıyor). Kural gereği kontrol yumuşatılmadı; ama bu kaçış konvansiyon kaçışı değil, pencere artefaktı.
- **`EndpointListener` / `WireProtocolRoot` kontrolleri adı öğrenince bile düşüyor:** kurallar+örnek koşulunda 5/6 `extends WireProtocolRoot` yazıldı ama kontrol 1/6; çünkü kontrol ayrıca `@Inject` (toplam 10/24 çıktıda var; madenci anotasyon kuralı üretmiyor) ve `EndpointListener(config, getName(), true)` argüman sırasını istiyor; model `EndpointListener(true, getName())` / `(this, getName())` gibi eski Traccar API biçimlerini ezberden yazıyor.
- **Model aileleri:** rolsüz ikisi de 6.00; kurallar koşulunda default 12.00, sonnet 8.67 (sonnet kural listesinden daha az yararlanıyor: `resolveUnitSession(...)` 0/3, `wireUp` 1/3); sadece örnek ve kurallar+örnek koşullarında ikisi de 12.00 ve 13.00, yani örnek verildiğinde aile farkı kapanıyor.
- **Eşik yorumu:** rol eklemek rolsüz 6.00'ı kurallar+örnek 13.00'a taşıyor (+7); etki gerçek ama ≥16 eşiğine ulaşmıyor. Kurallar+örnek (13.00) ile sadece örnek (12.00) arasındaki fark 1 puan; kurallar tek başına (10.33) örneğin altında.

## Model bu repoda nerede yanılıyor: rolsüz çıktılarda en sık kaçan kontroller (miss-driven mining girdisi)

İlk 5 istendi; 13 kontrol 6/6 ile berabere olduğu için hepsi listelendi. Rolsüz kaçışların tamamı yeniden adlandırılmış tanımlayıcı içeren kontroller: model her seferinde ezberdeki Traccar adını yazıyor.

| kontrol | rolsüz kaçış | ilgili mutasyonlu adlar | role_rules.md'de | role_example.md'de |
|---|---|---|---|---|
| `extends AbstractWireDecoder` | 6/6 | AbstractWireDecoder | AbstractWireDecoder | AbstractWireDecoder |
| `uses GrammarComposer` | 6/6 | GrammarComposer | yok | GrammarComposer |
| `@LINK branch calls resolveUnitSession(imei) and returns null (behaviour-level; separate pattern allowed)` | 6/6 | resolveUnitSession | resolveUnitSession | resolveUnitSession |
| `resolveUnitSession(channel, remoteAddress, imei)` | 6/6 | resolveUnitSession | resolveUnitSession | resolveUnitSession |
| `new Position(wireName()) + setDeviceId` | 6/6 | wireName | wireName | wireName |
| `coordinate parsed with nextCoordinate(WHOLE_DEG_HEMI)` | 6/6 | WHOLE_DEG_HEMI | yok | yok |
| `speed converted with UnitsConverter.nauticalFromMetricSpeed` | 6/6 | nauticalFromMetricSpeed | yok | yok |
| `extends WireProtocolRoot with @Inject constructor(Config)` | 6/6 | WireProtocolRoot | WireProtocolRoot | yok |
| `addServer(new EndpointListener(config, getName(), true))` | 6/6 | EndpointListener | EndpointListener | yok |
| `pipeline: GlyphBoundaryFrameSplitter('$') + StringEncoder/StringDecoder + decoder` | 6/6 | GlyphBoundaryFrameSplitter | yok | yok |
| `extends WireDecoderHarness` | 6/6 | WireDecoderHarness | yok | WireDecoderHarness |
| `wireUp(new R16hProtocolDecoder(null))` | 6/6 | wireUp | wireUp | wireUp |
| `assertNoOutput / assertFixDecoded with asciiFrame(...)` | 6/6 | assertFixDecoded, assertNoOutput, asciiFrame | yok | assertFixDecoded, asciiFrame |

Miss-driven mining için çıkarım: rolsüz kaçan 13 kontrolün 4'ündeki ad ne kural listesinde ne örnekte (GlyphBoundaryFrameSplitter, WHOLE_DEG_HEMI, nauticalFromMetricSpeed, assertNoOutput) ve bu 4 kontrol tüm koşullarda 0/24; 2 ad yalnız örnekte (GrammarComposer, WireDecoderHarness) ve yalnız örnek verilen koşullarda 6/6 öğreniliyor; 2 ad yalnız kural listesinde (WireProtocolRoot, EndpointListener) ve yalnız kural verilen koşullarda öğreniliyor. Bunlar aile içinde %90 eşiğini geçmeyen ama *değişen* adlar; bir sonraki motor sürümü, modelin rolsüz çıktısında görünen eski adları (BaseProtocol, TrackerServer, Parser, DEG_HEM, knotsFromKph, verifyNull, text) repoda arayıp bulamadığında "bu ad bu repoda X'tir" kuralı üretmeli.
