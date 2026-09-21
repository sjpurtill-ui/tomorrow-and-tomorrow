extends GdUnitTestSuite
const DiscoveryPopup=preload("res://scripts/hud/discovery_popup.gd")
const Pause=preload("res://scripts/hud/simulation_pause.gd")
class Host extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value
func before_test()->void:
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.known_discoveries.append_array(["food_drying","drainage","cordage"])
func fixture(width:int=1200,height:int=900)->Dictionary:
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(width,height);add_child(canvas)
	var host:=Host.new();canvas.add_child(host)
	var hud:=Control.new();host.add_child(hud)
	return {"canvas":canvas,"host":host,"hud":hud}
func test_new_discoveries_queue_once_and_pause_until_last_dismissal()->void:
	var f:=fixture();var popup:=DiscoveryPopup.announce(f.host,f.hud,[{"id":"food_drying","day":12},{"id":"drainage","day":12}])
	assert_float(f.host.game_speed).is_equal(0.0)
	assert_str(popup.current.id).is_equal("food_drying")
	assert_int(popup.pending.size()).is_equal(1)
	DiscoveryPopup.announce(f.host,f.hud,[{"id":"food_drying","day":12},{"id":"cordage","day":12}])
	assert_int(popup.pending.size()).is_equal(2)
	popup.advance();assert_str(popup.current.id).is_equal("drainage")
	assert_float(f.host.game_speed).is_equal(0.0)
	popup.close();assert_float(f.host.game_speed).is_equal(3.0)
	assert_bool(Pause.blocks(f.host)).is_false()
func test_popup_uses_actual_signed_effects_and_labels_tradeoffs()->void:
	var f:=fixture();var popup:=DiscoveryPopup.announce(f.host,f.hud,[{"id":"food_drying","day":12,"name":"Obsolete name","effects":{"made_up_effect":1}}])
	assert_str(popup.heading.text).is_equal("Food Drying")
	assert_str(popup.effect_cards.food_storage.value.text).is_equal("+10%")
	assert_str(popup.effect_cards.food_spoilage.value.text).is_equal("−10%")
	assert_bool(popup.effect_cards.food_spoilage.beneficial).is_true()
	assert_bool(popup.effect_cards.labor_demand.beneficial).is_false()
	assert_bool(popup.effect_cards.has("made_up_effect")).is_false()
	assert_str(DiscoveryPopup.percent(.0001)).is_equal("+<0.1%")
	popup.close()
func test_unknown_discovery_is_not_announced_and_reading_does_not_grant_effects()->void:
	var f:=fixture();var known:=GameState.known_discoveries.duplicate();var adoption:=GameState.discovery_adoption.duplicate(true)
	var popup:=DiscoveryPopup.announce(f.host,f.hud,[{"id":"unearned_future_discovery","day":12}])
	assert_bool(popup.closing).is_true();assert_float(f.host.game_speed).is_equal(3.0)
	assert_array(GameState.known_discoveries).is_equal(known);assert_dict(GameState.discovery_adoption).is_equal(adoption)
func test_escape_dismisses_entire_batch_and_preserves_already_paused_speed()->void:
	var f:=fixture();f.host.game_speed=0.0
	var popup:=DiscoveryPopup.announce(f.host,f.hud,[{"id":"food_drying","day":12},{"id":"drainage","day":12}])
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_ESCAPE;popup._input(key)
	assert_bool(popup.closing).is_true();assert_float(f.host.game_speed).is_equal(0.0)
func test_small_window_keeps_dismissal_buttons_onscreen_and_body_scrollable()->void:
	var f:=fixture(800,600);var popup:=DiscoveryPopup.announce(f.host,f.hud,[{"id":"drainage","day":12},{"id":"food_drying","day":12}])
	for i in 8:await get_tree().process_frame
	assert_bool(Rect2(0,0,800,600).encloses(popup.panel.get_global_rect())).is_true()
	assert_bool(Rect2(0,0,800,600).encloses(popup.next_button.get_global_rect())).is_true()
	assert_bool(Rect2(0,0,800,600).encloses(popup.dismiss_button.get_global_rect())).is_true()
	assert_float(popup.body.get_combined_minimum_size().x).is_less_equal(popup.scroll.size.x)
	popup.close()
func test_nested_modal_pause_is_not_released_by_discovery_dismissal()->void:
	var f:=fixture();var existing=Pause.new();existing.acquire(f.host)
	var popup:=DiscoveryPopup.announce(f.host,f.hud,[{"id":"food_drying","day":12}]);popup.close()
	assert_float(f.host.game_speed).is_equal(0.0);existing.release();assert_float(f.host.game_speed).is_equal(3.0)
func test_stone_selection_has_its_own_art_and_original_effects()->void:
	var f:=fixture();GameState.known_discoveries.append("stone_sorting")
	var popup:=DiscoveryPopup.announce(f.host,f.hud,[{"id":"stone_sorting","day":1129}])
	assert_str(popup.heading.text).is_equal("Stone Selection")
	assert_str(popup.hero.texture.resource_path).is_equal("res://assets/ui/research/stone-selection-v1.png")
	assert_object(popup.hero.get_node_or_null("FieldIllustrationCaption")).is_null()
	assert_str(popup.effect_cards.survey_speed.value.text).is_equal("+3%")
	assert_str(popup.effect_cards.tool_quality.value.text).is_equal("+4%")
	popup.close()
func test_subject_art_is_specific_and_hidden_questions_do_not_reveal_it()->void:
	var Art=preload("res://scripts/hud/research_visuals.gd")
	var f:=fixture();var popup:=DiscoveryPopup.announce(f.host,f.hud,[{"id":"food_drying","day":12}])
	assert_str(popup.hero.texture.resource_path).ends_with("food_drying-v1.png")
	assert_object(popup.hero.get_node_or_null("FieldIllustrationCaption")).is_null()
	var hidden:={"id":"stone_sorting","domain":"production","exposed":false}
	assert_str(Art.subject_art_key(hidden)).is_empty()
	assert_object(Art.for_discovery(hidden)).is_null()
	assert_str(Art.for_discovery({"id":"clay_shaping","domain":"production","exposed":true}).resource_path).ends_with("clay_shaping-v1.png")
	popup.close()
func test_full_illustration_and_footer_fit_after_resizing_to_phone_width()->void:
	var f:=fixture();var popup:=DiscoveryPopup.announce(f.host,f.hud,[{"id":"food_drying","day":12},{"id":"drainage","day":12}])
	for width:int in [1200,340,800]:
		f.canvas.size=Vector2i(width,640)
		for i in 10:await get_tree().process_frame
		assert_bool(Rect2(0,0,width,640).grow(.1).encloses(popup.panel.get_global_rect())).is_true()
		assert_bool(popup.panel.get_global_rect().encloses(popup.next_button.get_global_rect())).is_true()
		assert_bool(popup.panel.get_global_rect().encloses(popup.dismiss_button.get_global_rect())).is_true()
		assert_float(popup.body.get_combined_minimum_size().x).is_less_equal(popup.scroll.size.x+.1)
		assert_int(popup.hero.stretch_mode).is_equal(TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		assert_bool(popup.introduction.vertical).is_equal(width<628)
	popup.close()
