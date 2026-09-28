extends GdUnitTestSuite
## The HOI4-style Production screen: the numbers on screen match the model,
## line order is priority, deficits and levy badges show, and the main surface
## carries numbers and icons rather than paragraphs.
const Logistics=preload("res://scripts/equipment_logistics.gd")
const P=preload("res://scripts/persistent_production.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(7511);MilitaryCampaign.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.resource_stockpiles={"Timber":100.0,"Stone":50.0}
	GameState.population_allocations.Crafting=10;GameState.population_allocations.Logistics=10;GameState.population_allocations.Defense=0
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	GameState.settlement_plots=[{"land_use":"workshop","worker_capacity":100,"condition":1.0,"status":"active","damage":{}}]
	GameState.settlement_name="Workshop Town";GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	for id:String in ["hafted_weapons"]:
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0
	MilitaryCampaign.army_templates=[]
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[],.8,.7)
func after_test()->void:WorldSimulation.clear()

static func _formation(unit:String,weapon:String,count:int,equipment:int)->Dictionary:
	return {"id":MilitaryCampaign.next_formation_id,"unit":unit,"weapon":weapon,"count":count,"authorized_count":count,"equipment":equipment,"equipment_required":count,"ammunition":0,"ammunition_required":0,"training":.6,"experience":0.0}

func _levy_at_home(count:int,equipment:int)->void:
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[_formation("levy","improvised",count,equipment)],.8,.7)

# --- Shared logistics numbers ------------------------------------------------------

func test_needs_split_fielded_training_and_called_up()->void:
	_levy_at_home(20,12)
	MilitaryCampaign.training_queue=[{"id":1,"mode":"new","unit":"spearman","weapon":"spear","count":6,"initial_count":6,"progress_days":1.0,"required_days":14.0,"reserved_equipment":2}]
	MilitaryCampaign.military_inventory["improvised"]=3
	MilitaryCampaign.military_inventory["spear"]=1
	var levy:=Logistics.row("improvised")
	assert_int(int(levy.stock)).is_equal(3)
	assert_int(int(levy.fielded)).is_equal(8)
	assert_int(int(levy.needed)).is_equal(8)
	assert_int(int(levy.deficit)).is_equal(5)
	assert_str(String(levy["for"][0].who)).ends_with("levy")
	var spears:=Logistics.row("spear")
	assert_int(int(spears.training)).is_equal(4)
	assert_int(int(spears.deficit)).is_equal(3)
	assert_int(Logistics.deficit("spear")).is_equal(3)
	# Called-up watch: the Defense allocation not yet in drill wants clubs.
	GameState.population_allocations.Defense=25
	var called:=Logistics.row("improvised")
	assert_int(int(called.requisitioned)).is_greater(0)
	assert_int(int(called.needed)).is_equal(int(called.fielded)+int(called.training)+int(called.requisitioned))

static func _room_for_lines(tier:int)->void:
	for domain:String in ["security","production","logistics","institutions"]:ProgressionSystem.domain_levels[domain]=tier

func test_rows_follow_lines_damage_and_stable_order()->void:
	_room_for_lines(2)
	MilitaryCampaign.start_production_line("spear",10)
	MilitaryCampaign.start_production_line("improvised",10)
	MilitaryCampaign.damaged_equipment={"spear":2}
	var rows:=Logistics.rows()
	var names:Array=rows.map(func(row:Dictionary)->String:return String(row.item))
	assert_array(names).contains(["spear","improvised"])
	assert_int(names.find("improvised")).is_less(names.find("spear"))
	var spear:Dictionary=rows[names.find("spear")]
	assert_int(int(spear.damaged)).is_equal(2)
	assert_array(spear.lines).has_size(1)
	assert_str(String(spear.category)).is_equal("weapons")

