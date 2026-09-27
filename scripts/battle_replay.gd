extends RefCounted
## The frames of a recorded battle, for watching it again. Pure: it reads
## only the battle's record (its rounds), never the live engagement, so a
## replay cannot resolve anything again (docs/GENERAL_CAMPAIGN_DESIGN.md:
## "Viewing a recorded battle does not resolve it again").
##
## Frame 0 is the two sides drawn up; frame k is the field after exchange k.
## Each frame: {index, ours, theirs, our_lost, their_lost, our_morale,
## their_morale, caption, event, phase}. The last frame carries the ending.

const Account:=preload("res://scripts/battle_account.gd")


static func frames(record:Dictionary,stage:String="hearth")->Array:
	var s:=Account.sides(record)
	var home:=String(s.home); var foe:=String(s.enemy)
	var ours:Dictionary=record.get(home,{})
	var theirs:Dictionary=record.get(foe,{})
	var rounds:Array=record.get("rounds",[])
	var account:=Account.build(record,{"stage":stage})
	var band:=String(account.band)
	var enemy:=String(account.enemy)
	var our_count:=int(ours.get("initial_troops",0))
	var their_count:=int(theirs.get("initial_troops",0))
	var out:Array=[]
	var opening:="%s, %s strong, faces %s %s." % [_cap(band),Account.count_words(our_count),enemy,String(account.where)]
	var tactics:Dictionary=account.tactics
	if String(tactics.ours)!="": opening+=" "+String(tactics.ours)+(" "+String(tactics.theirs) if String(tactics.theirs)!="" else "")
	out.append({"index":0,"ours":our_count,"theirs":their_count,"our_lost":0,"their_lost":0,"our_morale":1.0,
		"their_morale":1.0,"caption":opening,"event":"","phase":"drawn up"})
	var phases:Array=account.phases
	for index in rounds.size():
		var r:Dictionary=rounds[index]
		var our_lost:=int(r.get(home+"_losses",0)); var their_lost:=int(r.get(foe+"_losses",0))
		our_count=maxi(0,int(r.get(home+"_remaining",our_count-our_lost)))
		their_count=maxi(0,int(r.get(foe+"_remaining",their_count-their_lost)))
		var event:=Account._event_words(r,home,band,enemy)
		var caption:="The %s exchange: %s. We lost %s; they lost %s." % [Account._ordinal(index),Account._intensity_words(String(r.get("intensity",""))),Account._loss_words(our_lost),Account._loss_words(their_lost)]
		if event!="": caption+=" "+_cap(event)
		var last:=index==rounds.size()-1
		# An overrun is one short beat: the account's own line, nothing more.
		if last and Account.overrun(record) and not phases.is_empty(): caption=String(account.headline)+" "+String(phases[-1])
		elif last and not phases.is_empty(): caption+=" "+String(phases[-1])
		out.append({"index":index+1,"ours":our_count,"theirs":their_count,"our_lost":our_lost,"their_lost":their_lost,
			"our_morale":float(r.get(home+"_morale",1.0)),"their_morale":float(r.get(foe+"_morale",1.0)),
			"caption":caption,"event":event,"phase":"ending" if last else "fighting"})
	# The record's own ending counts win over reconstruction.
	if not rounds.is_empty():
		out[-1]["ours"]=int(ours.get("remaining_troops",out[-1].ours))
		out[-1]["theirs"]=int(theirs.get("remaining_troops",out[-1].theirs))
	return out


static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)
