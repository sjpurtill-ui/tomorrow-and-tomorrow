extends GdUnitTestSuite
## The block battle (battle_blocks.gd, combat_simulator.gd): sides gathered
## into era-sized blocks, a frontage set by the ground, reserves that go in
## when the line tires, blocks that break and leave, generals who change
## course between phases, and a progress value that points at the winner.
## It must stay cheap at any size (the micro-benchmarks at the end).

const Sim:=preload("res://scripts/combat_simulator.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")


func _force(sim:CombatSimulator,name:String,parts:Array,morale:=0.8,readiness:=0.8)->Dictionary:
	var formations:Array=[]
	for part in parts:
		formations.append({"unit":String(part[0]),"weapon":String(part[1]),"count":int(part[2]),"equipment":int(part[2]),"training":0.7})
	var force:=sim.create_formation_force(name,formations,morale,readiness)
	force["commander"]=sim.create_commander(name+" general",0.6,0.6,0.5,0.6)
	return force


func _count(state:Dictionary,side:String,st:String)->int:
	var n:=0
	for block in state.live[side]:
		if String(block.st)==st: n+=1
	return n


# --- Blocks --------------------------------------------------------------------------

func test_blocks_are_era_sized_and_bounded()->void:
	var sim:=Sim.new()
	# A hearth band: bands of about thirty.
	var band:=Blocks.build_side(_force(sim,"Band",[["levy","improvised",120]]),"a",0)
	assert_str(String(band.word)).is_equal("band")
	assert_int(int(band.size)).is_equal(30)
	assert_int((band.blocks as Array).size()).is_equal(4)
	# A handful is one block.
	assert_int((Blocks.build_side(_force(sim,"Two",[["levy","improvised",2]]),"d",0).blocks as Array).size()).is_equal(1)
	# Bronze spears: still bands, and the arm is kept.
	var bronze:=Blocks.build_side(_force(sim,"Spears",[["spearman","spear",1500],["archer","bow",400]]),"a",1)
	for block in bronze.blocks: assert_array(["spear","bow"]).contains([String(block.arm)])
	assert_int((bronze.blocks as Array).size()).is_less_equal(Blocks.MAX_BLOCKS+2)
	# A great host of the rifle age: regiments, never more than about 24 a side.
	var rifles:=_force(sim,"Host",[["rifle_infantry","service_rifle",40000],["machine_gun_company","machine_gun",2000],["field_artillery","field_gun",1500]])
	var tier:=Blocks.tier_of(rifles)
	assert_int(tier).is_equal(4)
	var host:=Blocks.build_side(rifles,"a",tier)
	assert_int((host.blocks as Array).size()).is_less_equal(Blocks.MAX_BLOCKS+2)
	assert_str(String(host.word)).is_equal("regiment")
	var men:=0
	for block in host.blocks: men+=int(block.men0)
	assert_int(men).is_equal(43500)
	# Two hundred thousand: divisions, still bounded.
	var huge:=Blocks.build_side(_force(sim,"Huge",[["mechanized_infantry","mechanized_kit",150000],["light_tank","light_tank_kit",50000]]),"a",5)
	assert_int((huge.blocks as Array).size()).is_less_equal(Blocks.MAX_BLOCKS+2)
	assert_str(String(huge.word)).is_equal("division")


func test_arms_read_from_unit_and_weapon()->void:
	assert_str(Blocks.arm_of("levy","improvised")).is_equal("club")
	assert_str(Blocks.arm_of("line_infantry","spear")).is_equal("spear")
	assert_str(Blocks.arm_of("line_infantry","musket")).is_equal("musket")
	assert_str(Blocks.arm_of("slinger","sling")).is_equal("sling")
	assert_str(Blocks.arm_of("cavalry","lance")).is_equal("horse")
	assert_str(Blocks.arm_of("pikeman","pike")).is_equal("pike")
	assert_str(Blocks.arm_of("rifle_infantry","service_rifle")).is_equal("rifle")
	assert_str(Blocks.arm_of("field_artillery","field_gun")).is_equal("guns")
	assert_str(Blocks.arm_of("light_tank","light_tank_kit")).is_equal("armour")


