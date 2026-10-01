extends Control
## THE BATTLE SCREEN: one battle as a picture of the fight, read at a glance.
##
## Across the top, who is winning (a bar in the two sides' colours, and the
## odds by the engine's own measure of it) and each side: its general and the
## way he chose to fight (marked when the enemy has undone it), its strength
## as a bar that shrinks day by day, split into the men still standing and
## those killed, wounded, fled and taken, and its heart. In the middle, the
## field (hud/battle_field.gd): the ground, the engine's blocks drawn as their
## own kit, where the lines meet and the day's attacks as arrows. Below, the
## battle's days as a track to scrub or play, why one side has the better of
## it, and what changed. A battle being fought follows the days; a finished
## one opens on its result and plays back day by day. Nothing here fights a
## battle (battle_record.gd reads the record; battle_field_model.gd lays it
## out). A skirmish (one block a side, or a fight over at the first blow) is
## a small drawn card instead (hud/skirmish_scene.gd).

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Record:=preload("res://scripts/battle_record.gd")
const Account:=preload("res://scripts/battle_account.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")
const SimulationPause:=preload("res://scripts/hud/simulation_pause.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Model:=preload("res://scripts/hud/battle_field_model.gd")
const FieldScript:=preload("res://scripts/hud/battle_field.gd")
const TimelineScript:=preload("res://scripts/hud/battle_timeline.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const VIEW_PATH:="res://scripts/hud/battle_view.gd"

## The widest the sheet grows.
const SHEET_MAX:=1800.0
## Seconds each day is shown while the battle plays.
const PLAY_SECONDS:=1.4
## Reasons and changes shown at most.
const WHY_SHOWN:=5
const CHANGES_SHOWN:=3
## The weapons each age's battles cross, as the war chart marks them.
const ERA_MARK_WORDS:=["Crossed spears","Crossed swords","Crossed muskets","Crossed rifles","The armour sign","The lattice sign"]

var host:Node
var record:Dictionary={}
var live:=false
var view:Dictionary={}
## 0 is the two sides drawn up; k is the end of day k.
var step:=-1
var following:=true
var playing:=false
var play_clock:=0.0
var pause:=SimulationPause.new()
var paused_here:=false
var signature:=""
var poll:=0.0
## The battle shown, kept apart from the record: a battle that ends is
## cleared where it was fought and read again from its report.
var battle_id:=""
var battle_seed:=-1
## The battle whose skirmish has been drawn already (a live one is redrawn as
## it goes on, without marching in again).
var scene_shown:=""
var skirmish_scene:Control
var sheet:PanelContainer
var built:=""
var field:Control
var timeline:Control
var buttons:Dictionary={}
## The controls a new day updates in place.
var parts:Dictionary={}
var left_colour:=Color()
var right_colour:=Color()
var left_text:=Color()
var right_text:=Color()


func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_STOP
	theme=T.control_theme()
	var scrim:=ColorRect.new(); scrim.name="Scrim"; scrim.color=T.SCRIM; scrim.set_anchors_and_offsets_preset(PRESET_FULL_RECT); scrim.mouse_filter=MOUSE_FILTER_STOP; add_child(scrim)
	if not live and is_instance_valid(host):
		pause.acquire(host); paused_here=true
	_refresh()
	modulate.a=0.0
	var tween:=create_tween(); tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"modulate:a",1.0,float(T.MOTION.slow))


func _exit_tree()->void:
	if paused_here: pause.release()
	var ui:Node=get_tree().root.get_node_or_null("MilitaryCommandUI") if is_inside_tree() else null
	if ui!=null and ui.get("battle_graphics")==self: ui.set("battle_graphics",null)


func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_ESCAPE: get_viewport().set_input_as_handled(); close()
			KEY_LEFT: get_viewport().set_input_as_handled(); _stop_playing(); _step_by(-1)
			KEY_RIGHT: get_viewport().set_input_as_handled(); _stop_playing(); _step_by(1)
			KEY_SPACE: get_viewport().set_input_as_handled(); _act("play")


## Plays the days while asked; a live battle is read again as the days pass,
## and when it ends the screen shows how it ended.
func _process(delta:float)->void:
	if playing:
		play_clock+=delta
		if play_clock>=PLAY_SECONDS:
			play_clock=0.0
			if step>=_count(): _stop_playing()
			else: _select(step+1,true)
	if not live: return
	poll+=delta
	if poll<0.4: return
	poll=0.0
	var View:=load(VIEW_PATH)
	var found:Dictionary=View.find(battle_id) if battle_id!="" else {}
	if found.is_empty() and battle_seed>=0: found=View.find(battle_seed)
	if found.is_empty(): return
	if not bool(found.get("live",false)):
		record=found.record; live=false; following=true
		_refresh()
		return
	var now:Dictionary=found.record
	var mark:=_signature(now)
	if mark!=signature:
		record=now
		_refresh()


func _signature(source:Dictionary)->String:
	var battle:Dictionary=source.get("battle",{})
	return "%s|%d|%d|%d|%s" % [String(source.get("id","")),int(source.get("round",(source.get("rounds",[]) as Array).size())),int(battle.get("exchange",0)),(battle.get("phases",[]) as Array).size(),str(host.get("game_speed")) if is_instance_valid(host) else ""]


func _count()->int:
	return (view.get("phases",[]) as Array).size()


# --- Building ---------------------------------------------------------------------------

func _refresh()->void:
	if String(record.get("id",""))!="": battle_id=String(record.id)
	if record.has("seed"): battle_seed=int(record.seed)
	var View:=load(VIEW_PATH)
	view=Record.view(record,View.words(record,live))
	signature=_signature(record)
	var player:=bool(view.player)
	left_colour=T.TEAL if player else T.AMBER
	right_colour=T.RED if player else T.BLUE
	left_text=T.TEAL_TEXT if player else T.AMBER_TEXT
	right_text=T.RED_TEXT if player else T.BLUE_TEXT
	var count:=_count()
	if following or step<0 or step>count: step=count
	var kind:="card" if bool(view.skirmish) else "sheet"
	if kind=="sheet" and built=="sheet" and is_instance_valid(sheet):
		_update_static()
		_show_step(true)
		return
	_rebuild()


func _rebuild()->void:
	if is_instance_valid(sheet): sheet.get_parent().queue_free()
	buttons.clear(); parts.clear()
	field=null; timeline=null
	if bool(view.skirmish):
		built="card"; _build_card()
	else:
		built="sheet"; _build_panel()


func _build_card()->void:
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(center)
	sheet=PanelContainer.new(); sheet.name="Card"
	sheet.add_theme_stylebox_override("panel",T.paper_panel_style(true,T.RADIUS_CARD,32.0))
	sheet.custom_minimum_size=Vector2(minf(620.0,get_viewport_rect().size.x-32.0),0)
	center.add_child(sheet)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",14); sheet.add_child(column)
	_label(column,"A SKIRMISH%s" % _where_suffix().to_upper(),"kicker",T.INK_MUTED).name="Kicker"
	var headline:=_label(column,String(view.one_line) if String(view.one_line)!="" else String(view.phrase)+".","title",T.INK)
	headline.name="Headline"; headline.add_theme_font_override("font",T.voice_font()); headline.add_theme_font_size_override("font_size",26)
	# The fight itself, drawn: both bands, the ground, and how it went.
	var scene:=preload("res://scripts/hud/skirmish_scene.gd").new(); scene.name="Scene"
	column.add_child(scene)
	scene.configure(view,left_colour,right_colour,_town_behind())
	if scene_shown==battle_id and battle_id!="": scene.skip_approach()
	scene_shown=battle_id
	skirmish_scene=scene
	var line:=HBoxContainer.new(); line.add_theme_constant_override("separation",24); column.add_child(line)
	for key in ["left","right"]:
		var side:Dictionary=view.sides[key]
		var box:=VBoxContainer.new(); box.name="Side"+key.capitalize(); box.size_flags_horizontal=SIZE_EXPAND_FILL; line.add_child(box)
		_label(box,_side_kicker(key),"kicker",left_text if key=="left" else right_text)
		var totals:Dictionary=side.totals
		var exact:=bool(side.exact)
		_label(box,"%s went in; %s still standing." % [_n(int(totals.went_in),exact),_n(int(totals.standing),exact)],"body",T.BODY)
		var lost:=_lost_words(totals,exact,bool(view.player) and key=="right")
		if lost!="": _label(box,lost,"small",T.INK_MUTED).name="Lost"
	var events:Array=[]
	for phase in view.phases: events.append_array(phase.events)
	if not events.is_empty(): _label(column,String(events[-1])+".","body",T.BODY).name="Event"
	column.add_child(_rule())
	var row:=HBoxContainer.new(); row.alignment=BoxContainer.ALIGNMENT_END; row.add_theme_constant_override("separation",12); column.add_child(row)
	if not live:
		var again:=Button.new(); again.name="WatchAgain"; again.text="Watch again"
		T.text(again,"body",T.INK); again.custom_minimum_size=Vector2(0,40)
		again.add_theme_stylebox_override("normal",T.action_button_style(false))
		again.pressed.connect(func()->void: if is_instance_valid(skirmish_scene): skirmish_scene.replay())
		row.add_child(again)
	_time_button(row)
	_button(row,"Close","close",true)


## The town the right-hand side stood before, drawn behind it: the one we
## went against. "" for a fight in the field or at home.
func _town_behind()->String:
	var threat:Dictionary=record.get("threat",{}) if record.get("threat") is Dictionary else {}
	if bool(record.get("field_encounter",threat.get("field_encounter",false))): return ""
	if String(view.get("left",""))!="attacker": return ""
	return String(record.get("target_region_name",threat.get("target_region_name","")))


func _build_panel()->void:
	var shell:=MarginContainer.new(); shell.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: shell.add_theme_constant_override("margin_"+edge,20)
	add_child(shell)
	var row:=HBoxContainer.new(); row.alignment=BoxContainer.ALIGNMENT_CENTER; shell.add_child(row)
	sheet=PanelContainer.new(); sheet.name="Sheet"
	sheet.add_theme_stylebox_override("panel",T.paper_panel_style(true,T.RADIUS_CARD,22.0))
	var width:=minf(SHEET_MAX,get_viewport_rect().size.x-40.0)
	sheet.custom_minimum_size=Vector2(width,0)
	sheet.size_flags_vertical=SIZE_EXPAND_FILL
	row.add_child(sheet)
	var outer:=VBoxContainer.new(); outer.add_theme_constant_override("separation",10); sheet.add_child(outer)
	_build_header(outer)
	_build_balance(outer)
	_build_sides(outer)
	field=FieldScript.new(); field.name="Field"
	outer.add_child(field)
	_build_timeline(outer)
	_build_reasons(outer)
	_update_static()
	_show_step(false)


func _build_header(parent:Node)->void:
	var head:=HBoxContainer.new(); head.name="Header"; head.add_theme_constant_override("separation",16); parent.add_child(head)
	var words:=VBoxContainer.new(); words.add_theme_constant_override("separation",2); words.size_flags_horizontal=SIZE_EXPAND_FILL; head.add_child(words)
	parts.kicker=_label(words,"","kicker",T.INK_MUTED); parts.kicker.name="Kicker"
	var headline:=_label(words,"","title",T.INK); headline.name="Headline"
	headline.add_theme_font_override("font",T.voice_font()); headline.add_theme_font_size_override("font_size",30)
	parts.headline=headline
	parts.where=_label(words,"","small",T.INK_MUTED); parts.where.name="Where"
	parts.account=_label(words,"","body",T.BODY); parts.account.name="Account"
	var mark:=EraMark.new(); mark.name="EraMark"; mark.custom_minimum_size=Vector2(72,72)
	head.add_child(mark); parts.era=mark


func _build_balance(parent:Node)->void:
	var box:=VBoxContainer.new(); box.name="Balance"; box.add_theme_constant_override("separation",3); parent.add_child(box)
	var bar:=ProgressStrip.new(); bar.name="Progress"
	bar.custom_minimum_size=Vector2(0,20)
	bar.tooltip_text="Who has the better of the fight, by the engine's measure: men and heart in the line in full, the reserve in part."
	box.add_child(bar); parts.progress=bar
	var ends:=HBoxContainer.new(); box.add_child(ends)
	var left_name:=_label(ends,"","small",left_text); left_name.size_flags_horizontal=SIZE_EXPAND_FILL
	left_name.add_theme_font_override("font",T.font("ui_strong")); left_name.autowrap_mode=TextServer.AUTOWRAP_OFF
	var odds:=_label(ends,"","body",T.INK); odds.name="Odds"; odds.size_flags_horizontal=SIZE_EXPAND_FILL
	odds.mouse_filter=Control.MOUSE_FILTER_PASS; odds.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; odds.add_theme_font_override("font",T.font("ui_strong")); odds.autowrap_mode=TextServer.AUTOWRAP_OFF
	var right_name:=_label(ends,"","small",right_text); right_name.size_flags_horizontal=SIZE_EXPAND_FILL
	right_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; right_name.add_theme_font_override("font",T.font("ui_strong")); right_name.autowrap_mode=TextServer.AUTOWRAP_OFF
	parts.left_name=left_name; parts.right_name=right_name; parts.odds=odds


func _build_sides(parent:Node)->void:
	var row:=HBoxContainer.new(); row.name="Sides"; row.add_theme_constant_override("separation",40); parent.add_child(row)
	for key in ["left","right"]:
		var box:=VBoxContainer.new(); box.name="Side"+key.capitalize(); box.size_flags_horizontal=SIZE_EXPAND_FILL; box.add_theme_constant_override("separation",5)
		row.add_child(box)
		var top:=HBoxContainer.new(); top.add_theme_constant_override("separation",10); box.add_child(top)
		var kicker:=_label(top,_side_kicker(key),"kicker",left_text if key=="left" else right_text); kicker.autowrap_mode=TextServer.AUTOWRAP_OFF
		kicker.size_flags_vertical=SIZE_SHRINK_CENTER
		var name:=_label(top,"","value",T.INK); name.name="Name"; name.autowrap_mode=TextServer.AUTOWRAP_OFF
		var general:=_label(top,"","small",T.BODY); general.name="General"; general.size_flags_horizontal=SIZE_EXPAND_FILL
		general.autowrap_mode=TextServer.AUTOWRAP_OFF; general.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; general.size_flags_vertical=SIZE_SHRINK_CENTER
		parts[key+"_name"]=name; parts[key+"_general"]=general
		var how:=HBoxContainer.new(); how.add_theme_constant_override("separation",8); how.custom_minimum_size.y=26.0; box.add_child(how)
		var chip:=_label(how,"","small",T.INK); chip.name="Tactic"; chip.autowrap_mode=TextServer.AUTOWRAP_OFF
		chip.add_theme_stylebox_override("normal",T.chip_style()); chip.mouse_filter=Control.MOUSE_FILTER_PASS
		var undone:=_label(how,"","small",T.RED_TEXT); undone.name="Countered"; undone.autowrap_mode=TextServer.AUTOWRAP_OFF
		undone.size_flags_vertical=SIZE_SHRINK_CENTER
		parts[key+"_tactic"]=chip; parts[key+"_undone"]=undone
		var strength:=HBoxContainer.new(); strength.add_theme_constant_override("separation",12); box.add_child(strength)
		var bar:=StrengthBar.new(); bar.name="Strength"; bar.size_flags_horizontal=SIZE_EXPAND_FILL; bar.custom_minimum_size=Vector2(160,20)
		bar.size_flags_vertical=SIZE_SHRINK_CENTER
		bar.colour=left_colour if key=="left" else right_colour
		strength.add_child(bar)
		var standing:=_label(strength,"","body",T.INK); standing.name="Standing"; standing.autowrap_mode=TextServer.AUTOWRAP_OFF
		standing.add_theme_font_override("font",T.font("ui_strong")); standing.custom_minimum_size.x=190
		parts[key+"_bar"]=bar; parts[key+"_standing"]=standing
		var heart_row:=HBoxContainer.new(); heart_row.add_theme_constant_override("separation",12); box.add_child(heart_row)
		var heart:=HeartBar.new(); heart.name="Heart"; heart.size_flags_horizontal=SIZE_EXPAND_FILL; heart.custom_minimum_size=Vector2(160,8)
		heart.size_flags_vertical=SIZE_SHRINK_CENTER
		heart.tooltip_text="Heart: the will to keep fighting of those still standing, weighed by their men."
		heart_row.add_child(heart)
		var heart_words:=_label(heart_row,"","small",T.BODY); heart_words.name="HeartWords"; heart_words.autowrap_mode=TextServer.AUTOWRAP_OFF; heart_words.custom_minimum_size.x=190
		parts[key+"_heart"]=heart; parts[key+"_heart_words"]=heart_words
		var totals:=HBoxContainer.new(); totals.name="Totals"; totals.add_theme_constant_override("separation",20); box.add_child(totals)
		for pair in [["killed","Killed"],["wounded","Wounded"],["fled","Fled"],["captured","Taken"]]:
			var item:=HBoxContainer.new(); item.name=String(pair[1]); item.add_theme_constant_override("separation",5); totals.add_child(item)
			var mark:=CasualtyMark.new(); mark.kind=String(pair[0]); mark.custom_minimum_size=Vector2(20,20); mark.size_flags_vertical=SIZE_SHRINK_CENTER
			item.add_child(mark)
			var value:=_label(item,"","body",T.INK); value.name="Value"; value.autowrap_mode=TextServer.AUTOWRAP_OFF
			value.add_theme_font_override("font",T.font("ui_strong"))
			var word:=_label(item,String(pair[1]).to_lower(),"small",T.INK_MUTED); word.name="Word"; word.autowrap_mode=TextServer.AUTOWRAP_OFF
			word.size_flags_vertical=SIZE_SHRINK_CENTER
			parts[key+"_"+String(pair[0])]=value


func _build_timeline(parent:Node)->void:
	var row:=HBoxContainer.new(); row.name="Timeline"; row.add_theme_constant_override("separation",12); parent.add_child(row)
	var back:=_button(row,"Earlier","earlier",false); back.tooltip_text="The day before."
	var play:=_button(row,"Play","play",true); play.tooltip_text="Play the battle day by day."
	play.icon=Icons.command_texture("resume",T.INK,24); play.custom_minimum_size.x=104
	var forward:=_button(row,"Later","later",false); forward.tooltip_text="The day after."
	for b:Button in [back,play,forward]: b.size_flags_vertical=SIZE_SHRINK_CENTER
	timeline=TimelineScript.new(); timeline.name="Days"
	timeline.chosen.connect(_on_day_chosen)
	row.add_child(timeline)
	_time_button(row)
	var close_button:=_button(row,"Close","close",true)
	close_button.size_flags_vertical=SIZE_SHRINK_CENTER
	if buttons.has("time"): (buttons.time as Button).size_flags_vertical=SIZE_SHRINK_CENTER


func _build_reasons(parent:Node)->void:
	# A fixed height, so the field never changes size from one day to the next.
	var row:=HBoxContainer.new(); row.name="Reasons"; row.add_theme_constant_override("separation",40); parent.add_child(row)
	row.custom_minimum_size.y=122.0; row.clip_contents=true
	var why:=VBoxContainer.new(); why.name="Why"; why.size_flags_horizontal=SIZE_EXPAND_FILL; why.size_flags_stretch_ratio=1.2; why.add_theme_constant_override("separation",4)
	row.add_child(why)
	var top:=HBoxContainer.new(); top.add_theme_constant_override("separation",12); why.add_child(top)
	_label(top,"WHY","kicker",T.INK_MUTED).autowrap_mode=TextServer.AUTOWRAP_OFF
	var legend:=_label(top,"","small",T.INK_MUTED); legend.name="WhyLegend"; legend.autowrap_mode=TextServer.AUTOWRAP_OFF
	parts.why_legend=legend
	var bars:=WhyBars.new(); bars.name="WhyBars"; bars.size_flags_horizontal=SIZE_EXPAND_FILL; bars.custom_minimum_size=Vector2(300,float(WHY_SHOWN)*19.0)
	why.add_child(bars); parts.why=bars
	var changes:=VBoxContainer.new(); changes.name="Changes"; changes.size_flags_horizontal=SIZE_EXPAND_FILL; changes.add_theme_constant_override("separation",4)
	row.add_child(changes)
	_label(changes,"WHAT CHANGED","kicker",T.INK_MUTED)
	var lines:=VBoxContainer.new(); lines.name="Lines"; lines.add_theme_constant_override("separation",3); changes.add_child(lines)
	parts.changes=lines


# --- What a new reading or a new day changes ----------------------------------------------

## What stays the same from day to day: names, place, generals, the era's
## mark, the days on the track (a live battle adds one each day).
func _update_static()->void:
	parts.kicker.text="THE FIGHT %s · %s" % [_where_words().to_upper(),_when_words().to_upper()] if _when_words()!="" else "THE FIGHT %s" % _where_words().to_upper()
	var account:=String(view.one_line)
	(parts.account as Label).text=account if not live and account!="" and account!=String(view.phrase)+"." else ""
	(parts.account as Label).visible=(parts.account as Label).text!=""
	(parts.left_name as Label).text=_cap(String(view.names.left))
	(parts.right_name as Label).text=_cap(String(view.names.right))
	var era:=Model.era_of(record,String(view.get("stage","hearth")))
	(parts.era as Control).set("era",era)
	(parts.era as Control).tooltip_text="%s, as the war chart marks this battle." % String(ERA_MARK_WORDS[clampi(era,0,ERA_MARK_WORDS.size()-1)])
	(parts.era as Control).queue_redraw()
	for key in ["left","right"]:
		(parts[key+"_name"] as Label).text=_cap(String(view.names[key]))
		var general:Dictionary=view.sides[key].general
		var who:=String(general.name); var about:=String(general.line).trim_suffix(".")
		(parts[key+"_general"] as Label).text=(who+(", " if who!="" and about!="" else "")+(about.substr(0,1).to_lower()+about.substr(1) if who!="" else about)).strip_edges()
	field.set("left_colour",left_colour); field.set("right_colour",right_colour)
	field.set("names",{"left":String(view.names.left),"right":String(view.names.right)})
	var labels:Array=[]; var tips:Array=[]
	for index in _count()+1:
		labels.append(Model.day_label(view,index))
		tips.append(_day_tip(index))
	timeline.set("left_colour",left_colour); timeline.set("right_colour",right_colour)
	timeline.configure(labels,view.losses_by_phase,tips,step,_count() if live else -1)


## Everything that belongs to the day shown.
func _show_step(animate:bool)->void:
	var count:=_count()
	step=clampi(step,0,count)
	var shown:=Model.phase_at(view,step)
	var player:=bool(view.player)
	var progress:=float(shown.get("progress",0.0)) if step>0 else 0.0
	var phrase:=String(view.phrase)
	if step<count or (live and step==0):
		phrase=Record.phrase(progress,0.0,player,String(view.names.left),String(view.names.right))
	if step==0: phrase="The two sides are drawn up"
	(parts.headline as Label).text=phrase
	var sub:=[_cap(String(view.ground.words)),String(view.status)]
	if live and String(record.get("id",""))!="": sub.append(_battle_day_words())
	(parts.where as Label).text="  ·  ".join(PackedStringArray(sub))
	# The balance, and the odds it makes.
	var bar:ProgressStrip=parts.progress
	bar.value=progress
	var previous:=Model.phase_at(view,step-1)
	bar.ghost=float(previous.get("progress",0.0)) if step>1 else 0.0
	bar.left_colour=left_colour; bar.right_colour=right_colour
	bar.queue_redraw()
	var odds:=Model.odds_words(progress,player,_cap(_strip(String(view.names.left))),_cap(_strip(String(view.names.right))))
	if step==0: (parts.odds as Label).text="Before the first blow"
	elif odds=="": (parts.odds as Label).text=""
	else: (parts.odds as Label).text="Odds now: %s" % odds
	(parts.odds as Label).tooltip_text="The engine's measure of who has the better of it, said as odds."
	# Each side: its tactic, its strength and losses, its heart.
	for key in ["left","right"]:
		var side:Dictionary=view.sides[key]
		var totals:=Model.totals_at(view,step,key)
		var before:=Model.totals_at(view,maxi(0,step-1),key)
		var exact:=bool(side.exact)
		var strip:StrengthBar=parts[key+"_bar"]
		strip.colour=left_colour if key=="left" else right_colour
		strip.totals=totals; strip.ghost=int(before.get("standing",totals.standing)) if step>0 else int(totals.standing)
		strip.tooltip_text=_strength_words(totals,exact,key)
		strip.queue_redraw()
		(parts[key+"_standing"] as Label).text="%s of %s standing" % [_n(int(totals.standing),exact),_n(int(totals.went_in),exact)]
		for kind in ["killed","wounded","fled","captured"]:
			# Their men we took are ours to count: said exactly, as the report does.
			var counted:bool=exact or (String(kind)=="captured" and player and key=="right")
			(parts[key+"_"+kind] as Label).text="none" if int(totals[kind])<=0 else _n(int(totals[kind]),counted)
		var heart:=Model.heart_at(view,step,key)
		var heart_bar:HeartBar=parts[key+"_heart"]
		heart_bar.value=heart; heart_bar.queue_redraw()
		(parts[key+"_heart_words"] as Label).text="Heart: %s" % (Account.morale_words(heart) if heart>=0.0 else "none left standing")
		var tactic:Dictionary=((shown if step>0 else Model.phase_at(view,1)).get("tactics",{}) as Dictionary).get(key,{})
		var chip:Label=parts[key+"_tactic"]
		var words:=String(tactic.get("words",""))
		chip.text=_cap(words)
		chip.visible=chip.text!=""
		chip.tooltip_text="How %s general is fighting%s." % [("our" if key=="left" else "their") if player else _possessive(String(view.names[key])),(" this day" if step>0 else "")] if words!="" else ""
		var undone:Label=parts[key+"_undone"]
		undone.text=""
		if step>0 and bool(tactic.get("countered",false)):
			var by:=String(tactic.get("by",""))
			var whose:=("Their" if key=="left" else "Our") if player else _cap(_possessive(String(view.names["right" if key=="left" else "left"])))
			undone.text="Undone. %s answer: %s" % [whose,by.substr(0,1).to_lower()+by.substr(1)] if by!="" else "Undone by %s way of fighting" % whose.to_lower()
		elif step>0 and bool(tactic.get("changed",false)): undone.text="A new way of fighting"
		undone.add_theme_color_override("font_color",T.RED_TEXT if bool(tactic.get("countered",false)) else T.INK_MUTED)
		undone.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; undone.size_flags_horizontal=SIZE_EXPAND_FILL
		undone.tooltip_text=undone.text; undone.mouse_filter=Control.MOUSE_FILTER_PASS
	# The field, the days, the reasons.
	field.set("frontage",_frontage_note())
	field.call("show_step",view,record,step,animate)
	timeline.select(step)
	_show_reasons(shown)
	(buttons.earlier as Button).disabled=step<=0
	(buttons.later as Button).disabled=step>=count
	_update_play()


func _show_reasons(shown:Dictionary)->void:
	var player:=bool(view.player)
	var items:Array=shown.get("why",[]) if step>0 else []
	var bars:WhyBars=parts.why
	bars.items=items.slice(0,WHY_SHOWN); bars.left_colour=left_colour; bars.right_colour=right_colour
	bars.left_text=left_text; bars.right_text=right_text
	bars.empty_words="Nothing has been fought yet." if step==0 else "Too little is known to say."
	bars.queue_redraw()
	(parts.why_legend as Label).text=("Bars to the left help us; to the right, them." if player else "Each bar leans toward the side it helps.") if not items.is_empty() else ""
	var lines:VBoxContainer=parts.changes
	for child in lines.get_children(): child.queue_free()
	var events:Array=shown.get("events",[]) if step>0 else []
	if events.is_empty():
		_label(lines,"The two sides stand facing each other." if step==0 else "Nothing changed but the slow wearing down of both lines.","small",T.INK_MUTED)
	for line in events.slice(0,CHANGES_SHOWN):
		# The main clause on the screen; the whole line when pointed at.
		var said:=String(line).get_slice("; ",0)
		var label:=_label(lines,"•  %s." % said,"body",T.BODY)
		label.autowrap_mode=TextServer.AUTOWRAP_OFF; label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		label.tooltip_text=String(line)+"."
		label.mouse_filter=Control.MOUSE_FILTER_PASS
	if events.size()>CHANGES_SHOWN:
		var more:=_label(lines,"and %s more" % _count_word(events.size()-CHANGES_SHOWN),"small",T.INK_MUTED)
		more.mouse_filter=Control.MOUSE_FILTER_PASS
		more.tooltip_text=". ".join(PackedStringArray(events.slice(CHANGES_SHOWN)))+"."


func _update_play()->void:
	if not buttons.has("play"): return
	var play:Button=buttons.play
	play.text="Pause" if playing else "Play"
	play.icon=Icons.command_texture("pause" if playing else "resume",T.INK,24)
	play.disabled=_count()<=0


# --- Acting -------------------------------------------------------------------------------

func _act(id:String)->void:
	match id:
		"close": close()
		"earlier": _stop_playing(); _step_by(-1)
		"later": _stop_playing(); _step_by(1)
		"play":
			if built!="sheet": return
			if playing: _stop_playing(); return
			if step>=_count(): _select(0,false)
			playing=true; play_clock=0.0
			_update_play()
		"time":
			if is_instance_valid(host) and host.has_method("_set_game_speed"):
				host.call("_set_game_speed",1.0 if float(host.get("game_speed"))<=0.0 else 0.0)
			_rebuild()


func _on_day_chosen(index:int)->void:
	_stop_playing()
	_select(index,true)


func _stop_playing()->void:
	if not playing: return
	playing=false
	_update_play()


func _select(index:int,animate:bool=true)->void:
	step=clampi(index,0,_count())
	following=step>=_count()
	if built=="sheet" and is_instance_valid(sheet): _show_step(animate)
	else: _rebuild()


func _step_by(delta:int)->void:
	_select(step+delta)


func close()->void:
	var layer:=get_parent()
	if is_instance_valid(host) and host.has_meta(load(VIEW_PATH).META) and host.get_meta(load(VIEW_PATH).META)==layer: host.remove_meta(load(VIEW_PATH).META)
	if layer is CanvasLayer: layer.queue_free()
	else: queue_free()


# --- What is shown ---------------------------------------------------------------------------

## Losses so far at the step shown; the finished battle's own totals at its end.
func _totals_at(side:Dictionary,key:String)->Dictionary:
	return Model.totals_at(view,step,key)


func _plates_shown()->Dictionary:
	return Model.plates_at(view,step)


# --- Words -----------------------------------------------------------------------------------

func _where_words()->String:
	var where:=String(view.where)
	if where=="" and String(view.place)!="": return "at "+String(view.place)
	if where=="" or where=="in the open country":
		# No town to name it by: the ground itself.
		where=Record.ground_place(String(view.ground.kind))
	return where


func _where_suffix()->String:
	return " "+_where_words()


func _when_words()->String:
	if live: return Chronicle.date_label(int(WorldSimulation.state.elapsed_days)) if WorldSimulation!=null else ""
	return Chronicle.date_label(int(view.day)) if int(view.day)>0 else ""


## Which day of the fighting it is, as the map letters it under the battle
## (hud/battle_marker_source.gd day_of: the days it has been fought).
func _battle_day_words()->String:
	var today:=int(WorldSimulation.state.elapsed_days) if WorldSimulation!=null else int(view.started)
	var day:=int(preload("res://scripts/hud/battle_marker_source.gd").day_of(record,today))
	return "Day %s of the battle" % _count_word(day)


## How many the ground lets fight at once, when it holds some back: "Room
## for about 1,900 a side: 11 of 21 companies fighting." "" otherwise.
func _frontage_note()->String:
	var phase:=Model.phase_at(view,maxi(1,step))
	var capacity:=int(phase.get("capacity",0))
	var plates:=Model.plates_at(view,step)
	var side:Dictionary=plates.get("left",{})
	var fighting:=(side.get("front",[]) as Array).size()
	var total:=fighting+(side.get("rear",[]) as Array).filter(func(p:Dictionary)->bool: return String(p.state)=="reserve").size()
	if capacity<=0 or total<=fighting or fighting<=0: return ""
	var word:=String(view.sides.left.word)
	return "Room for %s a side: %s of %s %s %s" % [Marks.about(capacity),_grouped(fighting),_grouped(total),preload("res://scripts/battle_blocks.gd").plural(word),"in the line" if step==0 else "fighting"]


## A stop on the track, pointed at: the day, its hours and what each side lost.
func _day_tip(index:int)->String:
	if index<=0: return "The two sides drawn up, before the first blow."
	var phase:=Model.phase_at(view,index)
	var losses:Dictionary=phase.get("losses",{})
	var ours:=int((losses.get("left",{}) as Dictionary).get("total",0))
	var theirs:=int((losses.get("right",{}) as Dictionary).get("total",0))
	var when:=String(phase.get("when","")).to_lower()
	var head:="%s (%s)" % [Model.day_label(view,index),when] if when!="" and not when.begins_with("drawn") else Model.day_label(view,index)
	if bool(view.player): return "%s: we lost %s, they lost %s." % [head,_n(ours,true),_n(theirs,bool(view.sides.right.exact))]
	return "%s: %s lost %s, %s lost %s." % [head,_cap(String(view.names.left)),_n(ours,bool(view.sides.left.exact)),String(view.names.right),_n(theirs,bool(view.sides.right.exact))]


func _strength_words(totals:Dictionary,exact:bool,key:String)->String:
	var who:=("Ours" if key=="left" else "Theirs") if bool(view.player) else _cap(_strip(String(view.names[key])))
	var lost:=_lost_words(totals,exact,bool(view.player) and key=="right")
	return "%s: %s went in, %s still standing.\n%s" % [who,_n(int(totals.went_in),exact),_n(int(totals.standing),exact),lost]


func _side_kicker(key:String)->String:
	if bool(view.player): return "OUR SIDE" if key=="left" else "THEIR SIDE"
	var role:=String(view.sides[key].role)
	return "ATTACKING" if role=="attacker" else "DEFENDING"


## captives_counted: their men we took, ours to count exactly.
func _lost_words(totals:Dictionary,exact:bool,captives_counted:bool=false)->String:
	var parts_said:Array[String]=[]
	for pair in [["killed","killed"],["wounded","wounded"],["fled","ran"],["captured","taken"]]:
		if int(totals[pair[0]])>0: parts_said.append("%s %s" % [_n(int(totals[pair[0]]),exact or (captives_counted and pair[0]=="captured")),String(pair[1])])
	return _cap(", ".join(parts_said)+".") if not parts_said.is_empty() else "Nobody lost."


func _n(value:int,exact:bool)->String:
	return _grouped(value) if exact or value<=20 else Marks.about(value)


func _grouped(value:int)->String:
	return preload("res://scripts/hud/era_words.gd").grouped(value)


func _count_word(n:int)->String:
	var words:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
	return words[n] if n>=0 and n<words.size() else _grouped(n)


func _possessive(name:String)->String:
	var clean:=_strip(name)
	return clean+"'" if clean.ends_with("s") else clean+"'s"


func _strip(name:String)->String:
	return name.trim_prefix("the ").trim_prefix("The ")


func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)


