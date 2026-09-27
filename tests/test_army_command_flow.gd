extends GdUnitTestSuite
## The Army command screen in plain steps: who goes, what, where (clicked on
## the map or picked from a short list), then one "Give the order". Orders go
## through the court's war core, so the answer and the objective match the
## court's; nothing needs a drawn zone; every word reads on paper.

const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const Orders:=preload("res://scripts/army_orders.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const ArmyPanel:=preload("res://scripts/hud/command_hierarchy_panel.gd")
const Overlay:=preload("res://scripts/hud/service_world_overlay.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

## A flat stand-in for the terrain camera: 10 px per km round (400,400) at home.
class Map extends Overlay:
	var origin:=Vector2.ZERO
	func world_to_screen(point:Vector2)->Vector2:return (point-origin)*10.0+Vector2(400,400)
	func screen_to_world(point:Vector2)->Dictionary:
		var at:=(point-Vector2(400,400))/10.0+origin
		return {"x":at.x,"z":at.y}

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var _processing:Dictionary={}

func _land(_p:Vector2)->bool:return true

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=88*365
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Tsaren"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=false; relation.treaty="none"; relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	home=CivilizationSystem.player_world_origin
	city=home+Vector2(-30.0,12.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	CivilizationSystem.revealed_areas=[{"x":home.x,"z":home.y,"radius":100000.0}]

func after_test()->void:
	T.set_color_mode("light")
	CivilizationSystem.set_scout_geography_authority(Callable())
	Route.clear_cache()
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

func _train(count:int)->void:
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

func _set_garrison(mid:float)->void:
	var rec:Dictionary=CivilizationSystem.city_intelligence.records.player[city_id]
	rec.fields["garrison"]={"low":mid,"high":mid,"observed_day":int(GameState.elapsed_days),"reported_day":int(GameState.elapsed_days)}

func _court(words:String)->Dictionary:
	var marshal:=GovernmentPeopleSystem.officeholder("Marshal")
	var target:={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else {"person_id":int((Hall._officials()[0] as Dictionary).person_id)}
	var audience:=Hall.summon(target)
	return CC.hear(String(audience.id),words)

func _tsaren()->Dictionary:
	return {"type":"place","place":Orders.place(city_id)}

func _panel()->CanvasLayer:
	var panel:CanvasLayer=auto_free(ArmyPanel.new());panel.domain="army";add_child(panel)
	var stub:=Map.new();stub.domain="army";stub.origin=home;panel.add_child(stub);panel.map.queue_free();panel.map=stub
	return panel

func _click(panel:CanvasLayer,at:Vector2)->bool:
	var event:=InputEventMouseButton.new();event.pressed=true;event.button_index=MOUSE_BUTTON_LEFT;event.position=at
	return panel.handle_map_input(event)

func _army_shape(army_id:int)->Dictionary:
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
	return {"status":army.status,"destination_id":army.destination_id,"troops":army.troops,"operation":army.get("city_operation",{}),"order_kind":(army.get("court_order",{}) as Dictionary).get("kind",""),"order_city":(army.get("court_order",{}) as Dictionary).get("city_id","")}

# ---------------------------------------------------------------------------
# The same objective as the court
# ---------------------------------------------------------------------------

func test_attack_from_home_gives_the_courts_objective()->void:
	_train(400);_set_garrison(40.0)
	var spoken:=_court("Attack Tsaren")
	assert_str(String(spoken.war.verdict)).is_equal("act")
	var said:Dictionary=spoken.objective
	var said_army:=_army_shape(int(said.army_id))
	before_test()
	_train(400);_set_garrison(40.0)
	var given:=Orders.give(Orders.HOME,"attack",_tsaren())
	assert_str(String(given.verdict)).override_failure_message(String(given.outcome)).is_equal("act")
	for key in ["kind","city_id","civ_id","troops","days","route_km"]:
		assert_str(str(given.objective[key])).override_failure_message(key).is_equal(str(said[key]))
	assert_dict(_army_shape(int(given.objective.army_id))).is_equal(said_army)
	# The court's ledger follows it, so the general's report comes back to court.
	assert_int(WO.ledger().size()).is_equal(1)
	assert_str(String(WO.ledger()[0].status)).is_equal("marching")

func test_defend_from_the_screen_is_the_courts_home_watch()->void:
	_train(60)
	var spoken:=_court("Defend our home with the soldiers")
	before_test()
	_train(60)
	var given:=Orders.give(Orders.HOME,"defend",{})
	assert_str(String(given.verdict)).is_equal(String(spoken.war.verdict))
	assert_str(String(given.verdict)).is_equal("act")
	assert_int(int(given.objective.watch)).is_equal(int(spoken.objective.watch))
	assert_str(String(given.says)).is_equal(String(spoken.war.says))
	assert_array(MilitaryCampaign.command_hierarchy.data.zones).is_empty()

func test_come_home_matches_the_court()->void:
	_train(400);_set_garrison(20.0)
	var sent:=Orders.give(Orders.HOME,"attack",_tsaren())
	var army_id:=int(sent.objective.army_id)
	for day in 2:
		GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()
	var spoken:=_court("Bring the army home")
	var court_home:=_army_shape(army_id)
	before_test()
	_train(400);_set_garrison(20.0)
	sent=Orders.give(Orders.HOME,"attack",_tsaren())
	army_id=int(sent.objective.army_id)
	for day in 2:
		GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()
	var given:=Orders.give(army_id,"recall",{})
	assert_str(String(given.verdict)).is_equal(String(spoken.war.verdict))
	var screen_home:=_army_shape(army_id)
	assert_str(String(screen_home.destination_id)).is_equal("player_home")
	assert_dict(screen_home).is_equal(court_home)
	assert_int(int(given.objective.days)).is_equal(int(spoken.objective.days))
	assert_array(MilitaryCampaign.command_hierarchy.data.zones).is_empty()

func test_the_chosen_band_goes_and_the_general_objects_then_obeys()->void:
	_train(120)
	var band:Dictionary=MilitaryCampaign.create_field_army(30,"Levy band 1")
	var band_id:=int(band.army.army_id)
	var home_before:=int(MilitaryCampaign.home_army.troops)
	_set_garrison(600.0)
	var first:=Orders.give(band_id,"attack",_tsaren())
	assert_str(String(first.verdict)).is_equal("object")
	assert_str(String(first.says)).contains("600")
	assert_str(String(_army_shape(band_id).status)).is_equal("stationed")
	var again:=Orders.give(band_id,"attack",_tsaren(),true)
	assert_str(String(again.verdict)).is_equal("act")
	assert_int(int(again.objective.army_id)).is_equal(band_id)
	var shape:=_army_shape(band_id)
	assert_str(String(shape.destination_id)).is_equal(city_id)
	assert_str(String(shape.order_kind)).is_equal("attack")
	# The band went, not a new host from home.
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(home_before)
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(1)
	var chronicled:=false
	for e in GameState.chronicle.get("entries",[]):
		if String((e as Dictionary).get("key","")).begins_with("court_war:"):chronicled=true
	assert_bool(chronicled).is_true()

func test_guard_and_go_to_use_the_clicked_ground()->void:
	_train(60)
	var spot:=home+Vector2(8,0)
	var went:=Orders.give(Orders.HOME,"goto",{"type":"spot","x":spot.x,"z":spot.y})
	assert_str(String(went.verdict)).override_failure_message(String(went.outcome)).is_equal("act")
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(went.objective.army_id))]
	assert_str(String(army.status)).is_equal("moving")
	assert_float(float(army.destination_position.x)).is_equal_approx(spot.x,0.01)
	var guard:=Orders.give(int(went.objective.army_id),"guard",{"type":"spot","x":spot.x,"z":spot.y+4})
	assert_str(String(guard.verdict)).override_failure_message(String(guard.outcome)).is_equal("act")
	var zones:Array=MilitaryCampaign.command_hierarchy.data.zones
	assert_int(zones.size()).is_equal(1)
	assert_bool(Orders.R.contains(zones[0],Vector2(spot.x,spot.y+4))).is_true()
	assert_bool(MilitaryCampaign.command_hierarchy.controls_army(int(went.objective.army_id))).is_true()

# ---------------------------------------------------------------------------
# The screen
# ---------------------------------------------------------------------------

func test_map_clicks_pick_the_band_the_town_and_the_ground()->void:
	_train(40)
	var band:Dictionary=MilitaryCampaign.create_field_army(20,"Levy band 1")
	var band_id:=int(band.army.army_id)
	var panel:=_panel()
	var stub:Map=panel.map
	# The band at home is chosen by default; the levy at home is one click away.
	assert_int(panel.force_id).is_equal(band_id)
	panel.choose_force(Orders.HOME);assert_int(panel.force_id).is_equal(Orders.HOME)
	# A town on the map: Attack, with Tsaren as the target.
	assert_bool(_click(panel,stub.world_to_screen(city)+Vector2(5,-4))).is_true()
	assert_str(panel.verb_id).is_equal("attack")
	assert_str(String(panel.target.type)).is_equal("place")
	assert_str(String(panel.target.place.city_id)).is_equal(city_id)
	assert_bool(panel.give_button.disabled).is_false()
	# Besiege keeps the town.
	panel.choose_verb("siege")
	assert_str(String(panel.target.place.city_id)).is_equal(city_id)
	# Guard a place: open ground becomes the place.
	panel.choose_verb("guard")
	assert_dict(panel.target).is_empty()
	var ground:=home+Vector2(12,6)
	assert_bool(_click(panel,stub.world_to_screen(ground))).is_true()
	assert_str(String(panel.target.type)).is_equal("spot")
	assert_float(float(panel.target.x)).is_equal_approx(ground.x,0.01)
	assert_float(float(panel.target.z)).is_equal_approx(ground.y,0.01)
	# Our band's position on the map picks it as who goes.
	var index:=MilitaryCampaign._field_army_index(band_id)
	MilitaryCampaign.field_armies[index]["position"]={"x":home.x+3.0,"z":home.y+3.0}
	assert_bool(_click(panel,stub.world_to_screen(home+Vector2(3,3)))).is_true()
	assert_int(panel.force_id).is_equal(band_id)
	# Open ground with nothing chosen yet: go there.
	panel.verb_id="";panel.target={}
	assert_bool(_click(panel,stub.world_to_screen(home+Vector2(-9,14)))).is_true()
	assert_str(panel.verb_id).is_equal("goto")
	assert_str(String(panel.target.type)).is_equal("spot")

func test_land_attack_and_come_home_need_no_zone()->void:
	_train(200);_set_garrison(10.0)
	var panel:=_panel()
	panel.choose_force(Orders.HOME);panel.choose_verb("attack");panel.choose_place(city_id)
	assert_bool(panel.give_button.disabled).is_false()
	panel._give(false)
	assert_str(String(panel.last_answer.verdict)).override_failure_message(String(panel.last_answer.outcome)).is_equal("act")
	assert_array(MilitaryCampaign.command_hierarchy.data.zones).is_empty()
	var army_id:=int(panel.last_answer.objective.army_id)
	assert_int(panel.force_id).is_equal(army_id)
	for day in 2:
		GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()
	panel._refresh_flow()
	panel.choose_verb("recall")
	assert_bool(panel.give_button.disabled).is_false()
	panel._give(false)
	assert_str(String(panel.last_answer.verdict)).is_equal("act")
	assert_str(String(_army_shape(army_id).destination_id)).is_equal("player_home")
	assert_array(MilitaryCampaign.command_hierarchy.data.zones).is_empty()

func test_objection_shows_insist_and_the_generals_words()->void:
	_train(60);_set_garrison(600.0)
	var panel:=_panel()
	panel.choose_force(Orders.HOME);panel.choose_verb("attack");panel.choose_place(city_id)
	panel._give(false)
	assert_str(String(panel.last_answer.verdict)).is_equal("object")
	assert_bool(panel.insist_button.visible).is_true()
	assert_str(panel.answer_label.text).contains("objects")
	panel.insist_button.pressed.emit()
	assert_str(String(panel.last_answer.verdict)).is_equal("act")
	assert_bool(panel.insist_button.visible).is_false()

# ---------------------------------------------------------------------------
# Readability
# ---------------------------------------------------------------------------

static func _luminance(color:Color)->float:
	var c:=[color.r,color.g,color.b]
	for i in 3:c[i]=c[i]/12.92 if c[i]<=0.03928 else pow((c[i]+0.055)/1.055,2.4)
	return 0.2126*c[0]+0.7152*c[1]+0.0722*c[2]

static func _contrast(a:Color,b:Color)->float:
	var high:=maxf(_luminance(a),_luminance(b));var low:=minf(_luminance(a),_luminance(b))
	return (high+0.05)/(low+0.05)

static func _ground(node:Node)->Color:
	## The paper under a control: the nearest drawn box above it.
	var at:=node
	while at!=null:
		var box:StyleBox=null
		if at is Button:box=(at as Button).get_theme_stylebox("pressed" if (at as Button).button_pressed else "normal")
		elif at is LineEdit:box=(at as LineEdit).get_theme_stylebox("normal")
		elif at is PanelContainer:box=(at as PanelContainer).get_theme_stylebox("panel")
		if box is StyleBoxFlat and (box as StyleBoxFlat).bg_color.a>0.0:
			var bg:=(box as StyleBoxFlat).bg_color
			return T.DOCK_BG.lerp(Color(bg.r,bg.g,bg.b),bg.a)
		at=at.get_parent()
	return T.DOCK_BG

func _walk(node:Node,out:Array)->void:
	out.append(node)
	for child in node.get_children():_walk(child,out)

func _texts(panel:CanvasLayer)->PackedStringArray:
	var out:=PackedStringArray()
	var nodes:Array=[];_walk(panel.panel,nodes)
	for node in nodes:
		if node is Label:out.append((node as Label).text)
		elif node is OptionButton:
			for i in (node as OptionButton).item_count:out.append((node as OptionButton).get_item_text(i))
		elif node is Button:out.append((node as Button).text)
		elif node is LineEdit:out.append((node as LineEdit).placeholder_text)
		elif node is TabContainer:
			for i in (node as TabContainer).get_tab_count():out.append((node as TabContainer).get_tab_title(i))
		elif node is Tree:
			var tree:Tree=node
			for c in tree.columns:out.append(tree.get_column_title(c))
			var item:=tree.get_root()
			while item!=null:
				for c in tree.columns:out.append(item.get_text(c))
				item=item.get_next_in_tree()
	return out

func test_every_label_button_and_placeholder_reads_on_paper()->void:
	_train(22)
	MilitaryCampaign.create_field_army(20,"Levy band 1")
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		for service:String in ["army","navy","air"]:
			var panel:CanvasLayer=auto_free(ArmyPanel.new());panel.domain=service;add_child(panel)
			if service=="army":panel.choose_verb("attack");panel.choose_place(city_id);panel._give(false)
			await get_tree().process_frame
			var nodes:Array=[];_walk(panel.panel,nodes)
			var checked:=0
			for node in nodes:
				var where:="%s %s %s" % [mode,service,(node as Node).get_path()]
				if node is Label and (node as Label).text!="":
					var ratio:=_contrast((node as Label).get_theme_color("font_color"),_ground(node))
					assert_float(ratio).override_failure_message("%s '%s' contrast %.2f" % [where,(node as Label).text.left(40),ratio]).is_greater_equal(4.5)
					checked+=1
				elif node is LineEdit:
					var ratio:=_contrast((node as LineEdit).get_theme_color("font_placeholder_color"),_ground(node))
					assert_float(ratio).override_failure_message("%s placeholder contrast %.2f" % [where,ratio]).is_greater_equal(4.5)
					checked+=1
				elif node is Button and (node as Button).text!="":
					var button:Button=node
					var state:=["font_disabled_color","disabled",3.0] if button.disabled else ["font_color","normal",4.5]
					var ratio:=_contrast(button.get_theme_color(String(state[0])),T.DOCK_BG.lerp(Color((button.get_theme_stylebox(String(state[1])) as StyleBoxFlat).bg_color,1.0),(button.get_theme_stylebox(String(state[1])) as StyleBoxFlat).bg_color.a))
					assert_float(ratio).override_failure_message("%s '%s' contrast %.2f" % [where,button.text,ratio]).is_greater_equal(float(state[2]))
					checked+=1
			assert_int(checked).is_greater(10)
			panel.queue_free();await get_tree().process_frame

func test_no_jargon_or_shouting_on_the_army_screen()->void:
	_train(22)
	MilitaryCampaign.create_field_army(20,"Levy band 1")
	var panel:=_panel()
	panel.choose_verb("attack");panel.choose_place(city_id)
	var banned:=["NO OBJECTIVE","OBJECTIVE  •","CURRENT","Load","· D","Team · 1","personnel","FIELD OPERATIONS","COMMANDERS EXECUTE","ISSUE OBJECTIVE","Operating zone","subordinates"]
	var caps:=RegEx.create_from_string("\\b[A-Z]{3,}\\b")
	var all:=_texts(panel)
	assert_bool(all.size()>20).is_true()
	for text in all:
		for word in banned:
			assert_bool(word in text).override_failure_message("jargon '%s' in '%s'" % [word,text]).is_false()
		assert_object(caps.search(text)).override_failure_message("shouting in '%s'" % text).is_null()
	assert_bool("Home guard" in all).is_true()
	assert_bool("No orders" in all).is_true()
