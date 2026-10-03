# POC Requirements — Corporate Client Credit Monitoring (Watchlist) Tool

> ⚠️ *Draft — pending review by business unit and technical team. Not yet baselined.*

**Version:** 0.2 | **Date:** May 2026 | **Project Type:** 🟢 Small (POC)
**Author:** BA/PO Hybrid | **Status:** Elicitation Draft — Ready for Business Unit Review

---

## 1. Problem Statement

Currently, the credit monitoring process for corporate clients (Hard Factor + Soft Factor analysis) is carried out manually using Excel files. This requires data to be gathered separately from multiple sources, calculations to be repeated for each assessment, and the Watchlist level to be determined subjectively — introducing risk of error, inconsistency, and significant time loss.

The desired future state is that an analyst enters the customer identifier and segment, the system automatically fetches all available external data from public sources, pre-fills the assessment form, and the analyst only needs to supply data that is unavailable externally (internal system data). The system then calculates the Watchlist level automatically.

Without this POC, the manual process will continue, scaling will be impossible, and no audit trail can be established.

---

## 2. Scope — Country Segmentation

The POC operates across three segments. The segment drives which indicators are active and which external data sources are used.

| Segment | Scope | Key Differences |
|---|---|---|
| **🇩🇪 Germany** | German corporate clients | Auditor's opinion → Bundesanzeiger / HGB; Country rating Fitch AAA (stable, rarely triggers); LCR → BaFin / Bundesbank |
| **🇹🇷 Turkey** | Turkish corporate clients (banks + corporates) | FX LCR indicator **active in this segment only**; Auditor's opinion → KAP (listed) / Trade Registry Gazette (private); LCR & FX LCR → BDDK monthly bulletin; Country rating → Fitch (volatile) |
| **🌍 Other** | All countries outside Germany and Turkey | Auditor's opinion → Company annual report (source varies by country); FX LCR indicator **disabled**; External rating → S&P / Moody's / Fitch |

---

## 3. Data Automation Map

This is the core of the POC goal: **maximise automation of external data collection using free, publicly accessible sources — no licensed APIs.**

### Automation Legend
| Symbol | Meaning |
|---|---|
| ✅ Auto | Fetched automatically — analyst does not need to research this |
| ⚠️ Partial | Fetched automatically for listed companies; manual for private |
| ❌ Manual | Always requires analyst input — internal system data or no public source |

---

### 3A. Hard Factor Indicators — Automation by Segment

| # | Indicator | 🇩🇪 Germany | 🇹🇷 Turkey | 🌍 Other | Public Source | Technical Method |
|---|---|---|---|---|---|---|
| 1 | Repayment delay (yes/no) | ❌ Manual | ❌ Manual | ❌ Manual | CBS (internal) | — |
| 2 | Number of days with delay | ❌ Manual | ❌ Manual | ❌ Manual | CBS (internal) | — |
| 3 | Number of delays in last 12 months | ❌ Manual | ❌ Manual | ❌ Manual | CBS (internal) | — |
| 4 | Disclosure deadline | ❌ Manual | ❌ Manual | ❌ Manual | Loan documentation (internal) | — |
| 5 | Auditor's opinion | ⚠️ Partial | ✅ Auto (listed) | ❌ Manual | 🇹🇷 KAP (kap.org.tr) / 🇩🇪 Bundesanzeiger | Python KAP client / web scrape |
| 6 | Debt Service Capacity (DSC) | ❌ Manual | ❌ Manual | ❌ Manual | IBM ART / KDF (internal) | — |
| 7 | LCR Ratio *(banks only)* | ⚠️ Partial | ✅ Auto | ❌ Manual | 🇹🇷 BDDK monthly bulletin / 🇩🇪 Bundesbank | Public Excel download / web scrape |
| 8 | FX LCR *(Turkey + Bank only)* | N/A | ✅ Auto | N/A | BDDK monthly bulletin (bddk.org.tr) | Public Excel download |
| 9 | Material waiver / amendment | ❌ Manual | ❌ Manual | ❌ Manual | Loan documentation (internal) | — |
| 10 | Internal rating (current) | ❌ Manual | ❌ Manual | ❌ Manual | IBM ART (internal) | — |
| 11 | Internal rating change (12 months) | ❌ Manual | ❌ Manual | ❌ Manual | IBM ART (internal) | — |
| 12 | Country rating change (12 months) | ✅ Auto | ✅ Auto | ✅ Auto | Wikipedia sovereign ratings / countryeconomy.com | Web scrape (no API key) |
| 13 | External rating change (12 months) | ⚠️ Partial | ⚠️ Partial | ⚠️ Partial | Reuters public pages / rating agency websites | Web scrape (best-effort) |

