extends RefCounted
## FAIR DEALS ON AN ENVOY'S BUSINESS (envoy_requests.gd).
##
## The user (2026-10-03): "I have a ton of food, and my neighbors will come by
## and ask for a favor and give me food in return. If I decline them, it ruins
## our relationship, but if I accept it, I'm giving them way too much for
## something that has zero impact on me at all."
##
## So every request that asks something of us and pays for it is weighed on
## both sides with deal_value.gd (one rule for every people):
##   - what we give: goods (worth what they are worth to us, so food out of
##     deep stores costs little), hands lent abroad for so many days (a day of
##     our output a head each), a person gone for good (a year of it), and the
##     stated risks (a hunter killed, a sickness brought home) at their odds;
##   - what we get: their payment, worth what it is worth to us now;
##   - their side the same way.
## What they offer (offer()) is the good we lack most against what it costs
## them, in the amount that leaves both sides about equally better off, times
## their ruler's temper (a desperate people offers more, a hard or proud one
## less), never more than a share of their stock. A people never pays in food
## a people drowning in food when it has anything else we can use.
##
## Turning a request down costs in proportion to how fair and how needed it
## was (scale()): declining a deal that was poor for us costs little or
## nothing; refusing a fair plea from a starving neighbour costs more than
## before; a courteous decline costs half of a blunt refusal; harming the
## envoy (the hall's envoy acts) costs most.
##
## Counters (counters()): ask the same worth to them in a good we lack more,
## or half again as much. Each states its odds that their ruler agrees (by
## temper, regard, trust and need) and what happens if not; a seeded roll
## decides. Typed answers (online) reach the same counters through
## envoy_requests.typed_choice and envoy_request_ai.read_answer.
##
## Static; preload. Reads the ledgers, never writes them (resolve does).

const DV:=preload("res://scripts/deal_value.gd")
const Hall:=preload("res://scripts/audience_hall.gd")

## A teacher of a craft stays with them this long.
const TEACH_DAYS:=60
## What a taught craft saves the learners: this many times the teacher's time.
const TEACH_GAIN:=2.0
## Healers stay this long in a sick people's camps.
const HEAL_DAYS:=30
## Odds the healers bring the sickness home (envoy_requests "risk" roll).
const HEAL_RISK:=0.45
## A sickness brought home: health falls 0.05 (rival_rulers.gd "sickness"),
## felt as this many days' work a head lost.
const SICK_LOSS:=0.05*10.0
## A sick people's health rises 0.06 with our healers: days' work a head saved.
const HEALED_GAIN:=0.06*30.0
## Odds a hunter dies on a great drive (envoy_requests joint_hunt "risk").
const HUNT_RISK:=0.2
## A keeper of our rites is worth this many of a person to the people who learn from them.
const RITE_GAIN:=1.5
## Carriers given passage: a party this size saves this many days each crossing.
const PASSAGE_PARTY:=6
const PASSAGE_SAVED:=8
## Their workers' time, while hungry and idle at home, at this share of a day's work.
const IDLE_HANDS:=0.1
## A share of the payer's stock it pays at most in one deal.
const PAY_SHARE:=0.35

## Requests that are deals: something of ours for something of theirs (or
## a plea for help). These get the deal block, proportional refusals and a
## courteous decline.
const DEALS:=["food_loan","work_for_food","barter","refuge","forage_leave","craft_teaching","healer_plea","war_supplies","sacred_site","rite_keeper","joint_hunt","safe_passage"]
## Where each deal keeps its payment: [good field, amount field].
const PAY_FIELDS:={"food_loan":["repay_res","repay_amt"],"work_for_food":["res","amount"],"barter":["get_res","get_amt"],"forage_leave":["pay_res","pay_amt"],
	"craft_teaching":["pay_res","pay_amt"],"healer_plea":["pay_res","pay_amt"],"war_supplies":["pay_res","pay_amt"],"rite_keeper":["gift_res","gift_amt"],
	"joint_hunt":["share_res","share_amt"],"safe_passage":["toll_res","toll_amt"],"blessing_rite":["offer_res","offer_amt"]}
## Deals whose payment may be countered (food_loan's repayment good is read
## from the god's words instead; barter and blessing have their own "ask more").
const COUNTER_GOOD:=["work_for_food","barter","forage_leave","craft_teaching","healer_plea","war_supplies","rite_keeper","joint_hunt","safe_passage"]
const COUNTER_MORE:=["forage_leave","craft_teaching","healer_plea","war_supplies","rite_keeper","joint_hunt","safe_passage","work_for_food"]
## Half again as much.
const MORE:=1.5

