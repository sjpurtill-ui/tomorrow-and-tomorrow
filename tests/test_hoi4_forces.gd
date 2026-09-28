extends GdUnitTestSuite
## The Military screen's Forces and Readiness & supply tabs, as HOI4 shows
## its army overview and logistics: one row per army with the army bar's own
## numbers, bands grouped under their general, filter chips, a click that
## finds the army through the army bar, a row per force with the supply
## model's own line, and each force's gear shortfalls. Every number on the
## screen is checked against the one ledger it is read from
## (docs/ADJUDICATION.md); visible words stay short and read in both palettes.

const Forces:=preload("res://scripts/hud/forces_board.gd")
const ForcesModel:=preload("res://scripts/hud/forces_model.gd")
const Readiness:=preload("res://scripts/hud/readiness_board.gd")
const ReadinessModel:=preload("res://scripts/hud/readiness_model.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const ArmyBar:=preload("res://scripts/hud/army_bar.gd")
const Deploy:=preload("res://scripts/hud/deployment_model.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const Logistics:=preload("res://scripts/equipment_logistics.gd")
const March:=preload("res://scripts/march_terrain.gd")
const Roster:=preload("res://scripts/hud/military_roster_screen.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

## A stand-in terrain for the army bar: where it would centre the camera.
class Ground extends Node:
	var selected_army_id:=-1
	var camera_target:=Vector3.INF
	func _set_camera_target(at:Vector3)->void:camera_target=at
	func _height_at(_x:float,_z:float)->float:return 0.0

## The army bar with its orders entry point recorded (the real one opens the
## army command panel over the running map).
class RecordingBar extends "res://scripts/hud/army_bar.gd":
	var opened:Array[String]=[]
	func open_card(card:Dictionary)->void:
		select_card(card)
		opened.append(String(card.id))

## A stand-in HUD shell: its army bar, and the docks it would open.
class Shell extends Node:
	var army_bar:Control
	var docks:Array[String]=[]
	func open_dock(section:String,_sub:int,_expanded:bool=true)->void:docks.append(section)

## A stand-in map with the toolbar's Supply toggle, as the HUD builds it.
class Map extends Node:
	var hud:Node

var _processing:Dictionary={}
var home:=Vector2.ZERO
var civ_id:=""
var city_id:=""

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()
	T.set_color_mode("light")
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.food_stocks={FoodSystem.FRESH:400.0,FoodSystem.STORED:300000.0}
	GameState.simulation_metrics["food_intake_ratio"]=1.0
	GameState.population_allocations.Logistics=14
	GameState.elapsed_days=88*365
	home=CivilizationSystem.player_world_origin
	CivilizationSystem.revealed_areas.assign([{"kind":"circle","x":home.x,"z":home.y,"radius":400.0,"day":0}])
	CivilizationSystem.fog_revision+=1
	March.reset_overrides()
	March.ground_override=Callable(self,"_ground")
	March.use_roads_override=true
	March.roads_override=[]
	Supply.reset()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ_id=String(civ.id)
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	city_id=String(region.id)
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Levy band","entries":[{"unit":"levy","weapon":"improvised","count":10}]}]
	MilitaryCampaign.next_army_template_id=2

func after_test()->void:
	T.set_color_mode("light")
	March.reset_overrides()
	Supply.reset()
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
	for node:Node in _processing:node.set_process(bool(_processing[node]))

## Open level grassland (the supply tests' fixture ground).
func _ground(_p:Vector2)->Dictionary:
	return {"h":0.3,"slope":0.0,"wood":0.0,"wet":0.0,"t":0.55,"rain":0.55}

func _train(count:int)->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

func _band(count:int,name:String)->Dictionary:
	var made:Dictionary=MilitaryCampaign.create_field_army(count,name)
	return MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(made.army.army_id))]

## Out in the field, known by its runner's report.
func _send_out(army:Dictionary,offset:Vector2)->void:
	var at:=home+offset
	army["position"]={"x":at.x,"z":at.y};army["location_id"]="field";army["location_name"]="the field";army["status"]="stationed"
	army["last_report"]=MilitaryCampaign._army_report_snapshot(army)

## Tsaren, taken and held by a garrison short of some gear.
func _garrison(troops:int,missing:int)->Dictionary:
	var at:=home+Vector2(40,10)
	var day:=int(GameState.elapsed_days)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,day,"field campaign report","capture"),day)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":at.x,"z":at.y}
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.strategic_regions[CivilizationSystem._region_index(civ,city_id)]["controller"]="player"
	var force:={"civ_id":civ_id,"region_id":city_id,"region_name":"Tsaren","troops":troops,"morale":0.7,"supply_level":0.9,"commander":{"name":"Suri Vell"},
		"formations":[{"id":1,"unit":"levy","weapon":"improvised","count":troops,"authorized_count":troops,"equipment":troops-missing,"equipment_required":troops,"training":0.5,"experience":0.1}]}
	MilitaryCampaign.occupation_forces.append(force)
	return force

