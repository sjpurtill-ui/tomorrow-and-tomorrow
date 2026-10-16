extends "res://tests/own_town_capture.gd"
## Actual Home provider/HUD acceptance. Only on the private GPU test desktop,
## with isolated Test user data. Never reads or writes a player's save.
const Lives=preload("res://scripts/hud/home_lives_model.gd")
const Preview=preload("res://scripts/hud/workforce_preview.gd")
var failures:Array[String]=[]
var checks:=0
var audit_terrain:Node
var capture_prefix:="home-lives"
var case_name:="hearth"
var mode:="dark"

func _ready()->void:
	if not "Test" in OS.get_user_data_dir():push_error("Home journey requires isolated Test data");get_tree().quit(2);return
	get_tree().create_timer(240.0).timeout.connect(func():get_tree().quit(3))
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="):case_name=argument.trim_prefix("--case=")
		elif argument.begins_with("--mode="):mode=argument.trim_prefix("--mode=")
		elif argument.begins_with("--prefix="):capture_prefix=argument.trim_prefix("--prefix=")
	var config:=ConfigFile.new();config.set_value("display","visual_system",1);config.set_value("display","color_theme",mode);config.save("user://display.cfg")
	_world("late" if case_name=="mature" else ("secondary" if case_name=="secondary" else "early"))
	if case_name=="hearth":
		GameState.ensure_population_total(378);GameState.housing_capacity=569
		GameState.settlement_name="Wallyville"
		for town:Dictionary in GameState.player_settlements:
			if bool(town.get("primary",false)):town.name="Wallyville"
	GameState.civic_api_enabled=false;GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
	DiscoverySystem.initialize()
	if case_name=="mature":
		# Populate this private test world's real research and standing readers.
		DiscoverySystem.refresh_investigations()
		preload("res://scripts/standing.gd")._record_monthly()
	for town:Dictionary in GameState.player_settlements:
		SettlementModel.with_city_resources(String(town.id),func()->void:
			# These are explicit test receipts, not synthetic production in the UI.
			var recorded:Dictionary=GameState.simulation_metrics
			recorded["food_consumption"]=float(recorded.get("food_eaten",1.0))
			recorded["food_intake_ratio"]=1.0)
	if case_name=="secondary":
		# Deliberately different realm and town records expose a scope leak.
		var today:=int(GameState.elapsed_days)
		GameState.vital_statistics_tracking_start_day=today-100
		GameState.vital_statistics_history.assign([{"day":today-5,"births":21,"deaths":9}])
		var second:Dictionary=SettlementModel.settlement_record("second")
		var population_state:Dictionary=second.get("population_state",{}).duplicate(true)
		population_state["vital_statistics_tracking_start_day"]=today-30
		population_state["vital_statistics_history"]=[{"day":today-5,"births":2,"deaths":1}]
		second["population_state"]=population_state
	get_window().size=Vector2i(1600,1000);get_window().content_scale_size=Vector2i(1600,1000)
	audit_terrain=load("res://local_terrain.tscn").instantiate();audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(50);audit_terrain.call("_set_game_speed",0)
	for director:Node in get_tree().get_nodes_in_group("court_director"):director.set_process(false)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(10)
	var hud=audit_terrain.get("hud")
	var before:=_ledger()
	hud.section_requested.emit("settlement",0);hud.force_dock_layout();await _frames(16)
	var board=hud.dock.find_child("SettlementOverview",true,false)
	_expect(board!=null,"Actual Home provider creates the overview")
	if board==null:get_tree().quit(1);return
	_expect(board.get_script().resource_path.ends_with("home_lives_view.gd"),"Actual Home uses Lives and consequences")
	_expect(_ledger()==before,"Opening Home changes no population, allocations, stores or vital records")
	if case_name=="secondary":_check_secondary_readings(board)
	var original_instance:int=board.get_instance_id()
	_check_layout(board,"wide")
	await _capture("overview-wide")
	var comparison:Button=board.find_child("CareCompare",true,false)
	var current:Button=board.find_child("CareCurrent",true,false)
	var assign:Button=board.find_child("AssignCare",true,false)
	_expect(comparison!=null and current!=null,"Both comparison controls exist")
	if comparison and current:
		hud.dock.body_scroll.ensure_control_visible(comparison);await _frames(5)
		var initial_button:Rect2=comparison.get_global_rect()
		var initial_assign:Rect2=assign.get_global_rect()
		var initial_scroll:int=hud.dock.body_scroll.scroll_vertical
		var node_count:int=board.find_children("*","",true,false).size()
		before=_ledger()
		await _click(comparison.get_global_rect().get_center());await _frames(8)
		_expect(bool(board.get("comparison_active")),"Real click enters comparison mode")
		var preview:Dictionary=board.get("comparison")
		_expect(bool(preview.get("ok",false)),"Comparison contains a successful real calculator result")
		var expected:Dictionary=Lives.compare_care(String(GameState.selected_player_settlement_id),5)
		_expect(preview.get("after",{})==expected.get("after",{}),"Displayed comparison uses the same real selected-town consequences")
		_expect(_ledger()==before,"Care comparison does not apply an allocation or advance the simulation")
		_expect(comparison.get_global_rect()==initial_button,"Comparison control keeps its position")
		_expect(assign.get_global_rect()==initial_assign,"Assign care stays fixed while comparing")
		_expect(hud.dock.body_scroll.scroll_vertical==initial_scroll,"Comparison retains the user's scroll")
		_expect(board.find_children("*","",true,false).size()<=node_count+12,"Comparison reuses a bounded set of nodes")
		await _capture("care-comparison-wide")
		await _click(current.get_global_rect().get_center());await _frames(5)
		_expect(not bool(board.get("comparison_active")),"Current returns from comparison mode")
		_expect(_ledger()==before,"Returning to current conditions changes no game state")
		_expect(comparison.get_global_rect()==initial_button,"Returning to current keeps the comparison control fixed")
		var prior_day:=int(GameState.elapsed_days)
		for refresh in 3:
			GameState.elapsed_days+=1
			hud.live_refresh_dock();await _frames(3)
		_expect(int(board.data.lives.day)==prior_day+3,"Live refresh updates a changed day in the actual view")
		_expect(hud.dock.find_child("SettlementOverview",true,false).get_instance_id()==original_instance,"Live refresh retains Home's native controls")
		_expect(comparison.get_global_rect()==initial_button,"Live refresh retains comparison geometry")
		_expect(hud.dock.body_scroll.scroll_vertical==initial_scroll,"Live refresh retains scroll")
		before=_ledger()
		comparison.grab_focus();await _key(KEY_SPACE);await _frames(5)
		_expect(bool(board.get("comparison_active")),"Keyboard enters comparison mode")
		_expect(_ledger()==before,"Keyboard comparison also stays read-only")
		current.grab_focus();await _key(KEY_SPACE);await _frames(5)
	hud.dock.body_scroll.scroll_vertical=100000;await _frames(5);await _capture("consequences-wide")
	for canvas:Vector2i in [Vector2i(1024,720),Vector2i(2869,1337)]:
		get_window().size=canvas;get_window().content_scale_size=canvas;hud.force_dock_layout();await _frames(14)
		hud.dock.body_scroll.scroll_vertical=0;await _frames(4)
		_check_layout(board,str(canvas.x));await _capture("overview-"+str(canvas.x))
		if canvas.x==1024:
			if comparison and current:
				hud.dock.body_scroll.ensure_control_visible(comparison);await _frames(5)
				var narrow_button:Rect2=comparison.get_global_rect()
				var narrow_current:Rect2=current.get_global_rect()
				var narrow_assign:Rect2=assign.get_global_rect()
				var narrow_scroll:int=hud.dock.body_scroll.scroll_vertical
				var narrow_ledger:=_ledger()
				_expect(hud.dock.body_scroll.get_global_rect().encloses(narrow_button),"Narrow comparison button is inside the visible scroll area")
				await _click(narrow_button.get_center());await _frames(8)
				_expect(bool(board.get("comparison_active")),"Narrow real click enters comparison mode")
				var narrow_preview:Dictionary=board.get("comparison")
				_expect(bool(narrow_preview.get("ok",false)),"Narrow comparison has a successful calculator result")
				_expect(String(narrow_preview.get("after",{}).get("id",""))==String(board.data.lives.scope.id),"Narrow comparison remains scoped to the displayed settlement")
				_expect(_ledger()==narrow_ledger,"Narrow comparison preserves all audited game state")
				_expect(comparison.get_global_rect()==narrow_button and current.get_global_rect()==narrow_current,"Narrow comparison keeps both controls fixed")
				_expect(assign.get_global_rect()==narrow_assign,"Narrow assign care stays fixed while comparing")
				_expect(hud.dock.body_scroll.scroll_vertical==narrow_scroll,"Narrow comparison preserves scroll")
				_check_layout(board,"1024 comparison");await _capture("care-comparison-narrow")
				_expect(hud.dock.body_scroll.get_global_rect().encloses(current.get_global_rect()),"Narrow Current button remains in the visible scroll area")
				await _click(current.get_global_rect().get_center());await _frames(5)
				_expect(not bool(board.get("comparison_active")),"Narrow Current returns to current conditions")
				_expect(_ledger()==narrow_ledger,"Narrow Current preserves all audited game state")
				_expect(comparison.get_global_rect()==narrow_button and current.get_global_rect()==narrow_current,"Narrow Current keeps both controls fixed")
				_expect(hud.dock.body_scroll.scroll_vertical==narrow_scroll,"Narrow Current preserves scroll")
			hud.dock.body_scroll.scroll_vertical=100000;await _frames(4);await _capture("consequences-narrow")
	var text:=" ".join(_visible_text(board)).to_lower()
	for forbidden:String in ["illustrative additions","other net change","example only","51 in use","safer water preparation*"]:
		_expect(not text.contains(forbidden),"No illustrative placeholder: "+forbidden)
	_expect(board.find_child("ApplyWorkDraft",true,false)==null,"Home introduces no Apply step")
	print("HOME_LIVES_JOURNEY ",checks," checks; failures: ",failures)
	PlanetEnvironment.set_macro_bake_enabled(false)
	audit_terrain.queue_free();await _frames(2)
	get_tree().quit(0 if failures.is_empty() else 1)

