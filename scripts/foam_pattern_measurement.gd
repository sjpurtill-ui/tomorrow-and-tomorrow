extends RefCounted
## Selected small EPS pattern, in normalized batch mass and cavity volume units.
## Mold wear affects measured form; this is not a general polymer kinetics model.
static func evidence(work:float,wear:float,pauses:Array=[])->Dictionary:
	var temperature:=20.0;var expanded:=0.0;var elapsed:=0.0;var pause_index:=0
	var remaining:=minf(work,4.0)
	while remaining>.000001 or pause_index<pauses.size():
		if pause_index<pauses.size() and float(pauses[pause_index].work)<=elapsed+.000001:
			temperature=20.0+(temperature-20.0)*exp(-2.0*float(pauses[pause_index].days))
			pause_index+=1;continue
		if remaining<=.000001:break
		var used:=minf(.05,remaining)
		if pause_index<pauses.size():used=minf(used,float(pauses[pause_index].work)-elapsed)
		var heated:=elapsed<2.0-.000001
		temperature=20.0+(temperature-20.0)*exp(-(.1 if heated else 2.0)*used)
		if heated:temperature=minf(110,temperature+100*used)
		if heated and temperature>=90:expanded=minf(1.0,expanded+used)
		elapsed+=used;remaining-=used
	return {"temperature":temperature,"expansion":expanded,"volume":maxf(.01,expanded*(1.0+wear*.1)),"form_error":wear*.1,"dry_mass":.032}
static func witness(e:Dictionary)->Dictionary:
	return {"dry_mass":snappedf(float(e.dry_mass),.0001),"volume":snappedf(float(e.volume),.01),
		"form_error":snappedf(float(e.form_error),.01),"temperature":snappedf(float(e.temperature),1)}
static func inspect(observed:Dictionary)->Dictionary:
	var density:=float(observed.dry_mass)/maxf(.01,float(observed.volume))
	return {"qualified":density>=.025 and density<=.04 and absf(float(observed.volume)-1.0)+.01<=.05 and float(observed.form_error)+.01<=.05 and float(observed.temperature)<=40,
		"density":density,"scope":"selected pattern mass, volume and form; chemical residue unqualified"}
