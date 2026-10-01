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
	var summary:Dictionary=DiscoverySystem.research_program_summary()
	var observers:=int(summary.get("researchers",0))
	var science:=Indicators.science()
	var emphasis_total:=int(summary.get("emphasis_total",0))
	# Questions, not lines of attention: two lines on one question count once,
	# the same as the cards. Only the board refreshes the lines' questions.
	var investigations:Array=DiscoverySystem.active_investigation_records() if sub==0 else []
	var questions:=investigations.size() if sub==0 else _questions_under_way()
	var established:=_threads().size()
	var kpis:Array=[
		{"label":"SCIENCE CAPACITY" if EraWords.reckoned() else ("KEEPERS OF LORE" if EraWords.hearth() else "SCHOLARS"),"value":preload("res://scripts/hud/production_plain.gd").number(float(science.capacity)) if EraWords.reckoned() else str(roundi(float(science.minds))),"delta":"about %s people at it" % preload("res://scripts/hud/production_plain.gd").number(float(science.minds)) if EraWords.reckoned() else "watching and testing","delta_color":Tokens.MUTED,"accent":Tokens.TEAL,"tip":"People at learning, weighted by how well they were taught."},
		{"label":"AVG. EDUCATION" if EraWords.reckoned() else "HOW WELL IT IS TAUGHT","value":"%d%%" % roundi(float(science.education)*100.0) if EraWords.reckoned() else EraWords.teaching(float(science.education)),"delta":"research minds" if EraWords.reckoned() else "kept and passed on","delta_color":Tokens.MUTED,"accent":Tokens.GOLD,"tip":"How well what is known is kept and passed on."},
		{"label":"FIELDS WATCHED","value":str(emphasis_total),"delta":"steps of attention","delta_color":Tokens.MUTED,"accent":Tokens.AMBER,"tip":"All the attention you have given out across the fields; each field gets its share of the people"},
		{"label":"BEING LEARNED","value":str(questions),"delta":("question" if questions==1 else "questions")+(" · %d team%s" % [int(summary.get("teams",0)),"" if int(summary.get("teams",0))==1 else "s"] if int(summary.get("teams",0))>0 else ""),"delta_color":Tokens.MUTED,"accent":Tokens.BLUE,"tip":"Questions people are working on now. The people at learning work in teams, each on one question until it is proven; more of them field more teams."},
		{"label":"THINGS WE KNOW","value":str(established),"delta":"kinds of knowledge","accent":Tokens.GREEN,"tip":"Each is one body of knowledge, with the tests and refinements that followed it"},
	]
	var brief:Dictionary
	if observers==0:
		brief={"tone":"warn","title":"No one is set to learning","why":"Local leaders decide who works at learning. Ask them for more hands on learning.","action_label":"Who does the work","on_action":func():_open_report("RESEARCH WORK",_research_work_report)}
	elif questions==0:
		brief={"tone":"warn","title":"No question is being worked on","why":"Attention alone is not enough: the people need clues and earlier knowledge first. Open a field to see what it is waiting for."}
	else:
		brief={"tone":"info","title":"The people are learning","why":"What they find first depends on clues, place, what they already know, and luck."}
	match sub:
		1: return {"kpis":kpis,"brief":brief,"blocks":_technology_blocks()}
		2: return {"kpis":kpis,"brief":brief,"blocks":_established_blocks()}
	return {"kpis":[kpis[0],kpis[1],kpis[3]],"blocks":[_discovery_board(investigations),_artifact_study_block()]}

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
			"detail":team_line+" "+Visuals.plain_bottleneck(bottleneck)+(" Would bring: %s." % Explainer.summary(effects) if not effects.is_empty() else ""),
			"icon":ResourceIcons.domain_texture(domain,DOMAIN_COLORS.get(domain,Tokens.TEAL)),
			"value":"%d%%" % progress,"value_color":DOMAIN_COLORS.get(domain,Tokens.TEAL),
			"accent":DOMAIN_COLORS.get(domain,Tokens.TEAL),
			"tip":"%s\n%s\n%s%s" % [String(DOMAIN_GOALS.get(domain,"")),String(record.get("project_goal","")),String(record.get("project_method","")),"\n\nWhat it would do, at full use:\n"+Explainer.effect_lines(effects,1.0,1.0,false) if not effects.is_empty() else ""],
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
		"intro":"Everything the people know adds up here: each practice counts in proportion to how widely it is used, and each total is held under what this age allows. The capacities named are the twelve on Culture › Society's strengths; each also counts toward the people's next scale in its field. Open a field, then an effect, to see everywhere it acts.",
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
	if effects.is_empty(): return "Changes nothing by itself; it opens the way to later knowledge."
	var usage:=Explainer.usage_words(id)
	return "Does: %s. %s. Open it to see each effect." % [Explainer.summary(effects),usage.left(1).to_upper()+usage.substr(1)]

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

