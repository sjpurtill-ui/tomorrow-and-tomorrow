extends Control
## The Audience Hall: a theatrical, pausing modal in which envoys and
## petitioners speak, the court chimes in, and the ruler answers.
## World state changes only through AudienceHall (engine); this file only
## presents lines, collects speech and routes the chosen option.

signal closed(audience_id:String)

const Hall:=preload("res://scripts/audience_hall.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const EarlyArt:=preload("res://scripts/hud/early_civ_art.gd")
const Works:=preload("res://scripts/great_works_audience.gd")
const WorkPlate:=preload("res://scripts/hud/great_work_plate.gd")
const WORK_KINDS:=["great_work","wonder_proposal"]
const AMBITION_TIPS:={"modest":"A modest work: cheaper, surer, pays little.","grand":"A grand work: promise and risk in balance.","audacious":"An audacious work: pays greatly, fails often."}

const DESIGN_SIZE:=Vector2(1280,820)
const KINDS:={
	"gift":{"herald":"A GIFT FROM %s","eyebrow":"AN ENVOY BEARS GIFTS"},
	"request":{"herald":"A PLEA FROM %s","eyebrow":"AN ENVOY ASKS YOUR AID"},
	"threat":{"herald":"AN ULTIMATUM FROM %s","eyebrow":"AN ENVOY DEMANDS TRIBUTE"},
	"news":{"herald":"NEWS FROM %s","eyebrow":"AN ENVOY BRINGS WORD"},
	"proposal":{"herald":"A PROPOSAL FROM %s","eyebrow":"AN ENVOY BRINGS AN OFFER"},
	"petition":{"herald":"%s REQUESTS AN AUDIENCE","eyebrow":"A PETITION FROM YOUR COURT"},
	"report":{"herald":"%s RETURNS FROM THE FIELD","eyebrow":"A REPORT FROM BEYOND THE BORDERS"},
	"great_work":{"herald":"%s SEEKS YOUR JUDGMENT","eyebrow":"A GREAT WORK"},
	"wonder_proposal":{"herald":"%s WOULD RAISE A WONDER","eyebrow":"A GREAT WORK IS PROPOSED"},
	"summons":{"herald":"%s ANSWERS YOUR SUMMONS","eyebrow":"YOU SENT FOR THEM"},
}
const REACTION_WORDS:={"delighted":"DELIGHTED","pleased":"PLEASED","neutral":"UNMOVED","offended":"OFFENDED","furious":"FURIOUS"}

var terrain:Node
var voice:Node
var audience_id:=""
var pause=preload("res://scripts/hud/simulation_pause.gd").new()

var card:PanelContainer
var body:VBoxContainer
var transcript_scroll:ScrollContainer
var transcript:VBoxContainer
var thinking:Label
var speech_input:LineEdit
var speak_button:Button
var options_row:HBoxContainer
var outcome_box:VBoxContainer
var wait_button:Button
var summon_check:CheckBox
var queue_label:Label
var voice_label:Label
var frequency_pick:OptionButton
var next_button:Button
var mood_meter:Control
var mood_label:Label
var speaker_frame:PanelContainer
var bench_cards:Dictionary={}      # person_id -> PanelContainer
var envoy_color:=Color.WHITE
var speaker_person_id:=0
var accent:=Color.WHITE
var rendered_lines:=0
var revealing:=false
var reveal_tweens:Array[Tween]=[]
var follow_scroll:=0.0
var resolved_result:Dictionary={}
var clock:=0.0
var _italic:FontVariation
var _bold:FontVariation
var proposal_box:VBoxContainer
var weigh_clock:=-1.0
var conceive_next:=false

func _ready()->void:
	name="AudienceModal"
	set_meta("responsive_scroll_layout",true)
	mouse_filter=Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=Tokens.control_theme()
	var host:Node=terrain if is_instance_valid(terrain) else get_tree().current_scene
	pause.acquire(host)
	_italic=FontVariation.new();_italic.base_font=ThemeDB.fallback_font;_italic.variation_transform=Transform2D(Vector2(1,0),Vector2(.2,1),Vector2.ZERO)
	_bold=FontVariation.new();_bold.base_font=ThemeDB.fallback_font;_bold.variation_embolden=.7
	var backdrop:=ColorRect.new();backdrop.name="Backdrop"
	backdrop.color=Color(.02,.03,.04,.80) if not Tokens.is_light() else Color(.08,.07,.05,.66)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	card=PanelContainer.new();card.name="AudienceCard";add_child(card)
	get_viewport().size_changed.connect(_fit)
	if not audience_id.is_empty():show_audience(audience_id)

func _exit_tree()->void:
	pause.release()

func _fit()->void:
	if not is_instance_valid(card):return
	var view:=get_viewport().get_visible_rect().size
	var target:=Vector2(minf(DESIGN_SIZE.x,view.x-40),minf(DESIGN_SIZE.y,view.y-40))
	# Autowrapped labels report inflated heights before their first sort and a
	# container never shrinks by itself; re-assert the stage size every frame.
	if card.size!=target:card.size=target
	var place:=((view-card.size)*.5).round()
	if card.position!=place:card.position=place

# --- Building ---------------------------------------------------------------

func show_audience(id:String)->void:
	audience_id=id
	for tween in reveal_tweens:if tween and tween.is_valid():tween.kill()
	reveal_tweens.clear();revealing=false;rendered_lines=0;resolved_result={};bench_cards.clear()
	for child in card.get_children():card.remove_child(child);child.queue_free()
	var audience:=Hall.find(id)
	if audience.is_empty():_close();return
	var kind:=String(audience.get("kind","news"))
	accent=_kind_color(kind)
	speaker_person_id=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	envoy_color=_ink(Identity.banner_color(Identity.foreign(String(audience.get("civ_id",""))).texture)) if String(audience.get("origin",""))=="foreign" else _ink(Tokens.VIOLET)
	var style:=Tokens.flat(Tokens.PANEL_BG_SOLID,accent.darkened(.1),2,10,0)
	style.shadow_color=Color(0,0,0,.45);style.shadow_size=28
	card.add_theme_stylebox_override("panel",style)
	body=VBoxContainer.new();body.add_theme_constant_override("separation",0);card.add_child(body)
	body.add_child(_build_herald(audience))
	var inner:=MarginContainer.new();inner.size_flags_vertical=Control.SIZE_EXPAND_FILL
	for side in ["left","right"]:inner.add_theme_constant_override("margin_"+side,20)
	inner.add_theme_constant_override("margin_top",14);inner.add_theme_constant_override("margin_bottom",12)
	body.add_child(inner)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);inner.add_child(column)
	column.add_child(_build_stage(audience))
	proposal_box=null
	conceive_next=false
	if kind=="wonder_proposal" and String(audience.get("status",""))=="waiting":
		proposal_box=VBoxContainer.new();proposal_box.name="Proposal";proposal_box.add_theme_constant_override("separation",8)
		column.add_child(proposal_box)
		_build_proposal()
	column.add_child(_build_speech_row())
	options_row=HBoxContainer.new();options_row.name="Options";options_row.add_theme_constant_override("separation",10);column.add_child(options_row)
	outcome_box=VBoxContainer.new();outcome_box.name="Outcome";outcome_box.add_theme_constant_override("separation",8);outcome_box.visible=false;column.add_child(outcome_box)
	body.add_child(_build_footer())
	_fit()
	if String(audience.get("status",""))=="resolved":
		_show_outcome({"ok":true,"outcome":String(audience.get("outcome","")),"reaction":"neutral"})
	else:
		_build_options()
	if (audience.get("lines",[]) as Array).is_empty() and _voice_ok() and not voice.busy(id):
		voice.open_scene(id)
	_connect_voice()
	_refresh_footer()

