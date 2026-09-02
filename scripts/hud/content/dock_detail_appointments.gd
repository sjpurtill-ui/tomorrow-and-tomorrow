extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: commission an institution for one government office.
## Candidates are institutional slates, not individuals; the chosen structure
## shapes how policy in that portfolio actually executes.

var office:String="Steward"

func _init(terrain_node:Node,hud_node:Control,target_office:String="Steward")->void:
	super._init(terrain_node,hud_node)
	office=target_office
	terrain._generate_leader_candidates(office)

func meta()->Dictionary:
	return {
		"eyebrow":"GOVERNMENT · APPOINTMENT",
		"title":"%s Portfolio" % office,
		"subtabs":["CANDIDATE INSTITUTIONS"],
	}

func tab(_sub:int)->Dictionary:
	var incumbent:Dictionary=GameState.leadership_positions.get(office,{})
	var kpis:Array=[
		{"label":"OFFICE","value":office,"delta":"","accent":Tokens.GOLD,"tip":"The portfolio being commissioned"},
		{"label":"HOLDER","value":String(incumbent.get("name","vacant")).substr(0,14) if not incumbent.is_empty() else "vacant","delta":"","accent":Tokens.GREEN if not incumbent.is_empty() else Tokens.AMBER,"tip":"The institution currently charged with this portfolio"},
		{"label":"CANDIDATES","value":str(terrain.leader_candidates.size()),"delta":"slates","accent":Tokens.BLUE,"tip":"Institutional structures able to take the portfolio"},
		{"label":"EXECUTION","value":"−30%" if incumbent.is_empty() else "full","delta":"if vacant" if incumbent.is_empty() else "","accent":Tokens.RED if incumbent.is_empty() else Tokens.GREEN,"tip":"Vacant offices execute matching policy at reduced effect"},
	]
	var brief:Dictionary={"tone":"warn" if incumbent.is_empty() else "info","title":"Choose the structure, not a person" if incumbent.is_empty() else "Replacing the standing institution","why":"Each slate carries its own strengths and biases; policy in this portfolio will execute through it."}
	var blocks:Array=[]
	for candidate_index in terrain.leader_candidates.size():
		var candidate:Dictionary=terrain.leader_candidates[candidate_index]
		var candidate_name:=String(candidate.get("name","INSTITUTION"))
		var traits:Array=candidate.get("traits",[])
		var fit:=roundi(clampf(float(candidate.get("office_fit",0.5)),0.0,1.0)*100.0)
		var support:=roundi(clampf(float(candidate.get("support",0.5)),0.0,1.0)*100.0)
		blocks.append({"type":"rows","items":[{
			"name":candidate_name,
			"sub":"%s · %s" % [String(candidate.get("background","")),(" · ".join(PackedStringArray(traits))).to_lower()],
			"value":"fit %d%%" % fit,"value_color":Tokens.capacity_color(float(fit)),
			"accent":Tokens.GOLD if candidate_name==String(incumbent.get("name","")) else Tokens.BLUE,
			"tip":"Office fit %d%% · public support %d%%" % [fit,support],
		}]})
		blocks.append({"type":"actions","items":[{
			"label":"COMMISSION","sub":"charge it with the portfolio","primary":fit>=60,
			"disabled":candidate_name==String(incumbent.get("name","")),
			"on_press":func()->void: _commission(candidate_name),
			"tip":"Appoint %s to the %s portfolio" % [candidate_name,office],
		}]})
	if blocks.is_empty():
		blocks.append({"type":"text","text":"No institutional slate is available for this portfolio yet."})
	return {"kpis":kpis,"brief":brief,"blocks":blocks}

func _commission(candidate_name:String)->void:
	if AdvisorSystem.appoint(candidate_name,office):
		var topics:Dictionary={"Steward":"population","Quartermaster":"food","Scholar":"knowledge","Marshal":"security","Envoy":"resources"}
		AdvisorSystem.generate_council_item(office,String(topics.get(office,"construction")),0.58)
		terrain._report_military_action({"message":"%s commissioned for the %s portfolio." % [candidate_name,office]})
	hud.live_refresh_dock()

func signature()->Array:
	return [office,String((GameState.leadership_positions.get(office,{}) as Dictionary).get("name","")),terrain.leader_candidates.size()]
