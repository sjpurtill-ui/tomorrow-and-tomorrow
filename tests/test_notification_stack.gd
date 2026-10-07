extends GdUnitTestSuite
## The one notice stack at the top right (hud/notification_stack.gd) and its
## model (hud/notification_model.gd): categories, tiers, merging, clocks, the
## log, and the court's "what came of your order" notice.
const Chronicle:=preload("res://scripts/chronicle.gd")
const Model:=preload("res://scripts/hud/notification_model.gd")
const Stack:=preload("res://scripts/hud/notification_stack.gd")
const Card:=preload("res://scripts/hud/chronicle_card.gd")
const Lives:=preload("res://scripts/court_lives.gd")

class SheetHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:=PanelContainer.new()
	var detail_dock:=PanelContainer.new()
	var sections:Array=[]
	func _init()->void:
		add_child(dock);add_child(detail_dock);dock.visible=false;detail_dock.visible=false
		section_requested.connect(func(section:String,_sub:int)->void:sections.append(section))
	func right_stack_top()->float:return 640.0

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(90210)
	GameState.research_notification_mode="milestones"
	Chronicle.pending_cards.clear();Chronicle.pending_notes.clear()
	Model.reset()

func _stack(width:int=1280,height:int=720)->Array:
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(width,height);add_child(canvas)
	var host:=Node.new();canvas.add_child(host)
	var hud:=SheetHud.new();hud.size=Vector2(width,height);host.add_child(hud)
	var stack:=Stack.ensure(host,hud)
	await get_tree().process_frame
	return [stack,hud,canvas]


# --- The model -----------------------------------------------------------------

func test_each_told_line_gets_a_category_and_a_tier()->void:
	var callback:={"key":"court:callback:o1","title":"What came of your order “dig two wells”","text":"Lisse has news.","tier":"notice","kind":"court","action":{"kind":"court","focus":{"person_id":3}}}
	assert_str(Model.category_of(callback)).is_equal("court")
	assert_str(Model.tier_of(callback,"court")).is_equal("notable")
	var prisoner:={"key":"captive:1","title":"A spy is caught","tier":"notice","kind":"court","action":{"kind":"prisoner","prisoner_id":"p1"}}
	assert_str(Model.category_of(prisoner)).is_equal("spies")
	assert_str(Model.tier_of(prisoner,"spies")).is_equal("urgent")
	var raid:={"key":"war:raid:5","title":"They burned the granary","tier":"notice","kind":"war"}
	assert_str(Model.tier_of(raid,Model.category_of(raid))).is_equal("urgent")
	assert_str(Model.category_of({"title":"The wells run low","tier":"notice","kind":"work"})).is_equal("food")
	assert_str(Model.category_of({"title":"Floodwater in the low fields","tier":"notice","kind":"work"})).is_equal("weather")
	assert_str(Model.category_of({"title":"A caravan comes home","tier":"notice","kind":"settlement"})).is_equal("travel")
	# A moment is the Chronicle's own card; a whisper only goes to the log.
	assert_str(Model.tier_of({"tier":"moment","kind":"omen"},"faith")).is_equal("card")
	assert_str(Model.tier_of({"tier":"whisper","kind":"work"},"people")).is_equal("minor")

func test_the_discovery_setting_decides_whether_learning_pops_up()->void:
	var season:={"key":"learned:12","title":"What the spring taught","text":"This season the people learned: tanning.","tier":"notice","kind":"discovery"}
	assert_str(Model.tier_of(season,"learning","milestones")).is_equal("minor")
	assert_str(Model.tier_of(season,"learning","all")).is_equal("notable")
	assert_str(Model.tier_of(season,"learning","quiet")).is_equal("minor")

