extends "res://scripts/hud/people_screen.gd"
## Living settlement/work view. Drafts are read-only until the provider's guarded
## commit calls the original ManualWork commands. Person/city actions are inherited.
const ROLE_NAMES:={"Food":"Food grounds","Survey":"Surveying","Extraction":"Wood & stone","Construction":"Building","Crafting":"Workshops","Logistics":"Water & carrying","Knowledge":"Learning","Administration":"Keeping & caring","Defense":"The watch"}
const ROLE_PURPOSE:={"Food":"Gather, hunt, fish and grow food.","Survey":"Find resources in the nearby land.","Extraction":"Bring timber, stone and ore out of the land.","Construction":"Raise homes and works; repair what stands.","Crafting":"Make tools, equipment and everyday goods.","Logistics":"Carry supplies and bring drinking water home.","Knowledge":"Learn, teach and pursue current studies.","Administration":"Keep, distribute and care for the people.","Defense":"Keep watch and prepare our defenders."}

var settlement_view:Control
var stage:Control
var overlay:Control
var scene_title:Label
var scope_note:Label
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
var effect_graph:WorkEffectGraphic
var connections:AreaConnections
var face_shelf:Control

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
	var heading:=HFlowContainer.new();heading.name="PeopleSituation";heading.add_theme_constant_override("h_separation",16);heading.add_theme_constant_override("v_separation",6);add_child(heading)
	scene_title=T.make_label("",22,T.INK);scene_title.add_theme_font_override("font",T.font("ui_strong"));heading.add_child(scene_title)
	scope_note=T.make_label("",14,T.MUTED);scope_note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;heading.add_child(scope_note)
	var command:=heading
	mode_note=T.make_label("",14,T.BODY);mode_note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;command.add_child(mode_note)
	overview_button=_scene_button(command,"Overview",_return_overview);overview_button.visible=false
	leaders_button=_scene_button(command,"Let our leaders assign",_delegate);leaders_button.visible=false
	pause_button=_scene_button(command,"Pause to plan",_pause_to_plan);pause_button.name="PauseToPlan";pause_button.tooltip_text="The world keeps moving while you plan. Pause it here, then resume with the clock when ready.";pause_button.visible=false
	pending_note=T.make_label("",14,T.AMBER_TEXT);pending_note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;command.add_child(pending_note)
	stage=Control.new();stage.name="LivingPeopleScene";stage.custom_minimum_size.y=560;stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stage.clip_contents=true;add_child(stage)
	settlement_view=_make_settlement_view();settlement_view.name="PeopleSettlementView";stage.add_child(settlement_view);settlement_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settlement_view.connect("role_anchors_changed",_anchors_changed)
	if settlement_view.has_signal("role_selected"):settlement_view.connect("role_selected",focus_work)
	overlay=Control.new();overlay.name="WorkAreaReadings";overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage.add_child(overlay);overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	connections=AreaConnections.new();overlay.add_child(connections);connections.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for role:String in ROLE_NAMES:
		var marker:=PanelContainer.new();marker.name="WorkArea_"+role;marker.custom_minimum_size=Vector2(184,0);marker.add_theme_stylebox_override("panel",T.flat(Color.TRANSPARENT,Color.TRANSPARENT,0,0,6));overlay.add_child(marker)
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",6);marker.add_child(line)
		var body:=VBoxContainer.new();body.add_theme_constant_override("separation",0);line.add_child(body)
		var title:=T.make_label(ROLE_NAMES[role],14,T.INK);title.add_theme_font_override("font",T.font("ui_strong"));title.add_theme_color_override("font_outline_color",T.PANEL_BG);title.add_theme_constant_override("outline_size",2);body.add_child(title)
		var number:=T.make_label("",16,T.INK);number.name="Workers";number.add_theme_color_override("font_outline_color",T.PANEL_BG);number.add_theme_constant_override("outline_size",2);body.add_child(number)
		var assign:=_scene_button(line,"Assign",focus_work.bind(role));assign.name="Assign_"+role;assign.tooltip_text="Assign workers to "+String(ROLE_NAMES[role]);assign.add_theme_font_size_override("font_size",14);assign.custom_minimum_size=Vector2(66,40)
		var normal:=T.flat(Color(T.PANEL_BG,0.16),Color.TRANSPARENT,0,3,6)
		assign.add_theme_stylebox_override("normal",normal);assign.add_theme_color_override("font_color",T.ACTION);assign.add_theme_color_override("font_outline_color",T.PANEL_BG);assign.add_theme_constant_override("outline_size",2)
		markers[role]={"node":marker,"number":number,"button":assign}
	_build_focus()
	stage.resized.connect(_fit_scene)

