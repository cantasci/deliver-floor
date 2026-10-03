# Rol deneyi sonuçları

Görev: traccar/traccar commit `6918e9f` ("Implement R16H protocol", 20 Mayıs 2026) türevi. 19 kontrol; gerçek PR `ref/real_pr.md` ile scorer'dan **19/19** aldı.

Koşullar arasında tek fark `--append-system-prompt` eki; `task.md` metni üç koşulda birebir aynı.

## Model: `default`

| koşul | #1 | #2 | #3 | ortalama /19 | incomplete |
|---|---|---|---|---|---|
| rolsüz | 17 | 17 | 16 | 50/3 = 16.67 | 0 |
| kurallar | 15 | 16 | 15 | 46/3 = 15.33 | 0 |
| kurallar+örnek | 16 | 14 | 16 | 46/3 = 15.33 | 0 |

En çok kaçırılan 3 kural (yalnız complete çıktılar):

- **rolsüz**: `addServer(new TrackerServer(config, getName(), true))` (3/3); `pipeline: CharacterDelimiterFrameDecoder('$') + StringEncoder/StringDecoder + decoder` (2/3); `coordinate parsed with nextCoordinate(DEG_HEM)` (1/3)
- **kurallar**: `coordinate parsed with nextCoordinate(DEG_HEM)` (3/3); `addServer(new TrackerServer(config, getName(), true))` (3/3); `pipeline: CharacterDelimiterFrameDecoder('$') + StringEncoder/StringDecoder + decoder` (3/3)
- **kurallar+örnek**: `@LINK handled via getDeviceSession then return null` (3/3); `addServer(new TrackerServer(config, getName(), true))` (3/3); `pipeline: CharacterDelimiterFrameDecoder('$') + StringEncoder/StringDecoder + decoder` (3/3)

**Yorum:** Rolsüz koşul zaten ≥15: halka açık repoda rolün katkısı düşük; model Traccar kalıplarını eğitim verisinden biliyor. **Özel repoda tekrar gerek.**

## Model: `opus`

| koşul | #1 | #2 | #3 | ortalama /19 | incomplete |
|---|---|---|---|---|---|
| rolsüz | 17 | 18 | 17 | 52/3 = 17.33 | 0 |
| kurallar | 18 | 15 | 15 | 48/3 = 16.00 | 0 |
| kurallar+örnek | 17 | 17 | 17 | 51/3 = 17.00 | 0 |

En çok kaçırılan 3 kural (yalnız complete çıktılar):

- **rolsüz**: `addServer(new TrackerServer(config, getName(), true))` (3/3); `pipeline: CharacterDelimiterFrameDecoder('$') + StringEncoder/StringDecoder + decoder` (2/3)
- **kurallar**: `addServer(new TrackerServer(config, getName(), true))` (3/3); `@LINK handled via getDeviceSession then return null` (2/3); `coordinate parsed with nextCoordinate(DEG_HEM)` (2/3)
- **kurallar+örnek**: `addServer(new TrackerServer(config, getName(), true))` (3/3); `pipeline: CharacterDelimiterFrameDecoder('$') + StringEncoder/StringDecoder + decoder` (2/3); `@LINK handled via getDeviceSession then return null` (1/3)

**Yorum:** Rolsüz koşul zaten ≥15: halka açık repoda rolün katkısı düşük; model Traccar kalıplarını eğitim verisinden biliyor. **Özel repoda tekrar gerek.**

## Tüm modeller birleşik

| koşul | n | ortalama /19 | min | max |
|---|---|---|---|---|
| rolsüz | 6 | 102/6 = 17.00 | 16 | 18 |
| kurallar | 6 | 94/6 = 15.67 | 15 | 18 |
| kurallar+örnek | 6 | 97/6 = 16.17 | 14 | 17 |

**Yorum:** Rolsüz koşul zaten ≥15: halka açık repoda rolün katkısı düşük; model Traccar kalıplarını eğitim verisinden biliyor. **Özel repoda tekrar gerek.**

## Yöntem ve ham çıktılar

