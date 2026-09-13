extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var W=root.get_node("WorldSimulation")
 var G=root.get_node("GameState")
 var C=root.get_node("CivilizationSystem")
 var M=root.get_node("MilitaryCampaign")
 var S=root.get_node("SaveSystem")
 var F=load("res://scripts/settlement_fabric_operations.gd")
 G.reset_for_new_world(1341);C.reset_for_new_world()
 G.set_process(false);C.set_process(false);M.set_process(false)
 W.create_actor("fabric_save",1341)
 var slot:String="fabric_worker_%d" % OS.get_process_id()
 W.scoped("fabric_save",func()->void:
  var state=W.state
  state.settlement_completed.assign(["Hearth Circle"])
  state.settlement_site_committed=true;state.convoy_traveling=false;state.elapsed_days=30
  W.settlements.ensure_founded()
  var plot:Dictionary=state.settlement_plots[0]
  plot.status="active";plot.condition=1.0;plot.land_use="residential_compound";plot.material_family="timber"
  var method:String="building_shading_design"
  state.known_discoveries.append_array([method,"seasonal_patterns","geometric_survey"])
  state.discovery_adoption[method]=1.0
  state.resource_stockpiles["Building Shade Lattices"]=1.0
  assert(W.settlements.start_fabric_retrofit(int(plot.id),method).ok)
  assert(F.advance(plot,.5,31)==.5)
  state.elapsed_days=31
 )
 var saved:Dictionary=S.save_game(slot)
 if not saved.get("ok",false):push_error(str(saved));quit(1);return
 W.clear()
 var loaded:Dictionary=S.load_game(slot)
 DirAccess.remove_absolute(S.slot_path(slot))
 if not loaded.get("ok",false):push_error(str(loaded));quit(1);return
 W.scoped("fabric_save",func()->void:
  var state=W.state
  var plot:Dictionary=state.settlement_plots[0]
  assert(float(plot.fabric_job.work)==.5)
  assert(float(state.resource_stockpiles["Building Shade Lattices"])==0.0)
  assert(F.advance(plot,1,31)==0.0)
  assert(F.advance(plot,10,32)==1.5)
  state.resource_stockpiles["Timber"]=1.0;state.resource_stockpiles["Fiber Plants"]=1.0
  assert(F.start_trial(plot,state.resource_stockpiles,32).ok)
  assert(F.advance(plot,1,33)==1.0)
  assert(F.resolve(plot,33).state=="accepted")
  assert(F.valid_plot_records(plot))
  state.elapsed_days=33
 )
 var installed_save:Dictionary=S.save_game(slot)
 if not installed_save.get("ok",false):push_error(str(installed_save));quit(1);return
 W.clear()
 var installed_load:Dictionary=S.load_game(slot)
 DirAccess.remove_absolute(S.slot_path(slot))
 if not installed_load.get("ok",false):push_error(str(installed_load));quit(1);return
 W.scoped("fabric_save",func()->void:
  var plot:Dictionary=W.state.settlement_plots[0]
  assert(plot.fabric_components.has("building_shading_design"))
  assert(F.valid_plot_records(plot))
  assert(F.resolve(plot,40).is_empty())
  assert(load("res://scripts/settlement_architecture_kit.gd").installed_features(plot)&64)
 )
 W.clear()
 print("PASS: whole game save reload retains paid partial retrofit and resumes to installed acceptance")
 quit()
