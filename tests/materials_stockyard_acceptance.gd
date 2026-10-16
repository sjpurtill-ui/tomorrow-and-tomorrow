extends "res://tests/home_lives_journey_probe.gd"
## Actual terrain/HUD/provider acceptance. No player save is read or written.
## Private GPU runner + isolated Test userdata only.
## --out=<absolute directory> --mode=dark|light --case=early|mature|secondary
const Materials=preload("res://scripts/hud/materials_ledger.gd")
const Art=preload("res://scripts/hud/materials_art.gd")
const Sheet=preload("res://scripts/hud/econ_sheet.gd")
const BUSY_STOCKS:Array[String]=["Timber","Stone","Fiber Plants","Clay","Flint","Salt","Peat","Limestone","Fine Sand","Medicinal Plants"]
var output_directory:=""
var _captures:=0

func _ready()->void:
	case_name="early";capture_prefix="stockyard"
	if not "Test" in OS.get_user_data_dir():
		push_error("Stockyard acceptance requires isolated Test userdata");get_tree().quit(2);return
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="):case_name=argument.trim_prefix("--case=")
		elif argument.begins_with("--mode="):mode=argument.trim_prefix("--mode=")
		elif argument.begins_with("--prefix="):capture_prefix=argument.trim_prefix("--prefix=")
		elif argument.begins_with("--out="):output_directory=argument.trim_prefix("--out=").replace("\\","/")
	if not output_directory.is_absolute_path() or not mode in ["dark","light"] or not case_name in ["early","mature","secondary"]:
		push_error("Supply absolute --out, --mode=dark|light and --case=early|mature|secondary");get_tree().quit(2);return
	get_tree().create_timer(240.0).timeout.connect(func():get_tree().quit(3))
	var config:=ConfigFile.new();config.set_value("display","visual_system",1);config.set_value("display","color_theme",mode);config.save("user://display.cfg")
	_world("late" if case_name=="mature" else case_name)
	GameState.civic_api_enabled=false;GameState.select_founding_focus("provision");PeopleDirection.choose("makers");DiscoverySystem.initialize()
	get_window().size=Vector2i(1600,1000);get_window().content_scale_size=Vector2i(1600,1000)
	audit_terrain=load("res://local_terrain.tscn").instantiate();audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(50);audit_terrain.call("_set_game_speed",0)
	for system_name:String in WorldSimulation.OWNED_SYSTEMS:WorldSimulation.system(system_name).set_process(false)
	for director:Node in get_tree().get_nodes_in_group("court_director"):director.set_process(false)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(10)
	# Real private-world extraction/hauling rules produce the primary readings.
	# No prepared-material dictionary replaces the provider in these captures.
	if case_name=="mature":_prepare_busy_material_stocks()
	_sample_material_day()
	var hud:Control=audit_terrain.get("hud")
	var provider:Object=hud.providers.economy
	_expect(provider.get_script().resource_path=="res://scripts/hud/content/dock_content_economy.gd","Uses actual Economy provider")
	provider.tab(1) # Prepare established lazy caches before read-only audit.
	var before:=_ledger()
	hud.section_requested.emit("economy",1);hud.force_dock_layout();await _frames(16)
	var board:Control=hud.dock.find_child("MaterialsLedger",true,false)
	_expect(board!=null,"Actual Materials tab opens Working Stockyard")
	if board==null:get_tree().quit(1);return
	_expect(board.get_script()==Materials,"Actual renderer is materials_ledger.gd")
	_expect(_ledger()==before,"Opening stockyard preserves ledger, RNG and scope bindings")
	var identity:=board.get_instance_id()
	var controls:Array=board.find_children("*","",true,false)
	_check_readings(board)
	if case_name=="mature":_check_busy_material_stocks(board)
	_check_art()
	await _same_day_refresh(hud,provider,board)
	before=_ledger()
	for canvas:Vector2i in [Vector2i(1600,1000),Vector2i(1024,720),Vector2i(2869,1337)]:
		get_window().size=canvas;get_window().content_scale_size=canvas;hud.force_dock_layout();await _frames(14)
		hud.dock.body_scroll.scroll_vertical=0;await _frames(4)
		_check_layout(board,str(canvas.x))
		_expect(_ledger()==before,"Resizing remains read-only at "+str(canvas.x))
		await _capture("overview-"+str(canvas.x))
		# Genuine input chooses an available material, retaining the reader.
		if not board._rows.is_empty():
			var row:Dictionary=board._rows.back()
			var choice:Button=row.button
			var key:=String(row.key)
			hud.dock.body_scroll.ensure_control_visible(choice);await _frames(3)
			await _click(choice.get_global_rect().get_center());await _frames(8)
			_expect(String(provider.selected_material)==key,"Native tile click selects the exact material key")
			_expect(hud.dock.find_child("MaterialsLedger",true,false)==board,"Selection retains stockyard root")
			_expect(board.find_children("*","",true,false)==controls,"Selection retains controls, artwork and reader nodes")
			_expect(_ledger()==before,"Selection does not gather, trade or spend material")
		var sources:Button=board.find_child("WhereItComesFrom",true,false)
		if sources!=null and sources.is_visible_in_tree() and not sources.disabled:
			hud.dock.body_scroll.ensure_control_visible(sources);await _frames(3)
			sources.grab_focus();await _key(KEY_SPACE);await _frames(4)
			_expect(bool(provider.material_browse_state.get("sources_open",false)),"Keyboard opens known source details")
			_expect(_ledger()==before,"Known-source details do not survey new deposits")
		hud.dock.body_scroll.scroll_vertical=100000;await _frames(4)
		_check_layout(board,str(canvas.x)+" detail")
		await _capture("selected-detail-"+str(canvas.x))
		if bool(provider.material_browse_state.get("sources_open",false)):
			provider.material_browse_state.sources_open=false;hud.request_immediate_dock_refresh();await _frames(4)
	await _search_and_page(hud,provider,board)
	# A new real daily receipt must refresh without allocating another scene.
	GameState.elapsed_days+=1;_sample_material_day();before=_ledger()
	hud.live_refresh_dock();await _frames(10)
	_expect(board.get_instance_id()==identity and hud.dock.find_child("MaterialsLedger",true,false)==board,"New daily receipt retains stockyard")
	_expect(board.find_children("*","",true,false)==controls,"New daily receipt retains every UI node")
	_expect(_ledger()==before,"Live receipt refresh performs no extra resource step")
	_check_readings(board)
	if case_name=="mature":_check_busy_material_stocks(board)
	get_window().size=Vector2i(1024,720);get_window().content_scale_size=Vector2i(1024,720);hud.force_dock_layout();await _frames(12)
	hud.dock.body_scroll.scroll_vertical=0;await _frames(3);await _capture("live-update-1024")
	for target:Array in [["AssignExtractionWorkers","Extraction"],["AssignLogisticsWorkers","Logistics"]]:
		var button:Button=board.find_child(String(target[0]),true,false)
		_expect(button!=null and button.is_visible_in_tree(),"Existing assignment link is available: "+String(target[1]))
		if button==null:continue
		hud.dock.body_scroll.ensure_control_visible(button);await _frames(3);before=_ledger()
		await _click(button.get_global_rect().get_center());await _frames(16)
		var allocator:Control=hud.dock.find_child("CivilizationPeopleScreen",true,false)
		_expect(allocator!=null,"Assignment opens actual People screen")
		if allocator!=null:
			_expect(allocator.get_script().resource_path.ends_with("people_allocator_screen.gd"),"Uses active immediate allocator")
			_expect(String(allocator.active_role)==String(target[1]),"Assignment focuses "+String(target[1]))
		_expect(_ledger()==before,"Opening assignment does not issue an allocation command")
		hud.section_requested.emit("economy",1);hud.force_dock_layout();await _frames(12)
		board=hud.dock.find_child("MaterialsLedger",true,false)
		_expect(board!=null,"Stockyard remains reachable after assignment")
		if board==null:break
	print("MATERIALS_STOCKYARD_ACCEPTANCE ",checks," checks; ",_captures," captures; failures: ",failures)
	PlanetEnvironment.set_macro_bake_enabled(false);audit_terrain.queue_free();await _frames(2);get_tree().quit(0 if failures.is_empty() else 1)

