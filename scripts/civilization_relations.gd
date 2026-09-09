extends RefCounted
const SHARED:=["treaty","at_war","war_started_day","truce_until_day","war_id"]
static func synchronize()->void:
	var ids:Array=WorldSimulation.actors.keys();ids.append("player");ids.sort()
	var changes:Array[Dictionary]=[]
	for id:String in ids:
		WorldSimulation.scoped(id,func()->void:
			for civ in WorldSimulation.world.civilizations:
				var other:="player" if String(civ.id)=="human" else String(civ.id)
				var key:=id+":"+other
				var current:Dictionary={}
				for field in SHARED:
					if civ.player_relation.has(field):current[field]=civ.player_relation[field]
				var previous:Dictionary=WorldSimulation.relation_baselines.get(key,{})
				if current!=previous and not current.is_empty():changes.append({"source":id,"target":other,"fields":current})
				WorldSimulation.relation_baselines[key]=current.duplicate(true)
		)
	for change in changes:
		if change.target!="player" and not WorldSimulation.actors.has(change.target):continue
		WorldSimulation.scoped(String(change.target),func()->void:
			var source_id:="human" if change.source=="player" else String(change.source)
			for civ in WorldSimulation.world.civilizations:
				if String(civ.id)!=source_id:continue
				civ.player_relation.merge(change.fields,true)
				WorldSimulation.relation_baselines[String(change.target)+":"+String(change.source)]=change.fields.duplicate(true)
		)
