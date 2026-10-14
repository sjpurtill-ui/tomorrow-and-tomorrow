extends GdUnitTestSuite
## The shared strategy-screen blocks (hud/dense_blocks.gd):
## one line per item, verbs that act, costs against stock, frames that hold
## other blocks.
const Blocks:=preload("res://scripts/hud/dock_blocks.gd")
const Dense:=preload("res://scripts/hud/dense_blocks.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

func _body()->VBoxContainer:
	var body:VBoxContainer=auto_free(VBoxContainer.new())
	body.size=Vector2(900,600)
	add_child(body)
	return body

func test_a_table_is_one_line_per_item_with_groups_tags_and_working_verbs()->void:
	var body:=_body()
	var pressed:=[]
	var clicked:=[]
	Blocks.render(body,[{"type":"table","columns":[{"key":"what","label":"What"},{"key":"when","label":"When","width":90,"align":"right"}],
		"rows":[{"group":"Unread","cells":{"what":"Armed strangers on the road · 3 reports","when":"Year 436"},"tag":{"text":"New","tone":"warn"},"button":{"label":"Read","on_press":func()->void:pressed.append("read")}},
			{"group":"Unread","cells":{"what":"A river crossing","when":"Year 430"},"on_click":func()->void:clicked.append(1)},
			{"group":"Read","cells":{"what":"Smoke to the west","when":"Year 420"},"bar":{"value":0.5}}]}])
	var rows:=body.find_children("Row_*","PanelContainer",true,false)
	assert_int(rows.size()).is_equal(3)
	for row in rows:assert_float((row as Control).get_combined_minimum_size().y).is_less_equal(Dense.ROW_HEIGHT+2.0)
	var groups:Array=body.find_children("Group_*","Label",true,false).map(func(n:Node)->String:return (n as Label).text)
	assert_array(groups).is_equal(["UNREAD","READ"])
	assert_object(rows[0].find_child("Tag",true,false)).is_not_null()
	(rows[0].find_child("Verb_Read",true,false) as Button).pressed.emit()
	assert_array(pressed).is_equal(["read"])
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	(rows[1] as Control).gui_input.emit(click)
	assert_array(clicked).is_equal([1])

func test_an_empty_table_is_one_small_line()->void:
	var body:=_body()
	Blocks.render(body,[{"type":"table","columns":[{"key":"a","label":"A"}],"rows":[],"empty":"No party is away"}])
	assert_object(body.find_child("Head",true,false)).is_null()
	var texts:Array=body.find_children("*","Label",true,false).map(func(n:Node)->String:return (n as Label).text)
	assert_array(texts).contains(["No party is away"])

func test_costs_show_have_against_need_in_green_or_red_with_the_button_beside()->void:
	var body:=_body()
	var built:=[]
	Blocks.render(body,[{"type":"costs","label":"Palisade","items":[{"resource":"Timber","have":0,"need":360},{"resource":"Stone","have":25646,"need":150}],
		"button":{"label":"Build","on_press":func()->void:built.append(1)}}])
	var timber:=body.find_child("Cost_Timber",true,false)
	var stone:=body.find_child("Cost_Stone",true,false)
	var timber_words:Label=timber.find_children("*","Label",true,false)[0]
	var stone_words:Label=stone.find_children("*","Label",true,false)[0]
	assert_str(timber_words.text).is_equal("0 / 360")
	assert_str(stone_words.text).is_equal("25,646 / 150")
	assert_object(timber_words.get_theme_color("font_color")).is_equal(T.RED_TEXT)
	assert_object(stone_words.get_theme_color("font_color")).is_equal(T.GREEN_TEXT)
	(body.find_child("Verb_Build",true,false) as Button).pressed.emit()
	assert_array(built).is_equal([1])

func test_a_frame_holds_other_blocks_and_its_verbs_on_its_title_line()->void:
	var body:=_body()
	var sent:=[]
	Blocks.render(body,[{"type":"frame","heading":"Send a party","actions":[{"label":"Send","on_press":func()->void:sent.append(1)}],
		"blocks":[{"type":"fact_grid","items":[{"label":"Scouts","value":"6"}]}]}])
	var frame:=body.find_child("Frame",true,false)
	assert_object(frame).is_not_null()
	assert_object(frame.find_child("FactGrid",true,false)).is_not_null()
	(frame.find_child("Verb_Send",true,false) as Button).pressed.emit()
	assert_array(sent).is_equal([1])
