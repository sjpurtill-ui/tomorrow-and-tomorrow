extends VBoxContainer
## FEUDS & WARS, as HOI4's war overview shows a war: one card per feud or war
## (hud/war_ledger_model.gd). Each card carries:
##   head     their emblem and name, what it is about and how long, and a chip
##            saying it is hot, simmering, a war or ended;
##   dead     two bars meeting in the middle: our dead in our blue to the left,
##            theirs in their red to the right, each figure at its bar's end;
##   strength their strength against ours as a tug of war (the war leader's
##            own scale), with the odds in words;
##   worn     how worn each people is, with the engine's turning points marked
##            on theirs: from 40% they may seek peace, and from 55% they keep
##            their raiders home;
##   quiet    the clock since blood was last spilled: hot to the first mark
##            (no envoys from them), simmering to the second, then cold;
##   chips    their raids and our strikes, the last raid, the war leader's band
##            out against them and our bands at their towns;
##   ends     in one line, what would end it, with the engine's numbers.
## A feud that ended lately keeps a short row saying how it ended. Observe
## only: orders go through the court.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Model:=preload("res://scripts/hud/war_ledger_model.gd")
const Strips:=preload("res://scripts/hud/force_strips.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")
const REFRESH_SECONDS:=0.5
const OURS:=Color("#3d7f9c")
const THEIRS:=Color("#a8463a")
const OCHRE:=Color("#a8782a")

var list:VBoxContainer
## One per card shown: {civ_id, kind, dead, odds, worn, quiet, sub, chip, chips, ends}.
var cards:Array[Dictionary]=[]
var signature:=""
var clock:=0.0


func setup(_block:Dictionary={})->void:
	name="WarLedgerBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	list=VBoxContainer.new();list.name="Cards";list.add_theme_constant_override("separation",12);add_child(list)
	refresh(true)


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS: return
	clock=0.0
	refresh()


func refresh(force:=false)->void:
	var entries:=Model.entries()
	var next:=_signature(entries)
	if force or next!=signature:
		signature=next
		_rebuild(entries)
		return
	for i in mini(entries.size(),cards.size()): _update(cards[i],entries[i])


## What changes the cards' make-up: who, what kind, their chips' lines.
static func _signature(entries:Array)->String:
	var parts:=PackedStringArray()
	for e:Dictionary in entries:
		parts.append("%s|%s|%s|%d|%d" % [String(e.civ_id),String(e.kind),str(not (e.get("band",{}) as Dictionary).is_empty()),(e.get("bands",[]) as Array).size(),int(not (e.get("last_raid",{}) as Dictionary).is_empty())])
	return ";".join(parts)


func _rebuild(entries:Array)->void:
	for child in list.get_children(): list.remove_child(child);child.queue_free()
	cards.clear()
	var open:=entries.filter(func(e:Dictionary)->bool: return String(e.kind)!="ended")
	var ended:=entries.filter(func(e:Dictionary)->bool: return String(e.kind)=="ended")
	if open.is_empty(): _at_peace()
	for e:Dictionary in open: cards.append(_card(e))
	if not ended.is_empty():
		list.add_child(_kicker("Ended lately"))
		for e:Dictionary in ended: cards.append(_ended_row(e))


func _at_peace()->void:
	var panel:=PanelContainer.new();panel.name="AtPeace";panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,18));list.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
	var title:=Label.new();title.text="No feuds and no wars";T.text(title,"voice",T.INK);column.add_child(title)
	column.add_child(_line("No people we know has spilled our blood lately, nor we theirs.",14,T.INK_MUTED,true))


