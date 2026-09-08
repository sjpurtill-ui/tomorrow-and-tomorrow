extends "res://scripts/hud/military_service_panel.gd"

func _init()->void:
	domain="navy"

func _build_service()->void:
	var task_forces:=_page("Fleets")
	_label(task_forces,"FLEETS & SEA MISSIONS",17)
	_force_controls(task_forces,"Return to home port")
	_label(task_forces,"Patrols find hostile ships. Strike forces wait in port for contact; escorts protect convoys. Repairs require returning to port.",13)
	organization_controls=VBoxContainer.new();task_forces.add_child(organization_controls)
	companion_picker=_option(organization_controls)
	_button(organization_controls,"Join selected companion's fleet",func():_report(op.group_fleet(selected_id,int(_selected(companion_picker)))))
	_button(organization_controls,"Merge task forces in port",func():_report(op.merge_forces(selected_id,int(_selected(companion_picker)))))
	_button(organization_controls,"Split task force in port",func():_report(op.split_force(selected_id)))
	var ports:=_page("Ports")
	_production_controls(ports,"port","Commission ships and crews")
	_button(ports,"Disband task force in port",func():_report(op.disband(selected_id)))
	var transport:=_page("Convoys")
	_transport_controls(transport,"Sea transport uses cargo capacity and a navigable sea route. Assemble troops at the port. Hostile landings need preparation and naval control; the general commands troops ashore.")
	reports=_label(_page("Reports"),"",13)

func _force_summary(force:Dictionary)->String:
	var base:Dictionary=op.base(int(force.base_id))
	return "%s · Fleet %d\n%d ships · %d crew\nHome port: %s\nReadiness %d%% · hull condition %d%%\n%s\nFuel %d/day · reserve %d" % [force.name,int(force.get("fleet_id",force.id)),op.hardware(force),op.crew(force),base.get("name","Unavailable"),roundi(float(force.training)*100),roundi(float(force.condition)*100),force.status,op.fuel_cost(force),int(MilitaryCampaign.military_consumables.get("fuel",0))]
