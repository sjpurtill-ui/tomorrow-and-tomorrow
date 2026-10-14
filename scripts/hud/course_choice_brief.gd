extends RefCounted
## Presentation of the existing course rules; choosing still belongs to PeopleDirection.
const Effects:=preload("res://scripts/ambition_effects.gd")
const WHY:={
	"horizons":"Find useful ground and bring knowledge home.",
	"makers":"Raise homes and works with more materials.",
	"gathering":"Hold communities together and spread new ways.",
	"inquiry":"Learn faster and put discoveries to use.",
	"military":"Train a stronger force and improve command.",
	"sustenance":"Feed more people from the land you have.",
	"wellbeing":"Support healthier lives and more births.",
	"commerce":"Move goods and strengthen trade.",
	"expansion":"Extend your reach and explore new land.",
	"dominion":"Strengthen command and extract more work.",
	"purity":"Tighten social bonds at the cost of openness.",
	"dynasty":"Build lasting authority and stronger works.",
	"retribution":"Strengthen security through force.",
	"orthodoxy":"Hold people together around one authority."
}
const SHORT:={"survey_output":"Surveying","scout_reach":"Scout reach","realm_reach":"Territorial reach","adoption_rate":"New ways spreading","food_yield":"Food yield","construction_output":"Building","resource_output":"Materials gathered","material_target":"Material quality","health_target":"Health","cohesion_target":"Social cohesion","conception_support":"Birth support","security_target":"Home safety","knowledge_gain":"Learning","training_rate":"Training","training_capacity":"Training capacity","command_development":"Command development","labor_multiplier":"Work output","trade_access":"Trade access","logistics_target":"Transport & roads"}
const FIELDS:={"horizons":"Travel & land","makers":"Craft & building","gathering":"Culture & institutions","inquiry":"Knowledge & health","military":"Security & logistics","sustenance":"Food & land","wellbeing":"Health & population","commerce":"Production & logistics","expansion":"Logistics & population","dominion":"Security & institutions","purity":"Culture & security","dynasty":"Institutions & building","retribution":"Security & institutions","orthodoxy":"Institutions & culture"}
const POINT_TARGETS:=["health_target","cohesion_target","security_target","material_target","logistics_target","trade_access"]

static func brief(id:String)->Dictionary:
	var gains:PackedStringArray=[];var costs:PackedStringArray=[]
	for lever:String in Effects.EFFECTS.get(id,{}):
		var amount:=float(Effects.EFFECTS[id][lever])
		var line:="Land recovers" if amount>0 else "Land wears down"
		if lever!="ecology_delta":line="%s %s%s%s" % [String(SHORT.get(lever,Effects.WORDS.get(lever,lever))),"+" if amount>0 else "−",String.num(absf(amount)*100.0,1).trim_suffix(".0")," pts" if lever in POINT_TARGETS else "%"]
		if amount>0:gains.append(line)
		else:costs.append(line)
	return {"why":String(WHY.get(id,"")),"gains":" · ".join(gains.slice(0,2)),"costs":" · ".join(costs),"research":String(FIELDS.get(id,""))+" research +25%","full_gains":" · ".join(gains)}

static func full(id:String)->String:
	var reading:=brief(id)
	return "%s\nGains: %s.\nCosts: %s.\n%s; other research −5%%.\nPoints change the conditions your people can reach on a 0–100 scale; actual conditions adjust over time." % [String(reading.why),String(reading.full_gains),String(reading.costs),String(reading.research)]
