extends GdUnitTestSuite
## The Buildings page's board (hud/buildings_board.gd): one-line rows in
## sections that flow into two columns at 1600 and 2000 px (665 and 850 UI units), three on wider pages, a
## Build verb on the row, bills as pips, no "Details +" anywhere.

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

func test_sections_flow_into_two_or_three_columns_by_width()->void:
	for pair in [[665.0,[1,2]],[850.0,[1,2]],[1000.0,[1,3]],[500.0,[1,1]]]:
		var holder:=VBoxContainer.new();holder.size=Vector2(float(pair[0]),900);add_child(holder)
		var board:=Board.new();board.setup(_block());holder.add_child(board)
		await get_tree().process_frame
		await get_tree().process_frame
		assert_array(_columns(board)).override_failure_message("width %d: %s" % [int(pair[0]),str(_columns(board))]).is_equal(pair[1])
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
