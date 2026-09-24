extends Node
## Artifacts & Allure gallery probe. Headless: behavior checks, prints
## "ARTIFACT_GALLERY PASS". Windowed with `-- --shots=<dir> --mode=light|dark`
## it also saves review captures of the culture entry, grid, detail, sets and rumors.
const Gallery:=preload("res://scripts/hud/artifact_gallery.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const A:=preload("res://scripts/artifact_collection.gd")
const Art:=preload("res://scripts/hud/artifact_visuals.gd")
const Early:=preload("res://scripts/early_civ_artifacts.gd")

var failures:Array[String]=[]
var game_speed:=3.0
var shots:=""
var mode:="light"

func _set_game_speed(value:float)->void:game_speed=value

func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)

## Stand-in with the exact facade signatures from docs/ARTIFACT_CULTURE_DESIGN.md.
class Stub:
	static var items:Array=[]
	static var focus:=""
	static func populate()->void:
		items.clear();focus=""
		var sets:=[["Hoard of the Ochre Hands","Ochre Hands rock shelter",7],["Grave goods of the River Folk","Burial mound above the ford",6]]
		var stories:=["Its maker pressed a hand in red earth against the stone and left it for whoever came after.","Soot from a long-cold hearth still darkens the rim; it fed a family through a hard winter.","The marks were cut with care, in rows, as if someone were counting days or debts.","It was carried far from where the stone was quarried, then set down and never taken up again."]
		var styles:=["etched","painted","banded","spiraling","weathered"];var motifs:=["river","sun","herd","hand","ancestor"]
		var point:=0;var index:=0
		while items.size()<60 and point<4000:
			var record:=A.find_at(777,Vector2(point*24*5,300+point%7*24),1);point+=1
			var texture:=Art.texture(record)
			if texture==null:continue
			var state:String=["studied","in_study","unstudied","unstudied","studied"][index%5]
			var progress:=1.0 if state=="studied" else (.2+.15*(index%5) if state=="in_study" else (0.0 if index%3==0 else .08*(index%4)))
			var rarity:int=[0,1,0,2,1,3,0,4,2,1][index%10]
			var item:={"id":"a%02d" % index,"name":String(record.name),"object":String(record.get("form","object")),"style":styles[index%5],"motif":motifs[index%5],"material":String(record.get("material","stone")),
				"rarity":Gallery.TIER_NAMES[rarity],"rarity_index":rarity,"origin":"Prehistoric find","found_day":40+index*37,"held_days":1200-index*17,"prestige":pow(2.5,rarity)*1.3,"appraisal":20*pow(2.5,rarity)*1.3,
				"study_progress":progress,"state":state,"value":{"culture":.012*(rarity+1),"research":.009*(rarity+1),"economic":2.5*(rarity+1)} if state=="studied" else {"culture":0.0,"research":0.0,"economic":0.0},
				"research_subject":String(record.get("discovery_id","oral_epics")),"exhibited":state=="studied" and index%3==0,"can_exhibit":state=="studied",
				"story":stories[index%stories.size()],"texture":texture}
			if index<9:
				var group:Array=sets[index%2]
				item.site_name=group[1];item.set_name=group[0];item.set_progress="%d of %d" % [5 if index%2==0 else 4,group[2]]
			items.append(item);index+=1
		for form:int in [3,4,6,11,12]:
			var crafted:={"kind":"artifact","catalogue_id":form,"art_collection":"early-civ-v1","artifact_origin":"civilization","source_id":"cedar","maker_requirements":Early.REQUIREMENTS[form].duplicate(),"name":"Crafted piece"}
			var tex:=Art.texture(crafted)
			if tex==null:continue
			items.append({"id":"c%02d" % form,"name":["","","","Clay ceremonial bowl · etched river","Woven fragment · etched river","","Wood measuring rod · etched river","","","","","Wood painted panel · etched river","Clay storage jar · etched river"][form],"object":"ceremonial bowl","style":"etched","motif":"river","material":"clay",
				"rarity":"Legendary" if form==3 else "Exceptional","rarity_index":4 if form==3 else 3,"origin":"Gift of Cedar River","found_day":900,"held_days":400,"prestige":50.0,"appraisal":900.0,"study_progress":1.0 if form!=12 else .55,"state":"studied" if form!=12 else "in_study",
				"value":{"culture":.08,"research":.05,"economic":30.0},"research_subject":"pit_firing","exhibited":form==3,"can_exhibit":form!=12,"story":"Carried upriver as a gift of friendship, it was filled at the naming of every child in Cedar River for three generations.","texture":tex})
	static func summary()->Dictionary:
		var counts:={"studied":0,"in_study":0,"unstudied":0};var shown:=0;var prestige:=0.0
		var totals:={"culture":0.0,"research":0.0,"economic":0.0}
		for item:Dictionary in items:
			counts[item.state]+=1;prestige+=float(item.prestige)
			if item.exhibited:shown+=1
			for key in totals:totals[key]+=float(item.value[key])
		var allure:=clampf(.18+.02*shown+.004*counts.studied,0,1)
		return {"allure":allure,"allure_label":"admired","allure_breakdown":[{"source":"Studied pieces","value":.004*counts.studied,"text":"Understood objects others want to see"},{"source":"Exhibits","value":.02*shown,"text":"Public galleries"},{"source":"Cultural capacity","value":.1,"text":"Shared memory and cohesion"},{"source":"Openness","value":.08,"text":"Pluralist, open values"}],
			"allure_effects":[{"target":"Diplomacy","text":"Foreign envoys receive us more warmly (+4 reception).","value":4.0},{"target":"Migration","text":"Newcomers settle 6% more readily.","value":.06},{"target":"Museum","text":"Exhibits draw about 12 more visitors a month.","value":12.0}],
			"collection_count":items.size(),"studied_count":counts.studied,"in_study_count":counts.in_study,"unstudied_count":counts.unstudied,"exhibited_count":shown,"prestige_total":prestige,"value_totals":totals,
			"study_role":{"allocation_key":"artifacts","weight":2.0,"workers":4,"rate_text":"about 1.6 study-days per day","focus_id":focus}}
	static func artifacts(query:Dictionary={})->Dictionary:
		var status:=String(query.get("status","all"));var text:=String(query.get("search","")).to_lower()
		var result:Array=[]
		for item:Dictionary in items:
			if status=="exhibited" and not item.exhibited:continue
			if status in ["studied","in_study","unstudied"] and item.state!=status:continue
			if not text.is_empty() and not (String(item.name)+" "+String(item.material)+" "+String(item.motif)+" "+String(item.get("site_name",""))).to_lower().contains(text):continue
			result.append(item)
		match String(query.get("sort","rarity")):
			"recent":result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.found_day)>int(b.found_day))
			"prestige":result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.prestige)>float(b.prestige))
			_:result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.rarity_index)>int(b.rarity_index) if a.rarity_index!=b.rarity_index else String(a.id)<String(b.id))
		var size:=maxi(1,int(query.get("page_size",24)));var pages:=maxi(1,ceili(float(result.size())/size));var page:=clampi(int(query.get("page",0)),0,pages-1)
		return {"items":result.slice(page*size,(page+1)*size),"total":result.size(),"page":page,"pages":pages}
	static func artifact(id:String)->Dictionary:
		for item:Dictionary in items:
			if item.id==id:return item
		return {}
	static func set_study_focus(id:String)->Dictionary:
		var item:=artifact(id)
		if item.is_empty() or item.state=="studied":return {"error":"Nothing to study."}
		focus=id;item.state="in_study";return {"ok":true}
	static func set_exhibited(id:String,on:bool)->Dictionary:
		var item:=artifact(id)
		if item.is_empty() or (on and not item.can_exhibit):return {"error":"Cannot exhibit."}
		item.exhibited=on;return {"ok":true}
	static func rumored_sites(_observer:String="player")->Array:
		return [{"id":"r1","name":"The Sunken Shrine of Nine Bowls","hint":"Past the second bend of the great river, where the reeds hide a ring of standing stones, fishers say bowls rise from the mud in dry summers.","confidence":.72,"known_since_day":820,"found":false},
			{"id":"r2","name":"Barrow of the Antler King","hint":"Three days toward the morning sun, a lone hill shaped like a sleeping elk.","confidence":.4,"known_since_day":1030,"found":false},
			{"id":"r3","name":"Ochre Hands rock shelter","hint":"A cliff that bleeds red after rain, above the northern ford.","confidence":.9,"known_since_day":300,"found":true},
			{"id":"r4","name":"The Salt-Road Cache","hint":"Traders whisper of a cache buried where the salt road once crossed a dry wash.","confidence":.18,"known_since_day":1200,"found":false}]