# --- Frontage --------------------------------------------------------------------------

func test_frontage_by_terrain_limits_how_many_blocks_fight()->void:
	var sim:=Sim.new()
	var a:=_force(sim,"A",[["spearman","spear",20000]])
	var d:=_force(sim,"D",[["spearman","spear",20000]])
	var fronts:={}
	for kind in ["open","forest","ford","bridge"]:
		var state:=Blocks.begin(a,d,{"ground":{"kind":kind}})
		fronts[kind]=_count(state,"attacker","front")
		assert_int(fronts[kind]).override_failure_message(kind).is_greater_equal(1)
	assert_int(int(fronts.open)).is_greater(int(fronts.forest))
	assert_int(int(fronts.forest)).is_greater(int(fronts.ford))
	assert_int(int(fronts.ford)).is_greater_equal(int(fronts.bridge))
	# A small fight on open ground puts everyone in the line: the old fight exactly.
	var small:=Blocks.begin(_force(sim,"A",[["levy","improvised",120]]),_force(sim,"D",[["levy","improvised",90]]),{})
	assert_int(_count(small,"attacker","reserve")).is_equal(0)
	assert_bool(Blocks.limited(small)).is_false()
	# At walls only the gate or the breach can be fought over.
	var gate:=Blocks.begin(a,d,{"ground":{"kind":"gate"}})
	assert_int(Blocks.front_men(gate,"attacker")).is_less(Blocks.front_men(Blocks.begin(a,d,{"ground":{"kind":"breach"}}),"attacker")+1)
	# A flank attack widens the front both sides must hold.
	var straight:=Blocks.capacity(2,Blocks.ground_of({"ground":{"kind":"open"}}),0)
	var flanked:=Blocks.capacity(2,Blocks.ground_of({"ground":{"kind":"open"}}),1)
	assert_int(flanked).is_greater(straight)
	assert_int(Blocks.capacity(2,Blocks.ground_of({"ground":{"kind":"ford"}}),2)).is_equal(Blocks.capacity(2,Blocks.ground_of({"ground":{"kind":"ford"}}),0))


func test_narrow_ground_holds_off_numbers_for_a_while()->void:
	## Three to one at a ford: the few are not overrun at the first blow,
	## because only as many as the ford allows can reach them.
	var sim:=Sim.new()
	var many:=_force(sim,"Many",[["spearman","spear",9000]])
	var few:=_force(sim,"Few",[["spearman","spear",3000]])
	assert_str(sim.overrun_expected(many,few,1.0,{"kind":"ford"})).is_equal("")
	var result:=sim.simulate(many,few,{"seed":5,"ground":{"kind":"ford"},"max_rounds":6})
	assert_bool(bool(result.get("overrun",false))).is_false()
	assert_int(int(result.round_count)).is_greater(1)


# --- Reserves and breaking -----------------------------------------------------------------

func test_reserves_rotate_in_and_worn_blocks_come_out()->void:
	var sim:=Sim.new()
	var a:=_force(sim,"A",[["heavy_swordsman","sword_shield",30000]])
	var d:=_force(sim,"D",[["heavy_swordsman","sword_shield",30000]])
	var state:=Blocks.begin(a,d,{"ground":{"kind":"rough"}})
	assert_int(_count(state,"attacker","reserve")).is_greater(0)
	var front:Array=[]
	for index in (state.live.attacker as Array).size():
		if String(state.live.attacker[index].st)=="front": front.append(index)
	# Wear the first front block out: it comes out, a fresh block goes in.
	var worn:int=front[0]
	state.live.attacker[worn].cond=0.2
	var events:=Blocks.deploy(state,{})
	assert_str(String(state.live.attacker[worn].st)).is_equal("reserve")
	assert_int(_count(state,"attacker","front")).is_equal(front.size())
	assert_array(events).is_not_empty()
	assert_str(String(events[0].k)).is_equal("reserve_in")
	# Over a long fight the reserve is used: some blocks that started waiting fight.
	var result:=sim.simulate(a,d,{"seed":17,"ground":{"kind":"rough"},"max_rounds":24})
	var battle:Dictionary=result.battle
	var reserve_in:=0
	for event in battle.events:
		if String(event.k)=="reserve_in": reserve_in+=1
	assert_int(reserve_in).is_greater(0)
	assert_array(battle.phases).is_not_empty()


