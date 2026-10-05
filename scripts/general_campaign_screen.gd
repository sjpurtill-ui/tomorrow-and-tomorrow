extends PanelContainer
var title:Label
var kpis:Label
var conversation:RichTextLabel
var entry:LineEdit
var status:Label
var commit:Button
var send:Button
var next_button:Button
var map:Control
var map_stage:SubViewportContainer
var map_camera:Camera3D
var body:HBoxContainer
var right:VBoxContainer
var last_battle_seed:=-1
var shown_messages:=""

func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var style:=StyleBoxFlat.new();style.bg_color=Color("0c171c")
	for edge in ["left","right","top","bottom"]:style.set("content_margin_"+edge,14)
	add_theme_stylebox_override("panel",style)
	add_theme_font_size_override("font_size",16)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",12);add_child(root)
	var header:=HBoxContainer.new();root.add_child(header)
	title=_label(header,"THE ALDERFORD WAR",23);title.size_flags_horizontal=SIZE_EXPAND_FILL
	var level:=OptionButton.new();level.name="Difficulty"
	for value in ["Easy","Medium","Hard"]:level.add_item(value)
	level.select(["easy","medium","hard"].find(WorldSimulation.campaign.difficulty));level.disabled=int(WorldSimulation.campaign.state.get("turn",0))>0
	level.tooltip_text="Easy: slower adaptation. Medium: coalition planning. Hard: shared observations and more event-driven alternatives. Equal resource rules. Choose before the first commitment."
	level.item_selected.connect(func(index:int):WorldSimulation.campaign.difficulty=["easy","medium","hard"][index]);header.add_child(level)
	_button(header,"MAP",_show_map)
	_button(header,"WATCH",_watch)
	_button(header,"CLOSE",func():hide())
	kpis=_label(root,"",16);kpis.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body=HBoxContainer.new();body.size_flags_vertical=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",16);root.add_child(body)
	var left:=PanelContainer.new();left.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_child(left)
	map_stage=SubViewportContainer.new();map_stage.stretch=true;left.add_child(map_stage)
	var map_view:=SubViewport.new();map_view.own_world_3d=false;map_view.world_3d=WorldSimulation.campaign.terrain.get_world_3d();map_view.size=Vector2i(800,600);map_stage.add_child(map_view)
	map_camera=Camera3D.new();map_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;map_camera.far=2000;map_camera.near=.01;map_view.add_child(map_camera)
	var origin:Vector2=WorldSimulation.campaign.state.origin
	map_camera.position=Vector3(origin.x,100,origin.y);map_camera.look_at(Vector3(origin.x,0,origin.y),Vector3(0,0,-1));map_camera.size=80
	map=preload("res://scripts/general_campaign_map.gd").new();map.size_flags_vertical=SIZE_EXPAND_FILL;left.add_child(map)
	right=VBoxContainer.new();right.custom_minimum_size.x=360;body.add_child(right)
	_label(right,"YOUR GENERAL",12)
	conversation=RichTextLabel.new();conversation.bbcode_enabled=false;conversation.size_flags_vertical=SIZE_EXPAND_FILL;conversation.scroll_following=true;right.add_child(conversation)
	status=_label(right,"",13);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	entry=LineEdit.new();entry.placeholder_text="Ask, disagree, or give an objective…";entry.custom_minimum_size.y=42;entry.text_submitted.connect(_send);right.add_child(entry)
	send=_button(right,"SPEAK TO YOUR GENERAL",func():_send(entry.text))
	commit=_button(right,"COMMIT OBJECTIVE",_commit)
	next_button=_button(right,"PAUSE TO SPEAK",func():
		if WorldSimulation.campaign.state.status=="executing":WorldSimulation.campaign.pause_to_speak()
		else:WorldSimulation.campaign.resume())
	var footer:=HBoxContainer.new();root.add_child(footer)
	_button(footer,"SAVE CAMPAIGN",func():
		var result:=SaveSystem.save_game("river_war");status.text=String(result.get("message",result.get("error",""))))
	_button(footer,"RETURN TO MY WORLD",func():
		var result:=SaveSystem.load_game("before_river_war")
		if not result.has("error"):get_tree().reload_current_scene()
		else:status.text=String(result.error))
	_label(footer,"Generals execute. You decide the purpose.",13)
	WorldSimulation.campaign.changed.connect(refresh)
	resized.connect(_fit);map.resized.connect(_fit);_fit();_show_map();refresh()