func _ready()->void:
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="):shots=argument.trim_prefix("--shots=")
		elif argument.begins_with("--mode="):mode=argument.trim_prefix("--mode=")
	if DisplayServer.get_name()=="headless":shots=""
	T.set_color_mode(mode)
	for node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	get_tree().current_scene=self
	Stub.populate()
	check(Stub.items.size()>=40,"Stub collection seeded with real artwork (%d)" % Stub.items.size())
	await _check_showcase()
	await _check_gallery()
	await _check_real_facade()
	print("ARTIFACT_GALLERY ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)

func _frames(count:int=4)->void:
	for i in count:await get_tree().process_frame

func _shot(name:String)->void:
	if shots.is_empty():return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(shots)
	var path:=shots.path_join("%s-%s.png" % [name,mode])
	get_viewport().get_texture().get_image().save_png(path)
	print("SHOT ",path)

func _check_showcase()->void:
	GameState.reset_for_new_world(991704)
	var host:=Control.new();host.name="FakeHud";host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(host)
	host.add_user_signal("section_requested",[{"name":"section","type":TYPE_STRING},{"name":"sub","type":TYPE_INT}])
	var backdrop:=ColorRect.new();backdrop.color=Color("56613f") if mode=="light" else Color("1d2a24");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);host.add_child(backdrop)
	var provider=load("res://scripts/hud/content/dock_content_civilization.gd").new(null,host)
	provider.artifact_source=Stub
	var blocks:Array=[]
	var built:Variant=provider.tab(0)
	if built is Dictionary:blocks=built.get("blocks",[])
	check(not blocks.is_empty() and blocks[0].has("artifacts"),"Culture block carries the Artifacts & Allure entry")
	var dock:=PanelContainer.new();dock.theme=T.control_theme();dock.position=Vector2(T.DOCK_X,8);dock.size=Vector2(T.DOCK_WIDTH,get_viewport().get_visible_rect().size.y-16)
	var dock_style:=T.dock_style();dock_style.set_content_margin_all(18);dock.add_theme_stylebox_override("panel",dock_style);host.add_child(dock)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;dock.add_child(scroll)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	DockBlocks.render(body,blocks)
	await _frames(6)
	var showcase:=body.find_child("ArtifactShowcase",true,false) as Control
	check(showcase!=null,"Showcase rendered inside the Culture panel")
	if showcase==null:host.queue_free();return
	check(showcase.find_child("ShowcaseShelf",true,false)!=null and showcase.find_child("ShowcaseShelf",true,false).get_child_count()==4,"Four finest pieces on the shelf")
	check(dock.get_global_rect().encloses(showcase.get_global_rect().grow(-1)) or showcase.size.x<=T.DOCK_WIDTH,"Showcase fits the dock width")
	scroll.scroll_vertical=int(maxf(0,showcase.position.y-260))
	await _frames(3)
	await _shot("culture-entry")
	var open_button:=showcase.find_child("OpenArtifactGallery",true,false) as Button
	check(open_button!=null,"Open the collection button exists")
	if open_button:
		open_button.pressed.emit()
		await _frames(4)
		var layer:Variant=host.get_meta("artifact_gallery",null)
		check(is_instance_valid(layer) and layer.get_child_count()==1,"Entry point opens the gallery")
		if is_instance_valid(layer):layer.queue_free()
		await _frames(2)
	host.queue_free();await _frames(2)

