# Routine early raids

Follow-up to d6bc405. RaidPolicy stops parties smaller than six and rejects
raids whose readiness-adjusted strength is below 80% of the rival's dated observed
defense. It does not inspect hidden live player strength to pick targets. Failed
home raids increase the source's cooldown from 180 to at most 720 days.

Home raids of at most 24 personnel are routine only when the local defense has
at least twice their readiness-adjusted strength. Re-evaluate when combat begins.
Routine threat/start/result signals do not pause or open the battle view. The
existing calendar advances the real combat simulator and commits casualties and
reports; no fabricated automatic win. Empty aftermath is cleared; actual captives,
spoils or captured leaders still require the established policy decision.
Offensive actions, occupied-region defense and substantial attacks keep attention.

Worker: 25/25 raid policy, battle injury, and army-front checks passed, including
an actual routine engagement advancing to a committed result without a visual
gate. Log /tmp/raid-policy-final-tests.log. A broader surprise-hostilities run
also inherited the already documented siege withdrawal failure at
 test_siege_progression.gd:145 (moving versus stationed); not fixed by this slice.

Save schema unchanged: routine_raid and failed_home_raids are optional dictionary
fields. Existing records default to prior attention behavior. No army, civic-labor
or general ownership changes. Local terrain and military_campaign are shared
integration hotspots. This is a bounded small-raid fix, not a full scouting,
retreat, target-loot or opponent strategic-AI redesign.
