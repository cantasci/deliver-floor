# Questions before the work can start — JOB-20261004-2211-hard-factor-indicators-4-6-9

Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"

## PRD-acceptance

The request gives only one WL per indicator: '2nd reminder' → 2, 'DSC not given' → 4, '(Yes –) with forbearance' → 3. A4 requires the logic to mirror the Excel dropdown sheet exactly, but that sheet is in neither the request nor the repo. What WL (0–4) does each of the six other options return? Ind. 4: 'On schedule' and '1st reminder'. Ind. 6: 'DSC given' and 'DSC weak'. Ind. 9: 'No' and 'Yes – without forbearance'.

- A (preferred): the business supplies the six values from the Excel dropdown sheet (A4).
- B: the business confirms this proposal, which is a guess by severity order and not taken from the sheet: On schedule=0, 1st reminder=1; DSC given=0, DSC weak=2; No=0, Yes – without forbearance=1.
- C: the business gives other values.

_Why it matters:_ Without these values, 6 of the 9 option→WL examples cannot be tested, and the dev would have to invent scoring that A4 forbids. A wrong value changes a client's WL and so the watchlist outcome.

## CON-interface

Already fixed by the request: the file paths, the function names, a single `option` argument, and the return value (WL, see X-wl-output). Open: (a) What exactly is `option`? Do callers pass the dropdown labels verbatim (e.g. 'Yes – without forbearance' with an en dash, '1st reminder'), case- and whitespace-sensitive, or stable keys or constants? (b) Are the functions named exports or default exports? (c) Does each module also export its list of valid options for the form?

- A: the verbatim dropdown labels as strings, exact match (case- and whitespace-sensitive, en dash '–' in Ind. 9); named exports disclosureDeadlineWl / dscWl / materialWaiverWl; each module also exports its option labels as a constant.
- B: stable keys exported as constants (e.g. 'ON_SCHEDULE','FIRST_REMINDER','SECOND_REMINDER'; 'GIVEN','WEAK','NOT_GIVEN'; 'NO','YES_WITHOUT_FORBEARANCE','YES_WITH_FORBEARANCE'); named exports.
- C: labels with tolerant matching (trim, case-insensitive, '-' accepted for '–'); named exports. The normalisation rules must then be listed.

_Why it matters:_ This is the public contract that other POC parts import. A mismatch makes the form's value fail or score wrongly. Exact matching fits A4 best. Watch out: 'Yes – without forbearance' contains 'with', so any substring or prefix matching would give the wrong score.

## CON-errors

The request is silent: what must disclosureDeadlineWl / dscWl / materialWaiverWl do when `option` is not one of their three options? Cases: an unknown string (e.g. '3rd reminder'), wrong case or extra whitespace (if matching is exact), '' (nothing picked yet), null, undefined, a non-string (e.g. 2), or another indicator's option (e.g. dscWl('No')).

- A: throw: RangeError for an unknown string, TypeError for a non-string or null/undefined, with a message naming the received value and the allowed options. Fail fast, never a silent score.
- B: return null (no WL), and the caller or the REQ-05-01 aggregation decides what to do.
- C: return a fixed fallback WL: 4 (worst case, conservative) or 0 (no signal).

_Why it matters:_ This changes observable behaviour and the contract with the form and the aggregation. A silent fallback can put a client on or off the watchlist wrongly, which A4 rules out. Throwing forces the form to handle the error; null forces the aggregation to handle a missing WL. It also decides whether 'not picked yet' is an error or a valid state.

## X-dsc-q8

Q8 is still open in the POC: what distinguishes DSC 'weak' from 'not given'. Does this slice need that answer, or does dscWl only map the option the analyst picked (A2)? Note: job.json records Michael's assumption 'no definition logic needed', but that assumption is not a business answer.

- A: not needed. The analyst applies the definition when choosing; dscWl maps the three labels only. Q8 stays a POC-level open point and does not block REQ-03-06.
- B: needed. Settling Q8 may change the option list (merge or split weak/not given) or the WL for 'weak', so REQ-03-06 waits; Ind. 4 and 9 proceed.
- C: needed as logic. dscWl computes the category from input data (e.g. a DSCR value and a threshold), which changes the contract from option to number. That would be a scope change.

_Why it matters:_ A keeps the contract as written. B delays one of three Must items. C changes the public signature and the scope. The WL for 'DSC weak' (PRD-acceptance) may also depend on Q8.
