extends RefCounted

# Invisible possibility field: 12 dynamics × 4 real subconditions × eight
# modes of learning × twelve levels of maturity = 4,608 situated discoveries.
# The first eight levels form the initial 200-year phase. Later levels keep the
# same lived lines of inquiry meaningful across centuries and millennia.
const STAGES:Array[Dictionary]=[
	{"name":"Field Survey","day":30,"chance":0.0120,"verb":"record and compare recurring differences in"},
	{"name":"Comparative Study","day":180,"chance":0.0100,"verb":"compare independent accounts concerning"},
	{"name":"Replicated Practice","day":540,"chance":0.0085,"verb":"repeat practical trials addressing"},
	{"name":"Operational Standard","day":1200,"chance":0.0070,"verb":"separate useful and harmful methods affecting"},
	{"name":"Measured Trial","day":3000,"chance":0.0055,"verb":"preserve measured trials concerning"},
	{"name":"Validated Method","day":7000,"chance":0.0042,"verb":"teach and verify a method that reliably changes"},
	{"name":"Specialist Program","day":18000,"chance":0.0030,"verb":"support specialists testing"},
	{"name":"General Theory","day":43800,"chance":0.0022,"verb":"use general principles to predict"},
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

# The inquiry stays broad while it is active, but a completed discovery must
# name a thing people can actually teach, build, record, or organize. These
# concrete subjects combine with eight evidence traditions and twelve maturity
# levels to produce 4,608 distinct, causal outcomes through the modern age.
const CONCRETE_LINES:Dictionary={
	"Fertility conditions":{"subject":"birth-spacing records","finding":"comparing intervals between births with maternal recovery identifies spacing practices that preserve both fertility and health"},
	"Maternal safety":{"subject":"clean birthing stations","finding":"washing hands, cloth, water vessels, and birthing surfaces before delivery measurably reduces dangerous postpartum illness"},
	"Child survival":{"subject":"weaning and fever registers","finding":"recording weaning foods, fever duration, and outcomes reveals which care routines keep more children alive"},
	"Shelter capacity":{"subject":"roofed sleeping bays","finding":"counting dry sleeping places against crowding and illness predicts safe occupancy better than nominal floor area"},
	"Daily supply":{"subject":"ration-weight schedules","finding":"weighing incoming food and issued portions exposes predictable daily deficits before stores are exhausted"},
	"Diet quality":{"subject":"mixed-food meal plans","finding":"combining staple foods with varied gathered or cultivated foods produces stronger workers and fewer deficiency illnesses"},
	"Stored reserve":{"subject":"sealed reserve vessels","finding":"drying stores before sealing them above damp ground sharply reduces mold, pests, and spoilage"},
	"Land productivity":{"subject":"plot-yield rotations","finding":"recording harvest per plot across repeated planting sequences identifies rotations that restore rather than exhaust soil"},
	"General health":{"subject":"symptom and recovery ledgers","finding":"grouping symptoms with treatments and recovery times separates reliably helpful care from custom and coincidence"},
	"Water & sanitation":{"subject":"upstream water points","finding":"taking drinking water above washing and waste sites reduces recurring stomach illness"},
	"Disease control":{"subject":"household isolation rules","finding":"separating symptomatic households and their utensils interrupts visible chains of person-to-person illness"},
	"Injury safety":{"subject":"splinted wound protocols","finding":"clean wrapping, immobilization, and scheduled inspection preserve more injured people for later work"},
	"Able workforce":{"subject":"work-capacity rosters","finding":"matching assignments to recovery, age, and demonstrated capacity prevents avoidable exhaustion and labor loss"},
	"Work efficiency":{"subject":"task-time standards","finding":"timing repeated jobs reveals the tool sequence and crew size that complete the same work with fewer labor-days"},
	"Coordination":{"subject":"crew handoff signals","finding":"shared calls, markers, and responsibility at each handoff reduce idle time and duplicated work"},
	"Workload balance":{"subject":"rotating work shifts","finding":"scheduled rotation between heavy, light, and recovery duties sustains output longer than permanent exhausting assignments"},
	"Observers":{"subject":"field-observer notebooks","finding":"using the same dated fields for every observation makes independent accounts comparable and errors easier to expose"},
	"Directed attention":{"subject":"question assignment boards","finding":"assigning a bounded question, evidence owner, and review date prevents attention from dissolving across unrelated curiosities"},
	"Preserved knowledge":{"subject":"fired-clay record tablets","finding":"durable indexed records preserve quantities and procedures after individual witnesses die or leave"},
	"Communication":{"subject":"relay-message protocols","finding":"fixed message forms, repeat-back checks, and named relay stations carry instructions farther with less distortion"},
	"Material supply":{"subject":"graded material bins","finding":"sorting timber, stone, clay, and fibers by measured properties sends appropriate material to each job and reduces waste"},
	"Tool quality":{"subject":"edge-angle tool standards","finding":"controlling edge angle, hardness, and sharpening intervals produces tools that cut longer and fail less often"},
	"Craft capacity":{"subject":"apprentice work sequences","finding":"teaching a fixed progression of demonstrated operations creates competent makers faster than unguided imitation"},
	"Standardization":{"subject":"reference gauges","finding":"shared gauges make parts, measures, and containers interchangeable across different makers"},
	"Housing":{"subject":"modular dwelling frames","finding":"repeating tested structural bays speeds construction while preserving light, drainage, and safe occupancy"},
	"Construction":{"subject":"load-bearing joint patterns","finding":"placing tested joints along observed load paths permits larger structures with fewer collapses"},
	"Public works":{"subject":"drainage and path crews","finding":"permanent crews maintaining shared drains, crossings, and paths prevent small failures from becoming settlement-wide disruptions"},
	"Resilience":{"subject":"replaceable structural braces","finding":"sacrificial braces and standardized repair pieces let damaged structures be restored without complete rebuilding"},
	"Carrying capacity":{"subject":"balanced pack frames","finding":"distributing loads across shoulders and hips increases safe carried weight while reducing injury"},
	"Route quality":{"subject":"graded route markers","finding":"measured grades, drainage, surface repair, and distance markers reduce travel time and uncertainty"},
	"Storage system":{"subject":"raised sealed storehouses","finding":"separating stores by material and keeping them dry, sealed, counted, and guarded reduces loss throughout the chain"},
	"Trade reach":{"subject":"scheduled exchange caravans","finding":"fixed departure windows, relay stops, manifests, and return obligations make distant exchange repeatable"},
	"Land health":{"subject":"soil-cover rotations","finding":"keeping living or cut cover on resting ground reduces erosion and restores productive soil"},
	"Natural recovery":{"subject":"managed woodland closures","finding":"closing depleted patches until measured regrowth thresholds are met preserves future timber and forage"},
	"Pollution control":{"subject":"downstream waste zones","finding":"separating waste, craft runoff, and habitation according to water flow reduces contamination of occupied land"},
	"Resource sustainability":{"subject":"harvest quotas","finding":"counting extraction against observed renewal sets limits that avoid exhausting the source"},
	"Administration":{"subject":"household census rolls","finding":"regularly reconciled counts of people, obligations, stores, and locations make collective plans executable"},
	"Legitimacy":{"subject":"public judgment records","finding":"publishing reasons and precedents for consequential decisions makes authority more predictable and contestable"},
	"State capacity":{"subject":"district tax and labor rolls","finding":"territorial registers connect assessed resources to specific collection, service, and public-work obligations"},
	"Institutional flexibility":{"subject":"sunset and review rules","finding":"automatically reviewing emergency and obsolete rules lets institutions adapt without waiting for collapse"},
	"Public safety":{"subject":"night-watch sectors","finding":"dividing occupied ground into timed patrol sectors closes gaps while limiting sentry exhaustion"},
	"Organized defense":{"subject":"layered alarm posts","finding":"linked lookouts, rally points, obstacles, and reserve positions convert warning time into organized resistance"},
	"Military readiness":{"subject":"formation drill cycles","finding":"repeated movement, command, supply, and casualty drills let large formations act coherently under pressure"},
	"Crisis resilience":{"subject":"reserve muster plans","finding":"preassigned reserves, stores, shelters, routes, and decision authority shorten response to shocks"},
	"Social cohesion":{"subject":"shared feast rotations","finding":"reciprocal hosting and contribution across households builds repeated obligations beyond kin groups"},
	"Shared legitimacy":{"subject":"public oath ceremonies","finding":"witnessed reciprocal oaths make the limits and duties of rulers and communities common knowledge"},
	"Inquiry breadth":{"subject":"cross-craft study circles","finding":"regular exchange between different crafts transfers methods and exposes questions no single practice can see"},
	"Collective memory":{"subject":"dated oral-history recitations","finding":"fixed public recitation, correction, and dated anchors preserve events more reliably across generations"}
}

const STAGE_ACTIONS:Array[String]=["Mapped","Compared","Repeated","Standardized","Measured","Validated","Specialist","Predictive","Civic","Scholarly","Formal","Integrated"]
const LENS_QUALIFIERS:Array[String]=["Household","Seasonal","Material","Workshop","Case-Recorded","Environmental","Institutional","Regional"]
# Each investigative tradition changes what counts as evidence. These are not
# cosmetic prefixes: the method can expose a different cause even when two
# civilizations are asking about the same practical condition.
const LENS_METHODS:Array[String]=[
	"Matched households using the practice are compared with households that do not, isolating the daily routines and living conditions that change the result",
	"The same procedure is tracked through successive seasonal cycles, revealing when timing, weather, and stored reserves strengthen or reverse the result",
	"Materials, dimensions, and preparation are changed one variable at a time, identifying the physical property responsible for success or failure",
	"Crews record task order, tools, handoffs, fatigue, and output, exposing which working sequence actually produces the improvement",
	"Every case is recorded with the same starting conditions, intervention, and outcome, allowing rare failures and apparent successes to be tested against the full record",
	"The practice is repeated across contrasting water, soil, climate, terrain, and exposure conditions, separating a local accident from an environmental relationship",
	"Different rules, offices, incentives, and enforcement arrangements are trialed against the same problem, showing which organization makes the practice dependable",
	"Independent settlements and routes exchange comparable records, revealing which result travels beyond one place and which depends on local circumstance"
]
# Maturity is also causal. A survey, a reproducible technique, a predictive
# model, and a planet-scale public system are genuinely different capabilities,
# rather than the same discovery with a larger number attached.
const STAGE_APPLICATIONS:Array[String]=[
	"Known cases, locations, quantities, and visible failures can now be mapped consistently enough to reveal the first dependable pattern",
	"Matched alternatives can now be compared while obvious confounding conditions are held apart, eliminating several plausible but false explanations",
	"Independent crews can now reproduce the result from written or demonstrated instructions instead of relying on the original discoverer",
	"A fixed sequence, reference specification, inspection point, and failure rule can now hold the method stable across ordinary workplaces",
	"Measured thresholds, rates, tolerances, and dose-response limits now show how much intervention is useful and where it becomes wasteful or dangerous",
	"Deliberate attempts to disprove the method across independent cases have established its operating limits and the conditions under which it fails",
	"Dedicated specialists, instruments, training, and maintenance roles can now sustain precision that general labor cannot reliably preserve",
	"A tested model can now predict likely outcomes and failures before resources are committed, allowing plans to change in advance rather than after loss",
	"Territorial institutions can now fund, inspect, teach, and maintain the practice across many settlements without requiring direct supervision from its originators",
	"Generations of criticism, archival comparison, and specialist teaching can now correct the practice while preserving its accumulated evidence",
	"Formal notation, interoperable measures, controlled terminology, and explicit rules of inference now let distant specialists extend the method without sharing a workshop",
	"Linked instruments, institutions, supply systems, and population-scale records now create a feedback system that detects new conditions and revises practice across an entire civilization"
]
const ABILITY_RESULTS:Dictionary={
	"demography":"safe population renewal becomes more reliable","nutrition":"food output, preservation, and nourishment improve","health":"preventable sickness, exposure, and injury decline","labor":"the same population can coordinate more usable work","knowledge":"evidence survives, travels, and compounds more effectively","production":"materials and craft labor produce more dependable output","infrastructure":"construction becomes faster and more resistant to failure","logistics":"more material can move farther with fewer losses","ecology":"resource use can continue without destroying its physical basis","institutions":"collective decisions become more legitimate and executable","security":"warning, readiness, and organized defense improve","culture":"shared practice, memory, and adoption become more durable"
}
const SOCIAL_RESULTS:Dictionary={
	"demography":"Longer family lives change dependency, inheritance, housing, and care obligations across generations",
	"nutrition":"Reliable nourishment supports denser settlement and frees labor from repeated emergency food searches",
	"health":"Preserved lives and skills strengthen households while creating demand for durable systems of care",
	"labor":"Coordinated crews can undertake work beyond one household, increasing both collective capacity and claims on people's time",
	"knowledge":"Reproducible evidence can challenge inherited authority because claims no longer depend only on status or memory",
	"production":"Dependable output supports specialization and exchange while making communities more reliant on linked crafts",
	"infrastructure":"Larger permanent settlements become possible, but their population also becomes dependent on continued maintenance",
	"logistics":"Distant communities can sustain exchange and shared obligations instead of remaining isolated by carrying distance",
	"ecology":"Present extraction becomes negotiable against the measured continuity of land and resources for later generations",
	"institutions":"Administrative reach grows, sharpening conflict over who controls records, obligations, and binding decisions",
	"security":"Defense shifts from isolated household action toward organized provision, command, training, and public accountability",
	"culture":"A broader shared identity can spread while disagreements about memory, belonging, and legitimate practice become more visible"
}

static func entries()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for dynamic_id in SUBCATEGORIES:
		var subcategories:Array=SUBCATEGORIES[dynamic_id]
		for subcategory_index in subcategories.size():
			var subcategory:=String(subcategories[subcategory_index])
			for lens_index in LENSES.size():
				var lens:Dictionary=LENSES[lens_index]
				var path_key:="%s::%s::%s" % [dynamic_id,subcategory,String(lens.name)]
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
					var concrete:Dictionary=CONCRETE_LINES.get(subcategory,{"subject":subcategory.to_lower(),"finding":"repeated comparison identifies a dependable practice that changes this condition"})
					var discovery_name:="%s %s %s" % [STAGE_ACTIONS[stage_index],LENS_QUALIFIERS[lens_index],String(concrete.subject).capitalize()]
					var line_name:="%s inquiry through %s" % [subcategory,String(lens.name).to_lower()]
					var ability_result:=String(ABILITY_RESULTS.get(dynamic_id,"the civilization gains a repeatable practical capacity"))
					var lens_method:=LENS_METHODS[lens_index]
					var stage_application:=STAGE_APPLICATIONS[stage_index]
					var social_result:=String(SOCIAL_RESULTS.get(dynamic_id,"Collective expectations change as the practice spreads"))
					var mechanism_signature:="%s::%s::%s" % [String(concrete.subject),lens_method,stage_application]
					result.append({
						"id":id,"name":discovery_name,"line_name":line_name,
						"dynamic":String(dynamic_id),"subcategory":subcategory,"direction":String(dynamic_id),
						"chance":float(stage.chance),"day":roundi(float(stage.day)*gate_spread)+lens_index*29+subcategory_index*11,
						"requires":requirements,"resource_requirements":resource_requirements,
						"signals":[String(DYNAMIC_SIGNALS[dynamic_id]),String(lens.signal)],
						"question":"Which repeatable relationships within %s can be established through %s?" % [subcategory.to_lower(),String(lens.name).to_lower()],
						"method":"Assigned observers %s %s through %s; progress comes from staffed attention, relevant activity, material access, and capable leadership." % [String(stage.verb),subcategory.to_lower(),String(lens.name).to_lower()],
						"observation":"The established practice is %s. Core finding: %s. Method: %s. New operating capability: %s. Because this mechanism can now be taught, tested, and extended, %s. Social consequence: %s." % [discovery_name,String(concrete.finding),lens_method,stage_application,ability_result,social_result],
						"ability_reason":"Because %s can now be taught and repeated, %s." % [discovery_name,ability_result],
						"social_consequence":social_result,
						"mechanism_signature":mechanism_signature,
						"causal_mechanism":String(concrete.finding),"evidence_method":lens_method,"operating_capability":stage_application,
						"outcome_scope":"A concrete practice affecting %s will be named only if this line produces a repeatable result." % subcategory.to_lower(),
						"effects":{String(effect_names[0]):primary,String(effect_names[1]):secondary},
						"frontier":true,"maturity":stage_index+1,"stage_index":stage_index,
						"lens":String(lens.name),"lens_index":lens_index,"path_key":path_key,
						"branch_tags":[String(lens.signal),String(DYNAMIC_SIGNALS[dynamic_id])]
					})
					previous_id=id
	return result

static func _slug(value:String)->String:
	return value.to_lower().replace(" ","_").replace("-","_").replace("&","and").replace("/","_")
