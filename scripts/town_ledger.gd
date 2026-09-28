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
##
## WHO HOLDS THE TOWN is one reading too (hold / holds): the region says
## whose it is, and it is HELD only while a garrison of ours stands in it.
## Every system asks this, never its own test of a garrison or a controller.
## Only in a held town is anyone under our guard: settle() frees those we held
## where no garrison stands (or scatters them from a ruin we burned), says so
## once through the war leader, and runs when a game is loaded, whenever a
## ledger is read, and each day.
##
## CHILDREN have a make-up the engine keeps (kids): girls and boys, under ten
## and ten or older, from a stated estimate of a farming village's young
## (CHILD_YEARS, GIRL_SHARE), kept in step by every move so "the girls under
## ten" is an exact count wherever the children went.
## Static helpers; preload.

const Chronicle:=preload("res://scripts/chronicle.gd")
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"
const PURSUIT_PATH:="res://scripts/pursuit.gd"
const HALL_PATH:="res://scripts/audience_hall.gd"

const GROUPS:=["men","women","children","elders"]
const PRESENT:=["free","bound","hostage","worker","conscript"]
## Those under our guard: only a town we hold has any.
const HELD:=["bound","hostage","worker","conscript"]
const GONE:=["killed","fled","taken","displaced"]
## A farming village's people (town_fate.gd: men 0.24; women and children 0.55).
const SHARES:={"men":0.24,"women":0.24,"children":0.31,"elders":0.21}
const VERSION:=2
## People removed here but not yet off the world's count wait at most this long.
const PENDING_DAYS:=3
## Plain words for each group, and for one of them.
const GROUP_WORDS:={"men":"men","women":"women","children":"children","elders":"old people"}
const STATUS_WORDS:={"free":"free in their houses","bound":"bound under our guard","hostage":"held as hostages","worker":"at forced labour","conscript":"serving with our garrison"}
## The children by year of age, 0 to 14, relative (a farming village with
## many births and early deaths: the youngest years are the fullest, so about
## 7 in 10 children are under ten). A little under half are girls.
const CHILD_YEARS:=[1.25,1.16,1.1,1.05,1.0,0.97,0.94,0.91,0.88,0.85,0.82,0.8,0.78,0.76,0.74]
const GIRL_SHARE:=0.49
## Children younger than this are "young".
const YOUNG_AGE:=10
const KID_BANDS:=["girls_young","girls_older","boys_young","boys_older"]
const KID_WORDS:={"girls_young":"girls under ten","girls_older":"girls of ten and older","boys_young":"boys under ten","boys_older":"boys of ten and older"}

## Towns being settled now (a guard: settling reads the ledger again).
static var _settling:Dictionary={}

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

## The town's ledger, reconciled to the world's count and to who holds the
## town (settle); made from the town's people when first needed. {} when
## there is no such town.
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
	# Nobody is under our guard where no garrison of ours stands.
	if held(l)>0 and not _settling.has(civ_id+"|"+region_id) and not holds(civ_id,region_id): settle(civ_id,region_id)
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
		"present":present,"running":{},"gone":gone,"fled_to":{},"freed":0,"released":0,"pending":0,"pending_day":-1,"ruin":{},
		"kids":{"p:free":split_by(int(present.free.children),kid_shares())},"went_free":{}}

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

## n split over any keys by weight (the rounding remainder to the largest
## parts). Keys with no weight get nothing; with no weight at all, nothing.
static func split_by(n:int,weights:Dictionary)->Dictionary:
	var out:={}
	for k in weights: out[k]=0
	if n<=0: return out
	var total:=0.0
	for k in weights: total+=maxf(0.0,float(weights[k]))
	if total<=0.0: return out
	var given:=0
	var rests:Array=[]
	for k in weights:
		var exact:=float(n)*maxf(0.0,float(weights[k]))/total
		out[k]=floori(exact); given+=int(out[k])
		if float(weights[k])>0.0: rests.append([exact-floorf(exact),k])
	rests.sort_custom(func(a:Array,b:Array)->bool: return float(a[0])>float(b[0]))
	var i:=0
	while given<n and not rests.is_empty():
		var k:Variant=rests[i%rests.size()][1]
		out[k]=int(out[k])+1; given+=1; i+=1
	return out

