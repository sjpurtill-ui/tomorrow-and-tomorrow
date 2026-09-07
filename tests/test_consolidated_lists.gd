extends GdUnitTestSuite
const Ledger=preload("res://scripts/hud/content/dock_detail_population_ledger.gd")
const Picker=preload("res://scripts/hud/scout_target_picker.gd")
func test_death_summary_conserves_counts_and_pages_all_records()->void:
	var records:Array=[]
	for day in 400:records.append({"kind":"death","day":day*31,"cause":"Natural causes" if day%2==0 else "Hunger","count":2,"location":"Home"})
	var before:=records.duplicate(true)
	var rows:=Ledger.death_summary(records)
	assert_int(rows.size()).is_equal(2)
	assert_int(int(rows[0].count)+int(rows[1].count)).is_equal(800)
	var provider:=Ledger.new(null,null)
	var dated:=Ledger.grouped_deaths(records)
	var seen:=0
	for page in 50:
		provider.death_page=page
		var blocks:Array=provider._death_pages(dated,false)
		assert_int(blocks[0].items.size()).is_less_equal(8)
		seen+=blocks[0].items.size()
	assert_int(seen).is_equal(400)
	assert_array(records).is_equal(before)
func test_lead_picker_groups_accounts_without_changing_targets()->void:
	var options:Array=[{"id":"open_world","kind":"open_world","label":"Open exploration","description":"Explore"}]
	for i in 32:options.append({"id":"lead:%d"%i,"kind":"investigate_lead","civ_id":"people_a" if i<16 else "people_b","label":"INVESTIGATE LEAD · People A" if i<16 else "INVESTIGATE LEAD · People B","description":"Report %d at a distinct location"%i})
	var before:=options.duplicate(true)
	var groups:=Picker.grouped(options)
	assert_int(groups.investigate_lead.size()).is_equal(2)
	var picker:=Picker.new();add_child(picker);picker.setup(options,"lead:20")
	assert_int(picker.subject.item_count).is_equal(2)
	assert_int(picker.selector.item_count).is_equal(16)
	assert_str(String(picker.selector.get_item_metadata(picker.selector.selected))).is_equal("lead:20")
	picker.subject.select(0);picker.subject.item_selected.emit(0)
	assert_str(String(picker.selector.get_item_metadata(picker.selector.selected))).is_equal("lead:0")
	picker.category.select(0);picker.category.item_selected.emit(0)
	assert_str(String(picker.selector.get_item_metadata(picker.selector.selected))).is_equal("open_world")
	assert_array(options).is_equal(before)
	picker.free()
