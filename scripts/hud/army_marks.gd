extends RefCounted
## ARMY MARKS: how a force is drawn and named on the inked war chart.
##
## Pure and static. The war-front overlay asks this layer what a force is
## called, which mark it gets, how large to draw it at the current zoom,
## what its paper card says, and which marks give way when the chart is
## crowded. Nothing here reads the world; the overlay passes plain values.
##
## Marks evolve with the size of the force and with what its people know:
##   band       a spear tally (a few spears bound together): war bands and
##              war parties of the first ages;
##   host       a leader's standard: a pole, a crossbar and a streamer;
##   army       a framed standard with its arm's symbol on the cloth, as the
##              drilled armies of the lettered ages carried;
##   formation  a staff-map box with the branch symbol and echelon strokes,
##              once rifles, machine guns or motors are in the field.
## Owner colour is used only as a small accent (a streamer, a wash on the
## cloth or in the box); the marks themselves are iron-gall ink.
##
## Words are plain and fit the era (hud/era_words.gd stages): a band of
## twelve, a war party, a host, an army, a corps; the strength rounded the
## way a clerk would say it ("about 30,000"); the general's name; what the
## force is doing ("marching on Tsaren", "holding the line"); and how old
## the report is, only when that matters ("reported three days ago").

const EraWords:=preload("res://scripts/hud/era_words.gd")

const MAX_OURS:=12
const MAX_THEIRS:=24
## Card budgets per zoom band (cards beyond these are left to the note).
const CARDS:={"ground":6,"local":6,"regional":4}
## Reports younger than this are fresh and say nothing about their age.
const FRESH_DAYS:=2
## Reports this old are drawn as stale: faded, with a dashed ring, as the
## front's stale stretches are dashed.
const STALE_DAYS:=20
## Placeholder commander names that are not a person.
const UNNAMED:=["","field staff","the field staff","commander","staff"]
## A force is at home only when it stands at the home settlement, whatever
## its record says (a band camped 25 km out once kept location "player_home").
const HOME_RADIUS_KM:=2.0
const GENERIC_PLACES:=["","marked ground","commanded ground","destination","field position","the field","home","objective"]


# --- Words -------------------------------------------------------------------------

## The right noun for a force of this size, in the words its age would use.
## era: 0 before powder, 1 powder, 2 rifles and machine guns, 3 motors and
## armour (warfare_map_presentation.formation_era). corps_known: the people
## know how to form corps (professional corps or military staffs).
static func noun(troops:int,stage:String,era:int=0,corps_known:bool=false)->String:
	if troops<50: return "band"
	if troops<250: return "war party"
	match stage:
		"hearth": return "great host" if troops>=5000 else "host"
		"lettered": return "army" if troops>=5000 else "host"
	if era>=2:
		if troops<1500: return "battalion"
		if troops<5000: return "brigade"
		if troops<20000: return "division"
		if troops<60000: return "corps"
		return "army"
	if troops<5000: return "regiment" if era>=1 else "host"
	if troops>=20000 and troops<60000 and corps_known: return "corps"
	return "army"


## Which mark a force gets.
static func kind(troops:int,stage:String,era:int=0,staffs_known:bool=false)->String:
	if era>=2 or (stage=="reckoned" and staffs_known and troops>=1000): return "formation"
	if troops<250: return "band"
	if stage=="hearth" or troops<5000: return "host"
	return "army"


## Spears in a band's tally: more spears for a bigger band.
static func tally(troops:int)->int:
	if troops<25: return 2
	if troops<60: return 3
	if troops<120: return 4
	return 5


## Echelon strokes above a staff-map box: X brigade, XX division, XXX corps,
## XXXX army (as on the staff maps of the rifle age).
static func echelon_marks(troops:int)->int:
	if troops<5000: return 1
	if troops<20000: return 2
	if troops<60000: return 3
	return 4


## The branch of arms a mark shows, from the formation's leading arm.
static func branch(role:String,unit:String="")->String:
	match unit:
		"cavalry": return "horse"
		"skirmisher","archer","slinger": return "missile"
		"siege_engineer": return "engineers"
		"field_artillery","modern_artillery": return "guns"
		"motorized_infantry": return "motor"
		"armored_formation": return "armour"
	match role:
		"mobile": return "horse"
		"artillery": return "guns"
		"armored": return "armour"
	return "foot"


