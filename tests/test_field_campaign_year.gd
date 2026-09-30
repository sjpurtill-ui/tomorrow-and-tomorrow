extends GdUnitTestSuite
## A YEAR IN THE FIELD (field_sustainment.gd, carriers.gd, the day's
## rations): cadence and conservation over 365 days, the way a player would
## see them. A fed band with open places is refilled by a bounded stream of
## drafts (never a pile of one-man orders); a band cut off from its line
## starves at the stated pace and gets no drafts; every person is accounted
## for at every step.

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(3650)
	GameState.ensure_population_total(3000)
	GameState.settlement_site_committed=true;GameState.settlement_founded_at=Vector3.ZERO
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	FoodSystem.reset_for_new_world();FoodSystem.receive_external_food(1000000)
	GameState.population_allocations["Defense"]=600
	GameState.population_allocations["Logistics"]=80
	GameState.resource_stockpiles["Transport Carts"]=6.0
	MilitaryCampaign.military_inventory["spear"]=400

func after_test()->void:
	WorldSimulation.clear()

func _band(men:int,authorized:int)->Dictionary:
	var sim=MilitaryCampaign.simulator
	var sets:int=sim.equipment_required_for_weapon("spear",authorized)
	var force:Dictionary=sim.create_formation_force("Band",[{"id":1,"unit":"spearman","weapon":"spear","count":men,"authorized_count":authorized,"equipment":sets,"equipment_required":sets,"ammunition":0,"ammunition_required":0,"training":0.7,"experience":0.2,"personnel_condition":1.0}],1.0,1.0)
	force.merge({"army_id":1,"name":"Band","status":"stationed","location_id":"field","position":{"x":60.0,"z":0.0},"supply_level":1.0},true)
	return force

## Everyone the army holds, by the ledger's own parts.
func _parts()->int:
	var ledger:Dictionary=MilitaryCampaign.personnel_ledger()
	var sum:=0
	for key in ["naval_air","home","field","occupation","recruits","training","recovering","missing","replacements"]: sum+=int(ledger[key])
	assert_int(sum).is_equal(int(ledger.total))
	return sum

func _day(fed:bool)->void:
	GameState.elapsed_days+=1
	var need:=float(MilitaryCampaign.field_army_active_personnel())*1.12
	MilitaryCampaign.record_daily_provisions(need,need if fed else 0.0)
	MilitaryCampaign.sustainment.draft_day()
	MilitaryCampaign._process_training_day()
	MilitaryCampaign.sustainment.arrivals_day()

func test_a_fed_band_is_refilled_by_a_bounded_stream_of_drafts()->void:
	MilitaryCampaign.field_armies.assign([_band(300,400)])
	var population:=GameState.population_total
	var most_orders:=0
	var most_on_road:=0
	for day in 365:
		_day(true)
		var orders:=MilitaryCampaign.training_queue.filter(func(o:Dictionary)->bool:return String(o.get("mode",""))=="field_draft").size()
		most_orders=maxi(most_orders,orders)
		most_on_road=maxi(most_on_road,MilitaryCampaign.field_drafts.size())
		_parts()
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	# Refilled to within one minimum draft (2% of the band): a few men hurt in
	# training are not worth a new course on their own.
	assert_int(int(band.troops)).is_between(400-ceili(400*MilitaryCampaign.sustainment.DRAFT_MIN_SHARE),400)
	assert_int(int(band.formations[0].equipment)).is_less_equal(int(band.formations[0].equipment_required))
	# One formation: one course at a time, a few groups on the road at most.
	assert_int(most_orders).is_less_equal(1)
	assert_int(most_on_road).is_less_equal(3)
	assert_int(GameState.population_total).is_equal(population)

func test_a_band_cut_off_starves_at_the_stated_pace_and_is_not_redrafted()->void:
	GameState.population_allocations["Logistics"]=0
	GameState.resource_stockpiles["Transport Carts"]=0.0
	MilitaryCampaign.field_armies.assign([_band(400,400)])
	var population:=GameState.population_total
	for day in 60: _day(false)
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	var lost:Dictionary=band.get("hunger_losses",{})
	var total:=int(lost.get("sick",0))+int(lost.get("deserted",0))+int(lost.get("dead",0))
	# Foraging still feeds part of the band, so two months cost well under half.
	assert_int(total).is_greater(0)
	assert_float(float(total)/400.0).is_less(0.45)
	assert_int(int(band.troops)+total).is_equal(400)
	assert_int(GameState.population_total).is_equal(population-int(lost.get("dead",0)))
	assert_int(MilitaryCampaign.training_queue.size()).is_equal(0)
	assert_int(MilitaryCampaign.field_drafts.size()).is_equal(0)
	_parts()
