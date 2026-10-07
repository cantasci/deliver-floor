---
title: Brand visual identity
applies_to: [ba, lead, frontend, mobile, review, qa]
topics: [brand, ui, design]
---
# Brand visual identity

The company's (or this project's) visual identity: what every screen, e-mail and asset looks like. Written once by the
people who own the brand; every job reads it.

How /deliver uses this file:
- **Must** rules reach the role cards of the roles in `applies_to`. A reviewer answers each one per card — `ok`,
  `violated: <what>` or `n_a: <why>` — and `dl review … approve` is refused while one is unanswered or violated.
- A rule that still holds a `{{…}}` is **not a rule yet**: it reaches no one and `dl knowledge list` reports it. Fill it
  in or delete it — never leave a guess in it.
- The Business Analyst may settle a UI question from this file only where it states the answer in so many words
  (readiness source `standard: brand-visual.md` + the words, verbatim). Anything it does not state is asked to you.
- Keep each rule's `[id]`: reviews and readiness answers refer to it. Narrow `applies_to` to role names
  (e.g. `[ba, frontend, reviewer-ts, qa]`) if other reviewers should not answer these rules.

## Must

- [BV-colours] Colours come only from the brand tokens in {{the tokens file, e.g. src/styles/tokens.css}}; no other colour value is written in code or styles.
- [BV-type] Text uses only the typefaces {{primary typeface}} and {{secondary typeface, or "none"}}, at the sizes of the type scale below.
- [BV-logo] The logo is used only from {{logo asset folder}}, never redrawn, recoloured or stretched, with at least {{clear space}} of clear space around it.
- [BV-contrast] Text and its background meet {{contrast level, e.g. WCAG 2.2 AA}}.
- [BV-voice] Interface text follows the voice: {{one sentence: how the brand speaks, e.g. formal "siz" / informal "sen"}}.

## Decides

What this file settles for a job, so nobody has to ask (fill in; delete what you do not want it to decide):

- Primary colour: {{name and value}}
- Secondary colour(s): {{names and values}}
- Error / warning / success colours: {{values}}
- Typefaces: {{primary}} / {{secondary}}
- Corner radius: {{value}}
- Spacing unit: {{value}}
- Dark mode: {{yes, with its tokens in … / no}}

## Tokens

{{Paste or link the colour, spacing and radius tokens — name: value — exactly as the code uses them.}}

## Typography

{{The type scale: name — size / line height / weight, e.g. "heading-1 — 32/40/700".}}

## Logo and assets

{{Where the logo files and icons live, which variant goes on light and dark backgrounds, the minimum size.}}

## Examples

{{Links or paths to screens that are on-brand, and any that are known not to be.}}
