extends RefCounted
## INITIATIVE WITHIN THEIR DOMAIN: an official who loves the god (and does
## not dread them) takes up their own office's business when it plainly needs
## doing, without waiting to be told: at most once every EVERY_DAYS, through
## the same path as the god's own orders (home_orders.gd perform, at the
## holder's pace), with an order card (order_tracker.gd) and a chronicle line
## that says who acted and why, in the engine's numbers. A dreading official
## waits for the god's word, and one who is neither loving nor dreading does
## their work as told. Only the god's own court: other peoples' rulers act
## through their own controllers.
##
##   office          the need it answers                         the order
##   Quartermaster   a shortage forecast within SHORTAGE_DAYS     ration the food
##   Marshal         neighbours pressing (threat >= THREAT_MIN)   camp drill at home
##   Steward         shelter for fewer than SHELTER_MIN of us     build more homes
## Static; preload. Saves one field on the official: last_initiative_day.

const HomeOrders:=preload("res://scripts/home_orders.gd")
const Tracker:=preload("res://scripts/order_tracker.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")

const LOVE_MIN:=0.70
const DREAD_MAX:=0.30
const EVERY_DAYS:=30
const SHORTAGE_DAYS:=60
const THREAT_MIN:=0.5
const SHELTER_MIN:=0.90

## Whether this official acts on their own: loving, not dreading.
static func takes_initiative(person:Dictionary)->bool:
	if person.is_empty() or int(person.get("person_id",0))<=0: return false
	return DIVINE.love_of(person)>=LOVE_MIN and DIVINE.dread_of(person)<DREAD_MAX

## What an office's business needs now, as {words, why}, or {} when nothing
## plainly calls for it (or it is already in hand).
static func need(office:String)->Dictionary:
	var state=WorldSimulation.state
	var metrics:Dictionary=state.simulation_metrics
	match office:
		"Quartermaster":
			var forecast:Dictionary=metrics.get("food_forecast_90",{}) if metrics.get("food_forecast_90") is Dictionary else {}
			var shortage:=int(forecast.get("first_shortage_day",-1))
			if shortage<=0 or shortage>SHORTAGE_DAYS: return {}
			for mod in state.active_modifiers:
				if mod is Dictionary and String((mod as Dictionary).get("id","")).begins_with("court_ration") and float((mod as Dictionary).get("until_day",0.0))>float(state.elapsed_days): return {}
			return {"words":"Ration the food","why":"the stores were forecast to run short in %d days" % shortage}
		"Marshal":
			var threat:=float(WorldSimulation.government.neighbour_threat()) if WorldSimulation.government!=null else 0.0
			if threat<THREAT_MIN: return {}
			var mc:Variant=WorldSimulation.military
			if mc==null or int(mc.home_army.get("troops",0))<=0 or not (mc.training_program as Dictionary).is_empty(): return {}
			return {"words":"Hold a camp drill for the fighters at home","why":"our neighbours press on us (%d in 100)" % roundi(threat*100.0)}
		"Steward":
			var shelter:=float(metrics.get("housing_ratio",1.0))
			if shelter>=SHELTER_MIN or not bool(WorldSimulation.direction.automatic_work): return {}
			if state.player_settlements.is_empty() or String((state.player_settlements[0] as Dictionary).get("management_focus",""))=="shelter": return {}
			return {"words":"Build more homes","why":"shelter covers only %d in 100 of us" % roundi(shelter*100.0)}
	return {}

## The month's initiatives (government_people_system.process_day, monthly):
## each loving official whose business plainly needs doing acts once, by the
## ordinary path. Returns the events for the month's list.
static func month(day:int)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if String(WorldSimulation.actor_id)!="player" or WorldSimulation.government==null: return out
	for office in ["Quartermaster","Marshal","Steward"]:
		var holder:Dictionary=WorldSimulation.state.leadership_positions.get(office,{})
		if not takes_initiative(holder): continue
		var record:Dictionary=WorldSimulation.government._person_record(int(holder.get("person_id",0)))
		if record.is_empty() or day-int(record.get("last_initiative_day",-100000))<EVERY_DAYS: continue
		var wanted:=need(office)
		if wanted.is_empty(): continue
		var reading:=HomeOrders.read(String(wanted.words))
		if reading.is_empty(): continue
		var name:=String(holder.get("name",""))
		var given:=name.get_slice(" ",0)
		var card:=Tracker.register(String(wanted.words),"initiative","",given)
		var done:=HomeOrders.perform(reading)
		Tracker.from_home(card,done,given)
		if not bool(done.get("ok",false)): continue
		record["last_initiative_day"]=day
		var title:=String(WorldSimulation.government.office_definition(office).get("title",office))
		var text:="%s, our %s, acted without waiting for your word: %s. %s" % [name,title.to_lower(),String(wanted.why),String(done.get("outcome",""))]
		var event:={"day":day,"title":"%s Acts Unbidden" % given,"description":text.strip_edges(),"domain":"institutions","severity":"notice"}
		out.append(event)
		WorldSimulation.government.record_person_memory(int(holder.get("person_id",0)),"I did not wait for the god's word: %s." % String(wanted.why),"initiative",0.55,{"emotion":"duty","outcome":"acted"})
		if Chronicle.active():
			Chronicle.record({"key":"initiative:%s:%d" % [office,day],"day":day,"title":"%s Acts Unbidden" % given,"text":text.strip_edges(),"tier":"notice","kind":"court","domain":"institutions"})
	return out
