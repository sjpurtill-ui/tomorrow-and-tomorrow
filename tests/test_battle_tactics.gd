extends GdUnitTestSuite
## Generals fight with real, generically named tactics, only once their people
## can actually carry them out, and every tactic's effect stays bounded.
const Tactics:=preload("res://scripts/battle_tactics.gd")

const ERAS:=["stone","bronze","classical","gunpowder","industrial","modern"]

## Cumulative knowledge and a typical field force for each age (the multi-era check).
static func era_snapshots()->Array:
	var known:Array=[]
	var out:Array=[]
	var steps:=[
		["stone",["hafted_weapons","bow_craft","woven_carriers"],[["levy",60],["spearman",30],["archer",25]],0.5],
		["bronze",["shield_wall","formation_drill","bronze_weaponry","domesticated_mounts","field_fortifications"],[["spearman",1500],["archer",400],["cavalry",320]],0.6],
		["classical",["professional_corps","siege_engineering","war_chariots"],[["heavy_swordsman",3000],["spearman",2000],["cavalry",1000],["archer",600]],0.65],
		["gunpowder",["pike_drill","matchlock_drill","powder_artillery","military_staffs","optical_telegraphy"],[["pikeman",8000],["musketeer",9000],["cavalry",3500],["bombard_crew",300]],0.7],
		["industrial",["metallic_cartridges","rifled_barrels","automatic_actions","indirect_fire","electrical_telegraphy"],[["rifle_infantry",40000],["machine_gun_company",5000],["field_artillery",3000],["assault_infantry",2500]],0.7],
		["modern",["internal_combustion","armored_vehicles","radio_telegraphy"],[["mechanized_infantry",20000],["light_tank",8000],["rifle_infantry",30000],["modern_artillery",5000]],0.7],
	]
	for step in steps:
		known.append_array(step[1])
		var formations:Array=[]
		for entry in step[2]: formations.append({"unit":entry[0],"count":entry[1],"training":step[3]})
		out.append({"era":step[0],"known":known.duplicate(),"force":{"formations":formations,"commander":{"command":0.7,"tactics":0.7,"resolve":0.6}}})
	return out


func _side(snapshot:Dictionary,role:String)->Dictionary:
	return {"known":snapshot.known,"profile":Tactics.profile(snapshot.force),"role":role,"character":{"ambition":0.6,"confidence":0.6,"care":0.5}}


func test_nothing_clever_without_its_prerequisites()->void:
	var bare:={"formations":[{"unit":"levy","count":40,"training":0.2}]}
	var side:={"known":[],"profile":Tactics.profile(bare),"role":"attacker"}
	var ids:=Tactics.available_ids(side,{"kind":"field","terrain":1.0,"ratio":1.0})
	for id in ids: assert_str(String(Tactics.TACTICS[id].era)).is_equal("stone")
	assert_bool(ids.has("double_envelopment")).is_false()
	# Horsemen without drill cannot envelop; drill without horse cannot either.
	var mounted:={"formations":[{"unit":"spearman","count":2000,"training":0.7},{"unit":"cavalry","count":800,"training":0.7}],"commander":{"command":0.8,"tactics":0.8}}
	var context:={"kind":"field","terrain":1.0,"ratio":1.0}
	assert_bool(Tactics.available("double_envelopment",{"known":["domesticated_mounts"],"profile":Tactics.profile(mounted),"role":"defender"},context)).is_false()
	assert_bool(Tactics.available("double_envelopment",{"known":["formation_drill"],"profile":Tactics.profile(mounted),"role":"defender"},context)).is_false()
	assert_bool(Tactics.available("double_envelopment",{"known":["formation_drill","domesticated_mounts"],"profile":Tactics.profile(mounted),"role":"defender"},context)).is_true()
	# An armoured breakthrough needs armour, engines and wireless together.
	var armour:={"formations":[{"unit":"light_tank","count":5000,"training":0.7},{"unit":"rifle_infantry","count":20000,"training":0.7}]}
	assert_bool(Tactics.available("armoured_breakthrough",{"known":["armored_vehicles","internal_combustion"],"profile":Tactics.profile(armour),"role":"attacker"},context)).is_false()
	assert_bool(Tactics.available("armoured_breakthrough",{"known":["armored_vehicles","internal_combustion","radio_telegraphy"],"profile":Tactics.profile(armour),"role":"attacker"},context)).is_true()


