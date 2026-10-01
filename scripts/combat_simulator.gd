class_name CombatSimulator
extends RefCounted

## A deterministic, presentation-free battle resolver.
##
## Required force fields: name, troops. Optional fields are deliberately small:
## attack, defense, morale, readiness. All ratings use 1.0 as the baseline.

const MAX_ROUNDS := 12
const BattleTactics:=preload("res://scripts/battle_tactics.gd")
## Blocks, frontage, reserves and phases (battle_blocks.gd).
const Blocks:=preload("res://scripts/battle_blocks.gd")
## Above this many losses in one exchange, losses are spread over formations
## by their exposure in one pass instead of one person at a time.
const LOSS_ONE_BY_ONE:=64
const BASE_CASUALTY_RATE := 0.055
const MIN_EFFECTIVE_STRENGTH := 0.05
## Overwhelming odds (tests/test_battle_scale.gd). At about five to one in
## fighting power, with the numbers to match, the small side is overrun in
## a single exchange: cut down, taken or sent running at once, while the big
## side loses almost nobody. A band of a handful facing three times its
## number is overrun the same way; it cannot hold a line at all.
const OVERRUN_RATIO := 5.0
const OVERRUN_MIN_NUMBERS := 1.5
const OVERRUN_NUMBERS_ODDS := 1.25
const DEFENDED_GROUND := 1.1
const TINY_BAND := 8
const TINY_BAND_RATIO := 3.0
## Between even odds and an overrun, the weaker side is worn down faster and
## the stronger side slower, so only comparable forces fight for long.
const LOPSIDED_FROM := 1.5
const LOPSIDED_CASUALTY_STEP := 0.30
const LOPSIDED_MORALE_STEP := 0.05

const UNIT_TYPES := {
	"field_repair_company":{"name":"Field Repair Company","attack":0.0,"defense":0.5,"organization":1.0},
	"medical_detachment":{"name":"Medical Detachment","attack":0.0,"defense":0.5,"organization":1.0},
	"levy": {"name": "Levy", "attack": 0.65, "defense": 0.55, "organization": 0.65},
	"line_infantry": {"name": "Line Infantry", "attack": 1.00, "defense": 1.00, "organization": 1.00},
	"skirmisher": {"name": "Skirmisher", "attack": 0.85, "defense": 0.60, "organization": 0.85},
	"cavalry": {"name": "Cavalry", "attack": 1.35, "defense": 0.72, "organization": 0.90},
	"siege_engineer": {"name":"Siege Engineers","attack":0.72,"defense":0.68,"organization":0.92},
	"field_artillery":{"name":"Field Artillery","attack":1.55,"defense":0.42,"organization":0.78},
	"rifle_infantry":{"name":"Rifle Infantry","attack":1.42,"defense":1.28,"organization":1.08},
	"machine_gun_company":{"name":"Machine-Gun Company","attack":1.72,"defense":1.88,"organization":1.02},
	"motorized_infantry":{"name":"Motorized Infantry","attack":1.65,"defense":1.30,"organization":1.12},
	"armored_formation":{"name":"Armored Formation","attack":2.35,"defense":1.78,"organization":1.08},
	"modern_artillery":{"name":"Modern Artillery","attack":2.20,"defense":0.68,"organization":0.92},
	"spearman":{"name": "Spearmen", "attack": 0.85, "defense": 1.18, "organization": 0.88},
	"axeman":{"name": "Axemen", "attack": 1.25, "defense": 0.65, "organization": 0.75},
	"slinger":{"name": "Slingers", "attack": 0.83, "defense": 0.48, "organization": 0.76},
	"javelineer":{"name": "Javelineers", "attack": 0.94, "defense": 0.57, "organization": 0.84},
	"archer":{"name": "Massed Archers", "attack": 1.12, "defense": 0.43, "organization": 0.78},
	"pikeman":{"name": "Pikemen", "attack": 0.9, "defense": 1.48, "organization": 1.18},
	"crossbowman":{"name": "Crossbowmen", "attack": 1.26, "defense": 0.66, "organization": 0.84},
	"heavy_swordsman":{"name": "Armored Swordsmen", "attack": 1.28, "defense": 1.32, "organization": 1.1},
	"light_infantry":{"name": "Light Infantry", "attack": 1.06, "defense": 0.71, "organization": 0.96},
	"mountain_infantry":{"name": "Mountain Infantry", "attack": 1.32, "defense": 1.43, "organization": 1.15},
	"light_cavalry":{"name": "Light Cavalry", "attack": 1.05, "defense": 0.6, "organization": 0.83},
	"horse_archer":{"name": "Horse Archers", "attack": 1.14, "defense": 0.68, "organization": 1.02},
	"chariot":{"name": "War Chariots", "attack": 1.45, "defense": 0.83, "organization": 0.8},
	"armored_cavalry":{"name": "Armored Cavalry", "attack": 1.68, "defense": 1.28, "organization": 0.94},
	"war_elephant":{"name": "War Elephants", "attack": 1.85, "defense": 1.35, "organization": 0.62},
	"dragoon":{"name": "Dragoons", "attack": 1.32, "defense": 0.99, "organization": 1.03},
	"ram_crew":{"name": "Battering Ram Crews", "attack": 0.48, "defense": 0.83, "organization": 0.82},
	"catapult_crew":{"name": "Catapult Crews", "attack": 1.17, "defense": 0.34, "organization": 0.76},
	"trebuchet_crew":{"name": "Trebuchet Crews", "attack": 1.4, "defense": 0.31, "organization": 0.82},
	"bombard_crew":{"name": "Bombard Crews", "attack": 1.52, "defense": 0.32, "organization": 0.76},
	"horse_artillery":{"name": "Horse Artillery", "attack": 1.4, "defense": 0.44, "organization": 0.88},
	"mortar_crew":{"name": "Mortar Teams", "attack": 1.58, "defense": 0.57, "organization": 0.91},
	"rocket_artillery":{"name": "Rocket Artillery", "attack": 2.35, "defense": 0.51, "organization": 0.8},
	"hand_cannoneer":{"name": "Hand Cannoneers", "attack": 1.15, "defense": 0.51, "organization": 0.65},
	"musketeer":{"name": "Musketeers", "attack": 1.35, "defense": 0.82, "organization": 1.05},
	"grenadier":{"name": "Grenadiers", "attack": 1.53, "defense": 0.91, "organization": 1.12},
	"sharpshooter":{"name": "Sharpshooters", "attack": 1.38, "defense": 0.71, "organization": 1.07},
	"assault_infantry":{"name": "Assault Infantry", "attack": 1.75, "defense": 1.05, "organization": 1.2},
	"marines":{"name": "Marines", "attack": 1.48, "defense": 1.24, "organization": 1.24},
	"paratrooper":{"name": "Airborne Infantry", "attack": 1.44, "defense": 1.17, "organization": 1.3},
	"combat_engineer":{"name": "Combat Engineers", "attack": 1.18, "defense": 1.39, "organization": 1.16},
	"anti_tank":{"name": "Antitank Teams", "attack": 1.22, "defense": 1.21, "organization": 1.02},
	"anti_air":{"name": "Antiaircraft Batteries", "attack": 0.74, "defense": 1.12, "organization": 0.99},
	"armored_car":{"name": "Armored Reconnaissance", "attack": 1.28, "defense": 1.2, "organization": 1.06},
	"light_tank":{"name": "Light Tanks", "attack": 1.87, "defense": 1.43, "organization": 0.98},
	"heavy_tank":{"name": "Heavy Tanks", "attack": 2.62, "defense": 2.24, "organization": 0.97},
	"tank_destroyer":{"name": "Tank Destroyers", "attack": 2.08, "defense": 1.5, "organization": 1.03},
	"mechanized_infantry":{"name": "Mechanized Infantry", "attack": 1.98, "defense": 1.82, "organization": 1.22},
	"air_assault":{"name": "Air Assault Infantry", "attack": 1.63, "defense": 1.2, "organization": 1.27},
	"networked_infantry":{"name":"Networked Infantry","attack":1.55,"defense":1.45,"organization":1.25},
	"main_battle_tank":{"name":"Main Battle Tanks","attack":2.9,"defense":2.5,"organization":1.1},
	"precision_fires":{"name":"Precision Fires","attack":2.5,"defense":0.6,"organization":0.95},
	"drone_operators":{"name":"Drone Teams","attack":1.4,"defense":0.9,"organization":1.1},
	"counter_drone_battery":{"name":"Counter-Drone Batteries","attack":0.9,"defense":1.2,"organization":1.0},
	"robot_vehicle_company":{"name":"Robotic Combat Vehicles","attack":1.8,"defense":1.5,"organization":1.2},
	"exosuit_infantry":{"name":"Exosuit Infantry","attack":1.7,"defense":1.6,"organization":1.3},
	"combat_frame_cohort":{"name":"Combat Frames","attack":1.6,"defense":1.5,"organization":1.4}
}

const Ledger := preload("res://scripts/equipment_ledger.gd")
## Per-man battle stats of every land kit, read from the equipment ledger.
const WEAPONS := {
	"shield_spear":preload("res://scripts/armor_equipment.gd").KITS.shield_spear,
	"padded_spear":preload("res://scripts/armor_equipment.gd").KITS.padded_spear,
	"lamellar_spear":preload("res://scripts/armor_equipment.gd").KITS.lamellar_spear,
	"scale_spear":preload("res://scripts/armor_equipment.gd").KITS.scale_spear,
	"mail_spear":preload("res://scripts/armor_equipment.gd").KITS.mail_spear,
	"plate_spear":preload("res://scripts/armor_equipment.gd").KITS.plate_spear,
	"improvised":Ledger.KITS.improvised,
	"spear":Ledger.KITS.spear,
	"axe":Ledger.KITS.axe,
	"sword_shield":Ledger.KITS.sword_shield,
	"pike":Ledger.KITS.pike,
	"sling":Ledger.KITS.sling,
	"bow":Ledger.KITS.bow,
	"javelin":Ledger.KITS.javelin,
	"mounted_bow":Ledger.KITS.mounted_bow,
	"crossbow":Ledger.KITS.crossbow,
	"chariot_kit":Ledger.KITS.chariot_kit,
	"lance":Ledger.KITS.lance,
	"elephant_kit":Ledger.KITS.elephant_kit,
	"armored_lance":Ledger.KITS.armored_lance,
	"dragoon_kit":Ledger.KITS.dragoon_kit,
	"hand_cannon":Ledger.KITS.hand_cannon,
	"musket":Ledger.KITS.musket,
	"grenadier_kit":Ledger.KITS.grenadier_kit,
	"marksman_rifle":Ledger.KITS.marksman_rifle,
	"mountain_kit":Ledger.KITS.mountain_kit,
	"service_rifle":Ledger.KITS.service_rifle,
	"marine_kit":Ledger.KITS.marine_kit,
	"engineering_kit":Ledger.KITS.engineering_kit,
	"assault_kit":Ledger.KITS.assault_kit,
	"airborne_kit":Ledger.KITS.airborne_kit,
	"air_assault_kit":Ledger.KITS.air_assault_kit,
	"networked_rifle":Ledger.KITS.networked_rifle,
	"exosuit":Ledger.KITS.exosuit,
	"machine_gun":Ledger.KITS.machine_gun,
	"mortar":Ledger.KITS.mortar,
	"anti_tank_kit":Ledger.KITS.anti_tank_kit,
	"anti_air_gun":Ledger.KITS.anti_air_gun,
	"laser_point_defence":Ledger.KITS.laser_point_defence,
	"ram":Ledger.KITS.ram,
	"siege_kit":Ledger.KITS.siege_kit,
	"catapult":Ledger.KITS.catapult,
	"trebuchet":Ledger.KITS.trebuchet,
	"bombard":Ledger.KITS.bombard,
	"field_gun":Ledger.KITS.field_gun,
	"horse_gun":Ledger.KITS.horse_gun,
	"modern_field_gun":Ledger.KITS.modern_field_gun,
	"rocket_launcher":Ledger.KITS.rocket_launcher,
	"precision_launcher":Ledger.KITS.precision_launcher,
	"motorized_kit":Ledger.KITS.motorized_kit,
	"armored_car_kit":Ledger.KITS.armored_car_kit,
	"light_tank_kit":Ledger.KITS.light_tank_kit,
	"armored_vehicle":Ledger.KITS.armored_vehicle,
	"heavy_tank_kit":Ledger.KITS.heavy_tank_kit,
	"tank_destroyer_kit":Ledger.KITS.tank_destroyer_kit,
	"mechanized_kit":Ledger.KITS.mechanized_kit,
	"main_battle_tank":Ledger.KITS.main_battle_tank,
	"drone_team":Ledger.KITS.drone_team,
	"robotic_vehicle":Ledger.KITS.robotic_vehicle,
	"combat_frame":Ledger.KITS.combat_frame,
	"repair_kit":Ledger.KITS.repair_kit,
	"medical_kit":Ledger.KITS.medical_kit
}


