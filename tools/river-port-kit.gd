extends RefCounted
## Authored construction primitives. Deterministic, complete solid meshes;
## no collision, navigation or invented room authority.
var rng := RandomNumberGenerator.new()
var root := Node3D.new()
var materials: Dictionary = {}
var meshes: Dictionary = {}
var counts := {"pieces":0,"triangles":0}
var material_sources: Array = []

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
	material("moss",Color("4b5732"))
	material("flower",Color("a38cbd"))
	material("skin",Color("af8d69"))
	var glow := material("lamp",Color("d9a052"),0.6)
	glow.emission_enabled = true
	glow.emission = Color("e6a14c")
	glow.emission_energy_multiplier = 0.65
	for i in 12:
		var v := float(i) / 11.0
		material("stone%d" % i,Color("70695c").lerp(Color("8c8270"),v))
		material("wood%d" % i,Color("493122").lerp(Color("8c6745"),v))
		material("roof%d" % i,Color("624036").lerp(Color("825042"),v))
		material("slate%d" % i,Color("35414b").lerp(Color("4a5867"),v))
		material("leaf%d" % i,Color("35472a").lerp(Color("71824a"),v))

func shade(prefix: String) -> String:
	return prefix + str(rng.randi_range(0,11))

func apply_surface_sources(repo: String) -> void:
	# Use the catalog's licensed inputs rather than substituting an invented
	# texture dependency. Desaturate albedo toward a controlled painted palette.
	var ledger: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(repo.path_join("catalog/approved-material-ledger.json")))
	for entry in ledger.entries:
		if entry.sourceId not in ["rock-boulder-dry-1k","medieval-wood-1k","fabric-pattern-05-1k"]:
			continue
		var color_texture: ImageTexture
		var normal_texture: ImageTexture
		for source in entry.files:
			if source.role not in ["albedo","normal_gl"]:
				continue
			var path: String = repo.path_join(source.path)
			assert(FileAccess.get_sha256(path) == source.sha256)
			var image := Image.load_from_file(path)
			assert(image != null)
			if source.role == "albedo":
				# Retain full source resolution; no early quality reduction.
				for y in image.get_height():
					for x in image.get_width():
						var value := image.get_pixel(x,y).get_luminance()
						var painted := 0.13+value*0.87
						image.set_pixel(x,y,Color(painted,painted,painted))
				image.generate_mipmaps()
				color_texture = ImageTexture.create_from_image(image)
			else:
				image.generate_mipmaps()
				normal_texture = ImageTexture.create_from_image(image)
			material_sources.append({"sourceId":entry.sourceId,"sourcePath":source.path,"sha256":source.sha256,"license":"CC0-1.0","role":source.role})
		for key in materials:
			var use: bool = (entry.sourceId == "rock-boulder-dry-1k" and (key.begins_with("stone") or key.begins_with("roof") or key.begins_with("slate") or key == "plaster")) or (entry.sourceId == "medieval-wood-1k" and (key.begins_with("wood") or key.begins_with("oak"))) or (entry.sourceId == "fabric-pattern-05-1k" and key in ["cloth","redcloth"])
			if not use:
				continue
			var m: StandardMaterial3D = materials[key]
			m.albedo_texture = color_texture
			m.normal_enabled = true
			m.normal_texture = normal_texture
			m.normal_scale = 0.8
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE*1.4
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

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
		meshes.block = solid_polygon(PackedVector2Array([Vector2(-0.5,-0.5),Vector2(0.5,-0.5),Vector2(0.5,0.5),Vector2(-0.5,0.5)]),1,0.018)
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

func ellipsoid(pos: Vector3, size: Vector3, key: String, parent: Node3D) -> MeshInstance3D:
	if not meshes.has("sculpt_form"):
		var shape := SphereMesh.new()
		shape.radius = 1
		shape.height = 2
		shape.radial_segments = 24
		shape.rings = 12
		meshes.sculpt_form = shape
	return piece(meshes.sculpt_form,pos,size,key,parent)

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

func node_group(name_value: String, position: Vector3, rotation_y: float = 0, parent: Node3D = root) -> Node3D:
	var g := Node3D.new()
	g.name = name_value
	g.position = position
	g.rotation.y = rotation_y
	parent.add_child(g)
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
	if prefix == "thatch":
		# Thick continuous straw bedding with overlapping bundles on both slopes.
		# Keep the same roof bounds/owner; no shingle roof hidden beneath the straw.
		material("thatch",Color("88764f"))
		var half_span := width/2+0.25
		var angle := atan2(rise,half_span)
		var slope := Vector2(half_span,rise).length()
		for side in [-1,1]:
			var center := Vector3(side*half_span/2,eaves+rise/2,0)
			var bedding := block(center,Vector3(slope,0.24,depth+0.5),"thatch",parent)
			bedding.rotation.z = -side*angle
			bedding.position = center-bedding.basis*Vector3(0,0.12,0)
			var columns := int((depth+0.5)/0.075)
			for col in columns:
				var z := -(depth+0.5)/2+(col+0.5)*(depth+0.5)/columns
				for row in 12:
					var a := row/12.0
					var b := minf(1.0,(row+1.35)/12.0)
					var start := Vector3(side*half_span*a,eaves+rise*(1-a)+0.16,z)
					var end := Vector3(side*half_span*b,eaves+rise*(1-b)+0.13,z)
					beam(start,end,0.075,"thatch",parent)
		return
	# Individually modeled overlapping tiles on BOTH slopes, with a closed roof
	# deck and gable ends. Rotated views retain all actual geometry.
	var half := width/2+0.25
	var slope := sqrt(half*half+rise*rise)
	var angle := atan2(rise,half)
	for side in [-1,1]:
		var deck_center := Vector3(side*half/2,eaves+rise/2,0)
		var deck := block(deck_center,Vector3(slope,0.16,depth+0.5),"oak",parent)
		deck.rotate_z(-side*angle)
		deck.position = deck_center-deck.basis*Vector3(0,0.5,0)
		var rows := int(slope/0.25)+1
		var cols := int((depth+0.5)/0.29)+1
		for row in rows:
			var t := (row+0.5)/float(rows)
			for col in cols:
				var z := -depth/2-0.22+(col+0.5+0.42*(row%2))*(depth+0.44)/cols
				var normal := Vector3(side*sin(angle),cos(angle),0)
				var tile_center := Vector3(side*half*(1-t),eaves+rise*t,z+rng.randf_range(-0.01,0.01))+normal*(0.125+rng.randf_range(-0.003,0.003))
				var tile := block(tile_center,Vector3(slope/rows+0.07,0.048,(depth+0.44)/cols-0.009),shade(prefix),parent)
				tile.rotate_z(-side*(angle+0.045))
				tile.position = tile_center-tile.basis*Vector3(0,0.5,0)
	for col in int(depth/0.35)+2:
		cylinder(Vector3(0,eaves+rise+0.16,-depth/2+col*0.35),0.12,0.37,prefix+"6",parent).rotation.x = PI/2
	for z in [-depth/2-0.3,depth/2+0.3]:
		beam(Vector3(-half,eaves,z),Vector3(0,eaves+rise,z),0.16,"oak_light",parent)
		beam(Vector3(0,eaves+rise,z),Vector3(half,eaves,z),0.16,"oak_light",parent)

func window_at(pos: Vector3, parent: Node3D, width: float = 0.8) -> void:
	# Deep dark reveal, thin joinery, eight individual panes, sill and lintel.
	block(pos-Vector3(0,0,0.02),Vector3(width+0.17,1.35,0.18),"oak",parent)
	for side in [-1,1]:
		for row in 4:
			block(pos+Vector3(side*width*0.225,-0.43+row*0.285,0.1),Vector3(width*0.39,0.245,0.025),"lamp",parent)
	for x in [-width/2,0,width/2]:
		block(pos+Vector3(x,0,0.15),Vector3(0.04,1.25,0.05),"oak_light",parent)
	for y in [-0.58,-0.29,0,0.29,0.58]:
		block(pos+Vector3(0,y,0.15),Vector3(width+0.08,0.035,0.05),"oak_light",parent)
	block(pos+Vector3(0,-0.7,0.17),Vector3(width+0.3,0.11,0.35),"stone8",parent)
	block(pos+Vector3(0,0.7,0.1),Vector3(width+0.3,0.12,0.22),"oak",parent)

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

func house(name_value: String, position: Vector3, width: float, depth: float, height: float, roof_rise: float, roof_color: String, cutaway: bool = false, gable_key: String = "plaster", wall_windows: bool = true, door_width: float = 1.3, door_height: float = 2.2, roof_crosswise: bool = false, default_steps: bool = true) -> Node3D:
	var g := node_group(name_value,position)
	g.set_meta("building_bounds",{"width":width,"depth":depth,"wallHeight":height,"roofRise":roof_rise,"roofCrosswise":roof_crosswise,"cutaway":cutaway,"doorWidth":door_width,"doorHeight":door_height})
	var entrance := Node3D.new()
	entrance.name = "EntranceSocket"
	entrance.position = Vector3(0,0.315,depth/2+0.24)
	g.add_child(entrance)
	block(Vector3(0,0.12,0),Vector3(width+0.6,0.24,depth+0.6),"mortar",g)
	wall(width, height,0.35,Vector3(0,0,-depth/2),g)
	for side in [-1,1]:
		if cutaway:
			wall(depth*0.48,height,0.35,Vector3(side*width/2,0,-depth*0.26),g,true)
			wall(depth*0.52,0.85,0.35,Vector3(side*width/2,0,depth*0.24),g,true)
		else:
			wall(depth,height,0.35,Vector3(side*width/2,0,0),g,true)
	if cutaway:
		wall(width,0.7,0.35,Vector3(0,0,depth/2),g)
	else:
		wall((width-door_width)/2,height,0.35,Vector3(-(width+door_width)/4,0,depth/2),g)
		wall((width-door_width)/2,height,0.35,Vector3((width+door_width)/4,0,depth/2),g)
		wall(door_width,height-door_height-0.15,0.35,Vector3(0,door_height+0.15,depth/2),g)
		block(Vector3(0,door_height/2,depth/2+0.03),Vector3(door_width-0.15,door_height,0.12),"oak",g)
		for i in 8:
			var x := (i-3.5)*(door_width-0.16)/8
			block(Vector3(x,door_height/2,depth/2+0.13),Vector3((door_width-0.16)/8-0.012,door_height-0.08,0.045),shade("wood"),g)
		for y in [door_height*0.25,door_height*0.75]:
			block(Vector3(0,y,depth/2+0.17),Vector3(door_width*0.83,0.055,0.035),"iron",g)
			for x in [-door_width*0.35,door_width*0.35]:
				cylinder(Vector3(x,y,depth/2+0.2),0.02,0.025,"gold",g).rotation.x = PI/2
		cylinder(Vector3(door_width*0.25,door_height/2,depth/2+0.19),0.04,0.08,"gold",g).rotation.x = PI/2
		if default_steps:
			for step in 3:
				block(Vector3(0,-0.09+step*0.08,depth/2+0.85-step*0.2),Vector3(1.7-step*0.06,0.18,0.4),shade("stone"),g)
		if wall_windows:
			for x in [-width*0.32,width*0.32]:
				window_at(Vector3(x,height*0.64,depth/2+0.18),g)
		for i in 11:
			var a := PI*i/10
			var voussoir := block(Vector3(cos(a)*door_width*0.61,door_height-0.07+sin(a)*door_width*0.61,depth/2+0.24),Vector3(0.23,0.30,0.27),shade("stone"),g)
			voussoir.rotation.z = a-PI/2
		# Roof orientation is independent of the wall/door coordinate frame.
		var roof_frame := Node3D.new()
		roof_frame.name = "RoofFrame"
		g.add_child(roof_frame)
		roof_frame.rotation.y = PI/2 if roof_crosswise else 0.0
		var roof_width := depth if roof_crosswise else width
		var roof_depth := width if roof_crosswise else depth
		roof(roof_width,roof_depth,height,roof_rise,roof_color,roof_frame)
		# Gable infill built from stacked closed beams, no missing triangle faces.
		for z in [-roof_depth/2,roof_depth/2]:
			for row in int(roof_rise/0.15):
				var y := (row+0.5)*0.15
				block(Vector3(0,height+y,z),Vector3(roof_width*(1-y/roof_rise),0.16,0.2),gable_key,roof_frame)
			beam(Vector3(0,height,z+0.14),Vector3(0,height+roof_rise,z+0.14),0.16,"oak" if gable_key == "plaster" else gable_key,roof_frame)
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

