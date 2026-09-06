extends Control
## Embeddable asset-backed workshop. Never modifies the source model.
var viewport: SubViewport
var stage: Node3D
var pivot: Node3D
var model: Node3D
var camera: Camera3D
var controls: VBoxContainer
var status: Label
var parts: Dictionary = {}
var shapes: Dictionary = {}
var source_hash := ""
var source_name := ""
var source_height := 1.0
var target_height := 1.7
var title_edit: LineEdit
var outfit = preload("res://character-outfit.gd").new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#20262c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = 340
	layout.add_child(panel)
	var heading := Label.new()
	heading.text = "Character workshop"
	heading.add_theme_font_size_override("font_size",26)
	panel.add_child(heading)
	title_edit = LineEdit.new()
	title_edit.placeholder_text = "Character / variant name"
	panel.add_child(title_edit)
	button(panel,"Open source GLB",func(): file_dialog(false,"*.glb",func(path): status.text = import_model(path)))
	button(panel,"Open clothing/body profile",func(): file_dialog(false,"*.json",load_outfit_profile))
	button(panel,"Save appearance",func(): file_dialog(true,"*.json",save_recipe))
	button(panel,"Load appearance",func(): file_dialog(false,"*.json",load_recipe))
	status = Label.new()
	status.text = "Open a real model. No source assets included.\nPreview does not grant publication approval."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(status)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	controls = VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(controls)
	var view := SubViewportContainer.new()
	view.stretch = true
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(view)
	viewport = SubViewport.new()
	viewport.size = Vector2i(900,850)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	pivot = Node3D.new()
	stage.add_child(pivot)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	stage.add_child(camera)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("#303a43")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = .65
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40,-25,0)
	light.light_energy = 1.0
	stage.add_child(light)
	var args := OS.get_cmdline_user_args()
	if args.size() == 1:
		status.text = import_model(args[0])

func button(parent: Node, text: String, action: Callable) -> void:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 38
	parent.add_child(control)
	control.pressed.connect(action)

