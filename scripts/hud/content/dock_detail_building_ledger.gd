extends "res://scripts/hud/content/dock_content_base.gd"
## Civilization-wide architectural record. The simulation keeps the complete
## ledger; this dock pages it into a legible six-row view instead of scrolling
## through centuries of construction events.

const PAGE_SIZE:=6
var settlement_id:=""
var pages:Dictionary={0:0,1:0,2:0}
var active_sub:=0

func _init(terrain_node:Node,hud_node:Control,for_settlement_id:String="")->void:
	super(terrain_node,hud_node)
	settlement_id=for_settlement_id

func meta()->Dictionary:
	return {
		"eyebrow":"SETTLEMENT · COMPLETE ARCHITECTURAL RECORD",
		"title":"Buildings Through Time",
		"subtabs":["CHRONICLE","MATERIALS","BUILDING KINDS"],
	}

func tab(sub:int)->Dictionary:
	active_sub=sub
	var summary:=GameState.building_ledger_summary(settlement_id)
	var records:Array[Dictionary]=summary.get("records",[])
	var materials:Dictionary=summary.get("materials",{})
	var kinds:Dictionary=summary.get("kinds",{})
	var damaged:=0
	var destroyed:=0
	for row in records:
		var event_name:=String((row as Dictionary).get("event",""))
		if event_name=="damaged": damaged+=1
		elif event_name=="destroyed": destroyed+=1
	var total_material:=0.0
	for material_name in materials: total_material+=float(materials[material_name])
	var kpis:Array=[
		{"label":"RECORDS","value":str(records.size()),"delta":"entire run","accent":Tokens.TEAL,"tip":"Meaningful construction and lifecycle events; routine daily samples are not stored"},
		{"label":"BUILDING PHASES","value":str(_dictionary_total(kinds)),"delta":"founded, built, infilled, renewed","accent":Tokens.GREEN,"tip":"Distinct construction phases across the complete ledger"},
		{"label":"MATERIAL USED","value":"%.1f" % total_material,"delta":"recorded units","accent":Tokens.AMBER,"tip":"Exact deducted construction materials. Older imported saves clearly mark missing quantities."},
		{"label":"LOSSES","value":str(damaged+destroyed),"delta":"%d destroyed" % destroyed,"accent":Tokens.RED if damaged+destroyed>0 else Tokens.MUTED,"tip":"Recorded damage and destruction events"},
	]
	var blocks:Array=[]
	match sub:
		1: blocks=_materials_blocks(materials,records)
		2: blocks=_kinds_blocks(kinds)
		_: blocks=_chronicle_blocks(records)
	return {"kpis":kpis,"brief":{},"blocks":blocks}

func _chronicle_blocks(records:Array[Dictionary])->Array:
	var ordered:=records.duplicate(true)
	ordered.reverse()
	var page:=clampi(int(pages.get(0,0)),0,maxi(0,ceili(float(ordered.size())/PAGE_SIZE)-1))
	pages[0]=page
	var items:Array=[]
	for index in range(page*PAGE_SIZE,mini(ordered.size(),(page+1)*PAGE_SIZE)):
		var row:Dictionary=ordered[index]
		var event_name:=String(row.get("event","recorded")).replace("_"," ").to_upper()
		var title:=String(row.get("kind","Building")).replace("_"," ").capitalize()
		var form:=String(row.get("form","" )).replace("_"," ").capitalize()
		var use:=String(row.get("land_use","" )).replace("_"," ").capitalize()
		var roof:=String(row.get("roof_plan","" )).replace("_"," ").capitalize()
		var detail_parts:Array[String]=[]
		if form!="" and form.to_lower()!=title.to_lower(): detail_parts.append(form)
		if use!="": detail_parts.append(use)
		if roof!="": detail_parts.append("Roof: "+roof)
		var material_text:=_material_text(row.get("materials",{}))
		if material_text!="": detail_parts.append("Used: "+material_text)
		elif bool(row.get("reconstructed",false)): detail_parts.append("Material quantity not retained by the older save")
		var note:=String(row.get("note",""))
		if note!="": detail_parts.append(note)
		items.append({
			"name":"%s · %s" % [event_name,title],
			"sub":"Day %d · %s" % [int(row.get("day",0)),String(row.get("settlement_name","Unknown place"))],
			"detail":" • ".join(detail_parts),
			"value":"%d%%" % roundi(float(row.get("condition",1.0))*100.0) if row.has("condition") else "",
			"accent":_event_color(String(row.get("event",""))),
			"tip":"Permanent record #%d" % int(row.get("id",0)),
		})
	var blocks:Array=[]
	if items.is_empty():
		blocks.append({"type":"text","heading":"CONSTRUCTION CHRONICLE","text":"No construction has been recorded yet."})
	else:
		blocks.append({"type":"rows","heading":"CONSTRUCTION CHRONICLE","note":"newest first · page %d / %d" % [page+1,maxi(1,ceili(float(ordered.size())/PAGE_SIZE))],"items":items})
	blocks.append(_page_actions(0,page,ordered.size()))
	return blocks

