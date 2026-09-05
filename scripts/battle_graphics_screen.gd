class_name BattleGraphicsScreen
extends Control
## Simulation commits once; pause, speed, skip and replay consume records.
const INK:=Color("0b1013")
const TEXT:=Color("e8ebe6")
const MUTED:=Color("a3adaa")
const TEAL:=Color("7fe3d8")
const ORANGE:=Color("ff9f6b")
const GOLD:=Color("f2c14e")
const DURATION:=5.0
var campaign_mode:=true
var inspected_army_id:=0
var history_seed:=-1
var view:BattleDiorama
var viewport:SubViewport
var stage:SubViewportContainer
var phase:="orders"
var elapsed:=0.0
var playback_paused:=false
var speed:=1.0
var camera_drag_distance:=0.0
var camera_pressed:=false
var context:Dictionary={}
var finished_context:Dictionary={}
var cached_forces:Array=[]
var initial_forces:Array=[]
var strength_history:Dictionary={}
var round_records:Array=[]
var current_record:Dictionary={}
var final_outcome:=""
var home_side:=0
var selected_index:=0
var target_index:=-1
var formation_page:=0
var target_page:=0
var target_caption:Label
var log_page:=0
var replaying:=false
var replay_return:="result"
var resolve_count:=0
var ui_font:Font
var display_font:Font
var chrome:PanelContainer
var top_row:HBoxContainer
var heading:Label
var phase_label:Label
var city_button:Button
var armies_strip:Control
var army_panels:Array=[]
var force_labels:Array=[]
var momentum_panel:VBoxContainer
var momentum_label:Label
var momentum_bar:ProgressBar
var momentum_note:Label
var momentum_value:=50.0
var previous_momentum:=50.0
var left_panel:PanelContainer
var right_panel:PanelContainer
var formation_list:VBoxContainer
var selection_label:Label
var order_note:Label
var order_buttons:Dictionary={}
var targets:VBoxContainer
var left_pager:Label
var bottom:PanelContainer
var resolve_button:Button
var skip_button:Button
var retreat_button:Button
var pause_button:Button
var speed_button:Button
var progress:ProgressBar
var progress_note:Label
var camera_buttons:Dictionary={}
var result_panel:PanelContainer
var result_box:VBoxContainer
var result_title:Label
var result_text:Label
var result_primary:Button
var replay_button:Button
var result_return:Button
var history_choice:OptionButton
var policy_box:VBoxContainer
var prisoner_choice:OptionButton
var spoils_choice:OptionButton
var general_choice:OptionButton
var log_panel:PanelContainer
var log_text:RichTextLabel
var headline:VBoxContainer
var headline_title:Label
var headline_note:Label
var vignette:ColorRect
var marker_layer:Control
var plates:Array=[]
var floats:Array=[]
var arrow:Line2D
var selected_ring:Line2D
var target_ring:Line2D
var narrow_orders:=false
var small_toggle:Button
var seed_label:Label
var momentum_back:PanelContainer
var momentum_needle:ColorRect
var momentum_center:ColorRect
var momentum_ghost:ColorRect
var previous_scale_size:Vector2i
var previous_scale_aspect:int

func style(color:Color,border:Color=Color("263237"),radius:int=8)->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=color;s.border_color=border;s.set_border_width_all(1);s.set_corner_radius_all(radius)
	for edge in ["left","right","top","bottom"]:s.set("content_margin_"+edge,12.0)
	return s
func label(parent:Node,text:String,size:int=14,color:Color=TEXT,display:bool=false)->Label:
	var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);l.add_theme_font_override("font",display_font if display else ui_font);parent.add_child(l);return l
func button(parent:Node,text:String,action:Callable,color:Color=TEXT)->Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=36;b.add_theme_font_override("font",ui_font);b.add_theme_font_size_override("font_size",13);b.add_theme_color_override("font_color",color)
	b.add_theme_stylebox_override("normal",style(Color("192226")));b.add_theme_stylebox_override("hover",style(Color("263438"),color));b.add_theme_stylebox_override("pressed",style(Color("31464b"),color));b.add_theme_stylebox_override("focus",style(Color(0,0,0,0),GOLD));b.pressed.connect(action);parent.add_child(b);return b
func panel()->PanelContainer:
	var p:=PanelContainer.new();p.add_theme_stylebox_override("panel",style(Color(INK,.92)));add_child(p);p.minimum_size_changed.connect(_layout.call_deferred);return p
func box(parent:Node)->VBoxContainer:
	var b:=VBoxContainer.new();b.add_theme_constant_override("separation",9);parent.add_child(b);return b
func clear_children(parent:Node)->void:
	for c in parent.get_children():parent.remove_child(c);c.queue_free()
func _ready()->void:
	previous_scale_size=get_window().content_scale_size;previous_scale_aspect=get_window().content_scale_aspect
	get_window().content_scale_size=Vector2i.ZERO;get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	ui_font=load("res://assets/fonts/battle/Barlow-Medium.ttf")
	display_font=load("res://assets/fonts/battle/BarlowCondensed-Bold.ttf")
	stage=SubViewportContainer.new();stage.set_anchors_and_offsets_preset(PRESET_FULL_RECT);stage.stretch=true;add_child(stage)
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.size=Vector2i(1600,900);viewport.msaa_3d=Viewport.MSAA_8X;stage.add_child(viewport)
	view=BattleDiorama.new();viewport.add_child(view);view.formation_selected.connect(_selected);stage.gui_input.connect(_view_input)
	vignette=ColorRect.new();vignette.set_anchors_and_offsets_preset(PRESET_FULL_RECT);vignette.mouse_filter=MOUSE_FILTER_IGNORE
	var shader:=Shader.new();shader.code="shader_type canvas_item; void fragment(){float d=length((UV-vec2(.55,.5))*vec2(1.15,1.0));COLOR=vec4(.03,.025,.015,smoothstep(.27,.72,d)*.38);}"
	var material:=ShaderMaterial.new();material.shader=shader;vignette.material=material;add_child(vignette)
	marker_layer=Control.new();marker_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT);marker_layer.mouse_filter=MOUSE_FILTER_IGNORE;add_child(marker_layer)
	for i in 3:
		var line:=Line2D.new();line.width=2.0;line.default_color=TEAL if i<2 else ORANGE;marker_layer.add_child(line)
		if i==0:arrow=line
		elif i==1:selected_ring=line
		else:target_ring=line
	_build_header();_build_orders();_build_result();_build_controls()
	resized.connect(_layout);_initialize();_layout()
