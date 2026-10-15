extends "res://scripts/hud/people_screen.gd"
## Representative workforce illustration. Drafts are read-only until the provider's guarded
## commit calls the original ManualWork commands. Person/city actions are inherited.
const WorkforceCast=preload("res://scripts/hud/people_workforce_cast.gd")
const ROLE_NAMES:={"Food":"Food grounds","Survey":"Surveying","Extraction":"Wood & stone","Construction":"Building","Crafting":"Workshops","Logistics":"Water & carrying","Knowledge":"Learning","Administration":"Keeping & caring","Defense":"The watch"}
const ROLE_PURPOSE:={"Food":"Gather, hunt, fish and grow food.","Survey":"Find resources in the nearby land.","Extraction":"Bring timber, stone and ore out of the land.","Construction":"Raise homes and works; repair what stands.","Crafting":"Make tools, equipment and everyday goods.","Logistics":"Carry supplies and bring drinking water home.","Knowledge":"Learn, teach and pursue current studies.","Administration":"Keep, distribute and care for the people.","Defense":"Keep watch and prepare our defenders."}

var settlement_view:Control
var stage:Control
var overlay:Control
var scene_title:Label
var scene_toolbar:HFlowContainer
var scope_note:Label
var figure_legend:Label
var mode_note:Label
var overview_button:Button
var leaders_button:Button
var pause_button:Button
var markers:Dictionary={}
var anchors:Dictionary={}
var active_role:=""
var draft:Dictionary={}
var forecast:Dictionary={}
var draft_stale:=false
var focus_panel:PanelContainer
var focus_body:VBoxContainer
var evidence_panel:PanelContainer
var focus_actions:VBoxContainer
var focus_evidence:VBoxContainer
var focus_title:Label
var focus_purpose:Label
var source_reading:Label
var people_reading:Label
var transfer_reading:Label
var forecast_reading:Label
var risk_reading:Label
var apply_button:Button
var cancel_button:Button
var decrease_button:Button
var increase_button:Button
var five_button:Button
var pending_note:Label
var _configured:=false
var _draft_revision:Array=[]
var preview_rebased:=false
var _placement_key:=0
var effect_graph:WorkEffectGraphic
var connections:AreaConnections
var face_shelf:Control
var food_strip:VBoxContainer
var food_graph:FoodCrossGraphic
var navigation:VBoxContainer
var _shown_counts:Dictionary={}
var _shown_percentages:Dictionary={}
var _current_percentages:Dictionary={}
var _showing_preview:=false

func setup(block:Dictionary)->void:
	super.setup(block)
	name="CivilizationPeopleScreen"
	parts.labor.visible=false
	# The portrait grid wraps to the available width; its previous row width
	# must not become a minimum that prevents the entire dock from shrinking.
	var face_section:=faces_row.get_parent()
	face_shelf=Control.new();face_shelf.name="FaceShelf";face_shelf.size_flags_horizontal=Control.SIZE_EXPAND_FILL;face_section.add_child(face_shelf)
	faces_row.reparent(face_shelf)
	_layout.call_deferred()
	var requested:=String(block.get("focus_work",""))
	if requested!="":focus_work.call_deferred(requested)

func _layout()->void:
	super._layout()
	if face_shelf!=null and is_instance_valid(faces_row):
		faces_row.size.x=maxf(0,size.x)
		face_shelf.custom_minimum_size.y=faces_row.get_combined_minimum_size().y

func _build_scene()->void:
	var heading:=HFlowContainer.new();heading.name="PeopleSituation";heading.add_theme_constant_override("h_separation",24);heading.add_theme_constant_override("v_separation",4);add_child(heading);scene_toolbar=heading
	scene_title=_annotation_label("",18);scene_title.add_theme_font_override("font",T.font("ui_strong"));heading.add_child(scene_title)
	scope_note=_annotation_label("",12);scope_note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;heading.add_child(scope_note)
	figure_legend=_annotation_label("100 figures · each = 1% of workers",12);figure_legend.name="WorkforceFigureLegend";figure_legend.size_flags_vertical=Control.SIZE_SHRINK_CENTER;heading.add_child(figure_legend)
	var command:=heading
	mode_note=_annotation_label("",12);mode_note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;command.add_child(mode_note)
	overview_button=_annotation_button(command,"← Overview",_return_overview);overview_button.visible=false
	leaders_button=_annotation_button(command,"Let our leaders assign",_delegate);leaders_button.visible=false
	pause_button=_annotation_button(command,"Pause to plan",_pause_to_plan);pause_button.name="PauseToPlan";pause_button.tooltip_text="The world keeps moving while you plan. Pause it here, then resume with the clock when ready.";pause_button.visible=false
	pending_note=_annotation_label("",12);pending_note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;command.add_child(pending_note)
	stage=Control.new();stage.name="LivingPeopleScene";stage.custom_minimum_size.y=560;stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stage.clip_contents=true;add_child(stage)
	settlement_view=_make_settlement_view();settlement_view.name="PeopleSettlementView";stage.add_child(settlement_view);settlement_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settlement_view.connect("role_anchors_changed",_anchors_changed)
	if settlement_view.has_signal("role_selected"):settlement_view.connect("role_selected",focus_work)
	overlay=Control.new();overlay.name="WorkAreaReadings";overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage.add_child(overlay);overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	connections=AreaConnections.new();overlay.add_child(connections);connections.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for role:String in ROLE_NAMES:
		var marker:=PanelContainer.new();marker.name="WorkArea_"+role;marker.add_theme_stylebox_override("panel",StyleBoxEmpty.new());overlay.add_child(marker)
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",8);marker.add_child(line)
		var body:=VBoxContainer.new();body.add_theme_constant_override("separation",0);line.add_child(body)
		var title:=_annotation_label(ROLE_NAMES[role],14);title.add_theme_font_override("font",T.font("ui_strong"));body.add_child(title)
		var number:=_annotation_label("",16);number.name="Workers";body.add_child(number)
		var assign:=_annotation_button(line,"Assign",focus_work.bind(role));assign.name="Assign_"+role;assign.tooltip_text="Assign workers to "+String(ROLE_NAMES[role])
		markers[role]={"node":marker,"number":number,"button":assign}
	_build_focus()
	heading.reparent(overlay);heading.position=Vector2(12,8)
	navigation=VBoxContainer.new();navigation.name="VillageNavigation";navigation.add_theme_constant_override("separation",0);overlay.add_child(navigation)
	var camera_buttons:=HBoxContainer.new();camera_buttons.add_theme_constant_override("separation",8);navigation.add_child(camera_buttons)
	var zoom_out:=_annotation_button(camera_buttons,"−",func():settlement_view.call("zoom_view",1.0/.88));zoom_out.name="VillageZoomOut";zoom_out.custom_minimum_size.x=36;zoom_out.tooltip_text="Zoom out"
	var zoom_in:=_annotation_button(camera_buttons,"+",func():settlement_view.call("zoom_view",.88));zoom_in.name="VillageZoomIn";zoom_in.custom_minimum_size.x=36;zoom_in.tooltip_text="Zoom in"
	var recenter:=_annotation_button(camera_buttons,"Center view",func():settlement_view.call("reset_navigation"));recenter.name="VillageRecenter";recenter.tooltip_text="Return to the selected work area, or the workforce overview. Home also centers the view."
	var help:=_annotation_label("Drag to move · scroll to zoom",11);help.mouse_filter=Control.MOUSE_FILTER_IGNORE;navigation.add_child(help)
	stage.resized.connect(_fit_scene)

