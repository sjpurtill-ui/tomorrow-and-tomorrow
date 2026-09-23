extends RefCounted
## Installs the first controlled kiln once its knowledge is adopted and a
## firing practice needs it, paying the flattened bill from local stock.
const Ops=preload("res://scripts/technology_operations.gd")

static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	if "kiln_control" not in state.known_discoveries or WorldSimulation.discovery.adoption("kiln_control")<.25:return {}
	if "lime_burning" not in state.known_discoveries and "ceramic_pipe_firing_qualification" not in state.known_discoveries:return {}
	var record:Dictionary=Ops.data().plants.get("controlled_kiln",{})
	if int(record.get("installed",0))+int(record.get("building",0))>0:return {}
	# Wait for the materials; Civilian Goods come from Crafting households.
	if Ops.quote("controlled_kiln").has("error"):return {}
	return {"kind":"plant_install","plant":"controlled_kiln","count":1}
