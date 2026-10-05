extends RefCounted
## OUR NATION'S NAME ON PAPER (nation_name.gd holds the name and its rules).
##
##   add_field  the line under the settlement's name on its naming card while
##              our people have no name: "And our people", a line to type in,
##              and the names heard among the people as chips that fill it.
##              Left empty, nothing is named; nothing nags in between.
## Between foundings the nation is named or renamed in the court ("call our
## nation the Reedfolk", or the Headman's "Name our nation" choices).
## Static helpers; preload.

const Kit:=preload("res://scripts/hud/paper_kit.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const NationName:=preload("res://scripts/nation_name.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")


## The words on a founding's naming card above the two names.
static func founding_words()->String:
	return "Our people now live in %s %s. Name the new %s, and if you wish, all our %s together: the name other peoples will know us by. Leave it empty to decide at the next founding." % [EraWords.count_word(NationName.towns()),EraWords.word("places","towns"),EraWords.word("place","town"),EraWords.word("places","towns")]


## The founding card's kicker, title and words, for the town just founded.
static func founding_heading(column:VBoxContainer,town:String)->void:
	Kit.label(column,"A new %s" % EraWords.word("place","town"),"kicker")
	Kit.label(column,"Name %s, and our nation" % town,"title")
	Kit.label(column,founding_words(),"body").custom_minimum_size.x=460


## "And our people", its line and the names heard among the people, added
## to a naming card's column. Returns the line.
static func add_field(column:VBoxContainer,prefill:String="")->LineEdit:
	Kit.label(column,"And our people","heading")
	var input:=_line(column,prefill)
	# Why a name could not be given stays on the card, under the names heard.
	var status:=Kit.label(column,"","note")
	status.name="NationNameStatus"
	input.set_meta("status",status)
	return input


## The founding card's commit: names the nation from the line when it holds
## a name. town: the town just founded. {} when the line is empty (skipped);
## a refusal's reason is shown on the card.
static func commit_founding(input:LineEdit,town:String)->Dictionary:
	if input==null or not is_instance_valid(input) or NationName.tidy(input.text)=="": return {}
	var done:=NationName.give_name(input.text,String(input.get_meta("how","founding")),town)
	if bool(done.get("ok",false)): done["line"]="Our people are now called %s." % NationName.in_sentence(String(done.name))
	var status:Variant=input.get_meta("status",null)
	if not bool(done.get("ok",false)) and is_instance_valid(status) and status is Label: (status as Label).text=String(done.get("reason",""))
	return done


static func _line(column:VBoxContainer,prefill:String)->LineEdit:
	var input:=LineEdit.new()
	input.name="NationName"
	input.placeholder_text="What we call ourselves"
	input.max_length=NationName.MAX_LENGTH
	input.text=prefill
	input.custom_minimum_size=Vector2(0,44)
	input.add_theme_font_size_override("font_size",18)
	column.add_child(input)
	var heard:=NationName.suggestions(5)
	if heard.is_empty(): return input
	var row:=HFlowContainer.new()
	row.name="NationNameSuggestions"
	row.add_theme_constant_override("h_separation",8)
	row.add_theme_constant_override("v_separation",4)
	column.add_child(row)
	Kit.label(row,"Heard among the people:","note",Color(0,0,0,0),false)
	for heard_name in heard:
		var chosen:=String(heard_name)
		var pick:=func()->void:
			input.text=chosen
			input.text_changed.emit(chosen)
			if input.is_inside_tree(): input.grab_focus()
		Kit.quiet_button(row,chosen,pick,"Use this name").name="Suggestion"
	return input
