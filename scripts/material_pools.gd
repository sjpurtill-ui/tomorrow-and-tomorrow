extends RefCounted
## Common materials as one pool per seat (2026-10-09 direction).
##
## Timber, fibre, stone, clay, fine sand and limestone are not tracked site by
## site. Each is one pool record in the seat's resource list (`pool: true`,
## standing at the seat), worked by the same daily flow as any deposit: the
## cutters' share, yield, depth, regrowth and the carriers' haul all use the
## deposit rules, but a pool counts as working_fronts() faces in the labour
## split and its hauls arrive the day they leave (carriers as one number:
## capacity still falls with how far the worked land reaches).
##
## Surface pools (timber, fibre, loose stone) grow by opening the next ring of
## ground around the seat (SURFACE_FRONT_SPACING_KM apart, as far as the
## carriers search) once three quarters of what they hold is cut. Clay, sand,
## limestone and quarried stone grow when a found deposit becomes workable: it
## is folded in, its world reserve claimed. Older saves fold every site of
## these kinds on their first day, loads on the road delivered at once.
## Strategic goods (ores, coal, salt, sulfur, nitrates, oil...) keep deposits.

const POOLED:={
	"Timber":{"source":"woodland_catchment","stock":600.0,"minimum":0.08,"surface":true},
	"Fiber Plants":{"source":"plant_fiber_catchment","stock":180.0,"minimum":0.08,"surface":true},
	"Stone":{"source":"surface_stone_catchment","stock":1000.0,"minimum":0.03,"surface":true},
	"Clay":{"source":"common_pool","surface":false},
	"Fine Sand":{"source":"common_pool","surface":false},
	"Limestone":{"source":"common_pool","surface":false},
}
## A surface pool opens its next ring once it holds less than this share.
const OPEN_BELOW:=0.25
const CELL_KM2:=9.0
## Where a surface pool's ground was opened, nearest the seat first, kept for
## the map's cut-over marks ([x, z] km). The map draws the nearest 32.
const CELL_LIMIT:=256

static func pooled(resource:String)->bool:
	return POOLED.has(resource)

static func is_pool(deposit:Dictionary)->bool:
	return bool(deposit.get("pool",false))

## The seat's pool of `resource`, or {}.
static func pool_of(resource:String)->Dictionary:
	for deposit:Dictionary in WorldSimulation.state.resource_deposits:
		if is_pool(deposit) and String(deposit.get("resource",""))==resource:return deposit
	return {}

## How far the seat's worked land of this pool reaches, km.
static func reach_km(pool:Dictionary)->float:
	return (float(pool.get("ring",0))+0.5)*float(WorldSimulation.resources.SURFACE_FRONT_SPACING_KM)

## The average carry from the worked land to the stores: two thirds of the
## reach, as for points spread evenly over a disc.
static func haul_km(pool:Dictionary)->float:
	return reach_km(pool)*2.0/3.0

## Fold sites into pools, open new ground, once a day before the flow.
static func ensure(rs:Node,context:Dictionary)->void:
	if not bool(context.get("settled",false)):return
	var origin_value:Variant=context.get("origin",WorldSimulation.state.settlement_founded_at)
	var origin:=Vector3(origin_value.x,0.0,origin_value.z) if origin_value is Vector3 else Vector3(origin_value.x,0.0,origin_value.y)
	var deposits:Array=WorldSimulation.state.resource_deposits
	var pools:Dictionary={}
	var folding:Dictionary={}
	for deposit:Dictionary in deposits:
		var resource:=String(deposit.get("resource",""))
		if not POOLED.has(resource):continue
		if is_pool(deposit):pools[resource]=deposit;continue
		if _foldable(deposit,POOLED[resource]):(folding.get_or_add(resource,[]) as Array).append(deposit)
	for resource:String in POOLED:
		var spec:Dictionary=POOLED[resource]
		var pool:Dictionary=pools.get(resource,{})
		var to_fold:Array=folding.get(resource,[])
		if pool.is_empty() and to_fold.is_empty() and not bool(spec.surface):continue
		var fresh:=pool.is_empty()
		if fresh:pool=_new_pool(rs,resource,spec,origin)
		pool.position=origin
		if not to_fold.is_empty():_fold(rs,pool,to_fold,origin)
		if bool(spec.surface):_open_ground(rs,pool,spec,context,Vector2(origin.x,origin.z))
		# Bare ground holds no pool until it has something to work.
		if fresh and float(pool.initial_amount)>0.0:deposits.append(pool)
	if not folding.is_empty():
		var kept:Array=[]
		for deposit:Dictionary in deposits:
			if not bool(deposit.get("folded",false)):kept.append(deposit)
		deposits.assign(kept)

