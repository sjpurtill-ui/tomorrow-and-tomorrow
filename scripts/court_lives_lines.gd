extends RefCounted
## Offline words for court_lives.gd: mourning, successors, omens, callbacks,
## and the first words of a reply to the god's order. Every line is original,
## short, and era-safe for a stone-age band (character_voice.gd gates still
## filter each one). Banks are keyed by the speaker's lifelong manner
## (character_voice.gd VOICE_MODELS); GENERIC covers anyone else.
##
## Tokens: {dead} the dead one's given name, {office} their title, {deed} what
## they did for the people, {years} how long they served, {own} what a
## candidate says of themself, {order} the god's words, {wish} what the god
## asked of the sky, {sign} what the world did, {since} a past order, {change}
## what came of it.

const BANKS:={
	"ahab":{
		"mourn":["{dead} chased the cold all their life and never once turned back. Now the cold has them.","I will not weep. I will remember {dead}, who {deed}, and I will hunt what took them.","The fire is lower tonight. {dead} fed it {years}. Mark the gap."],
		"pitch":["Give me the fire and I will hold it against every wind. I have {own}.","I do not ask. I tell you what I am: one who has {own}, and will not stop."],
		"open":["Hear that, all of you.","Then we hunt.","I'll pass the word tonight.","Good, a thing worth chasing.","That will change things here.","At last, an order I can put my back into."],
		"quote":["“{order}” — I'll run it down to the last cold river.","“{order},” you say, and I'll bend every back to it."],
		"omen":["You called for {wish}, and {sign}. The sky itself heard you. I saw it.","{sign}. After your word. Tell me that is chance and I will laugh at you."],
		"callback":["Since {since}, {change} The hunt turned, as you said it would.","I've watched it since {since}. {change}"]},
	"judge":{
		"mourn":["{dead} gave {years} of service, and they {deed}. No one here is ready to do that in their place.","{dead} taught the others well. We will soon find out how well.","Observe how quiet the circle is without {dead}. No one has spoken up in their place."],
		"pitch":["I have {own}. You may weigh the others; I have already weighed them.","Choose as you like. But I have {own}, and the others know it."],
		"open":["Consider it calmly.","The thing is simple.","A curious order. It will be done.","Very well. We will see what it costs.","I see the shape of it already.","An interesting order. I will watch how they take it."],
		"quote":["“{order}.” It sounds small, but people will feel it for years. It will be done.","You say “{order},” and the people will do it, whatever they think of it."],
		"omen":["You asked for {wish}. {sign}. I do not believe in chance. Neither, now, do they.","{sign}, and every mouth in the camp says your name. Remarkable."],
		"callback":["Since {since}, {change} It took longer to show than I expected.","Consider what followed {since}. {change}"]},
	"atticus":{
		"mourn":["{dead} {deed}, and asked nothing for it. I'd like that said plainly.","We owe {dead} a fair memory. {years} they served, and served us well.","In fairness to {dead}, they did right when it was hard."],
		"pitch":["I'd serve honestly. I have {own}; I hope that counts for something.","You'll choose fairly, I know. For my part, I have {own}."],
		"open":["Plainly, and with respect.","Let's be fair about this.","I understand you.","Very well; I'll see to it.","It can be done, and done decently.","I'll tell you honestly how it stands."],
		"quote":["“{order}” — I'll carry it out, and carry it out fairly.","You've asked that we {order_low}, so we will, as decently as we can."],
		"omen":["You asked for {wish}, and {sign}. I won't claim more than I saw, but the people are claiming it for you.","{sign}. People say it came because you spoke. I can't prove them wrong."],
		"callback":["Since {since}, {change} I thought you should hear it from me.","It's been a while since {since}. Honestly: {change}"]},
	"lincoln":{
		"mourn":["{dead} was the kind of neighbour who shows up before you ask. They {deed}.","There's an old stump by the river that {dead} used to sit on. It'll be a lonely stump now.","{years} {dead} carried us. We'll carry their name a while."],
		"pitch":["I'm no great talker, but I have {own}. I'll do the job and not make a fuss about it.","The way I see it, I have {own}, and I'd keep at it."],
		"open":["Here's how I see it.","Put it this way.","Well, that's a clear enough word.","All right, we'll put a shoulder to it.","That's a real job of work, but we'll get it done.","I've heard harder asks."],
		"quote":["“{order}” is plain enough, and we'll get it done.","So it's {order_low}, and that's what we'll do."],
		"omen":["You said {wish}, and {sign}. The old folks are telling it already, and they'll tell it better every time.","{sign}. Could be chance. Try telling that to anyone at the fire tonight."],
		"callback":["Since {since}, {change} Funny how things come round.","The way I see it, since {since}, {change}"]},
	"grant":{
		"mourn":["{dead} {deed}. Did the work. That is the whole of it.","We lost {dead}. {years} in the office. Good service.","{dead} is dead. The work they started goes on."],
		"pitch":["I have {own}. I will do the work.","Appoint me and it gets done. I have {own}."],
		"open":["Understood.","It will be done.","Clear order; we move.","Right, starting now.","Yes, I have what I need.","No need to talk it over. Starting."],
		"quote":["“{order}” — understood, and moving on it.","Order heard, {order_low}, and hands are on it."],
		"omen":["You asked for {wish}. {sign}. People noticed.","{sign}, after your order. The camp talks of nothing else."],
		"callback":["Report on {since}: {change}","Since {since}: {change}"]},
	"falstaff":{
		"mourn":["{dead}! Gone! And owing me a haunch, too. They {deed}, bless them.","I'd drink to {dead} if anyone had left me a cup. {years} of good company.","Sad day. {dead} laughed at my jokes, and nobody else ever did."],
		"pitch":["Me? Why, I have {own}, and I eat less than you'd fear.","Choose me and the fire stays merry. Also I have {own}."],
		"open":["Ha, now there's an order!","Oh, splendid.","By my belly, a big ask.","Well, well, somebody will sweat.","A bold word, and I love a bold word.","Heavens, yes, mostly yes."],
		"quote":["“{order},” and who'll do the hard part, I wonder?","{order_cap}, says the god, so {order_low} it is, and supper after."],
		"omen":["You asked for {wish} and — ha! — {sign}! I'll take credit for standing nearby.","{sign}! After your word! I nearly dropped my meat."],
		"callback":["Since {since}, {change} And I said so. Didn't I? I meant to.","Remember {since}? Well: {change}"]},
	"aurelius":{
		"mourn":["{dead} is gone. They {deed}, and we still have the good of it.","{dead} lived well and did their share. I cannot ask more of anyone.","{years} of duty, quietly done. Let us be as {dead} was."],
		"pitch":["I would serve without wanting praise for it. I have {own}.","The choice is yours and rightly. I have {own}; that is all I would say."],
		"open":["It is within our power.","So be it.","Let it be done without complaint.","A duty, then.","We will do what the hour asks.","Nothing here is beyond us."],
		"quote":["“{order}.” It is work, and we have the hands for it.","You bid us {order_low}, and we will, without complaint."],
		"omen":["You asked for {wish}, and {sign}. Whether it answered you I cannot know. The people have decided.","{sign}. The people are sure it was you."],
		"callback":["Since {since}, {change} It came of what we did, nothing more.","Look what came of {since}. {change}"]},
	"iago":{
		"mourn":["Poor {dead}. They {deed}. Some of us will miss them.","{dead} served {years}. Give it a month and half the camp will have forgotten.","Such a loss. And such an empty seat, too."],
		"pitch":["I'm only a humble servant. Though I have {own}, as it happens.","Others will tell you what they are. I have {own}; judge by that."],
		"open":["Oh, wisely said.","Yes. I know just who to give it to.","I'd have said the very same.","They'll do it, and I'll see they don't complain.","Leave it with me.","Nothing could be simpler."],
		"quote":["“{order}” — oh, it will be done, and I'll watch who grumbles.","{order_cap}, yes, and I'll see who drags their feet."],
		"omen":["You asked for {wish}, and — how fortunate — {sign}. I'll see the right people hear of it.","{sign}. I've already told the doubters, in case they missed it."],
		"callback":["Since {since}, {change} I did keep an eye on it for you.","Since {since}, {change} Some are grateful. Some pretend."]},
	"elizabeth":{
		"mourn":["{dead} was never dull, which I'd count as the highest praise. They {deed}.","We shall all be poorer in conversation without {dead}.","{years} {dead} put up with us. That alone was heroic."],
		"pitch":["I'd hardly praise myself, but I have {own}, and I'd not bore you.","Choose as you like; only know I have {own}."],
		"open":["How very decided.","Well, that will give them something to talk about.","I see.","Then we'd better be quick about it.","A bold word; I rather like it.","Very well, though I have thoughts."],
		"quote":["“{order},” and they'll grumble, and then they'll do it.","So we are to {order_low}, and I'll make sure it's done properly."],
		"omen":["You asked for {wish}, and {sign}. The whole camp is insufferable about it.","{sign}. I'd call it chance, but nobody wants my opinion tonight."],
		"callback":["Since {since}, {change} I thought you'd like to know.","You'll remember {since}. Well: {change}"]},
	"achilles":{
		"mourn":["{dead} {deed}. I want every child here to know it.","I would trade my years for one more of {dead}'s. They served {years}.","Sing {dead}. Loudly, so the neighbours hear what we lost."],
		"pitch":["Give it to me. I have {own}, and I do not fail.","There is no one here fit for it but me. I have {own}."],
		"open":["Now that is worthy.","Yes, let it be glorious.","At last, something to do.","I will make them remember it.","Gladly.","Say no more."],
		"quote":["“{order}” will be done so they sing of it.","You want them to {order_low}, and they will, gloriously."],
		"omen":["You asked for {wish}, and {sign}! Even the sky knows who rules here.","{sign}! Let every neighbour hear it."],
		"callback":["Since {since}, {change} Glory is slow, but it comes.","Since {since}: {change}"]},
	"sancho":{
		"mourn":["{dead} was a good one. Their basket was never empty. They {deed}.","My old mother buried half her friends before she went. {dead} was one of the good ones.","{years} they worked. That's a long walk for short legs."],
		"pitch":["Me? I've {own}. I'm no talker, but I get the job done.","A plain helper for a plain job: I've {own}."],
		"open":["Well, you're the one who decides.","Right you are.","If you say so, then so it is.","Oof, some will sweat for that.","I'll go and tell the others.","No point moaning. Let's get on with it."],
		"quote":["“{order}” — that's a lot of work, but we'll get through it.","{order_cap}, is it, then {order_low} we shall."],
		"omen":["You asked for {wish}, and {sign}! I never thought I'd see it.","{sign}! My knees are knocking still."],
		"callback":["Since {since}, {change} So that's what came of it.","Remember {since}? Here's the tale: {change}"]},
	"polonius":{
		"mourn":["{dead}, who {deed}, was — and I will be brief — a most excellent servant.","In brief, {dead} served {years}, and served well.","I say it once: {dead} is gone, and no one here knows their work as they did."],
		"pitch":["I shall be brief. I have {own}, and more besides, which I will not list.","I will not boast. I will only say: I have {own}."],
		"open":["Most wisely commanded.","I would advise the same, and briefly.","I will see to it at once.","Let it be done, and let me say so.","This is the right course.","In brief: yes."],
		"quote":["“{order}” is a fine order, which I shall see done, and done in order.","To {order_low} is most apt, and it shall be so."],
		"omen":["You asked for {wish}, and — mark it — {sign}. I said as much, or nearly.","{sign}. I will be brief: the people are astonished."],
		"callback":["Since {since}, {change} Which, briefly, I foresaw.","As to {since}: {change}"]},
	"cicero":{
		"mourn":["Who among us {deed} as {dead} did? None. Let that stand as their praise.","For {years} {dead} served this people. Shall we let that be forgotten? We shall not.","Who will do what {dead} did, now?"],
		"pitch":["Set my record beside theirs. I have {own}. The case makes itself.","I will not flatter the court. I have {own}; judge me on it."],
		"open":["It is just, and I will say so to anyone.","Who could argue with that?","A command worth defending.","I will argue it to every hearth.","Let no one say it was not wise.","Consider how well this answers."],
		"quote":["“{order}” — I will make the people understand why.","You say {order_low}, and I will persuade them it was their own idea."],
		"omen":["You asked for {wish}. And then? {sign}. Who could doubt you now?","{sign}! What more proof does any doubter need?"],
		"callback":["Since {since}, {change} I put it to you: was it not well done?","Look what followed {since}. {change}"]},
	"lear":{
		"mourn":["{dead}! {dead}! They were well this morning!","They {deed}. And now nothing. Nothing.","Howl for {dead}. {years} they sat at this fire, and now their place is empty."],
		"pitch":["I am old in heart, but I have {own}. Do not cast me aside.","Choose me and I will be true. I have {own}."],
		"open":["So you command.","Ha, a word from on high!","Let it be so, then.","Aye, aye, it shall be done.","The whole camp will shake with it.","Well, well, as you will."],
		"quote":["“{order}” shall be done, though the heavens grumble.","To {order_low}, then, and so be it."],
		"omen":["You cried for {wish}, and {sign}. Even the storm obeys you. Not I, but the storm!","{sign}. The whole camp is on its knees."],
		"callback":["Since {since}, {change} Mark how it turned.","Since {since}: {change} I did not think it would."]},
	"churchill":{
		"mourn":["{dead} {deed}. Few of us did as much.","We shall remember {dead}. {years} of service, and not one day wasted.","The fire burns lower tonight. We shall build it up again, for {dead}."],
		"pitch":["I have {own}. I offer nothing but hard work, and more of it.","Give me the charge. I have {own}, and I do not give up."],
		"open":["We shall do it.","Very good, and to work.","A stout command.","Then let us begin, and not stop.","We shall not flinch from it.","Splendid; the harder, the better."],
		"quote":["“{order}” — we shall see it through, whatever it costs.","To {order_low}: we shall, and gladly."],
		"omen":["You asked for {wish}, and {sign}. The people will not forget this hour.","{sign}. I have never heard the camp so loud."],
		"callback":["Since {since}, {change} That is what came of it.","Since {since}: {change}"]},
}

