extends Node
## The Known World (World › first tab). Headless: builds the board in four
## states — no contact, rumors only, contacted peoples with scouts away, many
## findings — checks content and that every action reaches the right function,
## and prints "KNOWN_WORLD PASS". Windowed with `-- --shots=<dir>` it also saves
## review captures (early stone-age state and a later state with three peoples,
## light and dark).
const Content:=preload("res://scripts/hud/content/dock_content_world.gd")
const Board:=preload("res://scripts/hud/known_world_board.gd")
const DockPanel:=preload("res://scripts/hud/dock_panel.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const A:=preload("res://scripts/artifact_collection.gd")
const Art:=preload("res://scripts/hud/artifact_visuals.gd")
const ArchiveProvider:=preload("res://scripts/hud/content/dock_detail_scout_archive.gd")
const ReportProvider:=preload("res://scripts/hud/content/dock_detail_scout_report.gd")
const CivReport:=preload("res://scripts/hud/content/dock_detail_civ_report.gd")
const SEED:=424242

var failures:Array[String]=[]
var shots:=""
var errors:=0

class ErrorCount extends Logger:
	var probe:Node
	func _log_error(_function:String,_file:String,_line:int,_code:String,rationale:String,_editor_notify:bool,error_type:int,_script_backtrace:Array[ScriptBacktrace])->void:
		if error_type!=ERROR_TYPE_WARNING and probe!=null:probe.set("errors",int(probe.get("errors"))+1);printerr("counted error: ",rationale)
	func _log_message(_message:String,_error:bool)->void:pass

class Director extends Node:
	var summoned:Array=[]
	func summon(target:Dictionary)->Control:summoned.append(target);return null

class ProbeTerrain extends Node:
	var plans:=0
	var envoys:=0
	var courts:Array=[]
	var speed:=1.0
	func _open_scout_dispatch_panel()->void:plans+=1
	func _open_diplomat_dispatch_panel(_civ:String="",_purpose:String="goodwill")->void:envoys+=1
	func _diplomat_action_presentation(_status:Dictionary,known:int)->Dictionary:return {"label":"SEND DIPLOMAT","disabled":known==0,"tooltip":"Envoys walk to a located hearth."}
	func open_court_for(target:Dictionary)->void:courts.append(target)
	func _set_game_speed(value:float)->void:speed=value

class ProbeHud extends Control:
	var opened:Array=[]
	func open_detail(provider:Object,_sub:int=0)->void:opened.append(provider)

func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)

