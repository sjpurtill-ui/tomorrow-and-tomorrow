extends RefCounted
const Dock=preload("res://scripts/naval_dock_service.gd")
## Access upkeep reserve: timber and a rope coil as raw materials and goods.
static var UPKEEP:=preload("res://scripts/goods_bills.gd").flatten({"Timber":10.0,"Rope Coils":1.0})

static func local_city()->String:
	var state=WorldSimulation.state
	if not state.resource_settlement_id.is_empty():return state.resource_settlement_id
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)):return String(city.id)
	return ""

static func eligible_ports()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var op=WorldSimulation.military.joint_operations
	if WorldSimulation.state.convoy_traveling or not WorldSimulation.state.settlement_site_committed:return result
	if not bool(WorldSimulation.military._knowledge_gate("dry_dock_services",.25).unlocked):return result
	for port:Dictionary in op.state.bases:
		if port.domain!="navy" or String(port.city_id)!=local_city() or not op.base_owned(port) or not op.base_ready(port):continue
		var useful:=false
		for force:Dictionary in op.state.forces:
			if int(force.base_id)==int(port.id) and Dock.handling_load(force)>0:useful=true;break
		if useful:result.append(port)
	return result

static func targets()->Dictionary:
	var needs:Dictionary={}
	for port:Dictionary in eligible_ports():
		var bill:Dictionary={}
		if not port.has("dock_service"):
			if WorldSimulation.state.effective_workers("Construction",true)<4:continue
			bill=Dock.BILL
		elif not Dock.building(port):bill=UPKEEP
		for item:String in bill:needs[item]=float(needs.get(item,0))+float(bill[item])
	return needs

static func install_supplied()->void:
	if WorldSimulation.state.effective_workers("Construction",true)<4:return
	for port:Dictionary in eligible_ports():
		if not port.has("dock_service"):WorldSimulation.military.joint_operations.build_dock(int(port.id))

## Builds supplied docks in every accessible city. Dock bills are raw
## materials and Civilian Goods moved by city trade (settlement_model reads
## targets()); no production order is placed, so this always returns {}.
static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.resource_settlement_id.is_empty():return {}
	install_supplied()
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
		WorldSimulation.settlements.with_city_resources(String(city.id),func()->void:
			WorldSimulation.settlements.with_local_population(func()->void:install_supplied()))
	return {}
