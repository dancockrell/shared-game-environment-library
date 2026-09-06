extends SceneTree
const Bodice = preload("res://period-bodice.gd")
const Textiles = preload("res://character-textiles.gd")

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("Expected complete fitting-body .res and output directory.")
		quit(2)
		return
	var body := ResourceLoader.load(args[0],"ArrayMesh",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if body == null:
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(args[1])
	var cut := Bodice.pattern(body.get_aabb().size.y)
	print("Fitting four cut panels around complete body...")
	var result: Dictionary = Bodice.fit(body,cut)
	if result.error != "":
		printerr(result.error)
		quit(1)
		return
	print("Bodice metrics: ",result.metrics)
	var material := Textiles.material(Textiles.generate(512,64,17),Color(.70,.62,.45),8)
	for surface in result.mesh.get_surface_count():
		result.mesh.surface_set_material(surface,material)
	if ResourceSaver.save(result.mesh,args[1].path_join("bodice.res")) != OK:
		quit(1)
		return
	var receipt := {"pattern":cut,"metrics":result.metrics,"bodySha256":FileAccess.get_sha256(args[0]),"builderSha256":FileAccess.get_sha256("res://period-bodice.gd"),"solverSha256":FileAccess.get_sha256("res://sewing-pattern.gd"),"contactSha256":FileAccess.get_sha256("res://cloth-contact.gd"),"meshSha256":FileAccess.get_sha256(args[1].path_join("bodice.res")),"artAdmission":"unapproved-construction-study"}
	var output := FileAccess.open(args[1].path_join("receipt.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(receipt,"  "))
	output.close()
	if DisplayServer.get_name() != "headless":
		await review(body,result.mesh,args[1])
	quit(0)

func review(body: ArrayMesh, garment: ArrayMesh, directory: String) -> void:
	root.size = Vector2i(900,900)
	var world := Node3D.new()
	root.add_child(world)
	var figure := MeshInstance3D.new()
	figure.mesh = body
	var clay := StandardMaterial3D.new()
	clay.albedo_color = Color(.20,.24,.28)
	clay.roughness = .85
	figure.material_override = clay
	world.add_child(figure)
	var clothes := MeshInstance3D.new()
	clothes.mesh = garment
	world.add_child(clothes)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = .90
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(.055,.07,.09)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = .45
	camera.environment = environment
	var key := DirectionalLight3D.new()
	world.add_child(key)
	key.rotation_degrees = Vector3(-35,-35,0)
	key.light_energy = 1.5
	var fill := DirectionalLight3D.new()
	world.add_child(fill)
	fill.rotation_degrees = Vector3(-15,125,0)
	fill.light_energy = .6
	for view in [{"id":"front","eye":Vector3(0,.33,2)},{"id":"three-quarter","eye":Vector3(1.2,.6,1.7)},{"id":"back","eye":Vector3(0,.4,-2)}]:
		camera.position = view.eye
		camera.look_at(Vector3(0,.28,.03))
		for i in 4:
			await process_frame
		RenderingServer.force_draw(false)
		var frame := root.get_texture().get_image()
		if frame.get_size() != Vector2i(900,900) or frame.save_png(directory.path_join(view.id+".png")) != OK:
			printerr("Bodice review capture failed.")
			quit(1)
			return
	print("Rendered front, three-quarter and back construction reviews.")
