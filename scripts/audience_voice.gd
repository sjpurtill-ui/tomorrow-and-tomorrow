extends Node
## The voices of the Audience Hall. Writes scene lines (envoy, court, parting
## words) through AudienceHall.append_line and never touches world state beyond
## the bounded AudienceHall.apply_mood hook.
##
## Live path: Chat Completions via PronouncementInterpreter's connection, strict
## JSON schema whose speaker_key is an enum of the cast we supply. Offline path
## (no key, or any failure): persona-driven template banks run through each
## speaker's dialect. A failure never leaves a blank scene.

signal lines_ready(audience_id:String)
signal failed(audience_id:String,reason:String)

const CV:=preload("res://scripts/character_voice.gd")
const HALL_PATH:="res://scripts/audience_hall.gd"
const SCOUT_PATH:="res://scripts/chief_scout.gd"
const API_TIMEOUT_SECONDS:=45.0
const MAX_ATTEMPTS:=2
const RETRY_DELAY_SECONDS:=0.35
const MAX_COMPLETION_TOKENS:=1600
const MAX_RESPONSE_BYTES:=98304
const MAX_LINE_CHARS:=300
const MAX_PLAYER_CHARS:=400
const STAGE_LIMITS:={"open":9,"speak":4,"closing":3}
const META_PATTERN:="(?i)\\b(the game|this game|a game|games? (system|mechanic)s?|game ?play|gaming|game mechanics?|mechanics?|players?|buttons?|json|ai|a\\.i\\.|ai models?|artificial intelligence|language models?|llm|chatbot|as an assistant|the prompt|npcs?|click(ed|ing)?|menus?|user interface|save file|schema)\\b"

const SYSTEM_PROMPT:="""You write live dialogue for a royal audience hall in a fictional history. Speak only through the characters listed; no narration, no stage directions, no explanations.

Make it a scene worth watching. Every speaker has a distinct voice and a dialect that must be unmistakable on the page (word choice, rhythm, pet phrases), a temper, and private wants that leak out. Officials interrupt, contradict one another, flatter, needle, joke, grumble, whisper asides to the ruler, and let their self-interest show. Envoys bluff, flatter, boast, tease and defend their people's pride. Be forthright, funny and surprising. Never bureaucratic, never polite filler, never a recital of choices. Lines are short: one to three sentences. Use each pet phrase at most once; a secret only ever leaks sideways.

Truth: use only the facts supplied. Never invent amounts, goods, agreements, promises, battles, deaths, alliances or events; say amounts exactly as given or not at all. Nobody announces or assumes what the ruler will decide. Nobody agrees to new terms. Never mention games, systems, mechanics, buttons, menus, AI or data formats.

Reply with JSON only: {"lines":[{"speaker_key":"<a listed key>","text":"...","aside":false}],"mood_shift":0.0}. aside=true means murmured to the ruler alone. mood_shift (-0.25 to 0.25) is how this moment changed the warmth between the ruler and the visitor."""

# ---------------------------------------------------------------------------
# Offline banks. Every template is a complete, standalone thought; dialect comes
# from the speaker's address term, oath, word substitutions and at most one
# lead-in per line (never a trailing fragment).
# Tokens: {address} {oath} {civ} {leader} {res} {amt} {fact} {subject}
# {summary} {decree} {rival} {envoy} {petitioner} {why} {days} {homeless}
# A template is only used when every token it names has a real value.
# ---------------------------------------------------------------------------

const ENVOY_OPEN:={
	"gift":[
		"{oath} {leader} sends you {amt} {res}, {address}, and not a scrap of it grudging. Well, maybe one scrap.",
		"We hauled {amt} {res} across ugly country to stand in this pretty hall, {address}, so please look pleased; my feet are watching.",
		"{leader} told me, 'Bring them {amt} {res} and a smile.' The {res} survived the road, {address}; the smile is doing its best.",
		"A gift from {civ}: {amt} {res}, no strings attached. I checked twice, {address}, and once more in the rain.",
		"Before anyone asks what it costs, {address}: nothing. That's {amt} {res} because {leader} likes you, so kindly don't make it strange.",
	],
	"request":[
		"I'll not dress it in ribbons, {address}: {civ} needs {amt} {res}, and I'd not be standing here if we didn't.",
		"{leader} sent me with an empty sack and a hopeful face, {address}. The sack wants {amt} {res}; the face wants you to say yes.",
		"Our stores are thin and my pride is thinner for asking, but {amt} {res} would mend the first, {address}, and I'll nurse the second myself.",
		"{oath} I hate asking, {address}, so I'll ask fast: {amt} {res} for {civ}, and I'll owe you a song I can't sing.",
		"Straight to it, {address}: {amt} {res}. {civ} remembers who helps, and, rather less fondly, who doesn't.",
	],
	"threat":[
		"{leader} wants {amt} {res} as tribute, {address}, and {leader} is not a patient person. I'm the patient one, and I'm already bored.",
		"Let's be friends, {address}. Friends share, so you'll share {amt} {res} with {civ}, and we'll stay the very best of friends.",
		"{oath} Lovely hall, {address}, and such sturdy doors. It'd be a shame to test them, so let's talk about {amt} {res} instead.",
		"These are {leader}'s words, not mine, so glare at the words, {address}: {amt} {res}, or {civ} remembers you as the ones who refused.",
		"I'll keep this short, {address}, so you'll have more time to count out {amt} {res}.",
	],
	"news":[
		"Word from the road, {address}, fresh as warm bread: {fact}",
		"{oath} Nobody else was going to tell you, {address}, so it falls to me. {fact}",
		"You'll want to sit down for this, {address}, or lean on something ruler-ish. {fact}",
		"I ran the last stretch to be first with this, {address}, so kindly ignore the wheezing. {fact}",
		"{leader} thought you should hear this from a friend before you hear it from a spear, {address}. {fact}",
	],
	"report":[
		"Back in one piece, {address}, mostly. We've had a long look at {subject}, and I'll give it you straight.",
		"{oath} Muddy, tired and full of opinions, {address}. We've seen {subject}, and I'll tell you what I saw and not a hair more.",
	],
	"petition_grievance":[
		"I've a grievance, {address}, and I've been rationing my respect to make room for it. {why}",
		"{oath} I'll say this to your face, {address}, since saying it behind your back has worn thin. {why}",
		"I've swallowed this three times now, {address}, and it won't stay down. {why}",
	],
	"petition_ambition":[
		"I've a notion, {address}, a good one, and yes, it happens to involve me.",
		"Hear me out before {rival} starts sighing, {address}; this one's worth the whole afternoon.",
		"{oath} Let me do something grand for once, {address}. You'll get the credit and I'll get the blisters. Fair?",
	],
	"petition_generic":[
		"I'd not trouble you with a small thing, {address}. This is a middling thing that's growing teeth: {summary}",
		"Somebody has to say it, {address}, and everybody else has suddenly found something to polish. {summary}",
	],
}

const PETITION_PLEA:={
	"food":[
		"We're about {days} days from empty stores, {address}, and I'd sooner not learn how long a child lasts on bark.",
		"{oath} I've counted the sacks three times hoping I'd miscounted, {address}. About {days} days, and then we're boiling boots.",
		"People are weighing their portions with their eyes, {address}. About {days} days of stores left, and tempers shorter than that.",
		"The stores are sinking faster than anyone's saying out loud, {address}, and I'm done pretending otherwise.",
	],
	"health":[
		"The sick are stacking up, {address}, and the healthy have started eyeing the water like it owes them money.",
		"{oath} I passed sickbeds in three doorways on my way here, {address}, and I'd rather not count them on my way back.",
		"There's coughing in every doorway, {address}. If we wait for it to pass, it'll pass through all of us.",
	],
	"housing":[
		"About {homeless} of our people are sleeping under sky and sackcloth, {address}, and the sky isn't getting any warmer.",
		"{oath} I've had folk asking to sleep in my woodshed, {address}. About {homeless} of them without a proper roof, and my woodshed isn't that big.",
		"Folk are sleeping in doorways, {address}, and a doorway is a poor sort of house, especially in rain.",
	],
	"security":[
		"The watch is thin as broth, {address}; I've seen fences with more fight in them.",
		"{oath} I lie awake listening for boots, {address}, and I'd very much like them to be ours.",
		"Here's what keeps me up at night, {address}: {summary}",
	],
}

