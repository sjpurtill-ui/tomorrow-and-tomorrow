extends RefCounted
## Candidates are possibilities, not guaranteed awards. Costs are local stock units.
static func all()->Array:
	return [
		_d("ancestor_ring","Ancestors' Ring","ring","", "any",80,4000,{"Stone":240,"Timber":40},"Administration",.03),
		_d("great_hall","Hall of Many Hearths","hall","framed_construction","woodland",140,9000,{"Timber":600,"Fiber Plants":180},"Administration",.06),
		_d("rain_court","Court of Collected Rain","basin","clay_shaping","dry",100,6000,{"Clay":400,"Stone":150},"Logistics",.05),
		_d("flood_terraces","Gardens Above the Flood","terrace","seed_selection","wet",150,12000,{"Stone":450,"Timber":200},"Food",.06),
		_d("star_steps","Steps of the Watching Sky","terrace","","any",120,8000,{"Stone":500},"Knowledge",.05),
		_d("kiln_court","Court of a Hundred Fires","kilns","clay_shaping","any",180,11000,{"Clay":650,"Stone":200,"Timber":300},"Crafting",.06),
		_d("long_song","House of the Long Song","hall","","any",100,5000,{"Timber":240,"Fiber Plants":180},"Knowledge",.03),
		_d("common_stores","Granary of the Covenant","granary","public_stores","any",180,10000,{"Timber":450,"Clay":300},"Logistics",.06),
		_d("safe_passage","Sanctuary of Safe Passage","ring","","any",140,7000,{"Stone":200,"Timber":220,"Fiber Plants":100},"Administration",.04),
		_d("living_orchard","Orchard of Generations","orchard","seed_selection","wet",100,14000,{"Timber":160,"Fiber Plants":200},"Food",.05),
		_d("stone_crown","Crown of the Ridge","mound","","any",220,18000,{"Stone":1200,"Clay":400},"Administration",.04),
		_d("measures_house","House of Common Measures","hall","public_stores","any",160,8500,{"Timber":320,"Stone":160,"Clay":120},"Crafting",.05)]
static func _d(id:String,title:String,form:String,discovery:String,environment:String,population:int,work:float,cost:Dictionary,role:String,bonus:float)->Dictionary:
	return {"id":id,"title":title,"form":form,"discovery":discovery,"environment":environment,"population":population,"work":work,"cost":cost,"role":role,"bonus":bonus}
# Definitions are constant; index them once. Returned entries are read-only.
static var _by_id:Dictionary={}
static func get_definition(id:String)->Dictionary:
	if _by_id.is_empty():
		for d:Dictionary in all():
			(d.cost as Dictionary).make_read_only();d.make_read_only()
			if not _by_id.has(d.id):_by_id[d.id]=d
	return _by_id.get(id,{})