func _build_header()->void:
	chrome=panel();top_row=HBoxContainer.new();top_row.add_theme_constant_override("separation",14);chrome.add_child(top_row)
	heading=label(top_row,"BATTLE",26,TEXT,true);heading.size_flags_horizontal=SIZE_EXPAND_FILL
	phase_label=label(top_row,"GIVING ORDERS",12,GOLD);phase_label.add_theme_stylebox_override("normal",style(Color(ORANGE,.15),Color(0,0,0,0),18));city_button=button(top_row,"City report",_city_report)
	button(top_row,"People & legacies",func():HistoricalFigures.open_chronicle());button(top_row,"×",_close)
	armies_strip=Control.new();armies_strip.mouse_filter=MOUSE_FILTER_IGNORE;add_child(armies_strip)
	for side in 2:
		var p:=PanelContainer.new();p.add_theme_stylebox_override("panel",style(Color(INK,.86),Color(0,0,0,0)));armies_strip.add_child(p);p.minimum_size_changed.connect(_layout.call_deferred);army_panels.append(p)
		var b:=box(p);var n:=label(b,"ARMY",22,TEAL if side==0 else ORANGE,true);n.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		var values:=label(b,"",16);values.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;force_labels.append({"title":n,"values":values})
	momentum_back=PanelContainer.new();momentum_back.mouse_filter=MOUSE_FILTER_IGNORE;momentum_back.add_theme_stylebox_override("panel",style(Color(INK,.90),Color(0,0,0,0)));armies_strip.add_child(momentum_back)
	momentum_panel=VBoxContainer.new();momentum_panel.mouse_filter=MOUSE_FILTER_IGNORE;armies_strip.add_child(momentum_panel)
	momentum_label=label(momentum_panel,"MOMENTUM · COMBAT BALANCE",12)
	momentum_bar=ProgressBar.new();momentum_bar.custom_minimum_size.y=18;momentum_bar.show_percentage=false;momentum_bar.add_theme_stylebox_override("background",style(ORANGE,ORANGE,9));momentum_bar.add_theme_stylebox_override("fill",style(TEAL,TEAL,9));momentum_panel.add_child(momentum_bar)
	for kind in ["ghost","center","needle"]:
		var marker:=ColorRect.new();marker.mouse_filter=MOUSE_FILTER_IGNORE;marker.color=Color(1,1,1,.35) if kind=="ghost" else Color(1,1,1,.9);momentum_bar.add_child(marker)
		if kind=="ghost":momentum_ghost=marker
		elif kind=="center":momentum_center=marker
		else:momentum_needle=marker
	momentum_note=label(momentum_panel,"Calculated strength · not victory odds",11,MUTED)
	momentum_bar.tooltip_text="Share of calculated fighting strength: troops, readiness, morale, equipment, leadership and defender terrain. Not a probability or forecast."
	log_panel=panel();var logs:=box(log_panel);var row:=HBoxContainer.new();logs.add_child(row);label(row,"BATTLE LOG",15,TEXT,true).size_flags_horizontal=SIZE_EXPAND_FILL
	button(row,"‹",func():log_page=mini(log_page+1,maxi(0,ceili(round_records.size()/4.0)-1));_refresh_log());button(row,"›",func():log_page=maxi(0,log_page-1);_refresh_log())
	log_text=RichTextLabel.new();log_text.bbcode_enabled=true;log_text.fit_content=true;log_text.scroll_active=false;log_text.add_theme_font_override("normal_font",ui_font);log_text.add_theme_font_size_override("normal_font_size",13);logs.add_child(log_text)
	headline=VBoxContainer.new();headline.mouse_filter=MOUSE_FILTER_IGNORE;add_child(headline)
	headline_title=label(headline,"",42,TEXT,true);headline_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;headline_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;headline_title.add_theme_constant_override("outline_size",6);headline_title.add_theme_color_override("font_outline_color",Color(INK,.7))
	headline_note=label(headline,"",15,TEXT);headline_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func _build_orders()->void:
	left_panel=panel();var left:=box(left_panel);label(left,"YOUR FORMATIONS",17,TEAL,true)
	formation_list=box(left);formation_list.size_flags_vertical=SIZE_EXPAND_FILL
	var pages:=HBoxContainer.new();left.add_child(pages);button(pages,"‹",_formation_page.bind(-1));left_pager=label(pages,"",12,MUTED);left_pager.size_flags_horizontal=SIZE_EXPAND_FILL;button(pages,"›",_formation_page.bind(1))
	button(left,"HOLD ALL",_hold_all,TEAL)
	right_panel=panel();var right:=box(right_panel);selection_label=label(right,"SELECT A FORMATION",20,TEXT,true);selection_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var grid:=GridContainer.new();grid.columns=2;right.add_child(grid)
	for kind:String in BattleRoundOrders.KINDS:
		var b:=button(grid,String(BattleRoundOrders.KINDS[kind].label),_choose_order.bind(kind),TEAL);b.size_flags_horizontal=SIZE_EXPAND_FILL;order_buttons[kind]=b
	var target_heading:=HBoxContainer.new();right.add_child(target_heading);target_caption=label(target_heading,"TARGET",12,ORANGE);target_caption.size_flags_horizontal=SIZE_EXPAND_FILL
	button(target_heading,"‹",_target_page.bind(-1));button(target_heading,"›",_target_page.bind(1));targets=box(right)
	order_note=label(right,"",13,MUTED);order_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;order_note.size_flags_vertical=SIZE_EXPAND_FILL
	label(right,"Drag to pan · Right-drag to orbit\nWheel zooms at your cursor",11,MUTED)
