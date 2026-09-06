extends RefCounted
## Original straight-edge pattern compiler and XPBD constraint baseline.
## Metric fabric coordinates survive placement/refinement and cloth construction.

static func number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func vector(value: Variant, size: int) -> bool:
	if not value is Array or value.size() != size:
		return false
	for component in value:
		if not number(component) or absf(float(component)) > 100:
			return false
	return true

static func compile(pattern: Variant, levels: int = 2) -> Dictionary:
	if levels < 0 or levels > 5 or not pattern is Dictionary or pattern.get("schemaVersion") != 1 or pattern.get("units") != "metres":
		return {"error":"Unsupported pattern or refinement level."}
	if not pattern.get("panels") is Array or pattern.panels.is_empty() or pattern.panels.size() > 32 or not pattern.get("stitches",[]) is Array:
		return {"error":"Expected 1..32 panels and a stitch array."}
	var result := {"error":"","positions":PackedVector3Array(),"fabric":PackedVector2Array(),"triangles":PackedInt32Array(),"constraints":[],"bends":[],"panels":{},"inverse_mass":PackedFloat32Array()}
	for panel in pattern.panels:
		if not panel is Dictionary or not panel.get("id") is String or panel.id.is_empty() or result.panels.has(panel.id):
			return {"error":"Panel IDs must be nonempty and unique."}
		if not panel.get("boundary") is Array or panel.boundary.size() < 3 or panel.boundary.size() > 64:
			return {"error":"Panel requires 3..64 boundary points."}
		for field in ["origin","u","v"]:
			if not vector(panel.get(field),3):
				return {"error":"Invalid panel placement."}
		var origin := Vector3(panel.origin[0],panel.origin[1],panel.origin[2])
		var axis_u := Vector3(panel.u[0],panel.u[1],panel.u[2])
		var axis_v := Vector3(panel.v[0],panel.v[1],panel.v[2])
		if not is_equal_approx(axis_u.length(),1) or not is_equal_approx(axis_v.length(),1) or absf(axis_u.dot(axis_v)) > .00001:
			return {"error":"Panel placement must preserve metric fabric lengths."}
		var points := PackedVector2Array()
		for point in panel.boundary:
			if not vector(point,2):
				return {"error":"Invalid fabric coordinate."}
			points.append(Vector2(point[0],point[1]))
		var edges := []
		for i in points.size():
			var next := (i+1)%points.size()
			if points[i].distance_to(points[next]) < .00001:
				return {"error":"Degenerate boundary edge."}
			var previous := (i+points.size()-1)%points.size()
			if absf((points[i]-points[previous]).cross(points[next]-points[i])) < .00000001:
				return {"error":"Collinear boundary corners must be simplified before refinement."}
			for j in range(i+1,points.size()):
				var end := (j+1)%points.size()
				if j == next or end == i:
					continue
				if Geometry2D.segment_intersects_segment(points[i],points[next],points[j],points[end]) != null:
					return {"error":"Self-intersecting panel boundary."}
			edges.append([i,next])
		var triangles := Geometry2D.triangulate_polygon(points)
		if triangles.is_empty():
			return {"error":"Panel could not be triangulated."}
		for level in levels:
			var midpoints := {}
			var refined := PackedInt32Array()
			for face in range(0,triangles.size(),3):
				var mids := []
				for edge in 3:
					var a := triangles[face+edge]
					var b := triangles[face+(edge+1)%3]
					var key := Vector2i(mini(a,b),maxi(a,b))
					if not midpoints.has(key):
						midpoints[key] = points.size()
						points.append((points[a]+points[b])*.5)
					mids.append(midpoints[key])
				refined.append_array(PackedInt32Array([triangles[face],mids[0],mids[2],mids[0],triangles[face+1],mids[1],mids[2],mids[1],triangles[face+2],mids[0],mids[1],mids[2]]))
			for edge in edges.size():
				var chain: Array = edges[edge]
				var expanded := []
				for i in chain.size()-1:
					expanded.append(chain[i])
					expanded.append(midpoints[Vector2i(mini(chain[i],chain[i+1]),maxi(chain[i],chain[i+1]))])
				expanded.append(chain.back())
				edges[edge] = expanded
			triangles = refined
			if points.size()+result.positions.size() > 20000:
				return {"error":"Pattern exceeds 20000-vertex authoring limit."}
		var offset: int = result.positions.size()
		var links := {}
		for point in points:
			result.positions.append(origin+axis_u*point.x+axis_v*point.y)
			result.fabric.append(point)
			result.inverse_mass.append(1.0)
		for face in range(0,triangles.size(),3):
			for edge in 3:
				var a := triangles[face+edge]
				var b := triangles[face+(edge+1)%3]
				var key := Vector2i(mini(a,b),maxi(a,b))
				if not links.has(key):
					links[key] = triangles[face+(edge+2)%3]
					result.constraints.append({"a":offset+a,"b":offset+b,"rest":points[a].distance_to(points[b]),"kind":"stretch"})
				else:
					var c: int = links[key]
					var d := triangles[face+(edge+2)%3]
					var e := points[b]-points[a]
					var tc := (points[c]-points[a]).dot(e)/e.length_squared()
					var td := (points[d]-points[a]).dot(e)/e.length_squared()
					var hc := e.cross(points[c]-points[a])/e.length()
					var hd := e.cross(points[d]-points[a])/e.length()
					# Linear-precision flat-rest curvature stencil across the shared edge.
					# Sum(w)=0 and sum(w*p_flat)=0; rotation/translation invariant energy.
					var weights := PackedFloat32Array([-(1-tc)/hc+(1-td)/hd,-tc/hc+td/hd,1/hc,-1/hd])
					var norm := 0.0
					for weight in weights:
						norm += absf(weight)
					for i in 4:
						weights[i] /= norm
					result.bends.append({"vertices":PackedInt32Array([offset+a,offset+b,offset+c,offset+d]),"weights":weights})
		for vertex in triangles:
			result.triangles.append(offset+vertex)
		for chain in edges:
			for i in chain.size():
				chain[i] += offset
		result.panels[panel.id] = {"edges":edges,"vertexStart":offset,"vertexCount":points.size()}
	var occupied := {}
	if pattern.get("stitches",[]).size() > 256:
		return {"error":"Too many stitched edges."}
	for stitch in pattern.get("stitches",[]):
		if not stitch is Dictionary or not stitch.get("reverse",true) is bool:
			return {"error":"Invalid stitch."}
		var chains := []
		for side in ["a","b"]:
			var ref = stitch.get(side)
			if not ref is Array or ref.size() != 2 or not ref[0] is String or not result.panels.has(ref[0]) or not number(ref[1]) or float(ref[1]) != int(ref[1]):
				return {"error":"Stitch must reference a panel and integer edge index."}
			var edge := int(ref[1])
			if edge < 0 or edge >= result.panels[ref[0]].edges.size() or occupied.has(str(ref)):
				return {"error":"Invalid or already stitched edge."}
			occupied[str(ref)] = true
			chains.append(result.panels[ref[0]].edges[edge].duplicate())
		if stitch.get("reverse",true):
			chains[1].reverse()
		if chains[0].size() != chains[1].size():
			return {"error":"Unequal stitch sampling is not yet supported."}
		for i in chains[0].size():
			if chains[0][i] == chains[1][i]:
				return {"error":"Cannot stitch a vertex to itself."}
			result.constraints.append({"a":chains[0][i],"b":chains[1][i],"rest":0.0,"kind":"seam"})
	return result

