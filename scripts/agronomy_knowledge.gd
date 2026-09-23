extends RefCounted
## Aggregate cultivation practices, not a crop-genetics or individual-field model.
const GROUPS=["establishment","breeding","cover","tillage","water"]
static func entries()->Array[Dictionary]:
	return [
	_e("germination_trials","Germination Trials",["seed_selection","standard_measures"],"Counted seed samples are sprouted before sowing so poor establishment can be distinguished from later crop losses.","establishment",1,.025,0,0,.005,0),
	_e("seed_cleaning","Seed Cleaning",["seed_selection","basketry"],"Screens and hand sorting separate useful seed from chaff, stones and visibly damaged material.","establishment",2,.035,0,0,.01,0),
	_e("sowing_depth_trials","Sowing Depth Trials",["germination_trials","experimental_controls"],"Comparable seed is planted at measured depths to find which placements emerge reliably in the local soil.","establishment",3,.045,0,0,.012,0),
	_e("row_spacing_trials","Row Spacing Trials",["germination_trials","standard_measures"],"Parallel planted strips compare crowding, access and harvest without confusing spacing with seed quality.","establishment",4,.055,0,0,.015,0),
	_e("seedbed_firming","Seedbed Firming",["sowing_depth_trials","crop_calendars"],"Farmers compare seed contact and emergence after carefully pressing rather than merely loosening a seedbed.","establishment",5,.065,0,0,.018,0),
	_e("mass_seed_selection","Mass Seed Selection",["seed_reserves","crop_calendars"],"Seed from many desirable plants is pooled across harvests while retaining enough plants to avoid a narrow accidental lineage.","breeding",1,.035,0,0,.01,0),
	_e("progeny_rows","Progeny Rows",["mass_seed_selection","tallies"],"Offspring of selected plants are kept in identifiable rows so inherited performance can be compared.","breeding",2,.05,0,0,.015,.005),
	_e("controlled_pollination","Controlled Pollination",["progeny_rows","experimental_controls"],"Selected parents are crossed deliberately and their offspring kept separate from uncontrolled seed mixtures.","breeding",3,.07,0,0,.025,.01),
	_e("field_variety_trials","Field Variety Trials",["progeny_rows","statistical_sampling"],"Candidate varieties are compared in repeated field plots rather than judged from a single exceptional plant.","breeding",4,.085,0,.025,.025,.01),
	_e("regional_seed_trials","Regional Seed Trials",["field_variety_trials","regional_maps"],"The same seed is compared across growing districts so local adaptation is not mistaken for universal superiority.","breeding",5,.10,0,.04,.03,.01),
	_e("crop_residue_cover","Crop Residue Cover",["managed_fallow","cordage"],"Harvest residue is retained over soil instead of leaving the surface entirely exposed between crops.","cover",1,0,.15,.025,.005,.005),
	_e("green_manure_crops","Green Manure Crops",["crop_rotation","seed_reserves"],"A deliberately grown crop is returned to the soil rather than harvested for food, exchanging immediate output for land condition.","cover",2,0,.25,.03,.02,.04),
	_e("cover_crop_mixtures","Cover Crop Mixtures",["green_manure_crops","field_variety_trials"],"Different cover plants are combined and observed for complementary rooting and seasonal soil protection.","cover",3,.005,.35,.06,.025,.045),
	_e("contour_cultivation","Contour Cultivation",["geometric_survey","crop_calendars"],"Cultivation follows measured contours so disturbed soil and runoff are less directly connected down a slope.","tillage",1,0,.12,.015,.01,.005),
	_e("strip_cropping","Strip Cropping",["contour_cultivation","crop_rotation"],"Alternating crop strips interrupt long exposed slopes while requiring more careful work around field boundaries.","tillage",2,.005,.20,.025,.015,.01),
	_e("reduced_tillage","Reduced Tillage",["contour_cultivation","soil_assays"],"Repeated observations distinguish necessary seedbed work from disruptive passes that leave soil structure poorer.","tillage",3,.01,.25,.04,.005,0),
	_e("soil_infiltration_trials","Soil Infiltration Trials",["soil_assays","standard_measures"],"Measured additions of water reveal differences in infiltration and surface sealing that visual soil descriptions miss.","water",1,.015,0,.025,.005,0),
	_e("mulch_water_management","Mulch Water Management",["crop_residue_cover","soil_infiltration_trials"],"Cover depth and placement are compared against water retention and emergence instead of applying the same mulch everywhere.","water",2,.02,.025,.06,.015,.005),
	_e("irrigation_loss_accounts","Irrigation Loss Accounts",["irrigation_schedules","material_accounting"],"Water delivered and crop response are compared along a distribution route to identify where irrigation effort is being lost.","water",3,.03,0,.07,.02,0),
	_e("soil_moisture_scheduling","Soil Moisture Scheduling",["soil_infiltration_trials","irrigation_loss_accounts"],"Observed soil moisture and crop response guide watering intervals rather than applying identical turns regardless of conditions.","water",4,.045,.025,.10,.025,0)
	]
