extends GdUnitTestSuite
## A town we hold is ours: the court knows it, and orders about it are
## decisions about its fate, not attacks. The user's live play: Rovik's band
## took Tsaren and left 17 to hold it; one fighter stayed with Rovik. Asked
## to "kill all males and take all women and girls back to seanstone and
## burn what remains of Tsaren to the ground", Rovik answered "One fighter
## against a walled town?" and the hall said "No one marches yet." twice.

const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const Fate:=preload("res://scripts/town_fate.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")

const USERS_ORDER:="Kill all males and take all women and girls back to seanstone and burn what remains of Tsaren to the ground."

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
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
	civ["name"]="Tsaren"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=true; relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	region["population"]=300.0
	city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	home=CivilizationSystem.player_world_origin
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

## The user's situation: Tsaren taken, 17 of Rovik's band holding it, one
## fighter still with Rovik outside the town.
func _captured_tsaren()->Dictionary:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+18
	MilitaryCampaign.raise_recruits(18)
	MilitaryCampaign.start_training("levy","improvised",18)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	MilitaryCampaign.create_field_army(18,"LEVY BAND 1")
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army["supply_level"]=1.0; army["readiness"]=1.0
	army["position"]={"x":city.x+0.3,"z":city.y}
	army["location_id"]=city_id; army["location_name"]="Tsaren"; army["status"]="stationed"
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	# establish_occupation_force detaches ceil(required / (supply x readiness)).
	var source:Dictionary=MilitaryCampaign.field_armies[0]
	var factor:=maxf(.05,float(source.get("supply_level",1.0))*(.5+.5*clampf(float(source.get("readiness",.45))*.9,.15,1.0)))
	var garrison:=MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],floorf(17.0*factor),int(army.army_id))
	assert_int(int(garrison.get("troops",0))).override_failure_message(str(garrison)).is_equal(17)
	var band:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(army.army_id))]
	assert_int(int(band.troops)).is_equal(1)
	return band

func _audience(army:Dictionary)->String:
	var audience:=Hall.summon({"figure_id":String((army.commander as Dictionary).get("figure_id",""))})
	assert_dict(audience).is_not_empty()
	return String(audience.id)


func test_the_court_knows_tsaren_is_ours_and_refuses_to_attack_it()->void:
	var band:=_captured_tsaren()
	var held:=WO.held_towns()
	assert_int(held.size()).is_equal(1)
	assert_int(int(held[0].garrison)).is_equal(17)
	# Not a place to attack any more.
	for p:Dictionary in WO.known_places(): assert_str(String(p.city_id)).is_not_equal(city_id)
	assert_bool(bool(WO.find_target("Attack Tsaren").get("held",false))).is_true()
	# The war leader counts the garrison among his forces.
	assert_int(int(WO.forces(WO.war_leader()).holding)).is_equal(17)
	var id:=_audience(band)
	for words in ["Attack Tsaren","Send our full forces into battle on Tsaren","You already have 20 fighters in TSAREN!"]:
		var r:=CC.hear(id,words)
		assert_str(String(r.get("verb",""))).override_failure_message(words).is_equal("war")
		assert_str(String(r.war.verdict)).override_failure_message("%s -> %s" % [words,String(r.get("actor_says",""))]).is_equal("held")
		assert_str(String(r.actor_says)).contains("Tsaren is already ours")
		assert_str(String(r.actor_says)).contains("17 of")
		assert_str(String(r.actor_says)).contains("I have one with me")
		assert_str(String(r.actor_says)).not_contains("walled town")
		assert_str(String(r.outcome)).is_equal("Tsaren is already ours.")
	# Nothing marched.
	assert_str(String(MilitaryCampaign.field_armies[0].status)).is_equal("stationed")


