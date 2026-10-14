extends "res://scripts/hud/content/dock_content_base.gd"
const EraWords:=preload("res://scripts/hud/era_words.gd")
## INQUIRY section: Direct Attention / Investigations / Established.
## Replaces the knowledge panel and the progression panel's research views.

const DOMAIN_COLORS:Dictionary={
	"demography":Color("#9b7252"),"nutrition":Color("#79a8a0"),"health":Color("#8fa26a"),
	"labor":Color("#a9946e"),"knowledge":Color("#8798b5"),"production":Color("#c9a95a"),
	"infrastructure":Color("#b39a68"),"logistics":Color("#d0b46f"),"ecology":Color("#5e9d70"),
	"institutions":Color("#a897c9"),"security":Color("#c67462"),"culture":Color("#766d72"),
}

const ResourceIcons:=preload("res://scripts/resource_icons.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const ArtifactCulture:=preload("res://scripts/artifact_culture.gd")
const Explainer:=preload("res://scripts/effect_explainer.gd")
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const Research600:=preload("res://scripts/research_600_catalog.gd")
const Plain:=preload("res://scripts/hud/home_plain.gd")
const ARTIFACT_COLOR:=Color("#b98a5e")
const Memo:=preload("res://scripts/hud/content/dock_memo.gd")
const Borders:=preload("res://scripts/nation_borders.gd")
const Visits:=preload("res://scripts/scholar_visits.gd")
## Costly parts of the pages, kept while what they are made from holds.
var memo:=Memo.new()

## What each domain's research actually improves — the end goal a player is
## buying when they raise its weight. Aligned with the frontier catalog's
## per-domain effect pairs.
const DOMAIN_GOALS:Dictionary={
	"demography":"Aims at safe conception and maternal safety — how fast the population can grow.",
	"nutrition":"Aims at usable food output and diet quality — how well everyone eats.",
	"health":"Aims at health protection and lower disease exposure — who survives.",
	"labor":"Aims at labor efficiency and task coordination — output per working hand.",
	"knowledge":"Aims at the rate of learning and preserved records — every other inquiry speeds up.",
	"production":"Aims at tool quality and craft output — what raw materials become.",
	"infrastructure":"Aims at construction rate and disaster resilience — what stands and endures.",
	"logistics":"Aims at carrying capacity and route speed — how far food, materials, and armies reach.",
	"ecology":"Aims at natural recovery and lower ecological pressure — what the land can sustain.",
	"institutions":"Aims at state capacity and legitimacy — how much this society can coordinate.",
	"security":"Aims at security efficiency and military readiness — the price of being defended.",
	"culture":"Aims at cohesion and the spread of new practices — how fast change takes hold.",
}

# Discovery ids and domain ids the player has clicked open; everything else
# stays collapsed so the established record scales to hundreds of findings.
var tree_domain:String="nutrition"
## The question chosen on the knowledge tree ("" follows the field's first under way).
var tree_selected:=""
var expanded_discoveries:Dictionary={}
var expanded_domains:Dictionary={}
## Knowledge-tree questions opened to show what they would do.
var expanded_tech:Dictionary={}
## Effect rows and field groups opened in the impact ledgers (impact_ledger.gd
## toggles these itself, so opening one never rebuilds the page).
var effect_state:Dictionary={}

func meta()->Dictionary:
	return {
		"eyebrow":"What the people know and are learning",
		"title":"Research",
		"subtabs":["Where we look","Knowledge tree","What we know"],
	}

func tab(sub:int)->Dictionary:
	# Each tab is one board: its own figures, its own table; nothing is
	# repeated from the top bar or from another tab.
	match sub:
		1: return {"kpis":[],"blocks":[_tree_block()]}
		2: return {"kpis":[],"blocks":[_known_block()]}
	var investigations:Array=DiscoverySystem.active_investigation_records()
	return {"kpis":[],"blocks":[_discovery_board(investigations)]}

func _attention_blocks()->Array:
	var latest:=_latest_discovery_block()
	var items:Array=[]
	var allocations:Dictionary=GameState.research_allocations
	var observers:=maxi(0,int(GameState.population_allocations.get("Knowledge",0)))
	var total_weight:=ArtifactCulture.study_weight()
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
			"tip":"%s\nWeight %d of %d — about %.1f observers follow this domain automatically." % [String(DOMAIN_GOALS.get(id,"")),weight,total_weight,share*float(observers)],
			"on_minus":terrain._change_research_domain_allocation.bind(id,-1),
			"on_plus":terrain._change_research_domain_allocation.bind(id,1),
		})
	items.append(_artifact_study_item(total_weight,observers))
	var blocks:Array=[]
	if not latest.is_empty(): blocks.append(latest)
	blocks.append_array([
		{"type":"alloc","heading":"ATTENTION BY DOMAIN","note":"weights · observers follow the shares","items":items},
		{"type":"text","text":"Weights are shares, not people. Every observer is always working; raising a weight simply shifts more of them toward that domain."},
	])
	return blocks

