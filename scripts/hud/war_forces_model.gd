extends RefCounted
## THE ARMY WHERE IT STANDS, for the War screen's forces list. Every soldier is
## counted once, in the row of the place they are: at home (the watch at
## home: the home guard and those free for the bands), each band in the
## field, each garrison, those in a drill course, and those waiting, hurt or
## away. A row says where they are, how
## many, what they carry (kit by count), who leads them and how they stand.
## Read from the one ledger (MilitaryCampaign and the army bar's own cards);
## nothing here moves anyone. Static; preload.

const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const Strips:=preload("res://scripts/hud/force_strips.gd")
const Law:=preload("res://scripts/army_levy_law.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Ledger:=preload("res://scripts/equipment_ledger.gd")


## The rows, home first, then bands, garrisons, drill and the rest:
## {kind (home/band/garrison/drill/waiting), id, title, men, full, blocks
## (Strips.composition: glyph, count, label), kit (in words), leader, doing,
## will (0..1; -1 when not told), fed (0..1; -1 when not told), army_id}.
static func rows(mc:Node)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var home:=String(WorldSimulation.state.settlement_name)
	var watch:=Law.watch(mc)
	var home_men:=maxi(0,int(mc.home_army.get("troops",0)))
	if home_men>0:
		var blocks:=Strips.composition(mc.home_army.get("formations",[]))
		var ready:=maxi(0,home_men-int(watch.home))
		var doing:="%s free for the bands" % EraWords.grouped(ready)
		if int(watch.home)>0:doing+=" · %s guard home and the towns" % EraWords.grouped(int(watch.home))
		out.append({"kind":"home","id":"home","title":"At home in %s" % home,"men":home_men,"full":home_men,"blocks":blocks,"kit":kit_words(blocks),
			"leader":_name_of(mc.home_army.get("commander",{})),"doing":doing,"will":clampf(float(mc.home_army.get("morale",0.6)),0.0,1.0),"fed":-1.0,"army_id":0})
	for army_variant in mc.field_armies:
		if not army_variant is Dictionary or int((army_variant as Dictionary).get("troops",0))<=0:continue
		var army:Dictionary=army_variant
		var card:=BarModel.army_card(mc,army)
		var blocks:=Strips.composition(army.get("formations",[]))
		out.append({"kind":"band","id":String(card.id),"title":String(card.title),"men":int(card.men),"full":int(card.full),"blocks":blocks,"kit":kit_words(blocks),
			"leader":String((card.general as Dictionary).get("name","")) if card.get("general") is Dictionary and not (card.general as Dictionary).is_empty() else _name_of(army.get("commander",{})),
			"doing":String(card.doing) if not bool(card.get("unknown",false)) else "no word from them yet",
			"will":float(card.will),"fed":float(card.supply) if String(card.get("supply_state",""))!="unknown" else -1.0,"army_id":int(army.get("army_id",0))})
	for force_variant in mc.occupation_forces:
		if not force_variant is Dictionary or int((force_variant as Dictionary).get("troops",0))<=0:continue
		var force:Dictionary=force_variant
		var card:=BarModel._garrison_card(mc,force)
		var blocks:=Strips.composition(force.get("formations",[]))
		out.append({"kind":"garrison","id":String(card.id),"title":String(card.title),"men":int(card.men),"full":int(card.full),"blocks":blocks,"kit":kit_words(blocks),
			"leader":String((card.general as Dictionary).get("name","")) if card.get("general") is Dictionary and not (card.general as Dictionary).is_empty() else "",
			"doing":String(card.doing),"will":float(card.will),"fed":float(card.supply),"army_id":-1})
	# Those in drill: the army's own drill and the watch's apart.
	var drilling:={}
	var drill_men:=0
	for order_variant in mc.training_queue:
		if not order_variant is Dictionary:continue
		var order:Dictionary=order_variant
		if String(order.get("mode",""))=="field_draft":continue
		var count:=maxi(0,int(order.get("count",0)))
		var key:=String(order.get("weapon","improvised"))
		drilling[key]=int(drilling.get(key,0))+count
		drill_men+=count
	if drill_men>0:
		var blocks:=[]
		for weapon:String in drilling:blocks.append({"glyph":"","count":int(drilling[weapon]),"label":Ledger.label(weapon) if Ledger.has(weapon) else weapon.replace("_"," ").capitalize()})
		blocks.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.count)>int(b.count))
		var days:=int(BarModel.drill_card(mc).get("days",0))
		out.append({"kind":"drill","id":"drill","title":"In drill at %s" % home,"men":drill_men,"full":drill_men,"blocks":blocks,"kit":kit_words(blocks),
			"leader":_name_of(mc.home_army.get("commander",{})),"doing":("fit to fight in about %d days" % days) if days>0 else "drilling","will":-1.0,"fed":-1.0,"army_id":0})
	var ledger:Dictionary=mc.personnel_ledger()
	var waiting:=int(ledger.recruits);var hurt:=int(ledger.recovering);var away:=int(ledger.get("missing",0))
	if waiting+hurt+away>0:
		var parts:=PackedStringArray()
		if waiting>0:parts.append("%s waiting to drill" % EraWords.grouped(waiting))
		if hurt>0:parts.append("%s hurt, mending" % EraWords.grouped(hurt))
		if away>0:parts.append("%s scattered or taken" % EraWords.grouped(away))
		out.append({"kind":"waiting","id":"waiting","title":"Not ready","men":waiting+hurt+away,"full":waiting+hurt+away,"blocks":[],"kit":"","leader":"",
			"doing":" · ".join(parts),"will":-1.0,"fed":-1.0,"army_id":0})
	return out


## "12 spears, 6 bows, 2 with whatever came to hand": the kit by count.
static func kit_words(blocks:Array)->String:
	var parts:=PackedStringArray()
	for b:Dictionary in blocks:parts.append("%s %s" % [EraWords.grouped(int(b.count)),String(b.label).to_lower()])
	return ", ".join(parts)


## Where the army's people come from: everyone keeping watch is one fewer at
## other work (watch_military.gd). {soldiers, workers (who can work), one_in}.
static func drawn_from(mc:Node)->Dictionary:
	var soldiers:=maxi(Law.under_arms(mc),int(mc.watch_manpower()))
	var able:=maxi(1,int(WorldSimulation.state.able_population()))
	return {"soldiers":soldiers,"workers":able,"one_in":roundi(float(able)/float(soldiers)) if soldiers>0 else 0}


static func _name_of(commander:Variant)->String:
	return String((commander as Dictionary).get("name","")) if commander is Dictionary else ""