func catalog_specs() -> Array:
	# One recipe registry; these are neutral ingredients, never named DR rooms.
	return [
		["bakery", "architecture"], ["smithy", "architecture"],
		["warehouse", "architecture"], ["townhouse", "architecture"],
		["meeting-hall", "architecture"], ["watchtower", "architecture"],
		["gatehouse", "architecture"], ["stable", "architecture"],
		["produce-stall", "neutral_prop"], ["fish-stall", "neutral_prop"],
		["barrel", "neutral_prop"], ["cargo-stack", "neutral_prop"],
		["handcart", "neutral_prop"], ["roofed-well", "neutral_prop"],
		["fountain", "neutral_prop"], ["stone-bench", "neutral_prop"],
		["street-lantern", "neutral_prop"], ["signpost", "neutral_prop"],
		["hedge-run", "flora"], ["vine-bower", "flora"],
		["quay-wall", "architecture"], ["pier-section", "architecture"],
		["landing-stairs", "architecture"], ["mooring-post", "neutral_prop"],
		["tollhouse", "architecture"], ["boathouse", "architecture"],
		["granary", "architecture"], ["bell-hall", "architecture"],
		["courtyard-wall", "architecture"], ["timber-gate", "architecture"],
		["notice-board", "neutral_prop"], ["trestle-table", "neutral_prop"],
		["stool", "neutral_prop"], ["woodpile", "neutral_prop"],
		["water-trough", "neutral_prop"], ["cargo-crane", "neutral_prop"],
		["rope-coil", "neutral_prop"], ["timber-footbridge", "architecture"],
		["reed-bank", "flora"], ["rock-shelf", "geology"],
		["cobble-plaza", "terrain"], ["cobble-street", "terrain"],
		["dirt-path", "terrain"], ["grass-verge", "terrain"],
		["curb-run", "architecture"], ["curb-corner", "architecture"],
		["quay-corner", "architecture"], ["dock-ramp", "architecture"],
		["workbench", "neutral_prop"], ["anvil", "neutral_prop"],
		["tool-rack", "neutral_prop"], ["forge-hearth", "neutral_prop"],
		["bucket", "neutral_prop"], ["sack-stack", "neutral_prop"],
		["fishing-rack", "neutral_prop"], ["mooring-cleat", "neutral_prop"],
		["driftwood", "neutral_prop"], ["basalt-outcrop", "geology"],
		["beach-slope", "terrain"], ["stone-culvert", "architecture"],
		["fishmonger", "architecture"], ["chandlery", "architecture"],
		["stone-cottage", "architecture"], ["guard-barracks", "architecture"],
		["oak-tree", "flora"], ["willow-tree", "flora"],
		["cypress-tree", "flora"], ["flower-planter", "flora"],
		["hitching-post", "neutral_prop"], ["capstan", "neutral_prop"],
		["dock-ladder", "neutral_prop"], ["hand-pump", "neutral_prop"],
		["rain-barrel", "neutral_prop"], ["grindstone", "neutral_prop"],
		["log-bench", "neutral_prop"], ["canvas-shelter", "architecture"],
		["manicured-lawn", "terrain"], ["stump-seat", "neutral_prop"],
		["plank-approach", "terrain"], ["display-rack", "neutral_prop"],
		["unpainted-armorer-shop", "architecture"], ["trellised-herbalist", "architecture"],
		["low-brick-bathhouse", "architecture"], ["old-stone-residence", "architecture"],
		["cruck-cottage", "architecture"], ["barn-stable", "architecture"],
		["plain-weaponsmith", "architecture"], ["mud-court", "terrain"],
		["tattered-shelter", "architecture"],
		["plaster-wall-section", "architecture"], ["stone-wall-section", "architecture"],
		["timber-doorway-section", "architecture"], ["window-wall-section", "architecture"],
		["pine-shop-counter", "neutral_prop"], ["wooden-display-bin", "neutral_prop"],
		["shield-hook-board", "neutral_prop"], ["wooden-park-bench", "neutral_prop"],
		["gingham-picnic-table", "neutral_prop"]
	]

func attachment(parent: Node3D, name_value: String, pos: Vector3) -> Node3D:
	var socket := node_group(name_value,pos,0,parent)
	socket.set_meta("presentation_only",true)
	return socket

func barrel(parent: Node3D, pos: Vector3, size_value: float = 1.0) -> void:
	var g := node_group("CooperedBarrel",pos,0,parent)
	for stave in 20:
		var a := TAU*stave/20.0
		for row in 8:
			var t := (row+0.5)/8.0
			var r := 0.32+sin(t*PI)*0.07
			var wood := block(Vector3(cos(a)*r,t*0.95,sin(a)*r),Vector3(0.055,0.124,0.106),shade("wood"),g)
			wood.rotation.y = -a
	for y in [0.1,0.28,0.68,0.85]:
		ring(Vector3(0,y,0),0.34+sin(y/0.95*PI)*0.07,0.026,"iron",g)
	cylinder(Vector3(0,0.925,0),0.32,0.035,"oak_light",g,20)
	cylinder(Vector3(0,0.025,0),0.32,0.05,"oak",g,20)
	for x in [-0.2,-0.1,0.0,0.1,0.2]:
		block(Vector3(x,0.947,0),Vector3(0.009,0.005,sqrt(0.32*0.32-x*x)*2),"oak",g)
	g.scale = Vector3.ONE*size_value

func crate(parent: Node3D, pos: Vector3, size_value: Vector3) -> void:
	var g := node_group("BracedCrate",pos,0,parent)
	block(Vector3(0,size_value.y/2,0),size_value,"oak",g)
	for side in [-1,1]:
		for i in 6:
			block(Vector3((i-2.5)*size_value.x/6,size_value.y/2,side*(size_value.z/2+0.012)),Vector3(size_value.x/6-0.012,size_value.y,0.04),shade("wood"),g)
		for x in [-size_value.x/2+0.06,size_value.x/2-0.06]:
			block(Vector3(x,size_value.y/2,side*(size_value.z/2+0.045)),Vector3(0.09,size_value.y,0.06),"oak_light",g)
		beam(Vector3(-size_value.x/2,0.08,side*(size_value.z/2+0.065)),Vector3(size_value.x/2,size_value.y-0.08,side*(size_value.z/2+0.065)),0.07,"oak_light",g)
	for i in 6:
		block(Vector3((i-2.5)*size_value.x/6,size_value.y+0.02,0),Vector3(size_value.x/6-0.012,0.04,size_value.z),shade("wood"),g)

func framed_elevations(g: Node3D, width: float, depth: float, height: float) -> void:
	# All sides receive deliberate detail; a rotating camera cannot reveal a
	# completely blank rear. Window modules face their own wall normals.
	for face in [[Vector3(0,0,-depth/2-0.19),PI,width], [Vector3(width/2+0.19,0,0),PI/2,depth], [Vector3(-width/2-0.19,0,0),-PI/2,depth]]:
		var elevation := node_group("Elevation",face[0],float(face[1]),g)
		var span: float = face[2]
		for x in [-span*0.29,span*0.29]:
			window_at(Vector3(x,height*0.62,0.015),elevation,0.7)
			for side in [-1,1]:
				block(Vector3(x+side*0.52,height*0.62,0.025),Vector3(0.23,1.05,0.055),"oak_light",elevation)
		for y in [height*0.45,height-0.12]:
			block(Vector3(0,y,0),Vector3(span,0.16,0.14),"oak",elevation)
		for x in [-span*0.46,0.0,span*0.46]:
			block(Vector3(x,height/2,0),Vector3(0.14,height,0.15),"oak",elevation)

func sloped_block(parent: Node3D, width: float, depth: float, high: float, low: float, key: String) -> void:
	var raw := solid_polygon(PackedVector2Array([Vector2(-width/2,-depth/2),Vector2(width/2,-depth/2),Vector2(width/2,depth/2),Vector2(-width/2,depth/2)]),1,0.01)
	var vertices: PackedVector3Array = raw.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for vertex in vertices:
		vertex.y *= lerpf(high,low,(vertex.z+depth/2)/depth)
		surface.add_vertex(vertex)
	surface.generate_normals()
	piece(surface.commit(),Vector3.ZERO,Vector3.ONE,key,parent)

