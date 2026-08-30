class_name CombatSimulator
extends RefCounted

## A deterministic, presentation-free battle resolver.
##
## Required force fields: name, troops. Optional fields are deliberately small:
## attack, defense, morale, readiness. All ratings use 1.0 as the baseline.

const MAX_ROUNDS := 12
const BASE_CASUALTY_RATE := 0.055
const MIN_EFFECTIVE_STRENGTH := 0.05

const UNIT_TYPES := {
	"levy": {"name": "Levy", "attack": 0.65, "defense": 0.55, "organization": 0.65},
	"line_infantry": {"name": "Line Infantry", "attack": 1.00, "defense": 1.00, "organization": 1.00},
	"skirmisher": {"name": "Skirmisher", "attack": 0.85, "defense": 0.60, "organization": 0.85},
	"cavalry": {"name": "Cavalry", "attack": 1.35, "defense": 0.72, "organization": 0.90},
	"siege_engineer": {"name":"Siege Engineers","attack":0.72,"defense":0.68,"organization":0.92},
	"field_artillery":{"name":"Field Artillery","attack":1.55,"defense":0.42,"organization":0.78}
}

const WEAPONS := {
	"improvised": {"name": "Improvised Arms", "attack": 0.65, "defense": 0.70, "armor": 0.00, "penetration": 0.10},
	"spear": {"name": "Spears", "attack": 1.00, "defense": 1.18, "armor": 0.05, "penetration": 0.55},
	"bow": {"name": "Bows", "attack": 1.18, "defense": 0.70, "armor": 0.00, "penetration": 0.35},
	"sword_shield": {"name": "Sword & Shield", "attack": 1.12, "defense": 1.22, "armor": 0.38, "penetration": 0.42},
	"lance": {"name": "Lances", "attack": 1.35, "defense": 0.72, "armor": 0.18, "penetration": 0.70},
	"siege_kit": {"name":"Siege Kit","attack":0.88,"defense":0.72,"armor":0.08,"penetration":0.92},
	"field_gun":{"name":"Field Gun","attack":2.10,"defense":0.48,"armor":0.12,"penetration":1.45}
}

# Attack multipliers against the opposing unit mix. Unlisted matchups are 1.0.
# These are intentionally data, not branches, so discoveries can replace or
# extend the table later without rewriting battle resolution.
const MATCHUPS := {
	"levy": {"line_infantry": 0.82, "cavalry": 0.72},
	"line_infantry": {"levy": 1.18, "skirmisher": 1.08, "cavalry": 1.48},
	"skirmisher": {"levy": 1.28, "line_infantry": 0.82, "cavalry": 0.68},
	"cavalry": {"levy": 1.20, "line_infantry": 0.62, "skirmisher": 1.45}
	,"siege_engineer":{"levy":0.82,"line_infantry":0.78,"cavalry":0.62},
	"field_artillery":{"levy":1.35,"line_infantry":1.22,"cavalry":0.58,"siege_engineer":1.18}
}


func create_force(name: String, troops: int, attack := 1.0, defense := 1.0, morale := 1.0, readiness := 1.0) -> Dictionary:
	return {
		"name": name,
		"troops": maxi(0, troops),
		"attack": maxf(0.0, float(attack)),
		"defense": maxf(0.05, float(defense)),
		"morale": clampf(float(morale), 0.0, 1.5),
		"readiness": clampf(float(readiness), 0.0, 1.5)
	}

func create_commander(name:String,command:=0.5,tactics:=0.5,logistics:=0.5,resolve:=0.5)->Dictionary:
	return {"name":name,"command":clampf(command,0.0,1.0),"tactics":clampf(tactics,0.0,1.0),"logistics":clampf(logistics,0.0,1.0),"resolve":clampf(resolve,0.0,1.0)}