func test_the_users_order_is_carried_out_on_the_town_with_real_consequences()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	var ours_before:=int(GameState.population_total)
	var civ_before:=float(CivilizationSystem.civilizations[0].population)
	var opinion_before:=float(CivilizationSystem.civilizations[0].player_relation.get("opinion",0.0))
	var fear_before:=float(MilitaryCampaign.war_reputation.get("fear",0.0))
	var r:=CC.hear(id,USERS_ORDER)
	assert_str(String(r.get("verb",""))).is_equal("war")
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate")
	assert_bool(bool(r.get("executed",false))).is_true()
	var o:Dictionary=r.objective
	# Men killed, bounded by the men who could not get away and the garrison's reach.
	assert_int(int(o.killed)).is_greater(0)
	assert_int(int(o.killed)).is_less_equal(mini(roundi(300.0*Fate.MEN_SHARE*Fate.CAUGHT_SHARE),17*Fate.KILLS_PER_FIGHTER))
	# Captives led home, bounded by what 17 can guard on the road.
	assert_int(int(o.captives)).is_greater(0)
	assert_int(int(o.captives)).is_less_equal(17*Fate.CAPTIVES_PER_FIGHTER)
	# They walk the road home as bonded people (occupation_transfers), eating
	# travel rations; they are not counted at home until they arrive.
	var walking:Array=(MilitaryCampaign.occupation_transfers.data.transfers as Array).filter(func(t:Dictionary)->bool: return String(t.region)==city_id)
	assert_int(walking.size()).is_equal(1)
	assert_int(int(walking[0].people)).is_equal(int(o.captives))
	assert_str(String(walking[0].status)).is_equal("enslaved")
	assert_int(int(GameState.population_total)).is_equal(ours_before)
	# The town burned; the garrison comes home with the captives.
	assert_bool(bool(o.burned)).is_true()
	assert_bool(bool(o.left)).is_true()
	assert_dict(MilitaryCampaign.occupation_force_for_region(civ_id,city_id)).is_empty()
	var region:=CivilizationSystem.region_snapshot(civ_id,city_id)
	assert_float(float(region.get("damage",0.0))).is_equal(1.0)
	assert_float(float(CivilizationSystem.civilizations[0].population)).is_less_equal(civ_before-float(int(o.killed)+int(o.captives))+0.01)
	# Dread, grudges and hatred; our name for fear.
	assert_float(Divine.civ_dread(civ_id)).is_greater(0.0)
	assert_float(float(CivilizationSystem.civilizations[0].player_relation.get("opinion",0.0))).is_less(opinion_before)
	assert_float(float(MilitaryCampaign.war_reputation.get("fear",0.0))).is_greater(fear_before)
	# One sober Chronicle entry, no gore.
	var entries:=0
	for e:Dictionary in GameState.chronicle.get("entries",[]):
		if String(e.get("key","")).begins_with("town_fate:"):
			entries+=1
			var text:=String(e.get("text","")).to_lower()
			assert_str(text).contains("put to the sword")
			assert_str(text).contains("led away toward seanstone")
			for gore in ["blood","throat","skull","rape","entrails"]: assert_str(text).not_contains(gore)
	assert_int(entries).is_equal(1)
	# The war leader says it plainly, with the numbers.
	assert_str(String(r.actor_says)).contains("men of Tsaren were put to the sword")
	assert_str(String(r.actor_says)).contains(str(int(o.killed)) if int(o.killed)>12 else "")


func test_offline_court_offers_the_fates_of_a_held_town()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	var labels:Array=[]
	for c:Dictionary in WO.offline_choices(id): labels.append(String(c.label))
	for want in ["Spare Tsaren and hold it","Take captives and burn Tsaren","Put the men of Tsaren to the sword","Take tribute from Tsaren and leave"]:
		assert_bool(want in labels).override_failure_message(str(labels)).is_true()
	assert_bool(labels.any(func(l:String)->bool: return l.begins_with("March") and l.ends_with("Tsaren"))).override_failure_message(str(labels)).is_false()
	for c:Dictionary in WO.offline_choices(id):
		if String(c.label)=="Spare Tsaren and hold it":
			var r:=CC.hear(id,String(c.params.command_text))
			assert_str(String(r.war.verdict)).is_equal("fate")
			assert_bool(bool(r.objective.spared)).is_true()
			assert_int(int(r.objective.killed)).is_equal(0)
	assert_int(int(MilitaryCampaign.occupation_force_for_region(civ_id,city_id).get("troops",0))).is_equal(17)


