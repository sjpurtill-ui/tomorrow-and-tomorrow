extends RefCounted
## Aggregate primary-settlement installations. Government still assigns roles;
## operators reserve capacity within Crafting rather than creating workers.
const LIMIT:=1000
const WaterDrive=preload("res://scripts/water_hammer_site.gd")
const Storage=preload("res://scripts/electrical_storage.gd")
const PLANTS={
	"sec_analytical_bench":{"name": "Aqueous size-exclusion bench", "gate": "size_exclusion_chromatography", "requires": ["electrical_measurement"], "cost": {"SEC Bench Assemblies": 1, "Steel": 2}, "work": 16, "workers": 1, "inputs": {"Freshwater": 1}, "power": 2, "services": {"sec_column_time": 1}},
	"nmr_analytical_bench":{"name": "NMR analytical bench awaiting reference qualification", "gate": "nuclear_magnetic_resonance_spectroscopy", "requires": ["electrical_measurement"], "cost": {"Unqualified NMR Benches": 1, "Steel": 2}, "work": 24, "workers": 1, "inputs": {"Freshwater": 1, "Insulated Cable": 0.001}, "power": 8, "services": {"nmr_unqualified_time": 1}},
	"foam_insulated_cold_store":{"name": "Foam-insulated electric cold store", "gate": "polymer_foam_cell_control", "requires": ["mechanical_refrigeration", "electric_motors"], "cost": {"Foam Cold-Store Panels": 2, "Electric Motors": 1, "Pressure Vessels": 1, "Glass": 1}, "work": 16, "workers": 1, "inputs": {"Bitumen": 0.01, "Foam Cold-Store Panels": 0.002}, "power": 2.2, "services": {"cold_storage": 200}},
	"polymer_stirred_reactor":{"name": "Stirred polymer reactor", "gate": "pressure_vessels", "requires": ["precision_thermometry"], "cost": {"Polymer Stirred Reactors": 1, "Steel": 2}, "work": 18, "workers": 1, "inputs": {"Brazed Steel Fittings": 0.005}, "power": 2, "services": {"polymer_stirred_work": 1}},
	"polymer_passive_cooling":{"name": "Low-throughput polymer cooling bath", "gate": "calorimetry", "requires": ["pressure_vessels"], "cost": {"Pressure Vessels": 1, "Refined Copper": 2, "Steel": 2}, "work": 12, "workers": 0.5, "inputs": {"Freshwater": 2}, "power": 0, "services": {"polymer_heat_removal": 0.2}},
	"polymer_pressure_reactor":{"name": "High-pressure polymer reactor", "gate": "radical_chain_polymerization", "requires": ["pressure_vessels", "precision_thermometry"], "cost": {"Polymer Pressure Reactors": 1, "Steel": 4}, "work": 30, "workers": 2, "inputs": {"Brazed Steel Fittings": 0.01}, "power": 4, "services": {"polymer_reactor_work": 1}},
	"polymer_cooling_circuit":{"name": "Polymer heat-removal circuit", "gate": "polymer_reaction_heat_management", "requires": ["electric_motors"], "cost": {"Polymer Cooling Circuits": 1, "Steel": 2}, "work": 15, "workers": 0.5, "inputs": {"Freshwater": 4, "Pressure Pipe Fittings": 0.005}, "power": 2, "services": {"polymer_heat_removal": 2}},
	"water_hammer":{"name":"River-driven forge hammer","gate":"water_powered_hammers","requires":[],"cost":{"Water Hammer Drives":1.0,"Stone":8.0},"work":24.0,"workers":1.0,"inputs":{"Rope Coils":0.005},"power":0.0,"services":{"hammer_work":4.0}},
	"belt_workshop":{"name":"Belt-driven workshop","gate":"belt_power_transmission","requires":["electric_motors"],"cost":{"Belt Drive Sets":1.0,"Electric Motors":1.0,"Timber":4.0},"work":12.0,"workers":1.0,"inputs":{"Drive Belts":0.01},"power":2.0,"services":{"mechanical_work":3.5}},
	"geared_workshop":{"name": "Geared indexing workshop", "gate": "shaft_alignment_methods", "requires": ["electric_motors"], "cost": {"Basic Machine Tool Sets": 1, "Aligned Drive Assemblies": 1, "Generated Gear Sets": 1, "Electric Motors": 1, "Insulated Cable": 2}, "work": 18.0, "workers": 1.5, "inputs": {"Rolling Bearings": 0.01, "Drive Chains": 0.01}, "power": 3.0, "services": {"mechanical_work": 5.0}},
	"research_radio_station":{"name": "Research radio station", "gate": "radio_telegraphy", "requires": ["agreed_signal_codes"], "cost": {"Radio Telegraph Sets": 1, "Timber": 2}, "work": 14.0, "workers": 1.0, "inputs": {"Paper": 0.05}, "power": 2.0, "services": {"radio_records": 1.0}},
	"optical_signal_bench":{"analysis_family": "optical", "name": "Optical signaling bench", "gate": "optical_telegraphy", "requires": ["experimental_controls"], "cost": {"Optical Telegraph Sets": 1, "Timber": 2}, "work": 10.0, "workers": 0.5, "inputs": {"Paper": 0.02}, "power": 0.0, "services": {"analysis_optical": 1.0}},
	"electrical_signal_bench":{"analysis_family": "electrical", "name": "Electrical communications bench", "gate": "electrical_telegraphy", "requires": ["electrical_measurement", "telephone_circuits"], "cost": {"Electrical Telegraph Sets": 1, "Telephone Sets": 1, "Timber": 2}, "work": 14.0, "workers": 1.0, "inputs": {"Paper": 0.02}, "power": 1.0, "services": {"analysis_electrical": 3.0}},
	"radio_signal_bench":{"analysis_family": "radio", "name": "Radio communications bench", "gate": "superheterodyne_reception", "requires": ["amplitude_modulation", "frequency_modulation", "radio_telegraphy"], "cost": {"Superheterodyne Receivers": 1, "AM Exciters": 1, "FM Signal Sets": 1, "Radio Telegraph Sets": 1}, "work": 18.0, "workers": 1.0, "inputs": {"Paper": 0.02}, "power": 3.0, "services": {"analysis_radio": 5.0}},
	"digital_signal_bench":{"analysis_family": "digital", "name": "Digital communications bench", "gate": "store_forward_archives", "requires": ["error_detection_codes", "automatic_telegraphy", "manual_switchboards", "duplex_telegraphy", "inductive_line_loading"], "cost": {"Message Archive Units": 1, "Automatic Telegraph Sets": 1, "Telephone Switchboards": 1, "Duplex Telegraph Sets": 1, "Loading Coils": 1}, "work": 20.0, "workers": 1.5, "inputs": {"Message Tape": 0.02}, "power": 4.0, "services": {"analysis_digital": 8.0}},

	"cannery":{"name":"Thermal food cannery","gate":"thermal_process_validation","requires":["food_retorts","double_seaming"],"cost":{"Food Retorts":1.0,"Seaming Heads":1.0,"Wrought Iron":2.0},"work":16.0,"workers":2.0,"inputs":{"Food Can Sets":0.2,"Coal":0.2,"Freshwater":0.5},"power":0.0,"services":{"food_preservation":10.0}},
	"microscopy_bench":{"name":"Microscopy bench","gate":"compound_microscopy","requires":["specimen_slide_mounting"],"cost":{"Compound Microscopes":1.0,"Timber":2.0},"work":10.0,"workers":0.5,"inputs":{"Specimen Slides":0.1},"power":0.0,"services":{"specimen_observation":2.0}},
	"pneumatic_workshop":{"name":"Pneumatic pressing workshop","gate":"pneumatic_pressing","requires":["compressed_air_systems"],"cost":{"Pneumatic Presses":1.0,"Pressure Pipe Fittings":1.0},"work":12.0,"workers":1.0,"inputs":{"Compressed Air":0.5},"power":0.0,"services":{"mechanical_work":3.0}},
	"solar_array":{"name":"Photovoltaic array","gate":"photovoltaic_power","requires":["cable_insulation"],"cost":{"Photovoltaic Modules":1.0,"Insulated Cable":2.0,"Steel":1.0},"work":12.0,"workers":.2,"inputs":{},"power":0.0,"services":{"electricity":4.0}},
	"steam_generator":{"name":"Steam-electric works","gate":"electrical_generators","requires":["steam_propulsion"],"cost":{"Electrical Generators":1.0,"Pressure Vessels":1.0,"Wrought Iron":5.0},"work":20.0,"workers":2.0,"inputs":{"Coal":.5,"Freshwater":1.0},"power":0.0,"services":{"electricity":10.0}},
	"cold_store":{"name":"Electric cold store","gate":"mechanical_refrigeration","requires":["electric_motors"],"cost":{"Electric Motors":1.0,"Pressure Vessels":1.0,"Glass":1.0},"work":12.0,"workers":1.0,"inputs":{"Bitumen":.01},"power":3.0,"services":{"cold_storage":200.0}},
	"powered_workshop":{"name":"Motor-driven workshop","gate":"electric_motors","requires":["electrical_generators"],"cost":{"Basic Machine Tool Sets":1.0,"Electric Motors":1.0,"Insulated Cable":2.0,"Wrought Iron":2.0},"work":10.0,"workers":1.0,"inputs":{},"power":2.0,"services":{"mechanical_work":3.0}},
	"controlled_workshop":{"name":"Electronically controlled workshop","gate":"electronic_machine_control","requires":["electric_motors"],"cost":{"Precision Machine Tool Sets":1.0,"Electronic Controllers":1.0,"Electric Motors":1.0,"Insulated Cable":2.0,"Steel":2.0},"work":15.0,"workers":1.5,"inputs":{},"power":2.5,"services":{"mechanical_work":4.5}},
	"sequenced_workshop":{"name":"Hardwired sequencing workshop","gate":"hardwired_sequence_control","requires":["electric_motors"],"cost":{"Precision Machine Tool Sets":1.0,"Sequence Controllers":1.0,"Electric Motors":1.0,"Insulated Cable":2.0,"Steel":3.0},"work":18.0,"workers":1.5,"inputs":{},"power":3.0,"services":{"mechanical_work":5.0}},
	"programmable_workshop":{"name": "Programmable machine workshop", "gate": "stored_program_control", "requires": ["electric_motors"], "cost": {"Precision Machine Tool Sets":1.0,"Programmable Controllers": 1.0, "Electric Motors": 1.0, "Insulated Cable": 2.0, "Steel": 3.0}, "work": 20.0, "workers": 1.5, "inputs": {}, "power": 4.0, "services": {"mechanical_work": 6.0}},
	"battery_store":{"name": "Supervised battery store", "gate": "battery_bank_wiring", "requires": ["cable_insulation"], "cost": {"Battery Banks": 1.0, "Insulated Cable": 1.0}, "work": 12.0, "workers": 1.0, "inputs": {}, "power": 0.0, "services": {}, "storage": {"capacity": 12.0, "charge_rate": 3.0, "discharge_rate": 3.0, "charge_efficiency": 0.8, "discharge_efficiency": 0.8, "self_discharge": 0.001}},
	"regulated_battery_store":{"name": "Regulated battery store", "gate": "charge_regulation", "requires": ["battery_bank_wiring"], "cost": {"Battery Banks": 1.0, "Charge Controllers": 1.0, "Insulated Cable": 1.0}, "work": 16.0, "workers": 0.25, "inputs": {}, "power": 0.0, "services": {}, "storage": {"capacity": 12.0, "charge_rate": 6.0, "discharge_rate": 6.0, "charge_efficiency": 0.9, "discharge_efficiency": 0.9, "self_discharge": 0.0005}}
}
static func empty_state()->Dictionary:return {"last_day":-1,"plants":{},"services":{},"workers":0.0,"inputs":{}}
static func data()->Dictionary:return WorldSimulation.state.technology_operations
static func quote(id:String,count:int=1)->Dictionary:
	if not PLANTS.has(id) or count<1 or count>100:return {"error":"Choose an installation and between 1 and 100 units."}
	var state:=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {"error":"Install machinery at the primary settled home."}
	var spec:Dictionary=PLANTS[id]
	for gate:String in [spec.gate]+spec.requires:
		if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:return {"error":"Establish "+String(WorldSimulation.discovery.discovery_definition(gate).get("name",gate))+" before commissioning this plant."}
	var record:Dictionary=data().plants.get(id,{})
	if int(record.get("installed",0))+int(record.get("building",0))+count>LIMIT:return {"error":"Installation capacity is full."}
	if id=="water_hammer" and record.is_empty() and WaterDrive.select(WorldSimulation.discovery.latest_context).is_empty():return {"error":"Choose a settled home within 0.75 km of a revealed river or tributary."}
	var cost:Dictionary={};var parts:Array[String]=[]
	for item:String in spec.cost:
		cost[item]=float(spec.cost[item])*count
		parts.append("%.1f %s" % [cost[item],item])
		if float(state.resource_stockpiles.get(item,0))<float(cost[item]):return {"error":"Needs %.1f %s in stores." % [cost[item],item]}
	return {"ok":true,"cost":cost,"message":"Install %d %s: %s. Commissioning needs %.1f worker-days; operators share the assigned Crafting workforce." % [count,spec.name,", ".join(parts),float(spec.work)*count]}
