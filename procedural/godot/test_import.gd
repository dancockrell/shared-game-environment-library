extends SceneTree
const PluginScript = preload("res://addons/scene_forge/plugin.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var path := OS.get_cmdline_user_args()[0]
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var scene: Node3D = preload("res://addons/scene_forge/import_scene.gd").build(data)
	root.add_child(scene)
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
	if OS.get_cmdline_user_args().size() > 1:
		root.size = Vector2i(1280, 800)
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		root.add_child(camera)
		var total_bounds: AABB = scene.get_child(0).multimesh.custom_aabb
		for child in scene.get_children():
			total_bounds = total_bounds.merge(child.multimesh.custom_aabb)
		var center := total_bounds.get_center()
		var direction := Vector3(1, 1, 1).normalized()
		# Optional inspection angles, in degrees; geometry/import validation is
		# identical for every view. Use front/side/rear without a second renderer.
		if OS.get_cmdline_user_args().size() > 3:
			assert(OS.get_cmdline_user_args()[2].is_valid_float())
			assert(OS.get_cmdline_user_args()[3].is_valid_float())
			var azimuth := deg_to_rad(float(OS.get_cmdline_user_args()[2]))
			var elevation := deg_to_rad(float(OS.get_cmdline_user_args()[3]))
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
		await create_timer(1).timeout
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[1]) == OK)
	print("Scene Forge Godot import passed: ", count, " instances, ", scene.get_child_count(), " shared meshes")
	print("Spatial checks: ", "unavailable-data guards only (dummy renderer)" if DisplayServer.get_name() == "headless" else "graphics-backed transforms and bounds verified")
	if "--keep-open" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		root.title = "Scene Forge — procedural teapot review (work in progress)"
		# User-requested review reuses this process; normal automated tests still exit.
		Engine.max_fps = 12
		return
	scene.queue_free()
	quit()
