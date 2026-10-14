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

## The field shown on the knowledge tree.
var tree_domain:String="nutrition"
## The question chosen on the knowledge tree ("" follows the field's first under way).
var tree_selected:=""
## Fields opened on What we know.
var expanded_domains:Dictionary={}
var show_unlearned:=false

func meta()->Dictionary:
	return {
		"eyebrow":"What the people know and are learning",
		"title":"Research",
		"subtabs":["Work under way","Explore knowledge","What we know"],
	}

func tab(sub:int)->Dictionary:
	# Each tab is one board: its own figures, its own table; nothing is
	# repeated from the top bar or from another tab.
	match sub:
		1: return {"kpis":[],"blocks":[_tree_block()]}
		2:
			# Capture only: "--capture-open=<field>" opens that field on What we know.
			for argument:String in OS.get_cmdline_user_args():
				if argument.begins_with("--capture-open=") and not has_meta("captured"):set_meta("captured",true);expanded_domains[argument.trim_prefix("--capture-open=")]=true
			return _known_page()
	var investigations:Array=DiscoverySystem.active_investigation_records()
	var board:=_discovery_board(investigations)
	# The board keeps teams and pace beside the decision, with forecasts in
	# its explanatory section, rather than four equally weighted headline tiles.
	return {"kpis":[],"blocks":[board]}

func _toggle_domain(domain:String)->void:
	if expanded_domains.has(domain): expanded_domains.erase(domain)
	else: expanded_domains[domain]=true
	hud.request_immediate_dock_refresh()

func _toggle_unlearned()->void:
	show_unlearned=not show_unlearned
	hud.request_immediate_dock_refresh()

