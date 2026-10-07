extends GdUnitTestSuite
## The docks refresh while the game runs (command_rail_hud.live_refresh_dock).
## To keep that cheap, providers keep costly parts of their pages while what
## those parts are made from holds (hud/content/dock_memo.gd), the dock keeps
## sections whose print is unchanged, and widgets write a new day's figures
## into the nodes they already have. None of that may change what the player
## sees: in a small running world, through a discovery and a month's turn,
##   - every page made with memory equals the page made fresh,
##   - a dock refreshed in place looks exactly like one drawn fresh, and
##   - the few readings the docks take without copying records say exactly
##     what the records' own functions say.

const DockPanel:=preload("res://scripts/hud/dock_panel.gd")
const Memo:=preload("res://scripts/hud/content/dock_memo.gd")
const DAY:=preload("res://scripts/civilization_day.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const History:=preload("res://scripts/strategic_history.gd")
const Standing:=preload("res://scripts/standing.gd")
const Archive:=preload("res://scripts/scout_archive.gd")
const PROVIDERS:={"overview":"dock_content_overview.gd","standing":"dock_content_standing.gd","inquiry":"dock_content_inquiry.gd","construction":"dock_content_construction.gd","economy":"dock_content_economy.gd","production":"dock_content_production.gd","world":"dock_content_world.gd","chronicle":"dock_content_chronicle.gd","settlement":"dock_content_settlement.gd","civ":"dock_content_civilization.gd"}
const PAGES:=[["overview",0],["standing",0],["inquiry",0],["inquiry",1],["inquiry",2],["construction",0],["construction",1],["construction",2],["economy",0],["economy",1],["economy",2],["production",0],["world",0],["world",1],["world",2],["chronicle",0],["settlement",0],["settlement",1],["civ",0],["civ",1]]
## Widget state that is animation or bookkeeping, not what is shown.
const NOT_SHOWN:=["reveal","_clock","data","model","block","prints","parts","rebuilds","face_slots","_folio_print","_row_prints","_list_shape","_shape","_rows","_incoming","open_impact","hits","labels","sections_built","_section_prints","_section_frames","_kpi_print","_brief_print","_room","fit_height","_fitting","provider","explained","records","years","_cards","_fields","_refs","_page_shape","_page_refs","_culture","_culture_shape","_card_refs","_gauges","_groups","_group_refs","_row_refs","_vital_rows","_labor_head","_labor_rows","_labor_row_prints","_labor_row_shapes","_per_held"]

class StubTerrain extends Node:
	var selected_army_id:=-1
	func _report_military_action(_result:Dictionary)->void:pass
	func _change_research_domain_allocation(_id:String,_delta:int)->void:pass
	func _open_war_planning()->void:pass
	func _settlement_display_name()->String:return "Capital"
	func _select_army_and_focus(_id:int)->void:pass
	func _open_settlement_naming_panel(_id:String="")->void:pass
	func _open_scout_dispatch_panel()->void:pass
	func _on_settlement_action_pressed()->void:pass
	func _discovery_context()->Dictionary:return {}
	func site_temperature_c()->float:return 12.0
	func _toggle_resource_view()->void:pass
	func _open_diplomat_dispatch_panel()->void:pass
	func _on_caravan_override(_a:String,_b:String)->void:pass
	func _halt_founding_convoy_to_forage()->void:pass
	func _dynamic_definition(_id:String)->Dictionary:return {}

class TestHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Control
	func request_immediate_dock_refresh()->void:pass
	func open_detail(_provider:Object,_sub:int=0)->void:pass

var terrain:StubTerrain
var hud:TestHud
var _opponents:=-1
var day:=0

func before_test()->void:
	_opponents=GameState.opponent_count
	Memo.enabled=true
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	for system:Node in [ResourceSystem,FoodSystem,SettlementModel,MilitaryCampaign]:system.reset_for_new_world()
	GameState.opponent_count=1
	CivilizationSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.initialize_population_model()
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_site_committed=true;GameState.settlement_name="Capital"
	SettlementModel.ensure_founded()
	WorldSimulation.context_provider=func(_point:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.start_world()
	terrain=StubTerrain.new();add_child(terrain)
	hud=TestHud.new();add_child(hud)
	day=0

func after_test()->void:
	Memo.enabled=true
	if is_instance_valid(hud):hud.queue_free()
	if is_instance_valid(terrain):terrain.queue_free()
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	if _opponents>0:GameState.opponent_count=_opponents
	GameState.reset_for_new_world(515151)
	for system:Node in [ResourceSystem,FoodSystem,SettlementModel,MilitaryCampaign,CivilizationSystem]:system.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	await get_tree().process_frame

## One simulated day, committed the way the running game commits it.
func _advance()->void:
	day+=1
	var result:=WorldSimulation.advance_day(day,DAY.context(Vector2.ZERO))
	Chronicle.ingest_day(result)
	History.sample()

## The next day completes a question under way, and a month's reading is due.
func _arrange_discovery_and_month()->void:
	for channel in GameState.active_investigations:
		var id:=String(GameState.active_investigations[channel])
		if id!="":GameState.discovery_progress[id]=0.9999;break
	GameState.strategic_history["last_day"]=day-29

func _providers()->Dictionary:
	var made:={}
	for section:String in PROVIDERS:made[section]=load("res://scripts/hud/content/"+String(PROVIDERS[section])).new(terrain,hud)
	return made

## A page as the player sees it: callables by what they call, objects by kind,
## and the providers' private keys (a memory's print) left out.
static func canon(value:Variant)->String:
	match typeof(value):
		TYPE_DICTIONARY:
			var keys:Array=(value as Dictionary).keys();keys.sort()
			var parts:PackedStringArray=[]
			for key in keys:
				if str(key).begins_with("_"):continue
				parts.append(str(key)+":"+canon(value[key]))
			return "{"+",".join(parts)+"}"
		TYPE_ARRAY:
			var parts:PackedStringArray=[]
			for item in value:parts.append(canon(item))
			return "["+",".join(parts)+"]"
		TYPE_CALLABLE:return "fn:"+String((value as Callable).get_method())+str((value as Callable).get_bound_arguments())
		TYPE_OBJECT:
			if not is_instance_valid(value):return "null"
			return "obj:"+(value as Object).get_class()+":"+(String((value as Resource).resource_path) if value is Resource else "")
	return var_to_str(value)

## What a drawn dock shows: every node's words, inks, visibility, pictures and
## drawn values, in order.
static func snap(node:Node,out:PackedStringArray,depth:int=0)->void:
	if node.is_queued_for_deletion():return
	var line:=node.get_class()
	if not String(node.name).contains("@"):line+="#"+String(node.name)
	if node is CanvasItem:line+=" vis=%s mod=%s" % [(node as CanvasItem).visible,(node as CanvasItem).modulate]
	if node is Control:
		var control:=node as Control
		line+=" tip=%s min=%s" % [control.tooltip_text.c_escape(),control.custom_minimum_size]
	if node is Label:line+=" text=%s ink=%s" % [(node as Label).text.c_escape(),(node as Label).get_theme_color("font_color")]
	elif node is Button:line+=" text=%s off=%s on=%s" % [(node as Button).text.c_escape(),(node as Button).disabled,(node as Button).button_pressed]
	if node is TextureRect:
		var texture:=(node as TextureRect).texture
		line+=" tex=%s" % ("null" if texture==null else ("%s %s" % [(texture as AtlasTexture).atlas.resource_path,(texture as AtlasTexture).region] if texture is AtlasTexture else "%s %s" % [texture.resource_path,texture.get_size()]))
	if node is Range:line+=" value=%s" % (node as Range).value
	var script:Script=node.get_script()
	if script!=null:
		for property:Dictionary in script.get_script_property_list():
			if not (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) or String(property.name) in NOT_SHOWN:continue
			var value:Variant=node.get(String(property.name))
			if typeof(value) in [TYPE_OBJECT,TYPE_CALLABLE,TYPE_SIGNAL]:continue
			line+=" %s=%s" % [property.name,canon(value)]
	out.append("  ".repeat(depth)+line)
	for child in node.get_children():snap(child,out,depth+1)

func test_pages_made_with_memory_equal_pages_made_fresh()->void:
	var providers:=_providers()
	var discovered_before:=GameState.known_discoveries.size()
	var sampled_before:=int(GameState.strategic_history.get("last_day",-1))
	for step in 5:
		if step==2:_arrange_discovery_and_month()
		_advance()
		for page:Array in PAGES:
			var provider:Object=providers[page[0]]
			var kept:=canon(provider.call("tab",int(page[1])))
			Memo.enabled=false
			var fresh:=canon(provider.call("tab",int(page[1])))
			Memo.enabled=true
			assert_str(kept).override_failure_message("%s:%d on day %d differs from a fresh page" % [page[0],page[1],day]).is_equal(fresh)
	# The run did pass a discovery and a month's reading.
	assert_int(GameState.known_discoveries.size()).is_greater(discovered_before)
	assert_int(int(GameState.strategic_history.get("last_day",-1))).is_not_equal(sampled_before)

func test_docks_refreshed_in_place_look_like_docks_drawn_fresh()->void:
	var providers:=_providers()
	var live:=DockPanel.new();add_child(live);live.size=Vector2(900,900)
	hud.dock=live
	_advance()
	for index in PAGES.size():
		var page:Array=PAGES[index]
		var provider:Object=providers[page[0]]
		live.present(provider,int(page[1]))
		if index==PAGES.size()/2:_arrange_discovery_and_month()
		# Two days pass with the page open: it refreshes in place each day.
		for passing in 2:
			_advance()
			live.rebuild_body()
		var fresh:=DockPanel.new();add_child(fresh);fresh.size=live.size
		fresh.present(provider,int(page[1]))
		var a:=PackedStringArray();var b:=PackedStringArray()
		snap(live.body,a);snap(fresh.body,b)
		var at:=0
		while at<mini(a.size(),b.size()) and a[at]==b[at]:at+=1
		assert_bool(a==b).override_failure_message("%s:%d day %d, line %d | live: %s | fresh: %s" % [page[0],page[1],day,at,a[at] if at<a.size() else "<end>",b[at] if at<b.size() else "<end>"]).is_true()
		remove_child(fresh);fresh.free()
	remove_child(live);live.free()

func test_readings_taken_without_copying_records_say_what_the_records_say()->void:
	_advance()
	var Production:=load("res://scripts/hud/content/dock_content_production.gd")
	var Civilization:=load("res://scripts/hud/content/dock_content_civilization.gd")
	var StandingDock:=load("res://scripts/hud/content/dock_content_standing.gd")
	var World:=load("res://scripts/hud/content/dock_content_world.gd")
	# The workshop's officer, held and vacant.
	assert_str(Production.workshop_owner()).is_equal(MilitaryCampaign.workshop.owner())
	var positions:Dictionary=GameState.leadership_positions.duplicate(true)
	GameState.leadership_positions.erase("Quartermaster");GameState.leadership_positions.erase("Steward")
	assert_str(Production.workshop_owner()).is_equal(MilitaryCampaign.workshop.owner())
	GameState.leadership_positions=positions
	# The local leader's person id.
	for city:Dictionary in GameState.player_settlements:
		var id:=String(city.get("id",""))
		assert_int(Civilization.leader_person_id(id)).is_equal(int(GovernmentPeopleSystem.settlement_leader(id).get("person_id",0)))
	assert_int(Civilization.leader_person_id("nowhere")).is_equal(int(GovernmentPeopleSystem.settlement_leader("nowhere").get("person_id",0)))
	# How each people we have met sees us, from one reading of our strengths.
	for civ:Dictionary in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		relation["contact_level"]=2;civ["player_relation"]=relation
	assert_int(Standing.views().size()).is_greater(0)
	assert_str(canon(StandingDock.views_of(Standing.strengths()))).is_equal(canon(Standing.views()))
	for civ:Dictionary in CivilizationSystem.civilizations:
		var civ_id:=String(civ.id)
		assert_bool(StandingDock.comparable(civ_id)).is_equal(not Standing.their_strengths(civ_id).is_empty())
	assert_bool(StandingDock.comparable("")).is_false()
	# The newest tellings, ties on a day ordered as the archive orders them.
	var reports:Array=[]
	for index in 11:
		reports.append({"mission_id":index,"day":40-int(index/3),"target_id":"t%d" % (index%4),"target_label":"Open exploration","personnel":3+index,"route":[{"x":index,"z":0.0},{"x":index+5.0,"z":3.0}],"discoveries":[],"contacts":["Keshan"] if index==5 else [],"lost_personnel":1 if index==7 else 0})
	assert_str(canon(World.newest_tellings(reports,8))).is_equal(canon(Archive.select(reports,"",0,false).slice(0,8)))
	assert_str(canon(World.newest_tellings(reports,20))).is_equal(canon(Archive.select(reports,"",0,false)))

func test_a_section_keeps_its_nodes_while_its_print_holds()->void:
	var panel:=DockPanel.new();add_child(panel)
	var provider:=PrintedPage.new()
	panel.present(provider,0)
	var section:Node=panel.body.get_child(0)
	provider.revision="a";panel.rebuild_body()
	assert_bool(panel.body.get_child(0)==section).override_failure_message("an unchanged print must keep the section").is_true()
	provider.revision="b";panel.rebuild_body()
	assert_bool(panel.body.get_child(0)==section).override_failure_message("a new print must draw the section again").is_false()
	# A widget refreshed in place under a changed heading is drawn again, so
	# its heading never goes stale.
	var chart:Node=panel.body.get_child(1)
	provider.heading="LATER";panel.rebuild_body()
	assert_bool(panel.body.get_child(1)==chart).is_false()
	remove_child(panel);panel.free()

class PrintedPage extends RefCounted:
	var revision:="a"
	var heading:="EARLIER"
	func meta()->Dictionary:return {"eyebrow":"","title":"Test","subtabs":["One"]}
	func signature()->Array:return [revision,heading]
	func tab(_sub:int)->Dictionary:
		return {"blocks":[{"type":"chronicle","heading":"The years","events":[{"day":revision.length(),"kind":"Founding","title":"Founded "+revision,"scope":"Capital","description":"","art":0}],"_print":revision},
			{"type":"trend_chart","id":"t","heading":heading,"unit":"people","series":[{"key":"population","label":"People","color":Color.GREEN}],"items":[{"day":1,"population":3}],"description":"x"}]}
