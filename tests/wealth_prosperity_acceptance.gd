extends "res://tests/home_lives_journey_probe.gd"
## Actual terrain, Wealth provider and purse commands on a disposable world.
## Private GPU runner / Test userdata only; no player save or network is used.
## --out=<absolute directory> --case=early|mature --mode=dark|light --prefix=final
const WealthBoard=preload("res://scripts/hud/purse_board.gd")
const Purse=preload("res://scripts/realm_purse.gd")
const Business=preload("res://scripts/enterprise.gd")
const Goods=preload("res://scripts/civilian_goods.gd")
const Sheet=preload("res://scripts/hud/econ_sheet.gd")
const Tracker=preload("res://scripts/order_tracker.gd")
var output_directory:=""
var captures:=0

func _ready()->void:
	case_name="early";capture_prefix="prosperity"
	if not "Test" in OS.get_user_data_dir():
		push_error("Wealth acceptance requires isolated Test userdata");get_tree().quit(2);return
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):output_directory=argument.trim_prefix("--out=").replace("\\","/")
		elif argument.begins_with("--case="):case_name=argument.trim_prefix("--case=")
		elif argument.begins_with("--mode="):mode=argument.trim_prefix("--mode=")
		elif argument.begins_with("--prefix="):capture_prefix=argument.trim_prefix("--prefix=")
	if not output_directory.is_absolute_path() or not case_name in ["early","mature"] or not mode in ["dark","light"]:
		push_error("Supply absolute --out, --case=early|mature, --mode=dark|light");get_tree().quit(2);return
	get_tree().create_timer(240.0).timeout.connect(func():get_tree().quit(3))
	var config:=ConfigFile.new();config.set_value("display","visual_system",1);config.set_value("display","color_theme",mode);config.save("user://display.cfg")
	_world("late" if case_name=="mature" else "early")
	GameState.civic_api_enabled=false;GameState.select_founding_focus("provision");PeopleDirection.choose("makers");DiscoverySystem.initialize()
	if case_name=="mature":_prepare_currency()
	get_window().size=Vector2i(1600,1000);get_window().content_scale_size=Vector2i(1600,1000)
	audit_terrain=load("res://local_terrain.tscn").instantiate();audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(50);audit_terrain.call("_set_game_speed",0)
	for system_name:String in WorldSimulation.OWNED_SYSTEMS:WorldSimulation.system(system_name).set_process(false)
	for director:Node in get_tree().get_nodes_in_group("court_director"):director.set_process(false)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(10)
	# All primary figures come from the actual economy/purse and provider.
	_sample_economy_day()
	var hud:Control=audit_terrain.get("hud");var provider:Object=hud.providers.economy
	_expect(provider.get_script().resource_path=="res://scripts/hud/content/dock_content_economy.gd","Uses the real Economy provider")
	Purse.state();Purse.forecast();Purse.sources();Business.state();WealthBoard.kpis();provider.tab(2)
	hud.section_requested.emit("economy",2);hud.force_dock_layout();await _frames(16)
	var board:Control=hud.dock.find_child("PurseBoard",true,false)
	_expect(board!=null and board.get_script()==WealthBoard,"Actual Wealth route opens the new purse board")
	if board==null:get_tree().quit(1);return
	var view:Control=board.find_child("ProsperityAndPressure",true,false)
	_expect(view!=null,"Actual provider mounts Prosperity and Pressure")
	if view==null:get_tree().quit(1);return
	var primary_nodes:Array=view.find_children("*","",true,false)
	var identity:=board.get_instance_id()
	var before:=_ledger();board.refresh();hud.live_refresh_dock();await _frames(8)
	_expect(_ledger()==before,"Opening and refreshing the initialized Wealth view changes no audited ledger or RNG")
	_expect(Purse.in_kind()==(case_name=="early"),"Fixture exercises its intended goods or currency phase")
	_check_readings(board)
	for canvas:Vector2i in [Vector2i(1600,1000),Vector2i(1024,720),Vector2i(2869,1337)]:
		before=_ledger();get_window().size=canvas;get_window().content_scale_size=canvas;hud.force_dock_layout();await _frames(14)
		hud.dock.body_scroll.scroll_vertical=0;await _frames(4)
		_check_layout(board,str(canvas.x));_check_initial_reading(hud,board,str(canvas.x));_expect(_ledger()==before,"Resizing Wealth stays read-only at "+str(canvas.x))
		await _capture("overview-"+str(canvas.x))
		var choice:Button=view.levels.heavy
		hud.dock.body_scroll.ensure_control_visible(choice);await _frames(4)
		await _capture("decisions-"+str(canvas.x))
		await _exercise_commands(hud,board,view)
		_expect(view.find_children("*","",true,false)==primary_nodes,"Commands retain all primary controls at "+str(canvas.x))
		await _open_details(hud,board,"account")
		_check_layout(board,str(canvas.x)+" account");await _capture("account-"+str(canvas.x))
		await _close_details(hud,board)
	await _exercise_details(hud,board)
	# Actual day processing changes wealth, demand and purse receipts. Reading it
	# again must not itself collect another levy or pay another wage.
	GameState.elapsed_days+=1;_sample_economy_day();before=_ledger()
	var focus:Button=view.levels.usual;hud.dock.body_scroll.ensure_control_visible(focus);await _frames(3);focus.grab_focus()
	var scroll:=int(hud.dock.body_scroll.scroll_vertical)
	hud.live_refresh_dock();board.refresh();await _frames(8)
	_expect(hud.dock.find_child("PurseBoard",true,false).get_instance_id()==identity,"New-day provider update retains the board")
	_expect(view.find_children("*","",true,false)==primary_nodes,"Daily changes retain the primary controls")
	_expect(get_viewport().gui_get_focus_owner()==focus,"Daily refresh retains keyboard focus")
	_expect(int(hud.dock.body_scroll.scroll_vertical)==scroll,"Daily refresh does not jump scroll")
	_expect(_ledger()==before,"Live reading does not run another economy step")
	_check_readings(board)
	get_window().size=Vector2i(1024,720);get_window().content_scale_size=Vector2i(1024,720);hud.force_dock_layout();await _frames(12)
	hud.dock.body_scroll.scroll_vertical=0;await _frames(3);_check_layout(board,"live narrow");_check_initial_reading(hud,board,"live narrow");await _capture("live-update-1024")
	print("WEALTH_PROSPERITY_ACCEPTANCE ",checks," checks; ",captures," captures; failures: ",failures)
	PlanetEnvironment.set_macro_bake_enabled(false);audit_terrain.queue_free();await _frames(2);get_tree().quit(0 if failures.is_empty() else 1)

