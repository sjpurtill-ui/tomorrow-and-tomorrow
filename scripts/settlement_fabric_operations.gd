extends RefCounted
## Plot-local paid retrofit jobs. The settlement owner supplies shared builder work.
## Completion of assembly is not acceptance: inspection is a separate state.
const COMPONENTS={
 "timber_post_beam_connections":"Fitted Post Beam Sets",
 "timber_splice_connections":"Fitted Timber Splice Sets",
 "timber_lateral_bracing":"Timber Brace Sets",
 "timber_moisture_movement_design":"Timber Movement Joint Sets",
 "building_drainage_coordination":"Building Runoff Channels",
 "building_wind_load_assessment":"Building Wind Trial Frames",
 "building_capillary_breaks":"Capillary Break Courses",
 "roof_flashing_interfaces":"Roof Flashing Pieces",
 "rainscreen_wall_assemblies":"Rainscreen Batten Panels",
 "building_shading_design":"Building Shade Lattices"
}
const WORK={
 "timber_post_beam_connections":4.0,"timber_splice_connections":3.0,
 "timber_lateral_bracing":3.0,"timber_moisture_movement_design":2.0,
 "building_drainage_coordination":3.0,"building_wind_load_assessment":2.0,
 "building_capillary_breaks":3.0,"roof_flashing_interfaces":2.0,
 "rainscreen_wall_assemblies":4.0,"building_shading_design":2.0
}

static func start(plot:Dictionary,method:String,stock:Dictionary,known:Array,adoption:Dictionary,day:int)->Dictionary:
 if day<0 or not COMPONENTS.has(method):return {"ok":false,"reason":"Unknown method or invalid day."}
 if int(plot.get("id",0))<=0 or String(plot.get("status","")) not in ["active","stressed","damaged"]:
  return {"ok":false,"reason":"Requires an existing occupied plot."}
 if not compatible(plot,method):return {"ok":false,"reason":"This method does not fit the recorded building fabric."}
 if not foundations_met(method,known):return {"ok":false,"reason":"Required local foundations are absent."}
 if not plot.get("fabric_job",{}).is_empty():return {"ok":false,"reason":"This plot already has work pending."}
 if method not in known or float(adoption.get(method,0))<.25:return {"ok":false,"reason":"Local adoption is insufficient."}
 var component:String=COMPONENTS[method]
 var available:float=float(stock.get(component,0))
 if not is_finite(available) or available<1:return {"ok":false,"reason":"A prepared component batch must be delivered."}
 # Reserve by consuming at start; interruption cannot duplicate installed inputs.
 stock[component]=available-1.0
 plot.fabric_job={"method":method,"component":component,"paid":1.0,"work":0.0,"required_work":WORK[method],"started_day":day,"last_day":day,"state":"assembling"}
 return {"ok":true}

static func advance(plot:Dictionary,work:float,day:int)->float:
 var job:Dictionary=plot.get("fabric_job",{})
 if job.is_empty() or not valid_job(job) or not is_finite(work) or work<=0:return 0.0
 if day<=int(job.last_day) or String(job.state)!="assembling":return 0.0
 if String(plot.get("status","")) not in ["active","stressed","damaged"]:return 0.0
 var used:float=minf(work,float(job.required_work)-float(job.work))
 job.work=float(job.work)+used
 job.last_day=day
 if float(job.work)>=float(job.required_work):job.state="awaiting_inspection"
 return used

static func valid_job(value:Variant)->bool:
 if not value is Dictionary:return false
 if value.is_empty():return true
 var method:String=String(value.get("method",""))
 if not COMPONENTS.has(method) or value.get("component")!=COMPONENTS[method]:return false
 for key:String in ["paid","work","required_work","started_day","last_day"]:
  if not value.get(key) is float and not value.get(key) is int:return false
  if not is_finite(float(value[key])):return false
 if float(value.paid)!=1.0 or float(value.required_work)!=float(WORK[method]):return false
 if float(value.work)<0 or float(value.work)>float(value.required_work):return false
 if float(value.started_day)<0 or float(value.started_day)!=floorf(float(value.started_day)):return false
 if float(value.last_day)<float(value.started_day) or float(value.last_day)!=floorf(float(value.last_day)):return false
 if value.get("state") not in ["assembling","awaiting_inspection"]:return false
 return (String(value.state)=="awaiting_inspection")==is_equal_approx(float(value.work),float(value.required_work))

static func needs_work(plot:Dictionary)->bool:
 var job:Variant=plot.get("fabric_job",{})
 return valid_job(job) and not job.is_empty() and String(job.state)=="assembling" and String(plot.get("status","")) in ["active","stressed","damaged"]

static func foundations_met(method:String,known:Array)->bool:
 for entry:Dictionary in preload("res://scripts/settlement_fabric_knowledge.gd").entries():
  if String(entry.id)!=method:continue
  for parent:String in entry.requires_all:
   if parent not in known:return false
  for group:Array in entry.requires_any:
   var found:=false
   for parent:String in group:
    if parent in known:found=true
   if not found:return false
  return true
 return false

static func compatible(plot:Dictionary,method:String)->bool:
 if not COMPONENTS.has(method):return false
 var use:String=String(plot.get("land_use",""))
 if use not in ["residential_compound","mixed_household","workshop","storage","market","civic","communal","sacred","dirty_industry","hospitality"]:return false
 var family:String=String(plot.get("material_family",""))
 if method in ["timber_post_beam_connections","timber_splice_connections","timber_lateral_bracing","timber_moisture_movement_design"]:
  return family in ["organic","timber"]
 if method=="building_capillary_breaks":return family in ["stone","earth"]
 return family in ["organic","timber","stone","earth"]
