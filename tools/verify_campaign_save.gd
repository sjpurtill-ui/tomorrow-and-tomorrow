extends RefCounted
## Headless whole-save continuation check using a unique temporary test slot.
static func capture()->Dictionary:
	var payload:Dictionary={}
	for name:String in SaveSystem.REFLECTED_SYSTEMS:
		payload["reflected_"+name]=SaveSystem._capture_reflected(SaveSystem.get_node("/root/"+name),SaveSystem.REFLECT_SKIP.get(name,[]))
	payload.reflected_society_model=SaveSystem._capture_reflected(DiscoverySystem.society_model,SaveSystem.SOCIETY_REFLECT_SKIP)
	for name:String in SaveSystem.CURATED_SYSTEMS:
		payload["curated_"+name]=SaveSystem.get_node("/root/"+name).export_state()
	return payload
static func verify(origin:Vector2,rebind:Callable,checkpoint:String="")->Dictionary:
	var slot:="first300_probe_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	var path:=SaveSystem.slot_path(slot)
	if FileAccess.file_exists(path):return {"error":"Diagnostic save slot already exists."}
	var saved:=SaveSystem.save_game(slot)
	if saved.has("error"):return saved
	if not checkpoint.is_empty():
		var copied:=DirAccess.copy_absolute(path,checkpoint)
		if copied!=OK:
			DirAccess.remove_absolute(path)
			return {"error":"Could not retain the diagnostic checkpoint."}
	var before:=capture()
	var day:=int(GameState.elapsed_days)
	WorldSimulation.advance_day(day+1,preload("res://scripts/civilization_day.gd").context(origin))
	var expected:=capture()
	var loaded:=SaveSystem.load_game(slot)
	var result:Dictionary={"loaded":loaded}
	if not loaded.has("error"):
		rebind.call()
		var actual_before:=capture()
		result["restored_equal"]=before==actual_before
		result["restore_differences"]=differences(before,actual_before)
		result["restore_detail"]=details(before,actual_before)
		WorldSimulation.advance_day(day+1,preload("res://scripts/civilization_day.gd").context(origin))
		var actual:=capture()
		result["continuation_equal"]=expected==actual
		result["continuation_differences"]=differences(expected,actual)
		result["continuation_detail"]=details(expected,actual)
		result["final_restore"]=SaveSystem.load_game(slot)
		rebind.call()
	else:result["error"]=loaded.error
	DirAccess.remove_absolute(path)
	if not bool(result.get("restored_equal",false)) or not bool(result.get("continuation_equal",false)) or result.get("final_restore",{}).has("error"):
		result["error"]="Whole-game save continuation differs."
	return result
static func differences(a:Dictionary,b:Dictionary)->Array[String]:
	var result:Array[String]=[]
	for key:String in a:
		if not b.has(key) or a[key]!=b[key]:result.append(key)
	return result

static func details(a:Variant,b:Variant,path:String="",result:Array=[])->Array:
	if a==b or result.size()>=80:return result
	if a is Dictionary and b is Dictionary:
		for key in a:
			if not b.has(key):result.append({"path":path+"."+str(key),"missing":true});continue
			details(a[key],b[key],path+"."+str(key),result)
		for key in b:
			if not a.has(key):result.append({"path":path+"."+str(key),"added":true})
	elif a is Array and b is Array and a.size()==b.size():
		for i in a.size():details(a[i],b[i],path+"["+str(i)+"]",result)
	else:result.append({"path":path,"before":str(a).left(160),"after":str(b).left(160)})
	return result
