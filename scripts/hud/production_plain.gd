extends RefCounted
## Plain-language readings of workshop lines for the Production screen.
## Pure functions over the production snapshot: they explain the numbers the
## simulation already computes (rate, stock, materials, workforce) and never
## change them.

const LOW:=0.5
const NORMAL:=1.0
const HIGH:=2.0
const URGENT:=4.0
## Named priorities, in the order they are offered. Values are the existing
## relative work weights used by MilitaryCampaign.set_production_line_allocation.
const PRIORITIES:=[["Low",LOW],["Normal",NORMAL],["High",HIGH],["Urgent",URGENT]]
## Stock targets the target stepper moves between. 0 means no target.
const TARGET_STEPS:=[0,1,2,3,5,10,15,20,25,30,40,50,75,100,150,200,250,300,400,500,750,1000,1500,2000,3000,5000,10000]
## A working line that will reach its target within this many days is on pace.
const ON_PACE_DAYS:=120.0

static func number(value:float)->String:
	## Rounded for reading: whole numbers from 3 up, one decimal from 1, two below.
	var magnitude:=absf(value)
	if magnitude>=1.0:
		if magnitude>=3.0 or is_equal_approx(value,roundf(value)):return str(roundi(value))
		return _trim("%.1f" % value)
	if magnitude<=0.0:return "0"
	return _trim("%.2f" % value) if magnitude>=0.01 else "under 0.01"

static func _trim(text:String)->String:
	if text.contains("."):text=text.rstrip("0").trim_suffix(".")
	return text

static func _halves(value:float)->String:
	var halves:=roundi(value*2.0)
	var whole:=halves/2
	if halves%2==0:return str(whole)
	return ("½" if whole==0 else str(whole)+"½")

static func span_text(days:float)->String:
	## A length of time as a person would say it: "50 days", "4 months", "3½ years".
	if days<1.5:return "a day"
	if days<14.0:return "%d days" % roundi(days)
	if days<60.0:return "%d days" % (roundi(days/5.0)*5)
	if days<365.0*1.25:
		var months:=maxi(2,roundi(days/30.4))
		return "%d months" % months
	var years:=days/365.0
	if years>=100.0:return "over a century"
	if years>=10.0:return "%d years" % roundi(years)
	var text:=_halves(years)
	return ("a year" if text=="1" else text+" years")

static func duration_text(days:float)->String:
	if days<1.0:return "within a day"
	return "about "+span_text(days)

static func rate_text(per_day:float)->String:
	## "about 1 every 50 days" or "about 3 a day".
	if per_day<=0.0 or not is_finite(per_day):return "Nothing is being made right now"
	if per_day>=1.5:return "About %s a day" % number(per_day)
	if per_day>=0.75:return "About 1 a day"
	return "About 1 every "+span_text(1.0/per_day)

static func priority_name(allocation:float)->String:
	var best:=String(PRIORITIES[1][0]);var gap:=INF
	for entry:Array in PRIORITIES:
		var distance:=absf(float(entry[1])-allocation)
		if distance<gap:gap=distance;best=String(entry[0])
	return best

static func step_target(current:int,direction:int)->int:
	## Next stock target up (+1) or down (-1) the ladder.
	if direction>0:
		for step:int in TARGET_STEPS:
			if step>current:return step
		return current*2
	var result:=0
	for step:int in TARGET_STEPS:
		if step<current:result=step
	return result

static func officer(owner:String)->Dictionary:
	## "Mahun of the High Camp · Quartermaster" -> name and office.
	if owner.is_empty() or owner=="No workshop officeholder":return {}
	var parts:=owner.split(" · ")
	return {"name":parts[0],"office":parts[1] if parts.size()>1 else "steward"}

static func first_name(owner:String)->String:
	## The officer's name, or "Staff" when no one holds the office.
	var person:=officer(owner)
	return String(person.name) if not person.is_empty() else "Staff"

