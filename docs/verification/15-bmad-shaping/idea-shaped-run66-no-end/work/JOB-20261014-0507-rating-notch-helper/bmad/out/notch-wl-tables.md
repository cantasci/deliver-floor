# Notch and WL tables

Source: POC §3A Ind. 10–13, REQ-03-10..13, REQ-06-02. WL = Watchlist level 0–4.

## Rating scale (best → worst, index 0–18)

| Idx | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|---|
| Rating | AAA | AA+ | AA | AA- | A+ | A | A- | BBB+ | BBB | BBB- |

| Idx | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 |
|---|---|---|---|---|---|---|---|---|---|
| Rating | BB+ | BB | BB- | B+ | B | B- | CCC+ | CCC | CCC- |

Notch change = index(current) − index(previous). Positive = downgrade.

## WL by notch change

| Notch change | Ind. 12 (country) | Ind. 11 / 13 (internal / external) |
|---|---|---|
| ≤ 0 (same / upgrade) | 0 | 0 |
| 1 | 1 | 0 (accepted) |
| 2 | 2 | 1 |
| 3+ | 2 | 2 |

Rules: `ind12` (used inside `countryRatingChangeWl`) and `ind11-13` (used by `notchCalculator(previous, current)`, confirmed B-57/B-60; no profile argument).

Accepted ratings are the 19 above; input is trimmed and case-insensitive (`bbb+` = `BBB+`; `Aaa` folds to `AAA`, assumed: C1 does not name it). Errors: CC, C, D/SD, suffixes such as `(neg)`, Unicode minus, `unrated`, Moody's notation, missing or non-string input. `notchCalculator` returns `{ error: <message naming the input> }` and never `wl` alongside it; `notchChange` and `countryRatingChangeWl` throw a `RangeError` naming the input. A success result never contains `error`.

## Examples to test

| Previous → current | Notches | Ind. 12 WL (`countryRatingChangeWl`) | Ind. 11/13 WL (`notchCalculator`) |
|---|---|---|---|
| AAA → AAA | 0 | 0 | 0 |
| A → A- | 1 | 1 | 0 |
| A → BBB+ | 2 | 2 | 1 |
| BBB+ → BB+ | 3 (decided: scale right; POC text "2 notch, WL1" is corrected by the PM as a PR follow-up, not edited here) | 2 | 2 |
| BB → BBB | −2 | 0 | 0 |
