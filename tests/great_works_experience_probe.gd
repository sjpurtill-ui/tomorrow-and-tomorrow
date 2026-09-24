extends Node
## Great Works experience probe (conceived wonders). Headless it checks:
##  - a wonder pitch (wonder_proposal) plays in the Audience Hall, the ruler
##    changes ambition, describes a vision, hears the odds in words (never a
##    number) and commissions it through GreatWorks.commission;
##  - a stage decision resolved in the hall changes the site exactly as
##    GreatWorks.decide() does;
##  - a collapse becomes a grave audience with the named dead;
##  - a triumph's dedication ceremony shows attendees with real gifts, conserves
##    goods, names the work and shows the allure rise;
##  - "Our Great Works" lists every work, hides foreign works until heard of,
##    enshrines from the screen, and restore/loot buttons run the real orders;
##  - dedicated works glow on the map and ruins get a subdued marker.
## Windowed (tools/run_isolated_gpu_probe.ps1) it writes captures to
## res://reports/great-works/.
##   <godot> --headless --path <worktree> res://tests/great_works_experience_probe.tscn

const Hall:=preload("res://scripts/audience_hall.gd")
const Works:=preload("res://scripts/great_works_audience.gd")
const Director:=preload("res://scripts/audience_director.gd")
const Atlas:=preload("res://scripts/hud/great_works_atlas.gd")
const MapVisual:=preload("res://scripts/undertaking_map_visual.gd")
const Dock:=preload("res://scripts/hud/content/dock_content_undertakings.gd")
const GW:=preload("res://scripts/great_works.gd")
const U:=preload("res://scripts/undertaking_system.gd")
const Concept:=preload("res://scripts/wonder_concept.gd")
const SEED:=515151
const KNOWN:=["masonry_bond_patterns","joinery","clay_shaping","public_stores","seed_selection","seasonal_patterns","drainage","festival_calendar","tallies","voussoir_arch_assembly","framed_construction"]

class TerrainDouble extends Node:
	var game_speed:=1.0
	var capture_render_active:=false
	var decrees:Array[String]=[]
	func _set_game_speed(speed:float)->void:game_speed=speed
	func issue_civic_directive_text(text:String)->void:decrees.append(text)
	func _blocking_modal_or_report_open()->bool:return false

var failures:Array[String]=[]
var capture:=false
var out_dir:=""
var samples:Array[String]=[]
var director:Node
var terrain:TerrainDouble
var city:Dictionary
var _colossus:Dictionary={}

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	for argument in OS.get_cmdline_user_args():
		if argument=="--no-capture":capture=false
	out_dir=ProjectSettings.globalize_path("res://reports/great-works/")
	if capture:DirAccess.make_dir_recursive_absolute(out_dir)
	_setup_world()
	terrain=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	director=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	if capture:
		get_window().size=Vector2i(1920,1080);get_window().content_scale_size=Vector2i(1920,1080)
		await _frames(2)
	HudTokens.set_color_mode("dark" if capture else "light")
	await _proposal_to_commission()
	await _stage_decision_matches_decide()
	await _collapse_scene()
	for mode in (["light","dark"] if capture else ["light"]):
		HudTokens.set_color_mode(mode)
		await _triumph_ceremony(mode)
	HudTokens.set_color_mode("light")
	await _works_screen()
	await _map_glow()
	for line in samples:print("GREAT_WORKS_SAMPLE ",line)
	if failures.is_empty():
		print("GREAT_WORKS_EXPERIENCE PASS")
		get_tree().quit(0)
	else:
		for failure in failures:printerr("GREAT_WORKS_EXPERIENCE FAIL: ",failure)
		get_tree().quit(1)

# ---------------------------------------------------------------- world

