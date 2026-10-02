extends VBoxContainer
## THE PEOPLE screen: the god looking down on their people.
##
##   ┌ the settlement at this hour (court backdrop), season and weather,
##   │ a headline, and one voice from the fires with the speaker's face
##   ├ faces: named people; clicking one opens their card (summon from it)
##   ├ how they fare (vitals with trend and cause) │ what they are doing now
##   ├ the season's story (Chronicle)              │ the hearths
##   └ the tallies, one compact row
##
## Each task's name opens what that work does, with today's numbers
## (task_impact.gd, laid out by impact_panel.gd); one task is open at a time.
##
## Data comes from content/dock_content_overview.gd (people_model.gd). The
## daily refresh updates this widget in place (update_block): the scene keeps
## its nodes and only parts whose data changed are rebuilt, so the backdrop,
## the open card and the reader's place stay put.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Buildings:=preload("res://scripts/hud/construction_art.gd")
## The Production screen's hands controls (−, +, ×5), for the daily work.
const W:=preload("res://scripts/hud/production_widgets.gd")
## What a task does, line by line (the Buildings page's panel).
const ImpactPanel:=preload("res://scripts/hud/impact_panel.gd")

const SCENE_HEIGHT:=210.0
const TWO_COLUMNS_AT:=700.0
const FIGURES_PER_ROW:=14  # hard cap; the model scales figures to 12

class Meter extends Control:
	var fill:=0.0
	var color:=Color.WHITE
	var track:=Color.GRAY
	func _init()->void:
		custom_minimum_size=Vector2(40,6);mouse_filter=Control.MOUSE_FILTER_IGNORE
	func set_value(value:float,tint:Color)->void:
		fill=clampf(value,0.0,1.0);color=tint;queue_redraw()
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),track)
		draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*fill,size.y)),color)

