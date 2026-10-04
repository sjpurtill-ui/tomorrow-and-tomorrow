extends PanelContainer
## THE DECREE CARD: what the god just decreed, and what it really does.
##
## Shown on the court's stage the moment a decree is given or its measured
## result comes back (a petition's decree granted, a law laid down, a town
## leader's RECEIPT line). It says the decree in the god's own words, who
## carries it out, and each effect in the engine's own numbers: what it gives
## in green ink, what it costs in red, and how long it runs.
##
## Before this card the receipt was a stage caption: it rose under the next
## speech bubble and was dropped the instant that bubble overlapped it
## (court_stage.say drops any caption it touches), so the numbers were on
## screen for a fraction of a second. The card lives on its own layer, never
## dropped by speech. It stays open for a reading time (at least HOLD_MIN
## seconds, longer while the pointer is on it), then folds to a small seal
## chip in the corner that opens it again. A click folds it at once. The same
## words stay in the audience's "Earlier" history (history_row()).
##
## Paper, ink and gold (hud_tokens.gd). Sizes are UI units (1920x1080 base,
## scaled to the window), so it fits 1280x720 and 1536x864 alike.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

signal folded_changed(folded:bool)

const WIDTH:=640.0
const CHIP_WIDTH:=330.0
## Seconds the card stays open before it folds (more for longer cards).
const HOLD_MIN:=10.0
const HOLD_PER_ROW:=1.6
const HOLD_MAX:=24.0
const SEP:=" · "

## Engine labels said plainly. Multipliers read as a percentage of today's
## rate; targets read as points on the strengths list.
const NAMES:={"labor efficiency":"Work done","labor":"Work done","building pace":"Building pace","research pace":"Learning pace",
	"food yield":"Food gathered","food use":"Food eaten","water":"Water fetched","fertility":"Conceptions","migration":"Newcomers",
	"material capacity":"Materials at hand","materials":"Materials at hand","hauling":"Hauling","knowledge":"Learning",
	"health":"Health","cohesion":"Cohesion","legitimacy":"Legitimacy","security":"Security","ecology":"Land health","land health":"Land health",
	"resentment":"Resentment","sickness":"Sickness","violence":"Violence","newborn deaths":"Newborn deaths"}
const PERCENT:=["labor efficiency","labor","building pace","research pace","food yield","food use","water","fertility","migration"]
## Where a rise is a cost.
const BAD_UP:=["food use","resentment","sickness","violence","newborn deaths","disease"]

var info:Dictionary={}
var folded:=false
var _hold:=HOLD_MIN
var _left:=HOLD_MIN
var _hover:=false
var _open_box:VBoxContainer
var _chip:Button
var _born:=0


## info: {title, who, place, day, rows:[{key?,text,tone}], notes:[String],
## outcome:String, receipt:String (raw "RECEIPT · " words, parsed here)}.
func setup(data:Dictionary)->void:
	info=data.duplicate(true)
	if String(info.get("receipt",""))!="":
		var parsed:=parse_receipt(String(info.receipt))
		var rows:Array=info.get("rows",[]) if info.get("rows") is Array else []
		rows.append_array(parsed.rows)
		info["rows"]=rows
		var notes:Array=info.get("notes",[]) if info.get("notes") is Array else []
		notes.append_array(parsed.notes)
		info["notes"]=notes
		if int(parsed.days)>0 and int(info.get("days",0))<=0:info["days"]=int(parsed.days)
	_hold=clampf(HOLD_MIN+HOLD_PER_ROW*float((info.get("rows",[]) as Array).size()),HOLD_MIN,HOLD_MAX)
	_left=_hold
	if is_inside_tree():_build()


func _ready()->void:
	name="DecreeCard"
	mouse_filter=Control.MOUSE_FILTER_STOP
	_born=Time.get_ticks_msec()
	mouse_entered.connect(func()->void:_hover=true)
	mouse_exited.connect(func()->void:_hover=false)
	gui_input.connect(_on_input)
	_build()


func _process(delta:float)->void:
	if folded or _hover:return
	_left-=delta
	if _left<=0.0:fold()


func _on_input(event:InputEvent)->void:
	var click:=event as InputEventMouseButton
	if click==null or not click.pressed or click.button_index!=MOUSE_BUTTON_LEFT:return
	accept_event()
	# A click that lands as the card appears was meant for what was under it.
	if Time.get_ticks_msec()-_born<600:return
	fold()


func fold()->void:
	if folded:return
	folded=true
	_build()
	folded_changed.emit(true)


