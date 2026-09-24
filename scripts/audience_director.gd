extends Node
## Brings the world to the ruler: advances AudienceHall once per game day,
## summons the Audience Hall modal when it is appropriate, and otherwise shows
## a pulsing antechamber badge above the map toolbar.

const Hall:=preload("res://scripts/audience_hall.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const SimulationPause:=preload("res://scripts/hud/simulation_pause.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Works:=preload("res://scripts/great_works_audience.gd")
const CeremonyView:=preload("res://scripts/hud/great_work_ceremony.gd")
const WorksAtlas:=preload("res://scripts/hud/great_works_atlas.gd")

var terrain:Node
var voice:Node
var modal:Control
var modal_layer:CanvasLayer
var badge_layer:CanvasLayer
var badge:Button
var badge_text:Label
var last_day:=-1
var pending_summon:=""
var clock:=0.0
var _refresh_clock:=0.0
var ceremony:Control
var ceremonies_offered:Dictionary={}
var _ceremony_clock:=0.0

const GROUP:="court_director"

func _ready()->void:
	name="AudienceDirector"
	add_to_group(GROUP)
	voice=Voice.new();voice.name="AudienceVoice";add_child(voice)
	modal_layer=CanvasLayer.new();modal_layer.name="AudienceHallLayer";modal_layer.layer=85;add_child(modal_layer)
	badge_layer=CanvasLayer.new();badge_layer.name="AntechamberLayer";badge_layer.layer=4;add_child(badge_layer)
	_build_badge()
	last_day=int(GameState.elapsed_days)

func _build_badge()->void:
	badge=Button.new();badge.name="AntechamberBadge";badge.visible=false;badge.focus_mode=Control.FOCUS_NONE
	badge.custom_minimum_size=Vector2(260,40)
	var style:=Tokens.flat(Tokens.PANEL_BG_SOLID,Tokens.GOLD,2,20,0)
	style.content_margin_left=18;style.content_margin_right=18
	var hover:=style.duplicate() as StyleBoxFlat;hover.bg_color=Tokens.ACTIVE_BG
	badge.add_theme_stylebox_override("normal",style);badge.add_theme_stylebox_override("hover",hover);badge.add_theme_stylebox_override("pressed",hover)
	badge.tooltip_text="Envoys and petitioners wait in your antechamber. Receive them."
	badge.pressed.connect(open_next)
	badge_text=Tokens.make_label("",15,Tokens.GOLD_BRIGHT,.04);badge_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;badge_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	badge_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);badge_text.mouse_filter=Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_text)
	var seal:=Modal.Seal.new();seal.kind="petition";seal.tint=Tokens.GOLD;seal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	seal.position=Vector2(6,6);seal.size=Vector2(28,28);badge.add_child(seal)
	badge_layer.add_child(badge)

func _process(delta:float)->void:
	clock+=delta
	var day:=int(GameState.elapsed_days)
	if day!=last_day and _world_ready():
		var start:=last_day+1 if last_day>=0 and day>last_day else day
		last_day=day
		for step_day in range(maxi(start,day-30),day+1):
			var arrivals:Array=Hall.daily(step_day)
			if not arrivals.is_empty() and pending_summon.is_empty():pending_summon=String((arrivals[0] as Dictionary).get("id",""))
		# Great works: stage gates, hard news, pitches, outcomes, forecasts.
		var works:Array=Works.daily(day)
		if not works.is_empty() and pending_summon.is_empty():pending_summon=String((works[0] as Dictionary).get("id",""))
	elif day!=last_day:
		last_day=day
	if not pending_summon.is_empty():
		var waiting:=Hall.find(pending_summon)
		if waiting.is_empty() or String(waiting.get("status",""))!="waiting" or not bool(Hall.state().get("summon_immediately",true)):pending_summon=""
		elif can_open():
			var id:=pending_summon;pending_summon=""
			open_audience(id)
	_ceremony_clock-=delta
	if _ceremony_clock<=0.0:
		_ceremony_clock=.5
		# Ceremonies wait on the works screen; unattended ones dedicate themselves.
	_refresh_clock-=delta
	if _refresh_clock<=0.0:
		_refresh_clock=.25;_refresh_badge()
	if badge.visible:
		var pulse:=.5+.5*sin(clock*3.2)
		badge.modulate=Color(1,1,1,.82+.18*pulse)
		badge.scale=Vector2.ONE*(1.0+.025*pulse)

func _world_ready()->bool:
	if GameState.founding_focus=="":return false
	if is_instance_valid(terrain) and "capture_render_active" in terrain and bool(terrain.capture_render_active):return false
	return true

func can_open()->bool:
	if is_instance_valid(modal) or is_instance_valid(ceremony):return false
	if GameState.founding_focus=="":return false
	if is_instance_valid(terrain) and SimulationPause.blocks(terrain):return false
	if GeneralCampaign.active:return false
	if is_instance_valid(ForeignDiplomacy.panel):return false
	if is_instance_valid(terrain) and terrain.has_method("_blocking_modal_or_report_open") and terrain._blocking_modal_or_report_open():return false
	return true