static func relax(compiled: Dictionary, iterations: int = 100, compliance: float = 0.0, step_seconds: float = 1.0/60, options: Dictionary = {}) -> Dictionary:
	if compiled.get("error") != "" or iterations < 1 or iterations > 2000 or not is_finite(compliance) or compliance < 0 or not is_finite(step_seconds) or step_seconds < .00001:
		return {"error":"Invalid relaxation inputs."}
	if not compiled.get("positions") is PackedVector3Array or not compiled.get("inverse_mass") is PackedFloat32Array or not compiled.get("constraints") is Array:
		return {"error":"Missing compiled arrays."}
	var positions: PackedVector3Array = compiled.positions.duplicate()
	var masses: PackedFloat32Array = compiled.inverse_mass
	if positions.is_empty() or positions.size() > 20000 or masses.size() != positions.size():
		return {"error":"Inverse masses must match vertices."}
	for point in positions:
		if not point.is_finite():
			return {"error":"Invalid vertex position."}
	for mass in masses:
		if not is_finite(mass) or mass < 0:
			return {"error":"Invalid inverse mass."}
	for link in compiled.constraints:
		if not link is Dictionary or not number(link.get("rest")) or link.rest < 0 or link.get("kind") not in ["seam","stretch"]:
			return {"error":"Invalid constraint."}
		for field in ["a","b"]:
			var value: Variant = link.get(field)
			if not value is int or value < 0 or value >= positions.size():
				return {"error":"Invalid constraint vertex."}
		if link.a == link.b:
			return {"error":"Constraint requires distinct vertices."}
	var multipliers := PackedFloat64Array()
	multipliers.resize(compiled.constraints.size())
	var alpha := compliance/(step_seconds*step_seconds)
	var bends: Array = compiled.get("bends",[])
	var bending_enabled: bool = options.get("bending",false)
	var bend_compliance: float = options.get("bendCompliance",.001)
	if not is_finite(bend_compliance) or bend_compliance < 0:
		return {"error":"Invalid bend compliance."}
	var bend_alpha := bend_compliance/(step_seconds*step_seconds)
	if not is_finite(alpha) or not is_finite(bend_alpha):
		return {"error":"Constraint compliance overflow."}
	if bending_enabled:
		for bend in bends:
			if not bend is Dictionary or not bend.get("vertices") is PackedInt32Array or not bend.get("weights") is PackedFloat32Array or bend.vertices.size() != 4 or bend.weights.size() != 4:
				return {"error":"Invalid bending stencil."}
			for i in 4:
				if bend.vertices[i] < 0 or bend.vertices[i] >= positions.size() or not is_finite(bend.weights[i]):
					return {"error":"Invalid bending stencil values."}
	var bend_multipliers := PackedVector3Array()
	bend_multipliers.resize(bends.size())
	var contact: RefCounted = options.get("contact")
	var previous: PackedVector3Array = options.get("previous",positions).duplicate()
	if previous.size() != positions.size() or (contact != null and contact.error != ""):
		return {"error":"Invalid contact state."}
	for point in previous:
		if not point.is_finite():
			return {"error":"Invalid previous contact position."}
	for iteration in iterations:
		for index in compiled.constraints.size():
			var link: Dictionary = compiled.constraints[index]
			var delta := positions[link.a]-positions[link.b]
			var length := delta.length()
			var denominator: float = masses[link.a]+masses[link.b]+alpha
			if length < .00000001 or denominator <= 0:
				continue
			# XPBD accumulated multiplier; reset per solve, not per iteration.
			var change: float = (-(length-link.rest)-alpha*multipliers[index])/denominator
			multipliers[index] += change
			var correction := delta*(change/length)
			positions[link.a] += correction*masses[link.a]
			positions[link.b] -= correction*masses[link.b]
		if bending_enabled:
			for index in bends.size():
				var bend: Dictionary = bends[index]
				var curvature := Vector3.ZERO
				var denominator := bend_alpha
				for i in 4:
					var vertex: int = bend.vertices[i]
					var weight: float = bend.weights[i]
					curvature += positions[vertex]*weight
					denominator += masses[vertex]*weight*weight
				if denominator <= 0:
					continue
				var change := (-curvature-bend_multipliers[index]*bend_alpha)/denominator
				bend_multipliers[index] += change
				for i in 4:
					var vertex: int = bend.vertices[i]
					positions[vertex] += change*masses[vertex]*bend.weights[i]
		if contact != null:
			for vertex in positions.size():
				if masses[vertex] > 0:
					positions[vertex] = contact.resolve(previous[vertex],positions[vertex],options.get("thickness",.003))
	var seam_gap := 0.0
	var stretch_error := 0.0
	for link in compiled.constraints:
		var length := positions[link.a].distance_to(positions[link.b])
		if link.kind == "seam":
			seam_gap = maxf(seam_gap,length)
		else:
			stretch_error = maxf(stretch_error,absf(length-link.rest)/maxf(link.rest,.000001))
	return {"error":"","positions":positions,"maxSeamGapMetres":seam_gap,"maxRelativeEdgeStretch":stretch_error,"iterations":iterations,"bodyPenetration":null,"selfIntersections":null,"status":"constraint-baseline-not-draped-garment"}

