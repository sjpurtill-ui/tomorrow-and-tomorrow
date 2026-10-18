extends RefCounted
## Persistent institutions, not another population, wealth, or official ledger.
## Trade constituencies read the existing People allocation. Patronage affects
## efficiency and values, never the allocation, headcount, or manpower ledger.
const Character=preload("res://scripts/family_character.gd")
const THRESHOLDS:=[10000,100000,500000,5000000,20000000]
const STAGES:=["Households","Business families","Competing houses","Political factions","Emerging parties","Political parties"]
const MATURITY:=[0,6,12,24,36]
const TRADES:={
	"Food":["Food growers","Provisioning","relief","guarded"],
	"Survey":["Surveyors","Knowledge","scholars","open"],
	"Extraction":["Material suppliers","Construction","crews","chartered"],
	"Construction":["Builders","Construction","crews","state"],
	"Crafting":["Workshop owners","Construction","crews","guarded"],
	"Logistics":["Merchants","Logistics","crews","open"],
	"Knowledge":["Scholars and teachers","Knowledge","scholars","open"],
	"Administration":["Care and public services","Administration","relief","state"],
	"Defense":["Military suppliers","Defense","army","chartered"],
}
const EFFECT_NAMES:={"Food":"food yield","Survey":"survey speed","Extraction":"material yield","Construction":"building pace","Crafting":"craft efficiency","Logistics":"trade and hauling","Knowledge":"research speed","Administration":"public administration","Defense":"military production"}

static func data()->Dictionary:
	return WorldSimulation.state.society_exchange.get("major_families",{})

static func ensure()->void:
	if active() and data().is_empty():
		WorldSimulation.government.initialize()
		_seed(int(WorldSimulation.state.elapsed_days))

static func active()->bool:return int(WorldSimulation.settlements.national_population())>=THRESHOLDS[0]

static func ceiling(population:int)->int:
	var result:=0
	for threshold:int in THRESHOLDS:
		if population>=threshold:result+=1
	return result

static func family(id:String)->Dictionary:
	for f:Dictionary in data().get("families",[]):
		if String(f.id)==id:return f
	return {}

static func _note(d:Dictionary,text:String)->void:
	d.history.push_front({"day":int(WorldSimulation.state.elapsed_days),"text":text})
	if d.history.size()>40:d.history.resize(40)
	d.revision=int(d.revision)+1

static func _head(role:String,excluded:Array)->Dictionary:
	var gov=WorldSimulation.government
	var best:Dictionary={}
	var score:=-1.0
	for person:Dictionary in gov.people:
		if String(person.get("status",""))!="active" or excluded.has(int(person.person_id)):continue
		var value:=float(person.get("skills",{}).get(TRADES[role][1],0))
		if value>score:best=person;score=value
	if best.is_empty():best=gov.admit_person({"background":String(TRADES[role][0])+" representative"})
	return best

static func _seed(day:int)->Dictionary:
	var d:={"version":1,"families":[],"parties":{},"favored":"","mandate":"","challenger":"","last_month":day/30-1,"last_contest":day,"history":[],"revision":0,"roll":{},"culture":{},"value_shift":{"official":{},"lived":{}}}
	var used:Array=[]
	for role:String in TRADES:_form_house(d,role,used)
	WorldSimulation.state.society_exchange["major_families"]=d
	_note(d,"The trades now have named houses. Favor a head and hear the program they argue for in court.")
	return d

static func _form_house(d:Dictionary,role:String,used:Array)->void:
	if int(WorldSimulation.state.population_allocations.get(role,0))<=0:return
	var head:=_head(role,used)
	if head.is_empty():return
	used.append(int(head.person_id))
	var surname:=String(head.get("family",""))
	if surname.is_empty():surname=String(head.get("name",role))
	d.families.append({"id":role,"name":surname+" house","founder":String(head.name),"head":int(head.person_id),"stage":1,"months":0.0,"standing":1.0,"loyalty":0.5,"rival":"","party":"","successions":0,"character":Character.make(head,role,Character.context()),"performance":0.5})

