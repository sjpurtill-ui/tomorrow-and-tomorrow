extends RefCounted
## Automatic expansion uses surplus gear after existing commitments, not promised output.
static func places(host:Node,unit:String,weapon:String)->int:
	if unit.is_empty() or weapon.is_empty():return 0
	var gear:=maxi(0,int(host.military_inventory.get(weapon,0)))
	for force:Dictionary in [host.home_army]+host.field_armies+host.occupation_forces:
		for formation:Dictionary in force.get("formations",[]):
			if String(formation.get("weapon","improvised"))!=weapon:continue
			var required:=int(formation.get("equipment_required",host._equipment_required_for(String(formation.get("unit","levy")),int(formation.get("authorized_count",formation.get("count",0))))))
			gear-=maxi(0,required-int(formation.get("equipment",0)))
	for order:Dictionary in host.training_queue:
		if String(order.get("weapon","improvised"))!=weapon:continue
		gear-=maxi(0,host._equipment_required_for(String(order.get("unit","levy")),int(order.get("count",0)))-int(order.get("reserved_equipment",0)))
	var low:=0;var high:=maxi(0,host.training_capacity()-host._queued_trainees())
	while low<high:
		var middle:=(low+high+1)/2
		if host._equipment_required_for(unit,middle)<=gear:low=middle
		else:high=middle-1
	return low
