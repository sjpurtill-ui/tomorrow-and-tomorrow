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
	# The plate stands where it was asked; the footprint takes in the days tab.
	var rect:Rect2=drawn.rect
	assert_vector(rect.position).is_equal_approx(Vector2(200,100)-Counter.BASE*0.5,Vector2(1,1))
	assert_float(rect.size.y).is_equal_approx(Counter.BASE.y,0.5)
	assert_float(rect.size.x).is_greater(Counter.BASE.x)
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

func test_drilling_outside_the_lines_is_listed_and_grouped()->void:
	var Board:=preload("res://scripts/hud/recruit_deploy_board.gd")
	WorldSimulation.clear();GameState.reset_for_new_world(616);MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.training_queue.assign([
		{"id":1,"unit":"levy","weapon":"improvised","count":1,"progress_days":10.0,"required_days":45.0},
		{"id":2,"unit":"levy","weapon":"improvised","count":1,"progress_days":15.0,"required_days":45.0},
		{"id":3,"unit":"spearman","weapon":"spear","count":20,"progress_days":5.0,"required_days":45.0,"deployment_line":4},
		{"id":4,"mode":"field_draft","army_id":9,"unit":"spearman","weapon":"spear","count":3,"progress_days":2.0,"required_days":17.0}])
	var groups:=Board.drilling_groups()
	assert_int(groups.size()).is_equal(2)
	assert_int(int(groups[0].count)).is_equal(2)
	assert_float(float(groups[0].done_min)).is_equal(10.0)
	assert_float(float(groups[0].done_max)).is_equal(15.0)
	assert_str(Board.drilling_words(groups[0])).is_equal("2 Levy")
	assert_str(Board.drilling_words(groups[1])).contains("3 drafts for")
	WorldSimulation.clear()

func test_the_levy_at_home_stands_on_the_map_with_those_in_drill()->void:
	var levy:={"pos":Vector2(10,20),"troops":9,"drilling":4,"full":9,"morale":0.8,"glyph":"club","general":"Corvan of the Birch","town":"Sean Springs","era":0,"branch":"foot"}
	var marks:=Overlay._marks({"stage":"reckoned","home_levy":levy,"garrisons":[]},[],[],{})
	assert_int(marks.size()).is_equal(1)
	var home:Dictionary=marks[0]
	assert_bool(bool(home.home_levy)).is_true()
	assert_int(int(home.troops)).is_equal(9)
	var data:=Overlay.counter_data(home,Color.BLUE)
	assert_str(String(data.tab)).is_equal("+4 in drill")
	assert_str(String(data.glyph)).is_equal("club")
	# Nobody at home and nobody drilling: no mark.
	assert_array(Overlay._marks({"stage":"reckoned","home_levy":{},"garrisons":[]},[],[],{})).is_empty()

func test_alerts_say_what_is_wrong_with_our_fighters()->void:
	var Alerts:=preload("res://scripts/hud/army_alerts.gd")
	WorldSimulation.clear();GameState.reset_for_new_world(717);MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.settlement_site_committed=true
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	assert_array(Alerts.alerts()).is_empty()
	var sim=MilitaryCampaign.simulator
	var home:Vector2=CivilizationSystem.player_world_origin
	var force:Dictionary=sim.create_formation_force("Ennis band",[{"id":1,"unit":"spearman","weapon":"spear","count":4,"authorized_count":13,"equipment":3,"equipment_required":4,"training":0.6}],0.1,0.8)
	force.merge({"army_id":1,"name":"Ennis band","status":"stationed","position":{"x":home.x,"z":home.y},"supply_level":0.3,"provision_ratio":0.3,"hungry_days":5.0,"commander":{"name":"Ennis"},"morale":0.1},true)
	MilitaryCampaign.field_armies.assign([force])
	var shown:=Alerts.alerts()
	var ids:=shown.map(func(a:Dictionary)->String: return String(a.id))
	assert_array(ids).contains(["hungry","will","men"])
	var hungry:Dictionary=shown[ids.find("hungry")]
	assert_str(String(hungry.tone)).is_equal("red")
	assert_str(Alerts.tip(hungry)).contains("Ennis").contains("Readiness & supply")
	assert_str(String(shown[ids.find("men")].page)).is_equal("recruitment")
	WorldSimulation.clear()