func _card(e:Dictionary)->Dictionary:
	var hot:=bool(e.get("hot",false))
	var panel:=PanelContainer.new();panel.name="Feud_%s" % String(e.civ_id)
	panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,THEIRS if hot else T.RULE,16,3 if hot else 0))
	list.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);panel.add_child(column)
	# Head: their emblem, their name, what and how long, the chip.
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",14);column.add_child(head)
	var emblem:=TextureRect.new();emblem.texture=Identity.emblem(String(e.civ_id));emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.custom_minimum_size=Vector2(52,52);emblem.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(emblem)
	var titles:=VBoxContainer.new();titles.add_theme_constant_override("separation",0);titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(titles)
	var title:=Label.new();title.text=String(e.name);T.text(title,"voice",T.INK);titles.add_child(title)
	var sub:=_line(Model.subtitle(e),14,T.INK_MUTED);titles.add_child(sub)
	var chip:=StateChip.new();chip.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(chip)
	# The meters.
	var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",10);column.add_child(grid)
	grid.add_child(_row_name("The dead"))
	var dead:=DeadBars.new();dead.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(dead)
	grid.add_child(_row_name("Strength"))
	var odds:=Strips.OddsBar.new();odds.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(odds)
	grid.add_child(_row_name("Worn"))
	var worn:=WornBars.new();worn.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(worn)
	var quiet:QuietClock=null
	if String(e.kind)=="feud":
		grid.add_child(_row_name("Quiet"))
		quiet=QuietClock.new();quiet.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(quiet)
	# What is going on: raids, strikes, bands.
	var chips:=HFlowContainer.new();chips.add_theme_constant_override("h_separation",8);chips.add_theme_constant_override("v_separation",6);column.add_child(chips)
	var ends:=_line("",14,T.INK_MUTED,true);column.add_child(ends)
	var card:={"civ_id":String(e.civ_id),"kind":String(e.kind),"dead":dead,"odds":odds,"worn":worn,"quiet":quiet,"sub":sub,"chip":chip,"chips":chips,"ends":ends,"panel":panel}
	_update(card,e)
	return card


func _ended_row(e:Dictionary)->Dictionary:
	var panel:=PanelContainer.new();panel.name="Ended_%s" % String(e.civ_id);panel.add_theme_stylebox_override("panel",_skin(T.PAPER_SUNK,T.RULE,10));list.add_child(panel)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);panel.add_child(row)
	var emblem:=TextureRect.new();emblem.texture=Identity.emblem(String(e.civ_id));emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.custom_minimum_size=Vector2(32,32);emblem.size_flags_vertical=Control.SIZE_SHRINK_CENTER;emblem.modulate=Color(1,1,1,0.7);row.add_child(emblem)
	var name_label:=_line(String(e.name),16,T.INK);name_label.add_theme_font_override("font",T.font("ui_strong"));row.add_child(name_label)
	var how:=_line("",14,T.INK_MUTED);how.size_flags_horizontal=Control.SIZE_EXPAND_FILL;how.clip_text=true;how.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;row.add_child(how)
	var dead:=DeadBars.new();dead.compact=true;dead.custom_minimum_size=Vector2(220,22);row.add_child(dead)
	var card:={"civ_id":String(e.civ_id),"kind":"ended","dead":dead,"how":how}
	_update(card,e)
	return card


func _update(card:Dictionary,e:Dictionary)->void:
	(card.dead as DeadBars).set_dead(int(e.get("our_dead",0)),int(e.get("their_dead",0)),String(e.name))
	if String(card.kind)=="ended":
		(card.how as Label).text="Ended %s ago: %s" % [Model.span_words(int(e.ago)),String(e.how_words)]
		return
	(card.sub as Label).text=Model.subtitle(e)
	(card.chip as StateChip).set_state(Model.state_word(e),String(e.kind),bool(e.get("hot",false)))
	var odds:=Model.odds(e)
	(card.odds as Strips.OddsBar).set_odds(odds,Model.odds_words(e))
	(card.odds as Control).tooltip_text="Their people's fighting strength against ours: their numbers, warriors and readiness on the war leader's scale. %s." % Model.odds_words(e).capitalize()
	(card.worn as WornBars).set_worn(float(e.get("our_worn",0.0)),float(e.get("their_worn",0.0)),String(e.kind)=="feud",String(e.name))
	if card.quiet!=null: (card.quiet as QuietClock).set_quiet(int(e.get("quiet",0)),Model.clock_words(e))
	_fill_chips(card.chips as HFlowContainer,e)
	(card.ends as Label).text=Model.ending_words(e)
	(card.ends as Label).visible=(card.ends as Label).text!=""


