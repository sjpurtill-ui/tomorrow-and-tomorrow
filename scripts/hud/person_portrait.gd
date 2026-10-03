extends RefCounted
## One appearance for a persistent government person, regardless of screen or office.
## Living court members are given distinct pictures from the same art
## (court_lives.gd portrait slots): a cell of their own, then a mirrored one.
const PATH:="res://assets/portraits/founding_leaders.png"
const Early:=preload("res://scripts/hud/early_civ_art.gd")
## Each people's look (skin range): after the first age everyone shares one
## five-face painting, and a people is shown with the faces nearest its own.
## The painting has one deep-brown face, two medium and two light: where few
## faces fit a people, the same face is varied by a closer crop and a mirror
## (late_variant), so its people do not all look alike. More faces need new
## art (people_appearance.gd).
const Looks:=preload("res://scripts/people_appearance.gd")
const LIVES_PATH:="res://scripts/court_lives.gd"
static var sheet:Texture2D
static var _lives:GDScript
static func cells_for(person:Dictionary)->int:
	return 4 if Early.active() and Early.profile(person)!=3 else 5
static func natural_index(person:Dictionary)->int:
	var count:=cells_for(person)
	if Early.active() and person.has("early_art_index"):return posmod(int(person.early_art_index),count)
	var identity:=int(person.get("person_id",0))
	if identity<=0:identity=absi(String(person.get("name","Unknown")).hash())+1
	if person.has("portrait_index"):identity=int(person.portrait_index)+1
	if not Early.active():return int(_late_pick(person,identity-1)[0])
	return posmod(identity-1,count)
## The later faces in the order they suit this person's people.
static func late_order(person:Dictionary)->Array:
	return Looks.late_cells(Early.owner(person),_seed_of(person))
## After the first age: [face, mirrored, crop] for a person. One of the faces
## that fit their people; where fewer than three fit, the k-th person of a
## people takes the face again as a closer crop (left, right) and mirrored,
## six looks from one face before any repeats.
static func late_variant(person:Dictionary)->Array:
	var slot:=court_slot(person)
	if not slot.is_empty():
		var made:=_late_pick(person,int(slot[0]))
		return [made[0],bool(made[1])!=bool(slot[1]),made[2]]
	var identity:=int(person.get("person_id",0))
	if identity<=0:identity=absi(String(person.get("name","Unknown")).hash())+1
	if person.has("portrait_index"):identity=int(person.portrait_index)+1
	return _late_pick(person,identity-1)
static func _late_pick(person:Dictionary,k:int)->Array:
	var fitting:=Looks.late_fitting(Early.owner(person),_seed_of(person))
	var n:=fitting.size()
	var face:=int(fitting[posmod(k,n)])
	if n>=3:return [face,false,0]
	var turn:=posmod(k,n*6)/n
	return [face,turn>=3,turn%3]
static func _seed_of(person:Dictionary)->int:
	return int(person.get("appearance_world_seed",GameState.world_seed))
static func court_slot(person:Dictionary)->Array:
	if _lives==null:_lives=load(LIVES_PATH) as GDScript
	if _lives==null:return []
	var slot:Variant=_lives.call("portrait_slot",person)
	return slot if slot is Array else []
static func index_for(person:Dictionary)->int:
	var slot:=court_slot(person)
	if not Early.active():return int(late_variant(person)[0])
	if not slot.is_empty():return posmod(int(slot[0]),cells_for(person))
	return natural_index(person)
static func mirrored(person:Dictionary)->bool:
	if not Early.active():return bool(late_variant(person)[1])
	var slot:=court_slot(person)
	return not slot.is_empty() and bool(slot[1])
static func texture(person:Dictionary)->Texture2D:
	if Early.active():return Early.person_scene(person,index_for(person))
	var look:=late_variant(person)
	return slot_texture(person,[int(look[0]),bool(look[1]),int(look[2]),-1])
## What picture(person) shows, as plain values: the painted sheet, the cell
## taken from it and whether it is mirrored. The same key is the same picture,
## so a screen can keep a portrait while the person's other figures change.
static func picture_key(person:Dictionary)->Array:
	var image:=texture(person)
	var atlas:=image as AtlasTexture
	if atlas!=null:return [String(atlas.atlas.resource_path) if atlas.atlas!=null else "",atlas.region,mirrored(person)]
	return [String(image.resource_path) if image!=null else "",mirrored(person)]
## Distinct paintings for everyone shown together on one screen.
## Each person keeps a preferred painting (their own cell, or their court slot).
## When two people in the same view would share one, the later one (in a stable
## id/name order) takes the next free painting: another cell of their own
## people's set, then a cell from the neighbouring painted sets, then a closer
## crop. A mirror is never counted as a different painting.
## Returns one [index, mirrored, crop, set] slot per person, in the order given;
## set is the early painted set (EarlyCivArt.PATHS index) or -1 for the later
## founding-leaders sheet.
static func distinct_slots(people:Array)->Array:
	var order:Array=[]
	for i in people.size():order.append(i)
	order.sort_custom(func(a:int,b:int)->bool:return _identity(people[a])<_identity(people[b]))
	var registry:Dictionary={}
	var result:Array=[];result.resize(people.size())
	for i:int in order:
		result[i]=claim(registry,people[i] if people[i] is Dictionary else {})
	return result
