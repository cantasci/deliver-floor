#!/usr/bin/env python3
"""Aggregate out-mut/<model>/*.json into results-mut.md, side by side with round 1 (out/)."""
import json, re
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "out-mut"
OUT1 = HERE / "out"
CONDS = ["no_role", "rules", "example_only", "rules_example"]
CONDS1 = ["no_role", "rules", "rules_example"]
LABEL = {"no_role": "rolsüz", "rules": "kurallar", "example_only": "sadece örnek", "rules_example": "kurallar+örnek"}
CHECKS = json.loads((HERE / "checks.json").read_text())
CHECKS1 = json.loads((HERE / "ref/round1/checks.json").read_text())
RULES_TXT = (HERE / "role_rules.md").read_text()
MAP = json.loads((HERE / "mutation_map.json").read_text())

def load(model_dir: Path, conds):
    data = defaultdict(dict)
    for j in sorted(model_dir.glob("*_[0-9]*.json")):
        cond, n = j.stem.rsplit("_", 1)
        if cond in conds:
            data[cond][int(n)] = json.loads(j.read_text())
    return data

def complete(rs):
    return [r for r in rs.values() if not r.get("incomplete")]

def mean(xs):
    return sum(xs) / len(xs) if xs else float("nan")

def fmt_mean(xs):
    return f"{sum(xs)}/{len(xs)} = {mean(xs):.2f}" if xs else "–"

def table(data, runs, conds):
    lines = ["| koşul | " + " | ".join(f"#{i}" for i in range(1, runs + 1)) + " | ortalama /19 | incomplete |",
             "|---|" + "---|" * runs + "---|---|"]
    stats = {}
    for c in conds:
        rs = data.get(c, {})
        cells = []
        for i in range(1, runs + 1):
            if i not in rs: cells.append("–")
            elif rs[i].get("incomplete"): cells.append(f"({rs[i]['score']}) inc")
            else: cells.append(str(rs[i]["score"]))
        xs = [r["score"] for r in complete(rs)]
        stats[c] = mean(xs)
        n_inc = sum(1 for r in rs.values() if r.get("incomplete"))
        lines.append(f"| {LABEL[c]} | " + " | ".join(cells) + f" | {fmt_mean(xs)} | {n_inc} |")
    return "\n".join(lines), stats

def check_matrix(models, conds, checks):
    names = [c[1] for c in checks]
    mat = {c: Counter() for c in names}; n = Counter()
    for md in models:
        for cond, rs in load(md, conds).items():
            for r in complete(rs):
                n[cond] += 1
                for p in r["passed"]: mat[p][cond] += 1
    lines = ["| kontrol | " + " | ".join(LABEL[c] for c in conds) + " | toplam |", "|---|" + "---|" * (len(conds) + 1)]
    for c in names:
        lines.append(f"| `{c}` | " + " | ".join(f"{mat[c][k]}/{n[k]}" for k in conds) + f" | {sum(mat[c].values())}/{sum(n.values())} |")
    return "\n".join(lines), mat, n

def rule_mentions(check_name):
    """Which mutated identifiers in this check appear anywhere in role_rules.md?"""
    toks = set(re.findall(r"[A-Za-z_]\w+", check_name))
    ids = [v for v in MAP.values() if v in toks]
    hits = [i for i in ids if re.search(r"\b%s\b" % re.escape(i), RULES_TXT)]
    return ids, hits

