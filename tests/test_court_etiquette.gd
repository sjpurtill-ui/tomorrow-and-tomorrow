extends GdUnitTestSuite
## Presentation facts change routine manners, never the engine's decision.
const Director:=preload("res://scripts/hud/court_director.gd")
const Existing:=preload("res://tests/test_court_director.gd")

func _profile(period:String,greeting:="nod",lean:="throne")->Dictionary:
	return {"period":period,"routine_greeting":greeting,"routine_departure":"bow_small" if greeting in ["bow","kneel"] else greeting,
		"lean":lean,"paperwork":period!="early","rustic_props":period=="early","court_animals":period=="early"}

func _facts(profile:Dictionary)->Dictionary:
	var facts:=Existing.full_facts(60)
	facts["era_tags"]=["writing","metal","dairy","farming"]
	facts["era_tier"]=3
	facts["presentation"]=profile
	return facts

func _acts(beats:Array,who:="main")->Array:
	return beats.filter(func(b:Dictionary)->bool:return String(b.who)==who).map(func(b:Dictionary)->String:return String(b.act))

func test_industrial_and_modern_arrivals_acknowledge_without_routine_bowing()->void:
	for period in ["industrial","modern"]:
		for kind in ["petitioner","commoner","child","envoy"]:
			for seed_value in 24:
				var cast:=Existing.home_cast()
				cast[0]["kind"]=kind
				cast[0]["dread"]=0.7 # includes wrong-door and child-wave recovery
				cast[0]["temper"]="nervous"
				var acts:=_acts(Director.beats_for({"kind":"enter","who":"main"},cast,_facts(_profile(period)),seed_value))
				assert_bool(acts.has("nod")).is_true()
				for act in acts:assert_bool(act in Director.KNEEL_LIKE).override_failure_message("routine %s arrival: %s" % [period,act]).is_false()

func test_medieval_and_early_modern_protocol_keeps_throne_and_assembly_distinct()->void:
	for period in ["medieval","early_modern"]:
		var greeting:="bow" if period=="medieval" else "bow_small"
		var cast:=[{"key":"main","role":"main","kind":"envoy","temper":"calm"}]
		var throne:=Director.beats_for({"kind":"summon","who":"main"},cast,_facts(_profile(period,greeting)),41)
		var assembly:=Director.beats_for({"kind":"summon","who":"main"},cast,_facts(_profile(period,"nod","assembly")),41)
		assert_bool(_acts(throne).has(greeting)).is_true()
		assert_bool(_acts(assembly).has("nod")).is_true()
		assert_bool(_acts(assembly).has(greeting)).is_false()

func test_foreign_envoys_use_their_own_supplied_profile()->void:
	var cast:=Existing.envoy_cast("calm")
	cast[0]["people"]="visiting_realm"
	var facts:=_facts(_profile("modern"))
	facts["presentations"]={"visiting_realm":_profile("medieval","bow")}
	assert_bool(_acts(Director.beats_for({"kind":"summon","who":"main"},cast,facts,2)).has("bow")).is_true()
	facts["presentation"]=_profile("medieval","bow")
	facts["presentations"]={"visiting_realm":_profile("modern")}
	var modern:=_acts(Director.beats_for({"kind":"summon","who":"main"},cast,facts,2))
	assert_bool(modern.has("nod")).is_true()
	assert_bool(modern.has("bow")).is_false()

func test_routine_dismissal_gifts_and_pleased_departure_use_later_etiquette()->void:
	for event:Dictionary in [{"kind":"dismiss","who":"main","reaction":"offended"},
			{"kind":"gift","who":"main","accepted":true},
			{"kind":"decree","who":"main","accepted":true,"reaction":"pleased"},
			{"kind":"exit","who":"main","style":"bow","reaction":"pleased"}]:
		for seed_value in 24:
			var beats:=Director.beats_for(event,Existing.envoy_cast("nervous"),_facts(_profile("modern")),seed_value)
			var acts:=_acts(beats)
			assert_bool(acts.has("nod")).is_true()
			for act in acts:assert_bool(act in Director.KNEEL_LIKE).is_false()
			for beat:Dictionary in beats:
				if String(beat.who)=="main":assert_str(String((beat.args as Dictionary).get("walk",""))).is_not_equal("backward")

