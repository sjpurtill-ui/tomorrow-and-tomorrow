extends Node
## Private-desktop visual evidence. All state comes from the existing disposable
## production fixture; no campaign is loaded or saved.
const Fixture=preload("res://tests/hoi4_production_capture.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Dock=preload("res://scripts/hud/dock_panel.gd")
const Folio=preload("res://scripts/hud/reference_folio.gd")

class CaptureHud extends Control:
	signal section_requested(section:String,sub:int)
	var detail:Object
	func request_immediate_dock_refresh()->void:pass
	func open_detail(provider:Object)->void:detail=provider

class DetailProvider extends RefCounted:
	var report:Dictionary
	var title:String
	func _init(data:Dictionary,caption:String="Workshop order")->void:report=data;title=caption
	func meta()->Dictionary:return {"title":title,"eyebrow":"Production","subtabs":[]}
	func tab(_sub:int)->Dictionary:return report
	func signature()->Array:return []

func _ready()->void:call_deferred("_run")
func _arg(key:String,fallback:String)->String:
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--"+key+"="):return argument.get_slice("=",1)
	return fallback

func _run()->void:
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	if _arg("state","early")=="late":Fixture.seed_late()
	else:Fixture.seed_early()
	var output:=_arg("out",OS.get_user_data_dir())
	var tag:=_arg("tag","capture")
	var terrain:=Fixture.CaptureTerrain.new();add_child(terrain)
	var hud:=CaptureHud.new();add_child(hud)
	var provider=preload("res://scripts/hud/content/dock_content_production.gd").new(terrain,hud)
	for canvas:Vector2i in [Vector2i(1440,900),Vector2i(1000,760)]:
		for palette:String in ["light","dark"]:
			T.set_color_mode(palette)
			var viewport:=SubViewport.new();viewport.size=canvas;viewport.transparent_bg=false;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
			var bg:=ColorRect.new();bg.color=Color("29372f");bg.size=Vector2(canvas);viewport.add_child(bg)
			var dock:=Dock.new();dock.theme=T.control_theme();dock.position=Vector2(24,20);dock.size=Vector2(Folio.page_width(canvas.x),canvas.y-40);viewport.add_child(dock)
			for page:Array in [[0,"overview"],[1,"civilian"],[2,"military"]]:
				dock.present(provider,int(page[0]))
				await _settle()
				await _capture(viewport,output,"production-%s-%s-%s-%d" % [tag,page[1],palette,canvas.x])
				if int(page[0])==2:
					dock.body_scroll.scroll_vertical=int(dock.body.get_combined_minimum_size().y)
					await _settle()
					await _capture(viewport,output,"production-%s-workshops-%s-%d" % [tag,palette,canvas.x])
				if int(page[0]) in [0,2]:
					var disclosure:Button=dock.find_child("FlowDisclosure",true,false)
					disclosure.button_pressed=true
					await _settle()
					dock.body_scroll.scroll_vertical=int(dock.body.get_combined_minimum_size().y)
					await _settle()
					await _capture(viewport,output,"production-%s-flow%d-%s-%d" % [tag,page[0],palette,canvas.x])
			dock.present(DetailProvider.new(provider.workshop._workshop_job_report(2)),0)
			await _settle()
			await _capture(viewport,output,"production-%s-detail-%s-%d" % [tag,palette,canvas.x])
			for report:Array in [["catalog","Choose a product",provider.workshop._equipment_catalog()],["management","Workshop management",provider.workshop._workshop_management_report()],["retool","Change product",provider.workshop._retool_report(2)],["order","Order spears",provider.workshop._equipment_order_report("spear")],["history","Output history",provider._history()]]:
				dock.present(DetailProvider.new(report[2],report[1]),0)
				await _settle()
				await _capture(viewport,output,"production-%s-%s-%s-%d" % [tag,report[0],palette,canvas.x])
			provider.workshop.production_mode=2
			dock.present(DetailProvider.new(provider.workshop._equipment_order_report("spear"),"Make a batch"),0)
			await _settle()
			await _capture(viewport,output,"production-%s-batch-%s-%d" % [tag,palette,canvas.x])
			provider.workshop.production_mode=0
			viewport.queue_free()
			await get_tree().process_frame
	print("POPUP_PRODUCTION_CAPTURE PASS")
	get_tree().quit(0)

func _settle()->void:
	for frame in 12:await get_tree().process_frame
	await RenderingServer.frame_post_draw
func _capture(viewport:SubViewport,folder:String,label:String)->void:
	var path:=folder.path_join(label+".png")
	viewport.get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED ",path)
