# Questions before the work can start — JOB-20261005-1516-credit-watchlist-poc

Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"

## PRD-acceptance

Many requirement ACs are summaries without the full value-to-WL mapping, so they cannot be tested exhaustively. A4 says scoring mirrors the Excel dropdown sheet exactly, but that sheet is not attached. Please provide the Excel dropdown sheet (or the full mapping). Missing values: Ind.1 own WL when 'Yes'; Ind.2 'no delay' and '<=3 days'; Ind.3 '0'; Ind.4 'On schedule' / '1st reminder'; Ind.5 unqualified opinion; Ind.6 'DSC given' / 'DSC weak'; Ind.7 '>=110%'; Ind.8 FX LCR '<90%' (no WL stated at all); Ind.9 'No' / 'Yes - without forbearance'; Ind.10 'B-' (B -> 1, CCC+ and below -> 2, B- unmapped); Ind.11 'same/upgrade' and '1 notch'; Ind.12 upgrade and 0 notch; Ind.13 '1 notch' and upgrade; Soft Factor WL per Yes (Q1). See X-wl-mapping.

- Business supplies the Excel dropdown sheet; BA derives the full mapping table from it
- Business confirms an assumed default (every unstated option -> WL=0) in writing
- Leave unstated options unscored (WL shown as '-') until confirmed

_Why it matters:_ Without the mapping the scoring engine (REQ-05-01) and every per-row WL (REQ-03-14) cannot be specified or tested; A4 forbids interpretation.

## PRD-conflicts

The request contradicts itself in these places. Which resolution applies to each? (1) REQ-06-02 example 'BBB+ -> BB+ = 2 notch downgrade -> WL=1': on the S&P/Fitch scale BBB+ -> BBB -> BBB- -> BB+ is 3 notches, and 3 notches gives WL=2 under REQ-03-11/03-13 and also under REQ-03-12 (2+ -> WL=2), so the example matches no rule (X-notch-example). (2) REQ-05-03 says 'Checked By' stays inactive until an override is saved, but REQ-05-04 makes Checked By mandatory for every save, so an assessment without an override could never be saved (X-checked-by). (3) REQ-04-05 calls the comment 'mandatory if Yes' but the AC says only a 'validation warning on submit' (blocking vs non-blocking, X-sf-comment). (4) Hiding SF-11 for private companies is Should in REQ-01-04 and Must in REQ-04-06. (5) REQ-02-06 uses one company-name query, while §3B uses different queries per question (company + sector, company + supplier), and no sector or supplier field exists in REQ-01-01 (X-news-queries). (6) REQ-02-05 asks for market-cap change, but §3B SF-11 says '12-month price history' (X-marketcap-basis). (7) REQ-02-03 limits the BDDK LCR fetch to 'Turkish listed banks', but §3A Ind.7/8 and REQ-03-07/08 pre-fill for every Turkey bank. (8) Country rating: 1 notch -> WL=1 (REQ-03-12); internal and external rating: 2 notches -> WL=1 (REQ-03-11/13). Is the difference intended? (9) The minimum condition 'B or below' (REQ-05-02) includes B-, which REQ-03-10 leaves unscored. (10) §4 calls a field 'Pre-filled (locked)' yet 'editable' (A3 says editable). (11) A5 labels the 110% LCR threshold as Turkey, but REQ-03-07 applies it to every bank, including Germany and Other. (12) REQ-04-01 says 'all 12 questions' must be answered, but SF-11 is hidden for private companies. Are hidden questions and indicators excluded from completeness and from the max-rule (X-hidden-fields)?

- Business resolves each numbered item
- BA proposes: (1) correct the example to 3 notches with the WL from the agreed table; (2) Checked By enabled once the WL is final (with or without override); (3) blocking; (4) Must; (5) per-question queries plus a new optional sector field; (6) price change as proxy; (7) all Turkey banks; (8) intended as written; (9) B- -> per Excel; (10) editable; (11) 110% for all banks; (12) hidden = excluded. Business confirms.

_Why it matters:_ Each item changes observable behaviour or a business rule. Several block ACs for EPIC-03/04/05/06.

## CON-interface

