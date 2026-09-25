extends VBoxContainer
## "The Known World": the world as your people know it. A chart drawn only from
## routes that physically returned (early eras: charcoal and ochre on a scraped
## hide; later: ink on paper), the peoples met and how they hold you, walkers
## abroad, and what the walkers carried home. Built from the plain model in
## dock_content_world.gd; every action is a Callable supplied by that model.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Kit:=preload("res://scripts/hud/artifact_gallery.gd")
## Inner classes reach the shared static helpers through this self-reference.
const KnownWorld:=preload("res://scripts/hud/known_world_board.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const DISPLAY_FONT:=preload("res://assets/fonts/cinzel/Cinzel.ttf")
const CHART_ART:="res://assets/ui/world/chart-tier-%d.png"
const CHART_HEIGHT:=470.0

var model:Dictionary={}
var tier:=0
var chart:Chart
var columns:GridContainer
var finds_grid:GridContainer
var counters_row:HFlowContainer
var plan_button:Button
var summon_button:Button
var archive_button:Button

func setup(block:Dictionary)->void:
	name="KnownWorldBoard"
	model=block.get("model",{})
	tier=int(model.get("tier",0))
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",18)
	_build_counters()
	_build_aims()
	chart=Chart.new();chart.name="KnownWorldChart";chart.data=model.get("chart",{});chart.tier=tier;chart.settlement=String(model.get("settlement","Our hearth"))
	chart.custom_minimum_size.y=CHART_HEIGHT;add_child(chart)
	columns=GridContainer.new();columns.name="PeoplesAndWalkers";columns.columns=2
	columns.add_theme_constant_override("h_separation",18);columns.add_theme_constant_override("v_separation",18);add_child(columns)
	_build_peoples(_sheet(columns,"Peoples"))
	_build_walkers(_sheet(columns,"Walkers"))
	_build_finds()
	resized.connect(_layout);_layout()

## "What we strive for": the live generational aim (legacy_aims.gd), its
## progress in the people's words, what rivals have sworn, and legacies won.
func _build_aims()->void:
	var aims:Dictionary=model.get("aims",{})
	var live:Dictionary=aims.get("active",{})
	var waiting:=String(aims.get("waiting",""))
	var rivals:Array=aims.get("rivals",[])
	var legacies:Array=aims.get("legacies",[])
	if live.is_empty() and waiting=="" and rivals.is_empty() and legacies.is_empty(): return
	var frame:=PanelContainer.new();frame.name="AimsSheet";frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel",sheet_style());add_child(frame)
	var stack:=VBoxContainer.new();stack.name="Aims";stack.add_theme_constant_override("separation",8);frame.add_child(stack)
	heading(stack,"WHAT WE STRIVE FOR",String(live.get("by","")) if not live.is_empty() else "")
	if not live.is_empty():
		var title:=Kit.serif(stack,String(live.get("title","")),24,T.INK,true);title.name="AimTitle"
		var bar:=AimBar.new();bar.name="AimProgress";bar.progress=float(live.get("progress",0.0));bar.marks=live.get("milestones",[]);bar.custom_minimum_size=Vector2(0,18);stack.add_child(bar)
		bar.tooltip_text=preload("res://scripts/hud/era_words.gd").way_along(float(live.get("progress",0.0)))
		var said:=String(live.get("words",""))
		var line:=Kit.label(stack,"%s · %s left" % [said.substr(0,1).to_upper()+said.substr(1),String(live.get("left",""))],13,T.BODY,false);line.name="AimWords"
		if String(live.get("clash",""))!="":
			Kit.label(stack,"%s have sworn against it." % String(live.clash),12,T.GOLD,false)
	elif waiting!="":
		Kit.serif(stack,"The people want an aim. Summon %s to hear it." % waiting,16,T.INK,true).name="AimWaiting"
	for rival:Dictionary in rivals:
		var row:=Kit.label(stack,"%s of %s has sworn to %s%s" % [String(rival.get("leader","")),String(rival.get("people","")),String(rival.get("phrase","")),(" (against our aim)" if bool(rival.get("clash",false)) else "")],12,T.TEXT_SOFT,false)
		row.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;row.name="Vow_"+String(rival.get("civ_id","")).validate_node_name()
	for legacy:Dictionary in legacies:
		var remembered:=Kit.serif(stack,"Remembered: %s, year %d" % [String(legacy.get("name","")),int(int(legacy.get("day",0))/365.0)+1],13,T.BODY,true)
		remembered.name="Legacy_%d" % int(legacy.get("day",0))

class AimBar extends Control:
	var progress:=0.0
	var marks:Array=[]
	func _ready()->void:resized.connect(queue_redraw)
	func _draw()->void:
		var h:=size.y*0.5
		var y:=(size.y-h)*0.5
		draw_rect(Rect2(0,y,size.x,h),Color(T.BORDER_SOFT,.5))
		draw_rect(Rect2(0,y,size.x*clampf(progress,0.0,1.0),h),T.GOLD)
		for mark in [25,50,75]:
			var x:=size.x*float(mark)/100.0
			draw_line(Vector2(x,y-3),Vector2(x,y+h+3),T.INK if int(mark) in marks else Color(T.INK,.35),1.5)

func _layout()->void:
	var width:=size.x if size.x>0 else 940.0
	columns.columns=2 if width>=720 else 1
	if finds_grid:finds_grid.columns=3 if width>=900 else (2 if width>=600 else 1)

# ---------------------------------------------------------------- pieces

static func sheet_style()->StyleBoxFlat:
	var style:=T.flat(Kit.plate_color(),T.BORDER_SOFT,1,6)
	style.content_margin_left=18;style.content_margin_right=18;style.content_margin_top=14;style.content_margin_bottom=16
	style.shadow_color=Color(0,0,0,.10 if T.is_light() else .3);style.shadow_size=5;style.shadow_offset=Vector2(0,2)
	return style

func _sheet(parent:Node,node_name:String)->VBoxContainer:
	var frame:=PanelContainer.new();frame.name=node_name+"Sheet";frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;frame.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	frame.add_theme_stylebox_override("panel",sheet_style());parent.add_child(frame)
	var stack:=VBoxContainer.new();stack.name=node_name;stack.add_theme_constant_override("separation",10);frame.add_child(stack)
	return stack

static func heading(parent:Node,text:String,note:String="")->HBoxContainer:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row)
	var title:=Kit.label(row,text,11,T.GOLD,false,.14);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if not note.is_empty():
		var aside:=Kit.serif(row,note,12,T.TEXT_SOFT,true);aside.size_flags_horizontal=Control.SIZE_SHRINK_END;aside.autowrap_mode=TextServer.AUTOWRAP_OFF
	return row

func _action(parent:Node,text:String,callback:Variant,primary:bool=false,tip:String="")->Button:
	var call:Callable=callback if callback is Callable else Callable()
	var button:=Kit.action_button(parent,text,call,primary,tip)
	return button

func _build_counters()->void:
	var counts:Dictionary=model.get("counters",{})
	counters_row=HFlowContainer.new();counters_row.name="Counters";counters_row.add_theme_constant_override("h_separation",10);counters_row.add_theme_constant_override("v_separation",10);add_child(counters_row)
	var peoples:=int(counts.get("peoples",0));var located:=int(counts.get("located",0))
	var away:=int(counts.get("away",0));var capacity:=maxi(1,int(counts.get("capacity",1)))
	var reports:=int(counts.get("reports",0));var unread:=int(counts.get("unread",0))
	var people_note:="only smoke on the horizon" if peoples==0 else ("%d hearth%s found" % [located,"" if located==1 else "s"] if located>0 else "no hearth yet found")
	var walker_note:="all are home by the fire" if away==0 else ("every party is out" if away>=capacity else "%d more could go" % (capacity-away))
	var tale_note:="%d not yet told" % unread if unread>0 else ("all have been heard" if reports>0 else "none yet")
	_counter("PEOPLES MET",str(peoples),people_note,"tent",T.AMBER)
	_counter("WALKERS ABROAD","%d/%d" % [away,capacity],walker_note,"walker",T.TEAL)
	_counter("TALES CARRIED HOME",str(reports),tale_note,"spiral",T.GOLD)
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;counters_row.add_child(spacer)
	var actions:Dictionary=model.get("actions",{})
	plan_button=_action(counters_row,"Plan an expedition",actions.get("plan"),true,"Choose where the walkers go, how many, how long, and what they carry.")
	plan_button.name="PlanExpedition";plan_button.custom_minimum_size=Vector2(208,50);plan_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	plan_button.add_theme_font_size_override("font_size",15)
	plan_button.add_theme_font_override("font",DISPLAY_FONT)
	var strong:=T.flat(T.GOLD_WASH,T.GOLD,2,4);strong.content_margin_left=18;strong.content_margin_right=18
	strong.bg_color=Color(T.GOLD,.22 if T.is_light() else .18)
	var strong_hover:=strong.duplicate() as StyleBoxFlat;strong_hover.bg_color=Color(T.GOLD,.34 if T.is_light() else .28)
	plan_button.add_theme_stylebox_override("normal",strong);plan_button.add_theme_stylebox_override("hover",strong_hover);plan_button.add_theme_stylebox_override("pressed",strong_hover)

