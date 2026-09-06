extends SceneTree
const PluginScript = preload("res://addons/scene_forge/plugin.gd")
var _review_args := PackedStringArray()
var _review_nodes: Array[Node] = []
var _request_path := ""
var _request_root := ""
var _last_request := ""
var _request_sequence := ""
var _busy := true
var _pending_data: Dictionary = {}
func _initialize() -> void:
	_review_args = OS.get_cmdline_user_args()
	if "--test-review-requests" in _review_args:
		_test_review_requests()
		quit()
		return
	for argument in _review_args:
		if argument.begins_with("--watch-request="):
			_request_path = argument.trim_prefix("--watch-request=").simplify_path()
	if not _request_path.is_empty():
		if not _request_path.is_absolute_path() or not "--keep-open" in _review_args or DisplayServer.get_name() == "headless":
			push_error("Request review requires an absolute mailbox path, --keep-open and a graphics backend")
			quit(1)
			return
		_request_root = _request_path.get_base_dir().replace("\\", "/").to_lower() + "/"
		var poll := Timer.new()
		poll.wait_time = 1.0
		poll.autostart = true
		poll.timeout.connect(_poll_request)
		root.add_child(poll)
	call_deferred("_run")

static func _request_fields(request: Variant, directory: String) -> Dictionary:
	if not request is Dictionary:
		return {"error": "Review request must be an object"}
	for key in ["input", "output", "sequence"]:
		if not request.get(key) is String or request[key].is_empty():
			return {"error": "Review input, output and sequence must be nonempty strings"}
	var result: Dictionary = request.duplicate()
	for key in ["azimuth", "elevation"]:
		var value: Variant = request.get(key, 45.0 if key == "azimuth" else 25.0)
		if not (value is int or value is float) or not is_finite(float(value)):
			return {"error": "Review angles must be finite numbers"}
		result[key] = float(value)
	if absf(result.elevation) >= 89.0:
		return {"error": "Review elevation must be between -89 and 89 degrees"}
	var prefix := directory.replace("\\", "/").simplify_path().trim_suffix("/").to_lower() + "/"
	for key in ["input", "output"]:
		var path: String = request[key].replace("\\", "/").simplify_path()
		if not path.is_absolute_path() or not path.to_lower().begins_with(prefix):
			return {"error": "Review paths must stay inside the mailbox directory"}
		result[key] = path
	if result.input.get_extension().to_lower() != "json" or result.output.get_extension().to_lower() != "png":
		return {"error": "Review needs a JSON input and a PNG output"}
	return result

static func _scene_header_error(data: Variant) -> String:
	if not data is Dictionary or not data.get("meshes") is Array or not data.get("instances") is Array:
		return "Review input is not a compiled scene"
	var estimate: Variant = data.get("estimated_geometry_bytes")
	if not (estimate is int or estimate is float):
		return "Review payload estimate must be numeric"
	if not is_finite(float(estimate)) or estimate < 0 or estimate > 64 * 1024 * 1024:
		return "Review payload estimate exceeds budget or is invalid"
	if data.meshes.is_empty() or data.meshes.size() > 128 or data.instances.size() > 1000:
		return "Review scene exceeds the small-study mesh or instance budget"
	if not data.get("version") in [1, 2, 1.0, 2.0] or data.get("coordinate_system") != "right-handed-y-up-ccw-metres":
		return "Unsupported review scene format"
	return ""

static func _test_review_requests() -> void:
	var valid := {"sequence":"one", "input":"C:/review/source.json", "output":"C:/review/first.png"}
	assert(not _request_fields(valid, "C:/review").has("error"))
	assert(_request_fields(valid, "C:/review").azimuth == 45.0)
	var cases := [null, [], "bad", {}, {"sequence":1}]
	for field in ["input", "output", "sequence", "azimuth", "elevation"]:
		for value in [null, [], {}, true]:
			var bad := valid.duplicate()
			bad[field] = value
			cases.append(bad)
	for field in ["input", "output"]:
		for value in ["C:/review/../elsewhere/test.png", "C:/review-other/test.png", "relative.png"]:
			var bad := valid.duplicate()
			bad[field] = value
			cases.append(bad)
	for value in [NAN, INF, -INF, 89.0, -89.0, "25"]:
		var bad := valid.duplicate()
		bad.elevation = value
		cases.append(bad)
	for bad in cases:
		assert(_request_fields(bad, "C:/review").has("error"), str(bad))
	var header := {"version":2.0, "coordinate_system":"right-handed-y-up-ccw-metres", "meshes":[{}], "instances":[], "estimated_geometry_bytes":64 * 1024 * 1024}
	assert(_scene_header_error(header).is_empty())
	for value in [null, [], {}, true, "1024", -1, INF, NAN, 64 * 1024 * 1024 + 1]:
		var bad := header.duplicate()
		bad.estimated_geometry_bytes = value
		assert(not _scene_header_error(bad).is_empty())
	var oversized := header.duplicate()
	oversized.meshes = []
	oversized.meshes.resize(129)
	assert(not _scene_header_error(oversized).is_empty())
	oversized = header.duplicate()
	oversized.instances = []
	oversized.instances.resize(1001)
	assert(not _scene_header_error(oversized).is_empty())
	print("Review admission tests passed: ", cases.size(), " rejected requests, 9 invalid payload estimates, mesh/instance limits and valid defaults")

