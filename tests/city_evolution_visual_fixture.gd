extends RefCounted
## Prepared visual history, not a demographic simulation or a save. Each step
## adopts only catalogue-eligible construction knowledge and uses the live fabric
## conversion to produce the records consumed by the actual map renderer.
const Renderer=preload("res://scripts/local_terrain.gd")
const Early=preload("res://scripts/early_settlement_visual.gd")
const Kit=preload("res://scripts/settlement_architecture_kit.gd")
class FlatRenderer extends Renderer:
	func _ready()->void:pass
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _close_surface_height_at(_x:float,_z:float)->float:return 0.0
	func _settlement_stage_land_at(_point:Vector2)->bool:return true
	func _terrain_contour_angle(_point:Vector2,fallback:float)->float:return fallback

static func initialize()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(625114)
	SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	for node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:node.set_process(false)
	GameState.settlement_name="Visual history fixture"
	GameState.settlement_founded_day=0
	GameState.settlement_founded_at=Vector3.ZERO

static func plot(id:int,at:Vector2=Vector2.ZERO)->Dictionary:
	var corners:=PackedVector2Array()
	for point in [Vector2(-.014,-.016),Vector2(.014,-.016),Vector2(.014,.016),Vector2(-.014,.016)]:corners.append(at+point)
	return {"id":id,"seed":id+11,"land_use":"mixed_household","form":"portable_shelter_cluster","material_family":"organic","roof_plan":"timber_ridge","fabric_generation":0,"storeys":1,"status":"active","condition":.94,"area_ha":.0896,"roof_coverage":.18,"resident_count":12,"resident_capacity":16,"service_access":.8,"prosperity":.6,"created_day":0,"polygon":corners,"centroid":at,"frontage_route_id":1,"damage":{},"material_mix":{},"supply_provenance":{}}

static func snapshot(year:int)->Dictionary:
	GameState.elapsed_days=year*365.0
	GameState.known_discoveries.clear();GameState.discovery_adoption.clear()
	# Dates select a prepared knowledge sample only; runtime appearance is then
	# derived from that actual sample, never from a settlement-age threshold.
	for entry:Dictionary in DiscoverySystem.catalog:
		if float(entry.get("earliest_year",INF))<=year:
			GameState.known_discoveries.append(String(entry.id));GameState.discovery_adoption[String(entry.id)]=1.0
	DiscoverySystem.refresh_operating_effects()
	GameState.ensure_population_total(12000)
	for role in ["Construction","Crafting","Logistics","Administration"]:GameState.population_allocations[role]=1000
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits","Open Work Area"]
	GameState.settlement_nuclei=[{"id":1,"active":true},{"id":2,"active":true}]
	GameState.simulation_metrics={"labor_efficiency":.9,"logistics":.9}
	GameState.resource_stockpiles={"Clay":10000.0,"Stone":10000.0}
	var tier:=SettlementModel._supported_fabric_tier(int(GameState.elapsed_days))
	var plots:Array[Dictionary]=[];var routes:Array[Dictionary]=[]
	var count:=4+year/100
	for row in ceili(count/6.0):
		routes.append({"id":row+1,"active":true,"kind":"street","hierarchy":"lane","surface_tier":mini(tier,5),"width_m":4.0 if tier>=11 else 2.0,"condition":.9,"traffic":.8,"points":PackedVector2Array([Vector2(-.02,row*.043+.022),Vector2(.20,row*.043+.022)])})
	for index in count:
		# Persistent ids can have gaps after plots are retired. This deliberately
		# traverses the detailed mesh budget without increasing its allocation.
		var p:=plot(index*4+1,Vector2((index%6)*.035,(index/6)*.043))
		p.seed=37+index*11
		p.frontage_route_id=index/6+1
		if index>3 and index%7==4:p.land_use="workshop"
		elif index>3 and index%7==5:p.land_use="storage"
		elif index>3 and index%7==6:p.land_use="civic"
		var inherited_tier:=mini(tier,7) if index%9==8 else tier
		for generation in range(1,inherited_tier+1):
			var events:Array[Dictionary]=[]
			SettlementModel._apply_fabric_upgrade({"plot":p,"next_tier":generation,"cost":SettlementModel._fabric_upgrade_cost(p,generation)},year*365,events)
		plots.append(p)
	GameState.settlement_plots=plots;GameState.settlement_routes=routes
	var capacity:=0
	for p in plots:capacity+=int(p.resident_capacity)
	return {"year":year,"tier":tier,"plots":plots,"routes":routes,"capacity":capacity}

static func render(renderer:Node3D,snapshot:Dictionary,parent:Node3D)->Dictionary:
	GameState.settlement_plots=snapshot.plots;GameState.settlement_routes=snapshot.routes
	var before:=var_to_bytes([GameState.population_total,GameState.population_exact,GameState.housing_capacity])
	renderer._create_persistent_settlement_routes(Vector3.ZERO,snapshot.routes,parent)
	renderer._create_plot_fabric(Vector3.ZERO,snapshot.plots,0,parent)
	assert(before==var_to_bytes([GameState.population_total,GameState.population_exact,GameState.housing_capacity]))
	var instances:=0;var roof_vertices:=0;var highest:=0.0
	for child in parent.get_children():
		if child is MultiMeshInstance3D and not String(child.name).begins_with("GroundShadow"):
			instances+=child.multimesh.instance_count
			highest=maxf(highest,child.multimesh.mesh.get_aabb().end.y*.001)
		if child is MeshInstance3D and String(child.name)=="PersistentRoofFabric":roof_vertices=child.mesh.surface_get_array_len(0)
	return {"year":snapshot.year,"tier":snapshot.tier,"plots":snapshot.plots.size(),"capacity":snapshot.capacity,"detailed_buildings":instances,"fallback_roof_vertices":roof_vertices,"height_m":highest*1000.0}
