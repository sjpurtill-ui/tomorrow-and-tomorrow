extends GdUnitTestSuite
## The user's live play (September 27): the men of Tsaren (a town we hold,
## 17 under Rovik) were put to the sword; 15 died and the court said about
## ten got away and asked "Should we chase them?". "Yeah, go ahead and chase
## them": the court said 16 went after them, the chase never reported back,
## a "Held by us · 16" card sat far north of Tsaren while the town's badge
## counted the same 16, and "come back" moved nobody.
##
## Now: the escape is counted and offered; a chase is a real detachment out
## of the garrison (the garrison drops by as many), which chases for a day
## or two, reports once, walks back and rejoins; the map shows the garrison
## on the town and the detachment as its own band; recall reaches bands,
## detachments and (after asking once) garrisons.

const Ledger:=preload("res://scripts/town_ledger.gd")
const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const Fate:=preload("res://scripts/town_fate.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Ownership:=preload("res://scripts/map_ownership.gd")
const Leaders:=preload("res://scripts/leader_commands.gd")

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var refuge_id:=""
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
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=88*365
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=true; relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	# The user's town: seventeen could kill fifteen men who did not get away.
	region["population"]=90.0
	city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	home=CivilizationSystem.player_world_origin
	# Our chart has Tsaren here; the world's own site for it lies elsewhere
	# (the user's garrison card sat at that other point, far north).
	city=home+Vector2(-20.0,8.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))

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

## Tsaren taken, 17 of Rovik's band holding it, one fighter still with Rovik.
func _captured_tsaren()->Dictionary:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+18
	MilitaryCampaign.raise_recruits(18)
	MilitaryCampaign.start_training("levy","improvised",18)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	MilitaryCampaign.create_field_army(18,"LEVY BAND 1")
	# Rovik leads it: the ruler put the band under him, as the War screen and
	# the Military Leaders screen do (leader_commands.gd). A new band serves
	# under the war leader at home until then.
	var general:=Leaders.commission_general(MilitaryCampaign)
	assert_bool(general.has("error")).override_failure_message(str(general)).is_false()
	var put:=Leaders.assign(MilitaryCampaign,int(MilitaryCampaign.field_armies[0].army_id),String(general.get("figure_id","")))
	assert_bool(put.has("error")).override_failure_message(str(put)).is_false()
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army["supply_level"]=1.0; army["readiness"]=1.0
	army["position"]={"x":city.x+0.3,"z":city.y}
	army["location_id"]=city_id; army["location_name"]="Tsaren"; army["status"]="stationed"
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	var source:Dictionary=MilitaryCampaign.field_armies[0]
	var factor:=maxf(.05,float(source.get("supply_level",1.0))*(.5+.5*clampf(float(source.get("readiness",.45))*.9,.15,1.0)))
	var garrison:=MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],floorf(17.0*factor),int(army.army_id))
	assert_int(int(garrison.get("troops",0))).is_equal(17)
	# Their nearest other town, where the men run: Stonefield.
	var to:=Pursuit.refuge(civ_id,city_id)
	assert_bool(bool(to.hills)).override_failure_message("the Esurai need another town").is_false()
	refuge_id=String(to.region_id)
	civ.strategic_regions[CivilizationSystem._region_index(civ,refuge_id)]["name"]="Stonefield"
	return MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(army.army_id))]

func _audience(army:Dictionary)->String:
	var audience:=Hall.summon({"figure_id":String((army.commander as Dictionary).get("figure_id",""))})
	assert_dict(audience).is_not_empty()
	return String(audience.id)

func _garrison()->int:
	return int(MilitaryCampaign.occupation_force_for_region(civ_id,city_id).get("troops",0))

func _detachment()->Dictionary:
	for a in MilitaryCampaign.field_armies:
		if (a as Dictionary).get("pursuit") is Dictionary: return a
	return {}

## One world day: armies walk, then the court's daily business.
func _day()->Array:
	GameState.elapsed_days+=1
	MilitaryCampaign._process_field_army_movement_day()
	return WO.daily(int(GameState.elapsed_days))

func _chronicled(prefix:String)->Array:
	return (GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool: return String(e.get("key","")).begins_with(prefix))

func _kill_and_chase(id:String)->Dictionary:
	var kill:=CC.hear(id,"Kill all the men of Tsaren")
	assert_str(String(kill.war.verdict)).override_failure_message(String(kill.get("actor_says",""))).is_equal("fate")
	var chase:=CC.hear(id,"Yeah, go ahead and chase them")
	assert_str(String(chase.get("verb",""))).is_equal("war")
	assert_str(String(chase.war.verdict)).override_failure_message(String(chase.get("actor_says",""))).is_equal("act")
	return chase