# --- Small parts ------------------------------------------------------------------------------

func _label(parent:Node,text:String,role:String,color:Color)->Label:
	var label:=Label.new(); label.text=text; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	T.text(label,role,color); parent.add_child(label)
	return label


func _button(parent:Node,text:String,id:String,primary:bool)->Button:
	var button:=Button.new(); button.name=id.capitalize().replace(" ",""); button.text=text
	T.text(button,"body",T.INK)
	button.custom_minimum_size=Vector2(0,40)
	button.focus_mode=Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal",T.action_button_style(primary))
	button.add_theme_stylebox_override("hover",T.action_button_style(primary,true))
	button.add_theme_stylebox_override("disabled",T.button_disabled_style())
	button.add_theme_color_override("font_disabled_color",T.DISABLED)
	button.pressed.connect(_act.bind(id))
	parent.add_child(button); buttons[id]=button
	return button


func _time_button(row:Node)->void:
	if not live or not is_instance_valid(host) or not ("game_speed" in host) or not host.has_method("_set_game_speed"): return
	var held:=float(host.get("game_speed"))<=0.0
	_button(row,"Let the fight go on" if held else "Hold time","time",held)


func _rule()->Control:
	var rule:=ColorRect.new(); rule.color=T.RULE; rule.custom_minimum_size=Vector2(0,1)
	return rule


