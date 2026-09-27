extends PanelContainer
## THE GROUND SURVEY: what a left-click on land tells the ruler. A paper card
## at the right of the map: a plain title, where this is, and either the
## visual survey (ground, water, what is known nearby) or a short written
## account (uncharted ground, a foreign place, a plot inside our own town).
## The map only supplies facts; every sentence the player reads is here.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Kit:=preload("res://scripts/hud/paper_kit.gd")
const SurveyCard:=preload("res://scripts/hud/resource_survey_card.gd")

signal closed

var title_label:Label
var location_label:Label
var body:RichTextLabel
var survey:ScrollContainer
var close_button:Button

func _init()->void:
	name="GroundSurvey"
	set_meta("responsive_scroll_layout",true)
	mouse_filter=Control.MOUSE_FILTER_STOP
	theme=T.control_theme()
	add_theme_stylebox_override("panel",Kit.card_style(14.0))
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	add_child(column)
	var header:=HBoxContainer.new()
	header.add_theme_constant_override("separation",8)
	column.add_child(header)
	title_label=Kit.label(header,"Ground survey","heading",Color(0,0,0,0),false)
	title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	close_button=Kit.quiet_button(header,"Close",func()->void:closed.emit(),"Close the ground survey (or click the map)")
	close_button.custom_minimum_size=Vector2(64,28)
	close_button.add_theme_font_size_override("font_size",14)
	location_label=Kit.label(column,"","note",Color(0,0,0,0),false)
	location_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(HSeparator.new())
	body=RichTextLabel.new()
	body.name="GroundAccount"
	body.bbcode_enabled=true
	body.fit_content=false
	body.scroll_active=true
	body.custom_minimum_size=Vector2(0,160)
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_font_override("normal_font",T.FONT_UI)
	body.add_theme_font_override("bold_font",T.font("ui_strong"))
	body.add_theme_font_size_override("normal_font_size",14)
	body.add_theme_font_size_override("bold_font_size",14)
	body.add_theme_color_override("default_color",T.BODY)
	column.add_child(body)
	survey=SurveyCard.new()
	survey.host_panel=self
	column.add_child(survey)
	survey.visible=false
	visible=false

func place(view:Vector2)->void:
	size=Vector2(minf(380.0,view.x-40.0),minf(460.0,view.y-190.0))
	position=Vector2(view.x-size.x-20.0,104.0)

## Written account. `account` is bbcode built by the report helpers below.
func show_account(title:String,where:String,account:String)->void:
	title_label.text=title
	location_label.text=where
	body.text=account
	body.visible=true
	survey.visible=false
	visible=true

## Visual survey of open ground.
func show_ground(title:String,where:String,entries:Array,surface:Dictionary,advice:Dictionary)->void:
	title_label.text=title
	location_label.text=where
	body.visible=false
	survey.visible=true
	survey.show_survey(entries,surface,advice)
	visible=true

# ------------------------------------------------------------------ words

static func _ink(color:Color)->String:
	return "#"+Kit.text_color(color).to_html(false)

static func _heading(text:String)->String:
	return "[font_size=16][color=%s][b]%s[/b][/color][/font_size]\n" % [_ink(T.INK),text]

static func _note(text:String)->String:
	return "[color=%s]%s[/color]" % [_ink(T.INK_MUTED),text]

## Where the click was, in one short phrase.
static func where_words(context:Dictionary)->String:
	match String(context.get("kind","")):
		"uncharted":return "Beyond what our people have seen"
		"foreign_settlement":return "Where %s live" % String(context.get("name","strangers"))
		"encounter":return "Where we met %s" % String(context.get("name","strangers"))
		"convoy":return "Where the travellers are camped"
		"inside":return "Inside %s, %.1f km from its hearth" % [String(context.get("name","our town")),float(context.get("km",0.0))]
		"beyond_border":return "%.1f km beyond %s" % [float(context.get("km",0.0)),String(context.get("name","our town"))]
		"from_convoy":return "%.1f km from the travellers" % float(context.get("km",0.0))
		"from_site":return "%.1f km from our first hearth" % float(context.get("km",0.0))
		"site":return "Our first hearth"
	return ""

static func uncharted(site_committed:bool)->String:
	var next:="Send scouts this way; when they come home and tell of it, this ground joins the map." if site_committed else "Walk the travellers here, or send scouts this way. Ground joins the map once someone has seen it and come back."
	return _heading("Nobody has seen this ground")+"No one who has come home has walked here, so its land, water and people are unknown.\n\n"+next

static func foreign_settlement(name:String,source:String,observed_day:int)->String:
	return _heading(name)+"We know where they live from %s. We last saw the place ourselves in %s.\n\n%s" % [source if source!="" else "a returned report",Kit.when(observed_day).to_lower(),"To learn how many live there now and how well they guard it, ask the chief scout in court to send watchers."]

static func encounter(name:String,day:int,how:String)->String:
	return _heading("We met %s here" % name)+"First met in %s. %s.\n\n%s" % [Kit.when(day).to_lower(),how if how!="" else "The telling does not say how",_note("This is where we met them, not where they live.")]

static func inside_border(name:String,area_km2:float,people:String)->String:
	return _heading("Land of %s" % name)+"This ground lies inside %s. The town holds about %.1f km² and %s people live there.\n\nThe border grows as the town grows: more people, more fields and paths, and the strength to hold it.\n\n%s" % [name,area_km2,people,_note("Nothing beyond the ground's own cover has been found here yet.")]

static func unsurveyed()->String:
	return _heading("What can be seen")+"Trees, soil and bare stone show on the surface. Surveyors learn how good they are, how much can be taken and where the hidden seams lie."

static func river_channel()->String:
	return _heading("River channel")+"Water runs here. Look at the dry banks beside it for trees and soil. Whether people can drink from it depends on how far they carry it and how they store it.\n\n"

