extends RefCounted
## ONE RELATION FOR EACH PAIR OF PEOPLES. Every people keeps its own record of
## every other (its world's `player_relation`), so each pair's relation exists
## twice, once on each side, and a third time for two other peoples in the
## god's world (`relations`, which the court, the spies and the leagues read
## to ask "are these two at war?"). Once a day the three are made to agree.
##
## - SHARED facts (a treaty, a war and its days) are carried across when one
##   side changes them.
## - SHARED_NUMBERS (how they regard each other, the heat on the border) are
##   one number for the pair: each side's change since the last agreement is
##   added, so an insult given in our hall and a grudge nursed at their fire
##   both count. Before this, what we did changed our copy and their ruler
##   decided from theirs, which our deeds never touched.
## - Two other peoples' SHARED facts are written into the god's world's
##   record of the pair, which nothing else kept up while both are simulated.
const SHARED:=["treaty","at_war","war_started_day","truce_until_day","war_id"]
## Field: the bounds it is kept within.
const SHARED_NUMBERS:={"opinion":Vector2(-1.0,1.0),"border_tension":Vector2(0.0,1.0)}
const NUMBERS_KEY:="numbers:"

static func synchronize()->void:
	var ids:Array=WorldSimulation.actors.keys();ids.append("player");ids.sort()
	var changes:Array[Dictionary]=[]
	# What each side holds today: {"a:b": {field: value}}.
	var facts:={}
	var numbers:={}
	var unseen:={}
	for id:String in ids:
		WorldSimulation.scoped(id,func()->void:
			for civ in WorldSimulation.world.civilizations:
				var other:="player" if String(civ.id)=="human" else String(civ.id)
				var key:=id+":"+other
				var current:Dictionary={}
				for field in SHARED:
					if civ.player_relation.has(field):current[field]=civ.player_relation[field]
				var previous:Dictionary=WorldSimulation.relation_baselines.get(key,{})
				# A side seen for the first time (a new world, a save from before
				# this was kept) has changed nothing: the pair is settled below.
				if previous.is_empty():unseen[key]=true
				elif current!=previous and not current.is_empty():changes.append({"source":id,"target":other,"fields":current})
				WorldSimulation.relation_baselines[key]=current.duplicate(true)
				facts[key]=current
				var held:={}
				for field:String in SHARED_NUMBERS:
					if civ.player_relation.has(field):held[field]=float(civ.player_relation[field])
				numbers[key]=held
		)
	# A pair neither side of which has been seen before, whose two records
	# disagree: a war one of them knows of is a war (it was declared); else
	# the first of the two stands. (Taken in turn as two changes, each side
	# overwrote the other and they ended swapped.)
	for i in ids.size():
		for j in range(i+1,ids.size()):
			var a:=String(ids[i]);var b:=String(ids[j])
			if not unseen.has(a+":"+b) and not unseen.has(b+":"+a):continue
			var ours:Dictionary=facts.get(a+":"+b,{})
			var theirs:Dictionary=facts.get(b+":"+a,{})
			if ours.is_empty() or theirs.is_empty() or ours==theirs:continue
			if bool(theirs.get("at_war",false)) and not bool(ours.get("at_war",false)):changes.append({"source":b,"target":a,"fields":theirs})
			else:changes.append({"source":a,"target":b,"fields":ours})
	for change in changes:
		if change.target!="player" and not WorldSimulation.actors.has(change.target):continue
		WorldSimulation.scoped(String(change.target),func()->void:
			var source_id:="human" if change.source=="player" else String(change.source)
			for civ in WorldSimulation.world.civilizations:
				if String(civ.id)!=source_id:continue
				civ.player_relation.merge(change.fields,true)
				var back:=String(change.target)+":"+String(change.source)
				WorldSimulation.relation_baselines[back]=change.fields.duplicate(true)
				facts[back]=(facts.get(back,{}) as Dictionary).merged(change.fields,true)
		)
	# The pair's numbers: one value, each side's change added to it.
	var writes:={}
	for i in ids.size():
		for j in range(i+1,ids.size()):
			var a:=String(ids[i]);var b:=String(ids[j])
			var ours:Dictionary=numbers.get(a+":"+b,{})
			var theirs:Dictionary=numbers.get(b+":"+a,{})
			if not numbers.has(a+":"+b) or not numbers.has(b+":"+a):continue
			var base_key:=NUMBERS_KEY+a+":"+b
			var base:Dictionary=WorldSimulation.relation_baselines.get(base_key,{})
			var agreed:={}
			for field:String in SHARED_NUMBERS:
				# A side that has never held the number (a record made bare, as
				# another people's record of the god's people is) takes the other's.
				if not ours.has(field) and not theirs.has(field):continue
				var value:=0.0
				var va:=float(ours.get(field,theirs.get(field,0.0)));var vb:=float(theirs.get(field,ours.get(field,0.0)))
				if base.has(field) and ours.has(field) and theirs.has(field):
					value=float(base[field])+(va-float(base[field]))+(vb-float(base[field]))
				# The first agreement: what the god's people have seen stands;
				# between two other peoples, the middle of the two.
				elif a=="player" and ours.has(field):value=va
				elif b=="player" and theirs.has(field):value=vb
				else:value=(va+vb)*0.5
				var bounds:Vector2=SHARED_NUMBERS[field]
				value=clampf(value,bounds.x,bounds.y)
				agreed[field]=value
				if not ours.has(field) or not is_equal_approx(va,value):((writes.get_or_add(a,{}) as Dictionary).get_or_add(b,{}) as Dictionary)[field]=value
				if not theirs.has(field) or not is_equal_approx(vb,value):((writes.get_or_add(b,{}) as Dictionary).get_or_add(a,{}) as Dictionary)[field]=value
			WorldSimulation.relation_baselines[base_key]=agreed
	for id:String in writes:
		WorldSimulation.scoped(id,func()->void:
			var mine:Dictionary=writes[id]
			for civ in WorldSimulation.world.civilizations:
				var other:="player" if String(civ.id)=="human" else String(civ.id)
				if mine.has(other):civ.player_relation.merge(mine[other],true)
		)
	# Two other peoples, in the god's world's own record of the pair.
	_mirror_pairs(ids,facts)

## Writes each simulated pair's SHARED facts into the god's world's record of
## the two (CivilizationSystem relations): a war they declared on each other
## is a war to everyone who asks there.
static func _mirror_pairs(ids:Array,facts:Dictionary)->void:
	var world:Node=CivilizationSystem
	var index_of:={}
	for index in world.civilizations.size():index_of[String(world.civilizations[index].id)]=index
	for i in ids.size():
		for j in range(i+1,ids.size()):
			var a:=String(ids[i]);var b:=String(ids[j])
			if a=="player" or b=="player" or not index_of.has(a) or not index_of.has(b):continue
			var held:Dictionary=facts.get(a+":"+b,{})
			if held.is_empty():held=facts.get(b+":"+a,{})
			if held.is_empty():continue
			var pair:Dictionary=((world.civilizations[int(index_of[a])].get("relations",{}) as Dictionary).get(b,{}) as Dictionary)
			var differs:=false
			for field:String in held:
				if not pair.has(field) or pair[field]!=held[field]:differs=true;break
			if not differs:continue
			world._set_pair_relation(int(index_of[a]),int(index_of[b]),pair.merged(held,true))
