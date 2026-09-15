extends GdUnitTestSuite
const Hierarchy=preload("res://scripts/command_hierarchy.gd")
const TreeUI=preload("res://scripts/hud/command_tree.gd")
const CommandPanel=preload("res://scripts/hud/command_hierarchy_panel.gd")
var command:RefCounted
var op:RefCounted
func before_test()->void:
	GameState.set_process(false);MilitaryCampaign.set_process(false);CivilizationSystem.set_process(false)
	GameState.reset_for_new_world(424242);SettlementModel.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(10000)
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	CivilizationSystem.set_scout_geography_authority(func(_at:Vector2)->bool:return true)
	CivilizationSystem.revealed_areas=[{"x":0.0,"z":0.0,"radius":100000.0}]
	GameState.food_stocks={"Preserved food":1000000.0};GameState.resource_stockpiles.Food=1000000.0
	command=MilitaryCampaign.command_hierarchy;op=MilitaryCampaign.joint_operations
	op.geography.land_query=func(at:Vector2)->bool:return at.y>=0
	GeneralCampaign.active=false
func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	GameState.elapsed_days=0;GameState.set_process(true);MilitaryCampaign.set_process(true);CivilizationSystem.set_process(true)
func _home(count:int=144,unit:String="levy",weapon:String="improvised")->String:
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":1,"unit":unit,"weapon":weapon,"count":count,"equipment":count,"ammunition":count*3,"training":.6,"experience":.2}],.8,.7)
	MilitaryCampaign.home_army.supply_level=1.0;command.sync()
	for record:Dictionary in command.children("army"):
		if int(record.force_id)==0:return String(record.id)
	return ""
func _zone(center:Vector2=Vector2(50,0),half_size:float=15)->Dictionary:
	return command.create_region("army",command.R.rectangle(center,half_size),"Frontier").region
func _totals()->Dictionary:
	var result:={"troops":0,"equipment":0,"ammunition":0,"wounded":0}
	for actual:Dictionary in [MilitaryCampaign.home_army]+MilitaryCampaign.field_armies:
		result.troops+=int(actual.get("troops",0));result.wounded+=int(actual.get("wounded_pool",0))
		for formation:Dictionary in actual.get("formations",[]):result.equipment+=int(formation.equipment);result.ammunition+=int(formation.get("ammunition",0))
	return result
func test_inspecting_modern_army_to_team_is_lazy_and_read_only()->void:
	var id:=_home(120000,"rifle_infantry","service_rifle")
	var before:=_totals();var nodes:int=command.data.nodes.size();var path:Array=[]
	var leaf:Dictionary=command.preview(id,path)
	for _level in 12:
		if leaf.parts.is_empty():break
		path.append(0);leaf=command.preview(id,path)
	assert_str(leaf.name).contains("Team");assert_int(int(leaf.count)).is_less_equal(4)
	assert_int(command.data.nodes.size()).is_equal(nodes);assert_dict(_totals()).is_equal(before)
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(0)
func test_squad_assignment_detaches_real_assets_and_keeps_parent_unassigned()->void:
	var id:=_home(144);MilitaryCampaign.home_army.wounded_pool=3
	var before:=_totals();var area:=_zone()
	var squad:Dictionary=command.preview(id,[0,0])
	var result:Dictionary=command.assign(id,[0,0],area,"defend")
	assert_bool(result.has("ok")).is_true()
	assert_int(command.amount(command.node(result.id))).is_equal(int(squad.count))
	assert_dict(_totals()).is_equal(before)
	assert_dict(command.order_for(id)).is_empty()
	assert_str(command.order_for(result.id).mission).is_equal("defend")
	var assigned:=0
	for actual:Dictionary in MilitaryCampaign.field_armies:
		if command.controls_army(int(actual.army_id)):assigned+=int(actual.troops)
	assert_int(assigned).is_equal(int(squad.count))
func test_child_override_parent_reassignment_and_cancel_are_scoped()->void:
	var id:=_home();var area:=_zone()
	var result:Dictionary=command.assign(id,[0],area,"defend")
	assert_bool(result.has("ok")).is_true()
	assert_bool(command.assign(id,[],area,"encircle").has("ok")).is_true()
	for leaf:Dictionary in command.leaves(id):assert_str(command.order_for(leaf.id).mission).is_equal("encircle")
	assert_bool(command.assign(result.id,[],area,"defeat").has("ok")).is_true()
	assert_str(command.order_for(result.id).mission).is_equal("defeat")
	assert_str(command.order_for(id).mission).is_equal("encircle")
	command.cancel(result.id)
	assert_str(command.order_for(result.id).mission).is_equal("cancelled")
	assert_str(command.order_for(id).mission).is_equal("encircle")
func test_invalid_zone_and_smallest_subdivision_leave_assets_untouched()->void:
	var id:=_home(8);var before:=_totals()
	assert_bool(command.assign(id,[0],{},"encircle").has("error")).is_true()
	assert_bool(command.materialize(id,[0,0,0]).has("error")).is_true()
	assert_dict(_totals()).is_equal(before);assert_int(MilitaryCampaign.field_armies.size()).is_equal(0)
func test_orders_advance_calendar_and_do_not_teleport_or_repeat_day()->void:
	var id:=_home(12);var area:=_zone(Vector2(100,0))
	var result:Dictionary=command.assign(id,[],area,"defend");assert_bool(result.has("ok")).is_true()
	var actual:Dictionary=command.force(command.node(result.id));var start:Vector2=command.land.point(actual)
	GameState.elapsed_days=1;command.advance(1)
	var moved:Vector2=command.land.point(actual)
	assert_float(start.distance_to(moved)).is_greater(0.0).is_less(100.0)
	command.advance(1);assert_vector(command.land.point(actual)).is_equal(moved)
func test_staff_find_land_detour_and_reject_impassable_water()->void:
	CivilizationSystem.set_scout_geography_authority(func(at:Vector2)->bool:return not (at.x>3 and at.x<6 and absf(at.y)<2))
	var path:Array=command.land.route(Vector2.ZERO,Vector2(10,0))
	assert_int(path.size()).is_greater(1)
	var previous:=Vector2.ZERO
	for waypoint:Dictionary in path:
		var next:Vector2=command.G.unpack(waypoint)
		assert_bool(MilitaryCampaign.field_route_availability(previous,next).has("ok")).is_true();previous=next
	CivilizationSystem.set_scout_geography_authority(func(at:Vector2)->bool:return at.x<3)
	command.land.clear_cache();assert_array(command.land.route(Vector2.ZERO,Vector2(10,0))).is_empty()
func test_neutral_border_stops_defensive_order_without_declaring_war()->void:
	var id:=_home(12);var area:=_zone(Vector2(20,0));var result:Dictionary=command.assign(id,[],area,"defend")
	var actual:Dictionary=command.force(command.node(result.id))
	command.land.claims.assign([{"owner":"neutral","city_id":"none","position":Vector2(5,0),"boundary":PackedVector2Array([Vector2(4,-10),Vector2(6,-10),Vector2(6,10),Vector2(4,10)])}])
	command.land._move(actual,Vector2(20,0),{"mission":"defend"},1)
	assert_float(command.land.point(actual).x).is_less(4.0)
	assert_str(actual.command_status).contains("neutral border")
	assert_array(CivilizationSystem.war_history).is_empty()
func test_encirclement_requires_actual_supplied_frontages_not_a_drawn_polygon()->void:
	var enemy:Dictionary={"troops":100,"strength":60.0,"position":{"x":0.0,"z":0.0}}
	var allies:Array=[]
	for index in 8:
		var at:=Vector2.from_angle(TAU*index/8.0)*1.53
		allies.append({"position":command.G.pack(at),"troops":100,"supply_level":1.0,"morale":.8,"formations":[{"count":100,"equipment":100,"equipment_required":100,"training":.7}]})
	assert_float(command.land._encirclement(enemy,allies)).is_equal(1.0)
	allies.pop_back();allies.pop_back();allies.pop_back()
	assert_float(command.land._encirclement(enemy,allies)).is_less(1.0)
	for actual:Dictionary in allies:actual.supply_level=.1
	assert_float(command.land._encirclement(enemy,allies)).is_equal(0.0)
func test_save_restores_orders_hierarchy_and_rejects_cycle_without_mutation()->void:
	var id:=_home();var area:=_zone();command.assign(id,[0,0],area,"defend")
	var saved:Dictionary=command.export_state();command.reset();command.import_state(saved)
	assert_dict(command.export_state()).is_equal(saved)
	var corrupt:=saved.duplicate(true);corrupt.nodes[id].parent=id
	assert_str(Hierarchy.validate(corrupt)).is_not_empty()
	var military:Dictionary=MilitaryCampaign.export_state();military.command_hierarchy=corrupt
	assert_bool(MilitaryCampaign.import_state(military).has("error")).is_true()
	assert_dict(command.export_state()).is_equal(saved)