## Who is winning: the bar reaches toward the side that has the better of it;
## a fine mark shows where it stood the day before.
class ProgressStrip extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var value:=0.0
	var ghost:=0.0
	var left_colour:=Color.WHITE
	var right_colour:=Color.WHITE

	func _draw()->void:
		var w:=size.x; var h:=size.y
		var split:=clampf(0.5+value*0.5,0.0,1.0)*w
		draw_rect(Rect2(0,0,w,h),T.TRACK)
		draw_rect(Rect2(0,0,split,h),Color(left_colour,0.88))
		draw_rect(Rect2(split,0,w-split,h),Color(right_colour,0.88))
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE_STRONG,false,1.0)
		draw_line(Vector2(w*0.5,-3),Vector2(w*0.5,h+3),Color(T.PAPER,0.9),2.0)
		var before:=clampf(0.5+ghost*0.5,0.0,1.0)*w
		if absf(before-split)>2.0: draw_line(Vector2(before,1),Vector2(before,h-1),Color(T.PAPER,0.55),2.0)
		draw_line(Vector2(split,-4),Vector2(split,h+4),T.INK,3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(split-6,-8),Vector2(split+6,-8),Vector2(split,-2)]),T.INK)


## A side's strength: one bar the length of all who went in, the men still
## standing in the side's colour, then the killed, the wounded, the fled and
## the taken; a fine mark where the standing stood the day before.
class StrengthBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var totals:Dictionary={}
	var ghost:=0
	var colour:=Color.WHITE

	func _draw()->void:
		var w:=size.x; var h:=size.y
		draw_rect(Rect2(0,0,w,h),T.TRACK)
		var went:=float(maxi(1,int(totals.get("went_in",0))))
		var x:=0.0
		for kind in ["standing","killed","wounded","fled","captured"]:
			var n:=float(maxi(0,int(totals.get(kind,0))))
			if n<=0.0: continue
			var span:=w*n/went
			var rect:=Rect2(x,0,minf(span,w-x),h)
			CasualtyMark.fill(self,rect,kind,colour)
			x+=span
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE_STRONG,false,1.0)
		var before:=w*float(ghost)/went
		var now:=w*float(int(totals.get("standing",0)))/went
		if absf(before-now)>2.0: draw_line(Vector2(before,-3),Vector2(before,h+3),T.INK,1.5)


