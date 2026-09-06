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
	editor.status.text = "Test fixture only—not approved character art.\n"+result
	if DisplayServer.get_name() != "headless":
		for i in 8:
			await process_frame
		RenderingServer.force_draw(false)
		check(root.get_texture().get_image().save_png(args[1]+".png") == OK,"render workshop")
	print("Workshop failures: ",failures)
	quit(0 if failures == 0 else 1)

