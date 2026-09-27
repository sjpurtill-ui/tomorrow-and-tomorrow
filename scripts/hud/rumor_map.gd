extends Control
## Hearsay chart only: no terrain query, reveal call or hidden settlement lookup.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const FILTER_WORDS:=["Everything heard","Not yet found","Heard lately"]
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
		tooltip_text="Click a circle to read what was heard. Drag to move the chart; scroll to zoom."
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
		draw_style_box(T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CARD),Rect2(Vector2.ZERO,size))
		var font:=T.font("ui")
		var home_label:=screen(CivilizationSystem.player_world_origin)+Vector2(10,-24)
		var labels:Array[Rect2]=[Rect2(home_label,Vector2(55,22))]
		var ordered:Array=leads.duplicate()
		ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return a.id==selected and b.id!=selected)
		for lead:Dictionary in ordered:
			var p:=screen(CivilizationSystem.rumor_network.vector(lead.center))
			var radius:=float(lead.radius)*scale_km
			var active:bool=lead.id==selected
			var color:=T.GOLD_TEXT if active else T.INK_MUTED
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
				var cyan:=T.TEAL_TEXT
				draw_dashed_line(heard,p,cyan,1,7)
				draw_colored_polygon(PackedVector2Array([heard+Vector2(0,-7),heard+Vector2(7,0),heard+Vector2(0,7),heard+Vector2(-7,0)]),cyan)
				draw_string(font,heard+Vector2(10,22),"Account heard here",HORIZONTAL_ALIGNMENT_LEFT,-1,16,cyan)
		var home:=screen(CivilizationSystem.player_world_origin)
		draw_rect(Rect2(home-Vector2(4,4),Vector2(8,8)),T.INK)
		draw_string(font,home+Vector2(10,-8),"Home",HORIZONTAL_ALIGNMENT_LEFT,-1,16,T.INK)
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	theme=T.control_theme()
	var background:=Panel.new(); background.add_theme_stylebox_override("panel",T.flat(T.PAPER,T.RULE,0,0)); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,18)
	add_child(margin)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",12); margin.add_child(root)
	var toolbar:=HBoxContainer.new(); toolbar.add_theme_constant_override("separation",8); root.add_child(toolbar)
	var title:=Label.new(); title.text="Map of hearsay"; T.text(title,"title",T.INK); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; toolbar.add_child(title)
	var fit:=_button("Show all",toolbar)
	var back:=_button("Close",toolbar); back.tooltip_text="Close the map (Esc)"; back.pressed.connect(close)
	var navigation:=HBoxContainer.new(); navigation.add_theme_constant_override("separation",8); root.add_child(navigation)
	var group:=ButtonGroup.new()
	for index in FILTER_WORDS.size():
		var toggle:=_button(FILTER_WORDS[index],navigation); toggle.toggle_mode=true; toggle.button_group=group; toggle.button_pressed=index==filter_mode
		toggle.add_theme_stylebox_override("pressed",T.flat(T.PAPER_SUNK,T.RULE_STRONG,1,T.RADIUS_CONTROL,8))
		toggle.pressed.connect(func()->void: filter_mode=index; refresh())
	var spacer:=Control.new(); spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL; navigation.add_child(spacer)
	for direction in [-1,1]:
		var step:=_button("Previous" if direction<0 else "Next",navigation)
		step.pressed.connect(_step.bind(direction))
	status=Label.new(); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; T.text(status,"small",T.INK_MUTED); root.add_child(status)
	plot=Plot.new(); plot.custom_minimum_size=Vector2(0,160); plot.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(plot)
	plot.picked.connect(func(id:String)->void: selected_id=id; refresh_details())
	fit.pressed.connect(plot.fit)
	var footer:=HBoxContainer.new(); root.add_child(footer)
	details=Label.new(); details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.custom_minimum_size=Vector2(0,125); T.text(details,"body",T.BODY); footer.add_child(details)
	investigate=_button("Send scouts to look",footer); investigate.custom_minimum_size=Vector2(175,44); investigate.size_flags_vertical=Control.SIZE_SHRINK_CENTER; investigate.pressed.connect(_investigate)
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
	status.text="%s. Each circle is where a people is said to live; a diamond is where we heard it. Click a circle to read the account." % ("One account" if plot.leads.size()==1 else "%d accounts" % plot.leads.size())
	refresh_details()
func refresh_details()->void:
	var lead:Dictionary=CivilizationSystem.rumor_network.known("player",selected_id,int(GameState.elapsed_days))
	investigate.disabled=lead.is_empty() or not is_instance_valid(terrain)
	if lead.is_empty():
		details.text="No one has told us of any people we could place on a map yet."
		return
	investigate.text="Read the city report" if bool(lead.get("resolved",false)) else "Send scouts to look"
	details.text=String(lead.name)+"\n"+_describe(lead)+"\n"+T.sentence_case(String(lead.source))+(" · we do not know where this was heard" if lead.get("heard_position",{}).is_empty() else "")+"\nHearsay only: they may live somewhere in this circle, or not at all."
func _investigate()->void:
	if selected_id=="" or not is_instance_valid(terrain): return
	var lead:Dictionary=CivilizationSystem.rumor_network.known("player",selected_id,int(GameState.elapsed_days))
	if bool(lead.get("resolved",false)):
		close(); CivilizationSystem.city_intelligence.open("",String(lead.subject)); return
	terrain.pending_scout_target_id="lead:"+selected_id
	close()
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

func _button(text:String,parent:Node)->Button:
	var button:=Button.new(); button.text=text; T.text(button,"small",T.INK)
	button.add_theme_stylebox_override("normal",T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CONTROL,8))
	button.add_theme_stylebox_override("hover",T.flat(T.PAPER,T.RULE_STRONG,1,T.RADIUS_CONTROL,8))
	parent.add_child(button)
	return button

func close()->void:
	if is_instance_valid(get_parent()) and get_parent() is CanvasLayer: get_parent().queue_free()
	else: queue_free()

func _input(event:InputEvent)->void:
	# The map covers the screen, so Escape always closes it first.
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled(); close()

## The account in plain words, with the shared date phrase.
func _describe(lead:Dictionary)->String:
	var EraWords=preload("res://scripts/hud/era_words.gd")
	var direction:=String(CivilizationSystem._compass_phrase(CivilizationSystem.player_world_origin,CivilizationSystem.rumor_network.vector(lead.center)))
	var trust:="fairly sure" if float(lead.confidence)>=.35 else "unsure" if float(lead.confidence)>=.15 else "barely sure"
	var text:="Somewhere to the %s, in a circle about %.0f km across. The tellers are %s." % [direction,float(lead.radius)*2,trust]
	text+="
Seen %s; the word reached us %s, by way of %s." % [EraWords.when(int(lead.observed_day)),EraWords.ago(int(lead.reported_day)),String(lead.via)]
	var attempts:=int(lead.attempts)
	if attempts>0:text+=" Our scouts have looked %s without finding them." % ("once" if attempts==1 else "%d times" % attempts)
	if bool(lead.get("conflicting",false)):text+=" The accounts disagree about where."
	return text