func _craft(domain:String,count:int)->Dictionary:
	var type_id:="war_canoe" if domain=="navy" else "observation_balloon"
	var gate:="aerostat_observation" if domain=="air" else "river_craft"
	GameState.known_discoveries.append(gate);GameState.discovery_adoption[gate]=1.0
	for resource:String in ["Timber","Stone","Iron Ore"]:GameState.resource_stockpiles[resource]=100000.0
	var built:Dictionary=op.build_base(String(GameState.player_settlements[0].id),domain)
	assert_bool(built.has("ok")).override_failure_message(str(built)).is_true()
	var base:Dictionary=op.state.bases[-1];base.construction_work=base.required_work
	MilitaryCampaign.military_inventory[op.C.UNITS[type_id].equipment]=count
	var result:Dictionary=op.commission(int(base.id),type_id,count)
	assert_bool(result.has("ok")).is_true();command.sync()
	return op.force(int(result.id))
func test_navy_and_air_subcommands_use_separate_real_crews_and_missions()->void:
	for domain:String in ["navy","air"]:
		var actual:=_craft(domain,12);var initial:int=op.personnel();var node_id:=""
		for entry:Dictionary in command.children(domain):
			if int(entry.force_id)==int(actual.id):node_id=String(entry.id)
		var center:=Vector2(0,-20) if domain=="navy" else Vector2(0,5)
		var area:Dictionary=op.create_region(domain,command.R.rectangle(center,4),"Operations").region
		var result:Dictionary=command.assign(node_id,[0],area,"patrol" if domain=="navy" else "reconnaissance")
		assert_bool(result.has("ok")).override_failure_message(str(result)).is_true();assert_int(op.personnel()).is_equal(initial)
		var issued:Dictionary=command.force(command.node(result.id))
		assert_str(String(issued.domain)).is_equal(domain);assert_str(String(issued.mission)).is_equal("patrol" if domain=="navy" else "reconnaissance")
		var sibling:Dictionary=command.children(node_id)[-1]
		assert_str(String(command.force(sibling).mission)).is_equal("hold")
func test_cross_service_group_is_rejected_without_reparenting()->void:
	var id:=_home();_craft("air",2)
	var other:Dictionary=command.children("air")[0];var before:Dictionary=command.export_state()
	assert_bool(command.organize([id,other.id],8,"Mixed").has("error")).is_true()
	assert_dict(command.export_state()).is_equal(before)
func test_tree_browsing_and_main_map_panel_preserve_world_camera()->void:
	var id:=_home(144);var before:=_totals()
	var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain="army";add_child(panel)
	assert_bool("camera" in panel.map).is_false();assert_bool(panel.map.mouse_filter==Control.MOUSE_FILTER_IGNORE).is_true()
	var root:TreeItem=panel.tree.get_root().get_first_child()
	var unit:TreeItem=root.get_first_child();unit.collapsed=false;panel.tree._expanded(unit)
	assert_dict(_totals()).is_equal(before);assert_int(MilitaryCampaign.field_armies.size()).is_equal(0)
	panel.map.begin_boundary();panel.map.vertices=command.R.rectangle(Vector2(20,0),3);panel.map.finish_boundary("Land zone")
	assert_bool(panel.map.drawing).is_false();assert_str(panel.map.selected.domain).is_equal("army")
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true
	assert_bool(panel.handle_map_input(wheel)).is_false()
	panel.map.begin_boundary();var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
	panel.handle_early_input(escape);assert_bool(panel.map.drawing).is_false();assert_bool(panel.is_queued_for_deletion()).is_false()
func test_full_military_save_roundtrip_preserves_nested_detachments_and_counts()->void:
	var id:=_home();command.assign(id,[0,0],_zone(),"defend")
	var before:=_totals();var saved:Dictionary=MilitaryCampaign.export_state()
	var result:Dictionary=MilitaryCampaign.import_state(JSON.parse_string(JSON.stringify(saved)))
	assert_bool(result.has("ok")).override_failure_message(str(result)).is_true()
	assert_dict(_totals()).is_equal(before)
	assert_str(command.validate(command.export_state())).is_empty()
func test_encirclement_staff_organize_subcommands_automatically_without_recruiting()->void:
	var id:=_home();var area:=_zone(Vector2(100,0));command.assign(id,[],area,"encircle")
	var before:=_totals();GameState.elapsed_days=1;command.advance(1)
	assert_int(command.children(id).size()).is_greater_equal(2)
	assert_dict(_totals()).is_equal(before)
	var records:int=MilitaryCampaign.field_armies.size()
	GameState.elapsed_days=2;command.advance(2)
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(records)
func test_coordinated_battle_conserves_each_command_losses_and_population()->void:
	var id:=_home(144);var made:Dictionary=command.assign(id,[0],_zone(),"defend")
	var allies:Array=[]
	for record:Dictionary in command.leaves(id):allies.append(command.force(record))
	var initial:=_totals();var population:=GameState.population_total
	var enemy:Dictionary=MilitaryCampaign.simulator.create_formation_force("Enemy",[{"id":9,"unit":"levy","weapon":"improvised","count":120,"equipment":120,"training":.7}],.8,.7)
	var engagement:Dictionary={"home_side":"attacker","attacker":allies[0].duplicate(true),"defender":enemy,"attacker_initial":int(allies[0].troops)}
	command.battle.attach(engagement,allies)
	assert_int(int(engagement.attacker.troops)).is_equal(144)
	var combat:Dictionary=MilitaryCampaign.simulator.simulate(engagement.attacker,enemy,{"seed":741,"max_rounds":4})
	combat["home_side"]="attacker";combat["command_participants"]=engagement.command_participants
	command.battle.commit(combat)
	var after:=_totals();var dead:=0;var scattered:=0
	for actual:Dictionary in MilitaryCampaign.field_armies:dead+=int(actual.get("dead",0));scattered+=int(actual.get("scattered_pool",0))
	assert_int(int(after.troops)+int(after.wounded)+scattered+dead).is_equal(int(initial.troops))
	assert_int(GameState.population_total).is_equal(population-dead)
	assert_int(int(after.equipment)).is_less_equal(int(initial.equipment))
	assert_int(command.leaves(id).size()).is_equal(allies.size())
func test_remote_subcommands_do_not_contribute_to_battle()->void:
	var id:=_home();command.assign(id,[0],_zone(),"defend")
	var allies:Array=[]
	for record:Dictionary in command.leaves(id):allies.append(command.force(record))
	allies[-1].position={"x":100.0,"z":0.0}
	var near:Array=command.battle.participants(allies[0],allies,Vector2.ZERO)
	assert_int(near.size()).is_equal(allies.size()-1)
func test_front_geometry_depends_on_actual_contact_and_disappears_when_it_breaks()->void:
	CivilizationSystem.initialize()
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ.player_relation.at_war=true;civ.military_population=400.0
	var enemy:Dictionary=CivilizationSystem.foreign_formations[0]
	enemy.kind="patrol";enemy.command_position={"x":10.0,"z":0.0};enemy.command_response_day=1;enemy.disabled_until_day=0
	var id:=_home(100);var result:Dictionary=command.assign(id,[],_zone(Vector2(10,0),20),"defend")
	var actual:Dictionary=command.force(command.node(result.id));actual.position={"x":9.0,"z":0.0}
	GameState.elapsed_days=1;CivilizationSystem._process_local_observation(1,true)
	command.land._build_fronts(1)
	assert_int(command.data.fronts.size()).is_greater(0)
	actual.position={"x":-50.0,"z":0.0};CivilizationSystem._process_local_observation(2,true);command.land._build_fronts(2)
	assert_array(command.data.fronts).is_empty()
func test_rival_response_moves_real_existing_force_without_creating_soldiers()->void:
	CivilizationSystem.initialize();var civ:Dictionary=CivilizationSystem.civilizations[0];civ.player_relation.at_war=true;civ.military_population=400.0
	var enemy:Dictionary=CivilizationSystem.foreign_formations[0]
	enemy.kind="patrol";enemy.command_position={"x":10.0,"z":0.0};enemy.command_response_day=0;enemy.disabled_until_day=0
	var id:=_home(100);command.assign(id,[],_zone(),"defend")
	var population:=GameState.population_total;var rival_population:float=CivilizationSystem.land_military_population(civ);var count:int=CivilizationSystem.foreign_formations.size()
	command.land._respond_rivals(1)
	var moved:Vector2=CivilizationSystem._foreign_formation_position(enemy,1)
	assert_float(moved.x).is_less(10.0).is_greater_equal(0.0)
	assert_int(GameState.population_total).is_equal(population);assert_float(CivilizationSystem.land_military_population(civ)).is_equal(rival_population)
	assert_int(CivilizationSystem.foreign_formations.size()).is_equal(count)
