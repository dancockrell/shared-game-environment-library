extends SceneTree
var failures := 0
func _init() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
	else:
		print("PASS ",label)
func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1 and args[0] == "--review-only":
		var workshop = load("res://character-workshop.gd")
		check(workshop.build_review_text(null).begins_with("Invalid"), "reject null review")
		var review := {"changes":[],"views":[],"rendered":false,"source_blend_sha256":"a".repeat(64)}
		var text: String = workshop.build_review_text(review)
		check(text.contains("Build only") and text.contains("NOT ART APPROVAL"), "build receipt cannot imply visual approval")
		review.rendered = true
		check(workshop.build_review_text(review).begins_with("Invalid"), "reject rendered receipt without views")
		review.views = [{"view":"whole-eye"}]
		check(workshop.build_review_text(review).contains("Rendered views recorded"), "render state is explicit")
		review.changes = [null]
		check(workshop.build_review_text(review).begins_with("Invalid"), "reject malformed change")
		check(workshop.load_review_image("user://", "../outside") == null, "reject preview traversal")
		check(workshop.load_review_image("user://", "missing-review-image") == null, "missing preview is explicit")
		if args.size() == 2:
			var editor = workshop.new()
			root.add_child(editor)
			await process_frame
			var before: int = editor.stage.get_child_count()
			editor.show_build_review(args[1])
			await process_frame
			var dialogs: Array = editor.find_children("*", "AcceptDialog", false, false)
			check(dialogs.size() == 1, "actual review opens Workshop dialog")
			if dialogs.size() == 1:
				var reports = dialogs[0].find_children("*", "TextEdit", true, false)
				check(reports.size() == 1 and not reports[0].editable and not reports[0].text.begins_with("Invalid"), "actual receipt displayed read-only")
				var previews = dialogs[0].find_children("BuildRenderPreview", "TextureRect", true, false)
				var loaded: Image = workshop.load_review_image(args[1].get_base_dir(), "whole-eye")
				check(loaded != null and loaded.get_width() == 640, "actual review PNG decoded at source resolution")
				check(previews.size() == 1 and previews[0].texture != null, "actual review PNG assigned to preview")
			check(editor.model == null and editor.stage.get_child_count() == before, "review leaves character scene unchanged")
			editor.queue_free()
			await process_frame
		quit(0 if failures == 0 else 1)
		return
	if args.size()<2:
		quit(2)
		return
	root.size = Vector2i(1280,850)
	var scene := load("res://character-workshop.tscn") as PackedScene
	if scene == null:
		quit(2)
		return
	var editor := scene.instantiate()
	root.add_child(editor)
	await process_frame
	if args[0].get_extension() == "scn" or args[0].ends_with(".character.json"):
		var actor: Node3D
		if args[0].ends_with(".character.json"):
			var result: Dictionary = preload("res://addons/shared_character_builder/character_package.gd").instantiate_package(args[0])
			if result.error.is_empty():
				actor = result.actor
			else:
				printerr(result.error)
		else:
			var packed := ResourceLoader.load(args[0],"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
			if packed != null:
				actor = packed.instantiate() as Node3D
		check(actor != null,"standalone exported actor loads")
		if actor == null:
			quit(1)
			return
		editor.stage.add_child(actor)
		var is_batch := actor.name == "CharacterBatch"
		var appearance: Dictionary = actor.get_child(0).get_meta("appearance") if is_batch else actor.get_meta("appearance")
		check(actor.find_child("Skeleton3D",true,false) != null,"standalone actor has rig")
		for mesh in actor.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh == null:
				check(mesh.skin == null and mesh.material_override == null and mesh.material_overlay == null,"unused visual resources are absent: "+str(mesh.name))
				continue
			check(mesh.mesh != null and mesh.get_active_material(0) != null,"standalone geometry and material: "+str(mesh.name))
			for surface in mesh.mesh.get_surface_count():
				var material = mesh.get_active_material(surface)
				if material is BaseMaterial3D:
					for channel in BaseMaterial3D.TEXTURE_MAX:
						var texture: Texture2D = material.get_texture(channel)
						if texture != null:
							check(texture.get_image().has_mipmaps(),"standalone texture retains mipmaps: "+str(mesh.name)+" / "+str(channel))
		editor.camera.size = appearance.height*1.5
		editor.camera.position = Vector3(0,appearance.height*.6,appearance.height*3)
		editor.camera.look_at(Vector3(0,appearance.height*.5,0))
		editor.status.text = "Standalone exported character.\nNo source GLB or wardrobe profile loaded."
		if is_batch:
			for i in actor.get_child_count():
				actor.get_child(i).position = Vector3((i%3-1)*1.4,(1-i/3)*2.1,0)
			editor.camera.size = 4.8
			editor.camera.position = Vector3(0,2,8)
			editor.camera.look_at(Vector3(0,2,0))
			editor.status.text = "Standalone NPC batch: %d actors.\nReview layout only; no population simulation." % actor.get_child_count()
		if DisplayServer.get_name() != "headless":
			for i in 8:
				await process_frame
			RenderingServer.force_draw(false)
			check(root.get_texture().get_image().save_png(args[1]+".png") == OK,"render standalone export")
		print("Standalone export failures: ",failures)
		quit(0 if failures == 0 else 1)
		return
	var result: String = editor.import_model(args[0])
	check(editor.model != null,"real GLB import")
	if editor.model == null:
		print(result)
		quit(1)
		return
	editor.status.text = result
	var baseline: Dictionary = editor.make_recipe()
	var altered := baseline.duplicate(true)
	altered.name = "Roundtrip test"
	altered.height = 1.6
	var key: String = altered.parts.keys()[0]
	altered.parts[key] = false
	check(editor.apply_recipe(altered).is_empty(),"apply valid appearance")
	check(editor.make_recipe().parts[key] == false,"part visibility applies")
	check(is_equal_approx(editor.target_height,1.6),"height applies")
	var bad := baseline.duplicate(true)
	bad.sourceSha256 = "wrong"
	var before: Dictionary = editor.make_recipe()
	check(not editor.apply_recipe(bad).is_empty(),"reject different source")
	check(editor.make_recipe() == before,"hash rejection is atomic")
	bad = baseline.duplicate(true)
	bad.parts[key] = "not-a-boolean"
	check(not editor.apply_recipe(bad).is_empty(),"reject malformed part")
	check(editor.make_recipe() == before,"part rejection is atomic")
	bad = baseline.duplicate(true)
	bad.height = -5
	check(not editor.apply_recipe(bad).is_empty(),"reject invalid scale")
	check(editor.make_recipe() == before,"scale rejection is atomic")
	editor.save_recipe(args[1]+".json")
	check(FileAccess.file_exists(args[1]+".json"),"save appearance")
	editor.apply_recipe(baseline)
	editor.load_recipe(args[1]+".json")
	check(editor.make_recipe() == before,"file roundtrip")
	var old_model: Node = editor.model
	editor.import_model("C:/missing-character.glb")
	check(editor.model == old_model,"failed import retains character")
	editor.apply_recipe(baseline)
	var profile := {"schemaVersion":1,"sourceSha256":editor.source_hash,"slots":{"Fixture part":{"Shown":{"meshes":[key],"hides":[]},"Hidden":{"meshes":[],"hides":[]}}},"morphs":{},"dyes":{}}
	check(editor.outfit.configure(profile,editor.parts,editor.shapes,editor.source_hash).is_empty(),"configure profile in real editor")
	editor.refresh_controls()
	var dressed: Dictionary = editor.make_recipe()
	dressed.outfit.slots["Fixture part"] = "Hidden"
	check(editor.apply_recipe(dressed).is_empty() and not editor.parts[key].visible,"outfit recipe drives editor visibility")
	before = editor.make_recipe()
	bad = before.duplicate(true)
	bad.height = 2.1
	bad.outfit.profileSha256 = "wrong"
	check(not editor.apply_recipe(bad).is_empty() and editor.make_recipe() == before,"outfit failure leaves entire editor unchanged")
	editor.save_recipe(args[1]+".json")
	editor.load_recipe(args[1]+".json")
	check(editor.make_recipe() == before,"outfit file roundtrip")
	dressed.outfit.slots["Fixture part"] = "Shown"
	editor.apply_recipe(dressed)
	editor.status.text = "Test fixture only—not approved character art.\n"+result
	if args.size() == 3:
		editor.import_model(args[0])
		editor.load_outfit_profile(args[2])
		check(not editor.outfit.profile.is_empty(),"load authored source profile")
		if editor.outfit.profile.is_empty():
			printerr(editor.status.text)
			quit(1)
			return
		var measured_height: float = editor.source_height
		editor.outfit.selections.Headwear = "Felt hat"
		editor.outfit.selections.Outerwear = "Long travelling cloak"
		editor.outfit.apply()
		check(is_equal_approx(editor.source_height,measured_height),"clothing cannot alter measured body height")
		var vertical: Vector2 = editor.outfit.body_vertical_bounds()
		check(is_equal_approx((vertical.y-vertical.x)*editor.pivot.scale.y,editor.target_height) and is_zero_approx(editor.model.position.y+vertical.x),"source body is correctly scaled and grounded")
		var unvaried: Dictionary = editor.make_recipe()
		editor.create_variation("npc-001")
		var first_variation: Dictionary = editor.make_recipe()
		editor.create_variation("npc-002")
		check(editor.make_recipe().outfit.morphs != first_variation.outfit.morphs,"different NPC seeds vary real body and face controls")
		editor.create_variation("npc-001")
		check(editor.make_recipe() == first_variation,"NPC seed reproduces appearance")
		check(first_variation.name == unvaried.name and first_variation.height == unvaried.height,"variation preserves identity and height")
		check(first_variation.outfit.morphs["Pointed ears"] == unvaried.outfit.morphs["Pointed ears"],"variation preserves explicit species trait")
		check(first_variation.outfit.morphs["Narrow chin"] == 0 or first_variation.outfit.morphs["Broad jaw"] == 0,"seeded variation avoids opposing jaw controls")
		for control in editor.outfit.profile.variationCaps:
			check(first_variation.outfit.morphs[control] <= editor.outfit.profile.variationCaps[control],"seeded face respects authored cap: "+control)
		for slot in editor.outfit.profile.variationChoices:
			check(first_variation.outfit.slots[slot] in editor.outfit.profile.variationChoices[slot],"seeded appearance uses curated choices: "+slot)
		editor.focus_face()
		check(editor.camera.size < editor.target_height*.5,"face view focuses on the head")
		editor.frame_model()
		editor.create_variation("")
		check(editor.make_recipe() == first_variation,"blank seed rejected atomically")
		editor.save_recipe(args[1]+".json")
		editor.load_recipe(args[1]+".json")
		check(editor.make_recipe() == first_variation,"variation provenance roundtrip")
		var population: PackedScene = editor.build_population("population-test",6)
		check(population != null and editor.make_recipe() == first_variation,"batch creation preserves edited character")
		var batch: Node3D = population.instantiate()
		check(batch.get_child_count() == 6,"batch contains requested number of actors")
		var unique_shapes := {}
		for i in batch.get_child_count():
			var actor := batch.get_child(i)
			check(actor.get_meta("variation_id") == "population-test:"+str(i),"batch actor has stable variation ID "+str(i))
			check(actor.get_meta("appearance").name.is_empty(),"batch leaves narrative identity to consumer "+str(i))
			unique_shapes[JSON.stringify(actor.get_meta("appearance").outfit.morphs)] = true
		check(unique_shapes.size() == 6,"batch actors have distinct generated morphology")
		check(editor.build_population("population-test",65) == null and editor.make_recipe() == first_variation,"oversized batch rejected without changing character")
		batch.free()
		editor.export_population(args[1]+"-batch.scn","population-test",6)
		var batch_resource := ResourceLoader.load(args[1]+"-batch.scn","PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		check(batch_resource != null and ResourceLoader.get_dependencies(args[1]+"-batch.scn").is_empty(),"batch file is self-contained")
		var loaded_batch := batch_resource.instantiate()
		check(loaded_batch.get_child_count() == 6,"batch actors survive file roundtrip")
		loaded_batch.free()
		editor.apply_recipe(unvaried)
		var prepared_before: Dictionary = editor.make_recipe()
		editor.open_prepared_body("unknown")
		check(editor.make_recipe() == prepared_before,"invalid prepared body preserves appearance")
		editor.open_prepared_body("female" if args[0].get_file().begins_with("female") else "male")
		check(not editor.outfit.profile.is_empty() and editor.source_hash == prepared_before.sourceSha256,"prepared body opens matching wardrobe automatically")
		var body_mesh: MeshInstance3D = editor.parts["Skeleton3D/Body01"]
		var garment: MeshInstance3D = editor.parts["Skeleton3D/Outfit01"]
		for shape_index in range(2,body_mesh.get_blend_shape_count()):
			var points: PackedVector3Array = body_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var target: PackedVector3Array = body_mesh.mesh.surface_get_blend_shape_arrays(0)[shape_index][Mesh.ARRAY_VERTEX]
			var displacement := 0.0
			for i in points.size():
				displacement = maxf(displacement,points[i].distance_to(target[i]))
			check(displacement > .0001,"face geometry target: "+body_mesh.mesh.get_blend_shape_name(shape_index))
		for part in [body_mesh,garment]:
			var deltas: PackedVector3Array = part.mesh.surface_get_blend_shape_arrays(0)[0][Mesh.ARRAY_VERTEX]
			var original: PackedVector3Array = part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var largest := 0.0
			for i in deltas.size():
				var delta := deltas[i]
				if part.mesh.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_NORMALIZED:
					delta -= original[i]
				largest = maxf(largest,delta.length())
			check(largest > .001,"nonzero fitted body target: "+str(part.name))
			check(part.skin != null and part.skin.get_bind_count() == 163,"source skin retained: "+str(part.name))
		editor.outfit.morphs.Lean = 1.0
		editor.outfit.apply()
		check(is_equal_approx(body_mesh.get_blend_shape_value(0),1.0) and is_equal_approx(garment.get_blend_shape_value(0),1.0),"real body and outfit share target weight")
		editor.outfit.selections.Clothes = "Casual 02"
		editor.outfit.apply()
		check(not body_mesh.visible and editor.parts["Skeleton3D/Body02"].visible and not garment.visible,"real outfit swaps its masked body")
		editor.save_recipe(args[1]+".json")
		var fitted_recipe: Dictionary = editor.make_recipe()
		editor.load_recipe(args[1]+".json")
		check(editor.make_recipe() == fitted_recipe,"fitted wardrobe recipe roundtrip")
		var export_before: Dictionary = editor.make_recipe()
		editor.outfit.colors.Clothing = "8060c0ff"
		editor.outfit.apply()
		editor.target_height = 1.53
		editor.frame_model()
		editor.pivot.rotation.y = .7
		var export_recipe: Dictionary = editor.make_recipe()
		var source_transform: Transform3D = editor.model.transform
		editor.model.position += Vector3(2,0,0)
		var source_rig: Skeleton3D = editor.model.find_child("Skeleton3D",true,false)
		var preview_rotation := Quaternion(Vector3.UP,.4)
		source_rig.set_bone_pose_rotation(0,preview_rotation)
		var built: PackedScene = editor.build_character()
		check(built != null,"build portable character")
		var actor: Node3D = built.instantiate()
		var actor_body: Node3D = actor.get_child(0)
		check(actor_body.transform == source_transform,"export restores source node transform")
		var actor_rig: Skeleton3D = actor_body.find_child("Skeleton3D",true,false)
		check(actor_rig.get_bone_pose_rotation(0).is_equal_approx(Quaternion.IDENTITY),"export restores skeleton rest pose")
		check(source_rig.get_bone_pose_rotation(0).is_equal_approx(preview_rotation) and editor.model.position == source_transform.origin+Vector3(2,0,0),"export does not reset live preview")
		editor.model.transform = source_transform
		source_rig.reset_bone_poses()
		var actor_garment: MeshInstance3D = actor_body.get_node("Skeleton3D/Outfit02")
		check(actor_garment.visible and actor_body.get_node("Skeleton3D/Outfit01").mesh == null,"built actor retains selected wardrobe without unused geometry")
		var exported_geometry: Dictionary = actor.get_meta("export_geometry")
		check(exported_geometry.retained_meshes < exported_geometry.source_meshes and exported_geometry.retained_vertices < exported_geometry.source_vertices,"export measurably reduces retained geometry")
		check(editor.parts["Skeleton3D/Outfit01"].mesh != null,"export trimming preserves editable alternatives")
		print("Selected export geometry: ",exported_geometry)
		check(is_equal_approx(actor.scale.y,1.53/editor.source_height) and actor.rotation == Vector3.ZERO,"actor keeps height without preview rotation")
		check(actor_garment.get_blend_shape_count() == 0 and garment.get_blend_shape_count() > 0,"construction shapes bake only into export")
		var source_arrays: Array = editor.parts["Skeleton3D/Outfit02"].mesh.surface_get_arrays(0)
		var baked_arrays: Array = actor_garment.mesh.surface_get_arrays(0)
		check(baked_arrays[Mesh.ARRAY_BONES] == source_arrays[Mesh.ARRAY_BONES] and baked_arrays[Mesh.ARRAY_WEIGHTS] == source_arrays[Mesh.ARRAY_WEIGHTS],"baked construction preserves skin influences")
		var shape_reference: Array = editor.parts["Skeleton3D/Outfit02"].bake_mesh_from_current_blend_shape_mix().surface_get_arrays(0)
		check(baked_arrays[Mesh.ARRAY_VERTEX] == shape_reference[Mesh.ARRAY_VERTEX],"export retains the selected deformed geometry")
		var selected_source: MeshInstance3D = editor.parts["Skeleton3D/Outfit02"]
		var expected_vertices: PackedVector3Array = source_arrays[Mesh.ARRAY_VERTEX].duplicate()
		for shape in selected_source.get_blend_shape_count():
			var weight := selected_source.get_blend_shape_value(shape)
			var target: PackedVector3Array = selected_source.mesh.surface_get_blend_shape_arrays(0)[shape][Mesh.ARRAY_VERTEX]
			for vertex in expected_vertices.size():
				expected_vertices[vertex] += (target[vertex]-source_arrays[Mesh.ARRAY_VERTEX][vertex])*weight
		var mix_error := 0.0
		for vertex in expected_vertices.size():
			mix_error = maxf(mix_error,expected_vertices[vertex].distance_to(baked_arrays[Mesh.ARRAY_VERTEX][vertex]))
		check(mix_error < .00005,"baked vertices match independent normalized-shape calculation")
		var construction_controls: Array = editor.outfit.profile.constructionMorphs
		editor.outfit.profile.constructionMorphs = []
		check(editor.bake_export_shapes(selected_source) == null,"unclassified animation shapes are not frozen")
		editor.outfit.profile.constructionMorphs = construction_controls
		var export_color: Color = actor_garment.get_active_material(0).albedo_color
		editor.outfit.colors.Clothing = "ffffffff"
		editor.outfit.apply()
		check(actor_garment.get_active_material(0).albedo_color == export_color,"built material is isolated from editor")
		check(actor.get_meta("appearance") == export_recipe,"actor embeds source and appearance provenance")
		check(actor.find_children("*","Control",true,false).is_empty() and actor.find_children("*","Camera3D",true,false).is_empty(),"actor excludes workshop UI and camera")
		actor.free()
		var hidden_group := Node3D.new()
		hidden_group.name = "HiddenExportFixture"
		hidden_group.visible = false
		editor.model.add_child(hidden_group)
		var hidden_visual := MeshInstance3D.new()
		hidden_visual.name = "Visual"
		hidden_visual.mesh = BoxMesh.new()
		hidden_visual.material_override = StandardMaterial3D.new()
		hidden_group.add_child(hidden_visual)
		var attachment := Node3D.new()
		attachment.name = "Attachment"
		attachment.position = Vector3(.1,.2,.3)
		hidden_visual.add_child(attachment)
		var nested_actor: Node3D = editor.build_character().instantiate()
		var nested_visual := nested_actor.find_child("HiddenExportFixture",true,false).get_node("Visual") as MeshInstance3D
		check(nested_visual.mesh == null and nested_visual.material_override == null and nested_visual.get_node("Attachment").position == attachment.position,"inherited-hidden geometry is trimmed without deleting attachment structure")
		check(hidden_visual.mesh != null and hidden_visual.material_override != null,"inherited-hidden trimming leaves source resources intact")
		nested_actor.free()
		hidden_group.free()
		editor.apply_recipe(export_recipe)
		editor.export_character(args[1]+".scn")
		check(editor.export_portable_character(args[1]+"-portable.glb"),"export portable character package")
		var portable_manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]+"-portable.character.json"))
		check(portable_manifest.modelSha256 == FileAccess.get_sha256(args[1]+"-portable.glb"),"portable manifest binds exact model bytes")
		check(editor.apply_recipe(portable_manifest.appearance).is_empty() and editor.make_recipe() == export_recipe,"portable manifest restores exact appearance through recipe validation")
		var package_loader = preload("res://addons/shared_character_builder/character_package.gd")
		var package_result: Dictionary = package_loader.instantiate_package(args[1]+"-portable.character.json")
		check(package_result.error.is_empty(),"Godot integration imports verified portable package")
		if not package_result.error.is_empty():
			printerr(package_result.error)
			quit(1)
			return
		var portable_actor: Node3D = package_result.actor
		var portable_rig := portable_actor.find_child("Skeleton3D",true,false) as Skeleton3D
		check(portable_rig != null and portable_rig.get_bone_count() == 163,"portable GLB preserves skeleton")
		var portable_meshes := 0
		for mesh in portable_actor.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh != null:
				portable_meshes += 1
				if str(mesh.name) in ["ShortCloak","LongCloak","Tabard"]:
					var fabric: StandardMaterial3D = mesh.get_active_material(0)
					check(fabric != null and fabric.normal_enabled and fabric.normal_texture != null and fabric.roughness_texture != null,"portable GLB preserves generated fabric maps")
					check(fabric.normal_texture.get_image().has_mipmaps(),"portable import restores normal-map mip levels")
		check(portable_meshes == portable_manifest.geometry.retained_meshes,"portable GLB contains only retained visual resources")
		check(portable_actor.get_meta("art_status") == portable_manifest.artStatus,"Godot integration preserves art admission status")
		var portable_packed := PackedScene.new()
		check(portable_packed.pack(portable_actor) == OK,"Godot plugin can pack imported character")
		var portable_copy := portable_packed.instantiate()
		check(portable_copy.find_children("*","MeshInstance3D",true,false).size() == portable_meshes,"Godot packed import preserves all retained meshes")
		portable_copy.free()
		var bad_path := args[1]+"-invalid.character.json"
		for changes in [{"model":"../other.glb"},{"model":"C:\\other.glb"},{"modelSha256":"0".repeat(64)},{"schemaVersion":2},{"units":"centimetres"},{"appearance":null}]:
			var invalid: Dictionary = portable_manifest.duplicate(true)
			invalid.merge(changes,true)
			var bad_file := FileAccess.open(bad_path,FileAccess.WRITE)
			bad_file.store_string(JSON.stringify(invalid))
			bad_file.close()
			check(not package_loader.read_package(bad_path).error.is_empty(),"portable package rejects invalid "+str(changes.keys()))
		DirAccess.remove_absolute(bad_path)
		portable_actor.free()
		check(FileAccess.file_exists(args[1]+".scn"),"export bundled Godot scene")
		check(ResourceLoader.get_dependencies(args[1]+".scn").is_empty(),"export has no external resource dependencies")
		var reloaded := ResourceLoader.load(args[1]+".scn","PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		check(reloaded != null,"reload exported scene")
		if reloaded != null:
			var loaded_actor := reloaded.instantiate()
			check(loaded_actor.get_meta("appearance") == export_recipe,"exported appearance roundtrip")
			var loaded_rig: Skeleton3D = loaded_actor.find_child("Skeleton3D",true,false)
			check(loaded_rig != null and loaded_rig.get_bone_count() == 163,"exported skeleton roundtrip")
			loaded_actor.free()
		editor.apply_recipe(export_before)
		editor.pivot.rotation = Vector3.ZERO
		editor.outfit.morphs.Lean = 0.0
		editor.outfit.selections.Clothes = "Casual 01"
		editor.outfit.apply()
		editor.save_recipe(args[1]+".json")
		editor.refresh_controls()
		editor.status.text = "Source assembly review—not approved art.\nFitted source meshes; linked body shapes."
	if DisplayServer.get_name() != "headless":
		for i in 8:
			await process_frame
		RenderingServer.force_draw(false)
		check(root.get_texture().get_image().save_png(args[1]+".png") == OK,"render workshop")
		if args.size() == 3:
			var rig: Skeleton3D = editor.model.find_child("Skeleton3D",true,false)
			var arm := -1
			for i in rig.get_bone_count():
				if rig.get_bone_name(i).replace(".","_") == "upperarm01_L":
					arm = i
			check(arm >= 0,"imported upper arm bone available")
			if arm >= 0:
				var garment: MeshInstance3D = editor.parts["Skeleton3D/Outfit01"]
				var rest := garment.bake_mesh_from_current_skeleton_pose()
				rig.set_bone_pose_rotation(arm,Quaternion(Vector3.FORWARD,.6))
				for i in 8:
					await process_frame
				var posed := garment.bake_mesh_from_current_skeleton_pose()
				var before_points: PackedVector3Array = rest.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				var after_points: PackedVector3Array = posed.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				var moved := 0.0
				for i in before_points.size():
					moved = maxf(moved,before_points[i].distance_to(after_points[i]))
				check(moved > .01,"garment vertices move with arm bone")
				editor.outfit.morphs.Lean = 1.0
				editor.outfit.apply()
				editor.refresh_controls()
				for i in 8:
					await process_frame
				RenderingServer.force_draw(false)
				check(root.get_texture().get_image().save_png(args[1]+"-posed.png") == OK,"render lean posed garment")
				rig.reset_bone_poses()
				editor.camera.size = .58
				var face_y: float = editor.target_height*.91
				editor.camera.position = Vector3(0,face_y,3)
				editor.camera.look_at(Vector3(0,face_y,0))
				for seed_text in ["npc-001","npc-002"]:
					editor.create_variation(seed_text)
					for i in 8:
						await process_frame
					editor.focus_face()
					for i in 3:
						await process_frame
					RenderingServer.force_draw(false)
					check(root.get_texture().get_image().save_png(args[1]+"-"+seed_text+".png") == OK,"render seeded face "+seed_text)
				editor.outfit.morphs["Pointed ears"] = 1.0
				editor.outfit.apply()
				editor.refresh_controls()
				editor.focus_face()
				for i in 3:
					await process_frame
				RenderingServer.force_draw(false)
				check(root.get_texture().get_image().save_png(args[1]+"-ears.png") == OK,"render pointed ears")
				editor.outfit.selections.Clothes = "Formal separates"
				editor.outfit.selections.Hairstyle = "Source default"
				editor.outfit.selections.Headwear = "Felt hat"
				editor.outfit.colors["Formal top"] = "ac8654ff"
				editor.outfit.colors["Formal bottom"] = "605850ff"
				editor.outfit.apply()
				check(editor.parts["Skeleton3D/Body03"].visible and editor.parts["Skeleton3D/FormalTop"].visible and editor.parts["Skeleton3D/FormalBottom"].visible and not editor.parts["Skeleton3D/Body01"].visible,"formal clothes select their fitted masked body")
				check(editor.parts["Skeleton3D/Hat"].visible and not editor.parts["Skeleton3D/Hair"].visible,"headwear applies hair exclusion")
				check(editor.parts["Skeleton3D/FormalTop"].get_active_material(0).albedo_color != editor.parts["Skeleton3D/FormalBottom"].get_active_material(0).albedo_color,"separate garments have independent dyes")
				editor.refresh_controls()
				editor.frame_model()
				for i in 5:
					await process_frame
				RenderingServer.force_draw(false)
				check(root.get_texture().get_image().save_png(args[1]+"-formal.png") == OK,"render formal outfit and hat")
				editor.outfit.selections.Headwear = "Bare head"
				editor.outfit.apply()
				check(not editor.parts["Skeleton3D/Hat"].visible and editor.parts["Skeleton3D/Hair"].visible,"removing headwear restores hair")
				for cut in ["Short travelling cloak","Long travelling cloak","Open-sided tabard"]:
					editor.outfit.selections.Outerwear = cut
					editor.outfit.colors.Cloak = "668dadff"
					editor.outfit.apply()
					editor.refresh_controls()
					var long_cut: bool = cut.begins_with("Long")
					var tabard_cut: bool = cut == "Open-sided tabard"
					var garment_name := "Tabard" if tabard_cut else ("LongCloak" if long_cut else "ShortCloak")
					for candidate in ["Tabard","LongCloak","ShortCloak"]:
						check(editor.parts["Skeleton3D/"+candidate].visible == (candidate == garment_name),"outer garment selection is exclusive: "+cut+" / "+candidate)
					var cloak: MeshInstance3D = editor.parts["Skeleton3D/"+garment_name]
					check(cloak.mesh.get_blend_shape_count() == editor.outfit.profile.morphs.size() and cloak.skin.get_bind_count() == 163,"cloak retains linked fit shapes and rig: "+cut)
					check(cloak.mesh.get_surface_count() == 2,"cloak has separately constructed border: "+cut)
					var cloth_arrays: Array = cloak.mesh.surface_get_arrays(0)
					var border_arrays: Array = cloak.mesh.surface_get_arrays(1)
					var seam_normals := {}
					for v in cloth_arrays[Mesh.ARRAY_VERTEX].size():
						seam_normals[var_to_str(cloth_arrays[Mesh.ARRAY_VERTEX][v])] = cloth_arrays[Mesh.ARRAY_NORMAL][v]
					var seam_count := 0
					var seam_error := 0.0
					for v in border_arrays[Mesh.ARRAY_VERTEX].size():
						var point_key := var_to_str(border_arrays[Mesh.ARRAY_VERTEX][v])
						if seam_normals.has(point_key):
							seam_count += 1
							seam_error = maxf(seam_error,seam_normals[point_key].distance_to(border_arrays[Mesh.ARRAY_NORMAL][v]))
					check(seam_count > 0 and seam_error < .001,"cloth and border share smooth seam normals: "+cut)
					var orientation_ok := true
					for surface_arrays in [cloth_arrays,border_arrays]:
						var indices: Variant = surface_arrays[Mesh.ARRAY_INDEX]
						if indices == null or indices.is_empty():
							indices = range(surface_arrays[Mesh.ARRAY_VERTEX].size())
						for face in range(0,indices.size(),3):
							var a: Vector3 = surface_arrays[Mesh.ARRAY_VERTEX][indices[face]]
							var b: Vector3 = surface_arrays[Mesh.ARRAY_VERTEX][indices[face+1]]
							var c: Vector3 = surface_arrays[Mesh.ARRAY_VERTEX][indices[face+2]]
							var expected := -(b-a).cross(c-a).normalized()
							var average: Vector3 = surface_arrays[Mesh.ARRAY_NORMAL][indices[face]]+surface_arrays[Mesh.ARRAY_NORMAL][indices[face+1]]+surface_arrays[Mesh.ARRAY_NORMAL][indices[face+2]]
							if expected.dot(average.normalized()) <= 0:
								orientation_ok = false
					check(orientation_ok,"cloak normals agree with triangle winding: "+cut)
					var cloth_color: Color = cloak.get_active_material(0).albedo_color
					editor.outfit.colors["Tabard border" if tabard_cut else "Cloak border"] = "eddcc0ff"
					editor.outfit.apply()
					check(cloak.get_active_material(0).albedo_color == cloth_color and cloak.get_active_material(1).albedo_color != cloth_color,"border dye leaves cloak cloth unchanged: "+cut)
					if long_cut or tabard_cut:
						editor.export_character(args[1]+".scn")
						var saved := ResourceLoader.load(args[1]+".scn","PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
						var instance := saved.instantiate() if saved != null else null
						var exported_cloak := instance.find_child(garment_name,true,false) as MeshInstance3D if instance != null else null
						check(exported_cloak != null and exported_cloak.visible and exported_cloak.mesh.get_surface_count() == 2,"cloaked export retains selected garment and border")
						if instance != null:
							instance.free()
					for angle in ([0.65,1.57,2.8] if tabard_cut else [0.65,2.8]):
						editor.pivot.rotation.y = angle
						for i in 5:
							await process_frame
						RenderingServer.force_draw(false)
						var view_name := "front" if angle < 1 else ("side" if angle < 2 else "back")
						check(root.get_texture().get_image().save_png(args[1]+("-tabard" if tabard_cut else ("-long" if long_cut else "-short"))+"-"+view_name+".png") == OK,"render outer garment: "+cut+" / "+view_name)
				editor.outfit.selections.Outerwear = "No cloak"
				editor.outfit.apply()
				check(not editor.parts["Skeleton3D/LongCloak"].visible and not editor.parts["Skeleton3D/ShortCloak"].visible,"removing outerwear hides both cuts")
				editor.outfit.selections.Eyebrows = "Brow 01"
				editor.outfit.selections.Eyelashes = "Lashes 01"
				for control in ["Base face","Defined cheekbones","Full cheeks","Larger eyes","Broad jaw"]:
					for morph in editor.outfit.morphs:
						editor.outfit.morphs[morph] = 1.0 if morph == control else 0.0
					editor.outfit.apply()
					editor.pivot.rotation.y = .25
					editor.focus_face()
					editor.refresh_controls()
					for i in 5:
						await process_frame
					RenderingServer.force_draw(false)
					check(root.get_texture().get_image().save_png(args[1]+"-"+control.to_lower().replace(" ","-")+".png") == OK,"render isolated facial construction: "+control)
				for style in ["01","04"]:
					editor.outfit.selections.Eyebrows = "Brow 01" if style == "01" else "Brow 05"
					editor.outfit.selections.Eyelashes = "Lashes "+style
					editor.outfit.morphs["Broad jaw"] = 0
					editor.outfit.morphs["Larger eyes"] = .5
					editor.outfit.apply()
					editor.refresh_controls()
					var brow: MeshInstance3D = editor.parts["Skeleton3D/Brows001" if style == "01" else "Skeleton3D/Brows005"]
					var lashes: MeshInstance3D = editor.parts["Skeleton3D/Lashes"+style]
					check(brow.visible and lashes.visible and brow.get_blend_shape_count() == editor.outfit.profile.morphs.size(),"brow and lash style stays fitted: "+style)
					check(brow.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and lashes.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"source facial-hair shadow settings preserved: "+style)
					check(brow.get_active_material(0).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and lashes.get_active_material(0).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED,"facial hair retains texture transparency: "+style)
					for i in 5:
						await process_frame
					RenderingServer.force_draw(false)
					check(root.get_texture().get_image().save_png(args[1]+"-brows-lashes-"+style+".png") == OK,"render fitted brows and lashes: "+style)
				for style in editor.outfit.profile.slots.Hairstyle:
					editor.outfit.selections.Hairstyle = style
					editor.outfit.selections.Headwear = "Bare head"
					editor.outfit.apply()
					var selected: Array = editor.outfit.profile.slots.Hairstyle[style].meshes
					var all_hair: Array = editor.outfit.profile.slots.Headwear["Felt hat"].excludes
					for path in all_hair:
						check(editor.parts[path].visible == (path in selected),"exclusive hairstyle: "+style+" / "+path)
						editor.outfit.selections.Headwear = "Felt hat"
						editor.outfit.apply()
						check(not editor.parts[path].visible,"hat hides every hairstyle: "+style+" / "+path)
						editor.outfit.selections.Headwear = "Bare head"
						editor.outfit.apply()
					var hair_recipe: Dictionary = editor.make_recipe()
					var hair_actor: Node3D = editor.build_character().instantiate()
					for path in all_hair:
						var exported_hair := hair_actor.find_child(path.get_file(),true,false) as MeshInstance3D
						if path in selected:
							check(exported_hair != null and exported_hair.mesh != null and exported_hair.visible and exported_hair.skin.get_bind_count() == 163 and exported_hair.mesh.get_blend_shape_count() == 0,"export retains selected baked hairstyle: "+style+" / "+path)
						else:
							check(exported_hair != null and exported_hair.mesh == null and exported_hair.skin == null,"export removes unselected hairstyle resources: "+style+" / "+path)
					hair_actor.free()
					var hair_error: String = editor.apply_recipe(JSON.parse_string(JSON.stringify(hair_recipe,"",true,true)))
					var restored_hair: Dictionary = editor.make_recipe()
					check(hair_error.is_empty() and restored_hair == hair_recipe,"hairstyle recipe roundtrip: "+style)
					if not hair_error.is_empty():
						printerr(hair_error)
					for field in hair_recipe:
						if restored_hair.get(field) != hair_recipe[field]:
							printerr("Hair recipe mismatch ",field,": ",hair_recipe[field]," => ",restored_hair.get(field))
					editor.refresh_controls()
					editor.focus_face()
					editor.camera.size = .95
					editor.status.text = "Hair fitting review: "+style+"\nSource prototype; not approved character art."
					for angle in [.5,2.8]:
						editor.pivot.rotation.y = angle
						for i in 5:
							await process_frame
						RenderingServer.force_draw(false)
						var hair_view := "front" if angle < 1 else "back"
						check(root.get_texture().get_image().save_png(args[1]+"-hair-"+style.to_lower().replace(" ","-")+"-"+hair_view+".png") == OK,"render hairstyle: "+style+" / "+hair_view)
	print("Workshop failures: ",failures)
	quit(0 if failures == 0 else 1)
