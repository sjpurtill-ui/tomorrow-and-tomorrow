extends CanvasLayer
## A siege as the general's briefing: the city drawn behind, and on paper how
## it stands, what the general means to do and who to talk to. The general
## runs the siege; all progress and orders stay with MilitaryCampaign.
const CITY=preload("res://scripts/siege_city_scene.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const P=preload("res://scripts/hud/paper_sheet.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
const When=preload("res://scripts/hud/report_when.gd")
## Pressure at which a general storms the walls (military_campaign.gd).
const STORM_PRESSURE:=.72
var siege_id:=""
var scene:Node3D
var stage:SubViewportContainer
var viewport:SubViewport
var title:Label
var status:Label
var feedback:Label
var poll:=0.0
var last_snapshot:Dictionary={}
var live:Dictionary={}
var canvas:Control
var header:PanelContainer
var briefing:PanelContainer
var briefing_box:VBoxContainer
var bottom:PanelContainer
var time_buttons:Dictionary={}
var camera_buttons:Dictionary={}
var talk_general:Button
var talk_ruler:Button
var storm:Button
var watch_assault:Button
var result_panel:PanelContainer
var result_title:Label
var result_body:Label
var result_action:Button
var events:Array=[]
var terrain:Node
var previous_scale:Vector2i
var previous_aspect:int
var scale_restored:=false
var last_day:=-1
var signature:=""

static func open(identity:String="")->void:
	var root:Node=Engine.get_main_loop().root
	if root.has_meta("persistent_siege_view") and is_instance_valid(root.get_meta("persistent_siege_view")):return
	var view=load("res://scripts/hud/siege_screen.gd").new();view.siege_id=identity
	root.set_meta("persistent_siege_view",view);root.add_child.call_deferred(view)

func _panel(pad:float=14.0)->PanelContainer:
	var p:=PanelContainer.new();p.add_theme_stylebox_override("panel",P.sheet_style(pad));canvas.add_child(p);p.minimum_size_changed.connect(_layout.call_deferred);return p
func _box(parent:Node,separation:int=8)->VBoxContainer:
	var value:=VBoxContainer.new();value.add_theme_constant_override("separation",separation);parent.add_child(value);return value
func _clear(parent:Node)->void:
	for child in parent.get_children():parent.remove_child(child);child.queue_free()

func _ready()->void:
	layer=78;previous_scale=get_window().content_scale_size;previous_aspect=get_window().content_scale_aspect
	get_window().content_scale_size=Vector2i.ZERO;get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	canvas=Control.new();canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.theme=T.control_theme();add_child(canvas)
	stage=SubViewportContainer.new();stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stage.stretch=true;canvas.add_child(stage)
	viewport=SubViewport.new();viewport.own_world_3d=false;viewport.msaa_3d=Viewport.MSAA_8X;viewport.size=Vector2i(1600,900);stage.add_child(viewport)
	terrain=_terrain(get_tree().root)
	if terrain!=null:
		viewport.own_world_3d=false;viewport.world_3d=terrain.get_world_3d()
		scene=preload("res://scripts/city_encounter_scene.gd").new();scene.terrain=terrain
	else:viewport.own_world_3d=true;scene=CITY.new()
	viewport.add_child(scene);stage.gui_input.connect(scene.navigate)
	stage.tooltip_text="The city as our scouts and soldiers describe it. Drag to look around."
	_build_header();_build_briefing();_build_bottom();_build_result()
	canvas.resized.connect(_layout);_refresh();_layout();print("SIEGE_UI_OPEN briefing id=",siege_id," day=",GameState.elapsed_days)

func _build_header()->void:
	header=_panel(12);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);header.add_child(row)
	var names:=_box(row,0);names.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	P.kicker(names,"Siege briefing")
	title=P.label(names,"Siege","title",T.INK,false);title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	status=P.label(row,"","small",T.BODY,false);status.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var report:=P.button(row,"City report",_city_report);report.name="CityReport";report.size_flags_horizontal=Control.SIZE_SHRINK_END;report.custom_minimum_size.x=130
	var people:=P.button(row,"People and legacies",func():HistoricalFigures.open_chronicle());people.size_flags_horizontal=Control.SIZE_SHRINK_END;people.custom_minimum_size.x=170
	var close:=P.button(row,"Close",_close);close.name="Close";close.size_flags_horizontal=Control.SIZE_SHRINK_END;close.custom_minimum_size.x=96;close.tooltip_text="Back to the map (Esc)"

