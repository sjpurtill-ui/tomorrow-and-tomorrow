extends RefCounted
## THE ARMY BAR AS NUMBERS, as HOI4's bottom bar shows its armies; the
## cards are drawn by hud/army_bar.gd.
##
## One card for the levy at home (while anyone trained stands there), one
## per band in the field, one per town we hold; bands a general leads
## together (a headquarters from the Organization tab, or one general over
## several bands) stand as one army card with its bands listed. Each card:
## the general, the men against full strength, and three bars (gear, will to
## fight, supply), with one state glyph: marching, holding, besieging,
## fighting, broken or hungry (hud/battle_marks.gd).
##
## Numbers come from the one ledger. A band away before signals is known
## from its last runner's report, exactly as the war chart shows it. Gear is
## read the way scripts/equipment_logistics.gd reads it; supply from
## scripts/supply_state.gd when that reading exists, else from the band's own
## recorded ration share. Pure reads; nothing here changes the world.

const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Rations:=preload("res://scripts/field_rations.gd")
const Logistics:=preload("res://scripts/equipment_logistics.gd")
const Orders:=preload("res://scripts/army_orders.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const SUPPLY_PATH:="res://scripts/supply_state.gd"
## Most pressing first: the group's glyph is its most pressing member's.
const STATE_ORDER:=["broken","fighting","hungry","besieging","marching","holding"]

static var _supply_script:Script
static var _supply_checked:=false


static func _host(mc:Node)->Node:
	return mc if mc!=null else MilitaryCampaign


static func _v2(p:Variant)->Vector2:
	if p is Dictionary and (p as Dictionary).has_all(["x","z"]):return Vector2(float(p.x),float(p.z))
	if p is Vector2:return p
	return Vector2.INF


# --- Supply and gear readings ----------------------------------------------------

static func supply_reader()->Script:
	## scripts/supply_state.gd when it is in the game (codex/hoi4-supply).
	if not _supply_checked:
		_supply_checked=true
		if ResourceLoader.exists(SUPPLY_PATH):_supply_script=load(SUPPLY_PATH) as Script
	return _supply_script


## {ratio 0..1, state "well"|"strained"|"starving", words}. A runner's
## report (live=false) is read as it was written, never from today's state.
static func supply_of(force:Dictionary,live:bool=true)->Dictionary:
	var reader:=supply_reader()
	if live and reader!=null and reader.has_method("of_force"):
		var report:Dictionary=reader.call("of_force",force)
		if not report.is_empty():
			return {"ratio":clampf(float(report.get("ratio",1.0)),0.0,1.0),"state":String(report.get("state","well")),"words":String(report.get("words",""))}
	var ratio:=clampf(float(force.get("provision_ratio",force.get("supply_level",1.0))),0.0,1.0)
	var state:="well" if ratio>=0.75 else ("strained" if ratio>=0.45 else "starving")
	if Rations.is_hungry(force) and state=="well":state="strained"
	var words:="Supply %d%%: %s." % [roundi(ratio*100.0),{"well":"fed","strained":"short of food","starving":"going hungry"}[state]]
	return {"ratio":ratio,"state":state,"words":words}


static func supply_color(state:String)->Color:
	var reader:=supply_reader()
	if reader!=null and reader.has_method("state_color"):return reader.call("state_color",state)
	return {"well":T.GREEN,"strained":T.AMBER,"starving":T.RED}.get(state,T.GREEN)


## {share 0..1, issued, required, missing:{item:count}} for these formations.
static func gear_of(formations:Array,mc:Node=null)->Dictionary:
	mc=_host(mc)
	var issued:=0;var required:=0
	var missing:={}
	for f in formations:
		var formation:Dictionary=f
		issued+=mini(int(formation.get("equipment",0)),int(formation.get("equipment_required",formation.get("count",0))))
		required+=int(formation.get("equipment_required",formation.get("count",0)))
		var short:Dictionary=Logistics._formation_needs(mc,formation)
		for item:String in short:
			# Ammunition is told on the supply bar's tooltip, not the gear bar.
			if Logistics.category(item)=="ammunition":continue
			missing[item]=int(missing.get(item,0))+int(short[item])
	return {"share":clampf(float(issued)/maxf(1.0,float(required)),0.0,1.0) if required>0 else 1.0,"issued":issued,"required":required,"missing":missing}


static func gear_words(gear:Dictionary,mc:Node=null)->String:
	var missing:Dictionary=gear.get("missing",{})
	if missing.is_empty():return "Gear %d of %d." % [int(gear.get("issued",0)),int(gear.get("required",0))]
	var parts:PackedStringArray=["Gear %d of %d." % [int(gear.get("issued",0)),int(gear.get("required",0))]]
	for item:String in missing:
		var row:Dictionary=Logistics.row(item,_host(mc))
		parts.append("Short %d %s · %d in store" % [int(missing[item]),String(row.get("name",item)),int(row.get("stock",0))])
	parts.append("Click the gear bar to open production.")
	return "\n".join(parts)


# --- Ink for the bars (hud/army_bar.gd) ------------------------------------------

static func draw_bar(canvas:CanvasItem,rect:Rect2,share:float,fill:Color)->void:
	canvas.draw_rect(rect,Color(T.TRACK,0.85))
	if share>0.0:canvas.draw_rect(Rect2(rect.position,Vector2(rect.size.x*clampf(share,0.0,1.0),rect.size.y)),fill)
	canvas.draw_rect(rect,Color(T.RULE_STRONG,0.7),false,1.0)


## One colour per bar, so gear, will and supply read apart at a glance:
## gear steel blue (amber when short), will violet (red when they are
## close to breaking), supply by its state (green, amber, red).
static func will_color(will:float)->Color:
	return T.RED if will<0.3 else T.VIOLET


static func gear_color(share:float)->Color:
	return T.BLUE if share>=0.999 else (T.AMBER if share>=0.4 else T.RED)


static func will_words(will:float)->String:
	return "Will to fight %d%%%s." % [roundi(will*100.0)," · close to breaking" if will<0.3 else ""]


## "Supply 82%: fed" and the supply reading's own words.
static func supply_line(card:Dictionary)->String:
	var state:=String(card.get("supply_state","well"))
	var head:="Supply %d%%: %s." % [roundi(float(card.get("supply",1.0))*100.0),{"well":"well fed","strained":"short of food","starving":"going hungry"}.get(state,state)]
	var words:=String(card.get("supply_words","")).strip_edges()
	return head if words=="" or words.begins_with("Supply ") else head+"\n"+words


# --- Cards -----------------------------------------------------------------------

static func cards(mc:Node=null)->Array[Dictionary]:
	mc=_host(mc)
	var out:Array[Dictionary]=[]
	if mc==null or WorldSimulation.world==null:return out
	var home:=_home_card(mc)
	if not home.is_empty():out.append(home)
	var singles:Array[Dictionary]=[]
	for a in mc.field_armies:
		var army:Dictionary=a
		if int(army.get("troops",0))<=0 or bool(army.get("embarked",false)):continue
		singles.append(army_card(mc,army))
	out.append_array(_grouped(mc,singles))
	for f in mc.occupation_forces:
		var force:Dictionary=f
		if int(force.get("troops",0))<=0:continue
		out.append(_garrison_card(mc,force))
	return out


static func _general(record:Dictionary)->Dictionary:
	var commander:Dictionary=record.get("commander",{}) if record.get("commander") is Dictionary else {}
	var name:=Orders.general_name(record)
	return {"name":name,"full_name":String(commander.get("name","")),"figure_id":String(commander.get("figure_id",""))} if name!="" else {}


static func army_card(mc:Node,army:Dictionary)->Dictionary:
	var id:=int(army.get("army_id",0))
	var home:=Orders.at_home(army)
	var fighting:bool=mc.command_hierarchy.battle.engaged(id) or mc._army_in_battle(id)
	var live:bool=home or fighting or mc._live_army_reporting()
	var shown:Dictionary=army if live else army.get("last_report",{})
	var unknown:=shown.is_empty()
	if unknown:shown=army
	# A march ordered since that report is known all the same (the order was
	# given here), as the war chart shows it.
	elif not live and String(army.get("status",""))=="moving" and int(army.get("departure_day",-1))>=int(shown.get("day",-1)):
		shown=shown.duplicate();shown["status"]="moving"
	var today:=int(WorldSimulation.state.elapsed_days)
	var men:=int(shown.get("troops",army.get("troops",0)))
	var formations:Array=shown.get("formations",army.get("formations",[]))
	var gear:=gear_of(formations,mc)
	var will:=clampf(float(shown.get("morale",army.get("morale",0.6))),0.0,1.0)
	var supply:=supply_of(army if live else shown,live)
	var besieging:=""
	if String(army.get("status",""))=="besieging":besieging=String(army.get("location_name","the town"))
	if not mc.active_siege.is_empty() and int(mc.active_siege.get("army_id",0))==id:
		besieging=String((mc.active_siege.get("threat",{}) as Dictionary).get("target_region_name","the town"))
	var status:=String(shown.get("status",army.get("status","stationed")))
	var hungry:=Rations.is_hungry(army)
	var context:={"status":status,"fighting":fighting,"hungry":hungry,"broken":will<ArmyMarks.BROKEN_MORALE,"besieging":besieging}
	var state:=BattleMarks.state_of(context)
	var position:=_v2(shown.get("position",army.get("position",{})))
	var destination:=String(army.get("destination_name",""))
	var ordered:Dictionary=army.get("court_order",{}) if army.get("court_order") is Dictionary else {}
	if destination=="" and not ordered.is_empty():destination=String(ordered.get("city_name",""))
	var doing:=ArmyMarks.doing({"status":status,"destination_name":destination,"destination_id":String(army.get("destination_id","")),"location_name":String(army.get("location_name","")),
		"command_status":String(army.get("command_status","")),"at_home":home,"home_km":ArmyMarks.home_km(shown,WorldSimulation.world.player_world_origin),
		"besieging":besieging,"fighting":fighting,"days_left":maxi(0,int(army.get("arrival_day",0))-today)})
	var general:=_general(army)
	var noun:=ArmyMarks.noun(maxi(1,men),EraWords.stage())
	var name:=String(army.get("name","")).strip_edges()
	var title:=("%s's %s" % [String(general.name),noun]) if not general.is_empty() else (name if name!="" else "Our "+noun)
	return {"id":"army:%d" % id,"kind":"army","army_id":id,"members":[id],"title":title,"short":String(general.get("name",name if name!="" else noun.capitalize())),
		"general":general,"noun":noun,"men":men,"full":maxi(men,ArmyMarks.full_strength(army)),"gear":gear.share,"gear_detail":gear,"will":will,
		"supply":float(supply.ratio),"supply_state":String(supply.state),"supply_words":String(supply.words),"state":state,"doing":doing,
		"position":position,"report_age":0 if live else maxi(0,today-int(shown.get("day",today))),"unknown":unknown,"home":home}


static func _home_card(mc:Node)->Dictionary:
	var force:Dictionary=mc.home_army
	var men:=int(force.get("troops",0))
	if men<=0:return {}
	var gear:=gear_of(force.get("formations",[]),mc)
	var supply:=supply_of(force)
	var leader:=Orders.war_leader_name()
	var noun:=ArmyMarks.noun(maxi(1,men),EraWords.stage())
	var fighting:bool=mc._home_battle_running()
	return {"id":"home","kind":"home","army_id":Orders.HOME,"members":[],"title":("%s's %s at home" % [leader,"levy" if noun=="band" else noun]) if leader!="" else "The levy at home",
		"short":"Home","general":{"name":leader} if leader!="" else {},"noun":noun,"men":men,"full":maxi(men,ArmyMarks.full_strength(force)),
		"gear":gear.share,"gear_detail":gear,"will":clampf(float(force.get("morale",0.6)),0.0,1.0),"supply":float(supply.ratio),"supply_state":String(supply.state),
		"supply_words":String(supply.words),"state":"fighting" if fighting else "holding","doing":"in battle at home" if fighting else "at home",
		"position":WorldSimulation.world.player_world_origin,"report_age":0,"unknown":false,"home":true}


static func _garrison_card(mc:Node,force:Dictionary)->Dictionary:
	var men:=int(force.get("troops",0))
	var gear:=gear_of(force.get("formations",[]),mc)
	var supply:=supply_of(force)
	var town:=ArmyMarks.place(preload("res://scripts/town_names.gd").of(String(force.get("civ_id","")),String(force.get("region_id","")),String(force.get("region_name","the town"))))
	var general:=_general(force)
	var hungry:=Rations.is_hungry(force)
	var will:=clampf(float(force.get("morale",0.6)),0.0,1.0)
	var state:="broken" if will<ArmyMarks.BROKEN_MORALE else ("hungry" if hungry else "holding")
	return {"id":"garrison:%s/%s" % [String(force.get("civ_id","")),String(force.get("region_id",""))],"kind":"garrison","army_id":-1,"members":[],
		"civ_id":String(force.get("civ_id","")),"region_id":String(force.get("region_id","")),"title":"Garrison of %s" % town,"short":town,"general":general,
		"noun":"garrison","men":men,"full":maxi(men,ceili(float(force.get("required",men)))),"gear":gear.share,"gear_detail":gear,"will":will,
		"supply":float(supply.ratio),"supply_state":String(supply.state),"supply_words":String(supply.words),"state":state,"doing":"holding %s" % town,
		"position":Pursuit.town_position(String(force.get("region_id",""))),"report_age":0,"unknown":false,"home":false}


## Bands a general leads together stand as one card: a headquarters the
## player formed (Organization tab), or one named general over several bands.
static func _grouped(mc:Node,singles:Array[Dictionary])->Array[Dictionary]:
	var command:RefCounted=mc.command_hierarchy
	var key_of:={}
	var names:={}
	for entry:Dictionary in command.data.nodes.values():
		if String(entry.get("service",""))!="army" or int(entry.get("force_id",-1))<=0:continue
		var top:=entry
		for _step in 16:
			var parent:=String(top.get("parent",""))
			if parent=="" or parent=="army":break
			var above:Dictionary=command.node(parent)
			if above.is_empty():break
			top=above
		if String(top.get("id",""))!=String(entry.get("id","")):
			key_of[int(entry.force_id)]="group:"+String(top.id)
			names["group:"+String(top.id)]=String(top.get("name",""))
	var by_general:={}
	for card:Dictionary in singles:
		var figure:=String((card.general as Dictionary).get("figure_id",""))
		if figure!="" and not key_of.has(int(card.army_id)):by_general[figure]=int(by_general.get(figure,0))+1
	var groups:={}
	var order:Array[String]=[]
	for card:Dictionary in singles:
		var key:=String(key_of.get(int(card.army_id),""))
		var figure:=String((card.general as Dictionary).get("figure_id",""))
		if key=="" and figure!="" and int(by_general.get(figure,0))>1:key="general:"+figure
		if key=="":key=String(card.id)
		if not groups.has(key):groups[key]=[];order.append(key)
		(groups[key] as Array).append(card)
	var out:Array[Dictionary]=[]
	for key:String in order:
		var members:Array=groups[key]
		out.append(members[0] if members.size()==1 else group_card(key,members,String(names.get(key,""))))
	return out


static func group_card(key:String,members:Array,hq_name:String="")->Dictionary:
	var lead:Dictionary=members[0]
	var men:=0;var full:=0;var gear_issued:=0;var gear_required:=0;var will:=0.0;var supply:=0.0
	var missing:={}
	var state:="holding";var worst_supply:="well"
	var ids:Array=[]
	for m in members:
		var card:Dictionary=m
		if int(card.men)>int(lead.men):lead=card
		men+=int(card.men);full+=int(card.full)
		var gear:Dictionary=card.gear_detail
		gear_issued+=int(gear.get("issued",0));gear_required+=int(gear.get("required",0))
		for item:String in gear.get("missing",{}):missing[item]=int(missing.get(item,0))+int(gear.missing[item])
		will+=float(card.will)*float(card.men);supply+=float(card.supply)*float(card.men)
		if STATE_ORDER.find(String(card.state))<STATE_ORDER.find(state):state=String(card.state)
		if ["well","strained","starving"].find(String(card.supply_state))>["well","strained","starving"].find(worst_supply):worst_supply=String(card.supply_state)
		ids.append(int(card.army_id))
	var weight:=maxf(1.0,float(men))
	var general:Dictionary=lead.general
	var default_hq:=hq_name=="" or hq_name.ends_with("headquarters")
	var title:=hq_name if not default_hq else (("%s's army" % String(general.name)) if not general.is_empty() else "Our army")
	var words:PackedStringArray=[]
	for m in members:words.append(String((m as Dictionary).supply_words))
	return {"id":key,"kind":"group","army_id":int(lead.army_id),"members":ids,"member_cards":members,"title":title,"short":String(general.get("name",title)),
		"general":general,"noun":"army","men":men,"full":full,"gear":clampf(float(gear_issued)/maxf(1.0,float(gear_required)),0.0,1.0) if gear_required>0 else 1.0,
		"gear_detail":{"issued":gear_issued,"required":gear_required,"missing":missing,"share":clampf(float(gear_issued)/maxf(1.0,float(gear_required)),0.0,1.0) if gear_required>0 else 1.0},
		"will":will/weight,"supply":supply/weight,"supply_state":worst_supply,"supply_words":"\n".join(words),"state":state,
		"doing":"%d %s" % [members.size(),"bands"],"position":lead.position,"report_age":int(lead.report_age),"unknown":false,"home":bool(lead.home)}


## The card's hover words: who, how many, what they are doing, and each bar.
static func tooltip(card:Dictionary)->String:
	var lines:PackedStringArray=["%s · %s of %s men" % [String(card.title),EraWords.grouped(int(card.men)),EraWords.grouped(int(card.full))]]
	var doing:=String(card.get("doing",""))
	if doing!="":lines.append(doing.substr(0,1).to_upper()+doing.substr(1))
	lines.append(gear_words(card.get("gear_detail",{})).get_slice("\nClick",0))
	lines.append(will_words(float(card.will)))
	lines.append(supply_line(card))
	var age:=ArmyMarks.age_words(int(card.get("report_age",0)))
	if age!="":lines.append(age.substr(0,1).to_upper()+age.substr(1)+" by runner.")
	lines.append("Click to find them · double-click for orders.")
	return "\n".join(lines)
