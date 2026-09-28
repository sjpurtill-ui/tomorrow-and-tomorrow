extends RefCounted
## ONE LEDGER OF A TOWN'S PEOPLE (docs/ADJUDICATION.md: one state).
##
## Every town we take gets one ledger, kept on the town's own region record so
## it outlives the garrison: who lives there now by group (men, women,
## children, elders) and by what we have done with them (free, bound, hostage,
## worker, conscript), the people who ran and have not yet reached their
## refuge, and where the rest went (killed, fled and to where, taken to our
## home, scattered when the town burned). Captives on the road and people
## arrived among us are read from occupation_transfers (the travel record),
## never counted twice. Every system reads and writes this one ledger:
## town_fate (kill, captives, move, burn), occupation_measures (bind,
## hostages, labour, conscript, release), pursuit (the people who ran), the
## held-town report and the ruin account, the map, court_facts and the order
## reader's brief.
##
## The ledger always adds up to the world's own count for the town:
##   region.population == present + running + pending
## where pending is people the ledger already removed (dead, taken, scattered)
## that the world's count does not show yet (the multi-actor simulation
## brings its town counts over at the next day's sync). Growth or loss from
## anything else lands on the free people (joined / lost). check() tests the
## identity; snapshot() and balance() let tests prove that before, plus or
## minus the reported changes, equals after.
## Static helpers; preload.

const GROUPS:=["men","women","children","elders"]
const PRESENT:=["free","bound","hostage","worker","conscript"]
const GONE:=["killed","fled","taken","displaced"]
## A farming village's people (town_fate.gd: men 0.24; women and children 0.55).
const SHARES:={"men":0.24,"women":0.24,"children":0.31,"elders":0.21}
const VERSION:=1
## People removed here but not yet off the world's count wait at most this long.
const PENDING_DAYS:=3
## Plain words for each group, and for one of them.
const GROUP_WORDS:={"men":"men","women":"women","children":"children","elders":"old people"}
const STATUS_WORDS:={"free":"free in their houses","bound":"bound under our guard","hostage":"held as hostages","worker":"at forced labour","conscript":"serving with our garrison"}

static func _world()->Variant: return WorldSimulation.world
static func _day()->int: return int(WorldSimulation.state.elapsed_days) if WorldSimulation.state!=null else 0

## The town's region record, live (edits land in the world). {} when unknown.
static func region_ref(civ_id:String,region_id:String)->Dictionary:
	var world:Variant=_world()
	if world==null: return {}
	var index:int=world._civilization_index(civ_id)
	if index<0: return {}
	var civ:Dictionary=world.civilizations[index]
	var ri:int=world._region_index(civ,region_id)
	if ri<0: return {}
	return civ.strategic_regions[ri]

## The town's ledger, reconciled to the world's count; made from the town's
## people when first needed. {} when there is no such town.
static func of(civ_id:String,region_id:String,create:bool=true)->Dictionary:
	var r:=region_ref(civ_id,region_id)
	if r.is_empty(): return {}
	var l:Variant=r.get("ledger")
	if not l is Dictionary or (l as Dictionary).is_empty():
		if not create: return {}
		l=_fresh(r,civ_id,region_id)
		r["ledger"]=l
		_adopt_old_records(civ_id,region_id,l)
	_reconcile(l,r)
	return l

## Does this town have a ledger at all (have we ever held it)?
static func has(civ_id:String,region_id:String)->bool:
	var r:=region_ref(civ_id,region_id)
	return not r.is_empty() and r.get("ledger") is Dictionary and not (r.get("ledger") as Dictionary).is_empty()

static func _groups(n:int=0)->Dictionary:
	var out:={}
	for g in GROUPS: out[g]=n
	return out