## A garrison's older records (before this ledger) become the ledger's,
## bounded by the town itself: the people there now and those the records
## say are gone make the town as it was (the killed its men first, the
## captives its women and children), and whatever the records hold under
## guard or running can only be people who are there. The world's own count
## of the killings there caps the old tally. When the old numbers do not fit,
## the Chronicle says what was kept.
static func _adopt_old_records(civ_id:String,region_id:String,l:Dictionary)->void:
	var mc:Variant=WorldSimulation.military
	if mc==null: return
	var at:int=mc._occupation_force_index(civ_id,region_id)
	if at<0: return
	var force:Dictionary=mc.occupation_forces[at]
	# What the old records say.
	var asked:={}
	var measures:Variant=force.get("measures",[])
	if measures is Array:
		for m in measures:
			if not m is Dictionary or bool((m as Dictionary).get("ended",false)): continue
			var id:=String(m.get("id",""))
			if not id in ["bind_men","hostages","conscript","labour"] or not (m as Dictionary).has("count"): continue
			asked[id]=int(asked.get(id,0))+maxi(0,int(m.get("count",0)))
			(m as Dictionary).erase("count")
	var fled:Dictionary=(force.get("fled") as Dictionary).duplicate(true) if force.get("fled") is Dictionary else {}
	force.erase("fled")
	var killed:=0
	var captives:=0
	var fate:Variant=force.get("fate")
	if fate is Dictionary:
		killed=maxi(0,int(fate.get("killed",0)))
		captives=maxi(0,int(fate.get("captives",0)))
		# The ledger counts people now; the old record keeps only the tribute.
		for key in ["killed","captives","moved"]: (fate as Dictionary).erase(key)
	var ran:=maxi(0,int(fled.get("count",0)))
	var state:=String(fled.get("state",""))
	# A flight already over: those caught died, the rest reached their people.
	var chase_killed:=clampi(int(fled.get("caught",0)),0,ran) if state in ["gone","caught"] else 0
	var reached:=(ran-chase_killed) if state=="gone" else 0
	if asked.is_empty() and ran<=0 and killed<=0 and captives<=0: return
	var notes:PackedStringArray=PackedStringArray()
	var r:=region_ref(civ_id,region_id)
	var name:=String(r.get("name",l.get("name","the town")))
	# The world's own count of the killings there.
	var gov:Dictionary=r.get("governance",{}) if r.get("governance") is Dictionary else {}
	var world_killed:=int(gov.get("mass_killing_deaths",0))
	if world_killed>0 and killed+chase_killed>world_killed:
		notes.append("the old tally of %d killed is more than the %d deaths %s itself counts" % [killed+chase_killed,world_killed,name])
		killed=maxi(0,world_killed-chase_killed)
		chase_killed=mini(chase_killed,world_killed)
	# The town as it was: the people there now and everyone gone since.
	var now:=int(l.get("start",0))
	var before:=now+killed+chase_killed+captives+reached
	var was:=split(before,SHARES)
	var left:=was.duplicate()
	# The killed were its men first; more than its men, the rest in proportion.
	var dead_men:=mini(killed+chase_killed,int(was.men))
	var killed_by:=_groups(); killed_by.men=dead_men
	var over:=killed+chase_killed-dead_men
	if over>0:
		var rest:=split(over,{"women":float(was.women),"children":float(was.children),"elders":float(was.elders)})
		for g in ["women","children","elders"]: killed_by[g]=int(rest[g])
		notes.append("more were killed than the %d men it had, so the rest of the dead were its women, children and old people" % int(was.men))
	for g in GROUPS: left[g]=int(left[g])-int(killed_by[g])
	# Those who got away before: men.
	var fled_by:=_groups(); fled_by.men=mini(reached,int(left.men))
	left.men=int(left.men)-int(fled_by.men)
	# The captives were its women and children (in proportion to who was left).
	var taken_by:=_groups()
	var carried:=split_by(captives,{"women":0.45*float(maxi(0,int(left.women))),"children":0.55*float(maxi(0,int(left.children)))})
	for g in ["women","children"]:
		var k:=mini(int(carried.get(g,0)),maxi(0,int(left[g])))
		taken_by[g]=k; left[g]=int(left[g])-k
	var short:=captives-int(taken_by.women)-int(taken_by.children)
	if short>0:
		taken_by.elders=mini(short,int(left.elders)); left.elders=int(left.elders)-int(taken_by.elders)
	# Whatever cannot be placed (rounding) stays with the people there now.
	var placed:=0
	for g in GROUPS: placed+=int(left[g])
	if placed!=now:
		var weights:={}
		var any:=false
		for g in GROUPS:
			weights[g]=float(maxi(0,int(left[g])))
			if float(weights[g])>0.0: any=true
		left=split(now,weights if any else SHARES)
	l["start"]=0
	for g in GROUPS: l["start"]=int(l.start)+int(left[g])+int(killed_by[g])+int(fled_by[g])+int(taken_by[g])
	l.present.free=left
	l.gone.killed=killed_by
	l.gone.fled=fled_by
	l.gone.taken=taken_by
	(l.kids as Dictionary).clear()
	if int(fled_by.men)>0: went_to(l,"the hills" if bool(fled.get("hills",false)) else String(fled.get("toward","the hills")),int(fled_by.men))
	# Those the old measures held, from who is there now.
	for id in ["bind_men","conscript","hostages","labour"]:
		if not asked.has(id): continue
		var want:=int(asked[id])
		var got:=0
		match id:
			"bind_men": got=move(l,"free","bound","men",want)
			"conscript": got=move(l,"free","conscript","men",want)
			"hostages":
				for g in (move_any(l,"free","hostage",want,["elders","women","children","men"]) as Dictionary).values(): got+=int(g)
			"labour":
				got=move(l,"bound","worker","men",want)
				if got<want: got+=move(l,"free","worker","men",want-got)
		if got<want: notes.append("the old record held %d under %s, but only %d of its people were there for it" % [want,{"bind_men":"binding","conscript":"service with us","hostages":"guard as hostages","labour":"forced labour"}[id],got])
	# The flight: still running, or already over.
	var refuge:={"name":String(fled.get("toward","")),"region_id":String(fled.get("toward_id","")),"hills":bool(fled.get("hills",false)),"position":fled.get("toward_position",{})}
	if state in ["running","chased"] and ran>0:
		var rec:=run(l,"free","men",ran,refuge,int(fled.get("day",_day())))
		var got_away:=int(rec.get("ran",0))
		if state=="chased" and not rec.is_empty(): rec["state"]="chased"
		if got_away<ran: notes.append("the old record had %d men running from it, but only %d free men were left there to run" % [ran,got_away])
	elif state in ["gone","caught"] and ran>0:
		l["running"]={"count":0,"groups":_groups(),"ran":ran,"caught":chase_killed,"reached":int(fled_by.men),"day":int(fled.get("day",_day())),"toward":String(refuge.name) if String(refuge.name)!="" else "the hills",
			"toward_id":String(refuge.region_id),"toward_position":(refuge.position as Dictionary).duplicate(true) if refuge.position is Dictionary else {},"hills":bool(refuge.hills),"state":state}
	if not notes.is_empty():
		Chronicle.record({"key":"ledger_adopted:%s" % region_id,"title":("The Old Count of %s" % name).substr(0,70),"tier":"notice","kind":"war","domain":"security",
			"text":"Our old count of %s did not add up, and was set right from the town itself: %s." % [name,"; ".join(notes)],"action":{"kind":"court","focus":{"civ_id":civ_id}}})
		l["adopted_notes"]=Array(notes)

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
		for status in HELD: n+=count(l,status,String(g))
	return n

