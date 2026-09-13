extends RefCounted
## Selected normalized assembly models; not a solver for arbitrary buildings.
## Retained dimensions and support condition generate the trial response.
const DETAILS={
 "timber_post_beam_connections":{"stiffness":80.0,"clearance":.004},
 "timber_splice_connections":{"stiffness":100.0,"clearance":.003},
 "timber_lateral_bracing":{"stiffness":140.0,"clearance":.002},
 "timber_moisture_movement_design":{"movement":.12,"allowance":.10},
 "building_drainage_coordination":{"channel_capacity":1.2,"blocked_fraction":.02},
 "building_wind_load_assessment":{"elastic_limit":1.3,"residual_compliance":.08},
 "building_capillary_breaks":{"bridged_fraction":.015,"permeance":.01},
 "roof_flashing_interfaces":{"overlap":.25,"exposed_joint":.10,"gap_fraction":.005},
 "rainscreen_wall_assemblies":{"drain_capacity":1.2,"open_joint_fraction":.04},
 "building_shading_design":{"projection":.7,"aperture_height":1.0}
}
static func prepare(method:String,condition:float)->Dictionary:
 if not DETAILS.has(method) or not is_finite(condition):return {}
 return {"method":method,"support_condition":clampf(condition,.1,1.0),"detail":DETAILS[method].duplicate(true)}

static func valid(value:Variant,method:String)->bool:
 if not value is Dictionary or value.get("method")!=method or not DETAILS.has(method):return false
 if not value.get("support_condition") is float and not value.get("support_condition") is int:return false
 var c:float=float(value.support_condition)
 if not is_finite(c) or c<.1 or c>1:return false
 if not value.get("detail") is Dictionary or value.detail.size()!=DETAILS[method].size():return false
 for key:String in DETAILS[method]:
  if not value.detail.get(key) is float and not value.detail.get(key) is int:return false
  var n:float=float(value.detail[key])
  if not is_finite(n) or n<0 or n>1000:return false
 return true

static func observe(value:Dictionary,stimulus:float=1.0)->Dictionary:
 var method:String=String(value.get("method",""))
 if not valid(value,method) or not is_finite(stimulus) or stimulus<=0:return {}
 var d:Dictionary=value.detail
 var c:float=float(value.support_condition)
 var response:float=0.0
 match method:
  "timber_post_beam_connections","timber_splice_connections","timber_lateral_bracing":
   response=stimulus/maxf(.001,float(d.stiffness)*c)+float(d.clearance)
  "timber_moisture_movement_design":
   response=maxf(0.0,float(d.movement)*stimulus-float(d.allowance)*c)
  "building_drainage_coordination":
   response=maxf(0.0,stimulus-float(d.channel_capacity)*c*(1.0-clampf(float(d.blocked_fraction),0,1)))
  "building_wind_load_assessment":
   response=maxf(0.0,stimulus-float(d.elastic_limit)*c)*float(d.residual_compliance)
  "building_capillary_breaks":
   response=stimulus*(clampf(float(d.bridged_fraction),0,1)+float(d.permeance)/c)
  "roof_flashing_interfaces":
   response=stimulus*(float(d.gap_fraction)/c+maxf(0.0,float(d.exposed_joint)-float(d.overlap)*c))
  "rainscreen_wall_assemblies":
   response=maxf(0.0,stimulus*float(d.open_joint_fraction)-float(d.drain_capacity)*c*.08)
  "building_shading_design":
   response=stimulus*(1.0-clampf(float(d.projection)*c/maxf(.001,float(d.aperture_height)),0,1))
 var trial:Dictionary=preload("res://scripts/settlement_fabric_inspection.gd").TRIALS[method]
 return {trial.stimulus:stimulus,trial.response:response,"uncertainty":.001}
