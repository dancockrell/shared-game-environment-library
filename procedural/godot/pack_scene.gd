extends SceneTree
## Build-time package export through the same adapter used by the editor.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("Expected compiled JSON and destination .scn")
		quit(1)
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var scene: Node3D = preload("res://addons/scene_forge/import_scene.gd").build(data)
	for child in scene.get_children():
		if child is MultiMeshInstance3D and child.multimesh.buffer.size() != child.multimesh.instance_count * 12:
			push_error("Missing MultiMesh instance buffer; export requires a real rendering backend, not headless dummy rendering")
			scene.free()
			quit(1)
			return
		child.owner = scene
	var packed := PackedScene.new()
	var error := packed.pack(scene)
	if error == OK:
		error = ResourceSaver.save(packed, args[1])
	if error == OK:
		var reloaded: Node3D = (ResourceLoader.load(args[1], "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
		for index in scene.get_child_count():
			var before: MultiMesh = scene.get_child(index).multimesh
			var after: MultiMesh = reloaded.get_child(index).multimesh
			if scene.get_child(index).get_meta("scene_forge_sources", []) != reloaded.get_child(index).get_meta("scene_forge_sources", []):
				error = ERR_INVALID_DATA
				break
			if before.buffer != after.buffer or before.custom_aabb != after.custom_aabb:
				error = ERR_INVALID_DATA
				break
			var before_material: StandardMaterial3D = before.mesh.surface_get_material(0)
			var after_material: StandardMaterial3D = after.mesh.surface_get_material(0)
			if before_material.albedo_color != after_material.albedo_color or before_material.roughness != after_material.roughness or before_material.metallic != after_material.metallic:
				error = ERR_INVALID_DATA
				break
		reloaded.free()
	if error == OK:
		print("Verified native package buffers, bounds and materials: ", scene.get_child_count(), " shared meshes")
	scene.free()
	if error != OK:
		push_error("Scene Forge package save failed: " + str(error))
	quit(0 if error == OK else 1)
