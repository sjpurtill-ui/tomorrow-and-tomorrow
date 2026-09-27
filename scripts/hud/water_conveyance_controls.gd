extends RefCounted
## Water and waste works a settlement can start: water lines from a nearby
## source, latrine ground, wellheads, cisterns and settling basins. Each offer
## is one plain sentence (what it does), its cost and its time, and one verb.
## The Settlement dock shows these; `build` is the plain-control form used by
## tests and any panel that wants buttons.
const Water=preload("res://scripts/water_conveyance.gd")
const Works=preload("res://scripts/water_waste_works.gd")
const Plain=preload("res://scripts/hud/production_plain.gd")

const WORK_WORDS:={
	"latrine":["Latrine ground","Dig latrines well away from the drinking water, so waste does not foul it."],
	"wellhead":["Wall the well","Wall and cap the well so runoff and animals cannot spoil it."],
	"cistern":["Rain cistern","Line a pit to catch and keep rainwater for the dry months."],
	"settling_basin":["Settling basin","Dig a basin where mud sinks out of the water before anyone drinks it."],
}
const MATERIAL_WORDS:={"ceramic":"clay pipe","timber":"wooden pipe"}

## Whether this settlement has anything to show: known methods or works begun.
static func relevant()->bool:
	if not Water.data().lines.is_empty() or "gravity_conduit_grade_control" in Water.adopted() or not Works.data().works.is_empty():return true
	for kind:String in Works.ORDER:
		if Works.adopted(String(Works.SPECS[kind].discovery)):return true
	return false

## Days of building work a new site would take with today's builders, shared
## the way the monthly construction step shares them.
static func estimate_days(work_required:float)->float:
	var builders:=maxf(0.0,WorldSimulation.state.effective_workers("Construction"))
	var efficiency:=float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",0.72))
	var sites:=1
	for line:Dictionary in Water.data().lines:
		if String(line.status)=="under_construction":sites+=1
	sites+=Works.construction_sites()
	var per_month:=builders/float(sites)*efficiency*0.10
	if per_month<=0.0001:return -1.0
	return work_required/per_month*30.0

static func cost_words(cost:Dictionary)->String:
	var parts:Array[String]=[]
	for item:String in cost:parts.append("%s %s" % [Plain.number(float(cost[item])),item.to_lower()])
	if parts.is_empty():return "nothing"
	if parts.size()==1:return parts[0]
	return ", ".join(parts.slice(0,parts.size()-1))+" and "+parts[-1]

static func time_words(work_required:float)->String:
	var days:=estimate_days(work_required)
	if days<0.0:return "no builders are free to do it yet"
	return Plain.duration_text(days)+" of building with the builders we have"

## Everything that is under way or finished, in plain sentences.
static func progress_lines()->Array[String]:
	var lines:Array[String]=[]
	for record:Dictionary in Works.data().works:
		var words:Array=WORK_WORDS.get(String(record.kind),[String(record.kind),""])
		if String(record.status)=="under_construction":
			lines.append("%s: being built, %d%% done." % [String(words[0]),roundi(float(record.work_done)/maxf(0.01,float(record.work_required))*100.0)])
		else:
			lines.append("%s: in use, %s." % [String(words[0]),_condition(float(record.condition))])
	for line:Dictionary in Water.data().lines:
		var what:=String(MATERIAL_WORDS.get(String(line.material),String(line.material)+" pipe")).capitalize()
		if String(line.status)=="under_construction":
			lines.append("%s: being laid, %d%% done." % [what,roundi(float(line.work_done)/maxf(0.01,float(line.work_required))*100.0)])
		else:
			lines.append("%s: brought in %s drinks of water today, %s." % [what,Plain.number(float(line.get("delivered_today",0.0))),_condition(float(line.condition))])
		if not String(line.get("blocker","")).is_empty():lines.append(String(line.blocker))
	return lines

static func _condition(value:float)->String:
	if value>=0.85:return "in good repair"
	if value>=0.5:return "wearing, but sound"
	if value>=0.2:return "in poor repair"
	return "nearly ruined"

