extends SceneTree
## godot --path tools --rendering-method gl_compatibility --script res://build-river-port.gd -- <repo>
## Actual engine build and capture. No generated image is used as a background.
const Kit = preload("res://river-port-kit.gd")
var kit := Kit.new()
var output_dir: String
var repo: String
var camera: Camera3D

func reference_point(pixel: Vector2, height: float) -> Vector3:
	# Source pixels are geometric measurements, not a projected image texture.
	var screen := pixel*Vector2(root.size)/Vector2(1536,1024)
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	return origin+direction*((height-origin.y)/direction.y)

func reference_quay() -> void:
	# Visible perimeter traced from the approved 1536x1024 reference. Segments
	# behind roofs/cliffs are explicitly inferred, not claimed as measured.
	var trace := PackedVector2Array([
		Vector2(139,441),Vector2(142,397),Vector2(179,357),Vector2(220,270),
		Vector2(350,195),Vector2(499,119),Vector2(553,127),Vector2(624,187),
		Vector2(655,228),Vector2(709,253),Vector2(749,317),Vector2(855,285),
		Vector2(984,305),Vector2(1070,253),Vector2(1190,264),Vector2(1320,282),
		Vector2(1380,388),Vector2(1650,600),Vector2(1580,850),Vector2(1430,843),
		Vector2(1310,808),Vector2(1220,795),Vector2(1140,736),Vector2(1070,710),
		Vector2(1048,674),Vector2(979,653),Vector2(948,620),Vector2(918,593),
		Vector2(876,561),Vector2(805,526),Vector2(742,544),Vector2(702,580),
		Vector2(669,617),Vector2(638,638),Vector2(610,641),Vector2(593,629),
		Vector2(571,652),Vector2(532,677),Vector2(487,686),Vector2(454,706),
		Vector2(417,706),Vector2(346,680),Vector2(322,647),Vector2(344,602),
		# Shop foundation turns inward here; there is no broad paved apron.
		Vector2(370,577),Vector2(319,547),Vector2(271,525),Vector2(225,496),Vector2(177,471)
	])
	var outline := PackedVector2Array()
	var minimum := Vector2(INF,INF)
	var maximum := Vector2(-INF,-INF)
	for pixel in trace:
		var point := reference_point(pixel,0.8)
		var point2 := Vector2(point.x,point.z)
		outline.append(point2)
		minimum = minimum.min(point2)
		maximum = maximum.max(point2)
	var center := (minimum+maximum)/2
	for i in outline.size():
		outline[i] -= center
	var area := 0.0
	for i in outline.size():
		area += outline[i].cross(outline[(i+1)%outline.size()])
	if area < 0:
		outline.reverse()
	pavers(Vector3(center.x,0.8,center.y),maximum.x-minimum.x,maximum.y-minimum.y,outline)

func _init() -> void:
	call_deferred("build")

func pavers(center: Vector3, width: float, depth: float, outline_override: PackedVector2Array = PackedVector2Array()) -> void:
	var outline := PackedVector2Array([Vector2(-width/2+0.7,-depth/2),Vector2(width/2-0.9,-depth/2),Vector2(width/2,-depth/2+1),Vector2(width/2,depth/2-0.9),Vector2(width/2-0.85,depth/2),Vector2(-width/2+1,depth/2),Vector2(-width/2,depth/2-1.1),Vector2(-width/2,-depth/2+0.8)])
	if not outline_override.is_empty():
		outline = outline_override
	kit.piece(kit.solid_polygon(outline,1.2,0.1),center-Vector3(0,1.2,0),Vector3.ONE,"mortar")
	var cols := int(width/0.53)
	var rows := int(depth/0.51)
	var w := width/cols
	var d := depth/rows
	var seeds: Array[Vector2] = []
	for z in rows:
		for x in cols:
			seeds.append(Vector2(-width/2+(x+0.5)*w+kit.rng.randf_range(-w*0.43,w*0.43),-depth/2+(z+0.5)*d+kit.rng.randf_range(-d*0.43,d*0.43)))
	for seed_pos in seeds:
		var poly := outline.duplicate()
		for neighbor in seeds:
			if neighbor == seed_pos or neighbor.distance_squared_to(seed_pos) > 5:
				continue
			var n := neighbor-seed_pos
			poly = clip_polygon(poly,n,n.dot((seed_pos+neighbor)/2))
		if poly.size() < 3:
			continue
		for index in poly.size():
			poly[index] = poly[index].move_toward(seed_pos,0.018)-seed_pos
		var mesh := kit.solid_polygon(poly,0.14,0.016)
		kit.piece(mesh,center+Vector3(seed_pos.x,-0.06,seed_pos.y),Vector3.ONE,kit.shade("stone"))
	for index in outline.size():
		var a := outline[index]
		var b := outline[(index+1)%outline.size()]
		var edge := kit.node_group("QuayEdge",center+Vector3((a.x+b.x)/2,-0.95,(a.y+b.y)/2))
		edge.rotation.y = -atan2(b.y-a.y,b.x-a.x)
		kit.wall(a.distance_to(b),0.95,0.42,Vector3.ZERO,edge)
		var count := int(a.distance_to(b)/0.6)+1
		for i in count:
			kit.block(Vector3(-a.distance_to(b)/2+(i+0.5)*a.distance_to(b)/count,1.01,0),Vector3(a.distance_to(b)/count-0.035,0.2,0.5),kit.shade("stone"),edge)

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

func bridge_section(x0: float, x1: float, lower0: float, lower1: float, upper0: float, upper1: float, z0: float, width: float, key: String, parent: Node3D) -> void:
	assert(x1 > x0 and width > 0 and upper0 > lower0 and upper1 > lower1)
	# Extrude the actual sloping section sideways; rotating a centered box only
	# approximates these joints and leaves a staircase silhouette underneath.
	var outline := PackedVector2Array([Vector2(x0,-upper0),Vector2(x1,-upper1),Vector2(x1,-lower1),Vector2(x0,-lower0)])
	var node := kit.piece(kit.solid_polygon(outline,width,0.006),Vector3(0,0,z0),Vector3.ONE,key,parent)
	node.rotation.x = PI/2

