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
##     last battles, and how well each band and garrison is fed today
##     (supply_state.gd: the share it gets, foraged, carried, from its town,
##     days hungry, its line back to our stores);
##   headman, steward, keeper of stores (Steward, Quartermaster, a settlement
##     leader): food in store and the days it lasts, water, housing,
##     sickness, workers by task, births and deaths this season, the people
##     brought home from towns we took;
##   keeper of tribute (Quartermaster, Envoy): tribute taken, treaties,
##     trade and pacts with each people we know;
##   chief scout (the Pathfinder): the scouting parties out (where, how many,
##     when they come back), the peoples we have met and every town we know,
##     how far and which way;
##   everyone also knows how the people hold the god (love and dread, in
##     words) and who sits on the council now.
##
## offices(persona, speaker) -> ["common", "war"?, "stores"?, "tribute"?, "scouts"?].
## sheet(offices) -> {day, when, ..., towns:[{name, men_bound, ...}], ...}.
## text(sheet) -> the prompt block (plain lines, exact figures).
## Static helpers; preload.

const Ledger:=preload("res://scripts/town_ledger.gd")
const Measures:=preload("res://scripts/occupation_measures.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const HearthCount:=preload("res://scripts/hearth_count.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const AutoFounding:=preload("res://scripts/auto_founding.gd")
const TradeLedger:=preload("res://scripts/trade_ledger.gd")
const TradeWords:=preload("res://scripts/trade_words.gd")
const ManualWork:=preload("res://scripts/manual_work.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const TownNames:=preload("res://scripts/town_names.gd")

## Offices (government_people_system office keys) and, when no key is known,
## words in a title, that make each sheet.
const WAR_KEYS:=["Marshal"]
const STORE_KEYS:=["Steward","Quartermaster","settlement","SettlementLeader"]
const TRIBUTE_KEYS:=["Quartermaster","Envoy","Treasurer"]
const WAR_WORDS:=["marshal","war leader","watch captain","watch speaker","watch keeper","defense","defence","militia","shield speaker","security"]
const STORE_WORDS:=["steward","quartermaster","stores","storekeeper","provision","supply","hearth","headman","settlement"]
const TRIBUTE_WORDS:=["quartermaster","treasurer","tribute","envoy","messenger","emissary","treaty","trade","market"]
const SCOUT_KEYS:=["ChiefScout"]
const SCOUT_WORDS:=["pathfinder","scout","tracker","outrider"]
## The prompt block is kept within this many characters.
const MAX_CHARS:=3600
## Raids, feuds and the war leader's fights (loaded when asked: it reaches back here).
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"

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
	# His own office is war (the Marshal's): he keeps no store sheet. A headman
	# standing in for the war keeps his own sheets and gets the war's too.
	var own_war:=war
	# A war leader of renown (a General among the historical figures).
	var fid:=String(persona.get("figure_id",speaker.get("figure_id","")))
	if fid=="" and holder_key.begins_with("figure:"): fid=holder_key.trim_prefix("figure:")
	if not war and fid!="":
		var leader:=WarOrders.war_leader({"figure_id":fid})
		war=String(leader.get("figure_id",""))==fid
	if not war and pid>0:
		war=int(WarOrders.war_leader().get("person_id",-1))==pid
	if war: out.append("war")
	if not own_war and (key in STORE_KEYS or (key=="" and _any(office,STORE_WORDS))): out.append("stores")
	if key in TRIBUTE_KEYS or (key=="" and _any(office,TRIBUTE_WORDS)): out.append("tribute")
	# The Headman carries trade with other peoples while no Envoy holds office.
	elif key=="Steward" and GovernmentPeopleSystem.officeholder("Envoy").is_empty(): out.append("tribute")
	if key in SCOUT_KEYS or (key=="" and _any(office,SCOUT_WORDS)): out.append("scouts")
	return out

static func _any(text:String,words:Array)->bool:
	for w in words:
		if String(w) in text: return true
	return false

## The answer the one before the ruler gives from their own sheet, "" when
## the words ask nothing it lists (the court screen asks this before handing
## "who do we trade with?" to the persons engine as a question about people).
static func answer_for(audience_id:String,text:String)->String:
	var audience:=Hall.find(audience_id)
	if audience.is_empty() or String(audience.get("origin",""))!="court": return ""
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
	if String(speaker.get("known_id",""))!="": return ""
	var which:=offices({},speaker,String(audience.get("holder_key","")))
	return String((load("res://scripts/court_answers.gd") as GDScript).call("answer",sheet(which),text))

## The exact facts for these offices.
static func sheet(which:Array)->Dictionary:
	var day:=_day()
	var out:={"offices":which.duplicate(),"day":day,"when":EraWords.when(day)}
	_common(out)
	if which.has("war"): _war(out)
	if which.has("stores"): _stores(out)
	if which.has("tribute"): _tribute(out)
	if which.has("scouts"): _scouts(out)
	# How each people we know sees us (standing.gd): the keepers of our ties
	# and the war leader know it, with the odds it moves.
	if which.has("tribute") or which.has("war"): _standing(out)
	return out

static func _standing(out:Dictionary)->void:
	var Standing:=preload("res://scripts/standing.gd")
	var peoples:Array=[]
	for v:Dictionary in Standing.views():
		var does:PackedStringArray=PackedStringArray()
		for c:Dictionary in Standing.consequences(String(v.civ_id),v): does.append(String(c.words))
		var feelings:={}
		for row:Array in Standing.VIEWS: feelings[String(row[0])]=roundi(float(v.get(String(row[0]),0.0))*100.0)
		peoples.append({"name":String(v.civ_name),"headline":Standing.view_words(v),"feelings":feelings,"envy":roundi(float(v.envy)*100.0),"contempt":roundi(float(v.contempt)*100.0),
			"strength":String(preload("res://scripts/hud/content/dock_content_standing.gd")._strength_words(float(v.strength_ratio))),"does":does})
	out["standing"]={"peoples":peoples,"posture":String(Standing.posture().words)}

# --------------------------------------------------------------------------
# Everyone
# --------------------------------------------------------------------------

static func _common(out:Dictionary)->void:
	var state:Variant=WorldSimulation.state
	out["home"]=String(state.settlement_name) if state!=null else ""
	out["home_people"]=int(state.population_total) if state!=null else 0
	var wars:Array=[]
	var feuds:Array=[]
	var peace:Array=[]
	var broken:Array=[]
	var world:Variant=_world()
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	if world!=null:
		for c in world.civilizations:
			if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
			var rel:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
			if int(rel.get("contact_level",0))<=0 and not bool(rel.get("at_war",false)): continue
			# A small people's fight is a feud, never a war (conflict_scale.gd):
			# raids and killings back and forth, the numbers from the war ledger.
			var feud:Dictionary=war_loop.call("feud_view",String(c.get("id",""))) if war_loop!=null else {}
			# A people broken past feuding (war_loop.survivors) is neither at
			# peace nor at feud: no town of theirs is left, a handful live.
			var left:Dictionary=war_loop.call("survivors",String(c.get("id",""))) if war_loop!=null and feud.is_empty() and not bool(rel.get("at_war",false)) else {}
			if not feud.is_empty(): feuds.append(feud)
			elif bool(rel.get("at_war",false)): wars.append(String(c.get("name","")))
			elif not left.is_empty(): broken.append(left)
			else: peace.append(String(c.get("name","")))
	out["at_war_with"]=wars
	out["feuding_with"]=feuds
	out["at_peace_with"]=peace
	out["broken_peoples"]=broken
	# The last fight, as everyone has heard it: where, when and who won.
	out["last_fights"]=battles(1,false)
	# How the people hold the god, in words (divine_regard.people_regard), and
	# who sits on the council now: things every official at court knows.
	var officials:=Hall._officials()
	var regard:=Divine.people_regard(officials)
	out["people_regard"]={"read":String(regard.get("read","")),"love":Divine._band(float(regard.get("love",0.5))),"dread":Divine._band(float(regard.get("dread",0.0)))}
	var council:Array=[]
	for p:Dictionary in officials: council.append({"title":String(p.get("office_title","")),"name":String(p.get("name","")),"office":String(p.get("office_key",""))})
	out["council"]=council
	# What each office's holder changes, in the engine's numbers (office
	# levers): everyone at court knows what the council's hands are worth.
	out["hands"]=hands()
	# The god's word on new towns (auto_founding.gd), which everyone at court
	# knows; the headman also knows what keeps the leaders home.
	if state!=null: out["new_towns"]=AutoFounding.court_facts("stores" in (out.get("offices",[]) as Array))
	# Those put out of office or held under guard at the god's word, still living.
	var set_aside:Array=[]
	for p in GovernmentPeopleSystem.people:
		if not p is Dictionary: continue
		var reason:=String((p as Dictionary).get("removal_reason",""))
		var status:=String((p as Dictionary).get("status",""))
		if status=="detained": set_aside.append("%s (held under guard)" % String(p.get("name","")))
		elif status=="active" and reason in ["dismissed","arrested"] and String((p as Dictionary).get("office_key",""))=="": set_aside.append("%s (put out of office)" % String(p.get("name","")))
	out["set_aside"]=set_aside
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
			towns.append({"name":TownNames.of(String(h.civ_id),String(h.city_id),String(h.name)),"region_id":String(h.city_id),"civ_id":String(h.civ_id),"taken_from":String(h.civ_name),"status":"held","garrison":int(h.garrison),
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
	var t:={"name":TownNames.of(civ_id,region_id,String(c.name)),"region_id":region_id,"civ_id":civ_id,"taken_from":civ_name,"status":status,"held":bool(h.held),"why_not_held":Ledger.hold_words(h),
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
	# What they fight with, and who is still to be made a fighter.
	var inventory:Dictionary=mc.military_inventory
	out["spears"]=int(inventory.get("spear",0))
	var weapons:={}
	for item in inventory:
		var n:=int(inventory[item])
		if n>0 and String(item)!="spear": weapons[String(item).replace("_"," ")]=n
	out["weapons"]=weapons
	out["recruits"]=maxi(0,int(mc.aggregate_recruits))
	var drilling:=0
	for t in mc.training_queue:
		if t is Dictionary: drilling+=int((t as Dictionary).get("count",(t as Dictionary).get("troops",0)))
	out["in_training"]=drilling
	var bands:Array=[]
	for a in mc.field_armies:
		var army:Dictionary=a
		if int(army.get("troops",0))<=0: continue
		var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
		var doing:=Pursuit.doing_words(army)
		# A band standing at a town is at that town ("at Tsaren, about 21 km
		# from home"), not only somewhere out from home.
		var where:=WarOrders._where(army)
		var at:=String(army.get("location_name",""))
		if at!="" and String(army.get("status",""))=="stationed" and not at.to_lower() in where.to_lower(): where="at %s, %s" % [at,where]
		bands.append({"name":String(army.get("name","")),"fighters":int(army.troops),"where":where,"leader":String(commander.get("name","")),"doing":doing if doing!="" else String(army.get("status","")),
			"fed":fed_facts(Supply.of_force(army))})
	out["bands"]=bands
	# Our generals as their records stand, and what each changes in the
	# engine's numbers (general_record.gd): the war leader knows them all.
	out["generals"]=generals()
	var garrisons:Array=[]
	for f in mc.occupation_forces:
		var force:Dictionary=f
		garrisons.append({"town":TownNames.of(String(force.get("civ_id","")),String(force.get("region_id","")),String(force.get("region_name",""))),"fighters":int(force.get("troops",0)),"wounded":int(force.get("wounded_pool",0)),"commander":String((force.get("commander",{}) as Dictionary).get("name","")) if force.get("commander") is Dictionary else "",
			"fed":fed_facts(Supply.of_force(force))})
	out["garrisons"]=garrisons
	# Who carries the bands' supply and how much of it (carriers.gd), and the
	# replacements on their way (field_sustainment.gd): the war leader's to say.
	if mc.has_method("carrier_reading"):
		var r:Dictionary=mc.carrier_reading()
		var fleet:Dictionary=r.get("fleet",{})
		out["carriers"]={"porters":int(fleet.get("porters",0)),"carts":int(fleet.get("carts",0)),"lorries":int(fleet.get("lorries",0)),"asked":roundi(float(r.get("demand",0.0))),"brought":roundi(minf(float(r.get("moved",0.0)),float(r.get("demand",0.0)))),"bread":roundi(float(r.get("food",1.0))*100.0),"stores":roundi(float(r.get("stores",1.0))*100.0)}
	if "sustainment" in mc:
		var coming:=0
		for order in mc.training_queue:
			if order is Dictionary and String((order as Dictionary).get("mode",""))=="field_draft": coming+=int((order as Dictionary).get("count",0))
		out["replacements"]={"on_road":int(mc.sustainment.drafts_on_road()),"in_training":coming}
	# Our field depots and those being laid (field_depots.gd).
	if "depots" in mc:
		var Depots:=preload("res://scripts/field_depots.gd")
		var standing:Array=[]
		for d in mc.field_depots: standing.append({"where":Depots.place_words(Vector2(float(d.x),float(d.z))),"laid_by":String(d.get("by",""))})
		var laying:Array=[]
		for a in mc.field_armies:
			var work:=Depots.progress(a)
			if not work.is_empty(): laying.append({"band":String((a as Dictionary).get("name","a band")),"where":Depots.place_words(Vector2(float(work.x),float(work.z))),"days_left":int(work.days_left)})
		if not standing.is_empty() or not laying.is_empty() or mc.depots.known():
			out["depots"]={"standing":standing,"laying":laying,"keep":int(mc.depots.limit()),"can_build":bool(mc.depots.known())}
	var chases:Array=[]
	for d:Dictionary in Pursuit.detachments(): chases.append("%d fighters %s" % [int(d.troops),"chasing the men who fled "+String(d.town) if String(d.state)=="chasing" else ("walking back to "+String(d.town) if String(d.state)=="returning" else "marching home")])
	out["chases"]=chases
	out["battles"]=battles(3,true)
	# The town's defences: what stands, what goes up or why not, and the
	# god's word (home_defense.gd, the Buildings page's own reading).
	if bool(WorldSimulation.state.settlement_site_committed):out["defences"]=preload("res://scripts/home_defense.gd").court_facts()

## The last fights, newest first, from the battle record and what the war
## leader settled after each (the captives and spoils, military_campaign
## settlements): {when, where, place, winner, won, lost, our_dead, their_dead,
## their_people, general, captives, captives_fate, spoils, spoils_went}.
## detail=false: only where, when and who won (what everyone has heard).
static func battles(limit:int=3,detail:bool=true)->Array:
	var out:Array=[]
	var mc:Variant=_mc()
	if mc==null: return out
	for b in mc.battle_history:
		if out.size()>=limit: break
		if not b is Dictionary: continue
		var rec:Dictionary=b
		var ours:=String(rec.get("home_side","attacker"))
		var theirs:="defender" if ours=="attacker" else "attacker"
		var where:=String(rec.get("target_region_name",""))
		var winner:=String(rec.get("winner",""))
		var row:={"when":EraWords.when(int(rec.get("day",-1))),"in_season":_in_season(int(rec.get("day",-1))),"where":where if where!="" else "in the field","place":where,"winner":winner,
			"won":winner!="" and winner==ours,"lost":winner!="" and winner==theirs}
		# What the war leader did with the captives of this fight: everyone sees
		# bondservants arrive, so even the brief account carries them.
		var settled:Dictionary=rec.get("aftermath_settled",{}) if rec.get("aftermath_settled") is Dictionary else {}
		if settled.is_empty() and String(rec.get("id",""))!="":
			for s in mc.settlements:
				if s is Dictionary and String((s as Dictionary).get("battle_id",""))==String(rec.id): settled=s; break
		var term:Dictionary=rec.get("termination",{}) if rec.get("termination") is Dictionary else {}
		row["captives"]=int(settled.get("prisoners",term.get("prisoners",0)))
		row["captives_fate"]=CAPTIVE_FATE.get(String(settled.get("prisoner_policy","")),"held under guard") if int(row.captives)>0 else ""
		if not detail:
			out.append(row); continue
		var threat:Dictionary=rec.get("threat",{}) if rec.get("threat") is Dictionary else {}
		row["our_dead"]=int((rec.get(ours,{}) as Dictionary).get("dead",0))
		row["their_dead"]=int((rec.get(theirs,{}) as Dictionary).get("dead",0))
		row["our_troops"]=int((rec.get(ours,{}) as Dictionary).get("initial_troops",0))
		row["their_troops"]=int((rec.get(theirs,{}) as Dictionary).get("initial_troops",0))
		row["their_people"]=String(threat.get("source_name",""))
		row["general"]=String(((rec.get(ours,{}) as Dictionary).get("commander",{}) as Dictionary).get("name","")) if (rec.get(ours,{}) as Dictionary).get("commander") is Dictionary else ""
		# And the spoils, and where they went.
		var taken:Dictionary=settled.get("spoils_taken",{}) if settled.get("spoils_taken") is Dictionary else {}
		row["spoils"]=spoils_words(taken)
		row["spoils_went"]=SPOILS_WENT.get(String(settled.get("spoils_policy","")),"to the stores") if String(row.spoils)!="" else ""
		out.append(row)
	return out

## How well a band or garrison is fed today, from the supply model
## (supply_state.of_force, the rations' own numbers): whole percentages that
## add up, the state in words, the days hungry and its line back to stores.
## {gets, foraged, carried, from_town, state, hungry_days, line, words}.
static func fed_facts(report:Dictionary)->Dictionary:
	if report.is_empty(): return {}
	var parts:=Supply.percents(float(report.get("ratio",0.0)),[float(report.get("local",0.0)),float(report.get("foraged",0.0)),float(report.get("carried",0.0))])
	return {"gets":roundi(float(report.get("ratio",0.0))*100.0),"from_town":int(parts[0]),"foraged":int(parts[1]),"carried":int(parts[2]),
		"state":Supply.state_words(String(report.get("state",""))),"hungry_days":roundi(float(report.get("hungry_days",0.0))) if bool(report.get("hungry",false)) else 0,
		"at_home":bool(report.get("at_home",false)),"line":"" if bool(report.get("at_home",false)) else Supply.line_words(report),"words":String(report.get("words","")),
		"stores":roundi(float(report.get("stores_share",1.0))*100.0),"winter":roundi(float((report.get("winter",{}) as Dictionary).get("ratio",-1.0))*100.0) if report.get("winter") is Dictionary and float((report.winter as Dictionary).ratio)<float(report.get("ratio",0.0))-0.05 else -1,"winter_in":int((report.get("winter",{}) as Dictionary).get("in_days",0)) if report.get("winter") is Dictionary else 0,"sick":int((report.get("hunger_losses",{}) as Dictionary).get("sick",0)),"deserted":int((report.get("hunger_losses",{}) as Dictionary).get("deserted",0)),"dead":int((report.get("hunger_losses",{}) as Dictionary).get("dead",0))}

## "; food 60% (35% foraged, 25% carried), 4 days from Seanstone by cart
## track, hungry 3 days" for the prompt's band and garrison lines.
static func fed_line(fed:Dictionary)->String:
	if fed.is_empty(): return ""
	if bool(fed.get("at_home",false)): return "; fed from the stores at home"
	var shares:=PackedStringArray()
	if int(fed.get("from_town",0))>0: shares.append("%d%% from the town" % int(fed.from_town))
	if int(fed.get("foraged",0))>0: shares.append("%d%% foraged" % int(fed.foraged))
	if int(fed.get("carried",0))>0: shares.append("%d%% carried" % int(fed.carried))
	var out:="; food %d%%%s, %s" % [int(fed.get("gets",0)),(" ("+", ".join(shares)+")") if not shares.is_empty() else "",String(fed.get("line",""))]
	if int(fed.get("hungry_days",0))>0: out+=", hungry %d days" % int(fed.hungry_days)
	if int(fed.get("stores",100))<100: out+=", fodder, fuel and rounds %d%%" % int(fed.stores)
	if int(fed.get("winter",-1))>=0: out+="; in deep winter there (about %d days off) the same line would bring %d%%" % [int(fed.get("winter_in",0)),int(fed.winter)]
	var lost:=int(fed.get("sick",0))+int(fed.get("deserted",0))+int(fed.get("dead",0))
	if lost>0: out+="; hunger has cost %d fallen sick, %d gone home and %d dead" % [int(fed.get("sick",0)),int(fed.get("deserted",0)),int(fed.get("dead",0))]
	return out

const CAPTIVE_FATE:={"enslave":"sent home as bondservants","release":"let go","parole":"let go on their word","ransom":"given back for ransom","execute":"put to death","exchange":"traded for our own people","hold":"held under guard"}
const SPOILS_WENT:={"army stores":"to the stores","reward troops":"to the warriors","state treasury":"to the treasury","return property":"given back","unrestricted plunder":"kept by the warriors"}

## "40 supplies, a cart and 6 spears" (a battle's spoils in plain words).
static func spoils_words(taken:Dictionary)->String:
	var parts:PackedStringArray=PackedStringArray()
	var supplies:=int(taken.get("supplies",0))
	if supplies>0: parts.append("%d supplies" % supplies)
	var carts:=int(taken.get("carts",0))
	if carts>0: parts.append("a cart" if carts==1 else "%d carts" % carts)
	for kind in ["weapons","consumables"]:
		var items:Dictionary=taken.get(kind,{}) if taken.get(kind) is Dictionary else {}
		for item in items:
			var n:=int(items[item])
			if n<=0: continue
			var noun:=String(item).replace("_"," ")
			parts.append(("a %s" % noun) if n==1 else "%d %s" % [n,noun if noun.ends_with("s") else noun+"s"])
	var wealth:=int(taken.get("wealth",0))
	if wealth>0: parts.append("%d in goods of worth" % wealth)
	if parts.is_empty(): return ""
	if parts.size()==1: return parts[0]
	return ", ".join(parts.slice(0,parts.size()-1))+" and "+parts[parts.size()-1]

# --------------------------------------------------------------------------
# The headman and the keeper of stores
# --------------------------------------------------------------------------

static func _stores(out:Dictionary)->void:
	var state:Variant=WorldSimulation.state
	if state==null: return
	var food:=float((state.resource_stockpiles as Dictionary).get("Food",0.0))
	out["food_in_store"]=roundi(food)
	# Everything else in the stores, by what it is (the keeper counts it all).
	var stock:={}
	for res in (state.resource_stockpiles as Dictionary):
		var n:=roundi(float(state.resource_stockpiles[res]))
		if String(res)!="Food" and n>0: stock[String(res)]=n
	out["stock"]=stock
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
	# Who sets that work: our leaders, or the god by hand (manual_work.gd).
	out["daily_work"]=ManualWork.court_facts()
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
			if fate is Dictionary and int((fate as Dictionary).get("tribute",0))>0: taken.append("%d Food from %s" % [int(fate.tribute),TownNames.of(String((f as Dictionary).get("civ_id","")),String((f as Dictionary).get("region_id","")),String((f as Dictionary).get("region_name","")))])
	out["tribute_taken"]=taken
	var peoples:Array=[]
	var world:Variant=_world()
	if world!=null:
		for c in world.civilizations:
			if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
			var rel:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
			if int(rel.get("contact_level",0))<=0: continue
			var pact:Dictionary=(ForeignDiplomacy.commitments.state.get("pacts",{}) as Dictionary).get(String(c.id),{}) if ForeignDiplomacy!=null else {}
			# What really passes between us, from the trade ledger (trade_ledger.gd).
			var cid:=String(c.id)
			var trade:=TradeLedger.flow_value("player",cid)+TradeLedger.flow_value(cid,"player")
			peoples.append({"people":String(c.get("name","")),"treaty":String(rel.get("treaty","none")),"trade":snappedf(trade,0.1),"pact":String(pact.get("kind",pact.get("action",""))) if not pact.is_empty() else "none",
				"we_send":TradeWords.flow_words("player",cid),"they_send":TradeWords.flow_words(cid,"player"),"they_lean":TradeWords.leaning_line(cid,"player"),"we_lean":TradeWords.leaning_line("player",cid),
				"our_stance":TradeWords.stance_words("player",cid),"their_stance":TradeWords.theirs_label(cid),"tribute":TradeWords.tribute_label(cid),"met":int(rel.get("contact_level",0))>=2})
	out["peoples"]=peoples

# --------------------------------------------------------------------------
# The chief scout
# --------------------------------------------------------------------------

const COMPASS:=["east","southeast","south","southwest","west","northwest","north","northeast"]

## "west", "northeast": which way a place lies from another (+x east, +z south).
static func compass(from:Vector2,to:Vector2)->String:
	if from.distance_to(to)<0.01: return ""
	return COMPASS[posmod(roundi(rad_to_deg((to-from).angle())/45.0),8)]

static func _pos(p:Variant)->Vector2:
	if not p is Dictionary: return Vector2.INF
	var d:Dictionary=p
	if not d.has("x"): return Vector2.INF
	return Vector2(float(d.get("x",0.0)),float(d.get("z",d.get("y",0.0))))

static func _scouts(out:Dictionary)->void:
	## The scouting parties out, the peoples we have met and every town we know
	## of: how far and which way from home, from the scouts' own reports.
	var day:=_day()
	var parties:Array=[]
	var world:Variant=_world()
	if world!=null:
		for m in world.scout_missions:
			if not m is Dictionary: continue
			var mission:Dictionary=m
			var heading:=String(mission.get("ordered_heading",mission.get("planned_heading","")))
			var back:=int(mission.get("actual_return_day",mission.get("return_day",day)))
			parties.append({"scouts":int(mission.get("personnel",0)),"heading":heading,"toward":String(mission.get("target_label","")),"out_days":maxi(0,day-int(mission.get("start_day",day))),"back_in":maxi(0,back-day)})
	out["parties"]=parties
	var home:Vector2=world.player_world_origin if world!=null else Vector2.ZERO
	var peoples:Array=[]
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	if world!=null:
		for c in world.civilizations:
			if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
			var rel:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
			if int(rel.get("contact_level",0))<=0 and not bool(rel.get("at_war",false)): continue
			var feud:=war_loop!=null and bool(war_loop.call("feuding",String(c.get("id",""))))
			var broken:=war_loop!=null and not feud and bool(war_loop.call("broken",String(c.get("id",""))))
			peoples.append({"name":String(c.get("name","")),"at_war":bool(rel.get("at_war",false)) and not feud,"feud":feud,"broken":broken,"home_known":bool(rel.get("home_location_known",false)),"met":int(rel.get("contact_level",0))>=2})
	out["met_peoples"]=peoples
	var towns:Array=[]
	for t:Dictionary in WarOrders.held_towns()+WarOrders.known_places():
		var at:=_pos(t.get("position",{}))
		var row:={"name":String(t.get("name","")).trim_prefix("Reported home of "),"people":String(t.get("civ_name","")),"held":bool(t.get("held",false))}
		if at!=Vector2.INF:
			row["km"]=roundi(home.distance_to(at))
			row["way"]=compass(home,at)
		towns.append(row)
	out["known_towns"]=towns

# --------------------------------------------------------------------------
# A foreign envoy's own people
# --------------------------------------------------------------------------

## What an envoy knows of their own people, from the same world every system
## reads: their towns and how many live in each, where their ruler sits now
## (their high seat, or their largest town once the seat is lost), the towns
## our people took or burned, their number, and war or peace with us.
## {name, people, at_war, treaty, towns:[{name, people, seat}], seat, lost:[{name, how}]}.
static func people(civ_id:String)->Dictionary:
	var world:Variant=_world()
	if world==null: return {}
	var index:int=world._civilization_index(civ_id)
	if index<0: return {}
	var civ:Dictionary=world.civilizations[index]
	var rel:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	var home:=String(WorldSimulation.state.settlement_name) if WorldSimulation.state!=null else "the ruler's people"
	var towns:Array=[]; var lost:Array=[]
	var seat:=""
	for r in civ.get("strategic_regions",[]):
		if not r is Dictionary: continue
		var region:Dictionary=r
		var name:=String(region.get("name",""))
		if name=="" or not bool(region.get("settlement_founded",false)) and not Ledger.has(civ_id,String(region.get("id",""))): continue
		var ruin:=Ledger.our_ruin(String(region.get("id","")))
		if String(region.get("controller",""))=="player":
			var guarded:=bool(Ledger.hold(civ_id,String(region.id)).get("held",false))
			lost.append({"name":name,"state":"held" if guarded else "taken","how":"taken by %s; their garrison holds it" % home if guarded else "taken by %s" % home,"seat":String(region.get("role",""))=="capital"})
			continue
		if not ruin.is_empty():
			lost.append({"name":name,"state":"burned","how":"burned by %s" % home,"seat":String(region.get("role",""))=="capital"}); continue
		if not bool(region.get("settlement_founded",false)): continue
		var n:=roundi(float(region.get("population",0.0)))
		towns.append({"name":name,"people":n,"seat":String(region.get("role",""))=="capital"})
		if String(region.get("role",""))=="capital": seat=name
	# The high seat lost: the ruler sits in their largest town now.
	if seat=="" and not towns.is_empty():
		var best:Dictionary=towns[0]
		for t in towns:
			if int((t as Dictionary).people)>int(best.people): best=t
		seat=String(best.name)
		best["seat"]=true
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	var feud:=war_loop!=null and bool(war_loop.call("feuding",civ_id))
	return {"name":String(civ.get("name","")),"people":roundi(float(civ.get("population",0.0))),"at_war":bool(rel.get("at_war",false)) and not feud,"feud":feud,"treaty":String(rel.get("treaty","none")),
		"towns":towns,"seat":seat,"lost":lost,"home":home}

## The envoy's own people in plain lines, exact, for the voice's prompt.
static func people_text(p:Dictionary)->String:
	if p.is_empty(): return ""
	var rows:PackedStringArray=PackedStringArray()
	for t:Dictionary in p.get("towns",[]): rows.append("%s (%d people%s)" % [String(t.name),int(t.people),", where your ruler sits now" if bool(t.get("seat",false)) else ""])
	var lines:PackedStringArray=PackedStringArray()
	lines.append("Your people, the %s: about %d in all. Your towns now: %s." % [String(p.name),int(p.people),"; ".join(rows) if not rows.is_empty() else "none left"])
	for l:Dictionary in p.get("lost",[]): lines.append("%s%s: %s." % [String(l.name)," (once your ruler's seat)" if bool(l.get("seat",false)) else "",String(l.how)])
	lines.append("Your people and %s: %s." % [String(p.get("home","")),"in a feud (raids and killings back and forth; nobody has declared anything)" if bool(p.get("feud",false)) else ("at war" if bool(p.at_war) else ("treaty: "+String(p.treaty) if String(p.treaty) not in ["","none"] else "at peace"))])
	return "\n".join(lines)

# --------------------------------------------------------------------------
# The words the voice is given
# --------------------------------------------------------------------------

## The sheet as plain lines, exact figures, for the voice's prompt.
## Each living general: "Tesk Ford: Fought 4 · won 3 · ... Under Tesk bands
## fight 9% harder, ... than under an ordinary general." (leader_commands,
## general_record.gd).
static func generals()->Array:
	var out:Array=[]
	var mc:Variant=_mc()
	if mc==null: return out
	var Commands:=preload("res://scripts/leader_commands.gd")
	var Record:=preload("res://scripts/general_record.gd")
	for leader:Dictionary in Commands.leaders(mc):
		if String(leader.id)==Commands.WAR_LEADER: continue
		var record:=Commands.record(leader)
		out.append("%s: %s. %s" % [String(leader.name),Record.words(record),Record.lever_line(leader.get("commander",{}),String(leader.name))])
	return out

## What each office's holder changes, against an ordinary holder, in the
## engine's numbers: ["Iska, Keeper of Stores: saves 12% of what would rot
## (an ordinary one 0%)", ...] (office_levers.gd).
static func hands()->Array:
	var Levers:=preload("res://scripts/office_levers.gd")
	var out:Array=[]
	for office:Dictionary in GovernmentPeopleSystem.active_offices():
		var key:=String(office.key)
		var holder:Dictionary=WorldSimulation.state.leadership_positions.get(key,{}) if WorldSimulation.state!=null else {}
		if holder.is_empty() or int(holder.get("person_id",0))<=0: continue
		var card:Dictionary=Levers.marshal_card() if key=="Marshal" else Levers.card(key)
		if card.is_empty(): continue
		out.append("%s, %s: %s" % [String(holder.get("name","")),String(office.title),String(card.text).get_slice(" · ",0).to_lower()])
	return out

static func text(s:Dictionary)->String:
	var lines:PackedStringArray=PackedStringArray()
	lines.append("Today: %s. Home: %s, %d people." % [String(s.get("when","")),String(s.get("home","")),int(s.get("home_people",0))])
	var hands_said:Array=s.get("hands",[])
	if not hands_said.is_empty(): lines.append("What the council's hands are worth, against an ordinary holder: %s." % "; ".join(PackedStringArray(hands_said)))
	var wars:Array=s.get("at_war_with",[])
	var peace:Array=s.get("at_peace_with",[])
	var feud_rows:PackedStringArray=PackedStringArray()
	for v:Dictionary in s.get("feuding_with",[]): feud_rows.append(feud_words(v))
	lines.append("At war with: %s.%s At peace with: %s." % [", ".join(PackedStringArray(wars)) if not wars.is_empty() else "nobody",(" In a feud with: %s (a feud, not a war: raids and killings back and forth, nothing declared)." % "; ".join(feud_rows)) if not feud_rows.is_empty() else "",", ".join(PackedStringArray(peace)) if not peace.is_empty() else "nobody we know"])
	var broken_rows:PackedStringArray=PackedStringArray()
	for left:Dictionary in s.get("broken_peoples",[]): broken_rows.append(broken_words(left))
	if not broken_rows.is_empty(): lines.append("Broken, with no town left: %s. No feud with them goes on: they are too few to raid anyone." % "; ".join(broken_rows))
	if s.get("new_towns") is Dictionary: lines.append("New towns: %s." % AutoFounding.court_words(s.new_towns,false))
	var war:=(s.get("offices",[]) as Array).has("war")
	for t:Dictionary in s.get("towns",[]):
		lines.append(_town_line(t,war))
	if war:
		lines.append("Fighters at home: %d." % int(s.get("fighters_at_home",0)))
		var arms:PackedStringArray=PackedStringArray()
		var weapons:Dictionary=s.get("weapons",{})
		for w in weapons: arms.append("%s %d" % [String(w),int(weapons[w])])
		lines.append("Spears in store: %d%s. Called up, waiting for weapons and drill: %d; in training: %d." % [int(s.get("spears",0)),(" (other arms: %s)" % ", ".join(arms)) if not arms.is_empty() else "",int(s.get("recruits",0)),int(s.get("in_training",0))])
		var bands:PackedStringArray=PackedStringArray()
		for b:Dictionary in s.get("bands",[]): bands.append("%s, %d fighters, %s%s (%s)%s" % [String(b.name),int(b.fighters),String(b.where),(", led by "+String(b.leader)) if String(b.leader)!="" else "",String(b.doing),fed_line(b.get("fed",{}))])
		lines.append("Bands out: %s." % ("; ".join(bands) if not bands.is_empty() else "none"))
		var generals_said:Array=s.get("generals",[])
		if not generals_said.is_empty(): lines.append("Our generals: %s" % " ".join(PackedStringArray(generals_said)))
		var gar:PackedStringArray=PackedStringArray()
		for g:Dictionary in s.get("garrisons",[]): gar.append("%s: %d fighters%s%s%s" % [String(g.town),int(g.fighters),(", %d wounded" % int(g.wounded)) if int(g.wounded)>0 else "",(" under "+String(g.commander)) if String(g.commander)!="" else "",fed_line(g.get("fed",{}))])
		lines.append("Garrisons: %s." % ("; ".join(gar) if not gar.is_empty() else "none"))
		var carriers:Dictionary=s.get("carriers",{})
		if int(carriers.get("asked",0))>0:
			lines.append("Carriers: %d on foot, %d carts, %d lorries; they bring %d of the %d loads a day the bands and garrisons ask. Bread goes first: %d%% of the bread arrives, %d%% of the fodder, fuel and rounds." % [int(carriers.porters),int(carriers.carts),int(carriers.lorries),int(carriers.brought),int(carriers.asked),int(carriers.bread),int(carriers.stores)])
		var depots:Dictionary=s.get("depots",{})
		if not depots.is_empty():
			var said:=PackedStringArray()
			for d:Dictionary in depots.get("standing",[]): said.append(String(d.where))
			var line:="Field depots: "+(", ".join(said) if not said.is_empty() else "none yet")+" (we keep %d at most; the line from one starts at half the cost of reaching it)." % int(depots.keep)
			for d:Dictionary in depots.get("laying",[]): line+=" %s is laying one %s, %d days to go." % [String(d.band),String(d.where),int(d.days_left)]
			lines.append(line)
		var replacements:Dictionary=s.get("replacements",{})
		if int(replacements.get("on_road",0))+int(replacements.get("in_training",0))>0:
			lines.append("Replacements for the bands: %d in training at home, %d on the road to them." % [int(replacements.in_training),int(replacements.on_road)])
		if not (s.get("chases",[]) as Array).is_empty(): lines.append("Out on a chase: %s." % "; ".join(PackedStringArray(s.chases)))
		if s.get("defences") is Dictionary: lines.append("Town defences: %s." % preload("res://scripts/home_defense.gd").court_words(s.defences))
		var fights:PackedStringArray=PackedStringArray()
		for b:Dictionary in s.get("battles",[]): fights.append(battle_words(b))
		if not fights.is_empty(): lines.append("Last battles: %s." % "; ".join(fights))
	else:
		# Who won and the captives everyone has seen; the count of the dead is
		# the war leader's, so no one else says it (or makes one up).
		for b:Dictionary in s.get("last_fights",[]): lines.append("The last fight: %s, %s: %s%s; how many died on each side is the war leader's count, not yours." % [String(b.when),String(b.where),"we won" if bool(b.won) else ("we lost" if bool(b.lost) else "nobody won"),("; captives taken %d, %s" % [int(b.captives),String(b.captives_fate)]) if int(b.get("captives",0))>0 else ""])
	if (s.get("offices",[]) as Array).has("stores"):
		var water:Dictionary=s.get("water",{})
		var others:PackedStringArray=PackedStringArray()
		var stock:Dictionary=s.get("stock",{})
		for res in stock: others.append("%d %s" % [int(stock[res]),String(res)])
		lines.append("Stores: %d Food, enough for %s days%s. Water: %d stored, %s days%s." % [int(s.get("food_in_store",0)),str(s.get("food_days",0)),("; also "+", ".join(others)) if not others.is_empty() else "",int(water.get("stored",0)),str(water.get("days",0)),"" if bool(water.get("reachable",true)) else ", and the source is out of reach"])
		lines.append("People: %d; houses for %d. Health: %s. Born this season: %d; died this season: %d." % [int(s.get("people",0)),int(s.get("housing",0)),String(s.get("health","")),int(s.get("births_this_season",0)),int(s.get("deaths_this_season",0))])
		var work:PackedStringArray=PackedStringArray()
		var tasks:Dictionary=s.get("workers_by_task",{})
		for task in tasks: work.append("%s %d" % [String(task).to_lower(),int(tasks[task])])
		if not work.is_empty(): lines.append("At work: %s." % ", ".join(work))
		if s.get("daily_work") is Dictionary: lines.append("Who sets the daily work: %s." % ManualWork.court_words(s.daily_work,false))
		if not (s.get("brought_home",[]) as Array).is_empty(): lines.append("Brought home from towns we took: %s." % "; ".join(PackedStringArray(s.brought_home)))
	if (s.get("offices",[]) as Array).has("tribute"):
		lines.append("Tribute taken: %s." % ("; ".join(PackedStringArray(s.get("tribute_taken",[]))) if not (s.get("tribute_taken",[]) as Array).is_empty() else "none"))
		var ties:PackedStringArray=PackedStringArray()
		for p:Dictionary in s.get("peoples",[]):
			var tie:="%s: treaty %s, trade worth %s a month, pact %s" % [String(p.people),String(p.treaty),str(p.trade),String(p.pact)]
			if bool(p.get("met",false)): tie+="; we send %s; they send %s" % [String(p.get("we_send","nothing")),String(p.get("they_send","nothing"))]
			for key in ["they_lean","we_lean"]:
				if String(p.get(key,""))!="": tie+="; "+String(p[key]).trim_suffix(".")
			if String(p.get("our_stance",""))!="": tie+="; our stance toward them: %s" % String(p.our_stance)
			if String(p.get("their_stance",""))!="": tie+="; %s" % String(p.their_stance).to_lower()
			if String(p.get("tribute",""))!="": tie+="; %s" % String(p.tribute).to_lower()
			ties.append(tie)
		if not ties.is_empty(): lines.append("Peoples: %s." % "; ".join(ties))
	if (s.get("offices",[]) as Array).has("scouts"):
		var out_now:PackedStringArray=PackedStringArray()
		for p:Dictionary in s.get("parties",[]): out_now.append(party_words(p))
		lines.append("Scouting parties out: %s." % ("; ".join(out_now) if not out_now.is_empty() else "none"))
		var met:PackedStringArray=PackedStringArray()
		for p:Dictionary in s.get("met_peoples",[]): met.append("%s (%s%s)" % [String(p.name),"in a feud with us" if bool(p.get("feud",false)) else ("at war with us" if bool(p.at_war) else ("broken, no town of theirs left" if bool(p.get("broken",false)) else "at peace")),"" if bool(p.get("home_known",false)) else ", their home not yet found"])
		lines.append("Peoples we have met: %s." % (", ".join(met) if not met.is_empty() else "none"))
		var places:PackedStringArray=PackedStringArray()
		for t:Dictionary in s.get("known_towns",[]): places.append(town_way_words(t))
		lines.append("Towns we know of: %s." % ("; ".join(places) if not places.is_empty() else "none"))
	var standing:Dictionary=s.get("standing",{})
	if not standing.is_empty():
		var seen:PackedStringArray=PackedStringArray()
		for p:Dictionary in standing.get("peoples",[]):
			var f:Dictionary=p.feelings
			seen.append("the %s: %s Allure %d%%, awe %d%%, fear %d%%, respect %d%%, trust %d%%, resentment %d%%; envy %d%%, contempt %d%%. %s.%s" % [String(p.name),String(p.headline),int(f.get("allure",0)),int(f.get("awe",0)),int(f.get("fear",0)),int(f.get("respect",0)),int(f.get("trust",0)),int(f.get("resentment",0)),int(p.envy),int(p.contempt),String(p.strength),(" "+"; ".join(PackedStringArray(p.does))+".") if not (p.does as Array).is_empty() else ""])
		lines.append("What we are: %s How the peoples we know see us: %s" % [String(standing.get("posture","")),(" | ".join(seen)) if not seen.is_empty() else "we have met no other people."])
	# What every official knows: how the people hold the god, and the council.
	var regard:Dictionary=s.get("people_regard",{})
	if not regard.is_empty(): lines.append("The people: %s (love %s, dread %s)." % [String(regard.get("read","")),String(regard.get("love","")),String(regard.get("dread",""))])
	var council:PackedStringArray=PackedStringArray()
	for c:Dictionary in s.get("council",[]): council.append("%s %s" % [String(c.title),String(c.name)])
	if not council.is_empty(): lines.append("Council: %s.%s" % ["; ".join(council),(" Set aside: %s." % "; ".join(PackedStringArray(s.set_aside))) if not (s.get("set_aside",[]) as Array).is_empty() else ""])
	var out:="\n".join(lines)
	return out if out.length()<=MAX_CHARS else out.substr(0,MAX_CHARS)+"..."

## "once", "twice", "3 times".
static func times_words(n:int)->String:
	return "once" if n==1 else ("twice" if n==2 else "%d times" % n)

## One feud in plain words, exact, from the war ledger (war_loop.feud_view):
## "Esurai (since the spring of Year 94; their raiders have come 3 times; we
## have struck back twice; 4 of ours and 6 of theirs dead; the last blood in
## the autumn of Year 95; their home not yet found)".
static func feud_words(v:Dictionary)->String:
	var bits:=PackedStringArray()
	if int(v.get("since",-1))>=0 and int(v.get("days",0))>0: bits.append("since %s" % _in_season(int(v.since)).trim_prefix("in "))
	if bool(v.get("open_fight",false)): bits.append("our own band is out against them")
	if int(v.get("raids",0))>0: bits.append("their raiders have come %s" % times_words(int(v.raids)))
	if int(v.get("strikes",0))>0: bits.append("we have struck back %s" % times_words(int(v.strikes)))
	if int(v.get("our_dead",0))+int(v.get("their_dead",0))>0: bits.append("%d of ours and %d of theirs dead" % [int(v.get("our_dead",0)),int(v.get("their_dead",0))])
	if int(v.get("last_harm",-1))>=0: bits.append("the last blood %s" % _in_season(int(v.last_harm)))
	if not bool(v.get("hot",true)): bits.append("quiet now")
	bits.append("their home not yet found" if not bool(v.get("home_known",false)) else ("their home %s" % String(v.way) if String(v.get("way",""))!="" else "their home known"))
	return "%s (%s)" % [String(v.get("name","")),"; ".join(bits)]

## A people broken past feuding (war_loop.survivors), exact: "Oruq (Iglan is
## ash or ours; one of them lives, in the hills)".
static func broken_words(left:Dictionary)->String:
	var bits:=PackedStringArray()
	var lost:Array=left.get("towns_lost",[])
	if not lost.is_empty(): bits.append("%s %s ash or ours" % [" and ".join(PackedStringArray(lost)),"is" if lost.size()==1 else "are"])
	var living:=int(left.get("living",0))
	bits.append("none of them lives" if living<=0 else ("one of them lives, in the hills" if living==1 else "%d of them live, in the hills" % living))
	return "%s (%s)" % [String(left.get("name","")),"; ".join(bits)]

## One fight in plain words, exact: who won, the dead on each side, the
## captives and what became of them, the spoils and where they went.
static func battle_words(b:Dictionary)->String:
	var out:="%s, %s: %s; our dead %d, theirs %d" % [String(b.get("when","")),String(b.get("where","")),"we won" if bool(b.get("won",false)) else ("we lost" if bool(b.get("lost",false)) else "nobody won"),int(b.get("our_dead",0)),int(b.get("their_dead",0))]
	if int(b.get("captives",0))>0: out+="; captives taken %d, %s" % [int(b.captives),String(b.get("captives_fate",""))]
	if String(b.get("spoils",""))!="": out+="; spoils %s, %s" % [String(b.spoils),String(b.get("spoils_went",""))]
	return out

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

## One scouting party in plain words: "6 scouts to the north, out 3 days,
## back in about 27".
static func party_words(p:Dictionary)->String:
	var where:=String(p.get("heading",""))
	var toward:=("to the "+where) if where!="" else ("toward "+String(p.get("toward",""))) if String(p.get("toward",""))!="" else "out"
	var out_days:=int(p.get("out_days",0))
	return "%d scouts %s, %s, back in about %d days" % [int(p.get("scouts",0)),toward,"setting out today" if out_days<=0 else ("out a day" if out_days==1 else "out %d days" % out_days),int(p.get("back_in",0))]

## One town in plain words: "Tsaren (Esurai), about 22 km west".
static func town_way_words(t:Dictionary)->String:
	var way:=("about %d km %s" % [int(t.km),String(t.get("way",""))]).strip_edges() if t.has("km") else "we do not know the way yet"
	return "%s (%s%s), %s" % [String(t.get("name","")),String(t.get("people","")),", ours now" if bool(t.get("held",false)) else "",way]

static func _group_words(by:Dictionary)->String:
	var parts:PackedStringArray=PackedStringArray()
	for g in by: parts.append("%s %d" % [String(g),int(by[g])])
	return ", ".join(parts)
