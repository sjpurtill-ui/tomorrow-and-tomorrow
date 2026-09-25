extends RefCounted
## What the Hearth Chief says at the fire circle: the opening question, the
## answer to it, and the naming of the first home. Each line is written in the
## manner of the chief's lifelong voice model (character_voice.gd), in original
## words, and grounded in what a founding band knows: fire, feet, weather,
## children, hunting and gathering. No writing, metal, boats or beasts of burden.
##
## The answers are the people's founding purposes (PeopleDirection.AMBITIONS)
## put the way such a people would put them. Which four are offered first
## depends on the land they stand in; the rest are there if the god asks.

const Voice:=preload("res://scripts/character_voice.gd")

const LINES:={
	"ahab":{"ask":"Hear the wind in it: we are walking into country none of us has seen. Before the first fire is lit, tell me what our children should say of us.","reply":"Then that is our quarry. I will hold us to it through every winter.","name":"Mark this place: the fire is lit and the ground is ours. What do we call it?","named":"{name}. Let the wind learn it.","later":"Unnamed, then, until it earns one."},
	"judge":{"ask":"Observe: we are about to settle, and what we do first is what our grandchildren will be known for. Let us pick it ourselves. What should our children say of us?","reply":"A sound choice. The first hard winter will show whether we meant it.","name":"The fire has taken, and the others want to know what to call this ground. What is this place?","named":"{name}. Good. Now it exists.","later":"As you like. It is still ours, name or no name."},
	"atticus":{"ask":"Let's be fair about this: our children will judge us whether we ask them to or not. What should they say of us?","reply":"That's a fair thing to want. I'll see we're held to it.","name":"The fire's lit. A place wants a name the children can say without stumbling. What will it be?","named":"{name}. It's a good name. Plain and honest.","later":"No hurry. We'll know the right name when we hear it."},
	"lincoln":{"ask":"Here's how I see it: one day our grandchildren will sit at a fire and talk about us. Before we walk on, what should they say?","reply":"That'll do. I can work toward that, and so can the rest of them.","name":"Put it this way: the children keep asking where we are, and I have nothing to tell them. What do we call the place?","named":"{name}. I like it. It'll wear well.","later":"Leave it be for now. Someone will say something at supper and it will stick."},
	"grant":{"ask":"Plainly: we need to know what we are for. What should our children say of us?","reply":"Good. Then we start.","name":"Fire's lit. What's the place called?","named":"{name}. Done.","later":"Later, then."},
	"falstaff":{"ask":"Before my legs give out entirely and the stew goes cold: when our children tell tales at their own fires, what should they say of us?","reply":"A fine thing to be remembered for. Better than my singing, at any rate.","name":"The fire's roaring and nobody's died yet. A place this lucky wants a name. What'll it be?","named":"{name}! I'll shout it at the hills until they know it.","later":"No name yet? Then I'll call it Supper until you think of better."},
	"aurelius":{"ask":"Consider it carefully. We will be dead long before this camp is. What should our children say of us?","reply":"Then let us be that each day, and not only today.","name":"We will be saying this name for the rest of our lives. What shall this place be called?","named":"{name}. May we deserve it.","later":"Let us live here a while first. We will know it better then."},
	"iago":{"ask":"Between us: the children will believe whatever we tell them at this fire. So tell me, what should they say of us?","reply":"Clever. I'll make sure they say it.","name":"The others will argue over a name all night unless you settle it. What is it called?","named":"{name}. They will think they chose it themselves.","later":"Wise. Keep them guessing a while."},
	"elizabeth":{"ask":"I confess I'm curious what you'll say. We've walked a long way on hope alone. What should our children say of us?","reply":"Well answered. I'd have been disappointed by anything duller.","name":"The fire's lit, and I refuse to call it the camp for another night. What is its name?","named":"{name}. Yes, that suits it rather well.","later":"Very well. But I will hold you to finding one."},
	"achilles":{"ask":"I want our names sung at other fires long after we are gone. What should our children say of us?","reply":"Then that is what they will sing. I will see to it.","name":"The fire is ours and the ground is ours. Give it a name worth standing in front of.","named":"{name}. Let whoever wants it come and try.","later":"Unnamed. For now."},
	"sancho":{"ask":"Before I go and see to the fire, one thing, while everyone's still awake: what should our children say of us?","reply":"Well, that's a fire I can watch. I'll sleep easier.","name":"Fire's lit, bellies nearly full, and the little ones want to know where we are. What'll we call it?","named":"{name}. Easy on the tongue. Good.","later":"No name? Then we'll call it here, and it'll answer to that."},
	"polonius":{"ask":"If I may, and I shall be brief, which I seldom am: before we build a single shelter, we ought to agree what we are building it for. What should our children say of us?","reply":"Wisely chosen. I'd have said the same, at greater length.","name":"Now, a name: neither too long nor too short, and easily remembered. What shall it be?","named":"{name}. Admirable. Brief, even.","later":"Prudent. We would only have to live with a bad one."},
	"cicero":{"ask":"Friends, and you above all: the question that decides every other. What should our children say of us?","reply":"Spoken like the founder of a people. Let it be so.","name":"Our people will be saying this name to every stranger they meet. What shall we call this place?","named":"{name}. They will say it with pride, I promise you.","later":"Then let us earn the name first."},
	"lear":{"ask":"I am old, and I will not see what grows here. Tell me what they will say of us, the children, when I am under the ground.","reply":"Good. Good. Then I can rest easier.","name":"The fire is lit. Name it, before I forget which fire this is.","named":"{name}. I will remember that. I will.","later":"No name. Like me, soon enough."},
	"churchill":{"ask":"We have come through the worst of the walk, and the worst is not yet over. So let us be clear: what should our children say of us?","reply":"Then we shall never give it up. Not in the cold, not in hunger.","name":"The fire is lit, and this is the ground we mean to keep. What shall we call it?","named":"{name}. We shall hold it.","later":"Very well. We will name it when it has been tested."},
}
const FALLBACK:={"ask":"Before the first fire is lit, one thing. What should our children say of us?","reply":"Then that is what we will be.","name":"The fire is lit. What do we call this place?","named":"{name}. It is a good name.","later":"Then we will name it when it has earned one."}

