extends RefCounted
## Per-building paid fabric. This module owns no population, clock or stock ledger.
const METHODS=["concrete_curing_control","concrete_compaction_practice","masonry_moisture_management","masonry_bond_patterns","mortar_compatibility_assessment","masonry_repointing","shallow_foundation_assessment","foundation_settlement_monitoring","masonry_buttressing","vaulted_masonry_roofs","domed_masonry_roofs"]
const PROFILES={
	"arched_masonry":{"name": "Arched masonry fabric", "gate": "voussoir_arch_assembly", "family": "stone", "form": "arched_masonry_household", "cost": {"Stone": 2, "Voussoir Stones": 2, "Arch Centering": 0.2, "Building Mortar": 1}, "work": 1.8, "curing_days": 30, "curing_water": 0.5, "decay": 0.65, "repair": "Building Mortar"},
	"buttressed_masonry":{"name": "Buttressed masonry fabric", "gate": "masonry_buttressing", "family": "stone", "form": "buttressed_masonry_household", "cost": {"Stone": 6, "Building Mortar": 1.5, "Timber": 0.8}, "work": 1.7, "curing_days": 30, "curing_water": 0.7, "decay": 0.6, "repair": "Building Mortar"},
	"vaulted_masonry":{"name": "Vaulted masonry roof", "gate": "vaulted_masonry_roofs", "family": "stone", "form": "vaulted_masonry_household", "cost": {"Stone": 3, "Voussoir Stones": 3, "Arch Centering": 0.5, "Building Mortar": 2}, "work": 2.5, "curing_days": 30, "curing_water": 1.0, "decay": 0.45, "repair": "Building Mortar"},
	"domed_masonry":{"name": "Domed masonry roof", "gate": "domed_masonry_roofs", "family": "stone", "form": "domed_masonry_household", "cost": {"Stone": 5, "Voussoir Stones": 3, "Arch Centering": 0.5, "Building Mortar": 2}, "work": 2.8, "curing_days": 30, "curing_water": 1.0, "decay": 0.4, "repair": "Building Mortar"},
	"rammed_earth":{"name":"Rammed earth household","gate":"rammed_earth_construction","family":"earth","form":"rammed_earth_household","cost":{"Clay":4.0,"Fiber Plants":.8,"Ramming Frames":.15},"work":1.2,"curing_days":0,"curing_water":0.0,"decay":.85,"repair":"Clay"},
	"lime_masonry":{"name":"Lime-bonded masonry","gate":"lime_mortar","family":"stone","form":"lime_masonry_household","cost":{"Stone":4.0,"Building Mortar":1.0,"Timber":.8},"work":1.3,"curing_days":30,"curing_water":.5,"decay":.75,"repair":"Building Mortar"},
	"thatched_frame":{"name":"Bound thatch and timber frame","gate":"thatched_roofing","family":"organic","form":"thatched_frame_household","cost":{"Timber":3.0,"Thatch Panels":1.0},"work":.9,"curing_days":0,"curing_water":0.0,"decay":.95,"repair":"Thatch Panels"},
	"tiled_masonry":{"name":"Tile-roofed masonry","gate":"fired_roof_tiles","family":"stone","form":"tiled_masonry_household","cost":{"Stone":3.0,"Building Mortar":1.0,"Roof Tiles":1.0,"Timber":1.0},"work":1.5,"curing_days":30,"curing_water":.5,"decay":.60,"repair":"Building Mortar"},
	"trussed_roof":{"name":"Trussed timber roof","gate":"timber_roof_trusses","family":"organic","form":"trussed_roof_household","cost":{"Timber Trusses":1.0,"Thatch Panels":1.0,"Clay":3.0},"work":1.3,"curing_days":0,"curing_water":0.0,"decay":.70,"repair":"Thatch Panels"},
	"cast_concrete":{"name":"Cast concrete fabric","gate":"concrete_mix_design","family":"stone","form":"cast_concrete_household","cost":{"Concrete Dry Mix":2.0,"Building Formwork":.3,"Timber":1.0},"work":1.8,"curing_days":60,"curing_water":2.0,"decay":.50,"repair":"Concrete Dry Mix"}
}
static func adopted(id:String)->bool:
	return id in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption(id)>=.25
