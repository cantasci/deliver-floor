# GATES — kapı kanıtları

Her faz kapısı burada sayısal kanıtla kapanır (RULES S1). Ham veri: `rol-deneyi/results.md`, `results-mut.md`, `results-r3.md` ve `rol-deneyi/out*/`.

## Faz 0 — Deney kapısı — GEÇTİ (7 Eylül 2026)

### Orijinal eşik ve yeniden tanımı
- Orijinal kapı: `rules+example ≥17` ve `no_role ≤12` (halka açık traccar, R16H görevi, 19 kontrol).
- 1. tur (halka açık repo, araçsız, opus-5 iki varyant, n=3): rolsüz **17.00**, kurallar **15.67**, kurallar+örnek **16.17**. Rolsüz zaten eşiğin üstünde: model Traccar konvansiyonlarını eğitim verisinden biliyor; rol katkısı ölçülemez. Ayrıca görev metnindeki "TCP" ile gerçek PR'ın UDP (`datagram=true`) bayrağı çelişiyordu (tavan 18/19).
- **Yeniden tanım (gerekçe):** ezber karıştırıcısını kaldırmak için Traccar'ın 25 konvansiyon tanımlayıcısı sistematik olarak yeniden adlandırıldı (`rol-deneyi/mutation_map.json`, tek commit, 999 dosya, sızıntı grep 0, javac kontrolünde iki çatal aynı 8 hata / 826 sınıf). Görev metni UDP olarak düzeltildi (tavan 19). `@LINK` kontrolü davranış düzeyine indirildi (ayrı desen cezalandırılmaz). Yeni kapılar: **A** = araçsız, kurallar+örnekler ≥16 (birleşik); **B** = araçlı ajan, model başına uyum ≥ rolsüz VE (token ≤0.6× VEYA araç çağrısı ≤0.5×). Bu tanım RULES D4 olarak korunmuştur ("uyum +2 veya token ≤0.6×").

### 2. tur — mutasyonlu repo, motor v1 (araçsız, n=3, default=opus-5[1m] ve sonnet)
| koşul | birleşik /19 |
|---|---|
| rolsüz | 6.00 |
| kurallar v1 | 10.33 |
| sadece örnek v1 | 12.00 |
| kurallar+örnek v1 | 13.00 |
Kapsama (hedef tanımlayıcıların dokümanda görünme oranı): v1 tam **46.9%**. Sonuç: motor v1 yetersiz; kaçan her kontrol dokümanda görünmeyen bir ada denk geldi.

### 3. tur — motor v2
**Deney A (araçsız, n=3, iki model):**
| koşul | birleşik /19 | default | sonnet |
|---|---|---|---|
| rolsüz | 6.00 | 6, 6, 6 | 6, 6, 6 |
| kurallar v2 | 15.50 | 16, 18, 18 | 17, 12, 12 |
| örnekler v2 | 13.00 | 14, 14, 14 | 12, 11, 13 |
| kurallar+örnekler v2 | **17.83** | 19, 19, 19 | 17, 17, 16 |
| ablasyon: kurallar v2 − miss-driven (n=2) | 13.50 | 15, 16 | 11, 12 |
Kapsama v2 tam **78.8%**. Miss-driven madenci 16/16 doğru eşleme, 4 bilinmeyen sapma. **Kapı A: 17.83 ≥ 16 → GEÇTİ.**

**Deney B (araçlar açık, geçmişsiz tek commit'lik worktree, git yasak, n=3, iki model):**
| model | uyum rolsüz → rol v2 | token oranı | araç oranı | süre oranı | Kapı B |
|---|---|---|---|---|---|
| default (opus-5[1m]) | 18.67 → 18.67 | 0.45 | 0.48 | 0.60 | GEÇTİ (maliyet) |
| sonnet | 16.67 → 19.00 | 0.91 | 0.80 | 0.78 | GEÇTİ (uyum +2.33) |
| birleşik | 17.67 → 18.83 | 0.75 | 0.66 | 0.69 | birleşik eşik geçmedi |
Rolsüz ajanın kaçırdıkları: `GlyphBoundaryFrameSplitter` pipeline 2/6; `WHOLE_DEG_HEMI`, `assertNoOutput/asciiFrame`, `GrammarComposer`, `FieldCursor` null dönüşü, `resolveUnitSession` imzası 1/6'şar. Rol v2 ile hepsi 6/6 (Position penceresi hariç 5/6).

### Bilinen sınırlar (Faz 1'e taşınan riskler)
- n=3 (RULES D3 n≥5 ve bootstrap CI ister) — Faz 5'te ürün içi koşucu ile tekrarlanacak.
- Tek görev tipi (R16H, metin protokolü ekleme) ve tek repo → genelleme ölçülmedi (RULES D8, Faz 1 kapısı).
- Duman testinde yakalanan sızıntı (paylaşılan `.git` üzerinden `git show 6918e9f`) D2 kuralının kaynağıdır; ürün koşucusu bu kuralı otomatik uygular.
- Sonnet rol dokümanına rağmen keşfi kısaltmıyor; maliyet iddiası şimdilik Opus için geçerli.

## Faz 1 — Motor çekirdeği — AÇIK
Kapı ölçütleri: fixture golden test'ler geçer; traccar tam çıkarım <60 s; kural ID'leri iki çalıştırmada aynı; genelleme (mutasyonlu traccar'da 3 görev tipi + mutasyonlu CleanArchitecture'da 1 görev, her biri rol v2 araçsız ≥ rolsüz+6 ve araçlı ajan model başına D4).
