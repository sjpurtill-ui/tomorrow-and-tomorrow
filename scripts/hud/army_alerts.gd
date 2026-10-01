extends HBoxContainer
## HOI4's ALERTS, for our fighters: a row of small marks under the clock, at
## the map's top left. Each mark is a glyph on paper with a count beside it:
## red when men are starving, ready to break, or a feud is hot; amber for
## what wants seeing to (gear short, a band under half its men). A pointer
## over a mark lists who and how, with the same numbers the army bar and the
## Warriors screen show. Only what is known at home counts (a band far off
## counts by its runner's last word, as on the army bar). A click opens the
## page that deals with it. Nothing shows while nothing is wrong.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const Ledger:=preload("res://scripts/hud/war_ledger_model.gd")
const Rations:=preload("res://scripts/field_rations.gd")
const REFRESH_SECONDS:=1.0
## A band under this share of its full strength is under strength.
const UNDER_STRENGTH:=0.5
## A band's will under this is ready to break.
const LOW_WILL:=0.3
const RED:=Color("#a8463a")
const AMBER:=Color("#a8782a")

var clock:=REFRESH_SECONDS
var signature:=""
## For tests: the alerts last shown.
var shown:Array[Dictionary]=[]
## Bands hungry or ready to break: the red badge on the rail's Warriors
## button, which shows even while a dock covers this row (-1: not yet set).
var urgent:=-1


## How many bands are in a state that will not wait: hungry in the field or
## ready to break. Hot feuds are a state of things, not an interruption.
static func urgent_count(list:Array)->int:
	var count:=0
	for alert:Dictionary in list:
		if String(alert.id) in ["hungry","will"] and String(alert.tone)=="red": count+=int(alert.count)
	return count


## What is wrong with our fighters, worst first:
## [{id, glyph (a command glyph), or war / logistics (a war or logistics
## glyph instead), tone ("red" or "amber"), count, title, lines, page}].
## page: the Warriors page to open.
static func alerts(mc:Node=null)->Array[Dictionary]:
	var hungry:=PackedStringArray(); var breaking:=PackedStringArray(); var gear:=PackedStringArray(); var thin:=PackedStringArray()
	var broken:=false
	if mc==null: mc=MilitaryCampaign
	if mc!=null and WorldSimulation.world!=null:
		for army_variant in mc.field_armies:
			if not army_variant is Dictionary: continue
			var army:Dictionary=army_variant
			if int(army.get("troops",0))<=0 or bool(army.get("embarked",false)): continue
			var card:=BarModel.army_card(mc,army)
			if bool(card.get("unknown",false)): continue
			var title:=String(card.title)
			# Hunger is known at home the day it starts (the war leader sends
			# word, court_war_orders), however far off the band is.
			if Rations.is_hungry(army) or String(card.supply_state)=="starving":
				hungry.append("%s · %d%% fed" % [title,roundi(float(card.supply)*100.0)])
			if float(card.will)<LOW_WILL:
				breaking.append("%s · will %d%%" % [title,roundi(float(card.will)*100.0)])
				if float(card.will)<ArmyMarks.BROKEN_MORALE: broken=true
			var kit:Dictionary=card.get("gear_detail",{})
			if float(card.gear)<0.999 and int(kit.get("required",0))>0:
				gear.append("%s · %d of %d armed" % [title,int(kit.get("issued",0)),int(kit.get("required",0))])
			if float(card.men)<float(card.full)*UNDER_STRENGTH:
				thin.append("%s · %d of %d men" % [title,int(card.men),int(card.full)])
	var hot:=PackedStringArray()
	for e:Dictionary in Ledger.entries():
		if String(e.kind)!="ended" and bool(e.get("hot",false)): hot.append("%s · %s" % [String(e.name),Ledger.subtitle(e)])
	var out:Array[Dictionary]=[]
	if not hungry.is_empty(): out.append({"id":"hungry","logistics":"hungry","tone":"red","count":hungry.size(),"title":"Hungry in the field","lines":hungry,"page":"support"})
	if not breaking.is_empty(): out.append({"id":"will","glyph":"will","tone":"red" if broken else "amber","count":breaking.size(),"title":"Ready to break","lines":breaking,"page":"forces"})
	if not hot.is_empty(): out.append({"id":"feud","war":"feud","tone":"red","count":hot.size(),"title":"Hot feuds","lines":hot,"page":"wars"})
	if not gear.is_empty(): out.append({"id":"gear","glyph":"gear","tone":"amber","count":gear.size(),"title":"Short of gear","lines":gear,"page":"support"})
	if not thin.is_empty(): out.append({"id":"men","glyph":"men","tone":"amber","count":thin.size(),"title":"Under strength","lines":thin,"page":"recruitment"})
	return out


