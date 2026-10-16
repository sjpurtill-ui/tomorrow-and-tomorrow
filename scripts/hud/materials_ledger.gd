extends VBoxContainer
## Working Stockyard. Weighted storage space, individual piles, gross arrivals,
## losses and carrying coverage are separate readings of the provider's ledger.
## This retained presentation never changes simulation state.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const MaterialsArt:=preload("res://scripts/hud/materials_art.gd")
const Spark:=preload("res://scripts/hud/material_stock_spark.gd")
const ELSEWHERE:=["Freshwater","Civilian Goods","Food"]
const PAGE_SIZE:=8
const ART_PATH:="res://assets/ui/materials/working-stockyard.jpg"
const SCENE_INK:=Color("fff4df")

var data:Dictionary={}
var _shape:Array=[]
var _land:Label
var _land_bar:Control
var _land_note:Label
var _rows:Array=[]
var _grid:GridContainer
var _composition:BoxContainer
var _inventory:VBoxContainer
var _catalog:VBoxContainer
var _browse_state:Dictionary={}
var _page_label:Label
var _previous:Button
var _next:Button
var _detail_offset:=0
var _selection:Dictionary={}
var _detail_host:VBoxContainer
var _browser:Control
var _hero:Label
var _supply:Label
var _readings:Dictionary={}
var _incoming:Array=[]
var _details:Array=[]
var _slots:Array=[]
var _source_slots:Array=[]
var _shipment_slots:Array=[]
var _refs:Dictionary={}
var _margin:MarginContainer
var _body:VBoxContainer
var _banner:StockyardBanner
var _capacity:CapacityBand
var _search:LineEdit
var _selected_key:=""
var _provider_selected:=""
var _selected_art:=""
var _actions:Dictionary={}

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="MaterialsLedger"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",0)
	_shape=shape_of(block);_browse_state=block.get("browse_state",{})
	_selected_key=selected_key(block);_provider_selected=String(block.get("selected",""))
	_margin=MarginContainer.new();_margin.name="StockyardReadingWidth";add_child(_margin)
	_body=VBoxContainer.new();_body.add_theme_constant_override("separation",12);_margin.add_child(_body)
	_build_banner();_build_capacity()
	_composition=BoxContainer.new();_composition.name="StockyardInventoryAndContext";_composition.add_theme_constant_override("separation",22);_body.add_child(_composition)
	_inventory=VBoxContainer.new();_inventory.name="StockyardInventory";_inventory.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_inventory.size_flags_stretch_ratio=1.8;_inventory.add_theme_constant_override("separation",8);_composition.add_child(_inventory)
	_catalog=_inventory
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",10);_inventory.add_child(head)
	head.add_child(S.voice("In our hands",18))
	_refs.inventory_count=S.label("",14,T.INK_MUTED);_refs.inventory_count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_refs.inventory_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;_refs.inventory_count.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(_refs.inventory_count)
	_build_browser();_build_inventory();_build_land()
	_detail_host=VBoxContainer.new();_detail_host.name="SelectedMaterial";_detail_host.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_detail_host.size_flags_stretch_ratio=1.0;_detail_host.add_theme_constant_override("separation",7);_composition.add_child(_detail_host)
	_build_selected()
	_build_flow_and_commands()
	resized.connect(_arrange);_inventory.resized.connect(_arrange);_body.resized.connect(_arrange)
	_fill();_arrange.call_deferred()

func _build_banner()->void:
	_banner=StockyardBanner.new();_banner.name="StockyardPainting";_banner.custom_minimum_size.y=140;_body.add_child(_banner)
	_banner.tooltip_text="An illustrative working stockyard. The figures describe this settlement; the picture does not assert its exact buildings or stored materials."
	if ResourceLoader.exists(ART_PATH):_banner.picture=load(ART_PATH)
	elif FileAccess.file_exists(ART_PATH):_banner.picture=ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(ART_PATH)))
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",3);_banner.add_child(words);_refs.banner_words=words
	words.add_child(_paint_label("OUR MATERIAL RESERVES",14,true))
	_hero=_paint_label("",24,true);_hero.name="StockyardSituation";_hero.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(_hero)
	_supply=_paint_label("",14);_supply.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(_supply)
	var amount:=VBoxContainer.new();amount.add_theme_constant_override("separation",1);_banner.add_child(amount);_refs.banner_amount=amount
	var value:=_paint_label("",24,true);value.name="StoredBulk";value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;amount.add_child(value)
	var note:=_paint_label("",14);note.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;amount.add_child(note)
	_readings.stores={"cell":amount,"value":value,"note":note}

func _build_capacity()->void:
	var box:=VBoxContainer.new();box.name="StockyardCapacity";box.add_theme_constant_override("separation",4);_body.add_child(box)
	var line:=HFlowContainer.new();line.add_theme_constant_override("h_separation",18);line.add_theme_constant_override("v_separation",3);box.add_child(line)
	_refs.capacity_ratio=S.label("",16,T.INK,true);line.add_child(_refs.capacity_ratio)
	_refs.capacity_space=S.label("",14,T.INK_MUTED);line.add_child(_refs.capacity_space)
	_capacity=CapacityBand.new();_capacity.name="WeightedStorageGraphic";_capacity.custom_minimum_size.y=13;box.add_child(_capacity)
	_capacity.tooltip_text="Storage is weighted bulk: each material uses a different amount of space. The individual pile counts below use resource units and cannot be added to this figure. Beyond capacity, material lies in the open and is lost faster."
	_refs.capacity_units=S.label("Storage space is weighted by each material's bulk; pile counts are material units.",14,T.INK_MUTED);_refs.capacity_units.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(_refs.capacity_units)

