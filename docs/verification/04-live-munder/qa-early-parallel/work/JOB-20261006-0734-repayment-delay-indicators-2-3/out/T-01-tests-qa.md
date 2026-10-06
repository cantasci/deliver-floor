# T-01 QA-WRITE (qa#1)
File: test/indicators/integration/daysWithDelay.test.mjs (committed on branch ...--T-01-qa). No verdict yet; product code absent, file fails at import (ERR_MODULE_NOT_FOUND) — expected.
- AC-1: frozen array/order/push TypeError
- AC-2: "no delay","<=3 days" → 0
- AC-3: 2/3/4 + map → [0,0,2,3,4]
- AC-4: five whitespace cases
- AC-5: 13 invalid strings, 10 non-strings, no-arg → RangeError
- AC-6: message contains ">3 Days"; Symbol/object/null safe, not TypeError
- AC-11: exact exports, no default, sync/pure, list unchanged, source has no import/I-O
- AC-12 (testable part): no delayCount reference. "Only two files added" is a git-state check, deliberately not tested (rule 13); gate/reviewer should check it. Unit test run is dev's.
