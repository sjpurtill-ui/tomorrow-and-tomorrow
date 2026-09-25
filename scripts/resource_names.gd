extends RefCounted
## What the people call a material. Until they know what an ore holds, it is
## named by what they can see; the metal's name waits for the method that finds
## the metal in it. Save and simulation keys never change, only the words shown.

## resource key -> discoveries that teach its metal name (any one), and the
## plain name used before that.
const ERA_NAMES:={
	"Copper Ore":{"ids":["copper_outcrop_signs","ore_assaying","copper_smelting"],"name":"Green-stained Stone"},
	"Lead Ore":{"ids":["lead_smelting"],"name":"Heavy Grey Stone"},
	"Tin Ore":{"ids":["tin_smelting","bronze_alloying"],"name":"Heavy Black Stone"},
	"Iron Ore":{"ids":["bloomery_smelting","iron_assaying","forge_welding"],"name":"Heavy Red Stone"},
}


static func _knows(ids:Array,known:Variant=null)->bool:
	var have:Array=known if known is Array else (GameState.known_discoveries if Engine.get_main_loop()!=null else [])
	for id in ids:
		if have.has(String(id)): return true
	return false


## True once the people can name the metal in this material (always true for
## materials without an era name).
static func knows_metal(resource_name:String,known:Variant=null)->bool:
	var rule:Dictionary=ERA_NAMES.get(resource_name,{})
	return rule.is_empty() or _knows(rule.ids,known)


## The shown name of a material for the player's people (or for `known`).
static func label(resource_name:String,known:Variant=null)->String:
	var rule:Dictionary=ERA_NAMES.get(resource_name,{})
	if not rule.is_empty() and not _knows(rule.ids,known): return String(rule.name)
	return base_name(resource_name)


## The shown name once nothing is withheld.
static func base_name(resource_name:String)->String:
	return "Plant Fiber" if resource_name=="Fiber Plants" else resource_name


## Retells ore names inside a sentence the same way.
static func plain(text:String,known:Variant=null)->String:
	var out:=text
	for resource:String in ERA_NAMES:
		if out.findn(resource)<0 or _knows(ERA_NAMES[resource].ids,known): continue
		var shown:=String(ERA_NAMES[resource].name)
		out=out.replace(resource.to_upper(),shown.to_upper()).replace(resource,shown).replacen(resource,shown.to_lower())
	return out
