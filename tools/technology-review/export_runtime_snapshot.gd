extends SceneTree
## Export the loaded checkout's graph for editorial reconciliation, never gameplay proof.
func _initialize()->void:call_deferred("run")
func run()->void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=1:
		push_error("Pass one absolute snapshot output path after --");quit(2);return
	var output:=String(args[0])
	if not output.is_absolute_path():push_error("Snapshot output must be absolute");quit(2);return
	var revision:Array=[]
	var checkout:=ProjectSettings.globalize_path("res://")
	if OS.execute("git",["-C",checkout,"rev-parse","HEAD"],revision,true)!=0:
		push_error("Cannot identify checkout revision");quit(2);return
	if OS.execute("git",["-C",checkout,"diff","--quiet","HEAD"],[],true)!=0:
		push_error("Tracked checkout edits prevent a commit-backed snapshot");quit(2);return
	for name:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(name).set_process(false)
	var discovery:Node=root.get_node("DiscoverySystem")
	discovery.initialize()
	var pathways:Script=load("res://scripts/knowledge_pathways.gd")
	var requirements:Script=load("res://scripts/technology_requirements.gd")
	var entries:Array=[]
	for entry:Dictionary in discovery.technology_catalog:
		var row:Dictionary=entry.duplicate(true)
		row.merge(pathways.graph_entry(entry),true)
		row["requires_all"]=row.get("requires_all",row.get("requires",[]))
		row["requires_any"]=row.get("requires_any",[])
		entries.append(row)
	var errors:Array=requirements.validate(entries)
	if not errors.is_empty():push_error(str(errors));quit(1);return
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file==null:push_error("Cannot write snapshot");quit(2);return
	var snapshot:={"source_commit":String(revision[0]).strip_edges(),"source_checkout":checkout,"validation_scope":"Loaded runtime graph and causal reachability; integration and behavior must be independently verified","items":entries}
	file.store_string(JSON.stringify(snapshot,"  "));file.close()
	print(JSON.stringify({"source_commit":snapshot.source_commit,"discoveries":entries.size(),"output":output}))
	quit(0)