## A task's name that opens what the work does: a small arrow, then the name.
## The arrow points at the name while closed and down while open.
class TaskToggle extends Button:
	var open:=false
	func _init(words:String,is_open:bool)->void:
		text=words;open=is_open;focus_mode=Control.FOCUS_NONE;clip_text=true
		alignment=HORIZONTAL_ALIGNMENT_LEFT;custom_minimum_size=Vector2(136,24);size_flags_vertical=Control.SIZE_SHRINK_CENTER
		tooltip_text=("Close what %s does" if is_open else "What %s does, with today's numbers") % words
		add_theme_font_size_override("font_size",12)
		add_theme_color_override("font_color",T.INK if is_open else T.BODY)
		for state:String in ["font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:add_theme_color_override(state,T.INK)
		add_theme_color_override("font_disabled_color",T.DISABLED)
		var normal:=T.flat(T.ACTIVE_BG if is_open else Color(0,0,0,0),T.GOLD if is_open else Color(0,0,0,0),1,3)
		var hover:=T.flat(T.HOVER_BG,T.GOLD,1,3)
		for style:StyleBoxFlat in [normal,hover]:
			style.content_margin_left=17;style.content_margin_right=4;style.content_margin_top=2;style.content_margin_bottom=2
		add_theme_stylebox_override("normal",normal);add_theme_stylebox_override("hover",hover)
		add_theme_stylebox_override("pressed",hover);add_theme_stylebox_override("hover_pressed",hover)
		add_theme_stylebox_override("disabled",T.flat(Color(0,0,0,0)));add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	func _draw()->void:
		var ink:=T.INK if open or is_hovered() else T.BODY
		var c:=Vector2(8.5,size.y*0.5);var r:=3.6
		var arrow:=PackedVector2Array([c+Vector2(-r,-r*0.55),c+Vector2(0,r*0.6),c+Vector2(r,-r*0.55)]) if open else PackedVector2Array([c+Vector2(-r*0.55,-r),c+Vector2(r*0.6,0),c+Vector2(-r*0.55,r)])
		draw_polyline(arrow,ink,1.6,true)

var data:Dictionary={}
var selected_id:=""
var backdrop:Control
var season_label:Label
var headline_label:Label
var register_label:Label
var voice_line:Label
var voice_name:Label
var voice_face:Control
var faces_row:HFlowContainer
var card:PanelContainer
var columns:GridContainer
var left:VBoxContainer
var right:VBoxContainer
var parts:Dictionary={}
var prints:Dictionary={}
## Face id -> distinct painting slot, so no painting repeats on this screen.
var face_slots:Dictionary={}
## The task whose "what this work does" is open ("" for none).
var open_task:=""
## Parts rebuilt since setup (tests read this to prove in-place updates).
var rebuilds:=0


func setup(block:Dictionary)->void:
	name="PeopleScreen"
	add_theme_constant_override("separation",14)
	_build_scene()
	faces_row=HFlowContainer.new();faces_row.name="Faces"
	faces_row.add_theme_constant_override("h_separation",8);faces_row.add_theme_constant_override("v_separation",8)
	add_child(_section("FACES AT THE FIRE" if _hearth(block) else "FACES AMONG THE PEOPLE",faces_row,"Click a face to see who they are"))
	card=PanelContainer.new();card.name="PersonCard";card.visible=false
	card.add_theme_stylebox_override("panel",T.flat(T.TILE_BG,T.GOLD,1,4,12));add_child(card)
	columns=GridContainer.new();columns.name="Columns"
	columns.add_theme_constant_override("h_separation",22);columns.add_theme_constant_override("v_separation",14)
	add_child(columns)
	left=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.add_theme_constant_override("separation",14);columns.add_child(left)
	right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",14);columns.add_child(right)
	parts.vitals=_part(left,"Vitals")
	parts.labor=_part(right,"Labor")
	parts.story=_part(right,"Story")
	parts.hearths=_part(self,"Hearths")
	parts.tallies=_part(self,"Tallies")
	resized.connect(_layout)
	apply(block)
	_layout()


## The live refresh: same widget, new data.
func update_block(block:Dictionary)->bool:
	apply(block)
	return true


func apply(block:Dictionary)->void:
	data=block
	_assign_face_slots(block.get("faces",[]),block.get("scene",{}))
	_fill_scene(block.get("scene",{}))
	_rebuild_if_changed("faces",_faces_drawn(block.get("faces",[])),_fill_faces_part)
	_rebuild_if_changed("card",[selected_id,_face(selected_id)],_fill_card)
	_refresh_vitals(block.get("vitals",[]))
	_rebuild_labor()
	_rebuild_if_changed("story",block.get("story",{}),_fill_story)
	_rebuild_if_changed("hearths",block.get("hearths",[]),_fill_hearths)
	_rebuild_if_changed("tallies",block.get("tallies",[]),_fill_tallies)


func view_state()->Dictionary:
	return {"selected":selected_id,"task":open_task}


func restore_view_state(state:Dictionary)->void:
	var changed:=false
	var wanted:=String(state.get("selected",""))
	if wanted!=selected_id and (wanted=="" or not _face(wanted).is_empty()):
		selected_id=wanted
		prints.erase("card");prints.erase("faces");changed=true
	var task:=String(state.get("task",""))
	if task!=open_task:
		open_task=task;prints.erase("labor");changed=true
	if changed:apply(data)


## Opens what a task does, or closes it when it is the one open.
func toggle_task(role:String)->void:
	open_task="" if open_task==role else role
	prints.erase("labor")
	_rebuild_labor()


## The labor part is drawn from the tasks and, for the one task opened, what
## that work does with today's numbers: asked of the provider for that task
## alone (labor.impact_of), so the eight closed tasks cost nothing.
var open_impact:Dictionary={}
func _rebuild_labor()->void:
	var labor:Dictionary=data.get("labor",{})
	open_impact={}
	if open_task!="":
		for task:Dictionary in labor.get("tasks",[]):
			if String(task.get("id",""))!=open_task:continue
			var ask:Variant=labor.get("impact_of")
			if task.has("impact"):open_impact=task.get("impact",{})
			elif ask is Callable and (ask as Callable).is_valid():open_impact=(ask as Callable).call(open_task)
	var head:=labor.duplicate();head.erase("tasks")
	var head_print:=_print(head)
	var tasks:Array=labor.get("tasks",[])
	var row_prints:Array[String]=[]
	for task:Dictionary in tasks:
		var role:=String(task.get("id",""))
		row_prints.append(_print([task,int(labor.get("per_figure",1)),bool(labor.get("manual",false)),labor.get("on_move") is Callable,open_task==role,open_impact if open_task==role else {}]))
	var box:Control=parts.labor
	# The whole part is drawn afresh when its rows are not the ones drawn;
	# otherwise only the header or the task rows whose print moved.
	if _labor_head==null or not is_instance_valid(_labor_head) or _labor_rows.size()!=tasks.size() or _labor_row_prints.size()!=tasks.size():
		for child in box.get_children():box.remove_child(child);child.queue_free()
		_fill_labor(box,labor)
		prints["labor"]=head_print
		_labor_row_prints=row_prints
		rebuilds+=1
		return
	if String(prints.get("labor",""))!=head_print:
		prints["labor"]=head_print
		var at:=_labor_head.get_index()
		box.remove_child(_labor_head);_labor_head.queue_free()
		_labor_head=_labor_header(labor);box.add_child(_labor_head);box.move_child(_labor_head,at)
		rebuilds+=1
	for index in tasks.size():
		if row_prints[index]==_labor_row_prints[index]:continue
		var stale:Control=_labor_rows[index]
		var at:=stale.get_index()
		box.remove_child(stale);stale.queue_free()
		var fresh:=_labor_row(labor,tasks[index])
		box.add_child(fresh);box.move_child(fresh,at)
		_labor_rows[index]=fresh
		rebuilds+=1
	_labor_row_prints=row_prints

var _labor_head:Control
var _labor_rows:Array[Control]=[]
var _labor_row_prints:Array[String]=[]


# ---------------------------------------------------------------------------
# The scene
# ---------------------------------------------------------------------------

func _build_scene()->void:
	var frame:=PanelContainer.new();frame.name="Scene";frame.clip_contents=true
	frame.custom_minimum_size.y=SCENE_HEIGHT
	frame.add_theme_stylebox_override("panel",T.flat(Color("2a241c"),T.BORDER,1,4))
	add_child(frame)
	backdrop=Backdrop.new();backdrop.name="Backdrop"
	backdrop.configure(Backdrop.current_tier(),not T.is_light())
	frame.add_child(backdrop)
	var shade:=TextureRect.new();shade.name="Shade";shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var gradient:=Gradient.new();gradient.set_color(0,Color(0.04,0.03,0.02,0.45));gradient.set_color(1,Color(0.04,0.03,0.02,0.86))
	var ramp:=GradientTexture2D.new();ramp.gradient=gradient;ramp.fill_from=Vector2(0,0);ramp.fill_to=Vector2(0,1);ramp.width=4;ramp.height=64
	shade.texture=ramp;shade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;shade.stretch_mode=TextureRect.STRETCH_SCALE
	frame.add_child(shade)
	var pad:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:pad.add_theme_constant_override("margin_"+side,16 if side!="top" else 12)
	frame.add_child(pad)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",6);pad.add_child(stack)
	var top:=HBoxContainer.new();stack.add_child(top)
	season_label=T.make_label("",12,Color("f1e3c4"),0.08);season_label.name="Season";season_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(season_label)
	register_label=T.make_label("",12,Color("e0c27e"),0.12);register_label.name="Register";top.add_child(register_label)
	var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;stack.add_child(spacer)
	headline_label=T.make_label("",21,Color("fbf4e4"));headline_label.name="Headline"
	headline_label.add_theme_font_override("font",_serif());headline_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	headline_label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.6));headline_label.add_theme_constant_override("shadow_offset_y",1)
	stack.add_child(headline_label)
	var voice:=HBoxContainer.new();voice.name="Voice";voice.add_theme_constant_override("separation",10);stack.add_child(voice)
	voice_face=Control.new();voice_face.custom_minimum_size=Vector2(40,48);voice.add_child(voice_face)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",1);voice.add_child(words)
	voice_line=T.make_label("",14,Color("f6ead2"));voice_line.name="VoiceLine";voice_line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	voice_line.add_theme_font_override("font",_serif(true));words.add_child(voice_line)
	voice_name=T.make_label("",10,Color("e0c27e"),0.08);voice_name.name="VoiceName";words.add_child(voice_name)