static func header(owner:String,enabled:bool,lines:Array)->Dictionary:
	## Who runs the workshops, in one line, and the one control that changes it.
	var person:=officer(owner)
	var who:=("%s, your %s," % [String(person.name),String(person.office)]) if not person.is_empty() else ""
	var mine:Array[String]=[]
	for line:Dictionary in lines:
		if bool(line.get("persistent",false)) and not bool(line.get("planner_managed",false)):mine.append(String(line.get("name","")))
	var result:={"text":"","action":"","action_tip":""}
	if not enabled:
		result.text=("You run the workshops. %s keeps existing orders going but starts nothing new." % who) if not person.is_empty() else "You run the workshops."
		result.action="Hand back to "+(String(person.name) if not person.is_empty() else "staff")
		result.action_tip="Let staff schedule the workshops again. Every unpaused line goes back to them; work in progress is kept."
		result.kind="hand_back"
		return result
	if person.is_empty():
		result.text="No one runs the workshops yet. Appoint a Quartermaster or Steward, or run the lines yourself."
		if not mine.is_empty():result.text="No one runs the workshops yet; you run %s. Appoint a Quartermaster or Steward to hand work over." % (mine[0] if mine.size()==1 else "%d lines" % mine.size())
	elif mine.is_empty():
		result.text="%s runs the workshops." % who
	elif mine.size()==1:
		result.text="%s runs the workshops except %s, which you took over." % [who,mine[0]]
	else:
		result.text="%s runs the workshops except %d lines you took over." % [who,mine.size()]
	if mine.is_empty():
		result.action="Take over the workshops"
		result.action_tip="You choose what is made. Existing lines keep running; staff stop starting or changing lines."
		result.kind="take_over"
	else:
		result.action="Hand back to "+(String(person.name) if not person.is_empty() else "staff")
		result.action_tip="Give every unpaused line back to staff. Work in progress is kept."
		result.kind="hand_back"
	return result

static func _missing_name(state:String)->String:
	return state.trim_prefix("Missing ").to_lower()

