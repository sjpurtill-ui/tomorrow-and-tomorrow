extends "res://scripts/hud/settlement_overview.gd"
## The Research board ("Where we look"). It answers two questions:
## - how fast are we learning, and what limits it: one header with the pace
##   against a typical people of our age, the single biggest limiter named in
##   plain words, and every input as an icon with its value;
## - what is being learned: one lane per field in a fixed order, each with its
##   attention, its questions as compact cards and its waiting lines.
## Cards never move. A card's place is its line of study (its channel), so a
## proof that hands the line a new question changes the card's words, not its
## place; only the arc and the numbers change from day to day (update_block).
## Every number comes from the engine (dock_content_inquiry.gd learning_pace,
## waiting_lines and DiscoverySystem.active_investigation_records).
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const Explainer:=preload("res://scripts/effect_explainer.gd")
const Borders:=preload("res://scripts/nation_borders.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Arc:=preload("res://scripts/hud/learning_arc.gd")
const Catalog:=preload("res://scripts/research_600_catalog.gd")
## Below this board width the free team's options stack in one column.
const WIDE:=760.0
## A lane holds two cards a row from this width, one below it.
const TWO_CARDS:=540.0
const CARD_HEIGHT:=84.0
const ARC_SIZE:=46.0
## An input on the header is this wide; the header fits as many a row as it can.
const CHIP_WIDTH:=136.0
## Lines of study in each field, in the catalog's order: a card's place in its lane.
const LINES:=preload("res://scripts/discovery_frontier_catalog.gd").SUBCATEGORIES
## Each free team's options, side by side on a wide board, stacked on a narrow one.
var choice_grids:Array[GridContainer]=[]
## Each lane's cards (two a row on a wide board).
var lane_grids:Array[GridContainer]=[]
var chip_grid:GridContainer
## The board's shape (update_block keeps the nodes while it holds) and the
## nodes the daily refresh writes into.
var _shape:Array=[]
var _cards:Dictionary={}
var _lanes:Dictionary={}
var _chips:Dictionary={}
var _header:Dictionary={}

func setup(block:Dictionary)->void:
	data=block;name="InquiryBoard";add_theme_constant_override("separation",12)
	var plan:=_plan(block)
	_shape=plan.shape
	if block.has("pace"):_pace_header(self,plan.pace)
	else:_plain_heading(self)
	var learning:=VBoxContainer.new();learning.name="BeingLearned";learning.add_theme_constant_override("separation",6);add_child(learning)
	var heading:=HBoxContainer.new();learning.add_child(heading)
	var title:=T.make_label("BEING LEARNED, FIELD BY FIELD",12,T.GOLD_TEXT);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
	var hint:=T.make_label("Hover a card for the whole account; click it for its field.",12,T.TEXT_SOFT);heading.add_child(hint)
	for lane:Dictionary in plan.lanes:_lane(learning,lane)
	if (data.get("investigations",[]) as Array).is_empty():_empty(learning)
	# A team freed by a proof took up the best question open to it; for a season
	# the player may send it elsewhere (DiscoverySystem.team_choices). The choice
	# waits on that question's own card as a badge with a floating picker, so
	# it never pushes the board down when it arrives or goes.
	for choice:Dictionary in data.get("choices",[]):
		var card:Dictionary=_cards.get(String(choice.get("channel","")),{})
		if not card.is_empty():_choice_badge(card.panel,choice)
	resized.connect(_arrange);_arrange()

## The live refresh: while the board keeps its shape the header, the lanes
## and the cards take the day's numbers in place (the arcs ease to the day's
## evidence); otherwise the board is drawn afresh.
func update_block(block:Dictionary)->bool:
	var plan:=_plan(block)
	if _lanes.is_empty() or plan.shape!=_shape:return false
	data=block
	if not _header.is_empty():_fill_header(plan.pace)
	for lane:Dictionary in plan.lanes:
		var refs:Dictionary=_lanes.get(String(lane.id),{})
		if refs.is_empty():continue
		_fill_lane(refs,lane)
		for slot:Dictionary in lane.slots:
			var card:Dictionary=_cards.get(String(slot.key),{})
			if not card.is_empty():_fill_card(card,slot.record,true)
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
		words.value=_times(ratio,true)
		words.words="the work of a typical people our age (%s learners; such a people keeps about %s)" % [_count(learners),_count(typical)]
	if proofs>0.0:
		words.proofs="At today's pace about %s question%s proven a year." % [_amount(proofs),"" if proofs<1.5 and proofs>=0.95 else "s"]
	elif learners>0.0:
		words.proofs="No question is near enough to proof to count a year."
	var limit:=limiter(pace)
	words.limiter=String(limit.text);words.limiter_tone=String(limit.tone)
	var chips:Array=[]
	# Learners: the people at it, their teams, and what the age can spare.
	var heads:=float(pace.get("heads",learners))
	var share:=learners/maxf(1.0,float(pace.get("able",1.0)))
	chips.append({"kind":"learners","icon":["people","learn"],"value":_count(learners),"label":"learners",
		"tone":"bad" if learners<=0.0 else "plain",
		"tip":"%s at learning (%s by head; the hurt count less, those away teaching and those tending the sick and the lenses not at all, a gifted scholar more). They work %d question%s at once, a team on each.\nA people our age can spare %d in 100 of its able as learners, about %s; we keep %d in 100. Every learner counts; ten times the learners do about 7.6 times the work." % [_count(learners),_count(heads),int(pace.get("teams",0)),"" if int(pace.get("teams",0))==1 else "s",roundi(float(pace.get("sustainable",0.0))*100.0),_count(typical),roundi(share*100.0)]})
	# Goods: what the learners use a day, and any shortfall.
	var need:=float(pace.get("goods_need",0.0))
	var cover:=float(pace.get("goods_cover",1.0))
	var given:=need*cover
	var short:=cover<0.995 and need>0.0
	chips.append({"kind":"goods","icon":["moment","hearth_count"],"value":("%s of %s a day" % [_amount(given),_amount(need)]) if short else "%s a day" % _amount(need),
		"label":"goods: %s short" % _amount(need-given) if short else "goods, all given","tone":"bad" if short else "plain",
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
static func _count(value:float)->String:
	return preload("res://scripts/hud/production_plain.gd").number(roundf(value))

func _plain_heading(parent:Node)->void:
	var heading:=HBoxContainer.new();heading.add_theme_constant_override("separation",8);parent.add_child(heading)
	var title:=T.make_label("WHAT IS BEING LEARNED",12,T.GOLD_TEXT);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
	_small_button(heading,"Discovery tree",data.get("on_tree"),"Explore known methods and their prerequisites")
	_small_button(heading,"Who does the work",data.get("on_work"),"How many people the local leaders set to learning")

func _pace_header(parent:Node,words:Dictionary)->void:
	var panel:=PanelContainer.new();panel.name="LearningPace";parent.add_child(panel)
	panel.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,T.GOLD,1,T.RADIUS_CARD,12))
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8);panel.add_child(box)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",8);box.add_child(top)
	var left:=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.add_theme_constant_override("separation",2);top.add_child(left)
	left.add_child(T.make_label("HOW FAST WE LEARN",12,T.GOLD_TEXT))
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);left.add_child(line)
	var value:=_voice(String(words.value),28);value.name="PaceValue";value.autowrap_mode=TextServer.AUTOWRAP_OFF;value.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(value)
	var said:=T.make_label(String(words.words),13,T.BODY);said.name="PaceWords";said.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;said.size_flags_horizontal=Control.SIZE_EXPAND_FILL;said.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(said)
	var proofs:=T.make_label(String(words.proofs),13,T.TEXT_SOFT);proofs.name="PaceProofs";left.add_child(proofs)
	var actions:=VBoxContainer.new();actions.add_theme_constant_override("separation",4);actions.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;top.add_child(actions)
	_small_button(actions,"Discovery tree",data.get("on_tree"),"Explore known methods and their prerequisites")
	_small_button(actions,"Who does the work",data.get("on_work"),"How many people the local leaders set to learning")
	# The single biggest limiter, named.
	var limit:=HBoxContainer.new();limit.name="Limiter";limit.add_theme_constant_override("separation",8);box.add_child(limit)
	var bar:=ColorRect.new();bar.custom_minimum_size=Vector2(3,0);limit.add_child(bar)
	var limit_text:=T.make_label("",13,T.INK);limit_text.name="LimiterText";limit_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;limit_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;limit.add_child(limit_text)
	# Every input, an icon with its value; its whole account on hover.
	chip_grid=GridContainer.new();chip_grid.name="Inputs";chip_grid.add_theme_constant_override("h_separation",6);chip_grid.add_theme_constant_override("v_separation",6);box.add_child(chip_grid)
	for chip:Dictionary in words.chips:_chip(chip_grid,chip)
	_header={"value":value,"words":said,"proofs":proofs,"bar":bar,"limiter":limit_text}
	_fill_header(words)