func _fill_scene(scene:Dictionary)->void:
	season_label.text=String(scene.get("season","")).to_upper()
	register_label.text=String(scene.get("register",""))
	headline_label.text=String(scene.get("headline",""))
	var voice:Dictionary=scene.get("voice",{})
	var face:Dictionary=voice.get("face",{})
	voice_line.text="“%s”" % String(voice.get("line","")) if String(voice.get("line",""))!="" else ""
	voice_name.text=("— %s, %s" % [String(face.get("name","")),String(face.get("title",""))]).to_upper() if not face.is_empty() else ""
	var key:=String(face.get("id",""))
	if String(voice_face.get_meta("face_id",""))!=key:
		voice_face.set_meta("face_id",key)
		for child in voice_face.get_children():child.queue_free()
		if not face.is_empty():
			var picture:=_face_picture(face,40,48);picture.set_anchors_preset(Control.PRESET_FULL_RECT);voice_face.add_child(picture)


# ---------------------------------------------------------------------------
# Faces and the card
# ---------------------------------------------------------------------------

## What the faces row draws of each face (the card shows the rest): so a
## face's regard or wants moving does not redraw the row.
func _faces_drawn(faces:Array)->Array:
	var drawn:Array=[selected_id]
	for face_variant in faces:
		var face:Dictionary=face_variant
		var id:=String(face.get("id",""))
		drawn.append([id,String(face.get("name","")),String(face.get("tag","")),String(face.get("given",face.get("name",""))),bool(face.get("alive",true)),face.get("person",{}),face_slots.get(id,[])])
	return drawn

func _fill_faces_part(parent:Control,_drawn:Array)->void:
	_fill_faces(parent,data.get("faces",[]))

func _fill_faces(parent:Control,faces:Array)->void:
	for face_variant in faces:
		var face:Dictionary=face_variant
		var id:=String(face.get("id",""))
		var button:=Button.new();button.name="Face_"+id.validate_node_name();button.custom_minimum_size=Vector2(96,134)
		button.tooltip_text="%s · %s" % [String(face.get("name","")),String(face.get("tag","")).to_lower()]
		var chosen:=id==selected_id
		var accent:=T.GOLD if chosen else (T.BORDER_SOFT if bool(face.get("alive",true)) else T.DISABLED)
		button.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG if chosen else T.ROW_BG,accent,2 if chosen else 1,4))
		button.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,4))
		button.add_theme_stylebox_override("pressed",T.flat(T.ACTIVE_BG,T.GOLD,2,4))
		button.pressed.connect(_select.bind(id))
		parent.add_child(button)
		var column:=VBoxContainer.new();column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,5)
		column.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_theme_constant_override("separation",2);button.add_child(column)
		var picture:=_face_picture(face,82,82);picture.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		if not bool(face.get("alive",true)):picture.modulate=Color(0.62,0.62,0.62,0.85)
		column.add_child(picture)
		var tag:=T.make_label(String(face.get("tag","")),12,T.GOLD_TEXT if bool(face.get("alive",true)) else T.MUTED,0.06);tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tag.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tag.clip_text=true;column.add_child(tag)
		var given:=T.make_label(String(face.get("given",face.get("name",""))).get_slice(" ",0),12,T.INK);given.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;given.mouse_filter=Control.MOUSE_FILTER_IGNORE
		given.clip_text=true;column.add_child(given)


