extends Node

signal campaign_goal_ready(goal: Dictionary)
signal generation_failed(reason: String)

const ALLOWED_METRICS := {
	"population":Vector2(220.0,25000.0),
	"food_days":Vector2(30.0,180.0),
	"health":Vector2(0.55,0.92),
	"cohesion":Vector2(0.50,0.90),
	"knowledge":Vector2(0.30,0.92),
	"material_capacity":Vector2(0.30,0.92),
	"logistics":Vector2(0.30,0.90),
	"security":Vector2(0.50,0.92),
	"ecology":Vector2(0.48,0.92),
	"legitimacy":Vector2(0.50,0.92),
	"resource_access":Vector2(1.0,8.0),
	"completed_works":Vector2(3.0,12.0),
	"discoveries":Vector2(5.0,24.0)
}

const ALLOWED_PRESSURES := ["lean_harvest","harsh_winter","abundant_game","divided_camp","curious_youth","sickly_arrival","skilled_craftspeople","sacred_land","migratory_pressure","mineral_signs"]

var request_node: HTTPRequest
var pending_fallback: Dictionary = {}

func reset_for_new_world()->void:
	pending_fallback={}
	if request_node and is_instance_valid(request_node):
		request_node.cancel_request()
		request_node.queue_free()
	request_node=null

func request_campaign_goal(public_context: Dictionary) -> void:
	if not GameState.campaign_goal.is_empty():
		campaign_goal_ready.emit.call_deferred(GameState.campaign_goal)
		return
	var fallback := _local_goal(public_context)
	pending_fallback=fallback
	var endpoint := OS.get_environment("LEVIATHAN_AI_ENDPOINT").strip_edges()
	var api_key := OS.get_environment("LEVIATHAN_AI_API_KEY").strip_edges()
	if api_key.is_empty(): api_key=OS.get_environment("OPENAI_API_KEY").strip_edges()
	var model := OS.get_environment("LEVIATHAN_AI_MODEL").strip_edges()
	if endpoint.is_empty() and not OS.get_environment("OPENAI_API_KEY").strip_edges().is_empty():
		endpoint="https://api.openai.com/v1/chat/completions"
	if endpoint.is_empty() or api_key.is_empty() or model.is_empty():
		_accept_goal(fallback,"seeded director")
		return
	request_node=HTTPRequest.new()
	add_child(request_node)
	request_node.timeout=25.0
	request_node.request_completed.connect(_on_goal_response)
	var prompt := _goal_prompt(public_context)
	var payload := {
		"model":model,
		"temperature":1.05,
		"messages":[
			{"role":"system","content":"You are the campaign director for a rigorous civilization simulation. Return only one JSON object matching the requested contract. Never invent mechanics outside the allowed vocabulary."},
			{"role":"user","content":prompt}
		]
	}
	var headers := PackedStringArray(["Content-Type: application/json","Authorization: Bearer %s" % api_key])
	var error := request_node.request(endpoint,headers,HTTPClient.METHOD_POST,JSON.stringify(payload))
	if error!=OK:
		generation_failed.emit("The generative service could not be reached.")
		_accept_goal(fallback,"seeded director")

func _goal_prompt(context: Dictionary) -> String:
	return """Create one unusual but achievable founding mandate for a civilization simulation.
PUBLIC START: %s
The campaign covers the first 20–200 years. The player is the sovereign, beginning with 120 settlers. Knowledge is discovered organically; never name a hidden technology or resource.

Return exactly this JSON shape:
{
  "title": "2–7 evocative words",
  "premise": "2 concise sentences",
  "values": ["2–4 short cultural principles"],
  "horizon_years": 20–200,
  "conditions": [{"metric":"allowed metric","target":number,"direction":"above","label":"plain-language promise"}],
  "pressures": [{"id":"allowed pressure","magnitude":0.08–0.30,"duration_years":1–40,"description":"what the people experience"}],
  "opening_counsel": "one advisor-style paragraph, without spoilers"
}
Use 3 or 4 conditions and 1 or 2 pressures.
Allowed metric ranges: %s
Allowed pressures: %s
Make tradeoffs possible: at least one condition should pull labor or policy against another. Do not write numerical effects in prose.""" % [JSON.stringify(context),JSON.stringify(ALLOWED_METRICS),JSON.stringify(ALLOWED_PRESSURES)]

