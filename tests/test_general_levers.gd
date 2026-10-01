extends GdUnitTestSuite
## GENERALS TURN THE STANCE INTO RESULTS (historical_figures.gd skills,
## leader_commands.gd, combat_simulator.command_factor, field_sustainment.gd,
## military_campaign._field_army_speed, general_record.gd): every general has
## command, tactics, logistics and resolve of their own; command sets battle
## power (x0.85 to x1.15), logistics the march pace (x0.9 to x1.1) and what
## hunger costs (x1.2 to x0.8), command and resolve how many desert under
## hardship; each general keeps a record of battles, men lost, the march,
## hunger and deserters; skills and record survive a save.

const Commands:=preload("res://scripts/leader_commands.gd")
const GeneralRecord:=preload("res://scripts/general_record.gd")
const Sustainment:=preload("res://scripts/field_sustainment.gd")
const Combat:=preload("res://scripts/combat_simulator.gd")


func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(5151);MilitaryCampaign.reset_for_new_world()
	HistoricalFigures.reset_for_new_world()
	GameState.settlement_site_committed=true;GameState.settlement_founded_at=Vector3.ZERO
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()


func after_test()->void:
	WorldSimulation.clear()
	HistoricalFigures.reset_for_new_world()


func _formation(id:int,unit:String,weapon:String,count:int)->Dictionary:
	var sets:int=MilitaryCampaign.simulator.equipment_required_for_weapon(weapon,count)
	return {"id":id,"unit":unit,"weapon":weapon,"count":count,"authorized_count":count,"equipment":sets,"equipment_required":sets,"ammunition":0,"ammunition_required":0,"training":0.5,"experience":0.2,"personnel_condition":1.0}


func _band(id:int,count:int,commander:Dictionary)->Dictionary:
	var force:Dictionary=MilitaryCampaign.simulator.create_formation_force("Band %d" % id,[_formation(1,"spearman","spear",count)],1.0,1.0)
	force.merge({"army_id":id,"status":"stationed","location_id":"field","position":{"x":40.0,"z":0.0},"supply_level":1.0,"commander":commander},true)
	return force


func _general()->Dictionary:
	HistoricalFigures.ensure()
	for p:Dictionary in HistoricalFigures.people:
		if String(p.role)=="General" and String(p.status)=="living": return p
	return {}


func test_every_general_has_skills_of_their_own_with_a_strength_and_a_weakness()->void:
	HistoricalFigures.ensure()
	var general:=_general()
	assert_bool(general.is_empty()).is_false()
	var skills:Dictionary=HistoricalFigures.skills_of(general)
	assert_int(skills.size()).is_equal(4)
	var top:=0.0; var low:=1.0
	for key in HistoricalFigures.COMMAND_SKILLS:
		assert_float(float(skills[key])).is_between(HistoricalFigures.SKILL_MIN,HistoricalFigures.SKILL_MAX)
		top=maxf(top,float(skills[key])); low=minf(low,float(skills[key]))
	assert_float(top).is_greater_equal(0.66)
	assert_float(low).is_less_equal(0.38)
	# Drawn from the figure's own seed: the same world draws the same general.
	var again:=skills.duplicate()
	general.erase("skills")
	assert_dict(HistoricalFigures.skills_of(general)).is_equal(again)
	# Other figures command nothing.
	for p:Dictionary in HistoricalFigures.people:
		if not String(p.role) in HistoricalFigures.COMMAND_ROLES: assert_bool(HistoricalFigures.skills_of(p).is_empty()).is_true()


func test_a_generals_skills_reach_the_band_and_the_leaders_screen_alike()->void:
	var general:=_general()
	var base:Dictionary=MilitaryCampaign._acting_field_commander(false)
	HistoricalFigures.assignments["army_7"]=String(general.id)
	var on_band:=HistoricalFigures.commander(base,"army_7")
	HistoricalFigures.assignments.erase("army_7")
	var on_screen:=Commands._commander_of(MilitaryCampaign,String(general.id))
	for key in HistoricalFigures.COMMAND_SKILLS:
		assert_float(float(on_screen[key])).is_equal_approx(float(on_band[key]),0.0001)
		var own:=float(HistoricalFigures.skills_of(general)[key])
		# Mostly their own: three quarters, the army's quarter and patronage aside.
		assert_float(float(on_band[key])).is_equal_approx(own*0.75+float(base.get(key,0.5))*0.25+(HistoricalFigures.multiplier("security")-1.0)*0.1,0.0001)


