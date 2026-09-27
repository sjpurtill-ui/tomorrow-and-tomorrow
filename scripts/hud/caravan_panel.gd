extends CanvasLayer
## Caravan UI for the Command Rail HUD:
## - the caravan status card (one row per caravan: leader, people, food/water
##   days, what the leader is doing now, and optional override buttons);
## - the settler card shown once the ruler has picked land: who leads, how
##   many go, what they carry and how long it takes, then "Send them". The
##   leader chooses the party size and rations from real people and stores.
## The ruler never has to press anything on the card: the leader marches,
## camps and resumes by itself. Buttons are overrides only.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Systems:=preload("res://scripts/caravan_system.gd")
const Kit:=preload("res://scripts/hud/paper_kit.gd")
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
	# The settler card has the ruler's attention.
	if is_instance_valid(terrain_node) and is_instance_valid(terrain_node.get("settlement_convoy_confirm_panel")):cards=[]
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
	card.add_theme_stylebox_override("panel",Kit.card_style(12.0,T.GOLD))
	card.theme=T.control_theme()
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
	box.add_theme_constant_override("separation",4)
	rows.add_child(box)
	var top:=HBoxContainer.new()
	top.add_theme_constant_override("separation",6)
	box.add_child(top)
	var eyebrow:=Kit.label(top,_title_words(String(entry.title)),"kicker",Color(0,0,0,0),false)
	eyebrow.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	eyebrow.clip_text=true
	Kit.label(top,"%d%% of the way" % roundi(float(entry.progress)*100.0),"note",Color(0,0,0,0),false)
	var reputation:=String(entry.reputation).get_slice(" • ",0)
	var leader:=Kit.label(box,"%s leads · %s" % [String(entry.leader),reputation.to_lower()],"heading",Color(0,0,0,0),false)
	leader.clip_text=true
	leader.tooltip_text="%s\n%s" % [String(entry.reputation),String(entry.summary)]
	var intent:=Kit.label(box,String(entry.intent) if String(entry.intent)!="" else "Getting ready to set out.","body")
	intent.name="Intent"
	intent.custom_minimum_size.x=CARD_WIDTH-32.0
	var water_color:=T.RED if float(entry.water_days)<1.0 else (T.AMBER if float(entry.water_days)<2.0 else T.TEAL)
	var food_color:=T.RED if float(entry.food_days)<4.0 else (T.AMBER if float(entry.food_days)<8.0 else T.GREEN)
	var stats:=HBoxContainer.new()
	stats.add_theme_constant_override("separation",12)
	box.add_child(stats)
	Kit.label(stats,"%d people" % int(entry.people),"note",Color(0,0,0,0),false)
	Kit.label(stats,"food for %s" % _days(float(entry.food_days)),"note",food_color,false)
	Kit.label(stats,"water for %s" % _days(float(entry.water_days)),"note",water_color,false)
	Kit.label(stats,"%.0f km to go" % float(entry.remaining_km),"note",Color(0,0,0,0),false)
	var actions:=HBoxContainer.new()
	actions.add_theme_constant_override("separation",6)
	box.add_child(actions)
	var id:=String(entry.id)
	_button(actions,"Show on map",func()->void:_act(id,"focus"),"Move the map to the caravan.")
	if bool(entry.can_hold):_button(actions,"Halt",func()->void:_act(id,"hold"),"The leader stops and makes camp, moving to water first if there is none.")
	if bool(entry.can_resume):_button(actions,"March on",func()->void:_act(id,"resume"),"Break camp now and carry on.")
	if bool(entry.can_recall):_button(actions,"Call them home",func()->void:_act(id,"recall"),"The caravan turns back; its people and stores return home.")

static func _title_words(title:String)->String:
	if title.begins_with("SETTLER CARAVAN"):
		var place:=title.get_slice("→",1).strip_edges()
		return "Settlers bound for %s" % place.capitalize() if place!="" else "Settlers on the road"
	return T.sentence_case(title)

