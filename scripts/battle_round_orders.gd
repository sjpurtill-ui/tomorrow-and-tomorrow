class_name BattleRoundOrders
extends RefCounted
## Per-formation use of the existing offensive, push and cautious stance values.
## No directive means the original resolver's exact baseline.
const KINDS:Dictionary={
	"hold":{"label":"Hold","attack":1.0,"defense":1.0,"exposure":1.0,"intensity":1.0,"description":"Keep formation and fight from your position."},
	"advance":{"label":"Advance","attack":1.12,"defense":1.0,"exposure":1.08,"intensity":1.12,"description":"Press the target. More attack and exposure; uses the existing offensive stance."},
	"charge":{"label":"Charge","attack":1.25,"defense":1.0,"exposure":1.12,"intensity":1.30,"description":"Commit hard to the target. Stronger attack and more intense losses; uses the existing push order."},
	"fallback":{"label":"Fall back","attack":.90,"defense":1.08,"exposure":.82,"intensity":1.0,"description":"Yield pressure while maintaining contact. Less attack and exposure; uses the existing cautious stance. Whole-army retreat ends contact."}
}
static func validate(own:Array,enemy:Array,index:int,kind:String,target:int)->String:
	if index<0 or index>=own.size() or int(own[index].get("count",0))<=0:return "Select a fighting formation."
	if not KINDS.has(kind):return "Choose a valid formation order."
	if target>=enemy.size() or target< -1:return "Choose a valid target."
	if target>=0 and int(enemy[target].get("count",0))<=0:return "That target is no longer fighting."
	if kind in ["advance","charge"] and target<0:return "Select an enemy formation to target."
	return ""

static func apply(force:Dictionary,enemy:Dictionary,orders:Dictionary)->Dictionary:
	var total:=maxi(1,int(force.get("troops",0)));var exposure:=0.0;var intensity:=0.0
	var target_weights:Dictionary={}
	for index in force.get("formations",[]).size():
		var formation:Dictionary=force.formations[index]
		var order:Dictionary=orders.get(str(index),{})
		var kind:=String(order.get("kind","hold"))
		var target:=int(order.get("target",-1))
		if validate(force.formations,enemy.get("formations",[]),index,kind,target)!="":kind="hold";target=-1
		var rules:Dictionary=KINDS[kind];var share:=float(formation.get("count",0))/total
		formation["round_order_attack"]=float(rules.attack);formation["round_order_defense"]=float(rules.defense)
		formation["round_order_exposure"]=float(rules.exposure)
		exposure+=share*float(rules.exposure);intensity+=share*float(rules.intensity)
		if target>=0 and kind in ["advance","charge"]:target_weights[str(target)]=float(target_weights.get(str(target),0))+share
	return {"exposure":exposure,"intensity":intensity,"targets":target_weights}

static func clear_transient(force:Dictionary)->void:
	for formation:Dictionary in force.get("formations",[]):
		for key in ["round_order_attack","round_order_defense","round_order_exposure"]:formation.erase(key)