func _prepare_currency()->void:
	# Real state preparation, not invented renderer readings. The original
	# purse migration and economy day account for these saved-style holdings.
	GameState.economy_stage="currency"
	for id:String in ["property_registers","tallies"]:
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0
	DiscoverySystem.refresh_operating_effects()
	GameState.private_currency=7600.0;GameState.public_treasury=800.0;GameState.currency_hoards=800.0;GameState.mutual_aid_reserve=400.0;GameState.currency_supply=9600.0
	GameState.monetary_reserve_metals={"Copper Ore":3840.0}
	GameState.resource_stockpiles[Goods.GOODS]=6000.0
	var home:Vector2=SettlementModel.settlement_record(SettlementModel._primary_settlement_id()).get("position",Vector2.ZERO)
	GameState.player_settlements.append({"id":"wealth_rivermeet","name":"Rivermeet","position":home+Vector2(15,5),"primary":false,"population_share":.15,"founded_day":100})
	SettlementModel.with_city_resources("wealth_rivermeet",func()->void:
		GameState.resource_stockpiles[Goods.GOODS]=400.0
		GameState.food_stocks={"Fresh food":0.0,"Stored food":180.0};GameState.resource_stockpiles.Food=180.0
		GameState.simulation_metrics.food_consumption=360.0)
	GameState.realm_purse={};Purse.state();Purse.stage()
	Purse.set_line("crews",true);Purse.set_line("scholars",true)

