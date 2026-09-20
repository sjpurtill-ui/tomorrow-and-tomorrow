extends GdUnitTestSuite
const V=preload("res://scripts/societal_values_model.gd")
const S=preload("res://scripts/society_model.gd")
class ScalarSociety extends "res://scripts/society_model.gd":
	func _leadership_subcategory_effect(dynamic_id:String,subcategory:String,_cached:Dictionary)->float:
		return super._leadership_subcategory_effect(dynamic_id,subcategory,{})

func test_axis_effects_match_original_alignment_path()->void:
	var states:Array=[{}, {"lived":{}}, V.initial_state("inquiry",77,"player")]
	for value:float in [-1.0,0.0,0.5,1.0,2.0]:
		var state:=V.initial_state("defense",91,"player")
		for axis in V.VALUE_ORDER:state.lived[axis]=value
		state.erase("institutional_orientation")
		states.append(state)
	for state:Dictionary in states:
		for effect_id in ["cohesion","legitimacy","institutions","knowledge","adoption","ecology","security","trade","unknown"]:
			assert_float(V.simulation_effect(state,effect_id)).is_equal(reference_effect(state,effect_id))

func test_subcategories_match_scalar_with_live_leaders_and_state()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("daily",932)
	WorldSimulation.scoped("daily",func()->void:
		var model:=S.new()
		var reference:=ScalarSociety.new()
		var state=WorldSimulation.state
		for doctrine in ["","directive","federated","measured","representative","territorial","unknown"]:
			for legitimacy in [0.1,0.85]:
				state.simulation_metrics.legitimacy=legitimacy
				state.elapsed_days+=137
				state.player_settlements.assign([{"id":1,"position":Vector2(legitimacy*7,2)}])
				state.leadership_positions={}
				assert_dict(model.evaluate_subcategories({})).is_equal(reference.evaluate_subcategories({}))
				for office in S.OFFICE_DYNAMICS:
					state.leadership_positions[office]={"doctrine":doctrine,"skills":{"Knowledge":80,"Administration":20},"dynamic_profile":{"health":0.9,"knowledge":0.3},"subcategory_profile":{"health":{"General health":0.9},"knowledge":{"Observers":0.2}}}
					assert_dict(model.evaluate_subcategories({})).is_equal(reference.evaluate_subcategories({}))
				state.leadership_positions["Scholar"]={"dynamic_profile":{"knowledge":0.8},"subcategory_profile":{"knowledge":{"Observers":0.9}}}
				assert_dict(model.evaluate_subcategories({})).is_equal(reference.evaluate_subcategories({}))
	)
	WorldSimulation.clear()

# Pre-optimization formula retained as an independent numerical oracle.
func reference_effect(state:Dictionary,effect_id:String)->float:
	# Effects only read the value axes. Normalizing a complete society here
	# also copied its history and rebuilt identity/architecture for every query.
	var source:=V.initial_state() if state.is_empty() else state
	var lived:Dictionary={}
	var official:Dictionary=source.get("official",{})
	var raw_lived:Dictionary=source.get("lived",{})
	for axis in V.VALUE_ORDER:lived[axis]=clampf(float(raw_lived.get(axis,0.5)),0.0,1.0)
	var institutional:Dictionary=source.get("institutional_orientation",{})
	if institutional.is_empty():
		institutional=V._institutional_target({"lived":lived,"institutions":V._normalize_institution_records(source.get("institutions",{}))})
	var official_gap:=0.0
	var institutional_gap:=0.0
	for axis in V.VALUE_ORDER:
		official_gap+=absf(float(lived[axis])-clampf(float(official.get(axis,0.5)),0.0,1.0))
		institutional_gap+=absf(float(lived[axis])-clampf(float(institutional.get(axis,lived[axis])),0.0,1.0))
	var tension:=clampf((official_gap*0.56+institutional_gap*0.44)/float(V.VALUE_ORDER.size()),0.0,1.0)
	var alignment:=clampf(1.0-tension*1.55,0.0,1.0)
	match effect_id:
		"cohesion": return clampf((alignment-0.50)*0.12+(float(lived.collective_obligation)-0.50)*0.035,-0.08,0.09)
		"legitimacy": return clampf((alignment-0.50)*0.14,-0.09,0.07)
		"institutions": return clampf((alignment-0.50)*0.10+(float(lived.centralization)-0.50)*0.025,-0.07,0.07)
		"knowledge": return clampf((float(lived.experimentation)-0.50)*0.08+(float(lived.pluralism)-0.50)*0.035,-0.06,0.07)
		"adoption": return clampf((float(lived.experimentation)-0.50)*0.10+(float(lived.openness)-0.50)*0.035,-0.07,0.08)
		"ecology": return clampf((float(lived.ecological_restraint)-0.50)*0.10,-0.05,0.05)
		"security": return clampf((float(lived.collective_obligation)-0.50)*0.035+(float(lived.hierarchy)-0.50)*0.025,-0.035,0.035)
		"trade": return clampf((float(lived.openness)-0.50)*0.09+(float(lived.pluralism)-0.50)*0.035,-0.06,0.07)
	return 0.0

