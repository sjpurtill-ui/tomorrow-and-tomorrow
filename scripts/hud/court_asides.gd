extends RefCounted
## THE ROOM'S MUTTERING: what a bystander says under their breath.
##
## A short line in a small bubble from someone standing about (never the god,
## never the one the god is dealing with), after the room has reacted, in the
## held beat that follows. The director (court_director.gd) decides when one
## is said (about one event in four, never two at once, never at a death) and
## who says it; this file holds only the words.
##
## Every line is a template whose {slots} the director fills from the fact
## sheet and the engine's event, and every slot a line needs must be present
## or the line is not used. So a muttered line can never claim a number, a
## name or a sickness the ledger does not hold. Lines are plain, concrete and
## about the moment in the hall: no invented proverbs or maxims, no oaths, no
## real names, nothing the people's age does not know (the caller checks the
## era words). Each speaker keeps the manner of their lifelong voice model
## (character_voice.gd VOICE_MODELS), gathered here into families of manner;
## the people of the hall without a model speak plainly, children as children.
## Offline tables only: no live voice is ever called for a muttered line.
## Static helpers; preload.

## Each literary voice model's family of manner.
const FAMILY:={
	"grant":"terse","aurelius":"terse","washington":"terse","nemo":"terse","queequeg":"terse",
	"lincoln":"wry","falstaff":"wry","sancho":"wry","elizabeth":"wry",
	"ahab":"grand","lear":"grand","achilles":"grand","quixote":"grand","churchill":"grand","heathcliff":"grand",
	"judge":"cool","iago":"cool","odysseus":"cool","prospero":"cool","lady_macbeth":"cool",
	"atticus":"kind","nestor":"kind",
	"polonius":"fussy","cicero":"fussy",
}
const FAMILIES:=["terse","wry","grand","cool","kind","fussy","plain","child"]