static func _fresh(r:Dictionary,civ_id:String,region_id:String)->Dictionary:
	var present:={}
	for status in PRESENT: present[status]=_groups()
	var start:=maxi(0,roundi(float(r.get("population",0.0))))
	present.free=split(start,SHARES)
	var gone:={}
	for bucket in GONE: gone[bucket]=_groups()
	return {"v":VERSION,"civ_id":civ_id,"region_id":region_id,"name":String(r.get("name","")),"since":_day(),"start":start,"joined":0,"lost":0,
		"present":present,"running":{},"gone":gone,"fled_to":{},"freed":0,"released":0,"pending":0,"pending_day":-1,"ruin":{}}

## n people split by shares, the rounding remainder to the largest parts.
static func split(n:int,shares:Dictionary)->Dictionary:
	var out:=_groups()
	if n<=0: return out
	var total:=0.0
	for g in GROUPS: total+=maxf(0.0,float(shares.get(g,0.0)))
	if total<=0.0: out.men=n; return out
	var given:=0
	var rests:Array=[]
	for g in GROUPS:
		var exact:=float(n)*maxf(0.0,float(shares.get(g,0.0)))/total
		out[g]=floori(exact); given+=int(out[g])
		rests.append([exact-floorf(exact),g])
	rests.sort_custom(func(a:Array,b:Array)->bool: return float(a[0])>float(b[0]))
	var i:=0
	while given<n:
		var g:=String(rests[i%rests.size()][1])
		if float(shares.get(g,0.0))>0.0 or i>=rests.size()*2:
			out[g]=int(out[g])+1
			given+=1
		i+=1
	return out

## A garrison's older records (before this ledger) become the ledger's.
static func _adopt_old_records(civ_id:String,region_id:String,l:Dictionary)->void:
	var mc:Variant=WorldSimulation.military
	if mc==null: return
	var at:int=mc._occupation_force_index(civ_id,region_id)
	if at<0: return
	var force:Dictionary=mc.occupation_forces[at]
	var measures:Variant=force.get("measures",[])
	if measures is Array:
		for m in measures:
			if not m is Dictionary or bool((m as Dictionary).get("ended",false)): continue
			var id:=String(m.get("id",""))
			if not id in ["bind_men","hostages","conscript","labour"] or not (m as Dictionary).has("count"): continue
			var n:=int(m.get("count",0))
			match id:
				"bind_men": move(l,"free","bound","men",n)
				"hostages": move_any(l,"free","hostage",n,["elders","women","children","men"])
				"conscript": move(l,"free","conscript","men",n)
				"labour": move(l,"bound" if count(l,"bound","men")>=n else "free","worker","men",n)
			(m as Dictionary).erase("count")
	var fled:Variant=force.get("fled")
	if fled is Dictionary and String((fled as Dictionary).get("state",""))=="running":
		run(l,"free","men",int(fled.get("count",0)),{"name":String(fled.get("toward","")),"region_id":String(fled.get("toward_id","")),"hills":bool(fled.get("hills",false)),"position":fled.get("toward_position",{})},int(fled.get("day",_day())))
	force.erase("fled")
	var fate:Variant=force.get("fate")
	if fate is Dictionary:
		(l.gone.killed as Dictionary)["men"]=int(l.gone.killed.men)+int(fate.get("killed",0))
		var taken:=split(int(fate.get("captives",0)),{"women":0.45,"children":0.55})
		for g in GROUPS: (l.gone.taken as Dictionary)[g]=int(l.gone.taken[g])+int(taken[g])
		# The ledger counts people now; the old record keeps only the tribute.
		for key in ["killed","captives","moved"]: (fate as Dictionary).erase(key)

# --------------------------------------------------------------------------
# Counting
# --------------------------------------------------------------------------

static func count(l:Dictionary,status:String,group:String="")->int:
	var row:Dictionary=(l.get("present",{}) as Dictionary).get(status,{})
	if group!="": return int(row.get(group,0))
	var n:=0
	for g in GROUPS: n+=int(row.get(g,0))
	return n

static func gone(l:Dictionary,bucket:String,group:String="")->int:
	var row:Dictionary=(l.get("gone",{}) as Dictionary).get(bucket,{})
	if group!="": return int(row.get(group,0))
	var n:=0
	for g in GROUPS: n+=int(row.get(g,0))
	return n

