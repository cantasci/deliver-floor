#!/usr/bin/env python3
"""Miss-driven mining: identifiers the model used (no_role outputs) that do not
exist in the repo -> find the identifier playing the same role in the repo.
Usage: miss_mining.py <repo> <task.md> <out_glob> [--json out.json]"""
import glob, json, re, sys
from collections import Counter, defaultdict
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import scorer
from mine_invariants import mine
from mine_v2 import strip_code, identifiers, calls, head, JAVA_KW, task_types, analyze_files

def repo_index(repo, types):
    data = mine(repo, ".java")
    idx = {"ids": set(), "fam": {}}
    for scope in ("main", "test"):
        for f in data["files"][scope]:
            idx["ids"] |= identifiers(strip_code(Path(f["path"]).read_text(errors="replace")))
    fams = {**{k: v for k, v in data["families"]["main"].items()}, **{"test:" + k: v for k, v in data["families"]["test"].items()}}
    for t in types:
        key = next((k for k in sorted(fams, key=len, reverse=True) if t.endswith(k.split(":")[-1]) and (t.endswith("Test")) == k.startswith("test:")), None)
        if key: idx["fam"][t] = analyze_files(fams[key])
    return idx

def ctx_index(fam):
    """Context facts per family (from repo)."""
    c = {"super": Counter(), "var_new": defaultdict(Counter), "encl_new": defaultdict(Counter), "var_type": defaultdict(Counter),
         "bare": defaultdict(Counter), "chain": defaultdict(Counter), "static": defaultdict(Counter), "decl_params": defaultdict(Counter),
         "param_type": defaultdict(Counter), "helper_lit": defaultdict(Counter), "inner_lit": defaultdict(Counter), "recv": defaultdict(Counter),
         "encl_static": defaultdict(Counter)}
    for f in fam:
        code = strip_code(f["body"])
        for s in f["supers"]: c["super"][s] += 1
        for m in re.finditer(r"\b([A-Z]\w*)\s+(\w+)\s*=\s*new\s+(\w+)\s*\(", code):
            c["var_new"][m.group(2)][m.group(3)] += 1; c["var_type"][m.group(2)][m.group(1)] += 1
        for m in re.finditer(r"\b([A-Z]\w*)\s+(\w+)\s*=\s*(?!new)", code): c["var_type"][m.group(2)][m.group(1)] += 1
        for m in re.finditer(r"\b(\w+)\(\s*new\s+(\w+)\s*\(", code): c["encl_new"][m.group(1)][m.group(2)] += 1
        for m in re.finditer(r"(?<![.\w])([a-z]\w*)\s*\(([^()]*(?:\([^()]*\))?[^()]*)\)", code):
            args = [head(a) for a in re.split(r",(?![^()]*\))", m.group(2))] if m.group(2).strip() else []
            c["bare"][(len(args), tuple(args[:2]))][m.group(1)] += 1
        for m in re.finditer(r"\b([A-Z]\w*)\.([A-Z]\w*)\.([A-Z_]\w*)", code): c["chain"][(m.group(2), None)][m.group(1)] += 1; c["chain"][(m.group(2), "const")][m.group(3)] += 1
        for m in re.finditer(r"\b(\w+)\(\s*([A-Z]\w*)\.([a-z]\w*)\(", code): c["encl_static"][(m.group(1), m.group(2))][m.group(3)] += 1
        for m in re.finditer(r"\b([A-Z]\w*)\.([a-z]\w*)\(", code): c["static"][m.group(2)][m.group(1)] += 1
        for m in re.finditer(r"(?:protected|public|private)\s+\w+\s+(\w+)\s*\(([^)]*)\)", code):
            params = re.findall(r"(\w+)\s+(\w+)(?:,|$)", m.group(2))
            if params:
                c["decl_params"][tuple(p[1] for p in params)][m.group(1)] += 1
                for ty, nm in params: c["param_type"][nm][ty] += 1
        seen_h, seen_i = set(), set()
        for m in re.finditer(r"\b(\w+)\(\s*decoder,\s*(\w+)\(\s*\n?\s*\"([^\"]*)\"", f["body"]):
            lit = "hex" if re.fullmatch(r"[0-9a-fA-F\s]+", m.group(3)) else "ascii"
            seen_h.add((lit, m.group(1))); seen_i.add((lit, m.group(2)))
        for lit, h in seen_h: c["helper_lit"][lit][h] += 1
        for lit, i in seen_i: c["inner_lit"][lit][i] += 1
        for m in re.finditer(r"\b([a-z]\w*)\.([a-z]\w*)\(", code): c["recv"][m.group(1)][m.group(2)] += 1
    return c

def dominant(counter, min_share=0.5):
    if not counter: return None, 0
    tot = sum(counter.values()); name, k = counter.most_common(1)[0]
    return (name, k / tot) if k / tot >= min_share else (None, k / tot)

def analyze_output(md_text, types, base):
    b = scorer.split_blocks(md_text)
    files = {}
    for kind, t in (("protocol", types[0]), ("decoder", types[1]), ("test", types[2])):
        files[t] = b[kind]
    return files