const DECREE_PLEA:={
	"Send gatherers to find food":"Send gatherers out, {address}, today, while the ones who'd go can still walk.",
	"Ration food for thirty days":"Cut the portions now, {address}: thirty days of tight belts, before the belts are all we've left to boil.",
	"Secure water and dig wells":"Put spades in hands and dig wells, {address}; clean water is cheaper than graves.",
	"Organize healers to care for the sick":"Give the healers hands and orders, {address}, and let them fight this properly.",
	"Build shelters":"Let's raise shelters, {address}, before the first hard frost does the counting for us.",
	"Raise a watch and post guards":"Raise a proper watch and post guards, {address}, and let the rest of us sleep a night through.",
	"Support scholars and fund research":"Set more hands to study, under my eye, {address}, and I'll bring you answers to questions you haven't thought of yet.",
	"Expand workshops and make tools":"Enlarge the workshops and let us make tools in earnest, {address}; one good axe is worth ten speeches.",
	"Post guards and patrol the frontier":"Let me put patrols along the frontier, {address}, so strangers learn our faces before they meet our spears.",
	"Hold a public council to hear the people":"Call a public council, {address}, and let the people shout at us in person; it's cheaper than letting them whisper.",
	"Improve roads and organize haulers":"Mend the roads and organize the haulers, {address}; half our troubles are things arriving late or not at all.",
}
const DECREE_PLEA_GENERIC:="I'd have you proclaim it plainly, {address}: {decree}. Say the word and I'll carry it out myself."

const COURT_STANCE:={
	"sycophantic":[
		"A magnificent audience already, {address}; you have a real gift for being visited.",
		"Whatever you decide will be wise, {address}, and I'll be first to say so, loudly, possibly with a song.",
		"{address} is too gracious to say it, so I will: we are delighted. We are, aren't we? We're delighted.",
		"I agree with {address} completely. I don't yet know what {address} thinks, but I agree with it.",
	],
	"cantankerous":[
		"I don't like it, {address}: not the smile, not the boots, and certainly not the timing.",
		"Lovely speech. Count your fingers after you shake that hand, {address}.",
		"{oath} Nobody asked me, so I'll say it twice: something in here smells, and it isn't the rushes.",
		"Another visitor with a big hat and a bigger idea, {address}. Wonderful. My favourite kind.",
	],
	"principled":[
		"Plainly, {address}: they've said what they want, so let's answer just as plainly.",
		"No flattery from me, {address}. It's fair or it isn't, and we ought to say which.",
		"I'll not pretend to be charmed, {address}. I'm pretending to listen, which is harder work.",
	],
	"diplomatic":[
		"Let's not rush to scowls, {address}; our guest has come a long way, and so, frankly, has my patience.",
		"There's a version of this where everybody leaves proud, {address}, and I'd like to find it before supper.",
		"Everybody breathe. You too, {rival}. Especially you.",
	],
	"pragmatic":[
		"Three questions, {address}: what does it cost, who carries it, and by when? The fourth is supper.",
		"Fine words, {address}. I'd like to weigh them before we buy them.",
		"I've done the sum in my head, {address}, and I'd like to do it again on a slate, slowly, in front of witnesses.",
	],
}
## Stance lines for petitions and reports, where the speaker is one of our own.
const COURT_STANCE_COURT:={
	"sycophantic":[
		"Whatever {petitioner} says, {address}, I agreed with it first. Quietly, but first.",
		"A fine petition, {address}, and an even finer ruler to hear it.",
	],
	"cantankerous":[
		"{oath} Every season someone stands there wanting something, {address}, and every season it's somehow urgent.",
		"I'll believe it's that bad when I've seen it myself, {address}, and possibly tasted it.",
	],
	"principled":[
		"{petitioner} is right, {address}, and it costs me nothing to say so, which is rare in this room.",
		"Plainly, {address}: the problem is real. The only question is whether we fix it or keep talking about it.",
	],
	"diplomatic":[
		"Let's hear {petitioner} out before anyone starts sharpening their sighs, {address}.",
		"Nobody's to blame and everybody's to help, {address}; that's the only way this ends without a feud.",
	],
	"pragmatic":[
		"Fine, {address}, but who does the work, and what stops getting done while they do it?",
		"I'll back it if somebody shows me where the hands come from, {address}. Hands don't grow on hands.",
	],
}

const COURT_KIND:={
	"gift":[
		"Take it before they change their mind, {address}; {rival} will want to sniff it for curses first.",
		"Gifts from {civ} are like cats, {address}: lovely, right up until you learn what they expect in return.",
		"That's {amt} {res} for nothing, {address}? Nothing's free; even the air in here costs me a headache.",
		"Say thank you nicely, {address}. The last present we had was a goat, and the goat bit me.",
	],
	"request":[
		"Our {res} doesn't grow on trees, {address}. Well, some of it might, but not ours.",
		"That's {amt} {res} we won't have ourselves, {address}; I'm only saying it now so nobody faints later.",
		"Hungry neighbours turn into grateful neighbours or angry ones, {address}, and I've never once guessed which.",
		"Give once and they'll ask twice, {address}; refuse once and they'll remember it three times over.",
	],
	"threat":[
		"Give them nothing, {address}, and then, if they push, give them a little less.",
		"{rival}, stop fingering that knife; it's a bread knife, and they can see it.",
		"We could pay, {address}, or we could not pay, and I've always liked the sound of 'not'.",
		"A herald only shouts this loud when someone at home told them to, {address}; watch who's holding the leash.",
	],
	"news":[
		"If it's true, {address}, it's worth something, and if it isn't, it's still worth a laugh.",
		"Ask how they know, {address}; a messenger who knows everything usually knows somebody.",
		"{oath} Well, that'll change the gossip at supper.",
		"I suspected as much, {address}, which, as everyone knows, is nearly the same as knowing.",
	],
	"petition":[
		"{petitioner} rehearsed that in the corridor, {address}; I heard it twice, and it was better the second time.",
		"They're not wrong, {address}, which pains me more than I can decently say.",
		"Every season somebody stands there saying 'something must be done', {address}, and this season it's {petitioner}.",
		"I'd like it noted that I raised this first, {address}: quietly, to a wall, but first.",
	],
}

const COURT_REPORT_OFFICE:={
	"marshal":["Walls, {address}: how high, how thick, and who's sleeping on them? That's all I want to know.","If they've fighters I want a count, {address}, and then I want it doubled so I can worry properly."],
	"quartermaster":["Did anyone look at their granaries, {address}? Full barns tell you more than banners ever do.","Never mind the scenery, {address}: what do they eat, how much of it, and would they trade it?"],
	"steward":["Every time we send scouts they come back with stories and muddy boots, {address}, and I'll take the stories.","Lovely. Now who's going to write all that down properly, {address}? Not me. Fine, me."],
	"scholar":["If they've a craft we don't, {address}, I want it described down to the fingernails.","I want every word of that on a tablet, {address}, before it turns into legend at supper."],
	"envoy":["If they met our scouts without spears, {address}, I can work with that.","Did they smile or just show teeth, {address}? There's a difference, and I make my living on it."],
}
const COURT_REPORT_ANY:=[
	"I'd like the version of that without the heroic bits, {address}, and then the version with them for supper.",
	"{petitioner} always comes back with twice the story and half the boots, {address}.",
	"Write it down, {address}, because somebody will argue about it later, and it'll probably be {rival}.",
	"Sounds like they're either very rich or very good at pretending, {address}, and both are useful to know.",
]

const COURT_BICKER:=[
	"{rival}, if you sigh any louder they'll hear it in {civ}.",
	"Don't listen to {rival}, {address}; {rival} once haggled with a goose and lost.",
	"For once I agree with {rival}, and I'd like it carved over the door as a historic day.",
	"That's the worst advice I've heard since {rival}'s last advice, {address}.",
	"{rival} is right, {address}, but for all the wrong reasons, which is very like {rival}.",
]