func _build_herald(audience:Dictionary)->Control:
	var kind:=String(audience.get("kind","news"))
	var origin:=String(audience.get("origin","foreign"))
	var speaker:Dictionary=audience.get("speaker",{})
	var banner:=PanelContainer.new();banner.name="Herald"
	var banner_style:=Tokens.flat(accent.darkened(.35) if Tokens.is_light() else accent.darkened(.62),Color(0,0,0,0),0,0,0)
	banner_style.corner_radius_top_left=9;banner_style.corner_radius_top_right=9
	banner_style.border_color=accent.lightened(.25);banner_style.border_width_bottom=3
	banner_style.content_margin_left=20;banner_style.content_margin_right=20;banner_style.content_margin_top=14;banner_style.content_margin_bottom=14
	banner.add_theme_stylebox_override("panel",banner_style)
	var layers:=VBoxContainer.new();layers.add_theme_constant_override("separation",10);banner.add_child(layers)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);layers.add_child(row)
	var seal:=Seal.new();seal.kind=kind;seal.tint=accent.lightened(.15);seal.custom_minimum_size=Vector2(58,58);row.add_child(seal)
	if origin=="foreign":
		var flag:=TextureRect.new();flag.name="Flag";flag.texture=Identity.foreign(String(audience.get("civ_id",""))).texture
		flag.custom_minimum_size=Vector2(50,58);flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flag.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(flag)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",1);row.add_child(words)
	var cream:=Color("f6ecd6");var cream_dim:=Color("e2d3b4")
	var work_info:=_work_herald(audience) if kind in WORK_KINDS else {}
	var eyebrow:=Tokens.make_label("THE HERALD ANNOUNCES · "+String(work_info.get("eyebrow",KINDS.get(kind,KINDS.news).eyebrow)),12,cream_dim,.12);words.add_child(eyebrow)
	var subject:=String(audience.get("civ_name","A foreign people")).to_upper()
	if kind in ["petition","summons"]:subject=("%s %s" % [String(speaker.get("title","")),String(speaker.get("name","An official"))]).strip_edges().to_upper()
	var herald_text:=String(KINDS.get(kind,KINDS.news).herald) % subject
	if kind=="report":herald_text=_report_herald(speaker)
	# The hall's own short herald phrase says what this visit is about.
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation",{}) is Dictionary else {}
	var headline:=String(situation.get("headline","")).strip_edges()
	if not headline.is_empty() and kind!="report" and not kind in WORK_KINDS:
		herald_text=("%s %s" % [subject,headline]).to_upper()
	if kind in WORK_KINDS:herald_text=String(work_info.get("herald",herald_text))
	var title:=Tokens.make_label(herald_text,30,cream);title.name="HeraldTitle"
	title.add_theme_font_override("font",_bold);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(title)
	var day:=int(GameState.elapsed_days);var arrived:=int(audience.get("arrived_day",day))
	var waited:=day-arrived
	var byline:="%s, %s" % [String(speaker.get("name","An envoy")),String(speaker.get("title","envoy"))] if origin=="foreign" else String((audience.get("petition",{}) as Dictionary).get("summary",""))
	var report:Dictionary=audience.get("report",{}) if audience.get("report") is Dictionary else {}
	if kind=="report":
		byline="%s, %s" % [String(speaker.get("name","Your scout")),String(speaker.get("title","scout"))]
		var observed:=int(report.get("observed_day",-1))
		if observed>=0:byline+="  ·  seen day %d" % observed
	if kind in WORK_KINDS:byline=String(work_info.get("byline",byline))
	var timing:="arrived today" if waited<=0 else "has waited %d day%s" % [waited,"" if waited==1 else "s"]
	var expires:=int(audience.get("expires_day",0))
	if expires>0 and String(audience.get("status",""))=="waiting":timing+=" · will leave after day %d" % expires
	var sub:=Tokens.make_label(byline+"  ·  "+timing,14,cream_dim);sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(sub)
	var terms:Dictionary=audience.get("terms",{})
	if kind in WORK_KINDS:
		if work_info.has("plate"):
			var art:=PanelContainer.new();art.name="WorkArt";art.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			art.add_theme_stylebox_override("panel",Tokens.flat(Color("f6ecd6"),accent.lightened(.2),2,6,2))
			var picture:=WorkPlate.make(work_info.plate,58);picture.custom_minimum_size=Vector2(88,58);art.add_child(picture)
			row.add_child(art)
		if work_info.has("chip"):
			var chip:=_chip_box(null,String(work_info.chip[0]),String(work_info.chip[1]));chip.name="WorkChip";row.add_child(chip)
	elif not terms.is_empty() and float(terms.get("amount",0))>0:
		row.add_child(_terms_chip(kind,terms))
	elif kind=="news":
		var news:Dictionary=audience.get("news",{})
		if not String(news.get("subject_civ_name","")).is_empty():
			row.add_child(_chip_box(null,"CONCERNING",String(news.subject_civ_name)))
	elif kind=="petition":
		var topic:=String((audience.get("petition",{}) as Dictionary).get("topic",""))
		if not topic.is_empty():row.add_child(_chip_box(null,"MATTER",topic.capitalize()))
	elif kind=="report":
		var subject_id:=String(report.get("subject_civ_id",""))
		var subject_name:=String(report.get("subject_name",""))
		if not subject_name.is_empty() or not subject_id.is_empty():
			row.add_child(_chip_box(Identity.foreign(subject_id).texture if not subject_id.is_empty() else null,"SCOUTED",subject_name if not subject_name.is_empty() else "Unknown lands"))
		var findings:=_report_findings(report)
		if not findings.is_empty():
			var strip:=HFlowContainer.new();strip.name="Findings";strip.add_theme_constant_override("h_separation",8);strip.add_theme_constant_override("v_separation",6)
			var lead:=Tokens.make_label("FINDINGS",11,cream_dim,.14);lead.size_flags_vertical=Control.SIZE_SHRINK_CENTER;strip.add_child(lead)
			for finding in findings:strip.add_child(_finding_pill(finding))
			layers.add_child(strip)
	return banner

func _report_herald(speaker:Dictionary)->String:
	var person_id:=int(speaker.get("person_id",0))
	var chief:Dictionary=GovernmentPeopleSystem.officeholder("ChiefScout") if GovernmentPeopleSystem.has_method("officeholder") else {}
	if person_id>0 and int(chief.get("person_id",-1))==person_id:
		var title:=String(speaker.get("title","Chief Scout")).strip_edges()
		return "YOUR %s RETURNS WITH A REPORT" % (title if not title.is_empty() else "Chief Scout").to_upper()
	return "%s RETURNS FROM THE FIELD" % String(speaker.get("name","YOUR SCOUT")).to_upper()

static func _report_findings(report:Dictionary)->Array[String]:
	## Facts may be plain strings or records; show short labels only.
	var result:Array[String]=[]
	for fact in report.get("facts",[]):
		var text:=""
		if fact is Dictionary:
			for key in ["chip","short","label","title","text","fact"]:
				if not String(fact.get(key,"")).is_empty():text=String(fact[key]);break
		else:text=String(fact)
		text=text.strip_edges()
		if text.is_empty():continue
		if text.length()>34:text=text.substr(0,32).strip_edges()+"…"
		result.append(text)
		if result.size()>=8:break
	return result

func _finding_pill(text:String)->Control:
	var pill:=PanelContainer.new()
	var pill_style:=Tokens.flat(Color(1,1,1,.14),Color(1,1,1,.35),1,12,0)
	pill_style.content_margin_left=11;pill_style.content_margin_right=11;pill_style.content_margin_top=3;pill_style.content_margin_bottom=4
	pill.add_theme_stylebox_override("panel",pill_style)
	pill.add_child(Tokens.make_label(text,14,Color("f6ecd6")))
	return pill

func _terms_chip(kind:String,terms:Dictionary)->Control:
	var resource:=String(terms.get("resource",""))
	var caption:String={"gift":"THEY OFFER","request":"THEY ASK","threat":"THEY DEMAND"}.get(kind,"TERMS")
	return _chip_box(Icons.domain_texture("nutrition",Color("5f7f35")) if resource=="Food" else Icons.texture_for(resource),caption,"%s %s" % [_amount(float(terms.get("amount",0))),resource])

func _chip_box(icon:Texture2D,caption:String,value:String)->Control:
	var chip:=PanelContainer.new();chip.name="TermsChip";chip.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var chip_style:=Tokens.flat(Color("f6ecd6"),accent.lightened(.2),2,8,0)
	chip_style.content_margin_left=12;chip_style.content_margin_right=16;chip_style.content_margin_top=6;chip_style.content_margin_bottom=6
	chip.add_theme_stylebox_override("panel",chip_style)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);chip.add_child(line)
	if icon:
		var picture:=TextureRect.new();picture.texture=icon;picture.custom_minimum_size=Vector2(40,40);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;line.add_child(picture)
	var text:=VBoxContainer.new();text.add_theme_constant_override("separation",-2);line.add_child(text)
	text.add_child(Tokens.make_label(caption,11,Color("5d4a2a"),.12))
	var value_label:=Tokens.make_label(value,22,Color("2a2217"));value_label.add_theme_font_override("font",_bold);value_label.name="TermsValue";text.add_child(value_label)
	return chip

func _build_stage(audience:Dictionary)->Control:
	var stage:=HBoxContainer.new();stage.name="Stage";stage.size_flags_vertical=Control.SIZE_EXPAND_FILL;stage.add_theme_constant_override("separation",16)
	stage.add_child(_build_speaker(audience))
	var center:=VBoxContainer.new();center.size_flags_horizontal=Control.SIZE_EXPAND_FILL;center.add_theme_constant_override("separation",6);stage.add_child(center)
	var hall_panel:=PanelContainer.new();hall_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var hall_style:=Tokens.flat(Tokens.FIELD_BG if Tokens.is_light() else Color("0a1316"),Tokens.BORDER_SOFT,1,8,0)
	hall_style.content_margin_left=14;hall_style.content_margin_right=10;hall_style.content_margin_top=12;hall_style.content_margin_bottom=10
	hall_panel.add_theme_stylebox_override("panel",hall_style);center.add_child(hall_panel)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",6);hall_panel.add_child(stack)
	transcript_scroll=ScrollContainer.new();transcript_scroll.name="Transcript";transcript_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	transcript_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;stack.add_child(transcript_scroll)
	transcript_scroll.gui_input.connect(_on_transcript_input)
	transcript=VBoxContainer.new();transcript.size_flags_horizontal=Control.SIZE_EXPAND_FILL;transcript.add_theme_constant_override("separation",10)
	transcript_scroll.add_child(transcript)
	thinking=Tokens.make_label("",14,Tokens.TEXT_DIM);thinking.name="Thinking";thinking.add_theme_font_override("font",_italic);thinking.visible=false;stack.add_child(thinking)
	stage.add_child(_build_bench(audience))
	return stage

