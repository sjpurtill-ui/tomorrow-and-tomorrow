extends Control
## The Court: the one pausing screen for every dealing with the people who
## serve the god and the peoples beyond. At rest it shows the gathered court
## in its era's setting (fire circle, longhouse, hall), the antechamber of
## waiting envoys, and the foreign peoples one may send word to. Clicking a
## person summons them in place; envoys and petitioners speak, the court
## chimes in, and the ruler answers. Settlement leaders carry the civic
## directive conversation here, and foreign rulers are reached through the
## envoy channel (ForeignDialogue) in the same view.
## World state changes only through AudienceHall (engine), the civic pipeline
## and ForeignDialogue/ForeignDiplomacy; this file presents and routes.

signal closed(audience_id:String)

const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Roster:=preload("res://scripts/hud/court_roster.gd")
const Civic:=preload("res://scripts/hud/court_civic.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Commands:=preload("res://scripts/court_commands.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const Lives:=preload("res://scripts/court_lives.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
## Typed words that are about people (asked, summoned, questioned, accused or
## judged) go to the live persons exchange; offline the Court offers choices.
const PERSONS_WORDS:="(?i)\\b(who|whom|whose|summon|bring|fetch|send for|responsible|blame|fault|lying|liar|lie|lied|truth|swear|ledger|tally|confess|tell me (of|about)|where were you|mercy|pardon|exalt|maim|curse|marry|priest)\\b"

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
var regard_meter:Control
var regard_label:Label
var divine_row:HBoxContainer
## Offline, the Court's choices about people: ask, summon, question, confront, judge.
var persons_row:HBoxContainer
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

## "rest" (the court at rest), "audience" (someone stands before you) or
## "foreign" (word to a foreign ruler through your envoys).
var mode:="rest"
## Set before adding to the tree to open focused on someone (see focus()).
var start_focus:Dictionary={}
## True when the ruler brought this person in from the court: concluding
## returns to the court instead of closing it.
var from_court:=false
var backdrop:Control
var court_tier:=0
var return_button:Button
# Court at rest.
var scene_area:Control
var rest_seats:Dictionary={}      # roster key -> seat Control
var rest_signature:=[]
var _rest_clock:=0.0
# A settlement leader's civic conversation inside their audience.
var civic_settlement:=""
var civic_seen:Dictionary={}
var civic_strip:PanelContainer
var civic_state_label:Label
var civic_status_label:Label
var civic_replies:HBoxContainer
var civic_signature:=""
var _civic_clock:=0.0
# The envoy channel to a foreign ruler.
var foreign_civ:=""
var foreign_refs:Dictionary={}
var foreign_count:=-1
var _foreign_clock:=0.0

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
	court_tier=Backdrop.current_tier()
	if not audience_id.is_empty():show_audience(audience_id)
	elif not start_focus.is_empty():focus(start_focus)
	else:show_court()

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

func _reset_card(next_mode:String)->void:
	## Clear the stage for another view of the court.
	for tween in reveal_tweens:if tween and tween.is_valid():tween.kill()
	reveal_tweens.clear();revealing=false;rendered_lines=0;resolved_result={};bench_cards.clear()
	rest_seats.clear();foreign_refs.clear();rest_signature=[];foreign_count=-1
	civic_settlement="";civic_seen.clear();civic_signature=""
	civic_strip=null;civic_state_label=null;civic_status_label=null;civic_replies=null
	transcript=null;transcript_scroll=null;thinking=null;options_row=null;outcome_box=null;proposal_box=null
	speech_input=null;speak_button=null;wait_button=null;next_button=null;queue_label=null;return_button=null
	mood_meter=null;regard_meter=null;regard_label=null;divine_row=null;speaker_frame=null;scene_area=null;persons_row=null
	weigh_clock=-1.0
	mode=next_mode
	if next_mode!="audience":audience_id=""
	if next_mode!="foreign":foreign_civ=""
	for child in card.get_children():card.remove_child(child);child.queue_free()
	court_tier=Backdrop.current_tier()

func _add_backdrop(parent:Control)->Control:
	## The era's setting, drawn behind everything; subtle behind the veil.
	var scene:=Backdrop.new();scene.name="CourtScene"
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(scene)
	scene.configure(court_tier,not Tokens.is_light())
	backdrop=scene
	return scene

static func _plate(bg:Color,radius:int=0,pad:float=0.0)->StyleBoxFlat:
	## A raw box (no light-mode translation): dark plates must stay dark where
	## they sit on the painting.
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.set_corner_radius_all(radius);style.set_content_margin_all(pad)
	return style

func _compact()->bool:
	## Smaller screens: shorter portraits, smaller heralds, no dossier column.
	return is_inside_tree() and get_viewport().get_visible_rect().size.y<860.0

func _portrait_height()->float:
	return 150.0 if _compact() else 196.0

func _veil_style()->StyleBoxFlat:
	## The paper wash over the scene: enough to keep every word legible.
	var wash:=Tokens.PANEL_BG_SOLID;wash.a=.90 if Tokens.is_light() else .92
	return _plate(wash)

func show_audience(id:String)->void:
	var audience:=Hall.find(id)
	if audience.is_empty():
		if from_court and is_inside_tree():show_court()
		else:_close()
		return
	_reset_card("audience")
	audience_id=id
	var kind:=String(audience.get("kind","news"))
	accent=_kind_color(kind)
	speaker_person_id=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	envoy_color=_ink(Identity.banner_color(Identity.foreign(String(audience.get("civ_id",""))).texture)) if String(audience.get("origin",""))=="foreign" else _ink(Tokens.VIOLET)
	var style:=Tokens.flat(Tokens.PANEL_BG_SOLID,accent.darkened(.1),2,10,0)
	style.shadow_color=Color(0,0,0,.45);style.shadow_size=28
	card.add_theme_stylebox_override("panel",style)
	_add_backdrop(card)
	_civic_begin(audience)
	body=VBoxContainer.new();body.add_theme_constant_override("separation",0);card.add_child(body)
	body.add_child(_build_herald(audience))
	var veil:=PanelContainer.new();veil.name="Veil";veil.size_flags_vertical=Control.SIZE_EXPAND_FILL
	veil.add_theme_stylebox_override("panel",_veil_style());body.add_child(veil)
	var inner:=MarginContainer.new();inner.size_flags_vertical=Control.SIZE_EXPAND_FILL
	for side in ["left","right"]:inner.add_theme_constant_override("margin_"+side,20)
	inner.add_theme_constant_override("margin_top",14);inner.add_theme_constant_override("margin_bottom",12)
	veil.add_child(inner)
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
	persons_row=HBoxContainer.new();persons_row.name="PersonsRow";persons_row.add_theme_constant_override("separation",6);column.add_child(persons_row)
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
	banner.add_theme_stylebox_override("panel",_herald_style())
	var layers:=VBoxContainer.new();layers.add_theme_constant_override("separation",10);banner.add_child(layers)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);layers.add_child(row)
	# The court sits in the scene at the right of the herald band, watching.
	var seats:=_build_seats(audience)
	banner.set_meta("seats",seats)
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
	var title:=Tokens.make_label(herald_text,24 if _compact() else 30,cream);title.name="HeraldTitle"
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
	row.add_child(seats)
	return banner

func _herald_style()->StyleBoxFlat:
	## The herald band is a dark wash over the scene: the setting shows through,
	## the cream lettering stays legible in both themes.
	var shade:=accent.darkened(.55) if Tokens.is_light() else accent.darkened(.72)
	shade.a=.76
	var style:=_plate(shade)
	style.corner_radius_top_left=9;style.corner_radius_top_right=9
	style.border_color=accent.lightened(.25);style.border_width_bottom=3
	style.content_margin_left=20;style.content_margin_right=20;style.content_margin_top=14;style.content_margin_bottom=12
	return style

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
	if not civic_settlement.is_empty():center.add_child(_build_civic_strip())
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
	if not civic_settlement.is_empty():_add_civic_record()
	return stage

func _build_speaker(audience:Dictionary)->Control:
	var speaker:Dictionary=audience.get("speaker",{})
	var origin:=String(audience.get("origin","foreign"))
	var column:=VBoxContainer.new();column.name="Speaker";column.custom_minimum_size.x=236;column.add_theme_constant_override("separation",8)
	speaker_frame=PanelContainer.new();speaker_frame.name="SpeakerFrame"
	var frame_style:=Tokens.flat(Color("eee7d8"),envoy_color,2,8,6)
	speaker_frame.add_theme_stylebox_override("panel",frame_style);column.add_child(speaker_frame)
	var holder:=Control.new();holder.custom_minimum_size=Vector2(222,_portrait_height());holder.clip_contents=true;speaker_frame.add_child(holder)
	var person:=_speaker_person(audience)
	var portrait:=Portrait.picture(person,222,_portrait_height());portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);holder.add_child(portrait)
	if origin=="foreign":
		var flag:=TextureRect.new();flag.texture=Identity.foreign(String(audience.get("civ_id",""))).texture
		flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;flag.mouse_filter=Control.MOUSE_FILTER_IGNORE
		flag.position=Vector2(166,6);flag.size=Vector2(50,50);holder.add_child(flag)
	# Love and dread sit on the portrait itself, so the stage keeps its height.
	holder.add_child(_build_regard(audience))
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
	var dossier:=_build_dossier(audience) if not _compact() else null
	if dossier:column.add_child(dossier)
	return column

func _build_regard(audience:Dictionary)->Control:
	## Love and dread: how the summoned person holds their god, or how the
	## envoy's people regard you. Two gauges and one plain line.
	var strip:=PanelContainer.new();strip.name="Regard";strip.mouse_filter=Control.MOUSE_FILTER_PASS
	var strip_style:=StyleBoxFlat.new();strip_style.bg_color=Color(.06,.05,.04,.8)   # dark in both themes: it sits on the picture
	strip_style.content_margin_left=8;strip_style.content_margin_right=8;strip_style.content_margin_top=4;strip_style.content_margin_bottom=4
	strip.add_theme_stylebox_override("panel",strip_style)
	strip.position=Vector2(0,_portrait_height()-52);strip.size=Vector2(222,52)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",1);box.mouse_filter=Control.MOUSE_FILTER_IGNORE;strip.add_child(box)
	regard_meter=RegardMeter.new();regard_meter.name="RegardMeter";regard_meter.custom_minimum_size=Vector2(206,24);regard_meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(regard_meter)
	regard_label=Tokens.make_label("",12,Color("f6ecd6"));regard_label.name="RegardRead";regard_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	regard_label.clip_text=true;regard_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;box.add_child(regard_label)
	_refresh_regard()
	strip.visible=not Hall.regard_of(String(audience.get("id",""))).is_empty()
	return strip

func _refresh_regard()->void:
	if not is_instance_valid(regard_meter):return
	var regard:=Hall.regard_of(audience_id)
	if regard.is_empty():return
	var audience:=Hall.find(audience_id)
	var foreign:=String(audience.get("origin",""))=="foreign"
	regard_meter.love=float(regard.get("love",0.0));regard_meter.dread=float(regard.get("dread",0.0))
	regard_meter.love_word="REVERENCE" if foreign else "LOVE"
	regard_meter.queue_redraw()
	var who:=String(regard.get("name","")) if foreign else String((audience.get("speaker",{}) as Dictionary).get("name","")).get_slice(" ",0)
	regard_label.text=("%s %s" % [who,String(regard.get("read",""))]).strip_edges()
	var risky:=String(regard.get("id","")) in ["hates_dread","terror","fear","war"]
	regard_label.add_theme_color_override("font_color",Color("f0a08e") if risky else Color("f6ecd6"))
	var strip:=regard_label.get_parent().get_parent() as Control
	strip.tooltip_text=regard_label.text+". "
	strip.tooltip_text+="From their opinion of you, their ruler's trust, border tension and remembered terror." if foreign else "Dread buys obedience and costs honesty; love buys candour. Dread soured by resentment shows first in their words, then in their work, and at last in flight."

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
	if String(speaker.get("known_id",""))!="":
		# A summoned commoner: their own lasting look, drawn from their name.
		var known:=Persons.by_id(String(speaker.known_id))
		return {"name":String(known.get("name",speaker.get("name",""))),"person_id":0,"office_title":String(speaker.get("title","")),"sex":String(known.get("sex",""))}
	var person_id:=int(speaker.get("person_id",0))
	if person_id>0:
		var snapshot:Dictionary=GovernmentPeopleSystem.person_snapshot(person_id)
		if not snapshot.is_empty():return snapshot
	# A transient envoy record: bound to the civ's appearance family, never saved.
	var envoy:={"name":String(speaker.get("name","Envoy")),"person_id":0}
	var civ_id:=String(audience.get("civ_id",""))
	if not civ_id.is_empty():EarlyArt.bind_foreign_identity(envoy,civ_id,int(GameState.world_seed))
	return envoy

