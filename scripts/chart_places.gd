extends RefCounted
## The places the chart draws worked land round (codex/map-beauty): every
## town of ours and every stranger's town the people know, nearest the view
## first, with how far its fields and pastures reach. The terrain shader
## (map_chart.gdshaderinc mc_farmland) hatches the fields and dots the
## pasture inside that reach at the chart views. Visual only: it reads the
## settlements and the city reports, and changes nothing.

const MAX_PLACES:=24
const REFRESH_MSEC:=2000
## Places farther than this from the view are not sent (km).
const REACH_KM:=900.0

static var _checked_at:=-REFRESH_MSEC
static var _view_anchor:=Vector2.INF
static var places:=PackedVector4Array()

## How far a place of `population` farms (km): a camp's gardens reach about
## a kilometre, a village's fields two, a market town's four or five, a
## great city's hinterland ten or more, as field systems round settlements
## of those sizes did before railways.
static func worked_radius_km(population:float)->float:
	return clampf(0.8+0.05*sqrt(maxf(population,0.0)),1.0,14.0)

## The places as (x, z, worked radius km, 0 ours / 1 a stranger's).
static func gather(view:Vector2)->PackedVector4Array:
	var found:Array=[]
	for settlement in GameState.player_settlements:
		if not settlement is Dictionary:continue
		var at:Variant=settlement.get("position",Vector2.ZERO)
		if not at is Vector2 or (at as Vector2)==Vector2.ZERO:continue
		var population:=1.0
		if SettlementModel.has_method("_settlement_population"):population=float(SettlementModel.call("_settlement_population",settlement))
		found.append(Vector4((at as Vector2).x,(at as Vector2).y,worked_radius_km(population),0.0))
	if found.is_empty() and GameState.settlement_site_committed:
		var home:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
		found.append(Vector4(home.x,home.y,worked_radius_km(float(GameState.population_total)),0.0))
	if CivilizationSystem.city_intelligence!=null:
		for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false,view,REACH_KM):
			if String(city.get("controller",""))=="player":continue
			var location:Dictionary=city.get("position",{})
			var estimate:Dictionary=(city.get("fields",{}) as Dictionary).get("population",{})
			var population:=(float(estimate.get("low",0.0))+float(estimate.get("high",0.0)))*0.5
			if population<=0.0:population=800.0
			found.append(Vector4(float(location.get("x",0.0)),float(location.get("z",0.0)),worked_radius_km(population),1.0))
	found.sort_custom(func(a:Vector4,b:Vector4)->bool:return Vector2(a.x,a.y).distance_squared_to(view)<Vector2(b.x,b.y).distance_squared_to(view))
	if found.size()>MAX_PLACES:found.resize(MAX_PLACES)
	return PackedVector4Array(found)

## Sends the places to the terrain's materials every two seconds (a few
## uniforms, so a material made since picks them up), or at once when the
## view has moved far.
static func refresh(view:Vector2,materials:Array)->void:
	var now:=Time.get_ticks_msec()
	var moved:=_view_anchor==Vector2.INF or view.distance_to(_view_anchor)>REACH_KM*0.25
	if not moved and now-_checked_at<REFRESH_MSEC:return
	_checked_at=now
	_view_anchor=view
	places=gather(view)
	push(materials)

## Binds the current places to these materials (new ones too).
static func push(materials:Array)->void:
	var padded:=places.duplicate()
	while padded.size()<MAX_PLACES:padded.append(Vector4.ZERO)
	for material in materials:
		if material is ShaderMaterial:
			(material as ShaderMaterial).set_shader_parameter("chart_places",padded)
			(material as ShaderMaterial).set_shader_parameter("chart_place_count",places.size())
