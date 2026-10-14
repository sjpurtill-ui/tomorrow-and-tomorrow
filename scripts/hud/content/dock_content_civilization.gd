extends "res://scripts/hud/content/dock_content_base.gd"
## CIVILIZATION section: society and civic dialogue. Officials, their offices
## and standing orders live in the court (court_office_dossier.gd).

var culture_view_state:Dictionary={"roots_open":false}
## Tests may point the showcase at a stand-in facade; play uses artifact_culture.gd.
var artifact_source:Variant=null
const ArtifactGallery:=preload("res://scripts/hud/artifact_gallery.gd")

const DYNAMIC_ORDER:Array[String]=["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
const ValuesModel:=preload("res://scripts/societal_values_model.gd")
const Civic:=preload("res://scripts/hud/court_civic.gd")
const CourtDirector:=preload("res://scripts/audience_director.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const CapacityHistory:=preload("res://scripts/capacity_history.gd")
const CapacityWords:=preload("res://scripts/hud/capacity_words.gd")

func meta()->Dictionary:
	return {
		"eyebrow":"What our ways do",
		"title":"Culture",
		"subtabs":["Culture","Council"],
	}

func tab(sub:int)->Dictionary:
	if sub==1:return {"blocks":_council_blocks()}
	return {"blocks":_society_overview()}

func _society_blocks(capacities:Dictionary)->Array:
	var items:Array=[]
	for domain in DYNAMIC_ORDER:
		var value:=clampf(float(capacities.get(domain,0.0)),0.0,1.0)*100.0
		# Each row carries its last years and the change since last year, and
		# opens its history: how it moved and why (capacity_history.gd).
		var change:=CapacityHistory.change_over(domain,365)
		var points:=float(change.points)
		var since:=("since last winter" if EraWords.hearth() else "since last year") if bool(change.full) else "since %s" % EraWords.when(int(change.since))
		var steady:=absf(points)<0.05
		var definition:=String(terrain._dynamic_definition(domain)) if is_instance_valid(terrain) and terrain.has_method("_dynamic_definition") else ""
		var moved:=("Steady %s." % since) if steady else ("%s %s %s %s." % ["Up" if points>0.0 else "Down",CapacityWords.amount(points),"point" if CapacityWords.amount(points)=="1" else "points",since])
		items.append({"id":domain,"name":String(domain).capitalize(),"pct":value,"trend":"—",
			"history":CapacityHistory.sparkline(domain,120),
			"change_text":"steady" if steady else CapacityWords.points(points),
			"change_color":Tokens.MUTED if steady else (Tokens.GREEN_TEXT if points>0.0 else Tokens.RED_TEXT),
			"tip":"%s\n\n%s Click to see how it changed and why." % [definition,moved] if definition!="" else "%s Click to see how it changed and why." % moved,
			"on_press":_open_capacity.bind(domain)})
	items.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.pct)<float(b.pct))
	var identity:Dictionary=ValuesModel.identity_snapshot(GameState.societal_values)
	var identity_text:="%s · %s." % [String(identity.get("name","Forming order")).capitalize(),String(identity.get("summary","still forming")).to_lower()]
	return [
		{"type":"caps","heading":"TWELVE CAPACITIES","note":"weakest first · click one to see why","columns":1,"items":items},
		{"type":"text","heading":"VALUES & IDENTITY","text":identity_text+" Values shift slowly with lived conditions, not by decree."},
	]

## Opens one capacity's history: its line over the years, why it grew or fell,
## and what it is made of now.
func _open_capacity(domain:String)->void:
	if hud==null or not hud.has_method("open_detail"): return
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_capacity.gd").new(terrain,hud,domain))

