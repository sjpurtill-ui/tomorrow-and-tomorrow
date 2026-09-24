extends SceneTree
## Reconcile the art queue with the live technology catalogue without discarding
## the provenance and review decisions on existing entries.
const CATALOG_PATH:="res://assets/ui/research/paper/catalog.json"

func _initialize()->void:call_deferred("run")

func run()->void:
	for id:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(id).set_process(false)
	var discovery:Node=root.get_node("DiscoverySystem")
	discovery.initialize()
	var visuals:Script=load("res://scripts/hud/research_visuals.gd")
	var previous:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	var previous_by_id:Dictionary={}
	for entry:Dictionary in previous.get("items",[]):previous_by_id[String(entry.id)]=entry
	var live_by_id:Dictionary={}
	var ordered_ids:Array[String]=[]
	for item:Dictionary in discovery.technology_catalog:live_by_id[String(item.id)]=item
	for entry:Dictionary in previous.get("items",[]):
		var id:=String(entry.id)
		if live_by_id.has(id):ordered_ids.append(id)
	for item:Dictionary in discovery.technology_catalog:
		var id:=String(item.id)
		if not previous_by_id.has(id):ordered_ids.append(id)
	var entries:Array=[]
	var ready:=0
	var errors:Array[String]=[]
	for id:String in ordered_ids:
		var item:Dictionary=live_by_id[id]
		var entry:Dictionary=previous_by_id.get(id,{}).duplicate(true)
		var file_name:=String(visuals.EARLY_SUBJECT_FILES.get(id,id))
		var default_path:="res://assets/ui/research/paper/%s.png" % file_name
		var reviewed:bool=String(entry.get("status",""))=="verified" or visuals.EARLY_SUBJECTS.has(id)
		var path:=String(entry.get("asset",default_path)) if reviewed else default_path
		if reviewed and not FileAccess.file_exists(path):errors.append("Missing reviewed image: "+path)
		entry["id"]=id
		entry["name"]=String(item.name)
		entry["description"]=String(item.get("observation",""))
		entry["day"]=int(item.get("day",0))
		entry["domain"]=String(item.get("dynamic",""))
		entry["asset"]=path
		entry["status"]="verified" if reviewed else "queued"
		if reviewed:ready+=1
		entries.append(entry)
	if not errors.is_empty():print(JSON.stringify({"errors":errors}));quit(1);return
	previous["live_count"]=entries.size()
	previous["verified_count"]=ready
	previous["queued_count"]=entries.size()-ready
	previous["live_art_complete"]=ready==entries.size()
	previous["full_overhaul_art_complete"]=ready>=int(previous.get("target_discoveries",5000)) and ready==entries.size()
	previous["items"]=entries
	var file:=FileAccess.open(CATALOG_PATH,FileAccess.WRITE)
	if file==null:push_error("Cannot save art catalog");quit(1);return
	file.store_string(JSON.stringify(previous,"  ",false));file.close()
	print(JSON.stringify({"live":entries.size(),"verified":ready,"queued":entries.size()-ready}))
	quit()