const GENERIC:={
	"mourn":["{dead} {deed}. We will say their name at this fire for a long time.","{years} {dead} served us. The circle is smaller tonight.","{dead} is gone. Their family will need looking after."],
	"pitch":["I have {own}. I would serve, if you will have me.","I have {own}. Choose as you will."],
	"open":["As you say.","It will be done.","I hear you.","Then that is the word.","We will set to it."],
	"quote":["“{order}” — it will be done.","We are to {order_low}, and so it will be.","“{order},” then, and the people will hear it tonight.","So the word is {order_low}, and we will see to it."],
	"omen":["You asked for {wish}, and {sign}. The whole camp is talking.","{sign}, after your word. People are afraid and glad at once."],
	"callback":["Since {since}, {change}","It has been a while since {since}. {change}"],
}

## Openers keyed by the speaker's public demeanour
## (GovernmentPeopleSystem.leader_disposition).
const DISPOSITION_OPEN:={
	"sycophantic":["A wise and far-sighted word.","What a word; the people will marvel.","You see further than any of us.","Nothing could please us more.","It is already as good as done.","I'll start at once."],
	"cantankerous":["I have heard you.","If it must be done, it must.","Hm, well, you are the one who decides.","I have doubts, but I'll carry it.","That will cost us, but so be it.","Fine, but don't say I didn't warn you."],
	"principled":["I will answer plainly.","Then I will do it, and tell you the truth of it.","Honestly, yes, it can be tried.","You'll have a straight answer.","I'll carry it out, and report what really happens.","It is clear, and I'll do it."],
	"diplomatic":["I believe I can make this workable.","Let me find a way everyone can live with.","I'll bring the hearths along with me.","It can be done, gently.","We'll manage it without breaking anyone.","I'll talk it through at every fire."],
	"pragmatic":["I understand.","All right, here is how it goes.","That's workable.","Good; it's clear.","I'll see to it.","We can start at once."],
}

