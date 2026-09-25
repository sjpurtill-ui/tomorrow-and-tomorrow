extends RefCounted
## Authored chemical separations feeding physical industrial supply chains.
static func entries()->Array[Dictionary]:
	return [
	  {
	    "id": "brine_purification",
	    "name": "Brine Purification",
	    "direction": "Materials",
	    "day": 65000,
	    "chance": 0.002,
	    "requires": [
	      "salt_working",
	      "water_settling_basins",
	      "chemical_distillation"
	    ],
	    "requires_all": [
	      "salt_working",
	      "water_settling_basins",
	      "chemical_distillation"
	    ],
	    "signals": [
	      "crafting",
	      "research",
	      "materials"
	    ],
	    "observation": "Settling and filtered clarification remove suspended contamination from prepared salt solutions.",
	    "effects": {},
	    "production_items": [
	      "purified_brine"
	    ],
	    "production_contract": "Enables a physical batch-production line with consumed feedstocks, installed tooling, shared Crafting labor and any specified electricity. Products exist only after completed work; quantities are abstract game batches."
	  },
	  {
	    "id": "chloralkali_cells",
	    "name": "Chlor-Alkali Cells",
	    "direction": "Materials",
	    "day": 65000,
	    "chance": 0.002,
	    "requires": [
	      "brine_purification",
	      "electrochemical_cells",
	      "electrical_generators",
	      "pressure_vessels"
	    ],
	    "requires_all": [
	      "brine_purification",
	      "electrochemical_cells",
	      "electrical_generators",
	      "pressure_vessels"
	    ],
	    "signals": [
	      "crafting",
	      "research",
	      "materials"
	    ],
	    "observation": "Separated electrolysis compartments recover chlorine, caustic soda and hydrogen from the same brine feed.",
	    "effects": {},
	    "production_items": ["chloralkali_batch", "laundry_soap"],
	    "production_contract": "Enables a physical batch-production line with consumed feedstocks, installed tooling, shared Crafting labor and any specified electricity. Products exist only after completed work; quantities are abstract game batches."
	  },
	  {
	    "id": "hydrogen_chloride_synthesis",
	    "name": "Hydrogen Chloride Synthesis",
	    "direction": "Materials",
	    "day": 65000,
	    "chance": 0.002,
	    "requires": [
	      "chloralkali_cells",
	      "pressure_vessels",
	      "chemical_distillation"
	    ],
	    "requires_all": [
	      "chloralkali_cells",
	      "pressure_vessels",
	      "chemical_distillation"
	    ],
	    "signals": [
	      "crafting",
	      "research",
	      "materials"
	    ],
	    "observation": "Contained gas processing combines recovered hydrogen and chlorine into an industrial silicon-processing reagent.",
	    "effects": {},
	    "production_items": [
	      "hydrogen_chloride"
	    ],
	    "production_contract": "Enables a physical batch-production line with consumed feedstocks, installed tooling, shared Crafting labor and any specified electricity. Products exist only after completed work; quantities are abstract game batches."
	  },
{
  "id": "soap_manufacture",
  "name": "Soap Manufacture",
  "direction": "Materials",
  "day": 0,
  "chance": 0.002,
  "requires": [
    "experimental_controls",
    "seed_oil_pressing"
  ],
  "requires_all": [
    "experimental_controls",
    "seed_oil_pressing"
  ],
  "requires_any": [],
  "learning_routes": [
    {
      "id": "local",
      "label": "Soap manufacture trials",
      "requires_all": []
    }
  ],
  "signals": [
    "crafting",
    "research",
    "materials"
  ],
  "observation": "Controlled processing converts an existing plant oil and alkali into a cleaning material for supplied washing.",
  "effects": {},
  "production_items": ["oil_lye_soap"],
  "production_contract": "Completed civilian batches consume drying seed oil, caustic soda, water and fuel with paid vessels and labor. This implements the plant-oil route only. Laundry appliances consume the actual product; no animal fat, clinical qualification or global sanitation bonus is granted."
}
	]