func _build_briefing()->void:
	briefing=_panel(16)
	var root:=_box(briefing,10)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll)
	briefing_box=_box(scroll,10);briefing_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	P.rule(root)
	P.kicker(root,"Talk it over in court")
	talk_general=P.button(root,"Talk to the general",_talk_general,true);talk_general.name="TalkGeneral"
	talk_ruler=P.button(root,"Talk to their ruler",_negotiate);talk_ruler.name="TalkRuler"
	storm=P.button(root,"Tell the general to storm the walls",_siege_order.bind("assault"));storm.name="Storm"
	watch_assault=P.button(root,"Watch the assault",_open_battle);watch_assault.name="WatchAssault"
	feedback=P.label(root,"","small",T.BODY)

func _build_bottom()->void:
	bottom=_panel(10);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);bottom.add_child(row)
	var view:=P.label(row,"View","small",T.INK_MUTED,false);view.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	for place:String in ["overview","gate","city"]:
		camera_buttons[place]=P.button(row,{"overview":"Whole field","gate":"Our army" if terrain!=null else "The gate","city":"The city"}[place],_camera.bind(place));camera_buttons[place].custom_minimum_size.x=110
	var gap:=Control.new();gap.custom_minimum_size.x=16;row.add_child(gap)
	var time:=P.label(row,"Time","small",T.INK_MUTED,false);time.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	for item in [["Pause",0],["Play",1],["Fast",3]]:
		time_buttons[str(item[1])]=P.button(row,item[0],_speed.bind(float(item[1])));time_buttons[str(item[1])].custom_minimum_size.x=80

func _build_result()->void:
	result_panel=_panel(24);var box:=_box(result_panel,12);P.kicker(box,"The siege is over");result_title=P.label(box,"The siege has ended","title",T.INK)
	result_body=P.label(box,"","body",T.BODY);result_action=P.button(box,"Review the battle",_result_action,true);P.button(box,"Back to the map",_close)

func _camera(place:String)->void:
	scene.focus(place)
	for key in camera_buttons:camera_buttons[key].add_theme_stylebox_override("normal",T.button_pressed_style() if key==place else T.action_button_style(false))
func _process(delta:float)->void:
	poll+=delta
	if poll>=.3:poll=0;_refresh()

func _general()->Dictionary:
	var army:Dictionary={}
	var id:=int(MilitaryCampaign.active_siege.get("army_id",0)) if not MilitaryCampaign.active_siege.is_empty() else 0
	for force:Dictionary in MilitaryCampaign.field_armies:
		if int(force.get("army_id",-1))==id:army=force
	return P.general_for(army)

static func _spirit(morale:float)->String:
	return "in high spirits" if morale>=.75 else "steady" if morale>=.5 else "weary" if morale>=.3 else "close to breaking"
static func _ready_words(readiness:float)->String:
	return "well prepared" if readiness>=.75 else "fairly prepared" if readiness>=.5 else "poorly prepared"

