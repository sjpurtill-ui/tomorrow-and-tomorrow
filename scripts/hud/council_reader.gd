extends VBoxContainer
## One official and one open order, with searchable bounded native choosers.
## Every action is supplied unchanged by the civilization presentation provider.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const UI:=preload("res://scripts/hud/world_ui.gd")
var model:Dictionary={}
var view:Dictionary={}
var columns:BoxContainer
var person_reader:VBoxContainer
var order_reader:VBoxContainer
var people_picker:OptionButton
var order_picker:OptionButton
var people_count:Label
var order_count:Label
var order_heading:Label
var people_search:LineEdit
var order_search:LineEdit

func setup(block:Dictionary)->void:
	name="CouncilReader";size_flags_horizontal=Control.SIZE_EXPAND_FILL;add_theme_constant_override("separation",16);_take(block)
	columns=BoxContainer.new();columns.add_theme_constant_override("separation",24);columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL;add_child(columns)
	var people:=VBoxContainer.new();people.name="Officials";people.size_flags_horizontal=Control.SIZE_EXPAND_FILL;people.add_theme_constant_override("separation",10);columns.add_child(people)
	UI.label(people,"People you can call",22,T.INK,true)
	people_count=UI.label(people,"",14,T.INK_MUTED)
	people_search=_search(people,"FindOfficial","Find a name or office")
	people_picker=_picker(people,"ChooseOfficial")
	person_reader=VBoxContainer.new();person_reader.name="SelectedOfficial";person_reader.add_theme_constant_override("separation",10);people.add_child(person_reader)
	var orders:=VBoxContainer.new();orders.name="Orders";orders.size_flags_horizontal=Control.SIZE_EXPAND_FILL;orders.add_theme_constant_override("separation",10);columns.add_child(orders)
	order_heading=UI.label(orders,"Orders still open",22,T.INK,true)
	order_count=UI.label(orders,"",14,T.INK_MUTED)
	order_search=_search(orders,"FindOrder","Find an order")
	order_picker=_picker(orders,"ChooseOrder")
	order_reader=VBoxContainer.new();order_reader.name="SelectedOrder";order_reader.add_theme_constant_override("separation",10);orders.add_child(order_reader)
	people_search.text_changed.connect(func(text:String):view.query=text;_people())
	people_picker.item_selected.connect(func(index:int):view.person=String(people_picker.get_item_metadata(index));_person())
	order_search.text_changed.connect(func(text:String):view.order_query=text;_orders())
	order_picker.item_selected.connect(func(index:int):view.order=String(order_picker.get_item_metadata(index));_order())
	resized.connect(_layout);_people();_orders();_layout.call_deferred()

func _take(block:Dictionary)->void:
	model=block
	var given:Variant=block.get("view");view=given if given is Dictionary else {}
	for key in ["person","query","order","order_query"]:
		if not view.has(key):view[key]=""

func update_block(block:Dictionary)->bool:
	_take(block);_people();_orders();_layout();return true

func _layout()->void:
	if not is_inside_tree():return
	columns.vertical=size.x<720 or model.get("orders",[]).is_empty()

func _search(parent:Node,node_name:String,hint:String)->LineEdit:
	var input:=LineEdit.new();input.name=node_name;input.placeholder_text=hint;input.custom_minimum_size.y=40;input.size_flags_horizontal=Control.SIZE_EXPAND_FILL;input.add_theme_font_size_override("font_size",16);parent.add_child(input);return input

func _picker(parent:Node,node_name:String)->OptionButton:
	var picker:=OptionButton.new();picker.name=node_name;picker.fit_to_longest_item=false;picker.clip_text=true;T.apply_button_style(picker);picker.custom_minimum_size.x=120;picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;picker.get_popup().max_size.y=320;parent.add_child(picker);return picker

