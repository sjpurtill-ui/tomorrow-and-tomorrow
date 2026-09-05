extends Control
var civ_id:=""
var heading:Label
var personal:Label
var speech:RichTextLabel
var access_note:Label
var audience_button:Button
var retry_button:Button
var memory:Label
var assessment:Label
var costs:Label
var message:Label
var accord:OptionButton
var tone:OptionButton
var generous:CheckButton
var submit:Button
var ask_button:Button
var entry:LineEdit
var draft_button:Button
var page:=0
var timer:=0.0

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg:=ColorRect.new(); bg.color=Color("122128"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,22)
	add_child(margin)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",10); margin.add_child(root)
	var top:=HBoxContainer.new(); root.add_child(top)
	heading=label(top,27); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(top,"RETURN TO THE GAME",func(): queue_free())
	button(top,"TREATIES & LEAGUES",func(): open_commitments())
	var body:=HBoxContainer.new(); body.add_theme_constant_override("separation",24); body.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(body)
	var portrait:=VBoxContainer.new(); portrait.custom_minimum_size.x=300; body.add_child(portrait)
	var crest:=Label.new(); crest.text="◈"; crest.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; crest.add_theme_font_size_override("font_size",76); crest.add_theme_color_override("font_color",Color("d7b67a")); portrait.add_child(crest)
	personal=label(portrait,17)
	var archive:=HBoxContainer.new(); portrait.add_child(archive)
	button(archive,"‹",func(): page=maxi(0,page-1); refresh())
	var caption:=label(archive,14); caption.text="WHAT THEY REMEMBER"; caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(archive,"›",func(): page+=1; refresh())
	memory=label(portrait,15)
	var audience:=VBoxContainer.new(); audience.size_flags_horizontal=Control.SIZE_EXPAND_FILL; audience.add_theme_constant_override("separation",12); body.add_child(audience)
	access_note=label(audience,14)
	audience_button=button(audience,"SEND DELEGATES TO ESTABLISH AN AUDIENCE",func():
		var result:=ForeignDiplomacy.send_audience(civ_id)
		message.text=String(result.get("error","Delegates departed. Return when their exchange arrives home.")); refresh())
	speech=RichTextLabel.new(); speech.bbcode_enabled=false; speech.scroll_following=true
	speech.custom_minimum_size.y=175; speech.size_flags_vertical=Control.SIZE_EXPAND_FILL; speech.add_theme_font_size_override("normal_font_size",16); audience.add_child(speech)
	var talk:=HBoxContainer.new(); audience.add_child(talk)
	entry=LineEdit.new(); entry.placeholder_text="Ask, challenge, or suggest terms…"; entry.max_length=1500; entry.size_flags_horizontal=Control.SIZE_EXPAND_FILL; talk.add_child(entry)
	ask_button=button(talk,"DISCUSS",ask); entry.text_submitted.connect(func(_text:String): ask())
	retry_button=button(talk,"RETRY",func(): ForeignDialogue.retry(civ_id); refresh())
	draft_button=button(audience,"REVIEW PROPOSED TERMS",func():
		var draft:Dictionary=ForeignDialogue.thread(civ_id).draft
		if draft.is_empty(): return
		if draft.has("commitment"): open_commitments(draft.commitment); return
		accord.select(ForeignDiplomacy.ACCORDS.keys().find(draft.accord)); tone.select(ForeignDiplomacy.TONES.keys().find(draft.tone)); generous.set_pressed_no_signal(draft.generous); refresh())
	var row:=HBoxContainer.new(); audience.add_child(row)
	accord=OptionButton.new(); accord.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(accord)
	for definition:Dictionary in ForeignDiplomacy.ACCORDS.values(): accord.add_item(definition.name)
	accord.select(ForeignDiplomacy.ACCORDS.keys().find(ForeignDiplomacy.situation(civ_id).priority))
	tone=OptionButton.new(); row.add_child(tone)
	for text:String in ForeignDiplomacy.TONES.values(): tone.add_item(text)
	for choice:OptionButton in [accord,tone]: choice.item_selected.connect(func(_i:int): refresh())
	generous=CheckButton.new(); generous.text="Offer a larger contribution · 12 Timber, smaller benefit for us"; audience.add_child(generous); generous.toggled.connect(func(_value:bool): refresh())
	assessment=label(audience,16); assessment.add_theme_color_override("font_color",Color("d7b67a"))
	costs=label(root,16)
	var footer:=HBoxContainer.new(); root.add_child(footer)
	message=label(footer,15); message.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	submit=button(footer,"SEND ENVOYS WITH THESE TERMS",func():
		var result:Dictionary=ForeignDiplomacy.send(civ_id,selected_accord(),selected_tone(),generous.button_pressed)
		message.text=String(result.get("error","Your proposal is on the road. Return here when the envoys bring an answer.")); refresh())
	ForeignDialogue.changed.connect(func(id:String):
		if id==civ_id: refresh())
	refresh()

