extends RefCounted
## THE YEARS AS THE CHRONICLE PAGE SHOWS THEM (hud/chronicle_feed.gd): one
## record per year, oldest first, built from the Chronicle itself
## (GameState.chronicle): each closed year's kept record and entry
## (chronicle_annals.gd), the year in progress from its accumulator, and every
## told entry filed under the year it happened. Pure over the dictionary it is
## given; nothing here is saved.
##
## A record: {y (0-based), n (the year's number), closed, name ("" for a year
## the people did not name), glyph (its mark), pop, dpop (null when unknown),
## born, buried (-1 when unknown), learned, deaths (to its troubles),
## troubles [{name, type}], dry, mild, lost, heads, kept, unmet, met, works,
## turns, km, text (its entry), age {title, text} (a generation's account),
## story [entries oldest first], tallies [season lines oldest first]}.

const Annals:=preload("res://scripts/chronicle_annals.gd")


static func build(c:Dictionary,today:int,pop_now:int=-1)->Array:
	var entries:Array=c.get("entries",[]) if c.get("entries") is Array else []
	var annals:Array=c.get("annals",[]) if c.get("annals") is Array else []
	var filed:={}
	# Entries are newest first; each year's are kept oldest first.
	for i in range(entries.size()-1,-1,-1):
		var e:Variant=entries[i]
		if not e is Dictionary:continue
		var entry:Dictionary=e
		var key:=String(entry.get("key",""))
		var y:=maxi(0,int(entry.get("day",0)))/365
		var slot:Dictionary=filed.get(y,{})
		if slot.is_empty():
			slot={"story":[],"tallies":[],"annal":{},"age":{}}
			filed[y]=slot
		if key.begins_with("annal:"):slot.annal=entry
		elif key.begins_with("age:"):slot.age=entry
		elif String(entry.get("tier",""))=="whisper":(slot.tallies as Array).append(entry)
		else:(slot.story as Array).append(entry)
	var now_y:=maxi(0,today)/365
	var years:Array=[]
	var shown_names:Array=[]
	var last_pop:=-1
	var first_y:=now_y
	for m in annals:
		if m is Dictionary:first_y=mini(first_y,int((m as Dictionary).get("y",now_y)))
	for y in filed:first_y=mini(first_y,int(y))
	var by_y:={}
	for m in annals:
		if m is Dictionary:by_y[int((m as Dictionary).get("y",-1))]=m
	for y in range(first_y,now_y+1):
		var slot:Dictionary=filed.get(y,{"story":[],"tallies":[],"annal":{},"age":{}})
		var record:Dictionary
		if by_y.has(y):
			record=_closed(by_y[y],slot,shown_names)
		elif y==now_y:
			record=_current(c,y,slot,annals,pop_now)
		elif not (slot.story as Array).is_empty() or not (slot.annal as Dictionary).is_empty():
			# A year before the annals began (an older save): only its entries.
			record=_bare(y,slot)
		else:
			continue
		var pop:=int(record.get("pop",-1))
		record["dpop"]=pop-last_pop if pop>0 and last_pop>0 else null
		if pop>0:last_pop=pop
		years.append(record)
	return years


static func _base(y:int,slot:Dictionary)->Dictionary:
	return {"y":y,"n":y+1,"closed":true,"name":"","glyph":"quiet","pop":-1,"born":-1,"buried":-1,"learned":0,"deaths":0,"troubles":[],"dry":0,"mild":0,"routine":0,
		"lost":[],"heads":[],"kept":[],"unmet":[],"met":[],"works":[],"turns":[],"km":0,"text":String((slot.annal as Dictionary).get("text","")),
		"title":String((slot.annal as Dictionary).get("title","")),"age":_age(slot.age),"story":slot.story,"tallies":slot.tallies}


static func _age(entry:Dictionary)->Dictionary:
	if entry.is_empty():return {}
	return {"title":String(entry.get("title","")),"text":String(entry.get("text",""))}


static func _closed(m:Dictionary,slot:Dictionary,shown_names:Array)->Dictionary:
	var r:=_base(int(m.get("y",0)),slot)
	var name:=_recounted(Annals.display_name(m),m,shown_names)
	if name!="":shown_names.append(name)
	r.name=name
	r.glyph=Annals.glyph_of(m)
	r.pop=int(m.get("pop",-1))
	r.born=int(m.get("born",-1))
	r.buried=int(m.get("buried",-1))
	r.learned=int(m.get("learned",0))
	r.deaths=int(m.get("deaths",0))
	r.km=int(m.get("km",0))
	r.dry=int(m.get("dry",0))
	r.mild=int(m.get("mild",0))
	r.routine=int(m.get("routine",0))
	var troubles:Array=[]
	var types:Array=m.get("types",[]) if m.get("types") is Array else []
	var kinds:Array=m.get("kinds",[]) if m.get("kinds") is Array else []
	for i in kinds.size():
		var words:=String(kinds[i])
		troubles.append({"name":words,"type":String(types[i]) if i<types.size() else Annals._type_of_words(words)})
	r.troubles=troubles
	for field in ["lost","heads","kept","unmet","met","works","turns"]:
		if m.get(field) is Array:r[field]=(m[field] as Array).duplicate()
	return r


