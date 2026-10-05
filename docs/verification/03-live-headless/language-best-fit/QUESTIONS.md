# Questions before the work can start — JOB-20261005-1537-watchlist-credit-monitoring-poc

Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"

## PRD-acceptance

The register's acceptance summaries cannot be tested for every option. Many dropdown values have no stated WL (X-wl-mapping), the Soft Factor WL is undefined (X-q1-soft-wl), and the REQ-06-02 example is arithmetically wrong (X-notch-rules). A4 says scoring 'mirrors exactly the Excel dropdown sheet', but that sheet is not attached, and neither is the 'original Excel template' REQ-07-01 refers to. Will the business provide the Excel dropdown sheet (and the template) as the acceptance baseline, or confirm the values proposed in the linked X- items?

- Provide the Excel dropdown sheet + template; the BA derives every AC from it (recommended)
- Confirm the proposed values item by item in X-wl-mapping, X-q1-soft-wl and X-notch-rules
- Build only the explicitly stated WL values; unstated options give WL=0 (not recommended: breaks A4)

_Why it matters:_ Without it, QA cannot check the WL of about 15 dropdown options, and the scoring engine (the core of EPIC-05) may not match the Excel it must mirror (A4).

## PRD-conflicts

These points in the request contradict each other: (1) REQ-05-03 makes 'Checked By' inactive until an override is saved, but REQ-05-04 requires Checked By for every save, so an assessment without an override can never be saved -> X-checked-by. (2) REQ-06-02 example 'BBB+ -> BB+ = 2 notch downgrade -> WL=1': BBB+ -> BBB -> BBB- -> BB+ is 3 notches, and 3 notches give WL=2 under both the Ind. 11/13 rule and the Ind. 12 rule -> X-notch-rules. (3) The REQ-05-01 example 'Any indicator producing WL=3 results in final WL=3' contradicts its own max rule when another indicator gives WL=4 (Ind. 2 '>90 days', Ind. 6 'DSC not given'). Assumed: the max rule wins (final WL is at least 3, and 4 if any indicator gives 4). (4) REQ-02-06 searches news by 'company name' only, but §3B wants 'company + sector' (SF-7) and 'company + supplier' (SF-8) queries, and EPIC-01 captures no sector or supplier -> X-news. (5) §3A/§3B mark SF-3, SF-4, SF-10 and the German Bundesanzeiger/Handelsregister/Bundesbank sources as Auto/Partial, but EPIC-02 has no requirement for them, while REQ-02-01 says 'all automatable indicators' -> X-autofetch-scope. (6) §3A marks Ind. 7 LCR for Turkey as Auto (all banks), but REQ-02-03 says 'For Turkish listed banks' -> X-autofetch-scope. (7) REQ-04-05 makes the comment 'mandatory if Yes', but its acceptance summary only gives a 'validation warning on submit' -> X-sf-comment. (8) REQ-04-01 says 'All questions must be answered', but REQ-04-06 hides SF-11 for Private. Assumed: only visible questions are required. (9) REQ-01-04 (Should) and REQ-04-06 (Must) both hide SF-11 for Private. Assumed: hiding SF-11 is Must, and the auditor-guidance change is Should. (10) §4 calls fields 'Pre-filled (locked)' but also 'editable if analyst disagrees' (also A3, REQ-02-09). Assumed: 'locked' is only a label; the field stays editable, and an edit sets the 'Manually adjusted' flag. (11) REQ-02-05 uses 'market cap ... 12 months ago', but §3B SF-11 uses '12-month price history' -> X-q4-marketcap. Please confirm the assumed resolutions for 3, 8, 9 and 10. The other points are asked in their X- items.

- Confirm the assumed resolutions for 3, 8, 9 and 10, and answer the linked X- items
- Give a different resolution per point

_Why it matters:_ Every point changes observable behaviour or a test expectation. As written, (1) blocks saving any assessment that has no override.

## CON-errors

