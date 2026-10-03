# SPEC — "Senin standardını öğrenen rol" platformu

> Bu dosya ECC (Everything Claude Code) akışının girdisidir. `/ecc:plan` bu dosyayı okuyarak plan üretir; her faz `/ecc:tdd` → `/ecc:code-review` → `/ecc:verify` ile uygulanır. Faz kapıları `docs/GATES.md`'ye kanıtlanmadan sonraki faza geçilmez. Kullanım sırası: `ecc-workflow.md`. Bağlayıcı kural seti: `docs/RULES.md` (KURALLAR.md); konsey bulguları: `docs/COUNCIL.md`.

## 0. Ürün tanımı (değiştirme)

- **Konum (3 tur deneyle sabitlendi):** Özel kod tabanında ajanı daha ucuz (Opus: token 0.45×), daha tutarlı (Sonnet: 16.7→19.0, min 14→18) ve keşfin kaçırdığı nadir kararlarda güvenilir kılan; onaylanabilir, izlenebilir, dışa aktarılabilir derlenmiş bağlam. "Daha iyi kod" iddiası satılmaz; maliyet + tutarlılık + nadir karar garantisi + kayma tespiti satılır.
- **Kanıt durumu (docs/GATES.md):** Faz 0 Kapı A geçti (mutasyonlu repo, araçsız: rolsüz 6.00 → rol v2 17.83; Opus 19/19). Kapı B model başına geçti (Opus maliyet, Sonnet uyum). Genelleme (farklı görev tipi, farklı repo) HENÜZ ölçülmedi → Faz 1 kapısı.

- Ürün: kullanıcının reposundan/dokümanından **kanıtlı, onaylı, ağırlıklı kurallar** çıkaran; bunları **rollere** derleyen; rolü **açık Agent Skills formatında (SKILL.md)** dışa aktaran bir motor + web uygulaması.
- Model barındırmıyoruz: **BYOK**. Tüm LLM çağrıları kullanıcının anahtarıyla (Anthropic, OpenAI; sağlayıcı arayüzü genişletilebilir). Anahtar sunucuda sadece şifreli saklanır, loglanmaz.
- Öğrenme = modelin ağırlığı değil, **kuralların güven skoru**. Fine-tuning yok.
- Rolün ana taşıyıcısı **kurallar** (v2: alternatif + test ailesi + miss-driven + koşullu); **örnek demeti** tamamlayıcı ve göreve göre seçilir. Kapsama (hedef tanımlayıcıların dokümanda görünme oranı) her rol için ölçülür ve gösterilir; kapsama <%75 olan rol "eksik" etiketi taşır.
- Kaynak gerçek: ilişkisel DB. Arama: ayrı indeks. Ham kod **saklanmaz**; sadece kural, kanıt sayıları, ≤20 satırlık örnek parçası, dosya yolu.
- Katmanlar: **Free** (1 özel repo, öğrenme açık, onay ekranı; dışa aktarım ve kayma yok — hazır roller değer önerisi değildir, deneyler halka açık repoda rol katkısının ≈0 olduğunu gösterdi) · **Premium** (3 repo, dışa aktarım, bot PR) · **Team** (sınırsız repo, koltuk+repo hibrit fiyat, çoklu rol koordinasyonu, kayma uyarıları, MCP sunucusu, paylaşımlı kural havuzu). Enterprise (self-hosted çıkarım, SSO) bu kurulumda **kapsam dışı**, ama mimari engellemesin.
- Kod alanı ilk hedef; motor alan-bağımsız tasarlanır (kaynak türü eklentisi), kod dışı alan bu kurulumda **kapsam dışı**.
- **Dürüstlük özelliği:** onboarding'de rolsüz prob görevi ile "bu repoda tahmini katkı düşük/orta/yüksek" gösterilir (halka açık/ezberlenmiş repoda düşük çıkar ve söylenir).
- **Dağıtım:** derleme ve kayma sonrası **bot PR** (Claude Code skills + Cursor mdc + AGENTS.md/copilot-instructions adaptörleri); Team için MCP sunucusu. Otomatik push yok.
- **Lisans:** motor K1/K2b Apache-2.0 (açık kaynak `rolemine`); K2/K4/miss-driven/derleme/onay/kayma kapalı.