func _assign_face_slots(faces:Array,scene:Dictionary)->void:
	# Everyone on the screen at once: the faces row and the voice at the fire.
	var shown:Array=[];var people:Array=[]
	for face_variant in faces:
		if face_variant is Dictionary and not shown.has(String(face_variant.get("id",""))):
			shown.append(String(face_variant.get("id","")));people.append(face_variant.get("person",{}))
	var voice_face_data:Dictionary=(scene.get("voice",{}) as Dictionary).get("face",{}) if scene.get("voice",{}) is Dictionary else {}
	if not voice_face_data.is_empty() and not shown.has(String(voice_face_data.get("id",""))):
		shown.append(String(voice_face_data.get("id","")));people.append(voice_face_data.get("person",{}))
	var slots:=Portrait.distinct_slots(people)
	face_slots.clear()
	for i in shown.size():face_slots[shown[i]]=slots[i]


func _face_picture(face:Dictionary,width:float,height:float)->TextureRect:
	var person:Dictionary=face.get("person",{}) if face.get("person",{}) is Dictionary else {}
	var slot:Array=face_slots.get(String(face.get("id","")),[])
	return Portrait.picture_slot(person,slot,width,height)


func _select(id:String)->void:
	selected_id="" if selected_id==id else id
	prints.erase("card");prints.erase("faces")
	apply(data)


func _face(id:String)->Dictionary:
	if id=="":return {}
	for face in data.get("faces",[]):
		if String((face as Dictionary).get("id",""))==id:return face
	return {}


func _fill_card(parent:Control,value:Array)->void:
	var face:Dictionary=value[1]
	card.visible=not face.is_empty()
	if face.is_empty():return
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);parent.add_child(row)
	var picture:=_face_picture(face,96,116)
	if not bool(face.get("alive",true)):picture.modulate=Color(0.62,0.62,0.62,0.85)
	row.add_child(picture)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",4);row.add_child(body)
	body.add_child(T.make_label(String(face.get("tag","")),10,T.GOLD,0.1))
	var title:=T.make_label(String(face.get("name","")),20,T.INK);title.add_theme_font_override("font",_serif());body.add_child(title)
	if bool(face.get("alive",true)):
		var facts:PackedStringArray=[]
		var age:=int(face.get("age",0))
		facts.append("newborn" if age<=0 else ("%d %s" % [age,"winters" if data.get("scene",{}).get("hearth",true) else "years"]))
		facts.append(String(face.get("title","")))
		if String(face.get("village",""))!="":facts.append("of "+String(face.village))
		_line(body,", ".join(facts).strip_edges())
		_fact(body,"FAMILY",String(face.get("family","")))
		if String(face.get("note",""))!="":_fact(body,"",String(face.note))
		if String(face.get("temper",""))!="":_fact(body,"MANNER","%s; %s." % [String(face.temper).capitalize(),String(face.get("detail",""))])
		_fact(body,"WANTS",String(face.get("wants","")))
		var regard:=HBoxContainer.new();regard.add_theme_constant_override("separation",8);body.add_child(regard)
		regard.add_child(T.make_label("THE GOD",9,T.MUTED,0.1))
		var read:=T.make_label(_cap(String(face.get("regard","")))+".",12,T.BODY);read.size_flags_horizontal=Control.SIZE_EXPAND_FILL;regard.add_child(read)
		for pair in [["LOVE",float(face.get("love",0.5)),T.GREEN],["DREAD",float(face.get("dread",0.2)),T.RED]]:
			regard.add_child(T.make_label(String(pair[0]),9,T.MUTED,0.08))
			var meter:=Meter.new();meter.track=T.TRACK;meter.custom_minimum_size=Vector2(56,6);meter.size_flags_vertical=Control.SIZE_SHRINK_CENTER;meter.set_value(float(pair[1]),pair[2]);regard.add_child(meter)
		var actions:=HFlowContainer.new();body.add_child(actions)
		var summon:Dictionary=face.get("summon",{})
		var on_summon:Variant=data.get("on_summon")
		if not summon.is_empty() and on_summon is Callable:
			_button(actions,"Summon them to the court",(on_summon as Callable).bind(summon),"Call %s before you" % String(face.get("name","")),true)
		_button(actions,"Close",_select.bind(String(face.get("id",""))),"Close this card")
	else:
		_line(body,String(face.get("title","")))
		_fact(body,"REMEMBERED",String(face.get("note","")))
		if String(face.get("family",""))!="":_fact(body,"",String(face.family)+".")
		var actions:=HFlowContainer.new();body.add_child(actions)
		_button(actions,"Close",_select.bind(String(face.get("id",""))),"Close this card")


