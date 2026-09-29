extends GdUnitTestSuite
## The effect explainer (scripts/effect_explainer.gd) covers every research
## effect, says it in plain words, matches the engine's own readers and ledger,
## and the Research pages show it: the dock's three tabs and field report, the
## research atlas and the discovery announcement.

const Explainer:=preload("res://scripts/effect_explainer.gd")
const Society:=preload("res://scripts/society_model.gd")
const EarlyCare:=preload("res://scripts/early_life_conditions.gd")
const Inquiry:=preload("res://scripts/hud/content/dock_content_inquiry.gd")
const Atlas:=preload("res://scripts/hud/research_atlas.gd")
const DiscoveryPopup:=preload("res://scripts/hud/discovery_popup.gd")
const KNOWN:=["drainage","clean_water","wound_cleaning","food_drying","tallies","labor_rotations","cordage","herbal_classification"]

class FakeHud extends Control:
	func request_immediate_dock_refresh()->void:pass
	func open_detail(_report:Variant)->void:pass

class FakeTerrain extends Node:
	func _change_research_domain_allocation(_id:String,_delta:int)->void:pass

class Host extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value

func before_test()->void:
	GameState.reset_for_new_world(515151);DiscoverySystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(160)
	GameState.population_allocations["Knowledge"]=8
	GameState.elapsed_days=400
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	DiscoverySystem.initialize()
	for id:String in KNOWN:
		if not id in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=0.6
		GameState.discovery_log.push_front(DiscoverySystem.player_facing_discovery_event({"id":id,"day":120,"name":id}))
	DiscoverySystem.refresh_operating_effects()
	Explainer.invalidate()

# --- helpers --------------------------------------------------------------------

static var SNAKE:=RegEx.create_from_string("[a-z0-9]+_[a-z0-9]+")

func _assert_plain(text:String,where:String)->void:
	assert_bool(text.contains("_")).override_failure_message("%s shows an underscore: %s" % [where,text]).is_false()
	assert_object(SNAKE.search(text)).override_failure_message("%s shows snake_case: %s" % [where,text]).is_null()

func _data_keys()->Dictionary:
	var keys:Dictionary={}
	var root:=DirAccess.open("res://data/research")
	for folder:String in root.get_directories():
		if not folder.begins_with("effects"):continue
		var dir:=DirAccess.open("res://data/research/"+folder)
		for file:String in dir.get_files():
			if not file.ends_with(".json"):continue
			var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/research/%s/%s" % [folder,file]))
			if not parsed is Dictionary:continue
			for id:Variant in (parsed as Dictionary).get("items",{}):
				var row:Variant=parsed.items[id]
				if row is Dictionary:
					for key:Variant in (row as Dictionary).get("effects",{}):keys[String(key)]=true
	return keys

func _scripts(path:String="res://scripts",into:Array[String]=[])->Array[String]:
	var dir:=DirAccess.open(path)
	for file:String in dir.get_files():
		if file.ends_with(".gd"):into.append(path+"/"+file)
	for folder:String in dir.get_directories():
		if folder!="hud":_scripts(path+"/"+folder,into)
	return into

func _labels(node:Node)->Array[String]:
	var texts:Array[String]=[]
	for child:Node in node.find_children("*","Label",true,false):texts.append((child as Label).text)
	return texts

func _click(control:Control)->void:
	var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true
	control.gui_input.emit(press)

# --- coverage ---------------------------------------------------------------------

func test_every_effect_key_in_the_data_and_catalogs_has_an_entry()->void:
	var keys:=_data_keys()
	assert_int(keys.size()).is_greater(60)
	for definition:Dictionary in DiscoverySystem.catalog:
		for key:Variant in definition.get("effects",{}):keys[String(key)]=true
	for key:String in Society.EFFECT_LIMITS:keys[key]=true
	for key:String in keys:
		assert_dict(Explainer.entry(key)).override_failure_message("No explanation for effect %s" % key).is_not_empty()
		assert_str(Explainer.label(key)).is_not_empty()
		assert_str(String(Explainer.entry(key).get("what",""))).is_not_empty()
	# And nothing explained is outside the registered effects, and which way is
	# better is the engine's own (SocietyModel.LOWER_IS_BETTER; fewer births
	# chosen is neither).
	for key:String in Explainer.keys():
		assert_bool(Society.EFFECT_LIMITS.has(key)).override_failure_message("%s is not a registered effect" % key).is_true()
		var expected:=0 if key=="fertility_transition" else (-1 if key in Society.LOWER_IS_BETTER else 1)
		assert_int(Explainer.good(key)).override_failure_message("%s direction" % key).is_equal(expected)

