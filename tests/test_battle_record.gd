extends GdUnitTestSuite
## Reading a battle (battle_record.gd): any record, new or old, opens as the
## battle view's sides, block plates, phases, events and reasons, and viewing
## it never fights it again.

const Sim:=preload("res://scripts/combat_simulator.gd")
const Record:=preload("res://scripts/battle_record.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")

const JARGON:=["attacker_victory","defender_victory","_","%s","null","cohort","exposure","morale","NaN"]


func _force(sim:CombatSimulator,name:String,parts:Array,morale:=0.8)->Dictionary:
	var formations:Array=[]
	for part in parts:
		formations.append({"unit":String(part[0]),"weapon":String(part[1]),"count":int(part[2]),"equipment":int(part[2]),"training":0.7})
	var force:=sim.create_formation_force(name,formations,morale,0.8)
	force["commander"]=sim.create_commander(name+" general",0.7,0.7,0.5,0.7)
	return force


func _record(seed:int=11)->Dictionary:
	var sim:=Sim.new()
	var a:=_force(sim,"Rovik's host",[["spearman","spear",3200],["archer","bow",600],["cavalry","lance",400]])
	var d:=_force(sim,"Esurai host",[["spearman","spear",3000],["slinger","sling",500]],0.75)
	var plan:=preload("res://scripts/battle_tactics.gd").plan({"attacker":{"force":a,"known":["formation_drill","domesticated_mounts","shield_wall","bow_craft"]},"defender":{"force":d,"known":["shield_wall"]}},{"kind":"field","terrain":1.0},seed)
	var result:=sim.simulate(a,d,{"seed":seed,"tactics":plan,"ground":{"kind":"rough"}})
	result["home_side"]="attacker"
	result["day"]=500
	return result


func _plain(text:String)->void:
	for word in JARGON: assert_bool(text.contains(word)).override_failure_message("'%s' in: %s" % [word,text]).is_false()


func test_a_record_opens_with_sides_phases_and_plates()->void:
	var record:=_record()
	var view:=Record.view(record,{"stage":"lettered","left_name":"Rovik's host","right_name":"the Esurai","left_general":"Rovik Longstride"})
	assert_bool(bool(view.player)).is_true()
	assert_str(String(view.left)).is_equal("attacker")
	assert_array(view.phases).is_not_empty()
	var totals:Dictionary=view.sides.left.totals
	assert_int(int(totals.went_in)).is_equal(4200)
	assert_int(int(totals.killed)+int(totals.wounded)+int(totals.fled)+int(totals.captured)+int(totals.standing)).is_equal(4200)
	for phase in view.phases:
		var plates:Dictionary=phase.plates
		assert_array(plates.left.front).is_not_empty()
		for plate in plates.left.front+plates.left.rear:
			assert_float(float(plate.strength)).is_between(0.0,1.0)
			assert_float(float(plate.cohesion)).is_between(0.0,1.0)
			assert_array(["fighting","waiting","broken","fled"]).contains([String(plate.state_words)])
		for line in phase.events: _plain(String(line))
		for item in phase.why:
			_plain(String(item.label)+" "+String(item.text))
			assert_array(["left","right"]).contains([String(item.favours)])
	_plain(String(view.phrase))
	assert_str(String(view.phrase)).is_not_empty()
	# The drawn-up start shows every block in the line or waiting.
	var start:Dictionary=view.start
	assert_int((start.left.front as Array).size()+(start.left.rear as Array).size()).is_equal((record.battle.sides.attacker.blocks as Array).size())


func test_viewing_steps_through_identically_without_fighting_again()->void:
	var record:=_record(21)
	var before:=JSON.stringify(record)
	var first:=Record.view(record,{"stage":"reckoned"})
	var second:=Record.view(record,{"stage":"reckoned"})
	assert_str(JSON.stringify(first)).is_equal(JSON.stringify(second))
	# Stepping phase by phase reads the same snapshot every time.
	for index in (first.phases as Array).size():
		assert_str(JSON.stringify(first.phases[index].plates)).is_equal(JSON.stringify(second.phases[index].plates))
	assert_str(JSON.stringify(record)).is_equal(before)


