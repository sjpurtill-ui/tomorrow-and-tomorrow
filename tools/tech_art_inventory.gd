extends SceneTree

func _initialize()->void:
	call_deferred("run")

func run()->void:
	var system=root.get_node("DiscoverySystem")
	system.initialize()
	var entries:Array=[]
	for item:Dictionary in system.technology_catalog:
		entries.append({"id":item.id,"name":item.name,"description":item.get("observation",""),"day":item.get("day",0),"domain":item.get("dynamic","")})
	DirAccess.make_dir_recursive_absolute("res://artifacts/tech-paper")
	var file=FileAccess.open("res://artifacts/tech-paper/catalog.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(entries,"  "))
	file.close()
	print("TECH_ART_INVENTORY ",entries.size())
	root.get_node("WorldSimulation").clear()
	quit()
