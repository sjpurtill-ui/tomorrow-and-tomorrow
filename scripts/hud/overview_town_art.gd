extends RefCounted
## Representative painted architecture, not a second map or a building ledger.
const PATHS := [
	"res://assets/ui/overview/camp-v2.png",
	"res://assets/ui/overview/village-v2.png",
	"res://assets/ui/overview/town-v2.png",
	"res://assets/ui/overview/mature-v2.png"]
static var plates: Dictionary = {}

static func plate(drawing: Dictionary) -> int:
	var tier := float(drawing.get("architecture_tier", 0.0))
	if tier < 1.0: return 0
	if tier < 4.0: return 1
	if tier < 7.0: return 2
	return 3

static func texture(drawing: Dictionary) -> Texture2D:
	var index := plate(drawing)
	if plates.has(index): return plates[index]
	if not ResourceLoader.exists(PATHS[index]): return null
	var image := load(PATHS[index]) as Texture2D
	plates[index] = image
	return image
