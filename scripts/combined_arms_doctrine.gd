extends RefCounted
## Formation-held rehearsal, not a global combat bonus or a player tactic order.
const RULES={
	"cavalry_infantry_liaison":{"targets":["cavalry","light_cavalry","armored_cavalry"],"support":["spearman","line_infantry","heavy_swordsman"],"threats":["spearman","pikeman","heavy_swordsman"],"defense":.15},
	"gun_line_security":{"targets":["field_artillery","modern_artillery","horse_artillery","mortar_crew"],"support":["line_infantry","rifle_infantry","musketeer","assault_infantry"],"threats":["cavalry","light_cavalry","armored_cavalry","assault_infantry"],"defense":.25},
	"infantry_tank_cooperation":{"targets":["armored_formation","light_tank","heavy_tank"],"support":["rifle_infantry","motorized_infantry","mechanized_infantry","assault_infantry"],"threats":["anti_tank","tank_destroyer"],"defense":.20}
}
static func entries()->Array[Dictionary]:
	return [
		{"id":"cavalry_infantry_liaison","name":"Cavalry–Infantry Liaison","direction":"Warfare","day":3200,"chance":.002,"requires":["domesticated_mounts","formation_drill"],"signals":["training","warfare","logistics"],"observation":"Foot and mounted troops rehearse mutual support so mounted attacks do not meet formed resistance alone.","effects":{},"doctrine":"cavalry_infantry_liaison","production_contract":"Enables rehearsed infantry support for mounted formations facing formed spear or heavy infantry; actual equipped support troops must remain present."},
		{"id":"gun_line_security","name":"Gun-Line Security","direction":"Warfare","day":56000,"chance":.002,"requires":["powder_artillery","formation_drill"],"signals":["training","warfare","defense"],"observation":"Infantry guards and gun crews rehearse protecting gun positions against troops closing on the batteries.","effects":{},"doctrine":"gun_line_security","production_contract":"Rehearsed, equipped infantry screens improve artillery defense against mounted or assault formations; an isolated battery receives no benefit."},
		{"id":"infantry_tank_cooperation","name":"Infantry–Tank Cooperation","direction":"Warfare","day":85000,"chance":.002,"requires":["armored_vehicles","military_staffs"],"signals":["training","warfare","logistics"],"observation":"Infantry and tank crews rehearse coordinated movement and protection against antitank positions.","effects":{},"doctrine":"infantry_tank_cooperation","production_contract":"Rehearsed, supplied infantry improves tank defense against antitank troops. It does not replace armor, ammunition, vehicles or crews."}
	]
static func levels()->Dictionary:
	var result:Dictionary={}
	for id:String in RULES:
		if id in WorldSimulation.state.known_discoveries:result[id]=clampf(WorldSimulation.discovery.adoption(id),0,1)
	return result
static func clean(value:Variant)->Dictionary:
	var result:Dictionary={}
	if not value is Dictionary:return result
	for id:Variant in value:
		if RULES.has(id) and (value[id] is float or value[id] is int) and is_finite(float(value[id])):result[id]=clampf(float(value[id]),0,1)
	return result
static func valid_tree(value:Variant)->bool:
	if value is Array:
		for child:Variant in value:
			if not valid_tree(child):return false
	elif value is Dictionary:
		for key:Variant in value:
			if key=="doctrines":
				if not value[key] is Dictionary or clean(value[key])!=value[key]:return false
			elif not valid_tree(value[key]):return false
	return true
static func capacity(f:Dictionary)->float:
	var count:=maxf(0,float(f.get("count",0)))
	var equipped:=clampf(float(f.get("equipment",0))/maxf(1,float(f.get("equipment_required",count))),0,1)
	var ammunition:=1.0
	if float(f.get("ammunition_required",0))>0:ammunition=clampf(float(f.get("ammunition",0))/float(f.ammunition_required),0,1)
	return count*equipped*ammunition*clampf(float(f.get("training",0)),0,1)*clampf(float(f.get("personnel_condition",1)),0,1)*clampf(float(f.get("readiness",1)),0,1)
static func practice(formations:Array,available:Dictionary,supply:float)->void:
	for id:String in RULES:
		var ceiling:=float(clean(available).get(id,0))
		if ceiling<=0 or supply<=0:continue
		var rule:Dictionary=RULES[id];var targets:=0.0;var support:=0.0
		for f:Dictionary in formations:
			if f.get("unit","") in rule.targets:targets+=capacity(f)
			if f.get("unit","") in rule.support:support+=capacity(f)
		if targets<=0 or support<=0:continue
		for f:Dictionary in formations:
			if f.get("unit","") not in rule.targets+rule.support:continue
			if not f.has("doctrines"):f["doctrines"]={}
			var prior:=float(clean(f.doctrines).get(id,0))
			var condition:=capacity(f)/maxf(1,float(f.get("count",0)))
			if prior<ceiling:f.doctrines[id]=minf(ceiling,prior+.03*clampf(supply,0,1)*condition)
static func defense(formation:Dictionary,allies:Array,enemies:Array)->float:
	var modifier:=1.0
	for id:String in RULES:
		var rule:Dictionary=RULES[id]
		if formation.get("unit","") not in rule.targets:continue
		var practiced:=float(clean(formation.get("doctrines",{})).get(id,0))
		if practiced<=0 or capacity(formation)<=0:continue
		var targets:=0.0;var support:=0.0;var threats:=0.0;var enemy_total:=0.0
		for f:Dictionary in allies:
			if f.get("unit","") in rule.targets:targets+=maxf(0,float(f.get("count",0)))
			if f.get("unit","") in rule.support:support+=capacity(f)*float(clean(f.get("doctrines",{})).get(id,0))
		for f:Dictionary in enemies:
			var ready:=capacity(f);enemy_total+=ready
			if f.get("unit","") in rule.threats:threats+=ready
		var coverage:=clampf(support/maxf(1,targets*.5),0,1)
		modifier+=float(rule.defense)*practiced*coverage*(threats/maxf(1,enemy_total))
	return minf(1.3,modifier)
