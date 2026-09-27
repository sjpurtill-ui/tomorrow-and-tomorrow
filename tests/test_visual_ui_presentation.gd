extends GdUnitTestSuite

const RENDERER:=preload("res://scripts/local_terrain.gd")
const COMMAND_RAIL:=preload("res://scripts/hud/command_rail_hud.gd")
const INQUIRY_CONTENT:=preload("res://scripts/hud/content/dock_content_inquiry.gd")
const CIVILIZATION_CONTENT:=preload("res://scripts/hud/content/dock_content_civilization.gd")
const SCOUT_REPORT_DETAIL:=preload("res://scripts/hud/content/dock_detail_scout_report.gd")
const DOCK_BLOCKS:=preload("res://scripts/hud/dock_blocks.gd")

class ImmediateRefreshSpy:
	extends Control
	var active_section:="civ"
	var immediate_refreshes:=0
	func request_immediate_dock_refresh()->void:
		immediate_refreshes+=1

var renderer:Node3D


func before_test()->void:
	GameState.reset_for_new_world(741991)
	renderer=auto_free(RENDERER.new())


func test_discovery_mask_paints_a_scout_corridor_without_filling_its_bounding_region()->void:
	var image:=Image.create(200,100,false,Image.FORMAT_L8)
	image.fill(Color.BLACK)
	renderer._paint_discovery_segment(image,Vector2(-8000.0,-4000.0),Vector2(8000.0,4000.0),18.0,200,100)
	# The route crosses the center, while the opposite corners of its enormous
	# bounding rectangle were never observed.
	assert_float(image.get_pixel(100,50).r).is_greater(0.80)
	assert_float(image.get_pixel(100,15).r).is_equal(0.0)
	assert_float(image.get_pixel(30,80).r).is_equal(0.0)


func test_compass_arrows_match_screen_direction()->void:
	assert_str(renderer._screen_direction_arrow(Vector2(0.0,-10.0))).is_equal("↑")
	assert_str(renderer._screen_direction_arrow(Vector2(10.0,0.0))).is_equal("→")
	assert_str(renderer._screen_direction_arrow(Vector2(0.0,10.0))).is_equal("↓")
	assert_str(renderer._screen_direction_arrow(Vector2(-10.0,0.0))).is_equal("←")


func test_research_actions_refresh_the_open_tab_without_navigation()->void:
	var hud:Variant=auto_free(COMMAND_RAIL.new())
	add_child(hud)
	var provider:Variant=INQUIRY_CONTENT.new(renderer,hud)
	hud.register_provider("inquiry",provider)
	hud.open_dock("inquiry",2)
	await get_tree().process_frame
	var disclosure_signature:int=hud._dock_signature.hash()
	provider._toggle_domain("knowledge")
	await get_tree().process_frame
	assert_int(hud._dock_signature.hash()).is_not_equal(disclosure_signature)
	var allocation_signature:int=hud._dock_signature.hash()
	renderer.hud=hud
	renderer._change_research_domain_allocation("nutrition",1)
	await get_tree().process_frame
	assert_int(hud._dock_signature.hash()).is_not_equal(allocation_signature)
	renderer.hud=null
	hud.queue_free()
	await get_tree().process_frame


func test_docks_offer_no_second_talk_box_outside_the_court()->void:
	# One court screen: a dock never builds its own reply or order field.
	var root:=auto_free(VBoxContainer.new()) as VBoxContainer
	DOCK_BLOCKS.render(root,[{"type":"conversation","leader_name":"Enna Yarrow","on_submit":func(_field:LineEdit)->void: pass},
		{"type":"order","on_submit":func(_field:LineEdit)->void: pass}])
	assert_int(root.find_children("*","LineEdit",true,false).size()).is_equal(0)


func test_culture_council_has_no_ai_settings_or_second_summon_list()->void:
	var hud:Variant=auto_free(COMMAND_RAIL.new())
	var provider:Variant=CIVILIZATION_CONTENT.new(renderer,hud)
	# AI configuration lives in the game menu; people are summoned in the court.
	assert_bool(provider.has_method("_interpreter_status_block")).is_false()
	assert_bool(provider.has_method("_summon_block")).is_false()
	var council:=JSON.stringify(provider.tab(1))
	assert_str(council).not_contains("DIRECTIVE INTERPRETER").not_contains("CONVERSATION SETTINGS").not_contains("SUMMON TO THE COURT")
	assert_str(council).contains("Open the court")