func _build_speaker(audience:Dictionary)->Control:
	var speaker:Dictionary=audience.get("speaker",{})
	var origin:=String(audience.get("origin","foreign"))
	var column:=VBoxContainer.new();column.name="Speaker";column.custom_minimum_size.x=236;column.add_theme_constant_override("separation",8)
	speaker_frame=PanelContainer.new();speaker_frame.name="SpeakerFrame"
	var frame_style:=Tokens.flat(Color("eee7d8"),envoy_color,2,8,6)
	speaker_frame.add_theme_stylebox_override("panel",frame_style);column.add_child(speaker_frame)
	var holder:=Control.new();holder.custom_minimum_size=Vector2(222,196);holder.clip_contents=true;speaker_frame.add_child(holder)
	var person:=_speaker_person(audience)
	var portrait:=Portrait.picture(person,222,196);portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);holder.add_child(portrait)
	if origin=="foreign":
		var flag:=TextureRect.new();flag.texture=Identity.foreign(String(audience.get("civ_id",""))).texture
		flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;flag.mouse_filter=Control.MOUSE_FILTER_IGNORE
		flag.position=Vector2(160,134);flag.size=Vector2(56,56);holder.add_child(flag)
	var plate:=PanelContainer.new();var plate_style:=Tokens.flat(Tokens.TILE_BG,Color(0,0,0,0),0,6,0)
	plate_style.border_color=envoy_color;plate_style.border_width_left=4;plate_style.content_margin_left=12;plate_style.content_margin_right=8;plate_style.content_margin_top=7;plate_style.content_margin_bottom=8
	plate.add_theme_stylebox_override("panel",plate_style);column.add_child(plate)
	var names:=VBoxContainer.new();names.add_theme_constant_override("separation",0);plate.add_child(names)
	var name_label:=Tokens.make_label(String(speaker.get("name","An envoy")),19,envoy_color);name_label.add_theme_font_override("font",_bold);name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;names.add_child(name_label)
	var title_text:=String(speaker.get("title","envoy"))
	if origin=="foreign":title_text+=" of "+String(audience.get("civ_name",""))
	else:title_text=String(person.get("office_title",title_text))
	var title_label:=Tokens.make_label(title_text,13,Tokens.TEXT_SOFT);title_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;names.add_child(title_label)
	var room:=VBoxContainer.new();room.add_theme_constant_override("separation",3);column.add_child(room)
	var mood_head:=HBoxContainer.new();mood_head.add_theme_constant_override("separation",8);room.add_child(mood_head)
	mood_head.add_child(Tokens.make_label("THE ROOM",11,Tokens.TEXT_DIM,.1))
	mood_label=Tokens.make_label("",13,Tokens.BODY_2);mood_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;mood_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;mood_head.add_child(mood_label)
	mood_meter=MoodMeter.new();mood_meter.custom_minimum_size=Vector2(222,10);room.add_child(mood_meter)
	_update_mood(audience)
	var dossier:=_build_dossier(audience)
	if dossier:column.add_child(dossier)
	return column

func _build_dossier(audience:Dictionary)->Control:
	## Plain facts beside the performance: what the ruler actually knows.
	var context:Dictionary=Hall.voice_context(String(audience.get("id","")))
	var rows:Array=[]
	if String(audience.get("origin",""))=="foreign":
		var civ:Dictionary=context.get("civ",{}) if context.get("civ") is Dictionary else {}
		var leader:Dictionary=context.get("leader",{}) if context.get("leader") is Dictionary else {}
		if bool(civ.get("at_war_with_player",false)):rows.append(["Standing","at war with us",Tokens.RED])
		else:rows.append(["View of us",String(civ.get("opinion","unknown")),Tokens.BODY])
		rows.append(["Our border",String(civ.get("border","unknown")),Tokens.RED if String(civ.get("border",""))in ["tense","on the edge of violence"] else Tokens.BODY])
		rows.append(["Their larder",String(civ.get("food","unknown")),Tokens.BODY])
		if int(civ.get("population",0))>0:rows.append(["Their people","about %d" % int(civ.population),Tokens.BODY])
		if not String(leader.get("name","")).is_empty():rows.append(["Their ruler","%s, %s" % [String(leader.name),String(leader.get("trust","undecided"))],Tokens.BODY])
	elif String(audience.get("kind","")) in WORK_KINDS:
		rows.append_array(_work_dossier(audience))
	else:
		var petitioner:Dictionary=context.get("petitioner",{}) if context.get("petitioner") is Dictionary else {}
		if not petitioner.is_empty():
			rows.append(["Trust in you",String(petitioner.get("trust","moderate")),Tokens.BODY])
			rows.append(["Resentment",String(petitioner.get("resentment","none")),Tokens.RED if String(petitioner.get("resentment",""))=="deep" else Tokens.BODY])
	if context.has("food_situation"):rows.append(["Our stores",String(context.food_situation).trim_prefix("the stores are ").trim_prefix("food is "),Tokens.BODY])
	if rows.is_empty():return null
	var box:=VBoxContainer.new();box.name="Dossier";box.add_theme_constant_override("separation",3)
	box.add_child(Tokens.make_label("WHAT YOU KNOW",11,Tokens.TEXT_DIM,.1))
	for row:Array in rows:
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",6);box.add_child(line)
		var key:=Tokens.make_label(String(row[0]),12,Tokens.MUTED);key.custom_minimum_size.x=96;line.add_child(key)
		var value:=Tokens.make_label(String(row[1]),13,row[2]);value.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		value.clip_text=true;value.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;value.tooltip_text=String(row[1]);value.mouse_filter=Control.MOUSE_FILTER_PASS;line.add_child(value)
	return box

func _speaker_person(audience:Dictionary)->Dictionary:
	var speaker:Dictionary=audience.get("speaker",{})
	var person_id:=int(speaker.get("person_id",0))
	if person_id>0:
		var snapshot:Dictionary=GovernmentPeopleSystem.person_snapshot(person_id)
		if not snapshot.is_empty():return snapshot
	# A transient envoy record: bound to the civ's appearance family, never saved.
	var envoy:={"name":String(speaker.get("name","Envoy")),"person_id":0}
	var civ_id:=String(audience.get("civ_id",""))
	if not civ_id.is_empty():EarlyArt.bind_foreign_identity(envoy,civ_id,int(GameState.world_seed))
	return envoy

func _build_bench(audience:Dictionary)->Control:
	var column:=VBoxContainer.new();column.name="CourtBench";column.custom_minimum_size.x=212;column.add_theme_constant_override("separation",7)
	column.add_child(Tokens.make_label("YOUR COURT LOOKS ON",11,Tokens.TEXT_DIM,.1))
	var court:Array=Hall.court(String(audience.get("id","")))
	if court.is_empty():
		var alone:=Tokens.make_label("No officials attend. You receive them alone.",13,Tokens.MUTED);alone.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;alone.add_theme_font_override("font",_italic);column.add_child(alone)
	for person:Dictionary in court:
		var person_id:=int(person.get("person_id",0))
		var seat:=PanelContainer.new();seat.name="Seat%d" % person_id
		seat.add_theme_stylebox_override("panel",_seat_style(person_id,false))
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",9);seat.add_child(row)
		var face_frame:=PanelContainer.new();face_frame.add_theme_stylebox_override("panel",Tokens.flat(Color("eee7d8"),Color(0,0,0,0),0,4,2));row.add_child(face_frame)
		face_frame.add_child(Portrait.picture(person,52,62))
		var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",0);row.add_child(words)
		var who:=Tokens.make_label(String(person.get("name","Official")),14,_person_color(person_id));who.add_theme_font_override("font",_bold);who.clip_text=true;who.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;words.add_child(who)
		var office:=Tokens.make_label(String(person.get("office_title",person.get("title",""))),12,Tokens.TEXT_SOFT);office.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;office.max_lines_visible=2;words.add_child(office)
		seat.tooltip_text="%s · %s" % [String(person.get("name","")),String(person.get("office_title",""))]
		column.add_child(seat);bench_cards[person_id]=seat
	return column

func _seat_style(person_id:int,speaking:bool)->StyleBoxFlat:
	var style:=Tokens.flat(Tokens.ACTIVE_BG if speaking else Tokens.TILE_BG,Tokens.GOLD if speaking else Color(0,0,0,0),2 if speaking else 0,6,0)
	style.border_color=Tokens.GOLD if speaking else _person_color(person_id)
	style.border_width_left=4
	style.content_margin_left=8;style.content_margin_right=8;style.content_margin_top=6;style.content_margin_bottom=6
	return style

func _build_speech_row()->Control:
	var row:=HBoxContainer.new();row.name="SpeechRow";row.add_theme_constant_override("separation",8)
	speech_input=LineEdit.new();speech_input.name="SpeechInput";speech_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	speech_input.custom_minimum_size.y=42;speech_input.max_length=400;speech_input.add_theme_font_size_override("font_size",16)
	var audience:=Hall.find(audience_id)
	speech_input.placeholder_text="Speak to the envoy…" if String(audience.get("origin",""))=="foreign" else "Speak to %s…" % String((audience.get("speaker",{}) as Dictionary).get("name","them"))
	speech_input.add_theme_stylebox_override("read_only",Tokens.flat(Tokens.TILE_BG,Tokens.BORDER_SOFT,1,3,8))
	speech_input.text_submitted.connect(func(_t:String):_speak())
	row.add_child(speech_input)
	speak_button=Button.new();speak_button.name="Speak";speak_button.text="SPEAK";speak_button.custom_minimum_size=Vector2(110,42)
	speak_button.add_theme_font_size_override("font_size",15);speak_button.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
	speak_button.pressed.connect(_speak);row.add_child(speak_button)
	return row