def observations(models):
    import sys
    sys.path.insert(0, str(HERE)); import scorer
    rows = defaultdict(Counter)
    for md in models:
        for fn in sorted(md.glob("*_[0-9].md")):
            cond = fn.stem.rsplit("_", 1)[0]
            b = scorer.split_blocks(fn.read_text())
            p, d, t = b["protocol"], b["decoder"], b["test"]
            g = lambda rx, txt, grp=1: (re.search(rx, txt).group(grp) if re.search(rx, txt) else "?")
            rows["decoder extends"][(cond, g(r"class R16hProtocolDecoder extends (\w+)", d))] += 1
            rows["pattern builder sınıfı"][(cond, g(r"new (\w+)\(\)\s*\n?\s*\.(?:text|expression|number)", d))] += 1
            rows["new Position(arg)"][(cond, g(r"new Position\((\w+)", d))] += 1
            rows["setDeviceId(<var>.getDeviceId())"][(cond, g(r"setDeviceId\((\w+)\.getDeviceId", d))] += 1
            rows["setLatitude argümanı"][(cond, re.sub(r"\s+", " ", g(r"setLatitude\(([^;]*)\)", d))[:55])] += 1
            rows["setSpeed argümanı"][(cond, re.sub(r"\s+", " ", g(r"setSpeed\(([^;]*)\)", d))[:55])] += 1
            rows["protocol extends"][(cond, g(r"class R16hProtocol extends (\w+)", p))] += 1
            rows["addServer(new <X>(<args>"][(cond, g(r"addServer\(new (\w+\([^)]*)", p)[:40])] += 1
            fd = re.findall(r"new (\w*(?:FrameDecoder|Splitter))\(", p); rows["frame decoder sınıfı"][(cond, fd[0] if fd else "?")] += 1
            rows["@Inject var"][(cond, "evet" if "@Inject" in p else "hayır")] += 1
            rows["test extends"][(cond, g(r"class R16hProtocolDecoderTest extends (\w+)", t))] += 1
            rows["inject helper"][(cond, g(r"= (\w+)\(new R16hProtocolDecoder", t))] += 1
            lk = re.findall(r"\n\s*(\w+)\((?:decoder, )?(\w+)\(\s*\n?\s*\"@LINK", t)
            rows["@LINK test çağrısı"][(cond, (lk[0][0] + "(…" + lk[0][1] + "(") if lk else "LINK testi yok")] += 1
    out = ["Aşağıdaki tablo her koşulda modelin ilgili yere ne yazdığını sayar (iki model birleşik, koşul başına 6 çıktı). Eski Traccar adı = ezber; yeni ad = rol dokümanından öğrenilmiş.\n",
           "| yer | rolsüz | kurallar | sadece örnek | kurallar+örnek |", "|---|---|---|---|---|"]
    for k, c in rows.items():
        cells = []
        for cond in CONDS:
            items = sorted([(v, n) for (cc, v), n in c.items() if cc == cond], key=lambda x: -x[1])
            cells.append("; ".join(f"`{v}` ×{n}" for v, n in items))
        out.append(f"| {k} | " + " | ".join(cells) + " |")
    out += ["",
        "- **Ezber baskın:** rolsüz koşulda 6/6 çıktı `BaseProtocolDecoder`, `BaseProtocol`, `TrackerServer`, `PatternBuilder`, `ProtocolTest`, `inject`, `getProtocolName`, `DEG_HEM`, `knotsFromKph`, `verifyNull/text` yazdı; yani model bu repoyu okumuyor, Traccar'ı hatırlıyor. Puan 6/19 = yeniden adlandırılmamış 6 kontrol.",
        "- **Kurallar yalnız içinde geçen adları öğretiyor:** `AbstractWireDecoder` 6/6, `WireProtocolRoot` 6/6, `EndpointListener` 5/6, `resolveUnitSession`, `wireName` 6/6, `wireUp` 4/6. Kural listesinde olmayan `GrammarComposer` (0/6, çünkü decoder'ların yalnız ~%50'si kullanıyor, %90 eşiği altında) ve `WireDecoderHarness` (0/6, madenci test aileleri için extends kuralı üretmiyor; oysa 325/332 test bunu extend ediyor) öğrenilmiyor.",
        "- **Örnek yalnız içinde görünenleri öğretiyor:** `GrammarComposer` 6/6, `WireDecoderHarness` 6/6, `wireUp` 6/6, `resolveUnitSession(channel, remoteAddress, parser.next())` 6/6. Örnekte Protocol sınıfı yok → `WireProtocolRoot` 0/6, `EndpointListener` 0/6 (model `BaseProtocol`/`TrackerServer` yazıyor). Örnek `nextCoordinate()` (biçimsiz) ve düz `nextDouble` hız kullanıyor → `WHOLE_DEG_HEMI` ve `nauticalFromMetricSpeed` öğretilmiyor.",
        "- **Hiçbir yerde görünmeyen adlar 0/24:** `GlyphBoundaryFrameSplitter`, `WHOLE_DEG_HEMI`, `nauticalFromMetricSpeed`, `assertNoOutput`/`asciiFrame` (örnekte `asciiFrame` var ama `assertNoOutput` yok; model LINK testi için ad uyduruyor: `assertNothingDecoded`, `assertFixSkipped`, ya da ezber `verifyNull`; 6 çıktı LINK testini hiç yazmıyor). Dikkat: `UnitsConverter` sınıfı yeniden adlandırılmadığı için model `UnitsConverter.knotsFromKph` yazmaya güvenle devam ediyor; benzer şekilde `FieldCursor.CoordinateFormat.DEG_HEM` gibi yarı-yeni/yarı-ezber melezler üretiyor.",
        "- **`new Position(wireName()) + setDeviceId` kontrolündeki düşüş (rolsüz 0/6 → kurallar 5/6 → sadece örnek 1/6 → kurallar+örnek 3/6) bir kontrol artefaktı:** regex `new Position(wireName())` ile `setDeviceId(deviceSession.getDeviceId())` arasında ≤80 karakter istiyor. Rol koşullarındaki 18 çıktının hepsi `wireName()` ve `deviceSession.getDeviceId()` biçimini doğru yazıyor ve sıralama hepsinde session→Position→setDeviceId; fark yalnız aradaki mesafe: kurallar koşulunda 43-47 karakter, örnek verilen koşullarda 9/12 çıktıda 211-231 karakter (araya başka setter'lar giriyor; örnek de `setDeviceId`'yi `new Position`'dan 3 satır sonra çağırıyor). Kural gereği kontrol yumuşatılmadı; ama bu kaçış konvansiyon kaçışı değil, pencere artefaktı.",
        "- **`EndpointListener` / `WireProtocolRoot` kontrolleri adı öğrenince bile düşüyor:** kurallar+örnek koşulunda 5/6 `extends WireProtocolRoot` yazıldı ama kontrol 1/6; çünkü kontrol ayrıca `@Inject` (toplam 10/24 çıktıda var; madenci anotasyon kuralı üretmiyor) ve `EndpointListener(config, getName(), true)` argüman sırasını istiyor; model `EndpointListener(true, getName())` / `(this, getName())` gibi eski Traccar API biçimlerini ezberden yazıyor.",
        "- **Model aileleri:** rolsüz ikisi de 6.00; kurallar koşulunda default 12.00, sonnet 8.67 (sonnet kural listesinden daha az yararlanıyor: `resolveUnitSession(...)` 0/3, `wireUp` 1/3); sadece örnek ve kurallar+örnek koşullarında ikisi de 12.00 ve 13.00, yani örnek verildiğinde aile farkı kapanıyor.",
        "- **Eşik yorumu:** rol eklemek rolsüz 6.00'ı kurallar+örnek 13.00'a taşıyor (+7); etki gerçek ama ≥16 eşiğine ulaşmıyor. Kurallar+örnek (13.00) ile sadece örnek (12.00) arasındaki fark 1 puan; kurallar tek başına (10.33) örneğin altında.",
    ]
    return "\n".join(out)

