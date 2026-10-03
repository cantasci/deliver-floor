#!/usr/bin/env python3
"""Engine v2 additions on top of mine_invariants: alternatives, test-family
rules, task-driven example bundle, identifier coverage.  Generic: no knowledge
of Traccar names.  Usage (debug): mine_v2.py <repo> <task.md>"""
import json, re, sys
from collections import Counter, defaultdict
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from mine_invariants import mine, tokens, KEYWORDS  # noqa

JAVA_KW = set("""abstract assert boolean break byte case catch char class const continue default do double else enum
extends final finally float for goto if implements import instanceof int interface long native new package private
protected public return short static strictfp super switch synchronized this throw throws transient try void volatile
while var record yield sealed permits non true false null""".split())
LIC_RE = re.compile(r"\A\s*/\*.*?\*/\s*", re.DOTALL)

def strip_code(src: str) -> str:
    src = re.sub(r"/\*.*?\*/", " ", src, flags=re.DOTALL)
    src = re.sub(r"//[^\n]*", " ", src)
    src = re.sub(r'"(?:\\.|[^"\\])*"', '"S"', src)
    src = re.sub(r"'(?:\\.|[^'\\])'", "'C'", src)
    return src

def identifiers(code: str):
    return {t for t in re.findall(r"\b[A-Za-z_]\w*\b", code) if t not in JAVA_KW}

def match_paren(s, i):
    d = 0
    for j in range(i, len(s)):
        if s[j] == "(": d += 1
        elif s[j] == ")":
            d -= 1
            if d == 0: return j
    return -1

def split_args(s):
    args, d, cur = [], 0, ""
    for ch in s:
        if ch in "([{": d += 1
        elif ch in ")]}": d -= 1
        if ch == "," and d == 0:
            args.append(cur.strip()); cur = ""
        else: cur += ch
    if cur.strip(): args.append(cur.strip())
    return args

def head(arg: str) -> str:
    a = arg.strip()
    if a.startswith("new "):
        m = re.match(r"new\s+([\w.]+)", a); return "new " + m.group(1) if m else a[:30]
    if a.startswith('"'): return '"…"'
    if re.match(r"^-?\d", a): return "<number>"
    if a in ("true", "false", "null"): return a
    m = re.match(r"^([\w.]+)", a)
    return m.group(1) if m else a[:20]

def calls(code: str):
    """yield (name, args, is_new) for every call site."""
    PRIM = {"void", "int", "long", "boolean", "double", "float", "short", "byte", "char"}
    for m in re.finditer(r"(?:(?P<prev>[\w<>\[\]]+)\s+)?(?P<new>new\s+)?\b(?P<name>[A-Za-z_][\w.]*)\s*\(", code):
        name = m.group("name").split(".")[-1]; prev = m.group("prev")
        if name in JAVA_KW: continue
        if not m.group("new") and prev and (prev in PRIM or (prev[0].isupper() and prev not in ("return",))) and "." not in m.group("name"):
            continue  # method declaration `Type name(` -> not a call
        end = match_paren(code, m.end() - 1)
        if end < 0: continue
        yield name, split_args(code[m.end():end]), bool(m.group("new"))

def analyze_files(files):
    out = []
    for f in files:
        src = Path(f["path"]).read_text(errors="replace")
        body = LIC_RE.sub("", src, count=1)
        code = strip_code(src)
        cl = list(calls(code))
        out.append({**f, "ids": identifiers(code), "calls": cl, "callset": {c[0] for c in cl},
                    "lines": body.count("\n") + 1, "body": body})
    return out

