extends SceneTree
## Isolated seeded construction UI; never reads or writes campaign saves.
class ReviewTerrain extends Node:
	func _report_military_action(_result:Dictionary)->void:pass
	func _on_settlement_action_pressed()->void:pass
class ReviewHud extends Control:
	func request_immediate_dock_refresh()->void:pass
func _initialize()->void:call_deferred("render")
func render()->void:
	assert(load("res://scripts/hud/command_rail_hud.gd").can_instantiate())
	assert(load("res://scripts/hud/dock_blocks.gd").can_instantiate())
	root.title="PROVISIONS REVIEW — SEEDED SIMULATION"
	var state=root.get_node("GameState")
	state.reset_for_new_world(7511)
	state.player_settlements.append({"id":"review_city","name":"Riverbend","primary":true})
	state.resource_settlement_id="review_city";state.selected_player_settlement_id="review_city"
	state.food_stocks={"Fresh plants":820.0,"Fresh meat":180.0,"Fish":160.0,"Dry staples":1260.0,"Preserved food":560.0}
	state.simulation_metrics={"food_days":24.8,"food_production":140.0,"food_eaten":120.0,"food_spoilage":23.0,"food_net":-3.0,"food_spoilage_by_type":{"Fresh plants":12.0,"Fresh meat":4.0,"Fish":4.0,"Dry staples":2.0,"Preserved food":1.0},"food_forecast_30":{"ending_days":5.0},"food_forecast_90":{"ending_days":0.0,"first_shortage_day":38}}
	state.water_metrics={"required_today":120.0,"intake_ratio":1.0}
	var world:=ReviewTerrain.new();var hud:=ReviewHud.new()
	var provider=load("res://scripts/hud/content/dock_content_economy.gd").new(world,hud)
	var data:Dictionary=provider._local_tab(0).blocks[0]
	assert(data.rows.size()==4)
	assert(data.rows[1].name=="Meat & fish" and data.rows[1].stock==340 and data.rows[1].lost==8)
	assert(data.flow.Net==-3.0 and data.forecast90.first_shortage_day==38)
	provider._provisions_focus("water")
	assert(state.player_settlements[0].management_focus=="water")
	provider._provisions_focus("")
	assert(state.player_settlements[0].auto_manage)
	state.water_metrics={}
	assert(not provider._provisions_data().water.has("required_today"))
	print("PROVISIONS_DATA_AND_DELEGATION_OK")
	var T=load("res://scripts/hud/hud_tokens.gd");T.set_color_mode("light")
	var panel=load("res://scripts/hud/dock_panel.gd").new();root.add_child(panel);panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var review:=ReviewProvider.new();review.data=data;panel.present(review,0)
	for i in 5:await process_frame
	root.content_scale_size=Vector2i(920,1000);root.content_scale_factor=1.0;root.size=Vector2i(920,1000)
	for i in 5:await process_frame
	assert(panel.body.get_combined_minimum_size().x<=684)
	assert(panel.body.get_combined_minimum_size().y<=panel.body_scroll.size.y)
	await RenderingServer.frame_post_draw
	var output:=OS.get_environment("PROVISIONS_REVIEW_OUTPUT")
	if output.is_empty():output=OS.get_user_data_dir()+"/provisions-review.png"
	root.get_texture().get_image().save_png(output)
	print("PROVISIONS_RENDER_OK")
	world.free();hud.free();quit()

class ReviewProvider extends RefCounted:
	var data:Dictionary
	func meta()->Dictionary:return {"eyebrow":"GODOT UI REVIEW · SEEDED SIMULATION","title":"Provisions","serif":true,"title_size":38,"spread_tabs":true,"subtabs":["FOOD & WATER","MATERIALS","WEALTH"]}
	func tab(_sub:int)->Dictionary:return {"blocks":[data]}
