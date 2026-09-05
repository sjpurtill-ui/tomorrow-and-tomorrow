extends Control
## Hearsay chart only: no terrain query, reveal call or hidden settlement lookup.
var terrain:Node
var plot:Control
var details:Label
var investigate:Button
var status:Label
var selected_id:=""
var shown_revision:=-1
var shown_day:=-1
var elapsed:=0.0
var filter_mode:=0
class Plot extends Control:
	var leads:Array[Dictionary]=[]
	var selected:=""
	var center:=Vector2.ZERO
	var scale_km:=.1
	var dragging:=false
	signal picked(id:String)
	func _ready()->void:
		clip_contents=true; mouse_filter=Control.MOUSE_FILTER_STOP
		tooltip_text="Click a reported area to inspect it. Drag to pan. Scroll to zoom."
	func screen(p:Vector2)->Vector2: return (p-center)*scale_km+size*.5
	func world(p:Vector2)->Vector2: return (p-size*.5)/scale_km+center
	func fit()->void:
		var low:Vector2=CivilizationSystem.player_world_origin; var high:=low
		for lead:Dictionary in leads:
			var c:=CivilizationSystem.rumor_network.vector(lead.center); var r:=Vector2.ONE*float(lead.radius)
			low=low.min(c-r); high=high.max(c+r)
			if not lead.get("heard_position",{}).is_empty():
				var heard:=CivilizationSystem.rumor_network.vector(lead.heard_position); low=low.min(heard); high=high.max(heard)
		center=(low+high)*.5
		var extent:Vector2=(high-low).max(Vector2(100,100))
		scale_km=clampf(minf((size.x-60)/extent.x,(size.y-60)/extent.y),.002,12)
		queue_redraw()
	func zoom(factor:float,at:Vector2)->void:
		var anchor:=world(at); scale_km=clampf(scale_km*factor,.002,12); center=anchor-(at-size*.5)/scale_km; queue_redraw()
	func select_at(at:Vector2)->void:
		var closest:=""; var distance:=36.0
		for lead:Dictionary in leads:
			var delta:=screen(CivilizationSystem.rumor_network.vector(lead.center)).distance_to(at)
			if delta<distance: distance=delta; closest=lead.id
		if closest!="": selected=closest; picked.emit(closest); queue_redraw()
	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseButton:
			if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom(1.25,event.position); accept_event()
			elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom(.8,event.position); accept_event()
			elif event.button_index==MOUSE_BUTTON_LEFT:
				dragging=event.pressed
				if event.pressed: select_at(event.position)
		elif event is InputEventMouseMotion and dragging:
			center-=event.relative/scale_km; queue_redraw(); accept_event()
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("080e12"))
		var font:=ThemeDB.fallback_font
		var home_label:=screen(CivilizationSystem.player_world_origin)+Vector2(10,-24)
		var labels:Array[Rect2]=[Rect2(home_label,Vector2(55,22))]
		var ordered:Array=leads.duplicate()
		ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return a.id==selected and b.id!=selected)
		for lead:Dictionary in ordered:
			var p:=screen(CivilizationSystem.rumor_network.vector(lead.center))
			var radius:=float(lead.radius)*scale_km
			var active:bool=lead.id==selected
			var color:=Color("f2cc7d") if active else Color("9e8967")
			if active:
				draw_circle(p,radius,Color(color,.08),true)
				draw_arc(p,radius,0,TAU,64,color,2,true)
			draw_circle(p,7 if active else 4,color)
			var label:=String(lead.name)
			var rect:=Rect2(p+Vector2(12,-20),Vector2(font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x,20))
			var overlaps:=false
			for occupied:Rect2 in labels:
				if occupied.intersects(rect): overlaps=true
			if active or not overlaps:
				draw_string(font,rect.position+Vector2(0,16),label,HORIZONTAL_ALIGNMENT_LEFT,-1,16,color); labels.append(rect)
			if active and not lead.get("heard_position",{}).is_empty():
				var heard:=screen(CivilizationSystem.rumor_network.vector(lead.heard_position))
				var cyan:=Color("74d8d1")
				draw_dashed_line(heard,p,cyan,1,7)
				draw_colored_polygon(PackedVector2Array([heard+Vector2(0,-7),heard+Vector2(7,0),heard+Vector2(0,7),heard+Vector2(-7,0)]),cyan)
				draw_string(font,heard+Vector2(10,22),"Account heard here",HORIZONTAL_ALIGNMENT_LEFT,-1,16,cyan)
		var home:=screen(CivilizationSystem.player_world_origin)
		draw_rect(Rect2(home-Vector2(4,4),Vector2(8,8)),Color.WHITE)
		draw_string(font,home+Vector2(10,-8),"Home",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var background:=ColorRect.new(); background.color=Color("102128"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,18)
	add_child(margin)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",12); margin.add_child(root)
	var toolbar:=HBoxContainer.new(); root.add_child(toolbar)
	var title:=Label.new(); title.text="MAP OF RUMORS"; title.add_theme_font_size_override("font_size",24); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; toolbar.add_child(title)
	var fit:=Button.new(); fit.text="FIT REPORTS"; toolbar.add_child(fit)
	var back:=Button.new(); back.text="RETURN"; back.pressed.connect(func()->void: get_parent().queue_free()); toolbar.add_child(back)
	var navigation:=HBoxContainer.new(); root.add_child(navigation)
	var filter:=OptionButton.new()
	for label in ["ALL ACCOUNTS","UNRESOLVED","RECENT (60 DAYS)"]: filter.add_item(label)
	filter.item_selected.connect(func(index:int)->void: filter_mode=index; refresh())
	navigation.add_child(filter)
	for direction in [-1,1]:
		var step:=Button.new(); step.text="PREVIOUS ACCOUNT" if direction<0 else "NEXT ACCOUNT"
		step.pressed.connect(_step.bind(direction)); navigation.add_child(step)
	status=Label.new(); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; status.add_theme_font_size_override("font_size",16); root.add_child(status)
	plot=Plot.new(); plot.custom_minimum_size=Vector2(0,160); plot.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(plot)
	plot.picked.connect(func(id:String)->void: selected_id=id; refresh_details())
	fit.pressed.connect(plot.fit)
	var footer:=HBoxContainer.new(); root.add_child(footer)
	details=Label.new(); details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.custom_minimum_size=Vector2(0,125); details.add_theme_font_size_override("font_size",16); footer.add_child(details)
	investigate=Button.new(); investigate.text="INVESTIGATE LEAD"; investigate.custom_minimum_size=Vector2(175,44); investigate.size_flags_vertical=Control.SIZE_SHRINK_CENTER; investigate.pressed.connect(_investigate); footer.add_child(investigate)
	refresh()
	await get_tree().process_frame
	plot.fit()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed<.75: return
	elapsed=0
	if shown_revision!=CivilizationSystem.rumor_network.revision or shown_day!=int(GameState.elapsed_days): refresh()
func refresh()->void:
	shown_revision=CivilizationSystem.rumor_network.revision; shown_day=int(GameState.elapsed_days)
	plot.leads=CivilizationSystem.rumor_network.list_leads("player",shown_day)
	if filter_mode==1: plot.leads.assign(plot.leads.filter(func(lead:Dictionary)->bool: return not bool(lead.get("resolved",false))))
	elif filter_mode==2: plot.leads.assign(plot.leads.filter(func(lead:Dictionary)->bool: return int(lead.age)<=60))
	var selected_present:=false
	for lead:Dictionary in plot.leads:
		if lead.id==selected_id: selected_present=true
	if not selected_present: selected_id=String(plot.leads[0].id) if not plot.leads.is_empty() else ""
	plot.selected=selected_id; plot.queue_redraw()
	status.text="%d reports · circles show uncertain regions, diamonds show where an account was heard. Click to inspect; drag to pan; scroll to zoom. Terrain stays hidden." % plot.leads.size()
	refresh_details()
func refresh_details()->void:
	var lead:Dictionary=CivilizationSystem.rumor_network.known("player",selected_id,int(GameState.elapsed_days))
	investigate.disabled=lead.is_empty() or not is_instance_valid(terrain)
	if lead.is_empty():
		details.text="No mapped accounts have reached home. Older text-only rumors lack recorded coordinates; no source or destination is invented."
		return
	investigate.text="OPEN CITY REPORTS" if bool(lead.get("resolved",false)) else "INVESTIGATE LEAD"
	details.text=String(lead.name)+"\n"+CivilizationSystem.rumor_network.describe(lead)+"\n"+String(lead.source)+( " · heard location unknown" if lead.get("heard_position",{}).is_empty() else "")+"\nAn account of people in this region, not a confirmed homeland."
func _investigate()->void:
	if selected_id=="" or not is_instance_valid(terrain): return
	var lead:Dictionary=CivilizationSystem.rumor_network.known("player",selected_id,int(GameState.elapsed_days))
	if bool(lead.get("resolved",false)):
		get_parent().queue_free(); CivilizationSystem.city_intelligence.open("",String(lead.subject)); return
	terrain.pending_scout_target_id="lead:"+selected_id
	get_parent().queue_free()
	terrain._open_scout_dispatch_panel()

func _step(direction:int)->void:
	if plot.leads.is_empty(): return
	var index:=0
	for i in plot.leads.size():
		if plot.leads[i].id==selected_id: index=i; break
	index=posmod(index+direction,plot.leads.size())
	selected_id=String(plot.leads[index].id); plot.selected=selected_id
	plot.center=CivilizationSystem.rumor_network.vector(plot.leads[index].center)
	plot.queue_redraw(); refresh_details()