## A day's rations for everyone out, with full stores (food_system's call).
func _ration_day()->void:
	var need:=float(MilitaryCampaign.home_army.get("troops",0))+float(MilitaryCampaign.field_army_active_personnel())+float(MilitaryCampaign.occupation_active_personnel())
	var credit:Dictionary=MilitaryCampaign.draw_delivered_field_rations(need)
	var accessible:=(need-float(credit.total))*MilitaryCampaign.field_provision_delivery_ratio(need,credit)
	MilitaryCampaign.record_daily_provisions(need,accessible,credit)

func _forces_board(shell:Node=null,width:float=1400.0)->VBoxContainer:
	var board:VBoxContainer=auto_free(Forces.new());board.size=Vector2(width,700);add_child(board)
	board.setup({"hud":shell,"width":width} if shell!=null else {"width":width})
	return board

func _readiness_board(shell:Node=null,map:Node=null,width:float=1400.0)->VBoxContainer:
	var board:VBoxContainer=auto_free(Readiness.new());board.size=Vector2(width,700);add_child(board)
	var block:={"width":width}
	if shell!=null:block["hud"]=shell
	if map!=null:block["terrain"]=map
	board.setup(block)
	return board

func _shell()->Shell:
	var ground:Ground=auto_free(Ground.new());add_child(ground)
	var shell:Shell=auto_free(Shell.new());add_child(shell)
	var bar:=RecordingBar.new();bar.terrain=ground;shell.add_child(bar);shell.army_bar=bar
	bar.place(Rect2(100,600,1000,bar.bar_height()))
	return shell

func _control(board:VBoxContainer,id:String)->Dictionary:
	for control:Dictionary in board.live:
		if String(control.id)==id:return control
	return {}

func _card(id:String)->Dictionary:
	for card:Dictionary in BarModel.cards():
		if String(card.id)==id:return card
		for member:Dictionary in card.get("member_cards",[]):
			if String(member.id)==id:return member
	return {}

# ---------------------------------------------------------------------------
# Forces: HOI4's army overview
# ---------------------------------------------------------------------------

