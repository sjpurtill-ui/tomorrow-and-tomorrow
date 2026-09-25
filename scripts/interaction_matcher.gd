class_name InteractionMatcher
extends RefCounted
## Offline interaction engine. Given what the player said, where, and the
## current context, returns an intent, bounded effects scaled to that context,
## and an in-character reply, without any network access.
##
## Resolution ladder (offline never fails):
##   1. "match"   - a stored interaction is similar enough (TF-IDF cosine over
##                  canonical tokens + bigrams, character-trigram overlap,
##                  intent/type agreement and context-band proximity).
##   2. "type"    - the lexicon classifier recognises the interaction type; its
##                  canonical profile is used.
##   3. "default" - the generic custom-directive profile.

const _Text:=preload("res://scripts/interaction_text.gd")
const _Types:=preload("res://scripts/interaction_types.gd")
const _Context:=preload("res://scripts/interaction_context.gd")
const _Store:=preload("res://scripts/interaction_store.gd")
const _Voice:=preload("res://scripts/character_voice.gd")

const MATCH_THRESHOLD:=0.60
const TYPE_THRESHOLD:=0.22
const TYPE_CONFIDENCE_CAP:=0.68
const DEFAULT_CONFIDENCE:=0.12
const CANDIDATES:=32
const POSTING_BUDGET:=2000
const MAX_EFFECT:=0.08
const REF_POPULATION:=150.0
const BAND_POPULATION:Dictionary={"band":40.0,"hamlet":150.0,"village":500.0,"town":2500.0,"city":10000.0}
const EFFECT_ACTS:Array[String]=["order","blessing","threat","praise","rebuke","statement"]
const COUNT_HINTS:Dictionary={"report_request":"population","census_records":"population","rationing":"food_days","feast_celebration":"feast_days",
	"watch_security":"pop:0.025","conscription_defense":"work:0.3","hunting_foraging":"work:0.12","fishing":"work:0.1","medicine_care":"pop:0.04",
	"burial_funeral":"pop:0.02"}
const ADDRESS_TERMS:Array[String]=["Great One","Great Current","O Luminous One","O Luminous Seat","Sky-Holder","Bright One Above","Tide-Turner",
	"Fire-Giver","Undying One","Anointed One","Blessed Seat","High One","Measureless One","Esteemed Presider","Feast-Giver","Storm-Wielder"]
const ERA_SUBS:Dictionary={"grain":"seed","granary":"storage pit","granaries":"storage pits","bread":"flatcakes","bronze":"stone","iron":"stone",
	"copper":"stone","metal":"stone","sword":"spear","swords":"spears","temple":"sacred place","temples":"sacred places","priest":"fire-keeper",
	"priests":"fire-keepers","written":"remembered","ledger":"tally","ledgers":"tallies","coin":"shells","coins":"shells","tax":"levy","taxes":"levies",
	"cart":"sledge","carts":"sledges","wheel":"roller","boat":"float","boats":"floats","farm":"clearing","farms":"clearings","farmer":"planter",
	"farmers":"planters","crops":"plantings","crop":"planting","pots":"skins","jars":"skins","cloth":"hide","school":"teaching circle"}
const DEFAULT_NOTABLES:Array[String]=["Keen-Eye","Old Hollin","Tamsa","Brek","Wenlo","Ashkin"]
const DEFAULT_TRAITS:Array[String]=["quick of mind and slow to anger","sharp-eyed and sure-handed","patient, and clever with snares","strong, and wiser than he lets on"]

# Session state (not saved).
static var _emitted:Dictionary={}
static var _used_record_templates:Dictionary={}
static var _calls:int=0
# Index state.
static var _idx_revision:int=-1
static var _idx_count:int=0
static var _idx_norm_n:int=0
static var _postings:Dictionary={}
static var _rec_terms:Array=[]
static var _rec_norm:PackedFloat32Array=PackedFloat32Array()
static var _rec_tri:Dictionary={}
static var _vocab_tri:Dictionary={}
static var _vocab_tri_size:int=-1
static var last_timing_usec:int=0
static var last_timing_breakdown:Dictionary={}
static var _policy_catalog:Dictionary={}
static var _policy_catalog_loaded:bool=false

# ================================================================= public API

