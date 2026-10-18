extends RefCounted
const Families=preload("res://scripts/major_families.gd")
## Deliberately anchored commands. Questions, reported speech and conditions
## never turn into patronage. Names must uniquely identify a current house.
static func read(words:String)->Dictionary:
	var text:=words.strip_edges().to_lower().trim_suffix(".")
	if text=="withdraw family patronage":return {"action":"neutral","id":""}
	var action:=""
	for pair:Array in [["favor ","favor"],["favour ","favor"],["endorse the program of ","entrust"]]:
		if text.begins_with(String(pair[0])):action=String(pair[1]);text=text.trim_prefix(String(pair[0]));break
	if action.is_empty():return {}
	var found:Array=[]
	for f:Dictionary in Families.data().get("families",[]):
		var head:Dictionary=WorldSimulation.government.person_snapshot(int(f.head))
		if text in [String(f.name).to_lower(),String(head.get("name","")).to_lower()]:found.append(String(f.id))
	if found.size()!=1:return {}
	return {"action":action,"id":String(found[0])}

static func carry(result:Dictionary,reading:Dictionary)->Dictionary:
	var done:=Families.decide(String(reading.action),String(reading.id))
	result["route"]="families";result["verb"]="order";result["executed"]=bool(done.ok)
	result["outcome"]=String(done.text);result["actor_says"]=String(done.text)
	result["stage"]="order" if done.ok else "none";result["reaction"]="neutral"
	return result
