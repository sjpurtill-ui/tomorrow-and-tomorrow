extends RefCounted
## WORLDS FOR THE COURT EVALUATION (tests/test_court_eval.gd).
##
## One base world shaped like the user's campaign: Seanstone (900 people),
## the Esurai at war with us, their chief town Tsaren (90 people, a short
## walk away), their other towns Stonefield (where men run) and Eldwick; our
## court renamed as the user's: Kishan of Reedwater the Headman (Steward),
## War Chief Suri (Marshal), Kavu the Keeper of Tribute (Quartermaster),
## Imeri of Windgap (Chief Scout; this early court has no Scholar), and Rovik
## Longstride, the war leader of renown who leads our band.
##
## Each named world below is built ONCE from a clean world through the real
## engine (the user's own orders where the world is the result of orders),
## then kept as an in-memory snapshot of every simulation autoload (the save
## system's own lists). A case restores its world in ~25 ms instead of
## rebuilding it (~1.5 s). self_check() proves a restore is faithful.
##
## WORLDS:
##   home_peace         at peace with the Esurai (Tsaren known, not held), no band out;
##                      12 trained at home and 20 called up, waiting for weapons and drill
##   home_charted       at peace, 12 trained at home, and the land around home charted by
##                      our scouts (a new town can be founded)
##   war_not_held       at war; Tsaren theirs; Rovik's band of 18 at home, 30 trained at home
##   tsaren_captured    Tsaren just taken: 17 of Rovik's band hold it, Rovik with 1 at the gate
##                      (a garrison a general leaves serves under the war leader at home, Suri)
##   tsaren_bound       ... and Rovik was told to round up and bind the men (the user's words)
##   tsaren_fled        ... and Rovik was told to kill the men: some died, the rest ran for Stonefield
##   tsaren_burned      bound, the bound killed, women and girls taken to Seanstone, Tsaren burned
##   old_build_bound    an old save: the garrison withdrawn but the ledger says 21 men bound
##                      (saved and loaded through the real save system on a temporary slot)
##   battle_won         a fight just won by Rovik's band at the ford: 12 captives and spoils settled
##   envoy_after_fall   Tsaren held; an Esurai envoy has come about Tsaren (town_return)
##   aim_suri           at war, Tsaren theirs; War Chief Suri holds a matter of aims for a generation
##   grain_lost         at peace; six days ago damp got into the grain pits and 600 Food rotted
##   feud_unfound       at peace with the Esurai; a blood feud with the Neyali, a small people whose
##                      envoy we killed: their raiders came forty days ago, nobody knows where they
##                      live, and Suri holds the matter of their raid (war_loop.gd feuds)
##
## Roles a case may speak to: headman, suri, kavu, imeri, rovik, envoy, aim.