func _sample_economy_day()->void:
	var context:Dictionary=audit_terrain.call("_discovery_context");context.traveling=false
	for town:Dictionary in GameState.player_settlements:
		SettlementModel.with_city_resources(String(town.id),func()->void:
			SettlementModel.with_local_population(func()->void:EconomySystem.process_day(context)))
	Purse.forecast();Business.state()
	Tracker.update(int(GameState.elapsed_days))

func _ledger()->PackedByteArray:
	return var_to_bytes([super._ledger(),GameState.realm_purse,GameState.enterprise,GameState.wealth_shares,
		GameState.economy_metrics,GameState.economy_history,GameState.market_prices,GameState.economy_stage,
		GameState.currency_supply,GameState.private_currency,GameState.public_treasury,GameState.currency_hoards,
		GameState.mutual_aid_reserve,GameState.monetary_reserve_metals,GameState.public_debt,GameState.military_arrears,
		GameState.civil_arrears,GameState.order_tracker,GameState.active_modifiers,GameState.civilian_goods,
		GameState.city_trade_shipments,GameState.city_trade_history])

func _check_readings(board:Control)->void:
	var view:Control=board.find_child("ProsperityAndPressure",true,false)
	var forecast:=Purse.forecast();var purse:=Purse.state();var season:=Purse.season()
	_expect(view.fifths.values==Array(GameState.wealth_shares),"Five equal household groups show their real wealth shares")
	for index in 5:_expect(view.quintiles[index].text==Sheet.n(float(GameState.wealth_shares[index])*100.0)+"%","Group "+str(index)+" uses wealth share, not population")
	_expect(String(view.refs.share_note.text).contains("not numbers of people"),"Wealth percentages explicitly distinguish population")
	_expect(String(view.refs.store.text)==Purse.amount_text(float(forecast.balance)),"Public balance matches the single real purse")
	var parts:Dictionary=GameState.economy_metrics.get("social_pressure_parts",{})
	var known:=parts.has("total") and parts.get("total")!=null
	_expect(bool(view.data.pressure_known)==known,"Missing pressure remains unknown")
	if known:_expect(is_equal_approx(float(view.data.pressure),float(parts.total)*100.0),"Trust target contribution preserves the engine sign and benefit")
	_expect(String(view.refs.forecast.text).to_lower().contains("forecast"),"Current-setting outlook is labeled forecast")
	_expect(String(view.refs.forecast.tooltip_text).contains(Purse.number(float(season.total_in))) and String(view.refs.forecast.tooltip_text).contains(Purse.number(float(season.total_out))),"Recorded receipts remain distinct from the current forecast")
	for level:String in Purse.LEVELS:_expect(view.levels[level].button_pressed==(level==String(purse.levy)),"Levy selection agrees with the real policy")
	for key:String in ["crews","scholars","army"]:
		var entry:Dictionary=forecast.lines[key];var row:Dictionary=view.funding[key]
		_expect(row.toggle.button_pressed==bool(entry.on),"Funding state is current for "+key)
		_expect(String(row.cost.text).contains(Purse.amount_text(float(entry.per_season))),"Funding cost uses actual seasonal quote for "+key)
		_expect(String(row.who.text)==String(entry.who),"Funding population reading agrees with original rules for "+key)