# --------------------------------------------------------------------------
# The children's make-up: girls and boys, under ten and ten or older
# --------------------------------------------------------------------------

## The stated make-up of a village's children: {band: share}.
static func kid_shares()->Dictionary:
	var young:=0.0
	var all:=0.0
	for i in CHILD_YEARS.size():
		all+=float(CHILD_YEARS[i])
		if i<YOUNG_AGE: young+=float(CHILD_YEARS[i])
	var y:=young/all
	return {"girls_young":GIRL_SHARE*y,"girls_older":GIRL_SHARE*(1.0-y),"boys_young":(1.0-GIRL_SHARE)*y,"boys_older":(1.0-GIRL_SHARE)*(1.0-y)}

## The share of a band's children aged from_age up to (not including)
## below_age: "under five" is about half the girls under ten.
static func band_part(band:String,from_age:int,below_age:int)->float:
	var lo:=0 if band.ends_with("_young") else YOUNG_AGE
	var hi:=YOUNG_AGE if band.ends_with("_young") else CHILD_YEARS.size()
	var total:=0.0
	var part:=0.0
	for i in range(lo,hi):
		total+=float(CHILD_YEARS[i])
		if i>=from_age and i<below_age: part+=float(CHILD_YEARS[i])
	return part/total if total>0.0 else 0.0

## How many children one place holds: "p:<status>", "g:<bucket>", "run".
static func _kid_total(l:Dictionary,cell:String)->int:
	if cell.begins_with("p:"): return int(((l.get("present",{}) as Dictionary).get(cell.substr(2),{}) as Dictionary).get("children",0))
	if cell.begins_with("g:"): return int(((l.get("gone",{}) as Dictionary).get(cell.substr(2),{}) as Dictionary).get("children",0))
	if cell=="run":
		var r:Variant=l.get("running",{})
		if not r is Dictionary or (r as Dictionary).is_empty(): return 0
		return int(_rec_groups(r).get("children",0))
	return 0