The request decides these: an assessment cannot start unless the five REQ-01-01 fields are set; a failed fetch falls back to manual input with a clear error and does not block the form (REQ-02-08); every visible SF question must be answered before submit (REQ-04-01); an override needs a non-empty justification (REQ-05-03); Prepared By/Checked By name+date are required to save (REQ-05-04). Not decided: (a) A source is still running when the 30 s budget of REQ-02-01 ends: is it shown as failed/manual, or filled in later while the analyst works? (b) A Listed company has no ticker, or the ticker is unknown: block creation, or treat it as a fetch failure for yfinance/KAP? (c) Hard Factor input is inconsistent, e.g. Ind. 1 = Yes with Ind. 2 = 'no delay': allow it or reject it? Error wording and HTTP codes (422 for validation recommended) are pm details.

- (a) Timeout = failure -> manual input with message 'source did not respond in time' (recommended) | late fill-in
- (b) Treat as a fetch failure; the form still opens (recommended) | block creation
- (c) Allow and score as entered (recommended) | reject with a validation error

_Why it matters:_ Observable behaviour on the error paths, and QA's expected results for them.

## ARC-data

Must assessments be persisted, and can they be re-opened? The request implies saving ('Form cannot be saved without both fields populated' REQ-05-04; 'until override is saved' REQ-05-03; the audit trail of §1 and REQ-07-02) but names no store, and §6 excludes historical comparison. Store, schema and migrations become pm details once this is answered.

- Persist each assessment in a local SQLite file: inputs, fetched values with source + timestamp, overrides + notes, WL override + justification, sign-offs, final WL. Saved assessments can be listed and re-opened read-only (recommended)
- No persistence: the assessment lives in the browser session, and the only record is the export (EPIC-07, which is only Could)
- Persist drafts and completed assessments, both editable

_Why it matters:_ Changes observable behaviour (save, list, re-open), the audit trail (NFR-audit) and whether a database component exists.

## UX-a11y

The request sets no accessibility target, yet it carries meaning through colour: field states green/yellow/white (§4) and the WL traffic light (REQ-05-05). Is there an accessibility requirement for this internal POC? Note: deciding a formal target such as WCAG 2.1 AA puts an a11y role on the job.

- No formal target for the POC, but colour is never the only signal: every state also shows text (WL number, 'Please confirm', 'Manually adjusted', source name), and everything is keyboard-usable (recommended)
- WCAG 2.1 AA (adds the a11y role and review)

_Why it matters:_ Scope of UI work and review, and whether an a11y specialist joins the job.

## UX-i18n

The request is in English but names no UI language or locale formats. The users and sources are Turkish and German. Which UI language, and which date/number formats? News headlines would appear in the source's language.

- English UI, ISO dates (YYYY-MM-DD), '.' as decimal separator, % to 1 decimal, no RTL (recommended)
- English UI with locale formats per segment (DD.MM.YYYY, ',' as decimal separator for DE/TR)
- Turkish and/or German UI

_Why it matters:_ Visible text and formats on every screen and in the export, and the test expectations for displayed values.

## NFR-privacy

The request is silent on data protection. (a) Will the POC be run on real customer data or on test/public companies only? Real data includes customer number, internal rating, DSC and payment delays, which are bank-confidential and subject to banking secrecy. Prepared By/Checked By names are personal data (GDPR/KVKK). (b) The tool sends the customer name (and ticker) to Google News, Yahoo Finance, KAP and the scraped sites, so third-party logs will hold the names of the bank's clients. Is that acceptable? (c) May application logs contain customer names/numbers, and how long are stored assessments kept?

- Test/public-company data only during the POC; no masking; logs carry the assessment id but not the customer number; no retention rule (recommended for a POC)
- Real customer data: needs a data-protection/infosec sign-off, log masking of customer number and names, and a retention period
- Real data, but external queries only for Listed companies (public names)

_Why it matters:_ Changes what may be logged and stored, whether queries to external sites are allowed for private companies, and may require an infosec review before use.

## NFR-audit

In-form audit signals are decided: the 'Manually adjusted' flag + note on overridden fetched values (REQ-02-09), the WL override justification (REQ-05-03), Prepared By/Checked By names + dates (REQ-05-04), and the override audit trail in the export (REQ-07-02, Could). Not decided: must the POC keep a persistent, timestamped change log (typed name, field, old -> new, source value, time), and for how long? §1 cites 'no audit trail can be established' as a reason for the POC.

- Store each saved assessment with its fetched values (source + fetch time), overrides (old/new/note/time), WL override (justification/time) and sign-offs; no separate event log; retention = as long as the POC database exists (recommended; needs ARC-data option 1)
- Full append-only event log of every change
- Only what is on the form at save time

