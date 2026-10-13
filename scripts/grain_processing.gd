extends RefCounted
## Ways of handling the grain harvest the people can learn. What each gives is
## in the food rules (food_system.gd); this file only names them for research.
## The rate, cost, inputs and power figures are the design record of the
## handling equipment that was retired; nothing reads them.
const METHODS := {
	"threshing_frames":{"name":"Threshing Frames","requires":["seed_selection","joinery"],"rate":30.0,"cost":{"Timber":4.0,"Stone":1.0,"Fiber Plants":1.0},"inputs":{},"power":0.0,"observation":"Frames and repeated impacts separate grain from harvested heads. Handling takes time and loses a small share of recoverable food."},
	"winnowing_practice":{"name":"Winnowing Practice","requires":["threshing_frames","seasonal_patterns","basketry"],"rate":40.0,"cost":{"Fiber Plants":2.0,"Timber":1.0},"inputs":{},"power":0.0,"observation":"Repeated tossing and sorting separate lighter residues from grain. Containers and handlers are required; discarded material is not extra food."},
	"grain_moisture_testing":{"name":"Grain-Moisture Testing","requires":["measurement_uncertainty","precision_thermometry","winnowing_practice"],"rate":60.0,"cost":{"Laboratory Glassware":1.0,"Timber":2.0,"Stone":1.0},"inputs":{"Timber":.005},"power":0.0,"observation":"Representative samples are compared before and after controlled drying. The sampled batch becomes eligible for monitored forced-air treatment."},
	"forced_air_grain_drying":{"name":"Forced-Air Grain Drying","requires":["grain_moisture_testing","electric_motors"],"rate":40.0,"cost":{"Electric Motors":1.0,"Insulated Cable":1.0,"Timber":4.0},"inputs":{},"power":.025,"observation":"Powered airflow dries an assessed grain batch. Fans, handlers and a finite electrical supply limit the volume treated."},
	"roller_grain_milling":{"name":"Roller Grain Milling","requires":["grain_milling","precision_machinery"],"rate":35.0,"cost":{"Precision Machine Tool Sets":1.0,"Electric Motors":1.0,"Steel":2.0},"inputs":{},"power":.04,"observation":"Driven rollers reduce grain through measured gaps. Their throughput requires deployed machinery, handlers and electricity."},
	"flour_sifting":{"name":"Flour Sifting","requires":["grain_milling","plain_weaving"],"rate":30.0,"cost":{"Woven Cloth":1.0,"Timber":2.0},"inputs":{},"power":0.0,"observation":"Meshes separate fine flour from edible bran. Both fractions remain in the food ledger; a small handling loss is recorded."},
	"grain_malting":{"name":"Grain Malting","requires":["germination_trials","food_drying"],"rate":15.0,"cost":{"Clay":3.0,"Timber":2.0},"inputs":{"Freshwater":.12,"Timber":.02},"power":0.0,"observation":"A portion of suitable grain is steeped, germinated and dried over four days. It is unavailable while in process and returns with less stored food energy."}
}
static func entries()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id:String in METHODS:
		var m:Dictionary=METHODS[id]
		result.append({"id":id,"name":m.name,"direction":"Sustenance","day":0,"chance":.002,"requires":m.requires.duplicate(),"requires_all":m.requires.duplicate(),"requires_any":[],"learning_routes":[{"id":"local","label":m.name,"requires_all":[]}],"signals":["food","crafting","storage"],"observation":m.observation,"effects":{},"production_contract":"A way of working, not a building: there is nothing to install. What it gives comes as the people take it up."})
	return result
