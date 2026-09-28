extends RefCounted
## Where the plan reckons a scout party to be along its route, as a fraction
## of the route: 0 at home, 1 at the route's far end. One rule for the map's
## walker glyph (scout_chart_walker.gd) and for the watchers' reckoning
## (city_intelligence.mission_position), so they never disagree.
##
## A circuit is a loop that comes home the other way round: it is walked once,
## 0 to 1. Any other route goes out, may wait at its goal, and comes home the
## same way (0 to 1, a stay at 1, then back to 0). A party turning back early
## has had its route cut to where it turned and returns along it.

static func fraction(mission:Dictionary,day:float)->float:
	var start:=float(mission.get("start_day",day))
	var end:=float(mission.get("actual_return_day",mission.get("return_day",start+1.0)))
	var total:=maxf(1.0,end-start)
	var elapsed:=clampf(day-start,0.0,total)
	var turning_back:=String(mission.get("route_status",""))=="turning_back"
	if bool(mission.get("circuit",false)) and not turning_back: return elapsed/total
	var leg:=clampf(float(mission.get("travel_leg_days",total*0.5)),0.5,total*0.5)
	if turning_back: leg=total*0.5
	if elapsed<leg: return elapsed/leg
	if elapsed<=total-leg: return 1.0
	return (total-elapsed)/leg