func _prepare_busy_material_stocks()->void:
	# A deliberately overfilled private-world inventory exercises a busy yard.
	# Only real stock fields are prepared; process_day below must calculate the
	# carrying receipt, actual capacity and storage losses before the HUD reads it.
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->void:
		var capacities:Dictionary=SettlementModel.with_local_population(func()->Dictionary:return ResourceSystem.storage_capacities())
		var total_capacity:=0.0
		for amount:float in capacities.values():total_capacity+=amount
		var bulk_per_material:=maxf(1200.0,total_capacity*2.0)/float(BUSY_STOCKS.size())
		for key:String in BUSY_STOCKS:
			_expect(ResourceSystem.catalog.has(key) and ResourceSystem._is_material_resource(key),"Busy fixture uses a real stored material: "+key)
			var bulk_per_unit:=float(ResourceSystem.material_profile(key).bulk)
			GameState.resource_stockpiles[key]=maxf(float(GameState.resource_stockpiles.get(key,0)),bulk_per_material/bulk_per_unit))

func _check_busy_material_stocks(board:Control)->void:
	var shown:Dictionary=board.data
	var positive_catalogue:=0
	for row:Dictionary in shown.rows:
		var key:=String(row.key)
		if ResourceSystem.catalog.has(key) and key not in Materials.ELSEWHERE and float(row.stock)>0:positive_catalogue+=1
	_expect(positive_catalogue>=BUSY_STOCKS.size(),"Mature actual provider retains ten positive catalogue stocks after daily processing")
	_expect(bool(shown.get("capacity_known",false)) and float(shown.capacity)>0,"Busy yard has a measured engine capacity")
	_expect(float(shown.storage)>float(shown.capacity),"Mature capture shows real weighted overflow after storage losses")
	var actual:=_actual_materials();var lost:=0.0
	for amount:float in actual.metrics.get("losses_by_resource",{}).values():lost+=amount
	_expect(lost>0,"The real resource step records losses for the overfilled yard")
	_expect(board._rows.size()==8,"Busy inventory shows eight compact choices on its first page")
	var next:Button=board.find_child("NextMaterials",true,false)
	_expect(next!=null and next.is_visible_in_tree() and not next.disabled,"Busy actual inventory exposes its remaining materials through paging")