func test_panel_fits_a_1280_by_720_view_with_close_button_accessible()->void:
	_home()
	var original_size:=get_tree().root.size;var original_scale:=get_tree().root.content_scale_size
	get_tree().root.size=Vector2i(1280,720);get_tree().root.content_scale_size=Vector2i(1280,720)
	var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain="army";add_child(panel)
	await get_tree().process_frame
	panel._process(0)
	await get_tree().process_frame
	var bounds:Rect2=panel.panel.get_global_rect()
	assert_float(bounds.end.y).is_less_equal(float(get_viewport().get_visible_rect().size.y))
	assert_float(bounds.position.x).is_greater_equal(0.0)
	get_tree().root.size=original_size;get_tree().root.content_scale_size=original_scale
func test_service_subdivision_rejects_a_mission_unsupported_by_its_actual_craft_atomically()->void:
	var actual:=_craft("air",12)
	actual.units={"fighter":6,"observation_balloon":6};actual.authorized=actual.units.duplicate(true)
	var id:=""
	for record:Dictionary in command.children("air"):id=String(record.id)
	var area:Dictionary=op.create_region("air",command.R.rectangle(Vector2(0,5),3),"Air").region
	var before:Dictionary=op.export_state();var hierarchy:Dictionary=command.export_state()
	# First child retains the final balloon craft after the later siblings
	# detach the fighter portion. It must not inherit fighter-only missions.
	var result:Dictionary=command.assign(id,[0],area,"air_superiority")
	assert_bool(result.has("error")).is_true()
	assert_dict(op.export_state()).is_equal(before);assert_dict(command.export_state()).is_equal(hierarchy)
func test_tree_refresh_preserves_expansion_without_rebuilding_on_daily_counts()->void:
	var id:=_home(144)
	var tree:Tree=auto_free(TreeUI.new());tree.service="army";add_child(tree)
	var unit:TreeItem=tree.get_root().get_first_child().get_first_child();unit.collapsed=false;tree._expanded(unit)
	var first:TreeItem=unit.get_first_child()
	MilitaryCampaign.home_army.formations[0].count-=1;MilitaryCampaign.home_army.troops-=1
	tree.refresh()
	assert_object(tree.get_root().get_first_child().get_first_child()).is_same(unit)
	assert_object(unit.get_first_child()).is_same(first)
	assert_bool(unit.collapsed).is_false()
	assert_str(unit.get_text(1)).is_equal("143")
func test_a_saved_rival_response_does_not_teleport_after_thirty_days()->void:
	var formation:Dictionary={"point_a":Vector2(100,0),"point_b":Vector2(200,0),"leg_days":90.0,"command_position":{"x":5.0,"z":7.0},"command_response_day":1}
	assert_vector(CivilizationSystem._foreign_formation_position(formation,40)).is_equal(Vector2(5,7))
func test_changed_terrain_invalidates_cached_detour_without_crossing_water()->void:
	CivilizationSystem.set_scout_geography_authority(func(at:Vector2)->bool:return not(at.x>3 and at.x<6 and absf(at.y)<2))
	var first:Array=command.land.route(Vector2.ZERO,Vector2(10,0));assert_int(first.size()).is_greater(1)
	CivilizationSystem.set_scout_geography_authority(func(at:Vector2)->bool:return not(at.x>3 and at.x<6))
	assert_array(command.land.route(Vector2.ZERO,Vector2(10,0))).is_empty()
func test_new_trained_forces_can_deploy_after_subordinate_commands_are_created()->void:
	var id:=_home();command.assign(id,[0,0],_zone(),"defend")
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("New reserve",[{"id":99,"unit":"levy","weapon":"improvised","count":8,"equipment":8}],.7,.7)
	assert_bool(MilitaryCampaign.create_field_army(8).has("ok")).is_true()
func test_service_orders_given_in_the_existing_panel_are_reflected_in_hierarchy()->void:
	var actual:=_craft("air",2);var id:=""
	for entry:Dictionary in command.children("air"):id=String(entry.id)
	var area:Dictionary=op.create_region("air",command.R.rectangle(Vector2(0,5),3),"Observe").region
	assert_bool(op.assign(int(actual.id),area,"reconnaissance").has("ok")).is_true()
	command.sync();assert_str(command.order_for(id).mission).is_equal("reconnaissance")
	op.assign(int(actual.id),{},"hold");command.sync();assert_str(command.order_for(id).mission).is_equal("hold")

func test_separate_commands_fight_concurrently_and_resume_without_duplicate_personnel()->void:
	CivilizationSystem.initialize()
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ.player_relation.at_war=true;civ.military_population=2400.0
	var id:=_home(144);command.assign(id,[0],_zone(),"defend")
	var forces:Array=[]
	for record:Dictionary in command.leaves(id):forces.append(command.force(record))
	var enemy_ids:Array=[]
	for index in 2:
		var enemy:Dictionary=CivilizationSystem.foreign_formations[index]
		enemy.kind="patrol";enemy.civ_id=civ.id;enemy.command_position={"x":10.0+40*index,"z":0.0};enemy.disabled_until_day=0;enemy.strength_share=.05
		forces[index].position=enemy.command_position.duplicate(true);enemy_ids.append(String(enemy.id))
	GameState.elapsed_days=1;CivilizationSystem._process_local_observation(1,true)
	var known:Array=command.land._known_enemies(1)
	for index in 2:
		for enemy:Dictionary in known:
			if enemy.id==enemy_ids[index]:command.land._engage(forces[index],enemy,{"mission":"defeat"},[forces[index]])
	assert_int(command.data.battles.size()).is_equal(2)
	assert_bool(command.battle.engaged(int(forces[0].army_id))).is_true()
	assert_bool(MilitaryCampaign.move_field_army_to_position(int(forces[0].army_id),20,0).has("error")).is_true()
	forces[0].location_id="player_home"
	assert_bool(MilitaryCampaign.disband_field_army(int(forces[0].army_id)).has("error")).is_true()
	assert_array(MilitaryCampaign._exercise_forces()).not_contains(forces[0])
	var saved:Dictionary=JSON.parse_string(JSON.stringify(MilitaryCampaign.export_state()))
	var restored:Dictionary=MilitaryCampaign.import_state(saved)
	assert_bool(restored.has("error")).override_failure_message(str(restored)).is_false()
	var corrupt:=saved.duplicate(true);corrupt.command_hierarchy.battles.append(corrupt.command_hierarchy.battles[0].duplicate(true))
	assert_bool(MilitaryCampaign.import_state(corrupt).has("error")).is_true()
	assert_int(command.data.battles.size()).is_equal(2)
	var before:=MilitaryCampaign.battle_history.size()
	command.battle.advance_all()
	assert_int(command.data.battles.size()+MilitaryCampaign.battle_history.size()-before).is_equal(2)
	for engagement:Dictionary in command.data.battles:assert_int(int(engagement.round)).is_equal(1)
	assert_dict(MilitaryCampaign.active_engagement).is_empty()

func test_native_mouse_expansion_creates_teams_after_tree_unlocks()->void:
	_home(10)
	var tree:Tree=auto_free(TreeUI.new());tree.size=Vector2(500,400);add_child(tree)
	await get_tree().process_frame
	var squad:TreeItem=tree.get_root().get_first_child().get_first_child()
	assert_bool(squad.collapsed).is_true()
	var row:Rect2=tree.get_item_area_rect(squad)
	var at:=tree.global_position+Vector2(row.position.x+8,row.get_center().y)
	var motion:=InputEventMouseMotion.new();motion.position=at;motion.global_position=at;get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=at;event.global_position=at;event.pressed=pressed;get_viewport().push_input(event,true)
	await get_tree().process_frame
	assert_bool(squad.collapsed).is_false()
	assert_int(squad.get_child_count()).is_equal(4)
	assert_str(squad.get_first_child().get_text(0)).contains("Team")
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(0)
	# A rebuild can free a row before its deferred expansion is delivered.
	squad.collapsed=true;squad.collapsed=false;tree.rebuild()
	await get_tree().process_frame
	assert_int(tree.get_root().get_first_child().get_first_child().get_child_count()).is_equal(4)