func test_line_badge_names_the_levy_and_needs_by_force_lists_it()->void:
	_levy_at_home(20,12)
	MilitaryCampaign.start_production_line("improvised",10)
	var line:Dictionary=MilitaryCampaign.production_lines_snapshot().lines[0]
	var badge:=Logistics.line_badge(line)
	assert_str(String(badge.text)).starts_with("for ").ends_with("levy")
	assert_int(int(badge.count)).is_equal(8)
	assert_str(String(badge.tip)).contains("8 at home")
	MilitaryCampaign.military_inventory["improvised"]=8
	assert_dict(Logistics.line_badge(line)).is_empty()
	var forces:=Logistics.needs_by_force()
	assert_int(forces.size()).is_equal(1)
	assert_int(int(forces[0].force_id)).is_equal(0)
	assert_int(int(forces[0].items.improvised)).is_equal(8)

func test_material_trend_reads_the_last_week()->void:
	GameState.elapsed_days=100
	Logistics.note_stores({"Timber":86.0},93)
	var trend:=Logistics.material_trend("Timber")
	assert_int(int(trend.days)).is_equal(7)
	assert_float(float(trend.per_day)).is_equal_approx(2.0,.0001)
	assert_dict(Logistics.material_trend("Clay")).is_empty()

# --- The screen ---------------------------------------------------------------------

const Provider=preload("res://scripts/hud/content/dock_content_production.gd")
const Queue=preload("res://scripts/hud/production_queue.gd")
const Plain=preload("res://scripts/hud/production_plain.gd")

static func _appoint(office:String,given:String,skip:Array=[])->int:
	for person:Dictionary in GovernmentPeopleSystem.people:
		if String(person.get("status",""))!="active" or not person.has("person_id") or int(person.person_id) in skip:continue
		person["name"]=given
		GameState.leadership_positions[office]={"person_id":int(person.person_id)}
		return int(person.person_id)
	return -1

func _officers()->void:
	var quartermaster:=_appoint("Quartermaster","Mahun of the High Camp")
	_appoint("Marshal","Rovik of the Ford",[quartermaster])

func _screen(sub:int=2)->Control:
	var provider=Provider.new(null,null)
	var block:Dictionary=provider.tab(sub).blocks[0]
	var panel:Control=auto_free(Queue.new());add_child(panel);panel.setup(block)
	return panel

static func _job(id:int)->Dictionary:
	for job:Dictionary in MilitaryCampaign.equipment_queue:
		if int(job.id)==id:return job
	return {}

func test_numbers_on_screen_match_the_model()->void:
	_room_for_lines(2);_officers();_levy_at_home(20,12)
	MilitaryCampaign.start_production_line("improvised",25)
	MilitaryCampaign.start_production_line("spear",20)
	MilitaryCampaign.military_inventory["spear"]=4
	var panel:=_screen()
	var pool:=P.hands(MilitaryCampaign)
	var hands:Node=panel.find_child("Header",true,false).find_child("Hands",true,false)
	assert_str((hands.get_node("Value") as Label).text).is_equal(Plain.hands_text(float(pool.lines)))
	assert_str((hands.get_node("Side") as Label).text).is_equal("/ "+Plain.hands_text(float(pool.total)))
	var snapshot:=MilitaryCampaign.production_lines_snapshot()
	var context:=Provider.line_context(snapshot)
	for index in snapshot.lines.size():
		var line:Dictionary=snapshot.lines[index]
		var row:Node=panel.find_child("Line%d" % int(line.id),true,false)
		assert_str((row.find_child("Rank",true,false).get_child(0) as Label).text).is_equal(str(index+1))
		assert_str((row.find_child("HandsValue",true,false) as Label).text).is_equal(Plain.hands_text(float(pool.by_line[int(line.id)])))
		assert_str((row.find_child("KeepValue",true,false) as Label).text).is_equal(str(int(line.target_stock)))
		assert_str((row.find_child("Stock",true,false) as Label).text).is_equal(str(int(line.stock)))
		var story:=Plain.line_story(line,context)
		if float(story.rate)>0.0:assert_str(String(row.find_child("Output",true,false).reading)).is_equal(Plain.rate_short(float(story.rate)))
	var levy:=Logistics.row("improvised")
	var chip:Node=panel.find_child("Stock_improvised",true,false)
	assert_str((chip.find_child("Have",true,false) as Label).text).is_equal(str(int(levy.stock)))
	assert_str((chip.find_child("Need",true,false) as Label).text).is_equal("/ %d" % int(levy.needed))

