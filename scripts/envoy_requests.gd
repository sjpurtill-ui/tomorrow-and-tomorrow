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
## Every answer is remembered by the people it was given to (answers), and
## the next envoy they send says concretely how the god answered last time
## (an audience "recall", voiced first), unless their ruler already raises an
## older grudge, debt or bond.
##
## Typed answers (online): typed_choice() reads the god's own words ("lend
## them half and ask for flint back") onto the same bounded answers, with a
## share and a repayment in another good as the only adjustments; the live
## model (envoy_request_ai.gd) reads what this cannot, validated the same way.
##
## State: AudienceHall.state().envoy_requests = {recent:[{d,c,t}], pledges:[...], took_in:{civ:n},
##   answers:{civ:[{a,d,t,o,x,told}]}}.
## Static helpers; the hall loads this lazily.

const Hall:=preload("res://scripts/audience_hall.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const SOCIETY:=preload("res://scripts/society_exchange.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const CV:=preload("res://scripts/character_voice.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const CHRONICLE_PATH:="res://scripts/chronicle.gd"
## A beaten people's business (town back, captives, pleas, vows).
const Aftermath:=preload("res://scripts/envoy_aftermath.gd")

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
	"captive_scouts":{"headline":"comes about scouts held captive","family":"captives"},
	"rite_keeper":{"headline":"asks for a keeper of your rites","family":"divine"},
	"boundary_cairn":{"headline":"asks to raise a cairn on the border","family":"land"},
	"joint_hunt":{"headline":"asks your hunters to join a great drive","family":"hunt"},
	"safe_passage":{"headline":"asks safe passage for its carriers","family":"trade"},
}
## Families of the hall's own situations, for the variety rule.
const HALL_FAMILY:={"aid_request":"food","gift_goods":"gift","gratitude_gift":"gift","dread_tribute":"gift","artifact_gift":"gift",
	"tribute_demand":"demand","emboldened_demand":"demand","test_of_resolve":"demand","redress_demand":"demand","debt_call":"demand",
	"trade_offer":"trade","artifact_purchase":"trade","research_sale":"knowledge","license_offer":"knowledge","scholar_offer":"knowledge",
	"news_report":"news","rumor_share":"news","intelligence_share":"news","accord_offer":"pact","protection_pact":"pact","league_invitation":"pact",
	"nonaggression_offer":"peace","peace_feeler":"peace","war_support":"war","artifact_return":"judgment","recruitment_protest":"judgment"}

## Which requests each occasion may also bring (their own candidates decide
## whether the state truly backs them).
## Round two (fun): the calmer business was starved because famine occasions
## filled the hall; it now also rides on tension, peace, kin calls and the
## return of a people the god helped, and hunger-backed pleas weigh less
## when the occasion is not itself a famine.
const EXTRA_MIX:={
	"their_famine":{"food_loan":1.0,"work_for_food":0.8,"barter":0.7,"refuge":0.6,"forage_leave":0.6,"healer_plea":0.4,"joint_hunt":0.6},
	"ambient":{"work_for_food":0.2,"barter":0.5,"craft_teaching":0.8,"healer_plea":0.8,"mediation":0.8,"marriage_request":0.6,"border_line":0.5,"fugitive_return":0.35,
		"blessing_rite":0.6,"war_supplies":0.7,"succession_backing":1.2,"sacred_site":0.5,"refuge":0.3,"forage_leave":0.25,
		"captive_scouts":1.2,"rite_keeper":0.6,"boundary_cairn":0.5,"joint_hunt":0.6,"safe_passage":0.6},
	"lean_season":{"food_loan":0.2,"work_for_food":0.4,"barter":0.3,"forage_leave":0.3,"joint_hunt":0.7,"healer_plea":0.5,"craft_teaching":0.6,"mediation":0.6,"marriage_request":0.4,
		"sacred_site":0.4,"blessing_rite":0.4,"rite_keeper":0.4,"boundary_cairn":0.4,"safe_passage":0.5,"captive_scouts":1.0,"succession_backing":1.0,"war_supplies":0.5,"border_line":0.4,"fugitive_return":0.3},
	"first_contact":{"barter":0.4,"sacred_site":0.5,"craft_teaching":0.4,"blessing_rite":0.3,"captive_scouts":1.0,"safe_passage":0.3},
	"relation_warm":{"marriage_request":0.8,"craft_teaching":0.6,"blessing_rite":0.6,"barter":0.4,"sacred_site":0.5,"succession_backing":0.6,
		"rite_keeper":0.7,"joint_hunt":0.6,"safe_passage":0.5,"boundary_cairn":0.4},
	"relation_cool":{"border_line":0.9,"fugitive_return":0.5,"sacred_site":0.3,"captive_scouts":0.8,"mediation":0.4},
	"tension_rise":{"border_line":1.2,"hostage_exchange":0.6,"fugitive_return":0.4,"captive_scouts":0.8,"boundary_cairn":0.5,"sacred_site":0.3,"marriage_request":0.4},
	"war_end":{"hostage_exchange":1.0,"refuge":0.5,"border_line":0.5,"captive_scouts":1.2,"boundary_cairn":0.6,"marriage_request":0.6},
	"grudge":{"succession_backing":0.8},
	"third_war":{"war_supplies":1.0,"refuge":0.5,"mediation":0.3},
	"kin_call":{"war_supplies":0.9},
}
## A people the god helped comes back grateful: sometimes with thanks, and
## sometimes with the warmer business that gratitude opens.
const SEQUEL_WARM:={"marriage_request":0.5,"craft_teaching":0.4,"blessing_rite":0.4,"rite_keeper":0.5,"joint_hunt":0.4,"sacred_site":0.3,"succession_backing":0.5,"safe_passage":0.3}

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
	if not d.get("answers",{}) is Dictionary or (d.get("answers",{}) as Dictionary).size()>ANSWER_CIVS_MAX: return false
	for list in (d.get("answers",{}) as Dictionary).values():
		if not list is Array or (list as Array).size()>ANSWERS_PER_CIV: return false
		for entry in list:
			if not entry is Dictionary or not Hall._num(entry.get("d")) or not entry.get("t","") is String or not entry.get("x",{}) is Dictionary or JSON.stringify(entry).length()>1200: return false
	return true

static func handles(situation_type:String)->bool:
	return TYPES.has(situation_type) or Aftermath.handles(situation_type)

static func is_help(situation_type:String)->bool:
	return bool((TYPES.get(situation_type,{}) as Dictionary).get("help",false))

static func family(situation_type:String)->String:
	if TYPES.has(situation_type): return String(TYPES[situation_type].family)
	if Aftermath.handles(situation_type): return Aftermath.family(situation_type)
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
	if enabled: attach_followup(audience)

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

static func extra_mix(occasion_type:String,occasion:Dictionary={})->Dictionary:
	if not enabled: return {}
	var mix:Dictionary=(EXTRA_MIX.get(occasion_type,{}) as Dictionary).duplicate()
	var odata:Dictionary=occasion.get("data",{}) if occasion.get("data") is Dictionary else {}
	if bool(odata.get("heir",false)):
		# A new ruler's first envoy: recognition is the business of the day.
		mix["succession_backing"]=3.0
	if occasion_type=="sequel":
		var data:Dictionary=occasion.get("data",{}) if occasion.get("data") is Dictionary else {}
		var previous:Dictionary=data.get("previous",{}) if data.get("previous") is Dictionary else {}
		var situation:=String(previous.get("situation",""))
		var option:=String(previous.get("option",""))
		if (situation=="aid_request" and option in ["grant","grant_half"]) or brings_sequel(situation,option) or (TYPES.has(situation) and option in ["accept","gift","partial"]):
			mix=SEQUEL_WARM.duplicate()
	return mix

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
		"rite_keeper": return maxf(0.1,0.5+maxf(0.0,opinion)*0.8+float(p.openness)*0.5)
		"boundary_cairn": return 0.5+float(p.discipline)*0.7+float(p.empathy)*0.2
		"joint_hunt": return 0.5+float(p.risk_tolerance)*0.5+maxf(0.0,opinion)*0.6
		"safe_passage": return 0.4+float(p.openness)*0.6+(0.5 if String(civ.get("strategy",""))=="commerce" else 0.0)
		"captive_scouts": return 1.0+float(p.discipline)*0.4
	return 1.0

# --------------------------------------------------------------------------
# Candidates: what the state truly backs
# --------------------------------------------------------------------------

static func _civ_ok(civ:Dictionary)->bool:
	return not civ.is_empty() and bool(civ.get("alive",true))