func test_stage_shaped_envoy_and_company_keep_foreign_identity_and_etiquette()->void:
	var cast:=[
		{"key":"main","role":"main","person":{"name":"Visiting Envoy","person_id":0,"appearance_civ_id":"visitors"}},
		{"key":"att0","role":"attendant","person":{"name":"First Companion","person_id":0,"appearance_civ_id":"visitors"}},
		{"key":"att1","role":"attendant","person":{"name":"Second Companion","person_id":0,"appearance_civ_id":"visitors"}},
		{"key":"official","role":"court","person":{"name":"Local Official","person_id":0}}]
	var facts:=_facts(_profile("modern"))
	facts["envoy"]={"civ_id":"visitors"}
	facts["presentations"]={"visitors":_profile("medieval","bow")}
	var normalized:=Director.normal_cast(cast,facts)
	for member:Dictionary in normalized.slice(0,3):assert_str(String(member.people)).is_equal("visitors")
	assert_str(String(normalized[0].kind)).is_equal("envoy")
	assert_str(String(normalized[3].people)).is_equal("player")
	var acts:=_acts(Director.beats_for({"kind":"enter","who":"main"},cast,facts,19))
	assert_bool(acts.has("bow")).is_true()
	assert_bool(acts.has("nod")).is_false()

func test_foreign_prisoner_keeps_identity_without_becoming_an_envoy()->void:
	var cast:=[{"key":"main","role":"main","person":{"name":"Prisoner","person_id":0,"appearance_civ_id":"visitors"}}]
	var normalized:=Director.normal_cast(cast,_facts(_profile("modern")))
	assert_str(String(normalized[0].people)).is_equal("visitors")
	assert_str(String(normalized[0].get("kind",""))).is_not_equal("envoy")

func test_explicit_reverence_and_fear_departures_are_not_replaced_by_routine_nods()->void:
	var modern:=_facts(_profile("modern"));var legacy:=modern.duplicate();legacy.erase("presentation")
	for reaction in ["awe","reverence","dread","fear"]:
		var event:={"kind":"exit","who":"main","style":"bow","reaction":reaction}
		for seed_value in 12:
			assert_str(var_to_str(Director.beats_for(event,Existing.home_cast(),modern,seed_value))).is_equal(
				var_to_str(Director.beats_for(event,Existing.home_cast(),legacy,seed_value)))

func test_modern_greetings_keep_love_and_dread_visible()->void:
	var cast:=[{"key":"main","role":"main","kind":"petitioner","dread":0.7}]
	var facts:=_facts(_profile("modern"))
	var frightened:=_acts(Director.beats_for({"kind":"summon","who":"main"},cast,facts,8))
	assert_bool(frightened.has("wring_hands")).is_true()
	cast[0]["dread"]=0.0;cast[0]["love"]=0.95
	var devoted:=_acts(Director.beats_for({"kind":"summon","who":"main"},cast,facts,8))
	assert_bool(devoted.has("beam")).is_true()
	assert_bool(devoted.has("nod")).is_true()

func test_office_extras_are_visitors_and_clerks_without_camp_props_or_animals()->void:
	var facts:=_facts(_profile("modern"))
	var extras:=Director.extras(facts,8)
	assert_bool(extras.any(func(e:Dictionary)->bool:return String(e.kind)=="scribe" and bool(e.get("paperwork",false)))).is_true()
	for entry:Dictionary in extras:
		assert_bool(String(entry.kind) in ["dog","goat"]).is_false()
		assert_bool(String(entry.get("stance","")) in ["staff","bowl"]).is_false()
	var loops:=Director.ambient(extras,facts,8)
	assert_bool(_acts(loops,"scribe").has("review_brief")).is_true()
	var announced:=Director.beats_for({"kind":"decree","issued":true},extras,facts,8)
	assert_bool(_acts(announced,"scribe").has("review_brief")).is_true()
	assert_str(String(Director.performance({"act":"review_brief"}).get("clip",""))).is_equal("stroke_chin")
	for seed_value in 24:
		var acts:=_acts(Director.beats_for({"kind":"god_speaks","text":"Read the report."},extras,facts,seed_value),"scribe")
		assert_bool(acts.has("scribble") or acts.has("scratch_out")).is_false()

