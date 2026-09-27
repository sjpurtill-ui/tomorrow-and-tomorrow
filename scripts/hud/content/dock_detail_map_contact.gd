extends "res://scripts/hud/content/dock_content_base.gd"
## Strangers in sight: a band clicked on the map. The card says what our
## lookouts see and what our nearest general is doing about it, and offers
## one thing to do: ask that general in court. Generals run every march,
## pursuit and battle (docs/GENERAL_CAMPAIGN_DESIGN.md); there are no
## numbered steps and no direct orders here.

const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
var formation_id:String=""

func _init(terrain_node:Node,hud_node:Control,target_formation_id:String="")->void:
	super._init(terrain_node,hud_node)
	formation_id=target_formation_id

func _sighting()->Dictionary:
	return CivilizationSystem.visible_formation_sighting(formation_id)

func meta()->Dictionary:
	var sighting:=_sighting()
	return {
		"eyebrow":"Strangers in sight",
		"title":String(sighting.get("label","Out of sight")),
		"subtabs":["What we see"],
	}

## Our army nearest the sighting, with the general who leads it.
func _nearest_army(point:Vector2)->Dictionary:
	var best:Dictionary={}
	var best_distance:=INF
	for army_variant in MilitaryCampaign.field_armies_snapshot().get("armies",[]):
		var army:Dictionary=army_variant
		if int(army.get("troops",0))<=0: continue
		var position_data:Dictionary=army.get("position",{})
		var distance:=Vector2(float(position_data.get("x",0.0)),float(position_data.get("z",0.0))).distance_to(point)
		if distance<best_distance:
			best_distance=distance
			best=army.duplicate()
			best["distance_km"]=distance
	return best

## Who answers for this: the army's own general, else the Marshal, else the
## war council. Returns {name, target} for the court.
func _who_answers(army:Dictionary)->Dictionary:
	var commander:Dictionary=army.get("commander",{}) if not army.is_empty() else {}
	var name:=ArmyMarks._named(String(commander.get("name","")))
	if String(commander.get("figure_id",""))!="" and name!="":
		return {"name":name,"target":{"figure_id":String(commander.figure_id)}}
	var holder:Dictionary=GovernmentPeopleSystem.officeholder("Marshal") if GovernmentPeopleSystem.has_method("officeholder") else {}
	if int(holder.get("person_id",0))>0:
		return {"name":String(holder.get("name","the Marshal")),"target":{"person_id":int(holder.person_id)}}
	return {"name":"","target":{}}

func _ask(target:Dictionary)->void:
	var director:Node=preload("res://scripts/audience_director.gd").court_node()
	if not target.is_empty() and director!=null and director.has_method("summon") and director.call("summon",target)!=null:return
	preload("res://scripts/audience_director.gd").open_court_for({})

func tab(_sub:int)->Dictionary:
	var sighting:=_sighting()
	if sighting.is_empty():
		return {
			"kpis":[],
			"brief":{"tone":"info","title":"Out of sight","why":"Our lookouts can no longer see them. If they come back into view, they will show on the map again."},
			"blocks":[],
		}
	var scouts:=bool(sighting.get("carries_report",false))
	var hostile:=bool(sighting.get("hostile",false))
	var low:=int(sighting.get("strength_estimate_low",0))
	var high:=int(sighting.get("strength_estimate_high",low))
	var from_home:=float(sighting.get("distance_km",0.0))
	var point_data:Dictionary=sighting.get("position",{})
	var point:=Vector2(float(point_data.get("x",0.0)),float(point_data.get("z",0.0)))
	var kpis:Array=[
		{"label":"Who","value":"Scouts" if scouts else ("A war band" if hostile else "A band"),"delta":"at war with us" if hostile else "not at war with us","accent":Tokens.RED if hostile else Tokens.AMBER,"tip":"Only a band from a people at war with us is an enemy."},
		{"label":"How many","value":"about %d" % roundi((low+high)*0.5),"delta":"a guess, %d to %d" % [low,high] if high>low else "a guess","accent":Tokens.AMBER,"tip":"Our lookouts can only guess their number."},
		{"label":"How far","value":"%.0f km" % from_home,"delta":"from our first hearth","accent":Tokens.MUTED,"tip":"How far they are from our first settlement."},
	]
	var blocks:Array=[]
	var seen:="%s: %s, %s, %.0f km from home." % ["Scouts" if scouts else "A band",String(sighting.get("label","strangers")),"%d to %d strong" % [low,high] if high>low else "about %d strong" % low,from_home]
	if scouts:seen+=" They are taking what they learned of us back to their people."
	blocks.append({"type":"text","heading":"What our lookouts see","text":seen})
	var army:=_nearest_army(point)
	var answers:=_who_answers(army)
	var first_name:=String(answers.name).get_slice(" ",0)
	var general_words:=""
	if army.is_empty():
		general_words="We have no army in the field. %s" % ("%s answers for war; ask them what should be done." % String(answers.name) if first_name!="" else "The war council can say what should be done.")
	else:
		var doing:=ArmyMarks.doing({"status":String(army.get("status","")),"destination_name":String(army.get("destination_name","")),"destination_id":String(army.get("destination_id","")),"location_name":String(army.get("location_name","")),"command_status":String(army.get("command_status","")),"at_home":String(army.get("location_id",""))=="player_home"})
		var leader:=String(answers.name) if first_name!="" else "Its general"
		general_words="%s leads %s, %.0f km from them, and is %s. The general chooses the road and whether to fight; say what you want and they will see to it their own way." % [leader,String(army.get("name","our nearest army")),float(army.get("distance_km",0.0)),doing]
	if not hostile:general_words+=" Attacking them would start a war with their people."
	blocks.append({"type":"text","heading":"What our general intends","text":general_words})
	var ask_label:=("Ask %s" % first_name) if first_name!="" else "Ask the war council"
	blocks.append({"type":"actions","items":[{"label":ask_label,"sub":"in court","primary":true,"on_press":_ask.bind(answers.target),"tip":"Open the court with the person who answers for this."}]})
	var nearby:Dictionary=terrain._contact_encounter_at(Vector3(point.x,0,point.y),0.3)
	if nearby.has("city_id"):
		var nearby_id:=String(nearby.city_id)
		blocks.append({"type":"actions","heading":"Nearby","items":[{"label":"What we know of %s" % String(nearby.get("name","the town nearby")),"on_press":func()->void:terrain._show_city_intel_summary(nearby_id)}]})
	var brief_title:="Their scouts are heading home with news of us" if scouts else ("An enemy band is in sight" if hostile else "Strangers are in sight")
	return {"kpis":kpis,"brief":{"tone":"danger" if hostile or scouts else "info","title":brief_title,"why":"Ask %s what they mean to do." % (first_name if first_name!="" else "the war council")},"blocks":blocks}

func signature()->Array:
	var sighting:=_sighting()
	return [formation_id,int(CivilizationSystem.observation_revision),String(sighting.get("position",{})),MilitaryCampaign.field_armies_snapshot().hash()]
