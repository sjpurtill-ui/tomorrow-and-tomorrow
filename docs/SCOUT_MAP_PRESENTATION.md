# Scouting map overlays

Active scouting orders use muted, thin dashed paths and small endpoint rings. The overlay draws in viewport coordinates, so camera zoom cannot inflate a route into a broad ribbon. Large direction pennants and persistent map labels have been removed.

Hover within eight viewport pixels of a path to highlight it and read its heading, planned-route status, and report due day. Details are suppressed beneath UI controls; the overlay does not intercept clicks. These remain issued plans, not live tracking or revealed observations.

Validation: `scout_gamble_probe.tscn` passes. `scout_map_visual_probe.tscn` renders three simultaneous routes at two camera distances and captures the hover state. Captures under `artifacts/scout-map-*.png` were visually checked.
