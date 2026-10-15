extends "res://scripts/hud/people_screen.gd"
## Painted town portrait. Each allocation step goes through a fresh
## snapshot and the existing guarded ManualWork commit. Person/city actions are inherited.
const WorkImpacts=preload("res://scripts/hud/people_work_impacts.gd")
const WorkforceCast=preload("res://scripts/hud/people_workforce_cast.gd")
const ROLE_NAMES:={"Food":"Food grounds","Survey":"Surveying","Extraction":"Wood & stone","Construction":"Building","Crafting":"Making","Logistics":"Water & carrying","Knowledge":"Learning","Administration":"Keeping & caring","Defense":"The watch"}
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
var navigation_surface:PanelContainer
var _shown_counts:Dictionary={}
var _shown_percentages:Dictionary={}
var _current_percentages:Dictionary={}
var _showing_preview:=false
var _committing:=false
var _comparison:=false
var _awaiting_commit_refresh:=false
var _refresh_pending:=false
var _last_change:=""
var _command_error:=""
var food_back:PanelContainer
var allocation_bar:AllocationBar
var _effect_slots:=0
var _last_effect_ms:=-3000
var _effects_outdated:=false
var sidebar:PanelContainer
var sidebar_content:Control
var overview_panel:VBoxContainer
var portrait_caption:Label

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
	figure_legend=_annotation_label("",12);figure_legend.visible=false;heading.add_child(figure_legend)
	var command:=heading
	mode_note=_annotation_label("",12);mode_note.custom_minimum_size.x=88;mode_note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;command.add_child(mode_note)
	overview_button=_annotation_button(command,"Whole town",_return_overview);overview_button.disabled=true
	leaders_button=_annotation_button(command,"Let our leaders assign",_delegate);leaders_button.visible=false
	pause_button=_annotation_button(command,"Pause world",_pause_to_plan);pause_button.name="PauseToPlan";pause_button.tooltip_text="Pause the world here; resume with the clock when ready.";pause_button.visible=false
	allocation_bar=AllocationBar.new();allocation_bar.custom_minimum_size.y=12;add_child(allocation_bar)
	pending_note=_annotation_label("",12);pending_note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;command.add_child(pending_note)
	stage=Control.new();stage.name="PeoplePortraitAndAssignments";stage.custom_minimum_size.y=560;stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stage.clip_contents=true;add_child(stage)
	settlement_view=_make_settlement_view();settlement_view.name="PeopleTownPortraitView";stage.add_child(settlement_view);settlement_view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	settlement_view.connect("role_anchors_changed",_anchors_changed)
	if settlement_view.has_signal("role_selected"):settlement_view.connect("role_selected",focus_work)
	overlay=Control.new();overlay.name="WorkAreaReadings";overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage.add_child(overlay);overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	portrait_caption=Label.new();portrait_caption.name="PortraitPopulation";portrait_caption.add_theme_font_size_override("font_size",12);portrait_caption.add_theme_color_override("font_color",T.MUTED);stage.add_child(portrait_caption)
	connections=AreaConnections.new();overlay.add_child(connections);connections.visible=false
	var short_names:={"Food":"Food","Survey":"Survey","Extraction":"Wood & stone","Construction":"Building","Crafting":"Making","Logistics":"Carrying","Knowledge":"Learning","Administration":"Care","Defense":"Watch"}
	for role:String in ROLE_NAMES:
		var pill:=Button.new();pill.name="WorkArea_"+role;pill.text=String(short_names[role]);pill.custom_minimum_size.y=28
		pill.add_theme_font_size_override("font_size",12);pill.add_theme_font_override("font",T.font("ui_strong"))
		pill.add_theme_color_override("font_color",annotation_ink());pill.add_theme_color_override("font_hover_color",annotation_ink());pill.add_theme_color_override("font_pressed_color",annotation_ink())
		var style:=_reading_surface();style.set_content_margin_all(6);style.set_corner_radius_all(12);pill.add_theme_stylebox_override("normal",style)
		var hover:=style.duplicate();hover.bg_color=Color("29414af5");pill.add_theme_stylebox_override("hover",hover);pill.add_theme_stylebox_override("pressed",hover)
		pill.pressed.connect(focus_work.bind(role));overlay.add_child(pill)
		# The number label is an accessible full-headcount reading; the picture
		# pill stays short and the selected sidebar carries the full numbers.
		var number:=Label.new();number.visible=false;pill.add_child(number)
		markers[role]={"node":pill,"number":number,"button":pill,"short":short_names[role]}
	sidebar=PanelContainer.new();sidebar.name="WorkAssignmentSidebar";sidebar.add_theme_stylebox_override("panel",_reading_surface());stage.add_child(sidebar)
	sidebar_content=Control.new();sidebar.add_child(sidebar_content)
	overview_panel=VBoxContainer.new();overview_panel.name="ChooseTownWork";overview_panel.add_theme_constant_override("separation",12);sidebar_content.add_child(overview_panel)
	var title:=_annotation_label("Work around the town",20);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;overview_panel.add_child(title)
	var guidance:=_annotation_label("Choose a work area in the portrait to see its people and change their assignment.",14);guidance.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;overview_panel.add_child(guidance)
	var scope:=_annotation_label("Assignments cover all our settlements. Each + or − changes the allocation immediately.",13);scope.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;overview_panel.add_child(scope)
	_build_focus()
	# The workforce total stays on the quiet HUD surface, outside the artwork.
	for child:Node in heading.get_children():
		if child is Button:
			T.apply_button_style(child,false);child.add_theme_constant_override("outline_size",0)
		if child is Label:
			child.add_theme_color_override("font_color",T.INK)
			child.add_theme_constant_override("outline_size",0)
			child.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	scope_note.add_theme_font_size_override("font_size",22)
	scope_note.add_theme_font_override("font",T.font("ui_strong"))
	scene_title.visible=false;pending_note.visible=false
	navigation_surface=PanelContainer.new();var nav_style:=_reading_surface();nav_style.set_content_margin_all(6);navigation_surface.add_theme_stylebox_override("panel",nav_style);overlay.add_child(navigation_surface)
	navigation=VBoxContainer.new();navigation.name="VillageNavigation";navigation.add_theme_constant_override("separation",0);navigation_surface.add_child(navigation)
	var camera_buttons:=HBoxContainer.new();camera_buttons.add_theme_constant_override("separation",8);navigation.add_child(camera_buttons)
	var zoom_out:=_annotation_button(camera_buttons,"−",func():settlement_view.call("zoom_view",1.0/.88));zoom_out.name="VillageZoomOut";zoom_out.custom_minimum_size.x=36;zoom_out.tooltip_text="Zoom out"
	var zoom_in:=_annotation_button(camera_buttons,"+",func():settlement_view.call("zoom_view",.88));zoom_in.name="VillageZoomIn";zoom_in.custom_minimum_size.x=36;zoom_in.tooltip_text="Zoom in"
	var recenter:=_annotation_button(camera_buttons,"Center view",func():settlement_view.call("reset_navigation"));recenter.name="VillageRecenter";recenter.tooltip_text="Return to the selected work area, or the workforce overview. Home also centers the view."
	var help:=_annotation_label("Drag to move · scroll to zoom",11);help.mouse_filter=Control.MOUSE_FILTER_IGNORE;navigation.add_child(help)
	stage.resized.connect(_fit_scene)

