extends RefCounted
## Place-driven artifact distribution: scattered finds concentrate where people
## once lived (water, coasts, rock shelters, good land); seeded ancient sites
## hold small coherent sets left by one "lost people"; a handful of named
## legendary pieces are placed, never rolled. Everything is deterministic from
## the world seed and claimed exclusively at pickup across every owner.
## Rumors about sites are per-owner accounts: vague direction, distance and
## landmark, never coordinates.
const A=preload("res://scripts/artifact_collection.gd")
const PREHISTORY=preload("res://scripts/prehistoric_artifacts.gd")
const CELL:=24.0
const REGION:=8 # cells per ancient-site region side (192 km)
const SITE_CHANCE:=300 # per 1000 regions
const LEGEND_COUNT:=8
const DIG_RADIUS:=38.0 # km; a party within this of a remembered site can dig there
const RUMOR_LIMIT:=48
const KINDS:=["ruin","hoard","burial ground","shrine","rock shelter","old campsite"]
const ADJECTIVES:=["Hollow","Sunken","Windward","Quiet","Broken","Ashen","Reed-choked","Lichened","High","Drowned","Red","Long","Leaning","Salt-white","Forgotten","Low"]
const PEOPLES:=["the Heron Folk","the Ochre Hands","the Salt Walkers","the Reed Weavers","the Moon Counters","the Ember Keepers","the Stone Singers","the River Mothers","the Antler Clan","the Shell Traders","the Dawn Watchers","the Cave Painters","the Seed Carriers","the Ash People","the Long Walkers","the Knot Tellers","the Hearth Sisters","the Horn Callers","the Flint Menders","the Rain Dancers","the Owl Watchers","the Marsh Folk","the Cliff Dwellers","the Star Readers"]
const LEGENDS:=[
	{"name":"The Two Hands of Ochre Hollow","catalogue":175,"kind":"rock shelter","people":"the Ochre Hands","story":"A small red hand rests beside a larger one, pressed to the stone in the same breath. Whoever made them wanted the wall to remember that a child had been there, and had been held."},
	{"name":"The First Flute of the Heron Folk","catalogue":174,"kind":"shrine","people":"the Heron Folk","story":"Blown once in the marsh at dusk, it is said to have made the herons answer. The bone is worn smooth where many mouths have tried it since."},
	{"name":"The Hidden Aurochs","catalogue":191,"kind":"rock shelter","people":"the Cave Painters","story":"The painter let a crack in the limestone become the animal's spine, so that by firelight it seems to step out of the rock. Only those who knew where to hold the torch ever saw it whole."},
	{"name":"The Thumb-Bird of the River Mothers","catalogue":168,"kind":"burial ground","people":"the River Mothers","story":"Pinched from one lump of clay by a single thumb, it was laid in a grave with its beak toward the water. Mourners pressed new clay birds beside it for generations."},
	{"name":"The Moon-Counter","catalogue":183,"kind":"shrine","people":"the Moon Counters","story":"Charcoal crescents march across the stone in patient rows, each one a night someone stayed awake to watch. Near the end the marks grow careful, as if a teacher had taken over the counting."},
	{"name":"The Singing Slate","catalogue":180,"kind":"ruin","people":"the Stone Singers","story":"Struck at one end it rings low; struck at the other it answers high. Two villages once argued over who might keep it, and settled the quarrel by sharing a song."},
	{"name":"The Shell of Three Dawns","catalogue":171,"kind":"hoard","people":"the Shell Traders","story":"Red, yellow and white earths lie in three careful pools inside the shell, never mixed. It was carried far from any sea, and the colors were kept for faces on the mornings that mattered."},
	{"name":"The Dark Mirror","catalogue":239,"kind":"shrine","people":"the Owl Watchers","story":"Wet, the black stone shows a face that is not quite your own. Its keepers poured water over it before any hard decision and trusted what they saw."},
	{"name":"The Blind Guide's Map","catalogue":249,"kind":"old campsite","people":"the Long Walkers","story":"Pebbles set in hardened sand trace a path meant for fingertips rather than eyes. Someone who could not see once led a whole band home by it."},
	{"name":"The Running Hand","catalogue":220,"kind":"rock shelter","people":"the Ochre Hands","story":"A red palm dragged sideways across the stone becomes a figure in flight. No one agrees whether it is fleeing or dancing, and perhaps its maker never decided."},
	{"name":"The Lamp That Outlived Its Keepers","catalogue":161,"kind":"ruin","people":"the Ember Keepers","story":"Fat once burned in this hollow stone through winter nights no one now remembers. The soot inside is layered like tree rings, each layer a season of light."},
	{"name":"The Answering Reed","catalogue":162,"kind":"hoard","people":"the Reed Weavers","story":"Breathe into it softly and it sighs; breathe hard and it cries out. Children of the reed country were said to learn their first word from it."},
]
static var _sites:Dictionary={}
static var _legends:Dictionary={}

