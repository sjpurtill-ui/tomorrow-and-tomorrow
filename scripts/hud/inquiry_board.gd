extends "res://scripts/hud/settlement_overview.gd"
## The Research board ("Where we look"), one table a strategy player reads at
## a glance:
## - a strip of four figures: our pace against a typical people of our age,
##   the discoveries that pace brings a year, the teams at work and how far
##   our learning runs ahead of the calendar (the one "ahead" on the page);
## - one bar of what speeds and slows the work on every question, each part
##   sized by how much it moves the pace, its whole account on hover;
## - who sets the learners, with the two orders that change it;
## - one row per field: its attention as a bar with − and +, its question
##   under way with the evidence as a bar and the time left to proof; a
##   field's further questions follow on lines of their own, and a field with
##   nothing under way says in a few words why it waits;
## - artifact study, the same row, last.
## A row never moves while only its numbers change (update_block). Every
## number comes from the engine (dock_content_inquiry.gd learning_pace,
## waiting_lines and DiscoverySystem.active_investigation_records).
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const Explainer:=preload("res://scripts/effect_explainer.gd")
const Borders:=preload("res://scripts/nation_borders.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Catalog:=preload("res://scripts/research_600_catalog.gd")
## Below this board width the free team's options stack in one column.
const WIDE:=760.0
## From this width each row also says what its question would bring.
const BRINGS_AT:=1000.0
## A question's line is this tall.
const CARD_HEIGHT:=24.0
## The table's fixed columns.
const FIELD_W:=118.0
const SHARE_W:=40.0
const BAR_W:=56.0
const TIME_W:=84.0
## Lines of study in each field, in the catalog's order: a question's place in its field.
const LINES:=preload("res://scripts/discovery_frontier_catalog.gd").SUBCATEGORIES
## Each free team's options, side by side on a wide board, stacked on a narrow one.
var choice_grids:Array[GridContainer]=[]
## The board's shape (update_block keeps the nodes while it holds) and the
## nodes the daily refresh writes into.
var _shape:Array=[]
var _cards:Dictionary={}
var _lanes:Dictionary={}
var _header:Dictionary={}
var _brings:Array[Label]=[]
var factor_bar:FactorBar


## What speeds and slows the work on every question: one bar, centred on the
## usual pace. Slowing parts stand left of the centre in red, speeding parts
## right of it in green, each as wide as the share of the pace it moves (on a
## log scale, so halving and doubling weigh the same). Each part names itself
## where it has room; its whole account is on hover.
class FactorBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var parts:Array=[]
	var _rects:Array=[]
	func _init()->void:
		custom_minimum_size=Vector2(200,26)
		size_flags_horizontal=Control.SIZE_EXPAND_FILL
		mouse_filter=Control.MOUSE_FILTER_STOP
	func set_parts(items:Array)->void:
		parts=items;queue_redraw()
	## Each part as wide as its share of what moves the pace (6 px at least).
	func _layout()->Array:
		var rects:Array=[]
		var slows:Array=parts.filter(func(p:Dictionary)->bool:return float(p.factor)<1.0)
		var speeds:Array=parts.filter(func(p:Dictionary)->bool:return float(p.factor)>=1.0)
		var ordered:Array=slows+speeds
		var total:=0.0
		for p:Dictionary in ordered:total+=absf(log(maxf(0.0001,float(p.factor))))
		if total<=0.0 or ordered.is_empty():return rects
		var gap:=2.0
		var usable:=maxf(1.0,size.x-gap*float(ordered.size()-1)-4.0-6.0*float(ordered.size()))
		var x:=0.0
		for k in ordered.size():
			if k==slows.size() and k>0:x+=4.0
			var w:=6.0+usable*absf(log(maxf(0.0001,float(ordered[k].factor))))/total
			rects.append({"rect":Rect2(x,0,w,size.y),"part":ordered[k]})
			x+=w+gap
		return rects
	func _draw()->void:
		_rects=_layout()
		draw_rect(Rect2(Vector2.ZERO,size),T.TRACK)
		for item:Dictionary in _rects:
			var r:Rect2=item.rect
			var p:Dictionary=item.part
			var slow:=float(p.factor)<1.0
			draw_rect(r,Color(T.RED if slow else T.GREEN,0.85 if slow else 0.8))
		# The usual pace, between what slows and what speeds.
		var centre:=-1.0
		for item:Dictionary in _rects:
			if float((item.part as Dictionary).factor)>=1.0:centre=(item.rect as Rect2).position.x-3.0;break
		if centre<0.0 and not _rects.is_empty():centre=(_rects.back().rect as Rect2).end.x+1.0
		if centre>=0.0:draw_line(Vector2(centre,-2),Vector2(centre,size.y+2),T.INK,2.0)
	func _get_tooltip(at:Vector2)->String:
		for item:Dictionary in _rects:
			if (item.rect as Rect2).grow(1.0).has_point(at):return String((item.part as Dictionary).tip)
		return "What speeds (green) and slows (red) the work on every question; the dark mark is the usual pace."

func setup(block:Dictionary)->void:
	data=block;name="InquiryBoard";add_theme_constant_override("separation",8)
	var plan:=_plan(block)
	_shape=plan.shape
	if block.has("pace"):_pace_header(self,plan.pace,block.get("pace",{}))
	if block.has("hands"):_hands(self,block.hands)
	var learning:=VBoxContainer.new();learning.name="BeingLearned";learning.add_theme_constant_override("separation",0);add_child(learning)
	_table_head(learning)
	for lane:Dictionary in plan.lanes:_lane(learning,lane)
	if (data.get("investigations",[]) as Array).is_empty():_empty(learning)
	if block.has("artifacts"):_artifact_row(learning,block.artifacts)
	# A team freed by a proof took up the best question open to it; for a season
	# the player may send it elsewhere (DiscoverySystem.team_choices). The choice
	# waits on that question's own line as a badge with a floating picker, so
	# it never pushes the board down when it arrives or goes.
	for choice:Dictionary in data.get("choices",[]):
		var card:Dictionary=_cards.get(String(choice.get("channel","")),{})
		if not card.is_empty():_choice_badge(card.badges,choice)
	resized.connect(_arrange);_arrange()

## The live refresh: while the board keeps its shape the header, the rows and
## the questions take the day's numbers in place; otherwise it is drawn afresh.
func update_block(block:Dictionary)->bool:
	var plan:=_plan(block)
	if _lanes.is_empty() or plan.shape!=_shape:return false
	data=block
	if not _header.is_empty():_fill_header(plan.pace,block.get("pace",{}))
	for lane:Dictionary in plan.lanes:
		var refs:Dictionary=_lanes.get(String(lane.id),{})
		if refs.is_empty():continue
		_fill_lane(refs,lane)
		for slot:Dictionary in lane.slots:
			var card:Dictionary=_cards.get(String(slot.key),{})
			if not card.is_empty():_fill_card(card,slot.record)
	return true

# --------------------------------------------------------------------------
# The board's plan: its lanes, slots and header, and its shape
# --------------------------------------------------------------------------

## The lanes in field order, each with its slots (one per line of study that
## holds a question, in the line's place), its waiting lines and its words;
## the header's words; and the shape the board keeps while only numbers move.
static func _plan(block:Dictionary)->Dictionary:
	var lanes:=lanes_of(block)
	var lane_shape:Array=[]
	for lane:Dictionary in lanes:
		var keys:Array=[]
		for slot:Dictionary in lane.slots:keys.append(String(slot.key))
		lane_shape.append([String(lane.id),keys,(lane.lacks as Array).duplicate(),not (lane.field as Dictionary).is_empty()])
	var pace:Dictionary=pace_words(block.get("pace",{})) if block.has("pace") else {}
	var chips:Array=[]
	for chip:Dictionary in pace.get("chips",[]):chips.append(String(chip.kind))
	var choices:Array=[]
	for choice:Dictionary in block.get("choices",[]):
		var options:Array=[]
		for option:Dictionary in choice.get("options",[]):options.append([String(option.get("id","")),option_words(option)])
		choices.append([String(choice.get("key","")),String(choice.get("taken","")),int(choice.get("days_left",0))/30,options])
	return {"lanes":lanes,"pace":pace,"shape":[lane_shape,(block.get("investigations",[]) as Array).is_empty(),chips,choices,block.has("pace")]}

## One lane per field (the fields' fixed order), and one for questions of no
## field. A lane's slots are its questions, each in its line's place.
static func lanes_of(block:Dictionary)->Array:
	var fields:Dictionary={}
	for field:Dictionary in block.get("fields",[]):fields[String(field.get("id",""))]=field
	var by_lane:Dictionary={}
	for record:Dictionary in block.get("investigations",[]):
		var domain:=String(record.get("dynamic",record.get("direction","")))
		var lane_id:=domain if Visuals.NAMES.has(domain) else ""
		(by_lane.get_or_add(lane_id,[]) as Array).append(record)
	var waiting:Dictionary={}
	for channel:String in block.get("waiting",{}):
		var info:Dictionary=block.waiting[channel]
		(waiting.get_or_add(String(info.get("domain","")),[]) as Array).append(info)
	var lanes:Array=[]
	var order:Array=Visuals.NAMES.keys()
	if by_lane.has(""):order.append("")
	for lane_id:String in order:
		var field:Dictionary=fields.get(lane_id,{})
		var records:Array=by_lane.get(lane_id,[])
		var waits:Array=waiting.get(lane_id,[])
		# A field with no attention, no question and nothing waiting is still a
		# lane (its place never changes), drawn as one line; a board drawn
		# without fields (a preview) shows only the fields at work.
		if field.is_empty() and records.is_empty() and waits.is_empty() and not fields.is_empty():continue
		if fields.is_empty() and records.is_empty():continue
		var slots:Array=[]
		for record:Dictionary in records:slots.append({"key":slot_key(record),"order":line_order(lane_id,record),"record":record})
		slots.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			if a.order!=b.order:return a.order<b.order
			return String(a.key)<String(b.key))
		waits.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return _line_index(lane_id,String(a.get("line","")))<_line_index(lane_id,String(b.get("line",""))))
		var lacks:Array=[]
		for info:Dictionary in waits:
			for material:Variant in info.get("lacks",[]):
				if not lacks.has(String(material)):lacks.append(String(material))
		var name:=Visuals.name_for(lane_id) if not lane_id.is_empty() else (field_name(records[0]) if not records.is_empty() and not field_name(records[0]).is_empty() else "Other questions")
		lanes.append({"id":lane_id,"name":name,"field":field,"slots":slots,"waiting":waits,"lacks":lacks})
	return lanes

