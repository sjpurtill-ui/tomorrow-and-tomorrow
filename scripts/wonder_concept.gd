extends RefCounted
## Conceived wonders. There is no list: a wonder is composed from a bounded
## grammar — form × purpose × ambition × materials — gated by what a people
## knows and has, motivated by what it values and what it is living through,
## and named in its own naming tradition. Everything is deterministic from the
## world seed, owner, day and trigger. Player and AI use identical rules.
##
## A concept id encodes the whole definition so any system can rebuild it:
##   "wonder:<form>:<purpose>:<ambition>:<material>:<tier>:<token>"
const AMBITIONS:Array[String]=["modest","grand","audacious"]
const AMBITION_WORK:={"modest":.6,"grand":1.0,"audacious":2.0}
## Engineering demand an ambition places on a people's capability.
const AMBITION_DEMAND:={"modest":.45,"grand":.65,"audacious":.88}
## Overreach: audacious works fail far more often...
const AMBITION_RISK:={"modest":.5,"grand":1.0,"audacious":1.8}
## ...and pay far more when they stand.
const AMBITION_PAY:={"modest":.5,"grand":1.0,"audacious":2.5}
const AMBITION_TRIUMPH:={"modest":.6,"grand":1.0,"audacious":1.5}
const OUTCOMES:Array[String]=["triumph","success","flawed","collapse","abandoned"]
const OUTCOME_PAY:={"triumph":1.35,"success":1.0,"flawed":.5,"collapse":0.0,"abandoned":0.0}
const OUTCOME_CONDITION:={"triumph":1.0,"success":.9,"flawed":.6}
const ERA_BY_TIER:=["founding","founding","classical","medieval","industrial","modern"]
const TIER_MARKERS:=[[1,["masonry_bond_patterns","joinery","clay_shaping","framed_construction"]],[2,["voussoir_arch_assembly","domed_masonry_roofs","gravity_conduit_grade_control"]],[3,["masonry_buttressing","vaulted_masonry_roofs","hydraulic_lime_binders"]],[4,["clinker_cement","steel_refining","heat_engine_cycles"]],[5,["concrete_mix_design","electrical_generators","stored_program_control"]]]
## Form: visual (map silhouette family), base work, any-of discoveries (empty =
## always), usable materials, water need, nouns, and heavy (extra demand).
const FORMS:={
	"ring":{"visual":"ring","work":4000,"requires":[],"materials":["stone","timber"],"nouns":["Ring","Circle","Stone-ring"]},
	"mound":{"visual":"mound","work":5500,"requires":[],"materials":["earth","stone"],"nouns":["Mound","Barrow","Hill"]},
	"stair":{"visual":"terrace","work":7000,"requires":["seasonal_patterns","masonry_bond_patterns"],"materials":["stone","brick","earth"],"nouns":["Stair","Stairway","Terrace"]},
	"tower":{"visual":"mound","work":8000,"requires":["masonry_bond_patterns","joinery"],"materials":["stone","brick","timber","iron","concrete"],"nouns":["Tower","Spire","Pillar"],"heavy":true},
	"hall":{"visual":"hall","work":6000,"requires":["joinery","framed_construction"],"materials":["timber","stone","brick"],"nouns":["Hall","House","Longhouse"]},
	"cistern":{"visual":"basin","work":6000,"requires":["clay_shaping","drainage"],"materials":["stone","brick","earth"],"nouns":["Cistern","Basin","Well-court"]},
	"granary":{"visual":"granary","work":7000,"requires":["public_stores"],"materials":["timber","brick","stone"],"nouns":["Granary","Storehouse","Bin-house"]},
	"bridge":{"visual":"mound","work":9000,"requires":["voussoir_arch_assembly","steel_refining"],"materials":["stone","iron","concrete"],"nouns":["Bridge","Span","Crossing"],"water":true,"heavy":true},
	"causeway":{"visual":"terrace","work":8000,"requires":["drainage"],"materials":["earth","stone"],"nouns":["Causeway","Road","Dyke"],"water":true},
	"dam":{"visual":"basin","work":14000,"requires":["hydraulic_lime_binders","clinker_cement","concrete_mix_design"],"materials":["stone","concrete"],"nouns":["Dam","Barrage","Weir"],"water":true,"heavy":true},
	"colossus":{"visual":"mound","work":12000,"requires":["masonry_bond_patterns"],"materials":["stone","iron","brick"],"nouns":["Colossus","Giant","Watcher"],"heavy":true},
	"garden":{"visual":"orchard","work":6000,"requires":["seed_selection"],"materials":["earth","timber","stone"],"nouns":["Garden","Grove","Orchard"]},
	"observatory":{"visual":"terrace","work":7500,"requires":["seasonal_patterns","lens_centering"],"materials":["stone","brick"],"nouns":["Observatory","Star-stair","Sky-house"]},
	"gate":{"visual":"ring","work":6500,"requires":["voussoir_arch_assembly"],"materials":["stone","brick","iron"],"nouns":["Gate","Arch","Threshold"]},
	"canal":{"visual":"basin","work":11000,"requires":["gravity_conduit_grade_control","drainage"],"materials":["earth","stone","brick"],"nouns":["Canal","Water-road","Channel"],"water":true},
	"archive":{"visual":"hall","work":6500,"requires":["tallies","public_libraries","manuscript"],"materials":["timber","stone","brick"],"nouns":["Archive","Library","Memory-house"]},
	"amphitheatre":{"visual":"terrace","work":9000,"requires":["festival_calendar"],"materials":["stone","earth"],"nouns":["Amphitheatre","Theatre","Singing Bowl"]},
	"lighthouse":{"visual":"mound","work":8500,"requires":["coastal_watercraft","galley_navigation"],"materials":["stone","brick","iron"],"nouns":["Lighthouse","Beacon","Lamp"],"water":true,"heavy":true},
}
const MATERIALS:={
	"earth":{"cost":{"Clay":1.0},"quality":.5,"requires":[],"word":"earthen","noun":"earth"},
	"timber":{"cost":{"Timber":.8,"Fiber Plants":.2},"quality":.6,"requires":[],"word":"timbered","noun":"timber"},
	"stone":{"cost":{"Stone":.85,"Timber":.15},"quality":.8,"requires":[],"word":"stone","noun":"stone"},
	"brick":{"cost":{"Clay":.7,"Timber":.3},"quality":.75,"requires":["clay_shaping"],"word":"brick","noun":"brick"},
	"iron":{"cost":{"Iron Ore":.6,"Coal":.3,"Stone":.1},"quality":.95,"requires":["steel_refining"],"word":"iron","noun":"iron"},
	"concrete":{"cost":{"Stone":.6,"Clay":.2,"Coal":.2},"quality":1.0,"requires":["clinker_cement","concrete_mix_design"],"word":"poured-stone","noun":"poured stone"},
}
## Purpose: effect family and practical rewards (at "grand"/"success" = 1.0),
## local worker role, favored forms, and the words its names are made of.
const PURPOSES:={
	"honor_dead":{"family":"civic","rewards":{"reputation":.04},"role":"Administration","forms":["mound","ring","stair","colossus"],"label":"honor the dead",
		"epithet":["Weeping","Silent","Remembering","Ashen","Mourning"],"things":["Winters","Names","Lanterns","Graves"],"phrase":["Keeps-the-Names","Never-Forgets","Holds-the-Fallen"],"decree":["Keep the Day of Names","Once a year the names of the dead are read aloud at the work, and no quarrel may be pursued that day."]},
	"bind_tribes":{"family":"civic","rewards":{"reputation":.03,"attraction":.02},"role":"Administration","forms":["ring","hall","amphitheatre","gate"],"label":"bind the people together",
		"epithet":["Joined","Common","Kindred","Braided","Many-Handed"],"things":["Hearths","Clans","Oaths","Hands"],"phrase":["Holds-Us-Together","Binds-the-Clans","Shares-the-Fire"],"decree":["Summon the Joined Council","Every settlement sends a voice to the work to settle disputes together."]},
	"tame_flood":{"family":"","rewards":{"water_capacity":8000.0,"food_capacity":6000.0,"spoilage":.08},"role":"Food","forms":["causeway","dam","canal","cistern","stair"],"label":"tame the waters",
		"epithet":["Patient","Unbroken","Drowned","High","Steadfast"],"things":["Floods","Rains","Tides","Springs"],"phrase":["Holds-Back-the-River","Drinks-the-Storm","Turns-the-Flood"],"decree":["Keep the Flood Watch","Keepers of the work ring the alarm at high water, and the low fields are cleared in time."]},
	"feed_people":{"family":"covenant","rewards":{"food_capacity":9000.0,"spoilage":.12},"role":"Logistics","forms":["granary","garden","cistern","stair"],"label":"end hunger",
		"epithet":["Full","Sealed","Generous","Covenant","Brimming"],"things":["Harvests","Loaves","Seasons","Bins"],"phrase":["Never-Goes-Empty","Feeds-the-Children","Remembers-the-Famine"],"decree":["Invoke the Covenant","In famine the sealed stores are opened to every household in equal measure."]},
	"watch_heavens":{"family":"watching_sky","rewards":{"research":.08},"role":"Knowledge","forms":["observatory","stair","tower","ring"],"label":"watch the heavens",
		"epithet":["Watching","Star-Counting","Far-Seeing","Waking","Patient"],"things":["Stars","Moons","Seasons","Skies"],"phrase":["Reads-the-Sky","Counts-the-Moons","Sees-the-Storm-Coming"],"decree":["Read the Sky Aloud","The watchers announce the coming season, and stores are planned by their reading."]},
	"awe_rivals":{"family":"deterrence","rewards":{"reputation":.06},"role":"Administration","forms":["colossus","tower","gate","mound"],"label":"awe every rival",
		"epithet":["Dreadful","Iron","Unyielding","Towering","Wrathful"],"things":["Spears","Crowns","Thunders","Kings"],"phrase":["Frightens-the-Proud","Watches-the-Border","Stands-Over-All"],"decree":["Light the Beacons","Fires burn on the work so every neighbor knows the land is watched."]},
	"remember_knowledge":{"family":"long_song","rewards":{"research":.06},"role":"Knowledge","forms":["archive","hall","stair","tower"],"label":"keep what we know",
		"epithet":["Unforgetting","Written","Singing","Deep","Patient"],"things":["Songs","Books","Voices","Tallies"],"phrase":["Never-Forgets","Keeps-the-Songs","Remembers-for-Us"],"decree":["Add a Verse","The keepers add this year's events to the record so they are never lost."]},
	"welcome_strangers":{"family":"traffic","rewards":{"attraction":.05,"reputation":.03},"role":"Administration","forms":["gate","lighthouse","bridge","hall","canal"],"label":"welcome strangers",
		"epithet":["Open","Guiding","Welcoming","Lantern","Wayfarers'"],"things":["Roads","Ships","Travelers","Lamps"],"phrase":["Guides-the-Lost","Opens-to-All","Lights-the-Way-Home"],"decree":["Proclaim Sanctuary","Any stranger who reaches the work is under protection until their business is done."]},
	"master_craft":{"family":"","rewards":{"craft":.10},"role":"Crafting","forms":["hall","tower","colossus","bridge"],"label":"show our mastery",
		"epithet":["Hundred-Fired","Masterwork","Cunning","Bright","Hammered"],"things":["Fires","Hammers","Hands","Wheels"],"phrase":["Shows-Our-Hands","Outworks-the-World","Never-Cools"],"decree":["Light the Hundred Fires","Once a year every workshop fires together and apprentices show their first work."]},
	"defy_gods":{"family":"civic","rewards":{"attraction":.04,"reputation":.05},"role":"Administration","forms":["tower","colossus","stair","dam"],"label":"defy the heavens",
		"epithet":["Defiant","Sky-Reaching","Proud","Heaven-Daring","Impossible"],"things":["Heavens","Storms","Gods","Clouds"],"phrase":["Touches-the-Sky","Laughs-at-Storms","Answers-the-Gods"],"decree":["Declare the Defiance","The ruler proclaims that no fate is fixed, and every family may petition to change its lot."]},
	"mark_triumph":{"family":"","rewards":{"reputation":.06,"attraction":.03},"role":"Administration","forms":["gate","colossus","tower","amphitheatre"],"label":"mark a triumph",
		"epithet":["Victorious","Returning","Golden","Triumphal","Laureled"],"things":["Victories","Banners","Returns","Laurels"],"phrase":["Remembers-the-Victory","Welcomes-the-Brave","Never-Kneels"],"decree":["Read the Names","On the day of return the names of those who fought are read aloud."]},
	"give_thanks":{"family":"civic","rewards":{"food_capacity":4000.0,"spoilage":.06},"role":"Food","forms":["garden","ring","stair","hall"],"label":"give thanks",
		"epithet":["Grateful","Blessed","Harvest","Green","Singing"],"things":["Harvests","Blessings","Springs","Fields"],"phrase":["Gives-Thanks","Blesses-the-Fields","Sings-at-Harvest"],"decree":["Share the First Fruit","The first harvest is given to the youngest and the oldest before anyone else eats."]},
}
const TRADITIONS:Array[String]=["Riverlands","Highlands","Plateau","Eastern Valleys"]
const SYLLABLES:={
	"Riverlands":[["Var","Ash","Mer","Hol","Wen","Brin","Tam","Eld"],["row","ford","mere","ley","wick","den","holt","by"]],
	"Highlands":[["Dun","Glen","Kil","Craig","Bal","Strath","Inver","Ard"],["more","ach","ie","loch","rie","an","vane","dhu"]],
	"Plateau":[["Az","Dar","Kas","Per","Sar","Vah","Mir","Tab"],["and","ish","ar","esh","an","ur","abad","ez"]],
	"Eastern Valleys":[["Lan","Qing","Shu","Yun","Hua","Mei","Ling","Tai"],["shan","ling","he","tai","zhou","yuan","ping","an"]],
}
const NUMBERS:=["Seven","Nine","Twelve","Ninety","Hundred","Ten Thousand"]
## The purpose a trigger asks for first; later concepts follow the people's values.
const TRIGGER_PURPOSE:={"famine":"feed_people","flood":"tame_flood","war":"awe_rivals","victory":"mark_triumph","death":"honor_dead","anniversary":"bind_tribes","founding":"bind_tribes","discovery":"watch_heavens","envy":"awe_rivals","plenty":"give_thanks"}
const TRIGGER_WORDS:={"famine":"the hungry years","flood":"the great flood","war":"the war","victory":"the victory","death":"the death of a beloved leader","anniversary":"the founding's anniversary","discovery":"a new understanding","envy":"news of a rival's wonder","plenty":"a season of plenty","expand":"the old work's long service","founding":"the founding of the settlement"}

