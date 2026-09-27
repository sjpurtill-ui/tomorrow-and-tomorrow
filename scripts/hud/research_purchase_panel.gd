extends VBoxContainer
## Help from abroad with one question: a licence, a finished study, a visiting
## scholar, a joint study or trial materials. This is not a form. The atlas
## shows, in one sentence, the best help a known people could give, and one
## link that opens the court on that people: every dealing with a foreign
## people happens in the court (one-court-screen).
##
## The static offers()/send() API is what the court's envoy conversation calls
## to carry the request; it quotes and dispatches through the same live
## actions the old form used.
const T=preload("res://scripts/hud/hud_tokens.gd")
const Licenses=preload("res://scripts/research_licenses.gd")
const Purchase=preload("res://scripts/research_purchase.gd")
const Partnerships=preload("res://scripts/research_partnerships.gd")
const Materials=preload("res://scripts/research_materials.gd")
const Scholars=preload("res://scripts/scholar_visits.gd")
const PAYMENTS:=["Food","Timber","Fiber Plants","Clay","Stone"]
const MODE_WORDS:={
	"license":"let us make it under their licence for a year",
	"purchase":"sell us a finished study of it",
	"scholar":"send a scholar to teach us for about two months",
	"partnership":"study it with us and share what they find",
	"materials":"sell us the materials we need to try it",
}
var subject:=""
var summary:Label
var ask:Button
var offer:Dictionary={}

static func visible_for(topic:String, exposed:bool, known:bool)->bool:
	if not exposed:return false
	var license_needed:=Licenses.available() and topic in Licenses.subjects() and not Licenses.independent(topic)
	if license_needed:return true
	if known and not Partnerships.pending(topic) and not (topic=="size_exclusion_chromatography" and Materials.available(topic)):return false
	return Purchase.available() or Scholars.available() or Partnerships.available() or Materials.available(topic)

## The kinds of help open for this question, in the order they are offered.
static func modes(topic:String)->Array[String]:
	var result:Array[String]=[]
	if Licenses.available() and topic in Licenses.subjects():result.append("license")
	if Purchase.available():result.append("purchase")
	if Scholars.available():result.append("scholar")
	if Partnerships.available():result.append("partnership")
	if Materials.available(topic):result.append("materials")
	return result

static func module(mode:String)->Script:
	match mode:
		"license":return Licenses
		"materials":return Materials
		"scholar":return Scholars
		"partnership":return Partnerships
	return Purchase

## Peoples we know well enough to ask (direct contact).
static func contacts()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if int(civ.get("player_relation",{}).get("contact_level",0))>=2:result.append({"id":String(civ.id),"name":String(civ.name)})
	return result

## Every help a known people could give now, with its real quote.
static func offers(topic:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for mode:String in modes(topic):
		for civ:Dictionary in contacts():
			for payment:String in PAYMENTS:
				var terms:Dictionary=module(mode).quote(String(civ.id),topic,payment)
				if terms.has("error"):continue
				result.append({"mode":mode,"civ_id":civ.id,"civ_name":civ.name,"payment":payment,"message":String(terms.get("message",""))})
				break
	return result

## Sends the request through the live action; the court calls this.
static func send(mode:String,civ_id:String,topic:String,payment:String)->Dictionary:
	return module(mode).dispatch(civ_id,topic,payment)

func _ready()->void:
	name="HelpFromAbroad";add_theme_constant_override("separation",6)
	var kicker:=T.make_label("HELP FROM ABROAD",12,T.GOLD_TEXT);add_child(kicker)
	summary=T.make_label("",13,T.BODY);summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(summary)
	ask=Button.new();ask.name="AskInCourt";ask.text="Ask them in court";ask.add_theme_font_size_override("font_size",13);add_child(ask)
	ask.pressed.connect(func()->void:load("res://scripts/audience_director.gd").open_court_for({"civ_id":String(offer.get("civ_id",""))}))
	refresh()

func refresh()->void:
	var found:Array=offers(subject) if not subject.is_empty() else []
	offer=found[0] if not found.is_empty() else {}
	if offer.is_empty():
		summary.text="None of the peoples we know well can help with this yet. We need direct contact with a people who knows it."
		ask.disabled=true;return
	summary.text="%s could %s. Send your envoy to ask in the court." % [String(offer.civ_name),String(MODE_WORDS.get(String(offer.mode),"help us"))]
	if found.size()>1:summary.text+=" %d other kinds of help are possible." % (found.size()-1)
	ask.disabled=false
	ask.tooltip_text=String(offer.message)
