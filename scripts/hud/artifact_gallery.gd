extends Control
## Artifacts & Allure — the culture section's museum catalogue.
## Reads only the ArtifactCulture facade (scripts/artifact_culture.gd) and acts
## through its set_study_focus / set_exhibited calls. Pauses the simulation
## while open, like the other full-screen reading rooms.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const DISPLAY_FONT:=preload("res://assets/fonts/cinzel/Cinzel.ttf")
const CULTURE_PATH:="res://scripts/artifact_culture.gd"
## Inner classes reach the shared static helpers through this self-reference.
const Kit:=preload("res://scripts/hud/artifact_gallery.gd")
const PAGE_SIZE:=24
const CARD_MIN_WIDTH:=196.0
const CARD_GAP:=14
const TIER_NAMES:=["Common","Unusual","Rare","Exceptional","Legendary"]
const VIEWS:=[["all","All"],["studied","Studied"],["in_study","In study"],["unstudied","Unstudied"],["exhibited","On exhibit"],["sets","Sets"],["rumors","Rumored treasures"]]
const SORTS:=[["rarity","Rarity"],["prestige","Prestige"],["recent","Recently found"],["value","Studied value"]]
const VEIL_CODE:="""
shader_type canvas_item;
uniform float veil:hint_range(0.0,1.0)=0.0;
uniform float vignette:hint_range(0.0,1.0)=0.0;
uniform vec4 paper:source_color=vec4(0.925,0.894,0.831,1.0);
void fragment(){
	vec4 c=COLOR;
	float l=dot(c.rgb,vec3(0.299,0.587,0.114));
	vec3 sepia=vec3(l*1.02+0.05,l*0.92+0.03,l*0.74+0.01);
	vec3 veiled=mix(sepia,paper.rgb,0.42);
	c.rgb=mix(c.rgb,veiled,veil);
	float d=distance(UV,vec2(0.5));
	c.rgb*=1.0-vignette*smoothstep(0.42,0.78,d);
	COLOR=c;
}
"""

static var _veil_shader:Shader
static var _serif:SystemFont
static var _italic:SystemFont

var source:Variant=null
var hud:Node
var terrain:Node
var layer:CanvasLayer
var pause=preload("res://scripts/hud/simulation_pause.gd").new()
var view:="all"
var sort:="rarity"
var search_text:=""
var page:=0
var selected_id:=""
var message:=""
var narrow:=false
var narrow_detail:=false
var method_cache:Dictionary={}
var summary_data:Dictionary={}
var page_result:Dictionary={}
var signature:=""
var timer:=0.0

var panel:PanelContainer
var seal:Control
var allure_title:Label
var allure_note:Label
var stats_label:Label
var breakdown:Control
var breakdown_legend:HFlowContainer
var effects_box:VBoxContainer
var tab_buttons:Dictionary={}
var search:LineEdit
var sort_select:OptionButton
var main:HBoxContainer
var browse:VBoxContainer
var browse_scroll:ScrollContainer
var browse_body:VBoxContainer
var grid:GridContainer
var pager:HBoxContainer
var pager_label:Label
var prev_button:Button
var next_button:Button
var detail_scroll:ScrollContainer
var detail_body:VBoxContainer
var detail_back:Button
var header:HBoxContainer
var effects_column:VBoxContainer
var detail_column:VBoxContainer

# ---------------------------------------------------------------- shared API

static func facade()->Variant:
	return load(CULTURE_PATH) if ResourceLoader.exists(CULTURE_PATH) else null

static func open(hud_node:Node,terrain_node:Node=null,focus_id:String="",source_override:Variant=null)->Control:
	var host:Node=hud_node if is_instance_valid(hud_node) else (Engine.get_main_loop() as SceneTree).current_scene
	var previous:Variant=host.get_meta("artifact_gallery") if host.has_meta("artifact_gallery") else null
	if is_instance_valid(previous):previous.queue_free()
	var canvas:=CanvasLayer.new();canvas.layer=90;host.add_child(canvas);host.set_meta("artifact_gallery",canvas)
	var gallery=new()
	gallery.hud=hud_node;gallery.terrain=terrain_node;gallery.layer=canvas;gallery.selected_id=focus_id
	if source_override!=null:gallery.source=source_override
	canvas.add_child(gallery)
	return gallery

static func tier_color(index:int)->Color:
	var light:=[Color("786e5f"),Color("4c7746"),Color("365c98"),Color("774183"),Color("9c6a12")]
	var dark:=[Color("b8ae9b"),Color("8fbb85"),Color("8eaee2"),Color("c197d2"),Color("e6bb58")]
	return (light if T.is_light() else dark)[clampi(index,0,4)]

static func tier_name(item:Dictionary)->String:
	var named:=String(item.get("rarity",""))
	return named if not named.is_empty() else TIER_NAMES[clampi(int(item.get("rarity_index",0)),0,4)]

static func plate_color()->Color:
	return Color("f8f1e3") if T.is_light() else Color("121b1e")

static func serif_font()->SystemFont:
	if _serif==null:_serif=SystemFont.new();_serif.font_names=PackedStringArray(["Georgia","Noto Serif","Times New Roman","serif"])
	return _serif

static func italic_font()->SystemFont:
	if _italic==null:_italic=SystemFont.new();_italic.font_names=PackedStringArray(["Georgia","Noto Serif","Times New Roman","serif"]);_italic.font_italic=true
	return _italic

static func veil_material(amount:float,vignette:float=0.0)->ShaderMaterial:
	if _veil_shader==null:_veil_shader=Shader.new();_veil_shader.code=VEIL_CODE
	var material:=ShaderMaterial.new();material.shader=_veil_shader
	material.set_shader_parameter("veil",clampf(amount,0,1));material.set_shader_parameter("vignette",vignette)
	return material

static func veil_for(item:Dictionary)->float:
	if String(item.get("state",""))=="studied":return 0.0
	return lerpf(.86,.22,clampf(float(item.get("study_progress",0)),0,1))

static func custody_text(days:int)->String:
	if days<1:return "newly arrived"
	var years:=days/360;var rest:=days%360
	if years==0:return "%d day%s" % [rest,"" if rest==1 else "s"]
	return "%d year%s%s" % [years,"" if years==1 else "s",(", %d days" % rest) if rest>0 else ""]

static func cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if not text.is_empty() else text

static func number(value:float)->String:
	var size:=absf(value)
	if size<.0005:return "0"
	if size>=100:return "%.0f" % value
	if size>=10:return "%.1f" % value
	if size>=.1:return "%.2f" % value
	return "%.3f" % value

static func state_text(item:Dictionary)->String:
	match String(item.get("state","")):
		"studied":return "Studied"
		"in_study":return "In study · %d%%" % roundi(float(item.get("study_progress",0))*100)
	return "Unstudied" if float(item.get("study_progress",0))<=0 else "Unstudied · %d%%" % roundi(float(item.get("study_progress",0))*100)

static func label(parent:Node,text:String,size:int,color:Color,wrap:bool=true,spacing:float=0.0)->Label:
	var node:=T.make_label(text,size,color,spacing)
	if wrap:node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if parent:parent.add_child(node)
	return node

static func serif(parent:Node,text:String,size:int,color:Color=T.INK,italic:bool=false)->Label:
	var node:=label(parent,text,size,color)
	node.add_theme_font_override("font",italic_font() if italic else serif_font())
	return node

static func display(parent:Node,text:String,size:int,color:Color=T.INK)->Label:
	var node:=label(parent,text,size,color)
	node.add_theme_font_override("font",DISPLAY_FONT)
	return node

