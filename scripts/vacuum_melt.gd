extends RefCounted
## Selected copper charge in a pumped chamber; normalized gas/thermal response.
const CHARGE:=1.05
const GAS:=.001
static func evidence(work:float,leak:float,pauses:Array=[])->Dictionary:
	var p:=101.0;var temperature:=20.0;var dissolved:=GAS;var headspace:=0.0
	var pumped:=0.0;var vapor:=0.0;var molten_work:=0.0;var elapsed:=0.0;var trace:Array=[]
	var remaining:=minf(work,6.0)
	var pause_index:=0
	while remaining>.000001 or pause_index<pauses.size():
		if pause_index<pauses.size() and float(pauses[pause_index].work)<=elapsed+.000001:
			var days:=float(pauses[pause_index].days)
			temperature=20.0+(temperature-20.0)*exp(-2.0*days)
			p=101.0-(101.0-p)*exp(-leak*days)
			pause_index+=1
			continue
		if remaining<=.000001:break
		var used:=minf(.05,remaining)
		if pause_index<pauses.size():used=minf(used,float(pauses[pause_index].work)-elapsed)
		var heated:=elapsed+.000001>=1 and elapsed+.000001<4
		var supplied:=minf(800,maxf(0,(1200-temperature)/used)) if heated else 0.0
		temperature=maxf(20,temperature+(supplied-(temperature-20)*(.02 if heated else 2.0))*used)
		p=maxf(0,p+(leak*(101-p)-4.0*p)*used)
		if temperature>=1085:
			molten_work+=used
			var equilibrium:=GAS*sqrt(clampf(p/101.0,0,1))
			var released:=maxf(0,dissolved-equilibrium)*(1-exp(-5*used))
			dissolved-=released;headspace+=released
			vapor+=.00005*(1-clampf(p/101.0,0,1))*used
		var exhausted:=headspace*(1-exp(-4*used))
		headspace-=exhausted;pumped+=exhausted
		elapsed+=used;remaining-=used
		if elapsed+.000001>=float(trace.size()+1)*.5:trace.append({"work":elapsed,"pressure":p,"temperature":temperature,"dissolved_gas":dissolved,"headspace_gas":headspace,"exhausted_gas":pumped})
	return {"work":minf(work,6.0),"temperature":temperature,"pressure":p,"dissolved_gas":dissolved,"headspace_gas":headspace,"exhausted_gas":pumped,
		"vapor_loss":vapor,"metal_mass":CHARGE-GAS-vapor,"molten_work":molten_work,"trace":trace}
static func witness(e:Dictionary)->Dictionary:
	var pixels:Array=[];var voids:=mini(400,int(round(float(e.dissolved_gas)*1000000.0)))
	for index:int in range(400):pixels.append(0.0 if index<voids else 1.0)
	return {"method":"weighed_charge_and_polished_section","section_pixels":pixels,"cast_mass":snappedf(float(e.metal_mass)+float(e.dissolved_gas)-.03,.0001),
		"temperature":snappedf(float(e.temperature),1.0),"molten_observed":float(e.molten_work)>=.5,"resolution":.0001}
static func inspect(observed:Dictionary)->Dictionary:
	var voids:=0
	for value:float in observed.section_pixels:
		if value<.5:voids+=1
	var porosity:=float(voids)/400.0
	return {"qualified":porosity+.0025<=.15 and float(observed.cast_mass)>=1.0 and float(observed.temperature)<=150 and bool(observed.molten_observed),
		"section_void_fraction":porosity,"scope":"selected copper charge; no general chemical purity claim"}
