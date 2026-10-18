extends VBoxContainer
## Compact equipment catalogue. Opening it never replaces the working lines.
const Folio=preload("res://scripts/hud/production_folio.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Plain=preload("res://scripts/hud/production_plain.gd")
const Industrial=preload("res://scripts/hud/production_skin.gd")
const Ledger=preload("res://scripts/equipment_ledger.gd")
var screen:Node
var cards:Dictionary={}
var readings:Dictionary={}
var room:Label
var _recipes:Array=[]
var _page:=0
var _query:=""
var _grid:GridContainer
var _counter:Label
var _previous:Button
var _next:Button

func build(owner_screen:Node,recipes:Array,note:String)->void:
	screen=owner_screen;name="Picker";add_theme_constant_override("separation",4)
	_recipes=recipes
	room=_label(self,"");room.name="Room"
	if recipes.size()>6:
		var search:=LineEdit.new();search.placeholder_text="Find equipment";add_child(search);search.text_changed.connect(func(value:String):_query=value;_page=0;_show_page())
	var scroll:=ScrollContainer.new();scroll.name="EquipmentChoices"
	scroll.custom_minimum_size.y=minf(150,recipes.size()*72.0)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
	_grid=GridContainer.new();_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_grid.add_theme_constant_override("v_separation",2);scroll.add_child(_grid)
	resized.connect(func():_grid.columns=2 if size.x>=900 else 1)
	for recipe:Dictionary in recipes:
		var item:=String(recipe.item)
		var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",Industrial.flat(Color("30372d"),Industrial.EDGE,1,0,4));panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_grid.add_child(panel)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);panel.add_child(row)
		var picture:=TextureRect.new();picture.texture=Folio.product_texture(item);picture.custom_minimum_size=Vector2(44,40);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(picture)
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",1);row.add_child(text)
		var title:=_label(text,String(recipe.name));title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		var needs:=_label(text,_needs(recipe));needs.name="MaterialsForOne";needs.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		var kit:=Ledger.row(item)
		if not kit.is_empty():_label(text,"Attack %.1f · Defense %.1f · Armour %.1f" % [float(kit.get("attack",0)),float(kit.get("defense",0)),float(kit.get("armor",0))])
		var action:=Button.new();action.name="Recipe_"+item;action.custom_minimum_size=Vector2(90,28);row.add_child(action);cards[item]=action
		action.pressed.connect(func():screen.act(0,"start",0.0,item))
		var reason:=_label(text,"");reason.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		readings[item]={"needs":needs,"reason":reason,"panel":panel}
	if recipes.is_empty():_label(self,"No equipment designs known yet.")
	var pager:=HBoxContainer.new();pager.visible=recipes.size()>6;add_child(pager)
	_previous=Button.new();_previous.text="Previous";pager.add_child(_previous);_previous.pressed.connect(func():_page-=1;_show_page())
	_counter=_label(pager,"")
	_next=Button.new();_next.text="Next";pager.add_child(_next);_next.pressed.connect(func():_page+=1;_show_page())
	apply(recipes,note)
	_show_page()

func apply(recipes:Array,note:String)->void:
	room.text="No free lines · close an existing line to add another" if note=="ALL LINES BUSY" else note.to_lower()+" lines available"
	for recipe:Dictionary in recipes:
		var item:=String(recipe.item);var action:Button=cards.get(item)
		if action==null:continue
		var blocker:=String(recipe.get("blocker",""));var running:=bool(recipe.get("running",false))
		action.disabled=running or not blocker.is_empty()
		action.text="Producing" if running else "Unavailable" if not blocker.is_empty() else "+ Produce"
		var why:="Already on the board. Adjust its makers below." if running else String(recipe.get("blocker_full",blocker)) if not blocker.is_empty() else "Start a line; keep %d in store." % int(recipe.get("start_target",10))
		var tip:=String(recipe.name)+": "+String(recipe.get("description",""))+"\n"+String(Ledger.card_words(item))+"\n"+_needs(recipe)+"\n"+why
		action.tooltip_text=tip;readings[item].panel.tooltip_text=tip
		readings[item].needs.text=_needs(recipe)
		readings[item].reason.text=blocker;readings[item].reason.visible=not blocker.is_empty() and not running

func _label(parent:Node,text:String)->Label:
	var label:=T.make_label(text,13,Industrial.INK);parent.add_child(label);return label

func _needs(recipe:Dictionary)->String:
	var parts:PackedStringArray=[]
	for material:Dictionary in recipe.get("materials",[]):parts.append("%s %s" % [Plain.number(float(material.amount)),String(material.get("name",ResourceSystem.display_name(String(material.resource)))).to_lower()])
	return ", ".join(parts)+" / unit" if not parts.is_empty() else String(recipe.get("needs","No materials"))

func _show_page()->void:
	var matches:Array=_recipes.filter(func(recipe:Dictionary)->bool:return _query.is_empty() or _query.to_lower() in String(recipe.name).to_lower())
	_page=clampi(_page,0,maxi(0,ceili(float(matches.size())/6)-1))
	for key:String in readings:readings[key].panel.visible=false
	for recipe:Dictionary in matches.slice(_page*6,(_page+1)*6):readings[String(recipe.item)].panel.visible=true
	_counter.text="%d–%d of %d" % [_page*6+1,mini((_page+1)*6,matches.size()),matches.size()] if not matches.is_empty() else "No matching equipment"
	_previous.disabled=_page==0;_next.disabled=(_page+1)*6>=matches.size()