func test_reorder_changes_priority()->void:
	_room_for_lines(2)
	GameState.population_allocations.Crafting=100
	var club:=int(MilitaryCampaign.start_production_line("improvised",100).job_id)
	var spear:=int(MilitaryCampaign.start_production_line("spear",100).job_id)
	# Timber for less than one club: whichever line comes first takes it.
	GameState.resource_stockpiles.Timber=0.05
	MilitaryCampaign._process_equipment_production_day()
	assert_float(float(_job(club).last_consumed.get("Timber",0.0))).is_greater(0.0)
	assert_float(float(_job(spear).last_consumed.get("Timber",0.0))).is_equal(0.0)
	GameState.resource_stockpiles.Timber=0.05
	var panel:=_screen()
	assert_bool((panel.find_child("Line%d" % club,true,false).find_child("Up",true,false) as Button).disabled).is_true()
	(panel.find_child("Line%d" % spear,true,false).find_child("Up",true,false) as Button).pressed.emit()
	assert_int(int(MilitaryCampaign.equipment_queue[0].id)).is_equal(spear)
	MilitaryCampaign._process_equipment_production_day()
	assert_float(float(_job(spear).last_consumed.get("Timber",0.0))).is_greater(0.0)
	assert_float(float(_job(club).last_consumed.get("Timber",0.0))).is_equal(0.0)
	# Dragging a row onto line 1 puts it first again.
	panel=_screen()
	var row:Node=panel.find_child("Line%d" % club,true,false)
	var target:Node=panel.find_child("Line%d" % spear,true,false)
	assert_bool(target._can_drop_data(Vector2.ZERO,{"production_line":club})).is_true()
	target._drop_data(Vector2.ZERO,{"production_line":club})
	assert_int(int(MilitaryCampaign.equipment_queue[0].id)).is_equal(club)
	assert_bool(row._can_drop_data(Vector2.ZERO,{"production_line":club})).is_false()

func test_hands_come_from_household_crafting_then_the_lowest_line()->void:
	_room_for_lines(2)
	var first:=int(MilitaryCampaign.start_production_line("improvised",25).job_id)
	var second:=int(MilitaryCampaign.start_production_line("spear",25).job_id)
	var before:=P.hands(MilitaryCampaign)
	var share:=MilitaryCampaign.production_labor_share
	assert_bool(P.add_hands(MilitaryCampaign,first,1.0).has("ok")).is_true()
	var after:=P.hands(MilitaryCampaign)
	assert_float(float(after.by_line[first])).is_equal_approx(float(before.by_line[first])+1.0,.001)
	assert_float(float(after.by_line[second])).is_equal_approx(float(before.by_line[second]),.001)
	assert_float(MilitaryCampaign.production_labor_share).is_equal_approx(share+1.0/float(before.total),.001)
	# Every craftsperson busy: the hand comes from the lowest line.
	MilitaryCampaign.production_labor_share=1.0
	before=P.hands(MilitaryCampaign)
	P.add_hands(MilitaryCampaign,first,1.0)
	after=P.hands(MilitaryCampaign)
	assert_float(float(after.by_line[first])).is_equal_approx(float(before.by_line[first])+1.0,.001)
	assert_float(float(after.by_line[second])).is_equal_approx(float(before.by_line[second])-1.0,.001)
	assert_float(float(after.lines)).is_equal_approx(float(before.lines),.001)
	# Taking a hand off sends it back to household crafting.
	P.add_hands(MilitaryCampaign,second,-1.0)
	assert_float(MilitaryCampaign.production_labor_share).is_less(1.0)
	assert_str(String(P.add_hands(MilitaryCampaign,999,1.0).get("error",""))).is_not_empty()

