extends RefCounted
## Seek stronger research only from evidence physically returned and examined.
## Supplier knowledge is not inspected; acceptance is negotiated on arrival.
const E=preload("res://scripts/society_exchange.gd")
const Scholar=preload("res://scripts/scholar_visits.gd")
const Purchase=preload("res://scripts/research_purchase.gd")
const PaperStudy=preload("res://scripts/paper_study.gd")
static func recommendation(plan:Dictionary={})->Dictionary:
	var state=WorldSimulation.state
	var world=WorldSimulation.world
	if bool(plan.get("hungry",false)) or bool(plan.get("at_war",false)):return {}
	var purchase:=Purchase.available()
	if not (purchase or Scholar.available()) or not world.diplomatic_mission.is_empty() or state.effective_workers("Knowledge")<=0:return {}
	var pending_work:=_pending_study_work() if purchase else 0.0
	var strong:Dictionary={}
	for item:Dictionary in E.data().collections.values():
		if float(item.get("study",0))>=1 and int(item.get("returned_day",0))<=int(state.elapsed_days) and E.evidence_strength(item)>=2.5:strong[String(item.get("discovery_id",""))]=true
	var best:Dictionary={};var best_score:=-INF;var considered:Dictionary={}
	for item:Dictionary in E.data().collections.values():
		if float(item.get("study",0))<1 or int(item.get("returned_day",0))>int(state.elapsed_days):continue
		var subject:=String(item.get("discovery_id",""));var source:=String(item.get("source_id",""))
		if source=="" or subject=="" or subject in state.known_discoveries or strong.has(subject):continue
		var key:=Purchase.key(source,subject)
		if considered.has(key):continue
		considered[key]=true
		var recent:=false
		for mission:Dictionary in world.diplomatic_history:
			if String(mission.get("research_subject",""))==subject and E.owner_id(String(mission.get("civ_id","")))==E.owner_id(source) and int(state.elapsed_days)-int(mission.get("returned_day",0))<365:recent=true;break
		if recent:continue
		for gift:Dictionary in world.diplomatic_gift_options(source):
			# Retain food for subsistence and most material stocks for local work.
			if String(gift.resource)=="Food" or not bool(gift.can_send) or float(gift.amount)>float(gift.available)*.10:continue
			var use_purchase:=purchase
			var quote:=Purchase.quote(source,subject,String(gift.resource)) if purchase else Scholar.quote(source,subject,String(gift.resource))
			# An active inquiry can benefit from teaching while returned studies
			# await examination. Compare only local workload, never hidden suppliers.
			if purchase and subject in state.active_investigations.values():
				if quote.has("error") or _study_delay(float(quote.total_days),pending_work)>=Scholar.DURATION:
					var visit:=Scholar.quote(source,subject,String(gift.resource))
					if not visit.has("error"):
						quote=visit;use_purchase=false
			if quote.has("error"):continue
			var score:=(3.0 if subject in state.active_investigations.values() else 0.0)+1.0-float(quote.total_days)/365.0-float(gift.amount)/maxf(1.0,float(gift.available))
			if score>best_score:
				best_score=score;best={"kind":"research_purchase" if use_purchase else "research_scholar","source":source,"subject":subject,"resource":String(gift.resource)}
	return best

## Optimistic local examination time after the embassy returns. Existing work
## can clear during travel; the new study cannot. Assume the maximum printed
## support even without stocks, so a long estimate is conservative.
static func _study_delay(travel_days:float,pending_work:float=-1.0)->float:
	var state=WorldSimulation.state
	var rate:=state.effective_workers("Knowledge")*.15*clampf(float(state.simulation_metrics.get("food_intake_ratio",1)),0,1)*(1.0+PaperStudy.PRINTED_BONUS)
	if rate<=0:return INF
	var pending:=_pending_study_work() if pending_work<0 else pending_work
	return (maxf(0,pending-rate*travel_days)+Purchase.STUDY_WORK)/rate

static func _pending_study_work()->float:
	var pending:=0.0
	for item:Dictionary in E.data().collections.values():
		if int(item.get("returned_day",0))>int(WorldSimulation.state.elapsed_days):continue
		pending+=maxf(0,1-float(item.get("study",0)))*float(item.get("work",0))
	return pending