static func strength(f:Dictionary)->float:
	# Real workers, actual office, and accumulated patronage. No extra workers.
	var workers:=float(WorldSimulation.state.population_allocations.get(String(f.id),0))
	var head:Dictionary=WorldSimulation.government.person_snapshot(int(f.head))
	var total:=0.0
	for count:Variant in WorldSimulation.state.population_allocations.values():total+=maxf(0.0,float(count))
	return (1.0+100.0*sqrt(maxf(0.0,workers)/maxf(1.0,total))+float(f.standing)*2.0+(12.0 if String(head.get("office_key",""))!="" else 0.0)+(20.0 if data().get("favored","")==f.id else 0.0))*(0.5+0.5*float(f.loyalty))*(0.5+0.5*float(f.get("performance",.5)))

static func tick(day:int)->void:
	if not active():return
	var d:=data()
	if d.is_empty():d=_seed(day)
	var month:=day/30
	if month<=int(d.last_month):return
	# A loaded save does not gain decades of political organization on first read.
	d.last_month=month
	var used:Array=[]
	for f:Dictionary in d.families:used.append(int(f.head))
	for role:String in TRADES:
		if family(role).is_empty():_form_house(d,role,used)
	for f:Dictionary in d.families:
		var head:Dictionary=WorldSimulation.government.person_snapshot(int(f.head))
		if head.is_empty() or String(head.get("status",""))!="active":
			var replacement:=_head(String(f.id),used)
			if not replacement.is_empty():
				f.head=int(replacement.person_id);used.append(int(f.head));f.successions=int(f.successions)+1
				_note(d,"%s now leads %s; its founding history and program remain." % [String(replacement.name),String(f.name)])
		var favored:=String(d.favored)==String(f.id)
		head=WorldSimulation.government.person_snapshot(int(f.head))
		var character:Dictionary=f.get("character",{})
		if int(character.get("head",0))!=int(f.head) or not Character.eligible(String(character.get("outlook","")),Character.context()):
			f.character=Character.make(head,String(f.id),Character.context())
		# A newly plausible ambition can emerge through experience, not a new
		# random personality roll when the player opens the court.
		elif Character.eligible("conquest",Character.context()) and f.id=="Defense" and character.get("outlook")=="security":
			f.character=Character.make(head,String(f.id),Character.context())
		f.performance=performance(String(f.id))
		var appointed:=String(head.get("office_key",""))!=""
		f.standing=clampf(float(f.standing)+(0.3 if favored else -0.04)+(0.12 if appointed else 0.0),0.0,30.0)
		f.loyalty=clampf(float(f.loyalty)+(0.01 if favored else -0.002),0.0,1.0)
		var limit:=ceiling(int(WorldSimulation.settlements.national_population()))
		if int(f.stage)<limit:
			f.months=float(f.months)+1.0+(0.5 if favored or appointed else 0.0)
			if float(f.months)>=float(MATURITY[int(f.stage)]):
				f.stage=int(f.stage)+1;f.months=0.0
				_note(d,"%s has become part of %s." % [String(f.name),String(STAGES[int(f.stage)]).to_lower()])
		else:f.months=0.0
	_organize(d,day)
	_advance_values(d)
	if day-int(d.last_contest)>=360 and stage()>=2:
		_contest(d,day)
	# AI rulers use the same institutions and efficiency effects, with their strongest
	# constituency. The player's mandate is always an explicit choice.
	if WorldSimulation.actor_id!="player" and String(d.mandate).is_empty() and not d.families.is_empty():
		var strongest:Dictionary=d.families[0]
		for f:Dictionary in d.families:
			if strength(f)>strength(strongest):strongest=f
		d.mandate=String(strongest.id);d.favored=String(strongest.id)
	d.revision=int(d.revision)+1

static func stage()->int:
	var result:=0
	for f:Dictionary in data().get("families",[]):result=maxi(result,int(f.stage))
	return mini(result,ceiling(int(WorldSimulation.settlements.national_population())))

