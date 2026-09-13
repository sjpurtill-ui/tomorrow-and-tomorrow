extends RefCounted
## Bounded synthetic aqueous-PEG column response. Numerical coefficients are
## game assumptions, not commercial instrument performance or empirical data.
const POINTS=601
const STEP=.02
static func number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))
static func profile()->Dictionary:
	return {"flow":1.0,"width":.07,"noise":.0001,"gain":1.0,"recovery":1.0}
static func scan(chains:Array,instrument:Dictionary,seed_value:int,sample_id:String,epoch:int)->Dictionary:
	if chains.is_empty() or chains.size()>32 or sample_id.is_empty() or epoch<0:return {"error":"Missing retained sample or column epoch."}
	for key:String in ["flow","width","noise","gain","recovery"]:
		if not number(instrument.get(key)):return {"error":"Invalid column condition."}
	if float(instrument.flow)<=0 or float(instrument.width)<=0 or float(instrument.noise)<=0 or float(instrument.gain)<=0 or float(instrument.recovery)<0 or float(instrument.recovery)>1:return {"error":"Invalid column condition."}
	var mass:=0.0;var count:=0.0
	for component:Variant in chains:
		if not component is Dictionary or not number(component.get("dp")) or not number(component.get("number_fraction")):return {"error":"Invalid retained-chain model."}
		if float(component.dp)<2 or float(component.dp)>1000 or float(component.number_fraction)<=0:return {"error":"Retained-chain model is outside the bounded simulation."}
		mass+=float(component.number_fraction)*(44.0*float(component.dp)+18.0)
		count+=float(component.number_fraction)
	if absf(count-1.0)>.000001:return {"error":"Retained-chain number fractions must sum to one."}
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var trace:Array[float]=[]
	for index:int in POINTS:
		var volume:=index*STEP;var intensity:=0.0
		for component:Dictionary in chains:
			var center:=(10.0-1.5*log(float(component.dp)))/float(instrument.flow)
			var fraction:=float(component.number_fraction)*(44.0*float(component.dp)+18.0)/mass
			var width:=float(instrument.width)
			intensity+=fraction*float(instrument.recovery)*float(instrument.gain)*exp(-.5*pow((volume-center)/width,2))/(sqrt(TAU)*width)
		trace.append(intensity+rng.randfn(0.0,float(instrument.noise)))
	# No latent chain sizes or fractions cross the measurement boundary.
	return {"sample_id":sample_id,"epoch":epoch,"trace":trace,"step":STEP,"origin":0.0,"measured_flow":instrument.flow,"noise_estimate":instrument.noise,"injected_mass":1.0,"method":"aqueous_peg_relative_sec_v1"}
