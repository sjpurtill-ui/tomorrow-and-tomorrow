class_name BattleGraphicsScreen
extends Control

const DIORAMA := preload("res://scripts/battle_diorama.gd")
var view: Node3D
var viewport: SubViewport
var stage: SubViewportContainer
var heading: Label
var status: Label
var event_label: Label
var details: Label
var life_story:Button
var selected_figure_id:=""
var meters: Array[ProgressBar] = []
var force_labels: Array[Label] = []
var order_buttons: Array[Button] = []
var theme_choice: OptionButton
var formation_choice: OptionButton
var model_choice: OptionButton
var appearance: VBoxContainer
var timeline: Label
var round_title: Label
var previous_round: Button
var next_round: Button
var round_records: Array = []
var selected_round := -1
var campaign_mode := true
var inspected_army_id := 0
var inspected_force: Dictionary = {}
var poll := 0.0
var signature := ""
var encounter := ""
var appearance_signature := ""
var cached_forces: Array = []
var camera_drag_distance := 0.0
var camera_pressed := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new(); background.color=Color("101e26"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,16)
	add_child(margin)
	var layout := VBoxContainer.new(); margin.add_child(layout)
	var header := HBoxContainer.new(); layout.add_child(header)
	heading=Label.new(); heading.text="BATTLEFIELD"; heading.add_theme_font_size_override("font_size",24); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(heading)
	button(header,"PEOPLE & LEGACIES",func(): HistoricalFigures.open_chronicle())
	button(header,"CLOSE",func(): queue_free())
	status=Label.new(); status.add_theme_color_override("font_color",Color("8db7c5")); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; layout.add_child(status)
	var scores:=HBoxContainer.new(); layout.add_child(scores)
	for side in 2:
		var box:=VBoxContainer.new(); box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scores.add_child(box)
		var label:=Label.new(); label.add_theme_font_size_override("font_size",18); label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.add_theme_color_override("font_color",BattleDiorama.COLORS[side]); box.add_child(label); force_labels.append(label)
		var meter:=ProgressBar.new(); meter.custom_minimum_size.y=10; meter.show_percentage=false; box.add_child(meter); meters.append(meter)
	var body:=HBoxContainer.new(); body.size_flags_vertical=Control.SIZE_EXPAND_FILL; layout.add_child(body)
	stage=SubViewportContainer.new(); stage.stretch=true; stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL; stage.size_flags_vertical=Control.SIZE_EXPAND_FILL
	stage.custom_minimum_size=Vector2(360,260); body.add_child(stage)
	viewport=SubViewport.new(); viewport.own_world_3d=true; viewport.size=Vector2i(960,600); viewport.msaa_3d=Viewport.MSAA_8X; stage.add_child(viewport)
	view=DIORAMA.new(); viewport.add_child(view)
	view.formation_selected.connect(_selected)
	stage.gui_input.connect(_view_input)
	var sidebar:=VBoxContainer.new(); sidebar.custom_minimum_size.x=310; body.add_child(sidebar)
	details=Label.new(); details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; sidebar.add_child(details)
	details.text="FORMATION INSPECTOR\nClick a formation to see its soldiers and condition."
	life_story=button(sidebar,"READ LIFE STORY",func(): HistoricalFigures.open_chronicle(selected_figure_id)); life_story.visible=false
	var legend:=Label.new(); legend.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; legend.add_theme_font_size_override("font_size",14)
	legend.text="CASUALTIES = dead + wounded.\nOUT OF ACTION also includes scattered.\nLasting injuries are a subset of wounded survivors; they retain reduced work capacity after returning home.\nEach figure represents a group."
	sidebar.add_child(legend)
	appearance=VBoxContainer.new(); sidebar.add_child(appearance)
	var appearance_title:=Label.new(); appearance_title.text="ARMY APPEARANCE"; appearance.add_child(appearance_title)
	theme_choice=OptionButton.new(); appearance.add_child(theme_choice)
	for label in UnitVisualCatalog.LABELS: theme_choice.add_item(label)
	theme_choice.item_selected.connect(func(index:int):
		var result:Dictionary=MilitaryCampaign.set_army_visual_theme(inspected_army_id,UnitVisualCatalog.THEMES[index])
		status.text=String(result.get("error",result.get("message",""))); signature="")
	formation_choice=OptionButton.new(); formation_choice.fit_to_longest_item=false; formation_choice.custom_minimum_size.x=250; appearance.add_child(formation_choice)
	formation_choice.item_selected.connect(func(_index:int): _model_options())
	model_choice=OptionButton.new(); model_choice.fit_to_longest_item=false; appearance.add_child(model_choice)
	model_choice.item_selected.connect(func(index:int):
		if formation_choice.selected<0: return
		var result:Dictionary=MilitaryCampaign.set_formation_visual(inspected_army_id,int(formation_choice.get_selected_metadata()),String(model_choice.get_item_metadata(index)))
		status.text=String(result.get("error",result.get("message",""))); signature="")
	var note:=Label.new(); note.text="Appearance only. Equipment and\ncombat role stay unchanged."; note.add_theme_font_size_override("font_size",12); appearance.add_child(note)
	var navigation:=HBoxContainer.new(); sidebar.add_child(navigation)
	previous_round=button(navigation,"‹",func(): _show_round(selected_round-1))
	previous_round.tooltip_text="Previous round summary"
	round_title=Label.new(); round_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; round_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; navigation.add_child(round_title)
	next_round=button(navigation,"›",func(): _show_round(selected_round+1))
	next_round.tooltip_text="Next round summary"
	button(navigation,"LATEST",func(): _show_round(round_records.size()-1))
	timeline=Label.new(); timeline.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; timeline.add_theme_font_size_override("font_size",15); sidebar.add_child(timeline)
	var controls:=HFlowContainer.new(); layout.add_child(controls)
	button(controls,"PAUSE VIEW",func(): view.playback_speed=1.0 if view.playback_speed==0.0 else 0.0)
	button(controls,"SLOW MOTION",func(): view.playback_speed=.35 if view.playback_speed!=.35 else 1.0)
	button(controls,"DIRECTOR CAMERA",func(): view.cinematic=not view.cinematic)
	button(controls,"OVERVIEW",func(): view.cinematic=false; view.elevation=.66; view.target=Vector3(0,1,0); view.zoom=65; view._camera_update())
	button(controls,"FRONT LINE",func(): view.cinematic=false; view.target=Vector3(0,1,0); view.zoom=32; view._camera_update())
	for command in ["hold","push","retreat"]:
		var text: String={"hold":"HOLD ROUND","push":"PRESS ATTACK","retreat":"RETREAT"}[command]
		var order:=button(controls,text,_order.bind(command)); order_buttons.append(order)
	var camera_help:=Label.new(); camera_help.text="Left drag: pan · Right drag: rotate / tilt · Wheel: zoom at cursor · Click: focus · Overview: reset"; camera_help.add_theme_font_size_override("font_size",14); camera_help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; layout.add_child(camera_help)
	event_label=Label.new(); event_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; event_label.text="Click a unit or the ground to focus. Playback controls affect only the picture."; layout.add_child(event_label)
	if campaign_mode: _sync_campaign()

