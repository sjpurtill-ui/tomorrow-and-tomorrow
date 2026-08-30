extends RefCounted

# Invisible possibility field: 12 dynamics × 4 real subconditions × eight
# modes of learning × twelve levels of maturity = 4,608 situated discoveries.
# The first eight levels form the initial 200-year phase. Later levels keep the
# same lived lines of inquiry meaningful across centuries and millennia.
const STAGES:Array[Dictionary]=[
	{"name":"Noticed Pattern","day":30,"chance":0.0120,"verb":"notice recurring differences in"},
	{"name":"Shared Observation","day":180,"chance":0.0100,"verb":"compare accounts concerning"},
	{"name":"Repeated Practice","day":540,"chance":0.0085,"verb":"repeat practical responses to"},
	{"name":"Working Distinction","day":1200,"chance":0.0070,"verb":"separate useful and harmful forms of"},
	{"name":"Measured Trial","day":3000,"chance":0.0055,"verb":"preserve measured trials concerning"},
	{"name":"Reliable Method","day":7000,"chance":0.0042,"verb":"teach a method that reliably changes"},
	{"name":"Specialized Practice","day":18000,"chance":0.0030,"verb":"support specialists devoted to"},
	{"name":"General Principle","day":43800,"chance":0.0022,"verb":"use general principles to predict"},
	{"name":"Civic System","day":109500,"chance":0.0015,"verb":"coordinate institutions responsible for"},
	{"name":"Scholarly Tradition","day":255500,"chance":0.0010,"verb":"sustain generations of criticism and teaching about"},
	{"name":"Formal Discipline","day":547500,"chance":0.00065,"verb":"formalize specialized evidence and institutions around"},
	{"name":"Integrated Science","day":1095000,"chance":0.00040,"verb":"connect theory, instrumentation, and public systems across"}
]

const SUBCATEGORIES:Dictionary={
	"demography":["Fertility conditions","Maternal safety","Child survival","Shelter capacity"],
	"nutrition":["Daily supply","Diet quality","Stored reserve","Land productivity"],
	"health":["General health","Water & sanitation","Disease control","Injury safety"],
	"labor":["Able workforce","Work efficiency","Coordination","Workload balance"],
	"knowledge":["Observers","Directed attention","Preserved knowledge","Communication"],
	"production":["Material supply","Tool quality","Craft capacity","Standardization"],
	"infrastructure":["Housing","Construction","Public works","Resilience"],
	"logistics":["Carrying capacity","Route quality","Storage system","Trade reach"],
	"ecology":["Land health","Natural recovery","Pollution control","Resource sustainability"],
	"institutions":["Administration","Legitimacy","State capacity","Institutional flexibility"],
	"security":["Public safety","Organized defense","Military readiness","Crisis resilience"],
	"culture":["Social cohesion","Shared legitimacy","Inquiry breadth","Collective memory"]
}

const LENSES:Array[Dictionary]=[
	{"name":"Household Experience","prefix":"Household","signal":"administration"},
	{"name":"Seasonal Comparison","prefix":"Seasonal","signal":"exploration"},
	{"name":"Material Experiment","prefix":"Material","signal":"crafting"},
	{"name":"Workplace Practice","prefix":"Occupational","signal":"construction"},
	{"name":"Recorded Cases","prefix":"Recorded","signal":"research"},
	{"name":"Environmental Contrast","prefix":"Environmental","signal":"survey"},
	{"name":"Institutional Trial","prefix":"Institutional","signal":"administration"},
	{"name":"Regional Comparison","prefix":"Regional","signal":"travel"}
]

const EFFECTS:Dictionary={
	"demography":["conception_support","maternal_safety"],"nutrition":["food_output","nutrition_quality"],
	"health":["health_protection","disease_exposure"],"labor":["labor_efficiency","task_coordination"],
	"knowledge":["knowledge_rate","knowledge_preservation"],"production":["tool_quality","craft_output"],
	"infrastructure":["construction_rate","disaster_resilience"],"logistics":["haul_capacity","route_speed"],
	"ecology":["ecology_recovery","ecological_pressure"],"institutions":["state_capacity","legitimacy"],
	"security":["security_efficiency","warfare_readiness"],"culture":["cohesion","adoption_rate"]
}

