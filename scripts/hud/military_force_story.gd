extends RefCounted
## FORCE STORY: the Forces page in plain words.
##
## Each force gets one sentence of its state, one short line each for its
## people, weapons and drill, a condition note only when it matters, and one
## next step that uses an existing flow. Everything is built from the real
## records the roster already reads; nothing here changes the campaign.
##
## What the old numbers meant, and what is said instead:
##   "planned"      a formation's authorized places (authorized_count). For a
##                  recruitment line it is the template's size (target_count).
##                  The old screen used initial_count for trainees: everyone
##                  ever enrolled, including recruits hurt in drill and already
##                  replaced, so a full band read "20 soldiers, 39 planned".
##   "short"        empty places. Home formations are refilled only when the
##                  player calls up replacements; a recruitment line tops itself
##                  up each day from free adults unless it is paused.
##   "condition"    health and fitness of the people (food, health, shelter,
##                  wounds). Shown only when it is poor.
##   "missing gear" weapon sets not yet issued. Home forces are armed from
##                  stores each day; the steward or quartermaster orders more
##                  from the workshops.
##
## describe() is pure: it takes a grouped roster row and a context dictionary.
## context() gathers that context from the live campaign.

const EraWords:=preload("res://scripts/hud/era_words.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")

# --- Words ---------------------------------------------------------------------

static func fighters(count:int,service:String="army",stage:String="hearth")->String:
	var one:=count==1
	match service:
		"navy":return ("boat" if one else "boats") if stage!="reckoned" else ("vessel" if one else "vessels")
		"air":return "aircraft"
	if stage=="hearth":return "warrior" if one else "warriors"
	return "soldier" if one else "soldiers"

static func force_word(service:String,count:int,stage:String)->String:
	match service:
		"navy":return "fleet" if stage!="hearth" else "flotilla"
		"air":return "wing"
	return ArmyMarks.noun(count,stage)

static func sentence_name(raw:String)->String:
	## "LEVY BAND" and "levy band" both read "Levy band"; mixed case is kept.
	var text:=raw.strip_edges()
	if text.is_empty():return "This force"
	if text==text.to_upper() or text==text.to_lower():text=text.to_lower()
	return text.substr(0,1).to_upper()+text.substr(1)

static func number(value:int)->String:
	return EraWords.grouped(value)

static func empty(count:int)->String:
	return "1 place is empty" if count==1 else "%s places are empty" % number(count)

static func were(count:int)->String:
	return "1 was" if count==1 else "%s were" % number(count)

static func about_days(days:float)->String:
	if days<=1.0:return "within a day"
	if days<=14.0:return "about %d days" % ceili(days)
	if days<=60.0:return "about %d weeks" % roundi(days/7.0)
	if days<=720.0:return "about %d months" % roundi(days/30.0)
	return "more than %d years" % floori(days/365.0)

static func item_words(name:String)->String:
	return name.to_lower()

static func drill_word(drill:float)->String:
	return ["Untrained","Lightly drilled","Trained","Well drilled","Fully drilled"][clampi(floori(drill*5),0,4)]

static func experience_words(experience:float)->String:
	if experience<.05:return "they have seen almost no fighting"
	if experience<.25:return "they have seen a little fighting"
	if experience<.6:return "they have fought before"
	return "they are hardened by many fights"

# --- The story -----------------------------------------------------------------

