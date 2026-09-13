extends RefCounted
## Real media are allocated to study notes, never substituted for Knowledge labor.
const PAPER_PER_WORK:=.01
const BONUS:=.2
const PRINTED_BONUS:=.3
const MEDIA:={
	"Printed Sheets":{"per_work":PAPER_PER_WORK,"bonus":PRINTED_BONUS},
	"Bound Record Books":{"per_work":.005,"bonus":.25},
	"Paper":{"per_work":PAPER_PER_WORK,"bonus":BONUS},
	"Clay Record Tablets":{"per_work":.02,"bonus":.15},
	"Record Cords":{"per_work":.01,"bonus":.12}
}
static func supports(resource:String,item:Dictionary)->bool:
	if resource!="Record Cords":return true
	# This implementation records quantities during local specimen work;
	# it does not assume arbitrary manuscripts can be encoded or translated.
	return String(item.get("kind",""))=="specimen" and "knotted_record_systems" in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption("knotted_record_systems")>=.1
static func use(work_available:float,remaining:float,item:Dictionary={})->Dictionary:
	var available:=maxf(0,work_available);var need:=maxf(0,remaining)
	var result:={"work":0.0,"progress":0.0,"paper":0.0,"printed_sheets":0.0,"record_media":{}}
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for resource:String in MEDIA:
		if not supports(resource,item):continue
		var spec:Dictionary=MEDIA[resource]
		var supported:=minf(available,minf(maxf(0,float(stocks.get(resource,0)))/float(spec.per_work),need/(1.0+float(spec.bonus))))
		if supported<=0:continue
		var spent:=supported*float(spec.per_work)
		stocks[resource]=maxf(0,float(stocks[resource])-spent)
		available-=supported;need=maxf(0,need-supported*(1.0+float(spec.bonus)))
		result.work+=supported;result.progress+=supported*(1.0+float(spec.bonus))
		if resource=="Paper":result.paper=spent
		elif resource=="Printed Sheets":result.printed_sheets=spent
		else:result.record_media[resource]=spent
	var plain:=minf(available,need)
	result.work+=plain;result.progress+=plain
	return result
