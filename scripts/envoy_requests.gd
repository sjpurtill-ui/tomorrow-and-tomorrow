extends RefCounted
## What foreign envoys ask for, drawn from the real state of both peoples.
##
## The Audience Hall decides WHEN an envoy comes (occasions, budgets, gaps);
## this module only widens WHAT they may come about, so the pace of visits is
## untouched: new business is offered only alongside business the hall could
## already truthfully back (see AudienceHall._foreign_candidates).
##
## Every request is grounded in state (a famine, sickness, a quarrel with a
## third people, a new ruler, a craft they lack, a surplus they can trade, a
## tense border, households that crossed over) and resolves through bounded
## changes to real ledgers and relations: stores move between peoples,
## people settle or leave, health, border tension and trust shift, and the
## foreign ruler's memory (rival_rulers.gd grudges, debts and bonds) keeps
## what happened. Loans fall due and are repaid, late or never, by traders
## (a Chronicle line, never an extra envoy).
##
## This deterministic generator is the shared core. Offline it is the whole
## story; online, envoy_request_ai.gd lets the model choose among the valid
## candidates and phrase the chosen one, validated and clamped here.
##
## State: AudienceHall.state().envoy_requests = {recent:[{d,c,t}], pledges:[...], took_in:{civ:n}}.
## Static helpers; the hall loads this lazily.

const Hall:=preload("res://scripts/audience_hall.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const SOCIETY:=preload("res://scripts/society_exchange.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const CV:=preload("res://scripts/character_voice.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const CHRONICLE_PATH:="res://scripts/chronicle.gd"

const RECENT_MAX:=40
const PLEDGES_MAX:=16
const TICK:=10
## Relative worth of goods when a people trades or repays in kind.
const VALUES:={"Food":1.0,"Timber":1.4,"Stone":1.8,"Clay":1.3,"Fiber Plants":1.5}
const PLACES:=["north woods","east ridge","river bend","upper valley","south marsh","west hills","old ford","far meadows"]

## Each request: its herald headline and its family (variety is judged by
## family as well as by type, so "Food, Food, Food" cannot recur in disguise).
const TYPES:={
	"food_loan":{"headline":"asks to borrow food against their next harvest","family":"food","help":true},
	"work_for_food":{"headline":"offers their labour for food","family":"labour","help":true},
	"barter":{"headline":"offers a trade of goods","family":"trade"},
	"refuge":{"headline":"asks you to take in their families","family":"people","help":true},
	"forage_leave":{"headline":"asks leave to hunt in your country","family":"land"},
	"craft_teaching":{"headline":"asks for a teacher of your craft","family":"knowledge"},
	"healer_plea":{"headline":"asks for your healers","family":"health","help":true},
	"mediation":{"headline":"asks the god to judge a quarrel","family":"judgment"},
	"marriage_request":{"headline":"seeks a marriage into your people","family":"kin"},
	"border_line":{"headline":"wants the border fixed","family":"land"},
	"fugitive_return":{"headline":"demands a fugitive back","family":"judgment"},
	"blessing_rite":{"headline":"asks the god's blessing","family":"divine"},
	"war_supplies":{"headline":"asks for supplies for their war","family":"war"},
	"succession_backing":{"headline":"asks you to recognise their new ruler","family":"kin"},
	"hostage_exchange":{"headline":"proposes an exchange of pledges","family":"peace"},
	"sacred_site":{"headline":"asks leave to visit a sacred place","family":"divine"},
}
## Families of the hall's own situations, for the variety rule.
const HALL_FAMILY:={"aid_request":"food","gift_goods":"gift","gratitude_gift":"gift","dread_tribute":"gift","artifact_gift":"gift",
	"tribute_demand":"demand","emboldened_demand":"demand","test_of_resolve":"demand","redress_demand":"demand","debt_call":"demand",
	"trade_offer":"trade","artifact_purchase":"trade","research_sale":"knowledge","license_offer":"knowledge","scholar_offer":"knowledge",
	"news_report":"news","rumor_share":"news","intelligence_share":"news","accord_offer":"pact","protection_pact":"pact","league_invitation":"pact",
	"nonaggression_offer":"peace","peace_feeler":"peace","war_support":"war","artifact_return":"judgment","recruitment_protest":"judgment"}

## Which requests each occasion may also bring (their own candidates decide
## whether the state truly backs them).
const EXTRA_MIX:={
	"their_famine":{"food_loan":1.0,"work_for_food":0.8,"barter":0.7,"refuge":0.6,"forage_leave":0.6,"healer_plea":0.4},
	"ambient":{"work_for_food":0.3,"barter":0.5,"craft_teaching":0.5,"healer_plea":0.8,"mediation":0.6,"marriage_request":0.35,"border_line":0.6,"fugitive_return":0.35,
		"blessing_rite":0.4,"war_supplies":0.6,"succession_backing":0.9,"sacred_site":0.35,"refuge":0.4,"forage_leave":0.3},
	"first_contact":{"barter":0.4,"sacred_site":0.4,"craft_teaching":0.3,"blessing_rite":0.3},
	"relation_warm":{"marriage_request":0.6,"craft_teaching":0.5,"blessing_rite":0.5,"barter":0.4,"sacred_site":0.4,"succession_backing":0.5},
	"relation_cool":{"border_line":0.9,"fugitive_return":0.5,"sacred_site":0.3},
	"tension_rise":{"border_line":1.2,"hostage_exchange":0.6,"fugitive_return":0.4},
	"war_end":{"hostage_exchange":1.0,"refuge":0.5,"border_line":0.5},
	"third_war":{"war_supplies":1.0,"refuge":0.5},
}

## Tests: switch the wider business off to compare against the hall alone.
static var enabled:=true

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func store()->Dictionary:
	var s:=Hall.state()
	if not s.get("envoy_requests") is Dictionary: s["envoy_requests"]={}
	var e:Dictionary=s.envoy_requests
	if not e.get("recent") is Array: e["recent"]=[]
	if not e.get("pledges") is Array: e["pledges"]=[]
	if not e.get("took_in") is Dictionary: e["took_in"]={}
	return e

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	var d:Dictionary=data
	if not d.get("recent",[]) is Array or (d.get("recent",[]) as Array).size()>RECENT_MAX: return false
	for r in d.get("recent",[]):
		if not r is Dictionary or not Hall._num(r.get("d")) or not r.get("t","") is String or not r.get("c","") is String: return false
	if not d.get("pledges",[]) is Array or (d.get("pledges",[]) as Array).size()>PLEDGES_MAX: return false
	for p in d.get("pledges",[]):
		if not p is Dictionary or not Hall._num(p.get("amt")) or not Hall._num(p.get("due")) or not String(p.get("res","")) in Hall.RESOURCES or JSON.stringify(p).length()>800: return false
	if not d.get("took_in",{}) is Dictionary or (d.get("took_in",{}) as Dictionary).size()>256: return false
	return true

static func handles(situation_type:String)->bool:
	return TYPES.has(situation_type)

static func is_help(situation_type:String)->bool:
	return bool((TYPES.get(situation_type,{}) as Dictionary).get("help",false))

static func family(situation_type:String)->String:
	if TYPES.has(situation_type): return String(TYPES[situation_type].family)
	return String(HALL_FAMILY.get(situation_type,situation_type))

static func brings_sequel(situation_type:String,option_id:String)->bool:
	## Help given brings the same people back in gratitude, as food aid does.
	return is_help(situation_type) and option_id in ["accept","gift","partial"]

static func _rivals()->GDScript:
	return load(RIVALS_PATH) as GDScript

static func _day()->int:
	return int(GameState.elapsed_days)

# --------------------------------------------------------------------------
# Variety
# --------------------------------------------------------------------------

static func note_arrival(audience:Dictionary)->void:
	var t:=Hall._situation_type(audience)
	var recent:Array=store().recent
	var id:=String(audience.get("id",""))
	# A revised request (the live model chose another) replaces its own entry.
	for index in range(recent.size()-1,-1,-1):
		if String((recent[index] as Dictionary).get("a",""))==id and id!="": recent.remove_at(index)
	recent.append({"d":int(audience.get("arrived_day",_day())),"c":String(audience.get("civ_id","")),"t":t,"a":id})
	while recent.size()>RECENT_MAX: recent.pop_front()

static func recent_kinds(limit:int=6)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var recent:Array=store().recent
	for index in range(recent.size()-1,-1,-1):
		out.append((recent[index] as Dictionary).duplicate())
		if out.size()>=limit: break
	return out

static func variety_factor(situation_type:String,civ_id:String,day:int)->float:
	## The same business back to back, or a family heard twice running, grows
	## unlikely; so does a people repeating itself within three years.
	var f:=1.0
	var recent:Array=store().recent
	if recent.is_empty(): return f
	var mine:=family(situation_type)
	var last:Dictionary=recent[-1]
	if String(last.t)==situation_type: f*=0.2
	elif family(String(last.t))==mine: f*=0.45
	for index in range(recent.size()-2,maxi(-1,recent.size()-5),-1):
		if String((recent[index] as Dictionary).t)==situation_type: f*=0.6
	for entry in recent:
		if String((entry as Dictionary).c)==civ_id and String((entry as Dictionary).t)==situation_type and day-int((entry as Dictionary).d)<1095: f*=0.3
	return f

static func extra_mix(occasion_type:String)->Dictionary:
	if not enabled: return {}
	return (EXTRA_MIX.get(occasion_type,{}) as Dictionary).duplicate()

static func temperament(situation_type:String,civ_id:String)->float:
	var p:=Hall._personality(civ_id)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var opinion:=float((civ.get("player_relation",{}) as Dictionary).get("opinion",0.0))
	match situation_type:
		"border_line","fugitive_return": return maxf(0.1,0.4+float(p.assertiveness)*1.0+maxf(0.0,-opinion))
		"marriage_request","blessing_rite","sacred_site","succession_backing": return maxf(0.1,0.5+maxf(0.0,opinion)*1.2+float(p.empathy)*0.4)
		"craft_teaching","barter": return 0.5+float(p.openness)*0.9
		"mediation","hostage_exchange": return 0.5+float(p.discipline)*0.6+float(p.empathy)*0.3
		"war_supplies": return 0.5+float(p.assertiveness)*0.6
	return 1.0

# --------------------------------------------------------------------------
# Candidates: what the state truly backs
# --------------------------------------------------------------------------

static func _civ_ok(civ:Dictionary)->bool:
	return not civ.is_empty() and bool(civ.get("alive",true))

static func _at_war(civ:Dictionary)->bool:
	return bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false))

