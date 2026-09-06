extends SceneTree
const Importer = preload("res://addons/scene_forge/import_scene.gd")
func _preflight_tests(path: String) -> bool:
	var bytes := FileAccess.get_file_as_bytes(path)
	if not Importer.portable_preflight(bytes).is_empty():
		return false
	var broken := bytes.duplicate()
	broken.encode_u32(4, 1)
	if Importer.portable_preflight(broken).is_empty():
		return false
	var old_size := bytes.decode_u32(12)
	var data: Dictionary = JSON.parse_string(bytes.slice(20, 20 + old_size).get_string_from_utf8())
	data.buffers[0]["uri"] = "must-not-be-opened.bin"
	var json := JSON.stringify(data).to_utf8_buffer()
	while json.size() % 4 != 0:
		json.append(32)
	var external := bytes.slice(0, 20)
	external.append_array(json)
	external.append_array(bytes.slice(20 + old_size))
	external.encode_u32(8, external.size())
	external.encode_u32(12, json.size())
	return not Importer.portable_preflight(external).is_empty() and not Importer.portable_preflight(bytes.slice(0, bytes.size() - 1)).is_empty()
## Headless metadata/scene-tree diagnostic; not a rendering or mesh-buffer test.
func _initialize() -> void:
	var editor_script = load("res://addons/scene_forge/plugin.gd")
	if editor_script == null or not editor_script.can_instantiate():
		push_error("Editor plugin script failed to compile")
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(1)
		return
	if not _preflight_tests(args[0]):
		push_error("Portable preflight regression")
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
