extends "res://scripts/hud/content/dock_content_base.gd"
const INTEL:=preload("res://scripts/city_intelligence.gd")
const V:=preload("res://scripts/hud/city_report_visuals.gd")
const Dossier:=preload("res://scripts/hud/city_dossier.gd")
const Orders:=preload("res://scripts/hud/city_watch_orders.gd")
const Held:=preload("res://scripts/held_town.gd")
const Ownership:=preload("res://scripts/map_ownership.gd")
var city_id:String
func _init(world:Node,shell:Control,id:String)->void:
	super(world,shell);city_id=id
func report()->Dictionary:return CivilizationSystem.city_intelligence.known("player",city_id)
func meta()->Dictionary:
	var city:=report()
	var held:=Held.report(city_id)
	if not held.is_empty():return {"eyebrow":"Burned by us" if String(held.get("kind",""))=="ruin" else "Our town","title":String(held.name),"subtabs":[]}
	return {"eyebrow":"City report","title":String(city.get("name","Reported city")),"subtabs":[]}
## The player's own primary city, for the gold home marks. Own figures are
## the player's to know; the foreign side stays on returned estimates.
func home(city:Dictionary)->Dictionary:
	var intel=CivilizationSystem.city_intelligence
	if String(city.get("civ_id",""))=="player" or String(city.get("controller",""))=="player":return {}
	var own:Dictionary=intel.truth(intel.primary_id("player"))
	return {} if own.is_empty() else {"name":String(GameState.settlement_name),"values":own.get("values",{})}
func tab(_sub:int)->Dictionary:
	var city:=report()
	if city.is_empty():return {"brief":{"title":"No report available","why":"This city has not been observed."},"blocks":[]}
	# A town we hold is reported by our own garrison, not by scouts.
	var held_report:=Held.report(city_id)
	if not held_report.is_empty():return held_tab(city,held_report)
	var today:=int(GameState.elapsed_days)
	var own:=home(city)
	var own_values:Dictionary=own.get("values",{})
	var home_name:=String(own.get("name",""))
	var rows:Array=[]
	for key in V.shown_keys():
		var field:Dictionary=city.get("fields",{}).get(key,{})
		var value:=V.words(key,field)
		var mine:=float(own_values.get(key,-1.0))
		var own_text:=""
		if mine>=0 and not field.is_empty():
			own_text="%s: %s" % [home_name,V.words(key,{"low":mine,"high":mine})]
			# Eyes inside the town can say how it stands against home.
			if V.inside(field) and key in Dossier.CAPACITY:value+=" · "+V.versus(key,field,mine,home_name)
		var seen:=int(field.get("observed_day",-1))
		rows.append({"key":key,"name":V.label(key),"value":value,"field":field,"own":mine if not field.is_empty() else -1.0,"own_text":own_text,"tip":"Seen %s. Only returned observations are shown." % Dossier.ago(today-seen) if seen>=0 else "Only returned observations are shown."})
	var fresh:=V.freshness(city,today)
	var seen_day:=int(city.get("observed_day",-1))
	var controller:=CivilizationSystem.city_intelligence.controller_label(String(city.get("controller","")))
	var held:=preload("res://scripts/map_ownership.gd").status(city)
	var dossier:={"type":"city_dossier","items":rows,"city_id":city_id,"fields":city.get("fields",{}),"home_name":home_name,
		"report":city.duplicate(true),"terrain":terrain,"on_visit":_visit_reported_city if is_instance_valid(terrain) and terrain.has_method("_focus_known_city") else Callable(),
		"account":Dossier.account(city,own_values,home_name,today),"source":String(city.get("source","Unknown")),
		"fresh_level":int(fresh.level),"fresh_status":String(fresh.status),"fresh_age":"" if seen_day<0 else Dossier.ago(today-seen_day),
		"caption":("%s · %s" % [String(held.line),String(held.note)]) if String(held.kind)=="occupied" else "Held by "+controller}
	# The view retains its own frozen scene when only age or home figures change.
	# Identical live-report ticks do not rebuild even the surrounding figure rows.
	dossier["_print"]=hash([city,rows,home_name,dossier.account,dossier.fresh_status,dossier.fresh_age,dossier.caption])
	var blocks:Array=[dossier]
	var scouting:=Orders.dock_items(city_id)
	if not scouting.is_empty():
		blocks.append({"type":"actions","heading":"Keep an eye on it","items":scouting})
		var status:=Orders.dock_status(city_id)
		if not status.is_empty():blocks.append({"type":"text","text":status})
	var owner:=String(city.get("controller",""))
	if owner=="":owner=String(city.get("civ_id",""))
	var talk:Array=[]
	if owner!="" and owner!="player":
		var ruler:=String(ForeignDiplomacy.leader(owner).get("name",""))
		talk.append({"label":"Talk to %s" % ruler.get_slice(" ",0) if ruler!="" else "Send word to their ruler","sub":"In court, through your envoys","primary":true,"on_press":court({"civ_id":owner})})
	talk.append({"label":"Full report","sub":"Everything our scouts saw, and who to talk to about it","on_press":func()->void:CivilizationSystem.city_intelligence.open(city_id)})
	blocks.append({"type":"actions","items":talk})
	return {"blocks":blocks}

func _visit_reported_city()->void:
	if is_instance_valid(terrain) and terrain.has_method("_focus_known_city"):terrain._focus_known_city(city_id)
## Our garrison's account of a town we hold, and one row of things to do.
func held_tab(city:Dictionary,held:Dictionary)->Dictionary:
	var status:=Ownership.status(city)
	var caption:="%s · %s" % [String(status.line),String(status.note)] if String(status.note)!="" else String(status.line)
	var name:=String(held.name)
	var talk:Dictionary=held.get("talk_target",{})
	var who:=String(held.general).get_slice(" ",0)
	var items:Array=[]
	items.append({"label":"Speak to %s about %s" % [who,name] if who!="" else "Speak to the court about %s" % name,"sub":"In court: what becomes of %s is decided there" % name,"primary":true,
		"on_press":speak_about(talk,name,who)})
	items.append({"label":"Show on map","sub":"Centre the chart on %s" % name,"on_press":func()->void:
		if terrain!=null and terrain.has_method("_focus_known_city"):terrain._focus_known_city(city_id)})
	return {"blocks":[{"type":"held_town","report":held,"caption":caption},{"type":"actions","items":items}]}

## Opens the court with the war leader before you and the town named as the
## matter at hand; with no war leader, the court at rest.
func speak_about(target:Dictionary,town:String,who:String)->Callable:
	return func()->void:
		var focus:=target.duplicate()
		if not focus.is_empty():focus["matter"]="Tell %s what is to become of %s…" % [who if who!="" else "them",town]
		load("res://scripts/audience_director.gd").open_court_for(focus)

func signature()->Array:return [Held.report(city_id).hash(),report(),CivilizationSystem.scouting_staff.city_watch(city_id),Orders.party_away(city_id).get("mission_id",-1),int(GameState.elapsed_days)]
