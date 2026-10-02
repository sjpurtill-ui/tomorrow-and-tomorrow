extends RefCounted
## NATION BORDERS: each people's land on the map, as our people know it, and
## the lines where two peoples' lands meet. Static and testable; the drawing
## lives in nation_border_layer.gd, the cut in nation_border_partition.gd and
## the ink in nation_border_ink.gd.
##
## What is drawn follows what each people knows:
##   none      Before Boundary Marker Surveys: a faint wash of the people's
##             colour on the worked ground round its towns; no line.
##   frontier  From Boundary Marker Surveys (the wild west): its land washed
##             in its colour, thinning to nothing at the edge with no rim. A
##             stroke appears only where two peoples' lands actually meet,
##             along the real meeting line, in both peoples' colours, fading
##             out at each end where the shared frontier dissolves into open
##             land. Against open land there is only the fading wash. A
##             kingdom's wash is a little firmer; nothing else changes until
##             the Peace Congress.
##   state     From the Peace Congress (Realms recognize each other's borders
##             and sovereignty): recognition is mutual, so only between two
##             peoples who both know it is the border one crisp, continuous
##             line in both colours with no fade. Against anyone else, or open
##             land, the frontier look goes on.
## While we are at war with a people, or in a hot feud, the real meeting line
## between us is lit red (war_map_overlay.gd puts its mark on it).
##
## Other peoples show only as we know them: their towns our people have
## found (city intelligence), on ground our people have charted. Everything
## is derived from the game as it stands; nothing here is saved.

const Partition:=preload("res://scripts/nation_border_partition.gd")
const BorderInk:=preload("res://scripts/nation_border_ink.gd")
const IDENTITIES:=preload("res://scripts/civilization_identity.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")

const FRONTIER_DISCOVERY:="boundary_marker_surveys"
const STATE_DISCOVERY:="sovereign_realms_congress"
const KINGDOM_DISCOVERY:="kingship"
const STAGE_NONE:=0
const STAGE_FRONTIER:=1
const STAGE_STATE:=2

## Our people's colour on the map: a deep royal plum, gold's old partner on
## our seal. The twelve palettes other peoples wear (civilization_identity.gd)
## leave this hue empty between their violet and their rose; on the map, where
## they wear their light band colours, it stands further from every one of
## them than they stand from each other. It is never the war's red, the
## water's slate or the land's olive and ochre.
const PLAYER_COLOR:=Color("#7b2a7a")
const INK:=Color("#2b2118")

## How strongly a people's colour lies on the heart of its land.
const WASH_NONE:=0.07
const WASH_FRONTIER:=0.17
const WASH_STATE:=0.19
## A kingdom's colour lies a little firmer: stronger, and full further out.
const KINGDOM_FIRMER:=1.15

## The grid over the view: this many cells a side, five views across, so a
## cell is about 25 pixels; it moves in steps of 24 cells and zooms in steps
## of 1.8 (the settlement network's zoom buckets).
const GRID_CELLS:=160
const GRID_VIEWS:=5.0
const GRID_STEP_CELLS:=24
const ZOOM_STEP:=1.8
## A people's claim judged only from a head count is a circle of the worked
## ground (settlement_model: people / 72 km² at a reach of 0.8).
const PEOPLE_PER_KM2:=72.0
const TYPICAL_REACH:=0.8

## Tests pin what a people knows here (owner -> discovery ids).
static var knowledge_override:Dictionary={}
## The lines last drawn, for the war marks: [{owners: [a, b], kind, points}].
static var published:Array=[]
static var published_revision:=0


# --- What a people knows --------------------------------------------------------

## The discoveries a people knows: ours from the game, another people's from
## its own simulation (every people researches under the same rules).
static func known_ids(owner:String)->Array:
	if knowledge_override.has(owner): return knowledge_override[owner]
	if Engine.get_main_loop()==null: return []
	if owner=="" or owner=="player": return GameState.known_discoveries
	var actors:Dictionary=WorldSimulation.actors
	if not actors.has(owner): return []
	var systems:Dictionary=(actors[owner] as Dictionary).get("systems",{})
	var state:Object=systems.get("GameState")
	if state==null: return []
	var ids:Variant=state.get("known_discoveries")
	return ids if ids is Array else []


