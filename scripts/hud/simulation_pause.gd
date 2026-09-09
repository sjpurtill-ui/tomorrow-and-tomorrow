extends RefCounted
## A modal owns a pause until its last nested modal closes.
static var owners:Dictionary={}
var host_id:=0

static func blocks(host:Object)->bool:
	return is_instance_valid(host) and owners.has(host.get_instance_id())

func acquire(host:Node)->void:
	if host_id!=0 or not is_instance_valid(host) or not host.has_method("_set_game_speed") or not "game_speed" in host:return
	host_id=host.get_instance_id()
	if not owners.has(host_id):
		owners[host_id]={"host":weakref(host),"speed":float(host.game_speed),"count":0}
	owners[host_id].count+=1
	host._set_game_speed(0.0)

func release()->void:
	if not owners.has(host_id):host_id=0;return
	var record:Dictionary=owners[host_id]
	record.count-=1
	if int(record.count)==0:
		owners.erase(host_id)
		var host:Node=record.host.get_ref()
		if is_instance_valid(host) and float(host.game_speed)==0:host._set_game_speed(float(record.speed))
	host_id=0