## Reusable room construction batch. Openings are actual gaps, not painted
## rectangles; perimeter sockets permit exact joins without game topology.
func interior_module(id: String, g: Node3D) -> void:
	if id.ends_with("-section"):
		var opening := id == "timber-doorway-section" or id == "window-wall-section"
		if id == "stone-wall-section":
			wall(3.0,3.0,0.32,Vector3.ZERO,g)
		elif opening:
			for x in [-1.12,1.12]:
				block(Vector3(x,1.5,0),Vector3(0.76,3,0.24),"plaster",g)
			block(Vector3(0,2.78,0),Vector3(1.48,0.44,0.24),"plaster",g)
			if id == "window-wall-section":
				block(Vector3(0,0.5,0),Vector3(1.48,1,0.24),"plaster",g)
				# Mullioned opening with a sill; glass is an authoring choice.
				for x in [-0.68,0.0,0.68]:
					block(Vector3(x,1.77,0),Vector3(0.08,1.5,0.20),"oak",g)
				for y in [1.04,1.78,2.52]:
					block(Vector3(0,y,0),Vector3(1.48,0.08,0.20),"oak",g)
				block(Vector3(0,1.0,0),Vector3(1.7,0.12,0.48),"oak_light",g)
			else:
				for x in [-0.75,0.75]:
					block(Vector3(x,1.28,0),Vector3(0.16,2.56,0.36),"oak",g)
				block(Vector3(0,2.56,0),Vector3(1.66,0.18,0.36),"oak_light",g)
				attachment(g,"entrance",Vector3(0,0,-0.22))
		else:
			block(Vector3(0,1.5,0),Vector3(3,3,0.24),"plaster",g)
		for x in [-1.46,1.46]:
			block(Vector3(x,1.5,0),Vector3(0.08,3,0.35),"oak",g)
		for y in [0.08,2.94]:
			block(Vector3(0,y,0),Vector3(3,0.12,0.35),"oak",g)
		attachment(g,"join_a",Vector3(-1.5,0,0))
		attachment(g,"join_b",Vector3(1.5,0,0))
		g.set_meta("opening_width",1.32 if opening else 0.0)
	elif id == "pine-shop-counter":
		for x in [-1.15,1.15]:
			for z in [-0.34,0.34]:
				block(Vector3(x,0.48,z),Vector3(0.13,0.96,0.13),"oak",g)
		for i in 15:
			block(Vector3(-1.12+i*0.16,0.5,-0.38),Vector3(0.155,0.82,0.065),shade("wood"),g)
		for y in [0.13,0.86]:
			block(Vector3(0,y,-0.43),Vector3(2.5,0.1,0.08),"oak_light",g)
		for z in [-0.3,0.0,0.3]:
			block(Vector3(0,1.0,z),Vector3(2.6,0.1,0.29),shade("wood"),g)
		attachment(g,"surface",Vector3(0,1.05,0))
	elif id == "wooden-display-bin":
		for i in 6:
			block(Vector3((i-2.5)*0.2,0.06,0),Vector3(0.19,0.12,0.85),shade("wood"),g)
		for y in [0.18,0.36,0.54]:
			for z in [-0.44,0.44]:
				block(Vector3(0,y,z),Vector3(1.26,0.17,0.055),shade("wood"),g)
			for x in [-0.62,0.62]:
				block(Vector3(x,y,0),Vector3(0.055,0.17,0.88),shade("wood"),g)
		for x in [-0.59,0.59]:
			for z in [-0.4,0.4]:
				block(Vector3(x,0.35,z),Vector3(0.07,0.7,0.07),"oak",g)
		attachment(g,"surface",Vector3(0,0.12,0))
	elif id == "shield-hook-board":
		block(Vector3(0,0.24,0),Vector3(2.4,0.48,0.1),"oak_light",g)
		for x in [-0.9,-0.3,0.3,0.9]:
			beam(Vector3(x,0.25,-0.05),Vector3(x,0.25,-0.23),0.035,"iron",g)
			beam(Vector3(x,0.25,-0.23),Vector3(x,0.36,-0.23),0.035,"iron",g)
			attachment(g,"hook_%s" % str(x),Vector3(x,0.3,-0.23))
	else:
		var picnic := id == "gingham-picnic-table"
		var height := 0.8 if picnic else 0.48
		var depth := 0.9 if picnic else 0.48
		for x in [-0.86,0.86]:
			for z in [-depth*0.35,depth*0.35]:
				beam(Vector3(x,0,z),Vector3(x,height,z),0.10,"oak",g)
		for i in 4:
			block(Vector3(0,height,(i-1.5)*depth/4),Vector3(2.2,0.075,depth/4-0.008),shade("wood"),g)
		if picnic:
			for x in 16:
				for z in 8:
					block(Vector3((x-7.5)*0.14,height+0.045,(z-3.5)*0.12),Vector3(0.14,0.01,0.12),"redcloth" if (x+z)%2 else "plaster",g)
			attachment(g,"surface",Vector3(0,height+0.05,0))
		else:
			for x in [-0.95,0.95]:
				block(Vector3(x,0.72,0.25),Vector3(0.09,0.65,0.09),"oak",g)
			for y in [0.72,0.92]:
				block(Vector3(0,y,0.25),Vector3(2.2,0.15,0.065),shade("wood"),g)

