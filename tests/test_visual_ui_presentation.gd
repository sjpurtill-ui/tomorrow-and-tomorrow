extends GdUnitTestSuite

const RENDERER:=preload("res://scripts/local_terrain.gd")

var renderer:Node3D


func before_test()->void:
	GameState.reset_for_new_world(741991)
	renderer=auto_free(RENDERER.new())


func test_population_notice_uses_demographic_conditions_not_food_duplication()->void:
	var text:String=renderer._demographic_notice_condition_text({
		"health":0.83,"water_intake_ratio":0.91,"housing_ratio":1.04,
		"food_days":42.0,"production_ratio":1.18
	})
	assert_str(text).contains("HEALTH 83%")
	assert_str(text).contains("WATER 91%")
	assert_str(text).contains("SHELTER 104%")
	assert_str(text.to_lower()).not_contains("food")
	assert_str(text.to_lower()).not_contains("stores")


func test_discovery_mask_paints_a_scout_corridor_without_filling_its_bounding_region()->void:
	var image:=Image.create(200,100,false,Image.FORMAT_L8)
	image.fill(Color.BLACK)
	renderer._paint_discovery_segment(image,Vector2(-8000.0,-4000.0),Vector2(8000.0,4000.0),18.0,200,100)
	# The route crosses the center, while the opposite corners of its enormous
	# bounding rectangle were never observed.
	assert_float(image.get_pixel(100,50).r).is_greater(0.80)
	assert_float(image.get_pixel(100,15).r).is_equal(0.0)
	assert_float(image.get_pixel(30,80).r).is_equal(0.0)


func test_population_notice_is_transient_and_old_records_stay_hidden()->void:
	var record:={"day":100,"end_day":100}
	assert_bool(renderer._demographic_notice_is_current(record,100)).is_true()
	assert_bool(renderer._demographic_notice_is_current(record,101)).is_true()
	assert_bool(renderer._demographic_notice_is_current(record,102)).is_false()
	assert_int(renderer._demographic_notice_duration_msec("birth")).is_equal(12000)
	assert_int(renderer._demographic_notice_duration_msec("death")).is_equal(18000)


func test_knowledge_header_stat_returns_the_live_value_label()->void:
	var row:HBoxContainer=auto_free(HBoxContainer.new()) as HBoxContainer
	var value:Label=renderer._make_knowledge_stat(row,"DIRECTED","4",Color("#c8a862"))
	assert_str(value.text).is_equal("4")
	value.text="3"
	assert_str(value.text).is_equal("3")
	assert_int(row.get_child_count()).is_equal(1)


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


func test_established_discovery_explains_evidence_capacity_and_social_cause()->void:
	var summary:String=renderer._discovery_cause_summary({
		"id":"fixture_discovery",
		"causal_mechanism":"Covered grain stays dry when raised above wet ground.",
		"evidence_method":"Repeated side-by-side storage trials",
		"operating_capability":"Build dependable raised granaries",
		"ability_reason":"Because the raised floor can be copied, reserve losses fall.",
		"social_consequence":"Communities begin expecting keepers to account for communal reserves."
	})
	assert_str(summary).contains("FOUND  •  Covered grain stays dry")
	assert_str(summary).contains("EVIDENCE  •  Repeated side-by-side storage trials")
	assert_str(summary).contains("WHY CAPACITY CHANGED  •  Because the raised floor can be copied")
	assert_str(summary).contains("SOCIAL EFFECT  •  Communities begin expecting keepers")


func test_small_discovery_effects_keep_precision_and_show_actual_direction()->void:
	var full_effect:String=renderer._effect_ripple_text({"food_output":0.0035,"ecological_pressure":-0.0018})
	var partial_effect:String=renderer._effect_ripple_text({"food_output":0.0035},0.5)
	assert_str(full_effect).contains("+0.4% food output")
	assert_str(full_effect).contains("−0.2% land pressure")
	assert_str(full_effect).not_contains("0%")
	assert_str(partial_effect).contains("+0.2% food output")


func test_research_library_filters_concrete_discoveries_by_macro_field()->void:
	GameState.discovery_log=[
		{"id":"food_measure","dynamic":"nutrition","name":"WEIGHED DAILY RATIONS","effects":{"food_output":0.01}},
		{"id":"shelter_span","dynamic":"demography","name":"SUPPORTED ROOF SPANS","effects":{"housing":0.01}},
		{"id":"soil_cover","dynamic":"ecology","name":"SEASONAL SOIL COVER","effects":{"ecology":0.01}}
	]
	var all_records:Array[Dictionary]=renderer._knowledge_records_for_mode("discoveries","all")
	var nutrition:Array[Dictionary]=renderer._knowledge_records_for_mode("discoveries","nutrition")
	assert_int(all_records.size()).is_equal(3)
	assert_int(nutrition.size()).is_equal(1)
	assert_str(String(nutrition[0].name)).is_equal("WEIGHED DAILY RATIONS")
	assert_int(RENDERER.KNOWLEDGE_RECORD_PAGE_SIZE).is_equal(5)


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


