# Questions before the work can start — JOB-20261004-0800-rating-notch-calculator-and-coun

Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"

## X-input-whitespace

C1 says input is 'trimmed' but does not say which characters are trimmed. Which leading and trailing characters are removed before matching?

- A — JavaScript String.prototype.trim(): all Unicode whitespace and line terminators (space, tab, \n, \r, NBSP U+00A0, U+2003 …). ' bbb+\n' and '\u00A0BBB+' are accepted.
- B — ASCII space only (U+0020). '\tBBB+' and '\u00A0BBB+' throw RangeError.
- C — ASCII whitespace only (space, \t, \n, \r, \f, \v). '\u00A0BBB+' throws RangeError.

_Why it matters:_ Decides whether inputs pasted from a public source or spreadsheet (tabs, NBSP, newlines) are accepted or rejected with a RangeError. Observable behaviour of all three functions; QA test data depends on it. Inner whitespace ('BBB +') is rejected under every option.
