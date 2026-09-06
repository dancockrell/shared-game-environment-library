@tool
extends RefCounted
## Sole Godot adapter for the engine-neutral mesh format. Meshes are shared via MultiMesh.
## Portable baked assets retain shared Mesh resources through Godot's glTF importer.
static func _has_external_uri(value: Variant, depth: int = 0) -> bool:
	if depth > 64:
		return true
	if value is Dictionary:
		if value.has("uri"):
			return true
		for child in value.values():
			if _has_external_uri(child, depth + 1):
				return true
	elif value is Array:
		for child in value:
			if _has_external_uri(child, depth + 1):
				return true
	return false

static func portable_preflight(bytes: PackedByteArray) -> String:
	if bytes.size() < 28 or bytes.size() > 64 * 1024 * 1024:
		return "Portable file outside size budget"
	if bytes.decode_u32(0) != 0x46546c67 or bytes.decode_u32(4) != 2 or bytes.decode_u32(8) != bytes.size():
		return "Invalid GLB header"
	var json_size := bytes.decode_u32(12)
	if bytes.decode_u32(16) != 0x4e4f534a or json_size % 4 != 0 or json_size > 24 * 1024 * 1024 or 28 + json_size > bytes.size():
		return "Invalid GLB JSON chunk"
	var bin_start := 20 + json_size
	var bin_size := bytes.decode_u32(bin_start)
	if bytes.decode_u32(bin_start + 4) != 0x004e4942 or bin_size % 4 != 0 or bin_start + 8 + bin_size != bytes.size():
		return "Expected one embedded binary chunk"
	var data = JSON.parse_string(bytes.slice(20, bin_start).get_string_from_utf8())
	if not data is Dictionary or _has_external_uri(data):
		return "External URI or unsupported JSON nesting"
	var buffers = data.get("buffers", [])
	if not buffers is Array or buffers.size() != 1 or not buffers[0] is Dictionary:
		return "Expected one embedded buffer"
	var declared = buffers[0].get("byteLength", -1)
	if not (declared is float or declared is int) or not is_finite(float(declared)) or declared < 0 or declared != floor(float(declared)) or bin_size - declared < 0 or bin_size - declared > 3:
		return "Invalid embedded buffer length"
	for field in ["extensionsUsed", "extensionsRequired"]:
		var extensions = data.get(field, [])
		if not extensions is Array:
			return "Invalid extension list"
		for extension in extensions:
			if extension not in ["KHR_materials_clearcoat", "KHR_materials_ior", "KHR_materials_specular", "KHR_texture_transform"]:
				return "Unsupported portable extension"
	return ""

static func build_portable(path: String) -> Node3D:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 64 * 1024 * 1024:
		push_error("Portable asset missing or exceeds 64 MiB")
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()
	var preflight := portable_preflight(bytes)
	if not preflight.is_empty():
		push_error(preflight)
		return null
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	# Parse the exact validated bytes, avoiding a file replacement race.
	if document.append_from_buffer(bytes, "", state) != OK:
		push_error("Godot could not parse portable glTF")
		return null
	var imported_names: Array[String] = []
	for source_node in state.get_nodes():
		imported_names.append(source_node.resource_name)
	var generated: Node = document.generate_scene(state)
	if generated == null:
		push_error("Godot generated no portable scene")
		return null
	var root: Node3D
	if generated is Node3D:
		root = generated
	else:
		root = Node3D.new()
		root.name = "SceneForgePortable"
		root.add_child(generated)
	var records: Array = state.json.get("nodes", [])
	var scene_nodes := root.find_children("*", "", true, false)
	scene_nodes.append(root)
	var manifest_count := 0
	for index in records.size():
		var extras: Dictionary = records[index].get("extras", {})
		# Conversion can leave stale references that are non-null on later runs.
		# Use only cached engine-assigned names, never post-conversion pointers.
		var expected_name: String = imported_names[index]
		var matches: Array = scene_nodes.filter(func(candidate: Node): return str(candidate.name) == expected_name)
		if matches.size() != 1:
			push_error("Cannot uniquely resolve portable node " + str(index))
			root.free()
			return null
		var node: Node = matches[0]
		for key in ["scene_forge_recipe_json", "scene_forge_asset_manifest", "scene_forge_export_id", "scene_forge_source_mesh", "scene_forge_source"]:
			if extras.has(key):
				node.set_meta(key, extras[key])
		if extras.has("scene_forge_asset_manifest"):
			var raw := str(extras.scene_forge_asset_manifest)
			var manifest = JSON.parse_string(raw) if raw.to_utf8_buffer().size() <= 65536 else null
			if not manifest is Dictionary or manifest.get("version") != 1 or manifest.get("admission") != "review-candidate":
				push_error("Invalid portable manifest")
				root.free()
				return null
			manifest_count += 1
			root.set_meta("scene_forge_asset_manifest", raw)
			root.set_meta("scene_forge_recipe_json", str(extras.get("scene_forge_recipe_json", "")))
	if manifest_count != 1 or str(root.get_meta("scene_forge_recipe_json", "")).is_empty():
		push_error("Portable source missing: records=" + str(records.size()) + " manifests=" + str(manifest_count))
		root.free()
		return null
	return root

static func build(data: Dictionary) -> Node3D:
	assert(data.get("version") in [1, 2, 1.0, 2.0] and data.get("coordinate_system") == "right-handed-y-up-ccw-metres", "Unsupported scene format")
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
			if texture_data.has("normal_rgba"):
				# Compiler supplies the complete normalized mip chain for both engines.
				var normal_image := Image.create_from_data(int(texture_data.width), int(texture_data.height), true, Image.FORMAT_RGBA8, PackedByteArray(texture_data.normal_rgba))
				assert(normal_image != null and not normal_image.is_empty())
				material.normal_enabled = true
				material.normal_texture = ImageTexture.create_from_image(normal_image)
				mesh.regen_normal_maps()
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
