extends Control
## People and legacies: one remarkable person and their complete record.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const P:=preload("res://scripts/hud/paper_sheet.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const ChronicleScript:=preload("res://scripts/chronicle.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
var index:=0
var displayed_person:=""
var portrait:TextureRect
var reader:ScrollContainer
var title:Label
var subtitle:Label
var body:Label
var effect:Label
var feedback:Label
var patron:Button
var person_page:Label
var previous:Button
var next:Button
var refresh_clock:=0.0

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=T.control_theme()
	var background:=ColorRect.new(); background.color=T.PAPER; background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	add_child(margin)
	var layout:=VBoxContainer.new(); layout.add_theme_constant_override("separation",16); margin.add_child(layout)
	var header:=HBoxContainer.new(); header.add_theme_constant_override("separation",8); layout.add_child(header)
	var heading:=P.label(header,"People and legacies","title",T.INK,false); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(header,"Our course",func(): WorldSimulation.direction.open_direction())
	_button(header,"Close",func(): queue_free())
	var nav:=HBoxContainer.new(); nav.add_theme_constant_override("separation",8); layout.add_child(nav)
	previous=_button(nav,"Previous person",func(): index-=1; _refresh())
	person_page=P.label(nav,"","small",T.INK_MUTED); person_page.size_flags_horizontal=Control.SIZE_EXPAND_FILL; person_page.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	next=_button(nav,"Next person",func(): index+=1; _refresh())
	reader=ScrollContainer.new();reader.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;reader.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(reader)
	var record:=VBoxContainer.new();record.size_flags_horizontal=Control.SIZE_EXPAND_FILL;record.add_theme_constant_override("separation",20);reader.add_child(record)
	var hero:=HBoxContainer.new();hero.add_theme_constant_override("separation",24);record.add_child(hero)
	portrait=Portrait.picture({},112,140);portrait.visible=false;hero.add_child(portrait)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.add_theme_constant_override("separation",8);hero.add_child(identity)
	title=P.label(identity,"","title",T.INK)
	subtitle=P.label(identity,"","body",T.BODY)
	effect=P.label(record,"","body",T.TEAL_TEXT)
	body=P.label(record,"","voice_small",T.INK)
	var actions:=HBoxContainer.new(); layout.add_child(actions)
	patron=_button(actions,"Support their work",func():
		var result:Dictionary=WorldSimulation.figures.support(String(WorldSimulation.figures.people[index].id))
		feedback.text=String(result.get("error","Your support has changed.")); _refresh())
	patron.custom_minimum_size.x=220
	T.apply_button_style(patron,true)
	feedback=P.label(layout,"","body",T.INK)
	P.label(layout,"You can support up to three living people at once. Patronage quickens our discoveries in their field, makes a general lead better and makes a gifted person's gift a fifth stronger. Their early lives are imagined; their deeds are what happened in your game.","small",T.INK_MUTED)
	_refresh()

func _button(parent:Node,text:String,action:Callable)->Button:
	var b:=P.button(parent,text,action); b.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN; b.custom_minimum_size=Vector2(140,40); return b

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
	if roster.is_empty():
		title.text="Their stories are still beginning";subtitle.text="Remarkable people will appear as their work shapes our world.";body.text="";effect.text="";person_page.text="No recorded people yet"
		previous.disabled=true;next.disabled=true;patron.disabled=true;portrait.visible=false
		return
	index=clampi(index,0,roster.size()-1)
	var p:Dictionary=roster[index]
	if displayed_person!=String(p.id):
		displayed_person=String(p.id);reader.scroll_vertical=0
		portrait.texture=Portrait.texture(p);portrait.flip_h=Portrait.mirrored(p);portrait.visible=portrait.texture!=null
	var day:=int(WorldSimulation.state.elapsed_days) if p.status!="dead" else int(p.death_day)
	var age:=maxi(0,(day-int(p.born))/365)
	var renown:=int(p.renown)
	var standing:="Great" if renown>=60 else ("Renowned" if renown>=20 else "Rising")
	title.text=String(p.name)
	var status_words:String="died at %d" % age if p.status=="dead" else ("%s, aged %d" % [String(p.status).replace("_"," "),age])
	var fame:="Spoken of far beyond our homes." if renown>=60 else ("Known across our people. More great work could make their name last for ages." if renown>=20 else "Known to those who work beside them. Recorded work and victories will spread their name.")
	subtitle.text="%s %s · %s tradition · %s\n%s" % [standing,String(p.role).to_lower(),String(p.tradition),status_words,fame]
	var count:=0
	for other in roster:
		if other.status!="dead" and other.supported: count+=1
	person_page.text="Person %d of %d · you support %d of 3" % [index+1,roster.size(),count]
	previous.disabled=index==0; next.disabled=index==roster.size()-1
	patron.disabled=p.status!="living" and not p.supported
	patron.text="Withdraw support" if p.supported else "Support their work"
	effect.text=patronage_text(p)
	var lines:PackedStringArray=["Their early life",WorldSimulation.figures.biography(p)]
	if not p.events.is_empty():
		lines.append("Recorded deeds")
		for event:Dictionary in p.events:
			lines.append("%s. %s" % [EraWords.when(int(event.day)),String(event.text)])
	body.text="\n\n".join(lines)