func _build_options()->void:
	for child in options_row.get_children():child.queue_free()
	options_row.visible=true;outcome_box.visible=false
	for option:Dictionary in Hall.options(audience_id):
		options_row.add_child(_option_card(option))

func _option_card(option:Dictionary)->Button:
	var tone:=String(option.get("tone","neutral"))
	var tone_color:=_tone_color(tone)
	var enabled:=bool(option.get("enabled",true))
	var button:=Button.new();button.name="Option_"+String(option.get("id",""))
	button.set_meta("option_id",String(option.get("id","")))
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.custom_minimum_size=Vector2(0,72)
	button.disabled=not enabled;button.focus_mode=Control.FOCUS_ALL
	button.tooltip_text=String(option.get("reason","")) if not enabled else String(option.get("sub",""))
	var base:=Tokens.flat(tone_color.lerp(Tokens.PANEL_BG_SOLID,.86 if Tokens.is_light() else .80),tone_color,1,8,0)
	base.border_width_left=5
	var hover:=base.duplicate() as StyleBoxFlat;hover.bg_color=tone_color.lerp(Tokens.PANEL_BG_SOLID,.72 if Tokens.is_light() else .64);hover.set_border_width_all(2);hover.border_width_left=5
	var off:=Tokens.flat(Tokens.TILE_BG,Tokens.BORDER_SOFT,1,8,0);off.border_width_left=5
	for state in ["normal","focus"]:button.add_theme_stylebox_override(state,base)
	button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover);button.add_theme_stylebox_override("disabled",off)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,16)
	margin.add_theme_constant_override("margin_top",9);margin.add_theme_constant_override("margin_bottom",8)
	button.add_child(margin)
	var stack:=VBoxContainer.new();stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_theme_constant_override("separation",2);margin.add_child(stack)
	var ink:=_ink(tone_color) if enabled else Tokens.DISABLED
	var title:=Tokens.make_label(String(option.get("label","")),17,ink);title.add_theme_font_override("font",_bold);title.mouse_filter=Control.MOUSE_FILTER_IGNORE
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;stack.add_child(title)
	var sub_text:=String(option.get("sub","")) if enabled else String(option.get("reason",option.get("sub","")))
	var sub:=Tokens.make_label(sub_text,13,Tokens.BODY_2 if enabled else Tokens.RED);sub.mouse_filter=Control.MOUSE_FILTER_IGNORE
	sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;sub.max_lines_visible=2;sub.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	if not enabled:sub.add_theme_font_override("font",_italic)
	stack.add_child(sub)
	var chosen:=String(option.get("id",""))
	button.pressed.connect(func():choose(chosen))
	return button

func _build_footer()->Control:
	var bar:=PanelContainer.new();bar.name="Footer"
	var bar_style:=Tokens.flat(Tokens.TILE_BG,Color(0,0,0,0),0,0,0)
	bar_style.corner_radius_bottom_left=9;bar_style.corner_radius_bottom_right=9;bar_style.border_color=Tokens.BORDER_SOFT;bar_style.border_width_top=1
	bar_style.content_margin_left=20;bar_style.content_margin_right=20;bar_style.content_margin_top=8;bar_style.content_margin_bottom=8
	bar.add_theme_stylebox_override("panel",bar_style)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);bar.add_child(row)
	wait_button=Button.new();wait_button.name="MakeThemWait";wait_button.text="Make them wait";wait_button.custom_minimum_size=Vector2(150,34)
	wait_button.tooltip_text="Send them to the antechamber. Guests kept waiting too long leave insulted."
	wait_button.pressed.connect(make_them_wait);row.add_child(wait_button)
	summon_check=CheckBox.new();summon_check.name="SummonImmediately";summon_check.text="Summon me at once when envoys arrive"
	summon_check.add_theme_font_size_override("font_size",13)
	summon_check.button_pressed=bool(Hall.state().get("summon_immediately",true))
	summon_check.toggled.connect(func(on:bool):Hall.state()["summon_immediately"]=on)
	row.add_child(summon_check)
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(spacer)
	# Which voice is speaking and what it has cost; the tooltip carries the receipts.
	voice_label=Tokens.make_label("",12,Tokens.MUTED);voice_label.name="VoiceIndicator"
	voice_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;voice_label.custom_minimum_size=Vector2(150,0)
	voice_label.clip_text=true;voice_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	voice_label.mouse_filter=Control.MOUSE_FILTER_PASS
	row.add_child(voice_label)
	frequency_pick=OptionButton.new();frequency_pick.name="AudienceFrequency";frequency_pick.focus_mode=Control.FOCUS_NONE
	frequency_pick.add_theme_font_size_override("font_size",13)
	for level in FREQUENCY_LEVELS:frequency_pick.add_item(String(FREQUENCY_WORDS[level]))
	frequency_pick.tooltip_text="How often envoys and petitioners ask to be received."
	frequency_pick.select(maxi(0,FREQUENCY_LEVELS.find(_frequency())))
	frequency_pick.item_selected.connect(_on_frequency_selected)
	frequency_pick.disabled=not _hall_api().has_method("set_frequency")
	row.add_child(frequency_pick)
	queue_label=Tokens.make_label("",13,Tokens.TEXT_SOFT);queue_label.name="QueueLabel";queue_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(queue_label)
	next_button=Button.new();next_button.name="NextAudience";next_button.text="Receive the next ›";next_button.custom_minimum_size=Vector2(150,34)
	next_button.pressed.connect(receive_next);row.add_child(next_button)
	return bar

func _hall_api()->Object:
	## The hall script as an object, for optional (duck-typed) engine calls.
	return load("res://scripts/audience_hall.gd")

const FREQUENCY_LEVELS:=["rare","normal","lively"]
const FREQUENCY_WORDS:={"rare":"Visitors: rare","normal":"Visitors: normal","lively":"Visitors: lively"}

func _frequency()->String:
	## The hall's pacing level; "normal" until the engine exposes one.
	if _hall_api().has_method("frequency"):return String(_hall_api().call("frequency"))
	var level:=String(Hall.state().get("frequency","normal"))
	return level if level in FREQUENCY_LEVELS else "normal"

func _on_frequency_selected(index:int)->void:
	if index<0 or index>=FREQUENCY_LEVELS.size():return
	if _hall_api().has_method("set_frequency"):_hall_api().call("set_frequency",String(FREQUENCY_LEVELS[index]))

func voice_status()->Dictionary:
	if _voice_ok() and voice.has_method("status"):return voice.status()
	return {"live":false,"label":"Offline voice — no voice attached","tooltip":""}

func _refresh_voice_indicator()->void:
	if not is_instance_valid(voice_label):return
	var status:=voice_status()
	var text:=String(status.get("label",""))
	if voice_label.text!=text:voice_label.text=text
	voice_label.tooltip_text=String(status.get("tooltip",""))
	voice_label.add_theme_color_override("font_color",Tokens.MUTED if bool(status.get("live",false)) else Tokens.TEXT_DIM)

# --- Behaviour --------------------------------------------------------------

func _voice_ok()->bool:
	return is_instance_valid(voice) and voice.has_method("busy")

func _connect_voice()->void:
	if not _voice_ok():return
	if voice.has_signal("lines_ready") and not voice.lines_ready.is_connected(_on_lines_ready):voice.lines_ready.connect(_on_lines_ready)

func _on_lines_ready(id:String)->void:
	if id==audience_id:_pump()

func _speak()->void:
	var text:=speech_input.text.strip_edges()
	if text.is_empty() or speak_button.disabled:return
	speech_input.clear()
	var before:=(Hall.find(audience_id).get("lines",[]) as Array).size()
	if _voice_ok():voice.player_speaks(audience_id,text)
	# An order given to a summoned official goes to the civic council as a directive.
	var here:=Hall.find(audience_id)
	if String(here.get("origin",""))=="court" and Hall.is_directive(text) and is_instance_valid(terrain) and terrain.has_method("issue_civic_directive_text"):
		terrain.issue_civic_directive_text(text)
		Hall.append_line(audience_id,{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":"Your words go out to the council as an order.","day":int(GameState.elapsed_days),"aside":false})
	# The ruler's own words always appear, even if the voice defers them.
	var lines:Array=Hall.find(audience_id).get("lines",[])
	var echoed:=false
	for index in range(before,lines.size()):
		if String((lines[index] as Dictionary).get("role",""))=="ruler":echoed=true
	if not echoed:
		Hall.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text,"day":int(GameState.elapsed_days),"aside":false})
	_pump()