## A blunt refusal at full weight (a fair, needed request turned down): regard
## (o), the ruler's trust (t), border tension (x), a grudge's weight (g) and
## its words, their dread (d). The old fixed costs of each refusal.
const REFUSAL:={
	"food_loan":{"o":0.04,"t":0.04,"g":0.4,"why":"how you would not lend us food when we were hungry"},
	"work_for_food":{"o":0.03,"t":0.03,"x":0.02},
	"barter":{"o":0.01},
	"refuge":{"o":0.03,"t":0.03},
	"forage_leave":{"o":0.02,"x":0.03},
	"craft_teaching":{"o":0.02},
	"healer_plea":{"o":0.03},
	"war_supplies":{"o":0.02},
	"sacred_site":{"o":0.05,"x":0.03,"g":0.3,"why":"how you barred us from {what}"},
	"rite_keeper":{"o":0.04,"g":0.15,"d":0.03,"why":"how you would not teach us your ways"},
	"joint_hunt":{"o":0.01},
	"safe_passage":{"o":0.02,"x":0.01},
}
## A blunt refusal never stings less than this share of its full weight.
const BLUNT_FLOOR:=0.35
## A courteous decline weighs this share of a blunt refusal.
const COURTEOUS:=0.5
## Below this weight a turned-down request brings no grudge, and its people
## come back cooler rather than with a demand (audience_hall._sequel_plan).
const SOFT:=0.4
## A counter turned down: they go home without a deal, their regard this
## much lower (the card says it; nothing else is applied).
const COUNTER_LOST:=0.01

# --------------------------------------------------------------------------
# Need and temper
# --------------------------------------------------------------------------

static func hunger(civ:Dictionary)->float:
	return clampf((22.0-float(civ.get("food_days",30.0)))/22.0,0.0,1.0)

static func sickness(civ:Dictionary)->float:
	return clampf((0.6-float(civ.get("health",0.7)))/0.4,0.0,1.0)

## How badly they need what they ask, 0 (plain business) to 1 (desperate).
static func need(type:String,civ_id:String)->float:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var h:=hunger(civ)
	match type:
		"food_loan","work_for_food","forage_leave": return h
		"refuge": return clampf(0.5+0.5*maxf(h,sickness(civ)),0.0,1.0)
		"healer_plea": return maxf(0.3,sickness(civ))
		"war_supplies": return 0.6
		"joint_hunt": return 0.2+0.5*h
		# Their own dead and holy places: a need, not a want.
		"sacred_site": return 0.6
		"rite_keeper": return 0.35
	return clampf(0.15+0.4*h,0.0,1.0)

## How freely their ruler pays: above 1 a desperate or kindly people, below 1
## a hard or proud one.
static func temper(civ_id:String,needed:float)->float:
	var p:=Hall._personality(civ_id)
	var proud:=String(ForeignDiplomacy.leader(civ_id).get("temperament",""))=="Proud guardian"
	return clampf(1.0+0.3*needed-0.4*(float(p.assertiveness)-0.5)+0.2*(float(p.empathy)-0.5)-(0.1 if proud else 0.0),0.7,1.35)

## How much of a loan their stores could repay, by the repayment rule itself
## (envoy_requests.daily): when it falls due, traders bring what they owe if
## they hold at least half of it, up to 6 in 10 of what they hold, and come
## again for the rest. Read from what they hold now: {share (0..1 of the
## loan their stores cover today), words (their holding and their record)}.
static func repayable(civ_id:String,res:String,owed:float)->Dictionary:
	if owed<=0.0: return {"share":1.0,"words":"nothing owed"}
	var held:=DV.held(civ_id,res)
	var share:=0.0
	var words:=""
	if held>=owed/0.6: share=1.0; words="they hold %d %s now, enough to repay it in full if they still do when it falls due" % [roundi(held),res]
	elif held>=owed*0.5: share=clampf(held*0.6/owed,0.0,1.0); words="they hold %d %s now, enough for about %d of it at first" % [roundi(held),res,roundi(held*0.6)]
	else: words="they hold only %d %s now, too little to repay unless they gather more" % [roundi(held),res]
	var failed:=0
	var repaid:=0
	var answers:Variant=(Hall.state().get("envoy_requests",{}) as Dictionary).get("answers",{}) if Hall.state().get("envoy_requests") is Dictionary else {}
	if answers is Dictionary:
		for entry in (answers as Dictionary).get(civ_id,[]):
			var how:=String(((entry as Dictionary).get("x",{}) as Dictionary).get("repaid","")) if entry is Dictionary else ""
			if how=="none": failed+=1
			elif how=="full": repaid+=1
	if failed>0: words+="; they failed to repay us %s before" % ("once" if failed==1 else "%d times" % failed)
	elif repaid>0: words+="; they have repaid us before"
	return {"share":share,"words":words}

