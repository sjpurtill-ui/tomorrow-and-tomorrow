extends RefCounted
## Capture/diagnostic ("--capture-rival-ships"): for each rival people, whether
## its ruler would send an expedition by sea (expedition.gd leaders_decide) and
## whether one sailed toward us would find us: its scouting staff, its boats,
## and a dry-run quote on the compass point nearest our bearing.

static func lines()->PackedStringArray:
	var Expedition:=preload("res://scripts/expedition.gd")
	var out:PackedStringArray=[]
	var home:Vector2=CivilizationSystem.player_world_origin
	for civ:Dictionary in CivilizationSystem.civilizations:
		var id:=String(civ.get("id",""))
		if not WorldSimulation.actors.has(id):out.append("%s: not simulated" % String(civ.get("name",id)));continue
		var at:Vector2=CivilizationSystem._civilization_world_position(civ)
		var line:String=WorldSimulation.scoped(id,func()->String:
			var world:Node=WorldSimulation.world
			var staff:Dictionary=world.scouting_staff.data
			var names:Array=world.SCOUT_HEADINGS.keys()
			var bearing:=rad_to_deg(fposmod((home-world.player_world_origin).angle(),TAU))
			var heading:=String(names[posmod(roundi(bearing/45.0),names.size())])
			var craft:Dictionary=Expedition.sea_ready()
			var text:="staff share %.2f fruitless %d/%d parties out %d; boats %s (dare %d); " % [float(staff.get("share",0.0)),int(staff.get("fruitless",0)),int(staff.get("land_fruitless",0)),world.scout_missions.size(),str(craft.ok),roundi(float(craft.get("offshore_km",0.0)))]
			if not bool(craft.ok):return text
			var best:=""
			for reach:float in [1200.0,2500.0]:
				var q:Dictionary=Expedition.quote(heading,reach,true,Expedition.LEADERS_PARTY,world)
				if not bool(q.ok):best+="%s %d: %s. " % [heading,int(reach),String(q.blocker)];continue
				var route:Array=q.route_plan.route
				var off:=float(world._closest_route_encounter(route,home).distance)
				best+="%s %d: %d in 100 home, passes %d km from us, signs followed %s. " % [heading,int(reach),roundi(float(q.chance)*100.0),roundi(off),str(Expedition.followed_signs(world,route,home,true).is_finite())]
				if off<450.0:
					var dry:=INF;var dry_at:=Vector2.INF
					for p:Dictionary in route:
						var v:=Vector2(float(p.x),float(p.z))
						if bool(world._scout_land_at(v)) and v.distance_to(home)<dry:dry=v.distance_to(home);dry_at=v
					var way:Dictionary=world._plan_scout_land_route(dry_at,home) if dry_at.is_finite() else {}
					var voyage:Dictionary=q.route_plan.voyage
					best+="[nearest dry turn %d km, home dry %s, land way ok=%s km=%s reason=%s; landing index %d of %d; closest point dry=%s] " % [roundi(dry),str(world._scout_land_at(home)),str(way.get("ok",false)),str(way.get("distance_km","-")),String(way.get("reason","")),int(voyage.landing_index),route.size(),str(world._scout_land_at(world._closest_route_encounter(route,home).position))]
			return text+best)
		# An army's road from their home to ours, and from ours to theirs (army_sea_road.gd).
		var theirs:String=WorldSimulation.scoped(id,func()->String:
			var road:Dictionary=WorldSimulation.military.field_route(WorldSimulation.world.player_world_origin,home)
			return _road_words(road))
		var ours:String=_road_words(MilitaryCampaign.field_route(home,at))
		out.append("%s (%d km): %s | ARMY theirs to us: %s | ours to them: %s | war in reach: ours %s" % [String(civ.get("name",id)),roundi(at.distance_to(home)),line,theirs,ours,str(preload("res://scripts/war_loop.gd").near_us(id))])
	return out

static func _road_words(road:Dictionary)->String:
	if road.has("error"):return "refused (%s)" % String(road.get("reason",""))
	if road.get("sea") is Dictionary:return "by sea %d km, %d open, %d in 100 drown" % [roundi(float(road.sea.sea_km)),roundi(float(road.sea.open_km)),roundi(float(road.sea.drown)*100.0)]
	return "by land %d km" % roundi(float(road.get("length_km",0.0)))
