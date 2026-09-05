extends SceneTree
## godot --path tools --rendering-method gl_compatibility --script res://build-river-port.gd -- <repo>
## Actual engine build and capture. No generated image is used as a background.
const Kit = preload("res://river-port-kit.gd")
var kit := Kit.new()
var output_dir: String
var repo: String

func _init() -> void:
	call_deferred("build")

func pavers(center: Vector3, width: float, depth: float) -> void:
	kit.block(center-Vector3(0,0.65,0),Vector3(width,1.2,depth),"mortar")
	var cols := int(width/0.7)
	var rows := int(depth/0.66)
	var w := width/cols
	var d := depth/rows
	var seeds: Array[Vector2] = []
	for z in rows:
		for x in cols:
			seeds.append(Vector2(-width/2+(x+0.5)*w+kit.rng.randf_range(-w*0.25,w*0.25),-depth/2+(z+0.5)*d+kit.rng.randf_range(-d*0.25,d*0.25)))
	for seed_pos in seeds:
		var poly := PackedVector2Array([Vector2(-width/2,-depth/2),Vector2(width/2,-depth/2),Vector2(width/2,depth/2),Vector2(-width/2,depth/2)])
		for neighbor in seeds:
			if neighbor == seed_pos or neighbor.distance_squared_to(seed_pos) > 5:
				continue
			var n := neighbor-seed_pos
			poly = clip_polygon(poly,n,n.dot((seed_pos+neighbor)/2))
		for index in poly.size():
			poly[index] = poly[index].move_toward(seed_pos,0.018)-seed_pos
		var mesh := kit.solid_polygon(poly,0.14,0.016)
		kit.piece(mesh,center+Vector3(seed_pos.x,-0.06,seed_pos.y),Vector3.ONE,kit.shade("stone"))
	for side in [-1,1]:
		kit.wall(width,0.85,0.45,center+Vector3(0,-0.95,side*depth/2),kit.root)
		kit.wall(depth,0.85,0.45,center+Vector3(side*width/2,-0.95,0),kit.root,true)
		for x in cols:
			kit.block(center+Vector3(-width/2+(x+0.5)*w,0.12,side*depth/2),Vector3(w-0.035,0.24,0.44),kit.shade("stone"))

