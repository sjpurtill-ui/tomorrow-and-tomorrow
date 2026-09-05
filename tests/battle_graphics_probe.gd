extends Node

var failures: Array[String] = []
func check(value:bool,message:String)->void:
	if not value: failures.append(message)

func _ready()->void:
	var simulator:=CombatSimulator.new()
	var a:=simulator.create_formation_force("A",[{"id":1,"unit":"line_infantry","weapon":"sword_shield","count":800,"visual_model":"armored_foot"},{"id":2,"unit":"skirmisher","weapon":"bow","count":300,"visual_model":"pavise_crossbowman"}],1,.9)
	var d:=simulator.create_formation_force("D",[{"id":3,"unit":"line_infantry","weapon":"spear","count":900},{"id":4,"unit":"skirmisher","weapon":"bow","count":300}],1,.9)
	var input_copy:=a.duplicate(true)
	var plain:=a.duplicate(true)
	for formation:Dictionary in plain.formations: formation.erase("visual_model")
	var result:=simulator.simulate(a,d,{"seed":43,"max_rounds":1})
	var baseline:=simulator.simulate(plain,d,{"seed":43,"max_rounds":1})
	check(result.attacker.remaining_troops==baseline.attacker.remaining_troops and result.defender.remaining_troops==baseline.defender.remaining_troops,"appearance changed combat outcome")
	check(result.attacker.formations[0].visual_model=="armored_foot","combat discarded appearance")
	var screen:=BattleGraphicsScreen.new(); screen.campaign_mode=false; add_child(screen)
	screen.view.reset(a,d)
	await get_tree().process_frame
	var cursor:=Vector2(screen.viewport.size)*Vector2(.6,.55)
	var anchor:Vector3=screen.view.ground_at(cursor)
	screen.view.zoom_at(cursor,-5)
	check(screen.view.ground_at(cursor).distance_to(anchor)<.02,"zoom lost its cursor anchor")
	var destination:=cursor+Vector2(12,8)
	screen.view.pan(cursor,destination)
	check(screen.view.ground_at(destination).distance_to(anchor)<.02,"pan did not hold the grabbed ground point")
	screen.view.cinematic=true; screen.view.orbit(.1,10)
	check(not screen.view.cinematic and screen.view.elevation<=1.35,"manual orbit failed to stop director or clamp tilt")
	screen.view.elevation=.66; screen.view.target=Vector3(0,1,0); screen.view.zoom=65; screen.view._camera_update()
	var representatives:int=screen.view.representative_count()
	check(representatives<=192,"battle exceeded its representative cap")
	var current:=a.duplicate(true); current.troops=result.attacker.remaining_troops; current.morale=result.attacker.morale; current.formations=result.attacker.formations
	var opponent:=d.duplicate(true); opponent.troops=result.defender.remaining_troops; opponent.formations=result.defender.formations
	screen.present(current,opponent,result.rounds[0],"",result.rounds)
	check(screen.view.representative_count()==representatives,"casualty update rebuilt population-sized actors")
	var fallen:=0
	for group:Dictionary in screen.view.groups:
		for dead:bool in group.dead:
			if dead: fallen+=1
	check(fallen>0,"recorded losses did not animate casualties")
	check(screen.view.carnage.events.size()==fallen,"casualty bursts do not match fallen representatives")
	screen.view.apply_snapshot(current,opponent,result.rounds[0])
	check(screen.view.carnage.events.size()==fallen,"duplicate snapshot replayed blood bursts")
	check(a==input_copy,"presentation mutated authoritative input")
	screen.view.playback_speed=0; var before:float=screen.view.clock; screen.view._process(1)
	check(screen.view.clock==before,"view pause did not stop its clock")
	screen.present(current,opponent,{},"attacker_retreat")
	check(screen.view._routed(0) and not screen.view._routed(1),"retreat affected wrong side")
	screen.view.reset(a,d)
	check(screen.view.carnage.events.is_empty(),"reset retained carnage effects")
	for group:Dictionary in screen.view.groups:
		check(not true in group.dead,"reset retained casualties")
	var huge:=a.duplicate(true)
	for f:Dictionary in huge.formations: f.count=500000000
	huge.troops=1000000000; screen.view.reset(huge,huge)
	check(screen.view.representative_count()==192,"billion-person force exceeded fixed cap")
	var commanded_a:=a.duplicate(true); commanded_a.commander=simulator.create_commander("Test General A")
	var commanded_d:=d.duplicate(true); commanded_d.commander=simulator.create_commander("Test General D")
	screen.view.reset(commanded_a,commanded_d)
	check(screen.view.generals.size()==2,"named generals absent")
	var fatal:Dictionary={"termination":{"defeated":"A","commander_fate":"killed"}}
	screen.view.apply_snapshot(commanded_a,commanded_d,fatal,"defender_victory")
	check(screen.view.generals[0].fate=="killed" and screen.view.generals[0].figure.clip=="death","general death not animated")
	check(screen.view.generals[1].fate=="in command","wrong general affected")
	var bursts:int=screen.view.carnage.events.size()
	screen.view.apply_snapshot(commanded_a,commanded_d,fatal,"defender_victory")
	check(screen.view.carnage.events.size()==bursts,"general death repeated")
	for fate in ["captured","wounded, but escaped","escaped"]:
		screen.view.reset(commanded_a,commanded_d)
		screen.view.apply_snapshot(commanded_a,commanded_d,{"termination":{"defeated":"D","commander_fate":fate}},"attacker_victory")
		check(screen.view.generals[1].fate==fate,"general fate missing: "+fate)
	screen.view.reset(a,d)
	check(screen.view.generals.is_empty(),"reset retained old generals")
	var saved_home:Dictionary=MilitaryCampaign.home_army.duplicate(true)
	var saved_engagement:Dictionary=MilitaryCampaign.active_engagement.duplicate(true)
	MilitaryCampaign.active_engagement={"attacker":a.duplicate(true),"defender":d.duplicate(true),"attacker_initial":a.troops,"defender_initial":d.troops,"round":0,"rounds":[],"seed":43,"terrain_defense":1.0,"home_side":"attacker","threat":{}}
	MilitaryCampaign.advance_engagement("hold")
	check(not MilitaryCampaign.active_engagement.is_empty(),"undecided round incorrectly ended campaign battle")
	if not MilitaryCampaign.active_engagement.is_empty():
		MilitaryCampaign.advance_engagement("hold")
		check(MilitaryCampaign.active_engagement.get("round",0)==2,"campaign failed to advance to second round")
	MilitaryCampaign.active_engagement=saved_engagement
	MilitaryCampaign.home_army=a.duplicate(true)
	var changed:=MilitaryCampaign.set_formation_visual(0,1,"legionary_infantry")
	check(not changed.has("error"),"campaign rejected valid model")
	check(MilitaryCampaign.home_army.troops==a.troops,"appearance changed personnel")
	var saved:Dictionary=MilitaryCampaign.export_state()
	check(saved.home_army.formations[0].visual_model=="legionary_infantry","save omitted model choice")
	var bad:=MilitaryCampaign.set_formation_visual(0,1,"trireme")
	check(bad.has("error"),"land formation accepted naval model")
	var inspection:=BattleGraphicsScreen.new()
	add_child(inspection)
	check(inspection.appearance.visible and inspection.formation_choice.item_count==2,"campaign inspector did not load formations")
	inspection.free()
	MilitaryCampaign.home_army=saved_home
	screen.free()
	if failures.is_empty(): print("BATTLE_GRAPHICS_PROBE PASS: combat invariance, metadata, casualties, reset, retreat, pause, save, 192 figure cap")
	else:
		for failure in failures: push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