# --------------------------------------------------------------------------
# What they offer
# --------------------------------------------------------------------------

## The goods `payer` pays `payee` for a thing that costs the payee `cost`
## and is worth `gain` to the payer: {res, amt, worth (to the payee), cost
## (to the payer), even (the worth an even split would give), capped}; {}
## when the payer holds nothing the payee can use. `only` limits the goods.
static func offer(payer:String,payee:String,cost:float,gain:float,mood:float=1.0,exclude:Array=[],only:Array=[],share:float=PAY_SHARE,min_stock:float=10.0)->Dictionary:
	if not DV.simulated(payer): return {}
	var best:={}
	var best_score:=-1.0
	for good:String in (only if not only.is_empty() else DV.GOODS):
		if good in exclude or not DV.usable(payee,good): continue
		var rp:=DV.reading(payer,good)
		if float(rp.h)<min_stock: continue
		var rq:=DV.reading(payee,good)
		var most:=float(rp.h)*share
		var even:=_even(rp,rq,gain+cost,most)
		var target:=DV.in_reading(rq,even)*mood
		# Never more than the thing is worth to the payer, by its temper.
		var most_worth:=DV.qty_for_cost(rp,maxf(0.0,gain*mood),most) if gain>0.0 else most
		var q:=Hall._nice(minf(DV.qty_for_worth(rq,target,most),most_worth))
		if q>float(rp.h)*share+0.5: q=floorf(float(rp.h)*share)
		if q<1.0: continue
		var w:=DV.in_reading(rq,q)
		var c:=DV.out_reading(rp,q)
		var fair_target:=maxf(1.0,(gain+cost)*0.5)
		# Reaching an even deal first; then the good that gives the payee the
		# most for what it costs the payer.
		var score:=minf(w/fair_target,1.0)*10.0+minf(w/maxf(0.01,c),10.0)
		if score>best_score:
			best_score=score
			best={"res":good,"amt":q,"worth":w,"cost":c,"even":fair_target,"capped":q>=floorf(most)-0.5}
	return best

static func _even(rp:Dictionary,rq:Dictionary,total:float,most:float)->float:
	## The amount at which worth to the payee plus cost to the payer is the
	## whole of the cost and gain: each side ends equally better off.
	if total<=0.0 or most<=0.0: return 0.0
	if DV.in_reading(rq,most)+DV.out_reading(rp,most)<=total: return most
	var lo:=0.0
	var hi:=most
	for i in 22:
		var mid:=(lo+hi)*0.5
		if DV.in_reading(rq,mid)+DV.out_reading(rp,mid)<total: lo=mid
		else: hi=mid
	return hi

# --------------------------------------------------------------------------
# Weighing a request: both sides, in rations' worth
# --------------------------------------------------------------------------

