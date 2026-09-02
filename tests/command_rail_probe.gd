extends Node
## Probes the Command Rail HUD shell: rail buttons, time pill speed control,
## KPI strip, decision queue bounds and dismissal, and toolbar repositioning.

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
var failures:Array[String]=[]


func _ready()->void:
	GameState.reset_for_new_world(551188)
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
	var hud:Control=terrain.hud
	_expect(hud!=null,"CommandRailHud missing")
	if hud==null:
		_finish()
		return
	var viewport_rect:Rect2=terrain.get_viewport().get_visible_rect()

	# Rail: six sections + menu, all inside the viewport.
	for rail_name in ["RailSettlement","RailEconomy","RailCivilization","RailInquiry","RailWorld","RailMilitary","RailMenu"]:
		var button:=hud.find_child(rail_name,true,false) as Control
		_expect(button!=null,"missing %s" % rail_name)
		if button:
			var rect:Rect2=button.get_global_rect()
			_expect(viewport_rect.encloses(rect),"%s outside viewport: %s" % [rail_name,rect])

	# Speed: keys 0-5 map onto the pill selection through _set_game_speed.
	terrain._set_game_speed(2.0)
	hud.refresh()
	_expect(int(terrain.game_speed)==2,"game speed did not change")
	terrain._set_game_speed(0.0)
	hud.refresh()

	# Decision queue: bounded to three cards regardless of inbox size.
	for index in 6:
		GameState.council_inbox.append({
			"id":"probe_item_%d" % index,"advisor":"Probe Advisor","office":"Probe Office",
			"topic":"probe","act":{"type":"warn"},"text":"Probe decision %d" % index,
			"urgency":0.8,"day":1,"status":"unread","severity":"warning",
			"responses":[{"label":"Act","effect":"probe"}]
		})
	hud._queue_signature=""
	hud.refresh()
	await get_tree().process_frame
	var queue:Control=hud.find_child("DecisionQueue",true,false)
	_expect(queue!=null,"decision queue missing")
	var cards:=0
	if queue:
		for child in queue.get_children():
			if child is PanelContainer: cards+=1
		_expect(cards<=3,"decision queue exceeded three cards: %d" % cards)
		_expect(cards>0,"decision queue showed no cards despite pending decisions")
		_expect(viewport_rect.encloses((queue as Control).get_global_rect()),"decision queue outside viewport")

	# Dismissal removes a card but keeps the inbox record.
	var inbox_before:int=GameState.council_inbox.size()
	hud.dismiss_alert("probe_item_0")
	await get_tree().process_frame
	_expect(GameState.council_inbox.size()==inbox_before,"dismiss deleted a council record")
	_expect(hud.dismissed_alert_ids.has("probe_item_0"),"dismissed id was not tracked")

	# Dismissing down to an empty queue must actually clear the rendered cards
	# (regression: the stale-signature sentinel collided with the empty state).
	for item_variant in GameState.council_inbox.duplicate():
		hud.dismiss_alert(String((item_variant as Dictionary).get("id","")))
	await get_tree().process_frame
	var stale_cards:=0
	for child in queue.get_children():
		if child is PanelContainer: stale_cards+=1
	_expect(stale_cards==0,"dismissing every decision left %d stale cards rendered" % stale_cards)

	# A deferred food condition merges silently instead of resurfacing…
	terrain._generate_leader_candidates("Steward")
	AdvisorSystem.appoint(String(terrain.leader_candidates[0].name),"Steward")
	var food_item:Dictionary=AdvisorSystem.generate_consequence_item({"condition_id":"probe_food_shortage","title":"Shortage Forecast","description":"Stores fail soon.","domain":"food","severity":"warning"})
	var food_id:=String(food_item.get("id",""))
	hud.refresh()
	await get_tree().process_frame
	hud.dismiss_alert(food_id)
	var remerge:Dictionary=AdvisorSystem.generate_consequence_item({"condition_id":"probe_food_shortage","title":"Shortage Forecast","description":"Stores still fail soon.","domain":"food","severity":"warning"})
	_expect(remerge.is_empty(),"a deferred condition resurfaced without escalating")
	_expect(AdvisorSystem.council_decision_items(9,false).is_empty() or String((AdvisorSystem.council_decision_items(9,false)[0] as Dictionary).get("id",""))!=food_id,"deferred decision stayed in the queue")
	# …but escalation reopens it.
	var escalated:Dictionary=AdvisorSystem.generate_consequence_item({"condition_id":"probe_food_shortage","title":"Shortage Forecast","description":"Stores fail imminently.","domain":"food","severity":"critical"})
	_expect(not escalated.is_empty() and String(escalated.get("status",""))=="unread","an escalated condition did not reopen the deferred decision")
	_expect(AdvisorSystem.merged_report_items(8).size()>=0,"merged report accessor failed")
	AdvisorSystem.defer_council_item(food_id)

	# Toolbar sits inside the viewport and recenters when a section opens.
	var toolbar:Control=hud.find_child("MapToolbar",true,false)
	_expect(toolbar!=null,"map toolbar missing")
	if toolbar:
		_expect(viewport_rect.encloses(toolbar.get_global_rect()),"toolbar outside viewport")
		var closed_x:float=toolbar.position.x
		hud.set_active_section("settlement")
		var open_x:float=toolbar.position.x
		hud.set_active_section("")
		_expect(open_x>closed_x,"toolbar did not shift right for the open dock")

	# Council dock: real order input wired to the pronouncement pipeline.
	terrain._on_hud_section_requested("civ",2)
	await get_tree().process_frame
	var order_input:=hud.find_child("SovereignOrderInput",true,false) as LineEdit
	_expect(order_input!=null,"council dock did not expose the sovereign order input")
	if order_input:
		var orders_before:int=GameState.sovereign_orders.size()
		order_input.text="Ration the stores for the cold season"
		terrain._issue_freeform_order(order_input)
		_expect(GameState.sovereign_orders.size()==orders_before+1,"dock order input did not record a pronouncement")
	terrain._on_hud_section_requested("",0)
	await get_tree().process_frame

	# Inquiry dock: attention +/- reallocates emphasis.
	terrain._on_hud_section_requested("inquiry",0)
	await get_tree().process_frame
	var nutrition_before:int=int(GameState.research_allocations.get("nutrition",0))
	terrain._change_research_domain_allocation("nutrition",1)
	_expect(int(GameState.research_allocations.get("nutrition",0))==nutrition_before+1,"inquiry attention step did not change the allocation")
	terrain._change_research_domain_allocation("nutrition",-1)
	terrain._on_hud_section_requested("",0)
	await get_tree().process_frame

	# Government appointments: office rows open the appointment detail and
	# commissioning actually fills the office.
	terrain._on_hud_section_requested("civ",1)
	await get_tree().process_frame
	GameState.leadership_positions.erase("Steward")
	var appointments=preload("res://scripts/hud/content/dock_detail_appointments.gd").new(terrain,hud,"Steward")
	hud.open_detail(appointments)
	await get_tree().process_frame
	_expect(hud.detail_dock.visible,"appointment detail did not open")
	_expect(terrain.leader_candidates.size()>0,"no candidate institutions were generated")
	if terrain.leader_candidates.size()>0:
		appointments._commission(String(terrain.leader_candidates[0].name))
		_expect(GameState.leadership_positions.has("Steward"),"commissioning did not fill the Steward office")
	hud.close_detail()
	terrain._on_hud_section_requested("",0)
	await get_tree().process_frame

	# Army builds: adjusting and training a build reaches the campaign.
	terrain._on_hud_section_requested("military",1)
	await get_tree().process_frame
	var build_snapshot:Dictionary=MilitaryCampaign.army_template_snapshot()
	_expect((build_snapshot.templates as Array).size()>0,"no default army build exists")
	var build_id:int=int((build_snapshot.templates as Array)[0].template_id)
	var default_target:int=int((build_snapshot.templates as Array)[0].required_total)
	var capacity:=MilitaryCampaign.recruitment_capacity()
	_expect(default_target<=capacity,"default build target %d exceeds mobilization capacity %d" % [default_target,capacity])
	var shrink:Dictionary=MilitaryCampaign.adjust_template_entry(build_id,"levy","improvised",-default_target)
	_expect(bool(shrink.get("ok",false)),"could not shrink the army build")
	var adjust:Dictionary=MilitaryCampaign.adjust_template_entry(build_id,"levy","improvised",capacity+10)
	_expect(bool(adjust.get("ok",false)),"could not adjust the army build")
	var adjusted_total:=0
	for entry_variant in ((MilitaryCampaign.army_template_snapshot().templates as Array)[0].entries as Array):
		adjusted_total+=int((entry_variant as Dictionary).get("count",0))
	_expect(adjusted_total==capacity,"build target %d was not clamped to mobilization capacity %d" % [adjusted_total,capacity])
	terrain._on_hud_section_requested("",0)
	await get_tree().process_frame

	# Landmark detail: opening a charted landmark's record shows the detail dock
	# (illustration falls back to text until the plate is imported).
	CivilizationSystem.landmarks.append({"id":"landmark_probe","name":"The Grey Scarp","kind":"cliffs","feature_id":"scarp_wall","myth":"Probe myth line.","position":{"x":0.0,"z":0.0},"discovered_day":1,"description":"Probe survey line."})
	terrain._open_landmark_detail(CivilizationSystem.landmarks[CivilizationSystem.landmarks.size()-1])
	await get_tree().process_frame
	_expect(terrain.hud.detail_dock.visible,"landmark detail dock did not open")
	_expect(terrain.hud.handle_escape(),"escape did not consume with landmark detail open")
	_expect(not terrain.hud.detail_dock.visible,"escape did not close the landmark detail dock")
	await get_tree().process_frame

	# Detail dock: opens beside the primary dock; Esc closes detail first.
	terrain._on_hud_section_requested("settlement",2)
	await get_tree().process_frame
	terrain.hud.open_detail(preload("res://scripts/hud/content/dock_detail_population_ledger.gd").new(terrain,terrain.hud))
	await get_tree().process_frame
	_expect(terrain.hud.detail_dock.visible,"detail dock did not open")
	_expect(terrain.hud.detail_dock.position.x>terrain.hud.dock.position.x,"detail dock is not beside the primary dock")
	_expect(terrain.hud.handle_escape(),"escape did not consume with docks open")
	_expect(not terrain.hud.detail_dock.visible and terrain.hud.dock.visible,"escape did not close the detail dock first")
	_expect(terrain.hud.handle_escape(),"escape did not consume with the primary dock open")
	_expect(not terrain.hud.dock.visible,"escape did not close the primary dock")
	await get_tree().process_frame

	# KPI strip inside viewport with all five chips.
	for chip_name in ["KpiPopulation","KpiFood","KpiWater","KpiHealth","KpiLabor"]:
		var chip:=hud.find_child(chip_name,true,false) as Control
		_expect(chip!=null,"missing %s" % chip_name)
		if chip:
			_expect(viewport_rect.encloses(chip.get_global_rect()),"%s outside viewport" % chip_name)

	_finish()


func _finish()->void:
	if failures.is_empty():
		print("COMMAND_RAIL_PROBE PASS")
		get_tree().quit(0)
	else:
		for failure in failures: push_error("COMMAND_RAIL_PROBE "+failure)
		get_tree().quit(1)


func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
