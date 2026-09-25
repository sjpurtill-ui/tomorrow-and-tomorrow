extends RefCounted
## Offline words for the god's wrath and favour, and for the love or dread an
## official carries into any audience. Each literary manner (see
## character_voice.gd VOICE_MODELS) has its own lines; generic banks, built as
## opener x closer pairs, give every speaker fresh words for a long reign (the
## hall never lets a line be said twice). Every line passes the era gate and
## the imitation check before it is spoken. Nothing supernatural: the god's
## anger is presence and words; the guards carry out real decrees.
## Tokens as in audience_voice.gd: {address} {petitioner} {envoy} {civ}.

## Per manner. cower: breaking under wrath. defy: the proud standing under it.
## blessed: taking favour. witness_dread: an aside after wrath falls on another.
## witness_favor: an aside after favour falls on another.
const MODEL_BANKS:={
	"ahab":{
		"cower":["I have faced the great beast and never shook. I shake now.","Your storm has found me, {address}. There is no cave deep enough."],
		"defy":["Strike, then. I have stood in worse weather and kept my feet.","Rage on. I will still hunt what you set me to hunt."],
		"blessed":["Then I hunt for you to the last cold river.","Your favour is a fair wind. I will not waste it."],
		"witness_dread":["That anger could split a cliff. Keep low.","I know that look. It is the look of the beast rising."],
		"witness_favor":["Good. Now point them at the quarry.","Good. Now send them after something worth catching."]},
	"judge":{
		"cower":["I have studied fear all my life. I did not expect to learn it.","You have my attention entirely, {address}. Entirely."],
		"defy":["You are angry. I have noted it, and I still think I was right.","Instructive. Do go on."],
		"blessed":["A gift from the one who holds every life here. I will use it well.","Noted, and treasured. You do not give this often."],
		"witness_dread":["Watch their knees. The knees always go first.","Now everyone in this hall knows the true shape of things."],
		"witness_favor":["The others will work harder now, hoping for the same.","Watch the others smile. Half of them are wondering why it was not them."]},
	"atticus":{
		"cower":["I have wronged you, {address}, and I will set it right.","I am afraid, and I won't pretend otherwise."],
		"defy":["I will take your anger, {address}, but I will not unsay the truth.","Be angry with me. The facts are still the facts."],
		"blessed":["I don't know that I earned it. I'll try to.","That's a kindness I'll try to pass along."],
		"witness_dread":["That was hard to watch. Harder to bear.","After that, nobody here will bring you bad news willingly."],
		"witness_favor":["Praising them in front of everyone will make the others try harder.","That was decently done."]},
	"lincoln":{
		"cower":["I have been scolded plenty in my life, {address}, but never like that.","I will mend it, {address}, and quickly."],
		"defy":["A hard word, and I will bear it. I will not bend the truth to dodge it.","You may be angry with me and still be wrong, {address}."],
		"blessed":["More than I deserve, and I'll try to grow into it.","I'll carry that the way a man carries a good tool."],
		"witness_dread":["Frightened people hide their mistakes. We will hear less truth now.","Well, nobody will sleep tonight."],
		"witness_favor":["That cost you nothing, and the whole hall saw it. Well done.","That'll be talked of at every hearth by morning."]},
	"grant":{
		"cower":["Understood. It won't happen again.","Yes, {address}. Corrected."],
		"defy":["Heard. I stand by what I did.","Rage all you like. The work still needs doing."],
		"blessed":["Thank you. Back to work.","I'll earn it."],
		"witness_dread":["That settles who's in charge.","Everyone just got quieter. Useful."],
		"witness_favor":["Good. They'll work harder, and so will everyone watching.","Fair."]},
	"odysseus":{
		"cower":["{address}, I have talked my way past many dangers. Not this one.","I bow, {address}, and I stay bowed as long as you like."],
		"defy":["I have weathered wilder gods than you on longer roads.","Rage, then. I will wait out the storm, as I always have."],
		"blessed":["A gift from a god. I will tell of this all my days.","I will spin this into a tale for every hearth I pass."],
		"witness_dread":["Clever men keep their mouths shut now.","I've seen gods angry. Best to look very small."],
		"witness_favor":["There goes a tale they'll tell for a generation.","Note who is in favour now. People will start going to them for help."]},
	"lear":{
		"cower":["O, the storm is in the hall now, and I stand under it with nothing.","I am a small and shivering thing before you, {address}."],
		"defy":["Thunder at me, then! I have been thundered at by better storms.","Rage! I have raged too, and I am still standing."],
		"blessed":["O kindness, where I looked for none! I could weep.","You lift me up; I did not think anyone still would."],
		"witness_dread":["I would hide from that too, if there were anywhere to go.","We are all small tonight, all of us."],
		"witness_favor":["Them raised up, and the rest of us still waiting. I cannot keep up with you.","Tender now. Let us see how long it lasts."]},
	"falstaff":{
		"cower":["I am the smallest, humblest, thinnest creature here, {address}. Mercy.","Anger at me? I would faint, if fainting did not take such effort."],
		"defy":["Shout all you like; my courage is buried deep, but it is in there somewhere.","A great rage for such a small crime, {address}."],
		"blessed":["A blessing! I shall live on it for a week, with a little meat besides.","Bless me again; I have room."],
		"witness_dread":["I am suddenly very interested in the floor.","If anyone asks, I was never here."],
		"witness_favor":["Why them and not me? I am twice as deserving, by weight.","They are thin as a rake and they get the blessing. Unfair."]},
	"aurelius":{
		"cower":["I accept what I cannot change. Your anger I cannot change.","I have erred, and I will not waste words defending it."],
		"defy":["Your anger is yours, {address}. My duty is mine.","Be angry, {address}. I will keep doing my work while you are."],
		"blessed":["I will take this gift without clinging to it.","Gratitude, then, and back to the work."],
		"witness_dread":["Frightened people do the least they can. We will see less work now.","Stay still. This will pass, and then we get back to work."],
		"witness_favor":["Deserved, I think. Let no one envy it.","A good act, simply done."]},
	"achilles":{
		"cower":["I have never begged. I am close to it now.","Your anger burns hotter than mine, {address}. I did not think it could."],
		"defy":["Rage at me? I have faced death laughing. Rage away.","I will not kneel lower than this, whatever you say."],
		"blessed":["Honour from you is worth more than any spoils.","Now all of them know my worth."],
		"witness_dread":["There goes a man broken in public. I'd rather die.","All their standing, gone in one moment."],
		"witness_favor":["Honour given to another. I will earn more.","They shine now. Tomorrow it will be me."]},
	"iago":{
		"cower":["I am your creature, {address}, wholly. Command me.","Forgive me. I live only to serve you, {address}."],
		"defy":["Of course, {address}. You are always right.","Your anger is well deserved. I deserve it most of all."],
		"blessed":["Your generosity overwhelms me, {address}. Truly.","How kind. I shall not forget it. Ever."],
		"witness_dread":["Poor soul. I did warn them, quietly.","Now they will confess to anything you like. Briefly."],
		"witness_favor":["Such favour. It will be interesting to watch them fall.","How lucky for them. I wonder how long it lasts."]},
	"elizabeth":{
		"cower":["I confess myself entirely overpowered, {address}.","I have been foolish, and you have made very sure I know it."],
		"defy":["I will bear your displeasure, {address}, but not agree with it.","You may frighten me; you will not make me think I was wrong."],
		"blessed":["That is more kindness than I expected, and I am rarely surprised.","I am obliged to you, and not at all sorry to be."],
		"witness_dread":["Well. Nobody will be clever at supper tonight.","What a lesson in manners."],
		"witness_favor":["How generous. I hope it is deserved.","A pretty reward. Let us see if it is repaid."]},
	"nemo":{
		"cower":["I went to the deep to escape anger like this. It found me.","I am silent before you, {address}."],
		"defy":["I have known the anger of the depths. Yours is shallower.","Rage. I will not surface for it."],
		"blessed":["I did not look for kindness here. I accept it.","A rare calm. I will remember it."],
		"witness_dread":["Keep that up and nobody will speak honestly to you.","Another outburst like that and people will stop coming to you at all."],
		"witness_favor":["Good. People will come to you now instead of hiding.","Good. Rare, but good."]},
	"quixote":{
		"cower":["I have faced giants, {address}, but never one so terrible!","I yield, I yield, and I swear to amend it."],
		"defy":["Rage on, {address}! I will not take back a word, not one!","No anger will turn me from the right path!"],
		"blessed":["A blessing! I shall be worthy of it, I swear by every star!","This honour I will carry into every trial!"],
		"witness_dread":["A terrible and wondrous fury. We will speak of it for years.","Surely an enchantment has fallen on this hall!"],
		"witness_favor":["Well deserved, noble friend! Well deserved!","Honour rightly given! They fought hard for it!"]},
	"sancho":{
		"cower":["I'll do anything, {address}, only don't look at me like that.","My knees have gone to water. It won't happen again."],
		"defy":["Shout if you like. I still did it for a good reason.","Go on, then. I'll still be the one cooking supper after."],
		"blessed":["Oh, that's kind. That's very kind. I'll eat well tonight.","Now there's a good day come out of nowhere."],
		"witness_dread":["Glad it wasn't me. Very glad.","I'll be keeping my head down a week or two."],
		"witness_favor":["Good for them. Maybe some of it rolls my way.","That'll put meat on their table."]},
	"cicero":{
		"cower":["I, who have argued down every rival, have no argument left, {address}.","I submit, entirely and without reservation."],
		"defy":["I will hear your anger, and then I will state my case.","You are angry, {address}, but you have not said what I did wrong."],
		"blessed":["I shall speak of this generosity at every gathering.","A just reward, justly given. I am honoured."],
		"witness_dread":["Whoever speaks next had better speak well.","Anger in the hall. The envoys will hear of it."],
		"witness_favor":["A reward that will be long remembered and discussed.","Generous, and the others saw it. Well judged."]},
	"churchill":{
		"cower":["I have misjudged it badly, {address}. I will set it right at once.","I accept the rebuke. Fully."],
		"defy":["I will stand. I have stood through worse, and I will stand through this.","Shout if you like. I will not give up the ground."],
		"blessed":["Then we go on, stronger for it.","A great kindness, at a hard hour."],
		"witness_dread":["We shall have to be very steady now.","Grim hour. Hold the line."],
		"witness_favor":["Rightly done. The crews will work better for it.","Good. That will steady the council."]},
	"washington":{
		"cower":["I have failed in my duty, and I will make it good.","I will not offer excuses, {address}. Only amends."],
		"defy":["I have served you honestly. That does not change because you are angry.","I accept your displeasure. I do not accept that I acted wrongly."],
		"blessed":["I am grateful, and I will be careful with it.","Thank you. I will serve the better for it."],
		"witness_dread":["I would have held that back. People will remember it.","The council will not speak freely after that."],
		"witness_favor":["Deserved. The others will see that good work is noticed.","Well done, and well deserved."]},
	"queequeg":{
		"cower":["I am very sorry. Please, no more anger.","Your eyes are thunder, {address}. I am small."],
		"defy":["I stand. My fathers stood. I do not run.","Be angry. I am still here, still yours."],
		"blessed":["Good, good. I remember this always.","You honour me. I will honour you."],
		"witness_dread":["Very angry. Quiet now, all of us.","Everyone unhappy now. Quiet."],
		"witness_favor":["Good. They were loyal to you. Now everyone sees it.","Happy day for them."]},
	"heathcliff":{
		"cower":["I have feared nothing on the moor. I fear this.","Stop. Please. I will do whatever you say."],
		"defy":["Rage. I have lived in rage. It is my own country.","Hate me if you must. I have been hated before."],
		"blessed":["I don't know what to do with kindness. I'll keep it.","You have given me something no one ever has."],
		"witness_dread":["That will leave a mark that won't heal.","Now they'll hate you quietly for years."],
		"witness_favor":["Kindness. It won't last.","Watch the others. Some of them are already jealous."]},
	"prospero":{
		"cower":["Your power is greater than any I have known. I kneel to it.","I am undone, {address}. Command me."],
		"defy":["You are angry, {address}. I will wait until you are ready to hear me.","Tell me what I did wrong, {address}, and I will answer it."],
		"blessed":["A grace I did not look for. I am grateful.","Then all is mended, and I am glad."],
		"witness_dread":["Everyone in the hall is shaking. Nobody will argue with you now.","People will remember that outburst longer than whatever caused it."],
		"witness_favor":["Forgiving them was the harder choice. Good.","Well done. They will be more loyal for that than punishment would make them."]},
	"lady_macbeth":{
		"cower":["I have no strength left. I am yours.","I will do anything you require. Anything."],
		"defy":["Rage, then. I have hardened myself against worse.","You cannot frighten one who has already looked into the dark."],
		"blessed":["At last. The recognition I deserved.","You honour me. I will make sure it lasts."],
		"witness_dread":["Watch that one. They will go looking for someone to blame.","Now we see who is frightened. Watch who they run to."],
		"witness_favor":["Favour today. What of tomorrow?","Mark that. Ambition rewarded."]},
	"polonius":{
		"cower":["I humbly, very humbly, beg your pardon, {address}, in every particular.","I was wrong, entirely and completely, and briefly I will say so."],
		"defy":["With respect, and I say this with great respect, I stand by it.","Your anger, though great, does not alter the plain matter."],
		"blessed":["A great honour, and I shall speak of it, at length, to everyone.","I am grateful beyond words, and I have many words."],
		"witness_dread":["A sharp lesson. I shall remember it. At length.","Let us be very careful what we say next."],
		"witness_favor":["A wise reward, wisely given, as I would have advised.","Well done, and I say so."]},
	"nestor":{
		"cower":["In all my long years, I have not faced anger like this.","I am old, {address}, and I am afraid."],
		"defy":["I have seen many rulers rage, {address}. The good ones asked afterward what went wrong.","I have lived long enough to stand through your anger."],
		"blessed":["In my many years, few kindnesses have warmed me so.","The old are grateful. I thank you."],
		"witness_dread":["In my day, anger was kept for enemies.","I have seen halls empty after anger like that."],
		"witness_favor":["Good. The loyal ones will stay; I have seen the neglected ones leave.","That will be remembered long after us."]},
}

