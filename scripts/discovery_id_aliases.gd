extends RefCounted
## Renamed research ids and stock names. Saves written before a rename still
## carry the old strings in known discoveries, adoption, research targets,
## progress, logs, stockpiles and other actors' states; load_game passes the
## payload through migrate() so those old strings become the current ids.
const ALIASES:={
	"portland_cement_clinker":"clinker_cement",
	"postmortem_caesarean_rule":"postmortem_incision_delivery",
	"living_mother_caesarean":"living_mother_incision_delivery",
	"saint_monday_custom":"idle_weekstart_custom",
	"saturday_half_holiday":"weekly_half_holiday",
	"penny_daily_press":"cheap_daily_press",
	"portland_concrete":"clinker_cement_concrete",
	"Portland Cement":"Clinker Cement",
}

static func current(id:String)->String:
	return String(ALIASES.get(id,id))

## Returns `value` with every string, array element and dictionary key that
## names an old id replaced by the current id. Other values are untouched.
static func migrate(value:Variant)->Variant:
	if value is String:
		return ALIASES.get(value,value)
	if value is Array:
		var list:Array=value
		for index in list.size():list[index]=migrate(list[index])
		return list
	if value is Dictionary:
		var dict:Dictionary=value
		for key:Variant in dict.keys():
			var migrated:Variant=migrate(dict[key])
			if key is String and ALIASES.has(key):
				dict.erase(key)
				var renamed:String=ALIASES[key]
				if dict.has(renamed) and (migrated is float or migrated is int) and (dict[renamed] is float or dict[renamed] is int):
					dict[renamed]=dict[renamed]+migrated
				elif not dict.has(renamed):
					dict[renamed]=migrated
			else:
				dict[key]=migrated
		return dict
	return value