## The bands of one place, made to add up to its children (a new or older
## record takes the stated make-up; a drifted one is rescaled in proportion).
## store: kept on the ledger (a move); a read never writes the ledger.
static func _kid_cell(l:Dictionary,cell:String,store:bool=true)->Dictionary:
	var kept:Dictionary=l.get("kids",{}) if l.get("kids") is Dictionary else {}
	var row:Dictionary=(kept.get(cell,{}) as Dictionary) if kept.get(cell) is Dictionary else {}
	if not store: row=row.duplicate()
	var total:=_kid_total(l,cell)
	var sum:=0
	for b in KID_BANDS:
		row[b]=maxi(0,int(row.get(b,0))); sum+=int(row[b])
	if sum!=total:
		var weights:={}
		var shares:=kid_shares()
		for b in KID_BANDS: weights[b]=float(row[b]) if sum>0 else float(shares[b])
		var fixed:=split_by(total,weights)
		# Rescaled onto bands with none left: the stated make-up takes the rest.
		var got:=0
		for b in KID_BANDS: got+=int(fixed.get(b,0))
		if got<total: fixed=split_by(total,shares)
		for b in KID_BANDS: row[b]=int(fixed.get(b,0))
	if store:
		if not l.get("kids") is Dictionary: l["kids"]={}
		(l.kids as Dictionary)[cell]=row
	return row

## n children from one place to another ("" for out of the ledger), before
## the group counts change: the named bands only (in order) when bands is
## given, else in proportion. Returns {band: n}.
static func _kid_shift(l:Dictionary,from:String,to:String,n:int,bands:Array=[])->Dictionary:
	var take:={}
	if n<=0: return take
	var src:=_kid_cell(l,from)
	if not bands.is_empty():
		var left:=n
		for b in bands:
			if left<=0: break
			var k:=mini(left,int(src.get(b,0)))
			if k>0: take[b]=k; left-=k
	else:
		var weights:={}
		var have:=0
		for b in KID_BANDS: weights[b]=float(src[b]); have+=int(src[b])
		var cut:=split_by(mini(n,have),weights)
		for b in KID_BANDS:
			var k:=mini(int(cut.get(b,0)),int(src[b]))
			if k>0: take[b]=k
	var dst:Dictionary=_kid_cell(l,to) if to!="" else {}
	for b in take:
		src[b]=int(src[b])-int(take[b])
		if to!="": dst[b]=int(dst.get(b,0))+int(take[b])
	return take

## New children in a place (born, come back): the stated make-up.
static func _kid_add(l:Dictionary,cell:String,n:int)->void:
	if n<=0: return
	var row:=_kid_cell(l,cell)
	var add:=split_by(n,kid_shares())
	for b in KID_BANDS: row[b]=int(row[b])+int(add.get(b,0))

## The children of one status in the town, by band: {band: n}.
static func kids(l:Dictionary,status:String)->Dictionary:
	return _kid_cell(l,"p:"+status,false)

## The children still in the town, whatever their status, by band.
static func kids_here(l:Dictionary)->Dictionary:
	var out:={}
	for b in KID_BANDS: out[b]=0
	for status in PRESENT:
		var row:=_kid_cell(l,"p:"+String(status),false)
		for b in KID_BANDS: out[b]=int(out[b])+int(row[b])
	return out

## The children gone into a bucket (killed, fled, taken, displaced), by band.
static func kids_gone(l:Dictionary,bucket:String)->Dictionary:
	return _kid_cell(l,"g:"+bucket,false)

## Everyone the ledger has ever counted: here, running and gone.
static func accounted(l:Dictionary)->int:
	var n:=present_total(l)+running_total(l)
	for bucket in GONE: n+=gone(l,bucket)
	return n

# --------------------------------------------------------------------------
# Moving people between statuses (no one enters or leaves the town)
# --------------------------------------------------------------------------