## The field's contributions as ledger rows.
func _field_rows(domain:String)->Array:
	var totals:=Explainer.field_totals(domain)
	var rows:Array=[]
	for key:String in totals:
		var row:=Explainer.ledger_row(key,float(totals[key]),1.0,1.0,"total")
		row["id"]="field:%s:%s" % [domain,key]
		row["usage"]="now, from this field's practices, before the age's limit"
		rows.append(row)
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return absf(float(totals[a.key]))>absf(float(totals[b.key])))
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
	return [tree_domain,GameState.research_targets.duplicate(),GameState.discovery_progress.duplicate(),GameState.research_allocations.duplicate(),ArtifactCulture.study_weight(),GameState.society_exchange.collections.size(),GameState.active_investigations.duplicate(),GameState.discovery_log.size(),int(GameState.population_allocations.get("Knowledge",0)),expanded_discoveries.duplicate(),expanded_domains.duplicate(),expanded_tech.duplicate(),GovernmentPeopleSystem.revision]

func _technology_blocks()->Array:
	var blocks:Array=[]
	var filters:Array=[]
	for domain in DOMAIN_COLORS:
		filters.append({"label":String(domain).capitalize(),"primary":String(domain)==tree_domain,"on_press":_choose_tree_domain.bind(String(domain))})
	blocks.append({"type":"actions","heading":"RESEARCH BRANCHES","items":filters})
	blocks.append({"type":"text","text":"Choose a technology to pursue. Research competes for your finite observers. Switching projects preserves unfinished work; prerequisites and material access still apply. Click a question to see what it does, or would do, in the game."})
	var technologies:=DiscoverySystem.technology_tree(tree_domain)
	var frontier:=DiscoverySystem.technology_frontier(technologies)
	for technology in technologies:
		var id:=String(technology.id)
		var status:=String(technology.status)
		if status=="LOCKED":
			# Next reachable questions are named with what they wait on; deeper
			# ones are summarized as a count below.
			if frontier.next.has(id):blocks.append({"type":"rows","items":[{"name":String(technology.name),"sub":"NEXT · LOCKED","detail":DiscoverySystem.plain_wait_reason(technology.missing)+". The outcome is not yet known.","accent":Tokens.MUTED}]})
			continue
		var known:=status=="DISCOVERED"
		var effects:Dictionary=technology.get("effects",{})
		var open:=expanded_tech.has(id)
		var detail:=String(technology.get("observation",""))
		if effects.is_empty(): detail+="\nChanges nothing by itself; it opens the way to later knowledge."
		else: detail+="\n%s %s.%s" % ["Does:" if known else "Would bring:",Explainer.summary(effects)," Click to %s each effect." % ("hide" if open else "see")]
		var children:Array=technology.leads_to
		if not children.is_empty(): detail+="\nOpens %d further avenues of inquiry." % children.size()
		var prerequisites:Array=[]
		for requirement in technology.get("requires",[]): prerequisites.append(String(DiscoverySystem.discovery_definition(String(requirement)).get("name",requirement)))
		if not prerequisites.is_empty(): detail+="\nREQUIRES → "+", ".join(prerequisites)
		if not (technology.missing as Array).is_empty(): detail+="\nWAITING FOR → "+", ".join(technology.missing)
		var row:={"name":String(technology.name),"sub":status,"detail":detail,"value":"%d%%" % roundi(float(technology.progress)*100.0) if status=="RESEARCHING" else "","accent":Tokens.GREEN if status=="DISCOVERED" else (Tokens.GOLD if bool(technology.ready) else Tokens.MUTED)}
		if not effects.is_empty():
			row["on_click"]=_toggle_tech.bind(id)
			row["tip"]=Explainer.amount_lines(effects,Explainer.practice_level(id) if known else 1.0,Explainer.focus_scale(String(technology.get("dynamic",""))) if known else 1.0,known)+"\n\nClick to see what each one does in the game."
		blocks.append({"type":"rows","items":[row]})
		if open and not effects.is_empty():
			blocks.append({"type":"impact","state":effect_state,"rows":Explainer.discovery_rows(id,known),
				"intro":("What it does now, at how widely it is used." if known else "What it would do once answered, at full use. Tried in a few households before it is proven, a new practice starts with about %d in 100 households and spreads over years, so its effects grow as it is taken up." % roundi(Research600.PROOF_ADOPTION*100.0))})
		if bool(technology.ready) and status!="RESEARCHING": blocks.append({"type":"actions","items":[{"label":"RESEARCH "+String(technology.name).to_upper(),"primary":true,"on_press":_research_technology.bind(id)}]})
	if int(frontier.beyond)>0:blocks.append({"type":"rows","items":[{"name":"%d further questions beyond" % int(frontier.beyond),"sub":"LOCKED","detail":"They open as the questions above are answered. Their outcomes are not yet known.","accent":Tokens.MUTED}]})
	return blocks

