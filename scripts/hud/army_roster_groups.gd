extends RefCounted
## Read-only force presentation. Never merges or rewrites campaign troop records.
static func group(rows:Array[Dictionary])->Array[Dictionary]:
	var groups:Dictionary={}
	var result:Array[Dictionary]=[]
	for row:Dictionary in rows:
		if bool(row.get("unknown",false)):
			result.append(row.duplicate(true));continue
		var key:=String(row.get("group_key",row.id))
		if not groups.has(key):
			var entry:=row.duplicate(true)
			entry.merge({"id":key,"name":row.get("group_name",row.name),"count":0,"authorized":0,"condition":0.0,"equipment":0.0,"skill":0.0,"experience":0.0,"progress":0.0,"in_training":false,"needs_attention":false,"gear":0.0,"gear_required":0.0,"parts":{},"largest":0},true)
			groups[key]=entry;result.append(entry)
		var entry:Dictionary=groups[key]
		var count:=int(row.count)
		entry.count+=count;entry.authorized+=int(row.authorized)
		for field:String in ["condition","skill","experience","progress"]:entry[field]+=float(row[field])*count
		var required:=float(row.get("equipment_required",count))
		entry.gear+=float(row.get("equipment_count",float(row.equipment)*required));entry.gear_required+=required
		entry.in_training=bool(entry.in_training) or bool(row.in_training)
		entry.needs_attention=bool(entry.needs_attention) or float(row.equipment)<.8 or float(row.condition)<.75
		if count>int(entry.largest):entry.largest=count;entry.type_id=row.type_id
		var part:=String(row.name)
		if not String(row.get("weapon","")).is_empty():part+=" · "+String(row.weapon).replace("_"," ").capitalize()
		if not entry.parts.has(part):entry.parts[part]={"count":0,"gear":0.0,"required":0.0,"skill":0.0}
		entry.parts[part].count+=count;entry.parts[part].gear+=float(row.get("equipment_count",float(row.equipment)*required))
		entry.parts[part].required+=required;entry.parts[part].skill+=float(row.skill)*count
	for entry:Dictionary in groups.values():
		for field:String in ["condition","skill","experience","progress"]:entry[field]/=maxi(1,int(entry.count))
		entry.equipment=float(entry.gear)/maxf(1,float(entry.gear_required)) if entry.gear_required>0 else 1.0
		entry.equipment_note="%d / %d equipped" % [entry.gear,entry.gear_required]
		var lines:Array[String]=[]
		for part:String in entry.parts:
			var piece:Dictionary=entry.parts[part]
			lines.append("%s — %d soldiers · gear %d/%d · drill %d%%" % [part,int(piece.count),int(piece.gear),int(piece.required),roundi(float(piece.skill)/maxi(1,int(piece.count))*100)])
		entry.composition="\n".join(lines)
		entry.purpose="Soldiers serving together, grouped by role and equipment. Review shortages below or open recruitment to prepare more formations."
		entry.training_note="Staff training includes part of this force." if entry.in_training else "Reserve and duty personnel."
		entry.activity="In training" if entry.in_training else "Needs attention" if entry.needs_attention else "On duty / reserve"
	return result
