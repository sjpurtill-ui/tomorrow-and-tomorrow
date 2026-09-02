extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: commission an institution for one government office.
## Candidates are institutional slates, not individuals; the chosen structure
## shapes how policy in that portfolio actually executes.

var office:String="Steward"

# What each governing structure is mechanically good and bad at. The "now"
# number is live: it is exactly the execution strength the doctrine would have
# in the realm's present condition, so no slate is best in every situation.
const DOCTRINE_NOTES:Dictionary={
	"directive":{"label":"DIRECTIVE","strength":"Strongest execution while legitimacy holds","risk":"Decays as legitimacy slips; obstructive below 25% · erodes council culture"},
	"federated":{"label":"FEDERATED","strength":"Gains strength with every federated settlement · steadies institutions","risk":"Modest while the realm is a single settlement"},
	"measured":{"label":"MEASURED","strength":"Identical output in every condition · feeds knowledge","risk":"Never exceeds its modest ceiling"},
	"representative":{"label":"ROTATING","strength":"Builds council culture and support","risk":"Capability arrives in waves as cohorts rotate"},
	"territorial":{"label":"TERRITORIAL","strength":"Holds strength across distance · aids logistics","risk":"Thin until the realm actually spreads"},
}

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
	var brief:Dictionary={"tone":"warn" if incumbent.is_empty() else "info","title":"Choose the structure, not a person" if incumbent.is_empty() else "Replacing the standing institution","why":"Each structure executes differently and its strength depends on the realm's present condition — legitimacy, settlements, spread, and time. The strongest structure today may not be the strongest next decade."}
	var blocks:Array=[]
	var society_model=DiscoverySystem.society_model
	var best_now:=-1.0
	for candidate_variant in terrain.leader_candidates:
		best_now=maxf(best_now,float(society_model.doctrine_execution_strength(String((candidate_variant as Dictionary).get("doctrine","")))))
	for candidate_index in terrain.leader_candidates.size():
		var candidate:Dictionary=terrain.leader_candidates[candidate_index]
		var candidate_name:=String(candidate.get("name","INSTITUTION"))
		var doctrine:=String(candidate.get("doctrine",""))
		var notes:Dictionary=DOCTRINE_NOTES.get(doctrine,{"label":"UNSTRUCTURED","strength":"","risk":""})
		var execution_now:=float(society_model.doctrine_execution_strength(doctrine))
		var execution_percent:=roundi(execution_now*100.0)
		blocks.append({"type":"rows","items":[{
			"name":candidate_name,
			"sub":String(candidate.get("background","")),
			"detail":"▲ %s\n▼ %s" % [String(notes.strength),String(notes.risk)],
			"value":"%s · now %s%d%%" % [String(notes.label),"+" if execution_percent>=0 else "−",absi(execution_percent)],
			"value_color":Tokens.GREEN if execution_now>=0.09 else (Tokens.RED if execution_now<0.0 else Tokens.AMBER),
			"accent":Tokens.GOLD if candidate_name==String(incumbent.get("name","")) else Tokens.BLUE,
			"tip":"Execution strength in the realm's current condition. It will move with legitimacy, settlements, territory, and rotation cycles — not a fixed aptitude.",
		}]})
		blocks.append({"type":"actions","items":[{
			"label":"COMMISSION","sub":"charge it with the portfolio","primary":execution_now>=best_now-0.005,
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
	# The "now" execution numbers move with legitimacy, settlements, and rotation
	# time, so the dock refreshes when any of those shift visibly.
	return [office,String((GameState.leadership_positions.get(office,{}) as Dictionary).get("name","")),terrain.leader_candidates.size(),roundi(clampf(float(GameState.simulation_metrics.get("legitimacy",0.62)),0.0,1.0)*50.0),GameState.player_settlements.size(),int(GameState.elapsed_days/30.0)]