func _make_settlement_view()->Control:
	return load("res://scripts/hud/people_settlement_view.gd").new()

func _scene_surface()->StyleBoxFlat:
	var surface:=T.flat(T.PANEL_BG,T.BORDER_SOFT,1,T.RADIUS_CONTROL,10)
	surface.bg_color.a=0.88
	return surface

func _scene_button(parent:Node,words:String,callback:Callable,primary:=false)->Button:
	var button:=Button.new();button.text=words;T.apply_button_style(button,primary);button.pressed.connect(callback);parent.add_child(button);return button

func _build_focus()->void:
	focus_panel=PanelContainer.new();focus_panel.name="WorkDraft";focus_panel.visible=false;focus_panel.custom_minimum_size.x=260;focus_panel.add_theme_stylebox_override("panel",_scene_surface());overlay.add_child(focus_panel)
	focus_body=VBoxContainer.new();focus_body.add_theme_constant_override("separation",8);focus_panel.add_child(focus_body)
	focus_title=T.make_label("",22,T.INK);focus_title.add_theme_font_override("font",T.font("ui_strong"));focus_body.add_child(focus_title)
	focus_purpose=T.make_label("",14,T.BODY);focus_purpose.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_body.add_child(focus_purpose)
	focus_actions=focus_body
	evidence_panel=PanelContainer.new();evidence_panel.name="WorkConsequences";evidence_panel.visible=false;evidence_panel.add_theme_stylebox_override("panel",_scene_surface());overlay.add_child(evidence_panel)
	focus_evidence=VBoxContainer.new();focus_evidence.add_theme_constant_override("separation",6);evidence_panel.add_child(focus_evidence)
	people_reading=T.make_label("",20,T.INK);people_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_actions.add_child(people_reading)
	var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",6);focus_actions.add_child(controls)
	decrease_button=_scene_button(controls,"−",_step.bind(-1));decrease_button.name="DraftLess";decrease_button.custom_minimum_size.x=44
	increase_button=_scene_button(controls,"+",_step.bind(1));increase_button.name="DraftMore";increase_button.custom_minimum_size.x=44
	five_button=_scene_button(controls,"+5",_step.bind(5));five_button.name="DraftFive";five_button.custom_minimum_size.x=44
	var step_note:=T.make_label("1% of workers per step",14,T.MUTED);step_note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;focus_actions.add_child(step_note)
	transfer_reading=T.make_label("",14,T.BODY);transfer_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_actions.add_child(transfer_reading)
	effect_graph=WorkEffectGraphic.new();effect_graph.name="LikelyWorkEffects";focus_evidence.add_child(effect_graph)
	forecast_reading=T.make_label("",16,T.INK);forecast_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_evidence.add_child(forecast_reading)
	risk_reading=T.make_label("",14,T.AMBER_TEXT);risk_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;focus_actions.add_child(risk_reading)
	var commands:=HFlowContainer.new();commands.add_theme_constant_override("h_separation",8);commands.add_theme_constant_override("v_separation",6);focus_actions.add_child(commands)
	apply_button=_scene_button(commands,"Apply assignment",_apply_draft,true);apply_button.name="ApplyWorkDraft"
	cancel_button=_scene_button(commands,"Cancel",_cancel_draft);cancel_button.name="CancelWorkDraft"