const COURT_ASIDE:=[
	"Watch their hands, {address}, not their mouth; the hands are more honest.",
	"Their boots are new, {address}. Somebody wants to look richer than they are.",
	"Whatever you say next, {address}, say it slowly; it makes them nervous.",
	"I'd keep one eye on the {res} and the other on them, {address}.",
	"They've practised this, {address}; nobody is naturally that dramatic.",
	"If this goes badly, {address}, I was never here.",
]
const COURT_ASIDE_COURT:=[
	"Between us, {address}, {petitioner} has wanted this for a year; it's only urgent now because it's true.",
	"Say yes slowly if you say it, {address}; they'll value it more.",
	"If you say no, {address}, say it kindly. {petitioner} holds a grudge the way a miser holds a coin.",
]
const COURT_ASIDE_REPORT:=[
	"Scouts always bring the scariest version home first, {address}. Give it a day to shrink to its true size.",
	"If half of that is true, {address}, we should be worried, and if all of it is, we should be packing.",
]

const ENVOY_REPLY:={
	"warm":[
		"Ha! You flatter well, {address}. I'll tell {leader} you were charming, and I'll leave out the parts where you weren't.",
		"Kind words, {address}, and {civ} collects those too; we've a whole shelf of them at home.",
		"{oath} Careful, {address}, or I'll start liking it here, and then who'll carry the grudges home?",
		"That's warmer than the road was, {address}, and the road had a bonfire.",
	],
	"hostile":[
		"Careful, {address}: words travel faster than envoys, and I travel fairly fast.",
		"{oath} I've been insulted by better, {address}. No, that's a lie; that one was quite good.",
		"Say that again, slower, {address}, so I can repeat it to {leader} exactly as you meant it.",
		"Bold talk, {address}, for someone sitting under such a very dry thatch.",
	],
	"question":[
		"A fair question, {address}, and here's a fair answer: I've told you all I was told, and a little of what I wasn't.",
		"Ask {leader} yourself, {address}, and bring food; it's a long answer.",
		"If I knew that, {address}, I'd be the one wearing the good hat.",
	],
	"neutral":[
		"I'll carry that home exactly as said, {address}; whether it arrives warm or cold depends on the weather.",
		"Noted, {address}: noted, remembered, and very possibly embroidered.",
		"Was that a yes, {address}? It sounded a little like a yes and a little like a cough.",
	],
}
const TERMS_STAND:=[
	"Pretty talk doesn't change the sack, {address}: it's still {amt} {res}.",
	"All the same, {address}, the matter stands where it stood, at {amt} {res}.",
]

const PETITIONER_REPLY:={
	"warm":["Thank you, {address}; I'd kneel, but my knees have opinions of their own.","That's more than I hoped for from a corridor day, {address}, and I'll take it with both hands."],
	"hostile":["I'll pretend I didn't hear that, {address}, but my face won't manage it.","{oath} I came in with one problem, {address}, and now I'm leaving with two."],
	"question":["Ask anyone who's been where I've been lately, {address}; they'll tell you the same, only with more swearing.","I've no more than I've said, {address}, but every word of it is true."],
	"neutral":["I'll wait, {address}; I'm good at waiting, as the corridor will tell you.","That's not a no, {address}, so in my head I'm calling it a yes."],
}

const COURT_REACT:={
	"warm":["Well said, {address}. I'd have said it louder, but well said.","Look at their ears go red, {address}; that landed.","A charm offensive, {address}? Bold. I approve, and I'm slightly jealous."],
	"hostile":["Bold, {address}, possibly too bold; I love it and I'm worried.","You've rattled them, {address}. Whether that's good, ask me tomorrow.","{rival} just swallowed a laugh, {address}; I saw it."],
	"question":["Good question, {address}. I'd have asked it myself, but I was busy looking wise.","Watch their eyes while they answer, {address}; eyes are terrible liars."],
	"neutral":["Neither here nor there, {address}, which is sometimes exactly where you want to be.","Keep them guessing, {address}; it suits you."],
}

const CLOSING_OPTION:={
	"accept":["{oath} Good! {leader} will be glad the {res} found a proper home, {address}.","Received and appreciated, {address}? Then my feet can finally stop aching with purpose."],
	"accept_return":["A gift back, {address}? Now I owe you a gift for the gift for the gift. This will never end, and I love it.","{oath} A courteous court! {leader} will hear you sent something home with me, and I'll tell it well."],
	"refuse":["Refused, {address}? Then I carry {amt} {res} home again, and the story with it.","You send it back, {address}. {leader} doesn't often hear 'no, thank you', so let's see how {leader} takes it."],
	"refuse_request":["No, then. I'll carry an empty sack home, {address}, and it's heavier than it looks.","Refused, {address}? {civ} will remember that, and I'll remember your face while you said it."],
	"grant":["{oath} All of it, {address}? I'll sing about you on the road, badly but sincerely.","{civ} won't forget this, {address}, and for once that's good news for you."],
	"grant_half":["Half a sack is still a sack, {address}; I'll tell {leader} you cut it down the middle like an honest butcher.","Half, {address}. Then we'll be half grateful, which is more than nothing and less than enough."],
	"pay":["Sensible, {address}. {leader} likes sensible; sensible tends to live longer.","The {res} will be counted twice, {address}; {leader} trusts nobody, least of all me."],
	"defy":["No tribute, {address}? {oath} I'll tell {leader} exactly how you said it, word for word.","Nothing, then? Brave, {address}. I'll carry your nothing home; at least it's lighter than {res}."],
	"counter":["Threat for threat, {address}? Ha! Now we're finally speaking the same tongue.","{oath} Snarling back at me, {address}? {leader} will enjoy that, though 'enjoy' is the wrong word."],
	"thank":["Thanks is thin soup, {address}, but it's warm, and I'll drink it.","Glad to be of use, {address}; just remember who told you first."],
	"reward":["A reward, {address}? For me? I was going to tell everyone you're wonderful anyway, but now I'll do it with feeling.","{oath} You pay your messengers, {address}? I may never leave."],
	"apologise":["Well, that's said, {address}. I'll put the grudge back on its shelf; not away, mind, just on the shelf.","An apology from the seat itself, {address}? I may need to sit down."],
	"rebuke":["As you like, {address}. I'll remember whom I serve, and how.","{oath} Rebuked like a scullion, {address}. I'll take it, and I'll keep it."],
	"decree":["You'll proclaim it, {address}? {oath} Then I'll see it done, and I'll hold you to every word.","That's the stuff, {address}; I'll roll up my sleeves before you can change your mind."],
	"promise":["A promise to think on it, {address}. I've eaten on less; not well, but I've eaten.","I'll hold you to the thinking, {address}, so please think quickly."],
	"reward_scouts":["{oath} Fed and thanked! The party will be insufferable for a week, {address}, and they've earned it.","A reward, {address}? I'll pass it round the fire, though the tall one will eat double."],
	"send_back":["Back out we go, {address}. Good; I was getting soft sitting still, and there's more to see.","There's more to see, right enough, {address}. I'll have my boots on before supper."],
	"dismiss":["Dismissed, {address}. I'll carry my problem back out that door, where it'll carry on growing.","{oath} As you wish, {address}; just don't be surprised when I'm proved right."],
}
const CLOSING_REACTION:={
	"delighted":["{oath} Now that's a court, {address}! {leader} will hear of this with music.","I came with a speech ready for disappointment, {address}, and now I'll have to burn it. Happily."],
	"pleased":["Fair and done, {address}. {civ} will remember this kindly, which for us is a great deal of remembering.","Good. I'll sleep on the road tonight, {address}, and not even mind the rocks."],
	"neutral":["So be it, {address}: neither sweet nor sour, like hall bread.","I'll carry your answer home as you gave it, {address}, with hardly any embroidery."],
	"offended":["Ah. I see how it is, {address}, and {leader} will see it too, once I describe your face.","{civ} has a long memory, {address}, and I've a short temper; between us we'll manage."],
	"furious":["{oath} You'll regret this, {address}. Not today, perhaps, but regret keeps well.","I'll go, {address}. My feet are leaving; my grudge is staying right here."],
}
const CLOSING_ASIDE:={
	"warm":["That went well, {address}. Suspiciously well; I'll check the doorframes.","Did you see that smile, {address}? A real one, teeth and everything.","Nicely done, {address}. I'll take partial credit if nobody minds, and possibly if they do."],
	"neutral":["Could have been worse, {address}; nobody spilled soup on anybody this time.","Nobody drew a knife, {address}, and in this hall I call that diplomacy."],
	"hostile":["That's one fewer feast invitation, {address}.","I'd double the watch tonight, {address}, and hide the good cups.","They'll tell that story at home, {address}, loudly and with gestures."],
}