## A question's place: its line of study (the channel that holds it), or its
## own id when it has no channel.
static func slot_key(record:Dictionary)->String:
	var channels:Array=record.get("channels",[])
	if not channels.is_empty():return String(channels[0])
	return "%s::%s" % [String(record.get("dynamic","")),String(record.get("subcategory",record.get("id","")))]

static func line_order(domain:String,record:Dictionary)->int:
	var line:=String(record.get("subcategory",""))
	var channels:Array=record.get("channels",[])
	if not channels.is_empty() and "::" in String(channels[0]):line=String(channels[0]).get_slice("::",1)
	return _line_index(domain,line)

static func _line_index(domain:String,line:String)->int:
	var lines:Array=LINES.get(domain,[])
	var index:=lines.find(line)
	return index if index>=0 else lines.size()

static func has_painting(record:Dictionary)->bool:
	var path:=Visuals.subject_art_key(record)
	return not path.is_empty() and ResourceLoader.exists(path)
## The field a question belongs to. A record without a field names its line
## of study instead; with neither, it has none.
static func field_name(record:Dictionary)->String:
	var domain:=String(record.get("dynamic",record.get("direction","")))
	if not domain.is_empty():return Visuals.name_for(domain)
	return String(record.get("subcategory","")).strip_edges()

# --------------------------------------------------------------------------
# How fast we learn, and what limits it
# --------------------------------------------------------------------------