## Years closed before the naming rule changed counted every trouble of a
## kind ("the third Dry Year"). A deadly trouble's count is taken again among
## the names still shown.
static func _recounted(name:String,m:Dictionary,shown:Array)->String:
	var re:=RegEx.create_from_string("^the (second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|eleventh|twelfth) (.+)$")
	var counted:=re.search(name)
	if counted==null or name.begins_with("the year"):return name
	if not Annals._trouble_name(name,m):return name
	var base:=counted.get_string(2)
	var seen:=0
	for old in shown:
		var o:=String(old)
		if o=="the "+base or o.ends_with(" "+base):seen+=1
	if seen>0 and seen+1<Annals.ORDINALS.size():return "the %s %s" % [Annals.ORDINALS[seen+1],base]
	return "the "+base


static func _bare(y:int,slot:Dictionary)->Dictionary:
	var r:=_base(y,slot)
	r.name=""
	r.glyph=_glyph_from_story(slot.story)
	return r


## The year in progress, from its accumulator: what it has brought so far.
static func _current(c:Dictionary,y:int,slot:Dictionary,annals:Array,pop_now:int)->Dictionary:
	var r:=_base(y,slot)
	r.closed=false
	var a:Dictionary=c.get("year_acc",{}) if c.get("year_acc") is Dictionary else {}
	if int(a.get("year",-1))!=y:a={}
	r.pop=pop_now if pop_now>0 else int(a.get("pop0",-1))
	r.born=int(a.get("born",-1)) if a.has("born") else -1
	r.buried=int(a.get("buried",-1)) if a.has("buried") else -1
	r.learned=(a.get("learned",[]) as Array).size() if a.get("learned") is Array else 0
	var troubles:Array=[]
	var deaths:=0
	for cr in a.get("crises",[]):
		if not cr is Dictionary:continue
		var short:=String(cr.get("short",""))
		if short=="":short=String(cr.get("title",""))
		troubles.append({"name":short,"type":String(cr.get("type",""))})
		deaths+=int(cr.get("deaths",0))
	r.troubles=troubles
	r.deaths=deaths
	r.dry=(a.get("dry",[]) as Array).size() if a.get("dry") is Array else 0
	r.mild=(a.get("mild",[]) as Array).size() if a.get("mild") is Array else 0
	r.routine=Annals.routine_troubles(y)
	var scouts:Dictionary=a.get("scouts",{}) if a.get("scouts") is Dictionary else {}
	r.km=int(scouts.get("km",0))
	var lost:Array=[]
	for d in a.get("deaths",[]):
		if d is Dictionary and (bool(d.get("great",false)) or String(d.get("role",""))!=""):lost.append(String(d.get("name","")))
	r.lost=lost
	for field in ["heads","works"]:
		if a.get(field) is Array:r[field]=(a[field] as Array).duplicate()
	for aim in a.get("aims",[]):
		if not aim is Dictionary:continue
		if String(aim.get("kind",""))=="done":(r.kept as Array).append(String(aim.get("name","")))
		elif String(aim.get("kind",""))=="fail":(r.unmet as Array).append(String(aim.get("name","")))
	var met:Array=[]
	for t in a.get("contacts",[]):
		if ": " in String(t):met.append(String(t).get_slice(": ",1))
	r.met=met
	var turns:Array=[]
	for t in a.get("turnings",[]):
		if t is Dictionary:turns.append(String(t.get("title","")))
	r.turns=turns
	# Its mark so far: what would name it if it ended today.
	var whole:=true
	for field in ["crises","deaths","aims","works","contacts","firsts","learned","scouts","born","buried"]:
		if not a.has(field):whole=false
	if whole:
		var named:Dictionary=Annals._name_year(a,annals)
		r.glyph=String(named.glyph) if String(named.name)!="" else Annals._quiet_glyph(a)
	else:
		r.glyph=_glyph_from_story(slot.story)
	return r


## A mark from a year's told entries alone (a year before the annals began).
static func _glyph_from_story(story:Array)->String:
	var best:="quiet"
	var rank:={"death":5,"contact":4,"milestone":4,"work":4,"ceremony":3,"discovery":2,"birth":1,"scout":1}
	for e in story:
		var kind:=String((e as Dictionary).get("kind",""))
		if int(rank.get(kind,0))>int(rank.get(best,0)):best=kind
	return best


## The plain words for a year with no name, from its facts: "a dry spell ·
## three new ways". Never a made-up name.
static func unnamed_words(r:Dictionary)->String:
	var bits:PackedStringArray=[]
	var troubles:Array=r.get("troubles",[])
	if not troubles.is_empty():bits.append(_trouble_words(troubles,int(r.get("deaths",0))))
	if int(r.get("dry",0))>0:bits.append("a dry spell" if int(r.dry)==1 else "%s dry spells" % Annals._number(int(r.dry)))
	if int(r.get("mild",0))>0:bits.append("a small fever" if int(r.mild)==1 else "%s small fevers" % Annals._number(int(r.mild)))
	var learned:=int(r.get("learned",0))
	if learned>0:bits.append("one new way" if learned==1 else "%s new ways" % Annals._number(learned))
	if int(r.get("km",0))>=500:bits.append("%s km walked" % Annals._grouped(int(r.km)))
	# Fevers and fires kept only in the sickness & disaster log are not named
	# here, but a year with one is not called quiet.
	if bits.is_empty():return "an ordinary year" if int(r.get("routine",0))>0 else "a quiet year"
	return " · ".join(bits.slice(0,3))


static func _trouble_words(troubles:Array,deaths:int)->String:
	var names:PackedStringArray=[]
	for t in troubles:
		var n:=Annals.short_name(String((t as Dictionary).get("name","")))
		if n!="" and not names.has(n):names.append(n)
	var said:=", ".join(names.slice(0,2)) if not names.is_empty() else "a trouble"
	if deaths<=0:return "%s, no one died" % said
	return "%s, %s died" % [said,Annals._number(deaths)]
