extends GdUnitTestSuite
const K=preload("res://scripts/formed_metal_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const ITEMS=["metal_spinning_tool_sets", "spun_motor_shrouds", "rotary_swaging_dies", "cast_terminal_pin_blanks", "swaged_terminal_pins", "terminated_motor_leads", "formed_component_motors", "centrifugal_tube_molds", "centrifugal_steel_tube_blanks", "bored_steel_tubes", "tube_bend_tool_sets", "formed_steel_pipe_bends", "qualified_bent_pipe_fittings", "channel_roll_tool_sets", "roll_formed_channels", "qualified_channel_press_frames", "channel_frame_pneumatic_presses", "continuity_test_sets"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("formed",1209)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_five_original_definitions_and_eighteen_paid_routes()->void:
	WorldSimulation.scoped("formed",func()->void:
		assert_int(K.entries().size()).is_equal(5)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var expected={"metal_spinning_forming":["centre_lathe_assembly","sheet_steel_rolling"],"rotary_swaging":["precision_machinery","toolbit_heat_treatment"],"tube_rotary_draw_bending":["precision_machinery","stress_strain_relations"],"roll_formed_sections":["sheet_steel_rolling","shaft_alignment_methods"],"centrifugal_tube_casting":["metal_casting_feed_design","precision_machinery"]}
		for e:Dictionary in K.entries():
			assert_array(e.requires_all).is_equal(expected[e.id]);assert_array(e.requires_any).is_empty()
		for item:String in ITEMS:assert_bool(I.product(item).is_empty()).is_false())
func test_unmachined_blanks_and_unqualified_sections_cannot_bypass_consumers()->void:
	WorldSimulation.scoped("formed",func()->void:
		var state=WorldSimulation.state
		for pair:Array in [["formed_steel_pipe_bends","Bored Steel Tubes","Centrifugal Steel Tube Blanks"],["channel_frame_pneumatic_presses","Qualified Channel Press Frames","Roll-Formed Steel Channels"],["terminated_motor_leads","Swaged Copper Terminal Pins","Copper Terminal Pin Blanks"]]:
			var spec:=I.product(pair[0]);learn(spec.gate)
			for field:String in ["materials","tooling"]:
				for r:String in spec[field]:state.resource_stockpiles[r]=10.0
			state.resource_stockpiles[pair[1]]=0.0;state.resource_stockpiles[pair[2]]=10.0
			var before:Dictionary=state.resource_stockpiles.duplicate(true)
			assert_bool(WorldSimulation.military.start_production_line(pair[0],1).has("error")).is_true()
			assert_dict(state.resource_stockpiles).is_equal(before))
