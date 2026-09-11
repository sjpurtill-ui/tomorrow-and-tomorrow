extends VBoxContainer
const Purchase=preload("res://scripts/research_purchase.gd")
var subject:=""
var sources:OptionButton
var resources:OptionButton
var summary:Label
var send:Button

func _ready()->void:
	var title:=Label.new();title.text="Purchase a validated study";add_child(title)
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
		var result:=Purchase.dispatch(String(sources.get_selected_metadata()),subject,resources.get_item_text(resources.selected))
		summary.text=String(result.get("message",result.get("error","The proposal could not depart.")))
		send.disabled=result.get("ok",false))
	refresh()

func refresh()->void:
	if sources.item_count==0:summary.text="A located foreign settlement and direct contact are needed.";send.disabled=true;return
	var terms:=Purchase.quote(String(sources.get_selected_metadata()),subject,resources.get_item_text(resources.selected))
	summary.text=String(terms.get("message",terms.get("error","No proposal available.")))
	send.disabled=terms.has("error")