# --- Identity -----------------------------------------------------------------
static func _state(owner:String)->Node:return preload("res://scripts/society_exchange.gd").owner_state(owner)
static func _seed()->int:return int(GameState.world_seed)
## Well-mixed deterministic integer for a key (string hashes of neighbouring
## keys are themselves neighbours, so they pass through a PCG step).
static func _h(parts:String)->int:return mix(hash("%d|%s" % [_seed(),parts]))
static func mix(value:int)->int:
	var rng:=RandomNumberGenerator.new()
	rng.seed=value
	return int(rng.randi()&0x7FFFFFFF)
## Deterministic roll in [0,1) for a key.
static func unit_roll(parts:String)->float:return float(_h(parts)%1000000)/1000000.0
static func tradition(owner:String)->String:
	return TRADITIONS[_h("tradition|"+owner)%TRADITIONS.size()]
static func values(owner:String)->Dictionary:
	var s:=_state(owner)
	var result:Dictionary={}
	if s==null:return result
	var model:Variant=s.get("societal_values")
	if model is Dictionary:result=(model.get("lived",{}) as Dictionary).duplicate()
	return result
static func tier(known:Array)->int:
	var best:=0
	for marker:Array in TIER_MARKERS:
		for id in marker[1]:
			if id in known:best=maxi(best,int(marker[0]))
	return best
