extends VBoxContainer
## Shared pieces for the home docks' illustrated ledgers (Food, Materials,
## Wealth, the Settlement overview and the Research board). These used to
## borrow _button, _bar and _rule from the Production screen
## (production_queue.gd); they live here now so either screen can change
## without breaking the other. Buttons carry words, never glyphs, and a chosen
## option shows that it is the current one.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
var data:Dictionary

## Accents used as words take their text-safe twins (HudTokens *_TEXT).
static func tone_color(tone:String)->Color:
	match tone:
		"bad":return T.RED_TEXT
		"warn":return T.AMBER_TEXT
		"good":return T.GREEN_TEXT
	return T.MUTED

static func trend_word(trend:String)->String:
	match trend:
		"rising":return "Rising"
		"falling":return "Falling"
	return "Steady"

func _button(parent:Node,label:String,callback:Variant,tip:String,active:bool=false)->Button:
	var b:=Button.new();b.text=label;b.tooltip_text=tip;b.custom_minimum_size=Vector2(28,30)
	b.add_theme_font_size_override("font_size",13);b.add_theme_color_override("font_color",T.INK if active else T.BODY);b.add_theme_color_override("font_hover_color",T.INK)
	var normal:=T.flat(T.ACTIVE_BG if active else Color.TRANSPARENT,T.GOLD if active else T.BORDER_SOFT,1,2,8)
	if active:normal.border_width_bottom=3
	b.add_theme_stylebox_override("normal",normal);b.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,2,8));b.add_theme_stylebox_override("pressed",normal)
	parent.add_child(b)
	if callback is Callable and (callback as Callable).is_valid():b.pressed.connect(callback)
	else:b.disabled=true
	return b

## A row of plain choices; the current one is marked and says so.
func _choices(parent:Node,lead:String,options:Array,current:String)->HFlowContainer:
	var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",6);row.add_theme_constant_override("v_separation",6);parent.add_child(row)
	if not lead.is_empty():
		var label:=T.make_label(lead,13,T.BODY);label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(label)
	for option:Dictionary in options:
		var chosen:=String(option.get("id",""))==current
		var b:=_button(row,String(option.label)+(" (now)" if chosen else ""),option.get("on_press"),String(option.get("tip","")),chosen)
		b.name="Choice_"+String(option.get("id","")).capitalize().replace(" ","")
	return row

func _bar(parent:Node,ratio:float,color:Color)->void:
	var bar:=ProgressBar.new();bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.custom_minimum_size.y=7;bar.show_percentage=false;bar.value=clampf(ratio,0,1)*100;bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(color));parent.add_child(bar)

func _rule(parent:Node)->void:
	var rule:=HSeparator.new();rule.add_theme_color_override("color",T.BORDER_SOFT);parent.add_child(rule)

func _line(parent:Node,text:String,size:int=13,color:Color=T.BODY)->Label:
	var label:=T.make_label(text,size,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(label);return label

## A callable as a live refresh compares it: its method and what it is bound
## to (dock_panel.fingerprint's rule). A lambda is made anew on every refresh
## and never equals the last one, and a bound method equals any binding of
## the same method, so neither can be compared as it is.
static func callable_key(value:Variant)->Variant:
	if value is Callable:return ["fn",String((value as Callable).get_method()),(value as Callable).get_bound_arguments()]
	return value

## Words (and their ink) set only when they differ, so a live refresh does
## not lay out an unchanged line again.
static func _put(label:Label,text:String,color:Variant=null)->void:
	if label.text!=text:label.text=text
	if color is Color and label.get_theme_color("font_color")!=color:label.add_theme_color_override("font_color",color)

func _voice(text:String,font_size:int)->Label:
	var label:=T.make_label(text,font_size,T.INK);label.add_theme_font_override("font",T.voice_font());label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return label

## A headline number read as a sentence: the value in the voice face, then
## "Rising: <cause>" beneath it in a readable accent.
func _reading(parent:Node,headline:String,trend:String,cause:String,tone:String)->VBoxContainer:
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",2);box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(box)
	box.add_child(_voice(headline,22))
	var detail:=(trend_word(trend)+": " if not trend.is_empty() else "")+cause
	_line(box,detail.left(1).to_upper()+detail.substr(1),13,tone_color(tone))
	return box