func button(parent:Node,text:String,action:Callable)->Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size.y=34; b.pressed.connect(action); parent.add_child(b); return b

func _process(delta:float)->void:
	if not campaign_mode: return
	poll+=delta
	if poll>.25: poll=0; _sync_campaign()
	var active:=not MilitaryCampaign.active_engagement.is_empty()
	for order in order_buttons: order.disabled=not active or view.round_clock<2.4 or view.playback_speed==0

func _force_for_inspection()->Dictionary:
	if inspected_army_id==0: return MilitaryCampaign.campaign_army_snapshot()
	for army:Dictionary in MilitaryCampaign.field_armies_snapshot().get("armies",[]):
		if int(army.get("army_id",0))==inspected_army_id: return army
	return {}

func _sync_campaign()->void:
	var active:Dictionary=MilitaryCampaign.engagement_snapshot()
	if not active.is_empty():
		appearance.visible=false
		var key:="%s/%s" % [active.get("seed",0),active.get("round",0)]
		if signature==key: return
		var id:=str(active.get("seed",0))
		var a:Dictionary=active.attacker; var d:Dictionary=active.defender
		if encounter!=id: view.set_landscape(active); view.reset(a,d); encounter=id
		var records:Array=active.get("rounds",[])
		present(a,d,records[-1] if not records.is_empty() else {},"",records)
		heading.text="LIVE BATTLE • ROUND %d" % int(active.get("round",0))
		status.text="%s · Orders resolve one campaign round. Defender terrain defense: %+.0f%%. Figures represent groups of soldiers." % [String(view.landscape.context.get("label","Battlefield")),(float(active.get("terrain_defense",1))-1.0)*100.0]
		signature=key
	elif not encounter.is_empty() and not MilitaryCampaign.battle_history.is_empty():
		var result:Dictionary=MilitaryCampaign.battle_history[0]
		if str(result.get("seed",-1))!=encounter: return
		var key:="finished/"+encounter
		if signature==key: return
		var records:Array=result.get("rounds",[])
		var final_record:Dictionary=records[-1].duplicate(true) if not records.is_empty() else {}
		final_record["termination"]=result.get("termination",{}).duplicate(true)
		present(result.attacker,result.defender,final_record,String(result.get("outcome","")),records)
		heading.text="BATTLE AFTERMATH"
		status.text=String((result.get("termination",{}) as Dictionary).get("summary",result.get("outcome","Battle ended")))
		signature=key
	else:
		inspected_force=_force_for_inspection()
		var key:=str(inspected_force.get("formations",[]))+str(inspected_force.get("troops",0))
		if signature==key: return
		view.reset(inspected_force,{})
		present(inspected_force,{}, {},"",[])
		appearance.visible=true; _appearance_options()
		heading.text="ARMY INSPECTION"
		status.text="No active engagement. Use the field-army orders to move this force; its appearance follows it onto the map."
		signature=key

