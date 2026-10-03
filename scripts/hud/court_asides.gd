extends RefCounted
## THE ROOM'S MUTTERING: what a bystander says under their breath.
##
## A short line in a small bubble from someone standing about, after the
## room has reacted, in the held beat that follows. The director
## (court_director.gd) decides when one is said and who dares to say it:
## only in answer to something everyone can see happen (the old one woken,
## the bowl dropped, the bow to the wrong person); only from the bold, the
## proud, a child or an old one past caring; never in a terrified or grieving
## room (there, the silence is the joke); never two events running; never to
## the god's face: these are sidelong, to a neighbour or to nobody. This file
## holds only the words.
##
## Every line is a template whose {slots} the director fills from the fact
## sheet, the event and the cast, and every slot a line needs must be present
## or the line is not used: a muttered line never claims a number, a name or
## a fact the ledger does not hold. Eight words at most. Plain and concrete:
## no invented proverbs or maxims, no oaths, no real names; a line that
## names something of a later age is kept for a people who know it (NEEDS).
## Each speaker keeps the manner of their lifelong voice model
## (character_voice.gd VOICE_MODELS), gathered here into families of manner;
## people of the hall without a model speak plainly, children as children.
## Offline only: no live voice is ever called for a muttered line.
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
const MAX_WORDS:=8
## Situations whose words belong to a later age: the era tags they need.
const NEEDS:={"scribe":["writing"]}