func _make_settlement_view()->Control:
	return load("res://scripts/hud/people_settlement_view.gd").new()

static func annotation_ink()->Color:
	return T.INK if T.INK.get_luminance()>T.PANEL_BG.get_luminance() else T.PANEL_BG
static func annotation_shade()->Color:
	return T.PANEL_BG if T.PANEL_BG.get_luminance()<T.INK.get_luminance() else T.INK

func _annotation_label(words:String,pixels:int=14)->Label:
	var label:=T.make_label(words,pixels,annotation_ink())
	label.add_theme_color_override("font_shadow_color",Color(annotation_shade(),0.95));label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1)
	label.add_theme_color_override("font_outline_color",Color(annotation_shade(),0.65));label.add_theme_constant_override("outline_size",2)
	return label

func _annotation_button(parent:Node,words:String,callback:Callable,primary:=false)->Button:
	var button:=_scene_button(parent,words,callback,primary)
	button.custom_minimum_size.y=40
	button.add_theme_font_size_override("font_size",14)
	if not primary:
		var normal:=T.flat(Color.TRANSPARENT,T.ACTION,0,0,3);normal.border_width_bottom=1;normal.border_color=T.ACTION
		button.add_theme_stylebox_override("normal",normal)
		button.add_theme_stylebox_override("hover",T.flat(Color(annotation_shade(),.35),T.ACTION,1,2,3))
		button.add_theme_stylebox_override("pressed",T.flat(Color(annotation_shade(),.55),T.ACTION,1,2,3))
		button.add_theme_color_override("font_color",annotation_ink());button.add_theme_color_override("font_hover_color",annotation_ink())
		button.add_theme_color_override("font_focus_color",annotation_ink());button.add_theme_color_override("font_pressed_color",annotation_ink());button.add_theme_color_override("font_disabled_color",Color(annotation_ink(),.5))
		button.add_theme_color_override("font_outline_color",annotation_shade());button.add_theme_constant_override("outline_size",2)
	return button

func _scene_button(parent:Node,words:String,callback:Callable,primary:=false)->Button:
	var button:=Button.new();button.text=words;T.apply_button_style(button,primary);button.pressed.connect(callback);parent.add_child(button);return button

func _build_focus()->void:
	focus_panel=PanelContainer.new();focus_panel.name="WorkDraft";focus_panel.visible=false;focus_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new());overlay.add_child(focus_panel)
	focus_body=VBoxContainer.new();focus_body.add_theme_constant_override("separation",4);focus_panel.add_child(focus_body)
	var identity:=HBoxContainer.new();identity.add_theme_constant_override("separation",10);focus_body.add_child(identity)
	focus_title=_annotation_label("",20);focus_title.add_theme_font_override("font",T.font("ui_strong"));identity.add_child(focus_title)
	source_reading=_annotation_label("",12);focus_body.add_child(source_reading)
	focus_purpose=_annotation_label("");focus_purpose.visible=false;focus_body.add_child(focus_purpose)
	people_reading=_annotation_label("",16);people_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_body.add_child(people_reading)
	var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",8);focus_body.add_child(controls)
	decrease_button=_annotation_button(controls,"−",_step.bind(-1));decrease_button.name="DraftLess";decrease_button.custom_minimum_size.x=40
	increase_button=_annotation_button(controls,"+",_step.bind(1));increase_button.name="DraftMore";increase_button.custom_minimum_size.x=40
	five_button=_annotation_button(controls,"+5",_step.bind(5));five_button.name="DraftFive";five_button.custom_minimum_size.x=40
	var step_note:=_annotation_label("1% requested",12);step_note.tooltip_text="Each step requests one percentage point. Figures show the likely allocation after whole-worker rounding and food protection.";step_note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;controls.add_child(step_note)
	transfer_reading=_annotation_label("");transfer_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_body.add_child(transfer_reading)
	risk_reading=_annotation_label("");risk_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;risk_reading.add_theme_color_override("font_color",annotation_ink().lerp(T.ACTION,.45));focus_body.add_child(risk_reading)
	var commands:=HFlowContainer.new();commands.add_theme_constant_override("h_separation",10);commands.add_theme_constant_override("v_separation",4);focus_body.add_child(commands)
	apply_button=_annotation_button(commands,"Apply assignment",_apply_draft,true);apply_button.name="ApplyWorkDraft"
	cancel_button=_annotation_button(commands,"Cancel",_cancel_draft);cancel_button.name="CancelWorkDraft"
	focus_actions=focus_body
	evidence_panel=PanelContainer.new();evidence_panel.name="WorkConsequences";evidence_panel.visible=false;evidence_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new());overlay.add_child(evidence_panel)
	focus_evidence=VBoxContainer.new();focus_evidence.add_theme_constant_override("separation",3);evidence_panel.add_child(focus_evidence)
	effect_graph=WorkEffectGraphic.new();effect_graph.name="LikelyWorkEffects";focus_evidence.add_child(effect_graph)
	forecast_reading=_annotation_label("");forecast_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_evidence.add_child(forecast_reading)
	food_strip=VBoxContainer.new();food_strip.name="FoodCrossEffect";food_strip.add_theme_constant_override("separation",3);overlay.add_child(food_strip)
	food_graph=FoodCrossGraphic.new();food_graph.name="FoodCrossEffectDiagram";food_strip.add_child(food_graph)

