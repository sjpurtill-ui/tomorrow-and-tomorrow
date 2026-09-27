extends Control
## The battle report: a paper card from the war leader (battle_account.gd).
## Headline, both sides before and after, how each fought, how it went,
## where things stand and what happens next, his advice, and at most three
## plain actions: watch the battle, talk to him, continue.
## local_terrain opens it when MilitaryCampaign reports a finished battle.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const BattleAccount:=preload("res://scripts/battle_account.gd")
const SimulationPause:=preload("res://scripts/hud/simulation_pause.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const META:="battle_report_panel"

var terrain:Node
var record:Dictionary={}
var account:Dictionary={}
var pause:=SimulationPause.new()
var card:PanelContainer
var buttons:Dictionary={}


## Opens the report on a recorded battle (by seed; newest when 0), or on
## `fallback` when the history does not hold it. Returns the panel, or null.
static func open(host:Node,seed:int=0,fallback:Dictionary={})->Control:
	if host==null: return null
	var found:=find_record(seed)
	if found.is_empty(): found=fallback.duplicate(true)
	if found.is_empty(): return null
	if host.has_meta(META) and is_instance_valid(host.get_meta(META)):
		(host.get_meta(META) as Node).queue_free()
	var layer:=CanvasLayer.new(); layer.name="BattleReportLayer"; layer.layer=80
	host.add_child(layer)
	var panel:Control=load("res://scripts/hud/battle_report_panel.gd").new()
	panel.terrain=host; panel.record=found
	layer.add_child(panel)
	host.set_meta(META,layer)
	return panel


static func find_record(seed:int)->Dictionary:
	var history:Array=WorldSimulation.military.battle_history if WorldSimulation.military!=null else []
	for past_variant in history:
		var past:Dictionary=past_variant
		if seed==0 or int(past.get("seed",-1))==seed: return past.duplicate(true)
	return {}


func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_STOP
	theme=T.control_theme()
	account=BattleAccount.build(record,BattleAccount.gather(record))
	pause.acquire(terrain)
	var scrim:=ColorRect.new(); scrim.color=T.SCRIM; scrim.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(scrim)
	_build()
	modulate.a=0.0
	var tween:=create_tween(); tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"modulate:a",1.0,float(T.MOTION.slow))


func _exit_tree()->void:
	pause.release()


func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled(); _act("continue")


func _build()->void:
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(center)
	card=PanelContainer.new(); card.name="Card"
	card.add_theme_stylebox_override("panel",T.paper_panel_style(true,T.RADIUS_CARD,32.0))
	card.custom_minimum_size=Vector2(820,0)
	center.add_child(card)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",16); card.add_child(column)
	var kicker:=_label(column,"WORD FROM THE FIELD · %s" % Chronicle.date_label(int(account.day)).to_upper(),"kicker",T.INK_MUTED)
	kicker.name="Kicker"
	var headline:=_label(column,String(account.headline),"title",T.INK); headline.name="Headline"
	headline.add_theme_font_override("font",T.voice_font()); headline.add_theme_font_size_override("font_size",30)
	var sub:=_label(column,_subline(),"small",T.INK_MUTED); sub.name="Where"
	column.add_child(_rule())
	var scroll:=ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size=Vector2(0,minf(560.0,get_viewport_rect().size.y-360.0))
	column.add_child(scroll)
	# A scroll box gives its child no width of its own: set it, or prose
	# wraps one letter to a line. The margin keeps figures clear of the bar.
	var inset:=MarginContainer.new(); inset.add_theme_constant_override("margin_right",20); inset.size_flags_horizontal=SIZE_EXPAND_FILL; scroll.add_child(inset)
	var body:=VBoxContainer.new(); body.size_flags_horizontal=SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",18); inset.add_child(body)
	body.custom_minimum_size.x=card.custom_minimum_size.x-64.0-28.0
	# Both sides, before and after.
	var sides:=HBoxContainer.new(); sides.add_theme_constant_override("separation",32); body.add_child(sides)
	_side_block(sides,"OUR SIDE",_our_rows(),String(account.ours.morale_words),BattleAccount.sent_line(account.ours))
	_side_block(sides,"THEIR SIDE",_their_rows(),"",_their_note())
	# How each side fought.
	var tactics:Dictionary=account.tactics
	if String(tactics.ours)!="":
		_section(body,"HOW THEY FOUGHT",[String(tactics.ours),String(tactics.theirs) if String(tactics.theirs)!="" else "They met us the same way."])
	_section(body,"HOW IT WENT",account.phases)
	_section(body,"WHERE THINGS STAND",[String(account.now)])
	_section(body,"WHAT HAPPENS NEXT",[String(account.next)])
	if String(account.advice)!="":
		var advice:=VBoxContainer.new(); advice.add_theme_constant_override("separation",4); body.add_child(advice)
		_label(advice,"%s ADVISES" % (String(account.general).to_upper() if String(account.general)!="" else "THE WAR LEADER"),"kicker",T.INK_MUTED)
		var quote:=_label(advice,"“%s”" % String(account.advice),"voice_small",T.INK); quote.name="Advice"
		quote.add_theme_font_override("font",T.voice_font(true))
	column.add_child(_rule())
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",12); row.alignment=BoxContainer.ALIGNMENT_END; column.add_child(row)
	for action_variant in account.actions:
		var action:Dictionary=action_variant
		var id:=String(action.id)
		var button:=Button.new(); button.name=id.capitalize().replace(" ","")
		button.text=String(action.label)
		T.text(button,"body",T.INK)
		button.custom_minimum_size=Vector2(0,44)
		var primary:=id in ["continue","aftermath"]
		button.add_theme_stylebox_override("normal",T.action_button_style(primary))
		button.pressed.connect(_act.bind(id))
		row.add_child(button); buttons[id]=button
	if buttons.has("continue"): (buttons.continue as Button).grab_focus.call_deferred()
	elif buttons.has("aftermath"): (buttons.aftermath as Button).grab_focus.call_deferred()