func _gallery_open(focus:String="")->Control:
	var gallery:=Gallery.open(self,null,focus,Stub)
	await _frames(6)
	return gallery

func _cards(gallery:Control)->Array:
	var grid:=gallery.find_child("ArtifactGrid",true,false)
	return grid.get_children() if grid else []

func _check_gallery()->void:
	game_speed=3.0
	var backdrop:=ColorRect.new();backdrop.color=Color("56613f");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var gallery:=await _gallery_open()
	check(game_speed==0.0,"Opening the gallery pauses the simulation")
	var screen:=Rect2(Vector2.ZERO,gallery.get_viewport_rect().size)
	if not screen.encloses(gallery.panel.get_global_rect()):
		var parts:=[]
		for node:Control in [gallery.header,gallery.main,gallery.browse,gallery.browse_scroll,gallery.pager,gallery.detail_scroll,gallery.detail_scroll.get_parent()]:parts.append("%s:%s" % [node.name,node.get_combined_minimum_size()])
		check(false,"Gallery panel %s fits the screen %s; minimums %s" % [gallery.panel.get_global_rect(),screen,parts])
	var total:=Stub.items.size()
	check(_cards(gallery).size()==Gallery.PAGE_SIZE,"First page shows %d cards (got %d)" % [Gallery.PAGE_SIZE,_cards(gallery).size()])
	check(String(gallery.pager_label.text).contains("of %d" % ceili(float(total)/Gallery.PAGE_SIZE)),"Pager counts pages: "+gallery.pager_label.text)
	check(gallery.seal.value>0,"Allure seal shows a value")
	check(gallery.effects_box.get_child_count()==3,"Allure effects explained in words")
	var first_card=_cards(gallery)[0]
	check(first_card.item.rarity_index==4,"Rarity sort puts legendary first")
	check(gallery.find_child("CataloguePlate",true,false)!=null,"Detail plate shown for the first piece")
	await _shot("gallery-grid")
	# paging
	gallery.next_button.pressed.emit();await _frames(3)
	check(gallery.page==1 and _cards(gallery).size()==mini(Gallery.PAGE_SIZE,total-Gallery.PAGE_SIZE),"Second page")
	gallery.next_button.pressed.emit();await _frames(3)
	check(_cards(gallery).size()==total-2*Gallery.PAGE_SIZE,"Last page holds the remainder")
	check(gallery.next_button.disabled,"Next disabled on the last page")
	# filters
	gallery.tab_buttons["studied"].pressed.emit();await _frames(3)
	check(gallery.page==0,"Changing view resets the page")
	var studied_ok:=true
	for card in _cards(gallery):studied_ok=studied_ok and card.item.state=="studied"
	check(studied_ok and not _cards(gallery).is_empty(),"Studied view shows only studied pieces")
	gallery.tab_buttons["exhibited"].pressed.emit();await _frames(3)
	var shown_ok:=true
	for card in _cards(gallery):shown_ok=shown_ok and card.item.exhibited
	check(shown_ok and _cards(gallery).size()==int(Stub.summary().exhibited_count),"On exhibit view")
	gallery.tab_buttons["all"].pressed.emit();await _frames(2)
	gallery.search.text="clay";gallery.search.text_changed.emit("clay");await _frames(3)
	var matched:=_cards(gallery)
	var search_ok:=not matched.is_empty()
	for card in matched:search_ok=search_ok and (String(card.item.name)+String(card.item.material)).to_lower().contains("clay")
	check(search_ok,"Search narrows to matching pieces (%d)" % matched.size())
	gallery.search.text="";gallery.search.text_changed.emit("");await _frames(2)
	# detail + actions on an unstudied piece
	var target:Dictionary={}
	for item:Dictionary in Stub.items:
		if item.state=="unstudied" and item.rarity_index>=2:target=item;break
	check(not target.is_empty(),"An unstudied rare piece exists")
	gallery.tab_buttons["unstudied"].pressed.emit();await _frames(2)
	gallery.select(String(target.id));await _frames(3)
	var plate:=gallery.find_child("CataloguePlate",true,false)
	check(plate!=null and _has_text(plate,String(target.name)),"Detail plate names the selected piece")
	check(gallery.find_child("StudyProgress",true,false)!=null,"Unstudied plate shows study progress")
	check(gallery.find_child("OpenResearchAllocation",true,false)!=null,"Study team links to the research allocation")
	var focus_button:=gallery.find_child("StudyFocusButton",true,false) as Button
	check(focus_button!=null and not focus_button.disabled,"Study focus action available")
	if focus_button:focus_button.pressed.emit();await _frames(3)
	check(Stub.focus==String(target.id),"Make this the study focus reaches the facade")
	check(gallery.find_child("ActionMessage",true,false)!=null,"Action feedback shown")
	var focus_after:=gallery.find_child("StudyFocusButton",true,false) as Button
	check(focus_after!=null and focus_after.disabled and focus_after.text=="Current study focus","Focus button reflects the new focus")
	# exhibit a studied piece
	var show_target:Dictionary={}
	for item:Dictionary in Stub.items:
		if item.state=="studied" and not item.exhibited and item.rarity_index>=1:show_target=item;break
	gallery.tab_buttons["all"].pressed.emit();await _frames(2)
	gallery.select(String(show_target.id));await _frames(3)
	var exhibit:=gallery.find_child("ExhibitButton",true,false) as Button
	check(exhibit!=null and not exhibit.disabled and exhibit.text=="Put on exhibit","Exhibit action available for a studied piece")
	if exhibit:exhibit.pressed.emit();await _frames(3)
	check(bool(Stub.artifact(String(show_target.id)).exhibited),"Put on exhibit reaches the facade")
	check((gallery.find_child("ExhibitButton",true,false) as Button).text=="Return to the storeroom","Exhibit button toggles")
	# detail capture: a legendary studied piece
	gallery.select("c03");await _frames(4)
	await _shot("gallery-detail")
	var detail_scroll:=gallery.find_child("DetailScroll",true,false) as ScrollContainer
	detail_scroll.scroll_vertical=100000;await _frames(3)
	await _shot("gallery-detail-lower")
	gallery.select(String(target.id));await _frames(3)
	detail_scroll.scroll_vertical=0;await _frames(2)
	await _shot("gallery-detail-unstudied")
	# sets
	gallery.tab_buttons["sets"].pressed.emit();await _frames(4)
	var set_panels:=0;var ghosts:=0
	for node in gallery.browse_body.get_children():
		if String(node.name).begins_with("Set_"):set_panels+=1;ghosts+=_count_class(node,"Silhouette")
	check(set_panels==2,"Two lost-people sets grouped (%d)" % set_panels)
	check(ghosts==4,"Missing set pieces drawn as silhouettes (%d)" % ghosts)
	check(not gallery.pager.visible,"Sets view has no pager")
	await _shot("gallery-sets")
	# rumors
	gallery.tab_buttons["rumors"].pressed.emit();await _frames(4)
	var notes:=gallery.find_child("RumorNotes",true,false)
	check(notes!=null and notes.get_child_count()==4,"Rumored treasures listed as notes")
	await _shot("gallery-rumors")
	# large collections page without building thousands of cards
	var extra:=Stub.items.duplicate()
	for i in 2000:
		var copy:Dictionary=extra[i%extra.size()].duplicate();copy.id="bulk%04d" % i;Stub.items.append(copy)
	gallery.tab_buttons["all"].pressed.emit();await _frames(3)
	check(_cards(gallery).size()==Gallery.PAGE_SIZE and gallery.pager_label.text.contains("of %d" % ceili(float(Stub.items.size())/Gallery.PAGE_SIZE)),"Thousands of pieces paginate: "+gallery.pager_label.text)
	# escape closes and releases the pause
	var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
	get_viewport().push_input(escape)
	await _frames(4)
	check(not is_instance_valid(gallery),"Escape closes the gallery")
	check(game_speed==3.0,"Closing restores the previous speed (%s)" % game_speed)
	Stub.populate()
	backdrop.queue_free()

