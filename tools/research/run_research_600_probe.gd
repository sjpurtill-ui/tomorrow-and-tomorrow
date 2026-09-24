extends SceneTree
## Headless earliest-possible-year probe; never launches the player scene.
##   <godot> --headless --path <worktree> -s res://tools/research/run_research_600_probe.gd -- [years] [step]
## Prints a JSON summary: items opened per decade, and any discovery that opens
## before its design band (registry) or era gate (everything else).
func _initialize()->void:
	call_deferred("run")

func run()->void:
	for name:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(name).set_process(false)
	var args:=OS.get_cmdline_user_args()
	var horizon:=float(args[0]) if args.size()>0 else 100.0
	var step:=float(args[1]) if args.size()>1 else 0.25
	var discovery:Node=root.get_node("DiscoverySystem")
	discovery.initialize()
	var catalog:Script=load("res://scripts/research_600_catalog.gd")
	var first:Dictionary=load("res://tools/research/research_600_probe.gd").earliest_years(discovery,horizon,step)
	var early:Array=[]
	var per_decade:Dictionary={}
	for id:String in first:
		var year:=float(first[id])
		var decade:=int(year/10.0)*10
		per_decade[decade]=int(per_decade.get(decade,0))+1
		var gate:=float(discovery.discovery_definition(id).get("earliest_year",0.0))
		var band_low:=float(catalog.item(id).get("band_low",gate)) if catalog.has(id) else gate
		if year+step<band_low or year<gate-0.000001: early.append({"id":id,"year":year,"band_low":band_low,"gate":gate})
	var registry_open:=0
	for id:String in catalog.ids(): if first.has(id): registry_open+=1
	print(JSON.stringify({"horizon_years":horizon,"step_years":step,"opened":first.size(),"registry_opened":registry_open,
		"registry_total":catalog.ids().size(),"live_total":discovery.technology_catalog.size(),"per_decade":per_decade,"before_band":early}))
	quit(0 if early.is_empty() else 1)
