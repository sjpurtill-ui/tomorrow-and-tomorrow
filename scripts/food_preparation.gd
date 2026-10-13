extends RefCounted
## Three ways of cooking the people can learn. What each gives the diet is in
## the food rules (food_system.gd); this file only names them for research.
static func entries()->Array[Dictionary]:
	return ENTRIES
const ENTRIES=[
	{
		"id": "hearth_roasting_control",
		"name": "Hearth Roasting Control",
		"direction": "Sustenance",
		"day": 0,
		"chance": 0.005,
		"requires": [
			"hearth_heat_retention"
		],
		"requires_all": [
			"hearth_heat_retention"
		],
		"requires_any": [],
		"signals": [
			"food",
			"crafting",
			"research"
		],
		"observation": "Manage distance and exposure of suitable food to a controlled hearth",
		"effects": {},
		"production_contract": "A way of working, not a building: there is nothing to install. What it gives comes as the people take it up.",
		"learning_routes": [
			{
				"id": "local",
				"label": "Hearth Roasting Control practice",
				"requires_all": []
			}
		]
	},
	{
		"id": "earth_oven_cooking",
		"name": "Earth Oven Cooking",
		"direction": "Sustenance",
		"day": 0,
		"chance": 0.005,
		"requires": [
			"hearth_roasting_control"
		],
		"requires_all": [
			"hearth_roasting_control"
		],
		"requires_any": [],
		"signals": [
			"food",
			"crafting",
			"research"
		],
		"observation": "Retain and transfer heat through an enclosed heated-earth or stone cooking arrangement",
		"effects": {},
		"production_contract": "A way of working, not a building: there is nothing to install. What it gives comes as the people take it up.",
		"learning_routes": [
			{
				"id": "local",
				"label": "Earth Oven Cooking practice",
				"requires_all": []
			}
		]
	},
	{
		"id": "food_steaming_vessels",
		"name": "Food Steaming Vessels",
		"direction": "Sustenance",
		"day": 0,
		"chance": 0.005,
		"requires": [
			"hearth_roasting_control"
		],
		"requires_all": [
			"hearth_roasting_control"
		],
		"requires_any": [
			[
				"clay_shaping",
				"basketry"
			]
		],
		"signals": [
			"food",
			"crafting",
			"research"
		],
		"observation": "Transfer heat to food through a qualified steam-producing vessel arrangement",
		"effects": {},
		"production_contract": "A way of working, not a building: there is nothing to install. What it gives comes as the people take it up.",
		"learning_routes": [
			{
				"id": "local",
				"label": "Food Steaming Vessels practice",
				"requires_all": []
			}
		]
	}
]
