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

func build(owner_screen:Node,recipes:Array,note:String)->void:
	screen=owner_screen;name="Picker";add_theme_constant_override("separation",4)
	room=_label(self,"");room.name="Room"
	var scroll:=ScrollContainer.new();scroll.name="EquipmentChoices"
	scroll.custom_minimum_size.y=minf(210,recipes.size()*58.0)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",2);scroll.add_child(list)
	for recipe:Dictionary in recipes:
		var item:=String(recipe.item)
		var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",Industrial.flat(Color("30372d"),Industrial.EDGE,1,0,4));list.add_child(panel)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);panel.add_child(row)
		var picture:=TextureRect.new();picture.texture=Folio.product_texture(item);picture.custom_minimum_size=Vector2(44,40);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(picture)
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",1);row.add_child(text)
		var title:=_label(text,String(recipe.name));title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		var needs:=_label(text,_needs(recipe));needs.name="MaterialsForOne";needs.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		var action:=Button.new();action.name="Recipe_"+item;action.custom_minimum_size=Vector2(90,28);row.add_child(action);cards[item]=action
		action.pressed.connect(func():screen.act(0,"start",0.0,item))
		readings[item]={"needs":needs,"panel":panel}
	if recipes.is_empty():_label(self,"No equipment designs known yet.")
	apply(recipes,note)

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

func _label(parent:Node,text:String)->Label:
	var label:=T.make_label(text,13,Industrial.INK);parent.add_child(label);return label

func _needs(recipe:Dictionary)->String:
	var parts:PackedStringArray=[]
	for material:Dictionary in recipe.get("materials",[]):parts.append("%s %s" % [Plain.number(float(material.amount)),String(material.get("name",ResourceSystem.display_name(String(material.resource)))).to_lower()])
	return ", ".join(parts)+" / unit" if not parts.is_empty() else String(recipe.get("needs","No materials"))
