extends RefCounted
## Read-only native quantities for the Buildings comparison board.
const Impact=preload("res://scripts/building_impact.gd")
static func pair(id:String,title:String,icon:String,left_label:String,left:float,right_label:String,right:float,unit:String,status:String="",bad:=false,tip:String="")->Dictionary:
	return {"id":id,"title":title,"icon":icon,"left_label":left_label,"left":left,"right_label":right_label,"right":right,"unit":unit,"status":status,"bad":bad,"tip":tip}
static func capacity()->Array:
	var state=WorldSimulation.state
	var homes:=Impact.homes();var people:=int(homes.people);var places:=int(homes.places)
	var rows:Array=[pair("Housing","Housing","homes","People",people,"Places",places,"people / places","%d places short"%(people-places) if places<people else "%d spare places"%(places-people),places<people)]
	var food=WorldSimulation.food
	if food!=null and food.has_method("_food_storage_capacity"):
		var capacity:=float(food.call("_food_storage_capacity"));var held:=0.0
		for amount in state.food_stocks.values():held+=float(amount)
		var eaten:=maxf(.1,float(state.simulation_metrics.get("food_consumption",state.population_exact)))
		rows.append(pair("FoodRoom","Food storage","stores","Stored",held,"Capacity",capacity,"rations",("%d days at full capacity"%roundi(capacity/eaten)),held>capacity,"Capacity is storage room, not food available to eat. Consumption uses today's rate."))
	var condition:=clampf(float(WorldSimulation.settlements.city_form().condition),0,1)
	rows.append(pair("Condition","Building condition","repair","Current",condition*100,"Fully repaired",100,"% condition","Failing · below 48%" if condition<.48 else "Repair needed" if condition<.75 else "Sound",condition<.75,"Condition limits the town's civic and work-building effects."))
	var capacities:Dictionary=WorldSimulation.settlements.city_capacities()
	var workshop:=float(capacities.get("workshop_function",0));var storage:=float(capacities.get("storage_function",0))
	var work:=pair("Workshops","Workshops","workshop","Current",workshop*100,"Maximum",100,"function index / 100","",false,"Combined development, staffing and condition. This is not factory utilization. Contributions are before other multipliers and shared limits.")
	work.effects=[{"label":"Tools & materials target","value":"+%.2f pts"%(workshop*12)},{"label":"Construction output","value":"+%.2f%%"%(workshop*10)}];rows.append(work)
	var stores:=pair("Stores","Stores & hauling","yard","Current",storage*100,"Maximum",100,"function index / 100","",false,"Combined development, carrier staffing and condition. This is not storage occupancy. Contribution is before other terms and limits.")
	stores.effects=[{"label":"Logistics target","value":"+%.2f pts"%(storage*10)}];rows.append(stores)
	var mc=WorldSimulation.military
	if mc!=null:
		var defense:Dictionary=mc.settlement_defense_snapshot()
		if int(defense.get("stage",0))>0:
			var tile:=pair("Defences","Built defenses","shield","Open ground",0,"Fortification",float(defense.get("defense_bonus",0))*100,"% defending bonus")
			tile.effects=[{"label":"Raid warning range","value":"%.1f km"%float(defense.get("observation_radius_km",0))},{"label":"Stores protected","value":"%.1f%%"%(float(defense.get("store_protection",0))*100)}];rows.append(tile)
	return rows
static func homes()->Array:
	var h:=Impact.homes();var values:Dictionary=h.numeric
	var rows:Array=[]
	for spec:Array in [["WorkPace","Work pace","builders",values.work,1.8],["Health","Health","health",values.health,2.4],["Cohesion","Cohesion","watchers",values.cohesion,2.25]]:
		rows.append(pair(spec[0],spec[1],spec[2],"No shelter",spec[4],"Current shelter",spec[3],"target contribution · points","",false,"The shelter term in this target, before other modifiers and shared caps. Not the total delivered outcome."))
	for spec:Array in [["Mortality","Age & weakness deaths","death",values.death],["Births","Conceptions","birth",values.births],["Outbreaks","Sickness outbreaks","sickness",values.sickness],["Fire","Fire starts","fire",values.fire]]:
		var amount:=float(spec[3]);var harm:=amount>1.0 if spec[0]!="Births" else amount<1.0
		var pct:=(amount-1)*100
		rows.append(pair(spec[0],spec[1],spec[2],"Roomy homes" if spec[0] in ["Outbreaks","Fire"] else "Neutral",1,"Current housing",amount,"× frequency",("%.1f%% more"%pct) if pct>=0 else ("%.1f%% fewer"%-pct),harm,"Housing contribution only. Deaths/conceptions use the engine's neutral factor; sickness and fire compare with homes 55% full. Other causes still apply."))
	rows.append(pair("Newcomers","Room for newcomers","homes","Entry minimum",2,"Spare places",h.spare,"places","Room available" if h.spare>=2 else "No room",h.spare<2))
	if values.childbirth>0:rows.append(pair("Childbirth","Childbirth danger","birth","Extra risk",0,"Current crowding",values.childbirth,"% extra danger","Overcrowded",true))
	if values.exposure>0:rows.append(pair("Exposure","Exposure deaths","health","With shelter",0,"Current estimate",values.exposure,"people / year","Shelter shortage",true,"Estimated exposure deaths at current crowding; weather can worsen them."))
	return rows