var hall:Variant=null          ## injected by tests; otherwise loaded from HALL_PATH
var force_offline:=false       ## tests / "no AI" play
var send_hook:Callable         ## tests: replaces the HTTP transport (id, payload, attempt)
var config_override:Dictionary={} ## tests: pretend a connection is configured
var last_problem:Dictionary={} ## audience_id -> reason the live voice fell back
var _requests:Dictionary={}
var _used:Dictionary={}

# ---------------------------------------------------------------------------
# Public API (contract)
# ---------------------------------------------------------------------------

func busy(audience_id:String)->bool:
	return _requests.has(audience_id)

func open_scene(audience_id:String)->void:
	_begin(audience_id,"open",{})

func player_speaks(audience_id:String,text:String)->void:
	var clean:String=text.strip_edges().replace("\n"," ").substr(0,MAX_PLAYER_CHARS)
	if clean.is_empty(): return
	var h:Variant=_hall()
	if h==null or (h.find(audience_id) as Dictionary).is_empty():
		failed.emit(audience_id,"No audience is waiting.")
		return
	# The ruler's words land in the transcript immediately, before any reply.
	h.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":clean,"day":_day(),"aside":false})
	_begin(audience_id,"speak",{"player_text":clean})

func closing(audience_id:String,result:Dictionary)->void:
	_begin(audience_id,"closing",{"result":result.duplicate(true)})

# ---------------------------------------------------------------------------
# Scene assembly
# ---------------------------------------------------------------------------

func _hall()->Variant:
	if hall==null and ResourceLoader.exists(HALL_PATH): hall=load(HALL_PATH)
	return hall

func _day()->int:
	return int(GameState.elapsed_days)

func _config()->Dictionary:
	if force_offline: return {}
	if not config_override.is_empty(): return config_override
	return PronouncementInterpreter._api_config()

func scene(audience_id:String)->Dictionary:
	var h:Variant=_hall()
	if h==null: return {}
	var audience:Dictionary=h.find(audience_id)
	if audience.is_empty(): return {}
	var ctx:Dictionary=h.voice_context(audience_id)
	var speaker:Dictionary=audience.get("speaker",{})
	var civ_id:String=String(audience.get("civ_id",""))
	var origin:String=String(audience.get("origin","foreign"))
	var envoy_persona:Dictionary
	if origin=="court":
		var person:Dictionary={}
		var pid:int=int(speaker.get("person_id",0))
		if pid>0 and GovernmentPeopleSystem.has_method("person_snapshot"): person=GovernmentPeopleSystem.person_snapshot(pid)
		if person.is_empty(): person={"person_id":pid,"name":String(speaker.get("name","")),"traits":[]}
		person["office_title"]=String(speaker.get("title",person.get("office_title","")))
		envoy_persona=CV.for_person(person)
	else:
		envoy_persona=CV.for_envoy(civ_id,audience_id)
	envoy_persona["key"]="envoy"
	if not String(speaker.get("name","")).is_empty(): envoy_persona["name"]=String(speaker.name)
	if not String(speaker.get("title","")).is_empty(): envoy_persona["title"]=String(speaker.title)
	var envoy:={"key":"envoy","persona":envoy_persona,"name":String(envoy_persona.name),"role":"official" if origin=="court" else "envoy",
		"person_id":int(speaker.get("person_id",0)),"civ_id":civ_id if origin!="court" else "player"}
	var officials:Array=[]
	for person in h.court(audience_id):
		var persona:=CV.for_person(person)
		officials.append({"key":String(persona.key),"persona":persona,"name":String(persona.name),"role":"official","person_id":int(persona.person_id),"civ_id":"player"})
	var terms:Dictionary=audience.get("terms",{})
	var news:Dictionary=audience.get("news",{})
	var petition:Dictionary=audience.get("petition",{})
	var leader:Dictionary=ctx.get("leader",{}) if ctx.get("leader",{}) is Dictionary else {}
	var civ_ctx:Dictionary=ctx.get("civ",{}) if ctx.get("civ",{}) is Dictionary else {}
	var s:={"id":audience_id,"audience":audience,"ctx":ctx,"kind":String(audience.get("kind","news")),"origin":origin,
		"envoy":envoy,"officials":officials,"civ_id":civ_id,
		"civ":String(audience.get("civ_name",civ_ctx.get("name",""))),"leader":String(leader.get("name","")),
		"res":_resource_words(String(terms.get("resource",""))),"amt":_amount_words(terms),
		"fact":String(news.get("fact","")),"subject":String(news.get("subject_civ_name","")),
		"summary":String(petition.get("summary","")),"decree":String(petition.get("suggested_decree","")),"topic":String(petition.get("topic",""))}
	if String(s.kind)=="report":
		var report:Dictionary=audience.get("report",{}) if audience.get("report",{}) is Dictionary else {}
		s["report"]=report
		s["subject"]=String(report.get("subject_name",""))
		s["scout_brief"]=_scout_call("voice_brief",audience)
	if origin=="court": s["civ"]=String(ctx.get("player_settlement","")) if not String(ctx.get("player_settlement","")).is_empty() else "our people"
	return s

func _scout_call(method:String,audience:Dictionary)->Variant:
	## Chief-scout helpers are optional until that file lands.
	var empty:Variant={} if method=="voice_brief" else []
	if not ResourceLoader.exists(SCOUT_PATH): return empty
	var scout:Variant=load(SCOUT_PATH)
	if scout==null or not scout.has_method(method): return empty
	var value:Variant=scout.call(method,audience)
	if method=="voice_brief": return value if value is Dictionary else {}
	return value if value is Array else []

static func _resource_words(resource:String)->String:
	return resource.replace("_"," ").to_lower().strip_edges()

static func _amount_words(terms:Dictionary)->String:
	if terms.is_empty() or not terms.has("amount"): return ""
	return "%d" % roundi(float(terms.amount))

func cast_keys(s:Dictionary)->Array[String]:
	var keys:Array[String]=["envoy"]
	for member in s.officials: keys.append(String(member.key))
	return keys

func _member(s:Dictionary,key:String)->Dictionary:
	if key=="envoy": return s.envoy
	for member in s.officials:
		if String(member.key)==key: return member
	return {}

func _line_for(member:Dictionary,text:String,aside:bool)->Dictionary:
	return {"speaker":String(member.name),"role":String(member.role),"person_id":int(member.person_id),"civ_id":String(member.civ_id),"text":text,"day":_day(),"aside":aside}

# ---------------------------------------------------------------------------
# Request lifecycle
# ---------------------------------------------------------------------------

func _begin(audience_id:String,stage:String,extra:Dictionary)->void:
	if busy(audience_id): return
	var s:=scene(audience_id)
	if s.is_empty():
		failed.emit(audience_id,"No audience is waiting.")
		return
	var config:=_config()
	if config.is_empty():
		_deliver_offline(s,stage,extra,"")
		return
	var request:=prepare_request(s,stage,extra,config)
	_requests[audience_id]=request
	_send(audience_id)

func prepare_request(s:Dictionary,stage:String,extra:Dictionary,config:Dictionary)->Dictionary:
	var keys:=cast_keys(s)
	var payload:={"model":String(config.get("model","")),"max_completion_tokens":MAX_COMPLETION_TOKENS,"messages":[
		{"role":"system","content":SYSTEM_PROMPT},
		{"role":"user","content":build_prompt(s,stage,extra)},
	]}
	if bool(config.get("structured_output",false)): payload["response_format"]=response_format(keys)
	var headers:PackedStringArray=PackedStringArray(["Content-Type: application/json","Authorization: Bearer %s" % String(config.get("api_key","")),"X-Client-Request-Id: audience-%s-%d" % [String(s.id),Time.get_ticks_msec()]])
	return {"scene":s,"stage":stage,"extra":extra,"config":config,"payload":payload,"headers":headers,"keys":keys,
		"attempts":0,"max_attempts":MAX_ATTEMPTS,"downgraded":false,"http":null}

