extends Node
## TEST capture: every surface that shows discovery paintings, with one wide
## banner painting (about 2.7:1), one classic 3:2 painting and one square one.
## Prints how much of each painting is visible and saves a capture per surface.
## Run only through tools/run_isolated_gpu_probe.ps1.
const Art=preload("res://scripts/hud/research_visuals.gd")
const DiscoveryNotice=preload("res://scripts/hud/discovery_popup.gd")
const ChronicleCard=preload("res://scripts/hud/chronicle_card.gd")
const ResearchView=preload("res://scripts/hud/research_atlas.gd")
const TreePlot=preload("res://scripts/hud/research_tree_plot.gd")
const DockBlocks=preload("res://scripts/hud/dock_blocks.gd")
const OUT:="res://artifacts/wide-discovery-art/"
const DOCK_WIDTH:=492.0
class Host extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value
var canvas:SubViewport
var tag:=""
func _ready()->void:
	get_window().title="TEST — Wide discovery art audit";get_window().mode=Window.MODE_MINIMIZED
	for arg:String in OS.get_cmdline_user_args():if arg.begins_with("--tag="):tag=arg.substr(6)
	call_deferred("run")
func settle(frames:int=8)->void:
	for i in frames:await get_tree().process_frame;RenderingServer.force_draw(false)
func pick(low:float,high:float)->Dictionary:
	for item:Dictionary in DiscoverySystem.technology_catalog:
		var shown:=item.duplicate();shown.exposed=true
		var texture:=Art.for_discovery(shown)
		if texture and texture.get_width()/float(texture.get_height())>=low and texture.get_width()/float(texture.get_height())<=high:return shown
	return {}
## Fraction of the painting's width and height that a control shows.
static func shown(control:Control,source:Texture2D)->Vector2:
	if control==null or source==null or control.size.y<=0:return Vector2.ZERO
	if control is TextureRect and (control as TextureRect).stretch_mode!=TextureRect.STRETCH_KEEP_ASPECT_COVERED:return Vector2.ONE
	if "contain" in control and bool(control.get("contain")):return Vector2.ONE
	return _fraction(source.get_size(),control.size)
static func _fraction(source:Vector2,target:Vector2)->Vector2:
	var ratio:=(target.x/target.y)/(source.x/source.y)
	return Vector2(minf(1.0,ratio),minf(1.0,1.0/ratio))
func painting_in(root:Node,source:Texture2D)->Control:
	var best:Control=null
	for node:Node in root.find_children("*","Control",true,false):
		if not "texture" in node:continue
		var texture:Variant=node.get("texture")
		if not texture is Texture2D or (texture as Texture2D).get_height()<=0:continue
		var aspect:=(texture as Texture2D).get_width()/float((texture as Texture2D).get_height())
		if absf(aspect-source.get_width()/float(source.get_height()))>.03 or not (node as Control).is_visible_in_tree():continue
		if best==null or (node as Control).size.x*(node as Control).size.y>best.size.x*best.size.y:best=node
	return best
func report(surface:String,sample:String,control:Control,source:Texture2D,size_override:=Vector2.ZERO)->void:
	var extent:=size_override if size_override!=Vector2.ZERO else (control.size if control else Vector2.ZERO)
	var fraction:=_fraction(source.get_size(),extent) if size_override!=Vector2.ZERO else shown(control,source)
	print("WIDE_ART %s %s source=%dx%d slot=%dx%d width=%d%% height=%d%% area=%d%%" % [surface,sample,source.get_width(),source.get_height(),roundi(extent.x),roundi(extent.y),roundi(fraction.x*100),roundi(fraction.y*100),roundi(fraction.x*fraction.y*100)])
func capture(name:String)->void:
	canvas.get_texture().get_image().save_png(OUT+"%s%s.png" % [tag+"-" if tag!="" else "",name])