func choose(option_id:String)->Dictionary:
	if not resolved_result.is_empty():return resolved_result
	var audience:=Hall.find(audience_id)
	var result:Dictionary=Hall.resolve(audience_id,option_id)
	if not bool(result.get("ok",false)):
		_show_toast(String(result.get("outcome",result.get("error","That cannot be done."))))
		_build_options();return result
	if not String(result.get("next_audience_id","")).is_empty():
		# They set the first matter aside and raise the other one.
		show_audience(String(result.next_audience_id))
		return result
	var routed:=String(result.get("decree",""))
	if not routed.is_empty() and is_instance_valid(terrain) and terrain.has_method("issue_civic_directive_text"):
		terrain.issue_civic_directive_text(routed)
	conceive_next=bool(result.get("conceive",false))
	if String(audience.get("kind",""))=="petition" and option_id.contains("decree"):
		var decree:=String((audience.get("petition",{}) as Dictionary).get("suggested_decree",""))
		if not decree.is_empty() and is_instance_valid(terrain) and terrain.has_method("issue_civic_directive_text"):
			terrain.issue_civic_directive_text(decree)
	if _voice_ok():voice.closing(audience_id,result)
	_show_outcome(result)
	return result

func _show_outcome(result:Dictionary)->void:
	resolved_result=result
	for child in options_row.get_children():child.queue_free()
	options_row.visible=false
	for child in outcome_box.get_children():child.queue_free()
	outcome_box.visible=true
	var reaction:=String(result.get("reaction","neutral"))
	var tone:="danger" if reaction in ["offended","furious"] else ("info" if reaction in ["delighted","pleased"] else "warn")
	var receipt:=PanelContainer.new();receipt.name="Receipt";receipt.add_theme_stylebox_override("panel",Tokens.brief_style(tone))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);receipt.add_child(row)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",2);row.add_child(words)
	var audience:=Hall.find(audience_id)
	var who:="THE ENVOY IS " if String(audience.get("origin",""))=="foreign" else "%s IS " % String((audience.get("speaker",{}) as Dictionary).get("name","YOUR OFFICIAL")).to_upper()
	if String(audience.get("kind",""))=="wonder_proposal" and not String(result.get("work_id","")).is_empty():who="THE WORK IS COMMISSIONED · "+who
	var colour:=Tokens.RED if tone=="danger" else (Tokens.TEAL if tone=="info" else Tokens.AMBER)
	var head:=Tokens.make_label("THE AUDIENCE IS CONCLUDED · "+who+String(REACTION_WORDS.get(reaction,"UNMOVED")),13,colour,.08);head.name="ReceiptHead";words.add_child(head)
	var outcome:=Tokens.make_label(String(result.get("outcome","")),15,Tokens.BODY);outcome.name="ReceiptText";outcome.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(outcome)
	var dismiss:=Button.new();dismiss.name="Dismiss";dismiss.text="Dismiss the court";dismiss.custom_minimum_size=Vector2(190,46)
	dismiss.add_theme_font_size_override("font_size",16);dismiss.add_theme_stylebox_override("normal",Tokens.gold_outline_style());dismiss.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	dismiss.pressed.connect(_close);row.add_child(dismiss)
	if conceive_next:
		var visions:=Button.new();visions.name="HearVisions";visions.text="Hear the court's visions ›";visions.custom_minimum_size=Vector2(220,46)
		visions.add_theme_font_size_override("font_size",16);visions.add_theme_stylebox_override("normal",Tokens.gold_outline_style());visions.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		visions.pressed.connect(open_conception);row.add_child(visions)
	outcome_box.add_child(receipt)
	_refresh_footer()

func make_them_wait()->void:
	if resolved_result.is_empty():Hall.defer(audience_id)
	_close()

func receive_next()->void:
	var next_id:=_next_waiting_id()
	if next_id.is_empty():return
	if resolved_result.is_empty():Hall.defer(audience_id)
	show_audience(next_id)

func _next_waiting_id()->String:
	for audience:Dictionary in Hall.waiting():
		if String(audience.get("id",""))!=audience_id:return String(audience.id)
	return ""

func _close()->void:
	if is_queued_for_deletion():return
	closed.emit(audience_id)
	queue_free()

func _refresh_footer()->void:
	if not is_instance_valid(queue_label):return
	var others:=0
	for audience:Dictionary in Hall.waiting():
		if String(audience.get("id",""))!=audience_id:others+=1
	queue_label.text="" if others==0 else ("1 more awaits in the antechamber" if others==1 else "%d more await in the antechamber" % others)
	next_button.visible=others>0
	wait_button.visible=resolved_result.is_empty()
	var open:=resolved_result.is_empty()
	if speech_input.editable!=open:
		speech_input.editable=open
		if not open:speech_input.placeholder_text="The audience is concluded. They are taking their leave."
	speak_button.disabled=not open or (_voice_ok() and voice.busy(audience_id))
	_refresh_voice_indicator()

