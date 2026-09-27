extends "res://scripts/hud/content/dock_content_base.gd"
const Model:=preload("res://scripts/scout_archive.gd")
var view_state:Dictionary={"query":"","filter":0,"order":0,"page":0}
func meta()->Dictionary:
	return {"eyebrow":"What our scouts brought home","title":"Every telling","subtabs":["Reports"]}
func tab(_sub:int)->Dictionary:
	return {"kpis":[],"brief":{},"blocks":[{"type":"scout_archive","reports":CivilizationSystem.scout_reports,"view_state":view_state,"on_open":func(report:Dictionary)->void: hud.open_detail(preload("res://scripts/hud/content/dock_detail_scout_report.gd").new(terrain,hud,report,self))},{"type":"text","text":"The newest %d tellings are kept in full. What older parties found stays on the map and in our other records." % CivilizationSystem.SCOUT_REPORT_LIMIT}]}
func signature()->Array:
	return Model.revision(CivilizationSystem.scout_reports)
