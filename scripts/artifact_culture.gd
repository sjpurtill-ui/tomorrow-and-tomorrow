extends RefCounted
## Artifact culture facade: studied material culture, its three kinds of value,
## and the derived allure of the civilization that holds it. Records remain in
## GameState.society_exchange (artifact_collection.gd owns the mechanics);
## allure is recomputed from real state and never saved as a second authority.
const A=preload("res://scripts/artifact_collection.gd")
const Sites=preload("res://scripts/artifact_sites.gd")
const Visuals=preload("res://scripts/hud/artifact_visuals.gd")
const ALLOCATION_KEY:="artifact_study"
# Allure weights (sum 1.0) and bounded effect sizes.
const ALLURE_COLLECTION:=.40
const ALLURE_CULTURE:=.20
const ALLURE_VALUES:=.15
const ALLURE_WORKS:=.25
const COLLECTION_SCALE:=60.0 # effective prestige at which the collection term is ~63% full
const DIPLOMACY_MAX:=.10 # proposal score per unit allure for an average-openness ruler
const MIGRATION_MAX:=.06 # household attraction per unit allure
const LABELS:=[[.15,"Obscure"],[.30,"Noticed"],[.50,"Admired"],[.70,"Renowned"],[1.01,"Luminous"]]

# --- Summary ----------------------------------------------------------------

static func summary()->Dictionary:
	var counts:={"collection":0,"studied":0,"in_study":0,"unstudied":0,"exhibited":0}
	var prestige:=0.0
	var totals:={"culture":0.0,"research":0.0,"economic":0.0}
	var role:=A.study_role()
	for item:Dictionary in _pieces():
		counts.collection+=1
		var worth:=A.prestige(item)
		prestige+=worth
		var state:=_state(item,role)
		counts[state]+=1
		if bool(item.get("exhibited",false)):counts.exhibited+=1
		if state=="studied":
			var value:=A.values(item,worth)
			for channel:String in totals:totals[channel]+=float(value[channel])
	var report:=allure_report()
	var capacity:=A.study_capacity()
	var workers:=float(capacity.researchers)
	var rate_text:="No researchers are assigned to artifact study. Unstudied pieces wait." if workers<=0 else ("About %.1f researchers study artifacts, %.1f study-work per day. A common piece needs 20, a legendary one 160." % [workers,float(capacity.rate)])
	return {"allure":report.allure,"allure_label":report.label,"allure_breakdown":report.breakdown,"allure_effects":report.effects,
		"collection_count":counts.collection,"studied_count":counts.studied,"in_study_count":counts.in_study,"unstudied_count":counts.unstudied,"exhibited_count":counts.exhibited,
		"prestige_total":snappedf(prestige,.01),"value_totals":{"culture":snappedf(totals.culture,.01),"research":snappedf(totals.research,.01),"economic":snappedf(totals.economic,.01)},
		"study_role":{"allocation_key":ALLOCATION_KEY,"weight":int(role.weight),"workers":roundi(workers),"researchers":workers,"rate":float(capacity.rate),"rate_text":rate_text,"focus_id":String(role.focus)},
		"museum_ready":A.museum_ready(),"museum_revenue":float(WorldSimulation.state.society_exchange.get("museum_revenue",0.0))}

# --- Listing ----------------------------------------------------------------

## query: {status:"all"|"studied"|"in_study"|"unstudied"|"exhibited", sort:"rarity"|"prestige"|"recent"|"value",
##         search:String, page:int (0-based), page_size:int}
static func artifacts(query:Dictionary={})->Dictionary:
	var status:=String(query.get("status","all"))
	var sort:=String(query.get("sort","rarity"))
	var search:=String(query.get("search","")).strip_edges().to_lower()
	var page_size:=clampi(int(query.get("page_size",24)),1,200)
	var role:=A.study_role()
	var rows:Array=[]
	for item:Dictionary in _pieces():
		var state:=_state(item,role)
		if status=="exhibited":
			if not bool(item.get("exhibited",false)):continue
		elif status!="all" and state!=status:continue
		if not search.is_empty():
			var haystack:=(String(item.name)+" "+String(display_name(Visuals.presentation(item)).name)+" "+String(item.get("source_name",""))+" "+String(item.get("site_name",""))+" "+String(item.get("set_name",""))+" "+String(item.get("material",""))).to_lower()
			if not search in haystack:continue
		var worth:=A.prestige(item)
		var value:=A.values(item,worth)
		rows.append({"item":item,"prestige":worth,"score":float(value.culture)+float(value.research)+float(value.economic)/40.0,"rarity":int(item.get("rarity",0)),"day":int(item.get("returned_day",0))})
	match sort:
		"prestige":rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.prestige)>float(b.prestige))
		"recent":rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.day)>int(b.day) if int(a.day)!=int(b.day) else String(a.item.id)<String(b.item.id))
		"value":rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.score)>float(b.score) if not is_equal_approx(float(a.score),float(b.score)) else float(a.prestige)>float(b.prestige))
		_:rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.rarity)>int(b.rarity) if int(a.rarity)!=int(b.rarity) else float(a.prestige)>float(b.prestige))
	var pages:=maxi(1,ceili(float(rows.size())/float(page_size)))
	var page:=clampi(int(query.get("page",0)),0,pages-1)
	var items:Array=[]
	for row:Dictionary in rows.slice(page*page_size,(page+1)*page_size):items.append(_describe(row.item,role,float(row.prestige)))
	return {"items":items,"total":rows.size(),"page":page,"pages":pages}