# --- Places -----------------------------------------------------------------

## "The Moon-Counter" reads as "the Moon-Counter" inside a sentence.
static func inline(title:String)->String:return "the "+title.trim_prefix("The ") if title.begins_with("The ") else title
## Well-mixed non-negative 31-bit value; String.hash() alone is nearly
## sequential for neighbouring cell keys.
static func noise(text:String)->int:
	# murmur3 fmix32 over the string hash (products wrap; only low 32 bits kept).
	var x:=hash(text)&0xffffffff
	x^=x>>16
	x=(x*0x85ebca6b)&0xffffffff
	x^=x>>13
	x=(x*0xc2b2ae35)&0xffffffff
	x^=x>>16
	return x&0x7fffffff
static func current_seed()->int:return int(WorldSimulation.state.world_seed)
static func cell_of(position:Vector2)->Vector2i:return Vector2i(floori(position.x/CELL),floori(position.y/CELL))
static func cell_center(cell:Vector2i)->Vector2:return Vector2(cell)*CELL+Vector2(CELL,CELL)*.5

## Ancient site for one 8x8-cell region, or {} when the region holds none.
static func region_site(world_seed:int,rx:int,rz:int)->Dictionary:
	var key:="%d:%d:%d" % [world_seed,rx,rz]
	if _sites.has(key):return _sites[key]
	var h:=noise(("%d:ancient:%d:%d" % [world_seed,rx,rz]))
	var site:={}
	if h%1000<SITE_CHANCE:
		var cell:=Vector2i(rx*REGION+(h/1000)%REGION,rz*REGION+(h/8000)%REGION)
		var people_index:=(h/64000)%PEOPLES.size()
		var kind:String=KINDS[(h/7)%KINDS.size()]
		var people:String=PEOPLES[people_index]
		site={"id":"site:%d:%d" % [rx,rz],"kind":kind,"people":people,"people_index":people_index,
			"name":"The %s %s of %s" % [ADJECTIVES[(h/13)%ADJECTIVES.size()],kind.capitalize(),people],
			"set_name":"Relics of %s" % people,"set_size":3+(h/3)%4,"cell":cell,"position":cell_center(cell),"legendary":false,"hash":h}
	if _sites.size()>20000:_sites.clear()
	_sites[key]=site
	return site