func test_live_report_focus_path_supports_internal_tab_controls()->void:
	var panel:=auto_free(Control.new()) as Control
	var tabs:=TabContainer.new()
	panel.add_child(tabs)
	var page:=Control.new(); page.name="PAGE"; tabs.add_child(page)
	var internal_tab_bar:=tabs.get_tab_bar()
	var index_path:Array[int]=renderer._live_report_child_index_path(panel,internal_tab_bar)
	assert_bool(index_path.is_empty()).is_false()
	assert_object(renderer._live_report_node_at_index_path(panel,index_path)).is_same(internal_tab_bar)


func test_modal_screen_contract_caps_large_type_without_touching_map_sized_controls()->void:
	var screen:=auto_free(Control.new()) as Control
	screen.size=Vector2(1920,1080)
	var title:=Label.new(); title.add_theme_font_size_override("font_size",30); screen.add_child(title)
	var button:=Button.new(); button.add_theme_font_size_override("font_size",18); screen.add_child(button)
	renderer._apply_modal_screen_contract(screen)
	assert_int(title.get_theme_font_size("font_size")).is_equal(22)
	assert_int(button.get_theme_font_size("font_size")).is_equal(12)
	assert_int(screen.theme.default_font_size).is_equal(11)


func test_compact_discovery_rows_lead_with_current_effect_and_hide_explanation_until_details()->void:
	var event:Dictionary={
		"name":"Compared Regional Ration Weight Schedules","dynamic":"nutrition",
		"effects":{"food_output":0.0035,"diet_quality":0.0020},
		"causal_mechanism":"A deliberately long mechanism that belongs in the detail view.",
		"evidence_method":"A deliberately long evidence account that belongs in the detail view."
	}
	var effect:String=renderer._compact_discovery_effect_text(event,1.0)
	assert_str(effect).starts_with("NOW  •")
	assert_str(effect).contains("+0.4% FOOD OUTPUT")
	var list:=VBoxContainer.new()
	renderer._make_discovery_card(list,event)
	var visible_text:=""
	for label in list.find_children("*","Label",true,false): visible_text+=String(label.text)+"\n"
	assert_str(visible_text).contains("COMPARED REGIONAL RATION WEIGHT SCHEDULES")
	assert_str(visible_text).contains("NOW  •")
	assert_str(visible_text).not_contains("deliberately long mechanism")
	assert_str(visible_text).not_contains("deliberately long evidence")
	assert_int(list.find_children("*","Button",true,false).size()).is_equal(1)
	list.free()


func test_population_function_display_is_fixed_conserved_and_contains_no_food_dashboard_data()->void:
	var records:Array[Dictionary]=renderer._population_function_display({
		"total":1_000_000,"productive":520_000,"support":110_000,
		"mobilized":70_000,"dependent":280_000,"absent":20_000
	})
	assert_int(records.size()).is_equal(5)
	var ids:Array[String]=[]
	var accounted:=0
	var display_text:=""
	for record in records:
		ids.append(String(record.id))
		accounted+=int(record.count)
		display_text+="%s %s " % [String(record.label),String(record.note)]
	assert_array(ids).is_equal(["productive","support","mobilized","dependent","absent"])
	assert_int(accounted).is_equal(1_000_000)
	assert_str(display_text.to_lower()).not_contains("food")
	assert_str(display_text.to_lower()).not_contains("rations")
	assert_float(float(records[4].share)).is_equal_approx(0.02,0.0001)


func test_major_ledgers_explain_status_reason_and_next_action()->void:
	var provisions:Dictionary=renderer._provisions_decision_brief({"food_intake_ratio":1.0,"food_net":-12.0,"food_forecast_90":{"first_shortage_day":-1}},{"intake_ratio":1.0},4.0)
	assert_str(String(provisions.status)).contains("FOOD RESERVE FELL")
	assert_str(String(provisions.why)).contains("issued for missions")
	assert_str(String(provisions.next)).contains("Mission Issues")
	var materials:Dictionary=renderer._material_constraint_brief({"at_source":40.0,"delivered_today":8.0,"extracted_today":12.0},3,100.0,20.0)
	assert_str(String(materials.status)).contains("CARRYING")
	assert_str(String(materials.next)).contains("Logistics")
	var population:Dictionary=renderer._population_attention_brief({"total":1_000_000,"productive":610_000,"absent":100_000,"mobilized":20_000},{"health":0.90,"housing_ratio":1.05})
	assert_str(String(population.status)).contains("AWAY")
	assert_str(String(population.next)).contains("missions")
	var society:Dictionary=renderer._society_attention_brief({"nutrition":0.72,"health":0.68,"knowledge":0.21,"production":0.64})
	assert_str(String(society.status)).contains("KNOWLEDGE")
	assert_str(String(society.next)).contains("Research Priorities")


