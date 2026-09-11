extends RefCounted
## Manufactured batches use the same physical stocks and finite workshop lines
## as equipment. Quantities are game batches, not claims of industrial SI units.
const PRODUCTS={
	"glass_batch":{"name":"Glass batches","output":"Glass","gate":"glassmaking","materials":{"Fine Sand":2.0,"Limestone":.3,"Timber":3.0},"days":3.0,"tooling":{"Stone":12.0,"Clay":8.0}},
	"refined_copper":{"name":"Refined copper","output":"Refined Copper","gate":"copper_smelting","materials":{"Copper Ore":2.0,"Timber":2.0},"days":3.0,"tooling":{"Stone":12.0,"Clay":8.0}},
	"wrought_iron":{"name":"Wrought iron","output":"Wrought Iron","gate":"bloomery_smelting","materials":{"Iron Ore":3.0,"Timber":4.0},"days":5.0,"tooling":{"Stone":18.0,"Clay":12.0}},
	"steel_stock":{"name":"Refined steel","output":"Steel","gate":"steel_refining","materials":{"Wrought Iron":2.0,"Coal":1.0,"Limestone":.2},"days":6.0,"tooling":{"Stone":24.0,"Clay":16.0}},
	"copper_wire":{"name":"Drawn copper wire","output":"Copper Wire","gate":"wire_drawing","materials":{"Refined Copper":1.0},"days":2.0,"tooling":{"Wrought Iron":3.0,"Timber":5.0}},
	"insulated_cable":{"name":"Insulated cable","output":"Insulated Cable","gate":"cable_insulation","materials":{"Copper Wire":1.0,"Fiber Plants":1.0,"Bitumen":.2},"days":2.0,"tooling":{"Timber":8.0,"Clay":2.0}},
	"optical_lens":{"name":"Ground optical lenses","output":"Optical Lenses","gate":"optical_lenses","materials":{"Glass":1.0,"Fine Sand":.3},"days":4.0,"tooling":{"Timber":5.0,"Stone":5.0}},
	"pressure_vessel":{"name":"Pressure vessels","output":"Pressure Vessels","gate":"pressure_vessels","materials":{"Wrought Iron":3.0,"Coal":1.0},"days":10.0,"tooling":{"Wrought Iron":5.0,"Stone":10.0}},
	"electrical_generator":{"name":"Electrical generators","output":"Electrical Generators","gate":"electrical_generators","materials":{"Refined Copper":5.0,"Wrought Iron":8.0,"Insulated Cable":2.0},"days":20.0,"tooling":{"Wrought Iron":8.0,"Timber":10.0}},
	"electric_motor":{"name":"Electric motors","output":"Electric Motors","gate":"electric_motors","materials":{"Wrought Iron":4.0,"Copper Wire":3.0,"Insulated Cable":2.0},"days":12.0,"tooling":{"Wrought Iron":6.0,"Timber":8.0}}
}
static func product(item:String)->Dictionary:return PRODUCTS.get(item,{})
static func entries()->Array[Dictionary]:
	return [
		{"id":"steel_refining","name":"Steel Refining","direction":"Materials","day":54000,"chance":.002,"requires":["bloomery_smelting","coke_firing","precision_thermometry"],"signals":["crafting","materials","research"],"observation":"Controlled refining compares carbon content and the behavior of iron under working loads.","effects":{},"production_contract":"Enables a finite workshop line converting wrought iron, coal and flux into steel batches.","production_items":["steel_stock"]},
		{"id":"wire_drawing","name":"Wire Drawing","direction":"Materials","day":26000,"chance":.003,"requires":["copper_casting","workshop_standards"],"signals":["crafting","materials"],"observation":"Successive dies reduce drawn metal to repeatable wire sections.","effects":{},"production_contract":"Converts physically refined copper to wire using workshop labor and iron tooling.","production_items":["copper_wire"]},
		{"id":"cable_insulation","name":"Cable Insulation","direction":"Materials","day":44000,"chance":.002,"requires":["wire_drawing","bitumen_sealing","electrical_measurement"],"signals":["crafting","research"],"observation":"Wrapped conductors and insulating compounds are tested against leakage and contact faults.","effects":{},"production_contract":"Consumes wire, fibers and bitumen to manufacture insulated cable for motors and generators.","production_items":["insulated_cable"]}
	]
