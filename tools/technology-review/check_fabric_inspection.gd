extends SceneTree
const I=preload("res://scripts/settlement_fabric_inspection.gd")
func _initialize()->void:
 for method:String in I.TRIALS:
  var t:Dictionary=I.TRIALS[method]
  var observed:Dictionary={t.stimulus:1.0,t.response:float(t.maximum)*.5,"uncertainty":float(t.maximum)*.1}
  assert(I.classify(method,observed).state=="accepted")
  observed[t.response]=float(t.maximum)*2
  assert(I.classify(method,observed).state=="rejected")
  observed[t.response]=float(t.maximum)
  assert(I.classify(method,observed).state=="inconclusive")
  observed[t.stimulus]=0.0
  assert(I.classify(method,observed).reason=="insufficient_trial")
  observed[t.stimulus]=100.0
  assert(I.classify(method,observed).reason=="outside_trial_envelope")
  observed[t.stimulus]=NAN
  assert(I.classify(method,observed).reason=="invalid_measurement")
  assert(I.classify(method,{}).state=="inconclusive")
 print("PASS: ten distinct trial envelopes; acceptance, rejection, uncertainty, insufficient and invalid observations")
 quit()