func _choose_tree_domain(domain:String)->void:
	tree_domain=domain
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

func open_expanded_tab(sub:int)->bool:
	if sub!=1:return false
	preload("res://scripts/hud/knowledge_atlas.gd").open(terrain,hud,"inquiry")
	return true

func _open_report(title:String,reader:Callable)->void:
	var report:=preload("res://scripts/hud/content/focused_report.gd").new(terrain,hud,title,"INQUIRY",reader,signature)
	hud.open_detail(report)
func open_domain(domain:String)->void:
	_open_report(domain.capitalize(),_domain_report.bind(domain))
func _attention_overview()->Array:
	return [{"type":"text","heading":"WHAT SHOULD WE UNDERSTAND BETTER?","text":"Choose a direction. Your people pursue the work; evidence, experience and established knowledge determine what becomes possible."},{"type":"actions","items":[focused_action("FOOD & LAND","Nutrition and the living landscape",_domain_group.bind(["nutrition","ecology"])),focused_action("PEOPLE & COMMUNITY","Growth, health and culture",_domain_group.bind(["demography","health","culture"])),focused_action("WORK & MAKING","Labor, production and construction",_domain_group.bind(["labor","production","infrastructure"])),focused_action("KNOWLEDGE & SOCIETY","Learning, institutions and security",_domain_group.bind(["knowledge","institutions","security","logistics"]))]},{"type":"actions","items":[focused_action("RESEARCH WORK","Your leader's labor priority",_research_work_report),focused_action("COMPARE ATTENTION","Advanced shares across all domains",func()->Dictionary:return {"blocks":_attention_blocks()})]}]
func _domain_group(domains:Array)->Dictionary:
	var items:Array=[]
	for id:String in domains:items.append({"label":id.capitalize(),"sub":String(DOMAIN_GOALS[id]).trim_prefix("Aims at "),"on_press":open_domain.bind(id)})
	return {"blocks":[{"type":"actions","heading":"CHOOSE A DIRECTION","items":items}]}
func _domain_report(id:String)->Dictionary:
	var weight:=int(GameState.research_allocations.get(id,0));var total:=ArtifactCulture.study_weight()
	for amount in GameState.research_allocations.values():total+=maxi(0,int(amount))
	var share:=float(weight)/maxf(1,total)
	var observers:=int(GameState.population_allocations.get("Knowledge",0))
	var blocks:Array=[{"type":"text","heading":"PURPOSE","text":String(DOMAIN_GOALS.get(id,""))},{"type":"text","heading":"CURRENT ATTENTION","text":"About %d in every 100 of our lore keepers' hours go to this field: roughly %s of our %d people at learning. More attention speeds the work here but cannot replace missing clues."%[roundi(share*100),preload("res://scripts/hud/production_plain.gd").number(share*observers),observers]},{"type":"actions","items":[{"label":"More attention here","sub":"Move one step of attention to this field","on_press":terrain._change_research_domain_allocation.bind(id,1)},{"label":"Less attention here","sub":"Give one step of attention back to the others","disabled":weight<=0,"on_press":terrain._change_research_domain_allocation.bind(id,-1)},focused_action("CURRENT INVESTIGATIONS","Progress and actual bottlenecks",func()->Dictionary:return {"blocks":_investigation_blocks(id)}),focused_action("RESEARCH WORK","Local leadership allocates observers",_research_work_report)]},{"type":"text","text":"Changing attention reallocates existing observers. It creates no discovery, people or resources, and cannot bypass missing evidence or prior knowledge."}]
	blocks.append({"type":"impact","heading":"WHAT THIS FIELD'S KNOWLEDGE DOES","note":"now","state":effect_state,"rows":_field_rows(id),
		"intro":"What the people's knowledge of %s adds now, each practice counted by how widely it is used. The whole people's totals, held under what this age allows, are on the Research page under What we know." % Visuals.name_for(id).to_lower(),
		"empty":"Nothing known in this field acts on the world yet."})
	for record:Dictionary in DiscoverySystem.active_investigation_records():
		if String(record.get("dynamic",""))!=id or (record.get("effects",{}) as Dictionary).is_empty(): continue
		blocks.append({"type":"impact","heading":"IF %s IS ANSWERED" % String(record.get("name","this question")).to_upper(),"note":"at full use","state":effect_state,
			"rows":Explainer.discovery_rows(String(record.id),false),
			"intro":"What this question under way would do. Tried in a few households before it is proven, a new practice starts with about %d in 100 households and spreads over years." % roundi(Research600.PROOF_ADOPTION*100.0)})
	return {"blocks":blocks}
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
	return {"type":"inquiry_board","fields":fields,"investigations":investigations,"choices":DiscoverySystem.team_choices(),"on_choose":_choose_team_question,"on_tree":func():open_expanded_tab(1),"on_work":func():_open_report("Who does the work",_research_work_report),"on_domain":open_domain}

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