static func _pop(civ:Dictionary)->float:
	return maxf(20.0,float(civ.get("population",100)))

static func _given(civ_id:String)->String:
	var r:=_rivals()
	var name:=String(r.call("given",civ_id)) if r!=null else ""
	return name if name!="" else String(ForeignDiplomacy.leader(civ_id).get("name","their ruler")).get_slice(" ",0)

static func _surplus(civ_id:String,exclude:Array,min_stock:float=30.0)->Dictionary:
	## What they hold most of (by worth), from their real ledger.
	var best:={}
	var best_value:=0.0
	for res in Hall.RESOURCES:
		if String(res) in exclude: continue
		var stock:=Hall.foreign_stock(civ_id,String(res))
		if stock<min_stock: continue
		var worth:=stock*float(VALUES.get(res,1.0))
		if worth>best_value: best_value=worth; best={"res":String(res),"stock":stock}
	return best

static func _pick(list:Array,rng:RandomNumberGenerator)->String:
	return String(list[rng.randi_range(0,list.size()-1)])

static func _third_tense(civ:Dictionary)->Dictionary:
	## A third people they quarrel with (tense border, not yet war).
	var best:={}
	var best_t:=0.5
	var relations:Dictionary=civ.get("relations",{}) if civ.get("relations") is Dictionary else {}
	for other in relations:
		var id:=String(other)
		if id in ["player",String(civ.get("id",""))] or not relations[other] is Dictionary: continue
		var rel:Dictionary=relations[other]
		var index:=Hall._civ_index(id)
		if index<0 or not bool(WorldSimulation.world.civilizations[index].get("alive",true)) or bool(rel.get("at_war",false)): continue
		var t:=float(rel.get("border_tension",0.0))
		if t>=best_t: best_t=t; best={"id":id,"name":Hall._civ_name(id),"tension":t}
	return best

static func _third_war(civ:Dictionary,prefer:String="")->Dictionary:
	var wars:=Hall._third_wars(civ)
	if wars.is_empty(): return {}
	var id:=prefer if prefer in wars else String(wars[0])
	return {"id":id,"name":Hall._civ_name(id)}