## A count said the way a clerk would say it: exact when small, then
## rounded ("about 35", "about 6,200", "about 30,000", "about 1.2 million").
static func about(n:int)->String:
	n=maxi(0,n)
	if n<=20: return str(n)
	var step:=5
	if n>=1_000_000_000:
		return "about %s billion" % ("%.1f" % snappedf(float(n)/1_000_000_000.0,0.1)).trim_suffix(".0")
	if n>=1_000_000:
		var millions:=snappedf(float(n)/1_000_000.0,0.1)
		var text:=("%.1f" % millions).trim_suffix(".0")
		return "about %s million" % text
	if n>=100_000: step=10_000
	elif n>=10_000: step=1000
	elif n>=1000: step=100
	elif n>=100: step=10
	return "about %s" % EraWords.grouped(roundi(float(n)/float(step))*step)


## An estimate of their strength: one figure when the scouts agree, a
## plain range when they do not ("900 to 1,500").
static func about_range(low:int,high:int)->String:
	low=maxi(0,low); high=maxi(low,high)
	if high<=0: return "numbers unknown"
	if low<=0 or float(high)<=float(low)*1.3: return about(roundi(float(low+high)*0.5) if low>0 else high)
	return "%s to %s" % [about(low).trim_prefix("about "),about(high).trim_prefix("about ")]


## How old a report is, in words, only when it matters ("" when fresh).
static func age_words(days:int,verb:String="reported")->String:
	if days<FRESH_DAYS: return ""
	if days<=12: return "%s %s days ago" % [verb,EraWords.count_word(days)]
	if days<45: return "%s %d days ago" % [verb,days]
	var months:=roundi(float(days)/30.0)
	return "%s about %s months ago" % [verb,EraWords.count_word(months)]


## A place name as a person would say it ("TSAREN" -> "Tsaren").
static func place(name:String)->String:
	var text:=name.strip_edges()
	if text=="": return ""
	if text==text.to_upper():
		var words:=PackedStringArray()
		for word in text.to_lower().split(" ",false): words.append(word.substr(0,1).to_upper()+word.substr(1))
		text=" ".join(words)
	return text


static func _generic_place(name:String)->bool:
	return GENERIC_PLACES.has(name.strip_edges().to_lower())


## How far a force stands from home, in km, or -1 when it has no position.
static func home_km(record:Dictionary,home:Vector2)->float:
	var p:Variant=record.get("position",null)
	if not p is Dictionary or not (p as Dictionary).has_all(["x","z"]) or not home.is_finite(): return -1.0
	return Vector2(float(p.x),float(p.z)).distance_to(home)


## Stationed at the home settlement itself.
static func at_home(record:Dictionary,home:Vector2)->bool:
	if String(record.get("status","stationed"))!="stationed": return false
	var km:=home_km(record,home)
	if km<0.0: return String(record.get("location_id",""))=="player_home"
	return km<HOME_RADIUS_KM


## "about 25 km" for a camp's distance from home.
static func km_words(km:float)->String:
	var n:=roundi(km)
	if n>=20: n=roundi(km/5.0)*5
	return "about %s km" % EraWords.grouped(n)


## Compass words for a heading on the map (+x east, +z south).
static func compass(delta:Vector2)->String:
	if delta.length_squared()<0.000001: return ""
	var names:=["east","south-east","south","south-west","west","north-west","north","north-east"]
	var angle:=fposmod(delta.angle(),TAU)
	return names[roundi(angle/(TAU/8.0))%8]