## Resolve player text offline. context keys (all optional): population,
## working_age, era_tier, era_tags, metrics{metric:0..1}, food_days,
## feasibility 0..1, compliance 0..1, speaker_model, voice_family, address,
## notable, trade, trait, neighbours, count. Empty context reads live state.
static func resolve(text:String,surface:String="civic",context:Dictionary={})->Dictionary:
	var t0:int=Time.get_ticks_usec()
	_calls+=1
	var ctx:Dictionary=_Context.from_live_state() if context.is_empty() else _Context.complete(context)
	var sig:Dictionary=_Context.signature(ctx)
	var t_cls:int=Time.get_ticks_usec()
	var cls:Dictionary=_Types.classify(text)
	var act:String=String(cls.speech_act)
	var t_match:int=Time.get_ticks_usec()
	var matches:Array=_best_matches(text,surface,cls,sig)
	var t_after:int=Time.get_ticks_usec()
	var source:String="default"
	var confidence:float=DEFAULT_CONFIDENCE
	var type_id:String=_Types.FALLBACK_TYPE
	var matched_ids:Array=[]
	var base_effects:Array=[]
	var from_records:bool=false
	if not matches.is_empty() and float((matches[0] as Dictionary).score)>=MATCH_THRESHOLD:
		source="match"
		confidence=float((matches[0] as Dictionary).score)
		var top:Dictionary=(matches[0] as Dictionary).rec
		type_id=String((top.get("intent",{}) as Dictionary).get("type_id",cls.type_id))
		if not _Types.has_type(type_id): type_id=String(cls.type_id)
		var used:Array=[]
		for m:Variant in matches:
			var md:Dictionary=m as Dictionary
			if float(md.score)>=MATCH_THRESHOLD-0.05 and used.size()<3: used.append(md)
		for md:Variant in used: matched_ids.append(String(((md as Dictionary).rec as Dictionary).get("id","")))
		base_effects=_blend_record_effects(used)
		from_records=not base_effects.is_empty()
	elif float(cls.confidence)>=TYPE_THRESHOLD and String(cls.type_id)!=_Types.FALLBACK_TYPE:
		source="type"
		type_id=String(cls.type_id)
		confidence=clampf(0.25+0.5*float(cls.confidence),0.25,TYPE_CONFIDENCE_CAP)
	var tdef:Dictionary=_Types.get_type(type_id)
	if String(tdef.get("act",""))!="" and act=="order" and String(tdef.act) in ["question","greeting"]: act=String(tdef.act)
	if not from_records: base_effects=(tdef.get("effects",[]) as Array).duplicate(true)
	var discussion:bool=not (act in EFFECT_ACTS)
	var scaled:Dictionary=scale_profile(base_effects,tdef,ctx,confidence,from_records)
	var effects:Array=[] if discussion else scaled.effects
	var counted:Dictionary={} if discussion else _counted(tdef,text,ctx)
	var t_reply:int=Time.get_ticks_usec()
	var reply:Dictionary=_compose_reply(text,act,tdef,ctx,matches if source=="match" else [],scaled)
	var t_end:int=Time.get_ticks_usec()
	var result:Dictionary={
		"confidence":snappedf(confidence,0.001),"source":source,"type_id":type_id,
		"intent":{"speech_act":act,"type_id":type_id,"topic":String(tdef.get("label",type_id)),"category":String(tdef.get("category","custom")),
			"policy_ids":_live_policies(tdef.get("policies",[])),"type_confidence":float(cls.confidence),"classified_type":String(cls.type_id)},
		"discussion":discussion,"effects":effects,"side_effects":[] if discussion else scaled.side_effects,"costs":{} if discussion else scaled.costs,
		"counted":counted,"duration_days":float(scaled.duration_days),"scale":scaled.scale,
		"reply_template":String(reply.template),"reply_slots":reply.slots,"reply_text":String(reply.text),"voice_family":String(reply.family),
		"matched_ids":matched_ids,"surface":surface,"context_signature":sig,
	}
	last_timing_usec=Time.get_ticks_usec()-t0
	last_timing_breakdown={"context":t_cls-t0,"classify":t_match-t_cls,"match":t_after-t_match,"effects":t_reply-t_after,"reply":t_end-t_reply}
	result["timing_usec"]=last_timing_usec
	return result

