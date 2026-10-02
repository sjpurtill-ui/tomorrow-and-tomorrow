extends RefCounted
## ORDERS BY OFFICE: what the official before the god carries out, offered as
## a few plain choices, each with at most one blank (a number, a town, a
## direction, a people). The user chose this (2026-09-29): "I don't mind
## making the player do a tiny bit of work, but not that much." Typing still
## works for anything.
##
## Every choice is the same plain words the god could type, so it reaches the
## same engine by the same path (court_commands.hear: home_orders.gd,
## realm_orders.gd, court_war_orders.gd), and the court answers it the same
## way. Choices are built from real state: the towns and peoples we know, the
## weapons our workshops can make, whether a band is away. An office's
## business falls to the Headman (Steward) while it stands vacant, so every
## order stays within reach.
##
##   menus(audience_id) -> [{label, name, items:[{label, text}]} or
##                          {label, name, text}]
## Static; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")

## Which business each office carries.
## The realm's purse is the Treasurer's (court_purse_orders.gd), the
## Headman's while no Treasurer is named. Trade with other peoples
## (court_trade.gd) is the Envoy's, the Headman's while no Envoy holds
## office.
const FAMILIES:={"Marshal":"war","Quartermaster":"stores","Steward":"town","ChiefScout":"scouting","Scholar":"learning","Treasurer":"purse","Envoy":"trade"}
const FAMILY_ORDER:=["war","stores","town","purse","trade","scouting","learning"]
const PurseOrders:=preload("res://scripts/court_purse_orders.gd")
## The stance on business goes with the purse (court_business_orders.gd).
const BusinessOrders:=preload("res://scripts/court_business_orders.gd")
const Trade:=preload("res://scripts/court_trade.gd")


## The office of the one before the god: an official's own, the war leader of
## renown's (war), or "" for anyone who holds none.
static func office_of(audience_id:String)->String:
	var audience:=Hall.find(audience_id)
	if audience.is_empty() or String(audience.get("origin",""))!="court": return ""
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
	var pid:=int(speaker.get("person_id",0))
	if pid>0:
		var official:=Hall._official(pid)
		var office:=String(official.get("office_key",""))
		if FAMILIES.has(office): return office
	if String(speaker.get("figure_id",""))!="" or String(speaker.get("role",""))=="figure":
		var general:=WarOrders.war_leader({"figure_id":String(speaker.get("figure_id",""))})
		if not general.is_empty(): return "Marshal"
	return ""


## The families of business this office answers for: its own, and, for the
## Headman, every office that stands vacant.
static func families(office:String)->Array:
	var out:Array=[]
	if not FAMILIES.has(office): return out
	out.append(String(FAMILIES[office]))
	if office=="Steward":
		for other in FAMILIES:
			if String(other)=="Steward": continue
			if WorldSimulation.government==null or (WorldSimulation.government.officeholder(String(other)) as Dictionary).is_empty():
				if not out.has(String(FAMILIES[other])): out.append(String(FAMILIES[other]))
	var ordered:Array=[]
	for f in FAMILY_ORDER:
		if out.has(f): ordered.append(f)
	return ordered


static func menus(audience_id:String)->Array:
	var out:Array=[]
	for family in families(office_of(audience_id)):
		match String(family):
			"war": out.append_array(_war())
			"stores": out.append_array(_stores())
			"town": out.append_array(_town())
			"trade": out.append_array(_trade())
			"scouting": out.append_array(_scouting())
			"learning": out.append_array(_learning())
			"purse":
				out.append_array(PurseOrders.menus())
				out.append_array(BusinessOrders.menus())
	return out


static func _menu(label:String,name:String,items:Array)->Dictionary:
	return {"label":label+" ▾","name":name,"items":items}

static func _item(label:String,text:String)->Dictionary:
	return {"label":label,"text":text}

static func _one(label:String,name:String,text:String)->Dictionary:
	return {"label":label,"name":name,"text":text}


# --- The war chief ---------------------------------------------------------------

