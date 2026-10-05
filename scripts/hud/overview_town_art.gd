extends RefCounted
## Representative painted architecture, not a second map or a building ledger.
const PATH := "res://assets/ui/overview/town-portraits-v1.png"
static var atlas: Texture2D
static var plates: Dictionary = {}

static func plate(drawing: Dictionary) -> int:
	var tier := float(drawing.get("architecture_tier", 0.0))
	if tier < 1.0: return 0
	if tier < 4.0: return 1
	if tier < 7.0: return 2
	return 3

static func texture(drawing: Dictionary) -> Texture2D:
	if atlas == null:
		if not ResourceLoader.exists(PATH): return null
		atlas = load(PATH) as Texture2D
	var index := plate(drawing)
	if plates.has(index): return plates[index]
	var cell := atlas.get_size() / Vector2(2, 2)
	var image := AtlasTexture.new()
	image.atlas = atlas
	image.region = Rect2(Vector2(index % 2, index / 2) * cell, cell)
	image.filter_clip = true
	plates[index] = image
	return image
