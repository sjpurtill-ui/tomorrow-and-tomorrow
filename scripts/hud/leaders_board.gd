extends VBoxContainer
## THE MILITARY LEADERS SCREEN: the army as its leaders and their commands
## (leader_commands.gd). The ruler puts bands under a leader; the leader sees
## to the rest. It reads at any size, from three bands to five hundred:
##   strip    leaders, bands, men under them, generals without a command;
##   list     one row per command: the leader's face, name and title, bands
##            and men, and small will and supply bars (a red mark when one of
##            theirs is hungry or ready to break);
##   dossier  the chosen leader: face, name, title, skills as pips, how the
##            captains rate them, their record; what they see to (supply,
##            gear, organization, pacing), each with the engine's numbers;
##            their bands, one row each (grouped by kit and place past
##            GROUP_FROM), each with "Move to" another leader; bands to put
##            under them; talk to them, give their command an objective, or
##            find it on the map.
## Every figure is the one the army bar reads (army_bar_model.army_card):
## what is known at home, a band away by its runner's last word.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Commands:=preload("res://scripts/leader_commands.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const Board:=preload("res://scripts/hud/recruit_deploy_board.gd")
const Strips:=preload("res://scripts/hud/force_strips.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Counter:=preload("res://scripts/hud/army_counter.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Record:=preload("res://scripts/battle_record.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const Sustain:=preload("res://scripts/field_sustainment.gd")
const Story:=preload("res://scripts/hud/military_force_story.gd")
const REFRESH_SECONDS:=0.5
## Past this many bands a command's bands are shown by kit and place.
const GROUP_FROM:=12
const LIST_WIDTH:=330.0

signal close_wanted

var chosen:=""
var signature:=""
var clock:=0.0
var show_each:=false
var strip:HBoxContainer
var list:VBoxContainer
var dossier:VBoxContainer
var feedback:Label


func setup(_block:Dictionary={})->void:
	name="LeadersBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	strip=HBoxContainer.new();strip.name="Strip";strip.add_theme_constant_override("separation",26)
	var strip_panel:=PanelContainer.new();strip_panel.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CARD,10));strip_panel.add_child(strip);add_child(strip_panel)
	feedback=_line("",14,T.GOLD_TEXT);feedback.visible=false;add_child(feedback)
	var body:=HBoxContainer.new();body.add_theme_constant_override("separation",16);add_child(body)
	list=VBoxContainer.new();list.name="Commands";list.custom_minimum_size.x=LIST_WIDTH;list.add_theme_constant_override("separation",6);body.add_child(list)
	dossier=VBoxContainer.new();dossier.name="Dossier";dossier.size_flags_horizontal=Control.SIZE_EXPAND_FILL;dossier.add_theme_constant_override("separation",12);body.add_child(dossier)
	refresh(true)


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS:return
	clock=0.0
	refresh()


## The commands with their bands' cards (army_bar_model): what is known.
static func read(mc:Variant=null)->Array:
	var host:Node=mc if mc!=null else MilitaryCampaign
	var out:=[]
	for command:Dictionary in Commands.commands(host):
		var cards:=[]
		for id in command.bands:
			var index:int=host._field_army_index(int(id))
			if index>=0:cards.append(BarModel.army_card(host,host.field_armies[index]))
		var entry:=command.duplicate()
		entry["cards"]=cards
		entry["sums"]=sums(cards)
		out.append(entry)
	return out


