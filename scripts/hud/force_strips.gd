extends RefCounted
## Two small HOI4 pieces for the army screens, in ink:
##   CompositionStrip  a force as its kit blocks, largest first, like HOI4's
##                     division template: the kit's glyph and how many carry
##                     it ("spear ×12 | bow ×6 | club ×2"); the full make-up
##                     in its tooltip.
##   OddsBar           the stated odds (war_odds.gd) as a tug of war: our
##                     share in our blue from the left, theirs in their red
##                     from the right, the even mark in the middle, and the
##                     odds in words under it.
## composition(formations) gives the strip its blocks from the one ledger.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")
const Ledger:=preload("res://scripts/equipment_ledger.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const OURS:=Color("#3d7f9c")
const THEIRS:=Color("#a8463a")

## A force's make-up by kit, largest first: [{glyph, count, label}].
static func composition(formations:Array)->Array:
	var by:={}
	for f in formations:
		if not f is Dictionary: continue
		var unit:=String((f as Dictionary).get("unit","levy")); var weapon:=String((f as Dictionary).get("weapon","improvised"))
		var count:=maxi(0,int((f as Dictionary).get("count",0)))
		if count<=0: continue
		var key:=unit+"|"+weapon
		if not by.has(key):
			var label:=Ledger.label(weapon) if Ledger.has(weapon) else unit.replace("_"," ").capitalize()
			by[key]={"glyph":Blocks.glyph_of(unit,weapon),"count":0,"label":label}
		by[key].count=int(by[key].count)+count
	var out:=by.values()
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.count)>int(b.count))
	return out

## "Spears 12, Bows 6, Improvised arms 2".
static func composition_words(blocks:Array)->String:
	var parts:=PackedStringArray()
	for b:Dictionary in blocks: parts.append("%s %s" % [String(b.label),EraWords.grouped(int(b.count))])
	return ", ".join(parts)