func test_recruitment_report_leads_with_people_choices_instead_of_generic_scout_copy()->void:
	var hud:Variant=auto_free(COMMAND_RAIL.new())
	var provider:Variant=SCOUT_REPORT_DETAIL.new(renderer,hud,{
		"day":550,"mission_kind":"recruit_people","target_label":"seek willing recruits",
		"personnel":8,"returned_personnel":8,"duration_days":90,"distance_km":46,"recruits":3,
		"recruitment_account":{
			"disposition":"some_joined","group":"two travelling households",
			"encountered":9,"joined":3,"declined":6,
			"summary":"Three younger adults accepted; six people chose to remain with their kin.",
			"reasons":["Shelter made the offer credible.","Family ties kept most of the group together."],
		},
	})
	var page:Dictionary=provider.tab(0)
	assert_str(String(page.brief.title)).is_equal("3 people chose to join")
	var serialized:=JSON.stringify(page)
	assert_str(serialized).contains("Who came back with them")
	assert_str(serialized).contains("Who they met")
	assert_str(serialized).contains("Why they decided")
	assert_str(serialized).contains("3 joined · 6 declined")
	assert_str(serialized).not_contains("found only ground")


func test_completed_civic_turn_bypasses_hover_guard_and_refreshes_immediately()->void:
	var spy:ImmediateRefreshSpy=auto_free(ImmediateRefreshSpy.new()) as ImmediateRefreshSpy
	add_child(spy)
	renderer.hud=spy
	renderer._refresh_council_dock()
	assert_int(spy.immediate_refreshes).is_equal(1)
	renderer.hud=null


func test_pending_civic_request_never_retains_transient_ui_nodes()->void:
	var transient_input:=LineEdit.new()
	add_child(transient_input)
	var order:=AdvisorSystem.begin_pronouncement("Support scholars.")
	var record:Dictionary=renderer._pending_civic_request_record(
		"Support scholars.",
		order,
		"settlement_test",
		42
	)
	assert_bool(record.has("input")).is_false()
	for value in record.values():
		assert_bool(value is Object).is_false()
	# Simulate a request submitted by the pre-fix UI, whose stored input was
	# destroyed by the immediate dock rebuild before the API result arrived.
	record["input"]=transient_input
	renderer.pending_pronouncement_inputs["request_test"]=record
	transient_input.queue_free()
	await get_tree().process_frame
	renderer._on_pronouncement_interpreted("request_test",{
		"source":"generative API","summary":"I understand the request.",
		"policies":[],"unresolved":"The settlement needs an appointed leader.",
	})
	assert_bool(renderer.pending_pronouncement_inputs.has("request_test")).is_false()
	assert_str(String(order.get("status",""))).is_equal("leader_unavailable")


func test_economy_badge_ignores_healthy_reserve_threshold_crossings()->void:
	var hud:Variant=auto_free(COMMAND_RAIL.new())
	GameState.consecutive_food_shortage_days=0.0
	GameState.consecutive_water_shortage_days=0.0
	var healthy_food:Dictionary={"food_days":6.8,"food_net":2.0,"food_intake_ratio":1.0}
	var healthy_water:Dictionary={"days":0.8,"required_today":120.0,"intake_ratio":1.0}
	assert_bool(hud._economy_danger_active(healthy_food,healthy_water)).is_false()
	GameState.consecutive_water_shortage_days=2.0
	var short_water:Dictionary={"days":0.0,"required_today":120.0,"intake_ratio":0.72}
	assert_bool(hud._economy_danger_active(healthy_food,short_water)).is_true()
	GameState.consecutive_water_shortage_days=0.0
	var falling_food:Dictionary={"food_days":5.0,"food_net":-8.0,"food_intake_ratio":1.0}
	assert_bool(hud._economy_danger_active(falling_food,healthy_water)).is_true()


