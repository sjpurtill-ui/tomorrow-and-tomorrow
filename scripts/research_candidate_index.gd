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
		channels.clear();sources.clear();source_sizes.clear()
	if not channels.has(channel) or not is_same(sources.get(channel),definitions) or int(source_sizes.get(channel,-1))!=definitions.size():
		var pending:Array=[]
		for definition:Dictionary in definitions:
			if not known.has(String(definition.get("id",""))):pending.append(definition)
		channels[channel]=pending
		sources[channel]=definitions
		source_sizes[channel]=definitions.size()
	return channels[channel]
