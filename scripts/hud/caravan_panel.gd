extends CanvasLayer
## Caravan UI for the Command Rail HUD:
## - the caravan status card (one row per caravan: leader, people, food/water
##   days, what the leader is doing now, and optional override buttons);
## - the formation section used before and after choosing a destination
##   (party size from real population, rations from real stores, leader from the
##   government cast with a plain-words fit summary).
## The ruler never has to press anything on the card: the leader marches,
## camps and resumes by itself. Buttons are overrides only.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Systems:=preload("res://scripts/caravan_system.gd")
const EDGE:=16.0
const CARD_WIDTH:=372.0
const LEFT_CLEARANCE:=96.0
const BOTTOM_CLEARANCE:=196.0

var terrain:Node
var card:PanelContainer
var rows:VBoxContainer
var signature:=""

## Creates or refreshes the card for the current owner's caravans.
static func sync(terrain_node:Node,hud_node:Control)->CanvasLayer:
	if not is_instance_valid(hud_node):return null
	var existing:Variant=hud_node.get_meta("caravan_status_card") if hud_node.has_meta("caravan_status_card") else null
	var cards:=Systems.status_cards()
	# A modal decision (formation or review) has the ruler's attention.
	if is_instance_valid(terrain_node) and (is_instance_valid(terrain_node.get("settlement_convoy_confirm_panel")) or is_instance_valid(terrain_node.get("caravan_formation_card"))):cards=[]
	if not is_instance_valid(existing):
		if cards.is_empty():return null
		existing=new()
		existing.terrain=terrain_node
		existing.name="CaravanStatusCard"
		hud_node.set_meta("caravan_status_card",existing)
		hud_node.add_child(existing)
	existing.refresh(cards)
	return existing

func _ready()->void:
	layer=70
	card=PanelContainer.new()
	card.name="CaravanCard"
	card.add_theme_stylebox_override("panel",T.flat(T.PANEL_BG,T.GOLD,1,6,10))
	card.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(card)
	rows=VBoxContainer.new()
	rows.add_theme_constant_override("separation",8)
	card.add_child(rows)
	get_viewport().size_changed.connect(layout)
	card.hide()

func refresh(cards:Array[Dictionary])->void:
	if not is_instance_valid(card):return
	var next:=str(cards.size())+JSON.stringify(cards.map(func(entry:Dictionary)->Array:return [entry.id,entry.intent,entry.people,roundi(float(entry.food_days)),roundi(float(entry.water_days)*10.0),entry.mode,entry.can_hold,entry.can_resume,entry.can_recall,roundi(float(entry.progress)*100.0)]))
	if next==signature:return
	signature=next
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	if cards.is_empty():
		card.hide()
		return
	for entry:Dictionary in cards:_add_row(entry)
	card.show()
	call_deferred("layout")

func _add_row(entry:Dictionary)->void:
	if rows.get_child_count()>0:rows.add_child(HSeparator.new())
	var box:=VBoxContainer.new()
	box.name="Caravan_%s" % String(entry.id)
	box.add_theme_constant_override("separation",3)
	rows.add_child(box)
	var top:=HBoxContainer.new()
	top.add_theme_constant_override("separation",6)
	box.add_child(top)
	var eyebrow:=T.make_label(String(entry.title),10,T.GOLD,0.08)
	eyebrow.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	eyebrow.clip_text=true
	top.add_child(eyebrow)
	top.add_child(T.make_label("%d%%" % roundi(float(entry.progress)*100.0),10,T.MUTED))
	var reputation:=String(entry.reputation).get_slice(" • ",0)
	var leader:=T.make_label("%s  ·  %s" % [String(entry.leader),reputation],12,T.INK)
	leader.clip_text=true
	leader.tooltip_text="%s\n%s" % [String(entry.reputation),String(entry.summary)]
	box.add_child(leader)
	var intent:=T.make_label(String(entry.intent) if String(entry.intent)!="" else "Preparing to march",13,T.BODY)
	intent.name="Intent"
	intent.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	intent.custom_minimum_size.x=CARD_WIDTH-24.0
	box.add_child(intent)
	var water_color:=T.RED if float(entry.water_days)<1.0 else (T.AMBER if float(entry.water_days)<2.0 else T.TEAL)
	var food_color:=T.RED if float(entry.food_days)<4.0 else (T.AMBER if float(entry.food_days)<8.0 else T.GREEN)
	var stats:=HBoxContainer.new()
	stats.add_theme_constant_override("separation",10)
	box.add_child(stats)
	stats.add_child(T.make_label("%d PEOPLE" % int(entry.people),11,T.TEXT_SOFT))
	stats.add_child(T.make_label("FOOD %s" % _days(float(entry.food_days)),11,food_color))
	stats.add_child(T.make_label("WATER %.1f d" % float(entry.water_days),11,water_color))
	stats.add_child(T.make_label("%.0f km left" % float(entry.remaining_km),11,T.TEXT_SOFT))
	var actions:=HBoxContainer.new()
	actions.add_theme_constant_override("separation",6)
	box.add_child(actions)
	var id:=String(entry.id)
	_button(actions,"FOCUS",func()->void:_act(id,"focus"),"Move the map to the caravan.")
	if bool(entry.can_hold):_button(actions,"HALT",func()->void:_act(id,"hold"),"Override: the leader stops and holds (moving to water first if there is none).")
	if bool(entry.can_resume):_button(actions,"MARCH ON",func()->void:_act(id,"resume"),"Override: break camp now and continue to the destination.")
	if bool(entry.can_recall):_button(actions,"RECALL",func()->void:_act(id,"recall"),"Override: the caravan turns for home; people and stores return to the origin.")

