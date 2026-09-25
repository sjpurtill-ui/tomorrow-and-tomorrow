extends Node

const Culture:=preload("res://scripts/cultural_inheritance.gd")
var cultural_memory:Dictionary=Culture.empty()
var auto_scouting:=true
var auto_settlement:=true
var auto_research:=true
var inclination_review_day:=-1
const VALUES=preload("res://scripts/societal_values_model.gd")
const CENTURY_DAYS:=36500
const AMBITIONS:={
	"horizons":{"name":"Know the wider world","vision":"Become a people whose knowledge travels beyond familiar ground.","domains":["logistics","ecology"],"axis":"openness","target":.8,"effect":"25% faster logistics and ecology research; 5% slower research elsewhere. Openness grows gradually."},
	"makers":{"name":"Create things that endure","vision":"Become known for skill, ingenuity, and work worth passing down.","domains":["production","infrastructure"],"axis":"achieved_status","target":.8,"effect":"25% faster production and infrastructure research; 5% slower research elsewhere. Earned standing grows gradually."},
	"gathering":{"name":"Bring people together","vision":"Build a shared identity spacious enough for different communities.","domains":["culture","institutions"],"axis":"pluralism","target":.8,"effect":"25% faster culture and institutions research; 5% slower research elsewhere. Acceptance of differences grows gradually."},
	"inquiry":{"name":"Become a people of ideas","vision":"Make questioning, teaching, and discovery part of everyday culture.","domains":["knowledge","health"],"axis":"experimentation","target":.8,"effect":"25% faster knowledge and health research; 5% slower research elsewhere. Openness to experimentation grows gradually."},
	"military":{"name":"Build military strength","vision":"Develop the organization and supply needed to defend our people or pursue military ambitions. This does not declare war.","domains":["security","logistics"],"axis":"collective_obligation","target":.8,"effect":"25% faster security and logistics research; 5% slower elsewhere. Your society’s stated values shift toward shared labor, resources and care for the community."},
	"sustenance":{"name":"Secure lasting abundance","vision":"Improve food systems and stewardship so growth rests on a dependable foundation.","domains":["nutrition","ecology"],"axis":"ecological_restraint","target":.8,"effect":"25% faster nutrition and ecology research; 5% slower elsewhere. Ecological restraint grows gradually."},
	"wellbeing":{"name":"Help generations thrive","vision":"Give care, health and the lives of future generations a central place.","domains":["health","demography"],"axis":"common_stewardship","target":.8,"effect":"25% faster health and demography research; 5% slower elsewhere. Common stewardship grows gradually."},
	"commerce":{"name":"Grow through exchange","vision":"Build the skills and connections that make useful goods travel. Trade still needs real partners and routes.","domains":["production","logistics"],"axis":"openness","target":.8,"effect":"25% faster production and logistics research; 5% slower elsewhere. Openness grows gradually."},
	"expansion":{"name":"Found new horizons","vision":"Make new settlements a source of opportunity and prestige.","domains":["logistics","demography"],"axis":"openness","target":.7,"effect":"Builds an enduring expansionist tradition; favors logistics and population knowledge."},
	"dominion":{"name":"Rule beyond our borders","vision":"Seek power through conquest, tribute and the labor of subject peoples.","domains":["security","institutions"],"axis":"hierarchy","target":.9,"effect":"Strengthens conquest, extraction, exploitation and personal authority."},
	"purity":{"name":"Preserve a chosen people","vision":"Treat outsiders and dissenting ways as threats to the community's identity.","domains":["culture","security"],"axis":"pluralism","target":.1,"effect":"Strengthens exclusion, purification and sacred certainty."},
	"dynasty":{"name":"Entrench a ruling order","vision":"Make inherited rank and enduring authority the foundation of society.","domains":["institutions","infrastructure"],"axis":"achieved_status","target":.1,"effect":"Strengthens hereditary privilege, tradition and personal authority."},
	"retribution":{"name":"Make defiance costly","vision":"Build a reputation for vengeance and punishment that others fear.","domains":["security","institutions"],"axis":"restorative_justice","target":.1,"effect":"Strengthens vengeance, terror and the prestige of force."},
	"orthodoxy":{"name":"Bind society to one truth","vision":"Reward loyalty to an official account of the world and suppress rival interpretations.","domains":["institutions","culture"],"axis":"pluralism","target":.15,"effect":"Strengthens conformity and the use of truth in service of power."}
}
const VISIONS:=[
	{"title":"Whose knowledge travels?","role":"Explorer","other":"Scholar","question":"Some argue that useful knowledge should circulate freely. Others want to preserve a trusted teaching tradition before spreading it.","options":[{"label":"Share what we learn","axis":"openness","delta":.04,"meaning":"Make openness to outsiders a stronger public value."},{"label":"Strengthen our own teaching","axis":"collective_obligation","delta":.04,"meaning":"Strengthen the duty to pass knowledge on within the community."}]},
	{"title":"What earns a voice?","role":"Organizer","other":"Artist","question":"Should influence follow demonstrated contribution, or the confidence of the wider community? Both visions promise a different kind of authority.","options":[{"label":"Recognize demonstrated contribution","axis":"achieved_status","delta":.04,"meaning":"Give earned achievement more weight than inherited standing."},{"label":"Broaden participation","axis":"hierarchy","delta":-.04,"meaning":"Move public values toward more equal standing."}]},
	{"title":"How much room for disagreement?","role":"Scholar","other":"General","question":"Some see disagreement as a source of discovery. Others believe a shared commitment gives people the confidence to undertake larger ambitions.","options":[{"label":"Protect room to disagree","axis":"pluralism","delta":.04,"meaning":"Make different viewpoints more legitimate."},{"label":"Build a common commitment","axis":"collective_obligation","delta":.04,"meaning":"Strengthen obligations to shared purposes."}]}
]
var ambition:=""
var chosen_day:=-1
var chosen_century:=-1
var last_day:=0
var seed_value:=0
var initialized:=false
var resolved:=0
var next_vision_day:=30
var automatic_work:=true
var work_baseline:Dictionary={}
var work_day:=-30
var history:Array[Dictionary]=[]
var panel:Control
var layer:CanvasLayer
## The Opening Arc's record of the first years (scripts/opening_arc.gd).
var opening_arc:Dictionary={}
## Generational aims (scripts/legacy_aims.gd): the live aim, proposals,
## legacies and rivals' vows. Replaces the three one-shot visions.
var aims:Dictionary={}
## Emitted for each Opening Arc beat: {id, kind, tier, day, title, text, refs}.
signal opening_beat(beat:Dictionary)