func test_command_moves_battle_power_from_x085_to_x115()->void:
	assert_float(Combat.command_factor(0.0)).is_equal_approx(0.85,0.0001)
	assert_float(Combat.command_factor(0.5)).is_equal_approx(1.0,0.0001)
	assert_float(Combat.command_factor(1.0)).is_equal_approx(1.15,0.0001)
	var strong:=_band(1,200,{"command":0.85,"tactics":0.5,"logistics":0.5,"resolve":0.5})
	var weak:=_band(2,200,{"command":0.25,"tactics":0.5,"logistics":0.5,"resolve":0.5})
	var a:=float(MilitaryCampaign.combat_summary(strong,weak).effective_strength)
	var b:=float(MilitaryCampaign.combat_summary(weak,strong).effective_strength)
	assert_float(a/b).is_equal_approx(Combat.command_factor(0.85)/Combat.command_factor(0.25),0.0001)


func test_logistics_sets_the_march_pace_and_what_hunger_costs()->void:
	var good:=_band(1,300,{"command":0.5,"tactics":0.5,"logistics":0.85,"resolve":0.5})
	var poor:=_band(2,300,{"command":0.5,"tactics":0.5,"logistics":0.25,"resolve":0.5})
	var fast:=float(MilitaryCampaign._field_army_speed(good))
	var slow:=float(MilitaryCampaign._field_army_speed(poor))
	assert_float(fast).is_greater(slow)
	# The general's staff term alone is (0.9+0.2*0.85)/(0.9+0.2*0.25); the
	# older blended logistics term adds a little more.
	assert_float(fast/slow).is_greater_equal((0.9+0.2*0.85)/(0.9+0.2*0.25)-0.0001)
	assert_float(Sustainment.hunger_factor(good)).is_equal_approx(1.2-0.4*0.85,0.0001)
	assert_float(Sustainment.hunger_factor(_band(3,300,{}))).is_equal_approx(1.0,0.0001)
	var lost_good:=0; var lost_poor:=0
	for force in [good,poor]:
		force["provision_ratio"]=0.0;force["hungry_days"]=5.0
	for day in 30:
		var g:Dictionary=MilitaryCampaign.sustainment.hunger_day(good,1.0)
		var p:Dictionary=MilitaryCampaign.sustainment.hunger_day(poor,1.0)
		lost_good+=int(g.sick)+int(g.deserted)+int(g.dead)
		lost_poor+=int(p.sick)+int(p.deserted)+int(p.dead)
	assert_float(float(lost_good)/float(lost_poor)).is_between(0.65,0.85)


func test_a_well_led_band_holds_together_under_hardship_and_deserters_are_counted()->void:
	var general:=_general()
	var steady:=_band(1,400,{"command":0.85,"tactics":0.5,"logistics":0.5,"resolve":0.85,"figure_id":String(general.id)})
	var shaky:=_band(2,400,{"command":0.25,"tactics":0.5,"logistics":0.5,"resolve":0.25})
	for force in [steady,shaky]:
		force["supply_level"]=0.2;force["morale"]=0.25;force["status"]="moving"
	var gone:={1:0,2:0}
	for day in 60:
		gone[1]=int(gone[1])+int(MilitaryCampaign.sustainment.desertion_day(steady,1.0).deserted)
		gone[2]=int(gone[2])+int(MilitaryCampaign.sustainment.desertion_day(shaky,1.0).deserted)
	assert_int(int(gone[2])).is_greater(0)
	assert_int(int(gone[1])).is_less(int(gone[2]))
	# Every man is accounted for: on the band and, for a named general, on their record.
	assert_int(int(steady.troops)+int(gone[1])).is_equal(400)
	assert_int(int(shaky.troops)+int(gone[2])).is_equal(400)
	assert_int(int(steady.get("desertions_total",0))).is_equal(int(gone[1]))
	assert_float(float((general.record as Dictionary).get("deserted",0.0))).is_equal(float(gone[1]))
	# A fed, heartened band does not slip away.
	var fed:=_band(3,400,{"command":0.25,"resolve":0.25})
	for day in 60: MilitaryCampaign.sustainment.desertion_day(fed,1.0)
	assert_int(int(fed.troops)).is_equal(400)


