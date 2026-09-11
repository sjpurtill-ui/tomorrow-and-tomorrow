extends RefCounted
## Validate production additions before they enter the live catalog. Existing
## legacy records are retained without inventing retrospective authoring notes.
const Society=preload("res://scripts/society_model.gd")
const FOODS=["Fresh plants","Fresh meat","Fish","Dry staples","Preserved food"]
static func validate(additions:Array,catalog:Array)->Array[String]:
	var errors:Array[String]=[]
	var names:Dictionary={}
	var ids:Dictionary={}
	for entry:Dictionary in catalog:
		var name:=String(entry.get("name","")).strip_edges().to_lower()
		names[name]=int(names.get(name,0))+1
		var id:=String(entry.get("id",""))
		ids[id]=int(ids.get(id,0))+1
	for entry:Dictionary in additions:
		var id:=String(entry.get("id",""))
		if int(ids.get(id,0))!=1:errors.append(id+": production identity must occur exactly once")
		if int(names.get(String(entry.get("name","")).strip_edges().to_lower(),0))!=1:errors.append(id+": duplicate or missing display identity")
		for field:String in ["name","observation","production_contract"]:
			if not entry.get(field) is String or String(entry[field]).strip_edges().is_empty():errors.append(id+": missing "+field)
		if not entry.get("day") is int or int(entry.day)<0:errors.append(id+": invalid earliest day")
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
		if effects.is_empty() and profile.is_empty():errors.append(id+": no implemented consequence")
	return errors
