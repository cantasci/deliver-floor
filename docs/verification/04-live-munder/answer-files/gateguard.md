# GateGuard and the seats' answer files

ECC 2.2.3's own `gateguard-fact-force.js` (`run()`), a first Write in a fresh session, with the kit's `GATEGUARD_EXEMPT_GLOBS` before (0.6.0) and after (0.6.1). Run 53 lost one round trip to this per answer file (5 in the job).

```
== OLD: .work/*/*.md,.work/*/*.json,.work/*/specs/**,.work/*/roles/**,.work/*/handoffs/**,.work/*/prompts/**,.work/*/munder/**
BLOCKED  .work/JOB-1/out/readiness-ba.json
BLOCKED  .work/JOB-1/out/.prev/plan-ba.md.20261006T1
BLOCKED  src/a.mjs
== NEW: .work/*/*.md,.work/*/*.json,.work/*/specs/**,.work/*/roles/**,.work/*/handoffs/**,.work/*/prompts/**,.work/*/out/**,.work/*/munder/**
allowed  .work/JOB-1/out/readiness-ba.json
allowed  .work/JOB-1/out/.prev/plan-ba.md.20261006T1
BLOCKED  src/a.mjs
```
