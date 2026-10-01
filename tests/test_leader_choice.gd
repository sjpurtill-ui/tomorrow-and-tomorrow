extends GdUnitTestSuite
## REAL CHOICE OF WHO SERVES (government_people_system.gd succession and
## shortlist, office_levers.gd estimates and cards, court_commands.gd town
## appointment, court_lives.gd mourning): an empty office is filled by a
## stated rule, not by seed order; the court's estimates of a candidate are a
## range that narrows as they serve; each office's card names who else could
## hold it with their numbers; a town is given to an official by name in the
## court; the mourning's choice shows each candidate's hand against the dead
## holder's.

const Levers:=preload("res://scripts/office_levers.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Lives:=preload("res://scripts/court_lives.gd")
const TEST_SEED:=640021


func before_test()->void:
	GameState.reset_for_new_world(TEST_SEED)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Choice Ford"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12.0,0.0,-8.0)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	Levers.clear_cache()


func _second_town(name:String)->String:
	var second:Dictionary=GameState.player_settlements[0].duplicate(true)
	second.id="town_%s" % name.to_lower()
	second.name=name
	second.primary=false
	second.population_share=0.3
	second.leader_person_id=0
	GameState.player_settlements.append(second)
	GovernmentPeopleSystem.initialize()
	return String(second.id)


func test_an_empty_office_is_filled_by_the_stated_rule_not_seed_order()->void:
	var gov:=GovernmentPeopleSystem
	assert_str(gov.succession_rule()).is_equal("kin" if gov.government_form()=="centralized" else "ablest")
	var holder:=gov.officeholder("ChiefScout")
	assert_bool(holder.is_empty()).is_false()
	var removed:=gov.remove_central_officeholder("ChiefScout","dismiss")
	assert_bool(bool(removed.ok)).is_true()
	var successor:Dictionary=removed.successor
	# The council's choice: the highest judged fit among those free of another office.
	var best_fit:=-1.0
	for person:Dictionary in gov.people:
		if String(person.status)!="active" or String(person.get("office_key",""))!="" or int(person.person_id)==int(holder.person_id): continue
		if int(person.person_id)==int(successor.person_id): continue
		best_fit=maxf(best_fit,gov.estimated_fit(person,"ChiefScout"))
	assert_float(gov.estimated_fit(gov.person_snapshot(int(successor.person_id)),"ChiefScout")).is_greater_equal(best_fit)


func test_the_eldest_able_kin_inherits_where_custom_keeps_the_seat()->void:
	var gov:=GovernmentPeopleSystem
	var dead:Dictionary=gov.people[0]
	var able:Array[Dictionary]=[]
	for person:Dictionary in gov.people:
		if int(person.person_id)!=int(dead.person_id) and String(person.status)=="active" and String(person.get("office_key",""))=="" and gov.office_competency(person,"Steward")>=gov.HEIR_MIN_FIT: able.append(person)
	assert_int(able.size()).is_greater_equal(2)
	# Two kin of the dead, the elder of them inherits.
	able[0]["born_day"]=-30*365; able[1]["born_day"]=-50*365
	dead["kin"]=[{"pid":int(able[0].person_id),"rel":"child"},{"pid":int(able[1].person_id),"rel":"sibling"}]
	var candidates:=gov.candidates_for_office("Steward","",gov.MAX_GOVERNMENT_PEOPLE,false)
	var heir:=gov._eldest_able_kin(int(dead.person_id),"Steward",candidates,0)
	assert_int(int(heir.get("person_id",0))).is_equal(int(able[1].person_id))
	assert_str(gov.succession_words("kin","Ada Ford")).contains("eldest of their kin")
	assert_str(gov.succession_words("ablest")).contains("ablest")


func test_estimates_are_a_range_that_narrows_as_they_serve()->void:
	var person:Dictionary=GovernmentPeopleSystem.people[1].duplicate(true)
	person["known_since_day"]=int(GameState.elapsed_days)
	person["experience_months"]=0
	var green:=Levers.estimate(person,"Quartermaster")
	person["experience_months"]=24
	var tried:=Levers.estimate(person,"Quartermaster")
	person["experience_months"]=48
	var proven:=Levers.estimate(person,"Quartermaster")
	assert_float(float(green.high)-float(green.low)).is_greater(float(tried.high)-float(tried.low))
	assert_float(float(proven.high)-float(proven.low)).is_equal_approx(0.0,0.0001)
	assert_float(float(proven.value)).is_equal_approx(Levers.person_lever(person,"Quartermaster"),0.0001)
	# The council's fit judgement narrows the same way.
	assert_float(GovernmentPeopleSystem.how_sure(person)).is_equal(1.0)


func test_each_card_names_who_else_could_hold_it_with_their_numbers()->void:
	var rows:=Levers.shortlist_rows("ChiefScout",3)
	assert_int(rows.size()).is_between(1,3)
	for row:Dictionary in rows:
		assert_str(String(row.text)).contains(" would ")
		assert_str(String(row.tip)).contains("make %s our" % String(row.name).get_slice(" ",0))
		assert_int(int(row.person_id)).is_not_equal(int(GovernmentPeopleSystem.officeholder("ChiefScout").person_id))
	var provider=preload("res://scripts/hud/content/dock_content_government.gd").new(null,null)
	var items:Array=provider.tab(0).blocks[0].items
	var scout:Dictionary={}
	for item:Dictionary in items:
		if String(item.office_key)=="ChiefScout": scout=item
	assert_bool((scout.get("shortlist",[]) as Array).is_empty()).is_false()
	assert_bool((scout.shortlist[0] as Dictionary).on_summon is Callable).is_true()
	var lever:Dictionary=scout.get("lever",{})
	assert_str(String(lever.get("text",""))).contains("Scouts are caught")


func test_a_town_is_given_to_an_official_by_name_in_the_court()->void:
	var town_id:=_second_town("Riverbend")
	assert_dict(CC.town_post("Make Oda headman of Riverbend")).is_equal({"id":town_id,"name":"Riverbend"})
	assert_dict(CC.town_post("Iska shall lead Riverbend")).is_equal({"id":town_id,"name":"Riverbend"})
	assert_bool(CC.town_post("Make Oda our keeper of stores").is_empty()).is_true()
	var former:=GovernmentPeopleSystem.settlement_leader(town_id)
	var chosen:Dictionary={}
	for person:Dictionary in GovernmentPeopleSystem.people:
		if String(person.status)=="active" and String(person.get("local_leader_of",""))=="" and String(person.get("office_key",""))=="": chosen=person; break
	assert_bool(chosen.is_empty()).is_false()
	var r:={"outcome":"","executed":false,"stage":"","reaction":"","text":"Make %s headman of Riverbend" % String(chosen.name)}
	var done:=CC._appoint_town("",r,{"kind":"official","person_id":int(chosen.person_id),"name":String(chosen.name)},{"id":town_id,"name":"Riverbend"})
	assert_bool(bool(done.executed)).override_failure_message(String(done.outcome)).is_true()
	assert_int(int(GovernmentPeopleSystem.settlement_leader(town_id).person_id)).is_equal(int(chosen.person_id))
	assert_str(String(done.outcome)).contains("now leads Riverbend")
	if not former.is_empty(): assert_str(String(done.outcome)).contains("%s no longer does" % String(former.name))
	assert_str(String(done.outcome)).contains("work done")


func test_town_leaders_are_the_headmen_of_their_towns_work()->void:
	var town_id:=_second_town("Hollowmere")
	GovernmentPeopleSystem.government_stage=1
	var leader:=GovernmentPeopleSystem.settlement_leader(town_id)
	assert_bool(leader.is_empty()).is_false()
	var share:=0.3
	var expected:=Levers.value("Steward")*(1.0-share)+share*Levers.town_labour(GovernmentPeopleSystem.person_snapshot(int(leader.person_id)))
	assert_float(Levers.labour()).is_equal_approx(expected,0.0001)


func test_the_mourning_choice_shows_each_candidates_hand_against_the_dead_holders()->void:
	var gov:=GovernmentPeopleSystem
	gov.government_stage=1
	var dead:Dictionary=gov.people[0].duplicate(true)
	var candidate:Dictionary=gov.people[1].duplicate(true)
	var line:=Levers.compare_line("Quartermaster",candidate,dead)
	assert_str(line).contains("would ")
	assert_str(line).contains("%s's:" % String(dead.name).get_slice(" ",0))
	var town:=Levers.compare_line("settlement",candidate,dead)
	assert_str(town).contains("town's work")
	var war:=Levers.compare_line("Marshal",candidate,dead)
	assert_str(war).contains("the home band would fight")