> **Note on Ind. 13:** Corporate-level external ratings from S&P, Moody's, and Fitch are largely behind paywalls. The POC will attempt to scrape publicly accessible pages; where data is unavailable, the field remains open for manual input with a source link provided.

---

### 3B. Soft Factor Indicators — Automation by Segment

| # | Category | Question | 🇩🇪 Germany | 🇹🇷 Turkey | 🌍 Other | Public Source | Technical Method |
|---|---|---|---|---|---|---|---|
| 1 | Info & Reporting | Incorrect / contradictory information provided? | ❌ Manual | ❌ Manual | ❌ Manual | Analyst observation | — |
| 2 | Info & Reporting | Declining willingness to provide information? | ❌ Manual | ❌ Manual | ❌ Manual | Analyst observation | — |
| 3 | Info & Reporting | Frequent auditor / advisor changes? | ⚠️ Partial | ✅ Auto (listed) | ❌ Manual | 🇹🇷 KAP disclosures | Python KAP client |
| 4 | Management | Extraordinary ownership structure changes? | ⚠️ Partial | ✅ Auto (listed) | ❌ Manual | 🇹🇷 KAP material events (MDD) / 🇩🇪 Handelsregister | Python KAP client / web scrape |
| 5 | Management | Drastic strategy changes in last 12 months? | ✅ Auto | ✅ Auto | ✅ Auto | Google News RSS (company name query) | RSS feed, no API key |
| 6 | Management | Publicly known internal problems? | ✅ Auto | ✅ Auto | ✅ Auto | Google News RSS (company name query) | RSS feed, no API key |
| 7 | External | Suffering from industry development? | ✅ Auto | ✅ Auto | ✅ Auto | Google News RSS (company + sector query) | RSS feed, no API key |
| 8 | External | Major suppliers/customers in financial difficulty? | ✅ Auto | ✅ Auto | ✅ Auto | Google News RSS (company + supplier query) | RSS feed, no API key |
| 9 | External | Other negative information? | ✅ Auto | ✅ Auto | ✅ Auto | Google News RSS (company name query) | RSS feed, no API key |
| 10 | External | Deterioration in capital market access? | ⚠️ Partial | ⚠️ Partial | ⚠️ Partial | Yahoo Finance (bond spread proxy via stock performance) | yfinance (free library) |
| 11 | External | Significant market cap deterioration? *(listed only)* | ✅ Auto | ✅ Auto | ✅ Auto | Yahoo Finance (12-month price history) | yfinance (free library) |
| 12 | Internal | Significant deterioration in operating profitability? | ⚠️ Partial | ✅ Auto (listed) | ❌ Manual | 🇹🇷 KAP financial reports | Python KAP client |

> **Note on News (SF-5 to SF-9):** Google News RSS returns headlines and article snippets. The system will surface the top 5 most recent news items per query for the analyst to review and confirm Yes/No. It does not auto-answer these questions — the analyst makes the final call with news evidence pre-loaded.

---

## 4. System Behaviour — Auto-fetch Flow

When the analyst opens a new assessment and enters the customer name, ticker (if listed), and selects the country segment, the system triggers an automated data fetch. The form then displays one of three states per field:

| Field State | Meaning | Visual |
|---|---|---|
| **Pre-filled (locked)** | Fetched automatically, source shown, editable if analyst disagrees | Green background, source link |
| **Pre-filled (suggested)** | News / partial data found, analyst must confirm | Yellow background, "Please confirm" label |
| **Empty (manual required)** | Internal data or no public source available | White background, mandatory input |

---

## 5. Requirements Register

### Epic Structure

| Epic ID | Epic Name | Description | MoSCoW |
|---|---|---|---|
| EPIC-01 | Customer & Segment Setup | Customer record, country segment, customer type, listed/private flag | Must |
| EPIC-02 | Automated Data Fetcher | Background fetch of all automatable external data on assessment creation | Must |
| EPIC-03 | Hard Factor Assessment Form | Entry / review of all 13 indicators with pre-filled values and WL calculation | Must |
| EPIC-04 | Soft Factor Assessment Form | News-assisted 12-question form with pre-loaded evidence | Must |
| EPIC-05 | Watchlist Level Calculation & Override | Max-rule aggregation, minimum condition alerts, override with justification | Must |
| EPIC-06 | Data Guide & Source Links | Static reference page with country-specific source URLs per indicator | Should |
| EPIC-07 | Reporting & Export | Assessment summary export (PDF / Excel) | Could |