# ---------------------------------------------------------------------------
# Vitals, labor, story, hearths, tallies
# ---------------------------------------------------------------------------

## The vitals keep their rows while the same vitals are shown under the same
## heading: each day's figures, trends and causes are written into them.
var _vital_rows:Array=[]
func _refresh_vitals(vitals:Array)->void:
	var shape:Array=[String(data.get("vitals_heading","HOW THEY FARE"))]
	for vital:Dictionary in vitals:shape.append(String(vital.get("id","")))
	if prints.get("vitals_shape")==shape and _vital_rows.size()==vitals.size():
		if prints.get("vitals")==vitals:return
		prints["vitals"]=vitals.duplicate(true)
		for index in vitals.size():_fill_vital(_vital_rows[index],vitals[index])
		return
	prints["vitals_shape"]=shape
	prints["vitals"]=vitals.duplicate(true)
	var box:Control=parts.vitals
	for child in box.get_children():box.remove_child(child);child.queue_free()
	_fill_vitals(box,vitals)
	rebuilds+=1

func _fill_vitals(parent:Control,vitals:Array)->void:
	parent.add_child(_heading(String(data.get("vitals_heading","HOW THEY FARE"))))
	_vital_rows.clear()
	for vital_variant in vitals:
		var vital:Dictionary=vital_variant
		var row:=HBoxContainer.new();row.name="Vital_"+String(vital.get("id",""));row.add_theme_constant_override("separation",10);parent.add_child(row)
		var icon:=TextureRect.new()
		icon.custom_minimum_size=Vector2(36,36);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;row.add_child(icon)
		var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",2);row.add_child(body)
		var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);body.add_child(top)
		var label:=T.make_label("",12,T.MUTED,0.1);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;top.add_child(label)
		var value:=T.make_label("",14,T.INK);value.add_theme_font_override("font",_serif());top.add_child(value)
		var arrow:=T.make_label("",12,T.MUTED)
		arrow.tooltip_text="Compared with last season"
		arrow.mouse_filter=Control.MOUSE_FILTER_PASS;body.add_child(arrow)
		var meter:=Meter.new();meter.track=T.TRACK;meter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(meter)
		var cause:=T.make_label("",12,T.TEXT_SOFT);cause.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(cause)
		var refs:={"icon":icon,"label":label,"value":value,"arrow":arrow,"meter":meter,"cause":cause}
		_vital_rows.append(refs)
		_fill_vital(refs,vital)

## One vital's words, meter and mark, for the first drawing and every refresh.
func _fill_vital(refs:Dictionary,vital:Dictionary)->void:
	var fill:=float(vital.get("fill",0.0))
	var tint:=T.GREEN if fill>=0.66 else (T.AMBER if fill>=0.33 else T.RED)
	(refs.icon as TextureRect).texture=Icons.people_texture(String(vital.get("id","")),tint.lightened(0.25),40)
	_put(refs.label,String(vital.get("label","")))
	_put(refs.value,String(vital.get("value","")))
	var trend:=int(vital.get("trend",0))
	_put(refs.arrow,"better this season" if trend>0 else ("worse this season" if trend<0 else "steady this season"),T.GREEN_TEXT if trend>0 else (T.RED_TEXT if trend<0 else T.MUTED))
	(refs.meter as Meter).set_value(fill,tint)
	_put(refs.cause,String(vital.get("cause","")))

## Words (and their ink) set only when they differ.
static func _put(label:Label,text:String,color:Variant=null)->void:
	if label.text!=text:label.text=text
	if color is Color and label.get_theme_color("font_color")!=color:label.add_theme_color_override("font_color",color)


## What the people are doing today, and who sets it (manual_work.gd): the
## switch "Who sets the daily work: Our leaders | I do", then each task as a
## row of figures and its count. Our leaders: each leader's word on why. The
## ruler: −/+ and ×5 on each row, in whole people, and the plain warnings.
func _fill_labor(parent:Control,labor:Dictionary)->void:
	_labor_head=_labor_header(labor);parent.add_child(_labor_head)
	_labor_rows.clear()
	for task_variant in labor.get("tasks",[]):
		var row:=_labor_row(labor,task_variant);parent.add_child(row);_labor_rows.append(row)
	var hint:=T.make_label("Click a task to see what that work does.",11,T.TEXT_SOFT);hint.name="WorkHint";parent.add_child(hint)


