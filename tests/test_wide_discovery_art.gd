extends GdUnitTestSuite
## Wide (about 2.7:1) discovery paintings are shown whole where they are the
## hero and cropped around their focus point only in fixed thumbnail slots.
const Art=preload("res://scripts/hud/research_visuals.gd")
const Painting=preload("res://scripts/hud/subject_painting.gd")
const DiscoveryPopup=preload("res://scripts/hud/discovery_popup.gd")
const Atlas=preload("res://scripts/hud/research_atlas.gd")
const TreePlot=preload("res://scripts/hud/research_tree_plot.gd")
class Host extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value
func before_test()->void:
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
func banner(width:int=270,height:int=100)->Texture2D:
	return ImageTexture.create_from_image(Image.create(width,height,false,Image.FORMAT_RGBA8))
func wide_discovery()->Dictionary:
	# Classical-era subjects painted as banners (about 2.8:1).
	for id:String in ["coin_count_trade","written_wills","majority_vote_assembly"]:
		var item:=DiscoverySystem.discovery_definition(id).duplicate()
		if item.is_empty():continue
		item.exposed=true
		var texture:=Art.for_discovery(item)
		if texture and Art.aspect(texture)>=2.5:return item
	return {}

func test_hero_slot_shows_the_whole_width_of_a_wide_painting()->void:
	var column:VBoxContainer=auto_free(VBoxContainer.new());column.size=Vector2(684,900);add_child(column)
	var hero:=Painting.new();hero.fit_whole_width=true;hero.min_height=150;hero.max_height=300
	hero.texture=banner();column.add_child(hero)
	for i in 4:await get_tree().process_frame
	assert_float(hero.size.x).is_equal_approx(684,.5)
	assert_float(hero.size.y).is_equal_approx(684/2.7,1.0)
	var shown:=Art.visible_fraction(hero.texture.get_size(),hero.size)
	assert_float(shown.x).is_greater_equal(.995)
	assert_float(shown.y).is_greater_equal(.995)

func test_hero_slot_bounds_a_tall_painting_and_crops_around_its_focus()->void:
	var column:VBoxContainer=auto_free(VBoxContainer.new());column.size=Vector2(684,900);add_child(column)
	var hero:=Painting.new();hero.fit_whole_width=true;hero.min_height=150;hero.max_height=300
	hero.focus=Vector2(.5,.72);hero.texture=banner(100,100);column.add_child(hero)
	for i in 4:await get_tree().process_frame
	assert_float(hero.size.y).is_equal_approx(300,.5)
	var region:=Art.crop_region(hero.texture,hero.size,hero.focus)
	assert_bool(region.has_point(hero.texture.get_size()*hero.focus)).is_true()
	# Switching to a wide painting refits the slot so it shows whole.
	hero.texture=banner();for i in 4:await get_tree().process_frame
	assert_float(hero.size.y).is_equal_approx(684/2.7,1.0)

func test_whole_width_height_respects_bounds()->void:
	assert_float(Painting.whole_width_height(banner(),540,110,220)).is_equal_approx(200,.01)
	assert_float(Painting.whole_width_height(banner(),200,110,220)).is_equal_approx(110,.01)
	assert_float(Painting.whole_width_height(banner(100,100),540,110,220)).is_equal_approx(220,.01)
	assert_float(Painting.whole_width_height(null,540,110,220)).is_equal_approx(110,.01)

func test_cropped_slots_keep_the_focus_point_in_frame_and_most_of_a_wide_painting()->void:
	var texture:=banner(2700,1000)
	var slots:={"atlas card":Vector2(Atlas.CARD_WIDTH,Atlas.CARD_IMAGE_HEIGHT),"tree node":TreePlot.IMAGE,"inquiry thumbnail":Vector2(124,124),"exchange thumbnail":Vector2(148,84)}
	for focus:Vector2 in [Vector2(.5,.5),Vector2(.12,.4),Vector2(.9,.7),Vector2(0,1)]:
		for slot:String in slots:
			var target:Vector2=slots[slot]
			var region:=Art.crop_region(texture,target,focus)
			assert_bool(Rect2(Vector2.ZERO,texture.get_size()).grow(.01).encloses(region)).override_failure_message(slot).is_true()
			assert_float(region.size.x/region.size.y).is_equal_approx(target.x/target.y,.001)
			assert_bool(region.grow(.5).has_point(texture.get_size()*focus)).override_failure_message("%s loses focus %s" % [slot,focus]).is_true()
	# List slots are sized so a banner keeps most of its picture.
	assert_float(Art.visible_fraction(texture.get_size(),slots["atlas card"]).x).is_greater_equal(.7)
	assert_float(Art.visible_fraction(texture.get_size(),slots["tree node"]).y).is_greater_equal(.85)

func test_discovery_announcement_shows_a_real_wide_painting_whole()->void:
	var item:=wide_discovery()
	assert_bool(item.is_empty()).override_failure_message("No wide discovery painting in the catalogue").is_false()
	GameState.known_discoveries.append(String(item.id))
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1600,900);add_child(canvas)
	var host:=Host.new();canvas.add_child(host);var hud:=Control.new();host.add_child(hud)
	var popup:=DiscoveryPopup.announce(host,hud,[{"id":String(item.id),"day":400}])
	for i in 8:await get_tree().process_frame
	assert_str(Art.source_path(popup.hero.texture)).is_equal(Art.subject_art_key(item))
	var shown:=Art.visible_fraction(popup.hero.texture.get_size(),popup.hero.size)
	assert_float(shown.x).is_greater_equal(.99)
	assert_float(shown.y).is_greater_equal(.99)
	popup.close()

func test_wide_detection_and_thumbnails_keep_their_source()->void:
	assert_bool(Art.is_wide(banner())).is_true()
	assert_bool(Art.is_wide(banner(150,100))).is_false()
	assert_bool(Art.is_wide(null)).is_false()
	var small:=Art.downscale(banner(2100,780),512)
	assert_int(small.get_width()).is_less_equal(768)
	assert_float(Art.aspect(small)).is_equal_approx(2100/780.0,.02)
	var item:=wide_discovery()
	assert_str(Art.source_path(Art.thumbnail_for(item))).is_equal(Art.subject_art_key(item))
	assert_int(Art.thumbs.size()).is_less_equal(Art.THUMB_LIMIT)