func _make_settlement_view()->Control:
	return load("res://scripts/hud/people_town_portrait_view.gd").new()

static func annotation_ink()->Color:
	return Color("f4eee0")
static func annotation_shade()->Color:
	return Color("14232b")

func _annotation_label(words:String,pixels:int=14)->Label:
	var label:=T.make_label(words,pixels,annotation_ink())
	label.add_theme_color_override("font_shadow_color",Color.TRANSPARENT);label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1)
	label.add_theme_color_override("font_outline_color",Color(annotation_shade(),0.65));label.add_theme_constant_override("outline_size",0)
	return label

func _annotation_button(parent:Node,words:String,callback:Callable,primary:=false)->Button:
	var button:=_scene_button(parent,words,callback,primary)
	button.custom_minimum_size.y=36
	button.add_theme_font_size_override("font_size",14)
	if not primary:
		var normal:=T.flat(Color.TRANSPARENT,T.ACTION,0,0,3);normal.border_width_bottom=1;normal.border_color=T.ACTION
		button.add_theme_stylebox_override("normal",normal)
		button.add_theme_stylebox_override("hover",T.flat(Color(annotation_shade(),.35),T.ACTION,1,2,3))
		button.add_theme_stylebox_override("pressed",T.flat(Color(annotation_shade(),.55),T.ACTION,1,2,3))
		button.add_theme_color_override("font_color",annotation_ink());button.add_theme_color_override("font_hover_color",annotation_ink())
		button.add_theme_color_override("font_focus_color",annotation_ink());button.add_theme_color_override("font_pressed_color",annotation_ink());button.add_theme_color_override("font_disabled_color",Color(annotation_ink(),.5))
		button.add_theme_color_override("font_outline_color",annotation_shade());button.add_theme_constant_override("outline_size",0)
	return button

