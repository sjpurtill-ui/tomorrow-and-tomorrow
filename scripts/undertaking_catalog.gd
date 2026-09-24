extends RefCounted
## Legacy definitions and concept lookup. Wonders are conceived from a grammar
## (scripts/wonder_concept.gd); the twelve founding definitions below remain only
## so saves made before conceived wonders keep loading and working. `all()`
## lists those legacy works; `get_definition` also resolves any concept id.
const ERAS:Array[String]=["founding","classical","medieval","industrial","modern"]
const ERA_TITLES:={"founding":"Founding","classical":"Classical","medieval":"Medieval","industrial":"Industrial","modern":"Modern"}
## Base allure of a claimed, fully maintained work by era.
const ERA_ALLURE:={"founding":6.0,"classical":10.0,"medieval":14.0,"industrial":18.0,"modern":22.0}
## Purpose of each legacy work in the conceived-wonder grammar.
const LEGACY_PURPOSE:={"ancestor_ring":"honor_dead","great_hall":"bind_tribes","rain_court":"tame_flood","flood_terraces":"tame_flood","star_steps":"watch_heavens","kiln_court":"master_craft","long_song":"remember_knowledge","common_stores":"feed_people","safe_passage":"welcome_strangers","living_orchard":"give_thanks","stone_crown":"awe_rivals","measures_house":"master_craft"}
static func all()->Array:
	return [
		# FOUNDING -------------------------------------------------------------
		_d("ancestor_ring","Ancestors' Ring","ring","", "any",80,4000,{"Stone":240,"Timber":40},"Administration",.03,"founding",[],"",
			"Standing stones where every lineage keeps a place, even the forgotten.","Anchors lineage and law; can grow into the Temple of the Ring.",{"id":"ring_oath","label":"Swear the Ring Oath","text":"Call the lineages to renew their oaths at the stones; disputes are heard before the ancestors."},"",2),
		_d("great_hall","Hall of Many Hearths","hall","framed_construction","woodland",140,9000,{"Timber":600,"Fiber Plants":180},"Administration",.06,"founding",[],"",
			"One roof long enough that no family eats alone in winter.","Draws households and warms foreign reception.",{"id":"hearth_welcome","label":"Open the Hearths","text":"Every traveler who reaches the hall is fed for three nights without question."},"",1),
		_d("rain_court","Court of Collected Rain","basin","clay_shaping","dry",100,6000,{"Clay":400,"Stone":150},"Logistics",.05,"founding",[],"",
			"A courtyard that drinks the storm and gives it back in the dry months.","Large local water storage.",{"id":"rain_share","label":"Declare the Rain Share","text":"In drought, the court's water is measured out equally by household, not by rank."},"",0),
		_d("flood_terraces","Gardens Above the Flood","terrace","seed_selection","wet",150,12000,{"Stone":450,"Timber":200},"Food",.06,"founding",[],"",
			"Stepped fields that let the river rise and still leave the harvest dry.","Food storage and less spoilage.",{"id":"flood_watch","label":"Keep the Flood Watch","text":"Terrace keepers ring the alarm at high water; lower fields are cleared before the river comes."},"",0),
		_d("star_steps","Steps of the Watching Sky","terrace","","any",120,8000,{"Stone":500},"Knowledge",.05,"founding",[],"watching_sky",
			"Stairs aligned so the first light of each season strikes a different step.","Forecasts lean seasons and famine up to 120 days ahead.",{"id":"sky_reading","label":"Read the Sky Aloud","text":"Sky-watchers announce the coming season from the steps; stores are planned by their reading."},"",1),
		_d("kiln_court","Court of a Hundred Fires","kilns","clay_shaping","any",180,11000,{"Clay":650,"Stone":200,"Timber":300},"Crafting",.06,"founding",[],"",
			"A ring of kilns whose glow can be seen from three valleys.","Stronger crafting.",{"id":"fire_festival","label":"Light the Hundred Fires","text":"Once a year every kiln is fired together and apprentices show their first work."},"",1),
		_d("long_song","House of the Long Song","hall","","any",100,5000,{"Timber":240,"Fiber Plants":180},"Knowledge",.03,"founding",[],"long_song",
			"A hall where the whole history is sung, one verse per generation.","Leaders' memories and knowledge survive succession and loss.",{"id":"new_verse","label":"Add a Verse","text":"The singers are asked to add this year's events to the Long Song, so it is never forgotten."},"",2),
		_d("common_stores","Granary of the Covenant","granary","public_stores","any",180,10000,{"Timber":450,"Clay":300},"Logistics",.06,"founding",[],"covenant",
			"Sealed bins filled in good years under a promise no one may break.","Seals a famine reserve from real surplus and releases it in shortage.",{"id":"open_covenant","label":"Invoke the Covenant","text":"In famine, the sealed bins are opened to every household in equal measure."},"",0),
		_d("safe_passage","Sanctuary of Safe Passage","ring","","any",140,7000,{"Stone":200,"Timber":220,"Fiber Plants":100},"Administration",.04,"founding",[],"traffic",
			"A ring with open gates where no blade may be drawn.","More envoys, traders and refugees route toward you.",{"id":"sanctuary_law","label":"Proclaim Sanctuary","text":"Any stranger who reaches the ring is under protection until their business is done."},"",1),
		_d("living_orchard","Orchard of Generations","orchard","seed_selection","wet",100,14000,{"Timber":160,"Fiber Plants":200},"Food",.05,"founding",[],"",
			"Each child plants a tree; the oldest trees bear the names of founders.","Food storage and less spoilage.",{"id":"first_fruit","label":"Share the First Fruit","text":"The orchard's first harvest is given to the youngest and the oldest before anyone else eats."},"",0),
		_d("stone_crown","Crown of the Ridge","mound","","any",220,18000,{"Stone":1200,"Clay":400},"Administration",.04,"founding",[],"deterrence",
			"A terraced crown on the ridge, visible to anyone who would march on you.","Rivals weigh war against you more gravely.",{"id":"crown_watch","label":"Light the Crown","text":"Beacons burn on the Crown so every neighbor knows the ridge is watched."},"",1),
		_d("measures_house","House of Common Measures","hall","public_stores","any",160,8500,{"Timber":320,"Stone":160,"Clay":120},"Crafting",.05,"founding",[],"",
			"The true cubit and the true basket, kept where anyone may check them.","Stronger crafting and trusted trade.",{"id":"true_measure","label":"Test the Measures","text":"Traders may bring any weight or basket to be checked against the house standard, free of charge."},"",0)]