func test_world_strategy_next_step_preserves_information_gates()->void:
	var step:Dictionary=renderer._world_strategy_next_step({
		"name":"Ashen Compact","intel_confidence":0.40,
		"player_relation":{"home_location_known":false,"at_war":false}
	})
	assert_str(String(step.status)).contains("SETTLEMENT UNLOCATED")
	assert_str(String(step.why)).contains("no returned report")
	assert_str(String(step.next)).contains("Diplomats cannot depart")


func test_council_policy_copy_keeps_decision_visible_and_audit_jargon_in_details()->void:
	var copy:Dictionary=renderer._council_active_policy_copy({
		"id":"route_priority","remaining_days":40.0,"execution_factor":0.82,
		"magnitude":0.6,"effects":{"logistics":0.10},"office":"Steward",
		"executor":"Route office","action_source":"deterministic enact reading of player clause",
		"parameter_basis":"catalog defaults","interpretation_basis":"improve routes",
		"interpretation_confidence":0.94,"description":"Move more labor into maintained routes."
	},{"summary":"Deliveries rose after the order.","disclaimer":"This is an observed movement."})
	assert_str(String(copy.visible)).contains("ROUTE PRIORITY")
	assert_str(String(copy.visible)).contains("CHANGES")
	assert_str(String(copy.visible)).contains("LATEST OBSERVED")
	assert_str(String(copy.visible)).not_contains("ACTION SOURCE")
	assert_str(String(copy.visible)).not_contains("TERMS")
	assert_str(String(copy.details)).contains("ACTION SOURCE")
	assert_str(String(copy.details)).contains("GROUNDED READING")


func test_council_pronouncement_copy_is_compact_but_auditable()->void:
	var copy:Dictionary=renderer._council_pronouncement_copy({
		"issued_day":12,"status":"active","parameters":{"text":"Improve routes.","interpretation":{"source":"local","policies":[{
			"id":"route_priority","action":"enact","days":90.0,"execution_factor":0.8,
			"magnitude":0.5,"effects":{"logistics":0.1},"basis":"improve routes",
			"action_source":"deterministic player-clause reading","parameter_basis":"catalog defaults",
			"observation":{"summary":"Deliveries improved."}
		}]}}
	})
	assert_str(String(copy.visible)).contains("ENACT ROUTE PRIORITY")
	assert_str(String(copy.visible)).contains("Deliveries improved")
	assert_str(String(copy.visible)).not_contains("catalog defaults")
	assert_str(String(copy.details)).contains("TERMS")
	assert_str(String(copy.details)).contains("VARIABLES")


func test_action_brief_and_council_empty_state_follow_what_why_next_hierarchy()->void:
	var container:VBoxContainer=auto_free(VBoxContainer.new()) as VBoxContainer
	var brief:Label=renderer._add_modal_action_brief(container,{"status":"STORES FALLING","why":"A mission left today.","next":"Review mission issues."},Color("#b99369"))
	assert_str(brief.text).starts_with("STATUS  •  STORES FALLING")
	assert_str(brief.text).contains("\nWHY  •  A mission left today.")
	assert_str(brief.text).contains("\nNEXT  •  Review mission issues.")
	var council:VBoxContainer=auto_free(VBoxContainer.new()) as VBoxContainer
	var no_decisions:Array[Dictionary]=[]
	renderer._add_council_decisions_section(council,no_decisions,2)
	var combined:=""
	for child in council.get_children():
		if child is Label: combined+=String((child as Label).text)+"\n"
	assert_str(combined).contains("NO DECISION REQUIRED")
	assert_str(combined).contains("routine updates")
	assert_str(combined).contains("Issue a standing policy")


func test_live_report_refresh_is_bounded_and_state_driven()->void:
	assert_float(RENDERER.LIVE_REPORT_REFRESH_INTERVAL_SECONDS).is_greater_equal(0.5)
	var before:String=renderer._live_report_signature("population")
	renderer._process_live_report_refresh(RENDERER.LIVE_REPORT_REFRESH_INTERVAL_SECONDS*0.40)
	assert_float(renderer.live_report_refresh_elapsed).is_greater(0.0)
	GameState.elapsed_days+=1.0
	var after:String=renderer._live_report_signature("population")
	assert_str(after).is_not_equal(before)