## Shapes a resolve() result like PronouncementInterpreter's contract so the
## civic pipeline can consume an offline answer: {summary, answer, policies
## [{id, basis, confidence, statistical_effects}], unresolved, source, ...}.
## Policies come from the type's live catalog ids; when there are none the
## scaled effects travel in offline_effects for the custom-directive path.
static func to_civic_interpretation(result:Dictionary,text:String)->Dictionary:
	var intent:Dictionary=result.get("intent",{})
	var basis:String=text.strip_edges().substr(0,160)
	var stat:Array=[]
	for e:Variant in result.get("effects",[]):
		var d:Dictionary=e as Dictionary
		stat.append({"metric":String(d.metric),"delta":float(d.delta),"uncertainty":float(d.uncertainty),"reason":String(d.reason)})
	var policies:Array=[]
	if not bool(result.get("discussion",false)):
		for id:Variant in intent.get("policy_ids",[]):
			if policies.size()>=1: break
			policies.append({"id":String(id),"basis":basis,"confidence":clampf(float(result.get("confidence",0.5)),0.55,1.0),"statistical_effects":stat})
	return {"summary":"%s (%s)" % [String(intent.get("topic","")),String(intent.get("speech_act",""))],"answer":String(result.get("reply_text","")),
		"policies":policies,"unresolved":"","source":"offline interaction database","source_detail":"Resolved offline (%s, confidence %.2f)." % [String(result.get("source","")),float(result.get("confidence",0.0))],
		"non_directive":bool(result.get("discussion",false)),"offline_effects":[] if not policies.is_empty() else stat,"offline_type":String(result.get("type_id","")),
		"offline_counted":result.get("counted",{}),"offline_costs":result.get("costs",{}),"offline_side_effects":result.get("side_effects",[]),"matched_ids":result.get("matched_ids",[])}

## Session reset: forgets which lines were already spoken.
static func reset_session()->void:
	_emitted.clear()
	_used_record_templates.clear()
	_calls=0

## Drops the similarity index; the next resolve() rebuilds it.
static func invalidate_index()->void:
	_idx_revision=-1
	_idx_count=0
	_idx_norm_n=0
	_postings.clear(); _rec_terms.clear(); _rec_tri.clear(); _vocab_tri.clear(); _vocab_tri_size=-1
	_rec_norm=PackedFloat32Array()

## Builds (or incrementally extends) the index now; returns microseconds spent.
static func warm_index()->int:
	var t0:int=Time.get_ticks_usec()
	_ensure_index()
	return Time.get_ticks_usec()-t0

## Abstracts a stored reply into a re-voiceable template: numbers -> {count},
## honorifics -> {address}, mid-sentence proper names -> {notable}/{other}.
static func extract_template(reply:String)->String:
	var out:String=reply
	for term:String in ADDRESS_TERMS: out=out.replace(term,"{address}")
	var re_num:RegEx=RegEx.new(); re_num.compile("\\b\\d+\\b")
	out=re_num.sub(out,"{count}",true)
	var re_name:RegEx=RegEx.new(); re_name.compile("(?<=[a-z,;:] )([A-Z][a-z]+(?:[- ][A-Z][a-z]+)?)")
	var names:Dictionary={}
	for m:RegExMatch in re_name.search_all(out):
		var n:String=m.get_string(1)
		if n in ["I","God","Great","The"]: continue
		if not names.has(n): names[n]="{notable}" if names.is_empty() else "{other}"
	for n:Variant in names: out=out.replace(String(n),String(names[n]))
	return out

# ================================================================= index

static func _ensure_index()->void:
	var recs:Array=_Store.records()
	if _idx_revision==_Store.revision() and _idx_count==recs.size(): return
	if recs.size()<_idx_count: invalidate_index()
	for i:int in range(_idx_count,recs.size()):
		var rec:Dictionary=recs[i] as Dictionary
		var terms:Dictionary=_Text.term_counts(String(rec.get("player_text_raw",rec.get("player_text",""))))
		_rec_terms.append(terms)
		for term:Variant in terms:
			var list:Variant=_postings.get(term)
			if list==null:
				var fresh:Array=[i]
				_postings[term]=fresh
			else: (list as Array).append(i)
	var n:int=recs.size()
	# Norms depend on IDF; recompute fully when the corpus has grown by a quarter.
	if _idx_norm_n==0 or n>int(float(_idx_norm_n)*1.25) or _rec_norm.size()!=n:
		var norms:PackedFloat32Array=PackedFloat32Array()
		norms.resize(n)
		var full:bool=_idx_norm_n==0 or n>int(float(_idx_norm_n)*1.25)
		var start:int=0 if full else _rec_norm.size()
		if not full:
			for i:int in range(mini(_rec_norm.size(),n)): norms[i]=_rec_norm[i]
		for i:int in range(start,n):
			var sum:float=0.0
			var terms2:Dictionary=_rec_terms[i]
			for term:Variant in terms2:
				var w:float=(1.0+log(float(terms2[term])))*_idf(term,n)
				sum+=w*w
			norms[i]=sqrt(maxf(sum,0.000001))
		_rec_norm=norms
		if full: _idx_norm_n=n
	_idx_count=n
	_idx_revision=_Store.revision()

