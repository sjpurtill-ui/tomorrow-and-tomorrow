extends RefCounted
## THE BATTLE SCENARIOS: realistic war situations across the ages and sizes,
## each played end to end by tests/battle_eval/runners.gd.
##
## Keys: id, about (one line), kind (runner: field, defend_home, assault,
## siege, concurrent, march, court, war_raid, chase, recall, recall_march,
## garrison, save, blocked, rival), era (0 stone .. 5 modern: sets what our
## people know and so the war leader's words), ours / theirs (formations:
## unit, weapon, count, training), morales and generals, seed, and expect
## (winner ours|theirs|either, overrun, skirmish, captives, spoils, why,
## event, ground, reserves, unseen, report_says, ...).

## Formations by age.
static func f(unit:String,weapon:String,count:int,training:float=0.6)->Dictionary:
	return {"unit":unit,"weapon":weapon,"count":count,"training":training}


static func all()->Array:
	var out:Array=[]
	# --- The first ages: bands in the open ------------------------------------------------
	out.append({"id":"stone_20v2_overrun","about":"twenty of ours catch two of theirs in the open","kind":"field","era":0,"seed":11,
		"ours":[f("levy","spear",20)],"theirs":[f("levy","improvised",2,0.3)],"their_morale":0.6,
		"expect":{"winner":"ours","overrun":true,"skirmish":true,"max_exchanges":1}})
	out.append({"id":"stone_2v20_overrun","about":"two of ours stumble on twenty of theirs","kind":"field","era":0,"seed":12,
		"ours":[f("levy","spear",2)],"theirs":[f("levy","spear",20)],"our_morale":0.6,"their_morale":0.8,
		"expect":{"winner":"theirs","overrun":true,"skirmish":true,"max_exchanges":1}})
	out.append({"id":"stone_20v20_even","about":"twenty against twenty, man for man the same","kind":"field","era":0,"seed":13,
		"ours":[f("levy","spear",20)],"theirs":[f("levy","spear",20)],"our_morale":0.8,"their_morale":0.8,
		"expect":{"winner":"either","overrun":false,"min_exchanges":2}})
	out.append({"id":"stone_120v90","about":"a hundred and twenty spears and bows against ninety","kind":"field","era":0,"seed":14,
		"ours":[f("levy","spear",80),f("archer","bow",40)],"theirs":[f("levy","improvised",70,0.4),f("archer","bow",20)],
		"expect":{"winner":"ours","overrun":false}})
	out.append({"id":"stone_60v20_lopsided","about":"sixty against twenty: decided the day it is fought","kind":"field","era":0,"seed":15,
		"ours":[f("levy","spear",60)],"theirs":[f("levy","improvised",20,0.3)],"their_morale":0.6,
		"expect":{"winner":"ours"}})
	out.append({"id":"stone_17v40_rout","about":"seventeen of ours meet forty and are routed","kind":"field","era":0,"seed":16,
		"ours":[f("levy","spear",17,0.4)],"theirs":[f("levy","spear",40,0.6)],"our_morale":0.6,"their_morale":0.85,
		"expect":{"winner":"theirs"}})
	out.append({"id":"stone_captives_enslave","about":"a clear win: the captives go home as bondservants, as the ruler ordered","kind":"field","era":0,"seed":17,
		"practice":{"prisoners":"enslave","spoils":"army stores"},
		"ours":[f("levy","spear",150)],"theirs":[f("levy","improvised",60,0.3)],"their_morale":0.55,
		"expect":{"winner":"ours","captives":true}})
	out.append({"id":"stone_captives_hold","about":"a clear win: the captives are held under guard","kind":"field","era":0,"seed":18,
		"practice":{"prisoners":"hold","spoils":"army stores"},
		"ours":[f("levy","spear",140)],"theirs":[f("levy","improvised",55,0.3)],"their_morale":0.55,
		"expect":{"winner":"ours","captives":true}})
	out.append({"id":"stone_captives_release","about":"a clear win: the captives are let go","kind":"field","era":0,"seed":19,
		"practice":{"prisoners":"release"},
		"ours":[f("levy","spear",140)],"theirs":[f("levy","improvised",55,0.3)],"their_morale":0.55,
		"expect":{"winner":"ours"}})
	out.append({"id":"stone_night_unseen","about":"forty creep up on sixty in the dark and are not seen","kind":"field","era":0,"seed":20,
		"approach":{"kind":"night","chance":0.85},"ours":[f("levy","spear",40)],"theirs":[f("levy","spear",60,0.5)],
		"expect":{"unseen":true,"event":"We fell on them while they slept","report_says":"unseen"}})
	out.append({"id":"stone_night_seen","about":"forty try it in the dark and their watch sees them","kind":"field","era":0,"seed":21,
		"approach":{"kind":"night","chance":0.05},"ours":[f("levy","spear",40)],"theirs":[f("levy","spear",40,0.5)],
		"expect":{"unseen":false,"report_says":"saw us coming"}})
	out.append({"id":"stone_hungry_band","about":"a hungry band of ours fights a fed one","kind":"field","era":0,"seed":22,"hungry":true,
		"ours":[f("levy","spear",100)],"theirs":[f("levy","spear",100)],"our_morale":0.8,"their_morale":0.8,
		"expect":{"why":"hunger"}})
	out.append({"id":"stone_forest_edge","about":"bands meet at a forest edge","kind":"field","era":0,"seed":23,"ground":"forest",
		"ours":[f("levy","spear",90),f("archer","bow",30)],"theirs":[f("levy","spear",100)],
		"expect":{"ground":"forest"}})
	# --- Bronze ---------------------------------------------------------------------------------
	out.append({"id":"bronze_300v280","about":"three hundred spears and bows against two hundred and eighty","kind":"field","era":1,"seed":31,
		"ours":[f("spearman","shield_spear",220),f("archer","bow",80)],"theirs":[f("spearman","shield_spear",200),f("archer","bow",80)],"our_morale":0.8,"their_morale":0.8,
		"expect":{"winner":"either","overrun":false}})
	out.append({"id":"bronze_chariots_ride_down","about":"our chariots ride down a broken host: captives taken in the chase","kind":"field","era":1,"seed":32,
		"practice":{"prisoners":"hold"},
		"ours":[f("spearman","shield_spear",450),f("chariot","chariot_kit",150)],"theirs":[f("levy","improvised",500,0.3)],"their_morale":0.6,
		"expect":{"winner":"ours","captives":true}})
	out.append({"id":"bronze_1000v1500_rout","about":"a thousand of ours break against fifteen hundred","kind":"field","era":1,"seed":33,
		"ours":[f("spearman","shield_spear",1000,0.45)],"theirs":[f("spearman","shield_spear",1200),f("archer","bow",300)],"our_morale":0.65,"their_morale":0.85,
		"expect":{"winner":"theirs"}})
	out.append({"id":"bronze_pass_reserves","about":"three thousand against three thousand in a narrow pass: most wait their turn","kind":"field","era":1,"seed":34,"ground":"pass",
		"ours":[f("spearman","shield_spear",3000)],"theirs":[f("spearman","shield_spear",2800)],"our_morale":0.8,"their_morale":0.8,"population":20000,
		"expect":{"ground":"pass","reserves":true}})
	out.append({"id":"bronze_our_general_falls","about":"we are beaten and our general falls","kind":"field","era":1,"seed":35,"seek":"our_general_killed",
		"ours":[f("spearman","shield_spear",200,0.45)],"theirs":[f("spearman","shield_spear",420)],"our_morale":0.6,"their_morale":0.85,
		"our_general":{"name":"Rovik Longstride","skill":0.4,"resolve":0.3},
		"expect":{"winner":"theirs"}})
	out.append({"id":"bronze_their_general_falls","about":"we win and their general falls","kind":"field","era":1,"seed":36,"seek":"their_general_killed",
		"ours":[f("spearman","shield_spear",420)],"theirs":[f("spearman","shield_spear",200,0.45)],"their_morale":0.6,
		"their_general":{"name":"Tavo Kesh","skill":0.4,"resolve":0.3},
		"expect":{"winner":"ours"}})
	# --- The classical age ---------------------------------------------------------------------
	out.append({"id":"classical_2000v1800","about":"pikes, swords and horse against pikes and swords","kind":"field","era":2,"seed":41,"population":12000,
		"ours":[f("pikeman","pike",1000),f("heavy_swordsman","sword_shield",700),f("armored_cavalry","armored_lance",300)],
		"theirs":[f("pikeman","pike",1000),f("heavy_swordsman","sword_shield",800)],
		"expect":{"winner":"either","overrun":false}})
	out.append({"id":"classical_12000v10000","about":"two great hosts of the classical age meet in the open","kind":"field","era":2,"seed":46,"population":80000,
		"ours":[f("pikeman","pike",6000),f("heavy_swordsman","sword_shield",4000),f("armored_cavalry","armored_lance",2000)],
		"theirs":[f("pikeman","pike",6000),f("heavy_swordsman","sword_shield",3000),f("light_cavalry","lance",1000)],"budget_ms":9000.0,
		"expect":{"overrun":false}})
	out.append({"id":"classical_5000v800_overrun","about":"five thousand overrun eight hundred","kind":"field","era":2,"seed":42,"population":30000,
		"ours":[f("pikeman","pike",3000),f("heavy_swordsman","sword_shield",2000)],"theirs":[f("levy","improvised",800,0.3)],"their_morale":0.6,
		"expect":{"winner":"ours","overrun":true}})
	out.append({"id":"classical_ford_crossing","about":"four thousand force a ford against three and a half","kind":"field","era":2,"seed":43,"population":25000,
		"river":[[5.12,-3.0,0.08,6.0]],"toward":Vector2(0.3,0.0),
		"ours":[f("heavy_swordsman","sword_shield",2500),f("crossbowman","crossbow",1500)],"theirs":[f("pikeman","pike",2500),f("crossbowman","crossbow",1000)],
		"expect":{"ground":"ford","reserves":true,"why":"river"}})
	out.append({"id":"classical_their_general_taken","about":"we win and take their general","kind":"field","era":2,"seed":44,"seek":"their_general_taken","population":8000,
		"ours":[f("heavy_swordsman","sword_shield",900),f("armored_cavalry","armored_lance",300)],"theirs":[f("levy","spear",700,0.4)],"their_morale":0.6,
		"their_general":{"name":"Tavo Kesh","skill":0.4,"resolve":0.2},
		"expect":{"winner":"ours"}})
	# --- Gunpowder ------------------------------------------------------------------------------
	out.append({"id":"gunpowder_8000v7000","about":"eight thousand musket, pike, horse and guns against seven thousand","kind":"field","era":3,"seed":51,"population":60000,
		"ours":[f("musketeer","musket",4500),f("pikeman","pike",1800),f("dragoon","dragoon_kit",1000),f("field_artillery","field_gun",700)],
		"theirs":[f("musketeer","musket",4000),f("pikeman","pike",2000),f("field_artillery","field_gun",1000)],
		"expect":{"winner":"either","overrun":false}})
	out.append({"id":"gunpowder_1200v1100","about":"a regiment's worth against another","kind":"field","era":3,"seed":52,"population":10000,
		"ours":[f("musketeer","musket",900),f("pikeman","pike",300)],"theirs":[f("musketeer","musket",800),f("pikeman","pike",300)],
		"expect":{"overrun":false}})
	out.append({"id":"gunpowder_night_attack","about":"musketeers try a night attack on a camp","kind":"field","era":3,"seed":53,"population":8000,
		"approach":{"kind":"night","chance":0.6},"ours":[f("musketeer","musket",600)],"theirs":[f("musketeer","musket",700,0.5)],
		"expect":{"report_says":"in the dark"}})
	out.append({"id":"classical_hungry_foe","about":"a starving host of theirs meets our fed one","kind":"field","era":2,"seed":45,"population":6000,"their_hungry":true,
		"ours":[f("pikeman","pike",600)],"theirs":[f("pikeman","pike",600)],"expect":{"why":"hunger","winner":"ours"}})
	# --- The age of rifles ----------------------------------------------------------------------
	out.append({"id":"industrial_20000v18000","about":"a corps of rifles, machine guns and guns against another","kind":"field","era":4,"seed":61,"population":200000,
		"ours":[f("rifle_infantry","service_rifle",16000),f("machine_gun_company","machine_gun",2000),f("field_artillery","field_gun",2000)],
		"theirs":[f("rifle_infantry","service_rifle",15000),f("machine_gun_company","machine_gun",1500),f("field_artillery","field_gun",1500)],
		"budget_ms":9000.0,"expect":{"overrun":false}})
	out.append({"id":"industrial_600v500","about":"a battalion of rifles against a smaller one","kind":"field","era":4,"seed":62,"population":8000,
		"ours":[f("rifle_infantry","service_rifle",540),f("machine_gun_company","machine_gun",60)],"theirs":[f("rifle_infantry","service_rifle",500)],
		"expect":{"overrun":false}})
	# --- Armour ---------------------------------------------------------------------------------
	out.append({"id":"modern_40000v35000","about":"forty thousand, armour and guns, against thirty-five thousand","kind":"field","era":5,"seed":71,"population":400000,
		"ours":[f("mechanized_infantry","mechanized_kit",24000),f("armored_formation","armored_vehicle",8000),f("modern_artillery","modern_field_gun",8000)],
		"theirs":[f("mechanized_infantry","mechanized_kit",22000),f("armored_formation","armored_vehicle",6000),f("modern_artillery","modern_field_gun",7000)],
		"budget_ms":12000.0,"expect":{"overrun":false,"reserves":true}})
	out.append({"id":"modern_200v180","about":"a company group against another","kind":"field","era":5,"seed":72,"population":6000,
		"ours":[f("mechanized_infantry","mechanized_kit",150),f("armored_formation","armored_vehicle",50)],"theirs":[f("mechanized_infantry","mechanized_kit",180)],
		"expect":{"overrun":false}})
	# --- Home attacked --------------------------------------------------------------------------
	out.append({"id":"home_raid_watch_holds","about":"twenty-five raiders against our twenty and the watch","kind":"defend_home","era":0,"seed":81,"incident":"raid",
		"ours":[f("levy","spear",20)],"watch":40,"theirs":[f("levy","improvised",25,0.4)],"their_morale":0.65,
		"expect":{"winner":"ours"}})
	out.append({"id":"home_raid_routine","about":"six raiders against sixty at home: the watch sees them off","kind":"defend_home","era":0,"seed":82,"incident":"raid",
		"ours":[f("levy","spear",60)],"watch":60,"theirs":[f("levy","improvised",6,0.3)],"their_morale":0.55,
		"expect":{"winner":"ours"}})
	out.append({"id":"home_raid_breaks_in","about":"eighty raiders overwhelm our ten","kind":"defend_home","era":0,"seed":83,"incident":"raid",
		"ours":[f("levy","spear",10,0.4)],"watch":10,"theirs":[f("levy","spear",80,0.6)],"their_morale":0.85,
		"expect":{"winner":"theirs"}})
	out.append({"id":"home_two_raiders","about":"two raiders against the twenty of the watch","kind":"defend_home","era":0,"seed":84,"incident":"raid",
		"ours":[f("levy","spear",20)],"watch":20,"theirs":[f("levy","improvised",2,0.3)],"their_morale":0.6,
		"expect":{"winner":"ours","overrun":true}})
	out.append({"id":"home_campaign_host","about":"a host of two hundred comes against our hundred and fifty at home","kind":"defend_home","era":1,"seed":85,"incident":"campaign",
		"ours":[f("spearman","shield_spear",150)],"watch":150,"theirs":[f("spearman","shield_spear",200)],"their_morale":0.8})
	# --- Towns ----------------------------------------------------------------------------------
	out.append({"id":"assault_tsaren_strong","about":"three hundred storm Tsaren","kind":"assault","era":1,"seed":91,"population":4000,
		"ours":[f("spearman","shield_spear",300)]})
	out.append({"id":"assault_tsaren_weak","about":"thirty try to storm Tsaren","kind":"assault","era":1,"seed":92,
		"ours":[f("spearman","shield_spear",30,0.4)]})
	out.append({"id":"siege_tsaren","about":"four hundred ring Tsaren for six days, then storm it","kind":"siege","era":1,"seed":93,"siege_days":6,"population":5000,
		"ours":[f("spearman","shield_spear",400)]})
	out.append({"id":"home_besieged","about":"a host of four hundred rings Seanstone behind its palisade, then storms it","kind":"home_siege","era":1,"seed":96,"siege_days":4,"population":4000,
		"ours":[f("spearman","shield_spear",120)],"watch":120,"theirs":[f("spearman","shield_spear",400)]})
	out.append({"id":"raid_tsaren","about":"our band raids Tsaren's fields and stores","kind":"raid","era":1,"seed":97,"population":3000,
		"ours":[f("spearman","shield_spear",150)]})
	out.append({"id":"garrison_holds_tsaren","about":"our thirty in Tsaren beat off twenty come to take it back","kind":"garrison","era":0,"seed":94,"garrison":30,
		"ours":[f("levy","spear",40)],"theirs":[f("levy","improvised",20,0.4)],"expect":{"winner":"ours"}})
	out.append({"id":"garrison_loses_tsaren","about":"our ten in Tsaren against sixty come to take it back","kind":"garrison","era":0,"seed":95,"garrison":10,
		"ours":[f("levy","spear",12)],"theirs":[f("levy","spear",60)],"expect":{"winner":"theirs"}})
	# --- Many at once ---------------------------------------------------------------------------
	out.append({"id":"two_battles_at_once","about":"two bands fight on two fronts at once","kind":"concurrent","era":0,"seed":101,"battles":2})
	out.append({"id":"five_battles_at_once","about":"five bands fight on five fronts at once","kind":"concurrent","era":1,"seed":102,"battles":5,
		"ours":[f("spearman","shield_spear",120)],"population":4000})
	out.append({"id":"twenty_battles_one_day","about":"a day of twenty battles stays quick","kind":"concurrent","era":1,"seed":103,"battles":20,"timed":true,
		"ours":[f("spearman","shield_spear",150)],"population":12000,"budget_ms":15000.0})
	# --- Marches --------------------------------------------------------------------------------
	out.append({"id":"march_round_the_lake","about":"a band marches to the far shore of a lake: round it, not across","kind":"march","era":0,
		"water":[[8.0,-6.0,8.0,12.0]],"goal":Vector2(24.0,0.0),"expect":{"direct":false}})
	out.append({"id":"march_wades_a_stream","about":"a narrow stream is waded, not walked round","kind":"march","era":0,
		"water":[[12.0,-30.0,0.15,60.0]],"goal":Vector2(24.0,0.0),"expect":{"direct":true}})
	out.append({"id":"march_no_road","about":"an island: no road by land, said plainly","kind":"march","era":0,
		"water":[[14.0,-12.0,4.0,24.0],[14.0,-12.0,24.0,4.0],[14.0,8.0,24.0,4.0],[34.0,-12.0,4.0,24.0]],"goal":Vector2(24.0,-2.0),"expect":{"refused":true}})
	out.append({"id":"march_over_the_hills","about":"a march across broken hills is slower than on the plain","kind":"march","era":0,
		"hills":[[4.0,-20.0,30.0,40.0]],"goal":Vector2(24.0,0.0),"expect":{"min_days":2}})
	out.append({"id":"battle_in_the_hills","about":"bands meet on broken, hilly ground","kind":"field","era":0,"seed":111,"ground":"rough",
		"ours":[f("levy","spear",120)],"theirs":[f("levy","spear",110)],"expect":{"ground":"rough"}})
	# --- The court's word, the war leader's clashes, the chase ---------------------------------
	out.append({"id":"court_attack_tsaren","about":"'Attack Tsaren': the war leader marches, fights and reports once","kind":"court","era":0,"seed":121,"officials":true,
		"words":"Attack Tsaren","ours":[f("levy","spear",90)],"town_people":120.0,"budget_ms":9000.0})
	out.append({"id":"war_loop_raid","about":"their raiders strike our planted fields","kind":"war_raid","era":0,"seed":122,"officials":true})
	out.append({"id":"war_loop_skirmish","about":"their fighters cross the border and ours meet them","kind":"war_raid","era":0,"seed":123,"officials":true,"skirmish":true})
	out.append({"id":"chase_the_fled","about":"a detachment chases the men who fled Tsaren and comes back","kind":"chase","era":0,"seed":124,"garrison":18,"fled":12,"town_people":90.0})
	# --- Pulling back, saves, orders ------------------------------------------------------------
	out.append({"id":"recall_mid_battle","about":"our host is called back in the middle of a fight, then home","kind":"recall","era":1,"seed":131,"population":6000,
		"ours":[f("spearman","shield_spear",1500)],"theirs":[f("spearman","shield_spear",1500)]})
	out.append({"id":"recall_the_march","about":"a band on the road is called home and turns round","kind":"recall_march","era":0})
	out.append({"id":"save_mid_battle","about":"a battle saved after its first day ends the same as fought straight through","kind":"save","era":1,"seed":141,
		"ours":[f("spearman","shield_spear",300)],"theirs":[f("spearman","shield_spear",290)]})
	out.append({"id":"orders_after_victory","about":"after a victory with captives, the next march and levy go at once","kind":"blocked","era":0,"seed":151,"case":"after_victory"})
	out.append({"id":"orders_with_raiders_coming","about":"raiders coming at home do not stop a band sent to Tsaren","kind":"blocked","era":0,"seed":152,"case":"raid_pending"})
	out.append({"id":"orders_during_a_siege","about":"a siege at Tsaren does not stop another band marching elsewhere","kind":"blocked","era":1,"seed":153,"case":"siege_elsewhere","population":4000})
	out.append({"id":"generals_fight_during_a_siege","about":"with a siege at Tsaren and raiders at home, our generals still fight the bands and towns before them","kind":"blocked","era":1,"seed":154,"case":"commanded_elsewhere","population":6000})
	out.append({"id":"general_fights_it","about":"our general takes a battle over and fights it himself","kind":"commanded","era":1,"seed":171,"population":4000,
		"ours":[f("spearman","shield_spear",400)],"theirs":[f("spearman","shield_spear",380)]})
	# --- Other peoples' battles -----------------------------------------------------------------
	out.append({"id":"rival_battle_seen","about":"the Esurai and the Cedar League fight where our band can see","kind":"rival","era":0,"seed":161,"watched":true,"at":Vector2(18.0,0.0),"budget_ms":12000.0})
	out.append({"id":"rival_battle_unseen","about":"the Esurai and the Cedar League fight far from any of ours","kind":"rival","era":0,"seed":162,"watched":false,"at":Vector2(70.0,40.0),"budget_ms":12000.0})
	return out
