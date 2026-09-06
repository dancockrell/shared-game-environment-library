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
		var body_mesh: MeshInstance3D = editor.parts["Skeleton3D/Body01"]
		var garment: MeshInstance3D = editor.parts["Skeleton3D/Outfit01"]
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
	print("Workshop failures: ",failures)
	quit(0 if failures == 0 else 1)