func bridge_deck(t: float) -> float:
	return lerpf(0.8,0.3,t)+1.05*sin(t*PI)

func bridge_soffit(t: float) -> float:
	return -0.45+1.3*sin(t*PI)

func bridge() -> void:
	var rear := reference_point(Vector2(855,551),0.8)
	var front := reference_point(Vector2(723,744),0.3)
	var direction := front-rear
	direction.y = 0
	var length := direction.length()
	var g := kit.node_group("StoneArchBridge",Vector3((rear.x+front.x)/2,0,(rear.z+front.z)/2),-atan2(direction.z,direction.x))
	for i in 28:
		var t0 := i/28.0
		var t1 := (i+1)/28.0
		var x0 := (t0-0.5)*length
		var x1 := (t1-0.5)*length
		var top0 := bridge_deck(t0)
		var top1 := bridge_deck(t1)
		var bottom0 := bridge_soffit(t0)
		var bottom1 := bridge_soffit(t1)
		# Closed load-bearing barrel, not two disconnected side ribbons.
		bridge_section(x0,x1,bottom0,bottom1,top0-0.14,top1-0.14,-1.5,3.0,"mortar",g)
		for lane in 5:
			bridge_section(x0+0.006,x1-0.006,top0-0.15,top1-0.15,top0,top1,-1.25+lane*0.5,0.48,kit.shade("stone"),g)
		for z in [-1.56,1.20]:
			# Individual arch stones face the water, with filled spandrels above.
			var arch0 := minf(bottom0+0.28,top0-0.18)
			var arch1 := minf(bottom1+0.28,top1-0.18)
			bridge_section(x0+0.008,x1-0.008,bottom0,bottom1,arch0,arch1,float(z),0.36,kit.shade("stone"),g)
			bridge_section(x0+0.008,x1-0.008,arch0+0.008,arch1+0.008,top0,top1,float(z),0.36,kit.shade("stone"),g)
			for row in 2:
				bridge_section(x0+0.008,x1-0.008,top0+row*0.25,top1+row*0.25,top0+row*0.25+0.24,top1+row*0.25+0.24,float(z),0.36,kit.shade("stone"),g)
			bridge_section(x0+0.004,x1-0.004,top0+0.5,top1+0.5,top0+0.63,top1+0.63,float(z)-0.04,0.44,kit.shade("stone"),g)
	assert(is_equal_approx(bridge_deck(0),rear.y) and is_equal_approx(bridge_deck(1),front.y))
	for end in [-1,1]:
		for z in [-1.37,1.37]:
			kit.wall(0.5,0.95,0.55,Vector3(end*(length/2-0.12),-0.15,float(z)),g)

func dock() -> void:
	# Four traced corners intentionally form a tapered quay landing; the dock
	# has its own axis and is not an extension of the bridge's centerline.
	var back_left := reference_point(Vector2(675,717),0.15)
	var back_right := reference_point(Vector2(853,773),0.15)
	var front_left := reference_point(Vector2(419,898),0.15)
	var front_right := reference_point(Vector2(537,973),0.15)
	var g := kit.node_group("TimberDock",Vector3.ZERO)
	for strip in 19:
		var u0 := (strip+0.045)/19.0
		var u1 := (strip+0.955)/19.0
		for section in 3:
			var t0 := section/3.0+0.003
			var t1 := (section+1)/3.0-0.003
			var a := back_left.lerp(back_right,u0).lerp(front_left.lerp(front_right,u0),t0)
			var b := back_left.lerp(back_right,u1).lerp(front_left.lerp(front_right,u1),t0)
			var c := back_left.lerp(back_right,u1).lerp(front_left.lerp(front_right,u1),t1)
			var d := back_left.lerp(back_right,u0).lerp(front_left.lerp(front_right,u0),t1)
			var outline := PackedVector2Array([Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z),Vector2(d.x,d.z)])
			var area := 0.0
			for i in 4:
				area += outline[i].cross(outline[(i+1)%4])
			if area < 0:
				outline.reverse()
			kit.piece(kit.solid_polygon(outline,0.13,0.01),Vector3(0,0.02,0),Vector3.ONE,kit.shade("wood"),g)
			for p in [a,b,c,d]:
				kit.cylinder(p+Vector3(0,0.008,0),0.018,0.012,"iron",g)
	for edge in [[back_left,front_left],[back_right,front_right]]:
		var start: Vector3 = edge[0]
		var finish: Vector3 = edge[1]
		kit.beam(start-Vector3(0,0.12,0),finish-Vector3(0,0.12,0),0.22,"oak",g)
		for t in [0.0,0.5,1.0]:
			var p := start.lerp(finish,t)
			kit.cylinder(p-Vector3(0,0.3,0),0.16,1.8,"oak",g,20)
			kit.cylinder(p+Vector3(0,0.63,0),0.195,0.10,"oak_light",g,24)
			for y in [0.30,0.34,0.38,0.42]:
				kit.ring(p+Vector3(0,y,0),0.17,0.018,"sand",g)
		for segment in 2:
			for i in 12:
				var t0 := (segment+i/12.0)/2
				var t1 := (segment+(i+1)/12.0)/2
				kit.beam(start.lerp(finish,t0)+Vector3(0,0.42-0.2*sin(i*PI/12),0),start.lerp(finish,t1)+Vector3(0,0.42-0.2*sin((i+1)*PI/12),0),0.026,"sand",g)
	var post := back_left.lerp(front_left,0.08)
	var arm := (front_right-front_left).normalized()*-1.0
	kit.beam(post,post+Vector3(0,2.65,0),0.14,"oak",g)
	kit.beam(post+Vector3(0,2.65,0),post+Vector3(0,2.65,0)+arm,0.13,"oak",g)
	kit.beam(post+Vector3(0,2.0,0),post+Vector3(0,2.65,0)+arm*0.8,0.10,"oak",g)
	kit.beam(post+Vector3(0,2.65,0)+arm,post+Vector3(0,0.65,0)+arm,0.03,"sand",g)

