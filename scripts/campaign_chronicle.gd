extends RefCounted
## Records observed continuity and reversals; it never invents intervening history.
const LEGACY_OPEN_DAY:=2500*365
const LEGACY_REVIEW_DAY:=3000*365
var data:Dictionary={}

func _init()->void:reset()
func reset()->void:
	data={"version":1,"last_day":-1,"observed_days":0,"healthy_days":0,"crisis_days":0,"recoveries":0,"in_crisis":false,"milestones":{},"chapters":[],"last_chapter":-1,"reckonings":[],"dominance_episodes":0,"dominant":false,"peak_population":0,"latest":{}}

func observe(day:int,facts:Dictionary)->void:
	if day<=int(data.last_day):return
	# A sparse debug jump is not evidence of a millennium of prosperity.
	var measured:=mini(30,maxi(0,day-int(data.last_day))) if int(data.last_day)>=0 else 0
	data.last_day=day;data.observed_days+=measured;data.latest=facts.duplicate(true)
	data.peak_population=maxi(int(data.peak_population),int(facts.get("population",0)))
	var crisis:=bool(facts.get("crisis",false))
	if crisis:data.crisis_days+=measured
	elif bool(facts.get("healthy",false)):data.healthy_days+=measured
	if bool(data.in_crisis) and not crisis:
		data.recoveries+=1;_event(day,"Recovery", "The society emerged from a recorded period of severe distress.")
	data.in_crisis=crisis
	var dominant:=bool(facts.get("dominant",false))
	if dominant and not bool(data.dominant):
		data.dominance_episodes+=1;_event(day,"Influence", "A sustained period of comparative strength began. It does not end the civilization's history.")
	data.dominant=dominant
	for key in ["settlement","exchange","learning","institutions","communities"]:
		if bool(facts.get(key,false)) and not data.milestones.has(key):
			data.milestones[key]=day
			_event(day,"Development",String({"settlement":"A permanent home supports the community.","exchange":"Exchange with a known society is operating.","learning":"A sustained body of adopted knowledge supports teaching.","institutions":"Institutions have grown able to carry commitments beyond one leader.","communities":"Multiple communities are part of the society."}[key]))
	var chapter:=day/(100*365)
	if chapter>int(data.last_chapter):
		data.last_chapter=chapter
		_event(day,"Generations", "Population %d; %d known societies; %d adopted discoveries. These are observations at this date."%[int(facts.get("population",0)),int(facts.get("contacts",0)),int(facts.get("discoveries",0))])

func _event(day:int,kind:String,text:String)->void:
	data.chapters.append({"day":day,"kind":kind,"text":text})
	while data.chapters.size()>40:data.chapters.pop_front()

func snapshot(day:int)->Dictionary:
	var recent:Array=data.chapters.slice(-5).duplicate(true)
	var status:="A living history"
	if bool(data.in_crisis):status="A society under strain"
	elif int(data.recoveries)>0:status="Continuity through change"
	if day>=LEGACY_OPEN_DAY:status="A legacy across generations"
	return {"title":status,"year":day/365,"review_available":day>=LEGACY_OPEN_DAY,"review_due":day>=LEGACY_REVIEW_DAY and data.reckonings.is_empty(),"observed_years":float(data.observed_days)/365.0,"healthy_years":float(data.healthy_days)/365.0,"crisis_years":float(data.crisis_days)/365.0,"recoveries":data.recoveries,"milestones":data.milestones.duplicate(true),"recent":recent,"reckonings":data.reckonings.duplicate(true),"summary":"Wars and periods of dominance shape this history; they do not finish it. A legacy review opens after 2,500 years. At 3,000 years, take stock of what endured and choose whether to continue.","next":_next()}

func _next()->String:
	if bool(data.in_crisis):return "Give leaders room to restore a viable society. Loss of standing can be recovered while people remain."
	if not data.milestones.has("settlement"):return "Establish a lasting home without dictating every person's work."
	if not data.milestones.has("exchange"):return "Discover reachable neighbors and decide what relationship to build."
	if not data.milestones.has("learning"):return "Support the transmission of useful knowledge beyond its discoverers."
	if not data.milestones.has("institutions"):return "Help responsibilities survive a change of leaders."
	return "Judge what this generation preserves, changes and passes on; leaders should bring proposals grounded in current conditions."

func reckon(day:int)->Dictionary:
	if day<LEGACY_OPEN_DAY:return {"error":"The long legacy review opens after 2,500 years. Current history remains available."}
	var record:Dictionary=snapshot(day)
	record.erase("reckonings");record["day"]=day
	record["text"]="Across %d years, the record contains %.1f observed years, %d recoveries and %d lasting developments. The present population is %d. Continue the living history or leave this as its closing account."%[day/365,float(data.observed_days)/365.0,int(data.recoveries),data.milestones.size(),int(data.latest.get("population",0))]
	data.reckonings.append(record)
	while data.reckonings.size()>4:data.reckonings.pop_front()
	return {"ok":true,"record":record}

func restore(saved:Dictionary)->void:
	reset()
	for key in data:
		if not saved.has(key):continue
		if typeof(saved[key])==typeof(data[key]):data[key]=saved[key]
		elif data[key] is int and (saved[key] is float) and is_finite(saved[key]):data[key]=int(saved[key])
	data.chapters=data.chapters.slice(-40);data.reckonings=data.reckonings.slice(-4)