func _build_browser()->void:
	var pages:=HFlowContainer.new();pages.name="MaterialBrowser";pages.add_theme_constant_override("h_separation",6);pages.add_theme_constant_override("v_separation",4);_inventory.add_child(pages);_browser=pages
	_search=LineEdit.new();_search.name="FindMaterial";_search.placeholder_text="Find a material";_search.custom_minimum_size=Vector2(150,40);_search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;pages.add_child(_search)
	_search.text_changed.connect(func(words:String):_browse_state.query=words;_browse_state.page=0;_repage())
	_previous=S.verb("‹",func():_browse_state.page=int(_browse_state.get("page",0))-1;_repage(),"Previous materials");_previous.name="PreviousMaterials";_previous.custom_minimum_size.x=40;pages.add_child(_previous)
	_page_label=S.label("",14,T.INK_MUTED);_page_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;pages.add_child(_page_label)
	_next=S.verb("›",func():_browse_state.page=int(_browse_state.get("page",0))+1;_repage(),"Next materials");_next.name="NextMaterials";_next.custom_minimum_size.x=40;pages.add_child(_next)

func _build_inventory()->void:
	_grid=GridContainer.new();_grid.name="Materials";_grid.columns=1;_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_grid.add_theme_constant_override("h_separation",14);_grid.add_theme_constant_override("v_separation",2);_inventory.add_child(_grid)
	for index:int in PAGE_SIZE:
		var button:=Button.new();button.name="MaterialSlot_"+str(index);button.custom_minimum_size.y=44;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		button.pressed.connect(_choose_slot.bind(index));_grid.add_child(button)
		_tile_style(button,false)
		var content:=HBoxContainer.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=6;content.offset_right=-6;content.offset_top=4;content.offset_bottom=-4;content.add_theme_constant_override("separation",8);content.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(content)
		var picture:=TextureRect.new();picture.name="MaterialPicture";picture.custom_minimum_size=Vector2(30,30);picture.size_flags_vertical=Control.SIZE_SHRINK_CENTER;picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(picture)
		var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.size_flags_vertical=Control.SIZE_SHRINK_CENTER;words.add_theme_constant_override("separation",0);words.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(words)
		var headline:=HBoxContainer.new();headline.add_theme_constant_override("separation",10);headline.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(headline)
		var label:=S.label("",15,T.INK,true);label.custom_minimum_size.x=120;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;headline.add_child(label)
		var stock:=S.voice("",16);stock.name="Stock";stock.custom_minimum_size.x=56;stock.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;stock.mouse_filter=Control.MOUSE_FILTER_IGNORE;headline.add_child(stock)
		var flow:=S.label("",14,T.INK_MUTED);flow.name="Flow";flow.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;flow.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(flow)
		_slots.append({"key":"","button":button,"label":label,"stock":stock,"flow":flow,"picture":picture,"selected":false})
	_refs.inventory_empty=S.label("",16,T.INK_MUTED);_refs.inventory_empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_inventory.add_child(_refs.inventory_empty)

func _build_land()->void:
	var land:=VBoxContainer.new();land.name="Land";land.add_theme_constant_override("separation",2);_inventory.add_child(land);_refs.land=land
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);land.add_child(line)
	_land=S.label("",14,T.INK,true);_land.name="SearchedLand";_land.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_land.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line.add_child(_land)
	_land_bar=S.bar(0,T.INK_MUTED,70,4);_land_bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(_land_bar)
	_land_note=S.label("",14,T.INK_MUTED);_land_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;land.add_child(_land_note)

