extends "res://scripts/hud/content/dock_content_base.gd"
## The Chronicle rail entry: one readable feed of what has happened to the
## people. Tab one holds moments and notices; tab two adds the seasons' tallies.
const Chronicle:=preload("res://scripts/chronicle.gd")

func meta()->Dictionary:
	var voice:=Chronicle.voice()
	return {"eyebrow":"THE STORY OF THE PEOPLE","title":String(voice.feed),"subtabs":["THE STORY","EVERY SEASON"]}

func tab(sub:int)->Dictionary:
	var voice:=Chronicle.voice()
	var entries:=Chronicle.entries("notice" if sub==0 else "whisper")
	var moments:=0
	for e in entries:
		if String((e as Dictionary).get("tier",""))=="moment":moments+=1
	var told:=[{"label":"MOMENTS","value":str(moments),"note":"Remembered with a card"},{"label":"TOLD","value":str(entries.size()),"note":"Entries in this view"}]
	return {"blocks":[{"type":"tiles","columns":2,"items":told},{"type":"chronicle_feed","entries":entries,"voice":voice}]}

func signature()->Array:
	var entries:Array=GameState.chronicle.get("entries",[])
	return [entries.size(),String((entries[0] as Dictionary).get("key","")) if not entries.is_empty() else "",GameState.known_discoveries.size()]