static func action_button(parent:Node,text:String,callback:Callable,primary:bool=false,tip:String="")->Button:
	var button:=Button.new();button.text=text;button.tooltip_text=tip;button.custom_minimum_size.y=34
	button.add_theme_font_size_override("font_size",13);button.focus_mode=Control.FOCUS_NONE
	var normal:=T.flat(T.GOLD_WASH if primary else T.BUTTON_BG,T.GOLD if primary else T.BORDER_2,1,3);normal.content_margin_left=14;normal.content_margin_right=14
	var hover:=T.flat(T.HOVER_BG,T.GOLD,1,3);hover.content_margin_left=14;hover.content_margin_right=14
	var disabled:=T.flat(Color(0,0,0,0),T.BORDER_SOFT,1,3);disabled.content_margin_left=14;disabled.content_margin_right=14
	button.add_theme_stylebox_override("normal",normal);button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover);button.add_theme_stylebox_override("disabled",disabled)
	button.add_theme_color_override("font_color",T.GOLD_BRIGHT if primary else T.BODY);button.add_theme_color_override("font_hover_color",T.INK);button.add_theme_color_override("font_disabled_color",T.DISABLED)
	if callback.is_valid():button.pressed.connect(callback)
	else:button.disabled=true
	if parent:parent.add_child(button)
	return button

static func pips(parent:Node,index:int,color:Color)->Control:
	var marks:=RarityPips.new();marks.index=index;marks.color=color;parent.add_child(marks);return marks

static func mini_plate(item:Dictionary,height:float,on_press:Callable)->Control:
	## Small framed artwork used in the culture showcase and set rows.
	var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(height,height);frame.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	var tier:=tier_color(int(item.get("rarity_index",0)))
	var style:=T.flat(Color("ece4d4"),tier,1,3);style.set_content_margin_all(3);frame.add_theme_stylebox_override("panel",style)
	frame.tooltip_text="%s\n%s · %s" % [String(item.get("name","")),tier_name(item),state_text(item)]
	var art:=TextureRect.new();art.texture=item.get("texture");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.material=veil_material(veil_for(item),.25);art.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.add_child(art)
	var marks:=CardMarks.new();marks.item=item;marks.tier=tier;marks.compact=true;frame.add_child(marks)
	if on_press.is_valid():
		frame.gui_input.connect(func(event:InputEvent)->void:
			if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:on_press.call(String(item.get("id",""))))
	return frame

static func showcase(block:Dictionary)->Control:
	## The culture section's entry point: allure seal, finest pieces, a door in.
	var box:=VBoxContainer.new();box.name="ArtifactShowcase";box.add_theme_constant_override("separation",10)
	var summary:Dictionary=block.get("summary",{})
	var on_open:Callable=block.get("on_open",Callable())
	var on_study:Callable=block.get("on_study",Callable())
	label(box,"ARTIFACTS & ALLURE",11,T.GOLD,false,.08)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",18);box.add_child(top)
	var medal:=Seal.new();medal.value=float(summary.get("allure",0));medal.custom_minimum_size=Vector2(112,112);medal.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;top.add_child(medal)
	medal.tooltip_text=_breakdown_tip(summary)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",5);top.add_child(words)
	serif(words,String(summary.get("allure_label","Unremarked")).capitalize(),24)
	var count:=int(summary.get("collection_count",0))
	label(words,"%d piece%s · %d studied · %d in study · %d on exhibit" % [count,"" if count==1 else "s",int(summary.get("studied_count",0)),int(summary.get("in_study_count",0)),int(summary.get("exhibited_count",0))],12,T.TEXT_SOFT)
	var effects:Array=summary.get("allure_effects",[])
	for effect:Dictionary in effects.slice(0,2):
		label(words,"◆  "+String(effect.get("text","")),12,T.BODY)
	if effects.is_empty():label(words,"Studied and exhibited pieces make our people admired abroad.",12,T.BODY)
	var highlights:Array=block.get("highlights",[])
	if not highlights.is_empty():
		var shelf:=HBoxContainer.new();shelf.name="ShowcaseShelf";shelf.add_theme_constant_override("separation",10);box.add_child(shelf)
		for item:Dictionary in highlights.slice(0,4):
			var plate:=mini_plate(item,96,on_open);plate.size_flags_horizontal=Control.SIZE_EXPAND_FILL;shelf.add_child(plate)
		for missing in range(highlights.size(),4):
			var empty:=Control.new();empty.size_flags_horizontal=Control.SIZE_EXPAND_FILL;empty.custom_minimum_size.y=96;shelf.add_child(empty)
	else:
		label(box,"No pieces yet. Explorers bring back finds from uncharted ground; peaceful neighbors can gift objects.",12,T.TEXT_SOFT)
	var study:Dictionary=summary.get("study_role",{})
	var actions:=HFlowContainer.new();actions.add_theme_constant_override("h_separation",10);actions.add_theme_constant_override("v_separation",8);box.add_child(actions)
	var open_button:=action_button(actions,"Open the collection",on_open.bind("") if on_open.is_valid() else Callable(),true,"Browse, study and exhibit every piece we hold")
	open_button.name="OpenArtifactGallery"
	action_button(actions,"Study team · %d researcher%s" % [int(study.get("workers",0)),"" if int(study.get("workers",0))==1 else "s"],on_study,false,String(study.get("rate_text","Artifact study is part of the research allocation.")))
	return box

static func _breakdown_tip(summary:Dictionary)->String:
	var lines:Array[String]=["Allure %d / 100" % roundi(float(summary.get("allure",0))*100)]
	for part:Dictionary in summary.get("allure_breakdown",[]):
		lines.append("%s  +%d · %s" % [String(part.get("source","")),roundi(float(part.get("value",0))*100),String(part.get("text",""))])
	return "\n".join(lines)

# ---------------------------------------------------------------- lifecycle

func _ready()->void:
	name="ArtifactGallery"
	theme=T.control_theme()
	if source==null:source=facade()
	pause.acquire(get_tree().current_scene)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim:=ColorRect.new();dim.color=Color(.02,.03,.03,.66);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(dim)
	dim.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:dim.accept_event();close())
	panel=PanelContainer.new();panel.name="GalleryPanel";panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var style:=T.flat(T.DOCK_BG,T.BORDER_2,1,6);style.content_margin_left=24;style.content_margin_right=24;style.content_margin_top=18;style.content_margin_bottom=16
	style.shadow_color=Color(0,0,0,.35);style.shadow_size=18
	panel.add_theme_stylebox_override("panel",style);add_child(panel)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",10);panel.add_child(root)
	_build_header(root)
	root.add_child(Flourish.new())
	_build_controls(root)
	main=HBoxContainer.new();main.size_flags_vertical=Control.SIZE_EXPAND_FILL;main.add_theme_constant_override("separation",22);root.add_child(main)
	browse=VBoxContainer.new();browse.size_flags_horizontal=Control.SIZE_EXPAND_FILL;browse.size_flags_stretch_ratio=1.6;browse.add_theme_constant_override("separation",8);main.add_child(browse)
	browse_scroll=ScrollContainer.new();browse_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;browse_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;browse.add_child(browse_scroll)
	browse_body=VBoxContainer.new();browse_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;browse_body.add_theme_constant_override("separation",12);browse_scroll.add_child(browse_body)
	pager=HBoxContainer.new();pager.add_theme_constant_override("separation",10);browse.add_child(pager)
	prev_button=action_button(pager,"‹  Previous",func()->void:page=maxi(0,page-1);refresh(true))
	pager_label=label(pager,"",12,T.TEXT_SOFT);pager_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	next_button=action_button(pager,"Next  ›",func()->void:page+=1;refresh(true))
	detail_column=VBoxContainer.new();detail_column.name="DetailColumn";detail_column.custom_minimum_size.x=430;main.add_child(detail_column)
	detail_back=action_button(detail_column,"‹  Back to the collection",func()->void:narrow_detail=false;_layout())
	detail_scroll=ScrollContainer.new();detail_scroll.name="DetailScroll";detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;detail_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;detail_column.add_child(detail_scroll)
	detail_body=VBoxContainer.new();detail_body.name="DetailPlate";detail_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail_scroll.add_child(detail_body)
	resized.connect(_layout);panel.minimum_size_changed.connect(_layout.call_deferred)
	_layout();refresh(true)

func _exit_tree()->void:
	pause.release()

