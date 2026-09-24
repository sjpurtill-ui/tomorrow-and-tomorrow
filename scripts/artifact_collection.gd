extends RefCounted
## Deterministic material culture, owned by the existing society_exchange ledger.
const PREHISTORY=preload("res://scripts/prehistoric_artifacts.gd")
const FORMS := ["cutting blade", "carved bead", "counting token", "ceremonial bowl", "woven fragment", "engraved tablet", "measuring rod", "pendant", "seal", "figurine", "flute", "painted panel", "storage jar", "spindle", "route marker", "calendar stone"]
const STYLES := ["etched", "painted", "banded", "dotted", "spiraling", "paired", "interlaced", "radiating", "bordered", "repeated", "angular", "flowing", "layered", "faded", "polished", "miniature"]
const FORM_MATERIALS := ["flint", "shell", "bone", "clay", "fiber", "slate", "wood", "amber", "soapstone", "clay", "bone", "wood", "clay", "wood", "basalt", "limestone"]
const MOTIFS := ["river", "sun", "moon", "herd", "spiral", "mountain", "seed", "rain", "wave", "hand", "star", "bird", "leaf", "hearth", "path", "ancestor"]
const SUBJECTS := ["stone_sorting", "cordage", "tallies", "clay_shaping", "basketry", "oral_epics", "standard_measures", "customary_law", "pit_firing", "festival_calendar", "route_memory", "seasonal_patterns", "food_drying", "joinery", "well_siting", "civic_games"]
const TIERS := ["Common", "Unusual", "Rare", "Exceptional", "Legendary"]
const OBJECT_MATERIALS := {"clay_shaping":"clay","pit_firing":"fired clay","cordage":"plant fiber","basketry":"plant fiber","stone_sorting":"stone","joinery":"timber","tallies":"wood"}
const CHANNEL_WORDS := {
	"culture":["figurine","flute","pendant","bead","paint","panel","ochre","pigment","handprint","reed","ceremonial","calendar","song","mask","tooth","antler","feather"],
	"research":["blade","flake","chopper","hammer","point","measuring","rod","tablet","token","counting","spindle","marker","grinding","scratched","tally","stick","joint","cord","wick","lens","needle"],
	"economic":["bowl","jar","storage","vessel","seal","woven","container","basket","amber","soapstone","salt","slab","trial","shell","net"],
}
const MOTIF_WORDS := {
	"culture":["ancestor","sun","moon","star","hand","spiral","bird","ochre","painted","faintly"],
	"research":["mountain","angular","repeated","mineral","charcoal","measured","banded"],
	"economic":["river","herd","seed","rain","leaf","path","wave","polished","clay"],
}
const RAW_SHARE := .25 # unstudied pieces count at a quarter of their prestige
const FAMILY_CAP := .10
const STUDY_RATE := .25 # study work per assigned researcher-day at average education
const MAX_STUDY_WEIGHT := 12
const MUSEUM_ALLURE := .6
static var _channel_cache:Dictionary={}
static var _family_cache:Dictionary={}
static var _set_counts:Dictionary={}

static func site_claimed(id:String)->bool:
	if GameState.society_exchange.get("artifact_sites",{}).has(id):return true
	for actor:Dictionary in WorldSimulation.actors.values():
		var owner:Node=actor.get("systems",{}).get("GameState")
		if owner!=null and owner.society_exchange.get("artifact_sites",{}).has(id):return true
	return false

static func find_at(seed:int, position:Vector2, day:int)->Dictionary:
	var site := "%d:%d" % [floori(position.x/24), floori(position.y/24)]
	var code := absi(hash(str(seed)+":"+site))
	var variant := code % 4096
	var roll := (code / 4096) % 1000
	var tier := 4 if roll>=997 else 3 if roll>=975 else 2 if roll>=880 else 1 if roll>=600 else 0
	var ancient:=PREHISTORY.definition(variant)
	ancient.merge({"id":"artifact:"+str(seed)+":"+site,"kind":"artifact","source_id":"","source_name":"Prehistoric find at "+site,"position":{"x":position.x,"z":position.y},"observed_day":day,"returned_day":day,"study":0.0,"work":20.0+tier*20.0,"signals":["survey","culture","research"],"rarity":tier,"held_days":0.0,"exhibited":false,"acquisition":"Prehistoric remnant recovered on physically visited uncharted ground"})
	return ancient