func test_describe_never_shows_snake_case()->void:
	for key:String in Explainer.keys():
		for amount:float in [0.012,-0.02,0.0]:
			for adoption:float in [1.0,0.4]:
				var said:=Explainer.describe(key,amount,adoption)
				for field:String in ["label","amount_words","sentence","now_words","held"]:_assert_plain(String(said[field]),"%s %s" % [key,field])
				for line:Variant in said.feeds:_assert_plain(String(line),"%s feed" % key)
				var row:=Explainer.ledger_row(key,amount,adoption)
				for field:String in ["label","amount","usage","headline","sentence","direction"]:_assert_plain(String(row[field]),"%s row %s" % [key,field])
	for row:Dictionary in Explainer.total_rows():
		for note:Variant in row.notes:_assert_plain(String(note),"total note")
	assert_str(Explainer.summary({"health_protection":0.01,"water_safety":0.02,"fatigue":-0.005,"cohesion":0.001})).is_equal("Safe drinking water, protection from sickness, weariness and 1 more")
	assert_str(Explainer.summary({"health_protection":0.01,"water_safety":0.02})).is_equal("Safe drinking water and protection from sickness")

# --- the engine's readers -----------------------------------------------------------

## Every key some simulation code reads through the discovery totals: literal
## reads, the capacity formula, early care's channels and the resource yields
## looked up by name. HUD pages are not the simulation.
func _read_keys()->Dictionary:
	var read:Dictionary={}
	var patterns:Array[RegEx]=[
		RegEx.create_from_string("(?:discovery|DiscoverySystem|society_model)\\.effect\\(\"([a-z_]+)\"\\)"),
		RegEx.create_from_string("(?<![A-Za-z_.])effect\\(\"([a-z_]+)\"\\)"),
		RegEx.create_from_string("(?<![A-Za-z_.])_effect\\(\"([a-z_]+)\"\\)"),
		RegEx.create_from_string("_fx\\(inputs,\"([a-z_]+)\"\\)")]
	for path:String in _scripts():
		if path.ends_with("/effect_explainer.gd"):continue
		var source:=FileAccess.get_file_as_string(path)
		for pattern:RegEx in patterns:
			for found:RegExMatch in pattern.search_all(source):read[found.get_string(1)]=path
	for key:String in EarlyCare.RELIEF_CHANNELS:read[key]="early_life_conditions.gd relief"
	for category:Dictionary in EarlyCare.CATEGORIES:
		for key:String in category.channels:read[key]="early_life_conditions.gd %s" % category.id
	var names:Dictionary={}
	for resource:String in ResourceSystem.catalog:names[resource]=true
	for resource:String in ResourceSystem.MATERIAL_PROFILES:names[resource]=true
	for resource:String in names:
		if ResourceSystem._is_material_resource(resource):read[resource.to_lower().replace(" ","_")+"_yield"]="resource_system.gd yield"
	return read

func test_inert_list_matches_the_code()->void:
	var read:=_read_keys()
	for key:String in Explainer.keys():
		assert_bool(Explainer.is_inert(key)).override_failure_message("%s: inert=%s but read=%s" % [key,Explainer.is_inert(key),String(read.get(key,"nowhere"))]).is_equal(not read.has(key))
	assert_array(Explainer.inert_keys()).contains_exactly_in_any_order(["water_access","fuel_efficiency","repair_capacity","chemical_control","mining_output","logistics_endurance","naval_capacity","fuel_demand"])
	# Fiber Plants is extracted, but its yield is looked up under its own name.
	assert_bool(read.has("fiber_plants_yield")).is_true()
	# Demand for timber guides research only: the capacities never read it.
	assert_array(Explainer.steer_only_keys()).contains_exactly(["timber_pressure"])
	assert_bool("timber_pressure" in Society.CAPACITY_EFFECTS).is_false()

func test_recorded_coefficients_still_match_the_source()->void:
	for key:String in Explainer.keys():
		for feed:Dictionary in Explainer.entry(key).feeds:
			for guard:Array in feed.get("guards",[]):
				var source:=FileAccess.get_file_as_string("res://scripts/"+String(guard[0]))
				assert_bool(source.contains(String(guard[1]))).override_failure_message("%s: %s no longer contains %s" % [key,guard[0],guard[1]]).is_true()
			if not feed.has("capacity") and not feed.has("cover") and not feed.has("relief"):
				assert_bool(not (feed.get("guards",[]) as Array).is_empty()).override_failure_message("%s has a reading with no source guard" % key).is_true()