static func form_available(form:String,known:Array)->bool:
	var requires:Array=FORMS[form].requires
	if requires.is_empty():return true
	for id in requires:
		if id in known:return true
	return false
static func material_available(material:String,known:Array)->bool:
	var requires:Array=MATERIALS[material].requires
	if requires.is_empty():return true
	for id in requires:
		if id in known:return true
	return false
static func best_material(form:String,known:Array)->String:
	var best:="";var quality:=-1.0
	for material:String in FORMS[form].materials:
		if material_available(material,known) and float(MATERIALS[material].quality)>quality:best=material;quality=float(MATERIALS[material].quality)
	return best

# --- Ids and definitions --------------------------------------------------------
static func make_id(form:String,purpose:String,ambition:String,material:String,tier_value:int,token:String)->String:
	return "wonder:%s:%s:%s:%s:%d:%s" % [form,purpose,ambition,material,tier_value,token]
static func parse(id:String)->Dictionary:
	var parts:=id.split(":")
	if parts.size()!=7 or parts[0]!="wonder":return {}
	if not FORMS.has(parts[1]) or not PURPOSES.has(parts[2]) or parts[3] not in AMBITIONS or not MATERIALS.has(parts[4]):return {}
	if not parts[5].is_valid_int() or int(parts[5])<0 or int(parts[5])>5 or parts[6].is_empty() or parts[6].length()>16:return {}
	return {"form":parts[1],"purpose":parts[2],"ambition":parts[3],"material":parts[4],"tier":int(parts[5]),"token":parts[6]}
