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
			panel.details_toggle.pressed.emit()
			panel._draw_zone()
			panel._report({"error":"Supply and route information with enough detail to wrap across several lines. ".repeat(8)})
			await get_tree().process_frame
			panel._process(0)
			await get_tree().process_frame
			assert_bool(panel.orders_scroll.get_global_rect().encloses(panel.mission.get_global_rect())).is_true()
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
	assert_dict(panel.selected).is_empty();assert_str(panel.selected_label.text).contains("Select a command")
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