func _build_result()->void:
	result_panel=panel();result_box=box(result_panel);result_title=label(result_box,"ROUND RESULT",30,GOLD,true);result_text=label(result_box,"",16);result_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	history_choice=OptionButton.new();history_choice.custom_minimum_size.y=32;history_choice.add_theme_font_override("font",ui_font);result_box.add_child(history_choice)
	policy_box=box(result_box);policy_box.visible=false
	prisoner_choice=_policy(policy_box,"Prisoners",["hold","release","exchange","parole","ransom","execute","enslave"])
	spoils_choice=_policy(policy_box,"Property & spoils",["return property","army stores","reward troops","state treasury","unrestricted plunder"])
	general_choice=_policy(policy_box,"Captured command",["hold","release","ransom","execute"])
	var actions:=HBoxContainer.new();result_box.add_child(actions);replay_button=button(actions,"Replay round",_replay)
	result_primary=button(actions,"NEXT ORDERS →",_continue,GOLD);result_primary.size_flags_horizontal=SIZE_EXPAND_FILL
	result_return=button(result_box,"RETURN TO MAP",_close)
func _policy(parent:Node,title:String,options:Array)->OptionButton:
	var row:=HBoxContainer.new();parent.add_child(row);label(row,title,13).custom_minimum_size.x=150
	var select:=OptionButton.new();select.size_flags_horizontal=SIZE_EXPAND_FILL;select.custom_minimum_size.y=32
	for option:String in options:select.add_item(option.capitalize());select.set_item_metadata(select.item_count-1,option)
	row.add_child(select);return select
func _build_controls()->void:
	bottom=panel();var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",10);bottom.add_child(controls)
	var cameras:=box(controls);cameras.add_theme_constant_override("separation",4);label(cameras,"CAMERA",10,MUTED);var row:=HBoxContainer.new();cameras.add_child(row)
	for mode in ["overview","frontline","director"]:camera_buttons[mode]=button(row,String(mode).capitalize(),_camera.bind(mode))
	var playback:=HBoxContainer.new();cameras.add_child(playback);pause_button=button(playback,"Pause",_pause);speed_button=button(playback,"½×",_speed)
	small_toggle=button(playback,"Orders / roster",func():narrow_orders=not narrow_orders;_layout())
	var center:=box(controls);center.size_flags_horizontal=SIZE_EXPAND_FILL;progress_note=label(center,"",12,MUTED);progress_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	resolve_button=button(center,"RESOLVE ROUND 1 →",_resolve,GOLD);resolve_button.custom_minimum_size.y=42
	resolve_button.add_theme_stylebox_override("normal",style(GOLD,GOLD));resolve_button.add_theme_color_override("font_color",INK);resolve_button.add_theme_font_override("font",display_font);resolve_button.add_theme_font_size_override("font_size",21)
	progress=ProgressBar.new();progress.show_percentage=false;progress.custom_minimum_size.y=6;progress.add_theme_stylebox_override("fill",style(GOLD,GOLD));center.add_child(progress)
	var ends:=box(controls);skip_button=button(ends,"Skip to result →",_skip);retreat_button=button(ends,"Retreat whole army",_retreat,ORANGE);seed_label=label(ends,"",10,MUTED)
func _initialize()->void:
	context=MilitaryCampaign.active_engagement.duplicate(true)
	if context.is_empty() and not MilitaryCampaign.battle_history.is_empty():
		context=MilitaryCampaign.battle_history.front().duplicate(true)
		if history_seed>=0:
			for past:Dictionary in MilitaryCampaign.battle_history:
				if int(past.get("seed",-1))==history_seed:context=past.duplicate(true);break
		finished_context=context.duplicate(true)
	home_side=0 if String(context.get("home_side","defender"))=="attacker" else 1
	var a:Dictionary=context.get("attacker",context.get("attacker_result",{}));var d:Dictionary=context.get("defender",context.get("defender_result",{}))
	initial_forces=[a.duplicate(true),d.duplicate(true)]
	for side in 2:
		for r:Dictionary in context.get("rounds",[]):
			var losses:Array=r.get(("attacker" if side==0 else "defender")+"_cohort_losses",[])
			for i in mini(losses.size(),initial_forces[side].get("formations",[]).size()):initial_forces[side].formations[i]["count"]+=int(losses[i])
	view.set_landscape(context);view.reset(initial_forces[0],initial_forces[1])
	present(a,d,{},String(context.get("outcome","")),context.get("rounds",[]))
	heading.text=String(context.get("target_region_name",context.get("threat",{}).get("target_region_name","BATTLEFIELD"))).to_upper()
	city_button.disabled=String(context.get("target_region_id",context.get("threat",{}).get("target_region_id",""))).is_empty()
	seed_label.text="BATTLE SEED %s"%str(context.get("seed","—")) if OS.has_feature("editor") or ProjectSettings.get_setting("application/config/custom_user_dir_name","").contains("Test") else ""
	if not MilitaryCampaign.active_engagement.is_empty():MilitaryCampaign.active_engagement["awaiting_player_view"]=true;phase="orders"
	else:phase="ended"
	_rebuild_orders();_rebuild_plates();_phase_ui()
	if phase=="ended":_show_result()

func present(attacker:Dictionary,defender:Dictionary,record:Dictionary={},outcome:String="",records:Array=[])->void:
	cached_forces=[attacker.duplicate(true),defender.duplicate(true)];current_record=record.duplicate(true);final_outcome=outcome;round_records=records.duplicate(true)
	view.apply_snapshot(attacker,defender,record,outcome)
	for group in view.groups:group.banner.visible=false
	_refresh_armies();_refresh_log();_rebuild_plates()