## The header's words from the engine's pace reading (learning_pace): the pace
## against a typical people of our age, the proofs a year, the biggest
## limiter, and one entry per input (icon, value, label, tone, its account).
static func pace_words(pace:Dictionary)->Dictionary:
	var learners:=float(pace.get("learners",0.0))
	var ratio:=float(pace.get("ratio",0.0))
	var typical:=float(pace.get("typical",0.0))
	var proofs:=float(pace.get("proofs",0.0))
	var words:={"value":"","words":"","proofs":"","limiter":"","limiter_tone":"plain","chips":[]}
	if learners<=0.0:
		words.value="No one"
		words.words="is set to learning, so nothing is being learned"
	else:
		words.value="%s×" % _amount(ratio,2 if absf(ratio-1.0)<0.1 else 1) if ratio<10.0 else "%d×" % roundi(ratio)
		# One headline: the pace against a typical people of our age, and what it proves a year.
		words.words="a typical people our age"+(" · about %s discover%s a year" % [_amount(proofs),"y" if proofs<1.5 and proofs>=0.95 else "ies"] if proofs>0.0 else " · no discovery near this year")
		words["tip"]="%s scholars; a typical people our age keeps about %s." % [_scholars(),_count(typical)]
	var limit:=limiter(pace)
	words.limiter=String(limit.text);words.limiter_tone=String(limit.tone)
	var chips:Array=[]
	# Learners: the people at it, their teams, and what the age can spare.
	var heads:=float(pace.get("heads",learners))
	var share:=learners/maxf(1.0,float(pace.get("able",1.0)))
	chips.append({"kind":"learners","icon":["people","learn"],"value":_scholars(),"label":"scholars",
		"tone":"bad" if learners<=0.0 else "plain",
		"tip":"%s at learning (%s by head; the hurt count less, those away teaching and those tending the sick and the lenses not at all, a gifted scholar more). They work %d question%s at once, a team on each.\nA people our age can spare %d in 100 of its able as learners, about %s; we keep %d in 100. Every learner counts; ten times the learners do about 7.6 times the work." % [_count(learners),_count(heads),int(pace.get("teams",0)),"" if int(pace.get("teams",0))==1 else "s",roundi(float(pace.get("sustainable",0.0))*100.0),_count(typical),roundi(share*100.0)]})
	# Goods: what the learners use a day, and any shortfall.
	var need:=float(pace.get("goods_need",0.0))
	var cover:=float(pace.get("goods_cover",1.0))
	var given:=need*cover
	var short:=cover<0.995 and need>0.0
	chips.append({"kind":"goods","icon":["moment","hearth_count"],"value":"%s goods a day" % _amount(need),
		"label":"only %s given, %s short" % [_amount(given),_amount(need-given)] if short else "fully supplied","tone":"bad" if short else "plain",
		"tip":"Learners use goods: tallies, writing stuff and tools. Each uses %s a day: one for each %d days of learning, and the same again for every %d years our learning runs ahead of the calendar.\nThey ask %s a day; the stores give %s and hold %s. Short of goods, learning slows, to half its pace with none: it goes at %d in 100 now. More makers make more goods." % [_amount(float(pace.get("goods_per_learner",0.0)),2),roundi(Catalog.LEARNER_DAYS_PER_GOOD),roundi(Catalog.LEAD_GOODS_YEARS),_amount(need),_amount(given),_amount(float(pace.get("goods_held",0.0))),roundi(float(pace.get("goods_factor",1.0))*100.0)]})
	# The lead over the calendar, and how it moves.
	var lead:=float(pace.get("lead",0.0))
	var rate:=float(pace.get("lead_rate",0.0))
	var drift:="gaining about %s years every ten years" % _amount(rate*10.0) if rate>0.0 else ("falling back about %s years every ten years" % _amount(-rate*10.0) if rate<0.0 and lead>0.0 else "level with the calendar")
	chips.append({"kind":"lead","icon":["moment","ahead"],"value":"%s years ahead" % _count(lead) if lead>=0.5 else "Level","label":"of the calendar" if lead>=0.5 else "with the calendar",
		"tone":"plain","tip":"Keeping more learners than our age can spare carries our learning ahead of the calendar: our questions are dated from year %d, not the calendar's. We are %s.\nThe lead is paid for: each learner needs %s times the goods, and learners past what the age can spare cost the people work, weariness, cohesion and births." % [roundi(float(pace.get("year",0.0))),drift,_amount(1.0+lead/Catalog.LEAD_GOODS_YEARS,2)]})
	# A young people learns slowly.
	var founding:=float(pace.get("founding",1.0))
	if founding>1.0001:
		chips.append({"kind":"young","icon":["moment","sprout"],"value":_times(founding)+" work","label":"young people","tone":"warn","tip":String(pace.get("founding_words",""))})
	# Support: food, tools and materials, order and schooling.
	var support:=float(pace.get("support",1.0))
	chips.append({"kind":"support","icon":["people","fed"],"value":_times(support)+" pace","label":"fed and taught","tone":"warn" if support<0.95 else "plain",
		"tip":"How well the learners are fed (food %d in 100 secure), kept in tools and materials, ordered, and taught (schooling %d in 100) sets how well each works: together %s the usual pace." % [roundi(clampf(float(pace.get("food_security",0.0)),0.0,1.0)*100.0),roundi(float(pace.get("education",0.0))*100.0),_times(support)]})
	# Scholars paid from the realm's purse.
	var pay:=float(pace.get("pay",1.0))
	if pay>1.0001:
		chips.append({"kind":"pay","icon":["domain","wealth"],"value":_times(pay)+" pace","label":"scholars paid","tone":"good","tip":"The realm's purse pays the scholars: while it does every question goes %s as fast." % _times(pay)})
	# Gifted scholars.
	var gifted:Array=pace.get("gifted",[])
	var lift:=float(pace.get("gifted_lift",0.0))
	chips.append({"kind":"gifted","icon":["moment","discovery"],"value":(str(gifted.size()) if not gifted.is_empty() else "None"),"label":"gifted scholars" if gifted.size()!=1 else "gifted scholar",
		"tone":"good" if lift>0.0 else "muted",
		"tip":("%s: each learner counts %d in 100 more while they live." % [", ".join(PackedStringArray(gifted)),roundi(lift*100.0)]) if not gifted.is_empty() else "No grown gifted scholar lives among us. Gifted children are born now and then; carers and learners spot them, and a gifted scholar makes every learner count for more."})
	# Teachers away, and visiting teachers here.
	var abroad:=int(pace.get("abroad",0))
	var taught:Array=pace.get("taught",[])
	chips.append({"kind":"teachers","icon":["moment","contact"],"value":("%d away · %d here" % [abroad,taught.size()]) if abroad>0 or not taught.is_empty() else "None","label":"teachers abroad",
		"tone":"plain" if abroad>0 or not taught.is_empty() else "muted",
		"tip":"%s%s" % ["%d of our learners teach abroad and do no learning here until they return.\n" % abroad if abroad>0 else "None of our learners is away teaching.\n",("A visiting teacher works with us on %s: half again as fast while they stay." % ", ".join(PackedStringArray(taught))) if not taught.is_empty() else "No visiting teacher is with us. Envoys can bring one for sixty days; their question goes half again as fast while they stay."]})
	# Builders' craft on building questions.
	var craft:=float(pace.get("craft",1.0))
	if craft>1.0005:
		chips.append({"kind":"craft","icon":["people","build"],"value":_times(craft)+" pace","label":"for building","tone":"good","tip":"Skilled builders learn new ways of building faster: questions of building and works go %s as fast." % _times(craft)})
	# Artifact study.
	if bool(pace.get("studying",false)):
		chips.append({"kind":"artifacts","icon":["domain","culture"],"value":_times(0.85)+" pace","label":"artifact study","tone":"warn","tip":"Learners study the artifacts we hold; while they do, every question goes at 85 in 100 of its pace."})
	words.chips=chips
	return words

## The single biggest limiter in plain words: whichever of working ahead of
## the age, short goods, a young people's extra work, few learners, weak
## support, weak offices, artifact study or a lacking material costs the most
## pace now. {kind, text, tone, loss}.
static func limiter(pace:Dictionary)->Dictionary:
	if float(pace.get("learners",0.0))<=0.0:
		return {"kind":"none","text":"Nobody is set to learning. Local leaders decide who learns: ask them for more hands on learning.","tone":"bad","loss":1.0}
	var candidates:Array=[]
	var factor:=float(pace.get("work_factor",1.0))
	if factor>1.05:
		var span:="%d years" % roundi(float(pace.get("furthest",0.0))) if absf(float(pace.get("furthest",0.0))-float(pace.get("earliest",0.0)))<5.0 else "%d to %d years" % [roundi(float(pace.get("earliest",0.0))),roundi(float(pace.get("furthest",0.0)))]
		candidates.append({"kind":"ahead","loss":1.0-1.0/factor,"tone":"warn","text":"Working ahead of our age: our questions stand %s early and take about %s the usual work. Nearer questions go faster; fewer learners let the calendar catch up." % [span,_times(factor)]})
	var goods:=float(pace.get("goods_factor",1.0))
	if goods<0.995:
		candidates.append({"kind":"goods","loss":1.0-goods,"tone":"bad","text":"Short of goods: the learners get %d in 100 of the tallies, writing stuff and tools they use, so learning goes at %d in 100 of its pace. More makers, or fewer learners." % [roundi(float(pace.get("goods_cover",1.0))*100.0),roundi(goods*100.0)]})
	var founding:=float(pace.get("founding",1.0))
	if founding>1.0001:
		candidates.append({"kind":"young","loss":1.0-1.0/founding,"tone":"warn","text":String(pace.get("founding_words",""))})
	var ratio:=float(pace.get("work",0.0))/maxf(0.000001,float(pace.get("typical_work",0.0)))
	if float(pace.get("typical_work",0.0))>0.0 and ratio<0.95:
		candidates.append({"kind":"few","loss":1.0-ratio,"tone":"warn","text":"Few learners: %s at learning, where a people our age keeps about %s. More hands on learning would speed every question." % [_count(float(pace.get("learners",0.0))),_count(float(pace.get("typical",0.0)))]})
	var support:=float(pace.get("support",1.0))
	if support<0.95:
		candidates.append({"kind":"support","loss":1.0-support,"tone":"warn","text":"Poorly kept learners: food, tools, order and schooling hold them to %d in 100 of the usual pace." % roundi(support*100.0)})
	var offices:=float(pace.get("offices",1.0))
	if offices<0.95:
		candidates.append({"kind":"offices","loss":1.0-offices,"tone":"warn","text":"Weak offices: the officials over the fields' work, and our aims, hold it to about %d in 100 of its pace." % roundi(offices*100.0)})
	if bool(pace.get("studying",false)):
		candidates.append({"kind":"artifacts","loss":0.15,"tone":"warn","text":"Artifact study takes the learners' time: every question goes at 85 in 100 of its pace until it is done."})
	var lacking:Array=pace.get("lacking",[])
	if not lacking.is_empty():
		candidates.append({"kind":"material","loss":0.25*float(lacking.size())/maxf(1.0,float(pace.get("questions",1))),"tone":"bad","text":"Lacking material: %s wait%s on a material we have not found or worked. Survey or work it." % [", ".join(PackedStringArray(lacking)),"s" if lacking.size()==1 else ""]})
	var best:Dictionary={"kind":"none","loss":0.0,"tone":"good","text":"Nothing holds the learning back much: the learners are fed, kept and working on questions of their age."}
	for candidate:Dictionary in candidates:
		if float(candidate.loss)>float(best.loss) and float(candidate.loss)>=0.03:best=candidate
	return best