## Each founding purpose, as a band at the fire would say it.
const ANSWERS:={
	"sustenance":"That no child of ours went hungry, and the land still fed us after.",
	"wellbeing":"That our children grew old, and their children after them.",
	"makers":"That we made things that outlasted us.",
	"inquiry":"That we asked why, and kept on asking.",
	"horizons":"That we walked farther than any people, and came home to tell it.",
	"gathering":"That whoever came to our fire found a place at it.",
	"commerce":"That what we made travelled farther than we ever walked.",
	"expansion":"That our fires burned in many valleys.",
	"military":"That no one ever took what was ours.",
	"dominion":"That other peoples bent to us.",
	"retribution":"That none who wronged us ever slept easy.",
	"purity":"That we kept ourselves apart, and stayed ourselves.",
	"dynasty":"That the chief's blood ruled after the chief.",
	"orthodoxy":"That we held one truth, and no one spoke against it.",
}

## Words a god might use in their own answer, by founding purpose.
const KEYWORDS:={
	"sustenance":["food","hunger","hungry","fed","feed","harvest","plenty","abundance","eat","starve","land"],
	"wellbeing":["children","child","grow old","healthy","health","care","heal","long lives","thrive","safe and well"],
	"makers":["make","made","build","built","craft","tools","endure","last","outlast","skill","works"],
	"inquiry":["why","learn","idea","ideas","question","wise","wisdom","think","curious","understand","truth of things"],
	"horizons":["walk","far","world","explore","beyond","travel","wander","horizon","see everything","discover"],
	"gathering":["together","welcome","everyone","share","kin","peace","belong","friends","united","one people"],
	"commerce":["trade","exchange","barter","rich","wealth","goods"],
	"expansion":["many valleys","spread","new homes","settle","everywhere","grow large","multiply"],
	"military":["strong","strength","defend","protect","warrior","warriors","fight","brave","never beaten"],
	"dominion":["rule","conquer","bow","bend","subject","master","empire","obey us","kneel"],
	"retribution":["vengeance","revenge","wronged","punish","feared","terror","terrible","dread"],
	"purity":["pure","chosen","outsiders","apart","our own kind","strangers out"],
	"dynasty":["blood","heirs","bloodline","my line","rank","noble","inherit"],
	"orthodoxy":["one truth","believe","faith","obey","heresy","doubt no"],
}

