#!/usr/bin/env python3
"""Score a model output file against checks.json.

Usage: scorer.py <output.md> [--json-out <path>]
Splits ```java blocks into three buckets (decoder / protocol / test),
applies each check with re.search to its bucket, prints JSON.
"""
import json
import re
import sys
from pathlib import Path

import os
HERE = Path(__file__).resolve().parent
CHECKS_PATH = Path(os.environ.get("CHECKS", HERE / "checks.json"))
CHECKS = json.loads(CHECKS_PATH.read_text())


def _match_close(code, i, open_ch, close_ch):
    depth = 0
    for j in range(i, len(code)):
        if code[j] == open_ch:
            depth += 1
        elif code[j] == close_ch:
            depth -= 1
            if depth == 0:
                return j
    return len(code) - 1


def link_behaviour(code: str, helper: str) -> bool:
    """Behaviour-level check: some branch conditioned on the LINK message calls
    <helper>(...) and returns null. A separate pattern for @LINK is fine."""
    link_ids = set()
    for m in re.finditer(r"(\w+)\s*=\s*new\s+\w+\(\)[\s\S]*?\.compile\(\)", code):
        if "LINK" in m.group(0):
            link_ids.add(m.group(1))
    for m in re.finditer(r"(\w+)\s*=\s*Pattern\.compile\(([^;]*)\);", code):
        if "LINK" in m.group(2):
            link_ids.add(m.group(1))
    changed = True
    while changed:
        changed = False
        for lid in list(link_ids):
            for m in re.finditer(r"\b(\w+)\s*=\s*(?:new\s+\w+\(\s*%s\b|%s\.matcher\()" % (lid, lid), code):
                if m.group(1) not in link_ids:
                    link_ids.add(m.group(1)); changed = True
    cands = []
    for m in re.finditer(r"\bif\s*\(", code):
        cend = _match_close(code, m.end() - 1, "(", ")")
        cond = code[m.end():cend]
        if re.search(r'"@?LINK', cond) or any(re.search(r"\b%s\b" % re.escape(i), cond) for i in link_ids):
            rest = code[cend + 1:]
            b = re.match(r"\s*\{", rest)
            if b:
                bend = _match_close(rest, b.end() - 1, "{", "}")
                cands.append(rest[:bend])
            else:
                cands.append(rest[: rest.find(";") + 1])
    for m in re.finditer(r'case\s+"@?LINK[^"]*"\s*(?:->|:)', code):
        seg = code[m.end():]
        nxt = re.search(r"\n\s*(case\s|default\b)", seg)
        cands.append(seg[: nxt.start()] if nxt else seg[:600])
    return any(helper + "(" in b and re.search(r"return\s+null\s*;", b) for b in cands)


FUNCTIONS = {"link_behaviour": link_behaviour}

FENCE_RE = re.compile(r"```(?:java)?[^\n]*\n(.*?)```", re.DOTALL)


def split_blocks(text: str):
    blocks = FENCE_RE.findall(text)
    if not blocks:
        # no fences at all: treat whole text as one block
        blocks = [text]
    buckets = {"decoder": [], "protocol": [], "test": []}
    for b in blocks:
        if "ProtocolDecoderTest" in b:
            buckets["test"].append(b)
        elif "class R16hProtocolDecoder" in b:
            buckets["decoder"].append(b)
        elif re.search(r"class R16hProtocol[\s{]", b) or "R16hProtocol.java" in b:
            buckets["protocol"].append(b)
    return {k: "\n".join(v) for k, v in buckets.items()}


def score(text: str):
    buckets = split_blocks(text)
    passed, failed = [], []
    for kind, name, pattern in CHECKS:
        if isinstance(pattern, dict):
            ok = FUNCTIONS[pattern["fn"]](buckets[kind], **{k: v for k, v in pattern.items() if k != "fn"})
        else:
            ok = bool(re.search(pattern, buckets[kind]))
        if ok:
            passed.append(name)
        else:
            failed.append(name)
    incomplete = any(not v.strip() for v in buckets.values())
    result = {
        "score": len(passed),
        "total": len(CHECKS),
        "passed": passed,
        "failed": failed,
        "buckets_present": {k: bool(v.strip()) for k, v in buckets.items()},
    }
    if incomplete:
        result["incomplete"] = True
    return result


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(2)
    path = Path(args[0])
    json_out = None
    if "--checks" in args:
        global CHECKS
        CHECKS = json.loads(Path(args[args.index("--checks") + 1]).read_text())
    if "--json-out" in args:
        json_out = Path(args[args.index("--json-out") + 1])
    result = score(path.read_text(errors="replace"))
    out = json.dumps(result, indent=1)
    if json_out:
        json_out.write_text(out)
    print(out)


if __name__ == "__main__":
    main()