func rowboat(pos: Vector3) -> void:
	var g := kit.node_group("Reference_Clinker_Rowboat",pos,-0.225)
	# Closed thin plank strips follow a pointed curved hull, not a solid block.
	for side in [-1,1]:
		for row in 6:
			for segment in 24:
				var corners: Array[Vector3] = []
				for q in [Vector2(row,segment),Vector2(row+1,segment),Vector2(row+1,segment+1),Vector2(row,segment+1)]:
					var v: float = q.x/6.0
					var t: float = q.y/24.0
					var z := (t-0.5)*4.3
					var width := pow(sin(PI*(0.02+t*0.96)),0.8)*(0.18+0.59*v)
					corners.append(Vector3(side*width,-0.18+v*0.65+0.24*pow(abs(z/2.15),4),z))
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				st.set_smooth_group(-1)
				var vertices := corners.duplicate()
				for p in corners:
					vertices.append(p+Vector3(-side*0.045,0.018,0))
				for face in [[0,1,2,3],[7,6,5,4],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]]:
					for index in ([0,2,1,0,3,2] if side == 1 else [0,1,2,0,2,3]):
						st.add_vertex(vertices[face[index]])
				st.generate_normals()
				kit.piece(st.commit(),Vector3.ZERO,Vector3.ONE,kit.shade("wood"),g)
				if row == 5:
					kit.beam(corners[1]+Vector3(0,0.025,0),corners[2]+Vector3(0,0.025,0),0.075,"oak_light",g)
		for rib in 9:
			var z := -1.65+rib*0.41
			var width := pow(sin(PI*(0.02+(z/4.3+0.5)*0.96)),0.8)
			for row in 5:
				var v0 := row/5.0
				var v1 := (row+1)/5.0
				kit.beam(Vector3(side*width*(0.18+0.54*v0),-0.13+v0*0.65,z),Vector3(side*width*(0.18+0.54*v1),-0.13+v1*0.65,z),0.065,"oak_light",g)
	for z in [-0.95,0.0,0.95]:
		kit.block(Vector3(0,0.27,z),Vector3(1.18,0.07,0.27),"wood7",g)
	for x in [-0.1,0.0,0.1]:
		kit.block(Vector3(x,-0.11,0),Vector3(0.095,0.05,3.0),"wood4",g)
	kit.beam(Vector3(-0.7,0.36,-1.5),Vector3(0.9,0.42,1.8),0.045,"oak_light",g)
	var blade := kit.block(Vector3(0.85,0.4,1.7),Vector3(0.15,0.025,0.6),"wood6",g)
	blade.rotation.y = 0.45

func source_model(filename: String, pos: Vector3, scale_value: float, rotation_y: float = 0) -> void:
	var source := repo.path_join("resource_packs/terrain/tabletop-foundation/artifacts/models/").path_join(filename)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	assert(doc.append_from_file(source,state) == OK)
	var node := doc.generate_scene(state) as Node3D
	node.position = pos
	node.scale = Vector3.ONE*scale_value
	node.rotation.y = rotation_y
	for mesh in collect_meshes(node):
		mesh.material_override = kit.mat("wood4")
		if filename == "boat-row-small.glb":
			mesh.material_override = kit.mat("wood6")
		else:
			for surface in mesh.mesh.get_surface_count():
				var original := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
				if original != null:
					var adjusted := original.duplicate() as StandardMaterial3D
					adjusted.albedo_color *= Color(0.55,0.58,0.62)
					mesh.set_surface_override_material(surface,adjusted)
	kit.root.add_child(node)

func collect_meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(collect_meshes(child))
	return result

func node_marker(pos: Vector3) -> void:
	kit.cylinder(pos+Vector3(0,0.075,0),0.21,0.14,"gold",kit.root,32)
	kit.cylinder(pos+Vector3(0,0.16,0),0.14,0.045,"gold",kit.root,32)
	kit.cylinder(pos+Vector3(0,0.015,0),0.27,0.035,"iron",kit.root,32)

func path_connection(a: Vector3,b: Vector3) -> void:
	kit.beam(a+Vector3(0,0.04,0),b+Vector3(0,0.04,0),0.045,"gold")