## A command's bands summed as the army bar reads them: men, full, gear
## issued and required, will and supply weighted by men, the hungry, those
## ready to break, those marching and where they stand.
static func sums(cards:Array)->Dictionary:
	var out:={"bands":cards.size(),"men":0,"full":0,"issued":0,"required":0,"will":0.0,"supply":0.0,"hungry":0,"breaking":0,"marching":0,"missing":{},"worst":"well"}
	var order:={"well":0,"strained":1,"unknown":1,"starving":2}
	for card:Dictionary in cards:
		var men:=int(card.get("men",0))
		out.men=int(out.men)+men;out.full=int(out.full)+int(card.get("full",men))
		var gear:Dictionary=card.get("gear_detail",{})
		out.issued=int(out.issued)+int(gear.get("issued",0));out.required=int(out.required)+int(gear.get("required",0))
		for item in (gear.get("missing",{}) as Dictionary):out.missing[item]=int((out.missing as Dictionary).get(item,0))+int(gear.missing[item])
		out.will=float(out.will)+float(card.get("will",0.6))*men
		out.supply=float(out.supply)+float(card.get("supply",0.0))*men
		if String(card.get("state",""))=="hungry" or String(card.get("supply_state",""))=="starving":out.hungry=int(out.hungry)+1
		if float(card.get("will",0.6))<0.3:out.breaking=int(out.breaking)+1
		if String(card.get("state",""))=="marching":out.marching=int(out.marching)+1
		var state:=String(card.get("supply_state","well"))
		if int(order.get(state,0))>int(order.get(String(out.worst),0)):out.worst=state
	var men:=maxi(1,int(out.men))
	out.will=float(out.will)/men if int(out.men)>0 else 0.0
	out.supply=float(out.supply)/men if int(out.men)>0 else 0.0
	return out


func refresh(force:=false)->void:
	var entries:=read()
	if chosen=="" or not entries.any(func(e:Dictionary)->bool: return String(e.id)==chosen):
		chosen=String(entries[0].id) if not entries.is_empty() else ""
	var next:=str(entries.map(func(e:Dictionary)->String: return "%s:%s:%d:%d:%d:%d" % [String(e.id),str(e.bands),int(e.sums.men),roundi(float(e.sums.will)*100),roundi(float(e.sums.supply)*100),int(e.sums.hungry)]))+chosen+str(show_each)
	if not force and next==signature:return
	signature=next
	_build_strip(entries)
	_build_list(entries)
	for e:Dictionary in entries:
		if String(e.id)==chosen:_build_dossier(e,entries)


func _build_strip(entries:Array)->void:
	for child in strip.get_children():strip.remove_child(child);child.queue_free()
	var leading:=entries.filter(func(e:Dictionary)->bool: return not (e.bands as Array).is_empty())
	var free:=entries.filter(func(e:Dictionary)->bool: return (e.bands as Array).is_empty() and String(e.id)!=Commands.WAR_LEADER)
	var bands:=0;var men:=0
	for e:Dictionary in entries:bands+=(e.bands as Array).size();men+=int(e.sums.men)
	for spec:Array in [["will",str(leading.size()),"leading" if leading.size()!=1 else "leading"," leaders with bands"],["men",EraWords.grouped(bands),"bands",""],["serving",EraWords.grouped(men),"men under them",""],["free",str(free.size()),"without a command",""]]:
		if String(spec[0])=="free" and free.is_empty():continue
		var chip:=HBoxContainer.new();chip.add_theme_constant_override("separation",7);strip.add_child(chip)
		var glyph:=TextureRect.new();glyph.texture=Icons.command_texture(String(spec[0]),T.INK,48);glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;glyph.custom_minimum_size=Vector2(22,22);glyph.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chip.add_child(glyph)
		var value:=_line(String(spec[1]),19,T.INK);value.add_theme_font_override("font",T.font("ui_strong"));chip.add_child(value)
		var word:=_line(String(spec[2]) if String(spec[0])!="will" else ("leader with bands" if leading.size()==1 else "leaders with bands"),13,T.INK_MUTED);word.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chip.add_child(word)


func _build_list(entries:Array)->void:
	for child in list.get_children():list.remove_child(child);child.queue_free()
	var free_heading:=false
	for e:Dictionary in entries:
		var leading:=String(e.id)==Commands.WAR_LEADER or not (e.bands as Array).is_empty()
		if not leading and not free_heading:
			free_heading=true
			list.add_child(_kicker("Without a command"))
		list.add_child(_row(e))