static func _idf(term:Variant,n:int)->float:
	var list:Variant=_postings.get(term)
	var df:int=0 if list==null else (list as Array).size()
	return log((float(n)+1.0)/(float(df)+1.0))+1.0

static func _nearest_vocab(term:String)->String:
	if _vocab_tri_size!=_postings.size():
		_vocab_tri.clear()
		for v:Variant in _postings:
			var vs:String=String(v)
			if "_" in vs or vs.length()<4: continue
			var tri:Dictionary=_Text.trigrams(vs)
			for g:Variant in tri:
				if not _vocab_tri.has(g): _vocab_tri[g]=[]
				(_vocab_tri[g] as Array).append(vs)
		_vocab_tri_size=_postings.size()
	var qt:Dictionary=_Text.trigrams(term)
	var votes:Dictionary={}
	for g:Variant in qt:
		var hits:Variant=_vocab_tri.get(g)
		if hits==null or (hits as Array).size()>400: continue
		for v:Variant in hits: votes[v]=int(votes.get(v,0))+1
	var best:String=""
	var best_j:float=0.0
	for v:Variant in votes:
		if int(votes[v])*2<qt.size(): continue
		var j:float=_Text.jaccard(qt,_Text.trigrams(String(v)))
		if j>best_j: best_j=j; best=String(v)
	return best if best_j>=0.5 else ""

static func _best_matches(text:String,surface:String,cls:Dictionary,sig:Dictionary)->Array:
	_ensure_index()
	var n:int=_rec_terms.size()
	if n==0: return []
	var q:Dictionary=_Text.term_counts(text)
	if q.is_empty(): return []
	# Weighted query terms; unknown words map to their nearest indexed word.
	var qterms:Array=[]
	var qnorm2:float=0.0
	for term:Variant in q:
		var key:String=String(term)
		var scale:float=1.0
		if not _postings.has(key):
			if "_" in key: continue
			var near:String=_nearest_vocab(key)
			if near.is_empty(): continue
			key=near; scale=0.7
		var idf:float=_idf(key,n)
		var w:float=(1.0+log(float(q[term])))*idf*scale
		qnorm2+=w*w
		qterms.append([key,w,(_postings[key] as Array).size()])
	if qterms.is_empty(): return []
	qterms.sort_custom(func(a:Array,b:Array)->bool: return int(a[2])<int(b[2]))
	var acc:Dictionary={}
	var visited:int=0
	for qt:Variant in qterms:
		var a:Array=qt as Array
		var plist:Array=_postings[a[0]] as Array
		if visited>0 and visited+plist.size()>POSTING_BUDGET: continue
		visited+=plist.size()
		var key2:String=String(a[0])
		var qw:float=float(a[1])
		var idf2:float=_idf(key2,n)
		var contrib:float=qw*idf2   # record tf is almost always 1; exact tf only matters in re-ranking
		for idx:Variant in plist:
			acc[idx]=float(acc.get(idx,0.0))+contrib
	var qnorm:float=sqrt(maxf(qnorm2,0.000001))
	# Keep the best CANDIDATES by cosine without sorting the whole accumulator.
	var top:Array=[]
	var floor_score:float=-1.0
	for idx:Variant in acc:
		var cosv:float=float(acc[idx])/(qnorm*_rec_norm[int(idx)])
		if top.size()<CANDIDATES:
			top.append([int(idx),cosv])
			if top.size()==CANDIDATES: floor_score=_min_score(top)
		elif cosv>floor_score:
			var mi:int=0
			for k:int in range(1,top.size()):
				if float(top[k][1])<float(top[mi][1]): mi=k
			top[mi]=[int(idx),cosv]
			floor_score=_min_score(top)
	# Re-rank candidates with fuzzy text, intent and context agreement.
	var qtri:Dictionary=_Text.trigrams(text)
	var recs:Array=_Store.records()
	var ranked:Array=[]
	for cand:Variant in top:
		var c:Array=cand as Array
		var idx3:int=int(c[0])
		var rec:Dictionary=recs[idx3] as Dictionary
		var tri:Variant=_rec_tri.get(idx3)
		if tri==null:
			tri=_Text.trigrams(String(rec.get("player_text_raw","")))
			if _rec_tri.size()<20000: _rec_tri[idx3]=tri
		var intent:Dictionary=rec.get("intent",{})
		var type_agree:float=1.0 if String(intent.get("type_id",""))==String(cls.type_id) else 0.0
		var act_agree:float=1.0 if String(intent.get("speech_act",""))==String(cls.speech_act) else 0.0
		var prox:float=_Context.proximity(sig,rec.get("context",{}))
		var score:float=0.5*clampf(float(c[1]),0.0,1.0)+0.25*_Text.jaccard(qtri,tri as Dictionary)+0.12*type_agree+0.05*act_agree+0.08*prox
		if String(rec.get("surface",""))!=surface: score*=0.93
		if not bool(rec.get("accepted",true)): score*=0.8
		ranked.append({"idx":idx3,"score":score,"rec":rec})
	ranked.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return float(x.score)>float(y.score))
	return ranked.slice(0,5)