func _label(parent:Node,text:String,font_size:int)->Label:
	var label:=Label.new();label.text=text;label.add_theme_font_size_override("font_size",font_size);parent.add_child(label);return label
func _button(parent:Node,text:String,call:Callable)->Button:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=36;button.pressed.connect(call);parent.add_child(button);return button
func _fit()->void:
	if right:right.custom_minimum_size.x=clampf(size.x*.32,290,430)
	if map_camera and map.size.x>0 and map.size.y>0:map_camera.size=80*map.size.y/minf(map.size.x,map.size.y)
	if title:title.add_theme_font_size_override("font_size",18 if size.x<1000 else 23)
	if kpis:kpis.add_theme_font_size_override("font_size",14 if size.x<1000 else 16)
func _send(text:String)->void:
	if WorldSimulation.general_dialogue.ask(text):entry.clear()
func _commit()->void:
	var result:=WorldSimulation.campaign.commit_proposal();refresh();status.text=String(result.get("error",result.get("message","")))
func refresh()->void:
	if not WorldSimulation.campaign.active:return
	var s:Dictionary=WorldSimulation.campaign.state;var a:=WorldSimulation.campaign.army()
	title.text="ALDERFORD · %s · %s"%[preload("res://scripts/calendar_date.gd").words(int(WorldSimulation.state.elapsed_days),true),"Orders resolving" if s.status=="executing" else "Council paused"]
	kpis.text="%d FIT SOLDIERS     %d CASUALTIES     %.1f DAYS OF FOOD     %d%% EQUIPPED"%[int(a.get("troops",0)),int(s.losses),WorldSimulation.campaign.food_days(),roundi(WorldSimulation.campaign.equipment_ratio(a)*100)]
	if float(a.get("morale",1))<.4:kpis.text+="     COHESION SHAKEN"
	kpis.tooltip_text="Fit soldiers can fight now. Casualties counts all losses from action in this war, including soldiers who later recover. Food is carried rations at current strength. Equipment is issued weapons divided by current personnel."
	var text:="%s\n\n"%s.general_name
	for message:Dictionary in s.messages.slice(-10):text+=("YOU" if message.role=="user" else String(s.general_name))+": "+String(message.content)+"\n\n"
	if text!=shown_messages:shown_messages=text;conversation.text=text
	var level:=find_child("Difficulty",true,false) as OptionButton
	if level:level.disabled=int(s.turn)>0
	var proposal:Dictionary=s.proposal
	commit.disabled=proposal.is_empty() or (WorldSimulation.campaign.resolving and s.status=="executing") or WorldSimulation.general_dialogue.pending.has("player")
	commit.text="COMMIT: "+String(proposal.get("action","objective")).to_upper()
	if not proposal.is_empty() and proposal.get("target","home")!="home":commit.text+=" "+String(WorldSimulation.campaign.rival(proposal.target).get("name",""))
	send.disabled=WorldSimulation.general_dialogue.pending.has("player")
	next_button.disabled=s.outcome!="" or (not WorldSimulation.campaign.resolving and s.mission.is_empty())
	next_button.text="PAUSE TO SPEAK" if s.status=="executing" else "CONTINUE MISSION"
	status.text=WorldSimulation.general_dialogue.status if not WorldSimulation.general_dialogue.status.is_empty() else "Discussion pauses time. Committing advances both sides and the wider world."
	if not s.battle.is_empty() and int(s.battle.seed)!=last_battle_seed:_watch()

## The last battle, in the battle panel (hud/battle_view.gd). Viewing does not
## resolve it again.
func _watch()->void:
	if WorldSimulation.campaign.state.get("battle",{}).is_empty():status.text="No battle has occurred yet. The map shows actual mission progress.";return
	var s:Dictionary=WorldSimulation.campaign.state
	var shown:Dictionary=(s.battle as Dictionary).duplicate(true)
	shown["home_side"]=String(shown.get("home_side","attacker"))
	last_battle_seed=int(s.battle.seed)
	preload("res://scripts/hud/battle_view.gd").open(shown,self)

func _process(_delta:float)->void:
	if not WorldSimulation.campaign.active:return
	if WorldSimulation.campaign.resolving:title.text="ALDERFORD · Day %.2f · %s"%[WorldSimulation.state.elapsed_days,WorldSimulation.campaign.state.status]

func _show_map()->void:
	map.show();map_stage.show()
	var at:Vector2=WorldSimulation.campaign.state.origin
	WorldSimulation.campaign.terrain._set_camera_target(Vector3(at.x,0,at.y));WorldSimulation.campaign.terrain.camera.size=80