## A site joins the pool: every surface front; a world deposit once workable.
static func _foldable(deposit:Dictionary,spec:Dictionary)->bool:
	var source:=String(deposit.get("landscape_source",""))
	if source in ["woodland_catchment","plant_fiber_catchment","surface_stone_catchment"]:return true
	return String(deposit.get("stage","")) in ["accessible","developed"]

static func _new_pool(rs:Node,resource:String,spec:Dictionary,origin:Vector3)->Dictionary:
	var pool:Dictionary=rs._deposit(resource,origin,0.5,0.0,0,"seat_pool")
	pool.id="pool_"+resource.to_snake_case()
	pool.merge({"pool":true,"stage":"developed","clues":1.0,"survey":1.0,"access":1.0,"blockers":[],"landscape_source":String(spec.source),
		"ring":-1,"area_km2":0.0,"initial_amount":0.0,"remaining":0.0,"surface_density":0.0,"cells":[],"bottleneck":"Working the land around the seat"},true)
	return pool

## Adds sites to the pool: their standing stock, capacity, quality (weighted
## by capacity) and worked history. What waits at them or is on the road
## reaches the stores now; their world reserve is the pool's from here on.
static func _fold(rs:Node,pool:Dictionary,sites:Array,origin:Vector3)->void:
	var Resources:=preload("res://scripts/civilization_resources.gd")
	var stock:Dictionary=WorldSimulation.state.resource_stockpiles
	var resource:=String(pool.resource)
	var spacing:=float(rs.SURFACE_FRONT_SPACING_KM)
	for site:Dictionary in sites:
		if site.has("world_key"):Resources.available(site)
		var capacity:=maxf(0.0,float(site.get("initial_amount",0.0)))
		var standing:=maxf(0.0,float(site.get("remaining",0.0)))
		if bool(site.get("spent",false)):standing=0.0
		var weight:=float(pool.initial_amount)+capacity
		if weight>0.0:pool.quality=(float(pool.quality)*float(pool.initial_amount)+float(site.get("quality",0.5))*capacity)/weight
		pool.initial_amount=float(pool.initial_amount)+capacity
		pool.remaining=float(pool.remaining)+standing
		pool.area_km2=float(pool.area_km2)+float(site.get("area_km2",CELL_KM2 if site.has("landscape_source") else 0.0))
		pool.stock_at_source=float(pool.stock_at_source)+float(site.get("stock_at_source",0.0))
		var moving:=float(rs.in_transit_for(site))
		if moving>0.0:
			stock[resource]=float(stock.get(resource,0.0))+moving
			pool.lifetime_delivered=float(pool.lifetime_delivered)+moving
		pool.lifetime_extracted=float(pool.lifetime_extracted)+float(site.get("lifetime_extracted",0.0))
		pool.lifetime_delivered=float(pool.lifetime_delivered)+float(site.get("lifetime_delivered",0.0))
		pool.depth=maxi(int(pool.get("depth",0)),int(rs._depth(site)))
		# A front's ring: how far out the land it stood on was opened.
		if site.has("landscape_source"):
			var at:Vector3=site.get("position",origin)
			pool.ring=maxi(int(pool.ring),ceili(Vector2(at.x,at.z).distance_to(Vector2(origin.x,origin.z))/spacing-0.5))
			_note_cell(pool,Vector2(at.x,at.z),Vector2(origin.x,origin.z))
		if site.has("world_key") and WorldSimulation.geography_stock.has(site.world_key):
			var reserve:Dictionary=WorldSimulation.geography_stock[site.world_key]
			reserve.remaining=0.0;reserve["claimed"]=true
		site["folded"]=true
	if float(pool.remaining)>0.001:pool.erase("spent")