func _button(parent:Node,text_value:String,callback:Callable,tip:String)->Button:
	var button:=Button.new()
	button.text=text_value
	button.tooltip_text=tip
	button.custom_minimum_size=Vector2(0,26)
	button.add_theme_font_size_override("font_size",11)
	button.add_theme_stylebox_override("normal",T.action_button_style(false))
	button.add_theme_stylebox_override("hover",T.action_button_style(true,true))
	button.add_theme_stylebox_override("pressed",T.action_button_style(true,true))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _act(id:String,action:String)->void:
	if terrain and terrain.has_method("_on_caravan_override"):terrain.call("_on_caravan_override",id,action)
	signature=""

func layout()->void:
	if not is_instance_valid(card):return
	var extent:=get_viewport().get_visible_rect().size
	var width:=maxf(260.0,minf(CARD_WIDTH,extent.x-EDGE*2.0-LEFT_CLEARANCE))
	card.custom_minimum_size.x=width
	card.size=Vector2(width,0.0)
	var height:=card.get_combined_minimum_size().y
	card.size.y=height
	card.position=Vector2(minf(LEFT_CLEARANCE,maxf(EDGE,extent.x-width-EDGE)),maxf(EDGE,extent.y-height-BOTTOM_CLEARANCE))

static func _days(days:float)->String:
	if days>=365.0:return "ample"
	return "%.0f d" % days

# --------------------------------------------------------------- formation

## Party controls used in the destination review (dark modal palette) and the
## pre-destination formation card. `values`: population, food, leader_person_id.
## Returns the controls; `on_change` is called with the current values.
static func build_formation(parent:Container,limits:Dictionary,candidates:Array[Dictionary],values:Dictionary,width:float,on_change:Callable,palette:Dictionary={})->Dictionary:
	var text_color:Color=palette.get("text",T.BODY)
	var muted:Color=palette.get("muted",T.TEXT_SOFT)
	var accent:Color=palette.get("accent",T.GOLD)
	var section:=VBoxContainer.new()
	section.name="CaravanFormation"
	section.add_theme_constant_override("separation",6)
	parent.add_child(section)
	var heading:=T.make_label("CARAVAN",11,accent,0.08)
	section.add_child(heading)
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",6)
	section.add_child(grid)
	var controls:={}
	grid.add_child(T.make_label("Leader",12,muted))
	var leader_choice:=OptionButton.new()
	leader_choice.name="CaravanLeader"
	leader_choice.custom_minimum_size=Vector2(maxf(160.0,width-150.0),30)
	leader_choice.clip_text=true
	var selected_id:=int(values.get("leader_person_id",0))
	var selected_index:=0
	for index in candidates.size():
		var candidate:Dictionary=candidates[index]
		leader_choice.add_item("%s — %s" % [String(candidate.get("name","")),String(candidate.get("summary",""))],index)
		leader_choice.set_item_metadata(index,int(candidate.get("person_id",0)))
		if int(candidate.get("person_id",0))==selected_id:selected_index=index
	if candidates.is_empty():
		leader_choice.add_item("A route organizer from among the settlers",0)
		leader_choice.set_item_metadata(0,0)
	leader_choice.select(selected_index)
	grid.add_child(leader_choice)
	controls["leader"]=leader_choice
	grid.add_child(T.make_label("Settlers",12,muted))
	var people:=SpinBox.new()
	people.name="CaravanPeople"
	people.min_value=float(limits.get("min_founders",40))
	people.max_value=maxf(float(limits.get("min_founders",40)),float(limits.get("max_founders",40)))
	people.step=5.0
	people.rounded=true
	people.value=clampf(float(values.get("population",limits.get("default_founders",40))),people.min_value,people.max_value)
	people.suffix="people"
	people.tooltip_text="Drawn from the origin's real population. At least %d people must remain behind." % 80
	grid.add_child(people)
	controls["people"]=people
	if bool(limits.get("show_food",false)):
		grid.add_child(T.make_label("Rations",12,muted))
		var food:=SpinBox.new()
		food.name="CaravanFood"
		food.min_value=0.0
		food.max_value=maxf(float(limits.get("food_available",0.0)),float(values.get("food",0.0)))
		food.step=10.0
		food.rounded=true
		food.value=clampf(float(values.get("food",limits.get("suggested_food",0.0))),0.0,food.max_value)
		food.suffix="person-days"
		food.tooltip_text="Taken from the origin's real stores. The leader suggests travel rations plus a %d-day reserve for the new settlement." % roundi(Systems.ESTABLISHMENT_DAYS)
		grid.add_child(food)
		controls["food"]=food
	var advice:=Label.new()
	advice.name="CaravanAdvice"
	advice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	advice.custom_minimum_size.x=width
	advice.add_theme_font_size_override("font_size",12)
	advice.add_theme_color_override("font_color",text_color)
	advice.text=String(limits.get("advice",""))
	section.add_child(advice)
	controls["advice"]=advice
	var emit:=func(_value:Variant=null)->void:
		if on_change.is_valid():on_change.call(formation_values(controls))
	leader_choice.item_selected.connect(func(_index:int)->void:emit.call())
	people.value_changed.connect(func(_value:float)->void:emit.call())
	if controls.has("food"):(controls.food as SpinBox).value_changed.connect(func(_value:float)->void:emit.call())
	return controls