## {us_give, us_get, them_give, them_get, give:[words], get:[words], risk:[words],
## plea}: what each side gives and gets if the request is taken as asked.
static func weigh(type:String,p:Dictionary,civ_id:String)->Dictionary:
	var w:={"us_give":0.0,"us_get":0.0,"them_give":0.0,"them_get":0.0,"give":[],"get":[],"risk":[],"plea":false}
	var pop_them:=DV.population(civ_id)
	match type:
		"food_loan":
			_goods_out(w,"Food",float(p.get("amount",0)),civ_id)
			var back:=repayable(civ_id,String(p.get("repay_res","Food")),float(p.get("repay_amt",0)))
			_goods_in(w,String(p.get("repay_res","Food")),float(p.get("repay_amt",0)),civ_id,float(back.share),"back within the year (%s)" % String(back.words))
		"work_for_food":
			_goods_out(w,"Food",float(p.get("food",0)),civ_id)
			_goods_in(w,String(p.get("res","Timber")),float(p.get("amount",0)),civ_id,1.0,"gathered by their workers")
			w.them_give=float(w.them_give)-DV.worth_out(civ_id,String(p.get("res","Timber")),float(p.get("amount",0)))+float(p.get("workers",0))*float(p.get("days",60))*DV.day_of_work(civ_id)*IDLE_HANDS
		"barter":
			_goods_out(w,String(p.get("give_res","Food")),float(p.get("give_amt",0)),civ_id)
			_goods_in(w,String(p.get("get_res","Food")),float(p.get("get_amt",0)),civ_id)
		"refuge":
			# More mouths at our fires for the first month (they work after).
			w.plea=true
			var people:=float(p.get("people",0))
			var month:=people*30.0
			var mouths:=DV.worth_out("player","Food",month)
			w.us_give=float(w.us_give)+mouths
			w.them_get=float(w.them_get)+DV.worth_in(civ_id,"Food",month)
			(w.give as Array).append("%d more mouths, about %d Food in their first month, worth about %d to us (%s); more hands after" % [roundi(people),roundi(month),roundi(mouths),DV.depth_words("player","Food")])
		"forage_leave":
			_goods_out(w,"Food",float(p.get("monthly",0))*float(p.get("months",6)),civ_id,"taken as game from our %s over %d months" % [String(p.get("place","country")),int(p.get("months",6))])
			_pay(w,type,p,civ_id)
		"craft_teaching":
			_hands_out(w,1,TEACH_DAYS,civ_id,TEACH_GAIN,"a teacher of %s away for %d days" % [String(p.get("craft_name","our craft")),TEACH_DAYS])
			_pay(w,type,p,civ_id)
		"healer_plea":
			_goods_out(w,"Fiber Plants",float(p.get("herbs",0)),civ_id,"for poultices")
			var healers:=int(p.get("healers",2))
			_hands_out(w,healers,HEAL_DAYS,civ_id,0.0,"%d healers away for %d days" % [healers,HEAL_DAYS])
			var home:=DV.population("player")*SICK_LOSS*DV.day_of_work("player")
			w.us_give=float(w.us_give)+HEAL_RISK*home
			(w.risk as Array).append("about %d in 100 that the healers bring the sickness home (health 5 points lower, about %d of our work)" % [roundi(HEAL_RISK*100.0),roundi(home)])
			w.them_get=float(w.them_get)+pop_them*HEALED_GAIN*DV.day_of_work(civ_id)
			_pay(w,type,p,civ_id)
		"war_supplies":
			_goods_out(w,String(p.get("res","Timber")),float(p.get("amount",0)),civ_id,"for spears and palisades")
			w.them_get=float(w.them_get)*1.5
			(w.risk as Array).append("%s counts you its enemy" % String(p.get("enemy_name","their enemy")))
			_pay(w,type,p,civ_id)
		"sacred_site":
			w.plea=true
			(w.give as Array).append("nothing from our stores: their people walk to the %s each spring" % String(p.get("place","place")))
		"rite_keeper":
			w.us_give=float(w.us_give)+DV.person("player")
			w.them_get=float(w.them_get)+DV.person(civ_id)*RITE_GAIN
			(w.give as Array).append("one of our people, gone to live among them for good (a year of a person's work, about %d)" % roundi(DV.person("player")))
			_pay(w,type,p,civ_id)
		"joint_hunt":
			var hunters:=int(p.get("hunters",0))
			var days:=int(p.get("days",20))
			_hands_out(w,hunters,days,civ_id,0.0,"%d hunters away for %d days" % [hunters,days])
			var dead:=DV.person("player")
			w.us_give=float(w.us_give)+HUNT_RISK*dead
			(w.risk as Array).append("about 1 in %d that a hunter is killed when the herd turns (a year of work, about %d)" % [roundi(1.0/HUNT_RISK),roundi(dead)])
			var meat:=float(p.get("meat",0))
			w.them_get=float(w.them_get)+DV.worth_in(civ_id,"Food",meat*0.5)
			if p.has("share_res"):
				_pay(w,type,p,civ_id)
				w.them_get=float(w.them_get)+DV.worth_in(civ_id,"Food",meat)
			else:
				w.us_get=float(w.us_get)+DV.worth_in("player","Food",meat)
				(w.get as Array).append("%d Food, our share of the meat: about %d to us (%s)" % [roundi(meat),roundi(DV.worth_in("player","Food",meat)),DV.depth_words("player","Food")])
		"safe_passage":
			var seasons:=int(p.get("seasons",8))
			(w.give as Array).append("nothing from our stores: a party of their %s crosses each season for %d seasons" % [String(p.get("carriers","carriers")),seasons])
			w.them_get=float(w.them_get)+float(seasons*PASSAGE_PARTY*PASSAGE_SAVED)*DV.day_of_work(civ_id)
			_pay(w,type,p,civ_id,float(seasons),"in all, %d at each of %d crossings" % [roundi(float(p.get("toll_amt",0))),seasons])
		"blessing_rite":
			(w.give as Array).append("the god's blessing: nothing from our stores")
			_pay(w,type,p,civ_id)
		_:
			return {}
	return w