func _scene_button(parent:Node,words:String,callback:Callable,primary:=false)->Button:
	var button:=Button.new();button.text=words;T.apply_button_style(button,primary);button.pressed.connect(callback);parent.add_child(button);return button

func _build_focus()->void:
	focus_panel=PanelContainer.new();focus_panel.name="WorkDraft";focus_panel.visible=false;focus_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new());sidebar_content.add_child(focus_panel)
	focus_body=VBoxContainer.new();focus_body.add_theme_constant_override("separation",4);focus_panel.add_child(focus_body)
	var identity:=HBoxContainer.new();identity.add_theme_constant_override("separation",10);focus_body.add_child(identity)
	focus_title=_annotation_label("",18);focus_title.add_theme_font_override("font",T.font("ui_strong"));identity.add_child(focus_title)
	source_reading=_annotation_label("",12);source_reading.visible=false;focus_body.add_child(source_reading)
	focus_purpose=_annotation_label("");focus_purpose.visible=false;focus_body.add_child(focus_purpose)
	people_reading=_annotation_label("",22);people_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_body.add_child(people_reading)
	var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",8);focus_body.add_child(controls)
	decrease_button=_annotation_button(controls,"−1%",_step.bind(-1));decrease_button.name="DraftLess";decrease_button.custom_minimum_size.x=64
	increase_button=_annotation_button(controls,"+1%",_step.bind(1));increase_button.name="DraftMore";increase_button.custom_minimum_size.x=64
	five_button=_annotation_button(controls,"+5%",_step.bind(5));five_button.name="DraftFive";five_button.custom_minimum_size.x=64
	var step_note:=_annotation_label("1% of workforce",12);step_note.tooltip_text="Each click takes control of work and applies now. Whole-worker rounding and local food protection can change the number moved.";step_note.visible=false;controls.add_child(step_note)
	for step_button:Button in [decrease_button,increase_button,five_button]:step_button.tooltip_text=step_note.tooltip_text
	transfer_reading=_annotation_label("");transfer_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_body.add_child(transfer_reading)
	risk_reading=_annotation_label("");risk_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;risk_reading.add_theme_color_override("font_color",annotation_ink().lerp(T.ACTION,.45));focus_body.add_child(risk_reading)
	var commands:=HFlowContainer.new();commands.add_theme_constant_override("h_separation",10);commands.add_theme_constant_override("v_separation",4);focus_body.add_child(commands)
	# No staged Apply/Cancel flow: these controls change work immediately.
	commands.visible=false
	focus_actions=focus_body
	evidence_panel=PanelContainer.new();evidence_panel.name="WorkConsequences";evidence_panel.visible=false;evidence_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new());sidebar_content.add_child(evidence_panel)
	focus_evidence=VBoxContainer.new();focus_evidence.add_theme_constant_override("separation",3);evidence_panel.add_child(focus_evidence)
	effect_graph=WorkEffectGraphic.new();effect_graph.name="LikelyWorkEffects";focus_evidence.add_child(effect_graph)
	forecast_reading=_annotation_label("");forecast_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_evidence.add_child(forecast_reading)
	food_back=PanelContainer.new();food_back.name="FoodReadingsSurface";food_back.add_theme_stylebox_override("panel",StyleBoxEmpty.new());sidebar_content.add_child(food_back)
	food_strip=VBoxContainer.new();food_strip.name="FoodCrossEffect";food_strip.add_theme_constant_override("separation",3);food_back.add_child(food_strip)
	food_graph=PortraitFoodGraphic.new();food_graph.name="FoodCrossEffectDiagram";food_strip.add_child(food_graph)
	risk_reading.reparent(food_strip)
	for label:Label in [transfer_reading,risk_reading]:
		label.add_theme_font_size_override("font_size",13);label.custom_minimum_size.y=32;label.max_lines_visible=2;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	forecast_reading.add_theme_font_size_override("font_size",13);forecast_reading.custom_minimum_size.y=38;forecast_reading.max_lines_visible=3;forecast_reading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	people_reading.custom_minimum_size.y=28

