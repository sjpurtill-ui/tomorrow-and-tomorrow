extends RefCounted
## Completed discoveries remain in the knowledge/history model, but leave the
## active candidate scan. Eligibility itself is never cached: resources, imports,
## practice and prerequisite groups are still evaluated against current state.
var known_snapshot:Array=[]
var known:Dictionary={}
var channels:Dictionary={}
var sources:Dictionary={}
var source_sizes:Dictionary={}
## The ids of each channel's open list, as a set.
var channel_ids:Dictionary={}
func candidates(channel:String,definitions:Array,known_ids:Array)->Array:
	if known_snapshot!=known_ids:
		var before:=known_snapshot.size()
		var grown:=known_ids.size()>before and known_ids.slice(0,before)==known_snapshot
		known_snapshot=known_ids.duplicate()
		if grown:
			# Discoveries were added: only the lists holding one are read again;
			# every other list stays the same Array, so what callers keep by it
			# stays good.
			var added:=known_ids.slice(before)
			for id in added:known[id]=true
			for open_channel:Variant in channels.keys():
				var ids:Dictionary=channel_ids.get(open_channel,{})
				for id in added:
					if ids.has(String(id)):
						channels.erase(open_channel)
						break
		else:
			known.clear()
			for id in known_ids:known[id]=true
			channels.clear();sources.clear();source_sizes.clear();channel_ids.clear()
	if not channels.has(channel) or not is_same(sources.get(channel),definitions) or int(source_sizes.get(channel,-1))!=definitions.size():
		var pending:Array=[]
		var ids:Dictionary={}
		for definition:Dictionary in definitions:
			var id:=String(definition.get("id",""))
			if not known.has(id):
				pending.append(definition)
				ids[id]=true
		channels[channel]=pending
		channel_ids[channel]=ids
		sources[channel]=definitions
		source_sizes[channel]=definitions.size()
	return channels[channel]
