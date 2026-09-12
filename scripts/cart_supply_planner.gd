extends RefCounted
## Vehicle acquisition follows actual military delivery demand and assigned staff.
## The ordinary workshop planner owns material dependencies and paid production.
const Supply=preload("res://scripts/civilian_production_planner.gd")
static func recommendation()->Dictionary:
	var state=WorldSimulation.state;var host=WorldSimulation.military
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	if state.effective_workers("Crafting")<=0 or state.effective_workers("Logistics")<=0:return {}
	var troops:=int(host.home_army.get("troops",0))+host.field_army_active_personnel()+host.occupation_active_personnel()
	if troops<=0:return {}
	var target:=mini(int(state.population_allocations.get("Logistics",0)),ceili(float(troops)/24.0))
	if target<=0 or float(state.resource_stockpiles.get("Transport Carts",0))>=target:return {}
	return Supply.supply("Transport Carts",target,{})
