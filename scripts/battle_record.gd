extends RefCounted
## A BATTLE, READ FOR THE BATTLE VIEW.
##
## view() turns any battle record into what hud/battle_panel.gd draws: both
## sides and their generals, the tactic each is using and whether it was
## countered, what each side took into the fight and what it has lost, the
## line and the reserve as block plates, who is winning and why, and the
## battle phase by phase. It reads only the record (and the words it is
## given), so viewing a battle never fights it again.
##
## Records come in three kinds: a live engagement (MilitaryCampaign), a
## finished battle from the history, and older records from before the block
## battle, which carry only exchange-by-exchange losses. For those the blocks
## and phases are worked out approximately from the recorded exchanges.
##
## Sides are "left" (ours when we fought, else the attacker) and "right".

const Blocks:=preload("res://scripts/battle_blocks.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")
const Account:=preload("res://scripts/battle_account.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")

## Up to this many on a side, numbers are given exactly.
const EXACT_UP_TO:=20
## Where a fight was, by its ground, when there is no town to name it by.
const GROUND_PLACES:={"open":"in the open country","rough":"on broken, hilly ground","forest":"at a forest edge","marsh":"in marshy ground",
	"pass":"in a narrow pass","ford":"at a ford","bridge":"at a bridge","breach":"at a breach in the walls","gate":"at the gate"}

## Arms in plain words: one, many.
const ARM_WORDS:={
	"club":["fighter","fighters"],"spear":["spearman","spearmen"],"pike":["pikeman","pikemen"],"sword":["swordsman","swordsmen"],
	"axe":["axeman","axemen"],"bow":["archer","archers"],"sling":["slinger","slingers"],"javelin":["javelin man","javelin men"],
	"horse":["rider","riders"],"chariot":["chariot","chariots"],"elephant":["elephant","elephants"],"musket":["musketeer","musketeers"],
	"rifle":["rifleman","riflemen"],"machine_gun":["machine gunner","machine gunners"],"guns":["gun crew","guns"],
	"armour":["tank","tanks"],"engineers":["engineer","engineers"],"support":["carrier","carriers"]}
const STATE_WORDS:={"front":"fighting","reserve":"waiting","broken":"broken","fled":"fled"}
const NUMBER_WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
## The most a "why" line says a thing adds: three times over.
const WHY_MOST_PCT:=300

## Tactic events are told by the side that used the tactic; seen from the
## other side they read the other way round.
const MIRROR:={
	"They broke ranks to chase us, and we turned on them.":"We broke ranks to chase them, and they turned on us.",
	"They did not take the bait and held their ranks.":"We did not take the bait and held our ranks.",
	"The wings closed behind them.":"Their wings closed behind us.",
	"The centre gave way before the wings could close.":"Our centre held, and their wings never closed.",
	"The armour broke through and closed a pocket behind them.":"Their armour broke through and closed a pocket behind us.",
	"The breakthrough stalled against their reserves.":"Their breakthrough stalled against our reserves.",
	"Our riders ran down the fleeing.":"Their riders ran down our men as they fled.",
}


# --- Entry ----------------------------------------------------------------------------

## The view of a battle. words (all optional): stage (hearth, lettered,
## reckoned), where, place, left_name / right_name (a side's name as the
## people say it: "Rovik's band", "the Esurai"), left_general / right_general
## (full names), live (the battle is still being fought), today.
static func view(record:Dictionary,words:Dictionary={})->Dictionary:
	var home:=String(record.get("home_side",""))
	var player:=home in ["attacker","defender"] and not bool(words.get("neutral",false))
	var left:=home if player else "attacker"
	var right:="defender" if left=="attacker" else "attacker"
	var stage:=String(words.get("stage","hearth"))
	var battle:Dictionary=record.get("battle",{}) if record.get("battle") is Dictionary else {}
	var derived:=battle.is_empty() or not battle.has("sides")
	if derived: battle=derive(record)
	var live:=bool(words.get("live",false))
	var finished:=not live
	var rounds:Array=record.get("rounds",[])
	var out:={"id":String(record.get("id","")),"seed":int(record.get("seed",0)),"live":live,"finished":finished,"derived":derived,
		"player":player,"left":left,"right":right,"stage":stage,
		"ground":_ground(battle,record),"era":int(battle.get("era",0)),
		"exchanges":rounds.size(),"hours":_hours_words(rounds.size()),
		"place":String(words.get("place","")),"where":String(words.get("where","")),"day":int(record.get("day",words.get("today",0))),
		"started":int((record.get("threat",{}) as Dictionary).get("discovered_day",record.get("day",words.get("today",0))))}
	var names:={left:String(words.get("left_name","our side" if player else "the attackers")),right:String(words.get("right_name","the enemy" if player else "the defenders"))}
	out["names"]={"left":names[left],"right":names[right]}
	var sides:={}
	for role in [left,right]:
		var key:="left" if role==left else "right"
		sides[key]=_side(record,battle,role,key,words,stage,player,rounds)
	out["sides"]=sides
	# Phases, and the drawn-up start.
	var phases:Array=[]
	var start:Dictionary=battle.get("start",{})
	for phase_variant in battle.get("phases",[]):
		phases.append(_phase(phase_variant,battle,left,right,out,words,stage))
	if live:
		var current:=_live_phase(battle,record,left,right,out,words,stage)
		if not current.is_empty(): phases.append(current)
	out["phases"]=phases
	out["start"]=_plates_of(battle,start,left,right) if not start.is_empty() else (phases[0].plates if not phases.is_empty() else {"left":{"front":[],"rear":[]},"right":{"front":[],"rear":[]}})
	var progress:=float(battle.get("progress",0.0))
	if live and not phases.is_empty(): progress=float(phases[-1].progress_attacker)
	out["progress"]=progress if left=="attacker" else -progress
	out["trend"]=float(battle.get("trend",0.0))*(1.0 if left=="attacker" else -1.0)
	out["outcome"]=_outcome_kind(record,left)
	out["phrase"]=phrase(float(out.progress),float(out.trend),player,names[left],names[right],out.outcome if finished else "")
	out["status"]=status_words(out,record)
	out["skirmish"]=skirmish(battle,record)
	out["one_line"]=_one_line(record,out,words)
	out["losses_by_phase"]=_losses_strip(phases)
	return out


