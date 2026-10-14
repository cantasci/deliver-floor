# Decisions before the work can start — JOB-20261014-0507-rating-notch-helper

BMad shaped this request. Below is what it decided, assumed, asked or found; nothing it wrote binds until you decide.
Michael's proposal stands on BMad's own words (quoted). Answer each in a terminal — `dl clarify <id> "<your decision>"` —
or accept all of Michael's proposals at once: `dl clarify proposals "<your words>"`.

## B-64 — question (bmad-architecture)

Is Moody's 'Aaa' accepted as AAA through the case-insensitive fold, or rejected as Moody's notation? B-58/B-61 give no explicit ruling on this string. The spine keeps the fold and lists the question under Deferred.

- **Michael proposes:** Keep the fold: 'Aaa' is accepted as AAA through the case-insensitive match, and every other Moody's rating stays rejected. The spine's AD-5 already works this way and the rest of the helper is unaffected; Credit Policy can overrule it later in one place (the validator).
  _BMad's words:_ ""Aaa"` folds to `AAA` by the case-insensitive rule" (ARCHITECTURE-SPINE.md)

