extends "res://scripts/hud/military_service_panel.gd"

func _init()->void:
	domain="air"

func _build_service()->void:
	var wings:=_page("Air wings")
	_label(wings,"WINGS & AIR MISSIONS",17)
	_force_controls(wings,"Stand down sorties")
	_label(wings,"Wings fly missions from their airbase or carrier. Range coverage, weather, training and base crowding determine mission efficiency.",13)
	var bases:=_page("Airbases")
	_production_controls(bases,"airbase","Form air wing from reserve")
	companion_picker=_option(bases)
	_button(bases,"Ferry wing to selected carrier",func():_report(op.attach_carrier(selected_id,int(_selected(companion_picker)))))
	_button(bases,"Combine wings at airbase",func():_report(op.merge_forces(selected_id,int(_selected(companion_picker)))))
	_button(bases,"Split air wing at base",func():_report(op.split_force(selected_id)))
	_button(bases,"Disband wing at base",func():_report(op.disband(selected_id)))
	var airlift:=_page("Airlift")
	_transport_controls(airlift,"Transport aircraft carry supplies or eligible airborne troops. Hostile drops require air control, preparation and range. Air supply missions sustain field armies in the assigned region.")
	reports=_label(_page("Reports"),"",13)

func _force_summary(force:Dictionary)->String:
	var base:Dictionary=op.base(int(force.base_id))
	var origin:Dictionary=op.force(int(force.get("carrier_id",0)))
	if origin.is_empty():origin=base
	var coverage:=0.0
	if not force.get("region",{}).is_empty():coverage=op.R.coverage(force.region,op.point(origin),op.range_km(force))
	return "%s\n%d aircraft · %d personnel\nBased at: %s\nRange %d km · region coverage %d%%\nMission efficiency %d%% · training %d%%\n%s\nFuel %d/day · reserve %d" % [force.name,op.hardware(force),op.crew(force),origin.get("name","Unavailable"),op.range_km(force),roundi(coverage*100),roundi(float(force.get("efficiency",0))*100),roundi(float(force.training)*100),force.status,op.fuel_cost(force),int(MilitaryCampaign.military_consumables.get("fuel",0))]
