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
## The live voice heard the ruler perform a spoken act of wrath or favour
## (bounded to divine_regard.gd SPOKEN); the hall validates and applies it.
signal divine_intent(audience_id:String,action:String)
## A court-known persons exchange finished (court_persons.gd result; ok=false
## when the words could not be mapped and the room simply answered).
signal persons_done(audience_id:String,result:Dictionary)

const CV:=preload("res://scripts/character_voice.gd")
const DV:=preload("res://scripts/divine_voice.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const PersonsBridge:=preload("res://scripts/court_persons_bridge.gd")
const PersonsLines:=preload("res://scripts/court_persons_lines.gd")
const Plain:=preload("res://scripts/plain_speech.gd")
const Relevance:=preload("res://scripts/court_relevance.gd")
const DIVINE_SPOKEN:=["terrify","penance","bless","raise_up"]
const HALL_PATH:="res://scripts/audience_hall.gd"
const LIVES_SCENES:=["mourning","callback","omen","aim"]
const SCOUT_PATH:="res://scripts/chief_scout.gd"
const API_TIMEOUT_SECONDS:=45.0
const MAX_ATTEMPTS:=2
const RETRY_DELAY_SECONDS:=0.35
const MAX_COMPLETION_TOKENS:=1600   ## ceiling; each stage asks for less (STAGE_TOKENS)
## Per-stage completion caps. Reasoning models spend part of this on thinking
## (a measured opening used ~260 reasoning + ~260 visible tokens), so the caps
## leave headroom; a reply cut off by the cap retries once with more room.
const STAGE_TOKENS:={"open":1100,"speak":900,"closing":650,"weigh":950,"divine":700,"command":900,"persons":1200}
const MAX_RESPONSE_BYTES:=98304
const USAGE_LIMIT:=40               ## receipts kept in memory (not saved)
const HISTORY_ENTRIES:=5            ## prior audiences described to the model
const AVOID_LINES:=10               ## prior lines the model is told not to echo
const MAX_LINE_CHARS:=300
const MAX_PLAYER_CHARS:=400
const STAGE_LIMITS:={"open":4,"speak":2,"closing":2,"weigh":5,"divine":3,"command":4,"persons":4}
## A proverb or riddle standing in for a thought: no one speaks in it (no I,
## you, we), no one is named, nothing is counted.
const FILLER_OPENING:="(?i)^(a|an|no|every|each|even a|never|the \\w+ that|what the|when the|where the)\\b"
const STANCE_WORDS:="(?i)\\b(i|i'm|i'll|i've|me|my|mine|we|us|our|you|your|yours|let|do|give|send|kill|strike)\\b"
const META_PATTERN:="(?i)\\b(the game|this game|a game|games? (system|mechanic)s?|game ?play|gaming|game mechanics?|mechanics?|players?|buttons?|json|ai|a\\.i\\.|ai models?|artificial intelligence|language models?|llm|chatbot|as an assistant|the prompt|npcs?|click(ed|ing)?|menus?|user interface|save file|schema)\\b"

const SYSTEM_PROMPT:="""You write live dialogue for a royal audience hall in a fictional history. Speak only through the characters listed; no narration, no stage directions, no explanations.

Every speaker has a distinct voice (word choice, rhythm, temper) and private wants that show in what they ask for. Envoys bargain, press, boast and defend their people's pride about the actual business. Be SUCCINCT: few speakers, lines of one sentence (never more than about 20 words), no filler, no throat-clearing, no stock quips; every line says something concrete about this situation. When the ruler asks a question, answer it directly from the facts. Paraphrase terms in the speaker's own voice; never recite the FACTS text. Never a recital of choices. A secret only ever leaks sideways. Address terms and oaths are seasoning: each speaker uses their address term at most once in a reply and an oath rarely (most lines have none), and skips any listed as recently used. Never reuse the wording, openings or jokes of the lines listed as said before; people who have been here before remember how it went and say so.

Plain speech: people say concrete things about the situation in front of them: who, what, how much, what it costs, what they want the god to do and why. Character shows through word choice, rhythm and temper, never through sayings. Never invent maxims, proverbs, aphorisms or riddles: no "X is best Y", no "a Z is a W", no "N fills bellies, but a fox leaves tracks", no kennings or poetic compounds (word-hoard, border-song, trail-leader), no comic or food nicknames for the god. At most one short, natural, era-true idiom per speaker in a whole scene, and usually none. Use the real names, places, amounts and strings given.
Bad: "Feast-Giver, a free bundle is best counted twice: it asks no carrying, no return, and feeds many hearths!" Good: "Great One, it's forty hides and they want nothing back. I'd take it."
Bad: "Gift-food fills bellies, but a fox leaves tracks." Good: "The meat is welcome, but Elarin will expect our hunters at their fire next spring."
Bad: "Their word-hoard will call it theft; twenty meals buy a long border-song." Good: "Elarin will call this theft. Twenty meals isn't worth a feud on the border."

Court officials are silent by default. Only officials in the CAST may speak, and an official beside the one addressed speaks at most ONE line, only when it carries real guidance the ruler cannot already see: a hidden string, a tell or risk, a fact about these people, a serious objection with concrete stakes, an answer to a question put to them, or their own life or kin at stake. Never a line that praises, repeats or comments on the order, the gift or the choice. If an official has nothing like that, leave them out.

Manner: each speaker is given a MANNER modelled on a figure from classic literature or history. Write in that manner (cadence, sentence length, diction, rhetorical habits, worldview) but in wholly original words, translated into this world: never quote or paraphrase the source's famous lines and never name the figure, its author or its story.

The world: people know only what the WORLD line lists. Anything not listed does not exist yet and must never appear, not even as a metaphor, oath, nickname or joke: no beer or ale before brewing, no metal before smelting, no coin, writing, ledgers, scrolls, wheels, carts, ships, sails, temples, priests, glass, bread or ploughs unless listed. Reach instead for weather, beasts, hunting, fire, stone, bone, rivers, ancestors, seasons, stars, hearths and kin.

The ruler is the living god of their own people, and the god's command is law. Officials never flatly refuse an order: they may fear, plead or protest briefly in their own manner, but whether an order is obeyed is decided before you write, and you are told; write only what was decided. When the ruler gives an order you are not told the outcome of, answer briefly and do not refuse. No filler: never a proverb, riddle or stock saying; say plain things plainly. Officials address and treat the ruler as divine, each in the way their REGARD line says: the loving are frank and warm, the frightened flatter, soften bad news and overpromise, the resentful let it leak sideways, the proud stand straight even under wrath. Foreign envoys regard the ruler as their people do. The god's wrath is presence, words and real decrees carried out by people; never invent miracles, omens, curses that come true or any supernatural event.

Truth: use only the facts supplied. Never invent amounts, goods, agreements, promises, battles, deaths, alliances or events; say amounts exactly as given or not at all. Nobody announces or assumes what the ruler will decide. Nobody talks down to the ruler: never "child", "dearie", "boy", "girl", "pet" or any diminutive. Nobody agrees to new terms. Never mention games, systems, mechanics, buttons, menus, AI or data formats.

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
		"{oath} {leader} sends you {amt} {res}, {address}. {leader} will tell you what {civ} wants for it, and so will I.",
		"We hauled {amt} {res} across bad country to bring it here, {address}. It comes from {leader}, with a condition I'll name plainly.",
		"{leader} told me to hand you {amt} {res}, {address}, and to be honest about what {civ} expects in return.",
		"A gift from {civ}, {address}: {amt} {res}. It isn't free; hear the terms before you take it.",
		"Before anyone asks what it costs, {address}: {leader} will say. First, {amt} {res} from {civ}.",
	],
	"request":[
		"I'll not dress it in ribbons, {address}: {civ} needs {amt} {res}, and I'd not be standing here if we didn't.",
		"{leader} sent me to ask for {amt} {res}, {address}, and I was told not to come home without an answer.",
		"Our stores are nearly empty, {address}, and I hate asking. {amt} {res} would carry us to the thaw.",
		"{oath} I'll ask fast, {address}: {amt} {res} for {civ}, and we'll pay it back when our hunting recovers.",
		"Straight to it, {address}: {amt} {res}. {civ} won't forget who helped us this winter.",
	],
	"threat":[
		"{leader} wants {amt} {res} as tribute, {address}, and {leader} is not a patient person. I'm the patient one, and I'm already bored.",
		"Let's be friends, {address}. Friends share, so you'll share {amt} {res} with {civ}, and we'll stay the very best of friends.",
		"{oath} Lovely hall, {address}, and such sturdy doors. It'd be a shame to test them, so let's talk about {amt} {res} instead.",
		"These are {leader}'s words, not mine, so glare at the words, {address}: {amt} {res}, or {civ} remembers you as the ones who refused.",
		"I'll keep this short, {address}, so you'll have more time to count out {amt} {res}.",
	],
	"news":[
		"Word from the road, {address}, only days old: {fact}",
		"{oath} Nobody else was going to tell you, {address}, so it falls to me. {fact}",
		"You'll want to sit down for this, {address}, or lean on something ruler-ish. {fact}",
		"I ran the last stretch to be first with this, {address}, so kindly ignore the wheezing. {fact}",
		"{leader} wanted you to hear this from us before anyone else, {address}. {fact}",
	],
	"report":[
		"Back in one piece, {address}, mostly. We've had a long look at {subject}, and I'll give it you straight.",
		"{oath} Muddy, tired and full of opinions, {address}. We've seen {subject}, and I'll tell you what I saw and not a hair more.",
	],
	"petition_grievance":[
		"I've a grievance, {address}, and I've held it in long enough. {why}",
		"{oath} I'll say this to your face, {address}, since saying it behind your back has worn thin. {why}",
		"I've swallowed this three times now, {address}, and it won't stay down. {why}",
	],
	"petition_ambition":[
		"I've a notion, {address}, a good one, and yes, it happens to involve me.",
		"Hear me out before {rival} starts sighing, {address}; this one's worth the whole afternoon.",
		"{oath} Let me do something grand for once, {address}. You'll get the credit and I'll get the blisters. Fair?",
	],
	"petition_generic":[
		"I'd not trouble you with a small thing, {address}. This one gets worse every week we leave it.",
		"Somebody has to say it, and everybody else has suddenly found something to polish.",
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
		"The sick are stacking up, {address}, and the healthy have started to fear the water.",
		"{oath} I passed sickbeds in three doorways on my way here, {address}, and I'd rather not count them on my way back.",
		"There's coughing in every doorway, {address}. If we wait for it to pass, it'll pass through all of us.",
	],
	"housing":[
		"About {homeless} of our people are sleeping under sky and sackcloth, {address}, and the sky isn't getting any warmer.",
		"{oath} I've had folk asking to sleep in my woodshed, {address}. About {homeless} of them without a proper roof, and my woodshed isn't that big.",
		"Folk are sleeping in doorways and under hides, {address}. The next cold rain will put some of them in sickbeds.",
	],
	"security":[
		"The watch is too thin, {address}; two tired people can't cover the whole edge of the camp at night.",
		"{oath} I lie awake listening for boots, {address}, and I'd very much like them to be ours.",
		"Here's what keeps me up at night, {address}: {summary}",
	],
}

const DECREE_PLEA:={
	"Send gatherers to find food":"Send gatherers out, {address}, today, while the ones who'd go can still walk.",
	"Ration food for thirty days":"Cut the portions now, {address}: thirty days of tight belts, before the belts are all we've left to boil.",
	"Secure water and dig wells":"Put spades in hands and dig wells, {address}, before more people drink from the fouled stream.",
	"Organize healers to care for the sick":"Give the healers hands and orders, {address}, and let them fight this properly.",
	"Build shelters":"Let's raise shelters, {address}, before the first hard frost catches people sleeping outside.",
	"Raise a watch and post guards":"Raise a proper watch and post guards, {address}, and let the rest of us sleep a night through.",
	"Support scholars and fund research":"Set more hands to study, under my eye, {address}, and I'll bring you answers to questions you haven't thought of yet.",
	"Expand workshops and make tools":"Enlarge the workshops and let us make tools in earnest, {address}; half our people are working with worn-out axes.",
	"Post guards and patrol the frontier":"Let me put patrols along the frontier, {address}, so we see strangers coming before they reach the camp.",
	"Hold a public council to hear the people":"Call a public council, {address}, and let the people say it to our faces instead of muttering at the fires.",
	"Improve roads and organize haulers":"Mend the roads and organize the haulers, {address}; half our troubles are things arriving late or not at all.",
}
const DECREE_PLEA_GENERIC:="I'd have you proclaim it plainly, {address}: {decree}. Say the word and I'll carry it out myself."

const COURT_STANCE:={
	"sycophantic":[
		"Whatever you answer, {address}, {leader} will hear it by the next moon, so let it be something that makes us look strong.",
		"I'll back whatever you decide, {address}, but {civ} is close enough to matter either way.",
		"You needn't answer {civ} today, {address}; making them wait a night costs us nothing.",
		"I'll agree with you, {address}, I always do, but {leader} sent a talker, not a fighter. They want something.",
	],
	"cantankerous":[
		"I don't like it, {address}. {civ} doesn't send people this far without wanting something back.",
		"Before you agree to anything, {address}, ask what {leader} gets out of it. They haven't said.",
		"{oath} Nobody asked me, {address}, but I'd give {civ} nothing until they say plainly what they're after.",
		"Another visitor from {civ} with a big idea, {address}. Ask what it costs us before they finish smiling.",
	],
	"principled":[
		"They've said what they want, {address}. Give them a plain yes or no and our reason for it.",
		"No flattery from me, {address}. Decide whether it's fair to our own people first; {civ} can look after theirs.",
		"I'm not charmed, {address}. We still don't know everything {leader} wants, and I'd ask before we answer.",
	],
	"diplomatic":[
		"Don't scowl at them yet, {address}. {civ} stays our neighbour whatever we answer today.",
		"We can answer this without sending {leader} home angry, {address}, and I'd like us to try.",
		"Calm down, {rival}. Shouting at {civ}'s envoy only hands {leader} a grievance.",
	],
	"pragmatic":[
		"Three questions, {address}: what does it cost us, who carries it, and by when?",
		"Before we agree to anything, {address}, I want to know what we'd have to give up for it.",
		"I've done the sum roughly, {address}, and I'd like to do it again slowly before anyone promises {civ} anything.",
	],
}
## Stance lines for petitions and reports, where the speaker is one of our own.
const COURT_STANCE_COURT:={
	"sycophantic":[
		"{petitioner} has a point, {address}, and if you act on it the people will know it was you.",
		"Hear {petitioner} out, {address}; they've been closer to this than anyone else in the hall.",
	],
	"cantankerous":[
		"{oath} Before you nod, {address}, ask {petitioner} what it'll cost and who'll do it.",
		"I'll believe it's that bad when I've seen it, {address}. {petitioner}, how many people, exactly?",
	],
	"principled":[
		"{petitioner} is right, {address}. I've seen it too, and I'd say so even if they hadn't asked.",
		"The problem is real, {address}. Either give the order or tell {petitioner} plainly why not.",
	],
	"diplomatic":[
		"Let {petitioner} finish before anyone argues, {address}; they walked here to say it.",
		"Don't let this turn into blaming, {address}. It needs hands, and {petitioner} can say how many.",
	],
	"pragmatic":[
		"Fine, {address}, but who does the work, and what stops getting done while they do it?",
		"I'll back it once someone tells me whose hands come off other work to do it, {address}.",
	],
}

const COURT_KIND:={
	"gift":[
		"Take it, {address}, but let {rival} look the {res} over first; spoiled {res} is worse than none.",
		"{civ} will ask for something back, {address}. Take it only if you can live with what they ask.",
		"{amt} {res} with terms attached, {address}. I want to know exactly what {civ} expects before we accept.",
		"Accepting ties us to {civ}, {address}; refusing insults them. Weigh the terms, not the size of the gift.",
	],
	"request":[
		"We need our {res} too, {address}. If we give {amt}, somebody here eats less this winter.",
		"That's {amt} {res} we won't have ourselves, {address}; I'm only saying it now so nobody faints later.",
		"If {civ} goes hungry on our border, {address}, their hunters will come for it anyway. Giving some may cost us less.",
		"Give {civ} {amt} {res} now, {address}, and expect them back next lean season asking again.",
	],
	"threat":[
		"Don't pay, {address}. Hand over {amt} {res} now and {civ} will ask for more next year.",
		"{rival}, put the knife away; they can see it, and it makes us look frightened.",
		"We could pay, {address}, but {amt} {res} is a lot to hand over for a threat nobody has backed with spears yet.",
		"This envoy is only saying what {civ} told them to, {address}. It's their chief who's testing us.",
	],
	"news":[
		"If it's true, {address}, it matters to us. If it isn't, somebody in {civ} wants us to believe it.",
		"Ask how they know, {address}. Did they see it themselves, or hear it at someone's fire?",
		"{oath} If that's true, {address}, we should send our own scouts to look.",
		"I'd heard something like it, {address}, but nothing I'd have brought you without more.",
	],
	"petition":[
		"{petitioner} isn't exaggerating, {address}. I've heard the same from others this month.",
		"They're right, {address}, much as I'd like them not to be. It needs an answer today.",
		"This time {petitioner} has said exactly what to do, {address}. That's more than most who stand there.",
		"I raised this at council a while back, {address}, and nobody acted. It's worse now.",
	],
}

const COURT_REPORT_OFFICE:={
	"marshal":["How many fighters do they have, {address}, and how many days away are they? That's what I need from this.","If they have fighters, {address}, I want a count and where they camp."],
	"quartermaster":["Did anyone look at their stores, {address}? If they're full, they can afford a quarrel with us.","Never mind the scenery, {address}: what do they eat, how much of it, and would they trade it?"],
	"steward":["Where exactly did they go, {address}, and how many days' walk is it? The rest can wait.","Have the scouts tell it again at the council fire, {address}, so everyone hears the same account."],
	"scholar":["If they know a craft we don't, {address}, I want to know exactly how they do it.","I'd like the scouts to tell me all of it tonight, {address}, before the details change in the retelling."],
	"envoy":["If they met our scouts without spears, {address}, I can work with that.","Did they greet our scouts or just watch them, {address}? That tells me whether to send an envoy."],
}
const COURT_REPORT_ANY:=[
	"I'd like the plain version, {address}: how many, how far, and whether they saw us.",
	"{petitioner} tells it bigger than it was, {address}. Ask how many they actually counted.",
	"Have it told again at council, {address}, because {rival} will argue about it later.",
	"Either they're rich or they want to look it, {address}. Worth knowing before we trade with them.",
]

const COURT_BICKER:=[
	"{rival}, you keep sighing, but you haven't offered anything better.",
	"{rival} is only thinking of their own people's work, {address}. Ask what it costs everyone.",
	"For once I agree with {rival}, {address}. That should tell you how clear this one is.",
	"That's bad advice, {rival}. If we do that, {civ} will take it as weakness.",
	"{rival} is right, {address}, but it's the cost that matters here, not our pride.",
]

const COURT_ASIDE:=[
	"They keep glancing at the door, {address}. I think they expected a harder answer.",
	"Their furs are new, {address}. They may be better off than they're letting on.",
	"Take your time answering, {address}. They need this more than we do, or they'd not have walked so far.",
	"Count the {res} before you thank them, {address}. We don't know these people well yet.",
	"They've rehearsed this, {address}. Ask them something they didn't expect and see what they say.",
	"If this goes badly, {address}, double the watch on the path they came by.",
]
const COURT_ASIDE_COURT:=[
	"Between us, {address}, {petitioner} has asked for this for a year. It's urgent now because it got worse.",
	"If you say yes, {address}, have {petitioner} report back in a few days so we know it's working.",
	"If you say no, {address}, tell {petitioner} why. They'll take a reason better than a flat refusal.",
]
const COURT_ASIDE_REPORT:=[
	"Scouts tell the frightening part first, {address}. Ask them for numbers before you act.",
	"If even half of that is true, {address}, I'd put more people on watch tonight.",
]

const ENVOY_REPLY:={
	"warm":[
		"Ha! You flatter well, {address}. I'll tell {leader} you were charming, and I'll leave out the parts where you weren't.",
		"Kind words, {address}. {civ} expected a colder welcome, and I'll tell them they were wrong.",
		"{oath} Careful, {address}, or I'll start liking it here, and then who'll carry the grudges home?",
		"That's a warmer welcome than {leader} expected, {address}. I'll say so when I'm home.",
	],
	"hostile":[
		"Careful, {address}. I repeat everything I hear to {leader}, and {leader} has a temper.",
		"{oath} I've been insulted by better, {address}. No, that's a lie; that one was quite good.",
		"Say that again, slower, {address}, so I can repeat it to {leader} exactly as you meant it.",
		"Bold talk, {address}, for someone sitting under such a very dry thatch.",
	],
	"question":[
		"A fair question, {address}, and here's a fair answer: I've told you all I was told, and a little of what I wasn't.",
		"Ask {leader} yourself, {address}, and bring food; it's a long answer.",
		"I don't know, {address}. {leader} doesn't tell me everything, and I won't guess.",
	],
	"neutral":[
		"I'll carry that home exactly as you said it, {address}, and let {leader} judge it.",
		"Noted, {address}: noted, remembered, and very possibly embroidered.",
		"Was that a yes, {address}? It sounded a little like a yes and a little like a cough.",
	],
}
const TERMS_STAND:=[
	"That's kindly said, {address}, but {leader} still wants {amt} {res}.",
	"All the same, {address}, the matter stands where it stood, at {amt} {res}.",
]

const PETITIONER_REPLY:={
	"warm":["Thank you, {address}; I'd kneel, but my knees have opinions of their own.","That's more than I hoped for from a corridor day, {address}, and I'll take it with both hands."],
	"hostile":["I'll pretend I didn't hear that, {address}, but my face won't manage it.","{oath} I came in with one problem, {address}, and now I'm leaving with two."],
	"question":["Ask anyone who's been where I've been lately, {address}; they'll tell you the same, only with more swearing.","That's all I know, {address}. I saw it myself, and I haven't added anything."],
	"neutral":["I'll wait, {address}; I'm good at waiting, as the corridor will tell you.","That's not a no, {address}, so in my head I'm calling it a yes."],
}

const COURT_REACT:={
	"warm":["That landed, {address}. They'll carry a kinder report home than they planned.","They weren't expecting that, {address}. If you want better terms, ask now while they're pleased.","Keep it warm, {address}; a friendly neighbour means one less border to guard."],
	"hostile":["That was hard, {address}. If they carry it home that way, expect fewer visitors and more watchers.","You've rattled them, {address}. I'd put a watch on the path they take home.","{rival} agrees with you, {address}, but I'd not push further unless you want a quarrel."],
	"question":["Good question, {address}. If they can't answer it, they know less than they claim.","See whether they answer that or talk around it, {address}."],
	"neutral":["You've promised nothing, {address}. That leaves you free to decide later.","Leaving them unsure gives us time to find out more, {address}."],
}

## Called in by the ruler with nothing of their own to raise: short, plain,
## and handing the floor back. Kept free of later-era idiom.
const SUMMONS_OPEN:=[
	"You sent for me, {address}. What do you need?",
	"I came as soon as I heard. What is it?",
	"Here I am. Say what you want of me.",
	"You called? I was in the middle of something, but it can wait.",
	"I'm listening, {address}. What's on your mind?",
	"Nothing pressing on my side. What's on yours?",
	"You wanted me? Then ask.",
	"I left the work to the others. What do you need me for?",
	"Well, I'm here. Tell me what this is about.",
	"My hands are free for the moment. Use them.",
	"Ask your question; I'll answer it straight.",
	"I had nothing to bring you today. Have you something for me?",
]
## A summoned official hears a plain order: they take it, briefly.
const ORDER_ACK:=[
	"It'll be done. I'll take it to the council myself.",
	"Understood. I'll see it started today.",
	"Then that's the order. I'll pass it on.",
	"As you say. The council will have it by nightfall.",
	"Done, or as good as. I'll tell you how it goes.",
	"Plain enough. I'll get people moving.",
	"I'll carry it out. Expect grumbling.",
	"Right. I'll put it in hand.",
]
## Asked something a summoned official has no facts for: honest and short.
const SUMMONS_REPLY:=[
	"I'd have to ask around before I answered that.",
	"I don't know enough to say, and I won't guess.",
	"Not my part of the work. I can find out.",
	"I've heard talk, nothing I'd swear to. Give me a few days.",
	"Nobody's brought that to me. I'll ask.",
	"I can tell you what I've seen, and it isn't much on that.",
]
const SUMMONS_CLOSING:=[
	"Then I'll get back to it.",
	"Understood. Send for me again when you need me.",
	"As you say. I'll be where I always am.",
	"Good. I'll be off, then.",
	"I'll go. Call if anything changes.",
	"Then that's settled. Back to work.",
]

const CLOSING_OPTION:={
	"dismiss_summons":SUMMONS_CLOSING,
	"accept":["{oath} Good! {leader} will be glad the {res} found a proper home, {address}.","Received and appreciated, {address}? Then my feet can finally stop aching with purpose."],
	"accept_return":["A gift back, {address}? Now I owe you a gift for the gift for the gift. This will never end, and I love it.","{oath} A courteous court! {leader} will hear you sent something home with me, and I'll tell it well."],
	"refuse":["Refused, {address}? Then I carry {amt} {res} home again, and the story with it.","You send it back, {address}. {leader} doesn't often hear 'no, thank you', so let's see how {leader} takes it."],
	"refuse_request":["No, then. I'll carry an empty sack home, {address}, and it's heavier than it looks.","Refused, {address}? {civ} will remember that, and I'll remember your face while you said it."],
	"grant":["{oath} All of it, {address}? I'll sing about you on the road, badly but sincerely.","{civ} won't forget this, {address}, and for once that's good news for you."],
	"grant_half":["Half, then, {address}. I'll tell {leader} you split it fairly.","Half, {address}. It won't last us to the thaw, but it helps."],
	"pay":["Sensible, {address}. {leader} likes sensible; sensible tends to live longer.","The {res} will be counted twice, {address}; {leader} trusts nobody, least of all me."],
	"defy":["No tribute, {address}? {oath} I'll tell {leader} exactly how you said it, word for word.","Nothing, then? Brave, {address}. I'll carry your nothing home; at least it's lighter than {res}."],
	"counter":["Threat for threat, {address}? Ha! Now we're finally speaking the same tongue.","{oath} Snarling back at me, {address}? {leader} will enjoy that, though 'enjoy' is the wrong word."],
	"thank":["Thanks will do, {address}. Just remember I brought it to you first.","Glad to be of use, {address}; just remember who told you first."],
	"reward":["A reward, {address}? For me? I was going to tell everyone you're wonderful anyway, but now I'll do it with feeling.","{oath} You pay your messengers, {address}? I may never leave."],
	"apologise":["Well, that's said, {address}. I'll put the grudge back on its shelf; not away, mind, just on the shelf.","An apology from the seat itself, {address}? I may need to sit down."],
	"rebuke":["As you like, {address}. I'll remember whom I serve, and how.","{oath} Rebuked in front of everyone, {address}. I'll take it, and I'll remember it."],
	"decree":["You'll proclaim it, {address}? {oath} Then I'll see it done, and I'll hold you to every word.","That's the stuff, {address}; I'll roll up my sleeves before you can change your mind."],
	"promise":["A promise to think on it, {address}. I've eaten on less; not well, but I've eaten.","I'll hold you to the thinking, {address}, so please think quickly."],
	"reward_scouts":["{oath} Fed and thanked! The party will be insufferable for a week, {address}, and they've earned it.","A reward, {address}? I'll pass it round the fire, though the tall one will eat double."],
	"send_back":["Back out we go, {address}. Good; I was getting soft sitting still, and there's more to see.","There's more to see, right enough, {address}. I'll have my boots on before supper."],
	"dismiss":["Dismissed, {address}. I'll carry my problem back out that door, where it'll carry on growing.","{oath} As you wish, {address}; just don't be surprised when I'm proved right."],
}
const CLOSING_REACTION:={
	"delighted":["{oath} Now that's a court, {address}! {leader} will hear of this with music.","I came with a speech ready for disappointment, {address}, and now I'll have to burn it. Happily."],
	"pleased":["Fair and done, {address}. {civ} will remember this kindly, which for us is a great deal of remembering.","Good. I'll sleep on the road tonight, {address}, and not even mind the rocks."],
	"neutral":["So be it, {address}. I'll tell {leader} it went neither well nor badly.","I'll carry your answer home as you gave it, {address}, with hardly any embroidery."],
	"offended":["Ah. I see how it is, {address}, and {leader} will see it too, once I describe your face.","{civ} won't forget this, {address}, and neither will I."],
	"furious":["{oath} You'll regret this, {address}, the next hard winter you need {civ}.","I'll go, {address}, and {leader} will hear every word of this."],
}
const CLOSING_ASIDE:={
	"warm":["That went well, {address}. Send someone to them before winter, while they still feel friendly.","They left pleased, {address}. That's one border we can watch less closely this season.","They'll report kindly at home, {address}. Next time they may bring more than words."],
	"neutral":["Nothing settled, {address}. I'd send a small gift next season to keep it from souring.","They'll be back with the same question, {address}. We should settle our answer before then."],
	"hostile":["They left angry, {address}. Expect a cold welcome if we send anyone their way.","I'd double the watch tonight, {address}, on the paths toward their country.","They'll tell that at home the worst way it can be told, {address}, and their young hunters will hear it."],
}

## More openings, so a people's envoys can visit often without reciting.
const ENVOY_OPEN_MORE:={
	"gift":[
		"{civ} doesn't send gifts to just anyone, {address}. Today it's {amt} {res}, and today it's you.",
		"I was told to say this is a small token, {address}. It's {amt} {res}; I carried it, and it is not small.",
		"{leader} insisted: {amt} {res}, straight into your hands, {address}, and no haggling over thanks.",
		"Fair warning, {address}: I'm terrible at ceremony. Here are {amt} {res} from {civ}. There, that's the ceremony.",
		"{oath} Stores full at home, so {leader} said share. {amt} {res}, {address}, with our good wishes stacked on top.",
	],
	"request":[
		"I've walked a long way to say one short thing, {address}: {civ} needs {amt} {res}.",
		"{leader} would rather eat bark than ask, {address}, and we've tried the bark. {amt} {res}, if you can spare it.",
		"Plain words from a plain envoy, {address}: {amt} {res}, and {civ} will remember the kindness.",
		"We're not beggars, {address}; we're neighbours in a lean season. {amt} {res} would see us through.",
		"{oath} I drew the short straw, {address}, so I'm the one asking: {amt} {res} for {civ}.",
	],
	"threat":[
		"I'm told to be polite, {address}, so politely: {amt} {res}, or {leader} stops being polite.",
		"{leader} wants {amt} {res} as the price of peace, {address}. That's the whole message.",
		"{oath} Here's the message, {address}, word for word: {amt} {res}. The rest was mostly shouting.",
		"You have a fine harvest and a thin wall, {address}. {leader} suggests {amt} {res} to keep both.",
		"Let's not waste each other's afternoon, {address}. {amt} {res}, and {civ} stays on its side of the hills.",
	],
	"news":[
		"I heard it three times on the road before I believed it, {address}. {fact}",
		"{oath} Keep this among your council for now, {address}. {fact}",
		"Fresh from the fires of {civ}, {address}, and not yet cold: {fact}",
		"{leader} thought you'd rather know than guess, {address}. {fact}",
		"I'll tell it plain and you can decorate it later, {address}. {fact}",
	],
}

# --- Situations (the hall's situation record) ----------------------------------
# {occasion} is why they came (a short phrase or clause from the engine);
# {summary} the plain facts of a proposal; {when}/{matter} the earlier
# audience an arc continues.

const OCCASION_OPEN:=[
	"You'll know why I've come, {address}: {occasion}.",
	"It comes down to this: {occasion}. That is what brings me to your fire.",
	"Let's not pretend otherwise, {address}: {occasion}, and so here I stand.",
	"I'd not have walked all this way for less. {occasioncap}.",
	"You may have heard already, {address}, but I'll say it plainly: {occasion}.",
]
const ARC_OPEN:={
	"cooler":["Since {when}, things between us have cooled.","We parted coldly {when}. I've come back anyway.","Things have been chilly since {when}. I'd like to change that."],
	"threat_after_refusal":["You refused us {when}. {leader} has not forgotten.","Since your refusal {when}, the talk at our fires has turned hard.","{whencap} you said no. {leader} took it badly."],
	"emboldened":["You paid {when}. {leader} learned to ask again.","What you gave {when} was noticed. So was how easily.","{whencap} you paid without a fight. {leader} remembers that."],
	"respect":["You stood firm {when}. {leader} respects that.","Since you faced us down {when}, we think better of you.","{whencap} you didn't bend. We came back with an open hand."],
	"test_of_resolve":["You stood up to us {when}. Was it a mood or a habit?","We've come to see if {when} was real.","{whencap} you held firm. {leader} wants to test it."],
	"second_thoughts":["After {when}, {leader} had second thoughts.","Hard things were said {when}. Some of us would unsay a few.","Since {when}, we've reconsidered."],
	"gratitude":["What you did for us {when} isn't forgotten.","{whencap} you helped when you needn't have. We've come to square it.","You carried us through {when}. We remember."],
	"alliance_feeler":["What passed between us {when} set people talking, the good kind.","Since {when}, {leader} wonders how far our friendship might go.","{whencap} went well. {leader} wants more of it."],
	"warming":["Things have warmed since {when}. Let's keep that fire fed.","Since {when}, our people speak more kindly of yours.","{whencap} started something good between us."],
	"promise_unkept":["{whencap} you promised {matter} would be considered. Still waiting.","Your promise about {matter}, from {when}, is still only a promise.","You promised {matter} {when}. Nothing since."],
	"refused_ambition":["You turned down {matter} {when}. I have better reasons now.","I haven't let {matter} go since {when}.","{whencap} you said no to {matter}. Hear me again."],
	"any":["We spoke {when}, and here I am again.","You'll remember {when}. I certainly do."],
}
const PROPOSAL_OPEN:={
	"any":["{leader} offers {gist}.","We've come to propose {gist}.","{leader} wants {gist}. So do I."],
	"accord_offer":["{leader} would bind our peoples in {gist}."],
	"protection_pact":["If one of us is attacked, the other comes. We propose {gist}."],
	"league_invitation":["Several peoples are joining together. We offer {gist}."],
	"war_support":["We're at war, and {leader} wants to know where you stand."],
	"peace_feeler":["I come under a sign of truce. {leader} offers {gist}."],
	"trade_offer":["You have things we lack, and we have things you lack. We propose {gist}."],
	"nonaggression_offer":["Neither of us can afford a war. We propose {gist}."],
	"scholar_offer":["We've learned things worth teaching. {leader} offers {gist}."],
	"research_sale":["We've learned things you haven't. We offer {gist}."],
	"license_offer":["We have a craft worth sharing. We offer {gist}."],
	"recruitment_protest":["{leader} wants your word it ends today.","Give your word it stops, and we'll forget it happened.","Stop it, and there's no quarrel between us."],
}
const COURT_PROPOSAL:=[
	"We hardly know them, {address}. I'd want to see them keep a smaller promise before this one.",
	"It sounds generous, {address}. I'd like to know what {leader} expects from us in return.",
	"If we say yes, we're tied to them when trouble comes. If we say no, we meet the trouble alone.",
	"I'd want to know what they aren't saying, {address}.",
	"If we agree, {address}, someone has to hold them to it every season, and I'd like to know who.",
]
const PETITION_PLEA_MORE:={
	"introduction":["I've come to present myself, {address}, and to say plainly what I mean to do in this office.","New to the post and not shy about it: I'm here so you'll know my face before you need it.","You gave me this charge, {address}. I've come to show you it wasn't a mistake."],
	"follow_up":["I'm here about what we spoke of before, {address}. It hasn't gone away.","You'll remember the matter; it certainly remembers us."],
	"war":["The war sits on everyone's shoulders, {address}, and I've come to say how heavy it's getting.","About the fighting: I've things to say the others won't.","Every day of this war costs us something, {address}. I've come to talk about what."],
	# fun-pop: the people are dwindling; {summary} names who dies and why (dwindling_cause.gd).
	"people":["{summary} I count the graves every winter, {address}, and there are more each time.","We buried more of our own than were born to us, {address}. {summary}"],
}
const CLOSING_MORE:={
	"welcome":["A warm welcome! I'll try to be worth it.","That's more than I expected, {address}. I'll start earning it tomorrow."],
	"patience":["Patience, then. I've plenty, though it's thinner than it was.","I'll wait, {address}, but I'll be counting the days."],
	"stand":["You stand with us! {leader} will hear it before the moon turns.","Then we are shoulder to shoulder. Good."],
	"counsel_peace":["Peace, you say. Easy counsel from far away, {address}, but I'll carry it.","I'll tell {leader} you urged peace. Whether anyone listens is another matter."],
	"abstain":["Staying out of it. That's an answer too, and a careful one.","Neither side, then. I'll tell them you're watching."],
	"restraint":["You'll call your people off? Then we can speak as neighbours again.","Restraint. Good. Our households will sleep easier."],
	"compensate":["You make it right with goods. {leader} will take that as an honest apology.","Paid for, then. It doesn't mend it all, but it mends enough."],
	"rebuff":["Rebuffed. I'll carry that home, {address}, and it won't travel quietly.","So that's how you answer an open hand."],
	"decline":["Declined, politely. I'll say you were courteous about it.","No, then. We asked like neighbours and you answered like one."],
	"accept_proposal":["Agreed! {leader} will be glad, and so, between us, am I.","Then it's settled between our peoples. Let's both keep it."],
	"refuse_proposal":["You choose to fight on. Then we will meet again, and not in a hall.","No? Then the war goes on, {address}, and it rests on you as much as us."],
}

# --- Answers: when the ruler asks, the visitor answers from the facts ----------
const QUESTION_PATTERNS:=[
	["ifno","(?i)\\b(if (we|i) (say no|refuse|decline|don't|do not)|and if (we|i)|what if|or else|if not)\\b"],
	["enforce","(?i)(keeps? the peace|breaks? it|who enforces|who holds)"],
	["whyshould","(?i)\\bwhy should (we|i|my people|you)\\b"],
	["whynot","(?i)(solved already|why not (before|sooner)|why has (this|it) not|why hasn't)"],
	["support","(?i)\\bwho else (supports|backs|agrees)\\b"],
	["whoelse","(?i)\\bwho else\\b"],
	["howlong","(?i)\\bhow long\\b"],
	["source","(?i)(how do you know|how sure|how certain|who told you)"],
	["strength","(?i)(would they fight|are they strong|how many|could they)"],
	["surprise","(?i)surprise"],
	["gain","(?i)(gain|get out of|hope this buys|this buys|in return|give in return|what do you want|what does your people|what do your people)"],
	["need","(?i)(what (do )?you need|tell me plainly|what is it you|what do you ask|what do you want)"],
	["why","(?i)\\bwhy\\b"],
]
const ANSWERS:={
	"why":{
		"recruitment_protest":["Because more of our families leave every moon.","Because it has happened once too often."],
		"gift":["{leader} wanted to show goodwill with something you could hold.","Our stores are full this year, and {leader} wants friends for the years they aren't.","{leader} would rather be remembered for giving than taking.","We noticed you. We'd rather you noticed us kindly."],
		"request":["We held out as long as we could. We can't any longer.","The cold came early and the hunting failed.","You're the nearest fire with food to spare."],
		"threat":["{leader} smells weakness on your border.","{leader} thinks you'll pay. Prove otherwise, or don't.","We're stronger this season, and {leader} knows it."],
		"news":["What happens there will reach you soon.","So you'll remember we were the ones who warned you.","{leader} wants you to hear it from us first."],
		"proposal":["Better settled now, while both sides are calm.","Both our peoples are tired of watching the border.","{leader} would rather have you beside us than facing us."],
		"petition":["It's getting worse, and faster than anyone admits.","Nobody else will say it, and it won't wait.","I've watched it grow a season. I'm done watching."],
		"report":["What we saw is moving this way.","You'd want to know before they come closer."]},
	"ifno":{
		"recruitment_protest":["Then we guard our households ourselves, and the border sours.","Then {leader} stops calling it a mistake."],
		"gift":["Then I carry it home, and {leader} remembers the refusal.","Then it goes home with me, and so does the insult.","Then we part a little cooler than we met."],
		"request":["Then we go home hungry, and some of our young hunters may come raiding for it.","Then some of ours won't see the thaw, and we'll remember who refused.","Then we find it elsewhere, and remember who didn't help."],
		"threat":["Then {leader} decides what comes next. I wouldn't wager on patience.","Then our hunters come to collect it themselves.","Then the border gets a great deal less quiet."],
		"proposal":["Then nothing binds us, and the border stays as nervous as it is.","Then we go on as before: watching each other, trusting nobody.","Then {leader} looks for friends elsewhere, and finds them."],
		"petition":["Then it gets worse out of your sight, until it's too big to fix quickly.","Then I'll be back, and it will be worse.","Then we'll pay for it later, and more.","Then the people will stop asking and start muttering."],
		"news":["Then you'll hear it later, from someone less friendly."]},
	"gain":{
		"recruitment_protest":["Our families stay at our own fires, and there's no quarrel between us.","Peace at the border, and our households left alone.","Nothing but what's ours: our own people, at home."],
		"gift":["Goodwill, and a friendly hearing the next time we come.","A friend at your border instead of a stranger.","Your good opinion, and maybe your help one day."],
		"request":["Full bellies this season, and a debt we'd honour.","Our people alive to the thaw. We'd repay it in kind.","A neighbour who owes you. That's worth something."],
		"threat":["{amt} {res}, and your caution. Both are useful to us.","Your stores, and your respect. In that order."],
		"proposal":["{gistcap}; you gain the same, and a quieter border.","Safety from one more quarter. You'd have the same from us.","Fewer spears pointed our way. Yours too."],
		"petition":["What I need is simple: {decree}.","Only this: {decree}. Nothing for me.","Nothing for me. For them: {decree}."]},
	"need":{
		"petition":["{decreecap}. That's the whole of it.","Plainly? {decreecap}, and soon.","One order: {decree}. The rest follows."],
		"request":["{amt} {res}. No more, no less.","Just {amt} {res}, and quickly."],
		"proposal":["Your word on {gist}. Nothing more today.","A yes, and a hand on it.","Only your answer. The rest can wait for spring.","Your word. We'll hold you to nothing else."],
		"any":["Your answer, today.","A plain yes or no."]},
	"howlong":{
		"request":["Until the thaw, if the hunting returns.","A season, maybe less, if the rains keep faith."],
		"petition":["A season, if we start now.","Not long, if we start before the cold.","Until it's done, and I'll see it done."],
		"any":["Until the job's done. I'll report when it is.","Until the next thaw, no longer."]},
	"source":{
		"news":["Travellers' word, and my own eyes for some of it.","Three camps told me the same, and they agree on nothing else."],
		"report":["Sure enough to go back and look again.","I saw most of it myself. The rest I'd not swear to."],
		"any":["I saw it, or I wouldn't say it."]},
	"whoelse":{
		"any":["Nobody yet that I know of. Yours is the first fire I came to.","A few travellers. It'll be everywhere by the next moon.","Our own people, and now you. Nobody else.","Whoever sat at the last few fires I passed. It won't stay quiet long."]},
	"support":{
		"petition":["Half the court, quietly. The other half once it works.","Everyone who's seen it. Ask them.","The people who carry the load. They're tired of carrying it.","More than will say so in this hall."]},
	"strength":{
		"report":["They'd fight, but they'd rather not. Their watch is thin.","If pushed, yes. They have the numbers but not the stomach."]},
	"surprise":{
		"report":["How calm they were. They didn't seem worried about anyone.","Their numbers. More than their smoke suggests."]},
	"enforce":{
		"proposal":["If either of us breaks it, the other is free to act, and both our peoples will know why.","We both do. If {leader} broke it, you'd be right to tell every neighbour."]},
	"whyshould":{
		"request":["Because next season it may be you asking, and we'll remember.","Because we'd do the same, and have, for others."],
		"threat":["Because {leader} is closer than your friends are.","You needn't want to. You should want the alternative even less."],
		"any":["Because it costs you little now, and it will be remembered."]},
	"whynot":{
		"petition":["Everyone hoped it would pass. It didn't.","Nobody gave the order. You can.","Everyone thought someone else would do it.","It was small. It isn't now."]},
}

# --- Why they came, in natural speech, by occasion type -------------------------
# Two halves combine, so the same occasion never opens the same way twice.
const OCCASION_SPEECH:={
	"first_contact":[["We've watched your smoke from across the hills for a season.","Our hunters have crossed your trails since the thaw.","Travellers have talked of your fires all winter.","We've seen your people at the far river more than once."],["It seemed time to meet face to face.","{leader} sent me to put a face to the smoke.","Better to meet in a hall than by accident in the woods.","So here I am, the first of us at your fire."]],
	"relation_warm":[["Our people have come to think well of yours.","Things have gone well between us lately.","{leader} speaks of you kindly these days."],["We'd like to build on it.","I've come to keep it that way.","That's worth tending, so here I am."]],
	"relation_cool":[["Things between our peoples have cooled.","There's a chill between us lately.","{leader} has grown wary of you."],["I'm here before it freezes.","I've come to see whether it can be mended.","Better we talk while we still can."]],
	"tension_rise":[["The border between us has grown tense.","Our watchers and yours have started counting each other.","There's been too much staring across the border."],["I'd rather talk than wait for it to snap.","Someone has to speak first.","That's how fights start, so I came."]],
	"war_end":[["The fighting between us is over.","The war has ended, and both sides are counting the cost."],["I've come to see what grows in its place.","Now we find out what peace looks like."]],
	"peace_possible":[["{leader} has lost the taste for this war.","Our people are tired of burying their own."],["I've come to talk about ending it.","There may be a way out, if you want one."]],
	"their_famine":[["Our stores are failing.","The hunting failed and our stores are nearly gone.","Our people are going hungry."],["I won't dress it up.","That's why I'm here.","I'm not too proud to say it."]],
	"recruitment_incident":[["Your people have been luring our households away.","Families of ours have been talked into leaving for your fires."],["It has to stop.","{leader} won't let it pass."]],
	"third_war":[["{occasioncap}.","Have you heard? {occasioncap}."],["Nobody will stay out of it for long.","It will reach your border soon enough."]],
	"sequel":[["I've come about what came of our last meeting.","Our last meeting left things unfinished."],["It's time to settle it.","Let's finish it properly."]],
	"ambient":[["It's been a long silence between our peoples.","We haven't spoken in too long."],["{leader} thought it time to change that.","So I've come to break it.","Our people have started to wonder what yours are doing."]],
	"ambition":[["I've been turning a plan over for a while.","There's an idea I can't put down."],["It's ready to be said aloud.","Hear me out."]],
	"war_council":[["It's the war.","The fighting weighs on everyone."],["I've come to talk about where it's going.","Someone has to speak plainly about it."]],
}

## A proposal's terms, as a speaker would put them (the herald carries the data).
const PROPOSAL_GIST:={
	"accord_offer":"an understanding between our peoples, sharing what we learn",
	"protection_pact":"a pact to defend each other when attacked",
	"league_invitation":"a place in a league of peoples",
	"war_support":"your people's support in their war",
	"peace_feeler":"an end to the fighting and a year's truce",
	"trade_offer":"a standing trade between our peoples",
	"nonaggression_offer":"a promise that neither people attacks the other",
	"scholar_offer":"a visiting teacher, paid in goods",
	"research_sale":"what their people have learned, for goods",
	"license_offer":"the right to use their craft, for a price",
	"recruitment_protest":"that your people stop luring their households away",
}

# --- Memory across audiences --------------------------------------------------
# Tokens: {when} (how long ago, in words) {matter} (what it was about) {nth}
# (ordinal of this visit or this answer) {count} (cardinal, this one included).

## The visitor's opening when they have stood here before, keyed by how it went.
const HISTORY_OPEN:={
	"promised":[
		"{whencap} you promised {matter} would be considered. I'm still waiting.",
		"The {nth} time I've come about {matter}, and still nothing done.",
		"I've carried your promise about {matter} since {when}. It's getting heavy.",
		"You said you'd think on {matter}. That was {when}.",
		"Back about {matter}, the {nth} time, and people are still waiting on it.",
		"Remember {when}? {mattercap}, you said, would be considered.",
		"Your promise from {when} is still only a promise.",
		"You promised {matter} {when}. Nothing has moved since.",
		"I've waited since {when} on {matter}. Patience is thinning.",
		"The {nth} visit about {matter}, and still no order.",
	],
	"decreed":[
		"You ordered {matter} {when}, and it did good. There's more of it to do.",
		"Your word on {matter} {when} worked. So I've come back.",
		"You trusted me with {matter} {when}. It held. Hear me again.",
		"What you ordered {when} worked. Now for the next piece.",
	],
	"rebuffed":[
		"You sent me off {when}. This matters too much to stay away.",
		"Dismissed over {matter} {when}, and it's got worse since.",
		"I know how it went {when}. I'm asking again, with better reasons.",
		"You refused {matter} {when}. It hasn't gone away.",
	],
	"soothed":[
		"You heard me kindly {when}. That's why I came back.",
		"Your fair words {when} did their work. Let's do it again.",
	],
	"kept_waiting":[
		"{whencap} I waited in your corridor until I gave up. I'm back.",
		"Last time nobody saw me at all. This is my {nth} try.",
		"I came {when} about {matter} and never got past the door.",
	],
	"heard":[
		"We spoke about {matter} {when}. Here I am again.",
		"About {matter} again. Things have moved since {when}, not all the right way.",
		"The {nth} time about {matter}. I'll make it worth hearing.",
		"Since {when}, {matter} has only grown.",
	],
	"welcomed":[
		"{leader} still talks of how you received us {when}.",
		"{whencap} you dealt fairly with {civ}. {civ} remembers.",
		"Last time the answer was kind, so they sent me again.",
		"Our last envoy came home {when} speaking well of you.",
		"The {nth} time {civ} has stood in this hall. We keep coming back.",
		"You were generous {when}. We haven't forgotten.",
		"Good to see this hall again. It was kind to us {when}.",
	],
	"spurned":[
		"{whencap} you turned {civ} away. {leader} has not forgotten.",
		"Last time we left with nothing. I'm told not to take it personally.",
		"You sent our last envoy home empty-handed {when}.",
		"{civ} remembers every word you said {when}.",
		"We were refused {when}. We've come anyway.",
	],
	"left_waiting":[
		"{whencap} our envoy waited in your antechamber until they gave up.",
		"The last of us never got a hearing. {leader} wants to know why.",
	],
	"visited":[
		"{civ} was here {when}, and here we are again.",
		"The {nth} time {civ} has sent someone. Draw your own conclusions.",
		"We spoke {when}. Much has changed since.",
		"Since our last visit {when}, a good deal has changed at home.",
	],
}

## Officials remembering that this has come up before.
const COURT_HISTORY:=[
	"{petitioner} was here about this {when}, {address}, and nothing was done then either.",
	"We heard this {when}, {address}. It's back because we never settled it.",
	"Same request as {when}, {address}, and more urgent now.",
	"If we'd settled {matter} {when}, {address}, it wouldn't be in front of us again.",
	"That's the {nth} time {matter} has come before you, {address}. Give the order or say plainly no.",
]
const COURT_HISTORY_FOREIGN:=[
	"{civ} again, {address}. Ask what's changed since last time; they asked for much the same.",
	"Remember how {civ} took our answer {when}, {address}? They'll be expecting the same one.",
	"The {nth} visit from {civ}, {address}. Either they want something steady from us or they're counting our spears.",
	"{when} they stood there and said much the same, {address}. Listen for what's different.",
]

## A farewell when the ruler gives the same answer again.
const CLOSING_REPEAT:={
	"promise":[
		"That's {count} promises now, {address}. I'm keeping them in a box, and the box is getting full.",
		"Another promise, {address}. I'll set it beside the one from {when} and see if either comes to anything.",
		"Considered again, {address}. At this rate {matter} will be the most considered thing in the land.",
		"The {nth} promise, {address}. I'll hold you to this one, and to the others too.",
	],
	"decree":[
		"You've given me my way {count} times now, {address}. I'll try to be worth it.",
		"Again you say yes, {address}; the {nth} time. I'll see it done faster than last time.",
	],
	"dismiss":[
		"Dismissed again, {address}. That's {count} times; I'm starting to know the door by its knots.",
		"The {nth} time you've sent me off, {address}. The problem doesn't mind; it'll still be there.",
	],
	"rebuke":[
		"Rebuked again, {address}. That's the {nth} time, and the court is counting too.",
		"{count} rebukes, {address}. I'll wear them, but I'll not forget them.",
	],
	"accept":["{civ} gives and you take, {address}: the {nth} time, and it's starting to look like friendship.","{count} gifts received, {address}. {leader} will call that a habit; I'd call it a start."],
	"refuse":["No again, {address}. That's {count} times; {leader} keeps a tally stick for this.","The {nth} refusal, {address}. I'll carry it home with the others."],
	"refuse_request":["No again, {address}. That's {count} times; {leader} keeps a tally stick for this.","The {nth} time we go home empty, {address}. People will stop asking, and not in a good way."],
	"grant":["You've helped us {count} times now, {address}. Nobody at home will believe it.","The {nth} time you've filled our sacks, {address}. {civ} owes you, and knows it."],
	"grant_half":["Half again, {address}. That's {count} halves; I'll let {leader} do the sum.","The {nth} half-measure, {address}. It helps, but it won't carry us through."],
	"pay":["Paid again, {address}. {leader} will call this a habit; I'd call it a warning.","The {nth} tribute, {address}. {leader} will send me back; I'd rather they didn't."],
	"defy":["Defied again, {address}, the {nth} time. {leader} won't keep sending envoys forever.","{count} times you've told us no, {address}. {leader} is running out of patience and I'm running out of road."],
	"counter":["Threats again, {address}, the {nth} time. One of these days somebody will mean it."],
	"thank":["The {nth} time I've brought you word, {address}, and the {nth} time you've been decent about it."],
	"reward":["Rewarded again, {address}! {count} times now; I'll start bringing news on purpose."],
	"any":["Same answer as {when}, {address}. At least you're consistent.","You said much the same {when}, {address}. I'll carry it home the same way."],
}
const CLOSING_ASIDE_MORE:={
	"warm":["They'll be back, {address}, and after today they'll come asking, not demanding.","They'll speak well of us at home, {address}. That makes next season's trading easier.","That's one people less likely to raid us this winter, {address}."],
	"neutral":["Nothing settled, {address}. They'll want a firmer answer next time.","We gave nothing away, {address}, and they didn't leave angry.","We'll hear how they reported it soon enough, {address}; traders pass through their camps."],
	"hostile":["I'll have someone watch the road tonight, {address}.","That went badly, {address}. They'll tell it at home as an insult.","Remember that envoy, {address}. If they come back, it'll be with more people."],
}

## Remedies phrased several ways; composed with PLEA_FRAMES so the same
## decree is never pleaded in the same words twice running.
const REMEDY:={
	"Send gatherers to find food":["send gatherers out for food","put foragers on every path out of here","send the strongest out gathering before the weak can't walk"],
	"Ration food for thirty days":["cut the portions for thirty days","ration the stores for a month","put everyone on short portions for thirty days"],
	"Secure water and dig wells":["dig wells and guard the clean water","put spades to new wells","guard the clean water before more of it goes bad"],
	"Organize healers to care for the sick":["give the healers hands and orders","set healers over the sick, properly organized","gather the healers and let them work"],
	"Build shelters":["raise shelters before the frost","get roofs over the people sleeping rough","build shelters, plain and quick"],
	"Raise a watch and post guards":["raise a proper watch","post guards and keep them posted","put a watch on the walls and mean it"],
	"Support scholars and fund research":["set more hands to study","feed the scholars and let them work","give the thinkers time and food"],
	"Expand workshops and make tools":["enlarge the workshops and make tools","put more hands and hearths into the workshops","make tools in earnest"],
	"Post guards and patrol the frontier":["patrol the frontier","put patrols along the border","walk the frontier with spears, regularly"],
	"Hold a public council to hear the people":["call a public council","hold an open council and hear the people","gather the people in council and let them speak"],
	"Improve roads and organize haulers":["mend the roads and organize the haulers","fix the roads and give the haulers a proper plan","set crews on the roads and order to the hauling"],
}
const PLEA_FRAMES:=[
	"{remedy}, {address}. That's the whole of it, and it isn't small.",
	"My ask is plain, {address}: {remedy}.",
	"What I want from this hall is simple to say, {address}: {remedy}.",
	"{oath} {remedy}, {address}, and I'll see it done myself.",
	"If you do one thing this season, {address}, {remedy}.",
	"I'm asking you to {remedy}, {address}. Not someday; now.",
	"Here's the remedy, {address}, and it costs less than the trouble: {remedy}.",
	"Let me put it in one line, {address}: {remedy}, before it gets worse.",
	"Give the word to {remedy}, {address}, and I'll carry it out before the dust settles.",
	"You needn't love the idea, {address}; just {remedy}.",
]
const TOPIC_MATTER:={"food":"the food stores","health":"the sickness","people":"the empty cradles","housing":"shelter for the homeless","security":"the watch","grievance":"my grievance","ambition":"my proposal","introduction":"my new charge","follow_up":"the old matter","war":"the war"}
const ORDINALS:=["first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth"]
const CARDINALS:=["one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]

var hall:Variant=null          ## injected by tests; otherwise loaded from HALL_PATH
var force_offline:=false       ## tests / "no AI" play
var send_hook:Callable         ## tests: replaces the HTTP transport (id, payload, attempt)
var config_override:Dictionary={} ## tests: pretend a connection is configured
var last_problem:Dictionary={} ## audience_id -> reason the live voice fell back
## func(audience_id:String, player_text:String, command:Dictionary)->bool: the
## court's command engine (set by the modal). The live classifier read the
## ruler's words as an order; true means the engine carried it out, and the
## model's provisional lines are dropped (they did not know the outcome).
var command_router:Callable=Callable()
## Cost receipts, one per HTTP attempt plus one per offline delivery. Bounded,
## in memory only: they describe this session's spend, not the campaign.
var usage:Array[Dictionary]=[]
var totals:Dictionary={"calls":0,"accepted":0,"failed":0,"offline":0,"prompt_tokens":0,"completion_tokens":0,"reasoning_tokens":0,"total_tokens":0,"latency_ms":0}
var remembered:Dictionary={}    ## audience_id -> the line in which the visitor recalled a past audience
var _compat:Dictionary={}      ## endpoint quirks learned this session: no_reasoning_effort, no_schema
var _requests:Dictionary={}
var _used:Dictionary={}

# ---------------------------------------------------------------------------
# Public API (contract)
# ---------------------------------------------------------------------------

func busy(audience_id:String)->bool:
	return _requests.has(audience_id)

func open_scene(audience_id:String)->void:
	_begin(audience_id,"open",{})

## True when a live model is configured (the court may let it read orders).
func is_live()->bool:
	return not _config().is_empty()

## offline_order: the offline reading found only a general order; the live
## classifier may read it more exactly, and if it does not, the general order
## still goes to the court's command engine (never lost).
func player_speaks(audience_id:String,text:String,offline_order:bool=false)->void:
	var clean:String=text.strip_edges().replace("\n"," ").substr(0,MAX_PLAYER_CHARS)
	if clean.is_empty(): return
	var h:Variant=_hall()
	if h==null or (h.find(audience_id) as Dictionary).is_empty():
		failed.emit(audience_id,"No audience is waiting.")
		return
	# The ruler's words land in the transcript immediately, before any reply.
	h.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":clean,"day":_day(),"aside":false})
	_begin(audience_id,"speak",{"player_text":clean,"offline_order":offline_order})

## Words about people (who is responsible, tell me of, summon, questioning,
## accusation, judgment) with a live model: ONE call maps them onto the
## court_persons.gd action vocabulary and writes the scene for what the engine
## decides; the engine then applies it and the exchange is learned for offline
## play. Offline there is no parsing: the Court offers choices instead.
func persons_turn(audience_id:String,text:String)->void:
	var clean:String=text.strip_edges().replace("\n"," ").substr(0,MAX_PLAYER_CHARS)
	if clean.is_empty(): return
	var h:Variant=_hall()
	if h==null or (h.find(audience_id) as Dictionary).is_empty(): return
	h.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":clean,"day":_day(),"aside":false})
	_begin(audience_id,"persons",{"player_text":clean,"menu":Persons.menu(audience_id,true)})

func closing(audience_id:String,result:Dictionary)->void:
	_begin(audience_id,"closing",{"result":result.duplicate(true)})

## Wonder proposals: the court weighs the chosen concept at the chosen ambition
## (assess() factors in the officials' own words). Appends a short round.
func weigh(audience_id:String)->void:
	_begin(audience_id,"weigh",{})

## The god has acted (AudienceHall.divine result): the target reacts in their
## manner (unless removed) and the watching court murmurs. Only those who
## actually witnessed it speak.
## The engine carried out (or the actor hesitated at, or refused) a command
## (court_commands.gd). A bracketed stage direction shows what happened, the
## one who acted answers as the engine decided, a witness murmurs, and the
## factual outcome closes it.
func command_reaction(audience_id:String,result:Dictionary)->void:
	var seen:Array=(result.get("witness_ids",[]) as Array).duplicate()
	var actor:Dictionary=result.get("actor",{}) if result.get("actor") is Dictionary else {}
	var target:Dictionary=result.get("target",{}) if result.get("target") is Dictionary else {}
	if int(actor.get("person_id",0))>0 and not int(actor.person_id) in seen: seen.append(int(actor.person_id))
	if int(target.get("person_id",0))>0 and not bool(result.get("removed",false)) and not int(target.person_id) in seen: seen.append(int(target.person_id))
	if bool(result.get("removed",false)): seen.erase(int(target.get("person_id",0)))
	if String(result.get("stage",""))=="refuse_flee": seen.erase(int(actor.get("person_id",0)))
	_begin(audience_id,"command",{"result":result.duplicate(true),"witness_ids":seen})

func divine_reaction(audience_id:String,result:Dictionary)->void:
	var witnesses:Array=[]
	var effects:Dictionary=result.get("effects",{}) if result.get("effects") is Dictionary else {}
	for wid in (effects.get("witnesses",{}) as Dictionary): witnesses.append(int(wid))
	_begin(audience_id,"divine",{"result":result.duplicate(true),"witness_ids":witnesses})

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
	CV.registry=_voice_state()
	var envoy_persona:Dictionary
	var figure_persona:=_work_speaker_persona(audience)
	if not figure_persona.is_empty():
		envoy_persona=figure_persona
	elif origin=="court":
		var person:Dictionary={}
		var pid:int=int(speaker.get("person_id",0))
		if pid>0 and GovernmentPeopleSystem.has_method("person_snapshot"): person=GovernmentPeopleSystem.person_snapshot(pid)
		if person.is_empty(): person={"person_id":pid,"name":String(speaker.get("name","")),"traits":[]}
		person["office_title"]=String(speaker.get("title",person.get("office_title","")))
		var known:Dictionary=Persons.by_id(String(speaker.get("known_id",""))) if String(speaker.get("known_id",""))!="" else {}
		envoy_persona=Persons.persona(known) if not known.is_empty() else CV.for_person(person)
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
	if String(s.kind) in WORK_KINDS:
		s["work"]=(ctx.get("wonder_proposal",ctx.get("great_work",{})) as Dictionary).duplicate(true)
		s["gwtok"]=_work_tokens(s)
	# Why they came and what it continues (the hall's situation record).
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation",{}) is Dictionary else {}
	if situation.is_empty() and ctx.get("situation",{}) is Dictionary: situation=ctx.get("situation",{})
	s["situation"]=situation
	s["sit_type"]=String(situation.get("type",ctx.get("situation_type","")))
	s["headline"]=String(situation.get("headline",""))
	s["sit_summary"]=String(situation.get("summary",""))
	s["occasion"]=situation.get("occasion",{}) if situation.get("occasion",{}) is Dictionary else {}
	s["arc"]=situation.get("arc",{}) if situation.get("arc",{}) is Dictionary else {}
	if String(s.summary).is_empty(): s["summary"]=String(s.sit_summary)
	# Words the true facts themselves use are allowed to every speaker.
	s["fact_tags"]=CV.lexicon_tags_in(" ".join(PackedStringArray([JSON.stringify(s.get("report",{})),JSON.stringify(s.get("scout_brief",{})),String(s.fact),String(s.summary),String(s.sit_summary),String(s.decree),String((s.occasion as Dictionary).get("text",""))])))
	s["regard"]=_hall_regard(audience_id,h)
	s["history"]=history_for(s)
	var focus:=_history_focus(s)
	s["history_focus"]=focus
	s["htok"]=_history_tokens(s,focus,_same_matter_count(s,focus))
	var arc:Dictionary=s.arc
	if not arc.is_empty():
		# An arc continues a known earlier audience: that is what they remember.
		var previous:Dictionary=arc.get("previous",{}) if arc.get("previous",{}) is Dictionary else {}
		var entry:={"day":int(previous.get("day",_day())),"decree":String(previous.get("decree","")),"kind":String(previous.get("kind","")),"topic":String(previous.get("topic","")),"option_id":String(previous.get("option",""))}
		s["arc_entry"]=entry
		s["htok"]=_history_tokens(s,entry,maxi(1,_same_matter_count(s,entry)))
	return s

func _hall_regard(audience_id:String,h:Variant)->Dictionary:
	## The speaker's love and dread (or their people's), when the hall knows it.
	var value:Variant={}
	if h is GDScript: value=(h as GDScript).call("regard_of",audience_id)
	elif h is Object and (h as Object).has_method("regard_of"): value=(h as Object).call("regard_of",audience_id)
	return value if value is Dictionary else {}

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
# Relevance gate (court_relevance.gd): court members are silent by default.
# ---------------------------------------------------------------------------

## Who among the officials has real guidance in this exchange, scored from
## game state alone: named or asked by the ruler, a witness who resents what
## the god did, or the stores keeper when the ask is a large share of what we
## hold. Returns the single best candidate ({} when nobody clears the bar).
func court_gate(s:Dictionary,stage:String,extra:Dictionary)->Dictionary:
	var officials:Array=s.get("officials",[])
	if officials.is_empty(): return {}
	var cands:Array=[]
	var player_text:=String(extra.get("player_text",""))
	if stage in ["speak","persons"] and not player_text.is_empty():
		for m:Dictionary in officials:
			if Relevance.addressed(player_text,m): cands.append({"kind":"direct_question","text":player_text,"key":String(m.key)})
	if stage in ["divine","command"]:
		var result:Dictionary=extra.get("result",{}) if extra.get("result") is Dictionary else {}
		var effects:Dictionary=result.get("effects",{}) if result.get("effects") is Dictionary else {}
		var seen:Dictionary=effects.get("witnesses",{}) if effects.get("witnesses") is Dictionary else {}
		for m:Dictionary in officials:
			var w:Variant=seen.get(int(m.person_id),seen.get(str(int(m.person_id)),{}))
			var resp:=String((w as Dictionary).get("response","")) if w is Dictionary else ""
			if resp in ["unbowed","envy"]: cands.append({"kind":"dissent","text":"%s is %s after the god's act; that is a risk to watch" % [String(m.name),resp],"key":String(m.key),"response":resp})
	if stage in ["open","speak"] and String(s.kind) in ["request","threat"]:
		# A real cost the ruler may not have weighed: the share of our stores asked.
		var stock:=int((s.get("ctx",{}) as Dictionary).get("player_stock_of_terms",-1))
		var amount:=int(String(s.get("amt","0"))) if String(s.get("amt","")).is_valid_int() else 0
		if stock>0 and amount>0 and float(amount)/float(stock)>=0.3:
			for m:Dictionary in officials:
				if _office_group(m)!="quartermaster": continue
				var share:=float(amount)/float(stock)
				var words:="more than we hold" if share>1.0 else ("nearly all we hold" if share>=0.75 else ("more than half of what we hold" if share>=0.5 else "a third of what we hold"))
				var left:=maxi(0,stock-amount)
				var variants:=["%d %s is %s: we have %d." % [amount,String(s.res),words,stock],"They want %d of the %d %s we hold. That leaves %d." % [amount,stock,String(s.res),left],
					"Giving %d %s leaves us %d of our %d." % [amount,String(s.res),left,stock],"That is %s. %d %s out of %d." % [words,amount,String(s.res),stock]]
				var said:Dictionary=_voice_state().said
				var text:=""
				for i in variants.size():
					var v:=String(variants[(i+posmod(hash(String(s.id)),variants.size()))%variants.size()])
					if not said.has(_text_key(v)): text=v; break
				if text.is_empty(): break
				cands.append({"kind":"objection","key":String(m.key),"text":text})
				break
	var visible:=" ".join(PackedStringArray([String(s.get("summary","")),String(s.get("fact","")),String(s.get("headline",""))]))
	return Relevance.pick(cands,visible)

## Prunes the cast to the principal speakers plus, at most, the one official
## the gate chose; records the choice as s["gate"]. Weighing a great work and
## the persons exchange keep their casts (their officials are the business).
func apply_court_gate(s:Dictionary,stage:String,extra:Dictionary)->void:
	if stage in ["weigh","persons"] or String(s.get("kind","")) in WORK_KINDS:
		s["gate"]={"all":true}
		return
	var gate:=court_gate(s,stage,extra)
	s["gate"]=gate
	var keep:={}
	if not gate.is_empty(): keep[String(gate.key)]=true
	if stage=="command":
		var result:Dictionary=extra.get("result",{}) if extra.get("result") is Dictionary else {}
		for role in ["actor","target"]:
			var entry:Dictionary=result.get(role,{}) if result.get(role) is Dictionary else {}
			var member:=_member_for(s,entry)
			if not member.is_empty(): keep[String(member.key)]=true
	s["officials"]=(s.officials as Array).filter(func(m:Dictionary)->bool:return keep.has(String(m.key)))

func _gate_key(s:Dictionary)->String:
	var gate:Dictionary=s.get("gate",{}) if s.get("gate") is Dictionary else {}
	return String(gate.get("key",""))

# ---------------------------------------------------------------------------
# Request lifecycle
# ---------------------------------------------------------------------------

func _begin(audience_id:String,stage:String,extra:Dictionary)->void:
	if busy(audience_id): return
	var s:=scene(audience_id)
	if s.is_empty():
		failed.emit(audience_id,"No audience is waiting.")
		return
	if stage in ["divine","command"] and String(s.origin)=="court":
		# Only those who saw it may speak of it (a successor was not there).
		var seen:Array=extra.get("witness_ids",[])
		s["officials"]=(s.officials as Array).filter(func(m:Dictionary)->bool:return int(m.person_id) in seen)
	# Court members are silent unless they have real guidance; the one who
	# does (if any) is the only official in this exchange's cast.
	apply_court_gate(s,stage,extra)
	var config:=_config()
	if config.is_empty():
		_receipt_offline(s,stage,offline_reason())
		_deliver_offline(s,stage,extra,"")
		return
	if stage=="closing":
		# The decision is made and shown: a farewell needs no model. The persona
		# bank reacts to the actual outcome just as truthfully, for free.
		_receipt_offline(s,stage,"closing kept offline: the ruler said nothing" if not _ruler_spoke(s) else "closing kept offline: the outcome is already decided",String(config.get("model","")))
		_deliver_offline(s,stage,extra,"")
		return
	var request:=prepare_request(s,stage,extra,config)
	_requests[audience_id]=request
	_send(audience_id)

func prepare_request(s:Dictionary,stage:String,extra:Dictionary,config:Dictionary)->Dictionary:
	var keys:=cast_keys(s)
	var payload:={"model":String(config.get("model","")),"max_completion_tokens":int(STAGE_TOKENS.get(stage,MAX_COMPLETION_TOKENS)),"messages":[
		{"role":"system","content":SYSTEM_PROMPT},
		{"role":"user","content":build_prompt(s,stage,extra)},
	]}
	# Dialogue needs little deliberation; low effort keeps reasoning tokens (and
	# latency) down. Endpoints that reject the field lose it for the session.
	if not bool(_compat.get("no_reasoning_effort",false)) and "api.openai.com" in String(config.get("endpoint","")).to_lower():
		payload["reasoning_effort"]="low"
	var divine:Array=_divine_allowed(s) if stage=="speak" else []
	if stage=="command" or stage=="persons": keys.append("narrator")
	if bool(config.get("structured_output",false)) and not bool(_compat.get("no_schema",false)): payload["response_format"]=PersonsBridge.response_format(keys) if stage=="persons" else response_format(keys,divine,stage=="speak")
	var headers:PackedStringArray=PackedStringArray(["Content-Type: application/json","Authorization: Bearer %s" % String(config.get("api_key","")),"X-Client-Request-Id: audience-%s-%d" % [String(s.id),Time.get_ticks_msec()]])
	return {"scene":s,"stage":stage,"extra":extra,"config":config,"payload":payload,"headers":headers,"keys":keys,
		"attempts":0,"max_attempts":MAX_ATTEMPTS,"downgraded":false,"http":null}

func _send(audience_id:String)->void:
	if not _requests.has(audience_id): return
	var request:Dictionary=_requests[audience_id]
	request.attempts=int(request.attempts)+1
	var attempt:int=int(request.attempts)
	request["started_ms"]=Time.get_ticks_msec()
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
	var envelope:=_envelope_facts(body)
	var receipt:=_receipt_http(audience_id,request,result,response_code,envelope)
	var detail:=""
	if ok_http and String(request.stage)=="persons":
		var why:=_persons_response(audience_id,request,body,receipt)
		if why=="": return
		detail=why
	elif ok_http:
		var parsed:=parse_body(body)
		if parsed.is_empty():
			detail="reply cut off at the token cap" if String(envelope.get("finish_reason",""))=="length" else ("model declined to answer" if bool(envelope.get("refusal",false)) else "reply was not the expected JSON")
		else:
			var s:Dictionary=request.scene
			var heard_command:Dictionary=parsed.get("command",{})
			if not (String(heard_command.get("act",""))=="command" and String(heard_command.get("verb","none"))!="none" and float(heard_command.get("confidence",0.0))>=CC.LIVE_CONFIDENCE):
				heard_command=GENERAL_ORDER if bool((request.extra as Dictionary).get("offline_order",false)) else {}
			if String(request.stage)=="speak" and command_router.is_valid() and not heard_command.is_empty():
				# An order: the engine decides and acts first; these lines were
				# written before anyone knew the outcome, so they are dropped.
				_requests.erase(audience_id)
				if bool(command_router.call(audience_id,String((request.extra as Dictionary).get("player_text","")),heard_command)):
					_finish_receipt(receipt,true,false,"")
					last_problem.erase(audience_id)
					return
				_requests[audience_id]=request
			var lines:=validate_lines(parsed.get("lines",[]),s,String(request.stage),request.extra)
			if not lines.is_empty():
				_requests.erase(audience_id)
				_finish_receipt(receipt,true,false,"")
				last_problem.erase(audience_id)
				_deliver(s,String(request.stage),request.extra,lines,float(parsed.get("mood_shift",0.0)))
				# --- interaction database capture (single call; audience UI owned by codex/court) ---
				if String(request.stage)=="speak": preload("res://scripts/interaction_capture.gd").capture_chat_body("summon" if String(s.get("origin",""))=="summoned" or String(s.get("kind","")).begins_with("summon") else "audience",String(request.extra.get("player_text","")),body,parsed)
				# --- end capture ---
				var heard:=String(parsed.get("divine","none"))
				if String(request.stage)=="speak" and heard in DIVINE_SPOKEN and heard in _divine_allowed(s): divine_intent.emit.call_deferred(audience_id,heard)
				return
			detail="every line failed validation (%d proposed)" % (parsed.get("lines",[]) as Array).size()
			# A readable reply whose every line broke the rules would cost as much
			# again and likely fail the same way: the offline line answers instead.
			_finish_receipt(receipt,false,true,detail)
			_requests.erase(audience_id)
			last_problem[audience_id]=detail
			_deliver_offline(s,String(request.stage),request.extra,detail)
			return
		if String(envelope.get("finish_reason",""))=="length":
			# The model ran out of room (usually reasoning). One retry with more.
			request.payload["max_completion_tokens"]=mini(MAX_COMPLETION_TOKENS,int(float(request.payload.get("max_completion_tokens",600))*1.6))
	elif result==HTTPRequest.RESULT_SUCCESS and response_code in [400,415,422] and not bool(request.downgraded):
		# Some compatible endpoints reject optional fields. Retry once without
		# them (remembered for the session); this retry does not consume the
		# ordinary one.
		var dropped:PackedStringArray=PackedStringArray()
		var complaint:String=String(envelope.get("error","")).to_lower()
		var names_field:bool="reasoning" in complaint or "response_format" in complaint or "schema" in complaint or "json" in complaint
		if request.payload.has("reasoning_effort") and ("reasoning" in complaint or not names_field):
			request.payload.erase("reasoning_effort");_compat["no_reasoning_effort"]=true;dropped.append("reasoning_effort")
		if request.payload.has("response_format") and (("reasoning" not in complaint and names_field) or dropped.is_empty()):
			request.payload.erase("response_format");_compat["no_schema"]=true;dropped.append("strict JSON schema")
		if not dropped.is_empty():
			request.downgraded=true
			request.max_attempts=int(request.max_attempts)+1
			var why:="endpoint rejected %s (HTTP %d)" % [" and ".join(dropped),response_code]
			_finish_receipt(receipt,false,false,why)
			_attempt_failed(audience_id,why,true)
			return
	var retryable:bool=ok_http or result!=HTTPRequest.RESULT_SUCCESS or response_code in [408,425,429] or response_code>=500
	if detail.is_empty(): detail="could not reach the service (transport %d)" % result if result!=HTTPRequest.RESULT_SUCCESS else _http_words(response_code,String(envelope.get("error","")))
	var is_final:bool=not (retryable and int(request.attempts)<int(request.max_attempts))
	_finish_receipt(receipt,false,is_final,detail)
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
	if not usage.is_empty() and String(usage[-1].get("audience_id",""))==audience_id: usage[-1]["fallback"]=true
	_deliver_offline(request.scene,String(request.stage),request.extra,detail)

# ---------------------------------------------------------------------------
# Cost receipts and the live/offline indicator
# ---------------------------------------------------------------------------

static func _http_words(code:int,error_text:String)->String:
	var base:String={401:"API key rejected (HTTP 401)",403:"no access to this model (HTTP 403)",404:"model or endpoint not found (HTTP 404)",429:"rate or usage limit reached (HTTP 429)"}.get(code,"HTTP %d" % code)
	if code>=500 and code!=0: base="service error (HTTP %d)" % code
	if not error_text.is_empty() and code in [400,404,422]: base+=": "+error_text.substr(0,90)
	return base

func _envelope_facts(body:PackedByteArray)->Dictionary:
	## Usage and finish facts from a provider reply. Never keeps content or headers.
	var facts:={"prompt_tokens":0,"completion_tokens":0,"reasoning_tokens":0,"total_tokens":0,"model":"","finish_reason":"","refusal":false,"error":""}
	var parser:=JSON.new()
	if body.is_empty() or parser.parse(body.get_string_from_utf8())!=OK or not parser.data is Dictionary: return facts
	var envelope:Dictionary=parser.data
	var tokens:Variant=envelope.get("usage",{})
	if tokens is Dictionary:
		for key in ["prompt_tokens","completion_tokens","total_tokens"]:
			var value:Variant=(tokens as Dictionary).get(key,0)
			facts[key]=int(value) if (value is int or value is float) else 0
		var details:Variant=(tokens as Dictionary).get("completion_tokens_details",{})
		if details is Dictionary:
			var reasoning:Variant=(details as Dictionary).get("reasoning_tokens",0)
			facts["reasoning_tokens"]=int(reasoning) if (reasoning is int or reasoning is float) else 0
	facts["model"]=String(envelope.get("model","")).substr(0,80)
	var choices:Variant=envelope.get("choices",[])
	if choices is Array and not (choices as Array).is_empty() and choices[0] is Dictionary:
		facts["finish_reason"]=String((choices[0] as Dictionary).get("finish_reason",""))
		var message:Variant=(choices[0] as Dictionary).get("message",{})
		if message is Dictionary and (message as Dictionary).get("refusal",null) is String: facts["refusal"]=true
	var error:Variant=envelope.get("error",null)
	if error is Dictionary:
		# Provider messages can quote part of a key; keep a redacted prefix only.
		var text:=String((error as Dictionary).get("message",(error as Dictionary).get("code","")))
		var secret:=RegEx.new(); secret.compile("(sk|key)[-_][A-Za-z0-9_*-]{4,}")
		facts["error"]=secret.sub(text,"[redacted]",true).replace("\n"," ").substr(0,160)
	return facts

func _receipt_http(audience_id:String,request:Dictionary,result:int,code:int,envelope:Dictionary)->Dictionary:
	var row:={"audience_id":audience_id,"stage":String(request.get("stage","")),"attempt":int(request.get("attempts",1)),"day":_day(),
		"model":String(envelope.get("model","")) if not String(envelope.get("model","")).is_empty() else String((request.get("config",{}) as Dictionary).get("model","")),
		"http":code,"transport":result,"latency_ms":Time.get_ticks_msec()-int(request.get("started_ms",Time.get_ticks_msec())),
		"prompt_tokens":int(envelope.get("prompt_tokens",0)),"completion_tokens":int(envelope.get("completion_tokens",0)),
		"reasoning_tokens":int(envelope.get("reasoning_tokens",0)),"total_tokens":int(envelope.get("total_tokens",0)),
		"finish_reason":String(envelope.get("finish_reason","")),"live":true,"accepted":false,"fallback":false,"reason":""}
	totals.calls=int(totals.calls)+1
	for key in ["prompt_tokens","completion_tokens","reasoning_tokens","total_tokens","latency_ms"]: totals[key]=int(totals[key])+int(row[key])
	_push_receipt(row)
	return row

func _finish_receipt(row:Dictionary,accepted:bool,fallback:bool,reason:String)->void:
	row["accepted"]=accepted;row["fallback"]=fallback;row["reason"]=reason
	if accepted: totals.accepted=int(totals.accepted)+1
	else: totals.failed=int(totals.failed)+1
	# One plain line per call in the player log: proof of what was spent.
	print("AUDIENCE_VOICE_RECEIPT stage=%s attempt=%d model=%s http=%d tokens=%d (prompt %d, completion %d, reasoning %d) latency_ms=%d accepted=%s%s" % [
		String(row.stage),int(row.attempt),String(row.model),int(row.http),int(row.total_tokens),int(row.prompt_tokens),int(row.completion_tokens),int(row.reasoning_tokens),int(row.latency_ms),str(accepted)," reason="+reason if not reason.is_empty() else ""])

func _receipt_offline(s:Dictionary,stage:String,reason:String,model:String="")->void:
	totals.offline=int(totals.offline)+1
	_push_receipt({"audience_id":String(s.get("id","")),"stage":stage,"attempt":0,"day":_day(),"model":model,"http":0,"transport":0,"latency_ms":0,
		"prompt_tokens":0,"completion_tokens":0,"reasoning_tokens":0,"total_tokens":0,"finish_reason":"","live":false,"accepted":false,"fallback":true,"reason":reason})

func _push_receipt(row:Dictionary)->void:
	usage.append(row)
	while usage.size()>USAGE_LIMIT: usage.pop_front()

func offline_reason()->String:
	## Why the live voice is not in use, in a few plain words ("" when it is).
	if force_offline: return "switched to offline voices"
	if not config_override.is_empty(): return ""
	var status:Dictionary=PronouncementInterpreter.configuration_status()
	if not bool(status.get("enabled",false)): return "AI is switched off"
	var issues:Array=status.get("issues",[])
	if not issues.is_empty(): return String(issues[0]).substr(0,90)
	if not bool(status.get("configured",false)): return "no API key"
	return ""

func status()->Dictionary:
	## For the hall's footer: which voice speaks, why, and what it has cost.
	var reason:=offline_reason()
	var config:Dictionary={} if not reason.is_empty() else _config()
	var model:=String(config.get("model",""))
	var last_live:Dictionary={}
	for i in range(usage.size()-1,-1,-1):
		if bool(usage[i].get("live",false)): last_live=usage[i]; break
	var live:=not config.is_empty()
	var note:=""
	if live and not last_live.is_empty() and bool(last_live.get("fallback",false)):
		note="last reply failed: %s; offline lines stood in" % String(last_live.get("reason",""))
	if not live and reason.is_empty(): reason="no connection"
	var label:=("Live voice · %s" % model)+(" · last line offline" if not note.is_empty() else "") if live else "Offline voice — %s" % reason
	var tip:=PackedStringArray()
	tip.append("Audience voices this session: %d live call%s (%d used, %d failed), %d offline scene%s." % [int(totals.calls),"" if int(totals.calls)==1 else "s",int(totals.accepted),int(totals.failed),int(totals.offline),"" if int(totals.offline)==1 else "s"])
	tip.append("Tokens: %d total (%d prompt, %d completion, of which %d reasoning)." % [int(totals.total_tokens),int(totals.prompt_tokens),int(totals.completion_tokens),int(totals.reasoning_tokens)])
	if not last_live.is_empty():
		tip.append("Last call: %s, HTTP %d, %d tokens, %.1f s%s." % [String(last_live.stage),int(last_live.http),int(last_live.total_tokens),float(last_live.latency_ms)/1000.0,"" if bool(last_live.accepted) else " — "+String(last_live.reason)])
	if not note.is_empty(): tip.append(note.substr(0,1).to_upper()+note.substr(1)+".")
	if not live: tip.append("Offline voices are written from each speaker's character and never cost anything.")
	return {"live":live,"model":model,"reason":reason,"note":note,"label":label,"tooltip":"\n".join(tip),"calls":int(totals.calls),"tokens":int(totals.total_tokens),"totals":totals.duplicate()}

func _ruler_spoke(s:Dictionary)->bool:
	for line in (s.audience as Dictionary).get("lines",[]):
		if String((line as Dictionary).get("role",""))=="ruler": return true
	return false

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
	var divine:Variant=(proposed as Dictionary).get("divine","none")
	var command:Variant=(proposed as Dictionary).get("command",{})
	var heard:Dictionary={}
	if command is Dictionary:
		for key in ["act","verb","actor_ref","target_ref","object"]: heard[key]=String((command as Dictionary).get(key,"")).substr(0,120)
		var confidence:Variant=(command as Dictionary).get("confidence",0.0)
		heard["confidence"]=clampf(float(confidence),0.0,1.0) if (confidence is float or confidence is int) and is_finite(float(confidence)) else 0.0
	return {"lines":(proposed as Dictionary).lines,"mood_shift":clampf(mood_value,-0.25,0.25),"divine":String(divine).substr(0,24) if divine is String else "none","command":heard}

func allowed_numbers(s:Dictionary,extra:Dictionary)->Dictionary:
	var allowed:={}
	var sources:PackedStringArray=PackedStringArray([JSON.stringify(s.get("report",{})),JSON.stringify(s.get("scout_brief",{})),JSON.stringify(s.get("ctx",{})),String(s.get("fact","")),String(s.get("summary","")),String(s.get("amt","")),String(extra.get("player_text",""))])
	var result:Dictionary=extra.get("result",{})
	sources.append(String(result.get("outcome","")))
	var hist:Dictionary=s.get("history",{})
	for entry in (hist.get("speaker",[]) as Array)+(hist.get("civ",[]) as Array): sources.append(String((entry as Dictionary).get("outcome","")))
	var terms:Dictionary=(s.get("audience",{}) as Dictionary).get("terms",{})
	if terms.has("amount"):
		sources.append("%d" % roundi(float(terms.amount)))
		sources.append("%d" % roundi(float(terms.amount)*0.5))
	var number:=RegEx.new(); number.compile("\\d+(?:\\.\\d+)?")
	for m in number.search_all(" ".join(sources)): allowed[m.get_string()]=true
	return allowed

func validate_lines(raw:Array,s:Dictionary,stage:String,extra:Dictionary={})->Array[Dictionary]:
	var keys:=cast_keys(s)
	if stage=="command" or stage=="persons": keys.append("narrator")
	var refusal:=RegEx.new(); refusal.compile(CC.REFUSAL_PATTERN)
	var result:Dictionary=extra.get("result",{}) if extra.get("result") is Dictionary else {}
	var obeyed:=stage=="command" and String((result.get("obedience",{}) as Dictionary).get("id","obey")) in ["obey","reluctant"]
	var ordered:=stage=="speak" and String(CC.classify(String(extra.get("player_text",""))).get("act",""))=="command"
	var names:=_cast_names(s)
	var staged:=false
	var meta:=RegEx.new(); meta.compile(META_PATTERN)
	var number:=RegEx.new(); number.compile("\\d+(?:\\.\\d+)?")
	var allowed:=allowed_numbers(s,extra)
	var out:Array[Dictionary]=[]
	var limit:int=int(STAGE_LIMITS.get(stage,4))
	var gate:Dictionary=s.get("gate",{}) if s.get("gate") is Dictionary else {}
	var gated_all:=bool(gate.get("all",false)) or stage in ["weigh","persons"]
	var principals:Array=[]
	if stage=="command":
		for role in ["actor","target"]:
			var who:=_member_for(s,result.get(role,{}) if result.get(role) is Dictionary else {})
			if not who.is_empty(): principals.append(String(who.key))
	var visible:=" ".join(PackedStringArray([String(s.get("summary","")),String(s.get("fact","")),String(s.get("headline","")),String(result.get("outcome",""))]))
	var side_spoken:=0
	for item in raw:
		if out.size()>=limit: break
		if not item is Dictionary: continue
		var key:String=String((item as Dictionary).get("speaker_key",""))
		if key not in keys: continue
		if stage=="divine" and key=="envoy" and bool((extra.get("result",{}) as Dictionary).get("terminal",false)): continue   # the removed do not speak
		if stage=="command" and key=="envoy" and not _envoy_may_speak(s,result): continue
		if key=="narrator":
			if staged: continue
			var stage_text:=stage_direction(String((item as Dictionary).get("text","")))
			if stage_text.is_empty() or not line_ok(stage_text,CV.era_tags("player")+(s.get("fact_tags",[]) as Array)) or meta.search(stage_text)!=null or (_voice_state().said as Dictionary).has(_text_key(stage_text)): continue
			staged=true
			out.push_front({"key":"narrator","text":stage_text,"aside":false})
			continue
		var text:=_clean_text(String((item as Dictionary).get("text","")),_member(s,key))
		text=without_filler(text,names)
		# Invented maxims go; the plain part of the line stays if it stands alone.
		text=Plain.strip(text)
		if text.is_empty(): continue
		if (obeyed or ordered) and refusal.search(text)!=null: continue   # the engine, not the model, decides obedience
		if text.is_empty() or meta.search(text)!=null: continue
		if _recent_lines(s,_member(s,key)).has(text.to_lower()): continue   # word for word from a past audience
		if not line_ok(text,_era_for(s,_member(s,key))): continue   # anachronism, quotation or named source
		if (_voice_state().said as Dictionary).has(_text_key(text)): continue   # said before in this hall
		var invented:=false
		for m in number.search_all(text):
			if not allowed.has(m.get_string()): invented=true
		if invented: continue
		if key!="envoy" and not key in principals and not gated_all:
			# One official beside the principals, and only with real guidance.
			if side_spoken>=1: continue
			var kind:=String(gate.get("kind","aside")) if String(gate.get("key",""))==key else "aside"
			if not Relevance.clears({"kind":kind,"text":text},visible): continue
			side_spoken+=1
		out.append({"key":key,"text":text,"aside":bool((item as Dictionary).get("aside",false))})
	return out

func _cast_names(s:Dictionary)->Array[String]:
	var names:Array[String]=[]
	for member in [s.envoy]+(s.officials as Array):
		# Epithet words ("who", "the") do not count as naming anyone.
		for part in preload("res://scripts/era_names.gd").name_keys(String((member as Dictionary).get("name",""))): names.append(part)
	return names

static func filler(text:String,names:Array)->bool:
	## True for a line that is only a proverb or riddle: it opens like a saying,
	## nobody speaks in it, nobody is named and nothing is counted.
	var t:=text.strip_edges()
	if t.is_empty(): return true
	var opening:=RegEx.new(); opening.compile(FILLER_OPENING)
	if opening.search(t)==null: return false
	var stance:=RegEx.new(); stance.compile(STANCE_WORDS)
	if stance.search(t)!=null: return false
	var digits:=RegEx.new(); digits.compile("\\d")
	if digits.search(t)!=null: return false
	var lower:=t.to_lower()
	for n in names:
		if String(n)!="" and String(n) in lower: return false
	return true

static func without_filler(text:String,names:Array)->String:
	## Drops a leading stock saying ("A goose may hiss at the fire...; I will...")
	## and rejects a line that is nothing but one.
	var t:=text.strip_edges()
	var cut:=t.find("; ")
	if cut>0 and filler(t.substr(0,cut),names):
		var rest:=t.substr(cut+2).strip_edges()
		t=rest.substr(0,1).to_upper()+rest.substr(1) if not rest.is_empty() else ""
		# What follows a stock saying must stand on its own: someone speaking.
		var stance:=RegEx.new(); stance.compile(STANCE_WORDS)
		if stance.search(t)==null: return ""
	if filler(t,names): return ""
	return t

static func stage_direction(text:String)->String:
	## A bracketed stage direction: one or two sentences, never a speech.
	var t:=text.replace("\n"," ").strip_edges().trim_prefix("[").trim_suffix("]").strip_edges()
	if t.is_empty() or "\"" in t: return ""
	var words:=t.split(" ",false).size()
	if words<4 or words>60: return ""
	var stops:=0
	for i in range(t.length()-1):
		if t[i] in ".!?" and t[i+1]==" ": stops+=1
	if stops>1: return ""
	return "["+t+"]"

func _envoy_may_speak(s:Dictionary,result:Dictionary)->bool:
	## The one before the god speaks unless they were removed (dead, cast out,
	## bound, fled).
	var target:Dictionary=result.get("target",{}) if result.get("target") is Dictionary else {}
	var actor:Dictionary=result.get("actor",{}) if result.get("actor") is Dictionary else {}
	if bool(target.get("speaker",false)) and bool(result.get("removed",false)): return false
	if bool(actor.get("speaker",false)) and String(result.get("stage",""))=="refuse_flee": return false
	return not s.is_empty()

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
	# Nobody repeats a line verbatim within one audience.
	var said:={}
	for line in (h.find(String(s.id)) as Dictionary).get("lines",[]): said[String(line.get("text","")).strip_edges().to_lower()]=true
	var ordered:Array[Dictionary]=[]
	var outcome_words:=String((extra.get("result",{}) as Dictionary).get("outcome","")).strip_edges().to_lower() if stage=="command" else ""
	for line in lines:
		var text:=String(line.get("text","")).strip_edges().to_lower()
		if said.has(text): continue
		if outcome_words!="" and (text==outcome_words or text.trim_prefix("[").trim_suffix("]")==outcome_words): continue
		said[text]=true
		ordered.append(line)
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
	if stage=="command":
		var has_stage:=false
		for line in ordered:
			if String(line.key)=="narrator": has_stage=true
		if not has_stage:
			var staged:=_stage_line(s,extra.get("result",{}),_scene_rng(s,"command:stage"))
			if not staged.is_empty(): ordered.push_front(staged)
	for line in ordered:
		if String(line.key)=="narrator":
			h.append_line(String(s.id),{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":String(line.text),"day":_day(),"aside":false})
			if String(line.text).begins_with("["): _mark_said(String(line.get("tkey","")),String(line.text))
			continue
		var member:=_member(s,String(line.key))
		if member.is_empty(): continue
		h.append_line(String(s.id),_line_for(member,String(line.text),bool(line.aside)))
		_mark_said(String(line.get("tkey","")),String(line.text))
		line_log.append({"audience_id":String(s.id),"speaker":String(member.name),"model":String(member.persona.get("model","")),"manner":bool(line.get("manner",false)),"fact":bool(line.get("fact",not line.has("tkey"))),"text":String(line.text)})
		while line_log.size()>4000: line_log.pop_front()
	if stage=="command":
		var outcome:=String((extra.get("result",{}) as Dictionary).get("outcome",""))
		var already:=false
		for line in (h.find(String(s.id)) as Dictionary).get("lines",[]):
			if String((line as Dictionary).get("text","")).strip_edges()==outcome.strip_edges(): already=true
		if not outcome.is_empty() and not already: h.append_line(String(s.id),{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":outcome,"day":_day(),"aside":false})
	# Only the ruler's own words move the room; openings and farewells do not.
	if stage=="speak" and absf(mood_shift)>0.0: h.apply_mood(String(s.id),clampf(mood_shift,-0.25,0.25))
	lines_ready.emit.call_deferred(String(s.id))

func _proposal(body:PackedByteArray)->Dictionary:
	## The model's JSON object (from a chat envelope or bare), or {}.
	var parser:=JSON.new()
	if parser.parse(body.get_string_from_utf8())!=OK or not parser.data is Dictionary: return {}
	var envelope:Dictionary=parser.data
	if envelope.has("canonical_action"): return envelope
	var content:=""
	var choices:Variant=envelope.get("choices",[])
	if choices is Array and not (choices as Array).is_empty() and choices[0] is Dictionary:
		var message:Variant=(choices[0] as Dictionary).get("message",{})
		if message is Dictionary: content=PronouncementInterpreter._content_text((message as Dictionary).get("content",""))
	if content.is_empty(): content=PronouncementInterpreter._content_text(envelope.get("output_text",""))
	var first:=content.find("{"); var last:=content.rfind("}")
	if first<0 or last<=first: return {}
	var inner:=JSON.new()
	if inner.parse(content.substr(first,last-first+1))!=OK or not inner.data is Dictionary: return {}
	return inner.data

func _persons_response(audience_id:String,request:Dictionary,body:PackedByteArray,receipt:Dictionary)->String:
	## Validates the live mapping, lets the engine decide and apply, speaks the
	## model's lines for it, and stores the exchange for offline replay.
	## Returns "" when handled, else why it failed (retry, then offline).
	var raw:=_proposal(body)
	if raw.is_empty(): return "reply was not the expected JSON"
	var extra:Dictionary=request.extra
	var menu:Array=extra.get("menu",[])
	var mapped:=PersonsBridge.validate_live(raw,menu)
	if not bool(mapped.get("ok",false)): return String(mapped.get("reason","invalid mapping"))
	var s:Dictionary=request.scene
	var lines:=validate_lines(raw.get("lines",[]) if raw.get("lines") is Array else [],s,"persons",extra)
	var params:Dictionary=mapped.params
	if raw.get("descriptor") is Dictionary and String(mapped.action) in ["ask_about","summon"] and not params.has("desc") and not params.has("ref"):
		params["desc"]=Persons.descriptor_from(raw.descriptor)
	var spoken:Array=[]
	var principal_text:=""
	for line in lines:
		var l:Dictionary=line
		if String(l.key)=="narrator":
			spoken.append({"speaker":"","role":"narrator","person_id":0,"text":String(l.text)})
			continue
		var member:=_member(s,String(l.key))
		if member.is_empty(): continue
		spoken.append({"speaker":String(member.name),"role":"official","person_id":int(member.person_id),"text":String(l.text),"aside":bool(l.get("aside",false))})
		if principal_text=="" and not bool(l.get("aside",false)): principal_text=String(l.text)
	_requests.erase(audience_id)
	_finish_receipt(receipt,true,false,"")
	last_problem.erase(audience_id)
	var action:=String(mapped.action)
	var result:Dictionary
	if action=="talk":
		if not spoken.is_empty():
			for l2 in spoken: _hall().append_line(audience_id,(l2 as Dictionary).merged({"day":_day()}))
		else:
			var said:={"player_text":String(extra.get("player_text",""))}
			_deliver(s,"speak",said,_offline_lines(s,"speak",said,_scene_rng(s,"speak")),0.0)
		result={"ok":true,"action":"talk","signature":Persons.signature(audience_id,"talk",{}),"lines":[]}
	else:
		result=Persons.perform(audience_id,action,params,{"lines":spoken,"deltas":mapped.deltas,"require_name":true})
	for l3 in lines: _mark_said("",String((l3 as Dictionary).text))
	var beat:=PersonsLines.principal_beat(result.get("lines",[]))
	if action.begins_with("novel:") and beat=="": beat="react_novel"
	if principal_text!="" and beat!="" and bool(result.get("spoke_live",action=="talk" or action.begins_with("novel:"))):
		var usage_row:Dictionary=receipt
		PersonsBridge.learn(String(extra.get("player_text","")),action,beat,result.get("signature",{}),principal_text,String(mapped.template),mapped.deltas,
			{"model":String(s.envoy.persona.get("model","")),"generalizable":bool(mapped.generalizable),"label":String(mapped.label),"model_name":String(request.config.get("model","")),
			"usage":{"prompt_tokens":int(usage_row.get("prompt_tokens",0)),"completion_tokens":int(usage_row.get("completion_tokens",0)),"total_tokens":int(usage_row.get("total_tokens",0))}})
	lines_ready.emit.call_deferred(audience_id)
	persons_done.emit.call_deferred(audience_id,result)
	return ""

const GENERAL_ORDER:={"act":"command","verb":"order","actor_ref":"","target_ref":"","object":"","confidence":1.0}

func _deliver_offline(s:Dictionary,stage:String,extra:Dictionary,_problem:String)->void:
	if stage=="persons":
		# The words could not be mapped: the one before you simply answers.
		var said:={"player_text":String(extra.get("player_text",""))}
		_deliver(s,"speak",said,_offline_lines(s,"speak",said,_scene_rng(s,"speak")),0.0)
		persons_done.emit.call_deferred(String(s.id),{"ok":false,"action":"talk"})
		return
	if stage=="speak" and bool(extra.get("offline_order",false)) and command_router.is_valid():
		if bool(command_router.call(String(s.id),String(extra.get("player_text","")),GENERAL_ORDER)): return
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
	var occasion:String=String((s.get("occasion",{}) as Dictionary).get("text","")).strip_edges().trim_suffix(".")
	if not occasion.is_empty():
		tokens["occasion"]=occasion
		tokens["occasioncap"]=occasion.substr(0,1).to_upper()+occasion.substr(1)
	tokens.merge(s.get("gwtok",{}),true)
	tokens.merge(s.get("htok",{}),true)
	if tokens.has("when"): tokens["whencap"]=String(tokens.when).substr(0,1).to_upper()+String(tokens.when).substr(1)
	var gist:=String(PROPOSAL_GIST.get(String(s.get("sit_type","")),""))
	if not gist.is_empty(): tokens["gist"]=gist; tokens["gistcap"]=gist.substr(0,1).to_upper()+gist.substr(1)
	if tokens.has("matter"): tokens["mattercap"]=String(tokens.matter).substr(0,1).to_upper()+String(tokens.matter).substr(1)
	if tokens.has("decree"): tokens["decreecap"]=String(tokens.decree).substr(0,1).to_upper()+String(tokens.decree).substr(1)
	if not String(persona.get("model","")).is_empty(): tokens.erase("oath")
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

var _last_choice_fresh:=true
var _last_template:=""
var _era_now:Array=[]          ## era tags permitted for the line being written
const WORD_CAP:=22             ## offline lines stay short
const SAID_LIMIT:=2500         ## lines remembered as said (hashes, saved with the hall)
var _mem_state:Dictionary={}
var answered:Dictionary={}       ## audience_id -> the last reply answered the ruler's question from the facts
var line_log:Array[Dictionary]=[] ## recent offline lines and whether they came from the speaker's manner

func _voice_state()->Dictionary:
	## Lifelong voice choices and everything ever said, saved with the hall's
	## state when there is one (a test stub gets a session-long dictionary).
	var h:Variant=_hall()
	var v:Dictionary=_mem_state
	if h!=null and h.has_method("validate_state") and h.has_method("state"):
		var st:Dictionary=h.state()
		if not st.get("voice") is Dictionary: st["voice"]={}
		v=st.voice
	for key in ["models","addresses","said","counts"]:
		if not v.get(key) is Dictionary: v[key]={}
	if not v.has("serial"): v["serial"]=0
	return v

static func norm_line(text:String)->String:
	## A line's identity: names, titles and address terms removed (any word
	## starting with a capital), case and punctuation ignored.
	var words:PackedStringArray=PackedStringArray()
	for raw in text.replace("\u2014"," ").split(" ",false):
		var w:=String(raw)
		var core:=""
		for c in w:
			if (c>="a" and c<="z") or (c>="A" and c<="Z") or (c>="0" and c<="9") or c=="'": core+=c
		if core.is_empty(): continue
		if core.substr(0,1)!=core.substr(0,1).to_lower() and core!="I": continue
		words.append(core.to_lower())
	var out:=" ".join(words)
	for address in ["ma chief","friend-chief","hearth-holder","my chief","my bright one","forge-master","chief of the fire","high one","big-hearted one","hearth-lord","ring-giver"]:
		out=out.replace(address.replace("-",""),"").replace(address,"")
	return out.replace("  "," ").strip_edges()

static func _template_key(template:String)->String:
	return "t%d" % hash(template.replace(", {address}","").replace("{address}","").replace("{oath} ","").replace("{oath}",""))

static func _text_key(text:String)->String:
	return "l%d" % hash(norm_line(text))

func _mark_said(tkey:String,text:String)->void:
	var v:=_voice_state()
	var said:Dictionary=v.said
	v.serial=int(v.serial)+1
	if not tkey.is_empty(): said[tkey]=int(v.serial)
	said[_text_key(text)]=int(v.serial)
	if said.size()>SAID_LIMIT:
		# Forget the oldest fifth: a very long reign may hear an old line again.
		var keys:Array=said.keys()
		keys.sort_custom(func(a:Variant,b:Variant)->bool: return int(said[a])<int(said[b]))
		for i in int(SAID_LIMIT/5.0): said.erase(keys[i])
const OATH_CHANCE:=0.18        ## most lines carry no oath at all
const ADDRESS_CHANCE:=0.45     ## the address term is seasoning, not a refrain

func _era_for(s:Dictionary,member:Dictionary)->Array:
	## What this speaker's people know, plus anything the supplied facts
	## themselves mention (a scout who saw kilns may say so).
	var persona:Dictionary=member.get("persona",{})
	var tags:Array=(persona.get("era_tags",CV.era_tags(String(persona.get("era_owner","player")))) as Array).duplicate()
	for tag in s.get("fact_tags",[]):
		if not tags.has(tag): tags.append(tag)
	return tags

func line_ok(text:String,tags:Array)->bool:
	## Era-true and never a quotation or a named source.
	return CV.permits(text,tags) and CV.imitation_ok(text)

static func _season(bank:Array,allow_oath:bool,drop_address:bool)->Array:
	if allow_oath and not drop_address: return bank
	var out:Array=[]
	for template in bank:
		var line:=String(template)
		if not allow_oath: line=line.replace("{oath} ","").replace(" {oath}","").replace("{oath}","")
		if drop_address and line.contains(", {address}"): line=line.replace(", {address}","")
		out.append(line.strip_edges())
	return out

func _choose(s:Dictionary,bank:Array,tokens:Dictionary,rng:RandomNumberGenerator,recent:Array[String]=[],fresh_only:bool=false)->String:
	## Prefer templates unused in this scene and unsaid by this speaker lately.
	## fresh_only: return "" rather than repeat something said lately.
	## Templates the era forbids (or that echo a famous line) are never used.
	var used:Dictionary=_used.get(String(s.id),{})
	var fresh:Array=[]; var unscened:Array=[]; var any:Array=[]
	var said:Dictionary=_voice_state().said
	for template in bank:
		if not _usable(String(template),tokens): continue
		var filled:=_fill(String(template),tokens)
		if not line_ok(filled,_era_now): continue
		# Short lines only (facts may run a little longer).
		if filled.split(" ",false).size()>(30 if "{fact}" in String(template) or "{summary}" in String(template) else WORD_CAP): continue
		# Nothing is ever said twice in this hall, by anyone.
		if said.has(_template_key(String(template))) or said.has(_text_key(filled)): continue
		any.append(template)
		if used.has(String(template)): continue
		unscened.append(template)
		if not _recently_said(_fill(String(template),tokens),recent): fresh.append(template)
	_last_choice_fresh=not fresh.is_empty()
	if fresh_only and fresh.is_empty(): return ""
	var pool:Array=fresh if not fresh.is_empty() else (unscened if not unscened.is_empty() else any)
	if pool.is_empty(): return ""
	var chosen:String=String(pool[rng.randi_range(0,pool.size()-1)])
	used[chosen]=true
	_used[String(s.id)]=used
	_last_template=chosen
	return _fill(chosen,tokens)

func _say(s:Dictionary,member:Dictionary,bank:Array,rng:RandomNumberGenerator,rival:Dictionary={},aside:bool=false,reserve:Array=[])->Dictionary:
	## reserve: a wider bank used when everything in bank was said lately, so a
	## speaker reaches for new words before repeating themselves.
	var tokens:=_tokens(s,member,rival)
	_era_now=_era_for(s,member)
	# Oaths are rare flavour: most lines carry none, and nobody swears twice a
	# scene. The address term is seasoning too, often left out.
	var scene_memory:Dictionary=_used.get(String(s.id),{})
	var oath_key:="~oath:"+String(member.get("key",""))
	var oath:=String(tokens.get("oath",""))
	var allow_oath:bool=not scene_memory.has(oath_key) and rng.randf()<OATH_CHANCE
	if not allow_oath: tokens.erase("oath")
	# One address term for life, in at most one line in three.
	var who:=String((member.get("persona",{}) as Dictionary).get("speaker_key",member.get("key","")))
	var counts:Dictionary=_voice_state().counts
	var tally:Array=counts.get(who,[0,0])
	var drop_address:bool=(int(tally[1])+1)*3>int(tally[0])+1
	if drop_address: tokens.erase("address")
	var recent:=_recent_lines(s,member)
	var raw:=_choose(s,_season(bank,allow_oath,drop_address),tokens,rng,recent)
	if raw.is_empty() and allow_oath:
		raw=_choose(s,_season(bank,false,drop_address),tokens,rng,recent)
	if (raw.is_empty() or not _last_choice_fresh) and not reserve.is_empty():
		var wider:=_choose(s,_season(reserve,false,drop_address),tokens,rng,recent,true)
		if not wider.is_empty(): raw=wider
	if raw.is_empty(): return {}
	if not oath.is_empty() and raw.contains(oath):
		scene_memory[oath_key]=true
		_used[String(s.id)]=scene_memory
	# A line that opens on a name or title keeps it up front; no lead-in before it.
	var lead_ok:=true
	for k in ["address","leader","rival","petitioner","civ","envoy","oath","subject","work","name","ruin","trigger","eventtext","gatetext","forecast","civtwo","dead"]:
		var value:String=String(tokens.get(k,""))
		if not value.is_empty() and raw.to_lower().begins_with(value.to_lower()): lead_ok=false
	var text:=CV.speak(member.persona,raw,rng,true,_flourish_memory(s,member),lead_ok)
	# Never the same words twice from the same mouth across recent audiences,
	# and never a flourish the era does not have.
	var tries:=0
	while (recent.has(text.to_lower()) or not line_ok(text,_era_now)) and tries<4:
		text=CV.speak(member.persona,raw,rng,true,_flourish_memory(s,member),lead_ok)
		tries+=1
	if recent.has(text.to_lower()) or not line_ok(text,_era_now): return {}
	var address:=String((member.get("persona",{}) as Dictionary).get("address",""))
	counts[who]=[int(tally[0])+1,int(tally[1])+(1 if not address.is_empty() and address in text else 0)]
	var own:=_model_templates(member.get("persona",{}))
	var tkey:=_template_key(_last_template)
	return {"key":String(member.key),"text":text,"aside":aside,"tkey":tkey,"manner":own.has(tkey),"fact":_fact_templates().has(tkey) and not own.has(tkey)}

var _fact_keys:Dictionary={}
func _fact_templates()->Dictionary:
	## Lines that carry the facts of the moment (why they came, the terms, a
	## memory, an answer, what the ruler decided). Shared phrasing is expected
	## there; everything else should be in the speaker's own manner.
	if not _fact_keys.is_empty(): return _fact_keys
	var banks:Array=[]
	for source in [ENVOY_OPEN,ENVOY_OPEN_MORE,PETITION_PLEA,PETITION_PLEA_MORE,PROPOSAL_OPEN,CLOSING_OPTION,CLOSING_MORE,CLOSING_REPEAT,ARC_OPEN,HISTORY_OPEN]:
		for bank in (source as Dictionary).values(): banks.append(bank)
	for by_kind in ANSWERS.values():
		for bank in (by_kind as Dictionary).values(): banks.append(bank)
	banks.append(TERMS_STAND)
	for decree in REMEDY: banks.append(decree_pleas(String(decree)))
	banks.append([DECREE_PLEA_GENERIC])
	for halves in OCCASION_SPEECH.values():
		for a in halves[0]:
			for b in halves[1]: banks.append(["%s %s" % [String(a),String(b)]])
	for bank in banks:
		for template in bank: _fact_keys[_template_key(String(template))]=true
	return _fact_keys

var _model_sets:Dictionary={}
func _model_templates(persona:Dictionary)->Dictionary:
	var model_id:=String(persona.get("model",""))
	if not _model_sets.has(model_id):
		var keys:={}
		for bank in (CV.MODEL_BANKS.get(model_id,{}) as Dictionary).values():
			for template in bank: keys[_template_key(String(template))]=true
		_model_sets[model_id]=keys
	return _model_sets[model_id]

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

const RECENT_AUDIENCES:=10

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
		# A foreign people's envoys share one memory: a new face must not replay
		# what the last envoy of the same people said.
		var civ_voice:bool=String(member.key)=="envoy" and String(s.origin)=="foreign" and not String(s.civ_id).is_empty()
		for audience in audiences:
			if found>=RECENT_AUDIENCES: break
			if String(audience.get("id",""))==String(s.id): continue
			var same_people:bool=civ_voice and String(audience.get("civ_id",""))==String(s.civ_id)
			var spoke:=false
			for line in audience.get("lines",[]):
				if String(line.get("speaker",""))==String(member.name) or (same_people and String(line.get("role",""))=="envoy"):
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

# ---------------------------------------------------------------------------
# Memory across audiences
# ---------------------------------------------------------------------------

func history_for(s:Dictionary)->Dictionary:
	## {"speaker":[entry],"civ":[entry]}, newest first, resolved or expired
	## audiences only. Prefers the hall's own history_with_speaker /
	## history_with_civ (voice_context); otherwise derives the same from the
	## hall's queue and history, so no extra save data is needed.
	## entry = {id,day,kind,origin,topic,decree,option_id,status,outcome,speaker,lines:[{speaker,text}]}
	var ctx:Dictionary=s.get("ctx",{})
	var records:=_hall_records(String(s.get("id","")))
	var by_id:={}
	for record in records: by_id[String(record.get("id",""))]=record
	var out:={"speaker":[],"civ":[]}
	for pair in [["speaker","history_with_speaker"],["civ","history_with_civ"]]:
		var which:String=String(pair[0])
		var supplied:Variant=ctx.get(String(pair[1]),null)
		var list:Array=[]
		if supplied is Array:
			for item in supplied:
				if item is Dictionary: list.append(_history_entry(item,by_id))
		else:
			for record in records:
				if _history_matches(s,record,which): list.append(_history_entry(record,by_id))
		var kept:Array=[]
		for entry in list:
			if String(entry.id)==String(s.get("id","")): continue
			if String(entry.status) in ["resolved","expired"] or not String(entry.option_id).is_empty(): kept.append(entry)
		kept.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.day)>int(b.day))
		out[which]=kept
	return out

func _hall_records(exclude_id:String)->Array:
	var h:Variant=_hall()
	if h==null or not h.has_method("state"): return []
	var st:Dictionary=h.state()
	var records:Array=[]
	for key in ["history","queue"]:
		for record in st.get(key,[]):
			if record is Dictionary and String((record as Dictionary).get("id",""))!=exclude_id: records.append(record)
	return records

func _history_matches(s:Dictionary,record:Dictionary,which:String)->bool:
	var audience:Dictionary=s.get("audience",{})
	var speaker:Dictionary=audience.get("speaker",{})
	var other:Dictionary=record.get("speaker",{}) if record.get("speaker",{}) is Dictionary else {}
	if which=="civ":
		return String(s.origin)=="foreign" and String(record.get("origin",""))=="foreign" and String(record.get("civ_id",""))==String(s.civ_id) and not String(s.civ_id).is_empty()
	var pid:int=int(speaker.get("person_id",0))
	if pid>0 and int(other.get("person_id",0))==pid: return true
	return String(other.get("name",""))==String(speaker.get("name","")) and not String(speaker.get("name","")).is_empty() and String(record.get("origin",""))==String(s.origin)

func _history_entry(item:Dictionary,by_id:Dictionary)->Dictionary:
	## Accepts full Audience records or the hall's ledger rows from
	## history_with ({day,kind,ask,summary,answer,reaction,outcome}).
	var petition:Dictionary=item.get("petition",{}) if item.get("petition",{}) is Dictionary else {}
	var id:=String(item.get("id",item.get("audience_id","")))
	var record:Dictionary=by_id.get(id,{})
	var lines:Array=item.get("lines",record.get("lines",[])) if item.get("lines",record.get("lines",[])) is Array else []
	var speaker:Variant=item.get("speaker",record.get("speaker",{}))
	var topic:=String(item.get("topic",petition.get("topic","")))
	var decree:=String(item.get("decree",item.get("suggested_decree",petition.get("suggested_decree",""))))
	var ask:=String(item.get("ask",""))
	if topic.is_empty() and decree.is_empty() and String(item.get("kind",""))=="petition" and ":" in ask:
		topic=ask.get_slice(":",0);decree=ask.substr(ask.find(":")+1)
		# Only a spoken decree is a matter in words; keys like "band2" or "Varrow:380" are not.
		if not decree.contains(" "): decree=""
	var option:=String(item.get("option_id",item.get("option",item.get("answer",record.get("option_id","")))))
	var status:=String(item.get("status",record.get("status","expired" if option in ["expired","left","ignored"] else "resolved")))
	var day:=int(item.get("day",item.get("resolved_day",item.get("arrived_day",record.get("arrived_day",0)))))
	if item.has("days_ago") and not item.has("day"): day=_day()-int(item.days_ago)
	var entry:={"id":id,"day":day,"kind":String(item.get("kind",record.get("kind",""))),"origin":String(item.get("origin",record.get("origin",""))),
		"topic":topic,"decree":decree,"option_id":option,"status":status,
		"outcome":String(item.get("outcome",record.get("outcome",""))),"summary":String(item.get("summary","")).substr(0,160),
		"speaker":String((speaker as Dictionary).get("name","")) if speaker is Dictionary else "",
		"lines":lines}
	if id.is_empty(): entry["id"]="%d|%s|%s|%s" % [day,String(entry.kind),ask,option]
	return entry

static func when_words(days_ago:int)->String:
	if days_ago<=3: return "only days ago"
	if days_ago<=12: return "not two weeks back"
	if days_ago<=40: return "a month or so back"
	if days_ago<=110: return "last season"
	if days_ago<=420: return "last year"
	return "years ago"

static func _ordinal(n:int)->String:
	return String(ORDINALS[n-1]) if n>=1 and n<=ORDINALS.size() else "umpteenth"

static func _cardinal(n:int)->String:
	return String(CARDINALS[n-1]) if n>=1 and n<=CARDINALS.size() else "a dozen"

func _matter_words(s:Dictionary,entry:Dictionary)->String:
	var decree:String=String(entry.get("decree",""))
	if REMEDY.has(decree): return String({"Send gatherers to find food":"the gatherers","Ration food for thirty days":"the rationing","Secure water and dig wells":"the wells",
		"Organize healers to care for the sick":"the healers","Build shelters":"the shelters","Raise a watch and post guards":"the watch","Support scholars and fund research":"the scholars",
		"Expand workshops and make tools":"the workshops","Post guards and patrol the frontier":"the frontier patrols","Hold a public council to hear the people":"a public council",
		"Improve roads and organize haulers":"the roads"}.get(decree,"it"))
	if not decree.is_empty(): return _lower_initial(decree)
	var topic:String=String(entry.get("topic",""))
	if TOPIC_MATTER.has(topic): return String(TOPIC_MATTER[topic])
	var leader:String=String(s.get("leader",""))
	return String({"gift":"our gift","request":"our request","threat":("%s's demand" % leader) if not leader.is_empty() else "our demand","news":"the news we brought","report":"what we found","great_work":"the great work","wonder_proposal":"the great work"}.get(String(entry.get("kind","")),"the last matter"))

func _history_group(s:Dictionary,entry:Dictionary)->String:
	var option:String=String(entry.get("option_id",""))
	var expired:bool=String(entry.get("status",""))=="expired"
	if String(s.origin)=="foreign":
		if expired: return "left_waiting"
		if option in ["accept","accept_return","grant","grant_half","pay","thank","reward","stand","restraint","compensate","welcome"]: return "welcomed"
		if option in ["refuse","refuse_request","defy","counter","decline","rebuff"]: return "spurned"
		return "visited"
	if expired: return "kept_waiting"
	if option in ["promise","patience"]: return "promised"
	if option=="decree": return "decreed"
	if option in ["dismiss","rebuke"]: return "rebuffed"
	if option in ["apologise","welcome"]: return "soothed"
	return "heard"

func _history_focus(s:Dictionary)->Dictionary:
	## The prior audience the visitor would bring up: same matter first, else
	## the latest with this speaker, else (foreign) the latest with their people.
	var hist:Dictionary=s.get("history",{})
	var mine:Array=hist.get("speaker",[])
	var theirs:Array=hist.get("civ",[])
	var decree:String=String(s.get("decree",""))
	var topic:String=String(s.get("topic",""))
	for entry in mine+theirs:
		if (not decree.is_empty() and String(entry.decree)==decree) or (decree.is_empty() and not topic.is_empty() and String(entry.topic)==topic) or (String(s.origin)=="foreign" and String(entry.kind)==String(s.kind)):
			return entry
	if not mine.is_empty(): return mine[0]
	if not theirs.is_empty(): return theirs[0]
	return {}

func _same_matter_count(s:Dictionary,focus:Dictionary)->int:
	var hist:Dictionary=s.get("history",{})
	var seen:={}
	var n:=0
	for entry in (hist.get("speaker",[]) as Array)+(hist.get("civ",[]) as Array):
		if seen.has(String(entry.id)): continue
		seen[String(entry.id)]=true
		if String(s.origin)=="foreign" or (String(entry.decree)==String(focus.get("decree","")) and String(entry.topic)==String(focus.get("topic",""))): n+=1
	return n

func _history_tokens(s:Dictionary,focus:Dictionary,repeats:int)->Dictionary:
	if focus.is_empty(): return {}
	return {"when":when_words(maxi(0,_day()-int(focus.get("day",_day())))),"matter":_matter_words(s,focus),"nth":_ordinal(repeats+1),"count":_cardinal(repeats+1)}

func _closing_repeat_tokens(s:Dictionary,option_id:String)->Dictionary:
	## Same answer given before to this speaker (or this people): count them.
	var hist:Dictionary=s.get("history",{})
	var same:Array=[]
	var seen:={}
	for entry in (hist.get("speaker",[]) as Array)+(hist.get("civ",[]) as Array):
		if seen.has(String(entry.id)): continue
		seen[String(entry.id)]=true
		var opt:String=String(entry.option_id)
		if opt==option_id or (option_id=="refuse_request" and opt=="refuse" and String(entry.kind)=="request"): same.append(entry)
	if same.is_empty(): return {}
	var tokens:=_history_tokens(s,same[0],same.size())
	return tokens

func _prompt_history(s:Dictionary)->String:
	var hist:Dictionary=s.get("history",{})
	var rows:PackedStringArray=PackedStringArray()
	var seen:={}
	for entry in (hist.get("speaker",[]) as Array)+(hist.get("civ",[]) as Array):
		if rows.size()>=HISTORY_ENTRIES: break
		if seen.has(String(entry.id)): continue
		seen[String(entry.id)]=true
		var about:String=_matter_words(s,entry)
		var result:String=String(entry.outcome).substr(0,170) if not String(entry.outcome).is_empty() else ("they left unheard" if String(entry.status)=="expired" else "answered: "+String(entry.option_id))
		rows.append("- %s: %s%s about %s. Outcome: %s" % [when_words(maxi(0,_day()-int(entry.day))),String(entry.kind),(" by "+String(entry.speaker)) if not String(entry.speaker).is_empty() else "",about,result])
	return "\n".join(rows)

func _prompt_avoid(s:Dictionary)->PackedStringArray:
	## Recent lines by everyone in this cast, newest audiences first, short.
	var out:PackedStringArray=PackedStringArray()
	var members:Array=[s.envoy]+(s.officials as Array)
	var per:int=maxi(2,int(AVOID_LINES/float(maxi(1,members.size()))))
	for member in members:
		var taken:=0
		for text in _recent_lines(s,member):
			if taken>=(per+2 if String(member.key)=="envoy" else per) or out.size()>=AVOID_LINES+4: break
			out.append("%s said: \"%s\"" % [String(member.name),String(text).substr(0,110)])
			taken+=1
	return out

func _recent_flourishes(s:Dictionary,member:Dictionary)->PackedStringArray:
	## Oath, address term and pet phrases this speaker already used lately.
	var persona:Dictionary=member.get("persona",{})
	var candidates:Array=[String(persona.get("oath","")),String(persona.get("address",""))]
	candidates.append_array(persona.get("tics",[]))
	var used:PackedStringArray=PackedStringArray()
	var recent:=_recent_lines(s,member)
	for phrase in candidates:
		var p:String=String(phrase).strip_edges().trim_suffix("!").trim_suffix(",").to_lower()
		if p.length()<3: continue
		var hits:=0
		for text in recent:
			if p in text: hits+=1
		if hits>=1: used.append(String(phrase))
	return used

func _offline_lines(s:Dictionary,stage:String,extra:Dictionary,rng:RandomNumberGenerator)->Array[Dictionary]:
	if String(s.kind) in WORK_KINDS:
		match stage:
			"open": return _work_open(s,rng)
			"weigh": return _work_weigh(s,rng,true)
			"closing": return _work_closing(s,extra.get("result",{}),rng)
	match stage:
		"open": return _offline_open(s,rng)
		"speak": return _offline_speak(s,String(extra.get("player_text","")),rng)
		"divine": return _offline_divine(s,extra.get("result",{}),rng)
		"command": return _offline_command(s,extra.get("result",{}),rng)
		"closing": return _offline_closing(s,extra.get("result",{}),rng)
	return []

func _append_if(out:Array[Dictionary],line:Dictionary)->void:
	if not line.is_empty(): out.append(line)

func _offline_open(s:Dictionary,rng:RandomNumberGenerator)->Array[Dictionary]:
	## Short and punchy: the visitor says at most two lines (why they came or
	## what they remember, then the business), and at most two officials speak,
	## each in their own manner.
	var out:Array[Dictionary]=[]
	# Mourning, omens and callbacks were already staged in the court's own
	# voices when the matter was taken up (court_lives.gd).
	if String(s.get("sit_type","")) in LIVES_SCENES and not ((s.audience as Dictionary).get("lines",[]) as Array).is_empty(): return out
	var kind:String=String(s.kind)
	var envoy:Dictionary=s.envoy
	var first_official:Dictionary=s.officials[0] if not s.officials.is_empty() else {}
	var focus:Dictionary=s.get("history_focus",{})
	var history_bank:Array=HISTORY_OPEN.get(_history_group(s,focus),[]) if not focus.is_empty() else []
	var arc:Dictionary=s.get("arc",{})
	var occasion_bank:=_occasion_bank(s)
	# Continuing an earlier audience comes first; otherwise why they came
	# outranks an unrelated memory.
	if not arc.is_empty():
		_remembered(s,out,_say(s,envoy,ARC_OPEN.get(String(arc.get("branch","")),ARC_OPEN.any),rng,first_official,false,ARC_OPEN.any))
	elif not occasion_bank.is_empty() and kind!="report" and (history_bank.is_empty() or String(focus.get("kind",""))!=kind):
		_append_if(out,_say(s,envoy,occasion_bank,rng,first_official))
	elif not history_bank.is_empty() and kind!="report":
		_remembered(s,out,_say(s,envoy,history_bank,rng,first_official,false,_history_reserve(s)))
	match kind:
		"report":
			for item in _scout_call("debrief_lines",s.audience):
				var text:=""
				var aside:bool=false
				if item is Dictionary:
					text=String((item as Dictionary).get("text",""))
					aside=bool((item as Dictionary).get("aside",false))
				elif item is String: text=String(item)
				text=_clean_text(text,envoy)
				if text.is_empty(): continue
				out.append({"key":"envoy","text":text,"aside":aside})
				if out.size()>=2: break
			if out.is_empty(): _append_if(out,_say(s,envoy,ENVOY_OPEN.report,rng,first_official))
		"proposal":
			var protest:bool=String(s.sit_type)=="recruitment_protest"
			var generic:Array=(PROPOSAL_OPEN.get(String(s.sit_type),[]) as Array)+([] if protest else PROPOSAL_OPEN.any as Array)
			# A protest is not an offer: it keeps its own words.
			var own_terms:Array=PROPOSAL_OPEN.recruitment_protest if protest else CV.model_bank(envoy.persona,"proposal")
			_append_if(out,_say(s,envoy,own_terms if not own_terms.is_empty() else generic,rng,first_official,false,generic))
		"summons":
			var regard:Dictionary=s.get("regard",{})
			var bank:Array=SUMMONS_OPEN
			if float(regard.get("dread",0.0))>=0.55: bank=DV.generic("summons_dread")
			elif float(regard.get("love",0.0))>=0.62 and float(regard.get("dread",0.0))<0.3: bank=DV.generic("summons_love")
			_append_if(out,_say(s,envoy,bank,rng,{},false,SUMMONS_OPEN))
		"petition":
			var topic:String=String(s.topic)
			var topic_bank:Array=ENVOY_OPEN.petition_grievance if topic=="grievance" else (ENVOY_OPEN.petition_ambition if topic=="ambition" else PETITION_PLEA.get(topic,PETITION_PLEA_MORE.get(topic,[])))
			if out.is_empty(): _append_if(out,_say(s,envoy,topic_bank,rng,first_official,false,ENVOY_OPEN.petition_generic))
			if not String(s.decree).is_empty():
				_append_if(out,_say(s,envoy,CV.model_bank(envoy.persona,"plea"),rng,{},false,decree_pleas(String(s.decree))))
			elif out.size()<2:
				_append_if(out,_say(s,envoy,topic_bank,rng,first_official,false,ENVOY_OPEN.petition_generic))
		_:
			var generic:Array=(ENVOY_OPEN.get(kind,ENVOY_OPEN.news) as Array)+(ENVOY_OPEN_MORE.get(kind,[]) as Array)
			var business:=_say(s,envoy,CV.model_bank(envoy.persona,kind),rng,first_official,false,generic)
			if business.is_empty(): business=_business_fallback(s)
			_append_if(out,business)
	while out.size()>2: out.pop_front()
	# The ruler behind a foreign envoy: what they remember, then the string
	# their business carries, in the tone of that ruler's signature trait.
	var rival:=_rival_lines(s)
	var rival_envoy:Array=rival.get("envoy",[])
	if not rival_envoy.is_empty():
		var said_now:Array[Dictionary]=[]
		for variants in rival_envoy:
			var line:=_fresh_line(s,variants as Array,"envoy",false)
			if not line.is_empty(): said_now.append(line)
		if not said_now.is_empty():
			# The memory replaces why-they-came; the string follows the business.
			var recall_first:=said_now.size()>1 or not (((s.situation as Dictionary).get("recall",{})) as Dictionary).is_empty()
			if recall_first and out.size()>=2: out.pop_front()
			if recall_first: out.push_front(said_now.pop_front())
			for line in said_now: out.append(line)
	var staged:=0
	var stage_room:=2 if out.size()<=2 else 1
	for text in rival.get("narrator",[]):
		if staged>=stage_room: break
		if not _voice_state().said.has(_text_key(String(text))): out.append({"key":"narrator","text":String(text),"aside":false,"fact":true}); staged+=1
	# Dread curdled with resentment leaks out sideways before it becomes flight.
	if String(s.origin)=="court" and bool((s.get("regard",{}) as Dictionary).get("warned",false)):
		var hint:=_say(s,envoy,DV.generic("flight_hint"),rng,{},true)
		if not hint.is_empty():
			if out.size()>=2: out.pop_back()
			out.append(hint)
	# Court members are silent unless the gate found real guidance the ruler
	# cannot already see (court objections and support are on the answer cards).
	var key:=_gate_key(s)
	var member:=_member(s,key) if not key.is_empty() else {}
	if member.is_empty(): return out
	var gate:Dictionary=s.gate
	if String(gate.get("kind",""))=="objection" and not String(gate.get("text","")).is_empty():
		out.append({"key":key,"text":String(gate.text),"aside":true,"fact":true})
	return out

func _rival_lines(s:Dictionary)->Dictionary:
	if String(s.get("origin",""))!="foreign": return {}
	var rivals:GDScript=load("res://scripts/rival_rulers.gd") as GDScript
	if rivals==null: return {}
	return rivals.call("open_lines",s.audience)

func _fresh_line(s:Dictionary,variants:Array,key:String,manner:bool,member:Dictionary={})->Dictionary:
	## The first of these ready lines not yet said in this hall. Officials say it
	## in their own manner (their lead-ins and tics).
	var said:Dictionary=_voice_state().said
	var rng:=_scene_rng(s,"rival:"+key)
	var era:=_era_for(s,member if not member.is_empty() else s.envoy)
	for text in variants:
		var raw:=String(text).strip_edges()
		if raw.is_empty(): continue
		if said.has(_text_key(raw)) or not line_ok(raw,era): continue
		if manner and not member.is_empty():
			# The reason, then a turn of phrase in their own manner.
			var flourishes:Array=[]
			for bank in ["aside","interject"]:
				for template in CV.model_bank(member.persona,bank):
					var t:=String(template)
					if "{" in t or said.has(_template_key(t)) or not line_ok(t,era) or t.split(" ",false).size()>10: continue
					flourishes.append(t)
			if not flourishes.is_empty():
				var flourish:=String(flourishes[rng.randi_range(0,flourishes.size()-1)])
				return {"key":key,"text":raw+" "+flourish,"aside":false,"tkey":_template_key(flourish),"manner":true,"fact":false}
			var spoken:=CV.speak(member.persona,raw,rng,true,_flourish_memory(s,member),true)
			return {"key":key,"text":spoken,"aside":false,"fact":true}
		return {"key":key,"text":raw,"aside":false,"fact":true}
	return {}

func _occasion_bank(s:Dictionary)->Array:
	## Why they came, as natural speech: every opener half with every closer.
	var occasion:Dictionary=s.get("occasion",{})
	var halves:Array=OCCASION_SPEECH.get(String(occasion.get("type","")),[])
	var out:Array=[]
	if halves.size()<2: return out
	for a in halves[0]:
		for b in halves[1]: out.append("%s %s" % [String(a),String(b)])
	return out

func _business_fallback(s:Dictionary)->Dictionary:
	## The facts, plainly, when every phrasing has been used before.
	var text:=""
	match String(s.kind):
		"gift": text="%s %s, from %s." % [String(s.amt),String(s.res),String(s.civ)]
		"request": text="We ask %s %s." % [String(s.amt),String(s.res)]
		"threat": text="%s %s, as tribute." % [String(s.amt),String(s.res)]
		"news": text=String(s.fact)
	if text.strip_edges().is_empty(): return {}
	return {"key":"envoy","text":_capitalize_sentences(text),"aside":false}

func _remembered(s:Dictionary,out:Array[Dictionary],line:Dictionary)->void:
	## A line recalling a past audience; noted so tests and the hall can tell.
	if line.is_empty(): return
	out.append(line)
	remembered[String(s.id)]=String(line.text)

func decree_pleas(decree:String)->Array:
	## The remedy pleaded several ways: the house line plus frame x phrasing.
	var out:Array=[String(DECREE_PLEA.get(decree,DECREE_PLEA_GENERIC))]
	var phrasings:Array=REMEDY.get(decree,[_lower_initial(decree).trim_suffix(".")])
	for frame in PLEA_FRAMES:
		for remedy in phrasings: out.append(String(frame).replace("{remedy}",String(remedy)))
	return out

func _history_reserve(s:Dictionary)->Array:
	var out:Array=[]
	if not (s.get("arc",{}) as Dictionary).is_empty(): out.append_array(ARC_OPEN.any)
	for group in (["promised","decreed","rebuffed","heard"] if String(s.origin)=="court" else ["visited","welcomed","spurned"]):
		if group in ["promised","decreed","rebuffed"] and group!=_history_group(s,s.get("history_focus",{})): continue
		out.append_array(HISTORY_OPEN[group])
	return out

func _court_reserve(stances:Dictionary,kind_bank:Array,memory:Array)->Array:
	var out:Array=[]
	for key in stances: out.append_array(stances[key])
	out.append_array(kind_bank)
	out.append_array(memory)
	return out

func _report_bank(member:Dictionary)->Array:
	var office:String=(String(member.persona.get("office_key",""))+" "+String(member.persona.get("title",""))).to_lower()
	for key in COURT_REPORT_OFFICE:
		if String(key) in office: return COURT_REPORT_OFFICE[key]
	return COURT_REPORT_ANY

func _offline_speak(s:Dictionary,player_text:String,rng:RandomNumberGenerator)->Array[Dictionary]:
	## One reply: an answer from the facts when the ruler asked something,
	## otherwise the visitor's manner. At most one official reacts.
	var out:Array[Dictionary]=[]
	var mood:=sentiment(player_text)
	var envoy:Dictionary=s.envoy
	var generic:Array=(PETITIONER_REPLY if s.origin=="court" else ENVOY_REPLY).get(mood,ENVOY_REPLY.neutral)
	if String(s.kind) in WORK_KINDS and String(s.envoy.persona.get("figure_id","")).length()>0: generic=BUILDER_REPLY.get(mood,BUILDER_REPLY.neutral)
	var line:Dictionary={}
	var h:Variant=_hall()
	var directive:=false
	if String(s.origin)=="court":
		if h is GDScript: directive=bool((h as GDScript).call("is_directive",player_text))
		elif h is Object and (h as Object).has_method("is_directive"): directive=bool((h as Object).call("is_directive",player_text))
	var regard:Dictionary=s.get("regard",{}) if String(s.origin)=="court" else {}
	var dreadful:=float(regard.get("dread",0.0))>=0.55
	var loving:=float(regard.get("love",0.0))>=0.62 and float(regard.get("dread",0.0))<0.3
	if directive:
		line=_say(s,envoy,DV.generic("order_dread") if dreadful else ORDER_ACK,rng,{},false,ORDER_ACK)
	if line.is_empty():
		var counted:=fact_answer(s,player_text)
		if not counted.is_empty(): line=_say(s,envoy,counted,rng,{},false,counted)
	var answers:=answer_bank(s,player_text) if line.is_empty() else []
	if not answers.is_empty(): line=_say(s,envoy,answers,rng,{},false)
	if line.is_empty() and String(s.kind)=="summons" and "?" in player_text:
		line=_say(s,envoy,SUMMONS_REPLY,rng,{},false)
	answered[String(s.id)]=not line.is_empty()
	if line.is_empty() and dreadful: line=_say(s,envoy,DV.generic("evasive"),rng,{},false,generic)
	elif line.is_empty() and loving and rng.randf()<0.6: line=_say(s,envoy,DV.generic("frank"),rng,{},false,generic)
	if line.is_empty(): line=_say(s,envoy,CV.model_bank(envoy.persona,"reply"),rng,{},false,generic)
	_append_if(out,line)
	# An official speaks only when the ruler addressed them, or to name a real
	# cost the ruler may not have weighed (court_relevance.gd).
	var key:=_gate_key(s)
	var member:=_member(s,key) if not key.is_empty() else {}
	if not member.is_empty():
		var gate:Dictionary=s.gate
		if String(gate.get("kind",""))=="direct_question":
			var counted:=fact_answer(s,player_text)
			var bank:Array=counted if not counted.is_empty() else answer_bank(s,player_text)
			if bank.is_empty(): bank=CV.model_bank(member.persona,"react")
			_append_if(out,_say(s,member,bank,rng,{},false,COURT_REACT.get(mood,COURT_REACT.neutral)))
		elif String(gate.get("kind",""))=="objection" and not ((s.audience as Dictionary).get("lines",[]) as Array).any(func(l:Variant)->bool:return l is Dictionary and String((l as Dictionary).get("text","")).ends_with(String(gate.get("text","")))):
			out.append({"key":key,"text":String(gate.text),"aside":true,"fact":true})
	return out

static func question_type(text:String)->String:
	if not "?" in text and not text.to_lower().begins_with("tell me"): return ""
	for pair in QUESTION_PATTERNS:
		var re:=RegEx.new(); re.compile(String(pair[1]))
		if re.search(text)!=null: return String(pair[0])
	return ""

## Questions about things the state has counted, answered with the count.
## [topic, pattern, number key(s) in voice_context.numbers, answer templates].
const FACT_TOPICS:=[
	["water","(?i)\\b(water|drink|wells?)\\b",["water_days"],["About {n} days of water stored.","Water for about {n} days, as things stand."]],
	["food","(?i)(stores?|food|grain|granar|eat|last\\b|hungry|ration)",["food_days"],["About {n} days, if nobody wastes a mouthful.","The stores hold about {n} days of food.","Roughly {n} days. After that, bark and prayers."]],
	["soldiers","(?i)(soldiers?|warriors?|fighters?|spears?|under arms|garrison|troops|guards?)",["soldiers_seen"],["We counted about {n} under arms.","About {n} fighters, by our count."]],
	["since","(?i)(how long ago|since you (saw|were)|when did you (see|leave)|how old is)",["days_since_seen"],["{n} days ago, no more.","We saw it {n} days back."]],
	["stay","(?i)(how long (will|can) you (stay|wait)|until you leave|when (will|must) you (go|leave))",["days_until_leaving"],["{n} more days, then I must go home.","I can wait {n} days, no longer."]],
	["homeless","(?i)(homeless|shelter|roof|sleep(ing)? outside)",["homeless"],["About {n} people without a proper roof.","Near {n} sleep with no real shelter."]],
	["their_people","(?i)\\b(they|their|them|those people)\\b.*\\b(many|number|people|souls|strong)\\b|how many (are|of) (they|them)",["their_population"],["About {n} of them, near enough.","They number about {n}."]],
	["our_people","(?i)how many (are )?(we|of us|people|souls|mouths)",["population"],["We number about {n}.","About {n} souls, counting the babes."]],
]
const DONT_KNOW:=["I don't know that. Nobody has counted it.","That I can't tell you; no one has a count.","I don't know, and I won't guess at it."]

func fact_answer(s:Dictionary,player_text:String)->Array:
	## Real numbers for how-long/how-many/how-much questions. Empty when the
	## question is not about a counted thing; DONT_KNOW when it is but the
	## figure is absent.
	var lower:=player_text.to_lower()
	if not "?" in player_text: return []
	var re_q:=RegEx.new(); re_q.compile("(?i)\\b(how long|how many|how much|how big|how old|when did|until|number)\\b")
	if re_q.search(lower)==null: return []
	var numbers:Dictionary=(s.get("ctx",{}) as Dictionary).get("numbers",{}) if (s.get("ctx",{}) as Dictionary).get("numbers") is Dictionary else {}
	for topic in FACT_TOPICS:
		var re:=RegEx.new(); re.compile(String(topic[1]))
		if re.search(lower)==null: continue
		for key in topic[2]:
			if numbers.has(String(key)):
				var out:Array=[]
				for template in topic[3]: out.append(String(template).replace("{n}",str(int(numbers[String(key)]))))
				return out
		return DONT_KNOW.duplicate()
	return []

func answer_bank(s:Dictionary,player_text:String)->Array:
	var q:=question_type(player_text)
	if q.is_empty(): return []
	var by_kind:Dictionary=ANSWERS.get(q,{})
	var specific:Array=by_kind.get(String(s.get("sit_type","")),[])
	if not specific.is_empty(): return specific
	if String(s.get("sit_type",""))=="recruitment_protest": return by_kind.get("any",[])
	return by_kind.get(String(s.kind),by_kind.get("any",[]))

func _offline_closing(s:Dictionary,result:Dictionary,rng:RandomNumberGenerator)->Array[Dictionary]:
	## One parting line that reacts to the actual outcome, and at most one aside.
	var out:Array[Dictionary]=[]
	if String(s.get("sit_type","")) in LIVES_SCENES: return out
	var option_id:String=String(result.get("option_id",(s.audience as Dictionary).get("option_id","")))
	var reaction:String=String(result.get("reaction","neutral"))
	var envoy:Dictionary=s.envoy
	if String(s.kind)=="request" and option_id=="refuse": option_id="refuse_request"
	if String(s.kind)=="proposal" and option_id in ["accept","refuse"]: option_id=option_id+"_proposal"
	if String(s.kind)=="report":
		if "reward" in option_id: option_id="reward_scouts"
		elif "back" in option_id or "closer" in option_id or "again" in option_id or "resend" in option_id: option_id="send_back"
	var truthful:Array=CLOSING_OPTION.get(option_id,CLOSING_MORE.get(option_id,CLOSING_REACTION.get(reaction,CLOSING_REACTION.neutral)))
	var group:="warm" if reaction in ["delighted","pleased"] else ("hostile" if reaction in ["offended","furious"] else "neutral")
	var farewell:Array=CV.model_bank(envoy.persona,{"warm":"farewell_warm","hostile":"farewell_cold","neutral":"farewell_neutral"}[group])
	var bank:Array=truthful
	var reserve:Array=farewell
	# A foreign visitor usually parts in their own manner; an official's
	# answer is told plainly, since it binds them.
	if String(s.origin)=="foreign" and not farewell.is_empty() and rng.randf()<0.6:
		bank=farewell; reserve=truthful
	var repeat_tokens:=_closing_repeat_tokens(s,option_id)
	if not repeat_tokens.is_empty():
		s["htok"]=repeat_tokens
		reserve=bank+reserve
		bank=(CLOSING_REPEAT.get(option_id,[]) as Array)+(CLOSING_REPEAT.any as Array)
	_append_if(out,_say(s,envoy,bank,rng,{},false,reserve+(CLOSING_REACTION.get(reaction,CLOSING_REACTION.neutral) as Array)))
	# No parting aside: the choice is made and on screen; a court comment on it
	# adds nothing the ruler lacks (court_relevance.gd).
	return out

const FAVOR_ACTS:=["bless","boon","raise_up"]
const RESPONSE_MANNER:={"cower":"cower","endure":"cower","penance":"cower","defy":"defy","relief":"blessed","blessed":"blessed"}

func _offline_divine(s:Dictionary,result:Dictionary,rng:RandomNumberGenerator)->Array[Dictionary]:
	## The god has acted. The target answers in their own manner (breaking,
	## enduring, defying, relieved or blessed) unless they were removed; then
	## one or two witnesses murmur, each as they took it.
	var out:Array[Dictionary]=[]
	var action:=String(result.get("action",""))
	var response:=String(result.get("response","none"))
	var terminal:=bool(result.get("terminal",false))
	var envoy:Dictionary=s.envoy
	var foreign:=String(s.origin)=="foreign"
	if not terminal and response!="none":
		var key:=response
		if action=="penance" and response!="defy": key="penance"
		var generic:Array
		if foreign: generic=DV.generic("envoy_defy" if response=="defy" else "envoy_cower")
		else: generic=DV.generic(key)
		var own:Array=DV.model_bank(envoy.persona,String(RESPONSE_MANNER.get(key,"cower")))
		var first:Array=own if not own.is_empty() and rng.randf()<0.7 else generic
		_append_if(out,_say(s,envoy,first,rng,{},false,generic+own))
	var effects:Dictionary=result.get("effects",{}) if result.get("effects") is Dictionary else {}
	var seen:Dictionary=effects.get("witnesses",{}) if effects.get("witnesses") is Dictionary else {}
	var pool:Array=(s.officials as Array).duplicate()
	var shuffled:Array=[]
	while not pool.is_empty(): shuffled.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
	var count:int=2 if terminal else (1 if rng.randf()<0.6 else 2)
	for member:Dictionary in shuffled.slice(0,count):
		var w:Variant=seen.get(int(member.person_id),seen.get(str(int(member.person_id)),{}))
		var wresp:=String((w as Dictionary).get("response","shaken")) if w is Dictionary else "shaken"
		var key2:=""
		if foreign: key2="witness_envoy"
		elif action=="strike_down": key2="witness_execution"
		elif action=="cast_out": key2="witness_exile"
		elif not action in FAVOR_ACTS: key2="witness_unbowed" if wresp=="unbowed" else "witness_shaken"
		else: key2="witness_envy" if wresp=="envy" else "witness_glad"
		var manner:Array=DV.model_bank(member.persona,"witness_favor" if action in FAVOR_ACTS else "witness_dread")
		var generic2:Array=DV.generic(key2)
		var aside:bool=key2 in ["witness_shaken","witness_execution","witness_envy","witness_exile"]
		var bank:Array=manner if not manner.is_empty() and rng.randf()<0.6 else generic2
		_append_if(out,_say(s,member,bank,rng,{},aside,generic2+manner))
	return out

func _member_for(s:Dictionary,entry:Dictionary)->Dictionary:
	if entry.is_empty(): return {}
	if bool(entry.get("speaker",false)): return s.envoy
	var pid:=int(entry.get("person_id",0))
	for member in s.officials:
		if pid>0 and int(member.person_id)==pid: return member
	return {}

func _stage_line(s:Dictionary,result:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	## The bracketed stage direction for what the engine decided, era-true and
	## never said before in this hall.
	var bank:=CC.stage_bank(result)
	if bank.is_empty(): return {}
	var tags:Array=CV.era_tags("player")
	var tokens:=CC.stage_tokens(result,tags,rng)
	var said:Dictionary=_voice_state().said
	var fresh:Array=[]; var unsaid:Array=[]
	for template in bank:
		if not _usable(String(template),tokens): continue
		var filled:=_fill(String(template),tokens)
		if not line_ok(filled,tags) or said.has(_text_key(filled)): continue
		unsaid.append(template)
		if not said.has(_template_key(String(template))): fresh.append(template)
	var pool:Array=fresh if not fresh.is_empty() else unsaid
	if pool.is_empty():
		# Every wording is spent: the plain fact, staged.
		var plain:=stage_direction(String(result.get("outcome","")).get_slice(". ",0))
		return {"key":"narrator","text":plain,"tkey":""} if not plain.is_empty() and not said.has(_text_key(plain)) else {}
	var chosen:=String(pool[rng.randi_range(0,pool.size()-1)])
	return {"key":"narrator","text":_fill(chosen,tokens),"tkey":_template_key(chosen)}

const COMMAND_WITNESS:={"maim":"witness_execution","kill":"witness_execution","exile":"witness_exile","detain":"witness_exile","terrify":"witness_shaken","penance":"witness_shaken",
	"hesitate":"witness_shaken","refuse_flee":"witness_shaken","refuse_seized":"witness_shaken","prostrate":"witness_shaken","demote":"witness_shaken",
	"bless":"witness_glad","raise":"witness_envy","appoint":"witness_envy","boon":"witness_glad","give":"witness_glad"}

func _offline_command(s:Dictionary,result:Dictionary,rng:RandomNumberGenerator)->Array[Dictionary]:
	## Stage direction, the actor's answer as decided, the target's if they are
	## still here, one witness. The factual outcome is appended on delivery.
	var out:Array[Dictionary]=[]
	_append_if(out,_stage_line(s,result,rng))
	var stage:=String(result.get("stage",""))
	var actor_entry:Dictionary=result.get("actor",{}) if result.get("actor") is Dictionary else {}
	var target_entry:Dictionary=result.get("target",{}) if result.get("target") is Dictionary else {}
	var actor:=_member_for(s,actor_entry)
	if String(actor.get("key",""))=="envoy" and not _envoy_may_speak(s,result): actor={}
	var spoke:Dictionary={}
	var key:=CC.actor_reaction_key(result)
	if not actor.is_empty() and key!="":
		var bank:=CC.reaction_bank(key)
		var regard:Dictionary=s.get("regard",{})
		if key=="obey_task" and stage=="order":
			# An ordinary order: the same acknowledgement the council has always given.
			bank=DV.generic("order_dread") if float(regard.get("dread",0.0))>=0.55 and String(actor.key)=="envoy" else ORDER_ACK
		_append_if(out,_say(s,actor,bank,rng,{},false,bank))
		spoke[String(actor.key)]=true
	var target:=_member_for(s,target_entry)
	if not bool(result.get("removed",false)) and not target.is_empty() and not spoke.has(String(target.key)) and not (String(target.key)=="envoy" and not _envoy_may_speak(s,result)):
		var tbank:Array=[]
		if stage in ["give","boon"]: tbank=CC.reaction_bank("receive")
		elif stage in ["penance","terrify","demote"]: tbank=DV.generic("cower")
		elif stage in ["bless","raise","appoint"]: tbank=DV.generic("blessed")
		if not tbank.is_empty() and bool(result.get("executed",false)):
			_append_if(out,_say(s,target,tbank,rng,{},false,tbank))
			spoke[String(target.key)]=true
	var wkey:=String(COMMAND_WITNESS.get(stage,""))
	if wkey!="":
		var pool:Array=[]
		for member in s.officials:
			if not spoke.has(String(member.key)): pool.append(member)
		if not pool.is_empty():
			var witness:Dictionary=pool[rng.randi_range(0,pool.size()-1)]
			var envoy_act:=String(target_entry.get("kind",""))=="envoy" and stage in ["kill","maim","detain","exile"]
			if envoy_act:
				# Horror, approval or fear, by the witness's own temper and regard.
				var wbank:=DV.generic(witness_envoy_key(int(witness.get("person_id",0))))
				_append_if(out,_say(s,witness,wbank,rng,{},true,wbank))
				return out
			var generic:Array=DV.generic(wkey)
			var manner:Array=DV.model_bank(witness.persona,"witness_favor" if wkey in ["witness_glad","witness_envy"] else "witness_dread")
			_append_if(out,_say(s,witness,manner if not manner.is_empty() and rng.randf()<0.5 else generic,rng,{},true,generic+manner))
	return out

static func witness_envoy_key(person_id:int)->String:
	## How one of the court takes violence done to an envoy: fear when dread
	## rules them, horror when they are tender-hearted or cool to the god,
	## approval otherwise.
	var person:Dictionary=CC.Hall._official(person_id) if person_id>0 else {}
	if person.is_empty(): return "witness_envoy_fear"
	var personality:Dictionary=person.get("personality",{}) if person.get("personality") is Dictionary else {}
	var empathy:=float(personality.get("empathy",0.5))
	var dread:=CC.DIVINE.dread_of(person)
	var love:=CC.DIVINE.love_of(person)
	if dread>=0.55: return "witness_envoy_fear"
	if empathy>=0.6 or love<0.35: return "witness_envoy_horror"
	return "witness_envoy_approve"

static func envoy_state_words(result:Dictionary)->String:
	## What became of a foreign envoy, for the live voice.
	var target:Dictionary=result.get("target",{}) if result.get("target") is Dictionary else {}
	if String(target.get("kind",""))!="envoy": return ""
	var name:=String(result.get("target_name","the envoy"))
	match String(result.get("envoy_state","")):
		"dead": return "THE ENVOY %s IS DEAD and says nothing, ever again. Their retinue flees or wails; the narrator shows it." % name
		"maimed": return "THE ENVOY %s WAS MAIMED%s: they scream, faint or are dragged out by their own bearers; they never answer calmly and never say 'it is done'. Their retinue reacts in terror and grief." % [name," (their "+String(result.get("part",""))+")" if String(result.get("part",""))!="" else ""]
		"beaten": return "THE ENVOY %s WAS FLOGGED BLOODY and is carried out groaning; they say nothing calm. Their retinue reacts." % name
		"shamed": return "THE ENVOY %s WAS SHAMED before the court and is pushed out shaking with shame and fury; no calm reply." % name
		"bound": return "THE ENVOY %s IS BOUND and dragged away under guard; their retinue is driven out to carry word home." % name
		"driven out": return "THE ENVOY %s WAS DRIVEN OUT of the hall and does not speak again here." % name
	return ""

func _command_instruction(s:Dictionary,extra:Dictionary)->String:
	var result:Dictionary=extra.get("result",{})
	var tools:=CC.weapons(CV.era_tags("player"))
	var actor:=_member_for(s,result.get("actor",{}) if result.get("actor") is Dictionary else {})
	var ob:=String((result.get("obedience",{}) as Dictionary).get("id","obey"))
	var parts:PackedStringArray=PackedStringArray([CC.decided_words(result)])
	var fate:=envoy_state_words(result)
	if fate!="": parts.append(fate+" Any goods moved are exactly as WHAT ACTUALLY HAPPENED says, and no others.")
	parts.append("The ruler's words were: \"%s\". The stage direction shows what the engine decided, never a different act." % String(result.get("text","")).substr(0,200))
	parts.append("First 'narrator' writes ONE stage direction in square brackets, one or two sentences, vivid, concrete and physical (graphic is fine), showing exactly what was decided and how the watchers take it. Weapons and tools only from: %s, cord, or bare hands; nothing the WORLD line lacks. Name people as given." % ", ".join(tools))
	if not actor.is_empty():
		var manner:String=String({"obey":"answers in ONE short line: it is done, or they go at once, in their own manner","reluctant":"answers in ONE short line: it cost them, but they did it","hesitate":"pleads in ONE short line not to have to do it; they have not done it","refuse":"says in ONE short line why they would not; they have not done it"}.get(ob,"answers in ONE line"))
		parts.append("'%s' %s." % [String(actor.key),manner])
	parts.append(_gate_words(s).strip_edges()+" At most 1 official reacts, only to exactly what happened, in their own temper (horror, approval or fear); nobody praises an act that did not happen or treats the outcome as something else. Nobody refuses or undoes anything unless REFUSED is written above. The dead and the removed never speak. No miracles. mood_shift 0.")
	return " ".join(parts)

func _divine_classify_words(s:Dictionary)->String:
	var allowed:=_divine_allowed(s)
	if allowed.is_empty(): return ""
	var meanings:={"terrify":"'terrify' if the words are raging, threatening fury meant to terrify","penance":"'penance' if they demand atonement or penance","bless":"'bless' if they bless","raise_up":"'raise_up' if they exalt the listener above others"}
	var said:PackedStringArray=PackedStringArray()
	for act in allowed: said.append(String(meanings.get(act,act)))
	return " Also set divine to %s; otherwise 'none'. If you set it, the lines already react to it (terror, defiance, relief, gratitude)." % ", ".join(said)

func _regard_line(regard:Dictionary)->String:
	if regard.is_empty(): return "unknown"
	var parts:PackedStringArray=PackedStringArray([String(regard.get("reads",""))])
	for key in ["love","dread","candor"]:
		if regard.has(key): parts.append("%s: %s" % [key,String(regard[key])])
	if regard.has("thinking_of_flight"): parts.append(String(regard.thinking_of_flight))
	return "; ".join(parts)

func _prompt_regard(s:Dictionary)->String:
	## How each speaker holds the god right now, and what the god has lately done.
	var ctx:Dictionary=s.get("ctx",{})
	var rows:PackedStringArray=PackedStringArray()
	if String(s.origin)=="foreign":
		var theirs:Dictionary=ctx.get("their_regard",{}) if ctx.get("their_regard") is Dictionary else {}
		if not theirs.is_empty(): rows.append("- envoy's people: %s (reverence %s, dread %s)" % [String(theirs.get("reads","")),String(theirs.get("reverence","")),String(theirs.get("dread",""))])
	else:
		var petitioner:Dictionary=ctx.get("petitioner",{}) if ctx.get("petitioner") is Dictionary else {}
		if petitioner.get("regard") is Dictionary: rows.append("- envoy: "+_regard_line(petitioner.regard))
	for entry in ctx.get("court",[]):
		if not entry is Dictionary or not (entry as Dictionary).get("regard") is Dictionary: continue
		for member in s.officials:
			if int(member.person_id)==int(entry.get("person_id",0)): rows.append("- %s: %s" % [String(member.key),_regard_line(entry.regard)])
	var acts:Array=ctx.get("recent_acts_of_the_god",[])
	var text:=""
	if not rows.is_empty(): text="REGARD FOR THE GOD (let it colour every line):\n"+"\n".join(rows)
	if not acts.is_empty(): text+=("\n" if text!="" else "")+"THE GOD LATELY (true; the court remembers): "+"; ".join(PackedStringArray(acts))
	return text

func _divine_allowed(s:Dictionary)->Array:
	## Spoken acts the live classifier may report here.
	var h:Variant=_hall()
	var allowed:Array=[]
	var options:Variant=[]
	if h is GDScript: options=(h as GDScript).call("divine_options",String(s.id))
	elif h is Object and (h as Object).has_method("divine_options"): options=(h as Object).call("divine_options",String(s.id))
	if options is Array:
		for option in options:
			if option is Dictionary and bool(option.get("enabled",false)) and String(option.get("id","")) in DIVINE_SPOKEN: allowed.append(String(option.id))
	return allowed

const DIVINE_STAGE_WORDS:={
	"terrify":"The god has just unleashed terrifying fury on %s before the whole court.",
	"penance":"The god has just demanded penance of %s: fasting and vigil until appeased.",
	"cast_out":"At the god's word, %s has just been stripped of office and driven out of the realm. They are gone and do not speak.",
	"strike_down":"At the god's word, %s has just been seized by the guards and put to death. They are gone and do not speak.",
	"bless":"The god has just blessed %s before the whole court.",
	"boon":"The god has just given %s a real gift from the stores.",
	"raise_up":"The god has just raised %s above their peers before the court.",
}

func _divine_instruction(s:Dictionary,extra:Dictionary)->String:
	var result:Dictionary=extra.get("result",{})
	var action:=String(result.get("action",""))
	var what:=String(DIVINE_STAGE_WORDS.get(action,"The god has acted on %s.")) % String(result.get("name",s.envoy.name))
	var response:=String(result.get("response","none"))
	var how:String=String({"cower":"'envoy' breaks: trembling, pleading, prostrate, in their own manner","endure":"'envoy' bows under it, shaken, accepting","defy":"'envoy' is proud: stands straight, answers with dignity or cold defiance, never grovels",
		"relief":"'envoy' was frightened and now floods with relief","blessed":"'envoy' is moved and grateful, in their own manner"}.get(response,""))
	var parts:PackedStringArray=PackedStringArray([what+" WHAT ACTUALLY HAPPENED: "+String(result.get("outcome",""))])
	if bool(result.get("terminal",false)) or how=="": parts.append("'envoy' says nothing."+_gate_words(s)+" Nobody pleads for the dead, nobody invents what happens next.")
	else: parts.append(how+", in ONE line."+_gate_words(s))
	parts.append("No miracles, nothing supernatural. mood_shift 0.")
	return " ".join(parts)

# ---------------------------------------------------------------------------
# Prompt craft
# ---------------------------------------------------------------------------

const COMMAND_CLASSIFY:=" Also fill command, reading the ruler's words: act is question, statement, command (an order for someone to do something, however phrased), threat or blessing; verb is the kind of order (kill, exile, detain, penance, terrify, bless, boon, raise, demote, appoint, give, take, send, or order for anything else) or none; actor_ref is who is told to do it exactly as the ruler referred to them ('Ansel', 'you', 'the guards') or ''; target_ref is who it is done to as referred to ('him', 'the war leader', 'Zuri') or ''; object is goods with amount, an office, a place or the task, or ''; confidence 0 to 1. If it is an order, keep the lines short and never refuse: the god's word is law and the court reacts once it is done."

static func response_format(keys:Array[String],divine:Array=[],command:bool=false)->Dictionary:
	var format:={"type":"json_schema","json_schema":{"name":"audience_lines","strict":true,"schema":{
		"type":"object","additionalProperties":false,"required":["lines","mood_shift"],
		"properties":{
			"lines":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["speaker_key","text","aside"],
				"properties":{"speaker_key":{"type":"string","enum":keys},"text":{"type":"string"},"aside":{"type":"boolean"}}}},
			"mood_shift":{"type":"number"}}}}}
	if not divine.is_empty():
		# A bounded classification of the ruler's own words; the hall decides.
		var schema:Dictionary=format.json_schema.schema
		schema.properties["divine"]={"type":"string","enum":["none"]+divine}
		(schema.required as Array).append("divine")
	if command:
		# A bounded reading of the ruler's words as a speech act; the court's
		# command engine resolves who is meant and decides what happens.
		var schema2:Dictionary=format.json_schema.schema
		schema2.properties["command"]={"type":"object","additionalProperties":false,"required":["act","verb","actor_ref","target_ref","object","confidence"],
			"properties":{"act":{"type":"string","enum":CC.ACTS},"verb":{"type":"string","enum":["none"]+CC.VERBS},"actor_ref":{"type":"string"},"target_ref":{"type":"string"},"object":{"type":"string"},"confidence":{"type":"number"}}}
		(schema2.required as Array).append("command")
	return format

static func _mood_words(value:float)->String:
	if value<=-0.5: return "icy; the visitor is barely civil"
	if value<=-0.15: return "frosty"
	if value<0.15: return "wary but civil"
	if value<0.5: return "warming up"
	return "merry; the visitor is enjoying themselves"

func _kind_words(s:Dictionary)->String:
	var civ:String=String(s.civ)
	match String(s.kind):
		"gift":
			var string:=String(((s.get("situation",{}) as Dictionary).get("string",{}) as Dictionary).get("text",""))
			return "An envoy of %s brings a GIFT: %s %s, from their own stores. It is NOT free; its string or cost: %s Whoever speaks of the gift names this cost or string; nobody calls it free, a free bundle, or without strings." % [civ,s.amt,s.res,string if string!="" else "every gift between peoples obliges something in return, and their ruler will remember it."]
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
		"proposal": return "An envoy of %s makes a PROPOSAL (%s): %s" % [civ,String(s.get("headline","an offer")),String(s.get("sit_summary",""))]
		"wonder_proposal","great_work": return _work_scene_words(s)
	return ""

func _audience_want(s:Dictionary,member:Dictionary)->String:
	var persona:Dictionary=member.persona
	if String(member.key)=="envoy":
		if String(s.kind)=="report": return "to be believed, to have the danger or the prize taken seriously, and to be sent out again"
		if String(s.kind) in WORK_KINDS: return _work_want(s)
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
	var occasion:Dictionary=s.get("occasion",{})
	if not String(occasion.get("text","")).is_empty():
		parts.append("WHY THEY CAME (true; the visitor's first words grow out of this): %s%s" % [String(occasion.text)," (a crisis)" if bool(occasion.get("crisis",false)) else ""])
	var arc:Dictionary=s.get("arc",{})
	if not arc.is_empty():
		var entry:Dictionary=s.get("arc_entry",{})
		parts.append("CONTINUING AN EARLIER AUDIENCE (%s, %s; the visitor must acknowledge it): %s" % [String(arc.get("branch","")).replace("_"," "),when_words(maxi(0,_day()-int(entry.get("day",_day())))),JSON.stringify(arc.get("previous",{})).substr(0,400)])
	var home_tags:=CV.era_tags("player")
	parts.append("WORLD AS THESE PEOPLE KNOW IT: "+CV.world_line(home_tags+(s.get("fact_tags",[]) as Array)))
	var visitor_tags:Array=s.envoy.persona.get("era_tags",home_tags)
	if String(s.origin)=="foreign" and JSON.stringify(visitor_tags)!=JSON.stringify(home_tags):
		parts.append("THE VISITOR'S OWN PEOPLE KNOW: "+CV.world_line(visitor_tags+(s.get("fact_tags",[]) as Array))+" The court speaks only of what the ruler's people know.")
	var ctx:Dictionary=(s.ctx as Dictionary).duplicate(true)
	ctx.erase("court"); ctx.erase("audience_id"); ctx.erase("status"); ctx.erase("mood")
	ctx.erase("history_with_speaker"); ctx.erase("history_with_civ")   # summarized below
	var facts:String=JSON.stringify(ctx)
	if facts.length()>2400: facts=facts.substr(0,2400)+"...}"
	parts.append("FACTS YOU MAY USE (nothing else is true): "+facts)
	var mood:float=float((s.audience as Dictionary).get("mood",0.0))
	parts.append("ROOM: %s (%.2f)." % [_mood_words(mood),mood])
	var regard:=_prompt_regard(s)
	if not regard.is_empty(): parts.append(regard)
	var cast:PackedStringArray=PackedStringArray()
	var envoy_label:="the petitioning official" if s.origin=="court" else "the visitor"
	cast.append("- envoy (%s) = %s | in this audience wants %s" % [envoy_label,CV.brief(s.envoy.persona),_audience_want(s,s.envoy)])
	for member in s.officials:
		cast.append("- %s (court official) = %s | in this audience wants %s" % [String(member.key),CV.brief(member.persona),_audience_want(s,member)])
	parts.append("CAST (speaker_key = character; use no one else):\n"+"\n".join(cast))
	var past:=_prompt_history(s)
	if not past.is_empty():
		parts.append("BEFORE TODAY (true; these people remember it and should refer to it where it matters, such as a promise still unkept or a refusal still resented; invent nothing beyond it):\n"+past)
	var avoid:=_prompt_avoid(s)
	if not avoid.is_empty():
		parts.append("SAID IN RECENT AUDIENCES (do not reuse this wording, these openings or these jokes; find new ones):\n"+"\n".join(avoid))
	var worn:PackedStringArray=PackedStringArray()
	for member in [s.envoy]+(s.officials as Array):
		var used:=_recent_flourishes(s,member)
		if not used.is_empty(): worn.append("%s: %s" % [String(member.name),", ".join(used)])
	if not worn.is_empty():
		parts.append("FLOURISHES WORN OUT LATELY (skip them this time): "+"; ".join(worn))
	var history:PackedStringArray=PackedStringArray()
	var lines:Array=(s.audience as Dictionary).get("lines",[])
	for line in lines.slice(maxi(0,lines.size()-10)):
		history.append("%s%s: %s" % [String(line.get("speaker",""))," (aside)" if bool(line.get("aside",false)) else "",String(line.get("text",""))])
	parts.append("SO FAR:\n"+("\n".join(history) if not history.is_empty() else "(the doors have just opened)"))
	parts.append("NOW: "+_stage_instruction(s,stage,extra))
	return "\n\n".join(parts)

## The prompt's word on court officials: silent unless the gate chose one.
func _gate_words(s:Dictionary)->String:
	var gate:Dictionary=s.get("gate",{}) if s.get("gate") is Dictionary else {}
	if bool(gate.get("all",false)): return ""
	var key:=String(gate.get("key",""))
	if key.is_empty() or _member(s,key).is_empty(): return " No official speaks."
	var why:=String({"direct_question":"the ruler addressed them; they answer plainly","dissent":"they resent what the god just did; let it show in one guarded line","objection":"they object with the concrete stakes: %s" % String(gate.get("text","")),"hidden_info":"they know something the ruler cannot see: %s" % String(gate.get("text","")),"own_kin":"their own kin are affected"}.get(String(gate.get("kind","")),"only if they have real guidance"))
	return " Optionally '%s' adds ONE short line (%s); no other official speaks." % [key,why]

func _stage_instruction(s:Dictionary,stage:String,extra:Dictionary)->String:
	var bench:int=int(s.officials.size())
	match stage:
		"open":
			var who:="'envoy' is the petitioning official: they make their case with feeling and a little self-interest." if s.origin=="court" else "'envoy' speaks first: a greeting with flourish and attitude, then the business in plain terms, exact amounts as given."
			if String(s.kind) in WORK_KINDS: who=_work_open_instruction(s)
			if String(s.kind)=="report": who="'envoy' is the Chief Scout, back from the field. Debrief in 2 to 3 lines: plain-spoken, concrete and sensory (what they saw, heard, smelled, who they met, what surprised or worried them, what they covet), opinionated, with uncertainty spoken naturally ('I'd not swear to it, but...'). Use only the findings supplied; never add numbers, places or events."
			if not (s.get("arc",{}) as Dictionary).is_empty(): who+=" The visitor first acknowledges the earlier audience named in CONTINUING."
			elif not String((s.get("occasion",{}) as Dictionary).get("text","")).is_empty(): who+=" The visitor's opening grows out of WHY THEY CAME."
			if bench==0: return who+" Nobody else is on the bench, so 'envoy' may add one more line. 1 to 2 lines total. mood_shift 0."
			return who+" 'envoy' says at most 2 lines in all."+_gate_words(s)+" mood_shift 0."
		"speak":
			return "The ruler just said: \"%s\". 'envoy' answers in ONE line, in character; if it was a question, the line answers it plainly from FACTS (what they gain, what happens if refused, why now). Change no terms and accept nothing new.%s Set mood_shift by how the ruler's words land with 'envoy'.%s%s" % [String(extra.get("player_text","")),_gate_words(s),_divine_classify_words(s),COMMAND_CLASSIFY]
		"divine":
			return _divine_instruction(s,extra)
		"command":
			return _command_instruction(s,extra)
		"persons":
			return PersonsBridge.instruction(String(extra.get("player_text","")),extra.get("menu",[]),Persons.hidden_words(String(s.id)))
		"weigh":
			return "The ruler is weighing the chosen work at the chosen ambition. Using ONLY the feasibility factors and verdict in FACTS (wonder_proposal.factors, spoken_verdict, odds_in_words), 2 to 4 officials each speak to the factor nearest their office (stores and stone: the Quartermaster; know-how and craft: the Scholar; war and safety: the Marshal; the people's mood and food: the Steward), one line each, in character, never as a number or percentage; then 'envoy' answers the doubts in one line. mood_shift 0."
		"closing":
			var result:Dictionary=extra.get("result",{})
			var option_id:String=String(result.get("option_id",(s.audience as Dictionary).get("option_id","")))
			return "The ruler has decided. WHAT ACTUALLY HAPPENED: %s (answer: %s). The visitor's reaction: %s. 'envoy' gives one parting line reacting to exactly this outcome and this reaction; no other outcome, no new promises. Then %s. mood_shift 0." % [String(result.get("outcome","")),option_id if not option_id.is_empty() else "given",String(result.get("reaction","neutral")),"stop. Exactly 1 line"]
	return ""

# ---------------------------------------------------------------------------
# Great Works: wonder pitches, master builders, outcomes, dedications.
# Tokens (only when real): {work} {form} {purpose} {stage} {pct} {odds}
# {verdict} {others} {trigger} {ambition} {city} {ruin} {dead} {eventtext}
# {forecast} {civtwo} {gatetext} {style} {gift} {name}
# ---------------------------------------------------------------------------

const WORK_KINDS:=["great_work","wonder_proposal"]

const PITCH_OPEN:=[
	"{trigger} I've not slept properly since, {address}, because I keep seeing the same thing when I close my eyes.",
	"{oath} Hear me out before anyone sighs, {address}. {trigger} A people who lives through that should leave something standing.",
	"I've carried this in my chest for a season, {address}, and it's grown too big to keep in there. {trigger}",
	"Let me describe it, {address}, and then tell me it isn't worth doing. {trigger}",
]
const PITCH_CONCEPT:=[
	"Picture it: {work}. A {form} to {purpose}, and nobody who sees it will ever mistake us for anyone else.",
	"I'd call it {work}, {address}: a {form}, raised to {purpose}. Our grandchildren will argue about who thought of it first. It was me.",
	"{work}, {address}. A {form} to {purpose}, built the way only our people would build it.",
]
const PITCH_CONCEPT_NOPURPOSE:=[
	"Picture it: {work}, a {form} like nothing standing anywhere, and ours down to the last stone.",
	"I'd call it {work}, {address}: a {form} our grandchildren will argue about.",
]
const PITCH_OTHERS:=[
	"There's also {others}, {address}, if you'd rather spend less.",
	"I've planned {others} too, {address}, in case the stores can't bear the big one.",
]
const PITCH_COURT:={
	"glory":[
		"{oath} Build it, {address}. People will come from other valleys to see it, and some will stay.",
		"I can see it already, {address}, and so will every envoy who comes over that ridge.",
		"If we raise {work}, {address}, neighbours will think twice before threatening us.",
		"Say yes, {address}. The crews want to start before the ground freezes.",
	],
	"folly":[
		"Lovely dream, {address}. Now who's going to carry it, and what are they eating while they do?",
		"{oath} If we run out of hands halfway, {address}, we're left with a heap of stone and a hungry winter.",
		"It'll take years of our strongest backs, {address}. Those are years of hunting and gathering nobody does.",
		"I'll say it so nobody else has to, {address}: we can't afford this, however fine it sounds.",
	],
}
const WEIGH_OFFICE:={
	"quartermaster":{"help":["I've counted the yards twice, {address}, and for once I'm not frowning: {factor}","The stores can bear it, {address}, just about: {factor}"],"hurt":["I've counted the yards twice, {address}, and the count doesn't change: {factor}","Before anyone falls in love with it, {address}: {factor}"]},
	"scholar":{"help":["We know how, {address}, which is more than most peoples can say: {factor}","It's within our learning, {address}: {factor}"],"hurt":["Does anyone here actually know how to do this, {address}? Because {factor}","We'd be guessing at the method, {address}: {factor}"]},
	"marshal":{"help":["The frontier's quiet enough for it, {address}: {factor}","I can spare the hands, {address}: {factor}"],"hurt":["It'll take hands off the watch, {address}: {factor}","Someone has to guard the frontier while this goes up, {address}: {factor}"]},
	"steward":{"help":["The people will carry it, {address}, and gladly: {factor}","They're with you on this, {address}: {factor}"],"hurt":["Think of the people who'll haul it, {address}: {factor}","The people will ask why, {address}, and here's what they'll say: {factor}"]},
	"any":{"help":["Here's the good news, {address}: {factor}","One thing in its favour, {address}: {factor}"],"hurt":["Here's what worries me, {address}: {factor}","The problem nobody's mentioned, {address}: {factor}"]},
}
const WEIGH_VERDICT:=[
	"Plainly, {address}? At this ambition it's {odds}. {verdict}",
	"Put all that together and it's {odds}, {address}. {verdict}",
	"I'll not dress it up, {address}: {odds}. {verdict}",
]
const ODDS_ORDER:=["folly, most likely","a long gamble","an even wager","likely, with care","as sure as stone gets"]
const WEIGH_SHIFT:={
	"better":["{ambition}, then? Now you're talking sense, {address}: {odds}.","That's less stone to haul, {address}. I'd call it {odds} now.","{oath} Pull it back to {ambition} and it's within our reach, {address}: {odds}."],
	"worse":["{ambition}? Then hear it plainly, {address}: {odds}, and no better.","Bolder means more stone and more risk, {address}. It's {odds} now.","{oath} {ambition} it is, {address}, and the odds slide to {odds}."],
	"same":["{ambition} changes the bill more than the odds, {address}: still {odds}.","Same stone, same risk, {address}. It stays {odds}."],
	"other":["{work}, then. Weighed fresh, {address}: {odds}.","A different dream, {address}, and a different wager: {work} is {odds}."],
}
const WEIGH_VERDICT_BARE:=[
	"Plainly, {address}? At this ambition it's {odds}.",
	"Put all that together and it's {odds}, {address}, and I'd still build it.",
]
const GATE_OPEN:={
	"design":[
		"The foundations of {work} are laid, {address}, and they're better than they had any right to be. Now: do we build what's sensible, or what's worth remembering?",
		"{oath} I've planned it two ways, {address}: one we can surely finish, and one far grander. You choose.",
	],
	"stores":[
		"The walls of {work} are rising, {address}, and the crews are hungry. There's grain in the stores that could buy us a season of hands.",
		"Feed a larger crew from the stores, {address}, and {work} goes up a whole stage faster.",
	],
	"labor":[
		"We're near the crown of {work}, {address}, and the heaviest lifting is still ahead. Who carries it: paid backs, forced backs, or willing ones?",
		"{oath} The last stones are the worst, {address}. I need hands, and I need to know how you mean to get them.",
	],
	"demand":[
		"I'll say it once, {address}: {work} should bear my mark, and the finest stone goes to the crown, not the gutters.",
		"I want my mark on {work}, {address}. I've given it years, and I think I've earned that.",
	],
	"_":["{gatetext}","A question for you, {address}, before another stone goes up: {gatetext}"],
}
const GATE_COURT:={
	"quartermaster":{"stores":["Pour the stores into that pit, {address}, and I'll be the one explaining to the children why supper's thin.","If the crews eat from the stores, {address}, we'll be short by late winter. I'll not pretend otherwise."],"design":["The grander design means more crews to feed for longer, {address}. Someone should say it before we start.","The plain design I can feed from what we have, {address}. The grand one I can't promise."],"_":["Whatever you choose comes out of the stores, {address}, and I'll have to find it."]},
	"marshal":{"design":["A bigger build pulls more people off the watch, {address}, and for longer.","Grand is well and good, {address}; I only ask that it can be held."],"labor":["Levy them and you'll get your crown, {address}, and a crowd with long memories on the other side of it.","Forced crews work fast, {address}, but they run off or turn on the overseers."],"_":["While the crews are hauling stone, {address}, the watch is short of hands."]},
	"steward":{"design":["The grander design takes more from the people, {address}, and they'll want to know why.","The plain design keeps the crews low and safe, {address}. The grand one will cost lives."],"labor":["The people will remember who carried those stones, {address}, and whether they were asked.","Pay them or ask them, {address}, but don't make them; our standing can't afford the whispers."],"demand":["Put a builder's mark above yours, {address}, and people will wonder who really leads.","Honour them, by all means, {address}, but carve your name bigger."],"_":["Whatever you choose, {address}, choose it where people can see you choosing."]},
	"scholar":{"design":["A grander design means methods we've barely tested, {address}. Glorious, if it holds.","The practical design we understand, {address}; the grander one we'd be learning on the way up."],"_":["I'd like the reasoning said aloud at council, {address}, whichever way this goes, so we learn from it."]},
	"any":{"design":["{oath} Grand or plain, {address}, just pick the one we can finish.","The builder wants it grand and the stores say plain, {address}. You'll have to disappoint one of them."],"stores":["If the stores go to the crews, {address}, our children go short this winter. Say that out loud if you choose it."],"labor":["However you get the hands, {address}, the people will remember how you got them."],"_":["Decide soon, {address}; the crews stand idle until you do.","{oath} Whatever you choose, {address}, tell the crews yourself; they'll take it better from you."]},
}
const ODDS_SHIFT:=[
	"As it stands, {address}, the court reckons it {odds}. {verdict}",
	"If you want the odds in plain words, {address}: {odds}. {verdict}",
]
const EVENT_OPEN:={
	"collapse":["{eventtext} I heard it go from across the yard, {address}; a sound I'll hear for the rest of my life.","{oath} Part of it came down, {address}. {eventtext} I'll not pretend it was the weather."],
	"accident":["{eventtext} I knew their names, {address}. Every one.","A hoist failed, {address}, and people died under it. {eventtext}"],
	"strike":["{eventtext} The crews have laid down their tools, {address}, and they're not wrong about everything.","The works are silent, {address}. {eventtext}"],
	"fire":["{eventtext} The scaffolds went up like kindling, {address}, and nobody saw who lit them.","We woke to smoke, {address}. {eventtext}"],
	"poaching":["{eventtext} Our master builder took their plans and their pride with them, {address}.","{oath} {eventtext} Somebody offered more than we did, {address}, and it wasn't only food."],
	"_":["{eventtext}"],
}
const OUTCOME_OPEN:={
	"shame":["It's down, {address}. {ruin}. I drew every line of it, so I'll not hide behind the stone.","{oath} I promised you a wonder and gave you a ruin, {address}. {eventtext}","I've no speech, {address}. {ruin} fell, and I was the one who said it would stand."],
	"defiance":["It fell, {address}. But I was right about the height and wrong about the ground, and that's a lesson, not a verdict.","{oath} Don't look at me like that, {address}. {ruin} was the boldest thing this people ever tried, and the ground failed it, not I.","Call it folly if you like, {address}. I know now where the ground is soft, and the next one won't fall."],
	"dead":["We lost {dead} when it came down, {address}. Say their names with me, at least.","{dead}. Those are the names, {address}. I'll carry them."],
	"abandoned":["We've laid down the tools at {work}, {address}. The walls stay half-high until someone takes the stone for something else.","{oath} So it ends half-built, {address}. All those seasons of work, and a heap to show for it."],
}
const OUTCOME_COURT:=[
	"I said it was folly, {address}. I said it in this very hall, and I'll say it again at every funeral.",
	"The families of the dead need food and help this winter, {address}. That comes before blame.",
	"The neighbours will have heard by now, {address}. Some will think us weak; I'd keep the watch strong.",
	"{oath} We reached too high, {address}. Next time we test the ground before we build.",
	"I'd have the ruin named and fenced, {address}, before it becomes a place children dare each other to climb.",
]
const NEWS_OPEN:=[
	"Word from the roads, {address}: {eventtext} I can't swear to every stone of it, but the shape is right.",
	"{oath} {civtwo} are building something, {address}. {eventtext}",
	"You'll want to hear this, {address}, and then you'll want to do something about it. {eventtext}",
]
const NEWS_COURT:=[
	"Let them build, {address}. It'll keep their crews off the border for years.",
	"Their people will be tired and hungry from building, {address}. Worth remembering if they threaten us.",
	"{oath} If {civtwo} can raise a wonder, {address}, so can we, if we plan it before they finish.",
	"Good for them, {address}. I'd send someone to see how they're managing it.",
]
const FORECAST_OPEN:=[
	"The light on the steps already shows it, {address}. {forecast}",
	"{oath} I read the light on the steps three mornings running, {address}, and it said the same thing each time. {forecast}",
	"I'd not bring you a guess, {address}. {forecast}",
]
const FORECAST_COURT:=[
	"Then we ration now, {address}, while the stores are still full enough to stretch.",
	"I'll start counting sacks tonight, {address}, so we know exactly what we have.",
	"If we ration and the year is good, we lose little, {address}. If we don't and it's bad, people starve.",
]
const BUILDER_REPLY:={
	"warm":["{oath} Say that again, {address}, slowly, so the stonecutters can carve it.","That's the sort of thing a builder remembers when the scaffolds sway, {address}."],
	"hostile":["Harsh, {address}, but I've built through worse than hard words.","I've heard that from people who never lifted a block, {address}."],
	"question":["A fair question, {address}. I won't know until we dig the footings.","I'll scratch it out in the dirt for you, {address}; it's easier to see than to say."],
	"neutral":["I'll take that as a yes with a warning, {address}.","Noted, {address}. I'll carve it somewhere nobody looks."],
}
const CLOSING_WORK:={
	"commission":["{oath} Then we begin at first light, {address}. Remember this day; {work} will.","You'll not regret it, {address}. Or if you do, you'll regret it magnificently."],
	"later":["Not yet, then, {address}. I'll keep the plans ready.","Then I'll wait, {address}, and I'll draw it better while I do."],
	"dismiss":["Folly, {address}? Then I'll keep working on it until you see it differently.","{oath} I'll take my picture home, {address}, and hang it where someone braver can see it."],
	"grander":["{oath} Grander it is! They'll see it from three valleys, {address}.","You won't be sorry, {address}. The stores will, but not you."],
	"practical":["Sensible, {address}. I'll build it well, and I'll dream the other one at night.","Practical. Very well, {address}. It'll stand, and the crews will come home."],
	"pour":["Fed crews, fast walls, {address}. The stores will remember this less fondly than I will.","{oath} Now we'll see some stone move, {address}."],
	"protect":["The stores stay shut, then, {address}. The walls will rise slower, and so will my temper.","As you say, {address}. The crews will be hungrier and slower, but the stores stay whole."],
	"paid":["Paid crews work carefully, {address}. You'll see it in the joins.","The crews will cheer your name tonight, {address}, and work harder for it tomorrow."],
	"levy":["It'll be fast, {address}. I'll not pretend it'll be loved.","Forced hands, then. I'll get your crown up, {address}, and you'll carry what comes with it."],
	"volunteers":["Willing backs, {address}. Slower, but they'll bring their children to see it.","Volunteers it is, {address}. Slower, but nobody will run off."],
	"honor":["{oath} My mark on it! I'll make it worth the honour, {address}.","You won't regret it, {address}. The crown will be the finest thing I ever cut."],
	"refuse":["No mark, then. Very well, {address}. I'll finish it, but don't expect me to like it.","{oath} Refused. I'll finish the work, {address}, but I'll remember the answer."],
	"honor_dead":["They'll be named at the works, {address}. The crews will see that.","That matters more than you know, {address}."],
	"press_on":["The work goes on, {address}. So will the whispering.","As you say. I'll tell the crews, {address}; you tell the widows."],
	"meet_demands":["The hammers start again at dawn, {address}.","Paid and back at it, {address}. Wise, and cheaper than a silent season."],
	"wait_out":["Then we wait, {address}, and the walls wait with us.","{oath} A silent yard and a stubborn court. Lovely."],
	"careful":["Slow and sound, {address}. The ground has made its point.","We'll rebuild carefully, {address}; this time I'll check the footings with my own hands."],
	"press":["Press it is, {address}. We'll outrun our bad luck or meet it head-on.","{oath} Then we climb faster, {address}, and pray the ground keeps up."],
	"mourn":["They'll be remembered, {address}, and so will you for remembering them.","Thank you, {address}. The ruin will have their names on it, at least."],
	"blame":["{oath} So it's mine to carry. I'll carry it, {address}, but I'll not carry it quietly.","Blame the builder. It's what builders are for, {address}, apparently."],
	"defy":["{oath} Another! Now that's a ruler, {address}.","Then the ruin showed us where the ground is soft, {address}. The next one stands."],
	"answer":["Then we answer them in stone, {address}. I'll start drawing tonight.","{oath} Let them look over their shoulders for once, {address}."],
	"decree":["I'll see the word gets round before the light changes, {address}.","Proclaimed. You'll thank the steps for this in the lean days, {address}."],
	"decree_gather":["Gatherers out by morning, {address}.","I'll send them with baskets and good boots, {address}."],
	"noted":["Noted, {address}. I'll keep watching.","As you say, {address}. I'll bring you the next word when it comes."],
	"acknowledge":["So be it, {address}.","As you say, {address}."],
	"settled":["Already settled? Then I'll get back to the stone, {address}.","Good. One less question between me and the crown, {address}."],
}
const DEDICATE_NARRATION:={
	"triumph":"Drums roll across {city}. The last scaffold falls away, and {work} stands in open light, greater than the drawings promised.",
	"success":"Drums roll across {city}. The scaffolds are down; {work} stands in open light, and the crowd goes quiet.",
	"flawed":"Drums roll across {city}. The scaffolds are down. {work} stands, a little crooked in places, and the crowd cheers anyway.",
}
const DEDICATE_ARCHITECT:={
	"triumph":["{oath} I drew it, {address}, and it still surprised me. Look at the light on it.","Every crack I feared never came, {address}. It stands better than I dreamed, and I dream large."],
	"success":["It stands, {address}. Every stone where I promised it would be, and one or two where I didn't.","I've built it, {address}. Now it belongs to everyone who'll ever stand in its shadow."],
	"flawed":["It isn't what I drew, {address}. It's what the ground and the seasons let us build, and it's still ours.","{oath} There's a lean in the east wall I'll dream about for years, {address}. But it stands."],
}
const DEDICATE_OFFICIAL:=[
	"{oath} Today nobody will ask me about the stores, {address}. Today they'll just look up.",
	"I argued against it, {address}. I was wrong, and I'll say so to anyone who asks.",
	"Every people we know will hear of {work} before the season turns, {address}.",
	"Look at their faces, {address}. That's what it was for.",
]
const DEDICATE_ENVOY_GIFT:=[
	"{civ} sends {gift} to honour {work}, and my own astonishment for free, {address}.",
	"{oath} We brought {gift}, {address}, and after seeing this I wish we'd brought more.",
	"Accept {gift} from {civ}, {address}, and my envy, which is heavier.",
]
const DEDICATE_ENVOY_PLAIN:=[
	"{civ} has nothing like it, {address}, and I'll be honest about that when I get home, mostly.",
	"{oath} I'll need a week to describe this properly to our people, {address}, and they'll still not believe me.",
	"We came to be polite, {address}. We'll leave having seen something.",
]
const NAMED_REACT:=[
	"{name}. {oath} It fits the stone, {address}.",
	"{name}. They'll say it in three languages by spring, {address}.",
	"{name}. Good. Now it can't be anyone else's, {address}.",
]

func _work_speaker_persona(audience:Dictionary)->Dictionary:
	if String(audience.get("kind","")) not in WORK_KINDS: return {}
	var speaker:Dictionary=audience.get("speaker",{})
	if int(speaker.get("person_id",0))>0: return {}
	var gw:Dictionary=audience.get("great_work",{}) if audience.get("great_work") is Dictionary else {}
	var figure_id:String=String(gw.get("architect_id",""))
	if figure_id.is_empty() and audience.get("wonder_proposal") is Dictionary: figure_id=String((audience.wonder_proposal as Dictionary).get("figure_id",""))
	var figure:Dictionary=HistoricalFigures.by_id(figure_id) if not figure_id.is_empty() else {}
	if figure.is_empty(): figure={"id":"builder:"+String(speaker.get("name","")),"name":String(speaker.get("name","The master builder")),"role":"Architect"}
	return CV.for_figure(figure,gw)

## The engine's spoken verdict without its narrator frame ("X says: ...") or
## the repeated chief worry, so a speaker can say it in their own mouth.
static func verdict_words(spoken:String)->String:
	var text:=spoken.strip_edges()
	var open_quote:=text.find("\"")
	var close_quote:=text.find("\"",open_quote+1) if open_quote>=0 else -1
	if open_quote>=0 and close_quote>open_quote:
		var quoted:=text.substr(open_quote+1,close_quote-open_quote-1).strip_edges()
		var tail:=text.substr(close_quote+1)
		var bold:=tail.find("An audacious design")
		return quoted+(" "+tail.substr(bold).strip_edges() if bold>=0 else "")
	return text

func _work_tokens(s:Dictionary)->Dictionary:
	var w:Dictionary=s.get("work",{})
	var raw:={
		"work":String(w.get("title",w.get("chosen",""))),"form":String(w.get("form","")).replace("_"," "),"purpose":_lower_initial(String(w.get("purpose",""))),
		"stage":String(w.get("stage_words","")).to_lower(),"odds":String(w.get("odds_in_words","")),"verdict":verdict_words(String(w.get("spoken_verdict",""))),
		"trigger":String(w.get("trigger","")),"ambition":String(w.get("ambition","")).to_lower(),"city":String(w.get("city",w.get("city_name",""))),
		"ruin":String(w.get("ruin_name","")),"eventtext":String(w.get("text","")),"gatetext":String(w.get("text","")),"forecast":String(w.get("text","")),
		"civtwo":String(w.get("civ_name","")),"style":String(w.get("style",""))}
	if float(w.get("progress",0))>0: raw["pct"]="%d" % roundi(float(w.get("progress",0))*100)
	var dead:Array=w.get("dead",[])
	if not dead.is_empty():
		var names:PackedStringArray=PackedStringArray()
		for person in dead: names.append(String(person))
		raw["dead"]=names[0] if names.size()==1 else ", ".join(names.slice(0,names.size()-1))+" and "+names[names.size()-1]
	if String(s.kind)=="wonder_proposal":
		var chosen:=String(w.get("chosen",""))
		var others:PackedStringArray=PackedStringArray()
		for concept in w.get("concepts",[]):
			if not concept is Dictionary: continue
			var concept_title:=String((concept as Dictionary).get("name",""))
			if concept_title==chosen:
				raw["form"]=String(concept.get("form","")).replace("_"," ")
				raw["purpose"]=_lower_initial(String(concept.get("purpose","")))
			elif not concept_title.is_empty(): others.append(concept_title)
		if not others.is_empty(): raw["others"]=" or ".join(others)
	var out:={}
	for key in raw:
		if not String(raw[key]).strip_edges().is_empty(): out[key]=String(raw[key]).strip_edges()
	return out

func _office_group(member:Dictionary)->String:
	var office:String=(String(member.persona.get("office_key",""))+" "+String(member.persona.get("title",""))).to_lower()
	for key in ["quartermaster","marshal","steward","scholar"]:
		if key in office: return key
	if "store" in office or "provision" in office or "supply" in office: return "quartermaster"
	if "watch" in office or "war" in office or "defense" in office: return "marshal"
	if "lore" in office or "record" in office or "inquiry" in office or "memory" in office: return "scholar"
	return "any"

const FACTOR_OFFICES:={"engineering":"scholar","materials":"quartermaster","cohesion":"steward","legitimacy":"steward","food":"quartermaster","war":"marshal","construction so far":"any"}

func _factor_office(factor:Dictionary)->String:
	var named:=String(factor.get("name","")).to_lower()
	if FACTOR_OFFICES.has(named): return String(FACTOR_OFFICES[named])
	var text:=(String(factor.get("name",""))+" "+String(factor.get("text",""))).to_lower()
	var table:=[["quartermaster",["stone","timber","clay","material","ore","brick","store","grain","cost","supply"]],["scholar",["know","discover","skill","craft","technique","vault","engineer","learn","method","architect"]],["marshal",["war","peace","security","enemy","raid","threat","army","frontier"]],["steward",["cohesion","legitimacy","food","hunger","support","people","stability","morale","famine","unrest"]]]
	for pair in table:
		for word in pair[1]:
			if String(word) in text: return String(pair[0])
	return "any"

func _speaker_for_office(s:Dictionary,office:String,used:Dictionary)->Dictionary:
	for member in s.officials:
		if _office_group(member)==office and not used.has(String(member.key)): return member
	for member in s.officials:
		if not used.has(String(member.key)): return member
	return {}

const ENGINEERING_WORDS:=[[.15,"our builders could raise this in their sleep, and their master knows it"],[0.0,"our builders can manage it, if the master keeps them honest"],[-.15,"this asks more of our builders than anything they have ever raised"],[-9.0,"nobody here has ever raised anything like it, and wishing won't teach them"]]

static func factor_effect(factor:Dictionary)->float:
	var effect:Variant=factor.get("effect",0.0)
	return float(effect) if (effect is float or effect is int) else 0.0

static func factor_words(factor:Dictionary)->String:
	## An engine factor in plain in-world words (never a number).
	var text:=String(factor.get("text","")).strip_edges()
	if String(factor.get("name","")).to_lower()=="engineering":
		var effect:Variant=factor.get("effect",0.0)
		var value:=float(effect) if (effect is float or effect is int) else (.1 if bool(factor.get("helps",false)) else -.1)
		for band in ENGINEERING_WORDS:
			if value>=float(band[0]): return String(band[1])+"."
	return text

func _factor_line(s:Dictionary,member:Dictionary,factor:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var text:=factor_words(factor)
	if text.is_empty(): return {}
	if not text.ends_with(".") and not text.ends_with("!") and not text.ends_with("?"): text+="."
	var office:=_factor_office(factor)
	var banks:Dictionary=WEIGH_OFFICE.get(office,WEIGH_OFFICE.any) if _office_group(member)==office else WEIGH_OFFICE.any
	var bank:Array=banks.help if bool(factor.get("helps",false)) else banks.hurt
	var used:Dictionary=_used.get(String(s.id),{})
	var fresh:Array=bank.filter(func(t:Variant)->bool:return not used.has(String(t)))
	if fresh.is_empty(): fresh=bank
	var template:String=String(fresh[rng.randi_range(0,fresh.size()-1)])
	used[template]=true
	_used[String(s.id)]=used
	var filled:=_fill(template.replace("{factor}","@@F@@"),_tokens(s,member,{})).replace("@@F@@",_lower_initial(text))
	return {"key":String(member.key),"text":CV.speak(member.persona,filled,rng,false,_flourish_memory(s,member),false),"aside":false}

## Officials voice assess() factors nearest their office; the speaker answers
## with the odds in words. Never a number.
func _work_weigh(s:Dictionary,rng:RandomNumberGenerator,with_narration:bool)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var w:Dictionary=s.get("work",{})
	var used:={}
	var hurts:Array=[]
	var helps:Array=[]
	var said:Dictionary=(_used.get(String(s.id),{}) as Dictionary).get("~factors",{})
	for factor in w.get("factors",[]):
		if not factor is Dictionary: continue
		var key:=factor_words(factor)
		if said.has(key): continue
		if bool((factor as Dictionary).get("helps",false)): helps.append(factor)
		else: hurts.append(factor)
	# The gravest doubts first.
	hurts.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return factor_effect(a)<factor_effect(b))
	var picks:Array=hurts.slice(0,2)
	picks.append_array(helps.slice(0,1))
	for factor in picks:
		var member:=_speaker_for_office(s,_factor_office(factor),used)
		if member.is_empty(): break
		used[String(member.key)]=true
		said[factor_words(factor)]=true
		_append_if(out,_factor_line(s,member,factor,rng))
	var scene_memory:Dictionary=_used.get(String(s.id),{})
	scene_memory["~factors"]=said
	_used[String(s.id)]=scene_memory
	if not String(w.get("odds_in_words","")).is_empty():
		var memory:Dictionary=_used.get(String(s.id),{})
		var last:Dictionary=memory.get("~weighed",{})
		var odds:=String(w.get("odds_in_words",""))
		var chosen:=String(w.get("chosen",w.get("title","")))
		if last.is_empty():
			_append_if(out,_say(s,s.envoy,WEIGH_VERDICT if not String(w.get("spoken_verdict","")).is_empty() else WEIGH_VERDICT_BARE,rng))
		else:
			var bank:Array=WEIGH_SHIFT.same
			if String(last.get("chosen",""))!=chosen: bank=WEIGH_SHIFT.other
			elif ODDS_ORDER.find(odds)>ODDS_ORDER.find(String(last.get("odds",""))): bank=WEIGH_SHIFT.better
			elif ODDS_ORDER.find(odds)<ODDS_ORDER.find(String(last.get("odds",""))): bank=WEIGH_SHIFT.worse
			_append_if(out,_say(s,s.envoy,bank,rng))
		memory["~weighed"]={"chosen":chosen,"odds":odds,"ambition":String(w.get("ambition",""))}
		_used[String(s.id)]=memory
	if with_narration and not out.is_empty() and String(s.kind)=="wonder_proposal":
		out.push_front({"key":"narrator","text":"The court weighs %s at %s ambition." % [String(w.get("chosen","the work")),String(w.get("ambition","grand"))],"aside":false})
	return out

func _work_open(s:Dictionary,rng:RandomNumberGenerator)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var w:Dictionary=s.get("work",{})
	var envoy:Dictionary=s.envoy
	var first:Dictionary=s.officials[0] if not s.officials.is_empty() else {}
	var tokens:Dictionary=s.get("gwtok",{})
	var mode:String=String(w.get("mode","")) if String(s.kind)=="great_work" else "proposal"
	var key:=String(w.get("key",""))
	var court_bank:Array=[]
	match mode:
		"proposal":
			if tokens.has("trigger"): _append_if(out,_say(s,envoy,PITCH_OPEN,rng,first))
			_append_if(out,_say(s,envoy,PITCH_CONCEPT if tokens.has("purpose") else PITCH_CONCEPT_NOPURPOSE,rng,first))
			if tokens.has("others"): _append_if(out,_say(s,envoy,PITCH_OTHERS,rng))
		"decision":
			_append_if(out,_say(s,envoy,GATE_OPEN.get(key,GATE_OPEN._),rng,first))
		"event":
			_append_if(out,_say(s,envoy,EVENT_OPEN.get(key,EVENT_OPEN._),rng,first))
		"outcome":
			if key=="abandoned": _append_if(out,_say(s,envoy,OUTCOME_OPEN.abandoned,rng))
			else:
				_append_if(out,_say(s,envoy,OUTCOME_OPEN.defiance if float(w.get("ego",.5))>.6 else OUTCOME_OPEN.shame,rng,first))
				if tokens.has("dead"): _append_if(out,_say(s,envoy,OUTCOME_OPEN.dead,rng))
			court_bank=OUTCOME_COURT
		"news":
			_append_if(out,_say(s,envoy,NEWS_OPEN,rng,first))
			court_bank=NEWS_COURT
		"forecast":
			_append_if(out,_say(s,envoy,FORECAST_OPEN,rng,first))
			court_bank=FORECAST_COURT
	if out.is_empty(): _append_if(out,{"key":"envoy","text":String(w.get("text","We must speak of the work.")),"aside":false})
	if s.officials.is_empty() or (mode=="outcome" and key=="abandoned"): return out
	var officials:Array=s.officials.duplicate()
	var shuffled:Array=[]
	while not officials.is_empty(): shuffled.append(officials.pop_at(rng.randi_range(0,officials.size()-1)))
	var count:int=clampi(rng.randi_range(2,3),1,shuffled.size())
	var previous:Dictionary={}
	for i in count:
		var member:Dictionary=shuffled[i]
		var line:Dictionary={}
		match mode:
			"proposal":
				var stance:=String(member.persona.get("stance","pragmatic"))
				var side:="glory" if stance in ["sycophantic","diplomatic"] or (stance=="principled" and rng.randf()<.5) else "folly"
				if i==1 and not previous.is_empty() and rng.randf()<.5: line=_say(s,member,COURT_BICKER,rng,previous)
				else: line=_say(s,member,PITCH_COURT[side],rng,previous)
			"decision":
				var banks:Dictionary=GATE_COURT.get(_office_group(member),GATE_COURT.any)
				line=_say(s,member,banks.get(key,banks.get("_",GATE_COURT.any._)),rng,previous,i==count-1 and rng.randf()<.4)
			_:
				line=_say(s,member,court_bank,rng,previous,i==count-1 and rng.randf()<.35)
		if line.is_empty(): line=_say(s,member,COURT_STANCE_COURT.get(String(member.persona.get("stance","pragmatic")),COURT_STANCE_COURT.pragmatic),rng,previous)
		_append_if(out,line)
		previous=member
	if mode=="proposal":
		out.append_array(_work_weigh(s,rng,false))
	elif mode=="decision" and tokens.has("odds"):
		_append_if(out,_say(s,envoy,ODDS_SHIFT,rng))
	return out

func _work_closing(s:Dictionary,result:Dictionary,rng:RandomNumberGenerator)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var option_id:String=String(result.get("option_id",(s.audience as Dictionary).get("option_id","")))
	var reaction:String=String(result.get("reaction","neutral"))
	var line:Dictionary={}
	if CLOSING_WORK.has(option_id): line=_say(s,s.envoy,CLOSING_WORK[option_id],rng)
	if line.is_empty(): line=_say(s,s.envoy,CLOSING_WORK.acknowledge,rng)
	_append_if(out,line)
	if not s.officials.is_empty():
		var member:Dictionary=s.officials[rng.randi_range(0,s.officials.size()-1)]
		var group:="warm" if reaction in ["delighted","pleased"] else ("hostile" if reaction in ["offended","furious"] else "neutral")
		_append_if(out,_say(s,member,CLOSING_ASIDE[group],rng,{},true))
	return out

func _work_scene_words(s:Dictionary)->String:
	var w:Dictionary=s.get("work",{})
	if String(s.kind)=="wonder_proposal":
		return "A WONDER IS PITCHED. The speaker urges the ruler to raise a great work conceived from who this people is. Why now: %s. The concepts (name, form, purpose, lore): %s. The ruler is weighing '%s' at %s ambition in %s; the court's reckoning is '%s'. Feasibility factors (use their words, never numbers): %s. %s" % [String(w.get("trigger","")),JSON.stringify(w.get("concepts",[])),String(w.get("chosen","")),String(w.get("ambition","grand")),String(w.get("city","")),String(w.get("odds_in_words","")),JSON.stringify(w.get("factors",[])),String(w.get("spoken_verdict",""))]
	match String(w.get("mode","")):
		"decision": return "A STAGE GATE on the great work '%s' (%s, stage %s, %s%% raised). The master builder brings the question: %s The court's reckoning of its odds now: '%s'. %s" % [String(w.get("title","")),String(w.get("form","")),String(w.get("stage_words","")),str(w.get("progress_percent",0)),String(w.get("text","")),String(w.get("odds_in_words","unknown")),String(w.get("spoken_verdict",""))]
		"event": return "HARD NEWS from the works of '%s': %s" % [String(w.get("title","")),String(w.get("text",""))]
		"outcome":
			if String(w.get("key",""))=="abandoned": return "The great work '%s' has been ABANDONED: %s" % [String(w.get("title","")),String(w.get("text",""))]
			return "The great work '%s' has COLLAPSED into a ruin now called '%s'. %s The dead (names exactly as given, possibly none): %s. The master builder faces the court: shame or defiance by their temperament; officials trade recriminations." % [String(w.get("title","")),String(w.get("ruin_name","")),String(w.get("text","")),JSON.stringify(w.get("dead",[]))]
		"news": return "NEWS OF ANOTHER PEOPLE'S WORK (dated, uncertain): %s" % String(w.get("text",""))
		"forecast": return "A WARNING from the Watching Sky: %s" % String(w.get("text",""))
	return ""

func _work_want(s:Dictionary)->String:
	var w:Dictionary=s.get("work",{})
	if String(s.kind)=="wonder_proposal": return "to have the ruler commission their vision, at the boldest ambition they can get away with"
	match String(w.get("mode","")):
		"decision": return "the answer that lets the work be as great as they imagine, and credit for it"
		"outcome": return "to be forgiven, or to be proven right after all" if float(w.get("ego",.5))>.6 else "to be forgiven, and for the dead to be honoured"
		"event": return "the ruler's help to keep the work alive"
		"news": return "for the ruler to answer the other people's work with one of our own"
		"forecast": return "for the warning to be heeded before it is too late"
	return "to be heard"

func _work_open_instruction(s:Dictionary)->String:
	if String(s.kind)=="wonder_proposal":
		return "'envoy' pitches the wonder with passion and a little vanity, in their dialect: why now, then the chosen concept by name, form and purpose, and a glance at the others. Officials argue glory against folly; then 1 to 2 officials voice the feasibility factors nearest their office, in plain in-world words and never as a number."
	var w:Dictionary=s.get("work",{})
	if String(w.get("mode",""))=="outcome" and String(w.get("key",""))!="abandoned": return "'envoy' is the master builder facing the ruler after the collapse: shame or defiance by temperament, naming the dead exactly as given if any. Officials trade recriminations and one proposes what to do with the ruin."
	if String(w.get("mode",""))=="decision": return "'envoy' is the master builder: they bring the stage-gate question in their own voice. Officials argue it from their office (stores, labor levies, legitimacy), and someone says how the odds of the work are shifting, in words, never numbers."
	return "'envoy' brings the matter in their own voice; officials react from their office."

# ---------------------------------------------------------------------------
# Dedication ceremony speeches (not an audience; the ceremony modal shows them)
# ctx: {key, title, lore, city_name, outcome:"triumph"|"success"|"flawed",
#       architect:{id,name,style,vision,ego,temperament}, official:{person},
#       attendees:[{civ_id,name,gift:{resource,amount}}]}
# Lines: {speaker, role:"narrator"|"architect"|"official"|"envoy", title,
#         civ_id, person_id, figure_id, text}
# ---------------------------------------------------------------------------

signal ceremony_ready(key:String,lines:Array)

func _ceremony_cast(ctx:Dictionary)->Array[Dictionary]:
	var cast:Array[Dictionary]=[]
	var architect:Dictionary=ctx.get("architect",{}) if ctx.get("architect") is Dictionary else {}
	if not String(architect.get("name","")).is_empty():
		var figure:Dictionary=HistoricalFigures.by_id(String(architect.get("id","")))
		if figure.is_empty(): figure={"id":"builder:"+String(architect.name),"name":String(architect.name),"role":"Architect"}
		var persona:=CV.for_figure(figure,architect)
		cast.append({"key":"architect","role":"architect","name":String(persona.name),"title":"Master Builder","persona":persona,"person_id":0,"civ_id":"player","figure_id":String(figure.get("id",""))})
	var official:Dictionary=ctx.get("official",{}) if ctx.get("official") is Dictionary else {}
	if not official.is_empty():
		var official_persona:=CV.for_person(official)
		cast.append({"key":"official","role":"official","name":String(official_persona.name),"title":String(official_persona.get("title","")),"persona":official_persona,"person_id":int(official.get("person_id",0)),"civ_id":"player"})
	var index:=0
	for attendee in ctx.get("attendees",[]):
		if not attendee is Dictionary: continue
		var civ_id:=String((attendee as Dictionary).get("civ_id",""))
		var envoy_persona:=CV.for_envoy(civ_id,"dedication:%s:%d" % [String(ctx.get("key","")),index])
		var gift:Dictionary=attendee.get("gift",{}) if attendee.get("gift") is Dictionary else {}
		var gift_text:=""
		if not gift.is_empty() and float(gift.get("amount",0))>0: gift_text="%d %s" % [roundi(float(gift.get("amount",0))),String(gift.get("resource","")).to_lower()]
		cast.append({"key":"envoy_%d" % index,"role":"envoy","name":String(envoy_persona.name),"title":"Envoy of %s" % String(attendee.get("name","")),"persona":envoy_persona,"person_id":0,"civ_id":civ_id,"civ":String(attendee.get("name","")),"gift":gift_text})
		index+=1
		if index>=4: break
	return cast

func _ceremony_scene(ctx:Dictionary,member:Dictionary)->Dictionary:
	## A small scene record so the offline bank machinery (_say) can be reused.
	var tokens:={"work":String(ctx.get("title","")),"city":String(ctx.get("city_name",""))}
	if not String(member.get("gift","")).is_empty(): tokens["gift"]=String(member.gift)
	if ctx.has("name"): tokens["name"]=String(ctx.name)
	return {"id":"ceremony:"+String(ctx.get("key","")),"audience":{"lines":[]},"kind":"ceremony","origin":"court","envoy":member,"officials":[],
		"civ":String(member.get("civ",ctx.get("city_name",""))),"leader":"","res":"","amt":"","fact":"","subject":"","summary":"","decree":"","topic":"","gwtok":tokens}

func _ceremony_line(member:Dictionary,text:String)->Dictionary:
	return {"speaker":String(member.get("name","")),"role":String(member.get("role","narrator")),"title":String(member.get("title","")),"civ_id":String(member.get("civ_id","")),"person_id":int(member.get("person_id",0)),"figure_id":String(member.get("figure_id","")),"text":text}

func ceremony_offline(ctx:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|ceremony|%s" % [int(GameState.world_seed),String(ctx.get("key",""))])
	var outcome:=String(ctx.get("outcome","success"))
	if not DEDICATE_NARRATION.has(outcome): outcome="success"
	var narration:=String(DEDICATE_NARRATION[outcome]).replace("{city}",String(ctx.get("city_name","the city"))).replace("{work}",String(ctx.get("title","the work")))
	out.append({"speaker":"","role":"narrator","title":"","civ_id":"","person_id":0,"figure_id":"","text":narration})
	for member in _ceremony_cast(ctx):
		var bank:Array=[]
		match String(member.role):
			"architect": bank=DEDICATE_ARCHITECT[outcome]
			"official": bank=DEDICATE_OFFICIAL
			"envoy": bank=DEDICATE_ENVOY_GIFT if not String(member.get("gift","")).is_empty() else DEDICATE_ENVOY_PLAIN
		var said:=_say(_ceremony_scene(ctx,member),member,bank,rng)
		if not said.is_empty(): out.append(_ceremony_line(member,String(said.text)))
	return out

## Drops any line already spoken in this ceremony (same scene memory as _say).
func _unrepeated(ctx:Dictionary,lines:Array[Dictionary])->Array[Dictionary]:
	var scene_key:="ceremony:"+String(ctx.get("key",""))
	var memory:Dictionary=_used.get(scene_key,{})
	var said:Dictionary=memory.get("~lines",{})
	var out:Array[Dictionary]=[]
	for line in lines:
		var text:=String(line.get("text","")).strip_edges().to_lower()
		if said.has(text): continue
		said[text]=true
		out.append(line)
	memory["~lines"]=said
	_used[scene_key]=memory
	return out

func ceremony_named_offline(ctx:Dictionary,title:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|named|%s|%s" % [int(GameState.world_seed),String(ctx.get("key","")),title])
	var named:=ctx.duplicate(true)
	named["name"]=title
	var cast:=_ceremony_cast(ctx)
	var picks:Array=[]
	for member in cast:
		if String(member.role)=="architect": picks.append(member)
	for member in cast:
		if String(member.role)=="envoy":
			picks.append(member)
			break
	if picks.is_empty() and not cast.is_empty(): picks.append(cast[0])
	for member in picks:
		var said:=_say(_ceremony_scene(named,member),member,NAMED_REACT,rng)
		if not said.is_empty(): out.append(_ceremony_line(member,String(said.text)))
	return out

## Speeches for a dedication: emits ceremony_ready(ctx.key, lines). Live voice
## when configured; offline banks otherwise or on any failure.
func ceremony_speeches(ctx:Dictionary)->void:
	var key:=String(ctx.get("key",""))
	var fallback:=_unrepeated(ctx,ceremony_offline(ctx))
	var config:=_config()
	if config.is_empty() or _ceremony_cast(ctx).is_empty():
		ceremony_ready.emit.call_deferred(key,fallback)
		return
	_ceremony_request(key,ctx,config,fallback,"Open the dedication: the master builder speaks first (what it cost, what it means), then the court official, then EACH foreign envoy in turn, in their own dialect, one or two sentences each; envoys mention their gift exactly as given if they brought one. Awe, rivalry and pride should leak through. 3 to 7 lines.")

## Reactions once the ruler names the work: emits ceremony_ready(ctx.key+":named", lines).
func ceremony_named(ctx:Dictionary,title:String)->void:
	var key:=String(ctx.get("key",""))+":named"
	var fallback:=_unrepeated(ctx,ceremony_named_offline(ctx,title))
	var config:=_config()
	if config.is_empty():
		ceremony_ready.emit.call_deferred(key,fallback)
		return
	var named:=ctx.duplicate(true)
	named["name"]=title
	_ceremony_request(key,named,config,fallback,"The ruler has just named the work \"%s\". The master builder and one envoy react to the name, one short line each. 2 lines." % title)

func _ceremony_request(key:String,ctx:Dictionary,config:Dictionary,fallback:Array[Dictionary],instruction:String)->void:
	if send_hook.is_valid():
		ceremony_ready.emit.call_deferred(key,fallback)
		return
	var cast:=_ceremony_cast(ctx)
	var keys:Array[String]=[]
	var cast_lines:PackedStringArray=PackedStringArray()
	for member in cast:
		keys.append(String(member.key))
		cast_lines.append("- %s = %s%s" % [String(member.key),CV.brief(member.persona),(" | brings %s" % String(member.gift)) if not String(member.get("gift","")).is_empty() else ""])
	var facts:=ctx.duplicate(true)
	facts.erase("official")
	facts.erase("key")
	var prompt:="SCENE: The DEDICATION of a great work before the people and foreign envoys.\n\nFACTS YOU MAY USE (nothing else is true): %s\n\nCAST (speaker_key = character; use no one else):\n%s\n\nNOW: %s mood_shift 0." % [JSON.stringify(facts).substr(0,2400),"\n".join(cast_lines),instruction]
	var payload:={"model":String(config.get("model","")),"max_completion_tokens":MAX_COMPLETION_TOKENS,"messages":[{"role":"system","content":SYSTEM_PROMPT.replace("royal audience hall","royal dedication ceremony")},{"role":"user","content":prompt}]}
	if bool(config.get("structured_output",false)): payload["response_format"]=response_format(keys)
	var headers:=PackedStringArray(["Content-Type: application/json","Authorization: Bearer %s" % String(config.get("api_key","")),"X-Client-Request-Id: ceremony-%d" % Time.get_ticks_msec()])
	var http:=HTTPRequest.new()
	add_child(http)
	http.timeout=API_TIMEOUT_SECONDS
	http.max_redirects=0
	http.body_size_limit=MAX_RESPONSE_BYTES
	http.request_completed.connect(_on_ceremony_response.bind(key,http,cast,ctx,fallback))
	if http.request(String(config.get("endpoint","")),headers,HTTPClient.METHOD_POST,JSON.stringify(payload))!=OK:
		http.queue_free()
		ceremony_ready.emit.call_deferred(key,fallback)

func _on_ceremony_response(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray,key:String,http:HTTPRequest,cast:Array[Dictionary],ctx:Dictionary,fallback:Array[Dictionary])->void:
	if is_instance_valid(http): http.queue_free()
	var lines:Array[Dictionary]=[]
	if result==HTTPRequest.RESULT_SUCCESS and code>=200 and code<300:
		var parsed:=parse_body(body)
		lines=_validate_ceremony(parsed.get("lines",[]),cast,ctx)
	if lines.size()<2:
		ceremony_ready.emit(key,fallback)
		return
	if not fallback.is_empty() and String(fallback[0].get("role",""))=="narrator": lines.push_front(fallback[0])
	ceremony_ready.emit(key,_unrepeated(ctx,lines))

func _validate_ceremony(raw:Array,cast:Array[Dictionary],ctx:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var meta:=RegEx.new()
	meta.compile(META_PATTERN)
	var number:=RegEx.new()
	number.compile("\\d+(?:\\.\\d+)?")
	var allowed:={}
	for m in number.search_all(JSON.stringify(ctx)): allowed[m.get_string()]=true
	for item in raw:
		if out.size()>=8: break
		if not item is Dictionary: continue
		var member:={}
		for candidate in cast:
			if String(candidate.key)==String((item as Dictionary).get("speaker_key","")): member=candidate
		if member.is_empty(): continue
		var text:=Plain.strip(_clean_text(String((item as Dictionary).get("text","")),member))
		if text.is_empty() or meta.search(text)!=null: continue
		var invented:=false
		for m in number.search_all(text):
			if not allowed.has(m.get_string()): invented=true
		if invented: continue
		out.append(_ceremony_line(member,text))
	return out