## row: a grouped roster row. Keys used: kind ("formation", "line", "basic",
## "instruction", "service"), place ("home", "field", "garrison", "report"),
## name, count, authorized, gear, gear_required, skill, experience, condition,
## progress, hurt, unknown.
## ctx: service, stage, free_adults, policy {id,label,intake}, food_for_drill,
## line {paused,auto_deploy,target_army}, supply {name,stores,per_day,making,
## state,steward}, days_left, stalled ("gear"/"people"/""), captain {name},
## defense_target, auto_replace, crew_short.
static func describe(row:Dictionary,ctx:Dictionary)->Dictionary:
	var service:=String(ctx.get("service","army"));var stage:=String(ctx.get("stage","hearth"))
	var name:=sentence_name(String(row.get("name","")))
	var result:={"headline":"","people":"","arms":"","drill":"","condition":"","action":{"id":"captain","label":"Talk to its captain"},"reasons":[],"attention":false}
	if bool(row.get("unknown",false)):
		var reported:=int(row.get("count",0))
		result.headline="%s is away and has not sent a full report yet." % name if reported<=0 else "%s is away; the last word was about %s %s." % [name,number(reported),fighters(reported,service,stage)]
		result.people="Their numbers, weapons and drill are unknown until a messenger arrives."
		result.action={"id":"map","label":"Follow it on the map"}
		return result
	var kind:=String(row.get("kind","formation"))
	var place:=String(row.get("place","home"))
	var count:=int(row.get("count",0));var target:=maxi(count,int(row.get("authorized",count)))
	var short:=maxi(0,target-count)
	var hurt:=maxi(0,int(row.get("hurt",0)))
	var free:=maxi(0,int(ctx.get("free_adults",0)))
	var who:=fighters(count,service,stage)
	var reasons:Array[String]=[]
	var action:Dictionary={}
	var lead:=""
	# People ---------------------------------------------------------------------
	if kind=="service":
		lead="%s has %s of the %s %s it is meant to have." % [name,number(count),number(target),fighters(target,service,stage)] if short>0 else "%s has all %s %s it is meant to have." % [name,number(count),who]
		if short>0:
			if bool(ctx.get("auto_replace",true)):
				var stores:=int(ctx.get("supply",{}).get("stores",0))
				result.people="%s. New craft join by themselves once more are built and crews are free; %s." % [empty(short),"%s %s waiting in stores" % [number(stores),"is" if stores==1 else "are"] if stores>0 else "none are waiting in stores"]
				if stores<=0:action={"id":"production","label":"Order new craft"}
			else:
				result.people="%s and replacements are switched off for this force." % empty(short)
			reasons.append("%s lacks %s craft" % [name,number(short)])
		else:result.people=""
		if int(ctx.get("crew_short",0))>0:
			result.people+=" %s among the crews; the depot and new recruits make them up." % empty(int(ctx.crew_short)).to_lower()
	elif kind=="line":
		var line:Dictionary=ctx.get("line",{})
		lead="%s has %s of the %s %s it is meant to have." % [name,number(count),number(target),fighters(target,service,stage)] if short>0 else "%s has all %s %s it is meant to have." % [name,number(count),who]
		if short>0:
			if bool(line.get("paused",false)):
				result.people="%s and no one is being called up: this recruitment is paused. Resume it in Recruit & deploy." % empty(short)
				action={"id":"recruitment","label":"Resume recruitment"}
				reasons.append("%s is paused" % name)
			elif free>0:
				result.people="%s more will be called up from the people %s." % [number(short),"tomorrow" if free>=short else "as they come free (%s free now)" % ("1 is" if free==1 else "%s are" % number(free))]
			else:
				result.people="%s and no one is being called up: every adult is already at work, away or under arms. Places fill as people come free." % empty(short)
				reasons.append("no one is free to join %s" % name)
		if hurt>0:result.people+=(" " if not result.people.is_empty() else "")+"%s hurt in drill along the way; others took their places and they rejoin the recruits as they heal." % were(hurt)
	elif kind=="basic":
		var watch:=int(ctx.get("defense_target",0))
		lead="%s: %s %s in first drill, called up because you set %s people to Defense." % [name,number(count),who,number(watch)] if watch>0 else "%s: %s %s in first drill." % [name,number(count),who]
		result.people="When drill ends they join the home reserve."
		if hurt>0:result.people+=" %s hurt in drill and are recovering." % were(hurt)
	elif kind=="instruction":
		lead="%s: %s %s in instruction." % [name,number(count),who]
		result.people="You ordered this training; when it ends they join the home reserve."
		if hurt>0:result.people+=" %s hurt in drill and are recovering." % were(hurt)
	else:
		var where:=String({"home":"at home","field":"in the field","garrison":"holding %s" % String(row.get("location","a captured place")).trim_suffix(" garrison"),"report":"in the field"}.get(place,"at home"))
		if short>0:
			lead="%s is %s with %s of the %s %s it is meant to have." % [name,where,number(count),number(target),fighters(target,service,stage)]
			if place=="reserve":
				if free>0:
					result.people="%s. No one is being called up to fill them: replacements come only when you send them." % empty(short)
					action={"id":"reinforce","label":"Call up %s replacements" % number(mini(short,free)) if short>1 else "Call up a replacement"}
				else:
					result.people="%s and no one is free to fill them: every adult is already at work, away or under arms." % empty(short)
			elif place=="home":
				result.people="%s. New recruits join this army when you choose it as the destination of a recruitment in Recruit & deploy." % empty(short)
				action={"id":"recruitment","label":"Recruit for it"}
			else:
				result.people="%s. New recruits can only join them once they are back home." % empty(short)
			reasons.append("%s has %s empty places" % [name,number(short)])
		else:
			lead="%s is %s: %s %s, every place filled." % [name,where,number(count),who]
		if place=="report":result.people+=" These numbers are from %s's last report." % name
	# Weapons ----------------------------------------------------------------------
	var need:=int(round(float(row.get("gear_required",0))))
	var have:=mini(need,int(round(float(row.get("gear",0)))))
	var missing:=maxi(0,need-have)
	var supply:Dictionary=ctx.get("supply",{})
	var item:=item_words(String(supply.get("name","weapons")))
	var weapons_line:=""
	if kind=="service":
		weapons_line="Crewed and fitted as built."
	elif need<=0:
		weapons_line="They need no weapons issued."
	elif missing<=0:
		weapons_line="All %s are armed." % number(need) if need>1 else "Armed."
	else:
		var armed:="None of the %s are armed yet." % number(need) if have<=0 else "%s of %s armed; %s still %s %s." % [number(have),number(need),number(missing),"waits for" if missing==1 else "wait for",item]
		if have<=0:armed="None of the %s are armed yet; they wait for %s." % [number(need),item]
		var stores:=int(supply.get("stores",0));var per_day:=float(supply.get("per_day",0))
		var waiting:="%s still %s" % [number(missing),"waiting for a weapon" if missing==1 else "waiting for weapons"]
		var from:="";var brief:=""
		if place in ["field","report","garrison"] and kind=="formation":
			from=" Weapons reach them only at home."
			brief=waiting+", which reach them only at home."
		elif stores>=missing:
			from=" They are in stores and will be handed out within days."
			brief="%s %s in stores and will be handed out within days." % [number(missing),"weapon is" if missing==1 else "weapons are"]
		elif bool(supply.get("covered",false)) or (bool(supply.get("making",false)) and per_day>0):
			# Someone is already covering the gap: say who and how long, and ask nothing.
			var maker:=String(supply.get("maker","")) if not String(supply.get("maker","")).is_empty() else String(supply.get("steward_title","the workshop"))
			var days:=float(supply.get("days",-1.0))
			if days<0 and per_day>0:days=float(missing-stores)/per_day
			var pace:=", %s" % about_days(days) if days>=0 else ""
			from=" %s is making them%s." % [maker.substr(0,1).to_upper()+maker.substr(1),pace]
			brief="%s; %s is making them%s." % [waiting,maker,pace]
		elif bool(supply.get("making",false)):
			from=" The workshop line for them is stopped (%s)." % String(supply.get("state","no one at work")).to_lower()
			brief=waiting+", and the workshop line for them is stopped."
			action=action if not action.is_empty() else {"id":"production","label":"Order weapons"}
		elif String(supply.get("steward","")).is_empty():
			from=" No one is making them, and there is no steward to order them. Start %s in Production." % item
			brief=waiting+", and no one is making them: there is no steward to order them. Start %s in Production." % item
			action=action if not action.is_empty() else {"id":"production","label":"Order weapons"}
		else:
			# The steward or quartermaster schedules them from army demand each day.
			var steward:=String(supply.steward)
			from=" %s orders them from the workshop." % (steward.substr(0,1).to_upper()+steward.substr(1))
			brief="%s; %s is ordering them from the workshop." % [waiting,String(supply.get("steward_title",supply.steward))]
		weapons_line=armed+from
		result.arms_brief=brief
		result.arms_count=armed
		reasons.append("%s lacks %s %s" % [name,number(missing),"weapon" if missing==1 else "weapons"])
	result.arms=weapons_line
	# Drill ------------------------------------------------------------------------
	var policy:Dictionary=ctx.get("policy",{})
	var suspended:=float(policy.get("intake",1.0))<=0.0
	if kind in ["line","basic","instruction"]:
		var done:=roundi(clampf(float(row.get("progress",0)),0,1)*100)
		var stalled:=String(ctx.get("stalled",""))
		var after:="Then they form their own %s at home." % force_word(service,count,stage) if kind=="line" and bool(ctx.get("line",{}).get("auto_deploy",true)) else "Then they wait for you to send them out in Recruit & deploy." if kind=="line" else "Then they join the home reserve."
		if suspended:
			result.drill="First drill has stopped at %d%%: training is set to %s. Choose another training level to go on." % [done,String(policy.get("label","Suspend")).to_lower()]
			action=action if not action.is_empty() else {"id":"training","label":"Resume drill"}
			reasons.append("%s has stopped drilling" % name)
		elif not bool(ctx.get("food_for_drill",true)):
			result.drill="First drill has stopped at %d%%: there is no food to spare for it." % done
			reasons.append("no food for %s's drill" % name)
		elif stalled=="gear":
			result.drill="First drill is %d%% done and cannot go further until everyone is armed. %s" % [done,after]
		elif stalled=="people":
			result.drill="First drill is %d%% done and cannot go further until every place is filled. %s" % [done,after]
		else:
			var days:=int(ctx.get("days_left",-1))
			result.drill="First drill is %d%% done%s. %s" % [done,", %s left" % about_days(days) if days>0 else "",after]
	else:
		var drill:=clampf(float(row.get("skill",0)),0,1)
		var level:=drill_word(drill)
		if drill<.2:
			result.drill="%s: they have barely drilled. " % level+("Training is set to %s, so no one is drilling now." % String(policy.get("label","Suspend")).to_lower() if suspended else "Your training staff rotate them through drill.")
			if suspended:action=action if not action.is_empty() else {"id":"training","label":"Start drill"}
		else:
			result.drill="%s (%d%%); %s." % [level,roundi(drill*100),experience_words(float(row.get("experience",0)))]
	# Condition --------------------------------------------------------------------
	var condition:=clampf(float(row.get("condition",1)),0,1)
	if condition<.75:
		result.condition="In poor shape (%d%%): hungry, sick, hurt or badly housed. They fight and drill worse until they recover." % roundi(condition*100)
		reasons.append("%s in poor shape" % name)
	# Headline and next step -------------------------------------------------------
	var next:=""
	if short>0 and not result.people.is_empty() and kind!="basic":next=result.people.split(".")[0]+"."
	if missing>0 and next.is_empty():
		next=String(result.get("arms_brief",""))
		# The headline already says who is making them; the line keeps the count.
		result.arms=String(result.get("arms_count",result.arms))
	if next.is_empty() and reasons.size()>0 and not result.drill.is_empty():next=result.drill.split(":")[0].split(".")[0]+"."
	result.headline=lead if next.is_empty() or next==lead else lead+" "+next
	if action.is_empty():
		var captain:=String(ctx.get("captain",{}).get("name",""))
		action={"id":"captain","label":"Talk to %s" % captain if not captain.is_empty() else "Talk to its captain"}
	result.action=action
	result.reasons=reasons
	result.attention=not reasons.is_empty()
	return result