static func _war()->Array:
	var out:Array=[]
	var levy:Array=[]
	for n in [3,5,10,20]: levy.append(_item("%d fighters" % n,"Recruit %d levies, train them and arm them" % n))
	out.append(_menu("Raise a levy","RaiseLevy",levy))
	out.append(_menu("Drill","Drill",[_item("Hard","Drill the army hard"),_item("As before","Train the army as before"),_item("Lightly","Train the fighters lightly"),_item("Stop","Stop all training")]))
	out.append(_one("Camp drill","CampDrill","Hold a camp drill for the fighters at home"))
	# The stance toward each people we fight, as the War screen gives it: the
	# war council carries it out with the real army (war_council.gd). The war
	# leader sees to who goes, the road and the fight.
	var toward:Array=[]
	var war_loop:GDScript=load("res://scripts/war_loop.gd")
	if WorldSimulation.world!=null:
		for c in WorldSimulation.world.civilizations:
			if not c is Dictionary or String((c as Dictionary).get("id",""))=="player" or not bool((c as Dictionary).get("alive",true)): continue
			var id:=String((c as Dictionary).get("id",""))
			var rel:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
			if not bool(rel.get("at_war",false)) and not bool(war_loop.call("feuding",id)): continue
			var people:=String((c as Dictionary).get("name",""))
			if people=="": continue
			var the:="the "+people.trim_prefix("The ").trim_prefix("the ")
			toward.append(_item("%s: defend" % people,"Defend us against %s" % the))
			toward.append(_item("%s: punish" % people,"Punish %s" % the))
			toward.append(_item("%s: seek peace" % people,"Make peace with %s" % the))
			if toward.size()>=12: break
	if not toward.is_empty(): out.append(_menu("Toward them","Toward",toward))
	var strike:Array=[]
	for town in WarOrders.known_places():
		var name:=String((town as Dictionary).get("name","")).trim_prefix("Reported home of ")
		if name=="": continue
		strike.append(_item("Take %s" % name,"Take %s" % name))
		strike.append(_item("Raid %s's fields" % name,"Raid the fields of %s" % name))
		if strike.size()>=10: break
	if not strike.is_empty(): out.append(_menu("Strike","Strike",strike))
	out.append(_one("Keep the soldiers home","GuardCamp","Defend our home with the soldiers"))
	if WorldSimulation.military!=null and not (WorldSimulation.military.field_armies as Array).is_empty():
		out.append(_one("Bring the bands home","BandsHome","Bring all the bands home"))
	# Assassins and sabotage: the war leader carries a killing (covert_orders.gd).
	var strike_covert:Array=[]
	for p:Dictionary in _covert_peoples():
		var bare:=String(p.name)
		strike_covert.append(_item("%s: assassin (as an envoy)" % bare,"Send an assassin to %s disguised as an envoy to strike at their leaders" % bare))
		strike_covert.append(_item("%s: sabotage their stores" % bare,"Sabotage %s's stores" % bare))
		if strike_covert.size()>=10: break
	if not strike_covert.is_empty(): out.append(_menu("Assassins","Assassins",strike_covert))
	return out


## The peoples a covert order could name: those we know, bare (no "the", so
## the covert reader resolves the possessive cleanly).
static func _covert_peoples()->Array:
	var out:Array=[]
	if WorldSimulation.world==null: return out
	for c in WorldSimulation.world.civilizations:
		if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
		var rel:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
		if int(rel.get("contact_level",0))<1: continue
		var name:=String((c as Dictionary).get("name","")).trim_prefix("The ").trim_prefix("the ")
		if name!="": out.append({"name":name})
	return out


# --- The keeper of stores --------------------------------------------------------

## The weapons our workshops can make now: [item, the word for it].
static func _weapons()->Array:
	var out:Array=[["improvised","clubs"]]
	var mc:Variant=WorldSimulation.military
	if mc==null: return out
	for pair in [["spear","spears"],["bow","bows"],["sword_shield","swords and shields"]]:
		var quote:Dictionary=mc.equipment_production_quote(String(pair[0]),1)
		if not quote.has("error") or "production lines" in String(quote.get("error","")) or String(quote.get("error","")).begins_with("Insufficient"): out.append(pair)
	return out