func _investigation_blocks(domain_filter:String="")->Array:
	var records:Array=DiscoverySystem.active_investigation_records()
	var items:Array=[]
	var unlock_lines:Array[String]=[]
	for record_variant in records:
		var record:Dictionary=record_variant
		if domain_filter!="" and String(record.get("dynamic",""))!=domain_filter:continue
		var progress:=roundi(clampf(float(record.get("progress",0.0)),0.0,1.0)*100.0)
		var domain:=String(record.get("dynamic",""))
		var effects:Dictionary=record.get("effects",{})
		# Plain words for the team, its clock and its step or holdup.
		var bottleneck:=String(record.get("bottleneck",""))
		var phase:=Visuals.phase({"assignment":{"bottleneck":bottleneck,"active":true,"capacity":{"researchers":float(record.get("research_workforce",0.0))}}})
		var clock:=Plain.clock(float(record.get("estimated_days",0.0)))
		var team_line:=Plain.team(float(record.get("research_workforce",0.0)),int(record.get("teams_on",1)))+("; "+clock if not clock.is_empty() else "")+"."
		items.append({
			"name":String(record.get("name","Investigation")),
			"sub":"%s · %s" % [Visuals.name_for(domain),phase if not phase.is_empty() else "under way"],
			"detail":team_line+" "+Visuals.plain_bottleneck(bottleneck)+(" Would bring: %s." % Explainer.summary(effects) if not effects.is_empty() else "")+(" "+Borders.research_note(String(record.get("id",""))) if Borders.research_note(String(record.get("id","")))!="" else ""),
			"icon":ResourceIcons.domain_texture(domain,DOMAIN_COLORS.get(domain,Tokens.TEAL)),
			"value":"%d%%" % progress,"value_color":DOMAIN_COLORS.get(domain,Tokens.TEAL),
			"accent":DOMAIN_COLORS.get(domain,Tokens.TEAL),
			# A young people's slow learning beside its clock (DiscoverySystem.founding_words).
			"tip":"%s\n%s\n%s%s%s" % [String(DOMAIN_GOALS.get(domain,"")),String(record.get("project_goal","")),String(record.get("project_method","")),("\n\n"+String(record.founding_note)) if not String(record.get("founding_note","")).is_empty() else "","\n\nWhat it would do, at full use:\n"+Explainer.effect_lines(effects,1.0,1.0,false) if not effects.is_empty() else ""],
		})
		if unlock_lines.size()<3:
			# The line of inquiry, what it has seen, and what answering it would
			# do in the game (the engine's own readings, at full use).
			unlock_lines.append("%s → %s%s" % [String(record.get("subcategory","An open question")).capitalize(),String(record.get("observation","")),(" Would bring: %s." % Explainer.summary(effects)) if not effects.is_empty() else ""])
	# A staffed line with nothing to study says why instead of looking empty.
	for domain_variant in GameState.research_subcategory_allocations:
		var domain:=String(domain_variant)
		if domain_filter!="" and domain!=domain_filter:continue
		var subs:Dictionary=GameState.research_subcategory_allocations[domain_variant]
		var rows:Array=[]
		for sub_variant in subs:
			var sub:=String(sub_variant)
			if int(subs[sub_variant])<=0 or String(GameState.active_investigations.get(DiscoverySystem._channel_key(domain,sub),""))!="":continue
			if rows.is_empty():rows=DiscoverySystem.technology_tree(domain)
			var reason:=DiscoverySystem.line_wait_reason(domain,sub,rows)
			if reason=="":continue
			items.append({"name":sub,"sub":"%s · waiting" % domain.capitalize(),"detail":reason,"icon":ResourceIcons.domain_texture(domain,Tokens.MUTED),"value":"—","value_color":Tokens.MUTED,"accent":Tokens.MUTED,"tip":reason})
	if items.is_empty():
		return [{"type":"text","heading":"CURRENT INVESTIGATIONS","text":"No viable investigation is running. Attention without supporting evidence waits; explore, work, and observe to create clues."}]
	var blocks:Array=[{"type":"rows","heading":"CURRENT INVESTIGATIONS","note":"evidence","items":items}]
	if not unlock_lines.is_empty():
		blocks.append({"type":"text","heading":"WHAT COMPLETION UNLOCKS","text":"\n".join(unlock_lines)})
	return blocks

## What the people know, one entry per body of knowledge
## (DiscoverySystem.established_knowledge_threads, a deep copy of its own
## cache on every call): made again only when the discovery log moves, and a
## logged discovery is never edited afterwards.
func _threads()->Array:
	return memo.take("threads",[Memo.log_identity(WorldSimulation.state.discovery_log)],func()->Array:return DiscoverySystem.established_knowledge_threads())

