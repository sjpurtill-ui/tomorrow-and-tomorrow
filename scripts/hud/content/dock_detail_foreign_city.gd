extends "res://scripts/hud/content/dock_content_base.gd"
const INTEL:=preload("res://scripts/city_intelligence.gd")
var city_id:String
func _init(world:Node,shell:Control,id:String)->void:
	super(world,shell);city_id=id
func report()->Dictionary:return CivilizationSystem.city_intelligence.known("player",city_id)
func meta()->Dictionary:
	var city:=report()
	return {"eyebrow":"CITY INTELLIGENCE","title":String(city.get("name","Reported city")),"subtabs":[]}
func tab(_sub:int)->Dictionary:
	var city:=report()
	if city.is_empty():return {"brief":{"title":"No report available","why":"This city has not been observed."},"blocks":[]}
	var rows:Array=[]
	for key in ["population","garrison","fortification","supply","damage","production","logistics"]:
		var field:Dictionary=city.get("fields",{}).get(key,{})
		var value:="Unknown"
		if not field.is_empty():
			var scale:=100.0 if INTEL.FIELDS[key].unit=="capacity" else 1.0
			value="%d–%d %s" % [roundi(float(field.get("observed_low",field.low))*scale),roundi(float(field.get("observed_high",field.high))*scale),"%" if scale>1 else String(INTEL.FIELDS[key].unit)]
		rows.append({"name":String(INTEL.FIELDS[key].label),"value":value,"sub":"Last observed · stale" if bool(field.get("stale",false)) else "Last observed","accent":Tokens.AMBER,"tip":"Only returned observations are shown."})
	var age:=int(city.get("age_days",-1))
	var controller:=CivilizationSystem.city_intelligence.controller_label(String(city.get("controller","")))
	return {"brief":{"title":"Last reported control: "+controller,"why":("Observation date unknown" if age<0 else "%d days since observation" % age)+" · "+String(city.get("freshness","unknown"))},"blocks":[{"type":"rows","items":rows},{"type":"text","text":"Source: "+String(city.get("source","Unknown"))},{"type":"actions","items":[{"label":"FULL REPORT & ACTIONS","sub":"Reconnaissance, diplomacy and military options","on_press":func()->void:CivilizationSystem.city_intelligence.open(city_id)}]}]}
func signature()->Array:return [report()]
