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

func _council_all_blocks()->Array:
	var blocks:Array=[]
	var settlement:=_civic_settlement()
	var settlement_id:=String(settlement.get("id",""))
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var disposition:=GovernmentPeopleSystem.leader_disposition(leader)
	var history:=AdvisorSystem.civic_dialogue_history(settlement_id,6)
	var latest_order:=_latest_civic_order(settlement_id,int(leader.get("person_id",0)))
	var latest_state:=_directive_state(latest_order)
	if not leader.is_empty():
		# The conversation itself happens in the court; here, a quiet summary.
		var last_words:=""
		for turn in history:
			if String(turn.get("speaker",""))=="player": continue
			last_words=String(turn.get("text",""))
			if "\n\nSTATE ·" in last_words: last_words=last_words.split("\n\nSTATE ·")[0]
		var status_text:=_pronouncement_status_text(settlement_id,int(leader.get("person_id",0)))
		blocks.append({"type":"rows","heading":"YOUR LOCAL LEADER","note":"speak with them in the court","items":[{
			"name":"%s · %s" % [String(leader.get("name","the appointed leader")),String(leader.get("title","local leader"))],
			"sub":status_text if not status_text.is_empty() else "%s, %s. Nothing you asked is still open." % [String(settlement.get("name","this settlement")),String(disposition.get("label","pragmatic")).to_lower()],
			"detail":("Last said: “%s”" % last_words.substr(0,220)) if not last_words.is_empty() else "",
			"value":"Summon","value_color":Tokens.GOLD_TEXT,"accent":_directive_state_color(latest_state),
			"on_click":_open_court.bind({"settlement_id":settlement_id}),"tip":"Call them to the court to talk, give orders, or replace them.",
		}]})
	if leader.is_empty():
		blocks.append({"type":"text","heading":"NO LOCAL LEADER","text":"No one fit to lead is free just now. The government will appoint someone as soon as they can."})
	var combat_reports:Array=[]
	for item in GameState.council_inbox:
		var item_id:=String(item.get("id",""))
		if not item_id.begins_with("battle_") and not item_id.begins_with("threat_"): continue
		combat_reports.append({"name":"A battle was fought" if item_id.begins_with("battle_") else "A force is coming","detail":String(item.get("text","")),"sub":"%s · %s" % [EraWords.ago(int(item.get("day",0))).capitalize(),String(item.get("office","Military command"))],"value":"Read","accent":Tokens.RED,"on_click":terrain._open_war_planning,"tip":"Read what your generals know and what they intend."})
		if combat_reports.size()>=6: break
	if not combat_reports.is_empty():
		blocks.append({"type":"rows","heading":"MILITARY ALERTS & BATTLE REPORTS","note":"war news","items":combat_reports})
	var decisions:Array=AdvisorSystem.council_decision_items(6)
	var shown:=0
	for item_variant in decisions:
		var item:Dictionary=item_variant
		if String(item.get("status","unread"))!="unread": continue
		if shown>=3: break
		shown+=1
		blocks.append({"type":"rows","heading":"DECISION · %s" % String(item.get("office","Council")).to_upper(),"note":EraWords.ago(int(item.get("day",0))),"items":[{
			"name":String(item.get("text","Council item")).split("\n")[0],
			"sub":String(item.get("advisor","")),
			"value":"","accent":Tokens.RED if String(item.get("severity","warning")) in ["danger","critical"] else Tokens.AMBER,
			"tip":String(item.get("text","")),
		}]})
		var responses:Array=item.get("responses",[])
		var response_items:Array=[]
		for response_variant in responses:
			var response:Dictionary=response_variant
			var label:=String(response.get("label",""))
			if label=="": continue
			# Every response carries its authored consequence line; a decision the
			# player cannot price is not a decision.
			var ripple:=String(response.get("ripple",response.get("hint","")))
			var effect_id:=String(response.get("effect",""))
			var duration_days:=roundi(float(response.get("days",0.0)))
			var enacts:="Sets a standing order on %s for %s." % [effect_id.replace("_"," "),preload("res://scripts/hud/production_plain.gd").span_text(float(duration_days))] if effect_id!="" else "Sets no standing order."
			response_items.append({
				"label":label,"sub":ripple,
				"primary":effect_id!="",
					"tip":"%s\n%s" % [ripple,enacts] if ripple!="" else enacts,
			})
		# Decisions are answered in the court; the dock only lists them.
		if not response_items.is_empty():
			var choices:PackedStringArray=PackedStringArray()
			for response_item:Dictionary in response_items:choices.append(String(response_item.label).capitalize())
			blocks.append({"type":"actions","items":[{"label":"Answer in court","sub":" · ".join(choices),"primary":true,"on_press":_open_court.bind({}),"tip":"Your council awaits your word in the court."}]})
	var pending_orders:Array=[]
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("type",""))!="pronouncement": continue
		if String(order.get("status","")) in ["interpreting"]:
			pending_orders.append({
				"name":"\"%s\"" % String(order.get("parameters",{}).get("text","")).substr(0,64),
				"sub":"still being worked out · given %s" % EraWords.ago(int(order.get("issued_day",0))),
				"value":"Withdraw","value_color":Tokens.RED_TEXT,"accent":Tokens.AMBER,
				"on_click":terrain._cancel_pending_pronouncement.bind(String(order.get("id","")),String(order.get("request_id",""))),
				"tip":"Take back this order before anyone acts on it",
			})
	if not pending_orders.is_empty():
		blocks.append({"type":"rows","heading":"PENDING ORDERS","items":pending_orders})
	var merged_items:Array=AdvisorSystem.merged_report_items(6)
	if not merged_items.is_empty():
		var merged_rows:Array=[]
		for merged_variant in merged_items:
			var merged_item:Dictionary=merged_variant
			var merged_id:=String(merged_item.get("id",""))
			if merged_id.begins_with("battle_") or merged_id.begins_with("threat_"): continue
			var deferred:=String(merged_item.get("status","unread"))=="deferred"
			var occurrences:=int(merged_item.get("occurrences",1))
			merged_rows.append({
				"name":String(merged_item.get("text","Report")).split("\n")[0],
				"sub":"%s · %s%s%s" % [String(merged_item.get("office","Council")),EraWords.ago(int(merged_item.get("day",0)))," · said %d times" % occurrences if occurrences>1 else ""," · put off" if deferred else ""],
				"value":"Bring back" if deferred else "","value_color":Tokens.GOLD_TEXT,
				"accent":Tokens.AMBER if deferred else Color(0,0,0,0),
				"on_click":(_restore_deferred.bind(merged_id)) if deferred else null,
				"tip":String(merged_item.get("text",""))+("\n\nClick to put this decision back among those waiting for you." if deferred else ""),
			})
		blocks.append({"type":"rows","heading":"REPORTS","note":"%d everyday reports not shown" % AdvisorSystem.routine_report_count(),"items":merged_rows})
	return blocks