func clip_polygon(poly: PackedVector2Array, normal: Vector2, limit: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in poly.size():
		var a := poly[index]
		var b := poly[(index+1)%poly.size()]
		var da := normal.dot(a)-limit
		var db := normal.dot(b)-limit
		if da <= 0:
			result.append(a)
		if (da < 0 and db > 0) or (da > 0 and db < 0):
			result.append(a.lerp(b,da/(da-db)))
	return result

func bridge() -> void:
	var g = kit.node_group("StoneArchBridge",Vector3(8,0.72,2.8))
	var half_span := 2.35
	for i in 16:
		var x := -half_span+(i+0.5)*half_span*2/16
		var rise := 0.85*(1-pow(x/half_span,2))
		for z in [-0.85,-0.28,0.28,0.85]:
			kit.block(Vector3(x,rise,float(z)),Vector3(0.32,0.24,0.53),kit.shade("stone"),g)
		for z in [-1.27,1.27]:
			kit.block(Vector3(x,rise+0.48,float(z)),Vector3(0.33,0.85,0.3),kit.shade("stone"),g)
			kit.block(Vector3(x,rise+0.94,float(z)),Vector3(0.34,0.17,0.43),kit.shade("stone"),g)
	for side in [-1,1]:
		for z in [-1.27,1.27]:
			kit.wall(0.6,1.45,0.65,Vector3(side*2.15,-1.45,float(z)),g)

func dock() -> void:
	var g = kit.node_group("TimberDock",Vector3(-4,0.12,8.7))
	for i in 29:
		var z := -2.6+i*0.19
		kit.block(Vector3(0,0.15,z),Vector3(3.2,0.16,0.175),kit.shade("wood"),g)
	for x in [-1.45,1.45]:
		kit.block(Vector3(x,-0.02,0),Vector3(0.23,0.3,5.65),"oak",g)
		for z in [-2.55,0,2.55]:
			kit.cylinder(Vector3(x,-0.1,z),0.16,2.2,"oak",g)
			kit.cylinder(Vector3(x,1.02,z),0.20,0.12,"oak_light",g)
			for y in [0.58,0.64,0.7]:
				kit.cylinder(Vector3(x,y,z),0.172,0.035,"sand",g)
		for segment in 2:
			for j in 8:
				var z0 := -2.55+segment*2.55+j*2.55/8
				var z1 := z0+2.55/8
				var t0 := j/8.0
				var t1 := (j+1)/8.0
				kit.beam(Vector3(x,0.72-0.3*sin(t0*PI),z0),Vector3(x,0.72-0.3*sin(t1*PI),z1),0.035,"sand",g)
	for step in 4:
		kit.block(Vector3(0,0.2+step*0.12,-2.8-step*0.22),Vector3(1.7,0.12,0.3),kit.shade("wood"),g)

func source_model(filename: String, pos: Vector3, scale_value: float, rotation_y: float = 0) -> void:
	var source := repo.path_join("resource_packs/terrain/tabletop-foundation/artifacts/models/").path_join(filename)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	assert(doc.append_from_file(source,state) == OK)
	var node := doc.generate_scene(state) as Node3D
	node.position = pos
	node.scale = Vector3.ONE*scale_value
	node.rotation.y = rotation_y
	kit.root.add_child(node)

func node_marker(pos: Vector3) -> void:
	kit.cylinder(pos+Vector3(0,0.075,0),0.21,0.14,"gold",kit.root,32)
	kit.cylinder(pos+Vector3(0,0.16,0),0.14,0.045,"gold",kit.root,32)
	kit.cylinder(pos+Vector3(0,0.015,0),0.27,0.035,"iron",kit.root,32)

func path_connection(a: Vector3,b: Vector3) -> void:
	kit.beam(a+Vector3(0,0.04,0),b+Vector3(0,0.04,0),0.045,"gold")

func pawn(pos: Vector3, cloth: String) -> void:
	# Explicit neutral scale pawn, not a finished or rigged character asset.
	var g = kit.node_group("NeutralScalePawn_NotFinalActor",pos)
	kit.cylinder(Vector3(0,0.04,0),0.42,0.08,"iron",g,32)
	kit.cylinder(Vector3(0,0.09,0),0.37,0.025,"gold",g,32)
	for x in [-0.12,0.12]:
		kit.block(Vector3(x,0.21,0.08),Vector3(0.16,0.24,0.32),"oak",g)
		kit.beam(Vector3(x,0.25,0),Vector3(x,0.86,0),0.16,"iron",g)
	var torso := CylinderMesh.new()
	torso.top_radius = 0.27
	torso.bottom_radius = 0.22
	torso.height = 0.55
	torso.radial_segments = 12
	kit.piece(torso,Vector3(0,1.08,0),Vector3.ONE,"iron",g)
	var cloak := CylinderMesh.new()
	cloak.top_radius = 0.19
	cloak.bottom_radius = 0.38
	cloak.height = 0.95
	cloak.radial_segments = 12
	kit.piece(cloak,Vector3(0,0.93,-0.09),Vector3(1,1,0.75),cloth,g)
	kit.cylinder(Vector3(0,1.52,0),0.18,0.34,"iron",g,16)
	kit.block(Vector3(0,1.55,0.172),Vector3(0.25,0.05,0.035),"oak",g)
	for x in [-0.3,0.3]:
		kit.beam(Vector3(x,1.28,0),Vector3(x*1.4,0.88,0.12),0.13,"iron",g)
	kit.beam(Vector3(0.48,0.68,0.15),Vector3(0.48,1.65,0.15),0.055,"gold",g)

func build() -> void:
	var args := OS.get_cmdline_user_args()
	assert(args.size() == 1,"Expected absolute repository path")
	repo = args[0]
	output_dir = repo.path_join("docs/river-port-build")
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1800,1200)
	root.msaa_3d = Viewport.MSAA_4X
	root.add_child(kit.root)
	kit.setup_palette()
	# Water shader is static spatial material; no animation or time dependency.
	var shader := Shader.new()
	shader.code = "shader_type spatial; varying vec3 world_position; void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float n=sin(world_position.x*1.8+sin(world_position.z*1.2))*sin(world_position.z*2.7+cos(world_position.x)); ALBEDO=vec3(0.09,0.16,0.17)+vec3(0.007,0.012,0.013)*n; ROUGHNESS=0.4; METALLIC=0.05;}"
	var water_mat := ShaderMaterial.new()
	water_mat.shader = shader
	var water = kit.block(Vector3(3,-0.48,1),Vector3(90,0.18,90),"water")
	water.material_override = water_mat
	pavers(Vector3(-2.5,0.65,-1),17,14)
	pavers(Vector3(14,0.65,0.0),8,12)
	# Sand and rocks below waterline at the outskirts, and reeds along the bank.
	for i in 75:
		var side := -1 if i%2 == 0 else 1
		var x := -11.2 if side == -1 else 18.3
		var z := kit.rng.randf_range(-6,6.5)
		kit.rock(Vector3(x+kit.rng.randf_range(-0.7,0.7),-0.55,z),Vector3(kit.rng.randf_range(0.6,1.4),kit.rng.randf_range(0.4,1.5),kit.rng.randf_range(0.6,1.4)))
	for i in 90:
		var x := kit.rng.randf_range(-11,-8)
		var z := kit.rng.randf_range(4.7,7)
		var a := Vector3(x,-0.3,z)
		kit.beam(a,a+Vector3(kit.rng.randf_range(-0.25,0.25),kit.rng.randf_range(0.5,1.15),0.13),0.035,"reed")
	var inn = kit.house("Inn",Vector3(0.5,0.75,-4.6),5.4,4.8,4.4,2.4,"roof")
	# Upper floor half-timbering, all sides present.
	for x in [-2.1,-1.1,1.1,2.1]:
		kit.block(Vector3(x,3.5,2.68),Vector3(0.15,1.7,0.18),"oak",inn)
		kit.beam(Vector3(x,2.8,2.69),Vector3(x+0.6,4.15,2.69),0.12,"oak",inn)
	for x in [-1.6,1.6]:
		kit.window_at(Vector3(x,3.35,2.67),inn,0.7)
	for i in 12:
		var awning = kit.block(Vector3(-1.9+i*0.34,2.45,3.07),Vector3(0.335,0.065,1.22),"cloth" if i%2 == 0 else "sand",inn)
		awning.rotation.x = 0.2
	kit.wall(0.65,2.4,0.68,Vector3(-1.65,4.1,-1.1),inn)
	kit.block(Vector3(-1.65,6.55,-1.1),Vector3(0.85,0.2,0.85),"stone7",inn)
	kit.beam(Vector3(-2.8,3.1,2.5),Vector3(-3.7,3.1,2.5),0.12,"iron",inn)
	kit.cylinder(Vector3(-3.6,2.65,2.5),0.35,0.09,"gold",inn,32).rotation.x = PI/2
	var shop = kit.house("CutawayShop",Vector3(-7.3,0.75,-1.9),4.2,4.4,2.9,1.7,"slate",true)
	kit.shelving(shop,Vector3(0,0.3,-1.85))
	kit.block(Vector3(0,0.9,0.45),Vector3(2.8,1.1,0.7),"oak",shop)
	kit.block(Vector3(0,1.5,0.45),Vector3(3.0,0.12,0.85),"oak_light",shop)
	for i in 8:
		kit.cylinder(Vector3(-1.15+i*0.3,1.63,0.45),0.1,0.15,kit.shade("roof"),shop)
	# Rear canopy as an explicit cutaway variant, full inn/guild remain closed.
	var canopy := kit.node_group("ShopRearRoof",Vector3(-7.3,3.65,-3.5))
	kit.roof(4.2,1.2,0,1.3,"slate",canopy)
	var guild = kit.house("GuildHall",Vector3(14,0.75,-1.4),5.0,5.0,4.2,3.2,"slate")
	for x in [-2.25,2.25]:
		kit.wall(0.55,5.3,0.6,Vector3(x,0,2.68),guild)
		kit.cylinder(Vector3(x,5.5,2.68),0.09,0.4,"gold",guild)
	kit.cylinder(Vector3(0,5.35,2.79),0.6,0.12,"gold",guild,48).rotation.x = PI/2
	kit.cylinder(Vector3(0,5.35,2.87),0.47,0.05,"iron",guild,48).rotation.x = PI/2
	for i in 8:
		var a := TAU*i/8
		kit.beam(Vector3(0,5.35,2.93),Vector3(cos(a)*0.42,5.35+sin(a)*0.42,2.93),0.065,"gold",guild)
	for x in [-1.9,1.9]:
		kit.block(Vector3(x,2.5,2.87),Vector3(0.65,1.8,0.035),"cloth",guild)
		kit.block(Vector3(x,2.5,2.91),Vector3(0.07,1.5,0.02),"gold",guild)
	bridge()
	dock()
	source_model("boat-row-small.glb",Vector3(-1.8,-0.24,9.1),0.85,0.3)
	source_model("barrel.glb",Vector3(-5,0.35,9.8),0.24)
	source_model("crate.glb",Vector3(-3.2,0.35,7.8),0.25)
	for pos in [Vector3(-10,0.7,-5),Vector3(4,0.7,-7),Vector3(17,0.7,-4)]:
		kit.tree(pos,5.0)
	var nodes: Array[Vector3] = [Vector3(-6,0.8,3),Vector3(-3,0.8,2),Vector3(0,0.8,1),Vector3(3,0.8,1),Vector3(5.5,0.8,2.8),Vector3(11,0.8,2.8),Vector3(14,0.8,3.5)]
	for p in nodes:
		node_marker(p)
	for i in nodes.size()-1:
		if i != 4:
			path_connection(nodes[i],nodes[i+1])
	pawn(Vector3(-2.8,0.8,0.25),"cloth")
	pawn(Vector3(0.4,0.8,-0.25),"redcloth")
	pawn(Vector3(3.3,0.8,2.5),"cloth")
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	var env := environment.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("293b3d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a9b6bd")
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	kit.root.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-38,0)
	sun.light_color = Color("ffdea8")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_bias = 0.12
	sun.shadow_normal_bias = 1.5
	kit.root.add_child(sun)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 29
	kit.root.add_child(camera)
	camera.position = Vector3(31,29,39)
	camera.look_at(Vector3(2,1.3,0.5))
	camera.current = true
	for frame in 8:
		await process_frame
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(output_dir.path_join("river-port-main.png")) == OK)
	# Save complete model geometry for independent import and alternate cameras.
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	assert(doc.append_from_scene(kit.root,state) == OK)
	assert(doc.write_to_filesystem(state,output_dir.path_join("river-port-scene.glb")) == OK)
	camera.position = Vector3(-29,26,33)
	camera.look_at(Vector3(2,1.3,0.5))
	for frame in 5:
		await process_frame
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(output_dir.path_join("river-port-alternate.png")) == OK)
	var file := FileAccess.open(output_dir.path_join("build-report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"generator":"tools/build-river-port.gd + tools/river-port-kit.gd","engine":Engine.get_version_info().string,"seed":5012026,"geometryPieces":kit.counts.pieces,"renderedObjects":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),"renderedPrimitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"drawCalls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"status":"authored environment study; not reference-matched or runtime-admitted","actors":"neutral unrigged scale pawns; not production characters","sceneSha256":FileAccess.get_sha256(output_dir.path_join("river-port-scene.glb"))},"\t")+"\n")
	file.close()
	print("Built river port: %d authored pieces" % kit.counts.pieces)
	quit()