static func _at_war(civ:Dictionary)->bool:
	## At war with us, or in a hot feud (war_loop.gd): no loans repaid, no
	## carriers crossing, no business while their raiders are out.
	if bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)): return true
	var id:=String(civ.get("id",""))
	return id!="" and bool((load("res://scripts/war_loop.gd") as GDScript).call("hot",id))

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

static func _captives(civ_id:String)->Dictionary:
	## Scouts each side holds of the other, from the real capture records.
	var out:={"ours":0,"ours_day":0,"theirs":0,"theirs_day":0}
	var ours:Variant=CivilizationSystem.captured_player_scouts.get(civ_id)
	if ours is Dictionary: out.ours=maxi(0,int((ours as Dictionary).get("count",0))); out.ours_day=int((ours as Dictionary).get("captured_day",0))
	var theirs:Variant=CivilizationSystem.captured_foreign_scouts.get(civ_id)
	if theirs is Dictionary: out.theirs=maxi(0,int((theirs as Dictionary).get("count",0))); out.theirs_day=int((theirs as Dictionary).get("captured_day",0))
	return out

static func _ago(days:int)->String:
	if days<45: return "this month"
	if days<200: return "this season"
	if days<500: return "last year"
	return "%s winters ago" % ["two","three","four","five","six","seven"][clampi(roundi(days/365.0)-2,0,5)] if days<2400 else "many winters ago"

static func _carriers(civ_id:String)->String:
	return "traders" if CV.era_tier(CV.era_tags(civ_id))>=1 else "carriers"

static func _destination(civ:Dictionary)->Dictionary:
	## Another living people this one deals with in peace, beyond your country.
	var best:={}
	var best_t:=2.0
	var relations:Dictionary=civ.get("relations",{}) if civ.get("relations") is Dictionary else {}
	for other in relations:
		var id:=String(other)
		if id in ["player",String(civ.get("id",""))] or not relations[other] is Dictionary: continue
		var rel:Dictionary=relations[other]
		var index:=Hall._civ_index(id)
		if index<0 or not bool(WorldSimulation.world.civilizations[index].get("alive",true)) or bool(rel.get("at_war",false)): continue
		var t:=float(rel.get("border_tension",0.0))
		if t<0.5 and t<best_t: best_t=t; best={"id":id,"name":Hall._civ_name(id)}
	return best

static func candidate(situation_type:String,civ_id:String,occasion:Dictionary,rng:RandomNumberGenerator,used:Dictionary,day:int)->Dictionary:
	if Aftermath.handles(situation_type): return Aftermath.candidate(situation_type,civ_id,occasion,rng,used,day)
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
		"captive_scouts":
			var held:=_captives(civ_id)
			if int(held.ours)>0:
				var n:=int(held.ours)
				var price:=Hall._nice(clampf(float(n)*12.0,10.0,maxf(10.0,Hall.player_stock("Food")*0.15)))
				s.ask="er:captives:ours:%d" % int(held.ours_day)
				s.headline="holds some of your scouts"
				req={"side":"ours","count":n,"price":price}
				s.summary="%s's people caught %d of your scouts in their country %s. %s will send them home for %d Food, or for your word that no more will come." % [name,n,_ago(day-int(held.ours_day)),who,roundi(price)]
			elif int(held.theirs)>0:
				var m:=int(held.theirs)
				s.ask="er:captives:theirs:%d" % int(held.theirs_day)
				s.headline="asks for its captured scouts back"
				req={"side":"theirs","count":m}
				var ransom:=_surplus(civ_id,[],20.0)
				if not ransom.is_empty(): req.merge({"pay_res":String(ransom.res),"pay_amt":Hall._nice(minf(float(ransom.stock)*0.25,clampf(float(m)*10.0,8.0,60.0)))})
				s.summary="Your people have held %d of %s's scouts since they were caught in your country %s. %s asks for them back." % [m,name,_ago(day-int(held.theirs_day)),who]
		"rite_keeper":
			var regard2:=DIVINE.foreign_regard(civ_id)
			if regard2.is_empty() or not (float(regard2.love)>=0.62 or float(regard2.dread)>=0.5): return {}
			if r!=null and not (r.call("has_bond",civ_id,["rites"]) as Dictionary).is_empty(): return {}
			var fear:=float(regard2.dread)>=0.5 and float(regard2.love)<0.62
			var keep:=_surplus(civ_id,[],20.0)
			s.ask="er:rites:%d" % floori(day/1095.0)
			req={"fear":fear}
			if not keep.is_empty(): req.merge({"gift_res":String(keep.res),"gift_amt":Hall._nice(minf(float(keep.stock)*0.15,clampf(pop*0.06,5.0,25.0)))})
			if fear: s.summary="%s fears your god and does not know what angers it. %s asks for one of your people who keeps your rites to live among them and teach them what is owed." % [name,who]
			else: s.summary="%s wants to honour your god as your own people do. %s asks for one of your people who keeps your rites to live among them and teach them." % [name,who]
		"boundary_cairn":
			if r!=null and not (r.call("has_bond",civ_id,["cairn"]) as Dictionary).is_empty(): return {}
			var tension2:=float(relation.get("border_tension",0.0))
			var earlier:Dictionary=r.call("has_bond",civ_id,["frontier","hostage","hunting"]) if r!=null else {}
			if tension2>0.75 or (earlier.is_empty() and not (tension2>=0.25 and tension2<=0.6 and opinion>=-0.05)): return {}
			var place5:=""
			for place_name in PLACES:
				if String(earlier.get("text","")).contains(String(place_name)): place5=String(place_name)
			if place5=="": place5=_pick(PLACES,rng)
			var stone:=Hall._nice(clampf(player_pop*0.06,5.0,30.0))
			s.ask="er:cairn:"+place5
			req={"place":place5,"stone":stone}
			s.summary="%s wants a cairn raised at the %s to mark the line between your peoples, with the elders of both there and each people bringing stones. %s says it would end the quarrels on that border." % [name,place5,who]
		"joint_hunt":
			if opinion<-0.05 or pop<40.0 or player_pop<30.0: return {}
			if r!=null and not (r.call("has_bond",civ_id,["hunt_partner"]) as Dictionary).is_empty(): return {}
			var hunters:=clampi(roundi(player_pop*0.04),3,15)
			var place6:=_pick(PLACES,rng)
			s.ask="er:hunt:%d" % floori(day/365.0)
			req={"hunters":hunters,"meat":Hall._nice(float(hunters)*rng.randf_range(6.0,10.0)),"place":place6,"days":20,"risk":rng.randf()<0.2}
			s.summary="%s's hunters have found a great herd moving through the %s, too many for them to drive alone. %s asks for %d of your hunters to join the drive; the meat would be shared, about %d Food for your people." % [name,place6,who,hunters,roundi(float(req.meat))]
		"safe_passage":
			if r!=null and not (r.call("has_bond",civ_id,["passage"]) as Dictionary).is_empty(): return {}
			if not (float(relation.get("trade",0.0))>0.03 or String(civ.get("strategy",""))=="commerce" or opinion>=0.15): return {}
			var dest:=_destination(civ)
			if dest.is_empty(): return {}
			var toll2:=_surplus(civ_id,[],20.0)
			if toll2.is_empty(): return {}
			var toll_amt:=Hall._nice(minf(float(toll2.stock)*0.08,clampf(pop*0.05,4.0,20.0)))
			if toll_amt<3.0: return {}
			s.ask="er:passage:"+String(dest.id)
			req={"dest":String(dest.id),"dest_name":String(dest.name),"toll_res":String(toll2.res),"toll_amt":toll_amt,"seasons":8,"carriers":_carriers(civ_id)}
			s.summary="%s's %s want to cross your country on the way to %s, a party each season for two years, and would leave %d %s at each crossing." % [name,String(req.carriers),String(dest.name),roundi(toll_amt),String(toll2.res)]
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
	if Aftermath.handles(type): return Aftermath.options(audience)
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
		"captive_scouts":
			var count:=int(p.count)
			if String(p.side)=="ours":
				var short7:=Hall._short("Food",float(p.price))
				o.append(Hall._option("accept","Pay for them","Send %d Food; your %d scouts come home." % [_n(p.price),count],"neutral",short7=="",short7))
				o.append(Hall._option("partial","Give your word","No more scouts go into their country for three years; yours come home.","warm"))
				o.append(Hall._option("refuse","Demand them back","Ask for them freely. They may give them up, or keep them and grow colder.","hostile"))
			else:
				o.append(Hall._option("accept","Send them home","Their %d scouts go home. What they saw goes with them." % count,"warm"))
				if p.has("pay_res"): o.append(Hall._option("bargain","Ask a ransom","Ask %d %s for them. They may pay, or leave them with you and resent it." % [_n(p.pay_amt),String(p.pay_res)],"neutral"))
				o.append(Hall._option("refuse","Keep them","The scouts stay among your people. %s will count it against you." % name,"hostile"))
		"rite_keeper":
			o.append(Hall._option("accept","Send a keeper of your rites","One of your people goes to live among them and teach them your ways.%s" % ((" They bring %d %s for the keeper's upkeep." % [_n(p.gift_amt),String(p.gift_res)]) if p.has("gift_res") else ""),"warm"))
			o.append(Hall._option("partial","Let one of theirs learn here","One of their young people comes to live among yours and learn. Slower, and nobody of yours leaves.","neutral"))
			o.append(Hall._option("bargain","Teach them to fear you","The keeper teaches what angers you before what pleases you. They obey more and love you less.","neutral"))
			o.append(Hall._option("refuse","Refuse them","Your ways stay with your people. They go home unsure of you.","hostile"))
		"boundary_cairn":
			var short8:=Hall._short("Stone",float(p.stone))
			o.append(Hall._option("accept","Raise it together","Send %d Stone and your elders to the %s. The border calms for years." % [_n(p.stone),String(p.place)],"warm",short8=="",short8))
			o.append(Hall._option("partial","Let them raise it","They set the stones where they like. The border calms a little.","neutral"))
			o.append(Hall._option("refuse","No stones on that line","The line stays unmarked. They will read it as a claim.","hostile"))
		"joint_hunt":
			o.append(Hall._option("accept","Send your hunters","%d of your hunters join the drive for about twenty days; about %d Food comes home. A drive can kill a hunter." % [int(p.hunters),_n(p.meat)],"warm"))
			o.append(Hall._option("gift","Send them, and give up your share","Your hunters help and the meat goes to %s. They will remember it." % name,"warm"))
			o.append(Hall._option("refuse","Keep your hunters home","They drive the herd alone and take what they can.","hostile"))
		"safe_passage":
			o.append(Hall._option("accept","Grant passage for the crossing gift","Their %s cross your country each season for two years and leave %d %s each time." % [String(p.carriers),_n(p.toll_amt),String(p.toll_res)],"warm"))
			o.append(Hall._option("gift","Grant it freely","They cross freely. %s will think well of you, and so may %s." % [name,String(p.dest_name)],"warm"))
			o.append(Hall._option("refuse","Close your country to them","They must go the long way round to %s." % String(p.dest_name),"hostile"))
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

