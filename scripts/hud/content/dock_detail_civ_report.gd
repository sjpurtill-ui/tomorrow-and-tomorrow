extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: the full known record for one foreign polity. Replaces the
## full-screen civilization report modal; everything shown is only what has
## physically returned as knowledge.

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
		"eyebrow":"KNOWN RECORD · CONTACT",
		"title":String(civ.get("name","Unknown polity")),
		"subtabs":["THE RECORD"],
	}

func tab(_sub:int)->Dictionary:
	var civ:=_civ()
	if civ.is_empty():
		return {"kpis":[],"brief":{},"blocks":[{"type":"text","text":"No record exists for this polity."}]}
	var relation:Dictionary=civ.get("player_relation",{})
	var met_day:=int(relation.get("met_day",-1))
	var observed:=maxi(met_day,int(relation.get("last_observed_day",-1)))
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player",civ_id):observed=maxi(observed,int(city.get("observed_day",-1)))
	var age:=maxi(0,int(GameState.elapsed_days)-observed) if observed>=0 else -1
	var kpis:Array=[
		{"label":"LAST REPORT","value":"Date unknown" if age<0 else ("Today" if age==0 else "%d days ago"%age),"delta":"","accent":Tokens.AMBER,"tip":"Age of the latest returned observation. Details may have changed."},
		{"label":"FIRST CONTACT","value":"Day %d"%(met_day%365+1) if met_day>=0 else "Unknown","delta":"Year %d"%(met_day/365+1) if met_day>=0 else "","accent":Tokens.MUTED},
		{"label":"HOME","value":"Located" if bool(relation.get("home_location_known",false)) else "Unlocated","delta":"","accent":Tokens.GREEN if bool(relation.get("home_location_known",false)) else Tokens.MUTED},
	]
	var estimate_items:Array=[
		{"name":"People in observed settlements","value":_reported_range(civ,"population"),"detail":"Only returned city observations; not a census of the whole society."},
		{"name":"Reported garrisons","value":_reported_range(civ,"military"),"detail":"A dated count, not their complete army or current readiness."},
		{"name":"Their intentions","value":"War declared" if bool(relation.get("at_war",false)) else "Uncertain","detail":"A leader's words and observed actions are evidence; motives are not directly known."},
	]
	var blocks:Array=[{"type":"rows","heading":"WHAT THE REPORTS ESTABLISH","items":estimate_items}]
	var source:=String(relation.get("contact_source",""))
	var provenance:="Our scouts brought back the encounter report." if source=="returned_scout_report" else ("Our lookouts made direct contact." if source=="local_formation" else "An earlier encounter account establishes this contact.")
	if met_day>=0:provenance+=" First contact: year %d, day %d."%[met_day/365+1,met_day%365+1]
	if bool(relation.get("home_location_known",false)):
		var home_source:=String(relation.get("home_location_source",""))
		provenance+=" A returning search party located the settlement." if home_source=="returned contact investigation" else " Its settlement is marked in an earlier location report."
	blocks.append({"type":"text","heading":"HOW WE KNOW","text":provenance})
	if not bool(relation.get("home_location_known",false)):
		var proposal:=CivilizationSystem.contact_investigation_proposal(civ_id)
		blocks.push_front({"type":"text","heading":"A PATH TO THEIR LEADER","text":String(proposal.get("message",proposal.get("error","")))})
		blocks.push_front({"type":"actions","items":[{"label":"ASK SCOUTS TO FIND THEIR SETTLEMENT","disabled":proposal.has("error"),"on_press":func():investigation_result=CivilizationSystem.investigate_known_contact(civ_id);hud.request_immediate_dock_refresh()}]})
	if not investigation_result.is_empty():blocks.push_front({"type":"text","heading":"EXPEDITION REPORT","text":String(investigation_result.get("message",investigation_result.get("error","")))})
	var diplomatic_status:Dictionary=CivilizationSystem.diplomatic_mission_status()
	var mission_active:=bool(diplomatic_status.get("active",false))
	blocks.append({"type":"actions","items":[
		{"label":"SPEAK WITH THEIR LEADER","sub":"Establish an audience, then discuss objectives","primary":true,"on_press":func():terrain._set_game_speed(0);ForeignDiplomacy.open(civ_id)},
		{"label":"SHOW HOME ON MAP","sub":"focus the reported settlement and its name",
		"disabled":not bool(relation.get("home_location_known",false)),
		"on_press":func()->void:
			hud.close_detail(); hud.close_dock()
			terrain._focus_known_world_point(civ_id,"settlement"),
		"tip":"Uses the reported home location; surrounding unknown terrain remains hidden."},
		{"label":"SEND DIPLOMAT","sub":"goodwill delegation","primary":true,
		"disabled":mission_active or not bool(relation.get("home_location_known",false)),
		"on_press":func()->void: terrain._open_diplomat_dispatch_panel(civ_id),
		"tip":"A physical delegation travels to the located settlement" if bool(relation.get("home_location_known",false)) else "Locate the polity's home settlement first"},
		{"label":"INVESTIGATE","sub":"scout the encounter site",
		"disabled":bool(CivilizationSystem.exploration_status().get("active",false)),
		"on_press":func()->void: terrain._open_scout_dispatch_panel(),
		"tip":"Send scouts back toward the known encounter position"},
	]})
	return {"kpis":kpis,"brief":{},"blocks":blocks}

func _reported_range(civ:Dictionary,prefix:String)->String:
	if not civ.has(prefix+"_estimate_low") or not civ.has(prefix+"_estimate_high"):return "Not yet observed"
	return "%s–%s"%[_compact(int(civ[prefix+"_estimate_low"])),_compact(int(civ[prefix+"_estimate_high"]))]

func _compact(amount:int)->String:
	if amount>=1000: return "%.1fk" % (float(amount)/1000.0)
	return str(amount)

func signature()->Array:
	var civ:=_civ()
	var relation:Dictionary=civ.get("player_relation",{})
	return [int(GameState.elapsed_days),civ_id,investigation_result.hash(),CivilizationSystem.scout_missions.size(),bool(relation.get("home_location_known",false)),float(relation.get("contact_intelligence",0.0)),float(relation.get("opinion",0.0)),bool(CivilizationSystem.diplomatic_mission_status().get("active",false))]
