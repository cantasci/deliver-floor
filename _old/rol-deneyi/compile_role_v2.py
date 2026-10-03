#!/usr/bin/env python3
"""Engine v2: compile role documents (rules + task-driven example bundle) and coverage.json.

Usage: compile_role_v2.py <repo> --task task.md --drafts 'out-mut/*/no_role_*.md' \
         --rules-out role_rules_v2.md --examples-out role_examples_v2.md \
         [--no-miss-out role_rules_v2_nomiss.md] [--coverage coverage.json] [--v1-docs role_rules.md role_example.md]
Nothing is hand-written: every line comes from extract_rules / mine_v2 / miss_mining.
"""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from mine_invariants import mine
from extract_rules import rules as v1_rules
import mine_v2 as m2
import miss_mining as mm

def arg(name, default=None, n=1):
    a = sys.argv
    if name in a:
        i = a.index(name); return a[i + 1] if n == 1 else a[i + 1:i + 1 + n]
    return default

def main():
    repo = Path(sys.argv[1]).resolve()
    task_path = arg("--task", "task.md"); drafts = arg("--drafts")
    task = Path(task_path).read_text()
    data = mine(repo, ".java")
    fams_main = {k: m2.analyze_files(v) for k, v in data["families"]["main"].items()}
    fams_test = {k: m2.analyze_files(v) for k, v in data["families"]["test"].items()}
    base, types = m2.task_types(task)
    relevant_main = {k for k in fams_main if any(t.endswith(k) and not t.endswith("Test") for t in types)}
    relevant_test = {k for k in fams_test if any(t.endswith(k) for t in types)}

    head = ("# Role: Traccar protocol developer (engine v2)\n\n"
            "Follow these project conventions. Each rule was mined from the repository; the fraction shows how many files obey it.\n\n")
    sec = ["## Conventions\n"] + v1_rules(repo) + [""]
    sec += ["## Alternatives (patterns below the 90% bar but dominant within the family)\n"]
    for k in sorted(relevant_main):
        for r in m2.exclusive_alternatives(fams_main[k]): sec.append(f"- *{k}: {r}")
        for r in m2.argument_alternatives(fams_main[k]): sec.append(f"- *{k}: {r}")
    sec.append("")
    sec += ["## Test conventions\n"]
    for k in sorted(relevant_test):
        for r in m2.test_rules(fams_test[k], k): sec.append(f"- {r}")
    sec.append("")
    rules_txt = head + "\n".join(sec)
    miss_txt = ""
    if drafts:
        res = mm.run(str(repo), task_path, drafts)
        miss_txt = mm.render(res)
        Path(arg("--miss-json", "miss_rules.json")).write_text(json.dumps(res, indent=1))
    Path(arg("--rules-out", "role_rules_v2.md")).write_text(rules_txt + "\n" + miss_txt)
    if arg("--no-miss-out"): Path(arg("--no-miss-out")).write_text(rules_txt)

    combo, edge, targets = m2.select_bundle(types, fams_main, fams_test, base)
    ex = ["# Example files from the repository (selected for this task)\n"]
    for f in combo:
        rel = Path(f["path"]).relative_to(repo)
        ex += [f"## {rel}\n", "```java", f["body"].rstrip("\n"), "```", ""]
    if edge:
        d, t, helpers = edge
        ex += [f"## Edge case: a decoder whose non-position message returns null, and its test\n"]
        for f in (d, t):
            rel = Path(f["path"]).relative_to(repo)
            ex += [f"### {rel}\n", "```java", f["body"].rstrip("\n"), "```", ""]
    ex_txt = "\n".join(ex)
    Path(arg("--examples-out", "role_examples_v2.md")).write_text(ex_txt)

    cov = {"targets": sorted(targets), "n_targets": len(targets),
           "v2_rules": m2.coverage(rules_txt + miss_txt, targets), "v2_examples": m2.coverage(ex_txt, targets),
           "v2_full": m2.coverage(rules_txt + miss_txt + ex_txt, targets),
           "v2_rules_nomiss+examples": m2.coverage(rules_txt + ex_txt, targets),
           "bundle": [str(Path(f["path"]).relative_to(repo)) for f in combo] + ([str(Path(edge[0]["path"]).relative_to(repo)), str(Path(edge[1]["path"]).relative_to(repo))] if edge else []),
           "bundle_lines": sum(f["lines"] for f in combo) + (edge[0]["lines"] + edge[1]["lines"] if edge else 0)}
    v1 = arg("--v1-docs", None, 2)
    if v1:
        v1r, v1e = Path(v1[0]).read_text(), Path(v1[1]).read_text()
        cov["v1_rules"] = m2.coverage(v1r, targets); cov["v1_examples"] = m2.coverage(v1e, targets); cov["v1_full"] = m2.coverage(v1r + v1e, targets)
    for k, v in cov.items():
        if isinstance(v, dict) and "missing" in v: v["missing"] = v["missing"][:60]
    Path(arg("--coverage", "coverage.json")).write_text(json.dumps(cov, indent=1))
    print("coverage:", {k: v["pct"] for k, v in cov.items() if isinstance(v, dict) and "pct" in v}, "bundle lines:", cov["bundle_lines"], cov["bundle"])

if __name__ == "__main__":
    main()
