extends GdUnitTestSuite
const S=preload("res://scripts/microscopy_samples.gd")
const L=preload("res://scripts/microscopy_lab.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(1902);CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();DiscoverySystem.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func specimen(ledger:Dictionary,site:String)->void:
	var known:Array=["laboratory_notebooks","microscopic_cell_observation","experimental_protocol_publication"]
	for source:int in [1,2]:
		var sample:=S.add(ledger,"starter",source,0,site,0,.04,{"viability":.8})
		S.measure(ledger,sample,0,true,known)
		S.grow(sample,1,.02,true);S.measure(ledger,sample,1,true,known)
	ledger.work_bank=4.0
	L.interpret(ledger,{"Printed Sheets":1.0},known,1)
	ledger.last_day=1
func test_save_city_and_rival_keep_recorded_evidence_separate()->void:
	specimen(GameState.microscopy,"home")
	GameState.elapsed_days=1
	var home:=GameState.microscopy.duplicate(true)
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":Vector2(10,10),"primary":false,"population_share":.2,"founded_day":0})
	SettlementModel.with_city_resources("second",func()->void:
		assert_dict(GameState.microscopy).is_equal(S.empty_state())
		specimen(GameState.microscopy,"second")
	)
	assert_dict(GameState.microscopy).is_equal(home)
	WorldSimulation.create_actor("lab_rival",1903)
	WorldSimulation.scoped("lab_rival",func()->void:
		assert_dict(WorldSimulation.state.microscopy).is_equal(S.empty_state())
		specimen(WorldSimulation.state.microscopy,"rival_home")
	)
	assert_dict(GameState.microscopy).is_equal(home)
	var rivals:=WorldSimulation.export_state()
	assert_str(WorldSimulation.validate_payload(rivals)).is_empty()
	var slot:="codex_microscopy_%d" % Time.get_ticks_usec()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	GameState.microscopy=S.empty_state()
	var loaded:=SaveSystem.load_game(slot)
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	assert_dict(GameState.microscopy).is_equal(home)
	SettlementModel.with_city_resources("second",func()->void:
		assert_str(GameState.microscopy.specimens[0].site).is_equal("second")
		assert_bool(S.valid(GameState.microscopy)).is_true()
	)
	WorldSimulation.scoped("lab_rival",func()->void:
		assert_str(WorldSimulation.state.microscopy.specimens[0].site).is_equal("rival_home")
	)
	L.advance(false)
	assert_dict(GameState.microscopy).is_equal(home)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
func test_protocol_report_ignores_later_latent_changes()->void:
	var ledger:=S.empty_state();specimen(ledger,"home")
	var report:Dictionary=ledger.protocols[0].duplicate(true)
	ledger.specimens[0].viability=.1;ledger.specimens[1].viability=1.0
	ledger.specimens[0].profile.tissue_order=.1
	assert_dict(ledger.protocols[0]).is_equal(report)
	assert_bool(L.protocol_ready(ledger,"starter")).is_true()
	assert_bool(S.valid(ledger)).is_true()

func test_early_microbial_growth_stops_without_supplies_and_recovers()->void:
	GameState.population_allocations.Knowledge=20
	GameState.known_discoveries.append_array(["microbial_observation","microbial_growth_measurement","laboratory_notebooks"])
	GameState.microscopy.tools.bench=true
	var sample:=S.add(GameState.microscopy,"starter",1,0,"home",0,.04,{"viability":.8})
	GameState.resource_stockpiles={};GameState.food_stocks={}
	GameState.elapsed_days=1;L.advance(false)
	assert_float(float(sample.media)).is_equal(0.0)
	assert_array(sample.history).is_empty()
	GameState.resource_stockpiles={"Freshwater":1.0,"Laboratory Glassware":1.0,"Clay":1.0}
	GameState.food_stocks={"Dry staples":1.0}
	GameState.elapsed_days=2;L.advance(false)
	assert_float(float(sample.media)).is_greater(0.0)
	assert_int(sample.history.size()).is_equal(1)
	assert_bool("cell_culture_methods" in GameState.known_discoveries).is_false()
	var observations:int=sample.history.size()
	GameState.microscopy.tools.bench=false
	GameState.elapsed_days=3;L.advance(false)
	assert_int(sample.history.size()).is_equal(observations)
	GameState.resource_stockpiles["Compound Microscopes"]=1.0
	GameState.resource_stockpiles["Specimen Slides"]=1.0
	GameState.resource_stockpiles["Laboratory Glassware"]=2.0
	GameState.elapsed_days=4;L.advance(false)
	assert_int(sample.history.size()).is_equal(observations+1)
	assert_float(float(GameState.resource_stockpiles["Compound Microscopes"])).is_equal(0.0)