func label(parent:Node,font:int)->Label:
	var l:=Label.new(); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size",font); parent.add_child(l); return l
func button(parent:Node,text:String,action:Callable)->Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size.y=34; b.pressed.connect(action); parent.add_child(b); return b
func selected_accord()->String: return ForeignDiplomacy.ACCORDS.keys()[accord.selected]
func selected_tone()->String: return ForeignDiplomacy.TONES.keys()[tone.selected]
func ask()->void:
	if ForeignDialogue.ask(civ_id,entry.text): entry.clear()
	refresh()

func open_commitments(draft:Dictionary={})->void:
	var council=preload("res://scripts/commitment_screen.gd").new()
	council.civ_id=civ_id; council.draft=draft.duplicate(true); add_child(council)
func _process(delta:float)->void:
	timer+=delta
	if timer>=1: timer=0; refresh()
func refresh()->void:
	ForeignDiplomacy.advance(int(GameState.elapsed_days))
	var p:=ForeignDiplomacy.leader(civ_id); var civ:=ForeignDiplomacy.civilization(civ_id)
	if p.is_empty(): queue_free(); return
	heading.text=String(p.name).to_upper()+" · "+String(civ.name)
	personal.text="%s\n\n%s\n\nPersonal trust: %s" % [p.temperament,p.bio,"earned" if float(p.trust)>.1 else ("damaged" if float(p.trust)<-.1 else "untested")]
	if not (p.accord as Dictionary).is_empty(): personal.text+="\n\n%s\n%d days of cooperation remain." % [ForeignDiplomacy.ACCORDS[p.accord.kind].name,maxi(0,int(p.accord.until)-int(GameState.elapsed_days))]
	page=clampi(page,0,maxi(0,p.memories.size()-1))
	memory.text="Your dealings will leave a record here." if p.memories.is_empty() else "Day %d · %d of %d\n%s" % [int(p.memories[page].day),page+1,p.memories.size(),String(p.memories[page].text)]
	# One memory per page keeps long campaign histories off the main screen.
	memory.max_lines_visible=7; memory.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var context:Dictionary=ForeignDiplomacy.situation(civ_id); var thread:Dictionary=ForeignDialogue.thread(civ_id)
	var gate:=ForeignDialogue.access(civ_id)
	access_note.text=String(gate.reason)+("\n"+String(thread.status) if String(thread.status)!="" else "")
	audience_button.visible=not bool(gate.ok)
	audience_button.disabled=not CivilizationSystem.diplomatic_mission.is_empty()
	var transcript:Array[String]=[]
	for turn:Dictionary in thread.messages:
		transcript.append("%s · %s\n%s" % ["You" if turn.role=="user" else String(p.name),"earlier exchange" if int(turn.day)<0 else "day %d" % int(turn.day),String(turn.content)])
	var displayed:="\n\n".join(transcript)
	if displayed.is_empty(): displayed=String(context.title)+"\n“"+String(context.line)+"”" if bool(gate.ok) else "An audience has not yet been established. Your delegates must make the journey before this leader can answer."
	if speech.text!=displayed: speech.text=displayed
	draft_button.visible=not (thread.draft as Dictionary).is_empty()
	ask_button.disabled=ForeignDialogue.pending.has(civ_id) or not bool(gate.ok)
	entry.editable=not ForeignDialogue.pending.has(civ_id) and bool(gate.ok)
	retry_button.visible=bool(thread.retryable)
	retry_button.disabled=ForeignDialogue.pending.has(civ_id) or not bool(gate.ok)
	var f:Dictionary=ForeignDiplomacy.forecast(civ_id,selected_accord(),selected_tone(),generous.button_pressed)
	assessment.text=f.label+" · "+f.reasons+"\nThe answer is settled when envoys return; circumstances can change."
	var quote:Dictionary=CivilizationSystem.diplomatic_mission_quote(civ_id,"","leader_parley")
	var blocker:String=f.blocker
	if blocker=="" and quote.has("error"): blocker=quote.error
	if blocker=="" and float(GameState.resource_stockpiles.get("Timber",0))<int(f.cost): blocker="Not enough Timber for these terms."
	submit.disabled=blocker!=""
	var travel:="" if quote.has("error") else " Journey: %d envoys, %.1f Food, %d days round trip." % [int(quote.personnel),float(quote.provisions),int(quote.total_days)]
	costs.text="%s\nReserve %d Timber; returned if declined. Accepted: +%d%% %s research for 730 days; their %s rises %d points.\nWar ends cooperation. Research bonuses from all leaders cap at +24%% per domain.%s" % [ForeignDiplomacy.ACCORDS[selected_accord()].purpose,int(f.cost),roundi(float(f.bonus)*100),f.domain,"logistics" if selected_accord()=="routes" else ("knowledge" if selected_accord()=="exchange" else "cohesion"),4 if generous.button_pressed else 2,travel]
	if blocker!="": costs.text+="\n"+blocker
