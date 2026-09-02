extends "res://scripts/hud/content/dock_content_base.gd"
## INQUIRY section: Direct Attention / Investigations / Established.
## Replaces the knowledge panel and the progression panel's research views.

const DOMAIN_COLORS:Dictionary={
	"demography":Color("#9b7252"),"nutrition":Color("#79a8a0"),"health":Color("#8fa26a"),
	"labor":Color("#a9946e"),"knowledge":Color("#8798b5"),"production":Color("#c9a95a"),
	"infrastructure":Color("#b39a68"),"logistics":Color("#d0b46f"),"ecology":Color("#5e9d70"),
	"institutions":Color("#a897c9"),"security":Color("#c67462"),"culture":Color("#766d72"),
}

const ResourceIcons:=preload("res://scripts/resource_icons.gd")

# Discovery ids and domain ids the player has clicked open; everything else
# stays collapsed so the established record scales to hundreds of findings.
var expanded_discoveries:Dictionary={}
var expanded_domains:Dictionary={}

func meta()->Dictionary:
	return {
		"eyebrow":"INQUIRY · THE COLLECTIVE MIND",
		"title":"Knowledge & Inquiry",
		"subtabs":["DIRECT ATTENTION","INVESTIGATIONS","ESTABLISHED"],
	}

func tab(sub:int)->Dictionary:
	var summary:Dictionary=DiscoverySystem.research_program_summary()
	var observers:=int(summary.get("researchers",0))
	var emphasis_total:=int(summary.get("emphasis_total",0))
	var lines:=int(summary.get("active_lines",0))
	var established:=GameState.discovery_log.size()
	var kpis:Array=[
		{"label":"OBSERVERS","value":str(observers),"delta":"auto-assigned","delta_color":Tokens.MUTED,"accent":Tokens.TEAL,"tip":"Aggregate research workforce; the weights below divide all of it automatically — nobody sits idle"},
		{"label":"EMPHASIS","value":str(emphasis_total),"delta":"total weight","delta_color":Tokens.MUTED,"accent":Tokens.AMBER,"tip":"Sum of domain weights; each domain receives its share of the observers"},
		{"label":"ACTIVE","value":str(lines),"delta":"projects","delta_color":Tokens.MUTED,"accent":Tokens.BLUE,"tip":"Viable investigations under way"},
		{"label":"ESTABLISHED","value":str(established),"delta":"","accent":Tokens.GREEN,"tip":"Knowledge that survived testing and memory"},
	]
	var brief:Dictionary
	if observers==0:
		brief={"tone":"warn","title":"No observers are assigned","why":"Assign Researchers in SETTLEMENT; the weights below split them automatically.","action_label":"OPEN LABOR","on_action":jump("settlement",0)}
	elif lines==0:
		brief={"tone":"warn","title":"No investigation is under way","why":"Raise a domain's weight below; observers follow the shares automatically."}
	else:
		brief={"tone":"info","title":"Inquiry is under way","why":"Evidence, place, prior findings, and chance decide what completes first."}
	match sub:
		1: return {"kpis":kpis,"brief":brief,"blocks":_investigation_blocks()}
		2: return {"kpis":kpis,"brief":brief,"blocks":_established_blocks()}
	return {"kpis":kpis,"brief":brief,"blocks":_attention_blocks()}