func test_a_worn_out_block_breaks_and_its_men_are_split()->void:
	var sim:=Sim.new()
	var a:=_force(sim,"A",[["spearman","spear",3000]])
	var d:=_force(sim,"D",[["spearman","spear",3000]])
	var state:=Blocks.begin(a,d,{})
	# Heart is the army's times the block's own condition.
	state.live.defender[0].cond=0.1
	var breaking:=Blocks.wear(state,"defender",{},0.0,0.5,0.8,false)
	assert_array(breaking).contains([0])
	var men:=int(state.live.defender[0].men)
	var rng:=RandomNumberGenerator.new(); rng.seed=3
	var split:=Blocks.break_block(state,"defender",0,rng,true,5)
	assert_int(int(split.killed)+int(split.wounded)+int(split.fled)+int(split.captured)).is_equal(men)
	assert_int(int(split.captured)).is_greater(0)
	assert_int(int(split.fled)).is_greater(int(split.killed))
	assert_str(String(state.live.defender[0].st)).is_equal("broken")
	assert_int(int(state.live.defender[0].men)).is_equal(0)
	var told:=false
	for event in state.events:
		if String(event.k)=="broke": told=true
	assert_bool(told).is_true()
	# Fresh blocks keep pace with the army when everyone fights: nobody breaks early.
	var calm:=Blocks.begin(a,d,{})
	assert_array(Blocks.wear(calm,"defender",{0:5},5.0/3000.0,0.5,0.8,false)).is_empty()


func test_broken_blocks_leave_and_every_man_is_accounted_for()->void:
	## Three to one at a ford, the many with riders: the few's worn blocks
	## break while their army still holds, and riders take some who run.
	var sim:=Sim.new()
	var found:=false
	for seed in 40:
		var a:=_force(sim,"A",[["spearman","spear",7000],["cavalry","lance",2000]])
		var d:=_force(sim,"D",[["spearman","spear",3000]])
		var result:=sim.simulate(a,d,{"seed":seed,"ground":{"kind":"ford"}})
		var battle:Dictionary=result.battle
		var broke:=0
		for event in battle.events:
			if String(event.k)=="broke": broke+=1
		for side in ["attacker","defender"]:
			for block in battle.live[side]:
				if String(block.st)=="broken": assert_int(int(block.men)).is_equal(0)
			var r:Dictionary=result[side]
			var losses:=0
			var kinds:=0
			var captured:=0
			for round in result.rounds:
				losses+=int(round.get(side+"_losses",0))
				var c:Dictionary=round.get(side+"_casualties",{})
				kinds+=int(c.get("killed",0))+int(c.get("wounded",0))+int(c.get("scattered",0))+int(c.get("captured",0))
				captured+=int(c.get("captured",0))
			assert_int(int(r.initial_troops)).is_equal(int(r.remaining_troops)+int(r.casualties))
			assert_int(losses).is_equal(int(r.casualties))
			assert_int(kinds).is_equal(losses)
			assert_int(int(r.captured_in_battle)).is_equal(captured)
		if broke>0 and int(result.defender.captured_in_battle)>0: found=true
	assert_bool(found).is_true()


# --- Tactics and phases ------------------------------------------------------------------

func test_countered_tactics_are_recorded_and_blunted()->void:
	var shield:={"attacker":{"id":"flank_attack","profile":{},"pursuit":false},"defender":{"id":"shield_wall","profile":{},"pursuit":false}}
	var fx:=Tactics.round_effects(shield,3,0.5,0.8,0.8)
	assert_bool(bool(fx.defender_countered)).is_true()
	assert_bool(bool(fx.attacker_countered)).is_false()
	# The shield wall no longer shields: its side is more exposed than behind a wall that holds.
	var holding:=Tactics.round_effects({"attacker":{"id":"head_on","profile":{}},"defender":{"id":"shield_wall","profile":{}}},3,0.5,0.8,0.8)
	assert_float(float(fx.defender)).is_greater(float(holding.defender))
	# The battle record says so, phase by phase.
	var sim:=Sim.new()
	var a:=_force(sim,"A",[["spearman","spear",2000],["cavalry","lance",500]])
	var d:=_force(sim,"D",[["spearman","spear",2400]])
	var result:=sim.simulate(a,d,{"seed":8,"max_rounds":8,"tactics":shield})
	var phase:Dictionary=result.battle.phases[0]
	assert_bool(bool(phase.tactics.defender.countered)).is_true()
	var told:=false
	for event in result.battle.events:
		if String(event.k)=="countered" and String(event.side)=="defender": told=true
	assert_bool(told).is_true()