func _ledger()->PackedByteArray:
	return var_to_bytes([GameState.elapsed_days,GameState.population_exact,GameState.population_total,
		GameState.population_allocations,GameState.population_allocation_percentages,GameState.population_cohorts,
		GameState.pregnancy_cohorts,GameState.food_stocks,GameState.resource_stockpiles,GameState.early_care,
		GameState.lifetime_births,GameState.lifetime_deaths,GameState.vital_statistics_history,GameState.vital_statistics_tracking_start_day,
		GameState.player_settlements,GameState.fabric_realm,GameState.built_fabric,GameState.early_care_blend,
		GameState.border_forts,GameState.simulation_events,GameState.selected_player_settlement_id,
		GameState.settlement_projects,GameState.settlement_plots,GameState.settlement_routes,
		PeopleDirection.automatic_work,PeopleDirection.work_baseline,PeopleDirection.cultural_memory,
		PeopleDirection.ambition,PeopleDirection.chosen_day,PeopleDirection.chosen_century,MilitaryCampaign.settlement_defense,
		[DiscoverySystem.rng.seed,DiscoverySystem.rng.state,ResourceSystem.rng.seed,ResourceSystem.rng.state,AdvisorSystem.rng.seed,AdvisorSystem.rng.state],
		_scope_bindings()])