## Opens the next ring of ground once the pool runs low, as far as the
## carriers search (surface_search_rings). Ring 0 is the seat's own ground.
static func _open_ground(rs:Node,pool:Dictionary,spec:Dictionary,context:Dictionary,origin:Vector2)->void:
	var limit:int=rs.surface_search_rings()
	while int(pool.ring)<limit and float(pool.remaining)<float(pool.initial_amount)*OPEN_BELOW+0.001:
		var ring:=int(pool.ring)+1
		# [density, where] for each cell of the ring.
		var cells:Array=[]
		if ring==0:
			var field:Dictionary=context.get("woodland_catchment",{}) if String(pool.resource)=="Timber" else (context.get("surface_material_catchments",{}) as Dictionary).get(String(pool.resource),{})
			if not field.is_empty():cells.append([clampf(float(field.get("density",0.0)),0.0,1.0),origin])
		elif WorldSimulation.surface_material_provider.is_valid():
			for entry:Array in (rs._surveyed_ring(origin,ring).get(String(pool.resource),[]) as Array):
				var at:Vector3=(entry[1] as Dictionary).get("position",Vector3(origin.x,0.0,origin.y))
				cells.append([float(entry[0]),Vector2(at.x,at.z)])
		pool.ring=ring
		var added:=0.0
		for cell:Array in cells:
			var density:float=cell[0]
			if density<float(spec.minimum):continue
			_note_cell(pool,cell[1],origin)
			var amount:=CELL_KM2*density*float(spec.stock)
			var weight:=float(pool.initial_amount)+amount
			pool.quality=(float(pool.quality)*float(pool.initial_amount)+(0.45+density*0.65)*amount)/maxf(0.0001,weight)
			pool.initial_amount=weight
			pool.remaining=float(pool.remaining)+amount
			pool.area_km2=float(pool.area_km2)+CELL_KM2
			added+=amount
		if added>0.0:pool.erase("spent")

## Remembers where ground was opened, keeping the CELL_LIMIT nearest the seat.
static func _note_cell(pool:Dictionary,at:Vector2,origin:Vector2)->void:
	var cells:Array=pool.get_or_add("cells",[])
	cells.append([snappedf(at.x,0.01),snappedf(at.y,0.01)])
	if cells.size()>CELL_LIMIT*2:
		cells.sort_custom(func(a:Array,b:Array)->bool:return Vector2(a[0],a[1]).distance_squared_to(origin)<Vector2(b[0],b[1]).distance_squared_to(origin))
		cells.resize(CELL_LIMIT)

## The pool's share of the cutters counts as this many faces, the most a
## people works of one kind at once (resource_system.gd working_fronts).
static func faces(rs:Node)->float:
	return float(rs.working_fronts())

## The people's wood for the screens: {stands_known, stands_working}, read
## from the timber pool's opened ground (one stand per opened cell).
static func woodland_stands()->Dictionary:
	var pool:=pool_of("Timber")
	if pool.is_empty():return {"stands_known":0,"stands_working":0}
	var known:=roundi(float(pool.get("area_km2",0.0))/CELL_KM2)
	var working:=known if float(pool.remaining)>=maxf(1.0,float(pool.initial_amount)*0.05) else 0
	return {"stands_known":known,"stands_working":working}