## The world's placed legendary sites (each a small set ending in its named piece).
static func legends(world_seed:int=-1)->Array:
	if world_seed==-1:world_seed=current_seed()
	if _legends.has(world_seed):return _legends[world_seed]
	var authority:Callable=WorldSimulation.world.ground_survey_authority if WorldSimulation.world!=null else Callable()
	var chosen:Array=range(LEGENDS.size())
	chosen.sort_custom(func(a:int,b:int)->bool:return noise("%d:legend-order:%d" % [world_seed,a])<noise("%d:legend-order:%d" % [world_seed,b]))
	var result:Array=[]
	for k:int in LEGEND_COUNT:
		var entry:Dictionary=LEGENDS[chosen[k]]
		var position:=Vector2.ZERO
		for attempt:int in 16:
			var h:=noise(("%d:legend:%d:%d" % [world_seed,k,attempt]))
			var angle:=float(h%3600)/3600.0*TAU
			var distance:=160.0+float((h/3600)%2400)
			position=Vector2(cos(angle),sin(angle))*distance
			if not authority.is_valid() or String(authority.call(position).get("biome",""))!="water":break
		var cell:=cell_of(position)
		result.append({"id":"legend:%d" % k,"kind":entry.kind,"people":entry.people,"name":"Resting place of %s" % inline(String(entry.name)),
			"legend_name":entry.name,"story":entry.story,"catalogue":int(entry.catalogue),"set_name":"Relics of %s" % entry.people,
			"set_size":3,"cell":cell,"position":cell_center(cell),"legendary":true,"hash":noise(("%d:legend:%d" % [world_seed,k]))})
	# Only cache placements checked against real terrain so they never shift later.
	if authority.is_valid():_legends[world_seed]=result
	return result

static func site_by_id(id:String,world_seed:int=-1)->Dictionary:
	if world_seed==-1:world_seed=current_seed()
	var parts:=id.split(":")
	if parts.size()==3 and parts[0]=="site":return region_site(world_seed,int(parts[1]),int(parts[2]))
	if parts.size()==2 and parts[0]=="legend":
		var all:=legends(world_seed);var k:=int(parts[1])
		if k>=0 and k<all.size():return all[k]
	return {}

## Ancient and legendary sites whose cell lies within `reach` cells of `cell`.
static func sites_near_cell(cell:Vector2i,reach:int=1)->Array:
	var world_seed:=current_seed()
	var found:Array=[]
	var regions:Dictionary={}
	for dx:int in range(-reach,reach+1):
		for dz:int in range(-reach,reach+1):
			regions[Vector2i(floori(float(cell.x+dx)/REGION),floori(float(cell.y+dz)/REGION))]=true
	for region:Vector2i in regions:
		var site:=region_site(world_seed,region.x,region.y)
		if not site.is_empty() and absi(site.cell.x-cell.x)<=reach and absi(site.cell.y-cell.y)<=reach:found.append(site)
	for legend:Dictionary in legends(world_seed):
		if absi(legend.cell.x-cell.x)<=reach and absi(legend.cell.y-cell.y)<=reach:found.append(legend)
	return found

## Likelihood (0-0.62) that a 24 km cell still holds a scattered find.
static func density(ground:Dictionary)->float:
	if ground.is_empty():return .12
	if String(ground.get("biome",""))=="water":return 0.0
	var value:=.04
	var river:=float(ground.get("river_distance_km",99.0))
	value+=.34 if river<2.5 else (.18 if river<8.0 else (.06 if river<20.0 else 0.0))
	if bool(ground.get("coastal",false)):value+=.20
	value+=clampf(float(ground.get("fertility",0)),0,1)*.14
	# Caves and rock shelters: exposed stone on broken ground.
	if float(ground.get("stone",0))>.45 and float(ground.get("slope",0))>.08:value+=.18
	# Old campsites: sheltered basins with game and forage.
	if float(ground.get("relief",0))<0:value+=.04
	value+=(clampf(float(ground.get("forage",0)),0,1)+clampf(float(ground.get("game",0)),0,1))*.05
	return clampf(value,0.0,.62)

# --- Finds ------------------------------------------------------------------

static func piece_id(site:Dictionary,index:int)->String:return "artifact:%d:%s:%d" % [current_seed(),String(site.id),index]

