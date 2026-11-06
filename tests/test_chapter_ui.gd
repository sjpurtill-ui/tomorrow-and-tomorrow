extends GdUnitTestSuite
const Chapters:=preload("res://scripts/campaign_chapters.gd")
const Provider:=preload("res://scripts/hud/content/dock_content_inquiry.gd")
const Board:=preload("res://scripts/hud/chapter_board.gd")
const ResearchTree:=preload("res://scripts/hud/knowledge_tree_board.gd")

class Hud extends Control:
	signal section_requested(section:String,sub:int)
	var opened:Array=[]
	func request_immediate_dock_refresh()->void:pass
	func open_dock(section:String,sub:int,_expanded:bool)->void:opened=[section,sub]

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(4242)
	MilitaryCampaign.reset_for_new_world();DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()

func after_test()->void:WorldSimulation.clear()

func test_chapter_report_is_read_only_and_all_routes_are_visible_at_both_widths()->void:
	var hud:=auto_free(Hud.new()) as Hud
	var provider:=Provider.new(null,hud)
	var before:=DiscoverySystem.chapter_progress.duplicate(true)
	for width in [1280,600]:
		var board:=auto_free(Board.new()) as Control
		add_child(board);board.size=Vector2(width,900);board.setup(provider._chapter_block())
		await get_tree().process_frame
		var grid:=board.find_child("BreakthroughRoutes",true,false) as GridContainer
		assert_int(grid.get_child_count()).is_equal(3)
		assert_int(grid.columns).is_equal(3 if width==1280 else 1)
		assert_float(board.get_combined_minimum_size().x).is_less_equal(float(width))
	assert_dict(DiscoverySystem.chapter_progress).is_equal(before)

func test_graph_uses_actual_edges_and_keeps_pan_across_refresh()->void:
	var hud:=auto_free(Hud.new()) as Hud
	var provider:=Provider.new(null,hud);provider.tree_domain="security"
	var block:=provider._tree_block()
	var board:=auto_free(ResearchTree.new()) as Control
	add_child(board);board.size=Vector2(1280,900);board.setup(block)
	await get_tree().process_frame
	var graph:=board.find_child("BranchingResearchTree",true,false) as GraphEdit
	assert_object(graph).is_not_null()
	assert_int(graph.get_connection_list().size()).is_greater(5)
	for edge:Dictionary in graph.get_connection_list():
		assert_bool((graph.by_id[String(edge.to_node)].parents as Array).has(String(edge.from_node))).is_true()
	graph.scroll_offset=Vector2(220,330);graph.zoom=0.8
	var state:Dictionary=graph.view_state()
	graph.scroll_offset=Vector2.ZERO;graph.zoom=1.0;graph.restore_view_state(state)
	assert_float(graph.zoom).is_equal_approx(0.8,0.001)
	assert_vector(graph.scroll_offset).is_equal(state.scroll)

func test_milestone_navigation_and_field_focus_reach_actual_actions()->void:
	var hud:=auto_free(Hud.new()) as Hud
	var provider:=Provider.new(null,hud)
	provider._open_chapter_question("shield_wall")
	assert_array(hud.opened).contains_exactly(["inquiry",1])
	assert_str(provider.tree_domain).is_equal("security")
	assert_str(provider.tree_selected).is_equal("shield_wall")
	var before:=int(GameState.research_allocations.security)
	provider._change_weight(1)
	assert_int(int(GameState.research_allocations.security)).is_equal(before+1)
