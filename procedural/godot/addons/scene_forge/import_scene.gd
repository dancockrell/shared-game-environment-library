@tool
extends RefCounted
## Sole Godot adapter for the engine-neutral mesh format. Meshes are shared via MultiMesh.
static func build(data: Dictionary) -> Node3D:
	assert(data.get("version") in [1, 2] and data.get("coordinate_system") == "right-handed-y-up-ccw-metres", "Unsupported scene format")
	var root := Node3D.new()
	root.name = "SceneForge"
	root.set_meta("scene_forge_recipe_json", str(data.get("recipe_json", "")))
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
		mesh.resource_name = spec.name
		mesh.set_meta("scene_forge_source_vertices", int(spec.get("source_vertex_count", vertices.size())))
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(spec.color[0], spec.color[1], spec.color[2], spec.color[3])
		var finish: Dictionary = spec.get("material", {})
		material.roughness = float(finish.get("roughness", 0.85))
		material.metallic = float(finish.get("metallic", 0.0))
		if spec.has("paint_texture"):
			var texture_data: Dictionary = spec.paint_texture
			var painted := Image.create_from_data(int(texture_data.width), int(texture_data.height), false, Image.FORMAT_RGBA8, PackedByteArray(texture_data.rgba))
			assert(painted.generate_mipmaps() == OK)
			material.albedo_texture = ImageTexture.create_from_image(painted)
			material.albedo_color = Color.WHITE
			material.set_meta("scene_forge_paint", finish.get("paint", {}))
		mesh.surface_set_material(0, material)
		var instances: Array = data.instances.filter(func(item): return int(item.mesh) == mesh_index)
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = instances.size()
		var instance_bounds := AABB()
		for i in instances.size():
			var item: Dictionary = instances[i]
			var basis: Basis
			if data.version == 2:
				var columns: Array = item.basis
				assert(columns.size() == 9, "Invalid version-2 basis")
				basis = Basis(Vector3(columns[0], columns[1], columns[2]), Vector3(columns[3], columns[4], columns[5]), Vector3(columns[6], columns[7], columns[8]))
			else:
				basis = Basis(Vector3.UP, float(item.yaw)).scaled(Vector3.ONE * float(item.scale))
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
		display.set_meta("scene_forge_sources", instances.map(func(item): return item.get("source", {})))
		root.add_child(display)
	return root

## Authored recipe locations survive engine packing without extra scene nodes.
## Return a copy so inspectors cannot accidentally mutate the shared metadata.
static func instance_source(display: MultiMeshInstance3D, instance_index: int) -> Dictionary:
	var sources: Array = display.get_meta("scene_forge_sources", [])
	if instance_index < 0 or instance_index >= sources.size():
		return {}
	return sources[instance_index].duplicate(true)

## JSON-friendly live inspection: follows editor transforms, not stale recipe poses.
static func describe_instance(display: MultiMeshInstance3D, instance_index: int) -> Dictionary:
	if instance_index < 0 or instance_index >= display.multimesh.instance_count:
		return {}
	if display.multimesh.buffer.size() != display.multimesh.instance_count * 12:
		return {"error": "Live instance transforms unavailable: missing rendering buffer", "source": instance_source(display, instance_index)}
	var mesh := display.multimesh.mesh
	var transform := display.global_transform * display.multimesh.get_instance_transform(instance_index)
	var bounds: AABB = transform * mesh.get_aabb()
	var vector = func(v: Vector3): return [v.x, v.y, v.z]
	var material: StandardMaterial3D = mesh.surface_get_material(0)
	return {
		"mesh": mesh.resource_name,
		"source": instance_source(display, instance_index),
		"position": vector.call(transform.origin),
		"basis_columns": [vector.call(transform.basis.x), vector.call(transform.basis.y), vector.call(transform.basis.z)],
		"bounds": {"min": vector.call(bounds.position), "max": vector.call(bounds.end)},
		"bounds_kind": "world_axis_aligned_mesh_envelope_not_collision",
		"vertices": mesh.surface_get_array_len(0),
		"source_vertices": mesh.get_meta("scene_forge_source_vertices", mesh.surface_get_array_len(0)),
		"indices": mesh.surface_get_array_index_len(0),
		"material": {"roughness": material.roughness, "metallic": material.metallic, "color": [material.albedo_color.r, material.albedo_color.g, material.albedo_color.b, material.albedo_color.a]},
		"aperture_count": display.get_meta("scene_forge_apertures", []).size(),
		"paint": material.get_meta("scene_forge_paint") if material.has_meta("scene_forge_paint") else null,
		"paint_texture_size": [material.albedo_texture.get_width(), material.albedo_texture.get_height()] if material.albedo_texture != null else [],
	}

## Query on demand; the caller binds an aperture to authoritative game data.
## Returned wall label stays in definition space; position/normal are world-space.
static func aperture_world(display: MultiMeshInstance3D, instance_index: int, opening_index: int) -> Dictionary:
	if display.multimesh.buffer.size() != display.multimesh.instance_count * 12:
		return {}
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