func _civ(id:String,civ_name:String,population:int,opinion:float,position:Vector2)->Dictionary:
	return {"id":id,"name":civ_name,"alive":true,"population":population,"food_days":60.0,"strategy":"commerce","aggression":.2,"world_position":position,"position":position,"strategic_regions":[],"relations":{},
		"player_relation":{"opinion":opinion,"border_tension":.1,"at_war":false,"treaty":"none","stance":"watchful","contact_level":2,"contact_intelligence":.1,"met_day":0,"home_location_known":true,"home_position":{"x":position.x,"z":position.y}}}

func _stock_actor(id:String,stone:float)->void:
	WorldSimulation.create_actor(id,SEED,Vector2(30,0));WorldSimulation.actors[id].controller="manual"
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.ensure_population_total(220);WorldSimulation.state.settlement_site_committed=true;WorldSimulation.state.settlement_name=id.capitalize()
		WorldSimulation.state.settlement_completed.assign(["Hearth Circle"])
		WorldSimulation.settlements.ensure_founded()
		WorldSimulation.food.receive_external_food(3000)
		for resource in ["Timber","Stone","Clay","Fiber Plants"]:WorldSimulation.state.resource_stockpiles[resource]=stone)

func _setup_world()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world();HistoricalFigures.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1100
	GameState.settlement_name="Ashmere";GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.known_discoveries.assign(KNOWN)
	GameState.population_health=.9;GameState.simulation_metrics.merge({"food_days":80.0,"food_intake_ratio":1.0,"security":.6,"cohesion":.72,"legitimacy":.64,"labor_efficiency":1.0,"food_consumption":90.0},true)
	GameState.population_allocations.merge({"Construction":40,"Crafting":14},true)
	GovernmentPeopleSystem.initialize()
	GovernmentPeopleSystem.government_stage=3
	GovernmentPeopleSystem.initialize(false)
	FoodSystem.receive_external_food(9000)
	for resource in ["Timber","Stone","Clay","Fiber Plants"]:GameState.resource_stockpiles[resource]=60000.0
	_stock_actor("rival_a",900);_stock_actor("rival_b",700)
	CivilizationSystem.civilizations.clear()
	CivilizationSystem.civilizations.append(_civ("rival_a","Kel Adun",260,.45,Vector2(30,0)))
	CivilizationSystem.civilizations.append(_civ("rival_b","Qingshan",420,.3,Vector2(0,30)))
	GameState.elapsed_days=400
	city=GameState.player_settlements[0]
	city["position"]=Vector2.ZERO

func _frames(count:int)->void:
	for i in count:await get_tree().process_frame

func _fail(text:String)->void:
	failures.append(text);printerr("GREAT_WORKS_EXPERIENCE FAIL: ",text)

func _wait_lines(modal:Control,id:String,minimum:int,limit:float=6.0)->void:
	var waited:=0.0
	while waited<limit:
		var lines:Array=Hall.find(id).get("lines",[])
		if lines.size()>=minimum and not modal.voice.busy(id):break
		await get_tree().process_frame;waited+=get_process_delta_time()
	modal.skip_reveal()
	await _frames(3)

func _sample(id:String,label:String)->void:
	for line in Hall.find(id).get("lines",[]):
		samples.append("%s | %s: %s" % [label,String(line.get("speaker","")) if not String(line.get("speaker","")).is_empty() else "narrator",String(line.get("text",""))])

func _no_numbers_in_odds(id:String,label:String)->void:
	var digits:=RegEx.new();digits.compile("\\d+\\s*%")
	for line in Hall.find(id).get("lines",[]):
		if digits.search(String(line.get("text","")))!=null:_fail("%s: a line spoke the odds as a number: %s" % [label,String(line.text)])

## No line is spoken twice in one audience or ceremony, and no speaker swears
## their oath twice in one scene.
func _no_repeats(lines:Array,label:String)->void:
	var seen:={}
	var oaths:={}
	var oath_pattern:=RegEx.create_from_string("^([^.!?]*!)")
	for line in lines:
		var text:=String((line as Dictionary).get("text","")).strip_edges()
		if seen.has(text.to_lower()):_fail("%s repeats a line: %s" % [label,text])
		seen[text.to_lower()]=true
		var found:=oath_pattern.search(text)
		if found==null or found.get_string(1).split(" ").size()>5:continue
		var key:=String((line as Dictionary).get("speaker",""))+"|"+found.get_string(1)
		if oaths.has(key):_fail("%s: %s swears \"%s\" twice" % [label,String(line.get("speaker","")),found.get_string(1)])
		oaths[key]=true

