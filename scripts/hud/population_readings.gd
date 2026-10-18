extends RefCounted
## Read-only population reconciliation from dated realm snapshots and vital records.
## Arrivals/departures are not independently tracked; never invent that split.
const History=preload("res://scripts/strategic_history.gd")
static func balance(state)->Dictionary:
	var today:=int(state.elapsed_days)
	var out:={"current":int(state.population_total),"known":false,"vitals_known":false,"from_day":today,"to_day":today}
	for point:Dictionary in History.points(state.strategic_history,"civilization"):
		var day:=int(point.get("day",-1))
		if day<maxi(0,today-365) or day>=today or not point.has("population"):continue
		out.from_day=day;out.before=int(point.population);out.change=out.current-out.before;out.known=true;break
	if not out.known:return out
	var start:=int(state.vital_statistics_tracking_start_day)
	out.vitals_known=start>=0 and start<=int(out.from_day)+1 and not state.vital_statistics_history.is_empty()
	if not out.vitals_known:return out
	out.births=0;out.deaths=0
	for row:Dictionary in state.vital_statistics_history:
		if int(row.day)<=int(out.from_day) or int(row.day)>today:continue
		out.births+=int(row.get("births",0));out.deaths+=int(row.get("deaths",0))
	out.other=int(out.change)-int(out.births)+int(out.deaths)
	return out
static func cohorts(state)->Array:
	var rows:Array=[]
	if state.population_cohorts.is_empty() or not state.population_cohorts.has_all(state.POPULATION_AGE_COHORTS):return rows
	for id:String in state.POPULATION_AGE_COHORTS:
		var ages:Vector2=state.POPULATION_COHORT_AGE_RANGES[id]
		rows.append({"name":"%d–%d years" % [int(ages.x),int(ages.y)-1] if id!="elders" else "60+ years","value":"%.1f" % float(state.population_cohorts.get(id,0)),"ratio":float(state.population_cohorts.get(id,0))/maxf(1,float(state.population_total)),"tip":"Modeled cohort, not individual age records","color":preload("res://scripts/hud/hud_tokens.gd").TEAL})
	return rows
