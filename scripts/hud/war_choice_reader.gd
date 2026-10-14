extends VBoxContainer
## A bounded index of fronts or commanders and one complete existing card.
## Selection and browsing belong to this view; all orders stay in the card.
const T=preload("res://scripts/hud/hud_tokens.gd")
const PAGE_SIZE:=4
const SIDE_AT:=700.0
var records:Array=[]
var selected_id:=""
var query:=""
var page:=0
var choosing:=false
var noun:="front"
var build_card:Callable
var pick:Button
var back:Button
var search:LineEdit
var layout:HBoxContainer
var index:VBoxContainer
var choices:VBoxContainer
var reader:VBoxContainer
var count:Label
var previous:Button
var next:Button
var page_label:Label

func setup(kind:String,builder:Callable)->void:
	noun=kind;build_card=builder
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	pick=_button("Choose %s" % noun);pick.name="ChooseRecord";add_child(pick)
	pick.pressed.connect(func()->void:choosing=true;_layout())
	layout=HBoxContainer.new();layout.size_flags_horizontal=Control.SIZE_EXPAND_FILL;layout.add_theme_constant_override("separation",16);add_child(layout)
	index=VBoxContainer.new();index.name="ChoiceIndex";index.add_theme_constant_override("separation",8);layout.add_child(index)
	var heading:=HBoxContainer.new();heading.add_theme_constant_override("separation",8);index.add_child(heading)
	count=_label("",14,T.INK_MUTED);count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(count)
	back=_button("Back");back.name="BackToRecord";back.tooltip_text="Back to selected %s" % noun;heading.add_child(back)
	back.pressed.connect(func()->void:choosing=false;_layout())
	search=LineEdit.new();search.name="ChoiceSearch";search.placeholder_text="Find a %s…" % noun;search.custom_minimum_size.y=40;index.add_child(search)
	search.text_changed.connect(func(value:String)->void:query=value;page=0;_refresh_choices())
	choices=VBoxContainer.new();choices.name="Choices";choices.add_theme_constant_override("separation",6);index.add_child(choices)
	var pager:=HBoxContainer.new();pager.add_theme_constant_override("separation",6);index.add_child(pager)
	previous=_button("←");previous.name="PreviousChoices";pager.add_child(previous)
	previous.pressed.connect(func()->void:page=maxi(0,page-1);_refresh_choices())
	page_label=_label("",14,T.INK_MUTED);page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;pager.add_child(page_label)
	next=_button("→");next.name="NextChoices";pager.add_child(next)
	next.pressed.connect(func()->void:page+=1;_refresh_choices())
	reader=VBoxContainer.new();reader.name="SelectedRecord";reader.size_flags_horizontal=Control.SIZE_EXPAND_FILL;layout.add_child(reader)
	resized.connect(_layout)
	_layout()

func set_records(next_records:Array)->void:
	records=next_records
	if not records.any(func(item:Dictionary)->bool:return String(item.id)==selected_id):
		selected_id=String(records[0].id) if not records.is_empty() else ""
	_refresh_choices();_refresh_reader();_layout()

func matches()->Array:
	return records.filter(func(item:Dictionary)->bool:
		return query.strip_edges().is_empty() or (String(item.title)+" "+String(item.get("subtitle",""))).to_lower().contains(query.strip_edges().to_lower()))

func select(id:String)->void:
	selected_id=id;choosing=false
	_refresh_choices();_refresh_reader();_layout()

func reveal(id:String)->bool:
	for i in records.size():
		if String(records[i].id)!=id:continue
		query="";search.text="";page=i/PAGE_SIZE
		select(id);return true
	return false

func _refresh_choices()->void:
	for child in choices.get_children():choices.remove_child(child);child.queue_free()
	var found:=matches()
	var pages:=maxi(1,ceili(float(found.size())/PAGE_SIZE))
	page=clampi(page,0,pages-1)
	count.text="%d %s%s" % [found.size(),noun,"s" if found.size()!=1 else ""] if query.strip_edges().is_empty() else "%d matching" % found.size()
	for i in range(page*PAGE_SIZE,mini(found.size(),(page+1)*PAGE_SIZE)):
		var item:Dictionary=found[i]
		var button:=_button(String(item.title)+"\n"+String(item.get("subtitle","")))
		button.name="Choice_%s" % String(item.id);button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.set_meta("choice_title",String(item.title));button.set_meta("choice_subtitle",String(item.get("subtitle","")))
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y=66
		button.toggle_mode=true;button.set_pressed_no_signal(String(item.id)==selected_id)
		T.apply_button_style(button,String(item.id)==selected_id)
		button.pressed.connect(select.bind(String(item.id)));choices.add_child(button)
	if found.is_empty():choices.add_child(_label("No matching %ss." % noun,16,T.INK_MUTED))
	previous.disabled=page==0;next.disabled=page+1>=pages
	page_label.text="%d / %d" % [page+1,pages]
	previous.get_parent().visible=pages>1
	_layout()

func _refresh_reader()->void:
	for child in reader.get_children():reader.remove_child(child);child.queue_free()
	for item:Dictionary in records:
		if String(item.id)==selected_id:
			reader.add_child(build_card.call(item.payload));break

func _layout()->void:
	if index==null:return
	var side:=size.x>=SIDE_AT
	var multiple:=records.size()>1
	pick.visible=multiple and not side and not choosing
	pick.text="Choose %s · %d" % [noun,records.size()]
	back.visible=not side and choosing
	index.visible=multiple and (side or choosing)
	reader.visible=side or not choosing or not multiple
	index.custom_minimum_size.x=228 if side else 0
	index.size_flags_horizontal=Control.SIZE_FILL if side else Control.SIZE_EXPAND_FILL
	index.size_flags_stretch_ratio=0.0 if side else 1.0
	for child in choices.get_children():
		if child is Button:
			child.custom_minimum_size.y=66 if side else 52
			child.text=String(child.get_meta("choice_title"))+("\n" if side else " · ")+String(child.get_meta("choice_subtitle"))

func _button(words:String)->Button:
	var button:=Button.new();button.text=words;T.apply_button_style(button)
	button.add_theme_font_size_override("font_size",14);return button

func _label(words:String,points:int,ink:Color)->Label:
	var label:=Label.new();label.text=words;label.add_theme_font_override("font",T.font("ui"));label.add_theme_font_size_override("font_size",points);label.add_theme_color_override("font_color",ink);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return label
