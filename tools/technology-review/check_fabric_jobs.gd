extends SceneTree
const F=preload("res://scripts/settlement_fabric_operations.gd")
func _initialize()->void:
 for method:String in F.COMPONENTS:
  var plot:Dictionary={"id":1,"status":"active","form":"inherited_house","land_use":"residential_compound","material_family":"stone" if method=="building_capillary_breaks" else "timber"}
  var item:String=F.COMPONENTS[method]
  var stock:Dictionary={item:1.0}
  assert(not F.start(plot,method,stock,[],{},1).ok)
  assert(stock[item]==1.0)
  var known:Array=[method]
  for entry:Dictionary in preload("res://scripts/settlement_fabric_knowledge.gd").entries():
   if entry.id!=method:continue
   known.append_array(entry.requires_all)
   for group:Array in entry.requires_any:known.append(group[0])
  assert(not F.start(plot,method,stock,[method],{method:1.0},1).ok)
  var incompatible:Dictionary=plot.duplicate(true)
  incompatible.land_use="field"
  assert(not F.start(incompatible,method,stock,known,{method:1.0},1).ok)
  assert(stock[item]==1.0)
  for entry:Dictionary in preload("res://scripts/settlement_fabric_knowledge.gd").entries():
   if entry.id!=method:continue
   for parent:String in entry.requires_all:
    var missing:Array=known.duplicate()
    missing.erase(parent)
    assert(not F.foundations_met(method,missing))
   for group:Array in entry.requires_any:
    var missing:Array=known.duplicate()
    for parent:String in group:missing.erase(parent)
    assert(not F.foundations_met(method,missing))
    for alternative:String in group:
     var alternate:Array=missing.duplicate()
     alternate.append(alternative)
     assert(F.foundations_met(method,alternate))
  assert(F.start(plot,method,stock,known,{method:1.0},1).ok)
  assert(stock[item]==0.0)
  assert(not F.start(plot,method,{item:1.0},[method],{method:1.0},1).ok)
  assert(F.advance(plot,10.0,1)==0.0)
  assert(F.advance(plot,.5,2)==.5)
  var restored:Dictionary=JSON.parse_string(JSON.stringify(plot))
  assert(F.valid_job(restored.fabric_job))
  assert(F.advance(restored,100,3)==float(F.WORK[method])-.5)
  assert(restored.fabric_job.state=="awaiting_inspection")
  assert(restored.form=="inherited_house")
  assert(F.advance(restored,100,4)==0.0)
  assert(not F.start_trial(restored,{},4).ok)
  var trial_stock:Dictionary=F.trial_cost(method)
  assert(F.start_trial(restored,trial_stock,4).ok)
  for amount:Variant in trial_stock.values():assert(float(amount)==0)
  assert(F.needs_work(restored))
  assert(F.advance(restored,1.0,4)==0)
  assert(F.advance(restored,.25,5)==.25)
  restored=JSON.parse_string(JSON.stringify(restored))
  assert(F.valid_job(restored.fabric_job))
  assert(F.advance(restored,4.0,6)==.75)
  assert(restored.fabric_job.state=="awaiting_observations")
  assert(not F.needs_work(restored))
  assert(restored.form=="inherited_house")
  assert(not F.start_trial(restored,F.trial_cost(method),7).ok)
  var ready:Dictionary=JSON.parse_string(JSON.stringify(restored))
  var resolved:Dictionary=F.resolve(ready,7)
  assert(resolved.state=="accepted")
  assert(ready.fabric_components.has(method))
  assert(F.valid_plot_records(ready))
  assert(F.affordable_repair(ready,.2,{})==0.0)
  var repair_stock:Dictionary={item:.025}
  assert(is_equal_approx(F.affordable_repair(ready,.2,repair_stock),.1))
  F.pay_repair(ready,.1,repair_stock)
  assert(is_zero_approx(float(repair_stock[item])))
  if method in ["roof_flashing_interfaces","rainscreen_wall_assemblies"]:
   ready.condition=1.0
   var protected:float=F.rain_transfer(ready)
   ready.condition=.1
   assert(F.rain_transfer(ready)>protected)
   assert(protected>=.8)
   ready.condition=1.0
  var kit=preload("res://scripts/settlement_architecture_kit.gd")
  ready.fabric_generation=12
  ready.storeys=1
  var legacy:Dictionary=ready.duplicate(true)
  legacy.erase("fabric_components")
  assert(kit.installed_features(legacy)==0)
  if method in ["timber_post_beam_connections","timber_splice_connections"]:
   assert(kit.kind(ready).begins_with("timber_"))
   assert(kit.kind(legacy).begins_with("modern_"))
  if method=="building_shading_design":
   var base_bounds:=AABB(Vector3(-2,0,-3),Vector3(4,3,6))
   var overlay:ArrayMesh=kit.detail_mesh(base_bounds,kit.installed_features(ready))
   assert(overlay.get_aabb().end.z>base_bounds.end.z)
   assert(overlay==kit.detail_mesh(base_bounds,kit.installed_features(ready)))
  var mesh:ArrayMesh=kit.mesh_for_plot(ready)
  assert(mesh==kit.mesh_for_plot(ready))
  if method=="building_shading_design":
   assert(mesh!=kit.mesh_for_plot(legacy))
   assert(mesh.get_aabb().end.z>kit.mesh_for_plot(legacy).get_aabb().end.z)
  assert(F.resolve(ready,8).is_empty())
  var moved:Dictionary=ready.duplicate(true)
  moved.id=999
  assert(not F.valid_plot_records(moved))
  var forged:Dictionary=restored.duplicate(true)
  forged.fabric_job.trial.result.state="rejected"
  assert(F.resolve(forged,7).is_empty())
  var weak:Dictionary=restored.duplicate(true)
  weak.fabric_job.assembly.support_condition=.1
  var response:Dictionary=preload("res://scripts/settlement_fabric_response.gd").observe(weak.fabric_job.assembly)
  weak.fabric_job.trial.result=preload("res://scripts/settlement_fabric_inspection.gd").classify(method,response)
  assert(F.resolve(weak,7).state!="accepted")
  assert(weak.get("fabric_components",{}).is_empty())
  assert(F.valid_plot_records(weak))
  if method in ["timber_post_beam_connections","timber_splice_connections","timber_lateral_bracing","timber_moisture_movement_design","building_wind_load_assessment"]:
   assert(not F.supports_further_loading(weak))
   ready.condition=1.0
   assert(F.supports_further_loading(ready))
   ready.condition=.1
   assert(not F.supports_further_loading(ready))
  restored.fabric_job.paid=0
  assert(not F.valid_job(restored.fabric_job))
 print("PASS: ten methods; payment, duplicate start, work, same-day guard, serialization, inspection hold, inherited form and malformed job")
 quit()