## What a candidate says they have done, by their strongest skill.
const OWN:={
	"Administration":["settled more quarrels between hearths than I can count","kept the shares fair when the stores ran thin","held the circle together through bad seasons"],
	"Provisioning":["kept the stores full through two lean winters","found food when the hunters came home empty","counted every basket and lost none"],
	"Construction":["raised the windbreaks and the long hut","rebuilt what the storms tore down","set the poles for half the shelters here"],
	"Logistics":["found the ford nobody else could find","carried loads across the ridge in the snow","brought every party home by the shortest path"],
	"Knowledge":["remembered what the rest of you forgot","read the sky before every storm","kept the old stories straight"],
	"Defense":["stood the night watch when the wolves came close","kept the young spears ready","walked the ridge every night of the hard winter"],
	"Diplomacy":["brought strangers to our fire without blood","talked down more angry men than I can count","carried word to the neighbours and came back whole"],
}
## What the dead did for the people, by their strongest skill.
const DEEDS:={
	"Administration":["kept the peace between the hearths","settled our quarrels before they became feuds","kept the shares fair when the stores ran low"],
	"Provisioning":["kept the stores through the lean seasons","fed us when the hunt failed","never let a basket go to waste"],
	"Construction":["raised the shelters we sleep in","set the poles of the long hut","mended every roof the storms tore"],
	"Logistics":["found the paths nobody else could","brought every party home","carried us over the ridge in the snow"],
	"Knowledge":["remembered what the rest of us forgot","read the sky for us","kept the old stories true"],
	"Defense":["stood the night watch when the wolves came close","kept the young spears ready","walked the ridge in the worst of the cold"],
	"Diplomacy":["brought strangers to our fire without blood","talked down angry men","carried our word to the neighbours"],
}