func test_forces_rows_read_the_army_bar_and_the_supply_model()->void:
	_train(80)
	var first:=_band(30,"Levy band 1")
	var second:=_band(20,"Levy band 2")
	(second.formations as Array)[0]["equipment"]=14
	second["morale"]=0.22
	_ration_day()
	second["provision_ratio"]=0.4;second["hungry_days"]=5.0
	var board:=_forces_board()
	var cards:=BarModel.cards()
	assert_int(board.rows.size()).is_equal(cards.size())
	for card:Dictionary in cards:
		var control:=_control(board,String(card.id))
		assert_dict(control).override_failure_message(String(card.id)).is_not_empty()
		var detail:Dictionary=card.gear_detail
		# Men against full strength, and the three bars, are the army bar's.
		var men_text:="%d/%d" % [int(card.men),int(card.full)]
		assert_str(control.men.text).is_equal(men_text)
		assert_float(float(control.meters[0].share)).is_equal_approx(float(card.gear),0.0001)
		assert_str(String(control.meters[0].text)).is_equal("%d/%d" % [int(detail.issued),int(detail.required)])
		assert_float(float(control.meters[1].share)).is_equal_approx(float(card.will),0.0001)
		assert_float(float(control.meters[2].share)).is_equal_approx(float(card.supply),0.0001)
		assert_bool(control.meters[2].fill==BarModel.supply_color(String(card.supply_state))).is_true()
		assert_str(String(control.meters[2].tooltip_text)).is_equal(BarModel.supply_line(card))
		assert_str(String(control.meters[0].tooltip_text)).is_equal(BarModel.gear_words(detail))
		assert_str(String((control.state as Control).get("state"))).is_equal(String(card.state))
	# At home a band is known today: its supply is the supply model's own.
	for army:Dictionary in [first,second]:
		var card:=_card("army:%d" % int(army.army_id))
		assert_float(float(card.supply)).is_equal_approx(float(Supply.of_army_id(int(army.army_id)).ratio),0.0001)
	var hungry:=_control(board,"army:%d" % int(second.army_id))
	assert_float(float(hungry.meters[2].share)).is_equal_approx(0.4,0.0001)
	assert_str(String((hungry.state as Control).get("state"))).is_equal("broken")
	# Short gear: the ledger's formations, amber, and a click opens Production.
	var issued:=0;var required:=0
	for formation:Dictionary in second.formations:issued+=int(formation.equipment);required+=int(formation.equipment_required)
	assert_str(String(hungry.meters[0].text)).is_equal("%d/%d" % [issued,required])
	assert_bool(bool(hungry.meters[0].clickable)).is_true()
	# Drill and experience: the formations' own, weighted by their men.
	var drill:=0.0;var men:=0
	for formation:Dictionary in first.formations:drill+=float(formation.get("training",0.0))*int(formation.count);men+=int(formation.count)
	assert_str(_control(board,"army:%d" % int(first.army_id)).drill.text).is_equal("%d%%" % roundi(drill/maxf(1.0,float(men))*100.0))
	# The template the band was raised from.
	assert_str(_control(board,"army:%d" % int(first.army_id)).template.text).is_equal("Levy band")

func test_forces_strip_sums_the_rows_and_counts_those_in_training()->void:
	_train(60)
	_band(30,"Levy band 1")
	MilitaryCampaign.military_inventory["improvised"]=6
	MilitaryCampaign.recruit_deploy.add(1)
	var board:=_forces_board()
	var men:=0
	for card:Dictionary in BarModel.cards():men+=int(card.men)
	assert_str(board.chips.men.value.text).is_equal(str(men))
	assert_str(board.chips.training.value.text).is_equal(str(int(Deploy.manpower().training)))
	assert_int(int(Deploy.manpower().training)).is_greater(0)