static func candidate(situation_type:String,civ_id:String,occasion:Dictionary,rng:RandomNumberGenerator,used:Dictionary,day:int)->Dictionary:
	if not enabled or not TYPES.has(situation_type): return {}
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if not _civ_ok(civ) or _at_war(civ): return {}
	var relation:Dictionary=civ.get("player_relation",{})
	var name:=String(civ.get("name",civ_id))
	var who:=_given(civ_id)
	var pop:=_pop(civ)
	var player_pop:=Hall._player_population()
	var opinion:=float(relation.get("opinion",0.0))
	var data:Dictionary=occasion.get("data",{}) if occasion.get("data") is Dictionary else {}
	var s:={"type":situation_type,"headline":String(TYPES[situation_type].headline)}
	var req:={}
	var terms:={}
	var r:=_rivals()
	match situation_type:
		"food_loan":
			if not Hall._hungry(civ): return {}
			var have:=Hall.player_stock("Food")
			var amount:=Hall._nice(minf(pop*rng.randf_range(0.35,0.55),have*0.25))
			if amount<10.0 or amount>have: return {}
			var repay:=_surplus(civ_id,["Food"],20.0)
			var repay_res:=String(repay.get("res","Food"))
			var repay_amt:=Hall._nice(amount*1.3*float(VALUES.Food)/float(VALUES.get(repay_res,1.0)))
			var episode:=int(data.get("episode",floori(day/365.0)))
			s.ask="er:food_loan:%d" % episode
			req={"amount":amount,"repay_res":repay_res,"repay_amt":repay_amt,"due_in":rng.randi_range(240,360)}
			terms={"resource":"Food","amount":amount}
			s.summary="%s's stores would last about %d days. %s asks to borrow %d Food and promises %d %s back within the year." % [name,roundi(float(civ.get("food_days",0))),who,roundi(amount),roundi(repay_amt),repay_res]
		"work_for_food":
			if not Hall._hungry(civ): return {}
			var have2:=Hall.player_stock("Food")
			var food:=Hall._nice(minf(pop*rng.randf_range(0.25,0.4),have2*0.2))
			if food<10.0 or food>have2: return {}
			var workers:=clampi(roundi(pop*0.08),4,30)
			var place0:=_pick(PLACES,rng)
			var yields:={"Timber":"woods","Stone":"quarries","Clay":"clay pits","Fiber Plants":"reed beds"}
			var goods:=_pick(yields.keys(),rng)
			var amount0:=Hall._nice(float(workers)*60.0*0.12*float(VALUES.Food)/float(VALUES.get(goods,1.0))*rng.randf_range(0.9,1.2))
			s.ask="er:labour:%d" % floori(day/365.0)
			req={"food":food,"workers":workers,"res":goods,"amount":amount0,"where":"%s in the %s" % [String(yields[goods]),place0],"days":60}
			terms={"resource":"Food","amount":food}
			s.summary="%s offers %d of its young people to work your %s for two months, bringing in about %d %s, for %d Food now to feed their families." % [name,workers,String(req.where),roundi(amount0),goods,roundi(food)]
		"barter":
			var want:=""
			if Hall._hungry(civ): want="Food"
			else:
				for res in Hall.STRATEGY_WANTS.get(String(civ.get("strategy","")),[]):
					if Hall.player_stock(String(res))>=30.0: want=String(res); break
			if want=="":
				var best:=0.0
				for res in Hall.RESOURCES:
					var mine:=Hall.player_stock(String(res))
					var theirs:=maxf(1.0,Hall.foreign_stock(civ_id,String(res)))
					if mine>=30.0 and mine/theirs>best: best=mine/theirs; want=String(res)
			if want=="": return {}
			var offer:=_surplus(civ_id,[want],40.0)
			if offer.is_empty(): return {}
			var give:=Hall._nice(minf(pop*(0.5 if want=="Food" else 0.15)*rng.randf_range(0.8,1.2),Hall.player_stock(want)*0.2))
			if give<8.0: return {}
			var receive:=Hall._nice(give*float(VALUES.get(want,1.0))/float(VALUES.get(offer.res,1.0))*rng.randf_range(1.0,1.2))
			var cap:=float(offer.stock)*0.35
			if receive>cap:
				give=Hall._nice(give*cap/receive); receive=Hall._nice(cap)
			if give<8.0 or receive<5.0: return {}
			s.ask="er:barter:%s:%s" % [want,String(offer.res)]
			req={"give_res":want,"give_amt":give,"get_res":String(offer.res),"get_amt":receive}
			terms={"resource":want,"amount":give}
			s.summary="%s offers %d %s for %d %s: it has %s to spare and is short of %s." % [name,roundi(receive),String(offer.res),roundi(give),want,String(offer.res),want]
		"refuge":
			var reason:=""
			if Hall._hungry(civ): reason="hunger"
			elif float(civ.get("health",0.7))<0.5: reason="sickness"
			elif not Hall._third_wars(civ).is_empty() or float(civ.get("displaced_population",0.0))>0.0: reason="war"
			if reason=="" or pop<40.0: return {}
			var people:=clampi(roundi(minf(pop*0.06,player_pop*0.05)*rng.randf_range(0.8,1.2)),3,40)
			s.ask="er:refuge:%s:%d" % [reason,floori(day/365.0)]
			req={"people":people,"reason":reason}
			var why:String={"hunger":"driven out by hunger","sickness":"fleeing the sickness in their camps","war":"driven from their homes by war"}[reason]
			s.summary="%d of %s's people, most of them families %s, ask to settle among your people." % [people,name,why]
		"forage_leave":
			if not (Hall._hungry(civ) or String(civ.get("strategy","")) in ["expansion","growth","sustenance"]): return {}
			if r!=null and not (r.call("has_bond",civ_id,["hunting"]) as Dictionary).is_empty(): return {}
			var place:=_pick(PLACES,rng)
			var monthly:=Hall._nice(clampf(pop*0.02,2.0,maxf(2.0,player_pop*0.03)))
			var pay:=_surplus(civ_id,["Food"],30.0)
			s.ask="er:forage:%s" % place
			req={"place":place,"monthly":monthly,"months":6}
			if not pay.is_empty(): req.merge({"pay_res":String(pay.res),"pay_amt":Hall._nice(minf(float(pay.stock)*0.2,monthly*6.0*0.7/float(VALUES.get(pay.res,1.0))))})
			s.summary="%s's hunters ask leave to hunt and gather in your %s for half a year; they would take about %d Food a month from that country." % [name,place,roundi(monthly)]
		"craft_teaching":
			if opinion<-0.1 or r==null: return {}
			var craft:Dictionary=r.call("_craft",civ_id)
			if craft.is_empty() or used.has("er:craft:"+String(craft.id)): return {}
			var pay2:=_surplus(civ_id,[],20.0)
			if pay2.is_empty(): return {}
			var amt:=Hall._nice(minf(clampf(pop*0.15,8.0,60.0),float(pay2.stock)*0.3))
			if amt<5.0: return {}
			s.ask="er:craft:"+String(craft.id)
			req={"craft":String(craft.id),"craft_name":String(craft.name),"pay_res":String(pay2.res),"pay_amt":amt}
			s.summary="%s wants a teacher of %s from your people, and offers %d %s for the teaching." % [name,String(craft.name),roundi(amt),String(pay2.res)]
		"healer_plea":
			var health:=float(civ.get("health",0.7))
			if health>=0.55: return {}
			var herbs:=Hall._nice(clampf(pop*0.05,5.0,30.0))
			s.ask="er:healers:%d" % floori(day/365.0)
			req={"herbs":herbs,"risk":rng.randf()<0.45}
			terms={"resource":"Fiber Plants","amount":herbs}
			s.summary="Sickness is running through %s's camps. %s asks for your healers and %d Fiber Plants for poultices." % [name,who,roundi(herbs)]
		"mediation":
			var third:=_third_tense(civ)
			if third.is_empty() or used.has("er:judge:"+String(third.id)): return {}
			var place2:=_pick(PLACES,rng)
			s.ask="er:judge:"+String(third.id)
			req={"third":String(third.id),"third_name":String(third.name),"place":place2}
			s.summary="%s and %s both claim the %s, and their hunters have come to blows over it. %s asks the god to judge between them." % [name,String(third.name),place2,who]
		"marriage_request":
			if opinion<0.2 or r==null or not (r.call("has_bond",civ_id,["marriage","inlaw"]) as Dictionary).is_empty(): return {}
			var woman:=rng.randf()<0.5
			var serial:=posmod(hash("%s:heir_match:%d" % [civ_id,floori(day/365.0)]),90000)+40000
			var heir:=String(EraNames.make(int(GameState.world_seed),serial,woman,civ_id,{String(ForeignDiplomacy.leader(civ_id).get("name","")):true}).get("name","")).get_slice(" ",0)
			if heir=="": return {}
			s.ask="er:marriage:%d" % floori(day/730.0)
			req={"heir":heir,"woman":woman}
			s.summary="%s's %s %s is of age. %s asks for a young %s of your people to marry into its ruling house." % [who,"daughter" if woman else "son",heir,who,"man" if woman else "woman"]
		"border_line":
			if float(relation.get("border_tension",0.0))<0.35: return {}
			var place3:=_pick(PLACES,rng)
			var timber:=Hall._nice(clampf(player_pop*0.1,5.0,40.0))
			s.ask="er:border:"+place3
			req={"place":place3,"timber":timber,"monthly":Hall._nice(clampf(pop*0.01,1.0,6.0))}
			s.summary="%s wants the line between your peoples fixed at the %s, which would leave that ground and its woods on its side." % [name,place3]
		"fugitive_return":
			var took:=int((store().took_in as Dictionary).get(civ_id,0))
			if int(relation.get("recruitment_visits",0))<=0 and took<=0: return {}
			var woman2:=rng.randf()<0.3
			var serial2:=posmod(hash("%s:fugitive:%d" % [civ_id,day]),90000)+50000
			var fled:=String(EraNames.make(int(GameState.world_seed),serial2,woman2,civ_id,{}).get("name","")).get_slice(" ",0)
			if fled=="": return {}
			var why2:=_pick(["a killing in a quarrel over game","a fight that left a hunter blind","stealing from the stores in a hard winter"],rng)
			var price:=Hall._nice(clampf(player_pop*0.08,5.0,40.0))
			s.ask="er:fugitive:%d" % floori(day/365.0)
			req={"name":fled,"woman":woman2,"why":why2,"price":price}
			s.summary="%s says %s, who fled to your people after %s, must be handed back to answer for it." % [name,fled,why2]
		"blessing_rite":
			var regard:=DIVINE.foreign_regard(civ_id)
			if regard.is_empty() or not (float(regard.love)>=0.6 or float(regard.dread)>=0.5): return {}
			var what:=""
			var lineage:Array=(r.call("character",civ_id) as Dictionary).get("lineage",[]) if r!=null else []
			if not lineage.is_empty() and day-int((lineage[0] as Dictionary).get("died",-99999))<=540: what="the first year of %s's rule" % who
			elif float(civ.get("health",0.7))<0.6: what="their sick"
			elif float(civ.get("food_days",30))>45.0: what="their planting" if CV.era_tags(civ_id).has("farming") else "their hunt"
			else: what="the child born to %s's house" % who
			var offer2:=_surplus(civ_id,[],20.0)
			if offer2.is_empty(): return {}
			var amt2:=Hall._nice(minf(clampf(pop*0.1,5.0,40.0),float(offer2.stock)*0.25))
			s.ask="er:bless:%d" % floori(day/365.0)
			req={"what":what,"offer_res":String(offer2.res),"offer_amt":amt2}
			s.summary="%s asks the god of your people to bless %s, and has brought %d %s as an offering." % [name,what,roundi(amt2),String(offer2.res)]
		"war_supplies":
			var enemy:=_third_war(civ,String(data.get("enemy","")))
			if enemy.is_empty() or used.has("er:supplies:"+String(enemy.id)): return {}
			var res:="Timber" if Hall.player_stock("Timber")>=Hall.player_stock("Stone") else "Stone"
			var amount2:=Hall._nice(minf(pop*0.2,Hall.player_stock(res)*0.2))
			if amount2<10.0: return {}
			var pay3:=_surplus(civ_id,[res],20.0)
			req={"enemy":String(enemy.id),"enemy_name":String(enemy.name),"res":res,"amount":amount2}
			if not pay3.is_empty(): req.merge({"pay_res":String(pay3.res),"pay_amt":Hall._nice(minf(float(pay3.stock)*0.3,amount2*0.8*float(VALUES.get(res,1.0))/float(VALUES.get(pay3.res,1.0))))})
			s.ask="er:supplies:"+String(enemy.id)
			terms={"resource":res,"amount":amount2}
			var offer_text:=" and offers %d %s for them" % [roundi(float(req.pay_amt)),String(req.pay_res)] if req.has("pay_res") else ""
			s.summary="%s is at war with %s and asks for %d %s for spears and palisades%s." % [name,String(enemy.name),roundi(amount2),res,offer_text]
		"succession_backing":
			if r==null: return {}
			var lineage2:Array=(r.call("character",civ_id) as Dictionary).get("lineage",[])
			if lineage2.is_empty() or day-int((lineage2[0] as Dictionary).get("died",-99999))>540: return {}
			var parent:=String((lineage2[0] as Dictionary).get("name","the old ruler")).get_slice(" ",0)
			s.ask="er:succession:%d" % int((lineage2[0] as Dictionary).get("died",0))
			req={"ruler":who,"parent":parent}
			s.summary="%s has ruled %s only since %s died, and others of the house dispute it. %s asks the god to name %s the rightful ruler." % [who,name,parent,who,who]
		"hostage_exchange":
			if not (String(occasion.get("type",""))=="war_end" or float(relation.get("border_tension",0.0))>=0.5): return {}
			if r!=null and not (r.call("has_bond",civ_id,["hostage"]) as Dictionary).is_empty(): return {}
			s.ask="er:pledges:%d" % floori(day/365.0)
			req={}
			s.summary="%s proposes an exchange of young kin as pledges of peace: one of theirs to live among your people, one of yours among them, for three years." % name
		"sacred_site":
			if r!=null and not (r.call("has_bond",civ_id,["pilgrimage"]) as Dictionary).is_empty(): return {}
			var what2:=_pick(["the graves of its ancestors","a spring its healers hold sacred","a standing stone where its elders are named"],rng)
			var place4:=_pick(PLACES,rng)
			var toll:=_surplus(civ_id,[],20.0)
			s.ask="er:sacred:"+place4
			req={"what":what2,"place":place4}
			if not toll.is_empty(): req.merge({"toll_res":String(toll.res),"toll_amt":Hall._nice(minf(float(toll.stock)*0.15,clampf(pop*0.08,5.0,30.0)))})
			s.summary="%s says %s lies in your %s. It asks leave for its people to visit it each spring." % [name,what2,place4]
	if String(s.get("ask",""))=="": return {}
	# Business born of a famine leaves the same mark in the ledger as a plea
	# for food would (AudienceHall._request_blocked), so a second famine
	# within the year is no likelier to bring an envoy than before.
	if String(occasion.get("type",""))=="their_famine" or situation_type=="food_loan":
		s.ask="request:Food:%s:%d" % [situation_type,int(data.get("episode",floori(day/365.0)))]
	if used.has(String(s.ask)): return {}
	s["req"]=req
	s.summary=_fix(String(s.get("summary","")))
	var out:={"kind":"request","situation":s}
	if not terms.is_empty(): out["terms"]=terms
	return out

# --------------------------------------------------------------------------
# Answers
# --------------------------------------------------------------------------

static func _req(audience:Dictionary)->Dictionary:
	var s:=Hall._situation(audience)
	return s.get("req",{}) if s.get("req") is Dictionary else {}

static func _n(value:Variant)->int:
	return roundi(float(value))

