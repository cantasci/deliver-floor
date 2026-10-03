# Rol deneyi, 3. tur: motor v2 (Deney A) ve araçlar açık ajan taban çizgisi (Deney B)

Repo: `/tmp/traccar-mut` (2. turdaki mutasyonlu çatal). Görev ve kontroller 2. turla aynı (`task.md`, `checks.json`). Rol dokümanları motor v2 ile üretildi: `role_rules_v2.md` (84 kural satırı; v1 kuralları + alternatifler + test kuralları + miss-driven bölüm), `role_examples_v2.md` (184 satır, 5 dosya: Xrb28Protocol.java, ArnaviProtocolDecoder.java, BlueProtocolDecoderTest.java, R12wProtocolDecoder.java, R12wProtocolDecoderTest.java). Elle eklenen satır yok.

## Deney A: araçlar kapalı, motor v2

Parantez içindeki sayı: `new Position(wireName()) + setDeviceId` kontrolünün 80 yerine 400 karakter penceresiyle puanı (yalnız ek sütun; ana skor değişmedi). `rolsüz` koşulu 2. turun birebir aynı koşulu olduğundan (aynı görev, kontroller, izolasyon, modeller) 2. tur çıktıları kopyalanarak kullanıldı, yeniden koşulmadı.

### Model `default`

| koşul | #1 | #2 | #3 | ortalama /19 | ort. pencere=400 |
|---|---|---|---|---|---|
| rolsüz | 6 | 6 | 6 | 18/3 = 6.00 | 18/3 = 6.00 |
| kurallar v2 | 16 | 18 | 18 | 52/3 = 17.33 | 52/3 = 17.33 |
| örnekler v2 | 14 | 14 | 14 | 42/3 = 14.00 | 42/3 = 14.00 |
| kurallar+örnekler v2 | 19 | 19 | 19 | 57/3 = 19.00 | 57/3 = 19.00 |
| kurallar v2 − miss-driven (ablasyon) | 15 | 16 |  | 31/2 = 15.50 | 31/2 = 15.50 |

### Model `sonnet`

| koşul | #1 | #2 | #3 | ortalama /19 | ort. pencere=400 |
|---|---|---|---|---|---|
| rolsüz | 6 | 6 | 6 | 18/3 = 6.00 | 18/3 = 6.00 |
| kurallar v2 | 17 | 12 | 12 | 41/3 = 13.67 | 41/3 = 13.67 |
| örnekler v2 | 12 | 11 | 13 | 36/3 = 12.00 | 36/3 = 12.00 |
| kurallar+örnekler v2 | 17 | 17 | 16 | 50/3 = 16.67 | 50/3 = 16.67 |
| kurallar v2 − miss-driven (ablasyon) | 11 | 12 |  | 23/2 = 11.50 | 23/2 = 11.50 |

### İki model birleşik (Deney A)

| koşul | n | ortalama /19 | min | max | ort. pencere=400 |
|---|---|---|---|---|---|
| rolsüz | 6 | 36/6 = 6.00 | 6 | 6 | 36/6 = 6.00 |
| kurallar v2 | 6 | 93/6 = 15.50 | 12 | 18 | 93/6 = 15.50 |
| örnekler v2 | 6 | 78/6 = 13.00 | 11 | 14 | 78/6 = 13.00 |
| kurallar+örnekler v2 | 6 | 107/6 = 17.83 | 16 | 19 | 107/6 = 17.83 |
| kurallar v2 − miss-driven (ablasyon) | 4 | 54/4 = 13.50 | 11 | 16 | 54/4 = 13.50 |

**Kapı A** (kurallar+örnekler v2 birleşik ≥16): ortalama **17.83** → GEÇTİ.

### 2. turla yan yana (birleşik ortalama /19)

| | 2. tur (v1) | 3. tur (v2) |
|---|---|---|
| rolsüz → rolsüz | 36/6 = 6.00 | 36/6 = 6.00 |
| kurallar v1 → kurallar v2 | 62/6 = 10.33 | 93/6 = 15.50 |
| sadece örnek v1 → örnekler v2 | 72/6 = 12.00 | 78/6 = 13.00 |
| kurallar+örnek v1 → kurallar+örnekler v2 | 78/6 = 13.00 | 107/6 = 17.83 |