func test_bands_under_one_headquarters_or_general_stand_under_it()->void:
	_train(120)
	var first:=_band(30,"Levy band 1")
	var second:=_band(20,"Levy band 2")
	var third:=_band(25,"Levy band 3")
	var fourth:=_band(15,"Levy band 4")
	var command:RefCounted=MilitaryCampaign.command_hierarchy
	command.sync()
	var ids:Array=[]
	for entry:Dictionary in command.data.nodes.values():
		if entry.service=="army" and int(entry.force_id) in [int(first.army_id),int(second.army_id)]:ids.append(String(entry.id))
	assert_bool(command.organize(ids,4,"Hill army").has("ok")).is_true()
	# One general over two other bands: they stand under him.
	for army:Dictionary in [third,fourth]:army["commander"]={"name":"Oda Longmeadow","figure_id":"fig_oda"}
	var board:=_forces_board()
	var groups:Array=board.rows.filter(func(row:Dictionary)->bool:return String(row.kind)=="group")
	assert_int(groups.size()).is_equal(2)
	var hill:Dictionary=groups.filter(func(row:Dictionary)->bool:return String(row.title)=="Hill army")[0]
	assert_int((hill.bands as Array).size()).is_equal(2)
	assert_int(int(hill.men)).is_equal(50)
	var oda:Dictionary=groups.filter(func(row:Dictionary)->bool:return String(row.id)=="general:fig_oda")[0]
	assert_int(int(oda.men)).is_equal(40)
	# On the board the army comes first and its bands beneath it, indented.
	var order:Array=board.live.map(func(control:Dictionary)->Array:return [String(control.id),int(control.depth)])
	var at:=order.find([String(hill.id),0])
	assert_int(at).is_greater_equal(0)
	for band:Dictionary in hill.bands:
		assert_bool(order.has([String(band.id),1])).is_true()
		assert_int(order.find([String(band.id),1])).is_greater(at)
	assert_str(_control(board,String(hill.id)).title.text).is_equal("Hill army ×2")
	assert_str(_control(board,String(hill.id)).template.text).is_equal("2 bands")

func test_filters_pick_bands_in_the_field_garrisons_and_those_short_of_gear()->void:
	_train(80)
	var out:=_band(30,"Levy band 1")
	var short:=_band(20,"Levy band 2")
	(short.formations as Array)[0]["equipment"]=12
	_send_out(out,Vector2(22,-8))
	_garrison(12,0)
	var board:=_forces_board()
	var counts:=ForcesModel.counts(board.rows)
	assert_int(int(counts.all)).is_equal(board.rows.size())
	assert_int(int(counts.field)).is_equal(1)
	assert_int(int(counts.garrison)).is_equal(1)
	assert_int(int(counts.short)).is_equal(1)
	assert_str(board.filter_buttons.field.text).is_equal("In the field 1")
	var shown:=func(filter:String)->Array:
		board.set_filter(filter)
		return board.live.map(func(control:Dictionary)->String:return String(control.id))
	assert_array(shown.call("field")).contains_exactly(["army:%d" % int(out.army_id)])
	assert_array(shown.call("garrison")).contains_exactly(["garrison:%s/%s" % [civ_id,city_id]])
	assert_array(shown.call("short")).contains_exactly(["army:%d" % int(short.army_id)])
	assert_int((shown.call("all") as Array).size()).is_equal(board.rows.size())
	assert_bool(board.filter_buttons.all.button_pressed).is_true()
	# A band away is read from its runner's report, and says where it is.
	var away:=_control(board,"army:%d" % int(out.army_id))
	assert_str(away.where.text).contains("km")

func test_click_finds_the_army_through_the_army_bar_and_orders_open_its_panel()->void:
	_train(60)
	var army:=_band(30,"Levy band 1")
	_send_out(army,Vector2(6,-4))
	var shell:=_shell()
	var board:=_forces_board(shell)
	var id:="army:%d" % int(army.army_id)
	var control:=_control(board,id)
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	control.panel._gui_input(click)
	var bar:Control=shell.army_bar
	var ground:Ground=bar.terrain
	assert_int(ground.selected_army_id).is_equal(int(army.army_id))
	assert_float(ground.camera_target.x).is_equal_approx(home.x+6.0,0.001)
	assert_float(ground.camera_target.z).is_equal_approx(home.y-4.0,0.001)
	assert_str(bar.selected_id).is_equal(id)
	assert_str(board.selected_id).is_equal(id)
	assert_bool(bool(control.panel.chosen)).is_true()
	# The sighting ring finds it and steps the screen aside for the map.
	var closed:=[false]
	board.close_wanted.connect(func():closed[0]=true)
	(control.find as Button).pressed.emit()
	assert_bool(closed[0]).is_true()
	# Orders and a double-click open it through the army bar's own entry point.
	var opened:=[]
	board.command_opened.connect(func(kind:String):opened.append(kind))
	(control.orders as Button).pressed.emit()
	assert_array((bar as RecordingBar).opened).contains_exactly([id])
	var double:=InputEventMouseButton.new();double.button_index=MOUSE_BUTTON_LEFT;double.pressed=true;double.double_click=true
	control.panel._gui_input(double)
	assert_array((bar as RecordingBar).opened).contains_exactly([id,id])
	assert_array(opened).contains_exactly(["army","army"])
	# The home levy is found at home.
	var levy:=_control(board,"home")
	levy.panel._gui_input(click)
	assert_str(bar.selected_id).is_equal("home")
	assert_float(ground.camera_target.x).is_equal_approx(home.x,0.001)

