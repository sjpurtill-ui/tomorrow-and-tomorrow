extends Node
const DiscoveryNotice=preload("res://scripts/hud/discovery_popup.gd")
const ResearchView=preload("res://scripts/hud/research_atlas.gd")
const Art=preload("res://scripts/hud/research_visuals.gd")
class Host extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value
func _ready()->void:
	get_window().title="TEST — Discovery artwork audit";get_window().mode=Window.MODE_MINIMIZED;call_deferred("run")
func settle()->void:
	for i in 8:await get_tree().process_frame;RenderingServer.force_draw(false)
func run()->void:
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]:node.set_process(false)
	GameState.known_discoveries.append_array(["stone_sorting","clay_shaping"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/discovery-art/"))
	var errors:=0
	for dimensions:Vector2i in [Vector2i(1200,900),Vector2i(800,600)]:
		var canvas:=SubViewport.new();canvas.size=dimensions;canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(canvas)
		var host:=Host.new();canvas.add_child(host);var hud:=Control.new();host.add_child(hud)
		for id:String in ["stone_sorting","clay_shaping"]:
			var popup:=DiscoveryNotice.announce(host,hud,[{"id":id,"day":1129}]);await settle()
			var inside:=Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(popup.next_button.get_global_rect())
			if not inside:errors+=1
			if id=="stone_sorting" and Art.source_texture(popup.hero.texture).resource_path!="res://assets/ui/research/paper/stone_sorting.png":errors+=1
			if popup.hero.has_node("FieldIllustrationCaption"):errors+=1
			if host.game_speed!=0:errors+=1
			canvas.get_texture().get_image().save_png("res://artifacts/discovery-art/%s-%d.png" % [id,dimensions.x])
			print("DISCOVERY_ART ",id," ",dimensions," artwork=",Art.source_texture(popup.hero.texture).resource_path," controls_inside=",inside)
			popup.close();await settle()
			if host.game_speed!=3:errors+=1
		if dimensions.x==1200:
			var view:=ResearchView.new();canvas.add_child(view);view.set_view("known");view.select("stone_sorting");await settle()
			canvas.get_texture().get_image().save_png("res://artifacts/discovery-art/research-cards.png")
			view.domain="production";view.show_locked=true;view.set_view("tree");view.select("stone_sorting");view.plot.center_selected();await settle()
			canvas.get_texture().get_image().save_png("res://artifacts/discovery-art/research-tree.png")
		canvas.queue_free();await settle()
	WorldSimulation.clear();print("DISCOVERY_ART_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)