## "3.4 times", "about the usual"; `bare` drops the "about the usual" words.
static func _times(factor:float,bare:=false)->String:
	if not bare and absf(factor-1.0)<0.005:return "the usual"
	if factor>=10.0:return "%d times" % roundi(factor)
	return "%s times" % _amount(factor,2 if absf(factor-1.0)<0.1 else 1)
static func _amount(value:float,places:int=1)->String:
	if absf(value)>=100.0:return str(roundi(value))
	var text:=("%."+str(places)+"f") % value
	if "." in text:text=text.rstrip("0").trim_suffix(".")
	return text
## The scholars by head, the top bar's own count and word
## (civilization_kpi_model.gd snapshot minds, the same call). Their weighted work (the hurt
## counting less, the gifted more) is in the chip's pointer.
static func _scholars()->String:
	return preload("res://scripts/hud/era_words.gd").grouped(roundi(float(preload("res://scripts/hud/civilization_kpi_model.gd").snapshot().minds)))

static func _count(value:float)->String:
	return preload("res://scripts/hud/production_plain.gd").number(roundf(value))

## A lane's waiting lines in a few words, and their whole account: "Injury
## safety: next question 107 years ahead", "Tool quality lacks stone".
static func _waiting_words(lane:Dictionary)->Dictionary:
	var parts:Array[String]=[]
	var tips:Array[String]=[]
	var lacking:=false
	for info:Dictionary in lane.waiting:
		var line:=String(info.get("line",""))
		match String(info.get("kind","")):
			"turn":parts.append("%s waits for a free team" % line)
			"ahead":parts.append("%s: next question too early" % line)
			_:
				var lacks:Array=info.get("lacks",[])
				if not lacks.is_empty():
					lacking=true
					parts.append("%s lacks %s" % [line," and ".join(PackedStringArray(lacks.map(func(m:Variant)->String:return String(m).to_lower())))])
				else:parts.append("%s needs earlier knowledge" % line)
		tips.append("%s: %s" % [line,String(info.get("reason",""))])
	# The first waiting line in a few words; every line and its reason on hover.
	var text:=parts[0]+(" · %d more line%s waiting" % [parts.size()-1,"" if parts.size()==2 else "s"] if parts.size()>1 else "") if not parts.is_empty() else ""
	if (lane.slots as Array).is_empty() and parts.is_empty():text="Nothing being worked on" if not (lane.field as Dictionary).is_empty() else ""
	return {"text":text,"tip":"\n".join(tips),"lacking":lacking}

## A question card's words from its record: its evidence (0..1), who works it
## and its time to proof, its step and holdup (a short name and its sentence),
## what answering it would bring and open, and its whole account for the tooltip.
static func _card_words(record:Dictionary)->Dictionary:
	var progress:=clampf(float(record.get("progress",0)),0,1);var researchers:=float(record.get("research_workforce",0))
	var bottleneck:=String(record.get("bottleneck","EARLY EVIDENCE"))
	# Its step to proof, always: first cases, repeated, and the households trying it.
	var step:=Words.step(int(record.get("stage",Catalog.stage(progress))),float(record.get("trial_share",Catalog.trial_share(progress))))
	step=step.left(1).to_upper()+step.substr(1)
	# What holds it back, if anything: a short name and its sentence.
	var phase:=""
	var why:=""
	# The engine names a holdup "KEY — words"; its steps are no holdup.
	if " — " in bottleneck and not (bottleneck.begins_with("EARLY EVIDENCE") or bottleneck.begins_with("REPLICATION") or bottleneck.begins_with("VALIDATION")):
		phase=Visuals.phase({"assignment":{"bottleneck":bottleneck,"active":true,"capacity":{"researchers":researchers}}})
		if phase.is_empty():
			var reason:=bottleneck.split(" — ",true,1);phase=reason[0].left(1)+reason[0].substr(1).to_lower()
		why=Visuals.plain_bottleneck(bottleneck)
	var restated:=why.is_empty() or why.trim_suffix(".").to_lower()==phase.to_lower()
	var holdup:=(step+".") if why.is_empty() else (why if restated else "%s: %s" % [phase,why.left(1).to_lower()+why.substr(1)])
	# On the card, the holdup in a line: ahead of its age with its price, else
	# the short name and its reason; with none, its step.
	var status:=step
	if not phase.is_empty():
		if bottleneck.begins_with("AHEAD OF ITS AGE") and float(record.get("years_ahead",0.0))>=1.0:
			status=Words.lead_price(float(record.years_ahead),float(record.get("work_factor",1.0)))
			status=status.left(1).to_upper()+status.substr(1)
		# "A thin team: …" already names its holdup; others take their short name.
		else:status=(why if phase.to_lower() in why.to_lower() else holdup).trim_suffix(".")
	# What answering it would do in the game, from the engine's own readings.
	var effects:Dictionary=record.get("effects",{})
	var would:=""
	var brings:=""
	if not effects.is_empty():
		would="Would bring: %s." % Explainer.summary(effects)
		brings="\n\nWhat it would do, at full use:\n"+Explainer.effect_lines(effects,1.0,1.0,false)
	# What answering it would change on the map itself (nation_borders.gd).
	var map_note:=Borders.research_note(String(record.get("id","")))
	if map_note!="":
		would=(would+" " if not would.is_empty() else "")+map_note
		brings+="\n\nOn the map: "+map_note
	var opens:=int(record.get("opens",0))
	var opens_words:=("Opens %d more question%s" % [opens,"" if opens==1 else "s"]) if opens>0 else ""
	if opens>0:would=(would+" " if not would.is_empty() else "")+opens_words+"."
	# The card's last line: what it opens first, then what it would bring.
	var bring_words:=("Would bring: %s." % Explainer.summary(effects)) if not effects.is_empty() else ""
	var card_opens:=opens_words+(" · " if not opens_words.is_empty() and not bring_words.is_empty() else "")+bring_words
	if card_opens.is_empty():card_opens=map_note if map_note!="" else "Changes nothing by itself; it opens the way to later knowledge."
	var goal:=String(record.get("observation",record.get("project_goal",record.get("project_method",""))))
	# Who works it and its clock: "A team of about 3 people; about 1½ years to proof".
	var team:=Words.team(researchers,int(record.get("teams_on",1)))
	var clock:=Words.clock(float(record.get("estimated_days",0.0)))
	# A young people's slow learning, beside the clock (DiscoverySystem.founding_words).
	var founding:=String(record.get("founding_note",""))
	var evidence:=team+("; "+clock if not clock.is_empty() else "")
	var brief:=Words.researchers(researchers) if int(record.get("teams_on",1))<2 else team
	if not clock.is_empty():brief+=" · "+clock
	var gathered:="%s (%d in 100 of the evidence)." % [Words.evidence(progress).left(1).to_upper()+Words.evidence(progress).substr(1),roundi(progress*100.0)]
	return {"progress":progress,"evidence":evidence,"brief":brief,"step":step,"phase":phase,"why":why,"restated":restated,"status":status,"would":would,"opens":card_opens,
		"tooltip":String(record.get("name","An open question"))+"\n"+(goal+"\n\n" if not goal.is_empty() else "\n")+evidence+". "+gathered+"\n"+holdup+("\n\n"+founding if not founding.is_empty() else "")+brings+("\n\n"+opens_words+"." if opens>0 else "")}

## The price of the furthest lead among the questions under way, once teams
## work five years or more ahead of the age: "Our learning runs ahead of its
## age. 25 years ahead: six times the work." "" otherwise.
static func lead_price(records:Array)->String:
	var furthest:Dictionary={}
	for record:Dictionary in records:
		if float(record.get("years_ahead",0.0))>=5.0 and (furthest.is_empty() or float(record.years_ahead)>float(furthest.years_ahead)):furthest=record
	if furthest.is_empty():return ""
	return "Our learning runs ahead of its age. %s." % Words.lead_price(float(furthest.years_ahead),float(furthest.get("work_factor",1.0)))

