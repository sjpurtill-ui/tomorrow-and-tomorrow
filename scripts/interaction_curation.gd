class_name InteractionCuration
extends RefCounted
## Report-only curation: clusters recorded interactions the catalogue does not
## explain well and proposes new types, and compares recorded model effects
## with each type's canonical profile to propose profile updates. Nothing here
## edits res://data; a human reviews the report and edits types.json.

const _Text:=preload("res://scripts/interaction_text.gd")
const _Types:=preload("res://scripts/interaction_types.gd")
const _Store:=preload("res://scripts/interaction_store.gd")

const LOW_CONFIDENCE:=0.3
const CLUSTER_SIMILARITY:=0.34
const MIN_CLUSTER:=3
const PROFILE_MIN_SAMPLES:=5
const PROFILE_DRIFT:=0.008

static func propose(records:Array=[],min_cluster:int=MIN_CLUSTER)->Dictionary:
	var recs:Array=records if not records.is_empty() else _Store.records()
	var unexplained:Array=[]
	var per_type:Dictionary={}
	for r:Variant in recs:
		var rec:Dictionary=r as Dictionary
		var text:String=String(rec.get("player_text_raw",""))
		var cls:Dictionary=_Types.classify(text)
		if String(cls.type_id)==_Types.FALLBACK_TYPE or float(cls.confidence)<LOW_CONFIDENCE: unexplained.append(rec)
		else:
			var t:String=String(cls.type_id)
			if not per_type.has(t): per_type[t]=[]
			(per_type[t] as Array).append(rec)
	return {"records":recs.size(),"unexplained":unexplained.size(),"new_types":_cluster(unexplained,min_cluster),"profile_updates":_profile_drift(per_type)}

static func _vector(text:String,idf:Dictionary)->Dictionary:
	var tc:Dictionary=_Text.term_counts(text,false)
	var v:Dictionary={}
	var norm:float=0.0
	for t:Variant in tc:
		var w:float=float(tc[t])*float(idf.get(t,1.0))
		v[t]=w; norm+=w*w
	norm=sqrt(maxf(norm,0.000001))
	for t2:Variant in v: v[t2]=float(v[t2])/norm
	return v

static func _cos(a:Dictionary,b:Dictionary)->float:
	var s:float=0.0
	for k:Variant in a:
		if b.has(k): s+=float(a[k])*float(b[k])
	return s

static func _cluster(recs:Array,min_cluster:int)->Array:
	if recs.is_empty(): return []
	var df:Dictionary={}
	for r:Variant in recs:
		for t:Variant in _Text.term_counts(String((r as Dictionary).get("player_text_raw","")),false): df[t]=int(df.get(t,0))+1
	var idf:Dictionary={}
	for t2:Variant in df: idf[t2]=log(float(recs.size()+1)/float(int(df[t2])+1))+1.0
	# Leader clustering: each record joins the most similar centroid above the threshold.
	var clusters:Array=[]
	for r2:Variant in recs:
		var rec:Dictionary=r2 as Dictionary
		var v:Dictionary=_vector(String(rec.get("player_text_raw","")),idf)
		var best:int=-1
		var best_s:float=CLUSTER_SIMILARITY
		for i:int in clusters.size():
			var s:float=_cos(v,(clusters[i] as Dictionary).centroid)
			if s>best_s: best_s=s; best=i
		if best<0: clusters.append({"centroid":v.duplicate(),"members":[rec]})
		else:
			var c:Dictionary=clusters[best]
			(c.members as Array).append(rec)
			var n:float=float((c.members as Array).size())
			var cen:Dictionary=c.centroid
			for k:Variant in v: cen[k]=float(cen.get(k,0.0))*(n-1.0)/n+float(v[k])/n
	var out:Array=[]
	for c2:Variant in clusters:
		var cd:Dictionary=c2 as Dictionary
		var members:Array=cd.members
		if members.size()<min_cluster: continue
		var terms:Array=[]
		for k2:Variant in cd.centroid: terms.append([String(k2),float((cd.centroid as Dictionary)[k2])])
		terms.sort_custom(func(a:Array,b:Array)->bool: return float(a[1])>float(b[1]))
		var top_terms:Array=[]
		for tt:Variant in terms.slice(0,8):
			if not ("_" in String((tt as Array)[0])): top_terms.append(String((tt as Array)[0]))
		var examples:Array=[]
		for m:Variant in members.slice(0,4): examples.append(String((m as Dictionary).get("player_text_raw","")))
		var acts:Dictionary={}
		for m2:Variant in members:
			var a:String=String(((m2 as Dictionary).get("intent",{}) as Dictionary).get("speech_act",""))
			acts[a]=int(acts.get(a,0))+1
		var suggested:String="_".join(PackedStringArray(top_terms.slice(0,2)))
		out.append({"suggested_id":suggested,"size":members.size(),"terms":top_terms,"examples":examples,"speech_acts":acts,
			"mean_effects":_mean_effects(members),"ids":members.slice(0,20).map(func(x:Variant)->String: return String((x as Dictionary).get("id","")))})
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.size)>int(b.size))
	return out

