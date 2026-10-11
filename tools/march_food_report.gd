extends RefCounted
## Diagnostic ("--capture-march-food"): for the road from home to each
## people's home, what the march's own reckoning says (military_campaign
## march_supply): the days, the days of food the army would carry, how it
## would be fed, and how large a host the carts could feed that far.

static func lines()->PackedStringArray:
	var out:PackedStringArray=[]
	var world:Node=CivilizationSystem
	var mc:Node=MilitaryCampaign
	var home:Vector2=world.player_world_origin
	var fleet:Dictionary=preload("res://scripts/carriers.gd").fleet(GameState,func(tech:String)->float: return float(mc._adoption(tech)))
	var men:=int((mc.home_army as Dictionary).get("troops",0))
	out.append("army at home %d; drivers %d, carts %d (load %d), porters %d; one trip carries %d rations" % [men,int(fleet.drivers),int(fleet.carts),roundi(float(fleet.cart_load)),int(fleet.porters),roundi(float(fleet.loads))])
	for size:int in [men,maxi(1,men/2),maxi(1,men/4),300]:
		var probe:Dictionary=(mc.home_army as Dictionary).duplicate(false)
		probe["troops"]=size;probe["position"]={"x":home.x,"z":home.y};probe["status"]="moving"
		out.append("a host of %d would carry food for %d days" % [size,int(mc.train_capacity_days(probe))])
	for civ:Dictionary in world.civilizations:
		var at:Vector2=world._civilization_world_position(civ)
		var probe:Dictionary=(mc.home_army as Dictionary).duplicate(false)
		probe["troops"]=men;probe["position"]={"x":home.x,"z":home.y};probe["status"]="moving"
		var route:Dictionary=mc.field_route(home,at,probe)
		if route.has("error"):out.append("%s: no road (%s)" % [String(civ.name),String(route.get("reason",""))]);continue
		var march:Dictionary=mc.march_supply(probe,route)
		var full:=float(march.days)/(1.0+float(march.half_pace))
		out.append("%s: %d km by road, %d days (%d at full pace), carries %d days, fed on road %d%%, fed there %d%%, carts could feed %d that far" % [String(civ.name),roundi(float(route.get("length_km",0.0))),int(march.days),roundi(full),int(float(march.train_days)),roundi(float(march.fed_on_road)*100.0),roundi(float(march.fed_there)*100.0),int(mc.train_feeds(full))])
	return out