func ensure()->void:
	if initialized and seed_value==WorldSimulation.state.world_seed: return
	reset_for_new_world(); seed_value=WorldSimulation.state.world_seed; initialized=true; last_day=int(WorldSimulation.state.elapsed_days)
	next_vision_day=last_day+30

func reset_for_new_world()->void:
	ambition=""; chosen_day=-1; chosen_century=-1; last_day=0; resolved=0; next_vision_day=30; automatic_work=true; work_baseline={}; work_day=-30; history.clear(); opening_arc={}; aims={}; cultural_memory=Culture.empty(); auto_scouting=true;auto_settlement=true;auto_research=true;inclination_review_day=-1; initialized=false
	if is_instance_valid(panel): panel.queue_free()

func choose(id:String)->Dictionary:
	ensure()
	if not AMBITIONS.has(id): return {"error":"Unknown ambition."}
	var day:=int(WorldSimulation.state.elapsed_days)
	if not needs_century_choice(): return {"error":"This century's focus is already chosen. Reconsider at the start of the next century."}
	_ensure_cultural_memory()
	Culture.record(cultural_memory,"century:%d" % century_at(day),id,day,10.0)
	ambition=id; chosen_day=day; chosen_century=century_at(day); last_day=day
	if WorldSimulation.state.founding_focus=="":
		# Complete the old time gate without applying an unrelated survival preset.
		WorldSimulation.state.founding_focus="collective_ambition"
		WorldSimulation.state.founding_focus_selected_day=day
		WorldSimulation.state.founding_banner_index=AMBITIONS.keys().find(id)%4
	apply_inclinations(day)
	_log(day,"Century %d: chose to %s." % [chosen_century+1,String(AMBITIONS[id].name).to_lower()])
	return {"ok":true}

func century_at(day:int)->int:
	return maxi(0,day)/CENTURY_DAYS

func needs_century_choice()->bool:
	ensure()
	return ambition.is_empty() or chosen_century!=century_at(int(WorldSimulation.state.elapsed_days))

func next_century_day()->int:
	return (century_at(int(WorldSimulation.state.elapsed_days))+1)*CENTURY_DAYS

func research_multiplier(domain:String)->float:
	ensure();_ensure_cultural_memory()
	var total:=0.0;var relevant:=0.0
	var weighted:=Culture.choice_weights(cultural_memory,int(WorldSimulation.state.elapsed_days))
	for choice in weighted:
		var amount:=float(weighted[choice]);total+=amount
		if domain in AMBITIONS[choice].domains:relevant+=amount
	return 1.0 if total<=0 else .95+.30*relevant/total

