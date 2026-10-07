extends GdUnitTestSuite
## THE COURT'S EXECUTIONS (scripts/hud/court_executions.gd, the director's
## execution scenes in court_director.gd). Headless and offline.
## - the god's own words name the method, if the people know what it needs;
## - the ways a people can stage follow what they know and the hall;
## - the director's pick is seeded and never the same twice running;
## - the caption names what the picture shows;
## - a child is never shown harmed; "off" keeps the sober exit; "mild" shows
##   no blood and no parts;
## - every staged method plays as a scene: a hush and a drum roll first, the
##   room after, the caption, an end, within about 12 seconds.

const Executions:=preload("res://scripts/hud/court_executions.gd")
const Director:=preload("res://scripts/hud/court_director.gd")
const DirectorTests:=preload("res://tests/test_court_director.gd")

func after_test()->void:
	Executions.gore="full"
	Executions.last_used=""

static func stone_age()->Dictionary:
	return {"known":["cordage","clay_shaping"],"tags":[],"set":"fire_ring","dogs":true}

static func bronze_age()->Dictionary:
	return {"known":["bronze_alloying","rope_laying","bow_craft","mast_fed_swine"],"tags":["metal","pottery","farming","dairy"],"set":"longhouse","dogs":true}

func test_the_gods_words_name_the_method_when_the_people_can()->void:
	var bronze:=bronze_age()
	assert_str(Executions.parse("Behead him!",bronze)).is_equal("behead")
	assert_str(Executions.parse("Off with her head.",bronze)).is_equal("behead")
	assert_str(Executions.parse("Throw her to the pigs",bronze)).is_equal("pigs")
	assert_str(Executions.parse("Burn him alive",bronze)).is_equal("fire")
	assert_str(Executions.parse("Feed him to the dogs.",bronze)).is_equal("dogs")
	assert_str(Executions.parse("Club him to death",bronze)).is_equal("club")
	assert_str(Executions.parse("Stone him!",bronze)).is_equal("stoning")
	assert_str(Executions.parse("Boil her in the cauldron",bronze)).is_equal("boil")
	assert_str(Executions.parse("Hang him from the beam",bronze)).is_equal("hang")
	assert_str(Executions.parse("Shoot him",bronze)).is_equal("arrows")
	# what a stone-age people cannot do, they cannot be asked to
	var stone:=stone_age()
	assert_str(Executions.parse("Behead him!",stone)).is_equal("")
	assert_str(Executions.parse("Hang him",stone)).is_equal("")
	assert_str(Executions.parse("Throw her to the pigs",stone)).is_equal("")
	assert_str(Executions.parse("Feed him to the dogs",stone)).is_equal("dogs")
	# no method named
	assert_str(Executions.parse("Put him to death.",stone)).is_equal("")

func test_what_a_people_can_stage_follows_what_they_know_and_the_hall()->void:
	var stone:=Executions.available(stone_age(),false)
	for id in ["boulder","club","fire","dogs","spears","stoning"]:assert_bool(stone.has(id)).override_failure_message(id).is_true()
	for id in ["behead","hang","pigs","arrows","boil","cannon","volley","bronze"]:assert_bool(stone.has(id)).override_failure_message(id).is_false()
	var bronze:=Executions.available(bronze_age(),false)
	for id in ["behead","hang","pigs","arrows","boil","herd","buried"]:assert_bool(bronze.has(id)).override_failure_message(id).is_true()
	assert_bool(bronze.has("cannon")).is_false()
	# a roof beam to hang from: not under the open sky
	var open_sky:=bronze_age();open_sky["set"]="fire_ring"
	assert_bool(Executions.available(open_sky,false).has("hang")).is_false()
	# no dogs in the hall, no dog dinner
	var no_dogs:=stone_age();no_dogs["dogs"]=false
	assert_bool(Executions.available(no_dogs,false).has("dogs")).is_false()
	# every one of the 25 is reachable by something a people could know
	assert_int(Executions.METHODS.size()).is_equal(25)

func test_the_directors_pick_is_seeded_and_never_twice_running()->void:
	var facts:=stone_age()
	assert_str(Executions.choose(facts,77)).is_equal(Executions.choose(facts,77))
	for seed in 40:
		var first:=Executions.choose(facts,seed)
		assert_str(Executions.choose(facts,seed,first)).is_not_equal(first)
	var seen:={}
	for seed in 200:seen[Executions.choose(facts,seed)]=true
	assert_int(seen.size()).is_equal(3)
	# the god's words win when the people can stage them
	assert_str(Executions.pick("feed him to the dogs",facts,3,"dogs")).is_equal("dogs")
	assert_bool(Executions.pick("hang him",facts,3) in Executions.available(facts)).is_true()