func _scope_bindings()->Array:
	var bindings:Array=[]
	for field:String in Preview.BINDINGS:
		var system:Object=WorldSimulation.get(field)
		bindings.append(system.get_instance_id() if is_instance_valid(system) else 0)
	return [WorldSimulation.actor_id,WorldSimulation._active.keys(),WorldSimulation.advancing,WorldSimulation.span,
		GameState.resource_settlement_id,SettlementModel._local_population_scope,
		SettlementModel._national_population_in_scope,SettlementModel._national_civilian_workforce_fraction,bindings]

func _check_secondary_readings(board:Control)->void:
	var data:Dictionary=board.get("data")
	var reading:Dictionary=data.lives
	_expect(String(reading.scope.id)=="second" and String(reading.scope.name)=="Rivermeet","Home displays the selected secondary settlement")
	_expect(int(reading.population.current)==220 and int(reading.scope.national_population)==1100,"Secondary Home distinguishes 220 local people from 1100 realm people")
	var conditions:Dictionary=reading.conditions
	_expect(bool(conditions.food.known) and is_equal_approx(float(conditions.food.production),58.0) and is_equal_approx(float(conditions.food.required),61.0) and is_equal_approx(float(conditions.food.net),-5.0),"Secondary food flow uses its own recorded 58 produced, 61 needed and -5 net")
	_expect(is_equal_approx(float(conditions.food.stock),1800.0),"Secondary reserves use its own 1800 rations")
	_expect(bool(conditions.water.known) and is_equal_approx(float(conditions.water.intake_ratio),0.86) and is_equal_approx(float(conditions.water.collected),190.0) and is_equal_approx(float(conditions.water.required),220.0),"Secondary water uses its own 86 percent intake and 190 of 220 collection")
	_expect(int(conditions.housing.capacity)==180,"Secondary housing uses its own 180 places")
	var vitals:Dictionary=reading.population.vitals
	_expect(bool(vitals.known) and int(vitals.births)==2 and int(vitals.deaths)==1,"Secondary vital records use two births and one death, not the realm tally")
	var before:=_ledger()
	var primary:Dictionary=Lives.snapshot(SettlementModel._primary_settlement_id())
	_expect(bool(primary.get("ok",false)),"Primary comparison reading is available")
	_expect(_ledger()==before,"Comparing town scopes preserves the full audited ledger and bindings")
	if bool(primary.get("ok",false)):
		_expect(reading.research==primary.research and reading.culture==primary.culture and reading.regard==primary.regard,"Learning, culture and regard keep civilization scope across both towns")