func _established_blocks()->Array:
	var log:Array=_threads()
	var blocks:Array=[_knowledge_acts_block()]
	if log.is_empty():
		blocks.append({"type":"text","heading":"ESTABLISHED KNOWLEDGE","text":"Nothing has yet been tried, used and remembered long enough to count as known."})
		return blocks
	# Group by domain, newest finding first inside each group. Domains collapse
	# to one aggregate row so fifty findings read as a dozen lines; an opened
	# finding is followed by its effects, one row each.
	var by_domain:Dictionary={}
	var domain_order:Array[String]=[]
	for index in log.size():
		var event:Dictionary=log[index]
		var domain:=String(event.get("dynamic",""))
		if not by_domain.has(domain):
			by_domain[domain]=[]
			domain_order.append(domain)
		(by_domain[domain] as Array).append(event)
	var items:Array=[]
	var rows_block:Dictionary={"type":"rows","heading":"ESTABLISHED KNOWLEDGE","note":"%d things known, in %d fields" % [log.size(),domain_order.size()]}
	for domain in domain_order:
		var events:Array=by_domain[domain]
		var accent:Color=DOMAIN_COLORS.get(domain,Tokens.GREEN)
		var domain_open:bool=expanded_domains.has(domain)
		items.append({
			"name":Visuals.name_for(domain),
			"sub":"%d thing%s known · latest %s" % [events.size(),"" if events.size()==1 else "s",EraWords.ago(int((events[0] as Dictionary).get("day",0)))],
			"detail":_domain_aggregate_text(domain),
			"icon":ResourceIcons.domain_texture(domain,accent),
			"value":"Hide" if domain_open else "Show","value_color":Tokens.MUTED,
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
			var id:=String(event.get("id",""))
			var effects:Dictionary=DiscoverySystem.discovery_definition(id).get("effects",event.get("effects",{}))
			var detail_lines:Array[String]=[]
			if expanded and description!="": detail_lines.append(description)
			detail_lines.append(_known_summary(id,effects))
			items.append({
				"name":"    %s" % String(event.get("name","Discovery")),
				"sub":"    "+String(event.get("record_summary","Discovered once")),
				"detail":"\n".join(detail_lines),
				"value":"Less" if expanded else "More","value_color":Tokens.MUTED,
				"accent":Color(accent,0.35),
				"on_click":_toggle_discovery.bind(entry_key),
				"tip":"Click to %s the full account and what each of its effects does." % ("collapse" if expanded else "read"),
			})
			if expanded and not effects.is_empty():
				# The finding's effects, one row each, right under it.
				rows_block["items"]=items
				blocks.append(rows_block)
				blocks.append({"type":"impact","state":effect_state,"rows":Explainer.discovery_rows(id,true),
					"intro":"What %s does now. Open an effect to see everywhere it acts." % String(event.get("name","this finding"))})
				items=[]
				rows_block={"type":"rows"}
	if not items.is_empty():
		rows_block["items"]=items
		blocks.append(rows_block)
	return blocks

## "Where your knowledge acts": every effect total the people's knowledge adds
## up to now, as the engine holds it, grouped by field; nothing-reads-it keys last.
func _knowledge_acts_block()->Dictionary:
	var by_line:Dictionary={}
	var inert:Array=[]
	for row:Dictionary in Explainer.total_rows():
		if bool(row.inert): inert.append(row)
		else: (by_line.get_or_add(String(row.line),[]) as Array).append(row)
	var groups:Array=[]
	for domain:String in DOMAIN_COLORS:
		if not by_line.has(domain): continue
		var rows:Array=by_line[domain]
		groups.append({"id":domain,"title":Visuals.name_for(domain),"summary":_rows_summary(rows),"count":"%d effect%s" % [rows.size(),"" if rows.size()==1 else "s"],"accent":Visuals.color(domain),"rows":rows})
	if not inert.is_empty():
		groups.append({"id":"inert","title":"Known, but nothing uses it yet","summary":"These effects are part of what the people know, but nothing in the simulation reads them, so they change nothing.","count":"%d" % inert.size(),"accent":Tokens.BORDER,"rows":inert})
	return {"type":"impact","heading":"WHERE YOUR KNOWLEDGE ACTS","note":"totals now, as the engine counts them","state":effect_state,"groups":groups,
		"intro":"Everything the people know adds up here: each practice counts in proportion to how widely it is used, and each total is held under what the year allows: a limit for each effect that rises as the years pass and the people learn. The capacities named are the twelve on Culture › Society's strengths; each also counts toward the people's next scale in its field. Open a field, then an effect, to see everywhere it acts.",
		"empty":"Nothing the people know acts on the world yet."}

## "Protection from sickness +5.3% · Diet quality +1.1% · 3 more".
static func _rows_summary(rows:Array,limit:int=3)->String:
	var parts:Array[String]=[]
	for index in mini(limit,rows.size()):
		var row:Dictionary=rows[index]
		parts.append("%s %s" % [String(row.label),String(row.amount)])
	if rows.size()>limit: parts.append("%d more" % (rows.size()-limit))
	return " · ".join(parts)

## A known finding in one line: what it adds now, and how widely it is used.
func _known_summary(id:String,effects:Dictionary)->String:
	# What it changes on the map itself, when it does (nation_borders.gd).
	var map_note:=Borders.research_note(id)
	if effects.is_empty(): return map_note if map_note!="" else "Changes nothing by itself; it opens the way to later knowledge."
	var usage:=Explainer.usage_words(id)
	return "Does: %s. %s. Open it to see each effect.%s" % [Explainer.summary(effects),usage.left(1).to_upper()+usage.substr(1)," "+map_note if map_note!="" else ""]

## What a field's known practices add now, before the age's limits.
func _domain_aggregate_text(domain:String)->String:
	var totals:=Explainer.field_totals(domain)
	if totals.is_empty():
		return "Changes nothing by itself; it opens the way to later knowledge."
	var effect_ids:Array=totals.keys()
	effect_ids.sort_custom(func(a,b)->bool: return absf(float(totals[b]))<absf(float(totals[a])))
	var parts:Array[String]=[]
	for effect_id in effect_ids.slice(0,4):
		parts.append("%s %s" % [Explainer.label(String(effect_id)),Explainer.percent(float(totals[effect_id]))])
	var text:="Adds now: "+", ".join(parts)
	if effect_ids.size()>4: text+=" and %d more" % (effect_ids.size()-4)
	return text+"."

## The field's contributions as ledger rows: what counts now. Where
## everything known about an effect adds up past the limit the year sets
## (effect_explainer.totals), each field's part is cut in the same measure,
## so the bars add up to what the engine uses; the row says what was cut.
func _field_rows(domain:String)->Array:
	var totals:=Explainer.field_totals(domain)
	var all:={}
	for total:Dictionary in Explainer.totals():all[String(total.key)]=total
	var rows:Array=[]
	var counted:={}
	for key:String in totals:
		var whole:Dictionary=all.get(key,{})
		var raw:=float(whole.get("raw",0.0))
		var used:=float(whole.get("total",raw))-float(whole.get("upkeep",0.0))
		var before:=float(totals[key])
		var now:=before*used/raw if absf(raw)>absf(used)+0.000001 and absf(raw)>0.000001 else before
		counted[key]=now
		var row:=Explainer.ledger_row(key,now,1.0,1.0,"total")
		row["id"]="field:%s:%s" % [domain,key]
		row["usage"]="now, from this field's practices"
		row["value"]=now
		if absf(before-now)>0.0005:
			(row.notes as Array).push_front("This field's practices add up to %s; %s of it counts now, the rest waits on the year's limit." % [Explainer.percent(before),Explainer.percent(now)])
		rows.append(row)
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return absf(float(counted[a.key]))>absf(float(counted[b.key])))
	return rows

func _toggle_domain(domain:String)->void:
	if expanded_domains.has(domain): expanded_domains.erase(domain)
	else: expanded_domains[domain]=true
	hud.request_immediate_dock_refresh()

func _toggle_discovery(entry_key:String)->void:
	if expanded_discoveries.has(entry_key): expanded_discoveries.erase(entry_key)
	else: expanded_discoveries[entry_key]=true
	hud.request_immediate_dock_refresh()

func _toggle_tech(id:String)->void:
	if expanded_tech.has(id): expanded_tech.erase(id)
	else: expanded_tech[id]=true
	hud.request_immediate_dock_refresh()

## Each effect of a finding on its own line: its size, what it adds now (known)
## or at full use (not yet), and the first thing it moves in the game.
func _established_effect_text(event:Dictionary)->String:
	var id:=String(event.get("id",""))
	var effects:Dictionary=event.get("effects",{})
	if effects.is_empty():
		effects=DiscoverySystem.discovery_definition(id).get("effects",{})
	var known:=id in GameState.known_discoveries
	var definition:=DiscoverySystem.discovery_definition(id)
	return Explainer.effect_lines(effects,Explainer.practice_level(id) if known else 1.0,Explainer.focus_scale(String(definition.get("dynamic",""))) if known else 1.0,known,Explainer.usage_words(id) if known else "")

func signature()->Array:
	return [tree_domain,tree_selected,GameState.research_targets.duplicate(),GameState.discovery_progress.duplicate(),GameState.research_allocations.duplicate(),ArtifactCulture.study_weight(),GameState.society_exchange.collections.size(),GameState.active_investigations.duplicate(),GameState.discovery_log.size(),int(GameState.population_allocations.get("Knowledge",0)),expanded_discoveries.duplicate(),expanded_domains.duplicate(),expanded_tech.duplicate(),GovernmentPeopleSystem.revision]

## The knowledge tree as lanes in the dock (knowledge_tree_board.gd): the
## chosen field's lines of study, what is known, under way, open and waiting
## in each, and the chosen question's account with its one order.
func _tree_block()->Dictionary:
	var rows:Array=_all_rows().filter(func(row:Dictionary)->bool:return String(row.get("dynamic",""))==tree_domain)
	var frontier:=DiscoverySystem.technology_frontier(rows)
	var known_by:=_known_by_field()
	var active_by:Dictionary={}
	for channel:Variant in GameState.active_investigations:
		if String(GameState.active_investigations[channel])=="":continue
		var domain:=String(channel).get_slice("::",0)
		active_by[domain]=int(active_by.get(domain,0))+1
	var fields:Array=[]
	for id:String in DOMAIN_COLORS:fields.append({"id":id,"known":int(known_by.get(id,0)),"active":int(active_by.get(id,0))})
	# The chosen question: the one chosen, else the field's first under way, else its first open.
	var chosen_row:Dictionary={}
	for row:Dictionary in rows:
		if String(row.id)==tree_selected:chosen_row=row;break
	if chosen_row.is_empty():
		for status:String in ["RESEARCHING","AVAILABLE"]:
			for row:Dictionary in rows:
				if String(row.status)==status:chosen_row=row;break
			if not chosen_row.is_empty():break
	return {"type":"knowledge_tree","domain":tree_domain,"fields":fields,"rows":rows,"next":frontier.next,"selected":String(chosen_row.get("id","")),
		"chosen":_tree_chosen(chosen_row,frontier.next),"on_field":_choose_tree_domain,"on_select":_choose_tree_question}

## Every question of every field (DiscoverySystem.technology_tree), made
## again only when what it is made from moves: the one source of the tree's
## lanes and of every "known" count on these pages.
func _all_rows()->Array:
	var rows:Array=memo.take("rows",[GameState.known_discoveries.size(),GameState.active_investigations.hash(),int(GameState.elapsed_days)/30,GameState.resource_deposits.size(),GameState.discovery_progress.size()],func()->Array:return DiscoverySystem.technology_tree())
	# The evidence moves every day: read it fresh onto the kept rows.
	for row:Dictionary in rows:row["progress"]=float(GameState.discovery_progress.get(String(row.id),0.0))
	return rows

## Questions known in each field, from the same rows: {domain: count}.
func _known_by_field()->Dictionary:
	var counts:Dictionary={}
	for row:Dictionary in _all_rows():
		if String(row.get("status",""))=="DISCOVERED":counts[String(row.dynamic)]=int(counts.get(String(row.dynamic),0))+1
	return counts

## What we know (known_board.gd): known against every question, what was
## learned this year and the newest finding; then each field's count, what
## its knowledge adds now (the engine's totals) and, opened, every effect and
## its findings newest first.
func _known_block()->Dictionary:
	var rows:=_all_rows()
	var total_by:Dictionary={}
	var findings_by:Dictionary={}
	var known:=0
	for row:Dictionary in rows:
		var domain:=String(row.get("dynamic",""))
		total_by[domain]=int(total_by.get(domain,0))+1
		if String(row.get("status",""))!="DISCOVERED":continue
		known+=1
		(findings_by.get_or_add(domain,[]) as Array).append(row)
	var days:Dictionary={}
	for event:Variant in WorldSimulation.state.discovery_log:
		if event is Dictionary and not days.has(String(event.get("id",""))):days[String(event.get("id",""))]=int(event.get("day",-1))
	var by_line:Dictionary={}
	var inert:Array=[]
	for row:Dictionary in Explainer.total_rows():
		if bool(row.inert):inert.append(row)
		else:(by_line.get_or_add(String(row.line),[]) as Array).append(row)
	var today:=int(GameState.elapsed_days)
	var this_year:=0
	var newest:Dictionary={}
	var newest_day:=-1
	var fields:Array=[]
	for domain:String in DOMAIN_COLORS:
		var found:Array=findings_by.get(domain,[])
		found.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(days.get(String(a.id),-1))>int(days.get(String(b.id),-1)))
		var listed:Array=[]
		for row:Dictionary in found:
			var day:=int(days.get(String(row.id),-1))
			if day>=0 and today-day<3650:this_year+=1
			if day>newest_day:newest_day=day;newest=row
			var effects:Dictionary=row.get("effects",{})
			listed.append({"name":String(row.name),"tip":"%s\n%s%s" % [String(row.name),("Learned "+EraWords.ago(day)) if day>=0 else "Known since before we set out",("\nDoes: "+Explainer.summary(effects)) if not effects.is_empty() else "\nOpens later knowledge"]})
		var effect_rows:Array=by_line.get(domain,[])
		var parts:Array=[]
		for row:Dictionary in effect_rows:parts.append("%s %s" % [String(row.label),String(row.amount)])
		fields.append({"id":domain,"known":found.size(),"total":int(total_by.get(domain,0)),"adds":parts,"effects":effect_rows,"findings":listed,
			"open":expanded_domains.has(domain),"on_toggle":_toggle_domain.bind(domain)})
	var figures:Array=[
		{"title":"KNOWN","value":EraWords.grouped(known),"note":"of %s questions in all" % EraWords.grouped(rows.size()),"ratio":float(known)/maxf(1.0,float(rows.size())),"tip":"Questions the people have answered, of every question there is to answer in all the fields."},
		{"title":"LEARNED IN TEN YEARS","value":str(this_year),"note":"the last ten years","tip":"Questions answered in the last ten years."},
		{"title":"NEWEST","value":String(newest.get("name","None yet")),"note":EraWords.ago(newest_day) if newest_day>=0 else "","tip":"The question answered most recently.","stretch":1.6},
	]
	return {"type":"known_board","figures":figures,"fields":fields,"inert":inert}

