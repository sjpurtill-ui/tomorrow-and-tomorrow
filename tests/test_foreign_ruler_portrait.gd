extends GdUnitTestSuite
## Portrait subjects use an existing diplomatic record; drawing them never
## initializes or alters the simulation's ruler, identity, or lifetime.
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const ERA:={"outfit":"robe","dress_options":["tunic","robe"],"period":"classical","stage_id":"portrait_identity_test","dye_level":2}
var _days:=0.0

func before_test()->void:
	_days=GameState.elapsed_days
	GameState.elapsed_days=40000.75

func after_test()->void:
	GameState.elapsed_days=_days

func test_ruler_portrait_reads_recorded_sex_age_rank_and_persistent_painting()->void:
	var modal:Control=auto_free(Modal.new())
	var leaders_before:=ForeignDiplomacy.leaders.duplicate(true)
	for woman:bool in [false,true]:
		var leader:={"name":"Portrait Identity Ruler","character":{"woman":woman,"born":40000-63*365,"portrait":2,"gen":4}}
		var before:=leader.duplicate(true)
		var person:Dictionary=modal._foreign_leader_person("civ_05",leader)
		assert_str(person.name).is_equal(leader.name)
		assert_int(person.person_id).is_equal(0)
		assert_str(person.sex).is_equal("female" if woman else "male")
		assert_int(person.age).is_equal(63)
		assert_str(person.office_title).is_equal("ruler")
		assert_int(person.early_art_index).is_equal(2)
		assert_str(person.appearance_civ_id).is_equal("civ_05")
		var look:=Stage.figure_look(person,{},ERA)
		assert_str(look.variant).is_equal("female_old" if woman else "male_old")
		assert_int(look.years).is_equal(63)
		assert_str(look.outfit).is_equal("robe")
		assert_dict(leader).is_equal(before)
	assert_dict(ForeignDiplomacy.leaders).is_equal(leaders_before)

func test_incomplete_legacy_record_stays_uninitialized_and_keeps_its_name()->void:
	var modal:Control=auto_free(Modal.new())
	var leader:={"name":"Existing Saved Ruler","title":"queen"}
	var before:=leader.duplicate(true)
	var leaders_before:=ForeignDiplomacy.leaders.duplicate(true)
	var person:Dictionary=modal._foreign_leader_person("civ_05",leader)
	assert_str(person.name).is_equal("Existing Saved Ruler")
	assert_str(person.office_title).is_equal("queen")
	assert_bool(person.has("sex")).is_false()
	assert_bool(person.has("age")).is_false()
	assert_bool(leader.has("character")).is_false()
	assert_dict(leader).is_equal(before)
	assert_dict(ForeignDiplomacy.leaders).is_equal(leaders_before)

func test_appearance_registry_refreshes_factual_age_and_sex_without_reseeding_identity()->void:
	var modal:Control=auto_free(Modal.new())
	var leader:={"name":"Portrait Registry Ruler","character":{"woman":false,"born":40000-35*365,"portrait":1}}
	var registry:={}
	var first:=Stage.figure_look(modal._foreign_leader_person("civ_05",leader),registry,ERA)
	assert_str(first.variant).is_equal("male_adult")
	leader.character.woman=true;leader.character.born=40000-64*365
	var current:=Stage.figure_look(modal._foreign_leader_person("civ_05",leader),registry,ERA)
	assert_str(current.variant).is_equal("female_old")
	assert_int(current.years).is_equal(64)
	assert_int(current.seed).is_equal(first.seed)
	var repeat:=Stage.figure_look(modal._foreign_leader_person("civ_05",leader),registry,ERA)
	assert_dict(repeat).is_equal(current)

func test_appearance_registry_refreshes_ruler_rank_without_changing_identity()->void:
	var person:={"name":"Portrait Rank Ruler","person_id":0,"appearance_civ_id":"civ_05","age":45,"sex":"female","office_title":"farmer"}
	var registry:={}
	var first:=Stage.figure_look(person,registry,ERA)
	assert_str(first.outfit).is_equal("tunic")
	person.office_title="ruler"
	var ruler:=Stage.figure_look(person,registry,ERA)
	assert_str(ruler.outfit).is_equal("robe")
	assert_int(ruler.seed).is_equal(first.seed)