func _fill_scene(scene:Dictionary)->void:
	if settlement_view==null:return
	var context:Dictionary=data.get("settlement_view",{}).duplicate()
	context.allocations={}
	for task:Dictionary in data.get("labor",{}).get("tasks",[]):context.allocations[String(task.id)]=int(task.count)
	if not _configured:settlement_view.call("configure",context);_configured=true
	else:settlement_view.call("update_state",context)
	scene_title.text="Our workforce"
	scope_note.text="%d workers · across our settlements" % int(data.get("labor",{}).get("able",0))
	scene_title.tooltip_text="An illustration of our work categories across all settlements, not a map of one town."
	figure_legend.tooltip_text="Percentages are rounded to 100 representative figures. Actual worker counts remain visible beside each work area."
	_sync_workforce()
	_fit_scene.call_deferred()

## Parent's nine-row labor UI is intentionally replaced, not duplicated.
func _rebuild_labor()->void:
	if stage==null:return
	var labor:Dictionary=data.get("labor",{})
	mode_note.text="You assign" if bool(labor.get("manual",false)) else "Leaders assign"
	mode_note.tooltip_text="\n".join(PackedStringArray(labor.get("who",[])))+"\n"+String(labor.get("leaders_tip",""))
	leaders_button.tooltip_text=String(labor.get("leaders_tip",""))
	leaders_button.visible=bool(labor.get("manual",false))
	pause_button.visible=bool(data.get("world_running",false))
	if not draft.is_empty():draft_stale=draft_stale or bool(forecast.get("stale",false)) or _draft_revision!=data.get("workforce_revision",[])
	_refresh_focus()

func _current_counts()->Dictionary:
	var counts:={}
	for role:String in ROLE_NAMES:counts[role]=0
	for task:Dictionary in data.get("labor",{}).get("tasks",[]):
		if counts.has(String(task.id)):counts[String(task.id)]=maxi(0,int(task.count))
	return counts

func _valid_changed_preview()->bool:
	return not (draft.get("commands",[]) as Array).is_empty() and bool(draft.get("has_changes",true)) and bool(forecast.get("ok",false)) and not draft_stale and not bool(forecast.get("stale",false)) and _draft_revision==data.get("workforce_revision",[])

func _sync_workforce()->void:
	if settlement_view==null:return
	var current:=_current_counts()
	_current_percentages=WorkforceCast.apportion(current)
	_showing_preview=_valid_changed_preview()
	# Heads after the original command replay include local food protection.
	# Productivity-equivalent workers and the requested split are not headcounts.
	_shown_counts=(forecast.get("after",{}).get("counts",current) as Dictionary).duplicate() if _showing_preview else current
	_shown_percentages=WorkforceCast.apportion(_shown_counts)
	if settlement_view.has_method("set_workforce"):settlement_view.call("set_workforce",_shown_counts,_showing_preview)
	for role:String in markers:
		var now:=int(current.get(role,0));var next:=int(_shown_counts.get(role,0))
		var percent:=int(_shown_percentages.get(role,0));var prior:=int(_current_percentages.get(role,0))
		(markers[role].number as Label).text="%d%% → %d%% · %s workers"%[prior,percent,preload("res://scripts/hud/era_words.gd").grouped(next)] if _showing_preview and (prior!=percent or now!=next) else "%d%% · %s workers"%[percent,preload("res://scripts/hud/era_words.gd").grouped(next)]
		(markers[role].node as Control).tooltip_text="Current: %d%% · %d workers"%[prior,now]+("\nProposed after rounding and food protection: %d%% · %d workers"%[percent,next] if _showing_preview else "")+"\n"+String(ROLE_PURPOSE[role])
	figure_legend.text="100 figures · each = 1% of workers" if int(_shown_percentages.get("Unassigned",0))==0 else "100 figures · no workers assigned"

func _movement_words()->String:
	transfer_reading.tooltip_text=""
	if not _showing_preview:return ""
	var moved:=0;var donors:PackedStringArray=[];var recipients:PackedStringArray=[];var details:PackedStringArray=[]
	var current:=_current_counts()
	for role:String in ROLE_NAMES:
		var before:=int(_current_percentages.get(role,0));var after:=int(_shown_percentages.get(role,0))
		if after>before:moved+=after-before;recipients.append(ROLE_NAMES[role])
		elif after<before:donors.append(ROLE_NAMES[role])
		if int(current.get(role,0))!=int(_shown_counts.get(role,0)):details.append("%s: %d%% → %d%% · %d → %d workers"%[ROLE_NAMES[role],before,after,int(current.get(role,0)),int(_shown_counts.get(role,0))])
	transfer_reading.tooltip_text="\n".join(details)
	var words:="The likely allocation leaves the figures unchanged." if moved==0 else ("%d figure%s move%s from %s."%[moved,"" if moved==1 else "s","s" if moved==1 else "",donors[0]] if donors.size()==1 else "%d figures change work across %d areas."%[moved,donors.size()+recipients.size()])
	var requested:=int(preload("res://scripts/manual_work.gd").percents(draft.get("shares",{})).get(active_role,0))
	var effective:=int(_shown_percentages.get(active_role,0))
	if requested!=effective:
		var protected:bool=(forecast.get("warnings",[]) as Array).any(func(w:Dictionary)->bool:return String(w.get("kind",""))=="safeguard")
		words+=" %d%% requested; %s yields %d%%."%[requested,"food protection" if protected else "whole-worker rounding",effective]
	return words