## Everyone still in the town, whatever we have done with them.
static func present_total(l:Dictionary)->int:
	var n:=0
	for status in PRESENT: n+=count(l,status)
	return n

## Everyone of one group still in the town, whatever their status.
static func here(l:Dictionary,group:String)->int:
	var n:=0
	for status in PRESENT: n+=count(l,status,group)
	return n

## The people who ran and have not reached their refuge yet ({} when none).
static func running(l:Dictionary)->Dictionary:
	var r:Variant=l.get("running",{})
	return r if r is Dictionary and int((r as Dictionary).get("count",0))>0 else {}

## The last flight from the town, over or not: {count (still running), ran,
## caught, reached, groups, day, toward, toward_id, toward_position, hills,
## state ("running" | "chased" | "gone" | "caught")}. {} when nobody ran.
static func last_flight(l:Dictionary)->Dictionary:
	var r:Variant=l.get("running",{})
	return r if r is Dictionary and not (r as Dictionary).is_empty() else {}

static func running_total(l:Dictionary)->int:
	return int(running(l).get("count",0))

## The men of the town held by our garrison (bound, at forced labour, serving).
static func held_men(l:Dictionary)->int:
	return count(l,"bound","men")+count(l,"worker","men")+count(l,"conscript","men")

## Everyone the garrison holds under guard, of the given groups.
static func held(l:Dictionary,groups:Array=GROUPS)->int:
	var n:=0
	for g in groups:
		for status in ["bound","hostage","worker","conscript"]: n+=count(l,status,String(g))
	return n

## Everyone the ledger has ever counted: here, running and gone.
static func accounted(l:Dictionary)->int:
	var n:=present_total(l)+running_total(l)
	for bucket in GONE: n+=gone(l,bucket)
	return n

# --------------------------------------------------------------------------
# Moving people between statuses (no one enters or leaves the town)
# --------------------------------------------------------------------------

## Up to n of one group from one status to another. Returns how many moved.
static func move(l:Dictionary,from:String,to:String,group:String,n:int)->int:
	if n<=0 or from==to: return 0
	var src:Dictionary=l.present[from]
	var dst:Dictionary=l.present[to]
	var moved:=mini(n,int(src.get(group,0)))
	if moved<=0: return 0
	src[group]=int(src[group])-moved
	dst[group]=int(dst.get(group,0))+moved
	return moved

## Up to n people from one status to another, taking groups in the order given.
## Returns {group: moved}.
static func move_any(l:Dictionary,from:String,to:String,n:int,order:Array=GROUPS)->Dictionary:
	var out:={}
	var left:=n
	for g in order:
		if left<=0: break
		var moved:=move(l,from,to,String(g),left)
		if moved>0: out[String(g)]=moved; left-=moved
	return out

## Take n people of the given groups from the given statuses, in order, out of
## the town into a gone bucket. The world's own count is the caller's to
## change (deaths, a transfer, a displacement); pending bridges the day.
## plan: [[status, group], ...]. Returns {"status/group": n, group: n, "total": n}.
static func remove(l:Dictionary,plan:Array,n:int,bucket:String)->Dictionary:
	var out:={"total":0}
	var left:=n
	for step in plan:
		if left<=0: break
		var status:=String(step[0]); var group:=String(step[1])
		var row:Dictionary=l.present[status]
		var took:=mini(left,int(row.get(group,0)))
		if took<=0: continue
		row[group]=int(row[group])-took
		(l.gone[bucket] as Dictionary)[group]=int(l.gone[bucket].get(group,0))+took
		out["%s/%s" % [status,group]]=int(out.get("%s/%s" % [status,group],0))+took
		out[group]=int(out.get(group,0))+took
		out.total=int(out.total)+took
		left-=took
	_pending(l,int(out.total))
	return out

static func _pending(l:Dictionary,n:int)->void:
	if n<=0: return
	l["pending"]=int(l.get("pending",0))+n
	l["pending_day"]=_day()