func test_food_weather_varies_across_years_without_escaping_bounded_yields()->void:
	var profile:Dictionary={"rainfall_variability":0.86}
	var minimum:=2.0
	var maximum:=0.0
	for day in range(0,365*16,5):
		var factor:float=FoodSystem._weather_yield_factor(profile,float(day))
		minimum=minf(minimum,factor)
		maximum=maxf(maximum,factor)
		assert_float(factor).is_between(0.52,1.24)
	assert_float(minimum).is_less(0.82)
	assert_float(maximum).is_greater(1.08)


func test_resource_overlay_draw_list_has_a_fixed_world_scale_ceiling()->void:
	var deposits:Array=[]
	for index in 2400:
		var x:=-8.5+float(index%120)*0.14
		var z:=-8.5+float(index/120)*0.82
		deposits.append({"id":"known_%d" % index,"resource":"Stone","stage":"recognized","position":Vector3(x,0.0,z)})
	var selected:Array[Dictionary]=renderer._bounded_resource_overlay_selection(deposits,Vector2.ZERO,10.0)
	assert_int(selected.size()).is_equal(RENDERER.RESOURCE_OVERLAY_MAX_CLUSTERS)


func test_resource_overlay_keeps_recognized_resources_at_regional_zoom_and_never_dots_rivers()->void:
	var deposits:Array=[
		{"id":"mere_hint","resource":"Stone","stage":"recognized","position":Vector3(0.2,0.0,0.1)},
		{"id":"worked_timber","resource":"Timber","stage":"accessible","position":Vector3(0.4,0.0,0.1)},
		{"id":"river","resource":"Freshwater","stage":"developed","position":Vector3(0.1,0.0,0.2)}
	]
	var selected:Array[Dictionary]=renderer._bounded_resource_overlay_selection(deposits,Vector2.ZERO,30.0)
	assert_int(selected.size()).is_equal(2)
	assert_str(String(selected[0].resource)).is_equal("Timber")
	assert_str(String(selected[0].visual_stage)).is_equal("active")
	assert_str(String(selected[1].resource)).is_equal("Stone")
	assert_str(String(selected[1].visual_stage)).is_equal("recognized")


func test_founding_party_recognizes_obvious_resources_only_on_charted_ground()->void:
	ResourceSystem.reset_for_new_world()
	GameState.resource_deposits=[]
	ResourceSystem.register_local_occurrences([
		{"type":"Timber","position":Vector3(2.0,0.0,1.0),"initially_observed":true},
		{"type":"Stone","position":Vector3(3.0,0.0,1.0),"initially_observed":true},
		{"type":"Fertile","position":Vector3(4.0,0.0,1.0),"initially_observed":true},
		{"type":"Timber","position":Vector3(90.0,0.0,1.0),"initially_observed":false}
	],"Plains")
	assert_str(String(GameState.resource_deposits[0].stage)).is_equal("recognized")
	assert_str(String(GameState.resource_deposits[1].stage)).is_equal("recognized")
	assert_str(String(GameState.resource_deposits[2].stage)).is_equal("recognized")
	assert_str(String(GameState.resource_deposits[3].stage)).is_equal("unknown")
	assert_float(float(GameState.resource_deposits[0].survey)).is_equal(0.0)


func test_opening_regional_zoom_renders_recognized_surface_resources()->void:
	var selected:Array[Dictionary]=renderer._bounded_resource_overlay_selection([
		{"resource":"Timber","stage":"recognized","position":Vector3(12.0,0.0,5.0)},
		{"resource":"Stone","stage":"recognized","position":Vector3(-18.0,0.0,8.0)}
	],Vector2.ZERO,190.0)
	assert_int(selected.size()).is_equal(2)


func test_resource_overlay_clusters_dense_occurrences_instead_of_creating_nodes_per_site()->void:
	var deposits:Array=[]
	for index in 20:
		deposits.append({"id":"timber_%d" % index,"resource":"Timber","stage":"developed","position":Vector3(float(index)*0.006,0.0,float(index)*0.004)})
	var selected:Array[Dictionary]=renderer._bounded_resource_overlay_selection(deposits,Vector2.ZERO,20.0)
	assert_int(selected.size()).is_equal(1)
	assert_int(int(selected[0].count)).is_equal(20)


