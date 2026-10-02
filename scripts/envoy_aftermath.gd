extends RefCounted
## WHAT A BEATEN PEOPLE SENDS.
##
## A people that has lost towns to us (above all its chief town), that is at
## war with us and losing, or whose town we sacked, does not send heralds to
## demand tribute. The Audience Hall still decides WHEN an envoy comes (the
## pace of visits is unchanged); this module decides WHAT a beaten people
## comes about, from the real state of the war and the occupation:
##   - peace_feeler (the hall's own): they sue for peace;
##   - town_return: they ask the price of a town we hold, and pay it;
##   - captive_plea: they beg for, or ransom, the captives we drove off;
##   - people_plea: they plead for their people living under our garrison;
##   - dread_tribute (the hall's own): they bring tribute, fearing worse;
##   - vengeance_vow: a proud ruler, struck hard, sends defiance instead.
## Chosen by their strength against ours, their ruler's temperament and what
## we did to them (killings, captives, burning -> dread and hatred).
##
## A people with no town left sends nobody (silenced()); if its chief town
## fell, the envoy speaks for the ruler who leads them from another town, and
## says so plainly (dress()).
##
## Answers resolve through real ledgers: goods between stores
## (civilization_exchange), the town handed back
## (occupation_resident_order restore_self_rule), captives on the road turned
## back home or captives at home freed (occupation_transfers), relations,
## dread and the ruler's grudges. Static helpers; envoy_requests.gd delegates
## here for these situation types.

