class_name HistoricalNameGenerator
extends RefCounted

# Fictional regional traditions, not an exhaustive historical-language model.
# Invented names only (alternative history: real history is calibration, never
# a source of names). Each tradition shares one sound palette with era_names.gd.
const POOLS := {
	"Riverlands": {"women": ["Cendra","Fenna","Morwe","Liseth","Brynne","Oriel","Thessa","Caelin","Merra","Evra","Sirra","Dalla"], "men": ["Corvan","Tebb","Hollin","Mardo","Brannoc","Fenwic","Garth","Radd","Tollan","Evrin","Kerrin","Dunnor"], "families": ["Reedwater","Ford","Ashbank","Longmeadow","Saltspring","Hollowhill","Redcliff","Stonewash","Birchstand","Deepwell","Otterpool","Windgap","Twinoak","Mossbrook","Whitestone","Fernside"]},
	"Highlands": {"women": ["Karsa","Vilka","Torra","Hesk","Ghia","Jora","Maren","Skai","Drenna","Ilke","Brisa","Kolla"], "men": ["Grom","Hask","Torv","Brek","Dask","Hobb","Ulf","Kjal","Rovik","Stav","Gunn","Oskel"], "families": ["Highcamp","Crowfield","Lakeshore","Thornbrake","Stonehand","Longstride","Owlsight","Keeneye","Swiftfoot","Fairhand","Fullbasket","Polesetter","Nightwatch","Softvoice","Greyeyes","Tallgrass"]},
	"Plateau": {"women": ["Aluna","Imeri","Sorava","Telani","Eshki","Namira","Ovea","Qira","Saoli","Yenna","Ilisa","Merai"], "men": ["Tomaq","Idrin","Kavu","Orun","Belem","Sadu","Ekkan","Anzu","Rimo","Tahun","Oskan","Mahun"], "families": ["Sandwell","Dunmere","Ashvale","Redmesa","Stonecrest","Highwell","Saltmere","Drywash","Palmreach","Windmesa","Cliffhold","Sunmere","Dustford","Claybank","Goldwash","Rimwell"]},
	"Eastern Valleys": {"women": ["Yelu","Soma","Pashi","Inni","Tavi","Rella","Anoka","Wisa","Hoya","Emu","Kallu","Nisa"], "men": ["Tahu","Pemo","Kanu","Iwo","Rahu","Sokko","Mato","Lenu","Wiru","Hanu","Olo","Tepa"], "families": ["Mistvale","Pinebrook","Reedmere","Cloudford","Jadewell","Canegrove","Riverbend","Terrace","Hillmist","Lotuspool","Stonebridge","Willowbank","Rainford","Cedarhill","Fogmere","Lanternford"]},
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
