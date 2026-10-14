# Service pages: decisions and selected forces

The reachable Navy/Air roster used to append every unit card. It now opens with
the fleet/wing totals, existing attention/training filters, four searchable force
choices and one selected profile. Crew, condition, drill, equipment and the
existing next action are visible together. Live updates match force IDs rather
than array positions; changing the page or searching does not change any orders.
The window is limited to 1200 pixels so large displays do not stretch the reading.

The old service Readiness page repeated the condition/crew values already available
on Forces. Its entry is removed; existing support links still open Forces. Army
readiness and its supply system remain unchanged. Training retains its four actual
policies, with visible “Drill at once” and “Skill target” labels beside their bars.

The map command Reports page shows three recent choices and one full telling.
An explicit searchable archive shows six choices per page. Current transports
remain included, with full report text preserved. Selecting a report brings its
reader into view. Fleet/base/order/production/transport controls retain their
existing handlers.

Review: root rejected its first stacked index because the selected force fell
below the fold at 1024. The revision places selection beside the profile. C
accepted Forces, the readiness merge and the report reader, then requested visible
training measure labels. Those labels now come from the existing tooltip meanings. C also requested
current food/material use and first-drill timing before the policy choices;
the revised strip is visible above all four choices at 1024 and is accepted.
The populated fixture contains 19 forces per service and 37 reports per service;
it searches the final force/report, pages, verifies the selected force updates live,
checks every initial choice and primary action is inside the viewport and captures
both palettes at 1600/1024. Eight existing roster cases pass. All work is UI-only.