## Slots: name (the one it is about, given name), other (a second person's
## given name), amount, resource (lower case), food_days, number (a number
## just said or given), enemy, envoy_civ, thing (what was left behind).
const LINES:={
	# The old one woken by the god's voice, a beat behind everyone.
	"doze_wake":{
		"plain":["Wake up, {name}. The god.","{name}. {name}. Eyes up.","Up, {name}. Up."],
		"wry":["Welcome back, {name}.","Good rest, {name}?","{name} missed the best part."],
		"terse":["Awake now, {name}?"],
		"kind":["Let {name} be. Old bones."],
		"fussy":["Asleep. In the god's hall."],
		"grand":["{name} sleeps through a god. Remarkable."],
		"child":["{name} was asleep!","{name} was snoring."],
	},
	"drop_bowl":{
		"plain":["Pick it up. Slowly.","Leave it. Leave it."],
		"wry":["That'll be the bowl, then.","There goes {name}'s supper."],
		"terse":["Leave it."],
		"fussy":["{name}. Honestly."],
		"child":["Somebody dropped a bowl."],
	},
	"eager_bow":{
		"plain":["{name} will put a back out.","Too deep, {name}. Far too deep."],
		"wry":["Any lower, {name}, and you're under the floor.","{name} nearly kissed the floor."],
		"terse":["Steady, {name}."],
		"cool":["{name} would bow to a stone."],
		"fussy":["Too deep, {name}. Too deep."],
		"kind":["Careful, {name}."],
		"child":["Why's {name} bowing like that?"],
	},
	"goat_nibble":{
		"plain":["Get off. Get off me.","Not now. Shoo."],
		"wry":["Of all the days to wear this."],
		"grand":["Away from me, beast."],
		"fussy":["Somebody. Take. This goat."],
		"child":["The goat's eating {name}!"],
	},
	"goat":{
		"wry":["Our goat's not impressed."],
		"plain":["Somebody take that goat out."],
		"terse":["Who let the goat in?"],
		"child":["Look, the goat's still eating!"],
	},
	"dog_gift":{
		"plain":["Somebody hold that dog.","Get that dog back here."],
		"wry":["Our dog likes their gift, anyway."],
		"child":["The dog wants it!"],
	},
	"number":{
		"plain":["{number}? Did they say {number}?","{number}. I heard {number}."],
		"terse":["{number}. Hm."],
		"wry":["{number}! I'd have settled for half."],
		"cool":["{number}. Remember that number."],
		"fussy":["{number}. I'll want that counted twice."],
		"grand":["{number}. Did everyone hear that?"],
		"child":["Is {number} a lot?"],
	},
	# A decree the people will pay for, counted on someone's fingers.
	"cost_grumble":{
		"plain":["{amount} {resource}. From whose store?","There goes {amount} {resource}."],
		"wry":["{amount} {resource}. I'll miss every one."],
		"terse":["{amount} {resource}. Ours."],
		"cool":["{amount} {resource}. And who carries it?"],
		"fussy":["{amount} {resource}. I counted. Twice."],
		"grand":["{amount} {resource}, gone at one word."],
		"child":["Is that our {resource}?"],
	},
	"sick_cough":{
		"plain":["Cough the other way.","Not on me. Please."],
		"wry":["Cough on someone you don't like."],
		"terse":["Stand further off."],
		"kind":["Go home and lie down."],
		"fussy":["Cover your mouth, {name}."],
		"child":["Why does everyone cough?"],
	},
	"guard_bored":{
		"wry":["Their guard's having a nice rest.","Their guard looks bored stiff."],
		"plain":["Look at their guard. Half asleep."],
		"cool":["Their guard is counting our roof poles."],
		"child":["That man's yawning!"],
	},
	"guard_awake":{
		"wry":["Their guard's awake now."],
		"plain":["Look at their guard."],
		"cool":["Their guard just remembered where they are."],
	},
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
		"plain":["Not yet. Closer first.","Closer, {name}. Then bow."],
		"wry":["{name} started bowing at the door."],
		"kind":["Easy, {name}. Come nearer."],
	},
	"late_lift":{
		"plain":["Look up. Up.","{name}. Up."],
		"child":["What? What happened?"],
	},
	"gasp":{
		"plain":["Did everyone see that?"],
		"wry":["Nobody gasped. Nobody saw anything."],
		"cool":["Well. That happened."],
		"terse":["Hm."],
		"child":["Why did everyone gasp?"],
	},
	"winter":{
		"plain":["My feet are ice.","My toes are going."],
		"wry":["Stamp quieter, {name}. Please."],
		"terse":["Cold."],
		"child":["I'm cold."],
	},
	# The old one swats at a fly and catches the speaker instead.
	"fly":{
		"plain":["Watch the hands, {name}.","That was my ear, {name}."],
		"wry":["Missed the fly. Got me."],
		"kind":["Leave it, {name}. It's only a fly."],
		"child":["{name} hit me!"],
	},
	"scribe":{
		"plain":["Did you get all that?","Write faster."],
		"wry":["You missed a bit, {name}."],
		"cool":["Write down what the god said. Exactly."],
		"child":["What are you scratching?"],
	},
	"over_thank":{
		"plain":["Once is enough, {name}.","Stop thanking. Start walking."],
		"wry":["{name} will be thanking the god till spring."],
		"terse":["We heard you, {name}."],
		"cool":["{name} knows who to please."],
		"child":["Why does {name} keep bowing?"],
	},
	"bump_post":{
		"plain":["Mind the post, {name}.","{name} just bowed to the post."],
		"wry":["The post forgives you, {name}."],
		"child":["{name} hit the post!"],
	},
	"forgot_thing":{
		"plain":["Forgot something, {name}?","And out again."],
		"wry":["Don't laugh. Don't laugh."],
		"terse":["Forgot the {thing}."],
		"child":["{name} came back!"],
	},
	"wrong_door":{
		"plain":["Other way, {name}.","Wrong side, {name}."],
		"wry":["{name} found a new way in."],
		"child":["{name} went the wrong way!"],
	},
	"bow_wrong":{
		"plain":["Not {other}. Up there. Up!","Wrong one. Wrong one."],
		"wry":["{other} enjoyed that, I think."],
		"cool":["{other} didn't correct them very quickly."],
		"child":["They bowed to {other}!"],
	},
	"child_wave":{
		"plain":["Hands down. Hands down.","Did {name} just wave?"],
		"wry":["Bold little thing, {name}."],
		"kind":["{name} means no harm by it."],
		"child":["Can I wave too?"],
	},
	"stare_down":{
		"plain":["{other} blinked first.","Go on. Blink."],
		"terse":["Their guard looked away."],
		"cool":["{other} won't forget that."],
		"child":["They're having a staring game!"],
	},
	"stare_war":{
		"terse":["That one's from {enemy}. Watch their hands."],
		"grand":["{enemy} sends us staring guards now."],
		"plain":["Someone from {enemy}, in our hall."],
	},
	"company_gawk":{
		"plain":["They've never seen a hall like it.","Close your mouths, friends."],
		"wry":["Their guard's counting our roof poles."],
		"child":["They're staring at our roof!"],
	},
	"gifted":{
		"plain":["Watch that one.","Where did {name} learn that?"],
		"terse":["Sharp, that one."],
		"kind":["{name} isn't afraid of anything."],
		"cool":["Remember {name}'s face."],
		"child":["{name} does that all the time."],
	},
	"envoy_haughty":{
		"plain":["Sniff all you like.","Who does that one think they are?"],
		"terse":["Proud, that one."],
		"cool":["Let them sniff. They came to us."],
		"child":["Why's that one making a face?"],
	},
	"envoy_nervous":{
		"plain":["It's only the dog.","Our dog won't bite. Probably."],
		"wry":["Scared of the dog. Good start."],
		"child":["Our dog scared them!"],
	},
	"envoy_greedy":{
		"plain":["Counting our things, that one.","Keep an eye on the baskets."],
		"cool":["That one's pricing our hall."],
		"child":["Why's that one looking at our stuff?"],
	},
	# Hungry eyes on food from the stores, or a food gift carried in.
	"boon_hungry":{
		"plain":["{amount} food, to one person.","I'd have knelt for {amount} food."],
		"terse":["{amount} food. {food_days} days left in store."],
		"wry":["{amount} food. I stood in the wrong place."],
		"grand":["{amount} food, and {food_days} days in store."],
		"cool":["{name} eats well, then."],
		"child":["Is all that food for {name}?"],
	},
	"gift_food_hungry":{
		"plain":["Tell me it's food.","{amount} food. Thank them twice."],
		"terse":["{amount} food. Good."],
		"wry":["{amount} food. I like these people."],
		"cool":["{amount} food. Nobody gives that for nothing."],
		"kind":["Some families will eat properly now."],
		"child":["Is that all food?"],
	},
	"gift_refused":{
		"plain":["All that way, and back again.","Those poor bearers."],
		"wry":["I'd carry it back for them. Halfway."],
		"cool":["They'll remember carrying it home."],
		"child":["Why are they taking it back?"],
	},
	"gift_refused_hungry":{
		"plain":["{amount} food, back out the door.","{food_days} days in store, and we refuse food?"],
		"terse":["{amount} food sent back."],
		"child":["They're taking the food away!"],
	},
	"bless_envy":{
		"plain":["{name}. Of course.","Blessed. {name}. Naturally."],
		"wry":["I'll stand nearer the front next time."],
		"cool":["{name} has a friend above."],
		"grand":["{name}, raised over us."],
		"fussy":["Well. I'm sure {name} deserved it."],
	},
	"penance_hungry":{
		"plain":["A fast. We're halfway there already.","{name} has to fast. We do it free."],
		"wry":["A fast? I've been practising for days."],
		"terse":["A fast. With {food_days} days left."],
		"child":["We fast every day now."],
	},
	"refused":{
		"plain":["That's a no, then.","Poor {name}."],
		"cool":["{name} won't ask twice."],
		"terse":["No, then."],
		"kind":["Next time, {name}."],
	},
	"promise_deflate":{
		"plain":["Consider it. That means no.","{name} has heard that before."],
		"wry":["Considered. Like the last time."],
		"cool":["Give it a season, {name}."],
		"child":["Did they get it or not?"],
	},
	"absurd":{
		"wry":["I'll start on that. Very slowly."],
		"plain":["What did the god mean?"],
		"cool":["Nothing will come of that. Watch."],
		"fussy":["I'm sure it made sense up there."],
		"terse":["Hm."],
		"child":["What did the god say?"],
	},
	"storm_out":{
		"plain":["Well. That went badly."],
		"wry":["{name} forgot to bow. On purpose."],
		"cool":["We'll hear from {envoy_civ} about this."],
		"child":["Why didn't {name} bow?"],
	},
	"wait_doze":{
		"plain":["{name}'s asleep again.","There goes {name} again."],
		"wry":["{name} has the right idea."],
		"child":["{name} is sleeping again!"],
	},
	"wait_long":{
		"plain":["Is the god still thinking?","How long do we stand here?"],
		"wry":["I've grown since we came in."],
		"child":["Is it over? Can we go?"],
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
## plain speech of the hall as the fallback (never a child's for an adult,
## never an adult's for a child).
static func lines(situation:String,manner:String)->Array:
	var table:Dictionary=LINES.get(situation,{})
	var own:Array=table.get(manner,[])
	if not own.is_empty():return own
	if manner=="child":return []
	return table.get("plain",[])

## Whether a people with these era tags may say this situation's lines.
static func allowed(situation:String,tags:Array)->bool:
	for tag in NEEDS.get(situation,[]):
		if not tags.has(tag):return false
	return true

## Words in a line, as said.
static func word_count(text:String)->int:
	return text.strip_edges().split(" ",false).size()

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

## Every template, for the checks (plain speech, era words, length, slots).
static func all_templates()->Array:
	var out:Array=[]
	for situation in LINES:
		for manner in (LINES[situation] as Dictionary):
			for line in (LINES[situation] as Dictionary)[manner]:out.append({"situation":situation,"family":manner,"text":String(line)})
	return out