func _close_modal(modal:Control)->void:
	if not is_instance_valid(modal):return
	var dismiss:=modal.find_child("Dismiss",true,false) as Button
	if dismiss!=null:dismiss.pressed.emit()
	else:modal.make_them_wait()
	await _frames(2)

# ---------------------------------------------------------------- pitch → commission

func _proposal_to_commission()->void:
	var audience:=Works.proposal_audience({"trigger":{"kind":"victory","text":"We held the river crossing against Qingshan, and the people want it remembered."}})
	if audience.is_empty():_fail("no wonder proposal could be raised");return
	var id:=String(audience.id)
	var concepts:Array=(audience.get("wonder_proposal",{}) as Dictionary).get("concepts",[])
	if concepts.is_empty() or concepts.size()>3:_fail("proposal should carry 1–3 concepts, got %d" % concepts.size())
	var modal:Control=director.open_audience(id)
	await _frames(2)
	if terrain.game_speed!=0.0:_fail("proposal did not pause the simulation")
	var herald:=modal.find_child("HeraldTitle",true,false) as Label
	if herald==null or not ("WONDER" in herald.text or "GREAT WORK" in herald.text):_fail("proposal herald missing: %s" % (herald.text if herald else "none"))
	await _wait_lines(modal,id,3)
	var cards:=modal.find_child("Concepts",true,false)
	if cards==null or cards.get_child_count()!=concepts.size():_fail("concept cards %d of %d" % [cards.get_child_count() if cards else 0,concepts.size()])
	var odds:=modal.find_child("OddsWords",true,false) as Label
	if odds==null or odds.text.is_empty():_fail("the court's reckoning is not shown")
	elif RegEx.create_from_string("\\d").search(odds.text)!=null:_fail("the odds were shown as a number: %s" % odds.text)
	modal.choose_proposal({"ambition":"modest"})
	var before:=float(Works.assessment(Hall.find(id)).get("score",0))
	modal.choose_proposal({"ambition":"audacious"})
	var after:=float(Works.assessment(Hall.find(id)).get("score",0))
	if after>=before:_fail("audacious ambition did not lower the odds (%.3f -> %.3f)" % [before,after])
	var lines_before:=(Hall.find(id).get("lines",[]) as Array).size()
	modal.voice.weigh(id)
	await _wait_lines(modal,id,lines_before+2)
	if (Hall.find(id).get("lines",[]) as Array).size()<lines_before+2:_fail("the court did not weigh the audacious design")
	var described:Dictionary=modal.describe_vision("A colossal tower to watch the stars and read the seasons")
	if described.has("error"):_fail("describing a vision failed: %s" % described.error)
	var chosen:=Works.chosen_concept(Hall.find(id))
	if not bool(chosen.get("described_by_ruler",false)):_fail("the ruler's vision was not chosen")
	modal.choose_proposal({"chosen":0,"ambition":"grand"})
	await _frames(2)
	modal.weigh_clock=-1.0
	modal.skip_reveal()
	if capture:await _capture("pitch-wonder-dark")
	_no_numbers_in_odds(id,"pitch")
	_no_repeats(Hall.find(id).get("lines",[]),"pitch")
	_sample(id,"PITCH")
	var picked:=Works.chosen_concept(Hall.find(id))
	var count_before:=(city.get("undertakings",[]) as Array).size()
	var result:Dictionary=modal.choose("commission")
	if not bool(result.get("ok",false)):
		_fail("commission failed: %s" % result)
		await _close_modal(modal)
		return
	var r:Dictionary={}
	for record in city.get("undertakings",[]):
		if String((record as Dictionary).get("id",""))==Concept.with_ambition(String(picked.get("id","")),"grand"):r=record
	if (city.get("undertakings",[]) as Array).size()!=count_before+1 or r.is_empty():_fail("commission did not create the chosen work")
	elif String(r.get("status",""))!="building":_fail("commissioned work is not building")
	elif (r.get("architect",{}) as Dictionary).is_empty():_fail("no master builder was commissioned")
	await _wait_lines(modal,id,(Hall.find(id).get("lines",[]) as Array).size()+1,4.0)
	if capture:await _capture("pitch-commissioned-dark")
	print("GREAT_WORKS_EXPERIENCE pitch: %s at grand ambition -> %s" % [Works.concept_name(picked),String(result.get("outcome",""))])
	await _close_modal(modal)
	if terrain.game_speed==0.0:_fail("proposal modal did not release the pause")