static func _min_score(top:Array)->float:
	var m:float=INF
	for e:Variant in top: m=minf(m,float((e as Array)[1]))
	return m

# ================================================================= effects

static func _pop_factor(population:float,sensitivity:float)->float:
	var d:float=log(REF_POPULATION)/log(10.0)-log(maxf(population,10.0))/log(10.0)
	return clampf(1.0+sensitivity*d*0.25,0.55,1.35)

static func _era_factor(tdef:Dictionary,tier:int)->float:
	var es:Variant=tdef.get("era_scale")
	if es is Array and (es as Array).size()>tier: return clampf(float((es as Array)[tier]),0.2,2.0)
	return 1.0

## Converts a profile (canonical or recorded) into bounded effects for ctx.
## Public so call sites can scale RD's own estimates the same way.
static func scale_profile(base_effects:Array,tdef:Dictionary,ctx_in:Dictionary,confidence:float=0.6,from_records:bool=false)->Dictionary:
	var ctx:Dictionary=_Context.complete(ctx_in)
	var allowed:Array[String]=_Context.writable_metrics()
	var population:float=float(ctx.population)
	var tier:int=int(ctx.era_tier)
	var sens:float=float(tdef.get("pop_sens",0.3))
	var pf:float=_pop_factor(population,sens)
	var ef:float=_era_factor(tdef,tier)
	var feas:float=float(ctx.feasibility)
	var comp:float=float(ctx.compliance)
	var metrics:Dictionary=ctx.get("metrics",{})
	var dur_factor:float=clampf(1.0+float(tdef.get("dur_pop_sens",0.0))*(log(maxf(population,10.0))-log(REF_POPULATION))/log(10.0)*0.5,0.5,3.0)
	var effects:Array=[]
	var dropped:Array=[]
	var longest:float=0.0
	for e:Variant in base_effects:
		var d:Dictionary=e as Dictionary
		var metric:String=String(d.get("metric",""))
		if not (metric in allowed):
			dropped.append(metric); continue
		var delta:float=float(d.get("delta",0.0))
		if not from_records: delta*=pf*ef
		if delta>0.0: delta*=feas*lerpf(0.6,1.1,comp)
		elif metric in ["cohesion","legitimacy"]: delta*=lerpf(1.4,0.8,comp)
		var cur:float=float(metrics.get(metric,0.5))
		delta*=clampf(((1.0-cur) if delta>0.0 else cur)/0.5,0.25,1.2)
		delta=clampf(delta,-MAX_EFFECT,MAX_EFFECT)
		var unc:float=float(d.get("uncertainty",0.01))*(1.0+(1.0-feas)*0.5)+(1.0-clampf(confidence,0.0,1.0))*0.015
		unc=clampf(unc,0.0,MAX_EFFECT)
		var days:float=float(d.get("duration_days",30.0))*(1.0 if from_records else dur_factor)
		longest=maxf(longest,days)
		var reason:String=String(d.get("reason","")).strip_edges()
		if reason.is_empty(): reason="estimated consequence of this kind of order"
		effects.append({"metric":metric,"delta":snappedf(delta,0.0001),"uncertainty":snappedf(unc,0.0001),"duration_days":roundf(days),"reason":reason})
	var side:Array=[]
	for s:Variant in tdef.get("side",[]):
		var sd:Dictionary=(s as Dictionary).duplicate()
		sd["odds"]=snappedf(clampf(float(sd.get("odds",0.0))*lerpf(1.4,0.7,comp),0.0,0.95),0.001)
		side.append(sd)
	var costs:Dictionary=_costs(tdef.get("costs",{}),ctx,dur_factor)
	return {"effects":effects,"side_effects":side,"costs":costs,"duration_days":longest,"dropped_metrics":dropped,
		"scale":{"population_factor":snappedf(pf,0.001),"era_factor":ef,"feasibility":feas,"compliance":comp,"duration_factor":snappedf(dur_factor,0.001)}}

