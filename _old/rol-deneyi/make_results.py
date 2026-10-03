#!/usr/bin/env python3
"""Aggregate out/<model>/*.json into results.md."""
import json
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
CONDS = ["no_role", "rules", "rules_example"]
LABEL = {"no_role": "rolsüz", "rules": "kurallar", "rules_example": "kurallar+örnek"}

def load(model_dir: Path):
    data = defaultdict(dict)  # cond -> n -> result
    for j in sorted(model_dir.glob("*_[0-9]*.json")):
        cond, n = j.stem.rsplit("_", 1)
        if cond not in CONDS:
            continue
        data[cond][int(n)] = json.loads(j.read_text())
    return data

def mean(xs):
    return sum(xs) / len(xs) if xs else float("nan")

def table(data, runs):
    lines = ["| koşul | " + " | ".join(f"#{i}" for i in range(1, runs + 1)) + " | ortalama /19 | incomplete |",
             "|---|" + "---|" * runs + "---|---|"]
    stats = {}
    for c in CONDS:
        rs = data.get(c, {})
        complete = [rs[i] for i in sorted(rs) if not rs[i].get("incomplete")]
        scores = [rs[i]["score"] if i in rs else None for i in range(1, runs + 1)]
        cells = []
        for i in range(1, runs + 1):
            if i not in rs:
                cells.append("–")
            elif rs[i].get("incomplete"):
                cells.append(f"({rs[i]['score']}) inc")
            else:
                cells.append(str(rs[i]["score"]))
        tot = sum(r["score"] for r in complete)
        m = mean([r["score"] for r in complete])
        n_inc = sum(1 for r in rs.values() if r.get("incomplete"))
        stats[c] = m
        lines.append(f"| {LABEL[c]} | " + " | ".join(cells) + f" | {tot}/{len(complete)} = {m:.2f} | {n_inc} |")
    return "\n".join(lines), stats

def top_missed(data):
    lines = []
    for c in CONDS:
        cnt = Counter()
        rs = [r for r in data.get(c, {}).values() if not r.get("incomplete")]
        for r in rs:
            cnt.update(r["failed"])
        top = cnt.most_common(3)
        if not top:
            lines.append(f"- **{LABEL[c]}**: hiç kaçırılan kural yok")
        else:
            lines.append(f"- **{LABEL[c]}**: " + "; ".join(f"`{k}` ({v}/{len(rs)})" for k, v in top))
    return "\n".join(lines)

def check_matrix(models):
    checks = [c[1] for c in json.loads((HERE / "checks.json").read_text())]
    mat = {c: Counter() for c in checks}
    n = Counter()
    for md in models:
        for cond, rs in load(md).items():
            for r in rs.values():
                if r.get("incomplete"):
                    continue
                n[cond] += 1
                for p in r["passed"]:
                    mat[p][cond] += 1
    lines = ["| kontrol | " + " | ".join(LABEL[c] for c in CONDS) + " | toplam |",
             "|---|" + "---|" * (len(CONDS) + 1)]
    for c in checks:
        tot = sum(mat[c].values())
        lines.append(f"| `{c}` | " + " | ".join(f"{mat[c][k]}/{n[k]}" for k in CONDS) + f" | {tot}/{sum(n.values())} |")
    return "\n".join(lines)

def verdict(s):
    nr, ru, ex = s["no_role"], s["rules"], s["rules_example"]
    out = []
    if nr <= 12 and ru >= 15 and ex >= 17:
        out.append("Eşiklere göre **rol etkisi kanıtlandı** (rolsüz ≤12, kurallar ≥15, kurallar+örnek ≥17).")
    if nr >= 15:
        out.append("Rolsüz koşul zaten ≥15: halka açık repoda rolün katkısı düşük; model Traccar kalıplarını eğitim verisinden biliyor. **Özel repoda tekrar gerek.**")
    if abs(ru - nr) <= 1.0 and ex - ru >= 2.0:
        out.append("Kurallar ≈ rolsüz ama kurallar+örnek belirgin yüksek: **değer kuralda değil, örnek getirmede.**")
    if not out:
        out.append("Hiçbir hazır eşik kalıbı tam oturmadı; sayılar yukarıda olduğu gibi.")
    return " ".join(out)