func _sample_material_day()->void:
	var context:Dictionary=audit_terrain.call("_discovery_context");context.traveling=false
	var record:Dictionary=SettlementModel.selected_settlement()
	var position:Vector2=record.get("position",Vector2.ZERO)
	context.origin=Vector3(position.x,0,position.y)
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->void:ResourceSystem.process_day(context))

func _ledger()->PackedByteArray:
	return var_to_bytes([super._ledger(),GameState.resource_deposits,GameState.material_metrics,GameState.resource_practice,
		GameState.resource_priorities,GameState.land_survey,GameState.strategic_history,GameState.simulation_metrics,
		GameState.water_metrics,GameState.city_trade_shipments,GameState.city_trade_history,GameState.known_discoveries])

func _actual_materials()->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:
		return {"stocks":GameState.resource_stockpiles.duplicate(true),"metrics":GameState.material_metrics.duplicate(true),
			"sites":ResourceSystem.visible_deposits().duplicate(true),"bulk":ResourceSystem.stored_bulk(),"city":SettlementModel.selected_settlement().get("name","")})

func _check_readings(board:Control)->void:
	var actual:=_actual_materials();var shown:Dictionary=board.data
	_expect(String(shown.city)==String(actual.city),"Reads the selected town's identity")
	var weighted:=0.0
	for key:String in actual.stocks:
		if key!="Food" and ResourceSystem._is_material_resource(key):weighted+=float(actual.stocks[key])*float(ResourceSystem.material_profile(key).bulk)
	_expect(is_equal_approx(float(shown.storage),weighted),"Yard occupancy is weighted material bulk, not a count of unlike units")
	_expect(is_equal_approx(float(shown.storage),float(actual.bulk)),"Weighted reading matches actual ResourceSystem yard accounting")
	_expect(is_equal_approx(float(shown.capacity),float(actual.metrics.get("storage_capacity",0))),"Capacity is the actual selected-town capacity")
	_expect(shown.get("hauling")==actual.metrics.get("flow_ratio",null),"Unknown carrying remains unknown; measured zero stays zero")
	var total_arrivals:=0.0;var total_loss:=0.0
	for row:Dictionary in shown.rows:
		var key:=String(row.key);var arrived:=0.0
		for site:Dictionary in actual.sites:
			if String(site.get("resource",""))==key:arrived+=float(site.get("delivered_today",0))
		_expect(is_equal_approx(float(row.stock),float(actual.stocks.get(key,0))),"Current stock retained for "+key)
		_expect(is_equal_approx(float(row.delivered),arrived),"Daily gross arrival is the actual source receipt for "+key)
		_expect(is_equal_approx(float(row.loss),float(actual.metrics.get("losses_by_resource",{}).get(key,0))),"Storage loss is the actual receipt for "+key)
		_expect(String(row.name)==ResourceSystem.display_name(key),"Name respects current discovery knowledge for "+key)
		if key not in Materials.ELSEWHERE:total_arrivals+=arrived;total_loss+=float(row.loss)
	var income:Dictionary=Materials.kpi_items(shown)[1]
	_expect(String(income.value)==("+"+Sheet.n(total_arrivals) if total_arrivals>=0.5 else "0"),"Gross arrivals are not reduced by storage loss or relabeled net")
	_expect(String(income.sub).contains(Sheet.n(total_loss)),"Storage losses remain stated separately")
	for row:Dictionary in board._rows:
		_expect(String(row.key) not in Materials.ELSEWHERE,"Elsewhere resource is excluded from material tiles")
		_expect(row.picture.texture!=null,"Displayed material has artwork or documented generic fallback")