static func artifact(id:String)->Dictionary:
	var item:Dictionary=WorldSimulation.state.society_exchange.collections.get(id,{})
	if not A.culture_piece(item):return {}
	return _describe(item,A.study_role(),A.prestige(item))

# --- Actions ----------------------------------------------------------------

static func set_study_focus(id:String)->Dictionary:
	var role:=A.study_role()
	if id.is_empty():
		role.focus="";WorldSimulation.state.society_exchange["artifact_study"]=role
		return {"ok":true}
	var item:Dictionary=WorldSimulation.state.society_exchange.collections.get(id,{})
	if not A.culture_piece(item):return {"error":"This object is no longer held here."}
	if float(item.study)>=1:return {"error":"This piece has already been studied."}
	if not A.role_studied(item):return {"error":"Knowledge workers are already examining this craft sample as practice evidence."}
	role.focus=id;WorldSimulation.state.society_exchange["artifact_study"]=role
	return {"ok":true,"note":"" if int(role.weight)>0 else "Assign artifact-study attention in Inquiry; without researchers this piece waits."}

static func set_exhibited(id:String,on:bool)->Dictionary:
	var item:Dictionary=WorldSimulation.state.society_exchange.collections.get(id,{})
	if not A.culture_piece(item):return {"error":"This object is no longer held here."}
	if on:
		if not A.museum_ready():return {"error":"Public libraries and comparative chronicles are needed to curate a museum collection."}
		if float(item.study)<1:return {"error":"Scholars must study this piece before it can be shown and explained to visitors."}
	item.exhibited=on
	return {"ok":true}

## Research-allocation role: same emphasis budget as the twelve domains (0-12).
static func study_weight()->int:return int(A.study_role().weight)
static func set_study_weight(weight:int)->Dictionary:
	A.set_study_weight(weight)
	return {"ok":true,"weight":study_weight()}
static func change_study_weight(delta:int)->Dictionary:return set_study_weight(study_weight()+delta)

static func rumored_sites(observer:String="player")->Array[Dictionary]:return Sites.rumored_sites(observer)

# --- Allure -----------------------------------------------------------------

static func allure()->float:return float(allure_report(false).allure)