const Hall:=preload("res://scripts/audience_hall.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const CHRONICLE_PATH:="res://scripts/chronicle.gd"
const TOWN_FATE_PATH:="res://scripts/town_fate.gd"

const TYPES:={
	"town_return":{"headline":"comes to ask for a town back","family":"peace"},
	"captive_plea":{"headline":"comes about the captives you took","family":"captives"},
	"people_plea":{"headline":"pleads for its people under your spears","family":"peace"},
	"vengeance_vow":{"headline":"brings a vow of vengeance","family":"war"},
}
## A demand from a beaten people is never raised.
const DEMANDS:=["tribute_demand","emboldened_demand","test_of_resolve","redress_demand","debt_call"]
## Towns of this size or more are towns; smaller places are empty land.
const TOWN_POPULATION:=1.0
## At war with us and losing by this much (war score) counts as beaten.
const BEATEN_SCORE:=10.0

static func handles(situation_type:String)->bool:
	return TYPES.has(situation_type)

static func family(situation_type:String)->String:
	return String((TYPES.get(situation_type,{}) as Dictionary).get("family",situation_type))

static func _rivals()->GDScript:
	return load(RIVALS_PATH) as GDScript

static func _day()->int:
	return int(WorldSimulation.state.elapsed_days) if WorldSimulation.state!=null else 0

static func _civ(civ_id:String)->Dictionary:
	var world:Variant=WorldSimulation.world
	if world==null: return {}
	var index:int=world._civilization_index(civ_id)
	return world.civilizations[index] if index>=0 else {}

static func _given(civ_id:String)->String:
	var r:=_rivals()
	var name:=String(r.call("given",civ_id)) if r!=null else ""
	return name if name!="" else "their ruler"

static func _is_town(region:Dictionary)->bool:
	return bool(region.get("settlement_founded",true)) and float(region.get("population",0.0))>=TOWN_POPULATION

static func _burned(region:Dictionary)->bool:
	var g:Dictionary=region.get("governance",{}) if region.get("governance") is Dictionary else {}
	return bool(g.get("ruined",false)) and float(region.get("damage",0.0))>=1.0

# --------------------------------------------------------------------------
# Where the war stands between them and us
# --------------------------------------------------------------------------

static func standing(civ_id:String)->Dictionary:
	## {held:[{id,name,capital}], burned:[names], left:[{id,name,population}],
	##  capital_name, capital_lost, seat (the town that leads them now),
	##  captives_road, captives_home, at_war, weak, harsh, defeated, silenced}
	var civ:=_civ(civ_id)
	var out:={"held":[],"burned":[],"left":[],"capital_name":"","capital_lost":false,"seat":"","captives_road":0,"captives_home":0,
		"at_war":false,"weak":false,"harsh":0.0,"defeated":false,"silenced":false,"ever_towns":false}
	if civ.is_empty(): return out
	var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	out.at_war=bool(relation.get("at_war",false))
	for r in civ.get("strategic_regions",[]):
		var region:Dictionary=r
		var name:=String(region.get("name",""))
		var capital:=String(region.get("role",""))=="capital"
		var controller:=String(region.get("controller",civ_id))
		if capital: out.capital_name=name
		if controller=="player":
			(out.held as Array).append({"id":String(region.get("id","")),"name":name,"capital":capital})
			out.ever_towns=true
			if capital: out.capital_lost=true
			continue
		if _burned(region) and String(region.get("original_controller",civ_id))==civ_id:
			(out.burned as Array).append(name)
			out.ever_towns=true
			if capital: out.capital_lost=true
			continue
		if controller==civ_id and _is_town(region):
			(out.left as Array).append({"id":String(region.get("id","")),"name":name,"population":float(region.get("population",0.0))})
			out.ever_towns=true
	(out.left as Array).sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.population)>float(b.population))
	if not (out.left as Array).is_empty(): out.seat=String((out.left as Array)[0].name)
	# Captives we drove off: on the road still, or living among us in bonds.
	var mc:Variant=WorldSimulation.military
	if mc!=null and "occupation_transfers" in mc and mc.occupation_transfers!=null:
		for t:Dictionary in mc.occupation_transfers.data.transfers:
			if String(t.get("source",""))==civ_id and String(t.get("status",""))!="citizen": out.captives_road=int(out.captives_road)+int(t.get("people",0))
		for g:Dictionary in mc.occupation_transfers.data.groups:
			if String(g.get("origin",""))==civ_id and String(g.get("status",""))!="citizen":
				out.captives_home=int(out.captives_home)+roundi(float(g.get("share",0.0))*float(WorldSimulation.state.population_exact))
	# Their fighters against ours.
	var ours:=0
	if mc!=null:
		ours+=int((mc.home_army as Dictionary).get("troops",0)) if "home_army" in mc else 0
		for a in mc.field_armies: ours+=int((a as Dictionary).get("troops",0))
		for o in mc.occupation_forces: ours+=int((o as Dictionary).get("troops",0))
	var theirs:=float(civ.get("military_population",float(civ.get("population",0.0))*0.1))
	out.weak=theirs<float(ours)*0.8
	out.harsh=clampf(DIVINE.civ_dread(civ_id),0.0,1.0)
	var losing:=bool(out.at_war) and float(relation.get("war_score",0.0))>=BEATEN_SCORE
	out.defeated=not (out.held as Array).is_empty() or not (out.burned as Array).is_empty() or losing or int(out.captives_road)+int(out.captives_home)>0
	out.silenced=bool(out.ever_towns) and (out.left as Array).is_empty()
	return out

static func silenced(civ_id:String)->bool:
	## A people with no town left sends no envoys; its remnants are refugees
	## and rumour, not an embassy.
	return bool(standing(civ_id).silenced)

static func defeated(civ_id:String)->bool:
	return bool(standing(civ_id).defeated)