func test_a_notice_is_one_plain_sentence()->void:
	var n:=Model.normalize({"title":"Scouts home","text":"They walked 300 km east and back along the river, then north to the hills where the snow lies. They met nobody. They want bread."})
	assert_str(String(n.text)).is_equal("They walked 300 km east and back along the river, then north to the hills where the snow lies.")
	var short:=Model.normalize({"title":"Scouts home","text":"They walked 300 km east. They met nobody. They want bread."})
	assert_str(String(short.text)).is_equal("They walked 300 km east. They met nobody.")
	var long:=Model.one_sentence("word ".repeat(80)+"end.")
	assert_bool(long.length()<=192).is_true()
	assert_bool(long.ends_with("…")).is_true()
	# Only words: the first sentence leads.
	var bare:=Model.normalize({"text":"Not founded here. No known fresh water within reach."})
	assert_str(String(bare.title)).is_equal("Not founded here")
	assert_str(String(bare.text)).is_equal("No known fresh water within reach.")


# --- The Chronicle feeds the stack ------------------------------------------------

func test_the_chronicle_queues_what_it_tells_and_a_folded_repeat_counts_on_it()->void:
	var first:=Chronicle.record({"key":"t:1","title":"The wells run low","text":"For the dead of the dry year.","tier":"notice","kind":"drought","day":10,"fold_as":"wells"})
	assert_str(String(first.tier)).is_equal("notice")
	assert_int(Chronicle.pending_notes.size()).is_equal(1)
	var again:=Chronicle.record({"key":"t:2","title":"The wells run low","text":"Another for the dead.","tier":"notice","kind":"drought","day":40,"fold_as":"wells"})
	assert_str(String(again.get("same_as",""))).is_equal("t:1")
	assert_int(Chronicle.pending_notes.size()).is_equal(2)
	var parts:Array=await _stack()
	var stack:CanvasLayer=parts[0]
	await get_tree().process_frame
	assert_int(stack.rows.size()).is_equal(1)
	assert_int(int(stack.rows[0].count)).is_equal(2)
	assert_str(String(stack.rows[0].text)).is_equal("Another for the dead.")
	# A whisper (the routine tally) never pops up.
	Chronicle.record({"key":"t:3","title":"The season's tally","tier":"whisper","kind":"hearth_count","day":41})
	await get_tree().process_frame
	assert_int(stack.rows.size()).is_equal(1)


func test_only_the_primary_lines_pop_up()->void:
	# Routine news goes to the log; war, strangers, thirst, the court's answers,
	# a great work and a first in learning are the primary notices.
	for routine:Dictionary in [{"key":"work_done:3","title":"A hall is raised","kind":"settlement"},{"key":"demo|1","title":"Three were born","kind":"birth"},{"key":"scout:4","title":"Scouts came home","kind":"scout"},{"key":"land_find:2","title":"Ochre found","kind":"work"},{"key":"annal:9","title":"The year's tale","kind":"annal"}]:
		var routine_entry:=routine.duplicate();routine_entry["tier"]="notice"
		assert_str(Model.from_chronicle(routine_entry).tier).is_equal("minor")
	for primary:Dictionary in [{"key":"contact:2","title":"Strangers come","kind":"contact"},{"key":"great_work:1","title":"The stone ring is raised","kind":"ceremony"},{"key":"court:callback:o1","title":"What came of your order","kind":"court"},{"key":"d:1","title":"A dry year","kind":"drought"},{"key":"discovery:5","title":"Fire is tamed","kind":"discovery","first":true}]:
		var primary_entry:=primary.duplicate();primary_entry["tier"]="notice"
		assert_str(Model.from_chronicle(primary_entry).tier).is_equal("notable")


# --- The stack -------------------------------------------------------------------

func test_notices_stack_at_the_top_right_and_merge_repeats()->void:
	var parts:Array=await _stack()
	var stack:CanvasLayer=parts[0]
	for i in 3:Model.push({"category":"scouts","title":"Scouts came home","plural":"%d scout parties came home","text":"Party %d is back." % i,"group":"scouts|home"})
	Model.push({"category":"trade","title":"Barter at the ford","text":"We gave 12 hides for 30 baskets of grain."})
	await get_tree().process_frame;await get_tree().process_frame
	assert_int(stack.rows.size()).is_equal(2)
	var scouts:Dictionary=stack.rows.filter(func(n:Dictionary)->bool:return String(n.category)=="scouts")[0]
	assert_str(Model.headline(scouts)).is_equal("3 scout parties came home")
	for n:Dictionary in stack.rows:
		var row:Control=stack._views[int(n.id)]
		assert_bool(row.visible).is_true()
		var rect:=row.get_global_rect()
		# Top right: flush with the right edge, under the status strip.
		assert_float(rect.end.x).is_equal_approx(1280.0-Stack.RIGHT,1.0)
		assert_bool(rect.position.y>=Stack.TOP).is_true()
		assert_bool(rect.end.y<=640.0).is_true()
		assert_str((row.get_meta("kicker") as Label).text).contains(Model.label(String(n.category)).to_upper())
	assert_bool(stack.pill.visible).is_true()