static func _costs(raw:Variant,ctx:Dictionary,dur_factor:float)->Dictionary:
	if not (raw is Dictionary): return {}
	var c:Dictionary=raw as Dictionary
	var population:float=float(ctx.population)
	var working:float=float(ctx.get("working_age",population*0.55))
	var out:Dictionary={}
	var share:float=float(c.get("labor_share",0.0))
	if share>0.0:
		out["workers"]=maxi(1,int(round(share*working)))
		out["labor_days"]=roundf(float(c.get("labor_days",7.0))*dur_factor)
	var food:float=float(c.get("food_per_capita_days",0.0))
	if food!=0.0: out["food_person_days"]=roundf(food*population)
	var mats:Variant=c.get("materials",{})
	if mats is Dictionary and not (mats as Dictionary).is_empty():
		var scaled:Dictionary={}
		var mf:float=pow(population/REF_POPULATION,0.7)
		for k:Variant in mats: scaled[k]=maxi(1,int(round(float((mats as Dictionary)[k])*mf)))
		out["materials"]=scaled
	return out

static func _blend_record_effects(used:Array)->Array:
	# Records carry effects proposed for their own context. Weighted average per
	# metric, un-scaled from the record's population band to the reference band;
	# scale_profile then applies the current context.
	var sums:Dictionary={}
	for m:Variant in used:
		var md:Dictionary=m as Dictionary
		var rec:Dictionary=md.rec
		var w:float=float(md.score)
		var sig:Dictionary=rec.get("context",{})
		var rec_pop:float=float(BAND_POPULATION.get(String(sig.get("pop_band","hamlet")),REF_POPULATION))
		var unscale:float=1.0/_pop_factor(rec_pop,0.3)
		var out:Dictionary=rec.get("output",{})
		for e:Variant in out.get("effects",[]):
			var d:Dictionary=e as Dictionary
			var metric:String=String(d.get("metric",""))
			if not sums.has(metric): sums[metric]={"w":0.0,"delta":0.0,"unc":0.0,"days":0.0,"reason":String(d.get("reason",""))}
			var s:Dictionary=sums[metric]
			s.w=float(s.w)+w
			s.delta=float(s.delta)+w*float(d.get("delta",0.0))*unscale
			s.unc=float(s.unc)+w*float(d.get("uncertainty",0.01))
			s.days=float(s.days)+w*float(d.get("duration_days",30.0))
	var result:Array=[]
	for metric:Variant in sums:
		var s2:Dictionary=sums[metric]
		var tw:float=maxf(float(s2.w),0.0001)
		result.append({"metric":String(metric),"delta":float(s2.delta)/tw,"uncertainty":float(s2.unc)/tw,"duration_days":float(s2.days)/tw,"reason":String(s2.reason)})
	# Records were scaled for their own population; re-apply only the current one.
	return result

static func _counted(tdef:Dictionary,text:String,ctx:Dictionary)->Dictionary:
	var c:Variant=tdef.get("counted")
	if not (c is Dictionary): return {}
	var cd:Dictionary=c as Dictionary
	var population:int=int(ctx.population)
	var n:int=_Text.first_count(text)
	if n<=0:
		if cd.has("share"): n=maxi(1,int(round(float(cd.share)*float(population))))
		else: n=int(cd.get("default",1))
	return {"kind":String(cd.get("kind","population_deaths")),"count":clampi(n,0,maxi(0,population-1))}

static func _live_policies(raw:Variant)->Array:
	var out:Array=[]
	if not (raw is Array): return out
	if not _policy_catalog_loaded:
		_policy_catalog_loaded=true
		if ResourceLoader.exists("res://scripts/government_policy_catalog.gd"):
			var script:Script=load("res://scripts/government_policy_catalog.gd") as Script
			if script!=null:
				var p:Variant=script.get_script_constant_map().get("POLICIES",{})
				if p is Dictionary: _policy_catalog=p as Dictionary
	var catalog:Dictionary=_policy_catalog
	for id:Variant in raw:
		if catalog.is_empty() or catalog.has(String(id)): out.append(String(id))
	return out

