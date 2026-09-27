extends "res://scripts/hud/military_service_panel.gd"

func _init()->void:
	domain="navy"

func _build_service()->void:
	var task_forces:=_page("Fleets")
	_label(task_forces,"Fleets and where they sail",17)
	_force_controls(task_forces,"Bring them home to port")
	_label(task_forces,"Patrols look for enemy ships, strike fleets wait in port until one is found, and escorts guard our transports. Damaged ships mend only in port. How the fleets are grouped and how they fight is for their commanders.",13)
	var ports:=_page("Ports")
	_production_controls(ports,"port","Crew the new ships")
	_button(ports,"Build timber-vessel dock access",func():_report(op.build_dock(int(_selected(base_picker)))))
	var transport:=_page("Transports")
	_transport_controls(transport,"Ships carry soldiers and food along open sea routes. Gather the soldiers at the port first. Landing on a hostile shore needs control of the sea there; ashore, the general takes command.")
	reports=_label(_page("Reports"),"",13)

func _force_summary(force:Dictionary)->String:
	var base:Dictionary=op.base(int(force.base_id))
	var summary:="%s: %d ships, %d crew, home port %s.\nTraining %d%%, hulls %d%% sound. %s" % [force.name,op.hardware(force),op.crew(force),base.get("name","none"),roundi(float(force.training)*100),roundi(float(force.condition)*100),P.first_up(String(force.status))]
	if op.fuel_cost(force)>0:summary+="\nThey burn %d fuel a day; %d is in our stores." % [op.fuel_cost(force),int(MilitaryCampaign.military_consumables.get("fuel",0))]

	var survey:Dictionary=force.get("hull_survey",{})
	if not survey.is_empty():summary+="\nHull survey in %s found them %d%% sound." % [EraWords.when(int(survey.day)),roundi(float(survey.condition)*100)]
	return summary

func _refresh_status()->void:
	super._refresh_status()
	var port:Dictionary=op.base(int(_selected(base_picker)))
	var dock:Dictionary=port.get("dock_service",{})
	if dock.is_empty():return
	base_status.text+="\nThe timber-vessel lift is %d%% built (for war canoes and ram galleys only)." % roundi(100.0*float(dock.work_done)/maxf(1.0,float(dock.work_required)))
	if not op.Dock.building(port):base_status.text+="\nIt can lift %.1f of %.1f ships more today." % [op.Dock.remaining_access(port,int(WorldSimulation.state.elapsed_days)),op.Dock.DAILY_ACCESS]
