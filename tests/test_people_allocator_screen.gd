extends GdUnitTestSuite
const View = preload("res://scripts/hud/people_allocator_screen.gd")
const Manual = preload("res://scripts/manual_work.gd")
var screen: Control
var counts: Dictionary
var shares: Dictionary
var revision := 1
var captures := 0
var evaluations := 0
var commits := 0
var manual := false
var protected_food := false
var available := true
var reject := false

func before_test() -> void:
	revision = 1; captures = 0; evaluations = 0; commits = 0
	manual = false; protected_food = false; available = true; reject = false
	counts = {}
	for role: String in Manual.ROLES: counts[role] = 10
	counts.Food = 20
	shares = counts.duplicate()
	screen = View.new(); add_child(screen); screen.size = Vector2(1200, 850)
	screen.setup(_block())

func after_test() -> void: screen.free()

func _capture() -> Dictionary:
	captures += 1
	return {"ok":true, "token":revision, "counts":counts.duplicate(), "shares":shares.duplicate(), "commands":[]}

func _step(draft: Dictionary, role: String, points: int) -> Dictionary:
	var out := draft.duplicate(true)
	var amount := clampi(points, -int(out.shares[role]), int(out.shares.Food))
	out.shares[role] += amount; out.shares.Food -= amount
	out.counts = out.shares.duplicate()
	out.commands.append({"role":role, "points":amount}); out.has_changes = amount != 0
	return out

func _evaluate(draft: Dictionary) -> Dictionary:
	evaluations += 1
	if not available: return {"ok":false, "reason":"Forecast unavailable today."}
	var actual: Dictionary = draft.counts.duplicate()
	if protected_food and not draft.commands.is_empty(): actual.Crafting -= 2; actual.Food += 2
	var food := {"production":100.0, "required":95.0, "net":4.0, "stock":900.0, "forecast90":{"ending_rations":1000.0}}
	return {"ok":true, "before":{"counts":counts.duplicate(), "food":food, "work_impacts":{"making_capacity":10.0}},
		"after":{"counts":actual, "food":food, "work_impacts":{"making_capacity":actual.Crafting}}, "warnings":[]}

func _commit(draft: Dictionary, takeover: bool) -> Dictionary:
	if reject or draft.token != revision: return {"ok":false, "reason":"World changed; try again."}
	assert_bool(takeover).is_true()
	commits += 1; manual = true; revision += 1
	shares = draft.shares.duplicate(); counts = draft.counts.duplicate()
	if protected_food: counts.Crafting -= 2; counts.Food += 2
	return {"ok":true, "counts":counts.duplicate(), "revision":[revision]}

func _block() -> Dictionary:
	var tasks: Array = []
	for role: String in Manual.ROLES: tasks.append({"id":role, "count":counts[role], "share":shares[role]})
	return {"type":"civilization_people", "settlement_view":{"population":193}, "workforce_revision":[revision],
		"labor":{"tasks":tasks, "manual":manual, "on_leaders":func(): manual = false},
		"workforce":{"capture":_capture, "step":_step, "evaluate":_evaluate, "commit":_commit}}

func test_all_nine_allocations_are_present_and_reading_is_shared_and_read_only() -> void:
	assert_int(screen.rows.size()).is_equal(9)
	for role: String in Manual.ROLES:
		assert_bool(screen.rows[role].panel.visible).is_true()
		for step: int in [-1, 1, 5]: assert_bool(screen.rows[role].steps[step].visible).is_true()
		screen.focus_work(role)
	assert_int(captures).is_equal(1)
	assert_int(evaluations).is_equal(1)
	assert_int(commits).is_equal(0)
	assert_str(screen.refs.total.text).is_equal("100 people assigned")
	assert_str(screen.refs.scope.text).contains("193 people")
	assert_object(screen.find_child("ApplyWorkDraft", true, false)).is_null()

func test_immediate_steps_use_fresh_tokens_and_show_actual_donors() -> void:
	for index in 3: screen.rows.Knowledge.steps[1].pressed.emit()
	assert_int(commits).is_equal(3)
	assert_int(counts.Knowledge).is_equal(13)
	assert_int(counts.Food).is_equal(17)
	assert_int(captures).is_equal(4)
	assert_str(screen.refs.transfer.text).contains("Learning +1").contains("Food grounds −1")
	assert_str(screen.rows.Knowledge.share.text).is_equal("13%")

func test_requested_target_and_safeguard_adjusted_heads_remain_distinct() -> void:
	protected_food = true
	screen.rows.Crafting.steps[5].pressed.emit()
	assert_str(screen.rows.Crafting.share.text).is_equal("15%")
	assert_str(screen.rows.Crafting.count.text).is_equal("13")
	assert_str(screen.refs.transfer.text).contains("Making +3").contains("Food grounds −3")
	screen.update_block(_block())
	assert_bool(screen._comparison).is_true()
	assert_str(screen.rows.Crafting.share.text).is_equal("15%")

