extends SceneTree
## godot --path tools --script res://review-model-packs.gd -- <absolute-repository-path>
## Review-only transforms: raw source members remain unchanged.
const PACKS := ["terrain/coast-foundation", "terrain/river-cliff-foundation", "maritime/pirate-prop-core"]
var report: Array = []
func _init() -> void:
	call_deferred("review")

func collect(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(collect(child))
	return found

func review() -> void:
	var args := OS.get_cmdline_user_args()
	assert(args.size() == 1, "Expected repository path")
	var repo: String = args[0]
	var derivative_dir := repo.path_join("resource_packs/terrain/tabletop-foundation")
	DirAccess.make_dir_recursive_absolute(derivative_dir.path_join("artifacts/models"))
	var outputs: Array = []
	var source_members: Array = []
	root.size = Vector2i(320, 300)
	var scene := Node3D.new()
	root.add_child(scene)
	var index := 0
	for pack_name in PACKS:
		var pack_dir := repo.path_join("resource_packs").path_join(pack_name)
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pack_dir.path_join("pack.json")))
		for output in manifest.outputs:
			var document := GLTFDocument.new()
			var state := GLTFState.new()
			var path: String = pack_dir.path_join(output.path)
			assert(document.append_from_file(path, state) == OK, path)
			var model := document.generate_scene(state) as Node3D
			assert(model != null, path)
			scene.add_child(model)
			var mesh_list := collect(model)
			assert(not mesh_list.is_empty(), path)
			var box := AABB()
			var first := true
			var triangles := 0
			var slots := 0
			for mesh in mesh_list:
				var actual: AABB = mesh.global_transform * mesh.get_aabb()
				box = actual if first else box.merge(actual)
				first = false
				for surface in mesh.mesh.get_surface_count():
					var original := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
					if original != null:
						var matte := original.duplicate() as StandardMaterial3D
						matte.metallic = 0.0
						matte.roughness = 0.92
						mesh.set_surface_override_material(surface, matte)
					var count: int = mesh.mesh.surface_get_array_index_len(surface)
					triangles += (count if count > 0 else mesh.mesh.surface_get_array_len(surface)) / 3
					slots += 1
			var factor := minf(4.4 / maxf(box.size.x, box.size.z), 5.0 / maxf(box.size.y, 0.01))
			var position := Vector3(index * 50.0, 0, 0)
			model.scale *= factor
			model.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * factor
			var holder := Node3D.new()
			scene.add_child(holder)
			model.reparent(holder, false)
			var out_path := "artifacts/models/" + path.get_file()
			var export_document := GLTFDocument.new()
			var export_state := GLTFState.new()
			assert(export_document.append_from_scene(holder, export_state) == OK)
			assert(export_document.write_to_filesystem(export_state, derivative_dir.path_join(out_path)) == OK)
			scene.remove_child(holder)
			holder.free()
			var reload_document := GLTFDocument.new()
			var reload_state := GLTFState.new()
			assert(reload_document.append_from_file(derivative_dir.path_join(out_path), reload_state) == OK)
			model = reload_document.generate_scene(reload_state)
			scene.add_child(model)
			var derived_bounds := AABB()
			var derived_first := true
			for mesh in collect(model):
				var actual: AABB = mesh.global_transform * mesh.get_aabb()
				derived_bounds = actual if derived_first else derived_bounds.merge(actual)
				derived_first = false
			assert(not derived_first)
			assert(absf(derived_bounds.position.y) < 0.001, "Exported ground contact")
			assert(absf(derived_bounds.get_center().x) < 0.001 and absf(derived_bounds.get_center().z) < 0.001, "Exported center")
			assert(derived_bounds.size.x <= 4.401 and derived_bounds.size.z <= 4.401 and derived_bounds.size.y <= 5.001, "Exported footprint")
			model.position = position
			outputs.append({"assetId":"terrain.tabletop-foundation.v1." + path.get_file().get_basename(),"path":out_path,"format":"GLB","sha256":FileAccess.get_sha256(derivative_dir.path_join(out_path)),"sourceAssetId":output.assetId,"sourceSha256":output.sha256,"originPolicy":"bottom-center","forwardAxis":"source orientation preserved; pending review","scaleMeters":"uniform miniature profile; width/depth <=4.4 m and height <=5 m; not physical object scale","materialSlots":"source names preserved; matte override","collisionPolicy":"none; presentation only","lodPolicy":"single source detail; world proxy pending","thumbnailPolicy":"fixed orthographic contact sheet","selectionHook":"consumer owned","statusHook":"none"})
			source_members.append({"sourceAssetId":output.assetId,"sourcePack":manifest.packId,"sourceMember":output.sourceMember,"upstreamArchive":manifest.sourceLineage.upstreamArchive,"sha256":output.sha256})
			var label := Label3D.new()
			label.text = path.get_file().get_basename()
			label.font_size = 26
			label.pixel_size = 0.014
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.position = position + Vector3(0, -1.0, -2.0)
			scene.add_child(label)
			report.append({"assetId":output.assetId,"sha256":FileAccess.get_sha256(path),"boundsSourceUnits":[box.size.x,box.size.y,box.size.z],"sourceMinimum":[box.position.x,box.position.y,box.position.z],"triangles":triangles,"surfaceCount":slots,"reviewScale":factor,"reviewGroundOffset":-box.position.y * factor,"readiness":"source imported; consumer scale and pivot remain pending"})
			index += 1
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("25323b")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.7
	scene.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	scene.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9.5
	scene.add_child(camera)
	camera.current = true
	var folder := repo.path_join("docs/model-review")
	DirAccess.make_dir_recursive_absolute(folder)
	var sheet := Image.create(1600, 900, false, Image.FORMAT_RGBA8)
	for i in index:
		var center := Vector3(i * 50.0, 1.5, 0)
		camera.position = center + Vector3(6, 5, -6)
		camera.look_at(center)
		await process_frame
		await process_frame
		RenderingServer.force_draw(false)
		var frame := root.get_texture().get_image()
		frame.convert(Image.FORMAT_RGBA8)
		assert(frame.get_size() == Vector2i(320, 300))
		sheet.blit_rect(frame, Rect2i(0, 0, 320, 300), Vector2i((i % 5) * 320, (i / 5) * 300))
	assert(sheet.save_png(folder.path_join("foundation-contact-sheet.png")) == OK)
	var file := FileAccess.open(folder.path_join("foundation-measurements.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"camera":"fixed orthographic; review framing, not consumer admission", "assets":report},"\t") + "\n")
	file.close()
	var pack := {"packId":"terrain.tabletop-foundation.v1","displayName":"Tabletop Foundation Miniature Profile","packType":"terrain","authoringStatus":"derivative","engineEligibility":"candidate_imported_not_consumer_approved","style":{"renderLanguage":["tabletop","matte","low_poly"],"sceneRoles":["coast","river","wetland","cave_approach","dock_dressing"]},"sourceLineage":{"kind":"CC0_derived","upstreamLicenseSpdx":"CC0-1.0","sourceMembers":source_members},"outputs":outputs,"review":{"legal":"CC0 source lineage retained","literalSemantics":"source identity retained; no game lore","technical":"reimported after uniform scale, pivot normalization and matte material override","visual":"contact sheet pending recorded review","reviewer":"Codex","createdAt":"2026-09-05"},"searchTags":["terrain","coast","riverine","miniature","matte","normalized"]}
	file = FileAccess.open(derivative_dir.path_join("pack.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(pack,"\t") + "\n")
	file.close()
	file = FileAccess.open(derivative_dir.path_join("build-report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"tool":"tools/review-model-packs.gd","transform":"uniform fit <=4.4m horizontal/5m height, bottom-center, metallic=0 roughness=0.92; textures and names preserved","sources":source_members,"outputs":outputs},"\t") + "\n")
	file.close()
	print("Imported and measured %d models" % index)
	quit()