func _reading_surface()->StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=Color("14232bf2");box.set_corner_radius_all(4);box.set_content_margin_all(12)
	return box

func _fill_scene(scene:Dictionary)->void:
	if settlement_view==null:return
	var context:Dictionary=data.get("settlement_view",{}).duplicate()
	context.allocations={}
	for task:Dictionary in data.get("labor",{}).get("tasks",[]):context.allocations[String(task.id)]=int(task.count)
	if not _configured:settlement_view.call("configure",context);_configured=true
	else:settlement_view.call("update_state",context)
	var portrait_info:Dictionary=settlement_view.call("portrait_stage") if settlement_view.has_method("portrait_stage") else {}
	portrait_caption.text="%s · %s people" % [String(portrait_info.get("title","Our community")),preload("res://scripts/hud/era_words.gd").grouped(int(context.get("population",0)))]
	portrait_caption.tooltip_text="An illustrative town portrait scaled to our total population. Work assignments cover the whole civilization."
	scene_title.text="Our workforce"
	var assigned:=0
	for count:int in _current_counts().values():assigned+=count
	scope_note.text="%s assigned" % preload("res://scripts/hud/era_words.gd").grouped(assigned)
	scope_note.tooltip_text="Everyone assigned across our settlements, including the watch and serving soldiers. The top-bar At work total excludes military service."
	scene_title.tooltip_text="A painted town portrait showing work categories; assignments cover all our settlements."
	figure_legend.tooltip_text=""
	_sync_workforce()
	_fit_scene.call_deferred()

## Parent's nine-row labor UI is intentionally replaced, not duplicated.
func _rebuild_labor()->void:
	if stage==null:return
	var labor:Dictionary=data.get("labor",{})
	mode_note.text="You assign" if bool(labor.get("manual",false)) else "Leaders assign"
	mode_note.tooltip_text="\n".join(PackedStringArray(labor.get("who",[])))+"\n"+String(labor.get("leaders_tip",""))
	leaders_button.tooltip_text=String(labor.get("leaders_tip",""))
	leaders_button.visible=true;leaders_button.disabled=not bool(labor.get("manual",false))
	pause_button.visible=true;pause_button.disabled=not bool(data.get("world_running",false))
	if _awaiting_commit_refresh and _current_counts()==forecast.get("after",{}).get("counts",{}):
		_awaiting_commit_refresh=false;_draft_revision=data.get("workforce_revision",[]).duplicate(true)
	elif not _committing and _draft_revision!=data.get("workforce_revision",[]):
		_comparison=false
		_effects_outdated=true
		if not _refresh_pending and Time.get_ticks_msec()-_last_effect_ms>=2500:_refresh_pending=true;_refresh_current.call_deferred(false)
	_refresh_focus()

func _current_counts()->Dictionary:
	var counts:={}
	for role:String in ROLE_NAMES:counts[role]=0
	for task:Dictionary in data.get("labor",{}).get("tasks",[]):
		if counts.has(String(task.id)):counts[String(task.id)]=maxi(0,int(task.count))
	return counts

func _sync_workforce()->void:
	if settlement_view==null:return
	_shown_counts=_current_counts();_current_percentages=WorkforceCast.apportion(_shown_counts)
	_shown_percentages=_current_percentages.duplicate();_showing_preview=false
	allocation_bar.percentages=_shown_percentages;allocation_bar.selected=active_role;allocation_bar.queue_redraw()
	if settlement_view.has_method("set_workforce"):settlement_view.call("set_workforce",_shown_counts,false)
	for role:String in markers:
		var count:=int(_shown_counts.get(role,0));var percent:=int(_shown_percentages.get(role,0))
		(markers[role].number as Label).text="%d%% · %s workers"%[percent,preload("res://scripts/hud/era_words.gd").grouped(count)]
		(markers[role].button as Button).text="%s %d%%"%[markers[role].short,percent]
		(markers[role].node as Control).tooltip_text="%d%% · %d assigned workers\n%s"%[percent,count,ROLE_PURPOSE[role]]
	figure_legend.text=""

func _api(method:String,arguments:Array=[])->Variant:
	var callback:Variant=(data.get("workforce",{}) as Dictionary).get(method)
	if callback is Callable and (callback as Callable).is_valid():return (callback as Callable).callv(arguments)
	return null

