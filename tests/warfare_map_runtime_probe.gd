extends Node

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
const PRESENTATION:=preload("res://scripts/warfare_map_presentation.gd")
var failures:Array[String]=[]


func _ready()->void:
	GameState.reset_for_new_world(830177)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("security")
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	var origin:Vector3=terrain.world_start_position
	var army:=_army(1,origin)
	MilitaryCampaign.field_armies.clear(); MilitaryCampaign.field_armies.append(army)
	terrain.camera.size=320.0
	terrain._refresh_player_field_army_markers()
	_expect(terrain.player_field_army_markers.size()==1,"one aggregate army did not create exactly one marker")
	var marker:Node3D=terrain.player_field_army_markers.get("1",null)
	_expect(marker!=null and marker.visible,"regional player army marker is absent")
	if marker:
		var label:=marker.get_node("ArmyLabel") as Label3D
		_expect("YOU" in label.text and "8.0K" in label.text and "FORMING" in label.text,"player marker omits owner, aggregate strength, or readiness")
		terrain._apply_warfare_formation_view(marker,PRESENTATION.player_marker(army,320.0,true))
		_expect((marker.get_node("SelectedRing") as MeshInstance3D).visible,"selected army has no distinct selection halo")
		_expect(label.global_transform.basis.get_scale().is_equal_approx(Vector3.ONE),"army label inherits the regional marker scale")
	army["status"]="moving"
	army["destination_id"]="probe_objective"
	army["destination_name"]="North Crossing"
	army["destination_position"]={"x":origin.x+12.0,"z":origin.z+6.0}
	army["distance_total_km"]=13.4
	army["distance_remaining_km"]=9.2
	army["arrival_day"]=18
	MilitaryCampaign.field_armies[0]=army
	terrain._refresh_player_field_army_markers()
	_expect(terrain.player_field_army_paths.size()==1,"moving army has no bounded movement path")
	var path:Node3D=terrain.player_field_army_paths.get("1",null)
	_expect(path!=null and path.visible and path.get_node_or_null("MovementPath")!=null and path.get_node_or_null("MovementObjective")!=null,"movement path omits route or objective")
	if path:
		var objective_label:=path.get_node("MovementObjective/ObjectiveLabel") as Label3D
		_expect(objective_label.global_transform.basis.get_scale().is_equal_approx(Vector3.ONE),"movement objective label inherits the objective marker scale")
	var front:={"id":"front_probe","war_name":"War of North Crossing","opponent":"Cedar League","target_region_id":"probe_objective","target":"North Crossing","objective":"Take North Crossing","progress":0.36,"field_personnel":8000,"inbound_personnel":0,"occupation_personnel":0,"readiness":0.62,"supply":0.58}
	var destination:={"position":{"x":origin.x,"z":origin.z}}
	terrain._refresh_warfare_front_markers([PRESENTATION.front_marker(front,destination,320.0,true)])
	var front_marker:Node3D=terrain.warfare_front_markers.get("front_probe",null)
	_expect(front_marker!=null and front_marker.visible,"active engagement/front marker is absent at regional scale")
	if front_marker:
		_expect("BATTLE IN PROGRESS" in (front_marker.get_node("FrontLabel") as Label3D).text,"front marker does not distinguish an active local engagement")
		_expect((front_marker.get_node("FrontLabel") as Label3D).global_transform.basis.get_scale().is_equal_approx(Vector3.ONE),"front label inherits the regional front scale")
	terrain.camera.size=12_000.0
	terrain._refresh_player_field_army_markers()
	marker=terrain.player_field_army_markers.get("1",null)
	_expect(marker!=null and not marker.visible,"world scale still renders individual army detail")
	terrain._refresh_warfare_front_markers([PRESENTATION.front_marker(front,destination,12_000.0,true)])
	front_marker=terrain.warfare_front_markers.get("front_probe",null)
	_expect(front_marker!=null and front_marker.visible,"world scale lost aggregate strategic war state")
	if front_marker:
		_expect("WAR OF NORTH CROSSING" in (front_marker.get_node("FrontLabel") as Label3D).text,"world front marker omits the named war")
	MilitaryCampaign.field_armies.clear()
	for army_id in 24: MilitaryCampaign.field_armies.append(_army(army_id+1,origin))
	terrain.camera.size=320.0
	terrain._refresh_player_field_army_markers()
	_expect(terrain.player_field_army_markers.size()==PRESENTATION.MAX_PLAYER_MARKERS,"renderer exceeded the fixed player-army marker budget")
	var stacked_labels:=0
	for stacked_marker_variant in terrain.player_field_army_markers.values():
		var stacked_marker:=stacked_marker_variant as Node3D
		if stacked_marker and (stacked_marker.get_node("ArmyLabel") as Label3D).visible: stacked_labels+=1
	_expect(stacked_labels==1,"co-located regional armies did not collapse to one aggregate label")
	terrain.camera.size=7.99
	terrain._refresh_player_field_army_markers()
	for hidden_marker_variant in terrain.player_field_army_markers.values():
		_expect(not (hidden_marker_variant as Node3D).visible,"ground-scale view still renders a strategic army token")
	if not failures.is_empty():
		for failure in failures: push_error(failure)
		get_tree().quit(1)
		return
	print("WARFARE_MAP_RUNTIME_PROBE PASS markers=%d paths=%d fronts=%d" % [terrain.player_field_army_markers.size(),terrain.player_field_army_paths.size(),terrain.warfare_front_markers.size()])
	get_tree().quit(0)


func _army(army_id:int,origin:Vector3)->Dictionary:
	return {"army_id":army_id,"name":"%d Field Army" % army_id,"troops":8_000,"readiness":0.62,"supply_level":0.74,"status":"stationed","location_id":"player_home","location_name":"HOME","position":{"x":origin.x,"z":origin.z},"destination_id":"","destination_position":{},"distance_remaining_km":0.0,"arrival_day":-1,"formations":[]}


func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