func catalog_model(id: String) -> Node3D:
	rng.seed = 5012026+id.hash() # Independent of build order and unrelated recipes.
	var g := node_group(id,Vector3.ZERO)
	if id in ["plaster-wall-section","stone-wall-section","timber-doorway-section","window-wall-section","pine-shop-counter","wooden-display-bin","shield-hook-board","wooden-park-bench","gingham-picnic-table"]:
		interior_module(id,g)
	elif id in ["unpainted-armorer-shop","trellised-herbalist","low-brick-bathhouse","old-stone-residence","cruck-cottage","barn-stable","plain-weaponsmith"]:
		# Complete exteriors. Shared archetypes, not named-game identity:
		# consumer recipes retain the description and interpretation boundary.
		var sizes := {"unpainted-armorer-shop":Vector3(6,3,5), "trellised-herbalist":Vector3(5.5,3.6,5),
			"low-brick-bathhouse":Vector3(10,2.7,5), "old-stone-residence":Vector3(4.8,4.7,5),
			"cruck-cottage":Vector3(4.8,2.6,6), "barn-stable":Vector3(7,4.3,11),
			"plain-weaponsmith":Vector3(6,3.4,5)}
		var d: Vector3 = sizes[id]
		var timber: bool = id in ["unpainted-armorer-shop","barn-stable"]
		var shell := house("CompleteExterior",Vector3.ZERO,d.x,d.z,d.y,2.2,
			"thatch" if id == "cruck-cottage" else ("wood" if timber else "slate"),false,
			"oak_light" if timber else "plaster",id != "barn-stable",
			3.2 if id == "barn-stable" else 1.3,3.4 if id == "barn-stable" else 2.2,
			id == "old-stone-residence",false)
		shell.reparent(g,false)
		if timber:
			if id == "barn-stable":
				block(Vector3(0,1.7,d.z/2+0.22),Vector3(0.035,3.4,0.045),"iron",g)
				for x in [-0.18,0.18]:
					ring(Vector3(x,1.5,d.z/2+0.26),0.07,0.015,"iron",g,true)
			for mesh in shell.find_children("*","MeshInstance3D",true,false):
				if mesh.material_override.resource_name.begins_with("stone"):
					mesh.material_override = mat("wood7")
			# Explicit board courses on all four elevations, with a door opening.
			for row in int(d.y/0.18):
				var y := 0.1+row*0.18
				block(Vector3(0,y,-d.z/2-0.2),Vector3(d.x,0.165,0.06),shade("wood"),g)
				for side in [-1,1]:
					block(Vector3(side*(d.x/2+0.2),y,0),Vector3(0.06,0.165,d.z),shade("wood"),g)
				if y > (3.4 if id == "barn-stable" else 2.2):
					block(Vector3(0,y,d.z/2+0.2),Vector3(d.x,0.165,0.06),shade("wood"),g)
			if id == "unpainted-armorer-shop":
				# No sign, heraldry, gold ornament or light gimmick.
				for child in shell.find_children("*","OmniLight3D",true,false):
					child.free()
				for mesh in shell.find_children("*","MeshInstance3D",true,false):
					if mesh.material_override.resource_name in ["gold","lamp"]:
						mesh.material_override = mat("iron")
				for x in [-2.1,2.1]:
					beam(Vector3(x,1.8,d.z/2+0.2),Vector3(x,1.8,d.z/2+0.5),0.04,"iron",g)
					var shield := cylinder(Vector3(x,1.38,d.z/2+0.47),0.38,0.07,"iron",g,32)
					shield.rotation.x = PI/2
					ring(Vector3(x,1.38,d.z/2+0.52),0.35,0.025,"oak",g,true)
		elif id == "low-brick-bathhouse":
			for mesh in shell.find_children("*","MeshInstance3D",true,false):
				if mesh.material_override.resource_name.begins_with("stone"):
					mesh.material_override = material("bath_brick",Color("794b38"))
			for x in [-3.5,3.5]:
				wall(0.8,2,0.8,Vector3(x,d.y,-0.8),g)
		elif id == "trellised-herbalist":
			for side in [-1,1]:
				var cx: float = side*1.9
				for i in 8:
					beam(Vector3(cx-0.65+i*0.18,0.2,d.z/2+0.48),Vector3(cx-0.65+i*0.18,3.6,d.z/2+0.48),0.025,"oak_light",g)
				for i in 16:
					beam(Vector3(cx-0.7,0.3+i*0.21,d.z/2+0.49),Vector3(cx+0.7,0.3+i*0.21,d.z/2+0.49),0.025,"oak",g)
				for i in 190:
					var p := Vector3(cx+rng.randf_range(-0.76,0.76),rng.randf_range(0.1,3.8),d.z/2+rng.randf_range(0.5,0.68))
					ellipsoid(p,Vector3(0.10,0.065,0.065),shade("leaf"),g)
					if i%9 == 0:
						ellipsoid(p+Vector3(0,0,0.06),Vector3(0.045,0.04,0.035),"flower",g)
		elif id == "cruck-cottage":
			material("thatch",Color("83704b"))
			for z in [-d.z/2-0.24,d.z/2+0.24]:
				for side in [-1,1]:
					beam(Vector3(side*2.25,0.2,z),Vector3(side*1.6,2.7,z),0.22,"oak",g)
					beam(Vector3(side*1.6,2.7,z),Vector3(0,4.8,z),0.22,"oak",g)
		attachment(g,"entrance",Vector3(0,0.315,d.z/2+0.85))
		attachment(g,"rear",Vector3(0,0,-d.z/2-0.4))
	elif id in ["bakery","smithy","warehouse","townhouse","meeting-hall","stable","tollhouse","boathouse","granary","bell-hall","fishmonger","chandlery","stone-cottage","guard-barracks"]:
		var dimensions: Dictionary = {"bakery":Vector3(5.2,3.3,4.6),"smithy":Vector3(6.0,3.4,5.0),"warehouse":Vector3(7.5,4.6,7.0),"townhouse":Vector3(4.1,6.1,5.1),"meeting-hall":Vector3(8.2,5.2,6.1),"stable":Vector3(8.2,3.2,4.4),"tollhouse":Vector3(3.6,3.1,3.8),"boathouse":Vector3(6.5,3.7,8.0),"granary":Vector3(6.8,5.5,5.8),"bell-hall":Vector3(5.1,4.4,7.3),"fishmonger":Vector3(6,3.6,5.4),"chandlery":Vector3(5.0,4.8,5.6),"stone-cottage":Vector3(4.8,3.1,5.0),"guard-barracks":Vector3(10.4,4.4,5.2)}
		var d: Vector3 = dimensions[id]
		var building := house("EnclosedShell",Vector3.ZERO,d.x,d.z,d.y,2.4 if id == "meeting-hall" else 1.9,"roof" if id in ["bakery","townhouse","tollhouse","stone-cottage"] else "slate",false,"stone8" if id == "stone-cottage" else "plaster",id != "boathouse",3.5 if id == "boathouse" else (2.2 if id in ["warehouse","stable"] else 1.3),2.5,id == "stone-cottage",false)
		building.reparent(g,false)
		framed_elevations(building,d.x,d.z,d.y)
		stairs(Vector3(0,0,d.z/2+0.2),2.4,0.315,0.85,building,false)
		attachment(g,"entrance",Vector3(0,0,d.z/2+1.15))
		attachment(g,"sign",Vector3(-1.6,2.6,d.z/2+0.3))
		if id in ["bakery","smithy"]:
			var oven := node_group("AttachedOven" if id == "bakery" else "ForgeChimney",Vector3(d.x/2+0.7,0,-0.7),0,g)
			wall(1.5,1.8,1.5,Vector3.ZERO,oven)
			wall(0.85,d.y+2.3,0.8,Vector3(0,0.3,-0.22),oven)
			block(Vector3(0,d.y+2.7,-0.22),Vector3(1.05,0.18,1.05),"stone9",oven)
			block(Vector3(0,0.7,0.78),Vector3(0.8,1.0,0.06),"iron",oven)
		if id == "bakery":
			var awning := block(Vector3(0,2.7,d.z/2+0.85),Vector3(3.3,0.09,1.3),"cloth",g)
			awning.rotation.x = 0.16
			for x in [-1.5,1.5]:
				beam(Vector3(x,0,d.z/2+1.45),Vector3(x,2.6,d.z/2+1.45),0.1,"oak",g)
		elif id == "smithy":
			block(Vector3(-2.3,0.55,d.z/2+0.85),Vector3(0.75,1.1,0.7),"oak",g)
			block(Vector3(-2.3,1.22,d.z/2+0.85),Vector3(1.05,0.26,0.4),"iron",g)
		elif id == "warehouse":
			beam(Vector3(0,d.y-0.25,d.z/2),Vector3(0,d.y-0.25,d.z/2+1.7),0.22,"oak",g)
			beam(Vector3(0,d.y-1.6,d.z/2),Vector3(0,d.y-0.25,d.z/2+1.4),0.13,"oak",g)
			ring(Vector3(0,d.y-0.6,d.z/2+1.5),0.22,0.04,"iron",g,true)
		elif id == "townhouse":
			block(Vector3(0,3.3,d.z/2+0.65),Vector3(3.6,0.22,1.25),"oak",g)
			for x in [-1.7,1.7]:
				beam(Vector3(x,2.3,d.z/2),Vector3(x,3.3,d.z/2+1.15),0.16,"oak",g)
			for i in 12:
				block(Vector3(-1.65+i*0.3,3.85,d.z/2+1.2),Vector3(0.065,0.95,0.065),"oak_light",g)
			block(Vector3(0,4.34,d.z/2+1.2),Vector3(3.6,0.1,0.12),"oak",g)
		elif id == "meeting-hall":
			for x in [-2.1,2.1]:
				wall(0.5,3.3,0.5,Vector3(x,0,d.z/2+1.5),g)
			roof(4.8,1.8,3.3,1.3,"slate",node_group("EntryPortico",Vector3(0,0,d.z/2+1),0,g))
			banner(Vector3(-3.2,4.4,d.z/2+0.3),0.7,2.2,g)
			banner(Vector3(3.2,4.4,d.z/2+0.3),0.7,2.2,g)
		elif id == "stable":
			for x in [-3.1,3.1]:
				crate(g,Vector3(x,0,d.z/2+0.65),Vector3(1.25,0.7,0.65))
			for x in [-3.8,-1.8]:
				beam(Vector3(x,0,d.z/2+1.5),Vector3(x,1.1,d.z/2+1.5),0.12,"oak",g)
			beam(Vector3(-3.8,0.95,d.z/2+1.5),Vector3(-1.8,0.95,d.z/2+1.5),0.13,"oak",g)
		elif id == "tollhouse":
			var porch := node_group("SideServicePorch",Vector3(d.x/2+0.85,0,0),0,g)
			for z in [-1.2,1.2]:
				beam(Vector3(0.65,0,z),Vector3(0.65,2.7,z),0.13,"oak",porch)
			roof(1.9,2.9,2.7,0.65,"roof",porch)
			block(Vector3(0,1.0,0),Vector3(1.6,0.13,1.3),"oak_light",porch)
			attachment(g,"service",Vector3(d.x/2+1.9,0,0))
		elif id == "boathouse":
			# Wide closed double door, boat slip apron and gable winch.
			for x in [-1.65,1.65]:
				beam(Vector3(x,0.05,d.z/2+0.5),Vector3(x,0.05,d.z/2+3.8),0.15,"oak",g)
			for i in 20:
				block(Vector3(0,0.02,d.z/2+0.5+i*0.17),Vector3(3.8,0.12,0.15),shade("wood"),g)
			block(Vector3(0,1.25,d.z/2+0.19),Vector3(0.06,2.5,0.08),"iron",g)
			ring(Vector3(0,3.25,d.z/2+0.35),0.28,0.055,"iron",g,true)
			attachment(g,"slip",Vector3(0,0,d.z/2+3.8))
		elif id == "granary":
			for z in [-1.6,0.0,1.6]:
				var vent := node_group("RoofVent",Vector3(0,d.y+1.55,z),0,g)
				block(Vector3(0,0.3,0),Vector3(0.85,0.6,0.7),"oak",vent)
				for y in [0.1,0.25,0.4,0.55]:
					block(Vector3(0,y,0.39),Vector3(0.75,0.06,0.1),"oak_light",vent)
				roof(1.15,0.95,0.6,0.4,"slate",vent)
			for x in [-2.4,2.4]:
				barrel(g,Vector3(x,0,d.z/2+0.8),1.2)
		elif id == "bell-hall":
			var turret := node_group("BellTurret",Vector3(0,d.y+1.6,1.8),0,g)
			block(Vector3(0,0.05,0),Vector3(1.6,0.15,1.6),"oak",turret)
			for x in [-0.65,0.65]:
				for z in [-0.65,0.65]:
					beam(Vector3(x,0,z),Vector3(x,1.6,z),0.13,"oak",turret)
			roof(1.9,1.9,1.6,0.9,"slate",turret)
			var bell := CylinderMesh.new()
			bell.top_radius = 0.18
			bell.bottom_radius = 0.44
			bell.height = 0.65
			bell.radial_segments = 32
			piece(bell,Vector3(0,0.85,0),Vector3.ONE,"gold",turret)
			beam(Vector3(0,0.9,0),Vector3(0,1.6,0),0.06,"iron",turret)
			banner(Vector3(-1.85,3.7,d.z/2+0.32),0.6,1.8,g)
		elif id == "fishmonger":
			var counter := catalog_model("fish-stall")
			counter.reparent(g,false)
			counter.position = Vector3(-2.9,0,d.z/2+1.5)
			var rack := catalog_model("fishing-rack")
			rack.reparent(g,false)
			rack.position = Vector3(d.x/2+0.7,0,0)
			rack.rotation.y = PI/2
		elif id == "chandlery":
			var stock := catalog_model("cargo-stack")
			stock.reparent(g,false)
			stock.position = Vector3(-2.2,0,d.z/2+0.8)
			for i in 4:
				var candle_x := 1.45+i*0.15
				cylinder(Vector3(candle_x,1.15,d.z/2+0.85),0.065,0.6+i*0.09,"sand",g)
			crate(g,Vector3(1.7,0,d.z/2+0.8),Vector3(1.2,0.85,0.7))
			beam(Vector3(-1.5,3.2,d.z/2),Vector3(-1.5,3.2,d.z/2+1),0.08,"iron",g)
			ring(Vector3(-1.5,2.85,d.z/2+0.9),0.3,0.045,"gold",g,true)
		elif id == "stone-cottage":
			wall(0.75,5.3,0.7,Vector3(d.x/2-0.5,0,-1.5),g)
			block(Vector3(d.x/2-0.5,5.4,-1.5),Vector3(0.95,0.2,0.9),"stone9",g)
			for x in [-1.6,1.6]:
				var planter := catalog_model("flower-planter")
				planter.reparent(g,false)
				planter.position = Vector3(x,0,d.z/2+0.65)
		elif id == "guard-barracks":
			for x in [-3.8,3.8]:
				banner(Vector3(x,3.5,d.z/2+0.35),0.8,2.2,g)
			var shelter := node_group("EntryShelter",Vector3(0,0,d.z/2+0.7),0,g)
			for x in [-1.5,1.5]:
				beam(Vector3(x,0,0.75),Vector3(x,2.8,0.75),0.16,"oak",shelter)
			roof(3.5,1.8,2.8,1,"slate",shelter)
	elif id in ["watchtower","gatehouse"]:
		for x in ([-3.0,3.0] if id == "gatehouse" else [0.0]):
			var tower := node_group("Tower",Vector3(x,0,0),0,g)
			block(Vector3(0,3.1,0),Vector3(3.3,6.2,3.3),"mortar",tower)
			for face in 4:
				var elevation := node_group("MasonryFace",Vector3.ZERO,face*PI/2,tower)
				wall(3.3,6.2,0.3,Vector3(0,0,1.65),elevation)
				window_at(Vector3(0,4.7,1.83),elevation,0.5)
				for y in [0.2,3.4,5.95]:
					block(Vector3(0,y,1.72),Vector3(3.6,0.16,0.34),"stone9",elevation)
				for row in 15:
					for bx in [-1.52,1.52]:
						block(Vector3(bx,0.21+row*0.4,1.71),Vector3(0.36 if row%2 == 0 else 0.54,0.37,0.32),shade("stone"),elevation)
				for bx in [-1.2,0.0,1.2]:
					block(Vector3(bx,6.55,1.65),Vector3(0.55,0.7,0.5),"stone9",elevation)
			block(Vector3(0,6.15,0),Vector3(3.8,0.24,3.8),"stone7",tower)
		if id == "gatehouse":
			block(Vector3(0,4.35,0),Vector3(3.0,1.0,3.2),"stone5",g)
			for z in [-1.7,1.7]:
				block(Vector3(0,5.05,z),Vector3(3.0,0.5,0.25),"stone9",g)
				for i in 13:
					var a := PI*i/12
					var arch := block(Vector3(cos(a)*1.48,2.5+sin(a)*1.48,z),Vector3(0.32,0.4,0.3),"stone9",g)
					arch.rotation.z = a-PI/2
			attachment(g,"route_a",Vector3(0,0,2.2))
			attachment(g,"route_b",Vector3(0,0,-2.2))
		else:
			block(Vector3(0,1.05,1.83),Vector3(1.05,2.1,0.08),"oak",g)
			for y in [0.45,1.5]:
				block(Vector3(0,y,1.88),Vector3(1.02,0.08,0.04),"iron",g)
			for x in [-0.65,0.65]:
				block(Vector3(x,1.12,1.84),Vector3(0.22,2.24,0.26),"stone9",g)
			block(Vector3(0,2.24,1.84),Vector3(1.5,0.25,0.26),"stone9",g)
			attachment(g,"entrance",Vector3(0,0,2.1))
	elif id in ["produce-stall","fish-stall"]:
		for x in [-1.45,1.45]:
			for z in [-0.65,0.65]:
				beam(Vector3(x,0,z),Vector3(x,2.55,z),0.1,"oak",g)
		for i in 16:
			var roof_panel := block(Vector3((i-7.5)*0.2,2.65,0),Vector3(0.2,0.07,1.95),"cloth" if i%2 == 0 else "sand",g)
			roof_panel.rotation.x = -0.12
		crate(g,Vector3.ZERO,Vector3(2.8,0.95,1.05))
		for tray in 3:
			var x := (tray-1)*0.85
			crate(g,Vector3(x,0.96,0),Vector3(0.78,0.14,0.85))
			for item in 9:
				ellipsoid(Vector3(x+(item%3-1)*0.2,1.14+(item/3)*0.015,(item/3-1)*0.21),Vector3(0.085,0.08,0.085) if id == "produce-stall" else Vector3(0.055,0.035,0.15),"roof8" if id == "produce-stall" else "stone10",g)
		attachment(g,"vendor",Vector3(0,0,-1.25))
		attachment(g,"customer",Vector3(0,0,1.2))
	elif id == "mud-court":
		material("wet_mud",Color("49372b"),0.45)
		material("mud_water",Color("302e25"),0.16)
		block(Vector3(0,0.1,0),Vector3(4,0.2,4),"wet_mud",g)
		for i in 90:
			var p := Vector3(rng.randf_range(-1.8,1.8),0.193,rng.randf_range(-1.8,1.8))
			var clod := rock(p,Vector3(rng.randf_range(0.08,0.25),0.025,rng.randf_range(0.1,0.28)),g)
			clod.material_override = mat("wet_mud")
		for p in [Vector3(-0.8,0.221,0.6),Vector3(1.1,0.221,-0.7),Vector3(0.2,0.221,1.2)]:
			ellipsoid(p,Vector3(0.48,0.006,0.28),"mud_water",g)
		attachment(g,"surface",Vector3(0,0.22,0))
	elif id == "manicured-lawn":
		var turf := material("lawn_base",Color.WHITE)
		var noise := FastNoiseLite.new()
		noise.seed = 607
		noise.frequency = 0.035
		var texture := NoiseTexture2D.new()
		texture.width = 512
		texture.height = 512
		texture.noise = noise
		texture.seamless = true
		var colors := Gradient.new()
		colors.set_color(0,Color("405634"))
		colors.set_color(1,Color("607348"))
		texture.color_ramp = colors
		turf.albedo_texture = texture
		material("lawn_blade",Color("64784c"))
		block(Vector3(0,0.10,0),Vector3(4,0.2,4),"soil",g)
		block(Vector3(0,0.215,0),Vector3(4,0.035,4),"lawn_base",g)
		for i in 750:
			var p := Vector3(rng.randf_range(-1.97,1.97),0.23,rng.randf_range(-1.97,1.97))
			beam(p,p+Vector3(0.018,rng.randf_range(0.012,0.035),0.008),0.006,"lawn_blade",g)
		attachment(g,"surface",Vector3(0,0.24,0))
	elif id == "stump-seat":
		cylinder(Vector3(0,0.23,0),0.3,0.46,"oak",g,24)
		cylinder(Vector3(0,0.46,0),0.285,0.025,"oak_light",g,32)
		for radius in [0.07,0.13,0.2,0.26]:
			ring(Vector3(0,0.475,0),radius,0.004,"wood3",g)
		for i in 18:
			var a := i*TAU/18
			beam(Vector3(cos(a)*0.29,0.02,sin(a)*0.29),Vector3(cos(a)*0.30,0.43,sin(a)*0.30),0.025,shade("wood"),g)
		attachment(g,"seat",Vector3(0,0.48,0))
	elif id == "plank-approach":
		for z in [-1.2,1.2]:
			block(Vector3(0,0.055,z),Vector3(1.7,0.11,0.13),"oak",g)
		for x in 7:
			block(Vector3((x-3)*0.23,0.135,0),Vector3(0.215,0.08,3.2),shade("wood"),g)
			for z in [-1.2,1.2]:
				cylinder(Vector3((x-3)*0.23,0.179,z),0.015,0.009,"iron",g,8)
		attachment(g,"start",Vector3(0,0.18,-1.6))
		attachment(g,"end",Vector3(0,0.18,1.6))
	elif id == "display-rack":
		for x in [-1.0,1.0]:
			beam(Vector3(x,0,-0.25),Vector3(x,2.1,-0.25),0.12,"oak_light",g)
			block(Vector3(x,0.06,0),Vector3(0.22,0.12,0.85),"oak",g)
		for y in [0.45,1.05,1.65]:
			for z in 4:
				block(Vector3(0,y,-0.2+z*0.14),Vector3(2.15,0.08,0.13),shade("wood"),g)
		beam(Vector3(-1,0.2,-0.3),Vector3(1,1.95,-0.3),0.06,"oak",g)
		attachment(g,"display",Vector3(0,1.13,0))
	elif id == "barrel":
		barrel(g,Vector3.ZERO)
	elif id == "cargo-stack":
		crate(g,Vector3(-0.45,0,0),Vector3(1,0.8,0.9))
		crate(g,Vector3(-0.4,0.82,0),Vector3(0.7,0.55,0.7))
		barrel(g,Vector3(0.65,0,0.15))
	elif id == "handcart":
		for i in 7:
			block(Vector3((i-3)*0.17,0.58,0),Vector3(0.16,0.12,1.7),shade("wood"),g)
		for row in 3:
			for x in [-0.58,0.58]:
				block(Vector3(x,0.72+row*0.15,0),Vector3(0.07,0.13,1.7),shade("wood"),g)
			block(Vector3(0,0.72+row*0.15,-0.84),Vector3(1.15,0.13,0.07),shade("wood"),g)
		for x in [-0.6,0.6]:
			for z in [-0.8,0.8]:
				block(Vector3(x,0.86,z),Vector3(0.09,0.68,0.09),"iron",g)
		for x in [-0.8,0.8]:
			var wheel := node_group("SpokedWheel",Vector3(x,0.5,0),0,g)
			wheel.rotation.z = PI/2
			ring(Vector3.ZERO,0.46,0.045,"iron",wheel)
			cylinder(Vector3.ZERO,0.1,0.18,"oak",wheel)
			for i in 10:
				beam(Vector3.ZERO,Vector3(cos(i*TAU/10)*0.44,0,sin(i*TAU/10)*0.44),0.045,"oak_light",wheel)
			beam(Vector3(x*0.65,0.7,0.4),Vector3(x*0.65,0.55,2.3),0.08,"oak",g)
		attachment(g,"handle",Vector3(0,0.55,2.3))
	elif id in ["roofed-well","fountain"]:
		for row in 4:
			for i in 20:
				var a := TAU*(i+0.5*(row%2))/20+0.004
				var b := a+TAU/20-0.008
				var outline := PackedVector2Array([Vector2(cos(a),sin(a))*0.88,Vector2(cos(a),sin(a))*1.21,Vector2(cos(b),sin(b))*1.21,Vector2(cos(b),sin(b))*0.88])
				piece(solid_polygon(outline,0.237,0.008),Vector3(0,row*0.24,0),Vector3.ONE,shade("stone"),g)
		cylinder(Vector3(0,0.22,0),0.96,0.045,"water",g,40)
		if id == "roofed-well":
			for x in [-1.25,1.25]:
				beam(Vector3(x,0,0),Vector3(x,2.75,0),0.16,"oak",g)
			roof(3.1,2.2,2.65,0.85,"slate",g)
			beam(Vector3(-1.3,1.75,0),Vector3(1.3,1.75,0),0.12,"oak_light",g)
			beam(Vector3(0,0.7,0),Vector3(0,1.75,0),0.025,"sand",g)
		else:
			cylinder(Vector3(0,0.95,0),0.19,1.6,"stone9",g,20)
			cylinder(Vector3(0,1.68,0),0.57,0.16,"stone7",g,32)
			ellipsoid(Vector3(0,1.94,0),Vector3(0.15,0.22,0.15),"stone10",g)
	elif id == "stone-bench":
		for x in [-0.8,0.8]:
			block(Vector3(x,0.23,0),Vector3(0.3,0.46,0.5),"stone5",g)
		block(Vector3(0,0.53,0),Vector3(2.1,0.18,0.65),"stone10",g)
		attachment(g,"seat",Vector3(0,0.62,0))
	elif id in ["street-lantern","signpost","mooring-post"]:
		var h := 3.0 if id == "street-lantern" else (2.4 if id == "signpost" else 1.1)
		cylinder(Vector3(0,0.1,0),0.24,0.2,"stone5",g)
		cylinder(Vector3(0,h/2,0),0.12,h,"oak",g)
		if id == "street-lantern":
			beam(Vector3(0,2.8,0),Vector3(0.7,2.8,0),0.08,"iron",g)
			lantern(Vector3(0.6,2.3,0),g)
		elif id == "signpost":
			for y in [1.8,2.2]:
				block(Vector3(0,y,0),Vector3(1.3,0.23,0.08),"oak_light",g)
			attachment(g,"label",Vector3(0,2.2,0.06))
		else:
			for y in [0.65,0.72,0.79]:
				ring(Vector3(0,y,0),0.15,0.025,"sand",g)
			attachment(g,"mooring",Vector3(0,0.72,0))
	elif id in ["hedge-run","vine-bower"]:
		if id == "hedge-run":
			for i in 12:
				var x := (i-5.5)*0.25
				beam(Vector3(x,0,0),Vector3(x,0.85,0),0.035,"oak",g)
				for y in [0.15,0.5,0.8]:
					shrub(Vector3(x,y,0),0.42,g)
		else:
			for x in [-1.45,1.45]:
				for z in [-0.75,0.75]:
					beam(Vector3(x,0,z),Vector3(x,2.25,z),0.1,"oak",g)
			for i in 11:
				var x := (i-5)*0.3
				beam(Vector3(x,2.3,-1.05),Vector3(x,2.3,1.05),0.08,"oak_light",g)
				shrub(Vector3(x,2.3,-0.65),0.5,g,true)
				shrub(Vector3(x,2.3,0.65),0.5,g,true)
			for z in [-0.75,0.75]:
				beam(Vector3(-1.6,2.23,z),Vector3(1.6,2.23,z),0.12,"oak",g)
	elif id == "quay-wall":
		wall(4.0,1.3,0.7,Vector3.ZERO,g)
		for i in 8:
			block(Vector3((i-3.5)*0.5,1.36,0),Vector3(0.48,0.18,0.88),shade("stone"),g)
		attachment(g,"join_a",Vector3(-2,0,0))
		attachment(g,"join_b",Vector3(2,0,0))
	elif id == "pier-section":
		for x in [-1.3,1.3]:
			for z in [-1.7,1.7]:
				cylinder(Vector3(x,0.8,z),0.15,1.6,"oak",g)
			beam(Vector3(x,0.5,-1.7),Vector3(x,1.1,1.7),0.12,"oak",g)
			block(Vector3(x,0.92,0),Vector3(0.2,0.2,4.0),"oak",g)
		for i in 24:
			block(Vector3(0,1.08,(i-11.5)*0.165),Vector3(2.9,0.13,0.15),shade("wood"),g)
		attachment(g,"join_a",Vector3(0,1.145,-1.98))
		attachment(g,"join_b",Vector3(0,1.145,1.98))
	elif id == "landing-stairs":
		stairs(Vector3(0,0,-1.5),2.4,1.44,3.0,g,true)
		attachment(g,"upper",Vector3(0,1.44,-1.5))
		attachment(g,"lower",Vector3(0,0,1.5))
	elif id == "courtyard-wall":
		wall(4,1.8,0.4,Vector3.ZERO,g)
		for x in [-2.05,2.05]:
			wall(0.6,2.15,0.6,Vector3(x,0,0),g)
			block(Vector3(x,2.22,0),Vector3(0.75,0.15,0.75),"stone9",g)
		for i in 10:
			block(Vector3((i-4.5)*0.4,1.86,0),Vector3(0.39,0.18,0.55),shade("stone"),g)
		attachment(g,"join_a",Vector3(-2.35,0,0))
		attachment(g,"join_b",Vector3(2.35,0,0))
	elif id == "timber-gate":
		for x in [-1.65,1.65]:
			block(Vector3(x,1.15,0),Vector3(0.24,2.3,0.3),"oak",g)
		for i in 18:
			block(Vector3((i-8.5)*0.17,0.9,0),Vector3(0.15,1.65,0.09),shade("wood"),g)
		for side in [-1,1]:
			for y in [0.4,1.4]:
				block(Vector3(side*0.8,y,0.08),Vector3(1.45,0.1,0.07),"iron",g)
			beam(Vector3(side*1.5,0.3,0.12),Vector3(side*0.08,1.5,0.12),0.09,"oak_light",g)
		attachment(g,"hinge_l",Vector3(-1.5,0,0))
		attachment(g,"hinge_r",Vector3(1.5,0,0))
	elif id == "notice-board":
		for x in [-1.1,1.1]:
			beam(Vector3(x,0,0),Vector3(x,2.6,0),0.13,"oak",g)
		crate(g,Vector3(0,1.2,0),Vector3(2.2,1.1,0.14))
		roof(2.7,0.75,2.65,0.4,"slate",g)
		for x in [-0.65,0.0,0.65]:
			block(Vector3(x,1.75,0.14),Vector3(0.45,0.62,0.015),"sand",g)
		attachment(g,"notice",Vector3(0,1.75,0.17))
	elif id in ["trestle-table","stool"]:
		var width := 2.8 if id == "trestle-table" else 0.55
		var depth := 0.85 if id == "trestle-table" else 0.55
		var height := 0.82 if id == "trestle-table" else 0.48
		for x in [-width*0.35,width*0.35]:
			for side in [-1,1]:
				beam(Vector3(x,0,side*depth*0.45),Vector3(x,height,side*depth*0.2),0.1,"oak",g)
		beam(Vector3(-width*0.35,height*0.45,0),Vector3(width*0.35,height*0.45,0),0.1,"oak",g)
		for i in 5:
			block(Vector3(0,height,(i-2)*depth/5),Vector3(width,0.09,depth/5-0.012),shade("wood"),g)
		attachment(g,"surface",Vector3(0,height+0.045,0))
	elif id == "woodpile":
		for row in 4:
			for i in 5-row:
				var pos := Vector3((i-(4-row)/2.0)*0.32,0.16+row*0.28,0)
				var log := cylinder(pos,0.155,1.8,"oak",g,16)
				log.rotation.x = PI/2
				for z in [-0.91,0.91]:
					var end := cylinder(pos+Vector3(0,0,z),0.135,0.012,"oak_light",g,16)
					end.rotation.x = PI/2
	elif id == "water-trough":
		block(Vector3(0,0.12,0),Vector3(2.4,0.24,0.8),"stone5",g)
		for z in [-0.38,0.38]:
			block(Vector3(0,0.4,z),Vector3(2.4,0.55,0.16),"stone8",g)
		for x in [-1.15,1.15]:
			block(Vector3(x,0.4,0),Vector3(0.17,0.55,0.8),"stone8",g)
		block(Vector3(0,0.42,0),Vector3(2.2,0.035,0.6),"water",g)
		attachment(g,"water",Vector3(0,0.44,0))
	elif id == "cargo-crane":
		block(Vector3(0,0.2,0),Vector3(1.7,0.4,1.7),"stone7",g)
		beam(Vector3(0,0.4,0),Vector3(0,4.2,0),0.32,"oak",g)
		beam(Vector3(0,3.9,0),Vector3(0,3.9,2.8),0.25,"oak",g)
		beam(Vector3(0,1.4,0),Vector3(0,3.9,2.5),0.2,"oak_light",g)
		for y in [0.7,1.1,3.6]:
			ring(Vector3(0,y,0),0.22,0.035,"iron",g)
		ring(Vector3(0,3.6,2.6),0.22,0.04,"iron",g,true)
		beam(Vector3(0,1.0,2.6),Vector3(0,3.6,2.6),0.03,"sand",g)
		ring(Vector3(0,0.9,2.6),0.13,0.035,"iron",g,true)
		attachment(g,"load",Vector3(0,0.72,2.6))
	elif id == "rope-coil":
		for i in 7:
			ring(Vector3(0,0.028,0),0.18+i*0.055,0.026,"sand",g)
		beam(Vector3(0.5,0.028,0),Vector3(0.95,0.028,0.2),0.045,"sand",g)
	elif id == "timber-footbridge":
		for x in [-1.3,1.3]:
			block(Vector3(x,0.45,0),Vector3(0.18,0.3,5.0),"oak",g)
			for z in [-2.35,0.0,2.35]:
				beam(Vector3(x,0,z),Vector3(x,1.65,z),0.13,"oak",g)
			for y in [0.95,1.6]:
				beam(Vector3(x,y,-2.4),Vector3(x,y,2.4),0.09,"oak_light",g)
		for i in 30:
			block(Vector3(0,0.63,(i-14.5)*0.165),Vector3(2.8,0.12,0.15),shade("wood"),g)
		attachment(g,"route_a",Vector3(0,0.69,-2.475))
		attachment(g,"route_b",Vector3(0,0.69,2.475))
	elif id == "reed-bank":
		piece(solid_polygon(PackedVector2Array([Vector2(-1.5,-0.5),Vector2(1.2,-0.8),Vector2(1.55,0.5),Vector2(0.4,0.85),Vector2(-1.3,0.65)]),0.12),Vector3.ZERO,Vector3.ONE,"soil",g)
		for i in 65:
			var pos := Vector3(rng.randf_range(-1.2,1.2),0.12,rng.randf_range(-0.45,0.45))
			var tip := pos+Vector3(rng.randf_range(-0.15,0.15),rng.randf_range(0.6,1.25),0.07)
			beam(pos,tip,0.018,"reed",g)
			if i%3 == 0:
				ellipsoid(tip,Vector3(0.035,0.12,0.035),"oak",g)
	elif id == "rock-shelf":
		for i in 12:
			rock(Vector3(rng.randf_range(-1.4,1.4),0,rng.randf_range(-0.9,0.9)),Vector3(rng.randf_range(0.7,1.5),rng.randf_range(0.35,0.8),rng.randf_range(0.6,1.2)),g)
	elif id in ["cobble-plaza","cobble-street","dirt-path","grass-verge"]:
		block(Vector3(0,0.08,0),Vector3(4,0.16,4),"mortar" if id.begins_with("cobble") else "soil",g)
		if id.begins_with("cobble"):
			for row in 16:
				for col in 12:
					var x := -2+(col+0.5)*4/12.0
					block(Vector3(x,0.19,-2+(row+0.5)*0.25),Vector3(4/12.0-0.018,0.06,0.235),shade("stone"),g)
			if id == "cobble-street":
				for x in [-1.85,1.85]:
					for row in 10:
						block(Vector3(x,0.25,(row-4.5)*0.4),Vector3(0.28,0.18,0.39),"stone9",g)
		else:
			if id == "grass-verge":
				for i in 130:
					var pos := Vector3(rng.randf_range(-1.8,1.8),0.16,rng.randf_range(-1.8,1.8))
					beam(pos,pos+Vector3(0.03,rng.randf_range(0.08,0.2),0),0.018,"reed",g)
			else:
				for x in [-0.72,0.72]:
					for i in 20:
						block(Vector3(x+rng.randf_range(-0.035,0.035),0.161,(i-9.5)*0.2),Vector3(rng.randf_range(0.12,0.2),0.005,0.2),"mortar",g)
			for i in 25:
				rock(Vector3(rng.randf_range(-1.9,1.9),0.15,rng.randf_range(-1.9,1.9)),Vector3(0.1,0.04,0.08),g)
		var top := 0.22 if id.begins_with("cobble") else 0.16
		attachment(g,"north",Vector3(0,top,-2))
		attachment(g,"south",Vector3(0,top,2))
		attachment(g,"west",Vector3(-2,top,0))
		attachment(g,"east",Vector3(2,top,0))
	elif id in ["curb-run","curb-corner","quay-corner"]:
		var height := 1.4 if id == "quay-corner" else 0.25
		for leg in (1 if id == "curb-run" else 2):
			var arm := node_group("Arm",Vector3.ZERO,-leg*PI/2,g)
			for i in (8 if id == "curb-run" else 4):
				block(Vector3(-1.75+i*0.5,height/2,0),Vector3(0.48,height,0.4),shade("stone"),arm)
		if id != "curb-run":
			block(Vector3(0,height/2,0),Vector3(0.4,height,0.4),"stone9",g)
		attachment(g,"join_a",Vector3(-2,height,0))
		attachment(g,"join_b",Vector3(2,height,0) if id == "curb-run" else Vector3(0,height,-2))
	elif id in ["dock-ramp","beach-slope"]:
		var width := 2.8 if id == "dock-ramp" else 4.0
		sloped_block(g,width,4,0.9,0.1,"oak" if id == "dock-ramp" else "sand")
		if id == "dock-ramp":
			for i in 24:
				var z := -2+(i+0.5)*4/24.0
				var plank := block(Vector3(0,lerpf(0.9,0.1,(z+2)/4)+0.025,z),Vector3(width,0.06,0.15),shade("wood"),g)
				plank.rotation.x = atan(0.2)
		else:
			for i in 20:
				var z := rng.randf_range(-1.8,1.8)
				rock(Vector3(rng.randf_range(-1.8,1.8),lerpf(0.9,0.1,(z+2)/4),z),Vector3(0.15,0.08,0.2),g)
		attachment(g,"upper",Vector3(0,0.95 if id == "dock-ramp" else 0.9,-2))
		attachment(g,"lower",Vector3(0,0.15 if id == "dock-ramp" else 0.1,2))
	elif id == "workbench":
		for x in [-1.1,1.1]:
			for z in [-0.4,0.4]:
				block(Vector3(x,0.45,z),Vector3(0.15,0.9,0.15),"oak",g)
		for y in [0.25,0.95]:
			for i in 6:
				block(Vector3(0,y,(i-2.5)*0.17),Vector3(2.6,0.12,0.16),shade("wood"),g)
		block(Vector3(1.0,1.03,0.38),Vector3(0.24,0.22,0.3),"iron",g)
		beam(Vector3(1,0.9,0.5),Vector3(1,0.9,0.8),0.05,"iron",g)
		attachment(g,"surface",Vector3(0,1.01,0))
	elif id == "anvil":
		cylinder(Vector3(0,0.3,0),0.36,0.6,"oak",g,20)
		block(Vector3(0,0.64,0),Vector3(0.6,0.12,0.4),"iron",g)
		block(Vector3(0,0.82,0),Vector3(0.3,0.3,0.24),"iron",g)
		block(Vector3(0,1.0,0),Vector3(0.78,0.15,0.35),"iron",g)
		var horn := CylinderMesh.new()
		horn.top_radius = 0.015
		horn.bottom_radius = 0.16
		horn.height = 0.5
		var mesh := piece(horn,Vector3(0.55,0.99,0),Vector3.ONE,"iron",g)
		mesh.rotation.z = -PI/2
		attachment(g,"strike",Vector3(0,1.08,0))
	elif id in ["tool-rack","fishing-rack"]:
		for x in [-1.1,1.1]:
			beam(Vector3(x,0,0),Vector3(x,2.0,0),0.11,"oak",g)
			beam(Vector3(x,0,-0.45),Vector3(x,0,0.45),0.13,"oak",g)
		for y in [0.5,1.8]:
			beam(Vector3(-1.2,y,0),Vector3(1.2,y,0),0.1,"oak_light",g)
		if id == "tool-rack":
			for i in 5:
				var x := (i-2)*0.43
				beam(Vector3(x,0.65,0.08),Vector3(x,1.8,0.08),0.045,"oak_light",g)
				block(Vector3(x,1.7,0.08),Vector3(0.28,0.14,0.1),"iron",g)
		else:
			for i in 18:
				var x := (i-8.5)*0.12
				beam(Vector3(x,0.6,0.04),Vector3(x,1.7,0.04),0.013,"sand",g)
			for i in 10:
				beam(Vector3(-1.03,0.6+i*0.12,0.04),Vector3(1.03,0.6+i*0.12,0.04),0.013,"sand",g)
	elif id == "forge-hearth":
		block(Vector3(0,0.15,0),Vector3(1.8,0.3,1.5),"stone5",g)
		wall(1.8,1.5,0.3,Vector3(0,0,-0.6),g)
		for x in [-0.8,0.8]:
			wall(1.5,0.9,0.25,Vector3(x,0,0),g,true)
		for i in 24:
			rock(Vector3(rng.randf_range(-0.5,0.5),0.3,rng.randf_range(-0.3,0.45)),Vector3(0.14,0.08,0.12),g).material_override = mat("iron")
		for i in 5:
			ellipsoid(Vector3((i-2)*0.18,0.36,0),Vector3(0.06,0.025,0.06),"lamp",g)
		attachment(g,"fire",Vector3(0,0.45,0))
	elif id == "bucket":
		cylinder(Vector3(0,0.025,0),0.25,0.05,"oak",g,20)
		for i in 20:
			var a := i*TAU/20
			var stave := block(Vector3(cos(a)*0.25,0.25,sin(a)*0.25),Vector3(0.035,0.48,0.075),shade("wood"),g)
			stave.rotation.y = -a
		for y in [0.08,0.4]:
			ring(Vector3(0,y,0),0.27,0.018,"iron",g)
		for i in 16:
			var a := PI*i/16
			var b := PI*(i+1)/16
			beam(Vector3(cos(a)*0.29,0.45+sin(a)*0.29,0),Vector3(cos(b)*0.29,0.45+sin(b)*0.29,0),0.02,"iron",g)
	elif id == "sack-stack":
		materials["burlap"] = mat("cloth").duplicate()
		materials["burlap"].resource_name = "burlap"
		materials["burlap"].albedo_color = Color("938266")
		var sphere := SphereMesh.new()
		sphere.radius = 1
		sphere.height = 2
		sphere.radial_segments = 32
		sphere.rings = 16
		var arrays := sphere.get_mesh_arrays()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in indices:
			var v := vertices[index]
			var width := (1-0.45*maxf(v.y,0))*(1+0.055*sin(v.y*18+atan2(v.z,v.x)*5))
			v.x *= width
			v.z *= width
			v.y = maxf(-0.78,v.y)
			surface.add_vertex(v)
		surface.generate_normals()
		var sack := surface.commit()
		for pos in [Vector3(-0.36,0.39,0),Vector3(0.36,0.39,0.1),Vector3(0,1.13,0)]:
			piece(sack,pos,Vector3(0.36,0.5,0.3),"burlap",g)
			ellipsoid(pos+Vector3(0,0.48,0),Vector3(0.1,0.09,0.08),"burlap",g)
			ring(pos+Vector3(0,0.43,0),0.085,0.018,"oak_light",g)
	elif id == "mooring-cleat":
		block(Vector3(0,0.055,0),Vector3(0.7,0.11,0.35),"iron",g)
		for x in [-0.18,0.18]:
			beam(Vector3(x,0.1,0),Vector3(x,0.27,0),0.08,"iron",g)
		beam(Vector3(-0.45,0.28,0),Vector3(0.45,0.28,0),0.1,"iron",g)
		attachment(g,"rope",Vector3(0,0.27,0))
	elif id == "driftwood":
		for ends in [[Vector3(-1.3,0.19,0),Vector3(1.1,0.22,0.1),0.17],[Vector3(-0.4,0.2,0),Vector3(-1,0.15,-0.6),0.07],[Vector3(0.5,0.2,0),Vector3(1.0,0.17,0.65),0.08]]:
			var a: Vector3 = ends[0]
			var b: Vector3 = ends[1]
			var log := cylinder((a+b)/2,ends[2],a.distance_to(b),"oak_light",g,16)
			log.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	elif id == "basalt-outcrop":
		for x in range(-2,3):
			for z in range(-1,2):
				var h := rng.randf_range(0.6,2.0)
				cylinder(Vector3(x*0.46,h/2,z*0.43+(x%2)*0.2),0.29,h,"slate2",g,6)
	elif id == "stone-culvert":
		for x in [-1.05,1.05]:
			wall(1.8,0.8,0.65,Vector3(x,0,0),g,true)
		for i in 16:
			var a := i*PI/16
			var b := (i+1)*PI/16
			# Side profile extruded along depth, leaving an actual water passage.
			var profile := PackedVector2Array([Vector2(cos(a)*0.72,sin(a)*0.72),Vector2(cos(a)*1.25,sin(a)*1.25),Vector2(cos(b)*1.25,sin(b)*1.25),Vector2(cos(b)*0.72,sin(b)*0.72)])
			var segment := piece(solid_polygon(profile,1.8,0.01),Vector3(0,0.45,0.9),Vector3.ONE,shade("stone"),g)
			segment.rotation.x = -PI/2
		attachment(g,"water_a",Vector3(0,0.25,-0.9))
		attachment(g,"water_b",Vector3(0,0.25,0.9))
	elif id in ["oak-tree","willow-tree"]:
		tree(Vector3.ZERO,6.2,g,"willow" if id == "willow-tree" else "oak")
	elif id == "cypress-tree":
		cylinder(Vector3(0,2.5,0),0.14,5,"oak",g,20)
		for level in 16:
			var y := 1.0+level*0.28
			var radius := 0.85*(1-level/18.0)
			for i in 9:
				var a := i*TAU/9+level*0.6
				ellipsoid(Vector3(cos(a)*radius*0.6,y,sin(a)*radius*0.6),Vector3(radius*0.48,0.38,radius*0.48),shade("leaf"),g)
	elif id == "flower-planter":
		crate(g,Vector3.ZERO,Vector3(1.0,0.5,0.6))
		block(Vector3(0,0.525,0),Vector3(0.9,0.02,0.5),"soil",g)
		for x in [-0.3,0.0,0.3]:
			shrub(Vector3(x,0.54,0),0.32,g,true)
	elif id == "hitching-post":
		for x in [-1.2,1.2]:
			cylinder(Vector3(x,0.65,0),0.13,1.3,"oak",g,16)
			cylinder(Vector3(x,1.32,0),0.15,0.06,"iron",g,16)
		beam(Vector3(-1.3,1.05,0),Vector3(1.3,1.05,0),0.14,"oak_light",g)
		for x in [-0.8,0.8]:
			ring(Vector3(x,0.99,0.1),0.085,0.02,"iron",g,true)
			attachment(g,"tether_l" if x < 0 else "tether_r",Vector3(x,0.95,0.1))
	elif id == "capstan":
		cylinder(Vector3(0,0.07,0),0.65,0.14,"oak",g,24)
		cylinder(Vector3(0,0.55,0),0.32,0.95,"oak_light",g,20)
		for y in [0.18,0.85]:
			ring(Vector3(0,y,0),0.35,0.055,"iron",g)
		for i in 4:
			var a := i*TAU/4
			beam(Vector3.ZERO+Vector3(0,0.95,0),Vector3(cos(a)*1.3,0.95,sin(a)*1.3),0.1,"oak",g)
		attachment(g,"rope",Vector3(0.35,0.45,0))
	elif id == "dock-ladder":
		for x in [-0.4,0.4]:
			beam(Vector3(x,0,0),Vector3(x,2.8,0.5),0.075,"oak",g)
		for i in 10:
			var y := 0.15+i*0.27
			beam(Vector3(-0.4,y,y/2.8*0.5),Vector3(0.4,y,y/2.8*0.5),0.06,"oak_light",g)
		attachment(g,"upper",Vector3(0,2.8,0.5))
		attachment(g,"lower",Vector3.ZERO)
	elif id == "hand-pump":
		block(Vector3(0,0.08,0),Vector3(0.7,0.16,0.7),"stone8",g)
		cylinder(Vector3(0,0.7,0),0.12,1.2,"iron",g,20)
		cylinder(Vector3(0,1.4,0),0.07,0.25,"iron",g,16)
		var pivot := cylinder(Vector3(0,1.5,0),0.08,0.22,"iron",g,16)
		pivot.rotation.z = PI/2
		var spout := cylinder(Vector3(0,1.08,0.25),0.065,0.5,"iron",g,16)
		spout.rotation.x = PI/2
		beam(Vector3(0,1.5,0),Vector3(0,1.65,-0.6),0.065,"iron",g)
		beam(Vector3(0,1.65,-0.6),Vector3(0,1.25,-0.75),0.065,"oak",g)
		attachment(g,"water",Vector3(0,1.05,0.5))
	elif id == "rain-barrel":
		barrel(g,Vector3.ZERO,1.25)
		# Removable top cover rather than an invented open liquid volume.
		var tap := cylinder(Vector3(0,0.28,0.49),0.035,0.16,"iron",g,12)
		tap.rotation.x = PI/2
		beam(Vector3(-0.08,0.35,0.49),Vector3(0.08,0.35,0.49),0.035,"iron",g)
		attachment(g,"tap",Vector3(0,0.26,0.57))
	elif id == "grindstone":
		for x in [-0.38,0.38]:
			for z in [-0.4,0.4]:
				beam(Vector3(x,0,z),Vector3(x,0.7,0),0.1,"oak",g)
		var wheel := cylinder(Vector3(0,0.9,0),0.47,0.22,"stone8",g,40)
		wheel.rotation.z = PI/2
		beam(Vector3(-0.65,0.9,0),Vector3(0.65,0.9,0),0.08,"iron",g)
		beam(Vector3(0.65,0.9,0),Vector3(0.65,0.7,0.22),0.05,"iron",g)
		beam(Vector3(0.65,0.7,0.22),Vector3(0.85,0.7,0.22),0.06,"oak_light",g)
	elif id == "log-bench":
		for x in [-0.8,0.8]:
			cylinder(Vector3(x,0.17,0),0.19,0.34,"oak",g,16)
		var seat := cylinder(Vector3(0,0.39,0),0.22,2.3,"oak_light",g,20)
		seat.rotation.z = PI/2
		attachment(g,"seat",Vector3(0,0.61,0))
	elif id in ["canvas-shelter","tattered-shelter"]:
		for x in [-1.5,1.5]:
			for z in [-1.5,1.5]:
				beam(Vector3(x,0,z),Vector3(x,2.3,z),0.1,"oak",g)
		for z in [-1.5,1.5]:
			beam(Vector3(0,0,z),Vector3(0,3.1,z),0.1,"oak",g)
		for side in [-1,1]:
			for i in 15:
				if id == "tattered-shelter" and i > 9 and i%3 == 0:
					continue
				var x: float = side*(i+0.5)*1.7/15
				var length := 3.5-rng.randf_range(0.0,0.35) if id == "tattered-shelter" else 3.5
				var panel := block(Vector3(x,3.1-absf(x)*0.5,0),Vector3(1.7/15+0.005,0.03,length),"redcloth" if id == "tattered-shelter" else "cloth",g)
				panel.rotation.z = -side*atan(0.5)
		attachment(g,"sheltered",Vector3.ZERO)
	else:
		assert(false,"Unknown catalog recipe: "+id)
	return g