## The hero strip, in words: "2 forces · 22 warriors · 2 need you".
static func summary(rows:Array,stories:Array,service:String,stage:String)->Dictionary:
	var fighters_total:=0;var unknown:=false;var needing:=0
	var worries:Array[String]=[]
	for index in rows.size():
		fighters_total+=int(rows[index].get("count",0));unknown=unknown or bool(rows[index].get("unknown",false))
		var story:Dictionary=stories[index] if index<stories.size() else {}
		if bool(story.get("attention",false)):
			needing+=1
			for reason in story.get("reasons",[]):
				var text:=String(reason)
				if text not in worries:worries.append(text)
	var forces_word:=String({"army":"force","navy":"flotilla" if stage=="hearth" else "fleet","air":"wing"}[service])
	var about:="; ".join(PackedStringArray(worries.slice(0,3)))
	return {
		"forces":"%s %s%s" % [number(rows.size()),forces_word,"" if rows.size()==1 else "s"],
		"fighters":"%s%s %s" % [number(fighters_total),"+" if unknown else "",fighters(fighters_total,service,stage)],
		"attention":("Nothing needs you" if needing==0 else "%s %s you: %s" % [number(needing),"needs" if needing==1 else "need",about]),
		"needing":needing}

# --- Live context ----------------------------------------------------------------