func _round()->int:return round_records.size()
func _forms(side:int)->Array:return cached_forces[side].get("formations",[]) if cached_forces.size()==2 else []
func _count(force:Dictionary)->int:return int(force.get("troops",force.get("remaining_troops",0)))
func _name(side:int,index:int)->String:
	var forms:=_forms(side)
	if index<0 or index>=forms.size():return "No formation"
	return "%d · %s"%[index+1,String(forms[index].get("name",forms[index].get("unit",forms[index].get("unit_id","Formation")))).replace("_"," ").capitalize()]
func _orders()->Dictionary:return MilitaryCampaign.active_engagement.get("formation_orders",{})
func _unordered()->int:
	var missing:=0
	for i in _forms(home_side).size():
		if int(_forms(home_side)[i].get("count",0))<=0:continue
		var order:Dictionary=_orders().get(str(i),{})
		if order.is_empty() or not BattleRoundOrders.validate(_forms(home_side),_forms(1-home_side),i,String(order.get("kind","")),int(order.get("target",-1))).is_empty():missing+=1
	return missing
func _hold_all()->void:
	if phase!="orders":return
	for i in _forms(home_side).size():
		if int(_forms(home_side)[i].get("count",0))>0:MilitaryCampaign.set_battle_formation_order(i,"hold")
	_rebuild_orders();_phase_ui()
func _choose_order(kind:String)->void:
	if phase!="orders":return
	var result:Dictionary=MilitaryCampaign.set_battle_formation_order(selected_index,kind,target_index if kind in ["advance","charge"] else -1)
	if not result.get("ok",false):order_note.text=String(result.get("error","Select a living enemy formation first."));return
	_rebuild_orders();_phase_ui()
func _select(index:int)->void:
	selected_index=index;formation_page=index/_roster_capacity();_rebuild_orders()
func _target(index:int)->void:
	target_index=index;_rebuild_orders()
func _roster_capacity()->int:return 2 if size.y<740 else (3 if size.y<850 else 5)
func _formation_page(delta:int)->void:
	formation_page=clampi(formation_page+delta,0,maxi(0,(_forms(home_side).size()-1)/_roster_capacity()));_rebuild_orders()
func _target_capacity()->int:return 1 if size.y<800 else 3
func _target_page(delta:int)->void:
	target_page=clampi(target_page+delta,0,maxi(0,(_forms(1-home_side).size()-1)/_target_capacity()));_rebuild_orders()
func _rebuild_orders()->void:
	clear_children(formation_list);clear_children(targets)
	var own:=_forms(home_side);var enemy:=_forms(1-home_side)
	var capacity:=_roster_capacity();formation_page=clampi(formation_page,0,maxi(0,(own.size()-1)/capacity))
	selected_index=clampi(selected_index,0,maxi(0,own.size()-1))
	for i in range(formation_page*capacity,mini(own.size(),formation_page*capacity+capacity)):
		var f:Dictionary=own[i];var order:Dictionary=_orders().get(str(i),{})
		var b:=button(formation_list,"%s\n%d fighting · %s"%[_name(home_side,i),int(f.get("count",0)),String(order.get("kind","NO ORDER")).to_upper()],_select.bind(i),TEAL if i==selected_index else TEXT)
		b.tooltip_text="Morale: %d%% · %s"%[roundi(float(cached_forces[home_side].get("morale",1))*100),"Broken" if float(cached_forces[home_side].get("morale",1))<=.15 else ("Wavering" if float(cached_forces[home_side].get("morale",1))<.42 else "Steady")];b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.custom_minimum_size.y=50;b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;b.disabled=int(f.get("count",0))<=0
	left_pager.text="%d / %d"%[formation_page+1,maxi(1,ceili(float(own.size())/capacity))]
	selection_label.text=_name(home_side,selected_index)
	for kind in order_buttons:
		order_buttons[kind].tooltip_text=String(BattleRoundOrders.KINDS[kind].get("description",""))
		var active_kind:=String(_orders().get(str(selected_index),{}).get("kind",""))
		order_buttons[kind].add_theme_stylebox_override("normal",style(TEAL if kind==active_kind else Color("192226")))
		order_buttons[kind].add_theme_color_override("font_color",INK if kind==active_kind else TEAL)
		order_buttons[kind].disabled=own.is_empty() or int(own[selected_index].get("count",0))<=0
	var target_capacity:=_target_capacity();target_page=clampi(target_page,0,maxi(0,(enemy.size()-1)/target_capacity))
	target_caption.text="TARGET · %d / %d"%[target_page+1,maxi(1,ceili(float(enemy.size())/target_capacity))]
	for i in range(target_page*target_capacity,mini(enemy.size(),target_page*target_capacity+target_capacity)):
		var b:=button(targets,"%s · %d"%[_name(1-home_side,i),int(enemy[i].get("count",0))],_target.bind(i),ORANGE if target_index==i else TEXT)
		b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;b.disabled=int(enemy[i].get("count",0))<=0
	var selected:Dictionary=_orders().get(str(selected_index),{})
	order_note.text="Select an enemy target, then Advance or Charge. Hold and Fall back need no target."
	if not selected.is_empty():
		order_note.text=String(BattleRoundOrders.KINDS.get(selected.get("kind","hold"),{}).get("description",""))
		if int(selected.get("target",-1))>=0:order_note.text+="\nTarget: "+_name(1-home_side,int(selected.target))
	_rebuild_plates()