func _row(e:Dictionary)->Control:
	var leader:Dictionary=e.leader
	var sums_now:Dictionary=e.sums
	var panel:=PanelContainer.new();panel.name="Leader_%s" % String(e.id);panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	var picked:=String(e.id)==chosen
	var style:=T.flat(T.PAPER_RAISED if picked else T.PAPER,T.GOLD if picked else T.RULE,2 if picked else 1,T.RADIUS_CARD,8)
	panel.add_theme_stylebox_override("panel",style)
	var id:=String(e.id)
	panel.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
			chosen=id;show_each=false;refresh(true))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(row)
	row.add_child(_face(leader,Vector2(44,52)))
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",1);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(words)
	var name_line:=HBoxContainer.new();name_line.add_theme_constant_override("separation",6);name_line.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(name_line)
	var name_label:=_line(String(leader.name).get_slice(" ",0),16,T.INK);name_label.add_theme_font_override("font",T.font("ui_strong"));name_line.add_child(name_label)
	if int(sums_now.hungry)>0 or int(sums_now.breaking)>0:
		var alarm:=_line("●",14,T.RED);alarm.tooltip_text="Hungry or ready to break";name_line.add_child(alarm)
	words.add_child(_line(String(leader.title)+_status_words(leader),12,T.INK_MUTED))
	var bands:=(e.bands as Array).size()
	words.add_child(_line(("%d %s · %s men" % [bands,"band" if bands==1 else "bands",EraWords.grouped(int(sums_now.men))]) if bands>0 else "no bands",13,T.INK))
	if bands>0:
		var bars:=MiniBars.new();bars.will=float(sums_now.will);bars.supply=float(sums_now.supply);bars.worst=String(sums_now.worst);words.add_child(bars)
	return panel


## The kit most of a band's men carry, from its card's kinds.
static func glyph_of(card:Dictionary)->String:
	var kinds:Array=card.get("kinds",[])
	if kinds.is_empty() or not kinds[0] is Dictionary:return "spear"
	return preload("res://scripts/battle_blocks.gd").glyph_of(String((kinds[0] as Dictionary).get("unit","levy")),String((kinds[0] as Dictionary).get("weapon","")))


static func _status_words(leader:Dictionary)->String:
	match String(leader.get("status","living")):
		"wounded":return " · wounded"
		"captured":return " · held captive"
		"relieved":return " · relieved"
	return ""