## Everyone of a status, every group, in removal order for remove().
static func plan_of(statuses:Array,groups:Array=GROUPS)->Array:
	var out:Array=[]
	for s in statuses:
		for g in groups: out.append([String(s),String(g)])
	return out

## Where the people of a town went, noted with the number: fled_to[where] += n.
static func went_to(l:Dictionary,where:String,n:int)->void:
	if n<=0: return
	var key:=where if where!="" else "the hills"
	(l.fled_to as Dictionary)[key]=int((l.fled_to as Dictionary).get(key,0))+n

# --------------------------------------------------------------------------
# The people who ran
# --------------------------------------------------------------------------

static func _rec_groups(rec:Dictionary)->Dictionary:
	var g:Variant=rec.get("groups")
	if g is Dictionary: return g
	var made:=_groups()
	made[String(rec.get("group","men"))]=int(rec.get("count",0))
	rec["groups"]=made
	return made

## Take n out of a running record, spread over its groups. {group: n}.
static func _take_running(rec:Dictionary,n:int)->Dictionary:
	var groups:=_rec_groups(rec)
	var take:=mini(n,int(rec.get("count",0)))
	var out:=_groups()
	if take<=0: return out
	var weights:={}
	for g in GROUPS: weights[g]=float(groups.get(g,0))
	var cut:=split(take,weights)
	var done:=0
	for g in GROUPS:
		var c:=mini(int(cut[g]),int(groups.get(g,0)))
		groups[g]=int(groups.get(g,0))-c; out[g]=c; done+=c
	for g in GROUPS:
		if done>=take: break
		var c:=mini(take-done,int(groups.get(g,0)))
		groups[g]=int(groups.get(g,0))-c; out[g]=int(out[g])+c; done+=c
	rec["count"]=maxi(0,int(rec.get("count",0))-done)
	return out

## n people of one group and status run for their refuge. They are still
## counted in the world's town until they get there (pursuit.gd). Returns the
## running record.
static func run(l:Dictionary,from:String,group:String,n:int,refuge:Dictionary,day:int)->Dictionary:
	var row:Dictionary=l.present[from]
	var ran:=mini(n,int(row.get(group,0)))
	if ran<=0: return running(l)
	row[group]=int(row[group])-ran
	var rec:Dictionary=running(l)
	if rec.is_empty():
		rec={"count":0,"groups":_groups(),"ran":0,"caught":0,"reached":0,"day":day,"toward":String(refuge.get("name","the hills")),"toward_id":String(refuge.get("region_id","")),
			"toward_position":(refuge.get("position",{}) as Dictionary).duplicate(true) if refuge.get("position") is Dictionary else {},"hills":bool(refuge.get("hills",false)),"state":"running"}
		l["running"]=rec
	var groups:=_rec_groups(rec)
	groups[group]=int(groups.get(group,0))+ran
	rec["count"]=int(rec.count)+ran
	rec["ran"]=int(rec.get("ran",0))+ran
	rec["day"]=day
	if String(rec.get("state",""))!="chased": rec["state"]="running"
	return rec

static func _flight_over(rec:Dictionary)->void:
	if int(rec.get("count",0))>0: return
	rec["state"]="gone" if int(rec.get("reached",0))>0 else "caught"

## Of the people who ran, n reach their refuge (the world moves them there).
## Returns {group: n, "total": n}.
static func reached_refuge(l:Dictionary,n:int)->Dictionary:
	var rec:=running(l)
	var out:={"total":0}
	if rec.is_empty() or n<=0: return out
	var took:=_take_running(rec,n)
	var total:=0
	for g in GROUPS:
		(l.gone.fled as Dictionary)[g]=int(l.gone.fled.get(g,0))+int(took[g])
		out[g]=int(took[g]); total+=int(took[g])
	went_to(l,"the hills" if bool(rec.get("hills",false)) else String(rec.get("toward","the hills")),total)
	rec["reached"]=int(rec.get("reached",0))+total
	out.total=total
	_pending(l,total)
	_flight_over(rec)
	return out

