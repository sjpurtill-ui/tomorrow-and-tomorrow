extends "res://scripts/hud/content/dock_content_base.gd"
## Government is a first-class destination. Offices fill themselves; the player
## evaluates conduct and results, then dismisses or executes officeholders.

func meta()->Dictionary:
	var government:=GovernmentPeopleSystem.structure_snapshot()
	return {
		"eyebrow":"GOVERNMENT · %s" % String(government.get("scope","founding council")).to_upper(),
		"title":String(government.get("name","Forming Order")).capitalize(),
		"subtabs":["OFFICEHOLDERS","POLICY"],
	}

func tab(sub:int)->Dictionary:
	var governance:=ConsequenceEngine.governance_metrics()
	var legitimacy:=clampf(float(GameState.simulation_metrics.get("legitimacy",0.7)),0.0,1.0)
	var support:=clampf(float(governance.get("council_support",0.6)),0.0,1.0)
	var kpis:Array=[
		{"label":"LEGITIMACY","value":"%d%%" % roundi(legitimacy*100.0),"accent":Tokens.capacity_color(legitimacy*100.0),"tip":"Shared acceptance of authority"},
		{"label":"SUPPORT","value":"%d%%" % roundi(support*100.0),"accent":Tokens.capacity_color(support*100.0),"tip":"Institutional support for current policy"},
	]
	if sub==1: return {"kpis":kpis,"brief":_policy_brief(governance),"blocks":_policy_blocks(governance)}
	return {"kpis":kpis,"brief":{"tone":"info","title":"Appointments are automatic","why":"Each available office is filled from the living public figures. Traits and abilities differ by person; dismissing or executing a holder triggers immediate succession."},"blocks":_office_blocks()}

func _office_blocks()->Array:
	var blocks:Array=[]
	for office_variant in GovernmentPeopleSystem.active_offices():
		var office:Dictionary=office_variant
		var key:=String(office.key)
		var holder:=GovernmentPeopleSystem.officeholder(key)
		if holder.is_empty():
			blocks.append({"type":"text","heading":String(office.title).to_upper(),"text":"Vacant. Government will fill this office when an eligible living person is available."})
			continue
		var traits:Array=holder.get("traits",[])
		var top_skills:=_top_skills(holder)
		var disposition:=GovernmentPeopleSystem.leader_disposition(holder)
		blocks.append({"type":"rows","heading":String(office.title).to_upper(),"items":[{
			"name":"%s · age %d" % [String(holder.get("name","Unknown")),int(holder.get("age",0))],
			"sub":"%s · %s" % [" / ".join(traits),String(disposition.get("label","pragmatic")).capitalize()],
			"detail":"%s\n%s" % [String(holder.get("background","Public figure")),top_skills],
			"value":"%d%% FIT" % roundi(GovernmentPeopleSystem.office_competency(holder,key)*100.0),
			"value_color":Tokens.BODY_2,"accent":Tokens.GOLD,
			"tip":"Traits and skills belong to this person and remain stable through service.",
		}]})
		blocks.append({"type":"actions","items":[
			{"label":"DISMISS","sub":"remove from office; successor appointed","on_press":_remove.bind(key,"dismiss"),"tip":"Fire %s. They remain alive and may serve again later." % String(holder.get("name","this officeholder"))},
			{"label":"EXECUTE","sub":"kill by decree; severe political cost","color":Tokens.RED,"on_press":_remove.bind(key,"execute"),"tip":"Execute %s and appoint a successor." % String(holder.get("name","this officeholder"))},
		]})
	return blocks

func _top_skills(person:Dictionary)->String:
	var ranked:Array=[]
	for skill in GovernmentPeopleSystem.SKILL_KEYS:
		ranked.append({"name":String(skill),"value":roundi(GovernmentPeopleSystem.skill_value(person,String(skill)))})
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.value)>int(b.value))
	var labels:Array[String]=[]
	for index in mini(3,ranked.size()): labels.append("%s %d" % [String(ranked[index].name),int(ranked[index].value)])
	return " · ".join(labels)

func _remove(office_key:String,action:String)->void:
	var result:=GovernmentPeopleSystem.remove_central_officeholder(office_key,action)
	terrain._report_military_action(result)
	hud.request_immediate_dock_refresh()

func _policy_brief(governance:Dictionary)->Dictionary:
	var policies:=ConsequenceEngine.active_policies()
	if policies.is_empty(): return {"tone":"info","title":"No standing policy","why":"Civic dialogue and council decisions create enforceable commitments."}
	return {"tone":"info","title":"%d standing polic%s" % [policies.size(),"y" if policies.size()==1 else "ies"],"why":"Execution depends on officeholder ability, administrative load, and political support."}

func _policy_blocks(governance:Dictionary)->Array:
	var items:Array=[]
	for policy_variant in ConsequenceEngine.active_policies():
		var policy:Dictionary=policy_variant
		items.append({"name":String(policy.get("name",policy.get("id","Policy"))).capitalize(),"sub":"%s · %d days remain" % [String(policy.get("office","Council")),ceili(float(policy.get("remaining_days",0.0)))],"value":"%d%%" % roundi(float(policy.get("execution_factor",0.62))*100.0),"accent":Tokens.BLUE})
	if items.is_empty(): return [{"type":"text","text":"No standing policy is in force."}]
	return [{"type":"rows","heading":"STANDING POLICY","note":"execution","items":items}]

func signature()->Array:
	return [GovernmentPeopleSystem.revision,GameState.leadership_positions.duplicate(true),ConsequenceEngine.active_policies().size(),roundi(float(GameState.simulation_metrics.get("legitimacy",0.7))*100.0)]
