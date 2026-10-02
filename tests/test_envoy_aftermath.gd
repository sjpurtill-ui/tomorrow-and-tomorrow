extends GdUnitTestSuite
## A beaten people's envoys (envoy_aftermath.gd). The user's live play: we
## held Tsaren, the Esurai's chief town, and an Esurai envoy arrived
## demanding 30 fiber plants as tribute, citing an old refused demand. A
## people that lost its chief town to us sues, pleads, ransoms or vows
## vengeance; it never demands tribute. A people with no town left sends
## nobody. The envoy says who leads them now, and from where.

const Hall:=preload("res://scripts/audience_hall.gd")
const ER:=preload("res://scripts/envoy_requests.gd")
const Aftermath:=preload("res://scripts/envoy_aftermath.gd")
const Fate:=preload("res://scripts/town_fate.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const CivReport:=preload("res://scripts/hud/content/dock_detail_civ_report.gd")

var civ_id:=""
var city_id:=""
var other_id:=""
var _processing:Dictionary={}

func _land(_p:Vector2)->bool:
	return true

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	for res in ["Timber","Stone","Clay","Fiber Plants"]: GameState.resource_stockpiles[res]=300.0
	GameState.elapsed_days=88*365
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=true; relation.contact_level=2; relation.home_location_known=true; relation.met_day=0
	relation.opinion=-0.5; relation.border_tension=0.8
	# Tsaren is their chief town; Stonefield their other town; the rest empty land.
	var ci:=CivilizationSystem._frontline_region_index(civ)
	for i in (civ.strategic_regions as Array).size():
		var region:Dictionary=civ.strategic_regions[i]
		region["settlement_founded"]=false; region["population"]=0.0; region["role"]="frontier"
	var tsaren:Dictionary=civ.strategic_regions[ci]
	tsaren.name="Tsaren"; tsaren.population=300.0; tsaren.role="capital"; tsaren.settlement_founded=true
	city_id=String(tsaren.id)
	var oi:=(ci+1)%(civ.strategic_regions as Array).size()
	var stonefield:Dictionary=civ.strategic_regions[oi]
	stonefield.name="Stonefield"; stonefield.population=60.0; stonefield.settlement_founded=true
	other_id=String(stonefield.id)
	civ.population=360.0
	for rid in [city_id,other_id]:
		CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",rid,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	var home:=CivilizationSystem.player_world_origin
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":home.x-20.0,"z":home.y+8.0}
	CivilizationSystem.city_intelligence.records.player[other_id]["position"]={"x":home.x-30.0,"z":home.y+12.0}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	# A hard, assertive ruler: the kind who would demand tribute of anyone else.
	var leader:=ForeignDiplomacy.leader(civ_id)
	var p:Dictionary=leader.get("personality",{})
	p["assertiveness"]=0.9; p["risk_tolerance"]=0.7; p["empathy"]=0.3
	leader["personality"]=p
	# Their stores, for ransoms and prices.
	for res in ["Food","Timber"]: Hall.EXCHANGE.receive(civ_id,res,400.0)

func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	Route.clear_cache()
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

func _take_tsaren()->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+18
	MilitaryCampaign.raise_recruits(18)
	MilitaryCampaign.start_training("levy","improvised",18)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	MilitaryCampaign.create_field_army(18,"LEVY BAND 1")
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army["supply_level"]=1.0; army["readiness"]=1.0
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	var factor:=maxf(.05,float(army.get("supply_level",1.0))*(.5+.5*clampf(float(army.get("readiness",.45))*.9,.15,1.0)))
	var garrison:=MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],floorf(17.0*factor),int(army.army_id))
	assert_int(int(garrison.get("troops",0))).is_greater(0)

func _occasion(type:String,data:Dictionary={})->Dictionary:
	return {"type":type,"key":"test:%s" % type,"civ_id":civ_id,"day":int(GameState.elapsed_days),"data":data}

func _types(occasion:Dictionary)->Array:
	var out:Array=[]
	var rng:=RandomNumberGenerator.new(); rng.seed=7
	for c:Dictionary in Hall._foreign_candidates(civ_id,occasion,rng,{},int(GameState.elapsed_days)):
		if float(c.get("w",0.0))>0.0: out.append(String((c.situation as Dictionary).get("type","")))
	return out