## Men per set (below one, a man runs several machines), rounds per firing
## element and the round's kind, all from the equipment ledger.
static func crew_for(weapon_id:String)->float:
	return float(_kit(weapon_id)[2])

## [hardness, armor, crew] of a kit, read from the ledger once: the battle
## asks them for every formation in every exchange.
static var _kits:Dictionary={}
static func _kit(weapon_id:String)->Array:
	var known:Variant=_kits.get(weapon_id)
	if known!=null: return known
	var row:=Ledger.row(weapon_id)
	var armor:=float(row.get("armor",0.0))
	var entry:=[clampf((armor-0.3)/1.2,0.0,1.0),armor,Ledger.crew(weapon_id) if not row.is_empty() else 1.0]
	_kits[weapon_id]=entry
	return entry

static func ammo_per(weapon_id:String)->int:
	return maxi(0,int(Ledger.row(weapon_id).get("ammo_per",0)))

static func ammo_type(weapon_id:String)->String:
	return String(Ledger.row(weapon_id).get("ammo",""))

## Machines (equipment_ledger crew below one): a formation's count is its
## operators or supervisors, each running several machines. The ledger gives
## a machine's stats; a man fights with all of his machines, cannot fight
## without them, and a blow on the formation mostly destroys machines
## (crewless share) rather than killing him.
static func machines_per_man(weapon_id:String)->float:
	var crew:=crew_for(weapon_id)
	return 1.0/crew if crew<1.0 else 1.0

static func is_machine(weapon_id:String)->bool:
	return crew_for(weapon_id)<1.0

## Stores (fodder, fuel, rounds, spares) a kit asks of the supply line besides
## bread, per man (equipment_ledger.gd supply). A kit living on them (three
## loads or more a man a day: horses, guns, vehicles, machines) fights weaker
## when its band's stores run short, down to 35%. Rounds alone are the
## ammunition rule's business.
const STORES_FLOOR:=0.35
const STORES_DEPENDENT:=3.0

static func stores_factor(weapon_id:String,share:float)->float:
	if share>=1.0 or not Ledger.has(weapon_id): return 1.0
	if Ledger.supply(weapon_id)/Ledger.crew(weapon_id)<STORES_DEPENDENT: return 1.0
	return STORES_FLOOR+(1.0-STORES_FLOOR)*clampf(share,0.0,1.0)

## Armour, HOI4's way but once: a formation is as "hard" as its kit's armour
## makes it (cloth 0, mail about half, plate and tanks nearly all). Fire at a
## hard target gets through by how well it pierces that armour: all of it
## when the pierce matches the armour, falling steeply below, never under the
## floor. Rifles hardly scratch a heavy tank; an antitank gun does.
const PIERCE_FLOOR:=0.10
const PIERCE_STEEPNESS:=2.5

static func kit_hardness(weapon_id:String)->float:
	return float(_kit(weapon_id)[0])

static func pierce_factor(pierce:float,armor:float)->float:
	if armor<=0.0 or pierce>=armor: return 1.0
	return clampf(pow(maxf(0.0,pierce)/armor,PIERCE_STEEPNESS),PIERCE_FLOOR,1.0)

## The enemy's armour as our fire meets it: the hard share of its men (by
## kit and issued sets) and the armour of that hard part.
func _armor_profile(formations:Array)->Dictionary:
	var men:=0.0
	var hard:=0.0
	var armor:=0.0
	for formation in formations:
		var count:=float(maxi(0,int(formation.get("count",0))))
		if count<=0.0: continue
		men+=count
		var kit:=_kit(String(formation.get("weapon","improvised")))
		if float(kit[0])<=0.0: continue
		var h:=float(kit[0])*issued_equipment_ratio(formation)
		hard+=count*h
		armor+=count*h*float(kit[1])
	return {"hard":hard/men if men>0.0 else 0.0,"armor":armor/hard if hard>0.0 else 0.0}

## The enemy's fire by pierce: [pierce, weight] pairs, weight = men x base attack.
func _fire_profile(formations:Array)->Array:
	var by_pierce:={}
	for formation in formations:
		var count:=float(maxi(0,int(formation.get("count",0))))
		if count<=0.0: continue
		var weapon_id:=String(formation.get("weapon","improvised"))
		var weapon:Dictionary=WEAPONS.get(weapon_id,WEAPONS.improvised)
		var unit:Dictionary=UNIT_TYPES.get(String(formation.get("unit","levy")),UNIT_TYPES.levy)
		var pierce:=float(weapon.get("penetration",0.0))
		by_pierce[pierce]=float(by_pierce.get(pierce,0.0))+count*float(unit.attack)*float(weapon.attack)*(0.22+issued_equipment_ratio(formation)*0.78)
	var fire:=[]
	for pierce in by_pierce: fire.append([float(pierce),float(by_pierce[pierce])])
	return fire

## Share of the enemy's fire that gets through a formation's armour.
static func _through(fire:Array,weapon_id:String,equipment_ratio:float)->float:
	var kit:=_kit(weapon_id)
	var hardness:=float(kit[0])*equipment_ratio
	if hardness<=0.0 or fire.is_empty(): return 1.0
	var armor:=float(kit[1])
	var total:=0.0
	var passed:=0.0
	for pair in fire:
		total+=float(pair[1])
		passed+=float(pair[1])*pierce_factor(float(pair[0]),armor)
	var share:=passed/total if total>0.0 else 1.0
	return (1.0-hardness)+hardness*share

# Attack multipliers against the opposing unit mix. Unlisted matchups are 1.0.
# These are intentionally data, not branches, so discoveries can replace or
# extend the table later without rewriting battle resolution.
const MATCHUPS := {
	"levy": {"line_infantry": 0.82, "cavalry": 0.72},
	"line_infantry": {"levy": 1.18, "skirmisher": 1.08, "cavalry": 1.48},
	"skirmisher": {"levy": 1.28, "line_infantry": 0.82, "cavalry": 0.68},
	"cavalry": {"levy": 1.20, "line_infantry": 0.62, "skirmisher": 1.45}
	,"siege_engineer":{"levy":0.82,"line_infantry":0.78,"cavalry":0.62},
	"field_artillery":{"levy":1.35,"line_infantry":1.22,"cavalry":0.58,"siege_engineer":1.18},
	"rifle_infantry":{"levy":1.75,"line_infantry":1.48,"cavalry":1.55},
	"machine_gun_company":{"levy":2.10,"line_infantry":1.85,"cavalry":2.20,"rifle_infantry":1.28},
	"motorized_infantry":{"levy":1.85,"line_infantry":1.60,"skirmisher":1.70,"machine_gun_company":0.82},
	"armored_formation":{"levy":2.25,"line_infantry":2.00,"rifle_infantry":1.65,"machine_gun_company":1.18},
	"modern_artillery":{"levy":1.95,"line_infantry":1.72,"rifle_infantry":1.55,"armored_formation":0.92},
	"spearman":{"cavalry": 1.5, "light_cavalry": 1.6, "armored_cavalry": 1.4, "archer": 0.7, "crossbowman": 0.72},
	"axeman":{"line_infantry": 1.25, "heavy_swordsman": 1.1, "archer": 0.8},
	"slinger":{"levy": 1.3, "pikeman": 1.3, "heavy_swordsman": 0.85, "cavalry": 0.65},
	"javelineer":{"levy": 1.3, "pikeman": 1.3, "heavy_swordsman": 0.85, "cavalry": 0.65},
	"archer":{"levy": 1.3, "pikeman": 1.3, "heavy_swordsman": 0.85, "cavalry": 0.65},
	"pikeman":{"cavalry": 1.5, "light_cavalry": 1.6, "armored_cavalry": 1.4, "archer": 0.7, "crossbowman": 0.72},
	"crossbowman":{"levy": 1.3, "pikeman": 1.3, "heavy_swordsman": 0.85, "cavalry": 0.65},
	"light_cavalry":{"archer": 1.4, "slinger": 1.5, "skirmisher": 1.35, "pikeman": 0.55, "spearman": 0.72},
	"horse_archer":{"archer": 1.4, "slinger": 1.5, "skirmisher": 1.35, "pikeman": 0.55, "spearman": 0.72},
	"chariot":{"archer": 1.4, "slinger": 1.5, "skirmisher": 1.35, "pikeman": 0.55, "spearman": 0.72},
	"armored_cavalry":{"archer": 1.4, "slinger": 1.5, "skirmisher": 1.35, "pikeman": 0.55, "spearman": 0.72},
	"war_elephant":{"levy": 1.7, "line_infantry": 1.25, "javelineer": 0.55, "horse_archer": 0.6},
	"assault_infantry":{"machine_gun_company": 1.3, "rifle_infantry": 1.15, "armored_formation": 0.6},
	"anti_tank":{"armored_formation": 1.8, "light_tank": 2.0, "heavy_tank": 1.5, "mechanized_infantry": 1.4, "rifle_infantry": 0.65, "assault_infantry": 0.6},
	"tank_destroyer":{"armored_formation": 1.8, "light_tank": 2.0, "heavy_tank": 1.5, "mechanized_infantry": 1.4, "rifle_infantry": 0.65, "assault_infantry": 0.6},
	# The last age: drones strike armour from above; counter-drone batteries
	# undo drones and robots; precision fires find guns and depots.
	"drone_operators":{"main_battle_tank":1.4,"heavy_tank":1.4,"armored_formation":1.4,"robot_vehicle_company":1.3,"precision_fires":1.5,"modern_artillery":1.5,"networked_infantry":1.15},
	"counter_drone_battery":{"drone_operators":2.4,"robot_vehicle_company":1.6,"combat_frame_cohort":1.6},
	"precision_fires":{"modern_artillery":1.6,"rocket_artillery":1.6,"precision_fires":1.4,"main_battle_tank":1.2},
	"main_battle_tank":{"heavy_tank":1.3,"light_tank":1.3,"armored_formation":1.3,"networked_infantry":1.1},
	"networked_infantry":{"rifle_infantry":1.3,"assault_infantry":1.2,"motorized_infantry":1.2},
	"combat_frame_cohort":{"networked_infantry":1.25,"rifle_infantry":1.4,"exosuit_infantry":1.1}
}