static func _goods_out(w:Dictionary,res:String,qty:float,civ_id:String,why:String="")->void:
	if qty<=0.0: return
	var cost:=DV.worth_out("player",res,qty)
	w.us_give=float(w.us_give)+cost
	w.them_get=float(w.them_get)+DV.worth_in(civ_id,res,qty)
	(w.give as Array).append("%d %s%s, worth about %d to us (%s)" % [roundi(qty),res," "+why if why!="" else "",roundi(cost),DV.depth_words("player",res)])

static func _goods_in(w:Dictionary,res:String,qty:float,civ_id:String,odds:float=1.0,why:String="")->void:
	if qty<=0.0: return
	var worth:=DV.worth_in("player",res,qty)*odds
	w.us_get=float(w.us_get)+worth
	w.them_give=float(w.them_give)+DV.worth_out(civ_id,res,qty)
	(w.get as Array).append("%d %s%s, worth about %d to us (%s)" % [roundi(qty),res," "+why if why!="" else "",roundi(worth),DV.depth_words("player",res)])

static func _hands_out(w:Dictionary,n:int,days:int,civ_id:String,gain:float,words:String)->void:
	if n<=0: return
	var cost:=float(n*days)*DV.day_of_work("player")
	w.us_give=float(w.us_give)+cost
	w.them_get=float(w.them_get)+float(n*days)*DV.day_of_work(civ_id)*gain
	(w.give as Array).append("%s: about %d of our work" % [words,roundi(cost)])

static func _pay(w:Dictionary,type:String,p:Dictionary,civ_id:String,times:float=1.0,why:String="")->void:
	var fields:Array=PAY_FIELDS.get(type,[])
	if fields.is_empty() or not p.has(String(fields[0])): return
	_goods_in(w,String(p[fields[0]]),float(p.get(String(fields[1]),0))*times,civ_id,1.0,why)

## The deal's numbers kept on the request (rounded), with its fairness and
## the weight a refusal carries.
static func summarize(type:String,p:Dictionary,civ_id:String)->Dictionary:
	var w:=weigh(type,p,civ_id)
	if w.is_empty(): return {}
	var needed:=need(type,civ_id)
	var fair:=fairness(w,needed)
	var out:={"us_give":snappedf(float(w.us_give),0.1),"us_get":snappedf(float(w.us_get),0.1),"them_give":snappedf(float(w.them_give),0.1),"them_get":snappedf(float(w.them_get),0.1),
		"need":snappedf(needed,0.01),"fair":snappedf(fair,0.01),"scale":snappedf(scale_of(needed,fair),0.01),"plea":bool(w.plea),
		"give":"; ".join(PackedStringArray(w.give)).substr(0,220),"get":"; ".join(PackedStringArray(w.get)).substr(0,220),"risk":"; ".join(PackedStringArray(w.risk)).substr(0,200)}
	return out

## How fair the request is to us, for what a refusal costs: what we get
## against what we give; for a plea (nothing comes back), what it means to
## them against what it costs us; and a request that costs us nothing is as
## fair as a request can be.
static func fairness(w:Dictionary,needed:float)->float:
	var give:=float(w.get("us_give",0.0))
	var them:=float(w.get("them_get",0.0))
	if give<1.0: return 1.2
	var kind:=needed*them/(3.0*give)
	if bool(w.get("plea",false)) or float(w.get("us_get",0.0))<=0.0: return clampf(maxf(them/(2.0*give),kind),0.1,1.2)
	return clampf(maxf(float(w.us_get)/give,kind),0.1,1.2)

## The weight a refusal carries: how needed (0.35 for plain business, 1 for
## the desperate) times how fair.
static func scale_of(needed:float,fair:float)->float:
	return (0.35+0.65*clampf(needed,0.0,1.0))*clampf(fair,0.1,1.2)