## Root's category shortcuts call this after opening Home → People.
func focus_work(role:String)->void:
	if not ROLE_NAMES.has(role):return
	var changed:=active_role!=role
	active_role=role
	if changed:
		_comparison=false;_last_change="";_command_error="";_effect_slots=0
		settlement_view.call("focus_role",role)
		_refresh_current()
	else:_refresh_focus()
	_focus_assignment.call_deferred()

func _refresh_current(force:=true)->void:
	if not force and not _refresh_pending:return
	_refresh_pending=false
	if _committing:return
	_last_effect_ms=Time.get_ticks_msec();_effects_outdated=false
	var captured:Variant=_api("capture")
	if captured is Dictionary and bool(captured.get("ok",false)):
		draft=captured;_draft_revision=data.get("workforce_revision",[]).duplicate(true)
		_evaluate()
		if bool(forecast.get("ok",false)):_command_error=""
	else:forecast={};_command_error=String(captured.get("reason","Current work is not available.") if captured is Dictionary else "Current work is not available.")
	_comparison=false;_refresh_focus()

func _focus_assignment()->void:
	# Opening an area hides its Assign button. Carry keyboard focus into the
	# visible controls, without disturbing a reader already working in them.
	if active_role=="" or get_viewport().gui_get_focus_owner()!=null:return
	for button:Button in [decrease_button,increase_button,overview_button]:
		if button.is_visible_in_tree() and not button.disabled:button.grab_focus();return

func _step(points:int)->void:
	if _committing or active_role=="" or points==0:return
	_committing=true;_command_error="";_effects_outdated=false;_last_effect_ms=Time.get_ticks_msec()
	# A new snapshot makes rapid clicks and running-world changes independent
	# commands. The provider still checks its exact token before mutating work.
	var fresh:Variant=_api("capture")
	if not fresh is Dictionary or not bool(fresh.get("ok",false)):
		_command_error=String(fresh.get("reason","Wait for the current day to finish.") if fresh is Dictionary else "Work is not available.")
		_committing=false;_refresh_focus();return
	var next:Variant=_api("step",[fresh,active_role,points])
	if not next is Dictionary or not bool(next.get("has_changes",not (next.get("commands",[]) as Array).is_empty())):
		_command_error="No further workers can move in that direction."
		_committing=false;_refresh_focus();return
	var prior_forecast:=forecast
	draft=next;_draft_revision=data.get("workforce_revision",[]).duplicate(true)
	_evaluate()
	if not bool(forecast.get("ok",false)) or draft_stale:
		_command_error=String(forecast.get("reason","Conditions changed. Click again to use the current allocation."))
		draft=fresh;forecast=prior_forecast;draft_stale=false;_comparison=false
		_committing=false;_refresh_focus();return
	var result:Variant=_api("commit",[draft,true])
	if result is Dictionary and bool(result.get("ok",false)):
		var counts:Dictionary=result.get("counts",forecast.get("after",{}).get("counts",{}))
		forecast.after.counts=counts.duplicate(true)
		data=data.duplicate(true)
		for task:Dictionary in data.get("labor",{}).get("tasks",[]):task.count=int(counts.get(String(task.id),0))
		data.labor.manual=true
		_comparison=true;_awaiting_commit_refresh=true
		var before_count:=int(forecast.get("before",{}).get("counts",{}).get(active_role,0));var after_count:=int(counts.get(active_role,0))
		var current:int=WorkforceCast.apportion(counts).get(active_role,0)
		_last_change="%d → %d workers · %d%% assigned here"%[before_count,after_count,current] if before_count!=after_count else "Share updated; rounding or food protection kept %d workers here."%after_count
		mode_note.text="You assign";leaders_button.disabled=false
	else:
		_command_error=String(result.get("reason","Conditions changed. Click again to use the current allocation.") if result is Dictionary else "This assignment could not be applied.")
		draft=fresh;forecast=prior_forecast;draft_stale=false;_comparison=false
	_committing=false
	_refresh_focus()

func _evaluate()->void:
	var result:Variant=_api("evaluate",[draft])
	forecast=result if result is Dictionary else {}
	draft_stale=bool(forecast.get("stale",false))