## The men among those running now (a chase goes after them only).
static func running_men(l:Dictionary)->int:
	var rec:=running(l)
	return int(_rec_groups(rec).get("men",0)) if not rec.is_empty() else 0

## Of the people who ran, n were caught and killed (the world's deaths are the
## caller's); group: only of that group. Returns how many.
static func caught(l:Dictionary,n:int,group:String="")->int:
	var rec:=running(l)
	if rec.is_empty() or n<=0: return 0
	var took:=_groups()
	if group!="":
		var groups:=_rec_groups(rec)
		var k:=mini(n,int(groups.get(group,0)))
		groups[group]=int(groups.get(group,0))-k
		rec["count"]=maxi(0,int(rec.get("count",0))-k)
		took[group]=k
	else:
		took=_take_running(rec,n)
	var dead:=0
	for g in GROUPS:
		(l.gone.killed as Dictionary)[g]=int(l.gone.killed.get(g,0))+int(took[g])
		dead+=int(took[g])
	rec["caught"]=int(rec.get("caught",0))+dead
	_pending(l,dead)
	_flight_over(rec)
	return dead

## n of a status leave for their people at once (deserters, a gang that slips
## off): the world moves them (Pursuit._reach_refuge). Returns how many.
static func fled_now(l:Dictionary,from:String,group:String,n:int,where:String)->int:
	var row:Dictionary=l.present[from]
	var ran:=mini(n,int(row.get(group,0)))
	if ran<=0: return 0
	row[group]=int(row[group])-ran
	(l.gone.fled as Dictionary)[group]=int(l.gone.fled.get(group,0))+ran
	went_to(l,where,ran)
	_pending(l,ran)
	return ran

# --------------------------------------------------------------------------
# Keeping the ledger true to the world's count
# --------------------------------------------------------------------------

static func _reconcile(l:Dictionary,r:Dictionary)->void:
	var pop:=maxi(0,roundi(float(r.get("population",0.0))))
	# People we removed that the world's count shows at last: pending is spent.
	var pending:=int(l.get("pending",0))
	if pending>0 and _day()-int(l.get("pending_day",-1))>PENDING_DAYS: l["pending"]=0; pending=0
	var diff:=pop-(present_total(l)+running_total(l)+pending)
	if diff<0 and pending>0:
		var spent:=mini(pending,-diff)
		l["pending"]=pending-spent; diff+=spent
	if diff>0:
		# Born, returned or counted since: free people, in the town's own mix.
		var mix:=l.present.free as Dictionary
		var weights:={}
		var any:=false
		for g in GROUPS:
			weights[g]=float(mix.get(g,0))
			if int(mix.get(g,0))>0: any=true
		var add:=split(diff,weights if any else SHARES)
		for g in GROUPS: mix[g]=int(mix.get(g,0))+int(add[g])
		l["joined"]=int(l.get("joined",0))+diff
	elif diff<0:
		# Dead or gone by other hands: from the free first, then those who ran,
		# then those we hold.
		var need:=-diff
		need-=_shrink(l.present.free as Dictionary,need)
		if need>0:
			var rec:=running(l)
			if not rec.is_empty():
				var cut:=_take_running(rec,need)
				for g in GROUPS: need-=int(cut[g])
				_flight_over(rec)
		for status in ["worker","conscript","hostage","bound"]:
			if need<=0: break
			need-=_shrink(l.present[status] as Dictionary,need)
		l["lost"]=int(l.get("lost",0))+(-diff-maxi(0,need))

## Remove up to n from a group row in proportion. Returns how many.
static func _shrink(row:Dictionary,n:int)->int:
	var total:=0
	for g in GROUPS: total+=int(row.get(g,0))
	if total<=0 or n<=0: return 0
	var take:=mini(n,total)
	var weights:={}
	for g in GROUPS: weights[g]=float(row.get(g,0))
	var cut:=split(take,weights)
	var done:=0
	for g in GROUPS:
		var c:=mini(int(cut[g]),int(row.get(g,0)))
		row[g]=int(row.get(g,0))-c; done+=c
	# Rounding left some over: take it from whoever is left.
	for g in GROUPS:
		if done>=take: break
		var c:=mini(take-done,int(row.get(g,0)))
		row[g]=int(row.get(g,0))-c; done+=c
	return done