func create_formation_force(name: String, formations: Array, morale := 1.0, readiness := 1.0) -> Dictionary:
	var troops := 0
	var attack_total := 0.0
	var defense_total := 0.0
	var organization_total := 0.0
	var armor_total := 0.0
	var penetration_total := 0.0
	var normalized: Array[Dictionary] = []
	for formation in formations:
		var unit_id := String(formation.get("unit", "levy"))
		var weapon_id := String(formation.get("weapon", "improvised"))
		var count := maxi(0, int(formation.get("count", 0)))
		var authorized_count := maxi(count,int(formation.get("authorized_count",count)))
		var default_equipment_required:=ceili(float(authorized_count)/5.0) if weapon_id=="field_gun" else authorized_count
		var equipment_required := maxi(0,int(formation.get("equipment_required",default_equipment_required)))
		var equipment := clampi(int(formation.get("equipment",count)),0,equipment_required)
		var default_ammunition_required:=authorized_count*6 if weapon_id=="bow" else (equipment_required*8 if weapon_id=="field_gun" else 0)
		var ammunition_required:=maxi(0,int(formation.get("ammunition_required",default_ammunition_required)))
		var ammunition:=clampi(int(formation.get("ammunition",ammunition_required)),0,ammunition_required)
		var unit: Dictionary = UNIT_TYPES.get(unit_id, UNIT_TYPES.levy)
		var weapon: Dictionary = WEAPONS.get(weapon_id, WEAPONS.improvised)
		var training:=clampf(float(formation.get("training",0.55 if unit_id=="levy" else 0.70)),0.25,1.25)
		var training_factor:=0.72+training*0.28
		var experience:=clampf(float(formation.get("experience",0.0)),0.0,1.0)
		var experience_factor:=0.94+experience*0.14
		troops += count
		attack_total += count * float(unit.attack) * float(weapon.attack)*training_factor*experience_factor
		defense_total += count * float(unit.defense) * float(weapon.defense)*training_factor*experience_factor
		organization_total += count * float(unit.organization)*training_factor*(0.92+experience*0.12)
		armor_total += count * float(weapon.armor)
		penetration_total += count * float(weapon.penetration)
		normalized.append({"id":int(formation.get("id",-1)),"unit":unit_id,"weapon":weapon_id,"count":count,"authorized_count":authorized_count,"equipment":equipment,"equipment_required":equipment_required,"ammunition":ammunition,"ammunition_required":ammunition_required,"training":training,"experience":experience,"soldier_ids":(formation.get("soldier_ids",[]) as Array).duplicate(),"wear_accumulator":float(formation.get("wear_accumulator",0.0))})
	var divisor := maxf(1.0, float(troops))
	return {
		"name": name,
		"troops": troops,
		"attack": attack_total / divisor,
		"defense": defense_total / divisor,
		# Morale is the force's current psychological state. Cohort training and
		# organization are represented separately in readiness and combat power;
		# multiplying them here made preparation apply the same penalty twice.
		"morale": clampf(float(morale), 0.0, 1.5),
		"readiness": clampf(float(readiness), 0.0, 1.5),
		"armor": armor_total / divisor,
		"penetration": penetration_total / divisor,
		"formations": normalized,
		# Campaign reserves must be backed by actual citizens. Callers may supply
		# reserve_manpower explicitly, but forming a unit cannot conjure another 20%.
		"reserve_manpower":0,
		"wounded_pool":0,
		"scattered_pool":0,
		"dead":0
	}