### Kapsama raporu (`coverage.json`)

Hedef küme: üç ailede (Protocol, ProtocolDecoder, DecoderTest) dosyaların ≥%20'sinde geçen 160 tanımlayıcı. Kapsama = dokümanda (kural veya örnek) görünen hedef yüzdesi.

| doküman | kapsama | eşleşen skor (kurallar+örnek birleşik) |
|---|---|---|
| v1 kurallar | 17.5% | – |
| v1 örnek | 41.2% | – |
| **v1 tam (2. tur)** | **46.9%** | 78/6 = 13.00 |
| v2 kurallar (miss dahil) | 55.6% | 93/6 = 15.50 (yalnız kurallar) |
| v2 örnekler | 49.4% | 78/6 = 13.00 (yalnız örnekler) |
| **v2 tam (3. tur)** | **78.8%** | 107/6 = 17.83 |
| v2 tam − miss-driven | 77.5% | – |

v2 tam dokümanda hâlâ eksik hedefler (ilk 30): `ByteBufUtil`, `DateBuilder`, `KEY_BATTERY_LEVEL`, `KEY_INPUT`, `LinkedList`, `List`, `PATTERN`, `PREFIX_TEMP`, `Pattern`, `S`, `Unpooled`, `add`, `addAlarm`, `any`, `expression`, `i`, `imei`, `index`, `length`, `matches`, `nextCoordinate`, `positions`, `readSlice`, `readUnsignedInt`, `readUnsignedShort`, `readableBytes`, `regex`, `response`, `setAltitude`, `setCourse`

### Kontrol × koşul matrisi (Deney A, iki model birleşik)

| kontrol | rolsüz | kurallar v2 | örnekler v2 | kurallar+örnekler v2 | kurallar v2 − miss-driven (ablasyon) |
|---|---|---|---|---|---|
| `extends AbstractWireDecoder` | 0/6 | 6/6 | 6/6 | 6/6 | 4/4 |
| `constructor (Protocol protocol) { super(protocol); }` | 6/6 | 3/6 | 6/6 | 6/6 | 2/4 |
| `decode(Channel, SocketAddress, Object) signature` | 6/6 | 6/6 | 6/6 | 6/6 | 4/4 |
| `uses GrammarComposer` | 0/6 | 6/6 | 0/6 | 6/6 | 0/4 |
| `FieldCursor + return null when no match` | 6/6 | 6/6 | 4/6 | 6/6 | 4/4 |
| `@LINK branch calls resolveUnitSession(imei) and returns null (behaviour-level; separate pattern allowed)` | 0/6 | 6/6 | 5/6 | 6/6 | 4/4 |
| `resolveUnitSession(channel, remoteAddress, imei)` | 0/6 | 4/6 | 3/6 | 5/6 | 3/4 |
| `new Position(wireName()) + setDeviceId` | 0/6 | 3/6 | 0/6 | 6/6 | 1/4 |
| `Position.KEY_* constants used` | 6/6 | 6/6 | 6/6 | 6/6 | 4/4 |
| `coordinate parsed with nextCoordinate(WHOLE_DEG_HEMI)` | 0/6 | 3/6 | 0/6 | 3/6 | 0/4 |
| `speed converted with UnitsConverter.nauticalFromMetricSpeed` | 0/6 | 6/6 | 0/6 | 6/6 | 4/4 |
| `no Optional / streams / generic catch / System.out` | 6/6 | 6/6 | 6/6 | 6/6 | 4/4 |
| `extends WireProtocolRoot with @Inject constructor(Config)` | 0/6 | 3/6 | 6/6 | 6/6 | 2/4 |
| `addServer(new EndpointListener(config, getName(), true))` | 0/6 | 4/6 | 6/6 | 6/6 | 2/4 |
| `pipeline: GlyphBoundaryFrameSplitter('$') + StringEncoder/StringDecoder + decoder` | 0/6 | 3/6 | 0/6 | 3/6 | 2/4 |
| `extends WireDecoderHarness` | 0/6 | 6/6 | 6/6 | 6/6 | 4/4 |
| `wireUp(new R16hProtocolDecoder(null))` | 0/6 | 4/6 | 6/6 | 6/6 | 2/4 |
| `assertNoOutput / assertFixDecoded with asciiFrame(...)` | 0/6 | 6/6 | 6/6 | 6/6 | 4/4 |
| `no raw assert*` | 6/6 | 6/6 | 6/6 | 6/6 | 4/4 |