def main():
    models = [d for d in sorted(OUT.iterdir()) if d.is_dir() and (d / "scores.csv").exists()]
    parts = ["# Rol deneyi sonuçları\n",
             "Görev: traccar/traccar commit `6918e9f` (\"Implement R16H protocol\", 20 Mayıs 2026) türevi. 19 kontrol; gerçek PR `ref/real_pr.md` ile scorer'dan **19/19** aldı.\n",
             "Koşullar arasında tek fark `--append-system-prompt` eki; `task.md` metni üç koşulda birebir aynı.\n"]
    overall = defaultdict(list)
    for md in models:
        data = load(md)
        runs = max((max(v) for v in data.values() if v), default=0)
        t, stats = table(data, runs)
        parts.append(f"## Model: `{md.name}`\n")
        parts.append(t + "\n")
        parts.append("En çok kaçırılan 3 kural (yalnız complete çıktılar):\n")
        parts.append(top_missed(data) + "\n")
        parts.append("**Yorum:** " + verdict(stats) + "\n")
        for c in CONDS:
            overall[c].extend(r["score"] for r in data.get(c, {}).values() if not r.get("incomplete"))
    parts.append("## Tüm modeller birleşik\n")
    parts.append("| koşul | n | ortalama /19 | min | max |\n|---|---|---|---|---|")
    st = {}
    for c in CONDS:
        xs = overall[c]
        st[c] = mean(xs)
        parts.append(f"| {LABEL[c]} | {len(xs)} | {sum(xs)}/{len(xs)} = {mean(xs):.2f} | {min(xs) if xs else '–'} | {max(xs) if xs else '–'} |")
    parts.append("\n**Yorum:** " + verdict(st) + "\n")
    parts.append("## Yöntem ve ham çıktılar\n")
    parts.append("- Ham çıktılar: `out/<model>/<koşul>_<n>.md` (model cevabı), `.json` (scorer sonucu), `.err` (stderr), `scores.csv` (özet). `incomplete` çıkan denemeler `<koşul>_<n>.incompleteK.md` olarak saklandı ve sayılmadı.")
    parts.append("- İzolasyon: her çağrı `mktemp -d` ile açılan boş dizinden, `claude -p --tools \"\" --strict-mcp-config --setting-sources \"\" --permission-prompts none` ile koştu. `--tools \"\"` tüm yerleşik araçları kapatır (stream-json init mesajında `tools: []`, `mcp_servers: []` doğrulandı; ayrı bir probe'da model dizindeki dosyayı okuyamadı). `--setting-sources \"\"` kullanıcı/proje ayarlarını, hook'ları ve CLAUDE.md'yi devre dışı bırakır.")
    parts.append("- Modeller: `default` = CLI'nin varsayılan modeli (`--model` verilmedi), `--output-format json` ile çözümlenen kimlik **`claude-opus-5[1m]`**; `opus` = `--model opus`, çözümlenen kimlik **`claude-opus-5`**. İki koşu aynı model ailesinin 1M-bağlam ve standart varyantı; farklı model karşılaştırması sayılmaz.")
    parts.append("- **Görev metnine eklenen ön ek (üç koşulda birebir aynı):** `--tools \"\"` ile araçlar kapalı olsa da CLI'nin varsayılan sistem promptu modeli ajan gibi konumlandırıyor; ilk denemede model metin içinde sahte araç çağrıları (`<invoke name=\"Bash\">` vb.) üretip duruyordu (5 denemenin 4'ü incomplete, `out/_aborted_attempt1/`). Bu yüzden talimattaki yedek yol uygulandı: kullanıcı mesajının başına *\"Hiçbir aracı kullanma, sadece cevap ver. Do not use or call any tools; answer directly and completely in this single message.\"* satırı eklendi. Ön ek `run_cc_eval.sh` içindeki `NO_TOOLS_PREFIX` değişkenidir; `task.md` dosyası değişmedi. Ön ek sonrası 18/18 çağrı ilk denemede complete geldi.")
    parts.append("- Kontroller: `checks.json`; puanlayıcı: `scorer.py`; koşucu: `run_cc_eval.sh`.")
    parts.append("\n## Kontrol × koşul geçme matrisi (iki model birleşik, complete çıktılar)\n")
    parts.append(check_matrix(models))
    parts.append("\n## Kontrol düzeyinde gözlemler (ham çıktılardan)\n")
    parts.append("- **`addServer(new TrackerServer(config, getName(), true))` 0/18 geçti ve kazanılamaz durumda.** Traccar'da üçüncü parametre `datagram`dır; gerçek PR `true` ile **UDP** sunucu kaydeder, oysa `task.md` \"registers a TCP server\" diyor. 16 çıktı `..., false)` yazdı, 2 çıktı eski iki-argümanlı `TrackerServer(false, getName())` kurucusunu kullandı. Modeller görev metnine uydu; kontrol gerçek PR'a. Bu görev metniyle fiili tavan **18/19**.")
    parts.append("- **Pipeline kontrolü** (`CharacterDelimiterFrameDecoder` → `StringEncoder` → `StringDecoder` → decoder) 4/18 geçti. 14/18 çıktı Traccar'ın kendi `CharacterDelimiterFrameDecoder` sınıfı yerine Netty'nin `DelimiterBasedFrameDecoder`'ını seçti; çoğu ayrıca `StringDecoder`'ı `StringEncoder`'dan önce ekledi. Ne kural listesi ne örnek bu sınıfı içeriyor (örnek yalnız decoder+test; Protocol sınıfı yok), dolayısıyla rol bu kuralı öğretemezdi. Koşullar arası fark yok (2/6, 1/6, 1/6).")
    parts.append("- **`@LINK` kontrolü** rol eklenince düştü: rolsüz 6/6, kurallar 2/6, kurallar+örnek 2/6. Rolsüz 6 çıktının hepsi gerçek PR gibi `if (sentence.startsWith(\"@LINK,\")) { getDeviceSession(...); return null; }` yazdı; rol eklenen 12 çıktının 10'u `@LINK` için ayrı bir `PatternBuilder` deseni (`PATTERN_LINK`/`PATTERN_LOGIN`) tanımladı (bunların 2'si regex toleransı sayesinde yine geçti). Davranış eşdeğer; kontrol stil duyarlı. Kural listesindeki \"decode() returns null when the parser does not match\" maddesi ve örnekteki tek-desen yapısı bu stile itmiş görünüyor. Kurallar koşulunun rolsüzden düşük çıkmasının ana nedeni bu.")
    parts.append("- **`nextCoordinate(DEG_HEM)`**: rolsüz 5/6, kurallar 1/6, kurallar+örnek 6/6. Yalnız kural listesi verildiğinde modeller koordinatı elle hesapladı (`opus/rules_2`, `opus/rules_3`: `nextDouble() * (S ? -1 : 1)`; `default/rules_1..3`: yerel `latitude` değişkeni). Örnekteki `parser.nextCoordinate()` çağrısı bu davranışı tamamen düzeltti. Bu kontrol özelinde değer kuralda değil, örnekte.")
    parts.append("- Kural listesindeki maddelerin karşılığı olan 13 kontrol (extends, constructor, decode imzası, PatternBuilder, return null, getDeviceSession, KEY_*, knotsFromKph, Optional/stream yasağı, ProtocolTest, inject, verifyNull/verifyPosition, assert yasağı) **rolsüz koşulda da 6/6 geçiyor**. Madenlenen kurallar modelin zaten bildiği şeyleri söylüyor; ayırt edici olan (CharacterDelimiterFrameDecoder, DEG_HEM biçimi, datagram bayrağı) kurallarda yok.")
    parts.append("- n=3 ile koşullar arası 1-2 puanlık farklar gürültü sınırında; bu raporda yalnız 6/6 ↔ 1-2/6 gibi büyük kaymalar yorumlandı.")
    (HERE / "results.md").write_text("\n".join(parts) + "\n")
    print("\n".join(parts))

if __name__ == "__main__":
    main()