static func options(audience:Dictionary)->Array[Dictionary]:
	var type:=Hall._situation_type(audience)
	var p:=_req(audience)
	var civ_id:=String(audience.get("civ_id",""))
	var name:=String(audience.get("civ_name",Hall._civ_name(civ_id)))
	var o:Array[Dictionary]=[]
	match type:
		"food_loan":
			var amt:=float(p.amount)
			var short:=Hall._short("Food",amt)
			var half:=Hall._nice(amt*0.5)
			o.append(Hall._option("accept","Lend it","Send %d Food now; they owe %d %s within the year." % [_n(amt),_n(p.repay_amt),String(p.repay_res)],"warm",short=="",short))
			o.append(Hall._option("gift","Give it freely","Send %d Food and ask nothing back. They will not forget it." % _n(amt),"warm",short=="",short))
			o.append(Hall._option("partial","Lend half","Send %d Food; they owe half the promised return." % _n(half),"neutral",Hall._short("Food",half)=="",Hall._short("Food",half)))
			o.append(Hall._option("refuse","Refuse","Keep your stores. They are hungry and will remember who would not lend.","hostile"))
		"work_for_food":
			var short0:=Hall._short("Food",float(p.food))
			var half0:=Hall._nice(float(p.food)*0.5)
			o.append(Hall._option("accept","Take their labour","Give %d Food now; %d workers bring in about %d %s over two months." % [_n(p.food),int(p.workers),_n(p.amount),String(p.res)],"warm",short0=="",short0))
			o.append(Hall._option("partial","Take half of them","Give %d Food; half the workers come, for half the %s." % [_n(half0),String(p.res)],"neutral",Hall._short("Food",half0)=="",Hall._short("Food",half0)))
			o.append(Hall._option("gift","Feed them and ask no work","Give %d Food and send the workers home to their own fields." % _n(p.food),"warm",short0=="",short0))
			o.append(Hall._option("refuse","Refuse","No food and no work. They go home hungry.","hostile"))
		"barter":
			var short2:=Hall._short(String(p.give_res),float(p.give_amt))
			o.append(Hall._option("accept","Make the trade","Give %d %s; receive %d %s." % [_n(p.give_amt),String(p.give_res),_n(p.get_amt),String(p.get_res)],"warm",short2=="",short2))
			o.append(Hall._option("bargain","Ask for more","Hold out for about a third more %s. They may agree, or walk away." % String(p.get_res),"neutral",short2=="",short2))
			o.append(Hall._option("refuse","Decline","No trade this time.","hostile"))
		"refuge":
			var n:=int(p.people)
			o.append(Hall._option("accept","Take them in","%d people join your people; more mouths now, more hands later." % n,"warm"))
			o.append(Hall._option("partial","Take the children and their mothers","About %d join you; the rest go home." % maxi(1,n/2),"neutral"))
			o.append(Hall._option("refuse","Turn them away","They go back to %s." % {"hunger":"their hunger","sickness":"the sickness","war":"the war"}.get(String(p.reason),"their troubles"),"hostile"))
		"forage_leave":
			o.append(Hall._option("accept","Grant the leave","Their hunters take about %d Food a month from your %s for half a year." % [_n(p.monthly),String(p.place)],"warm"))
			if p.has("pay_res"): o.append(Hall._option("bargain","Grant it for a price","Ask %d %s now for the leave. They may pay, or go home offended." % [_n(p.pay_amt),String(p.pay_res)],"neutral"))
			o.append(Hall._option("refuse","Keep them out","The %s stays yours alone. The frontier grows a little tenser." % String(p.place),"hostile"))
		"craft_teaching":
			o.append(Hall._option("accept","Teach it for the price","Receive %d %s; a teacher of %s goes to them." % [_n(p.pay_amt),String(p.pay_res),String(p.craft_name)],"warm"))
			o.append(Hall._option("gift","Teach it freely","A teacher goes, and nothing is asked. They will think well of you.","warm"))
			o.append(Hall._option("refuse","Keep the craft","%s stays your people's own." % Hall._cap_first(String(p.craft_name)),"hostile"))
		"healer_plea":
			var short3:=Hall._short("Fiber Plants",float(p.herbs))
			o.append(Hall._option("accept","Send healers and plants","Give %d Fiber Plants and send healers. The healers may bring the sickness home." % _n(p.herbs),"warm",short3=="",short3))
			o.append(Hall._option("partial","Send the plants only","Give %d Fiber Plants; your healers stay home and safe." % _n(p.herbs),"neutral",short3=="",short3))
			o.append(Hall._option("refuse","Close the paths to them","Nothing goes. Your people are safe from it; %s is not." % name,"hostile"))
		"mediation":
			o.append(Hall._option("accept","Judge for %s" % name,"The %s is theirs. %s will resent it." % [String(p.place),String(p.third_name)],"warm"))
			o.append(Hall._option("partial","Divide the ground","Each people keeps the side nearest it. Neither is glad, but the quarrel cools.","neutral"))
			o.append(Hall._option("other","Judge for %s" % String(p.third_name),"The %s goes to %s. The envoy goes home with nothing." % [String(p.place),String(p.third_name)],"hostile"))
			o.append(Hall._option("refuse","Refuse to judge","Let them settle it themselves.","hostile"))
		"marriage_request":
			o.append(Hall._option("accept","Send one of your young people","One of your people marries %s and goes to live with %s. Your peoples become kin." % [String(p.heir),name],"warm"))
			o.append(Hall._option("partial","Bid %s come here" % String(p.heir),"The match is made, but %s comes to live among your people." % String(p.heir),"neutral"))
			o.append(Hall._option("refuse","Refuse the match","No marriage. Their ruler will take it as a slight.","hostile"))
		"border_line":
			var short4:=Hall._short("Timber",float(p.timber))
			o.append(Hall._option("accept","Grant them the %s" % String(p.place),"The frontier calms; you lose the woods there (about %d Timber)." % _n(p.timber),"warm",short4=="",short4))
			o.append(Hall._option("partial","Share it as common ground","Both peoples hunt there; they take about %d Food a month for a year." % _n(p.monthly),"neutral"))
			o.append(Hall._option("refuse","Hold the line","The %s stays yours. The frontier grows tenser." % String(p.place),"hostile"))
		"fugitive_return":
			var short5:=Hall._short("Food",float(p.price))
			o.append(Hall._option("accept","Hand %s over" % String(p.name),"%s goes back to face %s's judgment. Your people will see it." % [String(p.name),name],"neutral"))
			o.append(Hall._option("bargain","Pay a blood-price","Send %d Food instead and keep %s." % [_n(p.price),String(p.name)],"neutral",short5=="",short5))
			o.append(Hall._option("refuse","Shelter %s" % String(p.name),"%s stays. %s will call it harbouring a killer." % [String(p.name),name],"hostile"))
		"blessing_rite":
			o.append(Hall._option("accept","Bless it and take the offering","Receive %d %s; they go home under your blessing." % [_n(p.offer_amt),String(p.offer_res)],"warm"))
			o.append(Hall._option("partial","Bless it and send the offering back","Nothing taken. They will love you the more for it.","warm"))
			o.append(Hall._option("bargain","Ask twice the offering","They may pay it, and fear you more than they love you.","neutral"))
			o.append(Hall._option("refuse","Refuse them","You are not their god. They go home afraid.","hostile"))
		"war_supplies":
			var short6:=Hall._short(String(p.res),float(p.amount))
			var paid:=" and receive %d %s" % [_n(p.pay_amt),String(p.pay_res)] if p.has("pay_res") else ""
			o.append(Hall._option("accept","Send the supplies","Give %d %s%s. %s will count you its enemy." % [_n(p.amount),String(p.res),paid,String(p.enemy_name)],"warm",short6=="",short6))
			if p.has("pay_res"): o.append(Hall._option("gift","Send them freely","Give %d %s and ask nothing. %s will count you its enemy." % [_n(p.amount),String(p.res),String(p.enemy_name)],"warm",short6=="",short6))
			o.append(Hall._option("refuse","Stay out of it","Nothing goes; you keep out of their war.","hostile"))
		"succession_backing":
			o.append(Hall._option("accept","Name %s the rightful ruler" % String(p.ruler),"Your word strengthens their hold; they will owe you for it.","warm"))
			o.append(Hall._option("bargain","Recognise them if the border calms","Ask them to pull their hunters back from your frontier in return.","neutral"))
			o.append(Hall._option("refuse","Withhold your word","Let the house settle it. %s will not forget." % String(p.ruler),"hostile"))
		"hostage_exchange":
			o.append(Hall._option("accept","Exchange pledges","One of theirs lives among your people, one of yours among them, for three years. The frontier calms.","warm"))
			o.append(Hall._option("bargain","Take their pledge, send none","They may accept it as the price of peace, or be insulted.","neutral"))
			o.append(Hall._option("refuse","Decline","No pledges. Things stay as they are.","hostile"))
		"sacred_site":
			o.append(Hall._option("accept","Let them come","Their people may visit the %s each spring." % String(p.place),"warm"))
			if p.has("toll_res"): o.append(Hall._option("bargain","Let them come for a toll","Ask %d %s now. They may pay, or go home bitter." % [_n(p.toll_amt),String(p.toll_res)],"neutral"))
			o.append(Hall._option("refuse","Bar them","The %s is yours. They will not forgive being kept from %s." % [String(p.place),String(p.what).replace("its ","their ")],"hostile"))
	for option in o:
		option["label"]=_fix(String(option.label)); option["sub"]=_fix(String(option.sub))
		# Every answer states what it costs or risks; the card shows this line.
		if bool(option.get("enabled",true)): option["cost"]=("Risk: " if String(option.id)=="bargain" else "Cost: ")+String(option.sub)
	return o

# ---- effects ----

static func _give(civ_id:String,res:String,amount:float)->float:
	var sent:=Hall._debit_player(res,amount)
	if sent>0.0: Hall._credit_civ(civ_id,res,sent)
	return sent

static func _take_from(civ_id:String,res:String,amount:float)->float:
	if Hall.foreign_stock(civ_id,res)<0.0: return 0.0
	var got:=EXCHANGE.take(civ_id,res,amount)
	return EXCHANGE.receive("player",res,got) if got>0.0 else 0.0

static func _civ_field(civ_id:String,key:String,delta:float,lo:float,hi:float)->void:
	var index:=Hall._civ_index(civ_id)
	if index<0: return
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	civ[key]=clampf(float(civ.get(key,0.0))+delta,lo,hi)

static func _between(a:String,b:String,tension:float)->void:
	## The border between two other peoples, both sides.
	for pair in [[a,b],[b,a]]:
		var index:=Hall._civ_index(String(pair[0]))
		if index<0: continue
		var relations:Dictionary=WorldSimulation.world.civilizations[index].get("relations",{})
		if relations.get(String(pair[1])) is Dictionary:
			var rel:Dictionary=relations[String(pair[1])]
			rel["border_tension"]=clampf(float(rel.get("border_tension",0.0))+tension,0.0,1.0)

static func _people(delta:int)->int:
	## Settle or send away real people; bounded to a small share.
	if delta==0: return 0
	var total:=roundi(float(GameState.population_exact))
	var target:=maxi(1,total+delta)
	GameState.ensure_population_total(target)
	return target-total

