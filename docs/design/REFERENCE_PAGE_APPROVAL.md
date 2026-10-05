# Reference page — approved Trade design

Status: APPROVED by the user on October 4, 2026. Integration checks complete.

The user rejected the first Trade implementation and the earlier Wealth
interpretation because they did not reproduce the approved photo's composition
and painted artwork. The target is the complete open-page presentation in
`approved-wealth-and-navigation.png`, including sidebar tools, labels, top bar,
parchment proportions, serif typography, fine rules and large illustrations.

The user explicitly requires seeing each rendered example before it is pushed
into the game. Do not integrate this prototype into `main` or the canonical
checkout until the user approves the concrete page preview. Development branch
backups do not count as approval or delivery. Future page examples retain this
review gate.

The first example is Trade inside the reference-style frame. Its GPU screenshot
comes from the actual UI scripts, with prepared in-memory trade records and an
isolated test shell. The neutral area beyond the page is not the player map.
No user campaign is loaded, saved, restarted or represented by these records.

Trade uses existing ledger values and existing action callbacks. Richer rows
open their goods, dependence, offers and terms. It does not invent historical
trends, account balances or trade outcomes. The new barter vignette is symbolic
early-era art, not a recorded event or portrait of an official.

The user's follow-up requires ONE trade balance bar. Its midpoint means equal
exchange; the fill extends left for more received and right for more sent.
The signed fraction is `(sent - received) / (received + sent)`, with an empty
or equal exchange centered. Displayed figures retain the ledger's period and
sender-price meaning; they are not profit or physical stock.

## First rendered example

Local output: `artifacts/trade-received-left/trade-preview.png`,
1536 by 1024, mounted through the real economy provider and dock. The review
shell has the same city selector, page visibility hooks and navigation widgets
as the game. Its plain map area and prepared records are labelled explicitly.
The original long-name fixtures remain in the acceptance harness; the approval
example uses ordinary names in those same prepared records.

Source components: Trade folio prototype `c0f5c780`, art source `ce031ad0`,
reference frame source `5c9ff0fb` (integrated into the development branch as
`ae6b9f2d`), and scoped harness source `de507fbe` (`6f73c6a3`).
The prototype incorporates synchronized main `8bd11fdd` without changing it.

Verification so far: 12/12 Trade/pressure regressions and 11/11 focused Trade
visual/data/action tests pass, including the centered bar's direction, zero
case, actual purchase conservation and orders. Subsequent spacing and frame
refinements are covered by the private GPU preview, not claimed as full
navigation acceptance. Captures, imports, generated UIDs and userdata stay
local. No player/editor process is launched or interrupted.

This is a visual approval checkpoint. After visual approval, finish multi-size,
theme, navigation and disclosure acceptance against the final integrated code
before remote-first delivery under `AGENTS.md`.

The user approved the final rendered Trade example at runtime commit 0bb4b393
with Received on the left, Sent on the right, and live readings on the same
persistent gray bar as the speed controls. This approval covers that Trade
page and its shared frame. Future page-specific redesigns still need previews.

Integration validation: nine GPU cases at 1920, 1536 and 1138px canvas widths,
both palettes, collapsed and expanded terms, 41 captures, 630/630 checks;
35 selected functional cases verified across reports 16 and 17. The new
sidebar test was corrected to distinguish opening a page from toggling the
active page closed. Runtime code required no change after visual approval.