## 1. Teknoloji seçimleri (gerekçeli değiştirme önerin varsa PLAN.md'de sor, kendiliğinden değiştirme)

- Monorepo: `apps/web` (Next.js 15, TypeScript, App Router), `apps/api` (Python 3.12, FastAPI), `packages/engine` (Python; çıkarım motoru, CLI olarak da paketlenir: `rolemine`), `packages/shared` (JSON şemaları, kontrol formatı).
- DB: Postgres 16 + SQLAlchemy 2 + Alembic. Arama: Typesense (facet + tam metin; **v1'de vektör/embedding yok** — örnek seçimi kapsama-maksimizasyonu ile, kanıtlı). Kuyruk: Redis + RQ; işler idempotency anahtarlı, ≤2 retry, DLQ.
- Çıkarım worker'ı: ayrı konteyner, root değil, klon sonrası ağ kapalı, disk/CPU/süre sınırlı; klon dizini iş sonunda silinir. Git URL allowlist + SSRF reddi.
- Barındırma: tüm veri servisleri tek AB bölgesinde (ADR-001).
- Kod analizi: tree-sitter (Java, C#, TypeScript ilk üç dil). İsim/kalıtım/yardımcı/yokluk madenciliği + dil eklentisi mimarisi.
- Kimlik: Auth.js, GitHub OAuth; RBAC owner/admin/member/viewer. Repo alımı: GitHub App (contents:read, pull_requests:read+write [bot PR], webhooks; imza doğrulama zorunlu). Ayrıca git URL ile shallow clone (allowlist).
- Ödeme: Stripe (Faz 8). Gizli değerler: `.env` + `docker compose` secrets; prod için env-injection.
- Çalıştırma: `docker compose up` ile tam yerel stack; prod için her servis Dockerfile + `deploy/` altında compose.prod ve isteğe bağlı Helm iskeleti.
- Gözlemlenebilirlik: OpenTelemetry (trace), yapılandırılmış JSON log, `/healthz`, `/readyz`, temel metrikler (çıkarım süresi, kural sayısı, onay oranı, LLM token/maliyet kullanıcıya göre).
- CI: GitHub Actions — lint (ruff, eslint), tip (mypy, tsc), test (pytest, vitest, playwright e2e), Alembic migration kontrolü, Docker build.

## 2. Veri modeli (tam olarak bu; alan ekleyebilirsin, çıkaramazsın)

- `workspaces`, `users`, `memberships(role)`, `api_keys(provider, encrypted_key, created_by)`
- `sources(id, workspace_id, kind[git|github_app|upload], uri, default_branch, last_ingested_sha, settings)`
- `families(id, source_id, kind[suffix|dir|export], pattern, member_count, sha, engine_version)` — dosya aileleri; kural, doğrulayıcı hedefi, örnek ve kapsama buna bağlanır
- `rules(id ULID sabit, workspace_id, source_id nullable, family_id nullable, scope[repo|module|path glob|global], text, rationale, exception_text, kind[invariant|alternative|conditional|test_family|miss_driven|semantic_const|style|git|custom], confidence 0..1, status[candidate|approved|rejected|deprecated], origin[deterministic|mined|llm|user|review], generic bool, enforced_by_tool bool, check_hash, version int, created_at, updated_at)`; `UNIQUE(workspace_id, scope, check_hash)`
- `rule_versions(rule_id, version, text, exception_text, changed_by, at)`
- `rule_suppressions(workspace_id, check_hash, reason, created_by, at)` — reddedilen kural yeniden önerilmez
- `rule_checks(rule_id, check_kind[regex|ast_query], target_family_id nullable, expression, robustness_tested bool)` — her kuralın çalıştırılabilir doğrulayıcısı; **`script` türü v1'de yok**; doğrulayıcısı olmayan kural approved olamaz (custom hariç, `verifiable=false`)
- `evidence(id, rule_id, source_id, sha, numerator, denominator, sample_paths[], observed_at, kind[scan|commit|review|user], engine_version)` — commit yazarı kimliği **saklanmaz**, yalnız `is_bot` hesaplanır
- `examples(id, rule_id nullable, family_id, path, snippet ≤20 satır, sha, license_flag bool)` — embedding yok
- `miss_events(id, source_id, eval_run_id, written_identifier, repo_identifier nullable, mapping_confidence, status[mapped|unknown|dismissed])`
- `eval_tasks(id, source_id, kind, spec_md, ground_truth_sha, checks jsonb)`, `eval_runs(id, task_id, model, condition[agent_no_role|agent_role|no_tools_*], role_snapshot_id, prompt_hash, temperature, n)`, `eval_results(run_id, rep, score, missed_checks[], tokens_in, tokens_cached, tokens_out, tool_calls, seconds, usd, leak_check_passed)`
- `llm_calls(id, workspace_id, provider, model, purpose, tokens_in, tokens_cached, tokens_out, usd, at)`; `pricing_tables(provider, model, in, cached_in, out, valid_from)`
- `tags(id, facet[domain|technology|version|topic|task|maturity|free], value)`, `rule_tags(rule_id, tag_id, confidence, source)`
- `roles(id, workspace_id, name, description, tag_query jsonb, output_format, handoffs jsonb, tier_required)`
- `role_snapshots(id, role_id, semver, changelog, compiled_skill_md, adapters jsonb, rule_ids[], example_ids[], coverage_pct, core_tokens, created_at)`
- `deliveries(id, role_snapshot_id, source_id, kind[pr|mcp], pr_url, status)`
- `approvals(id, rule_id, user_id, action[approve|reject|edit], previous_text, new_text, created_at)`
- `drift_events(id, rule_id, source_id, old_conf, new_conf, sha, created_at, acknowledged)`
- `audit_log(actor, action, entity, before, after, at)`

Eşikler (config'e al, koda gömme): approved adayı ≥0.90; 0.60–0.90 → "kural + istisna" adayı, kullanıcıya sorulur; <0.60 elenir. Onay: approve → confidence=1.0 **kilit**, origin=user. Reject → status=rejected + `rule_suppressions`. Edit → `rule_versions`'a yeni sürüm, origin=user.

**Güven formülü (config, birim testli):** `confidence = clamp(w_scan · (Σnum/Σden, son N tarama) + w_commit · (son 90 gün ihlal/uyum, üstel sönüm))`; kullanıcı onayı 1.0'a kilitler; kilitli kuralda kayma skoru düşürmez, yalnız `drift_event` üretir.

## 3. Fazlar ve kapılar

### Faz 0 — Deney kapısı — **TAMAMLANDI** (3 tur; sonuçlar `rol-deneyi/results*.md`, `docs/GATES.md`'ye taşınır)
> Aşağıdaki Faz 0 metni tarihsel kayıttır; iskelet ve fixture adımları Faz 1'in ilk işi olarak yapılır. Kapı A geçti (17.83), Kapı B model başına geçti (Opus maliyet 0.45×, Sonnet uyum +2.3). Bu fazın orijinal eşiği (rules+example ≥17 / no_role ≤12) 2. turda ezber karıştırıcısı nedeniyle yeniden tanımlandı; gerekçe GATES.md'de.
- Monorepo iskeleti, docker compose (postgres, typesense, redis), CI iskeleti, `docs/ARCHITECTURE.md`.
- `packages/engine` içine mevcut prototip mantığını taşı: deterministik çıkarıcı (K1), istatistiksel madenci (K2b), doğrulayıcı (K3). Fixture repolar olarak `traccar/traccar` (depth 300), `jasontaylordev/CleanArchitecture`, `honojs/hono` klonlanır (`make fixtures`), golden test'ler: traccar'da ≥40 değişmez, CleanArchitecture'da Validator→AbstractValidator kuralı, hono'da isim madenciliğinin boş dönmesi beklenen davranış olarak testlenir.
- Değerlendirme koşucusu: R16H deneyi (traccar 6918e9f) — görev, 19 kontrol, ground-truth 19/19 doğrulaması, `claude -p` ve BYOK API ile üç koşul (no_role / rules / rules+example).
- **Kapı:** ground-truth 19/19; deney koşulup `docs/GATES.md`'ye üç koşulun ortalaması yazılmış. Rol etkisi (rules+example ≥17, no_role ≤12) sağlanmıyorsa DUR ve bana raporla; sonraki fazlara geçme.

### Faz 1 — Motor çekirdeği (v2 tasarımı; deney harness'ı rol-deneyi/ içindeki mine_v2.py, miss_mining.py, compile_role_v2.py taşınır)
- Dil eklentisi arayüzü (`LanguagePlugin`: dosya tanıma, test tanımı, kalıtım/import çözümleme, yasak yapı listesi, AST sorgu çalıştırıcı). Java, C#, TS eklentileri tree-sitter ile.
- Gürültü filtreleri: bot yazarlar (dependabot, renovate, github-actions), üretilmiş kod işaretleri, vendor/build dizinleri, tekil dosyalar (`Usings.cs` gibi).
- Kural kimliği sabit (ULID), kural metni türetilmiş; kanıt metne gömülmez.
- Git sinyalleri: commit konvansiyonları, bot filtreli.
- Kural türleri: değişmez (≥0.90), **alternatif** (bir ailede 2–3 seçenek, toplam ≥%80, her biri ≥%20), **koşullu** (alt-aile şartlı: "metin protokollerinde X, ikili protokollerde Y"), test ailesi extends/helper kuralları, **miss-driven** ("bu repoda X yerine Y"; bkz. Faz 2), anlamsal sabit eşlemesi (LLM destekli, Faz 2).
- Örnek demeti: görevden dosya türleri çıkarılır; her tür için kısa örnek + sınır durumu örneği; seçim kapsama-maksimizasyonu ile; demet ≤200 satır.
- Kapsama raporu (`coverage.json`) her rol derlemesinde üretilir; çekirdek ≤3k token (satır değil token ölçülür).
- Doğrulayıcı sağlamlık testi: her kural için ground-truth + davranışsal eşdeğer varyant geçer, yanlış varyant düşer (RULES M2). AST sorgusu tercih; regex yalnız AST yetmezse.
- TS/JS aile tespiti export adı + dizin kalıbı ile (sonek değil); import-tabanlı sembol çözümleme, tsconfig `paths` dahil; çözülemeyen sembol kural üretmez.
- Tarama sınırları: ≤50k dosya, ≤2 MB/dosya, ≤10 dk; aşımda kısmi sonuç + uyarı.
- Çıktı: `ExtractionReport` (aday kurallar + kanıt + doğrulayıcı + etiket önerileri + kapsama).
- **Kapı:** fixture golden test'ler geçer; traccar tam çıkarım < 60 s; kural ID'leri iki çalıştırmada aynı; **genelleme:** mutasyonlu traccar'da R16H dışı 3 görev tipi (mevcut decoder'a alan ekleme, hata düzeltme, ikili protokol ekleme) ve mutasyonlu CleanArchitecture'da 1 görev — her birinde rol v2 araçsız ≥ rolsüz + 6 ve araçlı ajan model başına (uyum +2 veya token ≤0.6×). Geçmezse Faz 2'ye geçme.

### Faz 2 — LLM hipotez katmanı (K2) ve genellik filtresi (K4), BYOK
- `LLMProvider` arayüzü (anthropic, openai); anahtar workspace'ten şifreli okunur; her çağrı token/maliyet kaydı.
- K2: girdi = K1/K2b raporu + dizin ağacı + grup başına 3 örnek dosya (örneklemeli; tam okuma yok). Çıktı = **doğrulanabilir** hipotezler (regex/AST). Doğrulanamayan hipotez atılır. Küçük repo (<300 dosya) veya isim düzeni olmayan repo için K2 zorunlu yol.
- K4 **ampirik**: miss-driven koşusundaki rolsüz çıktıda zaten sağlanan kurallar `generic=true` (ek maliyet yok); öz-bildirim sorgusu yalnız ikincil sinyal. Genel kurallar role çekirdek olarak girmez.
- İstisna yazımı: 0.60–0.90 bandındaki kurallar için K2'den istisna taslağı.
- **Miss-driven mining (kanıtlı, 16/16):** rol yokken modele 2–3 temsilci görev verilir (BYOK), çıktıdaki tanımlayıcılar repoda aranır, bulunmayanlar için aynı rolü oynayan repo adı imza/konum benzerliğiyle eşlenir → "X yerine Y" kuralı. Eşlenemeyenler (anlamsal sabitler: DEG_HEM→WHOLE_DEG_HEMI, KEY_ARCHIVE) K2'ye seçenek listesiyle sorulur; hâlâ belirsizse onay ekranında "bilinmeyen sapma" olarak kullanıcıya gösterilir.
- Prompt injection savunması: repodan gelen tüm metin veri olarak sarmalanır; talimat benzeri satırlar (`ignore`, `you must`, `AI:` vb. + heuristik sınıflandırıcı) K2 girdisinden çıkarılır ve `security_flags`'e yazılır.
- **Kapı:** petclinic (30 dosya) için K2 ≥10 doğrulanmış kural üretir; hono için ≥8; K4 traccar'daki JUnit5/no-wildcard gibi kuralları generic işaretler; injection test seti (10 zehirli yorum) K2'ye sızmaz.

### Faz 3 — API ve depolama
- FastAPI: auth, workspaces, sources (bağla/tara/sil), rules (liste/facet filtre/onay), roles (CRUD, derle, dışa aktar), evaluations, drift, api_keys, billing hook'ları.
- Alembic migrasyonları; Typesense indeksleme (kural metni, facet'ler, örnek embedding'leri); indeks kaynak gerçekten yeniden kurulabilir (`reindex` komutu).
- Rate limit, idempotent iş kuyruğu (DLQ), iş durumu uçları; API `/v1/`.
- **Güvenlik temelleri burada (RULES G1–G5):** worker izolasyonu, git URL allowlist/SSRF reddi, webhook imza doğrulama + delivery dedupe, RBAC, anahtar şifreleme + log maskeleme; `workspace_id` zorunlu filtre middleware'i.
- **Kapı:** OpenAPI şeması üretilir; pytest kapsamı motor+api ≥80%; `docker compose up` sonrası e2e smoke (repo bağla → tarama → kurallar listelenir) yeşil; **negatif e2e:** çapraz workspace erişimi 0 sonuç, imzasız webhook 401, iç IP git URL reddi, klon dizini iş sonunda yok.

### Faz 4 — Web uygulaması: onboarding, onay, rol, dışa aktarım
- Ekranlar: repo bağla (GitHub App / URL) → tarama ilerlemesi → **onay listesi** (facet'e göre gruplu, ≤50 kural, her kuralın yanında kanıt oranı ve 3 örnek yol, approve/reject/edit; "hepsini onayla" YOK) → roller (etiket sorgusu düzenleyici, canlı önizleme) → rol sayfası (derlenmiş SKILL.md, katmanlı: çekirdek/örnekler) → dışa aktar (SKILL.md zip; Claude Code/Cursor/Codex yolları) → kayma uyarıları → ayarlar (API anahtarları, veri silme).
- Onboarding'de **katkı tahmini** (rolsüz prob görevi → düşük/orta/yüksek, dürüst mesaj). "Kural + istisna" ve "bilinmeyen sapma" ayrı sekmelerde, varsayılan: role girmez.
- Rol derleme: onaylı + generic=false kurallar çekirdek (miss-driven bölümü önde); generic olanlar "arka plan"; örnekler ayrı dosyalarda (progressive disclosure). Çıktı agentskills.io spesine uygun.
- **Adaptörler:** Claude Code (skills + CLAUDE.md bölümü), Cursor (`.cursor/rules/*.mdc`), Codex/Copilot (`AGENTS.md`, `copilot-instructions.md`).
- **Dağıtım = bot PR** (GitHub App): derleme sonrası adaptör dosyalarıyla PR; snapshot semver + changelog. Export URL'leri imzalı ve süreli.
- **Kapı:** Playwright e2e: bağla → onayla → rol derle → PR açılır akışı yeşil; derlenen SKILL.md `skills` CLI ile kurulabilir; **tetikleme testi:** Claude Code'da görev verilince skill yüklenir (stream-json); axe kritik hata yok.

### Faz 5 — Değerlendirme (rol var/yok) ürün özelliği
- Her repo için otomatik görev üretimi: son 20 birleşmiş commit'ten "yeni X ekle" tipindeki değişiklikler → görev + ground-truth + kontrol seti (kontroller kuralların doğrulayıcılarından üretilir). **Sızıntı kuralı (RULES D2):** ebeveyn commit'te geçmişsiz worktree, hedef dosyalar ve kayıt girdileri çıkarılmış, `git` yasak, Bash komut taraması rapora girer.
- Koşucu: **birincil taban çizgisi = araçlar açık, rolsüz ajan**; koşullar agent_no_role / agent_role (+ teşhis için araçsız); n≥5, eşleştirilmiş fark + bootstrap %95 CI; model string, prompt hash, sıcaklık kayıtlı; doküman biçimi A/B. Sonuç sayfası (uyum, kaçırılan kurallar, token/önbellek/dolar).
- **Maliyet telemetrisi (ürün özelliği):** her ajan/BYOK çağrısı için token, araç çağrısı, süre ve dolar; rol var/yok karşılaştırma panosu ("bu ay rol ile %X token tasarrufu"). Koltuk fiyatının gerekçesi bu panodur.
- Model sürümü değişince etkilenen roller yeniden değerlendirilir ("bu model için katkı" etiketi).
- **Kapı:** R16H deneyi ürün içinden koşulur ve 3. tur Deney B tablosunu yeniden üretir (CI alt sınırı ile); telemetri panosu aynı sayıları gösterir; `rolemine eval` CLI'da çalışır.

### Faz 6 — Sürekli döngü ve kayma
- GitHub webhook (push, pull_request): sadece değişen dosyalarda doğrulayıcılar yeniden koşar; kanıt güncellenir; güven yeniden hesaplanır; eşik altına düşen kural → `drift_event` + bildirim ("son 30 commit'te %X ihlal; kaldıralım mı / istisna mı?").
- Periyodik (haftalık) K2 turu: yeni hipotezler → aday kurallar → onay kuyruğu.
- PR review yorumları (K5): bakımcı yorum + diff eşleşmesi → düşük güvenli aday; **asla otomatik onay**. Yorum yazarı kimliği saklanmaz.
- Bildirim: e-posta + Slack webhook, <10 dk. Kayma sonrası yeniden derleme → bot PR; Team için MCP sunucusu snapshot'ı günceller.
- **Kapı:** traccar'da eski/yeni commit arasında "generic catch %15→%22" kayması ürün tarafından tespit edilir; webhook işleme idempotent (aynı push iki kez → tek etki).

### Faz 7 — Güvenlik denetimi, gizlilik, uyum (temeller Faz 3'te; burası sertleştirme)
- Ham kod saklanmadığının testi (DB dump'ında ≤20 satır dışında kaynak kod yok). Örneklerde gizli anahtar taraması (gitleaks kuralları) — sızıntı varsa örnek atılır.
- Workspace silme → tüm veriler + indeks + iş kuyruğu temizliği (silme kanıtı raporu).
- API anahtarları: AES-GCM + KMS, rotasyon, log maskeleme testi. Audit log append-only (trigger). Tedarik zinciri: lockfile, `pip-audit`/`npm audit`, SBOM, Dependabot.
- ToS/DPA: türetilmiş kural/örnek/export kullanıcınındır; BYOK sağlayıcı kullanıcının alt işlemcisi; commit yazarı verisi işlenmez (yalnız bot bayrağı).
- Rol/kural metnine talimat sızması: derleme öncesi filtre + test seti.
- `docs/PRIVACY.md`, `docs/DPA-checklist.md` (alt işlemciler: sadece kullanıcının seçtiği LLM sağlayıcı + barındırma), veri konumu ayarı (EU bölgesi varsayılan).
- **Kapı:** OWASP ASVS L1 kontrol listesi doldurulmuş; bağımlılık taraması temiz; yük testi (50 eşzamanlı tarama) hata yok.

### Faz 8 — Katmanlar, ödeme, kota
- Free/Premium/Team yetkileri (§0); Team fiyatı koltuk+repo hibrit. Stripe checkout + webhook; kota sayaçları; BYOK maliyet panosu. Team'de onay çatışması: son onay kazanır + audit; isteğe bağlı CODEOWNERS eşlemesi. Ürün içi "neden CLAUDE.md değil" karşılaştırma sayfası.
- Çoklu rol koordinasyonu (Team): rol → rol devri (`handoffs`), sıralı/hiyerarşik iki mod; koordinasyon tanımı SKILL.md'ye "when to hand off" bölümü olarak derlenir.
- **Kapı:** katman geçişleri e2e; kota aşımı doğru engellenir; faturalandırma test modunda uçtan uca.

### Faz 9 — Üretim hazırlığı
- `deploy/`: compose.prod, migrasyon job'ı, yedekleme (pg_dump zamanlayıcı, geri yükleme testi), Typesense yeniden indeksleme job'ı, healthcheck'ler, log/trace toplama.
- Runbook: `docs/RUNBOOK.md` (kurulum, ölçekleme, geri alma, **anahtar ifşası**, veri silme talebi). SLO: tarama p95 <5 dk (≤5k dosya), API p95 <300 ms, erişilebilirlik %99.5. Fixture repolar SHA'ya sabit tarball; golden çıktılar `engine_version`'a bağlı.
- Sürüm: semver, CHANGELOG, `rolemine` CLI'nin PyPI'a yayın akışı (self-hosted çıkarım için).
- **Kapı:** temiz bir makinede `docs/RUNBOOK.md` takip edilerek prod kurulumu 30 dk'da ayağa kalkar; yedekten geri yükleme testi geçer; CI tamamen yeşil.

## 4. Çalışma kuralları

- Her fazda: önce testler ve arayüz sözleşmesi, sonra uygulama. Her kural/doğrulayıcı için birim test; motor için fixture golden test'ler.
- Kod dışı alan, enterprise, self-hosted UI, fine-tuning, vektör-merkezli mimari, graph DB: **yapma**. Gerekçesi `docs/DECISIONS.md`'de (ADR formatı); ben istemeden kapsamı genişletme.
- Bir kapı geçilemiyorsa nedenini ve seçenekleri yaz, bekle. Kapıyı gevşetme; gerekiyorsa yeniden tanımla ve gerekçesini GATES.md'ye yaz.
- İlk ödeyen müşteri kesiti: Faz 1–4 + Faz 5 telemetri + Faz 6 webhook/kayma. Faz 8–9 ilk müşteriden sonra.
- Her PR açıklamasında etkilenen `docs/RULES.md` kural ID'leri ve test kanıtı.
- Her faz sonunda özet: ne yapıldı, kapı kanıtı (sayılar), açık riskler, sonraki faz için ihtiyacım olan karar/erişim (GitHub App kimlik bilgileri, Stripe test anahtarı, domain vb.).
- Türkçe iletişim, İngilizce kod/yorum/commit.