func _attention_blocks()->Array:
	var items:Array=[]
	var allocations:Dictionary=GameState.research_allocations
	var observers:=maxi(0,int(GameState.population_allocations.get("Knowledge",0)))
	var total_weight:=0
	for value in allocations.values(): total_weight+=maxi(0,int(value))
	var domains:Array=allocations.keys()
	domains.sort_custom(func(a,b)->bool: return int(allocations[b])<int(allocations[a]))
	for domain in domains:
		var id:=String(domain)
		var weight:=maxi(0,int(allocations[id]))
		var share:=float(weight)/maxf(1.0,float(total_weight))
		items.append({
			"name":id.capitalize(),"count":weight,
			"pct":"%d%%" % roundi(share*100.0),
			"color":DOMAIN_COLORS.get(id,Tokens.MUTED),
			"tip":"Weight %d of %d — about %.1f observers follow this domain automatically" % [weight,total_weight,share*float(observers)],
			"on_minus":terrain._change_research_domain_allocation.bind(id,-1),
			"on_plus":terrain._change_research_domain_allocation.bind(id,1),
		})
	return [
		{"type":"alloc","heading":"ATTENTION BY DOMAIN","note":"weights · observers follow the shares","items":items},
		{"type":"text","text":"Weights are shares, not people. Every observer is always working; raising a weight simply shifts more of them toward that domain."},
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
			"icon":ResourceIcons.domain_texture(domain,DOMAIN_COLORS.get(domain,Tokens.TEAL)),
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
	# Group by domain, newest finding first inside each group. Domains collapse
	# to one aggregate row so fifty findings read as a dozen lines.
	var by_domain:Dictionary={}
	var domain_order:Array[String]=[]
	for index in range(log.size()-1,-1,-1):
		var event:Dictionary=log[index]
		var domain:=String(event.get("dynamic",""))
		if not by_domain.has(domain):
			by_domain[domain]=[]
			domain_order.append(domain)
		(by_domain[domain] as Array).append(event)
	var items:Array=[]
	for domain in domain_order:
		var events:Array=by_domain[domain]
		var accent:Color=DOMAIN_COLORS.get(domain,Tokens.GREEN)
		var domain_open:bool=expanded_domains.has(domain)
		items.append({
			"name":domain.capitalize().to_upper(),
			"sub":"%d finding%s · latest day %d" % [events.size(),"" if events.size()==1 else "s",int((events[0] as Dictionary).get("day",0))],
			"detail":_domain_aggregate_text(events),
			"icon":ResourceIcons.domain_texture(domain,accent),
			"value":"▾" if domain_open else "▸","value_color":Tokens.MUTED,
			"accent":accent,
			"on_click":_toggle_domain.bind(domain),
			"tip":"Click to %s this domain's findings." % ("collapse" if domain_open else "list"),
		})
		if not domain_open: continue
		for event_variant in events:
			var event:Dictionary=event_variant
			var entry_key:=String(event.get("id","%s_%d" % [String(event.get("name","")),int(event.get("day",0))]))
			var expanded:bool=expanded_discoveries.has(entry_key)
			var description:=String(event.get("description",event.get("observation","")))
			var detail_lines:Array[String]=[]
			if expanded and description!="": detail_lines.append(description)
			detail_lines.append(_established_effect_text(event))
			items.append({
				"name":"    %s" % String(event.get("name","Discovery")),
				"sub":"    day %d" % int(event.get("day",0)),
				"detail":"\n".join(detail_lines),
				"value":"▾" if expanded else "▸","value_color":Tokens.MUTED,
				"accent":Color(accent,0.35),
				"on_click":_toggle_discovery.bind(entry_key),
				"tip":"Click to %s the full account." % ("collapse" if expanded else "read"),
			})
	return [{"type":"rows","heading":"ESTABLISHED KNOWLEDGE","note":"%d total in %d domains" % [log.size(),domain_order.size()],"items":items}]

func _domain_aggregate_text(events:Array)->String:
	# Sum every finding's effects into the domain's standing contribution, so a
	# collapsed domain still answers "what has all of this earned us".
	var totals:Dictionary={}
	for event_variant in events:
		var event:Dictionary=event_variant
		var effects:Dictionary=event.get("effects",{})
		if effects.is_empty():
			effects=DiscoverySystem.discovery_definition(String(event.get("id",""))).get("effects",{})
		for effect_id in effects:
			totals[effect_id]=float(totals.get(effect_id,0.0))+float(effects[effect_id])
	if totals.is_empty():
		return "No direct capacity changes — this domain unlocked prerequisites for later methods."
	var effect_ids:Array=totals.keys()
	effect_ids.sort_custom(func(a,b)->bool: return absf(float(totals[b]))<absf(float(totals[a])))
	var parts:Array[String]=[]
	for effect_id in effect_ids.slice(0,5):
		var display:=String(DiscoverySystem.EFFECT_DISPLAY_NAMES.get(String(effect_id),String(effect_id).replace("_"," ")))
		parts.append("%s %+.1f%%" % [display.capitalize(),float(totals[effect_id])*100.0])
	var text:=" · ".join(parts)
	if effect_ids.size()>5: text+=" · +%d more" % (effect_ids.size()-5)
	return text

func _toggle_domain(domain:String)->void:
	if expanded_domains.has(domain): expanded_domains.erase(domain)
	else: expanded_domains[domain]=true
	hud.live_refresh_dock()

func _toggle_discovery(entry_key:String)->void:
	if expanded_discoveries.has(entry_key): expanded_discoveries.erase(entry_key)
	else: expanded_discoveries[entry_key]=true
	hud.live_refresh_dock()

func _established_effect_text(event:Dictionary)->String:
	var effects:Dictionary=event.get("effects",{})
	if effects.is_empty():
		effects=DiscoverySystem.discovery_definition(String(event.get("id",""))).get("effects",{})
	if effects.is_empty():
		return "No direct capacity change — unlocks prerequisites for later methods."
	var parts:Array[String]=[]
	for effect_id in effects:
		var display:=String(DiscoverySystem.EFFECT_DISPLAY_NAMES.get(String(effect_id),String(effect_id).replace("_"," ")))
		parts.append("%s %+.1f%%" % [display.capitalize(),float(effects[effect_id])*100.0])
	return " · ".join(parts)

func signature()->Array:
	return [GameState.research_allocations.duplicate(),GameState.active_investigations.duplicate(),GameState.discovery_log.size(),int(GameState.population_allocations.get("Knowledge",0)),expanded_discoveries.duplicate(),expanded_domains.duplicate()]
