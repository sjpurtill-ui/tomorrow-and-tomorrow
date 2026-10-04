extends RefCounted
## Completed discoveries remain in the knowledge/history model, but leave the
## active candidate scan. Eligibility itself is never cached: resources, imports,
## practice and prerequisite groups are still evaluated against current state.
var known_snapshot:Array=[]
var known:Dictionary={}
var channels:Dictionary={}
var sources:Dictionary={}
var source_sizes:Dictionary={}
func candidates(channel:String,definitions:Array,known_ids:Array)->Array:
	if known_snapshot!=known_ids:
		known_snapshot=known_ids.duplicate()
		known.clear()
		for id in known_ids:known[id]=true
		# Each channel is read again; a list whose questions are all unchanged
		# is kept as the same Array, so what callers keep by it stays good.
		stale=channels;channels={};sources.clear();source_sizes.clear()
	if not channels.has(channel) or not is_same(sources.get(channel),definitions) or int(source_sizes.get(channel,-1))!=definitions.size():
		var pending:Array=[]
		for definition:Dictionary in definitions:
			if not known.has(String(definition.get("id",""))):pending.append(definition)
		var previous:Variant=stale.get(channel)
		if previous is Array and _same_items(previous,pending):pending=previous
		channels[channel]=pending
		sources[channel]=definitions
		source_sizes[channel]=definitions.size()
	return channels[channel]

## The lists before the known discoveries last changed.
var stale:Dictionary={}

static func _same_items(first:Array,second:Array)->bool:
	if first.size()!=second.size():return false
	for index in first.size():
		if not is_same(first[index],second[index]):return false
	return true