func _refresh_armies()->void:
	if cached_forces.size()!=2:return
	for side in 2:
		var force:Dictionary=cached_forces[side];var losses:Dictionary=BattleLossSummary.from_rounds(round_records,side,_count(force))
		force_labels[side].title.text=String(force.get("name","Your army" if side==home_side else "Enemy army")).to_upper()+(" · YOURS" if side==home_side else "")
		force_labels[side].values.text="%d FIGHTING    %d OUT    %d%% MORALE"%[_count(force),int(losses.get("out_of_action",0)),roundi(float(force.get("morale",1))*100)]
		force_labels[side].values.tooltip_text="Out of action: %d dead · %d wounded · %d fled / scattered. Lasting disabilities: %d. Unclassified: %d. Fighting is the remaining active personnel, not the number of decorative figures."%[int(losses.get("dead",0)),int(losses.get("wounded",0)),int(losses.get("scattered",0)),int(losses.get("disabled",0)),int(losses.get("unclassified",0))]
	var a:Dictionary=MilitaryCampaign.combat_summary(cached_forces[0],cached_forces[1]);var d:Dictionary=MilitaryCampaign.combat_summary(cached_forces[1],cached_forces[0],float(context.get("terrain_defense",1)))
	var av:=float(a.get("effective_strength",0));var dv:=float(d.get("effective_strength",0));momentum_value=100*av/(av+dv) if av+dv>0 else 50;strength_history[_round()]=momentum_value;previous_momentum=float(strength_history.get(_round()-1,momentum_value))
	var change:=roundi(momentum_value-previous_momentum)
	momentum_label.text="STRENGTH · %s · %d%% / %d%%%s"%["Attackers lead" if momentum_value>52 else ("Defenders lead" if momentum_value<48 else "Even"),roundi(momentum_value),100-roundi(momentum_value),(" · %+d"%change) if not current_record.is_empty() and change!=0 else ""]
	momentum_label.tooltip_text="Percentages are the attacker / defender shares of calculated combat strength. The signed change is the attacker share change in percentage points since the preceding round."
	momentum_label.add_theme_color_override("font_color",TEAL if momentum_value>=50 else ORANGE)
	momentum_note.text="Strength share, not odds · Morale breaks at 15%" if current_record.is_empty() else "%s · Morale breaks at 15%%"%String(current_record.get("intensity","Contact"))
func _resolve()->void:
	if phase!="orders" or _unordered()>0 or MilitaryCampaign.active_engagement.is_empty():return
	phase="resolving";resolve_count+=1
	var committed:Dictionary=MilitaryCampaign.advance_engagement("hold")
	_capture_round(committed);_start_presentation()
func _capture_round(committed:Dictionary={})->void:
	context=MilitaryCampaign.active_engagement.duplicate(true)
	if context.is_empty():
		if committed.has("rounds"):finished_context=committed.duplicate(true)
		context=finished_context.duplicate(true) if not finished_context.is_empty() else MilitaryCampaign.battle_history.front().duplicate(true)
	else:MilitaryCampaign.active_engagement["awaiting_player_view"]=true
	var records:Array=context.get("rounds",[]);var record:Dictionary=records.back() if not records.is_empty() else {}
	present(context.get("attacker",context.get("attacker_result",{})),context.get("defender",context.get("defender_result",{})),record,String(context.get("outcome","")),records)
func _start_presentation()->void:
	phase="resolving";elapsed=0;playback_paused=false;_camera("director");_spawn_losses();_phase_ui()
	headline_title.text=_event_text(current_record).to_upper()
	if headline_title.text.is_empty():headline_title.text="CONTACT ON THE LINE"
	headline_note.text="Round %d · %d of your troops and %d enemy troops out of action"%[_round(),_record_loss(home_side),_record_loss(1-home_side)]
func _event_text(record:Dictionary)->String:
	var event:=String(record.get("event",""))
	if event.is_empty() or event=="No decisive local event.":return String(record.get("intensity","Contact on the line"))
	return event.replace("River Host",String(cached_forces[0].get("name","Attackers"))).replace("Hill Guard",String(cached_forces[1].get("name","Defenders")))
func _record_loss(side:int)->int:
	return int(current_record.get(("attacker" if side==0 else "defender")+"_losses",0))
func _process(delta:float)->void:
	if not is_instance_valid(view):return
	momentum_bar.value=lerpf(momentum_bar.value,momentum_value,minf(1,delta*3))
	momentum_needle.position=Vector2(momentum_bar.size.x*momentum_bar.value/100-2,-2);momentum_needle.size=Vector2(4,momentum_bar.size.y+4)
	momentum_center.position=Vector2(momentum_bar.size.x*.5-1,-3);momentum_center.size=Vector2(2,momentum_bar.size.y+6)
	momentum_ghost.position=Vector2(momentum_bar.size.x*minf(previous_momentum,momentum_bar.value)/100,0);momentum_ghost.size=Vector2(momentum_bar.size.x*absf(momentum_bar.value-previous_momentum)/100,momentum_bar.size.y);momentum_ghost.modulate.a=clampf(1-elapsed/2.5,0,1) if phase=="resolving" else 0
	view.playback_speed=0 if playback_paused else speed
	if phase=="resolving":
		if not playback_paused:elapsed+=delta*speed
		progress.value=100*minf(1,elapsed/DURATION);progress_note.text="%s ROUND %d · %.1fs / %.0fs"%["REPLAYING" if replaying else "RESOLVING",_round(),minf(elapsed,DURATION),DURATION]
		headline.visible=elapsed>1.1 and elapsed<DURATION-.4
		if elapsed>=DURATION:_finish_presentation()
	_update_markers()
	for item in floats:
		if is_instance_valid(item.node):item.node.position=_formation_point(item.side,item.index)+Vector2(-20,44-elapsed*15);item.node.modulate.a=clampf(1-elapsed/DURATION,0,1)