func test_tactics_appear_only_in_their_age()->void:
	# Multi-era check: which tactics the generals actually choose, age by age.
	var table:PackedStringArray=[]
	for index in era_snapshots().size():
		var snapshot:Dictionary=era_snapshots()[index]
		var counts:={}
		for seed in 300:
			for role in ["attacker","defender"]:
				var side:=_side(snapshot,role)
				var battle:={"kind":"field","terrain":1.15 if seed%3==0 else 1.0,"ratio":0.9+float(seed%5)*0.1}
				var id:=Tactics.choose(side,{"rigid":seed%4==0},battle,seed*31+(1 if role=="defender" else 0))
				assert_bool(Tactics.available(id,side,battle)).override_failure_message("%s chose unavailable %s" % [snapshot.era,id]).is_true()
				assert_int(ERAS.find(String(Tactics.TACTICS[id].era))).override_failure_message("%s tactic in %s" % [id,snapshot.era]).is_less_equal(index)
				counts[id]=int(counts.get(id,0))+1
		# The plain fight stays common in every age.
		assert_int(int(counts.get(Tactics.BASELINE,0))).is_greater(60)
		var row:PackedStringArray=[]
		var ids:=counts.keys(); ids.sort_custom(func(a,b)->bool: return int(counts[a])>int(counts[b]))
		for id in ids: row.append("%s %d%%" % [id,roundi(float(counts[id])/6.0)])
		table.append("%s: %s" % [snapshot.era,", ".join(row)])
	print("TACTICS BY AGE\n"+"\n".join(table))


func test_rivals_know_only_what_they_field()->void:
	var rival:={"formations":[{"unit":"levy","count":200},{"unit":"cavalry","count":40}]}
	var known:=Tactics.known_from_force(rival,0.1)
	assert_bool(known.has("domesticated_mounts")).is_true()
	assert_bool(known.has("formation_drill")).is_false()
	assert_bool(known.has("radio_telegraphy")).is_false()
	var plan:=Tactics.plan({"attacker":{"force":rival,"known":known},"defender":{"force":{"formations":[{"unit":"levy","count":150}]},"known":[]}},{"kind":"field","terrain":1.0},4)
	assert_array(["stone","bronze"]).contains([String(Tactics.TACTICS[plan.attacker.id].era)])


func test_round_effects_are_bounded()->void:
	var snapshot:Dictionary=era_snapshots()[5]
	var ids:=Tactics.TACTICS.keys()
	for a in ids:
		for d in ids:
			var plan:={"attacker":{"id":a,"profile":Tactics.profile(snapshot.force),"pursuit":true},"defender":{"id":d,"profile":Tactics.profile(era_snapshots()[0].force),"pursuit":true}}
			for round_number in range(1,13):
				for share in [0.1,0.45,0.5,0.9]:
					var fx:=Tactics.round_effects(plan,round_number,share,0.2,0.2)
					assert_float(float(fx.attacker)).is_between(Tactics.COMBINED_MIN,Tactics.COMBINED_MAX)
					assert_float(float(fx.defender)).is_between(Tactics.COMBINED_MIN,Tactics.COMBINED_MAX)
					assert_float(float(fx.intensity)).is_between(0.8,1.2)
	assert_dict(Tactics.round_effects({},3,0.5,1.0,1.0)).contains_key_value("attacker",1.0)


