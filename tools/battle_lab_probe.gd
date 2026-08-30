extends SceneTree


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	var lab: Node = load("res://tools/battle_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	print("BATTLE_LAB_LAYOUT minimum=%s viewport=%s" % [lab.get_combined_minimum_size(),root.size])
	print("BATTLE_LAB_READINESS attacker=%s defender=%s" % [lab.attacker_readiness.text,lab.defender_readiness.text])
	var supplied_strength:=float(lab.strength_bar.value)
	lab.attacker_cards[2].ammunition.value=0
	lab._preview_battle()
	var depleted_strength:=float(lab.strength_bar.value)
	assert(depleted_strength<supplied_strength)
	lab.attacker_cards[2].ammunition.value=int(lab.attacker_archers.value)*6
	lab._preview_battle()
	print("BATTLE_LAB_AMMUNITION supplied=%.1f depleted=%.1f" % [supplied_strength,depleted_strength])
	lab._advance_preparation(1)
	lab._start_battle()
	lab.battle_timer.stop()
	for round_index in 12:
		if not lab.battle_active:
			break
		if round_index == 1:
			lab._push_harder()
		lab._advance_round()
	print("BATTLE_LAB_PROBE active=%s rounds=%d status=%s" % [lab.battle_active,lab.live_round,lab.outcome_label.text])
	if not lab.round_records.is_empty(): print("BATTLE_LAB_AFTERMATH %s" % String(lab.round_records[-1].get("termination",{}).get("summary","")))
	print("BATTLE_LAB_COMMANDERS attacker=%s defender=%s" % [lab.attacker_commander_select.get_item_text(lab.attacker_commander_select.selected),lab.defender_commander_select.get_item_text(lab.defender_commander_select.selected)])
	var recovery_before:=int(lab.live_attacker.troops)
	lab._advance_preparation(1)
	print("BATTLE_LAB_RECOVERY attacker=%d->%d reserves=%d wounded=%d scattered=%d" % [recovery_before,int(lab.live_attacker.troops),int(lab.live_attacker.get("reserve_manpower",0)),int(lab.live_attacker.get("wounded_pool",0)),int(lab.live_attacker.get("scattered_pool",0))])
	lab.queue_free()
	await process_frame
	var timed_lab: Node = load("res://tools/battle_lab.tscn").instantiate()
	root.add_child(timed_lab)
	await process_frame
	timed_lab._advance_preparation(1)
	timed_lab._start_battle()
	await create_timer(6.0).timeout
	print("BATTLE_LAB_TIMER_PROBE active=%s rounds=%d status=%s" % [timed_lab.battle_active,timed_lab.live_round,timed_lab.outcome_label.text])
	timed_lab._toggle_battle()
	await create_timer(6.0).timeout
	print("BATTLE_LAB_RESTART_PROBE active=%s rounds=%d status=%s" % [timed_lab.battle_active,timed_lab.live_round,timed_lab.outcome_label.text])
	var succession_text:String=timed_lab._apply_command_succession({"commander_fate":"captured","defeated":"Hill Guard"})
	print("BATTLE_LAB_SUCCESSION commander=%s event=%s" % [timed_lab.defender_commander_select.get_item_text(timed_lab.defender_commander_select.selected),succession_text])
	timed_lab.queue_free()
	await process_frame
	var day_zero_lab:Node=load("res://tools/battle_lab.tscn").instantiate()
	root.add_child(day_zero_lab)
	await process_frame
	day_zero_lab._start_battle()
	day_zero_lab.battle_timer.stop()
	for round_index in 12:
		if not day_zero_lab.battle_active: break
		day_zero_lab._advance_round()
	var before_recovery:=int(day_zero_lab.live_attacker.troops)
	var authorized_before:=int(day_zero_lab.live_attacker.formations[0].authorized_count)
	day_zero_lab._advance_preparation(150)
	var cohort_sum:=0
	for formation in day_zero_lab.live_attacker.formations: cohort_sum+=int(formation.count)
	var active_citizens:=0
	for person in day_zero_lab.attacker_roster:
		if bool(person.get("active_in_army",false)): active_citizens+=1
	print("BATTLE_LAB_150_DAY_RECOVERY troops=%d->%d cohort_sum=%d active_citizens=%d authorized_levy=%d equipment=%d reserves=%d summary=%s" % [before_recovery,int(day_zero_lab.live_attacker.troops),cohort_sum,active_citizens,authorized_before,int(day_zero_lab.live_attacker.formations[0].equipment),int(day_zero_lab.live_attacker.get("reserve_manpower",0)),day_zero_lab.attacker_summary.text])
	day_zero_lab.queue_free()
	await process_frame
	var simulator=load("res://scripts/combat_simulator.gd").new()
	var first_spoils_seed:=-1
	for audit_seed in range(1,101):
		var audit_attacker=simulator.create_formation_force("A",[{"unit":"levy","weapon":"improvised","count":50,"equipment":50},{"unit":"line_infantry","weapon":"spear","count":50,"equipment":50},{"unit":"skirmisher","weapon":"bow","count":20,"equipment":20}])
		var audit_defender=simulator.create_formation_force("D",[{"unit":"levy","weapon":"improvised","count":30,"equipment":30},{"unit":"line_infantry","weapon":"spear","count":50,"equipment":50},{"unit":"skirmisher","weapon":"bow","count":20,"equipment":20}])
		var audited:Dictionary=simulator.simulate(audit_attacker,audit_defender,{"seed":audit_seed})
		if first_spoils_seed<0 and not (audited.termination.get("spoils",{}) as Dictionary).is_empty(): first_spoils_seed=audit_seed
		for side_name in ["attacker","defender"]:
			var side:Dictionary=audited[side_name]
			var summed:=0
			for formation in side.formations: summed+=int(formation.count)
			assert(summed==int(side.remaining_troops))
			assert(int(side.initial_troops)==int(side.remaining_troops)+int(side.casualties))
		for record in audited.rounds:
			var ac:Dictionary=record.attacker_casualties
			var dc:Dictionary=record.defender_casualties
			assert(int(ac.killed)+int(ac.wounded)+int(ac.scattered)==int(record.attacker_losses))
			assert(int(dc.killed)+int(dc.wounded)+int(dc.scattered)==int(record.defender_losses))
	print("BATTLE_LAB_MATH_AUDIT seeds=100 status=PASS first_spoils_seed=%d" % first_spoils_seed)
	var policy_lab:Node=load("res://tools/battle_lab.tscn").instantiate()
	root.add_child(policy_lab)
	await process_frame
	policy_lab.pending_prisoner_decision={"captured_general":true}
	var policy_result:String=policy_lab._apply_captive_consequences("execute","execute general",policy_lab.live_attacker,policy_lab.live_defender)
	print("BATTLE_LAB_POLICY_AUDIT %s" % policy_result)
	policy_lab.queue_free()
	await process_frame
	quit()