func test_only_the_four_selected_acts_are_offered_or_picked()->void:
	assert_array(Executions.available(stone_age())).is_equal(["club","fire","dogs"])
	assert_array(Executions.available(bronze_age())).is_equal(["club","fire","dogs","behead"])
	var without_dogs:=bronze_age();without_dogs["dogs"]=false
	assert_array(Executions.available(without_dogs)).is_equal(["club","fire","behead"])
	for facts in [stone_age(),bronze_age(),without_dogs]:
		var allowed:=Executions.available(facts)
		var offered:=[]
		for item:Dictionary in Executions.menu(facts,"Heha"):
			offered.append(String(item.id))
			assert_str(Executions.pick(String(item.order),facts,3)).is_equal(String(item.id))
		assert_array(offered).is_equal(allowed)
		for seed in 200:
			assert_bool(allowed.has(Executions.choose(facts,seed))).is_true()
		# The parked descriptions still parse, but cannot select their old scene.
		for id:String in Executions.ids():
			var words:="Put Heha to death %s." % Executions.ORDER_WORDS[id]
			assert_bool(allowed.has(Executions.pick(words,facts,14,id))).override_failure_message(id).is_true()
	assert_int(Executions.METHODS.size()).is_equal(25)
	assert_bool(Executions.available(bronze_age(),false).has("pigs")).is_true()

func test_parked_and_unknown_methods_have_no_director_scene()->void:
	var methods:=Executions.ids()+["", "not_a_method"]
	for id:String in methods:
		if Executions.is_staged(id):continue
		var beats:=Director.beats_for({"kind":"execution","method":id,"victim":"main","style":"full"},DirectorTests.home_cast(),DirectorTests.full_facts(60),11)
		assert_array(beats).override_failure_message(id).is_empty()

func test_the_caption_names_what_the_picture_shows()->void:
	assert_str(Executions.caption("behead","Heha Bikatmat")).is_equal("Heha Bikatmat is beheaded at the third stroke before the whole court.")
	assert_str(Executions.caption("dogs","Tuk")).contains("fed to the camp dogs")
	for m:Dictionary in Executions.METHODS:
		assert_str(Executions.caption(String(m.id),"Someone")).starts_with("Someone is ")

func test_a_child_is_never_shown_harmed_and_off_keeps_the_sober_exit()->void:
	assert_str(Executions.style({"name":"Lio","age":9})).is_equal("off")
	assert_str(Executions.style({"name":"Lio","kind":"child"})).is_equal("off")
	assert_str(Executions.style({"name":"Heha","age":38})).is_equal("full")
	Executions.gore="mild"
	assert_str(Executions.style({"name":"Heha","age":38})).is_equal("mild")
	Executions.gore="off"
	assert_str(Executions.style({"name":"Heha","age":38})).is_equal("off")

func test_the_menu_offers_what_the_people_can_as_the_god_would_say_it()->void:
	var menu:=Executions.menu(stone_age(),"Heha Bikatmat")
	assert_bool(menu.is_empty()).is_false()
	var said:=RegEx.new();said.compile("(?i)\\bput [\\w' ]{0,30}?to death\\b")
	for item:Dictionary in menu:
		assert_object(said.search(String(item.order))).override_failure_message(String(item.order)).is_not_null()
		# the words name the very method offered
		assert_str(Executions.parse(String(item.order),stone_age())).is_equal(String(item.id))

func test_every_staged_method_plays_as_a_scene()->void:
	var cast:=DirectorTests.home_cast()
	var facts:=DirectorTests.full_facts(60)
	for id:String in Executions.staged:
		var beats:=Director.beats_for({"kind":"execution","method":id,"victim":"main","style":"full","caption":Executions.caption(id,"Hena Tuvasi")},cast,facts,11)
		var ops:={}
		var end:=-1.0;var hushed:=false;var drum:=false;var caption:=false
		for beat:Dictionary in beats:
			if String(beat.who)=="exec":ops[String(beat.act)]=true
			if String(beat.who)=="exec" and String(beat.act)=="end":end=float(beat.t)
			if String(beat.who)=="exec" and String(beat.act)=="caption":caption=String((beat.args as Dictionary).get("text","")).contains("Hena Tuvasi")
			if String(beat.who)=="room" and String(beat.act)=="hush" and float(beat.t)==0.0:hushed=true
			if beat.get("sound") is Dictionary and String((beat.sound as Dictionary).get("name",""))=="drum_roll":drum=true
			if not String(beat.who) in ["exec","room","camera"]:
				assert_bool(Director.ACTS.has(String(beat.act))).override_failure_message("%s: no acting entry for %s" % [id,beat.act]).is_true()
		assert_bool(hushed).override_failure_message(id+": no hush").is_true()
		assert_bool(drum==(id!="dogs")).override_failure_message(id+": musical cue differs from scene tone").is_true()
		assert_bool(caption).override_failure_message(id+": no caption").is_true()
		assert_float(end).override_failure_message(id+": no end").is_greater(5.0)
		# Includes the dogs' longer approach before the 12-second authored act.
		assert_float(end).override_failure_message(id+": too long").is_less_equal(15.0 if id=="dogs" else 14.5)
		assert_bool(ops.has("vanish") or ops.has("behead") or ops.has("crumble") or ops.has("fall") or ops.has("plan")).override_failure_message(id+": nobody dies on stage").is_true()
		if id in ["club","behead","dogs"]:assert_bool(ops.has("blow")).override_failure_message(id+": no blow for the sound to land on").is_true()

