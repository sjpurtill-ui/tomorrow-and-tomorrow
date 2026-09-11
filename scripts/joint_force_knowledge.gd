extends RefCounted
## Stable military application IDs share civilian scientific foundations.
static func entries()->Array:
	return [
		{
			"id": "pike_drill",
			"name": "Pike Formations",
			"direction": "Warfare",
			"day": 5000,
			"chance": 0.001,
			"requires": [
				"shield_wall"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate pike formations through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "crossbow_mechanism",
			"name": "Crossbow Mechanisms",
			"direction": "Warfare",
			"day": 5000,
			"chance": 0.001,
			"requires": [
				"bow_craft",
				"joinery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate crossbow mechanisms through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "war_chariots",
			"name": "Military Chariots",
			"direction": "Warfare",
			"day": 5000,
			"chance": 0.001,
			"requires": [
				"domesticated_mounts",
				"joinery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate military chariots through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "armored_riding",
			"name": "Armored Riding",
			"direction": "Warfare",
			"day": 5000,
			"chance": 0.001,
			"requires": [
				"domesticated_mounts",
				"bronze_weaponry"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate armored riding through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "elephant_training",
			"name": "Working Elephant Training",
			"direction": "Warfare",
			"day": 5000,
			"chance": 0.001,
			"requires": [
				"animal_taming",
				"supply_groups"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate working elephant training through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "counterweight_engines",
			"name": "Counterweight Siege Engines",
			"direction": "Warfare",
			"day": 5000,
			"chance": 0.001,
			"requires": [
				"siege_engineering",
				"rope_rigging"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate counterweight siege engines through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "matchlock_drill",
			"name": "Matchlock Arms and Drill",
			"direction": "Warfare",
			"day": 5000,
			"chance": 0.001,
			"requires": [
				"black_powder",
				"precision_machinery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate matchlock arms and drill through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "mounted_firearms",
			"name": "Mounted Firearms",
			"direction": "Warfare",
			"day": 5000,
			"chance": 0.001,
			"requires": [
				"matchlock_drill",
				"domesticated_mounts"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate mounted firearms through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "galley_navigation",
			"name": "Galley Navigation",
			"direction": "Warfare",
			"day": 15000,
			"chance": 0.001,
			"requires": [
				"coastal_watercraft",
				"formation_drill"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate galley navigation through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "naval_arsenals",
			"name": "Naval Arsenals",
			"direction": "Warfare",
			"day": 15000,
			"chance": 0.001,
			"requires": [
				"galley_navigation",
				"workshop_standards"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate naval arsenals through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "ocean_sailing",
			"name": "Ocean Sailing",
			"direction": "Warfare",
			"day": 15000,
			"chance": 0.001,
			"requires": [
				"coastal_watercraft",
				"rope_rigging",
				"regional_maps"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate ocean sailing through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "naval_gunnery",
			"name": "Naval Gunnery",
			"direction": "Warfare",
			"day": 15000,
			"chance": 0.001,
			"requires": [
				"ocean_sailing",
				"powder_artillery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate naval gunnery through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "steam_propulsion",
			"name": "Steam Propulsion",
			"direction": "Materials",
			"day": 77000,
			"chance": 0.001,
			"requires": [
				"heat_engine_cycles",
				"precision_machinery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate steam propulsion through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "armored_hulls",
			"name": "Armored Hulls",
			"direction": "Warfare",
			"day": 78000,
			"chance": 0.001,
			"requires": [
				"steam_propulsion",
				"naval_gunnery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate armored hulls through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "naval_torpedoes",
			"name": "Naval Torpedoes",
			"direction": "Warfare",
			"day": 79000,
			"chance": 0.001,
			"requires": [
				"steam_propulsion",
				"precision_machinery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate naval torpedoes through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "naval_fire_control",
			"name": "Naval Fire Control",
			"direction": "Warfare",
			"day": 80000,
			"chance": 0.001,
			"requires": [
				"armored_hulls",
				"military_staffs"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate naval fire control through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "submersible_hulls",
			"name": "Submersible Hulls",
			"direction": "Warfare",
			"day": 81000,
			"chance": 0.001,
			"requires": [
				"naval_torpedoes",
				"armored_hulls"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate submersible hulls through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "naval_logistics",
			"name": "Fleet Replenishment",
			"direction": "Warfare",
			"day": 82000,
			"chance": 0.001,
			"requires": [
				"steam_propulsion",
				"supply_groups"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate fleet replenishment through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "aerostat_observation",
			"name": "Aerostat Observation",
			"direction": "Warfare",
			"day": 83000,
			"chance": 0.001,
			"requires": [
				"woven_carriers",
				"regional_maps"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate aerostat observation through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "fuel_refining",
			"name": "Liquid Fuel Refining",
			"direction": "Materials",
			"day": 84000,
			"chance": 0.001,
			"requires": [
				"fractional_distillation",
				"precision_machinery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate liquid fuel refining through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "powered_flight",
			"name": "Powered Flight",
			"direction": "Materials",
			"day": 85000,
			"chance": 0.001,
			"requires": [
				"aerodynamics",
				"structural_load_testing",
				"internal_combustion"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate powered flight through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "fighter_tactics",
			"name": "Fighter Tactics",
			"direction": "Warfare",
			"day": 86000,
			"chance": 0.001,
			"requires": [
				"powered_flight",
				"formation_drill"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate fighter tactics through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "aerial_bombardment",
			"name": "Aerial Bombardment",
			"direction": "Warfare",
			"day": 87000,
			"chance": 0.001,
			"requires": [
				"powered_flight",
				"powder_artillery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate aerial bombardment through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "advanced_airframes",
			"name": "Advanced Airframes",
			"direction": "Materials",
			"day": 88000,
			"chance": 0.001,
			"requires": [
				"powered_flight",
				"wind_tunnel_testing",
				"structural_load_testing"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate advanced airframes through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "naval_aviation",
			"name": "Naval Aviation",
			"direction": "Warfare",
			"day": 89000,
			"chance": 0.001,
			"requires": [
				"powered_flight",
				"naval_torpedoes"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate naval aviation through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "carrier_aviation",
			"name": "Carrier Aviation",
			"direction": "Warfare",
			"day": 90000,
			"chance": 0.001,
			"requires": [
				"naval_aviation",
				"naval_fire_control"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate carrier aviation through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "airborne_operations",
			"name": "Airborne Operations",
			"direction": "Warfare",
			"day": 91000,
			"chance": 0.001,
			"requires": [
				"advanced_airframes",
				"professional_corps"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate airborne operations through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "amphibious_operations",
			"name": "Amphibious Operations",
			"direction": "Warfare",
			"day": 92000,
			"chance": 0.001,
			"requires": [
				"naval_arsenals",
				"professional_corps"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate amphibious operations through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "jet_propulsion",
			"name": "Jet Propulsion",
			"direction": "Materials",
			"day": 93000,
			"chance": 0.001,
			"requires": [
				"advanced_airframes",
				"heat_engine_cycles"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate jet propulsion through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "rotary_wing",
			"name": "Rotary-Wing Flight",
			"direction": "Warfare",
			"day": 94000,
			"chance": 0.001,
			"requires": [
				"advanced_airframes"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate rotary-wing flight through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "guided_weapons",
			"name": "Guided Weapons",
			"direction": "Warfare",
			"day": 95000,
			"chance": 0.001,
			"requires": [
				"jet_propulsion",
				"naval_fire_control"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate guided weapons through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "naval_missiles",
			"name": "Naval Missiles",
			"direction": "Warfare",
			"day": 96000,
			"chance": 0.001,
			"requires": [
				"guided_weapons",
				"naval_torpedoes"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate naval missiles through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "nuclear_propulsion",
			"name": "Nuclear Propulsion",
			"direction": "Warfare",
			"day": 97000,
			"chance": 0.001,
			"requires": [
				"reactor_engineering",
				"submersible_hulls"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate nuclear propulsion through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "remote_aircraft",
			"name": "Remote Aircraft",
			"direction": "Warfare",
			"day": 98000,
			"chance": 0.001,
			"requires": [
				"guided_weapons",
				"advanced_airframes"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Develop and demonstrate remote aircraft through trained crews, reliable equipment and repeatable supply.",
			"effects": {
				"warfare_readiness": 0.035,
				"task_coordination": 0.015
			}
		},
		{
			"id": "rifled_barrels",
			"name": "Rifled Barrels",
			"direction": "Warfare",
			"day": 40000,
			"chance": 0.001,
			"requires": [
				"matchlock_drill",
				"precision_machinery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Reliable rifled barrels allow standardized military equipment and specialist training.",
			"effects": {
				"warfare_readiness": 0.035
			}
		},
		{
			"id": "metallic_cartridges",
			"name": "Metallic Cartridges",
			"direction": "Warfare",
			"day": 42000,
			"chance": 0.001,
			"requires": [
				"rifled_barrels"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Reliable metallic cartridges allow standardized military equipment and specialist training.",
			"effects": {
				"warfare_readiness": 0.035
			}
		},
		{
			"id": "automatic_actions",
			"name": "Automatic Firearms",
			"direction": "Warfare",
			"day": 44000,
			"chance": 0.001,
			"requires": [
				"metallic_cartridges",
				"precision_machinery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Reliable automatic firearms allow standardized military equipment and specialist training.",
			"effects": {
				"warfare_readiness": 0.035
			}
		},
		{
			"id": "internal_combustion",
			"name": "Internal Combustion Engines",
			"direction": "Materials",
			"day": 46000,
			"chance": 0.001,
			"requires": [
				"fuel_refining",
				"heat_engine_cycles",
				"precision_machinery"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Reliable internal combustion engines allow standardized military equipment and specialist training.",
			"effects": {
				"warfare_readiness": 0.035
			}
		},
		{
			"id": "armored_vehicles",
			"name": "Armored Fighting Vehicles",
			"direction": "Warfare",
			"day": 48000,
			"chance": 0.001,
			"requires": [
				"internal_combustion",
				"armored_hulls"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Reliable armored fighting vehicles allow standardized military equipment and specialist training.",
			"effects": {
				"warfare_readiness": 0.035
			}
		},
		{
			"id": "indirect_fire",
			"name": "Indirect Artillery Fire",
			"direction": "Warfare",
			"day": 50000,
			"chance": 0.001,
			"requires": [
				"powder_artillery",
				"military_staffs"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Reliable indirect artillery fire allow standardized military equipment and specialist training.",
			"effects": {
				"warfare_readiness": 0.035
			}
		},
		{
			"id": "armor_piercing_weapons",
			"name": "Armor-Piercing Weapons",
			"direction": "Warfare",
			"day": 52000,
			"chance": 0.001,
			"requires": [
				"armored_vehicles",
				"indirect_fire"
			],
			"signals": [
				"warfare",
				"crafting",
				"information"
			],
			"observation": "Reliable armor-piercing weapons allow standardized military equipment and specialist training.",
			"effects": {
				"warfare_readiness": 0.035
			}
		},
		{
			"id": "atomic_physics",
			"name": "Atomic Physics",
			"direction": "Information",
			"day": 90000,
			"chance": 0.001,
			"requires": [
				"spectroscopy",
				"electron_physics"
			],
			"signals": [
				"knowledge",
				"information"
			],
			"observation": "Spectra and charged-particle experiments support models of atomic structure.",
			"effects": {
				"task_coordination": 0.01
			}
		},
		{
			"id": "reactor_engineering",
			"name": "Controlled Nuclear Reactors",
			"direction": "Materials",
			"day": 95000,
			"chance": 0.001,
			"requires": [
				"nuclear_fission",
				"neutron_moderation",
				"pressure_vessels",
				"electrical_generators"
			],
			"signals": [
				"crafting",
				"information"
			],
			"observation": "Reaction control, cooling, containment and instrumentation are combined into a reactor design; operation still needs a constructed plant and fuel.",
			"effects": {
				"task_coordination": 0.02
			}
		}
	]
