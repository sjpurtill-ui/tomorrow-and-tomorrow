extends RefCounted
static func entries()->Array:
	return [
  {
    "id": "aggregate_road_foundations",
    "name": "Aggregate Road Foundations",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "graded_roads",
      "structural_load_testing"
    ],
    "requires_all": [
      "graded_roads",
      "structural_load_testing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local rail service trials",
        "requires_all": []
      }
    ],
    "signals": [
      "movement",
      "crafting",
      "construction"
    ],
    "observation": "Build a load-spreading granular foundation matched to ground conditions.",
    "effects": {},
    "production_items": [
      "track_ballast"
    ],
    "production_contract": "Manufactures paid Track Ballast. Installed wagonways require a surveyed owned route, compatible wagons and brakes, actual construction work and continuing supplies. Capacity and crews remain committed through the return journey; worn or occupied routes cannot dispatch. The current haulage is human-worked; engines and animals are not supplied by this discovery.",
    "rail_service_method": "aggregate_road_foundations"
  },
  {
    "id": "rail_gauge_standards",
    "name": "Rail-Gauge Standards",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "standard_measures",
      "workshop_standards"
    ],
    "requires_all": [
      "standard_measures",
      "workshop_standards"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local rail service trials",
        "requires_all": []
      }
    ],
    "signals": [
      "movement",
      "crafting",
      "construction"
    ],
    "observation": "Specify compatible track spacing and wheel relationships for a railway.",
    "effects": {},
    "production_items": [
      "rail_gauge_templates",
      "rail_wheelsets_900",
      "rail_wheelsets_1435"
    ],
    "production_contract": "Manufactures paid Rail Gauge Templates, 900 mm Rail Wheelsets, 1435 mm Rail Wheelsets. Installed wagonways require a surveyed owned route, compatible wagons and brakes, actual construction work and continuing supplies. Capacity and crews remain committed through the return journey; worn or occupied routes cannot dispatch. The current haulage is human-worked; engines and animals are not supplied by this discovery.",
    "rail_service_method": "rail_gauge_standards"
  },
  {
    "id": "rail_track_foundations",
    "name": "Rail-Track Foundations",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "aggregate_road_foundations",
      "rail_gauge_standards"
    ],
    "requires_all": [
      "aggregate_road_foundations",
      "rail_gauge_standards"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local rail service trials",
        "requires_all": []
      }
    ],
    "signals": [
      "movement",
      "crafting",
      "construction"
    ],
    "observation": "Support and align rails over a maintained load-spreading foundation.",
    "effects": {},
    "production_items": [
      "timber_rail_panels"
    ],
    "production_contract": "Manufactures paid Timber Rail Panels. Installed wagonways require a surveyed owned route, compatible wagons and brakes, actual construction work and continuing supplies. Capacity and crews remain committed through the return journey; worn or occupied routes cannot dispatch. The current haulage is human-worked; engines and animals are not supplied by this discovery.",
    "rail_service_method": "rail_track_foundations"
  },
  {
    "id": "wagonway_haulage",
    "name": "Wagonway Haulage",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "rail_track_foundations",
      "cart_running_gear"
    ],
    "requires_all": [
      "rail_track_foundations",
      "cart_running_gear"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local rail service trials",
        "requires_all": []
      }
    ],
    "signals": [
      "movement",
      "crafting",
      "construction"
    ],
    "observation": "Use guided wagons to reduce resistance on a prepared route.",
    "effects": {},
    "production_items": [
      "rail_wagons_900",
      "rail_wagons_1435"
    ],
    "production_contract": "Manufactures paid 900 mm Rail Wagons, 1435 mm Rail Wagons. Installed wagonways require a surveyed owned route, compatible wagons and brakes, actual construction work and continuing supplies. Capacity and crews remain committed through the return journey; worn or occupied routes cannot dispatch. The current haulage is human-worked; engines and animals are not supplied by this discovery.",
    "rail_service_method": "wagonway_haulage"
  },
  {
    "id": "rail_vehicle_braking",
    "name": "Rail-Vehicle Braking",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "friction_measurement",
      "rail_track_foundations"
    ],
    "requires_all": [
      "friction_measurement",
      "rail_track_foundations"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local rail service trials",
        "requires_all": []
      }
    ],
    "signals": [
      "movement",
      "crafting",
      "construction"
    ],
    "observation": "Control and inspect braking effort across moving rail vehicles.",
    "effects": {},
    "production_items": [
      "rail_brake_sets"
    ],
    "production_contract": "Manufactures paid Rail Brake Sets. Installed wagonways require a surveyed owned route, compatible wagons and brakes, actual construction work and continuing supplies. Capacity and crews remain committed through the return journey; worn or occupied routes cannot dispatch. The current haulage is human-worked; engines and animals are not supplied by this discovery.",
    "rail_service_method": "rail_vehicle_braking"
  }
]