func shelving(parent: Node3D, pos: Vector3) -> void:
	for x in [-1.05,1.05]:
		block(pos+Vector3(x,1.2,0),Vector3(0.14,2.4,0.35),"oak",parent)
	for y in [0.35,0.95,1.55,2.15]:
		block(pos+Vector3(0,y,0),Vector3(2.25,0.12,0.5),"oak_light",parent)
		for i in 6:
			cylinder(pos+Vector3(-0.86+i*0.34,y+0.2,0),0.09,rng.randf_range(0.2,0.32),shade("roof"),parent)

func rock(pos: Vector3, size: Vector3, parent: Node3D = root) -> MeshInstance3D:
	var variant := rng.randi_range(0,5)
	var key := "rock%d" % variant
	if not meshes.has(key):
		var sphere := SphereMesh.new()
		sphere.radius = 0.6
		sphere.height = 1.2
		sphere.radial_segments = 11
		sphere.rings = 7
		var arrays := sphere.get_mesh_arrays()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_smooth_group(-1)
		for index in indices:
			var p := vertices[index]
			var perturb := 1.0+0.17*sin(p.x*9+variant)*cos(p.z*7+variant)+0.1*sin(p.y*13+variant)
			p *= perturb
			p.y = maxf(p.y,-0.36)+0.36
			st.add_vertex(p)
		st.generate_normals()
		meshes[key] = st.commit()
	var n := piece(meshes[key],pos,size,shade("stone"),parent)
	n.rotation.y = rng.randf()*TAU
	return n