## Reads one line from the production snapshot. `context` may hold
## workforce (PersistentProduction.workforce()), labor_share, line_count and
## demand (resource -> units all lines still need).
static func line_story(line:Dictionary,context:Dictionary={})->Dictionary:
	var state:=String(line.get("state","Working"))
	var persistent:=bool(line.get("persistent",false))
	var paused:=bool(line.get("paused",false)) or state=="Paused"
	var working:=state in ["Working","Repairing equipment","Batch"]
	var rate:=0.0
	if working:rate=float(line.get("output_per_day",line.get("forecast_output_per_day",0.0)))
	if state=="Batch":rate=float(line.get("forecast_output_per_day",0.0))
	var stock:=int(line.get("stock",0))
	var target:=int(line.get("target_stock",0))
	var per_item:=maxf(.001,float(line.get("work_per_item",1.0)))
	var next_done:=clampf(float(line.get("progress_days",0.0))/per_item,0.0,1.0)
	var remaining:=-1.0
	if persistent and target>0:remaining=maxf(0.0,target-stock-next_done)
	elif not persistent:remaining=maxf(0.0,float(line.get("ordered",0))-float(line.get("completed",0))-next_done)
	var story:={"rate":rate,"remaining":remaining,"tone":"good","short":""}
	# One progress readout.
	if persistent and target>0:
		story.progress=clampf(float(stock)/float(target),0.0,1.0)
		story.progress_text="%d of %d in store" % [stock,target]
	elif persistent:
		story.progress=next_done
		story.progress_text="%d in store · next one %d%% done" % [stock,roundi(next_done*100.0)]
	else:
		story.progress=clampf(float(line.get("completed",0))/maxf(1.0,float(line.get("ordered",1))),0.0,1.0)
		story.progress_text="%d of %d made" % [int(line.get("completed",0)),int(line.get("ordered",0))]
	story.pace=rate_text(rate) if not paused else "Paused"
	# When the target will be reached.
	if paused:story.eta="Not moving while paused"
	elif state=="Target met" or (remaining>=0.0 and remaining<=0.0):story.eta="Target reached; starts again when stock is used"
	elif remaining<0.0:story.eta="No target: keeps making until paused or out of materials"
	elif rate<=0.0:story.eta="Stalled until the problem below is fixed"
	else:
		var when:=duration_text(remaining/rate)
		story.eta=when.left(1).to_upper()+when.substr(1)+" at this pace"
	# Materials: what the line needs against what is in store.
	var materials:Array=[]
	var shortest:Dictionary={}
	for input:Dictionary in line.get("materials_status",[]):
		var name:=String(input.get("name",input.get("resource","")))
		var cost:=float(input.get("per_item",0.0));var stored:=maxf(0.0,float(input.get("stored",0.0)))
		if cost<=0.0:continue
		var use:=cost*rate
		var covers:=floorf(stored/cost+.000001)
		var entry:={"name":name,"stored":stored,"per_item":cost,"per_day":use,"covers":covers,"short":false}
		var text:="%s: " % name
		if use>=0.05:
			text+="needs about %s a day, %s in store" % [number(use),number(stored)]
			text+=" — about %s left" % span_text(stored/use) if stored>0.0 else " — none left"
		else:
			text+="%s for each one, %s in store" % [number(cost),number(stored)]
			if covers>=50.0 and (remaining<0.0 or covers>=remaining*5.0):text+=" — plenty"
			elif covers>=1.0:text+=" — enough for about %d more" % int(covers)
			else:text+=" — not enough for one"
		if stored<cost:entry.short=true
		elif remaining>0.0 and covers<ceilf(remaining-.000001):entry.short=true
		elif remaining<0.0 and use>0.0 and stored/use<30.0:entry.short=true
		var demand:=float(context.get("demand",{}).get(String(input.get("resource",name)),0.0))
		if not entry.short and remaining>0.0 and demand>stored+.000001:
			text+="; other lines need it too"
		entry.text=text
		materials.append(entry)
		if bool(entry.short) and (shortest.is_empty() or float(entry.covers)<float(shortest.covers)):shortest=entry
	story.materials=materials
	# What is holding it back: the one real limit, in plain words.
	var held:=""
	if paused:
		held="Paused. Nothing is made until the line is resumed.";story.tone="muted";story.short="Paused"
	elif state=="Target met":
		held="Nothing. The target is met.";story.tone="good";story.short="Target met"
	elif state.begins_with("Missing "):
		held="Out of %s. Nothing can be made until more comes in." % _missing_name(state);story.tone="bad";story.short="Out of "+_missing_name(state)
	elif state.begins_with("No operational "):
		var place:=state.trim_prefix("No operational ")
		held="Needs a working %s first." % place;story.tone="bad";story.short="Needs a "+place
	elif state=="No workshop crafting share":
		held="No crafting labor is set aside for workshop lines.";story.tone="bad";story.short="No workers assigned"
	elif state=="No available craftspeople":
		held="No craftspeople are free to work.";story.tone="bad";story.short="Short of workers"
	elif state=="No usable workplaces":
		held="There is no usable workshop space.";story.tone="bad";story.short="No workshop space"
	elif state=="Workforce unable to work":
		held="The craftspeople are too sick or too badly supplied to work.";story.tone="bad";story.short="Workers can't work"
	elif state.begins_with("Research unavailable"):
		held="Your people no longer know how to make this.";story.tone="bad";story.short="Know-how lost"
	elif state=="Waiting for workshop labor":
		held="Waiting for workshop hands.";story.tone="warn";story.short="Waiting for workers"
	elif not shortest.is_empty():
		var name:=String(shortest.name).to_lower()
		if float(shortest.stored)<float(shortest.per_item):
			held="Short of %s: %s in store, %s needed for the next one." % [name,number(float(shortest.stored)),number(float(shortest.per_item))]
		elif remaining>0.0:
			held="Short of %s: the %s in store covers about %d of the %d still wanted." % [name,number(float(shortest.stored)),int(shortest.covers),ceili(remaining)]
		else:
			held="Short of %s: it runs out in about %s." % [name,span_text(float(shortest.stored)/maxf(.0001,float(shortest.per_day)))]
		story.tone="bad";story.short="Short of "+name
	var slow:=_slow_reason(line,context)
	if held.is_empty():
		if state=="Repairing equipment":
			held="Repairing damaged sets before making new ones.";story.tone="warn";story.short="Repairing first"
		elif remaining>0.0 and rate>0.0 and remaining/rate>ON_PACE_DAYS:
			held="Slow. "+String(slow.text);story.tone="warn";story.short=slow.short
		elif remaining<0.0 and rate<0.1:
			held="Slow. "+String(slow.text);story.tone="warn";story.short=slow.short
		else:
			held="Nothing. On pace.";story.tone="good";story.short="On pace"
	elif story.short.begins_with("Short of") and remaining>0.0 and rate>0.0 and remaining/rate>ON_PACE_DAYS:
		story.also="Also slow: "+String(slow.text).left(1).to_lower()+String(slow.text).substr(1)
	story.held=held
	return story