- Ham çıktılar: `out/<model>/<koşul>_<n>.md` (model cevabı), `.json` (scorer sonucu), `.err` (stderr), `scores.csv` (özet). `incomplete` çıkan denemeler `<koşul>_<n>.incompleteK.md` olarak saklandı ve sayılmadı.
- İzolasyon: her çağrı `mktemp -d` ile açılan boş dizinden, `claude -p --tools "" --strict-mcp-config --setting-sources "" --permission-prompts none` ile koştu. `--tools ""` tüm yerleşik araçları kapatır (stream-json init mesajında `tools: []`, `mcp_servers: []` doğrulandı; ayrı bir probe'da model dizindeki dosyayı okuyamadı). `--setting-sources ""` kullanıcı/proje ayarlarını, hook'ları ve CLAUDE.md'yi devre dışı bırakır.
- Modeller: `default` = CLI'nin varsayılan modeli (`--model` verilmedi), `--output-format json` ile çözümlenen kimlik **`claude-opus-5[1m]`**; `opus` = `--model opus`, çözümlenen kimlik **`claude-opus-5`**. İki koşu aynı model ailesinin 1M-bağlam ve standart varyantı; farklı model karşılaştırması sayılmaz.
- **Görev metnine eklenen ön ek (üç koşulda birebir aynı):** `--tools ""` ile araçlar kapalı olsa da CLI'nin varsayılan sistem promptu modeli ajan gibi konumlandırıyor; ilk denemede model metin içinde sahte araç çağrıları (`<invoke name="Bash">` vb.) üretip duruyordu (5 denemenin 4'ü incomplete, `out/_aborted_attempt1/`). Bu yüzden talimattaki yedek yol uygulandı: kullanıcı mesajının başına *"Hiçbir aracı kullanma, sadece cevap ver. Do not use or call any tools; answer directly and completely in this single message."* satırı eklendi. Ön ek `run_cc_eval.sh` içindeki `NO_TOOLS_PREFIX` değişkenidir; `task.md` dosyası değişmedi. Ön ek sonrası 18/18 çağrı ilk denemede complete geldi.
- Kontroller: `checks.json`; puanlayıcı: `scorer.py`; koşucu: `run_cc_eval.sh`.

## Kontrol × koşul geçme matrisi (iki model birleşik, complete çıktılar)

| kontrol | rolsüz | kurallar | kurallar+örnek | toplam |
|---|---|---|---|---|
| `extends BaseProtocolDecoder` | 6/6 | 6/6 | 6/6 | 18/18 |
| `constructor (Protocol protocol) { super(protocol); }` | 6/6 | 6/6 | 6/6 | 18/18 |
| `decode(Channel, SocketAddress, Object) signature` | 6/6 | 6/6 | 6/6 | 18/18 |
| `uses PatternBuilder` | 6/6 | 6/6 | 6/6 | 18/18 |
| `Parser + return null when no match` | 6/6 | 6/6 | 6/6 | 18/18 |
| `@LINK handled via getDeviceSession then return null` | 6/6 | 2/6 | 2/6 | 10/18 |
| `getDeviceSession(channel, remoteAddress, imei)` | 6/6 | 6/6 | 6/6 | 18/18 |
| `new Position(getProtocolName()) + setDeviceId` | 6/6 | 6/6 | 5/6 | 17/18 |
| `Position.KEY_* constants used` | 6/6 | 6/6 | 6/6 | 18/18 |
| `coordinate parsed with nextCoordinate(DEG_HEM)` | 5/6 | 1/6 | 6/6 | 12/18 |
| `speed converted with UnitsConverter.knotsFromKph` | 6/6 | 6/6 | 6/6 | 18/18 |
| `no Optional / streams / generic catch / System.out` | 6/6 | 6/6 | 6/6 | 18/18 |
| `extends BaseProtocol with @Inject constructor(Config)` | 5/6 | 6/6 | 5/6 | 16/18 |
| `addServer(new TrackerServer(config, getName(), true))` | 0/6 | 0/6 | 0/6 | 0/18 |
| `pipeline: CharacterDelimiterFrameDecoder('$') + StringEncoder/StringDecoder + decoder` | 2/6 | 1/6 | 1/6 | 4/18 |
| `extends ProtocolTest` | 6/6 | 6/6 | 6/6 | 18/18 |
| `inject(new R16hProtocolDecoder(null))` | 6/6 | 6/6 | 6/6 | 18/18 |
| `verifyNull / verifyPosition with text(...)` | 6/6 | 6/6 | 6/6 | 18/18 |
| `no raw assert*` | 6/6 | 6/6 | 6/6 | 18/18 |

