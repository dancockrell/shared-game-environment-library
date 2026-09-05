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
	var outline := PackedVector2Array([Vector2(-width/2+0.7,-depth/2),Vector2(width/2-0.9,-depth/2),Vector2(width/2,-depth/2+1),Vector2(width/2,depth/2-0.9),Vector2(width/2-0.85,depth/2),Vector2(-width/2+1,depth/2),Vector2(-width/2,depth/2-1.1),Vector2(-width/2,-depth/2+0.8)])
	kit.piece(kit.solid_polygon(outline,1.2,0.1),center-Vector3(0,1.2,0),Vector3.ONE,"mortar")
	var cols := int(width/0.53)
	var rows := int(depth/0.51)
	var w := width/cols
	var d := depth/rows
	var seeds: Array[Vector2] = []
	for z in rows:
		for x in cols:
			seeds.append(Vector2(-width/2+(x+0.5)*w+kit.rng.randf_range(-w*0.25,w*0.25),-depth/2+(z+0.5)*d+kit.rng.randf_range(-d*0.25,d*0.25)))
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

func bridge() -> void:
	# Reference bridge runs from the plaza toward the foreground dock, not sideways.
	var g = kit.node_group("StoneArchBridge",Vector3(2.6,0.25,7.5),PI/2)
	var half_span := 3.0
	for i in 25:
		var x := -half_span+(i+0.5)*half_span*2/25
		var rise := 1.35*(1-pow(x/half_span,2)) + 0.27*(x/half_span+1)
		for z in [-0.96,-0.48,0.0,0.48,0.96]:
			var slab := kit.block(Vector3(x,rise,float(z)),Vector3(0.265,0.3,0.46),kit.shade("stone"),g)
			slab.rotation.z = atan(-2*1.35*x/(half_span*half_span)+0.09)
		for z in [-1.35,1.35]:
			for row in 2:
				kit.block(Vector3(x,rise+0.13+row*0.25,float(z)),Vector3(0.265,0.24,0.3),kit.shade("stone"),g)
			kit.block(Vector3(x,rise+0.56,float(z)),Vector3(0.28,0.14,0.45),kit.shade("stone"),g)
	for side in [-1,1]:
		for z in [-1.35,1.35]:
			kit.wall(0.55,1.15,0.6,Vector3(side*2.8,-0.55,float(z)),g)
	# Radial voussoirs and masonry haunches under the bridge establish an arch.
	for z in [-1.2,1.2]:
		for i in 25:
			var a := PI*(i+0.5)/25
			var stone := kit.block(Vector3(cos(a)*2.72,-0.15+sin(a)*1.5,float(z)),Vector3(0.35,0.38,0.34),kit.shade("stone"),g)
			stone.rotation.z = atan2(1.5*cos(a),-2.72*sin(a))

func dock() -> void:
	var g = kit.node_group("TimberDock",Vector3(2.6,0.0,13.35))
	for i in 35:
		var z := -3.1+i*0.19
		var plank := kit.block(Vector3(0,0.15+kit.rng.randf_range(-0.02,0.02),z),Vector3(3.2+kit.rng.randf_range(-0.08,0.08),0.16,0.175),kit.shade("wood"),g)
		plank.rotation.y = kit.rng.randf_range(-0.008,0.008)
		for x in [-1.35,1.35]:
			kit.cylinder(Vector3(x,0.245,z),0.025,0.008,"iron",g)
	for x in [-1.45,1.45]:
		kit.block(Vector3(x,-0.02,0),Vector3(0.23,0.3,6.5),"oak",g)
		for z in [-3.1,0,3.1]:
			kit.cylinder(Vector3(x,-0.1,z),0.16,2.2,"oak",g)
			kit.cylinder(Vector3(x,1.02,z),0.20,0.12,"oak_light",g)
			for y in [0.58,0.64,0.7]:
				kit.cylinder(Vector3(x,y,z),0.172,0.035,"sand",g)
		for segment in 2:
			for j in 8:
				var z0 := -3.1+segment*3.1+j*3.1/8
				var z1 := z0+3.1/8
				var t0 := j/8.0
				var t1 := (j+1)/8.0
				kit.beam(Vector3(x,0.72-0.3*sin(t0*PI),z0),Vector3(x,0.72-0.3*sin(t1*PI),z1),0.035,"sand",g)
	kit.beam(Vector3(-1.3,0.3,-2.7),Vector3(-1.3,3.6,-2.7),0.14,"oak",g)
	kit.beam(Vector3(-1.3,3.6,-2.7),Vector3(-1.3,3.6,-4.1),0.14,"oak",g)
	kit.beam(Vector3(-1.3,2.8,-2.7),Vector3(-1.3,3.6,-3.7),0.10,"oak",g)
	kit.beam(Vector3(-1.3,3.6,-4.0),Vector3(-1.3,1.3,-4.0),0.035,"sand",g)

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
	var inn := kit.house("Reference_L_Shaped_Inn",Vector3(1.5,1.05,-6.9),6.0,5.8,5.3,3.35,"roof")
	# Intersecting wing produces the reference's compound roof silhouette.
	var wing := kit.house("Inn_Right_Entrance_Wing",Vector3(5.5,1.05,-5.7),3.6,6.5,4.9,2.5,"roof")
	for g in [inn,wing]:
		var width: float = 6.0 if g == inn else 3.6
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
	for pos in [Vector3(-0.7,0.96,-1.9),Vector3(-2.25,0.96,-2.4)]:
		kit.cylinder(pos+Vector3(0,0.7,0),0.47,0.1,"oak_light",kit.root,32)
		kit.cylinder(pos+Vector3(0,0.35,0),0.11,0.7,"oak",kit.root)
		for a in [0.0,2.1,4.2]:
			var seat: Vector3 = pos+Vector3(cos(a)*0.67,0.35,sin(a)*0.67)
			kit.cylinder(seat,0.19,0.12,"oak_light",kit.root)
			kit.cylinder(seat-Vector3(0,0.15,0),0.05,0.3,"oak",kit.root)