## The works that can be started here, each ready to render.
## `city_id` is empty for the first settlement.
static func offers(context:Dictionary,city_id:String="")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for kind:String in Works.ORDER:
		var spec:Dictionary=Works.SPECS[kind]
		if not Works.adopted(String(spec.discovery)) or not Works.work_for(kind).is_empty():continue
		var terms:=Works.quote(kind,context)
		var words:Array=WORK_WORDS[kind]
		var ok:=bool(terms.get("ok",false))
		result.append({"id":"work:"+kind,"title":String(words[0]),"sentence":String(words[1]),
			"cost":("Costs %s; about %s." % [cost_words(terms.cost),time_words(float(terms.work_required))]) if ok else "",
			"blocked":"" if ok else _plain_error(String(terms.get("error",""))),
			"action":"Build it","on_press":begin_work.bind(kind,context,city_id) if ok else Callable()})
	var show_water:bool="gravity_conduit_grade_control" in Water.adopted()
	if show_water:
		var destination:Vector3=context.get("origin",WorldSimulation.state.settlement_founded_at)
		var height_at:Callable=context.get("terrain_height_at",Callable())
		for source:Dictionary in context.get("water_conveyance_sources",[]):
			for material:String in ["ceramic","timber"]:
				var terms:=Water.quote(source,destination,height_at,material)
				var ok:=bool(terms.get("ok",false))
				var kind:=String(source.get("kind","water source")).to_lower()
				var distance:=float(terms.get("length_km",source.get("distance_km",0.0)))
				result.append({"id":"line:%s:%s" % [String(source.get("id","")),material],
					"title":"%s from the %s" % [String(MATERIAL_WORDS[material]).capitalize(),kind],
					"sentence":"Lay a %s from the %s %s km away, so water runs to the settlement instead of being carried." % [String(MATERIAL_WORDS[material]),kind,Plain.number(distance)],
					"cost":("Costs %s; about %s." % [cost_words(terms.cost),time_words(float(terms.work_required))]) if ok else "",
					"blocked":"" if ok else _plain_error(String(terms.get("error",""))),
					"action":"Lay the pipe","on_press":install_line.bind(source,destination,height_at,material,city_id) if ok else Callable()})
	return result

static func _plain_error(error:String)->String:
	if error.begins_with("Insufficient "):
		return "Not enough "+error.trim_prefix("Insufficient ").get_slice(" for ",0).to_lower()+" in store."
	if error.begins_with("A cistern needs"):return "Needs a lining first: 2 goods, 3 lime mortar or 2 bitumen."
	if error.begins_with("A confirmed local well"):return "Needs a dug well first; walling cannot make a new source."
	if error.begins_with("Settle before"):return "Settle first."
	return error

static func _city_ready(city_id:String)->bool:
	if city_id.is_empty():return true
	var city:Dictionary=WorldSimulation.settlements.settlement_record(city_id)
	return not city.is_empty() and String(city.get("occupied_by","")).is_empty()

static func begin_work(kind:String,context:Dictionary,city_id:String)->Dictionary:
	if not _city_ready(city_id):return {"error":"This settlement can no longer build."}
	return WorldSimulation.settlements.with_city_resources(city_id,func()->Dictionary:return Works.begin(kind,context))

static func install_line(source:Dictionary,destination:Vector3,height_at:Callable,material:String,city_id:String)->Dictionary:
	if not _city_ready(city_id):return {"error":"This settlement can no longer build."}
	return WorldSimulation.settlements.with_city_resources(city_id,func()->Dictionary:return Water.install(source,destination,height_at,material))

## Every settlement's controls in one list. Kept only for the legacy materials
## overlay in local_terrain.gd until that dead panel is deleted.
static func build_all(parent:VBoxContainer,context:Dictionary)->void:
	build(parent,context)
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
		var city_id:=String(city.id)
		var local_context:=preload("res://scripts/civilization_day.gd").context(WorldSimulation.settlements._record_position(city))
		WorldSimulation.settlements.with_city_resources(city_id,func()->void:
			build(parent,local_context,city_id,String(city.get("name","Settlement"))))

## Plain controls: a sentence and one button per offer, directly under `parent`.
static func build(parent:VBoxContainer,context:Dictionary,city_id:String="",city_name:String="")->void:
	if not relevant():return
	var report:=Label.new();report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var lines:=progress_lines()
	report.text=(city_name+": " if not city_name.is_empty() else "")+("\n".join(lines) if not lines.is_empty() else "No water or waste works yet.")
	parent.add_child(report)
	for offer:Dictionary in offers(context,city_id):
		var about:=Label.new();about.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		about.text=String(offer.sentence)+" "+(String(offer.cost) if String(offer.blocked).is_empty() else String(offer.blocked))
		parent.add_child(about)
		var button:=Button.new();button.text="%s: %s" % [String(offer.action),String(offer.title).to_lower()]
		var press:Callable=offer.on_press
		button.disabled=not press.is_valid()
		button.tooltip_text=String(offer.cost) if not button.disabled else String(offer.blocked)
		button.pressed.connect(func()->void:
			var result:Dictionary=press.call()
			about.text=String(result.get("message",result.get("error","")))
			if bool(result.get("ok",false)):button.disabled=true)
		parent.add_child(button)