func _show_toast(text:String)->void:
	var note:=Tokens.make_label(text,13,Tokens.RED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	transcript.add_child(note)

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if resolved_result.is_empty():make_them_wait()
		else:_close()

func _on_transcript_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:skip_reveal()

func skip_reveal()->void:
	for tween in reveal_tweens:
		if tween and tween.is_valid():tween.custom_step(60.0)
	reveal_tweens.clear();revealing=false
	var lines:Array=Hall.find(audience_id).get("lines",[])
	while rendered_lines<lines.size():
		_add_line(lines[rendered_lines],false);rendered_lines+=1
	follow_scroll=.5

func _process(delta:float)->void:
	clock+=delta
	_fit()
	if audience_id.is_empty():return
	_pump()
	var busy:bool=_voice_ok() and voice.busy(audience_id)
	if is_instance_valid(thinking):
		thinking.visible=busy
		if busy:
			var audience:=Hall.find(audience_id)
			var who:=String((audience.get("speaker",{}) as Dictionary).get("name","The envoy"))
			thinking.text="%s weighs their words%s" % [who,".".repeat(1+int(clock*2.5)%3)] if resolved_result.is_empty() or rendered_lines==0 else "The room stirs%s" % ".".repeat(1+int(clock*2.5)%3)
	if is_instance_valid(speak_button):speak_button.disabled=not resolved_result.is_empty() or busy
	if follow_scroll>0.0 and is_instance_valid(transcript_scroll):
		follow_scroll-=delta
		transcript_scroll.scroll_vertical=int(transcript_scroll.get_v_scroll_bar().max_value)
	if int(clock*4)!=int((clock-delta)*4):
		_update_mood(Hall.find(audience_id));_refresh_footer()
	if weigh_clock>=0.0:
		weigh_clock-=delta
		if weigh_clock<0.0 and _voice_ok() and not voice.busy(audience_id) and voice.has_method("weigh") and resolved_result.is_empty():voice.weigh(audience_id)

func _pump()->void:
	if revealing or not is_instance_valid(transcript):return
	var lines:Array=Hall.find(audience_id).get("lines",[])
	if rendered_lines>=lines.size():return
	var line:Dictionary=lines[rendered_lines];rendered_lines+=1
	_add_line(line,true)

# --- Transcript rows --------------------------------------------------------

func _add_line(line:Dictionary,animate:bool)->void:
	var role:=String(line.get("role","official"))
	var aside:=bool(line.get("aside",false))
	var person_id:=int(line.get("person_id",0))
	var row:Control
	if role=="narrator":
		var narration:=Tokens.make_label(String(line.get("text","")),14,Tokens.TEXT_DIM);narration.add_theme_font_override("font",_italic)
		narration.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;narration.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		row=narration;transcript.add_child(row)
		_reveal(row,narration,animate);return
	var colour:=_line_color(line)
	var line_row:=HBoxContainer.new();line_row.add_theme_constant_override("separation",10);row=line_row
	if role=="ruler":
		var indent:=Control.new();indent.custom_minimum_size.x=110;line_row.add_child(indent)
	else:
		line_row.add_child(_avatar(line))
	var bubble:=PanelContainer.new();bubble.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var bubble_bg:=colour.lerp(Tokens.PANEL_BG_SOLID,.90 if Tokens.is_light() else .86)
	if aside:bubble_bg=Tokens.TILE_BG
	var bubble_style:=Tokens.flat(bubble_bg,colour if not aside else Tokens.BORDER_SOFT,1,10,0)
	if role=="ruler":bubble_style.border_width_right=4;bubble_style.border_width_left=1;bubble_style.corner_radius_top_right=2
	else:bubble_style.border_width_left=4;bubble_style.corner_radius_top_left=2
	bubble_style.content_margin_left=14;bubble_style.content_margin_right=14;bubble_style.content_margin_top=8;bubble_style.content_margin_bottom=10
	bubble.add_theme_stylebox_override("panel",bubble_style);line_row.add_child(bubble)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",2);bubble.add_child(stack)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);stack.add_child(head)
	var speaker_name:=String(line.get("speaker",""))
	if role=="ruler":speaker_name="You"
	var name_label:=Tokens.make_label(speaker_name,14,colour);name_label.add_theme_font_override("font",_bold);head.add_child(name_label)
	var note:=_line_note(line)
	if not note.is_empty():head.add_child(Tokens.make_label(note,12,Tokens.TEXT_DIM))
	if aside:
		var whisper:=Tokens.make_label("— aside to you —",12,Tokens.TEXT_DIM);whisper.add_theme_font_override("font",_italic);head.add_child(whisper)
	var text:=Tokens.make_label(String(line.get("text","")),16,Tokens.TEXT_SOFT if aside else Tokens.BODY);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if aside:text.add_theme_font_override("font",_italic)
	text.name="LineText";stack.add_child(text)
	transcript.add_child(row)
	_highlight_speaker(role,person_id)
	_reveal(row,text,animate)

func _line_note(line:Dictionary)->String:
	var role:=String(line.get("role",""))
	if role=="official":
		var seat:Control=bench_cards.get(int(line.get("person_id",0)))
		if seat:return String(seat.tooltip_text.get_slice(" · ",1))
		var snapshot:Dictionary=GovernmentPeopleSystem.person_snapshot(int(line.get("person_id",0))) if int(line.get("person_id",0))>0 else {}
		return String(snapshot.get("office_title",snapshot.get("title","")))
	if role=="envoy":
		var audience:=Hall.find(audience_id)
		return String((audience.get("speaker",{}) as Dictionary).get("title","")) if String(audience.get("origin",""))=="court" else "envoy of "+String(audience.get("civ_name",""))
	return ""

func _avatar(line:Dictionary)->Control:
	var frame:=PanelContainer.new();frame.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	frame.add_theme_stylebox_override("panel",Tokens.flat(Color("eee7d8"),_line_color(line),1,6,2))
	var role:=String(line.get("role",""))
	var person_id:=int(line.get("person_id",0))
	if role=="official" and person_id>0:
		frame.add_child(Portrait.picture(GovernmentPeopleSystem.person_snapshot(person_id),44,52))
	elif role=="official" and speaker_person_id==0 and String(line.get("speaker",""))==String((Hall.find(audience_id).get("speaker",{}) as Dictionary).get("name","")):
		frame.add_child(Portrait.picture(_speaker_person(Hall.find(audience_id)),44,52))
	elif role=="envoy":
		frame.add_child(Portrait.picture(_speaker_person(Hall.find(audience_id)),44,52))
	else:
		var flag:=TextureRect.new();flag.texture=Identity.foreign(String(line.get("civ_id",""))).texture;flag.custom_minimum_size=Vector2(44,52)
		flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;frame.add_child(flag)
	return frame

func _reveal(row:Control,text:Label,animate:bool)->void:
	follow_scroll=.6
	if not animate:return
	revealing=true
	row.modulate.a=0.0;text.visible_ratio=0.0
	var tween:=create_tween();reveal_tweens.append(tween)
	tween.tween_property(row,"modulate:a",1.0,.18)
	tween.tween_property(text,"visible_ratio",1.0,clampf(text.text.length()*.014,.25,1.8))
	tween.tween_interval(.35)
	tween.finished.connect(func():
		revealing=false;reveal_tweens.erase(tween))

func _highlight_speaker(role:String,person_id:int)->void:
	for id in bench_cards:
		(bench_cards[id] as PanelContainer).add_theme_stylebox_override("panel",_seat_style(int(id),role=="official" and int(id)==person_id))
	if is_instance_valid(speaker_frame):
		var speaking:=role=="envoy" or (speaker_person_id>0 and person_id==speaker_person_id)
		speaker_frame.add_theme_stylebox_override("panel",Tokens.flat(Color("eee7d8"),Tokens.GOLD if speaking else envoy_color,4 if speaking else 2,8,6 if not speaking else 4))

func _update_mood(audience:Dictionary)->void:
	if not is_instance_valid(mood_meter):return
	var mood:=clampf(float(audience.get("mood",0.0)),-1.0,1.0)
	mood_meter.value=mood;mood_meter.queue_redraw()
	mood_label.text="Frosty" if mood<=-.5 else ("Tense" if mood<=-.15 else ("Cordial" if mood<.15 else ("Warm" if mood<.5 else "Glowing")))

# --- Great works ------------------------------------------------------------

func _work_herald(audience:Dictionary)->Dictionary:
	var speaker:Dictionary=audience.get("speaker",{})
	var who:=String(speaker.get("name","The master builder")).to_upper()
	if String(audience.get("kind",""))=="wonder_proposal":
		var p:=Works.proposal(audience)
		var concepts:Array=p.get("concepts",[])
		var herald:="%s WOULD RAISE A WONDER" % who if int(speaker.get("person_id",0))==0 else "%s %s PROPOSES A GREAT WORK" % [String(speaker.get("title","")).to_upper(),who]
		if String(p.get("origin",""))=="ruler":herald="YOU CALL FOR A GREAT WORK"
		var info:={"eyebrow":"A GREAT WORK IS PROPOSED","herald":herald,"byline":String((p.get("trigger",{}) as Dictionary).get("text","")),
			"chip":["VISIONS","%d to weigh" % concepts.size() if concepts.size()!=1 else "one vision"]}
		var chosen:=Works.chosen_concept(audience)
		if not chosen.is_empty():info["plate"]=chosen
		return info
	var gw:Dictionary=audience.get("great_work",{}) if audience.get("great_work") is Dictionary else {}
	var title:=String(gw.get("title","the work"))
	var stage:=String(Works.STAGE_WORDS.get(String(gw.get("stage","")),""))
	var progress:=roundi(float(gw.get("progress",0))*100)
	var plate:={"work_id":String(gw.get("work_id","")),"shape":String(gw.get("form","")),"status":"building","progress":float(gw.get("progress",0))}
	match String(gw.get("mode","")):
		"decision":
			var master:=who if int(speaker.get("person_id",0))==0 else String(speaker.get("title","")).to_upper()+" "+who
			return {"eyebrow":"A STAGE GATE AT %s" % title.to_upper(),"herald":"MASTER BUILDER %s SEEKS YOUR JUDGMENT" % who if int(speaker.get("person_id",0))==0 else "%s SEEKS YOUR JUDGMENT" % master,
				"byline":String(gw.get("text","")),"chip":["THE WORK","%s · %d%%" % [stage if not stage.is_empty() else "Rising",progress]],"plate":plate}
		"event":
			return {"eyebrow":"HARD NEWS FROM THE WORKS","herald":"%s: %s" % [title.to_upper(),{"collapse":"A COLLAPSE","accident":"DEATH ON THE SCAFFOLDS","strike":"THE CREWS STRIKE","fire":"FIRE IN THE NIGHT","poaching":"OUR BUILDER IS LURED AWAY"}.get(String(gw.get("key","")),"TROUBLE")],
				"byline":String(gw.get("text","")),"chip":["THE WORK","%s · %d%%" % [stage if not stage.is_empty() else "Rising",progress]],"plate":plate}
		"outcome":
			plate["status"]="abandoned" if String(gw.get("key",""))=="abandoned" else "ruined"
			if String(gw.get("key",""))=="abandoned":
				return {"eyebrow":"A WORK LAID DOWN","herald":"THE WORK AT %s IS ABANDONED" % title.to_upper(),"byline":String(gw.get("text","")),"chip":["LEFT AT","%d%% raised" % progress],"plate":plate}
			var dead:Array=gw.get("dead",[])
			return {"eyebrow":"A GREAT WORK HAS FALLEN","herald":"%s HAS FALLEN" % String(gw.get("ruin_name",title)).to_upper(),"byline":String(gw.get("text","")),
				"chip":["THE DEAD","%d named" % dead.size() if not dead.is_empty() else "none named"],"plate":plate}
		"news":
			plate["status"]=String(gw.get("key","building"))
			return {"eyebrow":"WORD OF ANOTHER PEOPLE'S WONDER","herald":"%s RAISE A WONDER" % String(gw.get("civ_name","A NEIGHBOR")).to_upper(),"byline":String(gw.get("text","")),"chip":["AS OF","day %d" % int(gw.get("as_of",0))],"plate":plate}
		"forecast":
			return {"eyebrow":"THE WATCHING SKY","herald":"THE SKY-WATCHERS WARN OF LEAN DAYS","byline":String(gw.get("text","")),"chip":["COMING IN","about %d days" % int(gw.get("in_days",0))]}
	return {}

func _work_dossier(audience:Dictionary)->Array:
	var rows:Array=[]
	if String(audience.get("kind",""))=="wonder_proposal":
		var assess:=Works.assessment(audience)
		var chosen:=Works.chosen_concept(audience)
		if not chosen.is_empty():rows.append(["Weighing",Works.concept_name(chosen),Tokens.BODY])
		if not assess.is_empty():
			rows.append(["The odds",Works.odds_words(float(assess.get("score",.5))),Tokens.RED if float(assess.get("score",.5))<.4 else Tokens.BODY])
			var time:=Works.duration_words(assess.get("duration_estimate",""))
			if not time.is_empty():rows.append(["Would take",time,Tokens.BODY])
		return rows
	var gw:Dictionary=audience.get("great_work",{}) if audience.get("great_work") is Dictionary else {}
	if not String(gw.get("architect_name","")).is_empty():
		rows.append(["Master builder",String(gw.get("architect_name","")),Tokens.BODY])
		if not String(gw.get("style","")).is_empty():rows.append(["Their style",String(gw.get("style","")),Tokens.BODY])
		rows.append(["Their pride","towering" if float(gw.get("ego",.5))>.7 else ("prickly" if float(gw.get("ego",.5))>.5 else "modest"),Tokens.RED if float(gw.get("ego",.5))>.7 else Tokens.BODY])
	if String(gw.get("mode",""))=="decision":
		var feasible:=Works.site_feasibility(String(gw.get("city_id","")),String(gw.get("work_id","")))
		if not feasible.is_empty():rows.append(["The odds",Works.odds_words(float(feasible.get("score",.5))),Tokens.RED if float(feasible.get("score",.5))<.4 else Tokens.BODY])
	return rows

func _build_proposal()->void:
	if not is_instance_valid(proposal_box):return
	for child in proposal_box.get_children():child.queue_free()
	var audience:=Hall.find(audience_id)
	var p:=Works.proposal(audience)
	var concepts:Array=p.get("concepts",[])
	var chosen:=int(p.get("chosen",0))
	var cards:=HBoxContainer.new();cards.name="Concepts";cards.add_theme_constant_override("separation",10);proposal_box.add_child(cards)
	for index in concepts.size():
		if concepts[index] is Dictionary:cards.add_child(_concept_card(concepts[index],index,index==chosen))
	var controls:=HBoxContainer.new();controls.name="ProposalControls";controls.add_theme_constant_override("separation",8);proposal_box.add_child(controls)
	var ambition_label:=Tokens.make_label("AMBITION",11,Tokens.TEXT_DIM,.12);ambition_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;controls.add_child(ambition_label)
	var current:=String(p.get("ambition","grand"))
	for level:String in Works.AMBITIONS:
		var button:=Button.new();button.name="Ambition_"+level;button.text=String(Works.AMBITION_WORDS[level]);button.toggle_mode=true;button.button_pressed=level==current
		button.custom_minimum_size=Vector2(104,36);button.focus_mode=Control.FOCUS_NONE;button.tooltip_text=String(AMBITION_TIPS.get(level,""))
		var on:=level==current
		button.add_theme_stylebox_override("normal",Tokens.flat(Tokens.GOLD_WASH if on else Tokens.BUTTON_BG,Tokens.GOLD if on else Tokens.BORDER_SOFT,2 if on else 1,4,0))
		button.add_theme_stylebox_override("pressed",Tokens.flat(Tokens.GOLD_WASH,Tokens.GOLD,2,4,0))
		button.add_theme_color_override("font_color",Tokens.GOLD_BRIGHT if on else Tokens.BODY)
		var pick:=level
		button.pressed.connect(func()->void:choose_proposal({"ambition":pick}))
		controls.add_child(button)
	if GameState.player_settlements.size()>1:
		var cities:=OptionButton.new();cities.name="ProposalCity";cities.custom_minimum_size=Vector2(170,36)
		var index:=0
		for city:Dictionary in GameState.player_settlements:
			cities.add_item(String(city.get("name","")))
			cities.set_item_metadata(index,String(city.get("id","")))
			if String(city.get("id",""))==String(p.get("city_id","")):cities.select(index)
			index+=1
		cities.item_selected.connect(func(item:int)->void:choose_proposal({"city_id":String(cities.get_item_metadata(item))}))
		controls.add_child(cities)
	var assess:=Works.assessment(audience)
	var gauge:=OddsGauge.new();gauge.name="OddsGauge";gauge.custom_minimum_size=Vector2(150,36);gauge.score=float(assess.get("score",.5));gauge.known=not assess.is_empty();controls.add_child(gauge)
	var reckoning:=Tokens.make_label(Works.odds_words(gauge.score).capitalize() if gauge.known else "The court cannot yet say",14,Tokens.INK);reckoning.name="OddsWords"
	reckoning.add_theme_font_override("font",_bold);reckoning.size_flags_vertical=Control.SIZE_SHRINK_CENTER;controls.add_child(reckoning)
	var detail:=PackedStringArray()
	var costs:=Works.costs_words(assess.get("costs",{}))
	if not costs.is_empty():detail.append("needs "+costs)
	var time:=Works.duration_words(assess.get("duration_estimate",""))
	if not time.is_empty():detail.append(time)
	var bill:=Tokens.make_label(" · ".join(detail),12,Tokens.TEXT_SOFT);bill.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bill.clip_text=true;bill.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	bill.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bill.tooltip_text=bill.text;bill.mouse_filter=Control.MOUSE_FILTER_PASS;controls.add_child(bill)
	var describe:=LineEdit.new();describe.name="DescribeVision";describe.placeholder_text="Describe your own vision…";describe.custom_minimum_size=Vector2(250,36);describe.max_length=400
	describe.text_submitted.connect(func(text:String)->void:describe_vision(text))
	controls.add_child(describe)
	var ask:=Button.new();ask.name="AskBuilders";ask.text="Ask the builders";ask.custom_minimum_size=Vector2(130,36);ask.focus_mode=Control.FOCUS_NONE
	ask.pressed.connect(func()->void:describe_vision(describe.text))
	controls.add_child(ask)

func _concept_card(concept:Dictionary,index:int,active:bool)->Control:
	var card:=PanelContainer.new();card.name="Concept_%d" % index;card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	var style:=Tokens.flat(Tokens.ACTIVE_BG if active else Tokens.TILE_BG,Tokens.GOLD if active else Tokens.BORDER_SOFT,2 if active else 1,8,0)
	style.content_margin_left=8;style.content_margin_right=10;style.content_margin_top=6;style.content_margin_bottom=6
	card.add_theme_stylebox_override("panel",style)
	card.tooltip_text=Works.concept_lore(concept)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(row)
	var art:=WorkPlate.make(concept,70);art.custom_minimum_size=Vector2(104,70);row.add_child(art)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",0);words.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(words)
	var title:=Tokens.make_label(Works.concept_name(concept),16,Tokens.GOLD_BRIGHT if active else Tokens.INK);title.add_theme_font_override("font",_bold);title.clip_text=true;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(title)
	var purpose:=Works.concept_purpose(concept)
	var what:=Tokens.make_label("A %s%s%s" % [Works.concept_form(concept).replace("_"," "),(" to "+purpose) if not purpose.is_empty() else "",("  · your own vision" if bool(concept.get("described_by_ruler",false)) else "")],12,Tokens.TEXT_SOFT);what.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(what)
	var lore:=Tokens.make_label(Works.concept_lore(concept),12,Tokens.BODY_2);lore.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;lore.max_lines_visible=2;lore.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;lore.add_theme_font_override("font",_italic);lore.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(lore)
	card.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:choose_proposal({"chosen":index}))
	return card