def exclusive_alternatives(fam, lo=0.2, hi=0.9, union_min=0.8, overlap_max=0.1, max_rules=6):
    n = len(fam); cnt = Counter(c for f in fam for c in f["callset"])
    mid = [c for c, k in cnt.items() if lo <= k / n < hi]
    files_of = {c: {i for i, f in enumerate(fam) if c in f["callset"]} for c in mid}
    rules, used = [], set()
    pairs = []
    for i, a in enumerate(mid):
        for b in mid[i + 1:]:
            u = files_of[a] | files_of[b]; o = files_of[a] & files_of[b]
            if len(u) / n >= union_min and len(o) / len(u) <= overlap_max:
                pairs.append((len(u), a[0].isupper() + b[0].isupper(), a, b))
    for _, _, a, b in sorted(pairs, reverse=True):
        if a in used or b in used: continue
        used |= {a, b}
        rules.append(f"{a}() in {len(files_of[a])}/{n} files, {b}() in {len(files_of[b])}/{n} files (rarely both: choose one style)")
        if len(rules) >= max_rules: break
    return rules

def argument_alternatives(fam, lo=0.2, sum_min=0.8, max_rules=24):
    n = len(fam); cnt = Counter(c for f in fam for c in f["callset"])
    rules = []
    for cname, k in cnt.most_common():
        if k / n < lo: continue
        callers = [f for f in fam if cname in f["callset"]]
        # per position: set of heads per file
        pos_heads = defaultdict(Counter); arities = Counter()
        for f in callers:
            seen = defaultdict(set)
            for name, args, _ in f["calls"]:
                if name != cname: continue
                arities[len(args)] += 1
                if not args: seen[0].add("(no argument)")
                for i, a in enumerate(args): seen[i].add(head(a))
            for i, hs in seen.items():
                for h in hs: pos_heads[i][h] += 1
        for i, dist in sorted(pos_heads.items()):
            opts = [(h, c) for h, c in dist.most_common() if c / len(callers) >= lo][:10]
            if len(opts) >= 2 and not all(h in ("<number>", "'C'", '"…"', "null") for h, _ in opts) and sum(c for _, c in opts) / len(callers) >= sum_min:
                rules.append(f"{cname}(…) argument {i + 1}: " + ", ".join(f"`{h}` {c}/{len(callers)}" for h, c in opts))
        if len(rules) >= max_rules: break
    return rules

def test_rules(test_fam, name, hi=0.9, lo=0.2):
    n = len(test_fam); out = []
    sup = Counter(s for f in test_fam for s in f["supers"])
    if sup:
        s, k = sup.most_common(1)[0]
        if k / n >= hi: out.append(f"*test:{name} extends/implements {s}  ({k}/{n})")
    cnt = Counter(c for f in test_fam for c in f["callset"])
    for c, k in cnt.most_common():
        if lo <= k / n < hi and c[0].islower():
            out.append(f"*test:{name} commonly calls {c}()  ({k}/{n})")
    return out

def target_identifiers(fam, lo=0.2):
    n = len(fam); cnt = Counter(i for f in fam for i in f["ids"])
    return {i for i, k in cnt.items() if k / n >= lo}

def coverage(doc_text: str, targets: set):
    present = {t for t in targets if re.search(r"\b%s\b" % re.escape(t), doc_text)}
    return {"targets": len(targets), "covered": len(present), "pct": round(100 * len(present) / max(1, len(targets)), 1),
            "missing": sorted(targets - present)}

def task_types(task_text: str):
    names = re.findall(r"\b(\w+)\.java", task_text)
    base = None
    for nm in names:
        for other in names:
            if nm != other and other.startswith(nm[:4]):
                base = nm[:len(nm)] if all(x.startswith(nm) for x in names) else base
    # common prefix
    pre = names[0]
    for nm in names[1:]:
        while not nm.startswith(pre): pre = pre[:-1]
    while pre and (any(len(nm) == len(pre) for nm in names) or not re.match(r"[A-Z]", names[0][len(pre):len(pre) + 1] or "A")):
        pre = pre[:-1]
    return pre, [nm[len(pre):] for nm in names]