static func mix(civ_id:String)->Dictionary:
	## The business a beaten people may come about, weighted by their
	## strength, their ruler's temperament and what was done to them. {} when
	## they are not beaten (the hall's ordinary business stands).
	var st:=standing(civ_id)
	if not bool(st.defeated) or bool(st.silenced): return {}
	var p:=Hall._personality(civ_id)
	var assertive:=float(p.get("assertiveness",0.5)); var empathy:=float(p.get("empathy",0.5)); var bold:=float(p.get("risk_tolerance",0.5))
	var weak:=bool(st.weak)
	var harsh:=float(st.harsh)
	var out:={}
	if bool(st.at_war): out["peace_feeler"]=1.0+(0.8 if weak else 0.0)+empathy*0.4
	if not (st.held as Array).is_empty():
		out["town_return"]=0.7+(0.5 if bool(st.capital_lost) else 0.0)+float(p.get("discipline",0.5))*0.3
		out["people_plea"]=0.4+empathy*0.9+harsh*0.4
	if int(st.captives_road)+int(st.captives_home)>0: out["captive_plea"]=1.2+empathy*0.6
	if weak: out["dread_tribute"]=0.3+harsh*1.2+(1.0-assertive)*0.4
	# Defiance comes from a proud ruler who was struck hard and is not helpless.
	var vow:=(assertive*0.9+bold*0.4+harsh*0.6)*(0.35 if weak else 1.0)
	if (not (st.held as Array).is_empty() or not (st.burned as Array).is_empty() or harsh>=0.1) and not sworn(civ_id): out["vengeance_vow"]=maxf(0.05,vow-0.25)
	return out

# --------------------------------------------------------------------------
# Candidates
# --------------------------------------------------------------------------

static func _surplus(civ_id:String,min_stock:float=20.0)->Dictionary:
	var best:={}
	var best_value:=0.0
	var values:={"Food":1.0,"Timber":1.4,"Stone":1.8,"Clay":1.3,"Fiber Plants":1.5}
	for res in Hall.RESOURCES:
		var stock:=Hall.foreign_stock(civ_id,String(res))
		if stock<min_stock: continue
		var worth:=stock*float(values.get(res,1.0))
		if worth>best_value: best_value=worth; best={"res":String(res),"stock":stock}
	return best

static func _held_first(st:Dictionary)->Dictionary:
	## The town we hold that matters most to them: their chief town first.
	var held:Array=st.held
	for t:Dictionary in held:
		if bool(t.capital): return t
	return held[0] if not held.is_empty() else {}

static func candidate(situation_type:String,civ_id:String,_occasion:Dictionary,rng:RandomNumberGenerator,used:Dictionary,day:int)->Dictionary:
	if not TYPES.has(situation_type): return {}
	var civ:=_civ(civ_id)
	if civ.is_empty(): return {}
	var st:=standing(civ_id)
	if not bool(st.defeated) or bool(st.silenced): return {}
	var name:=String(civ.get("name",civ_id))
	var who:=_given(civ_id)
	var s:={"type":situation_type,"headline":String(TYPES[situation_type].headline)}
	var req:={}
	match situation_type:
		"town_return":
			var town:=_held_first(st)
			if town.is_empty(): return {}
			var offer:=_surplus(civ_id,20.0)
			s.headline="comes to ask for %s back" % String(town.name)
			s.ask=_give_back_key(st)
			req={"town":String(town.name),"city_id":String(town.id),"capital":bool(town.capital)}
			if not offer.is_empty():
				var amount:=Hall._nice(minf(float(offer.stock)*(0.45 if bool(town.capital) else 0.3),maxf(20.0,float(civ.get("population",100.0))*(1.2 if bool(town.capital) else 0.7))))
				if amount>=5.0: req.merge({"pay_res":String(offer.res),"pay_amt":amount})
			s.summary=("%s asks what it would take for %s to be theirs again. %s offers %d %s and the peace of the border." % [name,String(town.name),who,roundi(float(req.pay_amt)),String(req.pay_res)]) if req.has("pay_res") else ("%s asks for %s back. %s has little left to offer but the peace of the border." % [name,String(town.name),who])
		"captive_plea":
			var road:=int(st.captives_road); var home:=int(st.captives_home)
			if road+home<=0: return {}
			var town2:=_held_first(st)
			var from:=String(town2.get("name","")) if not town2.is_empty() else ""
			var ransom:=_surplus(civ_id,15.0)
			s.ask=_give_back_key(st)
			req={"road":road,"home":home,"town":from}
			if not ransom.is_empty() and road>0: req.merge({"pay_res":String(ransom.res),"pay_amt":Hall._nice(minf(float(ransom.stock)*0.3,clampf(float(road)*3.0,8.0,120.0)))})
			var where:="on the road to your country" if road>0 and home==0 else ("living among your people in bonds" if road==0 else "on the road and among your people")
			s.summary="%s asks for the captives you took%s, %d of them %s.%s" % [name," from "+from if from!="" else "",road+home,where,(" %s offers %d %s for those still on the road." % [who,roundi(float(req.pay_amt)),String(req.pay_res)]) if req.has("pay_res") else ""]
		"people_plea":
			var town3:=_held_first(st)
			if town3.is_empty(): return {}
			var region:Dictionary=WorldSimulation.world.region_snapshot(civ_id,String(town3.id))
			s.headline="pleads for the people of %s" % String(town3.name)
			s.ask=_give_back_key(st)
			req={"town":String(town3.name),"city_id":String(town3.id),"people":roundi(float(region.get("population",0.0)))}
			s.summary="%s pleads for the %d people still living in %s under your garrison: that they be left their homes, their stores and their lives." % [name,int(req.people),String(town3.name)]
		"vengeance_vow":
			# A vow is sworn once: by this ruler, for these losses (vow_key).
			if sworn(civ_id): return {}
			var town4:=_held_first(st)
			var what:=String(town4.get("name","")) if not town4.is_empty() else (String((st.burned as Array)[0]) if not (st.burned as Array).is_empty() else "")
			if what=="": what="what you did to them"
			s.headline="brings a vow of vengeance for %s" % what
			s.ask=vow_key(civ_id,st)
			req={"town":what,"seat":String(st.seat)}
			s.summary="%s sends no gift and asks nothing. %s swears that %s will be paid for, however long it takes." % [name,who,what]
	if String(s.get("ask",""))=="" or used.has(String(s.ask)): return {}
	if (String(s.ask).begins_with(GIVE_BACK) or String(s.ask).begins_with(VOW)) and _asked_before(civ_id,String(s.ask)): return {}
	s["req"]=req
	return {"kind":"request","situation":s}