## Does the ledger add up to the world's count? {ok, population, present,
## running, pending, diff, negative, accounted}. A test helper as much as a
## guard: every count is a whole number of people, none below zero, and
## start + joined - lost == everyone here, running and gone.
static func check(civ_id:String,region_id:String)->Dictionary:
	var r:=region_ref(civ_id,region_id)
	if r.is_empty() or not r.get("ledger") is Dictionary: return {"ok":false,"why":"no ledger"}
	var l:Dictionary=r.ledger
	var pop:=maxi(0,roundi(float(r.get("population",0.0))))
	var present:=present_total(l)
	var ran:=running_total(l)
	var pending:=int(l.get("pending",0))
	var negative:=false
	for status in PRESENT:
		for g in GROUPS:
			if int(l.present[status].get(g,0))<0: negative=true
	for bucket in GONE:
		for g in GROUPS:
			if int(l.gone[bucket].get(g,0))<0: negative=true
	var rec:=last_flight(l)
	if not rec.is_empty():
		var sum:=0
		for g in GROUPS: sum+=int(_rec_groups(rec).get(g,0))
		if sum!=int(rec.get("count",0)) or int(rec.get("count",0))<0: negative=true
	var diff:=pop-(present+ran+pending)
	var books:=int(l.get("start",0))+int(l.get("joined",0))-int(l.get("lost",0))-accounted(l)
	return {"ok":diff==0 and not negative and books==0,"population":pop,"present":present,"running":ran,"pending":pending,"diff":diff,"negative":negative,"books":books,"accounted":accounted(l)}

## A copy of the ledger with the world's count, for before/after tests.
static func snapshot(civ_id:String,region_id:String)->Dictionary:
	var l:=of(civ_id,region_id)
	var r:=region_ref(civ_id,region_id)
	var out:=l.duplicate(true)
	out["population"]=maxi(0,roundi(float(r.get("population",0.0))))
	out["transfers"]=_transfer_counts(region_id)
	return out

## What changed between two snapshots, and whether it adds up: the people in
## the town before (here and running) = the people after + everyone who left
## (killed, reached refuge, taken home, scattered) - newcomers + other losses.
static func balance(before:Dictionary,after:Dictionary)->Dictionary:
	var out:={"killed":gone(after,"killed")-gone(before,"killed"),"fled":gone(after,"fled")-gone(before,"fled"),"taken":gone(after,"taken")-gone(before,"taken"),"displaced":gone(after,"displaced")-gone(before,"displaced")}
	var in_before:=present_total(before)+running_total(before)
	var in_after:=present_total(after)+running_total(after)
	out["in_before"]=in_before; out["in_after"]=in_after
	var left:=int(out.killed)+int(out.fled)+int(out.taken)+int(out.displaced)
	var joined:=int(after.get("joined",0))-int(before.get("joined",0))
	var lost:=int(after.get("lost",0))-int(before.get("lost",0))
	out["left"]=left; out["joined"]=joined; out["lost"]=lost
	out["ok"]=in_before-in_after==left+lost-joined
	return out

# --------------------------------------------------------------------------
# Odds, in plain words
# --------------------------------------------------------------------------

## "about 1 in 4", "about 7 in 10", "nearly certain", "almost none".
static func chance_words(p:float)->String:
	if p>=0.97: return "nearly certain"
	if p<=0.03: return "almost no chance"
	if p>=0.5: return "about %d in 10" % clampi(roundi(p*10.0),5,9)
	return "about 1 in %d" % clampi(roundi(1.0/p),2,30)

## A seeded roll for a town's ledger: reproducible from the save.
static func rng(region_id:String,day:int,salt:String)->RandomNumberGenerator:
	var r:=RandomNumberGenerator.new()
	r.seed=hash("ledger|%d|%s|%d|%s" % [int(GameState.world_seed),region_id,day,salt])
	return r