func equipment_required_for_weapon(weapon_id:String,authorized_count:int)->int:
	return ceili(float(maxi(0,authorized_count))/crew_for(weapon_id)-0.000001)


func ammunition_required_for_weapon(weapon_id:String,equipment_required:int,authorized_count:int)->int:
	if ammo_per(weapon_id)<=0: return 0
	var elements:=authorized_count if weapon_id in ["bow","service_rifle"] else equipment_required
	return maxi(0,elements)*ammo_per(weapon_id)


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
		var default_equipment_required:=equipment_required_for_weapon(weapon_id,authorized_count)
		var equipment_required := maxi(0,int(formation.get("equipment_required",default_equipment_required)))
		var equipment := clampi(int(formation.get("equipment",count)),0,equipment_required)
		var default_ammunition_required:=ammunition_required_for_weapon(weapon_id,equipment_required,authorized_count)
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
		armor_total += count * float(weapon.armor) * issued_equipment_ratio(formation)
		penetration_total += count * float(weapon.penetration) * issued_equipment_ratio(formation)
		normalized.append({"id":int(formation.get("id",-1)),"unit":unit_id,"weapon":weapon_id,"count":count,"authorized_count":authorized_count,"equipment":equipment,"equipment_required":equipment_required,"ammunition":ammunition,"ammunition_required":ammunition_required,"training":training,"experience":experience,"personnel_condition":clampf(float(formation.get("personnel_condition",1.0)),0.0,1.0),"readiness":clampf(float(formation.get("readiness",readiness)),0.0,1.5),"prototype":bool(formation.get("prototype",false)),"wear_accumulator":float(formation.get("wear_accumulator",0.0))})
		normalized[-1]["doctrines"]=preload("res://scripts/combined_arms_doctrine.gd").clean(formation.get("doctrines",{}))
		normalized[-1]["visual_model"] = String(formation.get("visual_model", ""))
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
		# Campaign reserves are explicit numeric manpower cohorts. Forming a unit
		# cannot conjure an implicit percentage reserve.
		"reserve_manpower":0,
		"wounded_pool":0,
		"scattered_pool":0,
		"dead":0
	}


