extends "res://scripts/hud/content/dock_content_base.gd"
const INTEL:=preload("res://scripts/city_intelligence.gd")
const V:=preload("res://scripts/hud/city_report_visuals.gd")
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
	for key in ["population","science_capacity","education","gdp","life_expectancy","infant_mortality","garrison","fortification","supply","damage","production","logistics"]:
		var field:Dictionary=city.get("fields",{}).get(key,{})
		var value:=V.estimate(key,field)
		if key=="population" and not field.is_empty():value+=" people"
		rows.append({"name":String(V.LABELS[key]),"value":value,"sub":"Last observed","accent":Tokens.AMBER,"tip":"Only returned observations are shown."})
	var controller:=CivilizationSystem.city_intelligence.controller_label(String(city.get("controller","")))
	return {"brief":{"title":"Last reported control: "+controller,"why":"Report · "+String(V.freshness(city,int(GameState.elapsed_days)).status)},"blocks":[{"type":"rows","items":rows},{"type":"text","text":"Source: "+String(city.get("source","Unknown"))},{"type":"actions","items":[{"label":"FULL REPORT & ACTIONS","sub":"Reconnaissance, diplomacy and military options","on_press":func()->void:CivilizationSystem.city_intelligence.open(city_id)}]}]}
func signature()->Array:return [report()]