## The request's deal, read from it (computed once and kept on the request;
## an older save's request is weighed when first read).
static func deal_of(audience:Dictionary)->Dictionary:
	var s:=Hall._situation(audience)
	var type:=String(s.get("type",""))
	if not (type in DEALS or type=="blessing_rite"): return {}
	var p:Dictionary=s.get("req",{}) if s.get("req") is Dictionary else {}
	if p.get("deal") is Dictionary: return p.deal
	var d:=summarize(type,p,String(audience.get("civ_id","")))
	if not d.is_empty() and s.get("req") is Dictionary: (s.req as Dictionary)["deal"]=d
	return d

# --------------------------------------------------------------------------
# Turning a request down
# --------------------------------------------------------------------------

## What turning the request down does, before it is done: {o, t, x, g, d,
## scale, soft} (regard, trust and tension as signed changes; a grudge's
## weight; dread).
static func refusal(audience:Dictionary,courteous:bool)->Dictionary:
	var type:=Hall._situation_type(audience)
	var base:Dictionary=REFUSAL.get(type,{})
	var d:=deal_of(audience)
	var s:=float(d.get("scale",1.0)) if not d.is_empty() else 1.0
	var civ_id:=String(audience.get("civ_id",""))
	var weight:=s*COURTEOUS if courteous else maxf(s,BLUNT_FLOOR)
	var out:={"scale":snappedf(s,0.01),"weight":weight,"soft":weight<SOFT}
	out["o"]=-float(base.get("o",0.02))*weight
	out["t"]=-float(base.get("t",0.0))*weight
	var x:=float(base.get("x",0.0))
	if type=="food_loan" and float(Hall._personality(civ_id).assertiveness)>0.55: x=0.06
	out["x"]=0.0 if courteous else x*weight
	var g:=float(base.get("g",0.0))*weight
	out["g"]=g if g>=0.1 and not bool(out.soft) else 0.0
	out["d"]=0.0 if courteous else float(base.get("d",0.0))
	return out

## Plain words for a refusal's cost: "their regard falls about 1 point (of
## 100); no grudge".
static func refusal_words(r:Dictionary)->String:
	var parts:=PackedStringArray()
	var o:=roundi(-float(r.get("o",0.0))*100.0)
	parts.append("their regard of you falls about %d point%s (of 100)" % [o,"" if o==1 else "s"] if o>0 else "their regard of you hardly moves")
	var t:=roundi(-float(r.get("t",0.0))*100.0)
	if t>0: parts.append("their ruler trusts you %d point%s less" % [t,"" if t==1 else "s"])
	var x:=roundi(float(r.get("x",0.0))*100.0)
	if x>0: parts.append("the border grows %d point%s tenser" % [x,"" if x==1 else "s"])
	parts.append("they keep a grudge" if float(r.get("g",0.0))>0.0 else "no grudge")
	if float(r.get("d",0.0))>0.0: parts.append("and they fear you a little more")
	return ", ".join(parts)

## Why a refusal weighs what it does, in a few words.
static func refusal_reason(audience:Dictionary)->String:
	var d:=deal_of(audience)
	if d.is_empty(): return ""
	var fair:=float(d.get("fair",1.0))
	var needed:=float(d.get("need",0.0))
	var why:=""
	if fair<0.5: why="the deal was poor for us, and they know it"
	elif fair>=1.0 and needed>=0.6: why="it was a fair ask from a people in real need"
	elif fair>=1.0: why="it was a fair ask"
	else: why="the deal was thin for us"
	return why

# --------------------------------------------------------------------------
# Counters
# --------------------------------------------------------------------------

## Goods their workers can gather from our land (work_for_food).
const GATHERED:=["Timber","Stone","Clay","Fiber Plants"]
## What one of their workers gathers from our land in a day, in rations'
## worth (envoy_requests work_for_food: 0.12 a worker-day), and the most a
## good season gives over that (the request's own dice reach 1.2).
const GATHER_RATE:=0.12
const GATHER_MOST:=1.2

## The most their workers can gather of `res` in the days they stay (half
## again as long for "a third month"): workers x days x GATHER_RATE x
## GATHER_MOST, in units of the good. A counter past it is no counter: they
## cannot bring in what their hands cannot gather.
static func gather_cap(p:Dictionary,res:String,more:bool)->float:
	var days:=float(p.get("days",60))*(MORE if more else 1.0)
	var worth:=float(p.get("workers",0))*days*GATHER_RATE*GATHER_MOST*DV.price("player","Food")
	var first:=float(p.get("amount",0.0))*DV.price("player",String(p.get("res",res)))*(MORE if more else 1.0)
	return maxf(worth,first)/maxf(0.01,DV.price("player",res))
