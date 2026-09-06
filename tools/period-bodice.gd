extends RefCounted
## Rejected four-piece bodice benchmark, not an admitted wardrobe constructor.
## The approved Beatrix image guides square neck, shoulder straps and pointed waist.
const Sewing = preload("res://sewing-pattern.gd")
const Contact = preload("res://cloth-contact.gd")

static func pattern(height: float, chest_quarter: float = .215, waist_quarter: float = .17) -> Dictionary:
	if not is_finite(height) or not is_finite(chest_quarter) or not is_finite(waist_quarter) or height < 1.2 or height > 2.2 or chest_quarter <= waist_quarter or waist_quarter < .1 or chest_quarter > .35:
		return {"error":"Invalid bodice measurements."}
	var scale := height/1.62
	var cut := [[0,0],[waist_quarter,.025*scale],[waist_quarter*1.02,.075*scale],[chest_quarter,.255*scale],[chest_quarter*.94,.285*scale],[.16*scale,.40*scale],[.085*scale,.40*scale],[.077*scale,.275*scale],[0,.25*scale]]
	var panels := []
	for id in ["front_left","front_right","back_left","back_right"]:
		var back: bool = id.begins_with("back")
		var mirror: bool = id.ends_with("left") != back
		var boundary := []
		for point in cut:
			boundary.append([point[0]*(-1 if mirror else 1),point[1]])
		panels.append({"id":id,"boundary":boundary,"origin":[0,.075*scale,(-.15 if back else .245)*scale],"u":[-1 if back else 1,0,0],"v":[0,1,0]})
	var stitches := []
	for side in ["left","right"]:
		for edge in [1,2,5]:
			stitches.append({"a":["front_"+side,edge],"b":["back_"+side,edge],"reverse":false})
	for side in ["front","back"]:
		stitches.append({"a":[side+"_left",8],"b":[side+"_right",8],"reverse":false})
	return {"schemaVersion":1,"units":"metres","panels":panels,"stitches":stitches,"construction":"four-piece-pointed-waist-square-neck-bodice-study","measurements":{"height":height,"chestQuarter":chest_quarter,"waistQuarter":waist_quarter}}

static func fit(body: ArrayMesh, cut: Dictionary, levels: int = 2) -> Dictionary:
	var compiled: Dictionary = Sewing.compile(cut,levels)
	if compiled.error != "":
		return compiled
	var contact := Contact.new()
	if contact.build_mesh(body) != "":
		return {"error":contact.error}
	var settings := {"bending":true,"bendCompliance":.00005,"contact":contact,"thickness":.004,"iterations":5,"damping":8.0}
	var sewn: Dictionary = Sewing.relax(compiled,120,0,1.0/60,settings)
	if sewn.error != "":
		return sewn
	var original: PackedVector3Array = compiled.positions
	compiled.positions = sewn.positions
	var draped: Dictionary = Sewing.simulate(compiled,90,1.0/120,settings)
	if draped.error != "":
		return draped
	compiled.positions = original
	var mesh: ArrayMesh = Sewing.build_mesh(compiled,draped.positions)
	var minimum_separation := INF
	var penetrating_samples := 0
	# Include triangle centroids; vertex-only contact does not guarantee face clearance.
	var samples: PackedVector3Array = draped.positions.duplicate()
	for i in range(0,compiled.triangles.size(),3):
		samples.append((draped.positions[compiled.triangles[i]]+draped.positions[compiled.triangles[i+1]]+draped.positions[compiled.triangles[i+2]])/3)
	for point in samples:
		var nearest: Dictionary = contact.nearest(point,.05)
		if nearest.is_empty():
			continue
		var distance: float = (point-nearest.point).dot(nearest.normal)
		minimum_separation = minf(minimum_separation,distance)
		if distance < -.001:
			penetrating_samples += 1
	return {"error":"","mesh":mesh,"compiled":compiled,"positions":draped.positions,"metrics":{"maxSeamGapMetres":draped.maxSeamGapMetres,"maxRelativeEdgeStretch":draped.maxRelativeEdgeStretch,"minimumSampledBodySeparationMetres":minimum_separation,"penetratingVertexOrCentroidSamples":penetrating_samples,"sampleCount":samples.size(),"selfContact":false,"status":"unapproved-bodice-fit-study"}}
