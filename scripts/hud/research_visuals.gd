extends RefCounted
const T=preload("res://scripts/hud/hud_tokens.gd")
const NAMES:={"demography":"People & homes","nutrition":"Food & farming","health":"Health & care","labor":"Work & tools","knowledge":"Learning & records","production":"Craft & industry","infrastructure":"Water & building","logistics":"Transport & supply","ecology":"Land & nature","institutions":"Government","security":"Defense","culture":"Culture & memory"}
const COLORS:={"demography":Color("cf9c78"),"nutrition":Color("adbb77"),"health":Color("92c1ab"),"labor":Color("d5b57d"),"knowledge":Color("9db9d7"),"production":Color("d6a36d"),"infrastructure":Color("90bccc"),"logistics":Color("b7af83"),"ecology":Color("84b895"),"institutions":Color("baa2cd"),"security":Color("d28c7c"),"culture":Color("c29cb0")}
const Painting=preload("res://scripts/hud/subject_painting.gd")
const ART_MANIFEST="res://assets/ui/research/subject-art-manifest.json"
const CACHE_LIMIT:=64
static var assignments:Dictionary={}
static var textures:Dictionary={}
static func manifest()->Dictionary:
	if assignments.is_empty():assignments=JSON.parse_string(FileAccess.get_file_as_string(ART_MANIFEST))
	return assignments
static func art(domain:String)->Texture2D:
	# Field art is used only for a field overview, never as a discovery fallback.
	return texture_at("res://assets/ui/research/%s-v1.png" % domain)
static func texture_at(path:String)->Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):return null
	if textures.has(path):
		var existing:Texture2D=textures[path];textures.erase(path);textures[path]=existing;return existing
	if textures.size()>=CACHE_LIMIT:textures.erase(textures.keys()[0])
	textures[path]=load(path);return textures[path]
static func subject_art_key(item:Dictionary)->String:
	if not bool(item.get("exposed",true)):return ""
	return String(manifest().get(String(item.get("id","")),{}).get("path",""))
static func focus_for(item:Dictionary)->Vector2:
	var point:Array=manifest().get(String(item.get("id","")),{}).get("focus",[.5,.5])
	return Vector2(float(point[0]),float(point[1]))
static func for_discovery(item:Dictionary)->Texture2D:
	return texture_at(subject_art_key(item))
static func crop_region(texture:Texture2D,target:Vector2,focus:Vector2)->Rect2:
	return Painting.crop_region(texture,target,focus)
static func paint_discovery(parent:Node,item:Dictionary,height:float=96)->Control:
	var image:=Painting.new();image.texture=for_discovery(item);image.focus=focus_for(item)
	image.custom_minimum_size.y=height;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(image);return image
static func color(domain:String)->Color:return COLORS.get(domain,T.TEAL)
static func name_for(domain:String)->String:return NAMES.get(domain,domain.capitalize())
static func team(item:Dictionary)->float:
	var assignment:Dictionary=item.get("assignment",{})
	return float(assignment.get("capacity",{}).get("researchers",0)) if assignment.get("active",false) else 0.0
static func workforce(amount:float)->String:
	if amount<=0:return "No researchers"
	return "~%.1f researchers" % amount if amount<10 else "~%d researchers" % roundi(amount)
static func status(item:Dictionary)->String:
	if item.get("known",false):return "Established"
	var assignment:Dictionary=item.get("assignment",{})
	if assignment.get("active",false):return "Waiting for workers" if team(item)<=0 else "Being researched"
	return "Ready to investigate" if item.get("ready",false) else "Unexplored"
static func lead(item:Dictionary)->String:
	var leader:Dictionary=item.get("assignment",{}).get("leader",{})
	if leader.is_empty():return ""
	if leader.get("vacant",false):return "Vacant office · "+String(leader.office)
	return String(leader.name)+" · "+String(leader.office)
static func phase(item:Dictionary)->String:
	var text:=String(item.get("assignment",{}).get("bottleneck",""))
	if text.begins_with("NO RESEARCH"):return "No attention assigned"
	if text.begins_with("RESEARCH WORKFORCE"):return "Thinly spread team" if team(item)>0 else "Needs research workers"
	if text.begins_with("MATERIAL BASIS"):return "Needs material evidence"
	if text.begins_with("LEADERSHIP"):return "Needs stronger leadership"
	if text.begins_with("RESEARCH SUPPORT"):return "Supplies constrain research"
	if text.begins_with("EARLY EVIDENCE"):return "Gathering evidence"
	if text.begins_with("REPLICATION"):return "Testing the method"
	if text.begins_with("VALIDATION"):return "Validating results"
	return ""
static func paint(parent:Node,domain:String,height:float=96)->TextureRect:
	var image:=TextureRect.new();image.texture=art(domain);image.custom_minimum_size.y=height;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(image);return image
static func label(parent:Node,text:String,font:int=13,ink:Color=T.BODY,wrap:bool=false)->Label:
	var value:=T.make_label(text,font,ink);value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	if not wrap:value.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(value);return value
static func button(parent:Node,text:String,callback:Callable)->Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=34;b.add_theme_font_size_override("font_size",13)
	b.add_theme_stylebox_override("normal",T.flat(T.BUTTON_BG,T.BORDER,1,5,8));b.add_theme_stylebox_override("hover",T.flat(Color("253940"),T.TEAL,1,5,8));b.pressed.connect(callback);parent.add_child(b);return b
static func initials(name:String)->String:
	var words:=name.split(" ",false);var result:=""
	for word in words:
		if result.length()<2:result+=word.left(1).to_upper()
	return result
