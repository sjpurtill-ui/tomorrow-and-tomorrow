extends GdUnitTestSuite
const Words:=preload("res://scripts/hud/great_work_dedication_words.gd")
const Design:=preload("res://scripts/hud/great_work_design.gd")
const Concept:=preload("res://scripts/wonder_concept.gd")
const Voice:=preload("res://scripts/audience_voice.gd")

func test_every_architecture_has_its_own_speech_subject()->void:
	var unique:Dictionary={}
	for key:String in Design.catalog_ids():
		assert_bool(Words.FOCUS.has(key)).is_true()
		unique[Words.FOCUS[key]]=true
	assert_int(unique.size()).is_equal(30)

func test_purposes_remain_intentions_and_defiance_stays_defiant()->void:
	for purpose:String in Concept.PURPOSES:
		var ctx:={"key":Concept.make_id("archive",purpose,"grand","timber",1,"words")}
		var before:=var_to_str(ctx)
		var subjects:=Words.subjects(ctx)
		assert_str(subjects.purpose_vow).starts_with("to ")
		assert_str(var_to_str(ctx)).is_equal(before)
	assert_str(Words.VOWS.defy_gods).contains("defiance")
	assert_str(Words.subjects({"key":"great_hall"}).work_detail).not_contains("stone")

func test_offline_builder_uses_identity_without_inventing_a_specific_defect()->void:
	var ctx:={"key":"great_hall","title":"Hall of Many Hearths","city_name":"Ashfire","outcome":"flawed",
		"architect":{"id":"words_builder","name":"Aru","alive":true},"attendees":[]}
	var voice:=Voice.new()
	auto_free(voice)
	var lines:Array=voice.ceremony_offline(ctx)
	assert_int(lines.size()).is_greater_equal(2)
	var builder:=""
	for line:Dictionary in lines:
		if String(line.role)=="architect":builder=String(line.text)
	assert_str(builder).contains(String(Words.FOCUS["legacy:great_hall"]))
	assert_str(builder).not_contains("east wall")
	assert_str(builder).not_contains("stone")
	assert_str(builder).not_contains("{work_detail}")