func close()->void:
	if is_instance_valid(layer):layer.queue_free()
	else:queue_free()

func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if narrow and narrow_detail:narrow_detail=false;_layout()
		else:close()

func _process(delta:float)->void:
	timer+=delta
	if timer>=1.0:timer=0.0;refresh(false)

# ---------------------------------------------------------------- facade access

func has_api(method:String)->bool:
	if source==null:return false
	if method_cache.is_empty():
		if source is Script:
			for entry:Dictionary in (source as Script).get_script_method_list():method_cache[String(entry.name)]=true
		method_cache["__built"]=true
	if source is Script:return method_cache.has(method)
	return source.has_method(method)

func api(method:String,arguments:Array=[],fallback:Variant=null)->Variant:
	if not has_api(method):return fallback
	var result:Variant=source.callv(method,arguments)
	return fallback if result==null else result

# ---------------------------------------------------------------- building

func _build_header(root:VBoxContainer)->void:
	header=HBoxContainer.new();header.add_theme_constant_override("separation",24);root.add_child(header)
	seal=Seal.new();seal.name="AllureSeal";seal.custom_minimum_size=Vector2(138,138);seal.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;header.add_child(seal)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.size_flags_stretch_ratio=1.25;words.add_theme_constant_override("separation",4);header.add_child(words)
	label(words,"OUR COLLECTION · CULTURE",11,T.GOLD,false,.12)
	display(words,"Artifacts & Allure",34)
	allure_title=serif(words,"",18,T.BODY,true)
	stats_label=label(words,"",13,T.TEXT_SOFT)
	breakdown=Breakdown.new();breakdown.custom_minimum_size=Vector2(0,10);words.add_child(breakdown)
	breakdown_legend=HFlowContainer.new();breakdown_legend.add_theme_constant_override("h_separation",14);breakdown_legend.add_theme_constant_override("v_separation",2);words.add_child(breakdown_legend)
	effects_column=VBoxContainer.new();effects_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;effects_column.add_theme_constant_override("separation",6);header.add_child(effects_column)
	label(effects_column,"WHAT OUR ALLURE DOES",11,T.GOLD,false,.12)
	effects_box=VBoxContainer.new();effects_box.add_theme_constant_override("separation",6);effects_column.add_child(effects_box)
	var close_button:=Button.new();close_button.name="CloseGallery";close_button.text="×";close_button.custom_minimum_size=Vector2(40,38);close_button.tooltip_text="Close · Escape or click outside";close_button.add_theme_font_size_override("font_size",22);close_button.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;close_button.pressed.connect(close);header.add_child(close_button)

func _build_controls(root:VBoxContainer)->void:
	var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",12);root.add_child(controls)
	var tabs:=HFlowContainer.new();tabs.name="GalleryTabs";tabs.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tabs.add_theme_constant_override("h_separation",6);tabs.add_theme_constant_override("v_separation",6);controls.add_child(tabs)
	for spec:Array in VIEWS:
		var id:=String(spec[0])
		var button:=Button.new();button.name="Tab_"+id;button.focus_mode=Control.FOCUS_NONE;button.custom_minimum_size.y=32;button.add_theme_font_size_override("font_size",13)
		button.pressed.connect(func()->void:set_view(id));tabs.add_child(button);tab_buttons[id]=button
	search=LineEdit.new();search.name="GallerySearch";search.placeholder_text="Search the collection";search.custom_minimum_size=Vector2(250,32);search.clear_button_enabled=true;controls.add_child(search)
	search.text_changed.connect(func(value:String)->void:search_text=value;page=0;refresh(true))
	sort_select=OptionButton.new();sort_select.name="GallerySort";sort_select.custom_minimum_size=Vector2(170,32);sort_select.focus_mode=Control.FOCUS_NONE;controls.add_child(sort_select)
	for spec:Array in SORTS:sort_select.add_item("Sort · "+String(spec[1]));sort_select.set_item_metadata(sort_select.item_count-1,spec[0])
	sort_select.item_selected.connect(func(index:int)->void:sort=String(sort_select.get_item_metadata(index));page=0;refresh(true))

func set_view(id:String)->void:
	view=id;page=0;refresh(true)

func _style_tabs()->void:
	var counts:={"all":int(summary_data.get("collection_count",0)),"studied":int(summary_data.get("studied_count",0)),"in_study":int(summary_data.get("in_study_count",0)),"unstudied":int(summary_data.get("unstudied_count",0)),"exhibited":int(summary_data.get("exhibited_count",0))}
	for spec:Array in VIEWS:
		var id:=String(spec[0]);var button:Button=tab_buttons[id];var active:=id==view
		button.text=String(spec[1])+("  %d" % int(counts[id]) if counts.has(id) else "")
		var style:=T.flat(T.GOLD_WASH if active else Color(0,0,0,0),T.GOLD if active else T.BORDER_SOFT,1,14);style.content_margin_left=14;style.content_margin_right=14
		var hover:=T.flat(T.HOVER_BG,T.GOLD,1,14);hover.content_margin_left=14;hover.content_margin_right=14
		button.add_theme_stylebox_override("normal",style);button.add_theme_stylebox_override("hover",hover if not active else style);button.add_theme_stylebox_override("pressed",style)
		button.add_theme_color_override("font_color",T.GOLD_BRIGHT if active else T.TEXT_SOFT);button.add_theme_color_override("font_hover_color",T.INK)
	search.editable=view!="rumors"
	sort_select.disabled=view in ["sets","rumors"]

# ---------------------------------------------------------------- refresh

func refresh(force:bool)->void:
	summary_data=api("summary",[],{})
	var sig:=str([summary_data.get("collection_count",0),summary_data.get("studied_count",0),summary_data.get("in_study_count",0),summary_data.get("exhibited_count",0),snappedf(float(summary_data.get("allure",0)),.001),summary_data.get("study_role",{}).get("focus_id",""),view,sort,search_text,page])
	if not force and sig==signature:return
	signature=sig
	_render_header()
	_style_tabs()
	for child in browse_body.get_children():browse_body.remove_child(child);child.queue_free()
	grid=null
	match view:
		"sets":_render_sets()
		"rumors":_render_rumors()
		_:_render_grid()
	_render_detail()

func _render_header()->void:
	seal.value=float(summary_data.get("allure",0));seal.queue_redraw()
	seal.tooltip_text=_breakdown_tip(summary_data)
	if source==null:
		allure_title.text="The collection ledger is not yet kept."
		stats_label.text="Artifact records will appear here once the culture ledger is available."
		return
	allure_title.text="%s — %s" % [String(summary_data.get("allure_label","Unremarked")).capitalize(),_allure_phrase(float(summary_data.get("allure",0)))]
	var totals:Dictionary=summary_data.get("value_totals",{})
	stats_label.text="%d pieces held · %.1f prestige · studied value: culture +%s · research +%s · economic %s" % [int(summary_data.get("collection_count",0)),float(summary_data.get("prestige_total",0)),number(float(totals.get("culture",0))),number(float(totals.get("research",0))),number(float(totals.get("economic",0)))]
	var parts:Array=summary_data.get("allure_breakdown",[])
	breakdown.parts=parts;breakdown.queue_redraw()
	for child in breakdown_legend.get_children():child.queue_free()
	for index in parts.size():
		var part:Dictionary=parts[index]
		var key:=HBoxContainer.new();key.add_theme_constant_override("separation",5);key.tooltip_text=String(part.get("text",""));key.mouse_filter=Control.MOUSE_FILTER_PASS;breakdown_legend.add_child(key)
		var swatch:=ColorRect.new();swatch.color=Breakdown.color_at(index);swatch.custom_minimum_size=Vector2(9,9);swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE;key.add_child(swatch)
		var text:=label(key,"%s +%d" % [cap(String(part.get("source",""))),roundi(float(part.get("value",0))*100)],11,T.TEXT_SOFT,false);text.mouse_filter=Control.MOUSE_FILTER_PASS;text.tooltip_text=String(part.get("text",""))
	for child in effects_box.get_children():child.queue_free()
	var effects:Array=summary_data.get("allure_effects",[])
	for effect:Dictionary in effects:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);effects_box.add_child(row)
		var bullet:=label(row,"◆",9,T.GOLD,false);bullet.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;bullet.custom_minimum_size.y=18;bullet.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",0);row.add_child(column)
		label(column,String(effect.get("target","")).to_upper(),10,T.MUTED,false,.08)
		label(column,String(effect.get("text","")),13,T.BODY)
	if effects.is_empty():label(effects_box,"Allure has no effect yet. Study pieces and put them on exhibit to be admired abroad.",13,T.TEXT_SOFT)