func _on_goal_response(result: int,response_code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	var accepted := false
	if result==HTTPRequest.RESULT_SUCCESS and response_code>=200 and response_code<300:
		var envelope = JSON.parse_string(body.get_string_from_utf8())
		if envelope is Dictionary:
			var content := ""
			var choices: Array = envelope.get("choices",[])
			if not choices.is_empty() and choices[0] is Dictionary:
				content=String(choices[0].get("message",{}).get("content",""))
			if content.is_empty(): content=String(envelope.get("text",""))
			var first_brace := content.find("{")
			var last_brace := content.rfind("}")
			if first_brace>=0 and last_brace>first_brace:
				var proposed=JSON.parse_string(content.substr(first_brace,last_brace-first_brace+1))
				if proposed is Dictionary:
					var validated := _validate_goal(proposed,pending_fallback)
					_accept_goal(validated,"generative API")
					accepted=true
	if not accepted:
		generation_failed.emit("The generative response was unavailable or failed validation; the seeded director supplied a mandate.")
		_accept_goal(pending_fallback,"seeded director")
	if request_node:
		request_node.queue_free()
		request_node=null

func _accept_goal(goal: Dictionary,source: String) -> void:
	GameState.campaign_goal_source=source
	ConsequenceEngine.apply_campaign_goal(goal)
	campaign_goal_ready.emit(goal)

func _validate_goal(proposed: Dictionary,fallback: Dictionary) -> Dictionary:
	var goal := fallback.duplicate(true)
	var title := String(proposed.get("title","")).strip_edges()
	if title.length()>=4 and title.length()<=64: goal["title"]=title
	var premise := String(proposed.get("premise","")).strip_edges()
	if premise.length()>=30 and premise.length()<=520: goal["premise"]=premise
	goal["horizon_years"]=clampf(float(proposed.get("horizon_years",goal.horizon_years)),20.0,200.0)
	var horizon_years:=float(goal.horizon_years)
	var values: Array[String] = []
	for value in proposed.get("values",[]):
		var cleaned := String(value).strip_edges()
		if cleaned.length()>=3 and cleaned.length()<=48 and cleaned not in values: values.append(cleaned)
		if values.size()>=4: break
	if values.size()>=2: goal["values"]=values
	var conditions: Array[Dictionary] = []
	for condition in proposed.get("conditions",[]):
		if not condition is Dictionary: continue
		var metric := String(condition.get("metric",""))
		if not ALLOWED_METRICS.has(metric): continue
		var bounds: Vector2=ALLOWED_METRICS[metric]
		var target := clampf(float(condition.get("target",bounds.x)),bounds.x,bounds.y)
		if metric=="population": target=minf(target,maxf(220.0,GameState.population_exact*pow(1.025,horizon_years)*1.15))
		elif metric=="completed_works": target=minf(target,5.0)
		elif metric=="resource_access": target=minf(target,maxf(1.0,float(GameState.resource_deposits.size())))
		elif metric=="discoveries": target=minf(target,maxf(5.0,minf(24.0,horizon_years*0.45)))
		var label := String(condition.get("label",metric.capitalize())).strip_edges()
		if label.length()>100: label=label.left(100)
		conditions.append({"metric":metric,"target":target,"direction":"above","label":label})
		if conditions.size()>=4: break
	if conditions.size()>=3: goal["conditions"]=conditions
	var pressures: Array[Dictionary] = []
	for pressure in proposed.get("pressures",[]):
		if not pressure is Dictionary: continue
		var effect_id := String(pressure.get("id",""))
		if effect_id not in ALLOWED_PRESSURES: continue
		pressures.append({
			"id":effect_id,
			"magnitude":clampf(float(pressure.get("magnitude",0.12)),0.08,0.30),
			"duration_years":clampf(float(pressure.get("duration_years",8.0)),1.0,40.0),
			"description":String(pressure.get("description",effect_id.replace("_"," ").capitalize())).left(180)
		})
		if pressures.size()>=2: break
	if not pressures.is_empty(): goal["pressures"]=pressures
	var counsel := String(proposed.get("opening_counsel","")).strip_edges()
	if counsel.length()>=20 and counsel.length()<=480: goal["opening_counsel"]=counsel
	return goal

func _local_goal(context: Dictionary) -> Dictionary:
	var archetypes: Array[Dictionary] = [
		{"title":"The Long Table","premise":"The founders swear that no household will starve while another keeps abundance. Build a populous and legitimate commonwealth without destroying the land that feeds it.","values":["Common provision","Measured growth","Shared obligation"],"horizon_years":70,"conditions":[{"metric":"population","target":600,"direction":"above","label":"Raise a people of at least 600"},{"metric":"food_days","target":75,"direction":"above","label":"Keep seventy-five days of food"},{"metric":"legitimacy","target":0.72,"direction":"above","label":"Make sovereign authority broadly legitimate"},{"metric":"ecology","target":0.62,"direction":"above","label":"Leave the surrounding land resilient"}],"pressures":[{"id":"lean_harvest","magnitude":0.12,"duration_years":6,"description":"The first gathering grounds are less generous than expected."}],"opening_counsel":"Sovereign, the oath is admired, but admiration will not fill the stores. Every hand assigned elsewhere is a promise that the gatherers must somehow carry."},
		{"title":"Keepers of the Living Vale","premise":"The people believe the valley is borrowed from generations yet unborn. Grow into a learned civilization while preserving the fertility and wild abundance around it.","values":["Stewardship","Patient inquiry","Continuity"],"horizon_years":90,"conditions":[{"metric":"population","target":600,"direction":"above","label":"Support six hundred people"},{"metric":"discoveries","target":16,"direction":"above","label":"Establish sixteen discoveries"},{"metric":"ecology","target":0.78,"direction":"above","label":"Preserve a thriving landscape"},{"metric":"health","target":0.76,"direction":"above","label":"Sustain a healthy population"}],"pressures":[{"id":"sacred_land","magnitude":0.18,"duration_years":40,"description":"Many founders resist wasteful use of nearby land."},{"id":"curious_youth","magnitude":0.12,"duration_years":18,"description":"A restless generation closely observes every new practice."}],"opening_counsel":"Sovereign, restraint may preserve possibilities we cannot yet name. It will also make every early shortage more politically dangerous."},
		{"title":"Stone Before Winter","premise":"The caravan came seeking permanence in a hard country. Turn a vulnerable camp into a materially capable stronghold before isolation becomes decline.","values":["Endurance","Craft mastery","Preparedness"],"horizon_years":55,"conditions":[{"metric":"completed_works","target":5,"direction":"above","label":"Establish five enduring communal works"},{"metric":"material_capacity","target":0.66,"direction":"above","label":"Develop strong material capacity"},{"metric":"resource_access","target":3,"direction":"above","label":"Secure access to three resources"},{"metric":"security","target":0.68,"direction":"above","label":"Make the settlement defensible"}],"pressures":[{"id":"harsh_winter","magnitude":0.20,"duration_years":12,"description":"Long winters shorten the reliable gathering season."},{"id":"mineral_signs","magnitude":0.14,"duration_years":20,"description":"Unusual stone draws the attention of survey parties."}],"opening_counsel":"Sovereign, builders, carriers, surveyors, and guards all claim urgency. We do not possess enough hands to satisfy them together."},
		{"title":"A Commonwealth of Questions","premise":"The founders reject inherited certainty and bind themselves to observation. Create a durable culture of discovery without sacrificing ordinary lives to inquiry.","values":["Evidence","Open counsel","Human flourishing"],"horizon_years":100,"conditions":[{"metric":"discoveries","target":22,"direction":"above","label":"Preserve twenty-two discoveries"},{"metric":"knowledge","target":0.78,"direction":"above","label":"Build a mature culture of inquiry"},{"metric":"health","target":0.78,"direction":"above","label":"Keep knowledge in service of health"},{"metric":"cohesion","target":0.68,"direction":"above","label":"Prevent inquiry from dividing the people"}],"pressures":[{"id":"curious_youth","magnitude":0.24,"duration_years":30,"description":"Many young founders abandon routine assumptions and demand evidence."},{"id":"divided_camp","magnitude":0.10,"duration_years":8,"description":"Some elders see constant questioning as an attack on order."}],"opening_counsel":"Sovereign, observers require food, shelter, and time like everyone else. If you protect their work, others must carry a heavier immediate burden."},
		{"title":"The Unbroken Hearth","premise":"Illness marked the final months of the migration, and survival has become a civic promise. Make health, cohesion, and dependable provision the foundation of power.","values":["Care","Reliability","Mutual defense"],"horizon_years":65,"conditions":[{"metric":"health","target":0.84,"direction":"above","label":"Restore exceptional public health"},{"metric":"food_days","target":90,"direction":"above","label":"Maintain a season of reserve food"},{"metric":"cohesion","target":0.76,"direction":"above","label":"Bind the settlement together"},{"metric":"population","target":420,"direction":"above","label":"Grow beyond four hundred people"}],"pressures":[{"id":"sickly_arrival","magnitude":0.18,"duration_years":5,"description":"Lingering sickness reduces the strength of the founding generation."}],"opening_counsel":"Sovereign, care consumes labor before it creates strength. The promise can hold, but only if the healthy accept burdens whose reward lies years ahead."},
		{"title":"Hands of Many Crafts","premise":"The founders dream of a civilization known for making what others cannot. Secure resources, cultivate skill, and turn scattered ingenuity into lasting capacity.","values":["Mastery","Useful abundance","Exchange"],"horizon_years":80,"conditions":[{"metric":"material_capacity","target":0.80,"direction":"above","label":"Reach exceptional material capacity"},{"metric":"resource_access","target":5,"direction":"above","label":"Develop five resource chains"},{"metric":"logistics","target":0.70,"direction":"above","label":"Create dependable movement of goods"},{"metric":"population","target":650,"direction":"above","label":"Support six hundred and fifty inhabitants"}],"pressures":[{"id":"skilled_craftspeople","magnitude":0.20,"duration_years":24,"description":"Several founding families preserve unusually sophisticated craft habits."}],"opening_counsel":"Sovereign, talent is present, but talent without carriers, surveyors, stores, and steady food becomes ornament rather than power."}
	]
	var seeded := RandomNumberGenerator.new()
	seeded.seed=GameState.world_seed^0x53c91e7b^String(context.get("terrain","")).hash()
	return archetypes[seeded.randi_range(0,archetypes.size()-1)].duplicate(true)
