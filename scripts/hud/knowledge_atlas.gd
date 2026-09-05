extends Control
const Data:=preload("res://scripts/hud/atlas_data.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const GOLD:=Color("d7bd80")
const INK:=Color("e4e9e3")
const MUTED:=Color("8b999e")
var mode:="inquiry"
var terrain:Node
var hud:Node
var layer:CanvasLayer
var plot:AtlasPlot
var records:Array[Dictionary]=[]
var selected_id:=""
var domain:=""
var query:=""
var detail:Label
var action:Button
var legend:Label
var filter:OptionButton
var elapsed:=0.0
var revision:=""
static func open(terrain_node:Node,hud_node:Node,kind:String)->void:
	var old:Variant=hud_node.get_meta("knowledge_atlas") if hud_node.has_meta("knowledge_atlas") else null
	if is_instance_valid(old): old.queue_free()
	var canvas:=CanvasLayer.new();canvas.layer=88;hud_node.add_child(canvas)
	hud_node.set_meta("knowledge_atlas",canvas)
	var view:=new();view.mode=kind;view.domain="nutrition" if kind=="inquiry" else "";view.terrain=terrain_node;view.hud=hud_node;view.layer=canvas
	canvas.add_child(view)
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background:=ColorRect.new();background.color=Color("101e25");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,18)
	add_child(margin)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",10);margin.add_child(box)
	var header:=HBoxContainer.new();box.add_child(header)
	var title:=Label.new();title.text="THE TREE OF INQUIRY" if mode=="inquiry" else "MATERIALS · "+String(SettlementModel.selected_settlement().get("name","Our settlement"));title.add_theme_font_size_override("font_size",24);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;header.add_child(title)
	button(header,"Ledger",_ledger);button(header,"Close",_close)
	var controls:=HBoxContainer.new();box.add_child(controls)
	filter=OptionButton.new();filter.add_item("All branches" if mode=="inquiry" else "All materials")
	var groups:Array=GameState.research_allocations.keys() if mode=="inquiry" else ["Organic","Land & water","Stone, earth & metals","Unknown"]
	for id in groups: filter.add_item(String(id).capitalize());filter.set_item_metadata(filter.item_count-1,id)
	for index in filter.item_count:
		if filter.get_item_metadata(index)==domain:filter.select(index)
	filter.item_selected.connect(func(index:int)->void: domain="" if index==0 else String(filter.get_item_metadata(index));refresh(true))
	controls.add_child(filter)
	var search:=LineEdit.new();search.placeholder_text="Search known names";search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_child(search)
	search.text_changed.connect(func(value:String)->void: query=value;refresh(true))
	button(controls,"−",func()->void: plot.zoom_at(.8,plot.size*.5));button(controls,"+",func()->void: plot.zoom_at(1.25,plot.size*.5));button(controls,"Fit",func()->void: plot.fit())
	button(controls,"Previous",func()->void: step(-1));button(controls,"Next",func()->void: step(1))
	legend=Label.new();legend.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;legend.add_theme_font_size_override("font_size",12);legend.modulate=MUTED;box.add_child(legend)
	plot=AtlasPlot.new();plot.owner_view=self;plot.size_flags_vertical=Control.SIZE_EXPAND_FILL;plot.custom_minimum_size=Vector2(0,130);box.add_child(plot)
	detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size.y=66;detail.add_theme_font_size_override("font_size",14);box.add_child(detail)
	var actions:=HBoxContainer.new();box.add_child(actions)
	action=button(actions,"Choose a question",_act)
	if mode=="inquiry": button(actions,"Direct attention",func()->void: _close();hud.open_dock("inquiry",0))
	else:
		button(actions,"Local logistics",func()->void: var result:=GovernmentPeopleSystem.set_settlement_focus(GameState.selected_player_settlement_id,"logistics");detail.text=String(result.get("label",result.get("reason","Logistics focus set"))))
		button(actions,"Resource map",func()->void: _close();hud._on_layer_toggle("resources"))
	refresh(true)
func button(parent:Node,text:String,callback:Callable)->Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=32;b.pressed.connect(callback);parent.add_child(b);return b
func _close()->void:
	layer.queue_free()
func _ledger()->void:
	_close();hud.open_dock("inquiry" if mode=="inquiry" else "economy",1,false)
