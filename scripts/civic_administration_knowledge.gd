extends RefCounted
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "jurisdiction_boundaries",
    "name": "Jurisdiction Boundaries",
    "direction": "Society",
    "dynamic": "institutions",
    "subcategory": "Administration",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "regional_maps",
      "customary_law"
    ],
    "requires_all": [
      "regional_maps",
      "customary_law"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Jurisdiction Boundaries",
        "requires_all": []
      }
    ],
    "signals": [
      "administration",
      "research",
      "information"
    ],
    "observation": "Specify which authority handles a dispute by place, party or subject",
    "effects": {},
    "operating_contract": "Existing appointed officials and reserved administrative work maintain local scope, finite mandates, pending-duty custody and condition-backed petition dispositions. Knowledge grants no officials, settlement ownership or instant relief."
  },
  {
    "id": "official_mandate_registers",
    "name": "Official Mandate Registers",
    "direction": "Society",
    "dynamic": "institutions",
    "subcategory": "Administration",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "professional_service",
      "jurisdiction_boundaries"
    ],
    "requires_all": [
      "professional_service",
      "jurisdiction_boundaries"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Official Mandate Registers",
        "requires_all": []
      }
    ],
    "signals": [
      "administration",
      "research",
      "information"
    ],
    "observation": "Record which powers each office holds and when authorization ends",
    "effects": {},
    "operating_contract": "Existing appointed officials and reserved administrative work maintain local scope, finite mandates, pending-duty custody and condition-backed petition dispositions. Knowledge grants no officials, settlement ownership or instant relief."
  },
  {
    "id": "public_office_handover",
    "name": "Public Office Handover",
    "direction": "Society",
    "dynamic": "institutions",
    "subcategory": "Administration",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "professional_service",
      "formal_archives"
    ],
    "requires_all": [
      "professional_service",
      "formal_archives"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Public Office Handover",
        "requires_all": []
      }
    ],
    "signals": [
      "administration",
      "research",
      "information"
    ],
    "observation": "Transfer pending duties, records and assets when officials change",
    "effects": {},
    "operating_contract": "Existing appointed officials and reserved administrative work maintain local scope, finite mandates, pending-duty custody and condition-backed petition dispositions. Knowledge grants no officials, settlement ownership or instant relief."
  },
  {
    "id": "petition_registers",
    "name": "Petition Registers",
    "direction": "Society",
    "dynamic": "institutions",
    "subcategory": "Administration",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "phonetic_notation",
      "professional_service"
    ],
    "requires_all": [
      "phonetic_notation",
      "professional_service"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Petition Registers",
        "requires_all": []
      }
    ],
    "signals": [
      "administration",
      "research",
      "information"
    ],
    "observation": "Record submitted grievances and their disposition",
    "effects": {},
    "operating_contract": "Existing appointed officials and reserved administrative work maintain local scope, finite mandates, pending-duty custody and condition-backed petition dispositions. Knowledge grants no officials, settlement ownership or instant relief."
  }
]
