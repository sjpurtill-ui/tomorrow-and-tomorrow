extends Node
## Painted UI artwork only. Roster portraits never render the world unit meshes.
const COLORS:={"army":Color("d9b772"),"navy":Color("76bbce"),"air":Color("a9bbec")}
const Painting=preload("res://scripts/hud/subject_painting.gd")
static var symbols:Dictionary={}
const ART_MANIFEST="res://assets/ui/military/subject-art-manifest.json"
static var assignments:Dictionary={}
static func manifest()->Dictionary:
	if assignments.is_empty():assignments=JSON.parse_string(FileAccess.get_file_as_string(ART_MANIFEST))
	return assignments

static func artwork(service:String)->Texture2D:
	return load("res://assets/ui/military/%s-roster-v1.png" % service)

static func symbol(kind:String,color:Color,pixels:int=64)->Texture2D:
	var cache_key:="%s:%s:%d" % [kind,color.to_html(),pixels]
	if symbols.has(cache_key):return symbols[cache_key]
	var paths:={
		"army":'<path d="M19 12 L45 12 L44 34 Q39 45 32 50 Q23 45 20 34 Z"/><path d="M26 22 L38 34 M38 22 L26 34"/>',
		"navy":'<circle cx="32" cy="14" r="5"/><path d="M32 19 V49 M21 27 H43 M12 34 Q13 49 32 49 Q51 49 52 34 M10 37 L12 32 L18 35 M46 35 L52 32 L54 37"/>',
		"air":'<path d="M32 19 L38 29 L56 23 L45 38 L35 37 L32 45 L29 37 L19 38 L8 23 L26 29 Z"/>',
		"people":'<circle cx="23" cy="21" r="7"/><path d="M12 47 V40 Q12 31 23 31 Q34 31 34 40 V47 M39 17 Q50 18 47 27 M41 33 Q54 33 54 46"/>',
		"equipment":'<path d="M15 23 H49 V49 H15 Z M23 23 V15 H41 V23 M15 32 H49 M28 29 V36 H36 V29"/>',
		"skill":'<path d="M13 26 L32 14 L51 26 M13 37 L32 25 L51 37 M13 48 L32 36 L51 48"/>',
		"calendar":'<rect x="13" y="17" width="38" height="35" rx="4"/><path d="M22 11 V23 M42 11 V23 M13 29 H51 M23 38 H29 M36 38 H42 M23 45 H29"/>',
		"supply":'<path d="M14 22 L32 12 L50 22 V44 L32 54 L14 44 Z M14 22 L32 32 L50 22 M32 32 V54 M23 17 L41 27"/>',
		"map":'<path d="M10 17 L25 11 L40 17 L54 11 V47 L40 53 L25 47 L10 53 Z M25 11 V47 M40 17 V53"/>',
		"mounted":'<path d="M11 32 L22 26 L39 29 L45 16 L53 19 L49 32 L42 37 L38 51 M17 34 L16 51 M29 35 L29 50 M22 26 L20 17 L28 16 L33 29"/>',
		"artillery":'<circle cx="24" cy="42" r="10"/><path d="M24 42 L43 24 L52 20 L55 27 L29 45 M17 48 L10 53 M30 47 L45 53"/>',
		"armor":'<path d="M11 34 H53 L56 46 L50 52 H14 L8 46 Z M22 34 V25 H39 L43 34 M39 28 H56"/><circle cx="19" cy="44" r="3"/><circle cx="32" cy="44" r="3"/><circle cx="45" cy="44" r="3"/>',
		"ranged":'<path d="M21 11 Q52 32 21 53 L21 11 M10 32 H53 M45 25 L53 32 L45 39"/>',
		"balloon":'<path d="M32 8 C8 8 12 35 24 43 H40 C52 35 56 8 32 8 Z M24 43 L27 54 H37 L40 43 M32 8 Q19 25 28 43 M32 8 Q45 25 36 43"/>',
		"ship":'<path d="M8 39 H56 L48 51 H19 Z M19 39 V27 H45 V39 M28 27 V18 H38 V27 M33 18 V10 M7 56 Q15 51 23 56 T39 56 T55 56"/>',
		"unknown":'<path d="M24 21 Q26 10 38 15 Q50 22 37 31 Q32 34 32 40 M32 48 V50"/>'
	}
	var svg:='<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><g fill="none" stroke="#%s" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % [color.to_html(false),paths.get(kind,paths.army)]
	var image:=Image.new();image.load_svg_from_string(svg,float(pixels)/64.0)
	symbols[cache_key]=ImageTexture.create_from_image(image);return symbols[cache_key]

static func illustration_path(type_id:String)->String:
	return String(manifest().get(type_id,{}).get("path",""))

static func role_symbol(type_id:String,service:String)->String:
	if "balloon" in type_id or "airship" in type_id:return "balloon"
	if service=="navy":return "ship"
	if service=="air":return "air"
	if "tank" in type_id or "armored" in type_id or "mechanized" in type_id:return "armor"
	if "cavalry" in type_id or "horse" in type_id or "chariot" in type_id or "elephant" in type_id:return "mounted"
	if "artillery" in type_id or "siege" in type_id or "bombard" in type_id or "rocket" in type_id:return "artillery"
	if "bow" in type_id or "skirmish" in type_id or "sling" in type_id:return "ranged"
	return "army"

func portrait(type_id:String,service:String,unknown:bool=false)->Control:
	var image:=Painting.new()
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE;image.clip_contents=true
	if unknown:
		image.contain=true
		image.texture=symbol("unknown",COLORS[service]);image.tooltip_text="Awaiting a formation report"
		return image
	var path:=illustration_path(type_id)
	var assignment:Dictionary=manifest().get(type_id,{})
	var focal:Array=assignment.get("focus",[.5,.5])
	image.focus=Vector2(float(focal[0]),float(focal[1]))
	image.contain=bool(assignment.get("contain",false))
	if not path.is_empty() and ResourceLoader.exists(path):
		image.texture=load(path)
		image.tooltip_text="Painted role illustration. Actual personnel, equipment and training are listed alongside."
	else:
		# Unknown legacy types use a neutral role insignia; named catalogue types require their own art.
		image.texture=null
		var shade:=ColorRect.new();shade.color=Color(0.025,0.06,0.075,.7);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
		image.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var badge:=TextureRect.new();badge.texture=symbol(role_symbol(type_id,service),COLORS[service])
		badge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;badge.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;image.add_child(badge)
		badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);badge.offset_left=22;badge.offset_right=-22;badge.offset_top=22;badge.offset_bottom=-22
		image.tooltip_text="Role insignia. Actual equipment is listed alongside."
	return image
