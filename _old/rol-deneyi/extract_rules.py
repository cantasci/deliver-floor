#!/usr/bin/env python3
"""Turn mined invariants into rule lines (round-1 format).

Usage: extract_rules.py <repo> [--threshold 0.9]
Prints one `- rule  (x/y)` line per rule; used by compile_role.py.
"""
import sys
from collections import Counter
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from mine_invariants import mine, HYGIENE  # noqa: E402

THRESH = 0.9
NEG_ELSEWHERE_MIN = 200

def frac(n, d):
    return f"({n}/{d})"

def rules(repo: Path, thresh=THRESH):
    data = mine(repo, ".java")
    main, test = data["families"]["main"], data["families"]["test"]
    all_main = data["files"]["main"]; all_test = data["files"]["test"]
    test_names = {f["name"] for f in all_test}
    out = []
    # 1. pairing rules between main families
    for a, fa in main.items():
        best = None
        for b, fb in main.items():
            if a == b: continue
            names_b = {f["name"] for f in fb}
            n = sum(1 for f in fa if f["name"][: -len(a)] + b in names_b)
            if n / len(fa) >= thresh and (best is None or (n, len(fb)) > (best[1], best[2])):
                best = (b, n, len(fb))
        if best:
            out.append(f"- every *{a} has a matching *{best[0]}  {frac(best[1], len(fa))}")
    # 2. test-file rule
    for a, fa in main.items():
        n = sum(1 for f in fa if f["name"] + "Test" in test_names)
        if n / len(fa) >= thresh:
            out.append(f"- every *{a} has a test file  {frac(n, len(fa))}")
    # 3. superclass rule
    for a, fa in main.items():
        c = Counter(s for f in fa for s in f["supers"])
        if c:
            s, n = c.most_common(1)[0]
            if n / len(fa) >= thresh:
                out.append(f"- *{a} extends/implements {s}  {frac(n, len(fa))}")
    # 4. common calls per family (main then test)
    for scope, fams in (("", main), ("test:", test)):
        for a, fa in fams.items():
            c = Counter(call for f in fa for call in set(f["calls"]))
            for call, n in c.most_common():
                if n / len(fa) >= thresh:
                    out.append(f"- *{scope}{a} call {call}()  {frac(n, len(fa))}")
    # 5. negative rules
    for a, fa in main.items():
        fam_paths = {f["path"] for f in fa}
        for k in fa[0]["neg"]:
            in_fam = sum(1 for f in fa if f["neg"][k])
            elsewhere = sum(1 for f in all_main + all_test if f["path"] not in fam_paths and f["neg"][k])
            if in_fam == 0 and elsewhere >= NEG_ELSEWHERE_MIN:
                out.append(f"- *{a} never use `{k}` (used in {elsewhere} files elsewhere)  {frac(len(fa), len(fa))}")
    # 6. test style
    n = sum(1 for f in all_test if f["name"].endswith("Test"))
    out.append(f"- Test classes end with 'Test'  ({n}/{len(all_test)} test files)")
    n = sum(1 for f in all_test if f["junit5"])
    out.append(f"- Tests use JUnit5  ({n}/{len(all_test)} test files)")
    allf = all_main + all_test
    n = sum(1 for f in allf if f["indent4"])
    out.append(f"- Indentation uses 4 spaces  ({n}/{len(allf)} files)")
    # 7. parser null rule
    um = [f for f in all_main if f["uses_matches"]]
    if um:
        n = sum(1 for f in um if f["null_on_nomatch"])
        if n / len(um) >= thresh:
            out.append(f"- decode() returns null when the parser does not match  {frac(n, len(um))}")
    # 8. decoder hygiene + attribute keys (largest main family whose name contains 'Decoder')
    dec = [f for a, fa in main.items() if "Decoder" in a for f in fa]
    if dec:
        n = sum(1 for f in dec if not any(f["hygiene"].values()))
        if n / len(dec) >= thresh:
            out.append(f"- Decoders never use Optional or streams; no generic catch(Exception); no System.out/printStackTrace  {frac(n, len(dec))}")
        setters = [f for f in dec if f["sets_attr"]]
        n = sum(1 for f in setters if f["uses_key_const"])
        if setters and n / len(setters) >= 0.8:
            out.append(f"- Attribute keys use Position.KEY_* constants where a standard key exists  {frac(n, len(setters))}")
    return out

if __name__ == "__main__":
    repo = Path(sys.argv[1]).resolve()
    t = float(sys.argv[sys.argv.index("--threshold") + 1]) if "--threshold" in sys.argv else THRESH
    print("\n".join(rules(repo, t)))