static func _slow_reason(line:Dictionary,context:Dictionary)->Dictionary:
	## The weakest of the factors that set a working line's pace.
	var staff:Dictionary=context.get("workforce",{})
	var others:=int(context.get("line_count",1))-1
	var candidates:Array=[]
	candidates.append([float(line.get("efficiency",1.0)),"The workers are still learning this work (%d%% of full skill). They get faster with practice." % roundi(float(line.get("efficiency",1.0))*100.0),"Workers still learning"])
	if context.has("labor_share"):candidates.append([float(context.labor_share),"Only %d%% of crafting labor goes to workshop lines; the rest makes household goods." % roundi(float(context.labor_share)*100.0),"Few hands on lines"])
	if others>0:candidates.append([float(line.get("share",1.0)),"It shares workshop hands with %d other line%s." % [others,"" if others==1 else "s"],"Sharing workers"])
	if staff.has("workplace_condition"):candidates.append([float(staff.workplace_condition),"The workshops are in poor repair.","Workshops need repair"])
	if staff.has("health"):candidates.append([float(staff.health),"Many craftspeople are sick.","Sick workers"])
	if staff.has("logistics"):candidates.append([float(staff.logistics),"Too few haulers to keep materials moving.","Few haulers"])
	var best:Array=[]
	for candidate:Array in candidates:
		if float(candidate[0])<.75 and (best.is_empty() or float(candidate[0])<float(best[0])):best=candidate
	if not best.is_empty():return {"text":String(best[1]),"short":String(best[2])}
	var workers:=float(staff.get("workers",0.0))
	if workers>0.0:return {"text":"Only about %s craftspeople work for every craft in the settlement." % number(workers),"short":"Few craftspeople"}
	return {"text":"Workshop hands are few.","short":"Few craftspeople"}

static func blocker_text(reason:String)->String:
	## One short plain reason a recipe cannot start yet.
	if reason.contains("naval base"):return "Needs a naval base first"
	if reason.contains("airfield"):return "Needs an airfield first"
	if reason.begins_with("All ") and reason.contains("production lines are assigned"):return "No free workshop space"
	if reason.begins_with("No crafting labor"):return "No crafting labor set aside for workshops"
	if reason.begins_with("No available craftspeople"):return "No craftspeople free"
	if reason.begins_with("Workforce or workplaces"):return "Workshops can't operate"
	var shortage:=RegEx.new();shortage.compile("^(.+): ([0-9.]+) in stores; ([0-9.]+) needed for one item\\.$")
	var found:=shortage.search(reason)
	if found:return "Needs %s %s, %s in store" % [number(float(found.get_string(3))),found.get_string(1).to_lower(),number(float(found.get_string(2)))]
	var setup:=RegEx.new();setup.compile("^Line setup needs ([0-9.]+) (.+)\\.$")
	found=setup.search(reason)
	if found:return "Needs %s %s to set up" % [number(float(found.get_string(1))),found.get_string(2).to_lower()]
	var sentence:=reason.get_slice(". ",0).trim_suffix(".")
	return sentence if sentence.length()<=60 else sentence.left(57).trim_suffix(" ")+"…"

static func repair_text(status:String)->String:
	## RoutineMilitaryUpkeep.status in plain words, to follow "3 damaged sets,".
	if status=="Staff repairs underway":return "being repaired now"
	if status.begins_with("Staff waiting for workshop capacity"):return "waiting for free workshop space"
	if status=="Staff waiting for repair knowledge":return "waiting until your people know how to repair them"
	if status=="Staff will schedule repairs automatically":return "staff will repair them soon"
	if status.begins_with("Staff waiting · "):return "waiting: "+blocker_text(status.trim_prefix("Staff waiting · ")).to_lower()
	return status.to_lower()