func test_order_action_stays_reachable_when_optional_details_and_feedback_are_long()->void:
	_home(10);_craft("navy",12);_craft("air",12)
	var original_size:=get_tree().root.size;var original_scale:=get_tree().root.content_scale_size
	for dimensions:Vector2i in [Vector2i(1280,720),Vector2i(1024,640)]:
		get_tree().root.size=dimensions;get_tree().root.content_scale_size=dimensions
		assert_int(int(get_viewport().get_visible_rect().size.y)).is_equal(dimensions.y)
		for service:String in ["army","navy","air"]:
			var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain=service;add_child(panel)
			panel._selected(command.preview(service))
			if service!="army":panel.mission.select(1);panel._refresh_mission_availability();assert_bool(panel.preparation_box.visible).is_true()
			panel.current_order_label.text="CURRENT  •  Encircle · A long named frontier with subordinate exceptions ".repeat(12)
			panel.mission_hint.text="This command lacks the required equipment for the selected objective. ".repeat(4);panel.mission_hint.show()
			panel.details_toggle.pressed.emit()
			panel._draw_zone()
			panel._report({"error":"Supply and route information with enough detail to wrap across several lines. ".repeat(8)})
			await get_tree().process_frame
			panel._process(0)
			await get_tree().process_frame
			assert_bool(panel.orders_scroll.get_global_rect().encloses(panel.mission.get_global_rect())).is_true()
			assert_bool(panel.orders_scroll.get_global_rect().encloses(panel.current_order_label.get_global_rect())).is_true()
			assert_bool(panel.orders_scroll.get_global_rect().encloses(panel.edit_order_button.get_global_rect())).is_true()
			panel.orders_scroll.scroll_vertical=10000
			await get_tree().process_frame
			var button:Rect2=panel.apply_button.get_global_rect();var bounds:Rect2=panel.panel.get_global_rect()
			assert_bool(panel.apply_button.is_visible_in_tree()).is_true()
			assert_bool(panel.orders_scroll.is_ancestor_of(panel.apply_button)).is_false()
			assert_bool(bounds.encloses(button)).is_true()
			assert_float(bounds.end.y).is_less_equal(float(dimensions.y)-16.0)
			assert_float(bounds.position.x).is_greater_equal(0.0)
			assert_float(bounds.end.x).is_less_equal(float(dimensions.x))
			assert_float(panel.tree.size.y).is_greater_equal(180.0)
			panel.queue_free();await get_tree().process_frame
	get_tree().root.size=original_size;get_tree().root.content_scale_size=original_scale

func test_optional_command_names_start_collapsed_and_drawing_controls_follow_draft()->void:
	_home(10)
	var panel:CanvasLayer=auto_free(CommandPanel.new());add_child(panel)
	assert_bool(panel.details.visible).is_false()
	assert_bool(panel.finish_button.visible).is_false()
	panel._draw_zone();panel._process(0)
	assert_bool(panel.finish_button.visible).is_true()
	assert_bool(panel.cancel_boundary_button.visible).is_true()
	assert_bool(panel.feedback.visible).is_true()
	panel.details_toggle.pressed.emit();assert_bool(panel.details.visible).is_true()
	panel.cancel_boundary_button.pressed.emit();panel._process(0)
	assert_bool(panel.finish_button.visible).is_false()
	assert_bool(panel.cancel_boundary_button.visible).is_false()
	var title_width:float=panel.tree.get_theme_font("title_button_font").get_string_size(panel.tree.get_column_title(1),HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	assert_float(float(panel.tree.get_column_width(1))).is_greater_equal(title_width+16)
	# Already-open pre-update panels do not contain the new drawing controls.
	panel.finish_button=null;panel.cancel_boundary_button=null;panel._process(.1)

func test_reselecting_resized_team_uses_displayed_strength_and_allows_order()->void:
	var id:=_home(10)
	var panel:CanvasLayer=auto_free(CommandPanel.new());add_child(panel)
	var unit:TreeItem=panel.tree.get_root().get_first_child().get_first_child();unit.collapsed=false;panel.tree._expanded(unit)
	var team:TreeItem=unit.get_first_child();team.select(0);panel.tree.multi_selected.emit(team,0,true)
	assert_int(int(panel.selected.count)).is_equal(3)
	_home(6);panel.tree.refresh()
	assert_str(team.get_text(1)).is_equal("2")
	assert_int(int(team.get_metadata(0).count)).is_equal(2)
	assert_int(unit.get_child_count()).is_equal(3)
	var before:=_totals();panel._region(_zone())
	# A changed detachment still requires a fresh selection before committing.
	panel._assign();assert_str(panel.feedback.text).contains("strength changed")
	assert_dict(_totals()).is_equal(before);assert_int(MilitaryCampaign.field_armies.size()).is_equal(0)
	unit=panel.tree.get_root().get_first_child().get_first_child();team=unit.get_first_child()
	team.select(0);panel.tree.multi_selected.emit(team,0,true)
	assert_int(int(panel.selected.count)).is_equal(2)
	panel._assign();assert_bool(command.order_for(String(panel.selected.id)).has("mission")).is_true()
	assert_array(panel.selected.path).is_empty();assert_int(int(panel.selected.count)).is_equal(2)
	assert_dict(_totals()).is_equal(before)

func test_disappearing_team_clears_active_order_target_without_selecting_parent()->void:
	_home(10)
	var panel:CanvasLayer=auto_free(CommandPanel.new());add_child(panel)
	var unit:TreeItem=panel.tree.get_root().get_first_child().get_first_child()
	panel.tree.multi_selected.emit(unit.get_first_child(),1,true)
	assert_dict(panel.selected).is_empty()
	unit.collapsed=false;panel.tree._expanded(unit)
	var team:TreeItem=unit.get_child(3);team.select(0);panel.tree.multi_selected.emit(team,0,true)
	_home(2);panel.tree.refresh()
	assert_int(unit.get_child_count()).is_equal(2)
	assert_dict(panel.selected).is_empty();assert_str(panel.selected_label.text).is_equal("No command selected")
	panel._assign();assert_str(panel.feedback.text).contains("Select a command")
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(0)
	_home(10);panel.tree.refresh()
	assert_int(unit.get_child_count()).is_equal(4)
	assert_dict(panel.selected).is_empty()

func test_structure_refresh_keeps_exact_active_subdivision_for_each_service()->void:
	_home(10);_craft("navy",12);_craft("air",12)
	for service:String in ["army","navy","air"]:
		var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain=service;add_child(panel)
		var root:TreeItem=panel.tree.get_root().get_first_child()
		var unit:TreeItem=root.get_first_child();unit.collapsed=false;panel.tree._expanded(unit)
		# The active selection is the most recently chosen command, even when
		# the parent remains selected for headquarters organization.
		unit.select(0);panel.tree.multi_selected.emit(unit,0,true)
		var child:TreeItem=unit.get_first_child();child.select(0);panel.tree.multi_selected.emit(child,0,true)
		var chosen:Dictionary=panel.selected.duplicate(true)
		panel.mission.select(1);panel.vision.text="Keep this draft"
		command._add(service,service,command.LEVELS[service].size()-1,"New headquarters")
		panel.tree.refresh()
		assert_str(panel.selected.id).is_equal(String(chosen.id));assert_array(panel.selected.path).is_equal(chosen.path)
		assert_int(int(panel.selected.count)).is_equal(int(chosen.count))
		assert_int(panel.mission.selected).is_equal(1);assert_str(panel.vision.text).is_equal("Keep this draft")
		assert_array(panel.tree.active_selection.path).is_equal(chosen.path)
		assert_int(panel.tree.selections().size()).is_equal(2)
		panel.queue_free();await get_tree().process_frame

func test_cancel_virtual_squad_preserves_sibling_orders_assets_and_saved_override()->void:
	var id:=_home(144);var area:=_zone()
	assert_bool(command.assign(id,[],area,"defend").has("ok")).is_true()
	var squad:Dictionary=command.preview(id,[0,0]);var before:=_totals()
	var result:Dictionary=command.cancel(id,[0,0],int(squad.count))
	assert_bool(result.has("ok")).override_failure_message(str(result)).is_true()
	assert_str(result.id).is_not_equal(id)
	assert_int(command.amount(command.node(result.id))).is_equal(int(squad.count))
	assert_dict(_totals()).is_equal(before)
	var holding:=0;var defending:=0
	for leaf:Dictionary in command.leaves(id):
		if command.order_for(leaf.id).mission=="cancelled":holding+=command.amount(leaf)
		elif command.order_for(leaf.id).mission=="defend":defending+=command.amount(leaf)
	assert_int(holding).is_equal(int(squad.count));assert_int(defending).is_equal(144-holding)
	assert_str(command.order_for(id).mission).is_equal("defend")
	var saved:Dictionary=JSON.parse_string(JSON.stringify(MilitaryCampaign.export_state()))
	assert_bool(MilitaryCampaign.import_state(saved).has("ok")).is_true()
	assert_str(command.order_for(result.id).mission).is_equal("cancelled")
	assert_str(command.order_for(id).mission).is_equal("defend")
	assert_dict(_totals()).is_equal(before)
	var actual:Dictionary=command.force(command.node(result.id));var location:Vector2=command.land.point(actual)
	GameState.elapsed_days=1;command.advance(1)
	assert_vector(command.land.point(actual)).is_equal(location)
	var moved:=false
	for leaf:Dictionary in command.leaves(id):
		if command.order_for(leaf.id).mission=="defend" and command.land.point(command.force(leaf)).distance_to(location)>0:moved=true
	assert_bool(moved).is_true()

func test_cancel_button_keeps_selected_team_and_parent_objective()->void:
	var id:=_home(10);assert_bool(command.assign(id,[],_zone(),"defend").has("ok")).is_true()
	var panel:CanvasLayer=auto_free(CommandPanel.new());add_child(panel)
	var unit:TreeItem=panel.tree.get_root().get_first_child().get_first_child();unit.collapsed=false;panel.tree._expanded(unit)
	var team:TreeItem=unit.get_first_child();team.select(0);panel.tree.multi_selected.emit(team,0,true)
	var count:=int(panel.selected.count);var before:=_totals()
	var action:Button=panel.apply_button.get_parent().get_child(1)
	assert_str(action.text).is_equal("Cancel orders");action.pressed.emit()
	assert_str(panel.selected.id).is_not_equal(id);assert_array(panel.selected.path).is_empty()
	assert_int(int(panel.selected.count)).is_equal(count)
	assert_str(panel.selected.order.mission).is_equal("cancelled")
	assert_str(command.order_for(id).mission).is_equal("defend")
	assert_dict(_totals()).is_equal(before)
	assert_str(panel.feedback.text).contains("Objectives cancelled")

func test_cancel_stale_or_moving_subdivision_never_changes_its_parent()->void:
	var id:=_home(10);assert_bool(command.assign(id,[],_zone(),"defend").has("ok")).is_true()
	var team:Dictionary=command.preview(id,[0]);var before:Dictionary=MilitaryCampaign.export_state()
	assert_str(command.cancel(id,[0],int(team.count)+1).error).contains("strength changed")
	assert_bool(command.cancel(id,[99],int(team.count)).has("error")).is_true()
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	var actual:Dictionary=command.force(command.node(id));actual.status="moving"
	before=MilitaryCampaign.export_state()
	assert_str(command.cancel(id,[0],int(team.count)).error).contains("assemble")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)