static func _pledge(civ_id:String,res:String,amount:float,due_in:int,text:String,audience_key:String="")->void:
	var list:Array=store().pledges
	list.append({"civ":civ_id,"res":res,"amt":Hall._nice(amount),"due":_day()+due_in,"day":_day(),"text":text.substr(0,160),"tries":0,"a":audience_key.substr(0,40)})
	while list.size()>PLEDGES_MAX: list.pop_front()
	var r:=_rivals()
	if r!=null: r.call("debt",civ_id,"them",res,amount,due_in,text)

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var type:=Hall._situation_type(audience)
	if Aftermath.handles(type): return Aftermath.resolve(audience,option_id)
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
	# The god's own words may set a share or ask repayment in another good
	# (typed_choice / the live reading); nothing else about an answer bends.
	var typed:Dictionary=Hall._situation(audience).get("typed",{}) if Hall._situation(audience).get("typed") is Dictionary else {}
	var k:=clampf(float(typed.get("share",1.0)),0.1,1.0)
	var facts:Dictionary=p.duplicate()
	match "%s:%s" % [type,option_id]:
		"food_loan:accept","food_loan:partial":
			var lend:=float(p.amount)*(k if option_id=="accept" else 0.5)
			var repay_res:=String(p.repay_res)
			var repay_full:=float(p.repay_amt)
			var note:=""
			var asked:=String(typed.get("repay_res",""))
			if asked!="" and asked!=repay_res and asked in Hall.RESOURCES:
				var need:=Hall._nice(float(p.amount)*1.3*float(VALUES.Food)/float(VALUES.get(asked,1.0)))
				if Hall.foreign_stock(civ_id,asked)>=need*0.5: repay_res=asked; repay_full=need
				else: note=" They have too little %s to promise it, and will repay in %s." % [asked,repay_res]
			var sent:=_give(civ_id,"Food",Hall._nice(lend))
			var back:=Hall._nice(repay_full*sent/maxf(1.0,float(p.amount)))
			if sent>0.0:
				_pledge(civ_id,repay_res,back,int(p.due_in),"the %d Food you lent us in our hunger" % _n(sent),key)
				Hall._commitments().note_food_aid(civ_id,sent,_day())
			Hall._shift_relation(civ_id,(0.06 if option_id=="accept" else 0.03)+mood,-0.04)
			Hall._leader_trust(civ_id,0.05)
			reaction="pleased" if option_id=="accept" else "neutral"
			outcome="You lent %d Food to %s. They owe %d %s, due within the year.%s" % [_n(sent),name,_n(back),repay_res,note]
			memory="The ruler lent us %d Food in our hunger; we owe %d %s." % [_n(sent),_n(back),repay_res]
			facts.merge({"sent":sent,"back":back,"bres":repay_res},true)
		"food_loan:gift":
			var sent2:=_give(civ_id,"Food",Hall._nice(float(p.amount)*k))
			facts["sent"]=sent2
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
			var share:=k if option_id=="accept" else 0.5
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
			var fed2:=_give(civ_id,"Food",Hall._nice(float(p.food)*k))
			facts["food"]=fed2
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
					facts["failed"]=true
					_note_answer(audience,type,option_id,facts)
					return {"outcome":_fix(outcome),"reaction":reaction}
				get_amt=Hall._nice(get_amt*1.33)
			var gave:=_give(civ_id,String(p.give_res),Hall._nice(float(p.give_amt)*k))
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
			var n:=maxi(1,roundi(float(p.people)*k)) if option_id=="accept" else maxi(1,int(p.people)/2)
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
			var herbs:=_give(civ_id,"Fiber Plants",Hall._nice(float(p.herbs)*k))
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
					facts["failed"]=true
					_note_answer(audience,type,option_id,facts)
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
			var sent3:=_give(civ_id,String(p.res),Hall._nice(float(p.amount)*k))
			facts["amount"]=sent3
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
		"captive_scouts:accept","captive_scouts:partial","captive_scouts:refuse","captive_scouts:bargain":
			var count:=int(p.count)
			var ours:=String(p.side)=="ours"
			if ours and option_id=="accept":
				var paid3:=_give(civ_id,"Food",float(p.price))
				_release_ours(civ_id,count)
				Hall._shift_relation(civ_id,0.03+mood,-0.03)
				reaction="pleased"
				outcome="You sent %d Food to %s, and your %d scouts came home." % [_n(paid3),name,count]
				memory="The ruler paid %d Food for the scouts we caught." % _n(paid3)
				facts["paid"]=paid3
			elif ours and option_id=="partial":
				_release_ours(civ_id,count)
				_bond(civ_id,"no_scouts","your word that no more of your scouts would come into our country",_day()+1095)
				Hall._shift_relation(civ_id,0.04+mood,-0.08)
				Hall._leader_trust(civ_id,0.04)
				reaction="pleased"
				outcome="You gave %s your word: no more scouts in their country for three years. Your %d scouts came home." % [name,count]
				memory="The ruler gave us their word that no more scouts would come, and we sent theirs home."
			elif ours and option_id=="refuse":
				if _bargain_holds(audience):
					_release_ours(civ_id,count)
					DIVINE.add_civ_dread(civ_id,0.03)
					Hall._shift_relation(civ_id,-0.02+mood,0.0)
					reaction="neutral"
					outcome="%s's envoy did not dare keep them. Your %d scouts came home, and %s is the colder for it." % [name,count,name]
					memory="The ruler demanded their scouts back and we gave them up."
					facts["freed"]=true
				else:
					Hall._shift_relation(civ_id,-0.04+mood,0.05)
					_grudge(civ_id,"how you sent your scouts into our country and then made demands",0.25,"scouts:"+key)
					reaction="offended"
					outcome="%s would not give your scouts up for nothing. They stay captive, and the frontier grew tenser." % name
					memory="The ruler demanded back the scouts they sent spying on us. We kept them."
					facts["freed"]=false
			elif not ours and option_id=="accept":
				_release_theirs(civ_id,count)
				Hall._shift_relation(civ_id,0.06+mood,-0.05)
				Hall._leader_trust(civ_id,0.04)
				reaction="pleased"
				outcome="You sent %s's %d scouts home." % [name,count]
				memory="The ruler sent our %d scouts home." % count
			elif not ours and option_id=="bargain":
				if _bargain_holds(audience):
					var got4:=_take_from(civ_id,String(p.pay_res),float(p.pay_amt))
					_release_theirs(civ_id,count)
					Hall._shift_relation(civ_id,-0.01+mood,-0.02)
					reaction="neutral"
					outcome="%s paid %d %s, and its %d scouts went home." % [name,_n(got4),String(p.pay_res),count]
					memory="We paid the ruler %d %s for our scouts." % [_n(got4),String(p.pay_res)]
					facts["paid"]=got4
				else:
					Hall._shift_relation(civ_id,-0.04+mood,0.04)
					_grudge(civ_id,"how you would sell us our own scouts",0.2,"ransom:"+key)
					reaction="offended"
					outcome="%s would not pay a ransom. Its scouts stay with your people, and the envoy left angry." % name
					memory="The ruler wanted a ransom for our scouts. We would not pay it."
					facts["paid"]=0.0
			elif not ours and option_id=="refuse":
				Hall._shift_relation(civ_id,-0.05+mood,0.06)
				_grudge(civ_id,"how you kept our scouts from us",0.35,"kept_scouts:"+key)
				reaction="offended"
				outcome="You kept %s's scouts. %s will count it against you." % [name,who]
				memory="The ruler kept our scouts and would not send them home."
			else:
				return {"error":"That answer is not open to you here."}
		"rite_keeper:accept":
			_people(-1)
			_bond(civ_id,"rites","the keeper of your rites who lives among us",_day()+1825)
			var got5:=_take_from(civ_id,String(p.gift_res),float(p.gift_amt)) if p.has("gift_res") else 0.0
			Hall._shift_relation(civ_id,0.07+mood,-0.03)
			Hall._leader_trust(civ_id,0.05)
			reaction="delighted"
			outcome="One of your people went to live among %s and teach them your ways.%s" % [name,(" They brought %d %s for the keeper's upkeep." % [_n(got5),String(p.gift_res)]) if got5>0.0 else ""]
			memory="The ruler sent one who keeps their rites to live among us and teach us."
		"rite_keeper:partial":
			_people(1)
			_bond(civ_id,"rites","our young one learning your ways among your people",_day()+1825)
			Hall._shift_relation(civ_id,0.04+mood,-0.02)
			reaction="pleased"
			outcome="One of %s's young people came to live among yours and learn your ways." % name
			memory="The ruler let one of our young people learn their ways among them."
		"rite_keeper:bargain":
			_people(-1)
			DIVINE.add_civ_dread(civ_id,0.12)
			_bond(civ_id,"rites","the keeper who taught us what angers you",_day()+1825)
			Hall._shift_relation(civ_id,-0.02+mood,-0.06)
			reaction="neutral"
			outcome="The keeper you sent teaches %s what angers you first. They will obey you more readily, and love you less." % name
			memory="The ruler's keeper taught us what angers their god."
		"rite_keeper:refuse":
			DIVINE.add_civ_dread(civ_id,0.03)
			Hall._shift_relation(civ_id,-0.04+mood,0.0)
			_grudge(civ_id,"how you would not teach us your ways",0.15,"rites:"+key)
			reaction="offended"
			outcome="You refused to teach %s your ways. The envoy went home unsure what you want of them." % name
			memory="The ruler would not teach us their ways."
		"boundary_cairn:accept":
			var laid:=Hall._debit_player("Stone",float(p.stone))
			_bond(civ_id,"cairn","the cairn our peoples raised together at the %s" % String(p.place),_day()+3650)
			Hall._shift_relation(civ_id,0.04+mood,-0.2)
			reaction="delighted"
			outcome="Your elders and theirs raised a cairn at the %s with %d of your Stone. The border with %s is quiet." % [String(p.place),_n(laid),name]
			memory="We raised a cairn with the ruler's people at the %s." % String(p.place)
			facts["laid"]=laid
		"boundary_cairn:partial":
			_bond(civ_id,"cairn","the cairn we raised alone at the %s" % String(p.place),_day()+3650)
			Hall._shift_relation(civ_id,0.01+mood,-0.08)
			reaction="neutral"
			outcome="%s raised its own cairn at the %s, where it chose. The border cooled a little." % [name,String(p.place)]
			memory="We raised a cairn at the %s; the ruler let us place it." % String(p.place)
		"boundary_cairn:refuse":
			Hall._shift_relation(civ_id,-0.02+mood,0.03)
			reaction="offended"
			outcome="You would not mark the line at the %s. %s reads it as a claim." % [String(p.place),name]
			memory="The ruler would not mark the border with us at the %s." % String(p.place)
		"joint_hunt:accept","joint_hunt:gift":
			var share2:=option_id=="accept"
			var list2:Array=store().pledges
			list2.append({"civ":civ_id,"res":"Food","amt":float(p.meat) if share2 else 0.0,"theirs":Hall._nice(float(p.meat)*(0.5 if share2 else 1.5)),"due":_day()+int(p.days),"day":_day(),
				"text":"the drive in the %s" % String(p.place),"tries":0,"kind":"hunt","risk":bool(p.get("risk",false)),"a":key})
			while list2.size()>PLEDGES_MAX: list2.pop_front()
			_bond(civ_id,"hunt_partner","the great drive our hunters made together in the %s" % String(p.place),_day()+730)
			Hall._shift_relation(civ_id,(0.04 if share2 else 0.08)+mood,-0.03)
			Hall._leader_trust(civ_id,0.03 if share2 else 0.06)
			reaction="pleased" if share2 else "delighted"
			outcome=("%d of your hunters went to join %s's drive in the %s. They will be back in about twenty days with your share." if share2 else "%d of your hunters went to join %s's drive in the %s, and the meat is theirs.") % [int(p.hunters),name,String(p.place)]
			memory="The ruler's hunters joined our drive in the %s%s." % [String(p.place),"" if share2 else " and took none of the meat"]
		"joint_hunt:refuse":
			Hall._shift_relation(civ_id,-0.01+mood,0.0)
			reaction="neutral"
			outcome="You kept your hunters home. %s will drive the herd alone." % name
			memory="The ruler would not send hunters for our drive."
		"safe_passage:accept","safe_passage:gift":
			var toll3:=float(p.toll_amt) if option_id=="accept" else 0.0
			_bond(civ_id,"passage","the leave for our %s to cross your country to %s" % [String(p.carriers),String(p.dest_name)],_day()+int(p.seasons)*91,{"res":String(p.toll_res),"amt":toll3,"last":_day(),"crossings":0})
			Hall._shift_relation(civ_id,(0.04 if option_id=="accept" else 0.07)+mood,-0.02)
			Hall._leader_trust(civ_id,0.02 if option_id=="accept" else 0.04)
			if not ForeignDiplomacy.civilization(String(p.dest)).is_empty(): Hall._shift_relation(String(p.dest),0.02,0.0)
			reaction="pleased" if option_id=="accept" else "delighted"
			outcome=("%s's %s may cross your country to %s for two years, leaving %d %s at each crossing." % [name,String(p.carriers),String(p.dest_name),_n(toll3),String(p.toll_res)]) if toll3>0.0 else ("%s's %s may cross your country freely to %s for two years." % [name,String(p.carriers),String(p.dest_name)])
			memory="The ruler lets our %s cross their country to %s%s." % [String(p.carriers),String(p.dest_name),"" if toll3>0.0 else " and asks nothing"]
		"safe_passage:refuse":
			Hall._shift_relation(civ_id,-0.02+mood,0.01)
			reaction="neutral"
			outcome="You closed your country to %s's %s. They will go the long way round to %s." % [name,String(p.carriers),String(p.dest_name)]
			memory="The ruler would not let our %s cross their country." % String(p.carriers)
		_:
			return {"error":"That answer is not open to you here."}
	if memory!="": ForeignDiplomacy.remember(civ_id,memory)
	_note_answer(audience,type,option_id,facts)
	return {"outcome":_fix(outcome),"reaction":reaction}

