extends GdUnitTestSuite
const Presenter=preload("res://scripts/hud/culture_presenter.gd")
const Provider=preload("res://scripts/hud/content/dock_content_civilization.gd")
const Culture=preload("res://scripts/cultural_inheritance.gd")
func test_effects_reflect_memory_and_food_override()->void:
	var memory:=Culture.empty()
	Culture.record(memory,"first","wellbeing",0,10.0)
	var effects:=Presenter.effects(memory,0,{"health":1.25,"demography":1.25,"production":.95},true,1.0)
	assert_str(effects[0].title).contains("Knowledge")
	assert_str(effects[1].title).contains("Health +25.0%")
	assert_str(effects[1].detail).contains("5.0% slower")
	assert_str(effects[2].title).is_equal("2.0% scout target")
	assert_str(Presenter.effects(memory,0,{},true,.8)[2].title).is_equal("Paused for food")
	assert_str(Presenter.effects(memory,0,{},false,1.0)[2].title).is_equal("Player directed")
func test_reputation_requires_conduct_not_cultural_label()->void:
	var cards:=Presenter.reputation({})
	for card:Dictionary in cards:assert_str(card.title).is_equal("None recorded")
	cards=Presenter.reputation({"mercy":.1,"fear":.5,"grievance":.8})
	assert_str(cards[0].title).is_equal("Emerging")
	assert_str(cards[1].title).is_equal("Established")
	assert_str(cards[2].title).is_equal("Strong")
func test_culture_ui_builds_compact_effects_and_collapsed_roots()->void:
	var panel:Control=auto_free(preload("res://scripts/hud/culture_panel.gd").new());add_child(panel)
	var noop:=func():pass
	panel.setup({"identity":{"name":"Test society","summary":"Test"},"direction":{},"values":[],"memories":[{"domain":"justice","current":"Restoration","inherited":"Restoration"}],"effects":Presenter.effects(Culture.empty(),0,{},true,1.0),"reputation":Presenter.reputation({}),"on_direction":noop,"on_council":noop,"on_capacities":noop,"on_government":noop})
	var text:=""
	for label in panel.find_children("*","Label",true,false):text+=label.text+"\n"
	assert_str(text).contains("HOW CULTURE SHAPES PLAY")
	assert_str(text).contains("REPUTATION FROM OUR CONDUCT")
	assert_str(text).not_contains("Now ·")

func test_roots_open_and_closed_state_survive_live_body_rebuild()->void:
	var provider=Provider.new(null,null)
	var noop:=func():pass
	var block:={"view_state":provider.culture_view_state,"identity":{"name":"Test","summary":""},"direction":{},"values":[],"memories":[{"domain":"justice","current":"Restoration","inherited":"Restoration"}],"on_direction":noop,"on_council":noop,"on_capacities":noop,"on_government":noop}
	var panel:Control=auto_free(preload("res://scripts/hud/culture_panel.gd").new());add_child(panel);panel.setup(block)
	assert_bool(panel.get_node("CulturalRoots").visible).is_false()
	panel.get_node("CulturalRootsToggle").pressed.emit()
	assert_bool(provider.culture_view_state.roots_open).is_true()
	var rebuilt:Control=auto_free(preload("res://scripts/hud/culture_panel.gd").new());add_child(rebuilt);rebuilt.setup(block)
	assert_bool(rebuilt.get_node("CulturalRoots").visible).is_true()
	rebuilt.get_node("CulturalRootsToggle").pressed.emit()
	var closed:Control=auto_free(preload("res://scripts/hud/culture_panel.gd").new());add_child(closed);closed.setup(block)
	assert_bool(closed.get_node("CulturalRoots").visible).is_false()
