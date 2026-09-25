extends Node
## Dev tool: which (action x situation) cells of the court-known persons engine
## still speak only from the deterministic banks, because no live exchange has
## taught them a template yet (court_persons_bridge.gd, interaction database).
##
##   <godot> --headless --path <worktree> res://tools/court_persons_coverage.tscn
##
## Report mode (default) reads the player's interaction database and prints
## the table; it never contacts the API.
## Batch "prompt-farm" mode fills empty cells by running scripted scenarios
## against the live model. It is OFF unless COURT_FARM=1, needs a configured
## API key (never printed), prints a cost estimate first, and only spends when
## COURT_FARM_CONFIRM=1 is also set. COURT_FARM_MAX_CALLS caps the calls
## (default 10, hard cap 40); COURT_FARM_PRICE_IN / COURT_FARM_PRICE_OUT are the
## per-million-token prices used for the estimate.

const Bridge:=preload("res://scripts/court_persons_bridge.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Store:=preload("res://scripts/interaction_store.gd")
const HARD_CAP:=40
const EST_PROMPT_TOKENS:=3900
const EST_COMPLETION_TOKENS:=380
const PHRASES:={"ask_blame":"Who is responsible for this?","ask_about":"Tell me of the oldest woman alive.","q_where":"Where were you when it happened?",
	"q_did":"Did you do this?","q_swear":"Swear it before me.","q_who_else":"Who else knows of this?","q_mercy":"Tell me the truth and I will be merciful.",
	"q_threaten":"Tell me the truth or I will have you put to death.","accuse_lie":"You are lying to me.","exalt":"I raise you up before the whole court.",
	"pardon":"I pardon you.","curse":"I curse you before this court.","make_example":"Make an example of this one."}

func _ready()->void:
	var rows:=Bridge.coverage()
	var empty:Array=[]
	print("COURT_PERSONS COVERAGE (%d learned court records in the interaction database)" % _court_records())
	print("%-14s %-9s %-20s %-5s %-5s %s" % ["action","role","beat","guilt","lie","templates"])
	for r in rows:
		print("%-14s %-9s %-20s %-5s %-5s %d" % [String(r.action),String(r.role),String(r.beat),String(r.g),String(r.l),int(r.templates)])
		if int(r.templates)==0: empty.append(r)
	print("%d of %d cells have no learned template." % [empty.size(),rows.size()])
	if OS.get_environment("COURT_FARM")!="1":
		print("Batch mode is off (set COURT_FARM=1 to estimate, and COURT_FARM_CONFIRM=1 to spend).")
		get_tree().quit(0); return
	var config:Dictionary=PronouncementInterpreter._api_config()
	if config.is_empty():
		print("Batch mode needs a configured API key; none is configured. Nothing was sent.")
		get_tree().quit(0); return
	var cap:=clampi(int(OS.get_environment("COURT_FARM_MAX_CALLS")) if OS.get_environment("COURT_FARM_MAX_CALLS")!="" else 10,1,HARD_CAP)
	var calls:=mini(cap,empty.size())
	var price_in:=float(OS.get_environment("COURT_FARM_PRICE_IN")) if OS.get_environment("COURT_FARM_PRICE_IN")!="" else 0.4
	var price_out:=float(OS.get_environment("COURT_FARM_PRICE_OUT")) if OS.get_environment("COURT_FARM_PRICE_OUT")!="" else 1.6
	var cost:=float(calls)*(float(EST_PROMPT_TOKENS)*price_in+float(EST_COMPLETION_TOKENS)*price_out)/1000000.0
	print("Estimate: %d calls x ~%d prompt + ~%d completion tokens = ~%d tokens, about $%.4f at $%.2f/$%.2f per million (model %s)." % [calls,EST_PROMPT_TOKENS,EST_COMPLETION_TOKENS,calls*(EST_PROMPT_TOKENS+EST_COMPLETION_TOKENS),cost,price_in,price_out,String(config.get("model",""))])
	if OS.get_environment("COURT_FARM_CONFIRM")!="1":
		print("Not spending: set COURT_FARM_CONFIRM=1 to run these calls.")
		get_tree().quit(0); return
	await _farm(empty.slice(0,calls))
	get_tree().quit(0)

func _court_records()->int:
	var n:=0
	for r in Store.records():
		if String((r as Dictionary).get("surface",""))==Bridge.SURFACE: n+=1
	return n

func _farm(cells:Array)->void:
	## Scripted scenarios: a world, an event, the situation each cell needs
	## (forced guilt and lie), then one typed line through the live voice.
	var probe:Node=load("res://tests/audience_modal_probe.gd").new()
	probe._setup_world()
	probe.free()
	GameState.ensure_population_total(600)
	GovernmentPeopleSystem.initialize()
	var director:Node=load("res://scripts/audience_director.gd").new()
	add_child(director)
	await get_tree().process_frame
	var spent:=0
	for cell in cells:
		var c:Dictionary=cell
		var liar:=String(c.l)=="l"
		Persons.force={"culprit":"holder" if liar else "commoner","lie":liar}
		GameState.elapsed_days=int(GameState.elapsed_days)+3
		GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Stores Spoiled %d" % spent,"description":"The stores spoiled.","domain":"food","severity":"major"})
		var modal:Control=director.open_court({})
		await get_tree().process_frame
		var ask:Dictionary={}
		for ch in modal.persons_choices():
			if String(ch.action)=="ask_blame": ask=ch; break
		if ask.is_empty(): continue
		modal.persons_choose(ask)
		if String(c.role)=="commoner":
			for ch2 in modal.persons_choices():
				if String(ch2.action)=="summon": modal.persons_choose(ch2); break
			var p:=Persons.speaker_known(modal.audience_id)
			if String(c.g)=="g" and not p.is_empty(): Persons.record(String(Hall.find(modal.audience_id).get("record_id","")))["true_party"]=Persons.ref_of(p)
		var before:=Store.size()
		director.voice.persons_turn(modal.audience_id,String(PHRASES.get(String(c.action),"Speak.")))
		spent+=1
		var waited:=0.0
		while director.voice.busy(modal.audience_id) and waited<60.0:
			await get_tree().process_frame; waited+=get_process_delta_time()
		print("farmed %s/%s/%s: %s" % [String(c.action),String(c.beat),String(c.g),"learned" if Store.size()>before else "no template"])
		modal._close()
		await get_tree().process_frame
	Persons.force={}
	print("Spent %d calls." % spent)
