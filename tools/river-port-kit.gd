extends RefCounted
## Authored construction primitives. Deterministic, complete solid meshes;
## no collision, navigation or invented room authority.
var rng := RandomNumberGenerator.new()
var root := Node3D.new()
var materials: Dictionary = {}
var meshes: Dictionary = {}
var counts := {"pieces":0,"triangles":0}

func _init() -> void:
	rng.seed = 5012026
	root.name = "RiverPortConstruction"

func material(key: String, color: Color, roughness: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	if materials.has(key):
		return materials[key]
	var m := StandardMaterial3D.new()
	m.resource_name = key
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	materials[key] = m
	return m

func mat(key: String) -> StandardMaterial3D:
	return materials[key]

func setup_palette() -> void:
	material("mortar",Color("514b40"))
	material("oak",Color("3c281d"))
	material("oak_light",Color("765338"))
	material("plaster",Color("baab88"))
	material("iron",Color("30383c"),0.5,0.6)
	material("gold",Color("c4983e"),0.32,0.65)
	material("cloth",Color("344d60"))
	material("sand",Color("8a7857"))
	material("soil",Color("4a4834"))
	material("reed",Color("6d7040"))
	material("water",Color("254c52"),0.2,0.25)
	material("foam",Color("78928a"),0.75)
	material("redcloth",Color("693b32"))
	var glow := material("lamp",Color("f2bf6c"),0.6)
	glow.emission_enabled = true
	glow.emission = Color("e6a14c")
	glow.emission_energy_multiplier = 1.5
	for i in 12:
		var v := float(i) / 11.0
		material("stone%d" % i,Color("70695c").lerp(Color("8c8270"),v))
		material("wood%d" % i,Color("493122").lerp(Color("8c6745"),v))
		material("roof%d" % i,Color("593b30").lerp(Color("9c6250"),v))
		material("slate%d" % i,Color("303d46").lerp(Color("566575"),v))
		material("leaf%d" % i,Color("35472a").lerp(Color("71824a"),v))

func shade(prefix: String) -> String:
	return prefix + str(rng.randi_range(0,11))

func piece(mesh: Mesh, pos: Vector3, scale_value: Vector3, key: String, parent: Node3D = root) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat(key)
	node.position = pos
	node.scale = scale_value
	parent.add_child(node)
	counts.pieces += 1
	return node

func solid_polygon(points: PackedVector2Array, height: float, bevel: float = 0.04) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2.ZERO
	for p in points:
		center += p
	center /= points.size()
	var rings: Array = []
	for level in 4:
		var ring: Array[Vector3] = []
		for p in points:
			var q: Vector2 = p.move_toward(center,bevel) if level == 0 or level == 3 else p
			var y: float = [0.0,bevel,height-bevel,height][level]
			ring.append(Vector3(q.x,y,q.y))
		rings.append(ring)
	# Cap order is explicit: X/Z polygon CCW has its normal toward -Y.
	var indices := Geometry2D.triangulate_polygon(points)
	for t in range(0,indices.size(),3):
		for j in [0,1,2]:
			st.add_vertex(rings[0][indices[t+j]])
		for j in [2,1,0]:
			st.add_vertex(rings[3][indices[t+j]])
	for level in 3:
		for i in points.size():
			var next := (i+1)%points.size()
			for p in [rings[level][i],rings[level+1][i],rings[level+1][next],rings[level][i],rings[level+1][next],rings[level][next]]:
				st.add_vertex(p)
	# Godot's front-face winding is clockwise. Reverse the constructed
	# mathematical CCW shell before generating outward normals.
	var raw := st.commit()
	var vertices: PackedVector3Array = raw.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var corrected := SurfaceTool.new()
	corrected.begin(Mesh.PRIMITIVE_TRIANGLES)
	corrected.set_smooth_group(-1)
	for index in range(0,vertices.size(),3):
		for offset in [2,1,0]:
			corrected.add_vertex(vertices[index+offset])
	corrected.generate_normals()
	return corrected.commit()

func block(pos: Vector3, size: Vector3, key: String, parent: Node3D = root) -> MeshInstance3D:
	# Unit bevel shape shares resources. Side bevel remains small on thin parts.
	if not meshes.has("block"):
		meshes.block = solid_polygon(PackedVector2Array([Vector2(-0.5,-0.5),Vector2(0.5,-0.5),Vector2(0.5,0.5),Vector2(-0.5,0.5)]),1,0.045)
	return piece(meshes.block,pos-Vector3(0,size.y/2,0),size,key,parent)

func cylinder(pos: Vector3, radius: float, height: float, key: String, parent: Node3D = root, sides: int = 12) -> MeshInstance3D:
	var cache := "cylinder%d" % sides
	if not meshes.has(cache):
		var m := CylinderMesh.new()
		m.top_radius = 1
		m.bottom_radius = 1
		m.height = 1
		m.radial_segments = sides
		meshes[cache] = m
	return piece(meshes[cache],pos,Vector3(radius,height,radius),key,parent)

func beam(a: Vector3, b: Vector3, width: float, key: String, parent: Node3D = root) -> Node3D:
	var node := block(Vector3.ZERO,Vector3(width,a.distance_to(b),width),key,parent)
	# Box mesh is bottom-origin; place its bottom at a then align Y to direction.
	var direction := (b-a).normalized()
	var right := direction.cross(Vector3.FORWARD).normalized()
	if right.length() < 0.1:
		right = Vector3.RIGHT
	node.basis = Basis(right,direction,right.cross(direction).normalized()).scaled_local(Vector3(width,a.distance_to(b),width))
	node.position = a
	return node

func node_group(name_value: String, position: Vector3, rotation_y: float = 0) -> Node3D:
	var g := Node3D.new()
	g.name = name_value
	g.position = position
	g.rotation.y = rotation_y
	root.add_child(g)
	return g

func wall(length: float, height: float, thickness: float, position: Vector3, parent: Node3D, rotated: bool = false) -> void:
	var columns := maxi(1,int(length/0.68))
	var rows := maxi(1,int(height/0.38))
	var w := length/columns
	var h := height/rows
	for row in rows:
		for col in columns+1:
			var left := maxf(-length/2,-length/2+col*w-(w/2 if row%2 else 0.0))
			var right := minf(length/2,-length/2+(col+1)*w-(w/2 if row%2 else 0.0))
			if right-left < 0.05:
				continue
			var local := Vector3((left+right)/2,(row+0.5)*h,0)
			var size := Vector3(right-left-0.025,h-0.025,thickness)
			if rotated:
				local = Vector3(0,local.y,local.x)
				size = Vector3(thickness,size.y,size.x)
			block(position+local,size,shade("stone"),parent)

func roof(width: float, depth: float, eaves: float, rise: float, prefix: String, parent: Node3D) -> void:
	# Individually modeled overlapping tiles on BOTH slopes, with a closed roof
	# deck and gable ends. Rotated views retain all actual geometry.
	var half := width/2+0.25
	var slope := sqrt(half*half+rise*rise)
	var angle := atan2(rise,half)
	for side in [-1,1]:
		var deck := block(Vector3(side*half/2,eaves+rise/2,0),Vector3(slope,0.16,depth+0.5),"oak",parent)
		deck.rotate_z(-side*angle)
		var rows := int(slope/0.32)+1
		var cols := int((depth+0.5)/0.39)+1
		for row in rows:
			var t := (row+0.5)/float(rows)
			for col in cols:
				var z := -depth/2-0.22+(col+0.5)*(depth+0.44)/cols
				var tile := block(Vector3(side*half*(1-t),eaves+rise*t+0.14,z),Vector3(slope/rows+0.075,0.085,(depth+0.44)/cols-0.015),shade(prefix),parent)
				tile.rotate_z(-side*angle)
	for col in int(depth/0.35)+2:
		cylinder(Vector3(0,eaves+rise+0.16,-depth/2+col*0.35),0.12,0.37,prefix+"6",parent).rotation.x = PI/2
	for z in [-depth/2-0.3,depth/2+0.3]:
		beam(Vector3(-half,eaves,z),Vector3(0,eaves+rise,z),0.16,"oak_light",parent)
		beam(Vector3(0,eaves+rise,z),Vector3(half,eaves,z),0.16,"oak_light",parent)

func window_at(pos: Vector3, parent: Node3D, width: float = 0.8) -> void:
	block(pos,Vector3(width,1.15,0.12),"oak",parent)
	block(pos+Vector3(0,0,0.075),Vector3(width-0.17,0.96,0.025),"lamp",parent)
	for x in [-width/2,0,width/2]:
		block(pos+Vector3(x,0,0.12),Vector3(0.07,1.22,0.06),"oak",parent)
	for y in [-0.55,0,0.55]:
		block(pos+Vector3(0,y,0.12),Vector3(width+0.14,0.07,0.06),"oak",parent)

func lantern(pos: Vector3, parent: Node3D) -> void:
	block(pos,Vector3(0.23,0.36,0.23),"lamp",parent)
	for y in [-0.22,0.22]:
		block(pos+Vector3(0,y,0),Vector3(0.32,0.07,0.32),"iron",parent)
	for x in [-0.12,0.12]:
		for z in [-0.12,0.12]:
			block(pos+Vector3(x,0,z),Vector3(0.035,0.4,0.035),"iron",parent)
	var lamp := OmniLight3D.new()
	lamp.position = pos+Vector3(0,0,0.25)
	lamp.light_color = Color("ffbb65")
	lamp.light_energy = 0.8
	lamp.omni_range = 3.5
	parent.add_child(lamp)

func house(name_value: String, position: Vector3, width: float, depth: float, height: float, roof_rise: float, roof_color: String, cutaway: bool = false) -> Node3D:
	var g := node_group(name_value,position)
	block(Vector3(0,0.12,0),Vector3(width+0.6,0.24,depth+0.6),"mortar",g)
	wall(width, height,0.35,Vector3(0,0,-depth/2),g)
	wall(depth,height,0.35,Vector3(-width/2,0,0),g,true)
	wall(depth,height,0.35,Vector3(width/2,0,0),g,true)
	if cutaway:
		wall(width,0.7,0.35,Vector3(0,0,depth/2),g)
	else:
		wall((width-1.3)/2,height,0.35,Vector3(-(width+1.3)/4,0,depth/2),g)
		wall((width-1.3)/2,height,0.35,Vector3((width+1.3)/4,0,depth/2),g)
		wall(1.3,height-2.35,0.35,Vector3(0,2.35,depth/2),g)
		block(Vector3(0,1.15,depth/2+0.03),Vector3(1.15,2.2,0.12),"oak",g)
		for x in [-0.48,-0.24,0,0.24,0.48]:
			block(Vector3(x,1.15,depth/2+0.13),Vector3(0.19,2.1,0.045),shade("wood"),g)
		cylinder(Vector3(0.33,1.15,depth/2+0.19),0.06,0.08,"gold",g).rotation.x = PI/2
		for step in 3:
			block(Vector3(0,-0.09+step*0.08,depth/2+0.85-step*0.2),Vector3(1.7-step*0.06,0.18,0.4),shade("stone"),g)
		for x in [-width*0.32,width*0.32]:
			window_at(Vector3(x,height*0.64,depth/2+0.18),g)
		roof(width,depth,height,roof_rise,roof_color,g)
		# Gable infill built from stacked closed beams, no missing triangle faces.
		for z in [-depth/2,depth/2]:
			for row in int(roof_rise/0.15):
				var y := (row+0.5)*0.15
				block(Vector3(0,height+y,z),Vector3(width*(1-y/roof_rise),0.16,0.2),"plaster",g)
			beam(Vector3(0,height,z+0.14),Vector3(0,height+roof_rise,z+0.14),0.16,"oak",g)
	for x in [-width/2,width/2]:
		for z in [-depth/2,depth/2]:
			block(Vector3(x,height/2,z),Vector3(0.22,height+0.2,0.24),"oak",g)
	for y in [0.55,height-0.08]:
		block(Vector3(0,y,-depth/2-0.2),Vector3(width+0.4,0.2,0.2),"oak",g)
		if not cutaway:
			block(Vector3(0,y,depth/2+0.2),Vector3(width+0.4,0.2,0.2),"oak",g)
	for plank in int(width/0.24):
		block(Vector3(-width/2+0.12+plank*0.24,0.28,0),Vector3(0.22,0.07,depth-0.4),shade("wood"),g)
	lantern(Vector3(-0.92,1.8,depth/2+0.4),g)
	return g

func shelving(parent: Node3D, pos: Vector3) -> void:
	for x in [-1.05,1.05]:
		block(pos+Vector3(x,1.2,0),Vector3(0.14,2.4,0.35),"oak",parent)
	for y in [0.35,0.95,1.55,2.15]:
		block(pos+Vector3(0,y,0),Vector3(2.25,0.12,0.5),"oak_light",parent)
		for i in 6:
			cylinder(pos+Vector3(-0.86+i*0.34,y+0.2,0),0.09,rng.randf_range(0.2,0.32),shade("roof"),parent)

func rock(pos: Vector3, size: Vector3, parent: Node3D = root) -> void:
	if not meshes.has("rock"):
		var points := PackedVector2Array()
		for i in 7:
			var a := TAU*i/7
			points.append(Vector2(cos(a),sin(a))*rng.randf_range(0.4,0.55))
		meshes.rock = solid_polygon(points,1,0.18)
	var n := piece(meshes.rock,pos,size,shade("stone"),parent)
	n.rotation.y = rng.randf()*TAU

func tree(pos: Vector3, height: float) -> void:
	var g := node_group("OakTree",pos)
	beam(Vector3.ZERO,Vector3(0.15,height*0.72,0),0.3,"oak",g)
	if not meshes.has("leaves"):
		var s := SphereMesh.new()
		s.height = 2
		s.radius = 1
		s.radial_segments = 9
		s.rings = 5
		meshes.leaves = s
	for b in 9:
		var a := b*TAU/9
		var end := Vector3(cos(a)*height*0.28,height*rng.randf_range(0.55,0.88),sin(a)*height*0.28)
		beam(Vector3(0,height*0.4,0),end,0.13,"oak",g)
		for k in 5:
			var leaf_pos := end+Vector3(rng.randf_range(-0.45,0.45),rng.randf_range(-0.15,0.55),rng.randf_range(-0.45,0.45))
			piece(meshes.leaves,leaf_pos,Vector3(0.6,0.32,0.6),shade("leaf"),g)
