extends RefCounted
## THE WAY BETWEEN TWO PEOPLES: one rule for everyone a people sends to
## another: envoys, eyes, teachers, households, raiders, gifts and the hands
## that carry them. Ours and every ruler's alike.
##
## The pair's way is the one the traders use (trade_ledger.way, surveyed once
## on the real land with the armies' planner):
##   - a land road between their homes, or a way round by land through
##     peoples who know each other: everyone sent arrives;
##   - no land road: they go in the SENDER'S boats, and of those who put out
##         0.5 ^ ((km in sight of a coast x 0.2 + km out of sight of land) / the sender's sea endurance)
##     come through (expedition.gd's endurance, trade_ledger.sea_home's
##     rule). Nobody is sent at worse than LEAST: the way is shut;
##   - a sender with no boats fit for the sea sends nobody over it.
## Until a pair's way is surveyed (a day each, once a campaign) there is no
## rule yet and the way counts as open.
##
## Who came through is settled by a seeded roll (arrives), so a load never
## rerolls it. Static; preload.

const Trade:=preload("res://scripts/trade_ledger.gd")

## Nobody puts out at worse than this (the traders' own floor).
const LEAST:=Trade.SEA_LEAST_HOME

## The way from `from` to `to`: {kind ("land", "sea", "" not surveyed),
## share (of those sent who arrive, 0..1), open (anyone is sent at all),
## open_km, coast_km, endurance (the sender's, km; -1 not read)}.
static func between(from:String,to:String)->Dictionary:
	var a:=Trade.owner_of(from); var b:=Trade.owner_of(to)
	var out:={"kind":"","share":1.0,"open":true,"open_km":0.0,"coast_km":0.0,"endurance":-1.0}
	if a==b: return out
	var w:Dictionary=Trade.way(a,b)
	out.kind=String(w.kind)
	if out.kind!="sea": return out
	out.open_km=float(w.open); out.coast_km=float(w.coast)
	# The long way round by land, hand to hand through peoples who know each other.
	if is_finite(float(w.around)):
		out.kind="land"
		return out
	var endurance:=float(Trade.report(a).get("end",-1.0))
	out.endurance=endurance
	if endurance<0.0: return out
	var share:=0.0 if endurance<=0.0 else clampf(pow(0.5,(float(w.coast)*Trade.SEA_COAST_WEIGHT+float(w.open))/endurance),0.0,1.0)
	out.share=share if share>=LEAST else 0.0
	out.open=share>=LEAST
	return out

## Whether `from` sends anyone to `to` at all.
static func open(from:String,to:String)->bool:
	return bool(between(from,to).open)

## Of those `from` sends to `to`, the share who arrive (0 when the way is shut).
static func share(from:String,to:String)->float:
	return float(between(from,to).share)

## Whether one party sent from `from` to `to` came through: by land always,
## by sea a roll at the crossing's share, seeded from the world, the pair,
## `what` and `day`.
static func arrives(from:String,to:String,what:String,day:int)->bool:
	var w:=between(from,to)
	if not bool(w.open): return false
	if float(w.share)>=1.0: return true
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|passage|%s|%s|%s|%d" % [int(GameState.world_seed),Trade.owner_of(from),Trade.owner_of(to),what,day])
	return rng.randf()<float(w.share)

## The way in the engine's numbers, for a page or the court: "" by land or
## before the way is surveyed.
static func words(from:String,to:String)->String:
	var w:=between(from,to)
	if String(w.kind)!="sea": return ""
	var water:=roundi(float(w.open_km)+float(w.coast_km))
	if float(w.endurance)==0.0: return "There is no land road between us and %d km of water, %d of it out of sight of land; the boats are not fit for the sea, so nobody crosses." % [water,roundi(float(w.open_km))]
	if not bool(w.open): return "There is no land road between us and %d km of water, %d of it out of sight of land: too wide for the boats, so nobody crosses (nobody is sent at worse than %d in 100)." % [water,roundi(float(w.open_km)),roundi(LEAST*100.0)]
	return "There is no land road between us: the way is %d km of water, %d of it out of sight of land, and about %d in 100 of those sent come through." % [water,roundi(float(w.open_km)),roundi(float(w.share)*100.0)]