func test_every_former_occupation_decision_is_reachable_through_the_court()->void:
	# The occupation screen now only reports; every decision is a court order.
	var band:=_captured_tsaren()
	var id:=_audience(band)
	var texts:={}
	for c:Dictionary in WO.offline_choices(id): texts[String(c.label)]=String(c.params.command_text)
	var wants:={"Govern Tsaren as ours":{"policy":"stewardship"},"Rule Tsaren by the spear":{"policy":"military_rule"},"Let Tsaren keep its own elders":{"policy":"self_rule"},
		"Make Tsaren's people our own":{"policy":"equal_citizenship"},"Enslave the people of Tsaren":{"policy":"forced_labor"},"Bring 20 of Tsaren's people home as our own":{"move":"citizen","count":20},
		"Rebuild Tsaren":{"reconstruct":true},"Strengthen the garrison at Tsaren":{"reinforce":true},"Give Tsaren back and come home":{"leave":true}}
	for label:String in wants:
		assert_bool(texts.has(label)).override_failure_message("%s missing from %s" % [label,str(texts.keys())]).is_true()
		var reading:=WO.read(String(texts[label]))
		assert_str(String(reading.get("kind",""))).override_failure_message(label).is_equal("fate")
		for key:String in wants[label]: assert_str(str(reading.fate.get(key,""))).override_failure_message("%s: %s" % [label,str(reading.fate)]).is_equal(str(wants[label][key]))
	# Governed as ours: carried out through the occupation policy.
	var r:=CC.hear(id,String(texts["Govern Tsaren as ours"]))
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate")
	assert_str(String(CivilizationSystem.occupation_governance_snapshot(civ_id,city_id).get("policy",""))).is_equal("stewardship")
	# Rule by the spear needs more than 17 to hold 300 down: said plainly, never an attack.
	var spear:=CC.hear(id,String(texts["Rule Tsaren by the spear"]))
	assert_str(String(spear.war.verdict)).is_not_equal("act")
	assert_str(String(spear.get("actor_says",""))).is_not_empty()
	assert_str(String(MilitaryCampaign.field_armies[0].status)).is_equal("stationed")
	# Given back: the garrison comes home and the town is theirs again.
	var back:=CC.hear(id,String(texts["Give Tsaren back and come home"]))
	assert_str(String(back.war.verdict)).override_failure_message(String(back.get("actor_says",""))).is_equal("fate")
	assert_dict(MilitaryCampaign.occupation_force_for_region(civ_id,city_id)).is_empty()
	assert_array(WO.held_towns()).is_empty()


func test_a_besieging_band_can_be_told_to_storm_and_objects_first()->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+200
	MilitaryCampaign.raise_recruits(200)
	MilitaryCampaign.start_training("levy","improvised",200)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var made:=MilitaryCampaign.create_field_army(200,"LEVY BAND 1")
	var army_id:=int((made.army as Dictionary).army_id)
	var index:=MilitaryCampaign._field_army_index(army_id)
	MilitaryCampaign.field_armies[index]["position"]={"x":city.x+0.2,"z":city.y}
	MilitaryCampaign.field_armies[index]["status"]="stationed"
	var began:=MilitaryCampaign.order_city_operation(army_id,civ_id,city_id,true)
	assert_bool(began.has("error")).override_failure_message(str(began)).is_false()
	assert_dict(MilitaryCampaign.active_siege).is_not_empty()
	var id:=_audience(MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)])
	var r:=CC.hear(id,"Storm the walls of Tsaren")
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("object")
	assert_str(String(r.actor_says)).contains("Day ")
	assert_str(String(r.actor_says)).contains("say the word and we go over the walls")
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
	var again:=CC.hear(id,"Go anyway")
	assert_str(String(again.war.verdict)).override_failure_message(String(again.get("actor_says",""))).is_equal("act")
	assert_str(String(again.objective.kind)).is_equal("storm")
	assert_dict(MilitaryCampaign.active_siege).is_empty()
	assert_dict(MilitaryCampaign.active_engagement).is_not_empty()


