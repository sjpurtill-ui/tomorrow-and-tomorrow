extends RefCounted
## WHAT EACH OFFICIAL KNOWS, EXACTLY (docs/ADJUDICATION.md: officials know
## their office).
##
## The court's live voice is handed a fact sheet for the one who speaks, read
## from the same state every system writes: the towns' ledgers
## (town_ledger.gd), the bands and garrisons, the stores. An official states
## these numbers; what is not on the sheet they do not know, and they say who
## would know or what would find it out. Nobody invents ignorance.
##
##   everyone: the day and season, our home and its people, wars and peace,
##     who holds which town, and who is in each town we hold, by status;
##   war leader (the Marshal, or a war leader of renown who leads our bands):
##     bands and where they are, the fighters at home, every garrison, every
##     held town and ruin by its ledger (people by group and status: free,
##     bound, hostages, at forced labour, serving with us; killed, fled and
##     where, running now, taken home on the road or arrived, let go, freed),
##     the last flight from each town (and that the bound cannot run),
##     measures in force with the days left, resistance, chases out, the
##     last battles;
##   headman, steward, keeper of stores (Steward, Quartermaster, a settlement
##     leader): food in store and the days it lasts, water, housing,
##     sickness, workers by task, births and deaths this season, the people
##     brought home from towns we took;
##   keeper of tribute (Quartermaster, Envoy): tribute taken, treaties,
##     trade and pacts with each people we know.
##
## offices(persona, speaker) -> ["common", "war"?, "stores"?, "tribute"?].
## sheet(offices) -> {day, when, ..., towns:[{name, men_bound, ...}], ...}.
## text(sheet) -> the prompt block (plain lines, exact figures).
## Static helpers; preload.

