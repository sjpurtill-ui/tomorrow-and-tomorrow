extends Node

const POPULATION_ROLES := ["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
const GIVEN_NAMES := ["Asha","Tarek","Lin","Mara","Ilyan","Veya","Cassian","Rovan","Daman","Oren","Sela","Nuri","Amara","Keon","Thalia","Zuri","Arin","Sen","Tala","Brann","Elian","Nima","Soren","Kavi","Yara","Idris","Liora","Mateo","Anik","Rhea","Dara","Mael","Nyla","Soraya","Bao","Edda","Jalen","Kira","Samir","Ayla","Toma","Eshe","Ravi","Mina","Noor","Pavel","Sana","Tavi"]
const FAMILY_NAMES := ["Avel","Kest","Varo","Merek","Orin","Vale","Arden","Saye","Navar","Talen","Iven","Halden","Mora","Koro","Vey","Saren","Olan","Rami","Kel","Hara","Tor","Linn","Aster","Nerin","Pavo","Eren","Zaman","Duru","Sorin","Kade","Aru","Maro","Tir","Naven","Belen","Caro"]

var world_seed := 0
var founding_banner_index := -1
var active_province := -1
var province_name := ""
var province_terrain := "Plains"
var province_mask: Image
var province_aspect := 1.0
var elapsed_days := 0.0
var founding_leader: Dictionary = {}
var leadership_positions: Dictionary = {}
var advisor_roster: Array[Dictionary] = []
var council_inbox: Array[Dictionary] = []
var sovereign_orders: Array[Dictionary] = []
var research_allocations := {"demography":0,"nutrition":1,"health":1,"labor":0,"knowledge":1,"production":0,"infrastructure":0,"logistics":0,"ecology":1,"institutions":0,"security":0,"culture":0}
var research_subcategory_allocations:Dictionary={
	"demography":{"Fertility conditions":0,"Maternal safety":0,"Child survival":0,"Shelter capacity":0},
	"nutrition":{"Daily supply":1,"Diet quality":0,"Stored reserve":0,"Land productivity":0},
	"health":{"General health":0,"Water & sanitation":0,"Disease control":0,"Injury safety":1},
	"labor":{"Able workforce":0,"Work efficiency":0,"Coordination":0,"Workload balance":0},
	"knowledge":{"Observers":0,"Directed attention":0,"Preserved knowledge":1,"Communication":0},
	"production":{"Material supply":0,"Tool quality":0,"Craft capacity":0,"Standardization":0},
	"infrastructure":{"Housing":0,"Construction":0,"Public works":0,"Resilience":0},
	"logistics":{"Carrying capacity":0,"Route quality":0,"Storage system":0,"Trade reach":0},
	"ecology":{"Land health":1,"Natural recovery":0,"Pollution control":0,"Resource sustainability":0},
	"institutions":{"Administration":0,"Legitimacy":0,"State capacity":0,"Institutional flexibility":0},
	"security":{"Public safety":0,"Organized defense":0,"Military readiness":0,"Crisis resilience":0},
	"culture":{"Social cohesion":0,"Shared legitimacy":0,"Inquiry breadth":0,"Collective memory":0}
}
var known_discoveries: Array[String] = []
var discovery_adoption: Dictionary = {}
var knowledge_effects: Dictionary = {}
var society_capacities: Dictionary = {"demography":0.5,"nutrition":0.5,"health":0.5,"labor":0.5,"knowledge":0.18,"production":0.12,"infrastructure":0.05,"logistics":0.16,"ecology":0.88,"institutions":0.25,"security":0.38,"culture":0.58}
var society_subcategories:Dictionary={}
var combined_intelligence:=0.18
var discovery_log: Array[Dictionary] = []
var active_observations: Array[String] = []
var active_investigations:Dictionary={}
var discovery_progress:Dictionary={}
var population_allocations := {"Food": 30, "Survey": 6, "Extraction": 8, "Construction": 8, "Crafting": 5, "Logistics": 5, "Knowledge": 4, "Administration": 3, "Defense": 3}
var population_allocation_percentages := {"Food":42.0,"Survey":8.0,"Extraction":11.0,"Construction":11.0,"Crafting":7.0,"Logistics":7.0,"Knowledge":6.0,"Administration":4.0,"Defense":4.0}
var population_allocation_auto := true
var population_total := 120
var population_exact := 120.0
var population_health := 0.72
var food_security := 0.82
var housing_capacity := 150
var housing_progress := 0.0
var settlement_projects: Dictionary = {}
var settlement_completed: Array[String] = []
var settlement_site_committed := false
var settlement_founded_at := Vector3.ZERO
var settlement_name := ""
var settlement_founded_day := -1
var settlement_plots:Array[Dictionary]=[]
var settlement_nuclei:Array[Dictionary]=[]
var settlement_routes:Array[Dictionary]=[]
var settlement_morphology:Dictionary={}
var settlement_plot_history:Array[Dictionary]=[]
var next_settlement_plot_id:=1
var next_settlement_nucleus_id:=1
var morphology_revision:=0
var last_morphology_day:=-1
var resource_deposits: Array[Dictionary] = []
var resource_stockpiles: Dictionary = {}
var resource_events: Array[Dictionary] = []
var resource_practice: Dictionary = {}
var resource_priorities: Dictionary = {}
var founding_manifest:Dictionary={}
var economy_stage := "subsistence"
var economy_benchmarks:Dictionary={"subsistence":{"day":0,"from":"founding"}}
var market_prices:Dictionary={}
var economy_metrics:Dictionary={}
var economy_history:Array[Dictionary]=[]
var economy_events:Array[Dictionary]=[]
var economy_known_goods:Dictionary={}
var currency_supply:=0.0
var public_treasury:=0.0
var private_currency:=0.0
var currency_hoards:=0.0
var mutual_aid_reserve:=0.0
var weighed_metal_circulation:=0.0
var weighed_metal_composition:Dictionary={}
var weighed_metal_losses:=0.0
var monetary_reserve_metals:Dictionary={}
var currency_issued:=0.0
var currency_retired:=0.0
var currency_demand:=0.0
var civil_arrears:=0.0
var military_arrears:=0.0
var in_kind_labor_arrears:=0.0
var in_kind_material_arrears:=0.0
var public_debt:=0.0
var public_borrowed:=0.0
var public_debt_repaid:=0.0
var public_interest_accrued:=0.0
var credit_outstanding:=0.0
var credit_defaulted:=0.0
var wealth_shares:Array[float]=[0.08,0.13,0.19,0.25,0.35]
var economic_ledger:Array[Dictionary]=[]
var tax_rate:=0.06
var external_trade_policy:="balanced"
var public_spending_priority:="balanced"
var external_trade_credit:=0.0
var external_trade_exports:=0.0
var external_trade_imports:=0.0
var external_trade_losses:=0.0
var material_metrics: Dictionary = {
	"extracted_today":0.0,"delivered_today":0.0,"lost_today":0.0,
	"at_source":0.0,"in_transit":0.0,"stored_bulk":0.0,"storage_capacity":0.0,
	"flow_ratio":0.0
}
var material_history: Array[Dictionary] = []
var water_metrics: Dictionary = {"stored":0.0,"capacity":0.0,"collected_today":0.0,"required_today":0.0,"consumed_today":0.0,"intake_ratio":0.0,"days":0.0,"source_accessible":false}
var water_history: Array[Dictionary] = []
var food_stocks: Dictionary = {}
var food_source_health := {"Wild gathering":0.92,"Hunting":0.88,"Fishing":0.90,"Cultivation":0.94}
var food_history: Array[Dictionary] = []
var nutrition_reserve := 0.90
var malnutrition_burden := 0.0

# The generative layer proposes a campaign mandate and bounded pressures. The
# deterministic simulation owns every numerical outcome.
var campaign_goal: Dictionary = {}
var campaign_goal_source := ""
var campaign_goal_status := "generating"
var active_modifiers: Array[Dictionary] = []
var simulation_metrics := {
	"food_days":30.0,
	"food_balance":-1.0,
	"health":0.72,
	"labor_efficiency":0.72,
	"cohesion":0.58,
	"knowledge":0.18,
	"material_capacity":0.12,
	"logistics":0.16,
	"security":0.38,
	"ecology":0.88,
	"legitimacy":0.62,
	"resource_access":0.0,
	"settlement":0.0
}
var simulation_trends: Dictionary = {}
var simulation_events: Array[Dictionary] = []
var last_simulation_event_days: Dictionary = {}
var demographic_ledger: Array[Dictionary] = []
var lifetime_births := 0
var lifetime_deaths := 0
var death_progress := 0.0
var consecutive_food_shortage_days := 0.0
var consecutive_water_shortage_days := 0.0
var convoy_traveling := false
var convoy_exposure_days := 0.0
var convoy_emergency_halt_reason := ""
var citizen_registry: Array[Dictionary] = []
var citizen_registry_initialized := false
var next_citizen_id := 1
var used_person_names: Dictionary = {}
var pregnancy_registry: Array[Dictionary] = []
var next_pregnancy_id := 1
var next_household_id := 1
var lifetime_conceptions := 0
var lifetime_pregnancy_losses := 0
var lifetime_stillbirths := 0
var lifetime_maternal_deaths := 0
var lifetime_neonatal_deaths := 0
var lifetime_partnerships := 0

func reset_for_new_world(new_seed:int)->void:
	world_seed=new_seed
	founding_banner_index=-1
	active_province=-1
	province_name=""
	province_terrain="Plains"
	province_mask=null
	province_aspect=1.0
	elapsed_days=0.0
	founding_leader={}
	leadership_positions={}
	advisor_roster=[]
	council_inbox=[]
	sovereign_orders=[]
	research_allocations={"demography":0,"nutrition":1,"health":1,"labor":0,"knowledge":1,"production":0,"infrastructure":0,"logistics":0,"ecology":1,"institutions":0,"security":0,"culture":0}
	research_subcategory_allocations={
		"demography":{"Fertility conditions":0,"Maternal safety":0,"Child survival":0,"Shelter capacity":0},"nutrition":{"Daily supply":1,"Diet quality":0,"Stored reserve":0,"Land productivity":0},
		"health":{"General health":0,"Water & sanitation":0,"Disease control":0,"Injury safety":1},"labor":{"Able workforce":0,"Work efficiency":0,"Coordination":0,"Workload balance":0},
		"knowledge":{"Observers":0,"Directed attention":0,"Preserved knowledge":1,"Communication":0},"production":{"Material supply":0,"Tool quality":0,"Craft capacity":0,"Standardization":0},
		"infrastructure":{"Housing":0,"Construction":0,"Public works":0,"Resilience":0},"logistics":{"Carrying capacity":0,"Route quality":0,"Storage system":0,"Trade reach":0},
		"ecology":{"Land health":1,"Natural recovery":0,"Pollution control":0,"Resource sustainability":0},"institutions":{"Administration":0,"Legitimacy":0,"State capacity":0,"Institutional flexibility":0},
		"security":{"Public safety":0,"Organized defense":0,"Military readiness":0,"Crisis resilience":0},"culture":{"Social cohesion":0,"Shared legitimacy":0,"Inquiry breadth":0,"Collective memory":0}
	}
	known_discoveries=[]
	discovery_adoption={}
	knowledge_effects={}
	society_capacities={"demography":0.5,"nutrition":0.5,"health":0.5,"labor":0.5,"knowledge":0.18,"production":0.12,"infrastructure":0.05,"logistics":0.16,"ecology":0.88,"institutions":0.25,"security":0.38,"culture":0.58}
	society_subcategories={}
	combined_intelligence=0.18
	discovery_log=[]
	active_observations=[]
	active_investigations={}
	discovery_progress={}
	population_allocations={"Food":30,"Survey":6,"Extraction":8,"Construction":8,"Crafting":5,"Logistics":5,"Knowledge":4,"Administration":3,"Defense":3}
	population_allocation_percentages={"Food":42.0,"Survey":8.0,"Extraction":11.0,"Construction":11.0,"Crafting":7.0,"Logistics":7.0,"Knowledge":6.0,"Administration":4.0,"Defense":4.0}
	population_allocation_auto=true
	population_total=120
	population_exact=120.0
	population_health=0.72
	food_security=0.82
	housing_capacity=150
	housing_progress=0.0
	settlement_projects={}
	settlement_completed=[]
	settlement_site_committed=false
	settlement_founded_at=Vector3.ZERO
	settlement_name=""
	settlement_founded_day=-1
	settlement_plots=[]
	settlement_nuclei=[]
	settlement_routes=[]
	settlement_morphology={}
	settlement_plot_history=[]
	next_settlement_plot_id=1
	next_settlement_nucleus_id=1
	morphology_revision=0
	last_morphology_day=-1
	resource_deposits=[]
	resource_stockpiles={}
	resource_events=[]
	resource_practice={}
	resource_priorities={}
	founding_manifest={}
	economy_stage="subsistence"
	economy_benchmarks={"subsistence":{"day":0,"from":"founding"}}
	market_prices={}
	economy_metrics={}
	economy_history=[]
	economy_events=[]
	economy_known_goods={}
	currency_supply=0.0
	public_treasury=0.0
	private_currency=0.0
	currency_hoards=0.0
	mutual_aid_reserve=0.0
	weighed_metal_circulation=0.0
	weighed_metal_composition={}
	weighed_metal_losses=0.0
	monetary_reserve_metals={}
	currency_issued=0.0
	currency_retired=0.0
	currency_demand=0.0
	civil_arrears=0.0
	military_arrears=0.0
	in_kind_labor_arrears=0.0
	in_kind_material_arrears=0.0
	public_debt=0.0
	public_borrowed=0.0
	public_debt_repaid=0.0
	public_interest_accrued=0.0
	credit_outstanding=0.0
	credit_defaulted=0.0
	wealth_shares=[0.08,0.13,0.19,0.25,0.35]
	economic_ledger=[]
	tax_rate=0.06
	external_trade_policy="balanced"
	public_spending_priority="balanced"
	external_trade_credit=0.0
	external_trade_exports=0.0
	external_trade_imports=0.0
	external_trade_losses=0.0
	material_metrics={"extracted_today":0.0,"delivered_today":0.0,"lost_today":0.0,"at_source":0.0,"in_transit":0.0,"stored_bulk":0.0,"storage_capacity":0.0,"flow_ratio":0.0}
	material_history=[]
	water_metrics={"stored":0.0,"capacity":0.0,"collected_today":0.0,"required_today":0.0,"consumed_today":0.0,"intake_ratio":0.0,"days":0.0,"source_accessible":false}
	water_history=[]
	food_stocks={}
	food_source_health={"Wild gathering":0.92,"Hunting":0.88,"Fishing":0.90,"Cultivation":0.94}
	food_history=[]
	nutrition_reserve=0.90
	malnutrition_burden=0.0
	campaign_goal={}
	campaign_goal_source=""
	campaign_goal_status="generating"
	active_modifiers=[]
	simulation_metrics={"food_days":30.0,"food_balance":-1.0,"health":0.72,"labor_efficiency":0.72,"cohesion":0.58,"knowledge":0.18,"material_capacity":0.12,"logistics":0.16,"security":0.38,"ecology":0.88,"legitimacy":0.62,"resource_access":0.0,"settlement":0.0}
	simulation_trends={}
	simulation_events=[]
	last_simulation_event_days={}
	demographic_ledger=[]
	lifetime_births=0
	lifetime_deaths=0
	death_progress=0.0
	consecutive_food_shortage_days=0.0
	consecutive_water_shortage_days=0.0
	convoy_traveling=false
	convoy_exposure_days=0.0
	convoy_emergency_halt_reason=""
	citizen_registry=[]
	citizen_registry_initialized=false
	next_citizen_id=1
	used_person_names={}
	pregnancy_registry=[]
	next_pregnancy_id=1
	next_household_id=1
	lifetime_conceptions=0
	lifetime_pregnancy_losses=0
	lifetime_stillbirths=0
	lifetime_maternal_deaths=0
	lifetime_neonatal_deaths=0
	lifetime_partnerships=0

func initialize_citizen_registry() -> void:
	if citizen_registry_initialized:
		return
	citizen_registry_initialized=true
	var rng:=RandomNumberGenerator.new()
	rng.seed=world_seed^0x5f3759df
	var target:=maxi(1,population_total)
	var children:=roundi(target*0.32)
	var elders:=roundi(target*0.08)
	var working:=maxi(0,target-children-elders)
	var founder_index:=0
	for i in children:
		citizen_registry.append(_create_citizen(rng,rng.randi_range(0,13),"Founder","Female" if founder_index%2==0 else "Male"))
		founder_index+=1
	for i in working:
		citizen_registry.append(_create_citizen(rng,rng.randi_range(14,59),"Founder","Female" if founder_index%2==0 else "Male"))
		founder_index+=1
	for i in elders:
		citizen_registry.append(_create_citizen(rng,rng.randi_range(60,76),"Founder","Female" if founder_index%2==0 else "Male"))
		founder_index+=1
	_form_founding_households(rng)
	_seed_founding_pregnancies(rng)
	population_total=living_citizen_count()
	population_exact=float(population_total)
	synchronize_population_allocations()

func _create_citizen(rng: RandomNumberGenerator,age_years: int,origin: String,sex_override:="") -> Dictionary:
	var full_name:=_unique_person_name(rng)
	var age_days:=maxi(0,age_years*365+rng.randi_range(0,364))
	var sex:=sex_override if sex_override!="" else ("Female" if rng.randf()<0.495 else "Male")
	var strength:=_citizen_trait(rng,0.66,0.14)
	var endurance:=_citizen_trait(rng,0.67,0.13)
	var agility:=_citizen_trait(rng,0.65,0.15)
	var awareness:=_citizen_trait(rng,0.64,0.14)
	var composure:=_citizen_trait(rng,0.62,0.16)
	var person:={
		"id":next_citizen_id,"name":full_name,"birth_day":int(elapsed_days)-age_days,
		"alive":true,"role":"Unassigned","role_since_day":int(elapsed_days),
		"origin":origin,"sex":sex,"aptitude_seed":rng.randi(),"death_day":-1,"death_cause":"",
		"household_id":-1,"partner_id":-1,"partnership_available_day":-1,"mother_id":-1,"father_id":-1,"children_ids":[],
		"current_pregnancy_id":-1,"last_birth_day":-100000,"postpartum_until_day":-1,
		"reproductive_health":rng.randf_range(0.82,1.12),
		"strength":strength,"endurance":endurance,"agility":agility,
		"awareness":awareness,"composure":composure,
		"health_condition":clampf(population_health+rng.randfn(0.0,0.055),0.25,1.0),
		"nutrition_condition":clampf(food_security+rng.randfn(0.0,0.05),0.20,1.0),
		"fatigue":clampf(rng.randfn(0.08,0.035),0.0,0.25),
		"history":[{"day":int(elapsed_days),"event":"Joined the population as a %s." % origin.to_lower()}]
	}
	next_citizen_id+=1
	return person

func _citizen_trait(rng: RandomNumberGenerator,mean: float,deviation: float) -> float:
	return clampf(rng.randfn(mean,deviation),0.25,1.0)

func citizen_age_fitness(person: Dictionary) -> float:
	var age:=citizen_age_years(person)
	if age<14: return 0.0
	if age<18: return lerpf(0.48,0.72,float(age-14)/4.0)
	if age<30: return 1.0
	if age<40: return lerpf(1.0,0.92,float(age-30)/10.0)
	if age<50: return lerpf(0.92,0.76,float(age-40)/10.0)
	if age<60: return lerpf(0.76,0.56,float(age-50)/10.0)
	return clampf(0.48-float(age-60)*0.012,0.18,0.48)

func citizen_physical_capacity(person: Dictionary) -> float:
	if not bool(person.get("alive",true)): return 0.0
	var base:=(float(person.get("strength",0.5))*0.38+float(person.get("endurance",0.5))*0.37+float(person.get("agility",0.5))*0.25)
	var health:=clampf(float(person.get("health_condition",population_health)),0.0,1.0)
	var nutrition:=clampf(float(person.get("nutrition_condition",food_security)),0.0,1.0)
	var fatigue:=clampf(float(person.get("fatigue",0.0)),0.0,1.0)
	return clampf(citizen_age_fitness(person)*base*health*nutrition*(1.0-fatigue*0.65),0.0,1.0)

func citizen_condition_profile(citizens: Array) -> Dictionary:
	var bands: Array[Dictionary] = [
		{"id":"ready","label":"Ready","count":0,"color":"#5f9f73"},
		{"id":"capable","label":"Capable","count":0,"color":"#a4a85c"},
		{"id":"strained","label":"Strained","count":0,"color":"#c68b4f"},
		{"id":"unfit","label":"Unfit","count":0,"color":"#a8514d"}
	]
	var total:=0
	var capacity_total:=0.0
	for person in citizens:
		if not bool(person.get("alive",true)): continue
		var capacity:=citizen_physical_capacity(person)
		capacity_total+=capacity
		total+=1
		if capacity>=0.72: bands[0].count=int(bands[0].count)+1
		elif capacity>=0.50: bands[1].count=int(bands[1].count)+1
		elif capacity>=0.30: bands[2].count=int(bands[2].count)+1
		else: bands[3].count=int(bands[3].count)+1
	for band in bands:
		band["share"]=float(band.count)/maxf(1.0,float(total))
	return {"total":total,"average_capacity":capacity_total/maxf(1.0,float(total)),"bands":bands}

func _shuffle_demographic_array(values: Array[Dictionary],rng: RandomNumberGenerator) -> void:
	for i in range(values.size()-1,0,-1):
		var swap_index:=rng.randi_range(0,i)
		var held:=values[i]
		values[i]=values[swap_index]
		values[swap_index]=held

func _new_household() -> int:
	var household:=next_household_id
	next_household_id+=1
	return household

func _append_child_to_parent(parent: Dictionary,child_id: int) -> void:
	if parent.is_empty():
		return
	var children:Array=parent.get("children_ids",[])
	if child_id not in children:
		children.append(child_id)
	parent["children_ids"]=children

func _form_founding_households(rng: RandomNumberGenerator) -> void:
	var women:Array[Dictionary]=[]
	var men:Array[Dictionary]=[]
	var children:Array[Dictionary]=[]
	var elders:Array[Dictionary]=[]
	for person in citizen_registry:
		var age:=citizen_age_years(person)
		if age<14:
			children.append(person)
		elif age>=60:
			elders.append(person)
		elif String(person.get("sex",""))=="Female" and age>=17 and age<=49:
			women.append(person)
		elif String(person.get("sex",""))=="Male" and age>=17 and age<=59:
			men.append(person)
	_shuffle_demographic_array(women,rng)
	_shuffle_demographic_array(men,rng)
	var couples:Array[Dictionary]=[]
	var pair_count:=mini(women.size(),men.size())
	for index in pair_count:
		var mother:=women[index]
		var father:=men[index]
		var household:=_new_household()
		mother["partner_id"]=int(father.id)
		father["partner_id"]=int(mother.id)
		mother["household_id"]=household
		father["household_id"]=household
		mother.history.append({"day":int(elapsed_days),"event":"Entered the founding record as the partner of %s." % father.name})
		father.history.append({"day":int(elapsed_days),"event":"Entered the founding record as the partner of %s." % mother.name})
		couples.append({"mother":mother,"father":father,"household_id":household,"children":0})
		lifetime_partnerships+=1
	for person in citizen_registry:
		if int(person.get("household_id",-1))<0 and citizen_age_years(person)>=14:
			person["household_id"]=_new_household()
	_shuffle_demographic_array(children,rng)
	for child in children:
		var child_age:=citizen_age_years(child)
		var best_index:=-1
		var best_load:=100000
		for index in couples.size():
			var couple:Dictionary=couples[index]
			var mother:Dictionary=couple.mother
			var father:Dictionary=couple.father
			if citizen_age_years(mother)<child_age+16 or citizen_age_years(father)<child_age+16:
				continue
			var load:=int(couple.children)*10+rng.randi_range(0,4)
			if load<best_load:
				best_load=load
				best_index=index
		if best_index<0:
			child["household_id"]=_new_household()
			continue
		var chosen:Dictionary=couples[best_index]
		var mother:Dictionary=chosen.mother
		var father:Dictionary=chosen.father
		child["household_id"]=int(chosen.household_id)
		child["mother_id"]=int(mother.id)
		child["father_id"]=int(father.id)
		_append_child_to_parent(mother,int(child.id))
		_append_child_to_parent(father,int(child.id))
		mother["last_birth_day"]=maxi(int(mother.get("last_birth_day",-100000)),int(child.birth_day))
		child.history.append({"day":int(elapsed_days),"event":"Founding household recorded with %s and %s as parents." % [mother.name,father.name]})
		chosen["children"]=int(chosen.children)+1
		couples[best_index]=chosen
	for elder in elders:
		if couples.is_empty():
			break
		var related:Dictionary=couples[rng.randi_range(0,couples.size()-1)]
		elder["household_id"]=int(related.household_id)
	var current_day:=int(elapsed_days)
	for mother in women:
		var last_birth:=int(mother.get("last_birth_day",-100000))
		if last_birth>current_day-730:
			mother["postpartum_until_day"]=last_birth+rng.randi_range(450,700)

func _seed_founding_pregnancies(rng: RandomNumberGenerator) -> void:
	var candidates:=eligible_gestational_parents()
	_shuffle_demographic_array(candidates,rng)
	var target:=clampi(roundi(float(candidates.size())*0.11),1,3) if not candidates.is_empty() else 0
	for index in target:
		var mother:Dictionary=candidates[index]
		var father_id:=int(mother.get("partner_id",-1))
		var gestational_age:=rng.randi_range(28,245)
		var conception_day:=int(elapsed_days)-gestational_age
		var due_day:=maxi(int(elapsed_days)+14,conception_day+clampi(roundi(rng.randfn(280.0,9.0)),252,300))
		create_pregnancy(int(mother.id),father_id,conception_day,due_day,"Founding pregnancy")

func _ancestor_ids(person: Dictionary,depth: int) -> Dictionary:
	var result:Dictionary={}
	if person.is_empty() or depth<=0:
		return result
	for key in ["mother_id","father_id"]:
		var parent_id:=int(person.get(key,-1))
		if parent_id<0:
			continue
		result[parent_id]=true
		var parent:=citizen_by_id(parent_id)
		for ancestor_id in _ancestor_ids(parent,depth-1):
			result[ancestor_id]=true
	return result

func _are_close_relatives(first: Dictionary,second: Dictionary) -> bool:
	if first.is_empty() or second.is_empty():
		return false
	var first_id:=int(first.get("id",-1))
	var second_id:=int(second.get("id",-1))
	var first_ancestors:=_ancestor_ids(first,2)
	var second_ancestors:=_ancestor_ids(second,2)
	if first_ancestors.has(second_id) or second_ancestors.has(first_id):
		return true
	for ancestor_id in first_ancestors:
		if second_ancestors.has(ancestor_id):
			return true
	return false

func form_new_partnerships(rng: RandomNumberGenerator) -> int:
	var day:=int(elapsed_days)
	var women:Array[Dictionary]=[]
	var men:Array[Dictionary]=[]
	for person in citizen_registry:
		if not bool(person.get("alive",true)) or int(person.get("partner_id",-1))>=0 or day<int(person.get("partnership_available_day",-1)):
			continue
		var age:=citizen_age_years(person)
		if String(person.get("sex",""))=="Female" and age>=17 and age<=49:
			women.append(person)
		elif String(person.get("sex",""))=="Male" and age>=17 and age<=59:
			men.append(person)
	_shuffle_demographic_array(women,rng)
	_shuffle_demographic_array(men,rng)
	var paired_men:Dictionary={}
	var formed:=0
	for woman in women:
		var best_man:Dictionary={}
		var best_score:=INF
		for man in men:
			if paired_men.has(int(man.id)) or _are_close_relatives(woman,man):
				continue
			var score:=absf(float(citizen_age_years(woman)-citizen_age_years(man)))+rng.randf_range(0.0,5.0)
			if score<best_score:
				best_score=score
				best_man=man
		if best_man.is_empty():
			continue
		paired_men[int(best_man.id)]=true
		var household:=_new_household()
		woman["partner_id"]=int(best_man.id)
		best_man["partner_id"]=int(woman.id)
		woman["household_id"]=household
		best_man["household_id"]=household
		for child_id in woman.get("children_ids",[]):
			var child:=citizen_by_id(int(child_id))
			if not child.is_empty() and bool(child.get("alive",true)) and citizen_age_years(child)<14: child["household_id"]=household
		for child_id in best_man.get("children_ids",[]):
			var child:=citizen_by_id(int(child_id))
			if not child.is_empty() and bool(child.get("alive",true)) and citizen_age_years(child)<14: child["household_id"]=household
		var woman_history:Array=woman.get("history",[])
		woman_history.append({"day":day,"event":"Formed a household partnership with %s." % best_man.name})
		woman["history"]=woman_history
		var man_history:Array=best_man.get("history",[])
		man_history.append({"day":day,"event":"Formed a household partnership with %s." % woman.name})
		best_man["history"]=man_history
		formed+=1
	lifetime_partnerships+=formed
	return formed

func _dissolve_partnership_after_death(person: Dictionary) -> void:
	var partner:=citizen_by_id(int(person.get("partner_id",-1)))
	if not partner.is_empty() and bool(partner.get("alive",true)):
		partner["partner_id"]=-1
		partner["partnership_available_day"]=int(elapsed_days)+180+abs(int(person.get("id",0))*37+int(partner.get("id",0))*19)%361
		var history:Array=partner.get("history",[])
		history.append({"day":int(elapsed_days),"event":"Partner %s died; the household entered mourning." % person.name})
		partner["history"]=history
	person["partner_id"]=-1

func _unique_person_name(rng: RandomNumberGenerator) -> String:
	for attempt in 800:
		var given:=String(GIVEN_NAMES[rng.randi_range(0,GIVEN_NAMES.size()-1)])
		var family:=String(FAMILY_NAMES[rng.randi_range(0,FAMILY_NAMES.size()-1)])
		var full_name:="%s %s" % [given,family]
		if not used_person_names.has(full_name):
			used_person_names[full_name]=true
			return full_name
	var fallback:="Citizen %d" % next_citizen_id
	used_person_names[fallback]=true
	return fallback

func citizen_age_days(person: Dictionary) -> int:
	var reference_day:=int(person.get("death_day",-1)) if not bool(person.get("alive",true)) else int(elapsed_days)
	if reference_day<0: reference_day=int(elapsed_days)
	return maxi(0,reference_day-int(person.get("birth_day",reference_day)))

func citizen_age_years(person: Dictionary) -> int:
	return citizen_age_days(person)/365

func citizen_life_stage(person: Dictionary) -> String:
	if not bool(person.get("alive",true)): return "Deceased"
	var age:=citizen_age_years(person)
	if age<3: return "Infant"
	if age<14: return "Child"
	if age<60: return "Working age"
	if age<75: return "Elder"
	return "Old age"

func living_citizen_count() -> int:
	var count:=0
	for person in citizen_registry:
		if bool(person.get("alive",true)): count+=1
	return count

func living_citizens() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for person in citizen_registry:
		if bool(person.get("alive",true)): result.append(person)
	return result

func citizen_by_id(person_id: int) -> Dictionary:
	for person in citizen_registry:
		if int(person.get("id",-1))==person_id: return person
	return {}

func active_pregnancies() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for pregnancy in pregnancy_registry:
		if String(pregnancy.get("status",""))=="ongoing":
			result.append(pregnancy)
	return result

func pregnancy_by_id(pregnancy_id: int) -> Dictionary:
	for pregnancy in pregnancy_registry:
		if int(pregnancy.get("id",-1))==pregnancy_id:
			return pregnancy
	return {}

func eligible_gestational_parents(ignore_postpartum:=false) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var day:=int(elapsed_days)
	for person in citizen_registry:
		if not bool(person.get("alive",true)) or String(person.get("sex",""))!="Female":
			continue
		var age:=citizen_age_years(person)
		if age<15 or age>49:
			continue
		if int(person.get("partner_id",-1))<0 or int(person.get("current_pregnancy_id",-1))>=0:
			continue
		var partner:=citizen_by_id(int(person.partner_id))
		if partner.is_empty() or not bool(partner.get("alive",true)):
			continue
		if not ignore_postpartum and day<int(person.get("postpartum_until_day",-1)):
			continue
		result.append(person)
	return result

func age_specific_conception_rate(age: int) -> float:
	if age<15 or age>49: return 0.0
	if age<=17: return 0.07
	if age<=19: return 0.18
	if age<=24: return 0.30
	if age<=29: return 0.31
	if age<=34: return 0.26
	if age<=39: return 0.17
	if age<=44: return 0.065
	return 0.012

func create_pregnancy(mother_id: int,father_id: int,conception_day: int,due_day: int,origin:="Conception") -> Dictionary:
	var mother:=citizen_by_id(mother_id)
	if mother.is_empty() or not bool(mother.get("alive",true)) or int(mother.get("current_pregnancy_id",-1))>=0:
		return {}
	var pregnancy:={
		"id":next_pregnancy_id,"mother_id":mother_id,"father_id":father_id,
		"conception_day":conception_day,"due_day":maxi(conception_day+240,due_day),
		"status":"ongoing","outcome":"","end_day":-1,"child_id":-1,"origin":origin
	}
	next_pregnancy_id+=1
	pregnancy_registry.append(pregnancy)
	mother["current_pregnancy_id"]=int(pregnancy.id)
	var history:Array=mother.get("history",[])
	var history_text:="Arrived carrying a pregnancy." if origin=="Founding pregnancy" else "A pregnancy began."
	history.append({"day":maxi(int(elapsed_days),conception_day),"event":history_text})
	if history.size()>40: history.pop_front()
	mother["history"]=history
	lifetime_conceptions+=1
	return pregnancy

func _complete_pregnancy(pregnancy: Dictionary,outcome: String,recovery_days: int) -> void:
	pregnancy["status"]="completed"
	pregnancy["outcome"]=outcome
	pregnancy["end_day"]=int(elapsed_days)
	var mother:=citizen_by_id(int(pregnancy.get("mother_id",-1)))
	if mother.is_empty():
		return
	if int(mother.get("current_pregnancy_id",-1))==int(pregnancy.get("id",-1)):
		mother["current_pregnancy_id"]=-1
	mother["postpartum_until_day"]=maxi(int(mother.get("postpartum_until_day",-1)),int(elapsed_days)+recovery_days)
	var history:Array=mother.get("history",[])
	history.append({"day":int(elapsed_days),"event":"Pregnancy ended: %s." % outcome.to_lower()})
	if history.size()>40: history.pop_front()
	mother["history"]=history

func register_birth_from_pregnancy(pregnancy: Dictionary,rng: RandomNumberGenerator) -> Dictionary:
	var mother:=citizen_by_id(int(pregnancy.get("mother_id",-1)))
	var father:=citizen_by_id(int(pregnancy.get("father_id",-1)))
	if mother.is_empty() or not bool(mother.get("alive",true)):
		return {}
	var newborn:=_create_citizen(rng,0,"Born here")
	newborn["birth_day"]=int(elapsed_days)
	newborn["role"]="Infant"
	newborn["mother_id"]=int(mother.id)
	newborn["father_id"]=int(father.get("id",-1))
	newborn["household_id"]=int(mother.get("household_id",-1))
	var father_phrase:=String(father.get("name","an unrecorded parent"))
	newborn["history"]=[{"day":int(elapsed_days),"event":"Born to %s and %s." % [mother.name,father_phrase]}]
	citizen_registry.append(newborn)
	_append_child_to_parent(mother,int(newborn.id))
	_append_child_to_parent(father,int(newborn.id))
	mother["last_birth_day"]=int(elapsed_days)
	pregnancy["child_id"]=int(newborn.id)
	_complete_pregnancy(pregnancy,"Live birth",rng.randi_range(450,700))
	population_total=living_citizen_count()
	synchronize_population_allocations()
	return newborn

func register_specific_death(person_id: int,cause: String) -> String:
	var person:=citizen_by_id(person_id)
	if person.is_empty() or not bool(person.get("alive",true)):
		return ""
	var final_role:=String(person.get("role","Unassigned"))
	person["alive"]=false
	person["death_day"]=int(elapsed_days)
	person["death_cause"]=cause
	person["last_role"]=final_role
	person["role"]="Deceased"
	_dissolve_partnership_after_death(person)
	var history:Array=person.get("history",[])
	history.append({"day":int(elapsed_days),"event":"Died; attributed primarily to %s." % cause.to_lower()})
	person["history"]=history
	population_total=living_citizen_count()
	synchronize_population_allocations()
	return String(person.name)

func pregnancy_summary() -> Dictionary:
	var active:=active_pregnancies()
	var due_within_year:=0
	var first_trimester:=0
	var second_trimester:=0
	var third_trimester:=0
	var day:=int(elapsed_days)
	for pregnancy in active:
		if int(pregnancy.get("due_day",day))<=day+365: due_within_year+=1
		var gestation:=day-int(pregnancy.get("conception_day",day))
		if gestation<91: first_trimester+=1
		elif gestation<182: second_trimester+=1
		else: third_trimester+=1
	return {"active":active.size(),"due_within_year":due_within_year,"first_trimester":first_trimester,"second_trimester":second_trimester,"third_trimester":third_trimester,"eligible":eligible_gestational_parents().size()}

func _conception_condition_factor(person: Dictionary,context: Dictionary) -> float:
	var health:=clampf(float(context.get("health",population_health)),0.0,1.0)
	var food:=clampf(float(context.get("food_security",food_security)),0.0,1.0)
	var housing:=clampf(float(context.get("housing_ratio",0.5)),0.0,1.0)
	var cohesion:=clampf(float(context.get("cohesion",0.58)),0.0,1.0)
	var factor:=lerpf(0.12,1.08,health)*lerpf(0.10,1.05,food)*lerpf(0.55,1.03,housing)*lerpf(0.82,1.04,cohesion)
	if bool(context.get("traveling",false)):
		factor*=0.62
	var role:=String(person.get("role","Unassigned"))
	if role in ["Food","Extraction","Construction","Defense"]:
		factor*=0.84
	if bool(context.get("birth_crisis",false)):
		factor*=0.06
	factor*=1.0+clampf(float(context.get("conception_support",0.0)),-0.30,0.30)
	factor*=float(person.get("reproductive_health",1.0))
	return clampf(factor,0.0,1.30)

func _pregnancy_risk_multiplier(mother: Dictionary,context: Dictionary) -> float:
	var health:=clampf(float(context.get("health",population_health)),0.0,1.0)
	var food:=clampf(float(context.get("food_security",food_security)),0.0,1.0)
	var housing:=clampf(float(context.get("housing_ratio",0.5)),0.0,1.0)
	var age:=citizen_age_years(mother)
	var multiplier:=1.0+maxf(0.0,0.72-health)*3.2+maxf(0.0,0.58-food)*2.6+maxf(0.0,0.55-housing)*1.8
	if age<18: multiplier*=1.42
	elif age>=40: multiplier*=1.55
	elif age>=35: multiplier*=1.20
	if bool(context.get("traveling",false)): multiplier*=1.32
	multiplier*=1.0-clampf(float(context.get("maternal_safety",0.0)),0.0,0.60)
	return clampf(multiplier,0.72,5.0)

func process_reproduction_day(context: Dictionary) -> Dictionary:
	initialize_citizen_registry()
	var day:=int(elapsed_days)
	var rng:=RandomNumberGenerator.new()
	rng.seed=world_seed^(day*1103515245)^(next_pregnancy_id*7919)
	if day%30==0:
		form_new_partnerships(rng)
	var births:Array[Dictionary]=[]
	var deaths:Array[Dictionary]=[]
	var losses:Array[Dictionary]=[]
	var conceptions:Array[Dictionary]=[]
	for pregnancy in active_pregnancies():
		var mother:=citizen_by_id(int(pregnancy.get("mother_id",-1)))
		var gestation_days:=day-int(pregnancy.get("conception_day",day))
		if mother.is_empty() or not bool(mother.get("alive",true)):
			_complete_pregnancy(pregnancy,"Pregnancy lost with mother",90)
			lifetime_pregnancy_losses+=1
			losses.append({"mother":String(mother.get("name","Unknown")),"gestation_days":gestation_days,"reason":"Maternal death"})
			continue
		var risk_multiplier:=_pregnancy_risk_multiplier(mother,context)
		var daily_loss_chance:=0.00125 if gestation_days<84 else (0.00024 if gestation_days<168 else 0.000075)
		if rng.randf()<daily_loss_chance*risk_multiplier:
			_complete_pregnancy(pregnancy,"Pregnancy loss",rng.randi_range(60,150))
			lifetime_pregnancy_losses+=1
			losses.append({"mother":String(mother.name),"gestation_days":gestation_days,"reason":"Pregnancy loss under current conditions"})
			continue
		if day<int(pregnancy.get("due_day",day+1)):
			continue
		var stillbirth_chance:=clampf(0.018+(risk_multiplier-1.0)*0.018,0.010,0.14)
		if rng.randf()<stillbirth_chance:
			_complete_pregnancy(pregnancy,"Stillbirth",rng.randi_range(420,650))
			lifetime_stillbirths+=1
			losses.append({"mother":String(mother.name),"gestation_days":gestation_days,"reason":"Stillbirth"})
		else:
			var newborn:=register_birth_from_pregnancy(pregnancy,rng)
			if not newborn.is_empty():
				births.append(newborn)
				var neonatal_chance:=clampf((0.018+(risk_multiplier-1.0)*0.025)*(1.0-clampf(float(context.get("neonatal_survival",0.0)),0.0,0.60)),0.004,0.18)
				if rng.randf()<neonatal_chance:
					var neonatal_name:=register_specific_death(int(newborn.id),"Neonatal complications")
					if neonatal_name!="":
						lifetime_neonatal_deaths+=1
						deaths.append({"name":neonatal_name,"cause":"Neonatal complications"})
		var maternal_chance:=clampf((0.0045+(risk_multiplier-1.0)*0.0065)*(1.0-clampf(float(context.get("maternal_safety",0.0)),0.0,0.65)),0.0008,0.055)
		if rng.randf()<maternal_chance and bool(mother.get("alive",true)):
			var maternal_name:=register_specific_death(int(mother.id),"Complications of childbirth")
			if maternal_name!="":
				lifetime_maternal_deaths+=1
				deaths.append({"name":maternal_name,"cause":"Complications of childbirth"})
	var annual_conceptions_expected:=0.0
	for mother in eligible_gestational_parents():
		var annual_chance:=age_specific_conception_rate(citizen_age_years(mother))*_conception_condition_factor(mother,context)
		annual_conceptions_expected+=annual_chance
		if rng.randf()>=annual_chance/365.0:
			continue
		var gestation_length:=clampi(roundi(rng.randfn(280.0,9.0)),252,300)
		var pregnancy:=create_pregnancy(int(mother.id),int(mother.get("partner_id",-1)),day,day+gestation_length)
		if not pregnancy.is_empty():
			conceptions.append(pregnancy)
	population_total=living_citizen_count()
	population_exact=float(population_total)
	var active:=active_pregnancies()
	var expected_active_births:=0.0
	for pregnancy in active:
		if int(pregnancy.get("due_day",day+1000))<=day+365:
			expected_active_births+=0.88
	var projected_live_births:=annual_conceptions_expected*0.84
	# Only conceptions occurring in roughly the first 85 days of the coming year
	# can complete a mean 280-day gestation inside that same 12-month window.
	var new_conceptions_delivering_within_year:=projected_live_births*(85.0/365.0)
	return {
		"births":births,"deaths":deaths,"losses":losses,"conceptions":conceptions,
		"active_pregnancies":active.size(),"eligible_parents":eligible_gestational_parents().size(),
		"annual_conceptions_expected":annual_conceptions_expected,
		"projected_live_births":projected_live_births,
		"projected_birth_rate":projected_live_births/maxf(1.0,float(population_total)),
		"births_expected_next_year":expected_active_births+new_conceptions_delivering_within_year
	}

func age_distribution(bucket_years:=5,max_age:=85) -> Array[Dictionary]:
	var buckets:Array[Dictionary]=[]
	for start_age in range(0,max_age,bucket_years):
		buckets.append({"start":start_age,"end":start_age+bucket_years-1,"count":0})
	for person in citizen_registry:
		if not bool(person.get("alive",true)): continue
		var age:=citizen_age_years(person)
		var index:=mini(buckets.size()-1,age/bucket_years)
		buckets[index].count=int(buckets[index].count)+1
	return buckets

func population_age_profile() -> Dictionary:
	var bands:Array[Dictionary]=[
		{"label":"CHILDREN","range":"0–13","minimum":0,"maximum":13,"count":0},
		{"label":"YOUTH","range":"14–24","minimum":14,"maximum":24,"count":0},
		{"label":"EARLY ADULT","range":"25–34","minimum":25,"maximum":34,"count":0},
		{"label":"ESTABLISHED","range":"35–44","minimum":35,"maximum":44,"count":0},
		{"label":"MATURE","range":"45–59","minimum":45,"maximum":59,"count":0},
		{"label":"ELDERS","range":"60+","minimum":60,"maximum":1000,"count":0}
	]
	var ages:Array[int]=[]
	var working_age:=0
	var dependents:=0
	for person in citizen_registry:
		if not bool(person.get("alive",true)): continue
		var age:=citizen_age_years(person)
		ages.append(age)
		if age>=14 and age<60: working_age+=1
		else: dependents+=1
		for band in bands:
			if age>=int(band.minimum) and age<=int(band.maximum):
				band.count=int(band.count)+1
				break
	ages.sort()
	var total:=ages.size()
	var median_age:=0.0
	if total>0:
		if total%2==1: median_age=float(ages[total/2])
		else: median_age=(float(ages[total/2-1])+float(ages[total/2]))*0.5
	for band in bands:
		band["share"]=float(band.count)/maxf(1.0,float(total))
	var recorded_death_ages:Array[int]=[]
	for person in citizen_registry:
		if not bool(person.get("alive",true)) and int(person.get("death_day",-1))>=0:
			recorded_death_ages.append(citizen_age_years(person))
	var observed_age_at_death:=-1.0
	if not recorded_death_ages.is_empty():
		var death_age_total:=0
		for death_age in recorded_death_ages: death_age_total+=death_age
		observed_age_at_death=float(death_age_total)/float(recorded_death_ages.size())
	return {
		"bands":bands,
		"total":total,
		"median_age":median_age,
		"working_age":working_age,
		"dependents":dependents,
		"dependents_per_100_workers":100.0*float(dependents)/maxf(1.0,float(working_age)),
		"projected_life_expectancy":projected_life_expectancy(),
		"observed_age_at_death":observed_age_at_death,
		"recorded_deaths":recorded_death_ages.size()
	}

func projected_life_expectancy() -> float:
	# A period life table: the lifespan a newborn would expect if the current
	# food, health, shelter, and exceptional mortality pressures persisted.
	var health_factor:=lerpf(1.90,0.64,clampf(population_health,0.0,1.0))
	var food_factor:=lerpf(2.40,0.78,clampf(food_security,0.0,1.0))
	var housing_ratio:=clampf(float(housing_capacity)/maxf(1.0,population_exact),0.0,1.15)
	var shelter_factor:=lerpf(1.65,0.88,clampf(housing_ratio,0.0,1.0))
	var condition_factor:=health_factor*food_factor*shelter_factor
	var current_total_rate:=float(simulation_metrics.get("annual_death_rate",0.01))
	var exceptional_hazard:=maxf(0.0,current_total_rate-0.014)
	var survival:=1.0
	var expected_years:=0.0
	for age in 110:
		var baseline_hazard:=0.004
		if age==0: baseline_hazard=0.090
		elif age<5: baseline_hazard=0.025
		elif age<15: baseline_hazard=0.004
		elif age<25: baseline_hazard=0.006
		elif age<35: baseline_hazard=0.008
		elif age<45: baseline_hazard=0.012
		elif age<55: baseline_hazard=0.025
		elif age<65: baseline_hazard=0.055
		elif age<75: baseline_hazard=0.120
		elif age<85: baseline_hazard=0.230
		else: baseline_hazard=0.380
		var annual_hazard:=clampf(baseline_hazard*condition_factor+exceptional_hazard,0.0001,0.98)
		expected_years+=survival
		survival*=1.0-annual_hazard
	return clampf(expected_years,1.0,110.0)

func able_population() -> int:
	if not citizen_registry_initialized:
		return maxi(1,roundi(population_total*0.60))
	var count:=0
	for person in citizen_registry:
		if not bool(person.get("alive",true)): continue
		var age:=citizen_age_years(person)
		if age>=14 and age<60: count+=1
	return count

func synchronize_population_allocations() -> void:
	var total_percentage:=0.0
	for role in POPULATION_ROLES:
		total_percentage+=maxf(0.0,float(population_allocation_percentages.get(role,0.0)))
	if total_percentage<=0.001:
		population_allocation_percentages={"Food":42.0,"Survey":8.0,"Extraction":11.0,"Construction":11.0,"Crafting":7.0,"Logistics":7.0,"Knowledge":6.0,"Administration":4.0,"Defense":4.0}
		total_percentage=100.0
	var able:=able_population()
	var assigned:=0
	var remainders:Dictionary={}
	for role in POPULATION_ROLES:
		var normalized:=maxf(0.0,float(population_allocation_percentages.get(role,0.0)))/total_percentage
		var exact:=float(able)*normalized
		var count:=floori(exact)
		population_allocations[role]=count
		remainders[role]=exact-count
		assigned+=count
	while assigned<able:
		var best_role:=String(POPULATION_ROLES[0])
		var best_remainder:=-INF
		for role in POPULATION_ROLES:
			if float(remainders.get(role,-1.0))>best_remainder:
				best_remainder=float(remainders[role])
				best_role=String(role)
		population_allocations[best_role]=int(population_allocations.get(best_role,0))+1
		remainders[best_role]=-1.0
		assigned+=1
	var locked_military:=0
	if citizen_registry_initialized:
		for person in citizen_registry:
			if not bool(person.get("alive",true)): continue
			var age:=citizen_age_years(person)
			if age<14 or age>=60: continue
			if _citizen_locked_to_military(person): locked_military+=1
	var defense_shortfall:=maxi(0,locked_military-int(population_allocations.get("Defense",0)))
	population_allocations["Defense"]=int(population_allocations.get("Defense",0))+defense_shortfall
	while defense_shortfall>0:
		var donor_role:=""
		var donor_count:=0
		for role in POPULATION_ROLES:
			if role=="Defense": continue
			if int(population_allocations.get(role,0))>donor_count:
				donor_count=int(population_allocations.get(role,0))
				donor_role=String(role)
		if donor_role=="" or donor_count<=0: break
		population_allocations[donor_role]=donor_count-1
		defense_shortfall-=1
	if citizen_registry_initialized:
		_assign_citizen_roles()

func _citizen_locked_to_military(person:Dictionary)->bool:
	return String(person.get("army_status","civilian")) not in ["civilian","","deserter","killed"]

func _set_citizen_role(person: Dictionary,new_role: String) -> void:
	var old_role:=String(person.get("role","Unassigned"))
	if old_role==new_role:
		return
	person["role"]=new_role
	person["role_since_day"]=int(elapsed_days)
	var history:Array=person.get("history",[])
	history.append({"day":int(elapsed_days),"event":"Role changed from %s to %s." % [old_role,new_role]})
	if history.size()>40: history.pop_front()
	person["history"]=history

func _assign_citizen_roles() -> void:
	var remaining:Dictionary={}
	for role in POPULATION_ROLES:
		remaining[role]=int(population_allocations.get(role,0))
	var unassigned:Array[Dictionary]=[]
	for person in citizen_registry:
		if not bool(person.get("alive",true)):
			continue
		var age:=citizen_age_years(person)
		if age<14:
			_set_citizen_role(person,"Infant" if age<3 else "Child")
			continue
		if age>=60:
			_set_citizen_role(person,"Elder")
			continue
		if _citizen_locked_to_military(person):
			_set_citizen_role(person,"Defense")
			remaining["Defense"]=maxi(0,int(remaining.get("Defense",0))-1)
			continue
		var present_role:=String(person.get("role","Unassigned"))
		if present_role in POPULATION_ROLES and int(remaining.get(present_role,0))>0:
			remaining[present_role]=int(remaining[present_role])-1
		else:
			unassigned.append(person)
	for person in unassigned:
		var best_role:=""
		var best_score:=-INF
		for role in POPULATION_ROLES:
			if int(remaining.get(role,0))<=0: continue
			var score_seed:=hash("%s:%s" % [person.get("aptitude_seed",0),role])
			var score:=float(abs(score_seed)%100000)/100000.0
			if score>best_score:
				best_score=score
				best_role=String(role)
		if best_role=="":
			_set_citizen_role(person,"Unassigned")
		else:
			_set_citizen_role(person,best_role)
			remaining[best_role]=int(remaining[best_role])-1

func _mortality_weight(person: Dictionary,cause: String) -> float:
	var age:=citizen_age_years(person)
	var childhood:=2.4 if age<5 else (1.45 if age<14 else 1.0)
	var elder:=1.0+maxf(0.0,float(age-55))/8.0
	match cause:
		"Hunger": return childhood*1.7+elder*0.7
		"Illness": return childhood*1.35+elder*1.45
		"Exposure": return childhood*1.55+elder*1.25
		"Travel exhaustion": return childhood*1.20+(1.55 if age>=14 and age<60 else elder*0.85)
		"Insecurity": return 2.1 if age>=14 and age<60 else 0.65
		_: return 0.18+pow(maxf(0.0,float(age-42))/18.0,2.3)

func register_deaths(count: int,cause: String) -> Array[String]:
	initialize_citizen_registry()
	var rng:=RandomNumberGenerator.new()
	rng.seed=world_seed^int(elapsed_days*104729.0)^lifetime_deaths
	var names:Array[String]=[]
	for occurrence in maxi(0,count):
		var candidates:=living_citizens()
		if candidates.is_empty(): break
		var total_weight:=0.0
		for candidate in candidates: total_weight+=_mortality_weight(candidate,cause)
		var roll:=rng.randf()*maxf(0.001,total_weight)
		var selected:Dictionary=candidates.back()
		for candidate in candidates:
			roll-=_mortality_weight(candidate,cause)
			if roll<=0.0:
				selected=candidate
				break
		var final_role:=String(selected.get("role","Unassigned"))
		selected["alive"]=false
		selected["death_day"]=int(elapsed_days)
		selected["death_cause"]=cause
		selected["last_role"]=final_role
		selected["role"]="Deceased"
		_dissolve_partnership_after_death(selected)
		var history:Array=selected.get("history",[])
		history.append({"day":int(elapsed_days),"event":"Died; attributed primarily to %s." % cause.to_lower()})
		selected["history"]=history
		names.append(String(selected.name))
	population_total=living_citizen_count()
	synchronize_population_allocations()
	return names

func ensure_living_population(target: int) -> void:
	initialize_citizen_registry()
	target=maxi(1,target)
	var difference:=target-living_citizen_count()
	if difference>0:
		var rng:=RandomNumberGenerator.new()
		rng.seed=world_seed^target^0x43a9
		for i in difference:
			var band:=i%25
			var age:=rng.randi_range(14,59) if band<15 else (rng.randi_range(0,13) if band<23 else rng.randi_range(60,76))
			citizen_registry.append(_create_citizen(rng,age,"Migrant"))
	elif difference<0:
		var remaining:=-difference
		for person in citizen_registry:
			if remaining<=0: break
			if bool(person.get("alive",true)):
				person["alive"]=false
				person["death_day"]=int(elapsed_days)
				person["death_cause"]="Population test adjustment"
				person["role"]="Deceased"
				remaining-=1
	population_total=living_citizen_count()
	population_exact=float(population_total)
	synchronize_population_allocations()

func adjust_population_role_percentage(role: String,delta: float) -> void:
	if role not in POPULATION_ROLES:
		return
	var current:=clampf(float(population_allocation_percentages.get(role,0.0)),0.0,100.0)
	var target:=clampf(current+delta,0.0,82.0)
	var other_total:=maxf(0.0,100.0-current)
	var remaining:=100.0-target
	if other_total<=0.001:
		var share:=remaining/float(POPULATION_ROLES.size()-1)
		for other in POPULATION_ROLES:
			if other!=role: population_allocation_percentages[other]=share
	else:
		for other in POPULATION_ROLES:
			if other==role: continue
			population_allocation_percentages[other]=maxf(0.0,float(population_allocation_percentages.get(other,0.0))*remaining/other_total)
	population_allocation_percentages[role]=target
	synchronize_population_allocations()