The input and output contracts are not specified. (a) Customer number: format, length, uniqueness? (b) Ticker: which format? Yahoo needs an exchange suffix (e.g. 'THYAO.IS'), KAP uses the bare code ('THYAO'), Germany uses e.g. 'SAP.DE'. Does the analyst enter one ticker or one per source? (c) Rating scales: are internal/country/external ratings exactly AAA..CCC- (19 grades), and how are Moody's ratings (Aaa..Caa3) handled (X-rating-scale)? (d) LCR / FX LCR: is a numeric % pre-filled and banded by the system, or a band dropdown ('>=110%' / '<110%')? Where is the boundary (exactly 110.0% -> '>=110%')? (e) Market-cap change: sign convention and precision (e.g. -23.4%)? (f) The name and shape of the backend API between UI and engine, if there is a split (ARC-style).

- Business specifies (a)-(e); PM/backend-lead fixes (f) once ARC-style is decided
- Accept BA defaults: free-text customer number (non-empty); separate Yahoo ticker and KAP code fields; S&P/Fitch scale plus Moody's mapped 1:1 by notch; numeric LCR % with band derived (>=110 -> pass); % change rounded to 1 decimal, negative = decline

_Why it matters:_ Defines field validation, fetch keys and testable example values for EPIC-01/02/03.

## ARC-style

What application shape should the POC have? The request implies a browser UI (source links 'open ... in a new tab', tabs, coloured fields) plus server-side fetching (scraping and RSS cannot run from a browser because of CORS) and a scoring engine. It does not say whether this is one deployable or a UI/API split, or where it runs.

- A: two-tier web app: backend API (fetchers + scoring + persistence) plus a separate SPA web front-end (matches the backend and frontend roles on the job)
- B: single full-stack app in one language (e.g. Python server-rendered pages or Streamlit/Dash); the frontend role would shrink or drop
- C: single Node/TypeScript full-stack app (loses the yfinance and Python KAP client libraries named in the request)

_Why it matters:_ Fixes the components, roles, reviewers and the CI command; tied to ARC-stack.

## ARC-components

The component list in architecture below is a proposal that follows ARC-style option A. Please confirm the components, the stack of each, and whether a database component exists (ARC-data).

- Confirm the proposed watchlist-api + data-fetchers + watchlist-web (plus watchlist-db if ARC-data decides on persistence)
- Collapse into one component (ARC-style B/C)

_Why it matters:_ Every card must belong to one component; reviewers depend on the stack.

## ARC-stack

Which language, runtime and framework should the POC use? The repo has no code and the request names no language. Evidence: §3A Ind.5 and §3B SF-3/4/12 name a 'Python KAP client'; §3B SF-10/11 and REQ-02-05 name 'yfinance (free library)', a Python package. The browser UI implies HTML/JS. Are new third-party dependencies allowed, and under which licences? (The request only requires 'free' sources and libraries.) Note: the job's verify command 'npm test' is a tool default, not a decision.

- Python 3.12 backend (FastAPI or Flask; yfinance, a KAP client, feedparser, pandas/openpyxl for the BDDK Excel) + TypeScript/React SPA
- Python full stack (Django templates, Streamlit or Dash): one language, smaller UI control
- Node.js/TypeScript full stack (yahoo-finance2, rss-parser, xlsx); no Python KAP client exists, so KAP must be scraped by hand
- Other (Java/Spring, Go) as the bank's standard stack

_Why it matters:_ Determines every component's stack, the reviewers, the CI/test command and whether the named libraries can be used as-is.

## ARC-data

What is stored, and where? REQ-05-04 talks about 'saving' the form, §1 asks for an audit trail, and REQ-07-02 exports an 'audit trail of overrides'. But no store is named, and historical comparison is out of scope ('Requires data warehouse'). Must an assessment persist so it can be reopened later?

- No persistence: the assessment lives in the browser session; the export (EPIC-07) is the record
- Local file store (JSON/SQLite) per assessment, including fetched values, sources, overrides and sign-offs
- Server database (e.g. PostgreSQL) with a schema and migrations; adds a db component

_Why it matters:_ Changes observable behaviour (whether an assessment can be reopened), the audit capability (NFR-audit) and adds or removes a db component.

## FE-stack

Which web framework, component library, state management, supported browsers and screen sizes should the UI use? The request names none. It only implies a browser UI with tabs (Data Guide), dropdowns, a news panel and coloured field states.

- React + TypeScript (Vite) with a plain CSS or light component library; desktop Chrome/Edge latest; >=1280 px
- Vue + TypeScript
- Server-rendered Python templates / Streamlit (if ARC-stack chooses Python full stack)
- Bank's internal design system, if one exists