def verdict(s):
    nr, ru, ex, re_ = s["no_role"], s["rules"], s["example_only"], s["rules_example"]
    out = []
    if nr <= 10 and re_ >= 16:
        out.append("**Rol etkisi özel repoda kanıtlandı**; halka açık repoda görünmemesi modelin ezberinden.")
    if nr <= 10 and re_ <= 13:
        out.append("**Motorun çıkardığı kurallar yetersiz**: ayırt edici kurallar (delimiter, coordinate format, datagram) madenciye girmiyor.")
    if nr >= 15:
        out.append("**Mutasyon sızdırıyor** (rolsüz hâlâ ≥15): eski adlar kalmış olabilir, sızıntı listesi kontrol edilmeli.")
    if abs(ex - re_) <= 1.0:
        out.append("**Sadece örnek ≈ kurallar+örnek**: değer örnekte; kural listesi ürünün çekirdeği olamaz, örnek seçimi çekirdek olmalı.")
    if 10 < nr < 15 and not out:
        out.append("Rolsüz 10-15 arasında: hazır eşiklerin hiçbiri tam oturmadı; sayılar olduğu gibi.")
    if not out:
        out.append("Hazır eşik kalıplarının hiçbiri oturmadı; sayılar olduğu gibi.")
    return " ".join(out)