func test_office_war_vigilance_does_not_sharpen_an_archaic_spear()->void:
	var facts:=_facts(_profile("modern"));facts["war"]={"enemy":"Rivals"}
	var loops:=Director.ambient(Existing.home_cast(),facts,9)
	assert_bool(loops.any(func(b:Dictionary)->bool:return String(b.act)=="glance_door" and String(b.because)=="war")).is_true()
	assert_bool(loops.any(func(b:Dictionary)->bool:return String(b.act)=="sharpen_spear")).is_false()

func test_explicit_divine_responses_refusals_and_terminal_exits_are_identical()->void:
	var modern:=_facts(_profile("modern"))
	var legacy:=modern.duplicate();legacy.erase("presentation")
	var events:=[{"kind":"divine","action":"terrify","target":"main","response":"cower"},
		{"kind":"divine","action":"terrify","target":"main","response":"defy","witnesses":{"p1":"unbowed","p2":"shaken"}},
		{"kind":"divine","action":"bless","target":"main","response":"relief"},
		{"kind":"divine","action":"penance","target":"main","response":"endure"},
		{"kind":"command","verb":"detain","stage":"refuse_seized","actor":"p1","target":"main","obedience":"refuse"},
		{"kind":"command","verb":"kill","stage":"prostrate","actor":"p1","target":"god"},
		{"kind":"execution","method":"club","victim":"main","style":"full"},
		{"kind":"execution","method":"behead","victim":"main","style":"full"},
		{"kind":"execution","method":"fire","victim":"main","style":"full"},
		{"kind":"execution","method":"dogs","victim":"main","style":"full"},
		{"kind":"exit","who":"main","style":"led"},{"kind":"exit","who":"main","style":"fall"}]
	for event:Dictionary in events:
		for seed_value in 24:
			assert_str(var_to_str(Director.beats_for(event,Existing.home_cast(),modern,seed_value))).override_failure_message("changed explicit %s" % event).is_equal(
				var_to_str(Director.beats_for(event,Existing.home_cast(),legacy,seed_value)))

func test_legacy_callers_keep_bowing_camp_props_and_scribes()->void:
	var facts:=_facts({});facts.erase("presentation")
	var cast:=[{"key":"main","role":"main","kind":"envoy","temper":"calm"}]
	assert_bool(_acts(Director.beats_for({"kind":"summon","who":"main"},cast,facts,2)).has("bow")).is_true()
	var extras:=Director.extras(facts,2)
	assert_bool(extras.any(func(e:Dictionary)->bool:return String(e.get("stance",""))=="bowl")).is_true()
	assert_bool(extras.any(func(e:Dictionary)->bool:return String(e.kind)=="goat")).is_true()
	assert_bool(_acts(Director.ambient(extras,facts,2),"scribe").has("scribble")).is_true()

func test_protocol_planning_is_deterministic_and_does_not_mutate_inputs()->void:
	var event:={"kind":"summon","who":"main"}
	var cast:=Existing.home_cast();var facts:=_facts(_profile("modern"))
	var before:=var_to_str([event,cast,facts])
	var a:=Director.beats_for(event,cast,facts,73,{})
	var b:=Director.beats_for(event,cast,facts,73,{})
	assert_str(var_to_str(a)).is_equal(var_to_str(b))
	assert_str(var_to_str([event,cast,facts])).is_equal(before)
