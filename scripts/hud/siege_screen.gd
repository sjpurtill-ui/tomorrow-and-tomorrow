extends CanvasLayer
## Native siege command view. All progress and orders remain owned by MilitaryCampaign.
const CITY=preload("res://scripts/siege_city_scene.gd")
const INK:=Color("0b1013")
const TEXT:=Color("e8ebe6")
const MUTED:=Color("a3adaa")
const TEAL:=Color("7fe3d8")
const ORANGE:=Color("ff9f6b")
const GOLD:=Color("f2c14e")
var siege_id:=""
var scene:Node3D
var stage:SubViewportContainer
var viewport:SubViewport
var title:Label
var status:Label
var feedback:Label
var order_buttons:Dictionary={}
var battle_buttons:Dictionary={}
var poll:=0.0
var last_snapshot:Dictionary={}
var live:Dictionary={}
var canvas:Control
var header:PanelContainer
var strip:Control
var force_panels:Array=[]
var force_names:Array=[]
var force_values:Array=[]
var progress_panel:PanelContainer
var progress_title:Label
var pressure:ProgressBar
var progress_note:Label
var details_panel:PanelContainer
var detail_content:VBoxContainer
var details_tab:="supplies"
var commands_panel:PanelContainer
var commands_content:VBoxContainer
var command_tab:="orders"
var bottom:PanelContainer
var assault:Button
var time_label:Label
var time_buttons:Dictionary={}
var camera_buttons:Dictionary={}
var narrow_toggle:Button
var narrow_commands:=false
var result_panel:PanelContainer
var result_title:Label
var result_body:Label
var result_action:Button
var events:Array=[]
var event_page:=0
var terrain:Node
var ui_font:Font
var display_font:Font
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
func _style(color:Color,border:Color=Color("263237"),radius:int=8)->StyleBoxFlat:
	var value:=StyleBoxFlat.new();value.bg_color=color;value.border_color=border;value.set_border_width_all(1);value.set_corner_radius_all(radius)
	for edge in ["left","right","top","bottom"]:value.set("content_margin_"+edge,12.0)
	return value
func _bar_style(color:Color)->StyleBoxFlat:
	var value:=_style(color,color,5)
	for edge in ["left","right","top","bottom"]:value.set("content_margin_"+edge,0.0)
	return value
func _panel()->PanelContainer:
	var p:=PanelContainer.new();p.add_theme_stylebox_override("panel",_style(Color(INK,.94)));canvas.add_child(p);p.minimum_size_changed.connect(_layout.call_deferred);return p
func _box(parent:Node)->VBoxContainer:
	var value:=VBoxContainer.new();value.add_theme_constant_override("separation",8);parent.add_child(value);return value
func _label(parent:Node,text:String,font_size:int=14,color:Color=TEXT,display:bool=false)->Label:
	var value:=Label.new();value.text=text;value.add_theme_font_override("font",display_font if display else ui_font);value.add_theme_font_size_override("font_size",font_size);value.add_theme_color_override("font_color",color);parent.add_child(value);return value
func _button(parent:Node,text:String,action:Callable,color:Color=TEXT)->Button:
	var value:=Button.new();value.text=text;value.custom_minimum_size.y=36;value.add_theme_font_override("font",ui_font);value.add_theme_font_size_override("font_size",13);value.add_theme_color_override("font_color",color)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style:=_style(Color("263438") if state in ["hover","pressed"] else Color("192226"),GOLD if state=="focus" else Color("314044"));style.content_margin_top=8;style.content_margin_bottom=8;value.add_theme_stylebox_override(state,style)
	value.pressed.connect(action);parent.add_child(value);return value
func _body(parent:Node,text:String,font_size:int=13,color:Color=MUTED)->Label:
	var value:=_label(parent,text,font_size,color);value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return value
func _clear(parent:Node)->void:
	for child in parent.get_children():parent.remove_child(child);child.queue_free()