func test_cancelling_unassigned_virtual_team_is_read_only_and_keeps_selection()->void:
	var id:=_home(10)
	var panel:CanvasLayer=auto_free(CommandPanel.new());add_child(panel)
	var unit:TreeItem=panel.tree.get_root().get_first_child().get_first_child();unit.collapsed=false;panel.tree._expanded(unit)
	var team:TreeItem=unit.get_first_child();team.select(0);panel.tree.multi_selected.emit(team,0,true)
	var before:Dictionary=MilitaryCampaign.export_state();var selected:Dictionary=panel.selected.duplicate(true)
	panel._cancel_orders()
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	assert_dict(panel.selected).is_equal(selected)
	assert_str(panel.feedback.text).contains("no active objective")

func test_cancel_service_subdivision_on_mission_does_not_stand_down_its_parent()->void:
	for domain:String in ["navy","air"]:
		var actual:=_craft(domain,12);var id:=String(command.children(domain)[0].id)
		var center:=Vector2(0,-20) if domain=="navy" else Vector2(0,5)
		var area:Dictionary=op.create_region(domain,command.R.rectangle(center,4),"Operations").region
		assert_bool(command.assign(id,[],area,"patrol" if domain=="navy" else "reconnaissance").has("ok")).is_true()
		command.sync();var before:Dictionary=MilitaryCampaign.export_state()
		var result:Dictionary=command.cancel(id,[0],int(command.preview(id,[0]).count))
		assert_str(result.error).contains("ready home base")
		assert_dict(MilitaryCampaign.export_state()).is_equal(before)
		assert_str(actual.mission).is_equal("patrol" if domain=="navy" else "reconnaissance")

func test_whole_service_cancellation_is_atomic_when_a_subordinate_carries_a_convoy()->void:
	for domain:String in ["navy","air"]:
		_craft(domain,12);var id:=String(command.children(domain)[0].id)
		assert_bool(command.materialize(id,[0]).has("ok")).is_true()
		var center:=Vector2(0,-20) if domain=="navy" else Vector2(0,5)
		var area:Dictionary=op.create_region(domain,command.R.rectangle(center,4),"Operations").region
		assert_bool(command.assign(domain,[],area,"patrol" if domain=="navy" else "reconnaissance").has("ok")).is_true()
		var leaves:Array=command.leaves(domain);assert_int(leaves.size()).is_greater(1)
		op.state.convoys.append({"force_id":int(leaves[-1].force_id),"status":"outbound"})
		command.sync();var before:Dictionary=MilitaryCampaign.export_state();var crew:int=op.personnel()
		var result:Dictionary=command.cancel(domain)
		assert_str(result.error).contains("carrying a convoy")
		assert_dict(MilitaryCampaign.export_state()).is_equal(before)
		op.state.convoys.clear();result=command.cancel(domain)
		assert_bool(result.has("ok")).override_failure_message(str(result)).is_true()
		assert_str(result.message).contains("home ports" if domain=="navy" else "Sorties stop")
		assert_int(op.personnel()).is_equal(crew)
		command.sync()
		for leaf:Dictionary in leaves:
			assert_str(command.force(leaf).mission).is_equal("hold")
			assert_dict(command.force(leaf).region).is_empty()
			assert_str(command.order_for(leaf.id).mission).is_equal("cancelled")

func test_cancelling_during_a_real_battle_preserves_the_current_engagement()->void:
	CivilizationSystem.initialize()
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ.player_relation.at_war=true;civ.military_population=2400.0
	var id:=_home(144);assert_bool(command.assign(id,[],_zone(),"defeat").has("ok")).is_true()
	var actual:Dictionary=command.force(command.node(id))
	var enemy:Dictionary=CivilizationSystem.foreign_formations[0]
	enemy.kind="patrol";enemy.civ_id=civ.id;enemy.command_position={"x":10.0,"z":0.0};enemy.disabled_until_day=0;enemy.strength_share=.05
	actual.position=enemy.command_position.duplicate(true)
	GameState.elapsed_days=1;CivilizationSystem._process_local_observation(1,true)
	for known:Dictionary in command.land._known_enemies(1):
		if known.id==enemy.id:command.land._engage(actual,known,{"mission":"defeat"},[actual])
	assert_int(command.data.battles.size()).is_equal(1)
	var before:Dictionary=actual.duplicate(true);var battle_before:Array=command.data.battles.duplicate(true)
	assert_bool(command.cancel(id).has("ok")).is_true()
	assert_str(actual.command_status).contains("resolving current engagement")
	before.command_status=actual.command_status
	assert_dict(actual).is_equal(before);assert_array(command.data.battles).is_equal(battle_before)
	assert_bool(command.battle.engaged(int(actual.army_id))).is_true()
	var completed:=MilitaryCampaign.battle_history.size();command.battle.advance_all()
	assert_int(command.data.battles.size()+MilitaryCampaign.battle_history.size()-completed).is_equal(1)
	for engagement:Dictionary in command.data.battles:assert_int(int(engagement.round)).is_equal(1)

func _select_draft_mission(panel:CanvasLayer,id:String)->void:
	for index in panel.mission.item_count:
		if panel.mission.get_item_metadata(index)==id:panel.mission.select(index);return
	assert_bool(false).override_failure_message("Missing mission "+id).is_true()

func test_current_order_and_next_draft_stay_separate_until_explicit_edit()->void:
	var id:=_home(144);var issued_area:=_zone();issued_area.name="North frontier"
	assert_bool(command.assign(id,[],issued_area,"defend","","Hold the crossings").has("ok")).is_true()
	var draft_area:=_zone(Vector2(150,0));draft_area.name="Southern approach"
	var panel:CanvasLayer=auto_free(CommandPanel.new());add_child(panel)
	_select_draft_mission(panel,"encircle");panel._region(draft_area);panel.vision.text="Keep my new plan"
	var before:Dictionary=MilitaryCampaign.export_state()
	panel._selected(command.preview(id));panel._process(1.1)
	assert_str(panel.current_order_label.text).contains("CURRENT  •  Defend").contains("North frontier")
	assert_str(panel.current_order_label.tooltip_text).contains("Hold the crossings")
	assert_bool(panel.mission.get_item_text(panel.mission.selected).begins_with("OBJECTIVE  •")).is_true()
	assert_str(panel._mission()).is_equal("encircle");assert_str(panel.map.selected.id).is_equal(draft_area.id)
	assert_str(panel.vision.text).is_equal("Keep my new plan")
	assert_bool(panel.edit_order_button.disabled).is_false();panel.edit_order_button.pressed.emit()
	assert_str(panel._mission()).is_equal("defend");assert_str(panel.map.selected.id).is_equal(issued_area.id)
	assert_str(panel.vision.text).is_equal("Hold the crossings")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	assert_str(panel.feedback.text).contains("Issue objective applies changes")

