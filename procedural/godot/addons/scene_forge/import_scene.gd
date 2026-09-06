@tool
extends RefCounted
## Sole Godot adapter for the engine-neutral mesh format. Meshes are shared via MultiMesh.
static func build(data: Dictionary) -> Node3D:
	assert(data.get("version") == 1 and data.get("coordinate_system") == "right-handed-y-up-ccw-metres", "Unsupported scene format")
	var root := Node3D.new()
	root.name = "SceneForge"
	root.set_meta("geometry_bytes_estimate", data.estimated_geometry_bytes)
	for mesh_index in data.meshes.size():
		var spec: Dictionary = data.meshes[mesh_index]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		var vertices := PackedVector3Array()
		var normals := PackedVector3Array()
		var uvs := PackedVector2Array()
		for i in range(0, spec.positions.size(), 3):
			vertices.append(Vector3(spec.positions[i], spec.positions[i+1], spec.positions[i+2]))
			normals.append(Vector3(spec.normals[i], spec.normals[i+1], spec.normals[i+2]))
		for i in range(0, spec.uvs.size(), 2):
			uvs.append(Vector2(spec.uvs[i], spec.uvs[i+1]))
		var indices := PackedInt32Array(spec.indices)
		# Canonical CCW -> Godot clockwise, without mirroring coordinates/normals.
		for i in range(0, indices.size(), 3):
			var swap := indices[i+1]
			indices[i+1] = indices[i+2]
			indices[i+2] = swap
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(spec.color[0], spec.color[1], spec.color[2], spec.color[3])
		material.roughness = 0.85
		mesh.surface_set_material(0, material)
		var instances: Array = data.instances.filter(func(item): return int(item.mesh) == mesh_index)
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = instances.size()
		var instance_bounds := AABB()
		for i in instances.size():
			var item: Dictionary = instances[i]
			var basis := Basis(Vector3.UP, float(item.yaw)).scaled(Vector3.ONE * float(item.scale))
			var transform := Transform3D(basis, Vector3(item.position[0], item.position[1], item.position[2]))
			multi.set_instance_transform(i, transform)
			var bounds: AABB = transform * mesh.get_aabb()
			instance_bounds = bounds if i == 0 else instance_bounds.merge(bounds)
		# A PackedScene reload can retain instance buffers but lose the automatic
		# render-server AABB. Persist explicit bounds so meshes are not culled.
		multi.custom_aabb = instance_bounds
		var display := MultiMeshInstance3D.new()
		display.name = spec.name
		display.multimesh = multi
		# Shared local-space descriptors, not thousands of extra marker nodes.
		display.set_meta("scene_forge_apertures", spec.get("apertures", []))
		root.add_child(display)
	return root

## Query on demand; the caller binds an aperture to authoritative game data.
## Returned wall label stays in definition space; position/normal are world-space.
static func aperture_world(display: MultiMeshInstance3D, instance_index: int, opening_index: int) -> Dictionary:
	if instance_index < 0 or instance_index >= display.multimesh.instance_count:
		return {}
	for aperture in display.get_meta("scene_forge_apertures", []):
		if int(aperture.opening_index) != opening_index:
			continue
		var transform := display.global_transform * display.multimesh.get_instance_transform(instance_index)
		if is_zero_approx(transform.basis.determinant()):
			return {}
		var p: Array = aperture.position
		var n: Array = aperture.outward_normal
		var normal := Vector3(n[0], n[1], n[2])
		var tangent := Vector3.UP.cross(normal)
		# Dimension scaling remains correct when an editor scales the parent.
		return {
			"opening_index": opening_index,
			"definition_wall": aperture.wall,
			"position": transform * Vector3(p[0], p[1], p[2]),
			"outward_normal": (transform.basis.inverse().transposed() * normal).normalized(),
			"width": float(aperture.width) * (transform.basis * tangent).length(),
			"height": float(aperture.height) * (transform.basis * Vector3.UP).length(),
		}
	return {}
