extends RefCounted
## Validate production additions before they enter the live catalog. Existing
## legacy records are retained without inventing retrospective authoring notes.
const Society=preload("res://scripts/society_model.gd")
const Land=preload("res://scripts/military_unit_catalog.gd")
const FOODS=["Fresh plants","Fresh meat","Fish","Dry staples","Preserved food"]
static func validate(additions:Array,catalog:Array)->Array[String]:
	var errors:Array[String]=[]
	var names:Dictionary={}
	var ids:Dictionary={}
	var by_id:Dictionary={}
	for entry:Dictionary in catalog:
		var name:=String(entry.get("name","")).strip_edges().to_lower()
		names[name]=int(names.get(name,0))+1
		var id:=String(entry.get("id",""))
		ids[id]=int(ids.get(id,0))+1
		by_id[id]=entry
	for entry:Dictionary in additions:
		var id:=String(entry.get("id",""))
		if int(ids.get(id,0))!=1:errors.append(id+": production identity must occur exactly once")
		# The live entry's name is its display identity: a design block may retitle a
		# module identity (Research600.apply), and the retitled name must be unique.
		var shown:=String((by_id.get(id,entry) as Dictionary).get("name",entry.get("name",""))).strip_edges().to_lower()
		if shown.is_empty() or int(names.get(shown,0))!=1:errors.append(id+": duplicate or missing display identity")
		for field:String in ["name","observation","production_contract"]:
			if not entry.get(field) is String or String(entry[field]).strip_edges().is_empty():errors.append(id+": missing "+field)
		if not entry.get("day") is int or int(entry.day)<0:errors.append(id+": invalid legacy ordering day")
		if not (entry.get("chance") is float or entry.get("chance") is int) or not is_finite(float(entry.chance)) or float(entry.chance)<=0 or float(entry.chance)>1:errors.append(id+": invalid discovery chance")
		var effects:Variant=entry.get("effects",{})
		if not effects is Dictionary:errors.append(id+": effects must be a dictionary");continue
		for effect:Variant in effects:
			if not Society.EFFECT_LIMITS.has(effect):errors.append(id+": unsupported effect "+String(effect));continue
			if not (effects[effect] is float or effects[effect] is int) or not is_finite(float(effects[effect])):errors.append(id+": invalid effect magnitude");continue
			var bounds:Vector2=Society.EFFECT_LIMITS[effect]
			if float(effects[effect])<bounds.x or float(effects[effect])>bounds.y:errors.append(id+": effect exceeds engine bounds")
		var profile:Variant=entry.get("preservation_profile",{})
		if not profile is Dictionary:errors.append(id+": preservation must be a dictionary");continue
		for food:Variant in profile:
			if food not in FOODS:errors.append(id+": unsupported food category")
			var value:Variant=profile[food]
			if not (value is float or value is int) or not is_finite(float(value)) or float(value)<=0 or float(value)>.5:errors.append(id+": invalid preservation reduction")
		var training:Variant=entry.get("training_profile",{})
		if not training is Dictionary:errors.append(id+": training must be a dictionary");continue
		for unit:Variant in training:
			if not Land.ARCHETYPES.has(unit):errors.append(id+": unsupported training role")
			var value:Variant=training[unit]
			if not (value is float or value is int) or not is_finite(float(value)) or float(value)<=0 or float(value)>.25:errors.append(id+": invalid training reduction")
		var prospecting:Variant=entry.get("prospecting_profile",{})
		if not prospecting is Dictionary:errors.append(id+": prospecting profile must be a dictionary");continue
		if not prospecting.is_empty():
			if prospecting.get("group","") not in preload("res://scripts/geoscience_knowledge.gd").GROUPS:errors.append(id+": unknown prospecting method family")
			var resources:Variant=prospecting.get("resources",[])
			if not resources is Array or resources.is_empty():errors.append(id+": prospecting needs resource targets")
			else:
				for resource:Variant in resources:
					if not resource is String or not WorldSimulation.resources.catalog.has(resource):errors.append(id+": unknown prospecting resource")
			var useful:=false
			for phase:String in ["recognition","survey"]:
				var value:Variant=prospecting.get(phase)
				if not (value is float or value is int) or not is_finite(float(value)) or float(value)<0 or float(value)>.4:errors.append(id+": invalid prospecting improvement")
				else:useful=useful or float(value)>0
			if not useful:errors.append(id+": prospecting profile has no implemented improvement")
		var children:Variant=entry.get("foundation_for",[])
		if not children is Array:errors.append(id+": foundation targets must be an array");continue
		for child:Variant in children:
			if not child is String or not by_id.has(child):errors.append(id+": unknown foundation target");continue
			if id not in preload("res://scripts/knowledge_pathways.gd").definition_parents(by_id[child]):errors.append(id+": foundation has no causal link to "+child)
		var products:Variant=entry.get("production_items",[])
		if not products is Array:errors.append(id+": production items must be an array");continue
		for item:Variant in products:
			var recipe:Dictionary=preload("res://scripts/civilian_industry.gd").product(String(item))
			if recipe.is_empty() or recipe.gate!=id:errors.append(id+": no implemented recipe for production item")
		var inspections:Variant=entry.get("inspection_items",[])
		if not inspections is Array:errors.append(id+": inspection items must be an array");continue
		for item:Variant in inspections:
			var recipe:Dictionary=preload("res://scripts/civilian_industry.gd").product(String(item))
			if recipe.is_empty() or recipe.get("inspection_gate","")!=id:errors.append(id+": no implemented inspection for item")
		var plants:Variant=entry.get("operating_plants",[])
		if not plants is Array:errors.append(id+": operating plants must be an array");continue
		for plant:Variant in plants:
			var definition:Dictionary=preload("res://scripts/technology_operations.gd").PLANTS.get(plant,{})
			if definition.is_empty() or definition.gate!=id:errors.append(id+": no implemented operating plant")
		var agronomy:Variant=entry.get("agronomy_profile",{})
		if not agronomy is Dictionary:errors.append(id+": agronomy profile must be a dictionary");continue
		if not agronomy.is_empty():
			if agronomy.get("group","") not in preload("res://scripts/agronomy_knowledge.gd").GROUPS:errors.append(id+": unknown agronomy family")
			if not agronomy.get("rank") is int or int(agronomy.get("rank",0))<1:errors.append(id+": invalid agronomy rank")
			var useful:=false
			for field:String in ["yield_gain","soil_protection","weather_buffer","labor_cost","land_cost"]:
				var value:Variant=agronomy.get(field)
				if not (value is float or value is int) or not is_finite(float(value)) or float(value)<0 or float(value)>.4:errors.append(id+": invalid agronomy coefficient")
				elif field in ["yield_gain","soil_protection","weather_buffer"]:useful=useful or float(value)>0
			if not useful:errors.append(id+": agronomy needs an operating benefit")
		var naval:=String(entry.get("naval_service_method",""))
		if not naval.is_empty() and (naval!=id or naval not in ["dry_dock_services","hull_condition_surveys"]):errors.append(id+": no implemented naval service")
		var clothing:=String(entry.get("clothing_method",""))
		if not clothing.is_empty() and (clothing!=id or not preload("res://scripts/clothing_knowledge.gd").METHODS.has(clothing)):errors.append(id+": no implemented clothing method")
		var batch:=String(entry.get("food_batch_method",""))
		if not batch.is_empty() and (batch!=id or not preload("res://scripts/food_batch_knowledge.gd").METHODS.has(batch)):errors.append(id+": no implemented food batch method")
		var conveyance:=String(entry.get("water_conveyance_method",""))
		if not conveyance.is_empty() and (conveyance!=id or conveyance not in preload("res://scripts/water_conveyance.gd").METHODS):errors.append(id+": no implemented conveyance method")
		var building:=String(entry.get("building_method",""))
		if not building.is_empty() and (building!=id or building not in preload("res://scripts/building_material_operations.gd").METHODS):errors.append(id+": no implemented building method")
		var grain:=String(entry.get("grain_method",""))
		if not grain.is_empty() and (grain!=id or not preload("res://scripts/grain_processing.gd").METHODS.has(grain)):errors.append(id+": no implemented grain method")
		var meal:=String(entry.get("meal_preparation",""))
		if not meal.is_empty() and (meal!=id or not preload("res://scripts/food_preparation.gd").METHODS.has(meal)):errors.append(id+": no implemented meal preparation")
		var nutrients:=bool(entry.get("nutrient_application",false))
		if nutrients and id!=preload("res://scripts/crop_nutrition.gd").GATE:errors.append(id+": no implemented nutrient application")
		var repair:=String(entry.get("repair_method",""))
		if not repair.is_empty() and (repair!=id or repair!=preload("res://scripts/field_repair.gd").ID):errors.append(id+": no implemented repair method")
		var clinical:=String(entry.get("clinical_care_method",""))
		if not clinical.is_empty() and (clinical!=id or clinical not in preload("res://scripts/civilian_care.gd").IDS.values()):errors.append(id+": unknown clinical service")
		var medical:=String(entry.get("medical_method",""))
		if not medical.is_empty() and (medical!=id or not preload("res://scripts/field_medicine.gd").METHODS.has(medical)):errors.append(id+": no implemented medical method")
		var doctrine:=String(entry.get("doctrine",""))
		if not doctrine.is_empty() and (doctrine!=id or not preload("res://scripts/combined_arms_doctrine.gd").RULES.has(doctrine)):errors.append(id+": no implemented doctrine")
		var military_unlock:=id in Land.EQUIPMENT_GATES.values() or Land.ARCHETYPES.values().any(func(unit:Dictionary)->bool:return String(unit.get("gate",""))==id)
		if clinical.is_empty() and naval.is_empty() and clothing.is_empty() and conveyance.is_empty() and building.is_empty() and batch.is_empty() and grain.is_empty() and meal.is_empty() and not nutrients and repair.is_empty() and agronomy.is_empty() and medical.is_empty() and doctrine.is_empty() and effects.is_empty() and profile.is_empty() and training.is_empty() and children.is_empty() and products.is_empty() and inspections.is_empty() and plants.is_empty() and prospecting.is_empty() and not military_unlock:errors.append(id+": no implemented consequence")
	return errors
