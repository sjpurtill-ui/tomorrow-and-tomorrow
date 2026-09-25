extends RefCounted
## WAR ON THE MAP, in plain words.
##
## An early war is a feud between neighbours: a few men with spears, a burned
## drying rack, a stretch of ground both sides watch. The map says exactly that
## and nothing more. Each war is one small mark near the contested border with a
## short tag ("Feud with Ankora"); the rest is told on hover, in whole sentences.
## No readiness, supply or objective percentages are drawn here in any era.
##
## Pure helpers: callers pass positions (map km, x/z as Vector2), the day and the
## era stage, so tests need no scene. war_map_overlay.gd draws the result.

const EraWords:=preload("res://scripts/hud/era_words.gd")

## Days a burned field or rack keeps smoking on the map.
const RAID_FADE_DAYS:=24
## Only harm this recent is spoken of in the present tense.
const RECENT_HARM_DAYS:=180
## How far from home each raided place lies, in km, toward the enemy.
const TARGET_KM:={"racks":0.35,"fields":0.7,"gathering":1.0,"herds":1.2,"hunters":2.0,"scouts":2.4}
## What was struck, as our own people would name it.
const TARGET_OURS:={"racks":"our drying racks","fields":"our planted fields","gathering":"our gathering grounds","herds":"our herds","hunters":"our hunting parties","scouts":"our scouts"}
const TARGET_PLACE:={"racks":"drying racks","fields":"planted fields","gathering":"gathering grounds","herds":"herds","hunters":"hunting party","scouts":"scouting party"}


## The short tag drawn beside the mark. The year appears only once the people
## keep years; before writing a war between bands is a feud.
static func war_tag(enemy:String,stage:String,days:int)->String:
	if stage=="hearth": return "Feud with %s" % enemy
	var year:=maxi(1,floori(float(maxi(0,days))/365.0)+1)
	return "War with %s · year %d" % [enemy,year] if year>=2 else "War with %s" % enemy


static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


## "Three winters now." / "Less than a year so far."
static func time_words(days:int,stage:String)->String:
	var unit:="winter" if stage=="hearth" else "year"
	if days<300: return "Not yet a %s." % unit if stage=="hearth" else "Less than a year so far."
	var count:=maxi(1,roundi(float(days)/365.0))
	if count==1: return "One %s now." % unit
	return "%s %ss now." % [_cap(EraWords.count_word(count)),unit]


## The hover account of one war. `info` keys: enemy, days, our_dead, their_dead,
## leader, harm {target, days_ago}, op {band, days_left, leader}, quiet_days,
## field (people in the field, shown only in the statistical age).
static func details(info:Dictionary,stage:String)->String:
	var enemy:=String(info.get("enemy","They"))
	var lines:PackedStringArray=[]
	var harm:Dictionary=info.get("harm",{})
	if not harm.is_empty() and int(harm.get("days_ago",9999))<=RECENT_HARM_DAYS:
		lines.append("%s's men raid %s." % [enemy,String(TARGET_OURS.get(String(harm.get("target","")),"our lands"))])
	elif not harm.is_empty():
		lines.append("%s's men have not come for a long while." % enemy)
	else:
		lines.append(("We are feuding with %s." if stage=="hearth" else "We are at war with %s.") % enemy)
	lines.append(time_words(int(info.get("days",0)),stage))
	var ours:=int(info.get("our_dead",0)); var theirs:=int(info.get("their_dead",0))
	lines.append("No one has died yet." if ours+theirs<=0 else "%d of ours dead, %d of theirs." % [ours,theirs])
	var op:Dictionary=info.get("op",{})
	var leader:=String(info.get("leader",""))
	if not op.is_empty():
		var who:=String(op.get("leader",leader)) if String(op.get("leader",leader))!="" else "Our war leader"
		var left:=int(op.get("days_left",0))
		lines.append("%s is out with %d fighters%s." % [who,int(op.get("band",0)),", back in about %d days" % left if left>0 else ", due back any day"])
	elif leader!="":
		lines.append("%s leads our fighters." % leader)
	else:
		lines.append("No one leads our fighters.")
	var quiet:=int(info.get("quiet_days",0))
	if quiet>=90: lines.append("No fighting for %d days." % quiet)
	if stage=="reckoned" and int(info.get("field",0))>0: lines.append("%s of ours in the field." % EraWords.grouped(int(info.field)))
	return " ".join(lines)