func test_generals_change_course_between_phases_within_what_they_can_do()->void:
	var plan:={"attacker":{"id":"shield_wall","profile":{"tactics":0.9},"options":["head_on","shield_wall","flank_attack","reserve"],"since":0},
		"defender":{"id":"flank_attack","profile":{"tactics":0.5},"options":["head_on","flank_attack"],"since":0}}
	var changed:=0
	for seed in 40:
		var second:=Tactics.rechoose(plan,{"progress":-0.2,"exchange":4},seed)
		var new_plan:Dictionary=second.plan
		assert_array(plan.attacker.options).contains([String(new_plan.attacker.id)])
		if (second.changes as Dictionary).has("attacker"):
			changed+=1
			assert_int(int(new_plan.attacker.since)).is_equal(4)
			# A countered shield wall is dropped, never for something else the enemy counters.
			assert_bool(Tactics.countered(String(new_plan.attacker.id),"flank_attack")).is_false()
	assert_int(changed).is_greater(10)
	# Without choices (an old plan) nothing changes.
	assert_dict(Tactics.rechoose({"attacker":{"id":"head_on"},"defender":{"id":"head_on"}},{},1).changes).is_empty()


func test_phases_group_exchanges_by_age()->void:
	var sim:=Sim.new()
	var early:=sim.simulate(_force(sim,"A",[["levy","improvised",300]]),_force(sim,"D",[["levy","improvised",280]]),{"seed":3,"max_rounds":12})
	assert_int(int(early.battle.phase_len)).is_equal(4)
	for phase in early.battle.phases:
		assert_int(int(phase.to)-int(phase.from)+1).is_less_equal(4)
		assert_dict(phase.snap).contains_keys(["attacker","defender"])
	var modern:=Blocks.begin(_force(sim,"A",[["mechanized_infantry","mechanized_kit",20000]]),_force(sim,"D",[["rifle_infantry","service_rifle",20000]]),{})
	assert_int(int(modern.phase_len)).is_equal(8)


# --- Progress and why ------------------------------------------------------------------------

func test_progress_points_at_the_winner_in_clear_cases()->void:
	var sim:=Sim.new()
	for seed in 6:
		var strong:=_force(sim,"Strong",[["heavy_swordsman","sword_shield",3000]],0.9,0.9)
		var weak:=_force(sim,"Weak",[["levy","improvised",2400]],0.6,0.5)
		var result:=sim.simulate(strong,weak,{"seed":100+seed,"max_rounds":2})
		assert_float(float(result.battle.progress)).override_failure_message("seed %d" % seed).is_greater(0.2)
		var reversed:=sim.simulate(weak,strong,{"seed":100+seed,"max_rounds":2})
		assert_float(float(reversed.battle.progress)).is_less(-0.2)
		assert_float(float((reversed.rounds[0] as Dictionary).progress)).is_less(0.0)
	# At the end the winner's side is at the full mark.
	var won:=sim.simulate(_force(sim,"Strong",[["heavy_swordsman","sword_shield",3000]],0.9,0.9),_force(sim,"Weak",[["levy","improvised",2400]],0.6,0.5),{"seed":4})
	if String(won.outcome)=="attacker_victory": assert_float(float(won.battle.progress)).is_equal(1.0)