static func prestige(item:Dictionary)->float:
	return pow(2.5,int(item.get("rarity",0)))*(1.0+log(1.0+float(item.get("held_days",0))/360.0))*set_factor(item)

static func price(item:Dictionary)->float:
	return snappedf(20.0*prestige(item)*(1.0+float(item.study)),.01)

static func summary()->Dictionary:
	var result := {"count":0,"prestige":0.0,"science":0.0,"culture":0.0,"exhibited":0,"studied":0,"culture_value":0.0,"research_value":0.0,"economic_value":0.0}
	var collections:Dictionary=WorldSimulation.state.society_exchange.collections
	# Sets are counted first so each piece's prestige sees its siblings.
	var sets:Dictionary={}
	for item:Dictionary in collections.values():
		if item.kind=="artifact" and item.has("site_id"):sets[String(item.site_id)]=int(sets.get(String(item.site_id),0))+1
	if _set_counts.size()>256:_set_counts.clear()
	_set_counts[WorldSimulation.state.get_instance_id()]=sets
	var families:Dictionary={}
	for item:Dictionary in collections.values():
		if item.kind!="artifact":continue
		var worth:=prestige(item)
		result.count+=1;result.prestige+=worth
		if item.get("exhibited",false):result.exhibited+=1
		if not culture_piece(item) or float(item.study)<1:continue
		result.studied+=1
		var value:=values(item,worth)
		result.culture_value+=value.culture;result.research_value+=value.research;result.economic_value+=value.economic
		var family:=family_of(String(item.discovery_id))
		families[family]=float(families.get(family,0))+float(value.research)
	# Unstudied objects carry only a small raw prestige; study unlocks the rest.
	result.science=log(1.0+float(result.prestige)*RAW_SHARE+float(result.research_value))*.045
	result.culture=log(1.0+float(result.prestige)*RAW_SHARE+float(result.culture_value))*.075
	for family:String in families:result["family_"+family]=minf(FAMILY_CAP,log(1.0+float(families[family]))*.03)
	return result

static func bonus(domain:String)->float:
	var bonuses:Dictionary=WorldSimulation.state.society_exchange.get("artifact_bonuses",{})
	return float(bonuses.get("culture" if domain=="culture" else "science",0))+float(bonuses.get("family_"+domain,0))

static func museum_ready()->bool:
	return "public_libraries" in WorldSimulation.state.known_discoveries and "comparative_chronicles" in WorldSimulation.state.known_discoveries

static func exhibit(id:String)->Dictionary:
	var item:Dictionary=WorldSimulation.state.society_exchange.collections.get(id,{})
	if item.get("kind","")!="artifact":return {"error":"This object is no longer held here."}
	if not museum_ready():return {"error":"Public libraries and comparative chronicles are needed to curate a museum collection."}
	item.exhibited=not bool(item.get("exhibited",false))
	return {"ok":true}

