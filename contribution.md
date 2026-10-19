# 0.18.0 work in progress: fixes from the live job's lessons

Branch: `claude/lessons-0.18` (from `main` f0f76a4). **Nothing is committed yet.**

The request: review the lessons of JOB-20261018-1659 (watchlist-poc v0.3) and JOB-20261009-2215, and add the fixes they call
for. The main problem: a card needed `.env.local`; nobody asked for it at the start, and the work began without it. Added
during the work: an option to run the full suites at the end instead of at every card.

## Done in the code (not tested yet)

### 1. Inputs only a person can provide (the main problem)

- **The new readiness item `DEL-inputs`** (`readiness.yaml`) is `ask: human`. It asks about credentials, keys, accounts, sandbox access and `.env` files.
- **The new `kit/skills/deliver/bin/inputs.mjs`** handles the `readiness.json → inputs` list: `[{id:"IN-1", what, file:"/abs/path", link:".env.local", keys:[…], check:"curl … -w '%{http_code}'", for}]`.
  - `shapeErrors` checks the shape. When `DEL-inputs` is decided, inputs must not be empty; when it is n/a, they must be.
  - `checkInput` runs these checks:
    - the file exists, is not tracked by git, and is ignored when it sits inside the repo;
    - `link` is ignored;
    - every key has a value;
    - the `check` command passes; only an HTTP status is reported, never a value.
- **`readiness.mjs`** validates the inputs. It adds an "Inputs" table to `readiness.md`. In `QUESTIONS.md`, each missing input becomes its own question and is listed first.
- **The new `dl` command `dl input [list] | check [IN-n…] | defer IN-n "<the human's words>"`**:
  - `defer` is human-only; bash-guard refuses it in a headless session.
  - The results are recorded in `job.json` under `.input_checks` and `.input_deferred`.
  - `link_inputs` symlinks each provided input into every worktree, and only where git ignores it.
- **Enforcement:**
  - `dl phase planning` refuses while an input is neither provided nor deferred.
  - `dl wt add` refuses a card whose `card.inputs` is missing. No attempt is used.
  - `ready_ids` skips such cards.
  - `dl next` prints an `INPUT` line first, every time.
  - STUCK says the card waits for an input.
  - stop-guard counts a card waiting for an input as the human's to unblock.
  - `report_inputs` adds a section to the PR.
- **`validate.mjs`:** `card.inputs` ids must exist. A WARN appears when an input is used by no card. The card field `inputs` is in CARD_FIELDS.

### 2. Suites: a timeout, and when they run (`suite_runs`)

- **`run_timed`** stops a run with Perl's `alarm` in its own process group (124 = STALLED). The gate's `timeout(1)` did not exist on macOS, so the gate had no limit there.
- **`suite_timeout`** is `settings.suite_timeout_min`. Otherwise it is 3× the baseline time (at least 20 min). Without a baseline time it is 60 min.
- **These runs now have a timeout:** the QA-pass suite, the suite after a merge (STALLED, and the lane keeps moving), stack-test, verify-all, the baseline (90 min), and the gate's verify and qa_verify.
- **`settings.suite_runs`:**
  - `card` (the default): as today.
  - `batch`: after a merge, if another card of the same component is ready to merge, the suite waits for it (merge_check DEFERRED); BROKEN names the whole batch.
  - `end`: only the baseline and verify-all.
- **`blame_log`:** when verify-all fails, it lists the merged cards whose files the failures name (`LIKELY T-xx`).
- **Baseline:** its seconds are recorded. When it takes more than 10 min and `suite_runs` is not set, `dl phase planning` refuses and Michael asks the human.
- **`dl next`:** a STALLED suite also gives a FIX line.

### 3. Deadlocks and mechanics

