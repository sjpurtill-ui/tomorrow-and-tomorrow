extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var WorldSimulation=root.get_node("WorldSimulation")
 var B=load("res://scripts/building_material_operations.gd")
 WorldSimulation.clear()
 WorldSimulation.create_actor("fabric_owner",1301)
 WorldSimulation.scoped("fabric_owner",func()->void:
  var state=WorldSimulation.state
  var model=WorldSimulation.settlements
  state.ensure_population_total(80)
  state.settlement_completed.assign(["Hearth Circle"])
  state.settlement_site_committed=true
  state.convoy_traveling=false
  state.elapsed_days=19
  model.ensure_founded()
  state.population_allocations.Construction=8
  state.population_health=1.0
  state.simulation_metrics.labor_efficiency=1.0
  var method:String="building_shading_design"
  state.known_discoveries.append(method)
  state.known_discoveries.append_array(["seasonal_patterns","geometric_survey"])
  state.discovery_adoption[method]=1.0
  state.resource_stockpiles["Building Shade Lattices"]=1.0
  var plot:Dictionary=state.settlement_plots[0]
  plot.status="active"
  assert(model.start_fabric_retrofit(int(plot.id),method).ok)
  assert(state.resource_stockpiles["Building Shade Lattices"]==0.0)
  assert(B.valid_plot(plot))
  state.elapsed_days=30
  model.process_month()
  assert(float(plot.fabric_job.work)>0)
  var work:float=float(plot.fabric_job.work)
  model.process_month()
  assert(float(plot.fabric_job.work)==work)
  var saved:Dictionary=JSON.parse_string(JSON.stringify(plot))
  assert(B.valid_plot(saved))
  saved.fabric_job.required_work=0
  assert(not B.valid_plot(saved))
 )
 WorldSimulation.clear()
 print("PASS: actual settlement retrofit start, payment, monthly work, duplicate-month guard and plot validation")
 quit()
