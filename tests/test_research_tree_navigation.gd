extends GdUnitTestSuite

const Atlas:=preload("res://scripts/hud/research_atlas.gd")

func record(id:String,parents:Array[String]=[],active:=false,ready:=false,choices:Array=[])->Dictionary:
	return {"id":id,"name":id.capitalize(),"domain":"knowledge","known":not ready,"ready":ready,"exposed":true,"requires":parents,"requires_any":choices,"pathways":[],"assignment":{"active":active}}

func test_frontier_scope_keeps_active_foundations_and_bounded_next_branches()->void:
	var atlas=auto_free(Atlas.new())
	var source:Array[Dictionary]=[
		record("foundation"),record("alternative"),record("active_question",["foundation"],true,false,[["alternative"]]),
		record("branch_1",["active_question"],false,true),record("branch_2",["active_question"],false,true),record("branch_3",["active_question"],false,true),record("branch_4",["active_question"],false,true),record("branch_5",["active_question"],false,true),record("unrelated",[],false,true),
	]
	var scoped:Array[Dictionary]=atlas._frontier_records(source)
	var ids:Array=[]
	for item:Dictionary in scoped:ids.append(item.id)
	assert_array(ids).contains(["foundation","alternative","active_question"])
	assert_int(ids.filter(func(id:String)->bool:return id.begins_with("branch_")).size()).is_equal(4)
	assert_bool(ids.has("unrelated")).is_false()

func test_selected_detail_names_required_choice_and_alternate_outcomes()->void:
	var atlas=auto_free(Atlas.new())
	var records:Array[Dictionary]=[
		record("source"),record("required_result",["source"]),record("choice_result",[],false,true,[["source","other"]]),
		{"id":"route_result","name":"Route Result","domain":"knowledge","known":false,"ready":true,"exposed":true,"requires":[],"requires_any":[],"pathways":[{"requires_all":["source"],"requires_any":[]}],"assignment":{}},
	]
	atlas.all_records=records
	var possibilities:Array[Dictionary]=atlas._branching_possibilities(atlas.all_records[0])
	assert_int(possibilities.size()).is_equal(3)
	assert_array(possibilities.map(func(item:Dictionary)->String:return String(item.relation))).contains(["required foundation","one possible foundation","supports another approach"])
