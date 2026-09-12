extends RefCounted
## Only physical communications examples benefit from this finite daily service.
const Ops=preload("res://scripts/technology_operations.gd")
const K=preload("res://scripts/communications_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
static var subjects:Dictionary={}

static func eligible(item:Dictionary)->bool:
	if not bool(item.get("reverse_engineered",false)):return false
	if subjects.is_empty():
		for entry:Dictionary in K.entries():subjects[entry.id]=true
	var subject:=String(item.get("discovery_id",""))
	if not subjects.has(subject):return false
	return String(I.product(String(item.get("specimen_item",""))).get("gate",""))==subject

static func use(item:Dictionary,progress:float,remaining:float)->float:
	if progress<=0 or not eligible(item):return 0.0
	var extra:=minf(maxf(0,remaining-progress),minf(progress*.25,Ops.service("signal_analysis")))
	if extra>0:Ops.data().services.signal_analysis-=extra
	return extra
