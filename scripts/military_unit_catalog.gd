## Data authority for military unit archetypes and equipment gates, following
## the design bible (docs/Historical_Military_Unit_Progression.docx §17–18):
## units are archetypes on branching lineage spines, unlocked by knowledge but
## fielded only through people, material, training, command, and sustainment.
## Combat coefficients stay in combat_simulator.gd; this file owns identity,
## gating, lineage, and fielding data.

# Branch ids follow §17's spines. "lineage" points at the archetype this form
# grows out of — a viable transformation when its gates exist, never an
# automatic replacement; older forms persist wherever they stay rational.
const ARCHETYPES:Dictionary={
	"field_repair_company": {"label":"Field Repair Company","branch":"field_support","lineage":"","era":"organized equipment maintenance","gate":"field_armorer_teams","training_days":45,"equipment":["repair_kit"],"movement":"foot","pace_km_day":24,"purpose":"Supplies trained repair work at home workshops; contributes no offensive firepower.","sustainment":"Requires issued tools, provisions, repair materials and available workshop space.","politics":"Repair personnel remain mobilized people, subject to normal losses and demobilization."},
	"medical_detachment": {"label": "Medical Detachment", "branch": "field_support", "lineage": "", "era": "organized casualty care", "gate": "litter_bearer_drill", "training_days": 35, "equipment": ["medical_kit"], "movement": "foot", "pace_km_day": 24, "purpose": "Provides staffed, equipped casualty recovery during supported preparation; contributes no offensive firepower.", "sustainment": "Requires issued care equipment and consumes local dressings and medicinal supplies when providing care.", "politics": "Care workers remain part of mobilized population, with the same losses and demobilization accounting."},
	"levy": {
		"label": "Levy",
		"branch": "force_generation",
		"lineage": "",
		"era": "village warfare",
		"gate": "",
		"training_days": 7,
		"equipment": [
			"improvised",
			"spear"
		],
		"movement": "foot",
		"purpose": "Numbers, garrison mass, and the mobilization base every later form draws on.",
		"sustainment": "Eats from settlement stores; every levy is labor withheld from fields.",
		"politics": "Broad legitimacy; cheap to raise, costly to keep standing."
	},
	"line_infantry": {
		"label": "Line Infantry",
		"branch": "heavy_infantry",
		"lineage": "levy",
		"era": "early iron",
		"gate": "shield_wall",
		"training_days": 30,
		"equipment": [
			"shield_spear",
			"padded_spear",
			"lamellar_spear",
			"scale_spear",
			"mail_spear",
			"plate_spear",
			"spear",
			"sword_shield"
		],
		"movement": "foot",
		"purpose": "Holds ground in formation; the anchor other arms maneuver around.",
		"sustainment": "Standard rations; armor and shields need craft replacement.",
		"politics": "Drill time builds cohesion and a soldier identity distinct from the levy."
	},
	"skirmisher": {
		"label": "Skirmisher",
		"branch": "reconnaissance",
		"lineage": "levy",
		"era": "early iron",
		"gate": "bow_craft",
		"training_days": 21,
		"equipment": [
			"bow"
		],
		"movement": "foot",
		"purpose": "Screens, harasses, and scouts ahead of the line; the army's forward eyes.",
		"sustainment": "Light burden; consumes arrows on every engagement.",
		"politics": "Recruits from hunters; blurs the line between forager skill and war skill."
	},
	"cavalry": {
		"label": "Cavalry",
		"branch": "mounted",
		"lineage": "skirmisher",
		"era": "early iron",
		"gate": "domesticated_mounts",
		"training_days": 45,
		"equipment": [
			"lance",
			"sword_shield"
		],
		"movement": "mounted",
		"purpose": "Shock, pursuit, and operational reach; turns victories into routs.",
		"sustainment": "Fodder doubles the supply burden; every mount is a bred, fed animal.",
		"politics": "Mounts concentrate in wealthy hands; cavalry breeds an elite arm."
	},
	"siege_engineer": {
		"label": "Siege Engineers",
		"branch": "siege_fires",
		"lineage": "line_infantry",
		"era": "early states",
		"gate": "siege_engineering",
		"training_days": 48,
		"equipment": [
			"siege_kit"
		],
		"movement": "foot",
		"purpose": "Breaks fortifications and builds the works that protect a besieging army.",
		"sustainment": "Timber, tools, and skilled labor; slow to replace when lost.",
		"politics": "Specialist knowledge held by few; institutions must retain it."
	},
	"field_artillery": {
		"label": "Field Artillery",
		"branch": "siege_fires",
		"lineage": "siege_engineer",
		"era": "gunpowder",
		"gate": "powder_artillery",
		"training_days": 60,
		"equipment": [
			"field_gun"
		],
		"movement": "wheeled",
		"purpose": "Massed fire against formations and works alike.",
		"sustainment": "Powder, shot, and draft teams; ammunition dominates its logistics.",
		"politics": "Guns are state property; artillery centralizes military power."
	},
	"rifle_infantry": {
		"label": "Rifle Infantry",
		"branch": "heavy_infantry",
		"lineage": "line_infantry",
		"era": "industrial",
		"gate": "metallic_cartridges",
		"training_days": 42,
		"equipment": [
			"service_rifle"
		],
		"movement": "foot",
		"purpose": "Dispersed accurate fire; the standard formation of industrial war.",
		"sustainment": "Cartridge supply and arsenal-pattern repair.",
		"politics": "Mass conscription becomes practical and expected."
	},
	"machine_gun_company": {
		"label": "Machine-Gun Company",
		"branch": "siege_fires",
		"lineage": "rifle_infantry",
		"era": "industrial",
		"gate": "automatic_actions",
		"training_days": 56,
		"equipment": [
			"machine_gun"
		],
		"movement": "foot",
		"purpose": "Sustained suppression; makes open ground impassable.",
		"sustainment": "Devours ammunition; crew-served weapons need trained teams.",
		"politics": "Defense-dominant; changes what offensives cost."
	},
	"motorized_infantry": {
		"label": "Motorized Infantry",
		"branch": "mounted",
		"lineage": "cavalry",
		"era": "mechanization",
		"gate": "internal_combustion",
		"training_days": 70,
		"equipment": [
			"motorized_kit"
		],
		"movement": "motorized",
		"purpose": "Operational mobility for infantry; reach without exhaustion.",
		"sustainment": "Fuel, parts, and mechanics; roads or firm ground.",
		"politics": "Industry becomes the recruiting ground as much as the village."
	},
	"armored_formation": {
		"label": "Armored Formation",
		"branch": "protection",
		"lineage": "motorized_infantry",
		"era": "mechanization",
		"gate": "armored_vehicles",
		"training_days": 110,
		"equipment": [
			"armored_vehicle"
		],
		"movement": "tracked",
		"purpose": "Protected shock and breakthrough; the war wagon's industrial heir.",
		"sustainment": "The heaviest burden fielded: fuel, ammunition, recovery, and repair.",
		"politics": "A national industrial commitment visible to every rival."
	},
	"modern_artillery": {
		"label": "Modern Artillery",
		"branch": "siege_fires",
		"lineage": "field_artillery",
		"era": "mechanization",
		"gate": "indirect_fire",
		"training_days": 84,
		"equipment": [
			"modern_field_gun"
		],
		"movement": "wheeled",
		"purpose": "Long-range indirect fire coordinated by survey and signals.",
		"sustainment": "Shell industry and fire-direction specialists.",
		"politics": "Invisible killing at range; doctrine and staffs matter more than valor."
	},
	"spearman": {
		"label": "Spearmen",
		"branch": "heavy_infantry",
		"lineage": "levy",
		"era": "early states",
		"gate": "hafted_weapons",
		"equipment": [
			"shield_spear",
			"padded_spear",
			"lamellar_spear",
			"scale_spear",
			"mail_spear",
			"plate_spear",
			"spear"
		],
		"training_days": 18,
		"movement": "foot",
		"pace_km_day": 25,
		"purpose": "Stop mounted charges with ranked reach",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"axeman": {
		"label": "Axemen",
		"branch": "heavy_infantry",
		"lineage": "levy",
		"era": "early states",
		"gate": "bronze_weaponry",
		"equipment": [
			"axe"
		],
		"training_days": 22,
		"movement": "foot",
		"pace_km_day": 25,
		"purpose": "Break shielded infantry at close quarters",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"slinger": {
		"label": "Slingers",
		"branch": "missile_infantry",
		"lineage": "levy",
		"era": "early states",
		"gate": "woven_carriers",
		"equipment": [
			"sling"
		],
		"training_days": 25,
		"movement": "foot",
		"pace_km_day": 31,
		"purpose": "Cheap standoff harassment with stone ammunition",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"javelineer": {
		"label": "Javelineers",
		"branch": "missile_infantry",
		"lineage": "levy",
		"era": "early states",
		"gate": "hafted_weapons",
		"equipment": [
			"javelin"
		],
		"training_days": 20,
		"movement": "foot",
		"pace_km_day": 32,
		"purpose": "Disrupt a charge before withdrawing",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"archer": {
		"label": "Massed Archers",
		"branch": "missile_infantry",
		"lineage": "skirmisher",
		"era": "early states",
		"gate": "bow_craft",
		"equipment": [
			"bow"
		],
		"training_days": 32,
		"movement": "foot",
		"pace_km_day": 25,
		"purpose": "Concentrate missile fire behind a protective line",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"pikeman": {
		"label": "Pikemen",
		"branch": "heavy_infantry",
		"lineage": "spearman",
		"era": "early states",
		"gate": "pike_drill",
		"equipment": [
			"pike"
		],
		"training_days": 35,
		"movement": "foot",
		"pace_km_day": 22,
		"purpose": "Deny cavalry and frontal approaches; exposed to missiles",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"crossbowman": {
		"label": "Crossbowmen",
		"branch": "missile_infantry",
		"lineage": "archer",
		"era": "early states",
		"gate": "crossbow_mechanism",
		"equipment": [
			"crossbow"
		],
		"training_days": 28,
		"movement": "foot",
		"pace_km_day": 24,
		"purpose": "Pierce armor with deliberate ranged volleys",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"heavy_swordsman": {
		"label": "Armored Swordsmen",
		"branch": "heavy_infantry",
		"lineage": "line_infantry",
		"era": "early states",
		"gate": "bronze_weaponry",
		"equipment": [
			"sword_shield"
		],
		"training_days": 44,
		"movement": "foot",
		"pace_km_day": 21,
		"purpose": "Close assault against missile troops and lighter infantry",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"light_infantry": {
		"label": "Light Infantry",
		"branch": "heavy_infantry",
		"lineage": "skirmisher",
		"era": "early states",
		"gate": "professional_corps",
		"equipment": [
			"bow"
		],
		"training_days": 35,
		"movement": "foot",
		"pace_km_day": 36,
		"purpose": "Screen and exploit broken ground; avoid sustained shock",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"mountain_infantry": {
		"label": "Mountain Infantry",
		"branch": "specialist_infantry",
		"lineage": "light_infantry",
		"era": "industrial",
		"gate": "military_staffs",
		"equipment": [
			"mountain_kit"
		],
		"training_days": 65,
		"movement": "foot",
		"pace_km_day": 27,
		"purpose": "Hold difficult terrain with portable weapons and specialist kit",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"light_cavalry": {
		"label": "Light Cavalry",
		"branch": "mounted",
		"lineage": "cavalry",
		"era": "early states",
		"gate": "domesticated_mounts",
		"equipment": [
			"lance"
		],
		"training_days": 34,
		"movement": "mounted",
		"pace_km_day": 66,
		"purpose": "Scout, pursue, and attack exposed missile troops",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"horse_archer": {
		"label": "Horse Archers",
		"branch": "mounted",
		"lineage": "skirmisher",
		"era": "early states",
		"gate": "mounted_archery",
		"equipment": [
			"mounted_bow"
		],
		"training_days": 70,
		"movement": "mounted",
		"pace_km_day": 62,
		"purpose": "Mobile missile harassment; weak in a fixed melee",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"chariot": {
		"label": "War Chariots",
		"branch": "mounted",
		"lineage": "levy",
		"era": "early states",
		"gate": "war_chariots",
		"equipment": [
			"chariot_kit"
		],
		"training_days": 60,
		"movement": "wheeled",
		"pace_km_day": 42,
		"purpose": "Fast missile and shock platforms on open ground",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"armored_cavalry": {
		"label": "Armored Cavalry",
		"branch": "mounted",
		"lineage": "cavalry",
		"era": "early states",
		"gate": "armored_riding",
		"equipment": [
			"armored_lance"
		],
		"training_days": 82,
		"movement": "mounted",
		"pace_km_day": 40,
		"purpose": "Massed shock against an unprepared line",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"war_elephant": {
		"label": "War Elephants",
		"branch": "mounted",
		"lineage": "cavalry",
		"era": "early states",
		"gate": "elephant_training",
		"equipment": [
			"elephant_kit"
		],
		"training_days": 100,
		"movement": "mounted",
		"pace_km_day": 20,
		"purpose": "Heavy shock and morale pressure; vulnerable to dispersed missiles",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"dragoon": {
		"label": "Dragoons",
		"branch": "mounted",
		"lineage": "cavalry",
		"era": "gunpowder",
		"gate": "mounted_firearms",
		"equipment": [
			"dragoon_kit"
		],
		"training_days": 60,
		"movement": "mounted",
		"pace_km_day": 49,
		"purpose": "Ride to position and fight dismounted with firearms",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"ram_crew": {
		"label": "Battering Ram Crews",
		"branch": "siege_fires",
		"lineage": "siege_engineer",
		"era": "early states",
		"gate": "field_fortifications",
		"equipment": [
			"ram"
		],
		"training_days": 30,
		"movement": "wheeled",
		"pace_km_day": 12,
		"purpose": "Breach gates under protective timber",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"catapult_crew": {
		"label": "Catapult Crews",
		"branch": "siege_fires",
		"lineage": "siege_engineer",
		"era": "early states",
		"gate": "siege_engineering",
		"equipment": [
			"catapult"
		],
		"training_days": 50,
		"movement": "wheeled",
		"pace_km_day": 12,
		"purpose": "Mechanical bombardment of walls and concentrated troops",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"trebuchet_crew": {
		"label": "Trebuchet Crews",
		"branch": "siege_fires",
		"lineage": "catapult_crew",
		"era": "early states",
		"gate": "counterweight_engines",
		"equipment": [
			"trebuchet"
		],
		"training_days": 65,
		"movement": "wheeled",
		"pace_km_day": 9,
		"purpose": "Heavy long-range siege bombardment; costly to move",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"bombard_crew": {
		"label": "Bombard Crews",
		"branch": "siege_fires",
		"lineage": "trebuchet_crew",
		"era": "gunpowder",
		"gate": "powder_artillery",
		"equipment": [
			"bombard"
		],
		"training_days": 65,
		"movement": "wheeled",
		"pace_km_day": 8,
		"purpose": "Demolish fortifications with heavy powder guns",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"horse_artillery": {
		"label": "Horse Artillery",
		"branch": "mounted",
		"lineage": "field_artillery",
		"era": "gunpowder",
		"gate": "mounted_firearms",
		"equipment": [
			"horse_gun"
		],
		"training_days": 70,
		"movement": "wheeled",
		"pace_km_day": 46,
		"purpose": "Move light guns quickly with mounted columns",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"mortar_crew": {
		"label": "Mortar Teams",
		"branch": "siege_fires",
		"lineage": "field_artillery",
		"era": "industrial",
		"gate": "indirect_fire",
		"equipment": [
			"mortar"
		],
		"training_days": 45,
		"movement": "foot",
		"pace_km_day": 25,
		"purpose": "Portable high-angle fire against covered infantry",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"rocket_artillery": {
		"label": "Rocket Artillery",
		"branch": "siege_fires",
		"lineage": "modern_artillery",
		"era": "mechanization",
		"gate": "indirect_fire",
		"equipment": [
			"rocket_launcher"
		],
		"training_days": 75,
		"movement": "motorized",
		"pace_km_day": 70,
		"purpose": "Area saturation with high ammunition demand",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"hand_cannoneer": {
		"label": "Hand Cannoneers",
		"branch": "heavy_infantry",
		"lineage": "crossbowman",
		"era": "gunpowder",
		"gate": "black_powder",
		"equipment": [
			"hand_cannon"
		],
		"training_days": 28,
		"movement": "foot",
		"pace_km_day": 23,
		"purpose": "Early close-range gunpowder fire with low cohesion",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"musketeer": {
		"label": "Musketeers",
		"branch": "heavy_infantry",
		"lineage": "hand_cannoneer",
		"era": "gunpowder",
		"gate": "matchlock_drill",
		"equipment": [
			"musket"
		],
		"training_days": 42,
		"movement": "foot",
		"pace_km_day": 25,
		"purpose": "Disciplined firearm volleys protected by other troops",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"grenadier": {
		"label": "Grenadiers",
		"branch": "heavy_infantry",
		"lineage": "musketeer",
		"era": "gunpowder",
		"gate": "matchlock_drill",
		"equipment": [
			"grenadier_kit"
		],
		"training_days": 60,
		"movement": "foot",
		"pace_km_day": 25,
		"purpose": "Assault enclosed defenses and close infantry positions",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"sharpshooter": {
		"label": "Sharpshooters",
		"branch": "heavy_infantry",
		"lineage": "light_infantry",
		"era": "industrial",
		"gate": "rifled_barrels",
		"equipment": [
			"marksman_rifle"
		],
		"training_days": 78,
		"movement": "foot",
		"pace_km_day": 30,
		"purpose": "Precision harassment; low mass and weak close defense",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"assault_infantry": {
		"label": "Assault Infantry",
		"branch": "heavy_infantry",
		"lineage": "rifle_infantry",
		"era": "industrial",
		"gate": "automatic_actions",
		"equipment": [
			"assault_kit"
		],
		"training_days": 70,
		"movement": "foot",
		"pace_km_day": 27,
		"purpose": "Infiltrate and clear trenches at close range",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"marines": {
		"label": "Marines",
		"branch": "specialist_infantry",
		"lineage": "rifle_infantry",
		"era": "early states",
		"gate": "amphibious_operations",
		"equipment": [
			"marine_kit"
		],
		"training_days": 85,
		"movement": "foot",
		"pace_km_day": 27,
		"purpose": "Train for shore landings and fighting around ports",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"paratrooper": {
		"label": "Airborne Infantry",
		"branch": "specialist_infantry",
		"lineage": "rifle_infantry",
		"era": "mechanization",
		"gate": "airborne_operations",
		"equipment": [
			"airborne_kit"
		],
		"training_days": 100,
		"movement": "foot",
		"pace_km_day": 28,
		"purpose": "Air insertion infantry; requires transport aircraft for a drop",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"combat_engineer": {
		"label": "Combat Engineers",
		"branch": "specialist_infantry",
		"lineage": "siege_engineer",
		"era": "industrial",
		"gate": "indirect_fire",
		"equipment": [
			"engineering_kit"
		],
		"training_days": 70,
		"movement": "foot",
		"pace_km_day": 24,
		"purpose": "Breach field defenses and support fortified fighting",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"anti_tank": {
		"label": "Antitank Teams",
		"branch": "heavy_infantry",
		"lineage": "rifle_infantry",
		"era": "mechanization",
		"gate": "armor_piercing_weapons",
		"equipment": [
			"anti_tank_kit"
		],
		"training_days": 65,
		"movement": "foot",
		"pace_km_day": 25,
		"purpose": "Defeat armor at the cost of general infantry firepower",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"anti_air": {
		"label": "Antiaircraft Batteries",
		"branch": "siege_fires",
		"lineage": "field_artillery",
		"era": "mechanization",
		"gate": "powered_flight",
		"equipment": [
			"anti_air_gun"
		],
		"training_days": 60,
		"movement": "wheeled",
		"pace_km_day": 20,
		"purpose": "Protect concentrations from aircraft; vulnerable to ground assault",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"armored_car": {
		"label": "Armored Reconnaissance",
		"branch": "mounted",
		"lineage": "cavalry",
		"era": "mechanization",
		"gate": "armored_vehicles",
		"equipment": [
			"armored_car_kit"
		],
		"training_days": 60,
		"movement": "motorized",
		"pace_km_day": 125,
		"purpose": "Fast protected reconnaissance; light armor only",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"light_tank": {
		"label": "Light Tanks",
		"branch": "protection",
		"lineage": "armored_formation",
		"era": "mechanization",
		"gate": "armored_vehicles",
		"equipment": [
			"light_tank_kit"
		],
		"training_days": 85,
		"movement": "tracked",
		"pace_km_day": 115,
		"purpose": "Exploit gaps quickly; avoid heavier armor",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"heavy_tank": {
		"label": "Heavy Tanks",
		"branch": "protection",
		"lineage": "armored_formation",
		"era": "mechanization",
		"gate": "armored_vehicles",
		"equipment": [
			"heavy_tank_kit"
		],
		"training_days": 120,
		"movement": "tracked",
		"pace_km_day": 58,
		"purpose": "Break defended fronts with heavy protection and a large supply burden",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"tank_destroyer": {
		"label": "Tank Destroyers",
		"branch": "protection",
		"lineage": "armored_formation",
		"era": "mechanization",
		"gate": "armor_piercing_weapons",
		"equipment": [
			"tank_destroyer_kit"
		],
		"training_days": 95,
		"movement": "tracked",
		"pace_km_day": 88,
		"purpose": "Concentrate armor-piercing fire; weak against close infantry",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"mechanized_infantry": {
		"label": "Mechanized Infantry",
		"branch": "protection",
		"lineage": "motorized_infantry",
		"era": "mechanization",
		"gate": "armored_vehicles",
		"equipment": [
			"mechanized_kit"
		],
		"training_days": 95,
		"movement": "tracked",
		"pace_km_day": 105,
		"purpose": "Protected infantry keeps pace with armored forces",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	},
	"air_assault": {
		"label": "Air Assault Infantry",
		"branch": "specialist_infantry",
		"lineage": "paratrooper",
		"era": "mechanization",
		"gate": "rotary_wing",
		"equipment": [
			"air_assault_kit"
		],
		"training_days": 110,
		"movement": "foot",
		"pace_km_day": 29,
		"purpose": "Helicopter-lift infantry; land movement remains on foot without lift",
		"sustainment": "Consumes matching equipment, supplies and training capacity; replacements draw from the shared population.",
		"politics": "Available to any civilization that develops and sustains the capability."
	}
}

const EQUIPMENT_GATES:Dictionary={
	"shield_spear":"shield_equipment_fitting",
	"padded_spear":"textile_armor_layering",
	"lamellar_spear":"lamellar_armor_assembly",
	"scale_spear":"scale_armor_attachment",
	"mail_spear":"mail_armor_fabrication",
	"plate_spear":"articulated_plate_armor",
	"repair_kit":"field_armorer_teams",
	"medical_kit":"litter_bearer_drill",
	"improvised": "",
	"spear": "hafted_weapons",
	"bow": "bow_craft",
	"sword_shield": "bronze_weaponry",
	"lance": "domesticated_mounts",
	"siege_kit": "siege_engineering",
	"field_gun": "powder_artillery",
	"service_rifle": "metallic_cartridges",
	"machine_gun": "automatic_actions",
	"motorized_kit": "internal_combustion",
	"armored_vehicle": "armored_vehicles",
	"modern_field_gun": "indirect_fire",
	"axe": "bronze_weaponry",
	"sling": "woven_carriers",
	"javelin": "hafted_weapons",
	"pike": "pike_drill",
	"crossbow": "crossbow_mechanism",
	"mountain_kit": "military_staffs",
	"mounted_bow": "mounted_archery",
	"chariot_kit": "war_chariots",
	"armored_lance": "armored_riding",
	"elephant_kit": "elephant_training",
	"dragoon_kit": "mounted_firearms",
	"ram": "field_fortifications",
	"catapult": "siege_engineering",
	"trebuchet": "counterweight_engines",
	"bombard": "powder_artillery",
	"horse_gun": "mounted_firearms",
	"mortar": "indirect_fire",
	"rocket_launcher": "indirect_fire",
	"hand_cannon": "black_powder",
	"musket": "matchlock_drill",
	"grenadier_kit": "matchlock_drill",
	"marksman_rifle": "rifled_barrels",
	"assault_kit": "automatic_actions",
	"marine_kit": "amphibious_operations",
	"airborne_kit": "airborne_operations",
	"engineering_kit": "indirect_fire",
	"anti_tank_kit": "armor_piercing_weapons",
	"anti_air_gun": "powered_flight",
	"armored_car_kit": "armored_vehicles",
	"light_tank_kit": "armored_vehicles",
	"heavy_tank_kit": "armored_vehicles",
	"tank_destroyer_kit": "armor_piercing_weapons",
	"mechanized_kit": "armored_vehicles",
	"air_assault_kit": "rotary_wing",
	"war_canoe_equipment": "river_craft",
	"galley_equipment": "galley_navigation",
	"heavy_galley_equipment": "naval_arsenals",
	"sailing_warship_equipment": "ocean_sailing",
	"sailing_frigate_equipment": "naval_gunnery",
	"ship_of_line_equipment": "naval_gunnery",
	"steam_corvette_equipment": "steam_propulsion",
	"ironclad_equipment": "armored_hulls",
	"torpedo_boat_equipment": "naval_torpedoes",
	"destroyer_equipment": "naval_torpedoes",
	"light_cruiser_equipment": "armored_hulls",
	"heavy_cruiser_equipment": "naval_fire_control",
	"battleship_equipment": "naval_fire_control",
	"submarine_equipment": "submersible_hulls",
	"aircraft_carrier_equipment": "carrier_aviation",
	"amphibious_ship_equipment": "amphibious_operations",
	"missile_patrol_equipment": "guided_weapons",
	"missile_destroyer_equipment": "naval_missiles",
	"nuclear_submarine_equipment": "nuclear_propulsion",
	"fleet_support_equipment": "naval_logistics",
	"observation_balloon_equipment": "aerostat_observation",
	"airship_equipment": "powered_flight",
	"recon_plane_equipment": "powered_flight",
	"fighter_equipment": "fighter_tactics",
	"heavy_fighter_equipment": "advanced_airframes",
	"close_air_support_equipment": "aerial_bombardment",
	"tactical_bomber_equipment": "aerial_bombardment",
	"strategic_bomber_equipment": "advanced_airframes",
	"naval_bomber_equipment": "naval_aviation",
	"transport_aircraft_equipment": "airborne_operations",
	"jet_fighter_equipment": "jet_propulsion",
	"jet_bomber_equipment": "jet_propulsion",
	"transport_helicopter_equipment": "rotary_wing",
	"attack_helicopter_equipment": "guided_weapons",
	"recon_drone_equipment": "remote_aircraft",
	"strike_drone_equipment": "remote_aircraft",
	"convoy_transport_equipment": "ocean_sailing"
}

## Fielding-readiness bands (§18.4) derived from a formation's continuous
## state. Veteran is an overlay earned through combat experience.
static func readiness_band(formation:Dictionary)->String:
	var condition:=clampf(float(formation.get("personnel_condition",1.0)),0.0,1.0)
	var training:=clampf(float(formation.get("training",0.0)),0.0,1.0)
	var experience:=clampf(float(formation.get("experience",0.0)),0.0,1.0)
	if condition<0.30: return "BROKEN"
	if condition<0.55: return "DEGRADED"
	if experience>=0.50 and training>=0.55: return "VETERAN"
	if training>=0.80: return "READY"
	if training>=0.50: return "TRAINED"
	if training>=0.25: return "GREEN"
	return "ASSEMBLING"


static func archetype(unit:String)->Dictionary:
	return (ARCHETYPES.get(unit,{}) as Dictionary)

static func gate_for(unit:String)->String:
	return String(archetype(unit).get("gate",""))

static func equipment_for(unit:String)->Array:
	return (archetype(unit).get("equipment",["improvised"]) as Array)

static func training_days(unit:String)->float:
	return maxf(45.0,float(archetype(unit).get("training_days",21))*3.0)*WorldSimulation.discovery.military_training_multiplier(unit)

static func lineage_for(unit:String)->String:
	return String(archetype(unit).get("lineage",""))