static func _e(id:String,label:String,parents:Array,observation:String,group:String,rank:int,gain:float,protection:float,weather:float,labor:float,land:float)->Dictionary:
	return {"id":id,"name":label,"direction":"Sustenance","day":0,"chance":.0025,"requires":parents.duplicate(),"requires_all":parents.duplicate(),"requires_any":[],"learning_routes":[{"id":"local","label":label,"requires_all":[]}],"signals":["food","nature","information"],"observation":observation,"effects":{},"resource_requirements":[{"resource":"Fertile Soil","stage":"recognized"}],"agronomy_profile":{"group":group,"rank":rank,"yield_gain":gain,"soil_protection":protection,"weather_buffer":weather,"labor_cost":labor,"land_cost":land},"production_contract":"Changes staffed, settled cultivation through the authored crop-yield, soil-protection and weather-response profile, including its labor and land costs. Only the strongest adopted practice per family operates. No food, seed or farmland is granted."}
# Per-owner result of factors(); static, so saves never capture it.
static var _factor_cache:Dictionary={}
static func factors(traveling:bool=false)->Dictionary:
	var result:={"yield":1.0,"soil_damage":1.0,"weather_buffer":0.0,"labor_cost":0.0,"land_cost":0.0}
	if traveling or not WorldSimulation.state.settlement_site_committed or WorldSimulation.state.effective_workers("Food")<=0 or "seed_selection" not in WorldSimulation.state.known_discoveries:return result
	# The rest depends only on this owner's known discoveries and adoption levels.
	var owner:=WorldSimulation.discovery.get_instance_id()
	var key:=[WorldSimulation.discovery.catalog.size(),WorldSimulation.state.known_discoveries.hash(),WorldSimulation.state.discovery_adoption.hash()]
	var cached:Dictionary=_factor_cache.get(owner,{})
	if cached.get("key")==key:return (cached.value as Dictionary).duplicate()
	var selected:Dictionary={};var ranks:Dictionary={}
	for id:String in WorldSimulation.state.known_discoveries:
		var entry:Dictionary=WorldSimulation.discovery.discovery_definition(id)
		var profile:Dictionary=entry.get("agronomy_profile",{})
		if profile.is_empty():continue
		var adoption:=WorldSimulation.discovery.adoption(id)
		var rank:=float(profile.rank)*adoption
		if rank>float(ranks.get(profile.group,0)):
			ranks[profile.group]=rank;selected[profile.group]={"profile":profile,"adoption":adoption}
	var gain:=0.0;var protection:=0.0
	for choice:Dictionary in selected.values():
		var p:Dictionary=choice.profile;var adoption:=float(choice.adoption)
		gain+=float(p.yield_gain)*adoption;protection+=float(p.soil_protection)*adoption
		result.weather_buffer+=float(p.weather_buffer)*adoption
		result.labor_cost+=float(p.labor_cost)*adoption;result.land_cost+=float(p.land_cost)*adoption
	result.labor_cost=minf(.2,result.labor_cost);result.land_cost=minf(.15,result.land_cost)
	result["yield"]=(1+minf(.3,gain))*(1-result.labor_cost)*(1-result.land_cost)
	result.soil_damage=1-minf(.65,protection)
	result.weather_buffer=minf(.3,result.weather_buffer)
	_factor_cache[owner]={"key":key,"value":result.duplicate()}
	return result
static func weather_factor(base:float,factors:Dictionary)->float:
	return base+maxf(0,1-base)*float(factors.weather_buffer)