func _finish_presentation()->void:
	if phase!="resolving":return
	if replaying:
		replaying=false;_capture_round();view.reset(initial_forces[0],initial_forces[1]);view.apply_snapshot(cached_forces[0],cached_forces[1],current_record,final_outcome);_rebuild_plates();phase=replay_return
	else:phase="result" if not MilitaryCampaign.active_engagement.is_empty() else "ended"
	_show_result();_phase_ui()
func _skip()->void:
	if phase=="resolving":elapsed=DURATION;_finish_presentation()
func _pause()->void:
	playback_paused=not playback_paused;pause_button.text="Resume" if playback_paused else "Pause"
func _speed()->void:
	speed=.5 if speed==1 else 1;speed_button.text="1×" if speed==.5 else "½×"
func _show_result()->void:
	var ended:=phase=="ended"
	result_title.text="ROUND %d COMPLETE"%_round()
	if ended:result_title.text="VICTORY" if String(context.get("winner",""))==String(cached_forces[home_side].get("name","")) else ("WITHDRAWAL" if bool(context.get("orders",{}).get("retreated",false)) else ("DEFEAT" if not String(context.get("winner","")).is_empty() else "BATTLE ENDED"))
	result_text.text="Your army: %d fighting · %d out this round\nEnemy army: %d fighting · %d out this round\n\n%s"%[_count(cached_forces[home_side]),_record_loss(home_side),_count(cached_forces[1-home_side]),_record_loss(1-home_side),("Review the aftermath before choosing the next operation." if not MilitaryCampaign.pending_aftermath.is_empty() else "The result is recorded in the campaign. Return to the map when ready.") if ended else "The battle is paused. Review losses, then give the next orders."]
	if ended:
		var termination:Dictionary=context.get("termination",{})
		result_text.text="Active at contact end: Your army %d · Enemy %d.\n%d of the defeated army's remaining troops were taken prisoner.\nDefeated commander: %s."%[_count(cached_forces[home_side]),_count(cached_forces[1-home_side]),int(termination.get("prisoners",0)),String(termination.get("commander_fate","not recorded"))]
		if not MilitaryCampaign.pending_aftermath.is_empty():result_text.text+="\nYour decisions about captives and property are still pending."
		var strategic:Dictionary=context.get("strategic_outcome",{})
		if strategic.get("region_captured",false):result_text.text+="\nCity captured. Occupation assignments are recorded in the campaign."
		for side in 2:force_labels[side].values.text=force_labels[side].values.text.replace("FIGHTING","AT CONTACT END")
	history_choice.clear()
	for i in round_records.size():history_choice.add_item("Round %d"%(i+1),i)
	if not round_records.is_empty():history_choice.select(round_records.size()-1)
	replay_button.disabled=round_records.is_empty();policy_box.hide();result_return.visible=not ended or not MilitaryCampaign.pending_aftermath.is_empty()
	result_primary.text="REVIEW AFTERMATH →" if ended and not MilitaryCampaign.pending_aftermath.is_empty() else ("RETURN TO MAP" if ended else "NEXT ORDERS →")
func _continue()->void:
	if phase=="result":phase="orders";_rebuild_orders();_phase_ui()
	elif phase=="ended":
		if MilitaryCampaign.pending_aftermath.is_empty():_close()
		else:_open_aftermath()
	elif phase=="aftermath":
		var result:Dictionary=MilitaryCampaign.resolve_aftermath(prisoner_choice.get_item_metadata(prisoner_choice.selected),spoils_choice.get_item_metadata(spoils_choice.selected),general_choice.get_item_metadata(general_choice.selected))
		result_text.text=String(result.get("error",result.get("message","Aftermath recorded.")))
		if not result.has("error"):phase="ended";policy_box.hide();result_return.hide();result_primary.text="RETURN TO MAP";_phase_ui()
func _open_aftermath()->void:
	phase="aftermath";result_title.text="THE AFTERMATH";result_return.show()
	var pending:Dictionary=MilitaryCampaign.pending_aftermath
	var home_won:=String(pending.get("captor",""))==String(pending.get("home_force_name",""))
	result_text.text="%d captives · %s\n%s"%[int(pending.get("prisoners",0)),"Your army controls the captives and property." if home_won else "The enemy holds these prisoners.","Choose their treatment. Decisions enter the campaign record." if home_won else "Acknowledge the outcome to record your captured personnel."]
	policy_box.visible=home_won;general_choice.disabled=not bool(pending.get("captured_general",false));replay_button.hide();history_choice.hide();result_primary.text="CONFIRM DECISIONS →" if home_won else "ACKNOWLEDGE →";_phase_ui()
func _replay()->void:
	if phase not in ["result","ended"] or round_records.is_empty():return
	replay_return=phase;replaying=true
	var index:=history_choice.selected;var historical:Array=cached_forces.duplicate(true)
	for side in 2:
		var key:="attacker" if side==0 else "defender";var forms:Array=historical[side].get("formations",[])
		for later in range(index+1,round_records.size()):
			var losses:Array=round_records[later].get(key+"_cohort_losses",[])
			for i in mini(losses.size(),forms.size()):forms[i]["count"]=int(forms[i].get("count",0))+int(losses[i])
		var total:=0
		for f in forms:total+=int(f.get("count",0))
		historical[side]["troops"]=total;historical[side]["remaining_troops"]=total
		historical[side]["morale"]=round_records[index].get(key+"_morale",historical[side].get("morale",1))
	var record:Dictionary=round_records[index].duplicate(true)
	var before:Array=historical.duplicate(true)
	for side in 2:
		var losses:Array=record.get(("attacker" if side==0 else "defender")+"_cohort_losses",[])
		for i in mini(losses.size(),before[side].get("formations",[]).size()):before[side].formations[i]["count"]+=int(losses[i])
	view.reset(before[0],before[1]);present(historical[0],historical[1],record,final_outcome if index==round_records.size()-1 else "",round_records.slice(0,index+1))
	_start_presentation();headline_title.text="ROUND %d REPLAY"%(index+1)
