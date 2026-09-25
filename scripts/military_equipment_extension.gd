extends RefCounted
const ITEMS:Dictionary={
	"shield_spear":preload("res://scripts/armor_equipment.gd").KITS.shield_spear,
	"padded_spear":preload("res://scripts/armor_equipment.gd").KITS.padded_spear,
	"lamellar_spear":preload("res://scripts/armor_equipment.gd").KITS.lamellar_spear,
	"scale_spear":preload("res://scripts/armor_equipment.gd").KITS.scale_spear,
	"mail_spear":preload("res://scripts/armor_equipment.gd").KITS.mail_spear,
	"plate_spear":preload("res://scripts/armor_equipment.gd").KITS.plate_spear,
	"repair_kit":{"name":"Armorer tools","gate":"field_armorer_teams","materials":{"Timber":2.0,"Stone":2.0},"days":3.0,"crew":1,"ammo":"","ammo_per":0,"attack":0.0,"defense":0.5,"armor":0.0,"penetration":0.0,"delivery":1.0},
	"medical_kit":{"name": "Medical care equipment", "gate": "litter_bearer_drill", "materials": {"Timber": 1.0, "Fiber Plants": 2.0}, "days": 2.0, "crew": 1, "ammo": "", "ammo_per": 0, "attack": 0.0, "defense": 0.6, "armor": 0.0, "penetration": 0.0, "delivery": 1.0},
	"axe": {
		"name": "Axemen equipment",
		"gate": "bronze_weaponry",
		"materials": {
			"Timber": 0.4,
			"Copper Ore": 0.4,
			"Tin Ore": 0.08
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "",
		"ammo_per": 0,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"sling": {
		"name": "Slingers equipment",
		"gate": "woven_carriers",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2,
			"Fiber Plants": 0.3
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "",
		"ammo_per": 0,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"javelin": {
		"name": "Javelineers equipment",
		"gate": "hafted_weapons",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "",
		"ammo_per": 0,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"pike": {
		"name": "Pikemen equipment",
		"gate": "pike_drill",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "",
		"ammo_per": 0,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"crossbow": {
		"name": "Crossbowmen equipment",
		"gate": "crossbow_mechanism",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2,
			"Fiber Plants": 0.3
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "arrows",
		"ammo_per": 24,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"mountain_kit": {
		"name": "Mountain Infantry equipment",
		"gate": "military_staffs",
		"materials": {
			"Timber": 0.8,
			"Iron Ore": 1.5
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "small_arms_ammunition",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 1.4,
		"delivery": 2.0
	},
	"mounted_bow": {
		"name": "Horse Archers equipment",
		"gate": "mounted_archery",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2,
			"Fiber Plants": 0.3
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "arrows",
		"ammo_per": 24,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"chariot_kit": {
		"name": "War Chariots equipment",
		"gate": "war_chariots",
		"materials": {
			"Timber": 3.2,
			"Stone": 0.8,
			"Fiber Plants": 1.2
		},
		"days": 4.8,
		"crew": 2,
		"ammo": "",
		"ammo_per": 0,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 8.0
	},
	"armored_lance": {
		"name": "Armored Cavalry equipment",
		"gate": "armored_riding",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "",
		"ammo_per": 0,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.6,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"elephant_kit": {
		"name": "War Elephants equipment",
		"gate": "elephant_training",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2,
			"Fiber Plants": 0.3
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "",
		"ammo_per": 0,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"dragoon_kit": {
		"name": "Dragoons equipment",
		"gate": "mounted_firearms",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "artillery_rounds",
		"ammo_per": 24,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"ram": {
		"name": "Battering Ram Crews equipment",
		"gate": "field_fortifications",
		"materials": {
			"Timber": 3.2,
			"Stone": 0.8
		},
		"days": 4.8,
		"crew": 8,
		"ammo": "",
		"ammo_per": 0,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 8.0
	},
	"catapult": {
		"name": "Catapult Crews equipment",
		"gate": "siege_engineering",
		"materials": {
			"Timber": 3.2,
			"Stone": 0.8
		},
		"days": 4.8,
		"crew": 8,
		"ammo": "",
		"ammo_per": 0,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 8.0
	},
	"trebuchet": {
		"name": "Trebuchet Crews equipment",
		"gate": "counterweight_engines",
		"materials": {
			"Timber": 3.2,
			"Stone": 0.8
		},
		"days": 4.8,
		"crew": 8,
		"ammo": "",
		"ammo_per": 0,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 8.0
	},
	"bombard": {
		"name": "Bombard Crews equipment",
		"gate": "powder_artillery",
		"materials": {
			"Timber": 3.2,
			"Stone": 0.8
		},
		"days": 4.8,
		"crew": 8,
		"ammo": "artillery_rounds",
		"ammo_per": 24,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 8.0
	},
	"horse_gun": {
		"name": "Horse Artillery equipment",
		"gate": "mounted_firearms",
		"materials": {
			"Timber": 3.2,
			"Stone": 0.8
		},
		"days": 4.8,
		"crew": 8,
		"ammo": "artillery_rounds",
		"ammo_per": 24,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 8.0
	},
	"mortar": {
		"name": "Mortar Teams equipment",
		"gate": "__military_tier_5__",
		"materials": {
			"Timber": 3.2,
			"Iron Ore": 6.0
		},
		"days": 4.8,
		"crew": 8,
		"ammo": "heavy_shells",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 1.4,
		"delivery": 8.0
	},
	"rocket_launcher": {
		"name": "Rocket Artillery equipment",
		"gate": "__military_tier_6__",
		"materials": {
			"Iron Ore": 18.0,
			"Copper Ore": 2.0,
			"Fiber Plants": 1.0
		},
		"days": 16.0,
		"crew": 5,
		"ammo": "heavy_shells",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.35,
		"armor": 1.5,
		"penetration": 1.4,
		"delivery": 8.0
	},
	"hand_cannon": {
		"name": "Hand Cannoneers equipment",
		"gate": "powder_artillery",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "artillery_rounds",
		"ammo_per": 24,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"musket": {
		"name": "Musketeers equipment",
		"gate": "matchlock_drill",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "artillery_rounds",
		"ammo_per": 24,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"grenadier_kit": {
		"name": "Grenadiers equipment",
		"gate": "matchlock_drill",
		"materials": {
			"Timber": 0.8,
			"Stone": 0.2
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "artillery_rounds",
		"ammo_per": 24,
		"attack": 1.05,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 0.65,
		"delivery": 2.0
	},
	"marksman_rifle": {
		"name": "Sharpshooters equipment",
		"gate": "__military_tier_5__",
		"materials": {
			"Timber": 0.8,
			"Iron Ore": 1.5
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "small_arms_ammunition",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 1.4,
		"delivery": 2.0
	},
	"assault_kit": {
		"name": "Assault Infantry equipment",
		"gate": "__military_tier_5__",
		"materials": {
			"Timber": 0.8,
			"Iron Ore": 1.5
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "small_arms_ammunition",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 1.4,
		"delivery": 2.0
	},
	"marine_kit": {
		"name": "Marines equipment",
		"gate": "amphibious_operations",
		"materials": {
			"Timber": 0.8,
			"Iron Ore": 1.5
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "small_arms_ammunition",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 1.4,
		"delivery": 2.0
	},
	"airborne_kit": {
		"name": "Airborne Infantry equipment",
		"gate": "airborne_operations",
		"materials": {
			"Timber": 0.8,
			"Iron Ore": 1.5
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "small_arms_ammunition",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 1.4,
		"delivery": 2.0
	},
	"engineering_kit": {
		"name": "Combat Engineers equipment",
		"gate": "__military_tier_5__",
		"materials": {
			"Timber": 0.8,
			"Iron Ore": 1.5
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "small_arms_ammunition",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 1.4,
		"delivery": 2.0
	},
	"anti_tank_kit": {
		"name": "Antitank Teams equipment",
		"gate": "__military_tier_6__",
		"materials": {
			"Timber": 0.8,
			"Iron Ore": 1.5
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "small_arms_ammunition",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 3.0,
		"delivery": 2.0
	},
	"anti_air_gun": {
		"name": "Antiaircraft Batteries equipment",
		"gate": "powered_flight",
		"materials": {
			"Timber": 3.2,
			"Iron Ore": 6.0
		},
		"days": 4.8,
		"crew": 8,
		"ammo": "heavy_shells",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 1.4,
		"delivery": 8.0
	},
	"armored_car_kit": {
		"name": "Armored Reconnaissance equipment",
		"gate": "__military_tier_6__",
		"materials": {
			"Iron Ore": 18.0,
			"Copper Ore": 2.0,
			"Fiber Plants": 1.0
		},
		"days": 16.0,
		"crew": 5,
		"ammo": "heavy_shells",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.35,
		"armor": 1.5,
		"penetration": 1.4,
		"delivery": 8.0
	},
	"light_tank_kit": {
		"name": "Light Tanks equipment",
		"gate": "__military_tier_6__",
		"materials": {
			"Iron Ore": 18.0,
			"Copper Ore": 2.0,
			"Fiber Plants": 1.0
		},
		"days": 16.0,
		"crew": 5,
		"ammo": "heavy_shells",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.35,
		"armor": 1.5,
		"penetration": 1.4,
		"delivery": 8.0
	},
	"heavy_tank_kit": {
		"name": "Heavy Tanks equipment",
		"gate": "__military_tier_6__",
		"materials": {
			"Iron Ore": 35.0,
			"Copper Ore": 2.0,
			"Fiber Plants": 1.0
		},
		"days": 16.0,
		"crew": 5,
		"ammo": "heavy_shells",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.35,
		"armor": 1.5,
		"penetration": 1.4,
		"delivery": 8.0
	},
	"tank_destroyer_kit": {
		"name": "Tank Destroyers equipment",
		"gate": "__military_tier_6__",
		"materials": {
			"Iron Ore": 18.0,
			"Copper Ore": 2.0,
			"Fiber Plants": 1.0
		},
		"days": 16.0,
		"crew": 5,
		"ammo": "heavy_shells",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.35,
		"armor": 1.5,
		"penetration": 3.0,
		"delivery": 8.0
	},
	"mechanized_kit": {
		"name": "Mechanized Infantry equipment",
		"gate": "__military_tier_6__",
		"materials": {
			"Iron Ore": 18.0,
			"Copper Ore": 2.0,
			"Fiber Plants": 1.0
		},
		"days": 16.0,
		"crew": 5,
		"ammo": "heavy_shells",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.35,
		"armor": 1.5,
		"penetration": 1.4,
		"delivery": 8.0
	},
	"air_assault_kit": {
		"name": "Air Assault Infantry equipment",
		"gate": "rotary_wing",
		"materials": {
			"Timber": 0.8,
			"Iron Ore": 1.5
		},
		"days": 1.2,
		"crew": 1,
		"ammo": "small_arms_ammunition",
		"ammo_per": 24,
		"attack": 1.7,
		"defense": 1.0,
		"armor": 0.1,
		"penetration": 1.4,
		"delivery": 2.0
	}
}