---

### EPIC-01: Customer & Segment Setup

| Req ID | Requirement | Type | Priority | Acceptance Criteria (summary) |
|---|---|---|---|---|
| REQ-01-01 | System shall accept: customer name, customer number, country segment (Germany / Turkey / Other), customer type (Bank / Corporate), and listed flag (Listed / Private) | FR | Must | Assessment cannot be initiated unless all five fields are populated |
| REQ-01-02 | For listed companies, a stock ticker field shall be available (used to trigger yfinance and KAP data fetch) | FR | Must | Ticker field shown only when "Listed" is selected |
| REQ-01-03 | Country segment selection shall automatically activate or deactivate relevant indicators (FX LCR, LCR, source links) | FR | Must | Selecting Germany hides FX LCR; selecting Turkey + Bank shows both LCR and FX LCR |
| REQ-01-04 | Selecting "Private" shall hide market capitalisation question (SF-11) and change auditor source guidance | FR | Should | Private company selection hides SF-11 |

---

### EPIC-02: Automated Data Fetcher

| Req ID | Requirement | Type | Priority | Acceptance Criteria (summary) |
|---|---|---|---|---|
| REQ-02-01 | On assessment creation, the system shall automatically trigger data fetches for all automatable indicators in the background | FR | Must | Fetch completes within 30 seconds; form becomes available with pre-filled fields |
| REQ-02-02 | Country sovereign rating (Ind. 12) shall be fetched from a public source and compared against the rating 12 months prior; notch change shall be calculated automatically | FR | Must | Germany → Fitch AAA shown; Turkey → current Fitch sovereign rating shown with 12-month delta |
| REQ-02-03 | For Turkish listed banks, LCR and FX LCR shall be fetched from the BDDK monthly bulletin (publicly downloadable Excel) | FR | Must | System retrieves the latest published BDDK file and extracts the relevant bank's LCR row |
| REQ-02-04 | For Turkish listed corporates / banks, auditor name and opinion type shall be fetched from KAP | FR | Must | Fetches the most recent annual audit report disclosure from KAP; extracts auditor opinion classification |
| REQ-02-05 | For listed companies, 12-month market cap change shall be fetched via Yahoo Finance (yfinance); percentage change shall be calculated | FR | Must | System retrieves current market cap and market cap 12 months ago; % change displayed |
| REQ-02-06 | For all companies, a news search (Google News RSS) shall be triggered using the company name; top 5 recent articles shall be surfaced for Soft Factor questions 5–9 | FR | Must | News results shown in a panel next to questions 5–9 for analyst review |
| REQ-02-07 | Each pre-filled field shall display its data source name and a link to the original source | FR | Must | Clicking the source link opens the original public page in a new tab |
| REQ-02-08 | If a fetch fails (source unavailable, company not found), the field shall fall back to manual input with a clear error message | FR | Must | Partial fetch failure does not block the rest of the form from loading |
| REQ-02-09 | The analyst shall be able to override any auto-fetched value; overrides shall be flagged with a note | FR | Must | Overridden fields shown with a yellow border and "Manually adjusted" tag |

---

### EPIC-03: Hard Factor Assessment Form