# ================================================================= replies

static func _has(tags:Array,tag:String)->bool:
	return tags.has(tag)

static func _span_words(days:float)->String:
	if days<10.0: return "a few days"
	if days<40.0: return "a moon"
	if days<100.0: return "a season"
	if days<250.0: return "half a year"
	if days<500.0: return "a full year"
	return "years"

static func _count_value(type_id:String,ctx:Dictionary,text:String)->String:
	if ctx.has("count"): return str(ctx["count"])
	var n:int=_Text.first_count(text)
	if n>0: return str(n)
	var population:float=float(ctx.population)
	var working:float=float(ctx.get("working_age",population*0.55))
	var hint:String=String(COUNT_HINTS.get(type_id,"pop:0.02"))
	if hint=="population": return str(int(population))
	if hint=="food_days": return str(int(round(float(ctx.get("food_days",30.0)))))
	if hint=="feast_days": return "three"
	if hint.begins_with("pop:"): return str(maxi(2,int(round(population*float(hint.substr(4))))))
	if hint.begins_with("work:"): return str(maxi(2,int(round(working*float(hint.substr(5))))))
	return "a few"

## Slot values for the current era, population and caller-supplied names.
static func slot_values(tdef:Dictionary,ctx:Dictionary,text:String,span_days:float,seed_value:int)->Dictionary:
	var tags:Array=ctx.get("era_tags",[])
	var band:String=_Context.pop_band(int(ctx.population))
	var people:String={"band":"the band","hamlet":"the camp","village":"the village","town":"the town","city":"the city"}.get(band,"the people")
	var trades:Array[String]=["flint-knapper","tracker","fire-keeper"]
	if _has(tags,"pottery"): trades.append("potter")
	if _has(tags,"metal"): trades.append("smith")
	if _has(tags,"weaving"): trades.append("weaver")
	var slots:Dictionary={
		"address":String(ctx.get("address","Great One")),
		"people":people,
		"staple":"grain" if _has(tags,"farming") else "meat and roots",
		"store":"granaries" if _has(tags,"farming") else ("clay jars" if _has(tags,"pottery") else "storage pits"),
		"structure":"brick houses" if _has(tags,"masonry") else ("timber houses" if int(ctx.era_tier)>=1 else "hide shelters"),
		"record":"the written rolls" if _has(tags,"writing") else "knotted cords",
		"tool":"bronze tools" if _has(tags,"metal") else "stone blades",
		"fields":"the fields" if _has(tags,"farming") else "the gathering grounds",
		"shrine":"A temple" if _has(tags,"institutions") else "A ring of standing stones",
		"notable":String(ctx.get("notable",DEFAULT_NOTABLES[absi(seed_value)%DEFAULT_NOTABLES.size()])),
		"trade":String(ctx.get("trade",trades[absi(seed_value>>3)%trades.size()])),
		"trait":String(ctx.get("trait",DEFAULT_TRAITS[absi(seed_value>>5)%DEFAULT_TRAITS.size()])),
		"other":"another of ours",
		"neighbours":String(ctx.get("neighbours","Our neighbours")),
		"count":_count_value(String(tdef.get("id","")),ctx,text),
		"span":_span_words(span_days),
	}
	slots["notable_is_placeholder"]=not ctx.has("notable")
	return slots

static func fill(template:String,slots:Dictionary)->String:
	var out:String=template
	for k:Variant in slots:
		var v:Variant=slots[k]
		if v is bool: continue
		out=out.replace("{"+String(k)+"}",String(v))
	return _sentence_case(out)

static func _sentence_case(s:String)->String:
	if s.is_empty(): return s
	var out:String=s.substr(0,1).to_upper()+s.substr(1)
	for mark:String in [". ","! ","? "]:
		var from:int=0
		while true:
			var i:int=out.find(mark,from)
			if i<0 or i+2>=out.length(): break
			out=out.substr(0,i+2)+out.substr(i+2,1).to_upper()+out.substr(i+3)
			from=i+2
	return out