func simulate(attacker: Dictionary, defender: Dictionary, options: Dictionary = {}) -> Dictionary:
	var attacking_force := _normalize_force(attacker, "Attacker")
	var defending_force := _normalize_force(defender, "Defender")
	var seed := int(options.get("seed", 1))
	var round_limit := clampi(int(options.get("max_rounds", MAX_ROUNDS)), 1, MAX_ROUNDS)
	var terrain_defense := clampf(float(options.get("terrain_defense", 1.0)), 0.5, 2.0)
	var siege_reduction:=_siege_terrain_reduction(attacking_force)
	var effective_terrain_defense:=lerpf(terrain_defense,1.0,siege_reduction) if terrain_defense>1.0 else terrain_defense
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var attacker_initial := int(attacking_force.troops)
	var defender_initial := int(defending_force.troops)
	var attacker_troops := attacker_initial
	var defender_troops := defender_initial
	var attacker_morale := float(attacking_force.morale)
	var defender_morale := float(defending_force.morale)
	var rounds: Array[Dictionary] = []

	for round_number in range(1, round_limit + 1):
		if attacker_troops <= 0 or defender_troops <= 0:
			break
		if attacker_morale <= 0.15 or defender_morale <= 0.15:
			break

		var attacker_cohorts := evaluate_force(attacking_force, defending_force, 1.0)
		var defender_cohorts := evaluate_force(defending_force, attacking_force, effective_terrain_defense)
		var attacker_commander:Dictionary=attacking_force.get("commander",{})
		var defender_commander:Dictionary=defending_force.get("commander",{})
		var attacker_power := _cohort_power(attacker_cohorts,attacker_morale,float(attacking_force.readiness),float(attacker_commander.get("command",0.5)))
		var defender_power := _cohort_power(defender_cohorts,defender_morale,float(defending_force.readiness),float(defender_commander.get("command",0.5)))
		var total_power := maxf(MIN_EFFECTIVE_STRENGTH, attacker_power + defender_power)
		var attacker_share := attacker_power / total_power
		var defender_share := defender_power / total_power
		var engagement:=_engagement_context(rng,attacker_share,defender_share,attacker_morale,defender_morale,effective_terrain_defense)
		var attacker_variance := _casualty_variance(rng)
		var defender_variance := _casualty_variance(rng)

		# Casualties are based on the opposing force's share of power. They are
		# calculated before either side is reduced, so each round is simultaneous.
		var attacker_losses := mini(attacker_troops, maxi(0, roundi(float(attacker_troops) * BASE_CASUALTY_RATE * defender_share * 2.0 * defender_variance * float(engagement.intensity) * float(engagement.attacker_exposure))))
		var defender_losses := mini(defender_troops, maxi(0, roundi(float(defender_troops) * BASE_CASUALTY_RATE * attacker_share * 2.0 * attacker_variance * float(engagement.intensity) * float(engagement.defender_exposure) / effective_terrain_defense)))
		# A force in contact usually suffers at least one loss; true lulls may be bloodless.
		if attacker_losses==0 and float(engagement.intensity)>=0.65: attacker_losses=1
		if defender_losses==0 and float(engagement.intensity)>=0.65: defender_losses=1
		attacker_troops -= attacker_losses
		defender_troops -= defender_losses
		var attacker_cohort_result:=_apply_cohort_losses(attacking_force.get("formations", []), attacker_cohorts, attacker_losses,rng,engagement.get("attacker_target",-1))
		var defender_cohort_result:=_apply_cohort_losses(defending_force.get("formations", []), defender_cohorts, defender_losses,rng,engagement.get("defender_target",-1))
		var attacker_ammunition_used:=_consume_ammunition(attacker_cohort_result.formations,float(engagement.intensity),rng)
		var defender_ammunition_used:=_consume_ammunition(defender_cohort_result.formations,float(engagement.intensity),rng)
		var attacker_casualties:=_casualty_breakdown(attacker_losses,rng,float(engagement.intensity))
		var defender_casualties:=_casualty_breakdown(defender_losses,rng,float(engagement.intensity))
		attacking_force["formations"] = attacker_cohort_result.formations
		defending_force["formations"] = defender_cohort_result.formations
		attacking_force["wounded_pool"]=int(attacking_force.get("wounded_pool",0))+int(attacker_casualties.wounded)
		attacking_force["scattered_pool"]=int(attacking_force.get("scattered_pool",0))+int(attacker_casualties.scattered)
		attacking_force["dead"]=int(attacking_force.get("dead",0))+int(attacker_casualties.killed)
		defending_force["wounded_pool"]=int(defending_force.get("wounded_pool",0))+int(defender_casualties.wounded)
		defending_force["scattered_pool"]=int(defending_force.get("scattered_pool",0))+int(defender_casualties.scattered)
		defending_force["dead"]=int(defending_force.get("dead",0))+int(defender_casualties.killed)
		attacking_force["troops"] = attacker_troops
		defending_force["troops"] = defender_troops

		attacker_morale = _next_morale(attacker_morale,attacker_losses,maxi(1,attacker_initial),defender_share,float(attacker_commander.get("resolve",0.5)))
		defender_morale = _next_morale(defender_morale,defender_losses,maxi(1,defender_initial),attacker_share,float(defender_commander.get("resolve",0.5)))
		rounds.append({
			"round": round_number,
			"attacker_losses": attacker_losses,
			"defender_losses": defender_losses,
			"attacker_remaining": attacker_troops,
			"defender_remaining": defender_troops,
			"attacker_morale": attacker_morale,
			"defender_morale": defender_morale,
			"intensity":engagement.label,
			"event":engagement.event,
			"attacker_cohort_losses":attacker_cohort_result.losses,
			"defender_cohort_losses":defender_cohort_result.losses,
			"attacker_cohort_equipment_losses":attacker_cohort_result.equipment_losses,
			"defender_cohort_equipment_losses":defender_cohort_result.equipment_losses,
			"attacker_cohort_ammunition_used":attacker_ammunition_used,
			"defender_cohort_ammunition_used":defender_ammunition_used,
			"attacker_casualties":attacker_casualties,
			"defender_casualties":defender_casualties
		})

	var outcome := _outcome(attacker_troops, defender_troops, attacker_morale, defender_morale)
	var termination:=_termination_event(outcome,attacking_force,defending_force,attacker_troops,defender_troops,attacker_morale,defender_morale,rng)
	return {
		"seed": seed,
		"outcome": outcome,
		"winner": _winner_name(outcome, attacking_force, defending_force),
		"round_count": rounds.size(),
		"rounds": rounds,
		"attacker": _force_result(attacking_force, attacker_initial, attacker_troops, attacker_morale),
		"defender": _force_result(defending_force, defender_initial, defender_troops, defender_morale),
		"terrain_defense": terrain_defense,
		"effective_terrain_defense":effective_terrain_defense,
		"siege_terrain_reduction":siege_reduction,
		"termination":termination
	}