func _fill_header(words:Dictionary)->void:
	_put(_header.value,String(words.value))
	_put(_header.words,String(words.words))
	_put(_header.proofs,String(words.proofs))
	(_header.proofs as Label).visible=String(words.proofs)!=""
	var tone:=String(words.limiter_tone)
	var ink:Color=tone_color(tone) if tone!="plain" else T.INK
	_put(_header.limiter,("Held back most by: " if tone!="good" else "")+String(words.limiter),ink)
	(_header.bar as ColorRect).color=T.RED if tone=="bad" else (T.GREEN if tone=="good" else T.AMBER)
	for chip:Dictionary in words.chips:
		var refs:Dictionary=_chips.get(String(chip.kind),{})
		if not refs.is_empty():_fill_chip(refs,chip)

func _chip(parent:Node,chip:Dictionary)->void:
	var panel:=PanelContainer.new();panel.name="Input_"+String(chip.kind);panel.custom_minimum_size=Vector2(CHIP_WIDTH,0);panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",T.flat(T.TILE_BG,T.BORDER_SOFT,1,T.RADIUS_CONTROL,6));parent.add_child(panel)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(row)
	var icon:=TextureRect.new();icon.custom_minimum_size=Vector2(26,26);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.texture=_icon(chip.icon);row.add_child(icon)
	var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",0);text.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(text)
	var value:=_fixed(text,"",14,T.INK);value.name="Value"
	var label:=_fixed(text,"",12,T.TEXT_SOFT);label.name="Label"
	var refs:={"panel":panel,"value":value,"label":label}
	_chips[String(chip.kind)]=refs
	_fill_chip(refs,chip)

