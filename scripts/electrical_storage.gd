extends RefCounted
## Finite stationary storage. Charge input and discharge output use service-energy units.
static func retain(ledger:Dictionary,plants:Dictionary,days:int)->void:
	for id:String in ledger.plants:
		var storage:Dictionary=plants[id].get("storage",{})
		if storage.is_empty():continue
		var record:Dictionary=ledger.plants[id]
		record["charge_input"]=0.0;record["discharge_output"]=0.0
		record["stored_energy"]=maxf(0,float(record.get("stored_energy",0)))*pow(1.0-float(storage.self_discharge),maxi(1,days))
static func discharge(ledger:Dictionary,plants:Dictionary,available:float,condition:float,demand:float,operators:Callable)->float:
	for id:String in plants:
		var spec:Dictionary=plants[id];var storage:Dictionary=spec.get("storage",{})
		var record:Dictionary=ledger.plants.get(id,{})
		if storage.is_empty() or record.is_empty() or not record.enabled or int(record.installed)<=0:continue
		var need:=maxf(0,demand-float(ledger.services.get("electricity",0)))
		var units:=minf(float(record.installed),available/float(spec.workers))*condition
		var output:=minf(need,minf(units*float(storage.discharge_rate),float(record.get("stored_energy",0))*float(storage.discharge_efficiency)))
		var per_power:=float(spec.workers)/condition/float(storage.discharge_rate)
		var generated:=float(ledger.services.get("electricity",0))
		if output*per_power+float(operators.call(generated+output))>available:
			var low:=0.0;var high:=output
			for step in 32:
				var middle:=(low+high)*.5
				if middle*per_power+float(operators.call(generated+middle))<=available:low=middle
				else:high=middle
			output=low
		if output<=.00000001:continue
		units=output/float(storage.discharge_rate)
		var staff:=units/condition*float(spec.workers)
		available-=staff;ledger.workers+=staff
		record.running_units=units;record.discharge_output=output
		record.stored_energy=maxf(0,float(record.stored_energy)-output/float(storage.discharge_efficiency))
		ledger.services.electricity=float(ledger.services.get("electricity",0))+output
	return available
static func charge(ledger:Dictionary,plants:Dictionary,available:float,condition:float,workshop_reserve:float,generate:Callable)->float:
	# Prevent any bank from charging from another bank's same-day discharge.
	for record:Dictionary in ledger.plants.values():
		if float(record.get("discharge_output",0))>0:return available
	for id:String in plants:
		var spec:Dictionary=plants[id];var storage:Dictionary=spec.get("storage",{})
		var record:Dictionary=ledger.plants.get(id,{})
		if storage.is_empty() or record.is_empty() or not record.enabled or int(record.installed)<=0:continue
		var units:=minf(float(record.installed),available/float(spec.workers))*condition
		var room:=maxf(0,int(record.installed)*float(storage.capacity)-float(record.get("stored_energy",0)))
		var input:=minf(units*float(storage.charge_rate),room/float(storage.charge_efficiency))
		if input<=0:continue
		var reserved:=input/float(storage.charge_rate)/condition*float(spec.workers)
		available-=reserved
		available=float(generate.call(workshop_reserve+input,available))
		input=minf(input,maxf(0,float(ledger.services.get("electricity",0))-workshop_reserve))
		var staff:=input/float(storage.charge_rate)/condition*float(spec.workers)
		available+=reserved-staff;ledger.workers+=staff
		record.running_units=input/float(storage.charge_rate);record.charge_input=input
		record.stored_energy=float(record.get("stored_energy",0))+input*float(storage.charge_efficiency)
		ledger.services.electricity=maxf(0,float(ledger.services.get("electricity",0))-input)
	return available
static func forecast_available(ledger:Dictionary,plants:Dictionary,days_ahead:int)->bool:
	for id:String in ledger.plants:
		var storage:Dictionary=plants[id].get("storage",{})
		var record:Dictionary=ledger.plants[id]
		var output:=float(record.get("discharge_output",0))
		if storage.is_empty() or output<=0:continue
		if not record.enabled:return false
		# Fixed current contribution with no promise of future charging.
		var retention:=pow(1.0-float(storage.self_discharge),maxi(0,days_ahead))
		if float(record.get("stored_energy",0))*retention+.00000001<output/float(storage.discharge_efficiency)*maxi(0,days_ahead):return false
	return true
static func valid(record:Dictionary,spec:Dictionary)->bool:
	var storage:Dictionary=spec.get("storage",{})
	for field:String in ["stored_energy","charge_input","discharge_output"]:
		var value:Variant=record.get(field,0)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value)<0:return false
		var limit:=float(storage.get({"stored_energy":"capacity","charge_input":"charge_rate","discharge_output":"discharge_rate"}[field],0))*float(record.installed)
		if float(value)>limit+.000001:return false
	return true
