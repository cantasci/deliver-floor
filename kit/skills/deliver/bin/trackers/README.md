# Tracker plugins

Every `*.mjs` file in this folder is loaded by the tracker factory (`../tracker.mjs`) and registers itself with
`registerTracker("<kind>", Class)`. Set `"tracker": {"kind": "<kind>"}` in `.deliver.json` to use it.
See `docs/10-trackers.md` for the contract and a worked example.