## One block a side, or a fight over at the first blow: a card, not a panel.
static func skirmish(battle:Dictionary,record:Dictionary)->bool:
	if String((record.get("termination",{}) as Dictionary).get("type",""))=="overrun": return true
	var sides:Dictionary=battle.get("sides",{})
	if sides.is_empty(): return false
	return (sides.get("attacker",{}).get("blocks",[]) as Array).size()<=1 and (sides.get("defender",{}).get("blocks",[]) as Array).size()<=1


# --- Sides ----------------------------------------------------------------------------

static func _side(record:Dictionary,battle:Dictionary,role:String,key:String,words:Dictionary,stage:String,player:bool,rounds:Array)->Dictionary:
	var force:Dictionary=record.get(role,{})
	var went_in:=int(force.get("initial_troops",record.get(role+"_initial",force.get("troops",0))))
	var totals:={"went_in":went_in,"killed":0,"wounded":0,"fled":0,"captured":0}
	var lost:=0
	for round_variant in rounds:
		var r:Dictionary=round_variant
		var c:Dictionary=r.get(role+"_casualties",{})
		var total:=int(r.get(role+"_losses",0))
		totals.killed+=int(c.get("killed",0)); totals.wounded+=int(c.get("wounded",0)); totals.captured+=int(c.get("captured",0))
		totals.fled+=int(c.get("scattered",0))+maxi(0,total-int(c.get("killed",0))-int(c.get("wounded",0))-int(c.get("scattered",0))-int(c.get("captured",0)))
		lost+=total
	var remaining:=int(force.get("remaining_troops",force.get("troops",went_in-lost)))
	var termination:Dictionary=record.get("termination",{})
	if String(termination.get("defeated",""))==String(force.get("name","")) and String(force.get("name",""))!="":
		totals.captured+=mini(int(termination.get("prisoners",0)),remaining)
		remaining-=mini(int(termination.get("prisoners",0)),remaining)
	totals["standing"]=maxi(0,remaining)
	var commander:Dictionary=force.get("commander",{})
	var general_name:=String(words.get(key+"_general",commander.get("name","")))
	var side_battle:Dictionary=(battle.get("sides",{}) as Dictionary).get(role,{})
	var ours:=player and key=="left"
	return {"role":role,"key":key,"ours":ours,"name":String(words.get(key+"_name","")),
		"general":{"name":_person(general_name),"line":general_line(commander,stage)},
		"word":String(side_battle.get("word","band")),"size":int(side_battle.get("size",0)),
		"totals":totals,"exact":went_in<=EXACT_UP_TO or ours}


## One plain line about a general's skill, from his command, tactics and
## resolve (never numbers).
static func general_line(commander:Dictionary,stage:String)->String:
	if commander.is_empty(): return ""
	var role:="war leader" if stage=="hearth" else "general"
	var skill:=(float(commander.get("command",0.5))+float(commander.get("tactics",0.5)))*0.5
	var resolve:=float(commander.get("resolve",0.5))
	var line:=""
	if skill>=0.75: line="An able %s who reads a fight well" % role
	elif skill>=0.6: line="A capable %s" % role
	elif skill>=0.45: line="An ordinary %s" % role
	else: line="An untried %s" % role
	if resolve>=0.7: line+=", hard to shake"
	elif resolve<0.35: line+=", quick to lose heart"
	return line+"."


