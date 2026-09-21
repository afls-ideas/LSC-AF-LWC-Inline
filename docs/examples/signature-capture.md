# Example: Signature Capture

Action: `GetSignatureCaptureAction` · CLT: `signatureCaptureCLT` · LWC: `signatureCaptureLWC`

**Real data — queries `Case`, `Pricebook2`, `PricebookEntry`, and `Product2`
live.** No canned values. This is the library's write-capable, interactive
example: unlike the other three data-bearing examples (read-only display
cards), this card lets the rep search products, tally quantities, draw a
confirmation signature, and generate a real draft `Order` + `OrderItem`
records — all client-side, directly on the card.

Input is an optional `caseNumber` (free text, matched with `LIKE
'%...%'` against `CaseNumber` or `Subject`). The action resolves the most
recently opened non-`Closed` case if no filter is given, plus the org's
real active standard-pricebook product catalog (up to 200 priced,
active `Product2`/`PricebookEntry` rows).

## How the card works

1. **Search & log usage** — type in the search box to filter the real
   priced catalog by name or code; click a result to add it to the usage
   list with a quantity stepper (+/−).
2. **Confirmation signature** — draw on the canvas signature pad (mouse or
   touch) to satisfy the required confirmation gesture. "Clear signature"
   resets it. The drawn image is **never persisted** — it's a gate on the
   button, not a stored record or attachment.
3. **Generate draft order** — enabled only once at least one product is
   logged and the signature gesture is captured. Performs a real
   `createRecord` DML call (client-side, in the LWC — not a second
   Agentforce action) to create one `Order` (`Status: 'Draft'`) and one
   `OrderItem` per logged line, then shows a confirmation banner with a
   drill-through link to the new order.

If no case matches, `capture` is `null` and `summary` explains why.

## Utterance — no case named (most recently opened)

**Say:** "Log usage against a case and capture a signature" / "I need to
log what I used and generate a draft order"

**Action call:** `GetSignatureCaptureAction` with `caseNumber` blank —
returns the most recently opened non-Closed case in the org, plus the full
priced catalog.

**Confirmed live (2026-09-20), `<target-org>`:**
| Field | Value |
|---|---|
| Case | 00001504 |
| Subject | ClearView 4K — Scope Processor Compatibility Assessment Request |
| Account | Bay Area Endoscopy Center |
| Priced products available | 165 |
| Sample product | Aurora 3D Tower — $90,000.00 |

**Chat text:** "Case 00001504 (ClearView 4K — Scope Processor Compatibility
Assessment Request) is ready to log usage against — 165 priced products
available."

These values come straight from the org's real `Case`/`Product2` records
and will change as org data changes — this is a worked example, not a
fixed expected value.

## Utterance — named case

**Say:** "Log usage against case [a case number or subject keyword]"

**Action call:** `GetSignatureCaptureAction` with `caseNumber` set —
matches against `CaseNumber` or `Subject`, still non-Closed only.

## What to verify

- Product search only matches against the real catalog returned by the
  action — never fabricates a product that isn't in the priced list.
- "Generate draft order" stays disabled until both a product is logged
  **and** the signature pad has been drawn on — confirm neither condition
  alone enables it.
- After generating, the card shows a confirmation banner (not the
  search/log UI again) and the drill-through link opens the real new
  `Order` record.
- A case number with no match returns `capture: null` and a plain-text
  "no matching case was found" message — confirm the agent doesn't
  fabricate a card in this case.
