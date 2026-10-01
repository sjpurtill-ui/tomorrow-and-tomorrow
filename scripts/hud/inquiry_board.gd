extends "res://scripts/hud/settlement_overview.gd"
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const Explainer:=preload("res://scripts/effect_explainer.gd")
## Below this board width the questions stack in one column and the lead
## painting sits above its words instead of beside them.
const WIDE:=760.0
const THUMB:=96.0
## Tallest the lead painting grows, beside or above its words.
const LEAD_ART_MAX:=176.0
var fields_grid:GridContainer
var projects_grid:GridContainer
## Each free team's options, side by side on a wide board, stacked on a narrow one.
var choice_grids:Array[GridContainer]=[]
var lead_row:BoxContainer
## Holdup sentences already shown: each is written out once, on the first card
## that has it; later cards with the same holdup keep only its short name.
var explained:Dictionary={}
## The daily refresh (update_block) writes new words into the same cards while
## the board keeps its shape: the same questions in the same places, each
## showing the same lines, and the same fields. _card_words and _field_words
## make every word for the first drawing and every refresh alike.
var _shape:Array=[]
var _cards:Array=[]
var _fields:Array=[]
func setup(block:Dictionary)->void:
	data=block;name="InquiryBoard";add_theme_constant_override("separation",16)
	_shape=_plan(block).shape
	var heading:=HBoxContainer.new();heading.add_theme_constant_override("separation",16);add_child(heading)
	var intro:=VBoxContainer.new();intro.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(intro)
	intro.add_child(_serif("At the edge of what we know",27))
	_note(intro,"Follow the work underway, or give your people a new question to pursue.")
	_button(heading,"Explore the discovery tree",data.on_tree,"Explore known methods and their prerequisites")
	# A team freed by a proof took up the best question open to it; for a season
	# the player may send it elsewhere (DiscoverySystem.team_choices).
	for choice:Dictionary in data.get("choices",[]):_choice_card(self,choice)
	var learning:=VBoxContainer.new();learning.name="BeingLearned";learning.add_theme_constant_override("separation",12);add_child(learning)
	learning.add_child(T.make_label("BEING LEARNED NOW",12,T.GOLD_TEXT))
	# Teams working far ahead of the age: the price of that lead, in plain words.
	var price:=lead_price(data.investigations)
	if not price.is_empty():
		var lead_note:=_line(learning,price,13,T.AMBER_TEXT);lead_note.name="LeadPrice"
	var order:=question_order(data.investigations)
	if not (order.lead as Dictionary).is_empty():_question(learning,order.lead,true)
	projects_grid=GridContainer.new();projects_grid.columns=2;projects_grid.add_theme_constant_override("h_separation",16);projects_grid.add_theme_constant_override("v_separation",16);learning.add_child(projects_grid)
	for record:Dictionary in order.rest:
		_question(projects_grid,record,false)
	if data.investigations.is_empty():
		var empty:=_card(projects_grid);Visuals.paint(empty,"knowledge",130)
		empty.add_child(_serif("The next question is still open",22))
		_note(empty,"Learning needs people to do it, clues to follow and earlier knowledge. Open the knowledge tree to choose a question, or ask your leader for more hands on learning.")
		_button(empty,"Who does the work",data.on_work,"How many people the local leaders set to learning")
	_rule(self)
	var field_heading:=HBoxContainer.new();add_child(field_heading)
	var field_title:=T.make_label("WHERE SHOULD WE LOOK NEXT?",12,T.GOLD_TEXT);field_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;field_heading.add_child(field_title)
	_button(field_heading,"Who does the work",data.on_work,"How many people the local leaders set to learning")
	_note(self,"Your lore keepers work in teams, each on one question until it is proven. A field's share of attention sets how often its questions get a team; it cannot make up for clues the people have not found.")
	fields_grid=GridContainer.new();fields_grid.columns=3;fields_grid.add_theme_constant_override("h_separation",16);fields_grid.add_theme_constant_override("v_separation",18);add_child(fields_grid)
	for field:Dictionary in data.fields:
		var outer:=_card(fields_grid);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);outer.add_child(row)
		var art:=Visuals.art(String(field.id))
		var thumb:=TextureRect.new();thumb.texture=Visuals.source_texture(art) if art else null;thumb.custom_minimum_size=Vector2(92,92)
		thumb.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;thumb.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;thumb.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;thumb.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(thumb)
		var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_constant_override("separation",5);row.add_child(card)
		card.add_child(_serif(Visuals.name_for(String(field.id)),18))
		var goal:=String(field.goal).left(1).to_upper()+String(field.goal).substr(1);_clamped(card,goal,12,T.TEXT_SOFT);outer.get_parent().tooltip_text=goal
		var meter:=_meter(card,float(field.share),Visuals.color(String(field.id)))
		var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",6);card.add_child(controls)
		var share:=T.make_label(_field_words(field),12,T.BODY);share.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;share.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_child(share);card.move_child(share,controls.get_index())
		var less:=_button(controls,"Less",field.on_less,"Give one step of this field's attention to the others");less.disabled=int(field.weight)<=0
		_button(controls,"More",field.on_more,"Move one step of attention to this field")
		_button(controls,"Open",field.on_open,"What this field is for, and what is being worked on")
		_fields.append({"meter":meter,"share":share,"less":less})
	resized.connect(_arrange);_arrange()