func test_resource_overlay_keeps_active_supply_nodes_ahead_of_passive_hints()->void:
	var deposits:Array=[]
	for index in 900:
		var angle:=float(index)*0.37
		var distance:=0.5+float(index%80)*0.09
		deposits.append({"id":"hint_%d" % index,"resource":"Stone","stage":"recognized","position":Vector3(cos(angle)*distance,0.0,sin(angle)*distance)})
	deposits.append({"id":"active_copper","resource":"Copper Ore","stage":"accessible","position":Vector3(8.0,0.0,0.0)})
	var selected:Array[Dictionary]=renderer._bounded_resource_overlay_selection(deposits,Vector2.ZERO,12.0)
	assert_int(selected.size()).is_equal(RENDERER.RESOURCE_OVERLAY_MAX_CLUSTERS)
	assert_str(String(selected[0].resource)).is_equal("Copper Ore")
	assert_str(String(selected[0].visual_stage)).is_equal("active")


func test_non_scrolling_fit_host_keeps_finite_modal_content_inside_its_viewport()->void:
	var host:=auto_free(preload("res://scripts/viewport_fit_panel.gd").new()) as Control
	host.size=Vector2(400,200)
	var content:=VBoxContainer.new()
	content.custom_minimum_size=Vector2(800,400)
	host.add_child(content)
	host._fit_content()
	assert_float(float(host.effective_scale)).is_equal_approx(0.5,0.001)
	assert_float(content.position.x).is_greater_equal(0.0)
	assert_float(content.position.y).is_greater_equal(0.0)
	assert_float(content.position.x+content.size.x*content.scale.x).is_less_equal(host.size.x+0.01)
	assert_float(content.position.y+content.size.y*content.scale.y).is_less_equal(host.size.y+0.01)
	assert_int(host.find_children("*","ScrollContainer",true,false).size()).is_equal(0)


func test_fit_host_pages_a_growing_ledger_instead_of_miniaturizing_it()->void:
	var host:=auto_free(preload("res://scripts/viewport_fit_panel.gd").new()) as Control
	host.size=Vector2(520,240)
	var ledger:=VBoxContainer.new()
	host.add_child(ledger)
	for index in 24:
		var row:=PanelContainer.new()
		row.custom_minimum_size=Vector2(500,42)
		ledger.add_child(row)
	host._fit_content()
	assert_int(host.page_count).is_greater(1)
	assert_float(float(host.effective_scale)).is_greater_equal(0.74)
	var visible_rows:=0
	for row in ledger.get_children():
		if (row as Control).visible: visible_rows+=1
	assert_int(visible_rows).is_greater(0)
	assert_int(visible_rows).is_less(24)
	assert_int(host.find_children("ViewportPager","HBoxContainer",true,false).size()).is_equal(1)


func test_modal_screen_contract_caps_large_type_without_touching_map_sized_controls()->void:
	var screen:=auto_free(Control.new()) as Control
	screen.size=Vector2(1920,1080)
	var title:=Label.new(); title.add_theme_font_size_override("font_size",30); screen.add_child(title)
	var button:=Button.new(); button.add_theme_font_size_override("font_size",18); screen.add_child(button)
	renderer._apply_modal_screen_contract(screen)
	assert_int(title.get_theme_font_size("font_size")).is_equal(22)
	assert_int(button.get_theme_font_size("font_size")).is_equal(12)
	assert_int(screen.theme.default_font_size).is_equal(11)


func test_foreign_alert_arbitration_defers_without_losing_active_or_queued_events()->void:
	renderer.foreign_alert_panel=auto_free(PanelContainer.new()) as PanelContainer
	renderer.settlement_naming_panel=auto_free(Control.new()) as Control
	add_child(renderer.foreign_alert_panel)
	add_child(renderer.settlement_naming_panel)
	renderer.active_foreign_alert={"alert_key":"first","kind":"first_contact"}
	renderer.foreign_alert_queue.clear()
	renderer.foreign_alert_queue.append({"alert_key":"second","kind":"unit_sighting"})
	renderer.foreign_alert_panel.visible=true
	renderer.settlement_naming_panel.visible=true
	assert_bool(renderer._blocking_modal_or_report_open()).is_true()
	renderer._arbitrate_notification_overlays()
	assert_bool(renderer.foreign_alert_panel.visible).is_false()
	assert_str(String(renderer.active_foreign_alert.alert_key)).is_equal("first")
	assert_int(renderer.foreign_alert_queue.size()).is_equal(1)