static func _cohesion(delta:float)->void:
	var m:Dictionary=GameState.simulation_metrics
	m["cohesion"]=clampf(float(m.get("cohesion",0.58))+delta,0.01,0.99)

static func _grudge(civ_id:String,clause:String,weight:float,key:String)->void:
	var r:=_rivals()
	if r!=null: r.call("grudge",civ_id,clause,weight,key)

static func _bond(civ_id:String,kind:String,text:String,until:int,data:Dictionary={})->void:
	var r:=_rivals()
	if r!=null: r.call("bond",civ_id,kind,text,until,data)

static func _bargain_holds(audience:Dictionary)->bool:
	## Whether they take the harder terms: warm, trusting, needy peoples
	## bend; proud and assertive ones walk away.
	var civ_id:=String(audience.civ_id)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var p:=Hall._personality(civ_id)
	var opinion:=float((civ.get("player_relation",{}) as Dictionary).get("opinion",0.0))
	var trust:=float(ForeignDiplomacy.leader(civ_id).get("trust",0.0))
	var chance:=0.45+opinion*0.3+trust*0.15-(float(p.assertiveness)-0.5)*0.5+(0.15 if Hall._hungry(civ) else 0.0)
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:bargain:%s" % [int(GameState.world_seed),String(audience.get("id",""))])
	return rng.randf()<clampf(chance,0.15,0.85)