func test_the_users_sequence_kill_chase_report_return()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	# "Kill all the men of Tsaren": the men who did not get away are killed;
	# the rest are counted, with where they ran, and a chase is offered.
	var kill:=CC.hear(id,"Kill all the men of Tsaren")
	assert_str(String(kill.war.verdict)).override_failure_message(String(kill.get("actor_says",""))).is_equal("fate")
	# Each man caught on the stated odds (one seeded roll each); every man of
	# Tsaren is on its ledger, killed or running.
	var killed:=int(kill.objective.killed)
	var men:=int(Ledger.split(90,Ledger.SHARES).men)
	assert_int(killed).is_greater(0)
	assert_int(killed).is_less(men)
	var fled:=Pursuit.flight_of(civ_id,city_id)
	assert_int(int(fled.get("count",0))).is_equal(men-killed)
	assert_bool(bool(Ledger.check(civ_id,city_id).ok)).override_failure_message(str(Ledger.check(civ_id,city_id))).is_true()
	var says:=String(kill.actor_says)
	assert_str(says).contains("got away toward Stonefield")
	assert_str(says).contains("I can send")
	assert_str(String((Hall.find(id).get("pending_command",{}) as Dictionary).get("ask",""))).is_equal("chase")
	# "Yeah, go ahead and chase them": a real detachment leaves the garrison.
	var chase:=CC.hear(id,"Yeah, go ahead and chase them")
	assert_str(String(chase.war.verdict)).override_failure_message(String(chase.get("actor_says",""))).is_equal("act")
	var sent:=int(chase.objective.troops)
	assert_int(sent).is_greater(0)
	assert_int(_garrison()).is_equal(17-sent)
	assert_int(_garrison()).is_greater_equal(Pursuit.KEEP_AT_LEAST)
	var out:=_detachment()
	assert_dict(out).is_not_empty()
	assert_int(int(out.troops)).is_equal(sent)
	assert_str(String(out.status)).is_equal("moving")
	assert_str(String(chase.actor_says)).contains("stay to hold Tsaren")
	# The court's own count of what holds the town drops too.
	assert_int(int(WO.held_towns()[0].garrison)).is_equal(17-sent)
	assert_int(Ownership.player_hold(city_id).garrison).is_equal(17-sent)
	# Days pass: one report, then the walk back, then the garrison whole again.
	var reports:=0
	var texts:=PackedStringArray()
	for d in 12:
		for m in _day():
			reports+=1; texts.append(String((m as Dictionary).get("text",(m as Dictionary).get("summary",""))))
		if _detachment().is_empty(): break
	var chronicle:=_chronicled("pursuit:")
	assert_int(chronicle.size()).override_failure_message(str(texts)).is_equal(1)
	var told:=String(chronicle[0].text)
	assert_str(told).contains("went after the men who fled Tsaren")
	assert_str(told).contains("Stonefield")
	assert_int(reports).is_less_equal(1)
	assert_dict(_detachment()).override_failure_message("the detachment never came back").is_empty()
	var force:=MilitaryCampaign.occupation_force_for_region(civ_id,city_id)
	assert_int(int(force.troops)+int(force.get("wounded_pool",0))).is_equal(17)
	# Those who got away are out of Tsaren (or dead), bounded by who fled.
	var left:=CivilizationSystem.region_snapshot(civ_id,city_id)
	assert_float(float(left.population)).is_less_equal(90.0-float(killed)-0.0+0.01)
	assert_str(String(Pursuit.flight_of(civ_id,city_id).state)).is_not_equal("running")
	# Caught and away add up to those who ran; the ledger still balances.
	var flight:=Pursuit.flight_of(civ_id,city_id)
	assert_int(int(flight.caught)+int(flight.reached)).is_equal(int(flight.ran))
	assert_bool(bool(Ledger.check(civ_id,city_id).ok)).override_failure_message(str(Ledger.check(civ_id,city_id))).is_true()
	# The report says the odds it was decided on.
	assert_str(told).contains("for each man")