## The ruler's pick in a wonder proposal (concept, ambition, city). The court
## weighs the new pick a moment later.
func choose_proposal(choice:Dictionary)->Dictionary:
	var answer:=Hall.proposal_choice(audience_id,choice)
	if answer.has("error"):_show_toast(String(answer.error));return answer
	_build_proposal()
	_build_options()
	weigh_clock=.6
	return answer

## The ruler's own vision. With a configured model connection the words are
## mapped by the model (bounded by the grammar); otherwise, or on any failure,
## the offline keyword mapping answers at once.
func describe_vision(text:String)->Dictionary:
	if text.strip_edges().is_empty():return {"error":"Describe the work you imagine."}
	Hall.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text.strip_edges().substr(0,400),"day":int(GameState.elapsed_days),"aside":false})
	var offline:=_voice_ok() and "force_offline" in voice and bool(voice.force_offline)
	var request:={} if offline else Works.api_dict("mapping_request",[text])
	if not request.is_empty() and request.get("config") is Dictionary and not (request.config as Dictionary).is_empty():
		_request_mapping(audience_id,text,request)
		return {"ok":true,"pending":true}
	return _apply_vision(audience_id,text,{})

func _apply_vision(id:String,text:String,mapping:Dictionary)->Dictionary:
	if id!=audience_id:return {"error":"The audience has moved on."}
	var answer:=Hall.proposal_describe(id,text,mapping)
	if answer.has("error"):_show_toast(String(answer.error));return answer
	_build_proposal()
	_build_options()
	weigh_clock=.3
	return answer

func _request_mapping(id:String,text:String,request:Dictionary)->void:
	var config:Dictionary=request.config
	var payload:={"model":String(config.get("model","")),"max_completion_tokens":200,"messages":request.get("messages",[])}
	var http:=HTTPRequest.new();http.timeout=20.0;http.max_redirects=0;http.body_size_limit=16384;add_child(http)
	_show_toast("The builders are sketching your vision…")
	http.request_completed.connect(func(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray)->void:
		http.queue_free()
		var mapping:={}
		if result==HTTPRequest.RESULT_SUCCESS and code>=200 and code<300:mapping=_mapping_from(body)
		_apply_vision(id,text,mapping))
	var headers:=PackedStringArray(["Content-Type: application/json","Authorization: Bearer %s" % String(config.get("api_key",""))])
	if http.request(String(config.get("endpoint","")),headers,HTTPClient.METHOD_POST,JSON.stringify(payload))!=OK:
		http.queue_free()
		_apply_vision(id,text,{})

static func _mapping_from(body:PackedByteArray)->Dictionary:
	var envelope:Variant=JSON.parse_string(body.get_string_from_utf8())
	if not envelope is Dictionary:return {}
	var content:=""
	var choices:Variant=(envelope as Dictionary).get("choices",[])
	if choices is Array and not (choices as Array).is_empty() and choices[0] is Dictionary:
		var message:Variant=(choices[0] as Dictionary).get("message",{})
		if message is Dictionary:content=PronouncementInterpreter._content_text((message as Dictionary).get("content",""))
	var first:=content.find("{");var last:=content.rfind("}")
	if first<0 or last<=first:return {}
	var mapping:Variant=JSON.parse_string(content.substr(first,last-first+1))
	if not mapping is Dictionary:return {}
	var clean:={}
	for key in ["form","purpose","ambition"]:
		if (mapping as Dictionary).get(key) is String:clean[key]=String(mapping[key]).substr(0,40)
	return clean

