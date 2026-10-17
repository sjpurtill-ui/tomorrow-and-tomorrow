extends GdUnitTestSuite
## The idle map leaves room for the front; inspecting it recovers the exact report.
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Model:=preload("res://scripts/war_front_model.gd")

class Selection extends Node:
	var selected_army_id:=1

class Chart extends "res://scripts/hud/war_front_overlay.gd":
	var drawn_routes:Array=[]
	var drawn_objectives:Array=[]
	func _draw()->void:
		drawn_routes.clear();drawn_objectives.clear()
		super._draw()
	func _draw_arrow(entry:Dictionary,t:float,wide:bool)->void:
		drawn_routes.append(entry.get("data",entry))
		super._draw_arrow(entry,t,wide)
	func _draw_objective(objective:Dictionary)->void:
		drawn_objectives.append(objective)
		super._draw_objective(objective)

var saved_armies:Array=[]

func before_test()->void:
	saved_armies=MilitaryCampaign.field_armies.duplicate(true)

func after_test()->void:
	MilitaryCampaign.field_armies=saved_armies

static func _force(id:int,pos:Vector2,extra:Dictionary={})->Dictionary:
	var force:={"id":str(id),"army_id":id,"pos":pos,"strength":1200.0,"name":"North Host","report_age":0,"doing_context":{"status":"stationed"}}
	force.merge(extra,true)
	return force

static func _inputs()->Dictionary:
	return {"mode":"front","stage":"lettered","home":Vector2(-10,0),"today":100,
		"friendly":[_force(1,Vector2(-3,-2),{"objective":Vector2(8,0)}),_force(2,Vector2(-3,2),{"objective":Vector2(8,0)})],
		"enemy":[{"id":"seen","pos":Vector2(3,-2),"strength":1000.0,"low":900,"high":1100,"owner":"Esurai","age_days":4,"moving":true,"heading":0.0,"seen_day":96,"observed":false}],
		"battles":[{"id":"battle-one","pos":Vector2.ZERO,"kind":"battle","ours":true,"army_id":1,"status":"fighting","age_days":0,"progress":0.1,"sides":{"a":{"troops":1200},"b":{"troops":1000}}}]}

func _chart(inputs:Dictionary)->Chart:
	var chart:Chart=auto_free(Chart.new())
	chart.project=func(p:Vector2)->Vector2:return Vector2(600,400)+p*35.0
	chart.band_override="regional"
	add_child(chart)
	chart.set_process(false)
	chart.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	chart.size=Vector2(1200,800)
	chart.set_scene(Overlay.compose(inputs),true)
	return chart

func test_idle_map_keeps_small_hittable_identity_without_cards_or_routes()->void:
	var chart:=_chart(_inputs())
	await await_idle_frame();await await_idle_frame()
	assert_array(chart.counter_rects).is_empty()
	assert_array(chart.placed_captions).is_empty()
	assert_array(chart.drawn_routes).is_empty()
	assert_array(chart.drawn_objectives).is_empty()
	assert_int(chart.battle_cache.size()).is_equal(1)
	assert_bool((chart.battle_cache[0].rect as Rect2).has_area()).is_true()
	assert_int(chart.liquid_cache.size()).is_equal(1)
	assert_str(String(chart.battle_at(chart.battle_cache[0].at).battle.id)).is_equal("battle-one")
	assert_int(chart.drawn_marks.size()).is_equal(2) # Fighting army is the liquid body.
	for entry:Dictionary in chart.drawn_marks:
		assert_float(float(entry.size)).is_less_equal(18.0)
		var hit:=chart.mark_at(entry.at)
		assert_bool(hit.is_empty()).is_false()
		if String(entry.side)=="ours":assert_int(int(hit.army_id)).is_equal(int(entry.army_id))
		else:
			assert_str(String(hit.enemy_id)).is_equal("seen")
			assert_bool(bool(hit.observed)).is_false()
			assert_int(int(hit.sighting.age_days)).is_equal(4)

func test_inspecting_either_army_reveals_only_its_route_and_shared_objective()->void:
	var chart:=_chart(_inputs())
	for id in [1,2]:
		chart.note_about={"kind":"army","army_id":id}
		chart.queue_redraw()
		await await_idle_frame();await await_idle_frame()
		assert_int(chart.drawn_routes.size()).is_equal(1)
		assert_int(int(chart.drawn_routes[0].army_id)).is_equal(id)
		assert_int(chart.drawn_objectives.size()).is_equal(1)
		assert_bool((chart.drawn_objectives[0].armies as Array).has(id)).is_true()
	chart.close_note()
	await await_idle_frame();await await_idle_frame()
	assert_array(chart.drawn_routes).is_empty()
	assert_array(chart.drawn_objectives).is_empty()

func test_a_force_at_contact_is_inspected_through_its_battle_body()->void:
	var inputs:=_inputs()
	inputs.friendly=[_force(1,Vector2.ZERO)]
	inputs.enemy=[]
	var chart:=_chart(inputs)
	await await_idle_frame();await await_idle_frame()
	var force_at:=chart.mark_screen_position("ours","1")
	assert_bool(force_at.is_finite()).is_false()
	assert_int(int(chart.battle_at(chart.battle_cache[0].at).battle.army_id)).is_equal(1)
	assert_str(String(chart.battle_at(chart.battle_cache[0].at).battle.id)).is_equal("battle-one")
	# The same real contact stays inspectable on the close ground view.
	chart.band_override="ground"
	chart.queue_redraw()
	await await_idle_frame();await await_idle_frame()
	assert_int(chart.battle_cache.size()).is_equal(1)
	assert_str(String(chart.battle_at(chart.battle_cache[0].at).battle.id)).is_equal("battle-one")