## One option of a free team's choice in words: its time with the team, how
## far ahead of its age, what it would bring and what it opens.
static func option_words(option:Dictionary)->Dictionary:
	var days:=float(option.get("days",0.0))
	var time:=Words.clock(days)
	var ahead:=""
	if float(option.get("years_ahead",0.0))>=1.0:ahead=Words.lead_price(float(option.years_ahead),float(option.get("work_factor",1.0))).left(1).to_upper()+Words.lead_price(float(option.years_ahead),float(option.get("work_factor",1.0))).substr(1)
	var effects:Dictionary=option.get("effects",{})
	var brings:="Would bring: %s." % Explainer.summary(effects) if not effects.is_empty() else "Changes nothing by itself; it opens the way to later knowledge."
	var opens:=int(option.get("opens",0))
	return {"time":(time.left(1).to_upper()+time.substr(1)+" with this team") if not time.is_empty() else "","ahead":ahead,"brings":brings,
		"opens":("Opens %d more question%s." % [opens,"" if opens==1 else "s"]) if opens>0 else "Opens no further question yet."}

## The badge on a freed team's card: "Choose ▾" opens the picker beside it.
func _choice_badge(card:Control,choice:Dictionary)->void:
	var badge:=Button.new();badge.name="ChoiceBadge";badge.text="Choose ▾";badge.focus_mode=Control.FOCUS_NONE
	badge.size_flags_horizontal=Control.SIZE_SHRINK_END;badge.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;badge.custom_minimum_size.y=24
	badge.add_theme_font_size_override("font_size",12);badge.add_theme_color_override("font_color",T.INK);badge.add_theme_color_override("font_hover_color",T.INK)
	badge.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG,T.GOLD,1,12,6));badge.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD_BRIGHT,1,12,6))
	badge.add_theme_stylebox_override("pressed",T.flat(T.HOVER_BG,T.GOLD_BRIGHT,1,12,6))
	badge.tooltip_text="A team is free: %s is proven. Keep them on the question they took, or send them to another." % String(choice.get("proved","A question"))
	card.add_child(badge)
	var popup:=PopupPanel.new();popup.name="ChoicePicker";popup.add_theme_stylebox_override("panel",T.flat(T.PANEL_BG_SOLID,T.GOLD,1,T.RADIUS_CARD,0))
	badge.add_child(popup)
	_choice_card(popup,choice)
	badge.pressed.connect(_open_picker.bind(badge,popup))

## Opens a choice's picker under its badge, right-aligned to it, kept on screen
## and as tall as its options once they have wrapped at its width.
func _open_picker(badge:Button,popup:PopupPanel)->void:
	var width:=int(clampf(size.x,320.0,760.0))
	var at:=badge.get_screen_position()+Vector2(badge.size.x-width,badge.size.y+4)
	var screen:=get_viewport().get_visible_rect().size
	at.x=clampf(at.x,get_screen_position().x,maxf(get_screen_position().x,screen.x-width-4.0))
	popup.popup(Rect2i(Vector2i(at),Vector2i(width,120)))
	await get_tree().process_frame
	if not is_instance_valid(popup) or not popup.visible:return
	var tall:=int(popup.get_contents_minimum_size().y)
	popup.size=Vector2i(width,tall)
	if at.y+tall>screen.y-4.0:popup.position.y=int(maxf(4.0,badge.get_screen_position().y-tall-4.0))

## A free team's choice: the proof that freed it, the question it took up, and
## its options side by side, each with a plain button. A season after the proof
## the badge goes and the team keeps the question it took.
func _choice_card(parent:Node,choice:Dictionary)->void:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(panel)
	panel.name="Choice_"+String(choice.get("key","")).validate_node_name()
	panel.add_theme_stylebox_override("panel",T.flat(T.PANEL_BG_SOLID,Color.TRANSPARENT,0,T.RADIUS_CARD,12))
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8);panel.add_child(box)
	box.add_child(T.make_label("A TEAM IS FREE",12,T.GOLD_TEXT))
	var options:Array=choice.get("options",[])
	var taken_name:=String((options[0] as Dictionary).get("name","")) if not options.is_empty() else ""
	box.add_child(_serif("%s is proven. Its team took up %s." % [String(choice.get("proved","A question")),taken_name],19))
	var left:=int(choice.get("days_left",0))
	_note(box,"Keep them on it, or send them to another question instead%s. They stay with what they take until it is proven; the work already done on a question is never lost." % (" (about %s left to choose)" % Words.Plain.span_text(float(left)) if left>=1 else ""))
	var grid:=GridContainer.new();grid.name="Options";grid.columns=3;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);box.add_child(grid)
	choice_grids.append(grid)
	for index in options.size():
		var option:Dictionary=options[index]
		var taken:=index==0
		var tile:=PanelContainer.new();tile.name="Option_"+String(option.get("id","")).validate_node_name();tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",T.flat(T.ACTIVE_BG if taken else T.TILE_BG,T.GOLD if taken else T.BORDER_SOFT,1,T.RADIUS_CONTROL,10));grid.add_child(tile)
		var text:=VBoxContainer.new();text.add_theme_constant_override("separation",4);tile.add_child(text)
		var domain:=String(option.get("dynamic",""))
		var kicker:=T.make_label((field_name(option)+(" · TAKEN UP" if taken else "")).to_upper(),12,T.legible(Visuals.color(domain)));text.add_child(kicker)
		text.add_child(_serif(String(option.get("name","")),17))
		var words:=option_words(option)
		if String(words.time)!="":_line(text,String(words.time),13,T.BODY)
		if String(words.ahead)!="":_line(text,String(words.ahead),12,T.AMBER_TEXT)
		_line(text,String(words.brings),12,T.TEXT_SOFT)
		_line(text,String(words.opens),12,T.TEXT_SOFT)
		var press:Variant=(data.on_choose as Callable).bind(String(choice.get("key","")),String(option.get("id",""))) if data.get("on_choose") is Callable else null
		# Choosing closes the picker it floats in.
		var pick:Variant=press
		if pick is Callable:press=func()->void:
			var window:=panel.get_parent() as Window
			if window:window.hide()
			(pick as Callable).call()
		var button:=_button(text,"Keep them on it" if taken else "Take this up instead",press,"They keep %s until it is proven." % String(option.get("name","")) if taken else "The team leaves %s (its work is kept) and takes up %s until it is proven." % [taken_name,String(option.get("name",""))],taken)
		button.name="Choose"

## A field's attention in words: its share and what is being worked on.
static func _field_words(field:Dictionary)->String:
	var share_words:="No attention" if float(field.share)<=0.0 else "About %d in 100 of our attention" % maxi(1,roundi(float(field.share)*100))
	return "%s; %s"%[share_words,"%d question%s being worked on" % [int(field.active),"" if int(field.active)==1 else "s"] if int(field.active)>0 else "nothing being worked on"]


# --------------------------------------------------------------------------
# The figures, and what speeds and slows the work
# --------------------------------------------------------------------------