func _send(audience_id:String)->void:
	if not _requests.has(audience_id): return
	var request:Dictionary=_requests[audience_id]
	request.attempts=int(request.attempts)+1
	var attempt:int=int(request.attempts)
	if send_hook.is_valid():
		send_hook.call(audience_id,request.payload.duplicate(true),attempt)
		return
	var previous:HTTPRequest=request.get("http")
	if previous and is_instance_valid(previous): previous.queue_free()
	var http:=HTTPRequest.new()
	add_child(http)
	request.http=http
	http.timeout=API_TIMEOUT_SECONDS
	http.max_redirects=0
	http.body_size_limit=MAX_RESPONSE_BYTES
	http.request_completed.connect(_on_response.bind(audience_id,attempt))
	var error:Error=http.request(String(request.config.endpoint),request.headers,HTTPClient.METHOD_POST,JSON.stringify(request.payload))
	if error!=OK:
		request.http=null
		http.queue_free()
		_attempt_failed.call_deferred(audience_id,"request could not start",true)

func _on_response(result:int,response_code:int,_headers:PackedStringArray,body:PackedByteArray,audience_id:String,attempt:int)->void:
	if not _requests.has(audience_id): return
	var request:Dictionary=_requests[audience_id]
	if attempt!=int(request.attempts): return
	var http:HTTPRequest=request.get("http")
	request.http=null
	if http and is_instance_valid(http): http.queue_free()
	var ok_http:bool=result==HTTPRequest.RESULT_SUCCESS and response_code>=200 and response_code<300
	if ok_http:
		var parsed:=parse_body(body)
		if not parsed.is_empty():
			var s:Dictionary=request.scene
			var lines:=validate_lines(parsed.get("lines",[]),s,String(request.stage),request.extra)
			if not lines.is_empty():
				_requests.erase(audience_id)
				_deliver(s,String(request.stage),request.extra,lines,float(parsed.get("mood_shift",0.0)))
				return
	if result==HTTPRequest.RESULT_SUCCESS and response_code in [400,415,422] and request.payload.has("response_format") and not bool(request.downgraded):
		# Some compatible endpoints reject json_schema. Retry once without it;
		# this compatibility retry does not consume the ordinary retry.
		request.payload.erase("response_format")
		request.downgraded=true
		request.max_attempts=int(request.max_attempts)+1
		_attempt_failed(audience_id,"structured output rejected (HTTP %d)" % response_code,true)
		return
	var retryable:bool=ok_http or result!=HTTPRequest.RESULT_SUCCESS or response_code in [408,425,429] or response_code>=500
	var detail:="reply failed validation" if ok_http else ("transport failure" if result!=HTTPRequest.RESULT_SUCCESS else "HTTP %d" % response_code)
	_attempt_failed(audience_id,detail,retryable)

func _attempt_failed(audience_id:String,detail:String,retryable:bool)->void:
	if not _requests.has(audience_id): return
	var request:Dictionary=_requests[audience_id]
	if retryable and int(request.attempts)<int(request.max_attempts):
		if send_hook.is_valid(): _send(audience_id)
		else: get_tree().create_timer(RETRY_DELAY_SECONDS*int(request.attempts)).timeout.connect(_send.bind(audience_id))
		return
	_requests.erase(audience_id)
	last_problem[audience_id]=detail
	_deliver_offline(request.scene,String(request.stage),request.extra,detail)

# ---------------------------------------------------------------------------
# Parsing and validation
# ---------------------------------------------------------------------------

func parse_body(body:PackedByteArray)->Dictionary:
	var parser:=JSON.new()
	if parser.parse(body.get_string_from_utf8())!=OK or not parser.data is Dictionary: return {}
	var envelope:Dictionary=parser.data
	var proposed:Variant=null
	if envelope.has("lines"): proposed=envelope
	else:
		var content:=""
		var choices:Variant=envelope.get("choices",[])
		if choices is Array and not (choices as Array).is_empty() and choices[0] is Dictionary:
			var message:Variant=(choices[0] as Dictionary).get("message",{})
			if message is Dictionary: content=PronouncementInterpreter._content_text((message as Dictionary).get("content",""))
		if content.is_empty(): content=PronouncementInterpreter._content_text(envelope.get("output_text",""))
		if content.is_empty(): content=PronouncementInterpreter._content_text(envelope.get("output",[]))
		var first:=content.find("{"); var last:=content.rfind("}")
		if first<0 or last<=first: return {}
		var inner:=JSON.new()
		if inner.parse(content.substr(first,last-first+1))!=OK: return {}
		proposed=inner.data
	if not proposed is Dictionary or not (proposed as Dictionary).get("lines",null) is Array: return {}
	var mood:Variant=(proposed as Dictionary).get("mood_shift",0.0)
	var mood_value:float=float(mood) if (mood is float or mood is int) and is_finite(float(mood)) else 0.0
	return {"lines":(proposed as Dictionary).lines,"mood_shift":clampf(mood_value,-0.25,0.25)}

func allowed_numbers(s:Dictionary,extra:Dictionary)->Dictionary:
	var allowed:={}
	var sources:PackedStringArray=PackedStringArray([JSON.stringify(s.get("report",{})),JSON.stringify(s.get("scout_brief",{})),JSON.stringify(s.get("ctx",{})),String(s.get("fact","")),String(s.get("summary","")),String(s.get("amt","")),String(extra.get("player_text",""))])
	var result:Dictionary=extra.get("result",{})
	sources.append(String(result.get("outcome","")))
	var terms:Dictionary=(s.get("audience",{}) as Dictionary).get("terms",{})
	if terms.has("amount"):
		sources.append("%d" % roundi(float(terms.amount)))
		sources.append("%d" % roundi(float(terms.amount)*0.5))
	var number:=RegEx.new(); number.compile("\\d+(?:\\.\\d+)?")
	for m in number.search_all(" ".join(sources)): allowed[m.get_string()]=true
	return allowed

func validate_lines(raw:Array,s:Dictionary,stage:String,extra:Dictionary={})->Array[Dictionary]:
	var keys:=cast_keys(s)
	var meta:=RegEx.new(); meta.compile(META_PATTERN)
	var number:=RegEx.new(); number.compile("\\d+(?:\\.\\d+)?")
	var allowed:=allowed_numbers(s,extra)
	var out:Array[Dictionary]=[]
	var limit:int=int(STAGE_LIMITS.get(stage,4))
	for item in raw:
		if out.size()>=limit: break
		if not item is Dictionary: continue
		var key:String=String((item as Dictionary).get("speaker_key",""))
		if key not in keys: continue
		var text:=_clean_text(String((item as Dictionary).get("text","")),_member(s,key))
		if text.is_empty() or meta.search(text)!=null: continue
		var invented:=false
		for m in number.search_all(text):
			if not allowed.has(m.get_string()): invented=true
		if invented: continue
		out.append({"key":key,"text":text,"aside":bool((item as Dictionary).get("aside",false))})
	return out

func _clean_text(text:String,member:Dictionary)->String:
	var t:String=text.replace("\r"," ").replace("\n"," ").replace("\t"," ").strip_edges()
	while "  " in t: t=t.replace("  "," ")
	# Models sometimes prefix the speaker name; the hall already shows it.
	var speaker_name:String=String(member.get("name",""))
	if not speaker_name.is_empty() and t.begins_with(speaker_name+":"): t=t.substr(speaker_name.length()+1).strip_edges()
	if t.length()>=2 and t.begins_with("\"") and t.ends_with("\""): t=t.substr(1,t.length()-2).strip_edges()
	if t.length()>MAX_LINE_CHARS:
		var cut:String=t.substr(0,MAX_LINE_CHARS)
		var stop:int=maxi(cut.rfind(". "),maxi(cut.rfind("! "),cut.rfind("? ")))
		t=cut.substr(0,stop+1) if stop>60 else cut.substr(0,cut.rfind(" "))+"..."
	return t

# ---------------------------------------------------------------------------
# Delivery
# ---------------------------------------------------------------------------

func _deliver(s:Dictionary,stage:String,extra:Dictionary,lines:Array[Dictionary],mood_shift:float)->void:
	var h:Variant=_hall()
	if h==null: return
	var ordered:=lines
	# The visitor always speaks first when the room opens or answers the ruler.
	if stage in ["open","speak"] and (ordered.is_empty() or String(ordered[0].key)!="envoy"):
		var envoy_index:=-1
		for i in ordered.size():
			if String(ordered[i].key)=="envoy": envoy_index=i; break
		if envoy_index>0: ordered.push_front(ordered.pop_at(envoy_index))
		else:
			var rng:=_scene_rng(s,stage+":lead")
			var lead:=_offline_lines(s,stage,extra,rng)
			if not lead.is_empty(): ordered.push_front(lead[0])
	for line in ordered:
		var member:=_member(s,String(line.key))
		if member.is_empty(): continue
		h.append_line(String(s.id),_line_for(member,String(line.text),bool(line.aside)))
	# Only the ruler's own words move the room; openings and farewells do not.
	if stage=="speak" and absf(mood_shift)>0.0: h.apply_mood(String(s.id),clampf(mood_shift,-0.25,0.25))
	lines_ready.emit.call_deferred(String(s.id))