_Why it matters:_ Data model, persistence scope and what the export can show.

## X-wl-mapping

Which WL does each dropdown option give where the request states none (A4 says it 'mirrors exactly the Excel dropdown sheet', which is not attached)? Missing values, with the BA's proposal in brackets for confirmation: Ind. 1 'Yes' on its own (no own WL; severity comes from Ind. 2/3, plus the REQ-05-02 alert); Ind. 2 'no delay' (0) and '<=3 days' (? 0 or 1); Ind. 3 '0' (0); Ind. 4 'On schedule' (0) and '1st reminder' (? 0 or 1); Ind. 5 full option list and the WL of the clean opinion (Unqualified = 0?); Ind. 6 'DSC given' (0) and 'DSC weak' (? 1, 2 or 3); Ind. 7 '>=110%' (0); Ind. 8 FX LCR '<90%' (NO WL stated at all; ? 2 like LCR) and '>=90%' (0); Ind. 9 'No' (0) and 'Yes - without forbearance' (? 1 or 2); Ind. 10 'B-' (unmapped: REQ-03-10 gives B -> 1 and CCC+ and below -> 2; ? 1 or 2); Ind. 11 'same/upgrade' (0) and '1 notch' (0?); Ind. 12 0 notches/upgrade (0); Ind. 13 '1 notch' downgrade and upgrade (0?). Also confirm that hidden indicators (FX LCR outside Turkey+Bank, LCR for Corporates, SF-11 for Private, Ind. 2/3 when Ind. 1 = No) take no part in the max.

- Provide the Excel dropdown sheet (recommended)
- Confirm or correct the bracketed proposals

_Why it matters:_ Core scoring engine (REQ-03-xx, REQ-05-01). Every unmapped option is an untestable AC and may yield a wrong final WL.

## X-q1-soft-wl

Section 8 Q1: what WL does the Soft Factor section produce? The request never defines it, but REQ-05-01 puts Soft Factor WL values into the max rule. Is it 1 or more 'Yes' = WL1 flat, or does the WL rise with the number of 'Yes' answers (if so, give the bands, e.g. 1-2 Yes = WL1, 3+ = WL2)? Is the WL shown per question or only for the section?

- Any Yes -> Soft Factor WL=1; no Yes -> 0 (flat)
- Escalating by number of Yes answers (business gives the bands)
- Per-question WL values (business gives them)

_Why it matters:_ Changes the scoring engine design (as Q1 itself says) and every final-WL acceptance test that involves Soft Factors.

## X-notch-rules

Rating notch rules are inconsistent or incomplete. (a) REQ-06-02 example 'BBB+ -> BB+ = 2 notch downgrade -> WL=1' is wrong arithmetically. On the scale AAA=0 ... BBB+=7, BBB=8, BBB-=9, BB+=10, BBB+ -> BB+ is 3 notches. Is the intended example 'BBB+ -> BBB- = 2 notches -> WL=1' (Ind. 11/13 rule) or 'BBB+ -> BB+ = 3 notches -> WL=2'? (b) Which rule does the notch calculator apply to get the WL: Ind. 12 country (1 -> WL1, 2+ -> WL2) or Ind. 11/13 (2 -> WL1, 3+ -> WL2)? (c) Confirm that Ind. 12 is deliberately stricter than Ind. 11/13. (d) Do upgrades and no change give WL=0 for Ind. 11, 12 and 13? (e) Scale coverage: S&P/Fitch AAA..CCC- plus CC, C, RD/SD, D for sovereigns; Moody's equivalents Aaa=AAA, Aa1=AA+ ... Caa3=CCC-, Ca, C. What WL applies on a move into default, or when the rating is withdrawn / not rated? (f) Is '12 months prior' the rating in force on the assessment date minus 12 months?

- Analyst chooses the indicator rule in the calculator; corrected example 'BBB+ -> BBB- = 2 notches -> WL=1 (external)'; upgrades = 0; standard S&P/Fitch/Moody's equivalence; default/withdrawn -> manual input (BA proposal)
- Business gives the rules

_Why it matters:_ Ind. 11/12/13 scoring, the notch calculator (REQ-06-02) and its acceptance test.

## X-q2-other-country-rating