func test_the_home_levy_calls_up_its_empty_places()->void:
	_train(40)
	var formation:Dictionary=(MilitaryCampaign.home_army.formations as Array)[0]
	formation["authorized_count"]=int(formation.count)+5
	var board:=_forces_board()
	var levy:=_control(board,"home")
	var button:Button=levy.call_up
	assert_bool(button.visible).is_true()
	assert_str(button.text).is_equal("+5")
	var before:=MilitaryCampaign._mobilized_count()
	button.pressed.emit()
	# Five free adults called up, drilling to fill that formation's places.
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(before+5)
	var orders:=MilitaryCampaign.training_queue.filter(func(order:Dictionary)->bool:return String(order.get("mode",""))=="reinforce")
	assert_int(orders.size()).is_equal(1)
	assert_int(int(orders[0].count)).is_equal(5)
	assert_int(int(orders[0].target_formation_id)).is_equal(int(formation.id))
	assert_str(board.feedback.text).is_equal("5 called up to fill the levy")

# ---------------------------------------------------------------------------
# Readiness & supply: HOI4's logistics view
# ---------------------------------------------------------------------------

func test_readiness_rows_are_the_supply_models_own_line()->void:
	_train(90)
	var near:=_band(30,"Levy band 1")
	var far:=_band(25,"Levy band 2")
	_send_out(near,Vector2(18,0))
	_send_out(far,Vector2(140,0))
	_garrison(12,4)
	_ration_day()
	far["hungry_days"]=5.0
	var board:=_readiness_board()
	var reports:=Supply.forces()
	assert_int(board.rows.size()).is_equal(reports.size())
	for report:Dictionary in reports:
		var key:=ReadinessModel.key_of(report)
		var control:Dictionary={}
		for candidate:Dictionary in board.live:
			if String(candidate.key)==key:control=candidate
		assert_dict(control).override_failure_message(key).is_not_empty()
		# The bar is the model's ratio, in its state's colour.
		assert_float(float(control.meter.share)).is_equal_approx(float(report.ratio),0.0001)
		assert_str(String(control.meter.text)).is_equal("%d%%" % roundi(float(report.ratio)*100.0))
		assert_bool(control.meter.fill==Supply.state_color(String(report.state))).is_true()
		# The hub it draws on, and the days and km along the line.
		assert_str(control.hub.text).is_equal(String(report.hub))
		if not bool(report.get("at_home",false)):
			assert_str(control.span.text).is_equal("%s · %d km" % [Supply.days_words(float(report.days)),roundi(float(report.km))])
		# The reasons are the tooltip, never the row.
		for reason in report.why:assert_str(String(control.who.tooltip_text).to_lower()).contains(String(reason).to_lower())
		assert_bool((control.hungry as Control).visible).is_equal(bool(report.hungry))
	# Farther out, less arrives; the hungry band wears its badge.
	var near_report:=Supply.of_army_id(int(near.army_id))
	var far_report:=Supply.of_army_id(int(far.army_id))
	assert_float(float(far_report.days)).is_greater(float(near_report.days))
	for control:Dictionary in board.live:
		if String(control.key)=="army:%d" % int(far.army_id):
			assert_bool((control.hungry as Control).visible).is_true()
			assert_str(control.hungry_days.text).is_equal("5 days")