# --------------------------------------------------------------------------
# Captives: real capture records change hands
# --------------------------------------------------------------------------

static func _release_ours(civ_id:String,count:int)->void:
	## Your scouts held by them come home (they were never counted dead).
	var cohort:Variant=CivilizationSystem.captured_player_scouts.get(civ_id)
	if not cohort is Dictionary: return
	var left:=maxi(0,int((cohort as Dictionary).get("count",0))-count)
	if left<=0: CivilizationSystem.captured_player_scouts.erase(civ_id)
	else: (cohort as Dictionary)["count"]=left

static func _release_theirs(civ_id:String,count:int)->void:
	## Their scouts held by your people go home: off your prisoner rolls, back
	## to their people.
	var cohort:Variant=CivilizationSystem.captured_foreign_scouts.get(civ_id)
	if not cohort is Dictionary: return
	var freed:=mini(count,maxi(0,int((cohort as Dictionary).get("count",0))))
	var left:=int((cohort as Dictionary).get("count",0))-freed
	if left<=0: CivilizationSystem.captured_foreign_scouts.erase(civ_id)
	else: (cohort as Dictionary)["count"]=left
	if freed<=0: return
	_civ_field(civ_id,"population",float(freed),1.0,1e9)
	var military:Variant=WorldSimulation.military
	if military is Object and "foreign_prisoners" in (military as Object):
		(military as Object).set("foreign_prisoners",maxi(0,int((military as Object).get("foreign_prisoners"))-freed))