func construct_shop() -> void:
	var shop := kit.house("Reference_Cutaway_Apothecary",Vector3(-7.0,1.1,-0.7),6.2,5.4,3.4,2.0,"slate",true)
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
	canopy.position = Vector3(0,3.4,-1.45)
	canopy.rotation.y = PI/2
	kit.roof(3.1,6.5,0,1.75,"slate",canopy)
	dormer(shop,Vector3(1.35,3.55,-0.6),0,"slate")
	chimney(shop,Vector3(-2.9,0.3,1.0),5.2,0.8)
	for z in [-2.7,0,2.7]:
		kit.block(Vector3(-3.15,1.1,z),Vector3(0.6,2.2,0.6),"stone6",shop)
	for x in [-3.1,3.1]:
		kit.block(Vector3(x,0.85,2.7),Vector3(0.6,0.18,0.65),"stone9",shop)
	kit.banner(Vector3(-0.9,1.25,2.94),2.3,0.95,shop)
	kit.beam(Vector3(-3.2,3.4,1.8),Vector3(3.2,3.4,1.8),0.17,"oak",shop)
	kit.stairs(Vector3(2.8,-0.3,2.9),1.25,0.6,1.1,shop,false)
	kit.lantern(Vector3(2.5,2.0,2.9),shop)
	for i in 6:
		kit.shrub(Vector3(-9.7+i*1.0,0.9,2.45),0.35)