static func _allure_phrase(value:float)->String:
	if value<.08:return "few beyond our borders know our work"
	if value<.25:return "travelers mention what we keep"
	if value<.45:return "neighbors speak of our collection"
	if value<.7:return "our treasures draw envoys and newcomers"
	return "our halls are a wonder of the known world"

func _query()->Dictionary:
	return {"status":view,"sort":sort,"search":search_text.strip_edges(),"page":page,"page_size":PAGE_SIZE}

func _render_grid()->void:
	pager.visible=true
	page_result=api("artifacts",[_query()],{"items":[],"total":0,"page":0,"pages":1})
	var pages:=maxi(1,int(page_result.get("pages",1)))
	if page>=pages:page=pages-1;page_result=api("artifacts",[_query()],page_result)
	var items:Array=page_result.get("items",[])
	var total:=int(page_result.get("total",items.size()))
	pager_label.text="Page %d of %d  ·  %d piece%s" % [page+1,pages,total,"" if total==1 else "s"]
	prev_button.disabled=page<=0;next_button.disabled=page>=pages-1
	if selected_id.is_empty() and not items.is_empty():selected_id=String(items[0].get("id",""))
	if items.is_empty():
		_empty_state(browse_body)
		return
	grid=GridContainer.new();grid.name="ArtifactGrid";grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",CARD_GAP);grid.add_theme_constant_override("v_separation",CARD_GAP);browse_body.add_child(grid)
	var focus:=String(summary_data.get("study_role",{}).get("focus_id",""))
	for item:Dictionary in items:
		var card:=ArtifactCard.new();card.item=item;card.selected=String(item.get("id",""))==selected_id;card.focused=String(item.get("id",""))==focus;card.on_press=select
		grid.add_child(card)
	_fit_columns()

func _empty_state(parent:Node)->void:
	var box:=VBoxContainer.new();box.name="EmptyGallery";box.add_theme_constant_override("separation",8);box.custom_minimum_size.y=220;box.alignment=BoxContainer.ALIGNMENT_CENTER;parent.add_child(box)
	var title:=serif(box,"An empty cabinet" if int(summary_data.get("collection_count",0))==0 else "Nothing here matches",22,T.INK,true);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var text:=label(box,"Explorers bring back finds from uncharted ground, and peaceful neighbors can gift or trade objects. Every piece we hold will be catalogued here." if int(summary_data.get("collection_count",0))==0 else "Try another view, or clear the search.",13,T.TEXT_SOFT);text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func _fit_columns()->void:
	if grid==null or not is_instance_valid(grid):return
	grid.columns=maxi(1,int((_browse_width()+CARD_GAP)/(CARD_MIN_WIDTH+CARD_GAP)))

func _browse_width()->float:
	## Derived from the panel, not the grid, so columns never force the panel wider.
	var width:=panel.size.x-48.0-16.0
	if detail_column.visible:width-=detail_column.custom_minimum_size.x+22.0
	return maxf(CARD_MIN_WIDTH,width)

func select(id:String)->void:
	selected_id=id;message=""
	if grid and is_instance_valid(grid):
		for card in grid.get_children():
			if card is ArtifactCard:card.selected=String(card.item.get("id",""))==id;card.restyle()
	if narrow:narrow_detail=true;_layout()
	_render_detail()

# ---------------------------------------------------------------- sets & rumors

func _all_items()->Array:
	var result:Dictionary=api("artifacts",[{"status":"all","sort":"rarity","search":"","page":0,"page_size":100000}],{"items":[]})
	return result.get("items",[])

static func parse_progress(text:String)->Vector2i:
	var parts:=text.split(" of ")
	if parts.size()==2 and parts[0].strip_edges().is_valid_int() and parts[1].strip_edges().is_valid_int():
		return Vector2i(int(parts[0].strip_edges()),int(parts[1].strip_edges()))
	return Vector2i(-1,-1)

func collection_sets()->Array:
	var groups:Dictionary={}
	for item:Dictionary in _all_items():
		var set_name:=String(item.get("set_name",""))
		if set_name.is_empty():continue
		if not groups.has(set_name):groups[set_name]={"name":set_name,"site":String(item.get("site_name","")),"items":[],"total":0}
		groups[set_name].items.append(item)
		var progress:=parse_progress(String(item.get("set_progress","")))
		groups[set_name].total=maxi(int(groups[set_name].total),progress.y)
	var sets:Array=groups.values()
	for group:Dictionary in sets:group.total=maxi(int(group.total),group.items.size())
	sets.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ra:=float(a.items.size())/maxf(1,a.total);var rb:=float(b.items.size())/maxf(1,b.total)
		return String(a.name)<String(b.name) if is_equal_approx(ra,rb) else ra>rb)
	return sets

func _render_sets()->void:
	pager.visible=false
	var intro:=label(browse_body,"Pieces left by the same lost people belong together. A completed set is worth more than its parts; the missing pieces still lie somewhere in the land.",13,T.TEXT_SOFT)
	intro.name="SetsIntro"
	var query:=search_text.strip_edges().to_lower()
	var shown:=0
	for group:Dictionary in collection_sets():
		if not query.is_empty() and not (String(group.name)+" "+String(group.site)).to_lower().contains(query):continue
		shown+=1
		var card:=PanelContainer.new();card.name="Set_%d" % shown
		var style:=T.flat(plate_color(),T.BORDER_SOFT,1,5);style.set_content_margin_all(14);card.add_theme_stylebox_override("panel",style);browse_body.add_child(card)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);card.add_child(column)
		var title_row:=HBoxContainer.new();title_row.add_theme_constant_override("separation",12);column.add_child(title_row)
		var titles:=VBoxContainer.new();titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL;titles.add_theme_constant_override("separation",2);title_row.add_child(titles)
		serif(titles,String(group.name),20)
		if not String(group.site).is_empty():label(titles,"From "+String(group.site),12,T.TEXT_SOFT)
		var held:int=group.items.size();var total:=int(group.total)
		var tally:=display(title_row,"%d / %d" % [held,total],20,T.GOLD if held>=total else T.INK);tally.size_flags_horizontal=Control.SIZE_SHRINK_END;tally.autowrap_mode=TextServer.AUTOWRAP_OFF
		var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=5;bar.value=100.0*held/maxf(1,total);bar.add_theme_stylebox_override("background",T.flat(T.TRACK,Color(0,0,0,0),0,2));bar.add_theme_stylebox_override("fill",T.flat(T.GOLD,Color(0,0,0,0),0,2));column.add_child(bar)
		var shelf:=HFlowContainer.new();shelf.add_theme_constant_override("h_separation",10);shelf.add_theme_constant_override("v_separation",10);column.add_child(shelf)
		for item:Dictionary in group.items:shelf.add_child(mini_plate(item,92,select))
		for missing in range(held,total):
			var ghost:=Silhouette.new();ghost.custom_minimum_size=Vector2(92,92);ghost.tooltip_text="A missing piece of this set. Its companions suggest it still lies near where they were found.";shelf.add_child(ghost)
		label(column,"Complete — the whole set is ours." if held>=total else "%d piece%s still missing." % [total-held,"" if total-held==1 else "s"],12,T.GOLD if held>=total else T.TEXT_SOFT)
	if shown==0:
		var none:=serif(browse_body,"No sets recognized yet" if query.is_empty() else "No set matches the search",20,T.INK,true);none.name="EmptySets"
		label(browse_body,"When pieces share a maker, a site and a style, scholars recognize them as one set.",13,T.TEXT_SOFT)

