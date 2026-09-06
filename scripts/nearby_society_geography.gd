extends RefCounted
## Founding geography, not player intelligence. Bounded connected-land search.
static func sites(origin:Vector2,land:Callable,seed_value:int,count:int=3)->Array[Vector2]:
	var result:Array[Vector2]=[]
	if not land.is_valid() or not bool(land.call(origin)):return result
	var queue:Array[Vector2i]=[Vector2i.ZERO];var visited:Dictionary={Vector2i.ZERO:true};var candidates:Array[Vector2]=[];var cursor:=0
	var directions:Array[Vector2i]=[Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
	for rotation in posmod(seed_value,4):directions.push_back(directions.pop_front())
	while cursor<queue.size() and cursor<1600:
		var cell:=queue[cursor];cursor+=1
		var start:=origin+Vector2(cell)*16.0
		if start.distance_to(origin)>=96 and start.distance_to(origin)<=224:candidates.append(start)
		for direction in directions:
			var next:=cell+direction
			if absi(next.x)>14 or absi(next.y)>14 or visited.has(next):continue
			var finish:=origin+Vector2(next)*16.0
			var passable:=true
			for sample in range(1,9):
				if not bool(land.call(start.lerp(finish,float(sample)/8))):passable=false;break
			if passable:visited[next]=true;queue.append(next)
	for candidate in candidates:
		var separated:=true
		for chosen in result:
			if chosen.distance_to(candidate)<112:separated=false;break
		if separated:result.append(candidate)
		if result.size()>=count:break
	return result
