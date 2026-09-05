class_name HistoricalNameGenerator
extends RefCounted

# Fictional regional traditions, not an exhaustive historical-language model.
const POOLS := {
	"Riverlands": {"women": ["Alice", "Eleanor", "Matilda", "Edith", "Isabel", "Joan", "Margaret", "Agnes", "Beatrice", "Cecilia", "Emma", "Rose"], "men": ["William", "Robert", "Thomas", "Edward", "Henry", "Hugh", "Walter", "Richard", "Simon", "Edmund", "Roger", "Nicholas"], "families": ["Bennett", "Fletcher", "Turner", "Cooper", "Ward", "Clarke", "Baker", "Carter", "Mason", "Reed", "Wood", "Wright", "Hill", "Shaw", "Webb", "Hunt"]},
	"Highlands": {"women": ["Moira", "Fiona", "Eileen", "Iona", "Elspeth", "Flora", "Catriona", "Una", "Isobel", "Kirsten", "Mairi", "Aileen"], "men": ["Alasdair", "Ewan", "Duncan", "Malcolm", "Fergus", "Iain", "Callum", "Niall", "Angus", "Ruairidh", "Lachlan", "Finlay"], "families": ["Cameron", "Campbell", "Fraser", "Grant", "Gordon", "Graham", "MacLeod", "MacKay", "Munro", "Ross", "Sinclair", "Stewart", "Murray", "Drummond", "Douglas", "Bruce"]},
	"Plateau": {"women": ["Shirin", "Parisa", "Darya", "Nasrin", "Laleh", "Mina", "Soraya", "Azar", "Neda", "Roya", "Simin", "Farah"], "men": ["Arman", "Bahram", "Darius", "Farid", "Kamran", "Nader", "Navid", "Omid", "Reza", "Rostam", "Shahin", "Kaveh"], "families": ["Mehrani", "Farhadi", "Nouri", "Azadi", "Rahimi", "Karimi", "Darvishi", "Shirazi", "Tabrizi", "Kermani", "Yazdi", "Sadeghi", "Jafari", "Bahrami", "Rostami", "Farzan"]},
	"Eastern Valleys": {"women": ["Mei", "Lan", "Hua", "Lian", "Yun", "Xia", "Lin", "Yue", "Ning", "Yan", "Qiu", "Fang"], "men": ["Wei", "Jun", "Ming", "Tao", "Jian", "Wen", "Hao", "Liang", "Peng", "Bo", "Lei", "Hong"], "families": ["Zhao", "Qian", "Sun", "Li", "Zhou", "Wu", "Zheng", "Wang", "Feng", "Chen", "Chu", "Xu", "He", "Lu", "Shi", "Zhang"]},
}
const ORIGINS := ["the river crossing","the eastern orchards","the old quarry","the coastal terraces","the upper valley","the reed marshes","the western pasture","the stone bridge","the hill settlement","the market road","the lakeside","the southern fields","the harbor","the upland farms","the border village","the forest edge"]

static func make(seed_value:int,serial:int,woman:bool,tradition:String,used:Dictionary)->Dictionary:
	var pool:Dictionary=POOLS.get(tradition,POOLS.Riverlands)
	var given:Array=pool.women if woman else pool.men
	var total:int=given.size()*pool.families.size()
	var start:=posmod(hash("%d:%d" % [seed_value,serial]),total)
	for offset in total:
		var index:=(start+offset)%total
		var first:=String(given[index%given.size()])
		var family:=String(pool.families[index/given.size()])
		var full:=family+" "+first if tradition=="Eastern Valleys" else first+" "+family
		if not used.has(full): return {"name":full,"given":first,"family":family,"tradition":tradition}
	return {}