## Hook for staff plans (codex/auto-arm). A line may carry "staff_plan":
##   {"count":int items staff are making for this reason,
##    "reason":String such as "for the new levy",
##    "officer":String optional, defaults to the workshop officeholder}
## Returns "" when there is no plan.
static func plan_text(line:Dictionary,story:Dictionary,owner:String,product:String)->String:
	var plan:Variant=line.get("staff_plan",{})
	if not plan is Dictionary or (plan as Dictionary).is_empty():return ""
	var count:=int(plan.get("count",0))
	var who:=String(plan.get("officer",""))
	if who.is_empty():
		var person:=officer(owner)
		who=("The "+String(person.office)) if not person.is_empty() else "Staff"
	var what:=("%d %s" % [count,product.to_lower()]) if count>0 else product.to_lower()
	var text:="%s %s making %s" % [who,"are" if who=="Staff" else "is",what]
	var reason:=String(plan.get("reason","")).strip_edges()
	if not reason.is_empty():text+=" "+reason
	var notes:Array[String]=[]
	var rate:=float(story.get("rate",0.0))
	if count>0 and rate>0.0:notes.append(duration_text(count/rate))
	if String(story.get("tone",""))=="bad" and not String(story.get("short","")).is_empty():notes.append(String(story.short).to_lower())
	if not notes.is_empty():text+=" ("+"; ".join(notes)+")"
	return text+"."

# --- The compact (HOI4-style) screen: numbers on the row, words in tooltips ---

## Output in the shortest honest unit: "3.2 a day", "5 a week", "2 a month",
## "1 a year"; "" when nothing is made.
static func rate_short(per_day:float)->String:
	if per_day<=0.0 or not is_finite(per_day):return ""
	if per_day>=.95:return "%s a day" % number(per_day)
	if per_day*7.0>=.95:return "%s a week" % number(per_day*7.0)
	if per_day*30.4>=.95:return "%s a month" % number(per_day*30.4)
	if per_day*365.0>=.95:return "%s a year" % number(per_day*365.0)
	return "under 1 a year"

## Hands are whole people: "12", "2", "0".
static func hands_text(value:float)->String:
	return str(maxi(0,roundi(value)))

## How many hands one −/+ moves: one craftsperson in a small workshop, a
## tenth of the order of magnitude in a large one.
static func hands_step(total:float)->float:
	if total<200.0:return 1.0
	return pow(10.0,floorf(log(total)/log(10.0))-1.0)

static func target_text(target:int)->String:
	return "∞" if target<=0 else str(target)

## A staff note cut to its first clause, so the main surface never carries a
## paragraph. The whole note stays in the tooltip.
static func brief(text:String,max_words:int=12)->String:
	var result:=text.strip_edges()
	for mark:String in [". ","; "," — ",", "," so "," because "," while "," until "," and "]:
		if result.split(" ",false).size()<=max_words:break
		var cut:=result.find(mark)
		if cut>0:result=result.left(cut)
	var words:=result.split(" ",false)
	if words.size()>max_words:result=" ".join(words.slice(0,max_words))+"…"
	return result.trim_suffix(".")

## Why a stopped line is stopped, in two or three words for its bar:
## "No plant fiber", "No naval base", "No hands".
static func stop_words(short:String)->String:
	if short.begins_with("Out of "):return "No "+short.trim_prefix("Out of ")
	if short.begins_with("Short of "):return "No "+short.trim_prefix("Short of ")
	if short.begins_with("Needs a "):return "No "+short.trim_prefix("Needs a ")
	match short:
		"No workers assigned","Short of workers","Waiting for workers","Few hands on lines":return "No hands"
		"No workshop space":return "No workshop"
		"Workers can't work":return "Hands can't work"
		"Know-how lost":return "Know-how lost"
	return "Stopped"

