# Army staffing clarity

Worktree /Users/seanpurtill/Documents/Codex/tt-army-staffing; branch
codex/army-staffing; base 1589e37516dc3bc282482c9e200fd0abd32e8a3d.

Recruit & Train now shows available people, free versus required training places,
and the watch/training work allocation as separate quantities. The latter is a
work allocation, not an additional recruit pool. Replace the vague “Leaders
allocate Defense instructors” detour with per-city “Prioritize watch & training”
actions directly on the preparation screen and its requirements report. They use
GovernmentPeopleSystem.set_settlement_focus and preserve its occupation guards,
daily staffing, essential-needs protection and manual-priority behavior. Requested
priorities are shown as requested, not an instant capacity increase. Feedback
explains the daily reassessment, civilian work tradeoff, and unchanged service cap.

Owned files: scripts/hud/content/dock_content_military.gd and
scripts/military_campaign.gd (one blocker wording change only), plus
 tests/test_army_staffing_actions.gd. No recruitment calculation, capacity,
conservation, simulation authority or save schema changes. No shared-file conflicts.

Clean isolated headless import passes. Two new action tests plus nine existing
recruitment reconciliation cases pass: 11/11, zero errors/failures/orphans.
They check city-specific priority, no created soldiers, occupied-city rejection,
and existing full-class training/personnel conservation behavior. Logs:
/tmp/army-staffing-import.log and /tmp/army-staffing-tests.log. Final UI wording
clarifies the allocation is not an additional civilian headcount. No graphical
novice usability study is claimed.
