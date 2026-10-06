# T-02 QA-WRITE (qa#1)
File: test/indicators/integration/delayCount.test.mjs (committed on ...--T-02-qa). No verdict yet; fails at import (ERR_MODULE_NOT_FOUND) as product is absent.
- AC-7: frozen array/order/push TypeError
- AC-8: "0"→0,"1"→1,">1"→2, map → [0,1,2]
- AC-9: four whitespace cases
- AC-10: 12 invalid strings (message non-empty, contains value), 12 non-strings (RangeError not TypeError, message non-empty), numeric 0/1/2, no-arg
- AC-11: exact exports, no default, sync/pure, list unchanged, no import/I-O in source
- AC-12 (testable part): no daysWithDelay reference. "Only two files added" is a git-state check, not tested (rule 13); gate/reviewer to check.