## What speeds and slows the work on every question, each part with its size
## and its whole account: [{kind, label, amount, factor, tip}]. Parts that
## move the pace less than one in a hundred are left out.
static func pace_factors(pace:Dictionary)->Array:
	var parts:Array=[]
	if float(pace.get("learners",0.0))<=0.0:return parts
	var words:=pace_words(pace)
	var tips:Dictionary={}
	for chip:Dictionary in words.chips:tips[String(chip.kind)]=String(chip.tip)
	var add:=func(kind:String,label:String,factor:float,tip:String)->void:
		if absf(log(maxf(0.0001,factor)))<0.01:return
		parts.append({"kind":kind,"label":label,"factor":factor,"amount":factor_words(factor),"tip":tip})
	var early:=float(pace.get("work_factor",1.0))
	if early>1.05:
		add.call("early","Early questions",1.0/early,"The questions under way belong to a later age than ours: on average each takes %s the usual work (each question's own price is on its line). Nearer questions go faster; fewer learners let the calendar catch up." % _times(early))
	var goods:=float(pace.get("goods_factor",1.0))
	if goods<0.995:add.call("goods","Short of goods",goods,tips.get("goods",""))
	var founding:=float(pace.get("founding",1.0))
	if founding>1.0001:add.call("young","A young people",1.0/founding,String(pace.get("founding_words","")))
	var ratio:=float(pace.get("work",0.0))/maxf(0.000001,float(pace.get("typical_work",0.0)))
	if float(pace.get("typical_work",0.0))>0.0 and ratio<0.95:
		add.call("few","Few learners",ratio,"%s at learning, where a people our age keeps about %s. More hands on learning would speed every question." % [_count(float(pace.get("learners",0.0))),_count(float(pace.get("typical",0.0)))])
	var support:=float(pace.get("support",1.0))
	add.call("support","Fed and taught",support,tips.get("support",""))
	var offices:=float(pace.get("offices",1.0))
	add.call("offices","Officials",offices,"The officials over the fields' work, and our aims, set the pace of the questions under way: on average %s the usual." % _times(offices))
	if bool(pace.get("studying",false)):add.call("artifacts","Artifact study",0.85,tips.get("artifacts",""))
	var lacking:Array=pace.get("lacking",[])
	if not lacking.is_empty():
		add.call("material","Lacking material",1.0-0.25*float(lacking.size())/maxf(1.0,float(pace.get("questions",1))),"%s wait%s on a material we have not found or worked. Survey or work it." % [", ".join(PackedStringArray(lacking)),"s" if lacking.size()==1 else ""])
	var pay:=float(pace.get("pay",1.0))
	if pay>1.0001:add.call("pay","Scholars paid",pay,tips.get("pay",""))
	var lift:=float(pace.get("gifted_lift",0.0))
	if lift>0.0:add.call("gifted","Gifted scholars",1.0+lift,tips.get("gifted",""))
	var taught:Array=pace.get("taught",[])
	if not taught.is_empty():add.call("teachers","Visiting teacher",1.0+0.5*float(taught.size())/maxf(1.0,float(pace.get("questions",1))),tips.get("teachers",""))
	var craft:=float(pace.get("craft",1.0))
	if craft>1.0005:add.call("craft","Builders' craft",craft,tips.get("craft","")+" (Building questions only.)")
	return parts

## "×1.8", "+12%", "÷40", "−15%".
static func factor_words(factor:float)->String:
	if factor>=1.0:return ("×%s" % (str(roundi(factor)) if factor>=10.0 else _amount(factor))) if factor>=1.95 else "+%d%%" % roundi((factor-1.0)*100.0)
	var inverse:=1.0/maxf(0.0001,factor)
	return ("÷%s" % (str(roundi(inverse)) if inverse>=10.0 else _amount(inverse))) if inverse>=1.95 else "−%d%%" % roundi((1.0-factor)*100.0)

## The strip of figures, the bar of what speeds and slows the work.
func _pace_header(parent:Node,words:Dictionary,pace:Dictionary)->void:
	var box:=VBoxContainer.new();box.name="LearningPace";box.add_theme_constant_override("separation",8);parent.add_child(box)
	var strip:=HBoxContainer.new();strip.name="Figures";strip.add_theme_constant_override("separation",10);box.add_child(strip)
	_header["pace"]=_figure(strip,"PACE")
	_header["proofs"]=_figure(strip,"DISCOVERIES")
	_header["teams"]=_figure(strip,"TEAMS AT WORK")
	_header["lead"]=_figure(strip,"AHEAD OF THE CALENDAR")
	var row:=HBoxContainer.new();row.name="Factors";row.add_theme_constant_override("separation",10);box.add_child(row)
	var caption:=T.make_label("SPEEDS AND SLOWS",11,T.GOLD_TEXT,0.06);caption.custom_minimum_size.x=FIELD_W+30.0;caption.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(caption)
	var stack:=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",4);row.add_child(stack)
	factor_bar=FactorBar.new();factor_bar.name="FactorBar";factor_bar.custom_minimum_size.y=14;stack.add_child(factor_bar)
	var legend:=HFlowContainer.new();legend.name="FactorLegend";legend.add_theme_constant_override("h_separation",14);legend.add_theme_constant_override("v_separation",2);stack.add_child(legend)
	_header["legend"]=legend
	_fill_header(words,pace)

## A figure of the strip: its name, its value large, a note and, when it
## has a stated maximum, a bar against it.
func _figure(parent:Node,title:String)->Dictionary:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.name="Figure_"+title.capitalize().replace(" ","")
	panel.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,T.BORDER_SOFT,1,T.RADIUS_CONTROL,8));parent.add_child(panel)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",1);box.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(box)
	box.add_child(T.make_label(title,11,T.GOLD_TEXT,0.06))
	var value:=_voice("",24);value.autowrap_mode=TextServer.AUTOWRAP_OFF;value.name="Value";value.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(value)
	var note:=T.make_label("",12,T.TEXT_SOFT);note.name="Note";note.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(note)
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size=Vector2(0,5);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(T.GOLD));box.add_child(bar)
	return {"panel":panel,"value":value,"note":note,"bar":bar}

func _set_figure(refs:Dictionary,value:String,note:String,ratio:float,tip:String)->void:
	_put(refs.value,value);_put(refs.note,note)
	(refs.bar as ProgressBar).visible=ratio>=0.0
	(refs.bar as ProgressBar).value=clampf(ratio,0.0,1.0)*100.0
	(refs.panel as Control).tooltip_text=tip

func _fill_header(words:Dictionary,pace:Dictionary)->void:
	var learners:=float(pace.get("learners",0.0))
	var ratio:=float(pace.get("ratio",0.0))
	_set_figure(_header.pace,String(words.value),"of a typical people our age" if learners>0.0 else "is set to learning",ratio/3.0 if learners>0.0 else 0.0,
		String(words.get("tip",""))+"\nThe bar runs to three times a typical people.\n\n"+String(_chip_tip(words,"goods")))
	var proofs:=float(pace.get("proofs",0.0))
	_set_figure(_header.proofs,"about %s" % _amount(proofs) if proofs>0.0 else "None","a year at this pace" if proofs>0.0 else "near this year",-1.0,
		"The questions under way, each at its team's pace today, prove about this many a year.")
	var teams:=int(pace.get("teams",0))
	var placed:=int(pace.get("teams_at_work",teams))
	_set_figure(_header.teams,"%d of %d" % [placed,teams],"one question each",float(placed)/maxf(1.0,float(teams)),String(_chip_tip(words,"learners")))
	var lead:=float(pace.get("lead",0.0))
	_set_figure(_header.lead,"%s years" % _count(lead) if lead>=0.5 else "Level",_drift_words(pace),-1.0,String(_chip_tip(words,"lead")))
	var parts:=pace_factors(pace)
	if factor_bar:factor_bar.set_parts(parts)
	if _header.has("legend"):_fill_legend(_header.legend,parts)

## The bar's parts by name and size, slowing first: a swatch, the name, the size.
func _fill_legend(legend:HFlowContainer,parts:Array)->void:
	var ordered:Array=parts.filter(func(p:Dictionary)->bool:return float(p.factor)<1.0)+parts.filter(func(p:Dictionary)->bool:return float(p.factor)>=1.0)
	var wanted:Array=ordered.map(func(p:Dictionary)->String:return "%s %s" % [String(p.label),String(p.amount)])
	var had:Array=legend.get_children().map(func(n:Node)->String:return String(n.get_meta("words","")))
	if had==wanted:return
	for child in legend.get_children():legend.remove_child(child);child.queue_free()
	for k in ordered.size():
		var p:Dictionary=ordered[k]
		var slow:=float(p.factor)<1.0
		var item:=HBoxContainer.new();item.add_theme_constant_override("separation",4);item.set_meta("words",wanted[k]);item.tooltip_text=String(p.tip);item.mouse_filter=Control.MOUSE_FILTER_PASS
		var swatch:=ColorRect.new();swatch.color=T.RED if slow else T.GREEN;swatch.custom_minimum_size=Vector2(9,9);swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE;item.add_child(swatch)
		var name_label:=T.make_label(String(p.label),12,T.BODY);name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;item.add_child(name_label)
		var amount:=T.make_label(String(p.amount),12,T.RED_TEXT if slow else T.GREEN_TEXT);amount.mouse_filter=Control.MOUSE_FILTER_IGNORE;item.add_child(amount)
		legend.add_child(item)

