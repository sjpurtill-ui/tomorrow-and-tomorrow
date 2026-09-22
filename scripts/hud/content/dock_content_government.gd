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
	var kpis:Array=[]
	if sub==1: return {"kpis":kpis,"brief":_policy_brief(governance),"blocks":_policy_blocks(governance)}
	return {"kpis":kpis,"brief":{},"blocks":_office_blocks(legitimacy,support)}

func _office_blocks(legitimacy:float,support:float)->Array:
	var items:Array=[]
	for office_variant in GovernmentPeopleSystem.active_offices():
		var office:Dictionary=office_variant
		var key:=String(office.key)
		var holder:=GovernmentPeopleSystem.officeholder(key)
		if holder.is_empty():
			items.append({"office_key":key,"office_title":String(office.title),"name":"Vacant","vacant":true,"tip":"This office has no holder. A successor is selected automatically when an eligible public figure is available.","accent":Tokens.MUTED,"traits":[],"skills":[],"fit":0.0})
			continue
		var traits:Array=holder.get("traits",[])
		var top_skills:Array=_top_skills(holder)
		var disposition:=GovernmentPeopleSystem.leader_disposition(holder)
		items.append({"office_key":key,"office_title":String(office.title),"name":String(holder.get("name","Unknown")),"person_id":int(holder.get("person_id",1)),"appearance_civ_id":holder.get("appearance_civ_id","player"),"appearance_world_seed":holder.get("appearance_world_seed",GameState.world_seed),"early_art_index":holder.get("early_art_index",0),"traits":traits,"skills":top_skills,"fit":GovernmentPeopleSystem.office_competency(holder,key),"accent":_office_color(key),"tip":"Age %d · %s · %s" % [int(holder.get("age",0)),String(holder.get("background","Public figure")),String(disposition.get("label","pragmatic")).capitalize()],"on_dismiss":_remove.bind(key,"dismiss"),"on_execute":_remove.bind(key,"execute"),"dismiss_tip":"Dismiss %s; a successor is appointed immediately." % String(holder.get("name","officeholder")),"execute_tip":"Execute %s; severe political cost." % String(holder.get("name","officeholder"))})
	return [{"type":"cabinet","legitimacy":legitimacy,"support":support,"items":items}]

func _top_skills(person:Dictionary)->Array:
	var ranked:Array=[]
	for skill in GovernmentPeopleSystem.SKILL_KEYS:
		ranked.append({"name":String(skill),"value":roundi(GovernmentPeopleSystem.skill_value(person,String(skill)))})
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.value)>int(b.value))
	var result:Array=[]
	var colors:Array[Color]=[Tokens.GOLD,Tokens.TEAL,Tokens.BLUE]
	for index in mini(3,ranked.size()):
		var skill_name:=String(ranked[index].name)
		result.append({"name":skill_name,"short":skill_name.substr(0,3).to_upper(),"value":int(ranked[index].value),"color":colors[index]})
	return result

func _office_color(key:String)->Color:
	match key.to_lower():
		"steward":return Tokens.GOLD
		"quartermaster":return Tokens.TEAL
		"marshal":return Tokens.RED
		"scholar":return Tokens.BLUE
		"envoy":return Tokens.VIOLET
	return Tokens.GOLD

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
