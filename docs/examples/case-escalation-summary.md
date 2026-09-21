# Example: Case Escalation Summary

Action: `GetCaseEscalationSummaryAction` · CLT: `caseEscalationSummaryCLT` · LWC: `caseEscalationSummaryLWC`

**Real data — queries `Case` (+ `CaseMilestone`) live.** No canned values.
Input is an optional `accountName` (free text, matched with `LIKE
'%...%'` against `Account.Name`). The action walks priority tiers from
Critical → High → Medium → Low, preferring open over closed and most
recent first, and returns the first real match — optionally scoped to a
named account.

`slaDueDate` comes from the case's earliest incomplete `CaseMilestone`
(`TargetDate`) — a real field, not every case has one, so `slaDueDate` can
legitimately be `null`.

If no case matches, `summary` is `null` and `output` explains why.

## Utterance — no account named (org-wide most urgent)

**Say:** "What's the case status for an account?" / "Do I have any open cases?"

**Action call:** `GetCaseEscalationSummaryAction` with `accountName` blank —
returns the highest-priority real case in the org across all accounts.

**Confirmed live (2026-09-20), <target-org>:**
| Field | Value |
|---|---|
| Case | 00001182 |
| Subject | How do I upgrade? |
| Account | Advanced Communications |
| Status | Working |
| Priority badge | **Critical** (red) |
| SLA Due | (null in this example — no incomplete milestone on this case) |

**Chat text:** "Case 00001182 for Advanced Communications is Working (Critical priority)."

These values come straight from the org's real `Case` records and will
change as case data changes — this is a worked example, not a fixed
expected value.

## Utterance — named account

**Say:** "Do we have any open cases for [an account name]?"

**Action call:** `GetCaseEscalationSummaryAction` with `accountName` set —
walks the same priority tiers, scoped to accounts matching that name.

## What to verify

- The priority badge renders correctly across all four real tiers
  (Critical/High/Medium/Low → red/red/orange/green, per the LWC's
  `priorityClass` getter) — which tier you see depends on what's actually
  open in the org, not a fixed scenario.
- An account name with no matching case returns `summary: null` and a
  plain-text "no matching case was found" message — confirm the agent
  doesn't fabricate a card in this case.
- `slaDueDate` is `null` for cases with no incomplete `CaseMilestone` —
  confirm the LWC handles a missing SLA date gracefully rather than
  showing a blank/broken field.