func organic_branch(a: Vector3, b: Vector3, radius: float, parent: Node3D) -> void:
	if not meshes.has("tapered_branch"):
		var shape := CylinderMesh.new()
		shape.bottom_radius = 1
		shape.top_radius = 0.52
		shape.height = 1
		shape.radial_segments = 12
		meshes.tapered_branch = shape
	var branch := piece(meshes.tapered_branch,(a+b)/2,Vector3(radius,a.distance_to(b),radius),"oak",parent)
	branch.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func tree(pos: Vector3, height: float, parent: Node3D = root, form: String = "oak") -> void:
	var g := node_group("WillowTree" if form == "willow" else "OakTree",pos,0,parent)
	organic_branch(Vector3.ZERO,Vector3(0.15,height*0.62,0),0.23,g)
	if not meshes.has("leaves"):
		var s := SphereMesh.new()
		s.height = 2
		s.radius = 1
		s.radial_segments = 8
		s.rings = 4
		meshes.leaves = s
	for b in 15:
		var a := b*2.399
		var end := Vector3(cos(a)*height*rng.randf_range(0.12,0.32),height*rng.randf_range(0.45,0.9),sin(a)*height*rng.randf_range(0.12,0.32))
		organic_branch(Vector3(0,height*0.35,0),end,0.09,g)
		if form == "willow":
			shrub(end,0.7,g)
		for k in 4:
			var tip := end+Vector3(rng.randf_range(-0.65,0.65),rng.randf_range(0.1,0.7),rng.randf_range(-0.65,0.65))
			if form == "willow":
				tip = end+Vector3(cos(a)*0.6,-height*0.36,sin(a)*0.6)
			organic_branch(end,tip,0.028,g)
			for leaf_index in 25:
				var offset := Vector3(rng.randf_range(-0.6,0.6),rng.randf_range(-0.3,0.5),rng.randf_range(-0.6,0.6))
				if form == "willow":
					offset = (end-tip)*(leaf_index/25.0)+Vector3(rng.randf_range(-0.13,0.13),0,rng.randf_range(-0.13,0.13))
				var leaf := piece(meshes.leaves,tip+offset,Vector3(0.14,0.035,0.09)*rng.randf_range(0.7,1.3),shade("leaf"),g)
				leaf.rotation = Vector3(rng.randf_range(-0.8,0.8),rng.randf()*TAU,rng.randf_range(-0.8,0.8))

