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
		child.owner = scene
	var packed := PackedScene.new()
	var error := packed.pack(scene)
	if error == OK:
		error = ResourceSaver.save(packed, args[1])
	scene.free()
	if error != OK:
		push_error("Scene Forge package save failed: " + str(error))
	quit(0 if error == OK else 1)