func _build_selected()->void:
	var headline:=HBoxContainer.new();headline.add_theme_constant_override("separation",6);_detail_host.add_child(headline)
	headline.add_child(S.label("IN FOCUS",14,T.INK_MUTED,true))
	_selection.state=S.label("",14,T.INK_MUTED);_selection.state.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_selection.state.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;headline.add_child(_selection.state)
	var identity:=HBoxContainer.new();identity.name="SelectedMaterialIdentity";identity.add_theme_constant_override("separation",10);_detail_host.add_child(identity)
	var picture:=TextureRect.new();picture.name="SelectedMaterialPicture";picture.custom_minimum_size=Vector2(40,40);picture.size_flags_vertical=Control.SIZE_SHRINK_CENTER;picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;identity.add_child(picture);_selection.picture=picture
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",2);identity.add_child(words)
	_selection.name=S.voice("",18);_selection.name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(_selection.name)
	_selection.stock=S.voice("",16);_selection.stock.name="SelectedMaterialStock";words.add_child(_selection.stock)
	_selection.reading=S.label("",14,T.INK_MUTED);_selection.reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(_selection.reading)
	var actions:=HFlowContainer.new();actions.name="SelectedMaterialActions";actions.add_theme_constant_override("h_separation",6);actions.add_theme_constant_override("v_separation",5);_detail_host.add_child(actions)
	_actions.assign=S.verb("Assign workers",func():_invoke("on_assign"),"Open the civilization-wide Extraction allocation and its consequences.",false,true);_actions.assign.name="AssignExtractionWorkers";actions.add_child(_actions.assign)
	_actions.map=S.verb("Show on map",func():_invoke("on_map"),"Mark known material sources on the map.");_actions.map.name="ShowMaterialsOnMap";actions.add_child(_actions.map)
	var sources_head:=HFlowContainer.new();sources_head.add_theme_constant_override("h_separation",8);sources_head.add_theme_constant_override("v_separation",4);_detail_host.add_child(sources_head)
	_selection.sources_heading=S.label("Where it comes from",14,T.INK,true);_selection.sources_heading.size_flags_vertical=Control.SIZE_SHRINK_CENTER;sources_head.add_child(_selection.sources_heading)
	_selection.toggle=S.verb("All places",func():_browse_state.sources_open=not bool(_browse_state.get("sources_open",false));_fill_sources(),"Read every recorded source and its exact access condition.");_selection.toggle.name="WhereItComesFrom";sources_head.add_child(_selection.toggle)
	for index:int in PAGE_SIZE:
		var line:=S.label("",14,T.INK_MUTED);line.name="MaterialSource_"+str(index);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_detail_host.add_child(line);_source_slots.append(line)
	_selection.more=S.label("",14,T.INK_MUTED);_selection.more.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_detail_host.add_child(_selection.more)
	var pages:=HFlowContainer.new();pages.add_theme_constant_override("h_separation",6);_detail_host.add_child(pages);_selection.pages=pages
	_selection.previous=S.verb("Previous places",func():_browse_state.sources_page=int(_browse_state.get("sources_page",0))-1;_fill_sources());_selection.previous.name="PreviousSources";pages.add_child(_selection.previous)
	_selection.page_label=S.label("",14,T.INK_MUTED);_selection.page_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;pages.add_child(_selection.page_label)
	_selection.next=S.verb("Next places",func():_browse_state.sources_page=int(_browse_state.get("sources_page",0))+1;_fill_sources());_selection.next.name="NextSources";pages.add_child(_selection.next)
	var spark:=Spark.new();spark.name="SelectedMaterialHistory";spark.custom_minimum_size.y=28;_detail_host.add_child(spark);_selection.spark=spark
	_selection.since=S.label("",14,T.INK_MUTED);_selection.since.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_detail_host.add_child(_selection.since)

func _build_flow_and_commands()->void:
	var line:=HSeparator.new();_body.add_child(line)
	var account:=BoxContainer.new();account.name="MaterialDailyAccount";account.add_theme_constant_override("separation",18);_body.add_child(account);_refs.daily_account=account
	for key:String in ["income","loss","carry"]:
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_theme_constant_override("separation",2);account.add_child(cell)
		var value:=S.voice("",18);value.name="MaterialDaily_"+key;value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;cell.add_child(value)
		var note:=S.label("",14,T.INK_MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;cell.add_child(note);_readings[key]={"cell":cell,"value":value,"note":note}
	_refs.transport_queue=S.label("",14,T.INK_MUTED);_refs.transport_queue.name="MaterialTransportQueue";_refs.transport_queue.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_readings.carry.cell.add_child(_refs.transport_queue)
	var commands:=HFlowContainer.new();commands.name="StockyardManagement";commands.add_theme_constant_override("h_separation",8);commands.add_theme_constant_override("v_separation",6);_body.add_child(commands)
	_actions.carriers=S.verb("Assign carriers",func():_invoke("on_assign_carriers"),"Open the civilization-wide Logistics allocation. Carriers move food, water and materials.");_actions.carriers.name="AssignLogisticsWorkers";commands.add_child(_actions.carriers)
	_actions.more=S.verb("Ask leader: more carrying",func():_invoke("on_focus","logistics"));_actions.more.name="Choice_Logistics";_actions.more.toggle_mode=true;commands.add_child(_actions.more)
	_actions.delegate=S.verb("Let leader decide",func():_invoke("on_focus",""));_actions.delegate.name="Choice_";_actions.delegate.toggle_mode=true;commands.add_child(_actions.delegate)
	_actions.deliveries=S.verb("Deliveries",func():_invoke("on_trade"),"Goods on the road between your settlements and every arrival.");_actions.deliveries.name="MaterialDeliveries";commands.add_child(_actions.deliveries)
	var road:=VBoxContainer.new();road.name="Incoming";road.add_theme_constant_override("separation",4);_body.add_child(road);_refs.road=road
	for index:int in 3:
		var label:=S.label("",14,T.INK_MUTED);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;road.add_child(label);_shipment_slots.append({"label":label})

func _paint_label(words:String,font_size:int,strong:bool=false)->Label:
	var label:=S.label(words,font_size,SCENE_INK,strong)
	label.add_theme_color_override("font_shadow_color",Color(0.02,0.04,0.04,0.85));label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1);label.add_theme_constant_override("shadow_outline_size",2)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE;return label

func _tile_style(button:Button,selected:bool)->void:
	var normal:=StyleBoxFlat.new();normal.bg_color=Color(T.ACTIVE_BG,0.3) if selected else Color.TRANSPARENT;normal.border_width_bottom=1;normal.border_color=T.ACTION if selected else Color(T.RULE,0.5)
	button.add_theme_stylebox_override("normal",normal)
	var hover:StyleBoxFlat=normal.duplicate();hover.bg_color=Color(T.ACTIVE_BG,0.65);button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover)
	var focus:StyleBoxFlat=normal.duplicate();focus.bg_color=Color.TRANSPARENT;focus.border_color=T.ACTION;focus.border_width_top=2;focus.border_width_left=2;focus.border_width_right=2;button.add_theme_stylebox_override("focus",focus)

