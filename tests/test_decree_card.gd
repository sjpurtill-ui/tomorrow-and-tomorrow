extends GdUnitTestSuite
## THE DECREE CARD (hud/decree_card.gd, hud/audience_modal.gd): what the god
## decreed and what it does, in the engine's numbers, stays on the stage long
## enough to read. Before, the RECEIPT was a stage caption the next speech
## bubble dropped at once.
## - a RECEIPT line reads in plain words, every number the engine's own;
## - the card stays open for its reading time, longer under the pointer, then
##   folds to a seal that opens it again;
## - in the court a law, a granted petition and a receipt each raise the card,
##   and a receipt is never a stage caption.
## Offline; never calls a real API.

const Harness:=preload("res://tests/court_eval/harness.gd")
const DecreeCard:=preload("res://scripts/hud/decree_card.gd")

## A real receipt from the user's campaign (Ashleyfire, Year 97).
const REAL:="labor efficiency -0.009 · material capacity +0.029 · 120 days · building pace +0.033 · 334 food spent · 57.6 materials spent · 30 days"

var h:Harness


func before()->void:
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_READER_MODEL"]: OS.unset_environment(key)
	h=Harness.new(self)


func after()->void:
	GameState.elapsed_days=0


func _texts(rows:Array)->Array:
	return rows.map(func(r)->String:return String((r as Dictionary).text))


func test_a_receipt_reads_in_plain_words()->void:
	var parsed:=DecreeCard.parse_receipt(REAL)
	var texts:=_texts(parsed.rows)
	assert_array(texts).contains(["Work done −0.9%","Materials at hand +2.9 pts","Building pace +3.3%","334 food from the stores","57.6 materials from the stores"])
	assert_int(int(parsed.days)).is_equal(120)
	assert_array(parsed.notes).is_empty()
	var tones:={}
	for row:Dictionary in parsed.rows:tones[String(row.text)]=String(row.tone)
	assert_str(String(tones["Work done −0.9%"])).is_equal("cost")
	assert_str(String(tones["Building pace +3.3%"])).is_equal("gain")
	assert_str(String(tones["334 food from the stores"])).is_equal("cost")


func test_words_it_cannot_read_are_kept_as_they_are()->void:
	var parsed:=DecreeCard.parse_receipt("health now +1.2 pts · sickness down · This verifies the action only; productivity is not guaranteed. · 2 dead")
	var texts:=_texts(parsed.rows)
	assert_array(texts).contains(["Health now +1.2 pts","Sickness fall","2 dead"])
	assert_array(parsed.notes).contains(["This verifies the action only; productivity is not guaranteed."])


func test_the_card_stays_to_be_read_then_folds_to_a_seal()->void:
	var card:=DecreeCard.new()
	card.setup({"kind":"receipt","title":"Build shelters and repair the houses before winter","who":"Nanchaki Neni","place":"Ashleyfire","receipt":REAL,"day":35400})
	add_child(card)
	await await_idle_frame()
	assert_object(card.find_child("DecreeTitle",true,false)).is_not_null()
	assert_int((card.find_child("DecreeEffects",true,false) as Node).get_child_count()).is_equal(5)
	assert_str((card.find_child("DecreeBy",true,false) as Label).text).contains("Nanchaki Neni carries it out in Ashleyfire")
	assert_str((card.find_child("DecreeBy",true,false) as Label).text).contains("runs 4 moons")
	card._process(DecreeCard.HOLD_MIN-1.0)
	assert_bool(card.folded).is_false()
	# Under the pointer it never folds.
	card._hover=true
	card._process(60.0)
	assert_bool(card.folded).is_false()
	card._hover=false
	card._process(DecreeCard.HOLD_MAX)
	assert_bool(card.folded).is_true()
	var chip:=card.find_child("DecreeChip",true,false) as Button
	assert_object(chip).is_not_null()
	assert_str(chip.text).contains("Build shelters")
	chip.pressed.emit()
	assert_bool(card.folded).is_false()
	assert_object(card.find_child("DecreeTitle",true,false)).is_not_null()
	card.queue_free()


func test_in_the_court_a_law_and_its_receipt_raise_the_card_never_a_caption()->void:
	var w:=h.fx.use("home_peace")
	assert_bool(w.has("error")).is_false()
	GameState.civic_api_enabled=false
	var voice:=Harness.RecordingVoice.new()
	voice.force_offline=true
	add_child(voice)
	var id:=h.fx.audience_for(w,"suri")
	assert_str(id).is_not_empty()
	var modal:Control=Harness.Modal.new()
	modal.voice=voice; modal.audience_id=id
	add_child(modal)
	await await_idle_frame()
	voice.drain(id)
	modal._build_options()
	var heard:Dictionary=modal.office_order("From today every family must keep a store of grain for the winter.")
	assert_bool(bool(heard.get("law",false))).is_true()
	var card:Control=modal.decree_card
	assert_object(card).is_not_null()
	assert_str((card.find_child("DecreeTitle",true,false) as Label).text).contains("every family must keep a store of grain")
	assert_str((card.find_child("DecreeKicker",true,false) as Label).text).starts_with("MADE LAW")
	# The measured result comes back as a receipt line: the card, not a caption.
	modal.skip_reveal()
	preload("res://scripts/audience_hall.gd").append_line(id,{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":"RECEIPT · "+REAL,"day":int(GameState.elapsed_days),"aside":false})
	modal.revealing=false
	modal._pump()
	await await_idle_frame()
	var after:Control=modal.decree_card
	assert_object(after).is_not_null()
	assert_bool(after!=card).is_true()
	assert_str((after.find_child("DecreeTitle",true,false) as Label).text).contains("every family must keep a store of grain")
	assert_int((after.find_child("DecreeEffects",true,false) as Node).get_child_count()).is_equal(5)
	for node in modal.find_children("*","",true,false):
		assert_str(String(node.get_meta("caption_kind",""))).is_not_equal("receipt")
	# Kept in Earlier, in the same plain words.
	assert_object(modal.find_child("DecreeRecord",true,false)).is_not_null()
	modal.queue_free(); voice.queue_free()
