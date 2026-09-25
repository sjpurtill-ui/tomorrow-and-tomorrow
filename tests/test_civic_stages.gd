extends GdUnitTestSuite
## The form of court follows discoveries (scripts/civic_stages.gd,
## data/civic/civic_stages.json). Granting a stage's key discoveries must change
## the stage, the backdrop, who attends, the officials' titles and the way they
## address the god; a city-state gets an assembly, not a throne; and a save
## with no new fields derives its court from what it knows.

const Stages:=preload("res://scripts/civic_stages.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Roster:=preload("res://scripts/hud/court_roster.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const TEST_SEED:=481902

## Cumulative knowledge, earliest court first. Each row adds the key
## discoveries of one stage to everything before it.
const LADDER:=[
	["hearth_council",[]],
	["elders_circle",["elder_council_assent","customary_law"]],
	["chiefs_hall",["paramount_chiefdom","hereditary_chiefly_rank"]],
	["temple_palace",["temple_high_steward","offering_keepers","pictographic_records"]],
	["palace_bureaucracy",["kingship","dynastic_succession","formal_archives","written_law_code"]],
	["imperial_court",["provincial_governors","rotated_appointed_prefects","written_office_examinations"]],
	["late_antique_hall",["compiled_rescript_code","civil_military_separation"]],
]


func before_test()->void:
	Voice.knowledge_override.clear()
	Stages.stage_override=""
	Stages.reload()
	GameState.reset_for_new_world(TEST_SEED)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Keansburg"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12.0,0.0,-8.0)
	SettlementModel.ensure_founded()
	# A town large enough for every office the court can hold.
	GameState.ensure_population_total(12000)
	GameState.society_capacities["institutions"]=0.74
	GameState.elapsed_days=30.0
	GovernmentPeopleSystem.initialize()
	GovernmentPeopleSystem.process_day(30)


func after_test()->void:
	Voice.knowledge_override.clear()
	Stages.stage_override=""
	Stages.reload()


func _know(ids:Array)->void:
	Voice.knowledge_override["player"]=ids.duplicate()


func _backdrop()->Control:
	var scene:Control=auto_free(Backdrop.new())
	scene.configure(Backdrop.current_tier(),false)
	return scene


func _steward_title()->String:
	return String(GovernmentPeopleSystem.office_definition("Steward").get("title",""))


func _address(person_id:int)->String:
	var person:=GovernmentPeopleSystem.person_snapshot(person_id)
	return String(Voice.for_person(person).get("address",""))


func _office_keys()->Array[String]:
	var keys:Array[String]=[]
	for office in GovernmentPeopleSystem.active_offices(): keys.append(String(office.key))
	return keys


func test_stage_table_is_complete_and_every_trigger_exists()->void:
	var seen:Dictionary={}
	for stage_variant in Stages.stages():
		var stage:Dictionary=stage_variant
		var id:=String(stage.get("id",""))
		assert_bool(seen.has(id)).override_failure_message("duplicate stage %s" % id).is_false()
		seen[id]=true
		for field in ["name","place_name","place_line","scene","protocol","law","seat_of_rule","civic_buildings","titles","attendants","seats"]:
			assert_bool(stage.has(field)).override_failure_message("%s lacks %s" % [id,field]).is_true()
		if int(stage.get("rank",0))>0:
			for office in ["Steward","Quartermaster","Marshal","Scholar","ChiefScout","Envoy","HighPriest","Justice","Treasurer","Settlement"]:
				assert_str(Stages.office_title(stage,office)).override_failure_message("%s has no title for %s" % [id,office]).is_not_empty()
			assert_array(Stages.address_options(stage)).override_failure_message("%s has no form of address" % id).is_not_empty()
		# Triggers inside the 0-1200 game must name real discoveries; the
		# 1200-1800 ids live in data/civic/y1200_triggers.json until built.
		for group in stage.get("requires",[]):
			for trigger in group.get("any",[]):
				assert_dict(DiscoverySystem.discovery_definition(String(trigger))).override_failure_message("%s names unknown discovery %s" % [id,trigger]).is_not_empty()
	for id in ["hearth_council","elders_circle","chiefs_hall","temple_palace","palace_bureaucracy","citizen_assembly","imperial_court","senate_house","late_antique_hall","feudal_hall","chancery_court","chartered_commune","estates_assembly"]:
		assert_bool(seen.has(id)).override_failure_message("missing stage %s" % id).is_true()
	for office in Stages.office_definitions():
		for trigger in (office as Dictionary).get("requires_any",[]):
			if not String(trigger) in _y1200_ids():
				assert_dict(DiscoverySystem.discovery_definition(String(trigger))).override_failure_message("office trigger %s unknown" % trigger).is_not_empty()


func _y1200_ids()->Array:
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(Stages.Y1200_PATH))
	var out:Array=[]
	for key in (parsed as Dictionary).get("offices",{}): out.append_array((parsed as Dictionary).offices[key])
	return out


