# Example: HCP Affiliation Network

Action: `GetHcpAffiliationNetworkAction` · CLT: `hcpAffiliationNetworkCLT` · LWC: `hcpAffiliationNetworkLWC`

Input: optional `accountName` (free text). Queried live from
`ProviderAffiliation` — no canned data. Returns the named HCP, the real
organizations they're affiliated with (up to 8, primary/hard affiliations
first), and up to 10 other real providers who share one of those
organizations.

Unlike the other examples, the card renders a **force-directed graph**
(`nodes`/`edges`, two parallel lists) rather than scalar fields or a flat
timeline. Apex only returns the raw graph — the node x/y layout is computed
client-side in `hcpAffiliationNetworkLWC.js` by a small hand-rolled
spring/repulsion simulation (`computeForceLayout`), the same idea as
`d3-force`'s alpha-decay cooling, run once per card over plain SVG
`<circle>`/`<line>` elements — no external charting library.

## Utterance — affiliation network for a named HCP

**Say:** "Show me the affiliation network for Callum Stewart."

**Action call:** `GetHcpAffiliationNetworkAction` with `accountName = "Callum Stewart"`.

**Expected card** (worked example from a real run against `262-lsdo-july`):
| Field | Value |
|---|---|
| Account | Callum Stewart |
| Headline | "Callum Stewart is affiliated with 8 organizations, shared with 10 other providers in this network." |

- Center node: Callum Stewart (HCP).
- 8 organization nodes, e.g. Royal Infirmary of Edinburgh (primary, hard
  affiliation — solid edge), Western General Hospital, NHS Lothian, Royal
  London Hospital, St Thomas' Hospital, Great Ormond Street Hospital,
  King's College Hospital, Stockbridge Health Centre (soft — dashed edge).
- 10 colleague provider nodes (other HCPs affiliated with one of those same
  organizations), e.g. Charlotte Ainsworth, George Fitzwilliam, Richard
  Ellsworth, Chidinma Eze, Alasdair Campbell, and others — each connected
  only to the organization(s) they share with Callum Stewart, not directly
  to him.

**Expected chat text:** matches the headline above.

## Utterance — blank account (default)

**Say:** "Show me an HCP affiliation network." (or "Who is this provider affiliated with?")

**Action call:** `GetHcpAffiliationNetworkAction` with `accountName` blank → defaults to the real HCP with the most `ProviderAffiliation` records in the org.

**Expected card:** same graph shape, for whichever HCP currently has the most affiliation records.

## What to verify

- Center node renders larger and in a distinct color from organization and
  colleague-provider nodes (`.node-center` / `.node-hco` / `.node-hcp` CSS
  classes in `hcpAffiliationNetworkLWC.css`); node size also differs by
  role so the graph doesn't rely on color alone.
- Primary/hard affiliations render as solid, thicker edges; soft
  affiliations render dashed — hover an edge to see its role/type in the
  tooltip (`<title>` inside the SVG `<line>`).
- The graph settles into a stable, non-overlapping-ish layout — center HCP
  roughly in the middle, organizations and colleague providers spread
  around it. Minor overlap is expected with denser networks; this is a
  one-shot layout, not an interactive drag-to-reposition graph.
- On mobile, confirm `nodes` and `edges` each deserialize correctly from
  their own single JSON-stringified `c__nodes`/`c__edges` state params —
  the same list-through-mobile-page-reference path documented for
  `hcpEngagementTimelineCLT`, exercised twice here (two list fields instead
  of one).
- An HCP with no recorded affiliations returns a null card — confirm the
  agent says so in plain text rather than claiming a card is shown.