## The pointer's words: the title, then one line per band or people, then
## where a click goes.
static func tip(alert:Dictionary)->String:
	var page:="the War screen"
	return "%s\n%s\nClick to open %s." % [String(alert.title),"\n".join(alert.lines as PackedStringArray),page]


func _ready()->void:
	name="ArmyAlerts"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation",6)


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS: return
	clock=0.0
	refresh()


func refresh()->void:
	var next:=alerts()
	var pressing:=urgent_count(next)
	if pressing!=urgent:
		urgent=pressing
		var hud:=get_parent()
		if hud!=null and hud.has_method("_set_badge"): hud.call("_set_badge","military",str(pressing) if pressing>0 else "",T.RED)
	var words:=str(next)
	if words==signature: return
	signature=words
	shown=next
	for child in get_children(): remove_child(child);child.queue_free()
	for alert:Dictionary in next:
		var mark:=AlertMark.new()
		mark.setup(alert)
		add_child(mark)


## One alert: a glyph on a paper tile rimmed in its tone, its count on a tab.
class AlertMark extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Icons:=preload("res://scripts/resource_icons.gd")
	const RED:=Color("#a8463a")
	const AMBER:=Color("#a8782a")
	var alert:Dictionary={}
	var texture:Texture2D
	var hover:=false

	func setup(next:Dictionary)->void:
		alert=next
		var tone:=RED if String(next.tone)=="red" else AMBER
		if next.has("war"): texture=Icons.war_texture(String(next.war),tone,64)
		elif next.has("logistics"): texture=Icons.logistics_texture(String(next.logistics),tone.darkened(0.15),64)
		else: texture=Icons.command_texture(String(next.glyph),tone.darkened(0.15),64)
		name="Alert_%s" % String(next.id)
		tooltip_text=preload("res://scripts/hud/army_alerts.gd").tip(next)
		custom_minimum_size=Vector2(_width(),40)
		mouse_filter=Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func()->void: hover=true;queue_redraw())
		mouse_exited.connect(func()->void: hover=false;queue_redraw())

	func _width()->float:
		var text:=str(int(alert.get("count",0)))
		return 40.0+T.font("ui_strong").get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+10.0

	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
			MilitaryCampaign.open_roster("army",false,String(alert.get("page","forces")))
			accept_event()

	func _draw()->void:
		var tone:=RED if String(alert.get("tone",""))=="red" else AMBER
		var box:=Rect2(Vector2.ZERO,size)
		draw_rect(Rect2(box.position+Vector2(0,2),box.size),Color(0,0,0,0.18))
		draw_rect(box,T.PAPER_RAISED if not hover else T.PAPER)
		draw_rect(Rect2(box.position,Vector2(4,box.size.y)),tone)
		draw_rect(box,Color(tone,0.9),false,1.5)
		if texture: draw_texture_rect(texture,Rect2(Vector2(8,6),Vector2(28,28)),false)
		var font:=T.font("ui_strong")
		draw_string(font,Vector2(40,26),str(int(alert.get("count",0))),HORIZONTAL_ALIGNMENT_LEFT,-1,15,tone.darkened(0.25))
