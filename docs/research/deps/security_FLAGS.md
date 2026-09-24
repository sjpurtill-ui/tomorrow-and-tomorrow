# Security flags

Registry left unchanged. Items whose year conflicts with their prerequisites:

- `socketed_spearheads` (450) needs cored casting, but `cored_socket_casting` (production) is at 540, which is outside the band. Move `cored_socket_casting` to about 430–450 or move the spearheads to about 540. There is no link for now; the item uses `closed_moulds`.
- `stone_maceheads` (20): perforated heads need drilling, but `bow_drill_drive` (production) is at 28. It is only a precedent here. This is minor.
- Overlap chains, mapped as prerequisites rather than duplicates:
  - `watch_rotation` (2) → `watch_duty_rotation` (knowledge 18) → `rotating_watch_captaincy` (152) → `rotating_relief_wardens` (272).
  - `alarm_relay_signals` (3) + `warning_call_relay` (infrastructure 160) → `alarm_relay_customs` (240) → `border_fortress_chains` (520). The knowledge mapper should make `warning_call_relay` depend on `alarm_relay_signals`.
  - `refuge_point_marking` (6) → `refuge_point_designation` (infrastructure 75) → `fallback_route_marking` (158). The infrastructure mapper should make the designation require the marking.
- `seasonal_crisis_leader` (institutions 24; alias security 170) is only a precedent of `disaster_recovery_roles` (78). The early canonical year is compatible.
- `bronze_weaponry` (400) is gated by `resources_known` Copper+Tin. Tin is usually traded in, so the engine may want `contact_required` as an alternative to having local tin.
- `war_chariots` (500) has the same year as `spoked_wheel_assembly` (logistics 500). The link is valid, but it leaves no lag. Consider moving the spoked wheels to about 485.