func _api(method:String,arguments:Array=[])->Variant:
	var callback:Variant=(data.get("workforce",{}) as Dictionary).get(method)
	if callback is Callable and (callback as Callable).is_valid():return (callback as Callable).callv(arguments)
	return null

## Root's category shortcuts call this after opening Home → People.
func focus_work(role:String)->void:
	if not ROLE_NAMES.has(role):return
	active_role=role
	if draft.is_empty():
		var captured:Variant=_api("capture")
		if captured is Dictionary and bool(captured.get("ok",false)):draft=captured;_draft_revision=data.get("workforce_revision",[]).duplicate(true)
		_evaluate()
	settlement_view.call("focus_role",role)
	var impact_callback:Variant=data.get("labor",{}).get("impact_of")
	var impact:Dictionary=(impact_callback as Callable).call(role) if impact_callback is Callable else {}
	focus_purpose.text=String(ROLE_PURPOSE.get(role,impact.get("lead","")))
	var details:PackedStringArray=[String(impact.get("lead",""))]
	for line:Dictionary in impact.get("lines",[]):details.append("%s: %s. %s" % [line.get("label",""),line.get("value",""),line.get("words","")])
	focus_purpose.tooltip_text="\n".join(details)
	_refresh_focus()
	_focus_assignment.call_deferred()

func _focus_assignment()->void:
	# Opening an area hides its Assign button. Carry keyboard focus into the
	# visible controls, without disturbing a reader already working in them.
	if active_role=="" or get_viewport().gui_get_focus_owner()!=null:return
	for button:Button in [decrease_button,increase_button,overview_button]:
		if button.is_visible_in_tree() and not button.disabled:button.grab_focus();return

func _step(points:int)->void:
	if draft.is_empty() or active_role=="":return
	var next:Variant=_api("step",[draft,active_role,points])
	if next is Dictionary:draft=next;_evaluate();_refresh_focus()

func _evaluate()->void:
	var result:Variant=_api("evaluate",[draft])
	forecast=result if result is Dictionary else {}
	draft_stale=bool(forecast.get("stale",false)) or (_draft_revision!=data.get("workforce_revision",[]) if not draft.is_empty() else false)

func _refresh_focus()->void:
	if focus_panel==null:return
	_sync_workforce()
	var focused:=active_role!=""
	focus_panel.visible=focused;evidence_panel.visible=focused and bool(forecast.get("ok",false)) and not draft_stale;overview_button.visible=focused;food_strip.visible=focused
	for role:String in markers:(markers[role].node as Control).visible=not focused
	var commands:Array=draft.get("commands",[])
	pending_note.text=("Preview out of date · showing current work" if draft_stale else ("Proposed work · not applied" if _showing_preview else "Preview unavailable · showing current work")) if not commands.is_empty() else ""
	if not focused:return
	focus_title.text=String(ROLE_NAMES.get(active_role,active_role));focus_title.tooltip_text=focus_purpose.tooltip_text
	var now:=int(_current_counts().get(active_role,0))
	people_reading.text="Current %d%% · %d workers"%[int(_current_percentages.get(active_role,0)),now]
	if _showing_preview:people_reading.text+="\nProposed %d%% · %d workers"%[int(_shown_percentages.get(active_role,0)),int(_shown_counts.get(active_role,0))]
	transfer_reading.text=_movement_words();transfer_reading.visible=not transfer_reading.text.is_empty()
	effect_graph.show_forecast(forecast,active_role,String(data.get("settlement_view",{}).get("settlement_id","")),_showing_preview)
	forecast_reading.text=_forecast_words();forecast_reading.visible=not forecast_reading.text.is_empty()
	var warnings:=_warning_words() if not draft_stale else PackedStringArray()
	var food:Dictionary=forecast.get("after",{}).get("food",{})
	if not draft_stale and float(food.get("net",0))<0 and String(food.get("hunger_risk","none"))=="none":warnings.append("Food stores fall %.1f rations/day." % -float(food.net))
	if draft_stale:warnings.insert(0,"Conditions changed while you planned. Refresh this preview before applying.")
	elif not bool(forecast.get("ok",false)):warnings.insert(0,String(forecast.get("reason","A forecast is not available yet.")))
	risk_reading.text=" · ".join(warnings);risk_reading.visible=not warnings.is_empty()
	_update_food_strip(_showing_preview)
	apply_button.text="Refresh preview" if draft_stale else ("Apply assignment" if bool(data.get("labor",{}).get("manual",false)) else "Take control & apply")
	apply_button.disabled=not draft_stale and (commands.is_empty() or not bool(forecast.get("ok",false)))
	apply_button.visible=draft_stale or not commands.is_empty()
	cancel_button.visible=not commands.is_empty()
	cancel_button.disabled=commands.is_empty()
	var normalized:Dictionary=preload("res://scripts/manual_work.gd").percents(draft.get("shares",{})) if not draft.is_empty() else {}
	decrease_button.disabled=draft.is_empty() or int(normalized.get(active_role,0))<=0
	increase_button.disabled=draft.is_empty() or int(normalized.get(active_role,0))>=100;five_button.disabled=increase_button.disabled
	_fit_scene.call_deferred()

func _warning_words()->PackedStringArray:
	var all:Array=forecast.get("warnings",[])
	var complete:PackedStringArray=[]
	for warning:Dictionary in all:complete.append(String(warning.get("text","")).replace("currently puts extra hands on food","would put extra hands on food with this draft"))
	risk_reading.tooltip_text="\n".join(complete)
	if all.size()<=2:
		var brief:PackedStringArray=[]
		for warning:Dictionary in all:brief.append(_brief_warning(warning))
		return brief
	var groups:={}
	for warning:Dictionary in all:
		var kind:=String(warning.get("kind","other"))
		if not groups.has(kind):groups[kind]=[]
		groups[kind].append(warning)
	var summary:PackedStringArray=[]
	for kind:String in ["starvation","food_shortage","water","safeguard","other"]:
		var items:Array=groups.get(kind,[])
		if items.is_empty():continue
		if items.size()==1:summary.append(_brief_warning(items[0]));continue
		match kind:
			"starvation":summary.append("%d settlements cannot feed everyone now; continued shortfall risks starvation." % items.size())
			"food_shortage":
				var earliest:=9999
				for item:Dictionary in items:earliest=mini(earliest,int(item.get("days",9999)))
				summary.append("%d settlements risk food shortages; the first in about %d days." % [items.size(),earliest])
			"water":summary.append("%d settlements cannot bring home all the drinking water they need." % items.size())
			"safeguard":summary.append("%d town leaders add food workers; these estimates include their protection." % items.size())
			_:summary.append("%d other conditions affect this estimate." % items.size())
	return summary