## The god's words about the sky, and how the court names them.
const WISHES:={
	"rain":{"terms":["rain","storm","water from the sky","clouds","wet the","drought"],"wish":"rain","sign":["the rains came","rain fell on the dry ground","the sky opened and the streams rose"]},
	"dry":{"terms":["stop the rain","end the rain","sun to shine","make the sun","dry the","stop the flood"],"wish":"the sun","sign":["the rain stopped and the sun came out","the ground dried and the sky cleared"]},
	"winter":{"terms":["stop the winter","end winter","end the winter","end the cold","bring the spring","make it warm","warm the"],"wish":"an end to the cold","sign":["the thaw came","the cold broke and the ice went out of the streams"]},
	"harvest":{"terms":["good harvest","make the fields","plenty","feed us","full stores","make food","bring food","abundance","game to come","herds to come"],"wish":"plenty","sign":["the gathering came in rich","the baskets came home heavy"]},
	"healing":{"terms":["cure","heal","end the sickness","stop the fever","make them well","end the plague","drive out the sickness"],"wish":"healing","sign":["the fevers broke","the sick began to rise from their mats"]},
}

## An old order, named the way the court remembers it.
const SINCE_BY_NATURE:={
	"feast":"the feast","worship":"the prayers you asked of us","monument":"the work on your likeness","defense_works":"we raised the works","human_sacrifice":"the sacrifice",
	"prohibition":"your ban","punishment":"the punishment","exile":"the exile","relocation":"we moved the camp","welcome":"we took in the strangers","hunt_beast":"the great hunt",
	"rename":"the renaming","marriage":"the pairings","polygamy":"the men took more wives","teaching":"the young began their lessons","sanitation":"the new rules for water and waste",
	"planting":"we put seed in the ground","clear_land":"we cleared the trees","conservation":"we left the land to rest","work_harder":"you drove the work harder","rest":"the days of rest",
	"trade":"we sent goods to the neighbours","raid":"the raid","enslave":"we took the captives","mercy":"your mercy","segregation":"men and women went to separate fires",
	"intoxicants":"the cups went round","custom_art":"the new custom","gathering_goods":"the gathering drive","fishing":"we put more hands on the water","fasting":"the fast",
	"informers":"you set watchers at every hearth","communal_children":"the children went to one fire","miracle":"your word to the sky","selective_breeding":"your pairing of the households","selective_family":"you favoured the clever households",
}
## What changed, in plain words: [rose, fell].
const CHANGE_WORDS:={
	"cohesion":["the households share their fires more","there is bad blood between some hearths"],
	"legitimacy":["people speak your name with more awe","some mutter against you at the edges of the camp"],
	"health":["people look stronger","more of us are sick than before"],
	"security":["the camp sleeps easier at night","the camp feels less safe at night"],
	"knowledge":["the young are sharper at their reckoning","less is being learned than before"],
	"food":["the stores are fuller","the stores have thinned"],
	"population":["there are more mouths at the fires","there are fewer of us"],
	"births":["{n} children have been born","no child has been born"],
	"deaths":["we have buried {n}","we have buried no one"],
}

