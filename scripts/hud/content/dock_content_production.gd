extends "res://scripts/hud/content/dock_content_base.gd"
var workshop:RefCounted
func meta()->Dictionary:
	return {"eyebrow":"PRODUCTION", "title":"Workshops & equipment", "subtabs":["ALL LINES","CIVILIAN","MILITARY"]}
func tab(sub:int)->Dictionary:
	if workshop==null:workshop=preload("res://scripts/hud/content/dock_content_military.gd").new(terrain,hud)
	var page:Dictionary=workshop._production_overview()
	for block:Dictionary in page.blocks:
		if String(block.get("type",""))=="production_board" and sub>0:
			block.lines=(block.lines as Array).filter(func(line:Dictionary)->bool:return (String(line.get("job_type",""))=="civilian")== (sub==1))
			block.receipts=(block.receipts as Array).filter(func(receipt:Dictionary)->bool:return (String(receipt.get("kind",""))=="civilian")== (sub==1))
		elif String(block.get("type",""))=="text":
			block.text=""
	return page
func signature()->Array:
	return [MilitaryCampaign.production_lines_snapshot(),GameState.elapsed_days]
