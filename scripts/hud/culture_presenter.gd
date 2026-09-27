extends RefCounted
static func tendency(weights:Dictionary)->String:
	var strongest:=0.0
	for weight in weights.values():strongest=maxf(strongest,float(weight))
	if strongest<=0:return ""
	var labels:Array[String]=[]
	for key:String in weights:
		if is_equal_approx(float(weights[key]),strongest):labels.append(key.replace("_"," ").capitalize())
	return " / ".join(labels)

static func effects(memory:Dictionary,day:int,research:Dictionary,scouting:bool,food_ratio:float)->Array:
	var culture=preload("res://scripts/cultural_inheritance.gd")
	var bias:Dictionary=culture.labor_bias(memory,day)
	var roles:=bias.keys()
	roles.sort_custom(func(a:Variant,b:Variant)->bool:return float(bias[a])>float(bias[b]) if not is_equal_approx(float(bias[a]),float(bias[b])) else String(a)<String(b))
	var work:Array[String]=[]
	for role in roles.slice(0,3):work.append(String(role))
	var domains:=research.keys()
	domains.sort_custom(func(a:Variant,b:Variant)->bool:return float(research[a])>float(research[b]) if not is_equal_approx(float(research[a]),float(research[b])) else String(a)<String(b))
	var gains:Array[String]=[]
	for domain in domains:
		if float(research[domain])>1.0001 and gains.size()<3:gains.append("%s: about %d%% faster" % [preload("res://scripts/hud/research_visuals.gd").name_for(String(domain)),maxi(1,roundi((float(research[domain])-1)*100))])
	var share:float=culture.scout_share(memory,day)
	var scout_title:="About %d in every 100 workers go scouting" % maxi(1,roundi(share*100))
	var scout_note:="Our ways send this many out; food and known paths still limit how many can go."
	if not scouting:scout_title="You decide who scouts";scout_note="Our ways do not send scouts out on their own."
	elif food_ratio<.98:scout_title="No scouting while people are hungry";scout_note="Scouts stay home until there is enough food."
	elif share<=0:scout_title="No habit of scouting yet";scout_note="A remembered journey will give the people a taste for exploring."
	var minimum:=1.0
	for multiplier in research.values():minimum=minf(minimum,float(multiplier))
	return [
		{"label":"WORK WE FAVOUR","title":" · ".join(work) if not work.is_empty() else "Still forming","detail":"Leaders put people on this work first, once food and water are safe."},
		{"label":"WHAT WE LEARN FASTER","title":"\n".join(gains) if not gains.is_empty() else "No field is favoured","detail":"Other fields come up to %d%% slower." % roundi((1-minimum)*100) if minimum<.9999 else "Our ways do not slow any field."},
		{"label":"EXPLORING","title":scout_title,"detail":scout_note}]

static func reputation(record:Dictionary)->Array:
	var cards:Array=[]
	var definitions:={
		"mercy":["Mercy","Helps captured soldiers return.","Grows when prisoners are released or property returned."],
		"fear":["Fear","Reduces enemy morale in battle.","Grows through harsh treatment and plunder."],
		"grievance":["Resentment","Strengthens enemy resolve; hinders captive returns.","Grows through coercion, killings and plunder."]}
	for key in definitions:
		var amount:=clampf(float(record.get(key,0)),0,1)
		var level:="None recorded" if amount<=0 else "Emerging" if amount<.25 else "Established" if amount<.6 else "Strong"
		cards.append({"label":definitions[key][0],"title":level,"value":amount,"detail":definitions[key][1],"tip":definitions[key][2]})
	return cards