func _ready()->void:
	layer=78;previous_scale=get_window().content_scale_size;previous_aspect=get_window().content_scale_aspect
	get_window().content_scale_size=Vector2i.ZERO;get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	ui_font=load("res://assets/fonts/battle/Barlow-Medium.ttf");display_font=load("res://assets/fonts/battle/BarlowCondensed-Bold.ttf")
	canvas=Control.new();canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(canvas)
	stage=SubViewportContainer.new();stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stage.stretch=true;canvas.add_child(stage)
	viewport=SubViewport.new();viewport.own_world_3d=false;viewport.msaa_3d=Viewport.MSAA_8X;viewport.size=Vector2i(1600,900);stage.add_child(viewport)
	terrain=_terrain(get_tree().root)
	if terrain!=null:
		viewport.own_world_3d=false;viewport.world_3d=terrain.get_world_3d()
		scene=preload("res://scripts/city_encounter_scene.gd").new();scene.terrain=terrain
	else:viewport.own_world_3d=true;scene=CITY.new()
	viewport.add_child(scene);stage.gui_input.connect(scene.navigate)
	_build_header();_build_details();_build_commands();_build_bottom();_build_result()
	canvas.resized.connect(_on_resize);_refresh();_layout();print("SIEGE_UI_OPEN native-siege-v1 id=",siege_id," day=",GameState.elapsed_days)
func _build_header()->void:
	header=_panel();var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);header.add_child(row)
	title=_label(row,"SIEGE",26,TEXT,true);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	status=_label(row,"PAUSED",12,GOLD);status.add_theme_stylebox_override("normal",_style(Color(ORANGE,.12),Color(0,0,0,0),18))
	order_buttons.report=_button(row,"City report",_city_report);_button(row,"People & legacies",func():HistoricalFigures.open_chronicle());_button(row,"×",_close)
	strip=Control.new();strip.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(strip)
	for side in 2:
		var p:=PanelContainer.new();p.add_theme_stylebox_override("panel",_style(Color(INK,.90)));p.minimum_size_changed.connect(_layout.call_deferred);strip.add_child(p);force_panels.append(p)
		var box:=_box(p);var name:=_label(box,"",22,TEAL if side==0 else ORANGE,true);name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;force_names.append(name)
		force_values.append(_body(box,"",14,TEXT))
	progress_panel=PanelContainer.new();progress_panel.add_theme_stylebox_override("panel",_style(Color(INK,.94)));progress_panel.minimum_size_changed.connect(_layout.call_deferred);strip.add_child(progress_panel)
	var progress_box:=_box(progress_panel);progress_title=_label(progress_box,"ASSAULT PRESSURE",13,GOLD)
	pressure=ProgressBar.new();pressure.show_percentage=false;pressure.custom_minimum_size.y=12;pressure.add_theme_stylebox_override("background",_bar_style(Color("1f292d")));pressure.add_theme_stylebox_override("fill",_bar_style(GOLD));progress_box.add_child(pressure)
	progress_note=_body(progress_box,"",12,MUTED)
func _build_details()->void:
	details_panel=_panel();var box:=_box(details_panel);var tabs:=HBoxContainer.new();box.add_child(tabs)
	_button(tabs,"SUPPLY",_set_details.bind("supplies"),TEAL);_button(tabs,"CITY",_set_details.bind("city"),TEAL);_button(tabs,"REPORTS",_set_details.bind("reports"),TEAL)
	detail_content=_box(box)
func _build_commands()->void:
	commands_panel=_panel();var box:=_box(commands_panel);var tabs:=HBoxContainer.new();box.add_child(tabs)
	_button(tabs,"ORDERS",_set_commands.bind("orders"),GOLD);_button(tabs,"ACTIVITY",_set_commands.bind("activity"),GOLD);commands_content=_box(box)