static func _stores()->Array:
	var out:Array=[]
	var keep:Array=[]
	var make:Array=[]
	for pair in _weapons():
		keep.append(_item("20 %s" % String(pair[1]),"Keep 20 %s in store" % String(pair[1])))
		make.append(_item("10 %s" % String(pair[1]),"Make 10 %s" % String(pair[1])))
	out.append(_menu("Keep in store","KeepInStore",keep))
	out.append(_menu("Make","Make",make))
	out.append(_one("Stop making weapons","StopMaking","Stop making weapons"))
	out.append(_menu("Rations","Rations",[_item("Ration the food","Ration the food"),_item("End the ration","Stop rationing")]))
	out.append(_one("Lay in food","LayInFood","Store more food for the winter"))
	var carts:Array=[]
	for n in [1,2,4]: carts.append(_item("%d %s" % [n,"cart" if n==1 else "carts"],"Build %d %s" % [n,"cart" if n==1 else "carts"]))
	out.append(_menu("Build carts","Carts",carts))
	out.append(_one("Mend weapons","Mend","Mend the broken weapons"))
	return out


# --- The headman -----------------------------------------------------------------

const TASKS:=[["food","food"],["building","building"],["making","making"],["carrying","carrying"],["the watch","the watch"],["learning","learning"]]

static func _town()->Array:
	var out:Array=[]
	out.append(_menu("Build","Build",[_item("Homes","Build more homes"),_item("A granary","Build a granary"),_item("A wall","Build a wall around the town"),_item("A hall","Build a hall"),_item("A work area","Build a work area")]))
	out.append(_menu("Found a town","FoundTown",[_item("Where our leaders think best","Found a new town"),_item("By the river","Found a new town by the river")]))
	var moves:Array=[]
	for task in TASKS: moves.append(_item("5 more on %s" % String(task[0]),"Put 5 more on %s" % String(task[1])))
	moves.append(_item("Let our leaders set the work","Let the headman decide the work again"))
	out.append(_menu("Move workers","MoveWorkers",moves))
	out.append(_menu("The town's work","TownWork",[_item("Building shelter","Turn the town to building shelter"),_item("Food","Turn the town to food"),_item("Water","Turn the town to water"),
		_item("Holding the ground","Turn the town to defence"),_item("Our leaders decide","Let the leaders run the town again")]))
	out.append(_menu("Strangers","Strangers",[_item("Welcome them","Let strangers settle among us"),_item("Turn them away","Keep strangers out of our town")]))
	out.append(_menu("Our knowledge","Knowledge",[_item("Share it","Share what we know with our neighbours"),_item("Keep it","Keep our knowledge to ourselves")]))
	out.append(_menu("The sick","Sick",[_item("Keep them apart","Keep the sick apart from everyone else"),_item("Clean water only","Only drink clean water")]))
	var envoys:Array=[]
	if WorldSimulation.world!=null:
		for c in WorldSimulation.world.civilizations:
			if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
			var rel:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
			if int(rel.get("contact_level",0))<1: continue
			var people:=String((c as Dictionary).get("name",""))
			if people=="": continue
			var the:="the "+people.trim_prefix("The ").trim_prefix("the ")
			envoys.append(_item("%s: talk" % people,"Send an envoy to %s" % the))
			# Trade and gifts are the trade family's buttons (court_trade.gd).
			if bool(rel.get("at_war",false)): envoys.append(_item("%s: ask for peace" % people,"Send envoys to %s to ask for peace" % the))
			else: envoys.append(_item("%s: declare war" % people,"Declare war on %s" % the))
			if envoys.size()>=16: break
	if not envoys.is_empty(): out.append(_menu("Envoys","Envoys",envoys))
	return out


# --- The messenger: trade with other peoples ----------------------------------------

static func _trade()->Array:
	return Trade.menus()


# --- The chief scout ------------------------------------------------------------