func simulate(attacker: Dictionary, defender: Dictionary, options: Dictionary = {}) -> Dictionary:
	var attacking_force := _normalize_force(attacker, "Attacker")
	var defending_force := _normalize_force(defender, "Defender")
	# Short stores (fodder, fuel, rounds) weaken the kits that need them.
	attacking_force["stores_share"]=clampf(float(attacker.get("stores_share",1.0)),0.0,1.0)
	defending_force["stores_share"]=clampf(float(defender.get("stores_share",1.0)),0.0,1.0)
	var seed := int(options.get("seed", 1))
	var terrain_defense := clampf(float(options.get("terrain_defense", 1.0)), 0.5, 2.0)
	var casualty_intensity:=clampf(float(options.get("casualty_intensity",1.0)),0.20,2.0)
	var attacker_exposure_modifier:=clampf(float(options.get("attacker_exposure_modifier",1.0)),0.50,2.0)
	var defender_exposure_modifier:=clampf(float(options.get("defender_exposure_modifier",1.0)),0.50,2.0)
	var siege_reduction:=_siege_terrain_reduction(attacking_force)
	var effective_terrain_defense:=lerpf(terrain_defense,1.0,siege_reduction) if terrain_defense>1.0 else terrain_defense
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	# The generals' chosen tactics (battle_tactics.gd) shape each round's
	# exposure within fixed bounds. Absent a plan nothing changes.
	var tactics:Dictionary=options.get("tactics",{}) if options.get("tactics") is Dictionary else {}
	var plan:=tactics
	var round_offset:=maxi(0,int(options.get("round_offset",0)))
	# The block battle (battle_blocks.gd): carried between the campaign's
	# single-exchange calls, or begun here for a battle fought in one call.
	var carried:=options.get("battle") is Dictionary and not (options.get("battle") as Dictionary).is_empty()
	var block_options:=options.duplicate(false)
	block_options["tactics"]=tactics
	# A carried battle is advanced in place: the caller keeps the result's.
	var state:Dictionary=options.get("battle") if carried else Blocks.begin(attacking_force,defending_force,block_options)
	var round_limit := clampi(int(options.get("max_rounds", MAX_ROUNDS if carried else maxi(MAX_ROUNDS,int(state.get("max_exchanges",MAX_ROUNDS))))), 1, Blocks.MAX_EXCHANGES)
	var river:=bool((state.get("ground",{}) as Dictionary).get("river",false))
	var hungry:={"attacker":preload("res://scripts/field_rations.gd").is_hungry(attacker),"defender":preload("res://scripts/field_rations.gd").is_hungry(defender)}
	var pursues:={"attacker":_pursues(tactics,"attacker",attacking_force),"defender":_pursues(tactics,"defender",defending_force)}

	var attacker_initial := int(attacking_force.troops)
	var defender_initial := int(defending_force.troops)
	var attacker_troops := attacker_initial
	var defender_troops := defender_initial
	var attacker_morale := float(attacking_force.morale)
	var defender_morale := float(defending_force.morale)
	var side_initial:={"attacker":maxi(1,int(state.initial.get("attacker",attacker_initial))),"defender":maxi(1,int(state.initial.get("defender",defender_initial)))}
	var rounds: Array[Dictionary] = []
	var last_why:Array=state.get("why",[])
	Blocks.reconcile(state,"attacker",attacking_force.get("formations",[]))
	Blocks.reconcile(state,"defender",defending_force.get("formations",[]))
	var where:={"attacker":Blocks.index_of(state,"attacker",maxi(1,(attacking_force.get("formations",[]) as Array).size())),"defender":Blocks.index_of(state,"defender",maxi(1,(defending_force.get("formations",[]) as Array).size()))}

	for round_number in range(1, round_limit + 1):
		if attacker_troops <= 0 or defender_troops <= 0:
			break
		if attacker_morale < MORALE_BREAK_AT or defender_morale < MORALE_BREAK_AT:
			break
		if Blocks.standing_men(state,"attacker")<=0 or Blocks.standing_men(state,"defender")<=0:
			break
		var battle_round:=round_number+round_offset
		# A phase is over: each general may change how he fights.
		if not plan.is_empty() and battle_round>1 and (battle_round-1)%int(state.phase_len)==0:
			var second_look:Dictionary=BattleTactics.rechoose(plan,{"progress":float(state.progress),"exchange":battle_round-1},seed+battle_round*104729)
			if not (second_look.changes as Dictionary).is_empty():
				plan=second_look.plan
				Blocks.note_tactics(state,second_look.changes,plan)
		elif battle_round==1 and not plan.is_empty():
			Blocks.note_tactics(state,{},plan)
		Blocks.deploy(state,plan)

		var attacker_cohorts := evaluate_force(attacking_force, defending_force, 1.0, true)
		var defender_cohorts := evaluate_force(defending_force, attacking_force, effective_terrain_defense, true)
		var attacker_commander:Dictionary=attacking_force.get("commander",{})
		var defender_commander:Dictionary=defending_force.get("commander",{})
		var attacker_weights:=Blocks.weights(state,"attacker",attacker_cohorts.size(),attacker_morale)
		var defender_weights:=Blocks.weights(state,"defender",defender_cohorts.size(),defender_morale)
		var attacker_front:=Blocks.front_men(state,"attacker")
		var defender_front:=Blocks.front_men(state,"defender")
		var attacker_side_factor:=(Blocks.RIVER_ATTACK if river else 1.0)*(Blocks.HUNGER_POWER if bool(hungry.attacker) else 1.0)
		var defender_side_factor:=Blocks.HUNGER_POWER if bool(hungry.defender) else 1.0
		var attacker_power := _cohort_power(attacker_cohorts,attacker_morale,float(attacking_force.readiness),float(attacker_commander.get("command",0.5)),attacker_weights)*attacker_side_factor
		var defender_power := _cohort_power(defender_cohorts,defender_morale,float(defending_force.readiness),float(defender_commander.get("command",0.5)),defender_weights)*defender_side_factor
		var total_power := maxf(MIN_EFFECTIVE_STRENGTH, attacker_power + defender_power)
		var attacker_share := attacker_power / total_power
		var defender_share := defender_power / total_power
		# Overrun at the first blow only (a hopeless fight from the start). A
		# side worn down later in a real battle breaks and runs by its morale,
		# and the battle ends as a battle, not as a fight "over at once".
		var overrun:=overrun_side(attacker_power,defender_power,attacker_front,defender_front,effective_terrain_defense) if int(state.exchange)==0 else ""
		if overrun!="":
			var exchange:=_overrun_exchange(overrun,attacking_force,defending_force,attacker_troops,defender_troops,attacker_power,defender_power,rng)
			attacker_troops=int(exchange.attacker_remaining); defender_troops=int(exchange.defender_remaining)
			attacker_morale=float(exchange.attacker_morale) if overrun=="attacker" else attacker_morale
			defender_morale=float(exchange.defender_morale) if overrun=="defender" else defender_morale
			var overrun_record:Dictionary=exchange.record
			overrun_record["round"]=round_number
			overrun_record["attacker_morale"]=attacker_morale
			overrun_record["defender_morale"]=defender_morale
			overrun_record["order_intensity"]=casualty_intensity
			# Booked on the blocks and, by kind, on the phase: the record's
			# phases add up to the exchange like any other.
			var attacker_hit:=Blocks.book_losses(state,"attacker",_block_loss_list(attacking_force,overrun_record.get("attacker_cohort_losses",[]),int(overrun_record.get("attacker_losses",0))),where.attacker)
			var defender_hit:=Blocks.book_losses(state,"defender",_block_loss_list(defending_force,overrun_record.get("defender_cohort_losses",[]),int(overrun_record.get("defender_losses",0))),where.defender)
			Blocks.book_kinds(state,"attacker",attacker_hit,overrun_record.get("attacker_casualties",{}))
			Blocks.book_kinds(state,"defender",defender_hit,overrun_record.get("defender_casualties",{}))
			var overrun_outcome:="attacker_victory" if overrun=="defender" else "defender_victory"
			var overrun_termination:=_termination_event(overrun_outcome,attacking_force,defending_force,attacker_troops,defender_troops,attacker_morale,defender_morale,rng,true)
			_event_overrun(state,overrun)
			last_why=_why(state,attacking_force,defending_force,attacker_cohorts,defender_cohorts,attacker_weights,defender_weights,effective_terrain_defense,river,hungry,{},plan,attacker_morale,defender_morale)
			overrun_record["progress"]=1.0 if overrun=="defender" else -1.0
			rounds.append(overrun_record)
			Blocks.after_exchange(state,plan,last_why,true)
			Blocks.finish(state,overrun_outcome,overrun_termination)
			return {
				"seed": seed,
				"outcome": overrun_outcome,
				"winner": _winner_name(overrun_outcome, attacking_force, defending_force),
				"round_count": rounds.size(),
				"rounds": rounds,
				"attacker": _force_result(attacking_force, attacker_initial, attacker_troops, attacker_morale),
				"defender": _force_result(defending_force, defender_initial, defender_troops, defender_morale),
				"terrain_defense": terrain_defense,
				"effective_terrain_defense":effective_terrain_defense,
				"siege_terrain_reduction":siege_reduction,
				"tactics":tactics.duplicate(true),
				"plan_now":plan.duplicate(true),
				"termination":overrun_termination,
				"overrun":true,
				"battle":state
			}
		# Lopsided but not overwhelming: the weaker side bleeds and wavers faster.
		var odds:=clampf(maxf(attacker_power,defender_power)/maxf(MIN_EFFECTIVE_STRENGTH,minf(attacker_power,defender_power)),1.0,OVERRUN_RATIO)
		var crush:=1.0+maxf(0.0,odds-LOPSIDED_FROM)*LOPSIDED_CASUALTY_STEP
		var attacker_weaker:=attacker_power<defender_power
		var engagement:=_engagement_context(rng,attacker_share,defender_share,attacker_morale,defender_morale,effective_terrain_defense)
		var tactic_round:Dictionary=BattleTactics.round_effects(plan,battle_round,attacker_share,attacker_morale,defender_morale)
		var attacker_variance := _casualty_variance(rng)
		var defender_variance := _casualty_variance(rng)
		var river_exposure:=Blocks.RIVER_EXPOSURE if river else 1.0
		# How much of the line is struck in half an hour in this age.
		var lethality:=float(Blocks.LETHALITY[clampi(int(state.get("era",0)),0,Blocks.LETHALITY.size()-1)])

		# Casualties are based on the opposing force's share of power. They are
		# calculated before either side is reduced, so each round is simultaneous.
		# Only the men in the line can be struck; the reserve waits.
		var attacker_losses := mini(attacker_troops, maxi(0, roundi(float(attacker_front) * BASE_CASUALTY_RATE * lethality * defender_share * 2.0 * defender_variance * float(engagement.intensity) * casualty_intensity * float(engagement.attacker_exposure) * attacker_exposure_modifier * float(tactic_round.attacker) * float(tactic_round.intensity) * river_exposure)))
		var defender_losses := mini(defender_troops, maxi(0, roundi(float(defender_front) * BASE_CASUALTY_RATE * lethality * attacker_share * 2.0 * attacker_variance * float(engagement.intensity) * casualty_intensity * float(engagement.defender_exposure) * defender_exposure_modifier * float(tactic_round.defender) * float(tactic_round.intensity) / effective_terrain_defense)))
		if crush>1.0:
			if attacker_weaker:
				attacker_losses=mini(attacker_troops,roundi(float(attacker_losses)*crush)); defender_losses=roundi(float(defender_losses)/crush)
			else:
				defender_losses=mini(defender_troops,roundi(float(defender_losses)*crush)); attacker_losses=roundi(float(attacker_losses)/crush)
		# A force in contact usually suffers at least one loss; true lulls may be bloodless.
		if attacker_losses==0 and float(engagement.intensity)>=0.65: attacker_losses=1
		if defender_losses==0 and float(engagement.intensity)>=0.65: defender_losses=1
		attacker_troops -= attacker_losses
		defender_troops -= defender_losses
		var attacker_cohort_result:=_apply_cohort_losses(attacking_force.get("formations", []), attacker_cohorts, attacker_losses,rng,engagement.get("attacker_target",-1),options.get("attacker_ordered_targets",{}),Blocks.exposure(state,"attacker",attacker_cohorts.size()))
		var defender_cohort_result:=_apply_cohort_losses(defending_force.get("formations", []), defender_cohorts, defender_losses,rng,engagement.get("defender_target",-1),options.get("defender_ordered_targets",{}),Blocks.exposure(state,"defender",defender_cohorts.size()))
		# Operators whose machines took the blow are not casualties; the
		# machines wrecked are counted for the report.
		_count_machines(attacking_force,attacker_cohort_result)
		_count_machines(defending_force,defender_cohort_result)
		attacker_troops+=int(attacker_cohort_result.get("restored",0)); attacker_losses-=int(attacker_cohort_result.get("restored",0))
		defender_troops+=int(defender_cohort_result.get("restored",0)); defender_losses-=int(defender_cohort_result.get("restored",0))
		var attacker_block_losses:=Blocks.book_losses(state,"attacker",_block_loss_list(attacking_force,attacker_cohort_result.losses,attacker_losses),where.attacker)
		var defender_block_losses:=Blocks.book_losses(state,"defender",_block_loss_list(defending_force,defender_cohort_result.losses,defender_losses),where.defender)
		var attacker_ammunition_used:=_consume_ammunition(attacker_cohort_result.formations,float(engagement.intensity)*casualty_intensity,rng)
		var defender_ammunition_used:=_consume_ammunition(defender_cohort_result.formations,float(engagement.intensity)*casualty_intensity,rng)
		var attacker_casualties:=_casualty_breakdown(attacker_losses,rng,float(engagement.intensity))
		var defender_casualties:=_casualty_breakdown(defender_losses,rng,float(engagement.intensity))
		attacking_force["formations"] = attacker_cohort_result.formations
		defending_force["formations"] = defender_cohort_result.formations
		_pool_casualties(attacking_force,attacker_casualties)
		_pool_casualties(defending_force,defender_casualties)
		attacking_force["troops"] = attacker_troops
		defending_force["troops"] = defender_troops
		Blocks.book_kinds(state,"attacker",attacker_block_losses,attacker_casualties)
		Blocks.book_kinds(state,"defender",defender_block_losses,defender_casualties)

		attacker_morale = _next_morale(attacker_morale,attacker_losses,maxi(1,attacker_initial),defender_share,float(attacker_commander.get("resolve",0.5)),lethality)
		defender_morale = _next_morale(defender_morale,defender_losses,maxi(1,defender_initial),attacker_share,float(defender_commander.get("resolve",0.5)),lethality)
		if crush>1.0:
			var dread:=maxf(0.0,odds-LOPSIDED_FROM)*LOPSIDED_MORALE_STEP*lethality
			if attacker_weaker: attacker_morale=maxf(0.0,attacker_morale-dread)
			else: defender_morale=maxf(0.0,defender_morale-dread)
		# Blocks lose heart; the worn-out break and run, and the army sees it.
		var sides:={"attacker":{"force":attacking_force,"cohorts":attacker_cohort_result,"casualties":attacker_casualties,"block_losses":attacker_block_losses,"share":defender_share,"commander":attacker_commander,"target":int(engagement.get("attacker_target",-1))},
			"defender":{"force":defending_force,"cohorts":defender_cohort_result,"casualties":defender_casualties,"block_losses":defender_block_losses,"share":attacker_share,"commander":defender_commander,"target":int(engagement.get("defender_target",-1))}}
		var morale_now:={"attacker":attacker_morale,"defender":defender_morale}
		var broke_now:={"attacker":0,"defender":0}
		var losses_now:={"attacker":attacker_losses,"defender":defender_losses}
		for side in ["attacker","defender"]:
			var part:Dictionary=sides[side]
			var enemy:="defender" if side=="attacker" else "attacker"
			var struck:=_blocks_of_formation(state,side,int(part.target))
			var breaking:=Blocks.wear(state,side,part.block_losses,float(losses_now[side])/float(side_initial[side]),float((part.commander as Dictionary).get("resolve",0.5)),float(morale_now[side]),bool(hungry[side]),struck)
			for b in breaking:
				# Once the whole army breaks, its blocks go with it: the rout is
				# the battle's ending (termination), not one block at a time.
				if float(morale_now[side])<MORALE_BREAK_AT: break
				# Machines do not lose heart and run: they fight on until wrecked.
				if is_machine(String(((state.sides[side].blocks as Array)[b] as Dictionary).get("weapon",""))): continue
				var men0:=int((state.sides[side].blocks as Array)[b].men0)
				var split:Dictionary=Blocks.break_block(state,side,b,rng,bool(pursues[enemy]),battle_round)
				var removed:=_remove_broken(part.force,part.cohorts,split)
				broke_now[side]=int(broke_now[side])+removed
				var casualties:Dictionary=part.casualties
				casualties["killed"]=int(casualties.get("killed",0))+int(split.killed)
				casualties["wounded"]=int(casualties.get("wounded",0))+int(split.wounded)
				casualties["scattered"]=int(casualties.get("scattered",0))+int(split.fled)
				casualties["captured"]=int(casualties.get("captured",0))+int(split.captured)
				_pool_casualties(part.force,{"killed":split.killed,"wounded":split.wounded,"scattered":split.fled,"captured":split.captured})
				var phase_losses:Dictionary=state.cur.losses[side]
				phase_losses.k=int(phase_losses.k)+int(split.killed); phase_losses.w=int(phase_losses.w)+int(split.wounded)
				phase_losses.f=int(phase_losses.f)+int(split.fled); phase_losses.c=int(phase_losses.c)+int(split.captured)
				# Seeing a body of their own run shakes the whole army.
				morale_now[side]=maxf(0.0,float(morale_now[side])-minf(0.25,float(men0)/float(side_initial[side])*0.9))
		attacker_morale=float(morale_now.attacker); defender_morale=float(morale_now.defender)
		attacker_troops-=int(broke_now.attacker); defender_troops-=int(broke_now.defender)
		attacker_losses+=int(broke_now.attacker); defender_losses+=int(broke_now.defender)
		attacking_force["troops"]=attacker_troops; defending_force["troops"]=defender_troops
		var quality:={"attacker":_quality(attacker_cohorts,1.0),"defender":_quality(defender_cohorts,1.0)}
		var progress:=Blocks.measure(state,quality,{"attacker":attacker_morale,"defender":defender_morale})
		var decided:=attacker_troops<=0 or defender_troops<=0 or attacker_morale<MORALE_BREAK_AT or defender_morale<MORALE_BREAK_AT or Blocks.standing_men(state,"attacker")<=0 or Blocks.standing_men(state,"defender")<=0
		var closes:=decided or (round_number==round_limit and not carried)
		# Why one side is winning: worked out when a phase closes (and at the start).
		var why:Array=[]
		if Blocks.closing(state,closes) or int(state.exchange)==0:
			why=_why(state,attacking_force,defending_force,attacker_cohorts,defender_cohorts,attacker_weights,defender_weights,effective_terrain_defense,river,hungry,tactic_round,plan,attacker_morale,defender_morale)
			last_why=why
		rounds.append({
			"round": round_number,
			"attacker_losses": attacker_losses,
			"defender_losses": defender_losses,
			"attacker_remaining": attacker_troops,
			"defender_remaining": defender_troops,
			"attacker_morale": attacker_morale,
			"defender_morale": defender_morale,
			"intensity":engagement.label,
			"order_intensity":casualty_intensity,
			"event":engagement.event,
			"tactic_event":String(tactic_round.event),
			"attacker_tactic_phase":String(tactic_round.attacker_phase),
			"defender_tactic_phase":String(tactic_round.defender_phase),
			"attacker_cohort_losses":attacker_cohort_result.losses,
			"defender_cohort_losses":defender_cohort_result.losses,
			"attacker_cohort_equipment_losses":attacker_cohort_result.equipment_losses,
			"defender_cohort_equipment_losses":defender_cohort_result.equipment_losses,
			"attacker_cohort_ammunition_used":attacker_ammunition_used,
			"defender_cohort_ammunition_used":defender_ammunition_used,
			"attacker_casualties":attacker_casualties,
			"defender_casualties":defender_casualties,
			"attacker_front":attacker_front,
			"defender_front":defender_front,
			"progress":progress
		})
		if String(tactic_round.event)!="": Blocks.note_event(state,{"k":"tactic_event","text":String(tactic_round.event),"side":String(tactic_round.get("event_side",""))})
		elif String(engagement.event)!="No decisive local event.": Blocks.note_event(state,{"k":"local","code":String(engagement.event)})
		Blocks.after_exchange(state,plan,why,closes)

	var outcome := _outcome(attacker_troops if Blocks.standing_men(state,"attacker")>0 else 0, defender_troops if Blocks.standing_men(state,"defender")>0 else 0, attacker_morale, defender_morale)
	var termination:=_termination_event(outcome,attacking_force,defending_force,attacker_troops,defender_troops,attacker_morale,defender_morale,rng)
	if outcome!="inconclusive" or not carried:
		Blocks.close_phase(state,plan,last_why)
		Blocks.finish(state,outcome,termination)
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
		"tactics":tactics.duplicate(true),
		"plan_now":plan.duplicate(true),
		"termination":termination,
		"battle":state
	}


