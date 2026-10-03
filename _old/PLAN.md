# PLAN — Faz 1: Motor çekirdeği (rolemine engine v2)

**Kaynak:** `docs-SPEC-v3.md` §3 Faz 1, `docs/RULES.md` (M1–M13, V6–V7, D2, D8, O2, S1–S4)
**Önceki faz kanıtı:** `docs/GATES.md` (Faz 0 geçti; Kapı A 17.83, Kapı B model başına)
**Karmaşıklık:** Büyük (motor taşıma + 3 dil eklentisi + fixture golden + genelleme deneyi)

## 1. Gereksinimlerin yeniden ifadesi

Faz 1'in çıktısı, `rol-deneyi/` prototipinin (mine_invariants, mine_v2, miss_mining, compile_role_v2, scorer, run_*_eval) ürün motoruna dönüşmüş hâlidir:

1. **Monorepo iskeleti** (Faz 0'dan devralınan ilk iş): `apps/web`, `apps/api`, `packages/engine` (Python 3.12, CLI `rolemine`), `packages/shared` (JSON şemaları), `docker compose` (postgres, typesense, redis), GitHub Actions CI iskeleti, `docs/ARCHITECTURE.md`.
2. **Dil eklentisi arayüzü** `LanguagePlugin` (dosya/test tanıma, aile tespiti, kalıtım/import çözümleme, yasak yapı listesi, AST sorgu çalıştırıcı) — Java, C#, TS eklentileri tree-sitter ile. TS/JS'de aile = export adı + dizin kalıbı; import-tabanlı sembol çözümleme, `tsconfig paths` dahil; çözülemeyen sembol kural üretmez (M11).
3. **Gürültü filtreleri** (M10): bot yazar, üretilmiş kod işaretleri, vendor/build, tekil dosyalar.
4. **Kural türleri** (M5): değişmez ≥0.90, alternatif (toplam ≥%80, her biri ≥%20), koşullu (alt-aile şartlı), test ailesi extends/helper, miss-driven (deterministik eşleme burada; LLM'li tamamlama Faz 2), anlamsal sabit (Faz 2).
5. **Kural kimliği** ULID sabit; metin türetilmiş; kanıt metne gömülmez (M3). Aynı kapsam + `check_hash` tek kural (M4).
6. **Doğrulayıcılar**: her kural için regex/AST sorgusu; sağlamlık testi (ground-truth geçer, eşdeğer varyant geçer, yanlış varyant düşer) (M1, M2). `script` türü yok.
7. **Örnek demeti**: görevden dosya türleri → tür başına örnek + sınır durumu; kapsama-maksimizasyonu; ≤200 satır; çekirdek ≤3k **token** (M8).
8. **Kapsama raporu** `coverage.json` her derlemede (M9).
9. **Tarama sınırları** ≤50k dosya, ≤2 MB/dosya, ≤10 dk, aşımda kısmi sonuç (M12).
10. **Çıktı** `ExtractionReport` (aday kurallar + kanıt + doğrulayıcı + etiket önerileri + kapsama); şema `packages/shared`'da tek kaynak (M13).
11. **Kapı:** fixture golden test'ler; traccar tam çıkarım <60 s; ID kararlılığı; **genelleme deneyi** (D8): mutasyonlu traccar'da 3 yeni görev tipi + mutasyonlu CleanArchitecture'da 1 görev; her birinde rol v2 araçsız ≥ rolsüz+6 VE araçlı ajan model başına D4.

## 2. Mevcut kalıplar (pattern grounding)

Kod tabanı yalnız `rol-deneyi/` prototipidir; ürün kodu yok. Devralınacak ve değiştirilecek kalıplar:

| Kategori | Kaynak | Kalıp | Faz 1'de |
|---|---|---|---|
| Aile tespiti | `rol-deneyi/mine_invariants.py` (`suffixes`, MIN_FAMILY=50) | CamelCase sonek aileleri, en uzun eşleşen sonek | Java/C# eklentisinde korunur; TS için export+dizin (M11) |
| Çağrı madenciliği | `mine_invariants.py` CALL_RE, `mine_v2.py:calls()` | regex ile çağrı/bildirim ayrımı | tree-sitter AST ile değiştirilir; regex yalnız yedek |
| Alternatif kuralları | `mine_v2.py:exclusive_alternatives / argument_alternatives` | 0.2/0.8 eşikleri | korunur, eşikler config'e alınır |
| Miss-driven eşleme | `miss_mining.py:resolve / ctx_index` | bağlam türü → aday dağılımı → frekans sıralı atama | korunur; 16/16 regresyon testi (M6) |
| Kapsama | `mine_v2.py:coverage()` | ≥%20 hedef tanımlayıcı / dokümanda görünme | korunur; token ölçümü eklenir (M8) |
| Puanlama | `scorer.py` (regex + `link_behaviour` fonksiyonu) | kontrol = [aile, ad, regex\|fn] | `rule_checks` biçimine dönüşür; davranışsal kontroller AST sorgusu olur |
| Değerlendirme koşucusu | `run_cc_eval.sh`, `run_agent_eval.sh`, `agent_metrics.py` | claude -p, stream-json, worktree | `rolemine eval` CLI'ya taşınır; D2 sızıntı kuralı otomatik |
| Hata yönetimi / log / test | yok (script'ler `sys.argv`, print) | — | pytest + ruff + mypy kurulur; yapılandırılmış log Faz 3 |

Kural: kalıp yoksa uydurulmaz; "yok" yazanlar Faz 1'de ilk kez kurulur.

## 3. Değiştirilecek/oluşturulacak dosyalar

| Yol | Eylem | Neden |
|---|---|---|
| `.gitignore`, `README.md`, `Makefile` (`make fixtures`, `make test`) | CREATE | iskelet |
| `pyproject.toml` (kök: ruff, mypy, pytest ayarları) | CREATE | Python araç zinciri |
| `packages/engine/pyproject.toml`, `packages/engine/rolemine/` | CREATE | motor paketi + CLI |
| `packages/engine/rolemine/plugins/{base,java,csharp,typescript}.py` | CREATE | `LanguagePlugin` (M11) |
| `packages/engine/rolemine/mining/{families,invariants,alternatives,conditional,test_family,miss_driven}.py` | CREATE (prototipten taşıma) | kural türleri (M5) |
| `packages/engine/rolemine/{checks,compile,coverage,report,ids,noise,limits}.py` | CREATE | doğrulayıcı, derleme, kapsama, ExtractionReport, ULID, gürültü, sınırlar |
| `packages/engine/rolemine/eval/{runner,agent_runner,metrics,leak}.py` | CREATE (prototipten taşıma) | `rolemine eval` (D1–D4 iskeleti; ürün özelliği Faz 5) |
| `packages/engine/tests/` (+ `fixtures/`, `golden/`) | CREATE | golden + sağlamlık testleri |
| `packages/shared/schemas/{extraction_report,rule,check,coverage,eval_result}.schema.json` | CREATE | tek kaynak şema (M13) |
| `apps/api/`, `apps/web/` | CREATE (yalnız iskelet: healthz, boş Next.js) | monorepo bütünlüğü; içerik Faz 3–4 |
| `docker-compose.yml`, `.github/workflows/ci.yml` | CREATE | compose + CI iskeleti |
| `docs/ARCHITECTURE.md` | CREATE | mimari |
| `rol-deneyi/` | KEEP | tarihsel deney kaydı; GATES.md ona atıf yapar |
| `docs-SPEC-v3.md`, `KURALLAR.md` | MOVE → `docs/SPEC.md`, `docs/RULES.md` (kopya yapıldı) | spec'in kendi atıfları `docs/` altını gösteriyor — **onay bekliyor (Soru 1)** |

## 4. Görevler (sıra = bağımlılık sırası; her görev önce test)

### Görev 0 — Depo ve iskelet
- Eylem: `git init`; monorepo dizinleri; `pyproject` (poetry, Python 3.12); `pnpm-workspace.yaml`; `docker-compose.yml` (postgres 16, typesense, redis); CI (ruff, mypy, pytest, eslint/tsc iskelet, docker build); `docs/ARCHITECTURE.md`.
- Doğrula: `docker compose config` geçer; `make test` boş test paketiyle yeşil.

### Görev 1 — Fixture'lar ve golden altyapısı (O2)
- Eylem: `make fixtures`: traccar (SHA sabit, depth 300; `/tmp/traccar` mevcut), `jasontaylordev/CleanArchitecture`, `honojs/hono` SHA'ya sabit tarball; mutasyonlu traccar (`rol-deneyi/mutation_map.json` ile üretilir) ve **mutasyonlu CleanArchitecture** (yeni harita gerekir — Soru 4).
- Doğrula: fixture SHA'ları testte sabit; fixture yoksa test `skip` değil `fail`.

### Görev 2 — `packages/shared` şemaları (M13)
- Eylem: `ExtractionReport`, `Rule`, `RuleCheck`, `Evidence`, `Coverage`, `EvalResult` JSON şemaları; pydantic modelleri şemayla karşılaştırılır.
- Doğrula: şema-model eşleşme testi; örnek rapor şemayı geçer.

### Görev 3 — `LanguagePlugin` + Java eklentisi (tree-sitter)
- Eylem: arayüz; Java için sınıf/extends/implements/import/çağrı/metot bildirimi/anotasyon AST'den; test dosyası tanıma; yasak yapı listesi. Regex çağrı madenciliği yerine AST; `mine_invariants.py` ile aynı kesirleri vermesi golden'la test edilir (268/274 vb.).
- Doğrula: traccar golden ≥40 değişmez; alternatif/test-ailesi kuralları 3. tur `role_rules_v2.md` ile satır bazında eşleşir.

### Görev 4 — Aile tespiti, gürültü filtreleri, sınırlar (M10, M12, V7)
- Eylem: `families` birinci sınıf nesne (kind suffix|dir|export); bot yazar listesi (git log), `@Generated`/`<auto-generated>`/protobuf/`linguist-generated`, vendor/build, tekil dosyalar; ≤50k dosya/≤2 MB/≤10 dk kısmi sonuç.
- Doğrula: fixture'da `build/generated` aileye girmez; sınır aşımında `partial=true` + uyarı, çökme yok.

### Görev 5 — Kural türleri ve kimlik (M3, M4, M5)
- Eylem: değişmez, alternatif, **koşullu** (yeni: aile bir çağrıya göre alt-ailelere bölünür, ör. `GrammarComposer` kullanan/kullanmayan → "metin protokollerinde X, ikilide Y"), test ailesi, miss-driven (deterministik kısım). ULID = `hash(scope, check_hash)` tabanlı deterministik; metin şablondan; kanıt ayrı.
- Doğrula: iki ardışık taramada aynı ID'ler; her türden ≥1 kural fixture'da; `UNIQUE(scope, check_hash)` motor tarafında.

### Görev 6 — Doğrulayıcılar ve sağlamlık testi (M1, M2)
- Eylem: her kural → `RuleCheck` (AST tercih, regex yedek); sağlamlık paketi: ground-truth + eşdeğer varyant + yanlış varyant. R16H'nin 19 kontrolü bu biçime taşınır (`@LINK` davranışsal kontrol AST sorgusu; Position 80-karakter penceresi "aynı metot gövdesi" olarak yeniden yazılır — Soru 6).
- Doğrula: 19/19 ground-truth; 3. turdaki 24 çıktıda eski/yeni puan farkı raporlanır.

### Görev 7 — Örnek demeti, kapsama, derleme (M8, M9)
- Eylem: `compile_role_v2` taşınır; token sayacı ile çekirdek ≤3k token; `coverage.json`; SKILL.md üretimi Faz 4'e, burada düz markdown rol dokümanı.
- Doğrula: mutasyonlu traccar'da kapsama ≥ 78.8%; demet ≤200 satır; çekirdek token sayısı raporda.

### Görev 8 — C# ve TypeScript eklentileri (M11)
- Eylem: C#: sonek aileleri, `AbstractValidator<T>` kalıtımı; TS: export adı + dizin kalıbı, `tsconfig paths`; çözülemeyen sembol → kural yok.
- Doğrula: CleanArchitecture golden `*Validator extends AbstractValidator`; hono golden: isim madenciliği **boş** döner ve bu beklenen davranış olarak testlenir.

### Görev 9 — `rolemine` CLI
- Eylem: `rolemine scan <repo> --out report.json`, `rolemine compile report.json --task task.md --out role/`, `rolemine eval …` (D2: ebeveyn commit'te geçmişsiz worktree, hedef dosyalar çıkarılır, git yasak, Bash tarama raporu).
- Doğrula: CLI çıktısı şemayı geçer; traccar tam tarama <60 s (CI'da ölçülür).

### Görev 10 — Genelleme deneyi (Faz 1 kapısı, D8)
- Eylem: mutasyonlu traccar'da 3 görev (decoder'a alan ekleme; hata düzeltme; ikili protokol ekleme) + mutasyonlu CleanArchitecture'da 1 görev. Her görev: gerçek commit'ten türetilmiş metin, kontrol seti, sağlamlık testi. Koşullar: araçsız rolsüz/rol v2 (teşhis) ve araçlı ajan rolsüz/rol v2 (birincil, D1). n için Soru 5.
- Doğrula: her görevde araçsız rol v2 ≥ rolsüz+6 VE araçlı ajan model başına D4; sonuçlar `docs/GATES.md`'ye.

## 5. Doğrulama komutları
```bash
make fixtures
make test                          # ruff + mypy + pytest (golden, sağlamlık, şema)
poetry run rolemine scan /tmp/fixtures/traccar --out /tmp/report.json
poetry run rolemine compile /tmp/report.json --task rol-deneyi/task.md --out /tmp/role && cat /tmp/role/coverage.json
poetry run rolemine eval --task tasks/r16h.yaml --conditions agent_no_role,agent_role --n 3
docker compose config && docker compose up -d && curl -f localhost:8000/healthz
```

## 6. Riskler
| Risk | Olasılık | Azaltma |
|---|---|---|
| tree-sitter AST'ye geçişte golden kesirlerin regex prototipten sapması | Yüksek | Önce regex↔AST eşdeğerlik testi; sapmalar açıklanıp golden güncellenir (O2: PR'da açık onay) |
| Genelleme deneyi maliyeti: 4 görev × 2 koşul × 2 model × n=5 = 80 ajan koşusu ≈ 80–130 $ | Yüksek | Soru 5: n=3 pilot, kapı yalnız n≥5 ile "geçti" |
| Sonnet rol dokümanına rağmen keşfi kısaltmıyor (3. tur token 0.91×) | Orta | D4 model başına; doküman biçimi A/B Faz 5 (D7) |
| Mutasyonlu CleanArchitecture için yeni harita ve görev gerekiyor | Orta | Soru 4; `mutate.py` dil-bağımsız hâle getirilir |
| JDK 21 yok → Java fixture derlenemez | Düşük | Doğrulayıcılar AST/regex; derleme kanıtı opsiyonel |
| tree-sitter paketleri kurulu değil; C# grameri sürüm uyumu | Orta | gramer paketleri pin'lenir; CI'da kurulum |
| Anlamsal sabit (DEG_HEM→WHOLE_DEG_HEMI) deterministik eşlenemez | Kesin | Faz 2 (K2 seçenek listesiyle); Faz 1'de "bilinmeyen sapma" (M6) |
| Miss-driven, rolsüz model çıktısı gerektirir → motor testi LLM'e bağımlı | Orta | Golden test 3. turun 6 rolsüz çıktısını fixture olarak kullanır (16/16 regresyon) |

## 7. Kararlar / sorular

1. **Depo yerleşimi:** monorepo kökü = `skills-store/` mi? `docs-SPEC-v3.md` → `docs/SPEC.md`, `KURALLAR.md` → `docs/RULES.md` (kopya yapıldı) taşınsın mı? `rol-deneyi/` kökte kalır (öneri). `git init` ve ilk commit için onay.
2. **Eksik referanslar:** spec `ecc-workflow.md` ve `docs/COUNCIL.md`'ye atıf yapıyor; ikisi de yok. Sağlayacak mısın, yoksa ECC akışını PLAN→tdd→code-review→verify olarak ben `docs/ecc-workflow.md` yazayım mı?
3. **Python araç zinciri:** poetry var, `uv` yok. **Öneri: poetry.**
4. **CleanArchitecture mutasyonu:** öneri ~15 ad (`AbstractValidator`, `IRequestHandler`, `IApplicationDbContext`, `Result`, `BaseAuditableEntity`, `ValidationBehaviour`, test yardımcıları); görev son 50 commit'te "Add X command/query" tipinde bir PR'dan. Seçimi ben yapıp GATES'e yazarım.
5. **Deney bütçesi:** (a) n=5 tam (~100 $); (b) n=3 pilot, geçenlerde n=5'e tamamla; (c) yalnız default n=5, sonnet n=3. **Öneri: (b).**
6. **Position kontrolü:** 80-karakter penceresi AST tabanlı "aynı metot gövdesi" kontrolüne dönüştürülsün mü? Yumuşatma değil, biçim artefaktının kaldırılması; 3. tur skorları etkilenmez (fark 0 raporlanmıştı). **Öneri: evet.**
7. **Faz 1 kapısı modelleri:** default (opus-5[1m]) + sonnet (3. turla aynı) — **öneri**.

## 8. Kapsam dışı (bu fazda yapılmaz)
K2/K4 ve anlamsal sabit eşlemesi (Faz 2); FastAPI uçları, Alembic, Typesense (Faz 3); web ekranları, SKILL.md adaptörleri, bot PR (Faz 4); ürün içi değerlendirme koşucusu ve telemetri (Faz 5). `apps/api` ve `apps/web` yalnız iskelet.

**ONAY BEKLİYOR:** Plan böyle ilerlesin mi? (evet / değiştir: … / sorulara yanıt)