## Kontrol düzeyinde gözlemler (ham çıktılardan)

- **`addServer(new TrackerServer(config, getName(), true))` 0/18 geçti ve kazanılamaz durumda.** Traccar'da üçüncü parametre `datagram`dır; gerçek PR `true` ile **UDP** sunucu kaydeder, oysa `task.md` "registers a TCP server" diyor. 16 çıktı `..., false)` yazdı, 2 çıktı eski iki-argümanlı `TrackerServer(false, getName())` kurucusunu kullandı. Modeller görev metnine uydu; kontrol gerçek PR'a. Bu görev metniyle fiili tavan **18/19**.
- **Pipeline kontrolü** (`CharacterDelimiterFrameDecoder` → `StringEncoder` → `StringDecoder` → decoder) 4/18 geçti. 14/18 çıktı Traccar'ın kendi `CharacterDelimiterFrameDecoder` sınıfı yerine Netty'nin `DelimiterBasedFrameDecoder`'ını seçti; çoğu ayrıca `StringDecoder`'ı `StringEncoder`'dan önce ekledi. Ne kural listesi ne örnek bu sınıfı içeriyor (örnek yalnız decoder+test; Protocol sınıfı yok), dolayısıyla rol bu kuralı öğretemezdi. Koşullar arası fark yok (2/6, 1/6, 1/6).
- **`@LINK` kontrolü** rol eklenince düştü: rolsüz 6/6, kurallar 2/6, kurallar+örnek 2/6. Rolsüz 6 çıktının hepsi gerçek PR gibi `if (sentence.startsWith("@LINK,")) { getDeviceSession(...); return null; }` yazdı; rol eklenen 12 çıktının 10'u `@LINK` için ayrı bir `PatternBuilder` deseni (`PATTERN_LINK`/`PATTERN_LOGIN`) tanımladı (bunların 2'si regex toleransı sayesinde yine geçti). Davranış eşdeğer; kontrol stil duyarlı. Kural listesindeki "decode() returns null when the parser does not match" maddesi ve örnekteki tek-desen yapısı bu stile itmiş görünüyor. Kurallar koşulunun rolsüzden düşük çıkmasının ana nedeni bu.
- **`nextCoordinate(DEG_HEM)`**: rolsüz 5/6, kurallar 1/6, kurallar+örnek 6/6. Yalnız kural listesi verildiğinde modeller koordinatı elle hesapladı (`opus/rules_2`, `opus/rules_3`: `nextDouble() * (S ? -1 : 1)`; `default/rules_1..3`: yerel `latitude` değişkeni). Örnekteki `parser.nextCoordinate()` çağrısı bu davranışı tamamen düzeltti. Bu kontrol özelinde değer kuralda değil, örnekte.
- Kural listesindeki maddelerin karşılığı olan 13 kontrol (extends, constructor, decode imzası, PatternBuilder, return null, getDeviceSession, KEY_*, knotsFromKph, Optional/stream yasağı, ProtocolTest, inject, verifyNull/verifyPosition, assert yasağı) **rolsüz koşulda da 6/6 geçiyor**. Madenlenen kurallar modelin zaten bildiği şeyleri söylüyor; ayırt edici olan (CharacterDelimiterFrameDecoder, DEG_HEM biçimi, datagram bayrağı) kurallarda yok.
- n=3 ile koşullar arası 1-2 puanlık farklar gürültü sınırında; bu raporda yalnız 6/6 ↔ 1-2/6 gibi büyük kaymalar yorumlandı.