static func allure_report(with_text:bool=true)->Dictionary:
	var state:=WorldSimulation.state
	var effective:=0.0
	var museum:=A.museum_ready()
	for item:Dictionary in _pieces():
		var studied:=float(item.study)>=1
		var weight:=1.0 if studied else A.RAW_SHARE*.8
		if studied and museum and bool(item.get("exhibited",false)):weight*=1.5
		effective+=A.prestige(item)*weight
	var collection:=ALLURE_COLLECTION*(1.0-exp(-effective/COLLECTION_SCALE))
	var culture_capacity:=clampf(float(state.society_capacities.get("culture",.5)),0,1)
	var culture:=ALLURE_CULTURE*culture_capacity
	var lived:Dictionary=state.societal_values.get("lived",{}) if state.societal_values is Dictionary else {}
	var openness:=clampf((float(lived.get("openness",.5))+float(lived.get("pluralism",.5)))*.5,0,1)
	var values:=ALLURE_VALUES*openness
	var rewards:=preload("res://scripts/undertaking_rewards.gd")
	var works:=minf(ALLURE_WORKS,rewards.local_bonus(state,"attraction")+rewards.local_bonus(state,"reputation")*.5)
	var total:=clampf(collection+culture+values+works,0,1)
	var result:={"allure":total,"works":works}
	if not with_text:return result
	var label:=String(LABELS[-1][1])
	for step:Array in LABELS:
		if total<float(step[0]):label=String(step[1]);break
	result["label"]=label
	result["breakdown"]=[
		{"source":"collection","value":collection,"text":"Studied and exhibited artifacts (effective prestige %.1f). Unstudied pieces count for a fifth; exhibited studied pieces for half again as much." % effective},
		{"source":"culture","value":culture,"text":"Cultural capacity %d%% — cohesion, shared practice and the spread of new customs." % roundi(culture_capacity*100)},
		{"source":"values","value":values,"text":"Openness and pluralism in lived values (%d%%): a society others feel they could belong to." % roundi(openness*100)},
		{"source":"works","value":works,"text":"Functioning undertakings and wonders that travelers speak of."},
	]
	var diplomacy:=total*DIPLOMACY_MAX
	result["effects"]=[
		{"target":"diplomacy","value":diplomacy,"text":"Foreign rulers receive proposals more warmly: +%.3f to a proposal's reception (x0.6 for closed-minded rulers, up to x1.4 for open ones)." % diplomacy},
		{"target":"migration","value":maxf(0.0,total-works)*MIGRATION_MAX,"text":"Households elsewhere judge life here more attractive: +%.1f%% to living-condition attraction when invited (wonders already count there directly)." % (maxf(0.0,total-works)*MIGRATION_MAX*100)},
		{"target":"museum","value":total*A.MUSEUM_ALLURE,"text":"Museum visitors come more often: admissions draw x%.2f, still limited by household money and Knowledge staff." % (1.0+total*A.MUSEUM_ALLURE)},
	]
	return result

## Bounded addition to ForeignDiplomacy.forecast score (0 to 0.14).
static func diplomatic_bonus(personality:Dictionary={})->float:
	return allure()*DIPLOMACY_MAX*(.6+.8*clampf(float(personality.get("openness",.5)),0,1))

## Bounded addition to SocietyExchange.attraction (0 to 0.06). Undertakings are
## already counted there directly, so their share of allure is excluded here.
static func migration_bonus()->float:
	var report:=allure_report(false)
	return maxf(0.0,float(report.allure)-float(report.works))*MIGRATION_MAX

# --- Presentation -------------------------------------------------------------

static func _pieces()->Array:
	var result:Array=[]
	for item:Dictionary in WorldSimulation.state.society_exchange.collections.values():
		if A.culture_piece(item):result.append(item)
	return result

static func _state(item:Dictionary,role:Dictionary)->String:
	var study:=float(item.get("study",0))
	if study>=1:return "studied"
	if study>0 or (String(role.focus)==String(item.id) and int(role.weight)>0) or not A.role_studied(item):return "in_study"
	return "unstudied"

static func _describe(item:Dictionary,role:Dictionary,worth:float)->Dictionary:
	var shown:=Visuals.presentation(item)
	var facets:=A.descriptor(shown)
	var subject:=String(item.get("discovery_id",""))
	var tier:=clampi(int(item.get("rarity",0)),0,4)
	var set_id:=String(item.get("site_id",""))
	var set_size:=int(item.get("set_size",0))
	var held:=A.set_held(set_id) if not set_id.is_empty() else 0
	var state:=_state(item,role)
	var naming:=display_name(shown)
	return {"id":String(item.id),"name":String(naming.name),"catalogue_name":String(item.name),"variant":String(naming.variant),"object":String(naming.object) if not String(naming.object).is_empty() else String(facets.object),"style":String(facets.style),"motif":String(facets.motif),"material":String(facets.material),
		"rarity":A.TIERS[tier],"rarity_index":tier,"origin":origin_text(item),"origin_kind":"legendary" if tier==4 and set_id.begins_with("legend:") else ("site" if not set_id.is_empty() else String(facets.origin)),
		"found_day":int(item.get("observed_day",0)),"held_days":int(item.get("held_days",0)),"prestige":snappedf(worth,.01),"appraisal":A.price(item),
		"study_progress":clampf(float(item.get("study",0)),0,1),"state":state,"value":A.values(item,worth),"lean":A.channels(item),
		"research_subject":String(WorldSimulation.discovery.discovery_definition(subject).get("name",subject.capitalize())),"research_subject_id":subject,
		"exhibited":bool(item.get("exhibited",false)),"can_exhibit":A.museum_ready() and state=="studied","focused":String(role.focus)==String(item.id),
		"site_name":String(item.get("site_name","")),"set_name":String(item.get("set_name","")),"set_size":set_size,"set_held":held,
		"set_progress":("%d of %d" % [held,set_size]) if set_size>1 else "","set_factor":A.set_factor(item),
		"story":story(shown),"texture":Visuals.texture(item)}