func test_an_old_record_without_blocks_opens()->void:
	## A record from before the block battle: exchanges only.
	var rounds:=[]
	for n in 6:
		rounds.append({"round":n+1,"intensity":"Sustained combat","event":"No decisive local event.","tactic_event":"",
			"attacker_losses":3,"defender_losses":2,"attacker_morale":0.8-0.05*n,"defender_morale":0.7-0.1*n,
			"attacker_casualties":{"killed":1,"wounded":1,"scattered":1},"defender_casualties":{"killed":1,"wounded":1,"scattered":0},
			"attacker_cohort_losses":[3],"defender_cohort_losses":[2]})
	var record:={"seed":4242,"day":34826,"home_side":"attacker","outcome":"attacker_victory",
		"attacker":{"name":"LEVY BAND 1","initial_troops":60,"remaining_troops":42,"morale":0.55,"formations":[{"unit":"levy","weapon":"improvised","count":42}],"commander":{"name":"Rovik Longstride","command":0.6,"tactics":0.6}},
		"defender":{"name":"Tsaren defenders","initial_troops":40,"remaining_troops":28,"morale":0.2,"formations":[{"unit":"line_infantry","weapon":"spear","count":28}]},
		"rounds":rounds,"termination":{"type":"withdrawal","captor":"LEVY BAND 1","defeated":"Tsaren defenders","prisoners":3,"commander_fate":"escaped"},
		"tactics":{"attacker":{"id":"head_on"},"defender":{"id":"shield_wall"}}}
	var view:=Record.view(record,{"stage":"hearth","left_name":"Rovik's band","right_name":"the Esurai"})
	assert_bool(bool(view.derived)).is_true()
	assert_int((view.phases as Array).size()).is_equal(2)
	assert_int(int(view.sides.left.totals.went_in)).is_equal(60)
	assert_int(int(view.sides.right.totals.captured)).is_equal(3)
	# Bands of about thirty, blocks and plates reconstructed from the exchanges.
	var last:Dictionary=view.phases[-1]
	var ours:int=0
	for plate in last.plates.left.front+last.plates.left.rear: ours+=int(plate.men)
	assert_int(ours).is_between(40,44)
	var theirs_fled:=false
	for plate in last.plates.right.rear:
		if String(plate.state)=="fled": theirs_fled=true
	assert_bool(theirs_fled).is_true()
	assert_str(String(view.phrase)).is_equal("We won the field")
	# A record with nothing at all still opens.
	var empty:=Record.view({"attacker":{"name":"A","initial_troops":5,"remaining_troops":5},"defender":{"name":"B","initial_troops":0}},{})
	assert_array(empty.phases).is_empty()


func test_skirmishes_are_a_card()->void:
	var sim:=Sim.new()
	var result:=sim.simulate(_force(sim,"Ours",[["levy","improvised",20]]),_force(sim,"Theirs",[["levy","improvised",2]]),{"seed":3})
	result["home_side"]="attacker"
	var view:=Record.view(result,{"stage":"hearth"})
	assert_bool(bool(view.skirmish)).is_true()
	assert_str(String(view.one_line)).is_not_empty()
	var big:=Record.view(_record(),{"stage":"lettered"})
	assert_bool(bool(big.skirmish)).is_false()


func test_phrases_follow_the_winner()->void:
	assert_str(Record.phrase(0.8,0.0,true,"us","them")).is_equal("We are driving them from the field")
	assert_str(Record.phrase(0.5,0.0,true,"us","them")).is_equal("We are pushing them back")
	assert_str(Record.phrase(0.0,0.1,true,"us","them")).is_equal("The fight is turning our way")
	assert_str(Record.phrase(-0.6,0.0,true,"us","them")).is_equal("Our line is giving way")
	assert_str(Record.phrase(0.5,0.0,false,"the Esurai","the Tsaren")).is_equal("The Esurai are pushing the Tsaren back")
	assert_str(Record.phrase(0.0,0.0,true,"us","them","won")).is_equal("We won the field")


func test_a_live_engagement_shows_the_phase_being_fought()->void:
	var sim:=Sim.new()
	var a:=_force(sim,"A",[["spearman","spear",2000]])
	var d:=_force(sim,"D",[["spearman","spear",1900]])
	var battle:=sim.open_battle(a,d,{"ground":{"kind":"open"}})
	var engagement:={"id":"1-1","home_side":"defender","attacker":a,"defender":d,"rounds":[],"battle":battle,"attacker_initial":2000,"defender_initial":1900,"tactics":{}}
	var drawn:=Record.view(engagement,{"live":true,"stage":"lettered"})
	assert_bool(bool(drawn.live)).is_true()
	assert_str(String(drawn.status)).is_equal("Drawn up, about to fight")
	assert_array(drawn.phases).has_size(1)
	assert_str(String(drawn.left)).is_equal("defender")
	var one:=sim.simulate(a,d,{"seed":5,"max_rounds":2,"battle":battle})
	engagement["rounds"]=one.rounds
	var fighting:=Record.view(engagement,{"live":true,"stage":"lettered"})
	assert_str(String(fighting.status)).starts_with("Fighting")
	assert_bool(bool(fighting.phases[-1].get("current",false))).is_true()