func test_no_tribute_demand_from_a_people_whose_chief_town_we_hold()->void:
	var refused:={"previous":{"situation":"tribute_demand","option":"defy","kind":"threat","resource":"Food"}}
	# Before the war went our way, this ruler's refused demand comes back as a test of resolve.
	var before:=_types(_occasion("sequel",refused))+_types(_occasion("tension_rise"))
	assert_bool(before.any(func(t:String)->bool: return t in Aftermath.DEMANDS)).override_failure_message(str(before)).is_true()
	_take_tsaren()
	var st:=Aftermath.standing(civ_id)
	assert_bool(bool(st.defeated)).is_true()
	assert_bool(bool(st.capital_lost)).is_true()
	assert_str(String(st.seat)).is_equal("Stonefield")
	for occasion in [_occasion("sequel",refused),_occasion("tension_rise"),_occasion("relation_cool"),_occasion("dread_test"),_occasion("grudge"),_occasion("ambient")]:
		var types:=_types(occasion)
		for t in types: assert_bool(t in Aftermath.DEMANDS).override_failure_message("%s -> %s" % [String(occasion.type),str(types)]).is_false()
		assert_array(types).override_failure_message(String(occasion.type)).is_not_empty()
	# What they come about instead: peace, the town, a plea, or defiance.
	var after:=_types(_occasion("sequel",refused))
	assert_bool(after.any(func(t:String)->bool: return t in ["peace_feeler","town_return","people_plea","vengeance_vow","dread_tribute"])).override_failure_message(str(after)).is_true()
	# Forced or not, a demand is never raised.
	var rng:=RandomNumberGenerator.new()
	for t in ["tribute_demand","test_of_resolve","emboldened_demand"]:
		assert_dict(Hall._candidate(t,civ_id,_occasion("debug"),rng,{},int(GameState.elapsed_days))).is_empty()


func test_the_envoy_says_tsaren_fell_and_speaks_for_the_ruler_at_stonefield()->void:
	_take_tsaren()
	var audience:=Hall.debug_situation("town_return",civ_id)
	assert_dict(audience).is_not_empty()
	var who:=String(ForeignDiplomacy.leader(civ_id).get("name","")).get_slice(" ",0)
	assert_str(String(audience.speaker.title)).contains("who leads the Esurai from Stonefield since Tsaren fell")
	var s:Dictionary=audience.situation
	assert_str(String(s.summary)).starts_with("Tsaren is in your hands, and %s leads the Esurai from Stonefield now." % who)
	assert_str(String(s.headline)).is_equal("comes to ask for Tsaren back")
	var lines:=ER.open_lines(audience)
	assert_str(String(lines[0])).starts_with("Tsaren is in your hands")
	assert_str(String(lines[0])).contains("asks what it would take to have Tsaren back")
	for line in lines: assert_str(String(line).to_lower()).not_contains("tribute")
	# Answers are real: the garrison marches home and Tsaren is theirs again.
	# (Without a simulated ledger for them, they have no price to offer.)
	var labels:Array=[]
	for o:Dictionary in Hall.options(String(audience.id)): labels.append(String(o.label))
	assert_bool("Give it back freely" in labels and "Keep it" in labels).override_failure_message(str(labels)).is_true()
	var r:=Hall.resolve(String(audience.id),"gift")
	assert_bool(r.has("error")).override_failure_message(str(r)).is_false()
	assert_str(String(CivilizationSystem.region_snapshot(civ_id,city_id).get("controller",""))).is_equal(civ_id)
	assert_dict(MilitaryCampaign.occupation_force_for_region(civ_id,city_id)).is_empty()
	assert_bool(Aftermath.defeated(civ_id)).is_false()


func test_a_people_with_no_town_left_sends_no_envoys()->void:
	_take_tsaren()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.strategic_regions[CivilizationSystem._region_index(civ,other_id)]["population"]=0.0
	assert_bool(Aftermath.silenced(civ_id)).is_true()
	for type in ["tension_rise","sequel","peace_possible","ambient","grudge"]:
		assert_dict(Hall._generate_foreign_occasion(_occasion(type),int(GameState.elapsed_days))).override_failure_message(type).is_empty()
	for kind in ["threat","proposal","request","gift","news"]:
		assert_dict(Hall._generate_foreign(civ_id,int(GameState.elapsed_days),kind)).override_failure_message(kind).is_empty()
	# A people we never fought is not silenced by having small towns.
	assert_bool(Aftermath.silenced(String(CivilizationSystem.civilizations[1].id))).is_false()


