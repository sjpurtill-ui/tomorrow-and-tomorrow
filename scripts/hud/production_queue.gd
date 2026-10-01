extends VBoxContainer
## The Production screen, laid out the way HOI4 lays out production: a strip
## of materials (with their daily trend) and workshop hands, a strip of
## equipment in store against what the bands need, then the numbered lines
## (order is priority) beside the cards that start a new line. Numbers and
## marks on the surface; every sentence is in a tooltip. Household goods (the
## civilian crafts) follow as compact rows.
##
## Reads the block the production provider builds; every control calls the
## provider's actions through act(). The screen is built once per shape (which
## lines, cards and chips exist) and refreshed in place by update_block, so the
## daily refresh never closes a tooltip or resets a scroll.
##
## Other dock panels extend this script for _button, _bar and _rule; keep those
## three helpers, T, Art and data unchanged.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Art:=preload("res://scripts/hud/production_art.gd")
const P:=preload("res://scripts/persistent_production.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const W:=preload("res://scripts/hud/production_widgets.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const LineRow:=preload("res://scripts/hud/production_line_row.gd")
const Picker:=preload("res://scripts/hud/production_picker.gd")
const Names:=preload("res://scripts/era_names.gd")
const PICKER_WIDTH:=300.0
const LINES_MIN_WIDTH:=560.0
var data:Dictionary
var _shape:=""
var _rows:={}
var _stock_chips:={}
var _material_chips:={}
var _household_rows:={}
var _technique_chips:={}
var _picker:Node
var _header:Dictionary={}

func setup(block:Dictionary)->void:
	theme=T.control_theme();name="IllustratedProductionQueue"
	add_theme_constant_override("separation",14)
	data=_prepared(block)
	_shape=shape_key(data)
	var mode:=String(data.get("mode","military"))
	if mode!="civilian":
		_build_header()
		_build_stock()
		var columns:=HFlowContainer.new();columns.name="Columns";columns.add_theme_constant_override("h_separation",16);columns.add_theme_constant_override("v_separation",16);add_child(columns)
		var left:=VBoxContainer.new();left.name="LinesColumn";left.add_theme_constant_override("separation",14)
		left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.custom_minimum_size.x=LINES_MIN_WIDTH;columns.add_child(left)
		_build_lines(left)
		if mode!="military":_build_households(left,false)
		_picker=Picker.new();_picker.custom_minimum_size.x=PICKER_WIDTH;_picker.size_flags_horizontal=Control.SIZE_FILL;columns.add_child(_picker)
		_picker.build(self,data.get("recipes",[]),_room_note())
		_build_footer()
	else:
		_build_households(self,true)
	_apply()

## True when the new block has the same lines, chips and cards: the screen
## then updates its numbers in place and keeps what the player is hovering.
func update_block(block:Dictionary)->bool:
	if _shape.is_empty() or name!="IllustratedProductionQueue":return false
	var next:=_prepared(block)
	if shape_key(next)!=_shape:return false
	data=next;_apply()
	return true

static func shape_key(block:Dictionary)->String:
	var parts:PackedStringArray=[String(block.get("mode","military"))]
	for line:Dictionary in block.get("lines",[]):parts.append("L%d:%s:%s:%s" % [int(line.get("id",0)),str(bool(line.get("ship",false))),str(bool(line.get("persistent",false))),str(bool(line.get("auto",false)))])
	for recipe:Dictionary in block.get("recipes",[]):parts.append("R"+String(recipe.get("item","")))
	for row:Dictionary in block.get("stock",[]):parts.append("S"+String(row.get("item","")))
	for material:Dictionary in block.get("materials",[]):parts.append("M"+String(material.get("resource","")))
	for city:Dictionary in block.get("households",[]):parts.append("H"+String(city.get("id","")))
	for technique:Dictionary in block.get("techniques",[]):parts.append("T"+String(technique.get("id","")))
	parts.append("B%d" % int(block.get("boatyards",0)))
	parts.append("O"+str(not Plain.officer(String(block.get("owner",""))).is_empty()))
	return "|".join(parts)

## Lines may arrive as raw snapshot lines (tests, older callers): read them
## into row views here so the screen always draws the same way.
func _prepared(block:Dictionary)->Dictionary:
	var result:=block.duplicate()
	var lines:Array=[]
	var raw:Array=block.get("lines",[])
	for index in raw.size():
		var line:Dictionary=raw[index]
		var view:=line if line.has("look") else Plain.line_view(line,block.get("context",{}),{"name":P.product_name(String(line.get("item",""))),"owner":String(block.get("owner",""))})
		if not line.has("look"):view=view.duplicate();view.rank=index+1;view.count=raw.size()
		lines.append(view)
	result.lines=lines
	return result

# --- Actions ----------------------------------------------------------------------

func act(id:int,action:String,value:float,item:String="")->void:
	match action:
		"start":
			var start:Variant=data.get("on_start")
			if start is Callable:start.call(item)
		"detail":
			var detail:Variant=data.get("on_detail")
			if detail is Callable:detail.call(id)
		_:
			var callback:Variant=data.get("on_action")
			if callback is Callable:callback.call(id,action,value)

func _header_act(kind:String)->void:
	var callback:Variant=data.get("on_header")
	if callback is Callable:callback.call(kind)

# --- Header strip: materials, hands, lines, boatyards, who runs it -----------------

func _build_header()->void:
	var strip:=PanelContainer.new();strip.name="Header"
	var style:=T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CARD);style.content_margin_left=12;style.content_margin_right=10;style.content_margin_top=6;style.content_margin_bottom=6
	strip.add_theme_stylebox_override("panel",style);add_child(strip)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);strip.add_child(row)
	var materials:=HFlowContainer.new();materials.name="Materials";materials.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	materials.add_theme_constant_override("h_separation",16);materials.add_theme_constant_override("v_separation",4);row.add_child(materials)
	for material:Dictionary in data.get("materials",[]):
		var chip:=_fact(materials,Icons.material_texture(String(material.resource),44),"Material_"+String(material.resource))
		_material_chips[String(material.resource)]=chip
	if data.get("materials",[]).is_empty():
		var none:=Label.new();none.text="No materials in store";T.text(none,"small",T.INK_MUTED);materials.add_child(none)
	var rule:=VSeparator.new();rule.add_theme_color_override("color",T.RULE);row.add_child(rule)
	var workshop:=HBoxContainer.new();workshop.name="Workshop";workshop.add_theme_constant_override("separation",14);row.add_child(workshop)
	_header.hands=_fact(workshop,null,"Hands","HANDS")
	_header.lines=_fact(workshop,null,"LineSlots","LINES")
	if int(data.get("boatyards",0))>0:_header.boatyards=_fact(workshop,null,"Boatyards","BOATYARDS")
	var run:=HBoxContainer.new();run.name="RunBy";run.add_theme_constant_override("separation",0);run.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(run)
	var run_word:=Label.new();run_word.text="RUN BY";T.text(run_word,"kicker",T.INK_MUTED);run_word.size_flags_vertical=Control.SIZE_SHRINK_CENTER;run.add_child(run_word)
	var run_gap:=Control.new();run_gap.custom_minimum_size.x=6;run.add_child(run_gap)
	_header.staff=W.text_button("Staff","");_header.staff.name="RunStaff";run.add_child(_header.staff)
	_header.staff.pressed.connect(func():_header_act("hand_back"))
	_header.you=W.text_button("You","");_header.you.name="RunYou";run.add_child(_header.you)
	_header.you.pressed.connect(func():_header_act("take_over"))
	var note:=Label.new();note.name="StaffNote";T.text(note,"small",T.INK_MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.mouse_filter=Control.MOUSE_FILTER_PASS;add_child(note)
	_header.note=note

func _fact(parent:Node,texture:Texture2D,node_name:String,word:String="")->HBoxContainer:
	## A mark (an icon, or a small word), a value and a trend or total beside it.
	var box:=HBoxContainer.new();box.name=node_name;box.add_theme_constant_override("separation",5);box.mouse_filter=Control.MOUSE_FILTER_PASS;parent.add_child(box)
	if not word.is_empty():
		var caption:=Label.new();caption.name="Word";caption.text=word;T.text(caption,"kicker",T.INK_MUTED);caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.size_flags_vertical=Control.SIZE_SHRINK_CENTER;box.add_child(caption)
	if texture!=null:
		var icon:=TextureRect.new();icon.texture=texture;icon.custom_minimum_size=Vector2(22,22);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(icon)
	var value:=Label.new();value.name="Value";T.text(value,"body",T.INK);value.add_theme_font_override("font",T.font("ui_strong"));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(value)
	var side:=Label.new();side.name="Side";T.text(side,"kicker",T.INK_MUTED);side.mouse_filter=Control.MOUSE_FILTER_IGNORE;side.size_flags_vertical=Control.SIZE_SHRINK_CENTER;box.add_child(side)
	return box

func _set_fact(box:HBoxContainer,value:String,side:String,side_color:Color,tip:String)->void:
	(box.get_node("Value") as Label).text=value
	var label:=box.get_node("Side") as Label
	label.text=side;label.visible=not side.is_empty();label.add_theme_color_override("font_color",side_color)
	box.tooltip_text=tip

func _apply_header()->void:
	for material:Dictionary in data.get("materials",[]):
		var chip:HBoxContainer=_material_chips.get(String(material.resource))
		if chip==null:continue
		var trend:Dictionary=material.get("trend",{})
		var per_day:=float(trend.get("per_day",0.0))
		var side:=""
		var color:=T.INK_MUTED
		var tip:PackedStringArray=["%s: %s in store." % [String(material.name),Plain.number(float(material.amount))]]
		if not trend.is_empty():
			if absf(per_day)>=.05:
				side=("+" if per_day>0.0 else "−")+Plain.number(absf(per_day))
				color=T.GREEN_TEXT if per_day>0.0 else T.RED_TEXT
				tip.append("%s about %s a day over the last %s." % ["Up" if per_day>0.0 else "Down",Plain.number(absf(per_day)),Plain.span_text(float(trend.get("days",1)))])
			else:tip.append("Steady over the last %s." % Plain.span_text(float(trend.get("days",1))))
		var use:=float(material.get("use",0.0))
		if use>=.01:tip.append("The lines use about %s a day." % Plain.number(use))
		_set_fact(_material_chips[String(material.resource)],Plain.number(float(material.amount)),side,color,"\n".join(tip))
	var hands:Dictionary=data.get("hands",{})
	var total:=int(hands.get("total",0));var on_lines:=int(hands.get("lines",0))
	_set_fact(_header.hands,str(on_lines),"/ %d" % total,T.INK_MUTED,
		"Hands: %d of your %d craftspeople work the lines; the rest make household goods.\nAdd or take hands on each line with − and +." % [on_lines,total])
	var capacity:=int(data.get("capacity",0));var count:=(data.get("lines",[]) as Array).size()
	_set_fact(_header.lines,str(count),"/ %d" % capacity,T.INK_MUTED,"Lines: %d of %d workshop lines in use. More open as your security, production, supply and institutions grow." % [count,capacity])
	if _header.has("boatyards"):
		var yards:=int(data.get("boatyards",0))
		_set_fact(_header.boatyards,str(yards),"",T.INK_MUTED,"Boatyards: %d landing%s where boats can be built." % [yards,"" if yards==1 else "s"])
	# Who runs the workshops.
	var owner:=String(data.get("owner",""))
	var person:=Plain.officer(owner)
	var managed:=bool(data.get("managed",true))
	var head:=Plain.header(owner,managed,_named_lines())
	var given:=Names.given_of(String(person.name)) if not person.is_empty() else "Staff"
	var staff:Button=_header.staff;var you:Button=_header.you
	staff.text=given
	W.style_text_button(staff,managed and not person.is_empty());W.style_text_button(you,not managed or person.is_empty())
	staff.disabled=person.is_empty()
	staff.tooltip_text=(String(head.text)+" "+("They open lines for soldiers' gear and set targets to what the bands need." if managed else "Click to hand the workshops back.")) if not person.is_empty() else "Appoint a Quartermaster or Steward to let staff run the workshops."
	you.tooltip_text="You run the workshops: you choose what is made. Existing lines keep running." if not managed or person.is_empty() else "Take over: you choose what is made. Existing lines keep running."
	var status:=String(data.get("status","")).strip_edges()
	var note:Label=_header.note
	note.visible=not status.is_empty()
	# The officer by given name, as the game names people in short; the full
	# name, office and whole note are in the tooltip.
	note.text=((given+": ") if not person.is_empty() else "")+Plain.brief(status,11)
	note.tooltip_text=(("%s, your %s:
" % [String(person.name),String(person.office)]) if not person.is_empty() else "")+status

func _named_lines()->Array:
	var result:Array=[]
	for line:Dictionary in data.get("lines",[]):
		result.append({"name":String(line.get("name","")),"persistent":bool(line.get("persistent",false)),"planner_managed":bool(line.get("managed",line.get("planner_managed",false)))})
	return result

# --- Equipment strip: in store against what the bands need ------------------------

func _build_stock()->void:
	var box:=VBoxContainer.new();box.name="Equipment";box.add_theme_constant_override("separation",6);add_child(box)
	var kicker:=Label.new();kicker.text="EQUIPMENT · IN STORE / NEEDED BY THE BANDS";T.text(kicker,"kicker",T.GOLD_TEXT);box.add_child(kicker)
	var flow:=HFlowContainer.new();flow.name="Stock";flow.add_theme_constant_override("h_separation",8);flow.add_theme_constant_override("v_separation",8);box.add_child(flow)
	for row:Dictionary in data.get("stock",[]):
		var chip:=PanelContainer.new();chip.name="Stock_"+String(row.item);chip.mouse_filter=Control.MOUSE_FILTER_PASS
		var style:=T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CONTROL);style.content_margin_left=6;style.content_margin_right=8;style.content_margin_top=3;style.content_margin_bottom=3
		chip.add_theme_stylebox_override("panel",style);flow.add_child(chip)
		# HOI4's stockpile: the kit, its name, in store against needed, a bar
		# (the shortfall hatched red) and when the lines will cover it.
		chip.custom_minimum_size.x=196
		var card:=HBoxContainer.new();card.add_theme_constant_override("separation",8);card.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(card)
		var icon:=TextureRect.new();icon.texture=Icons.equipment_texture(String(row.item),T.INK,T.GOLD,64);icon.custom_minimum_size=Vector2(40,40);icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(icon)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",2);column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(column)
		var title:=Label.new();title.name="Name";title.text=String(row.get("name",row.item));T.text(title,"kicker",T.INK_MUTED);title.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(title)
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",5);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(line)
		for part:String in ["Have","Need","Short","Mend","Damaged"]:
			var label:Control
			if part=="Mend":
				var mend:=TextureRect.new();mend.texture=Icons.workshop_texture("mend",T.AMBER_TEXT,36);mend.custom_minimum_size=Vector2(16,16)
				mend.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mend.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;mend.size_flags_vertical=Control.SIZE_SHRINK_CENTER;label=mend
			else:
				var text:=Label.new()
				match part:
					"Have":T.text(text,"body",T.INK);text.add_theme_font_override("font",T.font("ui_strong"))
					"Need":T.text(text,"small",T.INK_MUTED)
					"Short":
						T.text(text,"kicker",T.RED_TEXT)
						var pill:=T.flat(T.DANGER_BG,T.DANGER_BORDER,1,T.RADIUS_CONTROL);pill.content_margin_left=4;pill.content_margin_right=4
						text.add_theme_stylebox_override("normal",pill)
					"Damaged":T.text(text,"kicker",T.AMBER_TEXT)
				label=text
			label.name=part;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(label)
		var bar:=StockBar.new();bar.name="Bar";bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(bar)
		var cover:=Label.new();cover.name="Cover";T.text(cover,"small",T.INK_MUTED);cover.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(cover)
		_stock_chips[String(row.item)]=chip
	if data.get("stock",[]).is_empty():
		var none:=Label.new();none.name="NoStock";none.text="No equipment in store or needed yet.";T.text(none,"small",T.INK_MUTED);flow.add_child(none)

func _apply_stock()->void:
	var where_words:={"home":"at home","field":"in the field","garrison":"holding a town","training":"in training","called_up":"called up"}
	for row:Dictionary in data.get("stock",[]):
		var chip:PanelContainer=_stock_chips.get(String(row.item))
		if chip==null:continue
		var needed:=int(row.needed);var deficit:=int(row.deficit);var damaged:=int(row.damaged)+int(row.get("repairing",0))
		(chip.find_child("Have",true,false) as Label).text=str(int(row.stock))
		var need:=chip.find_child("Need",true,false) as Label
		need.text="/ %d" % needed;need.visible=needed>0
		var short:=chip.find_child("Short",true,false) as Label
		short.text="−%d" % deficit;short.visible=deficit>0
		(chip.find_child("Mend",true,false) as Control).visible=damaged>0
		var broken:=chip.find_child("Damaged",true,false) as Label
		broken.text=str(damaged);broken.visible=damaged>0
		var tip:PackedStringArray=[String(row.name),("%d in store · %d needed by the bands" % [int(row.stock),needed]) if needed>0 else "%d in store; no band needs more now." % int(row.stock)]
		for group:Dictionary in row.get("for",[]):
			tip.append("%s: %d %s" % [String(group.who).left(1).to_upper()+String(group.who).substr(1),int(group.count),String(where_words.get(String(group.where),""))])
		if deficit>0:
			var per_day:=float(row.get("making_per_day",0.0))
			if per_day>0.0:tip.append("Short %d · the lines make %s: covered in %s." % [deficit,Plain.rate_short(per_day),Plain.span_text(float(row.days_to_cover))])
			elif (row.get("lines",[]) as Array).is_empty():tip.append("Short %d · no line makes it. Start one from the cards." % deficit)
			else:tip.append("Short %d · its line is not making any now." % deficit)
		if damaged>0:tip.append("%d damaged, %s." % [damaged,Plain.repair_text(String(row.get("repair_status","")))])
		chip.tooltip_text="\n".join(tip)
		(chip.find_child("Bar",true,false) as StockBar).set_stock(int(row.stock),needed)
		var cover:=chip.find_child("Cover",true,false) as Label
		var said:=cover_words(deficit,needed,float(row.get("making_per_day",0.0)),float(row.get("days_to_cover",0.0)),not (row.get("lines",[]) as Array).is_empty())
		cover.text=String(said.text)
		cover.add_theme_color_override("font_color",{"red":T.RED_TEXT,"amber":T.AMBER_TEXT,"green":T.GREEN_TEXT}.get(String(said.tone),T.INK_MUTED))
		var style:=T.flat(T.PAPER_RAISED,T.DANGER_BORDER if deficit>0 else T.RULE,1,T.RADIUS_CONTROL);style.content_margin_left=6;style.content_margin_right=8;style.content_margin_top=3;style.content_margin_bottom=3
		chip.add_theme_stylebox_override("panel",style)

## The line under a stockpile card: {text, tone}. Short and made: when it is
## covered (amber). Short and not made: red. Enough: green. Nobody needs it:
## what the lines make, if anything.
static func cover_words(deficit:int,needed:int,making:float,days:float,has_line:bool)->Dictionary:
	if deficit>0:
		if making>0.0: return {"text":"short %d · covered in %s" % [deficit,Plain.span_text(days)],"tone":"amber"}
		return {"text":"short %d · %s" % [deficit,"its line is idle" if has_line else "no line makes it"],"tone":"red"}
	if needed>0: return {"text":"enough for the bands"+(" · +%s" % Plain.rate_short(making) if making>0.0 else ""),"tone":"green"}
	return {"text":"+%s" % Plain.rate_short(making) if making>0.0 else "spare","tone":"muted"}


## In store against what the bands need, on one scale: the store in green
## when it covers the need (ochre when it does not), and the shortfall
## hatched in red after it.
class StockBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var stock:=0
	var needed:=0
	func _init()->void: custom_minimum_size=Vector2(120,8)
	func set_stock(have:int,need:int)->void:
		stock=maxi(0,have);needed=maxi(0,need);queue_redraw()
	func _draw()->void:
		var top:=float(maxi(1,maxi(stock,needed)))
		var bar:=Rect2(Vector2(0,1),Vector2(size.x,size.y-2))
		draw_rect(bar,Color(T.INK,0.08))
		var have:=bar.size.x*float(stock)/top
		var covered:=needed<=0 or stock>=needed
		if have>0.0: draw_rect(Rect2(bar.position,Vector2(have,bar.size.y)),T.GREEN if covered else Color("#a8782a"))
		if needed>stock:
			var gap:=Rect2(Vector2(have,bar.position.y),Vector2(bar.size.x*float(needed-stock)/top,bar.size.y))
			draw_rect(gap,Color(T.RED,0.18))
			# Hatching: short strokes leaning right, clipped to the gap.
			var x:=gap.position.x
			while x<gap.end.x:
				draw_line(Vector2(x,gap.end.y),Vector2(minf(x+gap.size.y,gap.end.x),gap.position.y),Color(T.RED,0.85),1.2)
				x+=4.0
		draw_rect(bar,Color(T.INK,0.4),false,1.0)


# --- Lines -------------------------------------------------------------------------

func _build_lines(parent:Node)->void:
	var head:=HBoxContainer.new();head.name="LinesHead";parent.add_child(head)
	var kicker:=Label.new();kicker.text="LINES";T.text(kicker,"kicker",T.GOLD_TEXT);kicker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(kicker)
	var room:=Label.new();room.name="LineRoom";T.text(room,"kicker",T.INK_MUTED);head.add_child(room);_header.line_room=room
	var lines:Array=data.get("lines",[])
	if not lines.is_empty():parent.add_child(_column_heads())
	var list:=VBoxContainer.new();list.name="WorkshopLines";list.add_theme_constant_override("separation",8);parent.add_child(list)
	for view:Dictionary in lines:
		var row:=LineRow.new();list.add_child(row);row.build(self,view);_rows[int(view.id)]=row
	if lines.is_empty():
		var empty:=Label.new();empty.name="NoLines"
		empty.text="No lines yet. Pick a card to start one." if not (data.get("recipes",[]) as Array).is_empty() else "No lines. Your people know no workshop crafts yet."
		T.text(empty,"body",T.BODY);empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(empty)

## The heads over the rows' columns, aligned with LineRow's fixed widths.
func _column_heads()->MarginContainer:
	var frame:=MarginContainer.new();frame.name="ColumnHeads";frame.add_theme_constant_override("margin_right",LineRow.PAD_RIGHT)
	var heads:=HBoxContainer.new();heads.add_theme_constant_override("separation",LineRow.COLUMN_GAP);frame.add_child(heads)
	var lead:=Control.new();lead.custom_minimum_size.x=LineRow.PAD_LEFT+LineRow.ART_WIDTH;heads.add_child(lead)
	for entry:Array in [["OUTPUT",0.0,"Made a day, week or month. Green: working. Amber: short of materials or hands. Red: stopped. Grey: resting or paused."],
		["HANDS",LineRow.HANDS_WIDTH,"Craftspeople on the line. More hands, more output; they come from household crafting."],
		["TARGET",LineRow.TARGET_WIDTH,"How many to keep in store; the line rests when it has them. Boats: build one, or keep building (∞)."],
		["SKILL",LineRow.SKILL_WIDTH,"How practised the hands are. Skill grows with work."]]:
		var label:=Label.new();label.text=String(entry[0]);T.text(label,"kicker",T.INK_MUTED);label.tooltip_text=String(entry[2]);label.mouse_filter=Control.MOUSE_FILTER_PASS
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		if float(entry[1])<=0.0:label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.custom_minimum_size.x=LineRow.BAR_MIN_WIDTH
		else:label.custom_minimum_size.x=float(entry[1])
		heads.add_child(label)
	return frame

func _apply_lines()->void:
	var lines:Array=data.get("lines",[])
	for view:Dictionary in lines:
		var row:Node=_rows.get(int(view.id))
		if row!=null:row.apply(view)
	if _header.has("line_room"):
		var room:Label=_header.line_room
		room.text="%d OF %d IN USE" % [lines.size(),int(data.get("capacity",lines.size()))]
		room.tooltip_text="Line 1 gets scarce materials first. Drag a row, or use its arrows, to change the order."

func _room_note()->String:
	var count:=(data.get("lines",[]) as Array).size();var capacity:=int(data.get("capacity",count))
	return "ALL LINES BUSY" if count>=capacity else "%d FREE" % (capacity-count)

# --- Household goods and techniques -----------------------------------------------

func _build_households(parent:Node,full:bool)->void:
	var box:=VBoxContainer.new();box.name="Households";box.add_theme_constant_override("separation",6);parent.add_child(box)
	var head:=Label.new();head.text="HOUSEHOLD GOODS";T.text(head,"kicker",T.GOLD_TEXT);box.add_child(head)
	head.tooltip_text="Tools, baskets, pots and fittings. Households make and wear them out; they are not workshop lines."
	head.mouse_filter=Control.MOUSE_FILTER_PASS
	var cities:Array=data.get("households",[])
	if cities.is_empty():
		var none:=Label.new();none.text="No settlement makes household goods yet.";T.text(none,"small",T.INK_MUTED);box.add_child(none)
	for city:Dictionary in cities:
		var row:=HBoxContainer.new();row.name="Household_"+String(city.get("id",""));row.add_theme_constant_override("separation",10);row.mouse_filter=Control.MOUSE_FILTER_PASS;box.add_child(row)
		var icon:=TextureRect.new();icon.texture=Icons.material_texture("Civilian Goods",44);icon.custom_minimum_size=Vector2(22,22)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(icon)
		var place:=Label.new();place.name="Place";place.text=String(city.get("city",""));T.text(place,"small",T.INK);place.custom_minimum_size.x=140;place.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(place)
		var bar:=W.OutputBar.new(220);bar.name="Coverage";row.add_child(bar)
		var net:=Label.new();net.name="Net";T.text(net,"kicker",T.INK_MUTED);net.custom_minimum_size.x=70;net.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(net)
		if full:
			# What households can work with, as marks and amounts (filled in _apply).
			var basket:=HBoxContainer.new();basket.name="Basket";basket.add_theme_constant_override("separation",4);basket.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(basket)
		_household_rows[String(city.get("id",""))]=row
	if not full:return
	var techniques:Array=data.get("techniques",[])
	if techniques.is_empty():return
	var gap:=Control.new();gap.custom_minimum_size.y=8;box.add_child(gap)
	var tech_head:=Label.new();tech_head.text="HOUSEHOLD TECHNIQUES";T.text(tech_head,"kicker",T.GOLD_TEXT);box.add_child(tech_head)
	var flow:=HFlowContainer.new();flow.name="Techniques";flow.add_theme_constant_override("h_separation",8);flow.add_theme_constant_override("v_separation",6);box.add_child(flow)
	for technique:Dictionary in techniques:
		var chip:=W.Chip.new();chip.name="Technique_"+String(technique.get("id",""));flow.add_child(chip)
		_technique_chips[String(technique.get("id",""))]=chip

func _apply_households()->void:
	for city:Dictionary in data.get("households",[]):
		var row:HBoxContainer=_household_rows.get(String(city.get("id","")))
		if row==null:continue
		var story:=household_story(city)
		var tone:=String(story.tone)
		var coverage:=clampf(float(city.get("coverage",0.0)),0.0,1.0)
		var look:={"good":"good","warn":"warn","bad":"bad"}.get(tone,"idle") as String
		if coverage>=.98:look="idle"
		var tip:="\n".join(PackedStringArray([String(story.progress_text),String(story.pace),String(story.eta),String(story.held),String(story.materials)]))
		(row.get_node("Coverage") as W.OutputBar).set_reading(coverage,look,"%d%% stocked" % roundi(coverage*100.0),tip)
		var change:=float(city.get("made",0.0))-float(city.get("worn",0.0))
		var net:=row.get_node("Net") as Label
		net.text=("+" if change>=0.0 else "−")+Plain.number(absf(change))+" a day"
		net.add_theme_color_override("font_color",T.GREEN_TEXT if change>0.0 else (T.RED_TEXT if change<0.0 else T.INK_MUTED))
		row.tooltip_text=tip
		var basket:=row.get_node_or_null("Basket")
		if basket!=null:
			for child:Node in basket.get_children():basket.remove_child(child);child.queue_free()
			for material:Dictionary in city.get("basket",[]):
				if not material.has("resource"):continue
				var mark:=TextureRect.new();mark.texture=Icons.material_texture(String(material.resource),36);mark.custom_minimum_size=Vector2(18,18)
				mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;basket.add_child(mark)
				var amount:=Label.new();amount.text=Plain.number(float(material.amount));T.text(amount,"kicker",T.BODY);amount.mouse_filter=Control.MOUSE_FILTER_IGNORE;basket.add_child(amount)
				var gap:=Control.new();gap.custom_minimum_size.x=6;gap.mouse_filter=Control.MOUSE_FILTER_IGNORE;basket.add_child(gap)
	var coverage:=float((data.get("households",[{}]) as Array)[0].get("coverage",0.0)) if not (data.get("households",[]) as Array).is_empty() else 0.0
	for technique:Dictionary in data.get("techniques",[]):
		var chip:W.Chip=_technique_chips.get(String(technique.get("id","")))
		if chip==null:continue
		var adoption:=roundi(float(technique.adoption)*100.0)
		chip.set_reading("%s %d%%" % [String(technique.name),adoption],T.TEAL,"%s: in use by %d%%, working at %d%%. A technique helps only as far as households have goods (stores %d%% full)." % [String(technique.name),adoption,roundi(float(technique.working)*100.0),roundi(coverage*100.0)])

static func household_story(city:Dictionary)->Dictionary:
	var stock:=float(city.get("stock",0.0));var target:=maxf(.01,float(city.get("target",1.0)))
	var made:=float(city.get("made",0.0));var worn:=float(city.get("worn",0.0))
	var coverage:=float(city.get("coverage",clampf(stock/target,0,1)))
	var net:=made-worn
	var story:={"tone":"good"}
	story.progress_text="%s in store of %s wanted (%d%%)" % [Plain.number(stock),Plain.number(target),roundi(coverage*100.0)]
	var wear:=("about %s a day wear out" % Plain.number(worn)) if worn>=0.01 else "hardly any wear out yet"
	story.pace=("Making about %s a day; %s" % [Plain.number(made),wear]) if made>0.0 else ("Nothing made today; "+wear)
	if coverage>=.98:story.eta="Full"
	elif net>0.0:
		var when:=Plain.duration_text((target-stock)/net);story.eta=when.left(1).to_upper()+when.substr(1)+" at this pace"
	else:story.eta="Not filling: wear outpaces making"
	var reason:=String(city.get("reason",""))
	match reason:
		"No craftspeople assigned":story.held="No craftspeople are at work.";story.tone="bad"
		"Needs timber, fiber, clay, stone or flint":story.held="Out of raw materials: timber, fiber, clay, stone or flint.";story.tone="bad"
		"Needs a settled workplace":story.held="Needs a settled place to work.";story.tone="bad"
		_:
			if coverage>=.98 or reason=="Stock target met":story.held="Nothing. Stores are full."
			elif net<=0.0:story.held="Too few craftspeople to keep up with wear.";story.tone="warn"
			else:story.held="Nothing. Filling as fast as the craftspeople can."
	var parts:Array[String]=[]
	for material:Dictionary in city.get("basket",[]):parts.append("%s %s" % [String(material.name).to_lower(),Plain.number(float(material.amount))])
	story.materials=("Any mix of these, in store: "+", ".join(parts)+".") if not parts.is_empty() else "No timber, fiber, clay, stone or flint in store."
	return story

# --- Footer --------------------------------------------------------------------------

func _build_footer()->void:
	var row:=HFlowContainer.new();row.name="Footer";row.add_theme_constant_override("h_separation",8);row.add_theme_constant_override("v_separation",8);add_child(row)
	for entry:Array in [["One-off orders","on_add","Make a fixed number once instead of keeping a store."],["Crafting share","on_manage","Who runs the workshops, and how much crafting labor goes to lines."],["Output history","on_history","What the workshops and households have finished."]]:
		var button:=W.text_button(String(entry[0]),String(entry[2]));button.name=String(entry[0]).replace(" ","").replace("-","");row.add_child(button)
		var key:=String(entry[1])
		button.pressed.connect(func():
			var callback:Variant=data.get(key)
			if callback is Callable:callback.call())
		button.disabled=not data.get(key) is Callable

func _apply()->void:
	if String(data.get("mode","military"))!="civilian":
		_apply_header();_apply_stock();_apply_lines()
		if _picker!=null:_picker.apply(data.get("recipes",[]),_room_note())
	_apply_households()

# --- Helpers shared with panels that extend this script (keep as they are) --------------
func _button(parent:Node,label:String,callback:Variant,tip:String,active:bool=false)->void:
	var b:=Button.new();b.text=label;b.tooltip_text=tip;b.custom_minimum_size=Vector2(28,28);b.add_theme_font_size_override("font_size",12);b.add_theme_color_override("font_color",T.BODY);b.add_theme_color_override("font_hover_color",T.INK)
	b.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG if active else Color.TRANSPARENT,T.GOLD if active else T.BORDER_SOFT,1,0,5));b.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,0,5));parent.add_child(b)
	if callback is Callable and callback.is_valid():b.pressed.connect(callback)
	else:b.disabled=true
func _bar(parent:Node,ratio:float,color:Color)->void:
	var bar:=ProgressBar.new();bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.custom_minimum_size.y=7;bar.show_percentage=false;bar.value=ratio*100;bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(color));parent.add_child(bar)
func _rule(parent:Node)->void:
	var rule:=HSeparator.new();rule.add_theme_color_override("color",T.BORDER_SOFT);parent.add_child(rule)
