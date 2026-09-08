extends RefCounted
const C=preload("res://scripts/joint_force_catalog.gd")
var _owner:WeakRef
var op:RefCounted:
	get:return _owner.get_ref()
func _init(operations:RefCounted)->void:_owner=weakref(operations)

func personnel(owner:String)->int:
	var count=0
	for force:Dictionary in op.state.forces:
		if force.owner==owner:count+=op.crew(force)
	return count

func spend(owner:String,cost:float)->bool:
	var index=CivilizationSystem._civilization_index(owner)
	if index<0:return false
	var civ:Dictionary=CivilizationSystem.civilizations[index]
	if float(civ.get("military_stockpile",0))<cost:return false
	civ.military_stockpile=float(civ.get("military_stockpile",0))-cost
	return true

func advance(day:int)->void:
	if not op.state.has("rival_orders"):op.state.rival_orders={}
	for civ:Dictionary in CivilizationSystem.civilizations:
		var owner=String(civ.id)
		var known:Array=civ.get("discovery_profile",{}).get("technologies",[])
		if known.is_empty():continue
		for base:Dictionary in op.state.bases:
			if base.owner==owner and op.base_owned(base,owner) and not op.base_ready(base):base.construction_work=minf(float(base.required_work),float(base.construction_work)+maxf(0,float(civ.get("production",0)))*maxf(0,float(civ.get("population",0)))*.0002)
		var allowance=maxi(0,floori(float(civ.get("military_population",0))*.25)-personnel(owner))
		var orders:Dictionary=op.state.rival_orders.get(owner,{})
		if not orders.is_empty():
			var unit:Dictionary=C.UNITS[orders.unit]
			orders.progress=float(orders.progress)+maxf(0,float(civ.get("production",0)))*maxf(0,float(civ.get("population",0)))*.0005
			if float(orders.progress)>=float(unit.work_days) and allowance>=int(unit.crew):
				var groups={};groups[orders.unit]=1
				var id=op._id();var base:Dictionary=op.base(int(orders.base_id))
				if not base.is_empty() and op.state.forces.size()<op.MAX_FORCES:
					op.state.forces.append({"id":id,"owner":owner,"name":String(civ.name)+" "+String(unit.label),"domain":unit.domain,"base_id":base.id,"position":base.position.duplicate(true),"route":[],"units":groups,"authorized":groups.duplicate(true),"mission":"hold","region":{},"regions":[],"status":"Training crews","training":0.0,"condition":1.0,"experience":0.0,"efficiency":0.0,"auto_replace":false,"repair_threshold":.6,"fuel_used":0,"loss_fraction":0.0,"damage":0.0,"carrier_id":0,"fleet_id":id})
				op.state.rival_orders.erase(owner)
			else:op.state.rival_orders[owner]=orders
		if day%30!=abs(owner.hash())%30:continue
		var existing=0
		for force:Dictionary in op.state.forces:
			if force.owner==owner:existing+=1;_order(force,civ)
		if existing>=6 or op.state.rival_orders.has(owner):continue
		var candidates:Array[String]=[]
		for id:String in C.UNITS:
			var unit:Dictionary=C.UNITS[id]
			if unit.gate in known and int(unit.crew)<=allowance:candidates.append(id)
		if candidates.is_empty():continue
		# Spread across roles and eras using a stable cycle, without bypassing research.
		var chosen=candidates[(day/30+abs(owner.hash()))%candidates.size()]
		var unit:Dictionary=C.UNITS[chosen]
		var base=_base(civ,String(unit.domain))
		if base.is_empty():continue
		var cost=0.0
		for amount in unit.materials.values():cost+=float(amount)
		if spend(owner,cost):op.state.rival_orders[owner]={"unit":chosen,"base_id":base.id,"progress":0.0,"reserved_material_value":cost}

func _base(civ:Dictionary,domain:String)->Dictionary:
	for base:Dictionary in op.state.bases:
		if base.owner==civ.id and base.domain==domain:return base
	if op.state.bases.size()>=256:return {}
	var id=CivilizationSystem.city_intelligence.primary_id(String(civ.id))
	var city=CivilizationSystem.city_intelligence.site(id)
	if city.is_empty():return {}
	var position:Dictionary=city.position
	if domain=="navy":
		var site:Dictionary=op.coastal_site({"position":op.point(city)})
		if site.has("error"):return {}
		position=site.position
	if not spend(String(civ.id),80):return {}
	var record={"id":op._id(),"owner":String(civ.id),"city_id":id,"name":String(city.name)+( " Naval Base" if domain=="navy" else " Airfield"),"domain":domain,"position":position.duplicate(true),"capacity":100 if domain=="air" else 20,"condition":1.0,"construction_work":0.0,"required_work":30.0}
	op.state.bases.append(record)
	return record

func _order(force:Dictionary,civ:Dictionary)->void:
	var base:Dictionary=op.base(int(force.base_id))
	if not op.base_ready(base) or not op.base_owned(base,String(force.owner)):return
	if float(force.training)<1 or not force.get("route",[]).is_empty():return
	var target=op.point(base)
	if bool(civ.player_relation.at_war):
		var reports:Array=CivilizationSystem.city_intelligence.known_cities(String(civ.id),"player",false)
		if not reports.is_empty():target=op.point(reports[0])
	if op.point(base).distance_to(target)>op.range_km(force):return
	var region:Dictionary=force.get("region",{})
	if region.is_empty() or op.point(region).distance_to(target)>100:
		var created:Dictionary=op.create_region(String(force.domain),op.R.rectangle(target,minf(200,op.range_km(force)*.3)),String(force.name)+" operations",String(force.owner))
		if created.has("error"):return
		region=created.region
	var type_id=String(force.units.keys()[0]);var mission=String(C.UNITS[type_id].mission)
	if mission=="transport":mission="convoy_escort"
	if force.domain=="navy":
		var water:Dictionary=op.geography.sea_point(region,op.force_position(force))
		if water.is_empty():return
		force.mission_destination=water
		if mission!="strike_force":
			var route:Dictionary=op.set_route(force,preload("res://scripts/joint_geography.gd").unpack(water))
			if route.has("error"):return
	force.mission=mission;force.region=region;force.regions=[region.duplicate(true)]