func _poll_request() -> void:
	if _busy or not FileAccess.file_exists(_request_path):
		return
	var file := FileAccess.open(_request_path, FileAccess.READ)
	if file == null or file.get_length() > 4096:
		return
	var text := file.get_as_text()
	if text == _last_request:
		return
	_last_request = text
	var request := _request_fields(JSON.parse_string(text), _request_root)
	if request.has("error"):
		push_warning(request.error)
		return
	var input_path: String = request.input
	var output_path: String = request.output
	var azimuth: float = request.azimuth
	var elevation: float = request.elevation
	# Local mailbox only. Inputs and new captures stay inside its review directory.
	# No shell commands, network listener, arbitrary output replacement or queue.
	if FileAccess.file_exists(output_path):
		push_warning("Review capture already exists")
		return
	var source := FileAccess.open(input_path, FileAccess.READ)
	if source == null or source.get_length() > 32 * 1024 * 1024:
		push_warning("Review input unavailable or exceeds 32 MiB")
		return
	var data: Variant = JSON.parse_string(source.get_as_text())
	var error := _scene_header_error(data)
	if not error.is_empty():
		push_warning(error)
		return
	_pending_data = data
	_review_args = PackedStringArray([input_path, output_path, str(azimuth), str(elevation), "--keep-open"])
	_request_sequence = str(request.get("sequence", ""))
	_busy = true
	call_deferred("_run")

