extends GdUnitTestSuite

const Presentation:=preload("res://scripts/hud/court_presentation.gd")
const Stages:=preload("res://scripts/civic_stages.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const PERIOD_CASES:=[
	["early","hide",[]],
	["ancient","robe",["temple_high_steward","pictographic_records","plain_weaving"]],
	["medieval","medieval",["fitted_tailoring","royal_chancery_office"]],
	["early_modern","courtcoat",["secretaries_of_state","privy_council_minutes","fitted_tailoring"]],
	["industrial","formal",["single_minister_departments","appointed_department_prefects","fitted_tailoring"]],
	["modern","business",["national_income_accounts","labor_ministry","fitted_tailoring"]]
]

func before_test()->void:
	Stages.stage_override="";Stages.reload();Voice.knowledge_override.clear()
	GameState.reset_for_new_world(76215)

func after_test()->void:
	Stages.stage_override="";Stages.reload();Voice.knowledge_override.clear()

func test_every_presentation_and_later_civic_anchor_is_in_the_live_catalog()->void:
	DiscoverySystem.initialize()
	var ids:Array=Presentation.CLOTH+Presentation.LETTERS+Presentation.FITTED+Presentation.DYES
	for group:Array in Presentation.GATES.values():ids.append_array(group)
	var later:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Stages.LATE_PATH))
	for markers:Array in later.tracks.values():ids.append_array(markers)
	for record:Dictionary in later.stages:
		assert_bool(String(record.presentation_period) in Presentation.PERIODS).is_true()
		assert_bool(String(record.track) in ["any","throne","assembly"]).is_true()
		assert_array(record.requires).is_not_empty()
		for group:Dictionary in record.requires:ids.append_array(group.any)
	for id in ids:
		assert_bool(DiscoverySystem.catalog_by_id.has(String(id))).override_failure_message("Unknown court presentation anchor: %s" % id).is_true()

func test_six_periods_share_dress_greetings_and_ambient_policy()->void:
	for row:Array in PERIOD_CASES:
		var profile:=Presentation.from_knowledge(row[2])
		assert_str(String(profile.period)).is_equal(row[0])
		assert_str(String(profile.outfit)).is_equal(row[1])
		assert_bool(String(profile.routine_greeting) in ["nod","bow_small","bow","kneel"]).is_true()
		if String(row[0]) in ["industrial","modern"]:
			assert_str(String(profile.routine_greeting)).is_equal("nod")
			assert_str(String(profile.routine_departure)).is_equal("nod")
			assert_bool(profile.paperwork).is_true()
			assert_bool(profile.rustic_props).is_false()
			assert_bool(profile.court_animals).is_false()
	assert_str(String(Presentation.from_knowledge(["plain_weaving"]).outfit)).is_equal("tunic")

func test_elapsed_years_do_not_modernize_a_people_without_knowledge()->void:
	Voice.knowledge_override["player"]=[]
	var before:=Presentation.for_owner()
	GameState.elapsed_days=365.0*9000.0
	assert_dict(Presentation.for_owner()).is_equal(before)
	assert_str(String(before.period)).is_equal("early")

func test_isolated_future_knowledge_does_not_redress_the_court()->void:
	for group:Array in Presentation.GATES.values():
		for anchor in group:
			var profile:=Presentation.from_knowledge([anchor])
			assert_bool(String(profile.period) in ["early","ancient"]).override_failure_message(str(anchor,": ",profile)).is_true()
	var mixed:=["plain_weaving","kingship","formal_archives","radio_broadcasting"]
	assert_str(String(Presentation.from_knowledge(mixed).period)).is_equal("ancient")
	assert_str(String(Presentation.from_knowledge(mixed+["garment_size_grading"]).period)).is_equal("modern")

func test_later_civic_stages_require_both_institutional_groups()->void:
	var later:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Stages.LATE_PATH))
	for record:Dictionary in later.stages:
		var first:=String(record.requires[0].any[0])
		var second:=String(record.requires[1].any[0])
		assert_bool(Stages.requirements_met(record,{first:true})).is_false()
		assert_bool(Stages.requirements_met(record,{second:true})).is_false()
		var derived:=Stages.derive([first,second])
		assert_str(String(derived.id)).is_equal(String(record.id))
		assert_str(String(Presentation.from_knowledge([first,second],derived).period)).is_equal(String(record.presentation_period))

func test_modern_administration_does_not_turn_a_monarchy_into_an_assembly()->void:
	var late:=["national_income_accounts","labor_ministry"]
	var throne:=Presentation.from_knowledge(late+["kingship","dynastic_succession","one_party_state"])
	var assembly:=Presentation.from_knowledge(late+["free_adult_assembly","annual_elected_magistrates","realm_bill_of_rights"])
	assert_str(String(throne.stage_id)).is_equal("executive_council")
	assert_str(String(assembly.stage_id)).is_equal("executive_council")
	assert_str(String(throne.lean)).is_equal("throne")
	assert_str(String(assembly.lean)).is_equal("assembly")
	assert_str(String(throne.outfit)).is_equal(String(assembly.outfit))
	assert_str(String(throne.routine_greeting)).is_equal("nod")
	assert_str(String(throne.protocol)).contains("god")

func test_foreign_and_home_presentations_use_their_own_knowledge()->void:
	Voice.knowledge_override["player"]=["national_income_accounts","labor_ministry","fitted_tailoring"]
	Voice.knowledge_override["neighbours"]=["plain_weaving"]
	assert_str(String(Presentation.for_owner().period)).is_equal("modern")
	assert_str(String(Presentation.for_owner("neighbours").period)).is_equal("early")
	assert_str(String(Presentation.for_owner("neighbours").outfit)).is_equal("tunic")
	assert_str(String(Presentation.for_owner().outfit)).is_equal("business")

func test_existing_save_knowledge_derives_the_profile_without_new_state()->void:
	GameState.known_discoveries.assign(["national_income_accounts","labor_ministry","fitted_tailoring"])
	var before:Array=GameState.known_discoveries.duplicate()
	var first:=Presentation.for_owner()
	Stages.reload()
	assert_dict(Presentation.for_owner()).is_equal(first)
	assert_array(GameState.known_discoveries).is_equal(before)
	assert_str(String(first.period)).is_equal("modern")
	var supplied:=Stages.derive(before)
	var unchanged:=supplied.duplicate(true)
	Presentation.from_knowledge(before,supplied)
	assert_dict(supplied).is_equal(unchanged)

func test_existing_monarchical_and_assembly_ritual_defaults_remain_distinct()->void:
	var temple:=Presentation.from_knowledge(["temple_high_steward","pictographic_records"])
	var chamber:=Presentation.from_knowledge(["annual_elected_magistrates","free_adult_assembly"])
	assert_str(String(temple.routine_greeting)).is_equal("kneel")
	assert_str(String(chamber.routine_greeting)).is_equal("nod")
	assert_str(String(Presentation.from_knowledge(["secretaries_of_state","privy_council_minutes"]).routine_greeting)).is_equal("bow_small")

func test_late_stages_reuse_existing_office_keys_and_keep_divine_address()->void:
	for id in ["privy_state_council","parliamentary_council","ministerial_cabinet","executive_council"]:
		var record:=Stages.stage(id)
		for office in ["Steward","Quartermaster","Marshal","Scholar","ChiefScout","Envoy","HighPriest","Justice","Treasurer","Settlement"]:
			assert_str(Stages.office_title(record,office)).is_not_empty()
		assert_int((record.titles as Dictionary).size()).is_equal(10)
		assert_array(Stages.address_options(record)).is_not_empty()
		assert_str(Stages.protocol_line(record)).contains("god")
