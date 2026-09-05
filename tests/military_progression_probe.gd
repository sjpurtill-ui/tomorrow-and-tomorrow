extends Node
## Probes the §18 unit-progression framework: archetype catalog integrity,
## the 7-state capability ladder, the prototype fielding path, experimental
## equipment batches, and readiness bands.

const UnitCatalog:=preload("res://scripts/military_unit_catalog.gd")
var failures:Array[String]=[]


func _ready()->void:
	GameState.reset_for_new_world(661144)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("defense")
	GameState.initialize_population_model()

	# Catalog integrity: every archetype is a real simulator unit with real
	# equipment, valid lineage, and resolvable gates.
	var simulator:RefCounted=MilitaryCampaign.simulator
	for unit_variant in UnitCatalog.ARCHETYPES:
		var unit:=String(unit_variant)
		_expect(simulator.UNIT_TYPES.has(unit),"archetype %s missing from combat simulator" % unit)
		for item in UnitCatalog.equipment_for(unit):
			_expect(simulator.WEAPONS.has(String(item)),"%s equipment %s missing from simulator" % [unit,item])
		var lineage:=UnitCatalog.lineage_for(unit)
		_expect(lineage=="" or UnitCatalog.ARCHETYPES.has(lineage),"%s lineage %s unknown" % [unit,lineage])
		for field in ["label","branch","era","purpose","sustainment","politics"]:
			_expect(String(UnitCatalog.archetype(unit).get(field,""))!="","%s missing %s" % [unit,field])
	_expect(MilitaryCampaign.validate_military_progression().is_empty(),"gate validation failed: %s" % str(MilitaryCampaign.validate_military_progression()))

	# Capability ladder: baseline levy is established; cavalry starts below
	# understood, becomes understood (prototype-ready, not fieldable) when the
	# discovery lands without adoption.
	_expect(String(MilitaryCampaign.unit_capability_state("levy").get("state",""))!="unobserved","levy should never be unobserved")
	var cavalry_before:=String(MilitaryCampaign.unit_capability_state("cavalry").get("state",""))
	_expect(cavalry_before in ["unobserved","observed"],"fresh cavalry state is %s" % cavalry_before)
	for id in ["seasonal_patterns","animal_taming","pack_animals","domesticated_mounts","bronze_weaponry"]:
		if id not in GameState.known_discoveries: GameState.known_discoveries.append(id)
	var cavalry_state:Dictionary=MilitaryCampaign.unit_capability_state("cavalry")
	_expect(String(cavalry_state.get("state",""))=="understood","known-unadopted cavalry state is %s" % cavalry_state.get("state"))
	_expect(bool(cavalry_state.get("can_prototype",false)),"understood cavalry cannot prototype")
	_expect(not bool(cavalry_state.get("can_field",true)),"understood cavalry can field normally")

	# Prototype path: one bounded experimental cohort; a second is refused.
	MilitaryCampaign.raise_recruits(40)
	var prototype:Dictionary=MilitaryCampaign.start_training("cavalry","sword_shield",20)
	_expect(bool(prototype.get("prototype",false)),"prototype flag missing: %s" % prototype.get("error",prototype.get("message","")))
	_expect(int(prototype.get("accepted",0))<=MilitaryCampaign.PROTOTYPE_COHORT_LIMIT,"prototype cohort exceeded limit (%d)" % int(prototype.get("accepted",0)))
	var second:Dictionary=MilitaryCampaign.start_training("cavalry","sword_shield",8)
	_expect(second.has("error"),"second prototype cohort was allowed")

	# Experimental equipment: bounded batch of an understood item; oversize refused.
	GameState.resource_stockpiles["Timber"]=500.0
	GameState.resource_stockpiles["Stone"]=500.0
	GameState.resource_stockpiles["Copper Ore"]=500.0
	GameState.resource_stockpiles["Fiber Plants"]=500.0
	GameState.resource_stockpiles["Iron Ore"]=500.0
	var oversize:Dictionary=MilitaryCampaign.queue_equipment_production("lance",30)
	_expect(oversize.has("error"),"oversize experimental batch was allowed")
	var batch:Dictionary=MilitaryCampaign.queue_equipment_production("lance",6)
	_expect(bool(batch.get("experimental",false)),"experimental batch not flagged: %s" % batch.get("error",""))

	# Readiness bands map the continuous state onto the §18.4 ladder.
	_expect(UnitCatalog.readiness_band({"training":0.9,"personnel_condition":1.0,"experience":0.0})=="READY","band for 0.9 training wrong")
	_expect(UnitCatalog.readiness_band({"training":0.6,"personnel_condition":1.0,"experience":0.6})=="VETERAN","veteran overlay wrong")
	_expect(UnitCatalog.readiness_band({"training":0.9,"personnel_condition":0.2,"experience":0.0})=="BROKEN","broken band wrong")
	_expect(UnitCatalog.readiness_band({"training":0.1,"personnel_condition":1.0,"experience":0.0})=="ASSEMBLING","assembling band wrong")
	_finish()


func _expect(condition:bool,message:String)->void:
	if not condition:
		failures.append(message)
		push_error("MILITARY_PROGRESSION_PROBE %s" % message)


func _finish()->void:
	if failures.is_empty():
		print("MILITARY_PROGRESSION_PROBE PASS")
		get_tree().quit(0)
	else:
		print("MILITARY_PROGRESSION_PROBE FAIL (%d)" % failures.size())
		get_tree().quit(1)