static func _mean_effects(members:Array)->Dictionary:
	var sums:Dictionary={}
	for m:Variant in members:
		for e:Variant in ((m as Dictionary).get("output",{}) as Dictionary).get("effects",[]):
			var d:Dictionary=e as Dictionary
			var metric:String=String(d.get("metric",""))
			if not sums.has(metric): sums[metric]=[0.0,0]
			var s:Array=sums[metric]
			s[0]=float(s[0])+float(d.get("delta",0.0)); s[1]=int(s[1])+1
	var out:Dictionary={}
	for k:Variant in sums:
		var s2:Array=sums[k]
		out[k]={"mean_delta":snappedf(float(s2[0])/float(maxi(1,int(s2[1]))),0.0001),"samples":int(s2[1])}
	return out

static func _profile_drift(per_type:Dictionary)->Array:
	var out:Array=[]
	for t:Variant in per_type:
		var members:Array=per_type[t]
		if members.size()<PROFILE_MIN_SAMPLES: continue
		var recorded:Dictionary=_mean_effects(members)
		var canon:Dictionary={}
		for e:Variant in _Types.get_type(String(t)).get("effects",[]): canon[String((e as Dictionary).metric)]=float((e as Dictionary).delta)
		var changes:Array=[]
		for metric:Variant in recorded:
			var r:Dictionary=recorded[metric]
			if int(r.samples)<PROFILE_MIN_SAMPLES: continue
			var c:float=float(canon.get(metric,0.0))
			if absf(float(r.mean_delta)-c)>=PROFILE_DRIFT:
				changes.append({"metric":String(metric),"canonical":c,"recorded_mean":float(r.mean_delta),"samples":int(r.samples)})
		if not changes.is_empty(): out.append({"type_id":String(t),"records":members.size(),"changes":changes})
	return out

static func to_markdown(report:Dictionary)->String:
	var lines:PackedStringArray=PackedStringArray()
	lines.append("# Interaction curation report")
	lines.append("")
	lines.append("Records scanned: %d. Poorly explained by the catalogue: %d." % [int(report.get("records",0)),int(report.get("unexplained",0))])
	lines.append("")
	lines.append("## Proposed new types")
	for c:Variant in report.get("new_types",[]):
		var cd:Dictionary=c as Dictionary
		lines.append("- **%s** (%d records) terms: %s" % [String(cd.suggested_id),int(cd.size),", ".join(PackedStringArray(cd.terms))])
		for ex:Variant in cd.examples: lines.append("  - \"%s\"" % String(ex))
		lines.append("  - mean recorded effects: %s" % JSON.stringify(cd.mean_effects))
	lines.append("")
	lines.append("## Proposed profile updates")
	for u:Variant in report.get("profile_updates",[]):
		var ud:Dictionary=u as Dictionary
		for ch:Variant in ud.changes:
			var cd2:Dictionary=ch as Dictionary
			lines.append("- %s.%s: canonical %+.4f, recorded mean %+.4f over %d" % [String(ud.type_id),String(cd2.metric),float(cd2.canonical),float(cd2.recorded_mean),int(cd2.samples)])
	return "\n".join(lines)+"\n"