func _invoke(key:String,argument:Variant=null)->void:
	var callback:Variant=data.get(key)
	if not callback is Callable:return
	if argument==null:callback.call()
	else:callback.call(argument)

func _choose_slot(index:int)->void:
	if index<0 or index>=_slots.size():return
	var key:=String(_slots[index].key)
	if key.is_empty():return
	_selected_key=key;_browse_state.sources_page=0;_browse_state.sources_open=false
	_fill();_invoke("on_select",key)

func _page_rows()->Array:
	var matches:Array=[]
	var query:=String(_browse_state.get("query","")).strip_edges().to_lower()
	for item:Dictionary in data.get("rows",[]):
		if String(item.get("key","")) in ELSEWHERE:continue
		if not query.is_empty() and not String(item.get("name",item.get("key",""))).to_lower().contains(query):continue
		matches.append(item)
	var last:=maxi(0,ceili(float(matches.size())/PAGE_SIZE)-1)
	var page:=clampi(int(_browse_state.get("page",0)),0,last);_browse_state.page=page
	S.put(_page_label,"%d–%d of %d" % [page*PAGE_SIZE+1,mini((page+1)*PAGE_SIZE,matches.size()),matches.size()] if not matches.is_empty() else "No matches")
	_previous.disabled=page==0;_next.disabled=page>=last
	return matches.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE)

func _repage()->void:
	_fill();_arrange.call_deferred()

func _selected_item()->Dictionary:
	for item:Dictionary in data.get("rows",[]):
		if String(item.get("key",""))==_selected_key and _selected_key not in ELSEWHERE:return item
	return {}

func update_block(block:Dictionary)->bool:
	if _slots.is_empty():return false
	var provider_selected:=String(block.get("selected",""))
	if provider_selected!=_provider_selected and not provider_selected.is_empty():_selected_key=provider_selected
	_provider_selected=provider_selected;data=block;_shape=shape_of(block)
	var fresh_state:Dictionary=block.get("browse_state",_browse_state)
	_browse_state=fresh_state
	if _selected_item().is_empty():_selected_key=selected_key(block)
	_fill();return true

static func shape_of(block:Dictionary)->Array:
	var keys:Array=[]
	for item:Dictionary in block.get("rows",[]):keys.append(String(item.get("key","")))
	return keys

func capture_view_state()->Dictionary:
	return {"selected":_selected_key,"query":String(_browse_state.get("query","")),"page":int(_browse_state.get("page",0)),"sources_page":int(_browse_state.get("sources_page",0)),"sources_open":bool(_browse_state.get("sources_open",false))}

func restore_view_state(state:Dictionary)->void:
	_selected_key=String(state.get("selected",_selected_key))
	for key:String in ["query","page","sources_page","sources_open"]:
		if state.has(key):_browse_state[key]=state[key]
	if _selected_item().is_empty():_selected_key=selected_key(data)
	_fill()

func _arrange()->void:
	if _body==null:return
	var side:=maxi(0,roundi((size.x-1360.0)/2.0));_margin.add_theme_constant_override("margin_left",side);_margin.add_theme_constant_override("margin_right",side)
	var width:=_body.size.x
	if width<1:return
	_composition.vertical=width<740
	_grid.columns=2 if _inventory.size.x>=560 and _rows.size()>4 else 1
	_refs.daily_account.vertical=width<650
	for key:String in ["income","loss","carry"]:
		_readings[key].cell.custom_minimum_size.x=0 if width<650 else 180
	var small:=width<500
	var height:=230.0 if small else 140.0
	_banner.custom_minimum_size.y=height
	_refs.banner_words.position=Vector2(18,20);_refs.banner_words.size=Vector2(width-36 if small else width*0.60,height-30)
	_refs.banner_amount.position=Vector2(18,150) if small else Vector2(width*0.65,36)
	_refs.banner_amount.size=Vector2(width-36 if small else width*0.32,60)
	_hero.add_theme_font_size_override("font_size",22 if small else 24)
	_readings.stores.value.add_theme_font_size_override("font_size",24)
	for slot:Dictionary in _slots:
		(slot.picture as Control).custom_minimum_size=Vector2(30,30)
		(slot.button as Control).custom_minimum_size.y=44
		# Keep each number beside its name even when a short list has ample room.
		var row_width:=(_inventory.size.x-float(_grid.columns-1)*14.0)/float(_grid.columns)
		var stock_width:=maxf(56.0,(slot.stock as Control).get_combined_minimum_size().x)
		(slot.label as Control).custom_minimum_size.x=clampf(row_width-60.0-stock_width,60.0,190.0)