func signature()->Array:
	var ids:Array=[]
	for item_variant in GameState.council_inbox:
		var item:Dictionary=item_variant
		ids.append(String(item.get("id",""))+String(item.get("status","")))
	var settlement:=_civic_settlement()
	var history:=AdvisorSystem.civic_dialogue_history(String(settlement.get("id","")),6)
	var latest_dialogue_status:=String(history.back().get("status","")) if not history.is_empty() else ""
	var latest_order:=_latest_civic_order(String(settlement.get("id","")),leader_person_id(String(settlement.get("id",""))))
	return [GameState.elapsed_days,WorldSimulation.direction.auto_scouting,MilitaryCampaign.war_reputation_snapshot(),GameState.societal_values.get("lived",{}).duplicate(),WorldSimulation.direction.ambition,WorldSimulation.direction.cultural_memory.get("events",[]).size(),GameState.society_capacities.duplicate(),ids,GameState.sovereign_orders.size(),ConsequenceEngine.active_policies().size(),GovernmentPeopleSystem.revision,GameState.player_settlements.size(),history.size(),latest_dialogue_status,String(latest_order.get("status","")),_artifact_signature()]


## The local leader's person id as GovernmentPeopleSystem.settlement_leader()
## gives it (0 when the place has no living leader record), read without
## copying the whole record. tests/test_dock_content_cache.gd holds the two
## equal.
static func leader_person_id(settlement_id:String)->int:
	for settlement:Dictionary in WorldSimulation.state.player_settlements:
		if String(settlement.get("id",""))!=settlement_id:continue
		var pid:=int(settlement.get("leader_person_id",0))
		for person:Dictionary in GovernmentPeopleSystem.people:
			if int(person.get("person_id",0))==pid:return pid
		return 0
	return 0

func _civic_settlement()->Dictionary:
	var settlement:=SettlementModel.selected_settlement_snapshot()
	if not settlement.is_empty(): return settlement
	return GameState.player_settlements[0] if not GameState.player_settlements.is_empty() else {}


func _latest_civic_order(settlement_id:String,leader_person_id:int)->Dictionary:
	return Civic.latest_order(settlement_id,leader_person_id)

func _society_overview()->Array:
	## What our culture does, in the engine's numbers (hud/culture_model.gd,
	## drawn by hud/culture_panel.gd).
	return [{"type":"culture","culture":preload("res://scripts/hud/culture_model.gd").snapshot(),"lived_values":GameState.societal_values.get("lived",{}).duplicate(),
		"on_direction":func():PeopleDirection.open_direction(),"on_council":_open_court.bind({"settlement_id":String(_civic_settlement().get("id",""))}),
		"on_capacities":focused_action("Society’s strengths & needs","",func()->Dictionary:return {"blocks":_society_blocks(GameState.society_capacities)}).on_press}.merged(_artifact_showcase())]

func _artifact_facade()->Variant:
	return artifact_source if artifact_source!=null else ArtifactGallery.facade()

func _artifact_showcase()->Dictionary:
	## Entry point to Artifacts & Allure inside the Culture tab.
	var facade:Variant=_artifact_facade()
	if facade==null:return {}
	var summary:Dictionary=facade.summary()
	var finest:Dictionary=facade.artifacts({"status":"all","sort":"prestige","search":"","page":0,"page_size":4})
	var source:Variant=artifact_source
	return {"artifacts":{"summary":summary,"highlights":finest.get("items",[]),
		"on_open":func(id:String="")->void:ArtifactGallery.open(hud,terrain,id,source),
		"on_study":jump("inquiry",0)}}

func _artifact_signature()->Array:
	var facade:Variant=_artifact_facade()
	if facade==null:return []
	var summary:Dictionary=facade.summary()
	return [summary.get("collection_count",0),summary.get("studied_count",0),summary.get("in_study_count",0),summary.get("exhibited_count",0),snappedf(float(summary.get("allure",0)),.01),snappedf(float(summary.get("study_role",{}).get("researchers",0.0)),.1)]