def find_missing(files, repo_ids, base, fam_calls=None):
    """Return {ident: [(type, ctx_kind, detail)]} for identifiers absent from repo
    (or, for lowercase call names, never *called* in the corresponding repo family)."""
    found = defaultdict(list)
    for t, src in files.items():
        code = strip_code(src)
        called_here = {c[0] for c in calls(code)}
        fam_called = (fam_calls or {}).get(t, set())
        imports = dict(re.findall(r"import\s+(?:static\s+)?([\w.]+)\.(\w+);", code))
        ids = identifiers(code)
        for X in ids:
            role_missing = X in called_here and fam_called and X not in fam_called and X[0].islower()
            if (X in repo_ids and not role_missing) or X.startswith(base) or X in JAVA_KW: continue
            pkg = imports.get(X, "")
            if pkg and not pkg.startswith("org.traccar"): continue   # library identifiers: not the repo's business
            recv = re.search(r"\b([A-Z]\w*)\.%s\(" % X, code)
            if recv and imports.get(recv.group(1), "org.traccar").startswith(("io.", "java", "jakarta", "com.")): continue
            if re.search(r"\b(?:io|java|javax|jakarta|com)\.[\w.]*\b%s\b" % X, code): continue   # fully-qualified library use
            ctxs = []
            if re.search(r"class\s+\w+\s+extends\s+%s\b" % X, code): ctxs.append(("extends", None))
            for m in re.finditer(r"\b([A-Z]\w*)\s+(\w+)\s*=\s*new\s+%s\s*\(([^;]*)\)" % X, code): ctxs.append(("var_new", (m.group(2), m.group(1), len([a for a in m.group(3).split(",") if a.strip()]))))
            for m in re.finditer(r"\b(\w+)\(\s*new\s+%s\s*\(" % X, code): ctxs.append(("encl_new", m.group(1)))
            for m in re.finditer(r"\b%s\s+(\w+)\s*[=;)]" % X, code): ctxs.append(("var_type", m.group(1)))
            for m in re.finditer(r"\b%s\.([A-Z]\w*)\.([A-Z_]\w*)" % X, code): ctxs.append(("chain_head", (m.group(1), m.group(2))))
            for m in re.finditer(r"\b([A-Z]\w*)\.([A-Z]\w*)\.%s\b" % X, code): ctxs.append(("chain_const", (m.group(1), m.group(2))))
            for m in re.finditer(r"\b(\w+)\(\s*([A-Z]\w*)\.%s\(" % X, code): ctxs.append(("encl_static", (m.group(1), m.group(2))))
            for m in re.finditer(r"\b([A-Z]\w*)\.%s\(" % X, code): ctxs.append(("static", m.group(1)))
            for m in re.finditer(r"(?<![.\w])%s\s*\(([^()]*(?:\([^()]*\))?[^()]*)\)" % X, code):
                args = [head(a) for a in re.split(r",(?![^()]*\))", m.group(1))] if m.group(1).strip() else []
                ctxs.append(("bare", (len(args), tuple(args[:2]))))
            for m in re.finditer(r"\b%s\(\s*decoder,\s*(\w+)\(\s*\n?\s*\"([^\"]*)\"" % X, src): ctxs.append(("helper", "hex" if re.fullmatch(r"[0-9a-fA-F\s]+", m.group(2)) else "ascii"))
            for m in re.finditer(r"\b(\w+)\(\s*decoder,\s*%s\(\s*\n?\s*\"([^\"]*)\"" % X, src): ctxs.append(("inner", "hex" if re.fullmatch(r"[0-9a-fA-F\s]+", m.group(2)) else "ascii"))
            for m in re.finditer(r"(?:protected|public|private)\s+\w+\s+%s\s*\(([^)]*)\)" % X, code):
                params = tuple(p[1] for p in re.findall(r"(\w+)\s+(\w+)(?:,|$)", m.group(1)))
                if params: ctxs.append(("decl", params))
            for m in re.finditer(r"\b%s\s+(\w+)\s*[,)]" % X, code): ctxs.append(("param_type", m.group(1)))
            for m in re.finditer(r"\b([a-z]\w*)\.%s\(" % X, code): ctxs.append(("recv", m.group(1)))
            if re.search(r"@%s\b" % X, code): ctxs.append(("annotation", None))
            if ctxs or X[0].isupper(): found[X].append((t, ctxs))
    return found
    return found

SPECIFIC = {"extends", "var_new", "encl_new", "var_type", "chain_head", "encl_static", "helper", "inner", "decl", "param_type"}

