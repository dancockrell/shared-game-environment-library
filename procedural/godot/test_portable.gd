extends SceneTree
## Headless metadata/scene-tree diagnostic; not a rendering or mesh-buffer test.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(1)
		return
	var scene: Node3D = preload("res://addons/scene_forge/import_scene.gd").build_portable(args[0])
	if scene == null:
		quit(1)
		return
	var manifest: Dictionary = JSON.parse_string(scene.get_meta("scene_forge_asset_manifest"))
	var recipe: String = scene.get_meta("scene_forge_recipe_json")
	var parsed = JSON.parse_string(recipe)
	if not parsed is Dictionary or recipe.sha256_text() != manifest.recipe_sha256:
		push_error("Portable recipe hash or JSON mismatch")
		scene.free()
		quit(1)
		return
	var parts := scene.find_children("*", "MeshInstance3D", true, false)
	var ids := {}
	for part in parts:
		var source_node: Node = part
		while source_node != null and not source_node.has_meta("scene_forge_export_id"):
			source_node = source_node.get_parent()
		if source_node == null or not source_node.has_meta("scene_forge_source_mesh"):
			push_error("Portable part metadata missing: " + str(part.name))
			scene.free()
			quit(1)
			return
		ids[source_node.get_meta("scene_forge_export_id")] = true
	var valid := parts.size() == int(manifest.instances) and ids.size() == parts.size()
	print("SCENE_FORGE_PORTABLE_METADATA_", "PASS" if valid else "FAIL", " instances=", parts.size(), " graphics=not_run")
	scene.free()
	quit(0 if valid else 1)