func test_each_fate_reads_from_plain_words()->void:
	assert_bool(bool(Fate.fate_words("put the men of tsaren to the sword").get("kill_men",false))).is_true()
	var taken:=Fate.fate_words("take captives home and burn tsaren")
	assert_bool(bool(taken.get("captives",false)) and bool(taken.get("raze",false))).is_true()
	assert_bool(bool(Fate.fate_words("take tribute from tsaren and leave").get("tribute",false))).is_true()
	var spared:=Fate.fate_words("spare tsaren and hold it")
	assert_bool(bool(spared.get("spare",false)) and bool(spared.get("hold",false))).is_true()
	var users:=Fate.fate_words(USERS_ORDER.to_lower())
	assert_bool(bool(users.get("kill_men",false)) and bool(users.get("captives",false)) and bool(users.get("raze",false))).is_true()
	assert_dict(Fate.fate_words("how is the harvest")).is_empty()


func test_one_outcome_line_said_once_even_when_the_stage_words_run_out()->void:
	var band:=_captured_tsaren()
	var id:=_audience(band)
	var voice:Node=auto_free(Voice.new())
	voice.force_offline=true
	var before:=(Hall.find(id).get("lines",[]) as Array).size()
	for words in ["Attack Tsaren","You already have 20 fighters in TSAREN!","Attack Tsaren now"]:
		voice.command_reaction(id,CC.hear(id,words))
	var lines:Array=(Hall.find(id).get("lines",[]) as Array).slice(before)
	for line:Dictionary in lines:
		var text:=String(line.text).strip_edges()
		# The outcome note is never staged as a bracketed line as well.
		assert_str(text).is_not_equal("[Tsaren is already ours.]")
		assert_str(text).is_not_equal("[No one marches yet.]")


func test_the_garrison_is_marked_on_its_town_as_a_small_card()->void:
	_captured_tsaren()
	var garrisons:=Overlay._garrison_inputs()
	assert_int(garrisons.size()).is_equal(1)
	assert_int(int(garrisons[0].troops)).is_equal(17)
	var marks:=Overlay._marks({"stage":"hearth","garrisons":garrisons},[],[],{"clashes":[],"sieges":[]})
	var held:Array=marks.filter(func(m:Dictionary)->bool: return bool(m.get("garrison",false)))
	assert_int(held.size()).is_equal(1)
	var card:=Marks.card_garrison(held[0])
	assert_str(card[0]).is_equal("Held by us · 17")
	assert_str(card[1]).contains("Tsaren")
	# Up close the war chart still inks the forces and their cards; it no
	# longer leaves them to a large world-space label.
	assert_float(Marks.size_px("ground","band")).is_greater(0.0)
	var laid:=Marks.layout([{"id":"a","side":"ours","at":Vector2(100,100),"size":22.0,"priority":1}],{"band":"ground","bounds":Rect2(0,0,800,600)})
	assert_int((laid.drawn as Array).size()).is_equal(1)
	assert_bool(bool((laid.drawn as Array)[0].card)).is_true()


func test_a_band_camped_out_of_town_is_not_at_home()->void:
	# Rovik's band, 25 km out, whose record still said "player_home".
	var camp:={"status":"stationed","location_id":"player_home","location_name":"Home settlement","position":{"x":home.x,"z":home.y+25.0}}
	assert_bool(Marks.at_home(camp,home)).is_false()
	var doing:=Marks.doing({"status":"stationed","location_name":"Home settlement","home_km":Marks.home_km(camp,home)})
	assert_str(doing).is_equal("camped about 25 km from home")
	var at:={"status":"stationed","location_id":"player_home","position":{"x":home.x+0.3,"z":home.y}}
	assert_bool(Marks.at_home(at,home)).is_true()
	assert_str(Marks.doing({"status":"stationed","location_name":"Home settlement","at_home":true,"home_km":0.3})).is_equal("at home")
	assert_str(Marks.doing({"status":"moving","destination_name":"Tsaren","days_left":3})).is_equal("marching on Tsaren, 3 days out")