_Why it matters:_ Fixes the frontend component stack, its reviewer and the test tooling.

## UX-a11y

What accessibility target applies? None is stated. REQ-05-05 and §4 encode meaning by colour (green/yellow/orange/red WL, green/yellow/white field states), which fails WCAG 1.4.1 unless a text label is added.

- No formal target for an internal single-user POC, but every colour state also carries a text label ('WL2', 'Please confirm', 'Manually adjusted')
- WCAG 2.1 AA (keyboard navigation, focus, contrast, labelled controls)

_Why it matters:_ Adds ACs and test effort to every UI card. A formal target would bring in an a11y specialist role.

## UX-i18n

What UI language and locale formats should the POC use? The request is in English, but users and data span Turkey and Germany (company names with diacritics such as 'ş', 'ğ', 'ü'; news in TR/DE). Date format for Prepared/Checked By and news dates? Number and percent format (110% vs 110,0 %)? Which news language/region does the Google News RSS query use per segment (hl/gl parameters)?

- English UI, ISO dates (YYYY-MM-DD), '.' decimal; news region per segment (TR -> tr-TR, DE -> de-DE, Other -> en-US)
- Localised UI (TR/DE/EN)

_Why it matters:_ Affects display formats, test data and the news query results.

## UX-design

Are there screen designs or mockups? Stated so far: three field states (green + source link / yellow + 'Please confirm' / white + mandatory, §4), override shown with a yellow border and a 'Manually adjusted' tag (REQ-02-09), WL colours (REQ-05-05), a news panel next to SF-5..9 (REQ-04-02), a red minimum-condition alert (REQ-05-02), a summary panel (REQ-05-06), a Data Guide tab (REQ-06-01). Not stated: page layout and navigation, the loading state during the 30 s fetch, the empty news result, the 'original Excel template' layout for export (REQ-07-01, not attached).

- Provide mockups and the original Excel template
- Frontend lead proposes a simple layout from the stated elements; business reviews it at the C1 session

_Why it matters:_ Without the Excel template the REQ-07-01 'layout closely mirrors' criterion cannot be tested.

## NFR-privacy

How should sensitive data be handled? The request does not say. (1) Assessments hold bank-confidential client data (customer number, internal rating, repayment delays, DSC), which falls under banking secrecy. (2) Every fetch sends the client's name or ticker to Google News and Yahoo, which reveals which clients the bank is monitoring. Is that acceptable? (3) Prepared By / Checked By names are personal data (GDPR/KVKK). What are the retention, logging and masking rules (e.g. must logs exclude customer numbers)?

- Accept for a research POC on a local machine; logs exclude customer number and internal data; no retention beyond the session or export
- Use test or dummy clients only until a privacy/security review
- Route outbound queries through a bank proxy; formal DPIA before use with real clients

_Why it matters:_ May restrict which data QA and users can use, what is logged, and whether live fetches for real clients are allowed.

## NFR-audit

What must the audit trail record, and how long must it be kept? §1 says the POC should make an audit trail possible. REQ-02-09 flags overrides with a note, REQ-05-03 requires a justification for a WL override, REQ-05-04 adds Prepared/Checked By with date, and REQ-07-02 exports the 'audit trail of overrides'. Not stated: which fields are recorded (old value, new value, fetched source value, who, timestamp), whether the audit trail persists (ARC-data), and the retention period.

- Per override: field, auto value + source, new value, note, timestamp, 'Prepared By' name; kept with the assessment record and in the export; no retention rule in the POC
- Append-only audit log persisted server-side with a defined retention period (e.g. per bank record-keeping policy)

_Why it matters:_ Shapes the data model and export content (REQ-07-02), and depends on ARC-data.

## DEL-deploy

Where and how does the POC run? Not stated. C1 only says it must not go to production before a business review. Options: the analyst's laptop, an internal server or VM, a container. Since there is no auth (A1), a shared server exposes client data to its whole network. Outbound internet access to KAP, BDDK, Google, Yahoo, Wikipedia etc. must be allowed from wherever it runs.

- Local run on the analyst's machine (one command, e.g. docker compose up or a run script); no deployment pipeline
- Internal VM/container behind the bank network with outbound proxy; requires the network/security sign-off

_Why it matters:_ Affects security exposure, proxy and outbound-access needs, and the run instructions QA uses.

## X-Q1

