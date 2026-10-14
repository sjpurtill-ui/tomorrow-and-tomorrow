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
	# Laid out at 900 wide, every row is one line.
	for i in 3:await get_tree().process_frame
	for row in rows:assert_float((row as Control).size.y).is_less_equal(maxf(Dense.ROW_HEIGHT+2.0,48.0))
	var groups:Array=body.find_children("Group_*","Label",true,false).map(func(n:Node)->String:return (n as Label).text)
	assert_array(groups).is_equal(["UNREAD","READ"])
	assert_object(rows[0].find_child("Tag",true,false)).is_not_null()
	# Tags, bars and verbs share one end column, so every cell stands under its heading.
	var ends:Array=rows.map(func(r:Node)->float:return (r.find_child("Extras",true,false) as Control).custom_minimum_size.x)
	assert_float(float(ends[0])).is_greater(0.0)
	assert_array(ends).is_equal([ends[0],ends[0],ends[0]])
	assert_float((body.find_child("Head",true,false).find_child("Extras",false,false) as Control).custom_minimum_size.x).is_equal(float(ends[0]))
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

func test_columns_stand_side_by_side_and_stack_when_narrow()->void:
	var body:=_body()
	Blocks.render(body,[{"type":"columns","columns":[[{"type":"table","columns":[{"key":"a","label":"A"}],"rows":[{"cells":{"a":"left"}}]}],
		[{"type":"table","columns":[{"key":"a","label":"A"}],"rows":[{"cells":{"a":"right"}}]}]]}])
	for i in 3:await get_tree().process_frame
	var row:=body.find_child("Columns",true,false) as BoxContainer
	assert_object(row).is_not_null()
	assert_int(row.get_child_count()).is_equal(2)
	assert_bool(row.vertical).is_false()
	assert_float((row.get_child(1) as Control).position.x).is_greater(300.0)
	body.size.x=500
	for i in 3:await get_tree().process_frame
	assert_bool(row.vertical).is_true()

## A desktop page stops growing once it has room for its working layout;
## an ultrawide monitor must not pull a label and its value metres apart.
func test_the_page_preserves_narrow_space_and_bounds_wide_reading_distance()->void:
	var Folio:=preload("res://scripts/hud/reference_folio.gd")
	assert_float(Folio.page_width(1000.0)).is_equal_approx(567.0,0.5)
	assert_float(Folio.page_width(1280.0)).is_equal_approx(1280.0-78.0-Folio.NOTICE_ROOM,0.5)
	assert_float(Folio.page_width(1600.0)).is_less_equal(1120.0)
	assert_float(Folio.page_width(2869.0)).is_equal(Folio.page_width(1600.0))

func test_a_wide_fact_keeps_its_value_near_its_label_and_its_keyboard_action()->void:
	var body:=_body()
	var acted:=[]
	var fact:=Dense._fact({"label":"Homes","value":"225","bar":0.76,"on_click":func():acted.append(true)})
	body.add_child(fact)
	for frame in 5:await get_tree().process_frame
	var label:=fact.find_child("Label",true,false) as Label
	var value:=fact.find_child("Value",true,false) as Label
	assert_float(value.global_position.x-label.get_global_rect().end.x).is_less_equal(12.0)
	assert_float(value.global_position.x-label.global_position.x).is_less(180.0)
	var press:=InputEventAction.new();press.action="ui_accept";press.pressed=true
	fact.gui_input.emit(press)
	assert_array(acted).is_equal([true])