func _same_day_refresh(hud:Control,provider:Object,board:Control)->void:
	var original:=_ledger();var snapshot:=_actual_materials()
	var signature:Array=provider.signature().duplicate(true);var nodes:Array=board.find_children("*","",true,false)
	var original_day:=float(GameState.elapsed_days)
	# Deliberately change the composition while keeping total weighted bulk.
	var amount:=minf(1.0,float(snapshot.stocks.get("Timber",0))*.1)
	_expect(amount>0,"Real fixture has timber for equal-bulk refresh regression")
	if amount>0:
		SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->void:
			GameState.resource_stockpiles.Timber=float(GameState.resource_stockpiles.Timber)-amount
			GameState.resource_stockpiles["Fiber Plants"]=float(GameState.resource_stockpiles.get("Fiber Plants",0))+amount*float(ResourceSystem.material_profile("Timber").bulk)/float(ResourceSystem.material_profile("Fiber Plants").bulk))
		var changed:=_ledger();var now:=_actual_materials()
		_expect(is_equal_approx(float(now.bulk),float(snapshot.bulk)),"Regression fixture preserves aggregate weighted bulk")
		_expect(provider.signature()!=signature,"Equal-bulk same-day stock swap invalidates provider")
		hud.live_refresh_dock();await _frames(8);_check_readings(board)
		_expect(_ledger()==changed,"Refresh does not alter the changed stock fixture")
		_expect(board.find_children("*","",true,false)==nodes,"Equal-bulk refresh keeps all controls")
		_restore_material_snapshot(snapshot)
		_expect(_ledger()==original,"Stock-swap fixture restores all audited state")
		hud.live_refresh_dock();await _frames(6)
	# Daily source/loss/carry reports may change without either day or stock.
	var deposits:Array[Dictionary]=GameState.resource_deposits.duplicate(true)
	var scoped:Dictionary=SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:
		return {"deposits":GameState.resource_deposits.duplicate(true),"metrics":GameState.material_metrics.duplicate(true)})
	signature=provider.signature().duplicate(true)
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->void:
		for site:Dictionary in GameState.resource_deposits:
			if String(site.get("stage","unknown"))!="unknown" and String(site.get("resource","")) not in Materials.ELSEWHERE:
				site.delivered_today=float(site.get("delivered_today",0))+2.0
				site.blockers=["Acceptance fixture: route temporarily blocked"]
				break
		GameState.material_metrics.flow_ratio=.37
		var losses:Dictionary=GameState.material_metrics.get("losses_by_resource",{}).duplicate(true);losses.Timber=.75
		GameState.material_metrics.losses_by_resource=losses)
	var changed_receipt:=_ledger()
	_expect(provider.signature()!=signature,"Same-day source and loss receipt invalidates provider")
	_expect(float(GameState.elapsed_days)==original_day,"Same-day tests never advance the day")
	hud.live_refresh_dock();await _frames(8);_check_readings(board)
	_expect(_ledger()==changed_receipt,"Reading changed receipt is not another extraction or hauling step")
	_expect(board.find_children("*","",true,false)==nodes,"Changed receipt preserves every control")
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->void:
		GameState.resource_deposits.assign(scoped.deposits)
		GameState.material_metrics.clear();GameState.material_metrics.merge(scoped.metrics,true))
	_expect(GameState.resource_deposits==deposits,"Scoped source fixture restores outer deposit binding")
	_expect(_ledger()==original,"Receipt fixture restores all audited state")
	hud.live_refresh_dock();await _frames(6)

