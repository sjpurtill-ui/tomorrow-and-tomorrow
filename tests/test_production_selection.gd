extends GdUnitTestSuite
const Queue=preload("res://scripts/hud/production_queue.gd")
const Fixture=preload("res://tests/test_production_screen.gd")
const Selection=preload("res://scripts/hud/production_selection.gd")

func test_last_simultaneous_line_keeps_global_rank_and_existing_actions()->void:
	var actions:Array=[];var lines:Array=[]
	for i in 19:
		var line:=Fixture.healthy_line();line.id=i+1;lines.append(line)
	var block:={"mode":"military","lines":lines,"capacity":20,"context":Fixture.CONTEXT,"on_action":func(id,action,value):actions.append([id,action,value])}
	var queue:Control=auto_free(Queue.new());add_child(queue);queue.size=Vector2(1000,700);queue.setup(block)
	for frame in 4:await get_tree().process_frame
	assert_int(queue._rows.size()).is_equal(19)
	var selected:Control=queue._rows[19]
	assert_bool(selected.is_visible_in_tree()).is_true()
	assert_int(queue._rows.values().filter(func(row:Control)->bool:return row.is_visible_in_tree()).size()).is_equal(19)
	(selected.find_child("Up",true,false) as Button).pressed.emit()
	(selected.find_child("KeepUp",true,false) as Button).pressed.emit()
	assert_array(actions).contains_exactly([[19,"move",-1.0],[19,"target",25.0]])
	lines[18].target_stock=40
	assert_bool(queue.update_block(block)).is_true()
	assert_str((selected.find_child("KeepValue",true,false) as Label).text).is_equal("40")
	assert_object(queue._rows[19]).is_same(selected)

func test_narrow_reading_and_back_keep_search_and_page()->void:
	var index:Control=auto_free(Selection.new());add_child(index);index.size=Vector2(500,700);index.setup({},6)
	for i in 17:index.add_record(str(i),"Product %d" % i,"Available",Label.new())
	index.refresh()
	for frame in 5:await get_tree().process_frame
	assert_bool(index.reader.visible).is_true()
	assert_bool(index.index.visible).is_false()
	index.back.pressed.emit();index.next.pressed.emit()
	assert_int(index.choices.get_child_count()).is_equal(4)
	assert_int(index.state.page).is_equal(1)
	index.select("5");index.back.pressed.emit()
	assert_int(index.state.page).is_equal(1)
	assert_bool(index.index.visible).is_true()
	index.search.text="Product 16";index.search.text_changed.emit(index.search.text);index.select("16")
	assert_str(index.state.selected).is_equal("16")
	index.back.pressed.emit()
	assert_str(index.search.text).is_equal("Product 16")
	index.search.text="Missing";index.search.text_changed.emit(index.search.text)
	assert_str(index.state.selected).is_empty()
	assert_bool(index.reader.visible).is_false()

func test_resize_keeps_the_selected_product_when_page_capacity_changes()->void:
	var index:Control=auto_free(Selection.new());add_child(index);index.size=Vector2(1100,700);index.setup({},6)
	for i in 19:index.add_record(str(i),"Product %d" % i,"Available",Label.new())
	index.refresh()
	for frame in 4:await get_tree().process_frame
	index.next.pressed.emit();index.select("11")
	assert_str(index.state.selected).is_equal("11")
	index.size.x=500
	for frame in 4:await get_tree().process_frame
	assert_str(index.state.selected).is_equal("11")
	assert_int(index.state.page).is_equal(2)
	assert_bool(index.reader.visible).is_true()
	index.size.x=1100
	for frame in 4:await get_tree().process_frame
	assert_str(index.state.selected).is_equal("11")
	assert_int(index.state.page).is_equal(1)
