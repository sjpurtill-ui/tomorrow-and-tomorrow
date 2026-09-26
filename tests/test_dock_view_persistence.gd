extends GdUnitTestSuite
## Playtest: "every day this rescrolls to the top, I can't even look at it
## without pausing". A live dock refresh must keep the reader's place: scroll
## offset, widget page state and unchanged nodes.
const DockPanel:=preload("res://scripts/hud/dock_panel.gd")
const Health:=preload("res://scripts/hud/content/dock_detail_health.gd")
const ChronicleDock:=preload("res://scripts/hud/content/dock_content_chronicle.gd")
const PopulationLedger:=preload("res://scripts/hud/content/dock_detail_population_ledger.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const PeopleDock:=preload("res://scripts/hud/content/dock_content_overview.gd")

class TestHud extends Control:
	signal section_requested(section:String,sub:int)
	func request_immediate_dock_refresh()->void:pass

var hud:TestHud
var panel

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(515151)
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_site_committed=true;GameState.settlement_name="Capital"
	SettlementModel.ensure_founded()
	hud=TestHud.new();add_child(hud)
	panel=DockPanel.new();add_child(panel)
	panel.position=Vector2.ZERO;panel.size=Vector2(560,700)

func after_test()->void:
	if is_instance_valid(panel):panel.queue_free()
	if is_instance_valid(hud):hud.queue_free()
	await get_tree().process_frame

func _frames(count:int)->void:
	for frame in count:await get_tree().process_frame

## What the HUD's live tick does: rebuild only when the provider's signature moves.
func _live_tick(last:Array)->Array:
	var signature:Array=panel.provider.signature().duplicate(true)+[panel.sub]
	if signature.hash()!=last.hash():panel.rebuild_body()
	return signature

func _scroll_deep()->int:
	var bar:ScrollBar=panel.body_scroll.get_v_scroll_bar()
	var room:=bar.max_value-bar.page
	assert_float(room).is_greater(60.0)
	panel.body_scroll.scroll_vertical=int(room*0.9)
	await _frames(2)
	return panel.body_scroll.scroll_vertical

func _open(provider:Object,sub:int=0)->void:
	panel.present(provider,sub)
	await _frames(8)

func test_life_and_death_keeps_its_place_and_nodes_across_days()->void:
	var provider:=Health.new(null,hud)
	await _open(provider)
	var middle:int=await _scroll_deep()
	assert_int(middle).is_greater(0)
	var sections_before:Array=panel.body.get_children()
	var built_before:int=panel.sections_built
	var signature:Array=panel.provider.signature().duplicate(true)+[panel.sub]
	var rebuilt_days:=0
	for day in 5:
		GameState.elapsed_days+=1.0
		GameState.lifetime_deaths+=1
		var next:=_live_tick(signature)
		if next.hash()!=signature.hash():rebuilt_days+=1
		signature=next
		await _frames(4)
		assert_int(absi(panel.body_scroll.scroll_vertical-middle)).is_less_equal(3)
	assert_int(rebuilt_days).is_equal(5)
	# Blocks whose data did not change (the history chart, the care rows,
	# the duty buttons) keep their nodes; nothing was rebuilt wholesale.
	var kept:=0
	for section in sections_before:
		if is_instance_valid(section) and section.get_parent()==panel.body:kept+=1
	assert_int(kept).is_greater_equal(sections_before.size()-1)
	# At most the one block that reads the day is rebuilt per day, not all of them.
	assert_int(panel.sections_built-built_before).is_less_equal(rebuilt_days)
	assert_int(panel.sections_built-built_before).is_less(rebuilt_days*sections_before.size())

func test_life_and_death_refresh_keeps_focus()->void:
	await _open(Health.new(null,hud))
	var button:Button=null
	for node in panel.body.find_children("*","Button",true,false):
		if (node as Button).focus_mode!=Control.FOCUS_NONE and (node as Button).is_visible_in_tree():button=node;break
	if button==null:return
	button.grab_focus()
	GameState.lifetime_deaths+=3
	panel.rebuild_body()
	await _frames(2)
	var owner:=get_viewport().gui_get_focus_owner()
	assert_object(owner).is_not_null()
	assert_bool(panel.body.is_ancestor_of(owner)).is_true()

func test_chronicle_keeps_its_place_and_opened_pages_as_tales_arrive()->void:
	for i in 70:
		Chronicle.record({"key":"test:%d" % i,"title":"The people remember %d" % i,"text":"A line long enough to wrap in the chronicle feed so the view has height.","tier":"notice","kind":"story","day":i})
	await _open(ChronicleDock.new(null,hud))
	var feed:Node=panel.body.find_child("ChronicleFeed",true,false)
	assert_object(feed).is_not_null()
	Chronicle.record({"key":"tally:1","title":"Season tally","text":"Notches cut.","tier":"whisper","kind":"story","day":69})
	await _open(ChronicleDock.new(null,hud))
	feed=panel.body.find_child("ChronicleFeed",true,false)
	# One feed, no tabs: the story hides the season tallies until asked.
	assert_bool(panel.tabs_row.visible).is_false()
	var total:int=(feed.data.entries as Array).size()
	assert_int(feed.visible_entries().size()).is_equal(total-1)
	feed.tallies_check.button_pressed=true
	assert_int(feed.visible_entries().size()).is_equal(total)
	# Open older tales; a refresh must not fold them away again.
	feed.shown+=feed.PAGE;feed._fill()
	await _frames(6)
	var middle:int=await _scroll_deep()
	var signature:Array=panel.provider.signature().duplicate(true)+[panel.sub]
	for day in 4:
		GameState.elapsed_days=100.0+day
		Chronicle.record({"key":"new:%d" % day,"title":"A new tale %d" % day,"text":"Told today.","tier":"notice","kind":"story","day":100+day})
		signature=_live_tick(signature)
		await _frames(4)
		assert_int(absi(panel.body_scroll.scroll_vertical-middle)).is_less_equal(3)
	feed=panel.body.find_child("ChronicleFeed",true,false)
	assert_int(int(feed.shown)).is_equal(int(feed.PAGE)*2)
	assert_bool(feed.show_tallies).is_true()

func test_the_people_update_in_place_keeping_scene_card_and_place()->void:
	var provider:=PeopleDock.new(null,hud)
	await _open(provider)
	var screen:Node=panel.body.find_child("PeopleScreen",true,false)
	assert_object(screen).is_not_null()
	var scene:Node=screen.find_child("Scene",true,false)
	# Open the oldest one's card, then read deep into the screen.
	var oldest:=""
	for face:Dictionary in screen.data.faces:
		if String(face.role)=="oldest":oldest=String(face.id)
	screen._select(oldest)
	await _frames(4)
	assert_bool((screen.card as Control).visible).is_true()
	var middle:int=await _scroll_deep()
	var signature:Array=panel.provider.signature().duplicate(true)+[panel.sub]
	var built:int=panel.sections_built
	for day in 4:
		GameState.elapsed_days+=1.0
		GameState.simulation_metrics.food_days=40.0-day*6.0
		signature=_live_tick(signature)
		await _frames(4)
		assert_int(absi(panel.body_scroll.scroll_vertical-middle)).is_less_equal(3)
	# The same widget took the new days: its scene nodes and the open card stayed.
	assert_int(panel.sections_built).is_equal(built)
	assert_bool(is_instance_valid(scene) and panel.body.is_ancestor_of(scene)).is_true()
	assert_str(String(screen.selected_id)).is_equal(oldest)
	assert_bool((screen.card as Control).visible).is_true()

func test_population_ledger_keeps_its_place_and_tab_across_days()->void:
	var provider:=PopulationLedger.new(null,hud)
	await _open(provider)
	var middle:int=await _scroll_deep()
	var signature:Array=panel.provider.signature().duplicate(true)+[panel.sub]
	var before:int=panel.sections_built
	var block_count:int=panel.body.get_child_count()
	for day in 4:
		GameState.elapsed_days+=1.0
		GameState.population_total+=1;GameState.lifetime_births+=1
		signature=_live_tick(signature)
		await _frames(4)
		assert_int(absi(panel.body_scroll.scroll_vertical-middle)).is_less_equal(3)
		assert_int(panel.sub).is_equal(0)
	# Headcount changes touch the KPI row, not every ledger block.
	assert_int(panel.sections_built-before).is_less(block_count*4)

func test_player_scroll_after_refresh_is_not_overridden()->void:
	await _open(Health.new(null,hud))
	var middle:int=await _scroll_deep()
	GameState.lifetime_deaths+=1
	panel.rebuild_body()
	await _frames(1)
	panel.body_scroll.scroll_vertical=0
	await _frames(8)
	assert_int(panel.body_scroll.scroll_vertical).is_equal(0)
	assert_int(middle).is_greater(0)