func run()->void:
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]:node.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var samples:={"wide":pick(2.55,2.85),"classic":pick(1.45,1.55),"square":pick(.95,1.05)}
	for key:String in samples:
		if samples[key].is_empty():print("WIDE_ART missing sample ",key);continue
		GameState.known_discoveries.append(String(samples[key].id))
	# Theme the capture the way the game does. Without the game's display
	# preferences, controls inside this SubViewport and the popups' CanvasLayers
	# fall back to Godot's default pale button text on paper.
	var prefs:Node=preload("res://scripts/display_preferences.gd").new();prefs.config_path="user://wide_art_probe_no_display.cfg";add_child(prefs)
	canvas=SubViewport.new();canvas.size=Vector2i(1600,900);canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(canvas)
	var backdrop:=ColorRect.new();backdrop.color=Color("2b2a26");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.add_child(backdrop)
	var host:=Host.new();canvas.add_child(host);var hud:=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);host.add_child(hud)
	for key:String in samples:
		var item:Dictionary=samples[key]
		if item.is_empty():continue
		var id:=String(item.id);var source:=Art.for_discovery(item)
		print("WIDE_ART sample ",key," ",id," ",source.resource_path)
		# 1. The discovery announcement.
		var popup:=DiscoveryNotice.announce(host,hud,[{"id":id,"day":1129}]);await settle(90)
		report("popup",key,popup.hero,source);capture("popup-"+key)
		popup.close();await settle()
		# 2. The chronicle moment card.
		var card:CanvasLayer=ChronicleCard.new();card.terrain=host;card.hud=hud;hud.add_child(card);await settle(2)
		card.queue.append({"kind":"discovery","title":String(item.name),"text":String(item.get("description","")),"day":1129,"art":{"discovery_id":id,"domain":String(item.get("domain",""))}})
		card._next();await settle(40)
		report("chronicle_card",key,painting_in(card.panel,source),source);capture("chronicle-card-"+key)
		card.queue_free();await settle(2)
		# 3. Research atlas: established cards and the detail column.
		var view:=ResearchView.new();canvas.add_child(view);view.set_view("known");view.select(id);await settle(20)
		if view.bindings.has(id):report("atlas_card",key,view.bindings[id].painting,source)
		report("atlas_detail",key,painting_in(view.detail_body,source),source);capture("atlas-"+key)
		# 4. Knowledge tree node.
		view.show_locked=true;view.set_view("tree");view.select(id);view.plot.center_selected();await settle(12)
		var plot_script:Script=TreePlot;var image_size:Vector2=plot_script.get_script_constant_map().get("IMAGE",Vector2(TreePlot.CARD.x-28,72))
		report("tree_node",key,null,source,image_size);capture("tree-"+key)
		view.queue_free();await settle(2)
		# 5-7. Dock sheets: discovery block, inquiry board, settlement chronicle.
		var sheet:=PanelContainer.new();sheet.position=Vector2(80,24);sheet.custom_minimum_size=Vector2(DOCK_WIDTH+48,0)
		sheet.add_theme_stylebox_override("panel",preload("res://scripts/hud/hud_tokens.gd").paper_panel_style(false,4,24));canvas.add_child(sheet)
		var column:=VBoxContainer.new();column.custom_minimum_size.x=DOCK_WIDTH;sheet.add_child(column)
		DockBlocks.render(column,[{"type":"discovery","kind":"discovery","discovery_id":id,"title":String(item.name),"description":String(item.get("description",""))}])
		await settle(12);report("dock_block",key,painting_in(column,source),source);capture("dock-block-"+key)
		for child in column.get_children():column.remove_child(child);child.queue_free()
		DockBlocks.render(column,[{"type":"inquiry_board","investigations":[{"id":id,"dynamic":String(item.get("domain","knowledge")),"name":String(item.name),"progress":.4,"research_workforce":3.0,"bottleneck":"Gathering evidence"}],"fields":[],"on_tree":func()->void:pass,"on_work":func()->void:pass,"on_domain":func(_d:String)->void:pass}])
		await settle(12);report("inquiry_board",key,painting_in(column,source),source);capture("inquiry-"+key)
		for child in column.get_children():column.remove_child(child);child.queue_free()
		DockBlocks.render(column,[{"type":"chronicle","events":[{"id":id,"day":1129,"kind":"Discovery","scope":"Settlement","title":String(item.name),"description":String(item.get("description",""))}]}])
		await settle(12);report("settlement_chronicle",key,painting_in(column,source),source);capture("settlement-chronicle-"+key)
		sheet.queue_free();await settle(2)
	WorldSimulation.clear();print("WIDE_ART_CAPTURE PASS");get_tree().quit(0)