## A new block battle between two forces (battle_blocks.gd), for a caller
## that fights it an exchange at a time and carries it between calls.
## options: ground, tactics, terrain_defense.
func open_battle(attacker:Dictionary,defender:Dictionary,options:Dictionary={})->Dictionary:
	return Blocks.begin(_normalize_force(attacker,"Attacker"),_normalize_force(defender,"Defender"),options)


## The whole army breaks when its will falls below this: the one break line
## (army_lines.gd), as _outcome, battle_blocks.gd and MilitaryCampaign read it.
const MORALE_BREAK_AT:=preload("res://scripts/army_lines.gd").BREAK


## Whether a side can ride down men who break: the plan says so, or (with no
## plan) a real share of the side is mounted.
func _pursues(plan:Dictionary,side:String,force:Dictionary)->bool:
	var entry:Variant=plan.get(side,{})
	if entry is Dictionary and (entry as Dictionary).has("pursuit"): return bool((entry as Dictionary).pursuit)
	return float(BattleTactics.profile(force).get("mobile",0.0))>=float(BattleTactics.PURSUIT.mobile)


## Adds an exchange's casualties to a force's pools.
func _pool_casualties(force:Dictionary,casualties:Dictionary)->void:
	force["wounded_pool"]=int(force.get("wounded_pool",0))+int(casualties.get("wounded",0))
	force["disabled_pool"]=int(force.get("disabled_pool",0))+int(casualties.get("disabled",0))
	force["severe_disabled_pool"]=int(force.get("severe_disabled_pool",0))+int(casualties.get("severe_disability",0))
	force["scattered_pool"]=int(force.get("scattered_pool",0))+int(casualties.get("scattered",0))
	force["captured_pool"]=int(force.get("captured_pool",0))+int(casualties.get("captured",0))
	force["captured_in_battle"]=int(force.get("captured_in_battle",0))+int(casualties.get("captured",0))
	force["dead"]=int(force.get("dead",0))+int(casualties.get("killed",0))


## Losses per formation for the blocks; a force with no formations (troops
## only) is one formation of everyone.
func _block_loss_list(force:Dictionary,cohort_losses:Array,total:int)->Array:
	if (force.get("formations",[]) as Array).is_empty(): return [total]
	return cohort_losses


## Takes a broken block's men out of their formations (and some of the kit
## they drop in the rout). Returns how many left.
func _remove_broken(force:Dictionary,cohort_result:Dictionary,split:Dictionary)->int:
	var formations:Array=force.get("formations",[])
	var removed:=0
	var per:Dictionary=split.get("per_formation",{})
	if formations.is_empty():
		for f in per: removed+=int(per[f])
		return removed
	for f in per:
		var index:=int(f)
		if index<0 or index>=formations.size(): continue
		var formation:Dictionary=formations[index]
		var before:=int(formation.get("count",0))
		var n:=mini(before,int(per[f]))
		if n<=0: continue
		formation["count"]=before-n
		var equipment:=int(formation.get("equipment",before))
		var dropped:=mini(equipment,roundi(float(equipment)*float(n)/maxf(1.0,float(before))*0.5))
		formation["equipment"]=equipment-dropped
		formations[index]=formation
		removed+=n
		var losses:Array=cohort_result.get("losses",[])
		if index<losses.size(): losses[index]=int(losses[index])+n
		var equipment_losses:Array=cohort_result.get("equipment_losses",[])
		if index<equipment_losses.size(): equipment_losses[index]=int(equipment_losses[index])+dropped
		_book_hardware(force,String(formation.get("weapon","")),dropped)
	force["formations"]=formations
	return removed


func _blocks_of_formation(state:Dictionary,side:String,formation_index:int)->Array:
	var out:Array=[]
	if formation_index<0: return out
	var blocks:Array=state.sides[side].blocks
	for b in blocks.size():
		for member in blocks[b].members:
			if int(member[0])==formation_index: out.append(b); break
	return out


## Fighting quality per man of each formation: sqrt(attack x defense) with the
## ground divided out (it is its own modifier).
func _quality(cohorts:Array[Dictionary],terrain:float)->PackedFloat32Array:
	var out:=PackedFloat32Array(); out.resize(cohorts.size())
	for i in cohorts.size():
		out[i]=sqrt(maxf(0.0,float(cohorts[i].attack)*float(cohorts[i].defense))/maxf(0.05,terrain))
	return out


func _event_overrun(state:Dictionary,weak:String)->void:
	Blocks.note_event(state,{"k":"overrun","side":weak})
	for block in state.live[weak]:
		if String(block.st) in ["front","reserve"] and int(block.men)<=0: block.st="broken"


## The signed modifiers actually used this exchange (battle_blocks.factors).
func _why(state:Dictionary,a:Dictionary,d:Dictionary,ac:Array[Dictionary],dc:Array[Dictionary],aw:PackedFloat32Array,dw:PackedFloat32Array,terrain:float,river:bool,hungry:Dictionary,tactic_round:Dictionary,plan:Dictionary,am:float,dm:float)->Array:
	var sides:={}
	for side in ["attacker","defender"]:
		var force:Dictionary=a if side=="attacker" else d
		var cohorts:Array[Dictionary]=ac if side=="attacker" else dc
		var w:PackedFloat32Array=aw if side=="attacker" else dw
		var t:=terrain if side=="defender" else 1.0
		var weighted:=0.0; var men:=0.0
		for i in cohorts.size():
			var n:=float(cohorts[i].count)*(float(w[i]) if i<w.size() else 1.0)
			weighted+=n*sqrt(maxf(0.0,float(cohorts[i].attack)*float(cohorts[i].defense))/maxf(0.05,t)); men+=n
		var cohesion:=0.0; var fatigue:=0.0; var front:=0.0
		var blocks:Array=state.sides[side].blocks
		for b in blocks.size():
			var block:Dictionary=state.live[side][b]
			if String(block.st)!="front": continue
			cohesion+=float(block.men)*float(block.c); fatigue+=float(block.men)*Blocks.fatigue_factor(int(block.fat)); front+=float(block.men)
		var commander:Dictionary=force.get("commander",{})
		sides[side]={"men":Blocks.standing_men(state,side),"front":Blocks.front_men(state,side),"quality":weighted/maxf(1.0,men),"terrain":t,
			"river":Blocks.RIVER_ATTACK if river and side=="attacker" else 1.0,"cohesion":cohesion/maxf(1.0,front) if front>0.0 else (am if side=="attacker" else dm),
			"readiness":float(force.get("readiness",1.0)),"command":0.90+clampf(float(commander.get("command",0.5)),0.0,1.0)*0.20,
			"fatigue":fatigue/maxf(1.0,front) if front>0.0 else 1.0,"hunger":Blocks.HUNGER_POWER if bool(hungry[side]) else 1.0}
	var ids:={"attacker":String((plan.get("attacker",{}) as Dictionary).get("id","")),"defender":String((plan.get("defender",{}) as Dictionary).get("id",""))}
	var surprise:=""
	for side in ["attacker","defender"]:
		if String(ids[side]) in ["dawn_raid","ambush"] and not tactic_round.is_empty() and absf(float(tactic_round.get("attacker",1.0))-float(tactic_round.get("defender",1.0)))>0.05: surprise=side
	return Blocks.factors(sides,{"attacker":float(tactic_round.get("attacker",1.0)),"defender":float(tactic_round.get("defender",1.0))},ids,surprise)


## Which side is overrun at these odds: "attacker", "defender" or "" (a real
## fight). Power is fighting power (numbers, arms, morale, readiness,
## command); the numbers must also be against the small side, so a few
## well-armed people are never "overrun" by a larger rabble they outclass.
static func overrun_side(attacker_power:float,defender_power:float,attacker_troops:int,defender_troops:int,terrain_defense:float=1.0)->String:
	# Nobody under arms on one side: the other walks in. A town with no one to
	# defend it is taken at once, never a battle both sides stand through.
	if defender_troops<=0 and attacker_troops>0: return "defender"
	if attacker_troops<=0 and defender_troops>0: return "attacker"
	if attacker_troops<=0 or defender_troops<=0: return ""
	var weak:="defender" if defender_power<=attacker_power else "attacker"
	var weak_power:=minf(attacker_power,defender_power); var strong_power:=maxf(attacker_power,defender_power)
	var weak_troops:=defender_troops if weak=="defender" else attacker_troops
	var strong_troops:=attacker_troops if weak=="defender" else defender_troops
	var odds:=strong_power/maxf(MIN_EFFECTIVE_STRENGTH,weak_power)
	var numbers:=float(strong_troops)/float(maxi(1,weak_troops))
	if odds>=OVERRUN_RATIO and numbers>=OVERRUN_MIN_NUMBERS: return weak
	# Weight of numbers. Fighting power scales with drill and kit, and a
	# green, half-armed band scores low on it; but at close quarters many
	# bodies still count. Effective odds are the geometric mean of the power
	# and head-count ratios, taken in favour of the more numerous side.
	var few:="defender" if defender_troops<=attacker_troops else "attacker"
	var few_troops:=mini(attacker_troops,defender_troops)
	var many:=float(maxi(attacker_troops,defender_troops))/float(maxi(1,few_troops))
	var effective:=effective_odds(attacker_power,defender_power,attacker_troops,defender_troops)
	if few=="attacker": effective=1.0/maxf(0.0001,effective)
	# Walls and ditches let a few hold against numbers: only fighting power
	# (which counts the defended ground) overruns a defended position.
	if few=="defender" and terrain_defense>DEFENDED_GROUND: return ""
	if many>=OVERRUN_RATIO and effective>=OVERRUN_NUMBERS_ODDS: return few
	if few_troops<=TINY_BAND and many>=TINY_BAND_RATIO and effective>=1.0: return few
	return ""


## Attacker's effective odds over the defender (above 1: the attacker is
## the stronger): the geometric mean of fighting power and numbers.
static func effective_odds(attacker_power:float,defender_power:float,attacker_troops:int,defender_troops:int)->float:
	var a:=maxf(MIN_EFFECTIVE_STRENGTH,attacker_power)*float(maxi(1,attacker_troops))
	var d:=maxf(MIN_EFFECTIVE_STRENGTH,defender_power)*float(maxi(1,defender_troops))
	return sqrt(a/d)


