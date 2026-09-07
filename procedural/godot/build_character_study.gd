extends SceneTree
## Bounded authoring caller of the canonical character workshop, not a second builder.
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or FileAccess.file_exists(args[0]):
		quit(2)
		return
	var editor = load("res://character-workshop.tscn").instantiate()
	root.add_child(editor)
	await process_frame
	editor.open_prepared_body("female")
	if editor.model == null or editor.outfit.profile.is_empty():
		push_error("Prepared shared female body/profile unavailable")
		quit(1)
		return
	var recipe: Dictionary = editor.make_recipe()
	recipe.name = "Cyberpunk adult character study"
	recipe.height = 1.68
	recipe.outfit.slots["Clothes"] = "Formal separates"
	recipe.outfit.slots["Outerwear"] = "No cloak"
	recipe.outfit.slots["Headwear"] = "Bare head"
	recipe.outfit.slots["Hairstyle"] = "Braid"
	for key in recipe.outfit.morphs:
		recipe.outfit.morphs[key] = 0.0
	recipe.outfit.morphs["Oval face"] = 0.15
	recipe.outfit.morphs["Full cheeks"] = 0.1
	recipe.outfit.morphs["Lean"] = 0.15
	recipe.outfit.dyes["Formal top"] = "101820ff"
	recipe.outfit.dyes["Formal bottom"] = "11131bff"
	recipe.outfit.dyes["Hair"] = "141a23ff"
	var error: String = editor.apply_recipe(recipe)
	if not error.is_empty():
		push_error(error)
		quit(1)
		return
	editor.save_recipe(args[0].get_basename()+".appearance.json")
	if not editor.export_portable_character(args[0]):
		push_error(editor.status.text)
		quit(1)
		return
	print("CHARACTER_STUDY_EXPORT_PASS requested_age=18 adult=true art_approval=pending")
	quit(0)