func _fill_chips(flow:HFlowContainer,e:Dictionary)->void:
	var wanted:=PackedStringArray()
	var specs:Array=[]
	if String(e.kind)=="feud":
		specs.append({"icon":Icons.war_texture("raid",THEIRS,48),"text":"Their raids %d" % int(e.get("raids",0)),"tip":"Times their raiders struck us in this feud."})
		specs.append({"icon":Icons.war_texture("feud",OURS,48),"text":"Our strikes %d" % int(e.get("strikes",0)),"tip":"Times our war leader's band struck them in this feud."})
	var raid:Dictionary=e.get("last_raid",{})
	if not raid.is_empty():
		var target:=String(WarLoop.TARGETS.get(String(raid.target),{}).get("words",String(raid.target))) if WarLoop.TARGETS.has(String(raid.target)) else String(raid.target)
		var dead:=int(raid.get("our_dead",0))
		specs.append({"icon":Icons.war_texture("raid",THEIRS,48),"text":"Last raid: %s, %s ago%s" % [target,Model.span_words(int(raid.days_ago)),(", %d dead" % dead) if dead>0 else ""],"tip":"Their last raid on us."})
	var band:Dictionary=e.get("band",{})
	if not band.is_empty():
		var who:=String(band.general).get_slice(" ",0)
		var men:=int(band.get("men",0))
		var text:="%s %s" % ["%s's %d" % [who,men] if who!="" and men>0 else ("%d of ours" % men if men>0 else "Our band"),String(band.words)]
		if int(band.get("days_left",0))>0: text+=" · back in %s" % Model.span_words(int(band.days_left))
		specs.append({"icon":Icons.war_texture("band",OURS,48),"text":text,"tip":"The war leader's band out against them."})
	for b:Dictionary in e.get("bands",[]):
		specs.append({"icon":Icons.arm_texture(String(b.glyph),T.INK,T.GOLD,48),"text":"%s · %s · %s" % [String(b.name),EraWords.grouped(int(b.troops)),String(b.where)],"tip":"A band of ours at or bound for their towns."})
	for spec:Dictionary in specs: wanted.append(String(spec.text))
	# Rebuild only when the words change.
	if str(flow.get_meta("words",PackedStringArray()))==str(wanted): return
	flow.set_meta("words",wanted)
	for child in flow.get_children(): flow.remove_child(child);child.queue_free()
	for spec:Dictionary in specs:
		var chip:=PanelContainer.new();chip.add_theme_stylebox_override("panel",_skin(T.PAPER_SUNK,T.RULE,6));chip.tooltip_text=String(spec.tip);chip.mouse_filter=Control.MOUSE_FILTER_PASS;flow.add_child(chip)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(row)
		var icon:=TextureRect.new();icon.texture=spec.icon;icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.custom_minimum_size=Vector2(22,22);icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(icon)
		var label:=_line(String(spec.text),14,T.INK);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(label)


func _row_name(text:String)->Label:
	var label:=_line(text.to_upper(),12,T.INK_MUTED)
	label.custom_minimum_size.x=92
	label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	return label


func _kicker(text:String)->Label:
	var label:=_line(text.to_upper(),13,T.INK_MUTED)
	label.add_theme_font_override("font",T.font("ui_strong"))
	return label


static func _line(text:String,size:int,color:Color,wrap:=false)->Label:
	var label:=Label.new();label.text=text
	label.add_theme_font_override("font",T.font("ui"));label.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size));label.add_theme_color_override("font_color",color)
	if wrap: label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label


static func _skin(bg:Color,border:Color,margin:int,top:int=0)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1)
	if top>0: style.border_width_left=top
	style.set_corner_radius_all(T.RADIUS_CARD);style.set_content_margin_all(margin)
	return style


