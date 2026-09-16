extends RefCounted
const Water=preload("res://scripts/water_conveyance.gd")
const Works=preload("res://scripts/water_waste_works.gd")

static func build_all(parent:VBoxContainer,context:Dictionary)->void:
	build(parent,context)
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
		var city_id:=String(city.id)
		var local_context:=preload("res://scripts/civilization_day.gd").context(WorldSimulation.settlements._record_position(city))
		WorldSimulation.settlements.with_city_resources(city_id,func()->void:
			build(parent,local_context,city_id,String(city.get("name","Settlement"))))

static func build(parent:VBoxContainer,context:Dictionary,city_id:String="",city_name:String="")->void:
	var show_water:bool=not Water.data().lines.is_empty() or "gravity_conduit_grade_control" in Water.adopted()
	var show_works:bool=not Works.data().works.is_empty()
	for kind:String in Works.ORDER:
		if Works.adopted(String(Works.SPECS[kind].discovery)):show_works=true
	if not show_water and not show_works:return
	if show_works:_build_works(parent,context,city_id,city_name)
	if not show_water:return
	var report:=Label.new();report.text=(city_name+"\n" if not city_name.is_empty() else "")+Water.describe();report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(report)
	var destination:Vector3=context.get("origin",WorldSimulation.state.settlement_founded_at)
	var height_at:Callable=context.get("terrain_height_at",Callable())
	for source:Dictionary in context.get("water_conveyance_sources",[]):
		for material:String in ["ceramic","timber"]:
			var terms:=Water.quote(source,destination,height_at,material)
			var button:=Button.new()
			button.text="Build %s water line · %s" % [material,String(source.get("kind","source"))]
			button.disabled=not bool(terms.get("ok",false))
			button.tooltip_text=String(terms.get("error",""))
			if not button.disabled:
				var bill:Array[String]=[]
				for item:String in terms.cost:bill.append("%.1f %s" % [float(terms.cost[item]),item])
				button.tooltip_text="%.2f km · %.1f construction work\n%s" % [float(terms.length_km),float(terms.work_required),", ".join(bill)]
			button.pressed.connect(func()->void:
				if not city_id.is_empty():
					var city:Dictionary=WorldSimulation.settlements.settlement_record(city_id)
					if city.is_empty() or not String(city.get("occupied_by","")).is_empty():
						report.text="This settlement is no longer available for construction.";return
				WorldSimulation.settlements.with_city_resources(city_id,func()->void:
					var result:=Water.install(source,destination,height_at,material)
					report.text=(city_name+"\n" if not city_name.is_empty() else "")+String(result.get("message",result.get("error","")))+"\n"+Water.describe()
					if bool(result.get("ok",false)):button.disabled=true))
			parent.add_child(button)

static func _build_works(parent:VBoxContainer,context:Dictionary,city_id:String,city_name:String)->void:
	var report:=Label.new()
	report.text=(city_name+"\n" if not city_name.is_empty() else "")+Works.describe()
	report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(report)
	for kind:String in Works.ORDER:
		var spec:Dictionary=Works.SPECS[kind]
		if not Works.adopted(String(spec.discovery)) or not Works.work_for(kind).is_empty():continue
		var terms:=Works.quote(kind,context)
		var button:=Button.new();button.text="Build "+String(spec.name);button.disabled=not bool(terms.get("ok",false));button.tooltip_text=String(terms.get("error",""))
		if not button.disabled:
			var bill:Array[String]=[]
			for item:String in terms.cost:bill.append("%.1f %s" % [float(terms.cost[item]),item])
			button.tooltip_text="%.1f construction work\n%s" % [float(terms.work_required),", ".join(bill)]
		button.pressed.connect(_begin_work.bind(kind,context,city_id,city_name,report,button))
		parent.add_child(button)

static func _begin_work(kind:String,context:Dictionary,city_id:String,city_name:String,report:Label,button:Button)->void:
	if not city_id.is_empty():
		var city:Dictionary=WorldSimulation.settlements.settlement_record(city_id)
		if city.is_empty() or not String(city.get("occupied_by","")).is_empty():
			report.text="This settlement is no longer available for construction.";return
	WorldSimulation.settlements.with_city_resources(city_id,func()->void:
		var result:=Works.begin(kind,context)
		report.text=(city_name+"\n" if not city_name.is_empty() else "")+String(result.get("message",result.get("error","")))+"\n"+Works.describe()
		if bool(result.get("ok",false)):button.disabled=true)
