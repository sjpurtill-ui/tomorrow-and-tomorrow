extends RefCounted

# Military organization is derived from the same broad, evidence-driven
# civilization capabilities as the rest of the simulation. These records are
# bounded descriptions and templates, not a second visible technology tree.
const ERAS:Array[Dictionary]=[
	{"id":"founding","label":"FOUNDING DEFENSE","tier":0,"formation":"war band","command":"one field host","production_lines":1,"fronts":1,"description":"Household arms, a common watch, and one aggregate field host."},
	{"id":"militia","label":"ORGANIZED MILITIA","tier":1,"formation":"company","command":"muster commands","production_lines":2,"fronts":1,"description":"Repeated drills and scheduled obligations sustain organized militia formations."},
	{"id":"fortified","label":"FORTIFIED ARMIES","tier":2,"formation":"regiment","command":"regional commands","production_lines":3,"fronts":2,"description":"Permanent stores, fortification, and specialist formations support several campaigns."},
	{"id":"professional","label":"PROFESSIONAL FORCES","tier":3,"formation":"brigade","command":"field staffs","production_lines":4,"fronts":3,"description":"Standing formations, staffs, reserves, and replacement flows become durable institutions."},
	{"id":"state","label":"STATE DEFENSE SYSTEM","tier":4,"formation":"division","command":"general staff","production_lines":5,"fronts":4,"description":"Mobilization, intelligence, logistics, and military production are coordinated across a state."},
	{"id":"industrial","label":"INDUSTRIAL WARFARE","tier":5,"formation":"division","command":"theater commands","production_lines":6,"fronts":6,"description":"Standard arms, heavy firepower, mass production, rail-scale supply, and continuous fronts dominate war."},
	{"id":"national","label":"NATIONAL JOINT COMMAND","tier":6,"formation":"field army","command":"joint national command","production_lines":8,"fronts":8,"description":"Motor transport, armored forces, deep reserves, and national replacement systems sustain multiple fronts."},
	{"id":"global","label":"GLOBAL FORCE SYSTEM","tier":7,"formation":"army group","command":"global commands","production_lines":10,"fronts":10,"description":"Worldwide logistics, intelligence, and combined arms connect distant theaters into one war system."},
	{"id":"planetary","label":"PLANETARY SECURITY","tier":8,"formation":"theater force","command":"planetary coordination","production_lines":12,"fronts":12,"description":"Planet-scale deterrence and crisis response integrate military and civilian protection."}
]

const FORMATION_SCALES:Array[Dictionary]=[
	{"id":"war_band","label":"WAR BAND","minimum":1,"maximum":249},
	{"id":"company","label":"COMPANY","minimum":250,"maximum":999},
	{"id":"regiment","label":"REGIMENT","minimum":1000,"maximum":4999},
	{"id":"brigade","label":"BRIGADE","minimum":5000,"maximum":19999},
	{"id":"division","label":"DIVISION","minimum":20000,"maximum":99999},
	{"id":"field_army","label":"FIELD ARMY","minimum":100000,"maximum":999999},
	{"id":"army_group","label":"ARMY GROUP","minimum":1000000,"maximum":9999999},
	{"id":"theater_force","label":"THEATER FORCE","minimum":10000000,"maximum":9223372036854775807}
]

static func era_for_tiers(security:int,production:int,logistics:int,institutions:int)->Dictionary:
	# Security leads, but mass armies cannot skip the production, logistics, and
	# administrative capacities that make their equipment and replacement flows real.
	var supported:=mini(security,mini(production+1,mini(logistics+1,institutions+1)))
	return ERAS[clampi(supported,0,ERAS.size()-1)].duplicate(true)

static func formation_scale(personnel:int)->Dictionary:
	var count:=maxi(0,personnel)
	for definition in FORMATION_SCALES:
		if count<=int(definition.maximum): return definition.duplicate(true)
	return FORMATION_SCALES[-1].duplicate(true)

static func organization_snapshot(formations:Array)->Dictionary:
	var totals:Dictionary={}
	var personnel:=0
	for formation_variant in formations:
		var formation:Dictionary=formation_variant
		var count:=maxi(0,int(formation.get("count",0)))
		var scale:=formation_scale(count)
		personnel+=count
		totals[String(scale.id)]=int(totals.get(String(scale.id),0))+1
	return {"personnel":personnel,"record_count":formations.size(),"echelons":totals,"largest":formation_scale(personnel)}