## Up to n of one group from one status to another. Returns how many moved.
## bands: for children, only those bands (in order).
static func move(l:Dictionary,from:String,to:String,group:String,n:int,bands:Array=[])->int:
	if n<=0 or from==to: return 0
	var src:Dictionary=l.present[from]
	var dst:Dictionary=l.present[to]
	var moved:=mini(n,int(src.get(group,0)))
	if moved<=0: return 0
	if group=="children":
		var shifted:=_kid_shift(l,"p:"+from,"p:"+to,moved,bands)
		if not bands.is_empty():
			moved=0
			for b in shifted: moved+=int(shifted[b])
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
		if group=="children": _kid_shift(l,"p:"+status,"g:"+bucket,took)
		row[group]=int(row[group])-took
		(l.gone[bucket] as Dictionary)[group]=int(l.gone[bucket].get(group,0))+took
		out["%s/%s" % [status,group]]=int(out.get("%s/%s" % [status,group],0))+took
		out[group]=int(out.get(group,0))+took
		out.total=int(out.total)+took
		left-=took
	_pending(l,int(out.total))
	return out

## Children of the named bands out of the town into a gone bucket, from the
## statuses in order (those we hold first, then the free). want: {band: n}.
## Returns {band: n, "status/band": n, "total": n}.
static func remove_kids(l:Dictionary,statuses:Array,want:Dictionary,bucket:String)->Dictionary:
	var out:={"total":0}
	for status in statuses:
		for b in KID_BANDS:
			var left:=int(want.get(b,0))-int(out.get(b,0))
			if left<=0: continue
			var k:=mini(left,int(_kid_cell(l,"p:"+String(status)).get(b,0)))
			if k<=0: continue
			_kid_shift(l,"p:"+String(status),"g:"+bucket,k,[b])
			var row:Dictionary=l.present[String(status)]
			row["children"]=int(row.get("children",0))-k
			(l.gone[bucket] as Dictionary)["children"]=int(l.gone[bucket].get("children",0))+k
			out[b]=int(out.get(b,0))+k
			out["%s/%s" % [status,b]]=int(out.get("%s/%s" % [status,b],0))+k
			out.total=int(out.total)+k
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

## Take n out of a running record, spread over its groups, into a place of
## the ledger ("g:<bucket>", or "" for out of it). {group: n}.
static func _take_running(l:Dictionary,rec:Dictionary,n:int,to:String="")->Dictionary:
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
		out[g]=c; done+=c
	for g in GROUPS:
		if done>=take: break
		var c:=mini(take-done,int(groups.get(g,0))-int(out[g]))
		if c>0: out[g]=int(out[g])+c; done+=c
	if int(out.children)>0: _kid_shift(l,"run",to,int(out.children))
	for g in GROUPS: groups[g]=int(groups.get(g,0))-int(out[g])
	rec["count"]=maxi(0,int(rec.get("count",0))-done)
	return out

## n people of one group and status run for their refuge. They are still
## counted in the world's town until they get there (pursuit.gd). Returns the
## running record. bands: for children, only those bands.
static func run(l:Dictionary,from:String,group:String,n:int,refuge:Dictionary,day:int,bands:Array=[])->Dictionary:
	var row:Dictionary=l.present[from]
	var ran:=mini(n,int(row.get(group,0)))
	if ran<=0: return running(l)
	if group=="children":
		var shifted:=_kid_shift(l,"p:"+from,"run",ran,bands)
		if not bands.is_empty():
			ran=0
			for b in shifted: ran+=int(shifted[b])
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
	var took:=_take_running(l,rec,n,"g:fled")
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
		if group=="children": _kid_shift(l,"run","g:killed",k)
		groups[group]=int(groups.get(group,0))-k
		rec["count"]=maxi(0,int(rec.get("count",0))-k)
		took[group]=k
	else:
		took=_take_running(l,rec,n,"g:killed")
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
	if group=="children": _kid_shift(l,"p:"+from,"g:fled",ran)
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
		_kid_add(l,"p:free",int(add.children))
		for g in GROUPS: mix[g]=int(mix.get(g,0))+int(add[g])
		l["joined"]=int(l.get("joined",0))+diff
	elif diff<0:
		# Dead or gone by other hands: from the free first, then those who ran,
		# then those we hold.
		var need:=-diff
		need-=_shrink(l,"free",need)
		if need>0:
			var rec:=running(l)
			if not rec.is_empty():
				var cut:=_take_running(l,rec,need)
				for g in GROUPS: need-=int(cut[g])
				_flight_over(rec)
		for status in ["worker","conscript","hostage","bound"]:
			if need<=0: break
			need-=_shrink(l,String(status),need)
		l["lost"]=int(l.get("lost",0))+(-diff-maxi(0,need))

