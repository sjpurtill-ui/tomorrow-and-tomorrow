extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: the full known record for one foreign polity. Replaces the
## full-screen civilization report modal; everything shown is only what has
## physically returned as knowledge.

const EraWords:=preload("res://scripts/hud/era_words.gd")
const P:=preload("res://scripts/hud/paper_sheet.gd")

var civ_id:String=""
var investigation_result:Dictionary={}

func _init(terrain_node:Node,hud_node:Control,target_civ_id:String="")->void:
	super._init(terrain_node,hud_node)
	civ_id=target_civ_id

func _civ()->Dictionary:
	for civ_variant in CivilizationSystem.known_competition_snapshot().get("leaders",[]):
		var civ:Dictionary=civ_variant
		if String(civ.get("id",""))==civ_id: return civ
	return {}

func meta()->Dictionary:
	var civ:=_civ()
	return {
		"eyebrow":"What we know",
		"title":String(civ.get("name","Unknown people")),
		"subtabs":["The record"],
	}

## The one way to speak with this people: their ruler, in the court.
func talk_label()->String:
	var ruler:=P.ruler_name(civ_id)
	return "Talk to %s" % P.first_name(ruler) if ruler!="" else "Send word to their ruler"

func tab(_sub:int)->Dictionary:
	var civ:=_civ()
	if civ.is_empty():
		return {"kpis":[],"brief":{},"blocks":[{"type":"text","text":"We have no record of this people."}]}
	var relation:Dictionary=civ.get("player_relation",{})
	var met_day:=int(relation.get("met_day",-1))
	var observed:=maxi(met_day,int(relation.get("last_observed_day",-1)))
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player",civ_id):observed=maxi(observed,int(city.get("observed_day",-1)))
	var home_known:=bool(relation.get("home_location_known",false))
	var kpis:Array=[
		{"label":"Last word","value":"Unknown" if observed<0 else _first_up(EraWords.ago(observed)),"delta":"","accent":Tokens.AMBER,"tip":"When the latest account of them came home. Things may have changed since."},
		{"label":"First met","value":EraWords.when(met_day) if met_day>=0 else "Unknown","delta":"","accent":Tokens.MUTED},
		{"label":"Their home","value":"Found" if home_known else "Not yet found","delta":"","accent":Tokens.GREEN if home_known else Tokens.MUTED},
	]
	var estimate_items:Array=[
		{"name":"People in the places we saw","value":_reported_range(civ,"population"),"detail":"Only what our scouts saw; not a count of the whole people."},
		{"name":"Fighters seen","value":_reported_range(civ,"military"),"detail":"What was seen on one visit, not their whole strength."},
		{"name":"What they intend","value":_intent(civ_id,relation),"detail":"We judge by what their ruler says and does; we cannot see their minds."},
	]
	var blocks:Array=[{"type":"rows","heading":"What the reports say","items":estimate_items}]
	var towns:=towns_block(civ_id)
	if not towns.is_empty(): blocks.append(towns)
	var source:=String(relation.get("contact_source",""))
	var provenance:="Our scouts brought back word of them." if source=="returned_scout_report" else ("Our lookouts met them directly." if source=="local_formation" else "An earlier account tells of this meeting.")
	if met_day>=0:provenance+=" We first met them in %s." % EraWords.when(met_day)
	if home_known:
		var home_source:=String(relation.get("home_location_source",""))
		provenance+=" A returning search party found where they live." if home_source=="returned contact investigation" else " An earlier account marks where they live."
	blocks.append({"type":"text","heading":"How we know","text":provenance})
	if not home_known:
		var proposal:=CivilizationSystem.contact_investigation_proposal(civ_id)
		blocks.push_front({"type":"text","heading":"Finding their home","text":String(proposal.get("message",proposal.get("error","")))})
		blocks.push_front({"type":"actions","items":[{"label":"Ask scouts to find their home","disabled":proposal.has("error"),"on_press":func():investigation_result=CivilizationSystem.investigate_known_contact(civ_id);hud.request_immediate_dock_refresh()}]})
	if not investigation_result.is_empty():blocks.push_front({"type":"text","heading":"The search party","text":String(investigation_result.get("message",investigation_result.get("error","")))})
	blocks.append({"type":"actions","items":[
		{"label":talk_label(),"sub":"In court, through your envoys","primary":true,"on_press":court({"civ_id":civ_id})},
		{"label":"Show their home on the map","sub":"Where our people last saw it",
		"disabled":not home_known,
		"on_press":func()->void:
			hud.close_detail(); hud.close_dock()
			terrain._focus_known_world_point(civ_id,"settlement"),
		"tip":"Only the place itself is shown; the land around it stays unknown." if home_known else "Our people have not found where they live yet."},
	]})
	return {"kpis":kpis,"brief":{},"blocks":blocks}