## A counter may take at most this share of their stock of a good.
const COUNTER_SHARE:=0.5

## The terms of one counter, by the same rules for the card and for the
## god's own words: `res` the good asked ("" for the payment's own good),
## `amt` the amount asked (0 for the rule's own: the same cost to them in
## another good; half again for more). {id, res, amt, worth (to us), was
## (the first terms' worth to us), over (how far past the first terms, or
## past what the business is worth to them, it reaches)}; {} when it cannot
## be asked: a good we cannot use or they cannot spare.
static func terms(type:String,p:Dictionary,civ_id:String,d:Dictionary,option_id:String,res:String,amt:float)->Dictionary:
	var fields:Array=PAY_FIELDS.get(type,[])
	if fields.is_empty() or not p.has(String(fields[0])) or not DV.simulated(civ_id): return {}
	var first:=String(p[fields[0]])
	var first_amt:=float(p.get(String(fields[1]),0.0))
	if first_amt<=0.0: return {}
	if res=="": res=first
	if not res in DV.GOODS or not DV.usable("player",res): return {}
	if option_id=="counter_good" and res==first: return {}
	var times:=float(p.get("seasons",1)) if type=="safe_passage" else 1.0
	var was:=DV.worth_in("player",first,first_amt*times)
	var gain:=maxf(1.0,float(d.get("them_get",0.0)))
	var q:=amt
	var over:=0.0
	if type=="work_for_food":
		# Their hands gather it from our land: the same labour, another yield.
		if not res in GATHERED: return {}
		var labour:=first_amt*DV.price("player",first)
		if q<=0.0: q=labour*(MORE if option_id=="counter_more" else 1.0)/DV.price("player",res)
		q=Hall._nice(q)
		if q>Hall._nice(gather_cap(p,res,option_id=="counter_more"))+0.5: return {}
		var extra:=q*DV.price("player",res)/maxf(0.01,labour)-1.0
		over=maxf(0.0,extra)+(0.15 if option_id=="counter_more" else 0.0)
	else:
		var theirs:=DV.reading(civ_id,res)
		var cost_first:=DV.out_reading(DV.reading(civ_id,first),first_amt*times)
		var cap:=float(theirs.h)*COUNTER_SHARE
		if q<=0.0:
			if option_id=="counter_more": q=first_amt*MORE if res==first else DV.qty_for_cost(theirs,cost_first*MORE,cap)/times
			else: q=DV.qty_for_cost(theirs,cost_first,cap)/times
		q=Hall._nice(q)
		if q<1.0 or q*times>cap+0.5: return {}
		var cost:=DV.out_reading(theirs,q*times)
		# Past the first terms; and harder still once it costs them more than
		# the business is worth to them.
		over=maxf(0.0,(cost-cost_first)/maxf(1.0,cost_first))*0.25+maxf(0.0,(cost-gain)/gain)
		if option_id=="counter_more": over+=0.15
	if q<1.0: return {}
	return {"id":option_id,"res":res,"amt":q,"worth":snappedf(DV.worth_in("player",res,q*times),0.1),"was":snappedf(was,0.1),"over":snappedf(over,0.01)}

## The counters open on this request, built when the envoy arrives from what
## they hold and what we lack: the good worth most to us at the same cost to
## them (only when it is worth a quarter more to us), and half again as much.
static func build_counters(type:String,p:Dictionary,civ_id:String,d:Dictionary)->Array:
	var out:Array=[]
	if type in COUNTER_GOOD:
		var best:={}
		for good:String in DV.GOODS:
			var t:=terms(type,p,civ_id,d,"counter_good",good,0.0)
			if t.is_empty() or float(t.worth)<float(t.was)*1.25 or float(t.over)>0.1: continue
			if best.is_empty() or float(t.worth)>float(best.worth): best=t
		if not best.is_empty(): out.append(best)
	if type in COUNTER_MORE:
		var more:=terms(type,p,civ_id,d,"counter_more","",0.0)
		if not more.is_empty(): out.append(more)
	return out

## A counter asked of this audience (the card's terms, or the god's words).
static func counter_terms(audience:Dictionary,option_id:String,res:String,amt:float)->Dictionary:
	var s:=Hall._situation(audience)
	var p:Dictionary=s.get("req",{}) if s.get("req") is Dictionary else {}
	return terms(String(s.get("type","")),p,String(audience.get("civ_id","")),deal_of(audience),option_id,res,amt)