func test_each_general_keeps_a_record_of_battles_the_march_and_hunger()->void:
	var general:=_general()
	var id:=String(general.id)
	var before:Dictionary=HistoricalFigures.skills_of(general).duplicate()
	HistoricalFigures.record_battle({"seed":7,"round_count":3,"outcome":"attacker_victory","termination":{"defeated":"Their Band"},
		"attacker":{"name":"Band 1","casualties":12,"remaining_troops":188,"commander":{"figure_id":id}},
		"defender":{"name":"Their Band","casualties":40,"remaining_troops":60,"commander":{}}})
	# A second report of the same battle is not counted twice.
	HistoricalFigures.record_battle({"seed":7,"round_count":3,"outcome":"attacker_victory","termination":{"defeated":"Their Band"},
		"attacker":{"name":"Band 1","casualties":12,"remaining_troops":188,"commander":{"figure_id":id}},"defender":{"name":"Their Band","casualties":40}})
	for day in 100: HistoricalFigures.note_field_day(id,1.0,day<50,18.0,day>=90)
	var leader:={"person":general}
	var record:=Commands.record(leader)
	assert_int(int(record.won)).is_equal(1)
	assert_int(int(record.men_lost)).is_equal(12)
	assert_int(int(record.enemy_lost)).is_equal(40)
	assert_float(float(record.km_day)).is_equal_approx(18.0,0.001)
	assert_int(int(record.hungry_days)).is_equal(10)
	assert_int(int(record.field_days)).is_equal(100)
	var words:=GeneralRecord.words(record)
	assert_str(words).contains("Fought 1 · won 1 · lost 0")
	assert_str(words).contains("12 of ours lost for 40 of theirs")
	assert_str(words).contains("18 km a day on the march")
	assert_str(words).contains("10 hungry days")
	# They grew: a battle's lessons, and a season in the field.
	var after:Dictionary=HistoricalFigures.skills_of(general)
	assert_float(float(after.command)).is_equal_approx(minf(HistoricalFigures.GROWTH_CAP,maxf(float(before.command),float(before.command)+HistoricalFigures.GROWTH_PER_BATTLE)),0.0001)
	assert_float(float(after.logistics)).is_greater_equal(float(before.logistics))
	# What they change, in words with numbers and no character labels.
	var line:=GeneralRecord.lever_line({"command":0.8,"tactics":0.5,"logistics":0.85,"resolve":0.85},String(general.name))
	assert_str(line).contains("fight 9% harder")
	assert_str(line).contains("march 7% faster")
	assert_str(line).contains("fewer men to hunger")
	assert_str(line).not_contains(String(general.temperament))


func test_skills_and_record_survive_a_save_and_old_saves_draw_the_same_skills()->void:
	var general:=_general()
	HistoricalFigures.note_record(String(general.id),"men_lost",5.0)
	var saved:=HistoricalFigures.export_state()
	var skills:Dictionary=(general.skills as Dictionary).duplicate()
	HistoricalFigures.reset_for_new_world()
	assert_bool(HistoricalFigures.import_state(saved).has("ok")).is_true()
	var back:=HistoricalFigures.by_id(String(general.id))
	assert_dict(back.skills as Dictionary).is_equal(skills)
	assert_float(float((back.record as Dictionary).men_lost)).is_equal(5.0)
	# A save from before generals had skills draws them, the same ones.
	var old:Dictionary=saved.duplicate(true)
	for p:Dictionary in old.people:
		p.erase("skills"); p.erase("record")
	HistoricalFigures.reset_for_new_world()
	assert_bool(HistoricalFigures.import_state(old).has("ok")).is_true()
	assert_dict(HistoricalFigures.by_id(String(general.id)).skills as Dictionary).is_equal(skills)
	# Nonsense is refused.
	var bad:Dictionary=saved.duplicate(true)
	for p:Dictionary in bad.people:
		if String(p.id)==String(general.id): p["skills"]={"command":4.0,"tactics":0.5,"logistics":0.5,"resolve":0.5}
	assert_bool(HistoricalFigures.import_state(bad).has("error")).is_true()
	var worse:Dictionary=saved.duplicate(true)
	for p:Dictionary in worse.people:
		if String(p.id)==String(general.id): p["record"]={"men_lost":-3}
	assert_bool(HistoricalFigures.import_state(worse).has("error")).is_true()