func test_a_selected_late_army_keeps_its_route_inside_the_arrow_budget()->void:
	var inputs:=_inputs()
	inputs.friendly=[]
	for id in range(1,Model.MAX_ARROWS+5):
		inputs.friendly.append(_force(id,Vector2(-5,float(id)),{"objective":Vector2(8,float(id)),"selected":id==Model.MAX_ARROWS+4}))
	var built:=Overlay.compose(inputs)
	assert_int((built.arrows as Array).size()).is_less_equal(Model.MAX_ARROWS)
	assert_bool((built.arrows as Array).any(func(route:Dictionary)->bool:return int(route.get("army_id",0))==Model.MAX_ARROWS+4)).is_true()

func test_front_and_dated_enemy_notes_focus_their_own_geometry()->void:
	var chart:=_chart(_inputs())
	chart.note_about={"kind":"front","armies":[2]}
	chart.queue_redraw()
	await await_idle_frame();await await_idle_frame()
	assert_int(chart.drawn_routes.size()).is_equal(1)
	assert_int(int(chart.drawn_routes[0].army_id)).is_equal(2)
	chart.note_about={"kind":"sighting","enemy_id":"seen"}
	chart.queue_redraw()
	await await_idle_frame();await await_idle_frame()
	assert_int(chart.drawn_routes.size()).is_equal(1)
	assert_str(String(chart.drawn_routes[0].enemy_id)).is_equal("seen")
	assert_int(int(chart.drawn_routes[0].seen_day)).is_equal(96)
	assert_array(chart.drawn_objectives).is_empty()

func test_dated_army_disclosure_uses_the_drawn_report_not_live_strength()->void:
	MilitaryCampaign.field_armies=[{"army_id":1,"troops":99000,"name":"North Host","status":"moving"}]
	var inputs:=_inputs()
	inputs.battles=[] # This is an old march report, not a currently observed battle.
	inputs.friendly=[_force(1,Vector2(-3,-2),{"report_age":3,"doing_context":{"status":"stationed","location_name":"North Road"}})]
	inputs.enemy=[]
	var chart:=_chart(inputs)
	await await_idle_frame();await await_idle_frame()
	var at:=chart.mark_screen_position("ours","1")
	var hit:=chart.mark_at(at)
	var content:=chart.note_content(hit)
	var words:=String(content.title)+" "+" ".join(content.lines)
	assert_str(words).contains("1,200").contains("reported three days ago").not_contains("99,000")
	chart._hover(at)
	assert_bool(chart.tip.visible).is_true()
	assert_str((chart.tip.get_child(0) as Label).text).contains("1,200").contains("reported three days ago").not_contains("99,000")

func test_garrison_glyph_exposes_its_own_held_and_away_account()->void:
	var inputs:=_inputs()
	inputs.friendly=[];inputs.enemy=[]
	inputs.garrisons=[{"region_id":"north","pos":Vector2(0,0),"troops":73,"town":"North Road","general":"Mara Venn","away":11,"fate_note":"18 captives on the road"}]
	var chart:=_chart(inputs)
	await await_idle_frame();await await_idle_frame()
	assert_int(chart.drawn_marks.size()).is_equal(1)
	var hit:=chart.mark_at(chart.drawn_marks[0].at)
	assert_str(String(hit.kind)).is_equal("garrison")
	var content:=chart.note_content(hit)
	assert_str(String(content.kicker)).is_equal("GARRISON")
	assert_str(String(content.title)).contains("73")
	assert_str(" ".join(content.lines)).contains("North Road").contains("11 more out of the town").contains("18 captives")
	assert_dict(content.action).is_empty()

func test_inspected_note_takes_precedence_over_an_older_terrain_selection()->void:
	var chart:=_chart(_inputs())
	await await_idle_frame();await await_idle_frame()
	chart.terrain=auto_free(Selection.new())
	chart.note_about={"kind":"front","armies":[2]}
	assert_bool(chart._focused({"army_id":2})).is_true()
	assert_bool(chart._focused({"army_id":1})).is_false()
	chart.note_about={"kind":"sighting","enemy_id":"seen"}
	assert_bool(chart._focused({"enemy_id":"seen"})).is_true()
	assert_bool(chart._focused({"enemy_id":"unseen"})).is_false()
	assert_bool(chart._focused({"army_id":1})).is_false()
	chart.note_about={"kind":"battle","battle":{"army_id":2}}
	assert_bool(chart._focused({"army_id":2})).is_true()
	assert_bool(chart._focused({"army_id":1})).is_false()
	chart.note_about={}
	assert_bool(chart._focused({"army_id":1})).is_true()
	chart.terrain=null
	var at:=chart.mark_screen_position("ours","2")
	chart._hover(at)
	assert_bool(chart.tip.visible).is_true()
	chart.open_note(chart.mark_at(at),at)
	chart._hover(at)
	assert_bool(chart.note.visible).is_true()
	assert_bool(chart.tip.visible).is_false()
