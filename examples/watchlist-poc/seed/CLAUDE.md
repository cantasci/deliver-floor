# Watchlist POC — notes for agents

- Plain Node.js 18+ ES modules (`.mjs`). No npm dependencies; do not add any.
- Tests: `node:test` + `node:assert/strict`, files `test/<area>/<name>.test.mjs`. `npm test` runs everything.
- Domain words: WL = Watchlist level (0–4, higher is worse). Indicators are numbered as in the POC requirements (Ind. 1–13).
- Pure functions, no I/O in `src/ratings` and `src/indicators`.