## The same test on two whole forces, before any exchange (the campaign uses
## it to settle a hopeless fight the day it starts).
## ground: the battle's ground (battle_blocks.GROUNDS); where it is too narrow
## for all to fight, only the men in the line count, as in the battle itself.
func overrun_expected(attacker:Dictionary,defender:Dictionary,terrain_defense:=1.0,ground:Dictionary={})->String:
	var a:=_normalize_force(attacker,"Attacker"); var d:=_normalize_force(defender,"Defender")
	var ac:=evaluate_force(a,d,1.0); var dc:=evaluate_force(d,a,clampf(terrain_defense,0.5,2.0))
	var state:=Blocks.begin(a,d,{"ground":ground,"terrain_defense":terrain_defense})
	var ap:=_cohort_power(ac,float(a.morale),float(a.readiness),float((a.get("commander",{}) as Dictionary).get("command",0.5)),Blocks.weights(state,"attacker",ac.size(),float(a.morale)))
	var dp:=_cohort_power(dc,float(d.morale),float(d.readiness),float((d.get("commander",{}) as Dictionary).get("command",0.5)),Blocks.weights(state,"defender",dc.size(),float(d.morale)))
	return overrun_side(ap,dp,Blocks.front_men(state,"attacker"),Blocks.front_men(state,"defender"),terrain_defense)


## Effective odds (stronger over weaker, at least 1) of two forces: fighting
## power weighed with numbers (effective_odds).
func odds_of(attacker:Dictionary,defender:Dictionary,terrain_defense:=1.0)->float:
	var odds:=raw_odds(attacker,defender,terrain_defense)
	return odds if odds>=1.0 else 1.0/maxf(0.0001,odds)

## The attacker's effective odds over the defender (below 1 when the defender
## is the stronger): the stated odds (war_odds.gd) read this.
func raw_odds(attacker:Dictionary,defender:Dictionary,terrain_defense:=1.0)->float:
	var a:=_normalize_force(attacker,"Attacker"); var d:=_normalize_force(defender,"Defender")
	var ap:=_cohort_power(evaluate_force(a,d,1.0),float(a.morale),float(a.readiness),float((a.get("commander",{}) as Dictionary).get("command",0.5)))
	var dp:=_cohort_power(evaluate_force(d,a,clampf(terrain_defense,0.5,2.0)),float(d.morale),float(d.readiness),float((d.get("commander",{}) as Dictionary).get("command",0.5)))
	return effective_odds(ap,dp,int(a.troops),int(d.troops))


## One exchange in which the weak side is overrun. The weak side: most of a
## small band is cut down on the spot (fewer of a large one, which breaks and
## runs); the rest are left broken for the victors to take or chase off. The
## strong side: a few hurt, in proportion to how many were there to resist.
func _overrun_exchange(weak:String,attacking_force:Dictionary,defending_force:Dictionary,attacker_troops:int,defender_troops:int,attacker_power:float,defender_power:float,rng:RandomNumberGenerator)->Dictionary:
	var strong:="attacker" if weak=="defender" else "defender"
	var forces:={"attacker":attacking_force,"defender":defending_force}
	var troops:={"attacker":attacker_troops,"defender":defender_troops}
	var odds:=maxf(attacker_power,defender_power)/maxf(MIN_EFFECTIVE_STRENGTH,minf(attacker_power,defender_power))
	var weak_troops:=int(troops[weak])
	# Share cut down: nearly all of a handful, about a third of a large host.
	var size_factor:=clampf(log(float(maxi(1,weak_troops)))/log(10.0)/3.0,0.0,1.0)
	var down_share:=clampf(lerpf(0.85,0.30,size_factor)+rng.randf_range(-0.12,0.12),0.15,1.0)
	var weak_down:=clampi(roundi(float(weak_troops)*down_share),mini(1,weak_troops),weak_troops)
	var weak_killed:=clampi(roundi(float(weak_down)*rng.randf_range(0.45,0.70)),0,weak_down)
	var weak_casualties:={"killed":weak_killed,"wounded":weak_down-weak_killed,"scattered":0,"disabled":floori(float(weak_down-weak_killed)*0.15),"severe_disability":0}
	# The victors: about one hurt for every twenty who resisted, fewer the
	# steeper the odds; a fraction becomes a chance, never a guaranteed loss.
	var expected:=float(weak_troops)*0.05*clampf(OVERRUN_RATIO/odds,0.2,1.0)
	var strong_losses:=floori(expected)+(1 if rng.randf()<expected-floorf(expected) else 0)
	strong_losses=mini(strong_losses,maxi(0,int(troops[strong])-1))
	var strong_killed:=0
	for k in strong_losses:
		if rng.randf()<0.2: strong_killed+=1
	var strong_casualties:={"killed":strong_killed,"wounded":strong_losses-strong_killed,"scattered":0,"disabled":0,"severe_disability":0}
	var losses:={weak:weak_down,strong:strong_losses}
	var casualties:={weak:weak_casualties,strong:strong_casualties}
	var result:={"record":{}}
	var record:Dictionary={"intensity":"Overrun","event":"OVERRUN","tactic_event":"","overrun":weak,
		"attacker_tactic_phase":"closing" if weak=="defender" else "hold","defender_tactic_phase":"closing" if weak=="attacker" else "hold"}
	for side in ["attacker","defender"]:
		var force:Dictionary=forces[side]
		var cohorts:=evaluate_force(force,forces["defender" if side=="attacker" else "attacker"],1.0)
		var applied:=_apply_cohort_losses(force.get("formations",[]),cohorts,int(losses[side]),rng)
		var ammunition:=_consume_ammunition(applied.formations,0.5 if side==strong else 0.2,rng)
		force["formations"]=applied.formations
		var c:Dictionary=casualties[side]
		# Operators whose machines took the blow are not casualties.
		_count_machines(force,applied)
		var restored:=int(applied.get("restored",0))
		if restored>0:
			losses[side]=int(losses[side])-restored
			c["killed"]=mini(int(c.killed),int(losses[side]))
			c["wounded"]=int(losses[side])-int(c.killed)
			c["disabled"]=mini(int(c.get("disabled",0)),int(c.wounded))
		force["wounded_pool"]=int(force.get("wounded_pool",0))+int(c.wounded)
		force["disabled_pool"]=int(force.get("disabled_pool",0))+int(c.disabled)
		force["dead"]=int(force.get("dead",0))+int(c.killed)
		var remaining:=int(troops[side])-int(losses[side])
		force["troops"]=remaining
		result[side+"_remaining"]=remaining
		record[side+"_losses"]=int(losses[side])
		record[side+"_remaining"]=remaining
		record[side+"_cohort_losses"]=applied.losses
		record[side+"_cohort_equipment_losses"]=applied.equipment_losses
		record[side+"_cohort_ammunition_used"]=ammunition
		record[side+"_casualties"]=c
	# The overrun side is broken; whoever is left is at the victors' mercy.
	result[weak+"_morale"]=0.0
	result["record"]=record
	return result