func open_next()->void:
	var queue:=Hall.waiting()
	if queue.is_empty():return
	open_audience(String((queue[0] as Dictionary).get("id","")))

func open_audience(id:String)->Control:
	if id.is_empty() or Hall.find(id).is_empty():return null
	if is_instance_valid(modal):
		modal.show_audience(id);return modal
	modal=Modal.new()
	modal.terrain=terrain;modal.voice=voice;modal.audience_id=id
	modal.closed.connect(func(_id:String):_refresh_badge.call_deferred())
	modal_layer.add_child(modal)
	_refresh_badge()
	return modal

func _refresh_badge()->void:
	if not is_instance_valid(badge):return
	var count:=Hall.waiting().size() if GameState.founding_focus!="" else 0
	badge.visible=count>0 and not is_instance_valid(modal)
	if not badge.visible:return
	badge_text.text="  %d AWAIT%s AN AUDIENCE" % [count,"S" if count==1 else ""]
	var view:=badge.get_viewport().get_visible_rect().size
	var toolbar_top:=view.y-10.0-44.0
	if is_instance_valid(terrain) and "hud" in terrain and terrain.hud and "toolbar" in terrain.hud and is_instance_valid(terrain.hud.toolbar) and terrain.hud.toolbar.visible:
		toolbar_top=terrain.hud.toolbar.position.y
	badge.size=badge.custom_minimum_size
	badge.pivot_offset=badge.size*.5
	badge.position=Vector2((view.x-badge.size.x)*.5,toolbar_top-badge.size.y-12.0).round()

# --- Great works ---------------------------------------------------------------

func _offer_ceremony()->void:
	## A finished work's dedication opens once by itself; the works screen and
	## the dock can reopen it until it is dedicated.
	if not _world_ready() or not can_open():return
	for entry in Works.api_list("pending_ceremonies",["player"]):
		if not entry is Dictionary:continue
		var key:="%s/%s" % [String(entry.get("city_id","")),String(entry.get("work_id",""))]
		if ceremonies_offered.has(key):continue
		ceremonies_offered[key]=true
		open_ceremony(String(entry.get("work_id","")))
		return

func open_ceremony(work_id:String)->Control:
	for entry in Works.api_list("pending_ceremonies",["player"]):
		if not entry is Dictionary or String(entry.get("work_id",""))!=work_id:continue
		if is_instance_valid(ceremony):ceremony.get_parent().queue_free()
		ceremonies_offered["%s/%s" % [String(entry.get("city_id","")),work_id]]=true
		ceremony=CeremonyView.open(self,terrain,voice,entry)
		ceremony.closed.connect(func(_id:String)->void:_refresh_badge.call_deferred())
		return ceremony
	return null

func open_works(focus:String="")->Control:
	var host:Node=terrain.hud if is_instance_valid(terrain) and "hud" in terrain and is_instance_valid(terrain.hud) else self
	return WorksAtlas.open(host,terrain,self,focus)

## The ruler calls someone into the court: {person_id} for an official,
## {figure_id} for a master builder or war leader, {role:"chief_scout"} for the
## scouts. They are summoned in place, inside the court.
func summon(target:Dictionary)->Control:
	var court:=open_court()
	if court==null or not court.summon(target):return null
	return court

# --- The court: the one place for every dealing with your people and others ----

## Opens the court (at rest, or focused: see AudienceModal.focus). If it is
## already open, it turns to that person in place.
func open_court(focus:Dictionary={})->Control:
	if is_instance_valid(modal):
		if not focus.is_empty():modal.focus(focus)
		return modal
	modal=Modal.new()
	modal.terrain=terrain;modal.voice=voice;modal.start_focus=focus.duplicate()
	modal.from_court=true
	modal.closed.connect(func(_id:String):_refresh_badge.call_deferred())
	modal_layer.add_child(modal)
	_refresh_badge()
	return modal

func toggle_court()->void:
	if is_instance_valid(modal):modal._close()
	else:open_court()

## Word to a foreign ruler, through your envoys, inside the court.
func open_foreign(civ_id:String)->Control:
	return open_court({"civ_id":civ_id})

func court_open()->bool:
	return is_instance_valid(modal)

static func court_node()->Node:
	## The running court director, if the world has one.
	var tree:=Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group(GROUP) if tree!=null else null

static func open_court_for(focus:Dictionary)->bool:
	## Old screens call this to hand a conversation to the court.
	var director:=court_node()
	if director==null or not director.has_method("open_court"):return false
	director.call("open_court",focus)
	return true

func open_conception()->Control:
	var made:=Works.ruler_proposal()
	if made.is_empty():return null
	return open_audience(String(made.id))