func _build_bottom()->void:
	bottom=_panel();var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);bottom.add_child(row)
	var cameras:=_box(row);_label(cameras,"CAMERA",10,MUTED);var camera_row:=HBoxContainer.new();cameras.add_child(camera_row)
	for place:String in ["overview","gate","city"]:camera_buttons[place]=_button(camera_row,"Army" if place=="gate" and terrain!=null else place.capitalize(),_camera.bind(place))
	var time_row:=HBoxContainer.new();cameras.add_child(time_row)
	for item in [["Pause",0],["Play",1],["Fast",3]]:time_buttons[str(item[1])]=_button(time_row,item[0],_speed.bind(float(item[1])),TEAL)
	var center:=_box(row);center.size_flags_horizontal=Control.SIZE_EXPAND_FILL;time_label=_label(center,"",12,MUTED);time_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	assault=_button(center,"BEGIN ASSAULT →",_siege_order.bind("assault"),INK);assault.add_theme_stylebox_override("normal",_style(GOLD,GOLD));assault.add_theme_font_override("font",display_font);assault.add_theme_font_size_override("font_size",22)
	feedback=_body(center,"",13,TEXT);feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;feedback.max_lines_visible=2;feedback.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var tail:=_box(row);narrow_toggle=_button(tail,"Supplies / orders",_toggle_narrow);_button(tail,"Return to map",_close)
func _build_result()->void:
	result_panel=_panel();var box:=_box(result_panel);result_title=_label(box,"SIEGE ENDED",32,GOLD,true)
	result_body=_body(box,"",16,TEXT);result_action=_button(box,"REVIEW BATTLE →",_result_action,GOLD);_button(box,"RETURN TO MAP",_close)
func _set_details(value:String)->void:details_tab=value;_details();_layout()
func _set_commands(value:String)->void:command_tab=value;_commands();_layout()
func _toggle_narrow()->void:narrow_commands=not narrow_commands;_layout()
func _camera(place:String)->void:
	scene.focus(place)
	for key in camera_buttons:camera_buttons[key].modulate=TEAL if key==place else TEXT
func _process(delta:float)->void:
	poll+=delta
	if poll>=.3:poll=0;_refresh()
func _on_resize()->void:
	_details();_commands();_layout()
