extends RefCounted
## Read-only presentation snapshot. This never establishes plots, converts
## buildings, or remembers placement back into the settlement ledger.
const ROLES:Array[String]=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
const Keys=preload("res://scripts/settlement_visual_keys.gd")
const USES:Dictionary={
	"Food":["field","pasture"],"Survey":["transport"],
	"Extraction":["dirty_industry"],"Construction":[],"Crafting":["workshop"],
	"Logistics":["storage","market","transport"],"Knowledge":["sacred","civic"],
	"Administration":["civic","communal"],"Defense":["defense"]}

static func snapshot(context:Dictionary)->Dictionary:
	var source:Dictionary={"settlement_plots":GameState.settlement_plots,"settlement_routes":GameState.settlement_routes}
	var origin:Vector3=GameState.settlement_founded_at
	var id:=String(context.get("settlement_id",""))
	if not id.is_empty():
		# Direct record lookup is read-only; selected_settlement() ensures state.
		var record:Dictionary=SettlementModel.settlement_record(id)
		if not record.is_empty() and not bool(record.get("primary",false)):
			source=record.get("local_resources",{})
			var at:Vector2=record.get("position",Vector2.ZERO)
			origin=Vector3(at.x,0,at.y)
	var plots:Array[Dictionary]=[];var routes:Array[Dictionary]=[]
	plots.assign((context.get("plots",source.get("settlement_plots",[])) as Array).duplicate(true))
	routes.assign((context.get("routes",source.get("settlement_routes",[])) as Array).duplicate(true))
	return {"plots":plots,"routes":routes,"origin":context.get("origin",origin),"settlement_id":id}

static func signature(data:Dictionary)->int:
	# Calendar/population changes cannot silently upgrade recorded architecture.
	var appearances:Array=[]
	for plot:Dictionary in data.plots:appearances.append(Keys.appearance(plot))
	for route:Dictionary in data.routes:appearances.append(Keys.route(route))
	return hash([Keys.placement(data.plots,data.routes),appearances,data.origin,data.settlement_id])

static func bounds(plots:Array[Dictionary],routes:Array[Dictionary])->Rect2:
	var points:=PackedVector2Array()
	for plot in plots:
		if String(plot.get("status","active"))=="reclaimed":continue
		points.append_array(plot.get("polygon",PackedVector2Array()))
	if points.is_empty():
		for route in routes:points.append_array(route.get("points",PackedVector2Array()))
	if points.is_empty():return Rect2(Vector2(-.025,-.025),Vector2(.05,.05))
	var result:=Rect2(points[0],Vector2.ZERO)
	for point in points:result=result.expand(point)
	return result.grow(.004)

static func zones(plots:Array[Dictionary],routes:Array[Dictionary])->Dictionary:
	var result:Dictionary={};var shared:Array[Dictionary]=[]
	for plot in plots:
		if String(plot.get("status","active")) in ["vacant","reclaimed","ruin"]:continue
		if String(plot.get("land_use","")) in ["communal","civic","market","workshop"]:shared.append(plot)
	if shared.is_empty():
		for plot in plots:
			if String(plot.get("status","active")) not in ["reclaimed","ruin"]:shared.append(plot)
	for role in ROLES:
		var matching:Array[Dictionary]=[]
		for plot in plots:
			if String(plot.get("status","active")) in ["vacant","reclaimed","ruin"]:continue
			var building:=String(plot.get("status",""))=="under_construction" or not (plot.get("fabric_job",{}) as Dictionary).is_empty()
			if (role=="Construction" and building) or String(plot.get("land_use","")) in USES[role]:matching.append(plot)
		var physical:=not matching.is_empty()
		# A role without a dedicated parcel belongs to existing shared working
		# ground. It does not manufacture a mine, school, barracks, or farm.
		if matching.is_empty() and not shared.is_empty():matching.append(shared[ROLES.find(role)%shared.size()])
		var ids:Array[int]=[];var polygons:Array[PackedVector2Array]=[];var center:=Vector2.ZERO
		for plot in matching:
			ids.append(int(plot.get("id",0)))
		# Focus a real parcel, rather than averaging distant workshops into an
		# empty point between them. All matching ids remain available to the UI.
		if not matching.is_empty():
			var principal:Dictionary=matching[0]
			center=Vector2(principal.get("centroid",Vector2.ZERO))
			var polygon:PackedVector2Array=principal.get("polygon",PackedVector2Array())
			if polygon.size()>=3:polygons.append(polygon)
		var area:=Rect2(center-Vector2.ONE*.012,Vector2.ONE*.024)
		for polygon in polygons:
			for point in polygon:area=area.expand(point)
		result[role]={"center":center,"bounds":area,"plot_ids":ids,"polygons":polygons,"physical":physical,"source":"Dedicated work ground" if physical else "Shared work ground"}
	return result
