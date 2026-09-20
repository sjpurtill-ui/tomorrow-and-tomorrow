extends "res://scripts/hud/content/dock_content_base.gd"
const Construction:=preload("res://scripts/settlement_construction.gd")
func meta()->Dictionary:
	return {"eyebrow":"CONSTRUCTION", "title":"Buildings & infrastructure", "subtabs":["PROJECTS","COMPLETED"]}
func tab(sub:int)->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _local_tab(sub)))
func _local_tab(sub:int)->Dictionary:
	var items:Array=[]
	if sub==1:
		for title in GameState.settlement_completed:items.append({"name":String(title),"value":"Complete","accent":Tokens.GREEN})
		return {"blocks":[{"type":"rows","items":items}] if not items.is_empty() else [{"type":"text","text":"No completed buildings yet."}]}
	if not GameState.settlement_site_committed:
		return {"blocks":[{"type":"text","text":"Choose a settlement site to begin construction."},{"type":"actions","items":[{"label":"REVIEW SITE","on_press":terrain._on_settlement_action_pressed}]}]}
	var current:=Construction._current_settlement_project()
	var priority:=String(SettlementModel.settlement_record(GameState.selected_player_settlement_id).get("construction_priority",""))
	for project:Dictionary in Construction._settlement_definitions():
		var title:=String(project.name)
		if title in GameState.settlement_completed:continue
		var discovery:=String(project.get("discovery",""))
		if not discovery.is_empty() and discovery not in GameState.known_discoveries:continue
		var active:=title==String(current.get("name",""))
		var progress:=clampf(float(GameState.settlement_projects.get(title,0))/float(project.days),0,1)
		items.append({"name":title,"value":"%d%%" % roundi(progress*100),"ratio":progress,"color":Tokens.TEAL if active else Tokens.MUTED,"tip":("In progress" if active else "Waiting for labor, materials or prerequisites")+" · "+String(project.get("effect",""))})
	return {"kpis":[{"label":"BUILDERS","value":str(GameState.population_allocations.get("Construction",0)),"accent":Tokens.GOLD},{"label":"COMPLETE","value":str(GameState.settlement_completed.size()),"accent":Tokens.GREEN}],"blocks":[{"type":"bars","heading":"PROJECTS","note":"leader managed" if priority.is_empty() else "priority: "+priority,"items":items},{"type":"actions","items":[{"label":"LEADER MANAGED" if priority.is_empty() else "RETURN TO LEADER","primary":priority.is_empty(),"on_press":_priority.bind("")},focused_action("OVERRIDE PRIORITY","Optional project preference",_priority_report)]}]}
func signature()->Array:
	return [GameState.selected_player_settlement_id,GameState.settlement_site_committed,GameState.settlement_projects.duplicate(true),GameState.settlement_completed.duplicate(),GameState.population_allocations.duplicate(),GameState.elapsed_days,GameState.settlement_network_revision]

func _priority(title:String)->void:
	terrain._report_military_action(Construction.set_priority(GameState.selected_player_settlement_id,title))
	hud.request_immediate_dock_refresh()
func _priority_report()->Dictionary:
	var actions:Array=[]
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->void:
		for project:Dictionary in Construction._settlement_definitions():
			var title:=String(project.name)
			var discovery:=String(project.get("discovery",""))
			if title in GameState.settlement_completed:continue
			if not discovery.is_empty() and discovery not in GameState.known_discoveries:continue
			actions.append({"label":title,"on_press":_priority.bind(title)}))
	return {"blocks":[{"type":"actions","items":actions},{"type":"text","text":"This project takes priority when feasible. The leader continues other work while its requirements are missing."}]}