## Heart: the standing men's will to fight, coloured by how much is left.
class HeartBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var value:=-1.0

	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),T.TRACK)
		if value>0.0:
			var c:=T.GREEN if value>=0.5 else (T.AMBER if value>=0.25 else T.RED)
			draw_rect(Rect2(0,0,size.x*clampf(value,0.0,1.0),size.y),Color(c,0.9))
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE_STRONG,false,1.0)


## The marks of a battle's losses, drawn as small ink figures in the colour
## of their part of the strength bar: the killed lie down, the wounded kneel,
## the fled run, the taken are bound.
class CasualtyMark extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var kind:="killed"

	static func colour_of(kind:String,side:Color)->Color:
		match kind:
			"standing": return Color(side,0.9)
			"killed": return Color(T.INK,0.88)
			"wounded": return Color(T.INK,0.45)
			"fled": return Color(T.INK_MUTED,0.7)
			"captured": return Color(T.VIOLET,0.8)
		return T.INK

	## A part of a strength bar in its mark's manner (the fled hatched).
	static func fill(canvas:CanvasItem,rect:Rect2,kind:String,side:Color)->void:
		if rect.size.x<=0.0: return
		if kind=="fled":
			canvas.draw_rect(rect,Color(T.PAPER,0.6))
			var x:=rect.position.x-rect.size.y
			while x<rect.end.x:
				var a:=Vector2(maxf(x,rect.position.x),rect.end.y-maxf(0.0,rect.position.x-x))
				var b:=Vector2(minf(x+rect.size.y,rect.end.x),rect.position.y+maxf(0.0,x+rect.size.y-rect.end.x))
				if a.x<b.x: canvas.draw_line(a,b,colour_of(kind,side),1.2,true)
				x+=4.0
			return
		canvas.draw_rect(rect,colour_of(kind,side))

	func _draw()->void:
		var c:=colour_of(kind,Color.WHITE)
		var s:=minf(size.x,size.y)
		var o:=(size-Vector2(s,s))*0.5
		var p:=func(x:float,y:float)->Vector2: return o+Vector2(x,y)*s/20.0
		match kind:
			"killed":
				draw_circle(p.call(4,14),2.4*s/20.0,c)
				draw_line(p.call(6.5,14),p.call(15,14),c,2.0*s/20.0,true)
				draw_line(p.call(15,14),p.call(19,16),c,1.6*s/20.0,true)
				draw_line(p.call(15,14),p.call(19,12.5),c,1.6*s/20.0,true)
				draw_line(p.call(1,17.5),p.call(19,17.5),Color(c,0.5),1.0,true)
			"wounded":
				draw_circle(p.call(9,4),2.4*s/20.0,c)
				draw_line(p.call(9,6.5),p.call(8,12),c,2.0*s/20.0,true)
				draw_line(p.call(8,12),p.call(13,13),c,1.6*s/20.0,true)
				draw_line(p.call(13,13),p.call(13,18),c,1.6*s/20.0,true)
				draw_line(p.call(8,12),p.call(5,18),c,1.6*s/20.0,true)
				draw_line(p.call(9,8),p.call(15,7),c,1.4*s/20.0,true)
				draw_line(p.call(15,4),p.call(15,18),Color(c,0.8),1.2*s/20.0,true)
			"fled":
				draw_circle(p.call(13,4),2.4*s/20.0,c)
				draw_line(p.call(12,6.5),p.call(9,11.5),c,2.0*s/20.0,true)
				draw_line(p.call(9,11.5),p.call(12,15),c,1.6*s/20.0,true)
				draw_line(p.call(12,15),p.call(10,19),c,1.6*s/20.0,true)
				draw_line(p.call(9,11.5),p.call(5,16),c,1.6*s/20.0,true)
				draw_line(p.call(11,8),p.call(16,10),c,1.4*s/20.0,true)
				draw_line(p.call(1,8),p.call(5,8),Color(c,0.7),1.2*s/20.0,true)
				draw_line(p.call(0,12),p.call(4,12),Color(c,0.7),1.2*s/20.0,true)
			"captured":
				draw_circle(p.call(10,4),2.4*s/20.0,c)
				draw_line(p.call(10,6.5),p.call(10,13),c,2.0*s/20.0,true)
				draw_line(p.call(10,13),p.call(8,19),c,1.6*s/20.0,true)
				draw_line(p.call(10,13),p.call(12,19),c,1.6*s/20.0,true)
				draw_arc(p.call(10,10),3.6*s/20.0,0.0,TAU,14,c,1.3*s/20.0,true)
				draw_line(p.call(13.5,10),p.call(19,13),Color(c,0.8),1.0,true)