func pawn(pos: Vector3, cloth: String) -> void:
	# Authored rigid-piece study rig. Not a final sculpt or skinned cloth asset.
	var g := kit.node_group("Rigged_Figure_Study",pos)
	g.rotation.y = -0.2
	kit.cylinder(Vector3(0,0.055,0),0.5,0.11,"iron",g,48)
	kit.ring(Vector3(0,0.115,0),0.43,0.018,"oak_light",g)
	var skeleton := Skeleton3D.new()
	skeleton.name = "StudySkeleton"
	g.add_child(skeleton)
	var definition := [
		["Hips",-1,Vector3(0,0.9,0)],["Chest",0,Vector3(0,0.42,0)],
		["Head",1,Vector3(0,0.38,0)],
		["UpperArmL",1,Vector3(-0.27,0,0)],["ForearmL",3,Vector3(-0.08,-0.26,0.04)],["HandL",4,Vector3(0,-0.23,0.07)],
		["UpperArmR",1,Vector3(0.27,0,0)],["ForearmR",6,Vector3(0.13,-0.23,0.06)],["HandR",7,Vector3(0.02,-0.22,0.06)],
		["ThighL",0,Vector3(-0.13,-0.08,0)],["ShinL",9,Vector3(-0.03,-0.34,0.04)],["FootL",10,Vector3(0,-0.28,0.07)],
		["ThighR",0,Vector3(0.13,-0.08,0)],["ShinR",12,Vector3(0.04,-0.34,-0.02)],["FootR",13,Vector3(0,-0.28,0.07)]
	]
	var parts: Dictionary = {}
	for row in definition:
		var index := skeleton.get_bone_count()
		skeleton.add_bone(row[0])
		skeleton.set_bone_parent(index,row[1])
		skeleton.set_bone_rest(index,Transform3D(Basis.IDENTITY,row[2]))
		skeleton.set_bone_pose_position(index,row[2])
		var attachment := BoneAttachment3D.new()
		attachment.name = row[0]+"Mount"
		attachment.bone_name = row[0]
		skeleton.add_child(attachment)
		parts[row[0]] = attachment
	var armored := cloth == "cloth"
	var body_mat := "iron" if armored else "wood3"
	kit.ellipsoid(Vector3(0,-0.12,0),Vector3(0.25,0.29,0.15),body_mat,parts.Chest)
	kit.ellipsoid(Vector3(0,0.03,0),Vector3(0.15,0.2,0.14),"skin",parts.Head)
	kit.ellipsoid(Vector3(0,0.04,0.14),Vector3(0.033,0.055,0.048),"skin",parts.Head)
	for side in [-1,1]:
		kit.ellipsoid(Vector3(side*0.06,0.085,0.127),Vector3(0.019,0.012,0.01),"iron",parts.Head)
		var label := "L" if side == -1 else "R"
		kit.ellipsoid(Vector3(0,-0.1,0),Vector3(0.12,0.17,0.12),body_mat,parts["UpperArm"+label])
		kit.ellipsoid(Vector3(0,-0.1,0),Vector3(0.085,0.15,0.09),body_mat,parts["Forearm"+label])
		kit.ellipsoid(Vector3(0,-0.025,0.025),Vector3(0.065,0.09,0.065),"skin",parts["Hand"+label])
		kit.ellipsoid(Vector3(0,-0.14,0),Vector3(0.11,0.2,0.12),body_mat,parts["Thigh"+label])
		kit.ellipsoid(Vector3(0,-0.11,0),Vector3(0.09,0.16,0.1),body_mat,parts["Shin"+label])
		kit.ellipsoid(Vector3(0,-0.015,0.065),Vector3(0.105,0.085,0.19),"oak",parts["Foot"+label])
		kit.ellipsoid(Vector3(0,0.015,0.01),Vector3(0.17,0.11,0.19),body_mat,parts["UpperArm"+label])
		kit.ring(Vector3(0,-0.13,0),0.10,0.015,"gold",parts["Forearm"+label])
	kit.cylinder(Vector3(0,0.01,0),0.24,0.075,"oak",parts.Hips,32).scale.z = 0.68
	kit.block(Vector3(0,0.01,0.175),Vector3(0.09,0.075,0.025),"gold",parts.Hips)
	if armored:
		kit.ellipsoid(Vector3(0,0.1,-0.005),Vector3(0.17,0.18,0.16),"iron",parts.Head)
		kit.block(Vector3(0,0.09,0.152),Vector3(0.26,0.035,0.04),"oak",parts.Head)
		kit.beam(Vector3(0,0.08,0.18),Vector3(0,-0.08,0.15),0.035,"gold",parts.Head)
		for side in [-1,1]:
			kit.beam(Vector3(side*0.18,0.08,0.1),Vector3(side*0.1,-0.25,0.16),0.035,"gold",parts.Chest)
		# Blue surcoat panels leave articulated legs visible.
		for side in [-1,1]:
			kit.block(Vector3(side*0.13,-0.25,0.13),Vector3(0.2,0.5,0.055),"cloth",parts.Hips)
		kit.beam(Vector3(0,0.03,0.03),Vector3(0,-0.72,0.13),0.05,"stone9",parts.HandR)
		kit.beam(Vector3(-0.12,0,0.03),Vector3(0.12,0,0.03),0.045,"gold",parts.HandR)
		kit.block(Vector3(0,-0.05,0.09),Vector3(0.38,0.6,0.1),"cloth",parts.HandL)
		for x in [-0.19,0.19]:
			kit.beam(Vector3(x,0.25,0.15),Vector3(x,-0.35,0.15),0.025,"gold",parts.HandL)
		kit.beam(Vector3(0,0.18,0.16),Vector3(0,-0.24,0.16),0.025,"gold",parts.HandL)
	else:
		# Fine radial pleats form a robe, rather than the former plain cylinder.
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for row in 12:
			for col in 64:
				var points: Array[Vector3] = []
				for uv in [Vector2(row,col),Vector2(row+1,col),Vector2(row+1,col+1),Vector2(row,col+1)]:
					var t: float = uv.x/12.0
					var angle: float = uv.y*TAU/64.0
					var radius: float = 0.21+0.16*t+0.026*sin(angle*12)*t
					points.append(Vector3(cos(angle)*radius,-t*0.7,sin(angle)*radius*0.8))
				for index in [0,1,2,0,2,3]:
					st.add_vertex(points[index])
		st.generate_normals()
		kit.piece(st.commit(),Vector3.ZERO,Vector3.ONE,"moss",parts.Hips)
		for side in [-1,1]:
			kit.beam(Vector3(side*0.13,0.1,0.14),Vector3(side*0.1,-0.3,0.18),0.025,"gold",parts.Chest)
		kit.ellipsoid(Vector3(0,0.14,-0.045),Vector3(0.17,0.19,0.12),"stone9",parts.Head)
		kit.ellipsoid(Vector3(0,-0.08,0.08),Vector3(0.09,0.16,0.08),"stone9",parts.Head)
		kit.beam(Vector3(0,-0.7,0.06),Vector3(0,1.0,0.06),0.045,"oak_light",parts.HandR)
		kit.ring(Vector3(0,1.03,0.06),0.12,0.025,"gold",parts.HandR,true)
		kit.ellipsoid(Vector3(0,1.03,0.06),Vector3.ONE*0.055,"gold",parts.HandR)
	# Rest-pose attachments are the rig contract; no animation is authored.
	skeleton.force_update_all_bone_transforms()