func ring(pos: Vector3, radius: float, thickness: float, key: String, parent: Node3D, vertical: bool = false) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = radius-thickness
	torus.outer_radius = radius+thickness
	torus.rings = 32
	torus.ring_segments = 8
	var item := piece(torus,pos,Vector3.ONE,key,parent)
	if vertical:
		item.rotation.x = PI/2

func spire(pos: Vector3, parent: Node3D, scale_value: float = 1.0) -> void:
	block(pos,Vector3(0.4,0.14,0.4)*scale_value,"gold",parent)
	cylinder(pos+Vector3(0,0.16,0)*scale_value,0.11*scale_value,0.2*scale_value,"gold",parent)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.005
	cone.bottom_radius = 0.13
	cone.height = 0.65
	cone.radial_segments = 12
	piece(cone,pos+Vector3(0,0.5,0)*scale_value,Vector3.ONE*scale_value,"gold",parent)

func stairs(pos: Vector3, width: float, height: float, depth: float, parent: Node3D, rails: bool = true) -> void:
	var steps := maxi(3,int(height/0.16))
	for i in steps:
		var y := height*(i+1)/steps
		var z := depth*(1.0-(i+0.5)/float(steps))
		block(pos+Vector3(0,y/2,z),Vector3(width,y,depth/steps+0.015),shade("stone"),parent)
	if rails:
		for x in [-width/2-0.12,width/2+0.12]:
			beam(pos+Vector3(x,0.5,depth),pos+Vector3(x,height+0.5,0),0.22,"stone7",parent)
			for z in [0.0,depth]:
				wall(0.35,0.65,0.4,pos+Vector3(x,height if z == 0 else 0,z),parent)

