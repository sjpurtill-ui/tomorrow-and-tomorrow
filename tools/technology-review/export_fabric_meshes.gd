extends SceneTree
func _initialize()->void:
 var args:=OS.get_cmdline_user_args()
 if args.size()<1:quit(1);return
 var kit=load(args[1] if args.size()>1 else "res://scripts/settlement_architecture_kit.gd")
 var result:Array=[]
 for shape:String in ["terrace","courtyard","villa","hall"]:
  var mesh:ArrayMesh=kit.mesh_for("timber_"+shape,2,255)
  var triangles:Array=[]
  for surface in mesh.get_surface_count():
   var arrays:Array=mesh.surface_get_arrays(surface)
   var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
   var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
   if indices.is_empty():
    for i in vertices.size():indices.append(i)
   for i in range(0,indices.size(),3):
    var row:Array=[]
    for j in 3:
     var v:Vector3=vertices[indices[i+j]];row.append([v.x,v.y,v.z])
    var color:Color=colors[indices[i]];row.append([color.r,color.g,color.b]);triangles.append(row)
  result.append({"name":shape,"triangles":triangles})
 var file:=FileAccess.open(args[0],FileAccess.WRITE)
 file.store_string(JSON.stringify(result));file.close()
 quit()