static func knows(owner:String,id:String)->bool:
	return known_ids(owner).has(id)


## How a people draws its land: STAGE_NONE, STAGE_FRONTIER or STAGE_STATE.
static func stage_of(owner:String)->int:
	if knows(owner,STATE_DISCOVERY): return STAGE_STATE
	if knows(owner,FRONTIER_DISCOVERY): return STAGE_FRONTIER
	return STAGE_NONE


## How the meeting line of two peoples is drawn: "state" only when both know
## the Peace Congress (recognition is mutual), "frontier" once either marks
## its land, "" before (no line).
static func line_kind(stage_a:int,stage_b:int)->String:
	if stage_a>=STAGE_STATE and stage_b>=STAGE_STATE: return "state"
	if maxi(stage_a,stage_b)>=STAGE_FRONTIER: return "frontier"
	return ""


# --- Colours --------------------------------------------------------------------

## A people's colour on the map: ours, or the colour of its emblem's band, the
## one its towns' marks already wear (city_map_identity.foreign accent).
static func nation_color(owner:String)->Color:
	if owner=="player": return PLAYER_COLOR
	var world_seed:=int(WorldSimulation.state.world_seed) if Engine.get_main_loop()!=null else 0
	return Color(String(IDENTITIES.identity(world_seed,owner).get("color","bdc6c7")))


## How a people's land is drawn: {color, stage, firm, wash, foreign}.
static func style(owner:String)->Dictionary:
	var stage:=stage_of(owner)
	var firm:=knows(owner,KINGDOM_DISCOVERY)
	var wash:float=[WASH_NONE,WASH_FRONTIER,WASH_STATE][stage]
	if firm: wash*=KINGDOM_FIRMER
	return {"color":nation_color(owner),"stage":stage,"firm":firm,"wash":wash,"foreign":owner!="player"}


## How strongly the washes show in a view `view_km` high: full from the
## region view outward, subtle close in.
static func wash_fade(view_km:float)->float:
	return lerpf(0.22,1.0,smoothstep(5.0,45.0,view_km))


## How strongly the lines show in a view `view_km` high.
static func ink_fade(view_km:float)->float:
	return lerpf(0.45,1.0,smoothstep(5.0,45.0,view_km))


# --- Claims ---------------------------------------------------------------------

## {owner, id, center, radius (its furthest reach), table (its outline), key
## (what it draws, coarsely: claim_key)}.
static func make_claim(owner:String,id:String,center:Vector2,radius:float,boundary:Variant=null)->Dictionary:
	var table:=Partition.shape_table(center,boundary,radius)
	var reach:=0.0
	for value in table: reach=maxf(reach,value)
	var claim:={"owner":owner,"id":id,"center":center,"radius":reach,"table":table}
	claim["key"]=claim_key(claim)
	return claim


## What one claim draws, coarsely: its holder, its town, its hearth, its reach
## in steps of about 2% and its outline's shape. Growth short of a step keys
## the same, so it redraws nothing.
static func claim_key(claim:Dictionary)->int:
	var radius:=maxf(float(claim.get("radius",0.0)),0.000001)
	var bucket:=roundi(log(radius)/log(1.02))
	# The hearth in steps of a twentieth of the claim's size bucket, so the same
	# town in the same bucket always keys the same.
	var step:=pow(1.02,float(bucket))*0.05
	var shape:=PackedInt32Array()
	for value in (claim.get("table",PackedFloat32Array()) as PackedFloat32Array): shape.append(roundi(value/radius*40.0))
	return hash([String(claim.get("owner","")),String(claim.get("id","")),((claim.get("center",Vector2.ZERO) as Vector2)/step).round(),bucket,hash(shape)])


## A claim judged from a head count alone (km).
static func estimated_radius(population:float)->float:
	return clampf(sqrt(maxf(0.12,maxf(population,1.0)/PEOPLE_PER_KM2*TYPICAL_REACH*TYPICAL_REACH)/PI),0.32,4600.0)