static func _pledge(civ_id:String,res:String,amount:float,due_in:int,text:String)->void:
	var list:Array=store().pledges
	list.append({"civ":civ_id,"res":res,"amt":Hall._nice(amount),"due":_day()+due_in,"day":_day(),"text":text.substr(0,160),"tries":0})
	while list.size()>PLEDGES_MAX: list.pop_front()
	var r:=_rivals()
	if r!=null: r.call("debt",civ_id,"them",res,amount,due_in,text)

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var type:=Hall._situation_type(audience)
	var p:=_req(audience)
	var civ_id:=String(audience.civ_id)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var name:=String(audience.get("civ_name",Hall._civ_name(civ_id)))
	var who:=_given(civ_id)
	var mood:=Hall._mood_opinion(audience)
	var key:=String(audience.get("id",""))
	var outcome:=""
	var reaction:="neutral"
	var memory:=""
	var p_emp:=float(Hall._personality(civ_id).empathy)
	match "%s:%s" % [type,option_id]:
		"food_loan:accept","food_loan:partial":
			var lend:=float(p.amount)*(1.0 if option_id=="accept" else 0.5)
			var sent:=_give(civ_id,"Food",Hall._nice(lend))
			var back:=Hall._nice(float(p.repay_amt)*sent/maxf(1.0,float(p.amount)))
			if sent>0.0:
				_pledge(civ_id,String(p.repay_res),back,int(p.due_in),"the %d Food you lent us in our hunger" % _n(sent))
				Hall._commitments().note_food_aid(civ_id,sent,_day())
			Hall._shift_relation(civ_id,(0.06 if option_id=="accept" else 0.03)+mood,-0.04)
			Hall._leader_trust(civ_id,0.05)
			reaction="pleased" if option_id=="accept" else "neutral"
			outcome="You lent %d Food to %s. They owe %d %s, due within the year." % [_n(sent),name,_n(back),String(p.repay_res)]
			memory="The ruler lent us %d Food in our hunger; we owe %d %s." % [_n(sent),_n(back),String(p.repay_res)]
		"food_loan:gift":
			var sent2:=_give(civ_id,"Food",float(p.amount))
			if sent2>0.0: Hall._commitments().note_food_aid(civ_id,sent2,_day())
			Hall._shift_relation(civ_id,0.11+mood,-0.06)
			Hall._leader_trust(civ_id,0.09)
			_bond(civ_id,"dependent","the food you gave freely in our hunger",_day()+1095)
			reaction="delighted"
			outcome="You gave %d Food to %s and asked nothing back. %s will count your people as friends in hard times." % [_n(sent2),name,who]
			memory="The ruler gave us %d Food in our hunger and asked nothing back." % _n(sent2)
		"food_loan:refuse":
			var hard:=float(Hall._personality(civ_id).assertiveness)>0.55
			Hall._shift_relation(civ_id,-0.04+mood,0.06 if hard else 0.0)
			Hall._leader_trust(civ_id,-0.04)
			_grudge(civ_id,"how you would not lend us food when we were hungry",0.4,"refused_loan:"+key)
			reaction="offended"
			outcome="You refused to lend %s food.%s" % [name," They are hungry and proud; the border grew tenser." if hard else ""]
			memory="We asked the ruler for a loan of food in our hunger and were refused."
		"work_for_food:accept","work_for_food:partial":
			var share:=1.0 if option_id=="accept" else 0.5
			var fed:=_give(civ_id,"Food",Hall._nice(float(p.food)*share))
			if fed>0.0: Hall._commitments().note_food_aid(civ_id,fed,_day())
			var owed:=Hall._nice(float(p.amount)*share*fed/maxf(1.0,float(p.food)*share))
			var list:Array=store().pledges
			list.append({"civ":civ_id,"res":String(p.res),"amt":owed,"due":_day()+int(p.days),"day":_day(),"text":"the work of %d of our young people in your %s" % [roundi(float(p.workers)*share),String(p.where)],"tries":0,"kind":"labour"})
			while list.size()>PLEDGES_MAX: list.pop_front()
			Hall._shift_relation(civ_id,(0.06 if option_id=="accept" else 0.03)+mood,-0.03)
			Hall._leader_trust(civ_id,0.04)
			reaction="pleased"
			outcome="You gave %d Food to %s. %d of their young people will work your %s for two months, for about %d %s." % [_n(fed),name,roundi(float(p.workers)*share),String(p.where),_n(owed),String(p.res)]
			memory="The ruler fed our families for %d of our young people's work." % roundi(float(p.workers)*share)
		"work_for_food:gift":
			var fed2:=_give(civ_id,"Food",float(p.food))
			if fed2>0.0: Hall._commitments().note_food_aid(civ_id,fed2,_day())
			Hall._shift_relation(civ_id,0.1+mood,-0.05)
			Hall._leader_trust(civ_id,0.08)
			_bond(civ_id,"dependent","the food you gave and would take no work for",_day()+1095)
			reaction="delighted"
			outcome="You gave %d Food to %s and sent their workers home to their own fields." % [_n(fed2),name]
			memory="The ruler fed our families and would take no work for it."
		"work_for_food:refuse":
			Hall._shift_relation(civ_id,-0.03+mood,0.02)
			Hall._leader_trust(civ_id,-0.03)
			reaction="offended"
			outcome="You refused %s's workers. They went home hungry." % name
			memory="The ruler would not trade food for our work."
		"barter:accept","barter:bargain":
			var get_amt:=float(p.get_amt)
			if option_id=="bargain":
				if not _bargain_holds(audience):
					Hall._shift_relation(civ_id,-0.02+mood,0.0)
					Hall._leader_trust(civ_id,-0.02)
					reaction="offended"
					outcome="You held out for more %s. %s's envoy would not pay it and left without a trade." % [String(p.get_res),name]
					memory="The ruler haggled over our trade and we left with nothing."
					ForeignDiplomacy.remember(civ_id,memory)
					return {"outcome":_fix(outcome),"reaction":reaction}
				get_amt=Hall._nice(get_amt*1.33)
			var gave:=_give(civ_id,String(p.give_res),float(p.give_amt))
			var got:=_take_from(civ_id,String(p.get_res),get_amt*gave/maxf(1.0,float(p.give_amt)))
			Hall._shift_relation(civ_id,(0.04 if option_id=="accept" else 0.01)+mood,-0.02)
			Hall._leader_trust(civ_id,0.03 if option_id=="accept" else 0.0)
			reaction="pleased" if option_id=="accept" else "neutral"
			outcome="You traded %d %s to %s for %d %s." % [_n(gave),String(p.give_res),name,_n(got),String(p.get_res)]
			if option_id=="bargain": outcome+=" They paid the higher price, grudgingly."
			if got+0.5<get_amt*gave/maxf(1.0,float(p.give_amt)): outcome+=" Less arrived than was promised."
			memory="We traded %d %s for the ruler's %d %s." % [_n(got),String(p.get_res),_n(gave),String(p.give_res)]
		"barter:refuse":
			Hall._shift_relation(civ_id,-0.01+mood,0.0)
			reaction="neutral"
			outcome="You declined %s's trade. Their envoy took the %s home." % [name,String(p.get_res)]
			memory="The ruler declined our trade."
		"refuge:accept","refuge:partial":
			var n:=int(p.people) if option_id=="accept" else maxi(1,int(p.people)/2)
			var index:=Hall._civ_index(civ_id)
			n=mini(n,maxi(0,roundi(_pop(civ)*0.1)))
			var came:=_people(n)
			if index>=0: _civ_field(civ_id,"population",-float(came),1.0,1e9)
			_cohesion(-0.005*float(came)/maxf(1.0,float(p.people)))
			var took:Dictionary=store().took_in
			took[civ_id]=int(took.get(civ_id,0))+came
			Hall._shift_relation(civ_id,(0.08 if option_id=="accept" else 0.04)+mood,-0.03)
			Hall._leader_trust(civ_id,0.06 if option_id=="accept" else 0.03)
			_bond(civ_id,"dependent","the families you took in",_day()+1095)
			reaction="delighted" if option_id=="accept" else "pleased"
			outcome="%d people of %s settled among your people. There are more mouths to feed this season." % [came,name]
			memory="The ruler took in %d of our people when we could not keep them." % came
		"refuge:refuse":
			Hall._shift_relation(civ_id,-0.03+mood,0.0)
			Hall._leader_trust(civ_id,-0.03)
			reaction="neutral" if p_emp<0.4 else "offended"
			outcome="You turned %s's families away. They went home to %s." % [name,{"hunger":"their hunger","sickness":"the sickness","war":"the war"}.get(String(p.reason),"their troubles")]
			memory="The ruler turned our families away."
		"forage_leave:accept":
			_bond(civ_id,"hunting","their hunters' leave to hunt your %s" % String(p.place),_day()+int(p.months)*30,{"monthly":float(p.monthly),"last":_day()})
			Hall._shift_relation(civ_id,0.05+mood,-0.04)
			Hall._leader_trust(civ_id,0.03)
			reaction="pleased"
			outcome="%s's hunters may hunt your %s for half a year, taking about %d Food a month." % [name,String(p.place),_n(p.monthly)]
			memory="The ruler let our hunters into the %s." % String(p.place)
		"forage_leave:bargain":
			if not _bargain_holds(audience):
				Hall._shift_relation(civ_id,-0.03+mood,0.03)
				reaction="offended"
				outcome="You asked %s to pay for the leave. Their hunters will not pay to hunt, they say, and went home." % name
				memory="The ruler wanted payment before our hunters could hunt."
			else:
				var paid:=_take_from(civ_id,String(p.pay_res),float(p.pay_amt))
				_bond(civ_id,"hunting","their hunters' paid leave to hunt your %s" % String(p.place),_day()+int(p.months)*30,{"monthly":float(p.monthly),"last":_day()})
				Hall._shift_relation(civ_id,0.01+mood,-0.02)
				reaction="neutral"
				outcome="%s paid %d %s for half a year's hunting in your %s." % [name,_n(paid),String(p.pay_res),String(p.place)]
				memory="We paid the ruler %d %s for leave to hunt." % [_n(paid),String(p.pay_res)]
		"forage_leave:refuse":
			Hall._shift_relation(civ_id,-0.02+mood,0.03)
			reaction="offended" if Hall._hungry(civ) else "neutral"
			outcome="You kept %s's hunters out of the %s. The frontier grew a little tenser." % [name,String(p.place)]
			memory="The ruler kept our hunters out of the %s." % String(p.place)
		"craft_teaching:accept","craft_teaching:gift":
			var r:=_rivals()
			if r!=null: r.call("_share_craft",civ_id,String(p.craft),String(p.craft_name))
			if option_id=="accept":
				var paid2:=_take_from(civ_id,String(p.pay_res),float(p.pay_amt))
				Hall._shift_relation(civ_id,0.04+mood,-0.02)
				Hall._leader_trust(civ_id,0.03)
				reaction="pleased"
				outcome="A teacher of %s went to %s. They paid %d %s." % [String(p.craft_name),name,_n(paid2),String(p.pay_res)]
				memory="The ruler sent us a teacher of %s for %d %s." % [String(p.craft_name),_n(paid2),String(p.pay_res)]
			else:
				Hall._shift_relation(civ_id,0.09+mood,-0.03)
				Hall._leader_trust(civ_id,0.07)
				reaction="delighted"
				outcome="A teacher of %s went to %s, and you asked nothing for it." % [String(p.craft_name),name]
				memory="The ruler sent us a teacher of %s and asked nothing." % String(p.craft_name)
			outcome+=" They must still learn it."
		"craft_teaching:refuse":
			Hall._shift_relation(civ_id,-0.02+mood,0.0)
			reaction="neutral"
			outcome="You kept %s to your own people." % String(p.craft_name)
			memory="The ruler kept the secret of %s from us." % String(p.craft_name)
		"healer_plea:accept","healer_plea:partial":
			var herbs:=_give(civ_id,"Fiber Plants",float(p.herbs))
			var healers:=option_id=="accept"
			_civ_field(civ_id,"health",(0.06 if healers else 0.03)*herbs/maxf(1.0,float(p.herbs)),0.05,0.98)
			Hall._shift_relation(civ_id,(0.1 if healers else 0.04)+mood,-0.03)
			Hall._leader_trust(civ_id,0.07 if healers else 0.03)
			reaction="delighted" if healers else "pleased"
			outcome="You sent %d Fiber Plants%s to %s." % [_n(herbs)," and your healers" if healers else "",name]
			memory="The ruler sent us %s in our sickness." % ("healers and plants" if healers else "plants for poultices")
			var r2:=_rivals()
			if healers and bool(p.get("risk",false)) and r2!=null:
				((r2.call("character",civ_id) as Dictionary).get("later",[]) as Array).append({"day":_day()+30,"kind":"sickness","text":"The healers you sent to %s came home coughing, and the sickness came with them." % name})
				outcome+=" Some of the healers look unwell."
		"healer_plea:refuse":
			Hall._shift_relation(civ_id,-0.03+mood,0.0)
			reaction="neutral" if p_emp>0.55 else "offended"
			outcome="You closed the paths to %s. The sickness stays with them." % name
			memory="The ruler shut us out in our sickness."
		"mediation:accept":
			var third:=String(p.third)
			Hall._shift_relation(civ_id,0.08+mood,-0.02)
			Hall._leader_trust(civ_id,0.05)
			_between(civ_id,third,0.05)
			if not ForeignDiplomacy.civilization(third).is_empty(): Hall._shift_relation(third,-0.05,0.03)
			_grudge(third,"how the god judged the %s against us" % String(p.place),0.3,"judged:"+key)
			reaction="delighted"
			outcome="You judged the %s to %s. %s will resent it, and the quarrel is not over." % [String(p.place),name,String(p.third_name)]
			memory="The ruler judged the %s ours." % String(p.place)
		"mediation:partial":
			_between(civ_id,String(p.third),-0.2)
			Hall._shift_relation(civ_id,0.03+mood,0.0)
			if not ForeignDiplomacy.civilization(String(p.third)).is_empty(): Hall._shift_relation(String(p.third),0.03,0.0)
			reaction="pleased"
			outcome="You divided the %s between %s and %s. The quarrel between them has cooled." % [String(p.place),name,String(p.third_name)]
			memory="The ruler divided the %s between us and %s." % [String(p.place),String(p.third_name)]
		"mediation:other":
			_between(civ_id,String(p.third),-0.1)
			Hall._shift_relation(civ_id,-0.06+mood,0.02)
			Hall._leader_trust(civ_id,-0.04)
			_grudge(civ_id,"how the god gave the %s to %s" % [String(p.place),String(p.third_name)],0.3,"judged:"+key)
			if not ForeignDiplomacy.civilization(String(p.third)).is_empty(): Hall._shift_relation(String(p.third),0.06,-0.02)
			reaction="offended"
			outcome="You judged the %s to %s. %s's envoy went home with nothing." % [String(p.place),String(p.third_name),name]
			memory="The ruler gave the %s to %s." % [String(p.place),String(p.third_name)]
		"mediation:refuse":
			Hall._shift_relation(civ_id,-0.01+mood,0.0)
			reaction="neutral"
			outcome="You would not judge between %s and %s." % [name,String(p.third_name)]
			memory="The ruler would not judge our quarrel."
		"marriage_request:accept","marriage_request:partial":
			_people(-1 if option_id=="accept" else 1)
			_bond(civ_id,"inlaw","the marriage of %s into your people" % String(p.heir) if option_id=="partial" else "the marriage of %s to one of your people" % String(p.heir),1<<30,{"heir":String(p.heir)})
			Hall._shift_relation(civ_id,(0.1 if option_id=="accept" else 0.06)+mood,-0.06)
			Hall._leader_trust(civ_id,0.06)
			var enemy:=String(_rivals().call("_enemy",civ_id)) if _rivals()!=null else ""
			if enemy!="":
				Hall._shift_relation(enemy,-0.04,0.03)
				_grudge(enemy,"how you married into %s's house" % name,0.2,"inlaw:"+civ_id)
			reaction="delighted" if option_id=="accept" else "pleased"
			outcome=("One of your young people went to marry %s. Your peoples are kin now." if option_id=="accept" else "%s came to live among your people as a spouse. Your peoples are kin now.") % String(p.heir)
			if enemy!="": outcome+=" %s took note." % Hall._civ_name(enemy)
			memory="Our house and the ruler's people are joined by the marriage of %s." % String(p.heir)
		"marriage_request:refuse":
			Hall._shift_relation(civ_id,-0.04+mood,0.01)
			Hall._leader_trust(civ_id,-0.04)
			_grudge(civ_id,"how you refused a match with our house",0.25,"match:"+key)
			reaction="offended"
			outcome="You refused a match with %s's house." % name
			memory="The ruler refused a match with our house."
		"border_line:accept":
			var lost:=Hall._debit_player("Timber",float(p.timber))
			Hall._shift_relation(civ_id,0.04+mood,-0.2)
			_bond(civ_id,"frontier","the line that leaves the %s to them" % String(p.place),_day()+1825)
			var marshal:=Hall._relevant_official(["Marshal","ChiefScout"])
			if not marshal.is_empty(): GovernmentPeopleSystem.adjust_person_relationship(int(marshal.person_id),0,-0.03,0.01)
			reaction="pleased"
			outcome="The %s is %s's now. The frontier calmed; the woods there (%d Timber) are lost to you." % [String(p.place),name,_n(lost)]
			memory="The ruler gave up the %s to us." % String(p.place)
		"border_line:partial":
			_bond(civ_id,"hunting","common hunting in the %s" % String(p.place),_day()+360,{"monthly":float(p.monthly),"last":_day()})
			Hall._shift_relation(civ_id,0.02+mood,-0.1)
			reaction="neutral"
			outcome="The %s is common ground now. The frontier cooled; their hunters take about %d Food a month there for a year." % [String(p.place),_n(p.monthly)]
			memory="The ruler made the %s common ground." % String(p.place)
		"border_line:refuse":
			Hall._shift_relation(civ_id,-0.03+mood,0.05)
			var marshal2:=Hall._relevant_official(["Marshal","ChiefScout"])
			if not marshal2.is_empty(): GovernmentPeopleSystem.adjust_person_relationship(int(marshal2.person_id),0,0.02,0.0)
			reaction="offended"
			outcome="You held the line at the %s. The frontier with %s grew tenser." % [String(p.place),name]
			memory="The ruler would not give up the %s." % String(p.place)
		"fugitive_return:accept":
			_people(-1)
			_cohesion(-0.01)
			Hall._shift_relation(civ_id,0.06+mood,-0.05)
			Hall._leader_trust(civ_id,0.04)
			reaction="pleased"
			outcome="%s was handed to %s's envoy and taken home to answer for it. Your people watched in silence." % [String(p.name),name]
			memory="The ruler gave %s back to us to face judgment." % String(p.name)
		"fugitive_return:bargain":
			var price:=_give(civ_id,"Food",float(p.price))
			Hall._shift_relation(civ_id,0.02+mood,-0.03)
			reaction="neutral"
			outcome="You paid %s %d Food as a blood-price. %s stays among your people." % [name,_n(price),String(p.name)]
			memory="The ruler paid a blood-price of %d Food and kept %s." % [_n(price),String(p.name)]
		"fugitive_return:refuse":
			Hall._shift_relation(civ_id,-0.05+mood,0.05)
			_grudge(civ_id,"how you sheltered %s from our judgment" % String(p.name),0.35,"fugitive:"+key)
			reaction="furious" if float(Hall._personality(civ_id).assertiveness)>0.6 else "offended"
			outcome="You sheltered %s. %s calls it harbouring a killer; the frontier grew tenser." % [String(p.name),name]
			memory="The ruler sheltered %s from our judgment." % String(p.name)
		"blessing_rite:accept","blessing_rite:bargain":
			var ask:=float(p.offer_amt)
			if option_id=="bargain":
				if not _bargain_holds(audience):
					DIVINE.add_civ_dread(civ_id,0.05)
					Hall._shift_relation(civ_id,-0.03+mood,0.0)
					reaction="offended"
					outcome="You asked %s for twice the offering. They could not give it and went home unblessed and afraid." % name
					memory="The god of that people asked more than we could give."
					ForeignDiplomacy.remember(civ_id,memory)
					return {"outcome":_fix(outcome),"reaction":reaction}
				ask*=2.0
			var got2:=_take_from(civ_id,String(p.offer_res),ask)
			if option_id=="bargain": DIVINE.add_civ_dread(civ_id,0.06)
			Hall._shift_relation(civ_id,(0.06 if option_id=="accept" else 0.02)+mood,-0.02)
			Hall._leader_trust(civ_id,0.05 if option_id=="accept" else 0.01)
			reaction="pleased" if option_id=="accept" else "neutral"
			outcome="You blessed %s and received %d %s as their offering." % [String(p.what),_n(got2),String(p.offer_res)]
			memory="The god of that people blessed %s, and took %d %s." % [String(p.what),_n(got2),String(p.offer_res)]
		"blessing_rite:partial":
			Hall._shift_relation(civ_id,0.1+mood,-0.03)
			Hall._leader_trust(civ_id,0.08)
			reaction="delighted"
			outcome="You blessed %s and sent %s's offering home with them." % [String(p.what),name]
			memory="The god of that people blessed %s and would not take our offering." % String(p.what)
		"blessing_rite:refuse":
			DIVINE.add_civ_dread(civ_id,0.05)
			Hall._shift_relation(civ_id,-0.04+mood,0.0)
			reaction="offended"
			outcome="You refused to bless %s. %s's envoy went home frightened." % [String(p.what),name]
			memory="The god of that people would not bless us."
		"war_supplies:accept","war_supplies:gift":
			var sent3:=_give(civ_id,String(p.res),float(p.amount))
			var got3:=0.0
			if option_id=="accept" and p.has("pay_res"): got3=_take_from(civ_id,String(p.pay_res),float(p.pay_amt)*sent3/maxf(1.0,float(p.amount)))
			var enemy2:=String(p.enemy)
			if not ForeignDiplomacy.civilization(enemy2).is_empty(): Hall._shift_relation(enemy2,-0.08,0.06)
			_grudge(enemy2,"how you armed %s against us" % name,0.35,"armed:"+civ_id)
			Hall._shift_relation(civ_id,(0.06 if option_id=="accept" else 0.12)+mood,-0.03)
			Hall._leader_trust(civ_id,0.05 if option_id=="accept" else 0.08)
			reaction="pleased" if option_id=="accept" else "delighted"
			outcome="You sent %d %s to %s for its war with %s%s. %s counts you its enemy now." % [_n(sent3),String(p.res),name,String(p.enemy_name),(", and received %d %s" % [_n(got3),String(p.pay_res)]) if got3>0.0 else "",String(p.enemy_name)]
			memory="The ruler sent us %d %s for our war with %s." % [_n(sent3),String(p.res),String(p.enemy_name)]
		"war_supplies:refuse":
			Hall._shift_relation(civ_id,-0.02+mood,0.0)
			reaction="neutral"
			outcome="You kept out of %s's war with %s." % [name,String(p.enemy_name)]
			memory="The ruler kept out of our war with %s." % String(p.enemy_name)
		"succession_backing:accept":
			Hall._shift_relation(civ_id,0.06+mood,-0.02)
			Hall._leader_trust(civ_id,0.12)
			_bond(civ_id,"recognised","your word that %s rules by right" % String(p.ruler),_day()+1825)
			reaction="delighted"
			outcome="You named %s the rightful ruler of %s. Their hold is firmer, and they owe you for it." % [String(p.ruler),name]
			memory="The god of that people named %s our rightful ruler." % String(p.ruler)
		"succession_backing:bargain":
			if _bargain_holds(audience):
				Hall._shift_relation(civ_id,0.02+mood,-0.12)
				Hall._leader_trust(civ_id,0.05)
				reaction="neutral"
				outcome="%s agreed to pull its hunters back from your frontier, and you named %s rightful ruler. The border calmed." % [name,String(p.ruler)]
				memory="The ruler named %s rightful ruler, for a quieter border." % String(p.ruler)
			else:
				Hall._shift_relation(civ_id,-0.03+mood,0.02)
				Hall._leader_trust(civ_id,-0.06)
				reaction="offended"
				outcome="%s would not buy your word with its frontier. The envoy left without it." % String(p.ruler)
				memory="The ruler tried to sell us their word on our succession."
		"succession_backing:refuse":
			Hall._shift_relation(civ_id,-0.04+mood,0.0)
			Hall._leader_trust(civ_id,-0.1)
			_grudge(civ_id,"how you would not name %s our ruler" % String(p.ruler),0.3,"succession:"+key)
			reaction="offended"
			outcome="You withheld your word from %s. %s will not forget it." % [String(p.ruler),String(p.ruler)]
			memory="The ruler withheld their word on our succession."
		"hostage_exchange:accept":
			Hall._shift_relation(civ_id,0.05+mood,-0.15)
			_bond(civ_id,"hostage","the young kin exchanged as pledges of peace",_day()+1095)
			reaction="pleased"
			outcome="Young kin were exchanged with %s as pledges of peace, for three years. The frontier calmed." % name
			memory="We exchanged young kin with the ruler's people as pledges of peace."
		"hostage_exchange:bargain":
			if _bargain_holds(audience):
				_people(1)
				Hall._shift_relation(civ_id,-0.03+mood,-0.08)
				Hall._leader_trust(civ_id,-0.05)
				_bond(civ_id,"hostage","their young kin held among your people as a pledge",_day()+1095)
				reaction="neutral"
				outcome="%s sent one of its young kin to live among your people as a pledge, and got none in return. The frontier calmed a little." % name
				memory="We gave the ruler a pledge of our young kin and got none back."
			else:
				Hall._shift_relation(civ_id,-0.05+mood,0.04)
				reaction="offended"
				outcome="%s would not give a pledge without one in return. The envoy left insulted." % name
				memory="The ruler wanted our young kin as pledges and would give none."
		"hostage_exchange:refuse":
			Hall._shift_relation(civ_id,-0.02+mood,0.0)
			reaction="neutral"
			outcome="You declined %s's pledges." % name
			memory="The ruler declined pledges of peace."
		"sacred_site:accept":
			_bond(civ_id,"pilgrimage","their leave to visit %s in your %s" % [String(p.what).replace("its ","their "),String(p.place)],_day()+1825)
			Hall._shift_relation(civ_id,0.07+mood,-0.05)
			Hall._leader_trust(civ_id,0.04)
			reaction="delighted"
			outcome="%s's people may visit the %s each spring." % [name,String(p.place)]
			memory="The ruler lets us visit %s in the %s." % [String(p.what).replace("its ","our "),String(p.place)]
		"sacred_site:bargain":
			if _bargain_holds(audience):
				var toll:=_take_from(civ_id,String(p.toll_res),float(p.toll_amt))
				_bond(civ_id,"pilgrimage","their paid leave to visit the %s" % String(p.place),_day()+1825)
				Hall._shift_relation(civ_id,0.02+mood,-0.03)
				reaction="neutral"
				outcome="%s paid %d %s for leave to visit the %s each spring." % [name,_n(toll),String(p.toll_res),String(p.place)]
				memory="We paid the ruler a toll to visit %s." % String(p.what).replace("its ","our ")
			else:
				Hall._shift_relation(civ_id,-0.04+mood,0.02)
				_grudge(civ_id,"how you charged us to visit %s" % String(p.what).replace("its ","our "),0.2,"toll:"+key)
				reaction="offended"
				outcome="%s would not pay to visit %s. The envoy went home bitter." % [name,String(p.what).replace("its ","their ")]
				memory="The ruler wanted payment for our own dead."
		"sacred_site:refuse":
			Hall._shift_relation(civ_id,-0.05+mood,0.03)
			_grudge(civ_id,"how you barred us from %s" % String(p.what).replace("its ","our "),0.3,"sacred:"+key)
			reaction="offended"
			outcome="You barred %s from the %s. They will not forgive it soon." % [name,String(p.place)]
			memory="The ruler barred us from %s." % String(p.what).replace("its ","our ")
		_:
			return {"error":"That answer is not open to you here."}
	if memory!="": ForeignDiplomacy.remember(civ_id,memory)
	return {"outcome":_fix(outcome),"reaction":reaction}