func _refresh_focus()->void:
	if focus_panel==null:return
	_sync_workforce()
	var focused:=active_role!=""
	focus_panel.visible=focused;evidence_panel.visible=focused;overview_button.visible=true;overview_button.disabled=not focused;overview_panel.visible=not focused;food_back.visible=true
	for role:String in markers:(markers[role].node as Control).visible=not focused
	pending_note.text=""
	var warnings:=_warning_words()
	risk_reading.text=_command_error if _command_error!="" else (warnings[0] if not warnings.is_empty() else "")
	risk_reading.tooltip_text=_command_error if _command_error!="" else "\n".join(warnings);risk_reading.visible=true
	_update_food_strip(_comparison)
	if not focused:_fit_scene.call_deferred();return
	focus_title.text=String(ROLE_NAMES.get(active_role,active_role))
	focus_title.tooltip_text=String(ROLE_PURPOSE.get(active_role,""))
	source_reading.text="Effects: previous update" if _effects_outdated else ""
	var now:=int(_current_counts().get(active_role,0))
	people_reading.text="%s workers · %d%%"%[preload("res://scripts/hud/era_words.gd").grouped(now),int(_current_percentages.get(active_role,0))]
	transfer_reading.text=_last_change if _comparison else ("Effects: previous update" if _effects_outdated else ("Changes apply immediately." if bool(data.get("labor",{}).get("manual",false)) else "Click to take control & assign."))
	transfer_reading.tooltip_text=transfer_reading.text;transfer_reading.visible=true
	effect_graph.show_forecast(forecast,active_role,String(data.get("settlement_view",{}).get("settlement_id","")),_comparison)
	if _effect_slots==0:_effect_slots=clampi(effect_graph.readings.size(),1,3)
	effect_graph.custom_minimum_size.y=132
	var notes:PackedStringArray=[]
	for reading:Dictionary in effect_graph.readings:
		var note:=String(reading.get("note",""))
		if note!="" and not notes.has(note):notes.append(note)
	forecast_reading.text=WorkImpacts.summary(active_role);forecast_reading.tooltip_text=("Estimate from the previous update.\n" if _effects_outdated else "")+"\n".join(notes);forecast_reading.visible=true
	var normalized:Dictionary=preload("res://scripts/manual_work.gd").percents(draft.get("shares",{})) if not draft.is_empty() else _current_percentages
	decrease_button.disabled=_committing or int(normalized.get(active_role,0))<=0
	increase_button.disabled=_committing or int(normalized.get(active_role,0))>=100;five_button.disabled=increase_button.disabled
	_fit_scene.call_deferred()

func _warning_words()->PackedStringArray:
	var all:Array=(forecast.get("warnings",[]) as Array).duplicate()
	var priority:={"starvation":0,"food_shortage":1,"water":2,"safeguard":3}
	all.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(priority.get(String(a.get("kind","")),4))<int(priority.get(String(b.get("kind","")),4)))
	var complete:PackedStringArray=[]
	for warning:Dictionary in all:complete.append(String(warning.get("text","")).replace("currently puts extra hands on food","keeps extra hands on food"))
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
		"safeguard":return "Town leaders keep extra workers on food."
	return String(warning.get("text",""))

func _update_food_strip(changed:bool)->void:
	food_back.visible=bool(forecast.get("ok",false))
	food_graph.show_food(forecast,changed)
	food_graph.tooltip_text="90-day outlook at current conditions, including known seasonal food changes."

func _delegate()->void:
	draft={};forecast={};draft_stale=false;preview_rebased=false;_comparison=false;_last_change=""
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
	var width:=maxf(560,stage.size.x)
	var top:=stage.global_position.y;var ancestor:Node=stage.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:top+=float((ancestor as ScrollContainer).scroll_vertical);break
		ancestor=ancestor.get_parent()
	stage.custom_minimum_size.y=clampf(get_viewport_rect().size.y-top-18,470,1120)
	var side_width:=300.0 if width<1100 else 340.0
	var portrait_width:=minf(width-side_width-16,(stage.size.y-24)*1.5)
	var composition_x:=maxf(0,(width-portrait_width-side_width-16)*.5)
	settlement_view.position=Vector2(composition_x,0);settlement_view.size=Vector2(portrait_width,stage.size.y-24)
	portrait_caption.position=Vector2(composition_x,stage.size.y-20);portrait_caption.size=Vector2(portrait_width,20)
	overlay.position=settlement_view.position;overlay.size=settlement_view.size
	sidebar.position=Vector2(composition_x+portrait_width+16,0);sidebar.size=Vector2(side_width,stage.size.y)
	var inner_width:=side_width-24;var inner_height:=stage.size.y-24
	scene_toolbar.size.x=width
	overview_panel.position=Vector2.ZERO;overview_panel.size.x=inner_width
	focus_panel.position=Vector2.ZERO;focus_panel.custom_minimum_size=Vector2(inner_width,132);focus_panel.size=Vector2(inner_width,132)
	evidence_panel.position=Vector2(0,144);evidence_panel.custom_minimum_size=Vector2(inner_width,176);evidence_panel.size=Vector2(inner_width,176)
	food_back.position=Vector2(0,maxf(326,inner_height-120));food_back.custom_minimum_size=Vector2(inner_width,120);food_back.size=Vector2(inner_width,120)
	var nav_size:=navigation_surface.get_combined_minimum_size();navigation_surface.size=nav_size
	navigation_surface.position=Vector2(maxf(4,portrait_width-nav_size.x-8),8)
	for role:String in markers:
		var marker:Control=markers[role].node;marker.size=marker.get_combined_minimum_size()
		var anchor:Vector2=anchors.get(role,Vector2(-1000,-1000))
		marker.visible=active_role=="" and Rect2(Vector2.ZERO,settlement_view.size).has_point(anchor)
		marker.position=Vector2(clampf(anchor.x-marker.size.x*.5,4,maxf(4,portrait_width-marker.size.x-4)),clampf(anchor.y-marker.size.y*.5,4,maxf(4,stage.size.y-marker.size.y-4)))