func _build_seats(audience:Dictionary)->Control:
	## The court seated in the scene: small portraits on the herald band, the
	## one who speaks lit in gold. They keep the room's witnesses in view
	## without taking width from the conversation.
	var column:=VBoxContainer.new();column.name="CourtBench";column.add_theme_constant_override("separation",4);column.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	column.tooltip_text="Your court looks on.";column.mouse_filter=Control.MOUSE_FILTER_PASS
	var benches:=HBoxContainer.new();benches.add_theme_constant_override("separation",6);column.add_child(benches)
	var court:Array=Hall.court(String(audience.get("id","")))
	if court.is_empty():
		var alone:=Tokens.make_label("No officials attend.\nYou receive them alone.",12,Color("e2d3b4"));alone.add_theme_font_override("font",_italic);benches.add_child(alone)
	for person:Dictionary in court:
		var person_id:=int(person.get("person_id",0))
		var seat:=PanelContainer.new();seat.name="Seat%d" % person_id
		seat.add_theme_stylebox_override("panel",_seat_style(person_id,false))
		seat.mouse_filter=Control.MOUSE_FILTER_PASS
		var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",2);stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;seat.add_child(stack)
		var face_frame:=PanelContainer.new();face_frame.add_theme_stylebox_override("panel",Tokens.flat(Color("eee7d8"),Color(0,0,0,0),0,3,1));face_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(face_frame)
		face_frame.add_child(Portrait.picture(person,48,52))
		var first:=String(person.get("name","Official")).get_slice(" ",0)
		var who:=Tokens.make_label(first,11,Color("f6ecd6"));who.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;who.clip_text=true;who.custom_minimum_size.x=50;who.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(who)
		seat.tooltip_text="%s · %s" % [String(person.get("name","")),String(person.get("office_title",""))]
		benches.add_child(seat);bench_cards[person_id]=seat
	return column

func _seat_style(person_id:int,speaking:bool)->StyleBoxFlat:
	var style:=_plate(Color(.95,.78,.36,.30) if speaking else Color(0,0,0,.22),4,0)
	style.border_color=Color("e8c35a") if speaking else _person_color(person_id).lightened(.25)
	style.border_width_bottom=3
	if speaking:style.set_border_width_all(2);style.border_width_bottom=3
	style.content_margin_left=3;style.content_margin_right=3;style.content_margin_top=3;style.content_margin_bottom=3
	return style

func _build_speech_row()->Control:
	var row:=HBoxContainer.new();row.name="SpeechRow";row.add_theme_constant_override("separation",8)
	speech_input=LineEdit.new();speech_input.name="SpeechInput";speech_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	speech_input.custom_minimum_size.y=42;speech_input.max_length=400;speech_input.add_theme_font_size_override("font_size",16)
	var audience:=Hall.find(audience_id)
	speech_input.placeholder_text="Speak to the envoy…" if String(audience.get("origin",""))=="foreign" else "Speak to %s…" % String((audience.get("speaker",{}) as Dictionary).get("name","them"))
	if not civic_settlement.is_empty():
		speech_input.placeholder_text="Speak to %s: ask a question, or give an order for %s…" % [String((audience.get("speaker",{}) as Dictionary).get("name","them")).get_slice(" ",0),Civic.settlement_name(civic_settlement)]
	speech_input.add_theme_stylebox_override("read_only",Tokens.flat(Tokens.TILE_BG,Tokens.BORDER_SOFT,1,3,8))
	speech_input.text_submitted.connect(func(_t:String):_speak())
	row.add_child(speech_input)
	speak_button=Button.new();speak_button.name="Speak";speak_button.text="SPEAK";speak_button.custom_minimum_size=Vector2(110,42)
	speak_button.add_theme_font_size_override("font_size",15);speak_button.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
	speak_button.pressed.connect(_speak);row.add_child(speak_button)
	divine_row=HBoxContainer.new();divine_row.name="DivineRow";divine_row.add_theme_constant_override("separation",6);row.add_child(divine_row)
	return row

func _build_options()->void:
	for child in options_row.get_children():child.queue_free()
	options_row.visible=true;outcome_box.visible=false
	var listed:=Hall.options(audience_id)
	_option_count=listed.size()
	for option:Dictionary in listed:
		options_row.add_child(_option_card(option))
	_build_divine_row()
	_build_persons_row()

const PERSONS_GROUPS:=[["ask","ASK ▾"],["summon","SUMMON ▾"],["question","QUESTION ▾"],["confront","CONFRONT ▾"],["judge","JUDGE ▾"]]

func _persons_live()->bool:
	return _voice_ok() and voice.has_method("is_live") and bool(voice.is_live()) and voice.has_method("persons_turn")

func persons_choices()->Array[Dictionary]:
	## What the Court offers about people at this step (from real state).
	return Persons.choices(audience_id if mode=="audience" else "")

func _build_persons_row()->void:
	## Offline there is no free-text parsing about people: the Court shows the
	## choices that exist now, grouped as the steps of an inquiry.
	if not is_instance_valid(persons_row):return
	for child in persons_row.get_children():child.queue_free()
	var audience:=Hall.find(audience_id)
	persons_row.visible=not _persons_live() and resolved_result.is_empty() and String(audience.get("origin",""))=="court" and String(audience.get("status",""))=="waiting"
	if not persons_row.visible:return
	_fill_persons_menus(persons_row,persons_choices())

func _fill_persons_menus(row:HBoxContainer,all:Array[Dictionary])->void:
	for pair in PERSONS_GROUPS:
		var items:Array[Dictionary]=[]
		for c in all:
			if String(c.get("group",""))==String(pair[0]):items.append(c)
		if items.is_empty():continue
		var menu:=MenuButton.new();menu.name="Persons_"+String(pair[0]);menu.text=String(pair[1]);menu.flat=false
		_divine_style(menu,Tokens.GOLD if String(pair[0]) in ["ask","summon","question"] else Tokens.RED)
		var popup:=menu.get_popup()
		for index in items.size():popup.add_item(String(items[index].label),index)
		menu.set_meta("choices",items)
		popup.id_pressed.connect(func(item:int):persons_choose(items[item]))
		row.add_child(menu)

func persons_choose(choice:Dictionary)->Dictionary:
	## One step of an inquiry, chosen from the Court's choices (or by a test).
	## The same core decides and applies it as the live path does.
	var action:=String(choice.get("action",""))
	var params:Dictionary=choice.get("params",{}) if choice.get("params") is Dictionary else {}
	if action=="command":
		if mode!="audience":return {}
		var heard:=Commands.hear(audience_id,String(params.get("command_text","")),{"terrain":terrain,"civic_settlement":civic_settlement})
		if bool(heard.get("handled",false)):_after_command(heard)
		return heard
	if mode!="audience" or audience_id.is_empty() or not resolved_result.is_empty():
		if action=="summon":
			var made:=Persons.summon_ref(params.get("ref",{}) as Dictionary,"")
			if made.is_empty():
				_court_note("They cannot be brought before you now.");return {}
			from_court=true
			show_audience(String(made.id))
			return {"ok":true,"summon_audience_id":String(made.id)}
		# Someone must answer: the fitting official comes forward.
		var answerer:=Persons.answerer_for(Persons.event_by_key(String(params.get("event","")),""),"") if action=="ask_blame" else Persons.answerer_for_desc(params.get("desc",{}) as Dictionary)
		if answerer.is_empty():
			_court_note("No one is at court to answer you yet.");return {}
		if not summon({"person_id":int(answerer.person_id)}):return {}
	var result:=Persons.perform(audience_id,action,params,{"echo":String(choice.get("label",""))})
	_after_persons(result)
	return result

func _after_persons(result:Dictionary)->void:
	var next_id:=String(result.get("summon_audience_id",""))
	if next_id!="" and next_id!=audience_id:
		if mode=="audience" and resolved_result.is_empty() and not audience_id.is_empty():Hall.defer(audience_id)
		from_court=true
		show_audience(next_id)
		return
	if mode!="audience":return
	_refresh_regard()
	var audience:=Hall.find(audience_id)
	_update_mood(audience)
	if String(audience.get("status","waiting"))!="waiting":
		_show_outcome({"ok":true,"outcome":String(result.get("outcome","")),"reaction":"furious" if String(result.get("action","")) in ["execute","exile"] else "neutral","terminal":true})
	else:
		_build_options()
		if not String(result.get("outcome","")).is_empty():_show_toast(String(result.outcome))
	_pump()

func _on_persons_done(id:String,result:Dictionary)->void:
	if id==audience_id:_after_persons(result)

func _build_divine_row()->void:
	## The god's wrath and favour live beside SPEAK: two menus for a summoned
	## official, one TERRIFY for an envoy. They add no height to the stage.
	if not is_instance_valid(divine_row):return
	for child in divine_row.get_children():child.queue_free()
	var acts:=Hall.divine_options(audience_id)
	divine_row.visible=not acts.is_empty() and resolved_result.is_empty()
	if acts.is_empty():return
	if String(Hall.find(audience_id).get("origin",""))=="foreign":
		var act:Dictionary=acts[0]
		var button:=Button.new();button.name="Divine_terrify";button.text="TERRIFY"
		_divine_style(button,Tokens.RED)
		button.disabled=not bool(act.get("enabled",true))
		button.tooltip_text=String(act.get("sub","")) if not button.disabled else String(act.get("reason",""))
		button.pressed.connect(func():divine("terrify"))
		divine_row.add_child(button)
		return
	for tone in ["wrath","favor"]:
		var menu:=MenuButton.new();menu.name="Divine_"+tone;menu.text="WRATH ▾" if tone=="wrath" else "FAVOUR ▾"
		menu.flat=false
		_divine_style(menu,Tokens.RED if tone=="wrath" else Tokens.GOLD)
		menu.tooltip_text="Your anger: terror, penance, exile, death." if tone=="wrath" else "Your favour: blessing, a gift from the stores, honour."
		var popup:=menu.get_popup()
		var ids:Array[String]=[]
		for act:Dictionary in acts:
			if String(act.get("tone",""))!=tone:continue
			popup.add_item(String(act.label),ids.size())
			var index:=popup.get_item_index(ids.size())
			popup.set_item_disabled(index,not bool(act.get("enabled",true)))
			popup.set_item_tooltip(index,String(act.get("sub","")) if bool(act.get("enabled",true)) else String(act.get("reason","")))
			ids.append(String(act.id))
		menu.set_meta("actions",ids)
		popup.id_pressed.connect(func(item:int):divine(String(ids[item])))
		divine_row.add_child(menu)

func _divine_style(button:Button,ink:Color)->void:
	button.custom_minimum_size=Vector2(104,42);button.add_theme_font_size_override("font_size",14);button.focus_mode=Control.FOCUS_ALL
	var style:=Tokens.flat(ink.lerp(Tokens.PANEL_BG_SOLID,.84),ink,1,6,0);style.content_margin_left=10;style.content_margin_right=10
	var hover:=style.duplicate() as StyleBoxFlat;hover.bg_color=ink.lerp(Tokens.PANEL_BG_SOLID,.68)
	for state in ["normal","focus"]:button.add_theme_stylebox_override(state,style)
	button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover)
	button.add_theme_stylebox_override("disabled",Tokens.flat(Tokens.TILE_BG,Tokens.BORDER_SOFT,1,6,0))
	button.add_theme_color_override("font_color",ink.lightened(.15) if not Tokens.is_light() else ink.darkened(.2))

func divine(action:String,words:String="",voice_reacts:bool=true)->Dictionary:
	## Wrath or favour, validated and applied by the hall; the room reacts.
	if not resolved_result.is_empty():return resolved_result
	var result:=Hall.divine(audience_id,action,words)
	if not bool(result.get("ok",false)):
		_show_toast(String(result.get("outcome","That cannot be done.")))
		return result
	if voice_reacts and _voice_ok() and voice.has_method("divine_reaction"):voice.divine_reaction(audience_id,result)
	_refresh_regard()
	_update_mood(Hall.find(audience_id))
	if bool(result.get("terminal",false)):_show_outcome(result)
	else:_build_options()
	_pump()
	return result

func _on_divine_intent(id:String,action:String)->void:
	## The live voice heard a spoken act of wrath or favour; the hall decides.
	if id!=audience_id or not resolved_result.is_empty():return
	divine(action,"",false)

var _option_count:=0
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
	# Who at court objects to this answer, or speaks for it (rival_rulers.gd).
	# One voice shows on the card (the objection first); both are in the tooltip.
	# Cards keep their height: the voice takes the second line of the terms.
	if _option_count>=4:
		title.max_lines_visible=1;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var shown:=false
	for side in ["objection","support"]:
		var said:=String(option.get(side,""))
		if said.is_empty() or not enabled:continue
		var words:=("Objects · " if side=="objection" else "For it · ")+said
		button.tooltip_text+="\n"+words
		if shown:continue
		shown=true;sub.max_lines_visible=1
		var voice:=Tokens.make_label(words,12,Tokens.RED if side=="objection" else Tokens.GREEN)
		voice.name="Option"+side.capitalize();voice.mouse_filter=Control.MOUSE_FILTER_IGNORE;voice.add_theme_font_override("font",_italic)
		voice.clip_text=true;voice.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		stack.add_child(voice)
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
	row.add_child(_build_return_button())
	wait_button=Button.new();wait_button.name="MakeThemWait";wait_button.text="Make them wait";wait_button.custom_minimum_size=Vector2(150,34)
	wait_button.tooltip_text="Send them to the antechamber. Guests kept waiting too long leave insulted."
	wait_button.pressed.connect(make_them_wait);row.add_child(wait_button)
	_add_court_controls(row,"Receive envoys at once")
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
	if voice.has_signal("divine_intent") and not voice.divine_intent.is_connected(_on_divine_intent):voice.divine_intent.connect(_on_divine_intent)
	if "command_router" in voice:voice.command_router=_route_live_command
	if voice.has_signal("persons_done") and not voice.persons_done.is_connected(_on_persons_done):voice.persons_done.connect(_on_persons_done)

func _on_lines_ready(id:String)->void:
	if id==audience_id:_pump()