static func _person(full:String)->String:
	var clean:=full.strip_edges()
	if clean=="" or (clean==clean.to_upper() and clean.length()>3): return ""
	return clean


# --- Phases ---------------------------------------------------------------------------

static func _phase(phase:Dictionary,battle:Dictionary,left:String,right:String,out:Dictionary,words:Dictionary,stage:String)->Dictionary:
	var losses:Dictionary=phase.get("losses",{})
	var tactics:Dictionary=phase.get("tactics",{})
	var names:Dictionary=out.names
	var events:Array=[]
	for event in phase.get("events",[]):
		var line:=event_words(event,battle,left,out,words,stage)
		if line!="" and not events.has(line): events.append(line)
	var p:=float(phase.get("progress",0.0))
	var result:={"i":int(phase.get("i",1)),"from":int(phase.get("from",1)),"to":int(phase.get("to",1)),
		"when":_span_words(int(phase.get("from",1)),int(phase.get("to",1))),
		"tactics":{"left":_tactic(tactics.get(left,{}),tactics.get(right,{}),stage,true,bool(out.player)),"right":_tactic(tactics.get(right,{}),tactics.get(left,{}),stage,false,bool(out.player))},
		"losses":{"left":_losses(losses.get(left,{})),"right":_losses(losses.get(right,{}))},
		"progress_attacker":p,"progress":p if left=="attacker" else -p,
		"events":events,"event":events[0] if not events.is_empty() else "",
		"why":why_words(phase.get("why",[]),left,bool(out.player),names,stage),
		"plates":_plates_of(battle,phase.get("snap",{}),left,right),
		"capacity":int(phase.get("capacity",battle.get("capacity",0)))}
	return result


## The phase still being fought, from the live blocks.
static func _live_phase(battle:Dictionary,record:Dictionary,left:String,right:String,out:Dictionary,words:Dictionary,stage:String)->Dictionary:
	var cur:Dictionary=battle.get("cur",{})
	if cur.is_empty() or not battle.has("live"): return {}
	var from:=int(cur.get("from",1)); var to:=int(battle.get("exchange",0))
	if to<from and not (battle.get("phases",[]) as Array).is_empty(): return {}
	var tactics:={}
	var plan:Dictionary=record.get("tactics",{})
	for role in ["attacker","defender"]:
		var other:="defender" if role=="attacker" else "attacker"
		var id:=String((plan.get(role,{}) as Dictionary).get("id",""))
		tactics[role]={"id":id,"countered":id!="" and Tactics.countered(id,String((plan.get(other,{}) as Dictionary).get("id",""))),"changed":(cur.get("changes",{}) as Dictionary).has(role)}
	var phase:={"i":(battle.get("phases",[]) as Array).size()+1,"from":from,"to":maxi(from-1,to),"tactics":tactics,"losses":cur.get("losses",{}),
		"progress":float(battle.get("progress",0.0)),"events":cur.get("events",[]),"why":battle.get("why",[]),"snap":Blocks.snapshot(battle),"capacity":int(battle.get("capacity",0))}
	var view:=_phase(phase,battle,left,right,out,words,stage)
	view["current"]=true
	if to<from: view["when"]="Drawn up, before the first blow"
	return view


static func _losses(raw:Variant)->Dictionary:
	var d:Dictionary=raw if raw is Dictionary else {}
	var k:=int(d.get("k",0)); var w:=int(d.get("w",0)); var f:=int(d.get("f",0)); var c:=int(d.get("c",0))
	return {"killed":k,"wounded":w,"fled":f,"captured":c,"total":k+w+f+c}


static func _tactic(entry:Variant,enemy:Variant,stage:String,left:bool,player:bool)->Dictionary:
	var e:Dictionary=entry if entry is Dictionary else {}
	var id:=String(e.get("id",""))
	if id=="": return {"id":"","words":"","countered":false,"changed":false,"by":""}
	var enemy_id:=String((enemy as Dictionary).get("id","")) if enemy is Dictionary else ""
	var countered:=bool(e.get("countered",Tactics.countered(id,enemy_id)))
	return {"id":id,"words":_cap(Tactics.name_of(id,stage)),"countered":countered,"changed":bool(e.get("changed",false)),
		"by":_cap(Tactics.name_of(enemy_id,stage)) if countered and enemy_id!="" else ""}


# --- Plates -----------------------------------------------------------------------------

