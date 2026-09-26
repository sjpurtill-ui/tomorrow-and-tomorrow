extends "res://scripts/hud/content/dock_content_base.gd"
## The Chronicle rail entry: one readable feed of what has happened to the
## people. It tells the story (moments and notices); one labelled checkbox in
## the feed adds every season's tally. No tabs, no counting tiles.
const Chronicle:=preload("res://scripts/chronicle.gd")

func meta()->Dictionary:
	var voice:=Chronicle.voice()
	return {"eyebrow":"THE STORY OF THE PEOPLE","title":String(voice.feed),"subtabs":[]}

func tab(_sub:int)->Dictionary:
	return {"blocks":[{"type":"chronicle_feed","entries":Chronicle.entries("whisper"),"voice":Chronicle.voice()}]}

func signature()->Array:
	var entries:Array=GameState.chronicle.get("entries",[])
	return [entries.size(),String((entries[0] as Dictionary).get("key","")) if not entries.is_empty() else "",GameState.known_discoveries.size()]