## Odds their ruler agrees to harder terms: warm, trusting and needy peoples
## bend; proud and assertive ones walk away; the further past what the
## business is worth to them, the less likely. 0.1 to 0.9.
static func odds(audience:Dictionary,over:float)->float:
	var civ_id:=String(audience.get("civ_id",""))
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var p:=Hall._personality(civ_id)
	var opinion:=float((civ.get("player_relation",{}) as Dictionary).get("opinion",0.0))
	var trust:=float(ForeignDiplomacy.leader(civ_id).get("trust",0.0))
	var d:=deal_of(audience)
	var needed:=float(d.get("need",0.0)) if not d.is_empty() else (0.6 if Hall._hungry(civ) else 0.0)
	var chance:=0.45+opinion*0.3+trust*0.15-(float(p.assertiveness)-0.5)*0.5+needed*0.25-over*0.4
	return clampf(chance,0.1,0.9)

## The seeded roll for one counter or bargain on one audience.
static func agrees(audience:Dictionary,option_id:String,chance:float)->bool:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:counter:%s:%s" % [int(GameState.world_seed),String(audience.get("id","")),option_id])
	return rng.randf()<chance

static func odds_words(chance:float)->String:
	return "about %d in 10 that they agree" % clampi(roundi(chance*10.0),1,9)

# --------------------------------------------------------------------------
# The deal block (proposal_stakes rows) above the answers
# --------------------------------------------------------------------------

static func balance_words(d:Dictionary)->Dictionary:
	var give:=float(d.get("us_give",0.0))
	var get:=float(d.get("us_get",0.0))
	if bool(d.get("plea",false)) or get<=0.0:
		if give<1.0: return {"text":"Nothing leaves our stores; they ask it as a favour.","tone":"odds"}
		return {"text":"They ask it as help: nothing comes back to us but their goodwill.","tone":"cost"}
	if give<1.0: return {"text":"Good for us: it costs us nothing we can count.","tone":"gain"}
	var ratio:=get/give
	if ratio<0.67: return {"text":"Poor for us: we give about %s what we get." % _times(1.0/ratio),"tone":"cost"}
	if ratio>1.5: return {"text":"Good for us: we get about %s what we give." % _times(ratio),"tone":"gain"}
	return {"text":"About even for us.","tone":"odds"}

static func _times(r:float)->String:
	if r>=1.75: return "%d times" % roundi(r)
	return "half again"

## The deal block's stakes ({kind, title, rows, refusal}) for an envoy's request.
static func stakes(audience:Dictionary)->Dictionary:
	var d:=deal_of(audience)
	if d.is_empty(): return {}
	var rows:Array=[]
	# The balance first: the folded block shows only its first line.
	var b:=balance_words(d)
	rows.append({"key":"The balance","text":"We give about %d and get about %d, in rations' worth to us. %s" % [roundi(float(d.us_give)),roundi(float(d.us_get)),String(b.text)],"tone":String(b.tone)})
	if String(d.get("give",""))!="": rows.append({"key":"We give","text":Hall._cap_first(String(d.give))+".","tone":"cost"})
	if String(d.get("risk",""))!="": rows.append({"key":"We risk","text":Hall._cap_first(String(d.risk))+".","tone":"cost"})
	if String(d.get("get",""))!="": rows.append({"key":"We get","text":Hall._cap_first(String(d.get))+".","tone":"gain"})
	var them:="They give about %d of theirs and get about %d, as they count it." % [roundi(float(d.them_give)),roundi(float(d.them_get))] if float(d.them_give)>=1.0 else "They give nothing from their stores and get about %d, as they count it." % roundi(float(d.them_get))
	rows.append({"key":"Their side","text":them+" Their need: %s." % _need_words(float(d.get("need",0.0))),"tone":"odds"})
	var r:=refusal(audience,true)
	return {"kind":"deal","title":"THE DEAL, AS EACH SIDE COUNTS IT","rows":rows,"refusal_key":"If you decline","refusal":"Declined courteously, %s; %s." % [refusal_words(r),refusal_reason(audience)],
		"short":String(b.text)}

static func _need_words(n:float)->String:
	if n>=0.75: return "desperate"
	if n>=0.5: return "great"
	if n>=0.3: return "real"
	return "plain business"
