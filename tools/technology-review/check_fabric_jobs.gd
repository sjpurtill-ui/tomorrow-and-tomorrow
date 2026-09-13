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
  restored.fabric_job.paid=0
  assert(not F.valid_job(restored.fabric_job))
 print("PASS: ten methods; payment, duplicate start, work, same-day guard, serialization, inspection hold, inherited form and malformed job")
 quit()
