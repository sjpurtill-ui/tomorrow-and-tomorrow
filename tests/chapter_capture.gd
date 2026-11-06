extends Node
## Native offscreen UI fixtures; no player scene, saved campaign or HTTP calls.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Provider:=preload("res://scripts/hud/content/dock_content_inquiry.gd")
const Board:=preload("res://scripts/hud/chapter_board.gd")
const ResearchTree:=preload("res://scripts/hud/knowledge_tree_board.gd")
class Hud extends Control:
	signal section_requested(section:String,sub:int)
	func request_immediate_dock_refresh()->void:pass
	func open_dock(_section:String,_sub:int,_expanded:bool)->void:pass

func _ready()->void:
	get_window().title="TEST · Chapter UI capture"
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	WorldSimulation.clear();GameState.reset_for_new_world(4242)
	MilitaryCampaign.reset_for_new_world();DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	var hud:=Hud.new();add_child(hud)
	var provider:=Provider.new(null,hud);provider.tree_domain="security"
	T.set_color_mode("light")
	DirAccess.make_dir_recursive_absolute("/tmp/tt-chapter-captures")
	for width in [1280,600]:
		for kind in ["goals","tree"]:
			var vp:=SubViewport.new();vp.size=Vector2i(width,1100);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(vp)
			var background:=ColorRect.new();background.color=T.PAPER_SUNK;background.size=Vector2(width,1100);vp.add_child(background)
			var scroll:=ScrollContainer.new();scroll.size=Vector2(width,1100);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;vp.add_child(scroll)
			var margin:=MarginContainer.new();margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			for side:String in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,18)
			scroll.add_child(margin)
			var board:Control=Board.new() if kind=="goals" else ResearchTree.new();margin.add_child(board)
			board.setup(provider._chapter_block() if kind=="goals" else provider._tree_block())
			for frame in 10:await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img:=vp.get_texture().get_image()
			assert(img!=null and not img.is_empty())
			img.save_png("/tmp/tt-chapter-captures/%s-%d.png" % [kind,width])
			assert(board.get_combined_minimum_size().x<=width-36,"Board exceeds narrow canvas")
			if kind=="goals" and width==600:
				scroll.scroll_vertical=800
				for frame in 5:await get_tree().process_frame
				await RenderingServer.frame_post_draw
				vp.get_texture().get_image().save_png("/tmp/tt-chapter-captures/goals-600-bottom.png")
			vp.queue_free();await get_tree().process_frame
	print("CHAPTER_UI_CAPTURE_PASS")
	WorldSimulation.clear();get_tree().quit()
