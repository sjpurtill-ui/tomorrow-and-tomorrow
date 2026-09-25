extends RefCounted
## FUN AUDIT UI measure: what the rail, the top strip and every dock section
## show the player, and how many of those words the people's era could not
## know. Used by fun_playtest.gd (headless) and ui_capture.gd (GPU).
##
## "Modern" terms are the dashboard's statistical and service vocabulary (GDP,
## IMR, per mille, Navy, Air Force...). They are anachronistic until the people
## have printing (the statistical age). "Lexicon" hits use the game's own era
## gates (character_voice.gd ERA_GATES) against what the player knows.

const MODERN:=["(?<![A-Za-z])GDP(?![A-Za-z])","(?<![A-Za-z])IMR(?![A-Za-z])","‰","(?i)\\bedu\\b","(?i)\\bper capita\\b","(?i)\\beconomic output\\b","(?i)\\breal output\\b","(?i)\\boutput index\\b","(?i)\\blife expectancy\\b","(?i)\\blife exp\\b","(?i)\\binfant mortality\\b","(?i)\\bscience\\b","(?i)\\bresearch capacity\\b","(?i)\\beducation\\b","(?i)\\bnavy\\b","(?i)\\bnaval\\b","(?i)\\bair force\\b","(?i)\\bairfields?\\b","(?i)\\bairbases?\\b","(?i)\\bair command\\b","(?i)\\bair wings?\\b","(?i)\\bmind-eq","(?i)work-days/d"]
static var _res:Array[RegEx]=[]


static func modern_age()->bool:
	return GameState.known_discoveries.has("printing_process")


static func modern_hits(text:String)->Array[String]:
	var out:Array[String]=[]
	if modern_age():return out
	if _res.is_empty():
		for pattern in MODERN:
			var re:=RegEx.new();re.compile(pattern);_res.append(re)
	for re in _res:
		for m in re.search_all(text):out.append(m.get_string())
	return out


static func lexicon_hits(text:String)->Array[String]:
	var voice:GDScript=load("res://scripts/character_voice.gd")
	var tags:Array=voice.call("era_tags","player")
	var hits:Array=voice.call("lexicon_hits",text,tags)
	var out:Array[String]=[]
	for h in hits:out.append(String(h))
	return out


static func visible_text(root:Node)->PackedStringArray:
	var out:PackedStringArray=[]
	if root==null or not is_instance_valid(root):return out
	_walk(root,out)
	return out


static func _walk(node:Node,out:PackedStringArray)->void:
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():return
	if node is Label and String((node as Label).text).strip_edges()!="":out.append(String((node as Label).text))
	elif node is RichTextLabel:
		var t:=(node as RichTextLabel).get_parsed_text().strip_edges()
		if t!="":out.append(t)
	elif node is Button and String((node as Button).text).strip_edges()!="":out.append(String((node as Button).text))
	elif node is LineEdit and String((node as LineEdit).placeholder_text)!="":out.append(String((node as LineEdit).placeholder_text))
	for child in node.get_children():_walk(child,out)


static func rail_visible(hud:Node)->Array:
	var out:Array=[]
	var court:Node=hud.find_child("RailCourt",true,false)
	if court is Control and (court as Control).is_visible_in_tree():out.append("Court")
	for id in hud.rail_buttons:
		var b:Control=hud.rail_buttons[id]
		if b and b.is_visible_in_tree():out.append(String(id))
	var drawer:Node=hud.find_child("RailLedgers",true,false)
	if drawer is Control and (drawer as Control).is_visible_in_tree():out.append("drawer")
	return out


static func kpi_visible(hud:Node)->Array:
	var out:Array=[]
	for id in hud.kpi_chips:
		var chip:Control=hud.kpi_chips[id].get("chip")
		if chip and chip.is_visible_in_tree():out.append(String(id))
	return out


static func provider_tiles(hud:Node,section:String,sub:int)->int:
	var provider:Object=hud.providers.get(section)
	if provider==null or not provider.has_method("tab"):return 0
	var data:Dictionary=provider.call("tab",sub)
	var n:=(data.get("kpis",[]) as Array).size()
	for block in data.get("blocks",[]):
		if block is Dictionary and String(block.get("type",""))=="tiles":n+=(block.get("items",[]) as Array).size()
	return n