class CompositionStrip extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Icons:=preload("res://scripts/resource_icons.gd")
	const MAX_BLOCKS:=5
	var blocks:Array=[]

	func _ready()->void:
		custom_minimum_size=Vector2(0,30);mouse_filter=Control.MOUSE_FILTER_PASS

	func set_blocks(next:Array)->void:
		blocks=next
		tooltip_text="Who carries what: "+preload("res://scripts/hud/force_strips.gd").composition_words(next) if not next.is_empty() else "Nobody under arms."
		visible=not next.is_empty()
		queue_redraw()

	func _draw()->void:
		var font:=T.font("ui_strong")
		var x:=0.0
		var shown:=mini(blocks.size(),MAX_BLOCKS)
		for i in shown:
			var b:Dictionary=blocks[i]
			var text:="×%s" % preload("res://scripts/hud/era_words.gd").grouped(int(b.count))
			var w:=26.0+font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+8.0
			if x+w>size.x: break
			var box:=Rect2(Vector2(x,1),Vector2(w,26))
			draw_rect(box,T.PAPER_SUNK)
			draw_rect(box,T.RULE,false,1.0)
			draw_texture_rect(Icons.arm_texture(String(b.glyph),T.INK,T.GOLD,48),Rect2(box.position+Vector2(2,2),Vector2(22,22)),false)
			draw_string(font,Vector2(box.position.x+26.0,box.position.y+18.0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.INK)
			x+=w+4.0
		if blocks.size()>shown: draw_string(font,Vector2(x,19),"+%d" % (blocks.size()-shown),HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK_MUTED)


class OddsBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Strips:=preload("res://scripts/hud/force_strips.gd")
	## raw: ours over theirs (war_odds.of "raw"); words: the odds said.
	var raw:=1.0
	var words:=""

	func _ready()->void:
		custom_minimum_size=Vector2(0,30);mouse_filter=Control.MOUSE_FILTER_PASS

	func set_odds(odds:Dictionary,said:String)->void:
		visible=not odds.is_empty()
		raw=float(odds.get("raw",1.0)) if not odds.is_empty() else 1.0
		words=said
		tooltip_text="The war leader's reckoning by the combat engine: our share of the strength on the left, theirs on the right."
		queue_redraw()

	func _draw()->void:
		var bar:=Rect2(Vector2(0,2),Vector2(size.x,12))
		var ours:=clampf(raw/(1.0+raw),0.03,0.97)
		draw_rect(bar,Color(Strips.THEIRS,0.9))
		draw_rect(Rect2(bar.position,Vector2(bar.size.x*ours,bar.size.y)),Color(Strips.OURS,0.95))
		draw_line(Vector2(bar.size.x*0.5,0),Vector2(bar.size.x*0.5,bar.end.y+2),T.INK,1.4)
		draw_rect(bar,T.INK,false,1.0)
		var font:=T.font("ui_strong")
		draw_string(font,Vector2(2,size.y-2),"Ours",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Strips.OURS.darkened(0.25))
		var tw:=font.get_string_size("Theirs",HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		draw_string(font,Vector2(size.x-tw-2,size.y-2),"Theirs",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Strips.THEIRS.darkened(0.2))
		if words!="":
			var ww:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
			draw_string(font,Vector2((size.x-ww)*0.5,size.y-2),words,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK)


## A general's skills as HOI4 shows a leader's: a glyph and five pips each,
## from the engine's own figures (historical_figures.commander):
##   command    which manoeuvres they can try (battle_tactics min_command);
##   tactics    how well they choose and carry out the plan in battle;
##   resolve    how long they stand when the fight goes badly;
##   logistics  how well the carriers move. The engine reads it from the war
##              leader at home, so it shows only on the levy at home.
class GeneralPips extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Icons:=preload("res://scripts/resource_icons.gd")
	const SKILLS:=[["command","front","Command","which manoeuvres they can try"],["tactics","attack","Tactics","how well they choose and carry out the plan in battle"],
		["resolve","defend","Resolve","how long they stand when the fight goes badly"],["logistics","supply","Logistics","how well the carriers move, for every band"]]
	const PIP:=8.0
	var values:={}

	func _ready()->void:
		custom_minimum_size=Vector2(0,22);mouse_filter=Control.MOUSE_FILTER_PASS

	## Five pips for a skill of 0..1: never fewer than one.
	static func pips(value:float)->int:
		return clampi(roundi(clampf(value,0.0,1.0)*5.0),1,5)

	func set_commander(commander:Dictionary,name:String,at_home:bool)->void:
		values={}
		for skill:Array in SKILLS:
			var key:=String(skill[0])
			if key=="logistics" and not at_home: continue
			if commander.has(key): values[key]=clampf(float(commander[key]),0.0,1.0)
		visible=not values.is_empty()
		var lines:=PackedStringArray([("%s, who leads them:" % name) if name!="" else "Who leads them:"])
		for skill:Array in SKILLS:
			if values.has(String(skill[0])): lines.append("%s %d of 5: %s." % [String(skill[2]),pips(float(values[String(skill[0])])),String(skill[3])])
		tooltip_text="\n".join(lines)
		queue_redraw()

	func _draw()->void:
		var x:=0.0
		for skill:Array in SKILLS:
			var key:=String(skill[0])
			if not values.has(key): continue
			draw_texture_rect(Icons.command_texture(String(skill[1]),T.INK,40),Rect2(Vector2(x,2),Vector2(18,18)),false)
			x+=21.0
			var filled:=pips(float(values[key]))
			for i in 5:
				var c:=Vector2(x+PIP*0.5+float(i)*PIP,11.0)
				var diamond:=PackedVector2Array([c+Vector2(0,-3.6),c+Vector2(3.6,0),c+Vector2(0,3.6),c+Vector2(-3.6,0)])
				if i<filled: draw_colored_polygon(diamond,T.GOLD)
				diamond.append(diamond[0])
				draw_polyline(diamond,Color(T.INK,0.7),1.0,true)
			x+=PIP*5.0+10.0