## "HOT" in oxblood, "SIMMERING" in ochre, "WAR" in oxblood, "ENDED" in ink.
class StateChip extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var word:=""
	var tone:=Color("#a8463a")
	func _ready()->void: mouse_filter=Control.MOUSE_FILTER_PASS
	func set_state(next:String,kind:String,hot:bool)->void:
		word=next.to_upper()
		tone=Color("#a8463a") if hot or kind=="war" else (Color("#a8782a") if kind=="feud" else T.INK_MUTED)
		tooltip_text={"HOT":"Blood was spilled within the year: no envoys come from them, and their raiders may.","SIMMERING":"No blood for a year: envoys can come again, but nobody has made peace.","WAR":"A war: their host may march.","ENDED":"Over."}.get(word,"")
		var font:=T.font("ui_strong")
		custom_minimum_size=Vector2(font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+24.0,28.0)
		queue_redraw()
	func _draw()->void:
		var box:=Rect2(Vector2(0,(size.y-28.0)*0.5),Vector2(size.x,28.0))
		draw_rect(box,tone)
		var font:=T.font("ui_strong")
		var w:=font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		draw_string(font,Vector2((size.x-w)*0.5,box.position.y+19.0),word,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#f6efe1"))


## The dead of both sides: two bars meeting at a middle line, ours to the
## left in our blue and theirs to the right in their red, on one scale.
class DeadBars extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const EraWords:=preload("res://scripts/hud/era_words.gd")
	const OURS:=Color("#3d7f9c")
	const THEIRS:=Color("#a8463a")
	var ours:=0
	var theirs:=0
	var compact:=false
	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_PASS
		if custom_minimum_size.y<=0.0: custom_minimum_size=Vector2(0,36)
	## The scale's top: 10, 20, 50, 100, 200, 500 ... at or above the most dead.
	static func _nice(most:int)->int:
		var step:=10
		while step<most:
			if step*2>=most: return step*2
			if step*5>=most: return step*5
			step*=10
		return step
	func set_dead(our_dead:int,their_dead:int,name:String)->void:
		ours=maxi(0,our_dead);theirs=maxi(0,their_dead)
		tooltip_text="The dead of it all told: %s of ours, %s of %s." % [EraWords.grouped(ours),EraWords.grouped(theirs),name]
		queue_redraw()
	func _draw()->void:
		var font:=T.font("ui_strong")
		var fs:=13 if compact else 16
		var bar_h:=10.0 if compact else 14.0
		var y:=(size.y-bar_h)*0.5 if compact else 3.0
		var mid:=size.x*0.5
		var room:=font.get_string_size("0000",HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x+8.0
		var half:=maxf(10.0,mid-room)
		# One scale for both, never finer than ten: a single death is a sliver.
		var top:=float(_nice(maxi(ours,theirs)))
		var lw:=half*float(ours)/top; var rw:=half*float(theirs)/top
		draw_rect(Rect2(Vector2(mid-half,y),Vector2(half*2.0,bar_h)),Color(T.INK,0.07))
		if ours>0: draw_rect(Rect2(Vector2(mid-lw,y),Vector2(lw,bar_h)),OURS)
		if theirs>0: draw_rect(Rect2(Vector2(mid,y),Vector2(rw,bar_h)),THEIRS)
		draw_line(Vector2(mid,y-3.0),Vector2(mid,y+bar_h+3.0),T.INK,1.5)
		var lt:=EraWords.grouped(ours); var rt:=EraWords.grouped(theirs)
		var base:=y+bar_h*0.5+float(fs)*0.36
		draw_string(font,Vector2(mid-lw-6.0-font.get_string_size(lt,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x,base),lt,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,OURS.darkened(0.35))
		draw_string(font,Vector2(mid+rw+6.0,base),rt,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,THEIRS.darkened(0.25))
		if compact: return
		var small:=T.font("ui")
		draw_string(small,Vector2(mid-half,y+bar_h+16.0),"ours",HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK_MUTED)
		var tw:=small.get_string_size("theirs",HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		draw_string(small,Vector2(mid+half-tw,y+bar_h+16.0),"theirs",HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK_MUTED)


## How worn each people is, 0 to 100%. On theirs, the engine's turning
## points: from PEACE_WORN they may send someone to end a feud, and from
## ENEMY_SPENT they keep their raiders home.
class WornBars extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const WarLoop:=preload("res://scripts/war_loop.gd")
	const OURS:=Color("#3d7f9c")
	const THEIRS:=Color("#a8463a")
	const LABEL_W:=56.0
	var ours:=0.0
	var theirs:=0.0
	var marks:=true
	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_PASS
		custom_minimum_size=Vector2(0,50)
	func set_worn(our_worn:float,their_worn:float,feud:bool,name:String)->void:
		ours=clampf(our_worn,0.0,1.0);theirs=clampf(their_worn,0.0,1.0);marks=feud
		tooltip_text="How worn each people is by it: the dead against their numbers, and every exchange. %s is %d%% worn and we are %d%%." % [name,roundi(theirs*100.0),roundi(ours*100.0)]
		if feud: tooltip_text+=" From %d%% they may send someone to end the feud; from %d%% they keep their raiders home." % [roundi(WarLoop.PEACE_WORN*100.0),roundi(WarLoop.ENEMY_SPENT*100.0)]
		queue_redraw()
	func _draw()->void:
		var font:=T.font("ui"); var strong:=T.font("ui_strong")
		var x0:=LABEL_W; var w:=maxf(20.0,size.x-LABEL_W-48.0)
		var rows:=[["theirs",theirs,THEIRS,22.0],["ours",ours,OURS,38.0]]
		for row:Array in rows:
			var y:=float(row[3])
			draw_string(font,Vector2(0,y+9.0),String(row[0]),HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK_MUTED)
			draw_rect(Rect2(Vector2(x0,y),Vector2(w,10.0)),Color(T.INK,0.08))
			if float(row[1])>0.0: draw_rect(Rect2(Vector2(x0,y),Vector2(w*float(row[1]),10.0)),row[2])
			draw_rect(Rect2(Vector2(x0,y),Vector2(w,10.0)),Color(T.INK,0.45),false,1.0)
			draw_string(strong,Vector2(x0+w+8.0,y+10.0),"%d%%" % roundi(float(row[1])*100.0),HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.INK)
		if not marks: return
		# The turning points on theirs, each word on the far side of its mark.
		var peace:=x0+w*WarLoop.PEACE_WORN; var spent:=x0+w*WarLoop.ENEMY_SPENT
		for at:float in [peace,spent]: draw_line(Vector2(at,16.0),Vector2(at,33.0),T.INK,1.5)
		var said:="may seek peace"; var sw:=font.get_string_size(said,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		draw_string(font,Vector2(peace-sw-3.0,13.0),said,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK if theirs>=WarLoop.PEACE_WORN else T.INK_MUTED)
		draw_string(font,Vector2(spent+3.0,13.0),"raiders stay home",HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK if theirs>=WarLoop.ENEMY_SPENT else T.INK_MUTED)


## The quiet since blood was last spilled, on the engine's own clock: hot
## until FEUD_HOT_DAYS (no envoys come from them), simmering until
## FEUD_COLD_DAYS, then cold. The pointer stands at today.
class QuietClock extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const WarLoop:=preload("res://scripts/war_loop.gd")
	const THEIRS:=Color("#a8463a")
	const OCHRE:=Color("#a8782a")
	var quiet:=0
	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_PASS
		custom_minimum_size=Vector2(0,50)
	func set_quiet(days:int,words:String)->void:
		quiet=maxi(0,days)
		tooltip_text=words+" A killing on either side starts the clock again."
		queue_redraw()
	func _draw()->void:
		var font:=T.font("ui"); var strong:=T.font("ui_strong")
		var span:=float(WarLoop.FEUD_COLD_DAYS)
		var x0:=0.0; var w:=maxf(40.0,size.x-70.0); var y:=20.0; var h:=10.0
		var hot_x:=x0+w*float(WarLoop.FEUD_HOT_DAYS)/span
		draw_rect(Rect2(Vector2(x0,y),Vector2(hot_x-x0,h)),Color(THEIRS,0.30))
		draw_rect(Rect2(Vector2(hot_x,y),Vector2(x0+w-hot_x,h)),Color(OCHRE,0.22))
		var now:=x0+w*clampf(float(quiet)/span,0.0,1.0)
		draw_rect(Rect2(Vector2(x0,y),Vector2(now-x0,h)),Color(T.INK,0.55))
		draw_rect(Rect2(Vector2(x0,y),Vector2(w,h)),Color(T.INK,0.45),false,1.0)
		draw_line(Vector2(hot_x,y-3.0),Vector2(hot_x,y+h+3.0),T.INK,1.5)
		# Today's pointer, with the days above it.
		draw_colored_polygon(PackedVector2Array([Vector2(now,y-1.0),Vector2(now-5.0,y-8.0),Vector2(now+5.0,y-8.0)]),T.INK)
		var days:=("today" if quiet<=0 else "%d days" % quiet) if quiet<99999 else "never"
		var dw:=strong.get_string_size(days,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		draw_string(strong,Vector2(clampf(now-dw*0.5,0.0,w-dw),y-10.0),days,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK)
		draw_string(font,Vector2(x0,y+h+15.0),"hot",HORIZONTAL_ALIGNMENT_LEFT,-1,12,THEIRS.darkened(0.2))
		draw_string(font,Vector2(hot_x+4.0,y+h+15.0),"simmering",HORIZONTAL_ALIGNMENT_LEFT,-1,12,OCHRE.darkened(0.3))
		draw_string(strong,Vector2(x0+w+8.0,y+h-1.0),"cold",HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.INK_MUTED)