static func with_ambition(id:String,ambition:String)->String:
	var p:=parse(id)
	if p.is_empty() or ambition not in AMBITIONS:return ""
	return make_id(String(p.form),String(p.purpose),ambition,String(p.material),int(p.tier),String(p.token))
static func work_for(form:String,ambition:String,tier_value:int)->float:
	return roundf(float(FORMS[form].work)*float(AMBITION_WORK[ambition])*(1.0+tier_value*.5))
static func cost_for(form:String,ambition:String,material:String,tier_value:int)->Dictionary:
	var units:=work_for(form,ambition,tier_value)*.07
	var cost:Dictionary={}
	var weights:Dictionary=MATERIALS[material].cost
	for resource:String in weights:cost[resource]=roundf(units*float(weights[resource]))
	return cost
## Payoff multiplier for an ambition and outcome (0 for failures).
static func pay(ambition:String,outcome:String)->float:
	return float(AMBITION_PAY.get(ambition,1.0))*float(OUTCOME_PAY.get(outcome,1.0))
## Engine definition for a concept id (the same shape legacy catalog entries use).
static func definition(id:String)->Dictionary:
	var p:=parse(id)
	if p.is_empty():return {}
	var form:Dictionary=FORMS[p.form]
	var purpose:Dictionary=PURPOSES[p.purpose]
	var ambition:=String(p.ambition)
	var t:=int(p.tier)
	var era:=String(ERA_BY_TIER[t])
	var title:="%s %s to %s" % [String(ambition).capitalize(),String(form.nouns[0]),String(purpose.label)]
	return {"id":id,"title":title,"form":String(form.visual),"shape":String(p.form),"purpose":String(p.purpose),"ambition":ambition,"material":String(p.material),"tier":t,"discovery":"","requires":[],"environment":"any","population":0,
		"work":work_for(String(p.form),ambition,t),"cost":cost_for(String(p.form),ambition,String(p.material),t),"role":String(purpose.role),"bonus":minf(.08,.04*float(AMBITION_PAY[ambition])),
		"era":era,"effect":String(purpose.family),"lore":"","effect_text":_effect_text(String(p.purpose),ambition),"decree":{"id":String(p.purpose),"label":String(purpose.decree[0]),"text":String(purpose.decree[1])},
		"upgrade_from":"","shrine_slots":{"modest":1,"grand":2,"audacious":4}[ambition],"allure":6.0*float(AMBITION_PAY[ambition])*(1.0+t*.4),"concept":true}
static func _effect_text(purpose:String,ambition:String)->String:
	var family:=String(PURPOSES[purpose].family)
	var words:={"civic":"steadies cohesion and legitimacy","covenant":"seals a famine reserve from real surplus","watching_sky":"forecasts lean seasons and famine","long_song":"keeps leaders' memories and lost knowledge","deterrence":"makes rivals weigh war more gravely","traffic":"draws envoys, traders and refugees"}
	var parts:Array[String]=[]
	if words.has(family):parts.append(String(words[family]))
	var rewards:Dictionary=PURPOSES[purpose].rewards
	if rewards.has("food_capacity") or rewards.has("water_capacity"):parts.append("adds real storage")
	if rewards.has("research"):parts.append("strengthens research")
	if rewards.has("craft"):parts.append("strengthens crafting")
	if rewards.has("reputation"):parts.append("carries your name abroad")
	return ("If it stands, it %s; " % ", ".join(parts))+("a modest work pays little but rarely fails." if ambition=="modest" else ("an audacious work pays greatly and fails often." if ambition=="audacious" else "a grand work balances promise and risk."))
## Practical rewards for a finished work (scaled, bounded by Rewards caps).
static func rewards_for(purpose:String,ambition:String,outcome:String)->Dictionary:
	var scale:=pay(ambition,outcome)
	var result:Dictionary={}
	var base:Dictionary=PURPOSES.get(purpose,{}).get("rewards",{})
	for key:String in base:result[key]=snappedf(float(base[key])*scale,.0001)
	return result

