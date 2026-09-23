extends RefCounted
## Study media are allocated to study notes, never substituted for Knowledge labor.
## Media are no longer separate stocks: an adopted record technique lets
## researchers draw Civilian Goods (plus the raw materials the medium is made
## from) for notes, and its study bonus scales with that adoption.
const Bills=preload("res://scripts/goods_bills.gd")
const Goods=preload("res://scripts/civilian_goods.gd")
const PAPER_PER_WORK:=.01
const BONUS:=.2
const PRINTED_BONUS:=.3
## Medium-equivalent units per unit of study work, the full-adoption bonus, and
## the discoveries whose adoption makes the medium available.
const MEDIA:={
	"Printed Sheets":{"per_work":PAPER_PER_WORK,"bonus":PRINTED_BONUS,"gates":["hand_relief_printing","screw_press_printing","cylinder_press_printing","rolling_intaglio_printing","mineral_pigment_preparation"]},
	"Bound Record Books":{"per_work":.005,"bonus":.25,"gates":["bookbinding_assemblies"]},
	"Paper":{"per_work":PAPER_PER_WORK,"bonus":BONUS,"gates":["paper_making","paper_sheet_pressing"]},
	"Parchment Sheets":{"per_work":.006,"bonus":.2,"gates":["parchment_record_preparation"]},
	"Clay Record Tablets":{"per_work":.02,"bonus":.15,"gates":["clay_record_tablets"]},
	"Record Cords":{"per_work":.01,"bonus":.12,"gates":["knotted_record_systems"]}
}
## Adoption below this share does not yet supply notes.
const MIN_ADOPTION:=.1
static func supports(resource:String,item:Dictionary)->bool:
	if resource!="Record Cords":return true
	# This implementation records quantities during local specimen work;
	# it does not assume arbitrary manuscripts can be encoded or translated.
	return String(item.get("kind",""))=="specimen" and "knotted_record_systems" in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption("knotted_record_systems")>=.1
## Best adoption among the techniques that make `resource`, 0 when none is known.
static func adoption(resource:String)->float:
	var best:=0.0
	for gate:String in MEDIA.get(resource,{}).get("gates",[]):
		if gate in WorldSimulation.state.known_discoveries:best=maxf(best,clampf(WorldSimulation.discovery.adoption(gate),0.0,1.0))
	return best
## Raw materials and Civilian Goods drawn per unit of study work on `resource`.
static func bill(resource:String)->Dictionary:
	return Bills.flatten({resource:float(MEDIA[resource].per_work)})
static func use(work_available:float,remaining:float,item:Dictionary={})->Dictionary:
	var available:=maxf(0,work_available);var need:=maxf(0,remaining)
	var result:={"work":0.0,"progress":0.0,"paper":0.0,"printed_sheets":0.0,"record_media":{},"goods":0.0}
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for resource:String in MEDIA:
		if available<=0 or need<=0:break
		if not supports(resource,item):continue
		var level:=adoption(resource)
		if level<MIN_ADOPTION:continue
		var spec:Dictionary=MEDIA[resource]
		var bonus:=float(spec.bonus)*level
		var per_work:=bill(resource)
		var supported:=minf(available,need/(1.0+bonus))
		for input:String in per_work:
			if float(per_work[input])>0:supported=minf(supported,maxf(0,float(stocks.get(input,0)))/float(per_work[input]))
		if supported<=0:continue
		for input:String in per_work:stocks[input]=maxf(0,float(stocks.get(input,0))-float(per_work[input])*supported)
		result.goods+=float(per_work.get(Goods.GOODS,0.0))*supported
		available-=supported;need=maxf(0,need-supported*(1.0+bonus))
		result.work+=supported;result.progress+=supported*(1.0+bonus)
		# Medium-equivalent quantities, kept for reports that name the medium.
		var spent:=supported*float(spec.per_work)
		if resource=="Paper":result.paper=spent
		elif resource=="Printed Sheets":result.printed_sheets=spent
		else:result.record_media[resource]=spent
	var plain:=minf(available,need)
	result.work+=plain;result.progress+=plain
	return result