## The live refresh: while the board keeps its shape the cards and fields
## take the day's evidence, people and attention in place; otherwise the board
## is drawn afresh.
func update_block(block:Dictionary)->bool:
	var plan:=_plan(block)
	if _cards.size()+_fields.size()==0 or plan.shape!=_shape:return false
	data=block
	for index in mini((plan.words as Array).size(),_cards.size()):
		var words:Dictionary=plan.words[index]
		var card:Dictionary=_cards[index]
		(card.meter as ProgressBar).value=float(words.progress)*100
		_put(card.line,String(words.evidence))
		_put(card.phase,String(words.phase))
		if card.why!=null:_put(card.why,String(words.why))
		if card.would!=null:_put(card.would,String(words.would))
		(card.panel as Control).tooltip_text=String(words.tooltip)
	for index in mini((data.fields as Array).size(),_fields.size()):
		var field:Dictionary=data.fields[index]
		var refs:Dictionary=_fields[index]
		(refs.meter as ProgressBar).value=float(field.share)*100
		_put(refs.share,_field_words(field))
		(refs.less as Button).disabled=int(field.weight)<=0
	return true

## The cards' words in board order, and the board's shape: each question in
## its place (the lead with its painting, the others in order) with the lines
## its card shows, whether the board stands empty, and the fields.
static func _plan(block:Dictionary)->Dictionary:
	var investigations:Array=block.get("investigations",[])
	var order:=question_order(investigations)
	var records:Array=([] if (order.lead as Dictionary).is_empty() else [order.lead])+order.rest
	var cards:Array=[]
	var all_words:Array=[]
	var shown:={}
	for index in records.size():
		var record:Dictionary=records[index]
		var words:=_card_words(record)
		all_words.append(words)
		var why_shown:=not bool(words.restated) and not shown.has(words.why)
		if why_shown:shown[words.why]=true
		var lead:=index==0 and not (order.lead as Dictionary).is_empty()
		cards.append([String(record.get("id","")),lead,has_painting(record),Visuals.subject_art_key(record) if has_painting(record) else "",field_name(record),String(record.get("name","An open question")),why_shown,String(words.would)!="",String(record.get("dynamic",record.get("direction","")))])
	var fields:Array=[]
	for field:Dictionary in block.get("fields",[]):fields.append([String(field.get("id","")),String(field.get("goal",""))])
	var choices:Array=[]
	for choice:Dictionary in block.get("choices",[]):
		var options:Array=[]
		for option:Dictionary in choice.get("options",[]):options.append([String(option.get("id","")),option_words(option)])
		choices.append([String(choice.get("key","")),String(choice.get("taken","")),int(choice.get("days_left",0))/30,options])
	return {"shape":[cards,investigations.is_empty(),fields,choices,lead_price(investigations)],"words":all_words}

## The question nearest to proof that has a painting leads the section at full
## width; the rest keep a steady order (by field, then name) so cards do not
## trade places as the evidence builds day by day.
static func question_order(records:Array)->Dictionary:
	var lead:=-1
	for index in records.size():
		var record:Dictionary=records[index]
		if not has_painting(record):continue
		if lead<0 or float(record.get("progress",0.0))>float((records[lead] as Dictionary).get("progress",0.0)):lead=index
	var rest:Array=[]
	for index in records.size():
		if index!=lead:rest.append(records[index])
	var fields:Array=Visuals.NAMES.keys()
	rest.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var first:=fields.find(String(a.get("dynamic","")));var second:=fields.find(String(b.get("dynamic","")))
		if first<0:first=fields.size()
		if second<0:second=fields.size()
		if first!=second:return first<second
		return String(a.get("name",""))<String(b.get("name","")))
	return {"lead":records[lead] if lead>=0 else {},"rest":rest}