func _deliver_offline(s:Dictionary,stage:String,extra:Dictionary,_problem:String)->void:
	var rng:=_scene_rng(s,stage)
	var lines:=_offline_lines(s,stage,extra,rng)
	var mood:=0.0
	if stage=="speak": mood=float(SENTIMENT_MOOD.get(sentiment(String(extra.get("player_text",""))),0.0))
	_deliver(s,stage,extra,lines,mood)

func _scene_rng(s:Dictionary,stage:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	var count:int=((s.audience as Dictionary).get("lines",[]) as Array).size()
	rng.seed=hash("%d|%s|%s|%d" % [int(GameState.world_seed),String(s.id),stage,count])
	return rng

# ---------------------------------------------------------------------------
# Offline scene writing
# ---------------------------------------------------------------------------

const SENTIMENT_MOOD:={"warm":0.08,"hostile":-0.12,"question":0.02,"neutral":0.0}
const WARM_WORDS:=["thank*","welcome*","friend*","grateful","honou*","honor*","generous","kind","kindly","gift*","glad","pleased","delight*","love*","admire*","brother*","sister*","ally","allies","peace*","wonderful","gracious","please","cousin*","feast*","toast"]
const HOSTILE_WORDS:=["never","refuse*","threat*","insult*","fool*","dare","war","wars","kill*","leave","liar*","lie","lies","coward*","begone","nonsense","pathetic","idiot*","burn*","crush*","destroy*","enough","out","scum","dog","dogs","fight*","spit","die","hang","beg*"]

static func _count_hits(words:PackedStringArray,bank:Array)->int:
	var hits:=0
	for entry in bank:
		var e:String=String(entry)
		var prefix:bool=e.ends_with("*")
		var stem:String=e.trim_suffix("*")
		for w in words:
			if (prefix and w.begins_with(stem)) or (not prefix and w==stem):
				hits+=1
				break
	return hits

static func sentiment(text:String)->String:
	var cleaned:=""
	for c in text.to_lower():
		cleaned+=c if (c>="a" and c<="z") or c=="'" else " "
	var words:PackedStringArray=cleaned.split(" ",false)
	var hostile:int=_count_hits(words,HOSTILE_WORDS)
	var warm:int=_count_hits(words,WARM_WORDS)
	if hostile>warm: return "hostile"
	if warm>0: return "warm"
	if "?" in text: return "question"
	return "neutral"

func _tokens(s:Dictionary,member:Dictionary,rival:Dictionary)->Dictionary:
	var persona:Dictionary=member.get("persona",{})
	var tokens:={"address":String(persona.get("address","")),"oath":String(persona.get("oath","")),"proverb":String(persona.get("proverb","")),
		"civ":String(s.civ),"leader":String(s.leader),"res":String(s.res),"amt":String(s.amt),"fact":String(s.fact),"subject":String(s.subject),
		"summary":String(s.summary),"decree":_lower_initial(String(s.decree)),"envoy":String(s.envoy.name),"petitioner":String(s.envoy.name) if s.origin=="court" else "",
		"rival":String(rival.get("name","")).get_slice(" ",0),"why":_grievance_words(String(s.summary)),
		"days":_number_after(String(s.summary),"about (\\d+) days"),"homeless":_number_after(String(s.summary),"(?i)about (\\d+) people")}
	if tokens.leader.is_empty() and s.origin!="court": tokens.leader="our chief"
	if tokens.decree.is_empty(): tokens.erase("decree")
	var out:={}
	for k in tokens:
		if not String(tokens[k]).strip_edges().is_empty(): out[k]=tokens[k]
	return out

static func _number_after(text:String,pattern:String)->String:
	var re:=RegEx.new(); re.compile(pattern)
	var m:=re.search(text)
	return m.get_string(1) if m!=null else ""

static func _lower_initial(text:String)->String:
	return text.substr(0,1).to_lower()+text.substr(1) if not text.is_empty() else text

static func _grievance_words(summary:String)->String:
	var t:String=summary.to_lower()
	if "insult" in t: return "My standing's been trodden on in this hall, and I felt every boot."
	if "ignored" in t: return "My counsel goes in one ear and out the window."
	if "grudge" in t or "slight" in t: return "I've been slighted, and I've kept count. It's a long count."
	return ""

func _fill(template:String,tokens:Dictionary)->String:
	var out:=template
	for k in tokens: out=out.replace("{"+String(k)+"}",String(tokens[k]))
	return _capitalize_sentences(out)

static func _capitalize_sentences(text:String)->String:
	var out:=text
	if not out.is_empty(): out=out.substr(0,1).to_upper()+out.substr(1)
	for i in range(2,out.length()):
		if out[i-1]==" " and out[i-2] in ".!?" and out[i]!=out[i].to_upper():
			out=out.substr(0,i)+out[i].to_upper()+out.substr(i+1)
	return out

func _usable(template:String,tokens:Dictionary)->bool:
	var re:=RegEx.new(); re.compile("\\{([a-z]+)\\}")
	for m in re.search_all(template):
		if not tokens.has(m.get_string(1)): return false
	return true

func _choose(s:Dictionary,bank:Array,tokens:Dictionary,rng:RandomNumberGenerator,recent:Array[String]=[])->String:
	## Prefer templates unused in this scene and unsaid by this speaker lately.
	var used:Dictionary=_used.get(String(s.id),{})
	var fresh:Array=[]; var unscened:Array=[]; var any:Array=[]
	for template in bank:
		if not _usable(String(template),tokens): continue
		any.append(template)
		if used.has(String(template)): continue
		unscened.append(template)
		if not _recently_said(_fill(String(template),tokens),recent): fresh.append(template)
	var pool:Array=fresh if not fresh.is_empty() else (unscened if not unscened.is_empty() else any)
	if pool.is_empty(): return ""
	var chosen:String=String(pool[rng.randi_range(0,pool.size()-1)])
	used[chosen]=true
	_used[String(s.id)]=used
	return _fill(chosen,tokens)

func _say(s:Dictionary,member:Dictionary,bank:Array,rng:RandomNumberGenerator,rival:Dictionary={},aside:bool=false)->Dictionary:
	var tokens:=_tokens(s,member,rival)
	var raw:=_choose(s,bank,tokens,rng,_recent_lines(s,member))
	if raw.is_empty(): return {}
	# A line that opens on a name or title keeps it up front; no lead-in before it.
	var lead_ok:=true
	for k in ["address","leader","rival","petitioner","civ","envoy","oath","subject"]:
		var value:String=String(tokens.get(k,""))
		if not value.is_empty() and raw.to_lower().begins_with(value.to_lower()): lead_ok=false
	return {"key":String(member.key),"text":CV.speak(member.persona,raw,rng,true,_flourish_memory(s,member),lead_ok),"aside":aside}

func _flourish_memory(s:Dictionary,member:Dictionary)->Dictionary:
	var used:Dictionary=_used.get(String(s.id),{})
	var memory_key:="~flourish:"+String(member.key)
	if not used.has(memory_key):
		# Seed with lead-ins this speaker opened lines with in their recent audiences.
		var memory:={}
		for text in _recent_lines(s,member):
			for lead in CV.lead_ins(member.persona):
				if text.begins_with(String(lead).to_lower()): memory[String(lead)]=true
		used[memory_key]=memory
	_used[String(s.id)]=used
	return used[memory_key]

const RECENT_AUDIENCES:=4

func _recent_lines(s:Dictionary,member:Dictionary)->Array[String]:
	## Lowercased lines this speaker said in their last few audiences, read from
	## the hall's own queue and history (no extra save data).
	var used:Dictionary=_used.get(String(s.id),{})
	var cache_key:="~recent:"+String(member.key)
	if used.has(cache_key): return used[cache_key]
	var out:Array[String]=[]
	var h:Variant=_hall()
	if h!=null and h.has_method("state"):
		var st:Dictionary=h.state()
		var audiences:Array=(st.get("queue",[]) as Array).duplicate()
		audiences.reverse()   # newest waiting first, then history (already newest first)
		audiences.append_array(st.get("history",[]))
		var found:=0
		for audience in audiences:
			if found>=RECENT_AUDIENCES: break
			if String(audience.get("id",""))==String(s.id): continue
			var spoke:=false
			for line in audience.get("lines",[]):
				if String(line.get("speaker",""))==String(member.name):
					out.append(String(line.get("text","")).to_lower())
					spoke=true
			if spoke: found+=1
	used[cache_key]=out
	_used[String(s.id)]=used
	return out

static func _recently_said(filled:String,recent:Array[String])->bool:
	if recent.is_empty(): return false
	var core:String=filled.to_lower()
	var probes:Array[String]=[core]
	if core.length()>=30: probes=[core.substr(int(core.length()/3.0),20),core.substr(core.length()-24,20)]
	for text in recent:
		for probe in probes:
			if probe in text: return true
	return false

func _offline_lines(s:Dictionary,stage:String,extra:Dictionary,rng:RandomNumberGenerator)->Array[Dictionary]:
	match stage:
		"open": return _offline_open(s,rng)
		"speak": return _offline_speak(s,String(extra.get("player_text","")),rng)
		"closing": return _offline_closing(s,extra.get("result",{}),rng)
	return []

func _append_if(out:Array[Dictionary],line:Dictionary)->void:
	if not line.is_empty(): out.append(line)

func _offline_open(s:Dictionary,rng:RandomNumberGenerator)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var kind:String=String(s.kind)
	var envoy:Dictionary=s.envoy
	var first_official:Dictionary=s.officials[0] if not s.officials.is_empty() else {}
	if kind=="report":
		for item in _scout_call("debrief_lines",s.audience):
			var text:=""
			var aside:bool=false
			if item is Dictionary:
				text=String((item as Dictionary).get("text",""))
				aside=bool((item as Dictionary).get("aside",false))
			elif item is String: text=String(item)
			text=_clean_text(text,envoy)
			if text.is_empty(): continue
			# chief_scout.gd already gives its first line the scout's dialect.
			out.append({"key":"envoy","text":text,"aside":aside})
			if out.size()>=6: break
		if out.is_empty(): _append_if(out,_say(s,envoy,ENVOY_OPEN.report,rng,first_official))
	elif kind=="petition":
		# A person pleading: the trouble in their own words, then the remedy as a plea.
		var topic:String=String(s.topic)
		if topic=="grievance": _append_if(out,_say(s,envoy,ENVOY_OPEN.petition_grievance,rng,first_official))
		elif topic=="ambition": _append_if(out,_say(s,envoy,ENVOY_OPEN.petition_ambition,rng,first_official))
		else: _append_if(out,_say(s,envoy,PETITION_PLEA.get(topic,[]),rng,first_official))
		if out.is_empty(): _append_if(out,_say(s,envoy,ENVOY_OPEN.petition_generic,rng,first_official))
		if not String(s.decree).is_empty():
			_append_if(out,_say(s,envoy,[String(DECREE_PLEA.get(String(s.decree),DECREE_PLEA_GENERIC))],rng))
	else:
		_append_if(out,_say(s,envoy,ENVOY_OPEN.get(kind,ENVOY_OPEN.news),rng,first_official))
	var officials:Array=s.officials.duplicate()
	if officials.is_empty():
		# An empty bench: the visitor fills the silence themselves.
		_append_if(out,_say(s,envoy,["A quiet court, {address}. I like a quiet court; it means somebody's actually listening."],rng))
		return out
	var own:bool=String(s.origin)=="court"
	var stances:Dictionary=COURT_STANCE_COURT if own else COURT_STANCE
	var asides:Array=COURT_ASIDE_REPORT if kind=="report" else (COURT_ASIDE_COURT if own else COURT_ASIDE)
	var kind_bank:Array=COURT_KIND.get(kind,COURT_KIND.petition if own else COURT_KIND.news)
	var shuffled:Array=[]
	while not officials.is_empty(): shuffled.append(officials.pop_at(rng.randi_range(0,officials.size()-1)))
	var count:int=clampi(rng.randi_range(2,4),1,shuffled.size())
	if shuffled.size()>=2: count=maxi(count,2)
	var previous:Dictionary={}
	for i in count:
		var member:Dictionary=shuffled[i]
		var stance:String=String(member.persona.get("stance","pragmatic"))
		var line:Dictionary={}
		var roll:float=rng.randf()
		if kind=="report" and (i==0 or roll<0.55):
			line=_say(s,member,_report_bank(member),rng,shuffled[1] if shuffled.size()>1 and i==0 else previous)
		elif i==0:
			line=_say(s,member,kind_bank if roll<0.6 else stances.get(stance,stances.pragmatic),rng,shuffled[1] if shuffled.size()>1 else {})
		elif i==1 and not previous.is_empty() and roll<0.65:
			line=_say(s,member,COURT_BICKER,rng,previous)
		elif i==count-1 and roll<0.6:
			line=_say(s,member,asides,rng,previous,true)
		else:
			line=_say(s,member,stances.get(stance,stances.pragmatic) if roll<0.5 else kind_bank,rng,previous)
		if line.is_empty(): line=_say(s,member,stances.get(stance,stances.pragmatic),rng,previous)
		_append_if(out,line)
		previous=member
	return out

func _report_bank(member:Dictionary)->Array:
	var office:String=(String(member.persona.get("office_key",""))+" "+String(member.persona.get("title",""))).to_lower()
	for key in COURT_REPORT_OFFICE:
		if String(key) in office: return COURT_REPORT_OFFICE[key]
	return COURT_REPORT_ANY

func _offline_speak(s:Dictionary,player_text:String,rng:RandomNumberGenerator)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var mood:=sentiment(player_text)
	var envoy:Dictionary=s.envoy
	var bank:Array=(PETITIONER_REPLY if s.origin=="court" else ENVOY_REPLY).get(mood,ENVOY_REPLY.neutral)
	var rival:Dictionary=s.officials[0] if not s.officials.is_empty() else {}
	_append_if(out,_say(s,envoy,bank,rng,rival))
	if String(s.kind) in ["gift","request","threat"] and mood in ["warm","hostile"] and rng.randf()<0.4 and not String(s.amt).is_empty():
		_append_if(out,_say(s,envoy,TERMS_STAND,rng))
	var reactions:int=rng.randi_range(0,mini(2,s.officials.size()))
	if reactions==0 and not s.officials.is_empty() and rng.randf()<0.6: reactions=1
	var pool:Array=s.officials.duplicate()
	var previous:Dictionary={}
	for i in reactions:
		var member:Dictionary=pool.pop_at(rng.randi_range(0,pool.size()-1))
		var aside:bool=rng.randf()<0.4
		var other:Dictionary=previous if not previous.is_empty() else (pool[0] if not pool.is_empty() else {})
		_append_if(out,_say(s,member,COURT_REACT.get(mood,COURT_REACT.neutral),rng,other,aside))
		previous=member
	return out

func _offline_closing(s:Dictionary,result:Dictionary,rng:RandomNumberGenerator)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var option_id:String=String(result.get("option_id",(s.audience as Dictionary).get("option_id","")))
	var reaction:String=String(result.get("reaction","neutral"))
	var envoy:Dictionary=s.envoy
	if String(s.kind)=="request" and option_id=="refuse": option_id="refuse_request"
	if String(s.kind)=="report":
		if "reward" in option_id: option_id="reward_scouts"
		elif "back" in option_id or "closer" in option_id or "again" in option_id or "resend" in option_id: option_id="send_back"
	var bank:Array=CLOSING_OPTION.get(option_id,CLOSING_REACTION.get(reaction,CLOSING_REACTION.neutral))
	var line:=_say(s,envoy,bank,rng)
	if line.is_empty(): line=_say(s,envoy,CLOSING_REACTION.get(reaction,CLOSING_REACTION.neutral),rng)
	_append_if(out,line)
	if not s.officials.is_empty():
		var member:Dictionary=s.officials[rng.randi_range(0,s.officials.size()-1)]
		var group:="warm" if reaction in ["delighted","pleased"] else ("hostile" if reaction in ["offended","furious"] else "neutral")
		_append_if(out,_say(s,member,CLOSING_ASIDE[group],rng,{},true))
	return out

# ---------------------------------------------------------------------------
# Prompt craft
# ---------------------------------------------------------------------------

static func response_format(keys:Array[String])->Dictionary:
	return {"type":"json_schema","json_schema":{"name":"audience_lines","strict":true,"schema":{
		"type":"object","additionalProperties":false,"required":["lines","mood_shift"],
		"properties":{
			"lines":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["speaker_key","text","aside"],
				"properties":{"speaker_key":{"type":"string","enum":keys},"text":{"type":"string"},"aside":{"type":"boolean"}}}},
			"mood_shift":{"type":"number"}}}}}

