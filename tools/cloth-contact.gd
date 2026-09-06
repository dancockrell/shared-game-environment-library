extends RefCounted
## Original static triangle BVH for offline tailoring. Not a closed-solid classifier.
## Surface winding must point outward; open/overlapping meshes require author review.
var faces: Array = []
var nodes: Array = []
var error := "Unbuilt collider."

func build_mesh(mesh: ArrayMesh) -> String:
	if mesh == null:
		error = "Missing fitting mesh."
		faces.clear()
		nodes.clear()
		return error
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var offset := vertices.size()
		vertices.append_array(arrays[Mesh.ARRAY_VERTEX])
		if arrays[Mesh.ARRAY_INDEX] == null or arrays[Mesh.ARRAY_INDEX].is_empty():
			for i in arrays[Mesh.ARRAY_VERTEX].size():
				indices.append(offset+i)
		else:
			for index in arrays[Mesh.ARRAY_INDEX]:
				indices.append(offset+index)
	return build(vertices,indices,true)

func build(vertices: PackedVector3Array, indices: PackedInt32Array, clockwise: bool = true) -> String:
	faces.clear()
	nodes.clear()
	error = "Invalid triangle collider."
	if vertices.is_empty() or indices.is_empty() or indices.size()%3 != 0 or indices.size() > 600000:
		return error
	for point in vertices:
		if not point.is_finite():
			return error
	for index in indices:
		if index < 0 or index >= vertices.size():
			return error
	for i in range(0,indices.size(),3):
		var a := vertices[indices[i]]
		var b := vertices[indices[i+1]]
		var c := vertices[indices[i+2]]
		var cross := (b-a).cross(c-a)
		if cross.length_squared() < 1e-16:
			faces.clear()
			return "Degenerate collider triangle."
		var bounds := AABB(a,Vector3.ZERO).expand(b).expand(c)
		faces.append({"a":a,"b":b,"c":c,"normal":cross.normalized()*(-1 if clockwise else 1),"bounds":bounds,"center":(a+b+c)/3})
	var ids := []
	for i in faces.size():
		ids.append(i)
	_branch(ids)
	error = ""
	return error

func _branch(ids: Array) -> int:
	var bounds: AABB = faces[ids[0]].bounds
	for id in ids:
		bounds = bounds.merge(faces[id].bounds)
	var index := nodes.size()
	nodes.append({"bounds":bounds,"ids":[],"left":-1,"right":-1})
	if ids.size() <= 8:
		nodes[index].ids = ids
	else:
		var axis := bounds.size.max_axis_index()
		ids.sort_custom(func(a: int,b: int) -> bool:
			var av: float = faces[a].center[axis]
			var bv: float = faces[b].center[axis]
			return a < b if av == bv else av < bv)
		var midpoint := ids.size()/2
		nodes[index].left = _branch(ids.slice(0,midpoint))
		nodes[index].right = _branch(ids.slice(midpoint))
	return index

static func box_distance_squared(point: Vector3, bounds: AABB) -> float:
	return point.distance_squared_to(point.clamp(bounds.position,bounds.end))

## Voronoi regions of the triangle, including all edges and vertices.
static func closest_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b-a
	var ac := c-a
	var ap := p-a
	var d1 := ab.dot(ap)
	var d2 := ac.dot(ap)
	if d1 <= 0 and d2 <= 0:
		return a
	var bp := p-b
	var d3 := ab.dot(bp)
	var d4 := ac.dot(bp)
	if d3 >= 0 and d4 <= d3:
		return b
	var vc := d1*d4-d3*d2
	if vc <= 0 and d1 >= 0 and d3 <= 0:
		return a+ab*(d1/(d1-d3))
	var cp := p-c
	var d5 := ab.dot(cp)
	var d6 := ac.dot(cp)
	if d6 >= 0 and d5 <= d6:
		return c
	var vb := d5*d2-d1*d6
	if vb <= 0 and d2 >= 0 and d6 <= 0:
		return a+ac*(d2/(d2-d6))
	var va := d3*d6-d5*d4
	if va <= 0 and d4-d3 >= 0 and d5-d6 >= 0:
		return b+(c-b)*((d4-d3)/((d4-d3)+(d5-d6)))
	return a+ab*(vb/(va+vb+vc))+ac*(vc/(va+vb+vc))

func nearest(point: Vector3, distance_limit: float = INF) -> Dictionary:
	if error != "" or not point.is_finite() or is_nan(distance_limit) or distance_limit < 0:
		return {}
	var best := distance_limit*distance_limit
	var result := {}
	var stack := [0]
	while not stack.is_empty():
		var node: Dictionary = nodes[stack.pop_back()]
		if box_distance_squared(point,node.bounds) > best:
			continue
		if node.left >= 0:
			var left_distance := box_distance_squared(point,nodes[node.left].bounds)
			var right_distance := box_distance_squared(point,nodes[node.right].bounds)
			stack.append(node.right if left_distance <= right_distance else node.left)
			stack.append(node.left if left_distance <= right_distance else node.right)
		else:
			for id in node.ids:
				var face: Dictionary = faces[id]
				var closest := closest_triangle(point,face.a,face.b,face.c)
				var distance := closest.distance_squared_to(point)
				if distance < best or (distance == best and (result.is_empty() or id < result.face)):
					best = distance
					result = {"point":closest,"normal":face.normal,"face":id,"distance":sqrt(best)}
	return result

## Front-facing vertex sweep prevents crossing the surface between endpoints.
## Does not implement cloth edge/triangle CCD or cloth self-contact.
func resolve(previous: Vector3, predicted: Vector3, thickness: float = .003, band: float = .05) -> Vector3:
	if error != "" or not previous.is_finite() or not predicted.is_finite() or not is_finite(thickness) or thickness < 0 or not is_finite(band) or band < thickness:
		return predicted
	var sweep_bounds := AABB(previous,Vector3.ZERO).expand(predicted).grow(.000001)
	var stack := [0]
	var best := INF
	var result := predicted
	while not stack.is_empty():
		var node: Dictionary = nodes[stack.pop_back()]
		if not sweep_bounds.intersects(node.bounds.grow(.000001)):
			continue
		if node.left >= 0:
			stack.append(node.left)
			stack.append(node.right)
		else:
			for id in node.ids:
				var face: Dictionary = faces[id]
				if (predicted-previous).dot(face.normal) >= 0:
					continue
				var hit: Variant = Geometry3D.segment_intersects_triangle(previous,predicted,face.a,face.b,face.c)
				if hit != null and previous.distance_squared_to(hit) < best:
					best = previous.distance_squared_to(hit)
					result = hit+face.normal*thickness
	if best != INF:
		return result
	var nearby := nearest(predicted,band)
	if not nearby.is_empty():
		var separation: float = (predicted-nearby.point).dot(nearby.normal)
		if separation < thickness:
			result += nearby.normal*(thickness-separation)
	return result
