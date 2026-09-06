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
	assert(count == data.instances.size())
	var packed := PackedScene.new()
	for child in scene.get_children():
		child.owner = scene
	assert(packed.pack(scene) == OK)
	var copy: Node3D = packed.instantiate()
	assert(copy.get_child_count() == scene.get_child_count())
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
		root.add_child(environment)
		await create_timer(1).timeout
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[1]) == OK)
	print("Scene Forge Godot import passed: ", count, " instances, ", scene.get_child_count(), " shared meshes")
	scene.queue_free()
	quit()
