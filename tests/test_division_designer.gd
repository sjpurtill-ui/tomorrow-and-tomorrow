extends GdUnitTestSuite
const D=preload("res://scripts/division_design.gd")
const S=preload("res://scripts/division_statistics.gd")
const UI=preload("res://scripts/hud/division_designer.gd")
const War=preload("res://scripts/hud/war_board.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(992);MilitaryCampaign.reset_for_new_world()
	GameState.settlement_site_committed=true
func after_test()->void:WorldSimulation.clear()
func cells(n:=8)->Array:
	var out:Array=[];out.resize(30);out.fill({});out[5]={"unit":"levy","weapon":"improvised","count":n};return out
func test_save_and_activate_never_move_people_or_issue_equipment()->void:
	var allocations:=GameState.population_allocations.duplicate(true)
	var army:=MilitaryCampaign.home_army.duplicate(true)
	var stock:=MilitaryCampaign.military_inventory.duplicate(true)
	var c:=cells();c[6]={"unit":"levy","weapon":"improvised","count":2}
	assert_dict(D.save(MilitaryCampaign,1,"Hearth guard",c)).contains_keys(["ok"])
	assert_int(int(MilitaryCampaign.army_templates[0].entries[0].count)).is_equal(10)
	assert_dict(D.activate(MilitaryCampaign,1)).contains_keys(["ok"])
	assert_dict(GameState.population_allocations).is_equal(allocations)
	assert_dict(MilitaryCampaign.home_army).is_equal(army)
	assert_dict(MilitaryCampaign.military_inventory).is_equal(stock)
func test_save_round_trip_and_invalid_slot_validation()->void:
	D.save(MilitaryCampaign,1,"Hearth guard",cells());D.activate(MilitaryCampaign,1)
	var saved:=MilitaryCampaign.export_state()
	assert_dict(MilitaryCampaign.import_state(saved)).not_contains_keys(["error"])
	assert_int(MilitaryCampaign.active_division_template_id).is_equal(1)
	assert_array(D.slots(MilitaryCampaign.army_templates[0])).is_equal(cells())
	var bad:=saved.duplicate(true);bad.army_templates[0].designer_slots[5].count=NAN
	assert_dict(MilitaryCampaign.import_state(bad)).contains_keys(["error"])
	bad=saved.duplicate(true);bad.army_templates[0].entries[0].count=999
	assert_dict(MilitaryCampaign.import_state(bad)).contains_keys(["error"])
	bad=saved.duplicate(true);bad.active_division_template_id=999
	assert_dict(MilitaryCampaign.import_state(bad)).contains_keys(["error"])
func test_old_save_remains_valid_and_uses_legacy_staffing_until_selected()->void:
	var old:=MilitaryCampaign.export_state();old.erase("active_division_template_id")
	assert_dict(MilitaryCampaign.import_state(old)).not_contains_keys(["error"])
	assert_int(MilitaryCampaign.active_division_template_id).is_equal(0)
	assert_array(D.active(MilitaryCampaign)).is_empty()
func test_locks_and_support_constraints_are_enforced_in_model()->void:
	var c:=cells();c[0]=c[5].duplicate(true)
	assert_str(D.validate(MilitaryCampaign,c)).is_not_empty()
	c=cells();c[5]={"unit":"main_battle_tank","weapon":"main_battle_tank","count":8}
	assert_str(D.validate(MilitaryCampaign,c)).is_not_empty()
	assert_str(D.validate(MilitaryCampaign,c,false)).is_empty()
	assert_str(D.validate(MilitaryCampaign,cells(0))).is_not_empty()
	assert_str(D.validate(MilitaryCampaign,cells(100001))).is_not_empty()
func test_exact_staffing_and_supply_demand_are_bounded()->void:
	var design:=[{"unit":"levy","weapon":"improvised","count":7},{"unit":"skirmisher","weapon":"bow","count":3}]
	for n:int in [1,8,57,1000000]:
		var sum:=0
		for e:Dictionary in D.targets(design,n):sum+=int(e.count)
		assert_int(sum).is_equal(n)
	D.save(MilitaryCampaign,1,"Small band",cells(8));D.activate(MilitaryCampaign,1)
	var split:=D.split(MilitaryCampaign,3)
	assert_int(int(split[0].count)).is_equal(3)
	assert_str(split[0].kit.item).is_equal("improvised")
func test_day_one_has_every_metric_and_small_totals_not_zero_speed()->void:
	var stats:=S.read(MilitaryCampaign,D.entries(cells()),.25)
	for list:Array in [S.BASE_FIELDS,S.COMBAT_FIELDS]:
		for field:Array in list:assert_bool(is_finite(float(stats[field[0]]))).is_true()
	assert_float(stats.soft_attack).is_between(0,.01)
	assert_float(stats.hp).is_equal_approx(.2,.0001)
	assert_float(stats.speed).is_equal(3.0)
	assert_float(stats.organization).is_less(10)
	assert_float(stats.air_attack).is_equal(0.0)
	assert_float(stats.fuel).is_equal(0.0)
	assert_float(stats.supply).is_greater(0)
func test_scaling_is_additive_or_average_as_appropriate_and_tech_improves_capability()->void:
	var small:=S.read(MilitaryCampaign,D.entries(cells(8)))
	var large:=S.read(MilitaryCampaign,D.entries(cells(8000)))
	assert_float(large.soft_attack).is_equal_approx(small.soft_attack*1000,.0001)
	assert_float(large.organization).is_equal_approx(small.organization,.0001)
	assert_float(large.speed).is_equal(small.speed)
	var late:=S.read(MilitaryCampaign,[{"unit":"main_battle_tank","weapon":"main_battle_tank","count":8}])
	assert_float(late.soft_attack).is_greater(small.soft_attack)
	assert_float(late.armor).is_greater(small.armor)
	assert_float(late.supply).is_greater(small.supply)
	assert_float(late.fuel).is_greater(0)
func test_breakthrough_and_support_affect_actual_combat_not_only_preview()->void:
	var stats:=S.read(MilitaryCampaign,D.entries(cells(100)))
	var force:Dictionary=MilitaryCampaign.simulator.create_formation_force("Band",stats.formations)
	var defended:Array=MilitaryCampaign.simulator.evaluate_force(force,{"formations":[]},1.0,false,false)
	var advanced:Array=MilitaryCampaign.simulator.evaluate_force(force,{"formations":[]},1.0,false,true)
	assert_float(float(advanced[0].defense)).is_less(float(defended[0].defense))
	var supported:Array=stats.formations.duplicate(true)
	supported.append({"unit":"combat_engineer","weapon":"engineering_kit","count":20,"equipment":20,"equipment_required":20,"training":.8})
	var traits:=S.support_traits(supported)
	assert_float(traits.entrenchment).is_greater(0)
	force=MilitaryCampaign.simulator.create_formation_force("Supported",supported)
	var protected:Array=MilitaryCampaign.simulator.evaluate_force(force,{"formations":[]},1.0)
	assert_float(float(protected[0].defense)).is_greater(float(defended[0].defense))
func test_editor_draft_is_retained_and_war_has_no_workforce_controls()->void:
	var ui:=UI.new();add_child(ui);await get_tree().process_frame
	assert_int(ui.slot_buttons.size()).is_equal(30)
	assert_int(ui.stat_labels.size()).is_equal(S.BASE_FIELDS.size()+S.COMBAT_FIELDS.size())
	ui._select_slot(5);ui._change_count(7)
	var input:SpinBox=ui.count_input
	await get_tree().process_frame
	assert_object(ui.count_input).is_same(input)
	assert_int(int(ui.cells[5].count)).is_equal(7)
	assert_bool(ui.draft_dirty).is_true()
	var war:=War.new();add_child(war);war.setup()
	assert_object(war.find_child("WatchMore",true,false)).is_null()
	assert_object(war.find_child("WatchLess",true,false)).is_null()
	assert_object(war.find_child("Levels",true,false)).is_null()
	assert_object(war.find_child("MakeupCard",true,false)).is_null()
	assert_object(war.find_child("DivisionDesigner",true,false)).is_not_null()
	ui.queue_free();war.queue_free();await get_tree().process_frame
func test_staff_retraining_uses_real_kit_and_preserves_total_and_labor()->void:
	for id:String in ["bow_craft","skirmisher_infantry_screens"]:
		GameState.known_discoveries.append(id);GameState.discovery_adoption[id]=1.0
	var c:=cells(80);c[0]={"unit":"skirmisher","weapon":"bow","count":20}
	assert_dict(D.save(MilitaryCampaign,1,"Screened band",c)).contains_keys(["ok"])
	D.activate(MilitaryCampaign,1)
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home",[{"unit":"levy","weapon":"improvised","count":100,"equipment":100,"training":.8}])
	MilitaryCampaign.military_inventory.bow=0
	var labor:=GameState.population_allocations.duplicate(true)
	assert_int(D.converge(MilitaryCampaign)).is_equal(0)
	MilitaryCampaign.military_inventory.bow=5
	assert_int(D.converge(MilitaryCampaign)).is_equal(2)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(100)
	assert_int(int(MilitaryCampaign.military_inventory.bow)).is_equal(3)
	assert_dict(GameState.population_allocations).is_equal(labor)
	assert_int(MilitaryCampaign._matching_home_count("skirmisher","bow")).is_equal(2)
	assert_int(MilitaryCampaign._matching_home_count("levy","improvised")).is_equal(98)
func test_unissued_support_never_grants_free_bonuses()->void:
	var forms:=[{"unit":"levy","weapon":"improvised","count":80,"equipment":80,"training":.8},{"unit":"medical_detachment","weapon":"medical_kit","count":20,"equipment":0,"equipment_required":20,"training":1.0}]
	assert_float(S.support_traits(forms).trickleback).is_equal(0.0)
	forms[1].equipment=20
	assert_float(S.support_traits(forms).trickleback).is_greater(0)
	forms[1].unit="anti_air";forms[1].weapon="anti_air_gun"
	var stats:=S.support_traits(forms)
	assert_float(stats.air_attack).is_greater(0)
	var with_aa:Dictionary=MilitaryCampaign.simulator.create_formation_force("AA",forms)
	with_aa.joint_air_pressure=.25
	var protected:Array=MilitaryCampaign.simulator.evaluate_force(with_aa,{"formations":[]})
	forms[1].equipment=0
	var bare:Dictionary=MilitaryCampaign.simulator.create_formation_force("Bare",forms);bare.joint_air_pressure=.25
	var exposed:Array=MilitaryCampaign.simulator.evaluate_force(bare,{"formations":[]})
	assert_float(protected[0].attack).is_greater(exposed[0].attack)
	var normalized:Dictionary=MilitaryCampaign.simulator._normalize_force(with_aa,"AA")
	assert_float(float(normalized.joint_air_pressure)).is_equal(.25)
	var actual:Array=MilitaryCampaign.simulator.evaluate_force(normalized,{"formations":[]})
	assert_float(actual[0].attack).is_equal_approx(protected[0].attack,.0001)

func test_starting_scale_and_identity_follow_real_people_and_equipment()->void:
	var first:Dictionary=MilitaryCampaign.army_templates[0]
	assert_int(int(first.entries[0].count)).is_between(1,20)
	assert_array(D.size_presets(3)).is_equal([1,2])
	assert_array(D.size_presets(20)).is_equal([1,2,5,10,20])
	assert_str(D.formation_name(D.entries(cells(3)))).is_equal("Levy band")
	assert_str(D.formation_name([{"unit":"main_battle_tank","weapon":"main_battle_tank","count":1000},{"unit":"rifle_infantry","weapon":"service_rifle","count":1000}])).is_equal("Armored battalion")
	var ui:=UI.new();add_child(ui);await get_tree().process_frame
	ui.cells[5]={"unit":"line_infantry","weapon":"shield_spear","count":20};ui._refresh()
	assert_str(ui.name_input.text).is_equal("Infantry group")
	ui.automatic_name=false;ui.name_input.text="River guard";ui._change_count(25)
	assert_str(ui.name_input.text).is_equal("River guard")
	ui.queue_free();await get_tree().process_frame

func test_oversized_legacy_template_cannot_silently_lose_groups()->void:
	var legacy:Dictionary=MilitaryCampaign.army_templates[0]
	legacy.entries=[]
	for i in 31:legacy.entries.append({"unit":"levy","weapon":"improvised","count":1})
	assert_str(D.migration_error(legacy)).is_not_empty()
	assert_dict(D.save(MilitaryCampaign,1,"Truncated",D.slots(legacy))).contains_keys(["error"])
	assert_dict(D.activate(MilitaryCampaign,1)).contains_keys(["error"])
	assert_int(legacy.entries.size()).is_equal(31)

func test_medical_preview_reads_existing_paid_care_capacity()->void:
	var forms:=[{"unit":"levy","weapon":"improvised","count":80,"equipment":80,"training":.8},{"unit":"medical_detachment","weapon":"medical_kit","count":20,"equipment":20,"training":.8}]
	var expected:float=preload("res://scripts/field_medicine.gd").capacity({"formations":forms})*.08/100.0
	assert_float(S.support_traits(forms).trickleback).is_equal_approx(expected,.00001)
	var scouts:={"entries":[{"unit":"skirmisher","weapon":"bow","count":8}]}
	assert_str(D.migration_error(scouts)).is_empty()
	assert_str(D.validate(null,D.slots(scouts),false)).is_empty()
