extends "res://scripts/hud/content/dock_content_base.gd"
## One of the twelve capacities, in the Health dock's manner: its line over the
## years with marks where something changed, why it grew or fell, and what it
## is made of now. Opened from Culture > Society's strengths & needs. Every
## number comes from the capacity ledger (society_model.gd) and its monthly
## history (capacity_history.gd); this page only reads them.

const History:=preload("res://scripts/capacity_history.gd")
const Words:=preload("res://scripts/hud/capacity_words.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Society:=preload("res://scripts/society_model.gd")

var dynamic_id:=""

func _init(terrain_node:Node,hud_node:Control,dynamic:String="logistics")->void:
	super(terrain_node,hud_node)
	dynamic_id=dynamic

func meta()->Dictionary:
	return {"eyebrow":Words.plain_name(dynamic_id),"title":Words.title(dynamic_id),"subtabs":[]}

func tab(_sub:int)->Dictionary:
	var model:Object=DiscoverySystem.society_model
	var ledger:Dictionary=model.capacity_ledger().get(dynamic_id,{"value":0.0,"drivers":{},"clamp":0.0})
	var now:=float(ledger.value)*100.0
	var recorded:=History.months(dynamic_id)
	var told:=History.changes(dynamic_id,6)
	return {"kpis":_kpis(now,recorded),"blocks":[_chart(recorded,told,model),_why(told),_made_of(ledger,model)]}

func _kpis(now:float,recorded:Array[Dictionary])->Array:
	var change:=History.change_over(dynamic_id,365)
	var points:=float(change.points)
	var then:=float(change.from)
	var low:=now
	var high:=now
	for month:Dictionary in recorded:
		low=minf(low,float(month.value));high=maxf(high,float(month.value))
	var ago:=("A WINTER AGO" if EraWords.hearth() else "A YEAR AGO") if bool(change.full) else "SINCE %s" % EraWords.when(int(change.since)).to_upper()
	var steady:=absf(points)<0.05
	return [
		{"label":"NOW","value":Words.percent(now),"delta":"today","accent":Tokens.capacity_color(now),"tip":_definition()},
		{"label":ago,"value":Words.percent(then),"delta":"steady since then" if steady else "%s points since then" % Words.points(points),
			"delta_color":Tokens.MUTED if steady else (Tokens.GREEN_TEXT if points>0.0 else Tokens.RED_TEXT),"accent":Tokens.TEAL,
			"tip":"%s then, %s now." % [Words.percent(then),Words.percent(now)]},
		{"label":"ON RECORD","value":"%d–%d%%" % [roundi(low),roundi(high)],"delta":"lowest and highest","accent":Tokens.AMBER,
			"tip":"The lowest and highest it has been since the record began, %s." % EraWords.when(int(recorded[0].day))},
	]

## The line over the recorded months, marked where something changed.
func _chart(recorded:Array[Dictionary],told:Array[Dictionary],model:Object)->Dictionary:
	var by_day:Dictionary={}
	for change:Dictionary in told: by_day[int(change.day)]=change
	var reads:=_effects_read(model)
	var items:Array=[]
	var previous_day:=-1
	var previous_value:=float(recorded[0].value)
	for month:Dictionary in recorded:
		var day:=int(month.day)
		var mark:=int(month.mark)
		var label:=""
		if by_day.has(day): label=Words.change_name(by_day[day])
		elif mark==History.MARK_DISCOVERY: label=_learned_label(previous_day,day,reads)
		items.append({"day":day,"value":float(month.value),"delta":float(month.value)-previous_value,
			"marker_type":String(History.MARK_NAMES[mark]) if mark>0 and mark<History.MARK_NAMES.size() else "","marker_label":label})
		previous_day=day
		previous_value=float(month.value)
	var name:=Words.title(dynamic_id)
	return {"type":"line_chart","heading":"%s over the years" % name,
		"note":"counted each moon, up to 40 winters back" if EraWords.hearth() else "counted each month, up to 40 years back",
		"items":items,"value_key":"value","min_span":10.0,"floor":0.0,"ceiling":100.0,
		"describe":func(point:Dictionary)->String:return "%s: %s" % [EraWords.when(int(point.get("day",0))),Words.percent(float(point.get("value",0.0)))],
		"legend":[{"kind":"discovery","text":"a new way"},{"kind":"up","text":"better"},{"kind":"down","text":"worse"},{"kind":"building","text":"a work built"},{"kind":"decree","text":"a decree or office"},{"kind":"crisis","text":"hard times"}],
		"tip":"%s, recorded each month. Hover the line to read a month; the marks show what moved it." % name}

## Practices learned between two recorded months that feed this capacity.
func _learned_label(from_day:int,to_day:int,reads:Dictionary)->String:
	var names:PackedStringArray=[]
	for entry:Variant in GameState.discovery_log:
		if not entry is Dictionary: continue
		var day:=int((entry as Dictionary).get("day",-1))
		if day<=from_day or day>to_day: continue
		var feeds:=false
		for effect_name in ((entry as Dictionary).get("effects",{}) as Dictionary):
			if reads.has(String(effect_name)): feeds=true
		if feeds: names.append(Words.practice_name(String((entry as Dictionary).get("id",""))))
		if names.size()>=3: break
	return ("Learned: %s" % ", ".join(names)) if not names.is_empty() else "A new way learned"

## The practice totals this capacity reads, found from the one formula itself.
func _effects_read(model:Object)->Dictionary:
	var inputs:Dictionary=model.capacity_inputs()
	for key in inputs: inputs[key]=0.3 if not String(key).begins_with("officials:") and not String(key).begins_with("values:") else 0.0
	inputs["fields"]=6.0;inputs["works"]=3.0
	var reads:Dictionary={}
	var base:=Society.capacity_value(dynamic_id,inputs)
	for effect_id:String in Society.CAPACITY_EFFECTS:
		var key:="fx:"+effect_id
		inputs[key]=0.35
		if absf(Society.capacity_value(dynamic_id,inputs)-base)>0.0000001: reads[effect_id]=true
		inputs[key]=0.3
	return reads

## The latest told changes: what moved it, in plain words and points.
func _why(told:Array[Dictionary])->Dictionary:
	var name:=Words.title(dynamic_id)
	if told.is_empty():
		var gathering:=History.gathering(dynamic_id)
		var so_far:=float(gathering.get("d",0.0))*100.0
		var text:="Nothing has moved it a whole point since the record began."
		if absf(so_far)>=0.05: text="Small changes are adding up: %s so far." % Words.points(so_far)
		return {"type":"text","heading":"Why it grew or fell","text":text}
	var rows:Array=[]
	for change:Dictionary in told:
		var points:=float(change.change)
		var mark:=int(change.mark)
		var events:PackedStringArray=[]
		for code:Array in change.events: events.append(Words.event(code))
		var detail:=_short("; ".join(events)) if not events.is_empty() else _third_reason(change)
		rows.append({"name":Words.change_name(change),"sub":EraWords.when(int(change.day)),"detail":detail,
			"value":Words.points(points),"value_color":Tokens.GREEN_TEXT if points>0.0 else Tokens.RED_TEXT,
			"accent":_mark_color(mark,points),"tip":Words.change_sentence(name,change)})
	return {"type":"rows","heading":"Why it grew or fell","note":"latest first","items":rows}

func _third_reason(change:Dictionary)->String:
	var shown:=0
	for reason:Array in change.reasons:
		if String(reason[0])=="~": continue
		shown+=1
		if shown==3: return "Also: "+Words.reason(String(reason[0]),float(reason[1]))
	return ""

## A visible line keeps to twelve words; the tooltip says the rest.
static func _short(text:String)->String:
	var words:=text.split(" ",false)
	if words.size()<=12: return text
	return " ".join(words.slice(0,11))+" …"

func _mark_color(mark:int,change:float)->Color:
	match mark:
		History.MARK_DISCOVERY: return Tokens.GOLD
		History.MARK_BUILDING: return Tokens.TEAL
		History.MARK_DECREE: return Tokens.VIOLET
		History.MARK_CRISIS: return Tokens.RED
	return Tokens.BLUE if change>0.0 else Tokens.RED

## What the capacity is made of now: each part and its points. The parts add
## up to the value; a limit that holds it back is said.
func _made_of(ledger:Dictionary,model:Object)->Dictionary:
	var drivers:Dictionary=ledger.drivers
	var keys:Array=drivers.keys()
	keys.sort_custom(func(a,b)->bool:return float(drivers[a])>float(drivers[b]))
	var peak:=0.000001
	for key in keys: peak=maxf(peak,absf(float(drivers[key])))
	# What each practice adds now, for the practice totals among the parts.
	var effect_ids:Array=[]
	for key in keys:
		if String(key).begins_with("fx:"): effect_ids.append(String(key).substr(3))
	var sources:Dictionary=model.effect_sources(model.practice_basis(),effect_ids) if not effect_ids.is_empty() else {}
	var bars:Array=[]
	var small:=0.0
	for key in keys:
		var amount:=float(drivers[key])*100.0
		if absf(amount)<0.05:
			small+=amount
			continue
		bars.append({"name":Words.part_name(String(key)),"value":Words.points(amount) if amount<0.0 else Words.amount(amount),"ratio":absf(float(drivers[key]))/peak,
			"color":Tokens.TEAL if amount>=0.0 else Tokens.RED,"tip":_part_tip(String(key),amount,sources)})
	if absf(small)>=0.05:
		bars.append({"name":"Small parts together","value":Words.points(small) if small<0.0 else Words.amount(small),"ratio":absf(small/100.0)/peak,"color":Tokens.TEAL if small>=0.0 else Tokens.RED,"tip":"Parts too small to name one by one."})
	var clamp_points:=float(ledger.get("clamp",0.0))*100.0
	if absf(clamp_points)>=0.05:
		bars.append({"name":"Held at the limit","value":Words.points(clamp_points),"ratio":absf(clamp_points/100.0)/peak,"color":Tokens.AMBER,
			"tip":"The parts come to %s, but a capacity stays between 1 and 100." % Words.percent(float(ledger.value)*100.0-clamp_points)})
	return {"type":"bars","heading":"What it is made of now","note":"in points, adding up to %s" % Words.percent(float(ledger.value)*100.0),"items":bars}

func _part_tip(key:String,amount:float,sources_by_effect:Dictionary)->String:
	var name:=Words.part_name(key)
	var said:="%s adds %s points." % [name,Words.amount(amount)] if amount>=0.0 else "%s takes away %s points." % [name,Words.amount(amount)]
	if key.begins_with("fx:"):
		var sources:Dictionary=sources_by_effect.get(key.substr(3),{})
		var places:Array=sources.keys()
		places.sort_custom(func(a,b)->bool:return absf(float(sources[a]))>absf(float(sources[b])))
		var names:PackedStringArray=[]
		for place in places.slice(0,3): names.append(Words.practice_name(String(GameState.known_discoveries[int(place)])))
		if not names.is_empty(): said+=" It comes from what we know and practise: %s%s." % [", ".join(names)," and others" if places.size()>3 else ""]
	elif key=="officials":
		var holders:PackedStringArray=[]
		for office in GameState.leadership_positions:
			if dynamic_id in Society.OFFICE_DYNAMICS.get(String(office),[]):
				holders.append(String((GameState.leadership_positions[office] as Dictionary).get("name",office)))
		said+=" How well those in office do their work: %s." % ", ".join(holders) if not holders.is_empty() else " No one holds an office that carries it."
	elif key=="values":
		said+=" What the people value, as they live it, adds or takes a little."
	elif key=="labor":
		said+=" It is the people's Labor, before its office holders."
	return said

func _definition()->String:
	if is_instance_valid(terrain) and terrain.has_method("_dynamic_definition"): return String(terrain._dynamic_definition(dynamic_id))
	return ""

func signature()->Array:
	var history:Dictionary=GameState.capacity_history
	var days:Variant=history.get("days",PackedInt32Array())
	var model:Object=DiscoverySystem.society_model
	return [dynamic_id,(days as PackedInt32Array).size() if days is PackedInt32Array else 0,roundi(float(GameState.society_capacities.get(dynamic_id,0.0))*10000.0),
		int(model._today.day) if model!=null else -1,EraWords.stage(),((history.get("why",{}) as Dictionary).get(dynamic_id,[]) as Array).size()]