## What a force of ours is doing, in plain words. context: {status,
## destination_name, destination_id, location_name, command_status,
## withdrawing, besieging (place name or ""), fighting, delta (Vector2 to its
## objective), at_home}.
static func doing(context:Dictionary)->String:
	if bool(context.get("fighting",false)): return "in battle"
	if bool(context.get("withdrawing",false)): return "falling back home"
	var besieging:=String(context.get("besieging",""))
	if besieging!="": return "besieging %s" % place(besieging) if not _generic_place(besieging) else "laying siege"
	var status:=String(context.get("command_status","")).to_lower()
	if String(context.get("status",""))=="moving":
		var target:=String(context.get("destination_name",""))
		if String(context.get("destination_id",""))=="player_home": return "marching home"
		if target.to_upper().begins_with("INTERCEPT"):
			var who:=target.get_slice("·",1).strip_edges() if "·" in target else ""
			if who=="" or who.to_upper()=="FOREIGN FORMATION": return "going after a host that was seen"
			return "going after %s" % place(who)
		var days_left:=int(context.get("days_left",0))
		if not _generic_place(target): return "marching on %s%s" % [place(target),", %d %s out" % [days_left,"day" if days_left==1 else "days"] if days_left>0 else ""]
		var heading:=compass(context.get("delta",Vector2.ZERO))
		return "marching %s" % heading if heading!="" else "on the march"
	var plain:=_plain_status(status)
	if plain!="": return plain
	var where:=String(context.get("location_name",""))
	var km:=float(context.get("home_km",-1.0))
	var homely:=_generic_place(where) or where.strip_edges().to_lower() in ["home settlement","home"]
	if bool(context.get("at_home",false)) or (homely and km>=0.0 and km<HOME_RADIUS_KM) or (km<0.0 and where.strip_edges().to_lower()=="home"): return "at home"
	if homely and km>=HOME_RADIUS_KM: return "camped %s from home" % km_words(km)
	if not _generic_place(where): return "holding at %s" % place(where)
	return "holding its ground"


## The staff's own command notes (land_command.gd), said plainly.
static func _plain_status(status:String)->String:
	if status=="": return ""
	var table:=[
		["withdrawing","falling back home"],["escape routes cut","fighting, their way out cut"],["engaging","fighting"],
		["investing city","laying siege"],["pressing enemy front","pressing their line"],["holding contact","holding the line, asking for help"],
		["front contested","holding the line"],["close escape routes","closing the ring"],["flank blocked","probing their line"],
		["patrolling","watching its ground"],["assembling","gathering"],["holding occupied city","holding the town it took"],
		["neutral border","halted at the border"],["no land route","looking for a way through"],["awaiting reconnaissance","waiting for the scouts"],
		["searching zone","searching for them"],["holding city approaches","holding the approaches"],["attacking city","storming the town"],
		["preparing objective","making ready"],["orders cancelled","holding its ground"],["holding approach","holding the approaches"],
	]
	for row in table:
		if String(row[0]) in status: return String(row[1])
	return ""


static func _named(general:String)->String:
	var name:=general.strip_edges()
	if UNNAMED.has(name.to_lower()): return ""
	return name.get_slice(" ",0)


static func _article(word:String)->String:
	return "an" if word.substr(0,1) in ["a","e","i","o","u"] else "a"


## The card for a town we hold: "Held by us · 17" over whose garrison it is.
static func card_garrison(mark:Dictionary)->PackedStringArray:
	var troops:=int(mark.get("troops",0))
	var general:=_named(String(mark.get("general","")))
	var town:=place(String(mark.get("town","the town")))
	var out:=PackedStringArray(["Held by us · %s" % (str(troops) if troops<1000 else about(troops)),("%s's garrison in %s" % [general,town]) if general!="" else "our garrison in %s" % town])
	# The last order carried out there ("36 killed, 80 captives on the road").
	var note:=String(mark.get("fate_note","")).strip_edges()
	if note!="": out.append(note)
	return out