func evaluate_force(force: Dictionary, opponent: Dictionary, terrain_modifier := 1.0) -> Array[Dictionary]:
	var formations: Array = force.get("formations", force.get("composition", []))
	if formations.is_empty():
		return [{
			"unit": "generic", "weapon": "generic", "count": int(force.get("troops", force.get("population", 0))),
			"attack": float(force.get("attack", 1.0)), "defense": float(force.get("defense", 1.0)) * terrain_modifier,
			"matchup": 1.0, "terrain": terrain_modifier
		}]
	var enemy_formations: Array = opponent.get("formations", opponent.get("composition", []))
	var commander:Dictionary=force.get("commander",{})
	var tactics:=clampf(float(commander.get("tactics",0.5)),0.0,1.0)
	var result: Array[Dictionary] = []
	for formation in formations:
		var unit_id := String(formation.get("unit", "levy"))
		var weapon_id := String(formation.get("weapon", "improvised"))
		var count := maxi(0, int(formation.get("count", 0)))
		var default_equipment_required:=ceili(float(formation.get("authorized_count",count))/5.0) if weapon_id=="field_gun" else int(formation.get("authorized_count",count))
		var equipment_required:=maxi(1,int(formation.get("equipment_required",default_equipment_required)))
		var equipment:=clampi(int(formation.get("equipment",count)),0,equipment_required)
		var equipment_ratio:=clampf(float(equipment)/float(equipment_required),0.0,1.0)
		var default_ammunition_required:=int(formation.get("authorized_count",count))*6 if weapon_id=="bow" else (equipment_required*8 if weapon_id=="field_gun" else 0)
		var ammunition_required:=maxi(0,int(formation.get("ammunition_required",default_ammunition_required)))
		var ammunition:=clampi(int(formation.get("ammunition",ammunition_required)),0,ammunition_required)
		var ammunition_ratio:=clampf(float(ammunition)/maxf(1.0,float(ammunition_required)),0.0,1.0) if ammunition_required>0 else 1.0
		var ammunition_floor:=0.12 if weapon_id=="field_gun" else 0.30
		var ammunition_attack_factor:=ammunition_floor+ammunition_ratio*(1.0-ammunition_floor) if ammunition_required>0 else 1.0
		var unit: Dictionary = UNIT_TYPES.get(unit_id, UNIT_TYPES.levy)
		var weapon: Dictionary = WEAPONS.get(weapon_id, WEAPONS.improvised)
		var training:=clampf(float(formation.get("training",0.55 if unit_id=="levy" else 0.70)),0.25,1.25)
		var training_factor:=0.72+training*0.28
		var experience:=clampf(float(formation.get("experience",0.0)),0.0,1.0)
		var experience_factor:=0.94+experience*0.14
		var matchup := _weighted_matchup(unit_id, enemy_formations)
		matchup=1.0+(matchup-1.0)*(0.65+tactics*0.70)
		var armor_protection := 1.0 + maxf(0.0, float(weapon.armor) - _enemy_penetration(enemy_formations)) * 0.35
		result.append({
			"unit": unit_id, "weapon": weapon_id, "count": count,
			"attack":float(unit.attack)*float(weapon.attack)*matchup*(0.22+equipment_ratio*0.78)*ammunition_attack_factor*training_factor*experience_factor,
			"defense":float(unit.defense)*float(weapon.defense)*terrain_modifier*armor_protection*(0.35+equipment_ratio*0.65)*training_factor*experience_factor,
			"matchup":matchup,"terrain":terrain_modifier,"equipment":equipment,"equipment_required":equipment_required,"equipment_ratio":equipment_ratio,"ammunition":ammunition,"ammunition_required":ammunition_required,"ammunition_ratio":ammunition_ratio,"training":training,"experience":experience
		})
	return result


func force_readiness(force: Dictionary,personnel_condition := 1.0) -> Dictionary:
	var formations:Array=force.get("formations",[])
	var soldiers:=0
	var authorized:=0
	var equipment:=0
	var equipment_required:=0
	var ammunition:=0
	var ammunition_required:=0
	for formation in formations:
		soldiers+=int(formation.get("count",0))
		authorized+=int(formation.get("authorized_count",formation.get("count",0)))
		equipment+=int(formation.get("equipment",formation.get("count",0)))
		equipment_required+=int(formation.get("equipment_required",formation.get("authorized_count",formation.get("count",0))))
		ammunition+=int(formation.get("ammunition",0))
		ammunition_required+=int(formation.get("ammunition_required",0))
	var manpower_fill:=clampf(float(soldiers)/maxf(1.0,float(authorized)),0.0,1.0)
	var equipment_fill:=clampf(float(equipment)/maxf(1.0,float(equipment_required)),0.0,1.0)
	var ammunition_fill:=clampf(float(ammunition)/maxf(1.0,float(ammunition_required)),0.0,1.0) if ammunition_required>0 else 1.0
	var condition:=clampf(personnel_condition,0.0,1.0)
	var training_total:=0.0
	for formation in formations: training_total+=int(formation.get("count",0))*clampf(float(formation.get("training",0.55)),0.0,1.0)
	var training_organization:=training_total/maxf(1.0,float(soldiers))
	var organization:=clampf(float(force.get("morale",1.0))*0.55+training_organization*0.45,0.0,1.0)
	var aggregate:=manpower_fill*0.28+equipment_fill*0.27+condition*0.23+organization*0.14+ammunition_fill*0.08
	return {"aggregate":aggregate,"manpower":manpower_fill,"equipment":equipment_fill,"ammunition":ammunition_fill,"condition":condition,"organization":organization}


