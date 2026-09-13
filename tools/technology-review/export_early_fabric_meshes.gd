extends SceneTree
func triangles(mesh:Mesh)->Array:
 var result:Array=[]
 for surface in mesh.get_surface_count():
  var arrays:Array=mesh.surface_get_arrays(surface)
  var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR]!=null else PackedColorArray()
  var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
  if indices.is_empty():
   for i in vertices.size():indices.append(i)
  for i in range(0,indices.size(),3):
   var row:Array=[]
   for j in 3:
    var v:Vector3=vertices[indices[i+j]];row.append([v.x,v.y,v.z])
   var color:Color=colors[indices[i]] if not colors.is_empty() else Color.WHITE
   row.append([color.r,color.g,color.b]);result.append(row)
 return result
func _initialize()->void:
 var args:=OS.get_cmdline_user_args()
 if args.size()!=2:quit(1);return
 var before:Array=[];var after:Array=[]
 var early=load("res://scripts/early_settlement_visual.gd")
 var kit=load("res://scripts/settlement_architecture_kit.gd")
 for name:String in ["round_household","earthen_household","covered_workshop","house_compact"]:
  var mesh:Mesh=load("res://scripts/organic_town_visual.gd").kit_mesh(1) if name=="house_compact" else early.kit_mesh(name)
  var raw:=triangles(mesh)
  var flags:int=8+64+(128 if name=="earthen_household" else 1+2+32)
  before.append({"name":name,"triangles":raw.duplicate()})
  var overlay:ArrayMesh=kit.early_detail_mesh(mesh.get_aabb(),name,flags)
  raw.append_array(triangles(overlay));after.append({"name":name,"triangles":raw})
 for i in 2:
  var file:=FileAccess.open(args[i],FileAccess.WRITE)
  file.store_string(JSON.stringify(before if i==0 else after));file.close()
 quit()