static func install(id:String,count:int=1)->Dictionary:
	var offer:=quote(id,count)
	if offer.has("error"):return offer
	for item:String in offer.cost:WorldSimulation.state.resource_stockpiles[item]=float(WorldSimulation.state.resource_stockpiles[item])-float(offer.cost[item])
	if not data().plants.has(id):data().plants[id]={"installed":0,"building":0,"work":0.0,"enabled":true}
	if id=="water_hammer" and not data().plants[id].has("river_site"):data().plants[id]["river_site"]=WaterDrive.select(WorldSimulation.discovery.latest_context)
	data().plants[id].building+=count
	return offer
static func set_enabled(id:String,value:bool)->void:
	if data().plants.has(id):data().plants[id].enabled=value
static func reserved_workers(state:Node)->float:
	if not state.resource_settlement_id.is_empty():return 0.0
	var ledger:Dictionary=state.technology_operations
	return float(ledger.workers) if int(ledger.last_day)==int(state.elapsed_days) else 0.0
static func service(name:String)->float:
	if not WorldSimulation.state.resource_settlement_id.is_empty() or int(data().last_day)!=int(WorldSimulation.state.elapsed_days):return 0.0
	return maxf(0,float(data().services.get(name,0)))
static func workshop_power_demand()->float:
	var demand:=0.0
	var host:=WorldSimulation.military
	if host.production_labor_share<=0:return 0.0
	for job:Dictionary in host.equipment_queue:
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):continue
		var recipe:Dictionary=preload("res://scripts/civilian_industry.gd").product(String(job.get("item","")))
		if float(recipe.get("power",0))<=0:continue
		if (recipe.gate not in WorldSimulation.state.known_discoveries or WorldSimulation.discovery.adoption(String(recipe.gate))<.10) and not preload("res://scripts/research_licenses.gd").active(String(recipe.gate)):continue
		if int(job.get("target_stock",0))>0 and float(WorldSimulation.state.resource_stockpiles.get(recipe.output,0))>=int(job.target_stock):continue
		# Reserved machine feed is already inside this local unfinished workpiece.
		# Free-stock exhaustion must not cancel the next day's generation request.
		if recipe.get("alloy_phase_trial",false) and job.has("alloy_trial"):
			if job.alloy_trial.site==WorldSimulation.state.resource_settlement_id:demand+=float(recipe.daily_power)
			continue
		if recipe.has("thermal_program") and job.has("metallurgy_pending"):
			if job.metallurgy_pending.site==WorldSimulation.state.resource_settlement_id:demand+=float(recipe.daily_power)
			continue
		if recipe.has("machine_program") and job.has("machine_pending"):
			if job.machine_pending.site==WorldSimulation.state.resource_settlement_id:demand+=float(recipe.daily_power)
			continue
		var supplied:=true
		for item:String in recipe.materials:
			if float(recipe.materials[item])>0 and float(WorldSimulation.state.resource_stockpiles.get(item,0))<=.000000001:supplied=false
		if supplied:demand+=float(recipe.daily_power)
	return demand