func test_readiness_gear_shortfalls_are_the_equipment_ledgers_and_open_production()->void:
	_train(60)
	var band:=_band(30,"Levy band 1")
	(band.formations as Array)[0]["equipment"]=21
	_garrison(12,4)
	var shell:=_shell()
	var board:=_readiness_board(shell)
	var needs:=Logistics.needs_by_force()
	assert_int(needs.size()).is_equal(2)
	for need:Dictionary in needs:
		var key:="home" if String(need.where)=="home" else ("held:%s" % String(need.force_id) if String(need.where)=="garrison" else "army:%d" % int(need.force_id))
		var control:Dictionary={}
		for candidate:Dictionary in board.live:
			if String(candidate.key)==key:control=candidate
		assert_dict(control).override_failure_message(key).is_not_empty()
		for item:String in need.items:
			var chip:Button=(control.gear as Node).get_node_or_null("Short_"+item)
			assert_object(chip).override_failure_message("%s %s" % [key,item]).is_not_null()
			assert_str(chip.text).is_equal("−%d" % int(need.items[item]))
			assert_str(chip.tooltip_text).contains("Short %d" % int(need.items[item])).contains("in store")
	var chip:Button=board.find_child("Short_improvised",true,false)
	chip.pressed.emit()
	assert_array(shell.docks).contains(["production"])

func test_readiness_strip_is_the_models_carriers_hubs_and_rations()->void:
	_train(40)
	var band:=_band(20,"Levy band 1")
	_send_out(band,Vector2(30,0))
	_garrison(10,0)
	GameState.resource_stockpiles["Transport Carts"]=6.0
	_ration_day()
	var board:=_readiness_board()
	var strip:=ReadinessModel.strip()
	assert_str(String(strip.carrier)).is_equal(Supply.carrier())
	assert_str(board.chips.carriers.word.text).is_equal("carts")
	assert_str(board.chips.carriers.value.text).is_equal("6")
	assert_str(board.chips.carried.value.text).is_equal("%d%%" % roundi(float(Supply.day_inputs().transport)*100.0))
	var hubs:=0;var depots:=0
	for hub:Dictionary in Supply.hubs():
		if String(hub.kind)=="held":depots+=1
		else:hubs+=1
	assert_str(board.chips.hubs.value.text).is_equal(str(hubs))
	assert_str(board.chips.depots.value.text).is_equal(str(depots))
	assert_int(depots).is_equal(1)
	var rations:=float(MilitaryCampaign.economic_burden_snapshot().daily_field_provisions)
	assert_str(board.chips.rations.value.text).is_equal(str(roundi(rations)) if rations>=10.0 else "%.1f" % rations)

func test_show_supply_on_the_map_throws_the_supply_maps_own_switch()->void:
	var map:Map=auto_free(Map.new());add_child(map)
	var hud:=Node.new();map.add_child(hud);map.hud=hud
	var toggle:=Button.new();toggle.name="ToolbarSupply";toggle.toggle_mode=true;hud.add_child(toggle)
	var board:=_readiness_board(null,map)
	assert_bool(board.map_button.visible).is_true()
	var closed:=[false]
	board.close_wanted.connect(func():closed[0]=true)
	board.map_button.pressed.emit()
	assert_bool(toggle.button_pressed).is_true()
	assert_bool(closed[0]).is_true()

# ---------------------------------------------------------------------------
# The screen: numbers, bars, glyphs; words in tooltips
# ---------------------------------------------------------------------------

func _walk(node:Node,out:Array)->void:
	out.append(node)
	for child in node.get_children():_walk(child,out)

func _long_texts(root:Node)->Array:
	var nodes:Array=[];_walk(root,nodes)
	var long:Array=[]
	for node in nodes:
		if not (node is Label or node is Button):continue
		if not (node as Control).is_visible_in_tree():continue
		var text:String=(node as Label).text if node is Label else (node as Button).text
		var words:=RegEx.create_from_string("[A-Za-z0-9']+").search_all(text).size()
		if words>12:long.append("%s: %s" % [node.name,text])
	return long

