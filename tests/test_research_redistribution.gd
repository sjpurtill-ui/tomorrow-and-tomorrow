extends GdUnitTestSuite
## Teams move, emphasis stays: when a line's questions run out its teams take up
## questions elsewhere, and nobody's steps of attention are moved behind the
## player's back.

func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.create_actor("research_review",789)

func after_test()->void:
	WorldSimulation.clear()

func _question(id:String,domain:String,channel:String,day:int=0)->Dictionary:
	return {"id":id,"dynamic":domain,"subcategory":channel,"day":day,"requires":[],"signals":[]}

func test_exhausted_lines_send_their_teams_on_and_conserve_emphasis()->void:
	WorldSimulation.scoped("research_review",func()->void:
		var state:=WorldSimulation.state
		var research:=WorldSimulation.discovery
		state.population_allocations.Knowledge=30
		state.active_investigations.clear()
		state.research_subcategory_allocations={"nutrition":{"Old question":3,"New question":0},"health":{"Old question":2,"New question":0},"culture":{"Continuing question":4}}
		state.research_allocations={"nutrition":3,"health":2,"culture":4}
		# Only these questions exist here: no foundation work from the catalog.
		research.technology_catalog.clear();research._research_600_foundation_cache.clear()
		research.catalog_by_channel={
			"nutrition::New question":[_question("new_food","nutrition","New question")],
			"health::New question":[_question("new_health","health","New question")],
			"culture::Continuing question":[_question("continuing_culture","culture","Continuing question")]
		}
		var rng_before:=research.rng.state
		research.refresh_investigations()
		# A line's team may work any of its channels, whatever steps they hold.
		assert_str(String(state.active_investigations.get("nutrition::New question",""))).is_equal("new_food")
		assert_str(String(state.active_investigations.get("health::New question",""))).is_equal("new_health")
		assert_str(String(state.active_investigations.get("culture::Continuing question",""))).is_equal("continuing_culture")
		assert_dict(state.research_subcategory_allocations).is_equal({"nutrition":{"Old question":3,"New question":0},"health":{"Old question":2,"New question":0},"culture":{"Continuing question":4}})
		assert_dict(state.research_allocations).is_equal({"nutrition":3,"health":2,"culture":4})
		assert_int(research.rng.state).is_equal(rng_before)
	)

func test_waiting_emphasis_stays_put_and_later_evidence_wakes_it()->void:
	WorldSimulation.scoped("research_review",func()->void:
		var state:=WorldSimulation.state
		var research:=WorldSimulation.discovery
		state.population_allocations.Knowledge=30
		state.active_investigations.clear()
		state.research_subcategory_allocations={"nutrition":{"Old question":3,"New question":0},"culture":{"Continuing question":4}}
		state.research_allocations={"nutrition":3,"culture":4}
		var gated:=_question("new_food","nutrition","New question",101)
		gated.requires=["food_drying"]
		state.known_discoveries.erase("food_drying")
		research.technology_catalog.clear();research._research_600_foundation_cache.clear()
		research.catalog_by_channel={"nutrition::New question":[gated],"culture::Continuing question":[_question("continuing_culture","culture","Continuing question")]}
		var waiting:=state.research_subcategory_allocations.duplicate(true)
		for day in [100,101]:
			state.elapsed_days=float(day)
			research.refresh_investigations()
			assert_dict(state.research_subcategory_allocations).is_equal(waiting)
			assert_bool("new_food" in state.active_investigations.values()).is_false()
		state.known_discoveries.append("food_drying")
		research.refresh_investigations()
		# The approved revamp opens causal routes without a calendar unlock.
		assert_str(String(state.active_investigations.get("nutrition::New question",""))).is_equal("new_food")
		assert_dict(state.research_subcategory_allocations).is_equal(waiting)
		assert_dict(state.research_allocations).is_equal({"nutrition":3,"culture":4})
	)