func _run() -> void:
	var path := _review_args[0]
	# Use the admitted snapshot rather than rereading a file that may have changed.
	var data: Dictionary = _pending_data if not _pending_data.is_empty() else JSON.parse_string(FileAccess.get_file_as_string(path))
	_pending_data = {}
	# Release only the previous study's owned scene/camera/lights. The mailbox
	# timer and this process survive. At most one requested study is loaded.
	for node in _review_nodes:
		node.free()
	_review_nodes.clear()
	var scene: Node3D = preload("res://addons/scene_forge/import_scene.gd").build(data)
	root.add_child(scene)
	_review_nodes.append(scene)
	assert(scene.get_meta("scene_forge_recipe_json", "") == data.get("recipe_json", ""))
	assert(scene.get_child_count() == data.meshes.size())
	var count := 0
	for child in scene.get_children():
		assert(child is MultiMeshInstance3D)
		count += child.multimesh.instance_count
		assert(child.multimesh.mesh.get_aabb().size.length() > 0)
		assert(child.multimesh.custom_aabb.size.length() > 0)
	assert(count == data.instances.size())
	var packed := PackedScene.new()
	for child in scene.get_children():
		child.owner = scene
	assert(packed.pack(scene) == OK)
	var copy: Node3D = packed.instantiate()
	assert(copy.get_meta("scene_forge_recipe_json", "") == scene.get_meta("scene_forge_recipe_json", ""))
	assert(copy.get_child_count() == scene.get_child_count())
	root.add_child(copy)
	for mesh_index in data.meshes.size():
		var descriptors: Array = data.meshes[mesh_index].get("apertures", [])
		var display: MultiMeshInstance3D = copy.get_child(mesh_index)
		var expected_instances: Array = data.instances.filter(func(item): return int(item.mesh) == mesh_index)
		for instance_index in expected_instances.size():
			var description: Dictionary = preload("res://addons/scene_forge/import_scene.gd").describe_instance(display, instance_index)
			if DisplayServer.get_name() == "headless":
				assert(description.has("error"))
			else:
				assert(description.vertices > 0 and description.indices > 0)
			assert(JSON.parse_string(JSON.stringify(description)) is Dictionary)
			if not description.has("error") and data.version == 2:
				for column in 3:
					for axis in 3:
						assert(absf(float(description.basis_columns[column][axis]) - float(expected_instances[instance_index].basis[column * 3 + axis])) < 0.00001)
			if not description.has("error") and expected_instances[instance_index].has("bounds"):
				for key in ["min", "max"]:
					for axis in 3:
						var actual := float(description.bounds[key][axis])
						var expected := float(expected_instances[instance_index].bounds[key][axis])
						# Different f32 transform implementations can differ near zero.
						if absf(actual - expected) > 0.00001 * maxf(1.0, absf(expected)):
							push_error("Bounds mismatch: actual=%s expected=%s" % [actual, expected])
							quit(1)
							return
			var source: Dictionary = preload("res://addons/scene_forge/import_scene.gd").instance_source(display, instance_index)
			assert(source == expected_instances[instance_index].get("source", {}))
			source["test_only"] = true
			assert(not preload("res://addons/scene_forge/import_scene.gd").instance_source(display, instance_index).has("test_only"))
		var spec: Dictionary = data.meshes[mesh_index]
		var finish: Dictionary = spec.get("material", {})
		var saved_material: StandardMaterial3D = display.multimesh.mesh.surface_get_material(0)
		assert(is_equal_approx(saved_material.roughness, float(finish.get("roughness", 0.85))))
		assert(is_equal_approx(saved_material.metallic, float(finish.get("metallic", 0.0))))
		if spec.has("paint_texture"):
			assert(saved_material.albedo_texture != null)
			var painted := saved_material.albedo_texture.get_image()
			assert(painted.get_width() == int(spec.paint_texture.width))
			assert(painted.has_mipmaps())
			assert(saved_material.get_meta("scene_forge_paint") == finish.paint)
			assert(painted.get_data().slice(0, spec.paint_texture.rgba.size()) == PackedByteArray(spec.paint_texture.rgba))
			if spec.paint_texture.has("normal_rgba"):
				assert(saved_material.normal_enabled and saved_material.normal_texture != null)
				var normal_image := saved_material.normal_texture.get_image()
				assert(normal_image.has_mipmaps())
				assert(normal_image.get_data().slice(0, spec.paint_texture.normal_rgba.size()) == PackedByteArray(spec.paint_texture.normal_rgba))
				var tangents: PackedFloat32Array = display.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TANGENT]
				assert(tangents.size() == spec.positions.size() / 3 * 4)
				for t in tangents:
					assert(is_finite(t))
		var surface := display.multimesh.mesh.surface_get_arrays(0)
		var positions: PackedVector3Array = surface[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = surface[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = surface[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = surface[Mesh.ARRAY_INDEX]
		assert(positions.size() * 3 == spec.positions.size())
		assert(normals.size() == positions.size())
		assert(uvs.size() == positions.size())
		for vertex in positions.size():
			var offset := vertex * 3
			var expected_position := Vector3(spec.positions[offset], spec.positions[offset+1], spec.positions[offset+2])
			var expected_normal := Vector3(spec.normals[offset], spec.normals[offset+1], spec.normals[offset+2])
			assert(positions[vertex].is_equal_approx(expected_position))
			# Godot stores octahedrally encoded normals: allow storage quantization,
			# not smoothing loss or sign/mirroring errors.
			assert(normals[vertex].distance_to(expected_normal) < 0.001)
			var expected_uv := Vector2(spec.uvs[vertex*2], spec.uvs[vertex*2+1])
			assert(uvs[vertex].distance_to(expected_uv) < 0.001)
		assert(indices.size() == spec.indices.size())
		for index in range(0, indices.size(), 3):
			assert(indices[index] == spec.indices[index])
			assert(indices[index+1] == spec.indices[index+2])
			assert(indices[index+2] == spec.indices[index+1])
		assert(display.multimesh.custom_aabb.size.length() > 0)
		assert(display.get_meta("scene_forge_apertures") == descriptors)
		if not descriptors.is_empty() and display.multimesh.instance_count > 1:
			var importer = preload("res://addons/scene_forge/import_scene.gd")
			if DisplayServer.get_name() == "headless":
				assert(importer.aperture_world(display, 0, 0).is_empty())
				continue
			var aperture: Dictionary = descriptors[0]
			var first: Dictionary = importer.aperture_world(display, 0, 0)
			var second: Dictionary = importer.aperture_world(display, 1, 0)
			var delta := display.multimesh.get_instance_transform(1).origin - display.multimesh.get_instance_transform(0).origin
			assert((second.position - first.position).is_equal_approx(delta))
			var instance_scale := display.multimesh.get_instance_transform(0).basis.x.length()
			assert(is_equal_approx(first.width, float(aperture.width) * instance_scale))
			copy.rotation.y = PI / 2
			copy.scale = Vector3.ONE * 2
			copy.position = Vector3(3, 4, 5)
			var moved: Dictionary = importer.aperture_world(display, 0, 0)
			assert(moved.position.is_equal_approx(copy.transform * first.position))
			assert(is_equal_approx(moved.width, first.width * 2))
			assert(is_equal_approx(moved.height, first.height * 2))
			assert(moved.outward_normal.is_equal_approx((copy.basis * first.outward_normal).normalized()))
			assert(importer.aperture_world(display, -1, 0).is_empty())
			assert(importer.aperture_world(display, 0, 999).is_empty())
			copy.transform = Transform3D.IDENTITY
	copy.free()
	if _review_args.size() > 1:
		root.size = Vector2i(1280, 800)
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		root.add_child(camera)
		_review_nodes.append(camera)
		var total_bounds: AABB = scene.get_child(0).multimesh.custom_aabb
		for child in scene.get_children():
			total_bounds = total_bounds.merge(child.multimesh.custom_aabb)
		var center := total_bounds.get_center()
		var direction := Vector3(1, 1, 1).normalized()
		# Optional inspection angles, in degrees; geometry/import validation is
		# identical for every view. Use front/side/rear without a second renderer.
		if _review_args.size() > 3:
			assert(_review_args[2].is_valid_float())
			assert(_review_args[3].is_valid_float())
			var azimuth := deg_to_rad(float(_review_args[2]))
			var elevation := deg_to_rad(float(_review_args[3]))
			assert(is_finite(azimuth) and is_finite(elevation) and absf(elevation) < PI/2)
			direction = Vector3(sin(azimuth)*cos(elevation), sin(elevation), cos(azimuth)*cos(elevation))
		camera.position = center + direction * maxf(10.0, total_bounds.size.length() * 2.0)
		camera.look_at(center)
		var half_width := 0.0
		var half_height := 0.0
		for corner in 8:
			var relative := total_bounds.get_endpoint(corner) - center
			half_width = maxf(half_width, absf(relative.dot(camera.basis.x)))
			half_height = maxf(half_height, absf(relative.dot(camera.basis.y)))
		camera.size = maxf(0.01, maxf(half_height * 2.0, half_width * 2.0 / (1280.0 / 800.0)) * 1.2)
		# A fixed 100 m depth volume wastes precision on a 25 cm hero prop.
		var distance_to_center := camera.position.distance_to(center)
		var depth_margin := maxf(0.01, total_bounds.size.length() * 1.2)
		camera.near = maxf(0.001, distance_to_center - depth_margin)
		camera.far = distance_to_center + depth_margin
		camera.current = true
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-45, -35, 0)
		sun.shadow_enabled = true
		root.add_child(sun)
		_review_nodes.append(sun)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color(0.13, 0.16, 0.18)
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color.WHITE
		environment.environment.ambient_light_energy = 0.5
		# Metallic surfaces require something to reflect. Use an engine-native
		# procedural sky, not a downloaded HDRI or a paid asset.
		var sky := Sky.new()
		sky.sky_material = ProceduralSkyMaterial.new()
		environment.environment.sky = sky
		environment.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		root.add_child(environment)
		_review_nodes.append(environment)
		await create_timer(1).timeout
		await RenderingServer.frame_post_draw
		if not _request_sequence.is_empty() and FileAccess.file_exists(_review_args[1]):
			push_warning("Capture appeared during review; refusing to replace it")
			_busy = false
			return
		assert(root.get_texture().get_image().save_png(_review_args[1]) == OK)
	print("Scene Forge Godot import passed: ", count, " instances, ", scene.get_child_count(), " shared meshes")
	print("Spatial checks: ", "unavailable-data guards only (dummy renderer)" if DisplayServer.get_name() == "headless" else "graphics-backed transforms and bounds verified")
	if "--keep-open" in _review_args and DisplayServer.get_name() != "headless":
		root.title = "Scene Forge — %s review (work in progress)" % path.get_file().get_basename()
		# User-requested review reuses this process; normal automated tests still exit.
		Engine.max_fps = 12
		_busy = false
		print("Review ready: ", JSON.stringify({"sequence": _request_sequence, "input": path, "capture": _review_args[1] if _review_args.size() > 1 else "", "process_id": OS.get_process_id()}))
		return
	scene.queue_free()
	quit()
