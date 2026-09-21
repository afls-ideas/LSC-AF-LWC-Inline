# Example: Sample Agentforce Output (template scaffold)

Action: `GetSampleAgentforceOutputAction` · CLT: `sampleAgentforceOutputCLT` · LWC: `sampleAgentforceOutputLWC`

Input: optional `topic` (free text). Leaving it out uses the default sample topic.

## Utterance 1 — default

**Say:** "Show me a sample card."

**Action call:** `GetSampleAgentforceOutputAction` with `topic` blank.

**Expected card:**
| Field | Value |
|---|---|
| Title | Sample Agentforce Output |
| Message | This is a template card about the scaffold library. |
| Items | Works on Web · Works on Mobile · Duplicate me to start a new example |

**Expected chat text:** "Sample Agentforce Output: This is a template card about the scaffold library."

## Utterance 2 — with a topic

**Say:** "Show me a sample card about onboarding."

**Action call:** `GetSampleAgentforceOutputAction` with `topic = "onboarding"`.

**Expected card:**
| Field | Value |
|---|---|
| Title | Sample Agentforce Output |
| Message | This is a template card about onboarding. |
| Items | Works on Web · Works on Mobile · Duplicate me to start a new example |

## What to verify

- Same card renders identically on Web (`@api value`) and on the AFLS
  mobile app (`CurrentPageReference` state params) — a web-only
  implementation is a common mistake this dual data path is meant to avoid.
- If items are missing entirely, the LWC's `hasData` getter should fall back
  to "No data available." — try an utterance that would return no title,
  message, or items (not reachable from this action as-is; this is a code
  read-through check, not a live test).