static func has_painting(record:Dictionary)->bool:
	var path:=Visuals.subject_art_key(record)
	return not path.is_empty() and ResourceLoader.exists(path)
## The field a question belongs to, for its card's kicker. A record without a
## field names its line of study instead; with neither, the card has no kicker.
static func field_name(record:Dictionary)->String:
	var domain:=String(record.get("dynamic",record.get("direction","")))
	if not domain.is_empty():return Visuals.name_for(domain)
	return String(record.get("subcategory","")).strip_edges()

## A question card's words from its record: the evidence meter, who works it
## and how far the evidence has come, its phase and holdup, what answering it
## would bring, and its tooltip.
static func _card_words(record:Dictionary)->Dictionary:
	var progress:=clampf(float(record.get("progress",0)),0,1);var researchers:=float(record.get("research_workforce",0))
	var bottleneck:=String(record.get("bottleneck","Gathering evidence"))
	var phase:=Visuals.phase({"assignment":{"bottleneck":bottleneck,"active":true,"capacity":{"researchers":researchers}}})
	if phase.is_empty():
		var reason:=bottleneck.split(" — ",true,1);phase=reason[0].left(1)+reason[0].substr(1).to_lower()
	var why:=Visuals.plain_bottleneck(bottleneck)
	# Its step to proof, unless something holds it back.
	if bottleneck.begins_with("EARLY EVIDENCE") or bottleneck.begins_with("REPLICATION") or bottleneck.begins_with("VALIDATION"):
		var step:=Words.step(int(record.get("stage",preload("res://scripts/research_600_catalog.gd").stage(progress))),float(record.get("trial_share",preload("res://scripts/research_600_catalog.gd").trial_share(progress))))
		why=step.left(1).to_upper()+step.substr(1)+"."
	var restated:=why.trim_suffix(".").to_lower()==phase.to_lower()
	var holdup:=why if restated else "%s: %s" % [phase,why.left(1).to_lower()+why.substr(1)]
	# What answering it would do in the game, from the engine's own readings.
	var effects:Dictionary=record.get("effects",{})
	var would:=""
	var brings:=""
	if not effects.is_empty():
		would="Would bring: %s." % Explainer.summary(effects)
		brings="\n\nWhat it would do, at full use:\n"+Explainer.effect_lines(effects,1.0,1.0,false)
	var opens:=int(record.get("opens",0))
	if opens>0:would=(would+" " if not would.is_empty() else "")+"Opens %d more question%s." % [opens,"" if opens==1 else "s"]
	var goal:=String(record.get("observation",record.get("project_goal",record.get("project_method",""))))
	# Who works it and its clock: "A team of about 3 people; about 1½ years to proof".
	var team:=Words.team(researchers,int(record.get("teams_on",1)))
	var clock:=Words.clock(float(record.get("estimated_days",0.0)))
	return {"progress":progress,"evidence":team+("; "+clock if not clock.is_empty() else ""),"phase":phase,"why":why,"restated":restated,"would":would,
		"tooltip":(goal+"\n\n" if not goal.is_empty() else "")+holdup+brings+"\n\nClick to review this field, its current investigations and what they would do."}

## The price of the furthest lead among the questions under way, once teams
## work five years or more ahead of the age: "Our learning runs ahead of its
## age: 25 years ahead: six times the work for each question there." "" otherwise.
static func lead_price(records:Array)->String:
	var furthest:Dictionary={}
	for record:Dictionary in records:
		if float(record.get("years_ahead",0.0))>=5.0 and (furthest.is_empty() or float(record.years_ahead)>float(furthest.years_ahead)):furthest=record
	if furthest.is_empty():return ""
	return "Our learning runs ahead of its age: %s for a question there. More hands buy a longer lead, not quicker answers." % Words.lead_price(float(furthest.years_ahead),float(furthest.get("work_factor",1.0)))

