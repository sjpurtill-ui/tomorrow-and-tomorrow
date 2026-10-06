extends RefCounted
static func entries()->Array[Dictionary]:
	return [
		_entry("structural_steel","Structural Steel Frames",["blast_furnace","precision_machinery"],60000,{"construction_rate":.10,"housing_output":.10}),
		_entry("reinforced_concrete","Reinforced Concrete",["structural_steel","lime_mortar"],65000,{"construction_rate":.12,"disaster_resilience":.08}),
		_entry("safety_lifts","Safety Lifts",["precision_machinery","steam_propulsion"],64000,{"housing_output":.12,"haul_capacity":.04}),
		_entry("curtain_wall_systems","Glazed Curtain Walls",["structural_steel","reinforced_concrete","standard_measures"],73000,{"construction_rate":.06,"craft_output":.04})]
static func _entry(id:String,title:String,requires:Array,day:int,effects:Dictionary)->Dictionary:
	return {"id":id,"name":title,"direction":"Infrastructure","day":day,"chance":.001,"requires":requires,"signals":["construction","materials","crafting"],"observation":"Builders test and standardize "+title.to_lower()+" before adopting it in new construction. Existing districts retain their inherited fabric.","effects":effects}
static func adopted(id:String)->bool:
	return id in WorldSimulation.state.known_discoveries and float(WorldSimulation.state.discovery_adoption.get(id,0))>=.2
static func ceiling()->int:
	if adopted("reinforced_concrete") and adopted("safety_lifts"):return 12
	if adopted("structural_steel"):return 11
	return 10

## Adopted practices for each physical form, independent of a town's age.
## Alternatives allow timber, earth and masonry traditions to develop.
const FABRIC_PRACTICES:={
	2:[["framed_construction","timber_post_beam_connections","central_hall_houses"]],
	3:[["adobe_wall_construction","mould_made_mudbricks","dry_stone_walls","timber_post_beam_connections"]],
	4:[["graded_roads","stone_lined_drains","urban_street_plans"]],
	5:[["shared_party_walls","standard_lot_grid_towns","urban_street_plans"]],
	6:[["stone_lined_drains","street_gutter_gratings","building_drainage_coordination"]],
	7:[["dressed_stone_masonry","kiln_fired_bricks","ashlar_masonry"]],
	8:[["urban_street_plans","standard_lot_grid_towns"]],
	9:[["stone_merchant_houses","jettied_timber_houses","stone_party_walls"]],
	10:[["vaulted_brick_sewers","street_utility_ducts"]],
	11:[["structural_steel"],["rotative_steam_engine","central_power_stations"]],
	12:[["reinforced_concrete"],["safety_lifts"]]
}

static func fabric_checks(tier:int)->Array[Dictionary]:
	var checks:Array[Dictionary]=[]
	for group:Array in FABRIC_PRACTICES.get(tier,[]):
		var met:=group.any(func(id:Variant)->bool:return adopted(String(id)))
		checks.append({"what":"practice","have":1 if met else 0,"need":1,"met":met,"practices":group.duplicate()})
	return checks