## One compact line row: `line` from the production snapshot, `context` as
## for line_story, `extra` from the provider: hands, hands_step, badge,
## stock (logistics row), ship, today, learn_per_day, office, staff_enabled,
## auto (staff may run this kind of line).
static func line_view(line:Dictionary,context:Dictionary={},extra:Dictionary={})->Dictionary:
	var story:=line_story(line,context)
	var item:=String(line.get("item",""))
	var name:=String(extra.get("name",item.replace("_"," ").capitalize()))
	var state:=String(line.get("state","Working"))
	var persistent:=bool(line.get("persistent",false))
	var paused:=bool(line.get("paused",false)) or state=="Paused"
	var rate:=float(story.rate)
	var view:={"id":int(line.get("id",0)),"item":item,"name":name,"persistent":persistent,"paused":paused,
		"managed":bool(line.get("planner_managed",false)),"ship":bool(extra.get("ship",false)),
		"stock":int(line.get("stock",0)),"target":int(line.get("target_stock",0)),"rate":rate,
		"progress":float(story.progress),"short":String(story.short),"efficiency":clampf(float(line.get("efficiency",.2)),0.0,1.0),
		"hands":int(extra.get("hands",0)),"hands_exact":float(extra.get("hands_exact",extra.get("hands",0))),"hands_step":float(extra.get("hands_step",1.0)),"badge":extra.get("badge",{}),
		"ordered":int(line.get("ordered",line.get("count",0))),"completed":int(line.get("completed",0)),"progress_text":String(story.progress_text)}
	# The next item's share done (the target row's arc on the line card).
	view.next=clampf(float(line.get("progress_days",0.0))/maxf(.001,float(line.get("work_per_item",1.0))),0.0,1.0)
	var stock_row:Dictionary=extra.get("stock",{})
	view.needed=int(stock_row.get("needed",0));view.deficit=int(stock_row.get("deficit",0))
	# The bar: green running, amber short or slow, red stopped, grey resting.
	var tone:=String(story.tone)
	if paused:view.look="idle";view.bar_text="Paused"
	elif state=="Target met":view.look="idle";view.bar_text="Full"
	elif rate<=0.0:view.look="bad" if tone in ["bad","warn"] else "idle";view.bar_text=stop_words(String(story.short)) if view.look=="bad" else "Waiting"
	else:
		view.look="warn" if tone in ["bad","warn"] else "good"
		view.bar_text=rate_short(rate)
	# Ships: the next hull's ready date instead of a rate.
	if bool(view.ship) and not paused and state!="Target met" and rate>0.0:
		var next_done:=clampf(float(line.get("progress_days",0.0))/maxf(.001,float(line.get("work_per_item",1.0))),0.0,1.0)
		var days:=(1.0-next_done)/rate
		view.ready_day=int(extra.get("today",0))+ceili(days)
		view.ready_days=days
		view.bar_text=String(extra.get("ready_words",""))
	# Tooltips carry the sentences the old cards printed, starting with what
	# the bar shows.
	var tip:PackedStringArray=[name+" · "+String(story.pace)]
	var target:=int(line.get("target_stock",0))
	if persistent and target>0 and not bool(view.ship):tip.append("The bar fills as the store nears the target: %d of %d." % [int(line.get("stock",0)),target])
	elif persistent:tip.append("The bar is the next %s: %d%% done." % ["hull" if bool(view.ship) else "one",roundi(float(story.progress)*100.0)])
	else:tip.append("The bar is this one-off order: %s." % String(story.progress_text))
	var plan:=plan_text(line,story,String(extra.get("owner","")),name)
	if not plan.is_empty():tip.append(plan)
	tip.append(String(story.progress_text))
	if persistent and not paused:tip.append(String(story.eta))
	if not String(story.held).begins_with("Nothing"):tip.append(String(story.held))
	if story.has("also"):tip.append(String(story.also))
	for entry:Dictionary in story.materials:tip.append(String(entry.text))
	view.tip="\n".join(tip)
	var learn:=float(extra.get("learn_per_day",0.0))
	var skill:=roundi(float(view.efficiency)*100.0)
	view.skill_tip="Skill %d%%. " % skill+(("The hands get faster with practice, about 1 point every %s, up to 100%%. Changing product costs some." % span_text(.01/learn)) if learn>0.0 and skill<100 else "Full skill: practice has nothing more to teach." if skill>=100 else "Skill grows only while the line works.")
	var office:=String(extra.get("office",""))
	var who:=("the "+office) if not office.is_empty() else "staff"
	view.auto=bool(extra.get("auto",false)) and persistent
	view.auto_tip=("Auto: %s sets this line's target to what the bands need. Click to run it yourself." % who) if bool(view.managed) else ("You run this line. Auto lets %s set its target to what the bands need." % who)
	if office.is_empty():view.auto_tip="Appoint a Quartermaster or Steward to let staff run lines."
	return view
