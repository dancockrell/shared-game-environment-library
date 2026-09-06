extends Control
## Embeddable asset-backed workshop. Never modifies the source model.
signal character_built(character: PackedScene, appearance: Dictionary)
@export_dir var prepared_asset_directory := ""
var viewport: SubViewport
var stage: Node3D
var pivot: Node3D
var model: Node3D
var camera: Camera3D
var controls: VBoxContainer
var status: Label
var parts: Dictionary = {}
var shapes: Dictionary = {}
var rest_transforms: Dictionary = {}
var source_hash := ""
var source_name := ""
var source_height := 1.0
var target_height := 1.7
var title_edit: LineEdit
var variation_seed := ""
var batch_count := 6
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
	if prepared_asset_directory.is_empty():
		prepared_asset_directory = ProjectSettings.globalize_path("res://").path_join("../assets/character-prototypes/makehuman").simplify_path()
	if FileAccess.file_exists(prepared_asset_directory.path_join("female-source.glb")) and FileAccess.file_exists(prepared_asset_directory.path_join("male-source.glb")):
		var bases := HBoxContainer.new()
		panel.add_child(bases)
		button(bases,"Female body",func(): open_prepared_body("female"))
		button(bases,"Male body",func(): open_prepared_body("male"))
	button(panel,"Open source GLB",func(): file_dialog(false,"*.glb",func(path): status.text = import_model(path)))
	button(panel,"Open clothing/body profile",func(): file_dialog(false,"*.json",load_outfit_profile))
	button(panel,"Save appearance",func(): file_dialog(true,"*.json",save_recipe))
	button(panel,"Load appearance",func(): file_dialog(false,"*.json",load_recipe))
	button(panel,"Export Godot character",func(): file_dialog(true,"*.scn",export_character))
	status = Label.new()
	status.text = "Open a source model and its wardrobe profile.\nPreview does not grant publication approval."
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
	elif args.size() == 2 and args[1].ends_with("-profile.json"):
		status.text = import_model(args[0])
		load_outfit_profile(args[1])

func button(parent: Node, text: String, action: Callable) -> void:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 38
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)
	control.pressed.connect(action)

func open_prepared_body(body_type: String) -> void:
	if body_type not in ["female","male"]:
		status.text = "Unknown prepared body."
		return
	var source_path := prepared_asset_directory.path_join(body_type+"-source.glb")
	var profile_path := prepared_asset_directory.path_join(body_type+"-profile.json")
	if not FileAccess.file_exists(source_path) or not FileAccess.file_exists(profile_path):
		status.text = "Prepared body or wardrobe profile is missing."
		return
	status.text = import_model(source_path)
	if source_hash == FileAccess.get_sha256(source_path):
		load_outfit_profile(profile_path)

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
	variation_seed = ""
	target_height = source_height
	pivot.rotation = Vector3.ZERO
	pivot.scale = Vector3.ONE
	model.position -= Vector3(box.get_center().x,box.position.y,box.get_center().z)
	rest_transforms.clear()
	rest_transforms[""] = model.transform
	for node in model.find_children("*","Node3D",true,false):
		rest_transforms[str(model.get_path_to(node))] = node.transform
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
	var views := HBoxContainer.new()
	controls.add_child(views)
	button(views,"Face view",focus_face)
	button(views,"Full body",frame_model)
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
		var seed_edit := LineEdit.new()
		seed_edit.placeholder_text = "NPC variation seed"
		seed_edit.text = variation_seed
		controls.add_child(seed_edit)
		button(controls,"Create variation",func(): create_variation(seed_edit.text))
		var count_input := SpinBox.new()
		count_input.min_value = 1
		count_input.max_value = 64
		count_input.value = batch_count
		count_input.prefix = "NPC count: "
		count_input.value_changed.connect(func(v): batch_count = int(v))
		controls.add_child(count_input)
		button(controls,"Export NPC batch",func(): file_dialog(true,"*.scn",func(path): export_population(path,seed_edit.text,batch_count)))
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
			var label := Label.new()
			label.text = channel
			controls.add_child(label)
			var picker := ColorPickerButton.new()
			picker.custom_minimum_size.y = 32
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
	var result := {"schemaVersion":1,"name":title_edit.text,"sourceFilename":source_name,"sourceSha256":source_hash,"height":target_height,"parts":visibility,"shapes":weights,"variationSeed":variation_seed}
	if not outfit.profile.is_empty():
		result["outfit"] = outfit.recipe()
	return result

func focus_face() -> void:
	if model == null:
		return
	var point := Vector3(0,target_height*.91,0)
	if parts.has("Skeleton3D/Eyes"):
		var eyes: MeshInstance3D = parts["Skeleton3D/Eyes"]
		point = eyes.global_transform*eyes.mesh.get_aabb().get_center()
	camera.size = maxf(.2,target_height*.34)
	camera.position = point+Vector3(0,0,target_height*2)
	camera.look_at(point)

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
	if not data.get("variationSeed","") is String:
		return "Invalid variation seed."
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
	variation_seed = data.get("variationSeed","")
	for key in data.parts:
		parts[key].visible = data.parts[key]
	for key in data.shapes:
		shapes[key][0].set_blend_shape_value(shapes[key][1],data.shapes[key])
	if not outfit.profile.is_empty():
		outfit.restore(data.outfit)
	frame_model()
	refresh_controls()
	return ""

func variation_value(seed_text: String, key: String) -> float:
	# Independent hashes avoid iteration-order changes reshuffling an NPC.
	return float((seed_text+"|"+key).sha256_text().left(8).hex_to_int())/4294967295.0

