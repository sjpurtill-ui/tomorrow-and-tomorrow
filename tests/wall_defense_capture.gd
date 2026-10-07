extends "res://tests/organic_settlement_capture.gd"
## Same-copy, same-camera defense review. Never hides or changes defenses.
## Far resource jobs need not finish; root and visible settlement seeds do.
func _wait_country_ready(country: Node, deadline: int) -> bool:
	var audit: Dictionary = _seed_readiness(country)
	while (not bool(audit.ready) or int(terrain.settlement_patch_stats().get("pending", 0)) > 0) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		audit = _seed_readiness(country)
	seed_audits.append(audit)
	return bool(audit.ready) and int(terrain.settlement_patch_stats().get("pending", 0)) == 0

func _write(path: String, value: Variant) -> void:
	if value is Dictionary and value.has("captures"):
		value["defense"] = MilitaryCampaign.settlement_defense_snapshot()
		var meshes: Array = []
		for node: Node in terrain.find_children("*Defense*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.mesh == null: continue
			var bounds: AABB = mesh.global_transform * mesh.mesh.get_aabb()
			meshes.append({"path": str(mesh.get_path()), "visible": mesh.is_visible_in_tree(), "world_aabb": str(bounds), "size_metres": str(bounds.size * 1000.0)})
		value["defense_meshes"] = meshes
		print("WALL_DEFENSE_AUDIT ", JSON.stringify({"defense": value.defense, "meshes": meshes}))
	super._write(path, value)