static func free_adults(campaign:Object)->int:
	return maxi(0,int(campaign.aggregate_recruits))+maxi(0,int(campaign.recruitment_capacity())-int(campaign._mobilized_count()))

static func supply_for(campaign:Object,item:String)->Dictionary:
	if item.is_empty():return {}
	var result:={"item":item,"name":String(campaign.PersistentProduction.product_name(item)),"stores":maxi(0,int(campaign.military_inventory.get(item,0))),"making":false,"per_day":0.0,"state":"","steward":""}
	for line:Dictionary in campaign.production_lines_snapshot().get("lines",[]):
		if String(line.get("item",""))!=item or String(line.get("job_type","production")) not in ["production",""]:continue
		result.making=true
		result.per_day=float(result.per_day)+float(line.get("forecast_output_per_day",0.0) if line.has("forecast_output_per_day") else float(line.get("daily_work",0))/maxf(.001,float(line.get("work_per_item",1))))
		result.state=String(line.get("state","Working"))
		if bool(line.get("paused",false)):result.state="Paused"
	if bool(campaign.workshop.data.get("enabled",true)):
		for office:String in ["Quartermaster","Steward"]:
			var person:Dictionary=WorldSimulation.government.officeholder(office)
			if not person.is_empty():
				result.steward="your %s %s" % [office.to_lower(),String(person.get("name",""))];result.steward_title="the "+office;break
	# Hook for the quartermaster's arming plan (codex/auto-arm). When the
	# workshop exposes gear_plan(item) -> {covered:bool, days:float, maker:String},
	# its answer replaces the estimate above; without it, nothing changes.
	if campaign.workshop.has_method("gear_plan"):
		var plan:Variant=campaign.workshop.call("gear_plan",item)
		if plan is Dictionary and not (plan as Dictionary).is_empty():
			if plan.has("covered"):result.covered=bool(plan.covered)
			if plan.has("days"):result.days=float(plan.days)
			if plan.has("maker"):result.maker=String(plan.maker)
	return result