## The paper card for one of our forces: [title, detail].
## mark: {troops, noun, name, general, doing, condition, report_age, members, members_troops}
static func card_ours(mark:Dictionary)->PackedStringArray:
	var members:=int(mark.get("members",1))
	var troops:=int(mark.get("members_troops",mark.get("troops",0))) if members>1 else int(mark.get("troops",0))
	var word:=String(mark.get("noun","host"))
	var title:=""
	if members>1:
		title="%s of ours, %s in all" % [_plural(word,members),about(troops)]
	else:
		var general:=_named(String(mark.get("general","")))
		var name:=String(mark.get("name","")).strip_edges()
		if general!="": title="%s's %s, %s" % [general,word,about(troops)]
		elif name!="" and name.to_lower().ends_with(word): title="%s, %s" % [name,about(troops)]
		elif name!="": title="%s: %s %s of %s" % [name,_article(word),word,about(troops)]
		else: title="Our %s, %s" % [word,about(troops)]
	var detail:=PackedStringArray()
	var doing_text:=String(mark.get("doing",""))
	if doing_text!="" and members<=1: detail.append(doing_text)
	var hurt:=condition(String(mark.get("condition","intact")))
	if hurt!="" and members<=1: detail.append(hurt)
	var age:=age_words(int(mark.get("report_age",0)))
	if age!="": detail.append(age)
	return PackedStringArray([title,_sentence(" · ".join(detail))])


static func _sentence(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)


## The paper card for a force of theirs, from what was seen: [title, detail].
## mark: {low, high, noun, owner, moving, condition, age_days, members, scout}
static func card_theirs(mark:Dictionary)->PackedStringArray:
	var members:=int(mark.get("members",1))
	var word:=String(mark.get("noun","host"))
	var owner:=String(mark.get("owner","")).strip_edges()
	var who:=("%s %s" % [owner,word]) if owner!="" else ("Their %s" % word)
	if bool(mark.get("scout",false)): who=("%s scouts" % owner) if owner!="" else "Strangers' scouts"
	var strength:=about_range(int(mark.get("low",0)),int(mark.get("high",0)))
	var title:="%s, %s" % [who,strength]
	if members>1: title="%s of theirs, %s in all" % [_plural(word,members),strength]
	var parts:=PackedStringArray()
	if bool(mark.get("moving",false)): parts.append("on the move")
	var hurt:=condition(String(mark.get("condition","intact")))
	if hurt!="" and members<=1: parts.append("looked "+hurt)
	var age:=age_words(int(mark.get("age_days",0)),"seen")
	if age!="": parts.append(age)
	return PackedStringArray([title,_sentence(" · ".join(parts))])


## A force's wear in a word or two ("" when it is whole).
static func condition(state:String)->String:
	match state:
		"worn": return "worn"
		"damaged": return "badly mauled"
		"shattered": return "shattered"
	return ""


static func _plural(word:String,count:int)->String:
	var plural:={"band":"bands","war party":"war parties","host":"hosts","great host":"great hosts","army":"armies","corps":"corps",
		"regiment":"regiments","battalion":"battalions","brigade":"brigades","division":"divisions"}
	return "%s %s" % [EraWords.count_word(count).capitalize(),String(plural.get(word,word+"s"))]


# --- Size and crowding (screen space) ---------------------------------------------------

## How strongly an old sighting is drawn: a fresh one in full ink, fading as
## it ages (never below a third, so a dated mark is still findable).
static func fade(days:int)->float:
	return clampf(1.0-float(days)/90.0,0.35,1.0)


## Mark height in screen pixels for a zoom band. Constant on screen within a
## band, so a mark never swells over a small front as the view pulls back.
static func size_px(band:String,mark_kind:String)->float:
	var base:float={"band":22.0,"host":26.0,"army":30.0,"formation":28.0}.get(mark_kind,24.0)
	match band:
		"ground","local": return base
		"regional": return roundf(base*0.8)
		"continental": return maxf(12.0,roundf(base*0.55))
	return 0.0


