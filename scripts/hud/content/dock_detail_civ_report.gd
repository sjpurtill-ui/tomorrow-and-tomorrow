extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: the full known record for one foreign polity. Replaces the
## full-screen civilization report modal; everything shown is only what has
## physically returned as knowledge.

var civ_id:String=""

func _init(terrain_node:Node,hud_node:Control,target_civ_id:String="")->void:
	super._init(terrain_node,hud_node)
	civ_id=target_civ_id

func _civ()->Dictionary:
	for civ_variant in CivilizationSystem.civilizations:
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
	var intel:=clampf(float(relation.get("contact_intelligence",0.0)),0.0,1.0)
	var opinion:=clampf(float(relation.get("opinion",0.0)),-1.0,1.0)
	var kpis:Array=[
		{"label":"INTEL","value":"%d%%" % roundi(intel*100.0),"delta":"","accent":Tokens.AMBER,"tip":"Confidence of everything below"},
		{"label":"STANCE","value":_stance_text(opinion),"delta":"","accent":Tokens.TEAL,"tip":"Estimated disposition toward you"},
		{"label":"MET","value":"Day %d" % int(relation.get("met_day",0)),"delta":"","accent":Tokens.MUTED,"tip":"First confirmed contact"},
		{"label":"HOME","value":"located" if bool(relation.get("home_location_known",false)) else "unknown","delta":"","accent":Tokens.GREEN if bool(relation.get("home_location_known",false)) else Tokens.MUTED,"tip":"Whether a settlement has been physically located"},
	]
	var estimate_items:Array=[
		{"name":"Population","value":_estimate_text(civ.get("population",-1),intel,0.25),"ratio":intel,"color":Tokens.AMBER,"tip":"Estimated from observation; decays as reports age"},
		{"name":"Military","value":_estimate_text(civ.get("military_strength",-1),intel,0.45),"ratio":intel*0.8,"color":Tokens.RED,"tip":"Visible formations and inferred capability"},
		{"name":"Intent","value":_stance_text(opinion),"ratio":clampf(opinion*0.5+0.5,0.0,1.0),"color":Tokens.TEAL,"tip":"Read from encounters, envoys, and observed movement"},
	]
	var blocks:Array=[
		{"type":"bars","heading":"ESTIMATES","note":"intel %d%%" % roundi(intel*100.0),"items":estimate_items},
	]
	var provenance:="Contact via %s on day %d." % [String(relation.get("contact_source","observation")).replace("_"," "),int(relation.get("met_day",0))]
	if bool(relation.get("home_location_known",false)):
		provenance+="  Home settlement located (%s)." % String(relation.get("home_location_source","returned report"))
	blocks.append({"type":"text","heading":"PROVENANCE","text":provenance})
	var diplomatic_status:Dictionary=CivilizationSystem.diplomatic_mission_status()
	var mission_active:=bool(diplomatic_status.get("active",false))
	blocks.append({"type":"actions","items":[
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

func _stance_text(opinion:float)->String:
	if opinion>0.35: return "warm"
	if opinion>0.05: return "open"
	if opinion>-0.2: return "wary"
	return "hostile"

func _estimate_text(value:Variant,intel:float,threshold:float)->String:
	var amount:=float(value) if (value is float or value is int) else -1.0
	if amount<0.0 or intel<threshold: return "unknown"
	var low:=int(amount*(1.0-0.6*(1.0-intel)))
	var high:=int(amount*(1.0+0.6*(1.0-intel)))
	return "%s–%s" % [_compact(low),_compact(high)]

func _compact(amount:int)->String:
	if amount>=1000: return "%.1fk" % (float(amount)/1000.0)
	return str(amount)

func signature()->Array:
	var civ:=_civ()
	var relation:Dictionary=civ.get("player_relation",{})
	return [civ_id,float(relation.get("contact_intelligence",0.0)),float(relation.get("opinion",0.0)),bool(CivilizationSystem.diplomatic_mission_status().get("active",false))]