func _restore_material_snapshot(snapshot:Dictionary)->void:
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->void:
		GameState.resource_stockpiles.clear();GameState.resource_stockpiles.merge(snapshot.stocks,true))

func _search_and_page(hud:Control,provider:Object,board:Control)->void:
	var search:LineEdit=board.find_child("FindMaterial",true,false)
	if search==null or not search.is_visible_in_tree():return
	var before:=_ledger();var nodes:Array=board.find_children("*","",true,false)
	var selected:=String(provider.selected_material)
	search.text="timber";search.text_changed.emit(search.text);await _frames(3)
	_expect(board._rows.size()==1 and String(board._rows[0].key)=="Timber","Search matches the known material")
	_expect(String(provider.selected_material)==selected,"Searching keeps the selected reader")
	var scroll:=int(hud.dock.body_scroll.scroll_vertical)
	hud.live_refresh_dock();await _frames(5)
	_expect(search.text=="timber" and String(provider.material_browse_state.query)=="timber","Live refresh keeps search")
	_expect(int(hud.dock.body_scroll.scroll_vertical)==scroll,"Live refresh does not move the reader scroll")
	search.text="";search.text_changed.emit("");await _frames(3)
	var next:Button=board.find_child("NextMaterials",true,false)
	if next!=null and not next.disabled:
		hud.dock.body_scroll.ensure_control_visible(next);await _frames(3);next.grab_focus();await _key(KEY_SPACE);await _frames(3)
		_expect(int(provider.material_browse_state.page)==1,"Keyboard pages the actual inventory")
		_expect(board._rows.size()<=8,"Every inventory page remains bounded")
		provider.material_browse_state.page=0;hud.request_immediate_dock_refresh();await _frames(4)
	_expect(board.find_children("*","",true,false)==nodes,"Search and paging keep the reader and tile controls")
	_expect(_ledger()==before,"Searching and paging do not alter simulation state")

func _check_art()->void:
	var count:=0
	for key:String in ResourceSystem.catalog:
		if key in Materials.ELSEWHERE:continue
		count+=1;var picture:Texture2D=Art.texture_for(key)
		_expect(picture!=null and picture.get_width()>0 and picture.get_height()>0,"Real imported artwork loads for "+key)
	_expect(count==34,"All34 catalogue entries that can reach Materials are covered")
	_expect(Art.texture_for("Retained imported specimen")!=null,"Unrecognized saved stock has a generic fallback")

func _check_layout(board:Control,label:String)->void:
	var bounds:=board.get_global_rect();var viewport:=get_viewport().get_visible_rect()
	_expect(board.get_combined_minimum_size().x<=board.size.x+1,"No minimum-width overflow at "+label)
	_expect(bounds.position.x>=-1 and bounds.end.x<=viewport.end.x+1,"Stockyard fits viewport at "+label)
	for control:Control in board.find_children("*","Control",true,false):
		if not control.is_visible_in_tree() or control.size.x<1:continue
		var rect:=control.get_global_rect()
		_expect(rect.position.x>=bounds.position.x-2 and rect.end.x<=bounds.end.x+2,"Visible child fits stockyard: "+String(control.name)+" at "+label)
	_expect(board._rows.size()<=8,"At most8 material choices at "+label)
	for row:Dictionary in board._rows:
		var picture:TextureRect=row.picture
		var button:Button=row.button
		_expect(picture.is_visible_in_tree() and picture.size.x>=30 and picture.size.y>=30,"Material icon remains legible at "+label)
		_expect(button.size.y>=40 and button.size.y<=48,"Compact material row remains an accessible 40–48px target at "+label)
		_expect(button.get_global_rect().grow(2).encloses(picture.get_global_rect()),"Artwork stays within its selectable row at "+label)

func _capture(label:String)->void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output_directory)
	var path:=output_directory.path_join("%s-%s-%s-%s.png" % [capture_prefix,case_name,mode,label])
	var error:=get_viewport().get_texture().get_image().save_png(path)
	_expect(error==OK,"Capture written: "+label);_captures+=1;print("MATERIALS_STOCKYARD_CAPTURE ",path)