func unfold()->void:
	folded=false
	_left=_hold
	_born=Time.get_ticks_msec()
	_build()
	folded_changed.emit(false)


func _build()->void:
	for child in get_children():
		remove_child(child);child.queue_free()
	_open_box=null;_chip=null
	if folded:
		add_theme_stylebox_override("panel",StyleBoxEmpty.new())
		custom_minimum_size=Vector2(0,0)
		_chip=Button.new();_chip.name="DecreeChip";_chip.focus_mode=Control.FOCUS_NONE
		_chip.text="Decreed:  "+_short(String(info.get("title","")),34)+"   ▸"
		_chip.tooltip_text="Open what you decreed and what it does."
		_chip.custom_minimum_size=Vector2(0,34)
		_chip.add_theme_font_size_override("font_size",14)
		_chip.add_theme_color_override("font_color",Tokens.GOLD_TEXT)
		_chip.add_theme_color_override("font_hover_color",Tokens.INK)
		_chip.add_theme_stylebox_override("normal",_chip_style(false))
		_chip.add_theme_stylebox_override("hover",_chip_style(true))
		_chip.add_theme_stylebox_override("pressed",_chip_style(true))
		_chip.pressed.connect(unfold)
		add_child(_chip)
		reset_size()
		return
	add_theme_stylebox_override("panel",paper())
	custom_minimum_size=Vector2(WIDTH,0)
	_open_box=VBoxContainer.new();_open_box.name="DecreeBody";_open_box.add_theme_constant_override("separation",6)
	_open_box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(_open_box)
	# The seal, then what kind of decree and when, with the decree itself under it.
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",12);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;_open_box.add_child(head)
	var seal:=Seal.new();seal.custom_minimum_size=Vector2(34,34);seal.size_flags_vertical=Control.SIZE_SHRINK_CENTER;seal.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(seal)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",0);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(words)
	var kicker:=_label(kicker_text(info),11,Tokens.GOLD_TEXT,.14);kicker.name="DecreeKicker"
	words.add_child(kicker)
	var title:=_label("“%s”" % String(info.get("title","Your decree")).strip_edges().trim_suffix("."),21,Tokens.INK)
	title.name="DecreeTitle";title.add_theme_font_override("font",Tokens.voice_font(true))
	title.clip_text=true;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.tooltip_text=String(info.get("title",""));title.mouse_filter=Control.MOUSE_FILTER_PASS
	words.add_child(title)
	var close:=Button.new();close.name="DecreeFold";close.text="Fold";close.flat=true;close.focus_mode=Control.FOCUS_NONE
	close.tooltip_text="Fold it to a small seal; it stays in the corner, and in Earlier."
	close.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	close.add_theme_font_size_override("font_size",13);close.add_theme_color_override("font_color",Tokens.INK_MUTED);close.add_theme_color_override("font_hover_color",Tokens.INK)
	close.pressed.connect(fold);head.add_child(close)
	var by:=by_text(info)
	if by!="":
		var by_label:=_label(by,13,Tokens.BODY_2);by_label.name="DecreeBy";by_label.clip_text=true;by_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;_open_box.add_child(by_label)
	var rows:Array=info.get("rows",[]) if info.get("rows") is Array else []
	if not rows.is_empty():
		var rule:=ColorRect.new();rule.color=Tokens.RULE;rule.custom_minimum_size=Vector2(0,1);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;_open_box.add_child(rule)
		var flow:=HFlowContainer.new();flow.name="DecreeEffects"
		flow.add_theme_constant_override("h_separation",24);flow.add_theme_constant_override("v_separation",3);flow.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_open_box.add_child(flow)
		for row in rows.slice(0,8):flow.add_child(_effect(row as Dictionary))
	var outcome:=String(info.get("outcome","")).strip_edges()
	# The decree is already the title: here the engine's words say "your words".
	outcome=outcome.replace("“%s”" % String(info.get("title","")).strip_edges(),"your words")
	if outcome!="":
		var said:=_label(outcome,14,Tokens.BODY);said.name="DecreeOutcome";said.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;said.max_lines_visible=2
		said.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;_open_box.add_child(said)
	for note in (info.get("notes",[]) as Array).slice(0,1):
		var n:=_label(String(note),13,Tokens.INK_MUTED);n.name="DecreeNote";n.add_theme_font_override("font",Tokens.voice_font(true))
		n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;n.max_lines_visible=2;n.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;_open_box.add_child(n)
	reset_size()