func test_current_order_distinguishes_parent_overrides_inheritance_and_mixed_headquarters()->void:
	var id:=_home(144);var zone:=_zone();zone.name="Border watch"
	assert_bool(command.assign(id,[],zone,"defend").has("ok")).is_true()
	var child:Dictionary=command.assign(id,[0],zone,"defeat");assert_bool(child.has("ok")).is_true()
	var panel:CanvasLayer=auto_free(CommandPanel.new());add_child(panel)
	panel._selected(command.preview(id))
	assert_str(panel.current_order_label.text).contains("Defend").contains("1 override")
	assert_str(panel.current_order_label.tooltip_text).contains("replaces those orders")
	for leaf:Dictionary in command.leaves(id):
		if leaf.id==child.id:continue
		panel._selected(command.preview(leaf.id))
		assert_str(panel.current_order_label.tooltip_text).contains("Inherited from")
		panel._selected(command.preview(leaf.id,[0]))
		assert_str(panel.current_order_label.tooltip_text).contains("shares its parent force's order")
		break
	panel._selected(command.preview("army"))
	assert_str(panel.current_order_label.text).contains("Mixed orders")
	assert_str(panel.current_order_label.tooltip_text).contains("Defend").contains("Defeat").contains("Border watch")
	assert_bool(panel.edit_order_button.disabled).is_true()
	command.assign(id,[],zone,"defend");panel._update_current_order()
	assert_str(panel.current_order_label.text).contains("Defend").not_contains("Mixed")
	assert_bool(panel.edit_order_button.disabled).is_false()
	assert_str(panel.current_order_label.tooltip_text).contains("subordinate commands share this order")

func test_service_order_strip_tracks_external_orders_without_overwriting_drafts()->void:
	for domain:String in ["navy","air"]:
		var actual:=_craft(domain,12);var id:=String(command.children(domain)[0].id)
		var center:=Vector2(0,-20) if domain=="navy" else Vector2(0,5)
		var region:Dictionary=op.create_region(domain,command.R.rectangle(center,4),"Coastal patrol" if domain=="navy" else "Sky watch").region
		var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain=domain;add_child(panel)
		panel._selected(command.preview(id));panel.vision.text="Uncommitted brief"
		var task:="patrol" if domain=="navy" else "reconnaissance"
		assert_bool(op.assign(int(actual.id),region,task).has("ok")).is_true()
		command.sync();var before:Dictionary=MilitaryCampaign.export_state()
		panel._process(1.1)
		assert_str(panel.current_order_label.text).contains(task.capitalize()).contains(region.name)
		assert_str(panel._mission()).is_equal("hold");assert_dict(panel.map.selected).is_empty()
		assert_str(panel.vision.text).is_equal("Uncommitted brief")
		panel.edit_order_button.pressed.emit()
		assert_str(panel._mission()).is_equal(task);assert_str(panel.map.selected.id).is_equal(region.id)
		assert_str(panel.map.selected.domain).is_equal(domain)
		assert_dict(MilitaryCampaign.export_state()).is_equal(before)
		assert_bool(op.assign(int(actual.id),{},"hold").has("ok")).is_true()
		panel._process(1.1)
		assert_str(panel.current_order_label.text).is_equal("CURRENT  •  Hold")
		assert_str(panel._mission()).is_equal(task)
		panel.edit_order_button.pressed.emit()
		assert_str(panel._mission()).is_equal("hold");assert_dict(panel.map.selected).is_empty()
		panel.queue_free();await get_tree().process_frame

func test_city_order_edit_retains_reported_target_and_never_reads_hidden_city_changes()->void:
	CivilizationSystem.initialize();var intel=CivilizationSystem.city_intelligence
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	for index in 2:
		var city_id:=String(civ.strategic_regions[index].id)
		intel.publish("player",intel.capture("player",city_id,.8,0,"test visit","test_visit"),0)
	var target:=String(civ.strategic_regions[1].id);var report:Dictionary=intel.known("player",target)
	var id:=_home(144);var zone:=_zone(command.G.unpack(report.position),500)
	var assigned:Dictionary=command.assign(id,[],zone,"capture",target,"Secure the city")
	assert_bool(assigned.has("ok")).override_failure_message(str(assigned)).is_true()
	civ.strategic_regions[1].name="Hidden replacement name"
	var panel:CanvasLayer=auto_free(CommandPanel.new());add_child(panel);panel._selected(command.preview(id))
	var before:Dictionary=MilitaryCampaign.export_state()
	assert_str(panel.current_order_label.text).contains(report.name).not_contains("Hidden replacement")
	panel.edit_order_button.pressed.emit()
	assert_bool(panel.cities.visible).is_true();assert_str(panel.cities.get_item_metadata(panel.cities.selected)).is_equal(target)
	assert_str(panel.vision.text).is_equal("Secure the city")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	intel.records.player.erase(target);panel._update_current_order()
	assert_str(panel.current_order_label.text).contains("Unreported city").not_contains("Hidden replacement")
	assert_bool(panel.edit_order_button.disabled).is_true()

func test_missing_zone_and_cancelled_orders_do_not_load_a_misleading_draft()->void:
	var id:=_home(10);var zone:=_zone()
	assert_bool(command.assign(id,[],zone,"defend").has("ok")).is_true()
	var panel:CanvasLayer=auto_free(CommandPanel.new());add_child(panel);panel._selected(command.preview(id))
	panel.vision.text="Keep draft";_select_draft_mission(panel,"withdraw")
	command.data.zones.clear();panel._update_current_order()
	assert_bool(panel.edit_order_button.disabled).is_true()
	assert_str(panel.current_order_label.tooltip_text).contains("assigned zone is unavailable")
	panel._edit_current_order()
	assert_str(panel._mission()).is_equal("withdraw");assert_str(panel.vision.text).is_equal("Keep draft")
	panel._cancel_orders()
	assert_str(panel.current_order_label.text).is_equal("CURRENT  •  Holding")
	assert_bool(panel.edit_order_button.disabled).is_true()
	panel._selected({})
	assert_str(panel.current_order_label.text).is_equal("CURRENT  •  No command selected")
	assert_bool(panel.edit_order_button.disabled).is_true()

func test_transport_order_is_identified_without_loading_an_unsupported_mission()->void:
	for service:String in ["navy","air"]:
		var actual:=_craft(service,2);actual.mission="transport";command.sync()
		var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain=service;add_child(panel)
		panel._selected(command.preview(command.children(service)[0].id))
		assert_str(panel.current_order_label.text).is_equal("CURRENT  •  Transport")
		assert_str(panel.current_order_label.tooltip_text).contains("Ports & ships" if service=="navy" else "Airbases & aircraft")
		assert_bool(panel.edit_order_button.disabled).is_true()
		var before:Dictionary=MilitaryCampaign.export_state();panel._edit_current_order()
		assert_str(panel._mission()).is_equal("hold");assert_str(actual.mission).is_equal("transport")
		assert_dict(MilitaryCampaign.export_state()).is_equal(before)
		panel.queue_free();await get_tree().process_frame

func _mission_disabled(panel:CanvasLayer,id:String)->bool:
	for index in panel.mission.item_count:
		if panel.mission.get_item_metadata(index)==id:return panel.mission.is_item_disabled(index)
	assert_bool(false).override_failure_message("Missing mission "+id).is_true();return true

func test_air_mission_options_explain_unsupported_aircraft_before_submission()->void:
	_craft("air",12);var id:=String(command.children("air")[0].id)
	var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain="air";add_child(panel)
	panel._selected(command.preview(id))
	var before:Dictionary=MilitaryCampaign.export_state()
	assert_bool(_mission_disabled(panel,"reconnaissance")).is_false()
	assert_bool(_mission_disabled(panel,"hold")).is_false()
	assert_bool(_mission_disabled(panel,"strategic_bombing")).is_true()
	_select_draft_mission(panel,"strategic_bombing");panel._refresh_targets()
	assert_bool(panel.apply_button.disabled).is_true()
	assert_str(panel.mission_hint.text).contains("required aircraft")
	assert_str(panel.mission_hint.tooltip_text).contains(command.node(id).name)
	assert_bool(panel.mission_hint.visible).is_true()
	panel._assign()
	assert_str(panel.feedback.text).contains("required aircraft")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)