func _refresh()->void:
	var snapshot:Dictionary=MilitaryCampaign.siege_visual_snapshot(siege_id)
	if snapshot.is_empty():
		title.text="NO SIEGE TO DISPLAY";status.text="NO ACTIVE OPERATION";assault.disabled=true;details_panel.hide();commands_panel.hide();progress_panel.hide();result_panel.show();result_title.text="NO SIEGE RECORD";result_body.text="Return to the map and select a known city to begin an operation.";result_action.hide();_layout();return
	siege_id=String(snapshot.id);last_snapshot=snapshot;live=MilitaryCampaign.siege_public_snapshot(siege_id);scene.configure(snapshot)
	title.text="SIEGE OF "+String(snapshot.name).to_upper()
	var active:=bool(snapshot.active);var in_battle:=bool(snapshot.battle_active);var days:=int(live.get("days",_operation().get("days",0)))
	var paused:=not is_instance_valid(terrain) or float(terrain.game_speed)==0
	status.text="● DAY %d · %s"%[days,"ASSAULT" if in_battle else ("PAUSED" if active and paused else ("HOLDING" if active else "ENDED"))]
	var own:Dictionary=snapshot.own_force
	force_names[0].text=String(own.get("name","YOUR DEFENDERS" if snapshot.mode=="defensive" else "YOUR ARMY")).to_upper()+" · YOURS"
	force_values[0].text="%d personnel · morale %d%% · readiness %d%%"%[int(own.get("troops",0)),roundi(float(own.get("morale",0))*100),roundi(float(own.get("readiness",0))*100)]
	force_values[0].tooltip_text="Readiness reflects training, organization, provisions and personnel condition. More people alone do not guarantee a successful assault."
	var enemy_report:=_enemy_report();force_names[1].text="CITY DEFENDERS" if snapshot.mode=="offensive" else "BESIEGING FORCE";force_values[1].text=enemy_report
	var pressure_value:=float(live.get("pressure",_operation().get("pressure",0)))
	pressure.value=pressure_value*100;progress_title.text="ASSAULT PRESSURE · %.1f%%"%(pressure_value*100)
	progress_note.text="Weakens the defense bonus · not a victory chance"
	progress_panel.tooltip_text="Current pressure removes %.1f%% of the prepared defense bonus when battle begins. It does not guarantee a breach or victory."%(pressure_value*.65*100)
	var reason:=_assault_blocker();assault.disabled=not reason.is_empty() and not in_battle
	assault.text="VIEW ASSAULT →" if in_battle else ("BEGIN ASSAULT →" if snapshot.mode=="offensive" else "LAUNCH SORTIE →")
	if not active and not in_battle:assault.hide()
	else:assault.show()
	assault.tooltip_text=reason if not reason.is_empty() else "Fight from the current siege conditions. Combat opens paused for your formation orders."
	for key in time_buttons:time_buttons[key].disabled=not active or not is_instance_valid(terrain);time_buttons[key].modulate=TEAL if is_instance_valid(terrain) and int(terrain.game_speed)==int(key) else TEXT
	time_label.text="TIME PAUSED · siege advances only when you play" if paused else "TIME RUNNING · %s game hours / second"%str(terrain._speed_hours_per_second())
	if not active:time_label.text="Siege record · simulation paused" if paused else "Siege record · campaign time is running"
	order_buttons.report.disabled=String(snapshot.region_id).is_empty()
	if days!=last_day:
		last_day=days
		if active:_event("Day %d: pressure %.1f%% · land access restricted %d%%."%[days,pressure_value*100,roundi(float(live.get("blockade",0))*100)])
	var next_signature:=JSON.stringify([live,snapshot.active,snapshot.battle_active,snapshot.summary,snapshot.own_force.get("troops",0),snapshot.own_force.get("morale",0)])
	if signature!=next_signature:signature=next_signature;_details();_commands()
	result_panel.visible=not active
	if not active:
		result_title.text="ASSAULT UNDERWAY" if in_battle else "SIEGE ENDED"
		result_body.text=String(snapshot.summary)
		if not snapshot.battle.is_empty() and not in_battle:result_body.text+="\n"+String(snapshot.battle.get("outcome","Battle ended")).replace("_"," ").capitalize()
		result_action.visible=not snapshot.battle.is_empty() or MilitaryCampaign.recovery.home_unavailable();result_action.text="SURVIVAL & INDEPENDENCE →" if snapshot.battle.is_empty() and MilitaryCampaign.recovery.home_unavailable() else ("VIEW ASSAULT →" if in_battle else "REVIEW BATTLE →")
	_layout()
func _operation()->Dictionary:
	if not MilitaryCampaign.active_siege.is_empty() and String(MilitaryCampaign.active_siege.id)==siege_id:return MilitaryCampaign.active_siege
	for past:Dictionary in MilitaryCampaign.siege_history:
		if String(past.id)==siege_id:return past
	return {}
func _enemy_report()->String:
	if last_snapshot.mode=="offensive":
		var city:Dictionary=CivilizationSystem.city_intelligence.known("player",String(last_snapshot.region_id));var report:Dictionary=city.get("fields",{}).get("garrison",{})
		if report.is_empty():return "Strength unknown · no reliable report"
		return "%d–%d reported · observed day %d%s"%[roundi(float(report.low)),roundi(float(report.high)),int(report.observed_day)," · stale" if report.get("stale",false) else ""]
	var threat:Dictionary=_operation().get("threat",{});var estimate:=int(threat.get("estimated_strength",0))
	return "About %d reported · enemy morale unknown"%estimate if estimate>0 else "Strength and morale unconfirmed"
