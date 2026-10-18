extends GdUnitTestSuite
## Real purse commands against a separate in-memory civilization. No saves.
const Board=preload("res://scripts/hud/purse_board.gd")
const Purse=preload("res://scripts/realm_purse.gd")
const Business=preload("res://scripts/enterprise.gd")
const S=preload("res://scripts/hud/econ_sheet.gd")
const ACTOR:="wealth_presentation_fixture"
var _processing:Dictionary={}
var _tracker:Dictionary={}
var _player_purse:PackedByteArray

func before()->void:
	for name:String in WorldSimulation.OWNED_SYSTEMS:
		var system:Node=WorldSimulation.system(name);_processing[system]=system.is_processing();system.set_process(false)

func after()->void:
	WorldSimulation.clear()
	for system:Node in _processing:system.set_process(bool(_processing[system]))

func before_test()->void:
	_tracker=GameState.order_tracker.duplicate(true)
	_player_purse=var_to_bytes(GameState.realm_purse)
	GameState.order_tracker={"next_id":1,"orders":[]}
	WorldSimulation.clear();WorldSimulation.create_actor(ACTOR,740195)
	WorldSimulation.scoped(ACTOR,func()->void:
		var state=WorldSimulation.state
		state.ensure_population_total(900);state.elapsed_days=3650.0;state.civic_api_enabled=false
		state.settlement_name="Prosperity fixture";state.settlement_site_committed=true
		state.settlement_completed.assign(["Hearth Circle","Lean-to Shelters","Storage Pits"])
		WorldSimulation.settlements.ensure_founded()
		state.economy_stage="subsistence";state.realm_purse={}
		state.resource_stockpiles["Civilian Goods"]=1000.0
		state.market_prices={"Civilian Goods":4.0,"Food":1.0,"Timber":2.0,"Stone":3.0,"Fiber Plants":1.0}
		state.economy_metrics={"price_observations":1,"real_economy":{"daily_output_value":800.0},"social_pressure_parts":{"unequal":.025,"want":.015,"prices":.005,"levy":.01,"benefit":.015,"total":-.04}}
		state.wealth_shares.assign([.07,.12,.18,.23,.40])
		Purse.state();Purse.deposit(250.0,"Fixture goods given to the common store");Purse.forecast();Business.state())

func after_test()->void:
	assert_bool(var_to_bytes(GameState.realm_purse)==_player_purse).override_failure_message("Detached Wealth commands must not change the player's purse").is_true()
	GameState.order_tracker=_tracker
	WorldSimulation.clear()

func _board()->Control:
	var board:Control=auto_free(Board.new());add_child(board)
	board.setup({"mode":"wealth","on_open":func(_section:String,_sub:int):pass});board.set_process(false)
	return board

func _primary(board:Control)->Control:
	return board.find_child("ProsperityAndPressure",true,false)

func _reading_state()->PackedByteArray:
	var state=WorldSimulation.state
	return var_to_bytes([state.realm_purse,state.wealth_shares,state.economy_metrics,state.market_prices,
		state.resource_stockpiles,state.food_stocks,state.player_settlements,state.enterprise,
		state.private_currency,state.public_treasury,state.currency_hoards,state.currency_supply,
		state.population_allocations,state.active_modifiers,WorldSimulation.resources.rng.state,WorldSimulation.discovery.rng.state])

func test_shares_are_equal_household_groups_with_exact_wealth_readings()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var board:=_board();var view:=_primary(board)
		assert_object(view).is_not_null()
		assert_array(view.fifths.values).is_equal(Array(WorldSimulation.state.wealth_shares))
		for index in 5:assert_str(view.quintiles[index].text).is_equal(S.n(float(WorldSimulation.state.wealth_shares[index])*100.0)+"%")
		assert_str(view.refs.share_note.text).contains("wealth").contains("not numbers of people")
		assert_str(view.picture.tooltip_text).contains("illustrative").contains("not a record")
		assert_str(view.refs.store.text).is_equal(Purse.amount_text(Purse.balance()))
		assert_str(view.refs.pressure.text).contains("−4")
		var before:=_reading_state();board.refresh();board.refresh()
		assert_bool(_reading_state()==before).is_true())