static func options(land_use:String="residential_compound")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id:String in PROFILES:
		var spec:Dictionary=PROFILES[id]
		if not adopted(spec.gate):continue
		if id=="cast_concrete" and not adopted("concrete_formwork_systems"):continue
		if id=="tiled_masonry" and not adopted("lime_mortar"):continue
		if id=="trussed_roof" and not adopted("thatched_roofing"):continue
		var profile:={"id":id,"work":float(spec.work),"curing_days":int(spec.curing_days),"curing_water":float(spec.curing_water),"decay":float(spec.decay),"applied":[String(spec.gate)]}
		var cost:Dictionary=spec.cost.duplicate()
		if id=="cast_concrete":
			if adopted("concrete_curing_control"):
				profile.curing_days=30;profile.applied.append("concrete_curing_control")
			if adopted("concrete_compaction_practice") and float(WorldSimulation.state.resource_stockpiles.get("Ramming Frames",0))>=.1:
				cost["Ramming Frames"]=.1;profile.decay*=.9;profile.applied.append("concrete_compaction_practice")
		if spec.family=="stone" and adopted("masonry_moisture_management") and float(WorldSimulation.state.resource_stockpiles.get("Masonry Drainage Beds",0))>=.5:
			cost["Masonry Drainage Beds"]=.5;profile.decay*=.9;profile.applied.append("masonry_moisture_management")
		if spec.repair=="Building Mortar" and adopted("masonry_bond_patterns"):
			cost["Building Mortar"]=float(cost.get("Building Mortar",0))+.1
			profile.work+=.1;profile.decay*=.9;profile.applied.append("masonry_bond_patterns")
		if adopted("shallow_foundation_assessment") and float(WorldSimulation.state.resource_stockpiles.get("Foundation Survey Kits",0))>=.1:
			cost["Foundation Survey Kits"]=.1;profile.work+=.1;profile.decay*=.95;profile.applied.append("shallow_foundation_assessment")
		if adopted("foundation_settlement_monitoring") and float(WorldSimulation.state.resource_stockpiles.get("Settlement Gauges",0))>=.1:
			cost["Settlement Gauges"]=.1;profile.applied.append("foundation_settlement_monitoring")
		var scale:=float({"civic":2.0,"market":1.5,"workshop":1.5,"dirty_industry":2.0,"storage":1.2,"hospitality":1.4}.get(land_use,1.0))
		for material:String in cost:cost[material]=float(cost[material])*scale
		profile.work*=scale;profile.curing_water*=scale
		result.append({"family":spec.family,"form":spec.form,"requires":spec.gate,"cost":cost,"building_materials":profile,"service_life":1.0/float(profile.decay)})
	return result
static func progress(plot:Dictionary,work:float,day:int)->float:
	var profile:Dictionary=plot.get("building_materials",{})
	var previous:=float(plot.get("construction_progress",0))
	if profile.is_empty():return clampf(previous+work,0,1)
	var amount:=clampf(previous+work/float(profile.work),0,1)
	if amount<1:return amount
	if int(profile.curing_days)<=0:return 1.0
	if not plot.has("curing_started_day"):
		plot.curing_started_day=day;plot.curing_last_day=day;plot.curing_work_days=0.0
		return .99
	var days:=minf(30.0,minf(float(profile.curing_days)-float(plot.get("curing_work_days",0)),maxf(0,day-int(plot.get("curing_last_day",day)))))
	plot.curing_last_day=day
	if days<=0:return .99
	var water:=float(profile.curing_water)*days/float(profile.curing_days)
	var stock:=float(WorldSimulation.state.resource_stockpiles.get("Freshwater",0))
	if stock<water:return .99
	WorldSimulation.state.resource_stockpiles["Freshwater"]=stock-water
	plot.curing_work_days=float(plot.get("curing_work_days",0))+days
	if float(plot.curing_work_days)<float(profile.curing_days):return .99
	plot.curing_completed_day=day
	return 1.0

