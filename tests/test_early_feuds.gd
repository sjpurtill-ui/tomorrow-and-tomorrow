extends GdUnitTestSuite
## EARLY CONFLICT IS FEUD AND RAID, NOT DECLARED WAR (conflict_scale.gd,
## war_loop.gd).
##
## The player, in a stone-age game: "Towns of 120 people don't DECLARE WAR.
## They just fight and raid, sending raiders." and "they don't send envoys to
## brag WHILE THEY DO THIS so that I CAN CUT THEIR HEADS OFF." Below the war
## line (both peoples at least ConflictScale.WAR_POP) fighting is a feud:
## raids, ambushes, vengeance, a blood price; no declaration, no generals, no
## fronts, no heralds' terms, and no envoy into the hall of the people being
## raided except a rare peace-seeker once the raids have stopped. Peoples
## organised for war still prepare, declare and fight wars as before.

const WAR:=preload("res://scripts/war_loop.gd")
const Scale:=preload("res://scripts/conflict_scale.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const RIVALS:=preload("res://scripts/rival_rulers.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Facts:=preload("res://scripts/court_facts.gd")
const Answers:=preload("res://scripts/court_answers.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
const Lives:=preload("res://scripts/court_lives.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Marks:=preload("res://scripts/war_map_marks.gd")
const Overlay:=preload("res://scripts/hud/war_map_overlay.gd")

## Words a feud never says of itself.
const WAR_WORDS:=["declare","declared","declaration","goes to war","go to war","generals","general take","front","war with","war over","herald","terms"]

var probe:Node
var civ_id:=""
var slot:=""
var _opponents:=0

func before_test()->void:
	slot="early_feuds_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	_opponents=GameState.opponent_count
	probe=auto_free(HallProbe.new())
	probe._base()
	GameState.opponent_count=4
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	probe._people(140)
	probe._refill()
	for civ in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.player_relation
		relation.contact_level=2; relation.met_day=0; relation.opinion=-0.1; relation.border_tension=0.3
		relation.home_location_known=false; relation.home_position={}
		_set_pop(civ,150.0)
		civ.food_days=45.0
		for other in civ.relations: civ.relations[other].at_war=false
		probe._stock_actor(String(civ.id),800,120)
		WorldSimulation.scoped(String(civ.id),func()->void:WorldSimulation.state.ensure_population_total(150))
	probe._fill_court()
	GameState.elapsed_days=10
	civ_id=String(CivilizationSystem.civilizations[0].id)
	Hall.envoys_only=false

func after_test()->void:
	Hall.envoys_only=false
	if slot!="": DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	GameState.elapsed_days=0
	# The world is left with as many peoples as it had (other suites count them).
	if _opponents>0: GameState.opponent_count=_opponents
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	# The rival peoples' own systems (probe._stock_actor) are freed here, not
	# left as orphans for the next suite.
	WorldSimulation.clear()

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

func _civ(id:String)->Dictionary:
	for civ in CivilizationSystem.civilizations:
		if String(civ.id)==id: return civ
	return {}

func _relation(id:String)->Dictionary:
	return _civ(id).player_relation

## A people's number, with its age groups and towns kept in step (the save
## validator checks both).
func _set_pop(civ:Dictionary,n:float)->void:
	var before:=maxf(1.0,float(civ.get("population",n)))
	civ["population"]=n
	civ["cohorts"]=CivilizationSystem._scaled_cohorts(civ.get("cohorts",{}),n)
	CivilizationSystem._scale_strategic_region_populations(civ,n/before)
	civ["military_population"]=minf(float(civ.get("military_population",0.0)),n*0.1)

## Both peoples organised for war (a chiefdom or more on each side).
func _make_large(id:String)->void:
	GameState.ensure_population_total(2400); GameState.housing_capacity=3200
	_set_pop(_civ(id),3000.0)

func _chronicle_about(id:String)->String:
	var name:=Hall._civ_name(id)
	var out:=PackedStringArray()
	for e in (GameState.chronicle.get("entries",[]) as Array):
		var t:=String((e as Dictionary).get("title",""))+" | "+String((e as Dictionary).get("text",""))
		if name in t: out.append(t)
	return "\n".join(out).to_lower()

func _threat(id:String,bluff:bool=false)->Dictionary:
	var day:=int(GameState.elapsed_days)
	var audience:=Hall._new_audience("foreign","threat",day)
	audience.civ_id=id; audience.civ_name=Hall._civ_name(id)
	audience.speaker={"name":"Herald of "+Hall._civ_name(id),"title":"Herald","person_id":0,"role":"envoy"}
	audience.terms={"resource":"Food","amount":40.0}
	audience.situation={"type":"tribute_demand","ask":"tribute:Food","headline":"demands tribute","summary":"%s demands 40 Food in tribute." % Hall._civ_name(id)}
	audience["hidden"]={"bluff":bluff}
	RIVALS.character(id)
	Hall._enqueue(audience,day,true)
	return audience

func _envoy(id:String)->Dictionary:
	var day:=int(GameState.elapsed_days)
	var audience:=Hall._new_audience("foreign","gift",day)
	audience.civ_id=id; audience.civ_name=Hall._civ_name(id)
	audience.speaker={"name":"Qira Venn","title":"Envoy","person_id":0,"role":"envoy"}
	audience.terms={"resource":"Food","amount":10.0}
	audience.situation={"type":"gift_goods","ask":"gift:Food","headline":"brings a gift","summary":"%s sends 10 Food as a gift." % Hall._civ_name(id)}
	RIVALS.character(id)
	Hall._enqueue(audience,day,true)
	return audience

func _run(days:int,step:Callable=Callable())->void:
	for i in days:
		GameState.elapsed_days=int(GameState.elapsed_days)+1
		probe._refill()
		var day:=int(GameState.elapsed_days)
		WAR.daily(day)
		RIVALS.daily(day)
		if step.is_valid(): step.call(day)

# --------------------------------------------------------------------------
# One predicate
# --------------------------------------------------------------------------

func test_the_war_line_is_one_predicate_for_every_system()->void:
	assert_float(Scale.WAR_POP).is_between(1000.0,2000.0)
	assert_bool(Scale.formal(civ_id)).override_failure_message("140 and 150 people cannot be at war").is_false()
	assert_str(Scale.word(civ_id)).is_equal("feud")
	_make_large(civ_id)
	assert_bool(Scale.formal(civ_id)).is_true()
	assert_str(Scale.word(civ_id)).is_equal("war")
	# One side small is enough to make it a feud.
	GameState.ensure_population_total(300)
	assert_bool(Scale.formal(civ_id)).is_false()

# --------------------------------------------------------------------------
# 1. A small people with a grievance sends raiders; nothing declares war
# --------------------------------------------------------------------------

func test_a_small_people_with_a_grievance_raids_and_never_declares_war()->void:
	var audience:=_threat(civ_id)
	Hall.resolve(String(audience.id),"defy")
	# However far the ladder climbs, the top rung among small peoples is an
	# ambush, never a war: a fight at the border lately and old blood between us.
	var f:=WAR.front(civ_id)
	f["level"]=2; f["last_skirmish"]=int(GameState.elapsed_days); f["last_harm"]=int(GameState.elapsed_days)
	for i in 30:
		GameState.elapsed_days=int(GameState.elapsed_days)+37
		probe._refill()
		WAR._schedule(civ_id,int(GameState.elapsed_days),"refusal","test")
		WAR.front(civ_id)["last_skirmish"]=int(GameState.elapsed_days)
		WAR._execute(civ_id,int(GameState.elapsed_days))
	var relation:=_relation(civ_id)
	assert_bool(bool(relation.get("at_war",false))).override_failure_message("a people of 150 is at war").is_false()
	assert_str(String(relation.get("treaty",""))).is_not_equal("war")
	assert_dict(WAR.front(civ_id).war as Dictionary).override_failure_message("a war object exists for a feud").is_empty()
	for record in CivilizationSystem.war_history: assert_str(String(record.get("status",""))).is_not_equal("active")
	var kinds:Array=(WAR.state().log as Array).filter(func(e:Dictionary)->bool:return String(e.civ)==civ_id).map(func(e:Dictionary)->String:return String(e.kind))
	assert_array(kinds).contains(["raid"])
	assert_bool(kinds.has("ambush") or kinds.has("skirmish")).override_failure_message("the ladder never climbed: %s" % str(kinds)).is_true()
	assert_array(kinds).not_contains(["war"])
	assert_int(int(WAR.summary().stats.get("wars",0))).is_equal(0)
	# The words say raid, ambush or feud; never war, declare, generals or front.
	var told:=_chronicle_about(civ_id)
	assert_str(told).is_not_empty()
	for word in WAR_WORDS: assert_bool(word in told).override_failure_message("the Chronicle of a feud says '%s':\n%s" % [word,told]).is_false()
	# The war leader carries the matter as a raid or the feud.
	var matter:={}
	for m in Hall.matters():
		if String(m.get("situation_type",""))=="war_campaign": matter=m
	assert_dict(matter).is_not_empty()
	var headline:=String(((matter.audience as Dictionary).situation as Dictionary).headline)
	assert_bool(headline in ["comes about the raid","comes about the feud"]).override_failure_message(headline).is_true()

func test_war_cannot_be_declared_or_opened_between_small_peoples()->void:
	assert_bool(WAR.declare(civ_id,10,"the tribute you would not pay")).is_false()
	assert_bool(bool(_relation(civ_id).get("at_war",false))).is_false()
	assert_bool(WAR.feuding(civ_id)).is_true()
	assert_bool(WAR.hot(civ_id)).is_true()
	var opened:=CivilizationSystem.rival_opens_war(civ_id,"Vengeance for an old wrong")
	assert_bool(bool(opened.get("ok",true))).is_false()
	assert_str(String(opened.get("error",""))).is_equal("feud")
	assert_bool(bool(_relation(civ_id).get("at_war",false))).is_false()
	# The god's own diplomacy cannot declare it either; the war leader is asked instead.
	_relation(civ_id)["home_location_known"]=true
	var avail:=CivilizationSystem.player_action_availability(civ_id,"declare_war")
	assert_bool(avail.has("error")).is_true()
	assert_str(String(avail.error)).contains("feud")
	# No campaign of theirs is queued against us.
	for incident in CivilizationSystem.pending_player_incidents: assert_str(String(incident.get("id",""))).does_not_start_with("campaign_%s" % civ_id)

func test_the_war_leader_answers_a_feud_with_the_feuds_own_acts()->void:
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	var audience:={"situation":{"war":{"civ_id":civ_id,"mode":"feud","filed":10}}}
	var ids:Array=WAR.options(audience).map(func(o:Dictionary)->String:return String(o.get("id","")))
	# Their home unknown: find it first; nothing strikes a home we cannot find.
	assert_array(ids).contains(["war_pursue","war_track","war_guard","war_parley","war_price","war_let"])
	assert_array(ids).not_contains(["war_burn","war_chief","war_general","war_pay"])
	WAR._find_home(civ_id,10,"a test","test")
	ids=WAR.options(audience).map(func(o:Dictionary)->String:return String(o.get("id","")))
	assert_array(ids).contains(["war_burn","war_chief","war_price"])
	for o in WAR.options(audience):
		var said:=(String(o.label)+" "+String(o.sub)).to_lower()
		for word in ["declare","generals","front","herald","truce"]: assert_bool(word in said).override_failure_message("a feud option says '%s': %s" % [word,said]).is_false()

func test_a_blood_price_settles_the_feud_and_keeps_their_raiders_home()->void:
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	WAR.front(civ_id)["their_dead"]=2
	var food_before:=Hall.player_stock("Food")
	var price:=WAR.blood_price(civ_id)
	assert_float(price).is_equal(2.0*WAR.PRICE_PER_DEAD)
	var said:=WAR.order(civ_id,"war_price")
	assert_str(said).contains("blood price")
	assert_float(Hall.player_stock("Food")).is_equal_approx(food_before-price,0.5)
	assert_int(int(WAR.front(civ_id).level)).is_equal(0)
	assert_bool(WAR.feuding(civ_id)).is_false()
	assert_bool(WAR._truce_binds(civ_id,20)).override_failure_message("a paid blood price does not keep the raiders home").is_true()
	assert_str(_chronicle_about(civ_id)).contains("settled")

## The user, 2026-10-01: "They keep threatening me and then sending me food to
## end the feud, and then threatening me again." Their peace taken, they send
## no tribute demands or tests while the settlement holds, and our own word to
## punish them is set down so our raiders do not start it again.
func test_a_peace_they_paid_for_ends_their_threats_and_our_punishing()->void:
	# Before any feud they could demand tribute (the gate below is the peace's).
	assert_dict(Hall._candidate("tribute_demand",civ_id,{"type":"routine","civ_id":civ_id,"data":{}},RandomNumberGenerator.new(),{},5)).is_not_empty()
	WAR.blood_feud(civ_id,10,"old wrongs")
	WAR.front(civ_id)["stance"]="punish"
	WAR._peace_answered({"civ_id":civ_id,"terms":{"resource":"Food","amount":12.0}},"accept")
	assert_bool(WAR.feuding(civ_id)).is_false()
	assert_str(String(WAR.front(civ_id).get("stance",""))).is_equal("")
	var rng:=RandomNumberGenerator.new()
	for later in [40,300,900]:
		assert_bool(WAR.keeps_peace(civ_id,later)).is_true()
		for asked in ["tribute_demand","test_of_resolve","emboldened_demand","redress_demand"]:
			assert_dict(Hall._candidate(asked,civ_id,{"type":"routine","civ_id":civ_id,"data":{}},rng,{},later)).override_failure_message("%s on day %d" % [asked,later]).is_empty()

func test_a_marriage_between_the_peoples_ends_the_feud()->void:
	WAR.blood_feud(civ_id,10,"old wrongs")
	RIVALS.bond(civ_id,"marriage","the marriage of Wren into your people")
	GameState.elapsed_days=15
	WAR.daily(15)
	assert_bool(WAR.feuding(civ_id)).is_false()
	assert_str(String((WAR.front(civ_id).get("feud_end",{}) as Dictionary).get("why",""))).is_equal("marriage")

func test_a_feud_goes_cold_after_three_quiet_winters()->void:
	WAR.blood_feud(civ_id,10,"old wrongs")
	WAR.front(civ_id)["pending"]={}
	var day:=10+WAR.FEUD_COLD_DAYS+5
	day-=day%WAR.TICK
	GameState.elapsed_days=day
	WAR.daily(day)
	assert_bool(WAR.feuding(civ_id)).is_false()
	assert_str(_chronicle_about(civ_id)).contains("gone cold")

# --------------------------------------------------------------------------
# 2. A killed envoy: a blood feud among small peoples, war among large
# --------------------------------------------------------------------------

func test_killing_a_small_peoples_envoy_starts_a_blood_feud_not_a_war()->void:
	var audience:=_envoy(civ_id)
	var r:=CC.envoy_act(String(audience.id),"kill")
	assert_str(String(r.get("envoy_state",""))).is_equal("dead")
	assert_bool(WAR.feuding(civ_id)).is_true()
	assert_int(int(WAR.front(civ_id).level)).is_greater_equal(2)
	assert_dict(WAR.front(civ_id).pending as Dictionary).override_failure_message("no vengeance raid is coming").is_not_empty()
	assert_str(String(WAR.front(civ_id).get("cause",""))).contains("Qira")
	assert_str(RIVALS.envoy_posture(civ_id)).is_equal("feud")
	assert_str(String(r.get("outcome",""))).contains("blood")
	assert_str(String(r.get("outcome","")).to_lower()).not_contains("preparing for war")
	# A year and more of their ruler's days: no war prepared or opened.
	_run(500)
	assert_bool(bool(_relation(civ_id).get("at_war",false))).is_false()
	assert_bool(RIVALS.character(civ_id).has("war_prep_day")).is_false()
	assert_dict(WAR.front(civ_id).war as Dictionary).is_empty()
	var told:=_chronicle_about(civ_id)
	assert_str(told).contains("blood feud")
	for word in ["sharpens its spears","goes to war","generals take the field","declare"]: assert_bool(word in told).override_failure_message("'%s' in:\n%s" % [word,told]).is_false()
	# Their raiders came for it.
	var kinds:Array=(WAR.state().log as Array).filter(func(e:Dictionary)->bool:return String(e.civ)==civ_id).map(func(e:Dictionary)->String:return String(e.kind))
	assert_bool(kinds.has("raid") or kinds.has("skirmish") or kinds.has("ambush") or kinds.has("held_back")).override_failure_message(str(kinds)).is_true()

func test_a_large_people_still_prepares_and_declares_war_for_its_envoys()->void:
	_make_large(civ_id)
	for i in 2:
		var audience:=_envoy(civ_id)
		CC.envoy_act(String(audience.id),"kill")
	assert_bool(WAR.feuding(civ_id)).override_failure_message("a people of 3,000 feuds instead of preparing war").is_false()
	var c:=RIVALS.character(civ_id)
	c["trait"]="grudge"
	assert_str(RIVALS.envoy_posture(civ_id)).is_equal("war")
	var start:=int(GameState.elapsed_days)
	for day in range(start+1,start+RIVALS.WAR_PREP_MAX+40):
		GameState.elapsed_days=day
		if day%RIVALS.TICK==0: RIVALS._war_preparation(civ_id,RIVALS.character(civ_id),day)
		if bool(_relation(civ_id).get("at_war",false)): break
	assert_bool(bool(_relation(civ_id).get("at_war",false))).override_failure_message("a large people wronged did not go to war").is_true()
	assert_str(_chronicle_about(civ_id)).contains("goes to war")

# --------------------------------------------------------------------------
# 3. No envoys from a people in a hot feud; a peace-seeker after the raids stop
# --------------------------------------------------------------------------

func test_no_boasting_demanding_or_threatening_envoy_during_a_hot_feud()->void:
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	# Their raiders keep coming: a raid scheduled far ahead keeps the feud hot
	# the whole year, and the envoy path alone runs (the fast surrogate).
	WAR.front(civ_id)["pending"]={"day":10000,"cause":"vengeance","ref":"test","stack":1}
	Hall.envoys_only=true
	var arrived:Array=[]
	# A people at peace, offered the same business, as a control: its envoys come.
	var control:=String(CivilizationSystem.civilizations[1].id)
	var came:Array=[]
	var hostile:=["gift_goods","tribute_demand","emboldened_demand","test_of_resolve","redress_demand","debt_call","vengeance_vow","dread_tribute","news_report","accord_offer","trade_offer"]
	for day in range(11,11+365):
		GameState.elapsed_days=day
		probe._refill()
		# Every kind of business a people might send, offered over and over.
		if day%20==0:
			var kinds:=["grudge","relation_cool","dread_test","tension_rise","ambient","relation_warm","their_famine"]
			var kind:=String(kinds[(day/20)%kinds.size()])
			for who in [civ_id,control]:
				Hall._add_occasion({"key":"probe:%s:%s:%d" % [who,kind,day],"type":kind,"civ_id":who,"day":day,"expires":day+60,"crisis":true,"data":{"text":"a test occasion"}})
		for a in Hall.daily(day):
			if String(a.get("civ_id",""))==civ_id: arrived.append(String((a.get("situation",{}) as Dictionary).get("type",a.kind)))
			elif String(a.get("civ_id",""))==control: came.append(String((a.get("situation",{}) as Dictionary).get("type",a.kind)))
		for w in Hall.waiting():
			if String(w.get("origin",""))=="foreign": Hall.resolve(String(w.id),String(Hall.options(String(w.id))[0].id))
		assert_bool(WAR.hot(civ_id,day)).override_failure_message("the feud went cold on day %d" % day).is_true()
	assert_array(came).override_failure_message("the control people sent nobody either: the occasions prove nothing").is_not_empty()
	assert_array(arrived).override_failure_message("envoys came from a people in a hot feud: %s" % str(arrived)).is_empty()
	for type in hostile: assert_array(arrived).not_contains([type])
	# No boast either: their vow is neither learned nor closed while they raid.
	Aims.state().rivals[civ_id]={"civ_id":civ_id,"civ_name":Hall._civ_name(civ_id),"template":"humble","title":"Make the God's People Yield","phrase":"make us yield to them","start_day":0,"deadline":300,"years":1,"status":"active","known":false,"progress":0.0,"leader":"Zerem","baseline":0.0,"target":2.0}
	Aims._rivals(390)
	var vow:Dictionary=Aims.state().rivals[civ_id]
	assert_str(String(vow.status)).is_equal("active")
	assert_bool(bool(vow.known)).is_false()
	Aims._rivals(420)
	assert_int(int(vow.deadline)).is_greater(300)

func test_a_worn_out_people_sends_a_peace_seeker_only_after_the_raids_stop()->void:
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	var f:=WAR.front(civ_id)
	f["pending"]={}; f["their_exh"]=0.6; f["our_dead"]=2; f["their_dead"]=3
	# While blood is fresh, not even a peace-seeker comes.
	assert_str(WAR.envoy_gate(civ_id,20)).is_equal("none")
	Hall._add_occasion({"key":"feud_peace:test:20","type":"feud_peace","civ_id":civ_id,"day":20,"expires":400,"crisis":true,"data":{"text":"they come to end the feud"}})
	assert_dict(Hall._generate_foreign_occasion({"key":"feud_peace:test:20","type":"feud_peace","civ_id":civ_id,"day":20,"crisis":true,"data":{}},20)).is_empty()
	# The raids stopped a while ago: now it may come, with a blood price.
	var day:=10+WAR.PEACE_QUIET_DAYS+5
	GameState.elapsed_days=day
	assert_str(WAR.envoy_gate(civ_id,day)).is_equal("peace")
	var audience:=Hall._generate_foreign_occasion({"key":"feud_peace:test:%d" % day,"type":"feud_peace","civ_id":civ_id,"day":day,"crisis":true,"data":{}},day)
	assert_dict(audience).is_not_empty()
	assert_str(String((audience.situation as Dictionary).type)).is_equal("feud_peace")
	assert_str(String((audience.situation as Dictionary).summary)).contains("end the feud")
	# No boasting business rides along: a demand is still refused at the gate.
	var demand:=Hall._generate_foreign_occasion({"key":"grudge:test:%d" % day,"type":"grudge","civ_id":civ_id,"day":day,"crisis":true,"data":{}},day)
	var demanded:=String((demand.get("situation",{}) as Dictionary).get("type","feud_peace"))
	assert_bool(demanded in ["feud_peace","dread_tribute","captive_plea","town_return","people_plea"]).override_failure_message(demanded).is_true()
	# Taken: the feud is settled and their raiders stay home.
	Hall._enqueue(audience,day,true)
	var r:=Hall.resolve(String(audience.id),"accept")
	assert_bool(bool(r.get("ok",false))).override_failure_message(str(r)).is_true()
	assert_str(String(r.outcome)).contains("feud is settled")
	assert_bool(WAR.feuding(civ_id)).is_false()
	assert_bool(WAR._truce_binds(civ_id,day+30)).is_true()

func test_killing_the_peace_seeker_makes_the_feud_worse()->void:
	WAR.blood_feud(civ_id,10,"old wrongs")
	var f:=WAR.front(civ_id)
	f["pending"]={}; f["their_exh"]=0.6
	var day:=10+WAR.PEACE_QUIET_DAYS+5
	GameState.elapsed_days=day
	var audience:=Hall._generate_foreign_occasion({"key":"feud_peace:kill:%d" % day,"type":"feud_peace","civ_id":civ_id,"day":day,"crisis":true,"data":{}},day)
	assert_dict(audience).is_not_empty()
	Hall._enqueue(audience,day,true)
	var r:=CC.envoy_act(String(audience.id),"kill")
	assert_str(String(r.get("envoy_state",""))).is_equal("dead")
	assert_int(int(WAR.front(civ_id).last_harm)).is_equal(day)
	assert_bool(WAR.hot(civ_id,day)).is_true()
	assert_dict(WAR.front(civ_id).pending as Dictionary).is_not_empty()
	assert_str(WAR.envoy_gate(civ_id,day)).is_equal("none")

func test_a_feuding_people_sends_neither_tribute_nor_tests_from_dread()->void:
	WAR.blood_feud(civ_id,10,"old wrongs")
	preload("res://scripts/divine_regard.gd").add_civ_dread(civ_id,0.4)
	preload("res://scripts/divine_regard.gd").add_civ_dread(civ_id,0.4)
	var before:=(Hall.state().occasions as Array).size()
	Lives._rivals(20)
	for o in Hall.state().occasions: assert_str(String((o as Dictionary).get("civ_id",""))).is_not_equal(civ_id)
	assert_str(_chronicle_about(civ_id)).not_contains("send tribute")

# --------------------------------------------------------------------------
# 4. An older save with a small people "at war" loads as a feud
# --------------------------------------------------------------------------

## The user's own situation, as an older save kept it: the Neyali's envoy
## killed, the Neyali "at war" with us (their ruler opened it), their general
## taken up by ours, one of our bands having burned their stores, their home
## found by that raid, a boast of theirs and a demand still waiting to come.
func _old_war_save()->void:
	var civ:=_civ(civ_id)
	civ["name"]="Neyali"
	var day:=int(GameState.elapsed_days)
	RIVALS.character(civ_id)
	RIVALS.grudge(civ_id,"how you slew our envoy Qira in your hall",1.0,"slain_envoy:aud_1")
	var relation:Dictionary=civ.player_relation
	relation["at_war"]=true; relation["treaty"]="war"; relation["stance"]="hostile"; relation["war_goal"]="defend"
	relation["war_started_day"]=day; relation["war_id"]=CivilizationSystem._start_war("player",civ_id,"defend","",day,"Vengeance for how you slew their envoy Qira in your hall")
	relation["trade"]=0.0
	var f:=WAR.front(civ_id)
	f["level"]=3
	f["war"]={"start":day,"war_id":String(relation.war_id),"cause":"the war","our_dead":3,"their_dead":5,"our_exh":0.2,"their_exh":0.3,"score":1,
		"op":{},"objective":"war_burn","queued":"","next_enemy":day+40,"filed_day":day,"chief_held":false,"ally":"","terms":{"resource":"Food","amount":60.0},"terms_day":day,"ops":1,"last_fight":day}
	WAR._log(civ_id,"op_burn","Hask's band reached the Neyali's stores by night and burned them.",{"won":true,"our_dead":1,"their_dead":2})
	WAR._log(civ_id,"enemy_attack","14 Neyali fighters came at the planted fields and were thrown back.",{"won":false})
	WAR._find_home(civ_id,day,"a band that went there","struck:"+civ_id)
	WAR._file(civ_id,"war","War with Neyali has begun. The war leader asks what you want done.",day)
	# Waiting to come: a demand for redress and a test of the god's resolve.
	Hall._add_occasion({"key":"grudge:%s:%d" % [civ_id,day],"type":"grudge","civ_id":civ_id,"day":day,"expires":day+300,"data":{"text":"an old grievance"}})
	Hall._add_occasion({"key":"dread_test:%s:%d" % [civ_id,day],"type":"dread_test","civ_id":civ_id,"day":day,"expires":day+90,"crisis":true,"data":{"text":"a test"}})
	RIVALS.character(civ_id)["war_prep_day"]=day-200

func test_an_older_save_with_a_small_people_at_war_loads_as_a_blood_feud()->void:
	_old_war_save()
	var saved:=SaveSystem.save_game(slot)
	assert_bool(saved.has("error")).override_failure_message(str(saved)).is_false()
	var loaded:=SaveSystem.load_game(slot)
	assert_bool(loaded.has("error")).override_failure_message(str(loaded)).is_false()
	var relation:=_relation(civ_id)
	# No war: no fronts, no war goal, no terms, no campaign.
	assert_bool(bool(relation.get("at_war",false))).is_false()
	assert_str(String(relation.get("treaty",""))).is_not_equal("war")
	assert_array(CivilizationSystem.military_fronts_snapshot().fronts as Array).is_empty()
	for record in CivilizationSystem.war_history:
		if String(record.get("id",""))==String(relation.get("war_id","")): assert_str(String(record.status)).is_equal("ended")
	var f:=WAR.front(civ_id)
	assert_dict(f.war as Dictionary).is_empty()
	for incident in CivilizationSystem.pending_player_incidents: assert_str(String(incident.get("source_civ_id",""))).is_not_equal(civ_id)
	# A blood feud: the dead of the war, the raids and the grudges are kept.
	assert_bool(WAR.feuding(civ_id)).is_true()
	assert_bool(WAR.hot(civ_id)).is_true()
	assert_int(int(f.our_dead)).is_equal(3)
	assert_int(int(f.their_dead)).is_equal(5)
	assert_str(String(f.cause)).contains("killing of their envoy Qira")
	assert_int(int(RIVALS.envoy_wrongs(civ_id).slain)).is_equal(1)
	var kinds:Array=(WAR.state().log as Array).filter(func(e:Dictionary)->bool:return String(e.civ)==civ_id).map(func(e:Dictionary)->String:return String(e.kind))
	assert_array(kinds).contains(["op_burn","enemy_attack","war_to_feud"])
	# Their home, found by the band that burned their stores, stays on the map.
	assert_bool(WAR.home_known(civ_id)).is_true()
	assert_bool((relation.get("home_position",{}) as Dictionary).has("x")).is_true()
	# No boasting envoy is waiting to come, and none can.
	for o in Hall.state().occasions: assert_str(String((o as Dictionary).get("civ_id",""))).is_not_equal(civ_id)
	assert_bool(RIVALS.character(civ_id).has("war_prep_day")).is_false()
	assert_str(WAR.envoy_gate(civ_id)).is_equal("none")
	# The war leader's matter is the feud: its own acts, no terms.
	var matter:={}
	for m in Hall.matters():
		if String(m.get("situation_type",""))=="war_campaign": matter=m
	assert_dict(matter).is_not_empty()
	var ids:Array=WAR.options(matter.audience).map(func(o:Dictionary)->String:return String(o.get("id","")))
	assert_array(ids).contains(["war_burn","war_guard","war_price"])
	assert_array(ids).not_contains(["war_pay","war_general","war_rest"])
	# The feud goes on: their raiders are coming.
	assert_dict(f.pending as Dictionary).is_not_empty()
	# And it round-trips as it stands.
	var view:=WAR.feud_view(civ_id)
	var again:=SaveSystem.save_game(slot)
	assert_bool(again.has("error")).is_false()
	assert_bool(SaveSystem.load_game(slot).has("error")).is_false()
	assert_dict(WAR.feud_view(civ_id)).is_equal(view)
	assert_bool(bool(_relation(civ_id).get("at_war",false))).is_false()

## The same save with one of our bands still on the road back from their
## stores: their war is a feud at once (no terms, no general's campaign, no
## envoy), and the engine's own flag goes, quietly, when the band is home.
func test_an_older_war_with_our_band_still_out_is_a_feud_at_once()->void:
	_old_war_save()
	var mc:=WorldSimulation.military
	mc.field_armies.append({"army_id":990,"name":"Hask's band","status":"moving","court_order":{"civ_id":civ_id,"kind":"raid"},"troops":12})
	var day:=int(GameState.elapsed_days)
	assert_array(WAR.reconcile(day)).contains([civ_id])
	var f:=WAR.front(civ_id)
	assert_dict(f.war as Dictionary).is_empty()
	assert_bool(WAR.feuding(civ_id)).is_true()
	assert_bool(bool(_relation(civ_id).get("at_war",false))).override_failure_message("the band's own fight lost its flag while it was out").is_true()
	assert_str(WAR.envoy_gate(civ_id)).is_equal("none")
	for o in Hall.state().occasions: assert_str(String((o as Dictionary).get("civ_id",""))).is_not_equal(civ_id)
	mc.field_armies.pop_back()
	var text:=Facts.text(Facts.sheet(["common","war"]))
	assert_str(text).contains("In a feud with: Neyali")
	assert_str(text).contains("At war with: nobody")
	# The band is home: the flag goes, and the feud goes on without a new word.
	var told:=(GameState.chronicle.get("entries",[]) as Array).size()
	assert_array(WAR.reconcile(day+5)).contains([civ_id])
	assert_bool(bool(_relation(civ_id).get("at_war",false))).is_false()
	assert_int((GameState.chronicle.get("entries",[]) as Array).size()).is_equal(told)
	assert_bool(WAR.feuding(civ_id)).is_true()
	assert_int(int(f.our_dead)).is_equal(3)
	assert_int(int(f.their_dead)).is_equal(5)

# --------------------------------------------------------------------------
# The line holds for a war already declared
# --------------------------------------------------------------------------

## A war declared between peoples organised for war is fought out through a
## lost battle or a hard winter; a people broken far below the line can no
## longer feed a host, and its war is a feud. A people that never declared is
## read by the line itself.
func test_a_declared_war_holds_through_a_hard_winter()->void:
	_make_large(civ_id)
	assert_bool(WAR.declare(civ_id,20,"the stolen herds")).is_true()
	assert_bool(Scale.declared("player",civ_id)).is_true()
	_set_pop(_civ(civ_id),Scale.WAR_POP*0.9)
	assert_bool(Scale.formal(civ_id)).override_failure_message("a declared war became a feud over a hard winter").is_true()
	assert_array(WAR.reconcile(30)).is_empty()
	assert_bool(bool(_relation(civ_id).get("at_war",false))).is_true()
	assert_bool(WAR.has_campaign(civ_id)).is_true()
	var other:=String(CivilizationSystem.civilizations[1].id)
	_set_pop(_civ(other),Scale.WAR_POP*0.9)
	assert_bool(Scale.formal(other)).override_failure_message("a people below the line that never declared is at war").is_false()
	_set_pop(_civ(civ_id),Scale.WAR_POP*0.5)
	assert_bool(Scale.formal(civ_id)).is_false()
	assert_array(WAR.reconcile(40)).contains([civ_id])
	assert_bool(bool(_relation(civ_id).get("at_war",false))).is_false()
	assert_bool(WAR.feuding(civ_id)).is_true()

# --------------------------------------------------------------------------
# 5. The court: "are we at war with them?" -> the feud, in plain words
# --------------------------------------------------------------------------

func test_the_court_calls_a_feud_a_feud()->void:
	_civ(civ_id)["name"]="Neyali"
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	WAR.front(civ_id)["our_dead"]=2; WAR.front(civ_id)["their_dead"]=1; WAR.front(civ_id)["raids"]=3
	var sheet:=Facts.sheet(["common","war"])
	var text:=Facts.text(sheet)
	assert_str(text).contains("In a feud with: Neyali")
	assert_str(text).contains("At war with: nobody")
	var said:=Answers.answer(sheet,"Are we at war with the Neyali?")
	assert_str(said).contains("feud")
	assert_str(said).contains("Neyali")
	assert_str(said.to_lower()).not_contains("we are at war with the neyali")
	var anyone:=Answers.answer(sheet,"Are we at war with anyone?")
	assert_str(anyone).contains("nobody")
	assert_str(anyone).contains("feud with the Neyali")

# --------------------------------------------------------------------------
# 6. Two other small peoples feud too; large ones still declare
# --------------------------------------------------------------------------

func test_two_small_peoples_feud_and_two_large_peoples_carry_a_declaration()->void:
	var a:=CivilizationSystem.civilizations[1]; var b:=CivilizationSystem.civilizations[2]
	var day:=100
	CivilizationSystem.start_rival_feud(1,2,day,"a quarrel on the border")
	var rel:Dictionary=(a.relations as Dictionary)[String(b.id)]
	assert_bool(bool(rel.get("at_war",false))).is_false()
	assert_bool(CivilizationSystem.rival_feud_hot(rel,day+10)).is_true()
	assert_dict((b.relations as Dictionary)[String(a.id)]).is_equal(rel)
	# An older save's war between two small peoples becomes their feud.
	var old:=rel.duplicate(true)
	old["at_war"]=true; old["treaty"]="war"; old["war_started_day"]=50
	old["war_id"]=CivilizationSystem._start_war(String(a.id),String(b.id),"limited","",50,"old")
	CivilizationSystem._set_pair_relation(1,2,old)
	CivilizationSystem.reconcile_rival_feuds(day)
	rel=(CivilizationSystem.civilizations[1].relations as Dictionary)[String(b.id)]
	assert_bool(bool(rel.get("at_war",false))).is_false()
	assert_bool(CivilizationSystem.rival_feud_hot(rel,day)).is_true()
	# A carried "war" between small peoples arrives as a feud.
	var carried:=rel.duplicate(true)
	carried["pending_message"]="war"; carried["pending_message_sent_day"]=day; carried["pending_message_due_day"]=day
	CivilizationSystem._set_pair_relation(1,2,carried)
	CivilizationSystem._process_intercivilization_relations(day)
	assert_bool(bool(((CivilizationSystem.civilizations[1].relations as Dictionary)[String(b.id)] as Dictionary).get("at_war",false))).is_false()
	# Large peoples keep the declared war.
	for civ in [CivilizationSystem.civilizations[1],CivilizationSystem.civilizations[2]]:
		civ["population"]=4000.0
		civ["cohorts"]=CivilizationSystem._scaled_cohorts(civ.get("cohorts",{}),4000.0)
	var big:=((CivilizationSystem.civilizations[1].relations as Dictionary)[String(b.id)] as Dictionary).duplicate(true)
	for key in ["feud_since","feud_last","feud_raids","feud_dead","feud_cause"]: big.erase(key)
	big["pending_message"]="war"; big["pending_message_sent_day"]=day; big["pending_message_due_day"]=day
	CivilizationSystem._set_pair_relation(1,2,big)
	CivilizationSystem._process_intercivilization_relations(day)
	assert_bool(bool(((CivilizationSystem.civilizations[1].relations as Dictionary)[String(b.id)] as Dictionary).get("at_war",false))).is_true()

func test_a_rival_feud_raids_a_little_and_goes_cold()->void:
	var a:=CivilizationSystem.civilizations[1]; var b:=CivilizationSystem.civilizations[2]
	var pop_before:=float(a.population)+float(b.population)
	CivilizationSystem.start_rival_feud(1,2,0,"a quarrel on the border")
	for day in range(1,5*365):
		var rel:Dictionary=(CivilizationSystem.civilizations[1].relations as Dictionary)[String(b.id)]
		if int(rel.get("feud_since",-1))<0: break
		CivilizationSystem._rival_feud_day(CivilizationSystem.civilizations[1],CivilizationSystem.civilizations[2],rel,day)
		CivilizationSystem._set_pair_relation(1,2,rel)
	var rel2:Dictionary=(CivilizationSystem.civilizations[1].relations as Dictionary)[String(b.id)]
	assert_int(int(rel2.get("feud_since",-1))).override_failure_message("the feud never went cold").is_equal(-1)
	var lost:=pop_before-(float(CivilizationSystem.civilizations[1].population)+float(CivilizationSystem.civilizations[2].population))
	# A feud between bands kills a few, never a war's toll (EPOCHAL_SHIFTS s3.4).
	assert_float(lost).is_less(pop_before*0.07)
	assert_bool(bool(rel2.get("at_war",false))).is_false()

# --------------------------------------------------------------------------
# 7. A people broken past feuding (Oruq, year 187: its last town burned with
# one of them left, and the map still read "Feud with Oruq")
# --------------------------------------------------------------------------

## Every town of theirs burned or held by us, and only `living` of them left.
func _break(id:String,living:float)->void:
	var civ:=_civ(id)
	_set_pop(civ,living)
	for region in civ.strategic_regions:
		if bool(region.get("settlement_founded",true)): region["controller"]="player"

func test_a_people_with_no_town_and_a_handful_left_ends_its_feud_once()->void:
	_civ(civ_id)["name"]="Oruq"
	WAR.blood_feud(civ_id,10,"our attack on them")
	assert_bool(WAR.feuding(civ_id)).is_true()
	assert_bool((WAR.front(civ_id).pending as Dictionary).is_empty()).is_false()
	_break(civ_id,1.3)
	# Read at once: no feud, nothing hot, survivors.
	assert_bool(WAR.broken(civ_id)).is_true()
	assert_bool(WAR.feuding(civ_id)).is_false()
	assert_bool(WAR.hot(civ_id)).is_false()
	assert_int(int(WAR.survivors(civ_id).living)).is_equal(1)
	assert_array(WAR.feuds().map(func(v:Dictionary)->String:return String(v.civ_id))).not_contains([civ_id])
	# The tick ends it, told once; the raiders scheduled never come.
	var raids_before:=int(WAR.front(civ_id).get("raids",0))
	_run(200)
	var f:=WAR.front(civ_id)
	assert_int(int(f.level)).is_equal(0)
	assert_bool((f.pending as Dictionary).is_empty()).is_true()
	assert_str(String((f.feud_end as Dictionary).why)).is_equal("broken")
	assert_int(int(f.get("raids",0))).is_equal(raids_before)
	var told:=_chronicle_about(civ_id)
	assert_str(told).contains("the feud with oruq is over")
	assert_str(told).contains("only one of them lives, in the hills")
	assert_int(told.count("is over:")).is_equal(1)
	# An old grudge sends nobody either: no chance, and a raid already
	# scheduled stands down when its day comes.
	assert_float(WAR.grudge_raid_chance(civ_id)).is_equal(0.0)
	var day:=int(GameState.elapsed_days)
	WAR._schedule(civ_id,day+1,"grudge","grudge")
	_run(10)
	assert_int(int(WAR.front(civ_id).get("raids",0))).is_equal(raids_before)
	assert_bool((WAR.front(civ_id).pending as Dictionary).is_empty()).is_true()
	assert_int(int(WAR.front(civ_id).level)).is_equal(0)

func test_a_people_with_many_left_but_no_town_keeps_its_feud()->void:
	# Burned out but forty strong in the hills: they can still raid.
	WAR.blood_feud(civ_id,10,"our attack on them")
	_break(civ_id,40.0)
	assert_bool(WAR.broken(civ_id)).is_false()
	assert_bool(WAR.feuding(civ_id)).is_true()

func test_the_map_and_the_court_tell_survivors_not_a_feud()->void:
	_civ(civ_id)["name"]="Oruq"
	WAR.blood_feud(civ_id,10,"our attack on them")
	_break(civ_id,2.0)
	var left:=WAR.survivors(civ_id)
	assert_str(Marks.remnant_tag(left)).is_equal("Oruq survivors in the hills")
	assert_str(Marks.remnant_details(left)).contains("Two of them live in the hills").contains("too few to raid anyone")
	# The overlay draws the survivors, never "Feud with Oruq".
	GameState.settlement_site_committed=true
	var overlay:Control=auto_free(Overlay.new())
	var tags:Array=overlay.collect().map(func(m:Dictionary)->String:return String(m.get("tag","")))
	assert_array(tags).contains(["Oruq survivors in the hills"])
	assert_array(tags).not_contains(["Feud with Oruq"])
	# The court: neither at peace nor at feud, but broken, with the numbers.
	var text:=Facts.text(Facts.sheet(["common","war"]))
	assert_str(text).contains("Broken, with no town left: Oruq (")
	assert_str(text).contains("2 of them live, in the hills")
	assert_str(text).not_contains("In a feud with: Oruq")
	# None of them left: no label at all.
	_civ(civ_id)["alive"]=false
	assert_str(Marks.remnant_tag(WAR.survivors(civ_id))).is_equal("")

func test_a_rival_feud_ends_when_one_people_is_down_to_a_handful()->void:
	var was:=WorldSimulation.enabled
	WorldSimulation.enabled=true
	var b:=CivilizationSystem.civilizations[2]
	CivilizationSystem.start_rival_feud(1,2,0,"a quarrel on the border")
	assert_int(int(((CivilizationSystem.civilizations[1].relations as Dictionary)[String(b.id)] as Dictionary).get("feud_since",-1))).is_greater_equal(0)
	_set_pop(CivilizationSystem.civilizations[2],3.0)
	preload("res://scripts/rival_feuds.gd").tick(WAR.TICK,WAR.TICK)
	WorldSimulation.enabled=was
	var rel:Dictionary=(CivilizationSystem.civilizations[1].relations as Dictionary)[String(b.id)]
	assert_int(int(rel.get("feud_since",-1))).is_equal(-1)
	assert_int(int(rel.get("feud_ended_day",-1))).is_equal(WAR.TICK)