## Each side's blocks for one moment: the line in order, then the rest.
static func _plates_of(battle:Dictionary,snap:Dictionary,left:String,right:String)->Dictionary:
	var out:={}
	for role in [left,right]:
		var key:="left" if role==left else "right"
		var defs:Array=((battle.get("sides",{}) as Dictionary).get(role,{}) as Dictionary).get("blocks",[])
		var rows:Array=snap.get(role,[])
		var front:Array=[]; var rear:Array=[]
		for index in mini(defs.size(),rows.size()):
			var block:Dictionary=defs[index]
			var row:Array=rows[index]
			var men0:=maxi(0,int(block.get("men0",0)))
			var men:=maxi(0,int(row[0]))
			var state:=String(Blocks.CODE_STATE[clampi(int(row[2]),0,3)])
			var plate:={"id":String(block.get("id","")),"arm":String(block.get("arm","spear")),"unit":String(block.get("unit","")),
				"men":men,"men0":men0,"strength":clampf(float(men)/float(maxi(1,men0)),0.0,1.0),"cohesion":clampf(float(row[1])/100.0,0.0,1.0),
				"state":state,"state_words":String(STATE_WORDS.get(state,state)),"slot":int(row[3]) if row.size()>3 else -1}
			if state=="front": front.append(plate)
			else: rear.append(plate)
		front.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.slot)<int(b.slot))
		rear.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			var order:={"reserve":0,"broken":1,"fled":2}
			if int(order.get(a.state,3))!=int(order.get(b.state,3)): return int(order.get(a.state,3))<int(order.get(b.state,3))
			return float(a.cohesion)>float(b.cohesion))
		out[key]={"front":front,"rear":rear}
	return out


# --- Words ----------------------------------------------------------------------------------

## Who is winning, from the viewer's side (+1: we are). outcome: the finished
## battle's outcome kind, if over.
static func phrase(progress:float,trend:float,player:bool,left_name:String,right_name:String,outcome:String="")->String:
	if outcome!="":
		if player:
			match outcome:
				"won": return "We won the field"
				"lost": return "We were beaten"
				"withdrew": return "We pulled back"
				"mutual": return "Both sides came apart"
			return "Neither side gave way"
		match outcome:
			"won": return "%s won the field" % _cap(left_name)
			"lost": return "%s won the field" % _cap(right_name)
			"mutual": return "Both sides came apart"
		return "Neither side gave way"
	if player:
		if progress>=0.75: return "We are driving them from the field"
		if progress>=0.45: return "We are pushing them back"
		if progress>=0.15: return "We have the better of it"
		if progress>-0.15:
			if trend>0.04: return "The fight is turning our way"
			if trend<-0.04: return "The fight is turning against us"
			return "Neither side is giving ground"
		if progress>-0.45: return "They have the better of it"
		if progress>-0.75: return "Our line is giving way"
		return "We are being driven from the field"
	var a:=_cap(left_name); var b:=right_name
	if progress>=0.45: return "%s are pushing %s back" % [a,b]
	if progress>=0.15: return "%s have the better of it" % a
	if progress>-0.15: return "Neither side is giving ground"
	if progress>-0.45: return "%s have the better of it" % _cap(b)
	return "%s are pushing %s back" % [_cap(b),left_name]


static func status_words(out:Dictionary,record:Dictionary)->String:
	if bool(out.live):
		if int(out.exchanges)<=0: return "Drawn up, about to fight"
		return "Fighting, %s so far" % String(out.hours)
	return "Over after %s of fighting" % String(out.hours) if int(out.exchanges)>0 else "Over at once"


static func _hours_words(exchanges:int)->String:
	var minutes:=maxi(0,exchanges)*Account.EXCHANGE_MINUTES
	if minutes<=0: return "no time"
	if minutes<60: return "half an hour"
	if minutes<90: return "an hour"
	var hours:=roundi(float(minutes)/60.0)
	return "%s hours" % _count(hours) if hours<=12 else "%d hours" % hours


## The hours of the fight a phase covers ("Hours 1 to 2", "Hour 3").
static func _span_words(from:int,to:int)->String:
	if to<from: return "Drawn up"
	var first:=ceili(float(from)/2.0); var last:=ceili(float(to)/2.0)
	return "Hour %d" % first if first==last else "Hours %d to %d" % [first,last]