static func advance(elapsed:int)->void:
	var state:=WorldSimulation.state
	var attraction:=0.0
	var unstudied:=0
	for item:Dictionary in state.society_exchange.collections.values():
		if item.kind!="artifact":continue
		item["held_days"]=float(item.get("held_days",0))+elapsed
		if role_studied(item) and float(item.study)<1:unstudied+=1
		if item.get("exhibited",false) and museum_ready() and float(item.study)>=1:attraction+=prestige(item)*(.6+float(channels(item).economic))
	# Other rulers staff the same role through their own research budget.
	if WorldSimulation.actor_id!="player" and String(WorldSimulation.actors.get(WorldSimulation.actor_id,{}).get("controller",""))=="ai":
		var role:Dictionary=study_role()
		if int(role.weight)!=(1 if unstudied>0 else 0):role.weight=1 if unstudied>0 else 0;state.society_exchange["artifact_study"]=role
	study(elapsed,int(state.elapsed_days))
	state.society_exchange["artifact_bonuses"]=summary()
	# Visitors pay from existing household money; exhibitions never mint currency.
	var revenue:=0.0
	if state.economy_stage=="currency" and attraction>0:
		var staff:=state.effective_workers("Knowledge")
		var draw:=1.0+preload("res://scripts/artifact_culture.gd").allure()*MUSEUM_ALLURE
		revenue=minf(state.private_currency*.001*elapsed,minf(attraction,staff*10)*.02*elapsed*draw)
		state.private_currency-=revenue;state.public_treasury+=revenue
	state.society_exchange["museum_revenue"]=revenue

## Material-culture pieces are studied by the artifact-study research role.
## Disassembled manufactured specimens remain ordinary Knowledge study.
static func culture_piece(item:Dictionary)->bool:
	return item.get("kind","")=="artifact" and not bool(item.get("reverse_engineered",false))

## Recovered finds (no living maker) wait for the artifact-study role. Craft
## samples handed over by a living society are practice evidence and remain in
## the ordinary Knowledge study queue, though they still count as culture once studied.
static func role_studied(item:Dictionary)->bool:
	return culture_piece(item) and String(item.get("source_id","")).is_empty()

static func study_role()->Dictionary:
	var saved:Variant=WorldSimulation.state.society_exchange.get("artifact_study",{})
	var role:={"weight":0,"focus":""}
	if saved is Dictionary:role.weight=clampi(int(saved.get("weight",0)),0,MAX_STUDY_WEIGHT);role.focus=String(saved.get("focus",""))
	return role

static func set_study_weight(weight:int)->void:
	var role:=study_role();role.weight=clampi(weight,0,MAX_STUDY_WEIGHT)
	WorldSimulation.state.society_exchange["artifact_study"]=role

## Researchers assigned through the shared emphasis budget and their daily work.
static func study_capacity()->Dictionary:
	var state:=WorldSimulation.state
	var weight:=int(study_role().weight)
	var total:=int(WorldSimulation.discovery.research_emphasis_total())
	var minds:=maxf(0.0,float(state.effective_workers("Knowledge")))
	var researchers:=minds*float(weight)/maxf(1.0,float(total)) if weight>0 else 0.0
	var education:=preload("res://scripts/civilization_indicators.gd").education_index(state)
	var food:=clampf(float(state.simulation_metrics.get("food_intake_ratio",1)),0,1)
	return {"weight":weight,"total_weight":total,"researchers":researchers,"education":education,"rate":researchers*lerpf(.55,1.45,education)*STUDY_RATE*food}

static func study(elapsed:int,day:int)->void:
	var pool:=float(study_capacity().rate)*elapsed
	if pool<=0:return
	var collections:Dictionary=WorldSimulation.state.society_exchange.collections
	var queue:Array=[]
	var focus:=String(study_role().focus)
	if collections.has(focus):queue.append(collections[focus])
	queue.append_array(collections.values())
	for item:Dictionary in queue:
		if pool<=0:break
		if not role_studied(item) or float(item.study)>=1 or day<int(item.returned_day):continue
		var work:=maxf(1.0,float(item.work))
		var used:=minf(pool,(1.0-float(item.study))*work)
		pool-=used
		item.study=minf(1.0,float(item.study)+used/work)
		if item.study>=.9999:
			item.study=1.0
			preload("res://scripts/society_exchange.gd").finish_study(item,day)