func test_why_lists_the_modifiers_used_in_the_maths()->void:
	var sim:=Sim.new()
	var a:=_force(sim,"A",[["spearman","spear",6000]])
	var d:=_force(sim,"D",[["spearman","spear",3000]])
	var result:=sim.simulate(a,d,{"seed":2,"max_rounds":4,"terrain_defense":1.3,"ground":{"kind":"ford"}})
	var keys:Array=[]
	for item in result.battle.phases[0].why: keys.append(String(item.k))
	assert_array(keys).contains(["numbers","ground","river"])
	for item in result.battle.phases[0].why:
		if String(item.k)=="numbers": assert_float(float(item.v)).is_greater(0.0)
		if String(item.k)=="river": assert_float(float(item.v)).is_less(0.0)
		if String(item.k)=="ground": assert_float(float(item.v)).is_less(0.0)


func test_a_small_fight_is_unchanged_in_shape()->void:
	## Everyone in the line: power and losses as before the blocks.
	var sim:=Sim.new()
	var a:=_force(sim,"A",[["levy","improvised",60]])
	var d:=_force(sim,"D",[["levy","improvised",55]])
	var state:=Blocks.begin(a,d,{})
	var w:=Blocks.weights(state,"attacker",1,float(a.morale))
	assert_float(float(w[0])).is_equal_approx(1.0,0.0001)
	assert_int(Blocks.front_men(state,"attacker")).is_equal(60)


# --- Size and speed ---------------------------------------------------------------------------

func _modern_host(sim:CombatSimulator,name:String,total:int)->Dictionary:
	var parts:=[["rifle_infantry","service_rifle",0.55],["machine_gun_company","machine_gun",0.08],["field_artillery","field_gun",0.07],["light_tank","light_tank_kit",0.1],["mechanized_infantry","mechanized_kit",0.2]]
	var formations:Array=[]
	for part in parts:
		for split in 3:
			var n:=int(float(total)*float(part[2])/3.0)
			formations.append({"unit":String(part[0]),"weapon":String(part[1]),"count":n,"equipment":n,"training":0.7})
	var force:=sim.create_formation_force(name,formations,0.85,0.85)
	force["commander"]=sim.create_commander(name,0.6,0.6,0.5,0.6)
	return force


func test_fifty_thousand_a_side_fights_a_day_within_a_frame()->void:
	var sim:=Sim.new()
	var a:=_modern_host(sim,"North",50000)
	var d:=_modern_host(sim,"South",50000)
	# One day of fighting is one phase: eight exchanges in this age.
	var start:=Time.get_ticks_usec()
	var result:=sim.simulate(a,d,{"seed":77,"max_rounds":8})
	var used:=float(Time.get_ticks_usec()-start)/1000.0
	print("BENCH 50k v 50k, 8 exchanges: %.2f ms" % used)
	assert_int(int(result.round_count)).is_greater(0)
	assert_float(used).is_less(16.0)
	# A whole day and night of exchanges one at a time, as the campaign does.
	var battle:Dictionary={}
	var total:=0.0
	for exchange in 16:
		var t0:=Time.get_ticks_usec()
		var one:=sim.simulate(a,d,{"seed":77+exchange,"max_rounds":1,"battle":battle,"round_offset":exchange})
		total+=float(Time.get_ticks_usec()-t0)/1000.0
		if (one.rounds as Array).is_empty(): break
		battle=one.battle
		a=one.attacker.duplicate(true); a["troops"]=int(one.attacker.remaining_troops)
		d=one.defender.duplicate(true); d["troops"]=int(one.defender.remaining_troops)
	print("BENCH 50k v 50k, 16 single exchanges: %.2f ms" % total)
	assert_float(total/16.0).is_less(4.0)


func test_twenty_battles_tick_a_day_quickly()->void:
	var sim:=Sim.new()
	var forces:Array=[]
	for i in 20:
		forces.append([_force(sim,"A%d" % i,[["spearman","spear",1500+i*300],["archer","bow",400]]),_force(sim,"D%d" % i,[["spearman","spear",1400+i*250],["cavalry","lance",300]])])
	var start:=Time.get_ticks_usec()
	for i in 20:
		sim.simulate(forces[i][0],forces[i][1],{"seed":i,"max_rounds":4})
	var used:=float(Time.get_ticks_usec()-start)/1000.0
	print("BENCH 20 battles, one day each: %.2f ms" % used)
	assert_float(used).is_less(120.0)