## Which marks are drawn, where, and which carry a card. Pure over screen
## positions. marks: [{id, side ("ours"/"theirs"), at, priority, kind,
## size, army_id?, selected?}]. context: {band, bounds:Rect2, fronts:
## [PackedVector2Array], echelons:[{at, armies}], home:Vector2}.
## Returns {drawn:[{... , at, anchor, members:[ids], moved}], hidden:{id:reason}}.
static func layout(marks:Array,context:Dictionary)->Dictionary:
	var band:=String(context.get("band","local"))
	var hidden:Dictionary={}
	var drawn:Array=[]
	if band=="world":
		for mark in marks: hidden[String(mark.id)]="band"
		return {"drawn":drawn,"hidden":hidden}
	var bounds:Rect2=context.get("bounds",Rect2(-1e6,-1e6,2e6,2e6))
	var fronts:Array=context.get("fronts",[])
	var echelons:Array=context.get("echelons",[])
	var home:Vector2=context.get("home",Vector2.INF)
	var ordered:=marks.duplicate()
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if int(a.get("priority",0))!=int(b.get("priority",0)): return int(a.get("priority",0))>int(b.get("priority",0))
		return String(a.id)<String(b.id))
	var ours_kept:=0; var theirs_kept:=0
	for mark:Dictionary in ordered:
		var at:Vector2=mark.get("at",Vector2.INF)
		var id:=String(mark.id)
		if not at.is_finite() or not bounds.has_point(at): hidden[id]="off chart"; continue
		# A corps or army group already stands for its armies here.
		var under:=false
		for echelon in echelons:
			if (echelon.get("armies",[]) as Array).has(int(mark.get("army_id",-1))): under=true; break
		if under and not bool(mark.get("selected",false)): hidden[id]="echelon"; continue
		var ours:=String(mark.get("side","ours"))=="ours"
		if (ours and ours_kept>=MAX_OURS) or (not ours and theirs_kept>=MAX_THEIRS): hidden[id]="budget"; continue
		var size:=float(mark.get("size",24.0))
		# Same side and overlapping: one mark stands for the stack.
		var joined:=false
		for entry:Dictionary in drawn:
			if String(entry.side)!=String(mark.get("side","ours")): continue
			if (entry.at as Vector2).distance_to(at)<(float(entry.size)+size)*0.55:
				(entry.members as Array).append(id)
				entry.members_troops=int(entry.get("members_troops",entry.get("troops",0)))+int(mark.get("troops",0))
				entry.members_low=int(entry.get("members_low",entry.get("low",0)))+int(mark.get("low",0))
				entry.members_high=int(entry.get("members_high",entry.get("high",0)))+int(mark.get("high",0))
				hidden[id]="stacked"; joined=true; break
		if joined: continue
		var entry:=mark.duplicate()
		entry.anchor=at
		entry.members=[id]
		entry.moved=false
		# Give way to the front: step back off the line toward our own side.
		var nearest:=Vector2.INF; var gap:=INF
		for line:PackedVector2Array in fronts:
			for i in range(1,line.size()):
				var p:=Geometry2D.get_closest_point_to_segment(at,line[i-1],line[i])
				var d:=p.distance_to(at)
				if d<gap: gap=d; nearest=p
		var clearance:=size*0.5+4.0
		if gap<clearance:
			var away:=(at-nearest).normalized() if gap>0.5 else Vector2.ZERO
			if away==Vector2.ZERO and home.is_finite(): away=((home-at) if ours else (at-home)).normalized()
			if away==Vector2.ZERO: away=Vector2.UP
			at=at+away*(clearance-gap)
			entry.moved=true
		# Opposing marks never sit on one another.
		for other:Dictionary in drawn:
			if String(other.side)==String(entry.side): continue
			var d:=(other.at as Vector2).distance_to(at)
			var need:=(float(other.size)+size)*0.5+2.0
			if d<need:
				var push:=(at-(other.at as Vector2)).normalized() if d>0.5 else Vector2.RIGHT*(1.0 if ours else -1.0)
				at+=push*(need-d); entry.moved=true
		entry.at=at
		drawn.append(entry)
		if ours: ours_kept+=1
		else: theirs_kept+=1
	# Cards: the selected force first, then by priority, within the band's budget.
	var budget:=int(CARDS.get(band,0))
	var carded:=0
	for entry:Dictionary in drawn:
		entry.card=false
		if budget<=0: continue
		if bool(entry.get("selected",false)): entry.card=true; carded+=1
	for entry:Dictionary in drawn:
		if carded>=budget: break
		if bool(entry.card): continue
		entry.card=true; carded+=1
	return {"drawn":drawn,"hidden":hidden}