## Their towns as we know them: the ones we hold, the ones burned, the ones
## our people have seen that they still hold, and a plain line saying where
## they still live. {} when we know of none.
static func towns_block(target_civ_id:String)->Dictionary:
	var world:Variant=WorldSimulation.world
	if world==null: return {}
	var index:int=world._civilization_index(target_civ_id)
	if index<0: return {}
	var civ:Dictionary=world.civilizations[index]
	var items:Array=[]
	var still:PackedStringArray=PackedStringArray()
	var unseen:=0
	for r in civ.get("strategic_regions",[]):
		var region:Dictionary=r
		var name:=String(region.get("name",""))
		var capital:=String(region.get("role",""))=="capital"
		var held:=String(region.get("controller",""))=="player"
		var governance:Dictionary=region.get("governance",{}) if region.get("governance") is Dictionary else {}
		var burned:=bool(governance.get("ruined",false)) and float(region.get("damage",0.0))>=1.0
		var town:=bool(region.get("settlement_founded",true)) and float(region.get("population",0.0))>=1.0
		var known:=world.city_intelligence!=null and not (world.city_intelligence.known("player",String(region.get("id",""))) as Dictionary).is_empty()
		if not held and not burned and not town: continue
		if not held and not burned and not known:
			unseen+=1
			continue
		var status:="Ours: our garrison holds it" if held else ("Burned" if burned and not town else "Theirs")
		if not held and town: still.append(name)
		items.append({"name":name,"value":status,"detail":"Their chief town." if capital else ""})
	if items.is_empty() and unseen==0: return {}
	var civ_name:=String(civ.get("name","They"))
	var line:=""
	if not still.is_empty(): line="%s still holds %s." % [civ_name,", ".join(still)]
	elif unseen>0: line="%s still lives in a town we have not seen." % civ_name if unseen==1 else "%s still lives in towns we have not seen." % civ_name
	else: line="%s holds no town that we know of." % civ_name
	if unseen>0 and not still.is_empty(): line+=" They hold %s more our people have not seen." % ("one" if unseen==1 else str(unseen))
	return {"type":"rows","heading":"Their towns","items":items+[{"name":"Where they live now","value":"","detail":line}]}

## "At war with us", "In a feud with us" (a small people's fight, never a war:
## war_loop.gd) or "Uncertain".
static func _intent(target_civ_id:String,relation:Dictionary)->String:
	var war_loop:GDScript=load("res://scripts/war_loop.gd")
	if war_loop!=null and bool(war_loop.call("feuding",target_civ_id)) and bool(war_loop.call("hot",target_civ_id)): return "In a feud with us: their raiders come"
	return "At war with us" if bool(relation.get("at_war",false)) else "Uncertain"

func _reported_range(civ:Dictionary,prefix:String)->String:
	if not civ.has(prefix+"_estimate_low") or not civ.has(prefix+"_estimate_high"):return "Not yet observed"
	return "%s–%s"%[_compact(int(civ[prefix+"_estimate_low"])),_compact(int(civ[prefix+"_estimate_high"]))]

func _compact(amount:int)->String:
	if amount>=1000: return "%.1fk" % (float(amount)/1000.0)
	return str(amount)

func signature()->Array:
	var civ:=_civ()
	var relation:Dictionary=civ.get("player_relation",{})
	return [int(GameState.elapsed_days),civ_id,investigation_result.hash(),CivilizationSystem.scout_missions.size(),bool(relation.get("home_location_known",false)),float(relation.get("contact_intelligence",0.0)),float(relation.get("opinion",0.0)),bool(CivilizationSystem.diplomatic_mission_status().get("active",false)),towns_block(civ_id).hash()]

static func _first_up(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)
