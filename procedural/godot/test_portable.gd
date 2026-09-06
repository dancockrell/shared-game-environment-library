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
func _snapshot(scene: Node3D) -> Dictionary:
	var result := {"recipe": scene.get_meta("scene_forge_recipe_json"), "manifest": scene.get_meta("scene_forge_asset_manifest"), "parts": {}}
	var mesh_ids := {}
	for part in scene.find_children("*", "MeshInstance3D", true, false):
		var source_node: Node = part
		while source_node != null and not source_node.has_meta("scene_forge_export_id"):
			source_node = source_node.get_parent()
		if source_node == null or part.mesh == null or part.mesh.get_surface_count() != 1:
			return {}
		mesh_ids[part.mesh.get_instance_id()] = true
		var arrays: Array = part.mesh.surface_get_arrays(0)
		if arrays.size() != Mesh.ARRAY_MAX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array or arrays[Mesh.ARRAY_VERTEX].is_empty():
			return {}
		var transform := Transform3D.IDENTITY
		var ancestor: Node = part
		while ancestor != null and ancestor != scene:
			if ancestor is Node3D:
				transform = ancestor.transform * transform
			ancestor = ancestor.get_parent()
		var material := part.mesh.surface_get_material(0) as BaseMaterial3D
		if material == null:
			return {}
		var finish := {}
		for property in ["albedo_color", "roughness", "metallic", "clearcoat_enabled", "clearcoat", "clearcoat_roughness", "normal_enabled", "normal_scale"]:
			finish[property] = material.get(property)
		for property in ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture"]:
			var texture: Texture2D = material.get(property)
			if texture == null:
				finish[property] = null
				continue
			var image := texture.get_image()
			if image == null or image.is_empty():
				return {}
			var hash := HashingContext.new()
			hash.start(HashingContext.HASH_SHA256)
			hash.update(image.get_data())
			finish[property] = {"size": image.get_size(), "format": image.get_format(), "mipmaps": image.has_mipmaps(), "sha256": hash.finish().hex_encode()}
		result.parts[source_node.get_meta("scene_forge_export_id")] = {"mesh": source_node.get_meta("scene_forge_source_mesh"), "transform": transform, "arrays": arrays, "material": finish}
	var manifest: Dictionary = JSON.parse_string(result.manifest)
	if mesh_ids.size() != int(manifest.unique_meshes):
		return {}
	result["unique_meshes"] = mesh_ids.size()
	return result

func _own_tree(node: Node, scene: Node) -> void:
	for child in node.get_children():
		child.owner = scene
		_own_tree(child, scene)

func _verify_package(scene: Node3D, path: String) -> bool:
	if FileAccess.file_exists(path):
		push_error("Refusing to overwrite package diagnostic output")
		return false
	var before := _snapshot(scene)
	if before.is_empty():
		push_error("Mesh buffers unavailable: package persistence cannot be verified with this backend")
		return false
	_own_tree(scene, scene)
	var packed := PackedScene.new()
	if packed.pack(scene) != OK or ResourceSaver.save(packed, path) != OK:
		return false
	var saved := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if saved == null:
		return false
	var restored := saved.instantiate() as Node3D
	if restored == null:
		return false
	var same := before == _snapshot(restored)
	restored.free()
	print("SCENE_FORGE_PORTABLE_PACKAGE_", "PASS" if same else "FAIL", " graphics=not_run material_pixels=checked")
	return same

## Optional fresh .scn path enables exact geometry/placement/source persistence checks.
## Neither mode certifies rendered appearance or GPU residency.
func _initialize() -> void:
	var editor_script = load("res://addons/scene_forge/plugin.gd")
	if editor_script == null or not editor_script.can_instantiate():
		push_error("Editor plugin script failed to compile")
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() < 1 or args.size() > 2:
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
	if valid and args.size() == 2:
		valid = _verify_package(scene, args[1])
		var expected := _snapshot(scene)
		for iteration in range(2):
			var repeated: Node3D = Importer.build_portable(args[0])
			if repeated == null:
				valid = false
				break
			valid = valid and _snapshot(repeated) == expected
			repeated.free()
		print("SCENE_FORGE_PORTABLE_REPEAT_", "PASS" if valid else "FAIL", " repeats=2")
	scene.free()
	quit(0 if valid else 1)