func _exercise_commands(hud:Control,board:Control,view:Control)->void:
	var prior_level:=String(Purse.state().levy);var target:="light" if prior_level=="heavy" else "heavy"
	var button:Button=view.levels[target]
	hud.dock.body_scroll.ensure_control_visible(button);await _frames(4)
	var rect:=button.get_global_rect();var balance:=Purse.balance();var original_history:=Purse.history().size()
	await _click(rect.get_center());await _frames(6)
	_expect(String(Purse.state().levy)==target,"Native levy click reaches original Purse.set_levy")
	_expect(Purse.history().size()==original_history+1,"One levy click records one real purse setting")
	_expect(is_equal_approx(Purse.balance(),balance),"Selecting levy does not invent current receipts")
	_expect(button.get_global_rect().is_equal_approx(rect),"Levy control stays in place after selection")
	# Keyboard returns to the original level through the same real command.
	var restore:Button=view.levels[prior_level];restore.grab_focus();await _key(KEY_SPACE);await _frames(4)
	_expect(String(Purse.state().levy)==prior_level,"Keyboard levy action reaches the same command")
	for key:String in ["crews","scholars","army"]:
		var toggle:BaseButton=view.funding[key].toggle;var was_on:=Purse.line_on(key)
		hud.dock.body_scroll.ensure_control_visible(toggle);await _frames(4)
		var toggle_rect:=toggle.get_global_rect();balance=Purse.balance()
		await _click(toggle_rect.get_center());await _frames(4)
		_expect(Purse.line_on(key)!=was_on,"Native funding click toggles original "+key+" policy")
		_expect(is_equal_approx(Purse.balance(),balance),"Enabling a pay line does not instantly charge a fictional season")
		_expect(toggle.get_global_rect().is_equal_approx(toggle_rect),"Funding control remains fixed for "+key)
		toggle.grab_focus();await _key(KEY_SPACE);await _frames(4)
		_expect(Purse.line_on(key)==was_on,"Keyboard returns "+key+" to original policy using fresh state")
	_check_readings(board)

func _open_details(hud:Control,board:Control,key:String)->void:
	var before:=_ledger();var button:Button=board.find_child("WealthDetail_"+key,true,false)
	_expect(button!=null and button.is_visible_in_tree(),"Original secondary task remains reachable: "+key)
	if button==null:return
	hud.dock.body_scroll.ensure_control_visible(button);await _frames(3);await _click(button.get_global_rect().get_center());await _frames(5)
	_expect(String(board.open_detail)==key,"Details open in place: "+key)
	_expect(_ledger()==before,"Reading "+key+" does not execute a command")
	hud.dock.body_scroll.scroll_vertical=100000;await _frames(4)

func _close_details(hud:Control,board:Control)->void:
	if String(board.open_detail).is_empty():return
	var button:Button=board.detail_buttons[String(board.open_detail)]
	hud.dock.body_scroll.ensure_control_visible(button);await _frames(3);button.grab_focus();await _key(KEY_SPACE);await _frames(4)
	_expect(String(board.open_detail).is_empty(),"Keyboard closes secondary detail")

func _exercise_details(hud:Control,board:Control)->void:
	if case_name=="mature":
		await _open_details(hud,board,"account")
		var sources:Button=board.find_child("TownContributions",true,false)
		_expect(sources!=null and sources.is_visible_in_tree(),"Actual multi-town contributions remain reachable")
		if sources!=null:
			var before:=_ledger();hud.dock.body_scroll.ensure_control_visible(sources);await _frames(3)
			sources.grab_focus();await _key(KEY_SPACE);await _frames(4)
			_expect(board.sources_open,"Keyboard expands the real town receipts")
			var rows:Array=board.sources_box.find_children("Row_*","PanelContainer",true,false)
			_expect(rows.size()==mini(8,Purse.sources().towns.size()),"Contributions show exact bounded engine towns")
			_expect(_ledger()==before,"Reading town contributions does not collect another levy")
		var relief:Control=board.find_child("Line_relief",true,false)
		_expect(relief!=null and relief.is_visible_in_tree(),"Multi-town food-relief command remains available")
		if relief!=null:
			var toggle:BaseButton=relief.find_child("Toggle",true,false);var was_on:=Purse.line_on("relief")
			hud.dock.body_scroll.ensure_control_visible(toggle);await _frames(3);toggle.grab_focus();await _key(KEY_SPACE);await _frames(4)
			_expect(Purse.line_on("relief")!=was_on,"Food-relief toggle still uses the real purse command")
			# The legacy relief section rebuilds; reacquire its current switch.
			toggle=board.find_child("Line_relief",true,false).find_child("Toggle",true,false)
			hud.dock.body_scroll.ensure_control_visible(toggle);await _frames(3);toggle.grab_focus();await _key(KEY_SPACE);await _frames(4)
			_expect(Purse.line_on("relief")==was_on,"Repeated relief action uses fresh current state")
		await _capture("town-contributions");await _close_details(hud,board)
	for key:String in ["households","business","work"]:
		await _open_details(hud,board,key)
		if key=="households":
			var buy:Button=board.find_child("BuyingPower",true,false)
			_expect(buy!=null and buy.is_visible_in_tree(),"Original buying-power comparison remains reachable")
			if buy!=null:
				var before:=_ledger();hud.dock.body_scroll.ensure_control_visible(buy);await _frames(3);buy.grab_focus();await _key(KEY_SPACE);await _frames(3)
				_expect(board.find_child("GoodsEquivalents",true,false).is_visible_in_tree(),"Buying power expands with keyboard")
				_expect(_ledger()==before,"Comparing buying power does not spend goods")
		_check_layout(board,"detail "+key);await _capture("detail-"+key);await _close_details(hud,board)