## The chosen question's account: its state, what it does or would do, what
## it builds on and waits for, what it opens, and the order that puts a team on it.
func _tree_chosen(row:Dictionary,next:Dictionary)->Dictionary:
	if row.is_empty():return {}
	var id:=String(row.id)
	var status:=String(row.status)
	var known:=status=="DISCOVERED"
	var effects:Dictionary=row.get("effects",{})
	var chosen:={"name":String(row.name),"facts":[]}
	match status:
		"DISCOVERED":
			var day:=preload("res://scripts/hud/atlas_data.gd")._discovered_day(id)
			chosen.state="Known"+(" since %s" % EraWords.when(day) if day>=0 else " since before we set out")
			chosen.tone="good"
		"RESEARCHING":
			chosen.state="Under way: %d in 100 of the evidence" % roundi(float(row.progress)*100.0)
			chosen.progress=float(row.progress)
		"AVAILABLE":
			chosen.state="Open to a team now"
		_:
			chosen.state=("Waiting: "+DiscoverySystem.plain_wait_reason(row.get("missing",[]))) if next.has(id) else "Further along: it opens once the questions before it are answered"
			chosen.tone="warn"
	if not known or not effects.is_empty() or Borders.research_note(id)!="":
		var does:=Explainer.summary(effects,4) if not effects.is_empty() else "Nothing by itself; it opens later questions"
		var amounts:=Explainer.amount_lines(effects,Explainer.practice_level(id) if known else 1.0,Explainer.focus_scale(String(row.get("dynamic",""))) if known else 1.0,known)
		chosen.facts.append(["Does" if known else "Would bring",does,amounts])
	if Borders.research_note(id)!="":chosen.facts.append(["On the map",Borders.research_note(id)])
	var builds:Array[String]=[]
	for requirement:Variant in row.get("requires",[]):builds.append(String(DiscoverySystem.discovery_definition(String(requirement)).get("name",requirement)))
	if not builds.is_empty():chosen.facts.append(["Builds on",", ".join(builds)])
	if not known and not (row.get("missing",[]) as Array).is_empty() and status=="LOCKED":chosen.facts.append(["Waits for","; ".join(PackedStringArray(row.missing))])
	if not known and float(row.get("years_ahead",0.0))>=1.0:
		var factor:=DiscoverySystem.research_early_factor(row)
		chosen.facts.append(["Price","%s the usual work: it belongs to a later age" % preload("res://scripts/hud/inquiry_board.gd")._times(factor),"Dated %d years after the age our learning has reached. Work on it goes slower in proportion; as our learning catches up its price falls." % roundi(float(row.years_ahead))])
	var opens:Array=row.get("leads_to",[])
	if not opens.is_empty():chosen.facts.append(["Opens",", ".join(PackedStringArray(opens.slice(0,4)))+(" and %d more" % (opens.size()-4) if opens.size()>4 else "")])
	if bool(row.get("ready",false)) and status!="RESEARCHING":
		chosen.on_research=_research_technology.bind(id)
		chosen.research_label="Put a team on it"
	return chosen