Q1 (request §8): Soft Factor scoring. Does 1 or more 'Yes' give WL=1 flat, or does the number of 'Yes' answers escalate the WL?

- Flat: any Yes -> WL=1; no Yes -> WL=0
- Escalating, e.g. 1 Yes -> WL1, 2-3 -> WL2, 4+ -> WL3 (thresholds to be given)
- Per-question WL weights from the Excel sheet

_Why it matters:_ Changes scoring engine design and final WL (REQ-05-01). Blocks EPIC-04/05 ACs.

## X-Q2

Q2 (request §8): For the 'Other' segment, which agency is the reference for country rating: Fitch, S&P, or the most conservative of the three?

- Fitch (consistent with Germany/Turkey)
- S&P
- Most conservative of Fitch/S&P/Moody's (needs a Moody's-to-S&P scale mapping)

_Why it matters:_ Affects the country-rating fetch logic and the Ind.12 WL for Other.

## X-Q3

Q3 (request §8): For SF-5..9, does the analyst confirm against the auto-fetched news, or are these always manual? If news is used, what is the minimum number of sources?

- News pre-loaded (top 5 per query), analyst answers (as REQ-04-02 describes); no minimum
- Always manual, with news shown only as reference
- Minimum N distinct sources before a 'suggested' state is shown

_Why it matters:_ Defines the scope of the EPIC-02 news fetcher and the SF-5..9 field state.

## X-Q4

Q4 (request §8): What numeric threshold makes a market-cap deterioration 'significant' (SF-11 pre-suggested 'Yes', REQ-04-03)? Is the boundary inclusive? Is it configurable by whom, and where?

- >20% decline over 12 months (example in Q4); exactly -20.0% -> ?
- Other value
- Config file value, default 20%

_Why it matters:_ Required to auto-suggest SF-11 and to write its boundary tests.

## X-Q5

Q5 (request §8): For private Turkish companies, is the Trade Registry Gazette enough as a source for the auditor's opinion, or must the physical annual report be obtained?

- Gazette is enough; the POC links to it (manual entry)
- Gazette scraped automatically (new fetch scope)
- Annual report required; manual only

_Why it matters:_ Determines whether Ind.5 for private Turkish companies is automated or manual.

## X-Q6

Q6 (request §8): Should the WL override justification be free text or chosen from predefined categories (e.g. 'Temporary event', 'Mitigant in place', 'Management decision')?

- Free text, non-empty (REQ-05-03 as written)
- Category dropdown + optional free text
- Category + mandatory free text

_Why it matters:_ UX and validation of the override flow, and the audit content.

## X-Q7

Q7 (request §8): What is the acceptable age of auto-fetched LCR data (the BDDK bulletin may be 4-6 weeks old)? Must older data be flagged?

- No flag
- Show the 'as of' period on the field always
- Warn when data is older than N days (N to be given)

_Why it matters:_ Drives the data-freshness warning logic on Ind.7/8.

## X-Q8

Q8 (request §8): What is the precise internal definition that separates DSC 'weak' from DSC 'not given'? Is it documented in the KDF Excel?

- Provide the definition text for tooltips
- No tooltip in the POC

_Why it matters:_ Ind.6 tooltip/help text. Also, the WL for 'DSC weak' is unstated (X-wl-mapping).

## X-Q9

Q9 (request §8): Which countries will be added to 'Other' in future phases?

- None planned; keep segments as config so a country can be added without code changes
- List of countries

_Why it matters:_ Informs technical design only. Does not block the POC if segments are data-driven.

## X-wl-mapping

Please provide the complete option -> WL table for all 13 Hard Factor indicators and the Soft Factor answers. Only some values are given in REQ-03-01..03-13, and A4 requires the Excel sheet to be mirrored exactly. Also: is the WL range exactly 0..4 (REQ-05-05 colours WL0..WL4)?

- Attach the Excel dropdown sheet
- Business fills a BA-prepared table (one row per option)

_Why it matters:_ Blocks the scoring engine and REQ-03-14 / REQ-05-01 tests. See PRD-acceptance for the list of missing values.

## X-rating-scale

(a) What is the exact rating scale? REQ-03-10 says 'AAA -> CCC-', i.e. AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- (19 grades). Are CC, C, RD/SD and D excluded, even for sovereign/external ratings? (b) Is a notch change downgrade-positive, and does an upgrade always give WL=0 for Ind.11/12/13? (c) Moody's (Aaa..Caa3, Ind.13 agency selector): map 1:1 by notch position to the S&P/Fitch scale? (d) What WL does B- get in REQ-03-10?

