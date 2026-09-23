extends GdUnitTestSuite
const L=preload("res://scripts/communications_links.gd")
const E=preload("res://scripts/society_exchange.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const Purchase=preload("res://scripts/research_purchase.gd")
func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.create_actor("sender",921,Vector2(30,0))
	WorldSimulation.create_actor("receiver",922,Vector2.ZERO)
	for id:String in ["sender","receiver"]:
		WorldSimulation.scoped(id,func()->void:
			var state=WorldSimulation.state
			state.settlement_site_committed=true;state.convoy_traveling=false
			state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
			state.population_allocations.Crafting=10
			state.elapsed_days=100
			for gate:String in ["radio_telegraphy","agreed_signal_codes"]:
				state.known_discoveries.append(gate);state.discovery_adoption[gate]=1.0
			stock_bill(state,Ops.PLANTS.research_radio_station.cost,1.0)
			stock_bill(state,Ops.PLANTS.research_radio_station.inputs,200.0)
			assert_bool(Ops.install("research_radio_station").get("ok",false)).is_true()
			Ops.data().plants.solar_array={"installed":1,"building":0,"work":0.0,"enabled":true}
			for day in range(90,101):state.elapsed_days=day;Ops.advance(day)
		)
	WorldSimulation.scoped("receiver",func()->void:
		WorldSimulation.world.civilizations.append({"id":"sender","name":"Sender","player_relation":{"at_war":false}}))
func after_test()->void:WorldSimulation.clear()
## Adds `bill` × `times` to the local stock (costs are raw materials and Civilian Goods).
func stock_bill(state,bill:Dictionary,times:float)->void:
	for item:String in bill:state.resource_stockpiles[item]=float(state.resource_stockpiles.get(item,0.0))+float(bill[item])*times
func mission()->Dictionary:
	var item:={"id":"purchase:sender:clay_shaping","kind":"knowledge","name":"Purchased clay study","source_id":"sender","source_name":"Sender","position":{"x":30.0,"z":0.0},"observed_day":100,"returned_day":100,"discovery_id":"clay_shaping","study":0.0,"work":120.0,"signals":["crafting"],"research_purchase":true}
	return {"civ_id":"sender","research_subject":"clay_shaping","accepted":true,"research_refused":false,"arrival_day":100,"return_day":110,"target_kind":"known settlement","encountered_societies":["sender"],"origin_position":{"x":0.0,"z":0.0},"target_position":{"x":30.0,"z":0.0},"carried_collections":[item],"gift_resource":"Stone","gift_amount":10.0}
func test_paired_stations_deliver_unstudied_records_without_moving_people_or_refunding_payment()->void:
	WorldSimulation.scoped("receiver",func()->void:
		var m:=mission()
		assert_float(Ops.service("radio_records")).is_equal(1.0)
		assert_int(L.transmit(m,100)).is_equal(1)
		assert_float(Ops.service("radio_records")).is_equal(0.0)
		assert_float(float(E.owner_state("sender").technology_operations.services.radio_records)).is_equal(0.0)
		assert_int(int(m.return_day)).is_equal(110)
		assert_float(float(E.data().collections["purchase:sender:clay_shaping"].study)).is_equal(0.0)
		assert_bool("clay_shaping" in WorldSimulation.state.known_discoveries).is_false()
		assert_int(L.transmit(m,100)).is_equal(0)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(m))
		assert_bool(E.valid_mission(saved)).is_true()
		Purchase.prepare_return(saved)
		assert_bool(saved.research_refused).is_false()
		assert_array(E.returned(saved,110)).is_empty()
		assert_bool(saved.get("research_refunded",false)).is_false()
	)
func test_no_power_or_disabled_peer_leaves_records_with_envoys()->void:
	WorldSimulation.scoped("receiver",func()->void:
		var m:=mission()
		E.owner_state("sender").technology_operations.plants.research_radio_station.enabled=false
		assert_int(L.transmit(m,100)).is_equal(0)
		E.owner_state("sender").technology_operations.plants.research_radio_station.enabled=true
		Ops.set_enabled("solar_array",false);WorldSimulation.state.elapsed_days=101;Ops.advance(101)
		assert_float(Ops.service("radio_records")).is_equal(0.0)
		assert_int(L.transmit(m,101)).is_equal(0)
		assert_int(E.returned(m,110).size()).is_equal(1)
	)
func test_contact_range_and_war_prevent_a_link()->void:
	WorldSimulation.scoped("receiver",func()->void:
		var m:=mission();m.encountered_societies=[]
		assert_int(L.transmit(m,100)).is_equal(0)
		m.encountered_societies=["sender"]
		WorldSimulation.world.civilizations.back().player_relation.at_war=true
		assert_int(L.transmit(m,100)).is_equal(0)
		WorldSimulation.world.civilizations.back().player_relation.at_war=false
		WorldSimulation.scoped("sender",func()->void:WorldSimulation.world.player_world_origin=Vector2(130,0))
		m.target_position={"x":130.0,"z":0.0}
		assert_int(L.transmit(m,100)).is_equal(0)
		assert_float(Ops.service("radio_records")).is_equal(1.0)
	)
func test_station_capacity_cannot_send_physical_artifacts_or_people()->void:
	WorldSimulation.scoped("receiver",func()->void:
		var m:=mission();m.carried_collections[0].kind="artifact"
		assert_int(L.transmit(m,100)).is_equal(0)
		m.carried_collections[0].kind="knowledge";m.carried_collections[0].research_purchase=false
		m.research_mode="scholar"
		assert_int(L.transmit(m,100)).is_equal(0)
		assert_float(Ops.service("radio_records")).is_equal(1.0)
		m.transmitted_collections=["invented"]
		assert_bool(E.valid_mission(m)).is_false()
	)

func test_rival_investment_requires_active_research_work_and_spends_hardware()->void:
	WorldSimulation.scoped("receiver",func()->void:
		var state=WorldSimulation.state
		Ops.data().plants.erase("research_radio_station")
		var spec:Dictionary=Ops.PLANTS.research_radio_station
		for item:String in spec.cost:state.resource_stockpiles[item]=0.0
		for item:String in spec.inputs:state.resource_stockpiles[item]=0.0
		stock_bill(state,spec.cost,1.0);stock_bill(state,spec.inputs,30.0)
		var before:Dictionary=state.resource_stockpiles.duplicate()
		state.population_allocations.Knowledge=10
		var planner=preload("res://scripts/communications_investment.gd")
		assert_dict(planner.radio_recommendation()).is_empty()
		WorldSimulation.world.diplomatic_mission=mission()
		assert_str(planner.radio_recommendation().get("plant","")).is_equal("research_radio_station")
		preload("res://scripts/civilization_controller.gd").civilian_orders("receiver",{})
		for item:String in spec.cost:assert_float(float(state.resource_stockpiles[item])).is_equal_approx(float(before[item])-float(spec.cost[item]),.000001)
		assert_int(int(Ops.data().plants.research_radio_station.building)).is_equal(1)
		assert_dict(planner.radio_recommendation()).is_empty()
	)