func _counter(caption:String,value:String,note:String,glyph:String,tint:Color)->void:
	var counter:=Counter.new();counter.name="Counter_"+caption.replace(" ","_");counter.caption=caption;counter.value=value;counter.note=note;counter.glyph=glyph;counter.tint=tint
	counter.tooltip_text="%s · %s" % [caption.capitalize(),note]
	counters_row.add_child(counter)

func _build_peoples(stack:VBoxContainer)->void:
	var peoples:Array=model.get("peoples",[])
	var leads:Array=model.get("leads",[])
	var actions:Dictionary=model.get("actions",{})
	if peoples.is_empty():
		heading(stack,"BEYOND THE SMOKE","%d telling%s" % [leads.size(),"" if leads.size()==1 else "s"] if not leads.is_empty() else "")
		var ask:=Kit.serif(stack,"Who lives beyond the smoke?",24,T.INK,true);ask.name="BeyondTheSmoke"
		Kit.label(stack,"No other people has been met. The walkers bring home only what they saw, and what strangers told them on the road.",13,T.TEXT_SOFT)
		if leads.is_empty():
			Kit.serif(stack,"No one has yet spoken of other peoples.",14,T.MUTED,true)
		for lead:Dictionary in leads:stack.add_child(_lead_slip(lead))
	else:
		heading(stack,"PEOPLES WE HAVE MET","%d known" % peoples.size())
		for people:Dictionary in peoples:stack.add_child(_people_card(people))
		if not leads.is_empty():
			var names:PackedStringArray=[]
			for lead:Dictionary in leads:names.append(String(lead.get("name","")))
			Kit.serif(stack,"Still only told of: the %s." % ", the ".join(names),13,T.TEXT_SOFT,true)
	var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",8);row.add_theme_constant_override("v_separation",8);stack.add_child(row)
	var map_button:=_action(row,"Map of hearsay",actions.get("rumor_map"),false,"Where travelers' accounts place peoples we have not seen.");map_button.name="RumorMap"
	if not leads.is_empty():
		var follow:=_action(row,"Follow a telling",actions.get("plan"),false,"Plan an expedition toward one of the leads.");follow.name="FollowLead"
	var envoys:Dictionary=actions.get("envoys",{})
	if not peoples.is_empty() or not bool(envoys.get("disabled",true)):
		var envoy_button:=_action(row,String(envoys.get("label","Send envoys")),envoys.get("on_press"),false,String(envoys.get("tip","")))
		envoy_button.name="SendEnvoys";envoy_button.disabled=bool(envoys.get("disabled",false))

func _lead_slip(lead:Dictionary)->Control:
	var slip:=PanelContainer.new();slip.name="Lead_"+String(lead.get("name","")).validate_node_name()
	var paper:=Color("efe3c8") if T.is_light() else Color("1c2322")
	var style:=T.flat(paper,Color(T.GOLD,.45),1,3);style.content_margin_left=16;style.content_margin_right=14;style.content_margin_top=10;style.content_margin_bottom=10
	style.shadow_color=Color(0,0,0,.14);style.shadow_size=3;style.shadow_offset=Vector2(1,2)
	slip.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",4);slip.add_child(column)
	Kit.serif(column,"“%s”" % String(lead.get("text","")),14,T.BODY,true)
	var meta:=HBoxContainer.new();meta.add_theme_constant_override("separation",8);column.add_child(meta)
	Kit.label(meta,String(lead.get("word","")),11,T.GOLD,false)
	var dots:=Dots.new();dots.amount=clampf(float(lead.get("confidence",0.0))/.5,0,1);meta.add_child(dots)
	var searched:=int(lead.get("searched",0))
	if searched>0:Kit.label(meta,"searched %d time%s, not found" % [searched,"" if searched==1 else "s"],11,T.MUTED,false)
	if bool(lead.get("stale",false)):Kit.label(meta,"an old telling",11,T.MUTED,false)
	return slip

func _people_card(people:Dictionary)->Control:
	var card:=HBoxContainer.new();card.name="People_"+String(people.get("civ_id","")).validate_node_name();card.add_theme_constant_override("separation",14)
	var medal:=Medallion.new();medal.person=people.get("leader",{});medal.mark=int(people.get("mark",0));medal.pigment=int(people.get("pigment",0));medal.custom_minimum_size=Vector2(84,84);medal.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	medal.tooltip_text=String(people.get("leader_name",""));card.add_child(medal)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",3);card.add_child(words)
	Kit.serif(words,String(people.get("name","")),20)
	var leader:=String(people.get("leader_name",""))
	if not leader.is_empty():
		var temperament:=String(people.get("temperament","")).to_lower()
		Kit.label(words,"Led by %s%s" % [leader,(", "+("an " if temperament.substr(0,1) in ["a","e","i","o","u"] else "a ")+temperament) if not temperament.is_empty() else ""],12,T.BODY)
	var regard_row:=HBoxContainer.new();regard_row.add_theme_constant_override("separation",6);words.add_child(regard_row)
	var meter:=TextureRect.new();meter.texture=Divine.meter_texture(float(people.get("love",.5)),float(people.get("dread",0.0)),20);meter.custom_minimum_size=Vector2(20,20);meter.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;meter.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	meter.tooltip_text=Divine.meter_words(float(people.get("love",.5)),float(people.get("dread",0.0)));regard_row.add_child(meter)
	var regard:=Kit.serif(regard_row,"They "+String(people.get("regard","are undecided about you")),14,regard_color(String(people.get("regard_id",""))),true);regard.name="Regard"
	var where:=String(people.get("where",""))
	if not where.is_empty():Kit.label(words,where+(" · "+String(people.get("met","")) if not String(people.get("met","")).is_empty() else ""),11,T.TEXT_SOFT)
	var last:=String(people.get("last_word","")).strip_edges()
	var quote:=Kit.serif(words,("“%s”" % (last if last.length()<=150 else last.substr(0,147)+"…")) if not last.is_empty() else "No word has yet passed between you.",13,T.BODY if not last.is_empty() else T.MUTED,true)
	quote.name="LastWord"
	var vow:Dictionary=people.get("aim",{})
	if not vow.is_empty():
		var sworn:=Kit.label(words,"%s has sworn to %s" % [String(vow.get("leader","Their chief")),String(vow.get("phrase",""))],12,T.GOLD,false);sworn.name="RivalAim"
		sworn.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var buttons:=HBoxContainer.new();buttons.add_theme_constant_override("separation",8);words.add_child(buttons)
	var speak:=_action(buttons,"Send word",people.get("on_speak"),true,"Their leader is heard in the court.");speak.name="SendWord"
	var record:=_action(buttons,"What we know",people.get("on_record"),false,"Everything that has returned about them.");record.name="KnownRecord"
	return card

static func regard_color(id:String)->Color:
	match id:
		"war","fear":return T.RED
		"awe","honor":return T.GOLD_BRIGHT if T.is_light() else T.GOLD
		"scorn","wary":return T.AMBER
	return T.TEXT_SOFT

func _build_walkers(stack:VBoxContainer)->void:
	var parties:Array=model.get("parties",[])
	var counts:Dictionary=model.get("counters",{})
	heading(stack,"WALKERS ABROAD","%d of %d parties out" % [int(counts.get("away",0)),maxi(1,int(counts.get("capacity",1)))])
	if parties.is_empty():
		var home:=Kit.serif(stack,"Every walker is home by the fire.",20,T.INK,true);home.name="AllHome"
		Kit.label(stack,"A party carries food and a few strong walkers into country no one has named. What they see comes home only with them.",13,T.TEXT_SOFT)
	for party:Dictionary in parties:
		var card:=VBoxContainer.new();card.name="Party_%d" % int(party.get("id",0));card.add_theme_constant_override("separation",4);card.tooltip_text=String(party.get("tip",""));card.mouse_filter=Control.MOUSE_FILTER_PASS;stack.add_child(card)
		Kit.serif(card,String(party.get("title","Into unwalked country")),17)
		var path:=PartyPath.new();path.progress=float(party.get("progress",0.0));path.overdue=int(party.get("overdue",0))>0;path.turning=bool(party.get("turning_back",false));path.custom_minimum_size.y=58;path.tooltip_text=String(party.get("tip",""));card.add_child(path)
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",8);card.add_child(line)
		Kit.label(line,"%d walker%s%s" % [int(party.get("personnel",0)),"" if int(party.get("personnel",0))==1 else "s",(" from "+String(party.get("from",""))) if not String(party.get("from","")).is_empty() else ""],12,T.TEXT_SOFT,false).size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var when:=Kit.serif(line,String(party.get("when","")),13,T.RED if int(party.get("overdue",0))>0 else T.TEAL,true);when.autowrap_mode=TextServer.AUTOWRAP_OFF;when.size_flags_horizontal=Control.SIZE_SHRINK_END;when.name="When"
	Kit.label(stack,"Nothing they see is known until they walk back in; the day of return is only a reckoning.",11,T.MUTED)