func _speak()->void:
	if not is_instance_valid(speech_input):return
	var text:=speech_input.text.strip_edges()
	if text.is_empty() or (is_instance_valid(speak_button) and speak_button.disabled):return
	if mode=="rest":
		speech_input.clear()
		speak_to_court(text)
		return
	if mode=="foreign":
		send_envoy_brief(text)
		return
	speech_input.clear()
	# Naming a successor at a mourning ("Let Iska keep the fire") chooses them.
	if resolved_result.is_empty():
		var named:=String(Lives.typed_choice(audience_id,text))
		if not named.is_empty():
			Hall.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text,"day":int(GameState.elapsed_days),"aside":false})
			choose(named)
			_pump()
			return
	# Words about people, with a live voice: one call maps them onto the
	# persons engine's actions (ask, summon, question, accuse, judge).
	if resolved_result.is_empty() and _persons_live() and String(Hall.find(audience_id).get("origin",""))=="court" and not voice.busy(audience_id):
		var about_people:=not Persons.speaker_known(audience_id).is_empty()
		if not about_people:
			var re:=RegEx.new();re.compile(PERSONS_WORDS)
			about_people=re.search(text)!=null
		if about_people:
			voice.persons_turn(audience_id,text)
			_pump()
			return
	# The god's word is law: an order (to the one before you, to anyone at
	# court, or to the guards) is decided and carried out by the engine first;
	# the court then reacts to what actually happened.
	var live_reads:=false
	if resolved_result.is_empty():
		# A general order with a live voice: let the live classifier read it
		# more exactly first ("see that she never draws breath again").
		var reading:=Commands.classify(text)
		live_reads=String(reading.get("verb",""))=="order" and _voice_ok() and voice.has_method("is_live") and bool(voice.is_live()) and "command_router" in voice and civic_settlement.is_empty()
	if resolved_result.is_empty() and not live_reads:
		var heard:=Commands.hear(audience_id,text,{"terrain":terrain,"civic_settlement":civic_settlement})
		if bool(heard.get("handled",false)):
			_after_command(heard)
			return
	# A settlement leader's civic conversation: plain words (not questions)
	# go through the civic pipeline, which answers, objects or refuses.
	if not civic_settlement.is_empty() and resolved_result.is_empty() and not text.ends_with("?") and Hall.divine_intent(audience_id,text).is_empty():
		_civic_say(text)
		return
	# Words that are themselves an act of the god (terror, penance, blessing,
	# exaltation) are carried out; the room reacts to the act.
	var spoken_act:=Hall.divine_intent(audience_id,text)
	if not spoken_act.is_empty():
		Hall.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text,"day":int(GameState.elapsed_days),"aside":false})
		divine(spoken_act,text)
		return
	var before:=(Hall.find(audience_id).get("lines",[]) as Array).size()
	if live_reads:
		voice.player_speaks(audience_id,text,true)
		_pump()
		return
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

## The live voice read the ruler's words as an order the offline reading
## missed; the engine decides and acts, and the voice reacts to that.
func _route_live_command(id:String,text:String,command:Dictionary)->bool:
	if id!=audience_id or not resolved_result.is_empty():return false
	var heard:=Commands.hear(id,text,{"terrain":terrain,"civic_settlement":civic_settlement,"live":command,"echoed":true})
	if not bool(heard.get("handled",false)):return false
	_after_command(heard)
	return true

## Shows a command's result: the voice stages it (a bracketed direction, the
## actor's answer as decided, a witness), then the outcome line and receipt.
func _after_command(result:Dictionary)->void:
	if _voice_ok() and voice.has_method("command_reaction"):voice.command_reaction(audience_id,result)
	elif not String(result.get("outcome","")).is_empty():
		Hall.append_line(audience_id,{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":String(result.outcome),"day":int(GameState.elapsed_days),"aside":false})
	_refresh_regard()
	var audience:=Hall.find(audience_id)
	_update_mood(audience)
	if bool(result.get("terminal",false)) or String(audience.get("status","waiting"))!="waiting":
		var shown:=result.duplicate()
		shown["terminal"]=true
		_show_outcome(shown)
	else:
		_build_options()
		if not String(result.get("outcome","")).is_empty():_show_toast(String(result.outcome))
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
	if is_instance_valid(divine_row):divine_row.visible=false
	if is_instance_valid(persons_row):persons_row.visible=false
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
	var head_text:="THE AUDIENCE IS CONCLUDED · "+who+String(REACTION_WORDS.get(reaction,"UNMOVED"))
	if bool(result.get("terminal",false)):head_text="THE AUDIENCE IS CONCLUDED · BY YOUR DECREE"
	var head:=Tokens.make_label(head_text,13,colour,.08);head.name="ReceiptHead";words.add_child(head)
	var outcome:=Tokens.make_label(String(result.get("outcome","")),15,Tokens.BODY);outcome.name="ReceiptText";outcome.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(outcome)
	var dismiss:=Button.new();dismiss.name="Dismiss";dismiss.text="Return to the court" if from_court else "Dismiss the court";dismiss.custom_minimum_size=Vector2(190,46)
	dismiss.add_theme_font_size_override("font_size",16);dismiss.add_theme_stylebox_override("normal",Tokens.gold_outline_style());dismiss.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	dismiss.pressed.connect(func()->void:
		if from_court:show_court()
		else:_close())
	row.add_child(dismiss)
	if conceive_next:
		var visions:=Button.new();visions.name="HearVisions";visions.text="Hear the court's visions ›";visions.custom_minimum_size=Vector2(220,46)
		visions.add_theme_font_size_override("font_size",16);visions.add_theme_stylebox_override("normal",Tokens.gold_outline_style());visions.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		visions.pressed.connect(open_conception);row.add_child(visions)
	outcome_box.add_child(receipt)
	_refresh_footer()

func make_them_wait()->void:
	if mode=="audience" and resolved_result.is_empty():Hall.defer(audience_id)
	if from_court and mode!="rest":show_court()
	else:_close()

func return_to_court()->void:
	## Back to the court at rest; an unconcluded audience waits its turn.
	if mode=="audience" and resolved_result.is_empty():Hall.defer(audience_id)
	from_court=true
	show_court()

func _build_return_button()->Button:
	return_button=Button.new();return_button.name="ReturnToCourt";return_button.text="‹ The court"
	return_button.custom_minimum_size=Vector2(118,34);return_button.focus_mode=Control.FOCUS_NONE
	return_button.tooltip_text="Back to the whole court. Anyone you leave standing waits their turn."
	return_button.pressed.connect(return_to_court)
	return return_button

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
	if mode!="audience":
		_refresh_voice_indicator()
		return
	if not is_instance_valid(queue_label):return
	var others:=0
	for audience:Dictionary in Hall.waiting():
		if String(audience.get("id",""))!=audience_id:others+=1
	queue_label.text="" if others==0 else ("1 more waits" if others==1 else "%d more wait" % others)
	queue_label.tooltip_text="" if others==0 else "Waiting in the antechamber."
	next_button.visible=others>0
	wait_button.visible=resolved_result.is_empty()
	var open:=resolved_result.is_empty()
	if speech_input.editable!=open:
		speech_input.editable=open
		if not open:speech_input.placeholder_text="The audience is concluded. They are taking their leave."
	speak_button.disabled=not open or (_voice_ok() and voice.busy(audience_id))
	_refresh_voice_indicator()

func _show_toast(text:String)->void:
	if not is_instance_valid(transcript):
		_court_note(text);return
	var note:=Tokens.make_label(text,13,Tokens.RED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	transcript.add_child(note)

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if mode=="rest":_close()
		elif mode=="foreign":
			if from_court:show_court()
			else:_close()
		elif resolved_result.is_empty():make_them_wait()
		elif from_court:show_court()
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
	if mode=="rest":
		_rest_clock-=delta
		if _rest_clock<=0.0:
			_rest_clock=.5
			if _rest_state()!=rest_signature:show_court()
			else:_refresh_voice_indicator()
		return
	if mode=="foreign":
		_foreign_clock-=delta
		if _foreign_clock<=0.0:
			_foreign_clock=.5
			_refresh_foreign()
		return
	if audience_id.is_empty():return
	_civic_clock-=delta
	if _civic_clock<=0.0 and not civic_settlement.is_empty():
		_civic_clock=.25
		_sync_civic()
	_pump()
	if not pending_words.is_empty():_deliver_pending_words()
	if mode!="audience":return
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
	if role=="narrator" and String(line.get("text","")).begins_with("["):
		# A stage direction: what physically happens in the hall, set apart.
		var stage_box:=PanelContainer.new();stage_box.name="StageLine"
		var stage_style:=Tokens.flat(Tokens.TILE_BG,Tokens.RED.lerp(Tokens.BORDER_SOFT,.35),0,4,0);stage_style.border_width_left=3
		stage_style.content_margin_left=14;stage_style.content_margin_right=14;stage_style.content_margin_top=6;stage_style.content_margin_bottom=6
		stage_box.add_theme_stylebox_override("panel",stage_style)
		var staged:=Tokens.make_label(String(line.get("text","")),15,Tokens.BODY);staged.add_theme_font_override("font",_italic)
		staged.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;staged.name="StageText";stage_box.add_child(staged)
		transcript.add_child(stage_box)
		_reveal(stage_box,staged,animate);return
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

# --- Footer controls shared by every view -----------------------------------

func _add_court_controls(row:HBoxContainer,summon_words:String="Summon me at once when envoys arrive")->void:
	summon_check=CheckBox.new();summon_check.name="SummonImmediately";summon_check.text=summon_words
	summon_check.add_theme_font_size_override("font_size",13)
	summon_check.tooltip_text="When an envoy arrives, open the court at once. Otherwise they wait in the antechamber."
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

func _footer_bar()->PanelContainer:
	var bar:=PanelContainer.new();bar.name="Footer"
	var bar_style:=Tokens.flat(Tokens.TILE_BG,Color(0,0,0,0),0,0,0)
	bar_style.corner_radius_bottom_left=9;bar_style.corner_radius_bottom_right=9;bar_style.border_color=Tokens.BORDER_SOFT;bar_style.border_width_top=1
	bar_style.content_margin_left=20;bar_style.content_margin_right=20;bar_style.content_margin_top=8;bar_style.content_margin_bottom=8
	bar.add_theme_stylebox_override("panel",bar_style)
	return bar

# --- The court: focus and summons ---------------------------------------------

## Opens the court on someone. {person_id} / {figure_id} / {role:"chief_scout"}
## summon them; {settlement_id} summons that settlement's leader; {civ_id}
## opens word to that people's ruler; {audience_id} receives a waiting visitor.
func focus(target:Dictionary)->bool:
	if target.is_empty():
		show_court();return true
	if target.has("audience_id"):
		if receive(String(target.audience_id)):return true
		show_court();return false
	if target.has("civ_id"):return show_foreign(String(target.civ_id))
	if target.has("settlement_id"):
		var leader:=GovernmentPeopleSystem.settlement_leader(String(target.settlement_id))
		if leader.is_empty():
			show_court();_court_note("No one leads that settlement just now; government will appoint someone.")
			return false
		return summon({"person_id":int(leader.person_id)})
	return summon(target)

## Calls someone before you, here and now.
func summon(target:Dictionary)->bool:
	if mode=="audience" and resolved_result.is_empty() and not audience_id.is_empty():Hall.defer(audience_id)
	var made:=Persons.summon_ref({"kind":"known","id":String(target.known_id)},audience_id) if String(target.get("known_id",""))!="" else Hall.summon(target)
	if made.is_empty():
		if mode!="rest":show_court()
		_court_note("They cannot be brought before you now.")
		return false
	from_court=true
	show_audience(String(made.id))
	return true

## Receives someone already waiting (an envoy, or a person set aside).
func receive(id:String)->bool:
	var audience:=Hall.find(id)
	if audience.is_empty() or String(audience.get("status",""))!="waiting":return false
	if mode=="audience" and resolved_result.is_empty() and not audience_id.is_empty() and audience_id!=id:Hall.defer(audience_id)
	from_court=true
	show_audience(id)
	return true

func _court_note(text:String)->void:
	var note:=find_child("CourtNote",true,false) as Label
	if note!=null:note.text=text

# --- The court at rest ---------------------------------------------------------

const ROSTER_ORDER:={"council":0,"settlement":1,"scouts":2,"builders":3,"generals":4,"folk":5}
const MAX_SEATED:=7
var pending_words:=""

func show_court()->void:
	## The whole court gathered in its setting, nobody yet before you.
	_reset_card("rest")
	from_court=true
	accent=Tokens.GOLD
	var style:=Tokens.flat(Tokens.PANEL_BG_SOLID,Tokens.GOLD.darkened(.1),2,10,0)
	style.shadow_color=Color(0,0,0,.45);style.shadow_size=28
	card.add_theme_stylebox_override("panel",style)
	body=VBoxContainer.new();body.name="CourtAtRest";body.add_theme_constant_override("separation",0);card.add_child(body)
	var roster:=Roster.people()
	body.add_child(_build_rest_scene(roster))
	var lower:=MarginContainer.new();lower.size_flags_vertical=Control.SIZE_EXPAND_FILL
	for side in ["left","right"]:lower.add_theme_constant_override("margin_"+side,18)
	lower.add_theme_constant_override("margin_top",12);lower.add_theme_constant_override("margin_bottom",10)
	body.add_child(lower)
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",16);lower.add_child(columns)
	columns.add_child(_rest_column("CourtRoster","THE COURT","Send for anyone; they come at once.",_build_roster_list(roster),1.45))
	columns.add_child(_rest_column("Antechamber","THE ANTECHAMBER","Only foreign envoys come unbidden.",_build_antechamber(),1.0))
	columns.add_child(_rest_column("ForeignPeoples","SEND WORD ABROAD","Your envoys carry your brief to their rulers.",_build_foreign_list(),1.0))
	body.add_child(_build_rest_footer())
	rest_signature=_rest_state()
	_fit()
	_layout_rest_seats.call_deferred()

func _rest_state()->Array:
	## What the court at rest shows; it redraws only when this changes.
	return [Hall.waiting().size(),Hall.matter_counts().hash(),Roster.people().size(),Roster.foreign_peoples().size(),int(GameState.elapsed_days),
		GovernmentPeopleSystem.revision,AdvisorSystem.council_decision_items(3,false).size(),Tokens.color_mode,ForeignDialogue.pending.size(),Backdrop.current_tier()]

func _rest_scene_height()->float:
	var view:=get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1920,1080)
	var card_h:=minf(DESIGN_SIZE.y,view.y-40)
	return clampf(card_h*.44,200.0,370.0)

func _build_rest_scene(roster:Array[Dictionary])->Control:
	scene_area=Control.new();scene_area.name="CourtSceneArea";scene_area.clip_contents=true
	scene_area.custom_minimum_size=Vector2(0,_rest_scene_height())
	_add_backdrop(scene_area)
	# The header sits on a dark wash across the top of the painting.
	var head:=PanelContainer.new();head.name="CourtHeader"
	var head_style:=_plate(Color(.06,.045,.03,.66),0,0)
	head_style.corner_radius_top_left=9;head_style.corner_radius_top_right=9
	head_style.content_margin_left=20;head_style.content_margin_right=16;head_style.content_margin_top=10;head_style.content_margin_bottom=10
	head.add_theme_stylebox_override("panel",head_style)
	head.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	scene_area.add_child(head);scene_area.set_meta("header",head)
	head.resized.connect(_layout_rest_seats)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",18);head.add_child(row)
	var seal:=Seal.new();seal.kind="petition";seal.tint=Color("b98a2e");seal.custom_minimum_size=Vector2(46,46);seal.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(seal)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",0);row.add_child(words)
	var day:=int(GameState.elapsed_days)
	words.add_child(Tokens.make_label("YOUR COURT · YEAR %d, DAY %d" % [day/365+1,day%365+1],11,Color("e2d3b4"),.12))
	var title:=Tokens.make_label(Backdrop.place_name(court_tier),28,Color("f6ecd6"));title.name="CourtTitle";title.add_theme_font_override("font",_bold);words.add_child(title)
	var line:=Tokens.make_label(Backdrop.place_line(court_tier).capitalize().substr(0,1)+Backdrop.place_line(court_tier).substr(1),13,Color("e2d3b4"));line.add_theme_font_override("font",_italic);words.add_child(line)
	var people:=Hall.people_regard()
	if not people.is_empty():
		var regard_box:=VBoxContainer.new();regard_box.name="PeopleRegard";regard_box.add_theme_constant_override("separation",2);regard_box.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		regard_box.tooltip_text="How your people hold their god: love from your officials' regard, legitimacy and cohesion; dread from your officials and your recent wrath."
		regard_box.mouse_filter=Control.MOUSE_FILTER_PASS
		var meter:=RegardMeter.new();meter.custom_minimum_size=Vector2(200,24);meter.love=float(people.love);meter.dread=float(people.dread);meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;regard_box.add_child(meter)
		var read:=Tokens.make_label(_first_upper(String(people.get("read",""))),12,Color("f6ecd6"));read.mouse_filter=Control.MOUSE_FILTER_IGNORE;regard_box.add_child(read)
		row.add_child(regard_box)
	var close:=Button.new();close.name="CloseCourt";close.text="Leave the court ×";close.focus_mode=Control.FOCUS_NONE
	close.size_flags_vertical=Control.SIZE_SHRINK_CENTER;close.custom_minimum_size=Vector2(150,34);close.tooltip_text="Close the court and return to your lands. Esc."
	close.pressed.connect(_close);row.add_child(close)
	# The court seated in the scene, the most pressing nearest the fire.
	var seated:=roster.duplicate()
	seated.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if int(a.matters)!=int(b.matters):return int(a.matters)>int(b.matters)
		return int(ROSTER_ORDER.get(String(a.group),9))<int(ROSTER_ORDER.get(String(b.group),9)))
	for index in mini(seated.size(),MAX_SEATED):
		var entry:Dictionary=seated[index]
		var seat:=_rest_seat(entry)
		scene_area.add_child(seat);rest_seats[String(entry.key)]=seat
	# Envoys stand at the threshold, at the edge of the firelight.
	var envoys:=Roster.envoys()
	if not envoys.is_empty():
		var threshold:=VBoxContainer.new();threshold.name="Threshold";threshold.add_theme_constant_override("separation",4)
		threshold.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		threshold.grow_horizontal=Control.GROW_DIRECTION_BEGIN;threshold.grow_vertical=Control.GROW_DIRECTION_BEGIN
		threshold.offset_right=-14;threshold.offset_bottom=-10
		var caption:=PanelContainer.new();caption.add_theme_stylebox_override("panel",_plate(Color(.06,.045,.03,.62),4,4))
		caption.add_child(Tokens.make_label("AT THE THRESHOLD",10,Color("e2d3b4"),.12));threshold.add_child(caption)
		for index in mini(envoys.size(),3):threshold.add_child(_threshold_chip(envoys[index]))
		scene_area.add_child(threshold)
	scene_area.resized.connect(_layout_rest_seats)
	return scene_area

func _rest_seat(entry:Dictionary)->Control:
	## One seated member of the court: a portrait on the logs or benches, their
	## name, a love/dread gauge and how many matters they hold. Click to summon.
	var holder:=Control.new();holder.name="Seat_"+_node_key(String(entry.key))
	holder.custom_minimum_size=Vector2(100,124);holder.size=holder.custom_minimum_size
	holder.mouse_filter=Control.MOUSE_FILTER_STOP;holder.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	var regard:Dictionary=entry.get("regard",{})
	var matters:=int(entry.get("matters",0))
	holder.tooltip_text="%s · %s%s\n%s" % [String(entry.name),String(entry.title),(" · "+String(regard.get("read",""))) if not regard.is_empty() else "",
		("%d matter%s to raise. Click to summon." % [matters,"" if matters==1 else "s"]) if matters>0 else "Nothing pending. Click to summon them anyway."]
	var panel:=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var plate:=_plate(Color(.06,.045,.03,.58),6,4)
	plate.border_color=_person_color(int((entry.get("target",{}) as Dictionary).get("person_id",0))).lightened(.2) if int((entry.get("target",{}) as Dictionary).get("person_id",0))>0 else Color("c9a24a")
	plate.border_width_bottom=3
	panel.add_theme_stylebox_override("panel",plate);holder.add_child(panel)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",2);stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(stack)
	var frame:=PanelContainer.new();frame.add_theme_stylebox_override("panel",Tokens.flat(Color("eee7d8"),Color(0,0,0,0),0,3,1));frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(frame)
	frame.add_child(Portrait.picture(entry.get("person",{}) as Dictionary,86,72))
	var who:=Tokens.make_label(String(entry.name).get_slice(" ",0),12,Color("f6ecd6"));who.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;who.clip_text=true;who.add_theme_font_override("font",_bold);who.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(who)
	var under:=HBoxContainer.new();under.add_theme_constant_override("separation",3);under.alignment=BoxContainer.ALIGNMENT_CENTER;under.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(under)
	if not regard.is_empty():
		var gauge:=TextureRect.new();gauge.texture=Divine.meter_texture(float(regard.love),float(regard.dread),18);gauge.custom_minimum_size=Vector2(18,18);gauge.mouse_filter=Control.MOUSE_FILTER_IGNORE;under.add_child(gauge)
	var office:=Tokens.make_label(_short_title(String(entry.title)),10,Color("e2d3b4"));office.clip_text=true;office.custom_minimum_size.x=66;office.mouse_filter=Control.MOUSE_FILTER_IGNORE;under.add_child(office)
	if matters>0:
		var badge:=Label.new();badge.name="Matters";badge.text=str(matters);badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size",12);badge.add_theme_color_override("font_color",Color("2a2217"))
		badge.add_theme_stylebox_override("normal",_plate(Color("e8c35a"),10,0));badge.size=Vector2(20,20);badge.position=Vector2(100-16,-6);badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
		holder.add_child(badge)
	var target:Dictionary=(entry.get("target",{}) as Dictionary).duplicate()
	holder.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:summon(target))
	holder.mouse_entered.connect(func()->void:holder.modulate=Color(1.12,1.08,.96))
	holder.mouse_exited.connect(func()->void:holder.modulate=Color.WHITE)
	return holder