- **A QA commit after a failed gate** (`qa_fix`): the gate takes it as QA's. The help functions are `qa_mark`, `qa_unrecorded` and `qa_unrecorded_msg`.
- **`dl card X state blocked`** is refused while QA has unrecorded commits.
- **`dl qa`:** when the -qa branch has not been joined, it refuses with "run dl qa-join first". On a pass, the files named in stack_verify must exist.
- **`dl wt rm`** also removes the -qa worktree. `dl wt rm T-05-qa` is accepted.
- **`dl_merge`** tries the first message twice, because a commit-msg hook's refusal can be transient.
- **`dl card set T-xx …`** is accepted as well as `dl card T-xx set …`.
- **Gate scope FAIL** prints a single `dl card set scope '<json>'` command with every out-of-scope file.
- **`dl card T-xx continue "<why>"`:**
  - It builds a continuation card from the live board, with a spec copy.
  - It splits the commits into dev and QA cherry-pick lists.
  - It archives the old card and re-points depends_on and stack_after to the new one.
- **The gate catches Python test-module name clashes** (the new `bin/pyclash.mjs`, `py_clash`, `added_py`): the dev's at the gate, QA's at `dl qa pass`.
- **`dep_setup`:** Node lockfile folders the card names (e2e/, frontend/) get `npm ci` in its worktree. After a merge that changes a lockfile, the integration worktree reinstalls. It can be turned off with `settings.worktree_deps:false`.
- **`dl next`:**
  - **PING:** an agent that has run more than `agent_ping_min` (20) is asked why (interactive sessions only).
  - The STACK lines come before the per-card lines.
- **bash-guard:**
  - `git stash` is refused in job worktrees.
  - Agents cannot run `dl input`.

Syntax (`bash -n`) and `tests/lint-bash32.mjs` are clean. The full `tests/run.sh` was started; its result is not in yet. The log is in the scratchpad as `run1.log`. Run it again: `bash tests/run.sh`. The earlier baseline was 990 passed, 4 known failures from Munder Difflin.

## Still to do

1. **Fix the existing tests.** Expected failures:
   - the `wt rm` output;
   - the merge-refusal count, since the first message is tried twice;
   - the `qa` order;
   - the gate's out-of-scope output has an extra "→" line.
2. **New tests in `tests/run.sh`:**
   - inputs: missing, tracked, not ignored, an empty key, a 401 check, deferral, wt add refusal, the link;
   - suite_runs batch and end, and run_timed STALLED;
   - qa_fix;
   - block refusal;
   - qa-join-first;
   - wt rm -qa;
   - card continue;
   - py clash;
   - dep_setup;
   - PING;
   - the validate rule that a verify inside qa_scope is an ERROR.
3. **Rules in the text:**
   - **SKILL.md:**
     - Phase 0.5 inputs: ask with AskUserQuestion, one per input, with the exact path and never in the chat; then `dl input check` or `defer`.
     - Phase 3: INPUT, PING and STALLED.
     - The rules:
       - zsh-safe chains, one dl call per step, no background watchers that fire dl steps;
       - one merge loop; before TaskStop, check with ps whether `dl integrate` is running;
       - record QA before blocking; never revert QA's commits;
       - a review defect in a QA test goes to QA (QA-RUN in the card worktree, then `dl qa` again), never to the dev;
       - decide spec conflicts before a fix is dispatched;
       - one red component suite gets one fix card;
       - after a contract change, update the card's context too;
       - continue with `dl card continue`.
   - **roles.yaml, lead:**
     - when a card changes existing behaviour, the old unit and integration tests that pin it go in its scope and verify;
     - before a fix card that changes a script's behaviour, grep the tests that pin the old behaviour;
     - no nested whole-suite test in verify;
     - CLI `-m` overrides addopts;
     - parallelism: split FE chains, doc cards depend only on facts, seat counts match the shape of the ready cards;
     - stack_after names every card whose endpoint the test calls;
     - stack_verify names stack specs only, with an exact file name.
   - **roles.yaml, qa:**
     - run the whole component suite before handing back from QA-WRITE;
     - write the stack spec under the exact name stack_verify gives and check it with `--list`;
     - after a failed gate, QA's fixes go to the card worktree (the gate takes them);
     - test helper modules get a prefix after their folder.
   - **roles.yaml, dev:** unit helpers get the `unit_` prefix, and no `git stash`.
   - **`kit/agents/business-analyst.md`:** add `inputs` to the READINESS JSON format and explain DEL-inputs.