# --------------------------------------------------------------------------
# Offline words: concrete, from the request itself
# --------------------------------------------------------------------------

static func open_lines(audience:Dictionary)->Array:
	## Opening lines for the envoy, filled from the facts; the voice uses the
	## first one not yet said (and one the AI wrote first, when it did).
	var type:=Hall._situation_type(audience)
	if not TYPES.has(type): return []
	var s:=Hall._situation(audience)
	var p:=_req(audience)
	var civ_id:=String(audience.get("civ_id",""))
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var who:=_given(civ_id)
	var out:Array=[]
	var ai:Dictionary=s.get("ai",{}) if s.get("ai") is Dictionary else {}
	if String(ai.get("opening",""))!="": out.append(String(ai.opening))
	match type:
		"food_loan":
			out.append_array(["%s asks to borrow %d Food, not to be given it. You'll have %d %s back within the year." % [who,_n(p.amount),_n(p.repay_amt),String(p.repay_res)],
				"Our stores last about %d more days. Lend us %d Food and %s will pay it back in %s." % [_n(civ.get("food_days",0)),_n(p.amount),who,String(p.repay_res)]])
		"work_for_food":
			out.append_array(["We have more hands than food. %d of our young people will work your %s until the next moon but one, for %d Food now." % [int(p.workers),String(p.where),_n(p.food)],
				"%s asks no gift. Feed our families and our young people will bring you about %d %s." % [who,_n(p.amount),String(p.res)]])
		"barter":
			out.append_array(["We have %s to spare and not enough %s. %d of ours for %d of yours." % [String(p.get_res),String(p.give_res),_n(p.get_amt),_n(p.give_amt)],
				"%s sent me to trade: %d %s for %d %s, carried to your door." % [who,_n(p.get_amt),String(p.get_res),_n(p.give_amt),String(p.give_res)]])
		"refuge":
			out.append_array(["There are %d of our people waiting at your border, most of them families. %s asks you to let them stay." % [int(p.people),who],
				"%s cannot keep them all. %d of our people would live under your hand, if you'll have them." % [who,int(p.people)]])
		"forage_leave":
			out.append_array(["Our hunters have emptied our own country. %s asks leave to hunt your %s until the autumn." % [who,String(p.place)],
				"Let our hunters into the %s for half a year. They'd take about %d Food a month, no more." % [String(p.place),_n(p.monthly)]])
		"craft_teaching":
			out.append_array(["We have seen what your people do with %s. %s would pay %d %s for someone to teach it." % [String(p.craft_name),who,_n(p.pay_amt),String(p.pay_res)],
				"Send us one person who knows %s, and %d %s is yours." % [String(p.craft_name),_n(p.pay_amt),String(p.pay_res)]])
		"healer_plea":
			out.append_array(["The sickness has reached the children now. %s asks for your healers and %d Fiber Plants." % [who,_n(p.herbs)],
				"Our own healers are sick. Send us yours, and plants for poultices, before it takes the whole camp."])
		"mediation":
			out.append_array(["%s and our people both hunt the %s, and blood has been spilled over it. %s will take your judgment as final." % [String(p.third_name),String(p.place),who],
				"Judge between us and %s over the %s. %s trusts no one else to do it." % [String(p.third_name),String(p.place),who]])
		"marriage_request":
			out.append_array(["%s's %s %s is of age, and %s wants the match to be with your people." % [who,"daughter" if bool(p.woman) else "son",String(p.heir),who],
				"%s would join our house to yours through %s. Name one of your young people." % [who,String(p.heir)]])
		"border_line":
			out.append_array(["Our hunters and yours keep meeting in the %s. %s wants the line fixed there, with that ground on our side." % [String(p.place),who],
				"Settle the %s now and there is no more trouble on that border. %s asks for it." % [String(p.place),who]])
		"fugitive_return":
			out.append_array(["%s is living among your people. %s fled us after %s, and %s wants %s back." % [String(p.name),"She" if bool(p.woman) else "He",String(p.why),who,"her" if bool(p.woman) else "him"],
				"Hand over %s. %s answers to our people for %s, not to yours." % [String(p.name),"She" if bool(p.woman) else "He",String(p.why)]])
		"blessing_rite":
			out.append_array(["%s asks you to bless %s. We have brought %d %s to lay before you." % [who,String(p.what),_n(p.offer_amt),String(p.offer_res)],
				"Our people say you are a god. %s asks your blessing on %s." % [who,String(p.what)]])
		"war_supplies":
			out.append_array(["%s is fighting %s and running short. %s asks for %d %s for spears and palisades." % [Hall._civ_name(civ_id),String(p.enemy_name),who,_n(p.amount),String(p.res)],
				"We need %d %s before %s comes again. %s will pay what we can." % [_n(p.amount),String(p.res),String(p.enemy_name),who]])
		"succession_backing":
			out.append_array(["Since %s died, some of the house say %s has no right to rule. A word from you would end it." % [String(p.parent),String(p.ruler)],
				"%s asks you to say plainly that %s rules %s by right." % [String(p.ruler),String(p.ruler),Hall._civ_name(civ_id)]])
		"hostage_exchange":
			out.append_array(["%s offers one of the young of the house to live among you, and asks one of yours in return. Three years, and no more raids." % who,
				"Pledges both ways, for three years. It keeps both our peoples honest."])
		"sacred_site":
			out.append_array(["%s lies in your %s. %s asks that our people may go there each spring." % [Hall._cap_first(String(p.what).replace("its ","our ")),String(p.place),who],
				"Our people have gone to the %s since before your people came. %s asks leave to keep going." % [String(p.place),who]])
	return out.map(func(line:Variant)->String:return _fix(String(line)))

