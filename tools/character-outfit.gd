extends RefCounted
## Asset-authored wardrobe on one imported body/rig. No inferred body regions.
var profile: Dictionary = {}
var selections: Dictionary = {}
var morphs: Dictionary = {}
var colors: Dictionary = {}
var meshes: Dictionary = {}
var bindings: Dictionary = {}
var base_colors: Dictionary = {}

func configure(value: Variant, available: Dictionary, shape_bindings: Dictionary, source: String) -> String:
	if not value is Dictionary or value.get("schemaVersion") != 1 or value.get("sourceSha256") != source:
		return "Outfit profile must match this exact source GLB."
	for field in ["slots", "morphs", "dyes"]:
		if not value.get(field) is Dictionary:
			return "Missing profile field: " + field
	var owned := {}
	var next_selections := {}
	for slot in value.slots:
		var choices: Variant = value.slots[slot]
		if not choices is Dictionary or choices.is_empty():
			return "Every clothing slot needs choices."
		for choice in choices:
			var item: Variant = choices[choice]
			if not item is Dictionary or not item.get("meshes") is Array or not item.get("hides") is Array:
				return "Each choice needs mesh and hidden-region lists."
			for key in item.meshes:
				if not available.has(key) or (owned.has(key) and owned[key] != slot):
					return "Clothing mesh missing or assigned to multiple slots."
				owned[key] = slot
			for key in item.hides:
				if not available.has(key):
					return "Hidden body region does not exist."
		next_selections[slot] = choices.keys()[0]
	for slot in value.slots:
		for item in value.slots[slot].values():
			for key in item.hides:
				if owned.has(key):
					return "A hidden body region cannot also be a clothing choice."
	var next_morphs := {}
	var mapped := {}
	for control in value.morphs:
		var keys: Variant = value.morphs[control]
		if not keys is Array or keys.is_empty():
			return "A body control needs explicit body and garment shape bindings."
		for key in keys:
			if not shape_bindings.has(key) or mapped.has(key):
				return "Missing or multiply assigned body shape."
			mapped[key] = control
		next_morphs[control] = 0.0
	var next_colors := {}
	var dyed := {}
	for channel in value.dyes:
		if not value.dyes[channel] is Array or value.dyes[channel].is_empty():
			return "A dye needs explicit mesh/surface bindings."
		for entry in value.dyes[channel]:
			if not entry is Dictionary or not available.has(entry.get("mesh")):
				return "Dye mesh does not exist."
			var index: Variant = entry.get("surface")
			if not (index is int or index is float) or not is_finite(float(index)) or index != int(index) or index < 0 or index >= available[entry.mesh].mesh.get_surface_count():
				return "Dye surface does not exist."
			var key := str(entry.mesh) + "::" + str(index)
			if dyed.has(key) or not available[entry.mesh].get_active_material(int(index)) is StandardMaterial3D:
				return "Dye requires a unique standard material surface."
			dyed[key] = channel
		next_colors[channel] = "ffffffff"
	# Commit only after complete validation. Duplicate materials before changing them.
	profile = value.duplicate(true)
	meshes = available
	bindings = shape_bindings
	selections = next_selections
	morphs = next_morphs
	colors = next_colors
	base_colors.clear()
	for entries in profile.dyes.values():
		for entry in entries:
			var mesh: MeshInstance3D = meshes[entry.mesh]
			base_colors[str(entry.mesh)+"::"+str(entry.surface)] = mesh.get_active_material(entry.surface).albedo_color
			mesh.set_surface_override_material(entry.surface, mesh.get_active_material(entry.surface).duplicate())
	apply()
	return ""

func recipe() -> Dictionary:
	return {"profileSha256":JSON.stringify(profile, "", true).sha256_text(), "slots":selections.duplicate(), "morphs":morphs.duplicate(), "dyes":colors.duplicate()}

func validate(value: Variant) -> String:
	if not value is Dictionary or value.get("profileSha256") != recipe().profileSha256:
		return "Wardrobe profile mismatch."
	for field in ["slots", "morphs", "dyes"]:
		if not value.get(field) is Dictionary or value[field].size() != profile[field].size():
			return "Wardrobe fields do not match."
	for slot in value.slots:
		if not profile.slots.has(slot) or not profile.slots[slot].has(value.slots[slot]):
			return "Unknown clothing choice."
	for control in value.morphs:
		var weight: Variant = value.morphs[control]
		if not morphs.has(control) or not (weight is float or weight is int):
			return "Unknown body control."
		if not is_finite(float(weight)) or weight < 0 or weight > 1:
			return "Invalid body control weight."
	for channel in value.dyes:
		var color: Variant = value.dyes[channel]
		if not colors.has(channel) or not color is String or color.length() != 8 or not Color.html_is_valid(color):
			return "Invalid dye color."
	return ""

func restore(value: Dictionary) -> String:
	var error := validate(value)
	if not error.is_empty():
		return error
	selections = value.slots.duplicate()
	morphs = value.morphs.duplicate()
	colors = value.dyes.duplicate()
	apply()
	return ""

func apply() -> void:
	var hidden := {}
	# Reset only profile-managed regions, preserving unrelated asset visibility.
	for choices in profile.slots.values():
		for item in choices.values():
			for key in item.hides:
				meshes[key].visible = true
			for key in item.meshes:
				meshes[key].visible = false
	for slot in selections:
		var item: Dictionary = profile.slots[slot][selections[slot]]
		for key in item.meshes:
			meshes[key].visible = true
		for key in item.hides:
			hidden[key] = true
	for key in hidden:
		meshes[key].visible = false
	for control in morphs:
		for key in profile.morphs[control]:
			bindings[key][0].set_blend_shape_value(bindings[key][1], morphs[control])
	for channel in colors:
		for entry in profile.dyes[channel]:
			meshes[entry.mesh].get_surface_override_material(entry.surface).albedo_color = base_colors[str(entry.mesh)+"::"+str(entry.surface)] * Color.html(colors[channel])