## A band's hover line.
static func band_details(band:Dictionary)->String:
	if bool(band.get("ours",false)):
		var left:=int(band.get("days_left",0))
		return "%d of our fighters with %s, gone against %s.%s" % [int(band.get("count",0)),String(band.get("leader","the war leader")),String(band.get("enemy","the enemy")),(" Back in about %d days." % left) if left>0 else " Due back any day."]
	var low:=int(band.get("low",0)); var high:=maxi(low,int(band.get("high",low)))
	var size:=("about %d" % high) if low==high or low<=0 else "%d to %d" % [low,high]
	var who:=String(band.get("enemy",""))
	var day:=int(band.get("seen_day",-1))
	var seen:=(" Seen on day %d." % day) if day>=0 else ""
	if who=="": return "Strangers, %s of them, armed.%s" % [size,seen]
	return "%s men, %s of them, armed.%s" % [_cap(who),size,seen]


static func raid_details(raid:Dictionary)->String:
	var place:=String(TARGET_PLACE.get(String(raid.get("target","")),"fields"))
	var ago:=int(raid.get("days_ago",0))
	var when:="today" if ago<=0 else ("yesterday" if ago==1 else "%d days ago" % ago)
	var text:="%s's men struck our %s %s." % [String(raid.get("enemy","Raiders")),place,when]
	var dead:=int(raid.get("our_dead",0))
	if dead>0: text+=" %d of ours died there." % dead
	if int(raid.get("taken",0))>0: text+=" They took %d Food." % int(raid.taken)
	return text


## Raid smoke fades over RAID_FADE_DAYS; 0 means gone.
static func raid_alpha(days_ago:int)->float:
	if days_ago<0 or days_ago>=RAID_FADE_DAYS: return 0.0
	return clampf(1.0-float(days_ago)/float(RAID_FADE_DAYS),0.15,1.0)


# --- Places ----------------------------------------------------------------

## Where the two peoples' ground meets: partway from home toward the enemy.
static func border_point(home:Vector2,enemy:Vector2)->Vector2:
	var delta:=enemy-home
	var distance:=delta.length()
	if distance<0.001: return home+Vector2(1.5,0.0)
	return home+delta/distance*clampf(distance*0.5,1.5,40.0)


## A short stretch of contested border, across the line between the peoples.
static func border_segment(home:Vector2,enemy:Vector2)->PackedVector2Array:
	var center:=border_point(home,enemy)
	var delta:=enemy-home
	var direction:=delta.normalized() if delta.length()>0.001 else Vector2.RIGHT
	var across:=Vector2(-direction.y,direction.x)
	var half:=clampf(delta.length()*0.08,0.4,6.0)
	return PackedVector2Array([center-across*half,center+across*half])


## Where a raid struck: close to home, on the enemy's side, a little aside.
static func raid_point(home:Vector2,enemy:Vector2,target:String,key:String)->Vector2:
	var delta:=enemy-home
	var direction:=delta.normalized() if delta.length()>0.001 else Vector2.RIGHT
	var across:=Vector2(-direction.y,direction.x)
	var reach:=minf(float(TARGET_KM.get(target,1.0)),maxf(0.2,delta.length()*0.4))
	var aside:=(float(posmod(hash(key),1000))/1000.0-0.5)*reach*0.9
	return home+direction*reach+across*aside


## Our band on its way: out from home toward the enemy as its days pass.
static func band_point(home:Vector2,enemy:Vector2,start_day:int,due_day:int,today:int)->Vector2:
	var span:=maxf(1.0,float(due_day-start_day))
	var progress:=clampf(float(today-start_day)/span,0.0,1.0)
	return home.lerp(enemy,progress*0.9)