func dormer(parent: Node3D, pos: Vector3, facing: float, prefix: String) -> void:
	var g := Node3D.new()
	g.name = "ReferenceDormer"
	parent.add_child(g)
	g.position = pos
	g.rotation.y = facing
	kit.block(Vector3(0,0.62,0),Vector3(1.1,1.25,1.15),"plaster",g)
	kit.window_at(Vector3(0,0.6,0.6),g,0.7)
	kit.roof(1.25,1.3,1.25,0.55,prefix,g)
	for x in [-0.52,0.52]:
		kit.block(Vector3(x,0.65,0.65),Vector3(0.12,1.3,0.14),"oak",g)

func chimney(parent: Node3D, pos: Vector3, height: float, width: float = 0.75) -> void:
	kit.wall(width,height,width,pos,parent)
	for side in [-1,1]:
		kit.block(pos+Vector3(side*width*0.42,height+0.05,0),Vector3(width*0.22,0.2,width+0.2),"stone8",parent)
		kit.block(pos+Vector3(0,height+0.05,side*width*0.42),Vector3(width+0.2,0.2,width*0.22),"stone8",parent)
	kit.block(pos+Vector3(0,height-0.07,0),Vector3(width*0.65,0.03,width*0.65),"iron",parent)

func construct_inn() -> void:
	var inn := kit.house("Reference_L_Shaped_Inn",Vector3(1.5,1.05,-7.7),4.6,5.8,5.3,3.35,"roof")
	# Intersecting wing produces the reference's compound roof silhouette.
	var wing := kit.house("Inn_Right_Entrance_Wing",Vector3(3.9,1.05,-8.0),4.4,6.5,4.9,2.5,"roof")
	wing.rotation.y = PI/2
	# Match the reference's lower building mass above its higher rear landing.
	for building in [inn,wing]:
		building.position += Vector3(-1.35,0,-2.12)
		building.scale.y = 0.85
	for g in [inn,wing]:
		var width: float = 4.6 if g == inn else 4.4
		var depth: float = 5.8 if g == inn else 6.5
		for z in [-depth/2-0.22,depth/2+0.22]:
			kit.block(Vector3(0,3.05,z),Vector3(width+0.45,1.95,0.12),"plaster",g)
			for y in [2.1,2.4,4.05,4.85]:
				kit.block(Vector3(0,y,z+0.08),Vector3(width+0.5,0.16,0.16),"oak",g)
			for x in [-width/2,-width/4,0,width/4,width/2]:
				kit.block(Vector3(x,3.55,z+0.1),Vector3(0.18,2.8,0.18),"oak",g)
			for x in [-width*0.29,width*0.29]:
				kit.window_at(Vector3(x,3.25,z+0.15),g,0.9)
		for side in [-1,1]:
			var facade := Node3D.new()
			g.add_child(facade)
			facade.position.x = side*(width/2+0.2)
			facade.rotation.y = side*PI/2
			kit.block(Vector3(0,3.25,0),Vector3(depth,2.0,0.12),"plaster",facade)
			for y in [2.25,4.2,4.85]:
				kit.block(Vector3(0,y,0.12),Vector3(depth,0.18,0.18),"oak",facade)
			for x in [-depth*0.35,0,depth*0.35]:
				kit.block(Vector3(x,3.5,0.12),Vector3(0.17,2.8,0.17),"oak",facade)
				kit.window_at(Vector3(x+0.4,3.25,0.16),facade,0.62)
		for x in [-width/2,width/2]:
			for row in 6:
				kit.block(Vector3(x,row*0.34+0.17,depth/2+0.23),Vector3(0.62 if row%2 else 0.42,0.3,0.5),kit.shade("stone"),g)
	chimney(inn,Vector3(-2.1,4.8,-1.1),3.7)
	chimney(wing,Vector3(1.2,4.4,-2.6),2.5)
	dormer(inn,Vector3(1.65,6.0,0.4),PI/2,"roof")
	dormer(wing,Vector3(1.0,5.3,0.65),PI/2,"roof")
	kit.window_at(Vector3(0,6.3,3.16),inn,0.9)
	for side in [-1,1]:
		kit.beam(Vector3(side*2.7,5.4,3.15),Vector3(side*1.0,7.2,3.15),0.15,"oak",inn)
	# Curved blue fabric awning, thin gold ribs rather than a striped flat slab.
	for col in 16:
		for row in 8:
			var t := (row+0.5)/8.0
			kit.block(Vector3(-2.55+col*0.22,2.4-0.42*sin(t*PI/2),3.02+t*1.25),Vector3(0.215,0.045,0.18),"cloth",inn)
		for row in 7:
			var t0 := row/7.0
			var t1 := (row+1)/7.0
			kit.beam(Vector3(-2.55+col*0.22,2.43-0.42*sin(t0*PI/2),3.02+t0*1.25),Vector3(-2.55+col*0.22,2.43-0.42*sin(t1*PI/2),3.02+t1*1.25),0.012,"gold",inn)
	kit.stairs(Vector3(0,-0.5,3.35),2.25,0.8,1.6,wing)
	kit.beam(Vector3(-3.05,4.1,3),Vector3(-4.2,4.1,3),0.14,"oak",inn)
	kit.beam(Vector3(-3.05,3.5,3),Vector3(-4.15,4.1,3),0.1,"oak",inn)
	kit.ring(Vector3(-4,3.4,3),0.58,0.055,"gold",inn,true)
	kit.ring(Vector3(-4,3.4,3),0.46,0.02,"gold",inn,true)
	for i in 8:
		var a := TAU*i/8
		kit.beam(Vector3(-4,3.4,3),Vector3(-4+cos(a)*0.4,3.4+sin(a)*0.4,3),0.04,"gold",inn)
	for pos in [reference_point(Vector2(813,309),1.65)-Vector3(0,0.7,0),reference_point(Vector2(854,329),1.65)-Vector3(0,0.7,0)]:
		kit.cylinder(pos+Vector3(0,0.7,0),0.47,0.1,"oak_light",kit.root,32)
		kit.cylinder(pos+Vector3(0,0.35,0),0.11,0.7,"oak",kit.root)
		for a in [0.0,2.1,4.2]:
			var seat: Vector3 = pos+Vector3(cos(a)*0.67,0.35,sin(a)*0.67)
			kit.cylinder(seat,0.19,0.12,"oak_light",kit.root)
			kit.cylinder(seat-Vector3(0,0.15,0),0.05,0.3,"oak",kit.root)

