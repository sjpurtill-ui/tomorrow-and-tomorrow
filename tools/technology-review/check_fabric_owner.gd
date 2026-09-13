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
  state.resource_stockpiles["Timber"]=10.0
  state.resource_stockpiles["Fiber Plants"]=2.0
  var recommendation:Dictionary=load("res://scripts/building_material_investment.gd").fabric_recommendation()
  assert(recommendation.get("item","")=="building_shade_lattices")
  assert(float(state.resource_stockpiles.get("Building Shade Lattices",0))==0)
  assert(WorldSimulation.military.start_production_line(String(recommendation.item),1).get("ok",false))
  var job:Dictionary=WorldSimulation.military.equipment_queue.back()
  load("res://scripts/persistent_production.gd").advance(WorldSimulation.military,job,3.0)
  assert(float(state.resource_stockpiles.get("Building Shade Lattices",0))==1.0)
  assert(float(state.resource_stockpiles["Timber"])<10.0)
  WorldSimulation.military.cancel_equipment_job(int(job.id))
  var plot:Dictionary=state.settlement_plots[0]
  plot.status="active"
  # Let the real monthly owner select a supplied job without a direct start call.
  state.elapsed_days=30
  model.process_month()
  var found:=false
  for candidate:Dictionary in state.settlement_plots:
   if candidate.get("fabric_job",{}).is_empty():continue
   plot=candidate;found=true;break
  assert(found)
  assert(state.resource_stockpiles["Building Shade Lattices"]==0.0)
  assert(B.valid_plot(plot))
  state.elapsed_days=60
  model.process_month()
  assert(float(plot.fabric_job.work)>0)
  var work:float=float(plot.fabric_job.work)
  model.process_month()
  assert(float(plot.fabric_job.work)==work)
  var saved:Dictionary=JSON.parse_string(JSON.stringify(plot))
  assert(B.valid_plot(saved))
  saved.fabric_job.required_work=0
  assert(not B.valid_plot(saved))
  state.resource_stockpiles["Timber"]=1.0
  state.resource_stockpiles["Fiber Plants"]=1.0
  for day in range(90,361,30):
   state.elapsed_days=day
   model.process_month()
   if plot.get("fabric_components",{}).has(method):break
  assert(plot.get("fabric_components",{}).has(method))
  assert(float(state.resource_stockpiles["Fiber Plants"])<1.0)
  assert(B.valid_plot(plot))
 )
 WorldSimulation.clear()
 print("PASS: autonomous settlement start, paid assembly/trial, installed result, duplicate-month guard and plot validation")
 quit()