func _check_layout(board:Control,label:String)->void:
	var bounds:=board.get_global_rect();var viewport:=get_viewport().get_visible_rect()
	_expect(board.get_combined_minimum_size().x<=board.size.x+1,"No horizontal minimum overflow at "+label)
	_expect(bounds.position.x>=-1 and bounds.end.x<=viewport.end.x+1,"Wealth fits viewport at "+label)
	for control:Control in board.find_children("*","Control",true,false):
		if not control.is_visible_in_tree() or control.size.x<1:continue
		var rect:=control.get_global_rect()
		_expect(rect.position.x>=bounds.position.x-2 and rect.end.x<=bounds.end.x+2,"Visible Wealth control fits: "+String(control.name)+" at "+label)
		if control is Label and control.autowrap_mode!=TextServer.AUTOWRAP_OFF and not control.text.is_empty():
			# Being horizontally contained is insufficient: a column one letter
			# wide can still pass containment while making the whole page unusable.
			var font:Font=control.get_theme_font("font");var font_size:int=control.get_theme_font_size("font_size")
			var longest_word:=0.0
			for word:String in control.text.replace("\n"," ").split(" ",false):longest_word=maxf(longest_word,font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
			_expect(control.size.x+2>=minf(longest_word,160.0),"Wrapped reading has room for whole words: "+String(control.name)+" at "+label)
	var picture:Control=board.find_child("ProsperityPainting",true,false)
	_expect(picture!=null and picture.size.x>200 and picture.size.y>=140,"Household painting remains substantial at "+label)
	if picture!=null:_expect(picture.texture!=null,"Approved household painting is loaded")
	for key:String in ["light","usual","heavy"]:
		var choice:Button=board.find_child("Level_"+key,true,false)
		_expect(choice!=null and choice.is_visible_in_tree() and choice.size.y>=36,"Levy action is readable and reachable: "+key)

func _check_initial_reading(hud:Control,board:Control,label:String)->void:
	var view:Control=board.find_child("ProsperityAndPressure",true,false)
	var totals:Control=view.refs.store.get_parent()
	var header:Control=totals.get_parent()
	_expect(header.size.y<=110.0,"Initial Wealth header stays compact rather than becoming a vertical text column at "+label)
	_expect(totals.size.x>=160.0,"Wealth totals retain a readable column at "+label)
	for reading:Label in [view.refs.households,view.refs.store,view.refs.store_name]:
		_expect(reading.get_theme_font_size("font_size")>=14,"Header totals retain readable type at "+label)
		_expect(reading.get_line_count()<=3,"Header total does not wrap one character per line at "+label)
	var picture:Control=view.picture
	var window:Rect2=hud.dock.body_scroll.get_global_rect()
	var art:Rect2=picture.get_global_rect()
	_expect(art.position.y<=window.position.y+minf(200.0,window.size.y*.4),"The initial page reaches its painting within the first useful reading region at "+label)
	_expect(art.intersection(window).size.y>=minf(140.0,picture.size.y),"A substantial part of the painting is visible before scrolling at "+label)

func _capture(label:String)->void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output_directory)
	var path:=output_directory.path_join("%s-%s-%s-%s.png" % [capture_prefix,case_name,mode,label])
	_expect(get_viewport().get_texture().get_image().save_png(path)==OK,"Capture written: "+label)
	captures+=1;print("WEALTH_PROSPERITY_CAPTURE ",path)
