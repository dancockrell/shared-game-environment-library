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
		for i in instances.size():
			var item: Dictionary = instances[i]
			var basis := Basis(Vector3.UP, float(item.yaw)).scaled(Vector3.ONE * float(item.scale))
			multi.set_instance_transform(i, Transform3D(basis, Vector3(item.position[0], item.position[1], item.position[2])))
		var display := MultiMeshInstance3D.new()
		display.name = spec.name
		display.multimesh = multi
		root.add_child(display)
	return root