func _brief_warning(warning:Dictionary)->String:
	var town:=String(warning.get("town","This settlement"))
	match String(warning.get("kind","")):
		"starvation":return "%s: food is short now. Continued shortfall risks starvation." % town
		"food_shortage":return "%s: food may run short in about %d days." % [town,int(warning.get("days",0))]
		"water":return "%s: drinking water falls short of daily needs." % town
		"safeguard":return "Food protection overrides part of this draft."
	return String(warning.get("text",""))

func _update_food_strip(changed:bool)->void:
	food_strip.visible=active_role!="" and not draft_stale and bool(forecast.get("ok",false)) and (changed or active_role=="Food" or risk_reading.visible)
	food_graph.show_food(forecast,changed)
	food_graph.tooltip_text=effect_graph.tooltip_text+"\n90-day path: captured current conditions; known seasonal food changes are included."

func _forecast_words()->String:
	if forecast.is_empty():return ""
	var new_food:Dictionary=forecast.get("after",{}).get("food",{})
	if new_food.is_empty():return ""
	if active_role=="Extraction":return "Output is not forecast. "+String(forecast.get("after",{}).get("materials",{}).get("reason","It also depends on deposits, carrying and demand."))
	if active_role=="Crafting":return "Goods output is not forecast; it also depends on supplies and demand."
	if active_role=="Logistics" and not bool(forecast.get("after",{}).get("water",{}).get("known",false)):return "Water collection is not measured yet. Food assumes today’s conditions."
	return ""

func _apply_draft()->void:
	if draft.is_empty():return
	if draft_stale or not bool(_api("is_current",[draft])):
		var commands:Array=draft.get("commands",[]).duplicate(true)
		var fresh:Variant=_api("capture")
		if not fresh is Dictionary or not bool(fresh.get("ok",false)):return
		draft=fresh;_draft_revision=data.get("workforce_revision",[]).duplicate(true)
		for command:Dictionary in commands:
			var next:Variant=_api("step",[draft,String(command.role),int(command.points)])
			if next is Dictionary:draft=next
		_evaluate();preview_rebased=true;_refresh_focus();return
	var result:Variant=_api("commit",[draft,not bool(data.get("labor",{}).get("manual",false))])
	if result is Dictionary and bool(result.get("ok",false)):
		draft={};forecast={};draft_stale=false;preview_rebased=false;_refresh_focus()
		# The provider queued its live update first. Capture the next plan only
		# after that update so its cheap UI revision matches the new allocation.
		focus_work.call_deferred(active_role)
	else:
		draft_stale=true;_refresh_focus()

func _cancel_draft()->void:
	draft={};forecast={};draft_stale=false;preview_rebased=false
	_refresh_focus()
	if active_role!="":focus_work(active_role)

func _delegate()->void:
	draft={};forecast={};draft_stale=false;preview_rebased=false
	var callback:Variant=data.get("labor",{}).get("on_leaders")
	if callback is Callable:(callback as Callable).call()
	_return_overview()

func _pause_to_plan()->void:
	var callback:Variant=data.get("pause_to_plan")
	if callback is Callable and callback.is_valid():callback.call()

func _return_overview()->void:
	var previous:=active_role
	var return_focus:=get_viewport().gui_get_focus_owner()!=null
	active_role="";settlement_view.call("reset_view");_refresh_focus()
	if return_focus and markers.has(previous):(markers[previous].button as Button).grab_focus.call_deferred()

func _anchors_changed(next:Dictionary)->void:
	anchors=next;_fit_scene()

