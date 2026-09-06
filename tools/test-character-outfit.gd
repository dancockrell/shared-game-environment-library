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
	for mesh in meshes.values():
		mesh.free()
	print("Outfit failures: ",failures)
	quit(0 if failures == 0 else 1)
