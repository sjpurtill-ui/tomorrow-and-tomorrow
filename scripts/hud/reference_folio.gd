extends RefCounted
## The approved Wealth reference, expressed as live UI rather than a screenshot.
## Prototype geometry is shared only by the rail and page shell.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Approved:=preload("res://scripts/hud/approved_ui_art.gd")
const RAIL_WIDTH:=78.0
const TOP_HEIGHT:=45.0
const OLIVE:=Color("29372f")
const GOLD:=Color("c5b582")
const RAIL_TEXT:=Color("eee4c9")
const RULE:=Color("a59a80")

static func page_width(view_width:float)->float:
	return minf(maxf(320.0,view_width*0.567),view_width-RAIL_WIDTH)

static func paper()->ColorRect:
	var surface:=ColorRect.new();surface.name="FolioPaper"
	surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shader:=Shader.new()
	shader.code="""shader_type canvas_item;
render_mode unshaded;
uniform vec4 paper_color : source_color = vec4(0.947, 0.916, 0.855, 1.0);
float grain(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 p = FRAGCOORD.xy;
	float fleck = (grain(p) - 0.5) * 0.032;
	float cloud = (grain(floor(p / 17.0)) - 0.5) * 0.009;
	float fibre = sin(p.x * 0.16 + sin(p.y * 0.037) * 6.0) * 0.003;
	COLOR = vec4(paper_color.rgb + vec3(fleck + cloud + fibre), 1.0);
}"""
	var material:=ShaderMaterial.new();material.shader=shader
	material.set_shader_parameter("paper_color",T.PAPER if T.color_mode=="dark" else Color("f2ebdc"))
	surface.material=material
	return surface

static func rail_icon(id:String)->Control:
	var slots:={"settlement":0,"overview":1,"economy":2,"materials":3,"wealth":4,"construction":5,"production":6,"civ":7,"military":8}
	if slots.has(id):
		var icon:=Approved.icon(int(slots[id]));icon.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		return icon
	if id=="court":return Approved.symbol(Rect2(14,7,48,45),40,40)
	var icon:=preload("res://scripts/hud/hud_chrome_icon.gd").new(id)
	icon.set_icon_color(GOLD);icon.custom_minimum_size=Vector2(40,40)
	return icon

static func rail_style(active:bool,hover:=false)->StyleBoxFlat:
	var style:=T.flat(Color("777449") if active else Color("485143") if hover else Color.TRANSPARENT)
	style.border_color=Color("b7a265")
	style.border_width_top=1 if active else 0;style.border_width_bottom=1 if active else 0
	return style

static func page_style()->StyleBoxFlat:
	var style:=T.flat(Color.TRANSPARENT)
	style.border_color=RULE;style.border_width_right=1
	return style
