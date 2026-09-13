extends RefCounted
const Water=preload("res://scripts/water_conveyance.gd")

static func build(parent:VBoxContainer,context:Dictionary)->void:
	if Water.data().lines.is_empty() and "gravity_conduit_grade_control" not in Water.adopted():return
	var report:=Label.new();report.text=Water.describe();report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(report)
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
				var result:=Water.install(source,destination,height_at,material)
				report.text=String(result.get("message",result.get("error","")))+"\n"+Water.describe()
				if bool(result.get("ok",false)):button.disabled=true)
			parent.add_child(button)