func _metric(parent:Node,caption:String,value:String,explanation:String,color:Color=TEXT)->void:
	_label(parent,caption,11,MUTED);_label(parent,value,22,color,true).tooltip_text=explanation
	if canvas.size.y>=800:_body(parent,explanation,12,MUTED)
func _details()->void:
	if not is_instance_valid(detail_content) or last_snapshot.is_empty():return
	_clear(detail_content)
	if details_tab=="reports":
		_label(detail_content,"LATEST INTELLIGENCE",20,TEAL,true)
		_body(detail_content,String(live.get("enemy_supply_assessment","Enemy stores unconfirmed.")),13,TEXT)
		_body(detail_content,String(live.get("civilian_hardship",last_snapshot.description)),12,MUTED)
		if canvas.size.y>=700:_body(detail_content,String(last_snapshot.description),12,MUTED)
	elif details_tab=="supplies":
		_metric(detail_content,"YOUR RATION COVERAGE","%d%%"%roundi(float(live.get("own_supply_ratio",0))*100) if not live.is_empty() else "Siege ended","Share of current ration needs delivered. This is not days of food remaining.",TEAL)
		_metric(detail_content,"LAND ACCESS RESTRICTED","%d%%"%roundi(float(last_snapshot.get("blockade",0))*100),"Share of approaches held. The ring can remain incomplete.",GOLD)
		if canvas.size.y<700:_body(detail_content,"Endurance: "+String(live.get("besieger_endurance","Unknown")) if last_snapshot.mode=="offensive" else "Enemy endurance unconfirmed.",12,TEXT)
		else:_label(detail_content,"ENDURANCE",11,MUTED);_body(detail_content,String(live.get("besieger_endurance","No live endurance report.")),14,TEXT)
		if canvas.size.y>=800:_body(detail_content,String(live.get("enemy_supply_assessment","Enemy stores are unconfirmed.")),12,MUTED)
	else:
		var offensive:=String(last_snapshot.mode)=="offensive";var population:="Unconfirmed"
		if offensive:
			var report:Dictionary=CivilizationSystem.city_intelligence.known("player",String(last_snapshot.region_id)).get("fields",{}).get("population",{})
			if not report.is_empty():population="%d–%d reported"%[roundi(float(report.low)),roundi(float(report.high))]
		else:population="%d residents"%roundi(float(last_snapshot.population))
		_metric(detail_content,"PEOPLE INSIDE",population,"A reported population is not the number of troops defending.",TEAL)
		var defense:=int(last_snapshot.defense_stage);_label(detail_content,"DEFENSES",11,MUTED);_body(detail_content,String(MilitaryCampaign.SETTLEMENT_DEFENSE_STAGES[defense].short) if defense>=0 else "Fortifications unconfirmed",16,TEXT)
		if canvas.size.y>=800:_body(detail_content,String(live.get("civilian_hardship",last_snapshot.description)),12,MUTED)
		if not offensive:_body(detail_content,"Home reserve: %.1f days at current demand."%float(live.get("own_food_days",0)),12,TEXT)
		else:_body(detail_content,"Reports contains the dated supply outlook and civilian access assessment.",12,MUTED)