static func _era_safe(text:String,tags:Array)->String:
	if _Voice.permits(text,tags): return text
	var out:String=text
	for w:Variant in ERA_SUBS:
		var re:RegEx=RegEx.new()
		re.compile("(?i)\\b"+String(w)+"\\b")
		out=re.sub(out,String(ERA_SUBS[w]),true)
	return out if _Voice.permits(out,tags) else ""

static func _key(text:String)->String:
	return _Text.normalize(text)

static func _compose_reply(text:String,act:String,tdef:Dictionary,ctx:Dictionary,matches:Array,scaled:Dictionary)->Dictionary:
	var family:String=String(ctx.get("voice_family",""))
	if family.is_empty(): family=_Types.family_for_model(String(ctx.get("speaker_model","")))
	var frames:Dictionary=_Types.frames(family)
	var tags:Array=ctx.get("era_tags",[])
	var seed_value:int=absi(text.hash())+_calls*7919
	var slots:Dictionary=slot_values(tdef,ctx,text,float(scaled.get("duration_days",30.0)),seed_value)
	var candidates:Array[String]=[]
	var from_record:Dictionary={}
	# 1. Stored replies from the same voice family, abstracted into templates.
	for m:Variant in matches:
		var rec:Dictionary=(m as Dictionary).rec
		if float((m as Dictionary).score)<MATCH_THRESHOLD-0.05: continue
		var spk:Dictionary=rec.get("speaker",{})
		var rec_family:String=String(spk.get("family",""))
		if not rec_family.is_empty() and rec_family!=family: continue
		var out:Dictionary=rec.get("output",{})
		var tpl:String=String(out.get("reply_template",""))
		if tpl.is_empty(): tpl=extract_template(String(out.get("reply","")))
		if preload("res://scripts/plain_speech.gd").is_maxim(tpl): continue   # stored before the plain-speech gate
		# A stored line (even re-slotted) is spoken at most once per session.
		if not tpl.strip_edges().is_empty() and not _used_record_templates.has(tpl):
			candidates.append(tpl); from_record[tpl]=true
	# 2. Type archetypes framed in the speaker's voice family.
	var stance:String=String(tdef.get("stance","comply"))
	var lines:Array=tdef.get("core",[])
	if act=="question":
		stance="answer"
		if not (tdef.get("ask",[]) as Array).is_empty(): lines=tdef.get("ask",[])
	var opens:Array=frames.get("open",[])
	var closes:Array=frames.get(stance,frames.get("comply",[]))
	var shapes:Array=[]
	var rot:int=seed_value
	for li:int in lines.size():
		var core:String=String(lines[(li+rot)%lines.size()])
		for k:int in range(maxi(opens.size(),closes.size())):
			var o:String=String(opens[(k+rot)%opens.size()]) if not opens.is_empty() else ""
			var c:String=String(closes[(k+rot)%closes.size()]) if not closes.is_empty() else ""
			shapes.append((o+" "+core).strip_edges())
			shapes.append((core+" "+c).strip_edges())
			shapes.append((o+" "+core+" "+c).strip_edges())
		shapes.append(core)
	for s:Variant in shapes: candidates.append(String(s))
	var generic:Dictionary=_Types.get_type(_Types.FALLBACK_TYPE)
	for g:Variant in generic.get("core",[]): candidates.append(String(g))
	var chosen_tpl:String=""
	var chosen:String=""
	for tpl2:String in candidates:
		var rendered:String=_era_safe(fill(tpl2,slots),tags)
		if rendered.is_empty(): continue
		if _emitted.has(_key(rendered)): continue
		chosen_tpl=tpl2; chosen=rendered
		break
	if chosen.is_empty():
		# Every phrasing has been heard this session: vary deterministically.
		var base_tpl:String=candidates[0] if not candidates.is_empty() else "{address}."
		var lead:Array[String]=["Again, then.","As before,","Once more,","So be it, again."]
		var n:int=0
		while chosen.is_empty() or _emitted.has(_key(chosen)):
			if n<lead.size():
				chosen_tpl=lead[n]+" "+base_tpl
				chosen=_era_safe(fill(chosen_tpl,slots),tags)
			else:
				chosen_tpl="As you command, {address}; this is the %s time of asking." % str(n-lead.size()+2)
				chosen=fill(chosen_tpl,slots)
			n+=1
	_emitted[_key(chosen)]=true
	if from_record.has(chosen_tpl): _used_record_templates[chosen_tpl]=true
	var public_slots:Dictionary=slots.duplicate()
	return {"template":chosen_tpl,"text":chosen,"slots":public_slots,"family":family}