func _button(parent:Node,text_value:String,callback:Callable,tip:String)->Button:
	var button:=Button.new()
	button.text=text_value
	button.tooltip_text=tip
	button.custom_minimum_size=Vector2(0,30)
	button.add_theme_font_size_override("font_size",14)
	button.add_theme_color_override("font_color",T.INK)
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
	if days>=365.0:return "a year or more"
	if days<1.0:return "under a day"
	return "%d day%s" % [roundi(days),"" if roundi(days)==1 else "s"]

# ------------------------------------------------------------ settler card

## The one card before settlers leave: where, who leads, how many, what they
## carry, how long it takes, and one "Send them". The caravan leader has
## already chosen the party size and the rations. `facts`:
##   name, origin_name, leader, leader_summary, people, food_days, journey,
##   distance_km, supplies, water_title, water_text, water_color,
##   neighbour_text, ready, problem, advice.
## Returns {overlay,name_input,status,send}.
static func open_settler_card(host:Node,facts:Dictionary,on_send:Callable,on_back:Callable)->Dictionary:
	var parts:=Kit.modal(host,560.0,T.GOLD,"SettlementConvoyConfirmation")
	var overlay:Control=parts[0]
	var column:VBoxContainer=parts[1]
	Kit.label(column,"New settlement","kicker")
	var name_input:=LineEdit.new()
	name_input.name="NewSettlementName"
	name_input.max_length=32
	name_input.text=String(facts.get("name",""))
	name_input.placeholder_text="Name the new settlement"
	name_input.tooltip_text="The name on the map and in the Chronicle. You can change it later."
	name_input.custom_minimum_size=Vector2(0,40)
	name_input.add_theme_font_override("font",T.font("ui_strong"))
	name_input.add_theme_font_size_override("font_size",20)
	column.add_child(name_input)
	var facts_box:=Kit.section(column,12.0)
	_fact(facts_box,"Who goes","%s leads %d people from %s." % [String(facts.get("leader","A caravan leader")),int(facts.get("people",0)),String(facts.get("origin_name","home"))],String(facts.get("leader_summary","")))
	_fact(facts_box,"Journey","About %s, %.1f km. The leader picks the camps and water stops." % [String(facts.get("journey","")),float(facts.get("distance_km",0.0))])
	_fact(facts_box,"They carry","Food for about %d days, for the road and the first weeks, and %s for shelter and tools." % [roundi(float(facts.get("food_days",0.0))),String(facts.get("supplies","nothing"))],"Taken from %s's stores when they leave." % String(facts.get("origin_name","home")))
	_fact(facts_box,"Water",String(facts.get("water_title","")),String(facts.get("water_text","")),facts.get("water_color",Color(0,0,0,0)))
	if String(facts.get("neighbour_text",""))!="":
		_fact(facts_box,"Neighbours",String(facts.neighbour_text),"",T.RED)
	var ready:=bool(facts.get("ready",false))
	var status:=Kit.label(column,String(facts.get("advice","")) if ready else "They cannot leave: %s" % String(facts.get("problem","something is missing.")),"body",Color(0,0,0,0) if ready else T.RED)
	status.name="SettlerStatus"
	status.custom_minimum_size.x=500
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation",10)
	column.add_child(footer)
	Kit.button(footer,"Choose other land",false,on_back)
	var send:=Kit.button(footer,"Send them",true,on_send,"Nothing leaves until you press this.")
	send.name="SendThem"
	send.custom_minimum_size.x=150
	send.disabled=not ready
	return {"overlay":overlay,"name_input":name_input,"status":status,"send":send}

static func _fact(parent:Node,what:String,text:String,note:String="",color:Color=Color(0,0,0,0))->void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	parent.add_child(row)
	var key:=Kit.label(row,what,"note",Color(0,0,0,0),false)
	key.custom_minimum_size.x=92
	var column:=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",1)
	row.add_child(column)
	Kit.label(column,text,"body",color)
	if note!="":Kit.label(column,note,"note")
