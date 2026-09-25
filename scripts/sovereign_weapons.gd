extends RefCounted
## Sovereign use of weapons of mass destruction.
##
## Research makes these weapons KNOWN (data/research/blocks/y2400_3000.json);
## it never makes them usable. A general does not use them on his own
## authority, whatever his orders, ambition or desperation: their use is the
## ruler's explicit decision, spoken aloud in the Court, and it is recorded so
## the people and other realms remember it. Three classes:
##   sovereign      never without the ruler's spoken decision;
##   restricted     usable against armies, fleets and works in the field, but
##                  striking a CITY needs the same decision;
##   human_signoff  the machine only proposes targets; a named commander must
##                  approve each strike, and it never widens his authority.
## MilitaryCampaign keeps the decisions (sovereign_decisions) and answers
## general_use_gate(); GeneralCampaign and the battle entry points ask it.
## Static helpers; reference with preload.

const SOVEREIGN:={
	"chemical_gas_warfare":"war gases",
	"fission_weapon":"the fission bomb",
	"thermonuclear_weapon":"the thermonuclear weapon",
	"intercontinental_missiles":"the intercontinental missiles",
	"missile_submarine_patrols":"the missile submarines",
	"hypersonic_glide_vehicles":"the hypersonic glide vehicles",
}
const RESTRICTED:={
	"aerial_bombardment":"bombing from the air",
	"armed_remote_strike":"armed remote strikes",
}
const HUMAN_SIGNOFF:={
	"machine_assisted_targeting":"machine-assisted targeting",
}
## Equipment whose use is one of the restricted means.
const EQUIPMENT_MEANS:={
	"close_air_support_equipment":"aerial_bombardment",
	"tactical_bomber_equipment":"aerial_bombardment",
	"strategic_bomber_equipment":"aerial_bombardment",
	"naval_bomber_equipment":"aerial_bombardment",
	"jet_bomber_equipment":"aerial_bombardment",
	"strike_drone_equipment":"armed_remote_strike",
}
## How the ruler names each means aloud. Checked in order: the more specific
## phrase first (a "thermonuclear" bomb is not the fission bomb).
const NAME_PATTERNS:=[
	["thermonuclear_weapon","(?i)\\b(thermonuclear|hydrogen bombs?|fusion bombs?|h-bombs?)\\b"],
	["missile_submarine_patrols","(?i)\\b(missile submarines?|missile boats?|submarine missiles?|missiles? from (the |our )?submarines?)\\b"],
	["hypersonic_glide_vehicles","(?i)\\b(hypersonic|glide vehicles?|gliders?)\\b"],
	["intercontinental_missiles","(?i)\\b(intercontinental|ballistic missiles?|the missiles|our missiles|missiles)\\b"],
	["fission_weapon","(?i)\\b(fission|atom(ic)? bombs?|a-bombs?|nuclear (bombs?|weapons?)|the bomb)\\b"],
	["chemical_gas_warfare","(?i)\\b(poison gas|war gas(es)?|the gas|gas (attack|shells?)|chlorine|mustard gas|nerve gas|chemical weapons?)\\b"],
	["armed_remote_strike","(?i)\\b(drone strikes?|armed drones?|strike drones?|remote strikes?|the drones)\\b"],
	["aerial_bombardment","(?i)\\b(bomb (the |their )?(city|cities|town|towns|capital)|bombers?|bombard(ment)? from the air|air raids?|aerial bombardment|bombing)\\b"],
	["machine_assisted_targeting","(?i)\\b(machine[- ]assisted targeting|targeting machines?|machine targeting)\\b"],
]
const USE_PATTERN:="(?i)\\b(use|loose|unleash|launch|drop|fire|release|deploy|employ|strike (them |it |\\w+ )?with|let (fly|loose)|i authori[sz]e|i permit|you may use|you have my leave|you are permitted|bomb)\\b"
const FORBID_PATTERN:="(?i)\\b(never|forbid|forbidden|do not|don't|must not|shall not|withhold|hold back|stand down|revoke|no one (may|shall))\\b"

static func authority(means:String)->String:
	if SOVEREIGN.has(means): return "sovereign"
	if RESTRICTED.has(means): return "restricted"
	if HUMAN_SIGNOFF.has(means): return "human_signoff"
	return ""

static func label(means:String)->String:
	return String(SOVEREIGN.get(means,RESTRICTED.get(means,HUMAN_SIGNOFF.get(means,means))))

static func means_of_equipment(item:String)->String:
	return String(EQUIPMENT_MEANS.get(item,""))

static func _re(pattern:String)->RegEx:
	var re:=RegEx.new(); re.compile(pattern)
	return re

static func named_means(text:String)->Array[String]:
	## The gated means the text names (sovereign and restricted), most specific first.
	var found:Array[String]=[]
	var remaining:=text
	for row:Array in NAME_PATTERNS:
		var re:=_re(String(row[1]))
		if re.search(remaining)!=null:
			if not found.has(String(row[0])): found.append(String(row[0]))
			remaining=re.sub(remaining," ",true)
	return found

static func parse_decree(text:String)->Dictionary:
	## A spoken decision about a gated means: {decree:"authorize"|"forbid", means:[...]} or {}.
	var means:=named_means(text)
	if means.is_empty(): return {}
	if _re(FORBID_PATTERN).search(text)!=null: return {"decree":"forbid","means":means}
	if _re(USE_PATTERN).search(text)!=null: return {"decree":"authorize","means":means}
	return {}

static func check_use(means:String,decisions:Dictionary,context:Dictionary={})->Dictionary:
	## Whether a general may use `means` now. context: {target:"city"|"field", signoff:bool}.
	## decisions: means -> the ruler's recorded decision (MilitaryCampaign.sovereign_decisions).
	var kind:=authority(means)
	if kind=="": return {"ok":true}
	var decided:Dictionary={}
	if decisions.get(means) is Dictionary: decided=decisions[means]
	var spoken:=not decided.is_empty() and String(decided.get("source",""))=="court" and String(decided.get("spoken","")).strip_edges()!=""
	match kind:
		"sovereign":
			if spoken: return {"ok":true,"authority":"sovereign","decision":decided.duplicate(true)}
			return {"error":"I will not use %s on my own authority. Only the ruler's own word, spoken in the Court, can loose it." % label(means),"kind":"sovereign","means":means}
		"restricted":
			if String(context.get("target","field"))!="city": return {"ok":true,"authority":"restricted"}
			if spoken: return {"ok":true,"authority":"restricted","decision":decided.duplicate(true)}
			return {"error":"I will not turn %s on a city on my own authority. Against their armies, yes; their people, only on the ruler's spoken word in the Court." % label(means),"kind":"restricted","means":means}
		"human_signoff":
			if bool(context.get("signoff",false)): return {"ok":true,"authority":"human_signoff"}
			return {"error":"The machine only proposes targets. A named commander must sign off each strike.","kind":"signoff","means":means}
	return {"ok":true}
