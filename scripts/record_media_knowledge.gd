extends RefCounted
## Physical record supplies used by finite local collection study.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "clay_record_tablets",
    "name": "Clay Record Tablets",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clay_shaping",
      "pictographic_records"
    ],
    "requires_all": [
      "clay_shaping",
      "pictographic_records"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Clay Record Tablets",
        "requires_all": []
      }
    ],
    "signals": [
      "information",
      "crafting",
      "research"
    ],
    "observation": "Impress or inscribe records on prepared clay and preserve selected tablets. Suitable clay, marking tools, skilled recorders and storage.",
    "effects": {},
    "production_items": [
      "clay_record_tablets"
    ],
    "production_contract": "Paid civilian batches produce actual record media. Local collection study allocates these supplies to notes alongside finite Knowledge work. Tablets and bound paper volumes support comparison; trained use of knotted records supports specimen quantity observations only. No purchased medium teaches its manufacture, translates a manuscript or grants instant research. The bound-volume implementation uses paper, not an invented parchment source."
  },
  {
    "id": "knotted_record_systems",
    "name": "Knotted Record Systems",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cordage",
      "tallies"
    ],
    "requires_all": [
      "cordage",
      "tallies"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Knotted Record Systems",
        "requires_all": []
      }
    ],
    "signals": [
      "information",
      "crafting",
      "research"
    ],
    "observation": "Encode agreed quantities or categories through structured knots and cord arrangements. Suitable cords, trained interpreters and shared conventions.",
    "effects": {},
    "production_items": [
      "knotted_record_cords"
    ],
    "production_contract": "Paid civilian batches produce actual record media. Local collection study allocates these supplies to notes alongside finite Knowledge work. Tablets and bound paper volumes support comparison; trained use of knotted records supports specimen quantity observations only. No purchased medium teaches its manufacture, translates a manuscript or grants instant research. The bound-volume implementation uses paper, not an invented parchment source."
  },
  {
    "id": "bookbinding_assemblies",
    "name": "Bookbinding Assemblies",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cordage"
    ],
    "requires_all": [
      "cordage"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Bookbinding Assemblies",
        "requires_all": []
      }
    ],
    "signals": [
      "information",
      "crafting",
      "research"
    ],
    "observation": "Join record leaves and protective covers into a usable ordered volume. Prepared leaves, bindings, skilled labor and compatible materials.",
    "effects": {},
    "production_items": [
      "bound_record_books"
    ],
    "production_contract": "Paid civilian batches produce actual record media. Local collection study allocates these supplies to notes alongside finite Knowledge work. Tablets and bound paper volumes support comparison; trained use of knotted records supports specimen quantity observations only. No purchased medium teaches its manufacture, translates a manuscript or grants instant research. The bound-volume implementation uses paper, not an invented parchment source."
  }
]