func test_outcomes_stay_within_historical_bounds()->void:
	# Equal armies: a good tactic helps, but never turns a coin toss into a sure thing.
	var simulator:=CombatSimulator.new()
	var formations:=[{"unit":"spearman","weapon":"spear","count":2000,"equipment":2000,"training":0.7},{"unit":"cavalry","weapon":"spear","count":600,"equipment":600,"training":0.7}]
	var wins_plain:=0; var wins_tactic:=0; var losses_plain:=0.0; var losses_tactic:=0.0
	for seed in 40:
		var a:=simulator.create_formation_force("A",formations.duplicate(true),0.8,0.8)
		var d:=simulator.create_formation_force("D",formations.duplicate(true),0.8,0.8)
		var plain:=simulator.simulate(a,d,{"seed":seed,"max_rounds":8})
		var plan:={"attacker":{"id":"double_envelopment","profile":Tactics.profile(a),"pursuit":true},"defender":{"id":"dense_line","profile":Tactics.profile(d),"pursuit":false}}
		var fought:=simulator.simulate(a,d,{"seed":seed,"max_rounds":8,"tactics":plan})
		if String(plain.outcome)=="attacker_victory": wins_plain+=1
		if String(fought.outcome)=="attacker_victory": wins_tactic+=1
		losses_plain+=float(plain.defender.casualties)/2600.0
		losses_tactic+=float(fought.defender.casualties)/2600.0
		assert_that(fought.get("tactics",{})).is_equal(plan)
	# Bounded: the defender's average loss share can rise, but by less than half again.
	assert_float(losses_tactic).is_less(losses_plain*1.5+0.5)
	assert_int(wins_tactic-wins_plain).is_less_equal(18)
	# No plan: the resolver is unchanged.
	var a2:=simulator.create_formation_force("A",formations.duplicate(true),0.8,0.8)
	var d2:=simulator.create_formation_force("D",formations.duplicate(true),0.8,0.8)
	assert_that(simulator.simulate(a2,d2,{"seed":9}).rounds).is_equal(simulator.simulate(a2,d2,{"seed":9,"tactics":{}}).rounds)


func test_names_are_generic_and_era_worded()->void:
	var banned:=["cannae","leuthen","blitz","napole","roman","mongol","zulu","hannibal","frederick","trafalgar","nelson","tsushima","macedon","prussia","german","british","french","greek","persian"]
	for table in [Tactics.TACTICS,Tactics.ZONE_TACTICS,Tactics.SIEGE_WORKS]:
		for id in table:
			for stage in ["hearth","lettered","reckoned"]:
				var name:=Tactics.name_of(String(id),stage).to_lower()
				assert_str(name).is_not_empty()
				for word in banned: assert_str(name).not_contains(word)
	var plan:={"attacker":{"id":"double_envelopment"},"defender":{"id":"shield_wall"}}
	assert_str(Tactics.report_sentence(plan,"attacker","reckoned")).is_equal("Our general chose a double envelopment. The enemy answered with a shield wall.")
	assert_str(Tactics.report_sentence({"attacker":{"id":"dawn_raid"},"defender":{"id":"head_on"}},"attacker","hearth")).is_equal("We fell on them at first light.")


func test_zone_tactics_follow_hulls_airframes_and_discoveries()->void:
	var subs:={"domain":"navy","mission":"convoy_raiding","units":{"submarine":6}}
	assert_array(Tactics.zone_available(subs,["submersible_hulls"])).not_contains(["wolf_packs"])
	assert_array(Tactics.zone_available(subs,["submersible_hulls","radio_telegraphy"])).contains(["wolf_packs"])
	var galleys:={"domain":"navy","mission":"patrol","units":{"galley":10}}
	assert_array(Tactics.zone_available(galleys,[])).not_contains(["close_blockade"])
	assert_array(Tactics.zone_available(galleys,[],{"port":true})).contains(["close_blockade"])
	assert_str(Tactics.zone_choose(galleys,[],{"port":true})).is_equal("close_blockade")
	var bombers:={"domain":"air","mission":"strategic_bombing","units":{"strategic_bomber":20}}
	assert_str(Tactics.zone_choose(bombers,[])).is_equal("night_area_bombing")
	assert_str(Tactics.zone_choose(bombers,[],{"escort":true})).is_equal("escorted_day_bombing")
	for id in Tactics.ZONE_TACTICS:
		for key in ["damage","detection","taken"]:
			assert_float(Tactics.zone_factor(String(id),key)).is_between(Tactics.ZONE_MIN,Tactics.ZONE_MAX)
	# A rival's knowledge comes from its own hulls only.
	var catalog:Dictionary=preload("res://scripts/joint_force_catalog.gd").UNITS
	assert_array(Tactics.zone_known(subs,catalog)).contains(["submersible_hulls"])
	assert_array(Tactics.zone_known(subs,catalog)).not_contains(["radio_telegraphy"])