func _fill()->void:
	var held:=float(data.get("storage",0.0));var room:=float(data.get("capacity",0.0))
	var capacity_known:=bool(data.get("capacity_known",room>0.0))
	var full:=held/room if capacity_known and room>0 else -1.0
	S.put(_hero,"Storage capacity not measured." if not capacity_known else "The yard is overflowing." if room>0 and held>room else "The yard is nearly full." if full>=0.85 else "Room for the next load." if room>0 else "No storage capacity.",SCENE_INK)
	var hauling:Variant=data.get("hauling")
	var carried:=clampf(float(hauling),0,1) if hauling!=null else -1.0
	var supply_words:="Carrying has not been measured yet." if carried<0 else "Recorded carrying: %d%% of extracted output." % roundi(carried*100)
	var queue_words:=_transport_words(data)
	if float(data.get("waiting",0.0) if data.get("waiting")!=null else 0.0)>0.0 or float(data.get("in_transit",0.0) if data.get("in_transit")!=null else 0.0)>0.0:
		supply_words=queue_words+"."
	if capacity_known and room>0 and held>room:supply_words+=" Excess storage is exposed to greater loss."
	S.put(_supply,supply_words,SCENE_INK)
	S.put(_readings.stores.value,S.n(held),SCENE_INK);S.put(_readings.stores.note,("storage space used / %s capacity" % S.n(room)) if capacity_known else "storage space used · capacity unmeasured",SCENE_INK)
	_readings.stores.cell.tooltip_text=String(kpi_items(data)[0].tip)
	S.put(_refs.capacity_ratio,("%s× capacity" % S.n(full)) if full>1 else ("%d%% of capacity" % roundi(full*100)) if full>=0 else ("No storage capacity" if capacity_known else "Capacity not measured"),T.RED_TEXT if full>1 else T.INK)
	S.put(_refs.capacity_space,"" if not capacity_known else ("Within capacity %s · Above capacity %s" % [S.n(room),S.n(maxf(0,held-room))]) if full>1 else ("%s storage space free" % S.n(maxf(0,room-held))) if room>0 else ("%s storage space used without capacity" % S.n(held)) if capacity_known else "")
	_capacity.held=held;_capacity.capacity=room;_capacity.known=capacity_known;_capacity.queue_redraw()
	var count:=0;var delivered:=0.0;var losses:=0.0;var flowing:=0
	for item:Dictionary in data.get("rows",[]):
		if String(item.get("key","")) in ELSEWHERE:continue
		count+=1;delivered+=float(item.get("delivered",0));losses+=float(item.get("loss",0))
		if float(item.get("delivered",0))>0.05:flowing+=1
	_browser.visible=count>PAGE_SIZE or not String(_browse_state.get("query","")).is_empty()
	if _search.text!=String(_browse_state.get("query","")):_search.text=String(_browse_state.get("query",""))
	var visible_rows:=_page_rows();_rows.clear()
	# Reassign names atomically when pages change, so a reused slot cannot
	# collide with another slot's old Material_<key> name during filtering.
	var mapping_changed:=false
	for index:int in PAGE_SIZE:
		var expected:=String(visible_rows[index].key) if index<visible_rows.size() else ""
		if expected!=String(_slots[index].key):mapping_changed=true;break
	if mapping_changed:
		for index:int in PAGE_SIZE:_slots[index].button.name="MaterialSlot_"+str(index)
	S.put(_refs.inventory_count,"%d of %d materials" % [visible_rows.size(),count])
	for index:int in PAGE_SIZE:
		var slot:Dictionary=_slots[index]
		var shown:=index<visible_rows.size();slot.button.visible=shown
		if not shown:slot.key="";continue
		var item:Dictionary=visible_rows[index];var key:=String(item.key)
		if String(slot.key)!=key:
			slot.picture.texture=MaterialsArt.texture_for(key);slot.key=key
		slot.button.name="Material_"+key.validate_node_name()
		S.put(slot.label,String(item.get("name",key)))
		var stock:=float(item.get("stock",0));var context:=_context_stock(key,stock)
		slot.stock.add_theme_font_size_override("font_size",14 if not context.is_empty() else 16)
		S.put(slot.stock,context if not context.is_empty() else _stock_amount(stock),T.INK if stock>0 or not context.is_empty() else T.INK_MUTED)
		var incoming:=float(item.get("delivered",0));var lost:=float(item.get("loss",0))
		var flow_words_short:="%s in" % S.n(incoming) if incoming>0.05 else "No arrivals"
		if lost>0.05:flow_words_short+=" · %s lost" % S.n(lost)
		if incoming>0.05 or lost>0.05:flow_words_short+=" / day"
		S.put(slot.flow,"" if not context.is_empty() and incoming<=0.05 and lost<=0.05 else flow_words_short)
		var stock_words:=context if not context.is_empty() else _stock_amount(stock)+" in store"
		slot.picture.tooltip_text=_art_words(key)
		slot.button.tooltip_text="%s: %s. %s\n%s\nPile counts are material units, not weighted storage space." % [String(item.get("name",key)),stock_words,flow_words(item) if context.is_empty() or incoming>0.05 or lost>0.05 else "Recorded natural resource.",_art_words(key)]
		var selected:bool=key==_selected_key
		if bool(slot.selected)!=selected:_tile_style(slot.button,selected);slot.selected=selected
		_rows.append(slot)
	_refs.inventory_empty.visible=visible_rows.is_empty()
	S.put(_refs.inventory_empty,"No materials match this search." if count>0 else "No material stocks or known sources recorded yet.")
	_refs.land.visible=not String(data.get("land","")).is_empty() or data.has("cover")
	var cover:=clampf(float(data.get("cover",0)),0,1)
	S.put(_land,"Land searched %d%%" % roundi(cover*100));_land.tooltip_text=String(data.get("land",""));_land_bar.ratio=cover;_land_bar.queue_redraw()
	S.put(_land_note,String(data.get("land_condition","")));_land_note.visible=not _land_note.text.is_empty();_land_note.tooltip_text=_land.tooltip_text
	_fill_selected();_fill_sources()
	S.put(_readings.income.value,"+%s arriving / day" % S.n(delivered));S.put(_readings.income.note,"Gross arrivals · %d materials flowing" % flowing)
	_readings.income.cell.tooltip_text="Recorded deliveries into this settlement's yards, summed in material units. This is gross incoming supply, not net stock change. Use by construction and production is separate."
	S.put(_readings.loss.value,"%s lost / day" % S.n(losses),T.AMBER_TEXT if losses>0.05 else T.INK);S.put(_readings.loss.note,"Spoilage and storage losses")
	S.put(_readings.carry.value,"%d%%" % roundi(carried*100) if carried>=0 else "—");S.put(_readings.carry.note,"Carrying · recorded extraction delivered" if carried>=0 else "Carrying not measured yet")
	S.put(_refs.transport_queue,queue_words);_refs.transport_queue.visible=not queue_words.is_empty()
	_refs.transport_queue.tooltip_text="Material units waiting at their sources or already in transit. These are current loads, not a daily flow or weighted storage space."
	_readings.carry.cell.tooltip_text="Recorded deliveries divided by recorded extraction; not route speed. A 100% ratio does not prove there are no older loads waiting or already on the road."
	_actions.assign.visible=data.get("on_assign") is Callable;_actions.map.visible=data.get("on_map") is Callable
	_actions.carriers.visible=data.get("on_assign_carriers") is Callable
	var can_direct:=bool(data.get("can_direct",false)) and data.get("on_focus") is Callable
	_actions.more.visible=can_direct;_actions.delegate.visible=can_direct
	_actions.more.set_pressed_no_signal(_current(data)=="logistics");_actions.delegate.set_pressed_no_signal(_current(data).is_empty())
	var who:=_who(data);who=who if not who.is_empty() else "the leader"
	_actions.delegate.text="Let %s decide" % who
	_actions.more.tooltip_text="Ask %s to put more local people on carrying and paths. Other work slows." % who
	var shipments:Array=data.get("incoming",[])
	_actions.deliveries.visible=data.get("on_trade") is Callable
	_actions.deliveries.text="All %d deliveries" % shipments.size() if shipments.size()>3 else "Deliveries"
	_refs.road.visible=not shipments.is_empty();_incoming.clear()
	for index:int in 3:
		var entry:Dictionary=_shipment_slots[index];entry.label.visible=index<shipments.size()
		if index>=shipments.size():continue
		var shipment:Dictionary=shipments[index]
		var days_left:=maxi(0,ceili(float(shipment.get("arrival_day",0))-float(data.get("day",0))))
		S.put(entry.label,"%s %s from %s · %s" % [S.n(float(shipment.get("quantity",0))),String(shipment.get("resource","")).to_lower(),String(shipment.get("source_name","")),"arrives today" if days_left<=0 else "in "+preload("res://scripts/hud/production_plain.gd").span_text(days_left)])
		_incoming.append(entry)
	_arrange.call_deferred()