def select_bundle(types, fams_main, fams_test, base_prefix, max_lines=200, max_file_lines=60):
    """Greedy-exhaustive: one file per requested type (<=60 lines), maximise coverage of
    >=20% identifiers of the involved families; plus an edge-case decoder+test pair."""
    def fam_for(t):
        if t.endswith("Test"):
            return "test", next((k for k in fams_test if t.endswith(k)), None)
        return "main", next((k for k in sorted(fams_main, key=len, reverse=True) if t.endswith(k)), None)
    picks, targets = {}, set()
    cands = {}
    for t in types:
        scope, fk = fam_for(t)
        fam = (fams_test if scope == "test" else fams_main)[fk]
        targets |= target_identifiers(fam)
        cands[t] = [f for f in fam if f["lines"] <= max_file_lines and not f["name"].startswith(base_prefix)
                    and f["name"].endswith(t) and not re.search(r"\babstract\s+class\b", f["body"])]
    # edge case: decoder whose test calls the 'no output' style helper (a helper used in <90% but >=20% of tests
    # whose name suggests absence) -> generic: a test helper co-occurring with a decoder having >=2 'return null'
    dec_t = [t for t in types if t.endswith("Decoder")][0]; tst_t = [t for t in types if t.endswith("Test")][0]
    dec_fam = fams_main[fam_for(dec_t)[1]]; tst_fam = fams_test[fam_for(tst_t)[1]]
    tst_by_name = {f["name"]: f for f in tst_fam}
    helper_cnt = Counter(c for f in tst_fam for c in f["callset"])
    n_t = len(tst_fam)
    mid_helpers = [c for c, k in helper_cnt.items() if 0.2 <= k / n_t < 0.9 and c[0].islower()]
    edge = None
    for d in sorted(dec_fam, key=lambda f: f["lines"]):
        if d["name"].startswith(base_prefix): continue
        t = tst_by_name.get(d["name"] + "Test")
        if not t or d["lines"] + t["lines"] > 90: continue
        nulls = len(re.findall(r"return null;", d["body"]))
        extra_helpers = [h for h in mid_helpers if h in t["callset"]]
        if nulls >= 2 and extra_helpers:
            edge = (d, t, extra_helpers); break
    budget = max_lines - (edge[0]["lines"] + edge[1]["lines"] if edge else 0)
    best = None
    import itertools
    edge_ids = (edge[0]["ids"] | edge[1]["ids"]) if edge else set()
    lists = [sorted(cands[t], key=lambda f: -len(f["ids"] & targets))[:40] for t in types]
    for combo in itertools.product(*lists):
        if sum(f["lines"] for f in combo) > budget: continue
        ids = set().union(edge_ids, *(f["ids"] for f in combo))
        cov = len(ids & targets)
        bases = [f["name"][: len(f["name"]) - len(t)] for f, t in zip(combo, types)]
        coherent = len(set(bases)) < len(bases)          # decoder+test (or protocol) share a base
        key = (cov + (1 if coherent else 0), coherent, -sum(f["lines"] for f in combo))  # coverage first; 1-id nudge for coherence
        if best is None or key > best[0]: best = (key, combo)
    return list(best[1]), edge, targets

if __name__ == "__main__":
    repo = Path(sys.argv[1]).resolve(); task = Path(sys.argv[2]).read_text()
    data = mine(repo, ".java")
    fams_main = {k: analyze_files(v) for k, v in data["families"]["main"].items()}
    fams_test = {k: analyze_files(v) for k, v in data["families"]["test"].items()}
    for k, fam in fams_main.items():
        print(f"== {k} exclusive:"); [print("  ", r) for r in exclusive_alternatives(fam)]
        print(f"== {k} argument alternatives:"); [print("  ", r) for r in argument_alternatives(fam)]
    for k, fam in fams_test.items():
        print(f"== test {k}:"); [print("  ", r) for r in test_rules(fam, k)]
    pre, types = task_types(task); print("task types:", pre, types)
    combo, edge, targets = select_bundle(types, fams_main, fams_test, pre)
    print("bundle:", [(f["name"], f["lines"]) for f in combo], "edge:", edge and (edge[0]["name"], edge[0]["lines"], edge[1]["lines"], edge[2]))
    print("targets:", len(targets))