## Slots: amount, resource (lower case, "food"), food_days, name (the one it
## is about, given name), other (a second person's given name), number (said
## aloud in the line just spoken), days_waiting, envoy_civ, enemy, sickness,
## deaths. A line is used only when every slot it names has a value.
const LINES:={
	# The god gives food from the stores while the stores run short.
	"boon_hungry":{
		"plain":["{amount} food, to one person. The stores hold {food_days} days.","{amount} food. I'd have knelt for {amount} food.","There goes {amount} food, and the stores down to {food_days} days."],
		"terse":["{amount} food. {food_days} days left in the stores.","{amount} food out. {food_days} days left."],
		"wry":["{amount} food. I should have stood nearer the front.","{amount} food! And I've stood here this whole time with nothing but my stomach."],
		"grand":["{amount} food, with the stores at {food_days} days. Someone will remember that.","{amount} food to {name}, and {food_days} days of food for the rest of us."],
		"cool":["{amount} food. With {food_days} days in the stores. Interesting.","{name} eats well, then."],
		"kind":["{amount} food. I hope {name} shares it. We have {food_days} days left."],
		"fussy":["{amount} food, from stores that hold {food_days} days. I would have mentioned it, had I been asked."],
		"child":["Is all that food for {name}?","Can I have some of {name}'s food?"],
	},
	# A gift from the stores when nobody is going short: envy, mostly.
	"boon_plenty":{
		"plain":["{amount} {resource}. For {name}.","{amount} {resource}, just like that."],
		"terse":["{amount} {resource} to {name}. Fine."],
		"wry":["{amount} {resource}. I'm going to start doing whatever {name} does.","{amount} {resource}. I'll stand nearer the front next time."],
		"grand":["{amount} {resource} to {name}, and not a word for the rest of us."],
		"cool":["{amount} {resource}. {name} will want more now."],
		"kind":["Good. {name} works hard."],
		"fussy":["{amount} {resource}. I'll be sure to remember the number."],
		"child":["Can I have {resource} too?"],
	},
	# Penance is fasting and vigil; the stores already make everyone fast.
	"penance_hungry":{
		"plain":["Fasting. The stores hold {food_days} days. We're halfway there already.","A fast. {name} will hardly notice, with the stores like this."],
		"terse":["A fast. With {food_days} days in the stores, that won't be hard."],
		"wry":["A fast. I've been practising since the stores got down to {food_days} days.","{name} has to fast. The rest of us are doing it for nothing."],
		"grand":["A fast, with the stores at {food_days} days. The whole hall is keeping that vigil."],
		"cool":["A fast, when the stores hold {food_days} days. Cheap penance."],
		"kind":["{name} will fast. Half of us already are, with {food_days} days left."],
		"fussy":["A fast, with {food_days} days in the stores. That saves us something, I suppose."],
		"child":["What's a fast? Is that when you don't eat? We do that."],
	},
	"terrify_cower":{
		"plain":["I've never seen {name} that colour.","{name}'s knees are going.","Don't look at {name}. Don't look."],
		"terse":["{name} won't sleep for a while.","{name} is finished for today."],
		"wry":["I'd be on my knees too. I nearly am.","Better {name} than me. Much better."],
		"grand":["Look at {name}. That could be any of us."],
		"cool":["{name} will remember that. So will the rest of us."],
		"kind":["Someone help {name} up after.","Oh, {name}."],
		"fussy":["In fairness, I would have shaken too. Somewhat less."],
		"child":["Why is {name} shaking?","Is the god angry with {name}?"],
	},
	"terrify_defy":{
		"plain":["{name} didn't even blink.","Is {name} mad?"],
		"terse":["{name} stood. Brave, or stupid."],
		"wry":["{name} has more nerve than I have. Or less sense."],
		"grand":["{name} stood up to it. I didn't think I'd live to see that."],
		"cool":["{name} held their ground. Let's see for how long."],
		"kind":["Kneel, {name}. Please kneel."],
		"fussy":["That is not how one stands before the god. Not at all."],
		"child":["{name} isn't scared!"],
	},
	"terrify_endure":{
		"plain":["{name} took that better than I would."],
		"terse":["{name} took it."],
		"kind":["Steady, {name}."],
		"cool":["{name} said nothing. Sensible."],
		"child":["Is it over?"],
	},
	"bless_envy":{
		"plain":["Blessed. {name}. Of course."],
		"wry":["If I'd known the god liked that sort of thing, I'd have done it first."],
		"grand":["{name}, raised over us. I won't forget this day."],
		"cool":["{name} has a friend above. Useful."],
		"fussy":["A blessing, for {name}. Well. I'm sure it was deserved."],
		"terse":["{name}. Of course."],
		"child":["Can the god bless me too?"],
	},
	"bless_glad":{
		"wry":["Look at {name}. Grinning like a child."],
		"kind":["Good. Good for {name}."],
		"plain":["{name} deserves it."],
		"child":["{name} is smiling!"],
	},
	# An envoy brings food while our stores run short.
	"gift_food_hungry":{
		"plain":["Is it really food? Tell me it's food.","{amount} food. Thank them. Thank them twice."],
		"terse":["{amount} food. Good. We need it."],
		"wry":["{amount} food. I could hug that envoy.","{amount} food. I like these people already."],
		"grand":["{amount} food from strangers, with our stores at {food_days} days. Remember who fed us."],
		"cool":["{amount} food. Nobody gives that much for nothing."],
		"kind":["{amount} food. Some families will eat properly now."],
		"fussy":["{amount} food. Generous. Suspiciously generous."],
		"child":["Is that all food?"],
	},
	# A gift turned back at the door: the bearer has to carry it home.
	"gift_refused":{
		"plain":["They carried all that here, and now they carry it home."],
		"terse":["Back it goes."],
		"wry":["If they're taking it back, I'll help carry it. Part of the way."],
		"cool":["They'll remember carrying it home."],
		"kind":["Those poor bearers."],
		"child":["Why are they taking it away again?"],
	},
	"gift_refused_hungry":{
		"plain":["{amount} food, going back out the door. With {food_days} days in our stores."],
		"wry":["{amount} food, and we send it home. I'll go hungry proudly, then."],
		"grand":["{amount} food turned away, and {food_days} days in the stores. I hope pride is filling."],
		"terse":["{amount} food sent back. {food_days} days left."],
		"child":["They're taking the food away!"],
	},
	"envoy_waited":{
		"plain":["They waited {days_waiting} days for this."],
		"wry":["{days_waiting} days they waited. I hope they like the answer."],
		"terse":["{days_waiting} days waiting, for that."],
		"cool":["{days_waiting} days outside. They'll have had time to count our spears."],
	},
	"war_envoy":{
		"terse":["That one's from {enemy}. Watch their hands."],
		"grand":["We're fighting {enemy}, and their envoy stands in our hall."],
		"cool":["{enemy} sends talk while their spears are out. Interesting."],
		"plain":["That's someone from {enemy}, in here?"],
		"child":["Is that one of the bad ones?"],
	},
	"sick_cough":{
		"plain":["Cough the other way.","Not on me. Please, not on me."],
		"terse":["Stand further off. {sickness} is among us."],
		"wry":["Cough on someone you don't like."],
		"grand":["{deaths} dead of {sickness} already, and you cough in the god's hall."],
		"cool":["Keep that away from me."],
		"kind":["Go home and lie down. Please."],
		"fussy":["Cover your mouth. {sickness} has killed {deaths} already."],
		"child":["Why does everyone cough?"],
	},
	"number":{
		"plain":["{number}? Did they say {number}?"],
		"terse":["{number}. Hm."],
		"wry":["{number}! I'd have settled for half."],
		"cool":["{number}. Remember that number."],
		"fussy":["{number}. I'll want that counted twice."],
		"grand":["{number}. Did everyone hear that? {number}."],
		"child":["Is {number} a lot?"],
	},
	"eager_bow":{
		"plain":["{name} will put a back out."],
		"wry":["Any lower, {name}, and you'll be under the floor."],
		"terse":["Steady, {name}."],
		"cool":["{name} would bow to a stone if the god looked at it."],
		"fussy":["Too deep, {name}. Far too deep."],
		"kind":["Careful, {name}."],
		"child":["Why is {name} bowing like that?"],
	},
	"faint":{
		"plain":["{name}'s gone over."],
		"wry":["Catch {name}. No, the other side."],
		"terse":["{name} is down. Breathing, though."],
		"kind":["Give {name} room. Let them breathe."],
		"child":["Is {name} asleep?"],
	},
	"prostrate":{
		"plain":["Nobody move."],
		"wry":["I'm not getting up first."],
		"child":["Do I lie down too?"],
		"terse":["Stay down."],
	},
	# An order that nothing in the world could carry out (the engine said so).
	"absurd":{
		"wry":["I'll go and start on that. Very slowly."],
		"plain":["What does the god mean?"],
		"cool":["Nothing will come of that. Watch."],
		"fussy":["I'm sure it made sense up there."],
		"terse":["Hm."],
		"child":["What did the god say?"],
	},
	"refused":{
		"plain":["That's a no, then."],
		"wry":["{name} came in hopeful, at least."],
		"kind":["Poor {name}."],
		"cool":["{name} won't ask twice."],
		"terse":["No, then."],
	},
	"granted":{
		"wry":["Look at {name}. Trying not to grin."],
		"cool":["{name} will ask for more next time."],
		"plain":["{name} got it, then."],
	},
	"storm_out":{
		"plain":["Well. That went badly."],
		"wry":["{name} forgot to bow. On purpose, I think."],
		"terse":["{name} is angry."],
		"cool":["We'll hear from {envoy_civ} about this."],
		"child":["Why didn't {name} bow?"],
	},
	"guard_awake":{
		"wry":["Their guard's awake now."],
		"plain":["Look at their guard."],
		"cool":["Their guard just remembered where they are."],
	},
	"doze_wake":{
		"plain":["{name}. {name}. The god is speaking.","Wake up, {name}."],
		"wry":["Welcome back, {name}."],
		"kind":["Let {name} be. Old bones."],
		"child":["{name} was asleep!"],
	},
	"drop_bowl":{
		"plain":["Pick it up. Slowly."],
		"wry":["That'll be the bowl, then."],
		"terse":["Leave it."],
		"child":["Somebody dropped a bowl."],
	},
	"goat_nibble":{
		"plain":["Get off. Get off me."],
		"wry":["Even the goat wants something from us."],
		"child":["The goat's eating {name}!"],
	},
	"dog_gift":{
		"plain":["Somebody hold that dog."],
		"wry":["The dog likes the gift, at least."],
		"child":["The dog wants it!"],
	},
	"guard_bored":{
		"wry":["Their guard's having a nice rest.","Their guard looks bored stiff."],
		"plain":["Look at their guard. Half asleep."],
		"cool":["Their guard is counting the roof poles."],
		"child":["That man's yawning!"],
	},
	# Someone laughed where they should not have, and got an elbow for it.
	"stifle":{
		"plain":["Not now.","Stop it. Stop it."],
		"wry":["Don't. Don't you dare."],
		"terse":["Enough."],
		"kind":["Breathe. Look at the floor."],
		"fussy":["This is the god's hall, {name}."],
	},
	"child_copy":{
		"plain":["Stop that.","Not now, {name}."],
		"kind":["Not now, little one."],
		"wry":["Not bad, {name}. Now stop."],
		"fussy":["{name}. Hands down. Now."],
	},
	"bow_early":{
		"plain":["Not yet. Not yet.","Closer first, {name}."],
		"wry":["{name} started bowing at the door."],
		"kind":["Easy, {name}. Come nearer first."],
	},
	"late_lift":{
		"plain":["Look up. Up.","{name}. Up."],
		"child":["What? What happened?"],
	},
	"goat":{
		"wry":["The goat's not impressed."],
		"plain":["Somebody take that goat out."],
		"child":["Look at the goat, it's still eating!"],
		"terse":["Who let the goat in?"],
	},
	"dog_scared":{
		"child":["The dog's scared too."],
		"kind":["Shh. It's all right, dog."],
		"plain":["Even the dog's hiding."],
	},
	"child_hides":{
		"kind":["Stay there. It's all right.","Stay behind me, {name}."],
		"plain":["Stay down, {name}."],
	},
	"gasp":{
		"plain":["Did everyone see that?"],
		"wry":["Nobody saw that. Nobody."],
		"cool":["Well. That happened."],
		"child":["Why did everyone gasp?"],
	},
	"late_down":{
		"plain":["Get down! Down!"],
		"wry":["{name}, the floor. Find the floor."],
		"child":["Do I lie down too?"],
	},
	"winter":{
		"plain":["My feet are ice.","Let the god finish before my hands fall off."],
		"wry":["I'd stand nearer the fire if I could find a way past {name}."],
		"child":["I'm cold."],
	},
	"war_watch":{
		"plain":["Who's watching for {enemy} while we're all in here?"],
		"terse":["Half of us in here, and {enemy} out there."],
		"grand":["{enemy} won't wait for us to finish talking."],
	},
	"dread_room":{
		"plain":["Don't look up. Don't look up."],
		"wry":["Whatever it is, I didn't do it."],
		"terse":["Quiet."],
		"child":["Is the god angry with us?"],
	},
}

