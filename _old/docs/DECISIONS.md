# DECISIONS — ADR kaydı

Biçim: bağlam · karar · gerekçe · sonuçlar. Kapsam dışı bırakılanlar da burada (RULES Ü4).

## ADR-001 — Tüm veri servisleri tek AB bölgesinde
- Bağlam: BYOK ile kullanıcı kodu kullanıcının LLM sağlayıcısına gider; platform tarafında kural/kanıt/örnek verisi tutulur (P5).
- Karar: Postgres, Typesense, Redis, object storage tek AB bölgesinde; alt işlemci listesi yayınlı.
- Sonuç: DPA eki ve veri konumu ayarı (varsayılan EU). Kaynak: docs-SPEC-v3.md §1.

## ADR-002 — v1'de vektör/embedding ve graph DB yok
- Bağlam: Örnek seçimi 3 turda kapsama-maksimizasyonu ile kanıtlandı (coverage 46.9% → 78.8%, skor 13.00 → 17.83).
- Karar: Typesense yalnız facet + tam metin indeksi; kaynak gerçek Postgres; vektör alanı yok (V4), graph DB yok (Ü4).
- Sonuç: örnek seçimi deterministik ve açıklanabilir; mimari vektör eklemeyi engellemez.

## ADR-003 — Öğrenme = kural güven skoru, fine-tuning yok
- Bağlam: Rol etkisi kural/örnek dokümanıyla elde edildi; model ağırlığı değişmeden.
- Karar: fine-tuning yok; güven formülü config'te (V1).

## ADR-004 — Kapsam dışı (v1): kod dışı alan, enterprise self-hosted UI, SSO
- Karar: motor alan-bağımsız tasarlanır (kaynak türü eklentisi) ama yalnız kod alanı uygulanır; enterprise mimariyi engellemez.

## ADR-005 — Faz 0 kapısının yeniden tanımı
- Bağlam: halka açık repoda rolsüz 17.00/19; ezber rol etkisini gizledi.
- Karar: mutasyonlu (yeniden adlandırılmış) çatal üzerinde ölçüm; Kapı A/B tanımı `docs/GATES.md`'de.
- Sonuç: RULES D2 (geçmişsiz worktree, git yasak, sızıntı taraması) ve D4 (model başına ölçüt).
