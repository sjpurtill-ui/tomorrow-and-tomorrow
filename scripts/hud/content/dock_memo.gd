extends RefCounted
## A dock provider's memory of the costly parts of its page. Each part is kept
## with the exact inputs it was made from and made again the moment any of
## them differs, so a kept part is always what making it now would give.
## Inputs are plain values (numbers, strings, small arrays and dictionaries),
## deep-copied when kept, so a later change to the live state is never missed.
##
##   var memo:=preload("res://scripts/hud/content/dock_memo.gd").new()
##   var rows:Array=memo.take("rows",[known.size(),day],_make_rows)
##   block["_print"]=memo.print_of("rows")   # the dock keeps an unchanged section
##
## Tests switch memory off (DockMemo.enabled=false) to compare every page
## with one made fresh.

static var enabled:=true

## slot -> [inputs, value, revision]
var _slots:Dictionary={}
var _revision:=0

## The part made from `inputs`, kept from before when the inputs are the same.
func take(slot:String,inputs:Array,make:Callable)->Variant:
	var kept:Variant=_slots.get(slot)
	if enabled and kept!=null and (kept as Array)[0]==inputs:return (kept as Array)[1]
	var value:Variant=make.call()
	_revision+=1
	_slots[slot]=[inputs.duplicate(true),value,_revision]
	return value

## A print for a block drawn only from the part in `slot`: it changes exactly
## when the part is made again (dock_panel.section_print keeps the section's
## nodes while it holds).
func print_of(slot:String)->String:
	var kept:Variant=_slots.get(slot)
	return "%s@%d" % [slot,int((kept as Array)[2]) if kept!=null else -1]

## True when `slot` was last made from exactly these inputs.
func holds(slot:String,inputs:Array)->bool:
	var kept:Variant=_slots.get(slot)
	return enabled and kept!=null and (kept as Array)[0]==inputs

func forget(slot:String="")->void:
	if slot=="":_slots.clear()
	else:_slots.erase(slot)

## Which state a log is in, for a log that only grows at one end and is
## trimmed at the other (discovery_log, building_ledger, food_history ...):
## its size and its two end entries. Logged entries are never edited, so the
## same identity is the same log.
static func log_identity(log:Array)->Array:
	if log.is_empty():return [0]
	return [log.size(),log.front(),log.back()]