func _retreat()->void:
	if phase!="orders" or MilitaryCampaign.active_engagement.is_empty():return
	phase="resolving";resolve_count+=1;var committed:Dictionary=MilitaryCampaign.advance_engagement("retreat");_capture_round(committed);_start_presentation()
func _city_report()->void:
	CivilizationSystem.city_intelligence.open(String(context.get("target_region_id",context.get("threat",{}).get("target_region_id",""))))
func _close()->void:queue_free()
func _exit_tree()->void:
	get_window().set_deferred("content_scale_size",previous_scale_size);get_window().set_deferred("content_scale_aspect",previous_scale_aspect)
func _camera(mode:String)->void:
	view.cinematic=mode=="director"
	if mode=="overview":view.target=Vector3(0,1,0);view.zoom=85;view.elevation=.85
	elif mode=="frontline":view.target=Vector3(0,1,0);view.zoom=32;view.elevation=.48
	view._camera_update()
	for key in camera_buttons:camera_buttons[key].modulate=TEAL if key==mode else TEXT
func _view_input(event:InputEvent)->void:
	var ratio:=Vector2(viewport.size)/stage.size
	if event is InputEventMouseMotion:
		if event.button_mask & (MOUSE_BUTTON_MASK_LEFT|MOUSE_BUTTON_MASK_MIDDLE):
			camera_drag_distance+=event.relative.length()
			if camera_drag_distance>5 or event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:view.pan((event.position-event.relative)*ratio,event.position*ratio)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:view.orbit(-event.relative.x*.006,event.relative.y*.005)
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:camera_pressed=true;camera_drag_distance=0
			else:
				if camera_pressed and camera_drag_distance<=5:view.pick(event.position*ratio)
				camera_pressed=false
		elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:view.zoom_at(event.position*ratio,-view.zoom*.12)
		elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:view.zoom_at(event.position*ratio,view.zoom*.12)
func _refresh_log()->void:
	if not is_instance_valid(log_text):return
	var lines:PackedStringArray=[]
	var finish:=maxi(0,round_records.size()-log_page*4)
	for i in range(finish-1,maxi(-1,finish-5),-1):
		var r:Dictionary=round_records[i];var own:="attacker" if home_side==0 else "defender";var enemy:="defender" if home_side==0 else "attacker"
		lines.append("[color=#f2c14e]ROUND %d[/color] · %s\nYour losses: %d · Enemy losses: %d"%[i+1,String(r.get("intensity","Contact")),int(r.get(own+"_losses",0)),int(r.get(enemy+"_losses",0))])
	log_text.text="\n\n".join(lines) if not lines.is_empty() else "Contact has not begun.\nGive your formations orders."
func _phase_ui()->void:
	phase_label.text="● ROUND %d · "%(_round()+1 if phase=="orders" else _round())+{"orders":"GIVING ORDERS","resolving":"REPLAY" if replaying else "RESOLVING","result":"ROUND RESULT","ended":"BATTLE ENDED","aftermath":"AFTERMATH"}.get(phase,phase.to_upper())
	resolve_button.visible=phase=="orders";resolve_button.disabled=_unordered()>0;resolve_button.text="RESOLVE ROUND %d →"%(_round()+1)
	progress.visible=phase=="resolving";skip_button.visible=phase=="resolving";retreat_button.visible=phase=="orders"
	result_panel.visible=phase in ["result","ended","aftermath"];log_panel.visible=phase in ["resolving","result","ended"]
	vignette.visible=phase=="resolving";headline.hide();pause_button.text="Resume" if playback_paused else "Pause"
	progress_note.text="%d %s · Hold all to keep position"%[_unordered(),"formation needs an order" if _unordered()==1 else "formations need orders"] if _unordered()>0 else "Orders ready · combat starts when you resolve"
	if phase!="orders" and phase!="resolving":progress_note.text="Simulation paused · every number comes from the battle record"
	_layout()
func _layout()->void:
	if not is_instance_valid(bottom):return
	var w:=size.x;var h:=size.y;var compact:=w<1150;var narrow:=w<960
	var test_top:=22.0 if ProjectSettings.get_setting("application/config/custom_user_dir_name","").contains("Test") else 0.0
	chrome.position=Vector2(0,test_top);chrome.size=Vector2(w,56)
	heading.add_theme_font_size_override("font_size",20 if compact else 26);heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	armies_strip.position=Vector2(0,test_top+56);armies_strip.size=Vector2(w,128 if compact else 90)
	if compact:
		army_panels[0].position=Vector2.ZERO;army_panels[0].size=Vector2(w*.5,76);army_panels[1].position=Vector2(w*.5,0);army_panels[1].size=Vector2(w*.5,76)
		momentum_panel.position=Vector2(w*.2,78);momentum_panel.size=Vector2(w*.6,50)
	else:
		army_panels[0].position=Vector2.ZERO;army_panels[0].size=Vector2(w*.29,86);army_panels[1].position=Vector2(w*.71,0);army_panels[1].size=Vector2(w*.29,86)
		momentum_panel.position=Vector2(w*.30,14);momentum_panel.size=Vector2(w*.40,65)
	var top:=test_top+(218 if compact else 154);var available:=maxf(240,h-top-144)
	left_panel.position=Vector2(16,top);left_panel.size=Vector2(230 if compact else 256,0)
	right_panel.position=Vector2(w-(276 if compact else 316),top);right_panel.size=Vector2(260 if compact else 300,0)
	left_panel.visible=phase=="orders" and (not narrow or not narrow_orders);right_panel.visible=phase=="orders" and (not narrow or narrow_orders)
	if narrow:right_panel.position.x=16
	small_toggle.visible=narrow and phase=="orders"
	log_panel.position=Vector2(w-296,top);log_panel.size=Vector2(280,minf(available,300))
	headline.position=Vector2(w*.15,h*.63);headline.size=Vector2(w*.70,100);headline_title.add_theme_font_size_override("font_size",30 if compact else 42)
	result_panel.size=Vector2(minf(520,w-32),0)
	var rh:=result_panel.get_combined_minimum_size().y
	result_panel.position=Vector2((w-minf(520,w-32))*.5,maxf(top,(h-rh)*.5))
	if phase in ["result","ended","aftermath"] and w<1250:log_panel.hide()
	momentum_back.position=momentum_panel.position-Vector2(12,8);momentum_back.size=momentum_panel.size+Vector2(24,16)
	bottom.size=Vector2(w-24,0);bottom.position=Vector2(12,h-bottom.get_combined_minimum_size().y-12)