## Each formation's fighting stats against this opponent. lean: only count,
## attack and defense (the same numbers), for the exchange loop.
func evaluate_force(force: Dictionary, opponent: Dictionary, terrain_modifier := 1.0, lean:=false) -> Array[Dictionary]:
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
	var formation_attack_modifier:=maxf(0.0,float(force.get("attack_modifier",1.0)))*(1+clampf(float(force.get("joint_air_support",0)),0,.3))*(1-clampf(float(force.get("joint_air_pressure",0)),0,.25))
	var formation_defense_modifier:=maxf(0.05,float(force.get("defense_modifier",1.0)))
	# The enemy's mix is the same for every formation: weigh it once per arm.
	var matchups:Dictionary={}
	var stores_share:=clampf(float(force.get("stores_share",1.0)),0.0,1.0)
	var enemy_armor:=_armor_profile(enemy_formations)
	var enemy_hard:=float(enemy_armor.hard)
	# The enemy's fire by pierce matters only to our armoured formations.
	var own_hard:=false
	for formation in formations:
		if kit_hardness(String(formation.get("weapon","improvised")))>0.0:
			own_hard=true
			break
	var enemy_fire:=_fire_profile(enemy_formations) if own_hard else []
	for formation in formations:
		var unit_id := String(formation.get("unit", "levy"))
		var weapon_id := String(formation.get("weapon", "improvised"))
		var count := maxi(0, int(formation.get("count", 0)))
		var authorized_count:=int(formation.get("authorized_count",count))
		var default_equipment_required:=equipment_required_for_weapon(weapon_id,authorized_count)
		var equipment_required:=maxi(1,int(formation.get("equipment_required",default_equipment_required)))
		var equipment:=clampi(int(formation.get("equipment",count)),0,equipment_required)
		var equipment_ratio:=clampf(float(equipment)/float(equipment_required),0.0,1.0)
		var default_ammunition_required:=ammunition_required_for_weapon(weapon_id,equipment_required,authorized_count)
		var ammunition_required:=maxi(0,int(formation.get("ammunition_required",default_ammunition_required)))
		var ammunition:=clampi(int(formation.get("ammunition",ammunition_required)),0,ammunition_required)
		var ammunition_ratio:=clampf(float(ammunition)/maxf(1.0,float(ammunition_required)),0.0,1.0) if ammunition_required>0 else 1.0
		var ammunition_floor:=0.12 if weapon_id in ["field_gun","machine_gun","modern_field_gun","armored_vehicle"] else 0.30
		var ammunition_attack_factor:=ammunition_floor+ammunition_ratio*(1.0-ammunition_floor) if ammunition_required>0 else 1.0
		var unit: Dictionary = UNIT_TYPES.get(unit_id, UNIT_TYPES.levy)
		var weapon: Dictionary = WEAPONS.get(weapon_id, WEAPONS.improvised)
		var training:=clampf(float(formation.get("training",0.55 if unit_id=="levy" else 0.70)),0.25,1.25)
		var training_factor:=0.72+training*0.28
		var experience:=clampf(float(formation.get("experience",0.0)),0.0,1.0)
		var experience_factor:=0.94+experience*0.14
		var personnel_condition:=clampf(float(formation.get("personnel_condition",1.0)),0.0,1.0)
		var condition_factor:=0.72+personnel_condition*0.28
		if not matchups.has(unit_id): matchups[unit_id]=_weighted_matchup(unit_id, enemy_formations)
		var matchup:=float(matchups[unit_id])
		matchup=1.0+(matchup-1.0)*(0.65+tactics*0.70)
		var doctrine_defense:=preload("res://scripts/combined_arms_doctrine.gd").defense(formation,formations,enemy_formations)
		# Our blows against the enemy's hard share lose what our kit cannot pierce;
		# how much of the enemy's fire gets through our own armour sets where
		# our losses fall (_apply_cohort_losses).
		var piercing:=(1.0-enemy_hard)+enemy_hard*pierce_factor(float(weapon.penetration),float(enemy_armor.armor)) if enemy_hard>0.0 else 1.0
		var through:=_through(enemy_fire,weapon_id,equipment_ratio)
		var per_man:=machines_per_man(weapon_id)
		var machine:=per_man>1.0
		var armed_attack:=equipment_ratio if machine else 0.22+equipment_ratio*0.78
		var armed_defense:=0.20+equipment_ratio*0.80 if machine else 0.35+equipment_ratio*0.65
		var guard:=1.0+(per_man-1.0)*equipment_ratio
		if lean:
			result.append({"count":count,
				"attack":float(unit.attack)*float(weapon.attack)*per_man*matchup*piercing*stores_factor(weapon_id,stores_share)*armed_attack*ammunition_attack_factor*training_factor*experience_factor*condition_factor*formation_attack_modifier*float(formation.get("round_order_attack",1.0)),
				"defense":float(unit.defense)*float(weapon.defense)*guard*terrain_modifier*armed_defense*training_factor*experience_factor*condition_factor*formation_defense_modifier*doctrine_defense*float(formation.get("round_order_defense",1.0)),"through":through,"per_man":guard})
			continue
		result.append({
			"unit": unit_id, "weapon": weapon_id, "count": count,
			"attack":float(unit.attack)*float(weapon.attack)*per_man*matchup*piercing*stores_factor(weapon_id,stores_share)*armed_attack*ammunition_attack_factor*training_factor*experience_factor*condition_factor*formation_attack_modifier*float(formation.get("round_order_attack",1.0)),
			"defense":float(unit.defense)*float(weapon.defense)*guard*terrain_modifier*armed_defense*training_factor*experience_factor*condition_factor*formation_defense_modifier*doctrine_defense*float(formation.get("round_order_defense",1.0)),
			"doctrine_defense":doctrine_defense,"matchup":matchup,"piercing":piercing,"through":through,"per_man":guard,"terrain":terrain_modifier,"equipment":equipment,"equipment_required":equipment_required,"equipment_ratio":equipment_ratio,"ammunition":ammunition,"ammunition_required":ammunition_required,"ammunition_ratio":ammunition_ratio,"training":training,"experience":experience,"personnel_condition":personnel_condition
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
	var base_readiness:=manpower_fill*0.28+equipment_fill*0.27+condition*0.23+organization*0.14+ammunition_fill*0.08
	# Personnel, issued equipment, and required ammunition are operational gates.
	# An additive score alone let an empty battery appear almost fully ready.
	var gate_product:=manpower_fill*equipment_fill*(ammunition_fill if ammunition_required>0 else 1.0)
	var gate_dimensions:=3.0 if ammunition_required>0 else 2.0
	var operational_fill:=pow(maxf(0.0,gate_product),1.0/gate_dimensions)
	var aggregate:=base_readiness*(0.20+operational_fill*0.80)
	return {"aggregate":aggregate,"base_readiness":base_readiness,"operational_fill":operational_fill,"manpower":manpower_fill,"equipment":equipment_fill,"ammunition":ammunition_fill,"condition":condition,"organization":organization}


func advance_preparation_day(force: Dictionary, context: Dictionary = {}) -> Dictionary:
	var prepared:=force.duplicate(true)
	var commander:Dictionary=prepared.get("commander",{})
	var logistics:=clampf(float(commander.get("logistics",0.5)),0.0,1.0)
	var command:=clampf(float(commander.get("command",0.5)),0.0,1.0)
	var available_equipment:=maxi(0,roundi(float(context.get("equipment_replacements",0))*(0.65+logistics*0.70)))
	var organization_recovery:=clampf(float(context.get("organization_recovery",0.08)),0.0,0.30)
	organization_recovery*=0.70+command*0.60
	# Days of home preparation covered by one call (multi-day rival steps).
	var days:=float(context.get("days",1.0))
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
	prepared["morale"]=move_toward(float(prepared.get("morale",1.0)),1.0,organization_recovery*days)
	var scattered_available:=int(prepared.get("scattered_pool",0))
	var disabled:=clampi(int(prepared.get("disabled_pool",0)),0,int(prepared.get("wounded_pool",0)))
	var wounded_available:=int(prepared.get("wounded_pool",0))-disabled
	var reserves_available:=int(prepared.get("reserve_manpower",0))
	var recovery_multiplier:=clampf(float(context.get("recovery_multiplier",1.0)),0.10,1.60)
	var scattered_progress:=float(prepared.get("scattered_recovery_accumulator",0.0))+float(scattered_available)*(0.22+logistics*0.28)*days
	var wounded_progress:=float(prepared.get("wounded_recovery_accumulator",0.0))+float(wounded_available)*(0.035+logistics*0.055)*recovery_multiplier*days
	var scattered_return:=mini(scattered_available,maxi(0,floori(scattered_progress)))
	wounded_progress+=clampf(float(context.get("medical_recovery",0)),0,float(wounded_available))
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
		var required:=maxi(1,int(formation.get("equipment_required",equipment_required_for_weapon(String(formation.get("weapon","improvised")),authorized))))
		var equipped_capacity:=floori(authorized*clampf(float(equipment)/float(required),0,1))
		var capacity:=mini(maxi(0,authorized-count),maxi(0,equipped_capacity-count))
		var arrivals:=mini(manpower_queue,capacity)
		formation["count"]=count+arrivals
		if arrivals>0:
			formation["doctrines"]=preload("res://scripts/combined_arms_doctrine.gd").clean(formation.get("doctrines",{}))
			for doctrine:String in formation.doctrines:formation.doctrines[doctrine]*=float(count)/float(count+arrivals)
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
	prepared["wounded_pool"]=wounded_available-from_wounded+disabled
	prepared["reserve_manpower"]=reserves_available-from_reserves
	prepared["formations"]=formations
	preload("res://scripts/combined_arms_doctrine.gd").practice(formations,context.get("doctrine_levels",{}),float(context.get("doctrine_supply",0)))
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
		if String(formation.get("unit","")) not in ["siege_engineer","combat_engineer","ram_crew","catapult_crew","trebuchet_crew","bombard_crew"]:continue
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


func issued_equipment_ratio(formation:Dictionary)->float:
	var count:=maxi(0,int(formation.get("count",0)))
	var authorized:=maxi(0,int(formation.get("authorized_count",count)))
	var required:=maxi(1,int(formation.get("equipment_required",equipment_required_for_weapon(String(formation.get("weapon","improvised")),authorized))))
	return clampf(float(formation.get("equipment",count))/float(required),0,1)


## Fighting power. weights: per formation, the share of its men in the line
## (battle_blocks.weights); empty means everyone fights.
func _cohort_power(cohorts: Array[Dictionary], morale: float, readiness: float,command: float,weights:PackedFloat32Array=PackedFloat32Array()) -> float:
	var power := 0.0
	var weighted:=not weights.is_empty()
	for index in cohorts.size():
		var cohort:Dictionary=cohorts[index]
		var weight:=float(weights[index]) if weighted and index<weights.size() else 1.0
		power += float(cohort.count) * weight * sqrt(float(cohort.attack) * float(cohort.defense))
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
	# Severity is a bounded game assumption. No additional random draw changes
	# casualty totals or outcomes; disability is a subset of surviving wounds.
	var disabled:=floori(wounded*clampf(.08+intensity*.035,.08,.20))
	return {"killed":killed,"wounded":wounded,"scattered":losses-killed-wounded,"disabled":disabled,"severe_disability":floori(disabled*.35)}


func _apply_cohort_losses(formations: Array, cohorts: Array[Dictionary], losses: int,rng: RandomNumberGenerator,targeted_cohort: int=-1,ordered_targets:Dictionary={},line_exposure:PackedFloat32Array=PackedFloat32Array()) -> Dictionary:
	var updated: Array[Dictionary] = []
	var original_counts:Array[int]=[]
	var cohort_losses:Array[int]=[]
	var cohort_equipment_losses:Array[int]=[]
	for formation in formations:
		# Only counts and kit change here: a shallow copy leaves the input as it was.
		updated.append(formation.duplicate(false))
		original_counts.append(int(formation.get("count",0)))
		cohort_losses.append(0)
		cohort_equipment_losses.append(0)
	var contact_factors:Array[float]=[]
	for index in updated.size():
		var contact:=rng.randf_range(0.55,1.45)
		if index==targeted_cohort: contact*=2.25
		contact*=1.0+1.25*clampf(float(ordered_targets.get(str(index),0)),0,1)
		contact*=float(updated[index].get("round_order_exposure",1.0))
		# Men waiting in reserve are almost out of reach (battle_blocks.exposure).
		if index<line_exposure.size(): contact*=float(line_exposure[index])
		contact_factors.append(contact)
	var remaining_losses := losses
	if losses>LOSS_ONE_BY_ONE:
		remaining_losses=_spread_losses(updated,cohorts,contact_factors,cohort_losses,losses,rng)
	while remaining_losses > 0:
		var total_exposure:=0.0
		var exposures:Array[float]=[]
		for index in updated.size():
			var count := int(updated[index].get("count", 0))
			var defense := maxf(0.05, float(cohorts[index].defense))
			var exposure := float(count)*float(cohorts[index].get("per_man",1.0))/defense*contact_factors[index]*float(cohorts[index].get("through",1.0)) if count>0 else 0.0
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
	var restored:=0
	for index in updated.size():
		var personnel_losses:=original_counts[index]-int(updated[index].get("count",0))
		var old_equipment:=int(updated[index].get("equipment",original_counts[index]))
		var weapon_id:=String(updated[index].get("weapon","improvised"))
		if is_machine(weapon_id) and personnel_losses>0:
			# The blow falls on machines: each man's worth of loss destroys his
			# machines; only the crewless remainder kills the man himself.
			var machines_lost:=mini(old_equipment,roundi(float(personnel_losses)*machines_per_man(weapon_id)))
			# Blows that found machines mostly wreck them; blows beyond the
			# machines left fall on the operators themselves.
			var covered:=float(machines_lost)/machines_per_man(weapon_id)
			var men_lost:=clampi(roundi(float(personnel_losses)-covered*Ledger.crewless(weapon_id)),0,personnel_losses)
			var back:=personnel_losses-men_lost
			updated[index]["count"]=int(updated[index].get("count",0))+back
			cohort_losses[index]-=back
			restored+=back
			updated[index]["equipment"]=old_equipment-machines_lost
			cohort_equipment_losses[index]=machines_lost
			continue
		var personnel_loss_share:=float(personnel_losses)/maxf(1.0,float(original_counts[index]))
		var equipment_losses:=mini(old_equipment,roundi(float(old_equipment)*personnel_loss_share*0.72+float(old_equipment)*0.006))
		updated[index]["equipment"]=old_equipment-equipment_losses
		cohort_equipment_losses[index]=equipment_losses
	return {"formations":updated,"losses":cohort_losses,"equipment_losses":cohort_equipment_losses,"restored":restored}


## Many losses at once: each formation takes its share of them by exposure
## (count over defense, times contact), whole people by largest remainder,
## none more than it has. Returns what could not be placed (normally 0).
func _spread_losses(updated:Array,cohorts:Array[Dictionary],contact:Array[float],cohort_losses:Array[int],losses:int,rng:RandomNumberGenerator)->int:
	var exposures:Array[float]=[]
	var total:=0.0
	for index in updated.size():
		var count:=int(updated[index].get("count",0))
		var exposure:=float(count)*float(cohorts[index].get("per_man",1.0))/maxf(0.05,float(cohorts[index].defense))*contact[index]*float(cohorts[index].get("through",1.0)) if count>0 else 0.0
		exposures.append(exposure); total+=exposure
	if total<=0.0: return losses
	var left:=losses
	var remainders:Array[float]=[]
	for index in updated.size():
		var count:=int(updated[index].get("count",0))
		var exact:=float(losses)*exposures[index]/total
		var whole:=mini(count,floori(exact))
		updated[index]["count"]=count-whole; cohort_losses[index]+=whole; left-=whole
		remainders.append(exact-float(whole)+rng.randf()*0.001)
	while left>0:
		var best:=-1
		for index in updated.size():
			if int(updated[index].get("count",0))<=0: continue
			if best<0 or remainders[index]>remainders[best]: best=index
		if best<0: break
		updated[best]["count"]=int(updated[best].count)-1; cohort_losses[best]+=1; left-=1; remainders[best]=-1.0
	return left


func _consume_ammunition(formations:Array,intensity:float,rng:RandomNumberGenerator)->Array[int]:
	var used_by_cohort:Array[int]=[]
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var used:=0
		var weapon:=String(formation.get("weapon","improvised"))
		if ammo_per(weapon)>0:
			var available:=maxi(0,int(formation.get("ammunition",0)))
			var firing_elements:=maxi(0,int(formation.get("count",0))) if weapon in ["bow","service_rifle"] else maxi(0,int(formation.get("equipment",0)))
			var rounds_per_element:=maxf(0.25,float(ammo_per(weapon))*0.06)
			var desired:=maxi(0,roundi(float(firing_elements)*rounds_per_element*rng.randf_range(0.38,0.78)*clampf(intensity,0.25,1.50)))
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
		formation_force["attack_modifier"]=float(force.get("attack_modifier",1.0))
		formation_force["defense_modifier"]=float(force.get("defense_modifier",1.0))
		formation_force["commander"]=force.get("commander",{}).duplicate(true)
		formation_force["reserve_manpower"]=int(force.get("reserve_manpower",formation_force.get("reserve_manpower",0)))
		formation_force["wounded_pool"]=int(force.get("wounded_pool",0))
		formation_force["disabled_pool"]=int(force.get("disabled_pool",0))
		formation_force["severe_disabled_pool"]=int(force.get("severe_disabled_pool",0))
		formation_force["scattered_pool"]=int(force.get("scattered_pool",0))
		formation_force["captured_pool"]=int(force.get("captured_pool",0))
		# Men taken when blocks broke, over every day the battle has been fought.
		formation_force["captured_in_battle"]=int(force.get("captured_in_battle",0))
		formation_force["dead"]=int(force.get("dead",0))
		formation_force["stores_share"]=clampf(float(force.get("stores_share",1.0)),0.0,1.0)
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
	normalized["stores_share"]=clampf(float(force.get("stores_share",1.0)),0.0,1.0)
	normalized["commander"] = force.get("commander",{}).duplicate(true)
	for key in ["wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","captured_pool","captured_in_battle","dead"]: normalized[key]=int(force.get(key,0))
	return normalized


func _combat_power(force: Dictionary, opponent: Dictionary, troops: int, morale: float, terrain_modifier: float) -> float:
	var armor := float(force.get("armor", 0.0))
	var enemy_penetration := float(opponent.get("penetration", 1.0))
	var armor_advantage := 1.0 + maxf(0.0, armor - enemy_penetration) * 0.35
	return float(troops) * float(force.attack) * float(force.defense) * float(force.readiness) * maxf(MIN_EFFECTIVE_STRENGTH, morale) * terrain_modifier * armor_advantage


## tempo: the age's pace (battle_blocks.LETHALITY): being outfought wears a
## dispersed, dug-in line down over hours, not in one half hour.
## Will wears toward the one break line (a quarter, army_lines.gd) at the
## pace that once took it to 0.15: WEAR_TO_BREAK keeps the hours a battle
## lasts in each age (the battle evaluation's historical ranges).
const WEAR_TO_BREAK:=(1.0-MORALE_BREAK_AT)/0.85
## How deep below the break line a beaten side's collapse is measured.
const COLLAPSE_SPAN:=0.22/0.15
func _next_morale(current: float, losses: int, initial_troops: int, enemy_power_share: float,resolve: float,tempo:float=1.0) -> float:
	var casualty_shock := float(losses) / float(initial_troops) * 1.8
	var pressure := maxf(0.0, enemy_power_share - 0.5) * 0.08 * clampf(tempo,0.0,1.0)
	var resolve_protection:=0.78+clampf(resolve,0.0,1.0)*0.34
	return clampf(current-(casualty_shock+pressure)/resolve_protection*WEAR_TO_BREAK,0.0,1.5)


func _outcome(attacker_troops: int, defender_troops: int, attacker_morale: float, defender_morale: float) -> String:
	var attacker_broken := attacker_troops <= 0 or attacker_morale < MORALE_BREAK_AT
	var defender_broken := defender_troops <= 0 or defender_morale < MORALE_BREAK_AT
	if attacker_broken and defender_broken:
		return "mutual_collapse"
	if defender_broken:
		return "attacker_victory"
	if attacker_broken:
		return "defender_victory"
	return "inconclusive"


func _termination_event(outcome: String,attacker: Dictionary,defender: Dictionary,attacker_remaining: int,defender_remaining: int,attacker_morale: float,defender_morale: float,rng: RandomNumberGenerator,overrun:=false) -> Dictionary:
	if overrun and outcome in ["attacker_victory","defender_victory"]:
		# Overrun: the few left standing are taken where they are or run for it.
		var beaten:Dictionary=defender if outcome=="attacker_victory" else attacker
		var victors:Dictionary=attacker if outcome=="attacker_victory" else defender
		var left:=defender_remaining if outcome=="attacker_victory" else attacker_remaining
		var small:=left<=TINY_BAND
		var taken:=clampi(roundi(float(left)*(rng.randf_range(0.4,1.0) if small else rng.randf_range(0.2,0.5))),0,left)
		var beaten_commander:Dictionary=beaten.get("commander",{})
		var fate_roll:=rng.randf()
		var fate:="captured" if fate_roll<0.35 else ("killed" if fate_roll<0.5 else "escaped")
		var spoils_taken:=_battle_spoils(beaten,victors,"surrender",rng)
		var beaten_name:=String(beaten.get("name","Defeated force")); var victor_name:=String(victors.get("name","Victors"))
		var summary:="%s overran %s" % [victor_name,beaten_name]
		if taken>0: summary+=" and took %d prisoners" % taken
		if left-taken>0: summary+="; %d got away" % (left-taken)
		summary+="."
		return {"type":"overrun","summary":summary,"prisoners":taken,"scattered":left-taken,"captor":victor_name,"defeated":beaten_name,"commander":String(beaten_commander.get("name","THE DEFEATED COMMAND GROUP")),
			"commander_record":beaten_commander.duplicate(true),"commander_fate":fate,"captured_general":fate=="captured" and not beaten_commander.is_empty(),"spoils":spoils_taken}
	if outcome=="inconclusive":
		return {"type":"continued","summary":"Neither army yields the field.","prisoners":0,"commander_fate":"in command","captured_general":false,"spoils":{}}
	if outcome=="mutual_collapse":
		return {"type":"mutual_withdrawal","summary":"Both shattered armies disengage; scattered personnel remain between the lines.","prisoners":0,"commander_fate":"unknown","captured_general":false,"spoils":{}}
	var loser:Dictionary=defender if outcome=="attacker_victory" else attacker
	var winner:Dictionary=attacker if outcome=="attacker_victory" else defender
	var loser_remaining:=defender_remaining if outcome=="attacker_victory" else attacker_remaining
	var loser_morale:=defender_morale if outcome=="attacker_victory" else attacker_morale
	var loser_commander:Dictionary=loser.get("commander",{})
	var resolve:=clampf(float(loser_commander.get("resolve",0.5)),0.0,1.0)
	# How far below the break line the beaten side fell (none just under it,
	# full at nothing left): the same depth below the one line (army_lines.gd)
	# that once measured below 0.15.
	var collapse:=clampf(1.0-loser_morale/(MORALE_BREAK_AT*COLLAPSE_SPAN),0.0,1.0)
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
	var commander_name:=String(loser_commander.get("name","THE DEFEATED COMMAND GROUP"))
	var summary:="%s withdraws in order." % loser_name
	if termination_type=="surrender": summary="Elements of %s surrender; %s takes %s." % [loser_name,winner_name,captive_words(prisoners)]
	elif termination_type=="pursuit": summary=("%s pursues the rout and takes %s." % [winner_name,captive_words(prisoners)]) if prisoners>0 else "%s pursues the rout." % winner_name
	elif prisoners>0: summary="%s escapes, leaving %s behind." % [loser_name,captive_words(prisoners)]
	summary+=" %s %s." % [commander_name,fate_words(commander_fate)]
	var spoils:=_battle_spoils(loser,winner,termination_type,rng)
	return {"type":termination_type,"summary":summary,"prisoners":prisoners,"captor":winner_name,"defeated":loser_name,"commander":commander_name,"commander_record":loser_commander.duplicate(true),"commander_fate":commander_fate,"captured_general":captured_general,"spoils":spoils}


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
		# Machines and vehicles left on the field for the victor are lost too.
		_book_hardware(loser,weapon,recovered)
		if ammo_per(weapon)>0 and ammo_type(weapon)!="":
			var ammunition:=int(formation.get("ammunition",0))
			var ammunition_recovered:=clampi(roundi(float(ammunition)*recovery_rate),0,ammunition)
			var ammunition_type:=ammo_type(weapon)
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


## Machines and vehicles lost in an exchange (wrecked), kept on the force
## for the report.
func _count_machines(force:Dictionary,applied:Dictionary)->void:
	var formations:Array=applied.get("formations",[])
	var lost:Array=applied.get("equipment_losses",[])
	for index in mini(formations.size(),lost.size()):
		if int(lost[index])>0: _book_hardware(force,String((formations[index] as Dictionary).get("weapon","")),int(lost[index]))

func _book_hardware(force:Dictionary,weapon:String,count:int)->void:
	if count<=0: return
	if is_machine(weapon): force["machines_lost"]=int(force.get("machines_lost",0))+count
	elif Ledger.family(weapon)=="vehicle": force["vehicles_lost"]=int(force.get("vehicles_lost",0))+count


func _force_result(force: Dictionary, initial: int, remaining: int, morale: float) -> Dictionary:
	return {
		"machines_lost":int(force.get("machines_lost",0)),
		"vehicles_lost":int(force.get("vehicles_lost",0)),
		"name": String(force.name),
		"initial_troops": initial,
		"commander":force.get("commander",{}).duplicate(true),
		"remaining_troops": remaining,
		"supply_level":float(force.get("supply_level",1.0)),
		"readiness":float(force.get("readiness",1.0)),
		"casualties": initial - remaining,
		"morale": morale,
		"routed": remaining <= 0 or morale < MORALE_BREAK_AT,
		"attack": float(force.attack),
		"defense": float(force.defense),
		"armor": float(force.get("armor", 0.0)),
		"penetration": float(force.get("penetration", 0.0)),
		"formations": force.get("formations", []).duplicate(true),
		"reserve_manpower":int(force.get("reserve_manpower",0)),
		"wounded_pool":int(force.get("wounded_pool",0)),
		"disabled_pool":int(force.get("disabled_pool",0)),
		"severe_disabled_pool":int(force.get("severe_disabled_pool",0)),
		"scattered_pool":int(force.get("scattered_pool",0)),
		"captured_pool":int(force.get("captured_pool",0)),
		"captured_in_battle":int(force.get("captured_in_battle",0)),
		"dead":int(force.get("dead",0))
	}


## "1 prisoner", "12 prisoners".
static func captive_words(count:int)->String:
	return "%d %s" % [count,"prisoner" if count==1 else "prisoners"]


## A beaten commander's fate as the report says it: "got away", "was taken",
## "was killed", "was wounded but got away".
static func fate_words(fate:String)->String:
	match fate:
		"escaped":return "got away"
		"captured":return "was taken"
		"killed":return "was killed"
		"wounded, but escaped":return "was wounded but got away"
	return "is %s" % fate
