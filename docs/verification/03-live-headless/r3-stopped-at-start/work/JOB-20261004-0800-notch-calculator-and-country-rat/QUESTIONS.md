# Questions before the work can start — JOB-20261004-0800-notch-calculator-and-country-rat

Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"

## X-trim-whitespace

C1 says 'Input is trimmed' but does not define which characters are trimmed from the start and end of a rating. Which whitespace must be stripped?

- (a) All Unicode whitespace and line terminators, as JavaScript String.prototype.trim() does (space, tab, newline, CR, NBSP U+00A0, BOM U+FEFF, U+2000-U+200A …).
- (b) ASCII whitespace only (space, \t, \n, \r, \f, \v); '\u00A0BBB+' throws RangeError.
- (c) Spaces (U+0020) only; '\tBBB+' and 'BBB+\n' throw RangeError.

_Why it matters:_ Decides which inputs are accepted vs rejected with RangeError in all three public functions; matters for ratings pasted from web pages/spreadsheets (NBSP) or CSV lines (trailing CRLF).