func test_a_bands_old_record_is_drawn_again_from_its_generals_own_skills()->void:
	# A save from before generals had skills of their own: every band's record
	# was the realm's acting staff with a little talent, all much alike.
	var general:=_general()
	var stale:={"name":String(general.name),"figure_id":String(general.id),"command":0.86,"tactics":0.84,"logistics":0.85,"resolve":0.88}
	MilitaryCampaign.field_armies.append(_band(4,300,stale))
	var leaders:=Commands.leaders(MilitaryCampaign)
	var record:Dictionary=(MilitaryCampaign.field_armies.back() as Dictionary).commander
	assert_dict(record.own_skills as Dictionary).is_equal(HistoricalFigures.skills_of(general))
	var fresh:=HistoricalFigures.commander_record(general,MilitaryCampaign._acting_field_commander(false))
	var top:=0.0; var low:=1.0
	for key in HistoricalFigures.COMMAND_SKILLS:
		assert_float(float(record[key])).is_equal_approx(float(fresh[key]),0.0001)
		top=maxf(top,float(record[key])); low=minf(low,float(record[key]))
	# A clear strength and a clear weakness: at least a pip apart in five.
	assert_float(top-low).is_greater_equal(0.2)
	# The screens read the same record the engine fights with.
	for leader:Dictionary in leaders:
		if String(leader.id)==String(general.id): assert_float(float((leader.commander as Dictionary).command)).is_equal_approx(float(record.command),0.0001)
	# Drawn once: a second reading changes nothing; growth draws it again.
	assert_int(Commands.sync_commanders(MilitaryCampaign)).is_equal(0)
	HistoricalFigures._grow(general,["command"],0.05,"grown_battles",1)
	# Every force they lead (this band, and the band at home if they hold it).
	assert_int(Commands.sync_commanders(MilitaryCampaign)).is_greater_equal(1)
	assert_dict((MilitaryCampaign.field_armies.back() as Dictionary).commander.own_skills as Dictionary).is_equal(HistoricalFigures.skills_of(general))
	MilitaryCampaign.field_armies.clear()


func test_generals_differ_from_one_another()->void:
	HistoricalFigures.ensure()
	var profiles:Array=[]
	for p:Dictionary in HistoricalFigures.people:
		if String(p.role)=="General": profiles.append(HistoricalFigures.skills_of(p))
	while profiles.size()<4:
		var made:=HistoricalFigures._create("General",int(GameState.elapsed_days))
		if made.is_empty(): break
		profiles.append(HistoricalFigures.skills_of(made))
	assert_int(profiles.size()).is_greater_equal(2)
	# Not one copied profile: each general's strongest skill or its size differs.
	var seen:={}
	for skills:Dictionary in profiles:
		var best:=""
		for key in skills:
			if best=="" or float(skills[key])>float(skills[best]): best=String(key)
		seen["%s:%d" % [best,roundi(float(skills[best])*20.0)]]=true
	assert_int(seen.size()).is_greater(1)


func test_the_war_screen_can_shortlist_and_commission_generals()->void:
	HistoricalFigures.ensure()
	# The first general may already lead the band at home; two more come forward.
	for n in 2: HistoricalFigures._create("General",int(GameState.elapsed_days))
	var free:=Commands.shortlist_generals(MilitaryCampaign,300.0,5)
	assert_bool(free.is_empty()).is_false()
	for i in range(1,free.size()): assert_float(float(free[i-1].levers.fight)).is_greater_equal(float(free[i].levers.fight))
	for row:Dictionary in free:
		assert_str(String(row.line)).contains("than under an ordinary general")
		assert_str(String(row.record)).is_not_empty()
	# A general leading a band is not free.
	var first:Dictionary=free[0]
	MilitaryCampaign.field_armies.append(_band(9,200,HistoricalFigures.commander_record(HistoricalFigures.by_id(String(first.figure_id)),MilitaryCampaign._acting_field_commander(false))))
	for row:Dictionary in Commands.shortlist_generals(MilitaryCampaign,300.0,5): assert_str(String(row.figure_id)).is_not_equal(String(first.figure_id))
	# Commissioning names a free general first, and brings one forward only when none is free.
	var named:=Commands.commission_general(MilitaryCampaign)
	assert_bool(bool(named.ok)).is_true()
	assert_bool(bool(named.new)).is_false()
	MilitaryCampaign.field_armies.clear()


func test_the_war_leaders_facts_carry_each_generals_record_and_hand()->void:
	HistoricalFigures.ensure()
	HistoricalFigures._create("General",int(GameState.elapsed_days))
	var facts:=preload("res://scripts/court_facts.gd")
	var said:Array=facts.generals()
	assert_bool(said.is_empty()).is_false()
	for line:String in said:
		assert_bool(line.contains("Fought") or line.contains("Has not led a fight yet")).override_failure_message(line).is_true()
		assert_str(line).contains("than under an ordinary general")