### Miss-driven mining: üretilen kurallar ve ablasyon

Miss-driven madenci 2. turun 6 rolsüz çıktısından **16 'X yerine Y' kuralı** (hepsi otomatik eşleşme; `mutation_map.json` ile karşılaştırıldığında 16/16 doğru) ve **4 bilinmeyen sapma** üretti (`ref/miss_rules_r3.json`). Bilinmeyenler: `KEY_ARCHIVE`, `DEG_HEM` (seçenekler listelendi), `wrappedBuffer`, `copiedBuffer`.

Ablasyon (`rules_v2_nomiss`, RUNS=2, sistem eki = v2 kurallar **miss-driven bölümü çıkarılmış**, örnek yok): birleşik 54/4 = 13.50 ↔ `rules_v2` 93/6 = 15.50 → miss-driven bölümünün katkısı **+2.00** puan.

## Deney B: araçlar açık, gerçek taban çizgisi

Çalışma dizini: her koşu için `/tmp/traccar-r3` deposundan taze `git worktree`; bu depo mutasyonlu çatalın `r3-base` ağacının (R16h dosyaları ve `PortConfigSuffix` port girdisi çıkarılmış) **geçmişsiz tek commit'lik** kopyasıdır, koşu sonunda worktree silinir. Araçlar: Read/Glob/Grep/Write/Edit + salt-okur Bash (ls, grep, rg, find, cat, head, tail, wc, sed -n); `--permission-mode acceptEdits`, `--max-turns 80`, `--setting-sources ""`, `--strict-mcp-config`. Görev `task_agent.md` (son cümle: "Create the three files in the repository."). Kayıt: `--output-format stream-json`.

### Model `default`

| koşul | # | uyum /19 | token (giriş+çıkış) | giriş | çıkış | araç çağrısı | tur | süre s | açılan dosya (Read+Bash) | Grep/Glob | maliyet $ | sonuç |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ajan, rolsüz | 1 | 19 | 1391539 | 1371383 | 20156 | 49 | 50 | 291.0 | 17 | 6 | 1.763 | success |
| ajan, rolsüz | 2 | 19 | 774509 | 760121 | 14388 | 37 | 38 | 203.0 | 13 | 0 | 1.157 | success |
| ajan, rolsüz | 3 | 18 | 1383335 | 1365752 | 17583 | 46 | 47 | 266.0 | 13 | 7 | 1.593 | success |
| ajan, rol v2 | 1 | 19 | 520605 | 511903 | 8702 | 22 | 23 | 126.0 | 6 | 0 | 0.831 | success |
| ajan, rol v2 | 2 | 19 | 627300 | 614582 | 12718 | 20 | 21 | 186.0 | 10 | 0 | 1.051 | success |
| ajan, rol v2 | 3 | 18 | 455093 | 445133 | 9960 | 21 | 22 | 144.0 | 9 | 1 | 0.817 | success |

### Model `sonnet`

| koşul | # | uyum /19 | token (giriş+çıkış) | giriş | çıkış | araç çağrısı | tur | süre s | açılan dosya (Read+Bash) | Grep/Glob | maliyet $ | sonuç |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ajan, rolsüz | 1 | 19 | 2130481 | 2109674 | 20807 | 51 | 52 | 278.0 | 17 | 8 | 0.872 | success |
| ajan, rolsüz | 2 | 17 | 2470227 | 2445425 | 24802 | 61 | 62 | 271.0 | 17 | 8 | 0.983 | success |
| ajan, rolsüz | 3 | 14 | 2020370 | 2005821 | 14549 | 52 | 53 | 210.0 | 13 | 14 | 0.822 | success |
| ajan, rol v2 | 1 | 19 | 2314109 | 2296703 | 17406 | 51 | 52 | 202.0 | 16 | 8 | 0.918 | success |
| ajan, rol v2 | 2 | 19 | 1699785 | 1681195 | 18590 | 34 | 35 | 209.0 | 8 | 19 | 0.774 | success |
| ajan, rol v2 | 3 | 19 | 2040120 | 2024096 | 16024 | 47 | 48 | 183.0 | 13 | 11 | 0.786 | success |