## Our towns' claims from the settlement network (settlement_model), each in
## its own outline; a town an enemy holds is that people's.
static func own_claims(settlements:Array)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for settlement_variant in settlements:
		if not settlement_variant is Dictionary: continue
		var settlement:Dictionary=settlement_variant
		var radius:=float(settlement.get("claim_radius_km",0.0))
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		if radius<=0.0 or not position_value is Vector2: continue
		var holder:=String(settlement.get("occupied_by",""))
		if holder=="" or holder=="human": holder="player"
		out.append(make_claim(holder,"own:"+String(settlement.get("id","")),position_value,radius,settlement.get("boundary",PackedVector2Array())))
	return out


## The towns of other peoples our people know of (city intelligence), within
## `reach` km of `center`: each with the claim the world keeps for it (the
## same settlement model as ours) or, where it keeps none, one judged from the
## head count last reported. A town held by us is ours. Unnamed places and
## burned towns have no land to draw.
## `cache` (city id -> {sig, claim}) keeps a town's claim while its holder,
## place and reach step hold, so a read rebuilds only what moved. Our book is
## read in place (city_intelligence.records), and who holds a town is told as
## own_control tells it: our people always know what they hold.
static func foreign_claims(center:Vector2,reach:float,cache:Dictionary={})->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if Engine.get_main_loop()==null or CivilizationSystem.city_intelligence==null: return out
	var regions:Dictionary={}
	for civ:Dictionary in CivilizationSystem.civilizations:
		for region:Dictionary in civ.get("strategic_regions",[]): regions[String(region.get("id",""))]=region
	var records:Variant=CivilizationSystem.city_intelligence.get("records")
	var book:Dictionary=(records as Dictionary).get("player",{}) if records is Dictionary else {}
	var kept:Dictionary={}
	for city_variant in book:
		var city_id:=String(city_variant)
		var report_variant:Variant=book[city_variant]
		if not report_variant is Dictionary or city_id=="": continue
		var report:Dictionary=report_variant
		var location:Variant=report.get("position",{})
		if not location is Dictionary: continue
		var at:=Vector2(float((location as Dictionary).get("x",0.0)),float((location as Dictionary).get("z",0.0)))
		if at.distance_squared_to(center)>reach*reach: continue
		var region:Dictionary=regions.get(city_id,{})
		var holder:=String(report.get("controller",""))
		var live:=String(region.get("controller","")) if not region.is_empty() else ""
		if live=="player" and holder!="player": holder="player"
		elif holder=="player" and live!="" and live!="player": holder=live
		if holder=="": holder=String(report.get("civ_id",""))
		if holder=="human": holder="player"
		if holder=="" or _report_damage(report)>=0.6: continue
		if _ruined(region) or not bool(region.get("settlement_founded",true)): continue
		var place:Variant=region.get("position",at)
		if place is Vector2: at=place
		var boundary:Variant=region.get("boundary",[])
		var radius:=0.0
		if (boundary is Array or boundary is PackedVector2Array) and int(boundary.size())>=3:
			for point in boundary:
				if point is Vector2: radius=maxf(radius,(point as Vector2).distance_to(at))
		if radius<=0.0:
			var estimate:Dictionary=(report.get("fields",{}) as Dictionary).get("population",{})
			var people:=(float(estimate.get("low",0.0))+float(estimate.get("high",0.0)))*0.5
			if people<=0.0: people=float(region.get("population",800.0))
			radius=estimated_radius(people)
			boundary=null
		var sig:=hash([holder,at.snapped(Vector2.ONE*0.001),roundi(log(maxf(radius,0.000001))/log(1.02)),int(boundary.size()) if boundary!=null else 0])
		var held:Dictionary=cache.get(city_id,{})
		var claim:Dictionary=held.get("claim",{}) if int(held.get("sig",0))==sig else make_claim(holder,"town:"+city_id,at,radius,boundary)
		kept[city_id]={"sig":sig,"claim":claim}
		out.append(claim)
	cache.clear()
	cache.merge(kept)
	return out