## A recorded event in plain words, told from the viewer's side.
static func event_words(event:Dictionary,battle:Dictionary,left:String,out:Dictionary,words:Dictionary,stage:String)->String:
	var side:=String(event.get("side",""))
	var ours:=bool(out.player) and side==left
	var mine:=side==left
	var names:Dictionary=out.names
	var owner:String=names.left if mine else names.right
	match String(event.get("k","")):
		"reserve_in":
			var n:=int(event.get("n",1))
			var word:=String(event.get("word","band"))
			var where:=_slots_words(event.get("slots",[]),battle,side)
			var who:=("our" if ours else "their") if bool(out.player) else owner
			if n<=1: return "%s went in%s" % [_cap(who+" reserve") if bool(out.player) else _cap(owner)+"'s reserve",where]
			return "%s fresh %s went in%s" % [_cap(_count(n)),("%s of ours" % Blocks.plural(word)) if ours else (("%s of theirs" % Blocks.plural(word)) if bool(out.player) else Blocks.plural(word)),where]
		"broke":
			var arm:=String(event.get("arm","spear"))
			var men:=int(event.get("men",0))
			var line:=""
			if ours: line="%s %s broke and ran" % [_possessive(String(words.get("left_general_first",""))),_arm_plural(arm)]
			elif bool(out.player): line="%s of their %s broke and ran" % [_cap(_amount(men,false)),_arm_plural(arm)]
			else: line="%s %s broke and ran" % [_cap(_strip_the(owner)),_arm_plural(arm)]
			if ours: line="%s of our %s broke and ran" % [_cap(_amount(men,true)),_arm_plural(arm)] if String(words.get("left_general_first",""))=="" else line
			var taken:=int(event.get("cap",0))
			if taken>0: line+=("; they took %s of them" if ours else "; we took %s of them") % _amount(taken,ours) if bool(out.player) else "; %s were taken" % _amount(taken,true)
			return line
		"countered":
			var id:=String(event.get("id","")); var by:=String(event.get("by",""))
			if id=="" or by=="": return ""
			if bool(out.player): return "%s %s undid %s %s" % [("Their" if ours else "Our"),Tactics.name_of(by,stage).trim_prefix("a ").trim_prefix("an "),("our" if ours else "their"),Tactics.name_of(id,stage).trim_prefix("a ").trim_prefix("an ")]
			return "The %s undid the %s" % [Tactics.name_of(by,stage).trim_prefix("a ").trim_prefix("an "),Tactics.name_of(id,stage).trim_prefix("a ").trim_prefix("an ")]
		"tactic":
			var to:=String(event.get("to",""))
			if to=="": return ""
			var name:=Tactics.name_of(to,stage)
			if stage=="hearth": return "%s %s" % ["We" if ours else ("They" if bool(out.player) else _cap(owner)),name]
			return "%s turned to %s" % [("We" if ours else ("Their %s" % ("war leader" if stage=="hearth" else "general"))) if bool(out.player) else _cap(owner),Tactics._with_article(name)]
		"tactic_event":
			var text:=String(event.get("text",""))
			if text=="": return ""
			var from_left:=side==left
			if bool(out.player) and not from_left and MIRROR.has(text): return String(MIRROR[text]).trim_suffix(".")
			return text.trim_suffix(".")
		"local":
			# The resolver's local events, named: the left side is "home" here.
			var line:=Account._event_words({"event":String(event.get("code",""))},left,String(names.left),String(names.right))
			return _cap(line.trim_suffix("."))
		"widened":
			if side=="": return ""
			if bool(out.player): return "%s came round %s flank, and the front widened" % [("Our riders" if ours else "Their riders"),("their" if ours else "our")]
			return "%s came round the flank, and the front widened" % _cap(owner)
		"overrun":
			return "It was over at once"
		"chief":
			var fate:=String(event.get("fate",""))
			var name:=_person(String(event.get("name","")))
			var fate_words:=String({"captured":"was taken","killed":"fell","wounded, but escaped":"was wounded but got away"}.get(fate,""))
			if fate_words=="": return ""
			if bool(out.player): return ("Our %s %s" if ours else "Their %s %s") % [("war leader" if stage=="hearth" else "general") if name=="" else name.get_slice(" ",0),fate_words] if name!="" else ("Our leader %s" if ours else "Their leader %s") % fate_words
			return "%s's leader %s" % [_cap(_strip_the(owner)),fate_words]
		"taken":
			var n:=int(event.get("n",0))
			if n<=0: return ""
			if bool(out.player): return ("%s of ours were taken captive" if ours else "We took %s captives") % _amount(n,true)
			return "%s of %s were taken" % [_cap(_amount(n,true)),_strip_the(owner)]
	return ""


static func _slots_words(slots:Variant,battle:Dictionary,side:String)->String:
	if not slots is Array or (slots as Array).is_empty(): return ""
	var front:=0
	for block in (battle.get("live",{}) as Dictionary).get(side,[]):
		if String(block.get("st",""))=="front": front+=1
	front=maxi(front,1)
	var places:Array=[]
	for slot in slots:
		var at:=float(int(slot))/float(front)
		var word:="on the left" if at<0.34 else ("in the centre" if at<0.67 else "on the right")
		if not places.has(word): places.append(word)
	if places.size()>=3: return " all along the line"
	return " "+" and ".join(PackedStringArray(places)).replace("on the left and on the right","on both wings")