func _subline()->String:
	var parts:Array[String]=[_cap(String(account.where))]
	if int(account.exchanges)>0: parts.append("%s of fighting" % String(account.duration))
	return " · ".join(parts)


func _our_rows()->Array:
	var ours:Dictionary=account.ours
	var rows:Array=[["Went into the fight",int(ours.in_fight),true],["Killed",int(ours.killed),true],["Wounded",int(ours.wounded),true],
		["Ran off",int(ours.fled),false],["Taken captive",int(ours.captured),false],["Left to hold the town",int(ours.detached),false],
		["Still with %s" % (String(account.general) if String(account.general)!="" else "the band"),int(ours.present),true]]
	return rows


func _their_rows()->Array:
	var theirs:Dictionary=account.theirs
	var had:String=BattleAccount.count_words(int(theirs.seen_low)) if bool(theirs.exact) else preload("res://scripts/hud/army_marks.gd").about_range(int(theirs.seen_low),int(theirs.seen_high))
	return [["Had",had,true],["Killed or hurt" if bool(theirs.counted) else "Brought down, we think",int(theirs.fell),true],
		["Ran",int(theirs.fled),false],["Taken by us",int(theirs.taken),false]]


func _their_note()->String:
	var theirs:Dictionary=account.theirs
	var notes:Array[String]=[]
	if bool(theirs.exact): notes.append("Few enough to count.")
	else: notes.append("Counted by eye across the field.")
	if not bool(theirs.counted): notes.append("We did not hold the ground, so this is our best guess.")
	if String(theirs.commander)!="" and String(theirs.commander_fate) not in ["","in command","unknown"]:
		notes.append("Their leader %s %s." % [String(theirs.commander),_fate_words(String(theirs.commander_fate))])
	return " ".join(notes)


func _fate_words(fate:String)->String:
	return String({"escaped":"got away","captured":"is our captive","killed":"was killed","wounded, but escaped":"was wounded but got away"}.get(fate,fate))


func _side_block(parent:Node,title:String,rows:Array,morale:String,note:String)->void:
	var box:=VBoxContainer.new(); box.size_flags_horizontal=SIZE_EXPAND_FILL; box.size_flags_stretch_ratio=1.0; box.add_theme_constant_override("separation",6); parent.add_child(box)
	box.custom_minimum_size.x=330.0
	box.name=title.replace(" ","").capitalize()
	var heading:=_label(box,title,"kicker",T.INK_MUTED); heading.name="Title"
	var grid:=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",16); grid.add_theme_constant_override("v_separation",4); box.add_child(grid)
	for row_variant in rows:
		var row:Array=row_variant
		var value:Variant=row[1]
		# Optional rows appear only when something happened.
		if not bool(row[2]) and value is int and int(value)<=0: continue
		var name:=_label(grid,String(row[0]),"body",T.BODY); name.size_flags_horizontal=SIZE_EXPAND_FILL
		name.autowrap_mode=TextServer.AUTOWRAP_OFF
		var number:=_label(grid,("none" if int(value)<=0 else str(value)) if value is int else String(value),"value",T.INK)
		number.autowrap_mode=TextServer.AUTOWRAP_OFF
		number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	if morale!="": _label(box,"They are %s." % morale,"small",T.BODY)
	if note!="": _label(box,note,"small",T.INK_MUTED)


func _section(parent:Node,title:String,lines:Array)->void:
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",4); parent.add_child(box)
	box.name=title.capitalize().replace(" ","")
	_label(box,title,"kicker",T.INK_MUTED)
	for line in lines:
		if String(line)!="": _label(box,String(line),"body",T.BODY)


func _label(parent:Node,text:String,role:String,color:Color)->Label:
	var label:=Label.new(); label.text=text; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x=0
	T.text(label,role,color); parent.add_child(label)
	return label


func _rule()->Control:
	var rule:=ColorRect.new(); rule.color=T.RULE; rule.custom_minimum_size=Vector2(0,1)
	return rule


func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)


func _act(id:String)->void:
	var seed:=int(record.get("seed",0))
	var host:=terrain
	match id:
		"watch":
			_close()
			var ui:Node=get_tree().root.get_node_or_null("MilitaryCommandUI")
			if ui!=null: ui.call_deferred("_open_battle_graphics",0,seed)
		"talk":
			var commander:Dictionary=(record.get(String(record.get("home_side","attacker")),{}) as Dictionary).get("commander",{})
			_close()
			talk_to(commander)
		"aftermath":
			_close()
			if is_instance_valid(host) and host.has_method("_open_war_planning"): host.call_deferred("_open_war_planning")
		_:
			_close()


## The general who fought, summoned into the one court; else the court at rest.
static func talk_to(commander:Dictionary)->void:
	var director:Node=preload("res://scripts/audience_director.gd").court_node()
	if director==null: return
	var figure:=String(commander.get("figure_id",""))
	if figure!="" and director.has_method("summon") and director.call("summon",{"figure_id":figure})!=null: return
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal") if GovernmentPeopleSystem.has_method("officeholder") else {}
	if int(marshal.get("person_id",0))>0 and director.has_method("summon") and director.call("summon",{"person_id":int(marshal.person_id)})!=null: return
	director.call("open_court",{})


func _close()->void:
	var layer:=get_parent()
	if is_instance_valid(terrain) and terrain.has_meta(META) and terrain.get_meta(META)==layer: terrain.remove_meta(META)
	if layer is CanvasLayer: layer.queue_free()
	else: queue_free()