# --- Motivation ----------------------------------------------------------------
## Purpose weights from values, needs/fears, trigger and environment.
static func purpose_weights(owner:String,trigger:Dictionary={})->Dictionary:
	var v:=values(owner)
	var s:=_state(owner)
	var weights:Dictionary={}
	for purpose:String in PURPOSES:weights[purpose]=1.0
	var get_v:=func(axis:String)->float:return float(v.get(axis,.5))
	weights.feed_people+=get_v.call("collective_obligation")*2.0+get_v.call("common_stewardship")
	weights.bind_tribes+=get_v.call("collective_obligation")+get_v.call("pluralism")
	weights.awe_rivals+=get_v.call("hierarchy")*2.0+get_v.call("centralization")
	weights.mark_triumph+=get_v.call("hierarchy")+get_v.call("achieved_status")
	weights.watch_heavens+=get_v.call("experimentation")*2.0
	weights.master_craft+=get_v.call("experimentation")+get_v.call("achieved_status")
	weights.welcome_strangers+=get_v.call("openness")*2.0+get_v.call("pluralism")
	weights.remember_knowledge+=get_v.call("restorative_justice")+(1.0-get_v.call("experimentation"))
	weights.honor_dead+=(1.0-get_v.call("experimentation"))+get_v.call("collective_obligation")*.5
	weights.give_thanks+=get_v.call("ecological_restraint")*2.0
	weights.defy_gods+=get_v.call("experimentation")+get_v.call("achieved_status")-get_v.call("ecological_restraint")
	if s!=null:
		var m:Dictionary=s.simulation_metrics
		if float(m.get("food_intake_ratio",1.0))<.95:weights.feed_people+=4.0;weights.give_thanks+=1.0
		if float(s.water_metrics.get("intake_ratio",1.0))<.95:weights.tame_flood+=3.0
		if float(m.get("cohesion",.5))<.45:weights.bind_tribes+=2.5
	match String(trigger.get("kind","")):
		"famine":weights.feed_people+=15.0;weights.give_thanks+=1.5
		"flood":weights.tame_flood+=15.0
		"war":weights.awe_rivals+=10.0;weights.honor_dead+=4.0
		"victory":weights.mark_triumph+=15.0;weights.awe_rivals+=2.0
		"death":weights.honor_dead+=15.0;weights.remember_knowledge+=2.0
		"anniversary","founding":weights.bind_tribes+=8.0;weights.honor_dead+=4.0
		"discovery":weights.watch_heavens+=6.0;weights.master_craft+=6.0;weights.remember_knowledge+=2.0
		"envy":weights.awe_rivals+=6.0;weights.master_craft+=4.0;weights.defy_gods+=4.0
		"plenty":weights.give_thanks+=12.0;weights.feed_people+=2.0
	var wanted:=String(trigger.get("purpose",""))
	if PURPOSES.has(wanted):weights[wanted]=float(weights[wanted])+20.0
	return weights

static func _weighted(weights:Dictionary,roll:int,exclude:Array=[])->String:
	var total:=0.0
	var keys:Array=weights.keys();keys.sort()
	for key in keys:
		if key not in exclude:total+=maxf(0.0,float(weights[key]))
	if total<=0.0:return ""
	var pick:=float(roll%100000)/100000.0*total
	for key in keys:
		if key in exclude:continue
		pick-=maxf(0.0,float(weights[key]))
		if pick<=0.0:return String(key)
	return String(keys[-1])

## The ambition a ruler of this temper would ask for.
static func proposed_ambition(owner:String,roll:int)->String:
	var v:=values(owner)
	var boldness:=float(v.get("hierarchy",.5))*.4+float(v.get("experimentation",.5))*.3+float(v.get("achieved_status",.5))*.3+float(roll%1000)/1000.0*.35-.15
	return "audacious" if boldness>.62 else ("grand" if boldness>.38 else "modest")

# --- Names -----------------------------------------------------------------------
static func place_name(owner:String,token:String)->String:
	var bank:Array=SYLLABLES[tradition(owner)]
	var h:=_h("place|"+owner+"|"+token)
	var head:String=bank[0][h%bank[0].size()]
	var tail:String=bank[1][(h/7)%bank[1].size()]
	return head+tail
## A name in the owner's tradition. `variant` walks alternatives on collision.
static func compose_name(owner:String,form:String,purpose:String,token:String,variant:int=0)->String:
	var p:Dictionary=PURPOSES[purpose]
	var h:=_h("name|%s|%s|%s|%s|%d" % [owner,form,purpose,token,variant])
	var nouns:Array=FORMS[form].nouns
	var noun:String=nouns[h%nouns.size()]
	var epithet:String=p.epithet[(h/3)%p.epithet.size()]
	var thing:String=p.things[(h/5)%p.things.size()]
	var phrase:String=p.phrase[(h/11)%p.phrase.size()]
	var number:String=NUMBERS[(h/13)%NUMBERS.size()]
	var place:=place_name(owner,token+str(variant))
	var style:=int(TRADITIONS.find(tradition(owner)))
	var pattern:=(style+(h/17)%3)%4
	var result:=""
	match pattern:
		0:result="The %s %s of %s" % [epithet,noun,place]
		1:result="%s of the %s %s" % [noun,number,thing]
		2:result="%s-that-%s" % [noun,phrase]
		_:result="%s of %s %s" % [noun,"Ten Thousand" if number=="Hundred" else number,thing] if style==3 else "%s's %s %s" % [place,epithet,noun]
	return result.substr(0,60)
static func used_names()->Dictionary:
	var used:Dictionary={}
	var owners:Array=["player"];owners.append_array(WorldSimulation.actors.keys())
	for owner:String in owners:
		var s:=_state(owner)
		if s==null:continue
		for city:Dictionary in s.player_settlements:
			for r:Dictionary in city.get("undertakings",[]):
				used[String(r.get("custom_name",""))]=true
				for layer in r.get("layers",[]):
					if layer is Dictionary:used[String(layer.get("name",""))]=true
	return used
static func unique_name(owner:String,form:String,purpose:String,token:String,taken:Dictionary)->String:
	for variant in 12:
		var name:=compose_name(owner,form,purpose,token,variant)
		if not taken.has(name):return name
	var base:=compose_name(owner,form,purpose,token,0)
	for n in range(2,100):
		var numbered:=("%s %s" % [base,["the Second","the Third","the Fourth","the Fifth"][mini(n-2,3)] if n<6 else str(n)]).substr(0,60)
		if not taken.has(numbered):return numbered
	return (base+" "+token).substr(0,60)

