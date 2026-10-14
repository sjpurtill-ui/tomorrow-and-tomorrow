extends RefCounted
## ANOTHER PEOPLE'S FIGHTERS, AS WE KNOW THEM: the one estimate every screen
## shows (War's Fronts and enemy cards, World's Peoples). Read only from the
## intelligence ledger, never their true numbers: the garrisons our reports
## saw in the towns they hold (city_intelligence known(), each widened with
## its age), plus the bands of theirs our lookouts saw in the last season,
## added up as the Peoples ledger adds them (hud/peoples_known_model.gd
## cell). A point value (the middle of the range, rounded as a crowd is
## counted) and the range it stands for.
##
## fighters(civ_id) -> {known, value, low, high, towns (reports giving it),
##   of (their towns we know), bands (bands seen), partial (some towns gave no
##   figure), text ("~2,700", "?" unknown), range ("1,800–3,500"), tip}
## Read once a day for every people (cached by day). Static.

const Known:=preload("res://scripts/hud/peoples_known_model.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

static var _day:=-1
static var _by_civ:={}


static func fighters(civ_id:String,day:int=-1)->Dictionary:
	if day<0:day=int(WorldSimulation.state.elapsed_days) if WorldSimulation!=null and WorldSimulation.state!=null else int(GameState.elapsed_days)
	if day!=_day:
		_day=day
		_by_civ.clear()
	if not _by_civ.has(civ_id):_by_civ[civ_id]=_read(civ_id,day)
	return _by_civ[civ_id]


## Forget the day's reading (a new report came in, or a test changed the
## ledger).
static func forget()->void:
	_day=-1
	_by_civ.clear()


static func _read(civ_id:String,day:int)->Dictionary:
	var held:Array=[]
	for record:Dictionary in Known.known_records(day):
		if Known.holder_of(record)==civ_id:held.append(record)
	var seen:=Known.bands_of(Known.sightings(day),civ_id,day)
	var column:Dictionary={}
	for c:Dictionary in Known.COLUMNS:
		if String(c.id)=="fighters":column=c
	var cell:=Known.cell(column,held,EraWords.stage(),seen)
	return shaped(cell,held.size())


## A ledger cell as the one estimate (pure; tests build cells by hand).
static func shaped(cell:Dictionary,towns_known:int)->Dictionary:
	if not bool(cell.get("known",false)):
		return {"known":false,"value":-1,"low":-1,"high":-1,"towns":0,"of":towns_known,"bands":0,"partial":false,"text":"?","range":"","tip":String(cell.get("tip","We know too little of them to count their warriors."))}
	var low:=maxf(0.0,float(cell.get("low",0.0)));var high:=maxf(low,float(cell.get("high",low)))
	var value:=Known.nice((low+high)*0.5)
	var a:=Known.nice(low);var b:=maxi(a,Known.nice(high))
	var partial:=bool(cell.get("partial",false))
	var range_words:=EraWords.grouped(a) if a==b else "%s–%s" % [EraWords.grouped(a),EraWords.grouped(b)]
	return {"known":true,"value":value,"low":a,"high":b,"towns":int(cell.get("of",0)),"of":towns_known,"bands":int(cell.get("bands",0)),"partial":partial,
		# A handful is told as its range ("0–2"), never a lone "~1".
		"text":(range_words if b<10 else "~%s" % EraWords.grouped(value))+("+" if partial else ""),"range":range_words,
		"tip":"About %s fighters, somewhere between %s, as our reports and lookouts saw them.%s\n%s" % [EraWords.grouped(value),range_words,(" Some of their towns gave no count, so there may be more.") if partial else "",String(cell.get("tip",""))]}