func _build_dossier(e:Dictionary,entries:Array)->void:
	for child in dossier.get_children():dossier.remove_child(child);child.queue_free()
	var leader:Dictionary=e.leader
	var sums_now:Dictionary=e.sums
	var commander:Dictionary=leader.get("commander",{})
	# Who they are.
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",16);dossier.add_child(head)
	head.add_child(_face(leader,Vector2(88,104)))
	var who:=VBoxContainer.new();who.add_theme_constant_override("separation",4);who.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(who)
	var title:=Label.new();title.text=String(leader.name);T.text(title,"voice",T.INK);who.add_child(title)
	who.add_child(_line(String(leader.title)+_status_words(leader),14,T.INK_MUTED))
	var pips:Control=Strips.GeneralPips.new();who.add_child(pips)
	pips.call("set_commander",commander,String(leader.name),true)
	var rated:=Record.general_line(commander,EraWords.stage())
	if rated!="":who.add_child(_line(rated,14,T.INK))
	var record:=Commands.record(leader)
	if not record.is_empty():
		var fought:=int(record.battles)
		who.add_child(_line(("Fought %d · won %d · lost %d" % [fought,int(record.won),int(record.lost)] if fought>0 else "Has not led a fight yet")+(" · %d %s in public life" % [int(record.years),"year" if int(record.years)==1 else "years"]),13,T.INK_MUTED))
	# What they see to.
	dossier.add_child(_kicker("What %s sees to" % String(leader.name).get_slice(" ",0)))
	var tiles:=GridContainer.new();tiles.columns=4;tiles.add_theme_constant_override("h_separation",10);tiles.add_theme_constant_override("v_separation",10);dossier.add_child(tiles)
	var bands:=(e.cards as Array)
	var logistics:=clampf(float(commander.get("logistics",0.5)),0.0,1.0)
	for tile:Dictionary in tile_specs(sums_now,bands,logistics,String(e.id)==Commands.WAR_LEADER):tiles.add_child(_tile(tile))
	# Their bands.
	var bands_head:=HBoxContainer.new();bands_head.add_theme_constant_override("separation",10);dossier.add_child(bands_head)
	var kicker:=_kicker("Their bands · %d" % bands.size());kicker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bands_head.add_child(kicker)
	bands_head.add_child(_put_under(e,entries))
	if bands.is_empty():
		dossier.add_child(_line("No bands under %s. Put bands under them here, and they will see to their supply, their camps and their fights." % String(leader.name).get_slice(" ",0),14,T.INK_MUTED,true))
	elif bands.size()>GROUP_FROM and not show_each:
		for group:Dictionary in grouped(bands):dossier.add_child(_group_row(group))
		var each:=Button.new();each.text="Show each of the %d bands" % bands.size();each.pressed.connect(func()->void:show_each=true;refresh(true));dossier.add_child(each)
	else:
		for card:Dictionary in bands:dossier.add_child(_band_row(card,entries,String(e.id)))
	# What the ruler can do with this command.
	var acts:=HBoxContainer.new();acts.add_theme_constant_override("separation",8);dossier.add_child(acts)
	var talk:=Button.new();talk.text="Talk to %s" % String(leader.name).get_slice(" ",0);talk.tooltip_text="Call them to court: give their command its purpose in your own words.";talk.pressed.connect(func()->void:_talk(leader));acts.add_child(talk)
	var aim:=Button.new();aim.text="Give an objective";aim.tooltip_text="Open army command with their bands chosen.";aim.pressed.connect(func()->void:_objective(e));acts.add_child(aim)
	aim.disabled=bands.is_empty() and String(e.id)!=Commands.WAR_LEADER
	var find:=Button.new();find.text="Show on the map";find.disabled=bands.is_empty();find.pressed.connect(func()->void:_find(e));acts.add_child(find)


