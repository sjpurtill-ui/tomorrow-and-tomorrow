extends RefCounted
## Local scouting presentation. No simulation, era unlocks or save state live here.
const T = preload("res://scripts/hud/hud_tokens.gd")
const INK = Color("f2e6cb")
const SOFT = Color("c0b299")
const GOLD = Color("d6b579")
const GREEN = Color("a9ba8a")
const CLAY = Color("211c17")
const TILE = Color("302820")
const BORDER = Color("65523c")
const TITLE = preload("res://assets/fonts/cinzel/Cinzel.ttf")
const BODY = preload("res://assets/fonts/battle/Barlow-Medium.ttf")
const HERO = preload("res://assets/ui/scouting/ancient-expedition-v2.jpg")
const SURFACE = preload("res://assets/ui/scouting/ancient-clay-v2.jpg")
const STONE = preload("res://assets/ui/scouting/ancient-find-v2.jpg")
static var icons: Dictionary = {}

static func icon(kind: String) -> Texture2D:
	if icons.has(kind): return icons[kind]
	var path: String = {
		"exploration": '<path d="M7 35L19 12l4 13 9-17 9 27M4 40h40M11 29l6 4 6-8M34 10l2-4m5 10 5-1"/>',
		"recruitment": '<circle cx="17" cy="15" r="6"/><circle cx="34" cy="18" r="5"/><path d="M5 39v-7q0-9 12-9t12 9v7m2-13q12 0 12 11v3M12 38h10"/>',
		"find": '<path d="M25 5L10 21l2 16 14 6 13-17-5-14zM25 5l1 17 13 4M10 21l16 1-14 15m14-15v21"/>',
	}.get(kind, '<path d="M12 10h24v29H12zM18 18h12m-12 7h12m-12 7h8"/>')
	var source := '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><g fill="none" stroke="#d6b579" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % path
	var image := Image.new()
	image.load_svg_from_string(source)
	icons[kind] = ImageTexture.create_from_image(image)
	return icons[kind]

static func stone_find(item: Dictionary) -> bool:
	return String(item.get("discovery_id", "")) == "stone_sorting" and String(item.get("kind", "")) in ["specimen", "artifact"]

static func style_button(node: Button, primary := false) -> void:
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var active := state in ["pressed", "hover_pressed"]
		var color := Color("483925") if active else Color("3b3025") if state == "hover" else TILE
		var style := T.flat(color, GOLD if active or state == "focus" or primary else BORDER, 1, 4, 8)
		node.add_theme_stylebox_override(state, style)
		node.add_theme_color_override("font_" + state + "_color", INK)
	node.add_theme_color_override("font_color", INK)
	node.add_theme_font_override("font", BODY)
	node.add_theme_font_size_override("font_size", 15)

static func style_slider(slider: HSlider) -> void:
	var track := T.flat(Color("15120f"), BORDER, 1, 3)
	track.content_margin_top = 4; track.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", T.flat(GOLD, Color.TRANSPARENT, 0, 3))
	slider.add_theme_stylebox_override("grabber_area_highlight", T.flat(INK, Color.TRANSPARENT, 0, 3))
	for key: String in ["grabber", "grabber_highlight", "grabber_disabled"]:
		var image := Image.new()
		image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="26" height="26"><ellipse cx="13" cy="14" rx="10" ry="10" fill="#17120e"/><path d="M6 5L17 3l7 9-4 10-13 1-5-11z" fill="#d6b579" stroke="#f2e6cb" stroke-width="1.5"/><path d="M9 8l8-1m-9 7h10" stroke="#9d7d4f" stroke-width="1.5"/></svg>')
		slider.add_theme_icon_override(key, ImageTexture.create_from_image(image))