func advance_preparation_day(force: Dictionary, context: Dictionary = {}) -> Dictionary:
	var prepared:=force.duplicate(true)
	var commander:Dictionary=prepared.get("commander",{})
	var logistics:=clampf(float(commander.get("logistics",0.5)),0.0,1.0)
	var command:=clampf(float(commander.get("command",0.5)),0.0,1.0)
	var available_equipment:=maxi(0,roundi(float(context.get("equipment_replacements",0))*(0.65+logistics*0.70)))
	var organization_recovery:=clampf(float(context.get("organization_recovery",0.08)),0.0,0.30)
	organization_recovery*=0.70+command*0.60
	var delivered:=0
	var formations:Array=prepared.get("formations",[])
	for index in formations.size():
		if available_equipment<=0: break
		var formation:Dictionary=formations[index]
		var required:=int(formation.get("equipment_required",formation.get("authorized_count",formation.get("count",0))))
		var present:=int(formation.get("equipment",0))
		var transfer:=mini(available_equipment,maxi(0,required-present))
		formation["equipment"]=present+transfer
		formations[index]=formation
		available_equipment-=transfer
		delivered+=transfer
	prepared["formations"]=formations
	prepared["morale"]=move_toward(float(prepared.get("morale",1.0)),1.0,organization_recovery)
	var scattered_available:=int(prepared.get("scattered_pool",0))
	var wounded_available:=int(prepared.get("wounded_pool",0))
	var reserves_available:=int(prepared.get("reserve_manpower",0))
	var recovery_multiplier:=clampf(float(context.get("recovery_multiplier",1.0)),0.10,1.60)
	var scattered_progress:=float(prepared.get("scattered_recovery_accumulator",0.0))+float(scattered_available)*(0.22+logistics*0.28)
	var wounded_progress:=float(prepared.get("wounded_recovery_accumulator",0.0))+float(wounded_available)*(0.035+logistics*0.055)*recovery_multiplier
	var scattered_return:=mini(scattered_available,maxi(0,floori(scattered_progress)))
	var wounded_return:=mini(wounded_available,maxi(0,floori(wounded_progress)))
	prepared["scattered_recovery_accumulator"]=scattered_progress-float(scattered_return) if scattered_available>scattered_return else 0.0
	prepared["wounded_recovery_accumulator"]=wounded_progress-float(wounded_return) if wounded_available>wounded_return else 0.0
	var reserve_arrivals:=mini(reserves_available,maxi(0,roundi(float(context.get("manpower_replacements",4))*(0.45+logistics*0.85))))
	var manpower_queue:=scattered_return+wounded_return+reserve_arrivals
	var integrated:=0
	for index in formations.size():
		if manpower_queue<=0: break
		var formation:Dictionary=formations[index]
		var count:=int(formation.get("count",0))
		var authorized:=int(formation.get("authorized_count",count))
		var equipment:=int(formation.get("equipment",count))
		var capacity:=mini(maxi(0,authorized-count),maxi(0,equipment-count))
		var arrivals:=mini(manpower_queue,capacity)
		formation["count"]=count+arrivals
		formations[index]=formation
		manpower_queue-=arrivals
		integrated+=arrivals
	var consumed:=integrated
	var from_scattered:=mini(scattered_return,consumed)
	consumed-=from_scattered
	var from_wounded:=mini(wounded_return,consumed)
	consumed-=from_wounded
	var from_reserves:=mini(reserve_arrivals,consumed)
	prepared["scattered_pool"]=scattered_available-from_scattered
	prepared["wounded_pool"]=wounded_available-from_wounded
	prepared["reserve_manpower"]=reserves_available-from_reserves
	prepared["formations"]=formations
	prepared["troops"]=_formation_manpower(formations)
	return {"force":prepared,"equipment_delivered":delivered,"equipment_unused":available_equipment,"manpower_rejoined":integrated,"scattered_recovered":scattered_return,"wounded_recovered":wounded_return,"scattered_returned":from_scattered,"wounded_returned":from_wounded,"reserves_arrived":from_reserves,"manpower_waiting_for_equipment":manpower_queue}


func _formation_manpower(formations: Array) -> int:
	var total:=0
	for formation in formations: total+=int(formation.get("count",0))
	return total


func _siege_terrain_reduction(force:Dictionary)->float:
	var troops:=maxi(1,int(force.get("troops",0)))
	var effective_engineers:=0.0
	for formation in force.get("formations",[]):
		if String(formation.get("unit",""))!="siege_engineer" or String(formation.get("weapon",""))!="siege_kit": continue
		var count:=maxi(0,int(formation.get("count",0)))
		var required:=maxi(1,int(formation.get("equipment_required",formation.get("authorized_count",count))))
		var equipment_ratio:=clampf(float(formation.get("equipment",0))/float(required),0.0,1.0)
		effective_engineers+=float(count)*equipment_ratio
	return clampf(effective_engineers/float(troops)*1.6,0.0,0.45)


func _weighted_matchup(unit_id: String, enemy_formations: Array) -> float:
	var enemy_total := 0
	var weighted := 0.0
	var table: Dictionary = MATCHUPS.get(unit_id, {})
	for enemy in enemy_formations:
		var count := maxi(0, int(enemy.get("count", 0)))
		enemy_total += count
		weighted += count * float(table.get(String(enemy.get("unit", "levy")), 1.0))
	return weighted / float(enemy_total) if enemy_total > 0 else 1.0


func _enemy_penetration(enemy_formations: Array) -> float:
	var total := 0
	var weighted := 0.0
	for enemy in enemy_formations:
		var count := maxi(0, int(enemy.get("count", 0)))
		var weapon: Dictionary = WEAPONS.get(String(enemy.get("weapon", "improvised")), WEAPONS.improvised)
		total += count
		weighted += count * float(weapon.penetration)
	return weighted / float(total) if total > 0 else 0.0


func _cohort_power(cohorts: Array[Dictionary], morale: float, readiness: float,command: float) -> float:
	var power := 0.0
	for cohort in cohorts:
		power += float(cohort.count) * sqrt(float(cohort.attack) * float(cohort.defense))
	return power*maxf(MIN_EFFECTIVE_STRENGTH,morale)*readiness*(0.90+clampf(command,0.0,1.0)*0.20)