# --------------------------------------------------------------------------
# Answers remembered: the next envoy of the same people says how you answered
# --------------------------------------------------------------------------

const ANSWERS_PER_CIV:=3
const FOLLOWUP_MAX_DAYS:=2190
const ANSWER_CIVS_MAX:=32
## Facts kept for the next envoy's words (numbers and names only).
const FACT_KEYS:=["amount","sent","back","bres","repay_res","repay_amt","food","workers","where","res","give_res","give_amt","get_res","get_amt","people","reason","place","monthly","craft_name",
	"pay_res","pay_amt","herbs","third_name","heir","woman","timber","name","why","price","what","offer_res","offer_amt","enemy_name","ruler","parent","toll_res","toll_amt","side","count",
	"stone","laid","hunters","meat","dest_name","carriers","fear","gift_res","gift_amt","paid","freed","failed","resource"]

static func _answers()->Dictionary:
	var e:=store()
	if not e.get("answers") is Dictionary: e["answers"]={}
	return e.answers

static func _note_answer(audience:Dictionary,type:String,option_id:String,facts:Dictionary,kind:String="")->void:
	var civ_id:=String(audience.get("civ_id",""))
	if civ_id=="": return
	var x:={}
	for key in FACT_KEYS:
		if not facts.has(key): continue
		var v:Variant=facts[key]
		if v is float or v is int: x[key]=roundi(float(v))
		elif v is bool: x[key]=v
		elif v is String: x[key]=String(v).substr(0,60)
	var all:=_answers()
	var list:Array=all.get(civ_id,[]) if all.get(civ_id) is Array else []
	var id:=String(audience.get("id",""))
	for index in range(list.size()-1,-1,-1):
		if String((list[index] as Dictionary).get("a",""))==id: list.remove_at(index)
	var entry:={"a":id.substr(0,40),"d":_day(),"t":type,"o":option_id.substr(0,24),"x":x,"told":0}
	if kind!="": entry["k"]=kind.substr(0,20)
	list.push_front(entry)
	while list.size()>ANSWERS_PER_CIV: list.pop_back()
	all[civ_id]=list
	while all.size()>ANSWER_CIVS_MAX: all.erase(all.keys()[0])

static func note_hall_answer(audience:Dictionary,option_id:String)->void:
	## The hall's own business (aid, tribute, gifts) is remembered the same way,
	## by what changed hands.
	var type:=Hall._situation_type(audience)
	if TYPES.has(type) or String(audience.get("origin",""))!="foreign": return
	var terms:Dictionary=audience.get("terms",{}) if audience.get("terms") is Dictionary else {}
	if String(terms.get("resource",""))=="" or float(terms.get("amount",0.0))<=0.0: return
	if not String(audience.get("kind","")) in ["request","threat","gift"]: return
	var share:=0.5 if option_id=="grant_half" else 1.0
	_note_answer(audience,type,option_id,{"resource":String(terms.resource),"amount":float(terms.amount)*share},String(audience.get("kind","")))

static func _mark_paid(audience_key:String,civ_id:String,how:String)->void:
	for entry in _answers().get(civ_id,[]):
		if entry is Dictionary and String(entry.get("a",""))==audience_key and audience_key!="": (entry.x as Dictionary)["repaid"]=how

## "{when}" and the facts fill these; the envoy speaks for their people.
const RECALL_WORDS:={
	"food_loan:accept":"{When} you lent us {sent} Food when our stores failed{repaid}.",
	"food_loan:partial":"{When} you lent us {sent} Food when our stores failed{repaid}.",
	"food_loan:gift":"{When} you gave us {sent} Food in our hunger and asked nothing back. {Who} has not forgotten it.",
	"food_loan:refuse":"{When} we came hungry and you would not lend us food.",
	"work_for_food:accept":"{When} our young people worked your {where} for the Food you gave our families.",
	"work_for_food:partial":"{When} half our young people worked your {where} for your Food.",
	"work_for_food:gift":"{When} you fed our families and would not take our work for it.",
	"work_for_food:refuse":"{When} you would not trade food for our work.",
	"barter:accept":"{When} we traded our {get_res} for your {give_res}, and both sides kept to it.",
	"barter:bargain":"{When} you drove a hard bargain over our {get_res}.",
	"barter:refuse":"{When} you would not trade with us.",
	"refuge:accept":"{When} you took in {people} of our people when we could not keep them.",
	"refuge:partial":"{When} you took in our mothers and children and sent the rest home.",
	"refuge:refuse":"{When} you turned our families away at your border.",
	"forage_leave:accept":"{When} you let our hunters into your {place}.",
	"forage_leave:bargain":"{When} you asked a price before our hunters could go into your {place}.",
	"forage_leave:refuse":"{When} you kept our hunters out of your {place}.",
	"craft_teaching:accept":"{When} you sent us a teacher of {craft_name}, for our {pay_res}.",
	"craft_teaching:gift":"{When} you sent us a teacher of {craft_name} and asked nothing for it.",
	"craft_teaching:refuse":"{When} you kept {craft_name} from us.",
	"healer_plea:accept":"{When} you sent your healers into our sick camps.",
	"healer_plea:partial":"{When} you sent us plants for the sick but kept your healers home.",
	"healer_plea:refuse":"{When} the sickness was in our camps, you closed the paths to us.",
	"mediation:accept":"{When} you judged the {place} ours, against {third_name}.",
	"mediation:partial":"{When} you divided the {place} between us and {third_name}, and the killing stopped.",
	"mediation:other":"{When} you gave the {place} to {third_name}.",
	"mediation:refuse":"{When} you would not judge between us and {third_name}.",
	"marriage_request:accept":"{When} one of your people married {heir}. We are kin now.",
	"marriage_request:partial":"{When} {heir} went to live among your people as a spouse. We are kin now.",
	"marriage_request:refuse":"{When} you refused a match with our house.",
	"border_line:accept":"{When} you gave us the {place}, and the border went quiet.",
	"border_line:partial":"{When} you made the {place} common ground.",
	"border_line:refuse":"{When} you held the line at the {place} against us.",
	"fugitive_return:accept":"{When} you gave {name} back to us to answer for it.",
	"fugitive_return:bargain":"{When} you paid a blood-price to keep {name}.",
	"fugitive_return:refuse":"{When} you sheltered {name} from our judgment.",
	"blessing_rite:accept":"{When} you blessed {what} and took our {offer_res}.",
	"blessing_rite:partial":"{When} you blessed {what} and sent our offering home with us.",
	"blessing_rite:bargain":"{When} you asked twice the offering for your blessing.",
	"blessing_rite:refuse":"{When} you would not bless us.",
	"war_supplies:accept":"{When} you sent us {amount} {res} for our war with {enemy_name}.",
	"war_supplies:gift":"{When} you sent us {amount} {res} for our war with {enemy_name} and asked nothing.",
	"war_supplies:refuse":"{When} you kept out of our war with {enemy_name}.",
	"succession_backing:accept":"{When} you named {ruler} our rightful ruler, and the quarrel in the house ended.",
	"succession_backing:bargain":"{When} you named {ruler} our ruler for a quieter border.",
	"succession_backing:refuse":"{When} you withheld your word from {ruler}.",
	"hostage_exchange:accept":"{When} we exchanged young kin with you as pledges of peace.",
	"hostage_exchange:bargain":"{When} you took one of our young kin as a pledge and gave none back.",
	"hostage_exchange:refuse":"{When} you declined our pledges of peace.",
	"sacred_site:accept":"{When} you let our people visit {what} in your {place}.",
	"sacred_site:bargain":"{When} you asked a toll before we could visit our own {place}.",
	"sacred_site:refuse":"{When} you barred us from {what}.",
	"captive_scouts:accept":"{When} {scouts_paid}",
	"captive_scouts:partial":"{When} you gave your word that no more of your scouts would come into our country.",
	"captive_scouts:refuse":"{When} {scouts_refused}",
	"captive_scouts:bargain":"{When} {scouts_ransom}",
	"rite_keeper:accept":"{When} you sent one who keeps your rites to live among us. We are learning your ways.",
	"rite_keeper:partial":"{When} you let one of our young people learn your ways among your people.",
	"rite_keeper:bargain":"{When} your keeper taught us what angers you. We have been careful since.",
	"rite_keeper:refuse":"{When} you would not teach us your ways.",
	"boundary_cairn:accept":"{When} our elders and yours raised the cairn at the {place}. It still stands.",
	"boundary_cairn:partial":"{When} you let us raise our cairn at the {place}.",
	"boundary_cairn:refuse":"{When} you would not mark the line with us at the {place}.",
	"joint_hunt:accept":"{When} your hunters drove the herd with ours in the {place}.",
	"joint_hunt:gift":"{When} your hunters drove the herd with ours in the {place} and left us all the meat.",
	"joint_hunt:refuse":"{When} you kept your hunters home from our drive.",
	"safe_passage:accept":"{When} you let our {carriers} cross your country to {dest_name}.",
	"safe_passage:gift":"{When} you let our {carriers} cross your country freely.",
	"safe_passage:refuse":"{When} you closed your country to our {carriers}.",
	"request:grant":"{When} you gave us {amount} {resource} when we asked for it.",
	"request:grant_half":"{When} you gave us {amount} {resource}, half of what we asked.",
	"request:refuse":"{When} we asked you for {resource} and went home with nothing.",
	"threat:pay":"{When} you paid the {amount} {resource} we demanded.",
	"threat:defy":"{When} you would not pay the tribute we demanded.",
	"threat:counter":"{When} you answered our demand with one of your own.",
	"gift:accept":"{When} you took our gift of {amount} {resource}.",
	"gift:accept_return":"{When} you took our gift of {resource} and sent some of it back with us.",
	"gift:decline":"{When} you sent our gift of {resource} back.",
	"gratitude_gift:accept":"{When} you took the {resource} we sent in thanks for your help.",
}

