extends "res://scripts/hud/content/dock_content_base.gd"
const INTEL:=preload("res://scripts/city_intelligence.gd")
const V:=preload("res://scripts/hud/city_report_visuals.gd")
const Dossier:=preload("res://scripts/hud/city_dossier.gd")
var city_id:String
func _init(world:Node,shell:Control,id:String)->void:
	super(world,shell);city_id=id
func report()->Dictionary:return CivilizationSystem.city_intelligence.known("player",city_id)
func meta()->Dictionary:
	var city:=report()
	return {"eyebrow":"CITY INTELLIGENCE","title":String(city.get("name","Reported city")),"subtabs":[]}
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
	var today:=int(GameState.elapsed_days)
	var own:=home(city)
	var own_values:Dictionary=own.get("values",{})
	var home_name:=String(own.get("name",""))
	var rows:Array=[]
	for key in ["population","science_capacity","education","gdp","life_expectancy","infant_mortality","garrison","fortification","supply","damage","production","logistics"]:
		var field:Dictionary=city.get("fields",{}).get(key,{})
		var value:=V.estimate(key,field)
		if key=="population" and not field.is_empty():value+=" people"
		var mine:=float(own_values.get(key,-1.0))
		var own_text:=""
		if mine>=0 and not field.is_empty():own_text="%s · %s" % [home_name.to_upper(),V.estimate(key,{"low":mine,"high":mine},false)]
		var seen:=int(field.get("observed_day",-1))
		rows.append({"key":key,"name":String(V.LABELS[key]),"value":value,"field":field,"own":mine if not field.is_empty() else -1.0,"own_text":own_text,"tip":"Seen %s. Only returned observations are shown." % Dossier.ago(today-seen) if seen>=0 else "Only returned observations are shown."})
	var fresh:=V.freshness(city,today)
	var seen_day:=int(city.get("observed_day",-1))
	var controller:=CivilizationSystem.city_intelligence.controller_label(String(city.get("controller","")))
	var dossier:={"type":"city_dossier","items":rows,"city_id":city_id,"fields":city.get("fields",{}),"home_name":home_name,
		"account":Dossier.account(city,own_values,home_name,today),"source":String(city.get("source","Unknown")),
		"fresh_level":int(fresh.level),"fresh_status":String(fresh.status),"fresh_age":"" if seen_day<0 else Dossier.ago(today-seen_day).to_upper(),
		"caption":"Held by "+controller}
	return {"blocks":[dossier,{"type":"actions","items":[{"label":"FULL REPORT & ACTIONS","sub":"Reconnaissance, diplomacy and military options","on_press":func()->void:CivilizationSystem.city_intelligence.open(city_id)}]}]}
func signature()->Array:return [report()]