func construct_shop() -> void:
	var shop := kit.house("Reference_Cutaway_Apothecary",Vector3(-7.45,1.1,3.3),6.2,5.4,3.4,2.0,"slate",true)
	shop.scale = Vector3(1.15,1.1,1.15)
	kit.shelving(shop,Vector3(-1.5,0.3,-2.28))
	kit.shelving(shop,Vector3(0.85,0.3,-2.28))
	# Side wall shelf is turned into the open interior, not facing the camera.
	var side := Node3D.new()
	shop.add_child(side)
	side.position = Vector3(2.7,0,0)
	side.rotation.y = -PI/2
	kit.shelving(side,Vector3(0,0.3,0))
	kit.block(Vector3(-0.2,0.87,0.75),Vector3(3.2,1.1,0.85),"oak",shop)
	kit.block(Vector3(-0.2,1.47,0.75),Vector3(3.4,0.16,1.0),"oak_light",shop)
	for x in [-1.55,-0.9,-0.2,0.5,1.15]:
		kit.block(Vector3(x,0.95,1.2),Vector3(0.1,0.8,0.08),"oak_light",shop)
	for i in 13:
		kit.cylinder(Vector3(kit.rng.randf_range(-1.6,1.3),1.65,kit.rng.randf_range(0.4,1.1)),kit.rng.randf_range(0.055,0.1),kit.rng.randf_range(0.12,0.27),kit.shade("roof"),shop)
	# The reference roof is a substantial rear roof, not a small lean-to.
	var canopy := Node3D.new()
	shop.add_child(canopy)
	canopy.position = Vector3(0,3.65,-1.9)
	canopy.rotation.y = PI/2
	kit.roof(2.3,6.5,0,1.6,"slate",canopy)
	dormer(shop,Vector3(1.35,3.55,-0.6),0,"slate")
	chimney(shop,Vector3(-2.9,0.3,1.0),5.2,0.8)
	for z in [-2.7,0,2.7]:
		kit.block(Vector3(-3.15,1.1,z),Vector3(0.6,2.2,0.6),"stone6",shop)
	for x in [-3.1,3.1]:
		kit.block(Vector3(x,0.85,2.7),Vector3(0.6,0.18,0.65),"stone9",shop)
	kit.banner(Vector3(-0.9,1.25,2.94),2.3,0.95,shop)
	# Cutaway deliberately omits the front upper wall and overhead beam.
	kit.stairs(Vector3(2.8,-0.3,2.9),1.25,0.6,1.1,shop,false)
	kit.lantern(Vector3(2.5,2.0,2.9),shop)
	for i in 6:
		kit.shrub(Vector3(-9.7+i*1.0,0.9,2.45),0.35)

func construct_guild() -> void:
	var guild := kit.house("Reference_Ornate_Guild",Vector3(14.8,1.4,-2.5),5.5,7.0,5.5,4.1,"slate",false,"stone6",false,1.7,2.7)
	guild.scale = Vector3(0.92,1.05,0.92)
	guild.rotation.y = 0.32
	# Layered stone pediment surrounds the roof edge and carries gold finials.
	for z in [-3.75,3.75]:
		for inset in [0.0,0.18,0.34]:
			kit.beam(Vector3(-3.1,5.45-inset,z),Vector3(0,9.85-inset,z),0.19,"stone7",guild)
			kit.beam(Vector3(0,9.85-inset,z),Vector3(3.1,5.45-inset,z),0.19,"stone7",guild)
		kit.spire(Vector3(0,9.97,z),guild,0.9)
	for x in [-2.65,2.65]:
		for z in [-3.5,0,3.5]:
			for tier in 4:
				kit.wall(0.62-tier*0.06,1.35,0.64-tier*0.05,Vector3(x,tier*1.35,z),guild)
				kit.block(Vector3(x,tier*1.35+1.3,z),Vector3(0.83-tier*0.05,0.16,0.8-tier*0.05),"stone8",guild)
			kit.spire(Vector3(x,5.6,z),guild,0.65)
	kit.block(Vector3(0,4.4,3.73),Vector3(5.8,0.23,0.4),"stone7",guild)
	kit.block(Vector3(0,4.65,3.72),Vector3(5.55,0.16,0.32),"stone9",guild)
	for side in [-1,1]:
		kit.beam(Vector3(side*2.5,4.7,3.75),Vector3(0,7.2,3.75),0.32,"stone8",guild)
		kit.beam(Vector3(side*2.6,4.8,3.8),Vector3(0,7.4,3.8),0.11,"stone5",guild)
	kit.cylinder(Vector3(0,5.75,3.96),0.84,0.13,"oak",guild,64).rotation.x = PI/2
	for radius in [0.88,0.76,0.59]:
		kit.ring(Vector3(0,5.75,4.06),radius,0.035,"gold",guild,true)
	for i in 12:
		var a := TAU*i/12
		kit.cylinder(Vector3(cos(a)*0.7,5.75+sin(a)*0.7,4.08),0.04,0.06,"gold",guild).rotation.x = PI/2
		kit.beam(Vector3(cos(a)*0.25,5.75+sin(a)*0.25,4.09),Vector3(cos(a)*0.5,5.75+sin(a)*0.5,4.09),0.045,"gold",guild)
	kit.ring(Vector3(0,5.75,4.1),0.25,0.04,"gold",guild,true)
	for x in [-1.82,1.82]:
		kit.banner(Vector3(x,4.35,3.98),0.83,3.8,guild)
		kit.lantern(Vector3(x*0.61,1.8,4.08),guild)
	kit.stairs(Vector3(0,-0.8,3.65),3.1,0.9,1.65,guild)
	# Tall pointed planting at both sides of the entrance.
	for x in [-3.35,3.35]:
		kit.cylinder(Vector3(x,0.15,3.7),0.47,0.5,"stone7",guild,24)
		for i in 7:
			kit.shrub(Vector3(x,0.4+i*0.35,3.7),0.62*(1-i/9.0),guild)