func banner(pos: Vector3, width: float, height: float, parent: Node3D) -> void:
	beam(pos+Vector3(-width*0.65,0,0),pos+Vector3(width*0.65,0,0),0.07,"gold",parent)
	for row in 15:
		var t := (row+0.5)/15.0
		var z := 0.06*sin(t*PI*2.0)
		block(pos+Vector3(0,-height*t,z),Vector3(width,height/15+0.01,0.03),"cloth",parent)
		for side in [-1,1]:
			block(pos+Vector3(side*(width/2-0.06),-height*t,z+0.025),Vector3(0.025,height/15+0.01,0.025),"gold",parent)
	ring(pos+Vector3(0,-height*0.35,0.1),width*0.23,0.015,"gold",parent,true)
	beam(pos+Vector3(0,-height*0.18,0.1),pos+Vector3(0,-height*0.75,0.1),0.025,"gold",parent)
	for side in [-1,1]:
		beam(pos+Vector3(0,-height*0.4,0.1),pos+Vector3(side*width*0.25,-height*0.23,0.1),0.025,"gold",parent)

func shrub(pos: Vector3, radius: float, parent: Node3D = root, flowers: bool = false) -> void:
	# Small separated leaves preserve the reference's fine silhouette.
	if not meshes.has("leaves"):
		var s := SphereMesh.new()
		s.radius = 1
		s.height = 2
		s.radial_segments = 8
		s.rings = 4
		meshes.leaves = s
	for i in 90:
		var a := rng.randf()*TAU
		var r := radius*sqrt(rng.randf())
		var p := pos+Vector3(cos(a)*r,rng.randf_range(0.05,0.55)*radius,sin(a)*r)
		piece(meshes.leaves,p,Vector3(0.10,0.045,0.065),"flower" if flowers and i%7 == 0 else shade("leaf"),parent)