func _ready()->void:
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="):shots=argument.trim_prefix("--shots=")
	if DisplayServer.get_name()=="headless":shots=""
	if ClassDB.class_exists("Logger"):
		var logger:=ErrorCount.new();logger.probe=self;OS.add_logger(logger)
	for node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	get_tree().current_scene=self
	if not shots.is_empty():
		DirAccess.make_dir_recursive_absolute(shots)
		get_window().size=Vector2i(1600,900);get_window().content_scale_size=Vector2i(1920,1080)
	# 1 · no contact, nothing returned yet
	_setup(16)
	await _scenario_empty()
	# 2 · rumors only, the user's stone-age state: 26 returns, one party away
	_setup(16)
	_seed_reports(26,true)
	_seed_mission(1,"OPEN EXPLORATION","northeast",.35,Vector2(1,-1))
	_seed_leads()
	await _scenario_early()
	# 3 · three peoples met, two parties away, a later era
	_setup(48)
	GameState.known_discoveries.append_array(["seed_selection","pit_firing","pictographic_records","copper_smelting"])
	_seed_reports(34,true)
	_seed_contacts()
	_seed_mission(1,"OPEN EXPLORATION","south",.62,Vector2(0.2,1))
	_seed_mission(2,"INVESTIGATE LEAD · Reed People","west",.2,Vector2(-1,.1))
	_seed_leads()
	await _scenario_later()
	# 4 · a very long record
	_setup(60)
	_seed_reports(120,true)
	await _scenario_many()
	check(errors==0,"%d engine errors were logged" % errors)
	print("KNOWN_WORLD ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)

# ---------------------------------------------------------------- state

func _setup(year:int)->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(140);GameState.housing_capacity=200
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.settlement_name="Ashford"
	GameState.elapsed_days=float(year*365+31)
	GovernmentPeopleSystem.initialize()
	CivilizationSystem.initialize()
	CivilizationSystem.scout_reports.clear();CivilizationSystem.scout_missions.clear()

func _route(direction:Vector2,reach:float,bend:float,steps:int=7)->Array:
	var home:=CivilizationSystem.player_world_origin
	var route:Array=[]
	var dir:=direction.normalized();var side:=Vector2(-dir.y,dir.x)
	for i:int in steps:
		var t:=float(i)/float(steps-1)
		var p:=home+dir*reach*t+side*sin(t*PI)*bend
		route.append({"x":p.x,"z":p.y})
	return route

func _seed_reports(count:int,artifacts:bool)->void:
	var home:=CivilizationSystem.player_world_origin
	var journals:=[["They crossed broadleaf woodland for three days."],["They forded running water twice."],["The land rose to high bare ground above the treeline."],["Open drylands, then dunes."],["Grassland without end."]]
	var resources:=["Timber","Stone","Fiber Plants","Game","Clay","Fertile Soil"]
	var seeded:=0
	var point:=0
	var collections:Dictionary=WorldSimulation.state.society_exchange.collections
	for index:int in count:
		var angle:=float(index)*2.39996
		var dir:=Vector2(cos(angle),sin(angle))
		var reach:=60.0+float(index%7)*22.0
		var route:=_route(dir,reach,float((index%5)-2)*9.0)
		var discoveries:Array=[{"kind":"knowledge","title":"A wider world, carried home","description":"Routine observations"}]
		var tip:Dictionary=route[route.size()-1]
		if index%3==0:
			discoveries.append({"kind":"resource","title":"%s marked" % resources[index%resources.size()],"resource":resources[index%resources.size()],"description":"The walkers marked %s." % resources[index%resources.size()].to_lower(),"position":{"x":float(tip.x)+4.0,"z":float(tip.z)-3.0}})
		if artifacts and index%2==0:
			var record:Dictionary={}
			while point<4000:
				var candidate:=A.find_at(SEED,Vector2(point*24*5,300+point%7*24),1);point+=1
				if _importable(Art.image_path(candidate)) and Art.texture(candidate)!=null and not collections.has(String(candidate.id)):record=candidate;break
			if not record.is_empty():
				record["returned_day"]=int(GameState.elapsed_days)-index*9;record["study"]=[0.0,.4,1.0][seeded%3];seeded+=1
				collections[String(record.id)]=record
				discoveries.append({"kind":"artifact","title":String(record.name),"description":"Found on the road","consequence":"Study it.","collection_id":String(record.id),"position":{"x":float(tip.x)-5.0,"z":float(tip.z)+4.0}})
		if index==5:discoveries.append({"kind":"hearsay","title":"A name beyond the horizon","description":"Travelers spoke of the Reed People."})
		var report:={"mission_id":count-index+3,"day":int(GameState.elapsed_days)-index*9-2,"duration_days":18+index%9,"actual_days":18+index%9,"personnel":6,"returned_personnel":6,"lost_personnel":1 if index==7 else 0,
			"target_id":"open_world","target_label":"OPEN EXPLORATION","route":route,"return_route":[],"distance_km":int(reach*2),"journal":journals[index%journals.size()],"discoveries":discoveries,"contacts":[],"archive_reviewed":index>=5,"recruits":3 if index==11 else 0}
		CivilizationSystem.scout_reports.append(report)
	check(home.is_finite(),"home origin is finite")

func _importable(path:String)->bool:
	## A few committed .import files carry backslashed "assets/ui" source paths
	## that the config parser rejects (a backslash-u escape) until the editor
	## rewrites them; such art cannot load in a fresh worktree.
	if path.is_empty() or not FileAccess.file_exists(path+".import"):return false
	var backslash:=char(92)
	return not (backslash+"ui"+backslash) in FileAccess.get_file_as_string(path+".import")

func _seed_mission(id:int,label:String,heading:String,progress:float,direction:Vector2)->void:
	var day:=int(GameState.elapsed_days)
	var duration:=40
	var start:=day-int(progress*duration)
	CivilizationSystem.scout_missions.append({"mission_id":900+id,"start_day":start,"return_day":start+duration,"duration_days":duration,"personnel":7-id,"provisions":30.0,
		"route":_route(direction,150.0,14.0,6),"origin_label":"Ashford","origin_position":{"x":CivilizationSystem.player_world_origin.x,"z":CivilizationSystem.player_world_origin.y},
		"target_id":"open_world","target_kind":"explore","target_label":label,"planned_heading":heading,"route_status":"outbound_and_returning","discoveries":[]})

func _seed_leads()->void:
	var home:=CivilizationSystem.player_world_origin
	var net=CivilizationSystem.rumor_network
	var day:=int(GameState.elapsed_days)
	var near:Dictionary=net.observation("wanderers","reed_people","Reed People",home+Vector2(-190,40),60,day-40,"travelers")
	near.confidence=.5
	net.receive("player",near,day)
	var far:Dictionary=net.observation("wanderers","salt_hill","Salt Hill folk",home+Vector2(1400,-1300),120,day-200,"travelers")
	far.confidence=.12
	net.receive("player",far,day)

func _seed_contacts()->void:
	var home:=CivilizationSystem.player_world_origin
	var names:=["Veshari","Orrun Hold","Tamsk"]
	var offsets:=[Vector2(170,-60),Vector2(-60,190),Vector2(-210,-120)]
	var opinions:=[.7,-.3,.1]
	for i:int in 3:
		var civ:Dictionary=CivilizationSystem.civilizations[i]
		civ.name=names[i]
		var at:Vector2=home+offsets[i]
		var relation:Dictionary=civ.player_relation
		relation.contact_level=2;relation.met_day=int(GameState.elapsed_days)-300*(i+1);relation.opinion=opinions[i];relation.border_tension=.6 if i==1 else .1
		relation.encounter_position={"x":at.x*.8+home.x*.2,"z":at.y*.8+home.y*.2};relation.contact_source="scout_report"
		relation.home_location_known=i!=2
		if i!=2:relation.home_position={"x":at.x,"z":at.y}
		var leader:Dictionary=ForeignDiplomacy.leader(String(civ.id))
		(leader.memories as Array).push_front({"day":int(GameState.elapsed_days)-20,"text":["Your walkers came to our fires with open hands. We will remember that when the reeds are high.","We saw your people cross the ridge. Keep them on your side of it.","We have heard of you, and no more than that."][i]})
	preload("res://scripts/divine_regard.gd").add_civ_dread(String(CivilizationSystem.civilizations[1].id),.5)

# ---------------------------------------------------------------- building

func _build(terrain:ProbeTerrain,hud:ProbeHud,mode:String)->Array:
	T.set_color_mode(mode)
	for child in get_children():child.queue_free()
	await get_tree().process_frame
	var backdrop:=ColorRect.new();backdrop.color=Color("2f3b33") if mode=="dark" else Color("7d8a6e");backdrop.size=Vector2(1920,1080);add_child(backdrop)
	add_child(terrain);add_child(hud)
	var content:=Content.new(terrain,hud)
	var dock:=DockPanel.new();dock.position=Vector2(88,64);dock.size=Vector2(980,1008);add_child(dock)
	dock.present(content,0)
	for i:int in 6:await get_tree().process_frame
	var board:Node=dock.find_child("KnownWorldBoard",true,false)
	return [content,dock,board]

func _fresh()->Array:
	var terrain:=ProbeTerrain.new();terrain.name="Terrain"
	var director:=Director.new();director.name="AudienceDirector";terrain.add_child(director)
	var hud:=ProbeHud.new();hud.name="Hud"
	return [terrain,hud,director]

func _shot(dock:Control,file:String,scroll_to_end:bool=false)->void:
	if shots.is_empty():return
	var scroll:ScrollContainer=dock.get("body_scroll")
	scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value) if scroll_to_end else 0
	for i:int in 3:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots.path_join(file))

