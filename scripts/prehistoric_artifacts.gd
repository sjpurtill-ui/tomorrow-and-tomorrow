extends RefCounted
## Ancient exploration finds. Variation describes crude form and preservation,
## never a later civilization's manufacturing technique or invention.
const FORMS := ["rough stone bowl", "battered hammerstone", "thick stone flake", "crude pebble chopper", "unfinished pointed stone", "worn grinding slab", "ochre lump", "pigment grinding pebble", "charcoal-marked rock", "handprint rock fragment", "animal-painting rock fragment", "scratched bone fragment", "rough bone point", "worn tooth fragment", "pinched unfired clay lump", "burnt hearth stone"]
const VARIANTS := ["irregular", "small", "heavy", "broad", "elongated", "lopsided", "fractured", "worn", "pitted", "weathered", "angular", "rounded", "flattened", "scarred", "unfinished", "fragmentary"]
const TRACES := ["earth-darkened", "ochre-dusted", "charcoal-stained", "mineral-crusted", "pale", "mottled", "smoke-stained", "red-brown", "gray", "yellow-stained", "sand-worn", "chalk-dusted", "clay-stained", "dark-patched", "faintly marked", "partly buried"]
const MATERIALS := ["coarse stone", "river cobble", "flint", "coarse stone", "flint", "sandstone", "red earth pigment", "coarse stone", "limestone", "limestone", "limestone", "bone", "bone", "tooth", "unfired clay", "coarse stone"]
const SUBJECTS := ["stone_sorting", "stone_sorting", "controlled_flaking", "stone_sorting", "controlled_flaking", "stone_sorting", "oral_epics", "stone_sorting", "oral_epics", "oral_epics", "oral_epics", "tallies", "stone_sorting", "oral_epics", "clay_shaping", "charcoal"]

static var experiments:Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/artifacts/prehistoric_experiments.json"))
## What people would call each authored experiment ("carved bone toggle"),
## keyed by the lower-case title before any " · " variation.
static var plain_names:Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/artifacts/plain_names.json"))

static func definition(id:int)->Dictionary:
	if id<0 or id>=4096:return {}
	if experiments.has(str(id)):return experiments[str(id)].duplicate(true)
	var form:=id%16
	return {"name":"%s %s · %s" % [String(VARIANTS[(id/16)%16]).capitalize(),FORMS[form],TRACES[(id/256)%16]],"form":FORMS[form],"material":MATERIALS[form],"discovery_id":SUBJECTS[form],"artifact_origin":"prehistoric","art_collection":"prehistoric-v1","catalogue_id":id}