func _choose_tree_question(id:String)->void:
	tree_selected=id
	hud.request_immediate_dock_refresh()

func _choose_tree_domain(domain:String)->void:
	tree_domain=domain
	tree_selected=""
	hud.request_immediate_dock_refresh()

func _research_technology(id:String)->void:
	var result:Dictionary=DiscoverySystem.select_research_target(id)
	preload("res://scripts/order_tracker.gd").research_order(id,String(DiscoverySystem.discovery_definition(id).get("name",id.replace("_"," "))),result)
	hud.request_immediate_dock_refresh()

func _latest_discovery_block()->Dictionary:
	for event in GameState.discovery_log:
		var discovery:=DiscoverySystem.discovery_definition(String(event.get("id","")))
		if discovery.is_empty() or bool(discovery.get("frontier",false)): continue
		var next:Array[String]=[]
		for candidate in DiscoverySystem.technology_catalog:
			if String(discovery.id) in candidate.get("requires",[]): next.append(String(candidate.name))
		var description:=String(discovery.get("observation",""))+"\n"+_established_effect_text(discovery)
		if not next.is_empty(): description+="\nOpens %d further avenues of inquiry." % next.size()
		return {"type":"text","heading":"DISCOVERED · "+String(discovery.name),"text":description}
	return {}

## The knowledge tree is drawn in the dock (knowledge_tree_board.gd); no tab
## opens a screen of its own.
func open_expanded_tab(_sub:int)->bool:
	return false

## Shows a question on the knowledge tree: its field, with it chosen.
func show_question(id:String)->void:
	var domain:=String(DiscoverySystem.discovery_definition(id).get("dynamic",""))
	if domain!="":tree_domain=domain
	tree_selected=id

func _open_report(title:String,reader:Callable)->void:
	var report:=preload("res://scripts/hud/content/focused_report.gd").new(terrain,hud,title,"INQUIRY",reader,signature)
	hud.open_detail(report)
func open_domain(domain:String)->void:
	_open_report(Visuals.name_for(domain),_domain_report.bind(domain))
func _attention_overview()->Array:
	return [{"type":"text","heading":"WHAT SHOULD WE UNDERSTAND BETTER?","text":"Choose a direction. Your people pursue the work; evidence, experience and established knowledge determine what becomes possible."},{"type":"actions","items":[focused_action("FOOD & LAND","Nutrition and the living landscape",_domain_group.bind(["nutrition","ecology"])),focused_action("PEOPLE & COMMUNITY","Growth, health and culture",_domain_group.bind(["demography","health","culture"])),focused_action("WORK & MAKING","Labor, production and construction",_domain_group.bind(["labor","production","infrastructure"])),focused_action("KNOWLEDGE & SOCIETY","Learning, institutions and security",_domain_group.bind(["knowledge","institutions","security","logistics"]))]},{"type":"actions","items":[focused_action("RESEARCH WORK","Your leader's labor priority",_research_work_report),focused_action("COMPARE ATTENTION","Advanced shares across all domains",func()->Dictionary:return {"blocks":_attention_blocks()})]}]