func test_headquarters_requires_compatible_subordinates_and_keeps_the_draft()->void:
	_craft("air",12);var scout_id:=String(command.children("air")[0].id)
	MilitaryCampaign.military_inventory.observation_balloon_equipment=12
	var receipt:Dictionary=op.commission(int(op.state.bases[0].id),"observation_balloon",12)
	assert_bool(receipt.has("ok")).is_true()
	var fighter:Dictionary=op.force(int(receipt.id));fighter.units={"fighter":12};fighter.authorized=fighter.units.duplicate()
	command.sync()
	var fighter_id:=""
	for leaf:Dictionary in command.leaves("air"):
		if int(leaf.force_id)==int(fighter.id):fighter_id=String(leaf.id)
	var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain="air";add_child(panel)
	panel._selected(command.preview(fighter_id));_select_draft_mission(panel,"air_superiority");panel._refresh_targets()
	assert_bool(panel.apply_button.disabled).is_false()
	var before:Dictionary=MilitaryCampaign.export_state()
	panel._selected(command.preview("air"))
	assert_str(panel._mission()).is_equal("air_superiority")
	assert_bool(panel.apply_button.disabled).is_true()
	assert_bool(panel.mission_hint.text.begins_with("1 command lacks")).is_true()
	assert_str(panel.mission_hint.tooltip_text).contains(command.node(scout_id).name)
	assert_bool(_mission_disabled(panel,"reconnaissance")).is_true()
	assert_bool(_mission_disabled(panel,"hold")).is_false()
	panel._selected(command.preview(fighter_id,[0]))
	assert_str(panel._mission()).is_equal("air_superiority")
	assert_bool(panel.apply_button.disabled).is_false()
	assert_bool(panel.mission_hint.visible).is_false()
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)

func test_mission_options_refresh_after_equipment_loss_without_changing_orders()->void:
	var actual:=_craft("air",12);actual.units={"fighter":6,"observation_balloon":6};actual.authorized=actual.units.duplicate()
	command.sync();var id:=String(command.children("air")[0].id)
	var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain="air";add_child(panel)
	panel._selected(command.preview(id));_select_draft_mission(panel,"air_superiority");panel._refresh_targets()
	assert_bool(panel.apply_button.disabled).is_false()
	actual.units.fighter=0;command.sync()
	var before:Dictionary=MilitaryCampaign.export_state()
	panel._process(1.1)
	assert_str(panel._mission()).is_equal("air_superiority")
	assert_bool(panel.apply_button.disabled).is_true()
	assert_bool(_mission_disabled(panel,"air_superiority")).is_true()
	assert_bool(_mission_disabled(panel,"reconnaissance")).is_false()
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	actual.units.fighter=6;command.sync();before=MilitaryCampaign.export_state();panel._process(1.1)
	assert_bool(panel.apply_button.disabled).is_false()
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)

func test_naval_mission_options_follow_ship_roles_and_allow_real_assignment()->void:
	var actual:=_craft("navy",12);var id:=String(command.children("navy")[0].id)
	var area:Dictionary=op.create_region("navy",command.R.rectangle(Vector2(0,-20),4),"Fleet patrol").region
	var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain="navy";add_child(panel)
	panel._selected(command.preview(id))
	assert_bool(_mission_disabled(panel,"patrol")).is_false()
	assert_bool(_mission_disabled(panel,"invasion_support")).is_true()
	_select_draft_mission(panel,"patrol");panel._region(area)
	assert_bool(panel.apply_button.disabled).is_false();panel._assign()
	assert_str(actual.mission).is_equal("patrol")
	assert_str(actual.region.id).is_equal(area.id)
	assert_str(panel.feedback.text).contains("Objective given")

func test_empty_command_blocks_submission_without_disabling_land_objectives()->void:
	var panel:CanvasLayer=auto_free(CommandPanel.new());add_child(panel)
	assert_bool(panel.apply_button.disabled).is_true()
	assert_str(panel.apply_button.tooltip_text).contains("Select an available command")
	var id:=_home(12);panel.tree.refresh();panel._selected(command.preview(id))
	assert_bool(_mission_disabled(panel,"encircle")).is_false()
	assert_bool(panel.apply_button.disabled).is_false()
	panel._selected({})
	assert_bool(panel.apply_button.disabled).is_true();assert_bool(panel.mission_hint.visible).is_false()

func _service_equipment_totals()->Dictionary:
	var result:={"units":{},"authorized":{},"crew":op.personnel()}
	for actual:Dictionary in op.state.forces:
		for field:String in ["units","authorized"]:
			for type_id:String in actual[field]:result[field][type_id]=int(result[field].get(type_id,0))+int(actual[field][type_id])
	return result

func test_virtual_air_subdivision_previews_exact_craft_and_rejects_unsupported_order()->void:
	var actual:=_craft("air",12);actual.units={"fighter":6,"observation_balloon":6};actual.authorized=actual.units.duplicate()
	command.sync();var id:=String(command.children("air")[0].id)
	var region:Dictionary=op.create_region("air",command.R.rectangle(Vector2(0,5),3),"Air watch").region
	var before:Dictionary=MilitaryCampaign.export_state()
	var balloons:Dictionary=command.preview(id,[0]);var fighters:Dictionary=command.preview(id,[2])
	assert_dict(balloons.units).is_equal({"fighter":0,"observation_balloon":4})
	assert_dict(fighters.units).is_equal({"fighter":4,"observation_balloon":0})
	var result:Dictionary=command.assign(id,[0],region,"air_superiority")
	assert_str(result.error).contains("detachment is not equipped")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	balloons.units.fighter=999
	assert_dict(command.preview(id,[0]).units).is_equal({"fighter":0,"observation_balloon":4})
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)

func test_nested_naval_preview_matches_split_and_preserves_replacement_targets()->void:
	_verify_nested_service_preview("navy")

func test_nested_air_preview_matches_split_and_preserves_replacement_targets()->void:
	_verify_nested_service_preview("air")

func _verify_nested_service_preview(domain:String)->void:
	var actual:=_craft(domain,13)
	actual.units={"war_canoe":5,"destroyer":4,"submarine":4} if domain=="navy" else {"fighter":5,"recon_plane":4,"observation_balloon":4}
	actual.authorized=actual.units.duplicate()
	for type_id:String in actual.authorized:actual.authorized[type_id]+=2
	command.sync();var id:=String(command.children(domain)[0].id)
	var before:=_service_equipment_totals();var state_before:Dictionary=MilitaryCampaign.export_state()
	var previewed:Dictionary=command.preview(id,[0,0])
	assert_dict(previewed.units).is_equal({"war_canoe":0,"destroyer":0,"submarine":3} if domain=="navy" else {"fighter":0,"recon_plane":0,"observation_balloon":2})
	assert_dict(MilitaryCampaign.export_state()).is_equal(state_before)
	var built:Dictionary=command.materialize(id,[0,0]);assert_bool(built.has("ok")).override_failure_message(str(built)).is_true()
	var detached:Dictionary=command.force(command.node(String(built.id)))
	assert_dict(detached.units).is_equal(previewed.units)
	assert_dict(_service_equipment_totals()).is_equal(before)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(MilitaryCampaign.export_state()))
	assert_bool(MilitaryCampaign.import_state(saved).has("ok")).is_true()
	var restored:Dictionary=command.force(command.node(String(built.id)))
	for type_id:String in previewed.units:assert_int(int(restored.units[type_id])).is_equal(int(previewed.units[type_id]))
	assert_dict(_service_equipment_totals()).is_equal(before)

func test_detached_aircraft_use_their_own_range_before_materialization()->void:
	var actual:=_craft("air",12);actual.units={"fighter":6,"observation_balloon":6};actual.authorized=actual.units.duplicate()
	command.sync();var id:=String(command.children("air")[0].id)
	var distance:float=(float(op.C.UNITS.fighter.range_km)+float(op.C.UNITS.observation_balloon.range_km))*.5
	var reachable:Dictionary=op.create_region("air",command.R.rectangle(Vector2(0,distance),3),"Distant air watch").region
	var far:Dictionary=op.create_region("air",command.R.rectangle(Vector2(0,5000),3),"Beyond range").region
	var before:Dictionary=MilitaryCampaign.export_state();var totals:=_service_equipment_totals()
	var rejected:Dictionary=command.assign(id,[2],far,"air_superiority")
	assert_str(rejected.error).contains("range")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	var issued:Dictionary=command.assign(id,[2],reachable,"air_superiority")
	assert_bool(issued.has("ok")).override_failure_message(str(issued)).is_true()
	var detached:Dictionary=command.force(command.node(String(issued.id)))
	assert_dict(detached.units).is_equal({"fighter":4,"observation_balloon":0})
	assert_str(detached.mission).is_equal("air_superiority")
	assert_str(detached.region.id).is_equal(reachable.id)
	assert_dict(_service_equipment_totals()).is_equal(totals)

