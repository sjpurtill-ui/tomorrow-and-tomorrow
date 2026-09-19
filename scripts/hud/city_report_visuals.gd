extends RefCounted
## Shared presentation of dated evidence. Never reads the hidden city ledger.
const T=preload("res://scripts/hud/hud_tokens.gd")
const LABELS={"population":"Population","fortification":"Defenses","garrison":"Garrison","production":"Workshops","logistics":"Roads & transport","supply":"Food reserves","damage":"Damage","science":"Legacy science index","gdp":"GDP · worker-days/day","health":"Legacy health index","science_capacity":"Science · researcher-equivalents","education":"Average education","life_expectancy":"Health · life expectancy","infant_mortality":"Infant deaths / 1,000 births"}
static var COLORS={"population":T.INK,"fortification":T.BLUE,"garrison":T.RED,"production":T.GOLD,"logistics":T.TEAL,"supply":T.GREEN,"damage":T.AMBER,"science":T.BLUE,"gdp":T.GOLD,"health":T.GREEN,"science_capacity":T.BLUE,"education":T.BLUE,"life_expectancy":T.GREEN,"infant_mortality":T.GREEN}
const PATHS={
	"science":'<path d="M9 3h6M10 3v7L4 20h16l-6-10V3M7 15h10"/>',
	"gdp":'<path d="M4 21V13h4v8M10 21V9h4v12M16 21V3h4v18"/>',
	"health":'<path d="M9 3h6v6h6v6h-6v6H9v-6H3V9h6Z"/>',
	"population":'<circle cx="12" cy="7" r="3"/><path d="M6 21v-4a6 6 0 0 1 12 0v4M3 10a3 3 0 0 0 0 6M21 10a3 3 0 0 1 0 6"/>',
	"fortification":'<path d="M3 21V5h4v4h3V5h4v4h3V5h4v16ZM10 21v-5a2 2 0 0 1 4 0v5"/>',
	"garrison":'<path d="M12 3 4 6v6c0 5 8 9 8 9s8-4 8-9V6ZM12 7v9M8 11h8"/>',
	"production":'<path d="M3 21V10l6-4v6l6-4v5h6v8ZM5 17h2m3 0h2m3 0h3M17 12V3h3v10"/>',
	"logistics":'<path d="m7 3-4 18M17 3l4 18M12 3v3m0 4v4m0 4v3"/>',
	"supply":'<path d="M12 22V4M12 8C5 8 4 5 5 2c4 0 7 2 7 6ZM12 13C5 13 4 10 5 7M12 18C5 18 4 15 5 12M12 10c7 0 8-3 7-6-4 0-7 2-7 6ZM12 15c7 0 8-3 7-6"/>',
	"damage":'<path d="M3 20h18M5 20V9l7-6 7 6v11M13 4l-3 7 5 2-4 7"/>'}
static var textures:Dictionary={}

static func icon(key:String)->Texture2D:
	key=String({"science_capacity":"science","education":"science","life_expectancy":"health","infant_mortality":"health"}.get(key,key))
	if not textures.has(key):
		var svg:='<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24"><g fill="none" stroke="#%s" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % [Color(COLORS[key]).to_html(false),PATHS[key]]
		var image:=Image.new();image.load_svg_from_string(svg)
		textures[key]=ImageTexture.create_from_image(image)
	return textures[key]

static func number(value:float)->String:
	if value>=1000000:return "%.1fm" % (value/1000000.0)
	if value>=10000:return "%.1fk" % (value/1000.0)
	return str(roundi(value))

static func bounds(field:Dictionary,observed:bool=true)->Vector2:
	return Vector2(float(field.get("observed_low",field.get("low",0))) if observed else float(field.get("low",0)),float(field.get("observed_high",field.get("high",0))) if observed else float(field.get("high",0)))

static func estimate(key:String,field:Dictionary,observed:bool=true)->String:
	if field.is_empty():return "Unknown"
	var range:=bounds(field,observed)
	var capacity:=key in ["fortification","production","logistics","damage","science","health","education"]
	if capacity:range*=100
	var low:=number(range.x);var high:=number(range.y)
	if key=="science_capacity":low="%.1f" % range.x;high="%.1f" % range.y
	return (low if low==high else low+"–"+high)+( "%" if capacity else " yr" if key=="life_expectancy" else "‰" if key=="infant_mortality" else " d" if key=="supply" else "")

static func freshness(record:Dictionary,today:int)->Dictionary:
	# This meter measures the freshness of delivered reports, not instant remote
	# knowledge. Preserve observation dates separately in the evidence details.
	var received:=int(record.get("reported_day",record.get("observed_day",-1)))
	var oldest:=received
	for key:String in ["population","science_capacity","gdp","life_expectancy","education","infant_mortality"]:
		var field:Dictionary=record.get("fields",{}).get(key,{})
		if not field.is_empty():oldest=mini(oldest,int(field.get("reported_day",received)))
	var dated:=int(record.get("observed_day",-1))>=0
	var age:=maxi(0,today-oldest)
	var level:=0 if not dated else 5 if age<=90 else 4 if age<=180 else 3 if age<=365 else 2 if age<=730 else 1
	return {"level":level,"status":"Undated" if level==0 else "Fresh" if level==5 else "Aging" if level>=3 else "Stale","received_age":age}

static func age_text(day:int,today:int)->String:
	if day<0:return "Undated"
	var age:=maxi(0,today-day)
	return "Seen today" if age==0 else "Seen %dd ago" % age

class Band extends Control:
	var field:Dictionary={}
	var ink:=T.TEAL
	func _init()->void:
		custom_minimum_size.y=5;mouse_filter=MOUSE_FILTER_IGNORE
	func _draw()->void:
		draw_style_box(T.flat(T.TRACK,Color.TRANSPARENT,0,2),Rect2(Vector2.ZERO,size))
		if field.is_empty():return
		var low:=clampf(float(field.get("observed_low",field.get("low",0))),0,1)
		var high:=clampf(float(field.get("observed_high",field.get("high",0))),0,1)
		draw_style_box(T.flat(ink,Color.TRANSPARENT,0,2),Rect2(Vector2(size.x*low,0),Vector2(maxf(3,size.x*(high-low)),size.y)))
