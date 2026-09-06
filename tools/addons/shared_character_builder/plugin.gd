@tool
extends EditorPlugin

const Package = preload("character_package.gd")
var picker: EditorFileDialog
var destination: EditorFileDialog
var feedback: AcceptDialog
var pending_actor: Node3D

func _enter_tree() -> void:
	picker = EditorFileDialog.new()
	picker.access = EditorFileDialog.ACCESS_FILESYSTEM
	picker.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	picker.filters = PackedStringArray(["*.character.json ; Built character manifest"])
	picker.file_selected.connect(_selected)
	add_child(picker)
	destination = EditorFileDialog.new()
	destination.access = EditorFileDialog.ACCESS_RESOURCES
	destination.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	destination.filters = PackedStringArray(["*.scn ; Bundled character scene"])
	destination.file_selected.connect(_save)
	destination.canceled.connect(_clear_pending)
	add_child(destination)
	feedback = AcceptDialog.new()
	add_child(feedback)
	add_tool_menu_item("Import shared character",func(): picker.popup_centered_ratio(.7))

func _clear_pending() -> void:
	if is_instance_valid(pending_actor):
		pending_actor.free()
	pending_actor = null

func _selected(path: String) -> void:
	_clear_pending()
	var result := Package.instantiate_package(path)
	if not result.error.is_empty():
		feedback.dialog_text = result.error
		feedback.popup_centered()
		return
	pending_actor = result.actor
	destination.current_file = path.get_file().trim_suffix(".character.json")+".scn"
	destination.popup_centered_ratio(.7)

func _save(path: String) -> void:
	if not is_instance_valid(pending_actor):
		return
	var packed := PackedScene.new()
	var result := packed.pack(pending_actor)
	if result == OK:
		result = ResourceSaver.save(packed,path,ResourceSaver.FLAG_BUNDLE_RESOURCES)
	if result != OK:
		feedback.dialog_text = "Character scene could not be saved."
		feedback.popup_centered()
		return
	_clear_pending()
	get_editor_interface().get_resource_filesystem().scan()
	get_editor_interface().open_scene_from_path(path)

func _exit_tree() -> void:
	remove_tool_menu_item("Import shared character")
	_clear_pending()
	picker.queue_free()
	destination.queue_free()
	feedback.queue_free()