func signature()->Array:
	return [tree_domain,tree_selected,GameState.research_targets.duplicate(),GameState.discovery_progress.duplicate(),GameState.research_allocations.duplicate(),ArtifactCulture.study_weight(),GameState.society_exchange.collections.size(),GameState.active_investigations.duplicate(),GameState.discovery_log.size(),int(GameState.population_allocations.get("Knowledge",0)),expanded_domains.duplicate(),show_unlearned,GovernmentPeopleSystem.revision]

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
	# The board gets only what it draws: each question's name, state, evidence, line and wait.
	var slim:Array=[]
	for row:Dictionary in rows:slim.append({"id":String(row.id),"name":String(row.name),"status":String(row.status),"progress":float(row.progress),"subcategory":String(row.get("subcategory","")),"earliest_year":float(row.get("earliest_year",0.0)),"missing":(row.get("missing",[]) as Array).duplicate()})
	return {"type":"knowledge_tree","domain":tree_domain,"fields":fields,"rows":slim,"next":frontier.next,"selected":String(chosen_row.get("id","")),
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

## What we know, on the game's shared blocks (dense_blocks.gd): the dock's
## strip (known against every question, learned in ten years, open to a team
## now); one table line per field with what its knowledge adds now (the
## engine's totals) and how much of it is known; each opened field beneath in
## a frame: every effect it adds and its findings, newest first.
func _known_page()->Dictionary:
	var rows:=_all_rows()
	var total_by:Dictionary={}
	var findings_by:Dictionary={}
	var known:=0
	var open_now:=0
	for row:Dictionary in rows:
		if String(row.get("status",""))=="AVAILABLE":open_now+=1
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
	var archive_fields:Array=[]
	for domain:String in DOMAIN_COLORS:
		var found:Array=findings_by.get(domain,[])
		found.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(days.get(String(a.id),-1))>int(days.get(String(b.id),-1)))
		var listed:Array=[]
		for row:Dictionary in found:
			var day:=int(days.get(String(row.id),-1))
			if day>=0 and today-day<3650:this_year+=1
			var effects:Dictionary=row.get("effects",{})
			listed.append({"wrap":true,"label":String(row.name),"value":EraWords.ago(day) if day>=0 else "of old","tip":"%s\n%s" % [String(row.name),("Does: "+Explainer.summary(effects)) if not effects.is_empty() else "Opens later knowledge"]})
		var effect_rows:Array=by_line.get(domain,[])
		var parts:Array[String]=[]
		for k in mini(1,effect_rows.size()):parts.append("%s %s" % [String(effect_rows[k].label),String(effect_rows[k].amount)])
		var adds:=" · ".join(parts)+(" · %d more" % (effect_rows.size()-1) if effect_rows.size()>1 else "")
		var open:=expanded_domains.has(domain)
		var total:=int(total_by.get(domain,0))
		var archive_field:={"name":Visuals.name_for(domain),"known":found.size(),"count":"%s of %s" % [EraWords.grouped(found.size()),EraWords.grouped(total)],"summary":adds if adds!="" else "No measured benefit yet; discoveries can open later knowledge.","open":open,"on_toggle":_toggle_domain.bind(domain),"sections":[]}
		archive_fields.append(archive_field)
		if not open:continue
		var effects:Array=[]
		for row:Dictionary in effect_rows:
			var notes:Array[String]=[String(row.get("headline",""))]
			for note:Variant in row.get("notes",[]):notes.append(String(note))
			effects.append({"wrap":true,"label":String(row.label),"value":String(row.amount),"tone":String(row.get("tone","")) if String(row.get("tone","")) in ["good","bad"] else "","tip":"\n".join(notes).strip_edges()})
		var inner:Array=[]
		if not effects.is_empty():inner.append({"type":"fact_grid","heading":"What it adds now","min_column":240,"items":effects})
		if not listed.is_empty():inner.append({"type":"fact_grid","heading":"Findings, newest first"+(" (the newest 36 of %d)" % listed.size() if listed.size()>36 else ""),"min_column":240,"items":listed.slice(0,36)})
		archive_field.sections=inner
	var blocks:Array=[{"type":"knowledge_tree","archive":true,"archive_fields":archive_fields,"show_unlearned":show_unlearned,"on_toggle_unlearned":_toggle_unlearned}]
	if not inert.is_empty():
		blocks.append({"type":"fact_grid","items":[{"label":"Known effects nothing uses yet","value":str(inert.size()),"tip":"Part of what the people know, but nothing in the world reads them yet:\n"+"\n".join(inert.map(func(r:Dictionary)->String:return "%s %s" % [String(r.label),String(r.amount)]))}]})
	var kpis:Array=[
		{"label":"KNOWN","value":EraWords.grouped(known),"delta":"of %s questions" % EraWords.grouped(rows.size()),"glance":true,"meter":float(known)/maxf(1.0,float(rows.size())),"meter_color":Tokens.GOLD,"tip":"Questions the people have answered, of every question there is to answer in all the fields."},
		{"label":"LEARNED IN TEN YEARS","value":str(this_year),"delta":"since year %d" % maxi(1,today/365+1-10),"glance":true,"tip":"Questions answered in the last ten years."},
		{"label":"OPEN TO A TEAM","value":EraWords.grouped(open_now),"delta":"questions ready now","glance":true,"tip":"Questions whose foundations, clues and materials are all in hand: a free team can take any of them up (Knowledge tree)."},
	]
	return {"kpis":kpis,"blocks":blocks}

## The chosen question's account: its state, what it does or would do, what
## it builds on and waits for, what it opens, and the order that puts a team on it.
func _tree_chosen(row:Dictionary,next:Dictionary)->Dictionary:
	if row.is_empty():return {}
	var id:=String(row.id)
	var status:=String(row.status)
	var known:=status=="DISCOVERED"
	var effects:Dictionary=row.get("effects",{})
	var chosen:={"name":String(row.name),"facts":[],"art":{"id":id,"dynamic":String(row.get("dynamic","")),"exposed":bool(row.get("exposed",true))}}
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
		var does:=Explainer.summary(effects,1) if not effects.is_empty() else "Nothing by itself"
		var amounts:=Explainer.amount_lines(effects,Explainer.practice_level(id) if known else 1.0,Explainer.focus_scale(String(row.get("dynamic",""))) if known else 1.0,known)
		chosen.facts.append(["Does" if known else "Would bring",does,amounts])
	if Borders.research_note(id)!="":chosen.facts.append(["On the map","changes it",Borders.research_note(id)])
	var builds:Array[String]=[]
	for requirement:Variant in row.get("requires",[]):builds.append(String(DiscoverySystem.discovery_definition(String(requirement)).get("name",requirement)))
	if not builds.is_empty():chosen.facts.append(["Builds on",builds[0]+(" +%d" % (builds.size()-1) if builds.size()>1 else ""),", ".join(builds)])
	if not known and not (row.get("missing",[]) as Array).is_empty() and status=="LOCKED":chosen.facts.append(["Waits for","%d condition%s" % [(row.missing as Array).size(),"" if (row.missing as Array).size()==1 else "s"],"\n".join(PackedStringArray(row.missing))])
	if not known and float(row.get("years_ahead",0.0))>=1.0:
		var factor:=DiscoverySystem.research_early_factor(row)
		chosen.facts.append(["Price","%s the work" % preload("res://scripts/hud/inquiry_board.gd")._times(factor),"Dated %d years after the age our learning has reached. Work on it goes slower in proportion; as our learning catches up its price falls." % roundi(float(row.years_ahead))])
	# Who leads its line, and how their skills set its pace (office_levers.research_pace).
	if not known:
		var assignment:Dictionary=DiscoverySystem.research_assignment(row)
		var leader:Dictionary=assignment.get("leader",{}) if assignment.get("leader") is Dictionary else {}
		if not leader.is_empty():
			chosen.facts.append(["Led by","nobody" if bool(leader.get("vacant",false)) else String(leader.get("name","")),("The office of %s is empty. " % String(leader.get("requested_office",leader.get("office",""))).to_lower() if bool(leader.get("vacant",false)) else "%s, %s. " % [String(leader.get("name","")),String(leader.get("office",""))])+leader_line(leader)])
	var opens:Array=row.get("leads_to",[])
	if not opens.is_empty():chosen.facts.append(["Opens","%d question%s" % [opens.size(),"" if opens.size()==1 else "s"],", ".join(PackedStringArray(opens))])
	if bool(row.get("ready",false)) and status!="RESEARCHING":
		chosen.on_research=_research_technology.bind(id)
		chosen.research_label="Put a team on it"
	return chosen