## Incremental form for screens that add faces as they draw: `registry` is the
## screen's own Dictionary. The same person always gets the same slot there, and
## a new person never takes a painting already shown.
static func claim(registry:Dictionary,person:Dictionary)->Array:
	var who:=_identity(person)
	var people:Dictionary=registry.get_or_add("people",{});var used:Dictionary=registry.get_or_add("used",{})
	if people.has(who):return people[who]
	var family:=Early.profile(person) if Early.active() else -1
	var base:=index_for(person);var flip:=mirrored(person)
	var chosen:Array=[base,flip,0,family]
	if family<0:
		var look:=late_variant(person)
		chosen=[base,flip,int(look[2]),family]
	for candidate:Array in ([chosen] if family<0 else [])+_candidates(base,flip,family,[] if family>=0 else _late_candidates(person)):
		if not used.has(_painting_key(candidate)):chosen=candidate;break
	used[_painting_key(chosen)]=true;people[who]=chosen
	return chosen
static func _painting_key(slot:Array)->String:
	# Mirror excluded: a flipped copy is the same painting to the eye.
	return str([int(slot[3]),int(slot[0]),int(slot[2])])
static func _cells_in(family:int)->int:
	return 5 if family==3 or family<0 else 4
## The later painting's faces for a screen, in turn: every crop of the faces
## that fit the person's people (mirrored by turns, so the same face never
## looks twice the same), then the other faces, nearest first.
static func _late_candidates(person:Dictionary)->Array:
	var fitting:=Looks.late_fitting(Early.owner(person),_seed_of(person))
	var order:=late_order(person)
	var out:Array=[]
	var turn:=0
	for crop in 3:
		for cell in fitting:
			out.append([int(cell),turn%2==1,crop,-1]);turn+=1
	for crop in 3:
		for cell in order:
			if not fitting.has(cell):out.append([int(cell),crop%2==1,crop,-1])
	return out
static func _candidates(base:int,flip:bool,family:int,late:Array=[])->Array:
	if family<0 and not late.is_empty():return late
	var out:Array=[]
	var sets:Array=[family]
	if family>=0:
		# Neighbouring painted sets, nearest first, so borrowed faces stay close.
		for step in range(1,Early.PATHS.size()):sets.append(posmod(family+step,Early.PATHS.size()))
	for crop in 3:
		for f:int in sets:
			var count:=_cells_in(f)
			for step in count:out.append([posmod(base+step,count),flip,crop,f])
	return out
static func _identity(person:Variant)->String:
	if not person is Dictionary:return ""
	var id:=int((person as Dictionary).get("person_id",0))
	return "%09d" % id if id>0 else "~"+String((person as Dictionary).get("name",""))
static func slot_texture(person:Dictionary,slot:Array)->Texture2D:
	var index:=int(slot[0]) if slot.size()>0 else index_for(person)
	var source:Texture2D
	var family:=int(slot[3]) if slot.size()>3 else -1
	if Early.active() and family>=0:source=Early.cell(Early.PATHS[family],posmod(index,_cells_in(family)),5 if family==3 else 2,1 if family==3 else 2)
	elif Early.active():source=Early.person_scene(person,index)
	else:
		if sheet==null:sheet=load(PATH) as Texture2D
		var atlas:=AtlasTexture.new();atlas.atlas=sheet
		var cell:=Vector2(sheet.get_width()/5.0,sheet.get_height())
		atlas.region=Rect2(Vector2(index*cell.x+5,5),cell-Vector2(10,10));source=atlas
	var crop:=int(slot[2]) if slot.size()>2 else 0
	if crop<=0 or not source is AtlasTexture:return source
	# A closer crop of the same painting: 78% of the cell, toward one side.
	var closer:=(source as AtlasTexture).duplicate() as AtlasTexture
	var region:=closer.region;var inner:=region.size*.78
	var offset:=Vector2((region.size.x-inner.x)*(0.15 if crop==1 else 0.85),(region.size.y-inner.y)*.2)
	closer.region=Rect2(region.position+offset,inner);return closer
## A picture using a slot from distinct_slots().
static func picture_slot(person:Dictionary,slot:Array,width:float=80,height:float=100)->TextureRect:
	var image:=picture(person,width,height)
	if slot.size()>=2:image.texture=slot_texture(person,slot);image.flip_h=bool(slot[1])
	return image
static func picture(person:Dictionary,width:float=80,height:float=100)->TextureRect:
	var image:=TextureRect.new();image.name="Portrait";image.texture=texture(person)
	image.flip_h=mirrored(person)
	image.custom_minimum_size=Vector2(width,height);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	# Paintings fill their frame (cover), never letterbox with a blank band.
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.set_meta("civilization_id",Early.owner(person))
	image.tooltip_text=String(person.get("name",""));image.set_meta("person_id",int(person.get("person_id",0)))
	if Early.active():image.tooltip_text+=" · Character illustration; current duties and conditions are reported alongside."
	return image