static func _contest(d:Dictionary,day:int)->void:
	d.last_contest=day
	var contenders:Array=[]
	for f:Dictionary in d.families:
		if int(f.stage)>=2:contenders.append(f)
	if contenders.size()<2:return
	contenders.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return strength(a)>strength(b) if strength(a)!=strength(b) else String(a.id)<String(b.id))
	var a:Dictionary=contenders[0]
	var b:Dictionary=contenders[1]
	# A rival to the entrusted house gets a real opportunity to contest privileges. At faction stage, sustained
	# opposition creates stronger efficiency penalties for the incumbent.
	if not family(String(d.mandate)).is_empty() and int(family(String(d.mandate)).stage)>=2:
		a=family(String(d.mandate));b=contenders[0] if contenders[0].id!=a.id else contenders[1]
	a.rival=String(b.id);b.rival=String(a.id)
	var chance:=clampf(strength(a)/(strength(a)+strength(b)),0.15,0.85)
	var rng:=RandomNumberGenerator.new();rng.seed=hash("%s:%s:houses:%d" % [str(WorldSimulation.state.world_seed),WorldSimulation.actor_id,day/360])
	var roll:=rng.randf()
	var winner:Dictionary=a if roll<chance else b
	d.challenger=String(winner.id)
	d.roll={"day":day,"a":String(a.id),"b":String(b.id),"chance":chance,"roll":roll,"winner":String(winner.id)}
	_note(d,"%s won the contest with %s. %s had a %.0f%% chance; roll %.3f. Their influence now changes the program's bonuses and political resistance." % [String(winner.name),String(b.name if winner==a else a.name),String(a.name),chance*100.0,roll])

static func _organize(d:Dictionary,day:int)->void:
	var assigned:Array=[]
	# Existing parties keep their origin and history. Each congress admits
	# aligned houses; a house whose succession changed its outlook may leave.
	for id:String in d.parties:
		var p:Dictionary=d.parties[id]
		p.members=[]
		for f:Dictionary in d.families:
			if int(f.stage)<4 or assigned.has(f.id):continue
			if affinity(f.character.values,p.values)>=.72:
				p.members.append(String(f.id));assigned.append(String(f.id));f.party=id
	for f:Dictionary in d.families:
		if int(f.stage)<4 or assigned.has(f.id):continue
		var id:=String(f.id)
		var p:Dictionary=d.parties.get(id,{})
		if p.is_empty():
			p={"name":String(f.name).trim_suffix(" house")+" Alliance","founder":String(f.name),"head":int(f.head),"members":[],"founded":day,"congress":day,"full":false,"leadership_votes":{},"values":f.character.values.duplicate(true)}
			d.parties[id]=p
			_note(d,"%s formed around %s's program. Other houses can join where their values agree." % [String(p.name),String(f.name)])
		p.members.append(id);assigned.append(id);f.party=id
		for other:Dictionary in d.families:
			if int(other.stage)>=4 and not assigned.has(other.id) and affinity(other.character.values,p.values)>=.72:
				p.members.append(String(other.id));assigned.append(String(other.id));other.party=id
	var party_heads:Array=[]
	for id:String in d.parties:
		var p:Dictionary=d.parties[id]
		p.full=false
		for member:String in p.members:
			if int(family(member).stage)>=5 and stage()>=5:p.full=true
		var current:Dictionary=WorldSimulation.government.person_snapshot(int(p.head))
		if p.members.is_empty():continue
		if current.is_empty() or current.get("status")!="active" or party_heads.has(int(p.head)) or (p.full and day-int(p.congress)>=360):
			var candidates:Array=[]
			for person:Dictionary in WorldSimulation.government.people:
				if person.get("status")!="active" or party_heads.has(int(person.person_id)):continue
				var fit:=0.0
				for member:String in p.members:fit+=float(person.get("skills",{}).get(TRADES[member][1],0))
				var values:Dictionary=Character.make(person,String(p.members[0]),Character.context()).values
				fit*=affinity(values,p.values)
				candidates.append({"id":int(person.person_id),"weight":fit})
			candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.weight>b.weight if a.weight!=b.weight else a.id<b.id)
			if not candidates.is_empty():
				p.head=int(candidates[0].id);p.leadership_votes={"winner":int(p.head),"weight":float(candidates[0].weight),"candidates":candidates.size()}
				_note(d,"%s chose %s for expertise and agreement with its program." % [String(p.name),String(WorldSimulation.government.person_snapshot(int(p.head)).get("name",""))])
			p.congress=day
		party_heads.append(int(p.head))

