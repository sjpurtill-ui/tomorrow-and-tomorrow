extends CanvasLayer
## A bounded, non-modal card for returned expeditions. The permanent report owns
## the full account; this card only identifies the return and opens that report.
const Archive:=preload("res://scripts/scout_archive.gd")
const ArtifactArt:=preload("res://scripts/hud/artifact_visuals.gd")
const ScoutArt:=preload("res://scripts/hud/scouting_window_art.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const UI_FONT:=preload("res://assets/fonts/battle/Barlow-Medium.ttf")
const DISPLAY_FONT:=preload("res://assets/fonts/cinzel/Cinzel.ttf")
const CARD_MAX_WIDTH:=460.0
const EDGE:=16.0
# Research digests occupy the lower card lane; expedition returns use the lane
# above it so simultaneous notices remain independently readable and clickable.
const LOWER_UI_CLEARANCE:=204.0

var terrain:Node
var hud:Control
var reports:Array[Dictionary]=[]
var notice:PanelContainer
var thumbnail:TextureRect
var eyebrow:Label
var title:Label
var detail:Label
var date_label:Label
var open_button:Button

static func announce(terrain_node:Node,hud_node:Control,report:Dictionary)->CanvasLayer:
	if not is_instance_valid(hud_node):return null
	var digest:Variant=hud_node.get_meta("scout_return_digest") if hud_node.has_meta("scout_return_digest") else null
	if not is_instance_valid(digest):
		digest=new();digest.terrain=terrain_node;digest.hud=hud_node
		hud_node.set_meta("scout_return_digest",digest);hud_node.add_child(digest)
	digest.receive(report)
	return digest

func _ready()->void:
	layer=71
	notice=PanelContainer.new()
	notice.add_theme_stylebox_override("panel",T.flat(Color("0b1519f7"),T.GOLD,1,7,12))
	add_child(notice)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);notice.add_child(row)
	thumbnail=TextureRect.new();thumbnail.custom_minimum_size=Vector2(82,82);thumbnail.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	thumbnail.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;thumbnail.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(thumbnail)
	var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",2);row.add_child(copy)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);copy.add_child(top)
	eyebrow=_label(top,"EXPEDITION RETURNED",10,T.GOLD);eyebrow.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	date_label=_label(top,"",10,T.MUTED)
	title=_label(copy,"",18,T.INK,true);title.add_theme_font_override("font",DISPLAY_FONT);title.max_lines_visible=2
	detail=_label(copy,"",12,T.TEXT_SOFT,true);detail.max_lines_visible=2;detail.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",6);copy.add_child(actions)
	open_button=_button(actions,"Open illustrated report  →",open_latest,true);open_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var dismiss:=_button(actions,"×",clear);dismiss.custom_minimum_size.x=34;dismiss.tooltip_text="Leave reports unread in the Expedition Archive"
	get_viewport().size_changed.connect(layout);layout();notice.hide()

func _label(parent:Node,text_value:String,size_value:int,color:Color,wrap:=false)->Label:
	var value:=Label.new();value.text=text_value;value.add_theme_font_override("font",UI_FONT)
	value.add_theme_font_size_override("font_size",size_value);value.add_theme_color_override("font_color",color)
	value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	parent.add_child(value);return value

func _button(parent:Node,text_value:String,callback:Callable,primary:=false)->Button:
	var value:=Button.new();value.text=text_value;value.clip_text=true;value.custom_minimum_size.y=30
	value.add_theme_font_override("font",UI_FONT);value.add_theme_font_size_override("font_size",12)
	value.add_theme_stylebox_override("normal",T.action_button_style(primary));value.add_theme_stylebox_override("hover",T.action_button_style(true,true))
	value.pressed.connect(callback);parent.add_child(value);return value

func layout()->void:
	if not is_instance_valid(notice):return
	var extent:=get_viewport().get_visible_rect().size
	var width:=maxf(260.0,minf(CARD_MAX_WIDTH,extent.x-EDGE*2.0))
	notice.custom_minimum_size.x=width;notice.size.x=width
	var height:=notice.get_combined_minimum_size().y
	notice.size.y=height
	notice.position=Vector2(maxf(EDGE,extent.x-width-EDGE),maxf(EDGE,extent.y-height-LOWER_UI_CLEARANCE))

func receive(report:Dictionary)->void:
	reports.append(report.duplicate(true))
	if reports.size()>8:reports.pop_front()
	refresh()

func refresh()->void:
	if reports.is_empty():notice.hide();return
	var report:=reports[-1]
	var summary:Dictionary=Archive.summary(report)
	eyebrow.text=("CITY RECONNAISSANCE" if String(report.get("mission_kind",""))=="observe_city" else "EXPEDITION RETURNED")+("  ·  %d UNREAD" % reports.size() if reports.size()>1 else "")
	title.text=String(summary.title)
	detail.text=String(summary.detail)
	var day:=int(summary.day)
	date_label.text="Y%d · D%d" % [day/365+1,day%365+1]
	var artifact:=_artifact_item(report)
	thumbnail.texture=_preview_texture(report,artifact)
	thumbnail.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if not artifact.is_empty() else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	open_button.tooltip_text=String(summary.detail)+" Open the full illustrated report."
	notice.show();call_deferred("layout")

func _artifact_item(report:Dictionary)->Dictionary:
	for finding:Dictionary in report.get("discoveries",[]):
		if finding.get("kind","")!="artifact":continue
		var collection_id:=String(finding.get("collection_id",""))
		if collection_id.is_empty() or WorldSimulation.state==null:continue
		var item:Variant=WorldSimulation.state.society_exchange.get("collections",{}).get(collection_id,{})
		if item is Dictionary:return item
	return {}

func _preview_texture(report:Dictionary,artifact:Dictionary)->Texture2D:
	var exact:=ArtifactArt.texture(artifact) if not artifact.is_empty() else null
	if exact!=null:return exact
	var findings:Array=report.get("discoveries",[])
	var kind:=String(findings[0].get("kind","exploration")) if not findings.is_empty() else "exploration"
	return ScoutArt.icon("recruitment" if not report.get("recruitment_account",{}).is_empty() else "find" if kind in ["artifact","specimen"] else "exploration")

func open_latest()->void:
	if reports.is_empty():return
	var report:Dictionary=reports.pop_back()
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_scout_report.gd").new(terrain,hud,report,preload("res://scripts/hud/content/dock_detail_scout_archive.gd").new(terrain,hud)))
	refresh()

func clear()->void:
	reports.clear();notice.hide()
