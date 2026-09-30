extends RefCounted
## Production view of the land kits: recipe, work days, ammunition and
## delivery load for each, read from the equipment ledger (one row per kit)
## and the armor kits. The gate shown is the one production actually checks,
## military_unit_catalog.gd EQUIPMENT_GATES.

const Ledger:=preload("res://scripts/equipment_ledger.gd")
const ArmorKits:=preload("res://scripts/armor_equipment.gd")
const UnitCatalog:=preload("res://scripts/military_unit_catalog.gd")

static var ITEMS:Dictionary=_build()

static func _build()->Dictionary:
	var items:={}
	for id:String in ArmorKits.KITS:
		var armor:Dictionary=(ArmorKits.KITS[id] as Dictionary).duplicate(true)
		armor["gate"]=String(UnitCatalog.EQUIPMENT_GATES.get(id,armor.get("gate","")))
		items[id]=armor
	for id:String in Ledger.KITS:
		var kit:Dictionary=(Ledger.KITS[id] as Dictionary).duplicate(true)
		kit["gate"]=String(UnitCatalog.EQUIPMENT_GATES.get(id,""))
		items[id]=kit
	return items
