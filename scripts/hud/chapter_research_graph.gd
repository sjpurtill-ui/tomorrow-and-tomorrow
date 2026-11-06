extends GraphEdit
## Edges are the catalog's actual prerequisite relationships, including alternate
## routes. The selected question's detail explains ALL/ANY groups precisely.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
var by_id:Dictionary={}
var selected:Callable

func setup(rows:Array,callback:Callable,selection_id:String="")->void:
	name="BranchingResearchTree";selected=callback
	custom_minimum_size=Vector2(0,440);size_flags_horizontal=Control.SIZE_EXPAND_FILL
	minimap_enabled=false
	for property:Dictionary in get_property_list():
		if String(property.name) in ["show_grid_buttons","show_minimap_button","show_arrange_button"]:set(String(property.name),false)
	var locate:=Button.new();locate.text="Find selected";T.apply_button_style(locate);get_menu_hbox().add_child(locate)
	locate.pressed.connect(func()->void:
		var node:=get_node_or_null(NodePath(selection_id)) as GraphNode
		if node:scroll_offset=node.position_offset*zoom-Vector2(32,72)
	)
	add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.BORDER_SOFT,1,4,0))
	add_theme_color_override("grid_minor",T.BORDER_SOFT)
	add_theme_color_override("grid_major",T.BORDER_SOFT)
	for row:Dictionary in rows:by_id[String(row.id)]=row
	var depth:Dictionary={}
	for row:Dictionary in rows:_depth(String(row.id),depth,{})
	var ranks:Dictionary={}
	for row:Dictionary in rows:
		var id:=String(row.id);var layer:=int(depth.get(id,0));var rank:=int(ranks.get(layer,0));ranks[layer]=rank+1
		var node:=GraphNode.new();node.name=id;node.title=String(row.get("status","LOCKED"));node.tooltip_text=String(row.get("name",id));node.custom_minimum_size=Vector2(230,0);node.position_offset=Vector2(32+layer*290,72+rank*175);node.resizable=false;node.selected=id==selection_id
		node.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,T.BORDER_SOFT,1,5,8))
		node.add_theme_stylebox_override("titlebar",T.flat(T.ACTIVE_BG,T.BORDER_SOFT,1,5,8))
		node.add_theme_color_override("title_color",T.INK)
		add_child(node)
		var box:=VBoxContainer.new();node.add_child(box)
		var button:=Button.new();button.text=String(row.get("name",id));button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size=Vector2(210,48);T.apply_button_style(button);box.add_child(button);button.pressed.connect(func()->void:selected.call(id))
		var progress:=ProgressBar.new();progress.min_value=0;progress.max_value=100;progress.step=0.01;progress.value=100 if String(row.get("status",""))=="DISCOVERED" else float(row.get("progress",0))*100;progress.custom_minimum_size.y=20;box.add_child(progress)
		var label:=Label.new();label.text="Evidence · 0–100% · higher helps";label.add_theme_font_size_override("font_size",11);label.add_theme_color_override("font_color",T.INK);box.add_child(label)
		node.set_slot(0,true,0,T.GOLD,true,0,T.GOLD)
		if bool(row.get("external",false)):node.modulate=Color(0.8,0.85,0.9)
	for row:Dictionary in rows:
		for parent:String in row.get("parents",[]):
			if by_id.has(parent):connect_node(StringName(parent),0,StringName(String(row.id)),0)

func _depth(id:String,depth:Dictionary,visiting:Dictionary)->int:
	if depth.has(id):return int(depth[id])
	if visiting.has(id):return 0
	visiting[id]=true
	var value:=0
	for parent:String in by_id[id].get("parents",[]):
		if by_id.has(parent):value=maxi(value,_depth(parent,depth,visiting)+1)
	visiting.erase(id);depth[id]=value
	return value

func view_state()->Dictionary:
	return {"scroll":scroll_offset,"zoom":zoom,"ids":by_id.keys()}

func restore_view_state(state:Dictionary)->void:
	if state.get("ids",[])!=by_id.keys():return
	zoom=float(state.get("zoom",1.0))
	scroll_offset=state.get("scroll",Vector2.ZERO)
