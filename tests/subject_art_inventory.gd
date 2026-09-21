extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var system=root.get_node("DiscoverySystem")
 system.initialize()
 var entries:Array=[]
 for item:Dictionary in system.technology_catalog:entries.append({"id":item.id,"name":item.name,"description":item.get("observation",""),"day":item.get("day",0),"domain":item.get("dynamic","")})
 DirAccess.make_dir_recursive_absolute("res://artifacts/subject-art")
 var file=FileAccess.open("res://artifacts/subject-art/discoveries.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(entries,"  "));file.close()
 var units:Array=[]
 for id:String in preload("res://scripts/military_unit_catalog.gd").ARCHETYPES:
  var unit:Dictionary=preload("res://scripts/military_unit_catalog.gd").ARCHETYPES[id]
  units.append({"id":id,"name":unit.label,"domain":"army","era":unit.era,"equipment":unit.equipment,"description":unit.purpose})
 for id:String in preload("res://scripts/joint_force_catalog.gd").UNITS:
  var unit:Dictionary=preload("res://scripts/joint_force_catalog.gd").UNITS[id]
  units.append({"id":id,"name":unit.label,"domain":unit.domain,"gate":unit.gate,"description":unit.purpose})
 var unit_file=FileAccess.open("res://artifacts/subject-art/units.json",FileAccess.WRITE)
 unit_file.store_string(JSON.stringify(units,"  "));unit_file.close()
 print("SUBJECT_ART_FIXED_DISCOVERIES ",entries.size()," UNIT_TYPES ",units.size())
 root.get_node("WorldSimulation").clear()
 quit()
