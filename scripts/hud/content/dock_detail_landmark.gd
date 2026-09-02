extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: one charted landmark — its illustration plate, the myth the
## naming party tells, and the sober survey record. Opened by clicking the
## landmark's label on the map. Illustrations are keyed by feature_id at
## assets/textures/landmarks/<feature_id>.png and fall back to text quietly.

var landmark:Dictionary={}

func _init(terrain_node:Node,hud_node:Control,landmark_record:Dictionary={})->void:
	super(terrain_node,hud_node)
	landmark=landmark_record

func meta()->Dictionary:
	return {
		"eyebrow":"CHARTED LANDMARK · %s" % String(landmark.get("kind","waymark")).to_upper(),
		"title":String(landmark.get("name","Landmark")),
		"subtabs":["THE RECORD"],
	}

func tab(_sub:int)->Dictionary:
	var position_data:Dictionary=landmark.get("position",{})
	var position:=Vector2(float(position_data.get("x",0.0)),float(position_data.get("z",0.0)))
	var distance:=roundi(CivilizationSystem.player_world_origin.distance_to(position))
	var waymarks:=CivilizationSystem.landmarks_snapshot().size()
	var range_bonus:=roundi((CivilizationSystem.scout_range_factor()-1.0)*100.0)
	var kpis:Array=[
		{"label":"GROUND","value":String(landmark.get("kind","?")).capitalize(),"delta":"","accent":Tokens.TEAL,"tip":"What the naming party's survey found this place to be"},
		{"label":"NAMED","value":"day %d" % int(landmark.get("discovered_day",0)),"delta":"","accent":Tokens.AMBER,"tip":"When the returning party recorded the name"},
		{"label":"DISTANCE","value":"%d km" % distance,"delta":"from home","delta_color":Tokens.MUTED,"accent":Tokens.BLUE,"tip":"Overland distance from the settlement"},
		{"label":"WAYMARKS","value":str(waymarks),"delta":"+%d%% range" % range_bonus,"delta_color":Tokens.GREEN,"accent":Tokens.GREEN,"tip":"Every charted landmark extends how far scout parties can safely range"},
	]
	var blocks:Array=[{
		"type":"image",
		"path":"res://assets/textures/landmarks/%s.png" % String(landmark.get("feature_id","")),
		"fallback":"No illustration of this place has been recorded yet.",
		"tip":String(landmark.get("name","")),
	}]
	if String(landmark.get("myth",""))!="":
		blocks.append({"type":"text","heading":"AS THE NAMING PARTY TELLS IT","text":String(landmark.myth)})
	blocks.append({"type":"text","heading":"THE SURVEY RECORD","text":String(landmark.get("description","No survey record survives."))})
	blocks.append({"type":"text","text":"A named place is a navigational anchor: the charted lattice of waymarks lets later parties range farther on the same provisions."})
	return {"kpis":kpis,"brief":{},"blocks":blocks}

func signature()->Array:
	return [String(landmark.get("id","")),CivilizationSystem.landmarks_snapshot().size()]