func test_the_map_shows_the_garrison_on_its_town_and_the_detachment_apart()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	var chase:=_kill_and_chase(id)
	var sent:=int(chase.objective.troops)
	# The garrison's card stands where our chart draws Tsaren, counting only
	# the men inside, and says who is out.
	var garrisons:=Overlay._garrison_inputs()
	assert_int(garrisons.size()).is_equal(1)
	assert_float((garrisons[0].pos as Vector2).distance_to(city)).is_less(0.01)
	assert_int(int(garrisons[0].troops)).is_equal(17-sent)
	var marks:=Overlay._marks({"stage":"hearth","garrisons":garrisons},[],[],{"clashes":[],"sieges":[]})
	var held:Dictionary=marks.filter(func(m:Dictionary)->bool: return bool(m.get("garrison",false)))[0]
	var card:=Marks.card_garrison(held)
	assert_str(card[0]).is_equal("Held by us · %d" % (17-sent))
	assert_str("\n".join(card)).contains("%d more out of the town" % sent)
	# The town's own badge and note.
	var status:=Ownership.status({"city_id":city_id,"civ_id":civ_id})
	assert_int(int(status.garrison)).is_equal(17-sent)
	assert_str(String(status.note)).contains("out after the men who fled")
	# The detachment is its own small band, saying what it is doing.
	var out:=_detachment()
	var doing:=Pursuit.doing_words(out)
	assert_str(doing).is_equal("chasing the Tsaren men who fled")
	var friendly:=[{"army_id":int(out.army_id),"pos":Vector2(float(out.position.x),float(out.position.z)),"strength":float(out.troops),"general":"Rovik Longstride","name":String(out.name),
		"detachment_of":"Tsaren","doing_context":{"status":"moving","pursuit":doing}}]
	var both:=Overlay._marks({"stage":"hearth","garrisons":garrisons},friendly,[],{"clashes":[],"sieges":[]})
	var band_mark:Dictionary=both.filter(func(m:Dictionary)->bool: return not bool(m.get("garrison",false)))[0]
	var lines:=Marks.card_ours(band_mark)
	assert_str(lines[0]).is_equal("%d of the Tsaren garrison" % sent)
	assert_str(lines[1]).is_equal("Chasing the Tsaren men who fled")
	# Stacked on the same spot as the garrison, they still keep two marks and cards.
	var laid:=Marks.layout([{"id":"held","side":"ours","at":Vector2(100,100),"size":22.0,"priority":2,"garrison":true,"troops":7},
		{"id":"det","side":"ours","at":Vector2(101,100),"size":22.0,"priority":1,"troops":10}],{"band":"local","bounds":Rect2(0,0,800,600)})
	assert_int((laid.drawn as Array).size()).is_equal(2)
	# Walking back it says so; our own band at our own town is never "reported days ago".
	for d in 6:
		_day()
		var now:=_detachment()
		if now.is_empty() or String((now.pursuit as Dictionary).state)=="returning": break
	var back:=_detachment()
	if not back.is_empty(): assert_str(Pursuit.doing_words(back)).is_equal("returning to Tsaren")


func test_come_back_turns_the_detachment_and_everyone_home_asks_about_the_town()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	var chase:=_kill_and_chase(id)
	var sent:=int(chase.objective.troops)
	# "All of you come back": the detachment turns back to Tsaren now.
	var back:=CC.hear(id,"All of you come back")
	assert_str(String(back.get("verb",""))).is_equal("war")
	assert_str(String(back.war.kind)).is_equal("recall")
	assert_str(String(back.actor_says)).contains("detachment from Tsaren (%d)" % sent)
	# Still at the gate they are back in the garrison at once; further out
	# they walk back to Tsaren.
	var out:=_detachment()
	if not out.is_empty():
		assert_str(String((out.pursuit as Dictionary).state)).is_equal("returning")
		assert_str(String(out.get("destination_id",""))).is_equal(city_id)
	# Rovik's band, camped at Tsaren, is called home too.
	var rovik:=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(band.army_id))]
	assert_str(String(rovik.destination_id)).is_equal("player_home")
	for d in 6:
		_day()
		if _detachment().is_empty(): break
	assert_dict(_detachment()).is_empty()
	assert_int(_garrison()+int(MilitaryCampaign.occupation_force_for_region(civ_id,city_id).get("wounded_pool",0))).is_equal(17)
	# "Everyone come home": the garrison is not pulled out of Tsaren
	# without asking once.
	var all:=CC.hear(id,"Everyone come home")
	assert_str(String(all.war.kind)).is_equal("recall")
	assert_str(String(all.actor_says)).contains("Leave Tsaren unguarded?")
	assert_int(_garrison()).is_greater(0)
	# "Yes": the garrison marches home and Tsaren is left to its people.
	var yes:=CC.hear(id,"Yes")
	assert_str(String(yes.war.verdict)).override_failure_message(String(yes.get("actor_says",""))).is_equal("act")
	assert_str(String(yes.war.kind)).is_equal("abandon")
	assert_dict(MilitaryCampaign.occupation_force_for_region(civ_id,city_id)).is_empty()
	assert_array(WO.held_towns()).is_empty()
	var marching:=MilitaryCampaign.field_armies.filter(func(a:Dictionary)->bool: return String(a.get("destination_id",""))=="player_home" and String(a.get("status",""))=="moving")
	var walking:=0
	for a in marching: walking+=int(a.troops)
	assert_int(walking).is_greater_equal(17)
	assert_str(String(yes.actor_says)).contains("marching home")