def main():
    models = [d for d in sorted(OUT.iterdir()) if d.is_dir() and (d / "scores.csv").exists()]
    models1 = [d for d in sorted(OUT1.iterdir()) if d.is_dir() and (d / "scores.csv").exists() and not d.name.startswith("_")]
    P = ["# Rol deneyi, 2. tur: sözde-özel repo (mutasyonlu Traccar çatalı)\n",
         "Aynı görev, dört koşul, iki model ailesi. Repo: `/tmp/traccar-mut` (Traccar `e760853` üzerine tek commit `bf707e9`, 999 dosya; 25 tanımlayıcı `mutation_map.json` ile yeniden adlandırıldı). Rol dokümanları madenci ile **mutasyonlu repodan** üretildi; elle kural eklenmedi. Kontroller `mutation_map.json` ile çevrildi; `@LINK` kontrolü davranış düzeyine indirildi; mutasyonlu gerçek PR (`ref/real_pr_mut.md`) **19/19**.\n"]
    overall = defaultdict(list); per_model_stats = {}
    for md in models:
        data = load(md, CONDS)
        runs = max((max(v) for v in data.values() if v), default=0)
        t, stats = table(data, runs, CONDS); per_model_stats[md.name] = stats
        P += [f"## Model: `{md.name}`\n", t + "\n", "**Yorum:** " + verdict(stats) + "\n"]
        for c in CONDS: overall[c] += [r["score"] for r in complete(data.get(c, {}))]
    P += ["## İki model birleşik\n", "| koşul | n | ortalama /19 | min | max |", "|---|---|---|---|---|"]
    st = {c: mean(overall[c]) for c in CONDS}
    for c in CONDS:
        xs = overall[c]
        P.append(f"| {LABEL[c]} | {len(xs)} | {fmt_mean(xs)} | {min(xs) if xs else '–'} | {max(xs) if xs else '–'} |")
    P.append("\n**Yorum (birleşik):** " + verdict(st) + "\n")
    # side by side with round 1
    r1 = defaultdict(list)
    for md in models1:
        d1 = load(md, CONDS1)
        for c in CONDS1: r1[c] += [r["score"] for r in complete(d1.get(c, {}))]
    P += ["## İlk turla yan yana (koşul ortalaması /19)\n",
          "| koşul | halka açık repo (1. tur, opus-5 ×2 varyant) | sözde-özel repo (2. tur, tüm modeller) | fark |", "|---|---|---|---|"]
    for c in CONDS:
        a = r1.get(c, []); b = overall[c]
        diff = f"{mean(b) - mean(a):+.2f}" if a and b else "–"
        P.append(f"| {LABEL[c]} | {fmt_mean(a) if a else '– (koşul yoktu)'} | {fmt_mean(b)} | {diff} |")
    P.append("\n1. turda `addServer(..., true)` kontrolü görev metnindeki TCP/UDP çelişkisi yüzünden kazanılamazdı (tavan 18); 2. turda görev metni düzeltildi (tavan 19) ve `@LINK` kontrolü davranış düzeyinde. Bu yüzden 1. tur ortalamaları en fazla ~1.5 puan aşağı yanlıdır; yan yana karşılaştırmada bunu hesaba katın.\n")
    # check matrix
    P.append("## Kontrol × koşul geçme matrisi (2. tur, iki model birleşik)\n")
    mt, mat, n = check_matrix(models, CONDS, CHECKS); P.append(mt + "\n")
    # per model matrices (short)
    for md in models:
        mt_m, _, _ = check_matrix([md], CONDS, CHECKS)
        P += [f"<details><summary>Kontrol matrisi, yalnız `{md.name}`</summary>\n", mt_m, "\n</details>\n"]
    # missed checks vs role_rules coverage
    P.append("## Kaçan kontroller ve role_rules.md kapsamı (kurallar+örnek koşulu)\n")
    P += ["| kontrol | kurallar+örnek geçme | kontroldeki mutasyonlu adlar | role_rules.md'de geçiyor mu? |", "|---|---|---|---|"]
    for c in CHECKS:
        name = c[1]; passed = mat[name]["rules_example"]; tot = n["rules_example"]
        if passed < tot:
            ids, hits = rule_mentions(name)
            P.append(f"| `{name}` | {passed}/{tot} | {', '.join(ids) if ids else '–'} | {'evet: ' + ', '.join(hits) if hits else ('hayır' if ids else 'n/a')} |")
    # method
    P += ["\n## Yöntem ve ham çıktılar\n",
          "- Ham çıktılar: `out-mut/<model>/<koşul>_<n>.md|json|err`, özet `out-mut/<model>/scores.csv`, koşu logları `out-mut/run_*.log`.",
          "- İzolasyon 1. turla aynı: boş `mktemp -d`, `claude -p --tools \"\" --strict-mcp-config --setting-sources \"\" --permission-prompts none`, görev metninin başında sabit `NO_TOOLS_PREFIX` (dört koşulda aynı).",
          "- Modeller: `default` = CLI varsayılanı (1. turda `claude-opus-5[1m]` olarak çözümlendi); `sonnet` = `--model sonnet` (farklı aile).",
          "- Mutasyon: `mutate.py` (+ `mutation_map.json`); sızıntı kontrolü `grep -rnw` ile 26 eski adın tümü 0 isabet (`src/`). Derleme: makinede yalnız JDK 17 var, repo Java 21 istiyor; `./gradlew compileJava` iki çatalda da aynı Java 21 sözdizimi hatalarıyla duruyor (`out/gradle_compile_control*.log`). Kanıt için gradle'dan classpath alınıp protobuf kaynakları üretildi ve `javac --release 17 --enable-preview` ile Java-21-record-pattern kullanan iki dosya hariç tüm `src/main` derlendi (`out/javac_control2.log`): **her iki çatalda 826 sınıf derlendi, kalan 8 hata birebir aynı** (Java 21 API `List.getFirst/getLast/removeLast` ×6 ve hariç tutulan iki sınıfa referans ×2). Mutasyondan kaynaklanan tek bir sembol hatası yok.",
          "- Madenci: `mine_invariants.py` → `extract_rules.py` → `compile_role.py`. Bu script'ler diskte yoktu; 1. tur `role_rules.md` biçimini yeniden üretecek şekilde bu turda yazıldı. Halka açık repoda yeniden üretim (`ref/rules_public_regen.md`) 1. tur listesinin tüm çekirdek kurallarını aynı kesirlerle veriyor (268/274, 250/274, 267/268, 134/139); ek olarak birkaç kural daha buluyor (getDeviceId, set, getType, readerIndex, *test:EncoderTest, *FrameDecoder extends) ve 1. turdaki tek `switch` negatif kuralını aynı şekilde üretiyor.",
          "- 1. tur dosyalarının orijinalleri `ref/round1/` altında (task.md TCP sürümü, checks.json, role_rules.md, role_example.md)."]
    # miss-driven mining input
    P.append("\n## Gözlemler (ham çıktılardan hesaplandı)\n")
    P.append(observations(models))
    P.append("\n## Model bu repoda nerede yanılıyor: rolsüz çıktılarda en sık kaçan kontroller (miss-driven mining girdisi)\n")
    miss = Counter(); tot = 0
    for md in models:
        for r in complete(load(md, CONDS).get("no_role", {})):
            tot += 1; miss.update(r["failed"])
    ranked = miss.most_common()
    top5_cut = ranked[4][1] if len(ranked) >= 5 else 0
    shown = [(k, v) for k, v in ranked if v >= top5_cut]
    P.append(f"İlk 5 istendi; {len(shown)} kontrol {shown[0][1]}/{tot} ile berabere olduğu için hepsi listelendi. Rolsüz kaçışların tamamı yeniden adlandırılmış tanımlayıcı içeren kontroller: model her seferinde ezberdeki Traccar adını yazıyor.\n")
    P += ["| kontrol | rolsüz kaçış | ilgili mutasyonlu adlar | role_rules.md'de | role_example.md'de |", "|---|---|---|---|---|"]
    ex_txt = (HERE / "role_example.md").read_text()
    for name, k in shown:
        ids, hits = rule_mentions(name)
        in_ex = [i for i in ids if re.search(r"\b%s\b" % re.escape(i), ex_txt)]
        P.append(f"| `{name}` | {k}/{tot} | {', '.join(ids) if ids else '–'} | {', '.join(hits) if hits else 'yok'} | {', '.join(in_ex) if in_ex else 'yok'} |")
    P.append("\nMiss-driven mining için çıkarım: rolsüz kaçan 13 kontrolün 4'ündeki ad ne kural listesinde ne örnekte (GlyphBoundaryFrameSplitter, WHOLE_DEG_HEMI, nauticalFromMetricSpeed, assertNoOutput) ve bu 4 kontrol tüm koşullarda 0/24; 2 ad yalnız örnekte (GrammarComposer, WireDecoderHarness) ve yalnız örnek verilen koşullarda 6/6 öğreniliyor; 2 ad yalnız kural listesinde (WireProtocolRoot, EndpointListener) ve yalnız kural verilen koşullarda öğreniliyor. Bunlar aile içinde %90 eşiğini geçmeyen ama *değişen* adlar; bir sonraki motor sürümü, modelin rolsüz çıktısında görünen eski adları (BaseProtocol, TrackerServer, Parser, DEG_HEM, knotsFromKph, verifyNull, text) repoda arayıp bulamadığında \"bu ad bu repoda X'tir\" kuralı üretmeli.")
    (HERE / "results-mut.md").write_text("\n".join(P) + "\n")
    print("\n".join(P))

if __name__ == "__main__":
    main()