const Ledger:=preload("res://scripts/town_ledger.gd")
const Measures:=preload("res://scripts/occupation_measures.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const HearthCount:=preload("res://scripts/hearth_count.gd")

## Offices (government_people_system office keys) and, when no key is known,
## words in a title, that make each sheet.
const WAR_KEYS:=["Marshal"]
const STORE_KEYS:=["Steward","Quartermaster","settlement","SettlementLeader"]
const TRIBUTE_KEYS:=["Quartermaster","Envoy","Treasurer"]
const WAR_WORDS:=["marshal","war leader","watch captain","watch speaker","watch keeper","defense","defence","militia","shield speaker","security"]
const STORE_WORDS:=["steward","quartermaster","stores","storekeeper","provision","supply","hearth","headman","settlement"]
const TRIBUTE_WORDS:=["quartermaster","treasurer","tribute","envoy","messenger","emissary","treaty","trade","market"]
## The prompt block is kept within this many characters.
const MAX_CHARS:=2600

static func _world()->Variant: return WorldSimulation.world
static func _mc()->Variant: return WorldSimulation.military
static func _day()->int: return int(WorldSimulation.state.elapsed_days) if WorldSimulation.state!=null else 0

## Which sheets a speaker gets. persona: the voice's persona (office_key,
## title, figure_id); speaker: the audience's speaker record (person_id).
static func offices(persona:Dictionary,speaker:Dictionary={},holder_key:String="")->Array[String]:
	var out:Array[String]=["common"]
	var key:=String(persona.get("office_key",""))
	var pid:=int(speaker.get("person_id",persona.get("person_id",0)))
	if key=="" and pid>0: key=String(GovernmentPeopleSystem.person_snapshot(pid).get("office_key",""))
	var office:=(String(persona.get("title",""))+" "+String(persona.get("office_title",""))+" "+String(speaker.get("title",""))).to_lower()
	var war:=key in WAR_KEYS or (key=="" and _any(office,WAR_WORDS))
	# A war leader of renown (a General among the historical figures).
	var fid:=String(persona.get("figure_id",speaker.get("figure_id","")))
	if fid=="" and holder_key.begins_with("figure:"): fid=holder_key.trim_prefix("figure:")
	if not war and fid!="":
		var leader:=WarOrders.war_leader({"figure_id":fid})
		war=String(leader.get("figure_id",""))==fid
	if not war and pid>0:
		war=int(WarOrders.war_leader().get("person_id",-1))==pid
	if war: out.append("war")
	if not war and (key in STORE_KEYS or (key=="" and _any(office,STORE_WORDS))): out.append("stores")
	if key in TRIBUTE_KEYS or (key=="" and _any(office,TRIBUTE_WORDS)): out.append("tribute")
	return out

static func _any(text:String,words:Array)->bool:
	for w in words:
		if String(w) in text: return true
	return false

## The exact facts for these offices.
static func sheet(which:Array)->Dictionary:
	var day:=_day()
	var out:={"offices":which.duplicate(),"day":day,"when":EraWords.when(day)}
	_common(out)
	if which.has("war"): _war(out)
	if which.has("stores"): _stores(out)
	if which.has("tribute"): _tribute(out)
	return out

# --------------------------------------------------------------------------
# Everyone
# --------------------------------------------------------------------------

static func _common(out:Dictionary)->void:
	var state:Variant=WorldSimulation.state
	out["home"]=String(state.settlement_name) if state!=null else ""
	out["home_people"]=int(state.population_total) if state!=null else 0
	var wars:Array=[]
	var peace:Array=[]
	var world:Variant=_world()
	if world!=null:
		for c in world.civilizations:
			if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
			var rel:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
			if int(rel.get("contact_level",0))<=0 and not bool(rel.get("at_war",false)): continue
			if bool(rel.get("at_war",false)): wars.append(String(c.get("name","")))
			else: peace.append(String(c.get("name","")))
	out["at_war_with"]=wars
	out["at_peace_with"]=peace
	var towns:Array=[]
	# Every town we hold has its ledger (begun from its people now if no
	# order has touched them yet).
	if _mc()!=null and world!=null:
		for h:Dictionary in WarOrders.held_towns():
			if not Ledger.has(String(h.civ_id),String(h.city_id)): Ledger.of(String(h.civ_id),String(h.city_id))
	for pair in Ledger.towns():
		var t:=town(String(pair[0]),String(pair[1]))
		if not t.is_empty(): towns.append(t)
	# Towns we hold that no order has touched yet (no ledger): the world's count.
	if _mc()!=null and world!=null:
		for h:Dictionary in WarOrders.held_towns():
			if towns.any(func(t:Dictionary)->bool: return String(t.region_id)==String(h.city_id)): continue
			towns.append({"name":String(h.name),"region_id":String(h.city_id),"civ_id":String(h.civ_id),"taken_from":String(h.civ_name),"status":"held","garrison":int(h.garrison),
				"commander":String(h.commander),"people_here":int(h.population),"by_status":"all %d free in their houses; nothing has been done to them since we took it" % int(h.population)})
	out["towns"]=towns

## One town's facts from its ledger ({} when it has none).
static func town(civ_id:String,region_id:String)->Dictionary:
	var c:=Ledger.counts(civ_id,region_id)
	if c.is_empty(): return {}
	var world:Variant=_world()
	var index:int=world._civilization_index(civ_id)
	var civ_name:=String(world.civilizations[index].get("name","")) if index>=0 else ""
	var region:Dictionary=world.region_snapshot(civ_id,region_id)
	# Who holds it: the one reading every system uses (town_ledger.hold).
	var h:=Ledger.hold(civ_id,region_id)
	var force:Dictionary=(_mc().occupation_force_for_region(civ_id,region_id) if _mc()!=null else {}) if bool(h.held) else {}
	var ruin:Dictionary=c.get("ruin",{})
	var status:="held" if String(h.state)=="held" else ("ruin" if bool(h.ruin) else ("ours" if bool(h.ours) else "theirs again"))
	var rs:Dictionary=ruin.get("resettle",{}) if ruin.get("resettle") is Dictionary else {}
	var t:={"name":String(c.name),"region_id":region_id,"civ_id":civ_id,"taken_from":civ_name,"status":status,"held":bool(h.held),"why_not_held":Ledger.hold_words(h),
		"garrison":int(h.garrison),"commander":String((force.get("commander",{}) as Dictionary).get("name","")) if force.get("commander") is Dictionary else "",
		"people_here":int(c.here),"by_status":Ledger.here_words(c),
		"men_here":int(c.here_men),"men_free":int(c.free_men),"men_bound":int(c.bound_men)+int(c.worker_men if _labour_from_bound(force) else 0),"hostages":int(c.hostage),
		"at_forced_labour":int(c.worker),"serving_with_us":int(c.conscript),
		"killed":int(c.killed),"killed_by_group":_groups_of(c,"killed"),
		"fled":int(c.fled)+int(c.displaced),"fled_to":(c.fled_to as Dictionary).duplicate(),"running_now":int(c.running),"running_toward":String(c.running_toward),
		"taken_home":int(c.taken),"taken_by_group":_groups_of(c,"taken"),"on_the_road":int(c.on_road),"road_days":int(c.road_days),"arrived_among_us":int(c.arrived),"died_on_road":int(c.died_on_road),
		"let_go":int(c.released),"freed":int(c.freed),"when_taken":_in_season(int(c.since)) if int(c.since)>=0 else "",
		"resistance":snappedf(float(region.get("resistance",0.0)),0.01)}
	# Its people came back unseen: what we know is what we saw when we left.
	if bool(Ledger.our_ruin(region_id).get("unheard",false)):
		t["people_here"]=0; t["by_status"]="nobody that our people know of"
		for key in ["men_here","men_free","men_bound","hostages","at_forced_labour","serving_with_us"]: t[key]=0
	var flight:Dictionary=c.get("flight",{})
	if not flight.is_empty():
		t["last_flight"]={"ran":int(flight.get("ran",flight.get("count",0))),"when":_in_season(int(flight.get("day",-1))),"toward":"the hills" if bool(flight.get("hills",false)) else String(flight.get("toward","")),
			"caught":int(flight.get("caught",0)),"reached":int(flight.get("reached",0)),"still_running":int(flight.get("count",0)),"state":String(flight.get("state",""))}
	if not ruin.is_empty():
		t["burned"]=_in_season(int(ruin.get("day",-1)))
		t["people_before_burning"]=int(ruin.get("before",0))
		t["garrison_left"]=not bool(ruin.get("held",true))
		if bool(rs.get("known",false)): t["lived_in_again"]="%s have come back to live there (we heard %s)" % [civ_name,EraWords.when(int(rs.get("learn_day",-1)))]
	# Those we held there who went free when our men left (town_ledger.settle).
	t["went_free"]=int(c.get("went_free",0))
	t["went_free_words"]=String(c.get("went_free_words",""))
	# The children by band, here now and taken (town_ledger's make-up).
	var kids_here:Dictionary=c.get("kids_here",{})
	var kids_taken:Dictionary=c.get("kids_taken",{})
	t["children_here"]={}
	t["children_taken"]={}
	for b in Ledger.KID_BANDS:
		if int(kids_here.get(b,0))>0: (t.children_here as Dictionary)[String(Ledger.KID_WORDS[b])]=int(kids_here[b])
		if int(kids_taken.get(b,0))>0: (t.children_taken as Dictionary)[String(Ledger.KID_WORDS[b])]=int(kids_taken[b])
	# The ledger's own counts, for answers built from this sheet (court_answers.gd).
	t["counts"]=c.duplicate(true)
	var lines:Array=[]
	var day:=_day()
	if not force.is_empty():
		for m:Dictionary in Measures.active(civ_id,region_id):
			var left:=maxi(0,int(m.get("until",day))-day)
			lines.append("%s (%s)" % [Measures.card_label(m,Ledger.of(civ_id,region_id,false),force),("%d more days" % left) if left<200 else "standing"])
	t["measures"]=lines
	return t

## "in the spring of Year 96" (a day in the Chronicle's own words).
static func _in_season(day:int)->String:
	if day<0: return "some time ago"
	var parts:=EraWords.when(day).split(" · ")
	return "in the %s of %s" % [parts[1].to_lower(),parts[0]] if parts.size()==2 else "in "+EraWords.when(day)

static func _labour_from_bound(force:Dictionary)->bool:
	var lab:=Measures._running(force,"labour") if not force.is_empty() else {}
	return not lab.is_empty() and String(lab.get("from",""))=="bound"

static func _groups_of(c:Dictionary,bucket:String)->Dictionary:
	var out:={}
	for g in Ledger.GROUPS:
		var n:=int(c.get("%s_%s" % [bucket,g],0))
		if n>0: out[String(Ledger.GROUP_WORDS[g])]=n
	return out

# --------------------------------------------------------------------------
# The war leader
# --------------------------------------------------------------------------

static func _war(out:Dictionary)->void:
	var mc:Variant=_mc()
	if mc==null: return
	out["fighters_at_home"]=maxi(0,int((mc.home_army as Dictionary).get("troops",0)))
	var bands:Array=[]
	for a in mc.field_armies:
		var army:Dictionary=a
		if int(army.get("troops",0))<=0: continue
		var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
		var doing:=Pursuit.doing_words(army)
		bands.append({"name":String(army.get("name","")),"fighters":int(army.troops),"where":WarOrders._where(army),"leader":String(commander.get("name","")),"doing":doing if doing!="" else String(army.get("status",""))})
	out["bands"]=bands
	var garrisons:Array=[]
	for f in mc.occupation_forces:
		var force:Dictionary=f
		garrisons.append({"town":String(force.get("region_name","")),"fighters":int(force.get("troops",0)),"wounded":int(force.get("wounded_pool",0)),"commander":String((force.get("commander",{}) as Dictionary).get("name","")) if force.get("commander") is Dictionary else ""})
	out["garrisons"]=garrisons
	var chases:Array=[]
	for d:Dictionary in Pursuit.detachments(): chases.append("%d fighters %s" % [int(d.troops),"chasing the men who fled "+String(d.town) if String(d.state)=="chasing" else ("walking back to "+String(d.town) if String(d.state)=="returning" else "marching home")])
	out["chases"]=chases
	var battles:Array=[]
	for b in mc.battle_history:
		if battles.size()>=3: break
		var rec:Dictionary=b
		var ours:=String(rec.get("home_side","attacker"))
		var theirs:="defender" if ours=="attacker" else "attacker"
		var where:=String(rec.get("target_region_name",""))
		battles.append({"when":EraWords.when(int(rec.get("day",-1))),"where":where if where!="" else "in the field","winner":String(rec.get("winner","")),
			"our_dead":int((rec.get(ours,{}) as Dictionary).get("dead",0)),"their_dead":int((rec.get(theirs,{}) as Dictionary).get("dead",0))})
	out["battles"]=battles

# --------------------------------------------------------------------------
# The headman and the keeper of stores
# --------------------------------------------------------------------------

static func _stores(out:Dictionary)->void:
	var state:Variant=WorldSimulation.state
	if state==null: return
	var food:=float((state.resource_stockpiles as Dictionary).get("Food",0.0))
	out["food_in_store"]=roundi(food)
	out["food_days"]=snappedf(float((state.simulation_metrics as Dictionary).get("food_days",0.0)),0.1)
	var water:Dictionary=state.water_metrics
	out["water"]={"stored":roundi(float(water.get("stored",0.0))),"days":snappedf(float(water.get("days",0.0)),0.1),"reachable":bool(water.get("source_accessible",false))}
	out["people"]=int(state.population_total)
	out["housing"]=int(state.housing_capacity)
	out["health"]=_health_words(float(state.population_health))
	var work:={}
	for task in (state.population_allocations as Dictionary):
		var n:=int(state.population_allocations[task])
		if n>0: work[String(task)]=n
	out["workers_by_task"]=work
	var season_start:=ceili(float(HearthCount.season_key(int(state.elapsed_days)))*HearthCount.SEASON_DAYS-HearthCount.SEASON_DAYS*0.5)
	var vital:Dictionary=state.rolling_vital_balance(maxi(1,int(state.elapsed_days)-season_start+1))
	out["births_this_season"]=int(vital.get("births",0))
	out["deaths_this_season"]=int(vital.get("deaths",0))
	var among:Array=[]
	var mc:Variant=_mc()
	if mc!=null:
		var total:=float(state.population_exact) if float(state.population_exact)>0.0 else float(state.population_total)
		for g in mc.occupation_transfers.data.get("groups",[]):
			if not g is Dictionary: continue
			among.append("%d from %s living among us as %s" % [roundi(float(g.get("share",0.0))*total),String(g.get("origin_name","")),{"enslaved":"slaves","penal":"bonded labourers","citizen":"our own people"}.get(String(g.get("status","")),"our own people")])
		for t in mc.occupation_transfers.data.get("transfers",[]):
			if not t is Dictionary: continue
			among.append("%d from %s on the road here as %s" % [int(t.get("people",0)),String(t.get("origin_region_name",t.get("origin_name",""))),{"enslaved":"captives","penal":"bonded labourers","citizen":"our own people"}.get(String(t.get("status","")),"people")])
	out["brought_home"]=among

static func _health_words(h:float)->String:
	if h>=0.8: return "most are well"
	if h>=0.65: return "some sickness, nothing spreading"
	if h>=0.5: return "much sickness"
	return "many are sick and some are dying of it"

# --------------------------------------------------------------------------
# The keeper of tribute
# --------------------------------------------------------------------------

static func _tribute(out:Dictionary)->void:
	var taken:Array=[]
	var mc:Variant=_mc()
	if mc!=null:
		for f in mc.occupation_forces:
			var fate:Variant=(f as Dictionary).get("fate")
			if fate is Dictionary and int((fate as Dictionary).get("tribute",0))>0: taken.append("%d Food from %s" % [int(fate.tribute),String((f as Dictionary).get("region_name",""))])
	out["tribute_taken"]=taken
	var peoples:Array=[]
	var world:Variant=_world()
	if world!=null:
		for c in world.civilizations:
			if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
			var rel:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
			if int(rel.get("contact_level",0))<=0: continue
			var pact:Dictionary=(ForeignDiplomacy.commitments.state.get("pacts",{}) as Dictionary).get(String(c.id),{}) if ForeignDiplomacy!=null else {}
			peoples.append({"people":String(c.get("name","")),"treaty":String(rel.get("treaty","none")),"trade":snappedf(float(rel.get("trade",0.0)),0.01),"pact":String(pact.get("kind",pact.get("action",""))) if not pact.is_empty() else "none"})
	out["peoples"]=peoples

# --------------------------------------------------------------------------
# The words the voice is given
# --------------------------------------------------------------------------

## The sheet as plain lines, exact figures, for the voice's prompt.
static func text(s:Dictionary)->String:
	var lines:PackedStringArray=PackedStringArray()
	lines.append("Today: %s. Home: %s, %d people." % [String(s.get("when","")),String(s.get("home","")),int(s.get("home_people",0))])
	var wars:Array=s.get("at_war_with",[])
	var peace:Array=s.get("at_peace_with",[])
	lines.append("At war with: %s. At peace with: %s." % [", ".join(PackedStringArray(wars)) if not wars.is_empty() else "nobody",", ".join(PackedStringArray(peace)) if not peace.is_empty() else "nobody we know"])
	var war:=(s.get("offices",[]) as Array).has("war")
	for t:Dictionary in s.get("towns",[]):
		lines.append(_town_line(t,war))
	if war:
		lines.append("Fighters at home: %d." % int(s.get("fighters_at_home",0)))
		var bands:PackedStringArray=PackedStringArray()
		for b:Dictionary in s.get("bands",[]): bands.append("%s, %d fighters, %s%s (%s)" % [String(b.name),int(b.fighters),String(b.where),(", led by "+String(b.leader)) if String(b.leader)!="" else "",String(b.doing)])
		lines.append("Bands out: %s." % ("; ".join(bands) if not bands.is_empty() else "none"))
		var gar:PackedStringArray=PackedStringArray()
		for g:Dictionary in s.get("garrisons",[]): gar.append("%s: %d fighters%s%s" % [String(g.town),int(g.fighters),(", %d wounded" % int(g.wounded)) if int(g.wounded)>0 else "",(" under "+String(g.commander)) if String(g.commander)!="" else ""])
		lines.append("Garrisons: %s." % ("; ".join(gar) if not gar.is_empty() else "none"))
		if not (s.get("chases",[]) as Array).is_empty(): lines.append("Out on a chase: %s." % "; ".join(PackedStringArray(s.chases)))
		var fights:PackedStringArray=PackedStringArray()
		for b:Dictionary in s.get("battles",[]): fights.append("%s, %s: %s won; our dead %d, theirs %d" % [String(b.when),String(b.where),String(b.winner) if String(b.winner)!="" else "nobody",int(b.our_dead),int(b.their_dead)])
		if not fights.is_empty(): lines.append("Last battles: %s." % "; ".join(fights))
	if (s.get("offices",[]) as Array).has("stores"):
		var water:Dictionary=s.get("water",{})
		lines.append("Stores: %d Food, enough for %s days. Water: %d stored, %s days%s." % [int(s.get("food_in_store",0)),str(s.get("food_days",0)),int(water.get("stored",0)),str(water.get("days",0)),"" if bool(water.get("reachable",true)) else ", and the source is out of reach"])
		lines.append("People: %d; houses for %d. Health: %s. Born this season: %d; died this season: %d." % [int(s.get("people",0)),int(s.get("housing",0)),String(s.get("health","")),int(s.get("births_this_season",0)),int(s.get("deaths_this_season",0))])
		var work:PackedStringArray=PackedStringArray()
		var tasks:Dictionary=s.get("workers_by_task",{})
		for task in tasks: work.append("%s %d" % [String(task).to_lower(),int(tasks[task])])
		if not work.is_empty(): lines.append("At work: %s." % ", ".join(work))
		if not (s.get("brought_home",[]) as Array).is_empty(): lines.append("Brought home from towns we took: %s." % "; ".join(PackedStringArray(s.brought_home)))
	if (s.get("offices",[]) as Array).has("tribute"):
		lines.append("Tribute taken: %s." % ("; ".join(PackedStringArray(s.get("tribute_taken",[]))) if not (s.get("tribute_taken",[]) as Array).is_empty() else "none"))
		var ties:PackedStringArray=PackedStringArray()
		for p:Dictionary in s.get("peoples",[]): ties.append("%s: treaty %s, trade %s, pact %s" % [String(p.people),String(p.treaty),str(p.trade),String(p.pact)])
		if not ties.is_empty(): lines.append("Peoples: %s." % "; ".join(ties))
	var out:="\n".join(lines)
	return out if out.length()<=MAX_CHARS else out.substr(0,MAX_CHARS)+"..."

## One town in plain words, exact. The war leader hears the whole ledger.
static func _town_line(t:Dictionary,war:bool)->String:
	var name:=String(t.get("name",""))
	var head:=""
	match String(t.get("status","")):
		"held": head="%s (taken from the %s%s; our garrison %d%s)" % [name,String(t.get("taken_from","")),(" "+String(t.when_taken)) if String(t.get("when_taken",""))!="" else "",int(t.get("garrison",0)),(" under "+String(t.commander)) if String(t.get("commander",""))!="" else ""]
		"ruin": head="%s (a ruin: burned by us %s; before, %d people; %s)" % [name,String(t.get("burned","")),int(t.get("people_before_burning",0)),"nobody of ours holds it" if int(t.get("garrison",0))<=0 else "%d of ours hold the ruins" % int(t.garrison)]
		"theirs again": head="%s (the %s's again, nobody of ours there%s)" % [name,String(t.get("taken_from","")),("; "+String(t.lived_in_again)) if String(t.get("lived_in_again",""))!="" else ""]
		_: head="%s (ours, but no garrison of ours is there)" % name
	var line:="%s: %d people there now: %s." % [head,int(t.get("people_here",0)),String(t.get("by_status",""))]
	# Nobody is under our guard where we have no garrison: said with the numbers.
	if String(t.get("went_free_words",""))!="": line+=" "+String(t.went_free_words)
	if not war or not t.has("men_bound"): return line
	var young:Dictionary=t.get("children_here",{})
	if not young.is_empty(): line+=" Children there now: %s." % _group_words(young)
	line+=" Men there now: %d (%d bound, %d free). Hostages: %d. At forced labour: %d. Serving with us: %d." % [int(t.men_here),int(t.men_bound),int(t.men_free),int(t.hostages),int(t.at_forced_labour),int(t.serving_with_us)]
	line+=" Killed since we took it: %d%s." % [int(t.killed),(" ("+_group_words(t.killed_by_group)+")") if not (t.killed_by_group as Dictionary).is_empty() else ""]
	line+=" Fled and reached their people: %d%s." % [int(t.fled),(" ("+Ledger.fled_words(t.fled_to)+")") if not (t.fled_to as Dictionary).is_empty() else ""]
	if int(t.running_now)>0: line+=" Running now, not there yet: %d toward %s." % [int(t.running_now),String(t.running_toward)]
	if int(t.taken_home)>0: line+=" Taken to %s: %d (%s): %d on the road%s, %d arrived%s." % [String(WorldSimulation.state.settlement_name),int(t.taken_home),_group_words(t.taken_by_group),int(t.on_the_road),(" about %d days out" % int(t.road_days)) if int(t.on_the_road)>0 else "",int(t.arrived_among_us),(", %d died on the road" % int(t.died_on_road)) if int(t.died_on_road)>0 else ""]
	var young_taken:Dictionary=t.get("children_taken",{})
	if not young_taken.is_empty(): line+=" The children taken: %s." % _group_words(young_taken)
	if int(t.let_go)>0: line+=" Let go back to their houses: %d." % int(t.let_go)
	if int(t.freed)>0: line+=" Freed among us: %d." % int(t.freed)
	var flight:Dictionary=t.get("last_flight",{})
	if not flight.is_empty():
		line+=" The bound cannot run: none of the bound got away. The last flight: %d ran %s toward %s, before they could be caught or bound; %d caught, %d reached their people, %d still running." % [int(flight.ran),String(flight.when),String(flight.toward),int(flight.caught),int(flight.reached),int(flight.still_running)]
	else:
		line+=" Nobody has run from it since we took it; the bound cannot run."
	if not (t.get("measures",[]) as Array).is_empty(): line+=" In force: %s." % "; ".join(PackedStringArray(t.measures))
	if String(t.get("status",""))=="held": line+=" Resistance %.2f." % float(t.get("resistance",0.0))
	return line

static func _group_words(by:Dictionary)->String:
	var parts:PackedStringArray=PackedStringArray()
	for g in by: parts.append("%s %d" % [String(g),int(by[g])])
	return ", ".join(parts)
