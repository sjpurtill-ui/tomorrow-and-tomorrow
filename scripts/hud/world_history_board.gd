extends VBoxContainer
## WORLD › HISTORY: what has passed between us and the world, as a dense
## dated list grouped by year: first meetings and envoys, wars, raids and
## battles, scouts home. Only the world: the life of our own towns is on
## Home › History, and the Chronicle holds everything together.
##
## Filter chips (with their counts) pick a kind; each row is one line (its
## icon, season, title and first words), the whole telling in its pointer;
## a row with somewhere to go opens it (a scout's telling, a battle).
## Data: content/dock_content_world.gd history_entries() (chronicle.gd).

const T:=preload("res://scripts/hud/hud_tokens.gd")
const UI:=preload("res://scripts/hud/world_ui.gd")

const FILTERS:=[["all","All"],["contact","Peoples"],["war","War"],["scout","Scouts"]]
const PAGE:=40

var model:Dictionary={}
var view:Dictionary={}
var chips:HBoxContainer
var list:VBoxContainer
var more:Button
## Where the next rows go (the list, or one of its two columns).
var target:Control

func setup(block:Dictionary)->void:
	name="WorldHistoryBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	_take(block)
	var top:=UI.line(self,6)
	chips=HBoxContainer.new();chips.name="Filters";chips.add_theme_constant_override("separation",4);top.add_child(chips)
	var frame:=UI.sheet(self,"Years")
	list=VBoxContainer.new();list.name="List";list.add_theme_constant_override("separation",0);frame.add_child(list)
	more=UI.verb(frame,"Earlier years",func()->void:view.shown=int(view.get("shown",PAGE))+PAGE;redraw(),"Show forty more")
	more.name="Earlier";more.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	redraw()

func update_block(block:Dictionary)->bool:
	_take(block)
	redraw()
	return true

var _wide:=false
func _notification(what:int)->void:
	if what==NOTIFICATION_RESIZED and (size.x>=800.0)!=_wide and list!=null:
		_wide=size.x>=800.0
		redraw.call_deferred()

func _take(block:Dictionary)->void:
	model=block
	var given:Variant=block.get("view")
	view=given if given is Dictionary else {}
	if not view.has("filter"):view["filter"]="all"
	if not view.has("shown"):view["shown"]=PAGE

## The entries the chosen chip keeps.
func chosen()->Array:
	var out:Array=[]
	for entry:Dictionary in model.get("entries",[]):
		if String(view.filter)=="all" or String(entry.get("group",""))==String(view.filter):out.append(entry)
	return out

func redraw()->void:
	UI.clear(chips)
	var counts:Dictionary={"all":0}
	for entry:Dictionary in model.get("entries",[]):
		counts["all"]=int(counts.all)+1
		counts[String(entry.get("group",""))]=int(counts.get(String(entry.get("group","")),0))+1
	for pair:Array in FILTERS:
		var key:=String(pair[0])
		var chip:=UI.chip(chips,"%s %d" % [String(pair[1]),int(counts.get(key,0))],String(view.filter)==key,func()->void:view.filter=key;view.shown=PAGE;redraw())
		chip.name="Filter_"+key
	UI.clear(list)
	var entries:=chosen()
	var shown:=entries.slice(0,int(view.get("shown",PAGE)))
	var year:=-1
	# On a wide page the years run on in a second column.
	var two:=size.x>=800.0
	var holder:Control=list
	var columns:HBoxContainer=null
	if two:
		columns=HBoxContainer.new();columns.add_theme_constant_override("separation",18);list.add_child(columns)
		holder=_column(columns)
	target=holder
	for index in shown.size():
		var entry:Dictionary=shown[index]
		var y:=int(entry.get("day",0))/365+1
		if y!=year:
			if two and columns.get_child_count()==1 and index>=shown.size()/2:target=_column(columns)
			year=y
			var head:=UI.line(target,8);head.name="Year_%d" % y
			UI.label(head,"Year %d" % y,13,T.GOLD_TEXT,true).name="Year"
			var rule:=ColorRect.new();rule.color=T.RULE;rule.custom_minimum_size=Vector2(0,1);rule.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(rule)
		_row(entry)
	if entries.is_empty():UI.label(list,"Nothing has passed between us and the world yet",12,T.INK_MUTED)
	more.visible=entries.size()>shown.size()

func _row(entry:Dictionary)->void:
	var open:Variant=entry.get("on_open")
	var text:=String(entry.get("text",""))
	var row:=UI.hot_row(target,"Entry_%d" % target.get_child_count(),open if open is Callable else Callable(),"%s\n%s" % [String(entry.get("title","")),text])
	UI.icon(row,String(entry.get("icon","world")),_tint(String(entry.get("group",""))),18)
	UI.cell(row,String(entry.get("season","")),58,12,T.INK_MUTED)
	# The title and its first sentence, wrapped: nothing is cut off.
	var said:=RichTextLabel.new();said.bbcode_enabled=true;said.fit_content=true;said.scroll_active=false
	said.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;said.size_flags_horizontal=Control.SIZE_EXPAND_FILL;said.custom_minimum_size.x=80
	said.mouse_filter=Control.MOUSE_FILTER_PASS
	said.add_theme_font_override("normal_font",T.font("ui"));said.add_theme_font_override("bold_font",T.font("ui_strong"))
	said.add_theme_font_size_override("normal_font_size",12);said.add_theme_font_size_override("bold_font_size",13)
	said.add_theme_color_override("default_color",T.INK_MUTED)
	var first:=_first_sentence(text)
	# One line: the event's title; its telling is in the row's pointer.
	said.text="[color=#%s]%s[/color]" % [T.INK.to_html(false),("[b]%s[/b]" if bool(entry.get("weighty",false)) else "%s") % _escape(String(entry.get("title","")))]
	said.add_theme_font_size_override("normal_font_size",13)
	row.add_child(said)
	if int(entry.get("count",1))>1:UI.tag(row,"×%d" % int(entry.count),"muted")

static func _column(parent:Node)->VBoxContainer:
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",0)
	parent.add_child(column)
	return column

static func _tint(group:String)->Color:
	match group:
		"war":return T.RED
		"contact":return T.TEAL
		"scout":return T.GOLD
	return T.INK_MUTED

static func _first_sentence(text:String)->String:
	var clean:=text.strip_edges()
	for i in clean.length():
		if clean[i] in [".","!","?"] and (i==clean.length()-1 or clean[i+1]==" "):return clean.substr(0,i+1)
	return clean

static func _escape(text:String)->String:
	return text.replace("[","[lb]")
