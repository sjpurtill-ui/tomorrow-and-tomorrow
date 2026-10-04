extends GdUnitTestSuite
## NO CHIEFS DOCK (the user, 2026-10-04: "I don't think we even need the
## chiefs section anymore. Everything's covered in the court."). The rail has
## no Government/Chiefs section and F3 opens nothing; what that dock showed of
## each official (office, fit, skills, nature, their hand in the engine's
## numbers, who could hold it, standing orders, empty offices, the officials'
## backing) is in the court's "What you know" (court_office_dossier.gd).

const CommandRail:=preload("res://scripts/hud/command_rail_hud.gd")
const NavIcon:=preload("res://scripts/hud/nav_icon.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Standing:=preload("res://scripts/standing.gd")
const OfficeDossier:=preload("res://scripts/hud/court_office_dossier.gd")
const Levers:=preload("res://scripts/office_levers.gd")

func before_test()->void:
	GameState.reset_for_new_world(991704)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Test Town"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	Levers.clear_cache()

func test_rail_has_no_chiefs_section_and_f3_opens_nothing()->void:
	assert_bool(CommandRail.SECTIONS.any(func(item:Dictionary)->bool:return String(item.id)=="government")).is_false()
	assert_bool(CommandRail.HOTKEYS.has(KEY_F3)).is_false()
	assert_bool(CommandRail.HOTKEYS.values().has("government")).is_false()
	for era:String in EraWords.WORDS:
		assert_bool((EraWords.WORDS[era] as Dictionary).has("rail.government")).is_false()
	for section:Dictionary in CommandRail.SECTIONS:
		var icon:Control=auto_free(NavIcon.new(String(section.id)))
		assert_str(icon.icon_id).is_equal(String(section.id))

func test_standing_sends_order_and_persuasion_to_the_court()->void:
	for row:Array in Standing.STRENGTHS:
		assert_str(String(row[3])).is_not_equal("government")
		if String(row[0]) in ["order","persuasion"]: assert_str(String(row[3])).is_equal("court")

func _rows_by_key(rows:Array)->Dictionary:
	var out:={}
	for row:Array in rows: out[String(row[0])]=String(out.get(String(row[0]),""))+String(row[1])+"|"
	return out

func test_the_headman_dossier_tells_office_fit_skills_hand_and_backing()->void:
	var steward:=GovernmentPeopleSystem.officeholder("Steward")
	assert_bool(steward.is_empty()).is_false()
	var rows:=OfficeDossier.rows(int(steward.person_id))
	var by:=_rows_by_key(rows)
	for key in ["Office","Suits it","Best at","The officials"]: assert_bool(by.has(key)).override_failure_message("missing "+key).is_true()
	assert_str(String(by["Suits it"])).contains("office")
	assert_str(String(by["Best at"])).contains("(")
	for row:Array in rows: assert_bool(row[2] is Color).is_true()

func test_each_official_names_who_could_hold_it_with_their_numbers()->void:
	var scout:=GovernmentPeopleSystem.officeholder("ChiefScout")
	if scout.is_empty(): return
	var by:=_rows_by_key(OfficeDossier.rows(int(scout.person_id)))
	assert_str(String(by.get("Their hand",""))).contains("Scouts are caught")
	if not Levers.shortlist_rows("ChiefScout",3).is_empty():
		assert_str(String(by.get("Could hold it",""))).contains(" would ")
		assert_str(String(by.get("Could hold it",""))).contains("make")

func test_standing_orders_show_under_the_official_who_carries_them()->void:
	var steward:=GovernmentPeopleSystem.officeholder("Steward")
	ConsequenceEngine.apply_policy("care_rotation",0.18,120.0,"test",{"office":"Steward","name":"care rotation","execution_factor":0.9})
	var by:=_rows_by_key(OfficeDossier.rows(int(steward.person_id)))
	assert_str(String(by.get("Standing order",""))).contains("Care Rotation: carried out well")

func test_no_office_no_rows()->void:
	assert_array(OfficeDossier.rows(0)).is_empty()
	assert_array(OfficeDossier.rows(987654)).is_empty()
