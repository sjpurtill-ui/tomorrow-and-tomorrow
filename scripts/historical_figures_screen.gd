extends Control

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
	var background:=ColorRect.new(); background.color=Color("122129"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	add_child(margin)
	var layout:=VBoxContainer.new(); layout.add_theme_constant_override("separation",12); margin.add_child(layout)
	var header:=HBoxContainer.new(); layout.add_child(header)
	var heading:=Label.new(); heading.text="PEOPLE & LEGACIES"; heading.add_theme_font_size_override("font_size",26); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(heading)
	_button(header,"OUR DIRECTION · F8",func(): PeopleDirection.open_direction())
	_button(header,"CLOSE · F10",func(): queue_free())
	var nav:=HBoxContainer.new(); layout.add_child(nav)
	previous=_button(nav,"PREVIOUS PERSON",func(): index-=1; chapter=0; _refresh())
	person_page=Label.new(); person_page.size_flags_horizontal=Control.SIZE_EXPAND_FILL; person_page.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; nav.add_child(person_page)
	next=_button(nav,"NEXT PERSON",func(): index+=1; chapter=0; _refresh())
	title=_label(layout,26); title.add_theme_color_override("font_color",Color("f3cd80"))
	subtitle=_label(layout,17)
	effect=_label(layout,17); effect.add_theme_color_override("font_color",Color("84d2be"))
	var chapter_nav:=HBoxContainer.new(); layout.add_child(chapter_nav)
	chapter_previous=_button(chapter_nav,"‹",func(): chapter-=1; _refresh())
	page=_label(chapter_nav,17); page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	chapter_next=_button(chapter_nav,"›",func(): chapter+=1; _refresh())
	body=_label(layout,20); body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var actions:=HBoxContainer.new(); layout.add_child(actions)
	patron=_button(actions,"SUPPORT THEIR WORK",func():
		var result:Dictionary=HistoricalFigures.support(String(HistoricalFigures.people[index].id))
		feedback.text=String(result.get("error","Patronage updated.")); _refresh())
	feedback=_label(layout,16)
	var note:=_label(layout,14); note.text="Three patronage places. Support boosts research in this person's field; generals also influence command. Backgrounds are fictional. Deeds are recorded from play."
	_refresh()

func _label(parent:Node,font:int)->Label:
	var label:=Label.new(); label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.add_theme_font_size_override("font_size",font); parent.add_child(label); return label

func _button(parent:Node,text:String,action:Callable)->Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size.y=36; b.pressed.connect(action); parent.add_child(b); return b

func _process(delta:float)->void:
	refresh_clock+=delta
	if refresh_clock>1: refresh_clock=0; _refresh()

func _refresh()->void:
	var roster:Array=HistoricalFigures.people
	if roster.is_empty(): return
	index=clampi(index,0,roster.size()-1)
	var p:Dictionary=roster[index]
	var day:=int(GameState.elapsed_days) if p.status!="dead" else int(p.death_day)
	var age:=maxi(0,(day-int(p.born))/365)
	var standing:="Great" if int(p.renown)>=60 else ("Renowned" if int(p.renown)>=20 else "Emerging")
	title.text="%s · %s %s" % [p.name,standing,p.role]
	subtitle.text="%s · %s · %s · %s %d
Reputation: %d points from recorded work and battles · Renowned at 20; Great at 60" % [p.role,p.tradition,String(p.status).capitalize(),"Died aged" if p.status=="dead" else "Age",age,int(p.renown)]
	var count:=0
	for other in roster:
		if other.status!="dead" and other.supported: count+=1
	person_page.text="PERSON %d OF %d · PATRONAGE %d OF 3" % [index+1,roster.size(),count]
	previous.disabled=index==0; next.disabled=index==roster.size()-1
	patron.disabled=p.status!="living" and not p.supported
	patron.text="WITHDRAW SUPPORT" if p.supported else "SUPPORT THEIR WORK"
	if p.status=="dead":
		effect.text="Legacy: +%.1f%% %s research progress, preserved through their life's work." % [float(p.legacy)*100,p.domain]
	elif p.status!="living": effect.text="Unavailable: no active contribution while %s." % p.status
	else:
		var bonus:float=HistoricalFigures.living_bonus(p)
		var potential:float=(.12+float(p.talent)*.18)*100
		effect.text="%s research: +%.1f%% now. Patronage enables +%.1f%%." % [String(p.domain).capitalize(),bonus*100,potential]
	var pages:=1+ceili(float(p.events.size())/3.0)
	chapter=clampi(chapter,0,pages-1); chapter_previous.disabled=chapter==0; chapter_next.disabled=chapter==pages-1
	page.text="BACKGROUND · generated" if chapter==0 else "RECORDED DEEDS · page %d of %d" % [chapter,pages-1]
	if chapter==0: body.text=HistoricalFigures.biography(p)
	else:
		body.text=""
		for event:Dictionary in p.events.slice((chapter-1)*3,chapter*3):
			body.text+="Day %d — %s

" % [int(event.day),String(event.text)]
