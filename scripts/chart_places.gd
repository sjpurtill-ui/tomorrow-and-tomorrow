extends RefCounted
## The places the chart draws round and at every town (codex/map-beauty):
## every town of ours and every stranger's town the people know, nearest the
## view first. The terrain shader (map_chart.gdshaderinc) hatches the fields
## and dots the pasture inside how far each place farms (mc_farmland), and
## draws its built ground as a small plan of ink blocks round its mark
## (mc_towns), walled if it is, broken if it was burned, tinted with its
## holder's colour the way its mark on the map is (map_ownership.gd).
## Visual only: it reads the settlements and the city reports, and changes
## nothing.

const MAX_PLACES:=24
const REFRESH_MSEC:=2000
## Places farther than this from the view are not sent (km).
const REACH_KM:=900.0
const OWNERSHIP:=preload("res://scripts/map_ownership.gd")

static var _checked_at:=-REFRESH_MSEC
static var _view_anchor:=Vector2.INF
## (x, z, how far its fields reach km, 0 ours / 1 a stranger's)
static var places:=PackedVector4Array()
## (built radius km, 1 walled + 2 ruined, holder's colour packed as
## r*65536+g*256+b in 0-255, that colour's strength 0-1)
static var towns:=PackedVector4Array()

## How far a place of `population` farms (km): a camp's gardens reach about
## a kilometre, a village's fields two, a market town's four or five, a
## great city's hinterland ten or more, as field systems round settlements
## of those sizes did before railways.
static func worked_radius_km(population:float)->float:
	return clampf(0.8+0.05*sqrt(maxf(population,0.0)),1.0,14.0)

## How far a place of `population` is built over (km): a hamlet's huts a
## couple of hundred metres, a market town's streets about 700 m, a great
## pre-modern city a kilometre and a half to two and a half.
static func built_radius_km(population:float)->float:
	return clampf(0.045*pow(maxf(population,1.0),0.33),0.08,2.5)

static func pack_colour(colour:Color)->float:
	return float(roundi(clampf(colour.r,0,1)*255.0)*65536+roundi(clampf(colour.g,0,1)*255.0)*256+roundi(clampf(colour.b,0,1)*255.0))

## The places as parallel arrays, nearest `view` first: [places, towns].
static func gather(view:Vector2)->Array:
	var found:Array=[]
	var walled_home:=MilitaryCampaign!=null and int(MilitaryCampaign.settlement_defense.get("stage",0))>=3
	for settlement in GameState.player_settlements:
		if not settlement is Dictionary:continue
		var at:Variant=settlement.get("position",Vector2.ZERO)
		if not at is Vector2 or (at as Vector2)==Vector2.ZERO:continue
		var population:=1.0
		if SettlementModel.has_method("_settlement_population"):population=float(SettlementModel.call("_settlement_population",settlement))
		var walled:=walled_home and bool(settlement.get("primary",false))
		found.append([Vector4((at as Vector2).x,(at as Vector2).y,worked_radius_km(population),0.0),Vector4(built_radius_km(population),1.0 if walled else 0.0,0.0,0.0)])
	if found.is_empty() and GameState.settlement_site_committed:
		var home:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
		var people:=float(GameState.population_total)
		found.append([Vector4(home.x,home.y,worked_radius_km(people),0.0),Vector4(built_radius_km(people),0.0,0.0,0.0)])
	if CivilizationSystem.city_intelligence!=null:
		for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false,view,REACH_KM):
			# A town of ours already came from our own settlements.
			if String(city.get("controller",""))=="player" and OWNERSHIP.player_hold(String(city.get("city_id",""))).is_empty():continue
			var location:Dictionary=city.get("position",{})
			var fields:Dictionary=city.get("fields",{})
			var estimate:Dictionary=fields.get("population",{})
			var population:=(float(estimate.get("low",0.0))+float(estimate.get("high",0.0)))*0.5
			if population<=0.0:population=800.0
			var fortification:Dictionary=fields.get("fortification",{})
			var walled:=(float(fortification.get("low",0.0))+float(fortification.get("high",0.0)))*0.5>=0.35
			var status:Dictionary=OWNERSHIP.status(city)
			var ruined:=String(status.get("kind",""))=="ruined"
			var accent:Color=status.get("accent",Color(0,0,0,0))
			var flags:=(1.0 if walled else 0.0)+(2.0 if ruined else 0.0)
			found.append([Vector4(float(location.get("x",0.0)),float(location.get("z",0.0)),worked_radius_km(population),1.0),Vector4(built_radius_km(population),flags,pack_colour(accent),accent.a)])
	found.sort_custom(func(a:Array,b:Array)->bool:return Vector2(a[0].x,a[0].y).distance_squared_to(view)<Vector2(b[0].x,b[0].y).distance_squared_to(view))
	if found.size()>MAX_PLACES:found.resize(MAX_PLACES)
	var place_list:=PackedVector4Array()
	var town_list:=PackedVector4Array()
	for entry in found:
		place_list.append(entry[0]);town_list.append(entry[1])
	return [place_list,town_list]

## Sends the places to the terrain's materials every two seconds (a few
## uniforms, so a material made since picks them up), or at once when the
## view has moved far.
static func refresh(view:Vector2,materials:Array)->void:
	var now:=Time.get_ticks_msec()
	var moved:=_view_anchor==Vector2.INF or view.distance_to(_view_anchor)>REACH_KM*0.25
	if not moved and now-_checked_at<REFRESH_MSEC:return
	_checked_at=now
	_view_anchor=view
	var gathered:=gather(view)
	places=gathered[0]
	towns=gathered[1]
	push(materials)

## Binds the current places to these materials (new ones too).
static func push(materials:Array)->void:
	var padded:=places.duplicate()
	var padded_towns:=towns.duplicate()
	while padded.size()<MAX_PLACES:padded.append(Vector4.ZERO)
	while padded_towns.size()<MAX_PLACES:padded_towns.append(Vector4.ZERO)
	for material in materials:
		if material is ShaderMaterial:
			(material as ShaderMaterial).set_shader_parameter("chart_places",padded)
			(material as ShaderMaterial).set_shader_parameter("chart_towns",padded_towns)
			(material as ShaderMaterial).set_shader_parameter("chart_place_count",places.size())