## The leader's own skills in what a line needs, and how much faster (or
## slower) it goes under them than under an ordinary holder of the office
## (office_levers.research_pace: the engine's own execution).
static func leader_line(leader:Dictionary)->String:
	var needs:Array=leader.get("skills",[])
	var office:=String(leader.get("office",""))
	if bool(leader.get("vacant",false)):
		var empty:=preload("res://scripts/office_levers.gd").research_pace({},office,needs)
		return "Needs %s. With nobody to lead it, it goes %d%% slower than under an ordinary %s." % [", ".join(PackedStringArray(needs)).to_lower(),roundi(absf(1.0-empty)*100.0),String(leader.get("requested_office",office)).to_lower()]
	var person:Dictionary=GovernmentPeopleSystem.person_snapshot(int(leader.get("person_id",0)))
	if person.is_empty():return "Needs %s." % ", ".join(PackedStringArray(needs)).to_lower()
	var theirs:PackedStringArray=PackedStringArray()
	for skill in needs:theirs.append("%s %d" % [String(skill).to_lower(),roundi(GovernmentPeopleSystem.skill_value(person,String(skill)))])
	var pace:=preload("res://scripts/office_levers.gd").research_pace(person,office,needs)
	var pct:=roundi(absf(pace-1.0)*100.0)
	var given:=String(person.get("name","")).get_slice(" ",0)
	var speed:="as fast as under an ordinary leader" if pct==0 else "%d%% %s than under an ordinary leader" % [pct,"faster" if pace>=1.0 else "slower"]
	return "%s's %s: this line goes %s." % [given,", ".join(theirs),speed]

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

## The knowledge tree is drawn in the dock (knowledge_tree_board.gd); no tab
## opens a screen of its own.
func open_expanded_tab(_sub:int)->bool:
	return false

## Shows a question on the knowledge tree: its field, with it chosen.
## Opens the knowledge tree on a field (the War page's security practices).
func open_domain(domain:String)->void:
	tree_domain=domain
	tree_selected=""
	hud.open_dock("inquiry",1,false)

func show_question(id:String)->void:
	var domain:=String(DiscoverySystem.discovery_definition(id).get("dynamic",""))
	if domain!="":tree_domain=domain
	tree_selected=id

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
	# Only what is not nothing: "3 waiting · 56 studied".
	var bits:Array[String]=[]
	if int(summary.unstudied_count)>0:bits.append("%d waiting" % int(summary.unstudied_count))
	if int(summary.in_study_count)>0:bits.append("%d in study" % int(summary.in_study_count))
	bits.append("%d studied" % int(summary.studied_count))
	var words:=" · ".join(bits)
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

func _change_artifact_study(delta:int)->void:
	ArtifactCulture.change_study_weight(delta)
	hud.request_immediate_dock_refresh()
