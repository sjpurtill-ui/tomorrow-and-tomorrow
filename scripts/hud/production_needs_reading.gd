extends VBoxContainer
## The needs of many armies remain available without turning a stock reading into a log.
const T=preload("res://scripts/hud/hud_tokens.gd")
var entries:Array=[]
var expanded:=false
var page:=0
var search:LineEdit
var reading:Label
var browse:Button
var pages:HBoxContainer
var count:Label
var previous:Button
var next:Button

func _init()->void:
	add_theme_constant_override("separation",6)
	browse=_button("",func():expanded=not expanded;page=0;_refresh());add_child(browse)
	search=LineEdit.new();search.placeholder_text="Find a formation";search.custom_minimum_size.y=40;add_child(search);search.text_changed.connect(func(_value:String):page=0;_refresh())
	reading=T.make_label("",15,T.INK);reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(reading)
	pages=HBoxContainer.new();add_child(pages)
	previous=_button("Previous",func():page-=1;_refresh());pages.add_child(previous)
	count=T.make_label("",13,T.INK_MUTED);count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pages.add_child(count)
	next=_button("Next",func():page+=1;_refresh());pages.add_child(next)

func update_entries(value:Array)->void:
	entries=value;_refresh()

func _refresh()->void:
	visible=not entries.is_empty()
	search.visible=expanded;pages.visible=expanded
	browse.visible=entries.size()>3
	browse.text="Back to summary" if expanded else "All %d formation needs" % entries.size()
	var query:=search.text.strip_edges().to_lower()
	var matched:=entries.filter(func(entry:Dictionary)->bool:return not expanded or query.is_empty() or String(entry.get("who","")).to_lower().contains(query))
	var limit:=6 if expanded else 3
	page=clampi(page,0,maxi(0,ceili(float(matched.size())/limit)-1))
	var lines:PackedStringArray=[]
	for entry:Dictionary in matched.slice(page*limit,(page+1)*limit):
		lines.append("%s · %d needed" % [String(entry.get("who","Formation")).capitalize(),int(entry.get("count",0))])
	reading.text="Needed by\n"+"\n".join(lines) if not lines.is_empty() else "No matching formations"
	count.text="%d · %d/%d" % [matched.size(),page+1,maxi(1,ceili(float(matched.size())/limit))]
	previous.disabled=page==0;next.disabled=(page+1)*limit>=matched.size()

func _button(words:String,callback:Callable)->Button:
	var button:=Button.new();button.text=words;button.custom_minimum_size.y=40;T.apply_button_style(button);button.pressed.connect(callback);return button
