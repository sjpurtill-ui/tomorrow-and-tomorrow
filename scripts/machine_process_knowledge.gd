extends RefCounted
# Registered after finite process and downstream consumer checks; integration remains separate.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "fluid_film_bearings",
    "name": "Fluid-Film Bearings",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "viscous_resistance",
      "lubrication_regimes"
    ],
    "requires_all": [
      "viscous_resistance",
      "lubrication_regimes"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Fluid-Film Bearings",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Support moving surfaces through a maintained fluid film",
    "effects": {},
    "operating_contract": "Qualified geometry, lubricant supply and suitable operating conditions"
  },
  {
    "id": "cutting_fluid_management",
    "name": "Cutting-Fluid Management",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "calorimetry",
      "lubrication_regimes"
    ],
    "requires_all": [
      "calorimetry",
      "lubrication_regimes"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cutting-Fluid Management",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Maintain a qualified fluid supply for a machining duty",
    "effects": {},
    "operating_contract": "Compatible fluid, delivery, filtration and maintenance"
  },
  {
    "id": "machine_tool_stiffness_assessment",
    "name": "Machine-Tool Stiffness Assessment",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "stress_strain_relations",
      "dimensional_metrology"
    ],
    "requires_all": [
      "stress_strain_relations",
      "dimensional_metrology"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Machine-Tool Stiffness Assessment",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Measure machine deformation under representative working loads",
    "effects": {},
    "operating_contract": "Qualified tests, instruments and workholding"
  },
  {
    "id": "machine_condition_monitoring",
    "name": "Machine-Condition Monitoring",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "mechanical_oscillation",
      "statistical_sampling"
    ],
    "requires_all": [
      "mechanical_oscillation",
      "statistical_sampling"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Machine-Condition Monitoring",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Track observed machine behavior against a maintained condition baseline",
    "effects": {},
    "operating_contract": "Sensors or inspections, records and qualified review"
  },
  {
    "id": "numerical_machine_control",
    "name": "Numerical Machine Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "electronic_machine_control",
      "coordinate_geometry"
    ],
    "requires_all": [
      "electronic_machine_control",
      "coordinate_geometry"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Numerical Machine Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Drive qualified machine motion from a defined numerical program",
    "effects": {},
    "operating_contract": "Compatible machine, program, tools and setup verification"
  },
  {
    "id": "gear_power_skiving",
    "name": "Gear Power Skiving",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "gear_tooth_generation",
      "numerical_machine_control"
    ],
    "requires_all": [
      "gear_tooth_generation",
      "numerical_machine_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Gear Power Skiving",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Synchronized crossed-axis rotation creates a continuous gear cutting action.",
    "effects": {},
    "operating_contract": "Spend compatible cutter, blank, drive energy and synchronization setup; check tooth geometry and collision clearance."
  },
  {
    "id": "wire_electrical_discharge_machining",
    "name": "Wire Electrical-Discharge Machining",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "electrical_measurement",
      "numerical_machine_control"
    ],
    "requires_all": [
      "electrical_measurement",
      "numerical_machine_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Wire Electrical-Discharge Machining",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A traveling electrode wire erodes conductive stock by discharges.",
    "effects": {},
    "operating_contract": "Consume wire, dielectric service, electrical energy and machining work; retain access, kerf and surface-integrity checks."
  },
  {
    "id": "sinker_electrical_discharge_machining",
    "name": "Sinker Electrical-Discharge Machining",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "electrical_measurement",
      "precision_machinery"
    ],
    "requires_all": [
      "electrical_measurement",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Sinker Electrical-Discharge Machining",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A shaped electrode erodes a matching conductive cavity.",
    "effects": {},
    "operating_contract": "Pay electrode manufacture, dielectric handling, power and gap-control work; measure electrode wear and cavity finish."
  },
  {
    "id": "electrochemical_machining",
    "name": "Electrochemical Machining",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "electrochemical_cells",
      "precision_machinery"
    ],
    "requires_all": [
      "electrochemical_cells",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Electrochemical Machining",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Controlled anodic dissolution removes conductive workpiece material.",
    "effects": {},
    "operating_contract": "Consume electrical charge, electrolyte circulation and tool-gap work; qualify chemistry and account for dissolved material."
  },
  {
    "id": "abrasive_waterjet_cutting",
    "name": "Abrasive Waterjet Cutting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "pressure_vessels",
      "numerical_machine_control"
    ],
    "requires_all": [
      "pressure_vessels",
      "numerical_machine_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Abrasive Waterjet Cutting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Pressurized water carries abrasive through a cutting jet.",
    "effects": {},
    "operating_contract": "Pay pumping energy, water, abrasive, nozzle wear and traverse work; retain kerf taper and entry damage limits."
  },
  {
    "id": "ultrasonic_abrasive_machining",
    "name": "Ultrasonic Abrasive Machining",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "mechanical_oscillation",
      "precision_machinery"
    ],
    "requires_all": [
      "mechanical_oscillation",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Ultrasonic Abrasive Machining",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A vibrating tool drives loose abrasive against brittle material.",
    "effects": {},
    "operating_contract": "Pay shaped tools, slurry, energy and feed work; retain tool wear and edge-chipping checks."
  },
  {
    "id": "incremental_sheet_forming",
    "name": "Incremental Sheet Forming",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "numerical_machine_control",
      "sheet_steel_rolling"
    ],
    "requires_all": [
      "numerical_machine_control",
      "sheet_steel_rolling"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Incremental Sheet Forming",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Localized tool passes gradually shape a supported sheet.",
    "effects": {},
    "operating_contract": "Pay fixture, toolpath generation, work and thickness measurements; retain compliance and springback errors."
  },
  {
    "id": "ultrasonic_metal_joining",
    "name": "Ultrasonic Metal Joining",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "mechanical_oscillation",
      "precision_machinery"
    ],
    "requires_all": [
      "mechanical_oscillation",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Ultrasonic Metal Joining",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Vibration under pressure creates a solid-state metal joint.",
    "effects": {},
    "operating_contract": "Pay compatible contacting parts, sonotrode wear, clamping and energy; retain joint-area and destructive-sample acceptance."
  }
]
