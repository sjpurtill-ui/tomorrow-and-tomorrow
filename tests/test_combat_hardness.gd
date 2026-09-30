extends GdUnitTestSuite
## ARMOUR BY HARDNESS (combat_simulator.gd): a formation is as hard as its
## kit's armour; our blows against the enemy's hard share lose what our kit
## cannot pierce, and the enemy's fire falls on our men in proportion to what
## gets through our armour. Soft against soft is unchanged.

const Combat:=preload("res://scripts/combat_simulator.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")

var sim

func before_test()->void:
	sim=auto_free(Combat.new())

func _force(name:String,parts:Array)->Dictionary:
	var formations:=[]
	for part in parts:
		var count:=int(part[2])
		var sets:int=sim.equipment_required_for_weapon(String(part[1]),count)
		formations.append({"unit":String(part[0]),"weapon":String(part[1]),"count":count,"authorized_count":count,"equipment":sets,"equipment_required":sets,"ammunition":sim.ammunition_required_for_weapon(String(part[1]),sets,count),"training":0.8})
	return sim.create_formation_force(name,formations,1.0,1.0)

func _cohort(force:Dictionary,against:Dictionary,index:int=0)->Dictionary:
	return sim.evaluate_force(force,against,1.0)[index]

func test_the_pierce_curve()->void:
	assert_float(Combat.pierce_factor(4.0,3.0)).is_equal(1.0)
	assert_float(Combat.pierce_factor(1.6,3.0)).is_between(0.15,0.30)
	assert_float(Combat.pierce_factor(0.1,3.8)).is_equal(Combat.PIERCE_FLOOR)
	assert_float(Combat.kit_hardness("service_rifle")).is_equal(0.0)
	assert_float(Combat.kit_hardness("heavy_tank_kit")).is_equal(1.0)
	assert_float(Combat.kit_hardness("mail_spear")).is_between(0.3,0.6)

func test_soft_against_soft_is_unchanged()->void:
	var a:=_force("A",[["rifle_infantry","service_rifle",100]])
	var b:=_force("B",[["rifle_infantry","service_rifle",100]])
	var c:=_cohort(a,b)
	assert_float(float(c.piercing)).is_equal(1.0)
	assert_float(float(c.through)).is_equal(1.0)

func test_rifles_hardly_scratch_heavy_tanks_and_antitank_guns_do()->void:
	var tanks:=_force("Tanks",[["heavy_tank","heavy_tank_kit",50]])
	var rifles:=_force("Rifles",[["rifle_infantry","service_rifle",500]])
	var guns:=_force("Guns",[["anti_tank","anti_tank_kit",60]])
	assert_float(float(_cohort(rifles,tanks).piercing)).is_less(0.3)
	assert_float(float(_cohort(guns,tanks).piercing)).is_greater(0.9)
	# And the tanks' own crews take little of the rifles' fire.
	assert_float(float(_cohort(tanks,rifles).through)).is_less(0.3)
	assert_float(float(_cohort(tanks,guns).through)).is_greater(0.9)

func test_mail_turns_arrows_more_than_crossbow_bolts()->void:
	var mailed:=_force("Mail",[["line_infantry","mail_spear",200]])
	var bows:=_force("Bows",[["archer","bow",200]])
	var crossbows:=_force("Crossbows",[["crossbowman","crossbow",200]])
	var arrows:=float(_cohort(bows,mailed).piercing)
	var bolts:=float(_cohort(crossbows,mailed).piercing)
	assert_float(arrows).is_between(0.4,0.85)
	assert_float(bolts).is_equal(1.0)

func test_a_tank_company_in_an_infantry_army_takes_few_of_the_rifle_losses()->void:
	var mixed:=_force("Mixed",[["rifle_infantry","service_rifle",1000],["armored_formation","armored_vehicle",100]])
	var rifles:=_force("Rifles",[["rifle_infantry","service_rifle",1500]])
	var cohorts:Array=sim.evaluate_force(mixed,rifles,1.0)
	assert_float(float(cohorts[0].through)).is_equal(1.0)
	assert_float(float(cohorts[1].through)).is_less(0.5)
	# The rifles' blows are mostly against soft men, so they barely weaken.
	assert_float(float(_cohort(rifles,mixed).piercing)).is_greater(0.9)

func test_tanks_beat_many_more_riflemen_in_battle()->void:
	var tanks:=_force("Tanks",[["armored_formation","armored_vehicle",150]])
	var rifles:=_force("Rifles",[["rifle_infantry","service_rifle",600]])
	var won:=0
	for seed in [11,23,37,41,53]:
		var result:Dictionary=sim.simulate(tanks,rifles,{"seed":seed})
		if float(result.attacker.casualties)/150.0<float(result.defender.casualties)/600.0: won+=1
	assert_int(won).is_greater_equal(4)

func test_late_kits_fight_at_the_last_ages_pace()->void:
	assert_int(Blocks.weapon_tier("main_battle_tank")).is_equal(5)
	assert_int(Blocks.weapon_tier("combat_frame")).is_equal(5)
	assert_int(Blocks.weapon_tier("musket")).is_equal(3)
	assert_int(Blocks.weapon_tier("spear")).is_equal(0)
