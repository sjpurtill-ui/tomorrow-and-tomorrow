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
	for project:Dictionary in Construction._settlement_definitions():
		var title:=String(project.name)
		if title in GameState.settlement_completed:continue
		var discovery:=String(project.get("discovery",""))
		if not discovery.is_empty() and discovery not in GameState.known_discoveries:continue
		var active:=title==String(current.get("name",""))
		var progress:=clampf(float(GameState.settlement_projects.get(title,0))/float(project.days),0,1)
		items.append({"name":title,"value":"%d%%" % roundi(progress*100),"ratio":progress,"color":Tokens.TEAL if active else Tokens.MUTED,"tip":("In progress" if active else "Waiting for labor, materials or prerequisites")+" · "+String(project.get("effect",""))})
	return {"kpis":[{"label":"BUILDERS","value":str(GameState.population_allocations.get("Construction",0)),"accent":Tokens.GOLD},{"label":"COMPLETE","value":str(GameState.settlement_completed.size()),"accent":Tokens.GREEN}],"blocks":[{"type":"bars","heading":"DELEGATED PROJECTS","note":"leader sets priority","items":items}]}
func signature()->Array:
	return [GameState.selected_player_settlement_id,GameState.settlement_site_committed,GameState.settlement_projects.duplicate(true),GameState.settlement_completed.duplicate(),GameState.population_allocations.duplicate(),GameState.elapsed_days]
