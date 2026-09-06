extends Node

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
	"commerce":{"name":"Grow through exchange","vision":"Build the skills and connections that make useful goods travel. Trade still needs real partners and routes.","domains":["production","logistics"],"axis":"openness","target":.8,"effect":"25% faster production and logistics research; 5% slower elsewhere. Openness grows gradually."}
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

func ensure()->void:
	if initialized and seed_value==GameState.world_seed: return
	reset_for_new_world(); seed_value=GameState.world_seed; initialized=true; last_day=int(GameState.elapsed_days)
	next_vision_day=last_day+30

func reset_for_new_world()->void:
	ambition=""; chosen_day=-1; chosen_century=-1; last_day=0; resolved=0; next_vision_day=30; automatic_work=true; work_baseline={}; work_day=-30; history.clear(); initialized=false
	if is_instance_valid(panel): panel.queue_free()

func choose(id:String)->Dictionary:
	ensure()
	if not AMBITIONS.has(id): return {"error":"Unknown ambition."}
	var day:=int(GameState.elapsed_days)
	if not needs_century_choice(): return {"error":"This century's focus is already chosen. Reconsider at the start of the next century."}
	ambition=id; chosen_day=day; chosen_century=century_at(day); last_day=day
	if GameState.founding_focus=="":
		# Complete the old time gate without applying an unrelated survival preset.
		GameState.founding_focus="collective_ambition"
		GameState.founding_focus_selected_day=day
		GameState.founding_banner_index=AMBITIONS.keys().find(id)%4
	_log(day,"Century %d: chose to %s." % [chosen_century+1,String(AMBITIONS[id].name).to_lower()])
	return {"ok":true}

func century_at(day:int)->int:
	return maxi(0,day)/CENTURY_DAYS

func needs_century_choice()->bool:
	ensure()
	return ambition.is_empty() or chosen_century!=century_at(int(GameState.elapsed_days))

func next_century_day()->int:
	return (century_at(int(GameState.elapsed_days))+1)*CENTURY_DAYS

func research_multiplier(domain:String)->float:
	ensure()
	if needs_century_choice(): return 1.0
	return 1.25 if domain in AMBITIONS[ambition].domains else .95

func advance(day:int)->void:
	ensure()
	if day<=last_day: return
	if ambition!="" and chosen_century>=0:
		var axis:String=AMBITIONS[ambition].axis
		var state:Dictionary=VALUES.normalize_state(GameState.societal_values)
		var active_days:=maxi(0,mini(day,(chosen_century+1)*CENTURY_DAYS)-maxi(last_day,chosen_day))
		state.official[axis]=move_toward(float(state.official[axis]),float(AMBITIONS[ambition].target),float(active_days)*.00008)
		GameState.societal_values=VALUES.normalize_state(state)
	last_day=day

func decide(option:int)->Dictionary:
	ensure()
	var day:=int(GameState.elapsed_days)
	if ambition=="" or resolved>=VISIONS.size() or day<next_vision_day: return {"error":"There is no vision awaiting your support."}
	if option<0 or option>=2: return {"error":"Unknown vision."}
	var choice:Dictionary=VISIONS[resolved].options[option]
	var state:Dictionary=VALUES.normalize_state(GameState.societal_values)
	state.official[choice.axis]=clampf(float(state.official[choice.axis])+float(choice.delta),0,1)
	GameState.societal_values=VALUES.normalize_state(state)
	_log(day,String(choice.label)+". "+String(choice.meaning))
	resolved+=1; next_vision_day=day+180
	return {"ok":true}

func _log(day:int,message:String)->void:
	history.push_front({"day":day,"text":message})
	if history.size()>24: history.resize(24)

func advocate(role:String)->String:
	HistoricalFigures.ensure()
	for p in HistoricalFigures.people:
		if p.role==role and p.status=="living": return String(p.name)+", "+role.to_lower()
	return "Community voices"

func routine_work(_day:int)->void:
	# Compatibility entry point. GovernmentPeopleSystem owns daily labor delegation.
	ensure()

