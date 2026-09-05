class_name ExpeditionFindings
extends RefCounted

# These are descriptions of real deposits created by the return resolver.
# No treasure, technology unlock or foreign civilization is invented by the UI.
const STORIES:Dictionary={
	"Flint":["The knife-stone country","They charted an exposed source of flint: stone that can hold a cutting edge.","A destination for future tool-making supplies. Extraction and transport still need to be organized."],
	"Salt":["White earth of the dry country","The party marked a salt occurrence on its return chart.","A potential supply for food preservation. A distant source needs a workable route before it can feed your stores."],
	"Medicinal Plants":["A living fieldbook","The scouts recorded a stand of medicinal plants and where it grows.","A source for future gathering and investigation; useful remedies still depend on your people's knowledge."],
	"Fertile Soil":["Land for another beginning","A tract of fertile ground is now marked beyond the familiar country.","A place to weigh for future settlement. Soil alone is not enough: water, distance and security matter too."],
	"Game":["The hunting grounds beyond home","The route crosses a newly recorded source of game.","A possible hunting destination or staging ground. Its animals have not been delivered to the settlement."],
	"Timber":["The far timber country","The party charted a timber stand along its route.","Useful to people living nearby or to a future outpost; hauling ordinary timber all the way home may not be worthwhile."],
	"Stone":["The stone country","The scouts marked exposed workable stone along the route.","A local building source for a future foothold, rather than a reason to haul rock across the world."],
	"Fiber Plants":["Cordage along the road","The party recorded plants suitable for cordage and weaving.","A practical resupply note for travelers. This is a minor field observation, not the prize of the expedition."],
	"Copper Ore":["The copper-bearing hills","The scouts marked an occurrence of copper ore in the high country.","A potential metalworking supply. Roads, tools, specialists and the right processing knowledge must come before production."],
	"Tin Ore":["The tin country","The party returned with the location of a tin-bearing deposit.","A new source for your developing metal economy. Finding the ore does not confer the knowledge or labor to work it."],
	"Iron Ore":["Iron beneath the uplands","An iron-bearing occurrence has been entered on the expedition's chart.","A long-term destination for mining and metalworking. Its remoteness still has to be overcome."],
	"Coal":["The black-stone country","The scouts located a coal occurrence on the route.","A potential fuel supply once mining, ventilation and transport can be supported."],
	"Phosphate Rock":["New ground for the growers","The party charted a phosphate-rock occurrence in the open country.","A prospective agricultural material source. Specialists, mining and logistics are still required."],
}

static func resource_for(ground:Dictionary,day:int,rng:RandomNumberGenerator,long_journey:bool)->String:
	var biome:=String(ground.get("biome",""))
	if biome=="water": return ""
	var pool:Array[String]=["Stone","Game"]
	match biome:
		"woodland": pool=["Timber","Game"]
		"grassland","wetland","floodplain": pool=["Fertile Soil","Game"]
		"steppe","tundra": pool=["Stone","Game"]
	if long_journey:
		# Recognition follows the resource system's existing knowledge chronology.
		var candidates:Array=["Medicinal Plants"] if biome in ["woodland","wetland","grassland","floodplain"] else ["Salt","Phosphate Rock"] if biome=="steppe" else ["Flint","Copper Ore","Tin Ore","Iron Ore","Coal"]
		var recognized:Array[String]=[]
		for special in candidates:
			if int(day/365)>=int(ResourceSystem.catalog.get(special,{}).get("recognition_year",999)): recognized.append(special)
		if not recognized.is_empty(): return recognized[rng.randi_range(0,recognized.size()-1)]
	return pool[rng.randi_range(0,pool.size()-1)]

static func deposit_card(deposit:Dictionary,distance:int)->Dictionary:
	var resource:=String(deposit.resource)
	var story:Array=STORIES.get(resource,STORIES["Stone"])
	return {"kind":"resource","title":String(story[0]),"description":String(story[1]),"consequence":String(story[2]),"resource":resource,"distance_km":distance,"position":{"x":deposit.position.x,"z":deposit.position.z},"deposit_id":String(deposit.id),"quality":float(deposit.quality),"minor":resource=="Fiber Plants"}