static func model_bank(persona:Dictionary,key:String)->Array:
	var bank:Dictionary=MODEL_BANKS.get(String(persona.get("model","")),{})
	return bank.get(key,[])

static func _pairs(openers:Array,closers:Array)->Array:
	var out:Array=[]
	for a in openers:
		for b in closers: out.append("%s %s" % [String(a),String(b)])
	return out

## Generic banks: [openers, closers]; each opener pairs with each closer.
const GENERIC:={
	"cower":[["Mercy, {address}.","I am dust before you.","Forgive me.","I meant no wrong.","Spare me your anger.","I am on my face before you.","My legs will not hold me.","Your anger is more than I can bear."],
		["I will do whatever you ask.","It will not happen again.","Only let the anger pass.","I am yours to command.","I will set it right at once.","Tell me what to mend and I will mend it.","I beg you, no more.","I will not fail you twice."]],
	"endure":[["I hear you, {address}.","I have earned that.","That was deserved.","I bow to it.","Your anger is just.","I will not argue."],
		["I will do better.","It will be put right.","I will carry it.","I will not forget this.","I will mend what I broke.","Say what you need."]],
	"defy":[["I hear your anger, {address}.","Rage if you must.","I have stood in worse storms.","I will bear it.","You may shout.","You have not said what I did wrong."],
		["I will not crawl.","I serve, but I do not grovel.","I still say what I said.","I will stand up when you are done.","The truth has not changed.","I am still here."]],
	"penance":[["I will fast, {address}.","I will keep the vigil.","The penance is fair.","I will pay it.","I will go hungry gladly.","I accept it."],
		["Until you are appeased.","Every night you ask.","And come back cleaner.","Without a word of complaint.","And remember why.","Before the moon turns."]],
	"relief":[["The fear goes out of me, {address}.","I can breathe again.","I thought I had lost you.","After your anger, this.","I did not dare hope for this.","My hands have stopped shaking."],
		["I will repay it.","I will not forget it.","Thank you.","I will serve all the harder.","I will not give you cause again.","It is more than I deserve."]],
	"blessed":[["You honour me, {address}.","I did not expect this.","This I will carry all my life.","My kin will hear of this.","Your favour warms me.","I am grateful."],
		["I will earn it.","I will not waste it.","I will serve the better for it.","I will tell it at every hearth.","Command me, and see.","It will be repaid in work."]],
	"witness_shaken":[["Keep your eyes down.","Nobody breathe.","That could be any of us.","I have never seen such anger.","Do not look up.","My heart is in my throat."],
		["Say nothing.","Wait for it to pass.","Not a word from anyone.","Stand very still.","Just nod.","Let it blow over."]],
	"witness_unbowed":[["That was too harsh.","They did not deserve all of that.","I would have taken it standing.","Hard words.","Nobody will speak up now."],
		["Someone should say so.","I will say it later.","Remember that I stood.","Mark it.","It will be remembered."]],
	"witness_execution":[["They are gone.","No one moved.","That was a life.","The hall is silent.","I saw their face as they went.","It was so quick."],
		["We will all remember this.","Nobody will argue with you for a long while.","I will not sleep tonight.","The whole realm will hear of it by morning.","Who is next.","Say nothing."]],
	"witness_exile":[["Out beyond the hearths.","Gone from us.","Driven out, like that.","A long walk into nothing."],
		["Better than death.","A warning to the rest of us.","Nobody will argue now.","I would not want to be them."]],
	"witness_glad":[["Well deserved.","Good.","A fair reward.","They earned it.","That was kindly done.","Rightly given."],
		["Everyone saw it.","It will be spoken of.","That will steady them.","Good to see.","We will all work harder.","A good day."]],
	"witness_envy":[["Some of us work just as hard.","Blessings for some.","Lucky them.","I notice who is favoured.","A fine gift, for them."],
		["I say nothing.","We will see.","I will remember.","Others have served longer.","Next time, perhaps."]],
	"witness_envoy":[["Look at them shake.","They will tell it at every fire.","That changes how they deal with us.","Their people will hear of this.","They came in proud."],
		["Good.","Let them carry it home.","Now they know whom they face.","Maybe too far.","They will not forget it."]],
	"envoy_cower":[["Mercy, {address}.","I am only a messenger.","I meant no offence to you.","Spare me.","I will carry your words home exactly.","My knees are weak."],
		["My people will hear every word.","I beg your patience.","Let me go home.","I will tell them of your anger.","Please, no more.","I understand."]],
	"envoy_defy":[["I will carry your anger home.","My people are not easily frightened.","Shout if you must.","We have heard threats before.","I am not yours to terrify."],
		["Our ruler will decide what it means.","We will remember this.","My people do not kneel.","Choose your next words carefully.","I will tell them exactly."]],
	# Everyday speech coloured by dread or love.
	"evasive":[["Whatever you judge best is best, {address}.","You see further than any of us.","It is well in hand, truly.","There is nothing to fear, nothing at all.","All is as you wish.","I would never question you."],
		["I am sure of it.","Every word.","Truly.","No trouble at all.","As you say.","Nothing is amiss."]],
	"frank":[["I will tell you straight.","You would want the truth, so here it is.","I will not flatter you.","Plainly, then.","You deserve better than soft words."],
		["It is harder than it looks.","Some of it is going badly.","I have doubts, and I will say them.","Ask me anything; I will answer it true.","Not all of it is good news."]],
	"summons_dread":[["You sent for me, {address}.","I came at once.","I am here, I am here.","I ran the whole way.","Whatever it is, I am ready."],
		["What have I done?","Tell me how to please you.","I will do anything.","Have I failed you?","Command me."]],
	"summons_love":[["You sent for me, {address}.","I am glad you called.","Here I am.","I came gladly."],
		["What can I do for you?","Ask me anything.","Tell me what you need.","I have things to tell you, too."]],
	"flight_hint":[["The far hills look quiet this season.","A body could walk a long way under a full moon.","Some nights I think of how quiet it is past the ridge.","There are valleys where nobody's anger reaches.","My feet have been restless lately."],
		["I only mention it.","Pay me no mind.","Forget I spoke.","It is nothing.","A foolish thought."]],
	"order_dread":[["At once, {address}, at once.","It will be done before nightfall.","Yes, yes, it will be done.","Immediately."],
		["I will see to it myself.","No delay.","I swear it.","Nothing will stop it."]],
}

static func generic(key:String)->Array:
	var pair:Array=GENERIC.get(key,[])
	if pair.size()<2: return []
	return _pairs(pair[0],pair[1])