- Business confirms the 19-grade scale, downgrade-only scoring, 1:1 Moody's mapping, and gives the B- WL
- Business supplies its own scale table

_Why it matters:_ Notch arithmetic for Ind.11/12/13 and REQ-06-02, and the minimum-condition alert (REQ-05-02).

## X-notch-example

REQ-06-02's example says 'BBB+ -> BB+ = 2 notch downgrade -> WL=1'. By scale index (BBB+ = 7, BB+ = 10) it is a 3-notch downgrade, which gives WL=2 under REQ-03-11/03-13 ('3+ -> WL=2') and under REQ-03-12 ('2+ notches -> WL=2'). Which is wrong: the example or the rule? Also, which WL table does the notch calculator apply: country (REQ-03-12), internal (REQ-03-11) or external (REQ-03-13)?

- Example is wrong: BBB+ -> BB+ = 3 notches -> WL=2; use BBB+ -> BBB- = 2 notches -> WL=1 (internal/external table)
- Calculator has a rating-type selector and applies the matching table
- The rule tables are wrong (business restates them)

_Why it matters:_ A wrong example would reach dev and QA as a binding AC.

## X-checked-by

REQ-05-03 says the 'Checked By' sign-off is inactive until an override is saved with a justification, but REQ-05-04 makes Checked By mandatory for every save. If no override is made, can the assessment be saved at all?

- Checked By is always enabled; if the user starts an override, it is disabled until the justification is saved
- Checked By is enabled only after an explicit 'WL confirmed' step (override or accept)
- Checked By is mandatory only when an override exists

_Why it matters:_ Decides whether a no-override assessment can be completed (core flow, EPIC-05).

## X-sf-comment

REQ-04-05 makes a comment 'mandatory if Yes', but its AC says a missing comment 'triggers a validation warning on submit'. Is submit blocked, or only warned?

- Blocking: submit refused until every Yes has a comment
- Non-blocking warning: user may submit anyway

_Why it matters:_ Observable submit behaviour and its tests.

## X-news-queries

How should news be queried for SF-5..9? REQ-02-06 runs one company-name query (top 5), but §3B uses distinct queries: company name (SF-5, 6, 9), company + sector (SF-7), company + supplier (SF-8). No sector or supplier field is captured in REQ-01-01. Is it one shared panel or one panel per question? Where do sector and supplier terms come from? What counts as 'recent' (any date, or last 12 months)?

- One company-name query, top 5, shown next to all of SF-5..9 (REQ-02-06 literal)
- Three queries per §3B with new optional 'sector' and 'key suppliers' input fields
- Fixed keyword sets per question appended to the company name (e.g. SF-7 '+ industry downturn')

_Why it matters:_ Changes the input form (new fields), the fetcher and the news panel layout.

## X-marketcap-basis

REQ-02-05 asks for 'current market cap and market cap 12 months ago', but §3B SF-11 names '12-month price history'. yfinance gives current market cap and historical prices, but not historical market cap directly. Should the % change use the price change, or market cap derived as price x current shares outstanding? What are the reference dates (today vs the same calendar day 1 year earlier, or the nearest trading day)?

- % change in closing price, nearest trading day 365 days ago (proxy, stated in the UI)
- Market cap = price x shares outstanding at both dates (share count changes ignored)

_Why it matters:_ Changes the displayed number and the SF-11 suggestion.

## X-fetch-scope

Which automated fetches are in scope for this delivery? §3A/§3B mark several indicators Auto/Partial that no REQ-02 requirement covers: Germany Ind.5 (Bundesanzeiger), Ind.7 (Bundesbank), SF-3/SF-4 (Handelsregister), SF-12 (partial); Turkey SF-3 and SF-4 (KAP disclosures / material events), SF-12 (KAP operating margin, REQ-04-04 Should); Ind.13 for all segments (Reuters/agency pages, best-effort); SF-10 for all segments (yfinance 'bond spread proxy'). Are only the REQ-02-01..09 fetches required (Ind.12; TR bank LCR/FX LCR; TR KAP auditor; market cap; news), or the whole map?

- Must = the REQ-02-0x fetches only; everything else shows a source link and is manual
- Whole automation map, best-effort
- REQ-02-0x plus a named subset