func _refresh()->void:
	var snapshot:Dictionary=MilitaryCampaign.siege_visual_snapshot(siege_id)
	if snapshot.is_empty():
		title.text="No siege to show";status.text="";briefing.hide();result_panel.show();result_title.text="There is no siege on record";result_body.text="Nothing is under siege. Close this and return to the map.";result_action.hide();_layout();return
	siege_id=String(snapshot.id);last_snapshot=snapshot;live=MilitaryCampaign.siege_public_snapshot(siege_id);scene.configure(snapshot)
	var offensive:=String(snapshot.mode)=="offensive"
	title.text=("Our siege of %s" if offensive else "%s under siege") % String(snapshot.name)
	var active:=bool(snapshot.active);var in_battle:=bool(snapshot.battle_active);var days:=int(live.get("days",_operation().get("days",0)))
	var paused:=not is_instance_valid(terrain) or float(terrain.game_speed)==0
	status.text=("Storming the walls now" if in_battle else (("Besieged since today" if days<=0 else "Besieged for %s" % When.span(days))+(" · time is paused" if paused else "") if active else "Ended"))
	for key in time_buttons:
		time_buttons[key].disabled=not active or not is_instance_valid(terrain)
		time_buttons[key].add_theme_stylebox_override("normal",T.button_pressed_style() if is_instance_valid(terrain) and int(terrain.game_speed)==int(key) else T.action_button_style(false))
	var general:=_general()
	talk_general.visible=not general.is_empty()
	talk_general.text=P.talk_label(general,"Talk to our war leader")
	var rival:=String(snapshot.get("rival",""))
	var ruler:=P.ruler_name(rival)
	talk_ruler.text="Talk to %s about terms" % P.first_name(ruler) if ruler!="" else "Talk to their ruler about terms"
	talk_ruler.disabled=ruler==""
	talk_ruler.tooltip_text="Opens the court, where your envoys carry your words." if ruler!="" else "We have no contact with their ruler."
	var pressure:=float(live.get("pressure",_operation().get("pressure",0)))
	var managed:=bool(_operation().get("commander_managed",false))
	# Sieges the general runs end in an assault on their own; an older siege
	# waits for the ruler's word, and says so plainly.
	storm.visible=active and not in_battle and not managed and pressure>=STORM_PRESSURE and _assault_blocker().is_empty()
	storm.text="Tell %s to storm the walls" % P.first_name(String(general.get("name","the general"))) if offensive else "Tell %s to break out" % P.first_name(String(general.get("name","the defenders")))
	watch_assault.visible=in_battle
	if days!=last_day:
		last_day=days
		if active:_event("%s: %s" % [EraWords.when(int(GameState.elapsed_days)),_pressure_words(pressure,offensive)])
	var next_signature:=JSON.stringify([live,snapshot.active,snapshot.battle_active,snapshot.summary,snapshot.own_force.get("troops",0),snapshot.own_force.get("morale",0),general.get("name",""),events.size()])
	if signature!=next_signature:signature=next_signature;_briefing(general,pressure,managed)
	briefing.visible=active or in_battle
	result_panel.visible=not active and not in_battle
	if not active:
		result_title.text="The siege of %s has ended" % String(snapshot.name)
		result_body.text=String(snapshot.summary)
		if not snapshot.battle.is_empty() and not in_battle:result_body.text+="\n"+_outcome_words(String(snapshot.battle.get("outcome","")))
		result_action.visible=not snapshot.battle.is_empty() or MilitaryCampaign.recovery.home_unavailable()
		result_action.text="Recovery briefing" if snapshot.battle.is_empty() and MilitaryCampaign.recovery.home_unavailable() else "Review the battle"
	_layout()

static func _outcome_words(outcome:String)->String:
	match outcome:
		"attacker_victory":return "The attackers carried the day."
		"defender_victory":return "The defenders held."
		"draw","stalemate":return "Neither side broke."
		"":return ""
	return P.first_up(outcome.replace("_"," "))+"."

static func _pressure_words(pressure:float,offensive:bool)->String:
	var share:="barely touched" if pressure<.15 else "somewhat worn" if pressure<.4 else "badly worn" if pressure<STORM_PRESSURE else "ready to be stormed"
	return ("their defences are %s" if offensive else "our defences are %s") % share