func view_state()->Dictionary:
	var saved:=super.view_state();saved.focus_work=active_role
	if settlement_view.has_method("navigation_state"):saved.work_navigation=settlement_view.call("navigation_state")
	return saved

func restore_view_state(saved:Dictionary)->void:
	super.restore_view_state(saved)
	var role:=String(saved.get("focus_work",""))
	# Same-widget live refresh must not reset camera or reposition controls.
	if role==active_role:return
	if ROLE_NAMES.has(role):
		focus_work(role)
		if saved.has("work_navigation") and settlement_view.has_method("restore_navigation_state"):settlement_view.call("restore_navigation_state",saved.work_navigation)
	else:_refresh_focus()

func handle_escape()->bool:
	if active_role!="":_return_overview();return true
	return false

class AllocationBar extends Control:
	var percentages:Dictionary={}
	var selected:=""
	func _init()->void:
		mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var at:=0.0;var details:PackedStringArray=[]
		for index in ROLE_NAMES.size():
			var role:String=ROLE_NAMES.keys()[index];var amount:=int(percentages.get(role,0))
			var width:=size.x*amount/100.0
			var tint:=Color.from_hsv(fmod(.09+index*.083,1),.25,.70)
			var rectangle:=Rect2(Vector2(at,0),Vector2(maxf(0,width-1),size.y))
			draw_rect(rectangle,tint)
			if selected==role:draw_rect(rectangle,T.ACTION,false,2)
			at+=width;details.append("%s: %d%%"%[ROLE_NAMES[role],amount])
		tooltip_text="Workforce allocation · 100%\n"+"\n".join(details)

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
		return Color("f4eee0")
	static func annotation_shade()->Color:
		return Color("14232b")
	static func annotation_accent()->Color:
		# The scene stays dark green in either appearance; Daylight's brick
		# button fill needs lighter ink when it becomes a thin plot or caption.
		return T.ACTION.lerp(annotation_ink(),.45) if T.INK.get_luminance()<T.PANEL_BG.get_luminance() else T.ACTION
	var readings:Array=[]
	var comparing:=false
	func _init()->void:
		custom_minimum_size=Vector2(260,72);mouse_filter=Control.MOUSE_FILTER_PASS
	func show_forecast(result:Dictionary,role:String,settlement_id:String="",has_changes:=false)->void:
		readings=WorkImpacts.readings(result,role,settlement_id,has_changes);comparing=has_changes
		custom_minimum_size.y=132;visible=true;queue_redraw()
	func _say(font:Font,at:Vector2,words:String,pixels:int,ink:Color)->void:
		draw_string(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,ink)
	func _draw()->void:
		var font:=T.font("ui");var strong:=T.font("ui_strong")
		for index in readings.size():
			var reading:Dictionary=readings[index];var y:=index*44.0
			var before:=float(reading.before);var after:=float(reading.after);var need:=float(reading.get("need",0))
			var changed:=comparing and not is_equal_approx(before,after)
			var scale:=maxf(1,maxf(maxf(before,after),need))*1.05
			var ink:=annotation_ink();var draft_ink:=annotation_accent()
			_say(strong,Vector2(0,y+15),String(reading.label),12 if String(reading.label).length()>34 else 14,ink)
			var words:=String(reading.get("words","%.1f → %.1f %s" % [before,after,reading.unit] if comparing else "%.1f %s" % [after,reading.unit]))
			_say(font,Vector2(0,y+29),words,16,ink)
			if not changed and need<=0:continue
			var line_width:=size.x-(105 if reading.has("current_caption") else 70)
			if changed:
				_say(font,Vector2(line_width+6,y+34),"Before",10,Color(ink,.65))
				_say(font,Vector2(line_width+6,y+44),"Now",10,draft_ink)
				draw_line(Vector2(0,y+34),Vector2(line_width*before/scale,y+34),Color(ink,.65),3,true)
			draw_line(Vector2(0,y+40),Vector2(line_width*after/scale,y+40),draft_ink if changed else ink,3,true)
			if need>0:
				var x:=line_width*need/scale;draw_line(Vector2(x,y+35),Vector2(x,y+42),ink,1.5)
				_say(font,Vector2(line_width+6,y+14),"%s %.0f%s"%[String(reading.get("need_label","Need")),need,"%" if String(reading.unit)=="%" else ""],10,ink)

