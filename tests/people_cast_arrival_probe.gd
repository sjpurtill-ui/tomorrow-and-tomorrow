extends Control
## Native temporal review of the actual renderer/cast. Test-only visibility
## isolation removes other sprites from close crops, never people from the cast.
const Costumes=preload("res://scripts/hud/people_settlement_costumes.gd")
const OUTPUT="res://artifacts/people-cast-journey"
var town:Control
var records:Array[Dictionary]=[]
var failures:Array[String]=[]

func _ready()->void:
	if "test" not in OS.get_user_data_dir().to_lower():push_error("Test user data required");get_tree().quit(2);return
	var source:="res://scripts/hud/people_settlement_view.gd"
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--view-script="):source=arg.trim_prefix("--view-script=")
	var View:Script=load(source)
	get_window().size=Vector2i(1600,1000);get_window().content_scale_size=Vector2i(1600,1000)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	town=View.new();town.size=Vector2(1600,1000);add_child(town)
	town.configure({"plots":[],"routes":[],"population":100,"allocations":{"Logistics":100},"origin":Vector3.ZERO,"clothing_knowledge":[],"clothing_context":{"coverage":0.0}})
	town.set_process(false)
	var before:=var_to_bytes([GameState.population_allocations,GameState.settlement_plots,GameState.settlement_routes])
	var original_batch:MultiMesh=town._people.multimesh
	for role:String in Costumes.ROLES:
		var origin:="Food" if role=="Logistics" else "Logistics"
		town._cast.set_weights({origin:100},false)
		town.set_workforce({origin:88,role:12},true)
		town.focus_role(role);town._target=town._desired_target;town._span=town._desired_span;town._position_camera();town._move_people()
		var selected:Dictionary={}
		for person:Dictionary in town._cast.people:
			if person.role==role and person.moving and not selected.has(int(person.sex)):selected[int(person.sex)]=int(person.id)
		if selected.size()!=2:failures.append(role+": transfer did not include both sexes");continue
		var start:Array=town._cast.population()
		var sheet:=_sheet(role)
		for sex:int in [0,1]:
			town._cast.people.assign(start.duplicate(true))
			var id:int=selected[sex];var person:Dictionary=town._cast.people[id]
			var distance:=_remaining(person)
			town._cast.advance(maxf(0,distance/.004-.12));town._move_people()
			var crop:=Rect2i();var previous:=Vector3.ZERO;var previous_moving:=false
			var frames:Array[Image]=[]
			for index in 5:
				if index>0:town._cast.advance([0.0,.06,.05,.02,.07][index])
				town._move_people();person=town._cast.people[id]
				var transform:Transform3D=town._people.multimesh.get_instance_transform(id)
				var custom:Color=town._people.multimesh.get_instance_custom_data(id)
				var fields:=Costumes.instance_fields(custom.b)
				if fields.sex!=sex or fields.role!=Costumes.ROLES.find(role):failures.append(role+": identity changed at arrival")
				if int(custom.g)!=(0 if person.moving else 20):failures.append(role+": pose does not match moving/work state")
				if index>0 and previous_moving and bool(person.moving):
					var movement:=transform.origin-previous
					if movement.length()>.000001 and transform.basis.z.normalized().dot(movement.normalized())<.95:failures.append(role+": heading opposes actual travel")
				previous=transform.origin;previous_moving=person.moving
				var feet:Vector2=town.camera.unproject_position(transform.origin)
				if index==0:crop=Rect2i(Vector2i(feet)-Vector2i(75,120),Vector2i(160,150))
				# Hide other rendered instances only for the unchanged-camera crop.
				for other in 100:
					if other!=id:town._people.multimesh.set_instance_transform(other,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*.0000001),Vector3(0,-1,0)))
				for wait in 3:await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var frame:Image=town.view.get_texture().get_image().get_region(crop)
				frames.append(frame)
				records.append({"role":role,"sex":sex,"id":id,"time_to_arrival":[-.12,-.06,-.01,.01,.08][index],"moving":person.moving,"position":person.position,"feet":feet,"custom":custom,"scale":transform.basis.x.length()})
				if town._cast.people.size()!=100:failures.append("Cast size changed")
			_show_row(sheet,sex,frames)
			if person.moving:failures.append(role+": selected person failed to arrive")
			# The encoded custom value crosses the vertex/fragment boundary. Its
			# harmless floating-point error must never select another role or sex.
			var exact_custom:Color=town._people.multimesh.get_instance_custom_data(id)
			for epsilon:float in [-.0001,.0001]:
				var perturbed:=exact_custom;perturbed.b+=epsilon
				town._people.multimesh.set_instance_custom_data(id,perturbed)
				for wait in 3:await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var stable:Image=town.view.get_texture().get_image().get_region(crop)
				if stable.get_data()!=frames.back().get_data():failures.append(role+": sub-integer custom precision changed the rendered identity")
			town._people.multimesh.set_instance_custom_data(id,exact_custom)
		await _save_sheet(sheet,role.to_lower()+"-arrival")
		town._cast.advance(60);town._move_people()
		if town._people.multimesh!=original_batch:failures.append(role+": changing allocations replaced the render batch")
		if town._people.multimesh.instance_count!=100:failures.append(role+": render batch is not exactly100")
		for person:Dictionary in town._cast.people:
			var custom:Color=town._people.multimesh.get_instance_custom_data(int(person.id))
			var expected:=Costumes.instance_code(Costumes.ROLES.find(String(person.role)),int(person.sex))
			if int(custom.g)!=20 or not is_equal_approx(custom.b,expected):failures.append(role+": settled GPU instance does not match role/sex/work pose")
		await _save_scene(role.to_lower()+"-worksite")
	town.reset_view();town._target=town._desired_target;town._span=town._desired_span;town._position_camera();town._move_people()
	await _save_scene("overview")
	if before!=var_to_bytes([GameState.population_allocations,GameState.settlement_plots,GameState.settlement_routes]):failures.append("Probe changed live model records")
	var output:=FileAccess.open(OUTPUT+"/report.json",FileAccess.WRITE);output.store_string(JSON.stringify({"records":records,"failures":failures,"view":source,"note":"Same ID before/after actual arrival; normal .0012 sprite scale. Close crops hide other instances only; full worksite views retain all100."},"\t"));output.close()
	print("PEOPLE_CAST_ARRIVAL ",records.size()," samples; ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _remaining(person:Dictionary)->float:
	var path:PackedVector2Array=person.path;var segment:=int(person.segment)
	var distance:=Vector2(person.position).distance_to(path[segment+1])
	for index in range(segment+1,path.size()-1):distance+=path[index].distance_to(path[index+1])
	return distance

func _sheet(role:String)->Control:
	var sheet:=ColorRect.new();sheet.color=Color("303b36");sheet.size=Vector2(1600,1000);add_child(sheet)
	var title:=Label.new();title.text="PRIVATE TEST · "+role+" · same person approaches and starts work";title.position=Vector2(24,20);title.add_theme_font_size_override("font_size",24);sheet.add_child(title)
	for index in 5:
		var label:=Label.new();label.text=["−0.12s","−0.06s","−0.01s","+0.01s","+0.08s"][index];label.position=Vector2(200+index*240,75);sheet.add_child(label)
	return sheet

func _show_row(sheet:Control,sex:int,frames:Array[Image])->void:
	var label:=Label.new();label.text="Woman" if sex==0 else "Man";label.position=Vector2(24,150+sex*280);sheet.add_child(label)
	for index in frames.size():
		var picture:=TextureRect.new();picture.texture=ImageTexture.create_from_image(frames[index]);picture.position=Vector2(180+index*240,100+sex*280);picture.size=Vector2(160,150);sheet.add_child(picture)

func _save_sheet(sheet:Control,name:String)->void:
	for i in 3:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+name+".png")
	sheet.queue_free();await get_tree().process_frame

func _save_scene(name:String)->void:
	for i in 3:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	town.view.get_texture().get_image().save_png(OUTPUT+"/"+name+".png")
