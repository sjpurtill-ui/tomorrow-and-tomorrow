extends RefCounted
## What the court knows of an official before the god: their office, how well
## they suit it, what they are best at, their nature, what their hand changes
## in the engine's numbers (office_levers.gd), who else could hold it, and the
## standing orders they carry out. The court's "What you know" shows these
## rows; this is what the Chiefs/Government dock used to show, now kept where
## the official is questioned, ordered, appointed or dismissed.
##
##   rows(person_id) -> [[key, value, Color], ...]   ([] for anyone without an office)
## Static; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const Levers:=preload("res://scripts/office_levers.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")

static func rows(person_id:int)->Array:
	var out:Array=[]
	if person_id<=0 or GovernmentPeopleSystem==null: return out
	var key:=String(Hall._official(person_id).get("office_key",""))
	var office:={}
	for entry_variant in GovernmentPeopleSystem.active_offices():
		if String((entry_variant as Dictionary).get("key",""))==key: office=entry_variant
	if office.is_empty(): return out
	var holder:Dictionary=GovernmentPeopleSystem.officeholder(key)
	if int(holder.get("person_id",-1))!=person_id: return out
	out.append(["Office",String(office.get("title",Levers.office_title(key))),Tokens.BODY])
	var fit:=float(GovernmentPeopleSystem.office_competency(holder,key))
	out.append(["Suits it",Words.fit_words(fit),Tokens.RED if fit<0.4 else Tokens.BODY])
	var best:=_top_skills(holder)
	if best!="": out.append(["Best at",best,Tokens.BODY])
	var nature:PackedStringArray=PackedStringArray()
	for t in (holder.get("traits",[]) as Array).slice(0,2): nature.append(String(t).to_lower())
	var manner:=String(GovernmentPeopleSystem.leader_disposition(holder).get("label",""))
	if manner!="": nature.append(manner.to_lower())
	if not nature.is_empty(): out.append(["Their nature",", ".join(nature),Tokens.BODY])
	var lever:Dictionary=Levers.marshal_card() if key=="Marshal" else Levers.card(key)
	if String(lever.get("text",""))!="": out.append(["Their hand",String(lever.text),Tokens.BODY])
	var work:=Levers.work_line(key,holder)
	if work!="": out.append(["Their work",work,Tokens.BODY])
	if key=="Steward":
		for other in ["Quartermaster","Scholar","Envoy"]:
			if not bool(Levers.holder_of(other).acting): continue
			var card:=Levers.card(other)
			if not card.is_empty(): out.append(["Also keeps","for the %s: %s" % [Levers.office_title(other).to_lower(),String(card.text).get_slice(" · ",0).to_lower()],Tokens.BODY])
	var could:PackedStringArray=PackedStringArray()
	for row:Dictionary in Levers.shortlist_rows(key,3): could.append(String(row.get("text","")))
	if not could.is_empty(): out.append(["Could hold it",("; ".join(could))+". Say \"make … our %s\" to appoint one" % Levers.office_title(key).to_lower(),Tokens.BODY])
	out.append_array(_orders(key))
	if key=="Steward":
		var empty:PackedStringArray=PackedStringArray()
		for entry_variant in GovernmentPeopleSystem.active_offices():
			var entry:Dictionary=entry_variant
			if (GovernmentPeopleSystem.officeholder(String(entry.get("key",""))) as Dictionary).is_empty(): empty.append(String(entry.get("title","")))
		if not empty.is_empty(): out.append(["Empty offices","%s. Someone fit is named when one is found" % ", ".join(empty),Tokens.MUTED])
		var support:=clampf(float(ConsequenceEngine.governance_metrics().get("council_support",0.6)),0.0,1.0)
		out.append(["The officials","%s back us" % ("firmly" if support>=0.7 else "fairly" if support>=0.45 else "barely"),Tokens.RED if support<0.45 else Tokens.BODY])
	return out

## The standing orders this office carries out; the Headman (Steward) also
## carries those of an office no one holds, and the council's own.
static func _orders(key:String)->Array:
	var out:Array=[]
	for policy_variant in ConsequenceEngine.active_policies():
		var policy:Dictionary=policy_variant
		var by:=String(policy.get("office","Council"))
		var mine:=by==key or (key=="Steward" and (by=="Council" or by=="" or (GovernmentPeopleSystem.officeholder(by) as Dictionary).is_empty()))
		if not mine: continue
		var done:=float(policy.get("execution_factor",0.62))
		var how:="carried out well" if done>=0.8 else "carried out fairly" if done>=0.55 else "carried out badly"
		var left:=preload("res://scripts/hud/production_plain.gd").span_text(float(policy.get("remaining_days",0.0)))
		out.append(["Standing order","%s: %s, %s left" % [String(policy.get("name",policy.get("id","an order"))).capitalize(),how,left],Tokens.RED if done<0.55 else Tokens.BODY])
	return out

static func _top_skills(person:Dictionary)->String:
	var ranked:Array=[]
	for skill in GovernmentPeopleSystem.SKILL_KEYS:
		ranked.append({"name":String(skill),"value":float(GovernmentPeopleSystem.skill_value(person,String(skill)))})
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.value)>float(b.value))
	var parts:PackedStringArray=PackedStringArray()
	for index in mini(2,ranked.size()):
		parts.append("%s (%s)" % [String(ranked[index].name).to_lower(),Words.skill_words(float(ranked[index].value))])
	return ", ".join(parts)