const Save:=preload("res://scripts/save_system.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const AiMode:=preload("res://scripts/ai_mode.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Leaders:=preload("res://scripts/leader_commands.gd")

const NAMES:=["home_peace","home_charted","home_towns","war_not_held","tsaren_captured","tsaren_bound","tsaren_fled","tsaren_burned","old_build_bound","battle_won","envoy_after_fall","aim_suri","grain_lost","feud_unfound","ruvak_known"]

## The user's own words used to make the worlds.
const BIND_WORDS:="Round up all the men of Tsaren and tie them up. If any resist or attempt to flee, threaten their wives and children."
const KILL_BOUND_WORDS:="Kill all the men of Tsaren that you have tied up!"
const KILL_WORDS:="Kill all the men of Tsaren"
const TAKE_WORDS:="Take the women and girls of Tsaren to Seanstone"
const BURN_WORDS:="Burn Tsaren"

const SEED:=74017
const TSAREN_PEOPLE:=90.0
const OLD_BUILD_BOUND:=21
const TMP_SLOT_PREFIX:="__court_eval_tmp_"

var root:Node                 ## the suite (for /root lookups and SaveSystem)
var built:Dictionary={}       ## name -> {snap, info, audiences, notes}
var home:=Vector2.ZERO

func _init(suite:Node)->void:
	root=suite

func _land(_p:Vector2)->bool:
	return true

# --------------------------------------------------------------------------
# Snapshots
# --------------------------------------------------------------------------

func _node(name:String)->Node:
	return root.get_node("/root/"+name)

func snapshot()->Dictionary:
	var out:={}
	for name in Save.REFLECTED_SYSTEMS: out["r:"+name]=Save._capture_reflected(_node(name),Save.REFLECT_SKIP.get(name,[]))
	out["society"]=Save._capture_reflected(DiscoverySystem.society_model,Save.SOCIETY_REFLECT_SKIP)
	for name in Save.CURATED_SYSTEMS: out["c:"+name]=_node(name).export_state()
	return out

func restore(snap:Dictionary)->String:
	## Lays a snapshot back over the live autoloads. "" or the first error.
	WorldSimulation.flush_day()
	for name in Save.REFLECTED_SYSTEMS: Save._apply_reflected(_node(name),(snap["r:"+name] as Dictionary).duplicate(true))
	Save._apply_reflected(DiscoverySystem.society_model,(snap.society as Dictionary).duplicate(true),Save.SOCIETY_REFLECT_SKIP)
	for name in Save.CURATED_SYSTEMS:
		var r:Variant=_node(name).import_state((snap["c:"+name] as Dictionary).duplicate(true))
		if r is Dictionary and (r as Dictionary).has("error"): return "%s: %s %s" % [name,str((r as Dictionary).error),str((r as Dictionary).get("details","")).substr(0,400)]
	Route.clear_cache()
	Chronicle.pending_cards.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	return ""

func use(name:String)->Dictionary:
	## The world, restored; built first if this run has not built it yet.
	if not built.has(name): built[name]=_build(name)
	var w:Dictionary=built[name]
	if w.has("error"): return w
	var problem:=restore(w.snap)
	if problem!="": return {"error":"restore failed: "+problem}
	return w

# --------------------------------------------------------------------------
# The base world
# --------------------------------------------------------------------------

func base(at_war:bool=true)->Dictionary:
	AiMode.reset_for_tests("user://__court_eval_missing.cfg")
	# Nothing said here is ever written into the player's interaction records.
	AiMode.set_records_interactions(false,false)
	OS.unset_environment("LEVIATHAN_AI_READER_MODEL")
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1100
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	# The home settlement's own record carries the same name, as in play.
	if not GameState.player_settlements.is_empty(): SettlementModel.rename_settlement(String((GameState.player_settlements[0] as Dictionary).get("id","")),"Seanstone")
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=6000.0
	for res in ["Timber","Stone","Clay","Fiber Plants"]: GameState.resource_stockpiles[res]=300.0
	GameState.elapsed_days=95*365+20
	Route.clear_cache()
	var info:={}
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	var civ_id:=String(civ.id)
	info["civ_id"]=civ_id
	var relation:Dictionary=civ.player_relation
	relation.at_war=at_war; relation.contact_level=2; relation.home_location_known=true; relation.met_day=0
	# The world's own rule: a people at war with us is under the war treaty state.
	if at_war: relation.treaty="war"
	relation.opinion=-0.4 if at_war else 0.1
	relation.border_tension=0.7 if at_war else 0.2
	# Tsaren their chief town; Stonefield and Eldwick their others; the rest empty land.
	var ci:=CivilizationSystem._frontline_region_index(civ)
	var regions:Array=civ.strategic_regions
	for i in regions.size():
		var r:Dictionary=regions[i]
		r["settlement_founded"]=false; r["population"]=0.0; r["role"]="frontier"
	home=CivilizationSystem.player_world_origin
	var tsaren:Dictionary=regions[ci]
	tsaren.name="Tsaren"; tsaren.population=TSAREN_PEOPLE; tsaren.role="capital"; tsaren.settlement_founded=true
	tsaren["position"]=home+Vector2(-20.0,8.0)
	var si:=(ci+1)%regions.size()
	var stonefield:Dictionary=regions[si]
	stonefield.name="Stonefield"; stonefield.population=60.0; stonefield.settlement_founded=true
	stonefield["position"]=home+Vector2(-30.0,12.0)
	var ei:=(ci+2)%regions.size()
	var eldwick:Dictionary=regions[ei]
	eldwick.name="Eldwick"; eldwick.population=120.0; eldwick.settlement_founded=true
	eldwick["position"]=home+Vector2(-12.0,-30.0)
	civ.population=TSAREN_PEOPLE+180.0
	# Their age cohorts must add up to their people (the world's validator).
	civ["cohorts"]=CivilizationSystem._scaled_cohorts(civ.get("cohorts",{}),float(civ.population))
	info["tsaren_id"]=String(tsaren.id); info["stonefield_id"]=String(stonefield.id); info["eldwick_id"]=String(eldwick.id)
	var day:=int(GameState.elapsed_days)
	for pair in [[String(tsaren.id),tsaren.position],[String(stonefield.id),stonefield.position],[String(eldwick.id),eldwick.position]]:
		CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(pair[0]),.8,day-40,"scout report","test"),day-40)
		var at:Vector2=pair[1]
		CivilizationSystem.city_intelligence.records.player[String(pair[0])]["position"]={"x":at.x,"z":at.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	# A second people we know, at peace (so "the Esurai" is never the only people).
	if CivilizationSystem.civilizations.size()>1:
		var other:Dictionary=CivilizationSystem.civilizations[1]
		other["name"]="Varesh"
		(other.player_relation as Dictionary).contact_level=1
		info["varesh_id"]=String(other.id)
	# Their stores, for ransoms and prices.
	for res in ["Food","Timber"]: Hall.EXCHANGE.receive(civ_id,res,400.0)
	_name_the_court(info)
	return info

func _rename(pid:int,name:String)->void:
	var index:=GovernmentPeopleSystem._find_person_index(pid)
	if index<0: return
	GovernmentPeopleSystem.people[index]["name"]=name
	for key in GameState.leadership_positions:
		if int((GameState.leadership_positions[key] as Dictionary).get("person_id",0))==pid: GameState.leadership_positions[key]["name"]=name

## A town of ours founded beside the home town, as a caravan's arrival founds
## one (settlement_model.complete_settlement_convoy). Returns its record.
func second_town(name:String)->Dictionary:
	var primary:Dictionary=GameState.player_settlements[0]
	var sequence:=GameState.next_player_settlement_id
	var record:={"id":"settlement_%03d" % sequence,"sequence":sequence,"primary":false,"name":name,"position":(primary.position as Vector2)+Vector2(4.0+2.0*float(sequence),4.0),
		"population_share":0.2,"founded_day":int(GameState.elapsed_days),"status":"established","source_settlement_id":String(primary.id),
		"territory_context":{},"environment_profile":{},"auto_manage":true,"management_focus":"establishment","leader_person_id":0}
	GameState.next_player_settlement_id+=1
	GameState.player_settlements.append(record)
	SettlementModel._ensure_city_resources(record)
	GameState.settlement_network_revision+=1
	return record

func _name_the_court(info:Dictionary)->void:
	# The court at this stage has no Scholar: Imeri keeps the trails (Chief Scout).
	var names:={"Steward":["headman","Kishan of Reedwater"],"Marshal":["suri","Suri Ashvale"],"Quartermaster":["kavu","Kavu Dunmere"],"ChiefScout":["imeri","Imeri of Windgap"]}
	var pids:={}
	for office in names:
		var person:=GovernmentPeopleSystem.officeholder(String(office))
		if person.is_empty(): continue
		_rename(int(person.person_id),String(names[office][1]))
		pids[String(names[office][0])]=int(person.person_id)
	info["pids"]=pids

# --------------------------------------------------------------------------
# Forces
# --------------------------------------------------------------------------

func train(count:int)->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

func _rovik(army:Dictionary)->String:
	## The band's commander, renamed Rovik Longstride everywhere he is recorded.
	var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
	commander["name"]="Rovik Longstride"
	var fid:=String(commander.get("figure_id",""))
	if fid!="":
		var figure:Dictionary=HistoricalFigures.by_id(fid)
		if not figure.is_empty(): figure["name"]="Rovik Longstride"
	return fid

func band(troops:int,at_home:bool=true)->Dictionary:
	## Rovik's band, trained and standing ready. A new band serves under the
	## war leader at home (Suri) until the ruler puts it under a general; the
	## ruler put this one under Rovik, as the War screen and the Military
	## Leaders screen do (leader_commands.gd).
	train(troops)
	var made:=MilitaryCampaign.create_field_army(troops,"ROVIK'S BAND")
	if made.has("error"): return {"error":str(made)}
	var army_id:=int((made.army as Dictionary).army_id)
	var general:=Leaders.commission_general(MilitaryCampaign)
	if general.has("error"): return {"error":"no general for Rovik: "+str(general)}
	var put:=Leaders.assign(MilitaryCampaign,army_id,String(general.get("figure_id","")))
	if put.has("error"): return {"error":"Rovik could not take the band: "+str(put)}
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
	army["supply_level"]=1.0; army["readiness"]=1.0
	if at_home:
		army["position"]={"x":home.x+0.4,"z":home.y}
		army["status"]="stationed"
	_rovik(army)
	return army

func take_tsaren(info:Dictionary)->Dictionary:
	## Tsaren taken: 17 of Rovik's band hold it, one fighter still with Rovik.
	var army:=band(18,false)
	if army.has("error"): return army
	var city:Vector2=home+Vector2(-20.0,8.0)
	army["position"]={"x":city.x+0.3,"z":city.y}
	army["location_id"]=String(info.tsaren_id); army["location_name"]="Tsaren"; army["status"]="stationed"
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,String(info.tsaren_id))
	civ.strategic_regions[ri]["controller"]="player"
	civ.strategic_regions[ri]["resistance"]=0.6
	var factor:=maxf(.05,float(army.get("supply_level",1.0))*(.5+.5*clampf(float(army.get("readiness",.45))*.9,.15,1.0)))
	var garrison:=MilitaryCampaign.establish_occupation_force(String(info.civ_id),civ.strategic_regions[ri],floorf(17.0*factor),int(army.army_id))
	if int(garrison.get("troops",0))<=0: return {"error":"no garrison: "+str(garrison)}
	info["band_id"]=int(army.army_id)
	info["rovik_fid"]=String((army.commander as Dictionary).get("figure_id",""))
	# The 17 who hold it serve under the war leader at home (Suri): a garrison
	# a general leaves is the war leader's, and Rovik stays with his band
	# (military_campaign._garrison_captain).
	return army

