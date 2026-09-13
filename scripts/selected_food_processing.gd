extends RefCounted
## Curated compatible opportunity classes in a generated world, not botanical
## species observations. Unknown organisms never enter this processing chain.
const K=preload("res://scripts/food_batch_knowledge.gd")
const R=preload("res://scripts/technology_requirements.gd")
const RAW={"selected_nuts":"nut_kernel_shelling","selected_acorns":"acorn_leaching","selected_roots":"root_grating_dewatering","selected_pulses":"pulse_splitting","selected_fruit":"fruit_pulp_screening"}
const PENDING=["leached_acorn_meal","pressed_root_pulp","split_pulses"]
const KINDS=["selected_nuts","selected_acorns","selected_roots","selected_pulses","selected_fruit","leached_acorn_meal","pressed_root_pulp","split_pulses"]
const YIELDS={"selected_nuts":.72,"selected_acorns":.65,"selected_roots":.8,"selected_pulses":.82,"selected_fruit":.75}
static func batches():return load("res://scripts/food_batches.gd")
static func opportunities(profile:Dictionary,origin:Vector2,seed_value:int)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if not bool(profile.get("land",false)):return result
	var warmth:=float(profile.get("temperature",0));var rain:=float(profile.get("precipitation",0));var woods:=float(profile.get("woodland",0))
	var compatible:={"selected_nuts":woods>.3 and warmth>.25 and warmth<.8,"selected_acorns":woods>.35 and warmth>.3 and warmth<.8,"selected_roots":rain>.25 and warmth>.25,"selected_pulses":rain>.2 and rain<.8 and warmth>.3,"selected_fruit":woods>.15 and warmth>.3 and rain>.3}
	var cell:=Vector2i(floori(origin.x),floori(origin.y))
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value^(cell.x*73856093)^(cell.y*19349663)
	for kind:String in RAW:
		var occurrence:=rng.randf();var abundance:=rng.randf_range(.4,1.0)
		if bool(compatible[kind]) and occurrence>.2:result.append({"kind":kind,"id":"%d:%d:%s"%[cell.x,cell.y,kind],"abundance":abundance,"origin":[origin.x,origin.y]})
	return result
static func harvest(context:Dictionary,food_workers:float,efficiency:float,ecology:float,demand:float,access:float=1.0)->Dictionary:
	var b=batches();var ledger:Dictionary=b.data();var state=WorldSimulation.state
	var report:={"workers":0.0,"gathered":0.0,"sources":{}}
	var day:=int(state.elapsed_days)
	if int(ledger.get("selected_harvest_day",-1))==day:return report
	ledger.selected_harvest_day=day
	if bool(context.get("traveling",state.convoy_traveling)) or not state.settlement_site_committed or food_workers<=0 or access<=0:return report
	if "edible_resource_recognition" not in state.known_discoveries or WorldSimulation.discovery.adoption("edible_resource_recognition")<.1:return report
	var profile:Dictionary=context.get("environment_profile",{})
	var p:Variant=context.get("settlement_origin",context.get("origin"))
	if not p is Vector3 or not is_finite(p.x) or not is_finite(p.z):return report
	var remaining:=food_workers*.08
	var health:=clampf(float(state.food_source_health.get("Wild gathering",.9)),0,1)
	var condition:=clampf(efficiency,0,1)*clampf(ecology,0,1)*health*clampf(access,0,1)
	var season:=clampf(.5+.5*PlanetEnvironment.season_wave(profile,day),.05,1.0)
	var sources:=opportunities(profile,Vector2(p.x,p.z),int(state.world_seed))
	var collector_share:=remaining/maxi(1,sources.size())
	for source:Dictionary in sources:
		var method:String=RAW[source.kind]
		if method not in state.known_discoveries or WorldSimulation.discovery.adoption(method)<.1:continue
		var stored:=0.0;var existing:Dictionary={}
		for lot:Dictionary in ledger.lots:
			if lot.kind==source.kind:
				stored+=float(lot.amount)
				if String(lot.get("source_id",""))==source.id:existing=lot
		var wanted:=maxf(0,demand*.5-stored)
		var rate:=4.0*float(source.abundance)*condition*(1.0 if source.kind=="selected_roots" else season)*clampf(WorldSimulation.discovery.adoption("edible_resource_recognition"),0,1)
		if rate<=.000001:continue
		var local_limit:=40.0*float(source.abundance)*health*(1.0 if source.kind=="selected_roots" else season)
		var amount:=minf(local_limit,minf(wanted,minf(remaining,collector_share)*rate))
		if amount<=.000001:continue
		if existing.is_empty():
			existing=b.add_lot(source.kind,amount,day)
			if existing.is_empty():break
			existing.source_id=source.id;existing.source_origin=source.origin
		else:existing.amount+=amount;existing.origin+=amount
		var work:=amount/rate;remaining-=work;report.workers+=work;report.gathered+=amount;report.sources[source.kind]=amount
		if remaining<=.000001:break
	return report