func _layout_rest_seats()->void:
	if not is_instance_valid(scene_area) or not is_instance_valid(backdrop):return
	# Compose the scene below the header that lies across its top.
	var head:Control=scene_area.get_meta("header") as Control if scene_area.has_meta("header") else null
	var top:=head.size.y*.8 if is_instance_valid(head) else 0.0
	if absf(float(backdrop.content_top)-top)>.5:
		backdrop.content_top=top;backdrop.queue_redraw()
	if rest_seats.is_empty():return
	# With envoys at the threshold, the court sits a little to the left.
	var points:Array[Vector2]=backdrop.seat_points(rest_seats.size(),.44 if scene_area.find_child("Threshold",false,false)!=null else .5)
	var shrink:=clampf((scene_area.size.y-top)/250.0,.62,1.0)
	var min_y:=INF;var max_y:=-INF
	for p in points:min_y=minf(min_y,p.y);max_y=maxf(max_y,p.y)
	var index:=0
	for key in rest_seats:
		var seat:=rest_seats[key] as Control
		if not is_instance_valid(seat) or index>=points.size():continue
		var p:=points[index];index+=1
		var depth:=0.0 if max_y-min_y<1.0 else (p.y-min_y)/(max_y-min_y)
		var s:=shrink*lerpf(.88,1.0,depth)
		seat.pivot_offset=Vector2(seat.size.x*.5,seat.size.y)
		seat.scale=Vector2.ONE*s
		seat.position=(p-Vector2(seat.size.x*.5,seat.size.y)).round()

func _threshold_chip(audience:Dictionary)->Control:
	var chip:=Button.new();chip.name="Threshold_"+String(audience.get("id",""))
	chip.focus_mode=Control.FOCUS_NONE;chip.custom_minimum_size=Vector2(0,40)
	var style:=_plate(Color(.06,.045,.03,.72),6,0);style.border_color=Color("c9a24a");style.border_width_left=3
	style.content_margin_left=8;style.content_margin_right=12
	var hover:=style.duplicate() as StyleBoxFlat;hover.bg_color=Color(.18,.13,.07,.82);hover.border_color=Color("e8c35a")
	chip.add_theme_stylebox_override("normal",style);chip.add_theme_stylebox_override("hover",hover);chip.add_theme_stylebox_override("pressed",hover)
	chip.icon=Identity.foreign(String(audience.get("civ_id",""))).texture
	chip.add_theme_constant_override("icon_max_width",26);chip.add_theme_constant_override("h_separation",8)
	chip.add_theme_color_override("font_color",Color("f6ecd6"));chip.add_theme_color_override("font_hover_color",Color("fff6e2"))
	chip.add_theme_font_size_override("font_size",13)
	var waited:=int(GameState.elapsed_days)-int(audience.get("arrived_day",GameState.elapsed_days))
	chip.text="Envoy of %s · %s" % [String(audience.get("civ_name","")),"arrived today" if waited<=0 else "waits %d d" % waited]
	chip.tooltip_text="Receive the envoy of %s." % String(audience.get("civ_name",""))
	var id:=String(audience.get("id",""))
	chip.pressed.connect(func()->void:receive(id))
	return chip

func _rest_column(node_name:String,heading:String,sub:String,content:Control,ratio:float)->Control:
	var column:=VBoxContainer.new();column.name=node_name;column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.size_flags_stretch_ratio=ratio
	column.add_theme_constant_override("separation",4)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);column.add_child(head)
	head.add_child(Tokens.make_label(heading,12,Tokens.GOLD_BRIGHT,.12))
	var note:=Tokens.make_label(sub,12,Tokens.TEXT_DIM);note.add_theme_font_override("font",_italic);note.size_flags_horizontal=Control.SIZE_EXPAND_FILL;note.clip_text=true;note.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;head.add_child(note)
	var rule:=ColorRect.new();rule.color=Tokens.BORDER_SOFT;rule.custom_minimum_size=Vector2(0,1);column.add_child(rule)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(content)
	return column

func _build_roster_list(roster:Array[Dictionary])->Control:
	var list:=VBoxContainer.new();list.name="RosterList";list.add_theme_constant_override("separation",5)
	var groups:Dictionary={}
	for entry in roster:
		if not groups.has(String(entry.group)):groups[String(entry.group)]=[]
		(groups[String(entry.group)] as Array).append(entry)
	for group in Roster.GROUPS:
		if not groups.has(group):continue
		var label:=Tokens.make_label(String(Roster.GROUP_WORDS.get(group,group.to_upper())),10,Tokens.TEXT_DIM,.12)
		list.add_child(label)
		for entry:Dictionary in groups[group]:list.add_child(_roster_row(entry))
	if roster.is_empty():
		var empty:=Tokens.make_label("No one holds office yet. Officials appear as your government grows.",13,Tokens.MUTED);empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(empty)
	preload("res://scripts/hud/court_remembered.gd").append_to(list,_italic)
	return list