func _fill_selected()->void:
	var item:=_selected_item()
	_detail_host.visible=not item.is_empty()
	if item.is_empty():return
	if _selected_art!=_selected_key:_selection.picture.texture=MaterialsArt.texture_for(_selected_key);_selected_art=_selected_key
	_selection.picture.tooltip_text=_art_words(_selected_key);_selection.picture.mouse_filter=Control.MOUSE_FILTER_PASS
	S.put(_selection.name,String(item.get("name",_selected_key)))
	var context:=_context_stock(_selected_key,float(item.get("stock",0)))
	S.put(_selection.stock,context if not context.is_empty() else _stock_amount(float(item.get("stock",0)))+" in store")
	var contextual_only:=not context.is_empty() and float(item.get("delivered",0))<=0.05 and float(item.get("loss",0))<=0.05
	S.put(_selection.reading,"Recorded natural resource; see its source conditions below." if contextual_only else flow_words(item));_selection.reading.tooltip_text="Daily arrivals and recorded storage losses. Use by workshops and construction is not included in these two flows."
	var points:Array=item.get("points",[])
	var has_record:=false
	for point:Dictionary in points:
		if point.get("value")!=null:has_record=true;break
	var reading:=reading_of(item)
	var stock:=float(item.get("stock",0))
	S.put(_selection.state,"" if contextual_only else "None held" if stock<=0.0 else "Low stock" if stock<0.5 else trend_word(String(reading.trend)) if has_record else "In store")
	_selection.spark.points=points;_selection.spark.visible=points.size()>1;_selection.spark.queue_redraw()
	S.put(_selection.since,(trend_word(String(reading.trend))+" since the latest recorded stock count.") if has_record else "Stock trend not recorded yet.")
	_selection.since.visible=has_record
	S.put(_selection.sources_heading,"Where it is found" if not context.is_empty() else "Where it comes from")

static func _stock_amount(stock:float)->String:
	var words:=S.n(stock)
	return "<0.1" if stock>0.0 and words=="0" else words

static func _context_stock(key:String,stock:float)->String:
	# These provider-visible land/water records are not empty material piles.
	# Any actual positive quantity still takes precedence over this context.
	if stock>0.0:return ""
	match key:
		"Fertile Soil":return "Known land"
		"Game":return "Known wildlife"
		"Deep Aquifer":return "Water source"
	return ""

