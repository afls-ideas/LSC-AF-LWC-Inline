# Example: Field Stock Snapshot

Action: `GetFieldStockSnapshotAction` · CLT: `fieldStockSnapshotCLT` · LWC: `fieldStockSnapshotLWC`

**Real data — queries `ProductBatchItem` live.** No canned values. Input is
an optional `productName` (free text, matched with `LIKE '%...%'` against
`Product.Name`). With a name given, returns the lowest-quantity,
soonest-to-expire **active** lot for a matching product. Left blank, returns
the single most urgent active lot across *all* products — the org's
worst-stocked item right now.

`reorderThreshold` is a fixed business-rule constant (`10`), not a stored
field. `lastCountDate` is the lot's real `LastModifiedDate`, used as the
closest available real proxy for "last counted." `isLowStock` is
`onHandQty <= reorderThreshold`.

If no active lot matches, `snapshot` is `null` and `summary` explains why —
the agent is instructed not to claim a card is shown in that case.

## Utterance — named product

**Say:** "How much TitanJoint stock do I have?" / "Show me the stock
snapshot for TitanJoint."

**Action call:** `GetFieldStockSnapshotAction` with `productName = "TitanJoint"`.

**Confirmed live (2026-09-20), <target-org>:**
| Field | Value |
|---|---|
| Product | TitanJoint Instrument Loan Set |
| Status badge | **Low Stock** (red) |
| On Hand | 1 |
| Reorder Threshold | 10 |
| Last Counted | 6/11/2026 |

**Chat text:** "TitanJoint Instrument Loan Set: 1 on hand (reorder at 10) — LOW STOCK"

These numbers come straight from the org's real `ProductBatchItem` records
and will drift as that data changes — don't treat them as fixed expected
values, only as a worked example of the shape.

## Utterance — blank product (org-wide most urgent)

**Say:** "Check my field stock."

**Action call:** `GetFieldStockSnapshotAction` with `productName` blank —
returns the single lowest-quantity active lot across every product in the org.

## What to verify

- The red/green status badge (`.status-low` / `.status-ok` CSS classes)
  actually flips based on real `onHandQty` vs. the `10` threshold.
- A product name with no matching active lot returns `snapshot: null` and a
  plain-text "no matching stock was found" message — confirm the agent
  doesn't fabricate a card in this case.
- On mobile, confirm the card renders from `CurrentPageReference` state
  (`c__productName`, `c__onHandQty`, etc.) rather than staying blank — this
  is the dual-path behavior the whole library exists to demonstrate.
- Confirmed rendering correctly in the standard Salesforce mobile app on
  both iPad and iPhone (2026-09-20) — see screenshots in this repo's
  `docs/images/`. That verification predates the real-data conversion but
  covers the same CLT/LWC rendering path, which the real-data change did
  not touch.
