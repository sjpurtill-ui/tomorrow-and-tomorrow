extends RefCounted
## Compact fighting fronts for participants without a held sector at the
## observed battle. These are battle marks, never defensive coverage. Inputs
## come from the chart's normal dated reports; no simulation state is read.

const MAX_BATTLES:=24
const POINTS:=9
const CONTACT_KM:=1.0
const MAX_LENGTH_KM:=2.4


static func build(battles:Array,friendly:Array,enemy:Array,fronts:Array)->Array:
	var out:Array=[]
	var seen:Dictionary={}
	for battle:Dictionary in battles.slice(0,MAX_BATTLES):
		if not bool(battle.get("ours",false)) or String(battle.get("kind",""))!="battle":continue
		if String(battle.get("status",""))!="fighting" or float(battle.get("age_days",0))>0.0 or bool(battle.get("skirmish",false)):continue
		var id:=String(battle.get("id",""))
		var at:Vector2=battle.get("pos",Vector2.INF)
		var army_id:=int(battle.get("army_id",0))
		if id.is_empty() or seen.has(id) or not at.is_finite() or army_id<=0:continue
		seen[id]=true
		var ours:Dictionary={}
		for force:Dictionary in friendly.slice(0,64):
			if int(force.get("army_id",0))==army_id:ours=force;break
		if ours.is_empty():continue
		var sides:Dictionary=battle.get("sides",{})
		var a:Dictionary=sides.get("a",{});var b:Dictionary=sides.get("b",{})
		var our_men:=int(a.get("troops",0));var their_men:=int(b.get("troops",0))
		if our_men<=0 or their_men<=0:continue
		var local:=_local_fronts(fronts,at,army_id)
		# An ordinary inferred front already paints both opposing sides.
		if bool(local.get("inferred",false)):continue
		var axis:=_axis(at,ours,enemy,String(b.get("civ_id","")),local)
		var length:=clampf(sqrt(float(mini(our_men,their_men)))*0.07,0.5,MAX_LENGTH_KM)
		if not local.has("ours"):
			out.append(_ribbon(id,at,axis,length,true,our_men,army_id,String(ours.get("name",a.get("name","")))))
		if not local.has("theirs"):
			# The current own battle is itself observation of this opponent.
			# Its known troops do not reveal any other force or held ground.
			out.append(_ribbon(id,at,-axis,length,false,their_men,army_id,String(b.get("name",""))))
	return out


static func _local_fronts(fronts:Array,at:Vector2,army_id:int)->Dictionary:
	var out:Dictionary={}
	for front:Dictionary in fronts.slice(0,80):
		if bool(front.get("stale",false)) or bool(front.get("combat",false)):continue
		var ages:Variant=front.get("age",PackedFloat32Array())
		if ages is float or ages is int:
			if float(ages)>0.0:continue
		elif ages is PackedFloat32Array:
			if not ages.is_empty() and ages[0]>0.0:continue
		var deployed:=bool(front.get("deployed",false))
		var ours:=bool(front.get("ours",true))
		var armies:Array=front.get("armies",[])
		if ours and not armies.has(army_id) and int(front.get("army_id",0))!=army_id and String(front.get("friendly",""))!=str(army_id):continue
		var points:PackedVector2Array=front.get("points",PackedVector2Array())
		var nearest:=INF;var segment:=-1
		for i in range(1,points.size()):
			var distance:=at.distance_to(Geometry2D.get_closest_point_to_segment(at,points[i-1],points[i]))
			if distance<nearest:nearest=distance;segment=i
		if segment<0 or nearest>CONTACT_KM:continue
		if not deployed:out["inferred"]=true;continue
		var key:="ours" if ours else "theirs"
		if out.has(key) and float(out[key].distance)<=nearest:continue
		var toward:PackedVector2Array=front.get("toward",PackedVector2Array())
		var normal:=(points[segment]-points[segment-1]).orthogonal().normalized()
		if not toward.is_empty():normal=toward[mini(segment,toward.size()-1)].normalized()
		out[key]={"distance":nearest,"axis":normal if ours else -normal}
	return out


static func _axis(at:Vector2,ours:Dictionary,enemy:Array,owner:String,local:Dictionary)->Vector2:
	# A local held segment supplies its observed facing, not a guessed line
	# between distant sector centroids. This matters at the end of a sector.
	if local.has("theirs"):return local.theirs.axis
	if local.has("ours"):return local.ours.axis
	var from:Vector2=ours.get("pos",at)
	var axis:=at-from
	var nearest:=INF
	for force:Dictionary in enemy.slice(0,96):
		if float(force.get("age_days",0))>0.0:continue
		var civ:=String(force.get("owner",""))
		if owner!="" and civ!="" and civ!=owner:continue
		var pos:Vector2=force.get("pos",Vector2.INF)
		var distance:=pos.distance_to(at)
		if distance<nearest and distance<=8.0 and pos.distance_squared_to(from)>0.000001:
			nearest=distance;axis=pos-from
	return axis.normalized() if axis.length_squared()>0.000001 else Vector2.RIGHT


static func _ribbon(id:String,at:Vector2,axis:Vector2,length:float,ours:bool,troops:int,army_id:int,name:String)->Dictionary:
	var points:=PackedVector2Array();var toward:=PackedVector2Array()
	var width:=PackedFloat32Array();var age:=PackedFloat32Array();var pressure:=PackedFloat32Array()
	# Both sides share one contact seam, with opposite normals. The chart's
	# ribbon renderer separates their ink in screen space.
	var along:=axis.orthogonal() if ours else -axis.orthogonal()
	var weight:=clampf(log(1.0+float(troops)/length)/9.0,0.22,1.0)
	for i in POINTS:
		points.append(at+along*length*(float(i)/float(POINTS-1)-0.5))
		toward.append(axis);width.append(weight);age.append(0.0);pressure.append(0.0)
	return {"id":"combat:%s:%s" % [id,"ours" if ours else "theirs"],"battle_id":id,"points":points,"toward":toward,
		"width":width,"age":age,"pressure":pressure,"deployed":true,"combat":true,"held":false,"ours":ours,"stale":false,
		"troops":troops,"army_id":army_id if ours else 0,"armies":[army_id] if ours else [],"holders":[],"name":name,"sigma":length*0.3}