func _domain_group(domains:Array)->Dictionary:
	var items:Array=[]
	for id:String in domains:items.append({"label":id.capitalize(),"sub":String(DOMAIN_GOALS[id]).trim_prefix("Aims at "),"on_press":open_domain.bind(id)})
	return {"blocks":[{"type":"actions","heading":"CHOOSE A DIRECTION","items":items}]}
## A field's page, drawn (field_sheet.gd): its banner, its attention as a
## dial and a dot per learner, what its knowledge does now as bars, and its
## questions under way with what each would bring.
func _domain_report(id:String)->Dictionary:
	var weight:=int(GameState.research_allocations.get(id,0));var total:=ArtifactCulture.study_weight()
	for amount in GameState.research_allocations.values():total+=maxi(0,int(amount))
	var share:=float(weight)/maxf(1,total)
	var observers:=int(GameState.population_allocations.get("Knowledge",0))
	var questions:Array=[]
	for record:Dictionary in DiscoverySystem.active_investigation_records():
		if String(record.get("dynamic",""))!=id:continue
		var effects:Dictionary=record.get("effects",{})
		var would:Array=Explainer.discovery_rows(String(record.id),false) if not effects.is_empty() else []
		for row:Dictionary in would:row["value"]=float(effects.get(row.key,0.0))
		questions.append({"record":record,"rows":would})
	# The sheet keeps its nodes (and the bars opened) while what it shows holds.
	var rows:=_field_rows(id)
	var shown:Array=[id,weight,total,observers]
	for row:Dictionary in rows:shown.append([row.key,row.amount,row.tone])
	for question:Dictionary in questions:
		var record:Dictionary=question.record
		shown.append([record.get("id",""),roundi(float(record.get("progress",0.0))*100.0),record.get("bottleneck",""),roundi(float(record.get("estimated_days",0.0))/30.0),roundi(float(record.get("trial_share",0.0))*100.0),roundf(float(record.get("research_workforce",0.0))*10.0)])
	var goal:=String(DOMAIN_GOALS.get(id,""))
	goal=(goal.get_slice(" — ",1) if " — " in goal else goal.trim_prefix("Aims at ")).trim_suffix(".")
	return {"blocks":[{"type":"field_sheet","id":id,"name":Visuals.name_for(id),"goal":goal.left(1).to_upper()+goal.substr(1),
		"share":share,"weight":weight,"learners":observers,"on_field":share*observers,
		"caveat":"About %d in every 100 of our learners' hours go to this field. More attention speeds the work here but cannot replace missing clues; it moves people already at learning and creates no discovery, people or resources." % roundi(share*100),
		"rows":rows,"questions":questions,"state":effect_state,"_print":str(shown).hash(),
		"on_more":terrain._change_research_domain_allocation.bind(id,1),"on_less":terrain._change_research_domain_allocation.bind(id,-1),
		"on_investigations":_open_report.bind("Under way in %s" % Visuals.name_for(id).to_lower(),func()->Dictionary:return {"blocks":_investigation_blocks(id)}),
		"on_work":_open_report.bind("Who does the work",_research_work_report)}]}
func _research_work_report()->Dictionary:
	var id:=SettlementModel._primary_settlement_id()
	var state:=GovernmentPeopleSystem.settlement_management(id)
	var occupied:=not String(SettlementModel.settlement_record(id).get("occupied_by","")).is_empty()
	return {"blocks":[{"type":"text","heading":"LOCAL RESEARCH WORK","text":"%d people work at learning now. The local leader shares out their time with food, water and other needs, and is putting extra hands on %s."%[int(GameState.population_allocations.get("Knowledge",0)),String({"water":"water","provisions":"food","shelter":"shelter","research":"learning","defense":"the watch","logistics":"carrying and paths","development":"building up the place","establishment":"setting the place up"}.get(String(state.get("focus","")),"everyday needs"))]},{"type":"actions","items":[{"label":"More hands on learning","sub":"Not while the place is occupied" if occupied else "Ask the leader to move some people to learning","disabled":occupied,"on_press":func():GovernmentPeopleSystem.set_settlement_focus(id,"research");hud.request_immediate_dock_refresh()},{"label":"Let the leader decide","sub":"Not while the place is occupied" if occupied else "Let the leader choose again","disabled":occupied,"on_press":func():GovernmentPeopleSystem.restore_delegation(id);hud.request_immediate_dock_refresh()}]},{"type":"text","text":"This changes the local work priority, not discovery outcomes. Essential needs can still constrain research; observations and investigations develop as time advances."}]}

## Distinct questions the lines of attention hold, read without refreshing them.
func _questions_under_way()->int:
	var ids:Dictionary={}
	for id:Variant in GameState.active_investigations.values():
		if String(id)!="":ids[String(id)]=true
	return ids.size()

func _discovery_board(investigations:Array)->Dictionary:
	var fields:Array=[]
	var total:=ArtifactCulture.study_weight()
	for amount in GameState.research_allocations.values():total+=maxi(0,int(amount))
	for id:String in DOMAIN_COLORS:
		var weight:=maxi(0,int(GameState.research_allocations.get(id,0)))
		var count:=0
		for record:Dictionary in investigations:
			if String(record.get("dynamic",""))==id:count+=1
		fields.append({"id":id,"goal":String(DOMAIN_GOALS[id]).trim_prefix("Aims at "),"weight":weight,"share":float(weight)/maxf(1,total),"active":count,"on_open":open_domain.bind(id),"on_more":terrain._change_research_domain_allocation.bind(id,1),"on_less":terrain._change_research_domain_allocation.bind(id,-1)})
	return {"type":"inquiry_board","fields":fields,"investigations":investigations,"choices":DiscoverySystem.team_choices(),"pace":learning_pace(investigations),"waiting":_waiting_lines(),"on_choose":_choose_team_question,
		"hands":_hands(),"artifacts":_artifact_study()}