func test_the_queue_counts_those_drilling_outside_the_lines()->void:
	var Board:=preload("res://scripts/hud/recruit_deploy_board.gd")
	assert_str(Board.queue_words(4,0,1)).is_equal("4 drilling · 1 sent")
	assert_str(Board.queue_words(0,2,0)).is_equal("2 bands training")
	assert_str(Board.queue_words(0,0,0)).is_equal("")

func test_a_general_shows_skills_as_pips()->void:
	var Strips:=preload("res://scripts/hud/force_strips.gd")
	assert_int(Strips.GeneralPips.pips(0.5)).is_equal(3)
	assert_int(Strips.GeneralPips.pips(0.0)).is_equal(1)
	assert_int(Strips.GeneralPips.pips(1.0)).is_equal(5)
	var pips:=Strips.GeneralPips.new()
	add_child(pips)
	pips.set_commander({"command":0.62,"tactics":0.41,"resolve":0.8,"logistics":0.3},"Ennis of the Ford",false)
	assert_bool(pips.values.has("logistics")).is_false()
	assert_str(pips.tooltip_text).contains("Ennis of the Ford").contains("Command 3 of 5").contains("Resolve 4 of 5")
	pips.set_commander({"command":0.62,"tactics":0.41,"resolve":0.8,"logistics":0.3},"Corvan",true)
	assert_bool(pips.values.has("logistics")).is_true()
	pips.set_commander({},"",false)
	assert_bool(pips.visible).is_false()
	pips.queue_free()

func test_a_card_under_the_pointer_rings_its_counter()->void:
	var overlay:=Overlay.new()
	var holder:=Node.new()
	overlay.terrain=holder
	add_child(holder)
	assert_bool(overlay._pointed({"id":"ours:3","members":["ours:3","ours:5"]})).is_false()
	holder.set_meta("pointed_marks",["ours:5"])
	assert_bool(overlay._pointed({"id":"ours:3","members":["ours:3","ours:5"]})).is_true()
	assert_bool(overlay._pointed({"id":"ours:4","members":["ours:4"]})).is_false()
	holder.set_meta("pointed_marks",["home"])
	assert_bool(overlay._pointed({"id":"home","members":["home"]})).is_true()
	overlay.free()
	holder.queue_free()

func test_drafts_drilling_for_a_band_show_on_its_counter()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(818);MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.training_queue.assign([
		{"id":1,"mode":"field_draft","army_id":4,"unit":"spearman","weapon":"spear","count":3,"progress_days":1.0,"required_days":17.0},
		{"id":2,"mode":"field_draft","army_id":9,"unit":"spearman","weapon":"spear","count":2,"progress_days":1.0,"required_days":17.0},
		{"id":3,"unit":"levy","weapon":"improvised","count":5,"progress_days":1.0,"required_days":45.0}])
	assert_int(Overlay.drafts_for(4)).is_equal(3)
	assert_int(Overlay.drafts_for(5)).is_equal(0)
	var data:=Overlay.counter_data({"side":"ours","army_id":4,"troops":4,"full":13,"will":0.2,"drafts":3},Color.BLUE)
	assert_str(String(data.tab)).is_equal("+3 coming")
	WorldSimulation.clear()

func test_men_gained_or_lost_flash_over_the_counter()->void:
	var overlay:=Overlay.new()
	var before:={"marks":[{"id":"home","side":"ours","troops":9},{"id":"ours:4","side":"ours","troops":5},{"id":"theirs:x","side":"theirs","troops":40}]}
	var after:={"marks":[{"id":"home","side":"ours","troops":13},{"id":"ours:4","side":"ours","troops":4},{"id":"ours:7","side":"ours","troops":20},{"id":"theirs:x","side":"theirs","troops":30}]}
	overlay._note_troop_changes(before,after)
	var by:={}
	for pulse in overlay.troop_pulses: by[String(pulse.id)]=int(pulse.delta)
	# The levy grew by 4; the band lost one; a new band and their host are not news here.
	assert_dict(by).is_equal({"home":4,"ours:4":-1})
	overlay.free()
