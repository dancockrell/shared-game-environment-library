extends SceneTree
const PluginScript = preload("res://addons/scene_forge/plugin.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var path := OS.get_cmdline_user_args()[0]
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var scene: Node3D = preload("res://addons/scene_forge/import_scene.gd").build(data)
	root.add_child(scene)
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
	assert(copy.get_child_count() == scene.get_child_count())
	root.add_child(copy)
	for mesh_index in data.meshes.size():
		var descriptors: Array = data.meshes[mesh_index].get("apertures", [])
		var display: MultiMeshInstance3D = copy.get_child(mesh_index)
		var spec: Dictionary = data.meshes[mesh_index]
		var finish: Dictionary = spec.get("material", {})
		var saved_material: StandardMaterial3D = display.multimesh.mesh.surface_get_material(0)
		assert(is_equal_approx(saved_material.roughness, float(finish.get("roughness", 0.85))))
		assert(is_equal_approx(saved_material.metallic, float(finish.get("metallic", 0.0))))
		var surface := display.multimesh.mesh.surface_get_arrays(0)
		var positions: PackedVector3Array = surface[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = surface[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = surface[Mesh.ARRAY_INDEX]
		assert(positions.size() * 3 == spec.positions.size())
		assert(normals.size() == positions.size())
		for vertex in positions.size():
			var offset := vertex * 3
			var expected_position := Vector3(spec.positions[offset], spec.positions[offset+1], spec.positions[offset+2])
			var expected_normal := Vector3(spec.normals[offset], spec.normals[offset+1], spec.normals[offset+2])
			assert(positions[vertex].is_equal_approx(expected_position))
			# Godot stores octahedrally encoded normals: allow storage quantization,
			# not smoothing loss or sign/mirroring errors.
			assert(normals[vertex].distance_to(expected_normal) < 0.001)
		assert(indices.size() == spec.indices.size())
		for index in range(0, indices.size(), 3):
			assert(indices[index] == spec.indices[index])
			assert(indices[index+1] == spec.indices[index+2])
			assert(indices[index+2] == spec.indices[index+1])
		assert(display.multimesh.custom_aabb.size.length() > 0)
		assert(display.get_meta("scene_forge_apertures") == descriptors)
		if not descriptors.is_empty() and display.multimesh.instance_count > 1:
			var importer = preload("res://addons/scene_forge/import_scene.gd")
			var aperture: Dictionary = descriptors[0]
			var first: Dictionary = importer.aperture_world(display, 0, 0)
			var second: Dictionary = importer.aperture_world(display, 1, 0)
			var delta := display.multimesh.get_instance_transform(1).origin - display.multimesh.get_instance_transform(0).origin
			assert((second.position - first.position).is_equal_approx(delta))
			assert(is_equal_approx(first.width, float(aperture.width)))
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
		camera.size = 46
		root.add_child(camera)
		camera.position = Vector3(37, 25, 35)
		camera.look_at(Vector3(15, 1, 0))
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
	scene.queue_free()
	quit()