## How many of n succeed, each with chance p (the roll is seeded).
static func roll(r:RandomNumberGenerator,n:int,p:float)->int:
	var hits:=0
	for i in maxi(0,n):
		if r.randf()<p: hits+=1
	return hits

# --------------------------------------------------------------------------
# What the report, the map and the court read
# --------------------------------------------------------------------------

## People taken home from this town, from the travel record itself:
## {on_road, arrived, days (the longest road left), by_status:{status:{on_road, arrived}}}.
static func _transfer_counts(region_id:String)->Dictionary:
	var out:={"on_road":0,"arrived":0,"days":0,"by_status":{}}
	var mc:Variant=WorldSimulation.military
	if mc==null: return out
	var data:Dictionary=mc.occupation_transfers.data
	for t in data.get("transfers",[]):
		if not t is Dictionary or String((t as Dictionary).get("region",""))!=region_id: continue
		var n:=int(t.get("people",0))
		out.on_road=int(out.on_road)+n
		out.days=maxi(int(out.days),ceili(maxf(0.0,float(t.get("distance",0.0))-float(t.get("traveled",0.0)))/12.0))
		var row:Dictionary=(out.by_status as Dictionary).get(String(t.get("status","")),{"on_road":0,"arrived":0})
		row.on_road=int(row.on_road)+n
		out.by_status[String(t.get("status",""))]=row
	var total:=float(WorldSimulation.state.population_exact) if float(WorldSimulation.state.population_exact)>0.0 else float(WorldSimulation.state.population_total)
	for g in data.get("groups",[]):
		if not g is Dictionary or String((g as Dictionary).get("origin_region",""))!=region_id: continue
		var n:=roundi(float(g.get("share",0.0))*total)
		out.arrived=int(out.arrived)+n
		var row:Dictionary=(out.by_status as Dictionary).get(String(g.get("status","")),{"on_road":0,"arrived":0})
		row.arrived=int(row.arrived)+n
		out.by_status[String(g.get("status",""))]=row
	return out

## Everything the ledger knows of a town, flat, for reports, the map card,
## court_facts and the order reader. {} when the town has no ledger.
static func counts(civ_id:String,region_id:String)->Dictionary:
	if not has(civ_id,region_id): return {}
	var l:=of(civ_id,region_id)
	var r:=region_ref(civ_id,region_id)
	var out:={"name":String(r.get("name",l.get("name",""))),"population":maxi(0,roundi(float(r.get("population",0.0)))),"start":int(l.get("start",0)),"since":int(l.get("since",-1)),
		"joined":int(l.get("joined",0)),"lost":int(l.get("lost",0))}
	for status in PRESENT:
		out[status]=count(l,status)
		for g in GROUPS: out["%s_%s" % [status,g]]=count(l,status,g)
	for bucket in GONE:
		out[bucket]=gone(l,bucket)
		for g in GROUPS: out["%s_%s" % [bucket,g]]=gone(l,bucket,g)
	out["here"]=present_total(l)
	for g in GROUPS: out["here_"+g]=here(l,g)
	var rec:=running(l)
	out["running"]=int(rec.get("count",0)); out["running_toward"]=String(rec.get("toward",""))
	out["flight"]=last_flight(l).duplicate(true)
	out["fled_to"]=(l.get("fled_to",{}) as Dictionary).duplicate()
	out["freed"]=int(l.get("freed",0)); out["released"]=int(l.get("released",0))
	var t:=_transfer_counts(region_id)
	out["on_road"]=int(t.on_road); out["arrived"]=int(t.arrived); out["road_days"]=int(t.days); out["transfers"]=t.by_status
	out["died_on_road"]=maxi(0,gone(l,"taken")-int(t.on_road)-int(t.arrived))
	out["ruin"]=(l.get("ruin",{}) as Dictionary).duplicate(true)
	out["pending"]=int(l.get("pending",0))
	return out