func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: _close();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed<.75:return
	elapsed=0
	var next:=str(int(GameState.elapsed_days))+str(GameState.discovery_progress)+str(GameState.research_targets)+str(GameState.selected_player_settlement_id)
	if next!=revision: revision=next;refresh(false)
func refresh(refit:bool)->void:
	if mode=="inquiry": records=Data.inquiry(domain,query)
	else:
		records.assign(SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Array: return Data.materials()).filter(func(item:Dictionary)->bool: return (domain=="" or item.domain==domain) and (query=="" or String(item.name).to_lower().contains(query.to_lower()))))
	legend.text=("DISCOVERED = colored · AVAILABLE / RESEARCHING = outlined · LOCKED = gray. Lines are prerequisites. " if mode=="inquiry" else "Colored = recognized · gray = still unknown. Quantities are bulk units in the selected city. ")+"Drag to pan, wheel to zoom. %d entries." % records.size()
	plot.arrange()
	if refit: plot.call_deferred("fit")
	var found:=false
	for item:Dictionary in records:
		if item.id==selected_id: found=true;break
	if not found: selected_id=String(records[0].id) if not records.is_empty() else ""
	select(selected_id)
func select(id:String)->void:
	selected_id=id;plot.queue_redraw()
	for item:Dictionary in records:
		if item.id!=id:continue
		detail.text="%s · %s
%s" % [item.name,item.status,item.description]
		if mode=="inquiry":
			var effects:Array[String]=[]
			for effect:String in item.effects:effects.append("%s %+.1f%%" % [DiscoverySystem.EFFECT_DISPLAY_NAMES.get(effect,effect.replace("_"," ")),float(item.effects[effect])*100])
			if not effects.is_empty():detail.text+="\n"+" · ".join(effects)
			if not item.missing.is_empty(): detail.text+=" Waiting for: "+", ".join(item.missing)
			action.text="Research this question" if bool(item.ready) else "Already discovered" if item.known else "Gather more evidence"
			action.disabled=not bool(item.ready)
		else:
			action.text="Inspect material accounts";action.disabled=false
		return
	detail.text="No matching entries. Clear the search or choose another branch.";action.disabled=true
func step(direction:int)->void:
	if records.is_empty():return
	var index:=0
	for i in records.size():
		if records[i].id==selected_id:index=i;break
	select(String(records[posmod(index+direction,records.size())].id));plot.center_selected()
func _act()->void:
	if mode!="inquiry":_ledger();return
	var result:=DiscoverySystem.select_research_target(selected_id)
	refresh(false)
	if not bool(result.get("ok",false)):detail.text=String(result.get("reason","Not currently researchable"))