## One option of a free team's choice in words: its time with the team, how
## far ahead of its age, what it would bring and what it opens.
static func option_words(option:Dictionary)->Dictionary:
	var days:=float(option.get("days",0.0))
	var time:=Words.clock(days)
	var ahead:=""
	if float(option.get("years_ahead",0.0))>=1.0:ahead=Words.lead_price(float(option.years_ahead),float(option.get("work_factor",1.0))).left(1).to_upper()+Words.lead_price(float(option.years_ahead),float(option.get("work_factor",1.0))).substr(1)
	var effects:Dictionary=option.get("effects",{})
	var brings:="Would bring: %s." % Explainer.summary(effects) if not effects.is_empty() else "Changes nothing by itself; it opens the way to later knowledge."
	var opens:=int(option.get("opens",0))
	return {"time":(time.left(1).to_upper()+time.substr(1)+" with this team") if not time.is_empty() else "","ahead":ahead,"brings":brings,
		"opens":("Opens %d more question%s." % [opens,"" if opens==1 else "s"]) if opens>0 else "Opens no further question yet."}

## A free team's choice: the proof that freed it, the question it took up, and
## its options side by side, each with a plain button. A season after the proof
## the card goes and the team keeps the question it took.
func _choice_card(parent:Node,choice:Dictionary)->void:
	var box:=_card(parent)
	var panel:=box.get_parent() as Control
	panel.name="Choice_"+String(choice.get("key","")).validate_node_name()
	panel.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,T.GOLD,1,T.RADIUS_CARD,14))
	box.add_child(T.make_label("A TEAM IS FREE",12,T.GOLD_TEXT))
	var options:Array=choice.get("options",[])
	var taken_name:=String((options[0] as Dictionary).get("name","")) if not options.is_empty() else ""
	box.add_child(_serif("%s is proven. Its team took up %s." % [String(choice.get("proved","A question")),taken_name],20))
	var left:=int(choice.get("days_left",0))
	_note(box,"Keep them on it, or send them to another question instead%s. They stay with what they take until it is proven; the work already done on a question is never lost." % (" (about %s left to choose)" % Words.Plain.span_text(float(left)) if left>=1 else ""))
	var grid:=GridContainer.new();grid.name="Options";grid.columns=3;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);box.add_child(grid)
	choice_grids.append(grid)
	for index in options.size():
		var option:Dictionary=options[index]
		var taken:=index==0
		var tile:=PanelContainer.new();tile.name="Option_"+String(option.get("id","")).validate_node_name();tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",T.flat(T.ACTIVE_BG if taken else T.TILE_BG,T.GOLD if taken else T.BORDER_SOFT,1,T.RADIUS_CONTROL,10));grid.add_child(tile)
		var text:=VBoxContainer.new();text.add_theme_constant_override("separation",4);tile.add_child(text)
		var domain:=String(option.get("dynamic",""))
		var kicker:=T.make_label((field_name(option)+(" · TAKEN UP" if taken else "")).to_upper(),12,T.legible(Visuals.color(domain)));text.add_child(kicker)
		text.add_child(_serif(String(option.get("name","")),17))
		var words:=option_words(option)
		if String(words.time)!="":_line(text,String(words.time),13,T.BODY)
		if String(words.ahead)!="":_line(text,String(words.ahead),12,T.AMBER_TEXT)
		_line(text,String(words.brings),12,T.TEXT_SOFT)
		_line(text,String(words.opens),12,T.TEXT_SOFT)
		var press:Variant=(data.on_choose as Callable).bind(String(choice.get("key","")),String(option.get("id",""))) if data.get("on_choose") is Callable else null
		var button:=_button(text,"Keep them on it" if taken else "Take this up instead",press,"They keep %s until it is proven." % String(option.get("name","")) if taken else "The team leaves %s (its work is kept) and takes up %s until it is proven." % [taken_name,String(option.get("name",""))],taken)
		button.name="Choose"

## A field card's line: its share of attention and what is being worked on.
static func _field_words(field:Dictionary)->String:
	var share_words:="No attention" if float(field.share)<=0.0 else "About %d in 100 of our attention" % maxi(1,roundi(float(field.share)*100))
	return "%s; %s"%[share_words,"%d question%s being worked on" % [int(field.active),"" if int(field.active)==1 else "s"] if int(field.active)>0 else "nothing being worked on"]