static func piece(site:Dictionary,index:int,day:int)->Dictionary:
	var h:=noise(("%s:piece:%d" % [String(site.id),index]))
	var tier:int
	var catalogue:int
	if bool(site.legendary):
		tier=4 if index==int(site.set_size)-1 else 2
		catalogue=int(site.catalogue) if tier==4 else (int(site.catalogue)+16*(index+1))%4096
	else:
		# A people's pieces share style and motif; forms differ within the set.
		var roll:=h%1000
		tier=3 if roll>=985 else (2 if roll>=850 else 1)
		var style:=(int(site.people_index)*5+3)%16
		var motif:=(int(site.people_index)*11+7)%16
		catalogue=((int(site.hash)/97+index*7)%16)+16*style+256*motif
	var record:=PREHISTORY.definition(catalogue)
	record.merge({"id":piece_id(site,index),"kind":"artifact","source_id":"","source_name":String(site.name),"position":{"x":site.position.x,"z":site.position.y},
		"observed_day":day,"returned_day":day,"study":0.0,"work":160.0 if tier==4 else 20.0+tier*20.0,"signals":["survey","culture","research"],"rarity":tier,
		"held_days":0.0,"exhibited":false,"acquisition":"Recovered at %s, a %s of %s" % [String(site.name),String(site.kind),String(site.people)],
		"site_id":String(site.id),"site_name":String(site.name),"set_name":String(site.set_name),"set_size":int(site.set_size)},true)
	if tier==4:record.name=String(site.legend_name)
	return record

static func next_piece(site:Dictionary,day:int)->Dictionary:
	for index:int in int(site.set_size):
		if not A.site_claimed(piece_id(site,index)):return piece(site,index,day)
	return {}

static func exhausted(site:Dictionary)->bool:
	for index:int in int(site.set_size):
		if not A.site_claimed(piece_id(site,index)):return false
	return true

## One find from a scout search around `position`: a site piece when a site is
## within reach, otherwise a scattered object from the densest nearby cells.
static func discover(system:Node,position:Vector2,day:int,_reserved:bool=false)->Dictionary:
	var cell:=cell_of(position)
	for site:Dictionary in sites_near_cell(cell,1):
		var found:=next_piece(site,day)
		if not found.is_empty():return found
	var world_seed:=current_seed()
	var cells:Array[Vector2i]=[]
	for dx:int in range(-1,2):
		for dz:int in range(-1,2):cells.append(cell+Vector2i(dx,dz))
	cells.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return noise("%d:order:%d:%d" % [world_seed,a.x,a.y])<noise("%d:order:%d:%d" % [world_seed,b.x,b.y]))
	for candidate:Vector2i in cells:
		var id:="artifact:%d:%d:%d" % [world_seed,candidate.x,candidate.y]
		if A.site_claimed(id):continue
		var center:=cell_center(candidate)
		var ground:Dictionary=system.ground_survey_authority.call(center) if system.ground_survey_authority.is_valid() else {}
		if noise(("%d:dense:%d:%d" % [world_seed,candidate.x,candidate.y]))%1000>=roundi(density(ground)*1000.0):continue
		var find:=A.find_at(world_seed,center,day)
		# Legendary pieces are placed at named sites, never rolled in the open.
		if int(find.rarity)>3:find.rarity=3;find.work=80.0
		return find
	return {}

static func claim(mission:Dictionary,record:Dictionary)->bool:
	var seen:Dictionary=WorldSimulation.state.society_exchange.get("artifact_sites",{})
	if record.is_empty() or A.site_claimed(String(record.id)) or seen.size()>=32768:return false
	seen[String(record.id)]=true;WorldSimulation.state.society_exchange["artifact_sites"]=seen
	mission.carried_collections.append(record)
	return true

## Parties passing a remembered site dig there, even on familiar home ground.
static func dig_rumored(system:Node,mission:Dictionary,position:Vector2,day:int)->void:
	var rumors:Dictionary=WorldSimulation.state.society_exchange.get("artifact_rumors",{})
	if rumors.is_empty() or int(mission.get("artifact_dig_day",-1))>=day:return
	if not mission.has("carried_collections"):mission.carried_collections=[]
	if mission.carried_collections.size()>=maxi(1,int(mission.get("personnel",2))/2):return
	for id:String in rumors:
		var site:=site_by_id(id)
		if site.is_empty() or position.distance_to(site.position)>DIG_RADIUS:continue
		mission["artifact_dig_day"]=day
		if claim(mission,next_piece(site,day)):
			preload("res://scripts/society_exchange.gd").log_event("Following an old account, the party dug at %s." % String(site.name))
		return