static func _art_words(key:String)->String:
	return "Illustration of "+key+"; not the exact quantity held." if MaterialsArt.has_dedicated(key) else "Generic stored-goods illustration for "+key+"; not a specific depiction of this material."

static func _transport_words(block:Dictionary)->String:
	var parts:PackedStringArray=[]
	if block.get("waiting")!=null:parts.append(S.n(float(block.waiting))+" waiting at sources")
	if block.get("in_transit")!=null:parts.append(S.n(float(block.in_transit))+" in transit")
	return " · ".join(parts)

func _fill_sources()->void:
	var item:=_selected_item();var details:Array=item.get("details",[]);var expanded:=bool(_browse_state.get("sources_open",false))
	var pages:=maxi(1,ceili(float(details.size())/PAGE_SIZE));var page:=clampi(int(_browse_state.get("sources_page",0)),0,pages-1)
	_browse_state.sources_page=page;_detail_offset=page*PAGE_SIZE if expanded else 0
	_selection.toggle.visible=details.size()>1;_selection.toggle.text="Fewer places" if expanded else "All %d places" % details.size()
	_selection.pages.visible=expanded and pages>1;_selection.previous.disabled=page==0;_selection.next.disabled=page>=pages-1
	S.put(_selection.page_label,"%d–%d of %d" % [_detail_offset+1,mini(_detail_offset+PAGE_SIZE,details.size()),details.size()])
	var limit:=PAGE_SIZE if expanded else 1;_details.clear()
	for index:int in PAGE_SIZE:
		var line:Label=_source_slots[index];var actual:=_detail_offset+index
		line.visible=index<limit and actual<details.size()
		if not line.visible:S.put(line,"");continue
		S.put(line,String(details[actual]),T.INK_MUTED);_details.append(line)
	var contextual_only:=not _context_stock(_selected_key,float(item.get("stock",0))).is_empty()
	S.put(_selection.more,("No source-place detail recorded." if contextual_only else "No extraction-place record for this stock. It may also arrive by trade or be made here.") if details.is_empty() else ("%d more recorded places" % (details.size()-1) if details.size()>1 and not expanded else ""))
	_selection.more.visible=not _selection.more.text.is_empty()

class StockyardBanner extends Control:
	var picture:Texture2D
	var shade:GradientTexture2D
	func _init()->void:
		var gradient:=Gradient.new();gradient.offsets=PackedFloat32Array([0,1]);gradient.colors=PackedColorArray([Color(0.03,0.08,0.09,0.22),Color(0.03,0.08,0.09,0.85)])
		shade=GradientTexture2D.new();shade.gradient=gradient;shade.width=4;shade.height=128;shade.fill_from=Vector2.ZERO;shade.fill_to=Vector2.DOWN
	func _ready()->void:
		clip_contents=true;mouse_filter=Control.MOUSE_FILTER_PASS;texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;resized.connect(queue_redraw)
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),T.TILE_BG)
		if picture!=null and size.x>0:
			var source:=picture.get_size();var region:=Rect2(Vector2.ZERO,source)
			var target_ratio:=size.x/maxf(1,size.y)
			if source.x/source.y>target_ratio:
				region.size.x=source.y*target_ratio;region.position.x=(source.x-region.size.x)*0.5
			else:
				region.size.y=source.x/target_ratio;region.position.y=(source.y-region.size.y)*0.5
			draw_texture_rect_region(picture,Rect2(Vector2.ZERO,size),region)
		draw_texture_rect(shade,Rect2(Vector2.ZERO,size),false)

class CapacityBand extends Control:
	var known:=true
	var held:=0.0
	var capacity:=0.0
	func _draw()->void:
		var extent:=maxf(held,capacity)
		draw_rect(Rect2(Vector2.ZERO,size),Color(T.INK,0.12))
		if not known or extent<=0:return
		var covered:=minf(held,maxf(0,capacity))/extent
		if covered>0:draw_rect(Rect2(0,0,size.x*covered,size.y),T.TEAL)
		if held>capacity:draw_rect(Rect2(size.x*covered,0,size.x*(1-covered),size.y),T.ACTION)
		if capacity>0 and held>capacity:
			var ratio:=held/capacity
			if ratio<=12:
				for index:int in range(1,ceili(ratio)):
					var x:=size.x*float(index)/ratio
					draw_line(Vector2(x,0),Vector2(x,size.y),T.PANEL_BG,2)


static func selected_key(block:Dictionary)->String:
	var rows:Array=block.get("rows",[])
	for row:Dictionary in rows:
		if String(row.key)==String(block.get("selected","")):return String(row.key)
	for row:Dictionary in rows:
		if String(row.key) not in ELSEWHERE and empty(row) and float(row.get("delivered",0.0))>0.05:return String(row.key)
	for row:Dictionary in rows:
		if String(row.key) not in ELSEWHERE and not is_idle(row,"") and not out_of_reach(row):return String(row.key)
	for row:Dictionary in rows:
		if String(row.key) not in ELSEWHERE:return String(row.key)
	return ""


static func is_idle(item:Dictionary,selected:String)->bool:
	return not out_of_reach(item) and float(item.get("delivered",0.0))<=0.05 and float(item.get("loss",0.0))<=0.05 and String(item.get("key",""))!=selected

## Nothing in store and nothing coming in: not yet within reach.
static func out_of_reach(item:Dictionary)->bool:
	return float(item.get("stock",0.0))<0.5 and float(item.get("delivered",0.0))<=0.05

