extends Node
## research_600 discovery paintings: every manifest entry loads, shares one size, wins in
## research_visuals, and carries no caption strip. Headless runs assert only; a rendered run
## (tools/run_isolated_gpu_probe.ps1) also captures research cards into reports/research-art/.
const Visuals=preload("res://scripts/hud/research_visuals.gd")
const Atlas=preload("res://scripts/hud/research_atlas.gd")
const DiscoveryPopup=preload("res://scripts/hud/discovery_popup.gd")
const MANIFEST="res://data/research/art_600.json"
const OUT="res://reports/research-art/"
var failures:Array[String]=[]
var canvas:SubViewport
func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)
func settle()->void:
	for frame in 8:await get_tree().process_frame;RenderingServer.force_draw(false)
func capture(file:String)->void:
	if DisplayServer.get_name()=="headless":return
	await settle();canvas.get_texture().get_image().save_png(OUT+file+".png");print("RESEARCH_ART_600 capture ",OUT+file+".png")
func _ready()->void:
	get_window().title="TEST — research_600 discovery art";call_deferred("run")
## Share of near-paper pixels (light, unsaturated) in the bottom band; a caption strip is ~0.9.
static func caption_band_share(image:Image)->float:
	var paper:=0;var total:=0;var band:=maxi(8,int(image.get_height()*.06))
	for y in range(image.get_height()-band,image.get_height()):
		for x in range(0,image.get_width(),2):
			var c:=image.get_pixel(x,y);var hi:=maxf(c.r,maxf(c.g,c.b));var lo:=minf(c.r,minf(c.g,c.b))
			if lo>200.0/255.0 and hi-lo<30.0/255.0:paper+=1
			total+=1
	return float(paper)/float(maxi(total,1))
func run()->void:
	var doc:Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	check(doc is Dictionary and doc.has("items"),"art_600.json parses with items")
	var items:Dictionary=doc.get("items",{}) if doc is Dictionary else {}
	var size:Array=doc.get("size",[512,384]) if doc is Dictionary else [512,384]
	var ids:=[]
	for entry:Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://data/research/research_600.json")).items:ids.append(String(entry.id))
	check(items.size()>=150,"manifest has the extracted paintings (%d)" % items.size())
	var worst:=0.0
	for id:String in items:
		var entry:Dictionary=items[id];var path:=String(entry.get("path",""))
		check(ids.has(id),"manifest id is a research_600 discovery: "+id)
		check(path=="res://assets/ui/research/discovery-600/%s.png" % id,"path follows convention: "+id)
		for key in ["source_sheet","tile_index","caption","style"]:check(entry.has(key),"%s has %s" % [id,key])
		var texture:=load(path) as Texture2D
		check(texture!=null,"loads as Texture2D: "+path)
		if texture==null:continue
		check(texture.get_width()==int(size[0]) and texture.get_height()==int(size[1]),"%s is %dx%d, got %dx%d" % [id,size[0],size[1],texture.get_width(),texture.get_height()])
		check(Visuals.subject_art_key({"id":id})==path,"research_visuals chooses the new painting for "+id)
		check(Visuals.for_discovery({"id":id})!=null,"research_visuals returns a texture for "+id)
		check(Visuals.focus_for({"id":id})==Vector2(.5,.5),"centered focus for "+id)
		var image:=texture.get_image()
		if image.is_compressed():image.decompress()
		var share:=caption_band_share(image);worst=maxf(worst,share)
		check(share<.3,"no caption strip at the bottom of %s (paper share %.2f)" % [id,share])
	check(Visuals.subject_art_key({"id":"tallies","exposed":false})=="","unexposed discoveries still show no art")
	print("RESEARCH_ART_600 entries=%d worst_bottom_paper_share=%.3f" % [items.size(),worst])
	if DisplayServer.get_name()!="headless":await capture_cards(items)
	if failures.is_empty():print("RESEARCH_ART_600 PASS")
	else:print("RESEARCH_ART_600 FAIL ",failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
func capture_cards(items:Dictionary)->void:
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	GameState.reset_for_new_world(424242);MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world();DiscoverySystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(400);GameState.population_allocations["Knowledge"]=24
	GameState.elapsed_days=300;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	var shown:=["route_memory","relay_call_stations","counting_words","weather_sign_reading","novice_task_shadowing","tallies","moon_counting","childrens_question_circles","shared_hearth_gatherings","communal_work_songs"]
	var day:=30
	for id:String in shown:
		if items.has(id) and not GameState.known_discoveries.has(id):GameState.known_discoveries.append(id);GameState.discovery_log.append({"id":id,"day":day});day+=20
	DiscoverySystem.initialize();DiscoverySystem._refresh_active_investigations()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	canvas=SubViewport.new();canvas.size=Vector2i(1440,900);canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(canvas)
	var background:=ColorRect.new();background.color=Color("293c32");background.size=Vector2(1800,1100);canvas.add_child(background)
	var view:=Atlas.new();canvas.add_child(view)
	view.domain="knowledge";view.set_view("known");await settle();view.select("tallies")
	for i in 4:await settle()
	await capture("research-cards-knowledge")
	view.domain="culture";view.set_view("known");await settle();view.select("shared_hearth_gatherings");await capture("research-cards-culture")
	view.hide()
	var popup:=DiscoveryPopup.announce(null,view,[{"id":"moon_counting","day":300}]);await capture("discovery-popup")
	popup.close();await settle();WorldSimulation.clear()
