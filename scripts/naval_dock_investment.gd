extends RefCounted
const Dock=preload("res://scripts/naval_dock_service.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")

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
		elif not Dock.building(port):bill={"Timber":10.0,"Rope Coils":1.0}
		for item:String in bill:needs[item]=float(needs.get(item,0))+float(bill[item])
	return needs

static func install_supplied()->void:
	if WorldSimulation.state.effective_workers("Construction",true)<4:return
	for port:Dictionary in eligible_ports():
		if not port.has("dock_service"):WorldSimulation.military.joint_operations.build_dock(int(port.id))

static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.resource_settlement_id.is_empty():return {}
	install_supplied()
	var needs:=targets()
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
		var local:Dictionary=WorldSimulation.settlements.with_city_resources(String(city.id),func()->Dictionary:
			return WorldSimulation.settlements.with_local_population(func()->Dictionary:
				install_supplied()
				var result:=targets()
				for item:String in result:result[item]=maxf(0,float(result[item])-float(state.resource_stockpiles.get(item,0))-WorldSimulation.settlements._city_incoming(String(city.id),item))
				return result))
		for item:String in local:needs[item]=float(needs.get(item,0))+float(local[item])
	for item:String in needs:
		if float(state.resource_stockpiles.get(item,0))>=float(needs[item]):continue
		var order:=Supply.supply(item,ceili(float(needs[item])),{})
		if not order.is_empty():return order
	return {}
