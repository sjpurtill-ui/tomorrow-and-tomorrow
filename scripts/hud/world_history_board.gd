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
	for entry:Dictionary in shown:
		var y:=int(entry.get("day",0))/365+1
		if y!=year:
			year=y
			var head:=UI.line(list,8);head.name="Year_%d" % y
			UI.label(head,"Year %d" % y,13,T.GOLD_TEXT,true).name="Year"
			var rule:=ColorRect.new();rule.color=T.RULE;rule.custom_minimum_size=Vector2(0,1);rule.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(rule)
		_row(entry)
	if entries.is_empty():UI.label(list,"Nothing has passed between us and the world yet",12,T.INK_MUTED)
	more.visible=entries.size()>shown.size()

func _row(entry:Dictionary)->void:
	var open:Variant=entry.get("on_open")
	var text:=String(entry.get("text",""))
	var row:=UI.hot_row(list,"Entry_%d" % list.get_child_count(),open if open is Callable else Callable(),"%s\n%s" % [String(entry.get("title","")),text])
	UI.icon(row,String(entry.get("icon","world")),_tint(String(entry.get("group",""))),18)
	UI.cell(row,String(entry.get("season","")),58,12,T.INK_MUTED)
	var title:=UI.label(row,String(entry.get("title","")),13,T.INK,bool(entry.get("weighty",false)))
	title.custom_minimum_size.x=0;title.clip_text=true;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.size_flags_stretch_ratio=1.0
	var words:=UI.label(row,text,12,T.INK_MUTED,false,true);words.size_flags_stretch_ratio=1.4
	if int(entry.get("count",1))>1:UI.tag(row,"×%d" % int(entry.count),"muted")

static func _tint(group:String)->Color:
	match group:
		"war":return T.RED
		"contact":return T.TEAL
		"scout":return T.GOLD
	return T.INK_MUTED