func _briefing(general:Dictionary,pressure:float,managed:bool)->void:
	_clear(briefing_box)
	var offensive:=String(last_snapshot.mode)=="offensive"
	var own:Dictionary=last_snapshot.own_force
	var gname:=P.first_name(String(general.get("name",""))) if not general.is_empty() else ""
	P.kicker(briefing_box,"How it stands")
	var ours:=P.card(briefing_box,T.TEAL)
	P.label(ours,"Our army" if offensive else "Our defenders","value",T.INK)
	P.label(ours,"%s soldiers, %s and %s." % [EraWords.grouped(int(own.get("troops",0))),_spirit(float(own.get("morale",0))),_ready_words(float(own.get("readiness",0)))],"body",T.BODY)
	if offensive:P.label(ours,_supply_words(float(live.get("own_supply_ratio",1.0))),"small",T.BODY)
	else:P.label(ours,"Food at home lasts about %s at today's needs." % EraWords.days(float(live.get("own_food_days",0))),"small",T.BODY)
	var theirs:=P.card(briefing_box,T.RED)
	P.label(theirs,"Inside the walls" if offensive else "The besiegers","value",T.INK)
	P.label(theirs,_enemy_report(),"body",T.BODY)
	P.label(theirs,String(live.get("civilian_hardship","")),"small",T.BODY)
	var walls:=P.card(briefing_box,T.GOLD)
	P.label(walls,"The walls","value",T.INK)
	P.label(walls,P.first_up(_pressure_words(pressure,offensive))+".","body",T.BODY)
	var ring:=float(last_snapshot.get("blockade",0))
	P.label(walls,("We hold %s of the roads in." if offensive else "They hold %s of the roads in.") % ("almost none" if ring<.15 else "a few" if ring<.4 else "most" if ring<.8 else "nearly all"),"small",T.BODY)
	P.kicker(briefing_box,"What %s means to do" % (gname if gname!="" else "the general"))
	var intent:=""
	if offensive:
		if managed:intent="Keep the ring closed until the walls are worn down, then storm them." if pressure<STORM_PRESSURE else "Storm the walls as soon as the soldiers are rested."
		else:intent="Hold the ring and wear the walls down. Storming needs your word." if pressure<STORM_PRESSURE else "The walls are worn enough to storm. They wait for your word."
		if String(live.get("besieger_endurance",""))=="Exhausted":intent+=" Our soldiers are worn out; the siege may have to be lifted."
	else:
		intent="Hold the walls and wait for the besiegers to tire or run short of food."
	P.label(briefing_box,intent,"body",T.BODY)
	if not events.is_empty():
		P.kicker(briefing_box,"Lately")
		for i in range(events.size()-1,maxi(-1,events.size()-4),-1):P.label(briefing_box,String(events[i]),"small",T.BODY)

static func _supply_words(ratio:float)->String:
	return "They get their full rations." if ratio>=.95 else "They get most of their rations." if ratio>=.7 else "They are on short rations." if ratio>=.4 else "They are going hungry."

func _operation()->Dictionary:
	if not MilitaryCampaign.active_siege.is_empty() and String(MilitaryCampaign.active_siege.id)==siege_id:return MilitaryCampaign.active_siege
	for past:Dictionary in MilitaryCampaign.siege_history:
		if String(past.id)==siege_id:return past
	return {}
func _enemy_report()->String:
	if last_snapshot.mode=="offensive":
		var city:Dictionary=CivilizationSystem.city_intelligence.known("player",String(last_snapshot.region_id));var report:Dictionary=city.get("fields",{}).get("garrison",{})
		if report.is_empty():return "No one has counted their fighters."
		return "About %s, as counted in %s." % [preload("res://scripts/hud/city_report_visuals.gd").words("garrison",report),EraWords.when(int(report.observed_day))]
	var threat:Dictionary=_operation().get("threat",{});var estimate:=int(threat.get("estimated_strength",0))
	return "Roughly %s of them, by our lookouts' count." % EraWords.grouped(estimate) if estimate>0 else "We do not know how many they are."
func _event(text:String)->void:
	if events.is_empty() or String(events.back()).get_slice(": ",1)!=text.get_slice(": ",1):events.append(text)
	if events.size()>24:events.pop_front()
func _assault_blocker()->String:
	if last_snapshot.is_empty() or not last_snapshot.active:return "This siege is over."
	if not MilitaryCampaign.active_engagement.is_empty():return "Another battle is being fought."
	if not MilitaryCampaign.pending_aftermath.is_empty():return "The last battle's aftermath is not settled yet."
	if int(last_snapshot.own_force.get("troops",0))<=0:return "No soldiers are here to fight."
	return ""