static func surface(label:String,cover:float,stone:String,soil:String,fiber:String)->String:
	var wood:="Thick woodland" if cover>=0.60 else ("Open woodland" if cover>=0.25 else ("A few scattered trees" if cover>=0.08 else "Hardly any trees"))
	return _heading(label.capitalize())+"%s, about %d%% tree cover. Those trees can be cut for timber if there are hands and tools to spare.\n\nSurface stone: %s. Soil: %s. Fibre plants: %s.\n\n" % [wood,roundi(cover*100.0),stone,soil,fiber]

static func water_advice(advice:Dictionary)->String:
	var text:="[color=%s][b]%s[/b][/color]\n%s\n%s\n\n" % [_ink(advice.get("color",T.TEAL)),Kit.sentence(String(advice.get("title",""))),String(advice.get("source_text","No confirmed drinking water")),String(advice.get("reason",""))]
	var neighbors:Dictionary=advice.get("neighbors",{})
	if not neighbors.is_empty():
		text+="[b]%s[/b]\n%s\n\n" % [Kit.sentence(String(neighbors.get("title",""))),String(neighbors.get("text",""))]
	return text

static func resources(entries:Array)->String:
	var text:=""
	for entry_variant in entries:
		var entry:Dictionary=entry_variant
		var workable:=bool(entry.get("retrievable",false))
		var surveyed:=String(entry.get("knowledge",""))=="surveyed"
		text+="[b]%s[/b]  ·  %.1f km\n" % [ResourceSystem.display_name(String(entry.get("resource",""))),float(entry.get("distance_km",0.0))]
		var explanation:=ResourceSystem.plain_language_description(String(entry.get("resource","")))
		if explanation!="":text+=explanation+"\n"
		var state:="Workable now" if workable else ("Seen but out of reach" if surveyed else "Not yet surveyed")
		text+="[color=%s]%s[/color]" % [_ink(T.TEAL if workable else T.AMBER),state]
		var quality:=String(entry.get("quality","unknown"))
		var abundance:=String(entry.get("abundance","unknown"))
		if quality!="unknown" or abundance!="unknown":text+=" · %s quality, %s" % [quality,abundance]
		text+="\n"
		for blocker in entry.get("blockers",[]):text+=_note("• "+String(blocker).capitalize())+"\n"
		text+="\n"
	return text

## A plot inside our own town, as its builders would describe it.
static func plot(plot:Dictionary,consumed:Dictionary,events:int,operations:String)->String:
	var use:=String(plot.get("land_use","unknown")).replace("_"," ").capitalize()
	var form:=String(plot.get("form","")).replace("_"," ").to_lower()
	var status:=String(plot.get("status","unknown")).replace("_"," ")
	var status_color:=T.GREEN
	if status in ["damaged","stressed","under construction"]:status_color=T.AMBER
	elif status in ["ruin","vacant"]:status_color=T.RED
	var text:=_heading(use)
	text+="[color=%s]%s[/color]%s · condition %d%%\n" % [_ink(status_color),status.capitalize(),(" · "+form) if form!="" else "",roundi(float(plot.get("condition",0.0))*100.0)]
	var residents:=int(plot.get("resident_count",0))
	if residents>0:text+="%d of %d places lived in\n" % [residents,int(plot.get("resident_capacity",0))]
	if int(plot.get("worker_capacity",0))>0:text+="%d of %d people at work\n" % [int(plot.get("worker_count",0)),int(plot.get("worker_capacity",0))]
	if int(plot.get("storeys",1))>1:text+="%d storeys high\n" % int(plot.get("storeys",1))
	var mix:=PackedStringArray()
	var material_mix:Dictionary=plot.get("material_mix",{})
	for material_name in material_mix:
		if float(material_mix[material_name])>=0.01:mix.append("%s %d%%" % [String(material_name).to_lower(),roundi(float(material_mix[material_name])*100.0)])
	text+="Built of %s%s\n" % [String(plot.get("material_family","unknown")).to_lower(),(" ("+", ".join(mix)+")") if not mix.is_empty() else ""]
	var roof:=String(plot.get("roof_plan","")).replace("_"," ").to_lower()
	if roof!="" and roof!="unspecified":text+="Roof: %s\n" % roof
	if not consumed.is_empty():
		var parts:=PackedStringArray()
		for material_name in consumed:parts.append("%.1f %s" % [float(consumed[material_name]),String(material_name).to_lower()])
		text+="It has used %s\n" % " and ".join(parts)
	if operations!="":text+=operations
	if status=="under construction":text+="Building is %d%% done\n" % roundi(float(plot.get("construction_progress",0.0))*100.0)
	if status=="vacant":text+="Weeds and brush have taken %d%% of it back\n" % roundi(float(plot.get("reclamation",0.0))*100.0)
	text+="\n"+_note("Built %s" % Kit.when(int(plot.get("created_day",0))).to_lower())
	if int(plot.get("converted_day",-1))>=0:text+="\n"+_note("Rebuilt %s" % Kit.when(int(plot.converted_day)).to_lower())
	if int(plot.get("damaged_day",-1))>=0:text+="\n"+_note("Last damaged %s" % Kit.when(int(plot.damaged_day)).to_lower())
	if int(plot.get("abandoned_day",-1))>=0:text+="\n"+_note("Left empty %s" % Kit.when(int(plot.abandoned_day)).to_lower())
	if events>0:text+="\n"+_note("%d change%s recorded in the builders' tally" % [events,"" if events==1 else "s"])
	var cause:=String(plot.get("growth_cause","")).replace("_"," ")
	if cause!="":text+="\n\n[b]Why it is here[/b]\n%s" % cause.capitalize()
	return text