func construct_guild() -> void:
	var guild := kit.house("Reference_Ornate_Guild",Vector3(11.2,1.4,0.4),5.5,7.0,5.5,4.1,"slate")
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
	if args.size() == 2 and args[1] == "--inspect":
		await inspect_saved_scene()
		return
	root.add_child(kit.root)
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
void fragment(){vec2 p=world_position.xz*vec2(1.1,2.7);float n=water(p);ALBEDO=mix(vec3(0.025,0.058,0.062),vec3(0.11,0.17,0.17),n);ROUGHNESS=0.78;SPECULAR=0.18;METALLIC=0.0;}
"""
	var water_mat := ShaderMaterial.new()
	water_mat.shader = shader
	var water = kit.block(Vector3(3,-0.48,1),Vector3(90,0.18,90),"water")
	water.material_override = water_mat
	# Layout reconstructed from the approved image: broad plaza, left cutaway,
	# compound inn at rear, tall guild right, bridge and dock toward the viewer.
	pavers(Vector3(-0.5,0.8,-2.8),24.0,15.0)
	pavers(Vector3(10.8,0.8,4.5),8.0,7.5)
	construct_inn()
	construct_shop()
	construct_guild()
	bridge()
	dock()
	source_model("boat-row-small.glb",Vector3(5.0,-0.25,14.1),0.95,0.1)
	source_model("crate.glb",Vector3(3.7,0.23,10.8),0.28)
	# Irregular sand shelves with varied outlines, not square beach blocks.
	for bank in [Vector3(-10.8,-0.62,5.0),Vector3(11.8,-0.62,9.0),Vector3(-12.4,-0.62,-2.0)]:
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
		var x := kit.rng.randf_range(-14.0,-11.7)
		kit.rock(Vector3(x,kit.rng.randf_range(-0.4,1.6),z),Vector3(kit.rng.randf_range(0.8,2.1),kit.rng.randf_range(0.6,1.7),kit.rng.randf_range(0.9,1.6)))
	for i in 35:
		kit.rock(Vector3(kit.rng.randf_range(-9,13),-0.1,kit.rng.randf_range(-12,-10)),Vector3(1.2,0.8,1.0)*kit.rng.randf_range(0.7,1.5))
	for pos in [Vector3(-12,1.3,-5),Vector3(-10.5,1.3,-8.3),Vector3(8.7,0.8,-9.2)]:
		kit.tree(pos,5.8)
	for i in 38:
		kit.shrub(Vector3(kit.rng.randf_range(-13,-11.5),0.9,kit.rng.randf_range(-9,1)),kit.rng.randf_range(0.35,0.7))
	for pos in [Vector3(7.9,0.9,-0.7),Vector3(5.9,0.9,-1.3),Vector3(-3.9,0.85,-2.6)]:
		kit.shrub(pos,0.65,kit.root,true)
	# Moss lives at joins and edges, not as a uniform green tint.
	for i in 230:
		var pos := Vector3(kit.rng.randf_range(-11,13),0.88,kit.rng.randf_range(-8,6))
		kit.rock(pos,Vector3(kit.rng.randf_range(0.07,0.21),0.012,kit.rng.randf_range(0.08,0.3)))
	# Reference gold points form a branching, partly elevated network.
	var nodes: Array[Vector3] = [Vector3(-8,0.93,-9),Vector3(-6,0.93,-5),Vector3(-3,0.93,0),Vector3(-1,0.93,0),Vector3(-1,2.0,0),Vector3(2.2,2.0,-0.9),Vector3(2.2,0.93,-0.9),Vector3(4.6,0.93,0.9),Vector3(4.6,2.15,0.9),Vector3(7.5,2.15,2.1),Vector3(7.5,0.93,2.1),Vector3(10.0,0.93,6.8),Vector3(13.5,0.93,7.7),Vector3(-4,0.93,3.4),Vector3(-1.8,0.93,4.4)]
	for p in nodes:
		node_marker(p)
	for edge in [Vector2i(0,1),Vector2i(1,2),Vector2i(2,3),Vector2i(3,4),Vector2i(4,5),Vector2i(5,6),Vector2i(6,7),Vector2i(7,8),Vector2i(8,9),Vector2i(9,10),Vector2i(10,11),Vector2i(11,12),Vector2i(2,13),Vector2i(13,14)]:
		path_connection(nodes[edge.x],nodes[edge.y])
	pawn(Vector3(-3.0,0.92,1.1),"cloth")
	pawn(Vector3(0.2,0.92,-0.8),"moss")
	pawn(Vector3(5.7,0.92,1.65),"moss")
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	var env := environment.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("293b3d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a9b6bd")
	env.ambient_light_energy = 0.42
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
	camera.size = 23.0
	kit.root.add_child(camera)
	camera.position = Vector3(29,33,46)
	camera.look_at(Vector3(1.0,1.7,2.0))
	camera.current = true
	for frame in 8:
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
	for frame in 5:
		await process_frame
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(output_dir.path_join("river-port-alternate.png")) == OK)
	var file := FileAccess.open(output_dir.path_join("build-report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"generator":"tools/build-river-port.gd + tools/river-port-kit.gd","engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"materialSources":kit.material_sources,"seed":5012026,"geometryPieces":kit.counts.pieces,"renderedObjects":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),"renderedPrimitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"drawCalls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"status":"authored environment study; not reference-matched or runtime-admitted","actors":"neutral unrigged scale pawns; not production characters","exportNote":"Native .scn preserves procedural water and world triplanar materials; GLB is a geometry interchange proof and does not preserve those renderer-specific materials.","sceneSha256":FileAccess.get_sha256(output_dir.path_join("river-port-scene.glb"))},"\t")+"\n")
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
	assert(meshes.size() > 4000,"Expected complete constructed scene")
	for mesh in meshes:
		assert(mesh.transform.is_finite() and mesh.mesh != null)
		assert(mesh.mesh.get_aabb().size.length() > 0)
	for frame in 8:
		await process_frame
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(output_dir.path_join("river-port-roundtrip.png")) == OK)
	var camera := root.get_camera_3d()
	assert(camera != null)
	camera.position = Vector3(30,25,-35)
	camera.look_at(Vector3(2,1.3,0.5))
	for frame in 5:
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