## Deterministic presentation facets; catalogue ids encode form, style and motif.
static func descriptor(item:Dictionary)->Dictionary:
	var id:=int(item.get("catalogue_id",-1))
	var origin:=String(item.get("artifact_origin","prehistoric" if String(item.get("source_id","")).is_empty() else "civilization"))
	if origin=="prehistoric" and id>=0 and id<4096:
		var form:=String(item.get("form",PREHISTORY.FORMS[id%16])).trim_prefix("the ")
		return {"object":form,"style":PREHISTORY.VARIANTS[(id/16)%16],"motif":PREHISTORY.TRACES[(id/256)%16],"material":String(item.get("material",PREHISTORY.MATERIALS[id%16])),"origin":origin}
	if id>=0 and id<4096:
		return {"object":FORMS[id%16],"style":STYLES[(id/16)%16],"motif":MOTIFS[(id/256)%16],"material":String(item.get("material",FORM_MATERIALS[id%16])),"origin":origin}
	var subject:=String(item.get("discovery_id",""))
	return {"object":String(item.get("name","object")).to_lower(),"style":"","motif":"","material":String(item.get("material",OBJECT_MATERIALS.get(subject,"worked material"))),"origin":origin}

## Culture/research/economic leaning (sums to 1) from object, material, motif and family.
static func channels(item:Dictionary)->Dictionary:
	var key:=String(item.get("id",""))+"|"+String(item.get("name",""))
	if _channel_cache.has(key):return _channel_cache[key]
	var facets:=descriptor(item)
	var weights:={"culture":.5,"research":.5,"economic":.5}
	var text:=(String(facets.object)+" "+String(facets.material)).to_lower()
	for channel:String in CHANNEL_WORDS:
		for word:String in CHANNEL_WORDS[channel]:
			if word in text:weights[channel]+=.6;break
	var motif:=(String(facets.motif)+" "+String(facets.style)).to_lower()
	for channel:String in MOTIF_WORDS:
		for word:String in MOTIF_WORDS[channel]:
			if word in motif:weights[channel]+=.3;break
	var family:=family_of(String(item.get("discovery_id","")))
	if family=="culture":weights.culture+=.7
	elif family=="knowledge":weights.research+=.7
	elif family in ["production","labor","logistics","infrastructure","nutrition"]:weights.economic+=.35;weights.research+=.35
	else:weights.research+=.5
	var total:=float(weights.culture)+float(weights.research)+float(weights.economic)
	for channel:String in weights:weights[channel]=float(weights[channel])/total
	if _channel_cache.size()>40000:_channel_cache.clear()
	_channel_cache[key]=weights
	return weights

## Real values once studied: culture and research in prestige units, economic
## in currency-equivalent appraisal. Unstudied pieces yield nothing here.
static func values(item:Dictionary,worth:float=-1.0)->Dictionary:
	if not culture_piece(item) or float(item.get("study",0))<1:return {"culture":0.0,"research":0.0,"economic":0.0}
	if worth<0:worth=prestige(item)
	var lean:=channels(item)
	return {"culture":snappedf(worth*3.0*float(lean.culture),.01),"research":snappedf(worth*3.0*float(lean.research),.01),"economic":snappedf(20.0*worth*2.0*(.4+float(lean.economic)),.01)}

static func family_of(subject:String)->String:
	if _family_cache.has(subject):return _family_cache[subject]
	var family:=String(WorldSimulation.discovery.discovery_definition(subject).get("dynamic","culture" if subject in ["oral_epics","festival_calendar","civic_games","customary_law"] else "knowledge"))
	_family_cache[subject]=family
	return family

## Holding more of one lost people's set raises each member's standing (max x1.5).
static func set_factor(item:Dictionary)->float:
	var set_id:=String(item.get("site_id",""))
	var size:=int(item.get("set_size",1))
	if set_id.is_empty() or size<=1:return 1.0
	var held:=clampi(int(_set_counts.get(WorldSimulation.state.get_instance_id(),{}).get(set_id,1)),1,size)
	return 1.0+.30*float(held-1)/float(size-1)+(.20 if held>=size else 0.0)

static func set_held(set_id:String)->int:
	var held:=0
	for item:Dictionary in WorldSimulation.state.society_exchange.collections.values():
		if item.get("kind","")=="artifact" and String(item.get("site_id",""))==set_id:held+=1
	return held