func build() -> void:
	var args := OS.get_cmdline_user_args()
	assert(args.size() >= 1,"Expected absolute repository path; optional --inspect")
	repo = args[0]
	output_dir = repo.path_join("docs/river-port-build")
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1800,1200)
	root.msaa_3d = Viewport.MSAA_4X
	root.use_taa = true
	RenderingServer.directional_shadow_atlas_set_size(8192,true)
	if args.size() == 2 and args[1] == "--inspect":
		await inspect_saved_scene()
		return
	root.add_child(kit.root)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23.0
	kit.root.add_child(camera)
	camera.position = Vector3(29,33,46)
	camera.look_at(Vector3(1.0,1.7,2.0))
	camera.current = true
	kit.setup_palette()
	kit.apply_surface_sources(repo)
	# Water shader is static spatial material; no animation or time dependency.
	var shader := Shader.new()
	shader.code = """shader_type spatial;
varying vec3 world_position;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float water(vec2 p){return noise(p)*0.5+noise(p*2.1)*0.25+noise(p*4.3)*0.125+noise(p*8.1)*0.065;}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){vec2 p=world_position.xz*vec2(4.4,7.2);float n=water(p);ALBEDO=mix(vec3(0.008,0.022,0.027),vec3(0.032,0.065,0.075),n);ROUGHNESS=0.9;SPECULAR=0.0;METALLIC=0.0;}
"""
	var water_mat := ShaderMaterial.new()
	water_mat.shader = shader
	var water = kit.block(Vector3(3,-0.48,1),Vector3(90,0.18,90),"water")
	water.material_override = water_mat
	# Layout reconstructed from the approved image: broad plaza, left cutaway,
	# compound inn at rear, tall guild right, bridge and dock toward the viewer.
	reference_quay()
	construct_inn()
	construct_shop()
	construct_guild()
	bridge()
	dock()
	rowboat(reference_point(Vector2(724,903),-0.14))
	source_model("crate.glb",reference_point(Vector2(807,761),0.23),0.28)
	# Irregular sand shelves with varied outlines, not square beach blocks.
	for bank in [reference_point(Vector2(271,648),-0.43),reference_point(Vector2(1220,886),-0.43),reference_point(Vector2(82,577),-0.43)]:
		var outline := PackedVector2Array()
		for i in 32:
			var a := TAU*i/32
			var radius := kit.rng.randf_range(0.85,1.15)
			outline.append(Vector2(cos(a)*3.4,sin(a)*1.7)*radius)
		kit.piece(kit.solid_polygon(outline,0.14,0.025),bank,Vector3.ONE,"sand")
		for i in 65:
			var a := kit.rng.randf()*TAU
			var r := kit.rng.randf()
			kit.rock(bank+Vector3(cos(a)*3.3*r,0.1,sin(a)*1.65*r),Vector3(0.15,0.09,0.2)*kit.rng.randf_range(0.5,2.5))
		for i in 90:
			var a: Vector3 = bank+Vector3(kit.rng.randf_range(-2.5,2.5),0.15,kit.rng.randf_range(-1,1))
			kit.beam(a,a+Vector3(kit.rng.randf_range(-0.3,0.3),kit.rng.randf_range(0.45,1.6),kit.rng.randf_range(-0.2,0.2)),0.025,"reed")
	# Stacked rocky bank at the shop side, low boulders behind the inn.
	for i in 90:
		var z := kit.rng.randf_range(-10,3.5)
		var x := kit.rng.randf_range(-17.2,-14.5)
		kit.rock(Vector3(x,kit.rng.randf_range(-0.4,1.6),z),Vector3(kit.rng.randf_range(0.8,2.1),kit.rng.randf_range(0.6,1.7),kit.rng.randf_range(0.9,1.6)))
	for i in 35:
		kit.rock(Vector3(kit.rng.randf_range(-9,13),-0.1,kit.rng.randf_range(-12,-10)),Vector3(1.2,0.8,1.0)*kit.rng.randf_range(0.7,1.5))
	for pos in [reference_point(Vector2(175,361),1.3),reference_point(Vector2(323,306),1.3),reference_point(Vector2(1302,310),0.8)]:
		kit.tree(pos,5.8)
	for i in 38:
		kit.shrub(Vector3(kit.rng.randf_range(-13,-11.5),0.9,kit.rng.randf_range(-9,1)),kit.rng.randf_range(0.35,0.7))
	for pos in [Vector3(7.9,0.9,-0.7),Vector3(5.9,0.9,-1.3),Vector3(-3.9,0.85,-2.6)]:
		kit.shrub(pos,0.65,kit.root,true)
	# Moss lives at joins and edges, not as a uniform green tint.
	for i in 230:
		var pos := Vector3(kit.rng.randf_range(-11,13),0.88,kit.rng.randf_range(-8,6))
		kit.rock(pos,Vector3(kit.rng.randf_range(0.07,0.21),0.012,kit.rng.randf_range(0.08,0.3))).material_override = kit.mat("moss")
	# Reference gold points form a branching, partly elevated network.
	var nodes: Array[Vector3] = []
	for marker in [Vector3(535,138,0.93),Vector3(617,211,0.93),Vector3(640,410,0.93),Vector3(752,497,0.93),Vector3(751,430,2.65),Vector3(926,401,2.5),Vector3(928,462,0.93),Vector3(974,570,0.93),Vector3(960,474,3.3),Vector3(1112,446,2.0),Vector3(1112,505,0.93),Vector3(1048,652,0.93),Vector3(1224,785,0.93),Vector3(558,577,0.93),Vector3(609,600,0.93)]:
		nodes.append(reference_point(Vector2(marker.x,marker.y),marker.z))
	for p in nodes:
		node_marker(p)
	for edge in [Vector2i(0,1),Vector2i(1,2),Vector2i(2,3),Vector2i(3,4),Vector2i(4,5),Vector2i(5,6),Vector2i(6,7),Vector2i(7,8),Vector2i(8,9),Vector2i(9,10),Vector2i(10,11),Vector2i(11,12),Vector2i(2,13),Vector2i(13,14)]:
		path_connection(nodes[edge.x],nodes[edge.y])
	pawn(reference_point(Vector2(678,523),0.92),"cloth")
	pawn(reference_point(Vector2(819,482),0.92),"moss")
	pawn(reference_point(Vector2(1019,553),0.92),"moss")
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	var env := environment.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("293b3d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a9b6bd")
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		env.ssao_enabled = true
		env.ssao_radius = 1.3
		env.ssao_intensity = 1.6
		env.glow_enabled = true
		env.glow_intensity = 0.35
	kit.root.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-38,0)
	sun.light_color = Color("fff0d5")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_bias = 0.12
	sun.shadow_normal_bias = 1.5
	kit.root.add_child(sun)
	# Ground-only proof uses the same geometry and camera, with buildings hidden.
	var hidden_buildings: Array[Node3D] = []
	for child in kit.root.get_children():
		if child is Node3D and (str(child.name).begins_with("Reference_") or str(child.name).begins_with("Inn_Right")) and not str(child.name).contains("Rowboat"):
			hidden_buildings.append(child)
			child.visible = false
	for frame in 32:
		await process_frame
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(output_dir.path_join("river-port-ground.png")) == OK)
	for child in hidden_buildings:
		child.visible = true
	for frame in 32:
		await process_frame
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(output_dir.path_join("river-port-main.png")) == OK)
	assign_owners(kit.root,kit.root)
	var packed := PackedScene.new()
	assert(packed.pack(kit.root) == OK)
	assert(ResourceSaver.save(packed,output_dir.path_join("river-port-native.scn")) == OK)
	# Save complete model geometry for independent import and alternate cameras.
	# Interchange export is deliberately geometry-only. The native scene is
	# the visual artifact: it retains triplanar textures and custom water.
	# Clearing texture references here avoids embedding identical source maps
	# once per palette material in an otherwise misleading GLB.
	var retained_textures: Dictionary = {}
	for key in kit.materials:
		var material: StandardMaterial3D = kit.materials[key]
		retained_textures[key] = [material.albedo_texture,material.normal_texture,material.normal_enabled]
		material.albedo_texture = null
		material.normal_texture = null
		material.normal_enabled = false
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	assert(doc.append_from_scene(kit.root,state) == OK)
	assert(doc.write_to_filesystem(state,output_dir.path_join("river-port-scene.glb")) == OK)
	for key in retained_textures:
		var material: StandardMaterial3D = kit.materials[key]
		material.albedo_texture = retained_textures[key][0]
		material.normal_texture = retained_textures[key][1]
		material.normal_enabled = retained_textures[key][2]
	camera.position = Vector3(-29,26,33)
	camera.look_at(Vector3(2,1.3,0.5))
	for frame in 24:
		await process_frame
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(output_dir.path_join("river-port-alternate.png")) == OK)
	var file := FileAccess.open(output_dir.path_join("build-report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"generator":"tools/build-river-port.gd + tools/river-port-kit.gd","engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"materialSources":kit.material_sources,"seed":5012026,"geometryPieces":kit.counts.pieces,"meshInstances":collect_meshes(kit.root).size(),"referenceImageSha256":FileAccess.get_sha256(repo.path_join("docs/visual-reference/painted-miniature-river-port-approved.png")),"referenceDimensions":[1536,1024],"groundMethod":"Manual visible perimeter and dock-corner pixel traces intersected with the camera ground plane; hidden perimeter inferred. Not a perceptual similarity score.","renderedObjects":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),"renderedPrimitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"drawCalls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"status":"authored environment study; not reference-matched or runtime-admitted","actors":"three 15-bone rigid-piece study rigs; not skinned or production character sculpts","exportNote":"Native .scn preserves procedural water and world triplanar materials; GLB is a geometry interchange proof and does not preserve those renderer-specific materials.","sceneSha256":FileAccess.get_sha256(output_dir.path_join("river-port-scene.glb"))},"\t")+"\n")
	file.close()
	print("Built river port: %d authored pieces" % kit.counts.pieces)
	quit()