## Offline fixed-step damped dynamics. Calls the same constraint owner as sewing.
static func simulate(compiled: Dictionary, steps: int = 120, dt: float = 1.0/120, options: Dictionary = {}) -> Dictionary:
	if compiled.get("error") != "" or steps < 1 or steps > 10000 or not is_finite(dt) or dt < .00001 or dt > .05:
		return {"error":"Invalid simulation inputs."}
	var validation := relax(compiled,1,0,dt,options)
	if validation.error != "":
		return validation
	var state := compiled.duplicate(false)
	state.positions = compiled.positions.duplicate()
	var velocities := PackedVector3Array()
	velocities.resize(state.positions.size())
	var gravity: Vector3 = options.get("gravity",Vector3(0,-9.81,0))
	var damping: float = options.get("damping",2.0)
	if not gravity.is_finite() or not is_finite(damping) or damping < 0:
		return {"error":"Invalid force settings."}
	var settings := options.duplicate(false)
	var result := {}
	for step in steps:
		var previous: PackedVector3Array = state.positions.duplicate()
		for i in state.positions.size():
			if state.inverse_mass[i] > 0:
				velocities[i] = (velocities[i]+gravity*dt)*exp(-damping*dt)
				state.positions[i] += velocities[i]*dt
		settings.previous = previous
		result = relax(state,options.get("iterations",8),options.get("stretchCompliance",0.0),dt,settings)
		if result.error != "":
			return result
		state.positions = result.positions
		for i in state.positions.size():
			velocities[i] = (state.positions[i]-previous[i])/dt
	result.velocities = velocities
	result.simulatedSeconds = steps*dt
	result.status = "offline-cloth-baseline-not-approved-garment"
	return result