func _labels(root:Node)->String:
	var text:PackedStringArray=[]
	for node in root.find_children("*","Label",true,false):text.append((node as Label).text)
	for node in root.find_children("*","Button",true,false):text.append((node as Button).text)
	return "\n".join(text)

func _button(root:Node,node_name:String)->Button:
	return root.find_child(node_name,true,false) as Button

# ---------------------------------------------------------------- scenarios

func _scenario_empty()->void:
	var parts:=_fresh()
	var built:Array=await _build(parts[0],parts[1],"light")
	var content=built[0];var board:Node=built[2]
	check(board!=null,"empty: board built")
	if board==null:return
	var data:Dictionary=content.tab(0)
	check(String(data.blocks[0].type)=="known_world","empty: tab 0 is the known world")
	var text:=_labels(board)
	check("Who lives beyond the smoke?" in text,"empty: invites the unknown")
	check("Every walker is home by the fire." in text,"empty: no party away")
	check("Nothing has been carried home yet" in text,"empty: no finds yet")
	var chart:Node=board.find_child("KnownWorldChart",true,false)
	check(chart!=null and chart.data.trails.is_empty(),"empty: chart has no trails")
	_button(board,"PlanExpedition").pressed.emit()
	check(parts[0].plans==1,"empty: plan expedition reaches the dispatch panel")
	await _shot(built[1],"empty-light-top.png")