func _build_finds()->void:
	var stack:=_sheet(self,"Finds")
	var groups:Array=model.get("finds",[])
	var counts:Dictionary=model.get("counters",{})
	var unread:=int(counts.get("unread",0))
	heading(stack,"CARRIED HOME","● %d telling%s not yet heard" % [unread,"" if unread==1 else "s"] if unread>0 else "")
	if groups.is_empty():
		Kit.serif(stack,"Nothing has been carried home yet. The first walkers back will lay their finds here.",15,T.TEXT_SOFT,true)
	else:
		finds_grid=GridContainer.new();finds_grid.name="FindGroups";finds_grid.columns=3;finds_grid.add_theme_constant_override("h_separation",14);finds_grid.add_theme_constant_override("v_separation",14);stack.add_child(finds_grid)
		for group:Dictionary in groups:finds_grid.add_child(_find_group(group))
	var actions:Dictionary=model.get("actions",{})
	var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",10);row.add_theme_constant_override("v_separation",8);stack.add_child(row)
	summon_button=_action(row,String(actions.get("summon_label","Summon your Chief Scout")),actions.get("summon"),true,String(actions.get("summon_tip","")))
	summon_button.name="SummonChiefScout";summon_button.custom_minimum_size.y=40
	archive_button=_action(row,"Every telling · %d" % int(counts.get("reports",0)),actions.get("archive"),false,"Search and read every retained report.")
	archive_button.name="OpenArchive";archive_button.custom_minimum_size.y=40
	var hint:=Kit.serif(row,"The Chief Scout tells what the walkers saw.",12,T.MUTED,true);hint.autowrap_mode=TextServer.AUTOWRAP_OFF;hint.size_flags_vertical=Control.SIZE_SHRINK_CENTER

func _find_group(group:Dictionary)->Control:
	var frame:=PanelContainer.new();frame.name="Group_"+String(group.get("party","")).validate_node_name();frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style:=T.flat(Color(T.TRACK,.28),Color(T.GOLD,.55) if bool(group.get("unread",false)) else T.BORDER_SOFT,1,5);style.set_content_margin_all(10)
	frame.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);frame.add_child(column)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);column.add_child(top)
	var title:=Kit.serif(top,String(group.get("party","")),15);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.autowrap_mode=TextServer.AUTOWRAP_OFF
	if bool(group.get("unread",false)):
		var mark:=Kit.label(top,"● not yet told",10,T.GOLD,false);mark.name="UnreadMark";mark.tooltip_text="The Chief Scout has not yet told this one."
	var sub:=Kit.label(column,"%s · %s" % [String(group.get("date","")),String(group.get("place",""))],11,T.TEXT_SOFT,false);sub.clip_text=true;sub.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;sub.custom_minimum_size.x=40
	var shelf:=HBoxContainer.new();shelf.add_theme_constant_override("separation",6);column.add_child(shelf)
	for item:Dictionary in group.get("items",[]):shelf.add_child(FindTile.make(item))
	if int(group.get("more",0))>0:
		var more:=Kit.label(shelf,"+%d" % int(group.more),13,T.MUTED,false);more.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var open:=Kit.action_button(column,"Read the telling",group.get("on_open",Callable()),false,"The full returned report.")
	open.name="ReadTelling";open.custom_minimum_size.y=28;open.add_theme_font_size_override("font_size",12);open.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var flat:=T.flat(Color(0,0,0,0),Color(0,0,0,0),0,3);flat.content_margin_left=4;flat.content_margin_right=4
	open.add_theme_stylebox_override("normal",flat);open.add_theme_color_override("font_color",T.GOLD_BRIGHT if T.is_light() else T.GOLD)
	return frame

# ================================================================ palette

static func ink(role:String,chart_tier:int=0)->Color:
	## The chart's pigments: charcoal and ochres on hide, iron-gall ink on paper.
	var light:=T.is_light()
	var paper:=chart_tier>=2
	match role:
		"base":return (Color("ecdfc2") if paper else Color("dcc59e")) if light else (Color("313a3a") if paper else Color("3a2f24"))
		"edge":return (Color("c9ad7f") if paper else Color("a88457")) if light else (Color("1a2021") if paper else Color("1e1812"))
		"grain":return (Color("b89c70") if paper else Color("9e7b50")) if light else (Color("3a4244") if paper else Color("554434"))
		"fog":return (Color(.95,.93,.88,.66) if paper else Color(.52,.41,.28,.58)) if light else (Color(.13,.155,.16,.7) if paper else Color(.12,.095,.07,.78))
		"line":return (Color("2c2a31") if paper else Color("3a2718")) if light else (Color("dfe2da") if paper else Color("eadcbf"))
		"red":return (Color("9b3526") if paper else Color("a4431c")) if light else Color("e0845c")
		"yellow":return (Color("7e560c") if paper else Color("8a5a0e")) if light else Color("e3b65c")
		"faint":return (Color("6d5a44") if paper else Color("6b523a")) if light else Color("b3a080")
		"halo":return (Color("ecdfc2") if paper else Color("dcc59e")) if light else (Color("313a3a") if paper else Color("3a2f24"))
	return Color.MAGENTA

static func pigment(index:int)->Color:
	var light:=[Color("a4431c"),Color("b07a17"),Color("3f4f5c"),Color("5b6f3a"),Color("7d5a7a")]
	var dark:=[Color("d9805a"),Color("ddb35c"),Color("93a8b8"),Color("9fb57a"),Color("c29ec0")]
	return (light if T.is_light() else dark)[posmod(index,5)]

# ================================================================ glyphs