static func auxiliary_power_demand()->float:
	return float(load("res://scripts/grain_processing.gd").power_demand())+float(load("res://scripts/household_clothing.gd").power_demand())
static func consume_service(name:String,amount:float)->float:
	if not is_finite(amount):return 0.0
	var used:=minf(maxf(0,amount),service(name))
	if used>0:data().services[name]=float(data().services[name])-used
	return used
static func consume_electricity(amount:float)->float:
	var used:=minf(maxf(0,amount),service("electricity"))
	if used>0:data().services.electricity-=used
	return used
static func advance(day:int,current_context:Variant=null)->void:
	if not WorldSimulation.state.resource_settlement_id.is_empty():return
	# The ordered daily owner supplies today's observations before discovery refresh.
	var operating_context:Dictionary=current_context if current_context is Dictionary else WorldSimulation.discovery.latest_context
	var ledger:=data()
	if day<=int(ledger.last_day):return
	var elapsed:=maxi(1,day-int(ledger.last_day)) if int(ledger.last_day)>=0 else 1
	ledger.last_day=day;ledger.services={};ledger.inputs={};ledger.workers=0.0
	Storage.retain(ledger,PLANTS,elapsed)
	for record:Dictionary in ledger.plants.values():record["running_units"]=0.0
	var state:=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return
	var available:float=state.effective_workers("Crafting")
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1.0)
	if condition<=0 or available<=0:return
	var workshop_demand:float=workshop_power_demand()+auxiliary_power_demand()
	var demand:=workshop_demand
	for id:String in PLANTS:
		var record:Dictionary=ledger.plants.get(id,{})
		if record.is_empty() or not record.enabled or float(PLANTS[id].power)<=0:continue
		var spec:Dictionary=PLANTS[id]
		var units:=float(record.installed)*condition
		for item:String in spec.inputs:units=minf(units,maxf(0,float(state.resource_stockpiles.get(item,0)))/float(spec.inputs[item]))
		demand+=units*float(spec.power)
	# Serve current demand first; storage covers a generation shortfall.
	available=_generate(ledger,available,condition,demand)
	var discharge_workshop_workers:=maxf(0,available-_consumer_staff(float(ledger.services.get("electricity",0)),condition))*clampf(WorldSimulation.military.production_labor_share,0,1) if workshop_demand>0 else 0.0
	available=discharge_workshop_workers+Storage.discharge(ledger,PLANTS,available-discharge_workshop_workers,condition,demand,func(power:float)->float:return _consumer_staff(power,condition))
	for id:String in PLANTS:
		var record:Dictionary=ledger.plants.get(id,{})
		if record.is_empty() or not record.enabled or int(record.installed)<=0:continue
		var spec:Dictionary=PLANTS[id]
		if float(spec.services.get("electricity",0))>0 or spec.has("storage"):continue
		var units:=minf(float(record.installed),available/float(spec.workers))*condition
		if float(spec.power)>0:units=minf(units,float(ledger.services.get("electricity",0))/float(spec.power))
		for item:String in spec.inputs:units=minf(units,maxf(0,float(state.resource_stockpiles.get(item,0)))/float(spec.inputs[item]))
		if id=="cannery":units=minf(units,canning_demand()/float(spec.services.food_preservation))
		if id=="water_hammer":units=minf(units,float(WaterDrive.assessment(record.get("river_site",{}),operating_context,day).capacity))
		if units>0:available=_operate(ledger,record,spec,units,available,condition)
	# Charging can use spare generation, after consumer operators and the
	# electricity budget for pending workshop production have been protected.
	var protected_workers:=available*clampf(WorldSimulation.military.production_labor_share,0,1) if workshop_demand>0 else 0.0
	available=protected_workers+Storage.charge(ledger,PLANTS,available-protected_workers,condition,workshop_demand,func(target:float,workers:float)->float:return _generate(ledger,workers,condition,target))
	# Existing services take priority over expansion; spent machinery stays
	# in the installation record through suspension and saving.
	for id:String in PLANTS:
		var record:Dictionary=ledger.plants.get(id,{})
		if record.is_empty() or not record.enabled or int(record.building)<=0:continue
		var spec:Dictionary=PLANTS[id]
		var required:=float(record.building)*float(spec.work)-float(record.work)
		var staff:=minf(available,minf(2.0*int(record.building),required/condition))
		record.work+=staff*condition;available-=staff;ledger.workers+=staff
		var completed:=mini(int(record.building),floori((float(record.work)+.00000001)/float(spec.work)))
		record.installed+=completed;record.building-=completed;record.work=maxf(0,float(record.work)-completed*float(spec.work))
	preload("res://scripts/nmr_acquisition.gd").advance_pending()
	preload("res://scripts/sec_acquisition.gd").advance_pending()