func _engagement_context(rng: RandomNumberGenerator,attacker_share: float,defender_share: float,attacker_morale: float,defender_morale: float,terrain: float) -> Dictionary:
	var roll:=rng.randf()
	var label:="Sustained combat"
	var intensity:=1.0
	if roll<0.16:
		label="Broken contact"
		intensity=0.18
	elif roll<0.39:
		label="Skirmishing"
		intensity=0.58
	elif roll<0.77:
		label="Sustained combat"
		intensity=1.0
	elif roll<0.94:
		label="Close engagement"
		intensity=1.48
	else:
		label="Violent crisis"
		intensity=2.25
	var context:={"label":label,"intensity":intensity,"event":"No decisive local event.","attacker_exposure":1.0,"defender_exposure":1.0,"attacker_target":-1,"defender_target":-1}
	var event_roll:=rng.randf()
	if attacker_share>=0.59 and event_roll<0.25:
		context.event="River Host punches through a weak point."
		context.defender_exposure=1.75
		context.attacker_exposure=0.82
		context.defender_target=rng.randi_range(0,2)
	elif defender_share>=0.59 and event_roll<0.25:
		context.event="Hill Guard catches the assault in a killing ground."
		context.attacker_exposure=1.75
		context.defender_exposure=0.82
		context.attacker_target=rng.randi_range(0,2)
	elif terrain>1.15 and event_roll<0.20:
		context.event="The defended ground breaks the attacking formation."
		context.attacker_exposure=1.38
		context.defender_exposure=0.68
	elif minf(attacker_morale,defender_morale)<0.42 and event_roll<0.35:
		if attacker_morale<defender_morale:
			context.event="A River Host cohort wavers and takes losses while falling back."
			context.attacker_exposure=1.65
			context.attacker_target=rng.randi_range(0,2)
		else:
			context.event="A Hill Guard cohort wavers and takes losses while falling back."
			context.defender_exposure=1.65
			context.defender_target=rng.randi_range(0,2)
	elif event_roll>0.86:
		context.event="Confused local fighting scatters both front lines."
		context.attacker_exposure=1.22
		context.defender_exposure=1.22
	return context


func _casualty_variance(rng: RandomNumberGenerator) -> float:
	# Log-normal noise: mostly near one, with rare but bounded casualty spikes.
	return clampf(exp(rng.randfn(-0.10,0.48)),0.25,2.65)


func _casualty_breakdown(losses: int,rng: RandomNumberGenerator,intensity: float) -> Dictionary:
	if losses<=0: return {"killed":0,"wounded":0,"scattered":0}
	var killed_share:=clampf(0.18+intensity*0.055+rng.randf_range(-0.05,0.06),0.10,0.38)
	var wounded_share:=clampf(0.43+rng.randf_range(-0.09,0.10),0.28,0.62)
	var killed:=clampi(roundi(float(losses)*killed_share),0,losses)
	var wounded:=clampi(roundi(float(losses)*wounded_share),0,losses-killed)
	return {"killed":killed,"wounded":wounded,"scattered":losses-killed-wounded}


func _apply_cohort_losses(formations: Array, cohorts: Array[Dictionary], losses: int,rng: RandomNumberGenerator,targeted_cohort: int=-1) -> Dictionary:
	var updated: Array[Dictionary] = []
	var original_counts:Array[int]=[]
	var cohort_losses:Array[int]=[]
	var cohort_equipment_losses:Array[int]=[]
	for formation in formations:
		updated.append(formation.duplicate(true))
		original_counts.append(int(formation.get("count",0)))
		cohort_losses.append(0)
		cohort_equipment_losses.append(0)
	var contact_factors:Array[float]=[]
	for index in updated.size():
		var contact:=rng.randf_range(0.55,1.45)
		if index==targeted_cohort: contact*=2.25
		contact_factors.append(contact)
	var remaining_losses := losses
	while remaining_losses > 0:
		var total_exposure:=0.0
		var exposures:Array[float]=[]
		for index in updated.size():
			var count := int(updated[index].get("count", 0))
			var defense := maxf(0.05, float(cohorts[index].defense))
			var exposure := float(count)/defense*contact_factors[index] if count>0 else 0.0
			exposures.append(exposure)
			total_exposure+=exposure
		var target := -1
		var pick:=rng.randf()*total_exposure
		for index in exposures.size():
			pick-=exposures[index]
			if pick<=0.0 and exposures[index]>0.0:
				target=index
				break
		if target < 0:
			break
		updated[target]["count"] = int(updated[target].count) - 1
		cohort_losses[target]+=1
		remaining_losses -= 1
	for index in updated.size():
		var personnel_losses:=original_counts[index]-int(updated[index].get("count",0))
		var old_equipment:=int(updated[index].get("equipment",original_counts[index]))
		var personnel_loss_share:=float(personnel_losses)/maxf(1.0,float(original_counts[index]))
		var equipment_losses:=mini(old_equipment,roundi(float(old_equipment)*personnel_loss_share*0.72+float(old_equipment)*0.006))
		updated[index]["equipment"]=old_equipment-equipment_losses
		cohort_equipment_losses[index]=equipment_losses
	return {"formations":updated,"losses":cohort_losses,"equipment_losses":cohort_equipment_losses}