## THE COUNCIL, as it stands: everyone the god may call to court, each one
## line with the one live fact about them (matters they would raise, or how
## they regard the god) and a Summon beside it; then the orders still open,
## each with its state. Nothing for what is switched off (the council's own
## proposals): no box that only leads somewhere else.
func _council_blocks()->Array:
	var Roster:=preload("res://scripts/hud/court_roster.gd")
	var Tracker:=preload("res://scripts/order_tracker.gd")
	var Stack:=preload("res://scripts/hud/order_stack.gd")
	var Posts:=preload("res://scripts/person_posts.gd")
	var Portrait:=preload("res://scripts/hud/person_portrait.gd")
	var commands:=Posts.commands_now()
	# Grouped by office, each with their face, their full title and where
	# they are now (person_posts.gd: the same words Home and War use).
	var office_order:=["council","settlement","war","scouts","builders","gifted"]
	var heads:={"council":"Officials","settlement":"Town leaders","war":"War leaders","scouts":"Scouts","builders":"Master builders","gifted":"The gifted"}
	var rows:Array=[]
	for person:Dictionary in Roster.people():
		if String(person.get("group","")) in ["prisoners","won_over","folk"]:continue
		var post:=Posts.of(person,commands)
		var matters:=int(person.get("matters",0))
		var regard:Dictionary=person.get("regard",{}) if person.get("regard") is Dictionary else {}
		var fact:="%d %s to raise" % [matters,"matter" if matters==1 else "matters"] if matters>0 else String(regard.get("read",""))
		var target:Dictionary=person.get("target",{})
		var face:Dictionary=(person.get("person",{}) as Dictionary).duplicate()
		if int(face.get("person_id",0))<=0:
			var key:=String(target.get("figure_id","")) if String(target.get("figure_id",""))!="" else String(person.name)
			face["person_id"]=absi(key.hash())%997+1
		var group:=String(post.group) if heads.has(String(post.group)) else "council"
		rows.append({"group":heads[group],"rank":office_order.find(group),"icon":Portrait.texture(face),
			"cells":{"name":String(person.name),"title":String(post.title),"place":String(post.place),"fact":fact},"tone":"",
			"tag":{"text":fact,"tone":"warn"} if matters>0 else {},
			"tip":"%s, %s. %s. Summon them to talk, give orders or replace them." % [String(person.name),String(post.title),String(post.place)],
			"button":{"label":"Summon","on_press":_open_court.bind(target),"tip":"Call %s to the court." % String(person.name)}})
	rows.sort_custom(func(x:Dictionary,y:Dictionary)->bool:return int(x.rank)<int(y.rank))
	for row:Dictionary in rows:
		row.erase("rank")
		# A matter to raise is a tag; regard is the plain last column.
		if (row.tag as Dictionary).is_empty():row.erase("tag")
		else:(row.cells as Dictionary)["fact"]=""
	var blocks:Array=[]
	if rows.is_empty():blocks.append({"type":"text","text":"No one holds an office yet. The government will appoint someone as soon as they can."})
	else:blocks.append({"type":"table","heading":"THE COURT","icon_size":26,"rows":rows,
		"columns":[{"key":"name","label":"Name"},{"key":"title","label":"Office"},{"key":"place","label":"Where now"},{"key":"fact","label":"Regard"}]})
	var open:Array=[]
	for order_variant in Tracker.orders():
		var order:Dictionary=order_variant
		var state:=String(order.get("state","accepted"))
		if state in ["done","refused","called_off"]:continue
		open.append({"label":String(order.get("words","")),"value":String(Stack.STATE_WORDS.get(state,state)),"tone":"bad" if state in ["stalled","nothing"] else "",
			"tip":Stack.status_words(order),"on_click":_open_court.bind({})})
		if open.size()>=12:break
	if not open.is_empty():blocks.append({"type":"fact_grid","heading":"ORDERS STILL OPEN","items":open,"min_column":300})
	return blocks

## Every talk, order and decision opens the court, focused on that person.
func _open_court(focus:Dictionary)->void:
	if CourtDirector.open_court_for(focus): return
	var director:Node=terrain.find_child("AudienceDirector",true,false) if is_instance_valid(terrain) else null
	if director!=null and director.has_method("open_court"):director.call("open_court",focus)