# --- Rumors -----------------------------------------------------------------

static func home()->Vector2:
	var world:Node=WorldSimulation.world
	if world==null:return Vector2.ZERO
	if WorldSimulation.actor_id=="player":return world.player_world_origin
	var index:int=world._civilization_index(WorldSimulation.actor_id)
	return world._civilization_world_position(world.civilizations[index]) if index>=0 else Vector2.ZERO

static func learn(site:Dictionary,day:int,confidence:float,source:String)->bool:
	if site.is_empty() or exhausted(site):return false
	var rumors:Dictionary=WorldSimulation.state.society_exchange.get("artifact_rumors",{})
	var id:=String(site.id)
	if rumors.has(id):
		if confidence<=float(rumors[id].confidence):return false
		rumors[id].confidence=confidence;rumors[id].hint=hint(site,confidence);rumors[id].source=source
		return true
	if rumors.size()>=RUMOR_LIMIT:
		var weakest:=""
		for key:String in rumors:
			if weakest=="" or float(rumors[key].confidence)<float(rumors[weakest].confidence):weakest=key
		if float(rumors[weakest].confidence)>=confidence:return false
		rumors.erase(weakest)
	rumors[id]={"day":day,"confidence":snappedf(confidence,.01),"source":source,"hint":hint(site,confidence)}
	WorldSimulation.state.society_exchange["artifact_rumors"]=rumors
	preload("res://scripts/society_exchange.gd").log_event("A new account: %s" % String(rumors[id].hint))
	return true

## Scouts sometimes hear of an old place nearby; a nearby legend is rarer news.
static func hear_local_tales(_system:Node,mission:Dictionary,position:Vector2,day:int)->void:
	var roll:=noise(("%s:tale:%d" % [str(mission.get("mission_id",0)),day]))%100
	if roll>=30:return
	var known:Dictionary=WorldSimulation.state.society_exchange.get("artifact_rumors",{})
	if roll<6:
		var legend:=nearest(legends(),position,1500.0,known)
		if not legend.is_empty() and learn(legend,day,.25,"A tale heard on the road"):return
	var cell:=cell_of(position)
	var candidates:Array=[]
	var region:=Vector2i(floori(float(cell.x)/REGION),floori(float(cell.y)/REGION))
	for dx:int in range(-2,3):
		for dz:int in range(-2,3):
			var site:=region_site(current_seed(),region.x+dx,region.y+dz)
			if not site.is_empty():candidates.append(site)
	learn(nearest(candidates,position,INF,known),day,.35,"Local memory along the scouts' route")

## Hosts share what they know of old places near their own lands.
static func hear_from_society(_source:String,source_name:String,position:Vector2,day:int)->void:
	var known:Dictionary=WorldSimulation.state.society_exchange.get("artifact_rumors",{})
	if learn(nearest(legends(),position,2500.0,known),day,.5,"Told by the people of "+source_name):return
	var cell:=cell_of(position)
	var region:=Vector2i(floori(float(cell.x)/REGION),floori(float(cell.y)/REGION))
	var candidates:Array=[]
	for dx:int in range(-3,4):
		for dz:int in range(-3,4):
			var site:=region_site(current_seed(),region.x+dx,region.y+dz)
			if not site.is_empty():candidates.append(site)
	learn(nearest(candidates,position,INF,known),day,.45,"Told by the people of "+source_name)

static func nearest(sites:Array,position:Vector2,limit:float,known:Dictionary)->Dictionary:
	var best:={};var best_distance:=limit
	for site:Dictionary in sites:
		if known.has(String(site.id)) or exhausted(site):continue
		var distance:=position.distance_to(site.position)
		if distance<best_distance:best=site;best_distance=distance
	return best