func assign_owners(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		assign_owners(child,owner_node)

func inspect_saved_scene() -> void:
	kit.root.free()
	var packed := load(output_dir.path_join("river-port-native.scn")) as PackedScene
	assert(packed != null,"Native scene must reload independently")
	var loaded := packed.instantiate()
	root.add_child(loaded)
	var meshes := collect_meshes(loaded)
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output_dir.path_join("build-report.json")))
	assert(meshes.size() == int(report.meshInstances),"Native mesh count must match generated scene")
	var skeletons := loaded.find_children("*","Skeleton3D",true,false)
	assert(skeletons.size() == 3)
	for skeleton in skeletons:
		assert(skeleton.get_bone_count() == 15)
		assert(skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin.y > 1.5)
	for mesh in meshes:
		assert(mesh.transform.is_finite() and mesh.mesh != null)
		assert(mesh.mesh.get_aabb().size.length() > 0)
	for frame in 32:
		await process_frame
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(output_dir.path_join("river-port-roundtrip.png")) == OK)
	var camera := root.get_camera_3d()
	assert(camera != null)
	camera.position = Vector3(30,25,-35)
	camera.look_at(Vector3(2,1.3,0.5))
	for frame in 24:
		await process_frame
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(output_dir.path_join("river-port-rear.png")) == OK)
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	assert(document.append_from_file(output_dir.path_join("river-port-scene.glb"),state) == OK)
	var imported := document.generate_scene(state)
	assert(imported != null)
	var imported_meshes := collect_meshes(imported)
	assert(imported_meshes.size() == meshes.size(),"GLB must retain every mesh instance")
	imported.free()
	print("PASS: native roundtrip and GLB import; %d mesh instances; front and rear captured" % meshes.size())
	quit()