Section 8 Q2: for the 'Other' segment, which agency is the reference for the country rating (Ind. 12): Fitch, S&P, or the most conservative of the three? If 'most conservative', is that the lowest current rating or the largest 12-month downgrade? (Germany and Turkey are Fitch per REQ-02-02.)

- Fitch, as for Germany/Turkey (simplest; one scraper)
- S&P
- Most conservative of S&P/Moody's/Fitch: three scrapes and a rule for picking

_Why it matters:_ Country-rating fetch logic and Ind. 12 results for every 'Other' customer.

## X-input-fields

Gaps in the EPIC-01 input contract: (a) 'Other' means every country outside DE/TR, but REQ-01-01 captures no country, while Ind. 12 country rating, the news locale and the Data Guide need it. Add a mandatory 'country' field (ISO 3166) when segment = Other? That changes REQ-01-01's 'all five fields'. (b) For a Listed company, is the ticker mandatory or optional (REQ-01-02 only says 'available')? (c) Ticker format: one field feeds both yfinance and KAP. Does the analyst enter the exchange code (e.g. 'AKBNK') and the system add the Yahoo suffix ('.IS' Turkey, '.DE' Germany), or enter the Yahoo symbol itself? (d) Customer number: any format rule?

- (a) add mandatory country for Other (recommended); (b) ticker mandatory when Listed (recommended); (c) exchange code + suffix per segment, Yahoo symbol as entered for Other (recommended); (d) any non-empty text
- Keep five fields only: Other uses no country rating (Ind. 12 manual)

_Why it matters:_ Public input contract, the Ind. 12 fetch for Other, and every fetch keyed on the ticker.

## X-checked-by

REQ-05-03 says ''Checked By' sign-off field is inactive until override is saved with non-empty justification', and REQ-05-04 says the form 'cannot be saved without both fields populated'. Read literally, an assessment with no override can never be saved. What is intended?

- Checked By is always required; it is inactive only while an override is being edited and not yet saved (recommended)
- Checked By is required, and activated, only when an override exists; otherwise optional
- Checked By is always active; the override only needs a justification

_Why it matters:_ Save/submit behaviour of every assessment; blocking as written.

## X-override

Override details: (a) Section 8 Q6: is the WL override justification free text, or predefined categories (e.g. 'Temporary event', 'Mitigant in place', 'Management decision') plus text? (b) May the override set any WL 0-4, both up and down? (c) Are the calculated WL and the overridden WL both kept and shown? (d) REQ-02-09 says an overridden fetched value is 'flagged with a note'. Must the analyst type a note (mandatory), or is the 'Manually adjusted' tag enough?

- (a) free text, mandatory non-empty (recommended for the POC; categories later); (b) any 0-4; (c) both shown; (d) note mandatory
- (a) category + free text
- Business specifies

_Why it matters:_ Override UX and data model, validation rules and the audit trail.

## X-autofetch-scope

Which §3 automation cells does this delivery build? Explicit fetch requirements exist for Ind. 12 country rating (REQ-02-02), Ind. 7/8 BDDK for Turkish listed banks (REQ-02-03), Ind. 5 KAP auditor opinion for Turkish listed companies (REQ-02-04), SF-11 market cap (REQ-02-05), SF-5..9 news (REQ-02-06), Ind. 13 best-effort (REQ-03-13) and SF-12 KAP margin (REQ-04-04, Should). The §3 map also marks as Auto/Partial, with no requirement: SF-3 auditor changes (KAP), SF-4 ownership changes (KAP MDD / Handelsregister), SF-10 capital-market access ('bond spread proxy via stock performance': no metric or threshold given), and the German partial sources for Ind. 5 (Bundesanzeiger), Ind. 7 (Bundesbank) and SF-12. Also: Ind. 7 LCR for non-listed Turkish banks (§3A 'Auto' vs REQ-02-03 'listed').

- Build only the explicit REQ fetchers; the other cells are manual inputs with a source link from the Data Guide (recommended for the POC)
- Build everything marked Auto/Partial in §3 (roughly doubles fetcher work, and adds the riskiest scrapers: Bundesanzeiger CAPTCHA, Handelsregister limits)
- Explicit REQs plus SF-3/SF-4 from KAP only

_Why it matters:_ Fetcher scope (the largest effort in the POC), the auto vs manual count of REQ-05-06, and test scope.

## X-bddk-lcr

