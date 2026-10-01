extends "res://scripts/hud/content/dock_content_base.gd"
## Government is a first-class destination. Offices fill themselves; the player
## reads how each official suits their office, then summons them to the court
## to question, order, dismiss or punish them. Nothing consequential happens
## from this screen with one click.
const Words:=preload("res://scripts/hud/home_plain.gd")
const Levers:=preload("res://scripts/office_levers.gd")

func meta()->Dictionary:
	var government:=GovernmentPeopleSystem.structure_snapshot()
	return {
		"eyebrow":"Government · %s" % String(government.get("scope","founding council")).to_lower(),
		"title":String(government.get("name","Forming Order")).capitalize(),
		"subtabs":["Officials","Standing orders"],
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
		# What they do, in the engine's numbers, against an ordinary holder and
		# the best free candidate (office_levers.gd).
		var lever:=Levers.marshal_card() if key=="Marshal" else Levers.card(key)
		var standing_in:=_standing_in(key)
		# Who else could hold it, best judged first, each one press from the
		# court (where the appointment is spoken).
		var shortlist:Array=[]
		for row:Dictionary in Levers.shortlist_rows(key,3): shortlist.append(row.merged({"on_summon":court({"person_id":int(row.person_id)})}))
		items.append({"lever":lever,"standing_in":standing_in,"work_line":Levers.work_line(key,holder),"shortlist":shortlist,"office_key":key,"office_title":String(office.title),"name":String(holder.get("name","Unknown")),"person_id":int(holder.get("person_id",1)),"appearance_civ_id":holder.get("appearance_civ_id","player"),"appearance_world_seed":holder.get("appearance_world_seed",GameState.world_seed),"early_art_index":holder.get("early_art_index",0),"early_art_profile":holder.get("early_art_profile",""),"traits":traits,"skills":top_skills,"fit":GovernmentPeopleSystem.office_competency(holder,key),"fit_words":Words.fit_words(GovernmentPeopleSystem.office_competency(holder,key)),"accent":_office_color(key),"tip":"Age %d · %s · %s" % [int(holder.get("age",0)),String(holder.get("background","Public figure")),String(disposition.get("label","pragmatic")).capitalize()],"on_summon":court({"person_id":int(holder.get("person_id",0))}),"summon_tip":"Call %s to the court to question them, give orders, or dismiss or punish them." % String(holder.get("name","them"))})
	return [{"type":"cabinet","legitimacy":legitimacy,"support":support,"items":items}]

## The offices not yet open whose work this office's holder stands in for
## (the Headman keeps the stores, the lore and the messengers until each has
## its own keeper): their lever lines.
func _standing_in(key:String)->Array:
	var out:Array=[]
	if key!="Steward": return out
	for office in ["Quartermaster","Scholar","Envoy"]:
		var who:=Levers.holder_of(office)
		if not bool(who.acting): continue
		var card:=Levers.card(office)
		if not card.is_empty(): out.append({"office":office,"text":"For the %s: %s" % [Levers.office_title(office).to_lower(),String(card.text).get_slice(" · ",0).to_lower()],"tip":String(card.tip)})
	return out

func _top_skills(person:Dictionary)->Array:
	var ranked:Array=[]
	for skill in GovernmentPeopleSystem.SKILL_KEYS:
		ranked.append({"name":String(skill),"value":roundi(GovernmentPeopleSystem.skill_value(person,String(skill)))})
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.value)>int(b.value))
	var result:Array=[]
	var colors:Array[Color]=[Tokens.GOLD,Tokens.TEAL,Tokens.BLUE]
	for index in mini(3,ranked.size()):
		var skill_name:=String(ranked[index].name)
		result.append({"name":skill_name,"words":Words.skill_words(float(ranked[index].value)),"value":int(ranked[index].value),"color":colors[index]})
	return result

func _office_color(key:String)->Color:
	match key.to_lower():
		"steward":return Tokens.GOLD
		"quartermaster":return Tokens.TEAL
		"marshal":return Tokens.RED
		"scholar":return Tokens.BLUE
		"envoy":return Tokens.VIOLET
	return Tokens.GOLD

func _policy_brief(governance:Dictionary)->Dictionary:
	var policies:=ConsequenceEngine.active_policies()
	if policies.is_empty(): return {"tone":"info","title":"No standing orders","why":"Orders you give in the court become standing orders here while they are being carried out."}
	return {"tone":"info","title":"%d standing order%s" % [policies.size(),"" if policies.size()==1 else "s"],"why":"How well an order is carried out depends on the official in charge, how much else they have to do, and how much the people back it."}

func _policy_blocks(governance:Dictionary)->Array:
	var items:Array=[]
	for policy_variant in ConsequenceEngine.active_policies():
		var policy:Dictionary=policy_variant
		var done:=float(policy.get("execution_factor",0.62))
		var how:="carried out well" if done>=0.8 else "carried out fairly" if done>=0.55 else "carried out badly"
		items.append({"name":String(policy.get("name",policy.get("id","Policy"))).capitalize(),"sub":"%s is in charge; %s left" % [String(policy.get("office","The council")),preload("res://scripts/hud/production_plain.gd").span_text(float(policy.get("remaining_days",0.0)))],"value":how.capitalize(),"value_color":Tokens.GREEN_TEXT if done>=0.8 else Tokens.AMBER_TEXT if done>=0.55 else Tokens.RED_TEXT,"accent":Tokens.BLUE,"tip":"About %d in every 10 parts of this order are actually done." % roundi(done*10.0)})
	if items.is_empty(): return [{"type":"text","text":"No standing orders are in force. Give orders to your officials in the court."},{"type":"actions","items":[{"label":"Open the court","sub":"Summon an official and give an order","primary":true,"on_press":court({})}]}]
	return [{"type":"rows","heading":"Standing orders","note":"how well each is carried out","items":items}]

func signature()->Array:
	return [GovernmentPeopleSystem.revision,GameState.leadership_positions.duplicate(true),ConsequenceEngine.active_policies().size(),roundi(float(GameState.simulation_metrics.get("legitimacy",0.7))*100.0)]