static func affinity(a:Dictionary,b:Dictionary)->float:
	var gap:=0.0;var count:=0
	for axis:String in a:
		gap+=absf(float(a[axis])-float(b.get(axis,.5)));count+=1
	for axis:String in b:
		if a.has(axis):continue
		gap+=absf(float(b[axis])-.5);count+=1
	return 1.0-gap/maxf(1.0,count)

static func program(id:String)->Dictionary:
	if not TRADES.has(id):return {}
	var f:=family(id)
	var roles:Array=[id]
	if not f.is_empty() and int(f.stage)>=4 and stage()>=4:
		var p:Dictionary=data().get("parties",{}).get(String(f.party),{})
		if not p.is_empty():roles=p.members.duplicate()
	var weights:Dictionary={}
	for role:String in roles:weights[role]=1.0
	weights[id]=2.0
	if not f.is_empty() and stage()>=5:
		var party:Dictionary=data().get("parties",{}).get(String(f.party),{})
		if bool(party.get("full",false)):
			var leader:Dictionary=WorldSimulation.government.person_snapshot(int(party.head))
			for role:String in weights:
				weights[role]=float(weights[role])*(1.0+float(leader.get("skills",{}).get(TRADES[role][1],0))/200.0)
	var sum:=0.0
	for value:float in weights.values():sum+=value
	for role:String in weights:weights[role]=float(weights[role])/sum
	return {"weights":weights,"line":String(TRADES[id][2]),"stance":String(TRADES[id][3])}

static func bonuses()->Dictionary:
	var d:=data()
	if not active() or d.is_empty() or String(d.mandate).is_empty():return {}
	var f:=family(String(d.mandate))
	if f.is_empty():return {}
	var result:Dictionary={}
	var support:=clampf(float(f.loyalty),0,1)
	var magnitude:=.06+.06*support
	for role:String in program(String(f.id)).weights:result[role]=magnitude*float(program(String(f.id)).weights[role])
	# A rival's victory causes resistance, not reassigned workers.
	var rival:=family(String(d.challenger))
	if stage()>=2 and not rival.is_empty() and rival.id!=f.id:
		result[f.id]=float(result.get(f.id,0))-(.06 if stage()>=3 else .03)
	var outlook:=String(f.character.outlook)
	var drawback:String={"discovery":"Administration","service":"Crafting","exchange":"Administration","dynasty":"Knowledge","security":"Logistics","conquest":"Logistics","stewardship":"Extraction"}.get(outlook,"Administration")
	result[drawback]=float(result.get(drawback,0))-.03
	return result

static func factor(role:String)->float:return clampf(1.0+float(bonuses().get(role,0)),.85,1.15)

static func performance(role:String)->float:
	var m:Dictionary=WorldSimulation.state.simulation_metrics
	match role:
		"Food":return clampf(float(m.get("food_intake_ratio",1.0)),0,1)
		"Defense":return clampf(float(m.get("security",.5)),0,1)
		"Construction":return clampf(float(WorldSimulation.state.housing_capacity)/maxf(1,WorldSimulation.state.population_total),0,1)
		"Knowledge","Survey":return clampf(float(m.get("knowledge",.5)),0,1)
		"Logistics":return clampf(float(m.get("logistics",.5)),0,1)
		_:return clampf(float(m.get("labor_efficiency",.5)),0,1)

static func _advance_values(d:Dictionary)->void:
	var f:=family(String(d.favored))
	var values:Dictionary=WorldSimulation.state.societal_values
	var profile:Dictionary=f.character.values if not f.is_empty() else {}
	var success:=float(f.performance) if not f.is_empty() else .5
	# A bounded inheritance continues to exert pressure after a patron loses
	# office. Current favor is faster; lived acceptance depends on actual results.
	for axis:String in profile:
		var inherited:=float(d.culture.get(axis,.5))
		d.culture[axis]=move_toward(inherited,float(profile[axis]) if success>=.5 else .5,.0004*absf(success-.5)*2.0)
	for axis:String in d.culture:
		for channel:String in ["official","lived"]:
			var before:=float(values[channel].get(axis,.5))
			var desired:=float(d.culture[axis])
			var rate:=.00015
			if profile.has(axis):
				var target:=float(profile[axis])
				desired=lerpf(desired,target if channel=="official" else lerpf(.5,target,clampf((success-.35)/.65,-.3,1.0)),.85)
				rate=.0015 if channel=="official" else .0006
			var after:=move_toward(before,desired,rate)
			values[channel][axis]=after
			d.value_shift[channel][axis]=clampf(float(d.value_shift[channel].get(axis,0))+after-before,-1.0,1.0)

