#!/usr/bin/env python3
"""Mine structural invariants from a Java repository.

Usage: mine_invariants.py <repo> <ext> [--out invariants.json]
Generic engine: no knowledge of the target codebase. Families are class-name
suffixes (CamelCase token suffixes) with >= MIN_FAMILY members.
"""
import json, os, re, sys
from collections import Counter, defaultdict
from pathlib import Path

MIN_FAMILY = 50
KEYWORDS = {"if", "for", "while", "switch", "catch", "return", "synchronized", "super", "this",
            "new", "else", "do", "try", "case", "throw", "assert", "instanceof"}
CALL_RE = re.compile(r"(?:(?P<prev>[\w.@]+)\s+|(?P<punct>[.,(!=&|+\-*/?:{;]|\)\s*)\s*)?(?P<name>[A-Za-z_]\w*)\s*\(")
CLASS_RE = re.compile(r"\b(?:public\s+)?(?:abstract\s+)?(?:final\s+)?(?:class|interface|enum)\s+(\w+)(?:\s+extends\s+([\w.<>, ]+?))?(?:\s+implements\s+([\w.<>, ]+?))?\s*\{")
STR_RE = re.compile(r'"(?:\\.|[^"\\])*"')
NEG_CANDIDATES = {"switch\\s*\\(": re.compile(r"\bswitch\s*\(")}
HYGIENE = {"Optional<": re.compile(r"Optional<"), ".stream(": re.compile(r"\.stream\("),
           "catch (Exception": re.compile(r"catch \(Exception"), "System.out": re.compile(r"System\.out"),
           "printStackTrace": re.compile(r"printStackTrace")}

def tokens(name):
    return re.findall(r"[A-Z][a-z0-9]*|[a-z0-9]+", name)

def suffixes(name, max_tokens=3):
    t = tokens(name)
    return ["".join(t[-k:]) for k in range(1, min(max_tokens, len(t) - 1) + 1)]  # never the whole name

def strip_strings(src):
    return STR_RE.sub('""', src)

def analyze(path: Path):
    src = path.read_text(errors="replace")
    code = strip_strings(src)
    m = CLASS_RE.search(code)
    supers = []
    if m:
        for grp in (m.group(2), m.group(3)):
            if grp:
                supers += [s.strip().split("<")[0].split(".")[-1] for s in grp.split(",")]
    calls = set()
    for cm in CALL_RE.finditer(code):
        name, prev = cm.group("name"), cm.group("prev")
        if name in KEYWORDS:
            continue
        if prev and prev not in KEYWORDS and prev[0].isupper():   # `Object decode(` -> declaration w/ type
            continue
        if prev and prev.startswith("@"):
            continue
        calls.add(name)
    lines = src.split("\n")
    indent_ok = all(((len(l) - len(l.lstrip(" "))) % 4 == 0 or l.lstrip().startswith("*")) and not l.startswith("\t") for l in lines)
    return {
        "path": str(path), "name": path.stem, "supers": supers, "calls": sorted(calls),
        "neg": {k: bool(rx.search(code)) for k, rx in NEG_CANDIDATES.items()},
        "hygiene": {k: bool(rx.search(code)) for k, rx in HYGIENE.items()},
        "indent4": indent_ok,
        "junit5": "org.junit.jupiter" in src,
        "uses_matches": "parser.matches()" in code,
        "null_on_nomatch": bool(re.search(r"if \(!parser\.matches\(\)\)\s*\{\s*return null;", code)),
        "sets_attr": bool(re.search(r"\.set\(", code)),
        "uses_key_const": bool(re.search(r"\bPosition\.KEY_\w+", code)),
    }

def mine(repo: Path, ext: str):
    files = {"main": [], "test": []}
    for root, _, fs in os.walk(repo / "src"):
        for f in fs:
            if f.endswith(ext):
                p = Path(root) / f
                files["test" if "/src/test/" in str(p) else "main"].append(analyze(p))
    fam = {}
    for scope in ("main", "test"):
        cnt = Counter()
        for fi in files[scope]:
            for s in suffixes(fi["name"], 2 if scope == "test" else 3):
                cnt[s] += 1
        good = {s for s, c in cnt.items() if c >= MIN_FAMILY}
        assign = defaultdict(list)
        for fi in files[scope]:
            cands = [s for s in suffixes(fi["name"], 2 if scope == "test" else 3) if s in good]
            if cands:
                assign[max(cands, key=len)].append(fi)
        fam[scope] = {s: v for s, v in assign.items() if len(v) >= MIN_FAMILY}
    return {"repo": str(repo), "files": files, "families": fam}

if __name__ == "__main__":
    repo, ext = Path(sys.argv[1]).resolve(), sys.argv[2]
    out = sys.argv[sys.argv.index("--out") + 1] if "--out" in sys.argv else "invariants.json"
    data = mine(repo, ext)
    Path(out).write_text(json.dumps(data, indent=1))
    print(f"files: main={len(data['files']['main'])} test={len(data['files']['test'])}; families:",
          {k: {s: len(v) for s, v in f.items()} for k, f in data["families"].items()})