const DYNAMIC_SIGNALS:Dictionary={
	"demography":"population","nutrition":"food","health":"health","labor":"construction","knowledge":"research","production":"crafting",
	"infrastructure":"construction","logistics":"logistics","ecology":"foraging","institutions":"administration","security":"defense","culture":"education"
}

const RESOURCE_BASIS:Dictionary={
	"Fertility conditions":"Medicinal Plants","Maternal safety":"Freshwater","Child survival":"Freshwater","Shelter capacity":"Timber",
	"Daily supply":"Fertile Soil","Diet quality":"Fertile Soil","Stored reserve":"Clay","Land productivity":"Fertile Soil",
	"General health":"Medicinal Plants","Water & sanitation":"Freshwater","Disease control":"Medicinal Plants","Injury safety":"Fiber Plants",
	"Able workforce":"","Work efficiency":"Stone","Coordination":"","Workload balance":"",
	"Observers":"","Directed attention":"","Preserved knowledge":"Clay","Communication":"Fiber Plants",
	"Material supply":"Stone","Tool quality":"Stone","Craft capacity":"Timber","Standardization":"Clay",
	"Housing":"Timber","Construction":"Stone","Public works":"Stone","Resilience":"Timber",
	"Carrying capacity":"Fiber Plants","Route quality":"Stone","Storage system":"Clay","Trade reach":"",
	"Land health":"Fertile Soil","Natural recovery":"Timber","Pollution control":"Freshwater","Resource sustainability":"Timber",
	"Administration":"","Legitimacy":"","State capacity":"Clay","Institutional flexibility":"",
	"Public safety":"","Organized defense":"Timber","Military readiness":"Iron Ore","Crisis resilience":"Stone",
	"Social cohesion":"","Shared legitimacy":"","Inquiry breadth":"","Collective memory":"Clay"
}

static func entries()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for dynamic_id in SUBCATEGORIES:
		var subcategories:Array=SUBCATEGORIES[dynamic_id]
		for subcategory_index in subcategories.size():
			var subcategory:=String(subcategories[subcategory_index])
			for lens_index in LENSES.size():
				var lens:Dictionary=LENSES[lens_index]
				var gate_spread:=0.80+float(absi(hash("%s:%s:%s" % [dynamic_id,subcategory,lens.name]))%401)/1000.0
				var previous_id:=""
				for stage_index in STAGES.size():
					var stage:Dictionary=STAGES[stage_index]
					var id:="inquiry_%s_%s_%s_%02d" % [_slug(dynamic_id),_slug(subcategory),_slug(String(lens.name)),stage_index+1]
					var requirements:Array=[] if previous_id=="" else [previous_id]
					var resource:=String(RESOURCE_BASIS.get(subcategory,""))
					var resource_requirements:Array=[]
					if resource!="":
						var access_stage:="recognized" if stage_index<3 else ("accessible" if stage_index<7 else "developed")
						resource_requirements=[{"resource":resource,"stage":access_stage,"minimum_stock":0.0}]
					var effect_names:Array=EFFECTS[dynamic_id]
					var primary:=0.0035+float(stage_index)*0.00075
					var secondary:=0.0018+float(stage_index)*0.00045
					if String(effect_names[1]) in ["disease_exposure","ecological_pressure"]: secondary=-secondary
					result.append({
						"id":id,"name":"%s: %s %s" % [String(stage.name),String(lens.prefix),subcategory],
						"dynamic":String(dynamic_id),"subcategory":subcategory,"direction":String(dynamic_id),
						"chance":float(stage.chance),"day":roundi(float(stage.day)*gate_spread)+lens_index*29+subcategory_index*11,
						"requires":requirements,"resource_requirements":resource_requirements,
						"signals":[String(DYNAMIC_SIGNALS[dynamic_id]),String(lens.signal)],
						"observation":"People %s %s. The finding remains grounded in %s." % [String(stage.verb),subcategory.to_lower(),String(lens.name).to_lower()],
						"effects":{String(effect_names[0]):primary,String(effect_names[1]):secondary},
						"frontier":true,"maturity":stage_index+1,"lens":String(lens.name)
					})
					previous_id=id
	return result

static func _slug(value:String)->String:
	return value.to_lower().replace(" ","_").replace("-","_").replace("&","and").replace("/","_")