class AtlasPlot extends Control:
	var owner_view:Control
	var boxes:Dictionary={}
	var center:=Vector2.ZERO
	var zoom_level:=1.0
	var dragging:=false
	var press:=Vector2.ZERO
	var moved:=false
	const CARD:=Vector2(238,104)
	func _ready()->void:
		clip_contents=true;mouse_default_cursor_shape=Control.CURSOR_DRAG;focus_mode=Control.FOCUS_ALL
		resized.connect(func()->void: arrange();fit())
	func arrange()->void:
		boxes.clear()
		var rows:Dictionary={};var levels:Dictionary={}
		for item:Dictionary in owner_view.records:levels[item.id]=0
		if owner_view.mode=="inquiry":
			for iteration in 24:
				var changed:=false
				for item:Dictionary in owner_view.records:
					var depth:=0
					for req in item.requires:
						if levels.has(req):depth=maxi(depth,mini(24,int(levels[req])+1))
					if levels[item.id]!=depth:levels[item.id]=depth;changed=true
				if not changed:break
		for index in owner_view.records.size():
			var item:Dictionary=owner_view.records[index]
			var columns:=clampi(floori(size.x/270),2,4)
			var col:int=int(levels[item.id]) if owner_view.mode=="inquiry" else index%columns
			var row:int=int(rows.get(col,0)) if owner_view.mode=="inquiry" else index/columns
			rows[col]=row+1;boxes[item.id]=Rect2(Vector2(col*300,row*140),CARD)
		queue_redraw()
	func fit()->void:
		if boxes.is_empty():queue_redraw();return
		var bounds:Rect2=boxes.values()[0]
		for rect:Rect2 in boxes.values():bounds=bounds.merge(rect)
		center=bounds.get_center();zoom_level=clampf(minf(size.x/(bounds.size.x+60),size.y/(bounds.size.y+60)),.22,1.0);queue_redraw()
	func at(point:Vector2)->Vector2:return (point-center)*zoom_level+size*.5
	func zoom_at(factor:float,anchor:Vector2)->void:
		var world:Vector2=(anchor-size*.5)/zoom_level+center;zoom_level=clampf(zoom_level*factor,.18,2.0);center=world-(anchor-size*.5)/zoom_level;queue_redraw()
	func center_selected()->void:
		if boxes.has(owner_view.selected_id):center=boxes[owner_view.selected_id].get_center();zoom_level=maxf(.8,zoom_level);queue_redraw()
	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseButton:
			if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:zoom_at(1.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.15,event.position);accept_event()
			elif event.button_index==MOUSE_BUTTON_LEFT:
				if event.pressed:dragging=true;press=event.position;moved=false;grab_focus()
				else:
					dragging=false
					if not moved:
						var world:Vector2=(event.position-size*.5)/zoom_level+center
						for id:String in boxes:
							if boxes[id].has_point(world):owner_view.select(id);break
				accept_event()
		elif event is InputEventMouseMotion and dragging:center-=event.relative/zoom_level;moved=moved or event.position.distance_to(press)>4;queue_redraw();accept_event()
		elif event is InputEventKey and event.pressed and event.keycode in [KEY_RIGHT,KEY_LEFT]:owner_view.step(1 if event.keycode==KEY_RIGHT else -1);accept_event()
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("0b171e"))
		for x in range(0,int(size.x),40):draw_line(Vector2(x,0),Vector2(x,size.y),Color("14252c"))
		for y in range(0,int(size.y),40):draw_line(Vector2(0,y),Vector2(size.x,y),Color("14252c"))
		if owner_view.mode=="inquiry":
			for item:Dictionary in owner_view.records:
				for req in item.requires:
					if boxes.has(req):
						var a:=at(boxes[req].position+Vector2(CARD.x,CARD.y*.5));var b:=at(boxes[item.id].position+Vector2(0,CARD.y*.5))
						draw_line(a,b,Color("587681"),maxf(1,2*zoom_level),true)
		for item:Dictionary in owner_view.records:
			var rect:=Rect2(at(boxes[item.id].position),CARD*zoom_level)
			if not rect.intersects(Rect2(Vector2.ZERO,size)):continue
			var selected:bool=item.id==owner_view.selected_id
			var color:=Color("83b7a5") if item.known else Color("7d898c")
			draw_style_box(style(Color("253e40") if item.known else Color("202a30"),GOLD if selected else color,2 if selected else 1),rect)
			var icon:Texture2D=Icons.texture_for(item.id) if owner_view.mode!="inquiry" and item.known else Icons.domain_texture(String(item.domain),color) if owner_view.mode=="inquiry" else null
			if icon:draw_texture_rect(icon,Rect2(rect.position+Vector2(10,24)*zoom_level,Vector2(48,48)*zoom_level),false)
			var left:=66.0 if icon else 14.0
			var font:=ThemeDB.fallback_font
			draw_string(font,rect.position+Vector2(left,31)*zoom_level,String(item.name),HORIZONTAL_ALIGNMENT_LEFT,(CARD.x-left-10)*zoom_level,maxi(8,roundi(14*zoom_level)),INK)
			draw_string(font,rect.position+Vector2(left,54)*zoom_level,String(item.status),HORIZONTAL_ALIGNMENT_LEFT,(CARD.x-left-10)*zoom_level,maxi(7,roundi(10*zoom_level)),color)
			var note:="%d%% progress" % roundi(float(item.get("progress",0))*100) if owner_view.mode=="inquiry" and item.status=="RESEARCHING" else String(item.domain).capitalize() if owner_view.mode=="inquiry" else "%.1f stored · +%.1f/day" % [item.get("stock",0),item.get("flow",0)] if item.known else "Survey to learn more"
			draw_string(font,rect.position+Vector2(14,86)*zoom_level,note,HORIZONTAL_ALIGNMENT_LEFT,(CARD.x-28)*zoom_level,maxi(7,roundi(11*zoom_level)),MUTED)
	func style(fill:Color,border:Color,width:int)->StyleBoxFlat:
		var value:=StyleBoxFlat.new();value.bg_color=fill;value.border_color=border;value.set_border_width_all(width);value.set_corner_radius_all(7);return value

