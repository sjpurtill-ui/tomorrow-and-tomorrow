extends Node
## Probes the scout gamble: dispatched parties genuinely complete within the
## bounded duration-scaled timing window, reports emit once each, and
## the status surfaces stay cheap enough for per-tick UI use.

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
var failures:Array[String]=[]
var reports_received:=0


func _ready()->void:
	GameState.reset_for_new_world(778899)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.select_founding_focus("provision")
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	if terrain.founding_focus_panel and is_instance_valid(terrain.founding_focus_panel): terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	await get_tree().process_frame
	CivilizationSystem.scout_report_returned.connect(func(_report:Dictionary)->void: reports_received+=1)

	GameState.resource_stockpiles["Food"]=maxf(2000.0,float(GameState.resource_stockpiles.get("Food",0.0)))
	var first:Dictionary=CivilizationSystem.dispatch_scouts(30)
	var second:Dictionary=CivilizationSystem.dispatch_scouts(30)
	_expect(bool(first.get("ok",false)),"first dispatch failed: %s" % first.get("error",""))
	_expect(bool(second.get("ok",false)) or CivilizationSystem.scout_missions.size()>=1,"second dispatch failed: %s" % second.get("error",""))
	var dispatched:=CivilizationSystem.scout_missions.size()
	for mission_variant in CivilizationSystem.scout_missions:
		var mission:Dictionary=mission_variant
		var planned:=int(mission.get("return_day",0))
		var actual:=int(mission.get("actual_return_day",planned))
		var late_cap:=ceili(float(mission.get("duration_days",30))*0.32)
		_expect(actual<=planned+late_cap,"late variance exceeds duration-scaled cap (planned %d, actual %d, cap %d)" % [planned,actual,late_cap])
		_expect(actual>=int(mission.get("start_day",0))+2,"actual return precedes minimum")

	# Advance day by day well past planned + cap; every party must complete.
	var start:=int(GameState.elapsed_days)
	for day in range(start+1,start+30+22+2):
		GameState.elapsed_days=float(day)
		CivilizationSystem.advance_to_day(day)
	_expect(CivilizationSystem.scout_missions.is_empty(),"%d of %d parties never completed" % [CivilizationSystem.scout_missions.size(),dispatched])
	var returned_reports:=0
	for report_variant in CivilizationSystem.scout_reports:
		returned_reports+=1
	_expect(returned_reports+CivilizationSystem._captured_player_scout_count()>0,"no report and no loss was recorded")
	_expect(reports_received<=dispatched,"reports emitted more than once per mission (%d for %d)" % [reports_received,dispatched])

	# New discovery lines exist and the cavalry gate resolves to a real,
	# researchable discovery instead of a permanent lock.
	for id in ["animal_taming","pack_animals","domesticated_mounts","mounted_scouts","hide_floats","river_craft","coastal_watercraft"]:
		_expect(not DiscoverySystem.discovery_definition(id).is_empty(),"missing discovery %s" % id)
	var progression_errors:Array=MilitaryCampaign.validate_military_progression()
	_expect(progression_errors.is_empty(),"military gates reference missing discoveries: %s" % str(progression_errors))
	var cavalry_gate:Dictionary=(MilitaryCampaign.military_capabilities().units as Dictionary).get("cavalry",{})
	_expect(String(cavalry_gate.get("discovery",""))=="domesticated_mounts","cavalry gate is '%s'" % cavalry_gate.get("discovery"))
	_expect(not bool(cavalry_gate.get("unlocked",true)),"cavalry unlocked without mounts")

	# A dictated heading biases the outward route.
	GameState.resource_stockpiles["Food"]=5000.0
	var directed:Dictionary=CivilizationSystem.dispatch_scouts(30,"open_world","north")
	_expect(bool(directed.get("ok",false)),"directed dispatch failed: %s" % directed.get("error",""))
	if bool(directed.get("ok",false)):
		var mission:Dictionary=CivilizationSystem.scout_missions[CivilizationSystem.scout_missions.size()-1]
		var route:Array=mission.get("route",[])
		var last:Dictionary=route[route.size()-1]
		var delta:=Vector2(float(last.get("x",0.0)),float(last.get("z",0.0)))-CivilizationSystem.player_world_origin
		_expect(delta.y<0.0,"north-directed route ended south of home (%s)" % delta)
		_expect(String(mission.get("ordered_heading",""))=="north","north order was not retained on mission")
		_expect(String(mission.get("planned_heading",""))=="north","north order left its compass sector (%s)" % mission.get("planned_heading",""))
		terrain._refresh_player_scout_route_markers()
		var route_marker:Node3D=terrain.player_scout_route_markers.get(str(mission.get("mission_id","")),null)
		_expect(route_marker!=null and is_instance_valid(route_marker),"active directed scout order has no map corridor")
		if route_marker and is_instance_valid(route_marker):
			var route_label:=route_marker.get_node_or_null("ScoutOrderLabel") as Label3D
			_expect(route_label!=null and "NORTH" in route_label.text,"scout corridor does not label the ordered heading")
	CivilizationSystem.scout_missions.clear()
	var recruiting:Dictionary=CivilizationSystem.dispatch_scouts(30,"recruit_people","east")
	_expect(bool(recruiting.get("ok",false)),"recruiting expedition ignored or rejected its heading: %s" % recruiting.get("error",""))
	if bool(recruiting.get("ok",false)):
		var recruit_mission:Dictionary=CivilizationSystem.scout_missions[CivilizationSystem.scout_missions.size()-1]
		_expect(String(recruit_mission.get("ordered_heading",""))=="east","recruiting expedition did not retain its east order")
		_expect(String(recruit_mission.get("planned_heading",""))=="east","recruiting expedition left its east compass sector")
	CivilizationSystem.scout_missions.clear()

	# Watercraft knowledge relaxes the water wall in bounded steps.
	_expect(CivilizationSystem._scout_water_crossing_allowance_km()==0.0,"water allowance nonzero without watercraft")

	# Long expeditions should have genuinely varied lateness. The old fixed
	# 21-day ceiling made almost every overdue annual expedition read as the
	# same "20 days late" outcome in the HUD.
	var late_values:Dictionary={}
	var longest_late:=0
	for mission_id in range(1,128):
		var variance:=CivilizationSystem._scout_timing_variance(365,mission_id,1000)
		if variance>0:
			late_values[variance]=true
			longest_late=maxi(longest_late,variance)
	_expect(late_values.size()>=12,"annual expedition lateness has too little variation: %s" % str(late_values.keys()))
	_expect(longest_late>21,"annual expedition lateness is still effectively capped near 20 days")
	_expect(
		CivilizationSystem._scout_timing_variance(365,41,1000)==CivilizationSystem._scout_timing_variance(365,41,1000),
		"scout timing is not deterministic for the same mission"
	)

	# Status surfaces must stay cheap: they run on UI ticks.
	var began:=Time.get_ticks_usec()
	for _index in 200: CivilizationSystem.exploration_status()
	var status_usec:=(Time.get_ticks_usec()-began)/200
	began=Time.get_ticks_usec()
	for _index in 200: CivilizationSystem.rumored_civilizations_snapshot()
	var rumor_usec:=(Time.get_ticks_usec()-began)/200
	began=Time.get_ticks_usec()
	for _index in 200: CivilizationSystem.nomad_sightings_snapshot()
	var nomad_usec:=(Time.get_ticks_usec()-began)/200
	print("SCOUT_GAMBLE_TIMING exploration_status=%dus rumors=%dus nomads=%dus" % [status_usec,rumor_usec,nomad_usec])
	_expect(status_usec<4000,"exploration_status is too slow for UI ticks (%dus)" % status_usec)
	_expect(rumor_usec<1000,"rumored snapshot too slow (%dus)" % rumor_usec)
	_expect(nomad_usec<1000,"nomad snapshot too slow (%dus)" % nomad_usec)
	_finish()


func _expect(condition:bool,message:String)->void:
	if not condition:
		failures.append(message)
		push_error("SCOUT_GAMBLE_PROBE %s" % message)


func _finish()->void:
	if failures.is_empty():
		print("SCOUT_GAMBLE_PROBE PASS")
		get_tree().quit(0)
	else:
		print("SCOUT_GAMBLE_PROBE FAIL (%d)" % failures.size())
		get_tree().quit(1)
