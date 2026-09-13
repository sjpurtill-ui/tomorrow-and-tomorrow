extends SceneTree
const R=preload("res://scripts/settlement_fabric_response.gd")
const I=preload("res://scripts/settlement_fabric_inspection.gd")
func _initialize()->void:
 for method:String in R.DETAILS:
  var sound:Dictionary=R.prepare(method,1.0)
  var degraded:Dictionary=R.prepare(method,.1)
  assert(R.valid(sound,method))
  assert(I.classify(method,R.observe(sound)).state=="accepted")
  assert(I.classify(method,R.observe(degraded)).state!="accepted")
  var saved:Dictionary=JSON.parse_string(JSON.stringify(degraded))
  assert(R.observe(saved)==R.observe(degraded))
  saved.support_condition=NAN
  assert(R.observe(saved).is_empty())
  assert(not R.valid(sound,"absent"))
 print("PASS: ten retained physical details respond differently on sound/degraded supports; serialized response stable")
 quit()