func _fit_scene()->void:
	if stage==null or not is_inside_tree():return
	var width:=maxf(300,stage.size.x)
	var top:=stage.global_position.y
	var ancestor:Node=stage.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:
			top+=float((ancestor as ScrollContainer).scroll_vertical)
			break
		ancestor=ancestor.get_parent()
	stage.custom_minimum_size.y=clampf(minf(width*0.66,get_viewport_rect().size.y-top-18),420,760)
	var nav_size:=navigation.get_combined_minimum_size()
	navigation.size=nav_size
	# Keep the camera controls inside the visible part of a scrolled scene.
	var nav_top:=8.0
	if ancestor is ScrollContainer:nav_top=maxf(8,(ancestor as ScrollContainer).global_position.y-stage.global_position.y+8)
	navigation.position=Vector2(width-nav_size.x-12,minf(nav_top,maxf(8,stage.size.y-nav_size.y-8)))
	scene_toolbar.size.x=maxf(180,width-nav_size.x-48)
	var toolbar_height:=maxf(scene_toolbar.get_combined_minimum_size().y,nav_size.y)+16
	var occupied:Array[Rect2]=[Rect2(Vector2.ZERO,Vector2(width,toolbar_height)),navigation.get_rect()]
	var lines:Array=[]
	var anchor_info:Dictionary=settlement_view.call("role_anchor_metadata") if settlement_view.has_method("role_anchor_metadata") else {}
	var obstacles:Array[Rect2]=[]
	if settlement_view.has_method("annotation_obstacles"):obstacles.assign(settlement_view.call("annotation_obstacles"))
	# The private camera publishes every frame. Repack only after a visible
	# pixel/layout change, rather than testing every label against every tree
	# while the village is idle.
	var geometry:Array=[Vector2i(stage.size),active_role,toolbar_height,focus_panel.get_combined_minimum_size(),evidence_panel.get_combined_minimum_size(),food_strip.visible,food_strip.get_combined_minimum_size()]
	for role:String in markers:geometry.append([Vector2i(anchors.get(role,Vector2.ZERO)),(markers[role].node as Control).get_combined_minimum_size(),anchor_info.get(role,{}).get("physical",false),anchor_info.get(role,{}).get("plot_ids",[])])
	for obstacle:Rect2 in obstacles:geometry.append(Rect2i(obstacle))
	var key:=hash(geometry)
	if key==_placement_key:return
	_placement_key=key
	for role:String in markers:
		if active_role!="":break # hidden overview labels need no packing during a focus tween
		var marker:Control=markers[role].node
		(markers[role].button as Button).text="Assign workers" if width>=1100 else "Assign"
		marker.size=marker.get_combined_minimum_size()
		var point:Vector2=anchors.get(role,Vector2(width*0.5,stage.size.y*0.5))
		var rect:=_annotation_rect(point,marker.size,occupied,Rect2(Vector2(12,toolbar_height+8),Vector2(width-24,stage.size.y-toolbar_height-20)),ROLE_NAMES.keys().find(role),obstacles)
		marker.position=rect.position;occupied.append(rect)
		lines.append({"from":point,"to":Vector2(clampf(point.x,rect.position.x,rect.end.x),clampf(point.y,rect.position.y,rect.end.y)),"shared":false})
	if connections!=null:connections.lines=lines;connections.visible=true;connections.queue_redraw()
	if focus_panel!=null:
		var point:Vector2=anchors.get(active_role,Vector2(width*0.5,stage.size.y*0.5))
		var control_width:=minf(310,width*.34)
		var evidence_width:=minf(290,width*.32)
		focus_panel.custom_minimum_size.x=control_width;focus_panel.size.x=control_width
		evidence_panel.custom_minimum_size.x=evidence_width;evidence_panel.size.x=evidence_width
		focus_panel.size.y=focus_panel.get_combined_minimum_size().y;evidence_panel.size.y=evidence_panel.get_combined_minimum_size().y
		# Attach readings to the illustrated area's edges, preserving its activity.
		focus_panel.position=Vector2(clampf(point.x+70,16,maxf(16,width-control_width-16)),clampf(point.y-170,toolbar_height+8,maxf(toolbar_height+8,stage.size.y-focus_panel.size.y-100)))
		evidence_panel.position=Vector2(clampf(point.x-evidence_width-65,16,maxf(16,width-evidence_width-16)),clampf(point.y-95,toolbar_height+8,maxf(toolbar_height+8,stage.size.y-evidence_panel.size.y-100)))
		food_strip.size.x=minf(1000,width-40);food_strip.size.y=food_strip.get_combined_minimum_size().y;food_strip.position=Vector2(20,maxf(16,stage.size.y-food_strip.size.y-16))
		if active_role!="" and not obstacles.is_empty():
			var bottom:=food_strip.position.y-12 if food_strip.visible else stage.size.y-16
			var safe:=Rect2(Vector2(16,toolbar_height+8),Vector2(width-32,maxf(1,bottom-toolbar_height-8)))
			var protected:Array[Rect2]=[Rect2(point-Vector2(48,48),Vector2(96,96))]
			var activity:Rect2=anchor_info.get(active_role,{}).get("activity_bounds",Rect2())
			if activity.has_area():protected.append(activity.grow(10))
			focus_panel.position=_annotation_rect(point,focus_panel.size,protected,safe,0,obstacles).position
			protected.append(focus_panel.get_rect())
			evidence_panel.position=_annotation_rect(point,evidence_panel.size,protected,safe,4,obstacles).position
		if active_role!="" and connections!=null:
			connections.lines=[]
			var info:Dictionary=anchor_info.get(active_role,{})
			source_reading.text="";source_reading.visible=false
			for panel:Control in [focus_panel,evidence_panel]:
				var rect:=panel.get_rect();var source:=point;var nearest:=INF
				# End the quiet line on the illustrated zone's nearest edge.
				for polygon:PackedVector2Array in info.get("polygons",[]):
					for vertex:Vector2 in polygon:
						var distance:=vertex.distance_squared_to(rect.get_center())
						if distance<nearest:nearest=distance;source=vertex
				connections.lines.append({"from":source,"to":Vector2(clampf(source.x,rect.position.x,rect.end.x),clampf(source.y,rect.position.y,rect.end.y)),"shared":false})
			connections.queue_redraw()

## Find nearby open space around each illustrated work area.
## Preference is stable on resize.
func _annotation_rect(point:Vector2,extent:Vector2,occupied:Array[Rect2],available:Rect2,index:int,obstacles:Array[Rect2]=[])->Rect2:
	var best:=Rect2(available.position,extent);var score:=INF
	var preferred:=float(index)*2.399963
	for ring in [20.0,72.0,132.0,210.0,290.0]:
		for step in 16:
			var angle:=preferred+step*TAU/16.0
			var direction:=Vector2.from_angle(angle)
			var reach:=Vector2(extent.x*.5+ring,extent.y*.5+ring)
			var at:=point+direction*reach-extent*.5
			at.x=clampf(at.x,available.position.x,maxf(available.position.x,available.end.x-extent.x))
			at.y=clampf(at.y,available.position.y,maxf(available.position.y,available.end.y-extent.y))
			var candidate:=Rect2(at,extent)
			# Distance to the nearest edge avoids penalising horizontal positions
			# just because a label is wider than it is tall (which made stacks).
			var edge:=Vector2(clampf(point.x,candidate.position.x,candidate.end.x),clampf(point.y,candidate.position.y,candidate.end.y))
			var weight:float=edge.distance_squared_to(point)+step*120+ring*ring*.05
			if candidate.has_point(point):weight+=100000
			for obstacle:Rect2 in obstacles:
				if candidate.intersects(obstacle):weight+=180000*candidate.intersection(obstacle).get_area()/maxf(1,candidate.get_area())
			for other:Rect2 in occupied:
				if candidate.intersects(other.grow(8)):weight+=10000000+candidate.intersection(other.grow(8)).get_area()*100
			if weight<score:score=weight;best=candidate
	return best

func view_state()->Dictionary:
	# A preview contains detached system/catalog snapshots. Dock memory retains
	# only the player's intentions, never megabytes of transient simulation data.
	var saved:=super.view_state();saved.focus_work=active_role
	saved.work_plan={"commands":(draft.get("commands",[]) as Array).duplicate(true),"token":draft.get("token",0)}
	return saved

