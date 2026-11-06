extends RefCounted
## A short founding respite, then shared military pressure in the first chapter.
## Reachability, treaties, relative strength and actual forces still govern action.

const QUIET_YEARS:=2.0
const RAMP_YEARS:=8.0
## At full pressure and an even lean, comings a year against one neighbour.
const PER_YEAR:=0.10
## A ruler's peace-time watch at full pressure, against the quiet age's.
const WATCH_GAIN:=0.5
## How much sooner a ruler takes offence at full pressure (points of opinion).
const OFFENCE_GAIN:=0.35

static func at_year(year:float)->float:
	return clampf((year-QUIET_YEARS)/RAMP_YEARS,0.0,1.0)

static func now()->float:
	return at_year(float(WorldSimulation.state.elapsed_days)/365.0) if WorldSimulation.state!=null else 0.0

static func quiet()->bool:
	return now()<=0.0

## "until year 300" / "since year 300, at 4 parts in 10 of its full weight".
static func words()->String:
	var p:=now()
	if p<=0.0: return "No people comes against another unprovoked before year %d." % int(QUIET_YEARS)
	if p>=1.0: return "Since year %d the peoples press on one another at full weight." % int(QUIET_YEARS+RAMP_YEARS)
	return "Since year %d the peoples press on one another: now at %d parts in 10 of the full weight, reached in year %d." % [int(QUIET_YEARS),roundi(p*10.0),int(QUIET_YEARS+RAMP_YEARS)]
