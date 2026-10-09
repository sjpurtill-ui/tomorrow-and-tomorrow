extends RefCounted
## THE BORDER in the Security screen (fort_border.gd): how each stretch of our
## border is watched, our forts and what they cost, the share of the watch
## sent out, and the war leader's sites for the next fort, all in the engine's
## numbers. Plain dock blocks (dock_blocks.gd).

const Forts:=preload("res://scripts/fort_border.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

static func blocks(hud:Node)->Array:
	var refresh:=func()->void:
		if is_instance_valid(hud) and hud.has_method("request_immediate_dock_refresh"):hud.request_immediate_dock_refresh()
	var out:=[]
	var kept:=Forts.watch()
	var bill:=Forts.costs(null,kept)
	var shape:=Forts.outline()
	var by_id:={}
	for f:Dictionary in Forts.forts():by_id[int(f.id)]=f
	var share:=Forts.border_share()
	var home:=preload("res://scripts/watch_military.gd").at_home(MilitaryCampaign)
	# How each stretch is kept.
	var bars:=[]
	for s:Dictionary in kept.stretches:
		var a:String=String(by_id[int(s.a)].get("name","a fort"));var b:String=String(by_id[int(s.b)].get("name","a fort"))
		bars.append({"name":"%s to %s · %d km" % [a,b,roundi(float(s.km))],"value":"%d on watch · %.1f a km · %d%%" % [roundi(float(s.watchmen)),float(s.per_km),roundi(float(s.strength)*100.0)],
			"ratio":float(s.strength),"color":_tone(float(s.strength)),"tip":"Of every crossing here, about %d in 100 are stopped (less for the stealthy). Six on watch a km would stop 95." % roundi(float(s.strength)*100.0)})
	bars.append({"name":"Open sides (no linked forts)","value":"%d in 100 stopped" % roundi(Forts.OPEN_STRENGTH*100.0),"ratio":Forts.OPEN_STRENGTH,"color":_tone(Forts.OPEN_STRENGTH),"tip":"Where no two forts are linked, people walk in and out as they please."})
	out.append({"type":"bars","heading":"THE BORDER · reaching %d km at most" % roundi(float(shape.reach)),"items":bars})
	# The watch sent out.
	out.append({"type":"actions","heading":"THE WATCH ON THE BORDER · %d of %d at home (%d%%)" % [roundi(float(home)*share),home,roundi(share*100.0)],"items":[
		{"label":"MORE TO THE BORDER","sub":"%d%% of the watch at home → %d%%" % [roundi(share*100.0),roundi(minf(1.0,share+0.1)*100.0)],"disabled":share>=1.0,
			"on_press":func()->void:Forts.set_border_share(minf(1.0,Forts.border_share()+0.1));refresh.call(),
			"tip":"Each fort's garrison is filled first, the rest spread along the linked stretches by their length."},
		{"label":"FEWER TO THE BORDER","sub":"%d%% → %d%%" % [roundi(share*100.0),roundi(maxf(0.0,share-0.1)*100.0)],"disabled":share<=0.0,
			"on_press":func()->void:Forts.set_border_share(maxf(0.0,Forts.border_share()-0.1));refresh.call(),
			"tip":"Fewer out there eat less of what spoils on the road; the line thins and forts not manned wear down."}]})
	# The forts and what they cost.
	var rows:=[]
	var posts:={}
	for p:Dictionary in bill.posts:posts[int(p.id)]=p
	for f:Dictionary in Forts.forts():
		if String(f.get("status",""))=="abandoned":continue
		var k:=Forts.kind(String(f.kind))
		var post:Dictionary=posts.get(int(f.id),{})
		var manned:=int(kept.garrisons.get(int(f.id),0))
		var state:="going up %d%%" % roundi(float(f.get("progress",0.0))/maxf(1.0,float(k.work))*100.0) if String(f.status)=="building" else "condition %d%%" % roundi(float(f.get("condition",1.0))*100.0)
		rows.append({"name":String(f.get("name","Fort")),"sub":"%s · %d km out · %d of %d manned · %s" % [String(k.name),roundi(float(post.get("km",0.0))),manned,int(k.garrison),state],
			"detail":"%d food lost a day on the road" % roundi(float(post.get("lost",0.0))),
			"tip":"Food carried %d km loses about %d in 100 on the way. A fort short of its garrison or its upkeep wears down and in the end is left." % [roundi(float(post.get("km",0.0))),roundi(Forts.transit_loss(float(post.get("km",0.0)),Forts.carrying())*100.0)]})
	if not rows.is_empty():
		var upkeep:PackedStringArray=[]
		for m:String in bill.upkeep:upkeep.append("%.1f %s" % [float(bill.upkeep[m]),m])
		out.append({"type":"rows","heading":"OUR FORTS · %d food lost a day on the road%s" % [roundi(float(bill.food_lost)),(" · upkeep "+", ".join(upkeep)+" a day") if not upkeep.is_empty() else ""],"items":rows})
		var leave:=[]
		for f:Dictionary in Forts.forts():
			if String(f.get("status",""))=="abandoned":continue
			var id:=int(f.id)
			leave.append({"label":"LEAVE %s" % String(f.get("name","fort")).to_upper(),"sub":"its garrison comes home; its ground is no longer ours",
				"on_press":func()->void:Forts.abandon(id);refresh.call()})
		out.append({"type":"actions","heading":"LEAVE A FORT","items":leave})
	# The war leader's sites.
	var sites:=[]
	for site:Dictionary in Forts.suggest_sites():
		var cost:PackedStringArray=[]
		for m:String in site.cost:cost.append("%d %s" % [roundi(float(site.cost[m])),m])
		var at:Vector2=site.at
		sites.append({"label":"RAISE A %s · %s" % [String(site.kind_name).to_upper(),String(site.why).to_upper()],
			"sub":"%d km out · %s · %d to man it · about %d food lost a day" % [roundi(float(site.km)),", ".join(cost),int(site.garrison),roundi(float(site.food_lost))],
			"tip":"Holds about %d km² more and pushes the border out toward it. Its garrison raises it over days." % roundi(float(site.gain_km2)),
			"on_press":func()->void:
				var made:=Forts.build(at)
				if made.has("error") and is_instance_valid(hud) and hud.has_method("show_message"):hud.show_message(String(made.error))
				refresh.call()})
	if not sites.is_empty():out.append({"type":"actions","heading":"THE WAR LEADER'S SITES FOR A FORT","items":sites})
	elif Forts.best_kind().is_empty():out.append({"type":"rows","heading":"FORTS","items":[{"name":"Our people know no way to raise a fort yet","sub":"A watch camp needs nothing; this appears once we are settled."}]})
	return out

static func _tone(strength:float)->Color:
	if strength>=0.7:return Color("#5d7a3a")
	if strength>=0.4:return Color("#b08a2e")
	return Color("#a4452c")
