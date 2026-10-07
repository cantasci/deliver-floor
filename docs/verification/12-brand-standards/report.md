# Brand DNA standards in a live job (R4)

Claude Code 2.1.292, `claude -p` (headless, subagents), plugin **0.8.0** installed from this checkout into a fresh HOME
(`scripts/init.sh --subagent --kit-from <checkout>`; `claude plugin list`: `deliver@deliver-floor Version: 0.8.0`).
2026-10-07, 17:57 → 18:19 UTC (it waited for the human's answers in between), $1.65 + $3.17.

## Setup

- Repo: the watchlist-poc seed, with a filled-in brand standard committed in the repo:
  [`.deliver/knowledge/brand-visual.md`](brand-visual.md) (five Must rules `BV-colours`, `BV-type`, `BV-contrast`, `BV-shape`,
  `BV-voice`, a `## Decides` list) and its tokens, [`web/tokens.css`](tokens.css).
- Request: [`JOB-brand.md`](JOB-brand.md). It names no colour, typeface or size, and says "each level in its own colour as the
  brand defines it" and "Follow the company's brand visual identity".

## 1 · Readiness: the BA settled UI items from the standard, quoted

[`readiness.json`](work/readiness.json) has five items with the source `standard: brand-visual.md`, each with the standard's
own words in `quote`, and `dl readiness` accepted them. Among them are the product-shaping UI items `UX-design` (quoting the
level colours from `## Decides`) and `UX-a11y` (quoting `BV-contrast`), as well as `NFR-compliance` and `X-contrast`.

**The standard settled only what it states.** It decides colour, typeface, radius and padding, but not font size or weight.
The BA did not fill that in: it raised `X-typography` ("The brand standard decides colour, typeface, radius and padding but
not font size, weight, line-height or display") as an open business question, and Michael stopped for the human.

The two open questions (`X-typography`, `DEL-deploy`) were about this test's own request, not a user's product. They were
answered with `dl clarify` by the test's author acting as the human, as the earlier scenarios do with `HUMAN_ANSWERS.json`.

## 2 · Role cards carry the rules with their ids

`MUST [BV-…]` rules: 5 each in `ba`, `frontend-lead`, `frontend`, `qa`, `reviewer` and `a11y`, which are the roles in
`applies_to` (reviewers by kind). See [`reviewer.md`](work/reviewer.md).

## 3 · Review: every rule answered, recorded with the review

Michael ran `dl knowledge must reviewer`, gave the list to the reviewer and recorded its answer with `--standards`
([`board.json`](work/board.json), T-01 `reviews[0].standards`):

```
BV-colours  ok: only var() tokens; no hex/rgb/hsl/colour names incl. comments; tokens.css unchanged
BV-type     ok: font-family: var(--font-sans) only
BV-contrast ok: 6.29/5.93/5.93/8.16 >= 4.5, computed at runtime
BV-shape    ok: radius-pill and space-1 padding
BV-voice    ok: text is WL 1..4, no exclamation mark
```

## 4 · Checked from outside

- No colour value outside `web/tokens.css` in the delivered `web/`: [`wlBadge.css`](work/wlBadge.css) uses only `var(--…)`.
- The suite on main passes: 28 tests ([`suite-on-main.txt`](suite-on-main.txt)). History: [`git-log.txt`](git-log.txt).
- The full check output: [`verify.txt`](verify.txt).

## Run 57 · a violated rule sends the card back (fault injection, disclosed)

The same request and brand file, on 0.8.1, in a fresh repo. To exercise the violation path, a git `post-commit` hook in the
test repo added one commit right after the developer's first commit on T-01. The commit was `T-01: outline the badge`, a
`box-shadow` with `rgba(…)`, which is a colour value outside `web/tokens.css` and breaks `BV-colours`
([`injection.txt`](run57/injection.txt)). The hook fired once and was otherwise inactive.

- **The gate caught it.** The developer had written a brand test from the rule in its role card
  ("wlBadge.css has no hex colour, colour function or custom-property definition … BV-colours"). Attempt 1 failed on it
  ([gate log](run57/), `T-01-a1-*.log`).
- **The card went back to the developer.** It removed the commit and passed the gate on attempt 2. QA passed, including the
  whole suite on the card's commit (0.8.1, [`T-01-qa-*-full.log`](run57/)). The reviewer answered all five rules `ok` and
  noted "foreign outline commit reverted". The card was merged and the job done ([`board.json`](run57/board.json),
  [`events.log`](run57/events.log), [`git-log.txt`](run57/git-log.txt)). Cost $0.99 + $3.48.

## Not shown live

- **A reviewer answering `violated`.** In run 57 the gate caught the violation first, so the reviewer saw a clean change. A
  `dl review … approve` with a `violated` answer, an unanswered rule or an `n_a` without a reason is refused in `tests/run.sh`
  only.
- The `a11y` role was on the job (from `UX-a11y`) and its card carries the brand rules, but T-01 had no `reviewers` list,
  so only the stack reviewer reviewed it. This behaviour predates this release and is noted here, not changed.