func restore_view_state(saved:Dictionary)->void:
	super.restore_view_state(saved)
	var plan:Dictionary=saved.get("work_plan",{})
	# A live dock refresh restores memory after updating this same widget.
	# Retain its stale flag and draft; only a new reader needs to replay memory.
	var retained:bool=not draft.is_empty() and int(plan.get("token",0))==int(draft.get("token",0)) and plan.get("commands",[])==draft.get("commands",[])
	if not retained and not (plan.get("commands",[]) as Array).is_empty():
		var fresh:Variant=_api("capture")
		if fresh is Dictionary and bool(fresh.get("ok",false)):
			draft=fresh;_draft_revision=data.get("workforce_revision",[]).duplicate(true)
			preview_rebased=int(plan.get("token",0))!=int(draft.get("token",0))
			for command:Dictionary in plan.commands:
				var next:Variant=_api("step",[draft,String(command.role),int(command.points)])
				if next is Dictionary:draft=next
			_evaluate()
	var role:=String(saved.get("focus_work",""))
	if ROLE_NAMES.has(role):focus_work.call_deferred(role)
	else:_refresh_focus()


## Escape backs the camera out first; a further Escape discards an unapplied draft.
func handle_escape()->bool:
	if active_role!="":_return_overview();return true
	if not (draft.get("commands",[]) as Array).is_empty():_cancel_draft();return true
	return false

class AreaConnections extends Control:
	var lines:Array=[]
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		for line:Dictionary in lines:
			var start:Vector2=line.from;var finish:Vector2=line.to
			if start.distance_to(finish)<8:continue
			var elbow:=Vector2(finish.x,start.y)
			var shared:=bool(line.get("shared",false))
			draw_polyline(PackedVector2Array([start,elbow,finish]),Color(T.PANEL_BG,.3 if shared else .7),2 if shared else 3,true)
			var cream:=T.INK if T.INK.get_luminance()>T.PANEL_BG.get_luminance() else T.PANEL_BG
			if shared:
				draw_dashed_line(start,elbow,Color(cream,.55),1.25,5,true);draw_dashed_line(elbow,finish,Color(cream,.55),1.25,5,true)
			else:draw_polyline(PackedVector2Array([start,elbow,finish]),Color(cream,.95),1.5,true)
			draw_circle(start,2.5,(T.INK if T.INK.get_luminance()>T.PANEL_BG.get_luminance() else T.PANEL_BG))

class WorkEffectGraphic extends Control:
	static func annotation_ink()->Color:
		return T.INK if T.INK.get_luminance()>T.PANEL_BG.get_luminance() else T.PANEL_BG
	static func annotation_shade()->Color:
		return T.PANEL_BG if T.PANEL_BG.get_luminance()<T.INK.get_luminance() else T.INK
	static func annotation_accent()->Color:
		# The scene stays dark green in either appearance; Daylight's brick
		# button fill needs lighter ink when it becomes a thin plot or caption.
		return T.ACTION.lerp(annotation_ink(),.45) if T.INK.get_luminance()<T.PANEL_BG.get_luminance() else T.ACTION
	var readings:Array=[]
	var comparing:=false
	func _init()->void:
		custom_minimum_size=Vector2(260,72);mouse_filter=Control.MOUSE_FILTER_PASS
	func show_forecast(result:Dictionary,role:String,settlement_id:String="",has_changes:=false)->void:
		readings.clear();comparing=has_changes
		var before:Dictionary=result.get("before",{});var after:Dictionary=result.get("after",{})
		var old_food:Dictionary=before.get("food",{});var food:Dictionary=after.get("food",{})
		if food.has("net"):
			tooltip_text="Food eaten %.1f → %.1f; spoiled %.1f → %.1f rations/day. Grey shows current work; coral shows this draft." % [float(old_food.get("eaten",0)),float(food.get("eaten",0)),float(old_food.get("spoilage",0)),float(food.get("spoilage",0))]
		if food.has("production"):readings.append({"label":"Food each day","before":float(old_food.get("production",0)),"after":float(food.production),"need":float(food.get("required",0)),"unit":"rations"})
		if role=="Knowledge":
			var old:Dictionary=before.get("research",{});var next:Dictionary=after.get("research",{})
			if next.has("effective_work"):
				var prior:=float(old.get("effective_work",0));var proposed:=float(next.effective_work)
				var words:="%d → %d teams · %+.0f%% effort" % [int(old.get("teams",0)),int(next.get("teams",0)),(proposed/prior-1)*100] if prior>0 else "%d → %d teams · work can begin" % [int(old.get("teams",0)),int(next.get("teams",0))]
				if not comparing:words="%d teams · current supplies" % int(next.get("teams",0))
				readings.append({"label":"Research pace · current supplies","before":prior,"after":proposed,"words":words,"unit":"","current_caption":"100%" if prior>0 else "0%","draft_caption":"%.0f%%"%(proposed/prior*100) if prior>0 else "new"})
		elif role=="Construction":
			var old:=_housing(before,settlement_id);var next:=_housing(after,settlement_id)
			if bool(next.get("building",false)) and float(next.get("work_per_day",0))>0 and float(next.get("days_left",-1))>=0:
				var prior:=maxf(0,float(old.get("days_left",0)));var proposed:=float(next.days_left)
				var words:="%d places · about %.0f → %.0f days" % [int(next.get("batch",0)),prior,proposed] if bool(old.get("building",false)) and float(old.get("work_per_day",0))>0 else "%d places · about %.0f days with this crew" % [int(next.get("batch",0)),proposed]
				if not comparing:words="%d places · about %.0f days" % [int(next.get("batch",0)),proposed]
				readings.append({"label":"Next homes here · estimate","before":prior,"after":proposed,"lower_better":true,"words":words,"unit":""})
			elif after.get("construction",{}).has("builders"):
				readings.append({"label":"Effective building crew","before":float(before.get("construction",{}).get("builders",0)),"after":float(after.construction.builders),"unit":"worker equivalents"})
		elif role=="Logistics":
			var old:Dictionary=before.get("water",{});var next:Dictionary=after.get("water",{})
			if bool(old.get("known",false)) and bool(next.get("known",false)):readings.append({"label":"Drinking needs met · estimate","before":float(old.ratio)*100,"after":float(next.ratio)*100,"need":100.0,"unit":"%"})
		elif role!="Food":
			var old:Dictionary=before.get("effective_workers",{});var next:Dictionary=after.get("effective_workers",{})
			if next.has(role):readings.append({"label":"Effective work crew","before":float(old.get(role,0)),"after":float(next[role]),"unit":"worker equivalents"})
		if role!="Food" and not readings.is_empty():readings.pop_front()
		custom_minimum_size.y=readings.size()*68.0+(18 if role=="Food" else 0);visible=not readings.is_empty();queue_redraw()
	func _housing(plan:Dictionary,settlement_id:String)->Dictionary:
		var construction:Dictionary=plan.get("construction",{})
		if not (construction.get("housing",{}) as Dictionary).is_empty():return construction.housing
		for town:Dictionary in construction.get("towns",[]):
			if String(town.get("id",""))==settlement_id:return town.get("construction",{}).get("housing",{})
		return {}
	func _say(font:Font,at:Vector2,words:String,pixels:int,ink:Color)->void:
		draw_string_outline(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,2,annotation_shade())
		draw_string(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,ink)
	func _draw()->void:
		var font:=T.font("ui");var strong:=T.font("ui_strong")
		for index in readings.size():
			var reading:Dictionary=readings[index];var y:=index*68.0
			var before:=float(reading.before);var after:=float(reading.after);var need:=float(reading.get("need",0))
			var scale:=maxf(1,maxf(maxf(before,after),need))*1.05
			var ink:=annotation_ink();var draft_ink:=annotation_accent()
			_say(strong,Vector2(0,y+15),String(reading.label),14,ink)
			var words:=String(reading.get("words","%.1f → %.1f %s" % [before,after,reading.unit] if comparing else "%.1f %s" % [after,reading.unit]))
			_say(font,Vector2(0,y+35),words,16,ink)
			var line_width:=size.x-(105 if reading.has("current_caption") else 70)
			if comparing:
				draw_line(Vector2(0,y+46),Vector2(line_width*before/scale,y+46),Color(ink,.65),3,true)
				_say(font,Vector2(line_width+6,y+50),"Current "+String(reading.get("current_caption","")),11,ink)
			draw_line(Vector2(0,y+58),Vector2(line_width*after/scale,y+58),draft_ink if comparing else ink,3,true)
			_say(font,Vector2(line_width+6,y+62),("Draft "+String(reading.get("draft_caption",""))) if comparing else "Current",11,draft_ink if comparing else ink)
			if need>0:
				var x:=line_width*need/scale;draw_line(Vector2(x,y+42),Vector2(x,y+64),ink,1.5)
				_say(font,Vector2(0,y+82),"Daily need %.1f %s"%[need,String(reading.unit)],12,ink)