## One surface per cut panel; seams remain separate, preserving cloth UV discontinuities.
## UV coordinates are metres, not normalized independently for each panel.
static func build_mesh(compiled: Dictionary, sewn_positions: PackedVector3Array) -> ArrayMesh:
	if compiled.get("error") != "" or sewn_positions.size() != compiled.positions.size():
		return null
	var mesh := ArrayMesh.new()
	for id in compiled.panels:
		var panel: Dictionary = compiled.panels[id]
		var first: int = panel.vertexStart
		var count: int = panel.vertexCount
		var normals := PackedVector3Array()
		normals.resize(count)
		var indices := PackedInt32Array()
		for face in range(0,compiled.triangles.size(),3):
			var a: int = compiled.triangles[face]
			if a < first or a >= first+count:
				continue
			var b: int = compiled.triangles[face+1]
			var c: int = compiled.triangles[face+2]
			var normal := (sewn_positions[b]-sewn_positions[a]).cross(sewn_positions[c]-sewn_positions[a])
			for vertex in [a,b,c]:
				normals[vertex-first] += normal
			# Godot front faces use clockwise winding.
			indices.append_array(PackedInt32Array([c-first,b-first,a-first]))
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in count:
			surface.set_normal(normals[i].normalized())
			surface.set_uv(compiled.fabric[first+i])
			surface.add_vertex(sewn_positions[first+i])
		for index in indices:
			surface.add_index(index)
		surface.generate_tangents()
		surface.commit(mesh)
		mesh.surface_set_name(mesh.get_surface_count()-1,id)
	return mesh