static func _consumer_staff(power:float,condition:float)->float:
	var staff:=0.0
	for id:String in PLANTS:
		var spec:Dictionary=PLANTS[id];var record:Dictionary=data().plants.get(id,{})
		if record.is_empty() or not record.enabled or float(spec.power)<=0:continue
		var units:=minf(float(record.installed)*condition,power/float(spec.power))
		for item:String in spec.inputs:units=minf(units,maxf(0,float(WorldSimulation.state.resource_stockpiles.get(item,0)))/float(spec.inputs[item]))
		staff+=units/condition*float(spec.workers)
		power=maxf(0,power-units*float(spec.power))
	return staff
static func _generate(ledger:Dictionary,available:float,condition:float,target:float)->float:
	for id:String in PLANTS:
		var spec:Dictionary=PLANTS[id]
		var output:=float(spec.services.get("electricity",0))
		var record:Dictionary=ledger.plants.get(id,{})
		if output<=0 or record.is_empty() or not record.enabled or int(record.installed)<=0:continue
		var remaining:=maxf(0,float(record.installed)*condition-float(record.get("running_units",0)))
		var units:=minf(remaining,available/float(spec.workers)*condition)
		units=minf(units,maxf(0,target-float(ledger.services.get("electricity",0)))/output)
		for item:String in spec.inputs:units=minf(units,maxf(0,float(WorldSimulation.state.resource_stockpiles.get(item,0)))/float(spec.inputs[item]))
		if units>0:available=_operate(ledger,record,spec,units,available,condition)
	return available