class FoodCrossGraphic extends WorkEffectGraphic:
	var current:Dictionary={}
	var proposed:Dictionary={}
	func _init()->void:
		custom_minimum_size=Vector2(0,96);mouse_filter=Control.MOUSE_FILTER_PASS
	func show_food(result:Dictionary,changed:bool)->void:
		current=result.get("before",{}).get("food",{});proposed=result.get("after",{}).get("food",{});comparing=changed;queue_redraw()
	func _reading(key:String,signed:=false)->String:
		var old:=float(current.get(key,0));var next:=float(proposed.get(key,0))
		var format:="%+.1f" if signed else "%.1f"
		return (format%old)+" → "+(format%next) if comparing and not is_equal_approx(roundf(old*10),roundf(next*10)) else format%next
	func _draw()->void:
		if proposed.is_empty():return
		var font:=T.font("ui");var strong:=T.font("ui_strong");var ink:=annotation_ink()
		var flow_width:=size.x*.59;var col:=flow_width/3.0
		_say(strong,Vector2(0,14),"Food · rations each day",13,ink)
		var captions:=["Produced","Needed","Store change"]
		for i in 3:
			var key:=String(["production","required","net"][i]);var x:=col*i
			_say(font,Vector2(x,36),captions[i],12,ink)
			_say(strong,Vector2(x,58),_reading(key,i==2),16,annotation_accent() if i==2 and float(proposed.get("net",0))<0 else ink)
			if i<2:_say(font,Vector2(x+col-20,53),"→",16,ink)
		_say(font,Vector2(0,83),"%s rations held now · net includes spoilage"%preload("res://scripts/hud/era_words.gd").grouped(roundi(float(proposed.get("stock",0)))),12,ink)
		var x:=flow_width+16;var chart_width:=maxf(80,size.x-x-110)
		_say(strong,Vector2(x,14),"Rations after 90 days",13,ink)
		var values:Array=[];var maximum:=1.0
		for day in [0,30,90]:
			var old:=float(current.get("stock",0)) if day==0 else float(current.get("forecast%d"%day,{}).get("ending_rations",0))
			var next:=float(proposed.get("stock",0)) if day==0 else float(proposed.get("forecast%d"%day,{}).get("ending_rations",0))
			values.append(Vector2(old,next));maximum=maxf(maximum,maxf(old,next))
		for draft_line:bool in ([false,true] if comparing else [true]):
			var points:=PackedVector2Array()
			for i in 3:points.append(Vector2(x+chart_width*[0.0,1.0/3,1.0][i],72-(values[i].y if draft_line else values[i].x)/maximum*42))
			var color:=annotation_accent() if comparing and draft_line else ink
			draw_polyline(points,Color(annotation_shade(),.7),4,true);draw_polyline(points,color,2,true)
			var ending:float=values[2].y if draft_line else values[2].x
			_say(font,Vector2(x+chart_width+8,58 if draft_line else 38),("Draft " if comparing and draft_line else "Current ")+"%.0f"%ending,12,color)
		_say(font,Vector2(x,87),"0",11,ink);_say(font,Vector2(x+chart_width-16,87),"90d",11,ink)