## Who sets the learners (the local leader's work priority), in a few words,
## and the two orders that change it.
func _hands()->Dictionary:
	var id:=SettlementModel._primary_settlement_id()
	var state:=GovernmentPeopleSystem.settlement_management(id)
	var occupied:=not String(SettlementModel.settlement_record(id).get("occupied_by","")).is_empty()
	var focus:=String({"water":"water","provisions":"food","shelter":"shelter","research":"learning","defense":"the watch","logistics":"carrying and paths","development":"building up the place","establishment":"setting the place up"}.get(String(state.get("focus","")),"everyday needs"))
	return {"words":"The local leader favours %s" % focus,"occupied":occupied,
		"tip":"The local leader shares out the people's time between food, water, learning and other needs. Asking for more hands on learning changes who works at learning, not what is found; essential needs can still hold it back.",
		"on_more":func():GovernmentPeopleSystem.set_settlement_focus(id,"research");hud.request_immediate_dock_refresh(),
		"on_free":func():GovernmentPeopleSystem.restore_delegation(id);hud.request_immediate_dock_refresh()}

## Artifact study as a row of the board: its share of the learners' time and the collection's count.
func _artifact_study()->Dictionary:
	var capacity:Dictionary=ArtifactCulture.A.study_capacity()
	var summary:=ArtifactCulture.summary()
	var item:=_artifact_study_item(int(capacity.total_weight),0)
	var words:="%d waiting · %d in study · %d studied" % [int(summary.unstudied_count),int(summary.in_study_count),int(summary.studied_count)]
	if float(capacity.researchers)>0:words+=" · %s a day" % ("%.1f study-work" % float(capacity.rate))
	return {"share":float(capacity.weight)/maxf(1.0,float(capacity.total_weight)),"weight":int(capacity.weight),"words":words,"tip":String(item.tip),"on_less":item.on_minus,"on_more":item.on_plus}

## How fast the people learn and what limits it, every number the engine's
## own: the learners and their teams' work (Research600.team_capacity) against
## the learners a people of our age can spare (the sustainable share), the
## goods they are fed (DiscoverySystem.role_effect), a young people's extra
## work (Research600.founding_work), the lead over the calendar, the support of
## food, tools, order and schooling (research_capacity_for), scholars' pay,
## gifted scholars, teachers abroad and visiting, builders' craft on building
## questions, artifact study, the offices over each field and the price of the
## questions under way (their years ahead and work).
static func learning_pace(records:Array)->Dictionary:
	var effect:Dictionary=DiscoverySystem.role_effect("Knowledge",1.0)
	var teams:Dictionary=DiscoverySystem.research_teams()
	var state=WorldSimulation.state
	var learners:=float(effect.get("learners",0.0))
	var able:=maxf(1.0,float(state.able_population()))
	var sustainable:=float(effect.get("sustainable_share",0.0))
	var typical:=sustainable*able
	var typical_work:=Research600.team_capacity(typical)
	var goods_factor:=float(effect.get("goods_factor",1.0))
	var work:=float(teams.work)*goods_factor
	var capacity:Dictionary=DiscoverySystem.research_capacity_for("knowledge","")
	var day:=int(state.elapsed_days)
	var year:=float(effect.get("learning_year",float(state.elapsed_days)/365.0))
	# The questions under way: their price (years ahead, work), offices,
	# materials, visiting teachers and the proofs a year their clocks add up to.
	var proofs:=0.0
	var factors:=0.0
	var offices:=0.0
	var counted:=0
	var earliest:=INF
	var furthest:=0.0
	var thin:=0
	var lacking:Array=[]
	var taught:Array=[]
	for record:Dictionary in records:
		var days:=float(record.get("estimated_days",0.0))
		# Its evidence a year at today's pace (estimated_days is the rest of
		# the evidence at that pace): together, the questions proven a year.
		if days>0.0:proofs+=365.0*(1.0-clampf(float(record.get("progress",0.0)),0.0,1.0))/days
		factors+=maxf(1.0,float(record.get("work_factor",1.0)))
		offices+=float(record.get("leader_factor",1.0))
		counted+=1
		var ahead:=float(record.get("years_ahead",0.0))
		earliest=minf(earliest,ahead);furthest=maxf(furthest,ahead)
		if String(record.get("bottleneck","")).begins_with("RESEARCH WORKFORCE"):thin+=1
		if float(record.get("material_evidence",1.0))<0.78:lacking.append(String(record.get("name","")))
		if Visits.bonus(String(record.get("id","")),day)>1.0:taught.append(String(record.get("name","")))
	# Gifted scholars (geniuses.gd): grown, living, their gift learning.
	var gifted:Array=[]
	for g:Dictionary in WorldSimulation.figures.geniuses:
		if String(g.get("status",""))!="adult":continue
		var person:Dictionary=WorldSimulation.figures.by_id(String(g.get("figure_id","")))
		if person.is_empty() or String(person.get("status",""))!="living":continue
		if String((person.get("genius",{}) as Dictionary).get("layer",""))=="Knowledge":gifted.append(String(person.get("name","")))
	return {
		"learners":learners,"heads":maxf(0.0,float(state.workers_at("Knowledge"))),"able":able,
		"teams":int(teams.count),"teams_at_work":int(teams.placed),"on_lines":float(teams.on_lines),
		"work":work,"typical":typical,"typical_work":typical_work,"sustainable":sustainable,
		"ratio":work/typical_work if typical_work>0.0 else 0.0,
		"goods_need":float(effect.get("goods_a_day",0.0)),"goods_cover":float(effect.get("goods_cover",1.0)),"goods_factor":goods_factor,
		"goods_held":float(effect.get("goods_held",0.0)),"goods_per_learner":float(effect.get("goods_per_learner",0.0)),
		"lead":float(effect.get("lead_years",0.0)),"lead_rate":float(effect.get("lead_rate",0.0)),"year":year,
		"founding":Research600.founding_work(year),"founding_words":DiscoverySystem.founding_words(),
		"support":float(capacity.get("support_multiplier",1.0)),"education":float(capacity.get("education",0.0)),"food_security":float(state.food_security),
		"pay":preload("res://scripts/realm_purse.gd").scholars_factor(),
		"gifted":gifted,"gifted_lift":preload("res://scripts/geniuses.gd").bonus(state,"Knowledge"),
		"abroad":Visits.absent(state,day),"taught":taught,
		"craft":preload("res://scripts/built_fabric.gd").research_multiplier("infrastructure"),
		"studying":preload("res://scripts/society_exchange.gd").studying(),
		"questions":counted,"proofs":proofs,"work_factor":factors/float(counted) if counted>0 else 1.0,
		"offices":offices/float(counted) if counted>0 else 1.0,
		"earliest":earliest if counted>0 else 0.0,"furthest":furthest,"thin":thin,"lacking":lacking,
	}