static func confidence_word(value:float)->String:
	if value<.34:return "A faint rumor"
	if value<.67:return "An uncertain account"
	return "A credible account"

func _render_rumors()->void:
	pager.visible=false
	label(browse_body,"What travelers, envoys and scouts have told us of treasures still in the ground. Rumors give landmarks and directions, never exact places.",13,T.TEXT_SOFT)
	var rumors:Array=api("rumored_sites",["player"],[])
	var notes:=GridContainer.new();notes.name="RumorNotes";notes.columns=2 if _browse_width()>620 else 1;notes.add_theme_constant_override("h_separation",14);notes.add_theme_constant_override("v_separation",14);browse_body.add_child(notes)
	for rumor:Dictionary in rumors:
		var note:=RumorNote.new();note.rumor=rumor;note.size_flags_horizontal=Control.SIZE_EXPAND_FILL;notes.add_child(note)
	if rumors.is_empty():
		var none:=serif(browse_body,"No rumors have reached us",20,T.INK,true);none.name="EmptyRumors"
		label(browse_body,"Envoys, traders and scouts may hear of ancient hoards, shrines and burial grounds.",13,T.TEXT_SOFT)

# ---------------------------------------------------------------- detail plate

func _render_detail()->void:
	for child in detail_body.get_children():detail_body.remove_child(child);child.queue_free()
	var item:Dictionary={}
	if not selected_id.is_empty():item=api("artifact",[selected_id],{})
	if item.is_empty():
		var hint:=serif(detail_body,"Choose a piece to read its catalogue plate.",17,T.TEXT_SOFT,true);hint.custom_minimum_size.y=120;hint.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		return
	var tier_index:=int(item.get("rarity_index",0));var tier:=tier_color(tier_index)
	var plate:=PanelContainer.new();plate.name="CataloguePlate";plate.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style:=T.flat(plate_color(),T.BORDER,1,6);style.content_margin_left=20;style.content_margin_right=20;style.content_margin_top=16;style.content_margin_bottom=18;plate.add_theme_stylebox_override("panel",style);detail_body.add_child(plate)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",11);plate.add_child(column)
	var eyebrow:=HBoxContainer.new();eyebrow.add_theme_constant_override("separation",8);column.add_child(eyebrow)
	pips(eyebrow,tier_index,tier)
	var origin:=String(item.get("origin",""))
	label(eyebrow,(tier_name(item)+(" · "+origin if not origin.is_empty() else "")).to_upper(),11,tier,true,.08)
	serif(column,String(item.get("name","An unnamed piece")),25)
	var frame:=ArtFrame.new();frame.name="PlateArt";frame.item=item;frame.tier=tier;frame.custom_minimum_size.y=330;column.add_child(frame)
	var caption:=serif(column,"%s · in our custody %s" % [_found_text(item),custody_text(int(item.get("held_days",0)))],12,T.TEXT_SOFT,true);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_study_state(column,item)
	_value_pills(column,item)
	_story(column,item)
	column.add_child(Flourish.new())
	_facts(column,item)
	_study_team(column,item)
	_actions(column,item)

func _found_text(item:Dictionary)->String:
	var day:=int(item.get("found_day",0))
	return "Found in year %d, day %d" % [day/360+1,day%360+1]

func _study_state(parent:Node,item:Dictionary)->void:
	var state:=String(item.get("state","unstudied"));var progress:=clampf(float(item.get("study_progress",0)),0,1)
	var row:=VBoxContainer.new();row.add_theme_constant_override("separation",5);parent.add_child(row)
	if state=="studied":
		label(row,"◆  Studied — its makers, use and meaning are understood.",13,T.TEAL)
		return
	label(row,("Being studied · %d%%" if state=="in_study" else "Unstudied · %d%% understood") % roundi(progress*100),13,T.TEAL if state=="in_study" else T.TEXT_SOFT)
	var bar:=ProgressBar.new();bar.name="StudyProgress";bar.show_percentage=false;bar.custom_minimum_size.y=6;bar.value=progress*100
	bar.add_theme_stylebox_override("background",T.flat(T.TRACK,Color(0,0,0,0),0,3));bar.add_theme_stylebox_override("fill",T.flat(T.TEAL,Color(0,0,0,0),0,3));row.add_child(bar)
	label(row,"Its value is veiled until study is complete. Unstudied pieces lend only a little raw prestige.",12,T.MUTED)

func _value_pills(parent:Node,item:Dictionary)->void:
	var studied:=String(item.get("state",""))=="studied"
	var values:Dictionary=item.get("value",{})
	var row:=HBoxContainer.new();row.name="ValuePills";row.add_theme_constant_override("separation",8);parent.add_child(row)
	var subject:=String(item.get("research_subject","")).replace("_"," ")
	var specs:=[["culture","CULTURE","culture",T.VIOLET,"Cultural capacity and cohesion from understanding this piece."],["research","RESEARCH","knowledge",T.BLUE,"Support for linked research"+(": "+subject.capitalize() if not subject.is_empty() else "")+"."],["economic","ECONOMIC","wealth",T.AMBER,"Museum admissions and appraisal-backed trade value."]]
	for spec:Array in specs:
		var pill:=PanelContainer.new();pill.name="Value_"+String(spec[0]);pill.size_flags_horizontal=Control.SIZE_EXPAND_FILL;pill.tooltip_text=String(spec[4])
		var pill_style:=T.flat(T.GOLD_WASH if studied else Color(0,0,0,0),(spec[3] as Color) if studied else T.BORDER_SOFT,1,18);pill_style.content_margin_left=8;pill_style.content_margin_right=12;pill_style.content_margin_top=5;pill_style.content_margin_bottom=5;pill.add_theme_stylebox_override("panel",pill_style);row.add_child(pill)
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",7);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;pill.add_child(line)
		var icon:=TextureRect.new();icon.texture=Icons.domain_texture(String(spec[2]),spec[3] if studied else T.DISABLED);icon.custom_minimum_size=Vector2(28,28);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(icon)
		var words:=VBoxContainer.new();words.add_theme_constant_override("separation",-2);line.add_child(words)
		label(words,String(spec[1]),9,T.MUTED,false,.1)
		var amount:=float(values.get(String(spec[0]),0))
		var value_label:=serif(words,("+" if spec[0]!="economic" else "")+number(amount) if studied else "Veiled",17,T.INK if studied else T.DISABLED)
		value_label.autowrap_mode=TextServer.AUTOWRAP_OFF

func _story(parent:Node,item:Dictionary)->void:
	var story:=String(item.get("story","")).strip_edges()
	if story.is_empty():return
	var text:=RichTextLabel.new();text.name="Story";text.bbcode_enabled=true;text.fit_content=true;text.scroll_active=false;text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.mouse_filter=Control.MOUSE_FILTER_PASS
	text.add_theme_font_override("normal_font",italic_font());text.add_theme_font_size_override("normal_font_size",15);text.add_theme_color_override("default_color",T.BODY);text.add_theme_constant_override("line_separation",3)
	var gold:=(T.GOLD_BRIGHT if T.is_light() else Color("e8c86e")).to_html(false)
	var initial:=FontVariation.new();initial.base_font=DISPLAY_FONT;initial.variation_embolden=.9
	var ink:=Color(gold)
	text.push_dropcap(story.substr(0,1).to_upper(),initial,44,Rect2(0,4,4,0),ink,1,ink.darkened(.2))
	text.add_text(story.substr(1))
	parent.add_child(text)

