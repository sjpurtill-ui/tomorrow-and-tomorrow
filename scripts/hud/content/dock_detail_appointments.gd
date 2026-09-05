extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: appoint an actual person to one evolving government office.

var office:String="Steward"

# What each governing style is reputed to do well and badly. These descriptions
# expose the nature of a tradeoff without collapsing it into a numerical answer.
const DOCTRINE_NOTES:Dictionary={
	"directive":{"label":"DIRECTIVE","strength":"inclined to decide quickly when authority is accepted","risk":"may harden opposition and fail badly when legitimacy is weak"},
	"federated":{"label":"FEDERATED","strength":"inclined to bargain with local leaders and preserve their cooperation","risk":"may be slow or indecisive while only one settlement bears the work"},
	"measured":{"label":"METHODICAL","strength":"inclined to demand records and repeatable procedure","risk":"may remain cautious when an exceptional response is needed"},
	"representative":{"label":"ROTATING","strength":"inclined to share voice and cultivate broad support","risk":"changing participants can make execution uneven"},
	"territorial":{"label":"DELEGATING","strength":"inclined to trust distant agents and preserve reach","risk":"may build machinery the present realm is too small to use"},
}

func _init(terrain_node:Node,hud_node:Control,target_office:String="Steward")->void:
	super._init(terrain_node,hud_node)
	office=target_office
	terrain._generate_leader_candidates(office)

func meta()->Dictionary:
	var definition:=GovernmentPeopleSystem.office_definition(office)
	return {
		"eyebrow":"GOVERNMENT · APPOINTMENT",
		"title":String(definition.get("title",office)),
		"subtabs":["ELIGIBLE PEOPLE"],
	}

func tab(_sub:int)->Dictionary:
	var incumbent:Dictionary=GovernmentPeopleSystem.officeholder(office)
	var office_title:=String(GovernmentPeopleSystem.office_definition(office).get("title",office))
	var kpis:Array=[
		{"label":"OFFICE","value":office_title.substr(0,15),"delta":"evolves","accent":Tokens.GOLD,"tip":"The title changes as the civilization's government develops."},
		{"label":"HOLDER","value":String(incumbent.get("name","vacant")).substr(0,14) if not incumbent.is_empty() else "vacant","delta":"age %d" % int(incumbent.get("age",0)) if not incumbent.is_empty() else "","accent":Tokens.GREEN if not incumbent.is_empty() else Tokens.AMBER,"tip":"The living person holding this office."},
		{"label":"SHORTLIST","value":str(terrain.leader_candidates.size()),"delta":"people","accent":Tokens.BLUE,"tip":"Known people put forward for consideration. Their order is not a ranking."},
		{"label":"EVIDENCE","value":"partial","delta":"accounts","accent":Tokens.AMBER,"tip":"Reputation is incomplete. Actual performance becomes clearer through service and consequences."},
	]
	var brief:Dictionary={"tone":"warn" if incumbent.is_empty() else "info","title":"Choose an actual officeholder" if incumbent.is_empty() else "Review or replace the current officeholder","why":"These are reputations, witnessed habits, and political impressions—not measurements. Appointment reveals performance over time; governing style may help in one circumstance and fail in another."}
	var blocks:Array=[]
	for candidate_index in terrain.leader_candidates.size():
		var candidate:Dictionary=terrain.leader_candidates[candidate_index]
		var candidate_name:=String(candidate.get("name","INSTITUTION"))
		var doctrine:=String(candidate.get("doctrine",""))
		var notes:Dictionary=DOCTRINE_NOTES.get(doctrine,{"label":"UNSTRUCTURED","strength":"","risk":""})
		var traits:Array=candidate.get("traits",[])
		var assessment:=GovernmentPeopleSystem.appointment_assessment(candidate,office)
		var duty_note:=" · currently %s" % String(assessment.current_duty) if String(assessment.current_duty)!="" and candidate_name!=String(incumbent.get("name","")) else ""
		blocks.append({"type":"rows","items":[{
			"name":"%s · age %d" % [candidate_name,int(candidate.get("age",0))],
			"sub":"%s · %s%s" % [String(candidate.get("background",""))," / ".join(traits),duty_note],
			"detail":"KNOWN FOR · %s\nDOUBT · %s\n%s · %s · %s" % [String(assessment.known_for),String(assessment.public_concern),String(notes.label),String(notes.strength),String(notes.risk)],
			"value":"%s · %s" % [String(assessment.record),String(assessment.standing)],
			"value_color":Tokens.BODY_2,
			"accent":Tokens.GOLD if candidate_name==String(incumbent.get("name","")) else Tokens.BLUE,
			"tip":"What your society presently believes about this person. It is evidence, not a forecast or a complete account of their ability.",
		}]})
		blocks.append({"type":"actions","items":[{
			"label":"APPOINT","sub":"entrust this office and learn through results","primary":false,
			"disabled":candidate_name==String(incumbent.get("name","")),
			"on_press":func()->void: _commission(candidate_name),
			"tip":"Appoint %s as %s" % [candidate_name,office_title],
		}]})
	if blocks.is_empty():
		blocks.append({"type":"text","text":"No eligible person is available for this office yet."})
	return {"kpis":kpis,"brief":brief,"blocks":blocks}

func _commission(candidate_name:String)->void:
	if AdvisorSystem.appoint(candidate_name,office):
		var topics:Dictionary={"Steward":"population","Quartermaster":"food","Scholar":"knowledge","Marshal":"security","Envoy":"resources"}
		AdvisorSystem.generate_council_item(office,String(topics.get(office,"construction")),0.58)
		terrain._report_military_action({"message":"%s appointed as %s." % [candidate_name,String(GovernmentPeopleSystem.office_definition(office).get("title",office))]})
	hud.live_refresh_dock()

func signature()->Array:
	# Reputation and incumbent status can change over time even though exact
	# aptitude and execution remain deliberately hidden from the player.
	return [office,int(GovernmentPeopleSystem.officeholder(office).get("person_id",0)),GovernmentPeopleSystem.revision,terrain.leader_candidates.size(),roundi(clampf(float(GameState.simulation_metrics.get("legitimacy",0.62)),0.0,1.0)*50.0),GameState.player_settlements.size(),int(GameState.elapsed_days/30.0)]
