extends GdUnitTestSuite
const F=preload("res://scripts/formed_workpiece.gd")
const P=preload("res://scripts/persistent_production.gd")
const I=preload("res://scripts/civilian_industry.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("formed_lifecycle",1401)
func after_test()->void:WorldSimulation.clear()
func prepare(work:float)->Dictionary:
	var state=WorldSimulation.state;var spec:=I.product("gently_formed_steel_bars")
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
	state.resource_stockpiles.Steel=1.0
	for resource:String in spec.tooling:state.resource_stockpiles[resource]=10.0
	Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
	assert_bool(WorldSimulation.military.start_production_line("gently_formed_steel_bars",1).get("ok",false)).is_true()
	var line:Dictionary=WorldSimulation.military.equipment_queue.back()
	P.advance(WorldSimulation.military,line,work)
	return line
func test_malformed_pending_store_and_overlapping_workpiece_are_rejected()->void:
	WorldSimulation.scoped("formed_lifecycle",func()->void:
		var line:=prepare(.5)
		for bad_site:Variant in [null,42]:
			var altered:Dictionary=line.duplicate(true)
			if bad_site==null:altered.forming_pending.erase("site")
			else:altered.forming_pending.site=bad_site
			assert_str(P.validate_saved({"equipment_queue":[altered]})).is_not_empty()
		var pending:Dictionary=line.forming_pending.duplicate(true)
		P.advance(WorldSimulation.military,line,1.5)
		pending.ordinal=2
		line.forming_pending=pending;line.progress_days=.5
		assert_str(P.validate_saved({"equipment_queue":[line]})).is_not_empty()
	)
func test_actual_cancel_downgrades_finished_piece_once_and_never_refunds_partial_feed()->void:
	WorldSimulation.scoped("formed_lifecycle",func()->void:
		var line:=prepare(2)
		assert_bool(WorldSimulation.military.cancel_equipment_job(line.id).get("cancelled",false)).is_true()
		assert_float(float(WorldSimulation.state.resource_stockpiles[F.MATERIAL])).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Unqualified Formed Steel"])).is_equal(1.0)
		assert_bool(F.clear(line)).is_true()
		assert_float(float(WorldSimulation.state.resource_stockpiles["Unqualified Formed Steel"])).is_equal(1.0)
		line=prepare(.5)
		assert_bool(WorldSimulation.military.cancel_equipment_job(line.id).get("cancelled",false)).is_true()
		assert_float(float(WorldSimulation.state.resource_stockpiles.Steel)).is_equal(0.0)
	)
func test_retool_and_mismatched_store_preserve_exact_ownership()->void:
	WorldSimulation.scoped("formed_lifecycle",func()->void:
		var line:=prepare(2);var state=WorldSimulation.state
		line.formed_piece.site="unavailable_store"
		assert_bool(WorldSimulation.military.cancel_equipment_job(line.id).has("error")).is_true()
		assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
		assert_float(float(state.resource_stockpiles[F.MATERIAL])).is_equal(1.0)
		line.formed_piece.site=state.resource_settlement_id
		state.resource_stockpiles.Steel=1.0
		assert_bool(WorldSimulation.military.retool_production_line(line.id,"cold_bent_steel_bars").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles[F.MATERIAL])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Unqualified Formed Steel"])).is_equal(1.0)
		P.advance(WorldSimulation.military,line,2)
		var source:=F.take();assert_bool(source.consumed).is_true()
		state.resource_stockpiles[F.MATERIAL]-=1.0
		assert_bool(WorldSimulation.military.cancel_equipment_job(line.id).get("cancelled",false)).is_true()
		assert_float(float(state.resource_stockpiles["Unqualified Formed Steel"])).is_equal(1.0)
	)

func test_cancellation_downgrades_at_original_secondary_store()->void:
	WorldSimulation.scoped("formed_lifecycle",func()->void:
		var line:=prepare(2);var state=WorldSimulation.state
		state.player_settlements.append({"id":"metal_store","name":"Metal store","primary":false,"position":Vector2(10,0),"population_share":.1,"founded_day":0})
		state.resource_stockpiles[F.MATERIAL]=7.0
		line.formed_piece.site="metal_store"
		WorldSimulation.settlements.with_city_resources("metal_store",func()->void:
			state.resource_stockpiles[F.MATERIAL]=1.0
		)
		assert_bool(WorldSimulation.military.cancel_equipment_job(line.id).get("cancelled",false)).is_true()
		assert_float(float(state.resource_stockpiles[F.MATERIAL])).is_equal(7.0)
		WorldSimulation.settlements.with_city_resources("metal_store",func()->void:
			assert_float(float(state.resource_stockpiles[F.MATERIAL])).is_equal(0.0)
			assert_float(float(state.resource_stockpiles["Unqualified Formed Steel"])).is_equal(1.0)
		)
	)