const DIRECTIONS:=["east","south-east","south","south-west","west","north-west","north","north-east"]
const OPENINGS:=["They say","It is told that","Old voices claim","A story goes that","Travelers swear"]
## Vague direction, distance and landmark; lower confidence blurs all three.
static func hint(site:Dictionary,confidence:float)->String:
	var from:=home()
	var offset:=Vector2(site.position)-from
	var h:=noise((String(site.id)+":hint"))
	var octant:=posmod(roundi(offset.angle()/(TAU/8.0)),8)
	if float(h%100)>confidence*100.0+20.0:octant=posmod(octant+(1 if h%2==0 else -1),8)
	var days:=offset.length()/25.0*(.8+float((h/100)%45)/100.0)
	var distance:="within a few days' walk" if days<3 else ("about a week's walk" if days<10 else ("two or three weeks' walk" if days<25 else ("a month or more on foot" if days<60 else "a season's journey or more")))
	var what:String=("the resting place of "+inline(String(site.legend_name))) if bool(site.legendary) and confidence>=.4 else (("a %s of %s" % [String(site.kind),String(site.people)]) if confidence>=.4 else ("an old %s" % String(site.kind)))
	return "%s %s lies %s of home, %s, %s." % [OPENINGS[h%OPENINGS.size()],what,DIRECTIONS[octant],distance,landmark(site)]

static func landmark(site:Dictionary)->String:
	var authority:Callable=WorldSimulation.world.ground_survey_authority if WorldSimulation.world!=null else Callable()
	var ground:Dictionary=authority.call(site.position) if authority.is_valid() else {}
	if float(ground.get("river_distance_km",99))<3.0:return "near running water"
	if bool(ground.get("coastal",false)):return "within sound of the sea"
	if float(ground.get("stone",0))>.45 and float(ground.get("slope",0))>.08:return "where broken rock overhangs"
	if float(ground.get("fertility",0))>.6:return "in green and generous country"
	if ground.has("label"):return "on %s" % String(ground.label).to_lower()
	return ["where old stones lean together","beneath a lone hill","where the land folds into a hollow","past the last good water"][int(site.hash)%4]

static func rumored_sites(observer:String="player")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var owner:Node=preload("res://scripts/society_exchange.gd").owner_state(observer)
	if owner==null:return result
	var rumors:Dictionary=owner.society_exchange.get("artifact_rumors",{})
	var claimed:Dictionary=owner.society_exchange.get("artifact_sites",{})
	for id:String in rumors:
		var site:=site_by_id(id,int(owner.world_seed))
		if site.is_empty():continue
		var rumor:Dictionary=rumors[id]
		var found:=false
		for index:int in int(site.set_size):
			if claimed.has("artifact:%d:%s:%d" % [int(owner.world_seed),id,index]):found=true;break
		var confident:=float(rumor.confidence)>=.4
		result.append({"id":id,"name":String(site.name) if confident else "An old %s" % String(site.kind),"hint":String(rumor.hint),"confidence":float(rumor.confidence),
			"known_since_day":int(rumor.day),"found":found,"exhausted":exhausted(site),"legendary":bool(site.legendary),"kind":String(site.kind),"source":String(rumor.source)})
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.confidence)>float(b.confidence))
	return result

static func valid_rumors(value:Variant)->bool:
	if not value is Dictionary or value.size()>64:return false
	for key:Variant in value:
		if not key is String or not (String(key).begins_with("site:") or String(key).begins_with("legend:")) or String(key).length()>64:return false
		var rumor:Variant=value[key]
		if not rumor is Dictionary or not rumor.has_all(["day","confidence","source","hint"]):return false
		if not (rumor.day is int or rumor.day is float) or rumor.day<0:return false
		if not (rumor.confidence is int or rumor.confidence is float) or rumor.confidence<0 or rumor.confidence>1:return false
		if not rumor.source is String or rumor.source.length()>240 or not rumor.hint is String or rumor.hint.length()>600:return false
	return true