static func _report_damage(report:Dictionary)->float:
	var damage:Dictionary=(report.get("fields",{}) as Dictionary).get("damage",{})
	if damage.is_empty(): return 0.0
	return (float(damage.get("low",0.0))+float(damage.get("high",0.0)))*0.5


## A town we burned and nobody is known to have resettled (town_ledger).
static func _ruined(region:Dictionary)->bool:
	var ledger:Variant=region.get("ledger")
	if not ledger is Dictionary: return false
	var ruin:Variant=(ledger as Dictionary).get("ruin")
	if not ruin is Dictionary or (ruin as Dictionary).is_empty(): return false
	var resettle:Variant=(ruin as Dictionary).get("resettle",{})
	return not (resettle is Dictionary and bool((resettle as Dictionary).get("known",false)))


## What a set of claims draws, coarsely: a town moving, a claim's reach
## changing by about 2% or its outline changing shape. Daily growth short of
## that redraws nothing.
static func claims_key(claims:Array)->int:
	var parts:=PackedInt64Array()
	for claim:Dictionary in claims: parts.append(int(claim["key"]) if claim.has("key") else claim_key(claim))
	return hash(parts)


# --- The grid -------------------------------------------------------------------

## The grid for a view `view_km` high about `target`, snapped so that small
## zooms and pans reuse it: {origin, cell, n, level, view_km, key, box}.
static func grid_for(target:Vector2,view_km:float)->Dictionary:
	var level:=roundi(log(maxf(view_km,0.02))/log(ZOOM_STEP))
	var size:=pow(ZOOM_STEP,float(level))
	var cell:=size*GRID_VIEWS/float(GRID_CELLS)
	var step:=cell*float(GRID_STEP_CELLS)
	var at:=Vector2i(roundi(target.x/step),roundi(target.y/step))
	var side:=cell*float(GRID_CELLS)
	var origin:=Vector2(at)*step-Vector2.ONE*side*0.5
	return {"origin":origin,"cell":cell,"n":GRID_CELLS+1,"level":level,"view_km":size,"key":[level,at.x,at.y],"box":Rect2(origin,Vector2.ONE*side)}


## The whole build from copies (any thread): the partition, its ground from
## the sampler where none is given, each line's kind and war, and the ink.
## input: the partition's (nation_border_partition.setup) plus styles[i].stage,
## war (owner index -> "war"/"feud" for our enemies), player (our owner
## index), view_km, and for the ground sampler, height_cache and level.
static func compose(input:Dictionary,cancel:Array=[false])->Dictionary:
	var began:=Time.get_ticks_usec()
	var partition:=Partition.new()
	partition.setup(input)
	var needed:=partition.assign()
	var given:Variant=input.get("heights")
	if not (given is PackedFloat32Array and (given as PackedFloat32Array).size()==partition.n*partition.n):
		partition.set_heights(Partition.sample_heights(input.get("sampler"),partition.origin,partition.cell,partition.n,needed,input.get("height_cache",{}),int(input.get("level",0)),cancel))
	if bool(cancel[0]): return {}
	var result:=partition.build(cancel)
	if result.is_empty(): return {}
	var styles:Array=input.get("styles",[])
	var war:Dictionary=input.get("war",{})
	var player:=int(input.get("player",0))
	var colors:Array=[]
	for style:Dictionary in styles: colors.append(style.get("color",INK))
	for line:Dictionary in result.lines:
		var a:=int(line.a)
		var b:=int(line.b)
		line["kind"]=line_kind(int((styles[a] as Dictionary).get("stage",0)),int((styles[b] as Dictionary).get("stage",0)))
		var other:=b if a==player else (a if b==player else -1)
		line["war"]=String(war.get(other,"")) if other>=0 else ""
	result["ink"]=BorderInk.build(result.lines,colors,float(input.get("view_km",1.0)))
	result["ms"]=float(Time.get_ticks_usec()-began)/1000.0
	return result


# --- War --------------------------------------------------------------------------

