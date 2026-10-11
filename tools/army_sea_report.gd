extends RefCounted
## Diagnostic ("--capture-army-sea"): on the real terrain, how an army of ours
## would go to each people's home and theirs to ours (by land, by sea with the
## crossing's cost, or refused), and what the sea road does for real places
## across water near home (land no road reaches).

static func lines()->PackedStringArray:
	var out:PackedStringArray=[]
	var world:Node=CivilizationSystem
	var home:Vector2=world.player_world_origin
	var Sea:=preload("res://scripts/army_sea_road.gd")
	var craft:Dictionary=preload("res://scripts/sea_voyage.gd").capability()
	out.append("our boats: %s, dare %d km, sail %d km a day; sea endurance %d km; war reach %d km (on foot %d)" % [String(craft.get("label","none")),roundi(float(craft.get("offshore_km",0.0))),roundi(float(craft.get("sail_km_per_day",0.0))),roundi(float(preload("res://scripts/expedition.gd").endurance_km(true))),roundi(float(preload("res://scripts/war_loop.gd").war_margin_km())),roundi(float(preload("res://scripts/war_loop.gd").NEIGHBOUR_MARGIN_KM))])
	for civ:Dictionary in world.civilizations:
		var id:=String(civ.get("id",""))
		var at:Vector2=world._civilization_world_position(civ)
		var ours:String=_words(MilitaryCampaign.field_route(home,at))
		var theirs:="not simulated"
		if WorldSimulation.actors.has(id):
			theirs=WorldSimulation.scoped(id,func()->String:return _words(WorldSimulation.military.field_route(WorldSimulation.world.player_world_origin,home)))
		out.append("%s %d km: ours to them %s | theirs to us %s | war in reach %s (on foot %s)" % [String(civ.get("name",id)),roundi(at.distance_to(home)),ours,theirs,str(preload("res://scripts/war_loop.gd").near_us(id)),str(preload("res://scripts/war_loop.gd").near_us(id,true))])
	# Real places over water: dry ground near home that no land road reaches.
	var land:=Callable(world,"_scout_land_at")
	var found:=0
	for ring:float in [60.0,120.0,200.0,300.0,450.0,650.0]:
		for k in 16:
			if found>=6:break
			var p:=home+Vector2.from_angle(TAU*float(k)/16.0)*ring
			if not bool(land.call(p)):continue
			var by_land:Dictionary=preload("res://scripts/army_land_route.gd").find(home,p,land,false,{})
			if not by_land.has("error") or String(by_land.get("reason",""))!="no_land_route":continue
			found+=1
			var road:Dictionary=MilitaryCampaign.field_route(home,p)
			var detail:=""
			if road.get("sea") is Dictionary:
				var pts:Array=road.points
				var wet:=0
				for q:Vector2 in pts:
					if not bool(land.call(q)):wet+=1
				detail=" | %d points, last on land %s, ends %d km from the place, total %d km, effort %d" % [pts.size(),str(bool(land.call(pts[-1]))),roundi((pts[-1] as Vector2).distance_to(p)),roundi(float(road.length_km)),roundi(float(road.effort_km))]
			out.append("across water %d km %s of home: %s%s" % [roundi(ring),String(world._compass_phrase(home,p)),_words(road),detail])
	if found==0:out.append("no dry ground within 650 km of home that the land road cannot reach")
	return out

static func _words(road:Dictionary)->String:
	if road.has("error"):return "refused (%s)" % String(road.get("reason",""))
	if road.get("sea") is Dictionary:return "by sea %d km, %d out of sight of land, %d in 100 drown" % [roundi(float(road.sea.sea_km)),roundi(float(road.sea.open_km)),roundi(float(road.sea.drown)*100.0)]
	return "by land %d km" % roundi(float(road.get("length_km",0.0)))