### Koşul başına özet (Deney B, iki model birleşik)

| koşul | n | uyum ort (min–max) | token ort (min–max) | araç çağrısı ort (min–max) | süre s ort (min–max) | açılan dosya ort | maliyet $ ort |
|---|---|---|---|---|---|---|---|
| ajan, rolsüz | 6 | 17.7 (14–19) | 1695076.8 (774509–2470227) | 49.3 (37–61) | 253.2 (203.0–291.0) | 15.0 | 1.20 |
| ajan, rol v2 | 6 | 18.8 (18–19) | 1276168.7 (455093–2314109) | 32.5 (20–51) | 175.0 (126.0–209.0) | 10.3 | 0.86 |

| Kapı B ölçütü | değer | sonuç |
|---|---|---|
| uyum: rol v2 ≥ rolsüz | 18.83 ≥ 17.67 | ✓ |
| token oranı (rol/rolsüz) ≤ 0.60 | 0.75 | ✗ |
| araç çağrısı oranı ≤ 0.50 | 0.66 | ✗ |
| **Kapı B** | uyum VE (token VEYA araç) | **GEÇMEDİ** |

Model bazında Kapı B:

| model | uyum rolsüz → rol v2 | token oranı | araç oranı | süre oranı | Kapı B |
|---|---|---|---|---|---|
| `default` | 18.67 → 18.67 | 0.45 | 0.48 | 0.60 | GEÇTİ |
| `sonnet` | 16.67 → 19.00 | 0.91 | 0.80 | 0.78 | GEÇMEDİ |

### Kontrol × koşul matrisi (Deney B)

| kontrol | ajan, rolsüz | ajan, rol v2 |
|---|---|---|
| `extends AbstractWireDecoder` | 6/6 | 6/6 |
| `constructor (Protocol protocol) { super(protocol); }` | 5/6 | 6/6 |
| `decode(Channel, SocketAddress, Object) signature` | 6/6 | 6/6 |
| `uses GrammarComposer` | 5/6 | 6/6 |
| `FieldCursor + return null when no match` | 5/6 | 6/6 |
| `@LINK branch calls resolveUnitSession(imei) and returns null (behaviour-level; separate pattern allowed)` | 6/6 | 6/6 |
| `resolveUnitSession(channel, remoteAddress, imei)` | 5/6 | 6/6 |
| `new Position(wireName()) + setDeviceId` | 6/6 | 5/6 |
| `Position.KEY_* constants used` | 6/6 | 6/6 |
| `coordinate parsed with nextCoordinate(WHOLE_DEG_HEMI)` | 5/6 | 6/6 |
| `speed converted with UnitsConverter.nauticalFromMetricSpeed` | 6/6 | 6/6 |
| `no Optional / streams / generic catch / System.out` | 6/6 | 6/6 |
| `extends WireProtocolRoot with @Inject constructor(Config)` | 6/6 | 6/6 |
| `addServer(new EndpointListener(config, getName(), true))` | 6/6 | 6/6 |
| `pipeline: GlyphBoundaryFrameSplitter('$') + StringEncoder/StringDecoder + decoder` | 4/6 | 6/6 |
| `extends WireDecoderHarness` | 6/6 | 6/6 |
| `wireUp(new R16hProtocolDecoder(null))` | 6/6 | 6/6 |
| `assertNoOutput / assertFixDecoded with asciiFrame(...)` | 5/6 | 6/6 |
| `no raw assert*` | 6/6 | 6/6 |

### Ajan keşfe rağmen neyi bulamıyor? (agent_no_role'ün kaçırdığı kontroller)