static func formation_values(controls:Dictionary)->Dictionary:
	var result:={}
	var leader_choice:OptionButton=controls.get("leader")
	if is_instance_valid(leader_choice) and leader_choice.selected>=0:
		result["leader_person_id"]=int(leader_choice.get_item_metadata(leader_choice.selected))
	var people:SpinBox=controls.get("people")
	if is_instance_valid(people):result["population"]=roundi(people.value)
	var food:SpinBox=controls.get("food")
	if is_instance_valid(food):result["food"]=food.value
	return result

## The pre-destination step: form the party, then choose where it goes.
static func open_formation_card(host:Node,origin_name:String,limits:Dictionary,candidates:Array[Dictionary],values:Dictionary,on_choose:Callable,on_cancel:Callable)->Control:
	var overlay:=Control.new()
	overlay.name="CaravanFormationCard"
	overlay.size=host.get_viewport().get_visible_rect().size
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	host.add_child(overlay)
	var dimmer:=ColorRect.new()
	dimmer.size=overlay.size
	dimmer.color=Color(0.0,0.0,0.0,0.45)
	overlay.add_child(dimmer)
	var panel:=PanelContainer.new()
	var width:=minf(560.0,overlay.size.x-48.0)
	panel.custom_minimum_size=Vector2(width,0)
	panel.add_theme_stylebox_override("panel",T.flat(T.PANEL_BG_SOLID,T.GOLD,1,6,18))
	overlay.add_child(panel)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	panel.add_child(root)
	root.add_child(T.make_label("NEW SETTLEMENT • FORM A CARAVAN",11,T.GOLD,0.08))
	var title:=T.make_label("Settlers from %s" % origin_name,22,T.INK)
	root.add_child(title)
	var explain:=T.make_label("Choose who leads and how many go. Then pick the destination on the map; the leader plans the route over water, suggests rations, and runs the march — camps, water stops and all.",12,T.TEXT_SOFT)
	explain.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	explain.custom_minimum_size.x=width-36.0
	root.add_child(explain)
	var controls:=build_formation(root,limits,candidates,values,width-36.0,Callable())
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation",8)
	root.add_child(footer)
	var cancel:=Button.new()
	cancel.name="CancelFormation"
	cancel.text="CANCEL"
	cancel.custom_minimum_size=Vector2(120,38)
	cancel.pressed.connect(func()->void:
		overlay.queue_free()
		if on_cancel.is_valid():on_cancel.call()
	)
	footer.add_child(cancel)
	var choose:=Button.new()
	choose.name="ChooseDestination"
	choose.text="CHOOSE DESTINATION ON MAP"
	choose.custom_minimum_size=Vector2(240,38)
	choose.disabled=int(limits.get("max_founders",0))<int(limits.get("min_founders",40))
	if choose.disabled:choose.tooltip_text="At least %d people must remain at %s after a %d-person party leaves." % [80,origin_name,int(limits.get("min_founders",40))]
	choose.pressed.connect(func()->void:
		var chosen:=formation_values(controls)
		overlay.queue_free()
		if on_choose.is_valid():on_choose.call(chosen)
	)
	footer.add_child(choose)
	panel.reset_size()
	panel.position=(overlay.size-panel.get_combined_minimum_size())*0.5
	return overlay