func _check_layout(board:Control,label:String)->void:
	_expect(board.get_combined_minimum_size().x<=board.size.x+1,"No horizontal content overflow at "+label)
	_expect(board.get_global_rect().end.x<=get_viewport().get_visible_rect().size.x+1,"Home fits viewport at "+label)
	_expect(board.get_global_rect().position.x>=-1,"Home stays inside the viewport's left edge at "+label)
	for control:Control in board.find_children("*","Control",true,false):
		if not control.is_visible_in_tree() or control.size.x<1:continue
		_expect(control.get_global_rect().end.x<=board.get_global_rect().end.x+2,"Visible child fits Home: "+String(control.name)+" at "+label)
		_expect(control.get_global_rect().position.x>=board.get_global_rect().position.x-2,"Visible child stays inside Home's left edge: "+String(control.name)+" at "+label)
	var portrait=board.find_child("HomePortrait",true,false)
	_expect(portrait!=null and portrait.size.x>150 and portrait.size.y>150,"Substantial portrait remains visible at "+label)
	if portrait:
		var refs:Dictionary=board.get("_refs")
		var housing:Control=refs.get("housing")
		var summary:Control=board.find_child("PopulationSummary",true,false)
		_expect(portrait.get_global_rect().end.y<=housing.get_global_rect().position.y+1,"Portrait does not cover its housing caption at "+label)
		_expect(portrait.get_global_rect().position.y>=summary.get_global_rect().end.y-1,"Portrait does not cover population figures at "+label)

func _visible_text(node:Node)->PackedStringArray:
	var out:PackedStringArray=[]
	for child in node.find_children("*","",true,false):
		if child is Label:out.append(child.text)
		elif child is Button:out.append(child.text)
	return out

func _frames(count:int)->void:
	for frame in count:await get_tree().process_frame
func _expect(ok:bool,description:String)->void:
	checks+=1
	if not ok:failures.append(description);push_error(description)
func _click(at:Vector2)->void:
	for pressed:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=at;event.global_position=at;get_viewport().push_input(event,true)
		await get_tree().process_frame
func _key(code:Key)->void:
	for pressed:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.pressed=pressed;get_viewport().push_input(event,true)
		await get_tree().process_frame
func _capture(label:String)->void:
	await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path("res://artifacts/home-lives/%s-%s-%s-%s.png" % [capture_prefix,case_name,mode,label])
	DirAccess.make_dir_recursive_absolute(path.get_base_dir());get_viewport().get_texture().get_image().save_png(path)
	print("HOME_LIVES_CAPTURE ",path)