- `pipeline: GlyphBoundaryFrameSplitter('$') + StringEncoder/StringDecoder + decoder`: 2/6 koşuda kaçtı
- `constructor (Protocol protocol) { super(protocol); }`: 1/6 koşuda kaçtı
- `uses GrammarComposer`: 1/6 koşuda kaçtı
- `FieldCursor + return null when no match`: 1/6 koşuda kaçtı
- `resolveUnitSession(channel, remoteAddress, imei)`: 1/6 koşuda kaçtı
- `coordinate parsed with nextCoordinate(WHOLE_DEG_HEMI)`: 1/6 koşuda kaçtı
- `assertNoOutput / assertFixDecoded with asciiFrame(...)`: 1/6 koşuda kaçtı

## Yorum

**A ≥16, B'de uyum eşit/yüksek ama maliyet farkı eşiği geçmiyor → ürün değeri yalnız maliyet/tutarlılık değil, keşfin kaçırdıkları; B'deki kaçırılan kontrol listesine göre yeniden konumlan.**

## Gözlemler

- **Deney A:** kurallar+örnekler v2 default'ta 19/19/19, sonnet'te 17/17/16; birleşik 17.83 (2. tur v1: 13.00, +4.83). Kapsama 46.9% → 78.8%. 400-karakter pencere sütunu hiçbir puanı değiştirmedi: v2 dokümanıyla modeller `setDeviceId`'yi Position'dan hemen sonra yazıyor (örnek demetindeki decoder öyle).
- **A'da hâlâ kaçanlar (kurallar+örnekler v2, 6 çıktı):** `nextCoordinate(WHOLE_DEG_HEMI)` 3/6 ve `GlyphBoundaryFrameSplitter` pipeline 3/6; ikisi de dokümanda yalnız dolaylı geçiyor (WHOLE_DEG_HEMI 'bilinmeyen sapma' seçenek listesinde, GlyphBoundaryFrameSplitter `addLast` argüman dağılımında 54/267). Sonnet bu ikisini default'tan daha sık kaçırıyor. Miss-driven madenci `DEG_HEM` için konumdan tek karşılık seçemedi (semantik sabit); `KEY_ARCHIVE` için seçenek de üretemedi.
- **Ablasyon:** miss-driven bölümü çıkarılınca kurallar v2 15.50 → 13.50 (default 17.33 → 15.50, sonnet 13.67 → 11.50); 16 'X yerine Y' kuralı ~2 puan taşıyor; miss-driven bölümü kapsamaya yalnız +1.3 puan ekliyor (77.5% → 78.8%) ama etkisi kapsama farkından büyük, çünkü modelin **ezberden yazdığı yanlış adı** doğrudan hedefliyor.
- **Kurallar v2 tek başına** (15.50) örnekler v2'den (13.00) daha güçlü; 2. turda tersiydi (v1 kurallar 10.33 < örnek 12.00). Fark alternatif kuralları ve miss-driven bölüm. Sonnet kurallar v2'de yüksek varyans (17, 12, 12).
- **Deney B:** araçlar açıkken rolsüz ajan zaten 17.67 (default 18.67, sonnet 16.67) alıyor; rol v2 ile 18.83 (default 18.67, sonnet 19.00). Uyum kazancı küçük ve sonnet'te; default zaten tavana yakın. Maliyet: default'ta rol v2 token'ı 0.45×, araç çağrısını 0.48×, süreyi 0.60× (Kapı B default için geçer); sonnet'te 0.91× / 0.80× / 0.78× (geçmez): sonnet rol dokümanına rağmen keşfi kısaltmıyor. Birleşik oranlar 0.75 / 0.66 → Kapı B geçmedi.
- **Ajan keşfe rağmen kaçırdıkları:** en sık `GlyphBoundaryFrameSplitter` pipeline (2/6; ajan Netty `DelimiterBasedFrameDecoder`/başka frame decoder seçiyor), sonra tek tek `WHOLE_DEG_HEMI`, `asciiFrame/assertNoOutput`, `GrammarComposer` (sonnet'in 14/19'luk koşusu). Beklenen üçlüden datagram bayrağı ajanlarca 6/6 bulundu (görev metni UDP diyor), frame splitter ve coordinate format kaçtı; rol v2 ile hepsi 6/6.
- **Maliyet ölçeği:** ajan koşusu başına 0.8–1.8 $ (default) ve 0.77–0.98 $ (sonnet) karşısında araçsız tek çağrı; ajan token'ının %97+'si önbellekten okunan bağlam (`cache_read_input_tokens`).