static func _chip_tip(words:Dictionary,kind:String)->String:
	for chip:Dictionary in words.get("chips",[]):
		if String(chip.kind)==kind:return String(chip.tip)
	return ""

## "gaining 1 a decade", "falling back 2 a decade", "steady".
static func _drift_words(pace:Dictionary)->String:
	var rate:=float(pace.get("lead_rate",0.0))*10.0
	if rate>=0.05:return "gaining %s a decade" % _amount(rate)
	if rate<=-0.05 and float(pace.get("lead",0.0))>0.0:return "losing %s a decade" % _amount(-rate)
	return "steady"

## Who sets the learners, and the two orders that change it.
func _hands(parent:Node,hands:Dictionary)->void:
	var row:=HBoxContainer.new();row.name="Hands";row.add_theme_constant_override("separation",8);parent.add_child(row)
	var caption:=T.make_label("LEARNERS",11,T.GOLD_TEXT,0.06);caption.custom_minimum_size.x=FIELD_W+30.0;caption.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(caption)
	var said:=T.make_label(String(hands.get("words","")),13,T.BODY);said.name="HandsWords";said.size_flags_horizontal=Control.SIZE_EXPAND_FILL;said.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	said.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;said.custom_minimum_size.x=120
	said.tooltip_text=String(hands.get("tip",""));said.mouse_filter=Control.MOUSE_FILTER_PASS;row.add_child(said)
	var blocked:=bool(hands.get("occupied",false))
	var more:=_small_button(row,"More hands on learning",null if blocked else hands.get("on_more"),"Not while the place is occupied" if blocked else "Ask the local leader to move some people to learning. It changes who works at learning, not what is found.")
	more.name="MoreHands"
	var free:=_small_button(row,"Let the leader decide",null if blocked else hands.get("on_free"),"Not while the place is occupied" if blocked else "Let the local leader share out the work again.")
	free.name="LeaderDecides"

# --------------------------------------------------------------------------
# The table: one row per field
# --------------------------------------------------------------------------

func _table_head(parent:Node)->void:
	var head:=HBoxContainer.new();head.name="TableHead";head.add_theme_constant_override("separation",8);parent.add_child(head)
	head.custom_minimum_size.y=22
	for spec:Array in [["FIELD",FIELD_W+38.0],["ATTENTION",_attention_width()],["UNDER WAY",0.0],["EVIDENCE",BAR_W],["TO PROOF",TIME_W]]:
		var label:=T.make_label(String(spec[0]),11,T.GOLD_TEXT,0.06);label.size_flags_vertical=Control.SIZE_SHRINK_END
		if float(spec[1])>0.0:label.custom_minimum_size.x=float(spec[1])
		else:label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		if String(spec[0])=="TO PROOF":label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		head.add_child(label)
	var rule:=ColorRect.new();rule.color=T.BORDER_SOFT;rule.custom_minimum_size.y=1;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(rule)

static func _attention_width()->float:
	return SHARE_W+4.0+34.0+4.0+22.0+4.0+22.0

## A field's row: its mark, name, attention with − and +, then its first
## question; its further questions on lines of their own beneath.
func _lane(parent:Node,lane:Dictionary)->void:
	var id:=String(lane.id)
	var accent:=Visuals.color(id) if not id.is_empty() else T.MUTED
	var box:=VBoxContainer.new();box.name="Lane_"+(id if not id.is_empty() else "other");box.add_theme_constant_override("separation",0);parent.add_child(box)
	var head:=_line_box(box,"LaneHead")
	var lead:=HBoxContainer.new();lead.add_theme_constant_override("separation",6);lead.custom_minimum_size.x=FIELD_W+38.0;lead.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(lead)
	var rule:=ColorRect.new();rule.color=accent;rule.custom_minimum_size=Vector2(3,20);rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;lead.add_child(rule)
	var glyph:=TextureRect.new();glyph.texture=Icons.domain_texture(id if not id.is_empty() else "knowledge",accent);glyph.custom_minimum_size=Vector2(20,20);glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE
	glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;glyph.size_flags_vertical=Control.SIZE_SHRINK_CENTER;lead.add_child(glyph)
	var title:=T.make_label(String(lane.name),13,T.INK);title.name="FieldLabel";title.size_flags_vertical=Control.SIZE_SHRINK_CENTER;title.mouse_filter=Control.MOUSE_FILTER_PASS;lead.add_child(title)
	var field:Dictionary=lane.field
	var attention:=HBoxContainer.new();attention.name="AttentionCell";attention.add_theme_constant_override("separation",4);attention.custom_minimum_size.x=_attention_width();head.add_child(attention)
	var refs:={"title":title,"less":null,"share":null,"attention":null,"waiting":null}
	if not field.is_empty():
		var share:=ProgressBar.new();share.name="Share";share.show_percentage=false;share.custom_minimum_size=Vector2(SHARE_W,7);share.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		share.add_theme_stylebox_override("background",T.flat(T.TRACK));share.add_theme_stylebox_override("fill",T.flat(accent));share.mouse_filter=Control.MOUSE_FILTER_PASS;attention.add_child(share)
		var pct:=T.make_label("",12,T.BODY);pct.name="Attention";pct.custom_minimum_size.x=34;pct.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;pct.size_flags_vertical=Control.SIZE_SHRINK_CENTER;pct.mouse_filter=Control.MOUSE_FILTER_PASS;attention.add_child(pct)
		refs.share=share;refs.attention=pct
		refs.less=_step_button(attention,"−",field.get("on_less"),"Give one step of this field's attention to the others")
		_step_button(attention,"+",field.get("on_more"),"Move one step of attention to this field")
	_lanes[id]=refs
	var slots:Array=lane.slots
	if slots.is_empty():
		var wait:=_fixed(head,"",12,T.TEXT_SOFT);wait.name="Waiting";wait.mouse_filter=Control.MOUSE_FILTER_STOP
		refs.waiting=wait
	else:
		_question(head,slots[0],accent)
		for index in range(1,slots.size()):
			var more:=_line_box(box,"More")
			var pad:=Control.new();pad.custom_minimum_size.x=FIELD_W+38.0+8.0+_attention_width();pad.mouse_filter=Control.MOUSE_FILTER_IGNORE;more.add_child(pad)
			_question(more,slots[index],accent)
	_fill_lane(refs,lane)

## A line of the table: one row tall, a hairline beneath.
func _line_box(parent:Node,line_name:String)->HBoxContainer:
	var line:=HBoxContainer.new();line.name=line_name;line.add_theme_constant_override("separation",8);line.custom_minimum_size.y=CARD_HEIGHT;parent.add_child(line)
	return line

func _step_button(parent:Node,label:String,callback:Variant,tip:String)->Button:
	var button:=_button(parent,label,callback,tip)
	button.custom_minimum_size=Vector2(22,22);button.add_theme_font_size_override("font_size",14);button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	for state:String in ["normal","hover","pressed","disabled"]:
		var style:StyleBoxFlat=(button.get_theme_stylebox(state) as StyleBoxFlat).duplicate() if button.get_theme_stylebox(state) is StyleBoxFlat else T.flat(Color.TRANSPARENT,T.BORDER_SOFT,1,2,0)
		style.content_margin_left=4;style.content_margin_right=4;style.content_margin_top=0;style.content_margin_bottom=0
		button.add_theme_stylebox_override(state,style)
	return button