## First words of a rite on the map, and of the court when the sky agrees.
const RITE_WORDS:={"bonfire":"a great fire","cairn":"a cairn of stones","procession":"a procession around the camp","stone":"a standing stone","pyre":"a funeral fire"}

## "No one has ever done such a thing" — the attempt at a miracle, by wish.
const MIRACLE_ACTS:={
	"rain":["I will have the rain-dancers on the dry bank before dawn","I will have the drums beat for rain from dusk to dawn"],
	"dry":["I will keep the smoke-fires going to push the clouds away","I will have the elders sing the sun up"],
	"winter":["I will keep every fire high and the drums going through the dark","I will have the young ones carry fire around the camp each night"],
	"harvest":["I will have offerings laid at every gathering ground","I will send the singers out with the gatherers"],
	"healing":["I will have the herb-finders and the singers sit with every sick one","I will have the sick carried past your fire each morning"],
	"dead":["I will have the old ones sing over the mound until their voices go","I will keep a fire burning on the burial mound"],
	"any":["I will try it, with every rite we know","I will have the whole camp dance for it","I will do what the old ones did when they asked the world for more than it gives"],
}
const MIRACLE_LEADS:=["No one has ever done such a thing, but","It has never been done. Still,","Nobody alive has seen it done; all the same,"]
const MIRACLE_RISKS:=["If nothing comes of it, people will wonder why.","If the sky stays silent, some will start to doubt.","If it fails, the doubters will say so loudly."]
const CAPACITY:={
	"high":["We have the hands and stores to carry {topic} through.","{topic_cap} can be done properly; we are strong enough for it.","Most of {topic} can be carried through as you want it.","We are well placed for {topic}, and it will show."],
	"mid":["The heart of {topic} will be done, though the edges may fray.","{topic_cap} can mostly be done; thin hands may leave gaps.","We can carry the main part of {topic}.","Most of {topic}, yes, though not all at once."],
	"low":["We can make a visible start on {topic}, but not every part at once.","{topic_cap} will be a start, not the whole of it.","We can begin {topic}, but a good part will wait for more hands.","We can start {topic} where people will see it, and grow it later.","Only the first part of {topic} can be carried now."],
	"narrow":["Only a narrow attempt at {topic} is possible with what we have.","{topic_cap} will be a small attempt; we have little to spare.","We can only try {topic} in a small way.","A thin attempt at {topic} is all we can manage now."],
}
## Underway, and when they will report: {topic} and {when}.
const REPORT_BACK:=["It has begun, and I will report back around {when} on how {topic} went.","People are already moving on {topic}; I will report back around {when}.","The first hands are on {topic}, and I will report back around {when}.","Work on {topic} starts today; I will report back around {when}.","It is underway, and I will report back around {when} on what came of {topic}."]
## What an order is called in a reply, by the nature of what was asked.
const TOPIC_BY_NATURE:={
	"feast":"the feast","worship":"the prayers","monument":"the work on your likeness","defense_works":"the works","human_sacrifice":"the offering","prohibition":"the ban",
	"punishment":"the punishment","exile":"the exile","relocation":"the move","welcome":"the welcome","hunt_beast":"the hunt","rename":"the new name","marriage":"the pairings",
	"polygamy":"the new wives","teaching":"the lessons","sanitation":"the new rules for water and waste","planting":"the planting","clear_land":"the clearing","conservation":"the resting of the land",
	"work_harder":"the harder work","rest":"the rest days","trade":"the trading","raid":"the raid","enslave":"the yoking of the captives","mercy":"the mercy","segregation":"the separate fires",
	"intoxicants":"the cups","custom_art":"the new custom","gathering_goods":"the gathering","fishing":"the fishing","fasting":"the fast","informers":"the watching of the hearths",
	"communal_children":"the children's fire","selective_breeding":"your pairing of the households","selective_family":"the favour to the clever households","miracle":"the rite",
}
const MIRACLE_TOPICS:={"rain":"the rain-calling","dry":"the sun-calling","winter":"the long fires against the cold","harvest":"the plenty-rites","healing":"the healing rites","dead":"the singing over the mound","any":"the rite"}
