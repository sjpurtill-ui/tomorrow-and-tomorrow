extends GdUnitTestSuite
const Culture:=preload("res://scripts/settlement_culture_visual.gd")
const Values:=preload("res://scripts/societal_values_model.gd")
const Country:=preload("res://scripts/settlement_country_plan.gd")
const Growth:=preload("res://scripts/settlement_country_growth.gd")

func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("builders",1301)

func after_test()->void:WorldSimulation.clear()

func _set_values(order:float,openness:float,crafts:=false)->void:
	var state=WorldSimulation.state
	state.societal_values=Values.initial_state("",state.world_seed,WorldSimulation.actor_id)
	for axis:String in Values.VALUE_ORDER:state.societal_values.lived[axis]=.5
	state.societal_values.lived.centralization=order;state.societal_values.lived.hierarchy=order
	for axis:String in ["openness","experimentation","pluralism"]:state.societal_values.lived[axis]=openness
	if crafts:
		for id:String in ["clay_shaping","lime_mortar","mineral_pigment_preparation","pictographic_records"]:
			if id not in state.known_discoveries:state.known_discoveries.append(id)
			state.discovery_adoption[id]=1.0

func _found()->void:
	var state=WorldSimulation.state
	state.ensure_population_total(80);state.settlement_completed.assign(["Hearth Circle"])
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_allocations.Construction=0
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.elapsed_days=30;WorldSimulation.settlements.ensure_founded()

func test_founding_and_actual_new_household_record_current_owner_finish()->void:
	WorldSimulation.scoped("builders",func()->void:
		_set_values(.8,.3);_found()
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		var expected:Dictionary=model._current_cultural_appearance()
		assert_int(int(expected.door)).is_equal(1)
		assert_dict(state.settlement_plots[0].cultural_appearance).is_equal(expected)
		state.ensure_population_total(240)
		var count:int=state.settlement_plots.size();var events:Array[Dictionary]=[]
		assert_bool(model._attempt_household_growth(30,events,{},2)).is_true()
		assert_int(state.settlement_plots.size()).is_equal(count+1)
		var plot:Dictionary=state.settlement_plots.back()
		assert_str(String(plot.status)).is_equal("under_construction")
		assert_dict(plot.cultural_appearance).is_equal(expected)
		# Stamps are independent snapshots, not aliases of another household.
		plot.cultural_appearance.door=3
		assert_dict(state.settlement_plots[0].cultural_appearance).is_equal(expected)
	)

func test_legacy_adoption_is_once_without_economy_history_or_footprint_changes()->void:
	WorldSimulation.scoped("builders",func()->void:
		_set_values(.8,.3);_found()
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		# Existing saved records lack this optional cosmetic field. Fields and
		# destroyed buildings must not acquire occupied architectural finishes.
		for plot:Dictionary in state.settlement_plots:plot.erase("cultural_appearance")
		state.settlement_plots[0].status="ruin"
		state.settlement_plots[1].land_use="field"
		var old:Array=state.settlement_plots.duplicate(true)
		var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
		var history:Array=state.settlement_plot_history.duplicate(true)
		var ledger:Array=state.building_ledger.duplicate(true)
		var routes:Array=state.settlement_routes.duplicate(true)
		var population:int=state.population_total;var revision:int=state.morphology_revision
		_set_values(.3,.8,true)
		var expected:Dictionary=model._current_cultural_appearance()
		model.ensure_founded()
		assert_bool(state.settlement_plots[0].has("cultural_appearance")).is_false()
		assert_bool(state.settlement_plots[1].has("cultural_appearance")).is_false()
		var adopted:=0
		for index in state.settlement_plots.size():
			var plot:Dictionary=state.settlement_plots[index]
			if plot.has("cultural_appearance"):
				adopted+=1;assert_dict(plot.cultural_appearance).is_equal(expected)
			var without_finish:=plot.duplicate(true);without_finish.erase("cultural_appearance")
			assert_dict(without_finish).is_equal(old[index])
		assert_int(adopted).is_greater(0)
		assert_int(state.morphology_revision).is_equal(revision+1)
		var after:Array=state.settlement_plots.duplicate(true)
		_set_values(.8,.3,true);model.ensure_founded();model.ensure_founded()
		assert_array(state.settlement_plots).is_equal(after)
		assert_int(state.morphology_revision).is_equal(revision+1)
		assert_dict(state.resource_stockpiles).is_equal(stocks)
		assert_int(state.population_total).is_equal(population)
		assert_array(state.settlement_plot_history).is_equal(history)
		assert_array(state.building_ledger).is_equal(ledger)
		assert_array(state.settlement_routes).is_equal(routes)
	)

