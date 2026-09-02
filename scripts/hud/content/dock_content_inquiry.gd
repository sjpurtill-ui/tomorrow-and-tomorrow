extends "res://scripts/hud/content/dock_content_base.gd"
## INQUIRY section: Direct Attention / Investigations / Established.
## Replaces the knowledge panel and the progression panel's research views.

const DOMAIN_COLORS:Dictionary={
	"demography":Color("#9b7252"),"nutrition":Color("#79a8a0"),"health":Color("#8fa26a"),
	"labor":Color("#a9946e"),"knowledge":Color("#8798b5"),"production":Color("#c9a95a"),
	"infrastructure":Color("#b39a68"),"logistics":Color("#d0b46f"),"ecology":Color("#5e9d70"),
	"institutions":Color("#a897c9"),"security":Color("#c67462"),"culture":Color("#766d72"),
}

func meta()->Dictionary:
	return {
		"eyebrow":"INQUIRY · THE COLLECTIVE MIND",
		"title":"Knowledge & Inquiry",
		"subtabs":["DIRECT ATTENTION","INVESTIGATIONS","ESTABLISHED"],
	}

func tab(sub:int)->Dictionary:
	var summary:Dictionary=DiscoverySystem.research_program_summary()
	var observers:=int(summary.get("researchers",0))
	var committed:=int(summary.get("emphasis_total",0))
	var lines:=int(summary.get("active_lines",0))
	var established:=GameState.discovery_log.size()
	var idle:=maxi(0,observers-committed)
	var kpis:Array=[
		{"label":"OBSERVERS","value":str(observers),"delta":"%d idle" % idle if idle>0 else "","delta_color":Tokens.AMBER,"accent":Tokens.TEAL,"tip":"Aggregate research workforce"},
		{"label":"COMMITTED","value":str(committed),"delta":"%d lines" % lines,"delta_color":Tokens.MUTED,"accent":Tokens.AMBER,"tip":"Observers assigned to questions"},
		{"label":"ACTIVE","value":str(lines),"delta":"projects","delta_color":Tokens.MUTED,"accent":Tokens.BLUE,"tip":"Viable investigations under way"},
		{"label":"ESTABLISHED","value":str(established),"delta":"","accent":Tokens.GREEN,"tip":"Knowledge that survived testing and memory"},
	]
	var brief:Dictionary
	if idle>0:
		brief={"tone":"warn","title":"%d observer%s uncommitted" % [idle," is" if idle==1 else "s are"],"why":"Broad emphasis below steers attention; evidence and chance decide what completes first."}
	elif lines==0:
		brief={"tone":"warn","title":"No investigation is under way","why":"Assign Researchers in SETTLEMENT and raise a domain's emphasis below.","action_label":"OPEN LABOR","on_action":jump("settlement",0)}
	else:
		brief={"tone":"info","title":"Inquiry is under way","why":"Evidence, place, prior findings, and chance decide what completes first."}
	match sub:
		1: return {"kpis":kpis,"brief":brief,"blocks":_investigation_blocks()}
		2: return {"kpis":kpis,"brief":brief,"blocks":_established_blocks()}
	return {"kpis":kpis,"brief":brief,"blocks":_attention_blocks()}

func _attention_blocks()->Array:
	var items:Array=[]
	var allocations:Dictionary=GameState.research_allocations
	var domains:Array=allocations.keys()
	domains.sort_custom(func(a,b)->bool: return int(allocations[b])<int(allocations[a]))
	for domain in domains:
		var id:=String(domain)
		items.append({
			"name":id.capitalize(),"count":int(allocations[id]),"pct":"",
			"color":DOMAIN_COLORS.get(id,Tokens.MUTED),
			"tip":"Broad question; viable projects auto-select from evidence",
			"on_minus":terrain._change_research_domain_allocation.bind(id,-1),
			"on_plus":terrain._change_research_domain_allocation.bind(id,1),
		})
	return [
		{"type":"alloc","heading":"ATTENTION BY DOMAIN","note":"emphasis · +/− reallocates","items":items},
		{"type":"text","text":"You steer attention, not answers. Evidence, place, prior findings, and chance decide what completes first."},
	]

func _investigation_blocks()->Array:
	var records:Array=DiscoverySystem.active_investigation_records()
	var items:Array=[]
	var unlock_lines:Array[String]=[]
	for record_variant in records:
		var record:Dictionary=record_variant
		var progress:=roundi(clampf(float(record.get("progress",0.0)),0.0,1.0)*100.0)
		var domain:=String(record.get("dynamic",""))
		items.append({
			"name":String(record.get("name","Investigation")),
			"sub":"%s · %s" % [domain.capitalize(),String(record.get("bottleneck","accumulating evidence"))],
			"value":"%d%%" % progress,"value_color":DOMAIN_COLORS.get(domain,Tokens.TEAL),
			"accent":DOMAIN_COLORS.get(domain,Tokens.TEAL),
			"tip":"%s\n%s" % [String(record.get("project_goal","")),String(record.get("project_method",""))],
		})
		if unlock_lines.size()<3:
			unlock_lines.append("%s → %s" % [String(record.get("discovery_name",record.get("name",""))),String(record.get("unlock_summary",""))])
	if items.is_empty():
		return [{"type":"text","heading":"CURRENT INVESTIGATIONS","text":"No viable investigation is running. Attention without supporting evidence waits; explore, work, and observe to create clues."}]
	var blocks:Array=[{"type":"rows","heading":"CURRENT INVESTIGATIONS","note":"evidence","items":items}]
	if not unlock_lines.is_empty():
		blocks.append({"type":"text","heading":"WHAT COMPLETION UNLOCKS","text":"  ".join(unlock_lines)})
	return blocks

func _established_blocks()->Array:
	var log:Array=GameState.discovery_log
	if log.is_empty():
		return [{"type":"text","heading":"ESTABLISHED KNOWLEDGE","text":"No discovery has yet survived testing, use, and collective memory."}]
	var items:Array=[]
	for index in range(log.size()-1,maxi(-1,log.size()-9),-1):
		var event:Dictionary=log[index]
		var domain:=String(event.get("dynamic",""))
		items.append({
			"name":String(event.get("name","Discovery")),
			"sub":"%s · day %d" % [domain.capitalize(),int(event.get("day",0))],
			"value":"","accent":DOMAIN_COLORS.get(domain,Tokens.GREEN),
			"tip":String(event.get("causal_mechanism",event.get("observation",""))),
		})
	return [{"type":"rows","heading":"ESTABLISHED KNOWLEDGE","note":"%d total" % log.size(),"items":items}]

func signature()->Array:
	return [GameState.research_allocations.duplicate(),GameState.active_investigations.duplicate(),GameState.discovery_log.size(),int(GameState.population_allocations.get("Knowledge",0))]
