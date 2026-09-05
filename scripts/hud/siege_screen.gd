extends CanvasLayer
const CITY=preload("res://scripts/siege_city_scene.gd")
var siege_id:String=""
var scene:Node3D
var stage:SubViewportContainer
var viewport:SubViewport
var title:Label
var status:Label
var feedback:Label
var order_buttons:Dictionary={}
var battle_buttons:Dictionary={}
var poll:float=0
var last_snapshot:Dictionary={}

static func open(identity:String="")->void:
	var root:Node=Engine.get_main_loop().root
	if root.has_meta("persistent_siege_view") and is_instance_valid(root.get_meta("persistent_siege_view")):return
	var view=load("res://scripts/hud/siege_screen.gd").new();view.siege_id=identity
	root.set_meta("persistent_siege_view",view);root.add_child.call_deferred(view)

func _ready()->void:
	layer=78
	var backdrop:=ColorRect.new();backdrop.color=Color("132029");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,10)
	backdrop.add_child(margin)
	var column:=VBoxContainer.new();margin.add_child(column)
	var head:=HBoxContainer.new();column.add_child(head)
	title=Label.new();title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(title)
	_button(head,"RETURN TO MAP",queue_free)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(status)
	stage=SubViewportContainer.new();stage.stretch=true;stage.size_flags_vertical=Control.SIZE_EXPAND_FILL;stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stage.custom_minimum_size.y=180;column.add_child(stage)
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_2X;stage.add_child(viewport)
	scene=CITY.new();viewport.add_child(scene);stage.gui_input.connect(scene.navigate)
	var camera_row:=HBoxContainer.new();column.add_child(camera_row)
	for place:String in ["overview","gate","city"]:_button(camera_row,place.to_upper(),scene.focus.bind(place))
	var hint:=Label.new();hint.text="Drag to pan • right-drag to orbit • wheel to zoom";hint.add_theme_font_size_override("font_size",13);camera_row.add_child(hint)
	var controls:=HBoxContainer.new();column.add_child(controls)
	for item in [["PAUSE",0],["PLAY",1],["FAST",3]]:_button(controls,String(item[0]),_speed.bind(float(item[1])))
	for order:String in ["continue","assault","withdraw"]:order_buttons[order]=_button(controls,order.to_upper(),_siege_order.bind(order))
	_button(controls,"NEGOTIATE",_negotiate)
	var battle_row:=HBoxContainer.new();column.add_child(battle_row)
	for order:String in ["hold","push","retreat"]:battle_buttons[order]=_button(battle_row,"BATTLE: "+order.to_upper(),_battle_order.bind(order))
	feedback=Label.new();feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;feedback.add_theme_font_size_override("font_size",13);column.add_child(feedback)
	_refresh()

func _button(parent:Node,label:String,action:Callable)->Button:
	var button:=Button.new();button.text=label;button.pressed.connect(action);parent.add_child(button);return button
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	poll+=delta
	if poll>=.3:poll=0;_refresh()
func _refresh()->void:
	var snapshot:Dictionary=MilitaryCampaign.siege_visual_snapshot(siege_id)
	if snapshot.is_empty():title.text="No siege to display";return
	siege_id=String(snapshot.id);last_snapshot=snapshot
	scene.configure(snapshot)
	title.text="SIEGE OF "+String(snapshot.name).to_upper()
	var live:Dictionary=MilitaryCampaign.siege_public_snapshot(siege_id)
	var state_text:="ASSAULT IN PROGRESS" if bool(snapshot.battle_active) else ("HOLDING APPROACHES • no assault underway" if bool(snapshot.active) else "SIEGE ENDED")
	var defense:=int(snapshot.defense_stage)
	var perimeter:String=MilitaryCampaign.SETTLEMENT_DEFENSE_STAGES[defense].short if defense>=0 else "Fortifications unconfirmed"
	status.text=state_text+" • "+String(perimeter)
	if not live.is_empty():status.text+="\nDay %d of siege • Approaches restricted %d%% • Assault pressure %d%% • Your ration coverage %d%%" % [int(live.days),roundi(float(live.blockade)*100),roundi(float(live.pressure)*100),roundi(float(live.own_supply_ratio)*100)]
	else:status.text+="\n"+String(snapshot.summary)
	status.text+="\n"+String(snapshot.description)+" Each soldier figure represents a group."
	for button:Button in order_buttons.values():button.disabled=not bool(snapshot.active)
	order_buttons.assault.text="ASSAULT" if String(snapshot.mode)=="offensive" else "SORTIE"
	for button:Button in battle_buttons.values():button.disabled=not bool(snapshot.battle_active)
func _siege_order(order:String)->void:
	var result:Dictionary=MilitaryCampaign.siege_order(siege_id,order)
	feedback.text=String(result.get("error",result.get("message","")));_refresh()
func _battle_order(order:String)->void:
	var result:Dictionary=MilitaryCampaign.advance_engagement(order)
	feedback.text=String(result.get("error","Battle order resolved."));_refresh()
func _negotiate()->void:
	if not last_snapshot.is_empty():ForeignDiplomacy.open(String(last_snapshot.rival))
func _speed(value:float)->void:
	var terrain:Node=_terrain(get_tree().root)
	if terrain!=null:terrain.call("_set_game_speed",value)
	else:feedback.text="Time controls require the live campaign."
func _terrain(node:Node)->Node:
	if node.has_method("_set_game_speed"):return node
	for child in node.get_children():
		var result:=_terrain(child)
		if result!=null:return result
	return null