static func work_values()->Dictionary:
	# Family pressure never becomes a disguised labor-allocation order.
	var values:Dictionary=WorldSimulation.state.societal_values.duplicate(true)
	for channel:String in ["official","lived"]:
		for axis:String in data().get("value_shift",{}).get(channel,{}):
			values[channel][axis]=clampf(float(values[channel].get(axis,.5))-float(data().value_shift[channel][axis]),0,1)
	return values

static func speaker_profile(person_id:int)->Dictionary:
	var profile:=head_profile(person_id)
	if not profile.is_empty():return profile
	var person:Dictionary=WorldSimulation.government.person_snapshot(person_id)
	if person.is_empty():return {}
	var role:="Administration"
	var score:=-1.0
	for id:String in TRADES:
		var skill:=float(person.get("skills",{}).get(TRADES[id][1],0))
		if skill>score:score=skill;role=id
	if String(person.get("office_key",""))=="Marshal":role="Defense"
	return Character.make(person,role,Character.context())

static func head_profile(person_id:int)->Dictionary:
	for f:Dictionary in data().get("families",[]):
		if int(f.head)==person_id:return f.get("character",{})
	return {}

static func decide(action:String,id:String)->Dictionary:
	var d:=data();var f:=family(id)
	if not active() or d.is_empty():return {"ok":false,"text":"Named trade families begin at 10,000 people."}
	if action=="neutral":
		d.mandate="";d.favored=""
		_note(d,"Patronage and the endorsed program were withdrawn. Existing spending and trade rules remain until changed.")
	elif f.is_empty():return {"ok":false,"text":"That family is not present."}
	elif action=="favor":
		if String(d.favored)==id:return {"ok":false,"text":"That head already has your favor."}
		var old:=family(String(d.favored))
		if not old.is_empty():old.loyalty=maxf(0.0,float(old.loyalty)-0.15);old.rival=id
		d.favored=id;d.mandate=id;f.loyalty=minf(1.0,float(f.loyalty)+0.15)
		_note(d,"You favor %s. Its program is endorsed, and patronage strengthens its organization and claim against rivals." % String(f.name))
	elif action=="entrust":
		if String(d.mandate)==id:return {"ok":false,"text":"That program is already endorsed."}
		d.mandate=id
		_note(d,"You endorsed %s. Its bonuses and drawbacks affect efficiency, without moving any workers." % String(f.name))
	elif action=="fund":
		var p:=program(id)
		var response:Dictionary=load("res://scripts/realm_purse.gd").set_line(String(p.line),true)
		if not response.get("ok",false):return {"ok":false,"text":String(response.get("error","Spending unavailable."))}
		if not response.get("changed",false):return {"ok":false,"text":"That spending line is already enabled."}
		f.loyalty=minf(1.0,float(f.loyalty)+.08)
		_note(d,"You accepted %s's request to fund %s from the existing public purse. Payment still requires actual funds." % [String(f.name),String(p.line)])
	elif action=="trade":
		var response:Dictionary=load("res://scripts/enterprise.gd").set_stance(String(program(id).stance))
		if not response.get("ok",false):return {"ok":false,"text":String(response.get("error","Trade policy unavailable."))}
		if not response.get("changed",false):return {"ok":false,"text":"Those trade rules are already in force."}
		f.loyalty=minf(1.0,float(f.loyalty)+.08)
		_note(d,"You accepted %s's %s trade rules." % [String(f.name),String(program(id).stance)])
	else:return {"ok":false,"text":"Unknown family decision."}
	return {"ok":true,"text":String(d.history[0].text)}

static func court_brief()->String:
	if data().is_empty():return "There are no established trade houses here. People speak for their households and their own practical concerns."
	return brief()