func _consume_ammunition(formations:Array,intensity:float,rng:RandomNumberGenerator)->Array[int]:
	var used_by_cohort:Array[int]=[]
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var used:=0
		var weapon:=String(formation.get("weapon","improvised"))
		if weapon in ["bow","field_gun"]:
			var available:=maxi(0,int(formation.get("ammunition",0)))
			var firing_elements:=maxi(0,int(formation.get("count",0))) if weapon=="bow" else maxi(0,int(formation.get("equipment",0)))
			var desired:=maxi(0,roundi(float(firing_elements)*rng.randf_range(0.38,0.72)*clampf(intensity,0.25,1.50))) if weapon=="bow" else maxi(0,roundi(float(firing_elements)*rng.randf_range(0.65,1.25)*clampf(intensity,0.25,1.50)))
			used=mini(available,desired)
			formation["ammunition"]=available-used
			formations[index]=formation
		used_by_cohort.append(used)
	return used_by_cohort


func _normalize_force(force: Dictionary, fallback_name: String) -> Dictionary:
	if force.has("formations"):
		var formation_force := create_formation_force(
			String(force.get("name", fallback_name)),
			force.formations,
			float(force.get("morale", 1.0)),
			float(force.get("readiness", 1.0))
		)
		# Command-level modifiers sit above equipment-derived statistics.
		formation_force.attack *= float(force.get("attack_modifier", 1.0))
		formation_force.defense *= float(force.get("defense_modifier", 1.0))
		formation_force["commander"]=force.get("commander",{}).duplicate(true)
		formation_force["reserve_manpower"]=int(force.get("reserve_manpower",formation_force.get("reserve_manpower",0)))
		formation_force["wounded_pool"]=int(force.get("wounded_pool",0))
		formation_force["scattered_pool"]=int(force.get("scattered_pool",0))
		formation_force["dead"]=int(force.get("dead",0))
		return formation_force
	var normalized := create_force(
		String(force.get("name", fallback_name)),
		int(force.get("troops", force.get("population", 0))),
		float(force.get("attack", 1.0)),
		float(force.get("defense", 1.0)),
		float(force.get("morale", 1.0)),
		float(force.get("readiness", 1.0))
	)
	normalized["armor"] = clampf(float(force.get("armor", 0.0)), 0.0, 2.0)
	normalized["penetration"] = clampf(float(force.get("penetration", 0.0)), 0.0, 2.0)
	normalized["composition"] = force.get("composition", []).duplicate(true)
	normalized["commander"] = force.get("commander",{}).duplicate(true)
	return normalized


func _combat_power(force: Dictionary, opponent: Dictionary, troops: int, morale: float, terrain_modifier: float) -> float:
	var armor := float(force.get("armor", 0.0))
	var enemy_penetration := float(opponent.get("penetration", 1.0))
	var armor_advantage := 1.0 + maxf(0.0, armor - enemy_penetration) * 0.35
	return float(troops) * float(force.attack) * float(force.defense) * float(force.readiness) * maxf(MIN_EFFECTIVE_STRENGTH, morale) * terrain_modifier * armor_advantage


func _next_morale(current: float, losses: int, initial_troops: int, enemy_power_share: float,resolve: float) -> float:
	var casualty_shock := float(losses) / float(initial_troops) * 1.8
	var pressure := maxf(0.0, enemy_power_share - 0.5) * 0.08
	var resolve_protection:=0.78+clampf(resolve,0.0,1.0)*0.34
	return clampf(current-(casualty_shock+pressure)/resolve_protection,0.0,1.5)


func _outcome(attacker_troops: int, defender_troops: int, attacker_morale: float, defender_morale: float) -> String:
	var attacker_broken := attacker_troops <= 0 or attacker_morale <= 0.15
	var defender_broken := defender_troops <= 0 or defender_morale <= 0.15
	if attacker_broken and defender_broken:
		return "mutual_collapse"
	if defender_broken:
		return "attacker_victory"
	if attacker_broken:
		return "defender_victory"
	return "inconclusive"