## The four things a leader sees to, each {key, title, value, share, color,
## line, tip}, from their bands as known at home and the engine's own rules.
static func tile_specs(sums_now:Dictionary,cards:Array,logistics:float,war_leader:bool)->Array:
	var out:=[]
	var bands:=int(sums_now.bands)
	var supply:=float(sums_now.supply)
	var state:=String(sums_now.worst)
	var fed:=bands-int(sums_now.hungry)
	out.append({"key":"supply","title":"Supply","value":"%d%%" % roundi(supply*100.0) if bands>0 else "—","share":supply,"color":BarModel.supply_color(state),
		"line":("%d of %d fed" % [fed,bands]) if bands>0 else ("the carriers for every band" if war_leader else "no bands to feed"),
		"tip":"The share of a day's food their bands get, by their men, as known at home. A band the carts cannot feed lives off the land and goes slower."})
	var issued:=int(sums_now.issued);var required:=int(sums_now.required)
	var gear:=float(issued)/float(required) if required>0 else 1.0
	var short:=PackedStringArray()
	for item in (sums_now.missing as Dictionary):short.append("%d %s" % [int(sums_now.missing[item]),String(preload("res://scripts/equipment_ledger.gd").label(String(item))).to_lower() if preload("res://scripts/equipment_ledger.gd").has(String(item)) else String(item)])
	out.append({"key":"gear","title":"Gear","value":"%d%%" % roundi(gear*100.0) if required>0 else "—","share":gear,"color":BarModel.gear_color(gear),
		"line":("short "+", ".join(short)) if not short.is_empty() else ("all armed" if required>0 else "no bands to arm"),
		"tip":"Kit in hand against what their men need. The staff hand out what the stores hold; Production makes the rest."})
	var will:=float(sums_now.will)
	# The engine's rest: up to MORALE_REST a day in full supply, a third of it
	# on the march, scaled by supply and by this leader's logistics.
	var regain:=Sustain.MORALE_REST*(0.35+0.65*supply)*(0.9+0.2*logistics)*100.0
	var ceiling:=(0.55+0.45*supply)*100.0
	out.append({"key":"will","title":"Organization","value":"%d%%" % roundi(will*100.0) if bands>0 else "—","share":will,"color":BarModel.will_color(will),
		"line":("%d ready to break" % int(sums_now.breaking)) if int(sums_now.breaking)>0 else ("+%.1f a day in camp, up to %d%%" % [regain,roundi(ceiling)] if bands>0 else "no bands"),
		"tip":"Their will to fight, by their men. At rest a band regains up to %.0f points a day in full supply (a third of it on the march), less when short of food, and more under a leader with good logistics (x0.9 to x1.1); a hungry band loses heart instead. Below a quarter they break." % (Sustain.MORALE_REST*100.0)})
	var marching:=int(sums_now.marching)
	var foraging:=0
	for card:Dictionary in cards:
		if String(card.get("state",""))=="marching" and String(card.get("supply_state",""))!="well":foraging+=1
	var pace:="%d marching · %d holding" % [marching,bands-marching] if bands>0 else "—"
	out.append({"key":"pace","title":"Pacing","value":str(marching) if bands>0 else "—","share":float(marching)/float(maxi(1,bands)),"color":T.BLUE,
		"line":(pace+(" · %d slowed to forage" % foraging if foraging>0 else "")) if bands>0 else "no bands",
		"tip":"How their bands move. A leader keeps a band the carts cannot feed at half pace so it can forage, hunt and camp on the way."})
	return out


func _tile(spec:Dictionary)->Control:
	var panel:=PanelContainer.new();panel.name="Tile_%s" % String(spec.key);panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.tooltip_text=String(spec.tip);panel.mouse_filter=Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD,10))
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",4);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(column)
	column.add_child(_kicker(String(spec.title)))
	var value:=_line(String(spec.value),24,T.INK);value.add_theme_font_override("font",T.font("ui_strong"));column.add_child(value)
	var bar:=MiniBars.new();bar.single=clampf(float(spec.share),0.0,1.0);bar.single_color=spec.color;bar.custom_minimum_size=Vector2(120,8);column.add_child(bar)
	var line:=_line(String(spec.line),13,T.INK_MUTED);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(line)
	return panel


## Bands shown by kit and place when there are many: [{glyph, place, count, men, full}].
static func grouped(cards:Array)->Array:
	var by:={}
	var order:=[]
	for card:Dictionary in cards:
		var glyph:=glyph_of(card)
		var place:=String(card.get("doing",""))
		var key:=glyph+"|"+place
		if not by.has(key):by[key]={"glyph":glyph,"place":place,"count":0,"men":0,"full":0};order.append(key)
		by[key].count=int(by[key].count)+1;by[key].men=int(by[key].men)+int(card.get("men",0));by[key].full=int(by[key].full)+int(card.get("full",0))
	return order.map(func(key:String)->Dictionary: return by[key])


func _group_row(group:Dictionary)->Control:
	var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD,6))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);panel.add_child(row)
	row.add_child(_glyph(String(group.glyph),26))
	row.add_child(_line("%d bands · %s men" % [int(group.count),EraWords.grouped(int(group.men))],15,T.INK))
	var where:=_line(String(group.place),13,T.INK_MUTED);where.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(where)
	return panel


