extends RefCounted
## The approved Wealth reference, expressed as live UI rather than a screenshot.
## Prototype geometry is shared only by the rail and page shell.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Approved:=preload("res://scripts/hud/approved_ui_art.gd")
const RAIL_WIDTH:=44.0
const RAIL_BUTTON_HEIGHT:=44.0
const RAIL_ICON_SIZE:=24.0
const TOP_HEIGHT:=45.0
const OLIVE:=Color("29372f")
const GOLD:=Color("c5b582")
const RAIL_TEXT:=Color("eee4c9")
const RULE:=Color("a59a80")

## Room kept at the right for the notice column (order_stack.gd WIDTH 340,
## the edge margin and a gap): on a wide window the page runs up to it, so
## the notices and a strip of map stay in view beside the page.
const NOTICE_ROOM:=340.0+T.EDGE_MARGIN+14.0
## From this canvas width (1600 px at 125%) the page takes the window up to
## the notice column. On smaller windows the open page uses the available room.
const WIDE_FROM:=1280.0
## Reading distance should not grow with an ultrawide monitor. Extra room
## belongs to the living map; internal page layouts use compact task groups.
const MAX_PAGE_WIDTH:=1120.0

## A 1280 px canvas gives 838 px; larger canvases stop at 1120 px so
## related information remains within one comfortable reading area.
static func page_width(view_width:float)->float:
	var share:=minf(maxf(320.0,view_width*0.567),view_width-RAIL_WIDTH)
	if view_width<WIDE_FROM:return maxf(240.0,view_width-RAIL_WIDTH-T.EDGE_MARGIN)
	return minf(MAX_PAGE_WIDTH,maxf(share,view_width-RAIL_WIDTH-NOTICE_ROOM))

static func paper()->ColorRect:
	var surface:=ColorRect.new();surface.name="FolioPaper"
	surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shader:=Shader.new()
	shader.code="""shader_type canvas_item;
render_mode unshaded;
uniform vec4 paper_color : source_color = vec4(0.067, 0.118, 0.157, 1.0);
void fragment() {
	COLOR = paper_color;
}"""
	var material:=ShaderMaterial.new();material.shader=shader
	material.set_shader_parameter("paper_color",T.PAPER)
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
	style.border_color=T.RULE;style.border_width_right=1
	return style