## Why one side is winning: the signed modifiers of a phase in plain words,
## from the viewer's side. Each: {k, label, text, pct (signed, + helps the
## left side), favours: left|right}.
static func why_words(items:Array,left:String,player:bool,names:Dictionary,stage:String)->Array:
	var out:Array=[]
	var sign:=1.0 if left=="attacker" else -1.0
	var us:=("we" if player else String(names.left))
	var them:=("they" if player else String(names.right))
	for item_variant in items:
		var item:Dictionary=item_variant
		var v:=float(item.get("v",0.0))*sign
		# Told as a share, at most "three times over" (+300%): against a side
		# that has broken the raw ratio runs to thousands and says nothing.
		var pct:=mini(WHY_MOST_PCT,roundi((exp(absf(v))-1.0)*100.0))*(1 if v>=0.0 else -1)
		if absi(pct)<3 and String(item.k)!="numbers": continue
		var good:=v>=0.0
		var a:Variant=item.get("a",0); var d:Variant=item.get("d",0)
		var ours_value:Variant=a if left=="attacker" else d
		var theirs_value:Variant=d if left=="attacker" else a
		var label:=""; var text:=""
		match String(item.k):
			"numbers":
				label="Numbers"
				# Ours counted, theirs as our people saw them (about, when many).
				text="%s against %s still in the fight" % [_amount(int(ours_value),true),_amount(int(theirs_value),false)] if player else "%s against %s" % [_amount(int(ours_value),false),_amount(int(theirs_value),false)]
			"frontage":
				label="Room to fight"
				# The side the narrow front holds back is the one with more to bring.
				if player: text="The ground lets only %s of %s reach %s at once" % [_amount(int(ours_value if not good else theirs_value),not good),"ours" if not good else "theirs","them" if not good else "us"]
				else: text="The ground lets only %s of %s fight at once" % [_amount(int(ours_value if not good else theirs_value),true),String(names.left) if not good else String(names.right)]
			"weapons":
				label="Weapons and drill"
				text=("%s are better armed and drilled" % _cap(us if good else them))
			"ground":
				label="The ground"
				text="%s hold the stronger ground" % _cap(us if good else them)
			"river":
				label="The river"
				text="%s are attacking across the water" % _cap(them if good else us)
			"cohesion":
				label="Heart"
				text="%s line is steadier" % _cap(("our" if good else "their") if player else ("%s's" % (String(names.left) if good else String(names.right))))
			"supply":
				label="Supply and kit"
				text="%s are better fed and equipped" % _cap(us if good else them)
			"hunger":
				label="Hunger"
				text="%s have gone short of food for days" % _cap(them if good else us)
			"fatigue":
				label="Tiredness"
				text="%s front line has fought for hours without relief" % _cap(("their" if good else "our") if player else ("%s's" % (String(names.right) if good else String(names.left))))
			"general":
				label="Generals" if stage!="hearth" else "War leaders"
				text="%s handles the fight better" % _cap(("ours" if good else "theirs") if player else ("%s's" % (String(names.left) if good else String(names.right))))
			"tactics":
				label="How they fight"
				if player: text="Our way of fighting costs them more men than it costs us" if good else "Their way of fighting costs us more men than it costs them"
				else: text="%s way of fighting costs the other side more men" % _cap("%s's" % _strip_the(String(names.left) if good else String(names.right)))
			"surprise":
				label="Surprise"
				text=("We caught them unready" if good else "They caught us unready") if player else "%s caught %s unready" % [_cap(String(names.left) if good else String(names.right)),String(names.right) if good else String(names.left)]
			_: continue
		out.append({"k":String(item.k),"label":label,"text":text,"pct":pct,"favours":"left" if good else "right"})
	return out


# --- Older records ----------------------------------------------------------------------