func _check_real_facade()->void:
	var facade:Variant=Gallery.facade()
	if facade==null:
		print("ARTIFACT_GALLERY NOTE real facade scripts/artifact_culture.gd not present; stub-only run")
		return
	GameState.reset_for_new_world(777)
	var data:Dictionary=GameState.society_exchange
	var made:=0;var point:=0
	while made<12 and point<500:
		var record:=A.find_at(777,Vector2(point*24*3,900),1);point+=1
		if Art.texture(record)==null:continue
		record.study=[0.0,.4,1.0][made%3];record.exhibited=made%6==2;record.held_days=float(made*90)
		data.collections[record.id]=record;made+=1
	var summary:Dictionary=facade.summary()
	check(int(summary.get("collection_count",0))>=made,"Real facade counts the seeded collection")
	var gallery:=Gallery.open(self,null,"",null)
	await _frames(6)
	check(gallery.source==facade,"Gallery reads the real facade by default")
	check(_cards(gallery).size()==mini(made,Gallery.PAGE_SIZE),"Real facade pieces appear as cards (%d)" % _cards(gallery).size())
	check(gallery.find_child("CataloguePlate",true,false)!=null,"Real facade detail plate renders")
	await _shot("gallery-real-facade")
	var more:=gallery.find_child("StudyWeightMore",true,false) as Button
	if facade.has_method("study_weight") or more!=null:
		var before:int=facade.study_weight()
		check(more!=null,"Study team offers inline research-weight control")
		if more:more.pressed.emit();await _frames(2)
		check(int(facade.study_weight())==before+1,"Inline control changes the artifact-study research weight")
		facade.set_study_weight(before)
	else:print("ARTIFACT_GALLERY NOTE facade has no study-weight API; inline control hidden")
	gallery.close();await _frames(2)

func _has_text(node:Node,text:String)->bool:
	if node is Label and (node as Label).text==text:return true
	for child in node.get_children():
		if _has_text(child,text):return true
	return false

func _count_class(node:Node,class_hint:String)->int:
	var count:=0
	for child in node.get_children():
		var script:Script=child.get_script()
		if script!=null and child.get_class()=="Control" and not child is Container and child.tooltip_text.begins_with("A missing piece"):count+=1
		count+=_count_class(child,class_hint)
	return count
