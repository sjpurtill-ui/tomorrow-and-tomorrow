extends RefCounted
## Dates and spans for the outward reports. Dates are the shared EraWords
## phrase ("Year 12 · Summer", "last season"); this only adds how long
## something lasted ("12 days", "3 months"), never a raw day number.

const EraWords:=preload("res://scripts/hud/era_words.gd")

static func when(day:int)->String:
	return EraWords.when(day)

static func ago(day:int)->String:
	return EraWords.ago(day)

## "12 days", "3 weeks", "2 years": a span of time.
static func span(days:int)->String:
	days=maxi(0,days)
	if days<=1:return "a day"
	if days<14:return "%d days" % days
	if days<60:return "%d weeks" % roundi(days/7.0)
	if days<540:return "%d months" % roundi(days/30.4)
	return "%d years" % roundi(days/365.0)