func _fill_scene(scene:Dictionary)->void:
	if settlement_view==null:return
	var context:Dictionary=data.get("settlement_view",{}).duplicate()
	context.allocations={}
	for task:Dictionary in data.get("labor",{}).get("tasks",[]):context.allocations[String(task.id)]=int(task.count)
	if not _configured:settlement_view.call("configure",context);_configured=true
	else:settlement_view.call("update_state",context)
	scene_title.text=String(context.get("name","Our people"))
	scope_note.text="%d workers · across our settlements" % int(data.get("labor",{}).get("able",0))
	scene_title.tooltip_text=String(scene.get("headline",""))+"\n"+String(scene.get("season",""))
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
	for task:Dictionary in labor.get("tasks",[]):
		var role:=String(task.id)
		if not markers.has(role):continue
		(markers[role].number as Label).text="%s workers" % preload("res://scripts/hud/era_words.gd").grouped(int(task.count))
		(markers[role].node as Control).tooltip_text=_share_text(task)+" of the work · "+_task_tip(task)
	if not draft.is_empty():draft_stale=draft_stale or bool(forecast.get("stale",false)) or _draft_revision!=data.get("workforce_revision",[])
	_refresh_focus()

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
	var focused:=active_role!=""
	focus_panel.visible=focused;evidence_panel.visible=focused;overview_button.visible=focused
	for role:String in markers:(markers[role].node as Control).visible=not focused
	var commands:Array=draft.get("commands",[])
	pending_note.text=("Updated preview · review before Apply" if preview_rebased else "Draft changes · not applied") if not commands.is_empty() else ""
	if not focused:return
	focus_title.text=String(ROLE_NAMES.get(active_role,active_role))
	var now:=0
	for task:Dictionary in data.get("labor",{}).get("tasks",[]):
		if String(task.id)==active_role:now=int(task.count);break
	var proposed:=int(draft.get("counts",{}).get(active_role,now))
	var applied:=int(forecast.get("after",{}).get("counts",{}).get(active_role,proposed))
	people_reading.text="%d → %d workers" % [now,proposed] if proposed!=now else "%d workers" % now
	if applied!=proposed:people_reading.text+=" · %d after food protection" % applied
	var transfers:PackedStringArray=[]
	for change:Dictionary in draft.get("changes",[]):
		if String(change.get("role",""))==active_role:continue
		transfers.append("%s %d → %d" % [String(change.role),int(change.before),int(change.after)])
	transfer_reading.text="Requested: "+" · ".join(transfers) if not transfers.is_empty() else ""
	effect_graph.show_forecast(forecast,active_role,String(data.get("settlement_view",{}).get("settlement_id","")),bool(draft.get("has_changes",not commands.is_empty())))
	forecast_reading.text=_forecast_words()
	var warnings:=_warning_words()
	var food:Dictionary=forecast.get("after",{}).get("food",{})
	if float(food.get("net",0))<0 and String(food.get("hunger_risk","none"))=="none":warnings.append("Stores fall by %.1f rations/day at today’s conditions." % -float(food.net))
	if draft_stale:warnings.insert(0,"Conditions changed while you planned. Refresh this preview before applying.")
	elif not bool(forecast.get("ok",false)):warnings.insert(0,String(forecast.get("reason","A forecast is not available yet.")))
	risk_reading.text="\n".join(warnings)
	apply_button.text="Refresh preview" if draft_stale else ("Apply assignment" if bool(data.get("labor",{}).get("manual",false)) else "Take control & apply")
	apply_button.disabled=not draft_stale and (commands.is_empty() or not bool(forecast.get("ok",false)))
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

func _forecast_words()->String:
	if forecast.is_empty():return ""
	var new_food:Dictionary=forecast.get("after",{}).get("food",{})
	if new_food.is_empty():return ""
	if active_role=="Extraction":return "Output is not forecast. "+String(forecast.get("after",{}).get("materials",{}).get("reason","It also depends on deposits, carrying and demand."))
	if active_role=="Crafting":return "Goods output is not forecast; it also depends on supplies and demand."
	if active_role=="Logistics" and not bool(forecast.get("after",{}).get("water",{}).get("known",false)):return "Water collection is not measured yet. Food assumes today’s conditions."
	return "Estimate with today’s conditions held steady."

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
	active_role="";settlement_view.call("reset_view");_refresh_focus()

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
	var occupied:Array[Rect2]=[]
	var lines:Array=[]
	var anchor_info:Dictionary=settlement_view.call("role_anchor_metadata") if settlement_view.has_method("role_anchor_metadata") else {}
	for role:String in markers:
		var marker:Control=markers[role].node
		(markers[role].button as Button).text="Assign workers" if width>=1100 else "Assign"
		marker.size=marker.get_combined_minimum_size()
		var point:Vector2=anchors.get(role,Vector2(width*0.5,stage.size.y*0.5))
		var wanted:=point+Vector2(10,-marker.size.y*0.5)
		wanted.x=clampf(wanted.x,8,maxf(8,width-marker.size.x-8));wanted.y=clampf(wanted.y,8,maxf(8,stage.size.y-marker.size.y-8))
		var rect:=Rect2(wanted,marker.size)
		for attempt in 18:
			var collision:=false
			for other:Rect2 in occupied:
				if rect.intersects(other.grow(4)):collision=true;break
			if not collision:break
			rect.position.y+=marker.size.y+6
			if rect.end.y>stage.size.y-8:rect.position.y=8;rect.position.x=maxf(8,rect.position.x-marker.size.x-12)
		marker.position=rect.position;occupied.append(rect)
		if bool(anchor_info.get(role,{}).get("physical",false)):
			lines.append({"from":point,"to":Vector2(clampf(point.x,rect.position.x,rect.end.x),clampf(point.y,rect.position.y,rect.end.y))})
	if connections!=null:connections.lines=lines;connections.visible=true;connections.queue_redraw()
	if focus_panel!=null:
		var point:Vector2=anchors.get(active_role,Vector2(width*0.5,stage.size.y*0.5))
		var control_width:=minf(280,width*0.32)
		var evidence_width:=minf(340,width*0.36)
		focus_panel.custom_minimum_size.x=control_width;focus_panel.size.x=control_width
		evidence_panel.custom_minimum_size.x=evidence_width;evidence_panel.size.x=evidence_width
		focus_panel.size.y=focus_panel.get_combined_minimum_size().y
		evidence_panel.size.y=evidence_panel.get_combined_minimum_size().y
		focus_panel.position=Vector2(clampf(point.x-control_width-70,12,maxf(12,width-control_width-12)),clampf(point.y-focus_panel.size.y*.5,12,maxf(12,stage.size.y-focus_panel.size.y-12)))
		evidence_panel.position=Vector2(clampf(point.x+80,12,maxf(12,width-evidence_width-12)),clampf(point.y-evidence_panel.size.y*.5,12,maxf(12,stage.size.y-evidence_panel.size.y-12)))
		if active_role!="" and connections!=null:
			connections.lines=[]
			if bool(anchor_info.get(active_role,{}).get("physical",false)):
				var rect:=focus_panel.get_rect()
				connections.lines=[{"from":point,"to":Vector2(clampf(point.x,rect.position.x,rect.end.x),clampf(point.y,rect.position.y,rect.end.y))}]
			connections.queue_redraw()

