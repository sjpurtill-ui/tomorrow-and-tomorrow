extends Node
## Disposable, in-memory UI fixtures. No campaign is loaded or saved.
const T=preload("res://scripts/hud/hud_tokens.gd")
const Dock=preload("res://scripts/hud/dock_panel.gd")
const Folio=preload("res://scripts/hud/reference_folio.gd")
const WealthFixture=preload("res://tests/wealth_visual_acceptance_probe.gd")
const TradeFixture=preload("res://tests/trade_visual_acceptance_probe.gd")
const FoodFixture=preload("res://tests/test_food_folio.gd")
const MaterialsFixture=preload("res://tests/test_materials_ledger_presentation.gd")
var _bounds_errors:Array[String]=[]

class CaptureHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Control
	var detail_provider:Object
	func request_immediate_dock_refresh()->void:pass
	func open_detail(provider:Object)->void:detail_provider=provider

class CaptureTerrain extends Node:
	func _toggle_resource_view()->void:pass
	func _report_military_action(_result:Dictionary)->void:pass

class FoodProvider extends "res://scripts/hud/content/dock_content_economy.gd":
	var short_food:=false
	var prepared_materials:=false
	var abundant_materials:=false
	func _materials_data()->Dictionary:
		var result:=super._materials_data()
		if prepared_materials or abundant_materials:
			var fixture:=MaterialsFixture.abundant_materials() if abundant_materials else MaterialsFixture.prepared_materials()
			if abundant_materials:
				fixture.storage=1426.0;fixture.capacity=918.0;fixture.hauling=0.64
				fixture.rows[0].stock=0.0;fixture.rows[0].delivered=178.0;fixture.rows[0].loss=15.0
				fixture.rows[0].points=[{"day":0,"value":90.0},{"day":30,"value":55.0},{"day":60,"value":0.0}]
			for key:String in fixture:
				if not key.begins_with("on_"):result[key]=fixture[key]
			result.selected=selected_material
			result.browse_state=material_browse_state
		return result
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
	var trade_ids:Array=[]
	if _arg("page","all")=="trade":trade_ids=TradeFixture.prepare_fixture(_arg("state","barter"))
	else:fixture._fixture(_arg("state","opening"))
	if _arg("history","")=="filled":
		var scope:=GameState.selected_player_settlement_id
		for index in 13:
			var values:={"private_currency":11000.0+index*300.0,"hoards":1700.0+index*50.0,"aid":240.0+index*20.0}
			preload("res://scripts/strategic_history.gd").record(GameState.strategic_history,int(GameState.elapsed_days)-360+index*30,{scope:values})
	var output:=_arg("out",OS.get_user_data_dir())
	var tag:=_arg("tag","capture")
	var terrain:=CaptureTerrain.new();add_child(terrain)
	var hud:=CaptureHud.new();add_child(hud)
	var provider:=FoodProvider.new(terrain,hud)
	if _arg("page","all")=="deliveries" and _arg("state","")=="filled":
		var day:=int(GameState.elapsed_days)
		var home:=GameState.selected_player_settlement_id
		GameState.society_capacities.logistics=0.45;GameState.society_capacities.institutions=0.3
		GameState.city_trade_shipments.assign([{"source_id":home,"source_name":"Reedwater","destination_id":"river","destination_name":"Long Willow River","resource":"Timber","quantity":24.0,"arrival_day":day+5},{"source_id":"river","source_name":"Long Willow River","destination_id":home,"destination_name":"Reedwater","resource":"Food","quantity":110.0,"arrival_day":day+1}])
		GameState.city_trade_history.assign([{"source_id":"river","source_name":"Long Willow River","destination_id":home,"destination_name":"Reedwater","resource":"Stone","delivered":5.0,"day":day-3,"status":"delivered"}])
	var canvases:Array[Vector2i]=[Vector2i(1440,900),Vector2i(1000,760)]
	if _arg("canvases","")!="":
		canvases.clear()
		for dimensions:String in _arg("canvases","").split(","):
			canvases.append(Vector2i(int(dimensions.get_slice("x",0)),int(dimensions.get_slice("x",1))))
	for canvas:Vector2i in canvases:
		for palette:String in ["dark","light"]:
			T.set_color_mode(palette)
			var viewport:=SubViewport.new();viewport.size=canvas;viewport.gui_embed_subwindows=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
			var background:=ColorRect.new();background.color=T.PAPER_SUNK;background.size=Vector2(canvas);viewport.add_child(background)
			var dock:=Dock.new();dock.theme=T.control_theme();dock.position=Vector2(24,20);dock.size=Vector2(Folio.page_width(canvas.x),canvas.y-40);viewport.add_child(dock);hud.dock=dock
			for page:Array in [[0,"food"],[1,"materials"],[2,"wealth"],[3,"trade"],[0,"deliveries"]]:
				if _arg("page","all")!="all" and _arg("page","all")!=String(page[1]):continue
				if page[1]=="deliveries":
					provider.focused_action("Deliveries between places","",provider._economy_report.bind("trade")).on_press.call()
					dock.present(hud.detail_provider,0);hud.detail_provider=null
				else:dock.present(provider,int(page[0]))
				await _settle()
				await _capture(viewport,output,"economy-%s-%s-%s-%d" % [tag,page[1],palette,canvas.x])
				dock.body_scroll.scroll_vertical=int(dock.body.get_combined_minimum_size().y);await _settle()
				await _capture(viewport,output,"economy-%s-%s-bottom-%s-%d" % [tag,page[1],palette,canvas.x])
				if page[1]=="food":
					provider.short_food=true;dock.present(provider,0);dock.body_scroll.scroll_vertical=0;await _settle()
					await _capture(viewport,output,"economy-%s-food-shortage-%s-%d" % [tag,palette,canvas.x]);provider.short_food=false
				if page[1]=="materials":
					provider.selected_material="Timber";dock.present(provider,1);dock.body_scroll.scroll_vertical=0;await _settle()
					await _capture(viewport,output,"economy-%s-material-sources-%s-%d" % [tag,palette,canvas.x])
					dock.body_scroll.scroll_vertical=int(dock.body.get_combined_minimum_size().y);await _settle()
					await _capture(viewport,output,"economy-%s-material-sources-bottom-%s-%d" % [tag,palette,canvas.x]);provider.selected_material=""
					provider.prepared_materials=true;provider.selected_material="Timber";dock.present(provider,1);dock.body_scroll.scroll_vertical=0;await _settle()
					await _capture(viewport,output,"economy-%s-material-active-sources-%s-%d" % [tag,palette,canvas.x])
					dock.body_scroll.scroll_vertical=int(dock.body.get_combined_minimum_size().y);await _settle()
					await _capture(viewport,output,"economy-%s-material-active-sources-bottom-%s-%d" % [tag,palette,canvas.x]);provider.selected_material="";provider.prepared_materials=false
					provider.abundant_materials=true;provider.selected_material="Timber";dock.present(provider,1);dock.body_scroll.scroll_vertical=0;await _settle()
					await _capture(viewport,output,"economy-%s-material-chooser-%s-%d" % [tag,palette,canvas.x])
					(dock.find_child("NextMaterials",true,false) as Button).pressed.emit();await _settle()
					await _capture(viewport,output,"economy-%s-material-next-%s-%d" % [tag,palette,canvas.x])
					(dock.find_child("WhereItComesFrom",true,false) as Button).pressed.emit();await _settle()
					await _capture(viewport,output,"economy-%s-material-places-%s-%d" % [tag,palette,canvas.x])
					provider.selected_material="";provider.abundant_materials=false;provider.material_browse_state.clear()
				if page[1]=="wealth" and _arg("state","opening")=="coin":
					provider.selected_account="private_currency";dock.present(provider,2);await _settle()
					var ledger:=dock.find_child("WealthLedger",true,false) as Control
					dock.body_scroll.scroll_vertical+=int(ledger.global_position.y-dock.body_scroll.global_position.y);await _settle()
					await _capture(viewport,output,"economy-%s-wealth-accounts-%s-%d" % [tag,palette,canvas.x])
					for button:Button in dock.find_children("*","Button",true,false):
						if button.text=="Past balances":button.pressed.emit();break
					if hud.detail_provider!=null:
						dock.present(hud.detail_provider,0);dock.body_scroll.scroll_vertical=0;await _settle()
						await _capture(viewport,output,"economy-%s-wealth-history-%s-%d" % [tag,palette,canvas.x]);hud.detail_provider=null
					provider.selected_account=""
				if page[1]=="trade" and not trade_ids.is_empty() and _arg("state","barter")!="word":
					var board:=dock.find_child("TradeBoard",true,false)
					if not bool(board.expanded_people.get(String(trade_ids[0]),false)):board._toggle_people(String(trade_ids[0]))
					dock.body_scroll.scroll_vertical=0;await _settle()
					await _capture(viewport,output,"economy-%s-trade-terms-%s-%d" % [tag,palette,canvas.x])
					dock.body_scroll.scroll_vertical=int(dock.body.get_combined_minimum_size().y);await _settle()
					await _capture(viewport,output,"economy-%s-trade-terms-bottom-%s-%d" % [tag,palette,canvas.x])
					for menu_name:String in ["Stance_squeeze","BuyWithGoods"]:
						var partner:=board.find_child("People_"+String(trade_ids[0]),true,false)
						var menu:=partner.find_child(menu_name,true,false) as MenuButton
						if menu==null or menu.disabled:continue
						dock.body_scroll.ensure_control_visible(menu);await _settle()
						menu.show_popup();await _settle()
						await _capture(viewport,output,"economy-%s-trade-%s-%s-%d" % [tag,menu_name,palette,canvas.x]);menu.get_popup().hide();await _settle()
			viewport.queue_free();await get_tree().process_frame
	fixture.free()
	if _arg("page","all")=="trade":TradeFixture.cleanup_fixture()
	for error:String in _bounds_errors:push_error(error)
	print("POPUP_ECONOMY_CAPTURE ","PASS" if _bounds_errors.is_empty() else "FAIL")
	get_tree().quit(0 if _bounds_errors.is_empty() else 1)

func _settle()->void:
	for frame in 12:await get_tree().process_frame
	await RenderingServer.frame_post_draw
func _capture(viewport:SubViewport,folder:String,label:String)->void:
	var dock:=viewport.get_child(1) as Control
	var expected:=Folio.page_width(viewport.size.x)
	if dock.size.x>expected+1.0:_bounds_errors.append("%s dock width %.1f exceeds %.1f" % [label,dock.size.x,expected])
	var path:=folder.path_join(label+".png")
	viewport.get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED ",path)