| Req ID | Requirement | Type | Priority | Acceptance Criteria (summary) |
|---|---|---|---|---|
| REQ-03-01 | Indicator 1 (Repayment delay): Yes/No; selecting "Yes" expands indicators 2 and 3 | FR | Must | "No" collapses ind. 2–3 and produces WL=0 for both |
| REQ-03-02 | Indicator 2 (Days with delay): Dropdown → no delay / ≤3 days / >3 days / >60 days / >90 days | FR | Must | >3 days → WL=2; >60 days → WL=3; >90 days → WL=4 |
| REQ-03-03 | Indicator 3 (Delays in 12 months): Dropdown → 0 / 1 / >1 | FR | Must | 1 → WL=1; >1 → WL=2 |
| REQ-03-04 | Indicator 4 (Disclosure deadline): On schedule / 1st reminder / 2nd reminder | FR | Must | 2nd reminder → WL=2 |
| REQ-03-05 | Indicator 5 (Auditor's opinion): Pre-filled where automatable; dropdown editable | FR | Must | Qualified → WL=1; Adverse / Disclaimer → WL=2 |
| REQ-03-06 | Indicator 6 (DSC): Dropdown → DSC given / DSC weak / DSC not given | FR | Must | DSC not given → WL=4 |
| REQ-03-07 | Indicator 7 (LCR): Shown for Banks only; pre-filled for Turkey from BDDK; ≥110% / <110% | FR | Must | <110% → WL=2 |
| REQ-03-08 | Indicator 8 (FX LCR): Active for Turkey + Bank only; pre-filled from BDDK; ≥90% / <90% | FR | Must | Hidden for all non-Turkey-Bank combinations |
| REQ-03-09 | Indicator 9 (Material waiver): No / Yes – without forbearance / Yes – with forbearance | FR | Must | With forbearance → WL=3 |
| REQ-03-10 | Indicator 10 (Internal rating): Dropdown AAA → CCC-; manual only | FR | Must | B → WL=1; CCC+ and below → WL=2; B+ and above → WL=0 |
| REQ-03-11 | Indicator 11 (Internal rating change): Dropdown → same/upgrade / 1 notch / 2 notches / 3+ notches | FR | Must | 2 notch downgrade → WL=1; 3+ → WL=2 |
| REQ-03-12 | Indicator 12 (Country rating change): Pre-filled from public source; notch change auto-calculated | FR | Must | 1 notch → WL=1; 2+ notches → WL=2; auto-filled value editable |
| REQ-03-13 | Indicator 13 (External rating change): Best-effort auto-fill; analyst confirms or enters manually; agency selector (S&P / Moody's / Fitch) | FR | Must | 2 notch downgrade → WL=1; 3+ notches → WL=2 |
| REQ-03-14 | Each indicator row shall display its calculated individual WL value | FR | Must | WL value shown on every row in real time as dropdowns are changed |

---

### EPIC-04: Soft Factor Assessment Form

| Req ID | Requirement | Type | Priority | Acceptance Criteria (summary) |
|---|---|---|---|---|
| REQ-04-01 | Each of the 12 questions shall be answerable via Yes / No | FR | Must | All questions must be answered before form can be submitted |
| REQ-04-02 | For questions 5–9, a news panel shall be shown alongside showing the top 5 fetched headlines with source links | FR | Must | News panel shows article title, source name, date, and link; analyst answers Yes/No based on this evidence |
| REQ-04-03 | For SF-11 (market cap), the auto-fetched 12-month % change shall be shown; analyst confirms Yes/No | FR | Must | If % change exceeds a configurable threshold (open question Q4), field is pre-suggested as "Yes" |
| REQ-04-04 | For Turkish listed companies, SF-12 (profitability) shall show the latest operating margin fetched from KAP; analyst confirms | FR | Should | Operating margin trend shown as supporting data; analyst makes final Yes/No |
| REQ-04-05 | A "Comments" text field shall be available per question; mandatory if "Yes" is selected | FR | Should | Yes selection without a comment triggers a validation warning on submit |
| REQ-04-06 | SF-11 shall be hidden for private companies | FR | Must | Listed flag = Private → SF-11 hidden |

---

### EPIC-05: Watchlist Level Calculation & Override

| Req ID | Requirement | Type | Priority | Acceptance Criteria (summary) |
|---|---|---|---|---|
| REQ-05-01 | Final WL = maximum of all individual Hard and Soft Factor WL values | FR | Must | Any indicator producing WL=3 results in final WL=3 |
| REQ-05-02 | Minimum Condition breach (Ind. 1 delay present / Ind. 10 internal rating B or below) shall display a prominent red alert | FR | Must | Alert shown regardless of other indicator values |
| REQ-05-03 | Front Officer may override the final WL; override requires a mandatory written justification | FR | Must | "Checked By" sign-off field is inactive until override is saved with non-empty justification |
| REQ-05-04 | "Prepared By" and "Checked By" fields (name + date) shall be mandatory for form submission | FR | Must | Form cannot be saved without both fields populated |
| REQ-05-05 | WL result shall be displayed with colour coding: WL0=green, WL1=yellow, WL2=orange, WL3/4=red | UXR | Should | Mirrors the Traffic Light logic in the original Excel |
| REQ-05-06 | A summary panel shall show: final WL, the indicator(s) that drove the highest level, and count of auto-fetched vs manually entered fields | FR | Should | Gives analyst and checker full transparency on what was automated |

---

### EPIC-06: Data Guide & Source Links

| Req ID | Requirement | Type | Priority | Acceptance Criteria (summary) |
|---|---|---|---|---|
| REQ-06-01 | A static "Data Guide" tab shall list every indicator, its country-specific source, URL, and a short research guide | FR | Should | Separate rows for Germany / Turkey / Other |
| REQ-06-02 | A notch calculator helper shall be available: analyst selects previous rating and current rating → system outputs notch change and resultant WL | FR | Should | BBB+ → BB+ = 2 notch downgrade → WL=1 displayed |

---

### EPIC-07: Reporting & Export

| Req ID | Requirement | Type | Priority | Acceptance Criteria (summary) |
|---|---|---|---|---|
| REQ-07-01 | Completed assessment shall be exportable as PDF or Excel | FR | Could | Layout closely mirrors the original Excel template |
| REQ-07-02 | Export shall include: assessment date, customer details, all indicator values, data sources used, and audit trail of overrides | FR | Could | Enables downstream audit and regulatory review |

---

## 6. Out of Scope (Won't Have for POC)

| Item | Reason |
|---|---|
| Automated CBS / IBM ART integration | Requires internal IT API agreement |
| Bloomberg / Reuters licensed data feeds | Requires paid terminal access |
| BDDK / BaFin direct API integration | Regulator APIs not publicly structured |
| Multi-user approval workflow / role-based access | Requires identity management infrastructure |
| Historical assessment comparison / trend view | Requires data warehouse |
| Automated Yes/No decision on Soft Factor news questions | NLP/AI layer — deferred to future phase |

---

## 7. Assumptions & Constraints

| # | Assumption / Constraint |
|---|---|
| A1 | POC operates for a single user; no authentication required |
| A2 | Internal data (CBS, IBM ART, DSC, loan docs) is always entered manually by the analyst |
| A3 | Auto-fetched values are editable — analyst has final authority on all fields |
| A4 | Watchlist scoring logic mirrors exactly the Excel dropdown sheet (no interpretation changes) |
| A5 | Turkey FX LCR threshold: 90%; LCR threshold: 110% (fixed per regulation) |
| A6 | FX LCR indicator is never shown outside Turkey + Bank combination |
| A7 | yfinance (Yahoo Finance) is used for personal/research purposes only per Yahoo ToS — not for commercial production |
| A8 | Google News RSS is used for research purposes; not a licensed data feed |
| C1 | POC output shall not move to production without a business unit review session |
| C2 | Automated data retrieval covers only publicly available, non-licensed sources |

---

## 8. Open Questions — To Be Clarified with Business Unit

| # | Question | Directed To | Priority | Impact |
|---|---|---|---|---|
| Q1 | Is the Soft Factor logic correct: 1 or more "Yes" = WL=1 flat? Or does the number of "Yes" answers escalate the WL level? | Credit Monitoring Team | 🔴 High | Changes scoring engine design |
| Q2 | For the "Other" segment, which agency is the reference for country rating: Fitch, S&P, or the most conservative of the three? | Credit Policy | 🔴 High | Affects country rating fetch logic |
| Q3 | For news-assisted Soft Factor questions (5–9): is the analyst expected to confirm the auto-fetched news, or are these always manual regardless? If news is used, what is the acceptable minimum number of sources? | Credit Monitoring Team | 🔴 High | Defines scope of EPIC-02 news fetcher |
| Q4 | What is the numerical threshold for "significant deterioration in market cap"? (e.g. >20% decline over 12 months = Yes) | Credit Policy | 🟡 Medium | Required to auto-suggest SF-11 answer |
| Q5 | For private Turkish companies, is the Trade Registry Gazette sufficient as a source for auditor's opinion, or must the physical annual report be obtained? | Credit Monitoring Team | 🟡 Medium | Determines automation feasibility for private segment |
| Q6 | Should the WL override justification be free text, or should predefined categories be available (e.g. "Temporary event", "Mitigant in place", "Management decision")? | Front Office / Risk | 🟡 Medium | UX design for override flow |
| Q7 | Is there an acceptable tolerance for auto-fetched LCR data age? (e.g. BDDK bulletin may be 4–6 weeks old) — is this acceptable or must it be flagged? | Credit Monitoring Team | 🟡 Medium | Drives data freshness warning logic |
| Q8 | What is the precise internal definition distinguishing DSC "weak" from DSC "not given"? Is this documented in the KDF Excel? | Risk Analytics | 🟡 Medium | Tooltip / help text in form |
| Q9 | Which countries are planned to be added to "Other" in future phases? (Needed to future-proof the segmentation architecture) | Product Owner | 🟢 Low | Informs technical design only |
