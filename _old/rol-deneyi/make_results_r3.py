#!/usr/bin/env python3
"""results-r3.md: Experiment A (tools off, engine v2), Experiment B (agent), coverage, ablation."""
import json, re, glob
from collections import Counter, defaultdict
from pathlib import Path
import sys
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE)); import scorer
A = HERE / "out-r3"; B = HERE / "out-r3-agent"; R2 = HERE / "out-mut"
CONDS_A = ["no_role", "rules_v2", "examples_v2", "rules_examples_v2"]
ABL = "rules_v2_nomiss"
CONDS_B = ["agent_no_role", "agent_role_v2"]
LABEL = {"no_role": "rolsüz", "rules_v2": "kurallar v2", "examples_v2": "örnekler v2", "rules_examples_v2": "kurallar+örnekler v2",
         "rules_v2_nomiss": "kurallar v2 − miss-driven (ablasyon)", "agent_no_role": "ajan, rolsüz", "agent_role_v2": "ajan, rol v2",
         "rules": "kurallar v1", "example_only": "sadece örnek v1", "rules_example": "kurallar+örnek v1"}
CHECKS = json.loads((HERE / "checks.json").read_text())
POS_NAME = "new Position(wireName()) + setDeviceId"
POS_RX_400 = r"new Position\(wireName\(\)\)[\s\S]{0,400}setDeviceId\(deviceSession\.getDeviceId\(\)\)"

def load(d, conds):
    data = defaultdict(dict)
    for j in sorted(Path(d).glob("*_[0-9]*.json")):
        cond, n = j.stem.rsplit("_", 1)
        if cond in conds: data[cond][int(n)] = json.loads(j.read_text())
    return data

def mean(xs): return sum(xs) / len(xs) if xs else float("nan")
def fm(xs): return f"{sum(xs)}/{len(xs)} = {mean(xs):.2f}" if xs else "–"

def pos400(md_path):
    b = scorer.split_blocks(Path(md_path).read_text(errors="replace"))
    return bool(re.search(POS_RX_400, b["decoder"]))

def table_A(model_dir, conds):
    data = load(model_dir, conds); rows = []; stats = {}; stats400 = {}
    for c in conds:
        rs = data.get(c, {}); xs = []; xs400 = []; cells = []
        for n in sorted(rs):
            r = rs[n]; s = r["score"]; xs.append(s)
            s400 = s + (1 if POS_NAME in r["failed"] and pos400(model_dir / f"{c}_{n}.md") else 0); xs400.append(s400)
            cells.append(f"{s}" + (f" ({s400})" if s400 != s else ""))
        stats[c] = mean(xs); stats400[c] = mean(xs400)
        rows.append(f"| {LABEL[c]} | " + " | ".join(cells) + " | " * (3 - len(cells)) + f" | {fm(xs)} | {fm(xs400)} |")
    hdr = "| koşul | #1 | #2 | #3 | ortalama /19 | ort. pencere=400 |\n|---|---|---|---|---|---|"
    return hdr + "\n" + "\n".join(rows), stats, stats400, data

def matrix(models, conds, loader):
    names = [c[1] for c in CHECKS]; mat = {c: Counter() for c in names}; n = Counter()
    for md in models:
        for cond, rs in loader(md, conds).items():
            for r in rs.values():
                r = r["score"] if isinstance(r.get("score"), dict) else r   # agent results nest the score
                if r.get("incomplete"): continue
                n[cond] += 1
                for p in r["passed"]: mat[p][cond] += 1
    lines = ["| kontrol | " + " | ".join(LABEL[c] for c in conds) + " |", "|---|" + "---|" * len(conds)]
    for c in names: lines.append(f"| `{c}` | " + " | ".join(f"{mat[c][k]}/{n[k]}" for k in conds) + " |")
    return "\n".join(lines), mat, n

