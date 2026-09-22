extends RefCounted
## First-pass physical silhouettes. Coordinates are kilometers, never screen-sized dots.
const C=preload("res://scripts/undertaking_catalog.gd")
static func render(cities:Array,parent:Node3D,height:Callable)->void:
	for city:Dictionary in cities:
		var point:Vector2=city.get("position",Vector2.ZERO)
		var index:=0
		for r:Dictionary in city.get("undertakings",[]):
			var d:=C.get_definition(String(r.id));if d.is_empty():continue
			var origin:=Vector3(point.x+.18+index*.12,0,point.y+.16)
			origin.y=float(height.call(origin.x,origin.z))+.001
			index+=1
			var root:=Node3D.new();root.name="Undertaking_"+String(r.id);root.position=origin;parent.add_child(root)
			var ratio:=clampf(float(r.progress)/float(d.work),.05,1)
			var ruin:bool=r.status in ["ruined","abandoned"]
			var color:=Color("a69270") if ruin else Color("c1aa7c")
			var shape:=String(d.form)
			var pieces:=12 if shape in ["ring","orchard","kilns"] else 5
			for i in range(pieces):
				if i>maxi(1,ceili(pieces*ratio)):continue
				var p:=Vector3.ZERO;var size:=Vector3(.012,.012,.012)
				if shape in ["ring","orchard","kilns"]:
					var a:=TAU*i/pieces;p=Vector3(cos(a)*.038,0,sin(a)*.038)
					size=Vector3(.006,.012 if shape=="ring" else .007,.006)
				elif shape in ["terrace","mound"]:p.y=i*.003;size=Vector3(.09-i*.014,.003,.07-i*.01)
				elif shape=="basin":
					p=Vector3((i%2)*.064-.032,0,(i/2)*.026-.026);size=Vector3(.006,.004,.045) if i<2 else Vector3(.065,.004,.005)
				else:p=Vector3(i*.013-.026,0,0);size=Vector3(.01,.014 if shape=="hall" else .009,.032)
				if ruin:size.y*=.25+.12*(i%3)
				var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size;mesh.mesh=box;mesh.position=p+Vector3(0,size.y/2,0)
				var material:=StandardMaterial3D.new();material.albedo_color=Color("607344") if shape=="orchard" and not ruin else color;material.roughness=1;mesh.material_override=material;root.add_child(mesh)
			var label:=Label3D.new();label.text=preload("res://scripts/undertaking_system.gd").display_name(r)+"\n"+String(r.status).capitalize();label.font_size=32;label.pixel_size=.00008
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false;label.position.y=.025;label.modulate=Color("f3e4bc");label.outline_modulate=Color("242c29");label.outline_size=8
			label.visibility_range_end=8;root.add_child(label)
