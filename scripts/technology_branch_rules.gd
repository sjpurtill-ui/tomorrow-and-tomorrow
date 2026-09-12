extends RefCounted
## First production reconvergences from the approved full-history design.
## Existing IDs and adoption effects remain authoritative.
static func apply(entry:Dictionary)->Dictionary:
	match String(entry.id):
		"public_libraries":
			entry["requires_all"]=["public_schools"]
			entry["learning_routes"]=[
				{"id":"local","label":"Printed shared collections","requires_all":["printing_process"]},
				{"id":"manuscript","label":"Copied archive collections","requires_all":["formal_archives"],"progress_multiplier":0.65}]
		"public_theatre":
			entry["requires_all"]=["framed_construction"]
			entry["requires_any"]=[["oral_epics","festival_calendar"]]
			entry["learning_routes"]=[{"id":"local","label":"Organized public performance","requires_all":[]}]
		"apprentice_contracts":
			entry["requires_all"]=["customary_law"]
			entry["requires_any"]=[["hafted_tools","joinery","pit_firing"]]
			entry["learning_routes"]=[{"id":"local","label":"Agreed duties in an established craft","requires_all":[]}]
	return entry