class FoodCrossGraphic extends WorkEffectGraphic:
	var current:Dictionary={}
	var proposed:Dictionary={}
	func _init()->void:
		custom_minimum_size=Vector2(0,70);mouse_filter=Control.MOUSE_FILTER_PASS
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
			_say(font,Vector2(x,30),captions[i],12,ink)
			_say(strong,Vector2(x,48),_reading(key,i==2),16,annotation_accent() if i==2 and float(proposed.get("net",0))<0 else ink)
			if i<2:_say(font,Vector2(x+col-20,46),"→",16,ink)
		_say(font,Vector2(0,68),"%s rations held now · net includes spoilage"%preload("res://scripts/hud/era_words.gd").grouped(roundi(float(proposed.get("stock",0)))),12,ink)
		var x:=flow_width+16;var chart_width:=maxf(80,size.x-x-110)
		_say(strong,Vector2(x,14),"Rations after 90 days",13,ink)
		var values:Array=[];var maximum:=1.0
		for day in [0,30,90]:
			var old:=float(current.get("stock",0)) if day==0 else float(current.get("forecast%d"%day,{}).get("ending_rations",0))
			var next:=float(proposed.get("stock",0)) if day==0 else float(proposed.get("forecast%d"%day,{}).get("ending_rations",0))
			values.append(Vector2(old,next));maximum=maxf(maximum,maxf(old,next))
		for draft_line:bool in ([false,true] if comparing else [true]):
			var points:=PackedVector2Array()
			for i in 3:points.append(Vector2(x+chart_width*[0.0,1.0/3,1.0][i],55-(values[i].y if draft_line else values[i].x)/maximum*28))
			var color:=annotation_accent() if comparing and draft_line else ink
			draw_polyline(points,Color(annotation_shade(),.7),4,true);draw_polyline(points,color,2,true)
			var ending:float=values[2].y if draft_line else values[2].x
			_say(font,Vector2(x+chart_width+8,48 if draft_line else 30),("Now " if draft_line else "Before ")+"%.0f"%ending,12,color)
		_say(font,Vector2(x,68),"0",11,ink);_say(font,Vector2(x+chart_width-16,68),"90d",11,ink)

class PortraitFoodGraphic extends FoodCrossGraphic:
	func _init()->void:custom_minimum_size=Vector2(0,82);mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		if proposed.is_empty():return
		var font:=T.font("ui");var strong:=T.font("ui_strong");var ink:=annotation_ink()
		_say(strong,Vector2(0,14),"Food each day",14,ink)
		_say(font,Vector2(0,34),"In %.1f · need %.1f"%[float(proposed.get("production",0)),float(proposed.get("required",0))],14,ink)
		var net:=float(proposed.get("net",0))
		_say(strong,Vector2(0,54),"Stores %+.1f rations/day"%net,15,annotation_accent() if net<0 else ink)
		_say(font,Vector2(0,76),"%s held · 90d estimate %s"%[preload("res://scripts/hud/era_words.gd").grouped(roundi(float(proposed.get("stock",0)))),preload("res://scripts/hud/era_words.gd").grouped(roundi(float(proposed.get("forecast90",{}).get("ending_rations",0))))],12,ink)
