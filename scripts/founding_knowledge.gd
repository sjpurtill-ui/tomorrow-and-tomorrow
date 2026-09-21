extends RefCounted
## Inherited everyday competence, not newly invented technologies or free industry.
## Applied only by new-world reset; save loading retains its recorded knowledge.
const PRACTICES:Array[String]=[
	"seasonal_patterns","edible_resource_recognition","timber_grading","fiber_grading",
	"controlled_flaking","cordage","hafted_tools","food_drying","watch_rotation","hafted_weapons"]
static func adoption()->Dictionary:
	var result:Dictionary={}
	for id in PRACTICES:result[id]=1.0
	return result
static func portable_supplies(population:float)->Dictionary:
	var scale:=maxf(0,population)
	return {"Flaked Stone Tools":scale*.03,"Cordage Bundles":scale*.04,"Hafted Tool Sets":scale*.02,"Drying Mats":scale*.025,"Flint":scale*.01,"Stone":scale*.025}
