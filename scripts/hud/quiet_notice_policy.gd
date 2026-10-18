extends RefCounted
## Presentation only. Quiet events remain in the saved Chronicle and ledgers.
## Legacy saves may request "all" research announcements; that setting no
## longer makes routine discoveries interrupt play.
const EXECUTION_TITLES:=["Put to Death","Officeholder Executed","Leader Executed"]

static func execution(entry:Dictionary)->bool:
	if String(entry.get("source",""))=="execution":return true
	# The ledger key retains the original event title even after retelling.
	var key:=String(entry.get("key",""))
	var title:=key.get_slice("|",2) if key.begins_with("ev|") else String(entry.get("title",""))
	return title in EXECUTION_TITLES

static func quiet(entry:Dictionary)->bool:
	var key:=String(entry.get("key",""))
	var kind:=String(entry.get("kind",""))
	if String(entry.get("category",""))=="learning" or kind=="discovery" or key.begins_with("discovery:") or key.begins_with("learned:"):return true
	if execution(entry):return false
	return kind=="death" or key.begins_with("court:death:")