func _restore_deferred(item_id:String)->void:
	for item_variant in GameState.council_inbox:
		var item:Dictionary=item_variant
		if String(item.get("id",""))!=item_id: continue
		if String(item.get("status","unread"))=="deferred":
			item["status"]="unread"
			item["day"]=int(GameState.elapsed_days)
		break
	if hud:
		hud.dismissed_alert_ids.erase(item_id)
		hud._queue_signature="__stale__"
		hud.refresh()
		hud.live_refresh_dock()

func _pronouncement_status_text(settlement_id:String,leader_person_id:int)->String:
	return Civic.status_text(_directive_state(_latest_civic_order(settlement_id,leader_person_id)))

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


func _open_civic_leadership(settlement_id:String)->void:
	if settlement_id.is_empty(): return
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_settlement_people.gd").new(terrain,hud,settlement_id))


func _latest_civic_order(settlement_id:String,leader_person_id:int)->Dictionary:
	return Civic.latest_order(settlement_id,leader_person_id)

func _civic_order_by_id(order_id:String)->Dictionary:
	if order_id.is_empty(): return {}
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("id",""))==order_id: return order
	return {}


func _directive_state(order:Dictionary)->String:
	return Civic.state(order)

func _directive_state_color(state:String)->Color:
	return Civic.state_color(state)

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

func _government_overview()->Array:
	return [{"type":"actions","heading":"GOVERNING TOGETHER","items":[{"label":"Talk with our leader","sub":"In the court: ask, order or replace","on_press":_open_court.bind({"settlement_id":String(_civic_settlement().get("id",""))})}]}]
func _council_blocks()->Array:
	var all:=_council_all_blocks();var blocks:Array=[]
	for item:Dictionary in all:
		if String(item.get("heading",""))=="YOUR LOCAL LEADER":blocks.append(item)
	blocks.push_front({"type":"actions","items":[{"label":"Open the court","sub":"Talk with anyone, your own people or foreign rulers · F12","primary":true,"on_press":_open_court.bind({}),"tip":"Call anyone before you, receive envoys, send word abroad."}]})
	if blocks.size()==1:
		blocks.append({"type":"text","text":"No one leads here just now. The government will appoint someone as soon as they can."})
	blocks.append({"type":"actions","items":[focused_action("Decisions waiting","What your council asks you to decide",_civic_report.bind("decisions")),focused_action("Orders and reports","Orders still open and reports that came back",_civic_report.bind("reports")),focused_action("War news","Threats and battles",_civic_report.bind("military"))]})
	return blocks
func _civic_report(kind:String)->Dictionary:
	var chosen:Array=[];var section:=""
	for block:Dictionary in _council_all_blocks():
		var heading:=String(block.get("heading",""))
		if heading.begins_with("DECISION ·"):section="decisions"
		elif heading=="MILITARY ALERTS & BATTLE REPORTS":section="military"
		elif heading in ["PENDING ORDERS","REPORTS"]:section="reports"
		elif heading=="NO LOCAL LEADER" or block.get("type","")=="conversation":section=""
		if section==kind:chosen.append(block)
	if chosen.is_empty():chosen.append({"type":"text","text":"Nothing is waiting for your decision." if kind=="decisions" else "No reports are waiting."})
	return {"blocks":chosen}

## Every talk, order and decision opens the court, focused on that person.
func _open_court(focus:Dictionary)->void:
	if CourtDirector.open_court_for(focus): return
	var director:Node=terrain.find_child("AudienceDirector",true,false) if is_instance_valid(terrain) else null
	if director!=null and director.has_method("open_court"):director.call("open_court",focus)