func _stage_war()->void:
	_train(120)
	var out:=_band(30,"Levy band 1")
	var short:=_band(20,"Levy band 2")
	(short.formations as Array)[0]["equipment"]=12
	_send_out(out,Vector2(60,-8))
	out["hungry_days"]=6.0
	_garrison(12,3)
	MilitaryCampaign.military_inventory["improvised"]=6
	MilitaryCampaign.recruit_deploy.add(1)
	_ration_day()

func test_no_visible_label_over_twelve_words_on_either_tab()->void:
	_stage_war()
	for width:float in [1400.0,700.0]:
		var forces:=_forces_board(null,width)
		var readiness:=_readiness_board(null,null,width)
		await get_tree().process_frame
		assert_array(_long_texts(forces)).is_empty()
		assert_array(_long_texts(readiness)).is_empty()
	# And inside the Military screen, where the old paragraphs were.
	for page:String in ["forces","support","training"]:
		MilitaryCampaign.open_roster("army",page=="training",page)
		await get_tree().process_frame
		assert_array(_long_texts(MilitaryCampaign.roster_screen.body)).override_failure_message(page).is_empty()
		MilitaryCampaign.roster_screen.free()

## What a label sits on: the nearest panel's paper, laid over what is below.
func _ground_of(node:Node)->Color:
	var parent:=node.get_parent()
	while parent!=null:
		if parent is PanelContainer:
			var style:=(parent as PanelContainer).get_theme_stylebox("panel")
			if style is StyleBoxFlat:
				var bg:=(style as StyleBoxFlat).bg_color
				if bg.a>=0.999:return bg
				return _ground_of(parent).lerp(Color(bg.r,bg.g,bg.b),bg.a)
		parent=parent.get_parent()
	return T.paper_panel_style(false).bg_color

func _contrast_failures(root:Node)->Array:
	var nodes:Array=[];_walk(root,nodes)
	var failures:Array=[]
	for node in nodes:
		if node is Label and (node as Label).is_visible_in_tree() and (node as Label).text!="":
			var ink:=(node as Label).get_theme_color("font_color")
			var ratio:=T.contrast(ink,_ground_of(node))
			if ratio<4.5:failures.append("%s '%s' %.2f" % [node.name,(node as Label).text,ratio])
		elif node is Button and (node as Button).is_visible_in_tree():
			var button:Button=node
			for state:Array in [["font_color","normal",4.5],["font_hover_color","hover",4.5],["font_pressed_color","pressed",4.5],["font_disabled_color","disabled",3.0]]:
				var style:=button.get_theme_stylebox(String(state[1]))
				if not style is StyleBoxFlat:failures.append("%s has no %s style" % [button.name,state[1]]);continue
				var bg:=(style as StyleBoxFlat).bg_color
				var ground:=_ground_of(button).lerp(Color(bg.r,bg.g,bg.b),bg.a)
				var ratio:=T.contrast(button.get_theme_color(String(state[0])),ground)
				if ratio<float(state[2]):failures.append("%s %s %.2f" % [button.name,state[1],ratio])
	return failures

func test_both_tabs_read_in_light_and_dark()->void:
	_stage_war()
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		var forces:=_forces_board()
		var readiness:=_readiness_board()
		await get_tree().process_frame
		assert_array(_contrast_failures(forces)).override_failure_message(mode).is_empty()
		assert_array(_contrast_failures(readiness)).override_failure_message(mode).is_empty()
		# The numbers the bars draw are ink on the row's paper.
		assert_float(T.contrast(T.INK,T.PAPER_RAISED)).is_greater_equal(4.5)
		assert_float(T.contrast(T.INK,T.HOVER_BG)).is_greater_equal(4.5)