func test_live_report_refresh_never_rebuilds_active_text_or_choice_workflows()->void:
	var panel:Control=auto_free(Control.new()) as Control
	var input:=LineEdit.new()
	input.text="Keep this unfinished policy text"
	panel.add_child(input)
	assert_bool(renderer._live_report_interaction_active("council",panel)).is_true()
	input.text=""
	var selector:=OptionButton.new()
	selector.add_item("Unfinished choice")
	panel.add_child(selector)
	selector.get_popup().visible=true
	assert_bool(renderer._live_report_interaction_active("civilization_report",panel)).is_true()


func test_deferred_live_report_commit_ignores_a_panel_closed_during_composition()->void:
	var closed_panel:=Control.new()
	closed_panel.free()
	var offscreen_replacement:=Control.new()
	renderer.live_report_pending_replacements={"materials":{"stable":closed_panel,"replacement":offscreen_replacement}}
	renderer._commit_live_report_replacements()
	assert_bool(is_instance_valid(offscreen_replacement)).is_false()


func test_provisions_dashboard_exposes_consumers_armies_and_prepaid_missions_without_main_scroll()->void:
	var summary:String=renderer._provisions_consumer_summary({
		"food_demand_breakdown":{"children":18.0,"adults":70.0,"elders":8.0,"labor":6.0,"army_field":12.0}
	},114.0)
	assert_str(summary).contains("Children")
	assert_str(summary).contains("Adults")
	assert_str(summary).contains("Field armies")
	var dashboard:=HBoxContainer.new()
	var column:VBoxContainer=renderer._make_provision_dashboard_column(dashboard,"WHO USES FOOD","Daily and prepaid")
	renderer._add_compact_provision_text(column,"DAILY MEALS",summary,Color.WHITE)
	assert_int(dashboard.find_children("*","ScrollContainer",true,false).size()).is_equal(0)
	assert_str(renderer._provisions_commitment_summary().to_lower()).contains("scout")
	assert_str(renderer._provisions_commitment_summary().to_lower()).contains("diplomat")
	assert_str(renderer._provisions_commitment_summary().to_lower()).contains("convoy")
	dashboard.free()


func test_foreign_alert_arbitration_defers_without_losing_active_or_queued_events()->void:
	renderer.foreign_alert_panel=auto_free(PanelContainer.new()) as PanelContainer
	renderer.materials_panel=auto_free(Control.new()) as Control
	add_child(renderer.foreign_alert_panel)
	add_child(renderer.materials_panel)
	renderer.active_foreign_alert={"alert_key":"first","kind":"first_contact"}
	renderer.foreign_alert_queue.clear()
	renderer.foreign_alert_queue.append({"alert_key":"second","kind":"unit_sighting"})
	renderer.foreign_alert_panel.visible=true
	renderer.materials_panel.visible=true
	assert_bool(renderer._blocking_modal_or_report_open()).is_true()
	renderer._arbitrate_notification_overlays()
	assert_bool(renderer.foreign_alert_panel.visible).is_false()
	assert_str(String(renderer.active_foreign_alert.alert_key)).is_equal("first")
	assert_int(renderer.foreign_alert_queue.size()).is_equal(1)


func test_material_flow_rows_put_blockers_first_and_suppress_meaningless_zero_copy()->void:
	var rows:Array[Dictionary]=renderer._material_flow_rows([
		{"resource":"Timber","stage":"developed","workers":8,"extracted_today":4.0,"stock_at_source":2.0,"distance_km":12.0,"bottleneck":"Flowing"},
		{"resource":"Stone","stage":"recognized","workers":0,"extracted_today":0.0,"stock_at_source":0.0,"distance_km":0.0,"bottleneck":""},
		{"resource":"Clay","stage":"accessible","workers":4,"extracted_today":0.0,"stock_at_source":8.0,"distance_km":4.0,"bottleneck":"carriers unavailable"}
	])
	assert_int(rows.size()).is_equal(3)
	assert_str(String(rows[0].material)).is_equal("Clay")
	assert_str(String(rows[0].status)).is_equal("BLOCKED")
	assert_str(String(rows[1].status)).is_equal("UNORGANIZED")
	assert_str(String(rows[2].status)).is_equal("FLOWING")
	var table:=VBoxContainer.new()
	renderer._add_material_flow_header(table)
	for row in rows: renderer._add_material_flow_row(table,row)
	var visible_text:=""
	for label in table.find_children("*","Label",true,false): visible_text+=String(label.text)+"\n"
	assert_str(visible_text.to_lower()).not_contains("farthest 0")
	assert_str(visible_text.to_lower()).not_contains("0.0 extracted  •  0.0 waiting  •  0.0 moving")
	assert_int(table.find_children("*","ScrollContainer",true,false).size()).is_equal(0)
	table.free()
