# Rating scale, WL tables, interface, worked examples

## Scale (position 1 = best)

| Pos | S&P / Fitch | Moody's |
|---|---|---|
| 1 | AAA | Aaa |
| 2–4 | AA+, AA, AA- | Aa1, Aa2, Aa3 |
| 5–7 | A+, A, A- | A1, A2, A3 |
| 8–10 | BBB+, BBB, BBB- | Baa1, Baa2, Baa3 |
| 11–13 | BB+, BB, BB- | Ba1, Ba2, Ba3 |
| 14–16 | B+, B, B- | B1, B2, B3 |
| 17–19 | CCC+, CCC, CCC- | Caa1, Caa2, Caa3 |
| 20 | CC | Ca |
| 21 | C | C |

SD, D, NR, WR and unknown symbols are not on the scale (error, CAP-3). Input is case-insensitive and trimmed. Mixing the two notations in one call is accepted; both map to positions.

## Notch change

`notches = position(current) - position(previous)`. Positive = downgrade, negative = upgrade, 0 = unchanged (BB → BBB is -3). `notches` in the result is signed exactly like this; `direction` says the same in words. Outlook/watch changes are not rating symbols and are out of scope.

## WL by indicator kind

Let `d = max(notches, 0)` (downgrade notches).

| kind | WL 0 | WL 1 | WL 2 |
|---|---|---|---|
| `country` (Ind. 12, REQ-03-12) | d = 0 | d = 1 | d ≥ 2 |
| `internal` (Ind. 11, REQ-03-11), `external` (Ind. 13, REQ-03-13) | d ≤ 1 | d = 2 | d ≥ 3 |

A 1-notch downgrade is WL 1 for `country` and WL 0 for `internal`/`external` (Ind. 13 starts at 2 notches; Ind. 11 assumed the same).

## Interface (shape fixed here, names chosen by the implementer)

- Input: `{ previous, current, kind }`, with `kind` one of `country | internal | external`.
- Success: `{ ok: true, notches, direction: 'downgrade' | 'upgrade' | 'unchanged', wl }`.
- Error: `{ ok: false, error: 'unknown_rating' | 'missing_input' | 'unknown_kind', field }`. Never throws for bad input.
- Country indicator (CAP-2) is the `country` kind with `previous` = rating 12 months ago, `current` = today.

## Worked examples

| previous → current | kind | notches | WL |
|---|---|---|---|
| AAA → AAA | country | 0 | 0 |
| AA → AA- | country | 1 | 1 |
| BBB → BB+ | country | 2 | 2 |
| BB+ → BBB- | country | -2 (upgrade) | 0 |
| BBB+ → BBB | internal | 1 | 0 |
| BBB → BB+ | internal | 2 | 1 |
| BBB+ → BB+ | external | 3 | 2 |
| A2 → Baa1 (Moody's) | external | 2 | 1 |
| BB → BBB | country | -3 (upgrade) | 0 |
| BBB+ → BB+ | any | 3 (REQ-06-02 states 2 / WL 1: documentation slip; the POC owner corrects it outside this job) | 2 |
| BBB → "XYZ" | country | error `unknown_rating`, field `current` | — |
| null → AA | country | error `missing_input`, field `previous` | — |
| BBB → NR | country | error `unknown_rating`, field `current` | — |