func test_capacity_and_care_readings_are_complete()->void:
	for key:String in Society.CAPACITY_EFFECTS:
		var listed:Array[String]=[]
		for feed:Dictionary in Explainer.entry(key).feeds:
			if feed.has("capacity"):listed.append(String(feed.capacity))
		assert_array(listed).override_failure_message("%s capacities" % key).contains_exactly_in_any_order(Explainer.capacity_readers(key))
	for category:Dictionary in EarlyCare.CATEGORIES:
		for key:String in category.channels:
			var covered:=false
			for feed:Dictionary in Explainer.entry(key).feeds:covered=covered or String(feed.get("cover",""))==String(category.id)
			assert_bool(covered).override_failure_message("%s does not say it covers %s" % [key,category.id]).is_true()
	for key:String in EarlyCare.RELIEF_CHANNELS:
		var relief:=false
		for feed:Dictionary in Explainer.entry(key).feeds:relief=relief or feed.has("relief")
		assert_bool(relief).is_true()

# --- numbers ----------------------------------------------------------------------

func test_describe_translates_amounts_with_the_engine_coefficients()->void:
	var said:=Explainer.describe("health_protection",0.012,1.0)
	assert_str(String(said.label)).is_equal("Protection from sickness")
	assert_str(String(said.amount_words)).is_equal("+1.2%")
	assert_str(String(said.now_words)).is_equal("+1.2% now → the health the people settle toward: up about 1.2 points of 100")
	assert_str(String(Explainer.describe("health_protection",0.012,0.5).now_words)).contains("up about 0.60 points of 100")
	var births:=Explainer.describe("maternal_safety",0.01,1.0)
	assert_array(births.feeds).contains(["Mothers who die in childbirth: down about 1% (counts up to 65 in 100)"])
	# Costs read the other way round.
	assert_int(Explainer.tone("disease_exposure",0.01)).is_equal(-1)
	assert_int(Explainer.tone("fatigue",-0.01)).is_equal(1)
	assert_str(String(Explainer.describe("disease_exposure",0.01).feeds[0])).is_equal("The health the people settle toward: down about 0.18 points of 100")
	# Inert keys say so and claim nothing.
	var fuel:=Explainer.describe("fuel_demand",0.02)
	assert_bool(fuel.inert).is_true();assert_array(fuel.feeds).is_empty()
	assert_str(String(fuel.now_words)).starts_with("No effect in the simulation yet")

func test_capacity_slopes_are_measured_on_the_capacity_formula()->void:
	var model=DiscoverySystem.society_model
	var inputs:=model.capacity_inputs()
	inputs["health"]=0.5;inputs["fx:health_protection"]=0.0;inputs["fx:disease_exposure"]=0.0;inputs["fx:health_risk"]=0.0
	inputs["officials:health"]=0.0
	inputs["cohesion"]=0.5;inputs["legitimacy"]=0.5;inputs["fields"]=6.0;inputs["treasures"]=0.0;inputs["fx:cohesion"]=0.0
	inputs["officials:culture"]=0.0;inputs["values:culture"]=0.0
	model._today.inputs=inputs
	Explainer.invalidate()
	assert_float(Explainer.capacity_slope("health_protection","health")).is_equal_approx(0.22,0.0001)
	assert_float(Explainer.capacity_slope("disease_exposure","health")).is_equal_approx(-0.18,0.0001)
	assert_float(Explainer.capacity_slope("cohesion","culture")).is_equal_approx(0.11,0.0001)
	assert_array(Explainer.capacity_readers("route_speed")).contains_exactly_in_any_order(["knowledge","logistics"])
	assert_array(Explainer.capacity_readers("labor_efficiency")).contains_exactly_in_any_order(["labor","production"])

