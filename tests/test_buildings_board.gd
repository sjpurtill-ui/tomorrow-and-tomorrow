extends GdUnitTestSuite
## Buildings keeps commands and exact costs together, with supporting
## categories and bounded choices leading to one readable work.

const Board:=preload("res://scripts/hud/buildings_board.gd")
const Dense:=preload("res://scripts/hud/dense_blocks.gd")

func _block()->Dictionary:
	var cards:Array=[]
	for section in ["a","b","c"]:
		for i in 4:cards.append({"section":section,"key":"%s%d" % [section,i],"icon":"homes","name":"Row %d" % i,"sub":"words","value":"%d%%" % (i*10),"bar":{"ratio":0.1*i,"color":Color.GREEN},"detail":"Meaning."})
	cards.append({"section":"top","key":"build","icon":"palisade","name":"Palisade","tag":{"text":"Waiting","tone":"warn"},"needs":[{"resource":"Timber","have":0.0,"need":360.0}],
		"actions":[{"label":"Build","primary":true,"on_press":func()->void:pass}],"detail":"The next stage."})
	return {"type":"town_works","board":true,"sections":[{"id":"top","heading":"Now","span":true},{"id":"a","heading":"A"},{"id":"b","heading":"B"},{"id":"c","heading":"C"}],"cards":cards}

func _columns(board:Node)->Array:
	var out:Array=[]
	for band in board.get_children():out.append(band.get_child_count())
	return out

func _walk(node:Node,out:Array)->void:
	out.append(node)
	for child in node.get_children():_walk(child,out)

func test_sections_keep_one_selected_reading_and_preserve_choice_on_resize()->void:
	var holder:=VBoxContainer.new();holder.size=Vector2(930,700);add_child(holder)
	var block:=_block();block.view_state={}
	var board:=Board.new();board.setup(block);holder.add_child(board)
	for frame in 4:await get_tree().process_frame
	assert_int(board.category.item_count).is_equal(4)
	assert_str(String(board.view_state.section)).is_equal("top")
	board.category.item_selected.emit(1)
	for frame in 4:await get_tree().process_frame
	assert_str(String(board.view_state.section)).is_equal("a")
	assert_int(board.browser.choices.get_child_count()).is_equal(4)
	board.browser.select("a3")
	assert_str(String(board.browser.state.selected)).is_equal("a3")
	holder.size.x=500
	for frame in 4:await get_tree().process_frame
	assert_str(String(board.browser.state.selected)).is_equal("a3")
	assert_int(board.browser.records.filter(func(record:Dictionary)->bool:return record.content.is_visible_in_tree()).size()).is_equal(1)
	assert_str(String(block.view_state.a.selected)).is_equal("a3")
	holder.queue_free()

func test_rows_carry_their_verb_and_pips_and_no_details_toggle()->void:
	var holder:=VBoxContainer.new();holder.size=Vector2(665,900);add_child(holder)
	var board:=Board.new();board.setup(_block());holder.add_child(board)
	await get_tree().process_frame
	var nodes:Array=[];_walk(board,nodes)
	var build:=nodes.filter(func(n:Node)->bool:return n is Button and (n as Button).text=="Build")
	assert_int(build.size()).is_equal(1)
	assert_int(nodes.filter(func(n:Node)->bool:return n is Dense.Pips).size()).is_equal(1)
	assert_int(nodes.filter(func(n:Node)->bool:return n is Button and (n as Button).text.begins_with("Details")).size()).is_equal(0)
	holder.queue_free()
