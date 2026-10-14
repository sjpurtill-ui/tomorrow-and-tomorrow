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
const DEEDS_PAGE:=6
var browsing_deeds:=false
var deeds_query:=""
var deeds_page:=0
var deed_selected:=-1
var biography_open:=false
var biography_button:Button
var deeds_toggle:Button
var deeds_search:LineEdit
var deeds_paging:HBoxContainer
var deeds_previous:Button
var deeds_next:Button
var deeds_count:Label
var deeds_split:BoxContainer
var deeds_choices:VBoxContainer
var deed_reader:VBoxContainer
var deeds_signature:=""
var content_margin:MarginContainer
var support_actions:HBoxContainer
var support_note:Label

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=T.control_theme()
	var background:=ColorRect.new(); background.color=T.PAPER; background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin=margin
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	add_child(margin)
	resized.connect(_fit_content)
	var layout:=VBoxContainer.new(); layout.add_theme_constant_override("separation",12); margin.add_child(layout)
	var header:=HBoxContainer.new(); header.add_theme_constant_override("separation",8); layout.add_child(header)
	var heading:=P.label(header,"People and legacies","title",T.INK,false);heading.add_theme_font_size_override("font_size",24);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(header,"Our course",func(): WorldSimulation.direction.open_direction())
	_button(header,"Close",func(): queue_free())
	var nav:=HBoxContainer.new(); nav.add_theme_constant_override("separation",8); layout.add_child(nav)
	previous=_button(nav,"Previous person",func(): index-=1; _refresh())
	person_page=P.label(nav,"","small",T.INK_MUTED); person_page.size_flags_horizontal=Control.SIZE_EXPAND_FILL; person_page.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	next=_button(nav,"Next person",func(): index+=1; _refresh())
	reader=ScrollContainer.new();reader.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;reader.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(reader)
	var record:=VBoxContainer.new();record.size_flags_horizontal=Control.SIZE_EXPAND_FILL;record.add_theme_constant_override("separation",12);reader.add_child(record)
	var hero:=HBoxContainer.new();hero.add_theme_constant_override("separation",24);record.add_child(hero)
	portrait=Portrait.picture({},80,100);portrait.visible=false;hero.add_child(portrait)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.add_theme_constant_override("separation",8);hero.add_child(identity)
	title=P.label(identity,"","title",T.INK);title.add_theme_font_size_override("font_size",28)
	subtitle=P.label(identity,"","body",T.BODY)
	effect=P.label(record,"","body",T.TEAL_TEXT)
	var reading_tools:=HFlowContainer.new();reading_tools.add_theme_constant_override("h_separation",10);reading_tools.add_theme_constant_override("v_separation",6);record.add_child(reading_tools)
	biography_button=_button(reading_tools,"Their early life",func()->void:biography_open=not biography_open;body.visible=biography_open)
	body=P.label(record,"","voice_small",T.INK);body.visible=false
	deeds_toggle=_button(reading_tools,"Browse recorded deeds",func()->void:browsing_deeds=not browsing_deeds;reader.scroll_vertical=0;_render_deeds());deeds_toggle.custom_minimum_size.x=240
	deeds_search=LineEdit.new();deeds_search.placeholder_text="Search this person's recorded deeds";deeds_search.clear_button_enabled=true;deeds_search.custom_minimum_size=Vector2(300,40);deeds_search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;reading_tools.add_child(deeds_search)
	deeds_search.text_changed.connect(func(text:String)->void:deeds_query=text;deeds_page=0;_render_deeds())
	deeds_paging=HBoxContainer.new();deeds_paging.add_theme_constant_override("separation",8);record.add_child(deeds_paging)
	deeds_previous=_button(deeds_paging,"Newer",func()->void:deeds_page-=1;_render_deeds())
	deeds_count=P.label(deeds_paging,"","small",T.INK_MUTED);deeds_count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;deeds_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	deeds_next=_button(deeds_paging,"Older",func()->void:deeds_page+=1;_render_deeds())
	deeds_split=BoxContainer.new();deeds_split.add_theme_constant_override("separation",20);record.add_child(deeds_split)
	deeds_choices=VBoxContainer.new();deeds_choices.custom_minimum_size.x=360;deeds_choices.add_theme_constant_override("separation",6);deeds_split.add_child(deeds_choices)
	deed_reader=VBoxContainer.new();deed_reader.size_flags_horizontal=Control.SIZE_EXPAND_FILL;deed_reader.add_theme_constant_override("separation",8);deeds_split.add_child(deed_reader)
	var actions:=HBoxContainer.new();layout.add_child(actions);support_actions=actions
	patron=_button(actions,"Support their work",func():
		var result:Dictionary=WorldSimulation.figures.support(String(WorldSimulation.figures.people[index].id))
		feedback.text=String(result.get("error","Your support has changed.")); _refresh())
	patron.custom_minimum_size.x=220
	T.apply_button_style(patron,true)
	feedback=P.label(layout,"","body",T.INK)
	support_note=P.label(layout,"You can support up to three living people at once. Patronage quickens our discoveries in their field, makes a general lead better and makes a gifted person's gift a fifth stronger. Their early lives are imagined; their deeds are what happened in your game.","small",T.INK_MUTED)
	_refresh();_fit_content()