static func brief()->String:
	if data().is_empty():return "Major families emerge at 10,000 people. Household visitors and officials bring the smaller settlement's business."
	var d:=data()
	var words:="%s. Favored: %s. Endorsed program: %s." % [String(STAGES[stage()]),String(family(String(d.favored)).get("name","none")),String(family(String(d.mandate)).get("name","none"))]
	if not active():return words+" Institutions survive in memory, but their current bonuses are suspended below 10,000 people."
	words+=" Worker allocations and manpower are unchanged."
	for role:String in bonuses():words+=" %s %+.1f%%." % [String(EFFECT_NAMES[role]),float(bonuses()[role])*100.0]
	if not d.roll.is_empty():words+=" Last contest: %s won (%.0f%% chance for %s; roll %.3f)." % [String(d.roll.winner),float(d.roll.chance)*100.0,String(d.roll.a),float(d.roll.roll)]
	return words

static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	if value.is_empty():return true
	if not value.has_all(["version","families","parties","favored","mandate","challenger","last_month","last_contest","history","revision","roll","culture","value_shift"]):return false
	if not value.culture is Dictionary or not value.value_shift is Dictionary:return false
	for channel in ["official","lived"]:
		if not value.value_shift.get(channel) is Dictionary:return false
		if not _vector_valid(value.value_shift[channel],-1.0,1.0):return false
	if not _vector_valid(value.culture,0.0,1.0):return false
	if value.version!=1 or not value.families is Array or value.families.size()>9 or not value.parties is Dictionary or value.parties.size()>9 or not value.history is Array or value.history.size()>40 or not value.roll is Dictionary:return false
	for key:String in ["favored","mandate","challenger"]:
		if not value[key] is String or (value[key]!="" and not TRADES.has(value[key])):return false
	for key:String in ["last_month","last_contest","revision"]:
		if not _number(value[key]) or value[key]<-1:return false
	var seen:Array=[]
	for f:Variant in value.families:
		if not f is Dictionary or not f.has_all(["id","name","founder","head","stage","months","standing","loyalty","rival","party","successions","character","performance"]):return false
		if not Character.valid(f.character) or not _number(f.performance) or f.performance<0 or f.performance>1:return false
		if not TRADES.has(f.id) or seen.has(f.id):return false
		seen.append(f.id)
		for key:String in ["name","founder","rival","party"]:
			if not f[key] is String or f[key].length()>200:return false
		for key:String in ["head","stage","months","standing","loyalty","successions"]:
			if not _number(f[key]) or f[key]<0:return false
		if float(f.stage)!=floorf(float(f.stage)) or f.stage<1 or f.stage>5 or f.months>36 or f.standing>30 or f.loyalty>1:return false
	for p:Variant in value.parties.values():
		if not p is Dictionary or not p.has_all(["name","founder","head","members","founded","congress","full","leadership_votes","values"]):return false
		if not p.values is Dictionary or not _vector_valid(p.values,0.0,1.0):return false
		if not p.name is String or not p.founder is String or p.name.length()>200 or p.founder.length()>200 or not p.members is Array or p.members.size()>9 or not p.full is bool or not p.leadership_votes is Dictionary:return false
		for id:Variant in p.members:
			if not TRADES.has(id):return false
		for key:String in ["head","founded","congress"]:
			if not _number(p[key]) or p[key]<0:return false
	for h:Variant in value.history:
		if not h is Dictionary or not h.get("text") is String or h.text.length()>1000 or not _number(h.get("day")):return false
	if not value.roll.is_empty():
		if not value.roll.has_all(["day","a","b","chance","roll","winner"]):return false
		for key:String in ["a","b","winner"]:
			if not TRADES.has(value.roll[key]):return false
		for key:String in ["chance","roll","day"]:
			if not _number(value.roll[key]) or value.roll[key]<0:return false
		if value.roll.chance>1 or value.roll.roll>1:return false
	return true

static func _number(v:Variant)->bool:return (v is int or v is float) and is_finite(float(v))

static func _vector_valid(vector:Dictionary,low:float,high:float)->bool:
	if vector.size()>10:return false
	for axis:Variant in vector:
		if axis not in ["hierarchy","collective_obligation","centralization","experimentation","pluralism","common_stewardship","restorative_justice","openness","ecological_restraint","achieved_status"]:return false
		if not _number(vector[axis]) or vector[axis]<low or vector[axis]>high:return false
	return true