## Remove up to n of one status in proportion, out of the ledger (the
## world's own losses). Returns how many.
static func _shrink(l:Dictionary,status:String,n:int)->int:
	var row:Dictionary=l.present[status]
	var total:=0
	for g in GROUPS: total+=int(row.get(g,0))
	if total<=0 or n<=0: return 0
	var take:=mini(n,total)
	var weights:={}
	for g in GROUPS: weights[g]=float(row.get(g,0))
	var cut:=split(take,weights)
	var out:=_groups()
	var done:=0
	for g in GROUPS:
		var c:=mini(int(cut[g]),int(row.get(g,0)))
		out[g]=c; done+=c
	# Rounding left some over: take it from whoever is left.
	for g in GROUPS:
		if done>=take: break
		var c:=mini(take-done,int(row.get(g,0))-int(out[g]))
		if c>0: out[g]=int(out[g])+c; done+=c
	if int(out.children)>0: _kid_shift(l,"p:"+status,"",int(out.children))
	for g in GROUPS: row[g]=int(row.get(g,0))-int(out[g])
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
	# The children's bands add up to the children in every place kept.
	var kids_ok:=true
	var kept:Dictionary=l.get("kids",{}) if l.get("kids") is Dictionary else {}
	for cell in kept:
		var row:Dictionary=kept[cell]
		var sum:=0
		for b in KID_BANDS:
			if int(row.get(b,0))<0: negative=true
			sum+=int(row.get(b,0))
		if sum!=_kid_total(l,String(cell)): kids_ok=false
	var diff:=pop-(present+ran+pending)
	var books:=int(l.get("start",0))+int(l.get("joined",0))-int(l.get("lost",0))-accounted(l)
	return {"ok":diff==0 and not negative and books==0 and kids_ok,"population":pop,"present":present,"running":ran,"pending":pending,"diff":diff,"negative":negative,"books":books,"accounted":accounted(l),"kids":kids_ok}

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
	# The children by band: here (every status), each status, and gone.
	out["kids_here"]=kids_here(l)
	for status in PRESENT: out["kids_"+String(status)]=kids(l,String(status))
	for bucket in GONE: out["kids_"+String(bucket)]=kids_gone(l,String(bucket))
	var went:Dictionary=l.get("went_free",{}) if l.get("went_free") is Dictionary else {}
	out["went_free"]=int(went.get("count",0))
	out["went_free_words"]=String(went.get("words",""))
	out["went_free_groups"]=(went.get("groups",{}) as Dictionary).duplicate() if went.get("groups") is Dictionary else {}
	return out

# --------------------------------------------------------------------------
# Who holds the town: the one reading every system uses
# --------------------------------------------------------------------------

## Who holds a town, as every system reads it: the order path, the court's
## facts, the order reader's brief, the map and its cards, the held-town
## report, the chase and the garrison's measures.
##   ours:     the region is ours (controller "player"): control comes from
##             the region;
##   garrison: our fighters standing there (0 when the town is not held);
##   held:     ours AND a garrison of ours stands in it. Only in a held town
##             is anyone under our guard (bound, hostage, at forced labour,
##             serving with us), and only there can the garrison act;
##   ruin:     our own ruin record stands (we burned it and have heard nothing
##             since: our_ruin);
##   taken:    we took it once (it has a ledger);
##   state:    "held" | "ruin_held" | "ruin" | "unguarded" | "theirs" | "unknown";
##   name, civ_id, region_id, controller.
static func hold(civ_id:String,region_id:String)->Dictionary:
	var r:=region_ref(civ_id,region_id)
	var out:={"state":"unknown","ours":false,"held":false,"garrison":0,"ruin":false,"taken":false,"name":String(r.get("name","")),"civ_id":civ_id,"region_id":region_id,"controller":""}
	if r.is_empty(): return out
	var controller:=String(r.get("controller",civ_id))
	var ours:=controller=="player"
	var troops:=0
	var mc:Variant=WorldSimulation.military
	if mc!=null:
		var at:int=mc._occupation_force_index(civ_id,region_id)
		if at>=0: troops=maxi(0,int(mc.occupation_forces[at].get("troops",0)))
	var l:Variant=r.get("ledger")
	var taken:=l is Dictionary and not (l as Dictionary).is_empty()
	var ruin:=taken and (l as Dictionary).get("ruin") is Dictionary and not ((l as Dictionary).ruin as Dictionary).is_empty() and not our_ruin(region_id).is_empty()
	var held:=ours and troops>0
	out.state="held" if held and not ruin else ("ruin_held" if held else ("ruin" if ruin else ("unguarded" if ours else "theirs")))
	out.ours=ours; out.held=held; out.garrison=troops if held else 0; out.ruin=ruin; out.taken=taken; out.controller=controller
	return out