## The labor part's head: its heading, who can work, who sets the work (the
## switch), each leader's word or the ruler's warnings.
func _labor_header(labor:Dictionary)->VBoxContainer:
	var parent:=VBoxContainer.new();parent.name="WorkHead";parent.add_theme_constant_override("separation",7)
	var per:=maxi(1,int(labor.get("per_figure",1)))
	var manual:=bool(labor.get("manual",false))
	parent.add_child(_heading(String(labor.get("heading","WHAT THEY ARE DOING NOW")),"each figure is %s" % ("one person" if per==1 else "%d people" % per)))
	# How many can work: the rows below add up to them.
	if String(labor.get("note",""))!="":
		var note:=T.make_label(String(labor.note),11,T.TEXT_SOFT);note.name="WorkNote";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(note)
	# Who sets the daily work: one plain switch, the current side marked.
	if labor.get("on_leaders") is Callable:
		var switch:=HFlowContainer.new();switch.name="WorkSwitch";switch.add_theme_constant_override("h_separation",6);switch.add_theme_constant_override("v_separation",6);parent.add_child(switch)
		var lead:=T.make_label("Who sets the daily work:",12,T.BODY);lead.size_flags_vertical=Control.SIZE_SHRINK_CENTER;switch.add_child(lead)
		var leaders:=_choice(switch,"Back to our leaders" if manual else "Our leaders (now)",labor.get("on_leaders"),String(labor.get("leaders_tip","")),not manual)
		leaders.name="WorkLeaders"
		var ruler:=_choice(switch,"I do (now)" if manual else "I do",labor.get("on_ruler"),String(labor.get("ruler_tip","")),manual)
		ruler.name="WorkRuler"
	for line_variant in labor.get("who",[]):
		var line:Dictionary=line_variant
		var said:=T.make_label(String(line.get("text","")),12,T.BODY);said.name="WorkWho";said.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		said.tooltip_text=String(line.get("tip",""));said.mouse_filter=Control.MOUSE_FILTER_PASS;parent.add_child(said)
	if manual:
		var yours:=T.make_label("You set the work in every town; the leaders keep to it.",12,T.BODY);yours.name="WorkYours";yours.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(yours)
		for warning_variant in labor.get("warnings",[]):
			var warning:Dictionary=warning_variant
			var tone:=String(warning.get("tone",""))
			var ink:=T.RED_TEXT if tone=="bad" else (T.AMBER_TEXT if tone=="warn" else T.GREEN_TEXT)
			var warn:=T.make_label(String(warning.get("text","")),12,ink);warn.name="WorkWarning";warn.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(warn)
	return parent


## One task: its row of figures and count (with −/+ and ×5 for the ruler)
## and, when it is the task opened, what that work does right under it.
func _labor_row(labor:Dictionary,task_variant:Variant)->VBoxContainer:
	var parent:=VBoxContainer.new();parent.add_theme_constant_override("separation",7)
	var per:=maxi(1,int(labor.get("per_figure",1)))
	var manual:=bool(labor.get("manual",false))
	var on_move:Variant=labor.get("on_move")
	var task:Dictionary=task_variant
	var role:=String(task.get("id",""))
	parent.name="TaskBox_"+role
	# The row and, under it, what the work does now and what ten more would do
	# (role_effects.gd), kept together so an opened task's panel sits just below.
	var head:=VBoxContainer.new();head.name="TaskHead";head.add_theme_constant_override("separation",2);parent.add_child(head)
	var row:=HBoxContainer.new();row.name="Task_"+role;row.add_theme_constant_override("separation",6);head.add_child(row)
	var effect:Dictionary=task.get("effect",{}) if task.get("effect") is Dictionary else {}
	for part:Array in [["now","Effect"],["plus_ten","TenMore"]]:
		if String(effect.get(String(part[0]),""))=="":continue
		var line:=T.make_label(String(effect[part[0]]),11,T.TEXT_SOFT);line.name=String(part[1]);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;head.add_child(line)
	var toggle:=TaskToggle.new(String(task.get("label","")),open_task==role);toggle.name="Task";row.add_child(toggle)
	toggle.pressed.connect(toggle_task.bind(role))
	var crowd:=HBoxContainer.new();crowd.add_theme_constant_override("separation",-3);crowd.size_flags_horizontal=Control.SIZE_EXPAND_FILL;crowd.clip_contents=true;row.add_child(crowd)
	var count:=int(task.get("count",0))
	# The food getters by what they got (plants, game, fish, fields).
	var kinds:Array=[]
	for pair in task.get("mix",[]):
		for index in clampi(ceili(float(pair[1])/float(per)),0,FIGURES_PER_ROW):kinds.append(String(pair[0]))
	if kinds.is_empty():
		for index in (clampi(ceili(float(count)/float(per)),1,FIGURES_PER_ROW) if count>0 else 0):kinds.append(String(task.get("icon",role)))
	for kind:String in kinds.slice(0,FIGURES_PER_ROW):
		var figure:=TextureRect.new();figure.texture=Icons.people_texture(kind,T.BODY_2 if T.is_light() else Color("e7dcc6"),40,false)
		figure.custom_minimum_size=Vector2(20,22);figure.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;figure.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		figure.mouse_filter=Control.MOUSE_FILTER_IGNORE;crowd.add_child(figure)
	if not (task.get("mix",[]) as Array).is_empty():
		var parts:PackedStringArray=[]
		for pair in task.mix:parts.append("%s %d" % [String({"gather":"gathering","hunt":"hunting","fish":"fishing","tend":"tending fields"}.get(String(pair[0]),String(pair[0]))),int(pair[1])])
		row.tooltip_text=", ".join(parts).capitalize().left(1)+", ".join(parts).substr(1)+"."
	var number:=T.make_label(str(count),12,T.INK);number.name="Count";number.custom_minimum_size.x=30;number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(number)
	if manual and on_move is Callable:
		var less:=W.IconButton.new("minus",String(task.get("take_tip","")),24);less.name="Less";less.disabled=not bool(task.get("can_take",false));row.add_child(less)
		less.pressed.connect((on_move as Callable).bind(role,-1))
		var more:=W.IconButton.new("plus",String(task.get("add_tip","")),24);more.name="More";more.disabled=not bool(task.get("can_add",false));row.add_child(more)
		more.pressed.connect((on_move as Callable).bind(role,1))
		var five:=W.text_button("×5",String(task.get("five_tip","")),false,30);five.name="Five";five.disabled=not bool(task.get("can_add",false));row.add_child(five)
		five.pressed.connect((on_move as Callable).bind(role,5))
	if open_task==role:_task_impact(parent,task)
	return parent