4. **Settings:**
   - `deliver.schema.json`: suite_runs, suite_timeout_min, worktree_deps, agent_ping_min, card `inputs`.
   - `docs/03-settings.md`.
5. **Docs:**
   - CHANGELOG 0.18.0;
   - plugin.json → 0.18.0;
   - README;
   - doctor (does Perl exist?);
   - a new doc page (inputs + suite_runs);
   - map each lesson to its fix (a table in the PR).
6. Commit, push (SSH: `git@github.com:cantasci/deliver-floor.git`) and open a PR. **Only when the user asks.**
7. **NEW, from the user (not started): fix cards go through the planning flow.**
   - **What the user said:** "duzeltme isleri micheal kendi yapiyordu, aslinda bunu PM e vermesi lazimdi, baslangicta planning de nasil ilerleniyorsa ayni sekilde ilerlemesi gerkiyor, eger bir duzeltme taski olusturualcak aktif bir board varken bunu yine ayni mantikla yapiyor olmamaiz lazim"
   - **Today:** in the live job Michael wrote the fix and continuation cards himself (card JSON + spec) and ran `dl card add`. The roles were bypassed.
   - **Wanted:** while a board is active, a fix card is cut the same way as in planning. The finding goes to the roles: the BA, if it touches the plan or the ACs; the Lead cuts the card(s) (MODE FIX: the finding, the merged code, the cards that pin it); the BA writes the spec (MODE CARD SPECS, a test design included). Then `dl validate` and `dl card add`. Michael only orchestrates.
   - **Proposed in dl:**
     - `dl fix open "<finding>" [--from T-xx|merge-check|stack|verify-all|review]` opens a fix request (F-n).
     - `dl next` lists its steps in order: `FIX-CUT F-n` (the Lead's dispatch prompt, from SKILL.md) → `FIX-SPEC F-n` (the BA) → `dl card add <card.json> --fix F-n`.
     - `dl card add` after the start is refused without `--fix F-n`, without the Lead's answer file (`.work/<job>/out/fix-F-n-<lead>.json`, or the agent named in `dl agents`) and without the BA's spec for the new card.
     - The FIX lines of `dl integrate` (BROKEN/STALLED), stack-test and verify-all, and the blocked-card DECIDE "split", all go through this flow.
     - `dl card continue` stays mechanical (it carries the same contract), but a contract change in it goes through the Lead as well.
   - **Ask the user first:** by "PM" they most likely mean the planning roles (Lead + BA), since Michael is the PM in the playbook. Confirm that this reading is right.

## Lessons → fixes

| Lesson (topic) | Fix |
| --- | --- |
| process (human-only inputs / credential check / secrets path) | DEL-inputs, `dl input`, planning and wt add guards, INPUT lines |
| qa-run-after-failed-gate | the gate takes `qa_fix` |
| verify-vs-qa-pins | validate: a verify inside qa_scope is an ERROR |
| no-nested-full-suite-in-verify, merge-lane (human kill) | run_timed + STALLED; baseline time; suite_runs; Lead rule |
| contract-edit (block with QA unrecorded) | `card state blocked` is refused |
| contract-edit (set order, scope widen) | `card set T-xx` alias; one scope command |
| continuation-card-from-live-board, continuation-card-handover | `dl card continue` |
| qa-join-order | `dl qa` asks for the join first; the merge is retried |
| worktrees (-qa left behind) | `wt rm` removes -qa |
| no-git-stash-in-worktrees | bash-guard |
| unique-test-module-names | pyclash (gate and qa) |
| e2e-worktree-node-modules, integration-worktree-env | dep_setup |
| stack-tests (exact file, run first) | qa pass file check; STACK lines first |
| long-running-agents | PING |
| merge-lane batch fix cards | suite_runs batch + rule |
| orchestrator-shell-chains, watcher-guards, qa-frozen-after-pass, spec conflicts, parallelism, fix-card-pins, scope-covers-pinned-tests | rules in SKILL.md and roles.yaml (still to write) |