static func _scouting()->Array:
	var out:Array=[]
	var ways:Array=[]
	for way in ["north","northeast","east","southeast","south","southwest","west","northwest"]: ways.append(_item(String(way).capitalize(),"Send scouts to the %s" % way))
	out.append(_menu("Send a party","SendParty",ways))
	out.append(_menu("Scouting","Scouting",[_item("More","Put more people on scouting"),_item("Less","Put fewer people on scouting"),_item("None","Stop sending scouts out")]))
	out.append(_menu("Look for","LookFor",[_item("Wandering bands","Look for wandering bands who might join us"),_item("Stone and ore","Search for stone and ore")]))
	# Spies: the Pathfinder's eyes abroad (covert_orders.gd).
	var spy:Array=[]
	for p:Dictionary in _covert_peoples():
		var bare:=String(p.name)
		spy.append(_item("Watch %s" % bare,"Send spies to %s" % bare))
		spy.append(_item("Steal %s's craft" % bare,"Steal %s's secrets" % bare))
		if spy.size()>=10: break
	if not spy.is_empty(): out.append(_menu("Spies","Spies",spy))
	return out


# --- The scholar ---------------------------------------------------------------

const FIELDS:=[["Getting food","food"],["Healing","healing"],["War and defence","war"],["Building","building"],["Crafts","crafts"],["Travel and carrying","travel"],
	["The land and seasons","the land and seasons"],["Law and custom","law"],["Song and stories","songs and stories"],["Counting and records","counting and records"],["Families","families and children"]]

static func _learning()->Array:
	var fields:Array=[]
	for f in FIELDS: fields.append(_item(String(f[0]),"Focus our learning on %s" % String(f[1])))
	return [_menu("Study","Study",fields)]


# --- The closest orders ---------------------------------------------------------

const STOP_WORDS:=["the","a","an","and","of","to","on","in","for","our","we","us","me","my","you","your","them","their","they","it","all","some","more","with","from","that","this","now","please","let","have","make","get","put","take","give","go","do","be","is","are","will","shall","must","should","would","want","need","hold","keep","turn","stop","look","search","focus","bring","set","start","begin","tell","ask","order","everyone","people","men","sure","always","again","new"]

## The orders of every office closest to the words said, best first, at most
## `count`: {label, text, menu}. Offered when the court could not carry the
## words out as a real mechanic, so the god can pick instead of rephrasing.
static func closest(words:String,count:int=3)->Array:
	var wanted:=_stems(words)
	if wanted.is_empty(): return []
	var scored:Array=[]
	for family in [_war(),_stores(),_town(),_trade(),_scouting(),_learning(),PurseOrders.menus(),BusinessOrders.menus()]:
		for menu:Dictionary in family:
			var items:Array=(menu.items as Array) if menu.has("items") else [{"label":String(menu.label),"text":String(menu.text)}]
			for item:Dictionary in items:
				var have:=_stems("%s %s %s" % [String(menu.label),String(item.label),String(item.text)])
				var hits:=0
				for w in wanted:
					if have.has(w): hits+=1
				if hits==0: continue
				var score:=float(hits)/float(wanted.size())+float(hits)*0.05
				var menu_word:=String(menu.label).trim_suffix(" ▾")
				scored.append({"score":score,"label":("%s: %s" % [menu_word,String(item.label)]) if menu.has("items") else String(menu.label),"text":String(item.text)})
	scored.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return float(x.score)>float(y.score))
	var out:Array=[]
	var seen:={}
	for s in scored:
		if float(s.score)<0.34 or seen.has(String(s.text)): continue
		seen[String(s.text)]=true
		out.append(s)
		if out.size()>=count: break
	return out


static func _stems(text:String)->Array:
	var out:Array=[]
	var re:=RegEx.create_from_string("[a-z]+")
	for m in re.search_all(text.to_lower()):
		var w:=m.get_string()
		if w.length()<3 or STOP_WORDS.has(w): continue
		for tail in ["ing","ies","es","s","ed"]:
			if w.length()>tail.length()+3 and w.ends_with(tail): w=w.substr(0,w.length()-tail.length());break
		if not out.has(w): out.append(w)
	return out