static func _when(days:int)->String:
	if days<200: return "This season"
	if days<500: return "Last year"
	if days<2400: return "%s winters ago" % Hall._cap_first(["two","three","four","five","six","seven"][clampi(roundi(days/365.0)-2,0,5)])
	return "Many winters ago"

static func recall_text(civ_id:String,entry:Dictionary,day:int)->String:
	var key:="%s:%s" % [String(entry.get("t","")),String(entry.get("o",""))]
	var template:=String(RECALL_WORDS.get(key,RECALL_WORDS.get("%s:%s" % [String(entry.get("k","")),String(entry.get("o",""))],"")))
	if template=="": return ""
	var x:Dictionary=entry.get("x",{}) if entry.get("x") is Dictionary else {}
	var fill:={"When":_when(day-int(entry.get("d",day))),"Who":_given(civ_id)}
	for k in x: fill[String(k)]=str(x[k])
	# What became of it since: a loan repaid or still owed, scouts freed or kept.
	var repaid:=String(x.get("repaid",""))
	var owed:=""
	if repaid=="full": owed=", and we paid back %s %s, as we promised" % [str(x.get("back","")),String(x.get("bres",""))]
	elif repaid=="none": owed=". We could not pay it back, and we are ashamed of that"
	elif x.has("back"): owed=", and we still owe you %s %s" % [str(x.back),String(x.get("bres",""))]
	fill["repaid"]=owed
	var n:=int(x.get("count",0))
	fill["scouts_paid"]=("you paid %s Food for your %d scouts, and we sent them home." % [str(x.get("paid","")),n]) if String(x.get("side",""))=="ours" else "you sent our %d scouts home." % n
	fill["scouts_refused"]=("you kept our %d scouts and would not send them home." % n) if String(x.get("side",""))=="theirs" else ("you demanded your scouts back and we %s." % ("gave them up" if bool(x.get("freed",false)) else "kept them"))
	fill["scouts_ransom"]=("we paid %s %s for our scouts." % [str(x.get("paid","")),String(x.get("pay_res",""))]) if int(x.get("paid",0))>0 else "you asked a ransom for our scouts and we would not pay it."
	var text:=template
	for k in fill: text=text.replace("{%s}" % String(k),String(fill[k]))
	if "{" in text: return ""
	return _fix(text)

static func followup(civ_id:String,audience_id:String,day:int)->Dictionary:
	## The last answer this people had from the god, if not yet spoken of.
	var list:Array=_answers().get(civ_id,[]) if _answers().get(civ_id) is Array else []
	for entry in list:
		if not entry is Dictionary or String(entry.get("a",""))==audience_id: continue
		# Only the latest dealing, once, and only while it is still fresh talk.
		var age:=day-int(entry.get("d",day))
		if (int(entry.get("told",0))>=1 and String(entry.get("told_a",""))!=audience_id) or age<30 or age>FOLLOWUP_MAX_DAYS: return {}
		var text:=recall_text(civ_id,entry,day)
		if text=="": return {}
		return {"entry":entry,"text":text}
	return {}

static func _grudge_retold(civ_id:String,grudge_day:int)->bool:
	## Whether this grudge had already been named by an earlier envoy.
	var r:=_rivals()
	if r==null: return false
	for g in (r.call("character",civ_id) as Dictionary).get("grudges",[]):
		if g is Dictionary and int(g.get("day",-2))==grudge_day: return int(g.get("recalled",0))>=2
	return false

static func attach_followup(audience:Dictionary)->void:
	## A returning people's envoy says how the god answered them last time,
	## unless their ruler is already raising an older grudge, debt or bond.
	if String(audience.get("origin",""))!="foreign": return
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	# A beaten people does not come to talk over old tribute (envoy_aftermath.gd).
	if bool(situation.get("no_followup",false)): return
	var old:Dictionary=situation.get("recall",{}) if situation.get("recall") is Dictionary else {}
	# An old grudge their envoys have already named yields to how the god
	# answered this people last (fresher, and not yet said); other memories stand.
	if not old.is_empty() and not (String(old.get("kind",""))=="grudge" and _grudge_retold(String(audience.get("civ_id","")),int(old.get("day",-1)))): return
	if (situation.get("arc",{}) is Dictionary) and not (situation.get("arc",{}) as Dictionary).is_empty() and not TYPES.has(String(situation.get("type",""))): return
	var civ_id:=String(audience.get("civ_id",""))
	var day:=int(audience.get("arrived_day",_day()))
	var found:=followup(civ_id,String(audience.get("id","")),day)
	if found.is_empty(): return
	if String((found.entry as Dictionary).get("told_a",""))!=String(audience.get("id","")):
		(found.entry as Dictionary)["told"]=int((found.entry as Dictionary).get("told",0))+1
		(found.entry as Dictionary)["told_a"]=String(audience.get("id","")).substr(0,40)
	var summary:=String(situation.get("summary",""))
	if not old.is_empty(): summary=summary.replace(" "+String(old.get("text","")),"").replace(String(old.get("text","")),"")
	situation["recall"]={"kind":"answer","text":String(found.text),"day":int((found.entry as Dictionary).get("d",day)),"ruler":String(ForeignDiplomacy.leader(civ_id).get("name",""))}
	situation["summary"]=(summary+" "+String(found.text)).strip_edges().substr(0,700)
	audience["situation"]=situation

# --------------------------------------------------------------------------
# Typed answers (online): the god's own words onto the same bounded answers
# --------------------------------------------------------------------------