func _band_row(card:Dictionary,entries:Array,leader_id:String)->Control:
	var panel:=PanelContainer.new();panel.name="Band_%d" % int(card.get("army_id",0));panel.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD,6))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);panel.add_child(row)
	row.add_child(_glyph(glyph_of(card),26))
	var name_label:=_line(String(card.get("title","A band")),15,T.INK);name_label.custom_minimum_size.x=170;name_label.clip_text=true;name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;row.add_child(name_label)
	row.add_child(_line("%s/%s" % [EraWords.grouped(int(card.get("men",0))),EraWords.grouped(int(card.get("full",0)))],14,T.INK))
	for kind:String in ["gear","will","supply"]:
		var meter:Control=Board.Meter.new();meter.set("kind",kind);meter.custom_minimum_size=Vector2(96,22);row.add_child(meter)
		match kind:
			"gear":meter.call("set_reading",float(card.get("gear",1.0)),"%d%%" % roundi(float(card.get("gear",1.0))*100),BarModel.gear_color(float(card.get("gear",1.0))),BarModel.gear_words(card.get("gear_detail",{})))
			"will":meter.call("set_reading",float(card.get("will",0.6)),"%d%%" % roundi(float(card.get("will",0.6))*100),BarModel.will_color(float(card.get("will",0.6))),BarModel.will_words(float(card.get("will",0.6))))
			"supply":meter.call("set_reading",float(card.get("supply",0.0)),"%d%%" % roundi(float(card.get("supply",0.0))*100),BarModel.supply_color(String(card.get("supply_state","well"))),BarModel.supply_line(card))
	var where:=_line(String(card.get("doing","")),13,T.INK_MUTED);where.size_flags_horizontal=Control.SIZE_EXPAND_FILL;where.clip_text=true;where.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;row.add_child(where)
	var move:=OptionButton.new();move.name="MoveTo";move.tooltip_text="Put this band under another leader. It fights, camps and recovers with that leader's skills.";move.fit_to_longest_item=false;move.custom_minimum_size.x=150
	move.add_item("Move to…",0);move.set_item_disabled(0,true)
	var ids:=[""]
	for other:Dictionary in entries:
		if String(other.id)==leader_id:continue
		var leader:Dictionary=other.leader
		if String(leader.get("status","living"))!="living":continue
		move.add_item(String(leader.name).get_slice(" ",0)+(" (war leader)" if String(other.id)==Commands.WAR_LEADER else ""),ids.size());ids.append(String(other.id))
	var army_id:=int(card.get("army_id",0))
	move.item_selected.connect(func(index:int)->void:
		var target:=String(ids[move.get_item_id(index)])
		if target!="":_move(army_id,target))
	row.add_child(move)
	return panel


## "Put bands under X": a list of every band led by someone else.
func _put_under(e:Dictionary,entries:Array)->Control:
	var pick:=OptionButton.new();pick.name="PutUnder";pick.fit_to_longest_item=false;pick.custom_minimum_size.x=230
	var leader:Dictionary=e.leader
	pick.add_item("Put a band under %s…" % String(leader.name).get_slice(" ",0),0);pick.set_item_disabled(0,true)
	var ids:=[0]
	for other:Dictionary in entries:
		if String(other.id)==String(e.id):continue
		for card:Dictionary in other.cards:
			pick.add_item("%s · %s" % [String(card.get("title","A band")),EraWords.grouped(int(card.get("men",0)))],ids.size());ids.append(int(card.get("army_id",0)))
	pick.disabled=ids.size()<=1 or String(leader.get("status","living"))!="living"
	var leader_id:=String(e.id)
	pick.item_selected.connect(func(index:int)->void:
		var army_id:=int(ids[pick.get_item_id(index)])
		if army_id>0:_move(army_id,leader_id))
	return pick