func rovik_audience(info:Dictionary)->String:
	var audience:=Hall.summon({"figure_id":String(info.get("rovik_fid",""))})
	return String(audience.get("id",""))

# --------------------------------------------------------------------------
# The worlds
# --------------------------------------------------------------------------

func _build(name:String)->Dictionary:
	var info:={}
	var audiences:={}
	var notes:PackedStringArray=PackedStringArray()
	match name:
		"home_peace":
			info=base(false)
			train(12)
			# Twenty more called up and waiting for weapons and drill.
			MilitaryCampaign.raise_recruits(20)
		"home_charted":
			info=base(false)
			train(12)
			# Our scouts have charted the land around home: a new town can be
			# founded there (realm_orders.gd found_town).
			CivilizationSystem._add_revealed_area(home,45.0,"scout report")
		"home_towns":
			info=base(false)
			train(12)
			# Our second town, Reedmouth: our nation, unnamed, can now take a
			# name of its own (nation_name.gd).
			second_town("Reedmouth")
		"war_not_held":
			info=base(true)
			train(30)
			var army:=band(18,true)
			if army.has("error"): return army
			info["band_id"]=int(army.army_id); info["rovik_fid"]=String((army.commander as Dictionary).get("figure_id",""))
		"tsaren_captured":
			info=base(true)
			var army:=take_tsaren(info)
			if army.has("error"): return army
			train(10)
		"tsaren_bound","tsaren_fled","tsaren_burned":
			info=base(true)
			var army:=take_tsaren(info)
			if army.has("error"): return army
			train(10)
			var id:=rovik_audience(info)
			audiences["rovik"]=id
			var words:Array=[BIND_WORDS] if name=="tsaren_bound" else ([KILL_WORDS] if name=="tsaren_fled" else [BIND_WORDS,KILL_BOUND_WORDS,TAKE_WORDS,BURN_WORDS])
			for w in words:
				var r:=CC.hear(id,String(w))
				notes.append("%s -> %s/%s: %s" % [String(w),String(r.get("verb","")),String((r.get("war",{}) as Dictionary).get("verdict","")),String(r.get("actor_says","")).substr(0,160)])
			if name=="tsaren_burned":
				# The court at rest after the burning: the next business is new.
				Hall.conclude(id,"The war leader goes out.","concluded")
				audiences.erase("rovik")
		"old_build_bound":
			info=base(true)
			var army:=take_tsaren(info)
			if army.has("error"): return army
			train(10)
			var l:=Ledger.of(String(info.civ_id),String(info.tsaren_id))
			var moved:=Ledger.move(l,"free","bound","men",OLD_BUILD_BOUND)
			notes.append("ledger: moved %d men free->bound" % moved)
			# The old build pulled the garrison out and left the ledger as it was.
			MilitaryCampaign.remove_occupation_force(String(info.civ_id),String(info.tsaren_id),true)
			var problem:=_round_trip()
			if problem!="": return {"error":"save/load round trip: "+problem}
			notes.append("after load: held=%d bound=%d" % [WO.held_towns().size(),int(Ledger.counts(String(info.civ_id),String(info.tsaren_id)).get("bound_men",0))])
		"battle_won":
			info=base(true)
			train(20)
			var army:=band(18,true)
			if army.has("error"): return army
			info["band_id"]=int(army.army_id); info["rovik_fid"]=String((army.commander as Dictionary).get("figure_id",""))
			var day:=int(GameState.elapsed_days)
			var record:={"id":"b-ford","day":day-1,"home_side":"attacker","target_region_name":"the ford","outcome":"attacker_victory","winner":"attacker",
				"attacker":{"name":"Rovik's band","initial_troops":18,"remaining_troops":16,"dead":2,"commander":{"name":"Rovik Longstride"}},
				"defender":{"name":"Esurai band","initial_troops":30,"remaining_troops":6,"dead":14},
				"threat":{"source_name":"Esurai","source_civ_id":String(info.civ_id)},"seed":5,"termination":{"type":"surrender","prisoners":12}}
			MilitaryCampaign.battle_history.insert(0,record)
			MilitaryCampaign.set_aftermath_practice("prisoners","enslave")
			MilitaryCampaign.set_aftermath_practice("spoils","army stores")
			var settled:=MilitaryCampaign._settle_aftermath({"type":"surrender","captor":"Rovik's band","defeated":"Esurai band","home_force_name":"Rovik's band","prisoners":12,
				"spoils":{"supplies":40,"carts":1,"weapons":{"spear":6},"consumables":{},"wealth":0},"captured_general":false,"commander":"Tavo"},
				{"home_side":"attacker","attacker":{"name":"Rovik's band","commander":{"name":"Rovik Longstride"}},"defender":{"name":"Esurai band"},
				"threat":{"source_name":"Esurai","source_civ_id":String(info.civ_id)},"seed":5,"id":"b-ford"})
			notes.append("settled: "+String(settled.get("line","")))
			# The practice is the era's custom again: "from now on" is the ruler's to say.
			MilitaryCampaign.aftermath_practice.clear()
		"envoy_after_fall":
			info=base(true)
			var army:=take_tsaren(info)
			if army.has("error"): return army
			train(10)
			var audience:=Hall.debug_situation("town_return",String(info.civ_id))
			if audience.is_empty(): return {"error":"no envoy audience (town_return)"}
			audiences["envoy"]=String(audience.id)
			notes.append("envoy: %s, %s" % [String((audience.speaker as Dictionary).get("title","")),String((audience.situation as Dictionary).get("headline",""))])
		"feud_unfound":
			info=base(false)
			train(30)
			var army:=band(18,true)
			if army.has("error"): return army
			info["band_id"]=int(army.army_id); info["rovik_fid"]=String((army.commander as Dictionary).get("figure_id",""))
			var made:=_feud_people(info)
			if made!="": return {"error":made}
			notes.append("feud with %s: %s" % [String(info.feud_id),str((load("res://scripts/war_loop.gd") as GDScript).call("feud_view",String(info.feud_id)))])
		"ruvak_known":
			# At peace, a people named Ruvak we know well: their town charted,
			# their ruler named, their envoys received. The god's covert orders
			# (covert_orders.gd) can resolve and reach them.
			info=base(false)
			train(12)
			var made:=_ruvak_people(info)
			if made!="": return {"error":made}
		"grain_lost":
			info=base(false)
			train(12)
			# Six days ago the grain pits spoiled: the stores are 600 Food lighter
			# and the realm's notices carry it, as the simulation would record it.
			GameState.resource_stockpiles["Food"]=float(GameState.resource_stockpiles.get("Food",0.0))-600.0
			GameState.simulation_events.push_front({"day":int(GameState.elapsed_days)-6,"title":"Grain Stores Spoiled","description":"Damp got into the grain pits; 600 Food rotted and was lost.","domain":"economy","severity":"major"})
		"aim_suri":
			info=base(true)
			train(30)
			var army:=band(18,true)
			if army.has("error"): return army
			info["band_id"]=int(army.army_id); info["rovik_fid"]=String((army.commander as Dictionary).get("figure_id",""))
			var day:=int(GameState.elapsed_days)
			var cands:=Aims.propose(day)
			if cands.is_empty(): return {"error":"no aims proposed"}
			# War Chief Suri speaks for the first of them.
			var suri:=int((info.pids as Dictionary).get("suri",0))
			for c in cands: c["by_pid"]=suri
			var entry:=Aims.file_proposal(day,cands)
			if entry.is_empty(): return {"error":"no aim matter filed"}
			var opened:=Hall.open_matter(String(entry.id))
			if opened.is_empty(): return {"error":"aim matter did not open"}
			audiences["aim"]=String(opened.id)
			notes.append("aim audience: speaker %s; %d candidates" % [String((opened.speaker as Dictionary).get("name","")),cands.size()])
		_:
			return {"error":"unknown world "+name}
	if info.is_empty(): return {"error":"base world failed"}
	info["world"]=name
	return {"snap":snapshot(),"info":info,"audiences":audiences,"notes":notes}