func advisor_recommendations()->Array[Dictionary]:
	# Read the existing redacted knowledge surface, never raw rival records.
	var known:Array=[]
	for record in CivilizationSystem.known_competition_snapshot().get("leaders",[]):
		if String(record.get("id",""))=="player": continue
		var relation:Dictionary=record.get("player_relation",{})
		if int(relation.get("contact_level",0))<2: continue
		known.append({"name":String(record.get("name","A contacted community")),"at_war":bool(relation.get("at_war",false)),"trade":float(relation.get("trade",0.0))>0.0})
	known.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return String(a.name)<String(b.name))
	var result:Array[Dictionary]=[]
	for office in GovernmentPeopleSystem.active_offices():
		var person:=GovernmentPeopleSystem.officeholder(String(office.key))
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
	var focus:=String({"Steward":"gathering","Quartermaster":"makers","Marshal":"military","Scholar":"inquiry","Envoy":"horizons"}.get(role,"gathering"))
	var why:=String({"Steward":"A shared civic life helps our settlements work together.","Quartermaster":"Durable tools and infrastructure make our existing labor more useful.","Marshal":"Reliable military organization and supply give us more options without committing us to war.","Scholar":"Sustained inquiry builds our capacity to test claims rather than rely on hearsay.","Envoy":"Returned journeys and direct contact can give future decisions a firmer basis."}.get(role,"Our institutions need a durable common purpose."))
	if role in ["Steward","Quartermaster"] and float(GameState.simulation_metrics.get("food_days",30.0))<15.0:
		focus="sustenance"; why="Our reported food reserve is low; I would put dependable food systems ahead of other ambitions."
	elif role=="Steward" and GameState.population_health<0.65:
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
	return {"version":2,"chosen_century":chosen_century,"network":CommunityNetwork.export_state(),"seed":seed_value,"ambition":ambition,"chosen_day":chosen_day,"last_day":last_day,"resolved":resolved,"next_vision_day":next_vision_day,"automatic_work":automatic_work,"work_baseline":work_baseline.duplicate(true),"work_day":work_day,"history":history.duplicate(true)}

func import_state(state:Dictionary)->Dictionary:
	if int(state.get("version",0)) not in [1,2] or state.get("seed",0)!=GameState.world_seed: return {"error":"Incompatible people-direction save."}
	var imported_century:=int(state.get("chosen_century",-1))
	if int(state.version)==1:
		# Preserve the player's existing ambition for their current century, rather
		# than replacing it with an assistant/game choice when an old save loads.
		imported_century=century_at(int(GameState.elapsed_days)) if String(state.get("ambition",""))!="" else -1
	if imported_century < -1 or imported_century>century_at(int(GameState.elapsed_days)): return {"error":"Invalid focus century."}
	if (String(state.get("ambition",""))=="")!=(imported_century==-1): return {"error":"Focus and century disagree."}
	if state.get("ambition","")!="" and not AMBITIONS.has(state.ambition): return {"error":"Invalid ambition."}
	if int(state.get("resolved",0))<0 or int(state.get("resolved",0))>VISIONS.size() or not state.get("history",[]) is Array or state.get("history",[]).size()>24: return {"error":"Invalid vision history."}
	if not state.get("work_baseline",{}) is Dictionary: return {"error":"Invalid automatic work baseline."}
	for value in state.get("work_baseline",{}).values():
		if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0: return {"error":"Invalid work share."}
	for event in state.get("history",[]):
		if not event is Dictionary or not event.has_all(["day","text"]): return {"error":"Invalid history record."}
	if state.has("network"):
		if not state.network is Dictionary: return {"error":"Invalid network save."}
		var network_result:=CommunityNetwork.import_state(state.network)
		if network_result.has("error"): return network_result
	else:
		CommunityNetwork.reset_for_new_world(); CommunityNetwork.ensure()
	ambition=state.get("ambition",""); chosen_day=int(state.get("chosen_day",-1)); last_day=int(state.get("last_day",0)); resolved=int(state.get("resolved",0)); next_vision_day=int(state.get("next_vision_day",30)); automatic_work=bool(state.get("automatic_work",true)); work_baseline=state.get("work_baseline",{}).duplicate(true); work_day=int(state.get("work_day",-30)); history.assign(state.get("history",[]).duplicate(true)); seed_value=GameState.world_seed; initialized=true
	chosen_century=imported_century
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
	panel=preload("res://scripts/people_direction_screen.gd").new(); layer.add_child(panel)