static func _operate(ledger:Dictionary,record:Dictionary,spec:Dictionary,units:float,available:float,condition:float)->float:
	record["running_units"]=float(record.get("running_units",0))+units
	var staff:=units/condition*float(spec.workers)
	available-=staff;ledger.workers+=staff
	for item:String in spec.inputs:
		var amount:=units*float(spec.inputs[item])
		WorldSimulation.state.resource_stockpiles[item]=maxf(0,float(WorldSimulation.state.resource_stockpiles.get(item,0))-amount)
		ledger.inputs[item]=float(ledger.inputs.get(item,0))+amount
	if float(spec.power)>0:ledger.services.electricity=maxf(0,float(ledger.services.get("electricity",0))-units*float(spec.power))
	for name:String in spec.services:ledger.services[name]=float(ledger.services.get(name,0))+units*float(spec.services[name])
	return available
static func canning_demand()->float:
	return preload("res://scripts/canning_capacity.gd").available_input(WorldSimulation.state.food_stocks,float(WorldSimulation.food._calculate_demand(false).total))
static func status(id:String)->String:
	var record:Dictionary=data().plants.get(id,{})
	if record.is_empty():return "Not installed"
	if WorldSimulation.state.convoy_traveling:return "Inactive while traveling"
	if not record.enabled:return "Pause scheduled; today's service is already delivered" if float(record.get("running_units",0))>0 else "Paused"
	if int(data().last_day)!=int(WorldSimulation.state.elapsed_days):return "Awaiting daily review"
	if PLANTS[id].has("storage") and int(record.installed)>0:return "Stored %.2f / %.1f energy units; today charged %.2f and supplied %.2f." % [float(record.get("stored_energy",0)),float(PLANTS[id].storage.capacity)*int(record.installed),float(record.get("charge_input",0)),float(record.get("discharge_output",0))]
	if float(record.get("running_units",0))>0:return "Operating %.2f of %d installed units" % [float(record.running_units),int(record.installed)]
	if int(record.installed)<=0:return "Commissioning: %.1f work completed toward the next unit" % float(record.work)
	var spec:Dictionary=PLANTS[id]
	if id=="water_hammer":
		var site_status:=WaterDrive.assessment(record.get("river_site",{}),WorldSimulation.discovery.latest_context,int(WorldSimulation.state.elapsed_days))
		if float(site_status.capacity)<=0:return String(site_status.reason)
	if id=="cannery" and canning_demand()<=0:return "Waiting for surplus perishable food"
	for item:String in spec.inputs:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0))<=0:return "Waiting for "+item
	if float(spec.power)>0:return "Waiting for power or available Crafting operators"
	if id=="cannery":return "Waiting for available Crafting operators"
	return "Waiting for powered demand or available Crafting operators"