def main():
    P = ["# Rol deneyi, 3. tur: motor v2 (Deney A) ve araçlar açık ajan taban çizgisi (Deney B)\n"]
    cov = json.loads((HERE / "coverage.json").read_text())
    P.append(f"Repo: `/tmp/traccar-mut` (2. turdaki mutasyonlu çatal). Görev ve kontroller 2. turla aynı (`task.md`, `checks.json`). Rol dokümanları motor v2 ile üretildi: `role_rules_v2.md` ({sum(1 for l in (HERE/'role_rules_v2.md').read_text().splitlines() if l.startswith('- '))} kural satırı; v1 kuralları + alternatifler + test kuralları + miss-driven bölüm), `role_examples_v2.md` ({cov['bundle_lines']} satır, {len(cov['bundle'])} dosya: {', '.join(Path(b).name for b in cov['bundle'])}). Elle eklenen satır yok.\n")
    # ---- Experiment A
    P.append("## Deney A: araçlar kapalı, motor v2\n")
    P.append("Parantez içindeki sayı: `new Position(wireName()) + setDeviceId` kontrolünün 80 yerine 400 karakter penceresiyle puanı (yalnız ek sütun; ana skor değişmedi). `rolsüz` koşulu 2. turun birebir aynı koşulu olduğundan (aynı görev, kontroller, izolasyon, modeller) 2. tur çıktıları kopyalanarak kullanıldı, yeniden koşulmadı.\n")
    models_A = [d for d in sorted(A.iterdir()) if d.is_dir()]
    allA = defaultdict(list); allA400 = defaultdict(list); statsA = {}
    for md in models_A:
        t, st, st400, data = table_A(md, CONDS_A + [ABL]); statsA[md.name] = st
        P += [f"### Model `{md.name}`\n", t, ""]
        for c in CONDS_A + [ABL]:
            for n, r in data.get(c, {}).items():
                allA[c].append(r["score"]); allA400[c].append(r["score"] + (1 if POS_NAME in r["failed"] and pos400(md / f"{c}_{n}.md") else 0))
    P += ["### İki model birleşik (Deney A)\n", "| koşul | n | ortalama /19 | min | max | ort. pencere=400 |", "|---|---|---|---|---|---|"]
    for c in CONDS_A + [ABL]:
        xs = allA[c]; P.append(f"| {LABEL[c]} | {len(xs)} | {fm(xs)} | {min(xs) if xs else '–'} | {max(xs) if xs else '–'} | {fm(allA400[c])} |")
    gateA = mean(allA["rules_examples_v2"]) >= 16
    P.append(f"\n**Kapı A** (kurallar+örnekler v2 birleşik ≥16): ortalama **{mean(allA['rules_examples_v2']):.2f}** → {'GEÇTİ' if gateA else 'GEÇMEDİ'}.\n")
    # side by side with round 2
    P += ["### 2. turla yan yana (birleşik ortalama /19)\n", "| | 2. tur (v1) | 3. tur (v2) |", "|---|---|---|"]
    r2 = defaultdict(list)
    for md in sorted(R2.iterdir()):
        if md.is_dir():
            for c, rs in load(md, ["no_role", "rules", "example_only", "rules_example"]).items(): r2[c] += [r["score"] for r in rs.values()]
    for a, b in (("no_role", "no_role"), ("rules", "rules_v2"), ("example_only", "examples_v2"), ("rules_example", "rules_examples_v2")):
        P.append(f"| {LABEL[a]} → {LABEL[b]} | {fm(r2[a])} | {fm(allA[b])} |")
    # coverage
    P += ["\n### Kapsama raporu (`coverage.json`)\n", f"Hedef küme: üç ailede (Protocol, ProtocolDecoder, DecoderTest) dosyaların ≥%20'sinde geçen {cov['n_targets']} tanımlayıcı. Kapsama = dokümanda (kural veya örnek) görünen hedef yüzdesi.\n",
          "| doküman | kapsama | eşleşen skor (kurallar+örnek birleşik) |", "|---|---|---|",
          f"| v1 kurallar | {cov['v1_rules']['pct']}% | – |", f"| v1 örnek | {cov['v1_examples']['pct']}% | – |", f"| **v1 tam (2. tur)** | **{cov['v1_full']['pct']}%** | {fm(r2['rules_example'])} |",
          f"| v2 kurallar (miss dahil) | {cov['v2_rules']['pct']}% | {fm(allA['rules_v2'])} (yalnız kurallar) |", f"| v2 örnekler | {cov['v2_examples']['pct']}% | {fm(allA['examples_v2'])} (yalnız örnekler) |",
          f"| **v2 tam (3. tur)** | **{cov['v2_full']['pct']}%** | {fm(allA['rules_examples_v2'])} |", f"| v2 tam − miss-driven | {cov['v2_rules_nomiss+examples']['pct']}% | – |",
          f"\nv2 tam dokümanda hâlâ eksik hedefler (ilk 30): {', '.join('`%s`' % x for x in cov['v2_full']['missing'][:30])}\n"]
    # matrix A
    mt, matA, nA = matrix(models_A, CONDS_A + [ABL], load); P += ["### Kontrol × koşul matrisi (Deney A, iki model birleşik)\n", mt, ""]
    # ablation
    miss = json.loads((HERE / "ref/miss_rules_r3.json").read_text())
    n_rules = sum(1 for r in miss["rules"] if r["outputs"] >= 2); n_unk = sum(1 for u in miss["unknown"] if u["outputs"] >= 2)
    P += ["### Miss-driven mining: üretilen kurallar ve ablasyon\n",
          f"Miss-driven madenci 2. turun 6 rolsüz çıktısından **{n_rules} 'X yerine Y' kuralı** (hepsi otomatik eşleşme; `mutation_map.json` ile karşılaştırıldığında {sum(1 for r in miss['rules'] if r['outputs']>=2 and json.loads((HERE/'mutation_map.json').read_text()).get(r['old'])==r['new'])}/{n_rules} doğru) ve **{n_unk} bilinmeyen sapma** üretti (`ref/miss_rules_r3.json`). Bilinmeyenler: " + ", ".join(f"`{u['old']}`" + (f" (seçenekler listelendi)" if u['options'] else "") for u in miss["unknown"] if u["outputs"] >= 2) + ".",
          f"\nAblasyon (`rules_v2_nomiss`, RUNS=2, sistem eki = v2 kurallar **miss-driven bölümü çıkarılmış**, örnek yok): birleşik {fm(allA[ABL])} ↔ `rules_v2` {fm(allA['rules_v2'])} → miss-driven bölümünün katkısı **{mean(allA['rules_v2']) - mean(allA[ABL]):+.2f}** puan.\n"]
    # ---- Experiment B
    P.append("## Deney B: araçlar açık, gerçek taban çizgisi\n")
    P.append("Çalışma dizini: her koşu için `/tmp/traccar-r3` deposundan taze `git worktree`; bu depo mutasyonlu çatalın `r3-base` ağacının (R16h dosyaları ve `PortConfigSuffix` port girdisi çıkarılmış) **geçmişsiz tek commit'lik** kopyasıdır, koşu sonunda worktree silinir. Araçlar: Read/Glob/Grep/Write/Edit + salt-okur Bash (ls, grep, rg, find, cat, head, tail, wc, sed -n); `--permission-mode acceptEdits`, `--max-turns 80`, `--setting-sources \"\"`, `--strict-mcp-config`. Görev `task_agent.md` (son cümle: \"Create the three files in the repository.\"). Kayıt: `--output-format stream-json`.\n")
    models_B = [d for d in sorted(B.iterdir()) if d.is_dir()] if B.exists() else []
    aggB = defaultdict(lambda: defaultdict(list))
    for md in models_B:
        data = load(md, CONDS_B)
        P += [f"### Model `{md.name}`\n", "| koşul | # | uyum /19 | token (giriş+çıkış) | giriş | çıkış | araç çağrısı | tur | süre s | açılan dosya (Read+Bash) | Grep/Glob | maliyet $ | sonuç |", "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
        for c in CONDS_B:
            for n, r in sorted(data.get(c, {}).items()):
                s, m = r["score"], r["metrics"]
                P.append(f"| {LABEL[c]} | {n} | {s['score']}{' (inc)' if s.get('incomplete') else ''} | {m['tokens_total']} | {m['tokens_in_total']} | {m['tokens_out']} | {m['tool_calls']} | {m['num_turns']} | {m['wall_seconds']} | {m.get('files_opened_distinct', m['files_read_distinct'])} | {m['grep_glob_calls']} | {m['cost_usd'] if m['cost_usd'] is None else round(m['cost_usd'], 3)} | {m['result_subtype']} |")
                for k, v in (("score", s["score"]), ("tokens", m["tokens_total"]), ("tools", m["tool_calls"]), ("wall", m["wall_seconds"] or 0), ("reads", m.get("files_opened_distinct", m["files_read_distinct"])), ("cost", m["cost_usd"] or 0)):
                    aggB[c][k].append(v)
        P.append("")
    if models_B:
        P += ["### Koşul başına özet (Deney B, iki model birleşik)\n", "| koşul | n | uyum ort (min–max) | token ort (min–max) | araç çağrısı ort (min–max) | süre s ort (min–max) | açılan dosya ort | maliyet $ ort |", "|---|---|---|---|---|---|---|---|"]
        def mm(xs): return f"{mean(xs):.1f} ({min(xs)}–{max(xs)})" if xs else "–"
        for c in CONDS_B:
            a = aggB[c]; P.append(f"| {LABEL[c]} | {len(a['score'])} | {mm(a['score'])} | {mm(a['tokens'])} | {mm(a['tools'])} | {mm(a['wall'])} | {mean(a['reads']) if a['reads'] else 0:.1f} | {mean(a['cost']) if a['cost'] else 0:.2f} |")
        nr, rv = aggB["agent_no_role"], aggB["agent_role_v2"]
        if nr["score"] and rv["score"]:
            tok_ratio = mean(rv["tokens"]) / mean(nr["tokens"]) if mean(nr["tokens"]) else float("nan")
            tool_ratio = mean(rv["tools"]) / mean(nr["tools"]) if mean(nr["tools"]) else float("nan")
            comp_ok = mean(rv["score"]) >= mean(nr["score"]); cost_ok = tok_ratio <= 0.6 or tool_ratio <= 0.5
            P += ["", "| Kapı B ölçütü | değer | sonuç |", "|---|---|---|",
                  f"| uyum: rol v2 ≥ rolsüz | {mean(rv['score']):.2f} ≥ {mean(nr['score']):.2f} | {'✓' if comp_ok else '✗'} |",
                  f"| token oranı (rol/rolsüz) ≤ 0.60 | {tok_ratio:.2f} | {'✓' if tok_ratio <= 0.6 else '✗'} |",
                  f"| araç çağrısı oranı ≤ 0.50 | {tool_ratio:.2f} | {'✓' if tool_ratio <= 0.5 else '✗'} |",
                  f"| **Kapı B** | uyum VE (token VEYA araç) | **{'GEÇTİ' if comp_ok and cost_ok else 'GEÇMEDİ'}** |", ""]
            gateB = comp_ok and cost_ok
        else: gateB = None
        P += ["Model bazında Kapı B:", "", "| model | uyum rolsüz → rol v2 | token oranı | araç oranı | süre oranı | Kapı B |", "|---|---|---|---|---|---|"]
        for md in models_B:
            d = load(md, CONDS_B); g = {c: defaultdict(list) for c in CONDS_B}
            for c in CONDS_B:
                for r in d.get(c, {}).values():
                    g[c]["s"].append(r["score"]["score"]); g[c]["t"].append(r["metrics"]["tokens_total"]); g[c]["k"].append(r["metrics"]["tool_calls"]); g[c]["w"].append(r["metrics"]["wall_seconds"] or 0)
            a, b = g["agent_no_role"], g["agent_role_v2"]
            if a["s"] and b["s"]:
                tr, kr, wr = mean(b["t"]) / mean(a["t"]), mean(b["k"]) / mean(a["k"]), mean(b["w"]) / mean(a["w"])
                ok = mean(b["s"]) >= mean(a["s"]) and (tr <= 0.6 or kr <= 0.5)
                P.append(f"| `{md.name}` | {mean(a['s']):.2f} → {mean(b['s']):.2f} | {tr:.2f} | {kr:.2f} | {wr:.2f} | {'GEÇTİ' if ok else 'GEÇMEDİ'} |")
        P.append("")
        mtB, matB, nB = matrix(models_B, CONDS_B, load); P += ["### Kontrol × koşul matrisi (Deney B)\n", mtB, ""]
        missed = [(c[1], nB["agent_no_role"] - matB[c[1]]["agent_no_role"]) for c in CHECKS if matB[c[1]]["agent_no_role"] < nB["agent_no_role"]]
        P += ["### Ajan keşfe rağmen neyi bulamıyor? (agent_no_role'ün kaçırdığı kontroller)\n"]
        P += [f"- `{name}`: {k}/{nB['agent_no_role']} koşuda kaçtı" for name, k in sorted(missed, key=lambda x: -x[1])] or ["- hiçbiri: ajan tüm kontrolleri geçti"]
        P.append("")
    else: gateB = None
    # ---- verdict
    P.append("## Yorum\n")
    a_mean = mean(allA["rules_examples_v2"]); v2cov = cov["v2_full"]["pct"]
    if gateA and gateB: P.append("**A ≥16 ve B geçer → Faz 1'e geçilebilir; ürün değeri: özel repoda uyum + maliyet.**")
    elif gateA and gateB is False and aggB and mean(aggB['agent_role_v2']['score']) >= mean(aggB['agent_no_role']['score']): P.append("**A ≥16, B'de uyum eşit/yüksek ama maliyet farkı eşiği geçmiyor → ürün değeri yalnız maliyet/tutarlılık değil, keşfin kaçırdıkları; B'deki kaçırılan kontrol listesine göre yeniden konumlan.**")
    elif not gateA:
        P.append(f"**A <16 ({a_mean:.2f}).** Kapsama raporu: v2 tam doküman kapsaması **{v2cov}%** → " + ("kapsama ≥%90 iken skor düşük: sorun öğrenmede (örnek uzunluğu/dikkat)." if v2cov >= 90 else "kapsama <%90: sorun motorda (hedef tanımlayıcıların bir kısmı hâlâ dokümanda yok)."))
        if gateB is not None: P.append(f" Kapı B ayrıca {'geçti' if gateB else 'geçmedi'}.")
    else: P.append("Hazır eşik kalıplarının hiçbiri tam oturmadı; sayılar yukarıda.")
    P += ["\n## Gözlemler\n",
      f"- **Deney A:** kurallar+örnekler v2 default'ta 19/19/19, sonnet'te 17/17/16; birleşik 17.83 (2. tur v1: 13.00, +4.83). Kapsama 46.9% → 78.8%. 400-karakter pencere sütunu hiçbir puanı değiştirmedi: v2 dokümanıyla modeller `setDeviceId`'yi Position'dan hemen sonra yazıyor (örnek demetindeki decoder öyle).",
      "- **A'da hâlâ kaçanlar (kurallar+örnekler v2, 6 çıktı):** `nextCoordinate(WHOLE_DEG_HEMI)` 3/6 ve `GlyphBoundaryFrameSplitter` pipeline 3/6; ikisi de dokümanda yalnız dolaylı geçiyor (WHOLE_DEG_HEMI 'bilinmeyen sapma' seçenek listesinde, GlyphBoundaryFrameSplitter `addLast` argüman dağılımında 54/267). Sonnet bu ikisini default'tan daha sık kaçırıyor. Miss-driven madenci `DEG_HEM` için konumdan tek karşılık seçemedi (semantik sabit); `KEY_ARCHIVE` için seçenek de üretemedi.",
      f"- **Ablasyon:** miss-driven bölümü çıkarılınca kurallar v2 15.50 → 13.50 (default 17.33 → 15.50, sonnet 13.67 → 11.50); 16 'X yerine Y' kuralı ~2 puan taşıyor; miss-driven bölümü kapsamaya yalnız +1.3 puan ekliyor (77.5% → 78.8%) ama etkisi kapsama farkından büyük, çünkü modelin **ezberden yazdığı yanlış adı** doğrudan hedefliyor.",
      "- **Kurallar v2 tek başına** (15.50) örnekler v2'den (13.00) daha güçlü; 2. turda tersiydi (v1 kurallar 10.33 < örnek 12.00). Fark alternatif kuralları ve miss-driven bölüm. Sonnet kurallar v2'de yüksek varyans (17, 12, 12).",
      "- **Deney B:** araçlar açıkken rolsüz ajan zaten 17.67 (default 18.67, sonnet 16.67) alıyor; rol v2 ile 18.83 (default 18.67, sonnet 19.00). Uyum kazancı küçük ve sonnet'te; default zaten tavana yakın. Maliyet: default'ta rol v2 token'ı 0.45×, araç çağrısını 0.48×, süreyi 0.60× (Kapı B default için geçer); sonnet'te 0.91× / 0.80× / 0.78× (geçmez): sonnet rol dokümanına rağmen keşfi kısaltmıyor. Birleşik oranlar 0.75 / 0.66 → Kapı B geçmedi.",
      "- **Ajan keşfe rağmen kaçırdıkları:** en sık `GlyphBoundaryFrameSplitter` pipeline (2/6; ajan Netty `DelimiterBasedFrameDecoder`/başka frame decoder seçiyor), sonra tek tek `WHOLE_DEG_HEMI`, `asciiFrame/assertNoOutput`, `GrammarComposer` (sonnet'in 14/19'luk koşusu). Beklenen üçlüden datagram bayrağı ajanlarca 6/6 bulundu (görev metni UDP diyor), frame splitter ve coordinate format kaçtı; rol v2 ile hepsi 6/6.",
      "- **Maliyet ölçeği:** ajan koşusu başına 0.8–1.8 $ (default) ve 0.77–0.98 $ (sonnet) karşısında araçsız tek çağrı; ajan token'ının %97+'si önbellekten okunan bağlam (`cache_read_input_tokens`).",
    ]
    P += ["\n## Yöntem notları\n",
      "- **Duman testi sızıntısı (düzeltildi):** ilk ajan denemesi `/tmp/traccar-mut` worktree'sinde koştu; worktree ana repoyla `.git` nesne deposunu paylaştığı için ajan `git log --all | grep -i r16h` ve `git show 6918e9f` ile gerçek R16h dosyalarını geçmişten okudu ve 19/19 aldı (`out-r3-agent-smoke/`, geçersiz, sayılmadı). Ayrıca `--allowedTools` listesi tırnaksız geçildiği için Bash fiilen sınırsızdı. Düzeltme: `r3-base` ağacından **geçmişsiz tek commit'lik** `/tmp/traccar-r3` deposu; allowlist dizi olarak; `Bash(git *)`, `rm`, `curl`, `wget` yasak; izin probu ile `git log` reddinin doğrulanması. Bütün B koşuları bu düzenle yapıldı.",
      "- **İzin esnekliği:** `acceptEdits` + allowlist altında CLI `echo`, `./gradlew` gibi listede olmayan komutlara da izin verdi (probda `echo hello` çalıştı). Ajanlar `./gradlew test` denedi; JDK 17 yüzünden başarısız oldu, yalnız süre/token maliyeti ekledi. Yasaklı `git` komutları reddedildi (probda doğrulandı) ve depoda zaten geçmiş yok.",
      "- **Sızıntı denetimi:** her B koşusunun Bash komutları tarandı; ajanlar `grep -rn r16h` ile depoyu aradı ve hiçbir eşleşme bulamadı (R16h dosyaları ve `PortConfigSuffix` girdisi çıkarılmış). Mutasyon eşlemesini ifşa edecek bir kaynak (git diff, eski adlar) depoda yok.",
      "- **`rolsüz` (Deney A):** 2. tur çıktıları yeniden kullanıldı (aynı görev metni, kontroller, izolasyon bayrakları, modeller ve NO_TOOLS_PREFIX); `out-mut/*/no_role_*` → `out-r3/*/no_role_*` kopyası.",
      "- **Açılan dosya metriği:** Read aracıyla okunan dosyalar + Bash `cat/head/tail/sed -n` hedefleri (komut metninden çıkarılan `.java/.xml/...` yolları), dosya adına göre tekilleştirilmiş. `Grep/Glob` sütunu Grep ve Glob araç çağrılarının sayısı; ajanlar aramayı çoğunlukla Bash `grep` ile yaptı, o çağrılar `araç çağrısı` toplamında.",
      "- **Token:** stream-json `result.usage` alanı: giriş = `input_tokens + cache_creation_input_tokens + cache_read_input_tokens` (önbellekten okunanlar dahil; ajanın bağlamı her turda yeniden okunur), çıkış = `output_tokens`. Maliyet `total_cost_usd`.",
      "- Örnek demeti seçimi kapsama-maksimizasyonu ile yapıldı (spec); eşitlik kırıcı olarak decoder+test aynı tabana +1 tanımlayıcı ağırlığı verildi, buna rağmen kapsama daha yüksek çıkan tutarsız demet (ArnaviProtocolDecoder + BlueProtocolDecoderTest) seçildi. Soyut sınıflar aday dışı.",
      "- Miss-driven madenci Netty `Unpooled.wrappedBuffer/copiedBuffer` için iki 'bilinmeyen sapma' satırı üretti (model import etmeden kullanmış); bu adlar depoda gerçekten yok, satırlar doğru ama alakasız. Elle silinmedi.",
      "- Deney A'da ablasyon çağrısı `scores.csv` özetini sıfırladı; JSON sonuçlar etkilenmedi, özet JSON'lardan yeniden üretildi ve runner düzeltildi.",
    ]
    P.append("\nHam çıktılar: Deney A `out-r3/<model>/`, Deney B `out-r3-agent/<model>/` (`*.stream.jsonl` tam kayıt, `*.md` dosyalardan derlenen üç dosya, `*.json` puan+metrik). Motor: `mine_v2.py`, `miss_mining.py`, `compile_role_v2.py`; kapsama: `coverage.json`.")
    (HERE / "results-r3.md").write_text("\n".join(P) + "\n"); print("\n".join(P))

if __name__ == "__main__":
    main()