## Do we hold this town (a garrison of ours in a town that is ours)?
static func holds(civ_id:String,region_id:String)->bool:
	return bool(hold(civ_id,region_id).get("held",false))

## hold() for a town known by its id alone (its people found by the region).
static func hold_at(city_id:String)->Dictionary:
	var world:Variant=_world()
	if world==null or city_id.is_empty(): return {"state":"unknown","ours":false,"held":false,"garrison":0,"ruin":false,"taken":false,"name":"","civ_id":"","region_id":city_id,"controller":""}
	var location:Dictionary=world._region_location(city_id)
	if location.is_empty(): return {"state":"unknown","ours":false,"held":false,"garrison":0,"ruin":false,"taken":false,"name":"","civ_id":"","region_id":city_id,"controller":""}
	return hold(String((world.civilizations[int(location.owner_index)] as Dictionary).get("id","")),city_id)

## "the Esurai" (a people's name as the court says it).
static func people_name(civ_id:String)->String:
	var world:Variant=_world()
	if world==null: return "their people"
	var index:int=world._civilization_index(civ_id)
	if index<0: return "their people"
	var name:=String((world.civilizations[index] as Dictionary).get("name","")).strip_edges()
	if name=="": return "their people"
	return name if name.to_lower().begins_with("the ") else "the "+name

## Why nobody of ours can act in a town, in plain words ("" when we hold it):
## "Tsaren is the Esurai's again: our men left it."
static func hold_words(h:Dictionary)->String:
	var name:=String(h.get("name","")) if String(h.get("name",""))!="" else "The town"
	match String(h.get("state","")):
		"held","ruin_held": return ""
		"ruin": return "%s is a ruin we burned, and nobody of ours holds it." % name
		"unguarded": return "%s is ours, but none of our fighters are there." % name
		"theirs":
			var who:=people_name(String(h.get("controller","")))
			if bool(h.get("taken",false)): return "%s is %s's again: our men left it." % [name,who]
			return "%s is still %s's." % [name,who]
	return "Nobody of ours holds %s." % name

# --------------------------------------------------------------------------
# Settling a town's people with who holds it
# --------------------------------------------------------------------------

## The ledger agrees with who holds the town (docs/ADJUDICATION.md: one
## state). Where no garrison of ours stands, nobody there can be under our
## guard: those we held go free in their houses, or, in a ruin we burned,
## are let go and scatter to their people (the burning's own rule). It is said
## once, in plain words: the words are returned and kept on the ledger (the
## war leader's facts carry them), and unless the caller tells it itself
## (quiet), the war leader reports it and the Chronicle notes it.
## Returns {} when nothing changed, else {freed, scattered, groups, words,
## matter (the report filed, or {})}.
static func settle(civ_id:String,region_id:String,quiet:bool=false)->Dictionary:
	var r:=region_ref(civ_id,region_id)
	if r.is_empty() or not r.get("ledger") is Dictionary or (r.ledger as Dictionary).is_empty(): return {}
	var key:=civ_id+"|"+region_id
	if _settling.has(key): return {}
	_settling[key]=true
	var out:=_settle(civ_id,region_id,r,quiet)
	_settling.erase(key)
	return out

static func _settle(civ_id:String,region_id:String,r:Dictionary,quiet:bool)->Dictionary:
	var l:Dictionary=r.ledger
	if held(l)<=0: return {}
	var h:=hold(civ_id,region_id)
	if bool(h.held): return {}
	var groups:=_groups()
	var by:={}
	var n:=0
	for status in HELD:
		for g in GROUPS:
			var k:=count(l,String(status),String(g))
			if k<=0: continue
			groups[g]=int(groups[g])+k; n+=k
			if not by.has(status): by[status]=_groups()
			(by[status] as Dictionary)[g]=k
	if n<=0: return {}
	var day:=_day()
	var name:=String(r.get("name",l.get("name","the town")))
	var scattered:=bool(h.ruin)
	var where:=""
	if scattered:
		# A ruin has no houses to go back to: they scatter to their people.
		var pursuit:GDScript=load(PURSUIT_PATH)
		var refuge:Dictionary=pursuit.call("refuge",civ_id,region_id)
		where="the hills" if bool(refuge.get("hills",false)) else String(refuge.get("name","the hills"))
		var removed:=remove(l,plan_of(HELD),n,"displaced")
		went_to(l,where,int(removed.total))
		pursuit.call("_reach_refuge",civ_id,region_id,int(removed.total),refuge,int(removed.get("men",0)))
	else:
		for status in HELD:
			for g in GROUPS: move(l,String(status),"free",String(g),count(l,String(status),String(g)))
	var words:=went_free_words(name,by,n,scattered,where)
	var rec:Dictionary=l.get("went_free",{}) if l.get("went_free") is Dictionary else {}
	var kept:Dictionary=rec.get("groups",_groups()) if rec.get("groups") is Dictionary else _groups()
	for g in GROUPS: kept[g]=int(kept.get(g,0))+int(groups[g])
	rec["count"]=int(rec.get("count",0))+n
	rec["groups"]=kept
	rec["day"]=day
	rec["words"]=words
	rec["scattered"]=scattered
	rec["told"]=quiet
	l["went_free"]=rec
	var matter:={}
	if not quiet: matter=_tell(civ_id,region_id)
	return {"freed":0 if scattered else n,"scattered":n if scattered else 0,"groups":groups,"words":words,"matter":matter}

