extends Control
## A compact review on the actual terrain, with projected site/water markers.
const Advice:=preload("res://scripts/founding_site_advice.gd")
var terrain:Node3D
var panel:PanelContainer
var heading:Label
var source:Label
var explanation:Label
var meter:ProgressBar
var meter_label:Label
var neighbor_label:Label
var action:Button
var options:HBoxContainer
var search_status:Label
var selected:Dictionary={}
var sites:Array[Dictionary]=[]
var later_city:=false
var selected_suggestion:=false
var update_elapsed:=0.0
var layout_size:=Vector2.ZERO
var drawn_labels:Array[Rect2]=[]

func setup(world:Node3D,position:Vector3,is_later:bool)->void:
	terrain=world;later_city=is_later
	name="FoundingSiteGuide";mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel=PanelContainer.new();panel.name="SiteReview";panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var style:=StyleBoxFlat.new();style.bg_color=Color("101e23f5");style.border_color=Color("618e87");style.set_border_width_all(1);style.set_corner_radius_all(6);style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel",style);add_child(panel)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",7);panel.add_child(root)
	var top:=HBoxContainer.new();root.add_child(top)
	var title:=Label.new();title.text="SETTLEMENT SITE";title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title)
	var close:=Button.new();close.text="×";close.custom_minimum_size=Vector2(36,32);close.tooltip_text="Close site review · Escape";close.pressed.connect(_close);top.add_child(close)
	heading=_label(root,19);source=_label(root,14);explanation=_label(root,14)
	meter_label=_label(root,12)
	meter=ProgressBar.new();meter.custom_minimum_size.y=8;meter.show_percentage=false;root.add_child(meter)
	neighbor_label=_label(root,13)
	search_status=_label(root,12)
	options=HBoxContainer.new();options.add_theme_constant_override("separation",8);root.add_child(options)
	var find_sites:=Button.new();find_sites.text="SHOW NEARBY SUITABLE SITES";find_sites.custom_minimum_size.y=34;find_sites.pressed.connect(_search);root.add_child(find_sites)
	action=Button.new();action.custom_minimum_size.y=42;action.pressed.connect(_act);root.add_child(action)
	update_site(position)
	_layout()
	_search()

func _label(parent:Node,font_size:int)->Label:
	var label:=Label.new()
	# Establish wrapping width before assigning text; zero-width labels otherwise
	# cache a many-thousand-pixel minimum height on the first container pass.
	label.custom_minimum_size.x=minf(380.0,get_viewport_rect().size.x-120.0)-32.0
	label.size.x=label.custom_minimum_size.x
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",Color("d9e2df"));parent.add_child(label);return label

func _layout()->void:
	var view:=get_viewport_rect().size
	if view==layout_size:return
	layout_size=view
	var width:=minf(380.0,view.x-120.0)
	panel.size.x=width
	panel.position=Vector2(view.x-width-18.0,108.0)
	panel.get_child(0).custom_minimum_size.x=width-32.0
	for child:Node in panel.get_child(0).get_children():
		if child is Label:child.custom_minimum_size.x=width-32.0;child.size.x=width-32.0
	panel.reset_size()

func update_site(position:Vector3,suggestion:bool=false,siting:Dictionary={})->void:
	selected=terrain._founding_site_advice(position)
	selected["position"]=position
	selected_suggestion=suggestion
	if later_city:
		if siting.is_empty():siting=terrain._settlement_convoy_site_assessment(position)
		if not bool(siting.get("valid",false)):
			selected.valid=false;selected.color=Advice.BLOCKED;selected.reason=String(siting.reason)
	_refresh()

func _refresh()->void:
	heading.text=String(selected.title);heading.add_theme_color_override("font_color",selected.color)
	source.text=String(selected.get("source_text","Fresh water · not confirmed"))
	explanation.text=String(selected.reason)
	meter_label.text="HOUSEHOLDS MEET %d%% OF DRINKING NEEDS" % roundi(minf(1.0,float(selected.household_ratio))*100.0)
	meter.value=minf(1.0,float(selected.household_ratio))*100.0
	var neighbors:Dictionary=selected.neighbors
	neighbor_label.text="%s\n%s" % [String(neighbors.title),String(neighbors.text)]
	neighbor_label.add_theme_color_override("font_color",Advice.BLOCKED if float(neighbors.penalty)>=.35 else (Advice.CAUTION if float(neighbors.penalty)>0 else Color("a3b7b0")))
	var fill:=StyleBoxFlat.new();fill.bg_color=selected.color;meter.add_theme_stylebox_override("fill",fill)
	action.disabled=not bool(selected.valid)
	if not bool(selected.valid):action.text="CHOOSE ANOTHER SITE"
	elif later_city:action.text="REVIEW CONVOY TO THIS SITE"
	elif selected_suggestion:action.text="MOVE CONVOY TO THIS SITE"
	elif float(neighbors.penalty)>0:action.text="FOUND HERE · PROVOKE NEIGHBOR"
	else:action.text="FOUND HERE" if bool(selected.water_recommended) else "FOUND HERE · WATER HAULING NEEDED"
	panel.reset_size.call_deferred()
	queue_redraw()