func _effect(row:Dictionary)->Control:
	var tone:=String(row.get("tone",""))
	var ink:=Tokens.GREEN_TEXT if tone=="gain" else (Tokens.RED_TEXT if tone=="cost" else Tokens.INK_MUTED)
	var line:=HBoxContainer.new();line.name="DecreeEffect";line.add_theme_constant_override("separation",6);line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var mark:=_label("+" if tone=="gain" else ("−" if tone=="cost" else "•"),15,ink);mark.add_theme_font_override("font",Tokens.font("ui_strong"))
	mark.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;line.add_child(mark)
	var words:=String(row.get("text",""))
	var key:=String(row.get("key",""))
	if key!="" and not key in ["Gain","Cost","You gain","It costs"]:words="%s: %s" % [key,words]
	var text:=_label(words,14,Tokens.BODY);text.name="DecreeEffectText"
	# A long effect takes the card's width and wraps; short ones sit side by side.
	if words.length()>44:
		text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.custom_minimum_size.x=WIDTH-60.0;text.max_lines_visible=2;text.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	line.add_child(text)
	return line

func _label(text:String,size:int,colour:Color,spacing:float=0.0)->Label:
	var label:=Tokens.make_label(text,size,colour,spacing)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label


# --- Words -----------------------------------------------------------------------

static func kicker_text(data:Dictionary)->String:
	var head:="DECREED"
	if String(data.get("kind",""))=="law":head="MADE LAW"
	elif String(data.get("kind",""))=="receipt":head="DECREE · WHAT IT DID"
	var day:=int(data.get("day",-1))
	if day>=0:head+="  ·  "+EraWords.when(day).to_upper()
	return head


static func by_text(data:Dictionary)->String:
	var parts:=PackedStringArray()
	var who:=String(data.get("who",""))
	var place:=String(data.get("place",""))
	if who!="" and place!="":parts.append("%s carries it out in %s" % [who,place])
	elif who!="":parts.append("%s carries it out" % who)
	var days:=int(data.get("days",0))
	var said_already:=false
	for row in (data.get("rows",[]) as Array):said_already=said_already or String((row as Dictionary).get("text","")).contains(" runs ")
	if days>0 and not said_already:parts.append("runs %s" % _span(days))
	if parts.is_empty():return ""
	var out:=SEP.join(parts)
	return out.substr(0,1).to_upper()+out.substr(1)


static func _span(days:int)->String:
	if days>=60 and days%30==0:return "%d moons" % (days/30)
	return "%d days" % days if days!=1 else "1 day"


static func _short(text:String,limit:int)->String:
	var t:=text.strip_edges().trim_suffix(".")
	return t if t.length()<=limit else t.substr(0,limit-1).strip_edges()+"…"


## A RECEIPT line in plain words: {rows:[{text,tone}], notes:[String], days}.
## Every number is the engine's own; a part this cannot read is shown as it is.
static func parse_receipt(text:String)->Dictionary:
	var rows:Array=[]
	var notes:Array=[]
	var days:=0
	var clean:=text.strip_edges().trim_prefix("RECEIPT").strip_edges().trim_prefix("·").strip_edges()
	var number:=RegEx.create_from_string("^(.*?)\\s+(now\\s+)?([+-]?\\d+(?:\\.\\d+)?)\\s*(pts|/day)?(\\s+from day \\d+)?$")
	var spent:=RegEx.create_from_string("^([\\d.]+)\\s+(food|materials?)\\s+spent$")
	var span:=RegEx.create_from_string("^(\\d+)\\s+days?$")
	var dead:=RegEx.create_from_string("^(\\d+)\\s+dead$")
	var updown:=RegEx.create_from_string("^(.*?)\\s+(up|down)$")
	for raw in clean.split("·",false):
		var part:=String(raw).strip_edges()
		if part=="":continue
		var m:=span.search(part)
		if m!=null:
			days=maxi(days,int(m.get_string(1)));continue
		m=spent.search(part)
		if m!=null:
			var what:=m.get_string(2)
			rows.append({"text":"%s %s from the stores" % [_amount(float(m.get_string(1))),"food" if what=="food" else "materials"],"tone":"cost"});continue
		m=dead.search(part)
		if m!=null:
			rows.append({"text":"%s dead" % m.get_string(1),"tone":"cost"});continue
		m=updown.search(part)
		if m!=null and m.get_string(1).length()<=24:
			var subject:=m.get_string(1)
			var up:=m.get_string(2)=="up"
			var bad:=(subject in BAD_UP)==up
			rows.append({"text":"%s %s" % [String(NAMES.get(subject,subject.capitalize())),"rise" if up else "fall"],"tone":"cost" if bad else "gain"});continue
		m=number.search(part)
		if m!=null and m.get_string(1).length()<=28 and not m.get_string(1).contains(";"):
			rows.append(effect_row(m.get_string(1).strip_edges(),float(m.get_string(3)),m.get_string(4),m.get_string(2)!="",m.get_string(5).strip_edges()));continue
		notes.append(part)
	return {"rows":rows,"notes":notes,"days":days}