func _facts(parent:Node,item:Dictionary)->void:
	var facts:=GridContainer.new();facts.name="Facts";facts.columns=2;facts.add_theme_constant_override("h_separation",16);facts.add_theme_constant_override("v_separation",7);parent.add_child(facts)
	var rows:Array=[["Object",item.get("object","")],["Style",item.get("style","")],["Motif",item.get("motif","")],["Material",item.get("material","")],["Provenance",item.get("origin","")],["Site",item.get("site_name","")],["Set",(String(item.get("set_name",""))+("  ·  "+String(item.get("set_progress","")) if not String(item.get("set_progress","")).is_empty() else "")) if not String(item.get("set_name","")).is_empty() else ""],["In custody",custody_text(int(item.get("held_days",0)))],["Prestige","%.1f" % float(item.get("prestige",0))],["Appraisal",number(float(item.get("appraisal",0)))],["Informs",String(item.get("research_subject","")).replace("_"," ").capitalize()]]
	for pair:Array in rows:
		var value:=String(pair[1]).strip_edges()
		if value.is_empty():continue
		var key:=label(facts,String(pair[0]).to_upper(),10,T.GOLD,false,.1);key.custom_minimum_size.x=96;key.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
		label(facts,cap(value),13,T.BODY)

func _study_team(parent:Node,item:Dictionary)->void:
	var role:Dictionary=summary_data.get("study_role",{})
	var box:=PanelContainer.new();box.name="StudyTeam";box.add_theme_stylebox_override("panel",T.brief_style("info"));parent.add_child(box)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",5);box.add_child(column)
	label(column,"STUDY TEAM · RESEARCH ALLOCATION",10,T.TEAL,false,.1)
	var workers:=int(role.get("workers",0))
	var rate:=String(role.get("rate_text",""))
	label(column,rate if not rate.is_empty() else "%d researcher%s assigned to artifact study." % [workers,"" if workers==1 else "s"],13,T.BODY)
	if has_api("change_study_weight"):
		var weight_row:=HBoxContainer.new();weight_row.name="StudyWeight";weight_row.add_theme_constant_override("separation",8);column.add_child(weight_row)
		label(weight_row,"Share of research attention · weight %d" % int(role.get("weight",0)),12,T.TEXT_SOFT,false).size_flags_vertical=Control.SIZE_SHRINK_CENTER
		var less:=action_button(weight_row,"−",func()->void:_act(api("change_study_weight",[-1],{}),""),false,"Less artifact study; attention returns to other research");less.name="StudyWeightLess";less.custom_minimum_size.x=34;less.disabled=int(role.get("weight",0))<=0
		var more:=action_button(weight_row,"+",func()->void:_act(api("change_study_weight",[1],{}),""),false,"More artifact study, drawn from the same research budget");more.name="StudyWeightMore";more.custom_minimum_size.x=34
	var focus:=String(role.get("focus_id",""))
	if focus==String(item.get("id","")) and not focus.is_empty():label(column,"This piece is the study focus; the team works on it first.",12,T.TEAL)
	elif workers<=0:label(column,"No one studies artifacts yet. Give artifact study weight in the research allocation.",12,T.GOLD)
	var link:=action_button(column,"Adjust in the research allocation  ›",_open_inquiry,false,"Opens Inquiry › Direct attention, where artifact study shares the research budget");link.name="OpenResearchAllocation";link.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN

func _actions(parent:Node,item:Dictionary)->void:
	var id:=String(item.get("id",""));var studied:=String(item.get("state",""))=="studied"
	var focus:=String(summary_data.get("study_role",{}).get("focus_id",""))==id
	var row:=HFlowContainer.new();row.name="PlateActions";row.add_theme_constant_override("h_separation",10);row.add_theme_constant_override("v_separation",8);parent.add_child(row)
	var study:=action_button(row,"Current study focus" if focus else "Make this the study focus",func()->void:_act(api("set_study_focus",[id],{"error":"Study focus is unavailable."}),"This piece is now the study focus."),true,"Researchers on artifact study will work on this piece first.")
	study.name="StudyFocusButton";study.disabled=studied or focus
	if studied:study.tooltip_text="Already studied."
	var exhibited:=bool(item.get("exhibited",false))
	var show:=action_button(row,"Return to the storeroom" if exhibited else "Put on exhibit",func()->void:_act(api("set_exhibited",[id,not exhibited],{"error":"Exhibition is unavailable."}),"Returned to the storeroom." if exhibited else "Now on exhibit."),not exhibited,"Exhibited studied pieces raise allure and draw paying visitors.")
	show.name="ExhibitButton";show.disabled=not exhibited and not bool(item.get("can_exhibit",false))
	if show.disabled:show.tooltip_text="A museum needs Public Libraries and Comparative Chronicles, and the piece must be in our hands."
	var exchange:=action_button(row,"Gift, sell or trade…",_open_exchange.bind(String(item.get("name",""))),false,"Offer this piece to a contacted civilization in Brought Home")
	exchange.name="ExchangeButton"
	if not message.is_empty():
		var note:=label(parent,message,12,T.RED if message.begins_with("!") else T.TEAL);note.name="ActionMessage";note.text=message.trim_prefix("!")

func _act(result:Variant,success:String)->void:
	var outcome:Dictionary=result if result is Dictionary else {}
	message="!"+String(outcome.error) if outcome.has("error") else (success+(" " if not success.is_empty() else "")+String(outcome.get("note",""))).strip_edges()
	refresh(true)

func _open_inquiry()->void:
	var target_hud:=hud;var target_terrain:=terrain
	close()
	if is_instance_valid(target_hud) and target_hud.has_method("open_dock"):target_hud.open_dock("inquiry",0)
	elif is_instance_valid(target_terrain) and target_terrain.has_method("_on_hud_section_requested"):target_terrain._on_hud_section_requested("inquiry",0)

func _open_exchange(artifact_name:String)->void:
	preload("res://scripts/hud/exchange_collection_panel.gd").open()
	var canvas:Variant=CivilizationSystem.get_meta("exchange_collection_panel",null)
	if is_instance_valid(canvas) and canvas.get_child_count()>0:
		var sheet=canvas.get_child(0)
		if sheet.search:sheet.search.text=artifact_name;sheet.page=0;sheet.refresh(true)

# ---------------------------------------------------------------- layout

func _layout()->void:
	if panel==null:return
	var area:=get_viewport_rect().size
	var margin:=24.0 if area.x>=900 else 8.0
	panel.position=Vector2(margin,margin);panel.size=Vector2(maxf(320,area.x-margin*2),maxf(320,area.y-margin*2))
	narrow=area.x<1180
	effects_column.visible=area.x>=1000
	browse.visible=not narrow or not narrow_detail
	detail_column.visible=not narrow or narrow_detail
	detail_back.visible=narrow
	detail_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_FILL
	detail_column.custom_minimum_size.x=0.0 if narrow else clampf(area.x*.3,430,560)
	_fit_columns()

# ================================================================ drawing

class RarityPips extends Control:
	var index:=0
	var color:=Color.WHITE
	func _init()->void:custom_minimum_size=Vector2(52,12);mouse_filter=Control.MOUSE_FILTER_IGNORE;size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func _draw()->void:
		for i in 5:
			var c:=Vector2(5+i*10.5,size.y*.5)
			var points:=PackedVector2Array([c+Vector2(0,-4.2),c+Vector2(4.2,0),c+Vector2(0,4.2),c+Vector2(-4.2,0)])
			if i<=index:draw_colored_polygon(points,color)
			else:
				points.append(points[0]);draw_polyline(points,Color(color,.45),1.0,true)