func _formation_point(side:int,index:int)->Vector2:
	var forms:=_forms(side)
	if index<0 or index>=forms.size():return Vector2(-1000,-1000)
	var model:=UnitVisualCatalog.model(forms[index],"equipment",index)
	for group in view.groups:
		if int(group.side)==side and String(group.id)==model:
			var world:Vector3=view.armies[side].to_global(group.center+Vector3(0,3,0))
			if view.camera.is_position_behind(world):return Vector2(-1000,-1000)
			return view.camera.unproject_position(world)*stage.size/Vector2(viewport.size)
	return Vector2(-1000,-1000)
func _rebuild_plates()->void:
	for item in plates:
		if is_instance_valid(item.node):item.node.queue_free()
	plates.clear()
	if not is_instance_valid(marker_layer):return
	for side in 2:
		for i in mini(12,_forms(side).size()):
			if int(_forms(side)[i].get("count",0))<=0:continue
			var b:=button(marker_layer,"%s · %d"%[_name(side,i),int(_forms(side)[i].get("count",0))],_select.bind(i) if side==home_side else _target.bind(i),TEAL if side==home_side else ORANGE)
			b.custom_minimum_size=Vector2(0,26);b.add_theme_font_size_override("font_size",11);b.add_theme_stylebox_override("normal",style(Color(INK,.82),TEAL if side==home_side else ORANGE,4));plates.append({"node":b,"side":side,"index":i})
	for group in view.groups:group.banner.visible=false
	for general in view.generals:
		general.label.visible=false
		var detail:Dictionary=general.details();var b:=button(marker_layer,"GENERAL · %s\n%s"%[String(detail.name),String(detail.fate).to_upper()],HistoricalFigures.open_chronicle.bind(String(detail.figure_id)),GOLD)
		b.add_theme_font_size_override("font_size",11);b.custom_minimum_size.y=30;b.disabled=String(detail.figure_id).is_empty();b.add_theme_stylebox_override("disabled",style(Color(INK,.85),GOLD,4));b.add_theme_color_override("font_disabled_color",GOLD);plates.append({"node":b,"general":general})
func _update_markers()->void:
	var occupied:Array[Rect2]=[]
	for item in plates:
		var b:Button=item.node;var point:Vector2
		if item.has("general"):
			if not is_instance_valid(item.general):b.hide();continue
			var world:Vector3=item.general.global_position+Vector3(0,6,0)
			point=view.camera.unproject_position(world)*stage.size/Vector2(viewport.size) if not view.camera.is_position_behind(world) else Vector2(-1000,-1000)
		else:point=_formation_point(item.side,item.index)
		b.position=point-Vector2(b.size.x*.5,28)
		for attempt in 32:
			var collision:=false
			for rect in occupied:
				if rect.intersects(Rect2(b.position,b.size)):
					b.position.y=rect.position.y-b.size.y-5;collision=true;break
			if not collision:break
		b.visible=phase in ["orders","resolving"] and b.position.y>armies_strip.position.y+armies_strip.size.y and b.position.y<bottom.position.y-32 and b.position.x>0 and b.position.x+b.size.x<size.x
		if b.visible and headline.visible and Rect2(b.position,b.size).intersects(Rect2(headline.position,headline.size)):b.visible=false
		if b.visible:occupied.append(Rect2(b.position,b.size))
	var a:=_formation_point(home_side,selected_index);var t:=_formation_point(1-home_side,target_index)
	selected_ring.visible=phase=="orders" and a.x>0;target_ring.visible=phase=="orders" and t.x>0;arrow.visible=phase=="orders" and a.x>0 and t.x>0
	for pair in [[selected_ring,a],[target_ring,t]]:
		var points:=PackedVector2Array()
		for i in 33:points.append(pair[1]+Vector2(cos(i*TAU/32)*35,sin(i*TAU/32)*12))
		pair[0].points=points
	if arrow.visible:
		var direction:Vector2=(t-a).normalized();var wing:=direction.rotated(PI*.75)*14
		arrow.points=PackedVector2Array([a,t,t+wing,t,t+direction.rotated(-PI*.75)*14])
func _spawn_losses()->void:
	for item in floats:
		if is_instance_valid(item.node):item.node.queue_free()
	floats.clear()
	for side in 2:
		var losses:Array=current_record.get(("attacker" if side==0 else "defender")+"_cohort_losses",[])
		for i in mini(12,losses.size()):
			if int(losses[i])<=0:continue
			var node:=label(marker_layer,"−%d"%int(losses[i]),34,ORANGE if side==home_side else TEAL,true);node.mouse_filter=MOUSE_FILTER_IGNORE
			node.add_theme_constant_override("outline_size",5);node.add_theme_color_override("font_outline_color",INK)
			floats.append({"node":node,"side":side,"index":i})
func _selected(data:Dictionary)->void:
	if data.has("figure_id"):HistoricalFigures.open_chronicle(String(data.figure_id));return
	var side:=int(data.get("side",home_side));var name:=String(data.get("name",""))
	for i in _forms(side).size():
		if UnitVisualCatalog.model(_forms(side)[i],"equipment",i).replace("_"," ").capitalize()==name:
			if side==home_side:_select(i)
			else:_target(i)
			return