func _termination_event(outcome: String,attacker: Dictionary,defender: Dictionary,attacker_remaining: int,defender_remaining: int,attacker_morale: float,defender_morale: float,rng: RandomNumberGenerator) -> Dictionary:
	if outcome=="inconclusive":
		return {"type":"continued","summary":"Neither army yields the field.","prisoners":0,"commander_fate":"in command","captured_general":false,"spoils":{}}
	if outcome=="mutual_collapse":
		return {"type":"mutual_withdrawal","summary":"Both shattered armies disengage; scattered soldiers remain between the lines.","prisoners":0,"commander_fate":"unknown","captured_general":false,"spoils":{}}
	var loser:Dictionary=defender if outcome=="attacker_victory" else attacker
	var winner:Dictionary=attacker if outcome=="attacker_victory" else defender
	var loser_remaining:=defender_remaining if outcome=="attacker_victory" else attacker_remaining
	var loser_morale:=defender_morale if outcome=="attacker_victory" else attacker_morale
	var loser_commander:Dictionary=loser.get("commander",{})
	var resolve:=clampf(float(loser_commander.get("resolve",0.5)),0.0,1.0)
	var collapse:=clampf((0.22-loser_morale)/0.22,0.0,1.0)
	var pursuit_roll:=rng.randf()
	var termination_type:="withdrawal"
	var capture_share:=0.0
	if pursuit_roll<0.18+collapse*0.32:
		termination_type="surrender"
		capture_share=rng.randf_range(0.24,0.55)*(0.75+collapse*0.5)
	elif pursuit_roll<0.58+collapse*0.20:
		termination_type="pursuit"
		capture_share=rng.randf_range(0.07,0.24)
	else:
		capture_share=rng.randf_range(0.0,0.06)
	var prisoners:=clampi(roundi(float(loser_remaining)*capture_share),0,loser_remaining)
	var capture_chance:=clampf(0.06+collapse*0.22+(1.0-resolve)*0.24+(0.10 if termination_type=="surrender" else 0.0),0.02,0.62)
	var fate_roll:=rng.randf()
	var commander_fate:="escaped"
	var captured_general:=false
	if fate_roll<capture_chance:
		commander_fate="captured"
		captured_general=true
	elif fate_roll<capture_chance+0.055:
		commander_fate="killed"
	elif fate_roll<capture_chance+0.16:
		commander_fate="wounded, but escaped"
	var loser_name:=String(loser.get("name","Defeated force"))
	var winner_name:=String(winner.get("name","Victors"))
	var commander_name:=String(loser_commander.get("name","The defeated commander"))
	var summary:="%s withdraws in order." % loser_name
	if termination_type=="surrender": summary="Elements of %s surrender; %s takes %d prisoners." % [loser_name,winner_name,prisoners]
	elif termination_type=="pursuit": summary="%s pursues the rout and takes %d prisoners." % [winner_name,prisoners]
	elif prisoners>0: summary="%s escapes, leaving %d prisoners behind." % [loser_name,prisoners]
	summary+="  %s is %s." % [commander_name,commander_fate]
	var spoils:=_battle_spoils(loser,winner,termination_type,rng)
	return {"type":termination_type,"summary":summary,"prisoners":prisoners,"captor":winner_name,"defeated":loser_name,"commander":commander_name,"commander_fate":commander_fate,"captured_general":captured_general,"spoils":spoils}


func _battle_spoils(loser: Dictionary,winner: Dictionary,termination_type: String,rng: RandomNumberGenerator) -> Dictionary:
	var base_rate:=0.05
	if termination_type=="pursuit": base_rate=0.16
	elif termination_type=="surrender": base_rate=0.34
	var logistics:=clampf(float((winner.get("commander",{}) as Dictionary).get("logistics",0.5)),0.0,1.0)
	var recovery_rate:=clampf(base_rate*(0.65+logistics*0.70)*rng.randf_range(0.85,1.15),0.0,0.60)
	var weapons:Dictionary={}
	var consumables:Dictionary={}
	var total_equipment:=0
	var formations:Array=loser.get("formations",[])
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var equipment:=int(formation.get("equipment",0))
		var recovered:=clampi(roundi(float(equipment)*recovery_rate),0,equipment)
		var weapon:=String(formation.get("weapon","improvised"))
		weapons[weapon]=int(weapons.get(weapon,0))+recovered
		if weapon in ["bow","field_gun"]:
			var ammunition:=int(formation.get("ammunition",0))
			var ammunition_recovered:=clampi(roundi(float(ammunition)*recovery_rate),0,ammunition)
			var ammunition_type:="arrows" if weapon=="bow" else "artillery_rounds"
			consumables[ammunition_type]=int(consumables.get(ammunition_type,0))+ammunition_recovered
			formation["ammunition"]=ammunition-ammunition_recovered
		total_equipment+=equipment
		formation["equipment"]=equipment-recovered
		formations[index]=formation
	loser["formations"]=formations
	var supplies:=maxi(0,roundi(float(total_equipment)*recovery_rate*rng.randf_range(0.28,0.52)))
	var carts:=maxi(0,roundi(float(total_equipment)*recovery_rate/28.0))
	var wealth:=maxi(0,roundi(float(total_equipment)*recovery_rate*rng.randf_range(0.8,1.8)))
	return {"weapons":weapons,"consumables":consumables,"supplies":supplies,"carts":carts,"wealth":wealth,"recovery_rate":recovery_rate}


func _winner_name(outcome: String, attacker: Dictionary, defender: Dictionary) -> String:
	if outcome == "attacker_victory":
		return String(attacker.name)
	if outcome == "defender_victory":
		return String(defender.name)
	return ""


func _force_result(force: Dictionary, initial: int, remaining: int, morale: float) -> Dictionary:
	return {
		"name": String(force.name),
		"initial_troops": initial,
		"remaining_troops": remaining,
		"casualties": initial - remaining,
		"morale": morale,
		"routed": remaining <= 0 or morale <= 0.15,
		"attack": float(force.attack),
		"defense": float(force.defense),
		"armor": float(force.get("armor", 0.0)),
		"penetration": float(force.get("penetration", 0.0)),
		"formations": force.get("formations", []).duplicate(true),
		"reserve_manpower":int(force.get("reserve_manpower",0)),
		"wounded_pool":int(force.get("wounded_pool",0)),
		"scattered_pool":int(force.get("scattered_pool",0)),
		"dead":int(force.get("dead",0))
	}
