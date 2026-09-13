extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var W=root.get_node("WorldSimulation")
 var K=load("res://scripts/settlement_fabric_knowledge.gd")
 var I=load("res://scripts/civilian_industry.gd")
 var P=load("res://scripts/persistent_production.gd")
 W.clear();W.create_actor("fabric_production",1401)
 var completed:Array[bool]=[false]
 W.scoped("fabric_production",func()->void:
  var catalog:Array=W.discovery.technology_catalog.duplicate(true)
  catalog.append_array(K.entries())
  var errors:Array=load("res://scripts/technology_catalog_contract.gd").validate(K.entries(),catalog)
  if not errors.is_empty():push_error(str(errors))
  assert(errors.is_empty())
  for entry:Dictionary in K.entries():
   W.state.resource_stockpiles={}
   W.state.known_discoveries.assign([entry.id])
   W.state.discovery_adoption={entry.id:1.0}
   var item:String=entry.production_items[0]
   var spec:Dictionary=I.product(item)
   assert(not W.military.start_production_line(item,1).get("ok",false))
   for input:String in spec.materials:W.state.resource_stockpiles[input]=float(spec.materials[input])
   for input:String in spec.tooling:W.state.resource_stockpiles[input]=float(W.state.resource_stockpiles.get(input,0))+float(spec.tooling[input])
   var before:Dictionary=W.state.resource_stockpiles.duplicate()
   assert(W.military.start_production_line(item,1).get("ok",false))
   for input:String in spec.tooling:
    assert(is_equal_approx(float(before[input])-float(W.state.resource_stockpiles[input]),float(spec.tooling[input])))
   var job:Dictionary=W.military.equipment_queue.back()
   P.advance(W.military,job,float(spec.days)*.5)
   assert(float(W.state.resource_stockpiles.get(spec.output,0))==0)
   P.advance(W.military,job,float(spec.days)*.5)
   assert(float(W.state.resource_stockpiles.get(spec.output,0))==1.0)
   assert(int(job.completed)==1)
   W.military.cancel_equipment_job(int(job.id))
  completed[0]=true
 )
 W.clear()
 if not completed[0]:
  printerr("FAIL: component production scenario stopped early");quit(1);return
 print("PASS: ten candidate catalog contracts and finite component production with missing-input/partial-work checks")
 quit()