static func _d(id:String,title:String,form:String,discovery:String,environment:String,population:int,work:float,cost:Dictionary,role:String,bonus:float,era:String="founding",also:Array=[],effect:String="",lore:String="",effect_text:String="",decree:Dictionary={},upgrade_from:String="",shrine:int=0)->Dictionary:
	var requires:Array=[]
	if not discovery.is_empty():requires.append(discovery)
	requires.append_array(also)
	return {"id":id,"title":title,"form":form,"discovery":discovery,"requires":requires,"environment":environment,"population":population,"work":work,"cost":cost,"role":role,"bonus":bonus,"era":era,"effect":effect,"lore":lore,"effect_text":effect_text,"decree":decree,"upgrade_from":upgrade_from,"shrine_slots":shrine,"allure":float(ERA_ALLURE.get(era,6.0)),"purpose":String(LEGACY_PURPOSE.get(id,"")),"ambition":"grand","shape":form}

# Definitions are constant; index them once. Returned entries are read-only.
static var _by_id:Dictionary={}
static func get_definition(id:String)->Dictionary:
	if _by_id.is_empty():
		for d:Dictionary in all():
			(d.cost as Dictionary).make_read_only();(d.requires as Array).make_read_only();(d.decree as Dictionary).make_read_only();d.make_read_only()
			if not _by_id.has(d.id):_by_id[d.id]=d
	if _by_id.has(id):return _by_id[id]
	if not id.begins_with("wonder:"):return {}
	var d:Dictionary=load("res://scripts/wonder_concept.gd").definition(id)
	if d.is_empty():return {}
	if _by_id.size()>4096:_by_id.clear()
	(d.cost as Dictionary).make_read_only();(d.requires as Array).make_read_only();(d.decree as Dictionary).make_read_only();d.make_read_only()
	_by_id[id]=d
	return d

## Works that rebuild `id` in place.
static func upgrades_of(id:String)->Array:
	var result:Array=[]
	for d:Dictionary in all():
		if String(d.upgrade_from)==id:result.append(d.id)
	return result
