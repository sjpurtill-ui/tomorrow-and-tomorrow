extends "res://scripts/hud/military_service_panel.gd"

func _init()->void:
	domain="air"

func _build_service()->void:
	var wings:=_page("Wings")
	_label(wings,"Wings and where they fly",17)
	_force_controls(wings,"Keep them on the ground")
	_label(wings,"Wings fly from their airfield or carrier. How far they reach, the weather, their training and a crowded airfield decide how much they get done. How the wings are grouped and how they fight is for their commanders.",13)
	var bases:=_page("Airfields")
	_production_controls(bases,"airfield","Form a wing from our stores")
	var airlift:=_page("Airlift")
	_transport_controls(airlift,"Transport aircraft carry supplies, or soldiers trained to drop from the air. A drop on enemy ground needs control of the air there. Supply flights keep our armies in that area fed.")
	reports=_label(_page("Reports"),"",13)

func _force_summary(force:Dictionary)->String:
	var base:Dictionary=op.base(int(force.base_id))
	var origin:Dictionary=op.force(int(force.get("carrier_id",0)))
	if origin.is_empty():origin=base
	var coverage:=0.0
	if not force.get("region",{}).is_empty():coverage=op.R.coverage(force.region,op.point(origin),op.range_km(force))
	return "%s: %d aircraft, %d crew, flying from %s.\nThey reach %d km and cover %d%% of their area. They get %d%% of their best done; training %d%%.\n%s\nFlight fuel: %d used today, %d a day on a mission, %d in our stores." % [force.name,op.hardware(force),op.crew(force),origin.get("name","nowhere yet"),op.range_km(force),roundi(coverage*100),roundi(float(force.get("efficiency",0))*100),roundi(float(force.training)*100),String(force.status),int(force.get("fuel_used",0)),op.fuel_cost(force),int(MilitaryCampaign.military_consumables.get("fuel",0))]