func _feud_people(info:Dictionary)->String:
	## The Neyali: a small people whose envoy was killed at our court. A blood
	## feud (no war: conflict_scale.gd), their raiders came forty days ago, and
	## nobody knows where they live.
	if CivilizationSystem.civilizations.size()<3: return "no third people for the feud"
	var neyali:Dictionary=CivilizationSystem.civilizations[2]
	neyali["name"]="Neyali"
	var id:=String(neyali.id)
	info["feud_id"]=id
	var rel:Dictionary=neyali.player_relation
	rel.at_war=false; rel.treaty="none"; rel.contact_level=2; rel.met_day=0
	rel.home_location_known=false; rel.home_position={}
	rel.opinion=-0.5; rel.border_tension=0.7
	var war_loop:GDScript=load("res://scripts/war_loop.gd")
	if bool(war_loop.call("formal",id)): return "the Neyali are large enough for war"
	var day:=int(GameState.elapsed_days)
	(load("res://scripts/rival_rulers.gd") as GDScript).call("grudge",id,"how you slew our envoy Qira in your hall",1.0,"slain_envoy:fixture")
	war_loop.call("blood_feud",id,day-60,"the killing of their envoy Qira")
	var f:Dictionary=war_loop.call("front",id)
	f["pending"]={}
	war_loop.call("_raid",id,day-40,"vengeance",false)
	f["pending"]={}
	if not bool(war_loop.call("feuding",id)): return "the feud did not take"
	return ""