## Blocks and phases worked out from an old record that has only its
## exchanges: every formation's strength after each exchange (the recorded
## losses taken back off the final count), gathered into blocks, four
## exchanges to a phase, every block in the line (old battles had no
## frontage), the beaten side's blocks leaving at the end.
static func derive(record:Dictionary)->Dictionary:
	var rounds:Array=record.get("rounds",[])
	var initial:={}
	var tiers:={}
	var sides:={}
	for role in ["attacker","defender"]:
		var force:Dictionary=(record.get(role,{}) as Dictionary).duplicate(true)
		var formations:Array=(force.get("formations",[]) as Array).duplicate(true)
		if formations.is_empty():
			formations=[{"unit":"levy","weapon":"improvised","count":int(force.get("remaining_troops",force.get("troops",0)))}]
		for r in rounds:
			var losses:Array=(r as Dictionary).get(role+"_cohort_losses",[])
			for i in mini(losses.size(),formations.size()): formations[i]["count"]=int(formations[i].get("count",0))+int(losses[i])
		var start_total:=0
		for f in formations: start_total+=int(f.get("count",0))
		var claimed:=int(force.get("initial_troops",start_total))
		if claimed>start_total and formations.size()==1: formations[0]["count"]=claimed
		initial[role]=formations
		tiers[role]=Blocks.tier_of({"formations":formations})
		sides[role]=Blocks.build_side({"formations":formations},"a" if role=="attacker" else "d",int(tiers[role]))
	var battle:={"v":0,"derived":true,"tier":tiers,"era":maxi(int(tiers.attacker),int(tiers.defender)),"ground":Blocks.ground_of({"terrain_defense":float(record.get("terrain_defense",1.0))}),
		"sides":sides,"phases":[],"events":[],"phase_len":4,"progress":0.0,"trend":0.0,"capacity":0}
	# Formation strengths after each exchange.
	var counts:={}
	for role in ["attacker","defender"]:
		var now:Array=[]
		for f in initial[role]: now.append(int(f.get("count",0)))
		counts[role]=now
	battle["start"]=_derived_snap(battle,counts,{"attacker":float((record.get("attacker",{}) as Dictionary).get("morale",1.0)) if rounds.is_empty() else 1.0,"defender":float((record.get("defender",{}) as Dictionary).get("morale",1.0)) if rounds.is_empty() else 1.0},"")
	var tactics:Dictionary=record.get("tactics",{})
	var phase_tactics:={}
	for role in ["attacker","defender"]:
		var other:="defender" if role=="attacker" else "attacker"
		var id:=String((tactics.get(role,{}) as Dictionary).get("id",""))
		phase_tactics[role]={"id":id,"countered":id!="" and Tactics.countered(id,String((tactics.get(other,{}) as Dictionary).get("id",""))),"changed":false}
	var outcome:=String(record.get("outcome",""))
	var beaten:=String({"attacker_victory":"defender","defender_victory":"attacker","attacker_retreat":"attacker","defender_retreat":"defender","mutual_collapse":"both"}.get(outcome,""))
	var losses:={"attacker":{"k":0,"w":0,"f":0,"c":0},"defender":{"k":0,"w":0,"f":0,"c":0}}
	var events:Array=[]
	var from:=1
	var last_progress:=0.0
	for index in rounds.size():
		var r:Dictionary=rounds[index]
		var morale:={}
		for role in ["attacker","defender"]:
			var cohort:Array=r.get(role+"_cohort_losses",[])
			for i in mini(cohort.size(),(counts[role] as Array).size()): counts[role][i]=maxi(0,int(counts[role][i])-int(cohort[i]))
			var c:Dictionary=r.get(role+"_casualties",{})
			var total:=int(r.get(role+"_losses",0))
			losses[role].k+=int(c.get("killed",0)); losses[role].w+=int(c.get("wounded",0)); losses[role].c+=int(c.get("captured",0))
			losses[role].f+=int(c.get("scattered",0))+maxi(0,total-int(c.get("killed",0))-int(c.get("wounded",0))-int(c.get("scattered",0))-int(c.get("captured",0)))
			morale[role]=float(r.get(role+"_morale",1.0))
		if String(r.get("tactic_event",""))!="": events.append({"k":"tactic_event","text":String(r.tactic_event),"side":"","x":index+1})
		elif String(r.get("event",""))!="" and String(r.get("event",""))!="No decisive local event.": events.append({"k":"local","code":String(r.event),"x":index+1})
		if String(r.get("intensity",""))=="Overrun": events.append({"k":"overrun","side":String(r.get("overrun","")),"x":index+1})
		var last:=index==rounds.size()-1
		if (index+1-from+1)>=4 or last:
			var a_left:=0.0; var d_left:=0.0
			for n in counts.attacker: a_left+=float(n)
			for n in counts.defender: d_left+=float(n)
			var a:=a_left*float(morale.attacker); var d:=d_left*float(morale.defender)
			last_progress=(a-d)/maxf(1.0,a+d)
			if last and beaten=="defender": last_progress=1.0
			elif last and beaten=="attacker": last_progress=-1.0
			if last:
				var termination:Dictionary=record.get("termination",{})
				if int(termination.get("prisoners",0))>0 and beaten in ["attacker","defender"]: events.append({"k":"taken","side":beaten,"n":int(termination.prisoners),"x":index+1})
				var fate:=String(termination.get("commander_fate",""))
				if fate in ["captured","killed","wounded, but escaped"] and beaten in ["attacker","defender"]: events.append({"k":"chief","side":beaten,"fate":fate,"name":String(termination.get("commander","")),"x":index+1})
			var why:Array=[{"k":"numbers","v":log(maxf(1.0,a_left)/maxf(1.0,d_left)),"a":int(a_left),"d":int(d_left)}]
			var terrain:=float(record.get("effective_terrain_defense",record.get("terrain_defense",1.0)))
			if terrain>1.001: why.append({"k":"ground","v":-log(sqrt(terrain)),"a":1.0,"d":terrain})
			why.append({"k":"cohesion","v":log(maxf(0.05,float(morale.attacker))/maxf(0.05,float(morale.defender))),"a":float(morale.attacker),"d":float(morale.defender)})
			(battle.phases as Array).append({"i":(battle.phases as Array).size()+1,"from":from,"to":index+1,"tactics":phase_tactics.duplicate(true),"losses":losses.duplicate(true),
				"progress":last_progress,"trend":0.0,"events":events.duplicate(true),"why":why,"snap":_derived_snap(battle,counts,morale,beaten if last else ""),"front":{},"capacity":0})
			battle.events.append_array(events)
			losses={"attacker":{"k":0,"w":0,"f":0,"c":0},"defender":{"k":0,"w":0,"f":0,"c":0}}
			events=[]
			from=index+2
	battle.progress=last_progress
	return battle