func _ensure_cultural_memory()->void:
	if not Culture.valid(cultural_memory):cultural_memory=Culture.empty()
	# Older saves retain only their last selected focus. Do not invent earlier choices.
	if cultural_memory.events.is_empty() and AMBITIONS.has(ambition):Culture.record(cultural_memory,"legacy:%d" % chosen_century,ambition,maxi(0,chosen_day),10.0)

func cultural_tendencies()->Array[Dictionary]:
	ensure();_ensure_cultural_memory()
	var result:Array[Dictionary]=[];var day:=int(WorldSimulation.state.elapsed_days)
	for domain in Culture.DOMAINS:
		result.append({"domain":domain,"inheritance":Culture.distribution(cultural_memory,domain,day),"current":Culture.distribution(cultural_memory,domain,day,true)})
	return result

func advance(day:int)->void:
	ensure()
	if day<=last_day: return
	_ensure_cultural_memory()
	if not cultural_memory.choices.is_empty():
		var state:Dictionary=VALUES.normalize_state(WorldSimulation.state.societal_values)
		var totals:Dictionary={};var weights:Dictionary={}
		var weighted:=Culture.choice_weights(cultural_memory,day)
		for choice in weighted:
			var axis:String=AMBITIONS[choice].axis;var amount:=float(weighted[choice])
			totals[axis]=float(totals.get(axis,0))+float(AMBITIONS[choice].target)*amount;weights[axis]=float(weights.get(axis,0))+amount
		for axis in totals:state.official[axis]=move_toward(float(state.official[axis]),float(totals[axis])/float(weights[axis]),float(day-last_day)*.00008)
		WorldSimulation.state.societal_values=VALUES.normalize_state(state)
	last_day=day

func decide(option:int)->Dictionary:
	## The three one-shot visions have given way to generational aims
	## (legacy_aims.gd), which the court proposes and the god takes up. Kept
	## for older callers; it never applies a vision now.
	ensure()
	if option>=0: return {"error":"The people's visions are now their aims: summon the court to hear what they would strive for."}
	var day:=int(WorldSimulation.state.elapsed_days)
	if ambition=="" or resolved>=VISIONS.size() or day<next_vision_day: return {"error":"There is no vision awaiting your support."}
	if option<0 or option>=2: return {"error":"Unknown vision."}
	var choice:Dictionary=VISIONS[resolved].options[option]
	_ensure_cultural_memory()
	var imprint:String=[["horizons","makers"],["makers","gathering"],["gathering","wellbeing"]][resolved][option]
	Culture.record(cultural_memory,"vision:%d" % resolved,imprint,day,2.0)
	var state:Dictionary=VALUES.normalize_state(WorldSimulation.state.societal_values)
	state.official[choice.axis]=clampf(float(state.official[choice.axis])+float(choice.delta),0,1)
	WorldSimulation.state.societal_values=VALUES.normalize_state(state)
	_log(day,String(choice.label)+". "+String(choice.meaning))
	resolved+=1; next_vision_day=day+180
	inclination_review_day=-1;apply_inclinations(day)
	return {"ok":true}

func _log(day:int,message:String)->void:
	history.push_front({"day":day,"text":message})
	if history.size()>24: history.resize(24)

func advocate(role:String)->String:
	WorldSimulation.figures.ensure()
	for p in WorldSimulation.figures.people:
		if p.role==role and p.status=="living": return String(p.name)+", "+role.to_lower()
	return "Community voices"

func routine_work(_day:int)->void:
	# Compatibility entry point. GovernmentPeopleSystem owns daily labor delegation.
	ensure()

func advisor_recommendations()->Array[Dictionary]:
	# Read the existing redacted knowledge surface, never raw rival records.
	var known:Array=[]
	for record in WorldSimulation.world.known_competition_snapshot().get("leaders",[]):
		if String(record.get("id",""))=="player": continue
		var relation:Dictionary=record.get("player_relation",{})
		if int(relation.get("contact_level",0))<2: continue
		known.append({"name":String(record.get("name","A contacted community")),"at_war":bool(relation.get("at_war",false)),"trade":float(relation.get("trade",0.0))>0.0})
	known.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return String(a.name)<String(b.name))
	var result:Array[Dictionary]=[]
	for office in WorldSimulation.government.active_offices():
		var person:=WorldSimulation.government.officeholder(String(office.key))
		if person.is_empty() or String(person.get("status","active"))!="active": continue
		var recommendation:=_recommendation(String(office.key),known)
		recommendation["person_id"]=int(person.get("person_id",0))
		recommendation["name"]=String(person.get("name","Advisor"))
		recommendation["title"]=String(office.title)
		result.append(recommendation)
	return result