func _fill_lane(refs:Dictionary,lane:Dictionary)->void:
	var field:Dictionary=lane.field
	if not field.is_empty():
		var share:=float(field.get("share",0.0))
		(refs.share as ProgressBar).value=clampf(share,0.0,1.0)*100.0
		_put(refs.attention,"none" if share<=0.0 else "%d%%" % maxi(1,roundi(share*100.0)),T.TEXT_SOFT if share<=0.0 else T.BODY)
		var goal:=String(field.get("goal",""))
		(refs.title as Label).tooltip_text=goal.left(1).to_upper()+goal.substr(1)
		var tip:=_field_words(field)
		(refs.attention as Label).tooltip_text=tip;(refs.share as Control).tooltip_text=tip
		if refs.less!=null:(refs.less as Button).disabled=int(field.get("weight",0))<=0
	if refs.waiting!=null:
		var waiting:=_waiting_words(lane)
		_put(refs.waiting,String(waiting.text),T.AMBER_TEXT if bool(waiting.lacking) else T.TEXT_SOFT)
		(refs.waiting as Label).tooltip_text=String(waiting.tip)

## A question's cells: its name, what holds it back (when something does),
## what it would bring (on a wide board), its evidence as a bar and its time
## to proof. Its whole account is on hover.
func _question(parent:Node,slot:Dictionary,accent:Color)->void:
	var record:Dictionary=slot.record
	var cell:=HBoxContainer.new();cell.name="Question_"+String(record.get("id","")).validate_node_name();cell.add_theme_constant_override("separation",8)
	cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.custom_minimum_size.y=CARD_HEIGHT;cell.mouse_filter=Control.MOUSE_FILTER_STOP;parent.add_child(cell)
	var refs:={"panel":cell,"id":""}
	refs.name=_fixed(cell,"",13,T.INK);refs.name.name="QuestionName"
	refs.phase=T.make_label("",12,T.AMBER_TEXT);refs.phase.name="Holdup";refs.phase.size_flags_vertical=Control.SIZE_SHRINK_CENTER;refs.phase.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(refs.phase)
	refs.would=T.make_label("",12,T.TEXT_SOFT);refs.would.name="WouldBring";refs.would.size_flags_vertical=Control.SIZE_SHRINK_CENTER;refs.would.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(refs.would)
	_brings.append(refs.would)
	var bar:=ProgressBar.new();bar.name="Evidence";bar.show_percentage=false;bar.custom_minimum_size=Vector2(BAR_W,8);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(accent));cell.add_child(bar)
	refs.bar=bar
	refs.time=T.make_label("",12,T.BODY);refs.time.name="TimeLeft";refs.time.custom_minimum_size.x=TIME_W;refs.time.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;refs.time.size_flags_vertical=Control.SIZE_SHRINK_CENTER;refs.time.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(refs.time)
	var badges:=HBoxContainer.new();badges.name="Badges";badges.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(badges)
	refs.badges=badges
	_cards[String(slot.key)]=refs
	_fill_card(refs,record)

func _fill_card(refs:Dictionary,record:Dictionary)->void:
	var words:=_card_words(record)
	var id:=String(record.get("id",""))
	if String(refs.id)!=id:
		refs.id=id
		(refs.panel as Control).name="Question_"+id.validate_node_name()
	_put(refs.name,String(record.get("name","An open question")))
	# What holds it back, in its short name; being early for our age is its price, told on hover.
	var held:=String(words.phase)!="" and not String(record.get("bottleneck","")).begins_with("AHEAD OF ITS AGE")
	_put(refs.phase,String(words.phase) if held else "")
	(refs.phase as Label).visible=held
	var effects:Dictionary=record.get("effects",{})
	_put(refs.would,("Would bring: %s" % Explainer.summary(effects,1)) if not effects.is_empty() else "")
	(refs.bar as ProgressBar).value=float(words.progress)*100.0
	var days:=float(record.get("estimated_days",0.0))
	var clock:=Words.Plain.span_text(days) if days>0.0 and is_finite(days) and days<=365.0*150.0 else ("—" if days<=0.0 else "no end in sight")
	_put(refs.time,clock,T.BODY if days>0.0 else T.TEXT_SOFT)
	(refs.panel as Control).tooltip_text=String(words.tooltip)
	_show_brings()

func _empty(parent:Node)->void:
	var line:=_line_box(parent,"NothingUnderWay")
	var label:=T.make_label("No question is under way: the people need clues and earlier knowledge first.",13,T.TEXT_SOFT);label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(label)

## Artifact study: the same row as a field, its share of the learners' time
## with − and +, and the collection's count.
func _artifact_row(parent:Node,study:Dictionary)->void:
	var box:=VBoxContainer.new();box.name="Lane_artifacts";parent.add_child(box)
	var head:=_line_box(box,"LaneHead")
	var lead:=HBoxContainer.new();lead.add_theme_constant_override("separation",6);lead.custom_minimum_size.x=FIELD_W+38.0;head.add_child(lead)
	var rule:=ColorRect.new();rule.color=Color("b98a5e");rule.custom_minimum_size=Vector2(3,20);rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER;lead.add_child(rule)
	var glyph:=TextureRect.new();glyph.texture=Icons.domain_texture("culture",Color("b98a5e"));glyph.custom_minimum_size=Vector2(20,20)
	glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;glyph.size_flags_vertical=Control.SIZE_SHRINK_CENTER;lead.add_child(glyph)
	var title:=T.make_label("Artifact study",13,T.INK);title.name="FieldLabel";title.size_flags_vertical=Control.SIZE_SHRINK_CENTER;lead.add_child(title)
	var attention:=HBoxContainer.new();attention.add_theme_constant_override("separation",4);attention.custom_minimum_size.x=_attention_width();head.add_child(attention)
	var share:=ProgressBar.new();share.show_percentage=false;share.custom_minimum_size=Vector2(SHARE_W,7);share.size_flags_vertical=Control.SIZE_SHRINK_CENTER;share.value=clampf(float(study.get("share",0.0)),0.0,1.0)*100.0
	share.add_theme_stylebox_override("background",T.flat(T.TRACK));share.add_theme_stylebox_override("fill",T.flat(Color("b98a5e")));attention.add_child(share)
	var pct:=T.make_label("%d%%" % roundi(float(study.get("share",0.0))*100.0),12,T.BODY);pct.custom_minimum_size.x=34;pct.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;pct.size_flags_vertical=Control.SIZE_SHRINK_CENTER;attention.add_child(pct)
	pct.tooltip_text=String(study.get("tip",""));pct.mouse_filter=Control.MOUSE_FILTER_PASS
	var less:=_step_button(attention,"−",study.get("on_less"),"Give one step of the study's attention to the fields");less.disabled=less.disabled or int(study.get("weight",0))<=0
	_step_button(attention,"+",study.get("on_more"),"Move one step of attention to artifact study")
	var said:=T.make_label(String(study.get("words","")),12,T.BODY);said.name="ArtifactWords";said.size_flags_horizontal=Control.SIZE_EXPAND_FILL;said.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	said.tooltip_text=String(study.get("tip",""));said.mouse_filter=Control.MOUSE_FILTER_PASS;head.add_child(said)

# --------------------------------------------------------------------------
# Small pieces
# --------------------------------------------------------------------------

## A one-line label whose words never change its size: too long, it ends in "…".
func _fixed(parent:Node,value:String,font:int,ink:Color)->Label:
	var label:=T.make_label(value,font,ink);_clip(label);parent.add_child(label);return label
static func _clip(label:Label)->void:
	label.autowrap_mode=TextServer.AUTOWRAP_OFF;label.clip_text=true;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;label.custom_minimum_size.x=1;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
func _small_button(parent:Node,label:String,callback:Variant,tip:String)->Button:
	var button:=_button(parent,label,callback,tip)
	button.custom_minimum_size.y=24;button.add_theme_font_size_override("font_size",12);button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	return button
func _show_brings()->void:
	var wide:=size.x>=BRINGS_AT
	for label:Label in _brings:
		if is_instance_valid(label):label.visible=wide and label.text!=""
func _arrange()->void:
	var wide:=size.x>=WIDE
	for grid:GridContainer in choice_grids:
		if is_instance_valid(grid):grid.columns=3 if wide else 1
	_show_brings()
