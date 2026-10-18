extends RefCounted
## Wants explain the voice. A disposition alone never supplies an army, a
## bank, a political party, or a grievance that the world has not produced.
const VALUES={
	"discovery":{"experimentation":.9,"achieved_status":.85,"pluralism":.75},
	"service":{"collective_obligation":.85,"common_stewardship":.75,"restorative_justice":.75},
	"exchange":{"openness":.9,"pluralism":.75,"common_stewardship":.25},
	"dynasty":{"hierarchy":.85,"achieved_status":.2,"experimentation":.25},
	"security":{"collective_obligation":.8,"centralization":.7,"hierarchy":.65},
	"conquest":{"hierarchy":.9,"centralization":.85,"openness":.2,"restorative_justice":.2},
	"stewardship":{"ecological_restraint":.85,"collective_obligation":.75,"experimentation":.4},
}
const WANTS={"discovery":"prove a disputed idea and earn respect for useful knowledge","service":"make care and public duty a lasting institution","exchange":"win dependable customers and the freedom to trade","dynasty":"keep the family's standing and control of its trade","security":"build a reputation for keeping people safe","conquest":"turn military success into territory and lasting command","stewardship":"leave dependable land and stores to the next generation"}
const FEARS={"discovery":"being dismissed because of birth or tradition","service":"seeing dependents abandoned while powerful people prosper","exchange":"having access closed by a rival's privilege","dynasty":"being replaced by an outsider and forgotten","security":"being blamed for a danger they warned about","conquest":"losing prestige when expansion stops","stewardship":"selling tomorrow's security for today's impressive promises"}
const ARGUMENTS={
	"discovery":"Judge the result, not the age of the person who suggested it. Let me show what our existing learners can achieve.",
	"service":"A promise of care should survive the person who made it. Back the institutions that keep it.",
	"exchange":"Let a stranger become a customer before we decide they must remain a stranger.",
	"dynasty":"Our name stands behind our work. You cannot demand that responsibility, then pretend our standing means nothing.",
	"security":"Keeping people safe is an achievement even when there is no victory to celebrate.",
	"conquest":"You have seen what victory makes possible. Give our military institutions your backing; I want that success to last.",
	"stewardship":"The next generation will eat from this land too. I want us to leave them something besides our reputation.",
}
const HUMOR={
	"discovery":["I can bear being wrong. Being told I am wrong before anyone tries it is much more irritating.","If age settled every argument, we would put a stone in charge."],
	"service":["Everyone praises generosity. The disagreement starts when we discuss whose stores to open."],
	"exchange":["I have nothing against strangers. Most of them have not yet asked me for credit."],
	"dynasty":["Inherited standing sounds much more respectable when it is one's own."],
	"security":["A quiet night is excellent work. Unfortunately it makes a very poor speech."],
	"conquest":["Caution is easier to admire when someone else would receive the credit."],
	"stewardship":["I worry about next winter. Winter has never thanked me for worrying less."],
}

static func context()->Dictionary:
	var victories:=0
	if WorldSimulation.military!=null:
		for battle:Dictionary in WorldSimulation.military.battle_history:
			var home:String=String(battle.get(String(battle.get("home_side","attacker")),{}).get("name",""))
			var termination:Dictionary=battle.get("termination",{})
			if home!="" and String(battle.get("winner",termination.get("captor","")))==home:victories+=1
	return {"population":int(WorldSimulation.settlements.national_population()),"defenders":int(WorldSimulation.state.population_allocations.get("Defense",0)),"victories":victories,"known":WorldSimulation.state.known_discoveries}

static func eligible(outlook:String,c:Dictionary)->bool:
	if outlook=="conquest":return int(c.get("population",0))>=100000 and int(c.get("defenders",0))>=100 and int(c.get("victories",0))>=2
	return VALUES.has(outlook)