## The peoples at war with us or in a hot feud (blood spilled within the year,
## as the war marks count it): civ id -> "war" or "feud". A small people's
## fight is a feud even in a war (conflict_scale.gd).
static func hot_enemies()->Dictionary:
	var out:Dictionary={}
	if Engine.get_main_loop()==null: return out
	for civ:Dictionary in CivilizationSystem.civilizations:
		if bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)):
			var id:=String(civ.get("id",""))
			out[id]="war" if WarLoop.formal(id) else "feud"
	var ledger:Variant=WarLoop.state().get("fronts",{})
	if ledger is Dictionary:
		var today:=int(GameState.elapsed_days)
		for civ_id in ledger:
			var front:Variant=(ledger as Dictionary)[civ_id]
			if not front is Dictionary or out.has(String(civ_id)): continue
			if int((front as Dictionary).get("level",0))>=1 and today-int((front as Dictionary).get("last_harm",-99999))<=WarLoop.FEUD_HOT_DAYS and not WarLoop.broken(String(civ_id)):
				out[String(civ_id)]="feud"
	return out


## The lines just drawn, for the war marks; owners by index.
static func publish(lines:Array,owners:PackedStringArray)->void:
	var out:Array=[]
	for line:Dictionary in lines:
		var a:=int(line.get("a",-1))
		var b:=int(line.get("b",-1))
		if a<0 or b<0 or a>=owners.size() or b>=owners.size(): continue
		out.append({"owners":[owners[a],owners[b]],"kind":String(line.get("kind","")),"points":line.points})
	published=out
	published_revision+=1


## Where the drawn line between peoples `a` and `b` passes nearest `near`;
## Vector2.INF when their lands meet nowhere we draw.
static func meeting_point(a:String,b:String,near:Vector2)->Vector2:
	var best:=Vector2.INF
	for line:Dictionary in published:
		var owners:Array=line.owners
		if not ((owners[0]==a and owners[1]==b) or (owners[0]==b and owners[1]==a)): continue
		var point:=nearest_on_polyline(line.points,near)
		if not best.is_finite() or point.distance_squared_to(near)<best.distance_squared_to(near): best=point
	return best


static func nearest_on_polyline(points:PackedVector2Array,near:Vector2)->Vector2:
	if points.is_empty(): return Vector2.INF
	var best:=points[0]
	for i in range(1,points.size()):
		var point:=Geometry2D.get_closest_point_to_segment(near,points[i-1],points[i])
		if point.distance_squared_to(near)<best.distance_squared_to(near): best=point
	return best


# --- Words ------------------------------------------------------------------------

## A border in a few words, on hover: "Frontier of the Kezari: claimed, not
## agreed" or "Border of the Kezari: fixed at the Peace Congress". `second`
## names the other side of a line between two other peoples.
static func line_words(kind:String,first:String,second:String="",war:String="")->String:
	var who:=first if second=="" else "%s and %s" % [first,second]
	var text:=""
	match kind:
		"state": text="Border of %s: fixed at the Peace Congress" % who
		"frontier": text="Frontier of %s: claimed, not agreed" % who
		_: text="Where our land meets %s" % who
	if war=="war": text+=". At war: their men cross here"
	elif war=="feud": text+=". A feud: their men cross here"
	return text


## "the Kezari", or "strangers" before we know their name.
static func people_name(owner:String)->String:
	if owner=="player": return "our people"
	return preload("res://scripts/map_ownership.gd").people(owner)


static func words_for(owners:Array,kind:String,war:String="")->String:
	var a:=String(owners[0])
	var b:=String(owners[1])
	if a=="player": return line_words(kind,people_name(b),"",war)
	if b=="player": return line_words(kind,people_name(a),"",war)
	return line_words(kind,people_name(a),people_name(b),war)


## What a discovery does to the map, for the research screens; "" for most.
static func research_note(id:String)->String:
	match id:
		FRONTIER_DISCOVERY: return "Our lands are marked: our frontier shows on the map."
		STATE_DISCOVERY: return "Borders with realms that also know this become fixed lines."
		KINGDOM_DISCOVERY: return "A kingdom's colour lies a little firmer on its land on the map."
	return ""
