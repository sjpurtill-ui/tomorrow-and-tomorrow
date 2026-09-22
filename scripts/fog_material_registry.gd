extends RefCounted
## Retain neither discarded terrain patches nor their GPU materials.
var references:Dictionary={}
var last_origin:Vector2=Vector2.INF
var last_texture:Texture2D

func register(material:ShaderMaterial,texture:Texture2D,world_size:Vector2,origin:Vector2)->void:
	# Prune during patch creation too: a stationary origin needs no frame updates.
	live_materials()
	references[material.get_instance_id()]=weakref(material)
	material.set_shader_parameter("discovery_mask",texture)
	material.set_shader_parameter("fog_world_size",world_size)
	material.set_shader_parameter("fog_current_origin",origin)

func live_materials()->Array[ShaderMaterial]:
	var result:Array[ShaderMaterial]=[]
	for id in references.keys():
		var material:ShaderMaterial=references[id].get_ref()
		if material==null:references.erase(id)
		else:result.append(material)
	return result

func update(texture:Texture2D,origin:Vector2,force:bool=false)->int:
	if not force and texture==last_texture and origin==last_origin:return 0
	var changed_texture:=force or texture!=last_texture
	var changed_origin:=force or origin!=last_origin
	var writes:=0
	for material:ShaderMaterial in live_materials():
		if changed_texture:material.set_shader_parameter("discovery_mask",texture);writes+=1
		if changed_origin:material.set_shader_parameter("fog_current_origin",origin);writes+=1
	last_texture=texture;last_origin=origin
	return writes
