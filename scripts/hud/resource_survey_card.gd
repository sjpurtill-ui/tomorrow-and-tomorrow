extends ScrollContainer
## Map inspection consumes disclosed lens entries, never the hidden deposit ledger.
const T=preload("res://scripts/hud/hud_tokens.gd")
const Meter=preload("res://scripts/hud/military_roster_gauge.gd")
var host_panel:PanelContainer
var body:VBoxContainer
var resource_cards:Array[Dictionary]=[]
var surface_values:Dictionary={}
var snapshot:Dictionary={}
static var icon_cache:Dictionary={}

func _ready()->void:
	horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",8);add_child(body)

func _process(_delta:float)->void:
	if not is_instance_valid(host_panel) or not is_visible_in_tree():return
	var view:=get_viewport_rect().size
	host_panel.size=Vector2(minf(420,view.x-40),clampf(body.get_combined_minimum_size().y+86,280,maxf(280,view.y-190)))
	host_panel.position=Vector2(view.x-host_panel.size.x-20,104)

static func symbol(kind:String,color:Color)->Texture2D:
	var key:=kind+color.to_html()
	if icon_cache.has(key):return icon_cache[key]
	var paths:={
		"wood":'<path d="M32 8 L15 29 H23 L11 43 H27 V56 H37 V43 H53 L41 29 H49 Z"/>',
		"clay":'<path d="M10 44 Q20 37 32 43 T54 41 M10 51 Q22 44 33 50 T54 48 M13 33 L21 17 Q33 10 46 21 L51 33 Z"/>',
		"stone":'<path d="M9 45 L16 24 L35 13 L53 28 L56 48 L32 55 Z M16 24 L32 37 L53 28 M32 37 V55"/>',
		"soil":'<path d="M9 44 Q20 35 32 43 T55 42 M9 53 Q20 44 32 52 T55 51 M32 37 V20 M32 27 Q12 29 15 13 Q31 13 32 27 M32 21 Q33 9 49 10 Q50 26 32 27"/>',
		"fiber":'<path d="M15 52 Q30 35 43 14 M22 42 Q7 29 19 20 Q34 26 26 36 M31 30 Q43 35 54 20 Q42 11 35 23"/>',
		"water":'<path d="M32 8 C28 20 13 32 13 41 A19 19 0 0 0 51 41 C51 32 36 20 32 8 Z M22 42 Q22 49 29 50"/>',
		"ore":'<path d="M12 23 L24 11 H43 L54 23 L32 55 Z M12 23 H54 M24 11 L22 23 L32 55 L43 23 L43 11"/>',
		"sun":'<circle cx="32" cy="32" r="12"/><path d="M32 6 V13 M32 51 V58 M6 32 H13 M51 32 H58 M13 13 L19 19 M45 45 L51 51 M13 51 L19 45 M45 19 L51 13"/>',
		"flag":'<path d="M17 56 V10 H51 L44 22 L51 34 H17"/>',
		"game":'<path d="M20 49 L19 28 L10 17 M19 28 L29 21 L45 26 L50 44 M24 51 L27 33 M45 51 L40 32 M19 20 L20 9 M15 13 L25 15"/>'
	}
	var svg:='<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><g fill="none" stroke="#%s" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % [color.to_html(false),paths.get(kind,paths.ore)]
	var img:=Image.new();img.load_svg_from_string(svg);icon_cache[key]=ImageTexture.create_from_image(img);return icon_cache[key]

static func kind(resource:String)->String:
	if resource in ["Timber","Wood","Fuelwood","Charcoal"]:return "wood"
	if resource=="Clay":return "clay"
	if resource in ["Stone","Flint","Limestone","Fine Sand"]:return "stone"
	if resource in ["Freshwater","Deep Aquifer","Water"]:return "water"
	if resource in ["Fertile Soil","Food"]:return "soil"
	if resource in ["Fiber Plants","Medicinal Plants","Plant Fiber"]:return "fiber"
	if resource=="Game":return "game"
	return "ore"

func label(parent:Node,text:String,font:int=12,color:Color=T.BODY,wrap:bool=false)->Label:
	var node:=T.make_label(text,font,color);node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	if not wrap:node.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(node);return node
func icon(parent:Node,id:String,color:Color,side:int=26)->void:
	var image:=TextureRect.new();image.texture=symbol(id,color);image.custom_minimum_size=Vector2(side,side);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(image)
func frame(parent:Node,color:Color=T.BORDER)->VBoxContainer:
	var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",T.flat(Color("15272c"),color,1,6,10));parent.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column);return column
func button(parent:Node,title:String)->Button:
	var node:=Button.new();node.text=title;node.add_theme_font_size_override("font_size",11);node.custom_minimum_size.y=28
	node.add_theme_stylebox_override("normal",T.flat(T.BUTTON_BG,T.BORDER,1,4,5));parent.add_child(node);return node

