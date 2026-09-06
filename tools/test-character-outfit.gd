extends SceneTree
## Synthetic triangles are mechanical fixtures, not character art.
var failures := 0
func _init() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS ",label)
	else:
		push_error(label)
		failures += 1
func part() -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	mesh.add_blend_shape("build")
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO,Vector3.RIGHT,Vector3.UP])
	var target := arrays.duplicate(true)
	target[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO,Vector3.RIGHT*1.2,Vector3.UP])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[target])
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.8,.7,.6)
	mesh.surface_set_material(0,material)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	return instance
func run() -> void:
	var outfit = load("res://character-outfit.gd").new()
	var meshes := {"torso":part(),"shirt":part(),"coat":part()}
	var shapes := {}
	for key in meshes:
		root.add_child(meshes[key])
		shapes[key+"::build"] = [meshes[key],0]
	var source_material: Material = meshes.shirt.get_active_material(0)
	var profile := {"schemaVersion":1,"sourceSha256":"test", "slots":{
		"Shirt":{"On":{"meshes":["shirt"],"hides":["torso"]},"Off":{"meshes":[],"hides":[]}},
		"Coat":{"On":{"meshes":["coat"],"hides":["torso"]},"Off":{"meshes":[],"hides":[]}}},
		"morphs":{"Build":["torso::build","shirt::build","coat::build"]},
		"dyes":{"Fabric":[{"mesh":"shirt","surface":0}]}}
	check(outfit.configure(profile,meshes,shapes,"test").is_empty(),"configure wardrobe")
	check(not meshes.torso.visible and meshes.shirt.visible and meshes.coat.visible,"clothing hides covered body")
	check(meshes.shirt.get_active_material(0) != source_material,"source material is isolated")
	check(meshes.shirt.get_active_material(0).albedo_color == source_material.albedo_color,"default dye preserves source palette")
	var preset: Dictionary = outfit.recipe()
	preset.slots.Shirt = "Off"
	preset.morphs.Build = .75
	preset.dyes.Fabric = "ff0000ff"
	check(outfit.restore(preset).is_empty(),"apply complete outfit")
	check(not meshes.torso.visible,"remaining coat still hides body")
	for mesh in meshes.values():
		check(is_equal_approx(mesh.get_blend_shape_value(0),.75),"body and garment shapes stay linked")
	preset.slots.Coat = "Off"
	outfit.restore(preset)
	check(meshes.torso.visible and not meshes.shirt.visible and not meshes.coat.visible,"unequip restores body")
	var before: Dictionary = outfit.recipe()
	var bad := before.duplicate(true)
	bad.slots.Shirt = "Missing"
	check(not outfit.restore(bad).is_empty() and outfit.recipe() == before,"invalid clothing is atomic")
	bad = before.duplicate(true)
	bad.morphs.Build = NAN
	check(not outfit.restore(bad).is_empty() and outfit.recipe() == before,"nonfinite morph is atomic")
	bad = before.duplicate(true)
	bad.dyes.Fabric = "notcolor"
	check(not outfit.restore(bad).is_empty() and outfit.recipe() == before,"invalid dye is atomic")
	bad = profile.duplicate(true)
	bad.slots.Coat.On.meshes = ["shirt"]
	check(not outfit.configure(bad,meshes,shapes,"test").is_empty() and outfit.recipe() == before,"ambiguous slot ownership is atomic")
	check(outfit.restore(JSON.parse_string(JSON.stringify(before))).is_empty(),"JSON roundtrip")
	var measured := profile.duplicate(true)
	measured.measurement = {"kind":"rest-body-height-envelope","morphs":["Build"],"samples":[[-.8,-.1],[.8,.2]]}
	check(outfit.configure(measured,meshes,shapes,"test").is_empty(),"configure measured body")
	outfit.morphs.Build = .5
	outfit.apply()
	check(outfit.body_vertical_bounds().is_equal_approx(Vector2(-.85,.9)),"measurement follows additive body morph")
	var measured_before: Dictionary = outfit.recipe()
	for measurement in [{"kind":"rest-body-height-envelope","morphs":["Build"],"samples":[[0,0],[0,0]]},{"kind":"rest-body-height-envelope","morphs":["Missing"],"samples":[[-1,0],[1,0]]},{"kind":"rest-body-height-envelope","morphs":["Build"],"samples":[[-1,NAN],[1,0]]}]:
		bad = measured.duplicate(true)
		bad.measurement = measurement
		check(not outfit.configure(bad,meshes,shapes,"test").is_empty() and outfit.recipe() == measured_before,"invalid measurement rejects atomically")
	for choices in [{"Coat":[]},{"Coat":["Missing"]},{"Coat":["On","On"]}]:
		bad = measured.duplicate(true)
		bad.variationChoices = choices
		check(not outfit.configure(bad,meshes,shapes,"test").is_empty() and outfit.recipe() == measured_before,"invalid generation choices reject atomically")
	for cap in [NAN,-.1,1.1]:
		bad = measured.duplicate(true)
		bad.variationCaps = {"Build":cap}
		check(not outfit.configure(bad,meshes,shapes,"test").is_empty() and outfit.recipe() == measured_before,"invalid generation cap rejects atomically")
	for shadowless in ["shirt",["Missing"],[42]]:
		bad = measured.duplicate(true)
		bad.shadowlessMeshes = shadowless
		check(not outfit.configure(bad,meshes,shapes,"test").is_empty() and outfit.recipe() == measured_before,"invalid shadow override rejects atomically")
	measured.shadowlessMeshes = ["shirt"]
	check(outfit.configure(measured,meshes,shapes,"test").is_empty() and meshes.shirt.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"source shadow override applies to fitted mesh")
	var layered := profile.duplicate(true)
	layered.slots.Coat.On.excludes = ["shirt"]
	check(outfit.configure(layered,meshes,shapes,"test").is_empty() and not meshes.shirt.visible and meshes.coat.visible,"outer equipment excludes selected inner equipment")
	outfit.selections.Coat = "Off"
	outfit.apply()
	check(meshes.shirt.visible and outfit.selections.Shirt == "On","removal restores remembered inner choice")
	outfit.morphs.Build = 0
	var numeric_recipe: Dictionary = outfit.recipe()
	check(outfit.restore(JSON.parse_string(JSON.stringify(numeric_recipe,"",true,true))).is_empty() and outfit.recipe() == numeric_recipe,"integer-authored weights have stable JSON recipe types")
	var layered_before: Dictionary = outfit.recipe()
	for exclusion in ["shirt",["Missing"],["coat"],[42]]:
		bad = layered.duplicate(true)
		bad.slots.Coat.On.excludes = exclusion
		check(not outfit.configure(bad,meshes,shapes,"test").is_empty() and outfit.recipe() == layered_before,"invalid equipment exclusion rejects atomically")
	for mesh in meshes.values():
		mesh.free()
	print("Outfit failures: ",failures)
	quit(0 if failures == 0 else 1)
