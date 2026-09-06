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
	if args[0].get_extension() == "scn":
		var packed := ResourceLoader.load(args[0],"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		check(packed != null,"standalone exported actor loads")
		if packed == null:
			quit(1)
			return
		var actor := packed.instantiate() as Node3D
		editor.stage.add_child(actor)
		var is_batch := actor.name == "CharacterBatch"
		var appearance: Dictionary = actor.get_child(0).get_meta("appearance") if is_batch else actor.get_meta("appearance")
		check(actor.find_child("Skeleton3D",true,false) != null,"standalone actor has rig")
		for mesh in actor.find_children("*","MeshInstance3D",true,false):
			check(mesh.mesh != null and mesh.get_active_material(0) != null,"standalone geometry and material: "+str(mesh.name))
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
		var unvaried: Dictionary = editor.make_recipe()
		editor.create_variation("npc-001")
		var first_variation: Dictionary = editor.make_recipe()
		editor.create_variation("npc-002")
		check(editor.make_recipe().outfit.morphs != first_variation.outfit.morphs,"different NPC seeds vary real body and face controls")
		editor.create_variation("npc-001")
		check(editor.make_recipe() == first_variation,"NPC seed reproduces appearance")
		check(first_variation.name == unvaried.name and first_variation.height == unvaried.height,"variation preserves identity and height")
		check(first_variation.outfit.morphs["Pointed ears"] == unvaried.outfit.morphs["Pointed ears"],"variation preserves explicit species trait")
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
		check(actor_garment.visible and not actor_body.get_node("Skeleton3D/Outfit01").visible,"built actor keeps selected wardrobe")
		check(is_equal_approx(actor.scale.y,1.53/editor.source_height) and actor.rotation == Vector3.ZERO,"actor keeps height without preview rotation")
		check(is_equal_approx(actor_garment.get_blend_shape_value(0),1.0),"actor keeps body shape")
		var export_color: Color = actor_garment.get_active_material(0).albedo_color
		editor.outfit.colors.Clothing = "ffffffff"
		editor.outfit.apply()
		check(actor_garment.get_active_material(0).albedo_color == export_color,"built material is isolated from editor")
		check(actor.get_meta("appearance") == export_recipe,"actor embeds source and appearance provenance")
		check(actor.find_children("*","Control",true,false).is_empty() and actor.find_children("*","Camera3D",true,false).is_empty(),"actor excludes workshop UI and camera")
		actor.free()
		editor.apply_recipe(export_recipe)
		editor.export_character(args[1]+".scn")
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
	print("Workshop failures: ",failures)
	quit(0 if failures == 0 else 1)
