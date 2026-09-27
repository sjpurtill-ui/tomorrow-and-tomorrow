extends Control
## The chart's key, in map help: each kind of place mark as the map draws it
## (resource_icons.settlement_atlas), with its meaning in plain words. Shown
## once the people have a home, since before that there is nothing to key.
const ICONS=preload("res://scripts/resource_icons.gd")
const Ownership=preload("res://scripts/map_ownership.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const ROW:=24.0
const MARK:=22.0
## A few peoples' colours shown in the stranger's row, so the key says that
## the colour is theirs.
const SAMPLE_TINTS:=[Color("ff9299"),Color("85bdeb"),Color("b5d77e")]

## Adds (or shows/hides) the key under the help text and keeps the panel's
## foot where it was, just above the help button.
static func attach(panel:Control,button:Control,shown:bool)->void:
	if panel==null or panel.get_child_count()==0:return
	var root:=panel.get_child(0) as Container
	if root==null:return
	var key:=root.get_node_or_null("MapLegend") as Control
	if key==null:
		if not shown:return
		key=load("res://scripts/hud/map_legend.gd").new();key.name="MapLegend"
		root.add_child(key)
	if key.visible!=shown:key.visible=shown
	panel.reset_size()
	if button!=null:panel.position.y=button.position.y-panel.get_combined_minimum_size().y-8.0

func _init()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size=Vector2(360,26+ROW*Ownership.LEGEND.size())

func _draw()->void:
	var atlas:=ICONS.settlement_atlas()
	var cell:=float(ICONS.SETTLEMENT_GLYPH_PX)
	var ui:=T.font("ui")
	draw_line(Vector2(0,4),Vector2(size.x,4),Color(T.BORDER_SOFT,.8),1.0)
	draw_string(ui,Vector2(0,20),"On the chart",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e7d8b8"))
	var y:=26.0
	for row:Dictionary in Ownership.LEGEND:
		var at:=Rect2(Vector2(4,y+1),Vector2(MARK,MARK))
		var index:=int(row.glyph)
		var source:=Rect2(Vector2(cell*index,0),Vector2(cell,cell))
		if index==ICONS.SETTLEMENT_GLYPH_FOREIGN:
			# One mark per sample people, each washed in its own colour.
			for k in SAMPLE_TINTS.size():
				draw_texture_rect_region(atlas,Rect2(at.position+Vector2(k*16.0,0),at.size),source,(SAMPLE_TINTS[k] as Color).lerp(Color.WHITE,.25))
		else:
			draw_texture_rect_region(atlas,at,source)
		if bool(row.get("home",false)):
			draw_arc(at.get_center(),MARK*.5+1.5,0,TAU,32,Color("#a88a4a"),1.6,true)
		var text_x:=4.0+MARK+(32.0 if index==ICONS.SETTLEMENT_GLYPH_FOREIGN else 0.0)+10.0
		draw_string(ui,Vector2(text_x,y+17),String(row.words),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#e7d8b8"))
		y+=ROW
