extends SceneTree
## Export the live technology art queue; readiness comes from reviewed bindings,
## never from the number of queued prompts or broad-field fallback images.
func _initialize()->void:call_deferred("run")
func run()->void:
	for id:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(id).set_process(false)
	var discovery:Node=root.get_node("DiscoverySystem");discovery.initialize()
	var visuals:Script=load("res://scripts/hud/research_visuals.gd")
	var entries:Array=[];var ready:=0;var errors:Array[String]=[]
	var ids:Array[String]=[]
	for item:Dictionary in discovery.technology_catalog:
		ids.append(String(item.id))
		var key:String=visuals.DISCOVERY_ART.get(String(item.id),"")
		var reviewed:=key.begins_with("paper/")
		var path:="res://assets/ui/research/paper/%s.png" % String(item.id)
		if reviewed:
			if not FileAccess.file_exists(path):errors.append("Missing reviewed image: "+path)
			else:ready+=1
		entries.append({"id":item.id,"name":item.name,"description":item.get("observation",""),"domain":item.get("dynamic",""),"asset":path,"status":"verified" if reviewed and FileAccess.file_exists(path) else "queued"})
	for id:String in visuals.DISCOVERY_ART:
		if id not in ids:errors.append("Artwork binding has no live discovery: "+id)
	if not errors.is_empty():print(JSON.stringify({"errors":errors}));quit(1);return
	var result:={"schema":1,"style_reference":"res://assets/ui/research/paper/apprentice_contracts.png","prompt_record":"res://assets/ui/research/paper/PROMPTS.md","live_count":entries.size(),"verified_count":ready,"queued_count":entries.size()-ready,"live_art_complete":ready==entries.size(),"target_discoveries":5000,"full_overhaul_art_complete":ready>=5000 and ready==entries.size(),"items":entries}
	var file:=FileAccess.open("res://assets/ui/research/paper/catalog.json",FileAccess.WRITE)
	if file==null:push_error("Cannot save art catalog");quit(1);return
	file.store_string(JSON.stringify(result,"  "));file.close()
	print(JSON.stringify({"live":entries.size(),"verified":ready,"queued":entries.size()-ready,"live_art_complete":ready==entries.size(),"target_discoveries":5000,"full_overhaul_art_complete":ready>=5000 and ready==entries.size()}));quit()