static func family(member:Dictionary)->String:
	## A person's family of manner: their lifelong voice model's, else a
	## child's or the plain speech of the hall.
	var kind:=String(member.get("kind",""))
	if kind=="child":return "child"
	var voice:=String(member.get("voice","")).to_lower()
	if FAMILIES.has(voice):return voice
	return String(FAMILY.get(voice,"plain"))

## The slots a template names, in order.
static func slots_in(template:String)->Array:
	var out:Array=[]
	var at:=template.find("{")
	while at>=0:
		var close:=template.find("}",at)
		if close<0:break
		var slot:=template.substr(at+1,close-at-1)
		if not out.has(slot):out.append(slot)
		at=template.find("{",close)
	return out

## The lines a speaker of this family may say in this situation, with the
## plain speech of the hall as the fallback (never a child's for an adult).
static func lines(situation:String,manner:String)->Array:
	var table:Dictionary=LINES.get(situation,{})
	var own:Array=table.get(manner,[])
	if not own.is_empty():return own
	if manner=="child":return []
	return table.get("plain",[])

## A template filled from the slots; "" when a slot it needs has no value.
static func render(template:String,slots:Dictionary)->String:
	var text:=template
	for slot in slots_in(template):
		if not slots.has(slot):return ""
		var value:=String(slots[slot])
		if value.strip_edges().is_empty():return ""
		text=text.replace("{%s}" % slot,value)
	# A sentence opens with a capital, also where a slot opens it.
	var out:=""
	var upper:=true
	for i in text.length():
		var ch:=text.substr(i,1)
		if upper and ch.strip_edges()!="":
			out+=ch.to_upper();upper=false
		else:out+=ch
		if ch in [".","!","?"]:upper=true
	return out

## Every template, for the checks (plain speech, era words, slots).
static func all_templates()->Array:
	var out:Array=[]
	for situation in LINES:
		for manner in (LINES[situation] as Dictionary):
			for line in (LINES[situation] as Dictionary)[manner]:out.append({"situation":situation,"family":manner,"text":String(line)})
	return out
