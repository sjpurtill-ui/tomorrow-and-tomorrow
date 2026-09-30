extends RefCounted
## Carts and lorries follow what the carriers cannot move (carriers.gd): the
## loads every band and garrison asks times their round trips, against what
## the Logistics workers can carry. Lorries once they can be made, else carts;
## never more than there are drivers for. With nobody short, a baggage train
## is kept ready for the next march: a cart for each READY_PER soldiers, as
## the drivers allow. The ordinary workshop planner owns material
## dependencies and paid production.
const READY_PER:=24.0
const Supply=preload("res://scripts/civilian_production_planner.gd")
const Carriers=preload("res://scripts/carriers.gd")
const P=preload("res://scripts/persistent_production.gd")
static func recommendation()->Dictionary:
	var state=WorldSimulation.state;var host=WorldSimulation.military
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	if state.effective_workers("Crafting")<=0 or state.effective_workers("Logistics")<=0:return {}
	var reading:Dictionary=host.carrier_reading()
	var held:=int(float(state.resource_stockpiles.get("Transport Carts",0)))
	var troops:=int(host.home_army.get("troops",0))+host.field_army_active_personnel()+host.occupation_active_personnel()
	var ready:=mini(int(state.population_allocations.get("Logistics",0)),ceili(float(troops)/READY_PER))
	if float(reading.demand)>float(reading.moved) and not P.recipe(host,"supply_lorry").has("error"):
		var lorries:=Carriers.wanted_from(reading,"supply_lorry")
		if lorries>0:
			var order:=Supply.supply("Supply Lorries",int(float(state.resource_stockpiles.get("Supply Lorries",0)))+lorries,{})
			if not order.is_empty():return order
	var carts:=Carriers.wanted_from(reading,"transport_cart") if float(reading.demand)>float(reading.moved) else 0
	var target:=maxi(held+carts,ready)
	if target<=held:return {}
	return Supply.supply("Transport Carts",target,{})
