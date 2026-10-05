extends RefCounted
## A calendar day as the player reads it: year and day of the year, never the
## raw count of days since the founding. "year 150, day 32"; `capital` gives
## "Year 150, day 32" for the start of a line. A negative day is unknown.
## Free of every other script, so the simulation and the screens alike may
## preload it. Static helpers.

static func words(day:int,capital:bool=false)->String:
	if day<0:return "an unknown day"
	return "%s %d, day %d" % ["Year" if capital else "year",day/365+1,posmod(day,365)+1]
