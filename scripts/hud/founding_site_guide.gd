extends Control
## A compact review on the actual terrain, with projected site/water markers.
const Advice:=preload("res://scripts/founding_site_advice.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const SurveyVisuals:=preload("res://scripts/hud/resource_survey_card.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const RESOURCE_RADIUS_KM:=18.0
var terrain:Node3D
var panel:PanelContainer
var body:VBoxContainer
var scroll:ScrollContainer
var heading:Label
var source:Label
var meter:ProgressBar
var meter_label:Label
var water_card:PanelContainer
var neighbor_heading:Label
var neighbor_label:Label
var neighbor_badge:Label
var resource_grid:GridContainer
var resource_empty:Label
var resource_cards:Array[Dictionary]=[]
var nearby_resources:Array[Dictionary]=[]
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
	theme=T.control_theme()
	# The full-size root projects markers onto the map; it is not a modal report.
	# Opt out of the shared report fitter before its deferred layer callback runs.
	set_meta("responsive_scroll_layout",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel=PanelContainer.new();panel.name="SiteReview";panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var style:=T.flat(T.PANEL_BG_SOLID,T.BORDER,1,6,16)
	panel.add_theme_stylebox_override("panel",style);add_child(panel)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",9);panel.add_child(root)
	var top:=HBoxContainer.new();root.add_child(top)
	var title:=Label.new();title.text="SETTLEMENT SITE";title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_theme_font_size_override("font_size",18);top.add_child(title)
	var close:=Button.new();close.text="×";close.custom_minimum_size=Vector2(36,32);close.tooltip_text="Close site review · Escape";close.pressed.connect(_close);top.add_child(close)
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
	water_card=_card(body,Advice.GOOD)
	var water_column:=VBoxContainer.new();water_column.add_theme_constant_override("separation",5);water_card.add_child(water_column)
	var water_row:=HBoxContainer.new();water_row.add_theme_constant_override("separation",9);water_column.add_child(water_row)
	_icon(water_row,Icons.texture_for("Freshwater"),38)
	var water_copy:=VBoxContainer.new();water_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;water_copy.add_theme_constant_override("separation",1);water_row.add_child(water_copy)
	heading=_label(water_copy,16);source=_label(water_copy,12)
	meter_label=_label(water_row,18);meter_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;meter_label.custom_minimum_size.x=54
	meter=ProgressBar.new();meter.custom_minimum_size.y=6;meter.show_percentage=false;water_column.add_child(meter)
	var neighbor_card:=_card(body,Color("607c78"))
	var neighbor_row:=HBoxContainer.new();neighbor_row.add_theme_constant_override("separation",9);neighbor_card.add_child(neighbor_row)
	_icon(neighbor_row,SurveyVisuals.symbol("flag",Color("9eb5af")),32)
	var neighbor_copy:=VBoxContainer.new();neighbor_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;neighbor_copy.add_theme_constant_override("separation",1);neighbor_row.add_child(neighbor_copy)
	neighbor_heading=_label(neighbor_copy,10);neighbor_heading.text="NEIGHBORS"
	neighbor_label=_label(neighbor_copy,12)
	neighbor_badge=_label(neighbor_row,10);neighbor_badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;neighbor_badge.custom_minimum_size.x=48
	var resource_header:=HBoxContainer.new();body.add_child(resource_header)
	var resource_title:=_label(resource_header,10);resource_title.text="SEEN NEARBY";resource_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var resource_radius:=_label(resource_header,10);resource_radius.text="≤ %d KM" % roundi(RESOURCE_RADIUS_KM);resource_radius.add_theme_color_override("font_color",T.MUTED)
	resource_grid=GridContainer.new();resource_grid.columns=2;resource_grid.add_theme_constant_override("h_separation",7);resource_grid.add_theme_constant_override("v_separation",7);body.add_child(resource_grid)
	resource_empty=_label(body,12);resource_empty.text="No resource reports nearby"
	var site_header:=HBoxContainer.new();body.add_child(site_header)
	var site_title:=_label(site_header,10);site_title.text="MARKED SITES";site_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	search_status=_label(site_header,10);search_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	options=HBoxContainer.new();options.add_theme_constant_override("separation",8);body.add_child(options)
	var find_sites:=Button.new();find_sites.text="↻  Scan nearby";find_sites.add_theme_font_size_override("font_size",12);find_sites.custom_minimum_size.y=30;find_sites.pressed.connect(_search);body.add_child(find_sites)
	action=Button.new();action.custom_minimum_size.y=42;action.add_theme_font_size_override("font_size",14);action.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;action.pressed.connect(_act);root.add_child(action)
	update_site(position)
	_layout()
	_search()

func _label(parent:Node,font_size:int)->Label:
	var label:=Label.new()
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",T.BODY);parent.add_child(label);return label

func _card(parent:Node,accent:Color)->PanelContainer:
	var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",T.flat(Color("14262b"),accent.darkened(.45),1,6,9));parent.add_child(card);return card

func _icon(parent:Node,texture:Texture2D,side:int)->TextureRect:
	var icon:=TextureRect.new();icon.texture=texture;icon.custom_minimum_size=Vector2(side,side)
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(icon);return icon

func _layout()->void:
	var view:=get_viewport_rect().size
	if view==layout_size:return
	layout_size=view
	var width:=minf(350.0,view.x-120.0)
	panel.size=Vector2(width,minf(460.0,view.y-198.0))
	panel.position=Vector2(view.x-width-18.0,108.0)
	panel.get_child(0).custom_minimum_size.x=width-32.0

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
	var accent:Color=selected.color
	water_card.add_theme_stylebox_override("panel",T.flat(Color("14262b"),accent.darkened(.45),1,6,9))
	heading.text="WATER NEARBY" if bool(selected.get("water_recommended",false)) else String(selected.title)
	heading.add_theme_color_override("font_color",accent)
	source.text=String(selected.get("source_text","Fresh water · not confirmed"))
	meter_label.text="%d%%" % roundi(minf(1.0,float(selected.household_ratio))*100.0)
	meter.value=minf(1.0,float(selected.household_ratio))*100.0
	var neighbors:Dictionary=selected.neighbors
	var neighbor_color:=Advice.BLOCKED if float(neighbors.penalty)>=.35 else (Advice.CAUTION if float(neighbors.penalty)>0 else Color("a3b7b0"))
	var affected:Array=neighbors.get("affected",[])
	neighbor_label.text="None reported within 30 km" if affected.is_empty() else "%s · %.1f km" % [String(affected[0].get("city_name","Reported city")),float(affected[0].get("distance_km",0.0))]
	neighbor_label.add_theme_color_override("font_color",neighbor_color)
	neighbor_badge.text="CLEAR" if affected.is_empty() else "RISK"
	neighbor_badge.add_theme_color_override("font_color",neighbor_color)
	neighbor_label.tooltip_text=String(neighbors.get("text","Returned reports only."));neighbor_badge.tooltip_text=neighbor_label.tooltip_text
	water_card.tooltip_text=String(selected.get("reason",""));source.tooltip_text=water_card.tooltip_text;meter.tooltip_text=water_card.tooltip_text
	var fill:=StyleBoxFlat.new();fill.bg_color=accent;meter.add_theme_stylebox_override("fill",fill)
	_refresh_resources()
	action.disabled=not bool(selected.valid)
	if not bool(selected.valid):action.text="CHOOSE ANOTHER SITE"
	elif later_city:action.text="REVIEW CONVOY TO THIS SITE"
	elif selected_suggestion:action.text="MOVE CONVOY TO THIS SITE"
	elif float(neighbors.penalty)>0:action.text="FOUND HERE · PROVOKE NEIGHBOR"
	else:action.text="FOUND HERE" if bool(selected.water_recommended) else "FOUND HERE · WATER HAULING NEEDED"
	queue_redraw()

func _refresh_resources()->void:
	nearby_resources.clear();resource_cards.clear()
	for child:Node in resource_grid.get_children():resource_grid.remove_child(child);child.queue_free()
	var nearest_by_resource:Dictionary={}
	for entry:Dictionary in ResourceSystem.lens_entries(selected.position,RESOURCE_RADIUS_KM):
		var resource:=String(entry.get("resource",""))
		if resource in ["","Freshwater"]:continue
		if not nearest_by_resource.has(resource) or float(entry.distance_km)<float(nearest_by_resource[resource].distance_km):nearest_by_resource[resource]=entry
	for value:Variant in nearest_by_resource.values():nearby_resources.append(value as Dictionary)
	nearby_resources.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.distance_km)<float(b.distance_km))
	if nearby_resources.size()>4:nearby_resources.resize(4)
	resource_empty.visible=nearby_resources.is_empty()
	for entry:Dictionary in nearby_resources:
		var chip:=_card(resource_grid,Color("557a73"));chip.custom_minimum_size.y=47
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);chip.add_child(row)
		_icon(row,Icons.texture_for(String(entry.resource)),28)
		var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",0);row.add_child(copy)
		var name_label:=_label(copy,11);name_label.text=ResourceSystem.display_name(String(entry.resource));name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;name_label.autowrap_mode=TextServer.AUTOWRAP_OFF
		var stage:="surveyed" if String(entry.get("knowledge",""))=="surveyed" else "seen"
		var detail:=_label(copy,9);detail.text="%.1f km · %s" % [float(entry.distance_km),stage];detail.add_theme_color_override("font_color",T.TEXT_SOFT)
		var blockers:Array=entry.get("blockers",[]) as Array
		var access_note:=String(blockers.front()) if not blockers.is_empty() else String(entry.get("access",""))
		chip.tooltip_text="Known from returned scouting or travel reports. "+access_note
		resource_cards.append({"resource":String(entry.resource),"card":chip,"distance":float(entry.distance_km),"knowledge":stage})

func _search()->void:
	var origin:Vector3=selected.position
	sites=terrain._founding_advisor().suggestions(origin,later_city)
	for child:Node in options.get_children():options.remove_child(child);child.queue_free()
	search_status.text="%d found" % sites.size()
	if sites.is_empty():search_status.text="None confirmed"
	for index:int in sites.size():
		var choose:=Button.new();choose.text="%d · %.1f km" % [index+1,float(sites[index].travel_distance_km)];choose.custom_minimum_size.y=34;choose.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choose.pressed.connect(_select.bind(index));options.add_child(choose)
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
