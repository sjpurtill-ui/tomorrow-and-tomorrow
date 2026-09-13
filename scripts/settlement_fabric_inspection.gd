extends RefCounted
## Selected field-trial acceptance envelopes, expressed in game measurement units.
## These are bounded game specifications, not universal engineering limits.
## The caller must obtain observations from paid site work; this classifier cannot
## create evidence or install a component merely from knowledge.
const TRIALS={
 "timber_post_beam_connections":{"stimulus":"proof_load","response":"joint_slip","minimum":1.0,"maximum":.04},
 "timber_splice_connections":{"stimulus":"proof_load","response":"splice_opening","minimum":1.0,"maximum":.03},
 "timber_lateral_bracing":{"stimulus":"lateral_load","response":"frame_drift","minimum":1.0,"maximum":.02},
 "timber_moisture_movement_design":{"stimulus":"moisture_cycle","response":"restrained_movement","minimum":1.0,"maximum":.08},
 "building_drainage_coordination":{"stimulus":"water_applied","response":"water_retained","minimum":1.0,"maximum":.10},
 "building_wind_load_assessment":{"stimulus":"lateral_load","response":"residual_displacement","minimum":1.0,"maximum":.015},
 "building_capillary_breaks":{"stimulus":"wet_contact_duration","response":"upper_surface_uptake","minimum":1.0,"maximum":.05},
 "roof_flashing_interfaces":{"stimulus":"water_applied","response":"interior_leakage","minimum":1.0,"maximum":.02},
 "rainscreen_wall_assemblies":{"stimulus":"driven_water_applied","response":"inner_wall_wetting","minimum":1.0,"maximum":.03},
 "building_shading_design":{"stimulus":"unshaded_irradiance","response":"shaded_irradiance","minimum":1.0,"maximum":.60}
}

static func classify(method:String,observation:Dictionary)->Dictionary:
 if not TRIALS.has(method):return {"state":"inconclusive","reason":"unknown_method"}
 var trial:Dictionary=TRIALS[method]
 for key:String in [String(trial.stimulus),String(trial.response),"uncertainty"]:
  if not observation.get(key) is float and not observation.get(key) is int:return {"state":"inconclusive","reason":"missing_measurement"}
  if not is_finite(float(observation[key])) or float(observation[key])<0:return {"state":"inconclusive","reason":"invalid_measurement"}
 var applied:float=float(observation[trial.stimulus])
 if applied<float(trial.minimum):return {"state":"inconclusive","reason":"insufficient_trial"}
 # Classification is qualified only near the selected reference exposure.
 # Do not let arbitrary overloads or long wetting periods dilute a bad result.
 if applied>float(trial.minimum)*1.25:return {"state":"inconclusive","reason":"outside_trial_envelope"}
 var response:float=float(observation[trial.response])/applied
 var uncertainty:float=float(observation.uncertainty)/applied
 var state:String="inconclusive"
 if response+uncertainty<=float(trial.maximum):state="accepted"
 elif response-uncertainty>float(trial.maximum):state="rejected"
 return {"state":state,"reason":"selected_trial_envelope","response_ratio":response,"uncertainty_ratio":uncertainty,"limit":float(trial.maximum),"observation":observation.duplicate(true)}
