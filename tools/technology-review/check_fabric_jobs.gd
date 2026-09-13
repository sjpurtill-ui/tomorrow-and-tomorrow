extends SceneTree
const F=preload("res://scripts/settlement_fabric_operations.gd")
func _initialize()->void:
 for method:String in F.COMPONENTS:
  var plot:Dictionary={"id":1,"status":"active","form":"inherited_house"}
  var item:String=F.COMPONENTS[method]
  var stock:Dictionary={item:1.0}
  assert(not F.start(plot,method,stock,[],{},1).ok)
  assert(stock[item]==1.0)
  assert(F.start(plot,method,stock,[method],{method:1.0},1).ok)
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