## Why one side has the better of it: each of the engine's reasons as a bar
## from the middle toward the side it helps, its size in percent; pointing
## at one says it in words.
class WhyBars extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const ROW:=19.0
	const LABEL_W:=150.0
	var items:Array=[]
	var left_colour:=Color.WHITE
	var right_colour:=Color.WHITE
	var left_text:=Color.WHITE
	var right_text:=Color.WHITE
	var empty_words:=""

	func _init()->void:
		mouse_filter=Control.MOUSE_FILTER_PASS

	func _get_tooltip(at:Vector2)->String:
		var row:=int(at.y/ROW)
		if row>=0 and row<items.size(): return String((items[row] as Dictionary).get("text",""))+"."
		return ""

	func _draw()->void:
		var font:=T.font("ui"); var strong:=T.font("ui_strong")
		if items.is_empty():
			draw_string(font,Vector2(0,14),empty_words,HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.INK_MUTED)
			return
		var most:=100
		for item in items: most=maxi(most,absi(int(item.pct)))
		var area:=minf(size.x-LABEL_W-8.0,600.0)
		var mid:=LABEL_W+8.0+area*0.5
		draw_line(Vector2(mid,0),Vector2(mid,ROW*float(items.size())),T.RULE_STRONG,1.0)
		for i in items.size():
			var item:Dictionary=items[i]
			var y:=float(i)*ROW
			var ours:=String(item.get("favours","left"))=="left"
			draw_string(font,Vector2(0,y+14.0),String(item.get("label","")),HORIZONTAL_ALIGNMENT_LEFT,LABEL_W,14,T.INK)
			var reach:=(area*0.5-48.0)*float(absi(int(item.pct)))/float(most)
			var rect:=Rect2(mid-reach if ours else mid,y+4.0,reach,ROW-8.0)
			draw_rect(rect,Color(left_colour if ours else right_colour,0.85))
			var words:="%s%d%%" % ["+" if int(item.pct)>=0 else "−",absi(int(item.pct))]
			var ww:=strong.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
			var tx:=rect.position.x-ww-5.0 if ours else rect.end.x+5.0
			draw_string(strong,Vector2(tx,y+14.0),words,HORIZONTAL_ALIGNMENT_LEFT,-1,13,left_text if ours else right_text)


## The battle's mark as the war chart inks it: crossed spears, swords,
## muskets or rifles, the armour sign or the lattice.
class EraMark extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
	var era:=0

	func _init()->void:
		mouse_filter=Control.MOUSE_FILTER_PASS

	func _draw()->void:
		var at:=size*0.5
		var r:=minf(size.x,size.y)*0.42
		draw_circle(at,r+4.0,Color(T.PAPER_SUNK,0.9))
		draw_arc(at,r+4.0,0.0,TAU,40,T.RULE_STRONG,1.2,true)
		BattleMarks.draw_weapons(self,at,r*0.78,era,T.INK,Color(T.PAPER_SUNK,0.0))