## One plea a conquest. A beaten people asks once for what we took from it
## (the town, its people under our garrison, or the captives: whichever
## matters most to them that day). Granted or refused, it does not ask again
## until we take another town of theirs.
const GIVE_BACK:="aftermath:give_back:"
## A vow of vengeance is sworn ONCE by a ruler for what was lost: not every
## year their envoys come. A new ruler (generation) or a new loss (another
## town taken or burned) may swear again. Kept on the ruler's own record
## (rival_rulers character "vowed"), so the hall's limited memory never lets
## the same vow come round again.
const VOW:="aftermath:vow:"
static func vow_key(civ_id:String,st:Dictionary={})->String:
	if st.is_empty(): st=standing(civ_id)
	var lost:PackedStringArray=PackedStringArray()
	for t:Dictionary in st.get("held",[]): lost.append(String(t.get("id","")))
	for n in st.get("burned",[]): lost.append(String(n))
	lost.sort()
	var r:=_rivals()
	var gen:=int((r.call("character",civ_id) as Dictionary).get("gen",0)) if r!=null else 0
	return VOW+"g%d:%d" % [gen,hash(",".join(lost))]

## Has this ruler already sworn vengeance for these losses?
static func sworn(civ_id:String)->bool:
	var r:=_rivals()
	if r==null: return false
	var c:Dictionary=r.call("character",civ_id)
	return String((c.get("vowed",{}) as Dictionary).get("key","")) == vow_key(civ_id) if c.get("vowed") is Dictionary else false

static func _mark_sworn(civ_id:String,key:String)->void:
	var r:=_rivals()
	if r==null: return
	var c:Dictionary=r.call("character",civ_id)
	if c.is_empty(): return
	c["vowed"]={"key":key.substr(0,80),"day":_day()}
static func _give_back_key(st:Dictionary)->String:
	var ids:PackedStringArray=PackedStringArray()
	for t:Dictionary in st.held: ids.append(String(t.id))
	ids.sort()
	return GIVE_BACK+(",".join(ids) if not ids.is_empty() else "captives")

