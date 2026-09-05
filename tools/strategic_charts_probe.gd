extends Node
const History:=preload("res://scripts/strategic_history.gd")
const Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")
class Fixture extends RefCounted:
	func meta()->Dictionary: return {"eyebrow":"TEST DATA · CHART RENDER PROBE","title":"Dawngate · Population","subtabs":["POPULATION"]}
	func tab(_sub:int)->Dictionary: return {"blocks":[Charts.population("dawngate",true),Charts.reserves("dawngate")]}
func _ready()->void:
	GameState.reset_for_new_world(99117)
	get_window().size=Vector2i(1280,900)
	get_window().content_scale_size=Vector2i(1280,900)
	GameState.economy_stage="currency"
	GameState.player_settlements=[{"id":"dawngate","name":"Dawngate","primary":false,"population_share":0.2}]
	GameState.selected_player_settlement_id="dawngate"
	SettlementModel._ensure_city_resources(GameState.player_settlements[0])
	GameState.player_settlements[0].local_resources.economy_stage="currency"
	for day in range(0,3650,30):
		History.record(GameState.strategic_history,day,{"dawngate":{"population":1000+day*12,"food_days":12+sin(day/220.0)*4,"water_days":6+sin(day/170.0)*2,"Timber":day/2.0,"Stone":day/3.0,"Clay":day/5.0,"Fiber Plants":day/7.0,"treasury":day*2,"private_currency":day*4,"hoards":day*1.1,"aid":day*0.25}})
	var left:=preload("res://scripts/hud/dock_panel.gd").new()
	left.position=Vector2(20,20)
	left.size=Vector2(590,860)
	add_child(left)
	left.present(Fixture.new())
	var right:=preload("res://scripts/hud/dock_panel.gd").new()
	right.position=Vector2(630,20)
	right.size=Vector2(630,860)
	add_child(right)
	var economy:=preload("res://scripts/hud/content/dock_content_economy.gd").new(null,null)
	right.present(economy,3)
	assert(right.sub==3 and right.tab_buttons.size()==4)
	await get_tree().process_frame
	await get_tree().process_frame
	var chart:Control=left.body.get_child(0).get_child(1)
	assert(chart.graph.size.x>400 and chart.graph.size.y>=215)
	chart.buttons[0].pressed.emit()
	await get_tree().process_frame
	assert(chart.graph.points.size()<20)
	chart.buttons[3].pressed.emit()
	await get_tree().process_frame
	var motion:=InputEventMouseMotion.new()
	motion.position=chart.graph.plot.get_center()
	chart.graph._gui_input(motion)
	assert(chart.graph.tooltip_text.contains("recorded snapshot"))
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/strategic-charts.png")
	print("STRATEGIC_CHARTS_RENDER PASS: actual dock, fourth economy tab, range controls, hover, layout")
	get_tree().quit()
