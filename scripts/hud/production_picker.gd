extends VBoxContainer
## Browse products without creating an order until its concrete action is chosen.
const Folio=preload("res://scripts/hud/production_folio.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Plain=preload("res://scripts/hud/production_plain.gd")
const Ledger=preload("res://scripts/equipment_ledger.gd")
const GROUP_NAMES={"weapons":"Weapons","ammunition":"Ammunition","carts":"Carts","boats":"Boats","aircraft":"Aircraft"}
var screen:Node
var cards:Dictionary={}
var readings:Dictionary={}
var room:Label
var browser:Control

func build(owner_screen:Node,recipes:Array,note:String)->void:
	screen=owner_screen;name="Picker";add_theme_constant_override("separation",8)
	room=_label(self,"",15,T.INK_MUTED);room.name="Room"
	browser=screen._selection(self,"recipes",6)
	for recipe:Dictionary in recipes:
		var item:=String(recipe.item)
		var content:=VBoxContainer.new();content.add_theme_constant_override("separation",10)
		browser.add_record(item,String(recipe.name),String(GROUP_NAMES.get(String(recipe.category),String(recipe.category).capitalize())),content)
		var lead:=HBoxContainer.new();lead.add_theme_constant_override("separation",14);content.add_child(lead)
		var picture:=TextureRect.new();picture.texture=Folio.product_texture(item);picture.custom_minimum_size=Vector2(80,80);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;lead.add_child(picture)
		var title:=_label(lead,String(recipe.name),25,T.INK);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_label(content,String(recipe.get("description","")),17,T.INK)
		var stats:=String(Ledger.card_words(item));if not stats.is_empty():_label(content,stats,15,T.INK_MUTED)
		var needs:=_label(content,_needs(recipe),16,T.INK);needs.name="MaterialsForOne"
		var condition:=_label(content,"",15,T.AMBER_TEXT)
		var action:=Button.new();action.name="Recipe_"+item;action.custom_minimum_size.y=44;T.apply_button_style(action,true);content.add_child(action);cards[item]=action
		action.pressed.connect(func():screen.act(0,"start",0.0,item))
		content.move_child(condition,content.get_child_count()-1)
		readings[item]={"condition":condition,"needs":needs}
	if recipes.is_empty():_label(self,"Your people know no workshop crafts yet.",16,T.INK_MUTED)
	browser.refresh();apply(recipes,note)

func apply(recipes:Array,note:String)->void:
	room.text="Every workshop line is in use. Review a current order to free a place." if note=="ALL LINES BUSY" else note.to_lower()+" workshop places · choose a product to see what it makes and what it needs"
	for recipe:Dictionary in recipes:
		var item:=String(recipe.item);var action:Button=cards.get(item)
		if action==null:continue
		var blocker:=String(recipe.get("blocker",""));var running:=bool(recipe.get("running",false));var deficit:=int(recipe.get("deficit",0))
		action.disabled=running or not blocker.is_empty()
		action.text="Already in production" if running else "Start line · keep %d in store" % int(recipe.get("start_target",10))
		var why:="A line already makes this. Give it more hands on Current orders." if running else String(recipe.get("blocker_full",blocker)) if not blocker.is_empty() else "The line rests when its stock target is filled and resumes when goods are used."
		var why_full:=why
		if blocker=="No free line" and not String(recipe.get("capacity_note","")).is_empty():why=why.trim_prefix(String(recipe.capacity_note)).strip_edges()
		readings[item].condition.visible=not why.is_empty() or deficit>0
		readings[item].condition.text=("The bands are %d short. " % deficit if deficit>0 else "")+why
		readings[item].needs.text=_needs(recipe)
		action.tooltip_text=String(recipe.name)+": "+String(recipe.get("description",""))+"\n"+_needs(recipe)+"\n"+why_full
		browser.update_record(item,String(recipe.name),"Making" if running else blocker if not blocker.is_empty() else "%d short" % deficit if deficit>0 else String(GROUP_NAMES.get(String(recipe.category),String(recipe.category).capitalize())))

func _label(parent:Node,text:String,points:int,color:Color)->Label:
	var label:=T.make_label(text,points,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label);return label

func _needs(recipe:Dictionary)->String:
	var parts:PackedStringArray=[]
	for material:Dictionary in recipe.get("materials",[]):parts.append("%s %s" % [Plain.number(float(material.amount)),String(material.get("name",ResourceSystem.display_name(String(material.resource)))).to_lower()])
	return "Each needs "+", ".join(parts) if not parts.is_empty() else String(recipe.get("needs","Needs no materials"))