const RESOURCE_WORDS:={"Food":["food","meat","grain","fish"],"Timber":["timber","wood","logs"],"Stone":["stone","stones","flint","rock"],"Clay":["clay"],"Fiber Plants":["fiber","fibre","reeds","flax","plants"]}
const YES_WORDS:=["yes","agree","agreed","accept","very well","do it","so be it","granted","grant it","gladly"]
const NO_WORDS:=["no","refuse","decline","never","go home","send them away","turn them away","reject","not this time","nothing"]
const NEGATIONS:=["not","don't","do not","never","won't","will not","no","cannot","can't","shall not"]
## Words that name each answer, per kind ({civ}, {third}, {heir}, {name} are
## filled from the request). The yes/no words above join accept/refuse.
const ANSWER_PHRASES:={
	"food_loan":{"accept":["lend","loan","borrow","owe us","pay us back","pay it back","repay"],"gift":["freely","as a gift","ask nothing","nothing back","nothing in return","give it","give them","keep it"],"refuse":["no food","not lend"]},
	"work_for_food":{"accept":["work","labour","labor","put them to work","take their"],"gift":["no work","ask no work","feed them","send the workers home"],"refuse":["no food"]},
	"barter":{"accept":["trade","deal","exchange","make the trade"],"bargain":["more","better price","hold out","too little","a third more"],"refuse":["no trade"]},
	"refuge":{"accept":["take them","take them in","let them stay","let them settle","welcome them","let them in"],"partial":["children","mothers","women and children"],"refuse":["turn them away","send them back","no room"]},
	"forage_leave":{"accept":["let them hunt","grant","they may hunt","hunt"],"bargain":["price","pay","payment","for a price"],"refuse":["keep them out","keep out","no hunting","stay out"]},
	"craft_teaching":{"accept":["teach","send a teacher","for the price","for their"],"gift":["freely","for nothing","ask nothing","as a gift"],"refuse":["keep the craft","keep it","secret","our own"]},
	"healer_plea":{"accept":["healers","send healers","send our healers"],"partial":["plants only","only the plants","just the plants","send the plants","no healers","keep our healers","keep the healers"],"refuse":["close the paths","keep away"]},
	"mediation":{"accept":["{civ}","for them","their claim","it is theirs"],"partial":["divide","split","share","both","each side","halves"],"other":["{third}","the other"],"refuse":["not judge","won't judge","settle it themselves","themselves","not my quarrel"]},
	"marriage_request":{"accept":["send","one of ours","one of our","marry","match"],"partial":["come here","live here","live among us","{heir} come","bring {heir}"],"refuse":["no match","no marriage"]},
	"border_line":{"accept":["give them","grant","let them have","it is theirs"],"partial":["common","share","both"],"refuse":["hold the line","ours","keep it"]},
	"fugitive_return":{"accept":["hand","give {name}","give him","give her","send him back","send her back","take him","take her"],"bargain":["blood-price","blood price","pay","price"],"refuse":["shelter","keep {name}","protect","stays","stay with us"]},
	"blessing_rite":{"accept":["bless","take the offering","accept the offering"],"partial":["keep the offering","keep their offering","send the offering back","take nothing","no offering"],"bargain":["twice","double","more"],"refuse":["not their god","no blessing","will not bless"]},
	"war_supplies":{"accept":["send","supplies","arm them","give them"],"gift":["freely","for nothing","ask nothing","no payment"],"refuse":["stay out","not our war","keep out","no supplies"]},
	"succession_backing":{"accept":["rightful","recognise","recognize","support","back {ruler}","name {ruler}"],"bargain":["border","pull back","in return","if they"],"refuse":["withhold","let the house","settle it"]},
	"hostage_exchange":{"accept":["exchange","both ways","pledges"],"bargain":["take their","send none","only theirs","without one"],"refuse":["no pledges"]},
	"sacred_site":{"accept":["let them come","let them visit","they may","welcome","may come"],"bargain":["toll","pay","price"],"refuse":["bar","keep them out","stay away"]},
	"captive_scouts:ours":{"accept":["pay","ransom","the food"],"partial":["word","promise","no more scouts","swear"],"refuse":["demand","release them","give them back","free them","return them"]},
	"captive_scouts:theirs":{"accept":["send them home","release","let them go","free them","go home"],"bargain":["ransom","pay","price"],"refuse":["keep them","they stay"]},
	"rite_keeper":{"accept":["send","keeper","teach them"],"partial":["learn here","come here","one of theirs"],"bargain":["fear","afraid","angers","wrath","obey"],"refuse":["not their god"]},
	"boundary_cairn":{"accept":["together","raise it","build it","our stone","our elders"],"partial":["let them raise","themselves","alone","their own"],"refuse":["no stones","unmarked","no cairn"]},
	"joint_hunt":{"accept":["send","hunters","join","our share"],"gift":["keep the meat","all the meat","give up","no share"],"refuse":["keep our hunters","stay home","no hunt"]},
	"safe_passage":{"accept":["toll","crossing gift","pass","cross","grant"],"gift":["freely","for nothing","no toll","ask nothing"],"refuse":["close","no passage","long way"]},
}
## The field each kind's share of goods scales, for "give them 40" or "a third".
const SHARE_FIELD:={"food_loan":"amount","work_for_food":"food","barter":"give_amt","refuge":"people","healer_plea":"herbs","war_supplies":"amount"}

static func answerable(audience:Dictionary)->bool:
	return TYPES.has(Hall._situation_type(audience)) and String(audience.get("status",""))=="waiting" and String(audience.get("origin",""))=="foreign"

static func _norm(text:String)->String:
	var clean:=" "+text.to_lower().replace("’","'")+" "
	for mark in [",",".","!",";",":","\"","(",")"]: clean=clean.replace(mark," ")
	while clean.contains("  "): clean=clean.replace("  "," ")
	return clean

static func _has_phrase(clean:String,phrase:String)->Array:
	## [found, negated]: whole-word match, and whether a negation stands
	## within two words before it.
	var at:=clean.find(" "+phrase+" ")
	if at<0: return [false,false]
	var before:=clean.substr(0,at).strip_edges().split(" ",false)
	var window:=" "+" ".join(before.slice(maxi(0,before.size()-3)))+" "
	for neg in NEGATIONS:
		if window.contains(" "+String(neg)+" "): return [true,true]
	return [true,false]

static func typed_share(text:String,audience:Dictionary)->float:
	## A share of the goods named in words or as a number; -1 when none.
	var clean:=_norm(text)
	for pair in [["two thirds",0.67],["three quarters",0.75],["a third",0.33],["one third",0.33],["a quarter",0.25],["one quarter",0.25],["half",0.5],["all of it",1.0],["all they ask",1.0],["everything they ask",1.0]]:
		if clean.contains(" "+String(pair[0])+" "): return float(pair[1])
	var field:=String(SHARE_FIELD.get(Hall._situation_type(audience),""))
	var p:=_req(audience)
	if field=="" or float(p.get(field,0.0))<=0.0: return -1.0
	var number:=RegEx.new(); number.compile("\\b(\\d+)\\b")
	var m:=number.search(clean)
	if m==null: return -1.0
	return clampf(float(m.get_string(1))/float(p.get(field)),0.1,1.0)

static func typed_resource(text:String,exclude:String)->String:
	var clean:=_norm(text)
	for res in RESOURCE_WORDS:
		if String(res)==exclude: continue
		for word in RESOURCE_WORDS[res]:
			if clean.contains(" "+String(word)+" "): return String(res)
	return ""

static func typed_choice(audience:Dictionary,text:String)->Dictionary:
	## {option, share?, repay_res?} when the words clearly name one open answer;
	## {} when they are a question, say nothing about it, or could mean two.
	if not answerable(audience): return {}
	var raw:=text.strip_edges()
	if raw=="" or raw.ends_with("?"): return {}
	# Conditions and long speeches are for the live reading (or talk), not
	# for keywords: "not unless they send stone" is not a plain refusal.
	var plain:=_norm(raw)
	for word in [" if "," unless "," but "," until "," when "," after "]:
		if plain.contains(word): return {}
	if plain.split(" ",false).size()>16: return {}
	var type:=Hall._situation_type(audience)
	var p:=_req(audience)
	var open:Array=[]
	for option in options(audience):
		if bool(option.get("enabled",true)): open.append(String(option.id))
	var table:Dictionary=ANSWER_PHRASES.get(type if type!="captive_scouts" else "captive_scouts:"+String(p.get("side","ours")),{})
	var fill:={"{civ}":String(audience.get("civ_name","")).to_lower(),"{third}":String(p.get("third_name","")).to_lower(),"{heir}":String(p.get("heir","")).to_lower(),
		"{name}":String(p.get("name","")).to_lower(),"{ruler}":String(p.get("ruler","")).to_lower()}
	var clean:=_norm(raw)
	var scores:={}
	for id in open: scores[id]=0
	var phrases:={}
	for id in table: phrases[id]=(table[id] as Array).duplicate()
	if not phrases.has("accept"): phrases["accept"]=[]
	if not phrases.has("refuse"): phrases["refuse"]=[]
	(phrases.accept as Array).append_array(YES_WORDS)
	(phrases.refuse as Array).append_array(NO_WORDS)
	for id in phrases:
		for phrase in phrases[id]:
			var words:=String(phrase)
			for slot in fill: words=words.replace(String(slot),String(fill[slot]))
			if words.strip_edges()=="" or words.contains("{"): continue
			var hit:=_has_phrase(clean,words)
			if not bool(hit[0]): continue
			# "Do not lend them anything" is a refusal, not a loan.
			var target:=String(id) if not bool(hit[1]) or String(id)=="refuse" else "refuse"
			if scores.has(target): scores[target]=int(scores[target])+words.length()
	var best:=""
	var best_score:=0
	var tied:=false
	for id in scores:
		if int(scores[id])>best_score: best=String(id); best_score=int(scores[id]); tied=false
		elif int(scores[id])==best_score and best_score>0: tied=true
	if best=="" or tied: return {}
	var out:={"option":best}
	if best in ["accept","gift"] and SHARE_FIELD.has(type):
		var share:=typed_share(raw,audience)
		if share>0.0 and share<0.99:
			# "Lend them half" is the half-loan answer the cards offer.
			if best=="accept" and absf(share-0.5)<0.01 and "partial" in open and type in ["food_loan","work_for_food"]: out.option="partial"
			else: out["share"]=share
	if type=="food_loan" and String(out.option) in ["accept","partial"]:
		var res:=typed_resource(raw,"Food")
		if res!="": out["repay_res"]=res
	return out

