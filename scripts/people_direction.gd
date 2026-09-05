extends Node

const VALUES=preload("res://scripts/societal_values_model.gd")
const AMBITIONS:={
	"horizons":{"name":"Know the wider world","vision":"Become a people whose knowledge travels beyond familiar ground.","domains":["logistics","ecology"],"axis":"openness","target":.8,"effect":"25% faster logistics and ecology research; 5% slower research elsewhere. Openness grows gradually."},
	"makers":{"name":"Create things that endure","vision":"Become known for skill, ingenuity, and work worth passing down.","domains":["production","infrastructure"],"axis":"achieved_status","target":.8,"effect":"25% faster production and infrastructure research; 5% slower research elsewhere. Earned standing grows gradually."},
	"gathering":{"name":"Bring people together","vision":"Build a shared identity spacious enough for different communities.","domains":["culture","institutions"],"axis":"pluralism","target":.8,"effect":"25% faster culture and institutions research; 5% slower research elsewhere. Acceptance of differences grows gradually."},
	"inquiry":{"name":"Become a people of ideas","vision":"Make questioning, teaching, and discovery part of everyday culture.","domains":["knowledge","health"],"axis":"experimentation","target":.8,"effect":"25% faster knowledge and health research; 5% slower research elsewhere. Openness to experimentation grows gradually."}
}
const VISIONS:=[
	{"title":"Whose knowledge travels?","role":"Explorer","other":"Scholar","question":"Some argue that useful knowledge should circulate freely. Others want to preserve a trusted teaching tradition before spreading it.","options":[{"label":"Share what we learn","axis":"openness","delta":.04,"meaning":"Make openness to outsiders a stronger public value."},{"label":"Strengthen our own teaching","axis":"collective_obligation","delta":.04,"meaning":"Strengthen the duty to pass knowledge on within the community."}]},
	{"title":"What earns a voice?","role":"Organizer","other":"Artist","question":"Should influence follow demonstrated contribution, or the confidence of the wider community? Both visions promise a different kind of authority.","options":[{"label":"Recognize demonstrated contribution","axis":"achieved_status","delta":.04,"meaning":"Give earned achievement more weight than inherited standing."},{"label":"Broaden participation","axis":"hierarchy","delta":-.04,"meaning":"Move public values toward more equal standing."}]},
	{"title":"How much room for disagreement?","role":"Scholar","other":"General","question":"Some see disagreement as a source of discovery. Others believe a shared commitment gives people the confidence to undertake larger ambitions.","options":[{"label":"Protect room to disagree","axis":"pluralism","delta":.04,"meaning":"Make different viewpoints more legitimate."},{"label":"Build a common commitment","axis":"collective_obligation","delta":.04,"meaning":"Strengthen obligations to shared purposes."}]}
]
var ambition:=""
var chosen_day:=-1
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
	ambition=""; chosen_day=-1; last_day=0; resolved=0; next_vision_day=30; automatic_work=true; work_baseline={}; work_day=-30; history.clear(); initialized=false
	if is_instance_valid(panel): panel.queue_free()

func choose(id:String)->Dictionary:
	ensure()
	if not AMBITIONS.has(id): return {"error":"Unknown ambition."}
	var day:=int(GameState.elapsed_days)
	if id==ambition: return {"error":"This is already your ambition."}
	if chosen_day>=0 and day-chosen_day<365: return {"error":"Let this direction develop for a year before changing it."}
	ambition=id; chosen_day=day; last_day=day
	if GameState.founding_focus=="":
		# Complete the old time gate without applying an unrelated survival preset.
		GameState.founding_focus="collective_ambition"
		GameState.founding_focus_selected_day=day
		GameState.founding_banner_index=AMBITIONS.keys().find(id)
	_log(day,"Chose to "+String(AMBITIONS[id].name).to_lower()+".")
	return {"ok":true}

func research_multiplier(domain:String)->float:
	ensure()
	if ambition=="": return 1.0
	return 1.25 if domain in AMBITIONS[ambition].domains else .95

func advance(day:int)->void:
	ensure()
	if day<=last_day: return
	if ambition!="":
		var axis:String=AMBITIONS[ambition].axis
		var state:Dictionary=VALUES.normalize_state(GameState.societal_values)
		state.official[axis]=move_toward(float(state.official[axis]),float(AMBITIONS[ambition].target),float(day-last_day)*.00008)
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

func export_state()->Dictionary:
	ensure()
	return {"version":1,"network":CommunityNetwork.export_state(),"seed":seed_value,"ambition":ambition,"chosen_day":chosen_day,"last_day":last_day,"resolved":resolved,"next_vision_day":next_vision_day,"automatic_work":automatic_work,"work_baseline":work_baseline.duplicate(true),"work_day":work_day,"history":history.duplicate(true)}

func import_state(state:Dictionary)->Dictionary:
	if state.get("version",0)!=1 or state.get("seed",0)!=GameState.world_seed: return {"error":"Incompatible people-direction save."}
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
	return {"ok":true}

func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:
		open_direction(); get_viewport().set_input_as_handled()

func open_direction()->void:
	ensure()
	if is_instance_valid(panel):
		if GameState.founding_focus!="": panel.queue_free()
		return
	if not is_instance_valid(layer): layer=CanvasLayer.new(); layer.layer=81; add_child(layer)
	panel=preload("res://scripts/people_direction_screen.gd").new(); layer.add_child(panel)