func _people()->void:
	if people_search.text!=String(view.query):people_search.text=String(view.query)
	people_search.visible=model.get("people",[]).size()>8 or String(view.query)!=""
	people_picker.clear();var matches:Array=[]
	for row:Dictionary in model.get("people",[]):
		if String(view.query)=="" or (String(row.cells.name)+" "+String(row.cells.title)+" "+String(row.group)).to_lower().contains(String(view.query).to_lower()):matches.append(row)
	if String(view.person)=="" and not matches.is_empty():
		view.person=String(matches[0].id)
		for row:Dictionary in matches:
			if int(row.get("matters",0))>0:view.person=String(row.id);break
	var found:=false
	for row:Dictionary in matches:
		people_picker.add_item(String(row.cells.name)+" · "+String(row.cells.title).get_slice("\n",0));var i:=people_picker.item_count-1;people_picker.set_item_metadata(i,String(row.id))
		if String(row.id)==String(view.person):people_picker.select(i);found=true
	people_count.text="%d matching of %d people" % [matches.size(),model.get("people",[]).size()] if String(view.query)!="" else "%d people available" % model.get("people",[]).size()
	if not found:
		people_picker.select(-1);people_picker.text="Choose a matching official" if not matches.is_empty() else "No matching officials"
	person_reader.visible=found;_person()

func _person()->void:
	UI.clear(person_reader)
	for row:Dictionary in model.get("people",[]):
		if String(row.id)!=String(view.person):continue
		person_reader.visible=true
		var identity:=HBoxContainer.new();identity.add_theme_constant_override("separation",12);person_reader.add_child(identity)
		var face:=TextureRect.new();face.texture=row.get("icon");face.custom_minimum_size=Vector2(64,72);face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;identity.add_child(face)
		var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.add_child(words)
		UI.label(words,String(row.cells.name),24,T.INK,true,true)
		UI.label(words,String(row.get("office",row.cells.title)),16,T.BODY,false,true)
		UI.label(person_reader,String(row.get("place","")),14,T.INK_MUTED,false,true)
		var regard:=HFlowContainer.new();regard.add_theme_constant_override("h_separation",14);person_reader.add_child(regard)
		UI.label(regard,String(row.get("read","Not yet read")).left(1).to_upper()+String(row.get("read","Not yet read")).substr(1),16,T.INK)
		UI.label(regard,"Love %d · dread %d in 100" % [roundi(float(row.get("love",0.5))*100),roundi(float(row.get("dread",0.2))*100)],14,T.INK_MUTED)
		if int(row.get("matters",0))>0:UI.label(person_reader,"%d %s to raise" % [int(row.matters),"matter" if int(row.matters)==1 else "matters"],16,T.AMBER_TEXT)
		var button:=UI.verb(person_reader,"Summon",row.button.on_press,String(row.button.get("tip","")),true);button.name="Summon";button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		break
	# A search with no matching selected official must not show stale evidence.
	person_reader.visible=people_picker.selected>=0

func _orders()->void:
	if order_search.text!=String(view.order_query):order_search.text=String(view.order_query)
	order_picker.clear();var entries:Array=model.get("orders",[])
	if String(view.order)=="" and not entries.is_empty():view.order=String(entries[0].id)
	for row:Dictionary in entries:
		if String(view.order_query)!="" and not (String(row.label)+" "+String(row.value)).to_lower().contains(String(view.order_query).to_lower()):continue
		order_picker.add_item(String(row.label));var i:=order_picker.item_count-1;order_picker.set_item_metadata(i,String(row.id))
		if String(row.id)==String(view.order):order_picker.select(i)
	var matches:=order_picker.item_count
	var found:=false
	for index in matches:
		if String(order_picker.get_item_metadata(index))==String(view.order):order_picker.select(index);found=true;break
	if not found:order_picker.select(-1);order_picker.text="Choose a matching order" if matches>0 else "No matching orders"
	order_count.text="%d matching of %d orders" % [matches,entries.size()] if String(view.order_query)!="" else "%d open orders" % entries.size()
	order_heading.visible=not entries.is_empty();order_count.visible=not entries.is_empty()
	order_picker.visible=not entries.is_empty();order_search.visible=entries.size()>8 or String(view.order_query)!="";_order()
	if entries.is_empty():UI.label(order_reader,"No open orders.",16,T.INK_MUTED,false,true);order_reader.visible=true

func _order()->void:
	UI.clear(order_reader)
	for row:Dictionary in model.get("orders",[]):
		if String(row.id)!=String(view.order):continue
		UI.label(order_reader,String(row.value),14,T.AMBER_TEXT if String(row.get("tone",""))=="bad" else T.INK_MUTED)
		UI.label(order_reader,String(row.label),18,T.INK,true,true).tooltip_text=String(row.get("tip",""))
		var button:=UI.verb(order_reader,"Discuss at court",row.on_click,String(row.get("tip","")));button.name="DiscussOrder";button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		break
	order_reader.visible=order_picker.selected>=0