## Whether this people already asked this, at any time the hall remembers.
static func _asked_before(civ_id:String,ask:String)->bool:
	for entry in Hall.state().ledger:
		if entry is Dictionary and String(entry.get("speaker",""))=="civ:"+civ_id and String(entry.get("ask",""))==ask: return true
	return false

# --------------------------------------------------------------------------
# The envoy speaks for whoever leads them now
# --------------------------------------------------------------------------

static func fall_line(civ_id:String)->String:
	## One plain sentence on what they lost, for the envoy to say first.
	var st:=standing(civ_id)
	var who:=_given(civ_id)
	var civ_name:=String(_civ(civ_id).get("name","our people"))
	if bool(st.capital_lost) and String(st.capital_name)!="":
		var fell:="%s is in your hands" % String(st.capital_name) if (st.held as Array).any(func(t:Dictionary)->bool: return bool(t.capital)) else "%s is burned" % String(st.capital_name)
		if String(st.seat)!="": return "%s, and %s leads the %s from %s now." % [fell,who,civ_name,String(st.seat)]
		return "%s." % fell
	if not (st.held as Array).is_empty():
		return "Your fighters hold %s." % String((st.held as Array)[0].name)
	if not (st.burned as Array).is_empty():
		return "%s is ash because of you." % String((st.burned as Array)[0])
	return ""

static func dress(audience:Dictionary)->void:
	## After the hall and the ruler's memory have dressed the envoy: a people
	## that lost its chief town speaks for the ruler who leads them from
	## another; every envoy of a beaten people names what they lost; and an
	## old quarrel over our tribute is not what a beaten people talks about.
	var civ_id:=String(audience.get("civ_id",""))
	var st:=standing(civ_id)
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	# The vow is sworn the day their envoy brings it.
	if String(situation.get("type",""))=="vengeance_vow": _mark_sworn(civ_id,String(situation.get("ask","")))
	if bool(st.capital_lost) and String(st.seat)!="":
		var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
		var title:=String(speaker.get("title",""))
		var civ_name:=String(audience.get("civ_name",""))
		if title!="" and not "since" in title:
			speaker["title"]="%s, who leads the %s from %s since %s fell" % [title,civ_name,String(st.seat),String(st.capital_name)]
			audience["speaker"]=speaker
		situation["seat"]={"town":String(st.seat),"fallen":String(st.capital_name)}
	if not bool(st.defeated): return
	var line:=fall_line(civ_id)
	if line!="":
		situation["fall_line"]=line
		if not String(situation.get("summary","")).begins_with(line): situation["summary"]=(line+" "+String(situation.get("summary",""))).strip_edges().substr(0,700)
	var recall:Dictionary=situation.get("recall",{}) if situation.get("recall") is Dictionary else {}
	var said:=String(recall.get("text","")).to_lower()
	if "tribute" in said or "demand" in said:
		situation["summary"]=String(situation.get("summary","")).replace(" "+String(recall.get("text","")),"")
		situation.erase("recall")
	situation["no_followup"]=true
	audience["situation"]=situation

# --------------------------------------------------------------------------
# Answers
# --------------------------------------------------------------------------

static func _req(audience:Dictionary)->Dictionary:
	var s:=Hall._situation(audience)
	return s.get("req",{}) if s.get("req") is Dictionary else {}

static func _n(v:Variant)->int:
	return roundi(float(v))

