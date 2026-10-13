extends GdUnitTestSuite
## ARE THESE TWO PEOPLES FIGHTING (war_state.gd): one answer for war, feud and
## peace, and everything that asks (the trade ledger, the fleets, the envoys,
## the court's war orders) gives the same one. Quick: three peoples next door,
## no day simulated.

const State:=preload("res://scripts/war_state.gd")
const War:=preload("res://scripts/war_loop.gd")
const Trade:=preload("res://scripts/trade_ledger.gd")
const Orders:=preload("res://scripts/court_war_orders.gd")

var ids:Array=[]

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0,3))
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.start_world()
	ids=[]
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]
	CivilizationSystem.player_world_origin=Vector2.ZERO
	for i in CivilizationSystem.civilizations.size():
		var c:Dictionary=CivilizationSystem.civilizations[i]
		ids.append(String(c.id))
		var at:=Vector2(60.0*float(i+1),0.0)
		c["world_position"]=at
		c["position"]=Vector2(at.x/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,0.0)
		for region:Dictionary in c.get("strategic_regions",[]):
			if String(region.get("role",""))=="capital": region["position"]=at
		c["alive"]=true; c["population"]=900.0
		var rel:Dictionary=c.player_relation
		rel["contact_level"]=2; rel["home_location_known"]=true; rel["opinion"]=-0.3; rel["treaty"]="none"; rel["at_war"]=false
	ForeignDiplomacy.ensure()

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	CivilizationSystem.scout_land_authority=Callable()
	ForeignDiplomacy.reset_for_new_world()

func _pair(a:String,b:String)->Dictionary:
	var first:Dictionary=Trade.civ(a)
	var relations:Dictionary=first.get("relations",{})
	if not relations.has(b): relations[b]={}
	first["relations"]=relations
	return relations[b]

func test_with_us_war_feud_and_peace_are_told_apart_and_everyone_agrees()->void:
	var a:=String(ids[0])
	GameState.elapsed_days=400*365.0
	var day:=int(GameState.elapsed_days)
	assert_str(State.between("player",a)).is_equal("peace")
	assert_bool(Orders.at_war(a)).is_false()
	assert_bool(MilitaryCampaign.joint_operations._hostile("player",a)).is_false()
	assert_bool(ForeignDiplomacy.commitments.at_war("player",a)).is_false()
	assert_str(Trade.blocked("player",a)).is_not_equal("war")
	# A feud: harm done lately, nothing declared.
	var f:=War.front(a)
	f["level"]=1; f["last_harm"]=day-30
	assert_str(State.between("player",a)).is_equal("feud")
	assert_str(State.between(a,"player")).is_equal("feud")
	assert_bool(State.at_war("player",a)).is_false()
	assert_bool(State.fighting("player",a)).is_true()
	assert_str(Trade.blocked("player",a)).is_equal("feud")
	assert_bool(Orders.at_war(a)).is_false()
	# A declared war.
	CivilizationSystem.civilizations[0].player_relation["at_war"]=true
	assert_str(State.between("player",a)).is_equal("war")
	assert_bool(State.feud("player",a)).is_false()
	assert_bool(Orders.at_war(a)).is_true()
	assert_bool(MilitaryCampaign.joint_operations._hostile("player",a)).is_true()
	assert_bool(MilitaryCampaign.joint_operations._hostile(a,"player")).is_true()
	assert_bool(ForeignDiplomacy.commitments.at_war(a,"player")).is_true()
	assert_str(Trade.blocked("player",a)).is_equal("war")
	# The second people is untouched by any of it.
	assert_str(State.between("player",String(ids[1]))).is_equal("peace")

func test_two_other_peoples_war_feud_and_peace()->void:
	var a:=String(ids[0]); var b:=String(ids[1])
	GameState.elapsed_days=400*365.0
	var day:=int(GameState.elapsed_days)
	assert_str(State.between(a,b)).is_equal("peace")
	assert_str(State.between(a,a)).is_equal("peace")
	var pair:=_pair(a,b)
	pair["feud_since"]=day-200; pair["feud_last"]=day-40
	assert_str(State.between(a,b)).is_equal("feud")
	assert_str(Trade.blocked(a,b)).is_equal("feud")
	assert_bool(MilitaryCampaign.joint_operations._hostile(a,b)).is_false()
	# A feud nobody has raided in for longer than it stays hot is peace again.
	pair["feud_last"]=day-CivilizationSystem.RIVAL_FEUD_HOT_DAYS-1
	assert_str(State.between(a,b)).is_equal("peace")
	pair["at_war"]=true
	assert_str(State.between(a,b)).is_equal("war")
	assert_bool(MilitaryCampaign.joint_operations._hostile(a,b)).is_true()
	assert_bool(ForeignDiplomacy.commitments.at_war(a,b)).is_true()
	assert_str(Trade.blocked(a,b)).is_equal("war")
	# A people nobody knows of is fighting nobody.
	assert_str(State.between(a,"nobody")).is_equal("peace")