func show_survey(entries:Array,surface:Dictionary,advice:Dictionary={})->void:
	snapshot={"entries":entries.duplicate(true),"surface":surface.duplicate(true),"advice":advice.duplicate(true)}
	for child in body.get_children():body.remove_child(child);child.queue_free()
	resource_cards.clear();surface_values.clear();scroll_vertical=0
	var ground:=frame(body)
	var heading:=HBoxContainer.new();heading.add_theme_constant_override("separation",8);ground.add_child(heading)
	icon(heading,"sun" if surface.get("id","")=="steppe" else "water" if surface.get("id","") in ["water","floodplain","wetland"] else "wood" if surface.get("id","")=="woodland" else "soil",T.GOLD,32)
	label(heading,String(surface.get("label","Observed ground")).capitalize(),17,T.INK,true).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if surface.get("id","")!="water":
		var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",8);ground.add_child(grid)
		var cover:=clampf(float(surface.get("tree_cover",0)),0,1)
		for spec:Array in [["wood","TREE COVER","%d%%" % roundi(cover*100),T.GREEN],["stone","SURFACE STONE",String(surface.get("stone","Unknown")).capitalize(),T.TEXT_SOFT],["soil","SOIL",String(surface.get("soil","Unknown")).capitalize(),T.GREEN],["fiber","PLANT FIBER",String(surface.get("fiber","Unknown")).capitalize(),T.TEAL]]:
			var cell:=HBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(cell);icon(cell,spec[0],spec[3],22)
			var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",0);cell.add_child(text)
			label(text,spec[1],9,T.MUTED);surface_values[spec[0]]=label(text,spec[2],13,T.BODY)
	else:label(ground,"Open water · drinking suitability unconfirmed",12,T.TEXT_SOFT,true)
	if not advice.is_empty():
		var water:=HBoxContainer.new();ground.add_child(water);icon(water,"water",advice.get("color",T.TEAL),20)
		label(water,String(advice.get("source_text",advice.get("title","Water unconfirmed"))),12,advice.get("color",T.TEAL),true).size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var more:=button(ground,"Water & neighbors ▸")
		var details:=label(ground,String(advice.get("title",""))+"\n"+String(advice.get("reason",""))+"\n"+String(advice.get("neighbors",{}).get("title",""))+"\n"+String(advice.get("neighbors",{}).get("text","")),11,T.TEXT_SOFT,true);details.visible=false
		more.pressed.connect(func():details.visible=not details.visible;more.text="Water & neighbors ▾" if details.visible else "Water & neighbors ▸")
	label(body,"KNOWN SOURCES · WITHIN 18 KM",10,T.GOLD)
	if entries.is_empty():label(body,"No additional deposits recorded. Surface resources are shown above.",12,T.TEXT_SOFT,true)
	for entry:Dictionary in entries:_resource(entry)

func _resource(entry:Dictionary)->void:
	var available:=bool(entry.get("retrievable",false));var surveyed:=String(entry.get("knowledge","indicated"))=="surveyed"
	var accent:=T.TEAL if available else T.AMBER
	var card:=frame(body,accent.darkened(.55))
	var heading:=HBoxContainer.new();heading.add_theme_constant_override("separation",7);card.add_child(heading)
	icon(heading,kind(String(entry.resource)),accent,27)
	label(heading,ResourceSystem.display_name(String(entry.resource)),16,T.INK).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label(heading,"%.1f km" % float(entry.get("distance_km",0)),11,T.MUTED).custom_minimum_size.x=55
	var metrics:=HBoxContainer.new();metrics.add_theme_constant_override("separation",16);card.add_child(metrics)
	var quality:=String(entry.get("quality","unknown"));var abundance:=String(entry.get("abundance","unknown"))
	for spec:Array in [["QUALITY",quality,{"poor":1,"ordinary":2,"good":3,"exceptional":4}.get(quality,0),4],["ABUNDANCE",abundance,{"nearly exhausted":1,"traces":1,"limited":2,"common":3,"abundant":4}.get(abundance,0),4]]:
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_theme_constant_override("separation",0);metrics.add_child(cell)
		label(cell,spec[0],9,T.MUTED);label(cell,String(spec[1]).capitalize(),12,T.BODY)
		var meter:ProgressBar=Meter.new();meter.marks=spec[3];meter.ink=accent;cell.add_child(meter);meter.value=float(spec[2])/float(spec[3])*100
		meter.tooltip_text="Survey category: "+String(spec[1])+". No precise quantity is known from this report."
	var status:=HBoxContainer.new();card.add_child(status)
	label(status,("✓ Workable" if available else "○ Access blocked" if surveyed else "◇ Survey needed"),12,accent).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var expand:=button(status,"Details ▸")
	var blockers:Array=entry.get("blockers",[])
	if not available and not blockers.is_empty():label(card,String(blockers[0]).capitalize(),11,T.TEXT_SOFT,true)
	var detail:=VBoxContainer.new();detail.add_theme_constant_override("separation",5);detail.visible=false;card.add_child(detail)
	label(detail,ResourceSystem.plain_language_description(String(entry.resource)),12,T.BODY,true)
	for blocker in blockers:label(detail,"• "+String(blocker).capitalize(),11,T.TEXT_SOFT,true)
	expand.pressed.connect(func():detail.visible=not detail.visible;expand.text="Details ▾" if detail.visible else "Details ▸")
	resource_cards.append({"id":String(entry.id),"quality":quality,"abundance":abundance,"available":available,"detail":detail,"expand":expand,"card":card.get_parent()})
