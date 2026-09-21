extends Node
## Capture-only audit of source illustrations and the actual banner crop.
const Art=preload("res://scripts/hud/research_visuals.gd")
const MilitaryArt=preload("res://scripts/hud/military_roster_visuals.gd")
var military:=false
var canvas:SubViewport
func _ready()->void:
	get_window().title="TEST — Subject art review"
	get_window().mode=Window.MODE_MINIMIZED
	call_deferred("run")
func settle()->void:
	for i in 4:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
func run()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]:node.set_process(false)
	military=OS.get_cmdline_user_args().has("--military")
	var inventory_path:="units" if military else "discoveries"
	var inventory:Array=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/subject-art/"+inventory_path+".json"))
	var available:Array=[]
	for item:Dictionary in inventory:
		if ResourceLoader.exists(MilitaryArt.illustration_path(item.id) if military else Art.subject_art_key(item)):available.append(item)
	available.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return String(a.id)<String(b.id))
	var first:=0;var last:=available.size()
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--first="):first=int(argument.trim_prefix("--first="))
		if argument.begins_with("--last="):last=mini(last,int(argument.trim_prefix("--last=")))
	var destination:="res://artifacts/subject-art/review-military/" if military else "res://artifacts/subject-art/review/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	canvas=SubViewport.new();canvas.size=Vector2i(1600,2320);canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(canvas)
	var index:Dictionary={}
	for start:int in range(first,last,6):
		var page:=Control.new();canvas.add_child(page)
		var back:=ColorRect.new();back.color=Color("0a1419");back.size=Vector2(1600,2320);page.add_child(back)
		var ids:Array=[]
		for offset:int in range(mini(6,last-start)):
			var item:Dictionary=available[start+offset];ids.append(item.id)
			var card:=Control.new();card.position=Vector2(12+(offset%2)*794,10+(offset/2)*770);page.add_child(card)
			var label:=Label.new();label.text=String(item.name)+" / "+String(item.id);label.add_theme_font_size_override("font_size",22);card.add_child(label)
			var source:=TextureRect.new();source.texture=load(MilitaryArt.illustration_path(item.id)) if military else Art.for_discovery(item);source.position=Vector2(0,34);source.size=Vector2(780,500);source.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;source.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;card.add_child(source)
			var banner:Control
			if military:
				var painter:=MilitaryArt.new();page.add_child(painter);banner=painter.portrait(item.id,item.domain);card.add_child(banner)
			else:banner=Art.paint_discovery(card,item,0)
			banner.position=Vector2(0,540);banner.size=Vector2(210,210) if military else Vector2(780,210)
		await settle()
		var name:="page-%03d" % (start/6)
		canvas.get_texture().get_image().save_png(destination+name+".png")
		index[name]=ids
		page.queue_free();await settle()
	var file:=FileAccess.open(destination+"index.json",FileAccess.WRITE);file.store_string(JSON.stringify(index,"\t"));file.close()
	WorldSimulation.clear();print("SUBJECT_ART_REVIEW_CAPTURE ",available.size()," available; captured ",last-first);get_tree().quit()
