extends Control
## A compact review on the actual terrain, with projected site/water markers.
const Advice:=preload("res://scripts/founding_site_advice.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const SurveyVisuals:=preload("res://scripts/hud/resource_survey_card.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Kit:=preload("res://scripts/hud/paper_kit.gd")
const RESOURCE_RADIUS_KM:=18.0
const WATER_MARK:=Color("3f7f95")
var terrain:Node3D
var panel:PanelContainer
var body:VBoxContainer
var scroll:ScrollContainer
var heading:Label
var source:Label
var meter:ProgressBar
var meter_label:Label
var meter_note:Label
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
	panel.add_theme_stylebox_override("panel",Kit.card_style(16.0));add_child(panel)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",9);panel.add_child(root)
	var top:=HBoxContainer.new();root.add_child(top)
	Kit.label(top,"Where to settle" if not later_city else "Land for a new settlement","title",Color(0,0,0,0),false).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var close:=Kit.quiet_button(top,"Close",_close,"Close the site review (Esc)");close.custom_minimum_size=Vector2(64,30)
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
	water_card=_card(body,Advice.GOOD)
	var water_column:=VBoxContainer.new();water_column.add_theme_constant_override("separation",5);water_card.add_child(water_column)
	var water_row:=HBoxContainer.new();water_row.add_theme_constant_override("separation",9);water_column.add_child(water_row)
	_icon(water_row,Icons.texture_for("Freshwater"),38)
	var water_copy:=VBoxContainer.new();water_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;water_copy.add_theme_constant_override("separation",1);water_row.add_child(water_copy)
	heading=_label(water_copy,16);heading.add_theme_font_override("font",T.font("ui_strong"));source=_wrapping(_label(water_copy,13),160)
	meter_label=_label(water_row,18);meter_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;meter_label.custom_minimum_size.x=58;meter_label.add_theme_color_override("font_color",T.INK)
	meter=ProgressBar.new();meter.custom_minimum_size.y=6;meter.show_percentage=false;water_column.add_child(meter)
	meter_note=_wrapping(_label(water_column,13),260);meter_note.add_theme_color_override("font_color",T.INK_MUTED)
	var neighbor_card:=_card(body,T.RULE)
	var neighbor_row:=HBoxContainer.new();neighbor_row.add_theme_constant_override("separation",9);neighbor_card.add_child(neighbor_row)
	_icon(neighbor_row,SurveyVisuals.symbol("flag",T.INK_MUTED),28)
	var neighbor_copy:=VBoxContainer.new();neighbor_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;neighbor_copy.add_theme_constant_override("separation",1);neighbor_row.add_child(neighbor_copy)
	neighbor_heading=_label(neighbor_copy,12);neighbor_heading.text="NEIGHBOURS";neighbor_heading.add_theme_color_override("font_color",T.INK_MUTED)
	neighbor_label=_wrapping(_label(neighbor_copy,14),150)
	neighbor_badge=_label(neighbor_row,13);neighbor_badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;neighbor_badge.custom_minimum_size.x=78
	var resource_header:=HBoxContainer.new();body.add_child(resource_header)
	var resource_title:=_label(resource_header,12);resource_title.text="SEEN WITHIN %d KM" % roundi(RESOURCE_RADIUS_KM);resource_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;resource_title.add_theme_color_override("font_color",T.INK_MUTED)
	resource_grid=GridContainer.new();resource_grid.columns=2;resource_grid.add_theme_constant_override("h_separation",7);resource_grid.add_theme_constant_override("v_separation",7);body.add_child(resource_grid)
	resource_empty=_label(body,14);resource_empty.text="Nobody has reported anything useful nearby yet."
	var site_header:=HBoxContainer.new();body.add_child(site_header)
	var site_title:=_label(site_header,12);site_title.text="GOOD PLACES NEAR WATER";site_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;site_title.add_theme_color_override("font_color",T.INK_MUTED)
	search_status=_label(site_header,13);search_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;search_status.add_theme_color_override("font_color",T.INK_MUTED)
	options=HBoxContainer.new();options.add_theme_constant_override("separation",8);body.add_child(options)
	var find_sites:=Kit.button(body,"Look again nearby",false,_search,"Search the known ground around this spot for dry land near water")
	find_sites.custom_minimum_size.y=32
	action=Kit.button(root,"",true,_act);action.custom_minimum_size.y=44;action.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	update_site(position)
	_layout()
	_search()

func _label(parent:Node,font_size:int)->Label:
	var label:=Label.new()
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("font",T.FONT_UI)
	label.add_theme_font_size_override("font_size",maxi(12,font_size));label.add_theme_color_override("font_color",T.BODY);parent.add_child(label);return label

## A label that wraps onto more lines instead of trimming to "...".
func _wrapping(label:Label,width:float)->Label:
	label.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x=width
	return label

func _card(parent:Node,accent:Color)->PanelContainer:
	var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",_card_style(accent));parent.add_child(card);return card

## Sunk paper with the accent as a left rule, never a dark ground.
static func _card_style(accent:Color)->StyleBoxFlat:
	var style:=Kit.section_style(9.0)
	style.border_width_left=3
	style.border_color=accent if accent!=T.RULE else T.RULE
	return style

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
	water_card.add_theme_stylebox_override("panel",_card_style(accent))
	heading.text="Water nearby" if bool(selected.get("water_recommended",false)) else Kit.sentence(String(selected.title))
	heading.add_theme_color_override("font_color",Kit.text_color(accent))
	source.text=String(selected.get("source_text","Fresh water not yet found"))
	var share:=roundi(minf(1.0,float(selected.household_ratio))*100.0)
	meter_label.text="%d%%" % share
	meter_note.text="of households could fetch their drinking water each day from here." if share>0 else "No household could fetch drinking water from here."
	meter.value=minf(1.0,float(selected.household_ratio))*100.0
	var neighbors:Dictionary=selected.neighbors
	var neighbor_color:=Kit.text_color(Advice.BLOCKED) if float(neighbors.penalty)>=.35 else (Kit.text_color(Advice.CAUTION) if float(neighbors.penalty)>0 else T.BODY)
	var affected:Array=neighbors.get("affected",[])
	neighbor_label.text="None reported within 30 km" if affected.is_empty() else "%s, %.1f km away" % [String(affected[0].get("city_name","A known town")),float(affected[0].get("distance_km",0.0))]
	neighbor_label.add_theme_color_override("font_color",neighbor_color)
	neighbor_badge.text="None near" if affected.is_empty() else "Too close"
	neighbor_badge.add_theme_color_override("font_color",neighbor_color)
	neighbor_label.tooltip_text=String(neighbors.get("text","Returned reports only."));neighbor_badge.tooltip_text=neighbor_label.tooltip_text
	water_card.tooltip_text=String(selected.get("reason",""));source.tooltip_text=water_card.tooltip_text;meter.tooltip_text=water_card.tooltip_text
	var fill:=StyleBoxFlat.new();fill.bg_color=accent;meter.add_theme_stylebox_override("fill",fill)
	_refresh_resources()
	action.disabled=not bool(selected.valid)
	if not bool(selected.valid):action.text="This ground will not do; choose another"
	elif later_city:action.text="See who would go, and the cost"
	elif selected_suggestion:action.text="Walk the travellers to this site"
	elif float(neighbors.penalty)>0:action.text="Found here, though it will anger a neighbour"
	else:action.text="Found our home here" if bool(selected.water_recommended) else "Found here; water must be carried"
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
		var chip:=_card(resource_grid,T.RULE);chip.custom_minimum_size.y=47
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);chip.add_child(row)
		_icon(row,Icons.texture_for(String(entry.resource)),28)
		var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",0);row.add_child(copy)
		var name_label:=_label(copy,14);name_label.text=ResourceSystem.display_name(String(entry.resource));name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;name_label.autowrap_mode=TextServer.AUTOWRAP_OFF
		var stage:="surveyed" if String(entry.get("knowledge",""))=="surveyed" else "seen"
		var detail:=_label(copy,12);detail.text="%.1f km · %s" % [float(entry.distance_km),stage];detail.add_theme_color_override("font_color",T.INK_MUTED)
		var blockers:Array=entry.get("blockers",[]) as Array
		var access_note:=String(blockers.front()) if not blockers.is_empty() else String(entry.get("access",""))
		chip.tooltip_text="Known from returned scouting or travel reports. "+access_note
		resource_cards.append({"resource":String(entry.resource),"card":chip,"distance":float(entry.distance_km),"knowledge":stage})