## What an open task does: its lead, then each effect with today's numbers.
func _task_impact(parent:Control,task:Dictionary)->void:
	var impact:Dictionary=task.get("impact",open_impact)
	var box:=PanelContainer.new();box.name="TaskImpact"
	box.add_theme_stylebox_override("panel",T.flat(Color(0,0,0,0),T.BORDER_SOFT,1,4,12));parent.add_child(box)
	var inner:=VBoxContainer.new();inner.add_theme_constant_override("separation",8);box.add_child(inner)
	inner.add_child(_heading("WHAT %s DOES" % String(task.get("label","this work")).to_upper()))
	if (impact.get("lines",[]) as Array).is_empty() and String(impact.get("lead",""))=="":
		_line(inner,"Nothing is measured for this work yet.");return
	var panel:=ImpactPanel.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;inner.add_child(panel)
	panel.setup({"lead":String(impact.get("lead","")),"lines":impact.get("lines",[]),"columns":1})


## A plain choice button, the current one marked (home_ledger._choices' look).
func _choice(parent:Node,label:String,callback:Variant,tip:String,active:bool)->Button:
	var b:=Button.new();b.text=label;b.tooltip_text=tip;b.custom_minimum_size=Vector2(28,28)
	b.add_theme_font_size_override("font_size",12);b.add_theme_color_override("font_color",T.INK if active else T.BODY);b.add_theme_color_override("font_hover_color",T.INK)
	var normal:=T.flat(T.ACTIVE_BG if active else Color.TRANSPARENT,T.GOLD if active else T.BORDER_SOFT,1,2,8)
	if active:normal.border_width_bottom=3
	b.add_theme_stylebox_override("normal",normal);b.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,2,8));b.add_theme_stylebox_override("pressed",normal)
	parent.add_child(b)
	if callback is Callable and (callback as Callable).is_valid():b.pressed.connect(callback)
	else:b.disabled=true
	return b


func _fill_story(parent:Control,story:Dictionary)->void:
	parent.add_child(_heading(String(story.get("heading","THIS SEASON"))))
	var items:Array=story.get("items",[])
	if items.is_empty():_line(parent,"Nothing yet told of the people this season.")
	for item_variant in items:
		var item:Dictionary=item_variant
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row)
		var icon:=TextureRect.new();icon.texture=Icons.moment_texture(String(item.get("kind","")),T.GOLD.lightened(0.3),56)
		icon.custom_minimum_size=Vector2(26,26);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
		row.add_child(icon)
		var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",0);row.add_child(body)
		var title:=T.make_label(String(item.get("title","")),12,T.INK);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(title)
		var text:=String(item.get("text",""))
		if text!="":
			var line:=T.make_label(text,11,T.TEXT_SOFT);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(line)
		body.add_child(T.make_label(String(item.get("when","")),9,T.MUTED,0.06))
	var links:=HFlowContainer.new();parent.add_child(links)
	_button(links,String(story.get("link","Open the Chronicle")),story.get("on_open"),"The whole story of the people")