## One measured effect: "Building pace +3.3%", "Health now +1.2 pts".
static func effect_row(label:String,value:float,unit:String="",now:bool=false,suffix:String="")->Dictionary:
	var key:=label.to_lower()
	var name:=String(NAMES.get(key,label.capitalize()))
	var shown:=""
	if unit=="pts":shown="%+.1f pts" % value
	elif unit=="/day":shown="%+.5f a day" % value
	elif key=="resentment":shown="%+.2f" % value
	elif key in PERCENT:shown="%+.1f%%" % (value*100.0)
	elif NAMES.has(key):shown="%+.1f pts" % (value*100.0)
	else:shown="%+.3f" % value
	shown=shown.replace("-","−")
	var bad:=(key in BAD_UP)==(value>0.0)
	var text:="%s%s %s" % [name," now" if now else "",shown]
	if suffix!="":text+=" "+suffix
	return {"text":text,"tone":"cost" if bad else "gain"}


static func _amount(value:float)->String:
	return "%d" % roundi(value) if value>=100.0 or is_equal_approx(value,roundf(value)) else "%.1f" % value


## The same decree as one entry of the audience's history ("Earlier").
static func history_row(text:String)->Control:
	var parsed:=parse_receipt(text)
	var box:=PanelContainer.new();box.name="DecreeRecord"
	var style:=Tokens.flat(Tokens.PAPER_RAISED,Tokens.RULE,1,Tokens.RADIUS_CARD,0)
	style.border_width_left=3;style.border_color=Tokens.GOLD
	style.content_margin_left=14;style.content_margin_right=14;style.content_margin_top=6;style.content_margin_bottom=7
	box.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",2);box.add_child(column)
	var head:=Tokens.make_label("WHAT THE DECREE DID",11,Tokens.GOLD_TEXT,.12);column.add_child(head)
	var parts:=PackedStringArray()
	for row in parsed.rows:parts.append(String((row as Dictionary).text))
	if int(parsed.days)>0:parts.append("runs "+_span(int(parsed.days)))
	for note in parsed.notes:parts.append(String(note))
	var body:=Tokens.make_label(SEP.join(parts),14,Tokens.BODY);body.name="DecreeRecordText";body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)
	return box


# --- Paper -----------------------------------------------------------------------

static func paper()->StyleBoxFlat:
	var style:=Tokens.flat(Tokens.PAPER_RAISED,Tokens.RULE_STRONG,1,Tokens.RADIUS_CARD,0)
	style.border_width_top=3;style.border_color=Tokens.GOLD
	style.content_margin_left=18;style.content_margin_right=14;style.content_margin_top=10;style.content_margin_bottom=12
	style.shadow_color=Color(0,0,0,.28);style.shadow_size=10;style.shadow_offset=Vector2(0,3)
	return style


static func _chip_style(hover:bool)->StyleBoxFlat:
	var style:=Tokens.flat(Tokens.PAPER_RAISED if not hover else Tokens.PAPER,Tokens.GOLD,1,Tokens.RADIUS_CARD,0)
	style.border_width_left=3
	style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=4;style.content_margin_bottom=4
	style.shadow_color=Color(0,0,0,.22);style.shadow_size=6
	return style


## A small wax seal pressed into the paper.
class Seal extends Control:
	func _draw()->void:
		var c:=size*0.5
		var r:=minf(size.x,size.y)*0.5-1.0
		var wax:=Tokens.RED.darkened(.08)
		for i in 12:
			var a:=TAU*float(i)/12.0
			draw_circle(c+Vector2(cos(a),sin(a))*(r-2.5),3.0,wax)
		draw_circle(c,r-2.0,wax)
		draw_arc(c,r-5.5,0.0,TAU,28,wax.lightened(.28),1.2,true)
		draw_line(c+Vector2(-3.5,0),c+Vector2(3.5,0),wax.lightened(.4),1.6,true)
		draw_line(c+Vector2(0,-3.5),c+Vector2(0,3.5),wax.lightened(.4),1.6,true)
