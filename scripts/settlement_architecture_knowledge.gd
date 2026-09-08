extends RefCounted
static func entries()->Array[Dictionary]:
	return [
		_entry("structural_steel","Structural Steel Frames",["blast_furnace","precision_machinery"],60000,{"construction_rate":.10,"housing_output":.10}),
		_entry("reinforced_concrete","Reinforced Concrete",["structural_steel","lime_mortar"],65000,{"construction_rate":.12,"disaster_resilience":.08}),
		_entry("safety_lifts","Safety Lifts",["precision_machinery","steam_power"],64000,{"housing_output":.12,"haul_capacity":.04}),
		_entry("curtain_wall_systems","Glazed Curtain Walls",["structural_steel","reinforced_concrete","standard_measures"],73000,{"construction_rate":.06,"craft_output":.04})]
static func _entry(id:String,title:String,requires:Array,day:int,effects:Dictionary)->Dictionary:
	return {"id":id,"name":title,"direction":"Infrastructure","day":day,"chance":.001,"requires":requires,"signals":["construction","materials","crafting"],"observation":"Builders test and standardize "+title.to_lower()+" before adopting it in new construction. Existing districts retain their inherited fabric.","effects":effects}
static func adopted(id:String)->bool:
	return id in GameState.known_discoveries and float(GameState.discovery_adoption.get(id,0))>=.2
static func ceiling()->int:
	if adopted("reinforced_concrete") and adopted("safety_lifts"):return 12
	if adopted("structural_steel"):return 11
	return 10