static func decay_factor(plot:Dictionary)->float:
	return float(plot.get("building_materials",{}).get("decay",1.0))
static func supplied_maintenance(plot:Dictionary,work:float)->float:
	var profile:Dictionary=plot.get("building_materials",{})
	if profile.is_empty() or work<=0:return work
	var spec:Dictionary=PROFILES[profile.id]
	var material:=String(spec.repair)
	var needed:=work*2.0
	if material=="Building Mortar" and adopted("mortar_compatibility_assessment"):
		needed*=.95
		if adopted("masonry_repointing"):needed*=.8
	if "foundation_settlement_monitoring" in profile.applied:needed*=.95
	var stock:=float(WorldSimulation.state.resource_stockpiles.get(material,0))
	var used:=minf(stock,needed)
	WorldSimulation.state.resource_stockpiles[material]=stock-used
	return work*used/needed
static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	if value.is_empty():return true
	if not PROFILES.has(value.get("id","")):return false
	for key:String in ["work","curing_days","curing_water","decay"]:
		if not value.get(key) is float and not value.get(key) is int:return false
		if not is_finite(float(value[key])):return false
	if float(value.work)<.5 or float(value.work)>8 or float(value.curing_days)<0 or float(value.curing_days)>120:return false
	if float(value.curing_water)<0 or float(value.curing_water)>10 or float(value.decay)<.2 or float(value.decay)>1.5:return false
	if not value.get("applied") is Array or value.applied.size()>16:return false
	for id:Variant in value.applied:
		if not id is String or id.length()>100:return false
	return true
static func valid_plot(plot:Dictionary)->bool:
	var profile:Variant=plot.get("building_materials",{})
	if not valid(profile):return false
	for key:String in ["curing_started_day","curing_last_day","curing_work_days","curing_completed_day"]:
		if not plot.has(key):continue
		if profile.is_empty() or (not plot[key] is int and not plot[key] is float):return false
		if not is_finite(float(plot[key])) or float(plot[key])<0:return false
		if key=="curing_work_days" and float(plot[key])>float(profile.curing_days):return false
		if key!="curing_work_days" and float(plot[key])!=floorf(float(plot[key])):return false
	if int(plot.get("curing_last_day",0))<int(plot.get("curing_started_day",0)):return false
	return true
static func valid_state(state:Dictionary)->bool:
	var groups:Array=[state.get("settlement_plots",[])]
	var settlements:Variant=state.get("player_settlements",[])
	if not settlements is Array:return false
	for city:Variant in settlements:
		if not city is Dictionary or not city.get("local_resources",{}) is Dictionary:return false
		groups.append(city.get("local_resources",{}).get("settlement_plots",[]))
	for plots:Variant in groups:
		if not plots is Array:return false
		for plot:Variant in plots:
			if not plot is Dictionary or not valid_plot(plot):return false
	return true
static func describe(plot:Dictionary)->String:
	var profile:Dictionary=plot.get("building_materials",{})
	if profile.is_empty():return ""
	var spec:Dictionary=PROFILES[profile.id]
	var result:="Building fabric: %s. Maintenance consumes %s.\n" % [spec.name,spec.repair]
	if String(plot.get("status",""))=="under_construction" and plot.has("curing_started_day"):
		result+="Curing: %.0f / %d supplied days. Needs %.2f Freshwater per 30-day interval; shortages pause curing.\n" % [float(plot.get("curing_work_days",0)),int(profile.curing_days),float(profile.curing_water)*30.0/maxf(1,float(profile.curing_days))]
	return result
