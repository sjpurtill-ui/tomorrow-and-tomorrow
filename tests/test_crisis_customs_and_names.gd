extends GdUnitTestSuite
## Crisis follow-ups (crisis_system.gd):
## - once "The Sick Kept Apart" is told, officials keep the sick apart when the
##   god is silent (the turning point promises it), as they do after the people
##   learned it from a hard sickness; without either they still tend them;
## - the unnamed dead and helpers of a crisis never share a given name with a
##   living named person, nor with each other, and recent victims' names come
##   round again only when the palette is used up.
## Offline; never calls a real API.

const Crisis:=preload("res://scripts/crisis_system.gd")
const Turning:=preload("res://scripts/turning_points.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const SEED:=515151

var _saved_people:Array=[]

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(200)
	GameState.settlement_founded_day=0
	GameState.elapsed_days=400
	_saved_people=GovernmentPeopleSystem.people.duplicate(true)

func after_test()->void:
	GovernmentPeopleSystem.people=_saved_people

func _sickness()->Dictionary:
	return {"type":"sickness","mult":1.0,"id":"test_sickness"}

func test_silent_officials_tend_without_the_custom()->void:
	assert_bool(Crisis.apart_custom()).is_false()
	assert_str(Crisis._default_choice(_sickness(),"open")).is_equal("tend")
	assert_str(Crisis._default_choice({"type":"stranger"},"open")).is_equal("tend")

func test_turning_point_makes_silent_officials_keep_the_sick_apart()->void:
	(Turning.state().told as Dictionary)["apart"]=int(GameState.elapsed_days)
	assert_bool(Crisis.unlocked("sickness:apart_plus")).is_true()
	assert_bool(Crisis.apart_custom()).is_true()
	assert_str(Crisis._default_choice(_sickness(),"open")).is_equal("apart")
	assert_str(Crisis._default_choice({"type":"stranger"},"open")).is_equal("apart")
	# The mid-crisis default and other crises are unchanged.
	assert_str(Crisis._default_choice(_sickness(),"mid")).is_equal("children_apart")
	assert_str(Crisis._default_choice({"type":"hunger"},"open")).is_equal("ration")

func test_learned_custom_still_counts()->void:
	(Crisis.state().flags as Dictionary)["apart_custom"]=true
	assert_str(Crisis._default_choice(_sickness(),"open")).is_equal("apart")

func _palette()->Array:
	return EraNames.PALETTES[EraNames.tradition("player",int(GameState.world_seed))]

func _living(names:Array)->void:
	for n in names:
		GovernmentPeopleSystem.people.append({"person_id":"test_%s" % n,"name":"%s of Stonewash" % n,"status":"active"})

func _given(entry:String)->String:
	return entry.get_slice(",",0).strip_edges().get_slice(" ",0)

func test_victims_never_take_a_living_persons_name()->void:
	var palette:=_palette()
	var men:Array=palette[1]; var women:Array=palette[0]
	# Most of the palette is held by living officials: 16 of each sex.
	var held:Array=men.slice(0,16)+women.slice(0,16)
	_living(held)
	for round in 40:
		var dead:=Crisis._dead_names(3,"round:%d" % round)
		var givens:Array=[]
		for d in dead:
			var g:=_given(String(d))
			assert_bool(g in held).override_failure_message("victim %s shares a living official's name" % d).is_false()
			assert_bool(g in givens).override_failure_message("two victims named %s at once" % g).is_false()
			givens.append(g)
		for h in Crisis._people_names(2,"helper:%d" % round):
			assert_bool(_given(String(h)) in held).override_failure_message("helper %s shares a living name" % h).is_false()

func test_victim_sex_matches_role_even_when_one_sex_is_used_up()->void:
	var palette:=_palette()
	var men:Array=palette[1]
	_living(men)  # every man's name is held by someone living
	var women:Array=palette[0]
	for round in 10:
		for d in Crisis._dead_names(3,"sexless:%d" % round):
			var g:=_given(String(d))
			assert_bool(g in women).override_failure_message("%s should take a free woman's name" % d).is_true()
			var role:=String(d).get_slice(",",1).strip_edges()
			assert_bool(role in Crisis.WOMEN_ROLES).override_failure_message("%s has a man's role" % d).is_true()

func test_recent_victims_are_not_reused_while_names_remain()->void:
	# 20 names per sex, 4 held by the living: at least 32 free names in all.
	var palette:=_palette()
	_living((palette[1] as Array).slice(0,2)+(palette[0] as Array).slice(0,2))
	var seen:Array=[]
	for round in 10:
		for d in Crisis._dead_names(3,"recent:%d" % round):
			var g:=_given(String(d))
			assert_bool(g in seen).override_failure_message("%s reused after only %d names" % [g,seen.size()]).is_false()
			seen.append(g)
	# Past the palette the oldest come back, still never a living name.
	for round in 20:
		for d in Crisis._dead_names(3,"more:%d" % round):
			assert_str(_given(String(d))).is_not_empty()
