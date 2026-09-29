extends "res://scripts/hud/content/dock_content_base.gd"
## The Chronicle rail entry: the story of the people as a count of years
## (hud/chronicle_feed.gd): a mark for every year on a spiral from the
## founding, the chosen year's facts and moments as pictures, and the years
## one line each. The tellings are one choice away; one labelled checkbox adds
## every season's tally. No tabs.
const Chronicle:=preload("res://scripts/chronicle.gd")
const Years:=preload("res://scripts/hud/chronicle_year_model.gd")

func meta()->Dictionary:
	var voice:=Chronicle.voice()
	return {"eyebrow":"THE STORY OF THE PEOPLE","title":String(voice.feed),"subtabs":[]}

func tab(_sub:int)->Dictionary:
	var today:=int(GameState.elapsed_days)
	return {"blocks":[{"type":"chronicle_feed","entries":Chronicle.entries("whisper"),"voice":Chronicle.voice(),
		"years":Years.build(Chronicle.data(),today,int(GameState.population_total)),"today":today}]}

func signature()->Array:
	var entries:Array=GameState.chronicle.get("entries",[])
	var annals:Array=GameState.chronicle.get("annals",[]) if GameState.chronicle.get("annals") is Array else []
	return [entries.size(),String((entries[0] as Dictionary).get("key","")) if not entries.is_empty() else "",GameState.known_discoveries.size(),annals.size(),int(GameState.elapsed_days)/365]