func _siege_order(order:String)->void:
	print("SIEGE_UI_ORDER id=",siege_id," order=",order," day=",GameState.elapsed_days)
	if order=="assault" and last_snapshot.get("battle_active",false):_open_battle();return
	if order=="assault":_speed(0)
	var result:Dictionary=MilitaryCampaign.siege_order(siege_id,order)
	feedback.text=String(result.get("error",result.get("message","")))
	if order=="assault" and not result.has("error"):
		_open_battle();return
	_refresh()
func _result_action()->void:
	if last_snapshot.get("battle",{}).is_empty() and MilitaryCampaign.recovery.home_unavailable():preload("res://scripts/hud/recovery_screen.gd").open()
	else:_open_battle()
func _open_battle()->void:
	print("SIEGE_UI_TRANSITION battle id=",siege_id)
	_speed(0)
	var snapshot:Dictionary=MilitaryCampaign.siege_visual_snapshot(siege_id)
	var battle:Dictionary=snapshot.get("battle",{})
	if battle.is_empty():feedback.text="No battle has been fought here yet.";return
	if not MilitaryCampaign.active_engagement.is_empty() and int(MilitaryCampaign.active_engagement.seed)!=int(battle.get("seed",-1)):feedback.text="Another battle is being fought; it comes first.";return
	_restore_scale();MilitaryCommandUI.call_deferred("_open_battle_graphics",0,int(battle.get("seed",-1)));queue_free()
func _talk_general()->void:
	var general:=_general()
	_close();P.summon(general.get("target",{}))
func _negotiate()->void:
	_speed(0)
	var rival:=String(last_snapshot.get("rival",""))
	if ForeignDiplomacy.leader(rival).is_empty():feedback.text="We have no contact with their ruler.";return
	_close();ForeignDiplomacy.open(rival)
func _city_report()->void:
	_speed(0);CivilizationSystem.city_intelligence.open(String(last_snapshot.get("region_id","")))
func _speed(value:float)->void:
	print("SIEGE_UI_TIME requested=",value," day=",GameState.elapsed_days)
	if is_instance_valid(terrain):terrain.call("_set_game_speed",value)
	elif is_instance_valid(feedback):feedback.text="Time can only run in a live game."
func _terrain(node:Node)->Node:
	if node.has_method("_set_game_speed"):return node
	for child in node.get_children():
		var found:=_terrain(child)
		if found!=null:return found
	return null
func _close()->void:
	if is_queued_for_deletion():return
	print("SIEGE_UI_CLOSE id=",siege_id);_speed(0);_restore_scale();queue_free()
func _restore_scale()->void:
	if scale_restored:return
	scale_restored=true;get_window().content_scale_size=previous_scale;get_window().content_scale_aspect=previous_aspect
func _exit_tree()->void:
	if not scale_restored:get_window().set_deferred("content_scale_size",previous_scale);get_window().set_deferred("content_scale_aspect",previous_aspect)
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:_close();get_viewport().set_input_as_handled()
func _layout()->void:
	if not is_instance_valid(bottom):return
	var w:=canvas.size.x;var h:=canvas.size.y
	var top:=22.0 if ProjectSettings.get_setting("application/config/custom_user_dir_name","").contains("Test") else 0.0
	header.position=Vector2(12,top+12);header.size=Vector2(w-24,0)
	var header_bottom:=header.position.y+header.get_combined_minimum_size().y+12
	bottom.size=Vector2(0,0);bottom.position=Vector2(12,h-bottom.get_combined_minimum_size().y-12)
	var width:=clampf(w*.32,300,420)
	briefing.position=Vector2(12,header_bottom);briefing.size=Vector2(width,maxf(200,bottom.position.y-header_bottom-12))
	result_panel.size=Vector2(minf(520,w-32),0);result_panel.position=Vector2((w-result_panel.size.x)*.5,maxf(header_bottom,(h-result_panel.get_combined_minimum_size().y)*.5))