func test_subdivision_mission_ui_and_craft_tooltip_update_without_issuing_orders()->void:
	var actual:=_craft("air",12);actual.units={"fighter":6,"observation_balloon":6};actual.authorized=actual.units.duplicate()
	command.sync();var id:=String(command.children("air")[0].id)
	var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain="air";add_child(panel)
	panel._selected(command.preview(id,[0]));_select_draft_mission(panel,"air_superiority");panel._refresh_targets()
	var before:Dictionary=MilitaryCampaign.export_state()
	assert_bool(panel.apply_button.disabled).is_true()
	assert_str(panel.selected_label.tooltip_text).contains("4 × "+String(op.C.UNITS.observation_balloon.label)).not_contains("Fighters")
	panel._selected(command.preview(id,[2]))
	assert_str(panel._mission()).is_equal("air_superiority")
	assert_bool(panel.apply_button.disabled).is_false()
	assert_str(panel.selected_label.tooltip_text).contains("4 × Fighters").not_contains(String(op.C.UNITS.observation_balloon.label))
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	panel._selected(command.preview(id,[0]))
	actual.units={"fighter":9,"observation_balloon":3};actual.authorized=actual.units.duplicate()
	before=MilitaryCampaign.export_state();panel._process(1.1)
	assert_bool(panel.apply_button.disabled).is_false()
	assert_str(panel.selected_label.tooltip_text).contains("1 × Fighters").contains("3 × "+String(op.C.UNITS.observation_balloon.label))
	assert_str(panel._mission()).is_equal("air_superiority")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)

func test_selected_air_headquarters_budget_uses_shared_fuel_once_without_issuing_orders()->void:
	var first:=_craft("air",4);first.units={"fighter":4};first.authorized=first.units.duplicate();first.training=1.0
	# Commission through the available early equipment, then install the test craft.
	MilitaryCampaign.military_inventory[op.C.UNITS.observation_balloon.equipment]=4
	var created:Dictionary=op.commission(int(first.base_id),"observation_balloon",4,"Second wing")
	assert_bool(created.has("ok")).is_true()
	var second:Dictionary=op.force(int(created.id));second.units={"fighter":4};second.authorized=second.units.duplicate();second.training=1.0
	command.sync();MilitaryCampaign.military_consumables.fuel=6
	var area:Dictionary=op.create_region("air",command.R.rectangle(Vector2(0,5),3)).region
	var before:Dictionary=MilitaryCampaign.export_state()
	var result:Dictionary=CommandPanel.Preparation.snapshot(command,command.preview("air"),area)
	assert_int(int(result.commands)).is_equal(2)
	assert_int(int(result.fuel)).is_equal(8);assert_int(int(result.shortage)).is_equal(2)
	assert_str(String(result.summary)).contains("Fuel short by 2")
	assert_str(String(result.tooltip)).contains("shared reserve")
	assert_float(float(result.training)).is_equal(1.0)
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)

func test_virtual_air_preparation_uses_only_its_craft_and_reports_assembly_without_splitting()->void:
	var actual:=_craft("air",12);actual.units={"fighter":6,"observation_balloon":6};actual.authorized=actual.units.duplicate();actual.training=.5
	command.sync();var id:=String(command.children("air")[0].id)
	var area:Dictionary=op.create_region("air",command.R.rectangle(Vector2(0,300),3)).region
	MilitaryCampaign.military_consumables.fuel=4
	var before:Dictionary=MilitaryCampaign.export_state()
	var result:Dictionary=CommandPanel.Preparation.snapshot(command,command.preview(id,[2]),area)
	assert_int(int(result.fuel)).is_equal(4)
	assert_float(float(result.coverage)).is_equal(1.0)
	assert_float(float(result.training)).is_equal(.5)
	assert_str(String(result.tooltip)).not_contains("beyond operating range")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	actual.mission="reconnaissance";before=MilitaryCampaign.export_state()
	result=CommandPanel.Preparation.snapshot(command,command.preview(id,[2]),area)
	assert_str(String(result.tooltip)).contains("Subdivide this force at its ready home base")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)

func test_next_zone_preparation_does_not_borrow_old_region_and_respects_suspended_instruction()->void:
	var actual:=_craft("air",4);actual.training=.5
	var area:Dictionary=op.create_region("air",command.R.rectangle(Vector2(0,5),3)).region
	actual.region=area;actual.mission="reconnaissance"
	MilitaryCampaign.training_staff.set_policy("air","suspended")
	var id:=String(command.children("air")[0].id);var before:Dictionary=MilitaryCampaign.export_state()
	var result:Dictionary=CommandPanel.Preparation.snapshot(command,command.preview(id),{})
	assert_float(float(result.coverage)).is_equal(0.0)
	assert_str(String(result.summary)).contains("Choose the next operating zone")
	assert_str(String(result.tooltip)).contains("Initial instruction is suspended")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)

func test_preparation_meters_update_with_staff_progress_and_resupply_without_changing_drafts()->void:
	var actual:=_craft("air",4);actual.units={"fighter":4};actual.authorized=actual.units.duplicate();actual.training=.5;actual.condition=.7
	MilitaryCampaign.military_consumables.fuel=0
	var area:Dictionary=op.create_region("air",command.R.rectangle(Vector2(0,5),3)).region
	var id:=String(command.children("air")[0].id)
	var panel:CanvasLayer=auto_free(CommandPanel.new());panel.domain="air";add_child(panel)
	panel._selected(command.preview(id));_select_draft_mission(panel,"air_superiority");panel._region(area)
	assert_bool(panel.preparation_box.visible).is_true()
	assert_float(panel.preparation_meters.training.value).is_equal_approx(50.0,.0001)
	assert_float(panel.preparation_meters.condition.value).is_equal_approx(70.0,.0001)
	assert_str(panel.preparation_note.text).contains("Fuel short")
	assert_str(panel.preparation_note.tooltip_text).contains("Repairs required")
	# A valid objective can wait for staff and supplies, without another training click.
	assert_bool(panel.apply_button.disabled).is_false()
	actual.training=1.0;actual.condition=1.0;MilitaryCampaign.military_consumables.fuel=100
	var before:Dictionary=MilitaryCampaign.export_state();panel._process(1.1)
	assert_float(panel.preparation_meters.training.value).is_equal_approx(100.0,.0001)
	assert_float(panel.preparation_meters.condition.value).is_equal_approx(100.0,.0001)
	assert_str(panel.preparation_note.text).contains("No listed preparation blockers")
	assert_str(panel.preparation_fuel.text).contains("4 fuel/day").contains("reserve 100")
	assert_str(panel._mission()).is_equal("air_superiority")
	assert_str(String(actual.mission)).is_equal("hold")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	_select_draft_mission(panel,"strategic_bombing");panel._refresh_targets()
	assert_str(panel.preparation_note.text).contains("cannot perform")
	assert_bool(panel.apply_button.disabled).is_true()

func test_readiness_matches_staff_repair_threshold_and_ignores_absent_craft_training_time()->void:
	var actual:=_craft("air",2);actual.training=.5
	var baseline:Dictionary=op.readiness(int(actual.id))
	actual.units.fighter=0;actual.authorized.fighter=0;actual.condition=.7
	var before:Dictionary=MilitaryCampaign.export_state()
	var ready:Dictionary=op.readiness(int(actual.id))
	assert_int(int(ready.training_days)).is_equal(int(baseline.training_days))
	assert_str("\n".join(ready.blockers)).contains("Repairs required")
	assert_dict(MilitaryCampaign.export_state()).is_equal(before)
	op.advance(1)
	assert_bool(bool(actual.repairing)).is_true()

func test_naval_preparation_is_separate_from_air_and_preserves_land_command_view()->void:
	var navy:=_craft("navy",2);navy.units={"torpedo_boat":2};navy.authorized=navy.units.duplicate();navy.training=1.0
	var air:=_craft("air",4);air.units={"fighter":4};air.authorized=air.units.duplicate();air.training=.25
	MilitaryCampaign.military_consumables.fuel=3
	var area:Dictionary=op.create_region("navy",command.R.rectangle(Vector2(0,-20),3)).region
	var result:Dictionary=CommandPanel.Preparation.snapshot(command,command.preview("navy"),area)
	assert_int(int(result.commands)).is_equal(1)
	assert_int(int(result.fuel)).is_equal(op.fuel_cost(navy))
	assert_float(float(result.training)).is_equal(1.0)
	var id:=_home(10)
	assert_bool(CommandPanel.Preparation.snapshot(command,command.preview(id),{}).visible).is_false()