static func options(audience:Dictionary)->Array[Dictionary]:
	var type:=Hall._situation_type(audience)
	var p:=_req(audience)
	var civ_id:=String(audience.get("civ_id",""))
	var name:=String(audience.get("civ_name",Hall._civ_name(civ_id)))
	var o:Array[Dictionary]=[]
	match type:
		"town_return":
			if p.has("pay_res"): o.append(Hall._option("accept","Give it back for their price","They pay %d %s; our garrison leaves %s and marches home." % [_n(p.pay_amt),String(p.pay_res),String(p.town)],"neutral"))
			o.append(Hall._option("gift","Give it back freely","Our garrison leaves %s and marches home. %s will not soon forget it." % [String(p.town),name],"warm"))
			o.append(Hall._option("refuse","Keep it","%s stays ours. They go home with nothing, and angrier." % String(p.town),"hostile"))
		"captive_plea":
			var road:=int(p.get("road",0)); var home:=int(p.get("home",0))
			if road>0 and p.has("pay_res"): o.append(Hall._option("accept","Take the ransom and send them home","They pay %d %s; the %d still on the road turn back for home.%s" % [_n(p.pay_amt),String(p.pay_res),road," Those already here are freed." if home>0 else ""],"neutral"))
			o.append(Hall._option("gift","Let them go freely","%s%s" % [("The %d on the road turn back for home. " % road) if road>0 else "",("The %d living among us are freed, with our rights." % home) if home>0 else ""],"warm"))
			o.append(Hall._option("refuse","Keep them","The captives stay ours. %s will count it against you." % name,"hostile"))
		"people_plea":
			o.append(Hall._option("accept","Promise them mercy","The garrison leaves the people of %s their homes and lives, and keeps them safe." % String(p.town),"warm"))
			o.append(Hall._option("bargain","Their people's safety is their good conduct","Nobody is harmed while %s keeps the peace. They obey out of fear." % name,"neutral"))
			o.append(Hall._option("refuse","Promise nothing","The people of %s live at your word, and their kin know it." % String(p.town),"hostile"))
		"vengeance_vow":
			o.append(Hall._option("gift","Answer with an offer of peace","Tell them the killing can stop if they want it to.","warm"))
			o.append(Hall._option("accept","Hear them and send them home","Let the words stand. Nothing is given, nothing threatened.","neutral"))
			o.append(Hall._option("refuse","Answer with a warning","Tell them what happened at %s can happen again." % String(p.town),"hostile"))
	for option in o:
		if bool(option.get("enabled",true)): option["cost"]=("Risk: " if String(option.id) in ["refuse","bargain"] else "Cost: ")+String(option.sub)
	return o

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var type:=Hall._situation_type(audience)
	var p:=_req(audience)
	var civ_id:=String(audience.civ_id)
	var name:=String(audience.get("civ_name",Hall._civ_name(civ_id)))
	var who:=_given(civ_id)
	var mood:=Hall._mood_opinion(audience)
	var outcome:=""
	var reaction:="neutral"
	var memory:=""
	var r:=_rivals()
	match "%s:%s" % [type,option_id]:
		"town_return:accept","town_return:gift":
			var world:Variant=WorldSimulation.world
			var back:Dictionary=world.occupation_resident_order(civ_id,String(p.city_id),"restore_self_rule")
			if back.has("error"): return {"error":String(back.error)}
			var paid:=0.0
			if option_id=="accept" and p.has("pay_res"):
				paid=Hall.EXCHANGE.take(civ_id,String(p.pay_res),float(p.pay_amt))
				if paid>0.0: Hall.EXCHANGE.receive("player",String(p.pay_res),paid)
			Hall._shift_relation(civ_id,(0.1 if option_id=="accept" else 0.18)+mood,-0.2)
			Hall._leader_trust(civ_id,0.08 if option_id=="accept" else 0.14)
			reaction="pleased" if option_id=="accept" else "delighted"
			outcome=("%s paid %d %s, and %s is theirs again. Our garrison is marching home." % [name,roundi(paid),String(p.pay_res),String(p.town)]) if option_id=="accept" else ("You gave %s back to %s. Our garrison is marching home." % [String(p.town),name])
			memory="The god's people gave %s back to us%s." % [String(p.town)," for a price" if option_id=="accept" else ", asking nothing"]
			_chronicle("%s Given Back" % String(p.town),outcome,civ_id)
		"town_return:refuse":
			Hall._shift_relation(civ_id,-0.04+mood,0.08)
			if r!=null: r.call("grudge",civ_id,"%s, which you would not give back" % String(p.town),0.5,"aftermath:keep:%s" % String(p.city_id))
			reaction="offended"
			outcome="You kept %s. %s's envoy goes home with nothing." % [String(p.town),name]
			memory="The god's people would not give %s back." % String(p.town)
		"captive_plea:accept","captive_plea:gift":
			var turned:=_turn_back_captives(civ_id)
			var freed:=_free_captives(civ_id)
			var paid2:=0.0
			if option_id=="accept" and p.has("pay_res") and turned>0:
				paid2=Hall.EXCHANGE.take(civ_id,String(p.pay_res),float(p.pay_amt))
				if paid2>0.0: Hall.EXCHANGE.receive("player",String(p.pay_res),paid2)
			if turned<=0 and freed<=0: return {"error":"There are no captives of theirs left to give back."}
			Hall._shift_relation(civ_id,(0.08 if option_id=="accept" else 0.14)+mood,-0.1)
			Hall._leader_trust(civ_id,0.06 if option_id=="accept" else 0.1)
			reaction="pleased" if option_id=="accept" else "delighted"
			var bits:PackedStringArray=PackedStringArray()
			if turned>0: bits.append("%d captives on the road turned back for home" % turned)
			if freed>0: bits.append("the captives living among us are free people now")
			outcome="%s%s." % [(", ".join(bits)).substr(0,1).to_upper(),(", ".join(bits)).substr(1)]
			if paid2>0.0: outcome+=" %s paid %d %s for them." % [name,roundi(paid2),String(p.pay_res)]
			memory="The god's people let our captives go%s." % (" for a ransom" if paid2>0.0 else "")
			_chronicle("Captives Returned to %s" % name,outcome,civ_id)
		"captive_plea:refuse":
			Hall._shift_relation(civ_id,-0.05+mood,0.06)
			DIVINE.add_civ_dread(civ_id,0.03)
			if r!=null: r.call("grudge",civ_id,"the captives you kept",0.6,"aftermath:captives")
			reaction="offended"
			outcome="You kept the captives. %s's envoy goes home without them." % name
			memory="The god's people kept our captives."
		"people_plea:accept":
			var fate:Variant=(load(TOWN_FATE_PATH) as GDScript).call("apply",civ_id,String(p.city_id),{"spare":true},{})
			Hall._shift_relation(civ_id,0.08+mood,-0.08)
			Hall._leader_trust(civ_id,0.06)
			reaction="pleased"
			outcome="You promised mercy to the people of %s. %s" % [String(p.town),String((fate as Dictionary).get("text","")) if fate is Dictionary and not (fate as Dictionary).has("error") else "The garrison is told to keep them safe."]
			memory="The god promised mercy to our people in %s." % String(p.town)
		"people_plea:bargain":
			DIVINE.add_civ_dread(civ_id,0.06)
			Hall._shift_relation(civ_id,-0.01+mood,-0.04)
			reaction="neutral"
			outcome="You told %s that the people of %s are safe while %s keeps the peace. They will obey out of fear." % [name,String(p.town),who]
			memory="The god holds our people in %s against our good conduct." % String(p.town)
		"people_plea:refuse":
			DIVINE.add_civ_dread(civ_id,0.05)
			Hall._shift_relation(civ_id,-0.05+mood,0.06)
			reaction="offended"
			outcome="You promised nothing for the people of %s. Their kin will remember it." % String(p.town)
			memory="The god would promise nothing for our people in %s." % String(p.town)
		"vengeance_vow:gift":
			Hall._shift_relation(civ_id,0.04+mood,-0.06)
			reaction="neutral"
			outcome="You answered %s's vow with an offer of peace. The envoy did not accept it, but will carry it home." % who
			memory="The god answered our vow with an offer of peace."
		"vengeance_vow:accept":
			Hall._shift_relation(civ_id,mood,0.02)
			reaction="neutral"
			outcome="You heard %s's vow and sent the envoy home. Nothing was given." % who
			memory="The god heard our vow and gave no answer."
		"vengeance_vow:refuse":
			DIVINE.add_civ_dread(civ_id,0.05)
			Hall._shift_relation(civ_id,-0.04+mood,0.08)
			if r!=null: r.call("grudge",civ_id,"your threat over %s" % String(p.town),0.4,"aftermath:vow")
			reaction="offended"
			outcome="You warned %s that what happened at %s can happen again. The envoy left in silence." % [name,String(p.town)]
			memory="The god threatened us again after %s." % String(p.town)
		_:
			return {"error":"That answer is not open to you here."}
	if memory!="": ForeignDiplomacy.remember(civ_id,memory)
	return {"outcome":outcome,"reaction":reaction}

