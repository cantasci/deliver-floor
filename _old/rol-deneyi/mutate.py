#!/usr/bin/env python3
"""Systematically rename Traccar conventions in a fork.

Usage: mutate.py <repo> --scan        # report compound identifiers containing old names
       mutate.py <repo> --apply       # rewrite files, git mv renamed classes, commit
Renames come from mutation_map.json next to this script. String literals are
left untouched; comments are rewritten (they are not literals).
Special scoping:
  Parser  -> only files importing org.traccar.helper.Parser or living in org/traccar/helper/
  inject  -> only when followed by '(' (leaves jakarta.inject / google.inject packages)
  text    -> only src/test, only as a bare call/declaration `text(` (not `.text(`)
"""
import json, os, re, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
MAP = json.loads((HERE / "mutation_map.json").read_text())
CLASS_FILES = ["BaseProtocolDecoder", "BaseProtocol", "TrackerServer", "PipelineBuilder",
               "CharacterDelimiterFrameDecoder", "PatternBuilder", "PatternBuilderTest", "Parser",
               "DeviceSession", "ProtocolTest", "BaseProtocolEncoder", "BaseProtocolPoller"]
STR_RE = re.compile(r'"(?:\\.|[^"\\])*"')

def java_files(repo):
    for root, _, files in os.walk(repo / "src"):
        for f in files:
            if f.endswith(".java"):
                yield Path(root) / f

def rules_for(path: Path, src: str):
    """Return list of (regex, replacement) applicable to this file."""
    rules = []
    rel = str(path)
    in_test = "/src/test/" in rel
    for old, new in MAP.items():
        if old == "Parser":
            if "import org.traccar.helper.Parser;" in src or "/org/traccar/helper/" in rel:
                rules.append((re.compile(r"\bParser\b"), new))
        elif old == "inject":
            rules.append((re.compile(r"\binject\b(?=\s*\()"), new))
        elif old == "text":
            if in_test:
                rules.append((re.compile(r"(?<![.\w])text(?=\s*\()"), new))
        else:
            rules.append((re.compile(r"\b%s\b" % re.escape(old)), new))
    # longest first so PatternBuilderTest is handled before PatternBuilder (\b makes it safe anyway)
    rules.sort(key=lambda r: -len(r[0].pattern))
    return rules

def rewrite_outside_strings(line: str, rules):
    out, pos = [], 0
    for m in STR_RE.finditer(line):
        seg = line[pos:m.start()]
        for rx, new in rules:
            seg = rx.sub(new, seg)
        out.append(seg); out.append(m.group(0)); pos = m.end()
    seg = line[pos:]
    for rx, new in rules:
        seg = rx.sub(new, seg)
    out.append(seg)
    return "".join(out)

def scan(repo):
    olds = [o for o in MAP if o not in ("inject", "text")]
    rx = re.compile(r"\w*(?:%s)\w*" % "|".join(re.escape(o) for o in olds))
    hits = {}
    for p in java_files(repo):
        for tok in rx.findall(p.read_text(errors="replace")):
            if tok not in MAP:
                hits[tok] = hits.get(tok, 0) + 1
    print("compound identifiers containing an old name (not renamed by exact-word rules):")
    for k, v in sorted(hits.items(), key=lambda kv: -kv[1]):
        print(f"  {v:5d}  {k}")

def apply(repo):
    changed = 0
    for p in java_files(repo):
        src = p.read_text(errors="replace")
        rules = rules_for(p, src)
        new_lines = [rewrite_outside_strings(l, rules) for l in src.split("\n")]
        new = "\n".join(new_lines)
        if new != src:
            p.write_text(new); changed += 1
    print(f"rewrote {changed} files")
    # file renames
    for p in list(java_files(repo)):
        stem = p.stem
        if stem in CLASS_FILES:
            target = p.with_name(MAP[stem] + ".java")
            subprocess.run(["git", "-C", str(repo), "mv", str(p), str(target)], check=True)
            print(f"git mv {p.relative_to(repo)} -> {target.name}")
    subprocess.run(["git", "-C", str(repo), "add", "-A", "src"], check=True)
    subprocess.run(["git", "-C", str(repo), "-c", "user.name=mutate", "-c", "user.email=mutate@local",
                    "commit", "-q", "-m", "Systematic convention rename (rol-deneyi mutation)\n\nSee mutation_map.json in rol-deneyi."], check=True)
    print(subprocess.run(["git", "-C", str(repo), "log", "--oneline", "-1"], capture_output=True, text=True).stdout)

if __name__ == "__main__":
    repo = Path(sys.argv[1]).resolve()
    if "--scan" in sys.argv: scan(repo)
    elif "--apply" in sys.argv: apply(repo)
    else: print(__doc__)
