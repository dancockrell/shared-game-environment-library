extends RefCounted
## Portable built-appearance import; does not own character construction or gameplay.

static func read_package(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error":"Character manifest not found."}
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not manifest is Dictionary or manifest.get("schemaVersion") != 1 or manifest.get("format") != "glTF-2.0-binary" or manifest.get("units") != "metres" or manifest.get("upAxis") != "Y":
		return {"error":"Unsupported character package contract."}
	var filename = manifest.get("model")
	var digest = manifest.get("modelSha256")
	if not filename is String or filename.is_empty() or filename != filename.get_file() or filename.contains("\\") or filename.contains(":") or filename.get_extension().to_lower() != "glb":
		return {"error":"Model must be a sibling GLB filename."}
	if not digest is String or digest.length() != 64 or not digest.is_valid_hex_number():
		return {"error":"Invalid model digest."}
	if not manifest.get("appearance") is Dictionary or not manifest.get("geometry") is Dictionary or not manifest.get("artStatus") is String:
		return {"error":"Missing character provenance."}
	var model_path := path.get_base_dir().path_join(filename)
	if not FileAccess.file_exists(model_path) or FileAccess.get_sha256(model_path) != digest:
		return {"error":"Model is missing or does not match its manifest."}
	var bytes := FileAccess.get_file_as_bytes(model_path)
	if bytes.size() < 20 or bytes.decode_u32(0) != 0x46546c67 or bytes.decode_u32(4) != 2 or bytes.decode_u32(8) != bytes.size() or bytes.decode_u32(16) != 0x4e4f534a:
		return {"error":"Invalid GLB container."}
	var json_length := bytes.decode_u32(12)
	if json_length > bytes.size()-20:
		return {"error":"Truncated GLB document."}
	var document = JSON.parse_string(bytes.slice(20,20+json_length).get_string_from_utf8())
	if not document is Dictionary:
		return {"error":"Invalid GLB document."}
	for field in ["buffers","images"]:
		if not document.get(field,[]) is Array:
			return {"error":"Invalid GLB resources."}
		for resource in document.get(field,[]):
			if not resource is Dictionary or resource.has("uri"):
				return {"error":"Character packages must embed all resources."}
	return {"error":"","manifest":manifest,"model_path":model_path}

static func instantiate_package(path: String) -> Dictionary:
	var result := read_package(path)
	if not result.error.is_empty():
		return result
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(result.model_path,state) != OK:
		return {"error":"Character GLB could not be imported."}
	var actor := document.generate_scene(state)
	if actor == null:
		return {"error":"Character scene could not be created."}
	actor.set_meta("appearance",result.manifest.appearance)
	actor.set_meta("export_geometry",result.manifest.geometry)
	actor.set_meta("art_status",result.manifest.artStatus)
	result.actor = actor
	return result