static func lore_for(owner:String,form:String,purpose:String,material:String,trigger:Dictionary,token:String)->String:
	var h:=_h("lore|%s|%s" % [owner,token])
	var cause:=String(TRIGGER_WORDS.get(String(trigger.get("kind","")),""))
	var label:=String(PURPOSES[purpose].label)
	var noun:=String(FORMS[form].nouns[0]).to_lower()
	var mat:=String(MATERIALS[material].word)
	var stuff:=String(MATERIALS[material].noun)
	var article:="an" if mat.left(1).to_lower() in ["a","e","i","o","u"] else "a"
	var openers:=["Conceived after %s, " % cause if not cause.is_empty() else "Dreamed in a quiet season, ","Spoken of first at a winter fire, " if cause.is_empty() else "Born of %s, " % cause,"Asked for by the elders, "]
	var closers:=["%s %s %s raised to %s." % [article,mat,noun,label],"%s %s %s meant to %s for as long as the %s holds." % [article,mat,noun,label,stuff],"%s %s %s by which the people mean to %s." % [article,mat,noun,label]]
	return (String(openers[h%openers.size()])+String(closers[(h/3)%closers.size()])).substr(0,240)

static func motive_for(owner:String,purpose:String,trigger:Dictionary)->String:
	var v:=values(owner)
	var strongest:="";var high:=-1.0
	for axis in v:
		if absf(float(v[axis])-.5)>high:high=absf(float(v[axis])-.5);strongest=String(axis)
	var cause:=String(TRIGGER_WORDS.get(String(trigger.get("kind","")),""))
	var because:="Because of %s, " % cause if not cause.is_empty() else ""
	var value_word:=String(preload("res://scripts/societal_values_model.gd").VALUE_DEFINITIONS.get(strongest,{}).get("high" if float(v.get(strongest,.5))>=.5 else "low","OUR WAYS")).to_lower()
	return "%sa people that prizes %s wants to %s." % [because,value_word,String(PURPOSES[purpose].label)]

# --- Conception -----------------------------------------------------------------
## 1–3 fresh concepts for an owner. Deterministic in seed, owner, day and trigger.
## trigger: {kind, purpose?, form?, city_id?, work_id? (expand an existing site)}
static func conceive(owner:String="player",trigger:Dictionary={},count:int=3)->Array[Dictionary]:
	var s:=_state(owner)
	var result:Array[Dictionary]=[]
	if s==null:return result
	var known:Array=s.known_discoveries
	var t:=tier(known)
	# A stored pitch re-conceives exactly what was proposed on its own day.
	var day:=int(trigger.get("day",s.elapsed_days)) if (trigger.get("day") is int) else int(s.elapsed_days)
	var weights:=purpose_weights(owner,trigger)
	var taken:=used_names()
	var chosen:Array=[]
	for index in clampi(count,1,3):
		var key:="%s|%d|%s|%d" % [owner,day,str(trigger.get("kind",""))+str(trigger.get("purpose",""))+str(trigger.get("work_id","")),index]
		var h:=_h("conceive|"+key)
		var purpose:=_weighted(weights,h,chosen)
		var asked:=String(trigger.get("purpose",TRIGGER_PURPOSE.get(String(trigger.get("kind","")),"")))
		if index==0 and PURPOSES.has(asked):purpose=asked
		if purpose.is_empty():break
		chosen.append(purpose)
		var form:=_pick_form(purpose,known,String(trigger.get("form","")),h/100000,s)
		if form.is_empty():continue
		var material:=_pick_material(form,known,s,h/13)
		if material.is_empty():continue
		var token:="%x" % (h%0xFFFFFF)
		var ambition:=proposed_ambition(owner,h/7)
		var id:=make_id(form,purpose,ambition,material,t,token)
		var name:=unique_name(owner,form,purpose,token,taken)
		taken[name]=true
		var concept:=definition(id)
		concept.merge({"owner":owner,"name":name,"lore":lore_for(owner,form,purpose,material,trigger,token),"motive":motive_for(owner,purpose,trigger),"trigger":trigger.duplicate(),"tradition":tradition(owner),"proposed_ambition":ambition,"token":token,"day":day,
			"ambitions":_ambition_table(form,material,t,purpose)},true)
		if trigger.has("work_id"):concept.layer_on=String(trigger.work_id);concept.city_id=String(trigger.get("city_id",""))
		result.append(concept)
	return result

## A usable material, favoring quality and what the people actually hold.
static func _pick_material(form:String,known:Array,s:Node,roll:int)->String:
	var weights:Dictionary={}
	for material:String in FORMS[form].materials:
		if not material_available(material,known):continue
		var stock:=0.0
		for resource:String in MATERIALS[material].cost:stock+=float(s.resource_stockpiles.get(resource,0))
		weights[material]=float(MATERIALS[material].quality)*(1.0+minf(3.0,stock/2000.0))
	if weights.is_empty():return ""
	return _weighted(weights,roll)

static func _ambition_table(form:String,material:String,t:int,purpose:String)->Array:
	var rows:Array=[]
	for ambition:String in AMBITIONS:rows.append({"ambition":ambition,"work":work_for(form,ambition,t),"cost":cost_for(form,ambition,material,t),"rewards":rewards_for(purpose,ambition,"success")})
	return rows

static func _pick_form(purpose:String,known:Array,wanted:String,roll:int,s:Node)->String:
	var profile:Dictionary={}
	for city:Dictionary in s.player_settlements:
		if bool(city.get("primary",false)):profile=city.get("environment_profile",{})
	var wet:=float(profile.get("precipitation",.5))>=.45 or "river_craft" in known or "coastal_watercraft" in known
	var options:Array=[]
	if FORMS.has(wanted) and form_available(wanted,known) and (not FORMS[wanted].get("water",false) or wet):return wanted
	for form:String in PURPOSES[purpose].forms:
		if form_available(form,known) and (not FORMS[form].get("water",false) or wet) and not best_material(form,known).is_empty():options.append(form)
	if options.is_empty():
		for form:String in ["ring","mound"]:options.append(form)
	return String(options[roll%options.size()])