func _ruvak_people(info:Dictionary)->String:
	## A people named Ruvak the god knows well: at peace, their chief town
	## charted and their ruler named, so an assassin can be sent to their hall.
	if CivilizationSystem.civilizations.size()<2: return "no second people for Ruvak"
	var ruvak:Dictionary=CivilizationSystem.civilizations[1]
	ruvak["name"]="Ruvak"
	ruvak["population"]=420.0   # small: a feud, not a war (conflict_scale.gd)
	ruvak["cohorts"]=CivilizationSystem._scaled_cohorts(ruvak.get("cohorts",{}),420.0)
	var id:=String(ruvak.id)
	info["ruvak_id"]=id
	var rel:Dictionary=ruvak.player_relation
	rel.at_war=false; rel.treaty="none"; rel.contact_level=2; rel.met_day=0
	rel.home_location_known=true; rel.opinion=0.1; rel.border_tension=0.15
	# Their chief town, charted by our scouts, a short walk from home.
	var ci:=CivilizationSystem._frontline_region_index(ruvak)
	var regions:Array=ruvak.strategic_regions
	var town:Dictionary=regions[ci]
	town.name="Ruvaskel"; town.population=180.0; town.role="capital"; town.settlement_founded=true
	town["position"]=home+Vector2(26.0,-10.0)
	info["ruvak_town_id"]=String(town.id)
	var day:=int(GameState.elapsed_days)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(town.id),.75,day-20,"scout report","ruvak"),day-20)
	CivilizationSystem.city_intelligence.records.player[String(town.id)]["position"]={"x":town.position.x,"z":town.position.y}
	rel.home_position={"x":town.position.x,"z":town.position.y}
	# Their ruler is named (a character for the succession to pass to).
	(load("res://scripts/rival_rulers.gd") as GDScript).call("character",id)
	return ""