func _fill_chip(refs:Dictionary,chip:Dictionary)->void:
	var tone:=String(chip.get("tone","plain"))
	_put(refs.value,String(chip.value),T.RED_TEXT if tone=="bad" else (T.TEXT_SOFT if tone=="muted" else T.INK))
	_put(refs.label,String(chip.label),T.RED_TEXT if tone=="bad" else T.TEXT_SOFT)
	(refs.panel as Control).tooltip_text=String(chip.tip)

static func _icon(spec:Array)->Texture2D:
	var ink:=T.GOLD
	match String(spec[0]):
		"people":return Icons.people_texture(String(spec[1]),ink)
		"moment":return Icons.moment_texture(String(spec[1]),ink,56)
		"domain":return Icons.domain_texture(String(spec[1]),ink)
	return Icons.texture_for(String(spec[1]))

# --------------------------------------------------------------------------
# Lanes and cards
# --------------------------------------------------------------------------

## A field's lane: one line with its glyph, name, attention and waiting lines
## (with what they lack), then its questions two a row in their places.
func _lane(parent:Node,lane:Dictionary)->void:
	var id:=String(lane.id)
	var accent:=Visuals.color(id) if not id.is_empty() else T.MUTED
	var box:=VBoxContainer.new();box.name="Lane_"+(id if not id.is_empty() else "other");box.add_theme_constant_override("separation",4);parent.add_child(box)
	var head:=HBoxContainer.new();head.name="LaneHead";head.add_theme_constant_override("separation",6);box.add_child(head)
	var rule:=ColorRect.new();rule.color=accent;rule.custom_minimum_size=Vector2(3,22);head.add_child(rule)
	var glyph:=TextureRect.new();glyph.texture=Icons.domain_texture(id if not id.is_empty() else "knowledge",accent);glyph.custom_minimum_size=Vector2(22,22)
	glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;glyph.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(glyph)
	var field:Dictionary=lane.field
	var title:=T.make_label(String(lane.name).to_upper(),12,T.legible(accent));title.name="FieldLabel";title.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(title)
	var attention:=T.make_label("",12,T.BODY);attention.name="Attention";attention.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(attention)
	var wait:=_fixed(head,"",12,T.TEXT_SOFT);wait.name="Waiting";wait.size_flags_vertical=Control.SIZE_SHRINK_CENTER;wait.mouse_filter=Control.MOUSE_FILTER_STOP
	for material:String in lane.lacks:
		var icon:=TextureRect.new();icon.name="Lacks_"+material.validate_node_name();icon.texture=Icons.texture_for(material);icon.custom_minimum_size=Vector2(20,20)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		icon.tooltip_text="Lacks %s: a question here waits until we find and work it." % material.to_lower();head.add_child(icon)
	var refs:={"attention":attention,"waiting":wait,"title":title,"less":null}
	if not field.is_empty():
		refs.less=_small_button(head,"Less",field.get("on_less"),"Give one step of this field's attention to the others")
		_small_button(head,"More",field.get("on_more"),"Move one step of attention to this field")
		_small_button(head,"Open",field.get("on_open"),"What this field is for, what its knowledge does and what is being worked on")
	_lanes[id]=refs
	_fill_lane(refs,lane)
	if (lane.slots as Array).is_empty():return
	var grid:=GridContainer.new();grid.name="Cards";grid.columns=2;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);box.add_child(grid)
	lane_grids.append(grid)
	for slot:Dictionary in lane.slots:_question(grid,slot,accent)

