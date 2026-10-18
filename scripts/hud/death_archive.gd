extends VBoxContainer
## Deliberately opened archive. Six records and one account; no notices emitted.
const T=preload("res://scripts/hud/hud_tokens.gd")
const Words=preload("res://scripts/hud/era_words.gd")
var records:Array=[]
var choices:Control
var detail:VBoxContainer
var search:LineEdit
var page:=0
var selected:=""
func setup(block:Dictionary)->void:
	name="DeathArchive";records=block.get("records",[]).duplicate();records.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.get("day",0))>int(b.get("day",0)));add_theme_constant_override("separation",10)
	search=LineEdit.new();search.placeholder_text="Find a name, cause or place";add_child(search);search.text_changed.connect(func(_v:String):page=0;_refresh())
	choices=VBoxContainer.new();add_child(choices)
	detail=VBoxContainer.new();detail.add_theme_constant_override("separation",5);add_child(detail);_refresh()
func _key(record:Dictionary)->String:return String(record.get("id",JSON.stringify(record)))
func _refresh()->void:
	for child in choices.get_children():choices.remove_child(child);child.queue_free()
	for child in detail.get_children():detail.remove_child(child);child.queue_free()
	var matches:Array=records.filter(func(r:Dictionary)->bool:return search.text.is_empty() or search.text.to_lower() in (String(r.get("title",""))+" "+String(r.get("cause",""))+" "+String(r.get("location",""))+" "+String(r.get("description",""))).to_lower())
	page=clampi(page,0,maxi(0,ceili(float(matches.size())/6)-1))
	var current:Dictionary={}
	for r:Dictionary in matches:
		if _key(r)==selected:current=r;break
	if current.is_empty() and not matches.is_empty():current=matches[mini(page*6,matches.size()-1)];selected=_key(current)
	for record:Dictionary in matches.slice(page*6,(page+1)*6):
		var key:=_key(record);var button:=Button.new();button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.clip_text=true;button.toggle_mode=true;button.button_pressed=key==selected;T.apply_button_style(button)
		button.text="%s · %d died" % [String(record.get("title",String(record.get("cause","Recorded deaths")).capitalize())),int(record.get("count",0))]
		button.tooltip_text=String(record.get("title",""))+" · "+String(record.get("location","Place not recorded"));choices.add_child(button);button.pressed.connect(func():selected=key;_refresh())
	if matches.is_empty():choices.add_child(T.make_label("No matching death records.",16,T.INK_MUTED));return
	if matches.size()>6:
		var pager:=HBoxContainer.new();choices.add_child(pager)
		for delta in [-1,1]:
			var button:=Button.new();button.text="Newer" if delta<0 else "Older";button.disabled=page==0 if delta<0 else (page+1)*6>=matches.size();T.apply_button_style(button);pager.add_child(button);button.pressed.connect(func():page+=delta;selected="";_refresh())
		pager.add_child(T.make_label("%d–%d / %d" % [page*6+1,mini((page+1)*6,matches.size()),matches.size()],13,T.INK_MUTED))
	for text:String in [String(current.get("title","Recorded deaths")),"%s · %s · %s" % [String(current.get("location","Place not recorded")),Words.when(int(current.get("day",0))),String(current.get("cause","Cause not recorded"))],String(current.get("description","No further account recorded."))]:
		var label:=T.make_label(text,16,T.INK);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_child(label)
func view_state()->Dictionary:return {"selected":selected,"query":search.text,"page":page}
func restore_view_state(state:Dictionary)->void:
	selected=String(state.get("selected",""));search.text=String(state.get("query",""));page=int(state.get("page",0));_refresh()