func _roster_row(entry:Dictionary)->Control:
	var pid:=int((entry.get("target",{}) as Dictionary).get("person_id",0))
	var row:=PanelContainer.new();row.name="Row_"+_node_key(String(entry.key))
	row.add_theme_stylebox_override("panel",Tokens.row_style(_person_color(pid) if pid>0 else Tokens.GOLD))
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);row.add_child(line)
	var frame:=PanelContainer.new();frame.add_theme_stylebox_override("panel",Tokens.flat(Color("eee7d8"),Color(0,0,0,0),0,3,1));frame.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(frame)
	frame.add_child(Portrait.picture(entry.get("person",{}) as Dictionary,34,40))
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",0);line.add_child(words)
	var who:=Tokens.make_label(String(entry.name),14,Tokens.INK);who.add_theme_font_override("font",_bold);who.clip_text=true;who.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;words.add_child(who)
	var regard:Dictionary=entry.get("regard",{})
	var sub_text:=String(entry.title)
	if not regard.is_empty():sub_text+=" · "+String(regard.get("read",""))
	var sub:=Tokens.make_label(sub_text,12,Tokens.TEXT_SOFT);sub.clip_text=true;sub.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;words.add_child(sub)
	if not regard.is_empty():
		var gauge:=TextureRect.new();gauge.texture=Divine.meter_texture(float(regard.love),float(regard.dread),22);gauge.custom_minimum_size=Vector2(22,22);gauge.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		gauge.tooltip_text=Divine.meter_words(float(regard.love),float(regard.dread));line.add_child(gauge)
	var matters:=int(entry.get("matters",0))
	var count:=Tokens.make_label(("%d matter%s" % [matters,"" if matters==1 else "s"]) if matters>0 else "",12,Tokens.GOLD_BRIGHT);count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;count.custom_minimum_size.x=64;line.add_child(count)
	var button:=Button.new();button.name="Summon_"+_node_key(String(entry.key));button.text="Summon";button.custom_minimum_size=Vector2(88,30);button.focus_mode=Control.FOCUS_NONE
	button.size_flags_vertical=Control.SIZE_SHRINK_CENTER;button.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
	button.tooltip_text="Call %s before you now." % String(entry.name)
	var target:Dictionary=(entry.get("target",{}) as Dictionary).duplicate()
	button.pressed.connect(func()->void:summon(target))
	line.add_child(button)
	return row

func _build_antechamber()->Control:
	var list:=VBoxContainer.new();list.name="AntechamberList";list.add_theme_constant_override("separation",5)
	var envoys:=Roster.envoys()
	if envoys.is_empty():
		var empty:=Tokens.make_label("No envoy waits.",13,Tokens.MUTED);empty.add_theme_font_override("font",_italic);list.add_child(empty)
	for audience in envoys:list.add_child(_envoy_row(audience))
	var set_aside:=Roster.court_waiting()
	if not set_aside.is_empty():
		list.add_child(Tokens.make_label("STILL BEFORE YOU",10,Tokens.TEXT_DIM,.12))
		for audience in set_aside:
			var speaker:Dictionary=audience.get("speaker",{})
			var row:=_simple_row("Resume_"+String(audience.id),String(speaker.get("name","")),"%s · you left them waiting" % String(speaker.get("title","")),"Resume",Tokens.VIOLET)
			var id:=String(audience.id)
			(row.get_meta("button") as Button).pressed.connect(func()->void:receive(id))
			list.add_child(row)
	var decisions:Array[Dictionary]=[]
	for item in AdvisorSystem.council_decision_items(6,false):
		if String(item.get("status","unread"))=="unread" and not (item.get("responses",[]) as Array).is_empty():decisions.append(item)
		if decisions.size()>=3:break
	if not decisions.is_empty():
		list.add_child(Tokens.make_label("AWAITING YOUR WORD",10,Tokens.TEXT_DIM,.12))
		for item in decisions:list.add_child(_decision_row(item))
	return list

func _envoy_row(audience:Dictionary)->Control:
	var id:=String(audience.get("id",""))
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var headline:=String(situation.get("headline","")).strip_edges()
	if headline.is_empty():headline=String((KINDS.get(String(audience.get("kind","news")),KINDS.news) as Dictionary).eyebrow).to_lower()
	var waited:=int(GameState.elapsed_days)-int(audience.get("arrived_day",GameState.elapsed_days))
	var leaves:=int(audience.get("expires_day",0))
	var sub:="%s · %s%s" % [headline,"arrived today" if waited<=0 else "waited %d day%s" % [waited,"" if waited==1 else "s"]," · leaves after day %d" % leaves if leaves>0 else ""]
	var row:=_simple_row("Receive_"+id,"Envoy of %s" % String(audience.get("civ_name","")),sub,"Receive",_ink(Identity.banner_color(Identity.foreign(String(audience.get("civ_id",""))).texture)),Identity.foreign(String(audience.get("civ_id",""))).texture)
	(row.get_meta("button") as Button).pressed.connect(func()->void:receive(id))
	return row

func _simple_row(button_name:String,title:String,sub:String,action:String,colour:Color,icon:Texture2D=null)->PanelContainer:
	var row:=PanelContainer.new();row.add_theme_stylebox_override("panel",Tokens.row_style(colour))
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",9);row.add_child(line)
	if icon!=null:
		var picture:=TextureRect.new();picture.texture=icon;picture.custom_minimum_size=Vector2(28,34);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;line.add_child(picture)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",0);line.add_child(words)
	var head:=Tokens.make_label(title,14,Tokens.INK);head.add_theme_font_override("font",_bold);head.clip_text=true;head.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;words.add_child(head)
	var detail:=Tokens.make_label(sub,12,Tokens.TEXT_SOFT);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.max_lines_visible=2;words.add_child(detail)
	var button:=Button.new();button.name=button_name;button.text=action;button.custom_minimum_size=Vector2(84,30);button.focus_mode=Control.FOCUS_NONE
	button.size_flags_vertical=Control.SIZE_SHRINK_CENTER;button.add_theme_stylebox_override("normal",Tokens.gold_outline_style());line.add_child(button)
	row.set_meta("button",button)
	return row

func _decision_row(item:Dictionary)->Control:
	var row:=PanelContainer.new();row.name="Decision_"+_node_key(String(item.get("id","")))
	row.add_theme_stylebox_override("panel",Tokens.row_style(Tokens.RED if String(item.get("severity","warning")) in ["danger","critical"] else Tokens.AMBER))
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",4);row.add_child(stack)
	var text:=Tokens.make_label(String(item.get("text","")).split("\n")[0],13,Tokens.BODY);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.max_lines_visible=2;stack.add_child(text)
	var who:=Tokens.make_label("%s · %s" % [String(item.get("advisor","")),String(item.get("office","Council"))],11,Tokens.TEXT_DIM);stack.add_child(who)
	var answers:=HFlowContainer.new();answers.add_theme_constant_override("h_separation",6);answers.add_theme_constant_override("v_separation",4);stack.add_child(answers)
	var item_id:=String(item.get("id",""))
	for response in item.get("responses",[]):
		var label:=String((response as Dictionary).get("label",""))
		if label.is_empty():continue
		var answer:=Button.new();answer.text=label;answer.focus_mode=Control.FOCUS_NONE;answer.custom_minimum_size.y=28
		answer.tooltip_text=String((response as Dictionary).get("ripple",(response as Dictionary).get("hint","")))
		answer.pressed.connect(func()->void:
			AdvisorSystem.respond_to_council_item(item_id,label)
			show_court())
		answers.add_child(answer)
	return row

func _build_foreign_list()->Control:
	var list:=VBoxContainer.new();list.name="ForeignList";list.add_theme_constant_override("separation",5)
	var peoples:=Roster.foreign_peoples()
	if peoples.is_empty():
		var empty:=Tokens.make_label("You know no foreign ruler yet. Scouts and delegates must find them first.",13,Tokens.MUTED);empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;empty.add_theme_font_override("font",_italic);list.add_child(empty)
	for entry in peoples:
		var civ_id:=String(entry.civ_id)
		var regard:Dictionary=entry.get("regard",{})
		var state:="at war with you" if bool(entry.at_war) else ("your envoys know the way" if bool(entry.access) else "no audience yet: send delegates first")
		if bool(entry.waiting):state="their envoy waits in your antechamber"
		var sub:="%s · they %s · %s" % [String(entry.leader),String(regard.get("read","are undecided about you")),state]
		var row:=_simple_row("Foreign_"+civ_id,String(entry.name),sub,"Send word",_ink(Identity.banner_color(Identity.foreign(civ_id).texture)),Identity.foreign(civ_id).texture)
		(row.get_meta("button") as Button).pressed.connect(func()->void:show_foreign(civ_id))
		list.add_child(row)
	return list

func _build_rest_footer()->Control:
	var bar:=_footer_bar()
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",4);bar.add_child(stack)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);stack.add_child(row)
	speech_input=LineEdit.new();speech_input.name="SpeechInput";speech_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	speech_input.custom_minimum_size=Vector2(360,38);speech_input.max_length=400;speech_input.add_theme_font_size_override("font_size",15)
	speech_input.placeholder_text="Speak to your court…"
	speech_input.tooltip_text="Name whom you address (by name or office), or speak plainly and your local leader answers. Name a foreign people to brief an envoy."
	speech_input.text_submitted.connect(func(_t:String):_speak())
	row.add_child(speech_input)
	speak_button=Button.new();speak_button.name="Speak";speak_button.text="SPEAK";speak_button.custom_minimum_size=Vector2(96,38)
	speak_button.add_theme_stylebox_override("normal",Tokens.gold_outline_style());speak_button.pressed.connect(_speak);row.add_child(speak_button)
	_add_court_controls(row,"Receive envoys at once")
	if not _persons_live():
		# Offline: ask the court about people from choices, not parsing.
		var ask_row:=HBoxContainer.new();ask_row.name="PersonsRow";ask_row.add_theme_constant_override("separation",6);stack.add_child(ask_row)
		persons_row=ask_row
		var rest_choices:Array[Dictionary]=[]
		for c in persons_choices():
			if String(c.get("group",""))in ["ask","summon"]:rest_choices.append(c)
		_fill_persons_menus(ask_row,rest_choices)
	var note:=Tokens.make_label("",12,Tokens.TEXT_DIM);note.name="CourtNote";note.add_theme_font_override("font",_italic);stack.add_child(note)
	return bar

func speak_to_court(text:String)->void:
	## Words spoken to the court as a whole reach whoever they name, or the
	## local leader; a foreign ruler's name sets them down as an envoy's brief.
	var named:=Roster.find_by_words(text)
	var foreign:=Roster.find_foreign_by_words(text)
	if named.is_empty() and not foreign.is_empty():
		if show_foreign(String(foreign.civ_id)) and is_instance_valid(speech_input):
			speech_input.text=text
			ForeignDialogue.thread(String(foreign.civ_id))["next_brief"]=text
		return
	var entry:=named if not named.is_empty() else Roster.default_speaker()
	if entry.is_empty():
		_court_note("No one is at court to hear you yet.")
		return
	if summon(entry.get("target",{}) as Dictionary):pending_words=text

func _deliver_pending_words()->void:
	## Words spoken before the summoned person arrived are said once they stand
	## before you and the room has settled.
	if pending_words.is_empty() or mode!="audience" or revealing:return
	if _voice_ok() and voice.busy(audience_id):return
	if not is_instance_valid(speech_input) or not resolved_result.is_empty():pending_words="";return
	var lines:Array=Hall.find(audience_id).get("lines",[])
	if rendered_lines<lines.size():return
	speech_input.text=pending_words;pending_words=""
	if is_instance_valid(speak_button):speak_button.disabled=false
	_speak()

static func _short_title(title:String)->String:
	var words:=title.split(" ",false)
	return title if words.size()<=2 else "%s %s" % [words[0],words[1]]

static func _first_upper(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)

static func _node_key(key:String)->String:
	return key.replace(":","_").replace("/","_").replace(" ","_").replace(".","_").replace("@","_")

# --- A settlement leader's civic conversation ---------------------------------

func _civic_begin(audience:Dictionary)->void:
	## A summoned settlement leader carries the civic directive conversation:
	## orders, objections, refusals, confirmation and withdrawal, all here.
	civic_settlement="";civic_seen.clear();civic_signature=""
	if String(audience.get("origin",""))!="court" or speaker_person_id<=0:return
	if not is_instance_valid(terrain) or not terrain.has_method("_issue_freeform_order") or not terrain.has_method("issue_civic_directive_text"):return
	var sid:=Civic.leader_settlement(speaker_person_id)
	if sid.is_empty():return
	civic_settlement=sid
	for turn in Civic.history(sid,24):civic_seen[Civic.turn_key(turn)]=true

func _speaker_name()->String:
	return String((Hall.find(audience_id).get("speaker",{}) as Dictionary).get("name","The leader"))