func _scenario_early()->void:
	for mode:String in ["light","dark"]:
		var parts:=_fresh()
		var built:Array=await _build(parts[0],parts[1],mode)
		var board:Node=built[2];var dock:Control=built[1]
		check(board!=null,"early: board built")
		if board==null:return
		var model:Dictionary=board.model
		check(int(model.tier)<=1,"early: stone-age tier (%d)" % int(model.tier))
		check(int(model.counters.reports)==26 and int(model.counters.away)==1 and int(model.counters.peoples)==0,"early: counters 0 / 1 / 26 (%s)" % str(model.counters))
		check(int(model.counters.capacity)==2,"early: two parties possible (%d)" % int(model.counters.capacity))
		var text:=_labels(board)
		check("Who lives beyond the smoke?" in text,"early: no contact yet")
		check("Reed People" in text,"early: rumor told as a story fragment")
		check(not "Read findings" in text,"early: no wall of read-findings buttons")
		check("Into unwalked country toward the northeast" in text,"early: party titled in words")
		var chart:Node=board.find_child("KnownWorldChart",true,false)
		check(chart.data.trails.size()==26,"early: every returned route is a trail (%d)" % chart.data.trails.size())
		check(chart.data.parties.size()==1,"early: the party is on the chart")
		check(chart.data.rumors.size()==2,"early: rumored lands (%d)" % chart.data.rumors.size())
		check(not String(chart.tip_at(chart.to_screen(chart.home()))).is_empty(),"early: the hearth has a tooltip")
		var tiles:Array=board.find_children("Find_artifact","",true,false)
		check(tiles.size()>=4,"early: artifact thumbnails in the finds strip (%d)" % tiles.size())
		var textured:=0
		for tile:Node in tiles:
			if tile.find_children("*","TextureRect",true,false).size()>0:textured+=1
			check(not " · " in String(tile.item.title),"early: artifacts use their display name, not the catalogue line (%s)" % String(tile.item.title))
		check(textured>=4,"early: thumbnails show the artwork")
		check(board.find_children("UnreadMark","",true,false).size()>=1,"early: a quiet unread mark")
		if mode=="light":
			_button(board,"SummonChiefScout").pressed.emit()
			check(parts[2].summoned.size()==1 and String(parts[2].summoned[0].get("role",""))=="chief_scout","early: summon reaches the Chief Scout in the hall")
			_button(board,"OpenArchive").pressed.emit()
			check(not parts[1].opened.is_empty() and parts[1].opened[-1] is ArchiveProvider,"early: archive opens in the detail dock")
			var read:=_button(board,"ReadTelling");read.pressed.emit()
			check(parts[1].opened[-1] is ReportProvider,"early: a group opens its report")
			var other:Array=board.find_children("Find_resource","",true,false)
			if not other.is_empty():
				other[0].activate()
				check(parts[1].opened[-1] is ReportProvider,"early: a non-artifact find opens its report")
			tiles[0].activate()
			var gallery:Variant=parts[1].get_meta("artifact_gallery") if parts[1].has_meta("artifact_gallery") else null
			check(gallery is CanvasLayer,"early: an artifact thumbnail opens it in the collection")
			if gallery is CanvasLayer:(gallery as CanvasLayer).queue_free()
			await get_tree().process_frame
			_button(board,"FollowLead").pressed.emit()
			check(parts[0].plans==1,"early: follow a telling plans an expedition")
		await _shot(dock,"early-%s-top.png" % mode)
		await _shot(dock,"early-%s-bottom.png" % mode,true)