func test_culture_and_craft_development_waits_for_actual_inherited_fabric_renewal()->void:
	WorldSimulation.scoped("builders",func()->void:
		_set_values(.8,.3);_found()
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		var inherited:Dictionary=state.settlement_plots[0].cultural_appearance.duplicate(true)
		_set_values(.3,.8,true)
		var current:Dictionary=model._current_cultural_appearance()
		assert_str(Culture.signature(current)).is_not_equal(Culture.signature(inherited))
		model.ensure_founded()
		assert_dict(state.settlement_plots[0].cultural_appearance).is_equal(inherited)
		# Run the existing quarterly conversion selector with one actual slot.
		state.city_form={"tier":1.0,"condition":.8}
		state.simulation_metrics.logistics=0.0;state.population_allocations.Construction=0
		state.elapsed_days=90
		var events:Array[Dictionary]=[]
		model._evolve_inherited_fabric(90,events)
		assert_int(events.size()).is_equal(1)
		var changed:=0;var retained:=0
		for plot:Dictionary in state.settlement_plots:
			if int(plot.get("converted_day",-1))==90:
				changed+=1
				assert_int(int(plot.fabric_generation)).is_equal(1)
				assert_dict(plot.cultural_appearance).is_equal(current)
			elif plot.has("cultural_appearance"):
				retained+=1;assert_dict(plot.cultural_appearance).is_equal(inherited)
		assert_int(changed).is_equal(1);assert_int(retained).is_greater(0)
	)

func test_secondary_and_foreign_owners_keep_their_finish_and_country_templates_keep_geometry_order()->void:
	WorldSimulation.create_actor("neighbor",1302)
	var owners:Dictionary={}
	for owner:String in ["builders","neighbor"]:
		WorldSimulation.scoped(owner,func()->void:
			_set_values(.8 if owner=="builders" else .3,.3 if owner=="builders" else .8,true);_found()
			var state=WorldSimulation.state;var model=WorldSimulation.settlements
			var expected:Dictionary=model._current_cultural_appearance();owners[owner]=expected.duplicate(true)
			var city:Dictionary={"id":"second","name":"Second","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":30,"local_resources":{}}
			model._create_founding_plots(city)
			var local:Array=city.local_resources.settlement_plots
			assert_array(local).is_not_empty()
			assert_dict(local[0].cultural_appearance).is_equal(expected)
			assert_dict(state.settlement_plots[0].cultural_appearance).is_equal(expected)
			var plot:Dictionary=state.settlement_plots[0].duplicate(true)
			var duplicate:Dictionary=plot.duplicate(true);duplicate.id=999
			duplicate.cultural_appearance=Culture.neutral()
			var plain:Dictionary=plot.duplicate(true);plain.erase("cultural_appearance")
			var before:=Country._root_fabric([plain])
			var after:=Country._root_fabric([plot,duplicate])
			assert_int(after.templates.size()).is_equal(before.templates.size())
			assert_int(after.templates.size()).is_equal(1)
			assert_dict(after.templates[0].cultural_appearance).is_equal(expected)
			var geometry:Dictionary=after.templates[0].duplicate(true);geometry.erase("cultural_appearance")
			assert_dict(geometry).is_equal(before.templates[0])
			var record:Dictionary={"id":"culture-seed","position":Vector2.ZERO,"settlement_growth":{"seed":713,"parcels":6,"templates":after.templates}}
			var grown:=Growth.begin(record)
			while not Growth.advance(grown,Callable(),Callable()):pass
			assert_array(grown.plots).is_not_empty()
			for child:Dictionary in grown.plots:assert_dict(child.cultural_appearance).is_equal(expected)
			# Already prepared seeds adopt missing finishes once without moving
			# geometry. A previously recorded finish remains part of the old layer.
			var legacy:=grown.duplicate(true)
			for child:Dictionary in legacy.plots:child.erase("cultural_appearance")
			legacy.plots[1]["cultural_appearance"]=Culture.neutral()
			var old_geometry:=legacy.duplicate(true)
			var adopted:=Growth.begin(record,legacy)
			var adopted_count:=0
			for index in (adopted.plots as Array).size():
				var child:Dictionary=adopted.plots[index]
				var prior:Dictionary=old_geometry.plots[index]
				if index==1:assert_dict(child.cultural_appearance).is_equal(Culture.neutral())
				elif String(child.form)==String(plot.form):
					adopted_count+=1;assert_dict(child.cultural_appearance).is_equal(expected)
				var unchanged:=child.duplicate(true);unchanged.erase("cultural_appearance")
				var prior_geometry:=prior.duplicate(true);prior_geometry.erase("cultural_appearance")
				assert_dict(unchanged).is_equal(prior_geometry)
			assert_int(adopted_count).is_greater(0)
			assert_dict(legacy).is_equal(old_geometry)
			assert_array(Growth.begin(record,adopted).plots).is_equal(adopted.plots)
			assert_array(adopted.routes).is_equal(old_geometry.routes)
			# Neither root records nor their templates share mutable finish data.
			after.templates[0].cultural_appearance.door=0
			assert_dict(plot.cultural_appearance).is_equal(expected)
		)
	assert_str(Culture.signature(owners.builders)).is_not_equal(Culture.signature(owners.neighbor))
