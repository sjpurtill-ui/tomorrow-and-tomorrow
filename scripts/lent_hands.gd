extends RefCounted
## Hands lent abroad on an envoy's business: a teacher of a craft, healers in
## a sick people's camps, hunters on a great drive (envoy_requests.gd). They
## are away from our work until they come home, so a deal that sends them
## costs what it says it costs (envoy_deals.gd prices them at a day of our
## output a head each).
##
## The record lives with the envoy business (AudienceHall.state()
## .envoy_requests.lent = [{n, until, why}]); this reader touches nothing
## else, so the work-day count (game_state.gd civilian_workforce_fraction)
## can ask it cheaply, many times a day, for the god's own people only.

## How many of the god's people are away on lent work on `day`.
static func away(day:int)->float:
	var e:Variant=ForeignDiplomacy.audiences.get("envoy_requests")
	if not e is Dictionary: return 0.0
	var lent:Variant=(e as Dictionary).get("lent")
	if not lent is Array: return 0.0
	var n:=0.0
	for entry in lent:
		if entry is Dictionary and int((entry as Dictionary).get("until",0))>day: n+=maxf(0.0,float((entry as Dictionary).get("n",0)))
	return n