## Opens (or reopens) a wonder proposal: the court is asked for a new work.
func open_conception()->void:
	var made:=Works.ruler_proposal()
	if made.is_empty():_show_toast("Nobody at court can carry a proposal just now.");return
	show_audience(String(made.id))

# --- Colour helpers ---------------------------------------------------------

func _kind_color(kind:String)->Color:
	match kind:
		"gift":return Tokens.GREEN
		"request":return Tokens.AMBER
		"threat":return Tokens.RED
		"news","proposal":return Tokens.BLUE
		"petition":return Tokens.VIOLET
		"report":return Tokens.TEAL
		"wonder_proposal":return Tokens.GOLD
		"great_work":
			var found:=Hall.find(audience_id)
			var gw:Dictionary=found.get("great_work",{}) if found.get("great_work") is Dictionary else {}
			match String(gw.get("mode","")):
				"outcome":return Tokens.RED if String(gw.get("key",""))!="abandoned" else Tokens.MUTED
				"event":return Tokens.AMBER
				"news":return Tokens.BLUE
				"forecast":return Tokens.TEAL
			return Tokens.GOLD
	return Tokens.GOLD

func _tone_color(tone:String)->Color:
	match tone:
		"warm":return Tokens.GREEN
		"hostile":return Tokens.RED
	return Tokens.BLUE

func _line_color(line:Dictionary)->Color:
	if speaker_person_id>0 and int(line.get("person_id",0))==speaker_person_id:return envoy_color
	match String(line.get("role","")):
		"envoy":return envoy_color
		"ruler":return _ink(Tokens.GOLD)
		"narrator":return Tokens.TEXT_DIM
	return _person_color(int(line.get("person_id",0)))

func _person_color(person_id:int)->Color:
	var palette:=[Tokens.TEAL,Tokens.VIOLET,Tokens.AMBER,Tokens.BLUE,Tokens.GREEN]
	return _ink(palette[posmod(person_id,palette.size())])

static func _ink(colour:Color)->Color:
	## Nudge an identity colour until it reads against the card surface.
	var background:=Tokens.PANEL_BG_SOLID.srgb_to_linear().get_luminance()
	for step in 24:
		var foreground:=colour.srgb_to_linear().get_luminance()
		if (maxf(background,foreground)+.05)/(minf(background,foreground)+.05)>=4.5:break
		colour=colour.darkened(.08) if Tokens.is_light() else colour.lightened(.08)
	return colour

static func _amount(value:float)->String:
	return str(int(round(value))) if absf(value-round(value))<.05 else "%.1f" % value

# --- Small drawn pieces -----------------------------------------------------

class Seal extends Control:
	## A wax-seal medallion with a kind glyph, drawn procedurally.
	var kind:="news"
	var tint:=Color.WHITE
	func _draw()->void:
		var c:=size*.5;var r:=minf(size.x,size.y)*.5-1
		draw_circle(c,r,tint.darkened(.25))
		draw_circle(c,r-3,tint)
		draw_arc(c,r-7,0,TAU,48,Color(1,1,1,.35),1.5,true)
		var ink:=Color("fbf3e2");var s:=r*.46
		match kind:
			"gift":
				draw_rect(Rect2(c+Vector2(-s,-s*.35),Vector2(s*2,s*1.35)),ink)
				draw_rect(Rect2(c+Vector2(-s*1.1,-s*.7),Vector2(s*2.2,s*.45)),ink)
				draw_line(c+Vector2(0,-s*.7),c+Vector2(0,s),tint.darkened(.3),3)
				draw_line(c+Vector2(0,-s*.7),c+Vector2(-s*.6,-s*1.25),ink,3);draw_line(c+Vector2(0,-s*.7),c+Vector2(s*.6,-s*1.25),ink,3)
			"threat":
				draw_line(c+Vector2(-s,-s),c+Vector2(s,s),ink,4);draw_line(c+Vector2(s,-s),c+Vector2(-s,s),ink,4)
				draw_line(c+Vector2(-s*.9,s*.35),c+Vector2(-s*.35,s*.9),ink,3);draw_line(c+Vector2(s*.9,s*.35),c+Vector2(s*.35,s*.9),ink,3)
			"proposal":
				# Two hands meeting: an offer between peoples.
				draw_line(c+Vector2(-s*1.1,s*.35),c+Vector2(-s*.15,-s*.1),ink,4)
				draw_line(c+Vector2(s*1.1,s*.35),c+Vector2(s*.15,-s*.1),ink,4)
				draw_circle(c+Vector2(0,-s*.1),s*.34,ink)
				draw_arc(c,s*1.05,PI*1.15,PI*1.85,16,ink,2,true)
			"request":
				draw_arc(c+Vector2(0,-s*.1),s,0,PI,24,ink,4,true)
				draw_line(c+Vector2(-s*1.15,-s*.1),c+Vector2(s*1.15,-s*.1),ink,3)
				draw_circle(c+Vector2(0,-s*.55),s*.28,ink)
			"report":
				draw_arc(c,s*1.05,0,TAU,32,ink,3,true)
				draw_colored_polygon(PackedVector2Array([c+Vector2(0,-s*.95),c+Vector2(s*.28,0),c+Vector2(0,s*.95),c+Vector2(-s*.28,0)]),ink)
				draw_circle(c,s*.16,tint.darkened(.3))
			"great_work":
				draw_rect(Rect2(c+Vector2(-s*1.05,s*.72),Vector2(s*2.1,s*.3)),ink)
				for i in 3:draw_rect(Rect2(c+Vector2(-s*.85+s*.7*i,-s*.55),Vector2(s*.28,s*1.3)),ink)
				draw_colored_polygon(PackedVector2Array([c+Vector2(-s*1.15,-s*.55),c+Vector2(s*1.15,-s*.55),c+Vector2(0,-s*1.15)]),ink)
			"wonder_proposal":
				for i in 8:
					var a:=TAU*float(i)/8.0
					draw_line(c,c+Vector2(cos(a),sin(a))*s*(1.1 if i%2==0 else .7),ink,3)
				draw_circle(c,s*.34,tint.darkened(.3));draw_circle(c,s*.22,ink)
			"news":
				draw_rect(Rect2(c+Vector2(-s*.85,-s),Vector2(s*1.7,s*2)),ink)
				for i in 3:draw_line(c+Vector2(-s*.55,-s*.5+i*s*.45),c+Vector2(s*.55,-s*.5+i*s*.45),tint.darkened(.3),2)
			_:
				draw_line(c+Vector2(-s*.8,s),c+Vector2(s*.8,-s),ink,4)
				draw_colored_polygon(PackedVector2Array([c+Vector2(s*.8,-s),c+Vector2(s*.1,-s*.65),c+Vector2(s*.45,-s*.15)]),ink)
				draw_line(c+Vector2(-s,s),c+Vector2(s*.2,s),ink,2)

class OddsGauge extends Control:
	## The court's reckoning as a shaded bar — never a number.
	var score:=.5
	var known:=true
	func _draw()->void:
		var bar:=Rect2(Vector2(0,size.y*.38),Vector2(size.x,size.y*.24))
		var steps:=30
		for i in steps:
			var t:=float(i)/float(steps-1)
			var colour:=HudTokens.RED.lerp(HudTokens.AMBER,t*2.0) if t<.5 else HudTokens.AMBER.lerp(HudTokens.GREEN,(t-.5)*2.0)
			colour.a=.8 if known else .25
			draw_rect(Rect2(bar.position+Vector2(bar.size.x*i/steps,0),Vector2(bar.size.x/steps+.5,bar.size.y)),colour)
		if known:
			var x:=clampf(score,0,1)*size.x
			draw_colored_polygon(PackedVector2Array([Vector2(x-6,0),Vector2(x+6,0),Vector2(x,bar.position.y)]),HudTokens.INK)
			draw_rect(Rect2(Vector2(clampf(x-2,0,size.x-4),bar.position.y-2),Vector2(4,bar.size.y+4)),HudTokens.INK)

class MoodMeter extends Control:
	var value:=0.0
	func _draw()->void:
		var bar:=Rect2(Vector2(0,size.y*.3),Vector2(size.x,size.y*.4))
		var steps:=24
		for i in steps:
			var t:=float(i)/float(steps-1)
			var colour:=HudTokens.RED.lerp(HudTokens.AMBER,t*2.0) if t<.5 else HudTokens.AMBER.lerp(HudTokens.GREEN,(t-.5)*2.0)
			colour.a=.55
			draw_rect(Rect2(bar.position+Vector2(bar.size.x*i/steps,0),Vector2(bar.size.x/steps+.5,bar.size.y)),colour)
		var x:=(value+1.0)*.5*size.x
		draw_rect(Rect2(Vector2(clampf(x-3,0,size.x-6),0),Vector2(6,size.y)),HudTokens.INK)