func _recommendation(role:String,known:Array)->Dictionary:
	var war:=""
	var trading:=""
	for record in known:
		if bool(record.get("at_war",false)) and war=="": war=String(record.name)
		if bool(record.get("trade",false)) and trading=="": trading=String(record.name)
	var focus:=String({"Steward":"gathering","Quartermaster":"makers","Marshal":"military","Scholar":"inquiry","Envoy":"horizons","ChiefScout":"horizons"}.get(role,"gathering"))
	var why:=String({"Steward":"A shared civic life helps our settlements work together.","Quartermaster":"Durable tools and infrastructure make our existing labor more useful.","Marshal":"Reliable military organization and supply give us more options without committing us to war.","Scholar":"Sustained inquiry builds our capacity to test claims rather than rely on hearsay.","Envoy":"Returned journeys and direct contact can give future decisions a firmer basis.","ChiefScout":"What my scouts carry home is only as good as how far they can go; I would push our horizons outward."}.get(role,"Our institutions need a durable common purpose."))
	if role in ["Steward","Quartermaster"] and float(WorldSimulation.state.simulation_metrics.get("food_days",30.0))<15.0:
		focus="sustenance"; why="Our reported food reserve is low; I would put dependable food systems ahead of other ambitions."
	elif role=="Steward" and WorldSimulation.state.population_health<0.65:
		focus="wellbeing"; why="Our own health is under strain; I would invest in care and future generations."
	elif role in ["Quartermaster","Envoy"] and trading!="":
		focus="commerce"; why="Our recorded exchange with %s gives us a real starting point for better production and transport." % trading
	elif role in ["Steward","Marshal"] and war!="":
		focus="military"; why="We are at war with %s. I would prioritize security and the logistics our forces depend on." % war
	if known.is_empty(): why+=" We have no confirmed foreign contacts to compare against; I will not guess at unseen rivals."
	elif war=="" and trading=="": why+=" We have met %s, but contact alone does not establish their capabilities or intentions." % String(known[0].name)
	else: why+=" This uses recorded relations, not unseen foreign reserves or plans."
	return {"focus":focus,"reason":why}

func export_state()->Dictionary:
	ensure()
	return {"version":3,"inclination_review_day":inclination_review_day,"auto_scouting":auto_scouting,"auto_settlement":auto_settlement,"auto_research":auto_research,"cultural_memory":cultural_memory.duplicate(true),"chosen_century":chosen_century,"network":WorldSimulation.communities.export_state(),"seed":seed_value,"ambition":ambition,"chosen_day":chosen_day,"last_day":last_day,"resolved":resolved,"next_vision_day":next_vision_day,"automatic_work":automatic_work,"work_baseline":work_baseline.duplicate(true),"work_day":work_day,"history":history.duplicate(true),"aims":aims.duplicate(true)}

