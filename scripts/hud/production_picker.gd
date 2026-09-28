extends VBoxContainer
## The equipment cards that start a new line (HOI4's right-hand picker): one
## card per product the people know how to make, grouped by kind, each with
## its mark, name, materials for one item and who it arms. Clicking a card
## starts a line; a card that cannot start says why in a few words, and in
## full in its tooltip. Built once per shape; apply() refreshes in place.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const GROUP_NAMES:={"weapons":"Weapons","ammunition":"Ammunition","carts":"Carts","boats":"Boats","aircraft":"Aircraft"}

var screen:Node
var cards:Dictionary={}
var room:Label

func build(owner_screen:Node,recipes:Array,note:String)->void:
	screen=owner_screen;name="Picker"
	add_theme_constant_override("separation",6)
	var head:=HBoxContainer.new();add_child(head)
	var kicker:=Label.new();kicker.text="START A LINE";T.text(kicker,"kicker",T.GOLD_TEXT);kicker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(kicker)
	room=Label.new();room.name="Room";T.text(room,"kicker",T.INK_MUTED);head.add_child(room)
	var rule:=ColorRect.new();rule.color=T.RULE;rule.custom_minimum_size.y=1;add_child(rule)
	if recipes.is_empty():
		var none:=Label.new();none.text="Your people know no workshop crafts yet.";T.text(none,"small",T.INK_MUTED);none.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(none)
	var group:=""
	for recipe:Dictionary in recipes:
		if String(recipe.category)!=group:
			group=String(recipe.category)
			var heading:=Label.new();heading.text=String(GROUP_NAMES.get(group,group.capitalize()));T.text(heading,"small",T.INK_MUTED)
			heading.add_theme_font_override("font",T.font("ui_strong"));add_child(heading)
		var card:=_card(recipe);add_child(card);cards[String(recipe.item)]=card
	apply(recipes,note)

func apply(recipes:Array,note:String)->void:
	room.text=note
	for recipe:Dictionary in recipes:
		var card:Button=cards.get(String(recipe.item))
		if card==null:continue
		var blocker:=String(recipe.get("blocker",""))
		var running:=bool(recipe.get("running",false))
		card.disabled=running or not blocker.is_empty()
		var tag:Label=card.find_child("Tag",true,false)
		# "No free line" is said once, above the cards; the card only dims. A
		# kind the bands are short of, with no line making it, says so.
		var deficit:=int(recipe.get("deficit",0))
		tag.text="Making" if running else ("" if blocker.is_empty() or blocker=="No free line" else blocker)
		if tag.text.is_empty() and deficit>0 and not running:tag.text="%d short" % deficit
		tag.visible=not tag.text.is_empty()
		tag.add_theme_color_override("font_color",T.GREEN_TEXT if running else T.RED_TEXT)
		var name_label:Label=card.find_child("Title",true,false)
		name_label.add_theme_color_override("font_color",T.INK if not card.disabled or running else T.INK_MUTED)
		var tip:PackedStringArray=[String(recipe.name)+": "+String(recipe.get("description",""))]
		tip.append(String(recipe.get("needs","")))
		if int(recipe.get("deficit",0))>0 and not running:tip.append("The bands are %d short of these." % int(recipe.deficit))
		if running:tip.append("A line already makes this. Give it more hands instead.")
		elif not blocker.is_empty():tip.append(String(recipe.get("blocker_full",blocker)))
		else:tip.append("Click to start a line that keeps %d in store." % int(recipe.get("start_target",10)))
		card.tooltip_text="\n".join(tip)

func _card(recipe:Dictionary)->Button:
	var card:=Button.new();card.name="Recipe_"+String(recipe.item);card.focus_mode=Control.FOCUS_NONE
	card.custom_minimum_size=Vector2(0,62);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var normal:=T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD)
	var hover:=T.flat(T.HOVER_BG,T.GOLD,1,T.RADIUS_CARD)
	var off:=T.flat(T.PAPER,T.BORDER_SOFT,1,T.RADIUS_CARD)
	card.add_theme_stylebox_override("normal",normal);card.add_theme_stylebox_override("hover",hover)
	card.add_theme_stylebox_override("pressed",T.button_pressed_style());card.add_theme_stylebox_override("disabled",off)
	card.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	var item:=String(recipe.item)
	card.pressed.connect(func():screen.act(0,"start",0.0,item))
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for side:String in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,8 if side in ["left","right"] else 6)
	card.add_child(margin)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;margin.add_child(row)
	var mark:=TextureRect.new();mark.texture=Icons.equipment_texture(item,T.INK,T.GOLD,64);mark.custom_minimum_size=Vector2(40,40)
	mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(mark)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",1);words.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(words)
	var top:=HBoxContainer.new();top.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(top)
	var title:=Label.new();title.name="Title";title.text=String(recipe.name);T.text(title,"small",T.INK);title.add_theme_font_override("font",T.font("ui_strong"))
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.clip_text=true;title.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(title)
	var tag:=Label.new();tag.name="Tag";T.text(tag,"kicker",T.RED_TEXT);tag.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(tag)
	var cost:=HBoxContainer.new();cost.name="Cost";cost.add_theme_constant_override("separation",3);cost.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(cost)
	var shown:=0
	for material:Dictionary in recipe.get("materials",[]):
		if shown>=4:break
		shown+=1
		var icon:=TextureRect.new();icon.texture=Icons.material_texture(String(material.resource),32);icon.custom_minimum_size=Vector2(16,16)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;cost.add_child(icon)
		var amount:=Label.new();amount.text=Plain.number(float(material.amount));T.text(amount,"kicker",T.BODY);amount.mouse_filter=Control.MOUSE_FILTER_IGNORE;cost.add_child(amount)
		var gap:=Control.new();gap.custom_minimum_size.x=4;gap.mouse_filter=Control.MOUSE_FILTER_IGNORE;cost.add_child(gap)
	var arms:=Label.new();arms.name="Arms";arms.text=String(recipe.get("arms",""));T.text(arms,"kicker",T.INK_MUTED);arms.clip_text=true;arms.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(arms)
	arms.visible=not arms.text.is_empty()
	return card
