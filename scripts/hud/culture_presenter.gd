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
		if float(research[domain])>1.0001 and gains.size()<3:gains.append("%s +%.1f%%" % [String(domain).capitalize(),(float(research[domain])-1)*100])
	var share:float=culture.scout_share(memory,day)
	var scout_title:="%.1f%% scout target" % (share*100)
	var scout_note:="Share of available workers; supplies and routes still limit missions."
	if not scouting:scout_title="Player directed";scout_note="Cultural scouting target is switched off."
	elif food_ratio<.98:scout_title="Paused for food";scout_note="The scouting target falls to zero while people lack food."
	elif share<=0:scout_title="No inherited target";scout_note="A remembered direction will shape exploration."
	var minimum:=1.0
	for multiplier in research.values():minimum=minf(minimum,float(multiplier))
	return [
		{"label":"WORK PRIORITIES","title":" · ".join(work) if not work.is_empty() else "Still forming","detail":"Leaders favor these jobs; urgent survival needs take priority."},
		{"label":"RESEARCH SPEED","title":"\n".join(gains) if not gains.is_empty() else "No cultural bonus","detail":"Other fields: down to %.1f%% slower." % ((1-minimum)*100) if minimum<.9999 else "Current cultural contribution to research speed."},
		{"label":"EXPLORATION","title":scout_title,"detail":scout_note}]

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
