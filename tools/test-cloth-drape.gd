extends SceneTree
const Sewing = preload("res://sewing-pattern.gd")
const Contact = preload("res://cloth-contact.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:
		failures += 1

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var collider := Contact.new()
	var ground := PackedVector3Array([Vector3(-2,0,-2),Vector3(2,0,-2),Vector3(2,0,2),Vector3(-2,0,2)])
	check(collider.build(ground,PackedInt32Array([0,1,2,0,2,3]),true) == "","build outward triangle-surface collider")
	var near: Dictionary = collider.nearest(Vector3(.2,.4,.1))
	check(near.point.is_equal_approx(Vector3(.2,0,.1)) and near.normal == Vector3.UP,"nearest point and outward normal match independent plane result")
	check(collider.nearest(Vector3(0,1,0),.1).is_empty(),"bounded nearest query rejects distant surfaces")
	var swept: Vector3 = collider.resolve(Vector3(0,10,0),Vector3(0,-10,0))
	check(swept.is_equal_approx(Vector3(0,.003,0)),"vertex sweep catches a surface crossing with both endpoints far away")
	check(collider.resolve(Vector3(0,.001,0),Vector3(0,.001,0)).is_equal_approx(Vector3(0,.003,0)),"contact shell maintains cloth thickness")
	check(collider.resolve(Vector3(4,.01,4),Vector3(4,-.01,4)).is_equal_approx(Vector3(4,-.01,4)),"triangle collider does not act like an infinite plane")
	var bad := Contact.new()
	check(bad.build(ground,PackedInt32Array([0,1,99])) != "" and bad.nearest(Vector3.ZERO).is_empty(),"invalid collider indices reject atomically")
	check(bad.build(ground,PackedInt32Array([0,0,1])) != "","degenerate contact triangles reject")
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for z in 17:
		for x in 17:
			vertices.append(Vector3(x*.1,.1*sin(x*.3)*cos(z*.2),z*.1))
	for z in 16:
		for x in 16:
			var a := z*17+x
			indices.append_array(PackedInt32Array([a,a+1,a+18,a,a+18,a+17]))
	var curved := Contact.new()
	check(curved.build(vertices,indices) == "" and curved.nodes.size() > 1,"build a hierarchical collider for nonplanar triangle geometry")
	var rng := RandomNumberGenerator.new()
	rng.seed = 918
	var max_query_error := 0.0
	for query in 40:
		var point := Vector3(rng.randf_range(-.1,1.7),rng.randf_range(.15,.8),rng.randf_range(-.1,1.7))
		var minimum := INF
		for face in curved.faces:
			minimum = minf(minimum,point.distance_to(Contact.closest_triangle(point,face.a,face.b,face.c)))
		max_query_error = maxf(max_query_error,absf(curved.nearest(point).distance-minimum))
	check(max_query_error < .000001,"accelerated nearest distances match exhaustive triangle queries")
	var pattern := {"schemaVersion":1,"units":"metres","panels":[{"id":"cloth","boundary":[[0,0],[.4,0],[.4,.6],[0,.6]],"origin":[-.2,.45,0],"u":[1,0,0],"v":[0,0,1]}],"stitches":[]}
	var compiled: Dictionary = Sewing.compile(pattern,3)
	check(compiled.error == "" and not compiled.bends.is_empty(),"cut pattern generates internal flat-rest bending stencils")
	var max_rest_curvature := 0.0
	for bend in compiled.bends:
		var curvature := Vector3.ZERO
		var sum_weights := 0.0
		for i in 4:
			curvature += compiled.positions[bend.vertices[i]]*bend.weights[i]
			sum_weights += bend.weights[i]
		max_rest_curvature = maxf(max_rest_curvature,maxf(curvature.length(),absf(sum_weights)))
	check(max_rest_curvature < .000001,"bending stencils preserve flat cuts and translation invariance")
	var isolated: Dictionary = Sewing.compile(pattern,0)
	isolated.constraints = []
	for i in 3:
		isolated.inverse_mass[i] = 0
	isolated.positions[3] += Vector3(0,.2,0)
	var flattened: Dictionary = Sewing.relax(isolated,2,0,1.0/60,{"bending":true,"bendCompliance":0.0})
	check(absf(flattened.positions[3].y-.45) < .000001,"bending independently restores displaced fourth corner to pinned flat rest plane")
	var corrupt := isolated.duplicate(true)
	corrupt.bends[0].vertices[0] = 999
	check(Sewing.relax(corrupt,1,0,1.0/60,{"bending":true}).error != "","invalid bending indices reject before projection")
	check(Sewing.simulate(compiled,0).error != "" and Sewing.simulate(compiled,1,.5).error != "","invalid simulation step count and timestep reject")
	for i in compiled.positions.size():
		if compiled.fabric[i].y == 0:
			compiled.inverse_mass[i] = 0
	var settings := {"bending":true,"bendCompliance":.00001,"contact":collider,"damping":4.0,"iterations":6}
	var started := Time.get_ticks_msec()
	var draped: Dictionary = Sewing.simulate(compiled,180,1.0/120,settings)
	check(draped.error == "","fixed-step gravity, stretch, bend and triangle contact solve completes")
	var minimum_y := INF
	var pin_error := 0.0
	var largest_drop := 0.0
	for i in draped.positions.size():
		minimum_y = minf(minimum_y,draped.positions[i].y)
		largest_drop = maxf(largest_drop,compiled.positions[i].y-draped.positions[i].y)
		if compiled.inverse_mass[i] == 0:
			pin_error = maxf(pin_error,compiled.positions[i].distance_to(draped.positions[i]))
	check(minimum_y >= .00299 and largest_drop > .2,"cloth sags under gravity while ground contact prevents vertex penetration")
	check(pin_error == 0,"sewn-pattern attachment vertices remain fixed during dynamics")
	check(draped.maxRelativeEdgeStretch < .08,"measured dynamic edge strain stays below construction-fixture limit")
	print("Drape metrics: minY=",minimum_y," drop=",largest_drop," maxRelativeEdgeStretch=",draped.maxRelativeEdgeStretch," seconds=",(Time.get_ticks_msec()-started)/1000.0)
	var args := OS.get_cmdline_user_args()
	var body_report := {}
	if args.size() == 2:
		var fitting := ResourceLoader.load(args[1],"ArrayMesh",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
		var actual_body := Contact.new()
		check(fitting != null and actual_body.build_mesh(fitting) == "","build triangle contact from the compiler's complete unmasked body")
		if actual_body.error == "":
			check(actual_body.faces.size() > 1000,"body contact uses source anatomy triangles, not replacement primitives")
			var actual_error := 0.0
			for i in 8:
				var face: Dictionary = actual_body.faces[(i*997)%actual_body.faces.size()]
				var probe: Vector3 = face.center+face.normal*.02
				var minimum := INF
				for triangle in actual_body.faces:
					minimum = minf(minimum,probe.distance_to(Contact.closest_triangle(probe,triangle.a,triangle.b,triangle.c)))
				actual_error = maxf(actual_error,absf(actual_body.nearest(probe).distance-minimum))
			check(actual_error < .000001,"actual body BVH agrees with exhaustive source-triangle distances")
			var bounds := fitting.get_aabb()
			var torso: Dictionary = actual_body.nearest(Vector3(0,bounds.position.y+bounds.size.y*.7,1))
			check(torso.normal.z > .2,"front torso probe confirms outward source winding")
			var crossed: Vector3 = actual_body.resolve(torso.point+torso.normal*.02,torso.point-torso.normal*.01)
			var closest_after := actual_body.nearest(crossed)
			var clearance: float = (crossed-closest_after.point).dot(closest_after.normal)
			check(clearance >= .0029,"swept cloth vertex is kept outside nearest actual torso surface")
			body_report = {"sourceSha256":FileAccess.get_sha256(args[1]),"triangles":actual_body.faces.size(),"bvhNodes":actual_body.nodes.size(),"maxNearestDistanceErrorMetres":actual_error,"torsoSweepClearanceMetres":clearance,"scope":"base-body surface queries and one vertex sweep, not full garment fit or morph extremes"}
			print("Body contact: triangles=",actual_body.faces.size()," BVH nodes=",actual_body.nodes.size()," queryError=",actual_error," bounds=",bounds)
	if args.size() >= 1:
		var mesh: ArrayMesh = Sewing.build_mesh(compiled,draped.positions)
		check(ResourceSaver.save(mesh,args[0]+".res") == OK,"save simulated cloth geometry")
		if DisplayServer.get_name() != "headless":
			await render_review(mesh,args[0]+".png")
		var report := {"status":"drape-construction-fixture-not-costume","vertices":draped.positions.size(),"steps":180,"dt":1.0/120,"minimumGroundSeparationMetres":minimum_y,"maxRelativeEdgeStretch":draped.maxRelativeEdgeStretch,"maxPinnedDisplacementMetres":pin_error,"selfContact":false,"clothEdgeCCD":false,"rendered":DisplayServer.get_name() != "headless","solverSha256":FileAccess.get_sha256("res://sewing-pattern.gd"),"contactSha256":FileAccess.get_sha256("res://cloth-contact.gd")}
		report.bodyContact = body_report
		var file := FileAccess.open(args[0]+".json",FileAccess.WRITE)
		check(file != null,"write measured drape receipt")
		if file != null:
			file.store_string(JSON.stringify(report,"  "))
	print("Drape failures: ",failures)
	quit(1 if failures else 0)

func render_review(mesh: ArrayMesh, path: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(900,700)
	viewport.own_world_3d = true
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var cloth := MeshInstance3D.new()
	cloth.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.12,.32,.43)
	material.roughness = .9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloth.material_override = material
	world.add_child(cloth)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = .85
	world.add_child(camera)
	camera.position = Vector3(.9,.7,1.1)
	camera.look_at(Vector3(0,.23,.2))
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(.12,.14,.17)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = .45
	camera.environment = environment
	var light := DirectionalLight3D.new()
	world.add_child(light)
	light.rotation_degrees = Vector3(-50,-25,0)
	light.light_energy = 1.5
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i in 4:
		await process_frame
	RenderingServer.force_draw(false)
	var rendered := viewport.get_texture().get_image()
	check(rendered.get_width() == 900 and rendered.get_height() == 700,"review capture has requested dimensions")
	var cloth_pixels := 0
	for y in range(0,rendered.get_height(),4):
		for x in range(0,rendered.get_width(),4):
			var color := rendered.get_pixel(x,y)
			if color.b-color.r > .08 and color.g-color.r > .06:
				cloth_pixels += 1
	check(cloth_pixels > 1000,"review capture contains rendered cloth rather than an empty background")
	check(rendered.save_png(path) == OK,"render actual simulated cloth review")
	viewport.queue_free()