func file_dialog(save: bool, filter: String, action: Callable) -> void:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if save else FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = PackedStringArray([filter])
	add_child(dialog)
	dialog.file_selected.connect(action)
	dialog.file_selected.connect(func(_p): dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered_ratio(.75)

func slider(label_text: String, low: float, high: float, value: float, action: Callable) -> void:
	var label := Label.new()
	label.text = "%s: %.2f" % [label_text,value]
	controls.add_child(label)
	var control := HSlider.new()
	control.min_value = low
	control.max_value = high
	control.step = .01
	control.value = value
	controls.add_child(control)
	control.value_changed.connect(action)
	control.value_changed.connect(func(v): label.text = "%s: %.2f" % [label_text,v])

func import_model(path: String) -> String:
	if not path.is_absolute_path() or path.get_extension().to_lower() != "glb" or not FileAccess.file_exists(path):
		return "Select an existing absolute GLB path."
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(path,state) != OK:
		return "GLB could not be imported; previous character retained."
	var candidate := document.generate_scene(state) as Node3D
	if candidate == null:
		return "No model scene found."
	stage.add_child(candidate)
	var meshes := candidate.find_children("*","MeshInstance3D",true,false)
	var box := AABB()
	var first := true
	for mesh in meshes:
		if mesh.mesh == null:
			continue
		var b: AABB = mesh.global_transform*mesh.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first or not box.size.is_finite() or box.size.y < .001:
		candidate.free()
		return "No usable model geometry."
	if model != null:
		model.free()
	model = candidate
	model.reparent(pivot)
	source_height = box.size.y
	source_hash = FileAccess.get_sha256(path)
	source_name = path.get_file()
	target_height = source_height
	pivot.rotation = Vector3.ZERO
	pivot.scale = Vector3.ONE
	model.position -= Vector3(box.get_center().x,box.position.y,box.get_center().z)
	parts.clear()
	shapes.clear()
	outfit = preload("res://character-outfit.gd").new()
	for mesh in meshes:
		var key := str(model.get_path_to(mesh))
		parts[key] = mesh
		for i in mesh.get_blend_shape_count():
			shapes[key+"::"+mesh.mesh.get_blend_shape_name(i)] = [mesh,i]
	refresh_controls()
	frame_model()
	return "%s\n%d mesh parts · %d shape controls\nOriginal materials and rig retained." % [source_name,parts.size(),shapes.size()]

func frame_model() -> void:
	pivot.scale = Vector3.ONE*(target_height/source_height)
	camera.size = maxf(target_height*1.45,.1)
	camera.position = Vector3(0,target_height*.6,target_height*3)
	camera.look_at(Vector3(0,target_height*.5,0))
	camera.far = maxf(target_height*10,100)
	# Wide creatures must fit too.
	var extent := 0.0
	for mesh in parts.values():
		var b: AABB = mesh.global_transform*mesh.mesh.get_aabb()
		extent = maxf(extent,b.size.length())
	camera.size = maxf(camera.size,extent*1.15)

func refresh_controls() -> void:
	for child in controls.get_children():
		controls.remove_child(child)
		child.queue_free()
	slider("Turntable",0,360,pivot.rotation_degrees.y,func(v): pivot.rotation_degrees.y=v)
	slider("Height (source units assumed metres)",.1,maxf(10,source_height*2),target_height,func(v): target_height=v; frame_model())
	var animations := OptionButton.new()
	animations.add_item("Rest pose")
	var clips: Array = []
	for player in model.find_children("*","AnimationPlayer",true,false):
		for clip in player.get_animation_list():
			animations.add_item(str(clip))
			clips.append([player,clip])
	controls.add_child(animations)
	animations.item_selected.connect(func(index):
		for player in model.find_children("*","AnimationPlayer",true,false):
			player.stop()
		for skeleton in model.find_children("*","Skeleton3D",true,false):
			skeleton.reset_bone_poses()
		if index>0:
			clips[index-1][0].play(clips[index-1][1]))
	if not outfit.profile.is_empty():
		for slot in outfit.profile.slots:
			var label := Label.new()
			label.text = slot
			controls.add_child(label)
			var choices := OptionButton.new()
			var names: Array = outfit.profile.slots[slot].keys()
			for choice in names:
				choices.add_item(choice)
			choices.select(names.find(outfit.selections[slot]))
			controls.add_child(choices)
			choices.item_selected.connect(func(i): outfit.selections[slot] = names[i]; outfit.apply())
		for control in outfit.morphs:
			slider(control,0,1,outfit.morphs[control],func(v): outfit.morphs[control] = v; outfit.apply())
		for channel in outfit.colors:
			var picker := ColorPickerButton.new()
			picker.text = channel
			picker.edit_alpha = false
			picker.color = Color.html(outfit.colors[channel])
			controls.add_child(picker)
			picker.color_changed.connect(func(c): outfit.colors[channel] = c.to_html(); outfit.apply())
		return
	for key in parts:
		var mesh: MeshInstance3D = parts[key]
		var check := CheckBox.new()
		check.text = str(mesh.name)
		check.clip_text = true
		check.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		check.tooltip_text = key+"\nVisibility only; does not certify clothing compatibility."
		check.button_pressed = mesh.visible
		controls.add_child(check)
		check.toggled.connect(func(on): mesh.visible=on)
	for key in shapes:
		var binding: Array = shapes[key]
		slider(key,0,1,binding[0].get_blend_shape_value(binding[1]),func(v): binding[0].set_blend_shape_value(binding[1],v))

func make_recipe() -> Dictionary:
	var visibility := {}
	var weights := {}
	for key in parts:
		visibility[key] = parts[key].visible
	for key in shapes:
		weights[key] = shapes[key][0].get_blend_shape_value(shapes[key][1])
	var result := {"schemaVersion":1,"name":title_edit.text,"sourceFilename":source_name,"sourceSha256":source_hash,"height":target_height,"parts":visibility,"shapes":weights}
	if not outfit.profile.is_empty():
		result["outfit"] = outfit.recipe()
	return result

func apply_recipe(value: Variant) -> String:
	if model == null:
		return "Open the matching source GLB first."
	if not value is Dictionary:
		return "Invalid appearance document."
	var data: Dictionary = value
	if data.get("schemaVersion") != 1 or data.get("sourceSha256") != source_hash:
		return "Preset version or source hash mismatch; no changes applied."
	if not data.get("name") is String or not data.get("parts") is Dictionary or not data.get("shapes") is Dictionary:
		return "Malformed preset fields."
	var h: Variant = data.get("height")
	if not (h is float or h is int) or not is_finite(float(h)) or h < .1 or h > maxf(10,source_height*2):
		return "Height is outside supported range."
	if data.parts.size() != parts.size() or data.shapes.size() != shapes.size():
		return "Preset parts or shapes do not match."
	for key in data.parts:
		if not parts.has(key) or not data.parts[key] is bool:
			return "Unknown part or invalid visibility."
	for key in data.shapes:
		var weight: Variant = data.shapes[key]
		if not shapes.has(key) or not (weight is float or weight is int):
			return "Unknown shape or invalid weight."
		if not is_finite(float(weight)) or weight < 0 or weight > 1:
			return "Shape weight is outside supported range."
	if outfit.profile.is_empty() and data.has("outfit"):
		return "Open the matching clothing/body profile first."
	if not outfit.profile.is_empty():
		var error: String = outfit.validate(data.get("outfit"))
		if not error.is_empty():
			return error
	# All validation completes before any live state changes.
	target_height = float(h)
	title_edit.text = data.name
	for key in data.parts:
		parts[key].visible = data.parts[key]
	for key in data.shapes:
		shapes[key][0].set_blend_shape_value(shapes[key][1],data.shapes[key])
	if not outfit.profile.is_empty():
		outfit.restore(data.outfit)
	frame_model()
	refresh_controls()
	return ""

func save_recipe(path: String) -> void:
	if model == null:
		status.text = "Open a model first."
		return
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		status.text = "Could not save appearance."
		return
	file.store_string(JSON.stringify(make_recipe(),"  ",true,true))
	file.close()
	status.text = "Appearance saved. Source model unchanged."

func load_recipe(path: String) -> void:
	var error := apply_recipe(JSON.parse_string(FileAccess.get_file_as_string(path)))
	status.text = "Appearance loaded." if error.is_empty() else error

func load_outfit_profile(path: String) -> void:
	if model == null:
		status.text = "Open the source model first."
		return
	if not outfit.profile.is_empty():
		status.text = "Reopen the source before changing its clothing/body profile."
		return
	var error: String = outfit.configure(JSON.parse_string(FileAccess.get_file_as_string(path)), parts, shapes, source_hash)
	status.text = "Wardrobe and linked body controls ready." if error.is_empty() else error
	if error.is_empty():
		refresh_controls()