func test_recall_words_and_plain_refusals()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	for words in ["Come back","All of you come home","Return to Seanstone","Call off the chase and come back","Everyone come back home"]:
		assert_str(String(WO.read(words).get("kind",""))).override_failure_message(words).is_equal("recall")
	assert_bool(bool(WO.read("Return to Seanstone").home)).is_true()
	assert_bool(bool(WO.read("Come back").home)).is_false()
	# Not recalls: talk, and a town's fate.
	assert_dict(WO.read("Come back to me with the harvest count?")).is_empty()
	assert_str(String(WO.read("Give Tsaren back and come home").get("kind",""))).is_equal("fate")
	# "Abandon Tsaren" is explicit: done at once.
	assert_bool(bool(Fate.fate_words("abandon tsaren").get("leave",false))).is_true()
	# Nothing ran: a chase is answered plainly, and nobody leaves.
	var r:=CC.hear(id,"Chase the men who fled Tsaren")
	assert_str(String(r.war.verdict)).is_not_equal("act")
	assert_dict(_detachment()).is_empty()
	assert_int(_garrison()).is_equal(17)


func test_too_late_to_chase_is_said_plainly()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	CC.hear(id,"Kill all the men of Tsaren")
	for d in Pursuit.FLED_DAYS+2: _day()
	var r:=CC.hear(id,"Go after the men who ran")
	assert_str(String(r.war.verdict)).is_equal("impossible")
	assert_str(String(r.actor_says)).contains("got away")
	assert_dict(_detachment()).is_empty()
	assert_int(_garrison()).is_equal(17)


func test_offline_court_offers_the_chase_and_its_answers()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	CC.hear(id,"Put the men of Tsaren to the sword")
	var labels:Array=WO.offline_choices(id).map(func(c:Dictionary)->String: return String(c.label))
	assert_bool("Go after them" in labels).override_failure_message(str(labels)).is_true()
	assert_bool("Let them go" in labels).is_true()
	assert_bool("Take them as they are" in labels).is_false()
	var no:=CC.hear(id,"No, let them go")
	assert_str(String(no.war.kind)).is_equal("let_go")
	assert_dict(_detachment()).is_empty()


func test_a_load_reconciles_a_detachment_that_no_longer_fits()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	_kill_and_chase(id)
	var out:=_detachment()
	var index:=MilitaryCampaign._field_army_index(int(out.army_id))
	# A save where the chase was over but the detachment stood idle far out.
	MilitaryCampaign.field_armies[index]["status"]="stationed"
	MilitaryCampaign.field_armies[index]["position"]={"x":city.x,"z":city.y-30.0}
	MilitaryCampaign.field_armies[index]["pursuit"]["state"]="returning"
	assert_int(Pursuit.reconcile()).is_equal(1)
	var fixed:=_detachment()
	assert_str(String(fixed.status)).is_equal("moving")
	assert_str(String(fixed.destination_id)).is_equal(city_id)
	# And one whose town is gone walks home instead of standing in the field.
	MilitaryCampaign.remove_occupation_force(civ_id,city_id,true)
	Pursuit.reconcile()
	var lost:=_detachment()
	assert_str(String(lost.destination_id)).is_equal("player_home")


func test_come_back_after_a_day_out_walks_them_back_to_the_town()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	_kill_and_chase(id)
	GameState.elapsed_days+=1
	MilitaryCampaign._process_field_army_movement_day()
	var out:=_detachment()
	assert_float(Vector2(float(out.position.x),float(out.position.z)).distance_to(city)).is_greater(1.0)
	var back:=CC.hear(id,"Call off the chase and come back")
	assert_str(String(back.war.kind)).is_equal("recall")
	assert_str(String(back.actor_says)).contains("turns back to Tsaren")
	out=_detachment()
	assert_str(String((out.pursuit as Dictionary).state)).is_equal("returning")
	assert_str(String(out.destination_id)).is_equal(city_id)
	assert_str(Pursuit.doing_words(out)).is_equal("returning to Tsaren")
	for d in 8:
		_day()
		if _detachment().is_empty(): break
	assert_dict(_detachment()).is_empty()
	var force:=MilitaryCampaign.occupation_force_for_region(civ_id,city_id)
	assert_int(int(force.troops)+int(force.get("wounded_pool",0))).is_equal(17)
	# Called off, no chase report is filed.
	assert_int(_chronicled("pursuit:").size()).is_equal(0)
