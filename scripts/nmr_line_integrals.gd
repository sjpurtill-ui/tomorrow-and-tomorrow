extends RefCounted
## Fits declared assay line shapes to observed samples. Coefficients are areas;
## fitting the complete trace accounts for finite windows and overlapping tails.
## Width/shift are calibrated game-method assumptions, not inferred composition.
static func fit(response:Dictionary,centers:Array[float],width:float=.21,shift:float=.01)->Dictionary:
	if centers.is_empty() or centers.size()>3 or not response.get("trace") is Array or response.trace.size()!=401:return {"error":"Unsupported integral fit."}
	if not is_finite(width) or width<=0 or not is_finite(shift):return {"error":"Invalid line shape."}
	if response.get("step")!=.1 or response.get("origin")!=0.0:return {"error":"Unsupported trace coordinates."}
	var n:=centers.size();var matrix:Array=[];var rhs:Array[float]=[];var basis:Array=[]
	for row:int in n:
		var values:Array[float]=[]
		for col:int in 2*n:values.append(1.0 if col==n+row else 0.0)
		matrix.append(values);rhs.append(0.0)
	for index:int in 401:
		if not (response.trace[index] is int or response.trace[index] is float):return {"error":"Invalid observed trace."}
		var y:float=response.trace[index]
		if not is_finite(y):return {"error":"Nonfinite observed trace."}
		var values:Array[float]=[]
		for center:float in centers:values.append(1.0/(PI*width*(1.0+pow((index*.1-center-shift)/width,2))))
		basis.append(values)
		for row:int in n:
			rhs[row]+=values[row]*y
			for col:int in n:matrix[row][col]+=values[row]*values[col]
	for pivot:int in n:
		var divisor:float=matrix[pivot][pivot]
		if absf(divisor)<.000000001:return {"error":"Unresolved integral components."}
		for col:int in 2*n:matrix[pivot][col]/=divisor
		for row:int in n:
			if row==pivot:continue
			var factor:float=matrix[row][pivot]
			for col:int in 2*n:matrix[row][col]-=factor*matrix[pivot][col]
	var areas:Array[float]=[]
	for row:int in n:
		var area:=0.0
		for col:int in n:area+=float(matrix[row][n+col])*rhs[col]
		if area<=0:return {"error":"Positive component area is unresolved."}
		areas.append(area)
	var residual:=0.0
	for index:int in 401:
		var prediction:=0.0
		for col:int in n:prediction+=areas[col]*float(basis[index][col])
		residual+=pow(float(response.trace[index])-prediction,2)
	var rms:=sqrt(residual/(401-n))
	var noise:float=response.get("noise_estimate",0)
	if not is_finite(noise) or noise<=0 or rms>noise*5:return {"error":"Observed response does not fit the declared line shape."}
	var errors:Array[float]=[]
	for row:int in n:
		# Three-sigma fitted noise plus a 1% method allowance, including residual
		# recovery after >=6 measured T1. Conditional on this line-shape model.
		errors.append(3.0*maxf(noise,rms)*sqrt(maxf(0.0,float(matrix[row][n+row])))+areas[row]*.01)
	return {"areas":areas,"errors":errors,"residual_rms":rms,"scope":"declared_synthetic_line_shape"}