static func glyph(ci:CanvasItem,kind:String,c:Vector2,s:float,col:Color,width:float=1.6)->void:
	## Small hand-drawn pictographs shared by the chart, counters and tiles.
	match kind:
		"fire":
			var base:=c+Vector2(0,s*.55)
			ci.draw_line(base+Vector2(-s*.7,s*.15),base+Vector2(s*.7,-s*.15),Color(col.darkened(.4),.9),width*1.2,true)
			ci.draw_line(base+Vector2(-s*.7,-s*.15),base+Vector2(s*.7,s*.15),Color(col.darkened(.4),.9),width*1.2,true)
			ci.draw_colored_polygon(_flame(c+Vector2(0,s*.1),s*1.05),Color("b23a16") if T.is_light() else Color("e0663a"))
			ci.draw_colored_polygon(_flame(c+Vector2(0,s*.3),s*.62),Color("e2a12e") if T.is_light() else Color("f2c65c"))
		"walker":
			var head:=c+Vector2(s*.08,-s*.78)
			ci.draw_circle(head,s*.22,col)
			ci.draw_line(head+Vector2(0,s*.2),c+Vector2(-s*.04,s*.15),col,width,true)
			ci.draw_line(c+Vector2(-s*.04,s*.15),c+Vector2(s*.38,s*.85),col,width,true)
			ci.draw_line(c+Vector2(-s*.04,s*.15),c+Vector2(-s*.42,s*.85),col,width,true)
			ci.draw_line(c+Vector2(0,-s*.35),c+Vector2(s*.42,-s*.05),col,width,true)
			ci.draw_line(c+Vector2(s*.5,-s*.75),c+Vector2(s*.5,s*.9),col,width*.8,true)
			ci.draw_line(c+Vector2(0,-s*.4),c+Vector2(-s*.36,-s*.12),col,width,true)
			ci.draw_circle(c+Vector2(-s*.42,-s*.2),s*.17,col)
		"tree":
			for dx:float in [-s*.5,s*.45]:
				var t:=c+Vector2(dx,0)
				ci.draw_line(t+Vector2(0,s*.6),t+Vector2(0,-s*.1),col,width,true)
				ci.draw_colored_polygon(PackedVector2Array([t+Vector2(0,-s*.75),t+Vector2(s*.38,s*.1),t+Vector2(-s*.38,s*.1)]),Color(col,.85))
		"peak":
			ci.draw_polyline(PackedVector2Array([c+Vector2(-s,s*.6),c+Vector2(-s*.35,-s*.55),c+Vector2(0,0),c+Vector2(s*.4,-s*.7),c+Vector2(s,s*.6)]),col,width,true)
			ci.draw_line(c+Vector2(s*.4,-s*.7),c+Vector2(s*.25,-s*.35),col,width*.8,true)
		"wave":
			for row:int in 3:
				var y:=c.y+(row-1)*s*.45
				var pts:=PackedVector2Array()
				for i:int in 9:pts.append(Vector2(c.x-s+i*s*.25,y+sin(i*1.6)*s*.12))
				ci.draw_polyline(pts,col,width*.9,true)
		"dune":
			for i:int in 3:ci.draw_arc(c+Vector2((i-1)*s*.55,s*.2),s*.35,PI,TAU,10,col,width*.9,true)
			for i:int in 4:ci.draw_circle(c+Vector2((i-1.5)*s*.4,s*.55),s*.06,col)
		"stone":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-s*.7,s*.4),c+Vector2(-s*.4,-s*.3),c+Vector2(s*.2,-s*.5),c+Vector2(s*.7,0),c+Vector2(s*.5,s*.45)]),Color(col,.85))
		"grass":
			for i:int in 5:
				var x:=(i-2)*s*.28
				ci.draw_line(c+Vector2(x,s*.55),c+Vector2(x*1.5+sin(i)*s*.1,-s*.6+absf(i-2)*s*.2),col,width*.9,true)
		"sprout":
			ci.draw_line(c+Vector2(0,s*.6),c+Vector2(0,-s*.3),col,width,true)
			ci.draw_arc(c+Vector2(-s*.3,-s*.25),s*.3,-PI*.1,PI*.6,8,col,width,true)
			ci.draw_arc(c+Vector2(s*.3,-s*.4),s*.3,PI*.4,PI*1.1,8,col,width,true)
			ci.draw_line(c+Vector2(-s*.7,s*.6),c+Vector2(s*.7,s*.6),col,width,true)
		"antler":
			ci.draw_polyline(PackedVector2Array([c+Vector2(0,s*.7),c+Vector2(0,0),c+Vector2(-s*.6,-s*.7)]),col,width,true)
			ci.draw_line(c+Vector2(0,0),c+Vector2(s*.6,-s*.7),col,width,true)
			ci.draw_line(c+Vector2(-s*.3,-s*.35),c+Vector2(-s*.65,-s*.2),col,width,true)
			ci.draw_line(c+Vector2(s*.3,-s*.35),c+Vector2(s*.65,-s*.2),col,width,true)
		"pot":
			ci.draw_arc(c+Vector2(0,s*.1),s*.55,-PI*.15,PI*1.15,18,col,width,true)
			ci.draw_line(c+Vector2(-s*.35,-s*.5),c+Vector2(s*.35,-s*.5),col,width,true)
		"spiral":
			var pts:=PackedVector2Array()
			for i:int in 40:
				var a:=i*.42;var r:=s*.08+s*.022*i
				pts.append(c+Vector2(cos(a),sin(a))*r)
			ci.draw_polyline(pts,col,width,true)
		"tent":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-s*.75),c+Vector2(s*.75,s*.6),c+Vector2(-s*.75,s*.6)]),Color(col,.9))
			ci.draw_line(c+Vector2(-s*.2,-s*.95),c+Vector2(s*.1,-s*.55),col,width,true)
			ci.draw_line(c+Vector2(s*.2,-s*.95),c+Vector2(-s*.1,-s*.55),col,width,true)
		"spears":
			ci.draw_line(c+Vector2(-s*.7,s*.7),c+Vector2(s*.7,-s*.7),col,width,true)
			ci.draw_line(c+Vector2(s*.7,s*.7),c+Vector2(-s*.7,-s*.7),col,width,true)
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(s*.7,-s*.7),c+Vector2(s*.35,-s*.6),c+Vector2(s*.6,-s*.35)]),col)
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-s*.7,-s*.7),c+Vector2(-s*.35,-s*.6),c+Vector2(-s*.6,-s*.35)]),col)
		"ear":
			ci.draw_arc(c,s*.55,-PI*.9,PI*.5,16,col,width,true)
			ci.draw_arc(c+Vector2(s*.05,0),s*.25,-PI*.8,PI*.3,10,col,width*.8,true)
			for i:int in 3:ci.draw_arc(c+Vector2(-s*.2,0),s*(.75+i*.22),PI*.8,PI*1.2,6,Color(col,.6-.15*i),width*.7,true)
		"hands":
			for side:float in [-1.0,1.0]:
				var h:=c+Vector2(side*s*.32,0)
				ci.draw_circle(h+Vector2(0,s*.15),s*.25,col)
				for f:int in 4:ci.draw_line(h+Vector2((f-1.5)*s*.12,0),h+Vector2((f-1.5)*s*.16,-s*.55),col,width*.8,true)
		"people":
			for dx:float in [-s*.38,s*.38]:
				var p:=c+Vector2(dx,0)
				ci.draw_circle(p+Vector2(0,-s*.5),s*.2,col)
				ci.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-s*.28),p+Vector2(s*.3,s*.65),p+Vector2(-s*.3,s*.65)]),Color(col,.9))
		"cairn":
			ci.draw_circle(c+Vector2(0,s*.4),s*.32,col);ci.draw_circle(c+Vector2(0,-s*.05),s*.24,col);ci.draw_circle(c+Vector2(0,-s*.42),s*.16,col)
		"sun":
			ci.draw_arc(c,s*.38,0,TAU,20,col,width,true)
			for i:int in 8:
				var a:=TAU*i/8.0
				ci.draw_line(c+Vector2(cos(a),sin(a))*s*.55,c+Vector2(cos(a),sin(a))*s*.85,col,width*.9,true)
		"fish":
			ci.draw_arc(c+Vector2(-s*.1,-s*.35),s*.6,PI*.2,PI*.8,10,col,width,true)
			ci.draw_arc(c+Vector2(-s*.1,s*.35),s*.6,-PI*.8,-PI*.2,10,col,width,true)
			ci.draw_polyline(PackedVector2Array([c+Vector2(s*.35,0),c+Vector2(s*.75,-s*.3),c+Vector2(s*.75,s*.3),c+Vector2(s*.35,0)]),col,width,true)
			ci.draw_circle(c+Vector2(-s*.4,-s*.05),s*.06,col)
		"crescent":
			ci.draw_arc(c,s*.6,PI*.35,PI*1.65,18,col,width*1.4,true)
			ci.draw_arc(c+Vector2(-s*.25,0),s*.45,PI*.5,PI*1.5,14,col,width*.8,true)
		"question":
			var font:=Kit.italic_font();var fs:=int(s*2.0)
			var w:=font.get_string_size("?",HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
			ci.draw_string(font,c+Vector2(-w*.5,fs*.34),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,fs,col)
		_:
			ci.draw_arc(c,s*.45,0,TAU,16,col,width,true);ci.draw_circle(c,s*.12,col)

static func _flame(c:Vector2,s:float)->PackedVector2Array:
	var pts:=PackedVector2Array()
	for i:int in 14:
		var t:=float(i)/13.0;var a:=lerpf(-PI*.5,PI*1.5,t)
		var r:=s*.62*(1.0-.5*maxf(0,-sin(a)))
		pts.append(c+Vector2(cos(a)*r*.8,sin(a)*r*.55+s*.1))
	pts.insert(0,c+Vector2(0,-s*1.05))
	return pts

const TOTEMS:=["spiral","sun","antler","fish","wave","crescent"]

static func resource_glyph(resource:String,kind:String)->String:
	var lower:=resource.to_lower()
	if "timber" in lower or "wood" in lower:return "tree"
	if "fiber" in lower or "reed" in lower or "flax" in lower:return "grass"
	if "soil" in lower or "grain" in lower:return "sprout"
	if "game" in lower or "herd" in lower:return "antler"
	if "clay" in lower:return "pot"
	if "stone" in lower or "flint" in lower or "ore" in lower or "copper" in lower or "salt" in lower:return "stone"
	match kind:
		"artifact":return "spiral"
		"intelligence":return "spears"
		"hearsay":return "ear"
		"encounter":return "people"
		"knowledge":return "hands"
		"contact":return "tent"
		"recruits":return "people"
		"losses":return "cairn"
		"deposit","resource":return "stone"
	return "spiral"

# ================================================================ drawing classes

class Counter extends Control:
	var caption:=""
	var value:=""
	var note:=""
	var glyph:="spiral"
	var tint:=Color.WHITE
	func _init()->void:custom_minimum_size=Vector2(206,62);mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var c:=Vector2(26,size.y*.5)
		draw_circle(c,24,Color(tint,.12))
		draw_arc(c,24,0,TAU,40,Color(tint,.7),1.2,true)
		draw_arc(c,20.5,0,TAU,40,Color(tint,.3),1.0,true)
		KnownWorld.glyph(self,glyph,c,11,tint,1.7)
		var x:=60.0
		var fs:=28
		draw_string(DISPLAY_FONT,Vector2(x,31),value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,T.INK)
		var vw:=DISPLAY_FONT.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		var font:=ThemeDB.fallback_font
		draw_string(font,Vector2(x+vw+8,22),caption,HORIZONTAL_ALIGNMENT_LEFT,maxf(10,size.x-x-vw-8),9,T.GOLD)
		draw_string(Kit.italic_font(),Vector2(x,52),note,HORIZONTAL_ALIGNMENT_LEFT,size.x-x,12,T.TEXT_SOFT)

class Dots extends Control:
	var amount:=0.0
	func _init()->void:custom_minimum_size=Vector2(44,12);size_flags_vertical=Control.SIZE_SHRINK_CENTER;mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		for i:int in 5:
			var c:=Vector2(4+i*9,size.y*.5)
			if float(i)<amount*5.0-.01:draw_circle(c,3,T.GOLD)
			else:draw_arc(c,3,0,TAU,12,Color(T.GOLD,.45),1.0,true)

class Medallion extends Control:
	## A people's medallion: the leader's likeness in a pigment ring, or their mark.
	var person:Dictionary={}
	var mark:=0
	var pigment:=0
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var c:=size*.5;var r:=minf(size.x,size.y)*.5-2
		var tone:=KnownWorld.pigment(pigment)
		draw_circle(c,r,tone)
		draw_arc(c,r-3.5,0,TAU,64,Color(T.GOLD_BRIGHT if T.is_light() else T.GOLD,.9),1.2,true)
		var inner:=r-6.0
		var texture:Texture2D=Portrait.texture(person) if not person.is_empty() else null
		if texture!=null:
			var base:Texture2D=texture;var region:=Rect2(Vector2.ZERO,texture.get_size())
			if texture is AtlasTexture:base=(texture as AtlasTexture).atlas;region=(texture as AtlasTexture).region
			var full:=base.get_size()
			var side:=minf(region.size.x,region.size.y)*.92
			var focus:=region.position+Vector2(region.size.x*.5,minf(region.size.y*.42,region.size.y-side*.5))
			var pts:=PackedVector2Array();var uvs:=PackedVector2Array()
			for i:int in 48:
				var a:=TAU*i/48.0;var d:=Vector2(cos(a),sin(a))
				pts.append(c+d*inner);uvs.append((focus+d*side*.5)/full)
			draw_colored_polygon(pts,Color.WHITE,uvs,base)
		else:
			draw_circle(c,inner,Kit.plate_color())
			KnownWorld.glyph(self,KnownWorld.TOTEMS[posmod(mark,6)],c,inner*.62,tone,2.2)
		draw_arc(c,inner,0,TAU,64,Color(0,0,0,.25),1.0,true)
		# the people's mark rides on the ring
		var badge:=c+Vector2(r*.72,r*.72)
		draw_circle(badge,11,Kit.plate_color());draw_arc(badge,11,0,TAU,24,tone,1.5,true)
		KnownWorld.glyph(self,KnownWorld.TOTEMS[posmod(mark,6)],badge,7,tone,1.3)

class PartyPath extends Control:
	## Home fire, the loop out and back, and where the walkers are reckoned to be.
	var progress:=0.0
	var overdue:=false
	var turning:=false
	func _init()->void:size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_filter=Control.MOUSE_FILTER_PASS
	func _point(t:float)->Vector2:
		var left:=Vector2(22,size.y*.5);var right:=Vector2(size.x-22,size.y*.5)
		var mid:=(left+right)*.5;var rx:=(right.x-left.x)*.5;var ry:=size.y*.36
		var a:=PI+t*TAU
		return mid+Vector2(cos(a)*rx,sin(a)*ry*(1.0 if t<.5 else .8))
	func _draw()->void:
		var line:=Color(T.TEXT_SOFT,.55);var done:=T.TEAL if not overdue else T.RED
		var steps:=64
		var at:=clampf(progress,0,1)
		for i:int in steps:
			var t0:=float(i)/steps;var t1:=float(i+1)/steps
			var a:=_point(t0);var b:=_point(t1)
			if t1<=at:draw_line(a,b,Color(done,.85),2.0,true)
			elif i%2==0:draw_line(a,b,line,1.2,true)
		KnownWorld.glyph(self,"fire",Vector2(22,size.y*.5),9,T.GOLD)
		var far:=Vector2(size.x-22,size.y*.5)
		KnownWorld.glyph(self,"question",far,7,Color(T.GOLD,.8))
		var p:=_point(at)
		draw_circle(p,11,Color(Kit.plate_color(),.95));draw_arc(p,11,0,TAU,24,done,1.4,true)
		KnownWorld.glyph(self,"walker",p,7.5,done,1.5)
		var font:=Kit.italic_font()
		draw_string(font,Vector2(40,12),"outward",HORIZONTAL_ALIGNMENT_LEFT,-1,10,T.MUTED)
		draw_string(font,Vector2(40,size.y-2),"homeward" if not turning else "turned back",HORIZONTAL_ALIGNMENT_LEFT,-1,10,T.RED if turning else T.MUTED)

class FindTile extends VBoxContainer:
	var item:Dictionary={}
	static func make(entry:Dictionary)->FindTile:
		var tile:=FindTile.new();tile.item=entry;return tile
	func _ready()->void:
		name="Find_"+String(item.get("kind","")).validate_node_name()
		add_theme_constant_override("separation",3);custom_minimum_size.x=80;size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		mouse_filter=Control.MOUSE_FILTER_STOP;mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		tooltip_text="%s\n%s" % [String(item.get("title","")),String(item.get("sub",""))]
		var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(64,64);frame.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var texture:Variant=item.get("texture")
		var tier_tone:=Kit.tier_color(int(item.get("rarity_index",0))) if String(item.get("kind",""))=="artifact" else T.BORDER_SOFT
		var style:=T.flat(Color("ece4d4") if texture is Texture2D else Color(T.TRACK,.45),tier_tone,1,3);style.set_content_margin_all(2)
		frame.add_theme_stylebox_override("panel",style);add_child(frame)
		if texture is Texture2D:
			var art:=TextureRect.new();art.texture=texture;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.mouse_filter=Control.MOUSE_FILTER_IGNORE
			art.material=Kit.veil_material(Kit.veil_for({"state":String(item.get("state","")),"study_progress":float(item.get("study",0.0))}),.2);frame.add_child(art)
		else:
			var mark:=GlyphBox.new();mark.kind=KnownWorld.resource_glyph(String(item.get("resource","")),String(item.get("kind","")));mark.tone=T.RED if String(item.get("kind",""))=="losses" else T.GOLD;frame.add_child(mark)
		var caption:=Kit.label(self,String(item.get("title","")),11,T.BODY);caption.max_lines_visible=2;caption.custom_minimum_size=Vector2(80,32);caption.size_flags_horizontal=Control.SIZE_FILL;caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		gui_input.connect(_on_input)
	func _on_input(event:InputEvent)->void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
			accept_event();activate()
	func activate()->void:
		var callback:Variant=item.get("on_open")
		if callback is Callable and (callback as Callable).is_valid():(callback as Callable).call()

class GlyphBox extends Control:
	var kind:="spiral"
	var tone:=Color.WHITE
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:KnownWorld.glyph(self,kind,size*.5,minf(size.x,size.y)*.3,tone,1.8)

# ================================================================ the chart

const PAPER_CODE:="""
shader_type canvas_item;
uniform vec2 px_size=vec2(900.0,470.0);
uniform vec4 base_color:source_color;
uniform vec4 edge_color:source_color;
uniform vec4 grain_color:source_color;
uniform vec4 fog_color:source_color;
uniform float hide_shape=1.0;
uniform float seed=0.0;
uniform int count=0;
uniform vec4 known[96];
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7))+seed)*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);vec2 u=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),u.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0,1.0)),u.x),u.y);}
float fbm(vec2 p){float v=0.0;float a=0.5;for(int i=0;i<4;i++){v+=a*noise(p);p=p*2.03+vec2(17.0,9.0);a*=0.5;}return v;}
void fragment(){
	vec2 p=UV*px_size;
	float inset=mix(2.0,14.0,hide_shape);
	float radius=mix(3.0,46.0,hide_shape);
	vec2 q=abs(p-px_size*0.5)-(px_size*0.5-vec2(inset)-vec2(radius));
	float sdf=length(max(q,0.0))+min(max(q.x,q.y),0.0)-radius;
	sdf+=(fbm(p*0.016)-0.5)*30.0*hide_shape+(fbm(p*0.09)-0.5)*mix(1.5,6.0,hide_shape);
	float alpha=1.0-smoothstep(-1.2,0.8,sdf);
	float inner=clamp(-sdf/80.0,0.0,1.0);
	vec3 col=mix(edge_color.rgb,base_color.rgb,smoothstep(0.0,1.0,inner));
	float grain=fbm(p*0.22);
	float fibers=noise(vec2(p.x*0.012,p.y*0.42));
	col=mix(col,grain_color.rgb,clamp((grain-0.45)*0.55+(fibers-0.5)*0.22*hide_shape,0.0,1.0));
	float stain=smoothstep(0.6,0.78,fbm(p*0.005+vec2(7.0,3.0)));
	col=mix(col,edge_color.rgb,stain*0.22);
	float m=99.0;
	for(int i=0;i<96;i++){if(i>=count){break;}vec4 k=known[i];m=min(m,length(p-k.xy)/max(k.z,1.0));}
	float cloud=fbm(p*0.011+vec2(3.0,11.0));
	float fog=smoothstep(0.8,1.9,m+(cloud-0.5)*1.1);
	col=mix(col,fog_color.rgb,fog*fog_color.a);
	col*=mix(0.8,1.0,smoothstep(0.0,0.3,inner));
	COLOR=vec4(col,alpha);
}
"""

static var _paper_shader:Shader

class Chart extends Control:
	var data:Dictionary={}
	var tier:=0
	var settlement:="Our hearth"
	var background:Control
	var ink_layer:InkLayer
	var map_scale:=1.0
	var map_offset:=Vector2.ZERO
	var inner:=Rect2()
	var hits:Array=[]
	func _ready()->void:
		clip_contents=true;size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_filter=Control.MOUSE_FILTER_PASS
		var art_path:=CHART_ART % tier
		if ResourceLoader.exists(art_path):
			var art:=TextureRect.new();art.name="ChartArt";art.texture=load(art_path) as Texture2D;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_SCALE
			art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);art.mouse_filter=Control.MOUSE_FILTER_IGNORE;background=art
		else:
			var paper:=ColorRect.new();paper.name="ChartPaper";paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
			if KnownWorld._paper_shader==null:KnownWorld._paper_shader=Shader.new();KnownWorld._paper_shader.code=KnownWorld.PAPER_CODE
			var material:=ShaderMaterial.new();material.shader=KnownWorld._paper_shader;paper.material=material;background=paper
		add_child(background)
		ink_layer=InkLayer.new();ink_layer.chart=self;ink_layer.name="Ink";ink_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(ink_layer)
		resized.connect(_refit);_refit()
	func home()->Vector2:
		var value:Variant=data.get("home",Vector2.ZERO)
		return value if value is Vector2 else Vector2.ZERO
	func pace()->float:return maxf(1.0,float(data.get("pace",14.0)))
	func known_points()->PackedVector2Array:
		var pts:=PackedVector2Array([home()])
		for trail:Dictionary in data.get("trails",[]):pts.append_array(trail.get("points",PackedVector2Array()))
		for place:Dictionary in data.get("places",[]):pts.append(place.pos)
		for people:Dictionary in data.get("peoples",[]):pts.append(people.pos)
		return pts
	func known_reach()->float:
		var reach:=pace()*6.0
		for p:Vector2 in known_points():reach=maxf(reach,p.distance_to(home()))
		return reach
	func rumor_in_frame(rumor:Dictionary)->bool:
		return (rumor.pos as Vector2).distance_to(home())<=known_reach()*1.6
	func _refit()->void:
		inner=Rect2(Vector2(70,78),size-Vector2(140,150))
		if inner.size.x<40 or inner.size.y<40:inner=Rect2(Vector2.ZERO,size)
		var pts:=known_points()
		for party:Dictionary in data.get("parties",[]):pts.append_array(party.get("route",PackedVector2Array()))
		for rumor:Dictionary in data.get("rumors",[]):
			if rumor_in_frame(rumor):pts.append(rumor.pos)
		var bounds:=Rect2(home(),Vector2.ZERO)
		for p:Vector2 in pts:bounds=bounds.expand(p)
		var minimum:=pace()*8.0
		bounds=bounds.grow_individual(maxf(0,(minimum-bounds.size.x)*.5),maxf(0,(minimum-bounds.size.y)*.5),maxf(0,(minimum-bounds.size.x)*.5),maxf(0,(minimum-bounds.size.y)*.5))
		map_scale=minf(inner.size.x/maxf(1.0,bounds.size.x),inner.size.y/maxf(1.0,bounds.size.y))
		map_offset=inner.get_center()-bounds.get_center()*map_scale
		_update_paper()
		if ink_layer:ink_layer.queue_redraw()
	func to_screen(p:Vector2)->Vector2:return p*map_scale+map_offset
	func _update_paper()->void:
		if not background is ColorRect or (background as ColorRect).material==null:return
		var material:=(background as ColorRect).material as ShaderMaterial
		material.set_shader_parameter("px_size",size)
		material.set_shader_parameter("base_color",KnownWorld.ink("base",tier))
		material.set_shader_parameter("edge_color",KnownWorld.ink("edge",tier))
		material.set_shader_parameter("grain_color",KnownWorld.ink("grain",tier))
		material.set_shader_parameter("fog_color",KnownWorld.ink("fog",tier))
		material.set_shader_parameter("hide_shape",1.0 if tier<2 else 0.0)
		material.set_shader_parameter("seed",float(posmod(settlement.hash(),997))*.37)
		var circles:=fog_circles()
		material.set_shader_parameter("count",circles.size())
		var padded:=circles.duplicate()
		while padded.size()<96:padded.append(Vector4.ZERO)
		material.set_shader_parameter("known",padded)
	func fog_circles()->PackedVector4Array:
		## Where the hide is inked: around home and along every returned trail.
		var result:=PackedVector4Array()
		var home_px:=to_screen(home())
		result.append(Vector4(home_px.x,home_px.y,maxf(70.0,pace()*2.2*map_scale),0))
		var spacing:=26.0
		var samples:=PackedVector2Array()
		for trail:Dictionary in data.get("trails",[]):
			var pts:PackedVector2Array=trail.get("points",PackedVector2Array())
			var last:=Vector2.INF
			for p:Vector2 in pts:
				var s:=to_screen(p)
				if last==Vector2.INF or s.distance_to(last)>=spacing:samples.append(s);last=s
			if not pts.is_empty():samples.append(to_screen(pts[pts.size()-1]))
		for place:Dictionary in data.get("places",[]):samples.append(to_screen(place.pos))
		for people:Dictionary in data.get("peoples",[]):samples.append(to_screen(people.pos))
		var stride:=maxi(1,ceili(float(samples.size())/95.0))
		for i:int in range(0,samples.size(),stride):
			if result.size()>=96:break
			var s:=samples[i]
			var near:=false
			for existing:Vector4 in result:
				if Vector2(existing.x,existing.y).distance_to(s)<spacing*.6:near=true;break
			if not near:result.append(Vector4(s.x,s.y,38.0,0))
		return result
	func add_hit(center:Vector2,radius:float,text:String)->void:
		hits.append({"c":center,"r":radius,"text":text})
	func tip_at(at:Vector2)->String:
		var best:="";var best_d:=INF
		for hit:Dictionary in hits:
			var d:=(hit.c as Vector2).distance_to(at)
			if d<=float(hit.r) and d<best_d:best=String(hit.text);best_d=d
		return best