# ---------------------------------------------------------------- stage decision

func _building_record()->Dictionary:
	for record in city.get("undertakings",[]):
		if String((record as Dictionary).get("status",""))=="building":return record
	return {}

func _stage_decision_matches_decide()->void:
	var r:=_building_record()
	if r.is_empty():_fail("no work under way for the stage decision");return
	r.progress=U.total_work(r)*.26;r.quality=float(r.progress);r.gates=[];r.erase("decision")
	U.advance_record(GameState,r,int(GameState.elapsed_days)+1,city)
	if (r.get("decision",{}) as Dictionary).is_empty():_fail("the design gate was not posed");return
	var snapshot:=r.duplicate(true)
	var metrics:=GameState.simulation_metrics.duplicate(true)
	var audience:=Hall.debug_force("great_work",String(r.id))
	if audience.is_empty():_fail("no great_work audience for the stage gate");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _frames(2)
	var herald:=modal.find_child("HeraldTitle",true,false) as Label
	if herald==null or not herald.text.begins_with("MASTER BUILDER"):_fail("architect herald wrong: %s" % (herald.text if herald else "none"))
	if modal.find_child("WorkChip",true,false)==null:_fail("progress chip missing")
	await _wait_lines(modal,id,3)
	var ids:Array=Hall.options(id).map(func(o:Dictionary)->String:return String(o.id))
	var engine_ids:Array=[]
	for pending:Dictionary in GW.pending_decisions():
		if String(pending.work_id)==String(r.id):engine_ids=(pending.options as Array).map(func(o:Dictionary)->String:return String(o.id))
	if ids!=engine_ids:_fail("hall options %s differ from the engine's %s" % [ids,engine_ids])
	if capture:await _capture("architect-audience-dark")
	_sample(id,"STAGE GATE")
	_no_repeats(Hall.find(id).get("lines",[]),"stage gate")
	var result:Dictionary=modal.choose("grander")
	if not bool(result.get("ok",false)):_fail("hall decision failed: %s" % result)
	var via_hall:=r.duplicate(true)
	var hall_metrics:=GameState.simulation_metrics.duplicate(true)
	await _wait_lines(modal,id,(Hall.find(id).get("lines",[]) as Array).size()+1,4.0)
	await _close_modal(modal)
	# Replay the same decision straight through the facade from the same state.
	r.clear();r.merge(snapshot.duplicate(true))
	GameState.simulation_metrics.clear();GameState.simulation_metrics.merge(metrics.duplicate(true))
	var direct:=GW.decide(String(city.id),String(r.id),"grander")
	if not bool(direct.get("ok",false)):_fail("direct decide failed: %s" % direct)
	if JSON.stringify(r)!=JSON.stringify(via_hall):_fail("the hall's decision changed the site differently than decide()")
	if JSON.stringify(GameState.simulation_metrics)!=JSON.stringify(hall_metrics):_fail("the hall's decision changed metrics differently than decide()")
	print("GREAT_WORKS_EXPERIENCE stage decision: hall == decide() (%s)" % String(result.get("outcome","")))