## Presentation name. Catalogue names such as "An ember under ash · a broad
## contact" keep their saved form; the display splits the technical variation
## onto the object line and gives the piece a proper title.
static func display_name(item:Dictionary)->Dictionary:
	var raw:=String(item.get("name","Unnamed object"))
	var parts:=raw.split(" · ",false,1)
	var base:=parts[0].strip_edges()
	var suffix:=parts[1].strip_edges() if parts.size()>1 else ""
	if suffix.is_empty():return {"name":_title(base),"variant":"","object":""}
	var facets:=A.descriptor(item)
	var form:=String(facets.object).split(" · ")[0].strip_edges()
	if String(facets.origin)=="civilization":
		return {"name":"%s of the %s" % [_title(base),_title(suffix)],"variant":suffix,"object":"%s, %s" % [base.to_lower(),suffix]}
	if item.has("insight") or not item.has("catalogue_id"):
		# Authored prehistoric experiments: the base is already an evocative title.
		return {"name":_title(base),"variant":suffix,"object":"%s — %s" % [form,suffix]}
	# Generic prehistoric catalogue: "Irregular rough stone bowl · earth-darkened".
	return {"name":"The %s %s" % [_title(suffix),_title(form)],"variant":String(facets.style),"object":"%s, %s" % [form,String(facets.style)]}

const SMALL_WORDS:=["a","an","the","of","and","or","in","on","at","to","by","for","with","from","into","as"]
static func _title(text:String)->String:
	var words:=text.split(" ",false)
	for index:int in words.size():
		var word:=words[index]
		if index>0 and word.to_lower() in SMALL_WORDS:words[index]=word.to_lower();continue
		var pieces:=word.split("-")
		for p:int in pieces.size():pieces[p]=pieces[p].substr(0,1).to_upper()+pieces[p].substr(1)
		words[index]="-".join(pieces)
	return " ".join(words)

## Held sets: one entry per site/lost-people set with at least one piece here.
static func sets()->Array[Dictionary]:
	var groups:Dictionary={}
	for item:Dictionary in _pieces():
		var set_id:=String(item.get("site_id",""))
		if set_id.is_empty():continue
		if not groups.has(set_id):
			groups[set_id]={"set_id":set_id,"set_name":String(item.get("set_name","")),"site_name":String(item.get("site_name","")),"held":0,"total":int(item.get("set_size",1)),"items":[],"legendary":set_id.begins_with("legend:")}
		groups[set_id].held+=1;groups[set_id].items.append(String(item.id))
	var result:Array[Dictionary]=[]
	for group:Dictionary in groups.values():
		group["missing"]=maxi(0,int(group.total)-int(group.held))
		group["complete"]=int(group.missing)==0
		group["progress"]="%d of %d" % [int(group.held),int(group.total)]
		result.append(group)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.held)/float(a.total)>float(b.held)/float(b.total) if not is_equal_approx(float(a.held)/float(a.total),float(b.held)/float(b.total)) else String(a.set_name)<String(b.set_name))
	return result

static func origin_text(item:Dictionary)->String:
	if item.has("site_name"):return String(item.site_name)
	if not String(item.get("source_id","")).is_empty():return "Made by the people of "+String(item.get("source_name","a distant society"))
	return "Recovered from uncharted ground"

# --- Stories ----------------------------------------------------------------

