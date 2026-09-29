extends RefCounted
## LIFE CHANGE WORDS: why how long we live moved in a month, in plain words with
## its numbers. The reasons come from GameState.life_change_reasons, which
## splits the month's change among the inputs of the one life-expectancy
## formula (health, food to go round, roofs, each cause of death) and care of
## mothers, babies and the sick; this file only says them.

const EraWords:=preload("res://scripts/hud/era_words.gd")

## key: [when it lengthened lives, when it shortened them, short category]
const WORDS:={
	"health":["Fewer people sick","More people sick","Sickness"],
	"food":["More food to go round","Less food to go round","Food"],
	"housing":["More roofs for our numbers","Fewer roofs for our numbers","Roofs"],
	"care":["Better care of mothers, babies and the sick","Less care of mothers, babies and the sick","Care"],
	"cause:Hunger":["Fewer deaths from hunger","More deaths from hunger","Hunger"],
	"cause:Illness":["Fewer deaths from sickness","More deaths from sickness","Sickness"],
	"cause:Exposure":["Fewer deaths from cold and weather","More deaths from cold and weather","Weather"],
	"cause:Travel exhaustion":["The road wore people down less","The road wore people down","The road"],
	"cause:Insecurity":["Fewer deaths from raids and violence","More deaths from raids and violence","Raids"],
	"cause:Dehydration":["Fewer deaths from thirst","More deaths from thirst","Thirst"],
	"cause:Work accidents":["Fewer deaths at work","More deaths at work","Work"],
}

## One reason's own numbers: "food to go round 62% → 81%".
static func numbers(reason:Dictionary)->String:
	var key:=String(reason.get("key",""))
	var from:=float(reason.get("from",0.0))
	var to:=float(reason.get("to",0.0))
	match key:
		"health":return "health %d%% → %d%%" % [roundi(from*100.0),roundi(to*100.0)]
		"food":return "food to go round %d%% → %d%%" % [roundi(from*100.0),roundi(to*100.0)]
		"housing":return "roofs for %d%% → %d%% of the people" % [roundi(minf(from,1.0)*100.0),roundi(minf(to,1.0)*100.0)]
		"care":return "how the weak are cared for"
	if key.begins_with("cause:"):
		# The yearly risk of dying of it, per hundred people.
		return "yearly risk of dying of %s %s → %s in 100" % [String(CAUSE_WORDS.get(key.trim_prefix("cause:"),key.trim_prefix("cause:").to_lower())),_per_hundred(from),_per_hundred(to)]
	return ""

const CAUSE_WORDS:={"Hunger":"hunger","Illness":"sickness","Exposure":"cold and weather","Travel exhaustion":"the road","Insecurity":"raids and violence","Dehydration":"thirst","Work accidents":"accidents at work"}

static func _per_hundred(rate:float)->String:
	var value:=rate*100.0
	if value<0.05:return "0"
	if value<1.0:return "%.1f" % value
	return "%d" % roundi(value)

static func phrase(reason:Dictionary)->String:
	var words:Array=WORDS.get(String(reason.get("key","")),["Living conditions improved","Living conditions worsened","How we live"])
	return String(words[0] if float(reason.get("years",0.0))>=0.0 else words[1])

static func category(reason:Dictionary)->String:
	return String((WORDS.get(String(reason.get("key","")),["","","How we live"]) as Array)[2])

## {name, why, category, tip} for a month's change of `delta` years.
static func tell(reasons:Array,delta:float,index:int,history:Array)->Dictionary:
	# The reasons that pull the same way as the month's change, largest first.
	var pulling:Array=[]
	for reason_variant in reasons:
		var reason:Dictionary=reason_variant
		if signf(float(reason.get("years",0.0)))==signf(delta) or is_zero_approx(delta):pulling.append(reason)
	if pulling.is_empty() and not reasons.is_empty():pulling=[reasons[0]]
	if pulling.is_empty():
		# An older month recorded no reasons: say what its health did, if anything.
		var previous:Dictionary=history[index-1] if index>0 else {}
		var before:=float(previous.get("health",-1.0))
		var after:=float((history[index] as Dictionary).get("health",-1.0))
		if before>=0.0 and after>=0.0 and absf(after-before)>=0.01:
			var sick:={"key":"health","years":delta,"from":before,"to":after}
			var text:=numbers(sick)
			return {"name":phrase(sick),"why":text.substr(0,1).to_upper()+text.substr(1),"category":"Sickness","tip":"This month was recorded before causes were kept; health is what moved."}
		return {"name":"Living conditions changed","why":"This older month did not record its causes","category":"How we live","tip":"Months recorded from now on name what changed and by how much."}
	var parts:Array[String]=[]
	for reason:Dictionary in pulling.slice(0,2):
		parts.append("%s (%s)" % [numbers(reason),EraWords.life_change(float(reason.years))])
	var first:Dictionary=pulling[0]
	var why:=("; ".join(parts))
	why=why.substr(0,1).to_upper()+why.substr(1)
	var tip_parts:Array[String]=[]
	for reason_variant in reasons:
		var reason:Dictionary=reason_variant
		tip_parts.append("%s: %s, %s" % [phrase(reason),numbers(reason),EraWords.life_change(float(reason.years))])
	return {"name":phrase(first),"why":why,"category":category(first),"tip":"\n".join(tip_parts)}
