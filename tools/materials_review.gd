extends SceneTree
## Isolated seeded construction UI; never reads or writes campaign saves.
class ReviewTerrain extends Node:
	func _report_military_action(_result:Dictionary)->void:pass
	func _on_settlement_action_pressed()->void:pass
	func _toggle_resource_view()->void:pass
class ReviewHud extends Control:
	func request_immediate_dock_refresh()->void:pass
func _initialize()->void:call_deferred("render")
func render()->void:
	assert(load("res://scripts/hud/command_rail_hud.gd").can_instantiate())
	assert(load("res://scripts/hud/dock_blocks.gd").can_instantiate())
	root.title="MATERIALS REVIEW — SEEDED SIMULATION"
	var state=root.get_node("GameState")
	state.reset_for_new_world(7511)
	state.player_settlements.append({"id":"review_city","name":"Riverbend","primary":true})
	state.resource_settlement_id="review_city";state.selected_player_settlement_id="review_city"
	state.resource_stockpiles={"Timber":240.0,"Stone":180.0,"Clay":64.0,"Fiber Plants":42.0,"Copper Ore":12.0}
	state.material_metrics={"storage_capacity":800.0,"flow_ratio":.82}
	state.resource_deposits.clear()
	var rates:={"Timber":18.4,"Stone":9.2,"Clay":4.0,"Fiber Plants":3.1,"Copper Ore":0.0}
	for key in rates:state.resource_deposits.append({"resource":key,"stage":"recognized","delivered_today":rates[key],"blockers":["Outside hauling reach"] if key=="Copper Ore" else [],"name":key+" site"})
	state.resource_deposits.append({"resource":"Secret Gold","stage":"unknown"})
	var observations:Array=[]
	for i in 8:observations.append({"day":i*30,"Timber":150+i*12,"Stone":110+i*9,"Clay":25+i*5,"Fiber Plants":20+i*3})
	state.strategic_history={"scopes":{"review_city":{"monthly":observations,"annual":[]}}}
	state.city_trade_shipments.append({"destination_id":"review_city","source_id":"donor","source_name":"Hillford","resource":"Timber","quantity":40.0,"arrival_day":3.0,"status":"in_transit"})
	state.city_trade_shipments.append({"destination_id":"other","resource":"Stone","status":"in_transit"})
	var world:=ReviewTerrain.new();var hud:=ReviewHud.new()
	var provider=load("res://scripts/hud/content/dock_content_economy.gd").new(world,hud)
	provider.selected_material="Copper Ore"
	var data:Dictionary=provider._local_tab(1).blocks[0]
	assert(data.rows.size()==5 and data.incoming.size()==1)
	assert(data.rows[0].key=="Timber" and data.rows[0].delivered==18.4)
	assert(data.rows[4].points[0].value==null)
	assert(not provider.open_expanded_tab(1))
	var stocks_before:Dictionary=state.resource_stockpiles.duplicate(true)
	data.on_select.call("Stone")
	assert(provider.selected_material=="Stone")
	data.on_select.call("Stone")
	assert(provider.selected_material=="")
	provider._provisions_focus("logistics")
	assert(state.player_settlements[0].management_focus=="logistics")
	provider._provisions_focus("")
	assert(state.player_settlements[0].auto_manage)
	assert(state.resource_stockpiles==stocks_before)
	# Review uses an explicitly seeded official if the fixture has no appointed leader.
	if data.leader.is_empty():data.leader={"id":10,"name":"Damon of Riverbend"}
	print("MATERIALS_VISIBILITY_HISTORY_SHIPMENTS_DELEGATION_OK")
	var T=load("res://scripts/hud/hud_tokens.gd");T.set_color_mode("light")
	var panel=load("res://scripts/hud/dock_panel.gd").new();root.add_child(panel);panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var review:=ReviewProvider.new();review.data=data;panel.present(review,1)
	for i in 5:await process_frame
	root.content_scale_size=Vector2i(920,1000);root.content_scale_factor=1.0;root.size=Vector2i(920,1000)
	for i in 5:await process_frame
	assert(panel.body.get_combined_minimum_size().x<=684)
	assert(panel.body.get_combined_minimum_size().y<=panel.body_scroll.size.y)
	await RenderingServer.frame_post_draw
	var output:=OS.get_environment("MATERIALS_REVIEW_OUTPUT")
	if output.is_empty():output=OS.get_user_data_dir()+"/materials-review.png"
	root.get_texture().get_image().save_png(output)
	print("MATERIALS_RENDER_OK")
	world.free();hud.free();quit()

class ReviewProvider extends RefCounted:
	var data:Dictionary
	func meta()->Dictionary:return {"eyebrow":"GODOT UI REVIEW · SEEDED SIMULATION","title":"Materials","serif":true,"title_size":38,"spread_tabs":true,"subtabs":["FOOD & WATER","MATERIALS","DISTRIBUTION","WEALTH"]}
	func tab(_sub:int)->Dictionary:return {"blocks":[data]}