class Seal extends Control:
	var value:=0.0
	func _init()->void:custom_minimum_size=Vector2(132,132);mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var c:=size*.5;var r:=minf(size.x,size.y)*.5-2.0
		var metal:=T.GOLD;var rim:=metal.darkened(.18) if T.is_light() else metal.darkened(.35)
		var face:=Color("f8f1e3") if T.is_light() else Color("111a1d")
		var bumps:=36
		for i in bumps:
			var a:=TAU*i/bumps
			draw_circle(c+Vector2(cos(a),sin(a))*(r-r*.06),r*.07,rim)
		draw_circle(c,r-r*.06,rim)
		draw_circle(c,r-r*.1,metal)
		draw_circle(c,r-r*.16,face)
		draw_arc(c,r-r*.19,0,TAU,72,Color(metal,.55),1.0,true)
		var start:=deg_to_rad(135.0);var sweep:=deg_to_rad(270.0);var ring:=r*.64;var width:=maxf(4.0,r*.085)
		for i in 21:
			var a:=start+sweep*i/20.0;var d:=Vector2(cos(a),sin(a))
			var major:=i%5==0
			draw_line(c+d*(ring+width*.5+2),c+d*(ring+width*.5+(r*.1 if major else r*.05)),Color(T.INK,.55 if major else .3),1.2 if major else 1.0,true)
		draw_arc(c,ring,start,start+sweep,96,T.TRACK,width,true)
		var amount:=clampf(value,0,1)
		if amount>0.002:
			draw_arc(c,ring,start,start+sweep*amount,96,T.GOLD_BRIGHT if T.is_light() else T.GOLD,width,true)
			var tip:=start+sweep*amount
			draw_circle(c+Vector2(cos(tip),sin(tip))*ring,width*.72,T.GOLD_BRIGHT if T.is_light() else Color("f0d488"))
		var text:=str(roundi(amount*100));var font_size:=int(r*.5)
		var width_text:=DISPLAY_FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		draw_string(DISPLAY_FONT,c+Vector2(-width_text*.5,font_size*.3),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,T.INK)
		var caption:="ALLURE";var small:=maxi(8,int(r*.14))
		var width_caption:=DISPLAY_FONT.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,small).x
		draw_string(DISPLAY_FONT,c+Vector2(-width_caption*.5,r*.62),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,small,T.GOLD)

class Flourish extends Control:
	func _init()->void:custom_minimum_size.y=16;mouse_filter=Control.MOUSE_FILTER_IGNORE;size_flags_horizontal=Control.SIZE_EXPAND_FILL
	func _draw()->void:
		var y:=size.y*.5;var cx:=size.x*.5;var line:=Color(T.GOLD,.45)
		draw_line(Vector2(0,y),Vector2(cx-22,y),line,1.0)
		draw_line(Vector2(cx+22,y),Vector2(size.x,y),line,1.0)
		for offset:float in [-14.0,14.0]:_diamond(Vector2(cx+offset,y),2.6,T.GOLD)
		_diamond(Vector2(cx,y),5.0,T.GOLD)
	func _diamond(c:Vector2,r:float,color:Color)->void:
		draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r,0),c+Vector2(0,r),c+Vector2(-r,0)]),color)

class Breakdown extends Control:
	var parts:Array=[]
	const COLORS:=["gold","teal","violet","blue","green","amber"]
	static func color_at(index:int)->Color:
		match COLORS[index%COLORS.size()]:
			"gold":return T.GOLD
			"teal":return T.TEAL
			"violet":return T.VIOLET
			"blue":return T.BLUE
			"green":return T.GREEN
		return T.AMBER
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		var rect:=Rect2(Vector2(0,1),Vector2(size.x,size.y-2))
		draw_rect(rect,T.TRACK)
		var x:=0.0
		for index in parts.size():
			var width:=clampf(float(parts[index].get("value",0)),0,1)*size.x
			if width<=0:continue
			draw_rect(Rect2(Vector2(x,1),Vector2(minf(width,size.x-x),size.y-2)),color_at(index))
			x+=width
			if x<size.x:draw_line(Vector2(x,1),Vector2(x,size.y-1),T.DOCK_BG,1.0)

class CardMarks extends Control:
	## Ornaments over the artwork: rarity ribbon, exhibit badge, study ring.
	var item:Dictionary={}
	var tier:=Color.WHITE
	var compact:=false
	var focused:=false
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	func _draw()->void:
		var ink:=Color("2a2620");var paper:=Color("f6efe0")
		if item.get("texture")==null:
			var letter:=String(item.get("object",item.get("name","?"))).substr(0,1).to_upper()
			var font_size:=int(size.y*.42);var measure:=DISPLAY_FONT.get_string_size(letter,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
			draw_string(DISPLAY_FONT,Vector2((size.x-measure.x)*.5,size.y*.5+font_size*.34),letter,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(ink,.18))
		if not compact:draw_rect(Rect2(Vector2(5,5),size-Vector2(10,10)),Color(1,1,1,.55),false,1.0)
		var x:=10.0 if not compact else 5.0;var w:=16.0 if not compact else 10.0
		var h:=(32.0 if not compact else 20.0)+(6.0 if int(item.get("rarity_index",0))>=4 else 0.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x,0),Vector2(x+w,0),Vector2(x+w,h),Vector2(x+w*.5,h-w*.4),Vector2(x,h)]),tier)
		draw_line(Vector2(x+2.5,0),Vector2(x+2.5,h-3),tier.lightened(.4),1.0)
		var font:=ThemeDB.fallback_font
		if bool(item.get("exhibited",false)):
			if compact:
				draw_circle(Vector2(size.x-9,9),5.5,Color("7a5812"));draw_circle(Vector2(size.x-9,9),2.4,paper)
			else:
				var text:="ON EXHIBIT";var fs:=9;var tw:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
				var rect:=Rect2(Vector2(size.x-tw-24,8),Vector2(tw+16,18))
				draw_style_box(T.flat(Color("7a5812"),Color("e9cf8a"),1,9),rect)
				draw_string(font,Vector2(rect.position.x+8,rect.position.y+12.5),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("fbf1d8"))
		if focused and not compact:
			var focus_text:="STUDY FOCUS";var ffs:=9;var fw:=font.get_string_size(focus_text,HORIZONTAL_ALIGNMENT_LEFT,-1,ffs).x
			var focus_rect:=Rect2(Vector2(8,size.y-26),Vector2(fw+16,18))
			draw_style_box(T.flat(Color("2f6b62"),Color("a9d4cc"),1,9),focus_rect)
			draw_string(font,Vector2(focus_rect.position.x+8,focus_rect.position.y+12.5),focus_text,HORIZONTAL_ALIGNMENT_LEFT,-1,ffs,Color("effaf7"))
		var radius:=13.0 if not compact else 8.0
		var center:=size-Vector2(radius+7,radius+7)
		if String(item.get("state",""))=="studied":
			draw_circle(center,radius,Color("9c7418"));draw_arc(center,radius-2.5,0,TAU,32,Color("f2d98f"),1.0,true)
			var s:=radius*.45
			draw_polyline(PackedVector2Array([center+Vector2(-s,0),center+Vector2(-s*.25,s*.7),center+Vector2(s,-s*.6)]),Color("fff6de"),2.0 if not compact else 1.5,true)
		else:
			var progress:=clampf(float(item.get("study_progress",0)),0,1)
			draw_circle(center,radius+3,Color(paper,.94))
			draw_arc(center,radius,0,TAU,40,Color(ink,.18),3.0 if not compact else 2.0,true)
			if progress>0:draw_arc(center,radius,-PI*.5,-PI*.5+TAU*progress,48,Color("2f7a6e"),3.0 if not compact else 2.0,true)
			if not compact:
				var pct:=str(roundi(progress*100));var pfs:=9;var pw:=font.get_string_size(pct,HORIZONTAL_ALIGNMENT_LEFT,-1,pfs).x
				draw_string(font,center+Vector2(-pw*.5,3.5),pct,HORIZONTAL_ALIGNMENT_LEFT,-1,pfs,ink)