## Everything a section lays out: tiles, rows, actions, charts and metrics.
static func provider_items(hud:Node,section:String,sub:int)->int:
	var provider:Object=hud.providers.get(section)
	if provider==null or not provider.has_method("tab"):return 0
	var data:Dictionary=provider.call("tab",sub)
	var n:=(data.get("kpis",[]) as Array).size()
	for block in data.get("blocks",[]):
		if not block is Dictionary:continue
		var items:int=(block.get("items",[]) as Array).size() if block.get("items") is Array else 0
		items+=(block.get("metrics",[]) as Array).size() if block.get("metrics") is Array else 0
		n+=maxi(1,items)
	return n


static func kpi_detail_text()->PackedStringArray:
	var out:PackedStringArray=[]
	var data_script:GDScript=load("res://scripts/hud/kpi_detail_data.gd")
	for id in ["population","food","water","goods","health","science","gdp"]:
		var d:Dictionary=data_script.call("snapshot",id)
		for key in ["title","value","unit","status","meter_label","footer"]:out.append(String(d.get(key,"")))
		for row in d.get("rows",[]):out.append(String(row.get("label",""))+" "+String(row.get("value","")))
	return out


## Returns one measurement row. Opens each section in turn (as a player
## clicking through the rail would), then closes it again.
static func measure(terrain:Node,label:String)->Dictionary:
	var hud:Node=terrain.hud
	var row:={"label":label,"auto_dock":String(hud.active_section),"auto_dock_tiles":provider_tiles(hud,String(hud.active_section),int(hud.dock.sub)) if hud.dock.visible and hud.active_section!="" else 0,"auto_dock_items":provider_items(hud,String(hud.active_section),int(hud.dock.sub)) if hud.dock.visible and hud.active_section!="" else 0}
	var rail:=rail_visible(hud)
	var kpis:=kpi_visible(hud)
	row["rail_visible"]=rail.size();row["rail"]=rail
	row["kpi_visible"]=kpis.size()
	var shell_text:=visible_text(hud.rail_panel)
	shell_text.append_array(visible_text(hud.kpi_strip))
	row["kpi_text"]=" | ".join(visible_text(hud.kpi_strip))
	shell_text.append_array(kpi_detail_text())
	var modern:Array=[];var lexicon:Array=[]
	var per:Dictionary={}
	var shell_joined:=" \n ".join(shell_text)
	per["shell"]={"modern":modern_hits(shell_joined),"lexicon":lexicon_hits(shell_joined)}
	var ids:Array=[]
	for spec in hud.SECTIONS:
		var target:=String(spec.get("section",spec.id))
		var sub:=int(spec.get("sub",0))
		var key:=target+":"+str(sub)
		if not ids.has(key):ids.append(key)
	for extra in ["health:0","settlement:0"]:
		if not ids.has(extra):ids.append(extra)
	for key in ids:
		var target:=String(key).get_slice(":",0);var sub:=int(String(key).get_slice(":",1))
		if not hud.has_provider(target):continue
		terrain._on_hud_section_requested(target,sub)
		var text:PackedStringArray=[]
		if hud.dock.visible:
			hud.force_dock_layout()
			text.append_array(visible_text(hud.dock))
		if hud.detail_dock.visible:text.append_array(visible_text(hud.detail_dock))
		if target=="military" and is_instance_valid(MilitaryCampaign.roster_screen):
			text.append_array(visible_text(MilitaryCampaign.roster_screen))
			MilitaryCampaign.roster_screen.free()
		var joined:=" \n ".join(text)
		per[key]={"tiles":provider_tiles(hud,target,sub),"items":provider_items(hud,target,sub),"modern":modern_hits(joined),"lexicon":lexicon_hits(joined)}
		terrain._on_hud_section_requested("",0)
	var modern_total:=0;var lexicon_total:=0
	for key in per:
		modern_total+=(per[key].modern as Array).size();lexicon_total+=(per[key].lexicon as Array).size()
	row["modern_total"]=modern_total;row["lexicon_total"]=lexicon_total
	row["sections"]=per
	row["known"]=GameState.known_discoveries.size()
	return row