static func _derived_snap(battle:Dictionary,counts:Dictionary,morale:Dictionary,beaten:String)->Dictionary:
	var out:={}
	for role in ["attacker","defender"]:
		var rows:Array=[]
		var blocks:Array=((battle.sides as Dictionary)[role] as Dictionary).blocks
		# Each formation's men now, shared over its blocks as they were at the start.
		var start_share:={}
		for block in blocks:
			for member in block.members: start_share[int(member[0])]=int(start_share.get(int(member[0]),0))+int(member[1])
		var slot:=0
		for block in blocks:
			var men:=0
			for member in block.members:
				var f:=int(member[0])
				var now:=int((counts[role] as Array)[f]) if f<(counts[role] as Array).size() else 0
				men+=roundi(float(now)*float(member[1])/float(maxi(1,int(start_share.get(f,1)))))
			var state:=0
			if men<=0: state=2
			elif beaten==role or beaten=="both": state=3
			rows.append([men,roundi(clampf(float(morale.get(role,1.0)),0.0,1.0)*100.0),state,slot if state==0 else -1])
			if state==0: slot+=1
		out[role]=rows
	return out


# --- Small words -----------------------------------------------------------------------------

static func ground_place(kind:String)->String:
	return String(GROUND_PLACES.get(kind,GROUND_PLACES.open))


static func _ground(battle:Dictionary,record:Dictionary)->Dictionary:
	var given:Dictionary=record.get("ground",battle.get("ground",{})) if record.get("ground",battle.get("ground",{})) is Dictionary else {}
	var kind:=String(given.get("kind",(battle.get("ground",{}) as Dictionary).get("kind","open")))
	var spec:Dictionary=Blocks.GROUNDS.get(kind,Blocks.GROUNDS.open)
	return {"kind":kind,"words":String(given.get("label",spec.words))}


static func _outcome_kind(record:Dictionary,left:String)->String:
	var outcome:=String(record.get("outcome",""))
	if outcome=="" or outcome in ["inconclusive","continued"]: return "held"
	if outcome=="mutual_collapse": return "mutual"
	if outcome.ends_with("_retreat"): return "withdrew" if outcome.begins_with(left) else "won"
	return "won" if outcome==left+"_victory" else "lost"


static func _one_line(record:Dictionary,out:Dictionary,words:Dictionary)->String:
	var line:=String(words.get("headline",""))
	if line!="": return line
	return String(out.phrase)+"."


static func _losses_strip(phases:Array)->Array:
	var out:Array=[]
	for phase in phases:
		out.append({"left":int((phase.losses.left as Dictionary).total),"right":int((phase.losses.right as Dictionary).total)})
	return out


static func _arm_plural(arm:String)->String:
	return String((ARM_WORDS.get(arm,["fighter","fighters"]) as Array)[1])


static func arm_words(arm:String,count:int)->String:
	return String((ARM_WORDS.get(arm,["fighter","fighters"]) as Array)[0 if count==1 else 1])


static func _possessive(name:String)->String:
	return "Our" if name=="" else name+"'s"


static func _strip_the(name:String)->String:
	return name.trim_prefix("the ").trim_prefix("The ")


static func _count(n:int)->String:
	return NUMBER_WORDS[n] if n>=0 and n<NUMBER_WORDS.size() else str(n)


## A number said plainly: exact when small or ours, rounded like a clerk would otherwise.
static func _amount(n:int,exact:bool)->String:
	if exact or n<=EXACT_UP_TO: return _grouped(n)
	return Marks.about(n)


static func _grouped(n:int)->String:
	return preload("res://scripts/hud/era_words.gd").grouped(n)


static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)