func _build_civic_strip()->Control:
	civic_strip=PanelContainer.new();civic_strip.name="CivicStrip"
	civic_strip.add_theme_stylebox_override("panel",Tokens.brief_style("info"))
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",3);civic_strip.add_child(stack)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);stack.add_child(row)
	civic_state_label=Tokens.make_label("",13,Tokens.BODY,.04);civic_state_label.name="CivicState";civic_state_label.add_theme_font_override("font",_bold)
	civic_state_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;civic_state_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	civic_state_label.clip_text=true;civic_state_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;row.add_child(civic_state_label)
	civic_replies=HBoxContainer.new();civic_replies.name="CivicReplies";civic_replies.add_theme_constant_override("separation",6);row.add_child(civic_replies)
	var dismiss:=Button.new();dismiss.name="DismissFromOffice";dismiss.text="Dismiss from office";dismiss.focus_mode=Control.FOCUS_NONE;dismiss.custom_minimum_size=Vector2(0,28)
	dismiss.tooltip_text="Take their office from them. A successor takes it up at once; the dismissed keep their lives."
	dismiss.add_theme_color_override("font_color",Tokens.RED);dismiss.pressed.connect(dismiss_leader);row.add_child(dismiss)
	civic_status_label=Tokens.make_label("",12,Tokens.TEXT_SOFT);civic_status_label.name="CivicStatus";civic_status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;civic_status_label.max_lines_visible=2
	stack.add_child(civic_status_label)
	_refresh_civic_strip(true)
	return civic_strip

func civic_state()->String:
	if civic_settlement.is_empty():return ""
	return Civic.state(Civic.latest_order(civic_settlement,speaker_person_id))

func _refresh_civic_strip(force:bool=false)->void:
	if not is_instance_valid(civic_state_label) or civic_settlement.is_empty():return
	var order:=Civic.latest_order(civic_settlement,speaker_person_id)
	var state:=Civic.state(order)
	var signature:="%s|%s|%s" % [state,String(order.get("id","")),String(order.get("status",""))]
	if signature==civic_signature and not force:return
	civic_signature=signature
	var who:=_speaker_name().get_slice(" ",0)
	var place:=Civic.settlement_name(civic_settlement)
	if state.is_empty():
		civic_state_label.text="THE WORK OF %s" % (place.to_upper() if not place.is_empty() else "THE SETTLEMENT")
		civic_state_label.add_theme_color_override("font_color",Tokens.TEAL)
		civic_status_label.text="%s leads %s. Ask, and they answer at once; speak an order, and they weigh whether it can be done." % [who,place if not place.is_empty() else "your settlement"]
	else:
		civic_state_label.text=Civic.headline(state,who)
		civic_state_label.add_theme_color_override("font_color",Civic.state_color(state))
		civic_status_label.text=Civic.status_text(state).get_slice(" · ",1) if " · " in Civic.status_text(state) else Civic.status_text(state)
	civic_state_label.tooltip_text=Civic.status_text(state)
	civic_strip.add_theme_stylebox_override("panel",Tokens.brief_style("warn" if state in ["NEEDS YOUR DECISION","REFUSED","BLOCKED"] else "info"))
	for child in civic_replies.get_children():child.queue_free()
	for reply in Civic.quick_replies(state):
		var button:=Button.new();button.name="Civic_"+String(reply.id);button.text=String(reply.label);button.tooltip_text=String(reply.tip)
		button.focus_mode=Control.FOCUS_NONE;button.custom_minimum_size=Vector2(0,28);button.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
		var words:=String(reply.text)
		button.pressed.connect(func()->void:civic_reply(words))
		civic_replies.add_child(button)
	if state=="INTERPRETING" and terrain.has_method("_cancel_pending_pronouncement"):
		var cancel:=Button.new();cancel.name="Civic_cancel";cancel.text="Call it back";cancel.focus_mode=Control.FOCUS_NONE;cancel.custom_minimum_size=Vector2(0,28)
		cancel.tooltip_text="Withdraw the instruction before they finish weighing it."
		var order_id:=String(order.get("id",""));var request_id:=String(order.get("request_id",""))
		cancel.pressed.connect(func()->void:
			terrain._cancel_pending_pronouncement(order_id,request_id)
			_refresh_civic_strip(true))
		civic_replies.add_child(cancel)

## A one-word answer to the leader (confirm, insist, withdraw): ordinary
## speech, carried by the civic pipeline like anything else you say.
func civic_reply(words:String)->void:
	if civic_settlement.is_empty() or not resolved_result.is_empty():return
	_civic_say(words)

func _civic_say(text:String)->void:
	Hall.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text,"day":int(GameState.elapsed_days),"aside":false})
	SettlementModel.select_settlement(civic_settlement)
	terrain.issue_civic_directive_text(text)
	_sync_civic()
	_refresh_civic_strip(true)
	_pump()

