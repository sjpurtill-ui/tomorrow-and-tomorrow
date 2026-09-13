extends VBoxContainer
const Licenses=preload("res://scripts/research_licenses.gd")
const Purchase=preload("res://scripts/research_purchase.gd")
const Partnerships=preload("res://scripts/research_partnerships.gd")
const Materials=preload("res://scripts/research_materials.gd")
const Scholars=preload("res://scripts/scholar_visits.gd")
var modes:OptionButton
var subject:=""
var sources:OptionButton
var resources:OptionButton
var summary:Label
var send:Button

static func visible_for(topic:String, exposed:bool, known:bool)->bool:
	if not exposed:return false
	var license_needed:=Licenses.available() and topic in Licenses.subjects() and not Licenses.independent(topic)
	if license_needed:return true
	if known and not Partnerships.pending(topic) and not (topic=="size_exclusion_chromatography" and Materials.available(topic)):return false
	return Purchase.available() or Scholars.available() or Partnerships.available() or Materials.available(topic)

func _ready()->void:
	var title:=Label.new();title.text="Arrange foreign research support";add_child(title)
	modes=OptionButton.new();add_child(modes)
	if Licenses.available() and subject in Licenses.subjects():modes.add_item("Negotiate one-year production license");modes.set_item_metadata(modes.item_count-1,"license")
	if Purchase.available():modes.add_item("Purchase a validated study");modes.set_item_metadata(modes.item_count-1,"purchase")
	if Scholars.available():modes.add_item("Invite a scholar for 60 days");modes.set_item_metadata(modes.item_count-1,"scholar")
	if Partnerships.available():modes.add_item("Joint investigation and findings exchange");modes.set_item_metadata(modes.item_count-1,"partnership")
	if Materials.available(subject):modes.add_item("Purchase experimental materials");modes.set_item_metadata(modes.item_count-1,"materials")
	modes.item_selected.connect(func(_index:int)->void:refresh())
	sources=OptionButton.new();sources.size_flags_horizontal=SIZE_EXPAND_FILL;sources.clip_text=true;add_child(sources)
	for civ:Dictionary in WorldSimulation.world.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		if int(relation.get("contact_level",0))<2:continue
		sources.add_item(String(civ.name));sources.set_item_metadata(sources.item_count-1,String(civ.id))
	resources=OptionButton.new();resources.size_flags_horizontal=SIZE_EXPAND_FILL;add_child(resources)
	for resource:String in ["Food","Timber","Fiber Plants","Clay","Stone"]:resources.add_item(resource)
	summary=Label.new();summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;summary.add_theme_font_size_override("font_size",12);add_child(summary)
	send=Button.new();send.text="Send research proposal";add_child(send)
	sources.item_selected.connect(func(_index:int)->void:refresh())
	resources.item_selected.connect(func(_index:int)->void:refresh())
	send.pressed.connect(func()->void:
		var result:Dictionary=support().dispatch(String(sources.get_selected_metadata()),subject,resources.get_item_text(resources.selected))
		summary.text=String(result.get("message",result.get("error","The proposal could not depart.")))
		send.disabled=result.get("ok",false))
	refresh()

func refresh()->void:
	if sources.item_count==0 or modes.item_count==0:summary.text="A located foreign settlement and direct contact are needed.";send.disabled=true;return
	var terms:Dictionary=support().quote(String(sources.get_selected_metadata()),subject,resources.get_item_text(resources.selected))
	summary.text=String(terms.get("message",terms.get("error","No proposal available.")))
	send.disabled=terms.has("error")

func support()->Script:
	match modes.get_selected_metadata():
		"license":return Licenses
		"materials":return Materials
		"scholar":return Scholars
		"partnership":return Partnerships
	return Purchase
