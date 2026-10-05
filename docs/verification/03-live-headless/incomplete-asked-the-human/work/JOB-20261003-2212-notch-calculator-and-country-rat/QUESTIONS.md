# Questions before the work can start — JOB-20261003-2212-notch-calculator-and-country-rat

Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"

## PRD-priority

If both requirements cannot ship together, which one comes first?

- Both Must: ship together as one slice
- REQ-06-02 Must, REQ-03-12 Should (it depends on notchChange anyway)
- REQ-03-12 Must, with only notchChange from notch.mjs; notchCalculator Should

_Why it matters:_ Affects scope only if the job is cut short. The slice is small, so 'both Must' is likely.

## CON-errors

For non-string input (null, undefined, 42, {}), should the functions throw RangeError (literal C1: 'anything else') or TypeError?

- RangeError for every invalid input, strings and non-strings alike
- TypeError for non-string input, RangeError for strings not on the scale

_Why it matters:_ Observable error contract; callers' catch logic and QA error-path tests depend on it. Either way, no value is returned for invalid input.
