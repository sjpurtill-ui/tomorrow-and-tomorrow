extends GdUnitTestSuite
## WHAT THE RULER STANDS TO GAIN (proposal_stakes.gd): every proposal the court
## puts before the ruler says, before the choice, what it gives, what it costs,
## how likely it is to work and what saying no costs, in the engine's numbers.
##
## The world is a young people a season after the founding: about 120 souls,
## a Hearth Chief leading the camp, sixty days lived through the consequence
## engine so food, births and health are real readings, not defaults.

const Stakes:=preload("res://scripts/proposal_stakes.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Society:=preload("res://scripts/society_model.gd")

const ROADS:="Improve roads and organize haulers"
const HEALERS:="Organize healers to care for the sick"
const SCHOLARS:="Support scholars and fund research"

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_READER_MODEL"]: OS.unset_environment(key)

func after()->void:
	WorldSimulation.clear()
	GameState.elapsed_days=0
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	for node:Node in _processing: node.set_process(bool(_processing[node]))
	Stakes.clear_cache()

func before_test()->void:
	## A young people a season after the founding.
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(481902)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure()
	GameState.initialize_population_model()
	GameState.settlement_name="Dawngate"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	ConsequenceEngine.initialize()
	GameState.housing_capacity=140
	for day in 60:
		GameState.elapsed_days=float(day+300)
		# No mapped river in a test world: the carriers' water is taken as full.
		GameState.water_metrics["intake_ratio"]=1.0;GameState.water_metrics["source_accessible"]=true
		ConsequenceEngine.process_day({"traveling":false})
	Stakes.clear_cache()

# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------

func _city_id()->String:
	return String((GameState.player_settlements[0] as Dictionary).id)

func _leader()->Dictionary:
	return GovernmentPeopleSystem.settlement_leader(_city_id())

func _issue(text:String)->Dictionary:
	## The decree as the court's "Issue their decree" sends it (local_terrain
	## issue_civic_directive_text -> AdvisorSystem.resolve_civic_directive).
	var leader:=_leader()
	var order:=AdvisorSystem.begin_civic_directive(text,_city_id(),leader)
	return AdvisorSystem.resolve_civic_directive(text,PronouncementInterpreter._local_interpretation(text),order,_city_id(),int(leader.person_id))

func _labor_factor()->float:
	var load:=float(ConsequenceEngine.governance_metrics().get("administrative_load",0.0))
	return (1.0+ConsequenceEngine.policy_effect("labor_multiplier")+GameState.founding_effect("labor_multiplier")+ProgressionSystem.effect("labor_efficiency"))*(1.0-load)

func _entry(list:Array,what:String)->Dictionary:
	for entry in list:
		if String((entry as Dictionary).get("what",""))==what: return entry
	return {}

func _texts(list:Array)->String:
	return " | ".join(PackedStringArray(list.map(func(e:Dictionary)->String: return String(e.text))))

func _ledger()->String:
	## Everything a reading of the stakes must leave exactly as it was.
	var leader:=_leader()
	return JSON.stringify([GameState.active_modifiers.size(),GameState.resource_stockpiles,FoodSystem.total_stored(),GameState.simulation_metrics.get("cohesion"),GameState.simulation_metrics.get("legitimacy"),
		(leader.get("relationships",{}) as Dictionary).get("sovereign",{}),GameState.sovereign_orders.size(),Hall.state().get("queue",[]).size()])

func _petition(decree_kind:String="ambition")->String:
	var person:Dictionary=Hall._officials()[0]
	Hall._court_direct=true
	var audience:=Hall.debug_situation(decree_kind,str(int(person.person_id)))
	Hall._court_direct=false
	assert_bool(audience.is_empty()).override_failure_message("no %s petition could be raised" % decree_kind).is_false()
	return String(audience.get("id",""))

# --------------------------------------------------------------------------
# decrees
# --------------------------------------------------------------------------

func test_the_roads_decree_says_what_the_engine_then_does()->void:
	var before:=_ledger()
	var s:=Stakes.for_decree(ROADS)
	assert_str(_ledger()).override_failure_message("reading the stakes changed the world").is_equal(before)
	assert_str(String(s.kind)).is_equal("decree")
	assert_bool(bool(s.blocked)).is_false()
	assert_int(int(s.days)).is_equal(240)
	var gain:Dictionary=(s.gains as Array)[0]
	assert_str(String(gain.what)).is_equal("logistics")
	assert_float(float(gain.points)).is_greater(0.5)
	assert_str(String(gain.text)).starts_with("Logistics up about").contains("carrying and hauling")
	var work:=_entry(s.costs,"work")
	assert_float(float(work.get("people",0.0))).is_greater(0.5)
	assert_str(String(s.odds)).contains("will do it")
	assert_str(String(s.short)).starts_with("Logistics up about").contains("for eight moons").contains("takes the work of about")
	# Now issue it as the court would: the engine moves exactly what was said.
	var numbers:Dictionary=s.numbers
	var factor_before:=_labor_factor()
	var resolved:=_issue(ROADS)
	assert_str(String(resolved.get("status",""))).is_not_equal("leader_refused")
	assert_float(ConsequenceEngine.policy_effect("logistics_target")).is_equal_approx(float(numbers.logistics_target),0.000001)
	assert_float(ConsequenceEngine.policy_effect("labor_multiplier")).is_equal_approx(float(numbers.labor_multiplier),0.000001)
	# The work it takes: the labour channel and the stewards' upkeep, as a share
	# of the people able to work, is what the day's labour really loses.
	var lost:=float(GameState.able_population())*(_labor_factor()/factor_before-1.0)
	assert_float(lost).is_equal_approx(float(numbers.people_work),0.05)
	# The strength said is the capacity formula with hauling moved as far as
	# the engine moves it by the order's last day.
	var inputs:Dictionary=DiscoverySystem.society_model.capacity_inputs()
	var moved:=inputs.duplicate()
	moved["hauling"]=float(inputs.hauling)+float(numbers.logistics_target)*(1.0-pow(1.0-0.016,240.0))
	var points:=(Society.capacity_value("logistics",moved)-Society.capacity_value("logistics",inputs))*100.0
	assert_float(float(gain.points)).is_equal_approx(points,0.01)

func test_the_healers_name_health_newborns_and_the_food_they_draw()->void:
	var s:=Stakes.for_decree(HEALERS)
	var health:=_entry(s.gains,"health")
	assert_float(float(health.get("points",0.0))).override_failure_message(_texts(s.gains)).is_greater(1.0)
	assert_str(String(health.get("text",""))).starts_with("Health up about")
	var newborns:=_entry(s.gains,"newborns")
	assert_float(float(newborns.get("percent",0.0))).is_greater(0.0)
	assert_str(String(newborns.get("text",""))).starts_with("Newborn deaths down about")
	var food:=_entry(s.costs,"food")
	assert_bool(food.is_empty()).override_failure_message(_texts(s.costs)).is_false()
	var stored:=FoodSystem.total_stored()
	_issue(HEALERS)
	# The food said is the food drawn from the stores when the order is given.
	assert_float(stored-FoodSystem.total_stored()).is_equal_approx(float(food.get("amount",0.0)),0.01)
	assert_float(ConsequenceEngine.policy_effect("health_target")).is_equal_approx(float((s.numbers as Dictionary).get("health_target",0.0)),0.000001)

func test_the_scholars_promise_a_faster_pace_of_learning_not_discoveries()->void:
	var s:=Stakes.for_decree(SCHOLARS)
	var learning:=_entry(s.gains,"learning")
	assert_str(String(learning.get("text",""))).starts_with("What we remember grows about").ends_with("% faster")
	# The knowledge channel is a multiplier on each day's gain of what we
	# remember (process_day): this much, of a pace of one.
	var channel:=float((s.numbers as Dictionary).get("knowledge_gain",0.0))
	assert_float(float(learning.get("percent",0.0))).is_equal_approx(channel*100.0,0.5)
	assert_str(Stakes.tip(s).to_lower()).not_contains("discover")

func test_an_order_already_standing_is_not_counted_twice()->void:
	_issue(ROADS)
	Stakes.clear_cache()
	var again:=Stakes.for_decree(ROADS)
	assert_str(" ".join(PackedStringArray(again.notes))).contains("already in force")
	assert_bool(_entry(again.gains,"logistics").is_empty()).override_failure_message(_texts(again.gains)).is_true()
	assert_str(String(again.short)).override_failure_message("short: %s | gains: %s | costs: %s" % [again.short,_texts(again.gains),_texts(again.costs)]).starts_with("Already in force")
	assert_str(_texts(again.gains)).not_contains("Logistics up")

func test_a_part_the_people_cannot_do_is_named_and_the_rest_still_counts()->void:
	var s:=Stakes.for_decree("Build stone houses for the families")
	assert_bool(bool(s.blocked)).is_false()
	var notes:=" ".join(PackedStringArray(s.notes))
	assert_str(notes).contains("must wait").contains("stone selection")
	assert_array(s.gains).is_not_empty()

func test_with_no_leader_nothing_would_come_of_it()->void:
	var settlement:Dictionary=GameState.player_settlements[0]
	var s:=Stakes._decree(ROADS,settlement,{})
	assert_bool(bool(s.blocked)).is_true()
	assert_str(String(s.short)).starts_with("Cannot be done yet")
	assert_array(s.gains).is_empty()

# --------------------------------------------------------------------------
# aims and works
# --------------------------------------------------------------------------

func test_an_aim_says_what_keeping_it_gives_and_failing_it_costs()->void:
	var day:=int(GameState.elapsed_days)
	var cands:=Aims.propose(day)
	assert_array(cands).is_not_empty()
	var cand:Dictionary=cands[0]
	for c in cands:
		if String(c.template)=="grow": cand=c
	var s:=Stakes.for_aim(cand)
	var gains:=_texts(s.gains)
	assert_str(gains).contains("Culture up about").contains("Institutions up about").contains("loves and trusts you more").contains("fades")
	assert_str(_texts(s.costs)).contains("love you less and fear you more")
	assert_str(String(s.pace_short)).is_not_empty()
	if String(cand.template)=="grow": assert_str(String(s.odds)).contains(str(int(cand.target)))
	assert_str(String(s.refusal)).contains("instead of")
	# Keep the aim and see: Culture rises by what was said.
	var culture:=_entry(s.gains,"culture")
	var said:=float(Stakes.capacity_shift(Stakes.aim_ending("god").moves)[0].points)
	var before:=Society.capacity_value("culture",DiscoverySystem.society_model.capacity_inputs())
	Aims.adopt(cand,"god",day)
	Aims.fulfil(day)
	var after:=Society.capacity_value("culture",DiscoverySystem.society_model.capacity_inputs())
	assert_str(String(culture.get("text",""))).starts_with("Culture up about")
	assert_float((after-before)*100.0).is_equal_approx(said,0.05)

func test_pressing_an_aim_says_the_decree_it_sends_and_the_strain()->void:
	var day:=int(GameState.elapsed_days)
	var cand:Dictionary={}
	for c in Aims.propose(day):
		if String(c.template) in ["grow","plenty","reach","knowledge","unity","work"]: cand=c; break
	assert_bool(cand.is_empty()).is_false()
	Aims.adopt(cand,"god",day)
	var aim:=Hall.open_matter(String(Aims.file_course(day).get("id","")))
	assert_bool(aim.is_empty()).is_false()
	var press:Dictionary={}
	for option in Hall.options(String(aim.id)):
		if String(option.id)=="aim_press": press=option
	var decree:=String(Aims.PRESS_DECREES[String(cand.template)])
	assert_str(String(press.get("stakes_tip",""))).contains("It orders:").contains(decree).contains("fear your eye more").contains("Letting it go:")
	assert_str(String(press.get("stakes_short",""))).is_not_empty()

func test_a_hungry_petition_says_what_saying_no_leaves_standing()->void:
	var person:Dictionary=Hall._officials()[0]
	var day:=int(GameState.elapsed_days)
	var audience:=Hall._court_audience(person,{"topic":"food","summary":"Food stores would last about 9 days.","decree":"Send gatherers to find food","ask":"food:band2","situation_type":"crisis_petition"},{"type":"debug","key":"debug","data":{}},day)
	Hall._enqueue(audience,day)
	var s:=Hall.stakes(String(audience.id))
	var days:=roundi(float(Hall.conditions().food_days))
	assert_str(String(s.refusal)).contains("trusts you less").contains("The stores still last about %d days." % days)
	assert_str(String(s.refusal_spoken)).contains("trust your word a little less")
	assert_str(_texts(s.gains)).contains("more food a day from gathering, hunting and fishing")

func test_a_great_work_says_what_it_gives_what_it_needs_and_its_odds()->void:
	var audience:=Hall.debug_force("wonder_proposal")
	assert_bool(audience.is_empty()).is_false()
	var id:=String(audience.id)
	var s:=Hall.stakes(id)
	assert_str(String(s.kind)).is_equal("work")
	assert_array(s.gains).is_not_empty()
	assert_str(String(s.odds)).contains("It stands whole")
	var assess:Dictionary=preload("res://scripts/great_works_audience.gd").assessment(Hall.find(id))
	assert_dict(s.numbers).is_equal(assess.get("odds",{}))
	var costs:=_texts(s.costs)
	assert_str(costs).contains(preload("res://scripts/great_works_audience.gd").costs_words(assess.get("costs",{})))
	for option in Hall.options(id):
		if String(option.id)=="commission": assert_str(String(option.get("stakes_short",""))).starts_with("If it stands:")

# --------------------------------------------------------------------------
# the court: cards, the block, the voice
# --------------------------------------------------------------------------

func test_the_decree_card_and_the_block_carry_the_stakes()->void:
	var id:=_petition()
	var weighed:=Hall.stakes(id)
	assert_bool(weighed.is_empty()).is_false()
	var decree:=String((Hall.find(id).petition as Dictionary).suggested_decree)
	var card:Dictionary={}
	for option in Hall.options(id):
		if String(option.id)=="decree": card=option
	assert_str(String(card.get("stakes_short",""))).is_equal(String(weighed.short))
	assert_str(String(card.get("stakes_tip",""))).contains("You gain:").contains("How likely:").contains("If you say no:")
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=id
	add_child(modal)
	await await_idle_frame()
	var button:Button=modal.find_child("Option_decree",true,false)
	assert_object(button).is_not_null()
	var sub:Label=button.find_child("OptionSub",true,false)
	assert_str(sub.text).is_equal(String(weighed.short))
	assert_str(button.tooltip_text).contains(decree).contains("You gain:")
	var panel:=modal.find_child("StakesPanel",true,false)
	assert_object(panel).is_not_null()
	var said:=PackedStringArray()
	for label in panel.find_children("*","Label",true,false): said.append((label as Label).text)
	var block:=" / ".join(said)
	assert_str(block).contains("WHAT YOU STAND TO GAIN").contains("You gain").contains("If you say no")
	# Once answered, the block goes with the answers.
	modal.choose("promise")
	assert_bool((modal.find_child("Stakes",true,false) as Control).visible).is_false()

func test_a_crisis_answer_shows_its_cost_on_the_court_card()->void:
	assert_str(Stakes.cost_tag_words("labour")).is_equal("hands taken from other work")
	assert_str(Stakes.cost_tag_words("String: their anger")).is_equal("their anger")
	var id:=_petition()
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=id
	add_child(modal)
	await await_idle_frame()
	var button:Button=modal._option_card({"id":"hunt","label":"Send the strongest out to hunt far","sub":"A month away.","tone":"neutral","enabled":true,"cost":"labour","cost_words":Stakes.cost_tag_words("labour")})
	auto_free(button)
	var cost:Label=button.find_child("OptionCost",true,false)
	assert_object(cost).is_not_null()
	assert_str(cost.text).is_equal("Costs: hands taken from other work")
	assert_str(button.tooltip_text).contains("Costs: hands taken from other work")

func test_the_voice_is_told_the_stakes_and_answers_from_them_offline()->void:
	var id:=_petition()
	var context:=Hall.voice_context(id)
	var facts:Dictionary=context.get("stakes",{})
	assert_str(String(facts.get("you_gain",""))).contains("Logistics up about")
	assert_int(int(facts.get("lasts_days",0))).is_equal(240)
	var voice:Node=auto_free(Voice.new())
	voice.force_offline=true
	add_child(voice)
	var s:Dictionary=voice.scene(id)
	var prompt:String=voice.build_prompt(s,"speak",{"player_text":"What do we gain from this?"})
	assert_str(prompt).contains("WHAT THE RULER STANDS TO GAIN").contains("Logistics up about").contains("in WHAT THE RULER STANDS TO GAIN")
	# The facts line keeps its old shape: the stakes are their own section.
	var facts_line:=prompt.get_slice("FACTS YOU MAY USE (nothing else is true): ",1).get_slice("\n",0)
	assert_str(facts_line).not_contains("you_gain")
	# The numbers the stakes give are numbers a live line may say.
	var allowed:Dictionary=voice.allowed_numbers(s,{"player_text":"What do we gain?"})
	assert_bool(allowed.has("240")).is_true()
	assert_bool(allowed.has("8")).is_true()
	# Offline: asked what we gain, what refusing costs and how long.
	for asked in [["What's in it for us?","If you order it: Logistics up about"],["What if we refuse?","trust your word a little less"],["How long would it take?","It would run eight moons"]]:
		var before:=(Hall.find(id).lines as Array).size()
		voice.player_speaks(id,String(asked[0]))
		var lines:Array=(Hall.find(id).lines as Array).slice(before)
		var reply:=" ".join(PackedStringArray(lines.map(func(l:Dictionary)->String: return String(l.text))))
		assert_str(reply).override_failure_message("asked '%s', heard: %s" % [asked[0],reply]).contains(String(asked[1]))
	# "What do you want?" is still the petitioner's need, not the stakes.
	assert_bool(voice.stakes_gain_question("What do you want?")).is_false()
	assert_bool(voice.stakes_gain_question("is it worth it?")).is_true()
	assert_bool(voice.stakes_gain_question("How does this help us?")).is_true()

func _petition_for(decree:String,words:String)->String:
	## An official brings this decree to court, as their ambition would.
	var person:Dictionary=Hall._officials()[0]
	var day:=int(GameState.elapsed_days)
	var audience:=Hall._court_audience(person,{"topic":"ambition","summary":words % String(person.name),"decree":decree,"ask":"ambition:"+decree,"situation_type":"ambition"},{"type":"debug","key":"debug","data":{}},day)
	Hall._enqueue(audience,day)
	return String(audience.id)

static func _rows(stakes:Dictionary)->String:
	return "\n    ".join(PackedStringArray(Stakes.lines(stakes).map(func(r:Dictionary)->String: return "%s: %s" % [r.key,r.text])))

func test_the_texts_for_the_handoff()->void:
	## The exact card and block texts in this early world, for the record.
	for pair in [[ROADS,"%s wants the roads improved and hauling organized."],[HEALERS,"%s wants healers organized before the next sickness, not during it."],[SCHOLARS,"%s wants more hands set to inquiry, under their eye."]]:
		var id:=_petition_for(String(pair[0]),String(pair[1]))
		var card:Dictionary={}
		for option in Hall.options(id):
			if String(option.id)=="decree": card=option
		print("DECREE \"%s\"\n  card: %s | %s\n  tooltip:\n    %s\n  block:\n    %s" % [pair[0],card.get("label",""),card.get("stakes_short",""),String(card.get("stakes_tip","")).replace("\n","\n    "),_rows(Hall.stakes(id))])
		assert_str(String(card.get("stakes_short",""))).is_not_empty()
		Hall.conclude(id,"heard")
	var day:=int(GameState.elapsed_days)
	var cands:=Aims.propose(day)
	for cand in cands: cand["proposed_day"]=day
	var matter:=Aims.file_proposal(day,cands)
	var aim:=Hall.open_matter(String(matter.get("id","")))
	for option in Hall.options(String(aim.id)):
		print("AIM card: %s | %s" % [option.label,option.get("stakes_short",option.sub)])
		if option.has("stakes_tip"): print("  tooltip:\n    "+String(option.stakes_tip).replace("\n","\n    "))
	print("AIM block:\n    "+_rows(Hall.stakes(String(aim.id))))
	var work:=Hall.debug_force("wonder_proposal")
	for option in Hall.options(String(work.id)):
		print("WORK card: %s | %s" % [option.label,option.get("stakes_short",option.sub)])
	print("WORK block:\n    "+_rows(Hall.stakes(String(work.id))))

func test_the_block_takes_its_room_from_the_transcript_not_the_card()->void:
	## Under the conversation, above the answers: the card keeps its height,
	## the transcript gives up the room (a full-size court, 1920 by 1080).
	get_tree().root.size=Vector2i(1920,1080)
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=_petition()
	add_child(modal)
	await await_idle_frame()
	await await_idle_frame()
	var card:Control=modal.card
	var stakes:Control=modal.find_child("Stakes",true,false)
	assert_bool(stakes.visible).is_true()
	assert_object(stakes.get_parent()).is_equal(modal.find_child("Transcript",true,false).get_parent().get_parent().get_parent())
	var with_block:=card.get_combined_minimum_size().y
	stakes.visible=false
	await await_idle_frame()
	assert_float(card.get_combined_minimum_size().y).is_equal_approx(with_block,0.5)
	assert_float(with_block).is_less_equal(float(Modal.DESIGN_SIZE.y))