# --- Ruler-described wonders (offline keyword mapping) ------------------------------
const FORM_WORDS:={"tower":["tower","spire","pillar","minaret","obelisk"],"stair":["stair","steps","terrace","ziggurat","pyramid"],"ring":["ring","circle","henge","stones"],"mound":["mound","barrow","hill","tomb"],"hall":["hall","house","palace","longhouse","temple"],"cistern":["cistern","basin","well","reservoir","pool"],"granary":["granary","storehouse","barn","silo"],"bridge":["bridge","span","crossing"],"causeway":["causeway","road","dyke","levee"],"dam":["dam","barrage","weir"],"colossus":["colossus","statue","giant","idol"],"garden":["garden","grove","orchard","park"],"observatory":["observatory","sky","star","astronomy"],"gate":["gate","arch","door","threshold"],"canal":["canal","channel","waterway"],"archive":["archive","library","books","scriptorium"],"amphitheatre":["theatre","theater","amphitheatre","arena","stadium"],"lighthouse":["lighthouse","beacon","lamp"]}
const PURPOSE_WORDS:={"honor_dead":["dead","ancestor","ancestors","grave","memorial","mourn","tomb","fallen"],"bind_tribes":["unite","together","clans","tribes","bind","assembly","council"],"tame_flood":["flood","river","water","rain","drought","irrigation"],"feed_people":["food","famine","hunger","harvest store","grain","feed"],"watch_heavens":["stars","heavens","sky","moon","sun","season","astronomy"],"awe_rivals":["awe","fear","enemies","rivals","frighten","power","mighty"],"remember_knowledge":["knowledge","learning","books","memory","wisdom","songs","history"],"welcome_strangers":["strangers","travelers","traders","guests","welcome","ships"],"master_craft":["craft","skill","workshop","forge","art","mastery"],"defy_gods":["defy","gods","heaven","impossible","highest","tallest"],"mark_triumph":["victory","triumph","win","conquest","glory"],"give_thanks":["thanks","gratitude","blessing","plenty","bounty"]}
const AMBITION_WORDS:={"audacious":["greatest","tallest","impossible","colossal","largest","mightiest","audacious","enormous","vast"],"modest":["small","modest","simple","humble","little","quick"]}
## Map a ruler's words onto the grammar. Unknown words fall back to motivation.
static func concept_from_words(text:String,owner:String="player")->Dictionary:
	var lower:=text.to_lower()
	var trigger:Dictionary={"kind":"decree","words":text.substr(0,200)}
	for form:String in FORM_WORDS:
		for word:String in FORM_WORDS[form]:
			if lower.contains(word):trigger.form=form;break
		if trigger.has("form"):break
	var best:="";var hits:=0
	for purpose:String in PURPOSE_WORDS:
		var count:=0
		for word:String in PURPOSE_WORDS[purpose]:
			if lower.contains(word):count+=1
		if count>hits:hits=count;best=purpose
	if not best.is_empty():trigger.purpose=best
	var concepts:=conceive(owner,trigger,1)
	if concepts.is_empty():return {}
	var concept:Dictionary=concepts[0]
	var ambition:=String(concept.proposed_ambition)
	for level:String in AMBITION_WORDS:
		for word:String in AMBITION_WORDS[level]:
			if lower.contains(word):ambition=level
	return retarget(concept,ambition)
## Bound a model's JSON mapping ({form,purpose,ambition}) to the grammar.
static func concept_from_mapping(mapping:Dictionary,text:String,owner:String="player")->Dictionary:
	var trigger:Dictionary={"kind":"decree","words":text.substr(0,200)}
	if FORMS.has(String(mapping.get("form",""))):trigger.form=String(mapping.form)
	if PURPOSES.has(String(mapping.get("purpose",""))):trigger.purpose=String(mapping.purpose)
	var concepts:=conceive(owner,trigger,1)
	if concepts.is_empty():return {}
	var ambition:=String(mapping.get("ambition",""))
	return retarget(concepts[0],ambition if ambition in AMBITIONS else String(concepts[0].proposed_ambition))
## Optional model request, built only when the player has enabled the civic AI
## connection (PronouncementInterpreter._api_config). Returns {} otherwise; the
## caller performs the HTTP request and passes the reply to concept_from_mapping.
static func mapping_request(text:String)->Dictionary:
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null:return {}
	var interpreter:Node=tree.root.get_node_or_null("PronouncementInterpreter")
	if interpreter==null or not interpreter.has_method("_api_config"):return {}
	var config:Dictionary=interpreter.call("_api_config")
	if config.is_empty():return {}
	var system:="Map the ruler's description of a wonder onto JSON {\"form\":one of %s,\"purpose\":one of %s,\"ambition\":one of %s}. Reply with JSON only." % [JSON.stringify(FORMS.keys()),JSON.stringify(PURPOSES.keys()),JSON.stringify(AMBITIONS)]
	return {"config":config,"messages":[{"role":"system","content":system},{"role":"user","content":text.substr(0,600)}]}
## The same concept at another ambition (id, work, cost and table change; name kept).
static func retarget(concept:Dictionary,ambition:String)->Dictionary:
	if ambition not in AMBITIONS:return concept
	var id:=with_ambition(String(concept.get("id","")),ambition)
	if id.is_empty():return concept
	var result:=concept.duplicate(true)
	result.merge(definition(id),true)
	result.ambition=ambition
	return result