class ArtifactCard extends PanelContainer:
	var item:Dictionary={}
	var selected:=false
	var focused:=false
	var hovered:=false
	var on_press:Callable
	func _ready()->void:
		name="Card_"+String(item.get("id","")).validate_node_name()
		custom_minimum_size.x=CARD_MIN_WIDTH;size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		tooltip_text="%s\n%s · %s" % [String(item.get("name","")),TIER_NAMES[clampi(int(item.get("rarity_index",0)),0,4)],Kit.state_text(item)]
		var tier:=Kit.tier_color(int(item.get("rarity_index",0)))
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",5);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(column)
		var art_box:=Control.new();art_box.custom_minimum_size.y=176;art_box.clip_contents=true;art_box.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(art_box)
		var mount:=ColorRect.new();mount.color=Color("ece4d4");mount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mount.mouse_filter=Control.MOUSE_FILTER_IGNORE;art_box.add_child(mount)
		var art:=TextureRect.new();art.name="Art";art.texture=item.get("texture");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		art.material=Kit.veil_material(Kit.veil_for(item),.35);art_box.add_child(art)
		var marks:=CardMarks.new();marks.item=item;marks.tier=tier;marks.focused=focused;art_box.add_child(marks)
		var title:=Kit.serif(column,String(item.get("name","")),14);title.max_lines_visible=2;title.custom_minimum_size.y=40;title.clip_text=true;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var object:=String(item.get("object",""));var material:=String(item.get("material",""))
		var sub:=Kit.label(column," · ".join(PackedStringArray([Kit.cap(material),object]).slice(0 if not material.is_empty() else 1)),11,T.TEXT_SOFT,false);sub.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;sub.clip_text=true;sub.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var site:=String(item.get("site_name",""))
		if not site.is_empty():
			var where:=Kit.label(column,"⌖ "+site,11,T.MUTED,false);where.clip_text=true;where.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;where.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",6);footer.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(footer)
		Kit.pips(footer,int(item.get("rarity_index",0)),tier)
		var tier_label:=Kit.label(footer,TIER_NAMES[clampi(int(item.get("rarity_index",0)),0,4)].to_upper(),9,tier,false,.08);tier_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tier_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var state:=Kit.label(footer,Kit.state_text(item),10,T.TEAL if String(item.get("state",""))!="unstudied" else T.MUTED,false);state.mouse_filter=Control.MOUSE_FILTER_IGNORE
		mouse_entered.connect(func()->void:hovered=true;restyle())
		mouse_exited.connect(func()->void:hovered=false;restyle())
		gui_input.connect(func(event:InputEvent)->void:
			if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and on_press.is_valid():accept_event();on_press.call(String(item.get("id",""))))
		restyle()
	func restyle()->void:
		var tier:=Kit.tier_color(int(item.get("rarity_index",0)))
		var border:=T.GOLD if selected else (tier if hovered else Color(tier,.7))
		var style:=T.flat(Kit.plate_color(),border,2 if selected or hovered else 1,5);style.set_content_margin_all(8)
		if selected:style.shadow_color=Color(T.GOLD,.35);style.shadow_size=6
		add_theme_stylebox_override("panel",style)

class ArtFrame extends Control:
	## The detail plate's mounted artwork with a double rule and corner jewels.
	var item:Dictionary={}
	var tier:=Color.WHITE
	func _ready()->void:
		size_flags_horizontal=Control.SIZE_EXPAND_FILL;clip_contents=false
		var mount:=ColorRect.new();mount.color=Color("ece4d4");mount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mount.offset_left=9;mount.offset_top=9;mount.offset_right=-9;mount.offset_bottom=-9;add_child(mount)
		var art:=TextureRect.new();art.name="PlateTexture";art.texture=item.get("texture");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);art.offset_left=9;art.offset_top=9;art.offset_right=-9;art.offset_bottom=-9;art.material=Kit.veil_material(Kit.veil_for(item),.3);add_child(art)
		var marks:=CardMarks.new();marks.item=item;marks.tier=tier;marks.offset_left=9;marks.offset_top=9;marks.offset_right=-9;marks.offset_bottom=-9;add_child(marks)
	func _draw()->void:
		var outer:=Rect2(Vector2(1,1),size-Vector2(2,2))
		draw_rect(outer,tier,false,1.5)
		draw_rect(outer.grow(-4),Color(T.GOLD,.55),false,1.0)
		for corner:Vector2 in [outer.position,Vector2(outer.end.x,outer.position.y),Vector2(outer.position.x,outer.end.y),outer.end]:
			draw_colored_polygon(PackedVector2Array([corner+Vector2(0,-6),corner+Vector2(6,0),corner+Vector2(0,6),corner+Vector2(-6,0)]),tier)
			draw_colored_polygon(PackedVector2Array([corner+Vector2(0,-2.5),corner+Vector2(2.5,0),corner+Vector2(0,2.5),corner+Vector2(-2.5,0)]),T.GOLD_BRIGHT if T.is_light() else Color("f0d488"))

class Silhouette extends Control:
	## A missing set piece: an empty mount with a dashed outline.
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var rect:=Rect2(Vector2(1,1),size-Vector2(2,2))
		draw_rect(rect,Color(T.TRACK,.35))
		var dash:=6.0;var color:=Color(T.GOLD,.55)
		var edges:=[[rect.position,Vector2(rect.end.x,rect.position.y)],[Vector2(rect.end.x,rect.position.y),rect.end],[rect.end,Vector2(rect.position.x,rect.end.y)],[Vector2(rect.position.x,rect.end.y),rect.position]]
		for edge:Array in edges:
			var a:Vector2=edge[0];var b:Vector2=edge[1];var length:=a.distance_to(b);var t:=0.0
			while t<length:
				draw_line(a.lerp(b,t/length),a.lerp(b,minf(t+dash,length)/length),color,1.0)
				t+=dash*2
		var font_size:=int(size.y*.36);var measure:=DISPLAY_FONT.get_string_size("?",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
		draw_string(DISPLAY_FONT,Vector2((size.x-measure.x)*.5,size.y*.5+font_size*.34),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(T.GOLD,.5))

class RumorNote extends PanelContainer:
	## A parchment slip: the hint, how much to trust it, and whether it was found.
	var rumor:Dictionary={}
	func _ready()->void:
		name="Rumor_"+String(rumor.get("id","")).validate_node_name()
		var found:=bool(rumor.get("found",false))
		var paper:=Color("efe3c8") if T.is_light() else Color("1c2322")
		var style:=T.flat(paper,Color(T.GOLD,.5),1,3);style.content_margin_left=18;style.content_margin_right=16;style.content_margin_top=14;style.content_margin_bottom=14
		style.shadow_color=Color(0,0,0,.18);style.shadow_size=4;style.shadow_offset=Vector2(2,3)
		add_theme_stylebox_override("panel",style)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);add_child(column)
		var top:=HBoxContainer.new();column.add_child(top)
		var name_label:=RichTextLabel.new();name_label.bbcode_enabled=true;name_label.fit_content=true;name_label.scroll_active=false;name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_override("normal_font",Kit.serif_font());name_label.add_theme_font_size_override("normal_font_size",18);name_label.add_theme_color_override("default_color",T.MUTED if found else T.INK)
		name_label.text=("[s]%s[/s]" if found else "%s") % String(rumor.get("name","An unnamed place")).replace("[","(").replace("]",")");top.add_child(name_label)
		if found:
			var stamp:=Kit.label(top,"FOUND",10,T.TEAL,false,.14);stamp.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
		var hint:=Kit.serif(column,"“%s”" % String(rumor.get("hint","")),14,T.TEXT_SOFT if found else T.BODY,true)
		hint.add_theme_constant_override("line_spacing",2)
		var confidence:=clampf(float(rumor.get("confidence",0)),0,1)
		var meter:=HBoxContainer.new();meter.add_theme_constant_override("separation",8);column.add_child(meter)
		Kit.label(meter,Kit.confidence_word(confidence),11,T.GOLD,false)
		var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size=Vector2(80,4);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.value=confidence*100
		bar.add_theme_stylebox_override("background",T.flat(T.TRACK,Color(0,0,0,0),0,2));bar.add_theme_stylebox_override("fill",T.flat(T.GOLD,Color(0,0,0,0),0,2));meter.add_child(bar)
		var day:=int(rumor.get("known_since_day",-1))
		if day>=0:Kit.label(column,"Heard in year %d, day %d" % [day/360+1,day%360+1],11,T.MUTED,false)