class InkLayer extends Control:
	var chart:Chart
	var labels:Array[Rect2]=[]
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_PASS;tooltip_text=" "
	func _get_tooltip(at:Vector2)->String:
		return chart.tip_at(at) if chart else ""
	func c(role:String)->Color:return KnownWorld.ink(role,chart.tier)
	func label(text:String,at:Vector2,font_size:int,color:Color,italic:bool=true,prefer_left:bool=false,force:bool=false)->bool:
		var font:Font=Kit.italic_font() if italic else Kit.serif_font()
		var w:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var h:=float(font_size)+2.0
		var tries:=[Vector2(10,h*.35),Vector2(-10-w,h*.35),Vector2(-w*.5,-12),Vector2(-w*.5,h+8)]
		if prefer_left:tries=[tries[1],tries[0],tries[2],tries[3]]
		for offset:Vector2 in tries:
			var origin:=at+offset
			var box:=Rect2(origin-Vector2(2,h*.82),Vector2(w+4,h))
			if not Rect2(Vector2(6,6),size-Vector2(12,12)).encloses(box):continue
			var clash:=false
			if not force:
				for placed:Rect2 in labels:
					if placed.intersects(box):clash=true;break
			if clash:continue
			labels.append(box)
			draw_string_outline(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,4,Color(c("halo"),.85))
			draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
			return true
		return false
	func wobble_path(pts:PackedVector2Array,seed_value:int,amp:float)->PackedVector2Array:
		var out:=PackedVector2Array()
		for i:int in pts.size():
			var p:=chart.to_screen(pts[i])
			if i>0 and i<pts.size()-1:
				var n:=sin(float(i)*2.3+float(seed_value)*.7)*amp
				var dir:=(chart.to_screen(pts[i+1])-chart.to_screen(pts[i-1])).normalized()
				p+=Vector2(-dir.y,dir.x)*n
			out.append(p)
		return out
	func dashed(pts:PackedVector2Array,color:Color,width:float,dash:float,gap:float)->void:
		var carry:=0.0;var on:=true
		for i:int in range(1,pts.size()):
			var a:=pts[i-1];var b:=pts[i];var length:=a.distance_to(b);var t:=0.0
			while t<length:
				var step:=minf((dash if on else gap)-carry,length-t)
				if on:draw_line(a.lerp(b,t/length),a.lerp(b,(t+step)/length),color,width,true)
				t+=step;carry+=step
				if carry>=(dash if on else gap)-.001:carry=0.0;on=not on
	func footprints(pts:PackedVector2Array,color:Color)->void:
		var spacing:=8.0;var travelled:=0.0;var left:=true
		for i:int in range(1,pts.size()):
			var a:=pts[i-1];var b:=pts[i];var length:=a.distance_to(b)
			if length<.01:continue
			var dir:=(b-a)/length;var normal:=Vector2(-dir.y,dir.x)
			while travelled<length:
				var p:=a+dir*travelled+normal*(2.0 if left else -2.0)
				draw_set_transform(p,dir.angle(),Vector2(1.5,1.0))
				draw_circle(Vector2.ZERO,1.2,color)
				draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
				left=not left;travelled+=spacing
			travelled-=length
	func point_along(pts:PackedVector2Array,t:float)->Vector2:
		if pts.is_empty():return Vector2.ZERO
		var total:=0.0
		for i:int in range(1,pts.size()):total+=pts[i-1].distance_to(pts[i])
		var goal:=clampf(t,0,1)*total
		for i:int in range(1,pts.size()):
			var seg:=pts[i-1].distance_to(pts[i])
			if goal<=seg and seg>0:return pts[i-1].lerp(pts[i],goal/seg)
			goal-=seg
		return pts[pts.size()-1]
	func _draw()->void:
		if chart==null:return
		labels.clear();chart.hits.clear()
		var paper:=chart.tier>=2
		var line:=c("line");var red:=c("red");var yellow:=c("yellow");var faint:=c("faint")
		var home_px:=chart.to_screen(chart.home())
		labels.append(Rect2(Vector2(18,22),Vector2(380,46)))
		labels.append(Rect2(Vector2(18,size.y-44),Vector2(620,32)))
		labels.append(Rect2(Vector2(size.x-92,18),Vector2(80,90)))
		labels.append(Rect2(home_px-Vector2(18,18),Vector2(36,36)))
		# reckoning rings: days of walking from the hearth
		for days:int in [3,10,25]:
			var r:=float(days)*chart.pace()*chart.map_scale
			if r<28 or not Rect2(Vector2(24,24),size-Vector2(48,48)).encloses(Rect2(home_px-Vector2(r,r),Vector2(r,r)*2.0)):continue
			var pts:=PackedVector2Array()
			for i:int in 97:pts.append(home_px+Vector2(cos(TAU*i/96.0),sin(TAU*i/96.0))*r)
			dashed(pts,Color(faint,.35),1.0,3.0,6.0)
			var tag:=home_px+Vector2(0,-r)
			if Rect2(Vector2(20,20),size-Vector2(40,40)).has_point(tag):label("%d days" % days,tag+Vector2(-12,-3),11,Color(faint,.85),true,false,true)
		var trails:Array=chart.data.get("trails",[])
		# terrain seen at the far end of each walk
		var marked:Array[Vector2]=[]
		for trail:Dictionary in trails:
			var kind:=String(trail.get("terrain",""))
			if kind.is_empty():continue
			var far:=chart.to_screen(trail.far)
			var clash:=false
			for m:Vector2 in marked:
				if m.distance_to(far)<42:clash=true;break
			if clash:continue
			marked.append(far)
			var picto:=String({"forest":"tree","mountains":"peak","river":"wave","desert":"dune"}.get(kind,"tree"))
			var jitter:=Vector2(18,-16) if int(trail.rank)%2==0 else Vector2(-18,14)
			KnownWorld.glyph(self,picto,far+jitter,8,Color(faint,.75),1.3)
			chart.add_hit(far+jitter,14,"%s country, as the walkers told it" % kind.capitalize())
		# trails: older ones faint, the newest walked in footprints
		for i:int in range(trails.size()-1,-1,-1):
			var trail:Dictionary=trails[i]
			var rank:=int(trail.rank)
			var pts:=wobble_path(trail.points,rank,1.4)
			var fade:=clampf(1.0-float(rank)/float(maxi(8,trails.size())),.25,1.0)
			var tone:=red if bool(trail.get("lost",false)) else line
			if rank<3 and not paper:
				footprints(pts,Color(tone,.55+.3*fade))
			elif paper:
				draw_polyline(pts,Color(tone,.25+.55*fade),1.6 if rank<5 else 1.0,true)
			else:
				dashed(pts,Color(tone,.2+.45*fade),1.3,7.0,4.0)
			var back:PackedVector2Array=trail.get("return",PackedVector2Array())
			if rank<4 and back.size()>=2:dashed(wobble_path(back,rank+5,1.2),Color(tone,.25*fade),1.0,2.0,5.0)
			if not pts.is_empty():
				var end:=pts[pts.size()-1]
				draw_circle(end,2.2,Color(tone,.5*fade+.2))
				chart.add_hit(end,10,String(trail.get("title","A returned walk")))
		# the hearth
		draw_circle(home_px,19,Color(c("halo"),.9))
		KnownWorld.glyph(self,"fire",home_px,15,line)
		draw_arc(home_px,19,0,TAU,40,Color(red,.7),1.4,true)
		draw_arc(home_px,23,0,TAU,40,Color(red,.35),1.0,true)
		label(chart.settlement,home_px+Vector2(12,6),16,line,false,false,true)
		chart.add_hit(home_px,22,"%s · our hearth. Everything on this %s was carried home by walkers." % [chart.settlement,"chart" if paper else "hide"])
		# peoples met
		for people:Dictionary in chart.data.get("peoples",[]):
			var at:=chart.to_screen(people.pos)
			var tone:=KnownWorld.pigment(int(people.get("pigment",0)))
			draw_circle(at,13,Color(tone,.22))
			if bool(people.get("located",false)):draw_arc(at,13,0,TAU,32,tone,1.8,true)
			else:dashed(_circle(at,13),tone,1.6,3.0,3.0)
			KnownWorld.glyph(self,KnownWorld.TOTEMS[posmod(int(people.get("mark",0)),6)],at,8,tone,1.7)
			label(String(people.get("name","")),at+Vector2(8,0),15,tone,false,false,true)
			chart.add_hit(at,16,String(people.get("tip","")))
		# rumored lands: told of, never seen
		var hearsay:Array=chart.data.get("hearsay",[]).duplicate()
		for rumor:Dictionary in chart.data.get("rumors",[]):
			if not chart.rumor_in_frame(rumor):
				hearsay.append({"name":String(rumor.name),"direction":String(rumor.direction),"distance":"far"})
				continue
			var at:=chart.to_screen(rumor.pos)
			var r:=clampf(float(rumor.radius)*chart.map_scale,16,64)
			var alpha:=clampf(.35+float(rumor.confidence),.35,.85)
			dashed(_circle(at,r),Color(yellow,alpha*.8),1.3,5.0,5.0)
			KnownWorld.glyph(self,"question",at,11,Color(yellow,alpha))
			label("the %s?" % String(rumor.name),at+Vector2(0,r*.4),13,Color(yellow,minf(1.0,alpha+.15)),true,false,true)
			chart.add_hit(at,r,String(rumor.get("tip","")))
		_edge_marks(hearsay,home_px,yellow)
		# walkers abroad, where the settlement reckons them to be
		for party:Dictionary in chart.data.get("parties",[]):
			var route:PackedVector2Array=party.get("route",PackedVector2Array())
			var pts:=PackedVector2Array()
			for p:Vector2 in route:pts.append(chart.to_screen(p))
			dashed(pts,Color(red,.75),1.6,2.0,4.0)
			var progress:=clampf(float(party.get("progress",0.0)),0,1)
			var t:=progress if bool(party.get("circuit",false)) else (progress*2.0 if progress<.5 else (1.0-progress)*2.0)
			var at:=point_along(pts,t)
			var far:=pts[pts.size()-1] if not pts.is_empty() else at
			KnownWorld.glyph(self,"question",far,8,Color(red,.6))
			draw_circle(at,12,Color(c("halo"),.9));draw_arc(at,12,0,TAU,28,red,1.5,true)
			KnownWorld.glyph(self,"walker",at,8,red,1.6)
			var overdue:=int(party.get("overdue",0))
			var tag:="overdue %d days" % overdue if overdue>0 else ("home any day" if int(party.get("days",0))<=1 else "home in ~%d days" % int(party.get("days",0)))
			var party_text:="%d walkers · %s" % [int(party.get("personnel",0)),tag]
			if not label(party_text,at+Vector2(6,-2),13,red):label(party_text,at+Vector2(6,-2),13,red,true,false,true)
			chart.add_hit(at,16,"%s\n%d walkers · %s\nOnly a reckoning: what they see stays with them until they return." % [String(party.get("title","")),int(party.get("personnel",0)),tag])
		# places the walkers named
		for place:Dictionary in chart.data.get("places",[]):
			var at:=chart.to_screen(place.pos)
			var picto:=KnownWorld.resource_glyph(String(place.get("resource","")),String(place.get("kind","")))
			var tone:=yellow if String(place.kind)=="artifact" else (red if String(place.kind)=="intelligence" else line)
			KnownWorld.glyph(self,picto,at,7,tone,1.4)
			label(String(place.get("label","")),at,12,Color(line,.9))
			chart.add_hit(at,12,"%s\n%s" % [String(place.get("label","")),String(place.get("tip",""))])
		_frame_marks(line,red,yellow,faint,paper)
	func _cartouche(tone:Color)->StyleBoxFlat:
		var box:=StyleBoxFlat.new();box.bg_color=tone;box.set_corner_radius_all(14)
		box.shadow_color=Color(tone,.5);box.shadow_size=10
		return box
	func _circle(at:Vector2,r:float)->PackedVector2Array:
		var pts:=PackedVector2Array()
		for i:int in 49:pts.append(at+Vector2(cos(TAU*i/48.0),sin(TAU*i/48.0))*r)
		return pts
	func _edge_marks(hearsay:Array,home_px:Vector2,tone:Color)->void:
		var dirs:={"east":Vector2(1,0),"southeast":Vector2(1,1),"south":Vector2(0,1),"southwest":Vector2(-1,1),"west":Vector2(-1,0),"northwest":Vector2(-1,-1),"north":Vector2(0,-1),"northeast":Vector2(1,-1)}
		var used:Dictionary={}
		for entry:Dictionary in hearsay:
			var key:=String(entry.get("direction","")).to_lower().strip_edges()
			if not dirs.has(key):continue
			var dir:=(dirs[key] as Vector2).normalized()
			var box:=Rect2(Vector2(34,40),size-Vector2(68,92))
			var t:=INF
			if absf(dir.x)>.001:t=minf(t,((box.end.x if dir.x>0 else box.position.x)-home_px.x)/dir.x)
			if absf(dir.y)>.001:t=minf(t,((box.end.y if dir.y>0 else box.position.y)-home_px.y)/dir.y)
			if not is_finite(t) or t<0:continue
			var stack:=int(used.get(key,0));used[key]=stack+1
			var at:=home_px+dir*t+Vector2(-dir.y,dir.x)*stack*26.0
			var tail:=at-dir*26.0
			dashed(PackedVector2Array([tail,at]),Color(tone,.7),1.4,4.0,3.0)
			var side:=Vector2(-dir.y,dir.x)*5.0
			draw_colored_polygon(PackedVector2Array([at+dir*6.0,at+side-dir*2.0,at-side-dir*2.0]),Color(tone,.8))
			var text:="the %s? · far %s" % [String(entry.get("name","")),key]
			label(text,tail-dir*4.0,12,tone,true,dir.x>0,true)
			chart.add_hit(at,18,"The %s — only hearsay: off to the %s, %s." % [String(entry.get("name","")),key,String(entry.get("distance","far"))])
	func _frame_marks(line:Color,red:Color,yellow:Color,faint:Color,paper:bool)->void:
		# Caption, orientation and a small key, drawn like the rest of the chart.
		var title_font:=Kit.italic_font()
		var plate:=Color(c("halo"),.78)
		draw_style_box(_cartouche(plate),Rect2(Vector2(20,22),Vector2(360,46)))
		draw_style_box(_cartouche(plate),Rect2(Vector2(22,size.y-42),Vector2(560,30)))
		var caption:="The world as our walkers tell it" if not paper else "The known world, from the walkers' accounts"
		draw_string_outline(title_font,Vector2(30,42),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,19,4,Color(c("halo"),.8))
		draw_string(title_font,Vector2(30,42),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,19,line)
		var era:String=["Scratched in charcoal and ochre on a scraped hide","Painted on hide by those who walked it","Inked from the walkers' accounts","Drawn to measure from surveyed routes"][clampi(chart.tier,0,3)]
		draw_string(title_font,Vector2(30,60),era,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(faint,.95))
		if paper:
			draw_rect(Rect2(Vector2(8,8),size-Vector2(16,16)),Color(line,.55),false,1.4)
			draw_rect(Rect2(Vector2(13,13),size-Vector2(26,26)),Color(line,.3),false,1.0)
			var rose:=Vector2(size.x-54,58)
			for i:int in 4:
				var a:=-PI*.5+i*PI*.5;var d:=Vector2(cos(a),sin(a));var s:=Vector2(-d.y,d.x)
				draw_colored_polygon(PackedVector2Array([rose+d*26,rose+s*5,rose-s*5]),Color(line,.85 if i==0 else .45))
			draw_arc(rose,14,0,TAU,32,Color(line,.6),1.0,true)
			draw_string(Kit.serif_font(),rose+Vector2(-5,-31),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,13,line)
		else:
			var sun:=Vector2(size.x-48,size.y*.5-40)
			KnownWorld.glyph(self,"sun",sun,16,Color(yellow,.9),1.6)
			var font:=Kit.italic_font()
			var words:="sunrise"
			var w:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
			draw_string(font,sun+Vector2(-w*.5,32),words,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(line,.8))
			var sunset_at:=Vector2(40,size.y*.5-40)
			draw_arc(sunset_at,11,PI,TAU,16,Color(red,.7),1.5,true);draw_line(sunset_at+Vector2(-16,0),sunset_at+Vector2(16,0),Color(red,.7),1.3,true)
			var w2:=font.get_string_size("sunset",HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
			draw_string(font,sunset_at+Vector2(-w2*.5,22),"sunset",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(line,.8))
		# key
		var y:=size.y-26.0;var x:=34.0
		var font_key:=Kit.italic_font()
		var entries:=[["fire","the hearth",line],["walked","walked and returned",line],["walker","walkers abroad",red],["question","told of, unseen",yellow]]
		for entry:Array in entries:
			var kind:=String(entry[0]);var tone:Color=entry[2]
			if kind=="walked":
				if paper:draw_line(Vector2(x-6,y),Vector2(x+14,y),tone,1.6,true)
				else:footprints(PackedVector2Array([Vector2(x-8,y),Vector2(x+16,y)]),tone)
				x+=22
			else:
				KnownWorld.glyph(self,kind,Vector2(x,y),7 if kind!="fire" else 8,tone,1.4);x+=14
			var text:=String(entry[1])
			draw_string_outline(font_key,Vector2(x,y+4),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,3,Color(c("halo"),.8))
			draw_string(font_key,Vector2(x,y+4),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(line,.85))
			x+=font_key.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+26
		if (chart.data.get("trails",[]) as Array).is_empty():
			var empty:="Only the hearth is known. Send walkers, and the %s will fill." % ("chart" if paper else "hide")
			var fw:=title_font.get_string_size(empty,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
			draw_string(title_font,Vector2((size.x-fw)*.5,size.y*.5+70),empty,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(line,.8))