static func needed(id:String)->bool:
	for lot:Dictionary in batches().data().lots:
		if RAW.get(String(lot.kind),"")==id and valid_lot(lot):return true
	return false
static func process(workers:float,demand:float,report:Dictionary,day:int)->float:
	var b=batches();var state=WorldSimulation.state;var used:=0.0
	# Cook previously prepared lots first. Merely grating, splitting or leaching
	# never releases a ration. The remaining budget also serves the five methods.
	for lot:Dictionary in b.data().lots.duplicate():
		if lot.kind not in PENDING or int(lot.ready)>day or not valid_lot(lot):continue
		if "hearth_roasting_control" not in state.known_discoveries:continue
		var adoption:=clampf(WorldSimulation.discovery.adoption("hearth_roasting_control"),0,1)
		if adoption<=0:continue
		var inputs:={"Timber":.04,"Freshwater":.15,"Stone":.002}
		if lot.kind!="pressed_root_pulp":
			if "clay_shaping" not in state.known_discoveries or WorldSimulation.discovery.adoption("clay_shaping")<.1:continue
			inputs["Clay"]=.003
		var amount:=minf(float(lot.amount),maxf(0,workers-used)*12.0*adoption)
		for resource:String in inputs:amount=minf(amount,maxf(0,float(state.resource_stockpiles.get(resource,0)))/float(inputs[resource]))
		if amount<=.000001:continue
		for resource:String in inputs:
			var spent:=amount*float(inputs[resource]);state.resource_stockpiles[resource]-=spent;report.inputs[resource]=float(report.inputs.get(resource,0))+spent
		b.withdraw(lot,amount);var output:=amount*.95
		state.food_stocks["Fresh plants"]=float(state.food_stocks.get("Fresh plants",0))+output
		var work:=amount/(12.0*adoption);used+=work;report.workers+=work;report.loss+=amount-output
		report.methods["selected_hearth_cooking"]=float(report.methods.get("selected_hearth_cooking",0))+amount
	b.clean_empty()
	# Equipment acquisition obeys the existing food equipment quote and payment.
	if workers-used>.000001 and WorldSimulation.food._stock_total()>maxf(1,demand)*3:
		for id:String in RAW.values():
			if needed(id) and int(b.data().tools.get(id,0))==0 and not b.quote(id).has("error"):b.install(id);break
	for lot:Dictionary in b.data().lots.duplicate():
		if not RAW.has(String(lot.kind)) or used>=workers or not valid_lot(lot):continue
		var id:String=RAW[lot.kind]
		if not R.evaluate(K.METHODS[id],state.known_discoveries).ready:continue
		var amount:float=b.supplied(id,float(lot.amount),maxf(0,workers-used),report)
		if amount<=.000001:continue
		var output:=amount*float(YIELDS[lot.kind]);var next_kind:=""
		match String(lot.kind):
			"selected_acorns":next_kind="leached_acorn_meal"
			"selected_roots":next_kind="pressed_root_pulp"
			"selected_pulses":next_kind="split_pulses"
		var replaces:=amount>=float(lot.amount)-.000001
		if not next_kind.is_empty() and not replaces and b.data().lots.size()>=b.LIMIT:continue
		var origin:float=b.withdraw(lot,amount)
		if replaces:b.data().lots.erase(lot)
		if next_kind.is_empty():
			var category:="Dry staples" if lot.kind=="selected_nuts" else "Fresh plants"
			state.food_stocks[category]=float(state.food_stocks.get(category,0))+output
		else:
			var prepared:Dictionary=b.add_lot(next_kind,output,day,origin)
			prepared.source_id=lot.source_id;prepared.source_origin=lot.source_origin.duplicate()
			prepared.ready=day+(2 if lot.kind=="selected_acorns" else 1)
		report.loss+=amount-output;used+=b.charge(id,amount,report)
	b.clean_empty();return used
static func valid_lot(lot:Dictionary)->bool:
	if lot.kind not in KINDS:return true
	if not lot.get("source_id") is String or String(lot.source_id).is_empty() or String(lot.source_id).length()>256:return false
	var p:Variant=lot.get("source_origin")
	if not p is Array or p.size()!=2:return false
	for n:Variant in p:
		if not (n is int or n is float) or not is_finite(float(n)):return false
	var source_kind:String={"leached_acorn_meal":"selected_acorns","pressed_root_pulp":"selected_roots","split_pulses":"selected_pulses"}.get(String(lot.kind),String(lot.kind))
	return String(lot.source_id)=="%d:%d:%s"%[floori(float(p[0])),floori(float(p[1])),source_kind]