func _round_trip()->String:
	## Save and load through the real save system on a temporary slot (the
	## player's own saves are never touched), as an old save would come in.
	var saver:Node=_node("SaveSystem")
	var slot:=TMP_SLOT_PREFIX+str(OS.get_process_id())
	var saved:Dictionary=saver.save_game(slot)
	var path:String=saver.slot_path(slot)
	if saved.has("error"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return String(saved.error)
	var loaded:Dictionary=saver.load_game(slot)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path+".tmp"))
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	return String(loaded.get("error","")) if loaded.has("error") else ""

# --------------------------------------------------------------------------
# Who is who, and a digest for checking restores
# --------------------------------------------------------------------------

func role_pid(w:Dictionary,role:String)->int:
	return int(((w.info as Dictionary).get("pids",{}) as Dictionary).get(role,0))

func audience_for(w:Dictionary,role:String)->String:
	## The audience the ruler speaks in: the world's own (continuing), or a summons.
	var own:=String((w.audiences as Dictionary).get(role,""))
	if own!="":
		var a:=Hall.find(own)
		if not a.is_empty() and String(a.get("status",""))=="waiting": return own
	var info:Dictionary=w.info
	var target:={}
	match role:
		"rovik":
			if String(info.get("rovik_fid",""))=="": return ""
			target={"figure_id":String(info.rovik_fid)}
		"envoy","aim": return ""
		_:
			var pid:=role_pid(w,role)
			if pid<=0: return ""
			target={"person_id":pid}
	return String(Hall.summon(target).get("id",""))

func digest(w:Dictionary)->String:
	## What a restore must bring back exactly.
	var info:Dictionary=w.info
	var parts:Array=[]
	parts.append(int(GameState.elapsed_days)); parts.append(int(GameState.population_total))
	parts.append(snappedf(float(GameState.resource_stockpiles.get("Food",0.0)),0.01))
	for a in MilitaryCampaign.field_armies: parts.append("%d:%d:%s" % [int(a.army_id),int(a.troops),String(a.get("status",""))])
	for f in MilitaryCampaign.occupation_forces: parts.append("%s:%d" % [String(f.get("region_id","")),int(f.get("troops",0))])
	parts.append(Hall.state().get("queue",[]).size())
	for p in Hall._officials(): parts.append("%d:%s" % [int(p.person_id),String(p.get("name",""))])
	var civ_id:=String(info.get("civ_id","")); var city:=String(info.get("tsaren_id",""))
	if Ledger.has(civ_id,city): parts.append(JSON.stringify(Ledger.counts(civ_id,city)))
	parts.append(int(MilitaryCampaign.foreign_prisoners)); parts.append(MilitaryCampaign.settlements.size())
	return JSON.stringify(parts).md5_text()