func test_totals_follow_the_engine_ledger()->void:
	var model=DiscoverySystem.society_model
	var raw:=Explainer.raw_totals()
	assert_bool(raw.has("health_protection")).is_true()
	var keys:Dictionary={}
	for key:String in raw:keys[key]=true
	for key:String in model.effect_totals:keys[key]=true
	for key:String in keys:
		var slot:Dictionary=raw.get(key,{"sum":0.0,"by":{}})
		var ceiling:Vector2=model.era_ceiling(key)
		var expected:=clampf(float(slot.sum),ceiling.x,ceiling.y)
		if Society.SPECIALIST_UPKEEP.has(key) and model.specialist_excess>0.0:
			var limit:Vector2=Society.EFFECT_LIMITS.get(key,Vector2(-0.5,0.8))
			expected=clampf(expected+float(Society.SPECIALIST_UPKEEP[key])*model.specialist_excess,limit.x,limit.y)
		assert_float(float(model.effect(key))).override_failure_message("%s total" % key).is_equal_approx(expected,0.000001)
		var parts:=0.0
		for id:Variant in slot.by:parts+=float(slot.by[id])
		assert_float(parts).is_equal_approx(float(slot.sum),0.000001)
	# The explained total is the engine's own, and names where it comes from.
	for total:Dictionary in Explainer.totals():
		assert_float(float(total.total)).is_equal_approx(float(model.effect(String(total.key))),0.000001)
	var protection:Dictionary={}
	for total:Dictionary in Explainer.totals():
		if String(total.key)=="health_protection":protection=total
	var sources:Array=(protection.contributors as Array).map(func(item:Dictionary)->String:return String(item.id))
	assert_array(sources).contains(["herbal_classification"])
	# A practice counts by how widely it is used...
	var amount:=float(DiscoverySystem.discovery_definition("herbal_classification").effects.health_protection)
	assert_float(Explainer.contribution("herbal_classification","health_protection")).is_equal_approx(amount*0.6*Explainer.focus_scale("health"),0.000001)
	# ...and, for one that needs supplies, only as far as they reach: wound
	# washing needs water carried for it, and none is in this state.
	assert_float(Explainer.practice_level("wound_cleaning")).is_equal(0.0)
	assert_array(sources).not_contains(["wound_cleaning"])
	assert_str(Explainer.usage_words("wound_cleaning")).is_equal("taken up by 60 in 100, but it needs water carried for washing wounds, which covers only 0 in 100 of them")

func test_a_total_at_its_age_limit_says_it_is_held_back()->void:
	var model=DiscoverySystem.society_model
	var ceiling:Vector2=model.era_ceiling("health_protection")
	model.effect_totals["health_protection"]=ceiling.y
	assert_str(Explainer.held_words("health_protection",0.01)).starts_with("Held back by our age")
	assert_str(Explainer.held_words("health_protection",-0.01)).is_empty()
	model.effect_totals["health_protection"]=0.0
	assert_str(Explainer.held_words("health_protection",0.01)).is_empty()

# --- the pages ----------------------------------------------------------------------

