extends Node

var facts: Dictionary = {}
var next_fact_id := 1

func reset_for_new_world()->void:
	facts={}
	next_fact_id=1

func set_fact(subject: String, predicate: String, value: Variant, visibility := "internal", source := "simulation") -> String:
	var key := "%s::%s" % [subject, predicate]
	var fact_id := "fact_%06d" % next_fact_id
	next_fact_id += 1
	facts[key] = {"id":fact_id, "subject":subject, "predicate":predicate, "value":value, "visibility":visibility, "source":source, "day":int(GameState.elapsed_days)}
	return fact_id

func query(subject: String, predicate: String) -> Dictionary:
	return facts.get("%s::%s" % [subject, predicate], {})

func relevant_facts(subjects: Array[String], allowed_visibilities: Array[String]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for fact in facts.values():
		if fact.subject in subjects and fact.visibility in allowed_visibilities:
			results.append(fact)
	return results

func change_from_simulation(subject: String, predicate: String, value: Variant, visibility := "internal") -> String:
	return set_fact(subject, predicate, value, visibility, "simulation")
