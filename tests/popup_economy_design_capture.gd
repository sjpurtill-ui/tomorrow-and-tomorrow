extends Node
## Disposable, in-memory UI fixtures. No campaign is loaded or saved.
const T=preload("res://scripts/hud/hud_tokens.gd")
const Dock=preload("res://scripts/hud/dock_panel.gd")
const Folio=preload("res://scripts/hud/reference_folio.gd")
const WealthFixture=preload("res://tests/wealth_visual_acceptance_probe.gd")
const TradeFixture=preload("res://tests/trade_visual_acceptance_probe.gd")
const FoodFixture=preload("res://tests/test_food_folio.gd")

class CaptureHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Control
	func request_immediate_dock_refresh()->void:pass
	func open_detail(_provider:Object)->void:pass

class CaptureTerrain extends Node:
	func _toggle_resource_view()->void:pass
	func _report_military_action(_result:Dictionary)->void:pass

class FoodProvider extends "res://scripts/hud/content/dock_content_economy.gd":
	var short_food:=false
	func _provisions_data()->Dictionary:
		var result:=super._provisions_data()
		var fixture:=FoodFixture.prepared_food()
		for key:String in fixture:
			if not key.begins_with("on_"):result[key]=fixture[key]
		if short_food:
			result.food_days=6.2;result.rows[1].stock=2641.0
			result.forecast90={"first_shortage_day":12,"ending_days":0.0}
			result.water.intake_ratio=0.5;result.water.collected_today=213.0
			result.flow.Produced=411.0;result.flow.Net=-37.0
			result.sources[0].produced=320.0;result.sources[1].produced=91.0
			result.history=[{"day":0,"value":20.0},{"day":30,"value":6.2}]
		return result

func _ready()->void:call_deferred("_run")
func _arg(key:String,fallback:String)->String:
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--"+key+"="):return argument.trim_prefix("--"+key+"=")
	return fallback

func _run()->void:
	for node:Node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	var fixture:=WealthFixture.new()
	fixture._fixture(_arg("state","opening"))
	var output:=_arg("out",OS.get_user_data_dir())
	var tag:=_arg("tag","capture")
	var terrain:=CaptureTerrain.new();add_child(terrain)
	var hud:=CaptureHud.new();add_child(hud)
	var provider:=FoodProvider.new(terrain,hud)
	for canvas:Vector2i in [Vector2i(1440,900),Vector2i(1000,760)]:
		for palette:String in ["dark","light"]:
			T.set_color_mode(palette)
			var viewport:=SubViewport.new();viewport.size=canvas;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
			var background:=ColorRect.new();background.color=T.PAPER_SUNK;background.size=Vector2(canvas);viewport.add_child(background)
			var dock:=Dock.new();dock.theme=T.control_theme();dock.position=Vector2(24,20);dock.size=Vector2(Folio.page_width(canvas.x),canvas.y-40);viewport.add_child(dock);hud.dock=dock
			for page:Array in [[0,"food"],[1,"materials"],[2,"wealth"]]:
				if _arg("page","all")!="all" and _arg("page","all")!=String(page[1]):continue
				dock.present(provider,int(page[0]));await _settle()
				await _capture(viewport,output,"economy-%s-%s-%s-%d" % [tag,page[1],palette,canvas.x])
				dock.body_scroll.scroll_vertical=int(dock.body.get_combined_minimum_size().y);await _settle()
				await _capture(viewport,output,"economy-%s-%s-bottom-%s-%d" % [tag,page[1],palette,canvas.x])
				if page[1]=="food":
					provider.short_food=true;dock.present(provider,0);dock.body_scroll.scroll_vertical=0;await _settle()
					await _capture(viewport,output,"economy-%s-food-shortage-%s-%d" % [tag,palette,canvas.x]);provider.short_food=false
			viewport.queue_free();await get_tree().process_frame
	fixture.free()
	print("POPUP_ECONOMY_CAPTURE PASS")
	get_tree().quit(0)

func _settle()->void:
	for frame in 12:await get_tree().process_frame
	await RenderingServer.frame_post_draw
func _capture(viewport:SubViewport,folder:String,label:String)->void:
	var path:=folder.path_join(label+".png")
	viewport.get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED ",path)