func _scenario_later()->void:
	for mode:String in ["light","dark"]:
		var parts:=_fresh()
		var built:Array=await _build(parts[0],parts[1],mode)
		var board:Node=built[2];var dock:Control=built[1]
		check(board!=null,"later: board built")
		if board==null:return
		var model:Dictionary=board.model
		check(int(model.tier)>=2,"later: inked-chart tier (%d)" % int(model.tier))
		check(model.peoples.size()==3,"later: three peoples (%d)" % model.peoples.size())
		check(int(model.counters.away)==2,"later: two parties away")
		var cards:Array=[]
		for people:Dictionary in model.peoples:
			var card:Node=board.find_child("People_"+String(people.civ_id).validate_node_name(),true,false)
			check(card!=null,"later: a medallion card for %s" % String(people.name))
			if card:cards.append(card)
			check(not String(people.leader_name).is_empty(),"later: leader named for %s" % String(people.name))
		var text:=_labels(board)
		check("They honour you" in text or "They hold you in awe" in text,"later: regard spoken in words")
		check("Your walkers came to our fires" in text,"later: the leader's last word")
		check("Still only told of" in text,"later: remaining leads kept")
		if mode=="light" and not cards.is_empty():
			_button(cards[0],"SendWord").pressed.emit()
			check(parts[0].courts.size()==1 and String(parts[0].courts[0].get("civ_id",""))==String(model.peoples[0].civ_id),"later: send word goes to the court for that people")
			_button(cards[0],"KnownRecord").pressed.emit()
			check(parts[1].opened[-1] is CivReport,"later: known record opens in the detail dock")
			var envoys:=_button(board,"SendEnvoys")
			check(envoys!=null and not envoys.disabled,"later: envoys available with located hearths")
			if envoys:envoys.pressed.emit()
			check(parts[0].envoys==1,"later: envoys reach the diplomat dispatch")
		var chart:Node=board.find_child("KnownWorldChart",true,false)
		check(chart.data.peoples.size()==3 and chart.data.parties.size()==2,"later: peoples and parties on the chart")
		await _shot(dock,"later-%s-top.png" % mode)
		await _shot(dock,"later-%s-bottom.png" % mode,true)

func _scenario_many()->void:
	var parts:=_fresh()
	var started:=Time.get_ticks_usec()
	var built:Array=await _build(parts[0],parts[1],"light")
	var board:Node=built[2]
	check(board!=null,"many: board built")
	if board==null:return
	var model:Dictionary=board.model
	check(model.finds.size()<=6,"many: finds are grouped and bounded (%d groups)" % model.finds.size())
	check(model.chart.trails.size()<=30,"many: trails bounded (%d)" % model.chart.trails.size())
	check(board.find_children("Find_*","",true,false).size()<=24,"many: bounded thumbnails")
	var chart:Node=board.find_child("KnownWorldChart",true,false)
	var circles:PackedVector4Array=chart.fog_circles()
	check(circles.size()<=96,"many: fog uniforms bounded (%d)" % circles.size())
	var content=built[0]
	var before:Array=content.signature()
	CivilizationSystem.scout_reports.push_front({"mission_id":999,"day":int(GameState.elapsed_days),"route":_route(Vector2(1,0),80,5),"discoveries":[{"kind":"resource","title":"Copper seam","resource":"Copper","description":"Green stone in the bank.","position":{"x":10.0,"z":0.0}}],"archive_reviewed":false})
	check(content.signature()!=before,"many: a new return refreshes the board")
	print("  many: built in %.1f ms" % ((Time.get_ticks_usec()-started)/1000.0))