## Each followed line with no question under way, and why it waits
## (DiscoverySystem.line_wait_reason, read through the same engine calls):
## {channel: {domain, line, kind, name, years, factor, lacks, missing, reason}}.
## Kind is "turn" (a question of its age waits for a free team), "ahead" (its
## next question is ahead of its age, so nearer work goes first) or "gate"
## (nothing in reach: earlier knowledge, a material or a place it lacks). Kept
## while what it is made from holds (a month at most, as its years ahead move).
func _waiting_lines()->Dictionary:
	var state=WorldSimulation.state
	return memo.take("waiting",[state.known_discoveries.size(),state.active_investigations.hash(),state.research_subcategory_allocations.hash(),int(state.elapsed_days)/30,state.resource_deposits.size()],func()->Dictionary:return waiting_lines())

static func waiting_lines()->Dictionary:
	var state=WorldSimulation.state
	var today:=int(floor(state.elapsed_days))
	var waiting:Dictionary={}
	var trees:Dictionary={}
	DiscoverySystem.begin_research_scan()
	for domain_variant in state.research_subcategory_allocations:
		var domain:=String(domain_variant)
		var lines:Dictionary=state.research_subcategory_allocations[domain_variant]
		for line_variant in lines:
			var line:=String(line_variant)
			var channel:String=DiscoverySystem._channel_key(domain,line)
			if int(lines[line_variant])<=0 or String(state.active_investigations.get(channel,""))!="":continue
			var info:={"domain":domain,"line":line,"kind":"gate","name":"","years":0.0,"factor":1.0,"lacks":[],"missing":[]}
			var next:Dictionary=DiscoverySystem._best_candidate_for_channel(channel,today)
			if DiscoverySystem._channel_has_candidate(channel,today):
				info.kind="turn";info.name=String(next.get("name",""))
			elif not next.is_empty():
				info.kind="ahead";info.name=String(next.get("name",""))
				info.years=DiscoverySystem.research_years_ahead(next);info.factor=DiscoverySystem.research_early_factor(next)
			else:
				if not trees.has(domain):trees[domain]=DiscoverySystem.technology_tree(domain)
				var rows:Array=trees[domain]
				var frontier:Dictionary=DiscoverySystem.technology_frontier(rows)
				var best:Dictionary={}
				for row:Dictionary in rows:
					if String(row.get("subcategory",""))!=line or not (frontier.next as Dictionary).has(String(row.id)):continue
					if best.is_empty() or float(row.get("earliest_year",0.0))<float(best.get("earliest_year",0.0)):best=row
				info.name=String(best.get("name",""))
				info.missing=(best.get("missing",[]) as Array).duplicate()
				info.lacks=materials_lacking(info.missing)
			info["reason"]=DiscoverySystem.line_wait_reason(domain,line,trees.get(domain,[]))
			waiting[channel]=info
	DiscoverySystem.end_research_scan()
	return waiting

## The materials named in a question's unmet conditions: "Knowledge of Stone"
## (a design condition) and "Copper Ore: surveyed access…" (a resource gate).
static func materials_lacking(missing:Array)->Array:
	var found:Array=[]
	for reason:Variant in missing:
		var text:=String(reason).strip_edges()
		var material:=""
		if text.begins_with("Knowledge of "):material=text.trim_prefix("Knowledge of ")
		elif ": " in text and " access" in text:material=text.get_slice(": ",0)
		if not material.is_empty() and not found.has(material):found.append(material)
	return found

## A free team's choice from the board: keep the question it took, or send it
## to another until that one is proven.
func _choose_team_question(key:String,id:String)->void:
	# A choice that has lapsed (the team moved on, the season passed) simply
	# leaves the board when it is drawn again.
	DiscoverySystem.choose_team_question(key,id)
	hud.request_immediate_dock_refresh()

## Artifact study is a research-team role inside the same attention budget.
func _artifact_study_item(total_weight:int,observers:int)->Dictionary:
	# The same headcount the collection shows: study speed follows these
	# researchers, and the bare weight is not a number of people.
	var capacity:Dictionary=ArtifactCulture.A.study_capacity()
	var weight:=int(capacity.weight)
	var share:=float(weight)/maxf(1.0,float(capacity.total_weight))
	var people:=ArtifactCulture.researcher_text(float(capacity.researchers))
	var rate_text:="No researchers are assigned; recovered artifacts wait unstudied." if float(capacity.researchers)<=0 else "About %s, %.1f study-work per day (a common piece needs 20, a legendary one 160)." % [people,float(capacity.rate)]
	return {
		"name":"Artifact study · %s" % people,"count":weight,"count_text":"","pct":"%d%%" % roundi(share*100.0),"color":ARTIFACT_COLOR,
		"tip":"Scholars examine held artifacts so they yield culture, research and appraisal value. Weight %d of %d.\n%s" % [weight,int(capacity.total_weight),rate_text],
		"on_minus":_change_artifact_study.bind(-1),"on_plus":_change_artifact_study.bind(1),
	}

func _artifact_study_block()->Dictionary:
	var observers:=maxi(0,int(GameState.population_allocations.get("Knowledge",0)))
	var total:=ArtifactCulture.study_weight()
	for amount in GameState.research_allocations.values():total+=maxi(0,int(amount))
	var summary:=ArtifactCulture.summary()
	var note:="%d waiting · %d in study · %d studied" % [int(summary.unstudied_count),int(summary.in_study_count),int(summary.studied_count)]
	return {"type":"alloc","heading":"RESEARCH TEAM ROLE","note":note,"items":[_artifact_study_item(total,observers)]}

func _change_artifact_study(delta:int)->void:
	ArtifactCulture.change_study_weight(delta)
	hud.request_immediate_dock_refresh()