func _commands()->void:
	if not is_instance_valid(commands_content) or last_snapshot.is_empty():return
	_clear(commands_content)
	if command_tab=="activity":
		_label(commands_content,"SIEGE ACTIVITY",20,GOLD,true)
		var finish:=maxi(0,events.size()-event_page*3)
		for i in range(finish-1,maxi(-1,finish-4),-1):_body(commands_content,String(events[i]),13,TEXT)
		var pages:=HBoxContainer.new();commands_content.add_child(pages);_button(pages,"‹ Older",_page.bind(1));_button(pages,"Newer ›",_page.bind(-1));return
	var active:=bool(last_snapshot.active);var compact:=canvas.size.y<800
	var parent:Node=commands_content
	if compact:
		var grid:=GridContainer.new();grid.columns=2;commands_content.add_child(grid);parent=grid
	order_buttons.continue=_button(parent,"MAINTAIN SIEGE",_siege_order.bind("continue"),TEAL);order_buttons.continue.disabled=not active
	order_buttons.continue.tooltip_text="Keep positions. This button does not start time, resolve battle, or change screens. Use Play or Fast to advance time."
	if not compact:_body(commands_content,"Keep positions. Supply and pressure change as campaign time passes.",12)
	order_buttons.negotiate=_button(parent,"NEGOTIATE",_negotiate);order_buttons.negotiate.disabled=not active
	var negotiation:Dictionary=MilitaryCampaign.siege_negotiation_available(siege_id,String(last_snapshot.rival))
	order_buttons.negotiate.tooltip_text=String(negotiation.get("reason","Talk to the opposing leader."))
	order_buttons.relief=_button(parent,"RELIEF & ALLIES",_relief);order_buttons.relief.disabled=not active
	if not compact:_body(commands_content,"Envoys handle terms and relief. No agreement or reinforcements are assumed.",12)
	order_buttons.withdraw=_button(parent,"LIFT SIEGE" if last_snapshot.mode=="offensive" else "YIELD CITY",_siege_order.bind("withdraw"),ORANGE);order_buttons.withdraw.disabled=not active
	for key in ["continue","negotiate","relief","withdraw"]:order_buttons[key].size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_body(commands_content,"Lift siege: your army starts its return route." if last_snapshot.mode=="offensive" else "Yield city: give up control and enter occupation and recovery.",12)

func _page(delta:int)->void:event_page=clampi(event_page+delta,0,maxi(0,(events.size()-1)/3));_commands()
func _event(text:String)->void:
	if events.is_empty() or String(events.back())!=text:events.append(text)
	if events.size()>24:events.pop_front()
	if command_tab=="activity":_commands()
func _assault_blocker()->String:
	if last_snapshot.is_empty() or not last_snapshot.active:return "This siege is no longer active."
	if not MilitaryCampaign.active_engagement.is_empty():return "Another battle is already active."
	if not MilitaryCampaign.pending_aftermath.is_empty():return "Resolve the previous battle's aftermath first."
	if int(last_snapshot.own_force.get("troops",0))<=0:return "No local force is available to fight."
	return ""
func _siege_order(order:String)->void:
	print("SIEGE_UI_ORDER id=",siege_id," order=",order," day=",GameState.elapsed_days)
	if order=="assault" and last_snapshot.get("battle_active",false):_open_battle();return
	if order=="assault":_speed(0)
	var result:Dictionary=MilitaryCampaign.siege_order(siege_id,order)
	feedback.text=("Positions maintained. Time stays paused until you press Play or Fast." if is_instance_valid(terrain) and float(terrain.game_speed)==0 else "Positions maintained. Campaign time continues at your chosen speed.") if order=="continue" and not result.has("error") else String(result.get("error",result.get("message","Order recorded.")));feedback.tooltip_text=feedback.text;_event(feedback.text)
	if order=="assault" and not result.has("error"):
		MilitaryCampaign.active_engagement["awaiting_player_view"]=true;_open_battle();return
	if order=="withdraw" and not result.has("error"):_speed(0)
	_refresh()
func _result_action()->void:
	if last_snapshot.get("battle",{}).is_empty() and MilitaryCampaign.recovery.home_unavailable():preload("res://scripts/hud/recovery_screen.gd").open()
	else:_open_battle()