func present(attacker:Dictionary,defender:Dictionary,round_record:Dictionary={},final_outcome:String="",records:Array=[])->void:
	cached_forces=[attacker.duplicate(true),defender.duplicate(true)]
	view.apply_snapshot(attacker,defender,round_record,final_outcome)
	for side in 2:
		var force:Dictionary=cached_forces[side]
		var ledger:=BattleLossSummary.from_rounds(records if not records.is_empty() else ([round_record] if not round_record.is_empty() else []),side,int(force.get("troops",force.get("remaining_troops",0))))
		var disabled_text:=str(ledger.disabled) if ledger.disability_recorded else "not recorded"
		force_labels[side].text="%s  |  %d at start\n%d FIGHTING  ·  %d OUT OF ACTION\n%d CASUALTIES: %d dead + %d wounded  ·  %d scattered\nLasting injuries: %s (included in wounded)  ·  Morale %d%%" % [String(force.get("name","No opposing force")),ledger.starting,ledger.remaining,ledger.out_of_action,ledger.casualties,ledger.dead,ledger.wounded,ledger.scattered,disabled_text,roundi(float(force.get("morale",0))*100)]
		force_labels[side].tooltip_text="This battle only. Casualties = dead + wounded. Out of action also includes scattered/missing. Lasting injuries are surviving wounded, never additional deaths. Earlier wounds are not counted again."
		meters[side].value=clampf(float(force.get("morale",0)),0,1)*100
		meters[side].tooltip_text="Morale: willingness to keep fighting. A full bar is 100%."
	event_label.text="Click a unit or the ground to focus. View controls change animation only."
	var follow_latest:=selected_round>=round_records.size()-1
	round_records=records.duplicate(true)
	if round_records.is_empty() and not round_record.is_empty(): round_records.append(round_record.duplicate(true))
	_show_round(round_records.size()-1 if follow_latest else selected_round)
	if not campaign_mode:
		appearance.visible=false
		for order in order_buttons: order.visible=false

func _appearance_options()->void:
	var key:=str(inspected_force.get("formations",[]))
	if appearance_signature==key: return
	appearance_signature=key; formation_choice.clear()
	for formation:Dictionary in inspected_force.get("formations",[]):
		formation_choice.add_item("#%d %s" % [int(formation.get("id",-1)),String(formation.get("unit","unit")).replace("_"," ")])
		formation_choice.set_item_metadata(formation_choice.item_count-1,int(formation.get("id",-1)))
	var index:=UnitVisualCatalog.THEMES.find(String(inspected_force.get("visual_theme","equipment")))
	theme_choice.select(maxi(0,index)); _model_options()

