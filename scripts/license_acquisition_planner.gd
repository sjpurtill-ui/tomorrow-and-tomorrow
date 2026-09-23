extends RefCounted
## License dependent lines or supplied fertilizer and operating inputs. Study
## media are Civilian Goods drawn under adopted record techniques, so they no
## longer create demand for a paper or printing license.
## Leads are examined returned evidence or the civilization's own contracts.
const L=preload("res://scripts/research_licenses.gd")
const E=preload("res://scripts/society_exchange.gd")
const I=preload("res://scripts/civilian_industry.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
static func recommendation(plan:Dictionary={})->Dictionary:
	var state=WorldSimulation.state;var world=WorldSimulation.world
	if bool(plan.get("hungry",false)) or bool(plan.get("at_war",false)) or not world.diplomatic_mission.is_empty():return {}
	if not L.available() or state.effective_workers("Crafting")<1:return {}
	var leads:Array[Dictionary]=[]
	for item:Dictionary in E.data().collections.values():
		if float(item.get("study",0))>=1 and int(item.get("returned_day",0))<=int(state.elapsed_days):
			leads.append({"source":String(item.get("source_id","")),"subject":String(item.get("discovery_id",""))})
	for subject:String in L.records():leads.append({"source":String(L.records()[subject].source),"subject":subject})
	var wanted:=demanded_subjects(leads)
	if wanted.is_empty():return {}
	var best:Dictionary={};var best_score:=-INF;var considered:Dictionary={}
	for lead:Dictionary in leads:
		var source:=String(lead.source);var subject:=String(lead.subject)
		if source.is_empty() or not wanted.has(subject):continue
		var key:=source+":"+subject
		if considered.has(key):continue
		considered[key]=true
		var recent:=false
		for mission:Dictionary in world.diplomatic_history:
			if String(mission.get("research_mode",""))=="license" and String(mission.get("research_subject",""))==subject and E.owner_id(String(mission.get("civ_id","")))==E.owner_id(source) and int(state.elapsed_days)-int(mission.get("returned_day",0))<30:recent=true;break
		if recent:continue
		for gift:Dictionary in world.diplomatic_gift_options(source):
			if String(gift.resource)=="Food" or not bool(gift.can_send) or float(gift.amount)>float(gift.available)*.10:continue
			var quote:=L.quote(source,subject,String(gift.resource))
			if quote.has("error"):continue
			var score:=float(wanted[subject])-float(quote.total_days)/365.0-float(gift.amount)/maxf(1,float(gift.available))
			if score>best_score:best_score=score;best={"kind":"research_license","source":source,"subject":subject,"resource":String(gift.resource)}
	return best
static func supplied(recipe:Dictionary,tooling:bool)->bool:
	var costs:Dictionary=recipe.materials.duplicate()
	if tooling:
		for resource:String in recipe.tooling:costs[resource]=float(costs.get(resource,0))+float(recipe.tooling[resource])
	for resource:String in costs:
		if float(WorldSimulation.state.resource_stockpiles.get(resource,0))<float(costs[resource]):return false
	return true
static func demanded_subjects(leads:Array[Dictionary])->Dictionary:
	var wanted:Dictionary={};var state=WorldSimulation.state
	for job:Dictionary in WorldSimulation.military.equipment_queue:
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):continue
		var recipe:=I.product(String(job.get("item","")))
		if recipe.is_empty() or L.independent(String(recipe.gate)):continue
		if int(job.get("target_stock",0))>0 and float(state.resource_stockpiles.get(recipe.output,0))>=int(job.target_stock):continue
		if supplied(recipe,false):wanted[recipe.gate]=3.0
	# Fertilizer and plant operating inputs are no longer made on licensed
	# workshop lines (they are raw materials and Civilian Goods), so licences
	# for their former recipes buy nothing.
	return wanted

static func fertilizer_subjects(leads:Array[Dictionary])->Dictionary:
	var nutrition=preload("res://scripts/crop_nutrition.gd")
	var needs:Dictionary=nutrition.needs()
	if needs.is_empty():return {}
	var examined:Dictionary={}
	for lead:Dictionary in leads:examined[String(lead.subject)]=true
	var wanted:Dictionary={}
	for nutrient:String in needs:
		var need:Dictionary=needs[nutrient]
		if float(need.deficit)<=.000001:continue
		var domestic:=false
		var possible:=float(need.available)>=float(need.daily)*.1
		var subjects:Array[String]=[]
		for resource:String in nutrition.INPUTS:
			var concentration:=float(nutrition.INPUTS[resource].get(nutrient,0))
			if concentration<=0:continue
			var stock:=maxf(0,float(WorldSimulation.state.resource_stockpiles.get(resource,0)))
			var target:=ceili(stock+minf(10,float(need.deficit)/concentration))
			if not Supply.supply(resource,target,{}).is_empty():domestic=true;possible=true
			for recipe:Dictionary in I.PRODUCTS.values():
				if String(recipe.output)!=resource or L.independent(String(recipe.gate)) or not examined.has(recipe.gate):continue
				if not supplied(recipe,true):continue
				if float(recipe.get("power",0))>0 and preload("res://scripts/technology_operations.gd").service("electricity")<=0:continue
				possible=true
				if String(recipe.gate) not in subjects:subjects.append(String(recipe.gate))
		# Both nutrients need a stock, domestic route or examined supplied license prospect.
		if not possible:return {}
		if not domestic:
			for subject:String in subjects:wanted[subject]=1.25+.25*clampf(1-float(need.available)/float(need.daily),0,1)
	return wanted

static func operating_subjects(leads:Array[Dictionary])->Dictionary:
	var wanted:Dictionary={};var examined:Dictionary={}
	for lead:Dictionary in leads:examined[String(lead.subject)]=true
	var needs:=Supply.operating_input_needs()
	for resource:String in needs:
		var need:Dictionary=needs[resource]
		var paused:=false
		for job:Dictionary in WorldSimulation.military.equipment_queue:
			if bool(job.get("persistent",false)) and bool(job.get("paused",false)) and String(I.product(String(job.get("item",""))).get("output",""))==resource:paused=true;break
		if paused:continue
		# An affordable independent or already licensed method takes precedence.
		if not Supply.supply(resource,int(need.target),{},true).is_empty():continue
		for recipe:Dictionary in I.PRODUCTS.values():
			if String(recipe.output)!=resource or L.independent(String(recipe.gate)) or not examined.has(recipe.gate):continue
			if not supplied(recipe,true):continue
			if float(recipe.get("power",0))>0 and not preload("res://scripts/power_investment_planner.gd").can_supply(float(recipe.daily_power)):continue
			wanted[recipe.gate]=1.5+.25*clampf(1-float(need.available)/float(need.daily),0,1)
	return wanted