def resolve(X, occurrences, idx):
    votes = Counter(); evidence = []
    has_specific = any(k in SPECIFIC for _, ctxs in occurrences for k, _ in ctxs)
    for t, ctxs in occurrences:
        fam = idx["fam"].get(t)
        if not fam: continue
        c = idx["ctx"][t]
        for kind, d in ctxs:
            if has_specific and kind not in SPECIFIC: continue
            cand = None
            if kind == "extends": cand = c["super"]
            elif kind == "var_new": cand = c["var_new"].get(d[0])
            elif kind == "encl_new": cand = c["encl_new"].get(d)
            elif kind == "var_type": cand = c["var_type"].get(d)
            elif kind == "chain_head": cand = c["chain"].get((d[0], None))
            elif kind == "chain_const": cand = None   # semantic constant: cannot be resolved by position
            elif kind == "encl_static": cand = c["encl_static"].get(d)
            elif kind == "static": cand = c["static"].get(X) and None
            elif kind == "bare": cand = c["bare"].get(d)
            elif kind == "helper": cand = c["helper_lit"].get(d)
            elif kind == "inner": cand = c["inner_lit"].get(d)
            elif kind == "decl": cand = c["decl_params"].get(d)
            elif kind == "param_type": cand = c["param_type"].get(d)
            elif kind == "recv": cand = c["recv"].get(d)
            if cand:
                tot = sum(cand.values())
                for name, k in cand.most_common(4):
                    if name != X and name not in idx["seen_in_output"] and k / tot >= 0.15:
                        votes[name] += k / tot; evidence.append(f"{kind}:{d}→{name} ({k} files)")
    return votes, evidence

def options_for(X, occurrences, idx):
    opts = Counter()
    for t, ctxs in occurrences:
        c = idx["ctx"].get(t)
        if not c: continue
        for kind, d in ctxs:
            if kind == "chain_const": opts.update(c["chain"].get((d[1], "const"), {}))
            elif kind == "bare": opts.update(c["bare"].get(d, {}))
            elif kind == "recv": opts.update(c["recv"].get(d, {}))
            elif kind == "static": opts.update(c["static"].get(X, {}))
    return [o for o, _ in opts.most_common(6) if o != X]

def run(repo, task_path, out_glob):
    base, types = task_types(Path(task_path).read_text())
    idx = repo_index(Path(repo), types)
    idx["ctx"] = {t: ctx_index(f) for t, f in idx["fam"].items()}
    fam_calls = {t: {c for f in fam for c in f["callset"]} for t, fam in idx["fam"].items()}
    per_ident = defaultdict(list); n_out = 0; seen_all = set()
    for fn in sorted(glob.glob(out_glob)):
        n_out += 1
        files = analyze_output(Path(fn).read_text(errors="replace"), types, base)
        seen_all |= set().union(*(identifiers(strip_code(s)) for s in files.values()))
        for X, occ in find_missing(files, idx["ids"], base, fam_calls).items():
            per_ident[X].append(occ)
    idx["seen_in_output"] = seen_all & idx["ids"]  # names that exist in repo and model already used -> not a replacement target
    rules, unknown, taken = [], [], set()
    # assignment: most frequent identifiers first; a repo name is assigned at most once
    order = sorted(per_ident.items(), key=lambda kv: (-len(kv[1]), -sum(len(c) for occ in kv[1] for _, c in occ)))
    for X, occs in order:
        flat = [o for occ in occs for o in occ]
        kinds = Counter(k for _, ctxs in flat for k, _ in ctxs)
        votes, ev = resolve(X, flat, idx)
        rec = {"old": X, "outputs": len(occs), "of": n_out, "kinds": dict(kinds)}
        ranked = [(n, v) for n, v in votes.most_common() if n not in taken]
        if ranked and ranked[0][1] >= 0.25:
            Y, sc = ranked[0]; taken.add(Y)
            conf = "high" if sc >= 1.0 else "medium"
            rules.append({**rec, "new": Y, "confidence": conf, "evidence": [e for e in ev if "→" + Y in e][:3]})
        else: unknown.append({**rec, "options": options_for(X, flat, idx)})
    return {"base": base, "types": types, "n_outputs": n_out, "rules": rules, "unknown": unknown}

def render(res, min_outputs=2):
    L = ["## Names that differ in this repository (mined from model drafts)", "",
         "The following identifiers appeared in model drafts for this task but do NOT exist in this repository. "
         "For each, the identifier that plays the same role here is given (matched automatically by position/signature).", ""]
    for r in res["rules"]:
        if r["outputs"] < min_outputs: continue
        L.append(f"- `{r['old']}` does not exist here; use **`{r['new']}`** instead  (seen in {r['outputs']}/{r['of']} drafts; match confidence {r['confidence']})")
    unk = [u for u in res["unknown"] if u["outputs"] >= min_outputs]
    if unk:
        L += ["", "Unknown deviations (no unique equivalent found automatically):"]
        for u in unk:
            opt = f"; options seen in that position: {', '.join('`%s`' % o for o in u['options'])}" if u["options"] else ""
            L.append(f"- `{u['old']}` does not exist here (seen in {u['outputs']}/{u['of']} drafts){opt}")
    return "\n".join(L) + "\n"

if __name__ == "__main__":
    repo, task, pat = sys.argv[1:4]
    res = run(repo, task, pat)
    if "--json" in sys.argv: Path(sys.argv[sys.argv.index("--json") + 1]).write_text(json.dumps(res, indent=1))
    print(render(res))
