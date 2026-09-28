extends GdUnitTestSuite
## The HOI4-style army screens: the deployment queue (templates, three bars
## per band, dates, deploy early, auto-deploy), the army bar along the map's
## bottom, and the compact army command panel with map-picked targets and
## drawn battle plans. Every number is checked against the one ledger it is
## read from, and the orders against the objectives the old form gave.

const Orders:=preload("res://scripts/army_orders.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Board:=preload("res://scripts/hud/recruit_deploy_board.gd")
const Deploy:=preload("res://scripts/hud/deployment_model.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const ArmyBar:=preload("res://scripts/hud/army_bar.gd")
const ArmyPanel:=preload("res://scripts/hud/command_hierarchy_panel.gd")
const Overlay:=preload("res://scripts/hud/service_world_overlay.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

## A flat stand-in for the terrain camera: 10 px per km round (400,400) at home.
class Map extends Overlay:
	var origin:=Vector2.ZERO
	func world_to_screen(point:Vector2)->Vector2:return (point-origin)*10.0+Vector2(400,400)
	func screen_to_world(point:Vector2)->Dictionary:
		var at:=(point-Vector2(400,400))/10.0+origin
		return {"x":at.x,"z":at.y}

## A stand-in terrain for the army bar: where it would centre the camera.
class Ground extends Node:
	var selected_army_id:=-1
	var camera_target:=Vector3.INF
	func _set_camera_target(at:Vector3)->void:camera_target=at
	func _height_at(_x:float,_z:float)->float:return 0.0

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var _processing:Dictionary={}

func _land(_p:Vector2)->bool:return true

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	FoodSystem.receive_external_food(100000)
	GameState.elapsed_days=88*365
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Tsaren"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=false; relation.treaty="none"; relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	home=CivilizationSystem.player_world_origin
	city=home+Vector2(-30.0,12.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	CivilizationSystem.revealed_areas=[{"x":home.x,"z":home.y,"radius":100000.0}]
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Levy band","entries":[{"unit":"levy","weapon":"improvised","count":10}]}]
	MilitaryCampaign.next_army_template_id=2

func after_test()->void:
	T.set_color_mode("light")
	CivilizationSystem.set_scout_geography_authority(Callable())
	Route.clear_cache()
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

func _train(count:int)->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

func _set_garrison(mid:float)->void:
	var rec:Dictionary=CivilizationSystem.city_intelligence.records.player[city_id]
	rec.fields["garrison"]={"low":mid,"high":mid,"observed_day":int(GameState.elapsed_days),"reported_day":int(GameState.elapsed_days)}

func _board()->VBoxContainer:
	var board:VBoxContainer=auto_free(Board.new());board.size=Vector2(1200,700);add_child(board)
	board.setup({"edit_template":func(_id:int):pass})
	return board

func _panel()->CanvasLayer:
	var panel:CanvasLayer=auto_free(ArmyPanel.new());panel.domain="army";add_child(panel)
	var stub:=Map.new();stub.domain="army";stub.origin=home;panel.add_child(stub);panel.map.queue_free();panel.map=stub
	return panel

func _click(panel:CanvasLayer,at:Vector2,button:int=MOUSE_BUTTON_LEFT)->bool:
	var event:=InputEventMouseButton.new();event.pressed=true;event.button_index=button;event.position=at
	return panel.handle_map_input(event)

func _row_for(board:VBoxContainer,slot:int)->Dictionary:
	for control:Dictionary in board.live:
		if int(control.get("slot",-1))==slot:return control
	return {}

func _army_shape(army_id:int)->Dictionary:
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
	return {"status":army.status,"destination_id":army.destination_id,"troops":army.troops,"order_kind":(army.get("court_order",{}) as Dictionary).get("kind",""),"order_city":(army.get("court_order",{}) as Dictionary).get("city_id","")}

# ---------------------------------------------------------------------------
# The deployment queue
# ---------------------------------------------------------------------------

func test_queue_rows_show_the_ledgers_three_bars()->void:
	MilitaryCampaign.military_inventory["improvised"]=6
	var line:Dictionary=MilitaryCampaign.recruit_deploy.add(1)
	for order:Dictionary in MilitaryCampaign.training_queue:order.progress_days=float(order.required_days)*0.35
	var board:=_board()
	var item:=MilitaryCampaign.recruit_deploy.line(int(line.id))
	var slot:=int(item.slots[0])
	var state:=MilitaryCampaign.recruit_deploy.status(int(line.id),slot)
	var row:=_row_for(board,slot)
	assert_dict(row).is_not_empty()
	var meters:Array=row.meters
	assert_float(float(meters[0].share)).is_equal_approx(float(state.people)/float(state.target),0.001)
	assert_float(float(meters[1].share)).is_equal_approx(float(state.equipment)/float(state.equipment_required),0.001)
	assert_float(float(meters[2].share)).is_equal_approx(float(state.training),0.001)
	assert_str(String(meters[1].text)).is_equal("%d/%d" % [int(state.equipment),int(state.equipment_required)])
	# Short gear: amber, with what is missing and where to make it.
	assert_bool(int(state.equipment)<int(state.equipment_required)).is_true()
	assert_bool(meters[1].fill==T.AMBER).is_true()
	assert_str(String(meters[1].tooltip_text)).contains("Short").contains("Click to open production")
	assert_bool(bool(meters[1].clickable)).is_true()
	# A date ready, from the same instruction estimate the staff use.
	var band:Dictionary=Deploy.lines()[0].bands[0]
	assert_str(String(row.date.text)).is_equal(Deploy.day_words(int(band.ready_day)) if int(band.ready_day)>=0 else "—")

func test_manpower_strip_adds_up_to_everyone_who_could_serve()->void:
	_train(40)
	MilitaryCampaign.recruit_deploy.add(1)
	var board:=_board()
	var m:=Deploy.manpower()
	assert_str(board.chips.free.value.text).is_equal(str(int(m.free)))
	assert_str(board.chips.serving.value.text).is_equal(str(int(m.serving)))
	assert_str(board.chips.training.value.text).is_equal(str(int(m.training)))
	assert_int(int(m.free)+int(m.serving)+int(m.training)).is_equal(MilitaryCampaign.recruitment_capacity())
	assert_int(int(m.training)).is_equal(MilitaryCampaign._queued_trainees()+MilitaryCampaign.aggregate_recruits)

func test_train_asks_for_one_band_and_times_five_for_five()->void:
	MilitaryCampaign.military_inventory["improvised"]=100
	var board:=_board()
	(board.find_child("TrainTemplate1",true,false) as Button).pressed.emit()
	assert_int(MilitaryCampaign.recruit_deploy.data.lines.size()).is_equal(1)
	var first:Dictionary=MilitaryCampaign.recruit_deploy.data.lines[0]
	assert_int(first.slots.size()+int(first.remaining)).is_equal(1)
	assert_bool(bool(first.repeat)).is_false()
	(board.find_child("TrainFive1",true,false) as Button).pressed.emit()
	var five:Dictionary=MilitaryCampaign.recruit_deploy.data.lines[1]
	assert_int(int(five.parallel)).is_equal(5)
	assert_int(five.slots.size()+int(five.remaining)).is_equal(5)
	# Five bands drill side by side: every one that has people has a row
	# (four to a page).
	assert_int(five.slots.size()).is_equal(5)
	assert_int(board.live.filter(func(c:Dictionary)->bool:return c.has("slot")).size()).is_equal(first.slots.size()+mini(4,five.slots.size()))

func test_more_and_fewer_change_the_bands_asked_for()->void:
	MilitaryCampaign.military_inventory["improvised"]=100
	var result:=MilitaryCampaign.recruit_deploy.add(1)
	var id:=int(result.id)
	var board:=_board()
	var line_card:Node=board.find_child("Line%d" % id,true,false)
	(line_card.find_child("More",true,false) as Button).pressed.emit()
	var item:=MilitaryCampaign.recruit_deploy.line(id)
	assert_int(item.slots.size()+int(item.remaining)).is_equal(2)
	line_card=board.find_child("Line%d" % id,true,false)
	(line_card.find_child("Fewer",true,false) as Button).pressed.emit()
	item=MilitaryCampaign.recruit_deploy.line(id)
	assert_int(item.slots.size()+int(item.remaining)).is_equal(1)
	# Stood-down recruits go home and their gear back to store.
	assert_int(MilitaryCampaign._queued_trainees()).is_equal(10)

func test_deploy_early_sends_the_band_off_with_its_real_people()->void:
	MilitaryCampaign.military_inventory["improvised"]=10
	var result:=MilitaryCampaign.recruit_deploy.add(1)
	var board:=_board()
	var slot:=int(MilitaryCampaign.recruit_deploy.line(int(result.id)).slots[0])
	var row:=_row_for(board,slot)
	assert_bool((row.deploy as Button).disabled).is_true()
	for order:Dictionary in MilitaryCampaign.training_queue:order.progress_days=float(order.required_days)*0.25
	board.update_values()
	assert_bool((row.deploy as Button).disabled).is_false()
	assert_str((row.deploy as Button).text).is_equal("Deploy early")
	var mobilized:=MilitaryCampaign._mobilized_count()
	(row.deploy as Button).pressed.emit()
	assert_int(MilitaryCampaign.field_army_active_personnel()).is_equal(10)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(mobilized)

func test_auto_deploy_switch_holds_or_sends_a_trained_band()->void:
	MilitaryCampaign.military_inventory["improvised"]=10
	var result:=MilitaryCampaign.recruit_deploy.add(1)
	var id:=int(result.id)
	var board:=_board()
	var auto:CheckButton=board.find_child("Line%d" % id,true,false).find_child("AutoDeploy",true,false)
	assert_bool(auto.button_pressed).is_true()
	auto.toggled.emit(false)
	assert_bool(bool(MilitaryCampaign.recruit_deploy.line(id).auto_deploy)).is_false()
	for order:Dictionary in MilitaryCampaign.training_queue:order.progress_days=order.required_days
	MilitaryCampaign.recruit_deploy.deploy_ready()
	assert_int(MilitaryCampaign.field_army_active_personnel()).is_equal(0)
	board.update_values()
	var row:=_row_for(board,int(MilitaryCampaign.recruit_deploy.line(id).slots[0]))
	assert_str(String(row.date.text)).is_equal("Ready")
	auto=board.find_child("Line%d" % id,true,false).find_child("AutoDeploy",true,false)
	auto.toggled.emit(true)
	MilitaryCampaign.recruit_deploy.deploy_ready()
	assert_int(MilitaryCampaign.field_army_active_personnel()).is_equal(10)

func test_day_words_are_a_calendar_date_not_a_day_number()->void:
	var today:=int(GameState.elapsed_days)
	var words:=Deploy.day_words(today+3)
	assert_bool(RegEx.create_from_string("^[0-9]{1,2} (Spring|Summer|Autumn|Winter)$").search(words)!=null).override_failure_message(words).is_true()
	assert_str(Deploy.day_words(today+2000)).contains(", year ")

# ---------------------------------------------------------------------------
# The army bar
# ---------------------------------------------------------------------------

func test_army_bar_has_one_card_per_force_with_the_ledgers_numbers()->void:
	_train(80)
	var first:Dictionary=MilitaryCampaign.create_field_army(30,"Levy band 1")
	var second:Dictionary=MilitaryCampaign.create_field_army(20,"Levy band 2")
	var a:=int(first.army.army_id);var b:=int(second.army.army_id)
	var army_b:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(b)]
	army_b["morale"]=0.2
	army_b["hungry_days"]=5.0;army_b["provision_ratio"]=0.4
	var cards:=BarModel.cards()
	assert_int(cards.size()).is_equal(3)
	assert_str(String(cards[0].kind)).is_equal("home")
	assert_int(int(cards[0].men)).is_equal(int(MilitaryCampaign.home_army.troops))
	var by_army:={}
	for card:Dictionary in cards:
		if String(card.kind)=="army":by_army[int(card.army_id)]=card
	assert_int(int(by_army[a].men)).is_equal(30)
	assert_int(int(by_army[b].men)).is_equal(20)
	assert_float(float(by_army[b].will)).is_equal_approx(0.2,0.001)
	assert_float(float(by_army[b].supply)).is_equal_approx(0.4,0.001)
	assert_str(String(by_army[b].supply_state)).is_equal("starving")
	# Broken is more pressing than hungry.
	assert_str(String(by_army[b].state)).is_equal("broken")
	army_b["morale"]=0.7
	assert_str(String(BarModel.army_card(MilitaryCampaign,army_b).state)).is_equal("hungry")
	assert_str(String(by_army[a].state)).is_equal("holding")
	var gear:Dictionary=by_army[a].gear_detail
	var issued:=0;var required:=0
	for formation:Dictionary in MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(a)].formations:
		issued+=int(formation.equipment);required+=int(formation.equipment_required)
	assert_int(int(gear.issued)).is_equal(issued)
	assert_int(int(gear.required)).is_equal(required)

func test_army_bar_groups_bands_their_general_leads_together()->void:
	_train(80)
	var first:Dictionary=MilitaryCampaign.create_field_army(30,"Levy band 1")
	var second:Dictionary=MilitaryCampaign.create_field_army(20,"Levy band 2")
	var command:RefCounted=MilitaryCampaign.command_hierarchy
	command.sync()
	var ids:Array=[]
	for entry:Dictionary in command.data.nodes.values():
		if entry.service=="army" and int(entry.force_id) in [int(first.army.army_id),int(second.army.army_id)]:ids.append(String(entry.id))
	assert_bool(command.organize(ids,4,"Hill army").has("ok")).is_true()
	var groups:=BarModel.cards().filter(func(card:Dictionary)->bool:return String(card.kind)=="group")
	assert_int(groups.size()).is_equal(1)
	assert_str(String(groups[0].title)).is_equal("Hill army")
	assert_int(int(groups[0].men)).is_equal(50)
	assert_int((groups[0].members as Array).size()).is_equal(2)

func test_army_bar_click_selects_and_centres_on_the_army()->void:
	_train(40)
	var made:Dictionary=MilitaryCampaign.create_field_army(30,"Levy band 1")
	var army_id:=int(made.army.army_id)
	var index:=MilitaryCampaign._field_army_index(army_id)
	MilitaryCampaign.field_armies[index]["position"]={"x":home.x+6.0,"z":home.y-4.0}
	# Away from home, the bar knows it by its runner's report, as the map does.
	MilitaryCampaign.field_armies[index]["last_report"]=MilitaryCampaign._army_report_snapshot(MilitaryCampaign.field_armies[index])
	var ground:Ground=auto_free(Ground.new());add_child(ground)
	var bar:Control=auto_free(ArmyBar.new());bar.terrain=ground;add_child(bar)
	bar.place(Rect2(100,600,1000,bar.bar_height()))
	bar.refresh()
	assert_int(bar.strip.get_child_count()).is_equal(bar.cards.size())
	var card:Dictionary={}
	for candidate:Dictionary in bar.cards:
		if int(candidate.army_id)==army_id:card=candidate
	bar.select_card(card)
	assert_int(ground.selected_army_id).is_equal(army_id)
	assert_float(ground.camera_target.x).is_equal_approx(home.x+6.0,0.001)
	assert_float(ground.camera_target.z).is_equal_approx(home.y-4.0,0.001)
	assert_str(bar.selected_id).is_equal(String(card.id))
	# Every card says what its bars mean.
	for face:Control in bar.strip.get_children():assert_str(face._get_tooltip(Vector2(2,2))).contains("Will to fight")

func test_army_bar_keeps_to_the_corner_and_waits_for_an_army()->void:
	# The player: the lone "Home 1" card over the middle of the map was "an
	# annoying place". The levy alone shows no bar; with a band out the cards
	# start at the bar's left edge, the levy last.
	var ground:Ground=auto_free(Ground.new());add_child(ground)
	var bar:Control=auto_free(ArmyBar.new());bar.terrain=ground;add_child(bar)
	_train(40)
	bar.refresh();bar.place(Rect2(100,600,1000,bar.bar_height()))
	assert_bool(bar.visible).override_failure_message("the levy alone must not show the bar").is_false()
	assert_array(ArmyBar.shown_cards([{"id":"home","kind":"home","state":"fighting"}])).has_size(1)
	var made:Dictionary=MilitaryCampaign.create_field_army(30,"Levy band 1")
	var index:=MilitaryCampaign._field_army_index(int(made.army.army_id))
	MilitaryCampaign.field_armies[index]["position"]={"x":home.x+6.0,"z":home.y-4.0}
	MilitaryCampaign.field_armies[index]["last_report"]=MilitaryCampaign._army_report_snapshot(MilitaryCampaign.field_armies[index])
	bar.refresh();bar.place(Rect2(100,600,1000,bar.bar_height()))
	assert_bool(bar.visible).is_true()
	assert_float(bar.strip.position.x).is_equal(0.0)
	var kinds:Array=bar.cards.map(func(c:Dictionary)->String:return String(c.kind))
	assert_str(String(kinds[0])).is_not_equal("home")
	if kinds.has("home"):assert_str(String(kinds[kinds.size()-1])).is_equal("home")

# ---------------------------------------------------------------------------
# The army command panel
# ---------------------------------------------------------------------------

func test_map_picked_target_gives_the_same_objective_as_the_old_form()->void:
	_train(400);_set_garrison(40.0)
	var form:=Orders.give(Orders.HOME,"attack",{"type":"place","place":Orders.place(city_id)})
	assert_str(String(form.verdict)).override_failure_message(String(form.says)).is_equal("act")
	var said:Dictionary=form.objective
	var said_army:=_army_shape(int(said.army_id))
	before_test()
	_train(400);_set_garrison(40.0)
	var panel:=_panel()
	panel.choose_force(Orders.HOME)
	var stub:Map=panel.map
	assert_bool(_click(panel,stub.world_to_screen(city)+Vector2(4,-3))).is_true()
	assert_str(panel.verb_id).is_equal("attack")
	assert_bool(panel.give_button.disabled).is_false()
	panel._give(false)
	var given:Dictionary=panel.last_answer
	assert_str(String(given.verdict)).is_equal("act")
	for key in ["kind","city_id","civ_id","troops","days","route_km"]:
		assert_str(str(given.objective[key])).override_failure_message(key).is_equal(str(said[key]))
	assert_dict(_army_shape(int(given.objective.army_id))).is_equal(said_army)

func test_hover_shows_the_road_and_the_same_days_the_order_states()->void:
	_train(60);_set_garrison(10.0)
	var panel:=_panel()
	panel.choose_force(Orders.HOME);panel.choose_verb("attack")
	var stub:Map=panel.map
	panel.hover_target(stub.world_to_screen(city))
	var expected:=Orders.preview(Orders.HOME,"attack",{"type":"place","place":Orders.place(city_id)})
	assert_bool((panel.hover.get("road",[]) as Array).size()>=2).is_true()
	var days:=int(expected.days)
	assert_str(String(panel.hover.words)).contains("%d %s" % [days,"day" if days==1 else "days"])
	# The chosen town's line is numbers: men, days, the day they arrive.
	panel.choose_place(city_id)
	assert_str(panel.happens_label.text).is_equal(Orders.summary(Orders.preview(Orders.HOME,"attack",panel.target)))
	assert_str(panel.happens_label.text).contains(" men · ").contains("arrive ")
	assert_str(panel.happens_label.tooltip_text).contains("The road to")

func test_drawn_front_line_is_held_as_a_defended_zone_along_it()->void:
	_train(60)
	var made:Dictionary=MilitaryCampaign.create_field_army(40,"Levy band 1")
	var army_id:=int(made.army.army_id)
	var panel:=_panel()
	panel.choose_force(army_id)
	panel.choose_verb("front")
	assert_str(panel.plan_mode).is_equal("front")
	var stub:Map=panel.map
	for p:Vector2 in [home+Vector2(6,-8),home+Vector2(9,0),home+Vector2(7,8)]:assert_bool(_click(panel,stub.world_to_screen(p))).is_true()
	assert_bool(_click(panel,stub.world_to_screen(home+Vector2(20,20)),MOUSE_BUTTON_RIGHT)).is_true()
	assert_str(panel.plan_mode).is_empty()
	assert_str(String(panel.target.type)).is_equal("front")
	assert_int((panel.target.points as Array).size()).is_equal(3)
	assert_str(panel.happens_label.text).contains("km line")
	panel._give(false)
	assert_str(String(panel.last_answer.verdict)).override_failure_message(String(panel.last_answer.get("outcome",""))).is_equal("act")
	var zones:Array=MilitaryCampaign.command_hierarchy.data.zones
	assert_int(zones.size()).is_equal(1)
	assert_str(String(zones[0].get("plan",""))).is_equal("front")
	assert_int((zones[0].line as Array).size()).is_equal(3)
	assert_bool(Orders.R.contains(zones[0],home+Vector2(9,0))).is_true()
	assert_bool(MilitaryCampaign.command_hierarchy.controls_army(army_id)).is_true()
	# Held ground survives a save.
	var saved:Dictionary=bytes_to_var(var_to_bytes(MilitaryCampaign.command_hierarchy.export_state()))
	assert_str(MilitaryCampaign.command_hierarchy.validate(saved)).is_empty()

func test_offensive_arrow_at_a_town_attacks_it_and_on_open_ground_advances()->void:
	_train(120);_set_garrison(4.0)
	var made:Dictionary=MilitaryCampaign.create_field_army(60,"Levy band 1")
	var army_id:=int(made.army.army_id)
	var panel:=_panel()
	panel.choose_force(army_id)
	panel.choose_verb("arrow")
	var stub:Map=panel.map
	assert_bool(_click(panel,stub.world_to_screen(city)+Vector2(3,2))).is_true()
	assert_str(String(panel.target.type)).is_equal("arrow")
	assert_str(String(panel.target.aim.verb)).is_equal("attack")
	panel._give(true)
	assert_str(String(panel.last_answer.verdict)).override_failure_message(String(panel.last_answer.get("outcome",""))).is_equal("act")
	var shape:=_army_shape(army_id)
	assert_str(String(shape.order_kind)).is_equal("attack")
	assert_str(String(shape.destination_id)).is_equal(city_id)
	# The same arrow the court's order would be: the objective matches give().
	var aim:=Orders.arrow_target(city)
	assert_str(String(aim.verb)).is_equal("attack")
	# On open ground the arrow is an advance to that ground.
	var second:Dictionary=MilitaryCampaign.create_field_army(40,"Levy band 2")
	var other:=int(second.army.army_id)
	panel.choose_force(other);panel.choose_verb("arrow")
	var ground:=home+Vector2(14,10)
	assert_bool(_click(panel,stub.world_to_screen(ground))).is_true()
	assert_str(String(panel.target.aim.verb)).is_equal("goto")
	panel._give(false)
	assert_str(String(panel.last_answer.verdict)).is_equal("act")
	var marched:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(other)]
	assert_str(String(marched.status)).is_equal("moving")
	assert_float(float(marched.destination_position.x)).is_equal_approx(ground.x,0.01)

func test_escape_stops_a_plan_without_closing_the_panel()->void:
	_train(40)
	var panel:=_panel()
	panel.choose_verb("front")
	panel.plan_point(home+Vector2(4,0))
	var escape:=InputEventKey.new();escape.pressed=true;escape.keycode=KEY_ESCAPE
	assert_bool(panel.handle_early_input(escape)).is_true()
	assert_str(panel.plan_mode).is_empty()
	assert_bool(panel.is_queued_for_deletion()).is_false()

# ---------------------------------------------------------------------------
# Little text
# ---------------------------------------------------------------------------

func _walk(node:Node,out:Array)->void:
	out.append(node)
	for child in node.get_children():_walk(child,out)

func _long_texts(root:Node,skip:Array=[])->Array:
	var nodes:Array=[];_walk(root,nodes)
	var long:Array=[]
	for node in nodes:
		if node in skip or not (node is Label or node is Button):continue
		if not (node as Control).is_visible_in_tree():continue
		var text:String=(node as Label).text if node is Label else (node as Button).text
		var words:=RegEx.create_from_string("[A-Za-z0-9']+").search_all(text).size()
		if words>12:long.append("%s: %s" % [node.name,text])
	return long

func test_main_surfaces_have_no_paragraph_over_twelve_words()->void:
	_train(60);_set_garrison(10.0)
	MilitaryCampaign.create_field_army(30,"Levy band 1")
	MilitaryCampaign.military_inventory["improvised"]=4
	MilitaryCampaign.recruit_deploy.add(1)
	var board:=_board()
	await get_tree().process_frame
	assert_array(_long_texts(board)).is_empty()
	var panel:=_panel()
	panel.choose_verb("attack");panel.choose_place(city_id)
	await get_tree().process_frame
	# The general's own answer is his voice, not the screen's.
	assert_array(_long_texts(panel.panel,[panel.answer_label,panel.answer_outcome])).is_empty()
	var ground:Ground=auto_free(Ground.new());add_child(ground)
	var bar:Control=auto_free(ArmyBar.new());bar.terrain=ground;add_child(bar)
	bar.refresh()
	assert_array(_long_texts(bar)).is_empty()