func test_granting_each_stages_key_discoveries_changes_the_whole_court()->void:
	var steward:=GovernmentPeopleSystem.officeholder("Steward")
	assert_bool(steward.is_empty()).is_false()
	var known:Array=[]
	var previous:={}
	for rung:Array in LADDER:
		known.append_array(rung[1])
		_know(known)
		var expected:=String(rung[0])
		assert_str(Stages.current_id()).override_failure_message("with %s" % str(known)).is_equal(expected)
		var scene:=_backdrop()
		assert_str(String(scene.stage_id)).is_equal(expected)
		var now:={"scene":String(scene.scene),"place":Backdrop.stage_place_name(),"attendants":Roster.attendance_line(),"roles":str(Roster.attendant_roles()),
			"title":_steward_title(),"address":_address(int(steward.person_id)),"council":Roster.group_word("council"),"protocol":Roster.ceremony_line()}
		if not previous.is_empty():
			for key in ["scene","place","attendants","title","address","protocol"]:
				assert_str(String(now[key])).override_failure_message("%s did not change from %s to %s (%s)" % [key,String(previous.stage),expected,String(now[key])]).is_not_equal(String(previous[key]))
		now["stage"]=expected
		previous=now


func test_court_details_for_the_palace()->void:
	_know(["elder_council_assent","customary_law","paramount_chiefdom","temple_high_steward","offering_keepers","pictographic_records","kingship","formal_archives","written_law_code","public_credit"])
	assert_str(Stages.current_id()).is_equal("palace_bureaucracy")
	assert_str(_steward_title()).is_equal("Grand Steward")
	assert_str(GovernmentPeopleSystem.settlement_leader_title()).is_equal("Governor")
	# Discoveries add the god's priesthood, a judge and a treasury to the court.
	var keys:=_office_keys()
	for key in ["HighPriest","Justice","Treasurer"]: assert_array(keys).contains([key])
	assert_str(String(GovernmentPeopleSystem.office_definition("Justice").title)).is_equal("Chief Judge")
	var roles:=Roster.attendant_roles()
	for role in ["herald","scribe","priest","guard","petitioner"]: assert_array(roles).contains([role])
	assert_int(Roster.seat_limit()).is_greater(7)
	assert_str(Roster.group_word("council")).is_equal("THE PALACE COUNCIL")
	assert_str(Roster.ceremony_line()).contains("herald")
	var steward:=GovernmentPeopleSystem.officeholder("Steward")
	assert_array(Stages.address_options(Stages.current())).contains([_address(int(steward.person_id))])
	assert_str(Voice.brief(Voice.for_person(GovernmentPeopleSystem.person_snapshot(int(steward.person_id))))).contains("court protocol:")


func test_the_hearth_council_keeps_the_rustic_court()->void:
	_know([])
	assert_str(Stages.current_id()).is_equal("hearth_council")
	var scene:=_backdrop()
	assert_str(String(scene.scene)).is_equal("fire_circle")
	assert_str(Backdrop.stage_place_name()).is_equal(Backdrop.place_name(0))
	assert_str(_steward_title()).is_equal("Hearth Chief")
	assert_array(Roster.attendants()).is_empty()
	assert_int(Roster.seat_limit()).is_equal(7)
	var steward:=GovernmentPeopleSystem.officeholder("Steward")
	# The dialect's own address, exactly as before stages existed.
	var address:=_address(int(steward.person_id))
	var dialect_terms:Array=[]
	for d in Voice.DIALECTS: dialect_terms.append_array(d.address)
	dialect_terms.append_array(Voice.DIALECT_SAFE.address)
	assert_array(dialect_terms).contains([address])