func import_state(state:Dictionary)->Dictionary:
	if int(state.get("version",0)) not in [1,2,3] or state.get("seed",0)!=WorldSimulation.state.world_seed: return {"error":"Incompatible people-direction save."}
	if state.has("cultural_memory") and not Culture.valid(state.cultural_memory):return {"error":"Invalid accumulated culture."}
	var imported_century:=int(state.get("chosen_century",-1))
	if int(state.version)==1:
		# Preserve the player's existing ambition for their current century, rather
		# than replacing it with an assistant/game choice when an old save loads.
		imported_century=century_at(int(WorldSimulation.state.elapsed_days)) if String(state.get("ambition",""))!="" else -1
	if imported_century < -1 or imported_century>century_at(int(WorldSimulation.state.elapsed_days)): return {"error":"Invalid focus century."}
	if (String(state.get("ambition",""))=="")!=(imported_century==-1): return {"error":"Focus and century disagree."}
	if state.get("ambition","")!="" and not AMBITIONS.has(state.ambition): return {"error":"Invalid ambition."}
	if int(state.get("resolved",0))<0 or int(state.get("resolved",0))>VISIONS.size() or not state.get("history",[]) is Array or state.get("history",[]).size()>24: return {"error":"Invalid vision history."}
	if not state.get("work_baseline",{}) is Dictionary: return {"error":"Invalid automatic work baseline."}
	for value in state.get("work_baseline",{}).values():
		if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0: return {"error":"Invalid work share."}
	for event in state.get("history",[]):
		if not event is Dictionary or not event.has_all(["day","text"]): return {"error":"Invalid history record."}
	if state.has("aims") and not preload("res://scripts/legacy_aims.gd").valid_state(state.aims): return {"error":"Invalid aims save."}
	if state.has("network"):
		if not state.network is Dictionary: return {"error":"Invalid network save."}
		var network_result:=WorldSimulation.communities.import_state(state.network)
		if network_result.has("error"): return network_result
	else:
		WorldSimulation.communities.reset_for_new_world(); WorldSimulation.communities.ensure()
	ambition=state.get("ambition",""); chosen_day=int(state.get("chosen_day",-1)); last_day=int(state.get("last_day",0)); resolved=int(state.get("resolved",0)); next_vision_day=int(state.get("next_vision_day",30)); automatic_work=bool(state.get("automatic_work",true)); work_baseline=state.get("work_baseline",{}).duplicate(true); work_day=int(state.get("work_day",-30)); history.assign(state.get("history",[]).duplicate(true)); seed_value=WorldSimulation.state.world_seed; initialized=true
	chosen_century=imported_century
	# Older saves have no aims: the court will propose one in due course.
	aims=(state.get("aims",{}) as Dictionary).duplicate(true) if state.get("aims") is Dictionary else {}
	cultural_memory=state.get("cultural_memory",Culture.empty()).duplicate(true)
	auto_scouting=bool(state.get("auto_scouting",true));auto_settlement=bool(state.get("auto_settlement",true));auto_research=bool(state.get("auto_research",true));inclination_review_day=int(state.get("inclination_review_day",-1))
	_ensure_cultural_memory()
	return {"ok":true}

func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:
		open_direction(); get_viewport().set_input_as_handled()

func open_direction()->void:
	ensure()
	if is_instance_valid(panel):
		if not needs_century_choice(): panel.queue_free()
		return
	if not is_instance_valid(layer): layer=CanvasLayer.new(); layer.layer=81; add_child(layer)
	# A new people is asked its purpose at the fire circle, in the Hearth Chief's
	# voice. Later centuries and the F8 review keep the full direction screen.
	var founding:bool=WorldSimulation.state.founding_focus=="" and ambition.is_empty()
	panel=(preload("res://scripts/hud/fire_circle_opening.gd") if founding else preload("res://scripts/people_direction_screen.gd")).new(); layer.add_child(panel)

func record_cultural_action(key:String,choice:String,weight:float=1.0)->bool:
	ensure();_ensure_cultural_memory()
	var day:=int(WorldSimulation.state.elapsed_days);var used:=0.0
	for event:Dictionary in cultural_memory.events:
		if String(event.id).begins_with("action:") and event.choice==choice and century_at(event.day)==century_at(day):used+=float(event.weight)
	# Repeated automated behavior cannot drown out a ten-point century commitment.
	return Culture.record(cultural_memory,"action:"+key,choice,day,minf(weight,maxf(0,5.0-used)))

func apply_inclinations(day:int)->void:
	ensure();_ensure_cultural_memory()
	if cultural_memory.choices.is_empty() or inclination_review_day==day:return
	inclination_review_day=day
	if auto_scouting:
		var share:=Culture.scout_share(cultural_memory,day)
		if float(WorldSimulation.state.simulation_metrics.get("food_intake_ratio",1))<.98:share=0.0
		WorldSimulation.world.scouting_staff.set_policy(share,"exploration",true)
	if auto_research:
		var controller=load("res://scripts/civilization_controller.gd")
		var plan:Dictionary=controller.current_plan(WorldSimulation.actor_id)
		var weights:Dictionary={}
		for domain in WorldSimulation.state.research_allocations:weights[domain]=.1
		var choices:=Culture.choice_weights(cultural_memory,day)
		for choice in choices:
			for domain in AMBITIONS[choice].domains:weights[domain]=float(weights.get(domain,.1))+float(choices[choice])
		plan.research_weights=weights
		controller.research_orders(WorldSimulation.actor_id,plan)
func set_delegated(area:String,enabled:bool)->void:
	match area:
		"scouting":auto_scouting=enabled
		"settlement":auto_settlement=enabled
		"research":auto_research=enabled
	inclination_review_day=-1
	if enabled:apply_inclinations(int(WorldSimulation.state.elapsed_days))