func _open_battle()->void:
	print("SIEGE_UI_TRANSITION battle id=",siege_id)
	_speed(0)
	var snapshot:Dictionary=MilitaryCampaign.siege_visual_snapshot(siege_id)
	var battle:Dictionary=snapshot.get("battle",{})
	if battle.is_empty():feedback.text="No linked battle is available.";return
	if not MilitaryCampaign.active_engagement.is_empty() and int(MilitaryCampaign.active_engagement.seed)!=int(battle.get("seed",-1)):feedback.text="Finish the current battle before reviewing this one.";return
	_restore_scale();MilitaryCommandUI.call_deferred("_open_battle_graphics",0,int(battle.get("seed",-1)));queue_free()
func _negotiate()->void:
	_speed(0)
	if ForeignDiplomacy.leader(String(last_snapshot.rival)).is_empty():feedback.text="No opposing leader is available for contact. Review the city report first.";return
	ForeignDiplomacy.open(String(last_snapshot.rival))
func _relief()->void:
	_speed(0);ForeignDiplomacy.open_relief(siege_id)
func _city_report()->void:
	_speed(0);CivilizationSystem.city_intelligence.open(String(last_snapshot.get("region_id","")))
func _speed(value:float)->void:
	print("SIEGE_UI_TIME requested=",value," day=",GameState.elapsed_days)
	if is_instance_valid(terrain):terrain.call("_set_game_speed",value)
	else:feedback.text="Time controls require a live campaign."
func _terrain(node:Node)->Node:
	if node.has_method("_set_game_speed"):return node
	for child in node.get_children():
		var found:=_terrain(child)
		if found!=null:return found
	return null
func _close()->void:print("SIEGE_UI_CLOSE id=",siege_id);_speed(0);_restore_scale();queue_free()
func _restore_scale()->void:
	if scale_restored:return
	scale_restored=true;get_window().content_scale_size=previous_scale;get_window().content_scale_aspect=previous_aspect
func _exit_tree()->void:
	if not scale_restored:get_window().set_deferred("content_scale_size",previous_scale);get_window().set_deferred("content_scale_aspect",previous_aspect)
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:_close();get_viewport().set_input_as_handled()
func _layout()->void:
	if not is_instance_valid(bottom):return
	var w:=canvas.size.x;var h:=canvas.size.y;var compact:=w<1200;var narrow:=w<1050
	var top:=22.0 if ProjectSettings.get_setting("application/config/custom_user_dir_name","").contains("Test") else 0.0
	header.position=Vector2(0,top);header.size=Vector2(w,56);title.add_theme_font_size_override("font_size",22 if compact else 26)
	strip.position=Vector2(0,top+56);strip.size=Vector2(w,142 if compact else 96)
	if compact:
		for side in 2:force_panels[side].position=Vector2(side*w*.5,0);force_panels[side].size=Vector2(w*.5,78)
		progress_panel.position=Vector2(w*.16,80);progress_panel.size=Vector2(w*.68,0)
	else:
		force_panels[0].position=Vector2.ZERO;force_panels[0].size=Vector2(w*.28,84);force_panels[1].position=Vector2(w*.72,0);force_panels[1].size=Vector2(w*.28,84);progress_panel.position=Vector2(w*.29,0);progress_panel.size=Vector2(w*.42,0)
	var body_top:=top+56+80+progress_panel.get_combined_minimum_size().y+12 if compact else top+164
	details_panel.position=Vector2(16,body_top);details_panel.size=Vector2(284,0);commands_panel.position=Vector2(w-316,body_top);commands_panel.size=Vector2(300,0)
	details_panel.visible=last_snapshot.get("active",false) and (not narrow or not narrow_commands);commands_panel.visible=last_snapshot.get("active",false) and (not narrow or narrow_commands)
	if narrow:commands_panel.position.x=16
	narrow_toggle.visible=narrow and last_snapshot.get("active",false)
	bottom.size=Vector2(w-24,0);bottom.position=Vector2(12,h-bottom.get_combined_minimum_size().y-12)
	result_panel.size=Vector2(minf(520,w-32),0);result_panel.position=Vector2((w-result_panel.size.x)*.5,maxf(body_top,(h-result_panel.get_combined_minimum_size().y)*.5))