static func transfer(id:String,recipient:String,mode:String,offered:String="")->Dictionary:
	var source:=WorldSimulation.state
	var source_id:=WorldSimulation.actor_id
	var target:Node=GameState if recipient=="player" else WorldSimulation.actors.get(recipient,{}).get("systems",{}).get("GameState")
	if target==null or target==source or mode not in ["gift","sell","trade"]:return {"error":"Choose another civilization and a supported exchange."}
	var view_id:="human" if recipient=="player" else recipient
	var index:int=WorldSimulation.world._civilization_index(view_id)
	if index<0 or WorldSimulation.world.civilizations[index].player_relation.get("at_war",false):return {"error":"A peaceful contact is required."}
	if not source.society_exchange.connections.has(recipient):return {"error":"Establish contact through a returned journey first."}
	var item:Dictionary=source.society_exchange.collections.get(id,{})
	if item.get("kind","")!="artifact" or target.society_exchange.collections.has(id):return {"error":"The object is unavailable."}
	if target.society_exchange.collections.size()>=16384:return {"error":"The recipient collection is full."}
	var other:Dictionary=target.society_exchange.collections.get(offered,{})
	if mode=="trade" and (other.get("kind","")!="artifact" or source.society_exchange.collections.has(offered) or price(item)<price(other)):return {"error":"Offer an artifact worth at least the requested object."}
	var value:=price(item)
	if mode=="sell":
		if source.economy_stage!="currency" or target.economy_stage!="currency":return {"error":"Both civilizations need currency before a sale."}
		if target.public_treasury<value:return {"error":"The buyer cannot afford this object."}
		var reserve:=0.0
		for amount:float in target.monetary_reserve_metals.values():reserve+=amount
		if reserve<value/2.5:return {"error":"The buyer lacks transferable monetary backing."}
		var backing:=value/2.5
		for metal:String in target.monetary_reserve_metals:
			var moved:=minf(backing,float(target.monetary_reserve_metals[metal]))
			target.monetary_reserve_metals[metal]-=moved
			source.monetary_reserve_metals[metal]=float(source.monetary_reserve_metals.get(metal,0))+moved
			backing-=moved
		target.public_treasury-=value;target.currency_supply-=value
		source.public_treasury+=value;source.currency_supply+=value
	var message:="%s: %s transferred to %s." % [mode.capitalize(),item.name,target.settlement_name]
	for owner:Node in [source,target]:
		owner.society_exchange.history.push_front({"day":int(source.elapsed_days),"text":message})
		if owner.society_exchange.history.size()>64:owner.society_exchange.history.resize(64)
	move(source,target,item)
	if mode=="trade":move(target,source,other)
	if mode=="gift" and (source_id+":"+recipient) not in item.get("gift_receipts",[]) and item.get("gift_receipts",[]).size()<64:
		if not item.has("gift_receipts"):item.gift_receipts=[]
		item.gift_receipts.append(source_id+":"+recipient)
		WorldSimulation.scoped(recipient,func()->void:
			var ties:Dictionary=preload("res://scripts/society_exchange.gd").connection(source_id)
			ties.respect=minf(1,float(ties.respect)+minf(.15,prestige(item)*.005)))
	for owner:Node in [source,target]:
		var owner_key:=source_id if owner==source else recipient
		WorldSimulation.scoped(owner_key,func()->void:owner.society_exchange["artifact_bonuses"]=summary())
	return {"ok":true,"value":value}

static func move(source:Node,target:Node,item:Dictionary)->void:
	source.society_exchange.collections.erase(item.id)
	if source.society_exchange.evidence.get(item.discovery_id)==item.id:
		source.society_exchange.evidence.erase(item.discovery_id)
		for replacement:Dictionary in source.society_exchange.collections.values():
			if replacement.discovery_id==item.discovery_id and replacement.study>=1:source.society_exchange.evidence[item.discovery_id]=replacement.id;break
	item.exhibited=false;item.returned_day=int(target.elapsed_days)
	target.society_exchange.collections[item.id]=item
	if item.study>=1:target.society_exchange.evidence[item.discovery_id]=item.id