func test_they_ask_for_the_captives_on_the_road_and_can_have_them_back()->void:
	_take_tsaren()
	var done:=Fate.apply(civ_id,city_id,Fate.fate_words("kill all the males and bring all the females back to seanstone","seanstone"))
	assert_bool(done.has("error")).override_failure_message(str(done)).is_false()
	var road:=int(done.captives)
	assert_int(road).is_greater(0)
	var st:=Aftermath.standing(civ_id)
	assert_int(int(st.captives_road)).is_equal(road)
	assert_bool(Aftermath.mix(civ_id).has("captive_plea")).is_true()
	var audience:=Hall.debug_situation("captive_plea",civ_id)
	assert_dict(audience).is_not_empty()
	var lines:=ER.open_lines(audience)
	assert_str(String(lines[0])).contains("You took %d of our people from Tsaren" % road)
	var population:=float(CivilizationSystem.civilizations[0].population)
	var r:=Hall.resolve(String(audience.id),"gift")
	assert_bool(r.has("error")).override_failure_message(str(r)).is_false()
	assert_array(MilitaryCampaign.occupation_transfers.data.transfers as Array).is_empty()
	assert_float(float(CivilizationSystem.civilizations[0].population)).is_equal_approx(population+road,0.01)


## The user, 2026-10-01: "They also need to stop asking for their fucking
## people back." The town, its people under our garrison and the captives are
## one plea a conquest: asked once and refused, none of the three comes back.
func test_a_beaten_people_asks_for_its_own_back_once_a_conquest()->void:
	_take_tsaren()
	var done:=Fate.apply(civ_id,city_id,Fate.fate_words("kill all the males and bring all the females back to seanstone","seanstone"))
	assert_bool(done.has("error")).override_failure_message(str(done)).is_false()
	var rng:=RandomNumberGenerator.new()
	var day:=int(GameState.elapsed_days)
	var first:=Aftermath.candidate("captive_plea",civ_id,{},rng,{},day)
	assert_str(String((first.situation as Dictionary).ask)).starts_with(Aftermath.GIVE_BACK)
	var audience:=Hall.debug_situation("captive_plea",civ_id)
	assert_dict(audience).is_not_empty()
	var r:=Hall.resolve(String(audience.id),"refuse")
	assert_bool(r.has("error")).override_failure_message(str(r)).is_false()
	for later in [day+200,day+400,day+1500]:
		for asked in ["captive_plea","people_plea","town_return"]:
			assert_dict(Aftermath.candidate(asked,civ_id,{},rng,{},later)).override_failure_message("%s came back on day %d" % [asked,later]).is_empty()


func test_the_record_shows_which_towns_they_still_hold()->void:
	_take_tsaren()
	var block:=CivReport.towns_block(civ_id)
	assert_dict(block).is_not_empty()
	var rows:={}
	for item:Dictionary in block.items: rows[String(item.name)]=item
	assert_str(String(rows["Tsaren"].value)).is_equal("Ours: our garrison holds it")
	assert_str(String(rows["Tsaren"].detail)).is_equal("Their chief town.")
	assert_str(String(rows["Stonefield"].value)).is_equal("Theirs")
	assert_str(String(rows["Where they live now"].detail)).is_equal("Esurai still holds Stonefield.")



## A vow of vengeance is sworn once by a ruler for what was lost: not every
## year their envoys come ("WAY TOO many of these"). A new ruler may swear it
## again; the vow leans them toward coming with everything (world_answer.gd).
func test_a_ruler_swears_vengeance_once_not_every_year()->void:
	_take_tsaren()
	var rng:=RandomNumberGenerator.new()
	var day:=int(GameState.elapsed_days)
	var vow:=Aftermath.candidate("vengeance_vow",civ_id,{},rng,{},day)
	assert_dict(vow).is_not_empty()
	assert_str(String((vow.situation as Dictionary).ask)).starts_with(Aftermath.VOW)
	var audience:=Hall.debug_situation("vengeance_vow",civ_id)
	assert_dict(audience).is_not_empty()
	assert_bool(Aftermath.sworn(civ_id)).is_true()
	assert_bool(Aftermath.mix(civ_id).has("vengeance_vow")).is_false()
	for later in [day+365,day+730,day+3650]:
		assert_dict(Aftermath.candidate("vengeance_vow",civ_id,{},rng,{},later)).override_failure_message("a second vow on day %d" % later).is_empty()
	# Sworn to our face, they come with everything sooner.
	var answer:=preload("res://scripts/world_answer.gd")
	assert_bool(bool(answer.reading(civ_id).sworn_vengeance)).is_true()
	# A new ruler may swear it again.
	(preload("res://scripts/rival_rulers.gd").character(civ_id) as Dictionary)["gen"]=int(preload("res://scripts/rival_rulers.gd").character(civ_id).get("gen",0))+1
	assert_bool(Aftermath.sworn(civ_id)).is_false()