# --- Feasibility and outcomes ------------------------------------------------------
## In-world feasibility. Reads the owner's real state; never shown as a bare %.
## extra: {architect:Dictionary, shift:float}
static func assess(concept:Dictionary,owner:String="player",extra:Dictionary={})->Dictionary:
	var s:=_state(owner)
	if s==null or parse(String(concept.get("id",""))).is_empty():return {"score":0.0,"factors":[],"spoken":"No one can say what this would take.","costs":{},"duration_estimate":0}
	var p:=parse(String(concept.id))
	var d:=definition(String(concept.id))
	var m:Dictionary=s.simulation_metrics
	var factors:Array=[]
	var architect:Dictionary=extra.get("architect",{})
	var talent:=float(architect.get("talent",.72))
	var crafters:=float(s.population_allocations.get("Crafting",0))
	var builders:=float(s.population_allocations.get("Construction",0))
	var t:=int(p.tier)
	var capability:=.35+.08*t+.10*float(MATERIALS[p.material].quality)+.10*talent+.08*minf(1,crafters/10.0)+.05*minf(1,builders/20.0)
	var demand:=float(AMBITION_DEMAND[p.ambition])+(.05 if bool(FORMS[p.form].get("heavy",false)) else 0.0)
	var engineering:=clampf(.5+(capability-demand)*1.4,0,1)
	factors.append({"name":"Engineering","effect":snappedf(engineering-.5,.01),"text":"Our builders' knowledge (%s era), %s materials and a %s master builder against a %s design." % [String(ERA_BY_TIER[t]),String(MATERIALS[p.material].word),"gifted" if talent>=.8 else "capable",String(p.ambition)]})
	var cohesion:=float(m.get("cohesion",.5));var legitimacy:=float(m.get("legitimacy",.5))
	var fed:=clampf(float(m.get("food_intake_ratio",1.0)),0,1)
	var war:=_at_war(owner)
	var social:=cohesion*.35+legitimacy*.25+fed*.25+(0.0 if war else .15)
	factors.append({"name":"Cohesion","effect":snappedf(cohesion-.5,.01),"text":"The people %s." % ("stand together" if cohesion>=.6 else ("grumble but hold" if cohesion>=.4 else "are divided"))})
	factors.append({"name":"Legitimacy","effect":snappedf(legitimacy-.5,.01),"text":"The ruler's word %s." % ("is trusted" if legitimacy>=.6 else ("is doubted" if legitimacy<.4 else "is heeded"))})
	factors.append({"name":"Food","effect":snappedf(fed-.9,.01),"text":"Bellies are %s." % ("full" if fed>=.98 else ("thin" if fed>=.85 else "empty"))})
	if war:factors.append({"name":"War","effect":-.15,"text":"War draws away hands and hope."})
	var cover:=1.0
	for resource:String in d.cost:cover=minf(cover,float(s.resource_stockpiles.get(resource,0))/maxf(1,float(d.cost[resource])))
	factors.append({"name":"Materials","effect":snappedf(cover-1,.01),"text":"We hold %s of the %s it needs." % ["all" if cover>=1 else ("half" if cover>=.5 else "little"),String(MATERIALS[p.material].word)+" materials"]})
	var shift:=float(extra.get("shift",0.0))
	if absf(shift)>.001:factors.append({"name":"Construction so far","effect":snappedf(shift,.01),"text":"What has happened at the site %s the odds." % ("improved" if shift>0 else "worsened")})
	var score:=clampf(engineering*.6+social*.4+shift,.02,.98)
	var daily:=maxf(.1,builders*.2*.8)
	return {"score":snappedf(score,.001),"engineering":snappedf(engineering,.001),"social":snappedf(social,.001),"factors":factors,"spoken":spoken(score,String(p.ambition),factors,String(architect.get("name",""))),"costs":d.cost,"work":float(d.work),"duration_estimate":roundi(float(d.work)/daily),"odds":odds(score,String(p.ambition))}

static func _at_war(owner:String)->bool:
	if owner!="player" and not WorldSimulation.actors.has(owner):return false
	return bool(WorldSimulation.scoped(owner,func()->bool:
		if WorldSimulation.world==null:return false
		for civ:Dictionary in WorldSimulation.world.civilizations:
			if bool(civ.get("player_relation",{}).get("at_war",false)):return true
		return false))

static func spoken(score:float,ambition:String,factors:Array,who:String)->String:
	var worst:Dictionary={}
	for factor:Dictionary in factors:
		if worst.is_empty() or float(factor.effect)<float(worst.effect):worst=factor
	var speaker:=("%s says: " % who) if not who.is_empty() else "The master builders say: "
	var mood:=""
	if score>=.8:mood="\"It can be done, and done well. I would stake my name on it.\""
	elif score>=.62:mood="\"It can be done, if nothing goes badly wrong.\""
	elif score>=.45:mood="\"I will not lie to you: it may stand, it may not.\""
	elif score>=.3:mood="\"This is beyond us as we are. We would be praying, not building.\""
	else:mood="\"If we try this, it will fall, and it will take people with it.\""
	var caveat:=""
	if not worst.is_empty() and float(worst.effect)<-.05:caveat=" Their chief worry: %s" % String(worst.text).to_lower()
	var bold:=" An audacious design multiplies both the glory and the danger." if ambition=="audacious" else ""
	return speaker+mood+caveat+bold

## Outcome probabilities for a feasibility score and ambition.
static func odds(score:float,ambition:String)->Dictionary:
	var risk:=float(AMBITION_RISK.get(ambition,1.0))
	var collapse:=clampf(pow(1.0-score,1.6)*.9*risk,0,.9)
	var flawed:=clampf((1.0-score)*.45*sqrt(risk),0,1.0-collapse)
	var triumph:=clampf(score*score*.25*float(AMBITION_TRIUMPH.get(ambition,1.0)),0,1.0-collapse-flawed)
	return {"triumph":snappedf(triumph,.0001),"success":snappedf(maxf(0,1.0-collapse-flawed-triumph),.0001),"flawed":snappedf(flawed,.0001),"collapse":snappedf(collapse,.0001)}
## Deterministic outcome from a roll in [0,1).
static func resolve(score:float,ambition:String,roll:float)->String:
	var o:=odds(score,ambition)
	if roll<float(o.collapse):return "collapse"
	if roll<float(o.collapse)+float(o.flawed):return "flawed"
	if roll<float(o.collapse)+float(o.flawed)+float(o.triumph):return "triumph"
	return "success"