static func _turn_back_captives(civ_id:String)->int:
	## Captives still on the road turn back: they leave our transit and are
	## counted among their own people again.
	var mc:Variant=WorldSimulation.military
	var world:Variant=WorldSimulation.world
	if mc==null or world==null: return 0
	var kept:Array=[]
	var turned:=0
	var index:int=world._civilization_index(civ_id)
	for t:Dictionary in mc.occupation_transfers.data.transfers:
		if String(t.get("source",""))!=civ_id or String(t.get("status",""))=="citizen" or index<0: kept.append(t); continue
		var people:=int(t.get("people",0))
		var civ:Dictionary=world.civilizations[index]
		civ.population=float(civ.population)+people
		var ri:int=world._region_index(civ,String(t.get("region","")))
		if ri>=0: civ.strategic_regions[ri]["population"]=float(civ.strategic_regions[ri].get("population",0.0))+people
		world.civilizations[index]=civ
		turned+=people
	mc.occupation_transfers.data.transfers=kept
	return turned

static func _free_captives(civ_id:String)->int:
	## Captives already living among us are freed, with our rights.
	var mc:Variant=WorldSimulation.military
	if mc==null: return 0
	var freed:=0
	for g:Dictionary in mc.occupation_transfers.data.groups:
		if String(g.get("origin",""))!=civ_id or String(g.get("status",""))=="citizen": continue
		if not mc.occupation_transfers.emancipate(int(g.id)).has("error"): freed+=1
	return freed