func test_assembly_discoveries_give_an_assembly_not_a_throne()->void:
	var base:=["elder_council_assent","customary_law","paramount_chiefdom","temple_high_steward","offering_keepers","pictographic_records","phonetic_notation","copper_smelting"]
	var city_state:=base+["free_adult_assembly","annual_elected_magistrates","majority_vote_assembly","lot_chosen_council"]
	# Even with an old kingship remembered, the assembly's institutions win.
	_know(city_state+["kingship","formal_archives"])
	assert_str(Stages.current().get("lean","")).is_equal("assembly")
	assert_str(Stages.current_id()).is_equal("citizen_assembly")
	assert_str(String(_backdrop().scene)).is_equal("assembly_tiers")
	assert_str(_steward_title()).is_equal("Presiding Magistrate")
	assert_str(Roster.group_word("council")).is_equal("THE MAGISTRATES")
	assert_str(Roster.ceremony_line()).contains("No one kneels")
	# The priesthood keeps no seat in an assembly's council.
	assert_array(_office_keys()).not_contains(["HighPriest"])
	# The same era under a king: a palace, with the priest in council.
	_know(base+["kingship","dynastic_succession","formal_archives"])
	assert_str(Stages.current().get("lean","")).is_equal("throne")
	assert_str(Stages.current_id()).is_equal("palace_bureaucracy")
	assert_str(String(_backdrop().scene)).is_equal("palace_hall")
	assert_array(_office_keys()).contains(["HighPriest"])
	# Later the commonwealth grows a council house, never an imperial court.
	_know(city_state+["mixed_constitution_checks","commoners_veto_tribunes","provincial_governors","rotated_appointed_prefects"])
	assert_str(Stages.current_id()).is_equal("senate_house")
	assert_str(String(_backdrop().scene)).is_equal("council_house")


func test_later_stages_wait_for_the_1200_1800_ids()->void:
	var realm:=["kingship","dynastic_succession","formal_archives","provincial_governors","rotated_appointed_prefects","compiled_rescript_code","civil_military_separation"]
	_know(realm)
	assert_str(Stages.current_id()).is_equal("late_antique_hall")
	_know(realm+["homage_commendation","fief_tenure_for_service","itinerant_royal_court"])
	assert_str(Stages.current_id()).is_equal("feudal_hall")
	assert_str(String(_backdrop().scene)).is_equal("great_hall")
	_know(realm+["homage_commendation","fief_tenure_for_service","royal_chancery_office","counting_table_audit"])
	assert_str(Stages.current_id()).is_equal("chancery_court")
	assert_str(_steward_title()).is_equal("Chancellor")
	_know(realm+["homage_commendation","royal_chancery_office","counting_table_audit","estates_assembly","great_liberties_charter"])
	assert_str(Stages.current_id()).is_equal("estates_assembly")
	assert_str(String(_backdrop().scene)).is_equal("estates_hall")
	# A commonwealth of sworn towns becomes a chartered commune.
	_know(["free_adult_assembly","annual_elected_magistrates","majority_vote_assembly","phonetic_notation","sworn_town_commune","elected_town_consuls","chartered_town_liberties"])
	assert_str(Stages.current_id()).is_equal("chartered_commune")
	assert_str(String(_backdrop().scene)).is_equal("commune_hall")


func test_an_older_save_with_no_new_fields_derives_its_court()->void:
	for id in ["kingship","dynastic_succession","formal_archives","copper_smelting","pictographic_records","temple_high_steward","written_law_code"]:
		if not GameState.known_discoveries.has(id): GameState.known_discoveries.append(id)
	var slot:="civic_stages_%d" % OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	# The saved government holds only the fields it always held.
	var payload:Dictionary=SaveSystem._read_payload(slot)
	var saved:Dictionary=payload.get("reflected_GovernmentPeopleSystem",{})
	assert_dict(saved).is_not_empty()
	for field in saved:
		assert_array(["administration_records","people","next_person_id","last_processed_month","government_stage","revision","initializing"]).contains([String(field)])
	# A fresh session: nothing cached, the court unknown until derived.
	GameState.known_discoveries.clear()
	Stages.reload()
	Stages._seen.clear()
	var restored:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	assert_str(Stages.current_id()).is_equal("palace_bureaucracy")
	assert_str(_steward_title()).is_equal("Grand Steward")
	# The first month after loading records no spurious change of court.
	GameState.elapsed_days=float(GovernmentPeopleSystem.last_processed_month+1)*30.0
	var events:=GovernmentPeopleSystem.process_day(int(GameState.elapsed_days))
	assert_bool(events.any(func(e:Dictionary)->bool:return String(e.get("title","")).begins_with("The Court Changes"))).is_false()


func test_a_change_of_court_is_recorded_once_as_a_dated_event()->void:
	_know([])
	Stages._seen.clear()
	GameState.elapsed_days=60.0
	GovernmentPeopleSystem.process_day(60)
	_know(["elder_council_assent","customary_law"])
	GameState.elapsed_days=90.0
	var events:=GovernmentPeopleSystem.process_day(90)
	var changes:=events.filter(func(e:Dictionary)->bool:return String(e.get("title","")).begins_with("The Court Changes"))
	assert_int(changes.size()).is_equal(1)
	assert_str(String(changes[0].description)).contains("elders")
	GameState.elapsed_days=120.0
	events=GovernmentPeopleSystem.process_day(120)
	assert_bool(events.any(func(e:Dictionary)->bool:return String(e.get("title","")).begins_with("The Court Changes"))).is_false()