static func forecast_service(name:String,days_ahead:int)->float:
	if not Storage.forecast_available(data(),PLANTS,days_ahead):return 0.0
	# Conservative fixed-stock forecast: future extraction and deliveries are
	# not promised. Real daily operation recalculates after actual resupply.
	for item:String in data().inputs:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0))+.00000001<float(data().inputs[item])*days_ahead:return 0.0
	return service(name)
static func refrigeration_multiplier(capacity:float,stocks:Dictionary)->float:
	var perishables:=0.0
	for food:String in ["Fresh plants","Fresh meat","Fish"]:perishables+=maxf(0,float(stocks.get(food,0)))
	if perishables<=0:return 1.0
	return 1.0-.8*clampf(capacity/perishables,0,1)
static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["last_day","plants","services","workers","inputs"]):return false
	if value.has("sec_column") and not preload("res://scripts/sec_acquisition.gd").valid_column(value.sec_column):return false
	if value.has("nmr_calibration") and not preload("res://scripts/nmr_calibration.gd").valid(value.nmr_calibration):return false
	if value.has("abrasive_lots") and not preload("res://scripts/abrasive_inspection.gd").valid(value.abrasive_lots):return false
	if value.has("polymer_samples") and not preload("res://scripts/polymer_samples.gd").valid(value.polymer_samples):return false
	if not value.plants is Dictionary or value.plants.size()>PLANTS.size():return false
	for field:String in ["last_day","workers"]:
		if not number(value[field]) or value[field]<(-1 if field=="last_day" else 0):return false
	if float(value.last_day)!=floorf(float(value.last_day)) or float(value.workers)>PLANTS.size()*2.0*LIMIT:return false
	for field:String in ["services","inputs"]:
		if not value[field] is Dictionary or value[field].size()>(17 if field=="services" else 16):return false
		for key:Variant in value[field]:
			if field=="services" and key not in ["electricity","cold_storage","hammer_work","mechanical_work","specimen_observation","food_preservation","signal_analysis","analysis_optical","analysis_electrical","analysis_radio","analysis_digital","radio_records","polymer_reactor_work","polymer_heat_removal","polymer_stirred_work","nmr_unqualified_time","sec_column_time"]:return false
			if field=="inputs" and key not in ["Coal","Freshwater","Bitumen","Compressed Air","Specimen Slides","Food Can Sets","Paper","Message Tape","Rolling Bearings","Drive Chains","Drive Belts","Rope Coils","Brazed Steel Fittings","Pressure Pipe Fittings","Foam Cold-Store Panels","Insulated Cable"]:return false
			if not key is String or not number(value[field][key]) or value[field][key]<0:return false
	for name:String in {"electricity":23000.0,"cold_storage":400000.0,"hammer_work":8.0,"mechanical_work":30000.0,"specimen_observation":2000.0,"food_preservation":10000.0,"signal_analysis":17000.0,"analysis_optical":1000.0,"analysis_electrical":3000.0,"analysis_radio":5000.0,"analysis_digital":8000.0,"radio_records":1000.0,"polymer_reactor_work":1000.0,"polymer_heat_removal":2200.0,"polymer_stirred_work":1000.0,"nmr_unqualified_time":1000.0,"sec_column_time":1000.0}:
		if float(value.services.get(name,0))>float({"electricity":23000.0,"cold_storage":400000.0,"hammer_work":8.0,"mechanical_work":30000.0,"specimen_observation":2000.0,"food_preservation":10000.0,"signal_analysis":17000.0,"analysis_optical":1000.0,"analysis_electrical":3000.0,"analysis_radio":5000.0,"analysis_digital":8000.0,"radio_records":1000.0,"polymer_reactor_work":1000.0,"polymer_heat_removal":2200.0,"polymer_stirred_work":1000.0,"nmr_unqualified_time":1000.0,"sec_column_time":1000.0}[name])+.000001:return false
	for id:Variant in value.plants:
		if not PLANTS.has(id):return false
		var record:Variant=value.plants[id]
		if not record is Dictionary or not record.has_all(["installed","building","work","enabled"]) or not record.enabled is bool:return false
		for field:String in ["installed","building","work"]:
			if not number(record[field]) or record[field]<0:return false
		if not number(record.get("running_units",0)) or float(record.get("running_units",0))<0 or float(record.get("running_units",0))>float(record.installed)+.000001:return false
		if not Storage.valid(record,PLANTS[id]):return false
		if id=="water_hammer" and not WaterDrive.valid(record.get("river_site")):return false
		if record.installed!=floorf(record.installed) or record.building!=floorf(record.building) or record.installed+record.building>LIMIT or record.work>=float(PLANTS[id].work):return false
	return true
static func number(value:Variant)->bool:return (value is float or value is int) and is_finite(float(value))
