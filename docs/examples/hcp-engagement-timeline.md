# Example: HCP Engagement Timeline

Action: `GetHcpEngagementTimelineAction` · CLT: `hcpEngagementTimelineCLT` · LWC: `hcpEngagementTimelineLWC`

Input: optional `accountName` (free text). Any value, or leaving it blank,
returns the same four canned events across four tracks (Visit, Medical
Insight, Event Participation, Inquiry) — only the account name and the
headline's echoed name change.

Unlike the other three examples, the card renders a **multi-track,
chronological timeline** (`events`, a list of objects) rather than a flat
set of scalar fields — it's the first example in this library exercising a
`List<Wrapper>` CLT field end-to-end, including the mobile page-reference
path (`c__events` arrives as one JSON-stringified array param, not one
param per field).

## Utterance — engagement timeline for a named account

**Say:** "Show me the engagement timeline for Acme Health System."

**Action call:** `GetHcpEngagementTimelineAction` with `accountName = "Acme Health System"`.

**Expected card:**
| Field | Value |
|---|---|
| Account | Acme Health System |
| Headline | "Acme Health System: engaged across 4 touchpoints in the last 30 days — the symposium attendance likely primed this week's formulary question." |

| Date | Track | Title | Detail |
|---|---|---|---|
| today − 30 days | Visit | Field visit | Discussed new indication data; rep left leave-behind on updated dosing guidance. |
| today − 21 days | Medical Insight | Adverse event inquiry logged | HCP raised a mild AE question; routed to Medical for a follow-up response. |
| today − 14 days | Event Participation | Attended regional symposium | HCP attended the sponsored CME session on the same therapeutic area. |
| today − 2 days | Inquiry | Formulary access question | HCP's office asked about prior-authorization requirements ahead of next visit. |

**Expected chat text:** matches the headline above.

## Utterance — blank account (default)

**Say:** "Show engagement timeline." (or "What's the engagement history for this account?")

**Action call:** `GetHcpEngagementTimelineAction` with `accountName` blank → defaults to `"Sample Account"`.

**Expected card:** same four events, headline and account name say "Sample Account" instead.

## What to verify

- All four tracks render with visually distinct badges (`.track-visit`,
  `.track-medical-insight`, `.track-event-participation`, `.track-inquiry`
  CSS classes in `hcpEngagementTimelineLWC.css`).
- Events render in chronological order along the timeline spine (oldest at
  top).
- On mobile, confirm `events` deserializes correctly from the single
  JSON-stringified `c__events` state param — this is the first example in
  the library passing a list of objects through the mobile page-reference
  path rather than one scalar param per field.
- Blank-`accountName` calls are non-deterministic in this topic (confirmed
  via `sf agent preview` trace inspection — see `docs/README.md`'s note on
  `agent preview`): the model sometimes narrates a card without calling the
  action at all. This mirrors the same phrasing-sensitivity documented for
  `fieldStockSnapshotCLT`; retry the exact utterance if a card doesn't
  render, and prefer naming an account explicitly, which calls the action
  reliably.