func create_variation(seed_text: String) -> void:
	if model == null or outfit.profile.is_empty() or seed_text.strip_edges().is_empty():
		status.text = "Open a prepared body and enter a variation seed."
		return
	var recipe := make_recipe()
	recipe.variationSeed = seed_text
	for key in recipe.outfit.morphs:
		# Dyadic steps survive JSON and float32 mesh storage exactly.
		recipe.outfit.morphs[key] = floori(variation_value(seed_text,"shape:"+key)*.65*1024)/1024.0
	# Keep species choice explicit, and avoid combining opposite face shapes.
	if recipe.outfit.morphs.has("Pointed ears"):
		recipe.outfit.morphs["Pointed ears"] = outfit.morphs["Pointed ears"]
	if recipe.outfit.morphs.has("Oval face") and recipe.outfit.morphs.has("Square face"):
		recipe.outfit.morphs["Oval face" if variation_value(seed_text,"face-family")<.5 else "Square face"] = 0.0
	for slot in outfit.profile.slots:
		var names: Array = outfit.profile.slots[slot].keys()
		names.sort()
		recipe.outfit.slots[slot] = names[mini(int(variation_value(seed_text,"slot:"+slot)*names.size()),names.size()-1)]
	if recipe.outfit.dyes.has("Hair"):
		var colors := ["342820ff","6b4930ff","ac8654ff","423731ff","80452fff"]
		recipe.outfit.dyes.Hair = colors[mini(int(variation_value(seed_text,"hair")*colors.size()),colors.size()-1)]
	# Profile application is the single owner of linked shapes and visibility.
	var error := apply_recipe(recipe)
	status.text = "Variation created; name, height and species retained." if error.is_empty() else error

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

func build_character() -> PackedScene:
	if model == null:
		return null
	# Own one presentation-ready actor; no workshop UI, lights or camera.
	var actor := Node3D.new()
	actor.name = "Character"
	actor.scale = Vector3.ONE*(target_height/source_height)
	actor.set_meta("appearance",make_recipe())
	actor.set_meta("art_status","workshop-export-requires-consumer-approval")
	var body := model.duplicate() as Node3D
	if body == null:
		actor.free()
		return null
	actor.add_child(body)
	for path in rest_transforms:
		var node := body if path.is_empty() else body.get_node_or_null(NodePath(path)) as Node3D
		if node != null:
			node.transform = rest_transforms[path]
	# Freeze mutable appearance materials so later editor changes cannot recolor
	# a previously built actor. Geometry and textures remain immutable resources.
	for part in body.find_children("*","MeshInstance3D",true,false):
		if part.mesh == null:
			continue
		for surface in part.mesh.get_surface_count():
			var material: Material = part.get_active_material(surface)
			if material != null:
				var owned_material: Material = material.duplicate()
				part.set_surface_override_material(surface,owned_material)
	# The preview's turntable and temporary poses must not become bind poses.
	for player in body.find_children("*","AnimationPlayer",true,false):
		player.stop()
		player.autoplay = ""
	for skeleton in body.find_children("*","Skeleton3D",true,false):
		skeleton.reset_bone_poses()
	set_export_owner(body,actor)
	var packed := PackedScene.new()
	var error := packed.pack(actor)
	actor.free()
	return packed if error == OK else null

func set_export_owner(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		set_export_owner(child,owner_node)

func build_population(seed_text: String, count: int) -> PackedScene:
	if model == null or outfit.profile.is_empty() or seed_text.strip_edges().is_empty() or count < 1 or count > 64:
		return null
	var previous := make_recipe()
	var camera_transform := camera.transform
	var camera_size := camera.size
	var batch := Node3D.new()
	batch.name = "CharacterBatch"
	batch.set_meta("art_status","workshop-batch-requires-consumer-approval")
	batch.set_meta("seed",seed_text)
	for i in count:
		var seed_value := seed_text+":"+str(i)
		create_variation(seed_value)
		# Batch IDs are not narrative identities; never clone a named hero's name.
		title_edit.text = ""
		var packed := build_character()
		if packed == null or variation_seed != seed_value:
			batch.free()
			apply_recipe(previous)
			camera.transform = camera_transform
			camera.size = camera_size
			return null
		var actor := packed.instantiate() as Node3D
		actor.name = "NPC_%03d" % i
		actor.set_meta("variation_id",seed_value)
		batch.add_child(actor)
		set_export_owner(actor,batch)
	var result := PackedScene.new()
	var error := result.pack(batch)
	batch.free()
	apply_recipe(previous)
	camera.transform = camera_transform
	camera.size = camera_size
	return result if error == OK else null

func export_population(path: String, seed_text: String, count: int) -> void:
	if not path.is_absolute_path() or path.get_extension().to_lower() != "scn":
		status.text = "Choose an absolute .scn output path."
		return
	var packed := build_population(seed_text,count)
	if packed == null:
		status.text = "A prepared body, seed and count of 1–64 are required."
		return
	var error := ResourceSaver.save(packed,path,ResourceSaver.FLAG_BUNDLE_RESOURCES)
	status.text = "%d NPC appearances exported. Current character unchanged." % count if error == OK else "NPC export failed."

func export_character(path: String) -> void:
	if not path.is_absolute_path() or path.get_extension().to_lower() != "scn":
		status.text = "Choose an absolute .scn output path."
		return
	var packed := build_character()
	if packed == null:
		status.text = "Open a usable model before exporting."
		return
	# Bundle dynamically imported geometry, textures, materials and skins.
	var error := ResourceSaver.save(packed,path,ResourceSaver.FLAG_BUNDLE_RESOURCES)
	if error != OK:
		status.text = "Character export failed."
		return
	character_built.emit(packed,make_recipe())
	status.text = "Godot character exported with appearance and rig."

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