func test_live_numeric_changes_retain_primary_controls_and_keyboard_focus()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var board:=_board();var view:=_primary(board)
		var nodes:Array=view.find_children("*","",true,false)
		var focus:Button=view.levels.usual;focus.grab_focus()
		Purse.deposit(19.0,"A real same-day gift")
		WorldSimulation.state.wealth_shares.assign([.08,.13,.19,.24,.36])
		WorldSimulation.state.economy_metrics.social_pressure_parts.want=.035
		WorldSimulation.state.economy_metrics.social_pressure_parts.total=-.06
		var before:=_reading_state();board.refresh()
		assert_array(view.find_children("*","",true,false)).contains_exactly(nodes)
		assert_object(get_viewport().gui_get_focus_owner()).is_same(focus)
		assert_str(view.refs.store.text).is_equal(Purse.amount_text(Purse.balance()))
		assert_str(view.quintiles[4].text).is_equal("36%")
		assert_str(view.refs.pressure.text).contains("−6")
		assert_bool(_reading_state()==before).is_true())

func test_levy_buttons_execute_original_command_once_and_retain_controls()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var board:=_board();var view:=_primary(board);var nodes:Array=view.find_children("*","",true,false)
		for level:String in ["light","heavy","usual"]:
			var prior:Dictionary=Purse.state().duplicate(true)
			var result:=Purse.set_levy(level);assert_bool(result.ok).is_true()
			var expected:Dictionary=Purse.state().duplicate(true)
			WorldSimulation.state.realm_purse=prior
			var order_count:=int(GameState.order_tracker.get("orders",[]).size())
			view.levels[level].pressed.emit()
			assert_dict(Purse.state()).is_equal(expected)
			assert_bool(view.levels[level].button_pressed).is_true()
			assert_int(GameState.order_tracker.orders.size()).is_equal(order_count+1)
			assert_array(view.find_children("*","",true,false)).contains_exactly(nodes))

func test_funding_switches_use_current_state_and_preserve_original_payment_rules()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var board:=_board();var view:=_primary(board);var nodes:Array=view.find_children("*","",true,false)
		for line:String in ["crews","scholars","army"]:
			for pass_index in 2:
				var before:Dictionary=Purse.state().duplicate(true);var target:=not Purse.line_on(line)
				var result:=Purse.set_line(line,target);assert_bool(result.ok).is_true()
				var expected:Dictionary=Purse.state().duplicate(true);WorldSimulation.state.realm_purse=before
				view.funding[line].toggle.pressed.emit()
				assert_dict(Purse.state()).is_equal(expected)
				assert_bool(view.funding[line].toggle.button_pressed).is_equal(target)
				assert_float(Purse.balance()).is_equal(float(before.balance))
				assert_array(view.find_children("*","",true,false)).contains_exactly(nodes))

func test_missing_shares_and_pressure_are_unknown_not_fabricated_zero()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		WorldSimulation.state.wealth_shares.clear();WorldSimulation.state.economy_metrics.erase("social_pressure_parts")
		var board:=_board();var view:=_primary(board)
		assert_array(view.fifths.values).is_empty()
		for label:Label in view.quintiles:assert_str(label.text).is_equal("—")
		assert_str(view.refs.share_note.text).contains("not been recorded")
		assert_str(view.refs.pressure.text).contains("—")
		WorldSimulation.state.economy_metrics.social_pressure_parts={"unequal":0.0,"want":0.0,"prices":0.0,"levy":0.0,"total":0.0}
		board.refresh();assert_str(view.refs.pressure.text).ends_with("0").not_contains("—")
		WorldSimulation.state.economy_metrics.social_pressure_parts.total=.015
		board.refresh();assert_str(view.refs.pressure.text).contains("+1.5"))