## Nothing in store although some still comes in: used as fast as it arrives.
static func empty(item:Dictionary)->bool:
	return float(item.get("stock",0.0))<0.5


static func _current(block:Dictionary)->String:
	var focus:=String(block.get("focus",""))
	return "" if bool(block.get("managed",true)) else (focus if focus=="logistics" else "other")

static func _who(block:Dictionary)->String:
	var leader:Dictionary=block.get("leader",{})
	return String(leader.get("name","")).get_slice(" ",0) if not leader.is_empty() else ""

## A material's reading: which way it goes, since when, and why.
static func reading_of(item:Dictionary)->Dictionary:
	var blocked:=""
	for detail:String in item.get("details",[]):
		if bool(item.get("blocked",false)):blocked=detail.get_slice(": ",1);break
	return Words.material(float(item.stock),float(item.delivered),float(item.loss),item.get("points",[]),blocked)

static func _reading_words(item:Dictionary)->String:
	var reading:=reading_of(item)
	var since:=(" "+String(reading.since)) if not String(reading.since).is_empty() else ""
	return "%s%s: %s." % [trend_word(String(reading.trend)),since,String(reading.cause)]

static func trend_word(trend:String)->String:
	match trend:
		"rising":return "Rising"
		"falling":return "Falling"
	return "Steady"

## The day's flow in and out: "+178 in · −15 lost".
static func flow_words(item:Dictionary)->String:
	var delivered:=float(item.get("delivered",0.0));var loss:=float(item.get("loss",0.0))
	var parts:PackedStringArray=[]
	if delivered>0.05:parts.append("+%s in" % S.n(delivered))
	if loss>0.05:parts.append("−%s lost" % S.n(loss))
	return " · ".join(parts)+" a day" if not parts.is_empty() else "nothing comes in"

## The strip's figures (the dock draws them under the tabs): the yards held
## against their room, what comes in a day, the carrying.
const KPI_LABELS:={"stores":"In the yards","income":"Total coming in a day","carry":"Carrying"}
static func kpis(data:Dictionary)->Array:
	return S.dock_kpis(kpi_items(data),KPI_LABELS)

static func kpi_items(data:Dictionary)->Array:
	var out:Array=[]
	var who:=_who(data)
	# The yards: held against their room, one bar, held ÷ room.
	var held:=float(data.get("storage",0.0));var room:=float(data.get("capacity",0.0))
	var capacity_known:=bool(data.get("capacity_known",room>0.0))
	var full:=held/room if capacity_known and room>0.0 else -1.0
	var counted:=String(data.get("counted",""))
	out.append(S.kpi_item("stores",{"value":S.n(held),"ratio":clampf(full,0.0,1.0) if full>=0.0 else -1.0,"color":T.RED if full>=0.97 else (T.AMBER if full>=0.85 else T.GREEN),"edge":T.RED if full>=1.0 else T.RULE,
		"sub":("of %s room" % S.n(room)+(" · %s× capacity" % S.n(full) if full>=1.5 else "")) if capacity_known and room>0.0 else ("no storage capacity" if capacity_known else "capacity not measured"),"sub_color":T.RED_TEXT if full>=1.0 else T.INK_MUTED,
		"tip":"Held: every material in the yards, each counted by the room it takes%s. Food, water and household goods are kept apart and not counted.\nWhat is held beyond the room lies in the open and spoils faster.\n%s" % [(" ("+counted+")") if not counted.is_empty() else "",String(Words.supply(held,room,data.get("hauling")).sentence)]}))
	# What comes in a day, and what is lost.
	var delivered:=0.0;var lost:=0.0;var count:=0
	for item:Dictionary in data.get("rows",[]):
		if String(item.get("key","")) in ELSEWHERE:continue
		delivered+=float(item.get("delivered",0.0));lost+=float(item.get("loss",0.0))
		if float(item.get("delivered",0.0))>0.05:count+=1
	out.append(S.kpi_item("income",{"value":"+"+S.n(delivered) if delivered>=0.5 else "0","ratio":clampf(delivered/maxf(1.0,delivered+lost),0.0,1.0) if delivered+lost>0.05 else -1.0,"color":T.GREEN,
		"sub":"%d materials · −%s lost" % [count,S.n(lost)],"tip":"Loads brought into the yards today, every material together; and what spoiled or was lost in store. The bar: what came in against what came in and was lost."}))
	# The carrying: how much of what is dug and cut the carriers bring in.
	var hauling:Variant=data.get("hauling")
	var supply:=Words.supply(held,room,hauling)
	var flow:=clampf(float(hauling),0.0,1.0) if hauling!=null else -1.0
	out.append(S.kpi_item("carry",{"value":"%d%%" % roundi(flow*100.0) if flow>=0.0 else "—","ratio":flow,"color":T.TEAL if flow>=0.9 else (T.AMBER if flow>=0.6 else T.RED),
		"sub":("hauling slows us" if String(supply.slows).begins_with("Hauling") else "storage slows us") if not String(supply.slows).is_empty() else "of what is dug is carried","sub_color":T.AMBER_TEXT if not String(supply.slows).is_empty() else T.INK_MUTED,
		"tip":"%s\n%s" % [String(supply.sentence),("%s decides who digs, cuts and carries." % who if not who.is_empty() else "The local leader decides who digs, cuts and carries.") if bool(data.get("managed",true)) else "You asked for extra hands on part of the work."]}))
	return out
