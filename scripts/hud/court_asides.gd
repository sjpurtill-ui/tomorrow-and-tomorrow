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
		"plain":["Wake up, {name}. The god.","{name}. {name}. Eyes up.","Up, {name}. Up.","Back with us, {name}?","Keep your eyes open, {name}."],
		"wry":["Welcome back, {name}.","Good rest, {name}?","{name} missed the best part.","Sleep well, {name}? We didn't."],
		"terse":["Awake now, {name}?","Eyes open, {name}."],
		"kind":["Let {name} be. Old bones.","Easy, {name}. Nothing happened."],
		"fussy":["Asleep. In the god's hall.","{name}, your chin was on your chest."],
		"grand":["{name} sleeps through a god. Remarkable."],
		"cool":["{name} could sleep through anything."],
		"child":["{name} was asleep!","{name} was snoring.","{name} woke up funny!"],
	},
	"drop_bowl":{
		"plain":["Pick it up. Slowly.","Leave it. Leave it.","Don't move. Just don't.","Was it empty, at least?"],
		"wry":["That'll be the bowl, then.","There goes {name}'s supper.","Loudest thing all day, that bowl."],
		"terse":["Leave it.","Later."],
		"fussy":["{name}. Honestly.","In the god's hall, {name}."],
		"kind":["Never mind, {name}. Leave it."],
		"cool":["Everyone heard that, {name}."],
		"child":["Somebody dropped a bowl.","It rolled under there!"],
	},
	"eager_bow":{
		"plain":["{name} will put a back out.","Too deep, {name}. Far too deep.","Up, {name}. That's enough."],
		"wry":["Any lower, {name}, and you're under the floor.","{name} nearly kissed the floor.","{name} is still going down."],
		"terse":["Steady, {name}.","Too far, {name}."],
		"cool":["{name} would bow to a stone."],
		"fussy":["Too deep, {name}. Too deep."],
		"kind":["Careful, {name}.","{name} means well. Too well."],
		"grand":["{name} bows as if for us all."],
		"child":["Why's {name} bowing like that?","{name} almost fell over!"],
	},
	"goat_nibble":{
		"plain":["Get off. Get off me.","Not now. Shoo.","Off. Off!","Not the hem. Not now."],
		"wry":["Of all the days to wear this.","It likes me. Wonderful."],
		"grand":["Away from me, beast."],
		"fussy":["Somebody. Take. This goat.","Whose goat is this?"],
		"terse":["Off."],
		"cool":["I'll remember you, goat."],
		"kind":["Shoo, little one. Shoo."],
		"child":["The goat's eating {name}!","The goat likes {name}!"],
	},
	"goat":{
		"plain":["Somebody take that goat out.","That goat's still chewing."],
		"wry":["Our goat's not impressed.","The goat's still eating. Good for it."],
		"terse":["Who let the goat in?","Goat. Out."],
		"cool":["At least the goat is calm."],
		"fussy":["A goat. In the god's hall."],
		"kind":["Leave the goat be."],
		"grand":["Only our goat kept its nerve."],
		"child":["Look, the goat's still eating!","The goat isn't scared!"],
	},
	"dog_gift":{
		"plain":["Somebody hold that dog.","Get that dog back here.","Not the gift. Get back."],
		"wry":["Our dog likes their gift, anyway."],
		"terse":["Dog. Back."],
		"fussy":["Whose dog is that?"],
		"kind":["Come here, dog. Leave it."],
		"cool":["Our dog has no manners."],
		"grand":["Our dog greets them better than we did."],
		"child":["The dog wants it!","The dog's sniffing their stuff!"],
	},
	"number":{
		"plain":["{number}? Did they say {number}?","{number}. I heard {number}.","Was that {number}? Truly?"],
		"terse":["{number}. Hm."],
		"wry":["{number}! I'd have settled for half."],
		"cool":["{number}. Remember that number."],
		"fussy":["{number}. I'll want that counted twice."],
		"grand":["{number}. Did everyone hear that?"],
		"kind":["{number}. That's a great many."],
		"child":["Is {number} a lot?","{number}! More than my fingers!"],
	},
	# A decree the people will pay for, counted on someone's fingers.
	"cost_grumble":{
		"plain":["{amount} {resource}. From whose store?","There goes {amount} {resource}.","Who's carrying {amount} {resource}? Us."],
		"wry":["{amount} {resource}. I'll miss every one.","{amount} {resource}. I'll count them out myself."],
		"terse":["{amount} {resource}. Ours.","{amount}. Fine."],
		"cool":["{amount} {resource}. And who carries it?"],
		"fussy":["{amount} {resource}. I counted. Twice."],
		"grand":["{amount} {resource}, gone at one word."],
		"kind":["{amount} {resource}. We'll manage. Somehow."],
		"child":["Is that our {resource}?"],
	},
	"sick_cough":{
		"plain":["Cough the other way.","Not on me. Please.","Turn your head, at least."],
		"wry":["Cough on someone you don't like.","Thank you. I wanted that."],
		"terse":["Stand further off.","Away from me."],
		"kind":["Go home and lie down.","You should be lying down."],
		"fussy":["Cover your mouth, {name}."],
		"cool":["Keep that to yourself, {name}."],
		"grand":["Must you cough on me, {name}?"],
		"child":["Why does everyone cough?"],
	},
	"guard_bored":{
		"wry":["Their guard's having a nice rest.","Their guard looks bored stiff.","Their guard has seen better halls, apparently."],
		"plain":["Look at their guard. Half asleep.","Their guard's yawning at us."],
		"cool":["Their guard is counting our roof poles."],
		"terse":["Their guard's asleep standing."],
		"fussy":["Yawning. In front of the god."],
		"grand":["They send us a sleepy guard."],
		"kind":["Long road for them. Let them yawn."],
		"child":["Their guard's yawning!"],
	},
	"guard_awake":{
		"wry":["Their guard's awake now.","That woke their guard up."],
		"plain":["Look at their guard.","Their guard's wide awake now."],
		"cool":["Their guard just remembered where they are."],
		"terse":["Guard's awake."],
		"grand":["Now their guard knows whose hall this is."],
		"kind":["Poor guard. Nearly jumped out of their skin."],
		"fussy":["Their guard should have been awake already."],
		"child":["Their guard jumped!"],
	},
	"stifle":{
		"plain":["Not now.","Stop it. Stop it.","Don't you dare laugh."],
		"wry":["Don't. Don't you dare.","Laugh later. Much later."],
		"terse":["Enough.","Quiet."],
		"kind":["Breathe. Look at the floor."],
		"fussy":["This is the god's hall, {name}."],
		"cool":["Laugh again and you're on your own."],
		"grand":["Not in front of the god, {name}!"],
		"child":["Shh! Shh!"],
	},
	"child_copy":{
		"plain":["Stop that.","Not now, {name}.","Hands down, {name}."],
		"kind":["Not now, little one.","Later, little one. Not here."],
		"wry":["Not bad, {name}. Now stop.","Better than the real one, {name}."],
		"fussy":["{name}. Hands down. Now."],
		"terse":["Stop it."],
		"cool":["Do that again and see."],
		"grand":["{name}! In the god's own hall!"],
	},
	"bow_early":{
		"plain":["Not yet. Closer first.","Closer, {name}. Then bow.","Too soon, {name}."],
		"wry":["{name} started bowing at the door.","{name}'s bowing to the doorway."],
		"kind":["Easy, {name}. Come nearer."],
		"terse":["Closer."],
		"fussy":["Walk first, {name}. Then bow."],
		"cool":["{name} is very keen today."],
		"child":["Why's {name} bowing at nothing?"],
	},
	"late_lift":{
		"plain":["Look up. Up.","{name}. Up.","Up, {name}. Everyone's looking."],
		"wry":["{name} looks up at last."],
		"terse":["Up."],
		"kind":["Up, {name}. It's all right."],
		"fussy":["Late again, {name}."],
		"cool":["{name} missed it. Again."],
		"child":["What? What happened?","Did I miss it?"],
	},
	"gasp":{
		"plain":["Did everyone see that?","Did that just happen?"],
		"wry":["Nobody gasped. Nobody saw anything.","That was {name}, not me."],
		"cool":["Well. That happened."],
		"terse":["Hm."],
		"fussy":["We'll all pretend that didn't happen."],
		"grand":["Nobody here will forget that."],
		"kind":["Breathe, everyone. Breathe."],
		"child":["Why did everyone gasp?","Everyone went oh!"],
	},
	"winter":{
		"plain":["My feet are ice.","My toes are going.","I can't feel my hands."],
		"wry":["If I stamp, it's the cold."],
		"terse":["Cold."],
		"kind":["Stand closer. Share the warmth."],
		"fussy":["Who left the door open?"],
		"grand":["This cold will be the end of me."],
		"cool":["Colder in here than out there."],
		"child":["I'm cold.","My nose is cold."],
	},
	# The old one swats at a fly and catches the speaker instead.
	"fly":{
		"plain":["Watch the hands, {name}.","That was my ear, {name}.","Mind your hands, {name}."],
		"wry":["Missed the fly. Got me.","The fly's fine, {name}. I'm not."],
		"kind":["Leave it, {name}. It's only a fly."],
		"terse":["Ow."],
		"fussy":["{name}, that was my face."],
		"grand":["Struck by {name}. Before the god."],
		"cool":["Next time, {name}, aim."],
		"child":["{name} hit me!","Ow! {name}!"],
	},
	"scribe":{
		"plain":["Did you get all that?","Write faster.","Got that down, {name}?"],
		"wry":["You missed a bit, {name}.","Your hand will fall off, {name}."],
		"cool":["Write down what the god said. Exactly."],
		"terse":["Write it."],
		"fussy":["Every word, {name}. Every word."],
		"kind":["Rest your hand a moment, {name}."],
		"grand":["{name} has the god's words. Careful."],
		"child":["What are you scratching?"],
	},
	"over_thank":{
		"plain":["Once is enough, {name}.","Stop thanking. Start walking.","We all heard, {name}."],
		"wry":["{name} will be thanking the god till spring.","One more bow and {name} lives here."],
		"terse":["We heard you, {name}.","Enough, {name}."],
		"cool":["{name} knows who to please."],
		"kind":["Let {name} be glad."],
		"fussy":["Three bows. Four. Five."],
		"grand":["{name} thanks the god for us all."],
		"child":["Why does {name} keep bowing?"],
	},
	"bump_post":{
		"plain":["Mind the post, {name}.","{name} just bowed to the post.","That post's been there all along."],
		"wry":["The post forgives you, {name}.","{name} and the post. Old friends."],
		"terse":["Post."],
		"kind":["Are you hurt, {name}?"],
		"fussy":["Look where you walk, {name}."],
		"cool":["That post will be talked about."],
		"grand":["Even the post got a bow."],
		"child":["{name} hit the post!","{name} said sorry to the post!"],
	},
	"forgot_thing":{
		"plain":["Forgot something, {name}?","And out again.","Back so soon?"],
		"wry":["Don't laugh. Don't laugh.","Grand exit. Second try."],
		"terse":["Forgot the {thing}.","Back again."],
		"cool":["That exit lost something."],
		"fussy":["{name} came back for the {thing}."],
		"kind":["Don't look at {name}. Let them go."],
		"grand":["Back for the {thing}. With dignity."],
		"child":["{name} came back!","{name} forgot!"],
	},
	"wrong_door":{
		"plain":["Other way, {name}.","Wrong side, {name}.","Over here, {name}. Here."],
		"wry":["{name} found a new way in.","{name} took the long way."],
		"terse":["Wrong way."],
		"kind":["This way, {name}. Don't worry."],
		"fussy":["The door's been there for years, {name}."],
		"cool":["{name} is lost in our own hall."],
		"grand":["{name} arrives. Eventually."],
		"child":["{name} went the wrong way!"],
	},
	"bow_wrong":{
		"plain":["Not {other}. Up there. Up!","Wrong one. Wrong one.","Up there, friend. Not {other}."],
		"wry":["{other} enjoyed that, I think.","{other} won't let us forget that."],
		"cool":["{other} didn't correct them very quickly.","{other} looked pleased about it."],
		"terse":["Wrong one."],
		"kind":["An easy mistake. {other} does stand tall."],
		"fussy":["{other} is not the god, {name}."],
		"grand":["{other}, mistaken for a god. Imagine."],
		"child":["They bowed to {other}!","{other} isn't the god!"],
	},
	"child_wave":{
		"plain":["Hands down. Hands down.","Did {name} just wave?","Don't wave, {name}. Bow."],
		"wry":["Bold little thing, {name}.","{name} waved. At the god."],
		"kind":["{name} means no harm by it.","Let {name} be. Only a child."],
		"terse":["Bow, {name}."],
		"fussy":["We do not wave, {name}."],
		"grand":["{name} greets a god like a neighbour."],
		"child":["Can I wave too?","I want to wave!"],
	},
	"stare_down":{
		"plain":["{other} blinked first.","Go on. Blink.","Look at those two."],
		"terse":["{other} looked away."],
		"wry":["Somebody blink. Please."],
		"cool":["{other} won't forget that.","{other} lost that one."],
		"kind":["Let it go, both of you."],
		"fussy":["Staring. In the god's hall."],
		"grand":["{other} looked away first. Remember it."],
		"child":["They're having a staring game!","Who won? Who won?"],
	},
	"stare_war":{
		"terse":["That one's from {enemy}. Watch their hands."],
		"grand":["{enemy} sends us staring guards now."],
		"plain":["Someone from {enemy}, in our hall.","{enemy}, here. After all that.","I don't trust anyone from {enemy}."],
		"wry":["{enemy} sent their friendliest face, I see."],
		"cool":["{enemy} wants a good look at us."],
		"kind":["They're tired too. Look at them."],
		"fussy":["Watch them all the way out."],
		"child":["Are they the bad ones?"],
	},
	"company_gawk":{
		"plain":["They've never seen a hall like it.","Close your mouths, friends.","Look at them looking."],
		"wry":["Their guard's counting our roof poles.","They like our roof, at least."],
		"terse":["Staring."],
		"cool":["Let them look. Let them tell it."],
		"kind":["First time here. Let them look."],
		"fussy":["Don't touch anything, please."],
		"grand":["Let them take this sight home."],
		"child":["They're staring at our roof!","They keep looking up!"],
	},
	"gifted":{
		"plain":["Watch that one.","Where did {name} learn that?","{name} again. Look."],
		"terse":["Sharp, that one."],
		"kind":["{name} isn't afraid of anything.","Let {name} be. Look at that."],
		"cool":["Remember {name}'s face."],
		"wry":["{name} will be running this hall."],
		"fussy":["Hands still, {name}. Oh. Well."],
		"grand":["Look at {name}. Just look."],
		"child":["{name} does that all the time.","{name}'s always doing that."],
	},
	"envoy_haughty":{
		"plain":["Sniff all you like.","Who does that one think they are?","Look at that nose go up."],
		"terse":["Proud, that one."],
		"cool":["Let them sniff. They came to us."],
		"wry":["Our hall offends them. How sad."],
		"fussy":["Our hall is perfectly clean."],
		"grand":["Sniff at us? In our god's hall?"],
		"kind":["Long journey. Let them be proud."],
		"child":["Why's that one making a face?","That one smells something!"],
	},
	"envoy_nervous":{
		"plain":["It's only the dog.","Our dog won't bite. Probably.","Easy. It's a dog."],
		"wry":["Scared of the dog. Good start."],
		"terse":["Jumpy."],
		"kind":["Poor thing. Calm down."],
		"cool":["Frightened of a dog. Interesting."],
		"fussy":["The dog was here first."],
		"grand":["They fear our dog. Good."],
		"child":["Our dog scared them!","It's just our dog!"],
	},
	"envoy_greedy":{
		"plain":["Counting our things, that one.","Keep an eye on the baskets.","Watch our stores while they're here."],
		"cool":["That one's pricing our hall.","Already counting what they'll ask for."],
		"wry":["Shall we tell them the price?"],
		"terse":["Greedy eyes."],
		"fussy":["Don't touch the baskets, please."],
		"grand":["They look at our hall like buyers."],
		"kind":["Let them look. It costs us nothing."],
		"child":["Why's that one looking at our stuff?"],
	},
	# Hungry eyes on food from the stores, or a food gift carried in.
	"boon_hungry":{
		"plain":["{amount} food, to one person.","I'd have knelt for {amount} food.","{amount} food. And us with {food_days} days."],
		"terse":["{amount} food. {food_days} days left in store."],
		"wry":["{amount} food. I stood in the wrong place.","Next time, I'm standing where {name} stands."],
		"grand":["{amount} food, and {food_days} days in store."],
		"cool":["{name} eats well, then."],
		"kind":["{name} will share it. I hope."],
		"fussy":["{amount} food. From stores of {food_days} days."],
		"child":["Is all that food for {name}?","Can I have some of {name}'s?"],
	},
	"gift_food_hungry":{
		"plain":["Tell me it's food.","{amount} food. Thank them twice.","Food. Real food."],
		"terse":["{amount} food. Good.","We needed that."],
		"wry":["{amount} food. I like these people.","{amount} food. I could kiss that bearer."],
		"cool":["{amount} food. Nobody gives that for nothing."],
		"kind":["Some families will eat properly now."],
		"fussy":["{amount} food. Count it before we thank."],
		"grand":["{amount} food. Remember who fed us."],
		"child":["Is that all food?","Can we eat it now?"],
	},
	"gift_refused":{
		"plain":["All that way, and back again.","Those poor bearers.","Carry it home again. Ouch."],
		"wry":["I'd carry it back for them. Halfway.","Their arms will remember us."],
		"cool":["They'll remember carrying it home."],
		"terse":["Back it goes."],
		"kind":["Someone help that bearer."],
		"fussy":["Refused. Unopened. Well."],
		"grand":["They will tell this at home."],
		"child":["Why are they taking it back?","Is it too heavy?"],
	},
	"gift_refused_hungry":{
		"plain":["{amount} food, back out the door.","{food_days} days in store, and we refuse food?","There goes {amount} food. Walking."],
		"terse":["{amount} food sent back.","{amount} food. Gone."],
		"wry":["{amount} food. I'll just watch it go."],
		"cool":["{amount} food refused. Proud of us?"],
		"kind":["Someone was going to eat that."],
		"fussy":["With {food_days} days left. Refused."],
		"grand":["We refuse {amount} food. Hungry and proud."],
		"child":["They're taking the food away!"],
	},
	"bless_envy":{
		"plain":["{name}. Of course.","Blessed. {name}. Naturally.","Why {name}? Why always {name}?"],
		"wry":["I'll stand nearer the front next time.","{name} again. What a surprise."],
		"cool":["{name} has a friend above.","{name} knows where to stand."],
		"grand":["{name}, raised over us."],
		"fussy":["Well. I'm sure {name} deserved it."],
		"terse":["{name}. Again."],
		"kind":["Good for {name}. I suppose."],
	},
	"penance_hungry":{
		"plain":["A fast. We're halfway there already.","{name} has to fast. We do it free.","Fasting, with these stores? Easy."],
		"wry":["A fast? I've been practising for days.","{name} fasts. We call it supper."],
		"terse":["A fast. With {food_days} days left."],
		"cool":["A fast. Cheap penance, these days."],
		"kind":["{name} can share our hunger, then."],
		"fussy":["A fast, with {food_days} days in store."],
		"grand":["{name} fasts. The whole hall fasts already."],
		"child":["We fast every day now.","What's a fast? Is it this?"],
	},
	"refused":{
		"plain":["That's a no, then.","Poor {name}.","No. Just like that."],
		"cool":["{name} won't ask twice.","{name} should have asked differently."],
		"terse":["No, then."],
		"kind":["Next time, {name}.","Chin up, {name}."],
		"wry":["{name} came in hopeful, at least."],
		"fussy":["Well, {name} did ask."],
		"grand":["Refused. Before us all."],
		"child":["Is {name} in trouble?"],
	},
	"promise_deflate":{
		"plain":["Consider it. That means no.","{name} has heard that before.","Considered. So, not today."],
		"wry":["Considered. Like the last time.","{name} will be considering it for years."],
		"cool":["Give it a season, {name}.","Consider it. Nobody will."],
		"terse":["Not yet, then."],
		"kind":["It might still come, {name}."],
		"fussy":["Considered is not refused, {name}."],
		"grand":["{name} waits on the god's thinking."],
		"child":["Did they get it or not?"],
	},
	"absurd":{
		"wry":["I'll start on that. Very slowly.","Right. I'll get right on that."],
		"plain":["What did the god mean?","Does anyone know what that means?"],
		"cool":["Nothing will come of that. Watch."],
		"fussy":["I'm sure it made sense up there."],
		"terse":["Hm.","Right."],
		"kind":["Somebody help them with that."],
		"grand":["The god has spoken. Somehow."],
		"child":["What did the god say?","Can anyone do that?"],
	},
	"storm_out":{
		"plain":["Well. That went badly.","That could have gone better."],
		"wry":["{name} forgot to bow. On purpose.","Lovely visit. Do come again."],
		"cool":["We'll hear from {envoy_civ} about this.","{envoy_civ} will hear all about this."],
		"terse":["Gone, then."],
		"kind":["Let them cool off."],
		"fussy":["No bow. Not even a small one."],
		"grand":["Let {envoy_civ} hear how we answer."],
		"child":["Why didn't {name} bow?","They're cross!"],
	},
	"wait_doze":{
		"plain":["{name}'s asleep again.","There goes {name} again."],
		"wry":["{name} has the right idea.","{name} will wake for the end."],
		"terse":["Asleep."],
		"kind":["Let {name} sleep. Long day."],
		"fussy":["{name}. Upright, please."],
		"cool":["{name} could sleep standing in a river."],
		"grand":["{name} sleeps while a god thinks."],
		"child":["{name} is sleeping again!","{name}'s snoring!"],
	},
	"wait_long":{
		"plain":["Is the god still thinking?","How long do we stand here?"],
		"wry":["I've grown since we came in.","My feet were younger when we came in."],
		"terse":["Waiting."],
		"kind":["Patience. The god is thinking."],
		"fussy":["We have been standing a long while."],
		"cool":["Let them sweat a little."],
		"grand":["Still the god thinks. Still we stand."],
		"child":["Is it over? Can we go?","I need to sit down."],
	},
	# The officials' own ways (court_director.gd quirk_of).
	# The pedant, under their breath, about the number just said.
	"pedant":{
		"terse":["{number}. I counted.","That's {number}. Exactly {number}."],
		"plain":["{number}. Not one more.","I make it {number}, yes."],
		"fussy":["{number}, to be precise.","Exactly {number}. I checked."],
		"cool":["{number}. I'll remember that."],
		"wry":["{number}. I was hoping someone would say it."],
		"grand":["{number}. Let it be counted right."],
		"kind":["{number}. I just like to be sure."],
	},
	# About the flatterer, who agrees with the god harder than anyone.
	"flatter":{
		"plain":["Listen to {name}. Every word, a nod.","{name} agrees with the god. Again."],
		"wry":["{name} would clap at a sneeze.","Careful, {name}. You'll wear out your head."],
		"cool":["{name} always claps first."],
		"terse":["{name}. Clapping."],
		"fussy":["Nobody claps in here, {name}."],
		"grand":["{name} praises the god for us all."],
		"kind":["{name} means it. Probably."],
		"child":["Why is {name} clapping?"],
	},
	# About the sleepy one, caught yawning.
	"yawn":{
		"plain":["Are we keeping you up, {name}?","{name}. Mouth closed."],
		"wry":["Tired of standing, {name}?","Yawn later, {name}."],
		"terse":["Wake up, {name}."],
		"kind":["Sit after, {name}. Soon."],
		"fussy":["{name}, you yawned at the god."],
		"cool":["Everyone saw that yawn, {name}."],
		"grand":["{name} yawns in a god's hall!"],
		"child":["{name} yawned so big!"],
	},
	# The jealous one, about the one just favoured.
	"jealous":{
		"plain":["Why {other}? Why always {other}?","{other}. Of course it's {other}."],
		"wry":["I bowed too. Nobody noticed.","Next time I'll trip on purpose."],
		"cool":["{other} will want more now.","{other} has a friend above."],
		"terse":["{other}. Again."],
		"fussy":["I've served longer than {other}."],
		"grand":["{other}, over me. We'll see."],
		"kind":["Good for {other}. Really."],
	},
	# About the one who agrees with everyone.
	"yes_man":{
		"plain":["{name} agrees with everyone.","{name} nodded at both of them."],
		"wry":["{name} would agree with the goat.","{name} agrees. With whom, though?"],
		"cool":["{name} waits to see who's winning."],
		"terse":["{name}. Nodding."],
		"fussy":["{name}, pick one. Please."],
		"kind":["{name} just wants everyone happy."],
		"grand":["{name} bends whichever way we lean."],
		"child":["{name} keeps nodding!"],
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

## Only this family's own lines for the situation (the caller adds the plain
## speech of the hall after them).
static func own_lines(situation:String,manner:String)->Array:
	return (LINES.get(situation,{}) as Dictionary).get(manner,[])

## How many lines a situation has, all manners together.
static func count(situation:String)->int:
	var n:=0
	for manner in (LINES.get(situation,{}) as Dictionary):n+=((LINES[situation] as Dictionary)[manner] as Array).size()
	return n

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