REQ-02-03 expects 'the relevant bank's LCR row' from the BDDK monthly bulletin. The BA's understanding, which needs a feasibility spike to confirm, is that the BDDK monthly bulletin publishes sector and bank-group aggregates, not per-bank LCR/FX LCR. Per-bank LCR is usually in each bank's own quarterly public disclosures. If per-bank rows are not in the bulletin, what should the POC do?

- Spike first; if there is no per-bank row, Ind. 7/8 are manual with a source link (REQ-02-08 fallback) (recommended)
- Fetch the per-bank LCR from the bank's quarterly disclosure on KAP instead
- Show the sector-level LCR as reference only, never as the bank's value

_Why it matters:_ Whether REQ-02-03 can be met as written; Turkey-bank automation and its acceptance test.

## X-q7-lcr-age

Section 8 Q7: the BDDK bulletin may be 4-6 weeks old. Is any age acceptable, or must old LCR/FX LCR data be flagged? If flagged, after how many days, and how (warning label vs not pre-filling)?

- Always show the reporting period ('as of YYYY-MM'); no warning (simplest)
- Show the period and a warning when older than N days (business gives N, e.g. 45)
- Do not pre-fill when older than N days

_Why it matters:_ Data-freshness logic and the UI warning state for Ind. 7/8.

## X-news

News fetch details (REQ-02-06, REQ-04-02, §3B note, Q3): (a) SF-7 needs a 'company + sector' query and SF-8 a 'company + supplier' query, but no sector or supplier is captured. Add optional sector/supplier inputs, or use the company name for all of SF-5..9 as REQ-02-06 says? (b) One shared top-5 panel for SF-5..9, or a top 5 per question/query? (c) Q3 remainder: is a minimum number of sources required before the analyst may answer Yes? (d) Google News language/region per segment (Turkey tr/TR, Germany de/DE, Other en/US?) (e) Time window: only articles from the last 12 months?

- (a) company name only for all, as REQ-02-06; (b) one shared panel of the 5 most recent; (c) no minimum; (d) per-segment locale; (e) last 12 months (BA proposal)
- (a) add optional sector + supplier fields; (b) top 5 per question

_Why it matters:_ News fetcher scope, the input contract and the news panel layout.

## X-q4-marketcap

Section 8 Q4 + REQ-04-03: (a) What is the threshold for 'significant market cap deterioration' (example given: >20% decline over 12 months)? (b) Is the comparison strict: is a decline of exactly 20% Yes or No? (c) Is the measure market cap (price x shares, REQ-02-05) or the 12-month price change (§3B SF-11)? (d) The request says the threshold is 'configurable'. Is a config-file value enough, or is a UI setting needed?

- (a) 20% (b) decline strictly greater than the threshold -> suggest Yes (c) market cap via yfinance, falling back to price change if shares history is missing (d) config file (BA proposal)
- Business gives the values

_Why it matters:_ The SF-11 auto-suggestion and its acceptance test; the yfinance data used.

## X-sf-comment

REQ-04-05 makes the comment 'mandatory if "Yes" is selected', but its acceptance summary only says a missing comment 'triggers a validation warning on submit'. Does a Yes without a comment block submission, or only warn?

- Block submission until a comment is entered (mandatory)
- Warn and still allow submission

_Why it matters:_ Validation behaviour and the acceptance test of REQ-04-05.

## X-q8-dsc

Section 8 Q8: what is the internal definition separating 'DSC weak' from 'DSC not given' (for the tooltip/help text)? Is it documented in the KDF Excel? Non-blocking: the WL of 'DSC weak' is asked in X-wl-mapping, and the tooltip can ship as a placeholder.

- Business supplies the definition text
- Ship without a tooltip

_Why it matters:_ Help text only.

## X-delivery-cut

Do the Should and Could items ship in this delivery? Should: EPIC-06 Data Guide + notch calculator, REQ-01-04, REQ-04-04, REQ-04-05, REQ-05-05, REQ-05-06. Could: EPIC-07 PDF/Excel export, whose layout must 'closely mirror the original Excel template', which is not provided.

- Must + Should; EPIC-07 deferred (recommended)
- Everything, including EPIC-07 (needs the Excel template; PDF and Excel are two exporters)
- Must only

_Why it matters:_ Delivery scope and the number of cards.
