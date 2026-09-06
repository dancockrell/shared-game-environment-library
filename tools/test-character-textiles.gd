extends SceneTree
const Textiles = preload("res://character-textiles.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:
		failures += 1

func _init() -> void:
	var maps: Dictionary = Textiles.generate(128,16,17)
	check(maps.error.is_empty(),"generate original weave maps")
	var repeat_maps: Dictionary = Textiles.generate(128,16,17)
	for channel in ["albedo","normal","roughness"]:
		check(maps[channel].get_data() == repeat_maps[channel].get_data(),"deterministic "+channel)
	for point in [Vector2(.13,.47),Vector2(.0,.5),Vector2(.99,.01)]:
		check(is_equal_approx(Textiles.height_at(point.x,point.y,16,17),Textiles.height_at(point.x+1,point.y-1,16,17)),"periodic thread field")
	check(not Textiles.generate(128,15).error.is_empty(),"reject seam-breaking odd thread count")
	check(not Textiles.generate(128,64).error.is_empty(),"reject undersampled weave")
	var roughness_ok := true
	for value in maps.roughness.get_data():
		roughness_ok = roughness_ok and value >= 226 and value <= 245
	check(roughness_ok,"linear roughness remains within authored matte range")
	var mat: StandardMaterial3D = Textiles.material(maps,Color.WHITE,4)
	check(mat.normal_enabled and mat.normal_texture != null and mat.roughness_texture != null,"material connects normal and roughness maps")
	check(mat.normal_texture.get_image().has_mipmaps(),"normal maps carry mipmaps")
	var second_material: StandardMaterial3D = Textiles.material(maps,Color.BLUE,8)
	check(mat.normal_texture == second_material.normal_texture and mat.albedo_texture == second_material.albedo_texture,"different dyes reuse shared texture resources")
	var original: PackedByteArray = maps.albedo.get_data()
	mat.albedo_color = Color.RED
	check(maps.albedo.get_data() == original,"dye leaves authored surface unchanged")
	var args := OS.get_cmdline_user_args()
	if args.size() == 1:
		var production: Dictionary = Textiles.generate(1024,128,17)
		for channel in ["albedo","normal","roughness"]:
			check(production[channel].save_png(args[0]+"-"+channel+".png") == OK,"save review "+channel)
	print("Textile failures: ",failures)
	quit(1 if failures else 0)