_Why it matters:_ Large scope swing: up to six extra scrapers.

## X-auto-suggest-rules

For Soft Factors that are auto-filled or partially auto-filled (SF-3 auditor changes, SF-4 ownership changes, SF-10 capital market access 'bond spread proxy via stock performance', SF-12 operating profitability), what fetched evidence turns the field into a pre-suggested 'Yes'? Only SF-11 has a rule (Q4).

- No auto-suggestion: show the fetched evidence only, analyst answers
- Rules per question (e.g. SF-3: more than 1 auditor change in 3 years; SF-10: share price -X% vs index; SF-12: operating margin down more than Y pp year over year), values to be given

_Why it matters:_ Defines the 'Pre-filled (suggested)' state for these questions.

## X-bddk-feasibility

REQ-02-03 expects the BDDK monthly bulletin Excel to contain 'the relevant bank's LCR row'. This needs a spike to verify: as far as we know, the BDDK monthly bulletin publishes sector and bank-group aggregates, not per-bank LCR. Per-bank LCR usually appears in each bank's own public disclosures (and possibly on KAP). If per-bank rows do not exist, what is acceptable?

- Spike first; if there are no per-bank rows, Ind.7/8 become manual with a source link
- Use the bank's own quarterly public disclosure (scrape, per bank)
- Show the sector LCR as reference only

_Why it matters:_ May make a Must requirement (REQ-02-03, REQ-03-07/08 pre-fill) infeasible as written.

## X-scraping-tos

A7/A8 cover only Yahoo and Google News. Are the terms of use and robots rules for Bundesanzeiger, Handelsregister, KAP, countryeconomy.com, Wikipedia and Reuters public pages acceptable for automated retrieval by the bank? Some of these (to be verified) restrict automated access or use CAPTCHAs.

- Legal/compliance clears each source before it is automated; uncleared sources stay manual with a link
- Accept for a research POC under C1, documented per source

_Why it matters:_ May move sources from auto to manual (X-fetch-scope).

## X-other-country

For the 'Other' segment, Ind.12 needs a specific country's sovereign rating, but REQ-01-01 captures only the segment, not the country. Add a country field for 'Other'? For Germany/Turkey, is the country implied by the segment?

- Add a mandatory country selector (ISO 3166) when segment = Other; Germany/Turkey implied
- Ind.12 manual for Other

_Why it matters:_ Changes the setup form contract (REQ-01-01 five fields) and the Ind.12 fetch for Other.

## X-override-range

What are the rules for a final WL override (REQ-05-03)? Allowed values (0..4)? Up and down? Does it change the minimum-condition alert (REQ-05-02) or the summary 'driver' (REQ-05-06)? Is there one override per assessment, or can it be edited (audit)?

- Any 0..4, up or down; the alert stays visible; the summary shows calculated and overridden WL side by side
- Downgrade of the calculated WL is not allowed (only escalate)

_Why it matters:_ Business rule on the core output.

## X-delivery-cut

Which MoSCoW levels ship in THIS delivery? Should items: REQ-01-04, REQ-04-04, REQ-04-05, REQ-05-05, REQ-05-06, EPIC-06 (Data Guide + notch calculator). Could items: EPIC-07 PDF/Excel export (REQ-07-01 says 'PDF or Excel', so which?).

- Must only
- Must + Should
- Must + Should + Could (Excel export only / PDF only / both)

_Why it matters:_ Defines the card set and the plan's scope.

## X-success-criteria

What will the business unit review (C1) use to judge the POC a success? No measure is stated beyond the 30 s fetch and the auto vs manual count.

- E.g. at least N% of fields auto-filled per segment on a sample of test clients; WL equals the Excel result on M reference cases
- No formal criteria; qualitative review

_Why it matters:_ Could add a reference-case test set (Excel vs tool) to the acceptance.

## X-hidden-fields

Are hidden or inactive items (FX LCR outside Turkey + Bank; LCR for Corporates; SF-11 for Private; Ind.2/3 when Ind.1 = No) excluded from 'all questions answered' (REQ-04-01), from the auto vs manual count (REQ-05-06) and from the max rule (REQ-05-01)? When a setup field changes after values were entered (e.g. Bank -> Corporate), are the hidden values cleared?

- Excluded everywhere and cleared on hide
- Excluded but retained (restored when shown again)

_Why it matters:_ Observable validation and WL results on segment/type changes.