func test_notable_notices_fade_on_their_own_and_urgent_ones_wait()->void:
	var parts:Array=await _stack()
	var stack:CanvasLayer=parts[0]
	Model.push({"category":"war","tier":"urgent","title":"A band is coming at Reedwater","text":"About 40 fighters, 2 days away."})
	Model.push({"category":"people","title":"A child is born","text":"Tova's daughter."})
	stack._intake()
	stack._layout(0.0)
	assert_str(String(stack.rows[0].tier)).is_equal("urgent")
	stack._layout(Model.NOTABLE_SECONDS+0.5)
	assert_int(stack.rows.size()).is_equal(1)
	assert_str(String(stack.rows[0].category)).is_equal("war")
	# The log keeps both.
	assert_int(Model.history.size()).is_equal(2)
	stack.dismiss(stack.rows[0])
	assert_int(stack.rows.size()).is_equal(0)

func test_at_most_four_show_and_the_rest_wait_their_turn()->void:
	var parts:Array=await _stack()
	var stack:CanvasLayer=parts[0]
	for word in ["granary","hall","well","road","wall","shrine"]:Model.push({"category":"building","title":"The %s is finished" % word,"text":"Raised by the builders."})
	stack._intake()
	assert_int(stack.rows.size()).is_equal(Stack.MAX_ROWS)
	assert_int(stack.waiting.size()).is_equal(2)
	# An urgent notice never waits behind routine ones.
	Model.push({"category":"spies","tier":"urgent","title":"An agent is caught","text":"Held at the hearth."})
	stack._intake()
	assert_str(String(stack.rows[0].category)).is_equal("spies")

func test_the_column_waits_while_a_wide_sheet_covers_it()->void:
	var parts:Array=await _stack()
	var stack:CanvasLayer=parts[0];var hud:SheetHud=parts[1]
	Model.push({"category":"food","title":"Stores are thinning","text":"14 days of food left."})
	stack._intake();stack._layout(0.0)
	hud.dock.position=Vector2(88,64);hud.dock.size=Vector2(1180,640);hud.dock.visible=true
	var left:=float(stack.rows[0].left)
	stack._layout(2.0)
	assert_bool(stack.held).is_true()
	assert_bool((stack._views[int(stack.rows[0].id)] as Control).visible).is_false()
	assert_float(float(stack.rows[0].left)).is_equal(left)

func test_a_click_opens_what_the_notice_is_about()->void:
	var parts:Array=await _stack()
	var stack:CanvasLayer=parts[0];var hud:SheetHud=parts[1]
	Model.push({"category":"building","title":"The granary is finished","text":"It holds 400 baskets.","action":{"kind":"section","section":"construction","sub":0}})
	stack._intake()
	stack.open(stack.rows[0])
	assert_array(hud.sections).contains(["construction"])
	assert_int(stack.rows.size()).is_equal(0)
	# The log lists it and opens it again.
	stack.toggle_log()
	assert_bool(stack.log_panel.visible).is_true()
	assert_int(stack.log_list.get_child_count()).is_equal(1)