func _sync_civic()->void:
	## Mirror the leader's civic answers into this audience as they arrive.
	if civic_settlement.is_empty() or audience_id.is_empty():return
	var holder:=int(GovernmentPeopleSystem.settlement_leader(civic_settlement).get("person_id",0))
	var who:=_speaker_name()
	for turn in Civic.history(civic_settlement,12):
		var key:=Civic.turn_key(turn)
		if civic_seen.has(key):continue
		civic_seen[key]=true
		if String(turn.speaker)!="leader" or String(turn.text).is_empty():continue
		# The council's own record (a leadership change) is narration; everything
		# else is the leader answering you.
		if String(turn.name)=="COUNCIL RECORD":
			Hall.append_line(audience_id,{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":String(turn.text),"day":int(turn.day),"aside":false})
			continue
		Hall.append_line(audience_id,{"speaker":who,"role":"official","person_id":speaker_person_id,"civ_id":"","text":String(turn.text),"day":int(turn.day),"aside":false})
		if not String(turn.get("receipt","")).is_empty():
			Hall.append_line(audience_id,{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":"RECEIPT · "+String(turn.receipt),"day":int(turn.day),"aside":false})
	if holder!=speaker_person_id and resolved_result.is_empty():
		# They no longer lead the settlement (dismissed, arrested, or gone).
		var place:=Civic.settlement_name(civic_settlement)
		var outcome:="%s no longer leads %s." % [who,place if not place.is_empty() else "the settlement"]
		Hall.append_line(audience_id,{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":outcome,"day":int(GameState.elapsed_days),"aside":false})
		Hall.conclude(audience_id,outcome,"removed_from_office")
		civic_settlement=""
		_show_outcome({"ok":true,"outcome":outcome,"reaction":"offended","terminal":true})
		return
	_refresh_civic_strip()

## Takes the settlement from its leader, through the ordinary civic removal.
func dismiss_leader()->Dictionary:
	if civic_settlement.is_empty() or not terrain.has_method("_perform_civic_leader_removal"):return {"ok":false}
	var who:=_speaker_name()
	var result:Variant=terrain._perform_civic_leader_removal(civic_settlement,"dismiss","You are dismissed from your office, %s." % who.get_slice(" ",0))
	var answer:Dictionary=result if result is Dictionary else {}
	if not bool(answer.get("ok",false)):
		_show_toast(String(answer.get("reason",answer.get("message","Leadership did not change."))))
		return answer
	Hall.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":"You are dismissed from your office, %s." % who.get_slice(" ",0),"day":int(GameState.elapsed_days),"aside":false})
	_sync_civic()
	_pump()
	return answer

func _add_civic_record()->void:
	## What passed between you before this audience, quietly at the top.
	var turns:=Civic.history(civic_settlement,4)
	if turns.is_empty() or not is_instance_valid(transcript):return
	var box:=VBoxContainer.new();box.name="CivicRecord";box.add_theme_constant_override("separation",3)
	box.add_child(Tokens.make_label("EARLIER WITH %s" % _speaker_name().to_upper(),10,Tokens.TEXT_DIM,.12))
	for turn in turns:
		var who:="You" if String(turn.speaker)=="player" else (String(turn.name) if not String(turn.name).is_empty() else _speaker_name())
		var text:=Tokens.make_label("Day %d · %s: %s" % [int(turn.day)+1,who,String(turn.text)],13,Tokens.TEXT_SOFT)
		text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.max_lines_visible=3;text.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		box.add_child(text)
	var rule:=ColorRect.new();rule.color=Tokens.BORDER_SOFT;rule.custom_minimum_size=Vector2(0,1);box.add_child(rule)
	transcript.add_child(box)

# --- Word to a foreign ruler (the envoy channel) --------------------------------

func show_foreign(civ_id:String)->bool:
	var leader:=ForeignDiplomacy.leader(civ_id)
	if leader.is_empty():
		if mode!="rest":show_court()
		_court_note("You have no way to reach that people's ruler yet.")
		return false
	if mode=="audience" and resolved_result.is_empty() and not audience_id.is_empty():Hall.defer(audience_id)
	_reset_card("foreign")
	foreign_civ=civ_id;from_court=true
	var civ:=ForeignDiplomacy.civilization(civ_id)
	accent=Tokens.BLUE
	envoy_color=_ink(Identity.banner_color(Identity.foreign(civ_id).texture))
	var style:=Tokens.flat(Tokens.PANEL_BG_SOLID,accent.darkened(.1),2,10,0)
	style.shadow_color=Color(0,0,0,.45);style.shadow_size=28
	card.add_theme_stylebox_override("panel",style)
	_add_backdrop(card)
	body=VBoxContainer.new();body.name="ForeignView";body.add_theme_constant_override("separation",0);card.add_child(body)
	body.add_child(_build_foreign_herald(civ_id,civ,leader))
	var veil:=PanelContainer.new();veil.name="Veil";veil.size_flags_vertical=Control.SIZE_EXPAND_FILL
	veil.add_theme_stylebox_override("panel",_veil_style());body.add_child(veil)
	var inner:=MarginContainer.new();inner.size_flags_vertical=Control.SIZE_EXPAND_FILL
	for side in ["left","right"]:inner.add_theme_constant_override("margin_"+side,20)
	inner.add_theme_constant_override("margin_top",14);inner.add_theme_constant_override("margin_bottom",12)
	veil.add_child(inner)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);inner.add_child(column)
	var stage:=HBoxContainer.new();stage.name="Stage";stage.size_flags_vertical=Control.SIZE_EXPAND_FILL;stage.add_theme_constant_override("separation",16);column.add_child(stage)
	stage.add_child(_build_foreign_speaker(civ_id,civ,leader))
	var center:=VBoxContainer.new();center.size_flags_horizontal=Control.SIZE_EXPAND_FILL;center.add_theme_constant_override("separation",6);stage.add_child(center)
	var status:=Tokens.make_label("",13,Tokens.TEXT_SOFT);status.name="ForeignStatus";status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.max_lines_visible=3
	center.add_child(status);foreign_refs["status"]=status
	var hall_panel:=PanelContainer.new();hall_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var hall_style:=Tokens.flat(Tokens.FIELD_BG if Tokens.is_light() else Color("0a1316"),Tokens.BORDER_SOFT,1,8,0)
	hall_style.content_margin_left=14;hall_style.content_margin_right=10;hall_style.content_margin_top=12;hall_style.content_margin_bottom=10
	hall_panel.add_theme_stylebox_override("panel",hall_style);center.add_child(hall_panel)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",6);hall_panel.add_child(stack)
	transcript_scroll=ScrollContainer.new();transcript_scroll.name="Transcript";transcript_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	transcript_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;stack.add_child(transcript_scroll)
	transcript=VBoxContainer.new();transcript.size_flags_horizontal=Control.SIZE_EXPAND_FILL;transcript.add_theme_constant_override("separation",10)
	transcript_scroll.add_child(transcript)
	thinking=Tokens.make_label("",14,Tokens.TEXT_DIM);thinking.name="Thinking";thinking.add_theme_font_override("font",_italic);thinking.visible=false;stack.add_child(thinking)
	column.add_child(_build_brief_row(civ_id))
	column.add_child(_build_offline_briefs())
	column.add_child(_build_terms_row(civ_id))
	body.add_child(_build_foreign_footer())
	if not ForeignDialogue.changed.is_connected(_on_foreign_changed):ForeignDialogue.changed.connect(_on_foreign_changed)
	_fit()
	_refresh_foreign()
	return true

func _on_foreign_changed(id:String)->void:
	if mode=="foreign" and id==foreign_civ:_refresh_foreign()

func _build_foreign_herald(civ_id:String,civ:Dictionary,leader:Dictionary)->Control:
	var banner:=PanelContainer.new();banner.name="Herald"
	banner.add_theme_stylebox_override("panel",_herald_style())
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);banner.add_child(row)
	var seal:=Seal.new();seal.kind="proposal";seal.tint=accent.lightened(.15);seal.custom_minimum_size=Vector2(58,58);row.add_child(seal)
	var flag:=TextureRect.new();flag.name="Flag";flag.texture=Identity.foreign(civ_id).texture
	flag.custom_minimum_size=Vector2(50,58);flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;flag.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(flag)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",1);row.add_child(words)
	words.add_child(Tokens.make_label("THE ENVOY CHANNEL · YOU SEND WORD ABROAD",12,Color("e2d3b4"),.12))
	var title:=Tokens.make_label(("WORD TO %s OF %s" % [String(leader.get("name","their ruler")),String(civ.get("name",civ_id))]).to_upper(),24 if _compact() else 30,Color("f6ecd6"))
	title.name="HeraldTitle";title.add_theme_font_override("font",_bold);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(title)
	var sub:=Tokens.make_label("You set the brief; your envoy chooses the words and carries them there and back.",14,Color("e2d3b4"));sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(sub)
	# The court looks on from the scene here too.
	var officials:Array=Hall._officials()
	var seats:=VBoxContainer.new();seats.name="CourtBench";seats.add_theme_constant_override("separation",4);seats.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	seats.tooltip_text="Your court looks on.";seats.mouse_filter=Control.MOUSE_FILTER_PASS
	var benches:=HBoxContainer.new();benches.add_theme_constant_override("separation",6);seats.add_child(benches)
	for index in mini(officials.size(),4):
		var person:Dictionary=officials[index]
		var seat:=PanelContainer.new();seat.add_theme_stylebox_override("panel",_seat_style(int(person.get("person_id",0)),false))
		seat.tooltip_text="%s · %s" % [String(person.get("name","")),String(person.get("office_title",""))]
		var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",2);stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;seat.add_child(stack)
		var face:=PanelContainer.new();face.add_theme_stylebox_override("panel",Tokens.flat(Color("eee7d8"),Color(0,0,0,0),0,3,1));face.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(face)
		face.add_child(Portrait.picture(person,48,52))
		var who:=Tokens.make_label(String(person.get("name","")).get_slice(" ",0),11,Color("f6ecd6"));who.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;who.clip_text=true;who.custom_minimum_size.x=50;stack.add_child(who)
		benches.add_child(seat)
	if not officials.is_empty():row.add_child(seats)
	return banner

func _foreign_leader_person(civ_id:String,leader:Dictionary)->Dictionary:
	var person:={"name":String(leader.get("name","")),"person_id":0}
	# The same picture for a ruler's whole life (rival_rulers.gd).
	var portrait:Dictionary=Rivals.portrait_person(civ_id)
	if portrait.has("early_art_index"):person["early_art_index"]=int(portrait.early_art_index)
	EarlyArt.bind_foreign_identity(person,civ_id,int(GameState.world_seed))
	return person

func _build_foreign_speaker(civ_id:String,civ:Dictionary,leader:Dictionary)->Control:
	var column:=VBoxContainer.new();column.name="Speaker";column.custom_minimum_size.x=236;column.add_theme_constant_override("separation",8)
	speaker_frame=PanelContainer.new();speaker_frame.name="SpeakerFrame"
	speaker_frame.add_theme_stylebox_override("panel",Tokens.flat(Color("eee7d8"),envoy_color,2,8,6));column.add_child(speaker_frame)
	var holder:=Control.new();holder.custom_minimum_size=Vector2(222,_portrait_height());holder.clip_contents=true;speaker_frame.add_child(holder)
	var portrait:=Portrait.picture(_foreign_leader_person(civ_id,leader),222,_portrait_height());portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);holder.add_child(portrait)
	var flag:=TextureRect.new();flag.texture=Identity.foreign(civ_id).texture;flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flag.mouse_filter=Control.MOUSE_FILTER_IGNORE;flag.position=Vector2(166,6);flag.size=Vector2(50,50);holder.add_child(flag)
	var regard:=Divine.foreign_regard(civ_id)
	if not regard.is_empty():
		var strip:=PanelContainer.new();strip.name="Regard";strip.mouse_filter=Control.MOUSE_FILTER_PASS
		var strip_style:=_plate(Color(.06,.05,.04,.8),0,0);strip_style.content_margin_left=8;strip_style.content_margin_right=8;strip_style.content_margin_top=4;strip_style.content_margin_bottom=4
		strip.add_theme_stylebox_override("panel",strip_style);strip.position=Vector2(0,_portrait_height()-52);strip.size=Vector2(222,52)
		var box:=VBoxContainer.new();box.add_theme_constant_override("separation",1);box.mouse_filter=Control.MOUSE_FILTER_IGNORE;strip.add_child(box)
		var meter:=RegardMeter.new();meter.name="RegardMeter";meter.custom_minimum_size=Vector2(206,24);meter.love=float(regard.love);meter.dread=float(regard.dread);meter.love_word="REVERENCE";meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(meter)
		var read:=Tokens.make_label("%s %s" % [String(regard.get("name","")),String(regard.get("read",""))],12,Color("f6ecd6"));read.name="RegardRead";read.clip_text=true;read.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;read.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(read)
		strip.tooltip_text=read.text+". From their opinion of you, their ruler's trust, border tension and remembered terror."
		holder.add_child(strip)
	var plate:=PanelContainer.new();var plate_style:=Tokens.flat(Tokens.TILE_BG,Color(0,0,0,0),0,6,0)
	plate_style.border_color=envoy_color;plate_style.border_width_left=4;plate_style.content_margin_left=12;plate_style.content_margin_right=8;plate_style.content_margin_top=7;plate_style.content_margin_bottom=8
	plate.add_theme_stylebox_override("panel",plate_style);column.add_child(plate)
	var names:=VBoxContainer.new();names.add_theme_constant_override("separation",0);plate.add_child(names)
	var name_label:=Tokens.make_label(String(leader.get("name","")),19,envoy_color);name_label.add_theme_font_override("font",_bold);name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;names.add_child(name_label)
	var title_label:=Tokens.make_label("ruler of %s" % String(civ.get("name",civ_id)),13,Tokens.TEXT_SOFT);title_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;names.add_child(title_label)
	var rows:Array=[]
	rows.append(["Temper",String(leader.get("temperament","")),Tokens.BODY])
	var trust:=float(leader.get("trust",0.0))
	rows.append(["Their trust","earned" if trust>.1 else ("damaged" if trust<-.1 else "untested"),Tokens.RED if trust<-.1 else Tokens.BODY])
	var accord:Dictionary=leader.get("accord",{}) if leader.get("accord") is Dictionary else {}
	if not accord.is_empty() and ForeignDiplomacy.ACCORDS.has(String(accord.get("kind",""))):
		rows.append(["Understanding","%s · %d days" % [String(ForeignDiplomacy.ACCORDS[String(accord.kind)].name),maxi(0,int(accord.get("until",0))-int(GameState.elapsed_days))],Tokens.GREEN])
	var character:Dictionary=Rivals.rival_character(civ_id)
	if not character.is_empty():
		rows.append(["Known for",String(character.get("trait_words","")),Tokens.BODY])
		if int(character.get("age",0))>0:rows.append(["Age","about %d" % int(character.age),Tokens.BODY])
		var grudges:Array=character.get("grudges",[])
		if not grudges.is_empty():rows.append(["Remembers",String((grudges[0] as Dictionary).get("text","")),Tokens.RED])
		var bonds:Array=character.get("bonds",[])
		if not bonds.is_empty():rows.append(["Bound by",String((bonds[0] as Dictionary).get("text","")),Tokens.GREEN])
		var lineage:Array=character.get("lineage",[])
		if not lineage.is_empty():rows.append(["Before them",String((lineage[0] as Dictionary).get("name","")),Tokens.BODY])
	var goals:Array=leader.get("goals",[]) if leader.get("goals") is Array else []
	for index in mini(goals.size(),2):
		if goals[index] is Dictionary:rows.append(["They want",String((goals[index] as Dictionary).get("title","")),Tokens.BODY])
	var box:=VBoxContainer.new();box.name="Dossier";box.add_theme_constant_override("separation",3);column.add_child(box)
	box.visible=not _compact()
	box.add_child(Tokens.make_label("WHAT YOU KNOW",11,Tokens.TEXT_DIM,.1))
	for row:Array in rows:
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",6);box.add_child(line)
		var key:=Tokens.make_label(String(row[0]),12,Tokens.MUTED);key.custom_minimum_size.x=96;line.add_child(key)
		var value:=Tokens.make_label(String(row[1]),13,row[2]);value.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		value.clip_text=true;value.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;value.tooltip_text=String(row[1]);value.mouse_filter=Control.MOUSE_FILTER_PASS;line.add_child(value)
	return column

func _build_brief_row(civ_id:String)->Control:
	var row:=HBoxContainer.new();row.name="SpeechRow";row.add_theme_constant_override("separation",8)
	speech_input=LineEdit.new();speech_input.name="SpeechInput";speech_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	speech_input.custom_minimum_size.y=42;speech_input.max_length=1500;speech_input.add_theme_font_size_override("font_size",16)
	speech_input.placeholder_text="Brief your envoy: what you want, what you will not give, how much they may bend…"
	speech_input.text=String(ForeignDialogue.thread(civ_id).get("next_brief",""))
	speech_input.text_changed.connect(func(value:String)->void:ForeignDialogue.thread(civ_id)["next_brief"]=value)
	speech_input.text_submitted.connect(func(_t:String):_speak())
	row.add_child(speech_input)
	speak_button=Button.new();speak_button.name="Speak";speak_button.text="SEND ENVOY";speak_button.custom_minimum_size=Vector2(130,42)
	speak_button.add_theme_font_size_override("font_size",15);speak_button.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
	speak_button.pressed.connect(_speak);row.add_child(speak_button)
	var delegates:=Button.new();delegates.name="SendDelegates";delegates.text="SEND DELEGATES";delegates.custom_minimum_size=Vector2(150,42)
	delegates.tooltip_text="A first journey to establish an audience. No agreement is proposed."
	delegates.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
	delegates.pressed.connect(func()->void:
		var result:=WorldSimulation.diplomacy.send_audience(civ_id)
		foreign_refs["message"]=String(result.get("error","Delegates depart to establish an audience."))
		_refresh_foreign())
	row.add_child(delegates);foreign_refs["delegates"]=delegates
	var retry:=Button.new();retry.name="RetryReply";retry.text="Retry reply";retry.custom_minimum_size=Vector2(0,42)
	retry.pressed.connect(func()->void:ForeignDialogue.retry(civ_id);_refresh_foreign())
	row.add_child(retry);foreign_refs["retry"]=retry
	var set_aside:=Button.new();set_aside.name="SetAsideReply";set_aside.text="Set aside";set_aside.custom_minimum_size=Vector2(0,42)
	set_aside.tooltip_text="Set the unanswered exchange aside. No agreement was made."
	set_aside.pressed.connect(func()->void:ForeignDialogue.set_aside_reply(civ_id);_refresh_foreign())
	row.add_child(set_aside);foreign_refs["set_aside"]=set_aside
	return row

func _build_offline_briefs()->Control:
	## Without a live voice, briefs are chosen from what lies between the peoples.
	var box:=HFlowContainer.new();box.name="OfflineBriefs";box.add_theme_constant_override("h_separation",8);box.add_theme_constant_override("v_separation",6)
	box.visible=false;foreign_refs["offline"]=box
	return box

func _refresh_offline_briefs(civ_id:String,show:bool,away:bool)->void:
	var box:=foreign_refs.get("offline") as HFlowContainer
	if box==null:return
	box.visible=show
	var choices:Array[Dictionary]=ForeignDialogue.offline_choices(civ_id) if show else []
	var signature:="%s|%s|%s" % [str(show),str(away),JSON.stringify(choices)]
	if String(foreign_refs.get("offline_sig",""))==signature:return
	foreign_refs["offline_sig"]=signature
	for child in box.get_children():child.queue_free()
	if not show:return
	var lead:=Tokens.make_label("BRIEF YOUR ENVOY",11,Tokens.TEXT_DIM,.12);lead.size_flags_vertical=Control.SIZE_SHRINK_CENTER;box.add_child(lead)
	for choice:Dictionary in choices:
		var button:=Button.new();button.name="Brief_"+String(choice.get("id",""));button.text=String(choice.get("label",""));button.custom_minimum_size=Vector2(0,34)
		button.add_theme_stylebox_override("normal",Tokens.gold_outline_style());button.focus_mode=Control.FOCUS_NONE
		var cost:Dictionary=choice.get("cost",{}) if choice.get("cost") is Dictionary else {}
		button.tooltip_text=("Your envoy carries %d %s." % [roundi(float(cost.amount)),String(cost.resource)]) if not cost.is_empty() else "Your envoy carries these words there and back."
		button.disabled=away or not bool(choice.get("enabled",true))
		if not bool(choice.get("enabled",true)):button.tooltip_text=String(choice.get("reason",""))
		var id:=String(choice.get("id",""))
		button.pressed.connect(func()->void:
			var sent:=ForeignDialogue.ask_offline(civ_id,id)
			foreign_refs["message"]="Your envoy sets out with your brief. The answer comes back with them." if sent else String(ForeignDialogue.thread(civ_id).get("status",""))
			_refresh_foreign())
		box.add_child(button)

func _build_terms_row(civ_id:String)->Control:
	## Terms the envoys can carry, with the council's reading of their reception.
	var row:=HBoxContainer.new();row.name="TermsRow";row.add_theme_constant_override("separation",8)
	var lead:=Tokens.make_label("TERMS",11,Tokens.TEXT_DIM,.12);lead.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(lead)
	var accord:=OptionButton.new();accord.name="Accord";accord.focus_mode=Control.FOCUS_NONE
	for definition:Dictionary in ForeignDiplomacy.ACCORDS.values():accord.add_item(String(definition.name))
	accord.select(maxi(0,ForeignDiplomacy.ACCORDS.keys().find(String(WorldSimulation.diplomacy.situation(civ_id).get("priority","")))))
	row.add_child(accord);foreign_refs["accord"]=accord
	var tone:=OptionButton.new();tone.name="Tone";tone.focus_mode=Control.FOCUS_NONE
	for text in ForeignDiplomacy.TONES.values():tone.add_item(String(text))
	row.add_child(tone);foreign_refs["tone"]=tone
	var generous:=CheckBox.new();generous.name="Generous";generous.text="Larger offer";generous.tooltip_text="12 Timber instead of 4: better reception, smaller research benefit for you."
	row.add_child(generous);foreign_refs["generous"]=generous
	for choice:OptionButton in [accord,tone]:choice.item_selected.connect(func(_i:int)->void:_refresh_foreign())
	generous.toggled.connect(func(_on:bool)->void:_refresh_foreign())
	var forecast:=Tokens.make_label("",13,Tokens.BODY_2);forecast.name="Forecast";forecast.size_flags_horizontal=Control.SIZE_EXPAND_FILL;forecast.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	forecast.clip_text=true;forecast.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;forecast.mouse_filter=Control.MOUSE_FILTER_PASS
	row.add_child(forecast);foreign_refs["forecast"]=forecast
	var send:=Button.new();send.name="SendTerms";send.text="Send these terms";send.custom_minimum_size=Vector2(0,34);send.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
	send.pressed.connect(func()->void:
		var result:Dictionary=WorldSimulation.diplomacy.send(civ_id,_selected_accord(),_selected_tone(),generous.button_pressed)
		foreign_refs["message"]=String(result.get("error","Proposal sent. Envoys must return with an answer before an agreement takes effect."))
		_refresh_foreign())
	row.add_child(send);foreign_refs["send"]=send
	var draft:=Button.new();draft.name="ReviewDraft";draft.text="Their draft";draft.custom_minimum_size=Vector2(0,34)
	draft.tooltip_text="Take up the terms drafted in your last exchange."
	draft.pressed.connect(func()->void:
		var proposed:Dictionary=ForeignDialogue.thread(civ_id).get("draft",{})
		if proposed.is_empty():return
		if proposed.has("commitment"):_open_commitments(civ_id,proposed.commitment as Dictionary);return
		accord.select(maxi(0,ForeignDiplomacy.ACCORDS.keys().find(String(proposed.get("accord","")))))
		tone.select(maxi(0,ForeignDiplomacy.TONES.keys().find(String(proposed.get("tone","")))))
		generous.set_pressed_no_signal(bool(proposed.get("generous",false)))
		_refresh_foreign())
	row.add_child(draft);foreign_refs["draft"]=draft
	var treaties:=Button.new();treaties.name="Treaties";treaties.text="Pacts & leagues";treaties.custom_minimum_size=Vector2(0,34)
	treaties.tooltip_text="Protection, leagues and relief: the promises between peoples."
	treaties.pressed.connect(func()->void:_open_commitments(civ_id,{}))
	row.add_child(treaties)
	return row

func _open_commitments(civ_id:String,draft:Dictionary)->void:
	var council:Control=preload("res://scripts/commitment_screen.gd").new()
	council.set("civ_id",civ_id);council.set("draft",draft.duplicate(true))
	add_child(council)

func _selected_accord()->String:
	var pick:=foreign_refs.get("accord") as OptionButton
	return String(ForeignDiplomacy.ACCORDS.keys()[maxi(0,pick.selected)]) if pick!=null else String(ForeignDiplomacy.ACCORDS.keys()[0])

func _selected_tone()->String:
	var pick:=foreign_refs.get("tone") as OptionButton
	return String(ForeignDiplomacy.TONES.keys()[maxi(0,pick.selected)]) if pick!=null else String(ForeignDiplomacy.TONES.keys()[0])

func _build_foreign_footer()->Control:
	var bar:=_footer_bar()
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);bar.add_child(row)
	row.add_child(_build_return_button())
	var connection:=Button.new();connection.name="AIConnection";connection.text="Connection settings…";connection.focus_mode=Control.FOCUS_NONE;connection.custom_minimum_size=Vector2(0,34)
	connection.pressed.connect(func()->void:PronouncementInterpreter.open_connection_settings())
	row.add_child(connection);foreign_refs["connection"]=connection
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(spacer)
	var note:=Tokens.make_label("",12,Tokens.TEXT_DIM);note.name="CourtNote";note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(note)
	var close:=Button.new();close.name="CloseCourt";close.text="Leave the court ×";close.focus_mode=Control.FOCUS_NONE;close.custom_minimum_size=Vector2(150,34)
	close.pressed.connect(_close);row.add_child(close)
	return bar

## Sends the envoy with your brief (a real journey with provisions).
func send_envoy_brief(text:String)->bool:
	if mode!="foreign" or foreign_civ.is_empty():return false
	var sent:=ForeignDialogue.ask(foreign_civ,text)
	if sent:
		if is_instance_valid(speech_input):speech_input.clear()
		foreign_refs["message"]="Your envoy sets out with your brief. The answer comes back with them."
	else:
		foreign_refs["message"]=String(ForeignDialogue.thread(foreign_civ).get("status",""))
	_refresh_foreign()
	return sent

func _refresh_foreign()->void:
	if mode!="foreign" or foreign_civ.is_empty():return
	var id:=foreign_civ
	WorldSimulation.diplomacy.advance(int(WorldSimulation.state.elapsed_days))
	var leader:=ForeignDiplomacy.leader(id)
	if leader.is_empty():show_court();return
	var thread:Dictionary=ForeignDialogue.thread(id)
	var gate:=ForeignDialogue.access(id)
	var connection_issue:=PronouncementInterpreter.connection_problem()
	# The exchange so far.
	var messages:Array=thread.get("messages",[])
	if messages.size()!=foreign_count and is_instance_valid(transcript):
		foreign_count=messages.size()
		for child in transcript.get_children():child.queue_free()
		var person:=_foreign_leader_person(id,leader)
		if messages.is_empty():
			var empty:=Tokens.make_label("No word has passed between you yet. Write your envoy's brief below." if bool(gate.ok) else "Send delegates to establish an audience. You can prepare your brief now.",14,Tokens.TEXT_DIM)
			empty.add_theme_font_override("font",_italic);empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;transcript.add_child(empty)
		for turn in messages:
			if turn is Dictionary:transcript.add_child(_foreign_line(turn as Dictionary,String(leader.get("name","")),person))
		follow_scroll=.6
	var mission:Dictionary=WorldSimulation.world.diplomatic_mission
	var away:=bool(thread.get("in_transit",false)) or not mission.is_empty()
	var status_lines:PackedStringArray=PackedStringArray()
	var message:=String(foreign_refs.get("message",""))
	if not message.is_empty():status_lines.append(message)
	if not connection_issue.is_empty() and not bool(gate.ok):status_lines.append("Your envoys cannot yet carry words: "+connection_issue)
	elif bool(thread.get("retryable",false)):status_lines.append(String(thread.get("status","")))
	elif not bool(gate.ok):status_lines.append(String(gate.reason))
	if bool(thread.get("returned_home",false)) and bool(thread.get("in_transit",false)):
		status_lines.append("Your envoys are home; the reply is being set down." if not bool(thread.get("retryable",false)) else "Your envoys are home, but the reply was lost. Retry it, or set it aside.")
	elif bool(thread.get("in_transit",false)):
		var mission_status:=WorldSimulation.world.diplomatic_mission_status()
		status_lines.append("Your envoy is on the road · %s · home about day %d." % [String(mission_status.get("phase","travelling")).to_lower(),int(mission_status.get("return_day",0))])
	else:
		var quote:Dictionary=WorldSimulation.world.diplomatic_mission_quote(id,"","leader_parley")
		if quote.has("error"):status_lines.append(String(quote.error))
		else:status_lines.append("%s: %d delegates, %.1f food rations at departure, %d days there and back." % ["The journey to establish an audience" if not bool(gate.ok) else "The next exchange",int(quote.personnel),float(quote.provisions),int(quote.total_days)])
	var status:=foreign_refs.get("status") as Label
	if status!=null:
		var joined:=" ".join(status_lines)
		if status.text!=joined:status.text=joined
	if is_instance_valid(thinking):
		thinking.visible=ForeignDialogue.pending.has(id) or bool(thread.get("in_transit",false))
		thinking.text="Your envoy is away with your brief…" if bool(thread.get("in_transit",false)) else "The reply is being set down…"
	if is_instance_valid(speak_button):
		speak_button.visible=bool(gate.ok) and connection_issue.is_empty()
		speak_button.disabled=not connection_issue.is_empty() or ForeignDialogue.pending.has(id) or not bool(gate.ok) or away
		speak_button.tooltip_text="Envoys must return before another party departs." if away else ("Your envoys need a working connection to carry words." if not connection_issue.is_empty() else "Send your envoy with this brief.")
	# Offline, the brief is chosen from what lies between you (rival_rulers.gd).
	_refresh_offline_briefs(id,not connection_issue.is_empty() and bool(gate.ok),away or ForeignDialogue.pending.has(id))
	if is_instance_valid(speech_input):speech_input.visible=connection_issue.is_empty() or not bool(gate.ok)
	var delegates:=foreign_refs.get("delegates") as Button
	if delegates!=null:
		delegates.visible=not bool(gate.ok)
		var quote_error:=WorldSimulation.world.diplomatic_mission_quote(id,"","leader_parley").has("error")
		delegates.disabled=not mission.is_empty() or quote_error
	var retry:=foreign_refs.get("retry") as Button
	if retry!=null:
		retry.visible=bool(thread.get("retryable",false))
		retry.disabled=not connection_issue.is_empty() or ForeignDialogue.pending.has(id) or not bool(gate.ok)
	var set_aside:=foreign_refs.get("set_aside") as Button
	if set_aside!=null:set_aside.visible=bool(thread.get("returned_home",false)) and bool(thread.get("in_transit",false))
	var draft:=foreign_refs.get("draft") as Button
	if draft!=null:draft.visible=not (thread.get("draft",{}) as Dictionary).is_empty()
	var connection:=foreign_refs.get("connection") as Button
	if connection!=null:connection.text="Connect AI…" if not connection_issue.is_empty() else "Connection settings…"
	# Terms and their likely reception.
	var generous:=foreign_refs.get("generous") as CheckBox
	var forecast:Dictionary=WorldSimulation.diplomacy.forecast(id,_selected_accord(),_selected_tone(),generous.button_pressed if generous!=null else false)
	var forecast_label:=foreign_refs.get("forecast") as Label
	if forecast_label!=null and not forecast.is_empty():
		forecast_label.text="%s · %s" % [String(forecast.get("label","")),String(forecast.get("reasons",""))]
		forecast_label.tooltip_text=forecast_label.text+"\nCosts %d Timber, reserved and refunded if declined. The answer is settled when the envoys return." % int(forecast.get("cost",4))
	var send:=foreign_refs.get("send") as Button
	if send!=null:
		var blocker:=String(forecast.get("blocker",""))
		var quote2:Dictionary=WorldSimulation.world.diplomatic_mission_quote(id,"","leader_parley")
		if blocker.is_empty() and quote2.has("error"):blocker=String(quote2.error)
		if blocker.is_empty() and float(WorldSimulation.state.resource_stockpiles.get("Timber",0))<float(forecast.get("cost",4)):blocker="Not enough Timber for these terms."
		send.disabled=not blocker.is_empty()
		send.tooltip_text=blocker if not blocker.is_empty() else "Envoys carry these terms; nothing binds until they return with an answer."

func _foreign_line(turn:Dictionary,leader_name:String,leader_person:Dictionary)->Control:
	var role:=String(turn.get("role",""))
	var ruler:=role=="user"
	var colour:=_ink(Tokens.GOLD) if ruler else (_ink(Tokens.VIOLET) if role=="envoy" else envoy_color)
	var line_row:=HBoxContainer.new();line_row.add_theme_constant_override("separation",10)
	if ruler:
		var indent:=Control.new();indent.custom_minimum_size.x=110;line_row.add_child(indent)
	else:
		var frame:=PanelContainer.new();frame.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
		frame.add_theme_stylebox_override("panel",Tokens.flat(Color("eee7d8"),colour,1,6,2))
		frame.add_child(Portrait.picture(leader_person if role!="envoy" else {"name":"Your envoy","person_id":0},44,52))
		line_row.add_child(frame)
	var bubble:=PanelContainer.new();bubble.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var bubble_style:=Tokens.flat(colour.lerp(Tokens.PANEL_BG_SOLID,.90 if Tokens.is_light() else .86),colour,1,10,0)
	if ruler:bubble_style.border_width_right=4;bubble_style.corner_radius_top_right=2
	else:bubble_style.border_width_left=4;bubble_style.corner_radius_top_left=2
	bubble_style.content_margin_left=14;bubble_style.content_margin_right=14;bubble_style.content_margin_top=8;bubble_style.content_margin_bottom=10
	bubble.add_theme_stylebox_override("panel",bubble_style);line_row.add_child(bubble)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",2);bubble.add_child(stack)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);stack.add_child(head)
	var who:="You · your brief" if ruler else ("Your envoy" if role=="envoy" else leader_name)
	var name_label:=Tokens.make_label(who,14,colour);name_label.add_theme_font_override("font",_bold);head.add_child(name_label)
	var day:=int(turn.get("day",-1))
	head.add_child(Tokens.make_label("earlier" if day<0 else "day %d" % (day+1),12,Tokens.TEXT_DIM))
	var text:=Tokens.make_label(String(turn.get("content","")),16,Tokens.BODY);text.name="LineText";text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if ruler:text.add_theme_font_override("font",_italic)
	stack.add_child(text)
	return line_row

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

class RegardMeter extends Control:
	## Two gauges: love (or reverence) in gold above, dread in red below.
	var love:=.5
	var dread:=0.0
	var love_word:="LOVE"
	func _draw()->void:
		var font:=ThemeDB.fallback_font
		var label_w:=70.0
		var h:=size.y*.34
		for row in 2:
			var y:=row*size.y*.5+size.y*.08
			var value:=clampf(love if row==0 else dread,0,1)
			var colour:=Color("d9a93a") if row==0 else Color("c2453a")
			draw_string(font,Vector2(0,y+h),love_word if row==0 else "DREAD",HORIZONTAL_ALIGNMENT_LEFT,label_w,10,Color("e2d3b4"))
			var track:=Rect2(Vector2(label_w,y),Vector2(size.x-label_w,h))
			draw_rect(track,Color(colour,.18))
			draw_rect(Rect2(track.position,Vector2(track.size.x*value,h)),colour)

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
