extends "res://scripts/hud/content/dock_content_base.gd"
## THE EYES: our eyes among other peoples and the wary at home, on a page of
## their own (rail F3). The hidden folio (covert_board.gd) is the whole page:
## how many of each serve and learn, buttons to set how many are taught, an
## errand among each people we know with its odds, and what came back.
## The rail and the title speak the age's word (eyes_corps.gd): Eyes at the
## hearth, Watchers once the people writes, Spies in a reckoned age.

const Corps:=preload("res://scripts/eyes_corps.gd")

func meta()->Dictionary:
	return {"eyebrow":"Among other peoples, and theirs among us","title":Corps.word("Eyes"),"subtabs":[Corps.word("Eyes")]}

func tab(_sub:int)->Dictionary:
	return {"brief":{},"blocks":[{"type":"eyes"}]}

## The board refreshes itself; the page rebuilds only when the age's words change.
func signature()->Array:
	return [Corps.stage()]