func _materials_blocks(materials:Dictionary,records:Array[Dictionary])->Array:
	var material_items:Array=[]
	var maximum:=0.001
	for material_name in materials: maximum=maxf(maximum,float(materials[material_name]))
	var names:=materials.keys()
	names.sort_custom(func(a:Variant,b:Variant)->bool: return float(materials[a])>float(materials[b]))
	for material_name in names:
		material_items.append({"name":String(material_name),"value":"%.1f units" % float(materials[material_name]),"ratio":float(materials[material_name])/maximum,"color":Tokens.AMBER,"tip":"Total exact material deducted for recorded construction, infill, and rebuilding"})
	var missing:=0
	for row in records:
		if bool((row as Dictionary).get("reconstructed",false)) and ((row as Dictionary).get("materials",{}) as Dictionary).is_empty(): missing+=1
	var blocks:Array=[]
	if material_items.is_empty():
		blocks.append({"type":"text","heading":"MATERIAL ACCOUNT","text":"No exact construction quantities have been recorded yet."})
	else:
		blocks.append({"type":"bars","heading":"ALL RECORDED CONSTRUCTION MATERIAL","note":"complete-run totals","items":material_items})
	if missing>0:
		blocks.append({"type":"text","heading":"OLDER SAVE LIMIT","text":"%d earlier work%s survived without exact quantities. The game does not invent them; every new project records its actual recipe." % [missing,"s" if missing!=1 else ""]})
	return blocks

func _kinds_blocks(kinds:Dictionary)->Array:
	var names:=kinds.keys()
	names.sort_custom(func(a:Variant,b:Variant)->bool:
		if int(kinds[a])!=int(kinds[b]): return int(kinds[a])>int(kinds[b])
		return String(a)<String(b))
	var page:=clampi(int(pages.get(2,0)),0,maxi(0,ceili(float(names.size())/PAGE_SIZE)-1))
	pages[2]=page
	var items:Array=[]
	for index in range(page*PAGE_SIZE,mini(names.size(),(page+1)*PAGE_SIZE)):
		var kind_name:=String(names[index])
		items.append({"name":kind_name,"sub":"Across the complete run","value":"× %d" % int(kinds[names[index]]),"accent":Tokens.TEAL,"tip":"Construction phases of this architectural kind"})
	var blocks:Array=[]
	if items.is_empty(): blocks.append({"type":"text","heading":"BUILDING KINDS","text":"No building kinds have been recorded yet."})
	else: blocks.append({"type":"rows","heading":"BUILDING KINDS","note":"page %d / %d" % [page+1,maxi(1,ceili(float(names.size())/PAGE_SIZE))],"items":items})
	blocks.append(_page_actions(2,page,names.size()))
	return blocks

func _page_actions(sub:int,page:int,total:int)->Dictionary:
	var pages_total:=maxi(1,ceili(float(total)/PAGE_SIZE))
	return {"type":"actions","items":[
		{"label":"NEWER","sub":"previous page","disabled":page<=0,"on_press":_change_page.bind(sub,-1),"tip":"Show newer records"},
		{"label":"OLDER","sub":"next page","disabled":page>=pages_total-1,"on_press":_change_page.bind(sub,1),"tip":"Show older records"},
	]}

func _change_page(sub:int,delta:int)->void:
	pages[sub]=maxi(0,int(pages.get(sub,0))+delta)

func _material_text(materials_variant:Variant)->String:
	var materials:Dictionary=materials_variant if materials_variant is Dictionary else {}
	var parts:Array[String]=[]
	for material_name in materials:
		parts.append("%.1f %s" % [float(materials[material_name]),String(material_name)])
	return " + ".join(parts)

func _dictionary_total(values:Dictionary)->int:
	var total:=0
	for key in values: total+=int(values[key])
	return total

func _event_color(event_name:String)->Color:
	if event_name in ["destroyed","damaged","abandoned","vacated"]: return Tokens.RED
	if event_name in ["completed","founded","infilled","rebuilt","reoccupied"]: return Tokens.GREEN
	return Tokens.TEAL

func signature()->Array:
	return [GameState.building_ledger.size(),GameState.next_building_record_id,pages.duplicate(),settlement_id]