static func _chronicle(title:String,text:String,civ_id:String)->void:
	var chronicle:=load(CHRONICLE_PATH) as GDScript
	if chronicle!=null: chronicle.call("record",{"key":"aftermath:%s:%d" % [civ_id,_day()],"title":title.substr(0,70),"text":text,"tier":"moment","kind":"war","domain":"diplomacy","action":{"kind":"court","focus":{"civ_id":civ_id}}})

# --------------------------------------------------------------------------
# Opening words
# --------------------------------------------------------------------------

static func open_lines(audience:Dictionary)->Array:
	var type:=Hall._situation_type(audience)
	if not TYPES.has(type): return []
	var p:=_req(audience)
	var civ_id:=String(audience.get("civ_id",""))
	var who:=_given(civ_id)
	var fall:=String(Hall._situation(audience).get("fall_line",""))
	var out:Array=[]
	match type:
		"town_return":
			var offer:=(" %s will give %d %s for it." % [who,_n(p.pay_amt),String(p.pay_res)]) if p.has("pay_res") else " We have little left to give, but the border would be quiet."
			out.append("%s %s asks what it would take to have %s back.%s" % [fall,who,String(p.town),offer])
			out.append("Name your price for %s.%s" % [String(p.town),offer])
		"captive_plea":
			var n:=int(p.get("road",0))+int(p.get("home",0))
			var pay:=(" %s sends %d %s for those still on the road." % [who,_n(p.pay_amt),String(p.pay_res)]) if p.has("pay_res") else ""
			out.append("%s You took %d of our people%s. Let them come home.%s" % [fall,n," from "+String(p.town) if String(p.get("town",""))!="" else "",pay])
			out.append("Their families are asking for them.%s" % pay)
		"people_plea":
			out.append("%s %d of our people still live in %s under your spears. %s asks that they keep their homes and their lives." % [fall,int(p.people),String(p.town),who])
			out.append("They are farmers and children. Let them live in %s." % String(p.town))
		"vengeance_vow":
			out.append("%s %s did not send me to ask for anything. %s swears that %s will be paid for." % [fall,who,who,String(p.town)])
			out.append("%s will be paid for. That is all I was sent to say." % String(p.town))
	var clean:Array=[]
	for line in out: clean.append(String(line).strip_edges().replace("  "," "))
	return clean