func test_the_moment_card_heads_the_same_column()->void:
	Chronicle.record({"title":"Smoke on the horizon","tier":"moment","kind":"scout","day":1})
	var parts:Array=await _stack()
	var stack:CanvasLayer=parts[0];var hud:SheetHud=parts[1]
	var card:=Card.flush(hud.get_parent(),hud)
	Model.push({"category":"war","title":"Drill at the ford","text":"20 fighters trained."})
	await get_tree().process_frame;await get_tree().process_frame;await get_tree().process_frame
	assert_bool(card.showing).is_true()
	var notice:Control=stack._views[int(stack.rows[0].id)]
	assert_bool(notice.position.y>=card.panel.position.y+card.panel.size.y).is_true()
	assert_float(card.panel.get_global_rect().end.x).is_between(1250.0,1290.0)
	assert_str(card.eyebrow.text).starts_with("SCOUTS")
	# The moment itself is in the log, not a second notice.
	assert_int(stack.rows.size()).is_equal(1)
	assert_bool(Model.history.any(func(n:Dictionary)->bool:return String(n.title)=="Smoke on the horizon")).is_true()


# --- The court's callback --------------------------------------------------------

func test_the_court_tells_which_order_came_back_and_how_to_hear_it()->void:
	var told:=Lives._tell_chronicle({"kind":"callback","day":50,"title":"An Old Order Remembered","text":"Lisse has word for you of what came of it: the stores are fuller."},
		{"key":"court:callback:o9","focus":{"person_id":7},"title":"What came of your order “Dig two wells”","category":"court",
		"text":"Lisse reports, 40 days after your order: the stores are fuller. Summon them in the court to hear it."})
	assert_str(String(told.title)).is_equal("What came of your order “Dig two wells”")
	var n:=Model.from_chronicle(Chronicle.pending_notes.back())
	assert_str(String(n.category)).is_equal("court")
	assert_str(String(n.tier)).is_equal("notable")
	assert_str(String(n.text)).contains("40 days after your order")
	assert_str(String(n.text)).contains("the stores are fuller")
	assert_str(Stack.action_words(n.action)).is_equal("summon them in the court")


# --- The content audit ---------------------------------------------------------

func test_the_audit_rules_retier_and_reword_the_frequent_lines()->void:
	var gone:=Model.from_chronicle({"key":"split_food:settlement_3:gone:900","title":"Koka's Food Is Gone","text":"At your split Koka is starving. Put 12 more on getting food.","tier":"notice","kind":"warning","domain":"food"})
	assert_str(String(gone.category)).is_equal("food")
	assert_str(String(gone.tier)).is_equal("urgent")
	assert_str(String((gone.action as Dictionary).get("section",""))).is_equal("settlement")
	var fed:=Model.from_chronicle({"key":"split_fed:settlement_3:901","title":"Koka's Leader Puts More on Food","text":"Its overseer put 85 in 100 hands on food.","tier":"notice","kind":"warning"})
	assert_str(String(fed.tier)).is_equal("notable")
	var cairn:=Model.from_chronicle({"key":"court:rite:902:abc","title":"A cairn of stones for the god's word","text":"A cairn of stones: you said “Improve roads”.","tier":"notice","kind":"ceremony"})
	assert_str(String(cairn.tier)).is_equal("minor")
	var issued:=Model.from_chronicle({"key":"ev|903|Directive Issued|Routes and carrying","title":"Directive Issued","text":"Routes and carrying coordination improve.","tier":"notice","kind":"work"})
	assert_str(String(issued.title)).is_equal("Your order is under way")
	assert_str(String(issued.tier)).is_equal("minor")
	var took:=Model.from_chronicle({"key":"ev|904|Directive Succeeded|Miana Eno","title":"Directive Succeeded","text":"Miana Eno reports: priority work on roads took hold.","tier":"notice","kind":"court"})
	assert_str(String(took.title)).is_equal("Your order took hold")
	assert_str(String(took.tier)).is_equal("notable")
	var find:=Model.from_chronicle({"key":"land_find:settlement_8:905:ochre","title":"Ochre earth found near Koka","text":"Searchers found ochre earth about 17 km south of Koka.","tier":"notice","kind":"economy","action":{"kind":"section","section":"economy","sub":1}})
	assert_str(String(find.category)).is_equal("land")
	assert_str(Model.label(String(find.category))).is_equal("Land & Finds")