func _model_options()->void:
	model_choice.clear()
	if formation_choice.selected<0: return
	var formation:Dictionary=inspected_force.get("formations",[])[formation_choice.selected]
	var options:Array=UnitVisualCatalog.VARIANTS.get(String(formation.get("unit","")),[])
	var current:=UnitVisualCatalog.model(formation)
	for id:String in options:
		model_choice.add_item(id.replace("_"," ").capitalize()); model_choice.set_item_metadata(model_choice.item_count-1,id)
		if id==current: model_choice.select(model_choice.item_count-1)

func _order(command:String)->void:
	if not campaign_mode or MilitaryCampaign.active_engagement.is_empty(): return
	var result:Dictionary=MilitaryCampaign.advance_engagement(command)
	if result.has("error"): status.text=String(result.error)
	else: _sync_campaign()

func _show_round(index:int)->void:
	selected_round=clampi(index,0,maxi(0,round_records.size()-1))
	previous_round.disabled=round_records.is_empty() or selected_round==0
	next_round.disabled=round_records.is_empty() or selected_round>=round_records.size()-1
	if round_records.is_empty():
		round_title.text="ROUND SUMMARY"
		timeline.text="No combat rounds yet."
		return
	var entry:Dictionary=round_records[selected_round]
	round_title.text="ROUND %d OF %d" % [int(entry.get("round",selected_round+1)),round_records.size()]
	timeline.text="SOLDIERS LOST THIS ROUND\n"
	for side in 2:
		var key:="attacker" if side==0 else "defender"
		var army_name:=String(cached_forces[side].get("name",key.capitalize()))
		var losses:=int(entry.get(key+"_losses",0))
		var casualties:Dictionary=entry.get(key+"_casualties",{})
		timeline.text+="%s: %d lost\n" % [army_name,losses]
		if not casualties.is_empty():
			timeline.text+="%d killed · %d wounded · %d scattered\n" % [int(casualties.get("killed",0)),int(casualties.get("wounded",0)),int(casualties.get("scattered",0))]
	timeline.text+="Round figures above; whole-battle totals are at the top. Scattered personnel are absent, not recorded dead."
	event_label.text="Round %d: %s" % [int(entry.get("round",selected_round+1)),String(entry.get("event","Round resolved."))]

func _selected(data:Dictionary)->void:
	selected_figure_id=String(data.get("figure_id",""))
	life_story.visible=not selected_figure_id.is_empty()
	if data.get("general",false):
		details.text="GENERAL %s\nStatus: %s\nLeadership: %d%%\nTactical skill: %d%%\nResolve: %d%%" % [data.name,data.fate,roundi(float(data.command)*100),roundi(float(data.tactics)*100),roundi(float(data.resolve)*100)]
		return
	details.text="%s\n%d soldiers remaining · %d at start\nWill to fight: %d%%\nBattle readiness: %d%%" % [data.name,int(data.count),int(data.initial),roundi(float(data.morale)*100),roundi(float(data.readiness)*100)]


func _view_input(event:InputEvent)->void:
	var ratio:=Vector2(viewport.size)/stage.size
	if event is InputEventMouseMotion:
		if event.button_mask & (MOUSE_BUTTON_MASK_LEFT|MOUSE_BUTTON_MASK_MIDDLE):
			camera_drag_distance+=event.relative.length()
			if camera_drag_distance>5 or event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
				view.pan((event.position-event.relative)*ratio,event.position*ratio)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			view.orbit(-event.relative.x*.006,event.relative.y*.005)
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				camera_pressed=true; camera_drag_distance=0
			else:
				if camera_pressed and camera_drag_distance<=5: view.pick(event.position*ratio)
				camera_pressed=false
		elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:
			view.zoom_at(event.position*ratio,-view.zoom*.12)
		elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			view.zoom_at(event.position*ratio,view.zoom*.12)
