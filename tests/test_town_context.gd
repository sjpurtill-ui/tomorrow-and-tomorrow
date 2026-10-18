extends GdUnitTestSuite
const Context=preload("res://scripts/hud/town_context.gd")
func test_work_refresh_retains_the_action()->void:
	var context:Control=auto_free(Context.new());add_child(context)
	var calls:Array=[]
	var block:={"builders":8,"civic_builders":2.4,"work":[{"name":"Storehouse","sub":"Short 4 timber","progress":{"ratio":.3}}],"on_assign":func():calls.append("builders")}
	context.setup(block)
	var button:Button=context.assign
	block.work[0].progress.ratio=.5;context.update_block(block)
	assert_object(context.assign).is_same(button)
	assert_float(context.lanes[0].bar.value).is_equal(.5)
	assert_str(context.lanes[0].note.text).is_equal("Short 4 timber")
	button.pressed.emit();assert_array(calls).contains_exactly(["builders"])
func test_empty_context_does_not_invent_capacity_or_queued_work()->void:
	var context:Control=auto_free(Context.new());add_child(context);context.setup({})
	assert_int(context.cells.size()).is_equal(0)
	assert_bool(context.lanes[0].bar.visible).is_false()
	assert_bool(context.lanes[1].box.visible).is_false()
	assert_str(context.lanes[0].heading.text).contains("No known civic work")

func test_capacity_view_keeps_fixed_categories_at_large_population_and_unknown_water()->void:
	var context:Control=auto_free(Context.new());add_child(context)
	var rows:Array=[{"id":"housing","name":"Housing","used":20000000,"capacity":19000000,"unit":"people / places","over":"without shelter","under":"spare places"},{"id":"drinking","name":"Water today","used":null,"capacity":null,"unit":"needed / supplied","over":"unmet","under":"surplus"}]
	for kind:String in preload("res://scripts/storage_works.gd").KINDS:
		rows.append({"id":kind,"name":kind,"used":1000000,"capacity":900000,"unit":"held / room","over":"over capacity","under":"free room"})
	context.setup({"city_id":"large_city","capacity":rows})
	assert_int(context.cells.size()).is_equal(9)
	assert_str(context.cells.housing.gap.text).contains("without shelter")
	assert_bool(context.cells.drinking.bar.visible).is_false()
	var original:Control=context.cells.housing.box
	rows[0].capacity=21000000;context.update_block({"city_id":"large_city","capacity":rows})
	assert_object(context.cells.housing.box).is_same(original)
	assert_str(context.cells.housing.gap.text).contains("spare places")
	assert_int(context.cells.size()).is_equal(9)