# ---------------------------------------------------------------- works on hand

func _add_work(form:String,purpose:String,ambition:String,token:String,fraction:float,title:String)->Dictionary:
	var id:=Concept.make_id(form,purpose,ambition,"stone",1,token)
	var d:=Concept.definition(id)
	var r:={"id":id,"status":"building","policy":"careful","progress":float(d.work)*fraction,"quality":float(d.work)*fraction,"condition":1.0,"strain":0,"stalled_days":0,"operating_days":0,"last_day":0,"started":0,"reason":"Crews at work.","legacy":"Unproven","gates":["design","stores","labor"],"decisions":[],"work_scale":1.0,"speed":1.0,"allure_scale":1.0,"custom_name":title,"shift":0.0,"feasibility":.6,
		"architect":{"id":"","name":"Oskadi Tallyhand","vision":.8,"ego":.8,"talent":.8,"style":"monumental","mood":0},
		"concept":{"name":title,"lore":"Born of the victory at the ford, a stone %s meant to %s for as long as the stone holds." % [form,String(Concept.PURPOSES[purpose].label)]}}
	var sites:=[{"position":Vector2(.2,.12),"angle":0.0},{"position":Vector2(-.2,.1),"angle":.4},{"position":Vector2(0,-.22),"angle":0.0},{"position":Vector2(.24,-.16),"angle":0.0},{"position":Vector2(-.22,-.18),"angle":.2}]
	r.site=sites[(city.get("undertakings",[]) as Array).size()%sites.size()]
	city.undertakings.append(r)
	return r

func _collapse_scene()->void:
	var r:=_add_work("tower","defy_gods","audacious","fall1",.9999,"The Weeping Stair of Ashmere")
	var food_before:=FoodSystem.total_stored()
	U.apply_outcome(GameState,r,city,int(GameState.elapsed_days),"collapse")
	var arrivals:=Works.daily(int(GameState.elapsed_days))
	var audience:={}
	for made in arrivals:
		if String((made.get("great_work",{}) as Dictionary).get("mode",""))=="outcome":audience=made
	if audience.is_empty():_fail("the collapse raised no audience");return
	var id:=String(audience.id)
	var dead:Array=(audience.great_work as Dictionary).get("dead",[])
	if dead.is_empty():_fail("the dead were not named")
	var modal:Control=director.open_audience(id)
	await _frames(2)
	var herald:=modal.find_child("HeraldTitle",true,false) as Label
	if herald==null or not "FALLEN" in herald.text:_fail("collapse herald wrong: %s" % (herald.text if herald else "none"))
	await _wait_lines(modal,id,3)
	if capture:await _capture("collapse-scene-dark")
	_sample(id,"COLLAPSE")
	_no_repeats(Hall.find(id).get("lines",[]),"collapse")
	var result:Dictionary=modal.choose("mourn")
	if not bool(result.get("ok",false)):_fail("mourning failed: %s" % result)
	if FoodSystem.total_stored()>=food_before:_fail("mourning did not pay the families from real stores")
	await _close_modal(modal)
	print("GREAT_WORKS_EXPERIENCE collapse: %s · dead %s" % [String((audience.great_work as Dictionary).get("ruin_name","")),dead])

# ---------------------------------------------------------------- ceremony