## Yöntem notları

- **Duman testi sızıntısı (düzeltildi):** ilk ajan denemesi `/tmp/traccar-mut` worktree'sinde koştu; worktree ana repoyla `.git` nesne deposunu paylaştığı için ajan `git log --all | grep -i r16h` ve `git show 6918e9f` ile gerçek R16h dosyalarını geçmişten okudu ve 19/19 aldı (`out-r3-agent-smoke/`, geçersiz, sayılmadı). Ayrıca `--allowedTools` listesi tırnaksız geçildiği için Bash fiilen sınırsızdı. Düzeltme: `r3-base` ağacından **geçmişsiz tek commit'lik** `/tmp/traccar-r3` deposu; allowlist dizi olarak; `Bash(git *)`, `rm`, `curl`, `wget` yasak; izin probu ile `git log` reddinin doğrulanması. Bütün B koşuları bu düzenle yapıldı.
- **İzin esnekliği:** `acceptEdits` + allowlist altında CLI `echo`, `./gradlew` gibi listede olmayan komutlara da izin verdi (probda `echo hello` çalıştı). Ajanlar `./gradlew test` denedi; JDK 17 yüzünden başarısız oldu, yalnız süre/token maliyeti ekledi. Yasaklı `git` komutları reddedildi (probda doğrulandı) ve depoda zaten geçmiş yok.
- **Sızıntı denetimi:** her B koşusunun Bash komutları tarandı; ajanlar `grep -rn r16h` ile depoyu aradı ve hiçbir eşleşme bulamadı (R16h dosyaları ve `PortConfigSuffix` girdisi çıkarılmış). Mutasyon eşlemesini ifşa edecek bir kaynak (git diff, eski adlar) depoda yok.
- **`rolsüz` (Deney A):** 2. tur çıktıları yeniden kullanıldı (aynı görev metni, kontroller, izolasyon bayrakları, modeller ve NO_TOOLS_PREFIX); `out-mut/*/no_role_*` → `out-r3/*/no_role_*` kopyası.
- **Açılan dosya metriği:** Read aracıyla okunan dosyalar + Bash `cat/head/tail/sed -n` hedefleri (komut metninden çıkarılan `.java/.xml/...` yolları), dosya adına göre tekilleştirilmiş. `Grep/Glob` sütunu Grep ve Glob araç çağrılarının sayısı; ajanlar aramayı çoğunlukla Bash `grep` ile yaptı, o çağrılar `araç çağrısı` toplamında.
- **Token:** stream-json `result.usage` alanı: giriş = `input_tokens + cache_creation_input_tokens + cache_read_input_tokens` (önbellekten okunanlar dahil; ajanın bağlamı her turda yeniden okunur), çıkış = `output_tokens`. Maliyet `total_cost_usd`.
- Örnek demeti seçimi kapsama-maksimizasyonu ile yapıldı (spec); eşitlik kırıcı olarak decoder+test aynı tabana +1 tanımlayıcı ağırlığı verildi, buna rağmen kapsama daha yüksek çıkan tutarsız demet (ArnaviProtocolDecoder + BlueProtocolDecoderTest) seçildi. Soyut sınıflar aday dışı.
- Miss-driven madenci Netty `Unpooled.wrappedBuffer/copiedBuffer` için iki 'bilinmeyen sapma' satırı üretti (model import etmeden kullanmış); bu adlar depoda gerçekten yok, satırlar doğru ama alakasız. Elle silinmedi.
- Deney A'da ablasyon çağrısı `scores.csv` özetini sıfırladı; JSON sonuçlar etkilenmedi, özet JSON'lardan yeniden üretildi ve runner düzeltildi.

Ham çıktılar: Deney A `out-r3/<model>/`, Deney B `out-r3-agent/<model>/` (`*.stream.jsonl` tam kayıt, `*.md` dosyalardan derlenen üç dosya, `*.json` puan+metrik). Motor: `mine_v2.py`, `miss_mining.py`, `compile_role_v2.py`; kapsama: `coverage.json`.