func _fill_hearths(parent:Control,hearths:Array)->void:
	parent.add_child(_heading(String(data.get("hearths_heading","OUR HEARTHS")),String(data.get("hearths_note",""))))
	var flow:=HFlowContainer.new();flow.add_theme_constant_override("h_separation",10);flow.add_theme_constant_override("v_separation",10);parent.add_child(flow)
	for hearth_variant in hearths:
		var hearth:Dictionary=hearth_variant
		var button:=Button.new();button.name="Hearth_"+String(hearth.get("id","")).validate_node_name();button.custom_minimum_size=Vector2(300,88)
		button.tooltip_text=String(hearth.get("tip",""))
		var accent:=T.AMBER if bool(hearth.get("attention",false)) else T.BORDER_SOFT
		button.add_theme_stylebox_override("normal",T.flat(T.ROW_BG,accent,1,4))
		button.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,4))
		var on_click:Variant=hearth.get("on_click")
		if on_click is Callable:button.pressed.connect(on_click)
		flow.add_child(button)
		var row:=HBoxContainer.new();row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,6);row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation",10);button.add_child(row)
		var art:=Buildings.picture(int(hearth.get("art",0)),96,76);row.add_child(art)
		var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_theme_constant_override("separation",2);row.add_child(body)
		var title:=T.make_label(String(hearth.get("name","")),15,T.INK);title.add_theme_font_override("font",_serif());title.clip_text=true;body.add_child(title)
		body.add_child(T.make_label(String(hearth.get("sub","")),10,T.MUTED,0.06))
		var needs:=T.make_label(String(hearth.get("needs","")),11,T.RED if bool(hearth.get("attention",false)) else T.BODY);needs.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;needs.custom_minimum_size.x=170;body.add_child(needs)
	for action_variant in data.get("hearth_actions",[]):
		var action:Dictionary=action_variant
		_button(flow,String(action.get("label","")),action.get("on_press"),String(action.get("sub","")),true)


func _fill_tallies(parent:Control,tallies:Array)->void:
	var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",6);row.add_theme_constant_override("v_separation",6);parent.add_child(row)
	var head:=T.make_label(String(data.get("tallies_heading","TALLIES"))+"  ",10,T.GOLD,0.1);head.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(head)
	for tally_variant in tallies:
		var tally:Dictionary=tally_variant
		_button(row,String(tally.get("label","")),tally.get("on_press"),String(tally.get("tip","")))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _layout()->void:
	if columns==null:return
	var wide:=size.x>=TWO_COLUMNS_AT or (size.x<=0.0 and get_parent_area_size().x>=TWO_COLUMNS_AT)
	columns.columns=2 if wide else 1


func _part(parent:Node,part_name:String)->VBoxContainer:
	var box:=VBoxContainer.new();box.name=part_name;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",7)
	parent.add_child(box)
	return box


func _rebuild_if_changed(part:String,value:Variant,fill:Callable)->void:
	var print_value:=_print(value)
	if prints.get(part,"")==print_value:return
	prints[part]=print_value
	var box:Control=faces_row if part=="faces" else (card if part=="card" else parts[part])
	for child in box.get_children():
		box.remove_child(child);child.queue_free()
	var target:Control=box
	if part=="card":
		var inner:=VBoxContainer.new();card.add_child(inner);target=inner
	fill.call(target,value)
	rebuilds+=1


static func _print(value:Variant)->String:
	## Stable text for part data; callables are named, not hashed.
	match typeof(value):
		TYPE_DICTIONARY:
			var keys:Array=(value as Dictionary).keys();keys.sort()
			var out:PackedStringArray=[]
			for key in keys:out.append(str(key)+":"+_print(value[key]))
			return "{"+",".join(out)+"}"
		TYPE_ARRAY:
			var out:PackedStringArray=[]
			for item in value:out.append(_print(item))
			return "["+",".join(out)+"]"
		TYPE_CALLABLE:return "fn:"+String((value as Callable).get_method())+str((value as Callable).get_bound_arguments())
		TYPE_OBJECT:return "obj"
	return var_to_str(value)


func _section(title:String,content:Control,note:String="")->VBoxContainer:
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6)
	box.add_child(_heading(title,note));box.add_child(content)
	return box


func _heading(title:String,note:String="")->HBoxContainer:
	var row:=HBoxContainer.new()
	var head:=T.make_label(title,10,T.GOLD,0.1);head.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(head)
	if note!="":
		var hint:=T.make_label(note,10,T.MUTED);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(hint)
	return row


func _line(parent:Node,text:String)->void:
	var label:=T.make_label(text,12,T.BODY);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label)


func _fact(parent:Node,head:String,text:String)->void:
	if text.strip_edges()=="":return
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row)
	if head!="":
		var label:=T.make_label(head,9,T.MUTED,0.1);label.custom_minimum_size.x=62;label.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;row.add_child(label)
	var body:=T.make_label(text,12,T.BODY);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(body)


func _button(parent:Node,label:String,callback:Variant,tip:String,primary:bool=false)->void:
	var b:=Button.new();b.text=label;b.tooltip_text=tip;b.custom_minimum_size=Vector2(28,28)
	b.add_theme_font_size_override("font_size",12);b.add_theme_color_override("font_color",T.INK if primary else T.BODY);b.add_theme_color_override("font_hover_color",T.INK)
	b.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG if primary else Color.TRANSPARENT,T.GOLD if primary else T.BORDER_SOFT,1,3,7))
	b.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,3,7))
	parent.add_child(b)
	if callback is Callable and (callback as Callable).is_valid():b.pressed.connect(callback)
	else:b.disabled=true


func _hearth(block:Dictionary)->bool:
	return bool((block.get("scene",{}) as Dictionary).get("hearth",true))


static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


static func _serif(italic:bool=false)->Font:
	return preload("res://scripts/hud/hud_tokens.gd").voice_font(italic)