static func make(person:Dictionary,role:String,c:Dictionary)->Dictionary:
	var p:Dictionary=person.get("personality",{})
	var outlook:="service"
	if role=="Defense":outlook="conquest" if eligible("conquest",c) and float(p.get("assertiveness",.5))>.7 and float(p.get("risk_tolerance",.5))>.6 else "security"
	elif float(person.get("pride",.5))>.72 and float(p.get("openness",.5))<.5:outlook="dynasty"
	elif role in ["Knowledge","Survey"]:outlook="discovery"
	elif role=="Logistics":outlook="exchange"
	elif role in ["Food","Extraction"]:outlook="stewardship" if float(p.get("empathy",.5))>.45 else "dynasty"
	elif role in ["Crafting","Construction"]:outlook="discovery" if float(p.get("openness",.5))>.6 else "dynasty"
	var wit:=posmod(hash("%s:%s:wit" % [str(person.get("person_id",0)),str(WorldSimulation.state.world_seed)]),5)
	var manner:="blunt and impatient" if float(p.get("assertiveness",.5))>.7 else "careful and insistent" if float(p.get("discipline",.5))>.65 else "warm but stubborn" if float(p.get("empathy",.5))>.65 else "proud and easily needled"
	var setting:="hearth" if int(c.get("population",0))<1000 else "settlement" if int(c.get("population",0))<10000 else "realm"
	var want:=String(WANTS[outlook]);var fear:=String(FEARS[outlook])
	if setting=="hearth":
		want={"Defense":"keep the people at this fire safe and have warnings taken seriously","Knowledge":"try an idea and have people notice whether it works","Survey":"find useful ground and be trusted when describing it","Crafting":"make dependable things and receive credit for the skill","Food":"keep the household fed without exhausting the land"}.get(role,"have a fair hearing and leave the household better provided for")
		fear="being ignored when the household needs what they know"
	return {"setting":setting,"trade":role,"head":int(person.get("person_id",0)),"outlook":outlook,"want":want,"fear":fear,"manner":manner,"humor":"dry" if wit==0 else "self-serving" if wit==1 else "none","values":VALUES[outlook].duplicate(true)}

static func speech(profile:Dictionary,variant:int=0,solemn:bool=false)->String:
	var outlook:=String(profile.get("outlook","service"))
	var said:=String(ARGUMENTS.get(outlook,ARGUMENTS.service))
	if profile.get("setting")=="hearth":said="I want to %s. Hear me out before we decide." % String(profile.want)
	# Most appearances have no joke. No comic beat during loss or hardship.
	if not solemn and profile.get("humor","none")!="none" and variant%3==0:
		var lines:Array=HUMOR.get(outlook,[])
		if not lines.is_empty():said+=" "+String(lines[posmod(variant/3,lines.size())])
	return said

static func prompt(profile:Dictionary)->String:
	if profile.is_empty():return ""
	return "Scale: %s. No invented standing armies, universities, banks or parties at a household fire. The motive below takes precedence over generic ambition text. PERSONAL MOTIVE: Wants to %s; fears %s. Manner: %s. Humor: %s, occasional and arising from self-interest; never joke about death or suffering. Argue for this person's actual interests, not generic exposition. Do not invent achievements, relatives, grievances, armies or offices. No modern political language before political institutions exist." % [String(profile.get("setting","realm")),String(profile.want),String(profile.fear),String(profile.manner),String(profile.humor)]

static func valid(v:Variant)->bool:
	if not v is Dictionary or not v.has_all(["head","outlook","want","fear","manner","humor","values","setting","trade"]):return false
	if v.setting not in ["hearth","settlement","realm"] or not v.trade is String:return false
	if not VALUES.has(v.outlook) or not v.head is int and not v.head is float or not v.values is Dictionary:return false
	for key in ["want","fear","manner","humor"]:
		if not v[key] is String or v[key].length()>200:return false
	return v.values==VALUES[v.outlook]
