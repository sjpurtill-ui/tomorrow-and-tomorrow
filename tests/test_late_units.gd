extends GdUnitTestSuite
## THE LAST AGE'S UNITS (military_unit_catalog, equipment_ledger,
## combat_simulator): networked infantry, main battle tanks, precision fires,
## drone teams, counter-drone batteries, robotic vehicles, exosuits and combat
## frames, each on real late research. Machines (crew below one) are run by
## operators: a blow mostly destroys machines, operators rarely die, and a
## machine formation cannot fight without its machines.

const Catalog:=preload("res://scripts/military_unit_catalog.gd")
const Ledger:=preload("res://scripts/equipment_ledger.gd")
const Combat:=preload("res://scripts/combat_simulator.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")

const LATE:=["networked_infantry","main_battle_tank","precision_fires","drone_operators","counter_drone_battery","robot_vehicle_company","exosuit_infantry","combat_frame_cohort"]

var sim

func before_test()->void:
	sim=auto_free(Combat.new())

func _years()->Dictionary:
	var years:={}
	for file:String in DirAccess.get_files_at("res://data/research/blocks"):
		if not file.ends_with(".json"): continue
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/research/blocks/"+file))
		for item:Dictionary in (parsed as Dictionary).get("items",[]): years[String(item.id)]=float(item.target_year)
	return years

func _force(parts:Array)->Dictionary:
	var formations:=[]
	for part in parts:
		var men:=int(part[2])
		var sets:int=sim.equipment_required_for_weapon(String(part[1]),men)
		var issued:=sets if part.size()<4 else int(part[3])
		formations.append({"id":formations.size()+1,"unit":String(part[0]),"weapon":String(part[1]),"count":men,"authorized_count":men,"equipment":issued,"equipment_required":sets,"ammunition":sim.ammunition_required_for_weapon(String(part[1]),sets,men),"training":0.9})
	return sim.create_formation_force("Force",formations,1.0,1.0)

func test_each_late_unit_is_whole()->void:
	var years:=_years()
	for unit:String in LATE:
		var row:=Catalog.archetype(unit)
		assert_bool(row.is_empty()).override_failure_message(unit).is_false()
		assert_bool(years.has(String(row.gate))).override_failure_message(unit+" gate").is_true()
		assert_float(float(years[String(row.gate)])).override_failure_message(unit).is_greater(2800.0)
		assert_bool(Combat.UNIT_TYPES.has(unit)).override_failure_message(unit).is_true()
		for kit:String in row.equipment:
			assert_bool(Ledger.has(kit)).override_failure_message(kit).is_true()
			assert_bool(Combat.WEAPONS.has(kit)).override_failure_message(kit).is_true()
		assert_int(int(Blocks.UNIT_TIER.get(unit,-1))).is_equal(5)
		assert_bool(Blocks.DEPLOY_ORDER.has(Blocks.arm_of(unit,String(row.equipment[0])))).override_failure_message(unit).is_true()
	assert_bool(Tactics.ARMOUR.has("main_battle_tank")).is_true()
	assert_bool(Tactics.ARTILLERY.has("precision_fires")).is_true()

func test_a_supervisor_runs_eight_frames_and_fights_with_them()->void:
	assert_int(sim.equipment_required_for_weapon("combat_frame",10)).is_equal(80)
	assert_float(Combat.machines_per_man("combat_frame")).is_equal(8.0)
	assert_bool(Combat.is_machine("drone_team")).is_false()
	var enemy:=_force([["rifle_infantry","service_rifle",100]])
	var armed:=_force([["combat_frame_cohort","combat_frame",10]])
	var bare:=_force([["combat_frame_cohort","combat_frame",10,0]])
	var armed_attack:float=sim.evaluate_force(armed,enemy,1.0)[0].attack
	var bare_attack:float=sim.evaluate_force(bare,enemy,1.0)[0].attack
	assert_float(bare_attack).is_equal(0.0)
	# One frame is worth somewhat more than a networked soldier, not a legion.
	var soldier:=_force([["networked_infantry","networked_rifle",10]])
	var frame_power:=sqrt(armed_attack*float(sim.evaluate_force(armed,enemy,1.0)[0].defense))/8.0
	var soldier_power:=sqrt(float(sim.evaluate_force(soldier,enemy,1.0)[0].attack)*float(sim.evaluate_force(soldier,enemy,1.0)[0].defense))
	assert_float(frame_power/soldier_power).is_between(1.0,3.0)