func _triumph_ceremony(mode:String)->void:
	var title:="The Dreadful Colossus of Ashmere" if mode=="light" else "Star-stair-that-Sees-the-Storm-Coming"
	var r:=_add_work("colossus" if mode=="light" else "stair","awe_rivals" if mode=="light" else "watch_heavens","audacious" if mode=="light" else "grand","ded"+mode,.9999,title)
	U.apply_outcome(GameState,r,city,int(GameState.elapsed_days),"triumph")
	var entry:={}
	for pending:Dictionary in GW.pending_ceremonies():
		if String(pending.work_id)==String(r.id):entry=pending
	if entry.is_empty():_fail("no ceremony pending after a triumph");return
	var attendees:Array=entry.get("attendees",[])
	if attendees.is_empty():_fail("no foreign envoys attend the dedication")
	var totals_before:=_gift_totals(attendees)
	var allure_before:=float(GW.allure_contribution().value)
	var view:Control=director.open_ceremony(String(r.id))
	if view==null:_fail("the ceremony did not open");return
	await _frames(3)
	if terrain.game_speed!=0.0:_fail("the ceremony did not pause the simulation")
	var waited:=0.0
	while view.pending_lines.size()<2 and waited<4.0:
		await get_tree().process_frame;waited+=get_process_delta_time()
	view.skip_reveal()
	await _frames(4)
	if view.envoy_cards.size()!=mini(attendees.size(),4):_fail("envoy cards %d of %d" % [view.envoy_cards.size(),attendees.size()])
	var gifted:=0
	for attendee:Dictionary in attendees:
		if not (attendee.get("gift",{}) as Dictionary).is_empty():gifted+=1
	if gifted>0 and view.find_child("GiftAmount",true,false)==null:_fail("gifts are not shown")
	var roles:={}
	for line in view.pending_lines:roles[String(line.get("role",""))]=true
	for role in ["narrator","architect","official","envoy"]:
		if not roles.has(role):_fail("the ceremony has no %s speech" % role)
	for line in view.pending_lines:samples.append("CEREMONY %s | %s: %s" % [mode,String(line.get("speaker","")) if not String(line.get("speaker","")).is_empty() else "narrator",String(line.get("text",""))])
	if capture:await _capture("ceremony-%s" % mode)
	var result:Dictionary=view.dedicate_with(title)
	if not bool(result.get("ok",false)):
		_fail("dedication failed: %s" % result)
		view.close()
		return
	await _frames(6)
	if String(U.display_name(r))!=title:_fail("the work was not named: %s" % U.display_name(r))
	var totals_after:=_gift_totals(attendees)
	for resource in totals_before:
		var before_pair:Array=totals_before[resource]
		var after_pair:Array=totals_after[resource]
		if absf((float(after_pair[0])+float(after_pair[1]))-(float(before_pair[0])+float(before_pair[1])))>.01:_fail("%s gifts were not conserved: %s -> %s" % [resource,before_pair,after_pair])
		if float(after_pair[0])<=float(before_pair[0]):_fail("no %s arrived in our stores" % resource)
	var allure_after:=float(GW.allure_contribution().value)
	if allure_after<=allure_before:_fail("allure did not rise with the dedication")
	if view.find_child("ChronicleLine",true,false)==null:_fail("no chronicle line shown")
	if capture:
		var settle:=0.0
		while view.pending_lines.size()>view.lines_shown or settle<1.0:
			view.skip_reveal();await get_tree().process_frame;settle+=get_process_delta_time()
			if settle>4.0:break
		await _capture("ceremony-%s-dedicated" % mode)
	_no_repeats(view.pending_lines,"ceremony %s" % mode)
	for line in view.pending_lines.slice(maxi(0,view.pending_lines.size()-2)):samples.append("NAMED %s | %s: %s" % [mode,String(line.get("speaker","")),String(line.get("text",""))])
	print("GREAT_WORKS_EXPERIENCE ceremony %s: %s · envoys %d · allure %.1f -> %.1f · %s" % [mode,title,attendees.size(),allure_before,allure_after,String(result.get("message",""))])
	view.close()
	await _frames(2)
	if terrain.game_speed==0.0:_fail("the ceremony did not release the pause")
	if mode=="light":_colossus=r

## {resource:[our stock, attending civs' combined stock]} for every gifted resource.
func _gift_totals(attendees:Array)->Dictionary:
	var result:={}
	for attendee:Dictionary in attendees:
		var gift:Dictionary=attendee.get("gift",{})
		if gift.is_empty():continue
		result[String(gift.resource)]=[0.0,0.0]
	for resource in result:
		var pair:Array=result[resource]
		pair[0]=float(GameState.resource_stockpiles.get(resource,0))
		for attendee:Dictionary in attendees:
			var owner_id:=String(attendee.civ_id)
			pair[1]=float(pair[1])+float(WorldSimulation.scoped(owner_id,func()->float:return float(WorldSimulation.state.resource_stockpiles.get(resource,0))))
	return result

