extends RefCounted
static func entries()->Array:
	return [
  {
    "id": "clinical_observation_rounds",
    "name": "Clinical Observation Rounds",
    "direction": "health",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "case_records"
    ],
    "requires_all": [
      "case_records"
    ],
    "requires_any": [
      [
        "birth_attendants",
        "civic_infirmaries"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local clinical practice",
        "requires_all": []
      }
    ],
    "signals": [
      "health",
      "illness",
      "information"
    ],
    "observation": "Repeat and record a patient's condition rather than relying on one encounter",
    "effects": {},
    "clinical_care_method": "clinical_observation_rounds",
    "production_contract": "Reserves a configurable share of available local Knowledge labor for dated observations, consuming clay for records. Fresh assessments establish priority and make subsequent nursing possible; observations alone grant no health recovery."
  },
  {
    "id": "clinical_pulse_assessment",
    "name": "Clinical Pulse Assessment",
    "direction": "health",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clinical_observation_rounds",
      "standard_measures"
    ],
    "requires_all": [
      "clinical_observation_rounds",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local clinical practice",
        "requires_all": []
      }
    ],
    "signals": [
      "health",
      "illness",
      "information"
    ],
    "observation": "Compare pulse features and their change over time in clinical context",
    "effects": {},
    "clinical_care_method": "clinical_pulse_assessment",
    "production_contract": "Spends additional observation time to distinguish severity within coarse assessment groups, improving the order of subsequent care rounds. Pulse assessment needs the local observation service and record supplies; it grants no recovery by itself."
  },
  {
    "id": "nursing_care_organization",
    "name": "Nursing Care Organization",
    "direction": "health",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clinical_observation_rounds",
      "crew_handoffs"
    ],
    "requires_all": [
      "clinical_observation_rounds",
      "crew_handoffs"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local clinical practice",
        "requires_all": []
      }
    ],
    "signals": [
      "health",
      "illness",
      "information"
    ],
    "observation": "Organize continuous practical care, monitoring and handover around patient needs",
    "effects": {},
    "clinical_care_method": "nursing_care_organization",
    "production_contract": "Shares the observation workforce to provide supportive care using actual local water and woven cloth. Fresh observations and uninterrupted care improve bounded recovery; missing staff or supplies breaks continuity. Treatment competes with research for available Knowledge labor."
  }
]
