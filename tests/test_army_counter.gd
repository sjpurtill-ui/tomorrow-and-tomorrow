extends GdUnitTestSuite
## THE ARMY COUNTER (scripts/hud/army_counter.gd, war_front_overlay
## counter_data): every force on the close and regional charts is a HOI4
## plate with the kit most of its men carry, its men in bold, strength and
## will bars, a supply dot (a sprig when it lives off the land), its march
## progress and days to go; a stranger's host shows the watchers' estimate.

const Counter:=preload("res://scripts/hud/army_counter.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")

func test_the_kit_most_men_carry_is_the_glyph()->void:
	var formations:=[{"unit":"levy","weapon":"improvised","count":4},{"unit":"spearman","weapon":"spear","count":20},{"unit":"archer","weapon":"bow","count":6}]
	assert_str(Counter.main_glyph(formations)).is_equal("spear")
	assert_str(Counter.main_glyph([])).is_equal("spear")
	assert_str(Counter.main_glyph([{"unit":"light_tank","weapon":"light_tank_kit","count":300}])).is_equal("light_tank")
	# A force known only by its arm and age wears what such a force carried.
	assert_str(Counter.glyph_for("foot",0)).is_equal("spear")
	assert_str(Counter.glyph_for("foot",1)).is_equal("musket")
	assert_str(Counter.glyph_for("guns",2)).is_equal("field_gun")

func test_the_plate_says_ours_exactly_and_theirs_as_seen()->void:
	assert_str(Counter.men_words({"side":"ours","troops":1240})).is_equal("1,240")
	assert_str(Counter.men_words({"side":"theirs","low":100,"high":140})).is_equal("~120")
	assert_str(Counter.men_words({"side":"theirs","low":0,"high":0})).is_equal("?")
	assert_bool(Counter.supply_color("starving")==Counter.OXBLOOD).is_true()
	assert_bool(Counter.supply_color("well")==Counter.OLIVE).is_true()

func test_a_mark_becomes_its_counter()->void:
	var mark:={"side":"ours","army_id":3,"troops":18,"full":20,"will":0.7,"state":"marching","glyph":"spear","supply":"strained","foraging":true,
		"march_done":0.4,"days_left":6,"members":["ours:3"]}
	var data:=Overlay.counter_data(mark,Color.BLUE)
	assert_int(int(data.troops)).is_equal(18)
	assert_float(float(data.strength)).is_equal_approx(0.9,0.0001)
	assert_float(float(data.will)).is_equal_approx(0.7,0.0001)
	assert_bool(bool(data.foraging)).is_true()
	assert_str(String(data.supply)).is_equal("strained")
	assert_float(float(data.march_done)).is_equal_approx(0.4,0.0001)
	assert_int(int(data.days_left)).is_equal(6)
	assert_str(String(data.glyph)).is_equal("spear")
	# A stack of three bands: their men summed, no single march shown.
	var stack:={"side":"ours","army_id":1,"troops":4,"members_troops":14,"full":4,"members_full":14,"will":0.8,"members":["a","b","c"],"march_done":0.5,"days_left":3}
	var many:=Overlay.counter_data(stack,Color.BLUE)
	assert_int(int(many.troops)).is_equal(14)
	assert_int(int(many.members)).is_equal(3)
	assert_bool(many.has("march_done")).is_false()
	# Theirs: the watchers' range, their arm's glyph, no supply of theirs.
	var theirs:={"side":"theirs","low":90,"high":150,"branch":"foot","era":0,"age_days":0}
	var seen:=Overlay.counter_data(theirs,Color.RED)
	assert_str(Counter.men_words(seen)).is_equal("~120")
	assert_str(String(seen.glyph)).is_equal("spear")
	assert_bool(seen.has("supply")).is_false()

func test_the_counter_draws_on_a_canvas()->void:
	var canvas:=Control.new()
	canvas.size=Vector2(400,200)
	add_child(canvas)
	var drawn:={"rect":Rect2()}
	canvas.draw.connect(func()->void:
		drawn.rect=Counter.draw(canvas,Vector2(200,100),{"side":"ours","glyph":"spear","troops":20,"strength":0.8,"will":0.6,"supply":"well","state":"marching","march_done":0.3,"days_left":4,"selected":true,"members":2},1.0,1.0))
	canvas.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	var rect:Rect2=drawn.rect
	assert_vector(rect.size).is_equal(Counter.BASE)
	assert_vector(rect.get_center()).is_equal_approx(Vector2(200,100),Vector2(1,1))
	canvas.queue_free()

func test_those_in_drill_lead_the_army_bar()->void:
	var Model:=preload("res://scripts/hud/army_bar_model.gd")
	var Bar:=preload("res://scripts/hud/army_bar.gd")
	WorldSimulation.clear();GameState.reset_for_new_world(515);MilitaryCampaign.reset_for_new_world()
	GameState.settlement_site_committed=true
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	assert_dict(Model.drill_card(MilitaryCampaign)).is_empty()
	MilitaryCampaign.training_queue.assign([
		{"id":1,"unit":"spearman","weapon":"spear","count":20,"progress_days":10.0,"required_days":30.0},
		{"id":2,"mode":"field_draft","army_id":4,"unit":"spearman","weapon":"spear","count":3,"progress_days":1.0,"required_days":17.0}])
	MilitaryCampaign.aggregate_recruits=6
	var card:=Model.drill_card(MilitaryCampaign)
	assert_int(int(card.men)).is_equal(20)
	assert_int(int(card.drafts)).is_equal(3)
	assert_int(int(card.waiting)).is_equal(6)
	assert_float(float(card.progress)).is_equal_approx(1.0/3.0,0.001)
	assert_str(String(card.glyph)).is_equal("spear")
	# The same days the court says.
	assert_int(int(card.days)).is_equal(int(preload("res://scripts/court_war_orders.gd").forces().drill_days))
	assert_str(Model.drill_words(card)).contains("20 in drill at home, 33% through it").contains("6 called up").contains("3 drafts")
	# It leads the bar, and the bar shows while anyone drills.
	var shown:=Bar.bar_cards(MilitaryCampaign)
	assert_bool(shown.is_empty()).is_false()
	assert_str(String(shown[0].kind)).is_equal("drill")
	# The Forces list keeps to the forces.
	assert_bool(Model.cards(MilitaryCampaign).any(func(c:Dictionary)->bool: return String(c.kind)=="drill")).is_false()
	WorldSimulation.clear()

func test_a_force_shows_who_carries_what_and_the_odds_as_a_bar()->void:
	var Strips:=preload("res://scripts/hud/force_strips.gd")
	var blocks:=Strips.composition([{"unit":"archer","weapon":"bow","count":6},{"unit":"spearman","weapon":"spear","count":12},{"unit":"spearman","weapon":"spear","count":3},{"unit":"levy","weapon":"improvised","count":2}])
	assert_int(blocks.size()).is_equal(3)
	assert_str(String(blocks[0].glyph)).is_equal("spear")
	assert_int(int(blocks[0].count)).is_equal(15)
	assert_str(Strips.composition_words(blocks)).is_equal("Spears 15, Bows 6, Improvised Arms 2")
	var bar:=Strips.OddsBar.new()
	add_child(bar)
	bar.set_odds({"raw":3.0,"odds":3.0,"ours":true},"about 3 to 1 for us")
	assert_bool(bar.visible).is_true()
	assert_float(bar.raw).is_equal(3.0)
	bar.set_odds({},"")
	assert_bool(bar.visible).is_false()
	bar.queue_free()