# ---------------------------------------------------------------- works screen

func _works_screen()->void:
	if _colossus.is_empty():_fail("no dedicated work to show on the works screen");return
	# A foreign work nobody has told us about stays hidden.
	var secret_id:=Concept.make_id("tower","awe_rivals","grand","stone",1,"sec1")
	var secret_work:=float(Concept.definition(secret_id).work)
	var secret:={"id":secret_id,"status":"functioning","progress":secret_work,"quality":secret_work,"condition":1.0,"strain":0,"stalled_days":0,"operating_days":0,"last_day":0,"started":0,"reason":"","legacy":"","gates":[],"decisions":[],"work_scale":1.0,"speed":1.0,"allure_scale":1.0,"custom_name":"The Secret Spire of Kel","outcome":"success"}
	WorldSimulation.scoped("rival_a",func()->void:
		var rival_city:Dictionary=WorldSimulation.state.player_settlements[0]
		if not rival_city.has("undertakings"):rival_city.undertakings=[]
		rival_city.undertakings.append(secret))
	var atlas:Control=Atlas.open(self,terrain,director)
	await _frames(3)
	var ours:=GW.works()
	var list:=atlas.find_child("WorkList",true,false)
	if list==null or list.get_child_count()!=ours.size():_fail("works screen lists %d of %d works" % [list.get_child_count() if list else 0,ours.size()])
	for item:Dictionary in ours:
		atlas.select("player/%s/%s" % [String(item.city_id),String(item.work_id)])
		await _frames(1)
	var colossus_key:="player/%s/%s" % [String(city.id),String(_colossus.get("id",""))]
	atlas.select(colossus_key)
	await _frames(3)
	if _text_of(atlas).contains("VICTORY") or _text_of(atlas).contains("Victory"):_fail("the works screen speaks of victory")
	if capture:await _capture("works-ours-light")
	atlas.tab="foreign";atlas.selected_key="";atlas.refresh()
	await _frames(2)
	if _text_of(atlas).contains("Secret Spire"):_fail("an unheard-of foreign work was shown")
	secret["heard_by"]={"player":{"day":int(GameState.elapsed_days)-12,"condition":1.0,"strain":0}}
	atlas.refresh()
	await _frames(2)
	if not _text_of(atlas).contains("Secret Spire"):_fail("a foreign work heard of from travelers is missing")
	if not _text_of(atlas).contains("As of day"):_fail("the foreign work is not dated")
	if capture:await _capture("works-foreign-light")
	# Enshrine from the screen.
	atlas.tab="ours";atlas.select(colossus_key)
	await _frames(2)
	var artifact:={"id":"probe-jar","name":"Clay storage jar · etched river","kind":"artifact","catalogue_id":12,"artifact_origin":"civilization","source_id":"neighbor","source_name":"Neighbor","discovery_id":"clay_shaping","rarity":1,"study":1.0}
	GameState.society_exchange.collections[String(artifact.id)]=artifact
	atlas.refresh();await _frames(2)
	var slot:=atlas.find_child("Enshrine_0",true,false) as Button
	if slot==null:_fail("no empty shrine place on a dedicated work")
	else:
		slot.pressed.emit()
		await _frames(2)
		if atlas.enshrine_candidates().filter(func(item:Dictionary)->bool:return String(item.get("id",""))=="probe-jar").is_empty():_fail("the held artifact is not offered for enshrining")
		var answer:Dictionary=atlas.enshrine(String(_colossus.id),String(city.id),"probe-jar")
		if not bool(answer.get("ok",false)):_fail("enshrine failed: %s" % answer)
		if not "probe-jar" in (GW.site(String(city.id),String(_colossus.id)).get("enshrined",[]) as Array):_fail("the artifact is not enshrined")
	# Restore runs the real order.
	_colossus.condition=.6
	atlas.refresh();await _frames(2)
	var restore:=atlas.find_child("RestoreButton",true,false) as Button
	if restore==null:_fail("no restore button on a worn work")
	else:
		restore.pressed.emit();await _frames(2)
		if float(_colossus.condition)<=.6:_fail("restore did not repair the work: %s" % atlas.message)
	# Loot: a work in a city our armies hold.
	WorldSimulation.scoped("rival_a",func()->void:
		var rival_city:Dictionary=WorldSimulation.state.player_settlements[0]
		rival_city["occupied_by"]="human"
		var treasure:={"id":"kel-idol","name":"Painted idol · Kel","kind":"artifact","catalogue_id":6,"artifact_origin":"civilization","source_id":"x","discovery_id":"clay_shaping","study":1.0}
		WorldSimulation.state.society_exchange.collections[String(treasure.id)]=treasure
		secret["enshrined"]=["kel-idol"])
	atlas.tab="foreign";atlas.selected_key="";atlas.refresh();await _frames(2)
	var loot:=atlas.find_child("LootButton",true,false) as Button
	if loot==null:_fail("no loot button for a work in an occupied city")
	else:
		loot.pressed.emit();await _frames(2)
		if not GameState.society_exchange.collections.has("kel-idol"):_fail("loot did not carry the treasure off: %s" % atlas.message)
	if atlas.find_child("ConceiveButton",true,false)==null:_fail("no conceive button on the works screen")
	print("GREAT_WORKS_EXPERIENCE works screen: %d works · %s" % [ours.size(),atlas.message])
	atlas.close()
	await _frames(2)
	var dock:=Dock.new(terrain,null)
	var tab:Dictionary=dock._local(String(city.id))
	if (tab.get("blocks",[]) as Array).is_empty():_fail("the dock shows nothing")