## One card per question: its field, the question, how far the evidence has
## come, who works it and what holds it back. A card is as tall as its own
## words; the lead card spans the section with its painting beside its words
## (above them on a narrow board).
func _question(parent:Node,record:Dictionary,lead:bool)->void:
	var domain:=String(record.get("dynamic",record.get("direction","")));var accent:=Visuals.color(domain)
	var panel:=PanelContainer.new();panel.name="Question_"+String(record.get("id","")).validate_node_name()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;parent.add_child(panel)
	var pad:=16.0 if lead else 12.0
	var idle:=_card_style(pad);var hover:=_card_style(pad,true)
	panel.add_theme_stylebox_override("panel",idle)
	panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",hover))
	panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",idle))
	var review:Callable=data.on_domain.bind(domain if not domain.is_empty() else "knowledge")
	panel.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:review.call())
	var row:=BoxContainer.new();row.add_theme_constant_override("separation",20 if lead else 14);row.mouse_filter=Control.MOUSE_FILTER_PASS;panel.add_child(row)
	if lead:
		lead_row=row
		# Banners show whole at their own proportions; taller plates are cropped
		# around their subject so the painting stays about as tall as the words.
		var art:=Visuals.paint_hero(row,record,120,LEAD_ART_MAX)
		art.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;art.size_flags_stretch_ratio=0.85
	elif has_painting(record):
		var thumb:=Visuals.paint_discovery(row,record,THUMB);thumb.custom_minimum_size.x=THUMB;thumb.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	else:
		var tile:=PanelContainer.new();tile.custom_minimum_size=Vector2(THUMB,THUMB);tile.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;tile.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_theme_stylebox_override("panel",T.flat(T.TILE_BG,T.BORDER_SOFT,1,T.RADIUS_CONTROL,0));row.add_child(tile)
		var glyph:=TextureRect.new();glyph.texture=preload("res://scripts/resource_icons.gd").domain_texture(domain if not domain.is_empty() else "knowledge",accent);glyph.custom_minimum_size=Vector2(48,48)
		glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;glyph.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;glyph.size_flags_vertical=Control.SIZE_SHRINK_CENTER;tile.add_child(glyph)
	var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",6);text.mouse_filter=Control.MOUSE_FILTER_PASS;row.add_child(text)
	var field:=field_name(record)
	if not field.is_empty():
		var kicker:=T.make_label(field.to_upper(),12,T.legible(accent));kicker.name="FieldLabel";text.add_child(kicker)
	text.add_child(_serif(String(record.get("name","An open question")),24 if lead else 19))
	var words:=_card_words(record)
	var refs:={"panel":panel,"why":null,"would":null}
	refs.meter=_meter(text,float(words.progress),accent)
	refs.line=_line(text,String(words.evidence),14 if lead else 13,T.BODY)
	refs.phase=_line(text,String(words.phase),14 if lead else 13,T.INK)
	if not bool(words.restated) and not explained.has(words.why):
		explained[words.why]=true;refs.why=_line(text,String(words.why),13 if lead else 12,T.TEXT_SOFT)
	if String(words.would)!="":
		var would:=_line(text,String(words.would),13 if lead else 12,T.TEXT_SOFT);would.name="WouldBring";refs.would=would
	panel.tooltip_text=String(words.tooltip)
	_cards.append(refs)
func _card_style(pad:float,hover:bool=false)->StyleBoxFlat:
	return T.flat(T.HOVER_BG if hover else T.ROW_BG,T.GOLD if hover else T.BORDER,1,T.RADIUS_CARD,pad)
func _clamped(parent:Node,value:String,font:int,ink:Color,lines:int=2)->void:
	var label:=T.make_label(value,font,ink);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible=lines;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;parent.add_child(label)
func _card(parent:Node)->VBoxContainer:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(panel)
	panel.add_theme_stylebox_override("panel",_card_style(12))
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",9);panel.add_child(box);return box
func _meter(parent:Node,fraction:float,color:Color)->ProgressBar:
	var bar:=ProgressBar.new();bar.custom_minimum_size.y=6;bar.show_percentage=false;bar.value=fraction*100;parent.add_child(bar)
	bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(color))
	return bar
func _arrange()->void:
	var wide:=size.x>=WIDE
	for grid:GridContainer in choice_grids:
		if is_instance_valid(grid):grid.columns=3 if wide else 1
	if fields_grid:fields_grid.columns=3 if size.x>=1100 else (2 if size.x>=520 else 1)
	if projects_grid:projects_grid.columns=2 if wide and projects_grid.get_child_count()>1 else 1
	if lead_row:lead_row.vertical=not wide
