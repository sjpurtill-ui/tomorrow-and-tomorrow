extends RefCounted
## Great Works: each exists at most once in the world. Costs are local stock units.
## Availability depends on discoveries, population and environment, never on a
## calendar cap or a per-city dice roll. `upgrade_from` works rebuild an existing
## functioning site in place and keep its name, history and enshrined objects.
const ERAS:Array[String]=["founding","classical","medieval","industrial","modern"]
const ERA_TITLES:={"founding":"Founding","classical":"Classical","medieval":"Medieval","industrial":"Industrial","modern":"Modern"}
## Base allure of a claimed, fully maintained work by era.
const ERA_ALLURE:={"founding":6.0,"classical":10.0,"medieval":14.0,"industrial":18.0,"modern":22.0}
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
			"The true cubit and the true basket, kept where anyone may check them.","Stronger crafting and trusted trade.",{"id":"true_measure","label":"Test the Measures","text":"Traders may bring any weight or basket to be checked against the house standard, free of charge."},"",0),
		# CLASSICAL ------------------------------------------------------------
		_d("ring_temple","Temple of the Ring","ring","masonry_bond_patterns","any",1200,16000,{"Stone":900,"Timber":200,"Clay":200},"Administration",.05,"classical",[],"",
			"The ancestors' stones are roofed over, and the ring becomes a sanctuary.","Greater reputation and allure; rebuilt in place from the Ancestors' Ring.",{"id":"temple_rites","label":"Hold the Temple Rites","text":"Priests of the Ring keep a calendar of rites that binds every settlement to the old stones."},"ancestor_ring",4),
		_d("long_water","The Long Water","basin","gravity_conduit_grade_control","any",1500,20000,{"Stone":1400,"Clay":900},"Logistics",.06,"classical",["clay_pipe_forming"],"",
			"A channel falling one finger in a hundred paces, carrying hill springs to the city.","Very large water storage.",{"id":"water_right","label":"Grant the Water Right","text":"Every household is granted a share of the Long Water by law, recorded at the outflow."},"",0),
		_d("hall_of_voices","Hall of Voices","hall","public_libraries","any",1400,15000,{"Stone":700,"Timber":500,"Fiber Plants":300},"Knowledge",.06,"classical",[],"",
			"Shelves to the roof, and a rule that any reader may ask any question.","Stronger research; a great house for enshrined objects.",{"id":"open_reading","label":"Open the Reading Rooms","text":"The Hall's readers must answer any visitor's question, citizen or stranger."},"",4),
		_d("returning_arch","Arch of the Returning","mound","voussoir_arch_assembly","any",1300,14000,{"Stone":1100},"Administration",.04,"classical",[],"deterrence",
			"Every army that comes home marches beneath it and reads the names of those who did not.","Reputation, and a measured deterrent to rivals.",{"id":"names_read","label":"Read the Names","text":"On the day of return, the names of the fallen are read aloud beneath the arch."},"",1),
		_d("harbor_lamp","Lamp at the Harbor Mouth","mound","galley_navigation","any",1100,13000,{"Stone":900,"Timber":300,"Coal":80},"Logistics",.05,"classical",[],"traffic",
			"A fire kept burning so that no ship need wait for dawn.","More traders and envoys find their way to you.",{"id":"lamp_toll","label":"Waive the Lamp Toll","text":"Ships guided by the lamp pay no harbor toll in their first season."},"",0),
		_d("chronicle_house","Archive of the Long Song","hall","comparative_chronicles","any",1500,15000,{"Stone":600,"Timber":400,"Fiber Plants":400},"Knowledge",.05,"classical",[],"long_song",
			"The Long Song is written down, verse beside verse, in many hands.","Stronger memory keeping; rebuilt in place from the House of the Long Song.",{"id":"copy_song","label":"Copy the Song","text":"Every verse is copied twice and sent to a distant settlement for safekeeping."},"long_song",3),
		_d("thousand_steps","Theatre of the Thousand Steps","terrace","festival_calendar","any",1800,17000,{"Stone":1300,"Timber":200},"Administration",.04,"classical",["masonry_bond_patterns"],"",
			"A hillside cut into seats, where a whisper on the stage reaches the top row.","Draws households; allure.",{"id":"festival_plays","label":"Stage the Festival Plays","text":"The year's troubles are played out on the steps, and the audience votes on the ending."},"",1),
		_d("known_world","Table of the Known World","hall","regional_maps","any",1200,12000,{"Timber":500,"Stone":400,"Fiber Plants":200},"Knowledge",.04,"classical",[],"",
			"A floor-map of every route and river ever reported, corrected by each traveler.","Research and foreign reputation.",{"id":"chart_request","label":"Ask Travelers to Correct the Table","text":"Any traveler who corrects the Table is rewarded and recorded by name."},"",1),
		# MEDIEVAL -------------------------------------------------------------
		_d("ring_cathedral","Cathedral of the Ring","ring","masonry_buttressing","any",6000,30000,{"Stone":2600,"Timber":700,"Clay":400},"Administration",.06,"medieval",["vaulted_masonry_roofs"],"",
			"Vaults rise over the old ring; the first stones still stand at its heart.","The highest reputation and allure; rebuilt in place from the Temple of the Ring.",{"id":"ring_pilgrimage","label":"Call the Ring Pilgrimage","text":"Pilgrims from every land may walk the ring once in their lives, under protection."},"ring_temple",6),
		_d("assembly_dome","Dome of the Assembly","mound","domed_masonry_roofs","any",5000,26000,{"Stone":2200,"Clay":600,"Timber":300},"Administration",.05,"medieval",[],"deterrence",
			"A dome wide enough for every settlement's delegates to sit in one circle.","Reputation, and rivals hesitate to break a united people.",{"id":"full_assembly","label":"Summon the Full Assembly","text":"Delegates of every settlement meet under the Dome to hear and answer the sovereign."},"",2),
		_d("colored_light","House of Colored Light","hall","glass_blowing","any",4000,20000,{"Stone":900,"Timber":400,"Clay":600,"Coal":200},"Crafting",.06,"medieval",[],"",
			"Windows of blown glass that paint the floor with every season's colors.","Stronger crafting; a luminous house for enshrined objects.",{"id":"glass_guild","label":"Charter the Glass Guild","text":"Glassmakers are chartered to train apprentices from every settlement."},"",3),
		_d("hundred_hands","Scriptorium of the Hundred Hands","hall","manuscript","any",4500,18000,{"Stone":600,"Timber":600,"Fiber Plants":500},"Knowledge",.06,"medieval",[],"",
			"A hundred desks, and a rule that nothing leaves until it has been copied.","Stronger research.",{"id":"copy_everything","label":"Copy Every Book","text":"Every book entering the realm must be copied once before it may leave."},"",2),
		_d("covenant_vaults","Vaults of the Covenant","granary","vaulted_masonry_roofs","any",5000,24000,{"Stone":1800,"Timber":400,"Clay":600},"Logistics",.06,"medieval",[],"covenant",
			"The Covenant's bins become stone vaults cool enough to keep grain for a generation.","A far larger famine reserve; rebuilt in place from the Granary of the Covenant.",{"id":"vault_audit","label":"Audit the Vaults","text":"The vaults are opened and counted in public each year so no one doubts the Covenant."},"common_stores",0),
		_d("watching_tower","Tower of the Watching Sky","terrace","lens_centering","any",4000,22000,{"Stone":1500,"Timber":300,"Copper Ore":120},"Knowledge",.06,"medieval",["eyepiece_design"],"watching_sky",
			"Lenses crown the old steps, and the watchers see storms a season away.","Forecasts lean seasons and famine up to a year ahead; rebuilt in place from the Steps.",{"id":"almanac","label":"Publish the Almanac","text":"The watchers' year-ahead reading is published to every settlement each spring."},"star_steps",1),
		# INDUSTRIAL -----------------------------------------------------------
		_d("moving_letters","House of the Moving Letters","hall","screw_press_printing","any",20000,30000,{"Stone":1200,"Timber":800,"Iron Ore":400,"Fiber Plants":800},"Knowledge",.06,"industrial",[],"",
			"Presses that never sleep, and a reading room open all night.","Research and household attraction.",{"id":"free_press","label":"Free the Presses","text":"Any citizen may print a sheet at the House once a year without license."},"",2),
		_d("joining_water","The Joining Water","basin","hydraulic_lime_binders","any",25000,38000,{"Stone":3000,"Clay":1500,"Timber":600},"Logistics",.06,"industrial",["gravity_conduit_grade_control"],"traffic",
			"A canal that makes two river valleys one market.","Water storage, and more trade routed through you.",{"id":"open_locks","label":"Open the Locks","text":"The locks are opened to any peaceful vessel at the posted toll."},"",0),
		_d("thousand_rivets","Bridge of a Thousand Rivets","mound","steel_refining","any",30000,36000,{"Iron Ore":2400,"Coal":1600,"Stone":800},"Logistics",.05,"industrial",[],"",
			"Iron spans where the ferry used to drown a boat a year.","Strong foreign reputation.",{"id":"bridge_day","label":"Hold Bridge Day","text":"On Bridge Day anyone may cross toll-free and the riveters are honored by name."},"",0),
		_d("tireless_engines","Hall of Tireless Engines","kilns","heat_engine_cycles","any",30000,34000,{"Iron Ore":2000,"Coal":2500,"Stone":900},"Crafting",.07,"industrial",[],"",
			"Engines that breathe steam day and night under one great roof.","Much stronger crafting.",{"id":"engine_schools","label":"Found the Engine Schools","text":"Every engine hall must train apprentices from outside the owners' families."},"",1),
		_d("grand_terminus","Grand Terminus","hall","rail_track_foundations","any",40000,36000,{"Stone":2000,"Iron Ore":1600,"Timber":1000},"Logistics",.05,"industrial",[],"traffic",
			"A vaulted station where every line in the land begins and ends.","Households and envoys arrive more readily.",{"id":"open_timetable","label":"Publish the Timetable","text":"A single timetable is posted in every settlement, so any journey can be planned from anywhere."},"",1),
		_d("far_voices","Tower of Far Voices","mound","electrical_telegraphy","any",40000,30000,{"Iron Ore":1400,"Copper Ore":1200,"Stone":600},"Administration",.05,"industrial",[],"",
			"A mast that carries the capital's voice to the frontier in a heartbeat.","Strong foreign reputation.",{"id":"public_wire","label":"Open the Public Wire","text":"Any citizen may send one message a month over the wire without charge."},"",0),
		# MODERN ---------------------------------------------------------------
		_d("bright_river","Dam of the Bright River","basin","electrical_generators","any",150000,50000,{"Stone":6000,"Iron Ore":3000,"Clay":2000},"Crafting",.07,"modern",["concrete_mix_design"],"",
			"A wall of poured stone that turns a river into light.","Huge water storage and stronger crafting.",{"id":"light_share","label":"Share the Light","text":"The dam's first power is wired to schools and clinics before any factory."},"",0),
		_d("sky_harbor","Harbor of the Sky","terrace","powered_flight","any",200000,48000,{"Stone":5000,"Iron Ore":2500,"Copper Ore":800},"Logistics",.05,"modern",[],"traffic",
			"Long fields where the whole world lands.","Draws households; envoys and traders arrive from afar.",{"id":"open_skies","label":"Declare Open Skies","text":"Any peaceful craft may land at the Harbor of the Sky."},"",1),
		_d("reckoning_engine","Engine of Reckoning","hall","stored_program_control","any",200000,46000,{"Copper Ore":2400,"Iron Ore":1800,"Stone":1200},"Knowledge",.08,"modern",[],"",
			"Rooms of humming registers that can calculate a harvest before it is sown.","Much stronger research.",{"id":"public_reckoning","label":"Offer Public Reckoning","text":"Any settlement may submit a problem to the Engine and receive its answer."},"",1),
		_d("captured_sun","Fields of the Captured Sun","orchard","photovoltaic_power","any",250000,44000,{"Copper Ore":3000,"Iron Ore":1500,"Stone":1500},"Crafting",.07,"modern",[],"",
			"Glittering fields that drink light and never burn a tree.","Much stronger crafting.",{"id":"sun_share","label":"Share the Sun","text":"Every household receives a share of the fields' power as a birthright."},"",0)]

