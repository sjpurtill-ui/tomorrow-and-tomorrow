extends Control
## People and legacies: one remarkable person at a time, in paper and ink.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const P:=preload("res://scripts/hud/paper_sheet.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const ChronicleScript:=preload("res://scripts/chronicle.gd")
var index:=0
var chapter:=0
var title:Label
var subtitle:Label
var body:Label
var effect:Label
var feedback:Label
var patron:Button
var page:Label
var person_page:Label
var previous:Button
var next:Button
var chapter_previous:Button
var chapter_next:Button
var refresh_clock:=0.0

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=T.control_theme()
	var background:=ColorRect.new(); background.color=T.PAPER; background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	add_child(margin)
	var layout:=VBoxContainer.new(); layout.add_theme_constant_override("separation",12); margin.add_child(layout)
	var header:=HBoxContainer.new(); header.add_theme_constant_override("separation",8); layout.add_child(header)
	var heading:=P.label(header,"People and legacies","title",T.INK,false); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(header,"Our course",func(): WorldSimulation.direction.open_direction())
	_button(header,"Close",func(): queue_free())
	P.rule(layout)
	var nav:=HBoxContainer.new(); nav.add_theme_constant_override("separation",8); layout.add_child(nav)
	previous=_button(nav,"Previous person",func(): index-=1; chapter=0; _refresh())
	person_page=P.label(nav,"","small",T.INK_MUTED); person_page.size_flags_horizontal=Control.SIZE_EXPAND_FILL; person_page.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	next=_button(nav,"Next person",func(): index+=1; chapter=0; _refresh())
	title=P.label(layout,"","title",T.INK)
	subtitle=P.label(layout,"","body",T.BODY)
	effect=P.label(layout,"","body",T.TEAL_TEXT)
	var chapter_nav:=HBoxContainer.new(); chapter_nav.add_theme_constant_override("separation",8); layout.add_child(chapter_nav)
	chapter_previous=_button(chapter_nav,"Previous page",func(): chapter-=1; _refresh())
	page=P.label(chapter_nav,"","kicker",T.INK_MUTED); page.size_flags_horizontal=Control.SIZE_EXPAND_FILL; page.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	chapter_next=_button(chapter_nav,"Next page",func(): chapter+=1; _refresh())
	body=P.label(layout,"","voice_small",T.INK); body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var actions:=HBoxContainer.new(); layout.add_child(actions)
	patron=_button(actions,"Support their work",func():
		var result:Dictionary=WorldSimulation.figures.support(String(WorldSimulation.figures.people[index].id))
		feedback.text=String(result.get("error","Your support has changed.")); _refresh())
	patron.custom_minimum_size.x=220
	feedback=P.label(layout,"","body",T.INK)
	P.label(layout,"You can support up to three living people at once. Patronage quickens our discoveries in their field, makes a general lead better and makes a gifted person's gift a fifth stronger. Their early lives are imagined; their deeds are what happened in your game.","small",T.INK_MUTED)
	_refresh()

func _button(parent:Node,text:String,action:Callable)->Button:
	var b:=P.button(parent,text,action); b.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN; b.custom_minimum_size=Vector2(140,36); return b

func _process(delta:float)->void:
	refresh_clock+=delta
	if refresh_clock>1: refresh_clock=0; _refresh()

## What this person adds and what the god's patronage does, in plain words
## with the engine's numbers (HistoricalFigures.patron_lift, living_bonus,
## legacy; a gifted person's gift and patronage, geniuses.gd).
static func patronage_text(p:Dictionary)->String:
	var figures:=WorldSimulation.figures
	var learned:=ChronicleScript.DOMAIN_NAMES.has(String(p.domain))
	var field:=field_name(String(p.domain))
	if p.status=="dead":
		return "Their life's work still quickens our discoveries in %s by %.1f in 100." % [field,float(p.legacy)*100.0] if learned else "Their name is remembered; no field of discovery goes quicker for them."
	if p.status!="living":return "They add nothing while %s." % String(p.status).replace("_"," ")
	# A gifted person's gift and what patronage does for it (geniuses.gd).
	if p.get("genius") is Dictionary:
		var Geniuses:=preload("res://scripts/geniuses.gd")
		return "%s has %s. %s" % [String(p.name).get_slice(" ",0),Geniuses.gift_words(p),Geniuses.patronage_words(figures,p)]
	var lift:=float(figures.patron_lift(p))
	var general:=" and makes them lead %d in 100 better on each skill" % roundi(lift*20.0) if String(p.role) in figures.COMMAND_ROLES else ""
	var does:="adds to their name and to what they leave behind%s; no field of discovery goes quicker for it" % general if not learned else "quickens our discoveries in %s by %d in 100 while they live%s" % [field,roundi(lift*100.0),general]
	if p.supported:return "Your patronage %s." % does
	return "Your patronage (three at most at once) would %s." % does.replace("adds ","add ").replace("quickens ","quicken ").replace(" and makes them"," and make them")

static func field_name(domain:String)->String:
	return String(ChronicleScript.DOMAIN_NAMES.get(domain,domain.replace("_"," "))).replace(" & "," and ")

func _refresh()->void:
	var roster:Array=WorldSimulation.figures.people
	if roster.is_empty(): return
	index=clampi(index,0,roster.size()-1)
	var p:Dictionary=roster[index]
	var day:=int(WorldSimulation.state.elapsed_days) if p.status!="dead" else int(p.death_day)
	var age:=maxi(0,(day-int(p.born))/365)
	var renown:=int(p.renown)
	var standing:="Great" if renown>=60 else ("Renowned" if renown>=20 else "Rising")
	title.text="%s, %s %s" % [p.name,standing.to_lower(),String(p.role).to_lower()]
	var status_words:String="died at %d" % age if p.status=="dead" else ("%s, aged %d" % [String(p.status).replace("_"," "),age])
	var fame:="Spoken of far beyond our homes." if renown>=60 else ("Known across our people. More great work could make their name last for ages." if renown>=20 else "Known to those who work beside them. Recorded work and victories will spread their name.")
	subtitle.text="%s of the %s tradition, %s.\n%s" % [T.sentence_case(String(p.role)),String(p.tradition),status_words,fame]
	var count:=0
	for other in roster:
		if other.status!="dead" and other.supported: count+=1
	person_page.text="Person %d of %d · you support %d of 3" % [index+1,roster.size(),count]
	previous.disabled=index==0; next.disabled=index==roster.size()-1
	patron.disabled=p.status!="living" and not p.supported
	patron.text="Withdraw support" if p.supported else "Support their work"
	effect.text=patronage_text(p)
	var pages:=1+ceili(float(p.events.size())/3.0)
	chapter=clampi(chapter,0,pages-1); chapter_previous.disabled=chapter==0; chapter_next.disabled=chapter==pages-1
	page.text="Their early life" if chapter==0 else "What they did · page %d of %d" % [chapter,pages-1]
	if chapter==0: body.text=WorldSimulation.figures.biography(p)
	else:
		var lines:PackedStringArray=[]
		for event:Dictionary in p.events.slice((chapter-1)*3,chapter*3):
			lines.append("%s. %s" % [EraWords.when(int(event.day)),String(event.text)])
		body.text="\n\n".join(lines)