func test_current_forecast_is_not_presented_as_the_recorded_cash_reconciliation()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		Purse.deposit(1234.0,"Fixture sale receipt");assert_bool(Purse.spend(17.0,"Fixture outside purchase")).is_true()
		var recorded:=Purse.season();var expected:=Purse.forecast()
		var board:=_board();var view:=_primary(board)
		assert_str(view.refs.store.text).is_equal(Purse.amount_text(float(expected.balance)))
		assert_str(view.refs.forecast.tooltip_text).contains("today").contains(Purse.number(float(recorded.total_in))).contains(Purse.number(float(recorded.total_out)))
		assert_str(view.refs.forecast.text.to_lower()).contains("season")
		assert_bool(is_equal_approx(float(expected.net),float(recorded.total_in)-float(recorded.total_out))).is_false())

func test_currency_uses_the_real_unit_and_store_mode_keeps_its_existing_commands()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		WorldSimulation.state.economy_stage="currency"
		WorldSimulation.state.known_discoveries.append("property_registers")
		Purse.stage();var board:=_board();var view:=_primary(board)
		assert_bool(Purse.in_kind()).is_false()
		assert_str(view.refs.store.text).is_equal(Purse.amount_text(Purse.balance()))
		assert_str(view.refs.funding_unit.text).contains(Purse.unit_word())
		var store:Control=auto_free(Board.new());add_child(store);store.setup({"mode":"store"});store.set_process(false)
		assert_object(store.find_child("ProsperityAndPressure",true,false)).is_null()
		assert_object(store.find_child("Level_light",true,false)).is_not_null()
		assert_object(store.find_child("Line_scholars",true,false)).is_not_null())

func test_partial_funding_and_army_arrears_report_actual_effects_not_the_full_quote()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		for line:String in ["crews","scholars","army"]:Purse.set_line(line,true)
		var purse:=Purse.state()
		purse.funded.crews=.25;purse.funded.scholars=.40;purse.funded.army=0.0
		purse.unpaid_months=2;purse.last_army={"will_lost":.07,"deserted":3}
		var board:=_board();var view:=_primary(board)
		assert_str(view.funding.crews.effect.text).is_equal("Building +%s%% now" % S.n(Purse.crews_bonus()*100.0))
		assert_str(view.funding.scholars.effect.text).is_equal("Research +%s%% now" % S.n((Purse.scholars_factor()-1.0)*100.0))
		assert_float(Purse.crews_bonus()).is_less(Purse.CREWS_MAX)
		assert_float(Purse.scholars_factor()-1.0).is_less(Purse.SCHOLARS_MAX)
		assert_str(view.funding.army.effect.text).contains("arrears").not_contains("no arrears")
		assert_bool(view.refs.unpaid.visible).is_true()
		assert_str(view.refs.unpaid.text).contains("2 months").contains("will −7").contains("3 went home")
		var nodes:Array=view.find_children("*","",true,false)
		purse.funded.crews=0.0;purse.funded.scholars=0.0
		var before:=_reading_state();board.refresh()
		assert_str(view.funding.crews.effect.text).is_equal("Building +0% now")
		assert_str(view.funding.scholars.effect.text).is_equal("Research +0% now")
		assert_array(view.find_children("*","",true,false)).contains_exactly(nodes)
		assert_bool(_reading_state()==before).is_true())

func test_funding_coverage_tracks_paid_share_and_unknown_without_mutating_money()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var purse:=Purse.state();purse.lines.scholars=true;purse.funded.scholars=.25
		var before:=var_to_bytes(purse)
		var board:=_board();var primary:=_primary(board)
		assert_float(primary.funding.scholars.coverage.value).is_equal(25.0)
		assert_str(primary.funding.scholars.coverage_words.text).contains("25% funded")
		assert_bool(var_to_bytes(purse)==before).is_true()
		purse.funded.erase("scholars");board.refresh()
		assert_bool(primary.funding.scholars.coverage.visible).is_false()
		assert_str(primary.funding.scholars.coverage_words.text).contains("not recorded"))
