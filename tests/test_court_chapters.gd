extends GdUnitTestSuite
## Calendar renewal is presentation only. Construction, equipment and political
## form still come from the host society's actual knowledge and institutions.

const Chapters:=preload("res://scripts/hud/court_chapters.gd")
const Stages:=preload("res://scripts/civic_stages.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const YEAR:=365.0

func before_test()->void:
	Backdrop.tier_override=-1
	Voice.knowledge_override.clear();Stages.stage_override="";Stages.reload()
	GameState.reset_for_new_world(904621)

func after_test()->void:
	Backdrop.tier_override=-1
	Voice.knowledge_override.clear();Stages.stage_override="";Stages.reload()

func test_all_sixteen_chapters_change_at_the_exact_two_hundred_year_boundary()->void:
	var names:Array[String]=[]
	for index in 16:
		var boundary:=float(index*200)*YEAR
		var profile:=Chapters.derive(boundary,["precast_panel_housing"])
		assert_int(Chapters.index_for_days(boundary)).is_equal(index)
		assert_int(int(profile.index)).is_equal(index)
		assert_int(int(profile.design)).is_equal(index)
		assert_int(int(profile.start_year)).is_equal(index*200)
		assert_int(int(profile.renewal)).is_equal(index)
		assert_str(String(profile.set_kind)).is_equal("chapter_%02d" % index)
		assert_bool(profile.limited).is_false()
		assert_str(String(profile.name)).is_not_empty()
		assert_bool(String(profile.name) in names).is_false()
		names.append(String(profile.name))
		if index>0:
			assert_int(Chapters.index_for_days(boundary-0.001)).is_equal(index-1)
			assert_int(int(Chapters.derive(boundary-0.001,["precast_panel_housing"]).design)).is_equal(index-1)
		if index<15:
			assert_int(Chapters.index_for_days(boundary+200.0*YEAR-0.001)).is_equal(index)
	assert_int(names.size()).is_equal(16)

func test_negative_days_and_years_after_three_thousand_are_bounded()->void:
	for days:float in [-10000.0*YEAR,-1.0,0.0]:
		assert_int(Chapters.index_for_days(days)).is_equal(0)
		assert_int(int(Chapters.derive(days,["precast_panel_housing"]).design)).is_equal(0)
	for days:float in [3000.0*YEAR,3000.0*YEAR+0.001,1000000.0*YEAR]:
		var profile:=Chapters.derive(days,["precast_panel_housing"])
		assert_int(int(profile.index)).is_equal(15)
		assert_int(int(profile.start_year)).is_equal(3000)
		assert_str(String(profile.set_kind)).is_equal("chapter_15")

func test_aging_without_knowledge_renews_the_early_room_without_modernizing_it()->void:
	var known:Array=[]
	for index in 16:
		var profile:=Chapters.derive(float(index*200)*YEAR,known)
		assert_int(int(profile.design)).is_equal(0)
		assert_int(int(profile.renewal)).is_equal(index)
		assert_bool(profile.limited).is_equal(index>0)
		assert_str(String(profile.set_kind)).is_equal("chapter_00")
		for enabled in (profile.capabilities as Dictionary).values():
			assert_bool(bool(enabled)).is_false()
	assert_array(known).is_empty()

func test_construction_knowledge_limits_the_room_independently_of_elapsed_time()->void:
	var cases:=[
		["central_hall_houses",1],["lime_plastered_floors",2],
		["ashlar_masonry",3],["long_span_timber_halls",6],["plank_walled_timber_halls",7],
		["great_hall_of_justice",8],["fixed_capital_archives",9],
		["privy_council_minutes",11],["ministry_office_block",13],
		["reinforced_concrete",15]]
	for row:Array in cases:
		var profile:=Chapters.derive(3000.0*YEAR,[row[0]])
		assert_int(int(profile.design)).override_failure_message(str(row[0],": ",profile)).is_equal(int(row[1]))
		assert_bool(profile.limited).is_equal(int(row[1])<15)
	var early:=Chapters.derive(200.0*YEAR,["reinforced_concrete"])
	assert_int(int(early.design)).is_equal(1)

func test_acquiring_construction_never_removes_an_existing_room_capability()->void:
	var known:Array=["central_hall_houses","paper_making","telephone_circuits"]
	var previous:=int(Chapters.derive(3000.0*YEAR,known).design)
	for anchor in ["ashlar_masonry","great_hall_of_justice","ministry_office_block","precast_panel_housing"]:
		known.append(anchor)
		var profile:=Chapters.derive(3000.0*YEAR,known)
		assert_int(int(profile.design)).is_greater_equal(previous)
		assert_bool(profile.capabilities.paper).is_true()
		assert_bool(profile.capabilities.telephone).is_true()
		previous=int(profile.design)

func test_home_and_foreign_hosts_share_calendar_but_keep_their_own_knowledge()->void:
	Voice.knowledge_override["player"]=["ashlar_masonry","paper_making"]
	Voice.knowledge_override["neighbours"]=["precast_panel_housing","telephone_circuits"]
	GameState.elapsed_days=2600.0*YEAR
	var home:=Chapters.for_owner()
	var foreign:=Chapters.for_owner("neighbours")
	assert_int(int(home.index)).is_equal(13)
	assert_int(int(foreign.index)).is_equal(13)
	assert_int(int(home.design)).is_equal(3)
	assert_int(int(foreign.design)).is_equal(13)
	assert_bool(home.capabilities.paper).is_true()
	assert_bool(foreign.capabilities.paper).is_false()
	assert_bool(home.capabilities.telephone).is_false()
	assert_bool(foreign.capabilities.telephone).is_true()
	GameState.elapsed_days=2800.0*YEAR
	assert_int(int(Chapters.for_owner().renewal)).is_equal(14)
	assert_int(int(Chapters.for_owner("neighbours").renewal)).is_equal(14)

func test_calendar_reads_do_not_grant_discoveries_or_change_government_state()->void:
	GameState.known_discoveries.assign(["kingship","dynastic_succession","formal_archives","written_law_code"])
	var discoveries:=GameState.known_discoveries.duplicate()
	var values:=GameState.societal_values.duplicate(true)
	var offices:=GameState.leadership_positions.duplicate(true)
	var people:=GovernmentPeopleSystem.people.duplicate(true)
	var government_stage:=GovernmentPeopleSystem.government_stage
	var civic_before:=Stages.current().duplicate(true)
	for index in 16:
		GameState.elapsed_days=float(index*200)*YEAR
		assert_str(String(Chapters.for_owner().lean)).is_equal("throne")
	assert_array(GameState.known_discoveries).is_equal(discoveries)
	assert_dict(GameState.societal_values).is_equal(values)
	assert_dict(GameState.leadership_positions).is_equal(offices)
	assert_array(GovernmentPeopleSystem.people).is_equal(people)
	assert_int(GovernmentPeopleSystem.government_stage).is_equal(government_stage)
	assert_dict(Stages.current()).is_equal(civic_before)

func test_modern_rooms_keep_actual_monarchical_and_assembly_institutions_distinct()->void:
	var foundation:=["precast_panel_housing","national_income_accounts","labor_ministry"]
	var monarchy:=Chapters.derive(3000.0*YEAR,foundation+["kingship","dynastic_succession","one_party_state"])
	var assembly:=Chapters.derive(3000.0*YEAR,foundation+["free_adult_assembly","annual_elected_magistrates","realm_bill_of_rights"])
	assert_int(int(monarchy.design)).is_equal(15)
	assert_int(int(assembly.design)).is_equal(15)
	assert_str(String(monarchy.lean)).is_equal("throne")
	assert_str(String(assembly.lean)).is_equal("assembly")

func test_existing_civic_rooms_remain_valid_without_new_construction_save_fields()->void:
	for row:Array in [["citizen_assembly",6],["chancery_court",9],["privy_state_council",11],["ministerial_cabinet",13],["executive_council",15]]:
		var record:=Stages.stage(String(row[0]))
		var profile:=Chapters.derive(3000.0*YEAR,[],record)
		assert_int(int(profile.design)).is_equal(int(row[1]))
		assert_bool(profile.capabilities.computer).is_false()
		assert_bool(profile.capabilities.electricity).is_false()

func test_every_construction_hardware_and_stage_anchor_exists_in_the_live_catalog()->void:
	DiscoverySystem.initialize()
	var anchors:Array=[]
	for group:Array in Chapters.CONSTRUCTION.values():anchors.append_array(group)
	for group:Array in Chapters.CAPABILITIES.values():anchors.append_array(group)
	for id in anchors:
		assert_bool(DiscoverySystem.catalog_by_id.has(String(id))).override_failure_message("Unknown court chapter discovery: %s" % id).is_true()
	for id in Chapters.STAGE_CEILINGS:
		assert_bool(String(id) in Stages.ids()).override_failure_message("Unknown court chapter civic stage: %s" % id).is_true()

func test_isolated_future_equipment_does_not_upgrade_the_building()->void:
	for id in ["typewriter","telephone_circuits","filament_lamp_works","fluorescent_lighting","refrigerated_air_conditioning","stored_program_computer","desk_computers","flat_panel_displays","radio_broadcasting"]:
		var profile:=Chapters.derive(3000.0*YEAR,["central_hall_houses",id])
		assert_int(int(profile.design)).override_failure_message("Equipment upgraded structure: %s" % id).is_equal(1)

func test_independent_equipment_requires_its_own_discovery()->void:
	var cases:={"typewriter":"typewriter","telephone":"telephone_circuits",
		"electricity":"filament_lamp_works","radiator":"radiator_central_heating",
		"air_conditioning":"refrigerated_air_conditioning","computer":"desk_computers"}
	for capability:String in cases:
		var profile:=Chapters.derive(3000.0*YEAR,["precast_panel_housing",cases[capability]])
		for field:String in cases:
			assert_bool(bool(profile.capabilities[field])).override_failure_message("Wrong equipment for %s: %s" % [capability,field]).is_equal(field==capability)

func test_stored_program_computers_are_not_desktop_pcs_and_flat_screens_need_both_foundations()->void:
	var early_computer:=Chapters.derive(3000.0*YEAR,["stored_program_computer"])
	assert_bool(early_computer.capabilities.computer).is_false()
	assert_bool(early_computer.capabilities.flat_screen).is_false()
	var display_only:=Chapters.derive(3000.0*YEAR,["flat_panel_displays"])
	assert_bool(display_only.capabilities.computer).is_false()
	assert_bool(display_only.capabilities.flat_screen).is_false()
	for desktop in ["desk_computers","desktop_office_work"]:
		var crt:=Chapters.derive(3000.0*YEAR,[desktop])
		assert_bool(crt.capabilities.computer).is_true()
		assert_bool(crt.capabilities.flat_screen).is_false()
		var flat:=Chapters.derive(3000.0*YEAR,[desktop,"flat_panel_displays"])
		assert_bool(flat.capabilities.computer).is_true()
		assert_bool(flat.capabilities.flat_screen).is_true()

func test_fluorescent_fittings_require_electrical_lighting_foundations()->void:
	assert_bool(Chapters.derive(3000.0*YEAR,["fluorescent_lighting"]).capabilities.fluorescent).is_false()
	for electrical in ["filament_lamp_works","electric_street_lighting"]:
		var incandescent:=Chapters.derive(3000.0*YEAR,[electrical])
		assert_bool(incandescent.capabilities.electricity).is_true()
		assert_bool(incandescent.capabilities.fluorescent).is_false()
		assert_bool(Chapters.derive(3000.0*YEAR,[electrical,"fluorescent_lighting"]).capabilities.fluorescent).is_true()

func test_ancient_and_later_window_glass_discoveries_enable_glazing()->void:
	for id in ["cast_window_glass","glazed_windows","house_glass_windows","sash_windows"]:
		assert_bool(Chapters.derive(3000.0*YEAR,[id]).capabilities.glazing).override_failure_message("Window glass not recognized: %s" % id).is_true()
	assert_bool(Chapters.derive(3000.0*YEAR,["glass_blowing"]).capabilities.glazing).is_false()

func test_clay_parchment_printing_and_bound_records_do_not_invent_paper()->void:
	for id in ["pictographic_records","formal_archives","parchment_record_preparation","printing_process","bookbinding_assemblies"]:
		assert_bool(Chapters.derive(3000.0*YEAR,[id]).capabilities.paper).override_failure_message("Non-paper discovery invented paper: %s" % id).is_false()
	assert_bool(Chapters.derive(3000.0*YEAR,["paper_making"]).capabilities.paper).is_true()
	assert_bool(Chapters.derive(3000.0*YEAR,["bookbinding_assemblies"]).capabilities.bound_records).is_true()
	assert_bool(Chapters.derive(3000.0*YEAR,["paper_making"]).capabilities.bound_records).is_false()
	assert_bool(Chapters.derive(3000.0*YEAR,[],Stages.stage("executive_council")).capabilities.paper).is_false()

func test_derivation_is_deterministic_and_does_not_mutate_input_or_share_outputs()->void:
	var known:Array=["ashlar_masonry","paper_making","kingship","dynastic_succession"]
	var record:=Stages.derive(known).duplicate(true)
	var before_known:=known.duplicate(true)
	var before_record:=record.duplicate(true)
	var first:=Chapters.derive(1800.0*YEAR,known,record)
	var expected:=first.duplicate(true)
	for repeat in 3:assert_dict(Chapters.derive(1800.0*YEAR,known,record)).is_equal(expected)
	var reordered:=known.duplicate();reordered.reverse();reordered.append("ashlar_masonry")
	assert_dict(Chapters.derive(1800.0*YEAR,reordered,record)).is_equal(expected)
	first.capabilities.paper=false;first["name"]="Changed only in caller"
	assert_dict(Chapters.derive(1800.0*YEAR,known,record)).is_equal(expected)
	assert_array(known).is_equal(before_known)
	assert_dict(record).is_equal(before_record)

func test_old_save_fields_alone_reconstruct_the_same_room_after_cache_reload()->void:
	GameState.elapsed_days=3000.0*YEAR
	GameState.known_discoveries.assign(["ministry_office_block","paper_making","typewriter"])
	var before:=GameState.known_discoveries.duplicate()
	var first:=Chapters.for_owner()
	Stages.reload()
	assert_dict(Chapters.for_owner()).is_equal(first)
	assert_int(int(first.design)).is_equal(13)
	assert_bool(first.capabilities.typewriter).is_true()
	assert_array(GameState.known_discoveries).is_equal(before)

func test_default_overview_uses_the_chapter_but_explicit_civic_fixtures_stay_exact()->void:
	GameState.elapsed_days=3000.0*YEAR
	Voice.knowledge_override["player"]=["reinforced_concrete","national_income_accounts","labor_ministry"]
	var actual:Control=auto_free(Backdrop.new());actual.configure(4,false)
	assert_str(String(actual.scene)).is_equal("government")
	assert_int(int(actual.chapter.design)).is_equal(15)
	assert_str(Backdrop.stage_place_name()).is_equal(String(Chapters.for_owner().name))
	var pinned:Control=auto_free(Backdrop.new());pinned.configure(4,false,"feudal_hall")
	assert_str(String(pinned.scene)).is_equal("great_hall")
	assert_dict(pinned.chapter).is_empty()
	assert_str(Backdrop.stage_place_name("feudal_hall")).is_equal(String(Stages.stage("feudal_hall").place_name))

func test_medieval_assembly_overview_does_not_introduce_a_throne()->void:
	GameState.elapsed_days=1800.0*YEAR
	Voice.knowledge_override["player"]=["reinforced_concrete","free_adult_assembly","annual_elected_magistrates"]
	var actual:Control=auto_free(Backdrop.new());actual.configure(3,false)
	assert_str(String(actual.chapter.lean)).is_equal("assembly")
	assert_str(String(actual.scene)).is_equal("commune_hall")