func _move(army_id:int,leader_id:String)->void:
	var result:=Commands.assign(MilitaryCampaign,army_id,leader_id)
	feedback.text=String(result.get("message",result.get("error","")))
	feedback.add_theme_color_override("font_color",T.GOLD_TEXT if result.has("ok") else T.RED_TEXT)
	feedback.visible=feedback.text!=""
	refresh(true)


func _talk(leader:Dictionary)->void:
	var director:Node=preload("res://scripts/audience_director.gd").court_node()
	if director==null:
		feedback.text="The court cannot sit just now";feedback.visible=true;return
	var captain:=Story.captain_for({"commander":{"figure_id":String(leader.get("figure_id","")),"name":String(leader.get("name",""))}},MilitaryCampaign)
	if not captain.is_empty() and director.has_method("summon"):director.call("summon",captain.target)
	else:director.call("open_court",{})
	close_wanted.emit()


func _objective(e:Dictionary)->void:
	MilitaryCampaign.joint_operations.open_hierarchy("army")
	var screen:Variant=MilitaryCampaign.joint_operations.screen
	var bands:Array=e.bands
	if is_instance_valid(screen) and screen.has_method("choose_force"):screen.choose_force(int(bands[0]) if not bands.is_empty() else 0)


func _find(e:Dictionary)->void:
	var bands:Array=e.bands
	if bands.is_empty():return
	var scene:=get_tree().current_scene
	var hud:Variant=scene.get("hud") if scene!=null else null
	if hud!=null and (hud as Object).has_method("select_army"):(hud as Object).call("select_army",int(bands[0]))
	close_wanted.emit()


func _face(leader:Dictionary,side:Vector2)->Control:
	var frame:=PanelContainer.new();frame.clip_contents=true;frame.custom_minimum_size=side;frame.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK))
	var face:=TextureRect.new();face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;face.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var full_name:=String(leader.get("name",""))
	var key:=String(leader.get("figure_id","")) if String(leader.get("figure_id",""))!="" else full_name
	# The same face the army bar gives this leader.
	face.texture=Portrait.texture({"name":full_name,"person_id":absi(key.hash())%997+1})
	frame.add_child(face)
	return frame


func _glyph(kind:String,side:float)->TextureRect:
	var glyph:=TextureRect.new();glyph.texture=Icons.arm_texture(kind,T.INK,T.GOLD,48);glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;glyph.custom_minimum_size=Vector2(side,side);glyph.size_flags_vertical=Control.SIZE_SHRINK_CENTER;glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return glyph


func _kicker(text:String)->Label:
	var label:=_line(text.to_upper(),12,T.INK_MUTED)
	label.add_theme_font_override("font",T.font("ui_strong"))
	return label


static func _line(text:String,size:int,color:Color,wrap:=false)->Label:
	var label:=Label.new();label.text=text;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",T.font("ui"));label.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size));label.add_theme_color_override("font_color",color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label


## Two thin bars (will in ochre, supply in the state's colour) for a row; or
## one bar (single) for a tile.
class MiniBars extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
	var will:=0.0
	var supply:=0.0
	var worst:="well"
	var single:=-1.0
	var single_color:=Color.WHITE
	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		if custom_minimum_size.y<=0.0:custom_minimum_size=Vector2(120,12)
	func _draw()->void:
		if single>=0.0:
			draw_rect(Rect2(Vector2.ZERO,size),Color(T.INK,0.08))
			draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*single,size.y)),single_color)
			draw_rect(Rect2(Vector2.ZERO,size),Color(T.INK,0.4),false,1.0)
			return
		var w:=size.x
		for row:Array in [[0.0,will,BarModel.will_color(will)],[6.0,supply,BarModel.supply_color(worst)]]:
			var y:=float(row[0])
			draw_rect(Rect2(Vector2(0,y),Vector2(w,4)),Color(T.INK,0.1))
			draw_rect(Rect2(Vector2(0,y),Vector2(w*clampf(float(row[1]),0.0,1.0),4)),row[2])