## "When our men left Tsaren, the 21 bound men there went free."
static func went_free_words(name:String,by:Dictionary,n:int,scattered:bool,where:String)->String:
	var parts:PackedStringArray=PackedStringArray()
	for status in HELD:
		if not by.has(status): continue
		for g in GROUPS:
			var k:=int((by[status] as Dictionary).get(g,0))
			if k<=0: continue
			var who:=String(GROUP_WORDS[g])
			match String(status):
				"bound": parts.append("%d bound %s" % [k,who])
				"hostage": parts.append("%d %s held as hostages" % [k,who])
				"worker": parts.append("%d %s at forced labour" % [k,who])
				"conscript": parts.append("%d %s who served with us" % [k,who])
	var list:=parts[0] if parts.size()==1 else (", ".join(parts.slice(0,parts.size()-1))+" and "+parts[parts.size()-1])
	var whom:=("the "+list+" there") if parts.size()==1 else ("the %d we held there (%s)" % [n,list])
	if scattered:
		return "When our men left the ruins of %s, %s were let go; with no houses left, they scattered %s." % [name,whom,"into the hills" if where in ["","the hills"] else "toward "+where]
	return "When our men left %s, %s went free." % [name,whom]

## Tells what settle() found, once: the war leader reports it (unless he is
## already bringing another matter about that people, which it must not push
## aside; then it waits for the next day) and the Chronicle notes it.
static func _tell(civ_id:String,region_id:String)->Dictionary:
	var r:=region_ref(civ_id,region_id)
	if r.is_empty() or not r.get("ledger") is Dictionary: return {}
	var rec:Dictionary=(r.ledger as Dictionary).get("went_free",{}) if (r.ledger as Dictionary).get("went_free") is Dictionary else {}
	if rec.is_empty() or bool(rec.get("told",false)) or String(rec.get("words",""))=="": return {}
	var day:=_day()
	var name:=String(r.get("name","the town"))
	var words:=String(rec.words)
	Chronicle.record({"key":"went_free:%s:%d" % [region_id,int(rec.get("day",day))],"title":("Those We Held in %s Go Free" % name).substr(0,70),"text":words,
		"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	if _war_matter_waiting(civ_id): return {}
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	var matter:Variant=war_loop.call("_file",civ_id,"report",words,day) if war_loop!=null else {}
	rec["told"]=true
	return matter if matter is Dictionary else {}

## A war matter about this people already waits for the god (the war
## leader's filing replaces it, so a report waits instead).
static func _war_matter_waiting(civ_id:String)->bool:
	var hall:GDScript=load(HALL_PATH)
	if hall==null: return false
	var st:Variant=hall.call("state")
	if not st is Dictionary: return false
	for m in (st as Dictionary).get("matters",[]):
		if not m is Dictionary or String((m as Dictionary).get("situation_type",""))!="war_campaign": continue
		var war:Variant=(((m as Dictionary).get("audience",{}) as Dictionary).get("situation",{}) as Dictionary).get("war",{})
		if war is Dictionary and String((war as Dictionary).get("civ_id",""))==civ_id: return true
	return false

## Every town's ledger made to agree with who holds it, and any word still
## owed given (a game loaded; each day). Returns the report matters filed.
static func settle_all()->Array:
	var filed:Array=[]
	for pair in towns():
		var civ_id:=String(pair[0]); var region_id:=String(pair[1])
		var s:=settle(civ_id,region_id)
		if s.get("matter") is Dictionary and not (s.matter as Dictionary).is_empty(): filed.append(s.matter)
		var told:=_tell(civ_id,region_id)
		if not told.is_empty(): filed.append(told)
	return filed

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