static func captain_for(row:Dictionary,campaign:Object)->Dictionary:
	## The person the court should call for this force.
	var commander:Dictionary=row.get("commander",{})
	var figure:=String(commander.get("figure_id",""))
	if not figure.is_empty():return {"target":{"figure_id":figure},"name":String(commander.get("name",""))}
	var holder:Dictionary=WorldSimulation.government.officeholder("Marshal") if WorldSimulation.government!=null else {}
	if not holder.is_empty():return {"target":{"person_id":int(holder.get("person_id",0))},"name":String(holder.get("name",""))}
	return {}

static func context(row:Dictionary,service:String,campaign:Object)->Dictionary:
	var stage:=EraWords.stage()
	var policy:Dictionary=campaign.training_staff.policy(service)
	var ctx:={"service":service,"stage":stage,"policy":{"id":String(policy.get("id","")),"label":String(policy.get("label","")),"intake":float(policy.get("intake",1.0))}}
	if bool(row.get("unknown",false)):return ctx
	var members:Array=row.get("members",[row])
	var item:=String(row.get("weapon",""))
	for member:Dictionary in members:
		if int(member.get("gear",member.get("equipment_count",0)))<int(member.get("gear_required",member.get("equipment_required",0))):item=String(member.get("weapon",item));break
	if String(row.get("kind",""))=="service":
		item=String(row.get("service_equipment",""))
		ctx.auto_replace=bool(row.get("auto_replace",true));ctx.crew_short=int(row.get("crew_short",0))
	ctx.supply=supply_for(campaign,item)
	var kind:=String(row.get("kind",""))
	# Only read what this force's sentences need; reading is never spending.
	if int(row.get("authorized",0))>int(row.get("count",0)):ctx.free_adults=free_adults(campaign)
	if kind in ["line","basic","instruction"]:ctx.food_for_drill=float(campaign.training_staff.instruction_food())>0.0
	if kind=="basic":ctx.defense_target=int(campaign._home_garrison_target())
	ctx.captain=captain_for(row,campaign)
	if kind=="line":
		ctx.line=campaign.recruit_deploy.line(int(row.get("line_id",-1)))
	if kind in ["line","basic","instruction"]:
		var estimates:Dictionary=campaign.training_progress_snapshot()
		var days:=-1;var stalled:=""
		for member:Dictionary in members:
			var estimate:Dictionary=estimates.get(int(member.get("order_id",-1)),{})
			days=maxi(days,int(estimate.get("estimated_days",-1)))
			var ceiling:=float(member.get("ceiling",1.0))
			if ceiling<.999 and float(member.get("progress",0))>=ceiling-.001:
				stalled="gear" if String(member.get("ceiling_reason",""))=="gear" else "people"
		ctx.days_left=days;ctx.stalled=stalled
	return ctx