static func apply_typed(audience:Dictionary,terms:Dictionary)->void:
	## Keeps the typed adjustments on the request for resolve() to read.
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var typed:={}
	if terms.has("share"): typed["share"]=clampf(float(terms.share),0.1,1.0)
	if String(terms.get("repay_res","")) in Hall.RESOURCES: typed["repay_res"]=String(terms.repay_res)
	if typed.is_empty(): situation.erase("typed")
	else: situation["typed"]=typed
	audience["situation"]=situation

# --------------------------------------------------------------------------
# Offline words: concrete, from the request itself
# --------------------------------------------------------------------------

static func open_lines(audience:Dictionary)->Array:
	## Opening lines for the envoy, filled from the facts; the voice uses the
	## first one not yet said (and one the AI wrote first, when it did).
	var type:=Hall._situation_type(audience)
	if Aftermath.handles(type): return Aftermath.open_lines(audience)
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
		"captive_scouts":
			if String(p.side)=="ours":
				out.append_array(["We caught %d of your people creeping through our country, watching our camps. %s will send them home for %d Food." % [int(p.count),who,_n(p.price)],
					"Your scouts are alive and fed. Pay %d Food, or promise no more will come, and %s sends them home." % [_n(p.price),who]])
			else:
				out.append_array(["Your people hold %d of ours, caught in your country. %s asks for them back." % [int(p.count),who],
					"%s wants our %d scouts home. They were sent to look, not to fight." % [who,int(p.count)]])
		"rite_keeper":
			if bool(p.get("fear",false)):
				out.append_array(["We do not know what angers you, and we are afraid of getting it wrong. Send us someone who knows.",
					"%s asks for one of your people who keeps your rites. Tell us what is owed to you and we will give it." % who])
			else:
				out.append_array(["%s wants our people to honour you as yours do. Send one who keeps your rites to live with us." % who,
					"We have heard how your people honour you. Lend us one who knows the rites, and we will learn them."])
		"boundary_cairn":
			out.append_array(["Let us raise a cairn at the %s, your elders and ours, each bringing stones. Then nobody can say where the line is not." % String(p.place),
				"%s wants the line at the %s marked in stone, with both peoples watching it done." % [who,String(p.place)]])
		"joint_hunt":
			out.append_array(["There is a great herd in the %s, more than our hunters can turn. Send %d of yours and we share the meat." % [String(p.place),int(p.hunters)],
				"%s asks for %d of your hunters for the drive in the %s. About %d Food would be yours." % [who,int(p.hunters),String(p.place),_n(p.meat)]])
		"safe_passage":
			out.append_array(["Our %s go to %s, and the short way is through your country. %s would leave %d %s at each crossing." % [String(p.carriers),String(p.dest_name),who,_n(p.toll_amt),String(p.toll_res)],
				"Let our %s cross your country each season, and they will leave %d %s each time." % [String(p.carriers),_n(p.toll_amt),String(p.toll_res)]])
	return out.map(func(line:Variant)->String:return _fix(String(line)))

# --------------------------------------------------------------------------
# Daily: loans fall due
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if day%TICK!=0 or WorldSimulation.actor_id!="player": return
	_passages(day)
	_broken_word(day)
	var list:Array=store().pledges
	for pledge in list.duplicate():
		if not pledge is Dictionary or int(pledge.due)>day: continue
		var civ_id:=String(pledge.civ)
		var civ:=ForeignDiplomacy.civilization(civ_id)
		if civ.is_empty() or not bool(civ.get("alive",true)):
			list.erase(pledge); continue
		if _at_war(civ):
			pledge["due"]=day+90; continue
		if String(pledge.get("kind",""))=="hunt":
			list.erase(pledge)
			_finish_hunt(civ_id,civ,pledge)
			continue
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
				_mark_paid(String(pledge.get("a","")),civ_id,"full")
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
			_mark_paid(String(pledge.get("a","")),civ_id,"none")
			Hall._leader_trust(civ_id,-0.04)
			_record("%s Cannot Pay" % name.substr(0,40),"%s has not repaid %s, and says it cannot. The debt stands in memory, if not in the stores." % [name,_narrate(String(pledge.text))],civ_id)
			ForeignDiplomacy.remember(civ_id,"We could not repay what the ruler lent us. We are ashamed of it.")
		else:
			pledge["due"]=day+180
			_record("%s Asks for Time" % name.substr(0,40),"Word from %s: they cannot yet repay %s, and ask until the autumn." % [name,_narrate(String(pledge.text))],civ_id)

static func _finish_hunt(civ_id:String,civ:Dictionary,pledge:Dictionary)->void:
	## The drive is over: meat for both peoples, and sometimes a hunter lost.
	var name:=String(civ.get("name",civ_id))
	var brought:=EXCHANGE.receive("player","Food",float(pledge.amt)) if float(pledge.amt)>0.0 else 0.0
	if float(pledge.get("theirs",0.0))>0.0: Hall._credit_civ(civ_id,"Food",float(pledge.theirs))
	var lost:=bool(pledge.get("risk",false))
	if lost: _people(-1)
	var text:="Your hunters came back from the drive with %s in %s." % [name,_narrate(String(pledge.text)).replace("the drive in ","the ")]
	text+=(" They brought %d Food." % roundi(brought)) if brought>0.0 else " They left the meat with %s, as you told them." % name
	if lost: text+=" One of them was killed when the herd turned."
	_record("Back From the Drive",text,civ_id)

static func _passages(day:int)->void:
	## Carriers with leave to cross come each season and leave what was agreed.
	var r:=_rivals()
	if r==null: return
	for civ_id in ForeignDiplomacy.leaders.keys():
		var id:=String(civ_id)
		var civ:=ForeignDiplomacy.civilization(id)
		if civ.is_empty() or not bool(civ.get("alive",true)) or _at_war(civ): continue
		var b:Dictionary=r.call("has_bond",id,["passage"])
		if b.is_empty(): continue
		var data:Dictionary=b.get("data",{}) if b.get("data") is Dictionary else {}
		if day-int(data.get("last",int(b.get("day",day))))<91: continue
		data["last"]=day
		data["crossings"]=int(data.get("crossings",0))+1
		b["data"]=data
		var left:=_take_from(id,String(data.get("res","Food")),float(data.get("amt",0.0))) if float(data.get("amt",0.0))>0.0 else 0.0
		if int(data.crossings)==1: _record("%s Carriers Cross" % String(civ.get("name",id)).substr(0,40),"The first party from %s crossed your country as agreed%s." % [String(civ.get("name",id)),(", and left %d %s" % [roundi(left),String(data.get("res",""))]) if left>0.0 else ""],id)

static func _broken_word(day:int)->void:
	## Your word that no scouts would come, broken by a fresh capture.
	var r:=_rivals()
	if r==null: return
	for civ_id in CivilizationSystem.captured_player_scouts.keys():
		var id:=String(civ_id)
		var b:Dictionary=r.call("has_bond",id,["no_scouts"])
		if b.is_empty() or bool((b.get("data",{}) as Dictionary).get("broken",false)): continue
		var cohort:Variant=CivilizationSystem.captured_player_scouts[civ_id]
		if not cohort is Dictionary or int((cohort as Dictionary).get("captured_day",0))<=int(b.get("day",day)): continue
		b["data"]={"broken":true}
		_grudge(id,"how you gave your word that no scouts would come, and sent them anyway",0.4,"broken_word:%d" % day)
		Hall._shift_relation(id,-0.06,0.06)
		Hall._leader_trust(id,-0.1)

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