func view_state()->Dictionary:
	# A preview contains detached system/catalog snapshots. Dock memory retains
	# only the player's intentions, never megabytes of transient simulation data.
	var saved:=super.view_state();saved.focus_work=active_role
	saved.work_plan={"commands":(draft.get("commands",[]) as Array).duplicate(true),"token":draft.get("token",0)}
	return saved

func restore_view_state(saved:Dictionary)->void:
	super.restore_view_state(saved)
	var plan:Dictionary=saved.get("work_plan",{})
	if not (plan.get("commands",[]) as Array).is_empty():
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
			draw_polyline(PackedVector2Array([start,elbow,finish]),T.PANEL_BG,2,true)
			draw_polyline(PackedVector2Array([start,elbow,finish]),Color(T.ACTION,0.6),1,true)
			draw_circle(start,2,T.ACTION)

class WorkEffectGraphic extends Control:
	var readings:Array=[]
	var food_path:Array=[]
	var food_change:=""
	var comparing:=false
	func _init()->void:
		custom_minimum_size=Vector2(260,72);mouse_filter=Control.MOUSE_FILTER_IGNORE
	func show_forecast(result:Dictionary,role:String,settlement_id:String="",has_changes:=false)->void:
		readings.clear();food_path.clear();food_change="";comparing=has_changes
		var before:Dictionary=result.get("before",{});var after:Dictionary=result.get("after",{})
		var old_food:Dictionary=before.get("food",{});var food:Dictionary=after.get("food",{})
		if food.has("net"):
			food_change="Needs %.1f → %.1f/day\nStores %+.1f → %+.1f rations/day" % [float(old_food.get("required",0)),float(food.get("required",0)),float(old_food.get("net",0)),float(food.net)] if comparing else "Needs %.1f/day\nStores %+.1f rations/day" % [float(food.get("required",0)),float(food.net)]
			tooltip_text="Food eaten %.1f → %.1f; spoiled %.1f → %.1f rations/day. Grey shows current work; coral shows this draft." % [float(old_food.get("eaten",0)),float(food.get("eaten",0)),float(old_food.get("spoilage",0)),float(food.get("spoilage",0))]
		if food.has("production"):readings.append({"label":"Food each day","before":float(old_food.get("production",0)),"after":float(food.production),"need":float(food.get("required",0)),"unit":"rations"})
		if role=="Knowledge":
			var old:Dictionary=before.get("research",{});var next:Dictionary=after.get("research",{})
			if next.has("effective_work"):
				var prior:=float(old.get("effective_work",0));var proposed:=float(next.effective_work)
				var words:="%+.0f%% effort · %d teams" % [(proposed/prior-1)*100,int(next.get("teams",0))] if prior>0 else "%d teams · no earlier work capacity" % int(next.get("teams",0))
				if not comparing:words="%d teams · current supplies" % int(next.get("teams",0))
				readings.append({"label":"Research pace · current supplies","before":prior,"after":proposed,"words":words,"unit":""})
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
		if food.has("stock"):
			food_path.append({"day":0,"before":float(old_food.get("stock",0)),"after":float(food.stock)})
			for day:int in [30,90]:
				var old:Dictionary=old_food.get("forecast%d"%day,{});var next:Dictionary=food.get("forecast%d"%day,{})
				if old.has("ending_rations") and next.has("ending_rations"):food_path.append({"day":day,"before":float(old.ending_rations),"after":float(next.ending_rations)})
		custom_minimum_size.y=readings.size()*64.0+(38 if food_change!="" else 0)+(112 if food_path.size()>1 else 0);visible=not readings.is_empty();queue_redraw()
	func _housing(plan:Dictionary,settlement_id:String)->Dictionary:
		var construction:Dictionary=plan.get("construction",{})
		if not (construction.get("housing",{}) as Dictionary).is_empty():return construction.housing
		for town:Dictionary in construction.get("towns",[]):
			if String(town.get("id",""))==settlement_id:return town.get("construction",{}).get("housing",{})
		return {}
	func _draw()->void:
		var font:=T.font("ui");var strong:=T.font("ui_strong")
		for index in readings.size():
			var reading:Dictionary=readings[index];var y:=index*64.0
			var before:=float(reading.before);var after:=float(reading.after);var need:=float(reading.get("need",0))
			var scale:=maxf(1,maxf(maxf(before,after),need))*1.05
			var ink:=T.RED_TEXT if need>0 and after<need else (T.AMBER_TEXT if after<before else T.GREEN_TEXT)
			if bool(reading.get("lower_better",false)):ink=T.GREEN_TEXT if after<=before else T.AMBER_TEXT
			draw_string(strong,Vector2(0,y+15),String(reading.label),HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.INK)
			draw_string(font,Vector2(0,y+34),String(reading.get("words","%.1f → %.1f %s" % [before,after,reading.unit] if comparing else "%.1f %s" % [after,reading.unit])),HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
			draw_rect(Rect2(0,y+43,size.x,12),T.TRACK)
			if comparing:draw_rect(Rect2(0,y+43,size.x*before/scale,4),T.MUTED)
			draw_rect(Rect2(0,y+48,size.x*after/scale,7),ink)
			if need>0:
				var x:=size.x*need/scale;draw_line(Vector2(x,y+40),Vector2(x,y+58),T.INK,2)
				var caption:="need %.1f" % need;var text_width:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
				draw_string(font,Vector2(maxf(0,size.x-text_width),y+15),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.MUTED)
		var y:=readings.size()*64.0
		if food_change!="":
			for line:String in food_change.split("\n"):draw_string(font,Vector2(0,y+14),line,HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.AMBER_TEXT if line.begins_with("Stores") and (line.contains("→ -") or line.begins_with("Stores -")) else T.BODY);y+=18
			y+=2
		if food_path.size()>1:_draw_food_path(y,font,strong)
	func _draw_food_path(y:float,font:Font,strong:Font)->void:
		var maximum:=1.0
		for point:Dictionary in food_path:maximum=maxf(maximum,maxf(float(point.before),float(point.after)))
		draw_string(strong,Vector2(0,y+14),"Food held · seasonal outlook",HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.INK)
		var prior_before:=Vector2.ZERO;var prior_after:=Vector2.ZERO
		for i in food_path.size():
			var point:Dictionary=food_path[i];var x:=20+(size.x-48)*float(point.day)/90.0
			var before:=Vector2(x,y+89-float(point.before)/maximum*30);var after:=Vector2(x,y+89-float(point.after)/maximum*30)
			if i>0:
				if comparing:draw_line(prior_before,before,T.MUTED,1.5,true)
				draw_line(prior_after,after,T.ACTION,2.5,true)
			draw_circle(after,3,T.ACTION)
			var caption:="Now" if int(point.day)==0 else "%dd" % int(point.day)
			draw_string(font,Vector2(x-12,y+106),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.MUTED)
			prior_before=before;prior_after=after
		var end:Dictionary=food_path.back()
		var words:="%s → %s rations" % [preload("res://scripts/hud/era_words.gd").grouped(int(round(float(end.before)))),preload("res://scripts/hud/era_words.gd").grouped(int(round(float(end.after))))]
		if not comparing:words="%s rations" % preload("res://scripts/hud/era_words.gd").grouped(int(round(float(end.after))))
		draw_string(font,Vector2(0,y+32),"At 90 days · current work → draft" if comparing else "At 90 days · current work",HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.MUTED)
		draw_string(font,Vector2(0,y+49),words,HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.BODY)