func _search()->void:
	var origin:Vector3=selected.position
	sites=terrain._founding_advisor().suggestions(origin,later_city)
	for child:Node in options.get_children():options.remove_child(child);child.queue_free()
	search_status.text="Green = nearby water, dry ground, no known city within 30 km."
	if sites.is_empty():search_status.text="No site with nearby water and no known border friction found within 12 km. Compare the tradeoffs or scout further."
	for index:int in sites.size():
		var choose:=Button.new();choose.text="%d · %.1f km" % [index+1,float(sites[index].travel_distance_km)];choose.custom_minimum_size.y=34;choose.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choose.pressed.connect(_select.bind(index));options.add_child(choose)
	panel.reset_size.call_deferred()
	queue_redraw()

func _select(index:int)->void:
	var position:Vector3=sites[index].position
	update_site(position,true)
	terrain._set_camera_target(position)
	# Use the agreed 50,000-foot view so a continental zoom cannot hide the pins.
	terrain.set_camera_distance_level(1)

func _act()->void:
	var position:Vector3=selected.position
	if later_city:terrain._begin_settlement_convoy(position);return
	if selected_suggestion:
		terrain._close_founding_site_guide()
		terrain._move_settlers_to(position)
		return
	# The convoy can move while review is open. Founding validates its current
	# exact position again, including whether this review still matches it.
	if terrain.settler_marker.position.distance_to(position)>.025:
		update_site(terrain.settler_marker.position);return
	terrain._start_settlement_here()

func _close()->void:
	if later_city:terrain._cancel_settlement_convoy_targeting()
	else:terrain._close_founding_site_guide()

func _process(delta:float)->void:
	_layout()
	update_elapsed+=delta
	if update_elapsed>=.25:
		update_elapsed=0.0
		if not later_city and not selected_suggestion and terrain.settler_marker:update_site(terrain.settler_marker.position)
	queue_redraw()

func _draw()->void:
	if not is_instance_valid(terrain) or not is_instance_valid(terrain.camera):return
	drawn_labels.clear()
	for index:int in sites.size():_marker(sites[index].position,"%d · NEAR WATER" % (index+1),Advice.GOOD)
	if selected.has("source_position"):
		var position:Vector3=selected.position
		var water:Vector3=selected.source_position
		if not terrain.camera.is_position_behind(position) and not terrain.camera.is_position_behind(water):
			draw_dashed_line(terrain.camera.unproject_position(position),terrain.camera.unproject_position(water),Color("6bcddd"),2,6)
		_marker(water,"FRESH WATER",Color("6bcddd"))
	if not selected.is_empty():_marker(selected.position,"SELECTED SITE",selected.color)

func _marker(position:Vector3,text:String,color:Color)->void:
	if terrain.camera.is_position_behind(position):return
	var point:Vector2=terrain.camera.unproject_position(position)
	if not get_viewport_rect().has_point(point) or panel.get_rect().has_point(point):return
	draw_circle(point,11,Color("0b191e"));draw_arc(point,11,0,TAU,32,color,2,true);draw_circle(point,4,color)
	var font:=ThemeDB.fallback_font
	var label_size:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13)
	var label_position:=point+Vector2(16,-10)
	label_position.x=clampf(label_position.x,90,get_viewport_rect().size.x-label_size.x-10)
	for attempt:int in 12:
		var rect:=Rect2(label_position-Vector2(4,14),label_size+Vector2(8,5))
		var clear:=not rect.intersects(panel.get_rect()) and rect.position.y>90 and rect.end.y<get_viewport_rect().size.y-55
		for occupied:Rect2 in drawn_labels:
			if rect.intersects(occupied.grow(3)):clear=false;break
		if clear:
			drawn_labels.append(rect)
			if attempt>0:draw_line(point,label_position-Vector2(5,5),color,1,true)
			draw_style_box(_marker_style(),rect)
			draw_string(font,label_position,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
			return
		label_position.y=point.y+float((attempt/2)+1)*24.0*(1.0 if attempt%2==0 else -1.0)

func _marker_style()->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("0b191eee");return style