func test_blows_on_machines_destroy_machines_and_spare_the_operators()->void:
	var frames:=_force([["combat_frame_cohort","combat_frame",40]])
	var rifles:=_force([["rifle_infantry","service_rifle",800]])
	var result:Dictionary=sim.simulate(rifles,frames,{"seed":17})
	var side:Dictionary=result.defender
	var formation:Dictionary=(side.formations as Array)[0] if side.has("formations") else {}
	var men_lost:=int(side.casualties)
	var machines_lost:=320-int(formation.get("equipment",320))
	assert_int(machines_lost).is_greater(0)
	# About one supervisor dies for every hundred and sixty frames lost (5% of
	# each man's worth of loss, eight frames to a man's worth).
	assert_int(men_lost).is_less_equal(maxi(2,machines_lost/40))

func test_drones_hunt_armour_and_counter_drone_batteries_hunt_drones()->void:
	assert_float(float(Combat.MATCHUPS.drone_operators.main_battle_tank)).is_greater(1.0)
	assert_float(float(Combat.MATCHUPS.counter_drone_battery.drone_operators)).is_greater(2.0)
	# Drone warheads strike armour from above: they pierce a main battle tank.
	assert_float(Combat.pierce_factor(float(Ledger.row("drone_team").penetration),float(Ledger.row("main_battle_tank").armor))).is_greater(0.9)

func test_operators_without_machines_are_ordinary_men_and_fall_like_them()->void:
	var enemy:=_force([["rifle_infantry","service_rifle",100]])
	var bare:=_force([["combat_frame_cohort","combat_frame",40,0]])
	var man:=_force([["combat_frame_cohort","combat_frame",40]])
	var bare_def:float=sim.evaluate_force(bare,enemy,1.0)[0].defense
	var full_def:float=sim.evaluate_force(man,enemy,1.0)[0].defense
	# With all eight frames a supervisor is guarded by them; without, he is one man.
	assert_float(full_def/bare_def).is_greater(20.0)
	var result:Dictionary=sim.simulate(_force([["rifle_infantry","service_rifle",400]]),bare,{"seed":5})
	assert_int(int(result.defender.casualties)).is_greater(0)

func test_a_blow_on_a_frame_cohort_is_as_likely_as_its_machines_make_it()->void:
	# Mixed with riflemen, frames take a share of the blows by their machines'
	# number and defense, not an eighth of it.
	var mixed:=_force([["rifle_infantry","service_rifle",320],["combat_frame_cohort","combat_frame",40]])
	var enemy:=_force([["rifle_infantry","service_rifle",1200]])
	var cohorts:Array=sim.evaluate_force(mixed,enemy,1.0)
	var rifle_exposure:=float(cohorts[0].count)/float(cohorts[0].defense)
	var frame_exposure:=float(cohorts[1].count)*float(cohorts[1].per_man)/float(cohorts[1].defense)
	# A blow on the cohort is one supervisor's worth (eight frames): it is picked
	# by the frames' own defense, eight times as often as by the supervisor's
	# whole guarded defense (the double count the review found).
	var old_exposure:=float(cohorts[1].count)/float(cohorts[1].defense)
	assert_float(frame_exposure/old_exposure).is_equal_approx(8.0,0.001)
	assert_float(frame_exposure/rifle_exposure).is_between(0.02,0.2)