func _fit_content()->void:
	var side:=maxi(28,int((size.x-1120.0)*0.5))
	content_margin.add_theme_constant_override("margin_left",side);content_margin.add_theme_constant_override("margin_right",side)
	if deeds_split!=null:
		deeds_split.vertical=size.x<760
		deeds_choices.custom_minimum_size.x=0 if deeds_split.vertical else 360

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
	feedback.visible=not browsing_deeds and not feedback.text.is_empty()
	var roster:Array=WorldSimulation.figures.people
	if roster.is_empty():
		title.text="Their stories are still beginning";subtitle.text="Remarkable people will appear as their work shapes our world.";body.text="";effect.text="";person_page.text="No recorded people yet"
		previous.disabled=true;next.disabled=true;patron.disabled=true;portrait.visible=false
		deeds_split.visible=false;deeds_toggle.visible=false;deeds_search.visible=false;deeds_paging.visible=false;biography_button.visible=false;deeds_signature=""
		return
	index=clampi(index,0,roster.size()-1)
	var p:Dictionary=roster[index]
	if displayed_person!=String(p.id):
		displayed_person=String(p.id);reader.scroll_vertical=0;deed_selected=-1;deeds_page=0;deeds_query="";deeds_search.text="";deeds_signature=""
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
	body.text=WorldSimulation.figures.biography(p)
	biography_button.text="Their early life "+("-" if biography_open else "+")
	var signature:=str([p.id,p.events,browsing_deeds,deeds_page,deeds_query,deed_selected])
	if signature!=deeds_signature:_render_deeds()

func deed_records()->Array:
	var records:Array=[]
	var roster:Array=WorldSimulation.figures.people
	if roster.is_empty():return records
	var events:Array=roster[index].events
	for at in range(events.size()-1,-1,-1):
		var event:Dictionary=events[at]
		if browsing_deeds and not deeds_query.strip_edges().is_empty() and not (EraWords.when(int(event.day))+" "+String(event.text)).to_lower().contains(deeds_query.strip_edges().to_lower()):continue
		records.append({"index":at,"day":event.day,"text":event.text})
	return records

func _render_deeds()->void:
	for box in [deeds_choices,deed_reader]:
		for child in box.get_children():box.remove_child(child);child.queue_free()
	var roster:Array=WorldSimulation.figures.people
	if roster.is_empty():return
	var person:Dictionary=roster[index]
	deeds_split.visible=true;deeds_toggle.visible=true
	portrait.visible=not browsing_deeds and portrait.texture!=null;subtitle.visible=not browsing_deeds;effect.visible=not browsing_deeds
	support_actions.visible=not browsing_deeds;support_note.visible=not browsing_deeds;feedback.visible=not browsing_deeds and not feedback.text.is_empty()
	var records:=deed_records()
	var pages:=maxi(1,ceili(float(records.size())/DEEDS_PAGE));deeds_page=clampi(deeds_page,0,pages-1)
	deeds_toggle.text="Back to recent deeds" if browsing_deeds else "Browse all %d recorded deeds" % (person.events as Array).size()
	deeds_search.visible=browsing_deeds;deeds_paging.visible=browsing_deeds
	biography_button.visible=not browsing_deeds;body.visible=biography_open and not browsing_deeds
	deeds_count.text="%d deeds · %d / %d" % [records.size(),deeds_page+1,pages]
	deeds_previous.disabled=deeds_page==0;deeds_next.disabled=deeds_page>=pages-1
	var shown:Array=records.slice(deeds_page*DEEDS_PAGE,(deeds_page+1)*DEEDS_PAGE) if browsing_deeds else records.slice(0,3)
	if shown.is_empty():P.label(deed_reader,"No deed matches the search." if browsing_deeds else "Their first deeds are yet to be recorded.","body",T.INK_MUTED)
	else:
		if not shown.any(func(event:Dictionary)->bool:return int(event.index)==deed_selected):deed_selected=int(shown[0].index)
		for event:Dictionary in shown:
			var words:=String(event.text)
			var summary:=words if words.length()<=86 else words.substr(0,83).get_slice("\n",0)+"..."
			var button:=Button.new();button.name="DeedChoice";button.text=EraWords.when(int(event.day))+"\n"+summary;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.alignment=HORIZONTAL_ALIGNMENT_LEFT;T.apply_button_style(button)
			button.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG if int(event.index)==deed_selected else T.PAPER_RAISED,T.GOLD if int(event.index)==deed_selected else T.BORDER_SOFT,1,4,6));deeds_choices.add_child(button)
			button.pressed.connect(func()->void:deed_selected=int(event.index);_render_deeds())
			if int(event.index)==deed_selected:
				P.label(deed_reader,EraWords.when(int(event.day)),"small",T.INK_MUTED)
				P.label(deed_reader,String(event.text),"body",T.INK)
	deeds_signature=str([person.id,person.events,browsing_deeds,deeds_page,deeds_query,deed_selected])