func test_mild_shows_no_blood_and_no_parts_and_cuts_to_the_room()->void:
	var cast:=DirectorTests.home_cast()
	for id:String in ["club","fire","dogs","behead"]:
		var beats:=Director.beats_for({"kind":"execution","method":id,"victim":"main","style":"mild","caption":"x"},cast,DirectorTests.full_facts(60),5)
		var vanished:=false;var cut:=false
		for beat:Dictionary in beats:
			if String(beat.who)=="exec":
				assert_bool(String(beat.act) in ["behead","spray","pool","char","crumble"]).override_failure_message("%s mild: %s" % [id,beat.act]).is_false()
				if String(beat.act)=="vanish":vanished=true
			if String(beat.who)=="camera" and String(beat.act)=="reaction":cut=true
		assert_bool(vanished).is_true()
		assert_bool(cut).is_true()

func test_the_club_home_run_plays_its_beats_in_order()->void:
	# With the acting's plan (K): the batter steps up, the plan plays, the
	# blow lands on the plan's impact, the room after, the caption, the end.
	var beats:=Director.beats_for({"kind":"execution","method":"club","victim":"main","style":"full","caption":"x"},DirectorTests.home_cast(),DirectorTests.full_facts(60),3)
	var at:={}
	for beat:Dictionary in beats:
		var key:=("%s:%s" % [beat.who,beat.act]) if String(beat.who)=="exec" else String(beat.act)
		if not at.has(key):at[key]=float(beat.t)
	assert_float(float(at["exec:approach"])).is_less(float(at["exec:plan"]))
	assert_float(float(at["exec:plan"])).is_less(float(at["exec:blow"]))
	assert_float(float(at["exec:blow"])).is_less(float(at["exec:caption"]))
	assert_float(float(at["exec:caption"])).is_less(float(at["exec:end"]))
	for beat:Dictionary in beats:
		if String(beat.who)=="exec" and String(beat.act)=="plan":assert_str(String((beat.args as Dictionary).act)).is_equal("club_home_run")
	# the blow lands on the plan's impact
	assert_float(float(at["exec:blow"])-float(at["exec:plan"])).is_equal_approx(3.62,0.05)

func test_fire_has_an_impact_and_its_sound_matches_the_visible_collapse()->void:
	var beats:=Director.beats_for({"kind":"execution","method":"fire","victim":"main","style":"full"},DirectorTests.home_cast(),DirectorTests.full_facts(60),3)
	var impact:=-1.0;var collapse:=-1.0;var end:=-1.0
	var walked:=false;var heaved:=false
	for beat:Dictionary in beats:
		if String(beat.who)!="exec":continue
		match String(beat.act):
			"blow":impact=float(beat.t)
			"crumble":collapse=float(beat.t)
			"end":end=float(beat.t)
			"walk":walked=true
			"heave":heaved=true
	assert_float(impact).is_greater(0.0)
	assert_bool(walked and heaved).is_true()
	var track:Array=preload("res://scripts/hud/court_gore_foley.gd").ACTS.into_the_fire
	for cue:Dictionary in track:
		assert_float(impact+float(cue.t)).is_between(0.0,end)
		if String(cue.cue)=="crumble":assert_float(impact+float(cue.t)).is_equal_approx(collapse,0.01)

func test_dog_attack_has_anticipation_completed_aftermath_and_no_comic_return()->void:
	var cast:=DirectorTests.home_cast()
	for dread:int in [0,100]:
		var facts:=DirectorTests.full_facts(dread)
		var beats:=Director.beats_for({"kind":"execution","method":"dogs","victim":"main","style":"full"},cast,facts,3)
		var at:={};var crunch_seconds:=0.0
		for beat:Dictionary in beats:
			var op:=String(beat.act)
			assert_bool(op in ["pack_fetch","fetch","applaud_alone","cover_eyes_peek","double_take"]).override_failure_message(op).is_false()
			if String(beat.who)=="exec":
				at[op]=float(beat.t)
				if op=="pack_crunch":crunch_seconds=float(beat.args.seconds)
			if beat.get("sound") is Dictionary:
				assert_bool(String(beat.sound.get("name","")) in ["drum_roll","punch_drum","bone_drop"]).is_false()
		assert_float(float(at.plan)-float(at.pack_come)).is_greater_equal(2.0)
		assert_float(float(at.pack_crunch)).is_equal_approx(float(at.plan)+6.6,0.01)
		assert_float(float(at.caption)).is_greater(float(at.pack_crunch)+crunch_seconds)
		assert_float(float(at.end)).is_equal_approx(14.8,0.01)
	var plan:=preload("res://scripts/hud/court_acting.gd").exec_plan("dog_dinner")
	assert_bool(plan.things.has("bone")).is_false()
	for cue:Dictionary in plan.cues:assert_bool(String(cue.cue) in ["wave_goodbye","bone_dropped"]).is_false()
	var interrupted_wave:=false
	for clip:Dictionary in plan.roles.victim.clips:
		if String(clip.clip)=="exec_dog_claw" and float(clip.t)>2.2 and float(clip.t)<4.35:interrupted_wave=true
	assert_bool(interrupted_wave).is_true()