func _fill_lane(refs:Dictionary,lane:Dictionary)->void:
	var field:Dictionary=lane.field
	var waiting:=_waiting_words(lane)
	if field.is_empty():
		_put(refs.attention,"")
	else:
		var share:=float(field.get("share",0.0))
		_put(refs.attention,"No attention" if share<=0.0 else "%d in 100 of our attention" % maxi(1,roundi(share*100.0)),T.TEXT_SOFT if share<=0.0 else T.BODY)
		(refs.title as Label).tooltip_text=String(field.get("goal","")).left(1).to_upper()+String(field.get("goal","")).substr(1)
		(refs.attention as Label).tooltip_text=_field_words(field)
		(refs.attention as Label).mouse_filter=Control.MOUSE_FILTER_STOP
		if refs.less!=null:(refs.less as Button).disabled=int(field.get("weight",0))<=0
	_put(refs.waiting,String(waiting.text),T.AMBER_TEXT if bool(waiting.lacking) else T.TEXT_SOFT)
	(refs.waiting as Label).tooltip_text=String(waiting.tip)

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
			"ahead":parts.append("%s: next question %d years ahead" % [line,roundi(float(info.get("years",0.0)))])
			_:
				var lacks:Array=info.get("lacks",[])
				if not lacks.is_empty():
					lacking=true
					parts.append("%s lacks %s" % [line," and ".join(PackedStringArray(lacks.map(func(m:Variant)->String:return String(m).to_lower())))])
				else:parts.append("%s needs earlier knowledge" % line)
		tips.append("%s: %s" % [line,String(info.get("reason",""))])
	var text:=" · ".join(parts)
	if (lane.slots as Array).is_empty() and parts.is_empty():text="Nothing being worked on" if not (lane.field as Dictionary).is_empty() else ""
	return {"text":text,"tip":"\n".join(tips),"lacking":lacking}

## One card per question, in its line's place: the painting in its progress
## arc; the question; who works it and its time to proof; what holds it back
## (or its step); and what it would bring and open. Its whole account on hover;
## a click opens its field.
func _question(parent:Node,slot:Dictionary,accent:Color)->void:
	var record:Dictionary=slot.record
	var panel:=PanelContainer.new();panel.name="Question_"+String(record.get("id","")).validate_node_name()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.custom_minimum_size=Vector2(0,CARD_HEIGHT)
	panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;parent.add_child(panel)
	var idle:=_card_style();var hover:=_card_style(true)
	panel.add_theme_stylebox_override("panel",idle)
	panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",hover))
	panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",idle))
	var refs:={"panel":panel,"id":""}
	panel.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and data.get("on_domain") is Callable:
			(data.on_domain as Callable).call(String(refs.get("domain","knowledge"))))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(row)
	var arc:=Arc.new();arc.custom_minimum_size=Vector2(ARC_SIZE,ARC_SIZE);arc.size_flags_vertical=Control.SIZE_SHRINK_CENTER;arc.accent=accent;row.add_child(arc)
	var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",0);text.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(text)
	var name_label:=_voice("",16);name_label.name="QuestionName";_clip(name_label);text.add_child(name_label)
	refs.arc=arc;refs.name=name_label
	refs.line=_fixed(text,"",12,T.BODY);refs.line.name="Team"
	refs.phase=_fixed(text,"",12,T.AMBER_TEXT);refs.phase.name="Holdup"
	refs.would=_fixed(text,"",12,T.TEXT_SOFT);refs.would.name="WouldBring"
	_cards[String(slot.key)]=refs
	_fill_card(refs,record,false)

