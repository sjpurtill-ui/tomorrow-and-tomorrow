extends GdUnitTestSuite

func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.create_actor("research_review",789)

func after_test()->void:
	WorldSimulation.clear()

func _question(id:String,domain:String,channel:String,day:int=0)->Dictionary:
	return {"id":id,"dynamic":domain,"subcategory":channel,"day":day,"requires":[],"signals":[]}

func test_exhausted_domains_reassign_independently_and_conserve_emphasis()->void:
	WorldSimulation.scoped("research_review",func()->void:
		var state:=WorldSimulation.state
		var research:=WorldSimulation.discovery
		state.active_investigations.clear()
		state.research_subcategory_allocations={"nutrition":{"Old question":3,"New question":0},"health":{"Old question":2,"New question":0},"culture":{"Continuing question":4}}
		state.research_allocations={"nutrition":3,"health":2,"culture":4}
		research.catalog_by_channel={
			"nutrition::New question":[_question("new_food","nutrition","New question")],
			"health::New question":[_question("new_health","health","New question")],
			"culture::Continuing question":[_question("continuing_culture","culture","Continuing question")]
		}
		var rng_before:=research.rng.state
		research._redistribute_stranded_attention(100)
		assert_dict(state.research_subcategory_allocations).is_equal({"nutrition":{"Old question":0,"New question":3},"health":{"Old question":0,"New question":2},"culture":{"Continuing question":4}})
		assert_dict(state.research_allocations).is_equal({"nutrition":3,"health":2,"culture":4})
		assert_int(research.rng.state).is_equal(rng_before)
	)

func test_unrelated_live_work_cannot_take_waiting_emphasis_and_later_evidence_wakes_it()->void:
	WorldSimulation.scoped("research_review",func()->void:
		var state:=WorldSimulation.state
		var research:=WorldSimulation.discovery
		state.active_investigations.clear()
		state.research_subcategory_allocations={"nutrition":{"Old question":3,"New question":0},"culture":{"Continuing question":4}}
		state.research_allocations={"nutrition":3,"culture":4}
		var gated:=_question("new_food","nutrition","New question",101)
		gated.requires=["food_drying"]
		state.known_discoveries.erase("food_drying")
		research.catalog_by_channel={"nutrition::New question":[gated],"culture::Continuing question":[_question("continuing_culture","culture","Continuing question")]}
		var waiting:=state.research_subcategory_allocations.duplicate(true)
		for day in [100,101]:
			research._redistribute_stranded_attention(day)
			assert_dict(state.research_subcategory_allocations).is_equal(waiting)
		state.known_discoveries.append("food_drying")
		research._redistribute_stranded_attention(100)
		# The approved revamp opens causal routes without a calendar unlock.
		assert_dict(state.research_subcategory_allocations).is_equal({"nutrition":{"Old question":0,"New question":3},"culture":{"Continuing question":4}})
		research._redistribute_stranded_attention(101)
		assert_dict(state.research_subcategory_allocations).is_equal({"nutrition":{"Old question":0,"New question":3},"culture":{"Continuing question":4}})
		assert_dict(state.research_allocations).is_equal({"nutrition":3,"culture":4})
	)