static func _d(id:String,title:String,form:String,discovery:String,environment:String,population:int,work:float,cost:Dictionary,role:String,bonus:float,era:String="founding",also:Array=[],effect:String="",lore:String="",effect_text:String="",decree:Dictionary={},upgrade_from:String="",shrine:int=0)->Dictionary:
	var requires:Array=[]
	if not discovery.is_empty():requires.append(discovery)
	requires.append_array(also)
	return {"id":id,"title":title,"form":form,"discovery":discovery,"requires":requires,"environment":environment,"population":population,"work":work,"cost":cost,"role":role,"bonus":bonus,"era":era,"effect":effect,"lore":lore,"effect_text":effect_text,"decree":decree,"upgrade_from":upgrade_from,"shrine_slots":shrine,"allure":float(ERA_ALLURE.get(era,6.0))}

# Definitions are constant; index them once. Returned entries are read-only.
static var _by_id:Dictionary={}
static func get_definition(id:String)->Dictionary:
	if _by_id.is_empty():
		for d:Dictionary in all():
			(d.cost as Dictionary).make_read_only();(d.requires as Array).make_read_only();(d.decree as Dictionary).make_read_only();d.make_read_only()
			if not _by_id.has(d.id):_by_id[d.id]=d
	return _by_id.get(id,{})

## Works that rebuild `id` in place.
static func upgrades_of(id:String)->Array:
	var result:Array=[]
	for d:Dictionary in all():
		if String(d.upgrade_from)==id:result.append(d.id)
	return result