func test_inquiry_dock_builds_with_explanations_for_a_small_state()->void:
	var hud:=FakeHud.new();auto_free(hud)
	var terrain:=FakeTerrain.new();auto_free(terrain)
	var inquiry=Inquiry.new(terrain,hud)
	# What we know: the totals first, grouped by field.
	var known:Dictionary=inquiry.tab(2)
	var acts:Dictionary=known.blocks[0]
	assert_str(String(acts.type)).is_equal("impact")
	assert_str(String(acts.heading)).is_equal("WHERE YOUR KNOWLEDGE ACTS")
	var health:Dictionary={}
	for group:Dictionary in acts.groups:
		if String(group.id)=="health":health=group
	assert_dict(health).is_not_empty()
	var labels:Array=(health.rows as Array).map(func(row:Dictionary)->String:return String(row.label))
	assert_array(labels).contains(["Protection from sickness"])
	# Rendered: a field opens to its rows, a row opens to everywhere it acts.
	var box:=VBoxContainer.new();add_child(box);auto_free(box)
	box.size=Vector2(540,900)
	DockBlocks.render(box,known.blocks)
	var ledger:Node=box.find_children("ImpactLedger*","",true,false)[0]
	var group_header:PanelContainer=ledger.find_child("Group_health",true,false)
	_click(group_header)
	var row:PanelContainer=ledger.find_child("Effect_health_protection",true,false)
	assert_object(row).is_not_null()
	_click(row)
	var detail:Control=row.find_child("Detail",true,false)
	assert_bool(detail.visible).is_true()
	var words:="\n".join(_labels(detail))
	assert_str(words).contains("Where it acts").contains("The health the people settle toward").contains("The Health capacity")
	assert_bool(inquiry.effect_state.has("r:health_protection")).is_true()
	for text:String in _labels(ledger):_assert_plain(text,"dock label")
	# An opened finding is followed by its effects, one row each.
	inquiry.expanded_domains["health"]=true;inquiry.expanded_discoveries["clean_water"]=true
	var opened:Array=inquiry.tab(2).blocks
	var found:=false
	for block:Dictionary in opened:
		if String(block.get("type",""))=="impact" and not block.has("groups"):
			for effect_row:Dictionary in block.rows:found=found or String(effect_row.id).begins_with("clean_water:")
	assert_bool(found).is_true()
	# Knowledge tree: a known question opens to what it does now, an open one
	# to what it would do at full use.
	inquiry.tree_domain="health"
	inquiry.expanded_tech["clean_water"]=true
	var does:Array=[]
	for block:Dictionary in inquiry.tab(1).blocks:
		if String(block.get("type",""))=="impact":does=block.rows
	assert_array(does).is_not_empty()
	assert_str(String((does[0] as Dictionary).usage)).contains("taken up by 60 in 100")
	var open_question:=""
	for technology:Dictionary in DiscoverySystem.technology_tree("health"):
		if String(technology.status) in ["AVAILABLE","RESEARCHING"] and not (technology.get("effects",{}) as Dictionary).is_empty():open_question=String(technology.id);break
	if open_question!="":
		inquiry.expanded_tech.clear();inquiry.expanded_tech[open_question]=true
		var would:Array=[]
		for block:Dictionary in inquiry.tab(1).blocks:
			if String(block.get("type",""))=="impact":would=block.rows
		assert_str(String((would[0] as Dictionary).usage)).starts_with("at full use")
	assert_str(String(Explainer.discovery_rows("well_siting",false)[0].usage)).starts_with("at full use")
	# The field report: what the field's knowledge does now.
	var report:Dictionary=inquiry._domain_report("health")
	var field_rows:Array=[]
	for block:Dictionary in report.blocks:
		if String(block.get("heading",""))=="WHAT THIS FIELD'S KNOWLEDGE DOES":field_rows=block.rows
	assert_array(field_rows.map(func(item:Dictionary)->String:return String(item.key))).contains(["health_protection"])

func test_question_cards_say_what_they_would_bring()->void:
	var board:VBoxContainer=auto_free(preload("res://scripts/hud/inquiry_board.gd").new())
	board.setup({"fields":[],"investigations":[{"id":"well_siting","name":"Well Siting","dynamic":"infrastructure","progress":0.3,"research_workforce":1.5,"bottleneck":"EARLY EVIDENCE","effects":DiscoverySystem.discovery_definition("well_siting").effects}],
		"on_tree":func():pass,"on_work":func():pass,"on_domain":func(_d:String):pass})
	var line:Label=board.find_child("WouldBring",true,false)
	assert_object(line).is_not_null()
	assert_str(line.text).starts_with("Would bring: ")
	_assert_plain(line.text,"question card")

func test_research_atlas_explains_known_and_open_questions()->void:
	GameState.population_allocations["Knowledge"]=24
	DiscoverySystem._refresh_active_investigations()
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1440,900);add_child(viewport)
	var view:=Atlas.new();viewport.add_child(view)
	view.set_view("known");view.select("clean_water")
	var ledger:Node=view.detail_body.find_child("ImpactLedger",true,false)
	assert_object(ledger).is_not_null()
	assert_str("\n".join(_labels(view.detail_body))).contains("WHAT IT DOES").contains("Safe drinking water")
	view.set_view("tree")
	var open:=""
	for item:Dictionary in view.records:
		if bool(item.exposed) and not bool(item.known) and not (item.effects as Dictionary).is_empty():open=String(item.id);break
	if open!="":
		view.select(open)
		assert_str("\n".join(_labels(view.detail_body))).contains("WHAT IT WOULD DO")
	for text:String in _labels(ledger):_assert_plain(text,"atlas label")

func test_discovery_announcement_says_what_each_effect_moves()->void:
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1200,900);add_child(canvas)
	var host:=Host.new();canvas.add_child(host)
	var hud:=Control.new();host.add_child(hud)
	var popup=DiscoveryPopup.announce(host,hud,[{"id":"clean_water","day":12}])
	for key:String in DiscoverySystem.discovery_definition("clean_water").effects:
		var card:Dictionary=popup.effect_cards[key]
		assert_str((card.meaning as Label).text).is_not_empty()
		_assert_plain((card.meaning as Label).text,"announcement")
		assert_bool(bool(card.beneficial)).is_equal(Explainer.tone(key,float(DiscoverySystem.discovery_definition("clean_water").effects[key]))>0)
	popup.close()