func _fill_card(refs:Dictionary,record:Dictionary,animate:bool)->void:
	var words:=_card_words(record)
	var id:=String(record.get("id",""))
	if String(refs.id)!=id:
		# A new question on the line: its painting (or its field's glyph).
		refs.id=id
		var arc:Arc=refs.arc
		var painting:=Visuals.thumbnail_for(record,256) if has_painting(record) else null
		var domain:=String(record.get("dynamic",record.get("direction","")))
		arc.glyph=painting==null
		arc.focus=Visuals.focus_for(record)
		arc.texture=painting if painting!=null else Icons.domain_texture(domain if not domain.is_empty() else "knowledge",arc.accent)
		(refs.panel as Control).name="Question_"+id.validate_node_name()
		animate=false
	refs.domain=String(record.get("dynamic",record.get("direction","")))
	if (refs.domain as String).is_empty():refs.domain="knowledge"
	(refs.arc as Arc).held=String(words.phase)!="" and not String(record.get("bottleneck","")).begins_with("AHEAD OF ITS AGE")
	(refs.arc as Arc).set_value(float(words.progress),animate)
	_put(refs.name,String(record.get("name","An open question")))
	_put(refs.line,String(words.brief))
	_put(refs.phase,String(words.status),T.AMBER_TEXT if String(words.phase)!="" else T.INK)
	_put(refs.would,String(words.opens))
	(refs.panel as Control).tooltip_text=String(words.tooltip)

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
		"tooltip":String(record.get("name","An open question"))+"\n"+(goal+"\n\n" if not goal.is_empty() else "\n")+evidence+". "+gathered+"\n"+holdup+("\n\n"+founding if not founding.is_empty() else "")+brings+("\n\n"+opens_words+"." if opens>0 else "")+"\n\nClick to review this field, its current investigations and what they would do."}

## The price of the furthest lead among the questions under way, once teams
## work five years or more ahead of the age: "Our learning runs ahead of its
## age. 25 years ahead: six times the work." "" otherwise.
static func lead_price(records:Array)->String:
	var furthest:Dictionary={}
	for record:Dictionary in records:
		if float(record.get("years_ahead",0.0))>=5.0 and (furthest.is_empty() or float(record.years_ahead)>float(furthest.years_ahead)):furthest=record
	if furthest.is_empty():return ""
	return "Our learning runs ahead of its age. %s." % Words.lead_price(float(furthest.years_ahead),float(furthest.get("work_factor",1.0)))

func _empty(parent:Node)->void:
	var panel:=PanelContainer.new();panel.name="NothingUnderWay";parent.add_child(panel)
	panel.add_theme_stylebox_override("panel",_card_style())
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6);panel.add_child(box)
	box.add_child(_serif("The next question is still open",20))
	_note(box,"Learning needs people to do it, clues to follow and earlier knowledge. Open the discovery tree to choose a question, or ask your leader for more hands on learning.")
	_small_button(box,"Who does the work",data.get("on_work"),"How many people the local leaders set to learning")

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
func _choice_badge(card:PanelContainer,choice:Dictionary)->void:
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
# Small pieces
# --------------------------------------------------------------------------

func _card_style(hover:bool=false)->StyleBoxFlat:
	return T.flat(T.HOVER_BG if hover else T.ROW_BG,T.GOLD if hover else T.BORDER_SOFT,1,T.RADIUS_CARD,8)
## A one-line label whose words never change its size: too long, it ends in "…".
func _fixed(parent:Node,value:String,font:int,ink:Color)->Label:
	var label:=T.make_label(value,font,ink);_clip(label);parent.add_child(label);return label
static func _clip(label:Label)->void:
	label.autowrap_mode=TextServer.AUTOWRAP_OFF;label.clip_text=true;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.custom_minimum_size.x=1;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
func _small_button(parent:Node,label:String,callback:Variant,tip:String)->Button:
	var button:=_button(parent,label,callback,tip)
	button.custom_minimum_size.y=24;button.add_theme_font_size_override("font_size",12);button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	return button
func _arrange()->void:
	var wide:=size.x>=WIDE
	for grid:GridContainer in choice_grids:
		if is_instance_valid(grid):grid.columns=3 if wide else 1
	for grid:GridContainer in lane_grids:
		if is_instance_valid(grid):grid.columns=2 if size.x>=TWO_CARDS else 1
	if chip_grid:chip_grid.columns=clampi(floori((size.x-24.0+6.0)/(CHIP_WIDTH+6.0)),1,maxi(1,chip_grid.get_child_count()))
