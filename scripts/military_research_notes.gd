extends RefCounted
## What a piece of research does for the army, in the engine's own numbers,
## for its research card (discovery_system._discovery_effect_summary): the
## supply research that changes the carriers or depots, and the kits and
## units its knowledge lets us make and raise.
## Static helpers; preload.

const Carriers:=preload("res://scripts/carriers.gd")
const Depots:=preload("res://scripts/field_depots.gd")
const Ledger:=preload("res://scripts/equipment_ledger.gd")
const Catalog:=preload("res://scripts/military_unit_catalog.gd")

static var _unlocks:Dictionary={}

## "" when the research does nothing for the army directly.
static func note(id:String)->String:
	var lines:=PackedStringArray()
	match id:
		"forward_supply_depots":
			lines.append("Bands can lay field depots, %d at once. Carriers passing one eat from it, so more of each load reaches the bands beyond; they still walk the whole road." % Depots.LIMIT)
		"army_supply_magazines":
			lines.append("We can keep %d field depots instead of %d." % [Depots.MAGAZINE_LIMIT,Depots.LIMIT])
		"horse_freight_wagons":
			lines.append("Each supply cart carries up to %d loads instead of %d, as the wagons spread." % [int(Carriers.WAGON_LOAD),int(Carriers.CART_LOAD)])
		"motor_freight_lorries":
			lines.append("Supply lorries can be built: %s loads each, %d km a day." % [_grouped(int(Carriers.LORRY_LOAD)),150])
		"driverless_highway_freight":
			lines.append("Each supply lorry carries up to %d%% more, as it spreads." % roundi(Carriers.DRIVERLESS_BONUS*100.0))
	var made:Dictionary=_unlock_table().get(id,{})
	if not (made.get("kits",[]) as Array).is_empty(): lines.append("The workshops can make %s." % _list(made.kits))
	if not (made.get("units",[]) as Array).is_empty(): lines.append("We can raise %s." % _list(made.units))
	return " ".join(lines)

## {research id: {kits:[names], units:[names]}} from the equipment gates and
## the unit catalogue (built once).
static func _unlock_table()->Dictionary:
	if not _unlocks.is_empty(): return _unlocks
	var out:={}
	for kit:String in Catalog.EQUIPMENT_GATES:
		var gate:=String(Catalog.EQUIPMENT_GATES[kit])
		if gate=="" or not Ledger.has(kit): continue
		var row:Dictionary=out.get(gate,{"kits":[],"units":[]})
		(row.kits as Array).append(Ledger.label(kit))
		out[gate]=row
	for unit:String in Catalog.ARCHETYPES:
		var gate:=String((Catalog.ARCHETYPES[unit] as Dictionary).get("gate",""))
		if gate=="": continue
		var row:Dictionary=out.get(gate,{"kits":[],"units":[]})
		(row.units as Array).append(String((Catalog.ARCHETYPES[unit] as Dictionary).get("label",unit)))
		out[gate]=row
	_unlocks=out
	return out

static func _list(names:Array)->String:
	var parts:=PackedStringArray()
	for n in names: parts.append(String(n).to_lower().replace(" & "," and "))
	if parts.size()<=1: return "".join(parts)
	return ", ".join(parts.slice(0,parts.size()-1))+" and "+parts[-1]

static func _grouped(n:int)->String:
	var s:=str(n)
	var out:=""
	while s.length()>3:
		out=","+s.substr(s.length()-3)+out
		s=s.substr(0,s.length()-3)
	return s+out
