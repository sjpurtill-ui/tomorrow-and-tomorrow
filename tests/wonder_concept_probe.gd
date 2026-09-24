extends Node
## Prints sample conceived wonders for contrasting peoples and an outcome
## distribution by ambition. Headless: res://tests/wonder_concept_probe.tscn
const W=preload("res://scripts/wonder_concept.gd")
const KNOWN:=["masonry_bond_patterns","joinery","clay_shaping","public_stores","seed_selection","seasonal_patterns","drainage","festival_calendar","tallies","voussoir_arch_assembly"]
func _ready()->void:
	for node in get_tree().root.get_children():
		if node!=self:node.set_process(false)
	WorldSimulation.clear();GameState.reset_for_new_world(921);SettlementModel.reset_for_new_world()
	GameState.settlement_name="Hometown";GameState.settlement_site_committed=true;GameState.settlement_completed.assign(["Hearth Circle"]);SettlementModel.ensure_founded()
	GameState.known_discoveries.assign(KNOWN)
	GameState.population_allocations={"Construction":20,"Crafting":10,"Food":20}
	GameState.simulation_metrics={"food_intake_ratio":1.0,"labor_efficiency":1.0,"cohesion":.7,"legitimacy":.6,"food_consumption":100.0}
	var peoples:={"player":{"hierarchy":.95,"centralization":.9,"experimentation":.15,"openness":.1},"sages":{"experimentation":.95,"pluralism":.8,"openness":.7,"hierarchy":.2},"keepers":{"collective_obligation":.95,"common_stewardship":.9,"ecological_restraint":.9,"experimentation":.2}}
	for id in peoples:
		if id!="player":
			WorldSimulation.create_actor(id,921)
			WorldSimulation.scoped(id,func()->void:
				WorldSimulation.state.settlement_name=id.capitalize()
				WorldSimulation.state.known_discoveries.assign(KNOWN))
		var s:Node=preload("res://scripts/society_exchange.gd").owner_state(id)
		for axis in peoples[id]:s.societal_values.lived[axis]=float(peoples[id][axis])
		print("== %s (tradition %s)" % [id,W.tradition(id)])
		for trigger in [{},{"kind":"famine"},{"kind":"victory"}]:
			for c:Dictionary in W.conceive(id,trigger):
				print("  [%s] %s — %s %s (%s, %s) :: %s | %s" % [str(trigger.get("kind","none")),c.name,c.proposed_ambition,c.shape,c.purpose,c.material,c.lore,c.motive])
	print("== outcomes by ambition (1000 seeded trials each, same people and conditions)")
	for ambition in W.AMBITIONS:
		var concept:=W.retarget(W.conceive("player",{"purpose":"awe_rivals","form":"mound"})[0],ambition)
		var a:=W.assess(concept,"player")
		var counts:={"triumph":0,"success":0,"flawed":0,"collapse":0}
		var pay:=0.0
		for i in 1000:
			var o:=W.resolve(float(a.score),ambition,W.unit_roll("trial/%s/%d" % [ambition,i]))
			counts[o]+=1;pay+=W.pay(ambition,o)
		print("  %s score=%.2f %s mean_pay=%.2f spoken=%s" % [ambition,float(a.score),str(counts),pay/1000.0,a.spoken])
	get_tree().quit()
