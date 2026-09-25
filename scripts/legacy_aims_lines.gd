extends RefCounted
## Offline words for legacy_aims.gd: how the court urges an aim, how the people
## at the fires put one, and how the court takes its fulfilment or failure.
## Every line is original, short, and era-safe for a stone-age band (the
## character_voice.gd era gate still filters each one). URGE is keyed by the
## speaker's lifelong manner (character_voice.gd VOICE_MODELS); GENERIC covers
## anyone else.
##
## Tokens: {aim} what the aim asks, as a verb phrase ("see our hearths hold
## 130 souls"); {why} the real reason, one sentence; {years} a span in winters
## ("twelve winters"); {name} the aim's short title; {legacy} the name it
## leaves behind; {dead} a remembered name.

const URGE:={
	"ahab":["{why} Give me this and I will run it down: let us {aim} before {years} are gone.","{why} There is our quarry. We {aim}, and we do not turn back for {years}."],
	"judge":["{why} Consider it carefully. I would have us {aim} within {years}.","{why} Observe how small we are. Let us {aim}; {years} is time enough."],
	"atticus":["{why} It seems to me the fair thing, and the right one, is to {aim}. {years}, I'd say.","{why} I'd ask plainly that we {aim}, and give ourselves {years} to do it."],
	"lincoln":["{why} So here's a plain job for plain folk: {aim}. Give it {years}.","{why} I'd put it this way. Let's {aim}, and take {years} over it if we must."],
	"grant":["{why} We should {aim}. {years}. I will see it done.","{why} The task is to {aim}. {years} is enough."],
	"falstaff":["{why} Now here is a thing worth a song, and a feast after: we {aim}! {years}, and not a day longer, or throw me in the river.","{why} Let us {aim}. {years}, friends. What's a vow without a feast to swear it on?"],
	"aurelius":["{why} We cannot stop bad years coming, but we can choose what we work for. Let it be to {aim}, over {years}.","{why} Let us {aim}, and do it patiently; {years} is not long for something our grandchildren will still see."],
	"iago":["{why} I only say what the others think and will not say. We should {aim}. {years}, and they will thank us.","{why} Some will call it too much. I say we {aim}, and let {years} prove who was right."],
	"elizabeth":["{why} I would have us {aim}, and say so before all. {years}. We shall not be seen to falter.","{why} Let it be known at every fire: we {aim}, within {years}."],
	"achilles":["{why} Let us {aim}, so that our names outlast us. {years}, no more.","{why} I want a thing worth a life. We {aim}. {years}."],
	"sancho":["{why} It's a lot, but we can start small. Let's {aim}, and give it {years}.","{why} I'm a simple sort, but it seems to me we could {aim}. {years}, give or take a bad winter."],
	"polonius":["{why} Now, briefly, and I will be brief: we should {aim}, and give it {years}, which is neither too long nor, I think, too short.","{why} I have thought on it at length, and briefly: let us {aim}. {years}, I would counsel."],
	"cicero":["{why} Our grandchildren will live with whatever we do now. Let us {aim}, within {years}.","{why} I put it to you: we must {aim}. {years}. Who here would say otherwise?"],
	"lear":["{why} I am old, and I want to see one great thing before the dark. Let us {aim}. {years}.","{why} Let us {aim}. Give me {years}, and let them say we were more than we seemed."],
	"churchill":["{why} We shall {aim}. It will take {years}, and it will be hard, and we shall do it.","{why} Let every hearth know it: we {aim}, and we shall not flag in {years}."],
}
const GENERIC:=["{why} I would have us {aim} within {years}.","{why} Let us {aim}. {years} should be enough.","{why} It is time we {aim}. Give it {years}."]

## How the people put an aim, told by the narrator.
const PEOPLE:=["[At the fires they are saying it among themselves: {why_low} They want to {aim}.]","[The talk at every hearth comes to the same thing. {why} They would {aim}.]","[The old ones and the young agree, for once. {why} They ask to {aim}.]"]

## The court's aside when an aim is taken up.
const TAKEN:=["Then it is said. I'll tell the others tonight.","The whole camp will know by dark.","Good. Now people have something to work toward.","They'll be telling it at the fires tonight."]

## The court's words over a fulfilled or failed aim, for the Chronicle.
const FULFIL:=["It was done. {name}: they will call it {legacy}, and they will say it at the fires when we are gone.","{name}, done at last. The children who were small when it was sworn will tell it as {legacy}."]
const FAIL:=["{name} was not done, and the people grieve it. Some whisper that the god's eye has turned from us.","The winters ran out before {name} was done. There is grief at the fires, and a little fear."]
const RELEASE:=["{name} is set down. No one says it aloud, but there is sorrow in it.","The people let {name} go. They are quieter for a while."]

## Milestones, in the people's words.
const MILESTONE:={
	25:["{name}: a quarter of the way. The people are talking about it.","{name} has begun to show. People point at it."],
	50:["{name}: halfway. Even the ones who said it could not be done have gone quiet.","{name} is half done. People stop to look at it on their way past."],
	75:["{name} is nearly done. The children are already telling it.","{name}: only a little way left now."],
}

## Number words for the stone age: small numbers are said, not written.
const NUMBER_WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty"]
