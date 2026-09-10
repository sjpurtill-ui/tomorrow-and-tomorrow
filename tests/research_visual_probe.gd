extends Node
## Capture-only fixture. No player launch, no saves, no persistent simulation.
const Atlas=preload("res://scripts/hud/research_atlas.gd")
const DiscoveryPopup=preload("res://scripts/hud/discovery_popup.gd")
var canvas:SubViewport
var view:Control
func _ready()->void:
	get_window().title="TEST — Research visual audit";get_window().mode=Window.MODE_MINIMIZED;call_deferred("run")
func settle()->void:
	for frame in 8:await get_tree().process_frame;RenderingServer.force_draw(false)
func capture(file:String)->void:
	await settle();canvas.get_texture().get_image().save_png("res://artifacts/research/"+file+".png")
func run()->void:
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	GameState.reset_for_new_world(424242);MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world();DiscoverySystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(400);GameState.population_allocations["Knowledge"]=24
	GameState.elapsed_days=300;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	for office:String in ["Steward","Quartermaster","Scholar","Marshal","Envoy"]:
		GameState.leadership_positions[office]={"name":{"Steward":"Mira Vale","Quartermaster":"Tarin Moss","Scholar":"Amara Sen","Marshal":"Ilan Reed","Envoy":"Sora Aven"}[office],"person_id":office.hash(),"skills":{"Knowledge":.8,"Administration":.7,"Construction":.6,"Provisioning":.5,"Diplomacy":.5,"Logistics":.5,"Defense":.5}}
	GameState.known_discoveries.append("drainage");GameState.known_discoveries.append("cordage");GameState.known_discoveries.append("food_drying")
	DiscoverySystem.initialize();DiscoverySystem._refresh_active_investigations()
	var n:=0
	for id in GameState.active_investigations.values():GameState.discovery_progress[id]=.17+(n%5)*.15;n+=1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/research"))
	canvas=SubViewport.new();canvas.size=Vector2i(1440,900);canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(canvas)
	var background:=ColorRect.new();background.color=Color("293c32");background.size=Vector2(1800,1100);canvas.add_child(background)
	view=Atlas.new();canvas.add_child(view);await capture("active")
	view.domain="infrastructure";view.show_locked=true;view.set_view("tree");await settle();view.plot.center_selected();await capture("tree")
	view.domain="";view.set_view("known");await capture("known")
	canvas.size=Vector2i(800,600);view._layout();view.set_view("active");await capture("active-small")
	view.set_view("tree");await capture("tree-small")
	view.select(view.selected_id,true);await capture("detail-small")
	view.hide();canvas.size=Vector2i(1440,900)
	var popup:=DiscoveryPopup.announce(null,view,[{"id":"food_drying","day":300},{"id":"drainage","day":300}]);await capture("discovery")
	popup.advance();await capture("discovery-next")
	canvas.size=Vector2i(800,600);popup.layout();await capture("discovery-small")
	popup.close();await settle();WorldSimulation.clear();print("RESEARCH_VISUAL_CAPTURE PASS");get_tree().quit()
