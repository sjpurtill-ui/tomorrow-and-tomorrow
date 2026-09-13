extends RefCounted
## Forward instrument model. Coordinates and amplitudes are game assay units,
## not empirical polymer chemical-shift assignments. Only sampled response is
## returned; interpretation must not inspect the latent resonance list.
const POINTS=401
const STEP=0.1
const MAX_SCANS=1000000
static func number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))
static func acquire(resonances:Array,instrument:Dictionary,scans:int,seed_value:int)->Dictionary:
	if scans<1 or scans>MAX_SCANS:return {"error":"Acquisition needs a bounded positive scan count."}
	if resonances.is_empty() or resonances.size()>32:return {"error":"Sample response is unavailable."}
	for key:String in ["linewidth","noise","gain","shift_error","temperature_drift"]:
		if not number(instrument.get(key)):return {"error":"Instrument response is unavailable."}
	if float(instrument.linewidth)<=0 or float(instrument.linewidth)>10 or float(instrument.noise)<=0 or float(instrument.noise)>1000 or float(instrument.gain)<=0 or float(instrument.gain)>100:return {"error":"Instrument response is outside the modeled range."}
	if absf(float(instrument.shift_error))>5 or absf(float(instrument.temperature_drift))>10:return {"error":"Instrument drift is outside the modeled range."}
	for resonance:Variant in resonances:
		if not resonance is Dictionary:return {"error":"Invalid sample response."}
		for key:String in ["position","amplitude","intrinsic_width"]:
			if not number(resonance.get(key)):return {"error":"Invalid sample response."}
		if float(resonance.position)<0 or float(resonance.position)>40 or float(resonance.amplitude)<=0 or float(resonance.amplitude)>1000 or float(resonance.intrinsic_width)<=0 or float(resonance.intrinsic_width)>10:return {"error":"Sample response is outside the modeled range."}
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var noise:=float(instrument.noise)/sqrt(float(scans))
	var trace:Array[float]=[]
	for index:int in POINTS:
		var position:=index*STEP
		var response_value:=0.0
		for resonance:Dictionary in resonances:
			var center:=float(resonance.position)+float(instrument.shift_error)
			var width:=float(resonance.intrinsic_width)+float(instrument.linewidth)+absf(float(instrument.temperature_drift))*.1
			var distance:=(position-center)/width
			response_value+=float(resonance.amplitude)*float(instrument.gain)/(PI*width*(1.0+distance*distance))
		# Seeded Gaussian receiver noise is reproducible through saved acquisitions.
		trace.append(response_value+rng.randfn(0.0,noise))
	return {"trace":trace,"step":STEP,"origin":0.0,"scans":scans,"noise_estimate":noise,"coordinate_units":"game assay units"}