const OPEN_SITE:=[
	"It came out of %s, where %s once kept the things that mattered to them.",
	"Diggers lifted it from %s; %s had laid it there with care, and the earth kept faith with them.",
	"Of all the pieces at %s, this was the one the diggers set aside first. %s must have handled it often.",
	"It waited at %s under a skin of dust and roots, left behind when %s moved on.",
	"Scouts found it at %s, among the last traces of %s.",
]
const OPEN_WILD:=[
	"%s %s, it lay in open ground long after the hands that made it had gone.",
	"A scout's boot turned it up: %s %s, older than any story told around our fires.",
	"It surfaced after a hard rain, %s %s, as if the land had decided to give it back.",
	"Worked from %s %s, it sits heavier in the palm than it looks; someone once carried it a long way.",
	"Found half-buried where people once rested, this %s %s is quietly insistent.",
]
const OPEN_MADE:=[
	"It was made by the people of %s and carried to us in a traveler's pack.",
	"The people of %s gave it freely, the way one gives a story worth keeping.",
	"It came along the road from %s, still smelling faintly of someone else's hearth.",
	"Our envoys brought it back from %s, wrapped in cloth against the journey.",
]
const MIDDLE:={
	"culture":[
		"Its %s form still carries %s traces, as though its maker wanted to be remembered.",
		"Turn it in the light and the %s, %s surface seems almost ready to speak.",
		"Someone wore or showed this; the %s shape and %s patina give it away.",
	],
	"research":[
		"Its %s form shows where a maker tested an idea, failed and tried again; the %s patina keeps the record.",
		"Scholars argue over how its %s shape was worked, and the %s surface keeps them arguing.",
		"Nothing about its %s form is accidental, though time has left it %s.",
	],
	"economic":[
		"It is the kind of thing a household keeps, lends and trades; its %s form and %s skin tell of long use.",
		"It was useful before it was beautiful, and its %s, %s wear is the proof.",
		"Many hands passed it along; the %s shape and %s surface remember every one.",
	],
}
const MIDDLE_MADE:=[
	"Its %s %s motif was made by someone who had watched that %s all their life.",
	"The %s %s pattern repeats with a patience that feels like prayer, each %s a little different from the last.",
	"Whoever shaped it gave the %s %s pride of place; even the smallest %s is finished with care.",
]
const CLOSING:=[
	["Small as it is, it has outlasted every name that touched it.","Plain things endure; this one did.","It asks for nothing but a little attention."],
	["It is not rare, exactly — but no other is quite like it.","Visitors tend to linger over it a moment longer than they expect.","It rewards a second look."],
	["Few like it survive anywhere we know of.","Keepers handle it with both hands.","It has a way of quieting a room."],
	["Nothing else in the collection carries its weight of years.","Scholars travel to see it, and leave talking.","It is the kind of object a people is remembered by."],
	["Some objects are found; this one feels as if it was waiting.","Songs will be written about the finding of it.","It belongs to everyone who has ever wondered about the people before us."],
]

## Deterministic 1-3 sentence account from object, style, motif, material and origin.
static func story(item:Dictionary)->String:
	var tier:=clampi(int(item.get("rarity",0)),0,4)
	var site_id:=String(item.get("site_id",""))
	if tier==4 and site_id.begins_with("legend:"):
		var legend:=Sites.site_by_id(site_id)
		if not legend.is_empty():return String(legend.story)
	var h:=Sites.noise(String(item.get("id",""))+":story")
	var facets:=A.descriptor(item)
	var material:=String(facets.material) if not String(facets.material).is_empty() else "worked stone"
	var motif:=String(facets.motif) if not String(facets.motif).is_empty() else "weathered"
	var style:=String(facets.style) if not String(facets.style).is_empty() else "careful"
	var sentences:Array[String]=[]
	var made:=String(facets.origin)=="civilization" and not String(item.get("source_id","")).is_empty()
	if not site_id.is_empty():
		var site:=Sites.site_by_id(site_id)
		var people:=String(site.get("people","a forgotten people"))
		var line:String=OPEN_SITE[h%OPEN_SITE.size()]
		sentences.append(_cap(line % [Sites.inline(String(item.get("site_name","an old place"))),_cap(people) if "%s must" in line else people]))
	elif made:
		sentences.append(OPEN_MADE[h%OPEN_MADE.size()] % String(item.get("source_name","a distant society")))
	else:
		sentences.append(_cap(OPEN_WILD[h%OPEN_WILD.size()] % [motif,material]))
	var insight:=String(item.get("insight",""))
	if not insight.is_empty():
		sentences.append(insight.strip_edges())
	elif made and not String(facets.motif).is_empty():
		sentences.append(_cap(String(MIDDLE_MADE[(h/7)%MIDDLE_MADE.size()]) % [style,motif,motif]))
	else:
		var lean:=A.channels(item)
		var channel:="culture"
		for key:String in ["research","economic"]:
			if float(lean[key])>float(lean[channel]):channel=key
		var options:Array=MIDDLE[channel]
		sentences.append(_cap(String(options[(h/7)%options.size()]) % [style,motif]))
	var count:=0
	for sentence:String in sentences:count+=maxi(1,sentence.count(". ")+1)
	if count<3 and (tier>=2 or (h/31)%3==0):
		var closings:Array=CLOSING[tier]
		sentences.append(String(closings[(h/97)%closings.size()]))
	return " ".join(sentences)

static func _cap(text:String)->String:return text.substr(0,1).to_upper()+text.substr(1) if not text.is_empty() else text