## Our ruin record for a town while our own account is the last word on it
## (we burned it, and nobody has told us it is lived in again). {} otherwise.
## {civ_id, region_id, name, ruin (a copy), garrison}.
static func our_ruin(city_id:String)->Dictionary:
	var world:Variant=_world()
	if world==null or city_id.is_empty(): return {}
	var location:Dictionary=world._region_location(city_id)
	if location.is_empty(): return {}
	var civ:Dictionary=world.civilizations[int(location.owner_index)]
	var region:Dictionary=civ.strategic_regions[int(location.region_index)]
	var l:Variant=region.get("ledger")
	if not l is Dictionary: return {}
	var ruin:Variant=(l as Dictionary).get("ruin")
	if not ruin is Dictionary or (ruin as Dictionary).is_empty(): return {}
	var rs:Variant=(ruin as Dictionary).get("resettle",{})
	if rs is Dictionary and bool((rs as Dictionary).get("known",false)): return {}
	# Theirs again by a fight or by our word: we know it. Only a quiet return
	# of its people, not heard of yet, leaves our old account standing.
	var unheard:=rs is Dictionary and bool((rs as Dictionary).get("happened",false))
	if String(region.get("controller",""))!="player" and not unheard: return {}
	var mc:Variant=WorldSimulation.military
	var force:Dictionary=mc.occupation_force_for_region(String(civ.id),city_id) if mc!=null else {}
	# unheard: its people came back, but our people do not know it yet; what
	# we say of it is what we saw when we left.
	return {"civ_id":String(civ.id),"region_id":city_id,"name":String(region.get("name","")),"ruin":(ruin as Dictionary).duplicate(true),"garrison":maxi(0,int(force.get("troops",0))),"unheard":unheard}

## Every town that has a ledger: [[civ_id, region_id], ...].
static func towns()->Array:
	var out:Array=[]
	var world:Variant=_world()
	if world==null: return out
	for civ in world.civilizations:
		if not civ is Dictionary: continue
		for r in (civ as Dictionary).get("strategic_regions",[]):
			if r is Dictionary and (r as Dictionary).get("ledger") is Dictionary and not ((r as Dictionary).ledger as Dictionary).is_empty():
				out.append([String((civ as Dictionary).get("id","")),String((r as Dictionary).get("id",""))])
	return out

## Words for where people went: "toward Stonefield (6), into the hills (2)".
static func fled_words(fled_to:Dictionary)->String:
	var parts:PackedStringArray=PackedStringArray()
	for where in fled_to:
		var n:=int(fled_to[where])
		if n<=0: continue
		parts.append(("into the hills" if String(where) in ["the hills",""] else "toward "+String(where))+" (%d)" % n)
	return ", ".join(parts)

## One line per group: "men: 38 bound, 12 free; women: 70 free; ..." (only
## what is not zero). For the fact sheets and the reader's brief.
static func here_words(c:Dictionary)->String:
	var parts:PackedStringArray=PackedStringArray()
	for g in GROUPS:
		var bits:PackedStringArray=PackedStringArray()
		for status in PRESENT:
			var n:=int(c.get("%s_%s" % [status,g],0))
			if n>0: bits.append("%d %s" % [n,status])
		if not bits.is_empty(): parts.append("%s: %s" % [String(GROUP_WORDS[g]),", ".join(bits)])
	return "; ".join(parts) if not parts.is_empty() else "nobody"

## The gone, by group: "killed 38 (men 38); taken 64 (women 40, children 24)".
static func gone_words(c:Dictionary)->String:
	var parts:PackedStringArray=PackedStringArray()
	for bucket in GONE:
		var n:=int(c.get(bucket,0))
		if n<=0: continue
		var bits:PackedStringArray=PackedStringArray()
		for g in GROUPS:
			var k:=int(c.get("%s_%s" % [bucket,g],0))
			if k>0: bits.append("%s %d" % [String(GROUP_WORDS[g]),k])
		parts.append("%s %d (%s)" % [{"killed":"killed","fled":"fled","taken":"taken to our home","displaced":"scattered when the town burned"}[bucket],n,", ".join(bits)])
	return "; ".join(parts) if not parts.is_empty() else "none"