# --------------------------------------------------------------------------
# Daily: loans fall due
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if day%TICK!=0 or WorldSimulation.actor_id!="player": return
	var list:Array=store().pledges
	for pledge in list.duplicate():
		if not pledge is Dictionary or int(pledge.due)>day: continue
		var civ_id:=String(pledge.civ)
		var civ:=ForeignDiplomacy.civilization(civ_id)
		if civ.is_empty() or not bool(civ.get("alive",true)):
			list.erase(pledge); continue
		if _at_war(civ):
			pledge["due"]=day+90; continue
		if String(pledge.get("kind",""))=="labour":
			# Their workers' own gathering, not their stores.
			list.erase(pledge)
			var brought:=EXCHANGE.receive("player",String(pledge.res),float(pledge.amt))
			Hall._shift_relation(civ_id,0.02,0.0)
			_record("%s Workers Go Home" % _fix(String(civ.get("name",civ_id))+"'s").substr(0,50),"The workers from %s finished %s and went home. They brought in %d %s." % [String(civ.get("name",civ_id)),_narrate(String(pledge.text)),roundi(brought),String(pledge.res)],civ_id)
			continue
		var res:=String(pledge.res)
		var owed:=float(pledge.amt)
		var name:=String(civ.get("name",civ_id))
		var have:=Hall.foreign_stock(civ_id,res)
		if have<0.0:
			# No ledger to draw on: the debt stays a memory, not goods.
			list.erase(pledge); continue
		if have>=owed*0.5:
			var paid:=_take_from(civ_id,res,minf(owed,have*0.6))
			if paid+0.5>=owed:
				list.erase(pledge)
				_settle_debt(civ_id)
				Hall._shift_relation(civ_id,0.02,0.0)
				_record("%s Repays Its Debt" % name.substr(0,40),"Traders from %s brought %d %s: %s, repaid in full." % [name,roundi(paid),res,_narrate(String(pledge.text))],civ_id)
				ForeignDiplomacy.remember(civ_id,"We repaid the ruler %d %s, as we promised." % [roundi(paid),res])
			else:
				pledge["amt"]=Hall._nice(owed-paid)
				pledge["due"]=day+120
				_record("Part of a Debt From %s" % name.substr(0,40),"Traders from %s brought %d %s of what they owe; %d more is promised." % [name,roundi(paid),res,roundi(float(pledge.amt))],civ_id)
			continue
		pledge["tries"]=int(pledge.get("tries",0))+1
		if int(pledge.tries)>=2:
			list.erase(pledge)
			Hall._leader_trust(civ_id,-0.04)
			_record("%s Cannot Pay" % name.substr(0,40),"%s has not repaid %s, and says it cannot. The debt stands in memory, if not in the stores." % [name,_narrate(String(pledge.text))],civ_id)
			ForeignDiplomacy.remember(civ_id,"We could not repay what the ruler lent us. We are ashamed of it.")
		else:
			pledge["due"]=day+180
			_record("%s Asks for Time" % name.substr(0,40),"Word from %s: they cannot yet repay %s, and ask until the autumn." % [name,_narrate(String(pledge.text))],civ_id)

static var _poss_re:RegEx
static func _fix(text:String)->String:
	if _poss_re==null:
		_poss_re=RegEx.new(); _poss_re.compile("(\\w)s's\\b")
	return _poss_re.sub(text,"$1s'",true)

static func _narrate(text:String)->String:
	var r:=_rivals()
	return String(r.call("narrate",text)) if r!=null else text

static func _settle_debt(civ_id:String)->void:
	var r:=_rivals()
	if r==null: return
	var d:Dictionary=r.call("open_debt",civ_id,"them")
	if not d.is_empty(): d["settled"]=true

static func _record(title:String,text:String,civ_id:String)->void:
	var chronicle:=load(CHRONICLE_PATH) as GDScript
	if chronicle!=null: chronicle.call("record",{"title":title,"text":text,"tier":"notice","kind":"contact","key":"er:%s:%s:%d" % [civ_id,title.substr(0,20),_day()]})

static func pledges()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for p in store().pledges:
		if p is Dictionary: out.append((p as Dictionary).duplicate())
	return out
