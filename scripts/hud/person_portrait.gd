extends RefCounted
## One appearance for a persistent government person, regardless of screen or office.
## Living court members are given distinct pictures from the same art
## (court_lives.gd portrait slots): a cell of their own, then a mirrored one.
const PATH:="res://assets/portraits/founding_leaders.png"
const Early:=preload("res://scripts/hud/early_civ_art.gd")
const LIVES_PATH:="res://scripts/court_lives.gd"
static var sheet:Texture2D
static var _lives:GDScript
static func cells_for(person:Dictionary)->int:
	return 4 if Early.active() and Early.profile(person)!=3 else 5
static func natural_index(person:Dictionary)->int:
	var count:=cells_for(person)
	if Early.active() and person.has("early_art_index"):return posmod(int(person.early_art_index),count)
	if person.has("portrait_index"):return posmod(int(person.portrait_index),count)
	var identity:=int(person.get("person_id",0))
	if identity<=0:identity=absi(String(person.get("name","Unknown")).hash())+1
	return posmod(identity-1,count)
static func court_slot(person:Dictionary)->Array:
	if _lives==null:_lives=load(LIVES_PATH) as GDScript
	if _lives==null:return []
	var slot:Variant=_lives.call("portrait_slot",person)
	return slot if slot is Array else []
static func index_for(person:Dictionary)->int:
	var slot:=court_slot(person)
	if not slot.is_empty():return posmod(int(slot[0]),cells_for(person))
	return natural_index(person)
static func mirrored(person:Dictionary)->bool:
	var slot:=court_slot(person)
	return not slot.is_empty() and bool(slot[1])
static func texture(person:Dictionary)->Texture2D:
	if Early.active():return Early.person_scene(person,index_for(person))
	if sheet==null:sheet=load(PATH) as Texture2D
	var atlas:=AtlasTexture.new();atlas.atlas=sheet
	var cell:=Vector2(sheet.get_width()/5.0,sheet.get_height())
	atlas.region=Rect2(Vector2(index_for(person)*cell.x+5,5),cell-Vector2(10,10))
	return atlas
static func picture(person:Dictionary,width:float=80,height:float=100)->TextureRect:
	var image:=TextureRect.new();image.name="Portrait";image.texture=texture(person)
	image.flip_h=mirrored(person)
	image.custom_minimum_size=Vector2(width,height);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED if Early.active() else TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.set_meta("civilization_id",Early.owner(person))
	image.tooltip_text=String(person.get("name",""));image.set_meta("person_id",int(person.get("person_id",0)))
	if Early.active():image.tooltip_text+=" · Character illustration; current duties and conditions are reported alongside."
	return image
