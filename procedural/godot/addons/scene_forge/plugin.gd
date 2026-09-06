@tool
extends EditorPlugin
const Importer = preload("import_scene.gd")
var dock: VBoxContainer
var executable: LineEdit
var dialog: EditorFileDialog
var status: Label
var worker: Thread
var export_dialog: EditorFileDialog
var export_source: String
func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Scene Forge"
	executable = LineEdit.new()
	executable.placeholder_text = "Path to scene-forge executable"
	executable.text = ProjectSettings.globalize_path("res://../target/release/scene-forge-cli.exe")
	dock.add_child(executable)
	var button := Button.new()
	button.text = "Compile recipe into scene"
	button.pressed.connect(func(): dialog.popup_centered_ratio())
	dock.add_child(button)
	var export_button := Button.new()
	export_button.text = "Export selected source recipe…"
	export_button.tooltip_text = "Original construction recipe; manual engine edits are not captured."
	export_button.pressed.connect(_choose_source_export)
	dock.add_child(export_button)
	export_dialog = EditorFileDialog.new()
	export_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	export_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	export_dialog.add_filter("*.json", "Scene Forge source recipe")
	export_dialog.file_selected.connect(_write_source_export)
	dock.add_child(export_dialog)
	status = Label.new()
	status.text = "Local CPU generation; no server"
	dock.add_child(status)
	dialog = EditorFileDialog.new()
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.json", "Scene Forge recipe")
	dialog.file_selected.connect(_compile)
	dock.add_child(dialog)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
func _choose_source_export() -> void:
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() != 1:
		status.text = "Select one imported scene or one of its parts"
		return
	var node: Node = selected[0]
	while node != null and not node.has_meta("scene_forge_recipe_json"):
		node = node.get_parent()
	export_source = "" if node == null else str(node.get_meta("scene_forge_recipe_json", ""))
	if export_source.is_empty():
		status.text = "No source snapshot: this scene may predate recipe preservation"
		return
	export_dialog.current_file = "scene-forge-recipe.json"
	export_dialog.popup_centered_ratio()
func _write_source_export(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		status.text = "Cannot write source recipe: " + str(FileAccess.get_open_error())
		return
	file.store_string(export_source)
	file.flush()
	var error := file.get_error()
	file.close()
	status.text = "Original recipe exported; manual engine edits are not included" if error == OK else "Source write failed: " + str(error)
func _compile(path: String) -> void:
	if worker != null:
		status.text = "A compile is already running"
		return
	if not FileAccess.file_exists(executable.text):
		status.text = "Select a built scene-forge executable"
		return
	var output := ProjectSettings.globalize_path("user://scene-forge-" + str(Time.get_ticks_usec()) + ".json")
	worker = Thread.new()
	worker.start(_job.bind(executable.text, path, output))
	status.text = "Compiling…"
func _job(exe: String, recipe: String, output: String) -> Dictionary:
	var log_lines: Array = []
	var code := OS.execute(exe, [recipe, output], log_lines, true, false)
	return {"code": code, "output": output, "log": str(log_lines)}
func _process(_delta: float) -> void:
	if worker == null or worker.is_alive():
		return
	var result: Dictionary = worker.wait_to_finish()
	worker = null
	if result.code != 0:
		status.text = "Compile failed: " + result.log
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(result.output))
	DirAccess.remove_absolute(result.output)
	if not data is Dictionary:
		status.text = "Compiler returned invalid scene data"
		return
	var parent := EditorInterface.get_edited_scene_root()
	if parent == null:
		status.text = "Open a scene before importing"
		return
	var built: Node3D = Importer.build(data)
	var undo := get_undo_redo()
	undo.create_action("Import procedural scene")
	undo.add_do_method(parent, "add_child", built)
	undo.add_do_method(self, "_own", built, parent)
	undo.add_do_reference(built)
	undo.add_undo_method(parent, "remove_child", built)
	undo.commit_action()
	status.text = "Imported " + str(data.instances.size()) + " instances"
func _own(node: Node, scene: Node) -> void:
	node.owner = scene
	for child in node.get_children():
		_own(child, scene)
func _exit_tree() -> void:
	if worker != null:
		worker.wait_to_finish()
	remove_control_from_docks(dock)
	dock.queue_free()
