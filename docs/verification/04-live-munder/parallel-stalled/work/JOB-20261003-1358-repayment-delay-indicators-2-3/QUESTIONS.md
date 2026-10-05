# Questions before the work can start — JOB-20261003-1358-repayment-delay-indicators-2-3

Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"

## X-trim-semantics

C1 says 'Input is trimmed' without defining whitespace. Does that mean String.prototype.trim() (also strips tabs, newlines, Unicode spaces such as NBSP) or only ASCII spaces? Internal whitespace is never collapsed ('>3  days' -> RangeError).

- String.prototype.trim(): '\t>3 days\n' -> 2 and '\u00a0>3 days' -> 2
- ASCII-space-only trim: '\t>3 days' -> RangeError

_Why it matters:_ Changes results only for exotic whitespace input.