func _search()->void:
	var origin:Vector3=selected.position
	sites=terrain._founding_advisor().suggestions(origin,later_city)
	for child:Node in options.get_children():options.remove_child(child);child.queue_free()
	search_status.text="%d marked on the map" % sites.size()
	if sites.is_empty():search_status.text="None found yet"
	for index:int in sites.size():
		var choose:=Kit.button(options,"Site %d
%.1f km away" % [index+1,float(sites[index].travel_distance_km)],false,_select.bind(index),"Look at site %d on the map" % (index+1));choose.custom_minimum_size.y=48;choose.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choose.add_theme_font_size_override("font_size",14);choose.clip_text=true
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
	for index:int in sites.size():_marker(sites[index].position,"Site %d · near water" % (index+1),Advice.GOOD)
	if selected.has("source_position"):
		var position:Vector3=selected.position
		var water:Vector3=selected.source_position
		if not terrain.camera.is_position_behind(position) and not terrain.camera.is_position_behind(water):
			var from:Vector2=terrain.camera.unproject_position(position);var to:Vector2=terrain.camera.unproject_position(water)
			draw_dashed_line(from,to,T.INK,4,7);draw_dashed_line(from,to,WATER_MARK,2,7)
		_marker(water,"Fresh water",WATER_MARK)
	if not selected.is_empty():_marker(selected.position,"This site",selected.color)

func _marker(position:Vector3,text:String,color:Color)->void:
	if terrain.camera.is_position_behind(position):return
	var point:Vector2=terrain.camera.unproject_position(position)
	if not get_viewport_rect().has_point(point) or panel.get_rect().has_point(point):return
	# An ink keyline round a paper disc and a solid accent core reads on any
	# ground, pale grass or dark forest.
	draw_circle(point,13,T.INK);draw_circle(point,11.5,T.PAPER_RAISED);draw_arc(point,9,0,TAU,32,color,3,true);draw_circle(point,4.5,color.darkened(0.25))
	var font:Font=T.font("ui_strong")
	var label_size:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14)
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
			draw_string(font,label_position,text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Kit.text_color(color))
			return
		label_position.y=point.y+float((attempt/2)+1)*24.0*(1.0 if attempt%2==0 else -1.0)

func _marker_style()->StyleBoxFlat:
	return T.flat(T.PAPER_RAISED,T.RULE_STRONG,1,2,2)
