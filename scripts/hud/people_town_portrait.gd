extends RefCounted
## Population selects illustrative density only. This never unlocks a building,
## changes work, or modifies the settlement/technology ledgers.
const ROLES := ["Food", "Survey", "Extraction", "Construction", "Crafting", "Logistics", "Knowledge", "Administration", "Defense"]
const STAGES := [
	{"id": "camp", "title": "Camp", "min_population": 0},
	{"id": "hearth", "title": "Hearth", "min_population": 150},
	{"id": "village", "title": "Village", "min_population": 400},
	{"id": "town", "title": "Town", "min_population": 1500},
	{"id": "large_town", "title": "Large town", "min_population": 6000},
]

static func stage(context: Dictionary = {}) -> Dictionary:
	var population := maxi(0, int(context.get("population", 0)))
	var selected: Dictionary = STAGES[0]
	for candidate: Dictionary in STAGES:
		if population >= int(candidate.min_population): selected = candidate
	return selected.duplicate(true)

static func texture_path(context: Dictionary = {}) -> String:
	var id := String(stage(context).id)
	return "res://assets/ui/people/town-portrait-camp-v2.png" if id == "camp" else "res://assets/ui/people/town-portrait-%s-v1.png" % id.replace("_", "-")

## All coordinates are normalized in the original photograph, independent of
## its onscreen letterboxing, zoom, or aspect ratio. Regions enclose meaningful
## work, not decorative houses; the UI shows actual counts beside the image.
static func areas(context: Dictionary = {}) -> Dictionary:
	var hearth := String(stage(context).id) == "hearth"
	var boxes: Dictionary = {
		"Food": Rect2(.69, .04, .29, .20),
		"Survey": Rect2(.025, .025, .20, .145),
		"Extraction": Rect2(.025, .59, .28, .25),
		"Construction": Rect2(.83, .25, .17, .30),
		"Crafting": Rect2(.52, .30, .23, .22) if hearth else Rect2(.58, .29, .23, .24),
		"Logistics": Rect2(.44, .65, .28, .27),
		"Knowledge": Rect2(.33, .40, .19, .17) if hearth else Rect2(.40, .43, .18, .17),
		"Administration": Rect2(.025, .33, .28, .22) if hearth else Rect2(.13, .34, .22, .20),
		"Defense": Rect2(.82, .57, .17, .22),
	}
	if String(stage(context).id) == "camp":
		boxes = {
			"Food": Rect2(.79, .14, .17, .17),
			"Survey": Rect2(.07, .015, .12, .14),
			"Extraction": Rect2(.025, .56, .27, .24),
			"Construction": Rect2(.82, .28, .17, .24),
			"Crafting": Rect2(.59, .36, .16, .17),
			"Logistics": Rect2(.51, .63, .22, .23),
			"Knowledge": Rect2(.33, .37, .19, .19),
			"Administration": Rect2(.13, .31, .19, .20),
			"Defense": Rect2(.88, .55, .115, .31),
		}
	elif String(stage(context).id) == "town":
		boxes.Administration = Rect2(.035, .40, .18, .17)
	elif String(stage(context).id) == "large_town":
		boxes.Administration = Rect2(.055, .40, .19, .19)
		boxes.Knowledge = Rect2(.40, .49, .19, .16)
	var result: Dictionary = {}
	for role: String in ROLES:
		var box: Rect2 = boxes[role]
		var center := box.get_center()
		var focus := box.grow(.055).intersection(Rect2(0, 0, 1, 1))
		result[role] = {"polygon": PackedVector2Array([box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]), "anchor": center, "focus": focus}
	return result