static func hearth_chief()->Dictionary:
	## The Hearth Chief who speaks at the fire. Before the Hearth Circle stands
	## no office is held; GovernmentPeopleSystem will seat the first Hearth Chief
	## from its founding pool by a seeded shortlist, so the same person is
	## previewed here (read-only: nothing is appointed or stored).
	var holder:=GovernmentPeopleSystem.officeholder("Steward")
	if not holder.is_empty(): return holder
	var gps:=GovernmentPeopleSystem
	if not gps.people.is_empty(): return {}
	var offices:=gps.active_offices().size()
	var pool:=mini(maxi(clampi(3+int(gps.government_stage)*4+2+offices,6,gps.NORMAL_GOVERNMENT_POOL),1+offices+4),gps.MAX_GOVERNMENT_PEOPLE)
	var best:=1; var best_order:=2147483647
	for pid in range(1,pool+1):
		var order:=posmod(hash("%d:Steward:shortlist:%d" % [int(GameState.world_seed),pid]),2147483647)
		if order<best_order: best=pid; best_order=order
	var person:Dictionary=gps._generate_person(best)
	person["office_key"]="Steward"; person["office_title"]="Hearth Chief"
	return person

static func lines_for(person:Dictionary)->Dictionary:
	if person.is_empty(): return FALLBACK
	var persona:Dictionary=Voice.for_person(person)
	return LINES.get(String(persona.get("model","")),FALLBACK)

static func say(person:Dictionary,key:String,name:String="")->String:
	return String(lines_for(person).get(key,FALLBACK.get(key,""))).replace("{name}",name)

static func offered(profile:Dictionary,seed_value:int)->Array[String]:
	## Four answers for this land: one about keeping alive, one about making or
	## knowing, one about the world beyond, one about strength.
	var food:=float(profile.get("food_potential",0.5))
	var stone:=float(profile.get("stone",profile.get("construction_potential",0.5)))
	var routes:=float(profile.get("route_potential",0.5))
	var coastal:=bool(profile.get("coastal",false))
	var first:="sustenance" if food<0.62 else "wellbeing"
	var second:="makers" if stone>=0.45 or posmod(seed_value,2)==0 else "inquiry"
	var third:="horizons" if coastal or routes>=0.5 else ("gathering" if posmod(seed_value,3)!=0 else "expansion")
	return [first,second,third,"military"]

static func others(first:Array)->Array[String]:
	var result:Array[String]=[]
	for id in ANSWERS:
		if String(id) not in first and PeopleDirection.AMBITIONS.has(String(id)): result.append(String(id))
	return result

static func interpret(text:String,fallback:String)->String:
	## A god's own words, heard as the nearest founding purpose. Never refuses.
	var low:=" "+text.to_lower().strip_edges()+" "
	var best:=fallback; var best_score:=0
	for id in KEYWORDS:
		var score:=0
		for word in KEYWORDS[id]:
			if low.contains(" "+String(word)) : score+=2 if String(word).contains(" ") else 1
		if score>best_score: best=String(id); best_score=score
	return best

static func name_suggestions(profile:Dictionary,seed_value:int)->Array[String]:
	## Names a founding band might give, from the ground it actually stands on.
	var firsts:=["Alder","Ash","Reed","Elk","Hazel","Heron","Willow","Flint","Otter","Birch","Aurochs","Sedge"]
	var ends:Array[String]=["hearth","fire"]
	if float(profile.get("water_access",0.0))>0.5 or float(profile.get("river_distance_km",99.0))<3.0: ends.append_array(["ford","water"])
	if bool(profile.get("coastal",false)): ends.append("strand")
	if float(profile.get("woodland",0.0))>0.4: ends.append("wood")
	if float(profile.get("relief",0.0))>0.3: ends.append("rise")
	ends.append_array(["hollow","stand"])
	var rng:=RandomNumberGenerator.new(); rng.seed=hash("%d|first_fire_names" % seed_value)
	var result:Array[String]=[]
	var guard:=0
	while result.size()<3 and guard<40:
		guard+=1
		var name:=String(firsts[rng.randi_range(0,firsts.size()-1)])+String(ends[rng.randi_range(0,ends.size()-1)])
		if name not in result: result.append(name)
	return result