func _text_of(node:Node)->String:
	var parts:PackedStringArray=PackedStringArray()
	if node is Label:parts.append((node as Label).text)
	if node is Button:parts.append((node as Button).text)
	for child in node.get_children():parts.append(_text_of(child))
	return "\n".join(parts)

# ---------------------------------------------------------------- map glow

func _map_glow()->void:
	var parent:=Node3D.new();parent.name="MapProbe";add_child(parent)
	MapVisual.render([city],parent,func(_x:float,_z:float)->float:return 0.0)
	var halos:=0
	var scars:=0
	for root in parent.get_children():
		if root.get_node_or_null("Halo")==null:continue
		var label:=root.get_node_or_null("Name") as Label3D
		if label!=null and label.text.contains("Dedicated"):halos+=1
		else:scars+=1
	if halos<1:_fail("no dedicated work glows on the map")
	if scars<1:_fail("the ruin has no subdued marker")
	if capture:
		var env:=WorldEnvironment.new();var environment:=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("1c2430")
		environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color(.7,.7,.75);environment.ambient_light_energy=.7;env.environment=environment;parent.add_child(env)
		var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(2,2);ground.mesh=plane
		var ground_material:=StandardMaterial3D.new();ground_material.albedo_color=Color("56603f");ground.material_override=ground_material;parent.add_child(ground)
		var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,30,0);sun.light_energy=.6;parent.add_child(sun)
		var camera:=Camera3D.new();camera.fov=38;camera.near=.005;parent.add_child(camera)
		camera.look_at_from_position(Vector3(0,.22,.5),Vector3(0,0,-.02))
		camera.current=true
		await _frames(6)
		await _capture("map-glow")
	print("GREAT_WORKS_EXPERIENCE map: %d glowing, %d ruin markers" % [halos,scars])
	parent.queue_free()

func _capture(label:String)->void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	var path:=out_dir+"great-works-"+label+".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("GREAT_WORKS_EXPERIENCE capture ",path)