static func _mood_words(value:float)->String:
	if value<=-0.5: return "icy; the visitor is barely civil"
	if value<=-0.15: return "frosty"
	if value<0.15: return "wary but civil"
	if value<0.5: return "warming up"
	return "merry; the visitor is enjoying themselves"

func _kind_words(s:Dictionary)->String:
	var civ:String=String(s.civ)
	match String(s.kind):
		"gift": return "An envoy of %s brings a GIFT: %s %s, from their own stores, freely offered." % [civ,s.amt,s.res]
		"request": return "An envoy of %s makes a REQUEST: they ask the ruler for %s %s." % [civ,s.amt,s.res]
		"threat": return "A herald of %s makes a THREAT: they demand %s %s as tribute." % [civ,s.amt,s.res]
		"news": return "A messenger of %s brings NEWS: %s" % [civ,s.fact]
		"report":
			var report:Dictionary=s.get("report",{})
			var brief:Dictionary=(s.get("scout_brief",{}) as Dictionary).duplicate(true)
			brief.erase("persona")   # the cast line below already carries it
			var findings:String=JSON.stringify(brief) if not brief.is_empty() else JSON.stringify(report.get("facts",[]))
			return "The ruler's CHIEF SCOUT returns with a REPORT on %s (source: %s, observed on day %s). Debrief material, the only true findings: %s" % [String(report.get("subject_name","what they found")),String(report.get("source","scouts")),str(report.get("observed_day","?")),findings.substr(0,3200)]
		"petition": return "A PETITION from the ruler's own official (topic: %s). The matter: %s%s" % [s.topic,s.summary," Their proposed remedy: \"%s\"." % s.decree if not String(s.decree).is_empty() else ""]
	return ""