func test_deficits_and_damaged_sets_show_on_the_stock_strip()->void:
	_levy_at_home(20,12)
	MilitaryCampaign.military_inventory["improvised"]=3
	MilitaryCampaign.damaged_equipment={"improvised":2}
	var chip:Node=_screen().find_child("Stock_improvised",true,false)
	var short:Label=chip.find_child("Short",true,false)
	assert_bool(short.visible).is_true()
	assert_str(short.text).is_equal("−5")
	assert_str((chip.find_child("Damaged",true,false) as Label).text).is_equal("2")
	assert_str((chip as Control).tooltip_text).contains("Short 5").contains("2 damaged")

func test_raised_levy_is_armed_by_staff_and_the_line_says_for_whom()->void:
	_officers()
	_levy_at_home(20,12)
	assert_array(MilitaryCampaign.equipment_queue).is_empty()
	MilitaryCampaign.workshop.advance(1)
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(1)
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	assert_bool(bool(job.planner_managed)).is_true()
	var row:Node=_screen().find_child("Line%d" % int(job.id),true,false)
	var badge:Control=row.find_child("Badge",true,false)
	assert_bool(badge.visible).is_true()
	# The levy carries the war leader's name ("for Rovik's levy").
	var leader:=String(load("res://scripts/army_orders.gd").war_leader_name())
	assert_str(leader).is_not_empty()
	assert_str(String(badge.label.text)).is_equal("for %s's levy" % leader)
	assert_str(badge.tooltip_text).contains("8 at home")
	var auto:Button=row.find_child("Auto",true,false)
	assert_bool(auto.visible).is_true()
	assert_str(auto.tooltip_text).starts_with("Auto:")

func test_main_surface_has_no_paragraphs()->void:
	_room_for_lines(3);_officers();_levy_at_home(20,12)
	for item:String in ["improvised","spear"]:MilitaryCampaign.start_production_line(item,20)
	MilitaryCampaign.damaged_equipment={"spear":2}
	MilitaryCampaign.workshop.data.status="Short of timber (7 needed, 2 in store) for soldiers' gear; the Quartermaster has asked the settlement leaders for more hands to gather it."
	for sub:int in [0,1,2]:
		var panel:=_screen(sub)
		for node:Node in panel.find_children("*","",true,false):
			var text:=""
			if node is Label:text=(node as Label).text
			elif node is Button:text=(node as Button).text
			else:continue
			if not (node as Control).is_visible_in_tree():continue
			assert_int(text.split(" ",false).size()).override_failure_message("Too many words on the surface: "+text).is_less_equal(12)
			if node is Label:assert_int((node as Label).get_theme_font_size("font_size")).is_greater_equal(12)

func test_daily_refresh_updates_in_place()->void:
	_room_for_lines(2)
	var id:=int(MilitaryCampaign.start_production_line("improvised",25).job_id)
	var provider=Provider.new(null,null)
	var panel:Control=auto_free(Queue.new());add_child(panel);panel.setup(provider.tab(2).blocks[0])
	var row:Node=panel.find_child("Line%d" % id,true,false)
	MilitaryCampaign.configure_production_line(id,40,false)
	assert_bool(panel.update_block(provider.tab(2).blocks[0])).is_true()
	assert_object(panel.find_child("Line%d" % id,true,false)).is_same(row)
	assert_str((row.find_child("KeepValue",true,false) as Label).text).is_equal("40")
	MilitaryCampaign.start_production_line("spear",10)
	assert_bool(panel.update_block(provider.tab(2).blocks[0])).is_false()
