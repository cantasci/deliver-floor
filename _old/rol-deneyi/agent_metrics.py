#!/usr/bin/env python3
"""Parse an agent run: score the three files found in the worktree + stream-json metrics.
Usage: agent_metrics.py <worktree> <stream.jsonl> --wall <sec> --json out.json --md out.md"""
import json, os, re, sys
from collections import Counter
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import scorer

NAMES = ["R16hProtocol.java", "R16hProtocolDecoder.java", "R16hProtocolDecoderTest.java"]

def find_files(wt: Path):
    found = {}
    for root, dirs, files in os.walk(wt):
        dirs[:] = [d for d in dirs if d not in (".git", "build")]
        for f in files:
            if f in NAMES and f not in found: found[f] = Path(root) / f
    return found

def main():
    a = sys.argv; wt = Path(a[1]); stream = Path(a[2])
    wall = float(a[a.index("--wall") + 1]) if "--wall" in a else None
    if "--keep-score" in a:
        old = json.loads(Path(a[a.index("--json") + 1]).read_text()); files = {}
        md = Path(a[a.index("--md") + 1]).read_text()
    else:
        files = find_files(wt)
    md = md if "--keep-score" in a else "\n".join(f"```java\n// {n}\n{files[n].read_text(errors='replace')}\n```\n" for n in NAMES if n in files)
    if "--keep-score" not in a: Path(a[a.index("--md") + 1]).write_text(md)
    sc = old["score"] if "--keep-score" in a else scorer.score(md) if md else {"score": 0, "total": len(scorer.CHECKS), "passed": [], "failed": [c[1] for c in scorer.CHECKS], "incomplete": True}
    if "--keep-score" not in a: sc["files_found"] = sorted(files)
    m = {"tool_calls": 0, "by_tool": Counter(), "read_paths": set(), "grep_glob_calls": 0, "bash_cmds": [], "bash_cmds_full": [], "assistant_msgs": 0,
         "usage": {}, "num_turns": None, "duration_ms": None, "cost_usd": None, "result_subtype": None, "is_error": None, "model": None}
    for line in stream.read_text(errors="replace").splitlines():
        try: d = json.loads(line)
        except Exception: continue
        t = d.get("type")
        if t == "system" and d.get("subtype") == "init": m["model"] = d.get("model")
        elif t == "assistant":
            m["assistant_msgs"] += 1
            for c in d.get("message", {}).get("content", []):
                if c.get("type") == "tool_use":
                    m["tool_calls"] += 1; m["by_tool"][c["name"]] += 1
                    inp = c.get("input", {})
                    if c["name"] == "Read": m["read_paths"].add(inp.get("file_path", ""))
                    if c["name"] in ("Grep", "Glob"): m["grep_glob_calls"] += 1
                    if c["name"] == "Bash": m["bash_cmds"].append(inp.get("command", "")[:120]); m["bash_cmds_full"].append(inp.get("command", ""))
        elif t == "result":
            u = d.get("usage", {})
            m["usage"] = {k: u.get(k, 0) for k in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens", "output_tokens")}
            m["num_turns"] = d.get("num_turns"); m["duration_ms"] = d.get("duration_ms"); m["cost_usd"] = d.get("total_cost_usd")
            m["result_subtype"] = d.get("subtype"); m["is_error"] = d.get("is_error")
    u = m["usage"]
    m["tokens_in_total"] = sum(u.get(k, 0) for k in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))
    m["tokens_out"] = u.get("output_tokens", 0)
    m["tokens_total"] = m["tokens_in_total"] + m["tokens_out"]
    # files opened via Bash (cat/head/tail/sed -n <file>) count as opened too
    bash_files = set()
    for cmd in m["bash_cmds_full"]:
        for seg in re.split(r"[;|&]+|\n", cmd):
            if re.match(r"\s*(cat|head|tail|sed|less|more)\b", seg):
                bash_files.update(p for p in re.findall(r"[\w./-]+\.(?:java|xml|gradle|md|txt)", seg))
    m["bash_opened_files"] = sorted(bash_files)
    m["files_opened_distinct"] = len({p.split("/")[-1] for p in m["read_paths"]} | {p.split("/")[-1] for p in bash_files})
    m["files_read_distinct"] = len(m["read_paths"]); m["read_paths"] = sorted(m["read_paths"]); m["by_tool"] = dict(m["by_tool"])
    m["wall_seconds"] = wall
    m.pop("bash_cmds_full", None)
    out = {"score": sc, "metrics": m}
    Path(a[a.index("--json") + 1]).write_text(json.dumps(out, indent=1))
    print(f"score={sc['score']}/{sc['total']} files={len(files)} tools={m['tool_calls']} reads={m['files_read_distinct']} tok_in={m['tokens_in_total']} tok_out={m['tokens_out']} turns={m['num_turns']} wall={wall}s subtype={m['result_subtype']}")

if __name__ == "__main__":
    main()