func _audience_want(s:Dictionary,member:Dictionary)->String:
	var persona:Dictionary=member.persona
	if String(member.key)=="envoy":
		if String(s.kind)=="report": return "to be believed, to have the danger or the prize taken seriously, and to be sent out again"
		if s.origin=="court":
			return {"food":"food for the hungry before it turns to panic","health":"the sick tended and the water clean","housing":"roofs over heads before the weather turns",
				"security":"a watch strong enough to sleep behind","grievance":"to be acknowledged, publicly, without grovelling","ambition":"the ruler's yes, and the credit"}.get(String(s.topic),"to be heard and taken seriously")
		return {"gift":"to be thanked lavishly and have the gift admired","request":"to go home with the goods and their pride intact",
			"threat":"to make the ruler flinch and pay without being the one blamed","news":"to be believed, and ideally rewarded, for bringing it first"}.get(String(s.kind),"to be heard")
	var stance:String=String(persona.get("stance","pragmatic"))
	var office:String=String(persona.get("title","")).to_lower()
	var base:String=String(CV.DISPOSITION_WANT.get(stance,"to be heard"))
	if s.kind in ["request","threat"] and ("quartermaster" in office or "steward" in office): base+="; also to keep the stores from being emptied"
	elif s.kind=="threat" and "marshal" in office: base+="; also to not look weak in front of a herald"
	elif s.kind=="news" and "envoy" in office: base+="; also to know more than the messenger does"
	elif s.kind=="petition": base+="; also to not be outshone by the petitioner"
	elif s.kind=="report":
		if "marshal" in office: base+="; also to know how strong their defenses and fighters are"
		elif "quartermaster" in office or "steward" in office: base+="; also to know what they grow, store and might trade"
		elif "scholar" in office: base+="; also to learn their crafts and tricks"
		else: base+="; also to turn the report to their own advantage"
	return base

func build_prompt(s:Dictionary,stage:String,extra:Dictionary)->String:
	var parts:PackedStringArray=PackedStringArray()
	parts.append("SCENE: "+_kind_words(s))
	var ctx:Dictionary=(s.ctx as Dictionary).duplicate(true)
	ctx.erase("court"); ctx.erase("audience_id"); ctx.erase("status"); ctx.erase("mood")
	var facts:String=JSON.stringify(ctx)
	if facts.length()>2400: facts=facts.substr(0,2400)+"...}"
	parts.append("FACTS YOU MAY USE (nothing else is true): "+facts)
	var mood:float=float((s.audience as Dictionary).get("mood",0.0))
	parts.append("ROOM: %s (%.2f)." % [_mood_words(mood),mood])
	var cast:PackedStringArray=PackedStringArray()
	var envoy_label:="the petitioning official" if s.origin=="court" else "the visitor"
	cast.append("- envoy (%s) = %s | in this audience wants %s" % [envoy_label,CV.brief(s.envoy.persona),_audience_want(s,s.envoy)])
	for member in s.officials:
		cast.append("- %s (court official) = %s | in this audience wants %s" % [String(member.key),CV.brief(member.persona),_audience_want(s,member)])
	parts.append("CAST (speaker_key = character; use no one else):\n"+"\n".join(cast))
	var history:PackedStringArray=PackedStringArray()
	var lines:Array=(s.audience as Dictionary).get("lines",[])
	for line in lines.slice(maxi(0,lines.size()-10)):
		history.append("%s%s: %s" % [String(line.get("speaker",""))," (aside)" if bool(line.get("aside",false)) else "",String(line.get("text",""))])
	parts.append("SO FAR:\n"+("\n".join(history) if not history.is_empty() else "(the doors have just opened)"))
	parts.append("NOW: "+_stage_instruction(s,stage,extra))
	return "\n\n".join(parts)

func _stage_instruction(s:Dictionary,stage:String,extra:Dictionary)->String:
	var bench:int=int(s.officials.size())
	match stage:
		"open":
			var who:="'envoy' is the petitioning official: they make their case with feeling and a little self-interest." if s.origin=="court" else "'envoy' speaks first: a greeting with flourish and attitude, then the business in plain terms, exact amounts as given."
			if String(s.kind)=="report": who="'envoy' is the Chief Scout, back from the field. Debrief in 2 to 3 lines: plain-spoken, concrete and sensory (what they saw, heard, smelled, who they met, what surprised or worried them, what they covet), opinionated, with uncertainty spoken naturally ('I'd not swear to it, but...'). Use only the findings supplied; never add numbers, places or events."
			if bench==0: return who+" Nobody else is on the bench, so 'envoy' may add one more line. 1 to 2 lines total. mood_shift 0."
			return who+" Then %d to %d short interjections from different officials: at least one disagrees with another official, at least one is an aside to the ruler, and at least one is funny. End on a line that hands the floor to the ruler. mood_shift 0." % [mini(2,bench),mini(4,bench)]
		"speak":
			return "The ruler just said: \"%s\". 'envoy' answers first, in character: bristle, bargain, bluff, tease or be charmed, but change no terms and accept nothing new. Then 0 to 2 officials react (asides welcome). 1 to 3 lines total. Set mood_shift by how the ruler's words land with 'envoy'." % String(extra.get("player_text",""))
		"closing":
			var result:Dictionary=extra.get("result",{})
			var option_id:String=String(result.get("option_id",(s.audience as Dictionary).get("option_id","")))
			return "The ruler has decided. WHAT ACTUALLY HAPPENED: %s (answer: %s). The visitor's reaction: %s. 'envoy' gives one parting line reacting to exactly this outcome and this reaction; no other outcome, no new promises. Then %s. mood_shift 0." % [String(result.get("outcome","")),option_id if not option_id.is_empty() else "given",String(result.get("reaction","neutral")),"one official gets the last word as an aside to the ruler. Exactly 2 lines" if bench>0 else "stop. Exactly 1 line"]
	return ""