func test_failed_estimate_or_stale_commit_cannot_mutate_and_retry_is_fresh() -> void:
	available = false
	screen.rows.Knowledge.steps[1].pressed.emit()
	assert_int(commits).is_equal(0)
	assert_str(screen.refs.transfer.text).contains("Forecast unavailable")
	available = true; reject = true
	screen.rows.Knowledge.steps[5].pressed.emit()
	assert_int(commits).is_equal(0)
	assert_str(screen.rows.Knowledge.share.text).is_equal("10%")
	reject = false; revision += 1
	screen.rows.Knowledge.steps[1].pressed.emit()
	assert_int(commits).is_equal(1)
	assert_int(counts.Knowledge).is_equal(11)

func test_refresh_restore_and_long_risk_keep_row_nodes_and_controls_fixed() -> void:
	await get_tree().process_frame; screen._layout(); await get_tree().process_frame
	var button: Button = screen.rows.Crafting.steps[1]
	var rectangle := button.get_global_rect()
	for index in 3:
		button.pressed.emit(); screen.update_block(_block()); screen.restore_view_state(screen.view_state())
		await get_tree().process_frame
		assert_object(screen.rows.Crafting.steps[1]).is_same(button)
		assert_object(button.get_global_rect()).is_equal(rectangle)
	screen.forecast.warnings = [{"kind":"water", "text":"Water is short"}, {"kind":"starvation", "text":"Far Valley: food is short now and continued shortfall risks starvation."}]
	screen._fill_consequences(); await get_tree().process_frame
	assert_str(screen.refs.risk.text).starts_with("Far Valley")
	assert_object(button.get_global_rect()).is_equal(rectangle)
	var held := captures
	for index in 3: revision += 1; screen.update_block(_block())
	assert_int(captures).is_equal(held)
	assert_str(screen.refs.estimate_mode.text).contains("PREVIOUS")

func test_empty_unknown_and_boundary_states_do_not_invent_workers_or_effects() -> void:
	for role: String in counts: counts[role] = 0; shares[role] = 0
	screen.update_block(_block())
	assert_str(screen.refs.total.text).is_equal("0 people assigned")
	assert_bool(screen.rows.Knowledge.steps[1].disabled).is_true()
	counts.Knowledge = 100; shares.Knowledge = 100
	screen.update_block(_block())
	assert_bool(screen.rows.Knowledge.steps[1].disabled).is_true()
	assert_bool(screen.rows.Food.steps[-1].disabled).is_true()
	available = false; screen._refresh_current()
	assert_str(screen.refs.food.text).is_equal("Food estimate unavailable")
	assert_str(screen.rows.Knowledge.effect.text).is_equal("Estimate unavailable")

func test_delegation_uses_original_callback_and_restore_never_replays_actions() -> void:
	screen.rows.Crafting.steps[1].pressed.emit()
	var state: Dictionary = screen.view_state()
	screen.focus_work("Knowledge"); screen.restore_view_state(state)
	assert_str(screen.active_role).is_equal("Crafting")
	assert_int(commits).is_equal(1)
	screen.refs.delegate.pressed.emit()
	assert_bool(manual).is_false()
	assert_int(commits).is_equal(1)

func test_same_heads_after_world_change_do_not_certify_old_consequences() -> void:
	screen.rows.Crafting.steps[1].pressed.emit()
	assert_bool(screen._comparison).is_true()
	revision += 1
	screen.update_block(_block())
	assert_bool(screen._comparison).is_false()
	assert_bool(screen._dirty).is_true()
	assert_str(screen.refs.estimate_mode.text).contains("PREVIOUS")

func test_research_and_food_change_explain_tradeoff_without_claiming_discoveries() -> void:
	screen._comparison = true
	screen.forecast.before.research = {"effective_work":20.0, "teams":2, "goods_a_day":3.0}
	screen.forecast.after.research = {"effective_work":30.0, "teams":3, "goods_a_day":5.0}
	screen.forecast.before.food = {"net":-100.0}
	screen.forecast.after.food = {"net":-150.0}
	screen.focus_work("Knowledge")
	assert_str(screen._metrics[0].value.text).is_equal("+50% supplied effort")
	assert_str(screen._metrics[1].value.text).contains("2 → 3 teams")
	assert_str(screen.refs.food.text).contains("50 more rations drawn from stores/day")
	assert_str(screen._metrics[0].slot.tooltip_text).contains("not discoveries per day")
	screen._comparison = false
	screen.forecast.after.food = {"net":0.0, "stock":0.0, "hunger_risk":true}
	screen.forecast.warnings = [{"kind":"starvation", "text":"Far Valley: food is short now and continued shortfall risks starvation."}]
	screen._fill_consequences()
	assert_str(screen.refs.food.text).contains("Stored food is unchanged")
	assert_str(screen.refs.risk.text).contains("risks starvation")
