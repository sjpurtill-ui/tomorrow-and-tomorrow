extends RefCounted
## Preparation provenance, not a measurement or synthesis certificate. Records
## live in the existing per-civilization technology ledger and save owner.
const Industry=preload("res://scripts/civilian_industry.gd")
const LIMIT=256
const MAX_SERIAL=1000000000
static func data()->Dictionary:
	var ledger:Dictionary=WorldSimulation.state.technology_operations
	if not ledger.has("polymer_samples"):ledger.polymer_samples={"next_serial":1,"records":{}}
	return ledger.polymer_samples
static func has_capacity()->bool:
	return data().records.size()<LIMIT and int(data().next_serial)<MAX_SERIAL
static func retire_completed()->void:
	var ledger:=data()
	if ledger.records.size()<LIMIT:return
	# Keep recent reports and all unfinished work. Released physical specimens
	# remain in stock; removing an old record neither refunds nor releases them.
	var ids:Array=ledger.records.keys()
	ids.sort_custom(func(a:String,b:String)->bool:return int(a)<int(b))
	for id:String in ids:
		if ledger.records.size()<=LIMIT/2:break
		if ledger.records[id].status not in ["measured_unqualified","measurement_failed"]:continue
		ledger.records.erase(id)
		ledger["retired_count"]=int(ledger.get("retired_count",0))+1
static func completed(item:String,quantity:int)->void:
	var spec:=Industry.product(item)
	if quantity<=0 or not spec.has("specimen_source"):return
	assert(has_capacity())
	var ledger:=data();var serial:=int(ledger.next_serial)
	ledger.next_serial=serial+1
	ledger.records[str(serial)]={"sample_id":str(serial),"recipe":item,"quantity":quantity,"prepared_day":floori(WorldSimulation.state.elapsed_days),"source_store":WorldSimulation.state.resource_settlement_id,"source_material":spec.specimen_source,"status":"unmeasured"}
	if item=="sealed_copolymer_specimens":ledger.records[str(serial)]["response_model"]={"kind":"synthetic_copolymer_v1","seed":serial}
	if item=="traceable_pp_batch":ledger.records[str(serial)]["response_model"]={"kind":"synthetic_pp_triads_v1","seed":serial,"structure_basis":"retained_coordination_synthesis"}
	if item=="sec_traceable_peg_batch":ledger.records[str(serial)]["response_model"]={"kind":"synthetic_peg_distribution_v1","seed":serial,"structure_basis":"retained_controlled_synthesis"}
	if item=="traceable_peg_batch":ledger.records[str(serial)]["response_model"]={"kind":"synthetic_linear_peg_v1","seed":serial,"structure_basis":"retained_controlled_synthesis"}
static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["next_serial","records"]):return false
	if not integer(value.next_serial,1,MAX_SERIAL) or not value.records is Dictionary or value.records.size()>LIMIT:return false
	if not integer(value.get("retired_count",0),0,int(value.next_serial)-1) or int(value.get("retired_count",0))+value.records.size()>=int(value.next_serial):return false
	for key:Variant in value.records:
		if not key is String or not key.is_valid_int() or str(int(key))!=key:return false
		var serial:=int(key)
		if serial<1 or serial>=int(value.next_serial):return false
		var record:Variant=value.records[key]
		if not record is Dictionary or not record.has_all(["sample_id","recipe","quantity","prepared_day","source_store","source_material","status"]):return false
		if record.sample_id!=key or not record.recipe is String or not record.source_store is String or record.source_store.length()>128:return false
		var spec:=Industry.product(record.recipe)
		if not spec.has("specimen_source") or record.source_material!=spec.specimen_source:return false
		if record.has("response_model"):
			if not record.response_model is Dictionary or not integer(record.response_model.get("seed"),1,MAX_SERIAL):return false
			if record.recipe=="sealed_copolymer_specimens":
				if record.response_model.get("kind")!="synthetic_copolymer_v1":return false
			elif record.recipe=="sec_traceable_peg_batch":
				if record.response_model.get("kind")!="synthetic_peg_distribution_v1" or record.response_model.get("structure_basis")!="retained_controlled_synthesis":return false
			elif record.recipe=="traceable_peg_batch":
				if record.response_model.get("kind")!="synthetic_linear_peg_v1" or record.response_model.get("structure_basis")!="retained_controlled_synthesis":return false
			elif record.recipe=="traceable_pp_batch":
				if record.response_model.get("kind")!="synthetic_pp_triads_v1" or record.response_model.get("structure_basis")!="retained_coordination_synthesis":return false
			else:return false
		if not integer(record.quantity,1,1000000000) or not integer(record.prepared_day,0,1000000000):return false
		if record.recipe=="sec_traceable_peg_batch":
			if not record.has("response_model") or not preload("res://scripts/sec_acquisition.gd").valid(record):return false
		elif not preload("res://scripts/nmr_acquisition.gd").valid(record):return false
	return true
static func integer(value:Variant,low:int,high:int)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floorf(float(value)) and float(value)>=low and float(value)<=high
