extends "res://tests/popup_production_design_capture.gd"
var issues:Array[String]=[]
class PopulatedProvider extends "res://scripts/hud/content/dock_content_production.gd":
	func tab(sub:int)->Dictionary:
		var result:=super.tab(sub)
		var block:Dictionary=result.blocks[0]
		if block.has("households") and block.households.size()==1:
			var first:Dictionary=block.households[0];var towns:Array=[]
			for i in 19:
				var town:=first.duplicate(true);town.id="test_town_%d" % i;town.city="Alder Ford" if i==0 else "River settlement %d" % i;towns.append(town)
			block.households=towns
		return result

func _run()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):push_error("Requires isolated test userdata");get_tree().quit(2);return
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	Fixture.seed_late()
	var output:=ProjectSettings.globalize_path("res://artifacts/popup-audit/production-density");DirAccess.make_dir_recursive_absolute(output)
	var terrain:=Fixture.CaptureTerrain.new();add_child(terrain)
	var hud:=CaptureHud.new();add_child(hud)
	var provider=PopulatedProvider.new(terrain,hud)
	for canvas:Vector2i in [Vector2i(1600,900),Vector2i(1024,720),Vector2i(2869,1337)]:
		for palette:String in ["dark","light"]:
			T.set_color_mode(palette);provider.view_state.clear()
			var viewport:=SubViewport.new();viewport.size=canvas;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
			var bg:=ColorRect.new();bg.color=T.PAPER_RAISED;bg.size=Vector2(canvas);viewport.add_child(bg)
			var dock:=Dock.new();dock.theme=T.control_theme();dock.position=Vector2(20,20);dock.size=Vector2(Folio.page_width(canvas.x),canvas.y-40);viewport.add_child(dock)
			for page:int in [0,2]:
				dock.present(provider,page);await _settle()
				var queue:=dock.find_child("IllustratedProductionQueue",true,false)
				if page==0:
					await _capture(viewport,output,"daily-%s-%d" % [palette,canvas.x])
					for button:Button in queue.find_children("*","Button",true,false):
						if button.text=="Crafts in use":button.pressed.emit();break
					await _settle();await _capture(viewport,output,"crafts-%s-%d" % [palette,canvas.x])
				else:
					for workspace:String in ["orders","recipes","stock"]:
						queue._show_workspace(workspace);dock.body_scroll.scroll_vertical=0;await _settle()
						await _capture(viewport,output,"%s-%s-%d" % [workspace,palette,canvas.x])
						var browser:Control=queue._selectors.get("lines" if workspace=="orders" else workspace)
						if browser.records.size()>browser.page_size:
							browser.next.pressed.emit();await _settle()
							if browser.choices.get_child_count()>browser.page_size:issues.append("Unbounded "+workspace)
							var last:Dictionary=browser.records[-1];browser.search.text=String(last.title);browser.search.text_changed.emit(browser.search.text);await _settle();browser.select(String(last.key));await _settle()
							if not (last.content as Control).is_visible_in_tree():issues.append("Missing last "+workspace)
							await _capture(viewport,output,"%s-search-%s-%d" % [workspace,palette,canvas.x])
			for report:Array in [["catalog",provider.workshop._equipment_catalog()],["retool",provider.workshop._retool_report(2)]]:
				dock.present(DetailProvider.new(report[1],"Choose a product"),0);await _settle();await _capture(viewport,output,"%s-%s-%d" % [report[0],palette,canvas.x])
			viewport.queue_free();await get_tree().process_frame
	print("PRODUCTION_DENSITY ",issues);get_tree().quit(0 if issues.is_empty() else 1)
