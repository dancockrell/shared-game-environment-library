extends SceneTree
## Offline conversion of inspected source geometry; no invented anatomy or rig.
var source := ""
var destination := ""
var failure := false
var core := ""
var body := PackedVector3Array()
var body_variants: Array[PackedVector3Array] = []
const FACE_TARGETS := {
	"Oval face":["head/head-oval.target"],
	"Square face":["head/head-square.target"],
	"Narrow chin":["chin/chin-width-decr.target"],
	"Broad nose":["nose/nose-scale-horiz-incr.target"],
	"Full lips":["mouth/mouth-upperlip-volume-incr.target","mouth/mouth-lowerlip-volume-incr.target"],
	"Pointed ears":["ears/l-ear-shape-pointed.target","ears/r-ear-shape-pointed.target"],
	"Defined cheekbones":["cheek/l-cheek-bones-incr.target","cheek/r-cheek-bones-incr.target"],
	"Full cheeks":["cheek/l-cheek-volume-incr.target","cheek/r-cheek-volume-incr.target"],
	"Larger eyes":["eyes/l-eye-scale-incr.target","eyes/r-eye-scale-incr.target"],
	"Broad jaw":["chin/chin-width-incr.target"]}
var shape_names: Array = ["Lean","Muscular"] + FACE_TARGETS.keys()
var skeleton: Skeleton3D
var skin: Skin
var vertex_weights: Array[Dictionary] = []
func _init() -> void:
	call_deferred("run")
func fail(message: String) -> void:
	push_error(message)
	failure = true
func material(path: String) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.roughness = .85
	if not FileAccess.file_exists(path):
		fail("Missing material: "+path)
		return result
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var fields := line.strip_edges().split(" ",false)
		if fields.is_empty():
			continue
		if fields[0] == "diffuseColor" and fields.size() == 4:
			result.albedo_color = Color(float(fields[1]),float(fields[2]),float(fields[3]))
		if fields[0] == "backfaceCull" and fields.size() == 2 and fields[1] == "False":
			result.cull_mode = BaseMaterial3D.CULL_DISABLED
		if fields[0] == "castShadows" and fields.size() == 2:
			result.set_meta("source_cast_shadows",fields[1] != "False")
		if fields[0] == "transparent" and fields.size() == 2 and fields[1] == "True":
			# Preserve fine hair-card opacity instead of cutting strands into hard dots.
			result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		if fields[0] == "diffuseTexture" and fields.size() == 2:
			var texture_path := path.get_base_dir().path_join(fields[1])
			var image := Image.load_from_file(texture_path)
			if image == null:
				fail("Missing texture: "+texture_path)
				continue
			# Keep source textures untouched; workshop derivatives have a 1024px ceiling.
			var longest := maxi(image.get_width(),image.get_height())
			if longest > 1024:
				image.resize(maxi(1,roundi(image.get_width()*1024.0/longest)),maxi(1,roundi(image.get_height()*1024.0/longest)),Image.INTERPOLATE_LANCZOS)
			image.generate_mipmaps()
			result.albedo_texture = ImageTexture.create_from_image(image)
	return result
func read_vertices(path: String) -> PackedVector3Array:
	var result := PackedVector3Array()
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var f := line.strip_edges().split(" ",false)
		if f.size() == 4 and f[0] == "v":
			result.append(Vector3(float(f[1]),float(f[2]),float(f[3])))
	return result

func add_target(base: PackedVector3Array, path: String) -> PackedVector3Array:
	var result := base.duplicate()
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var f := line.strip_edges().split(" ",false)
		if f.size() == 4 and f[0].is_valid_int():
			var i := int(f[0])
			if i < 0 or i >= result.size():
				fail("Target vertex out of range")
				return base
			result[i] += Vector3(float(f[1]),float(f[2]),float(f[3]))
	return result

func proxy_data(path: String) -> Dictionary:
	var result := {"refs":[],"scales":{},"delete":{}}
	var mode := ""
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var f := line.strip_edges().split(" ",false)
		if f.is_empty() or f[0].is_empty() or f[0].begins_with("#"):
			continue
		if f[0] in ["x_scale","y_scale","z_scale"]:
			result.scales[f[0].left(1)] = [int(f[1]),int(f[2]),float(f[3])]
		elif f[0] == "verts":
			mode = "verts"
		elif f[0] == "delete_verts":
			mode = "delete"
		elif not f[0].is_valid_int():
			continue
		elif mode == "verts":
			if f.size() == 1:
				result.refs.append({"indices":[int(f[0])],"weights":[1.0],"offset":Vector3.ZERO})
			elif f.size() == 9:
				result.refs.append({"indices":[int(f[0]),int(f[1]),int(f[2])],"weights":[float(f[3]),float(f[4]),float(f[5])],"offset":Vector3(float(f[6]),float(f[7]),float(f[8]))})
			else:
				fail("Unsupported fitting row: "+path)
		elif mode == "delete":
			var i := 0
			while i < f.size():
				var start := int(f[i])
				if i+2 < f.size() and f[i+1] == "-":
					for v in range(start,int(f[i+2])+1):
						result.delete[v] = true
					i += 3
				else:
					result.delete[start] = true
					i += 1
	return result

func fitted(data: Dictionary, base: PackedVector3Array) -> PackedVector3Array:
	var scale := Vector3.ONE
	for axis in data.scales:
		var s: Array = data.scales[axis]
		var index: int = {"x":0,"y":1,"z":2}[axis]
		scale[index] = absf(base[s[0]][index]-base[s[1]][index])/s[2]
	var result := PackedVector3Array()
	for ref_data in data.refs:
		var point: Vector3 = ref_data.offset*scale
		for i in ref_data.indices.size():
			point += base[ref_data.indices[i]]*ref_data.weights[i]
		result.append(point*.1)
	return result

func weights_for(ref_data: Dictionary) -> Array:
	var combined := {}
	for i in ref_data.indices.size():
		for bone in vertex_weights[ref_data.indices[i]]:
			combined[bone] = combined.get(bone,0.0) + vertex_weights[ref_data.indices[i]][bone]*maxf(0,ref_data.weights[i])
	var ranked: Array = combined.keys()
	ranked.sort_custom(func(a,b): return combined[a]>combined[b])
	var bones := PackedInt32Array([0,0,0,0])
	var weights := PackedFloat32Array([0,0,0,0])
	var total := 0.0
	for i in mini(4,ranked.size()):
		bones[i] = ranked[i]
		weights[i] = combined[ranked[i]]
		total += weights[i]
	if total <= 0:
		fail("Source fitting point has no skin weights")
		return [bones,weights]
	for i in 4:
		weights[i] /= total
	return [bones,weights]

func connected_vertices(path: String, seed_vertex: int) -> Dictionary:
	var neighbors := {}
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var fields := line.strip_edges().split(" ",false)
		if fields.is_empty() or fields[0] != "f":
			continue
		var first := int(fields[1].split("/")[0])-1
		for field in fields.slice(1):
			var v := int(field.split("/")[0])-1
			if not neighbors.has(v):
				neighbors[v] = []
			if not neighbors.has(first):
				neighbors[first] = []
			neighbors[v].append(first)
			neighbors[first].append(v)
	var selected := {}
	var queue: Array[int] = [seed_vertex]
	while not queue.is_empty():
		var v: int = queue.pop_back()
		if selected.has(v):
			continue
		selected[v] = true
		for neighbor in neighbors.get(v,[]):
			if not selected.has(neighbor):
				queue.append(neighbor)
	return selected

func mesh_from_obj(path: String, fit_path: String, deleted: Dictionary = {}, component_seed: int = -1) -> ArrayMesh:
	var selected_component := connected_vertices(path,component_seed) if component_seed >= 0 else {}
	var data := proxy_data(fit_path)
	if data.refs.size() != read_vertices(path).size():
		fail("Fitting table count does not match source geometry: "+path)
		return null
	var positions: Array[PackedVector3Array] = [fitted(data,body)]
	for variant in body_variants:
		positions.append(fitted(data,variant))
	var weight_map: Array = []
	for ref_data in data.refs:
		weight_map.append(weights_for(ref_data))
	var surfaces: Array[SurfaceTool] = []
	for i in positions.size():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_smooth_group(0)
		surfaces.append(st)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var corner_keys: Array[String] = []
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var fields := line.strip_edges().split(" ",false)
		if fields.is_empty():
			continue
		if fields[0] == "v" and fields.size() >= 4:
			vertices.append(Vector3(float(fields[1]),float(fields[2]),float(fields[3]))*.1)
		elif fields[0] == "vt" and fields.size() >= 3:
			uvs.append(Vector2(float(fields[1]),1.0-float(fields[2])))
		elif fields[0] == "f":
			if not selected_component.is_empty() and not selected_component.has(int(fields[1].split("/")[0])-1):
				continue
			# Source OBJ is counterclockwise; Godot uses clockwise front faces.
			for i in range(2,fields.size()-1):
				var hidden := not deleted.is_empty()
				for corner in [1,i+1,i]:
					var vi := int(fields[corner].split("/")[0])-1
					if vi < 0 or vi >= data.refs.size():
						fail("Invalid fitting vertex: "+path)
						return null
					for base_index in data.refs[vi].indices:
						if not deleted.has(base_index):
							hidden = false
				if hidden:
					continue
				for corner in [1,i+1,i]:
					var ref_parts := fields[corner].split("/")
					var vi := int(ref_parts[0])-1
					var ti := int(ref_parts[1])-1 if ref_parts.size()>1 and not ref_parts[1].is_empty() else -1
					if vi < 0 or vi >= vertices.size() or ti >= uvs.size():
						fail("Invalid source OBJ index: "+path)
						return null
					corner_keys.append(str(vi)+"/"+str(ti))
					for variant in positions.size():
						var surface := surfaces[variant]
						surface.set_uv(uvs[ti] if ti >= 0 else Vector2.ZERO)
						surface.set_bones(weight_map[vi][0])
						surface.set_weights(weight_map[vi][1])
						surface.add_vertex(positions[variant][vi])
	if vertices.is_empty():
		fail("Empty OBJ: "+path)
		return null
	var result := ArrayMesh.new()
	# Store full target normals, not tiny normal deltas that octahedral packing
	# normalizes and destroys. Normalized mode also supports additive controls.
	result.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	for shape_name in shape_names:
		result.add_blend_shape(shape_name)
	for surface in surfaces:
		surface.generate_normals()
	var arrays := surfaces[0].commit_to_arrays()
	var blend_arrays: Array[Array] = []
	for i in range(1,surfaces.size()):
		var shape := surfaces[i].commit_to_arrays()
		var blend := []
		blend.resize(Mesh.ARRAY_MAX)
		var points: PackedVector3Array = shape[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = shape[Mesh.ARRAY_NORMAL]
		blend[Mesh.ARRAY_VERTEX] = points
		blend[Mesh.ARRAY_NORMAL] = normals
		blend_arrays.append(blend)
	# A shared index map preserves exact correspondence across all shape targets.
	# Include every normal in the key so hard edges are never welded accidentally.
	var unique := {}
	var kept: Array[int] = []
	var indices := PackedInt32Array()
	for v in corner_keys.size():
		var key := corner_keys[v]+var_to_str(arrays[Mesh.ARRAY_NORMAL][v])
		for blend in blend_arrays:
			key += var_to_str(blend[Mesh.ARRAY_NORMAL][v])
		if not unique.has(key):
			unique[key] = kept.size()
			kept.append(v)
		indices.append(unique[key])
	for channel in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_BONES,Mesh.ARRAY_WEIGHTS]:
		var old: Variant = arrays[channel]
		var reduced: Variant = old.slice(0,0)
		var stride := 4 if channel in [Mesh.ARRAY_BONES,Mesh.ARRAY_WEIGHTS] else 1
		for v in kept:
			for component in stride:
				reduced.append(old[v*stride+component])
		arrays[channel] = reduced
	for blend in blend_arrays:
		for channel in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL]:
			var old: PackedVector3Array = blend[channel]
			var reduced := PackedVector3Array()
			for v in kept:
				reduced.append(old[v])
			blend[channel] = reduced
	arrays[Mesh.ARRAY_INDEX] = indices
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,blend_arrays)
	return result
func add_part(parent: Node3D, part_name: String, obj_path: String, material_path: String, deleted: Dictionary = {}, component_seed: int = -1, fitting_path: String = "") -> void:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var extension := ".proxy" if obj_path.begins_with("proxymeshes/") else ".mhclo"
	var fit_path := obj_path.get_basename()+extension if fitting_path.is_empty() else fitting_path
	instance.mesh = mesh_from_obj(source.path_join(obj_path),source.path_join(fit_path),deleted,component_seed)
	if instance.mesh == null:
		instance.free()
		return
	var source_material := material(source.path_join(material_path))
	instance.mesh.surface_set_material(0,source_material)
	if not source_material.get_meta("source_cast_shadows",true):
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	skeleton.add_child(instance)
	instance.owner = parent
	instance.skin = skin
	instance.skeleton = NodePath("..")

func cloak_drop(t: float, length: float) -> float:
	return .035*minf(t/.16,1.0)+maxf(0,t-.16)/.84*(length-.035)

func cloak_panel_present(row: int, column: int, rings: int, segments: int, length: float) -> bool:
	if row < 0 or row >= rings or column < 0 or column >= segments:
		return false
	var angle := lerpf(25,335,(float(column)+.5)/segments)
	var drop := cloak_drop((float(row)+.5)/rings,length)
	# Sewn side vents provide arm clearance; no skin polygons are hidden.
	var side := (angle > 55 and angle < 125) or (angle > 235 and angle < 305)
	return not (side and drop > .09 and drop < .45)

func add_cloak(parent: Node3D, part_name: String, sex: String, length: float) -> void:
	# Authored radial cloth pattern, not a replacement body mesh. Open front,
	# shoulder yoke and widening folded hem. Fit deltas use the existing proxy.
	var fit := proxy_data(source.path_join("proxymeshes/%s_generic/%s_generic.proxy" % [sex,sex]))
	var base_points := fitted(fit,body)
	var variants: Array[PackedVector3Array] = [base_points]
	for variant in body_variants:
		variants.append(fitted(fit,variant))
	var anchor := skeleton.get_bone_global_rest(skeleton.find_bone("neck02")).origin
	var rings := 18
	var segments := 48
	var pattern := PackedVector3Array()
	var nearest: Array[int] = []
	for row in rings+1:
		var t := float(row)/rings
		var shoulder := minf(t/.16,1.0)
		var width := lerpf(.080,.255,shoulder)+maxf(0,t-.16)*.12
		var depth := lerpf(.09,.155,shoulder)+maxf(0,t-.16)*.12
		for column in segments+1:
			var angle := lerpf(deg_to_rad(25),deg_to_rad(335),float(column)/segments)
			var fold := sin(angle*12.0)*.013*pow(t,.7)
			var drop := cloak_drop(t,length)
			var point := Vector3(sin(angle)*(width+fold),anchor.y-.018-drop,anchor.z+cos(angle)*(depth+fold)-.025*t)
			pattern.append(point)
			var best := 0
			var distance := INF
			for i in base_points.size():
				var candidate := point.distance_squared_to(base_points[i])
				if candidate < distance:
					distance = candidate
					best = i
			nearest.append(best)
	var generated: Array[Array] = []
	for variant in variants:
		var fitted_pattern := PackedVector3Array()
		for i in pattern.size():
			fitted_pattern.append(pattern[i]+variant[nearest[i]]-base_points[nearest[i]])
		var pattern_normals := PackedVector3Array()
		for row in rings+1:
			for column in segments+1:
				var across := fitted_pattern[row*(segments+1)+mini(column+1,segments)]-fitted_pattern[row*(segments+1)+maxi(column-1,0)]
				var down := fitted_pattern[mini(row+1,rings)*(segments+1)+column]-fitted_pattern[maxi(row-1,0)*(segments+1)+column]
				# Match Godot's clockwise front-face convention for this grid.
				pattern_normals.append(across.cross(down).normalized())
		var panels: Array[SurfaceTool] = []
		for panel in 2:
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			surface.set_smooth_group(0)
			panels.append(surface)
		for row in rings:
			for column in segments:
				if not cloak_panel_present(row,column,rings,segments,length):
					continue
				var border := false
				for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
					if not cloak_panel_present(row+offset.x,column+offset.y,rings,segments,length):
						border = true
				var surface := panels[1 if border else 0]
				var a := row*(segments+1)+column
				for index in [a,a+segments+1,a+1,a+1,a+segments+1,a+segments+2]:
					surface.set_uv(Vector2(float(index%(segments+1))/segments,float(index/(segments+1))/rings))
					# Drape follows upper torso. Cloth simulation/secondary bones are
					# intentionally not claimed by this static tailoring prototype.
					surface.set_bones(PackedInt32Array([skeleton.find_bone("spine01"),0,0,0]))
					surface.set_weights(PackedFloat32Array([1,0,0,0]))
					surface.set_normal(pattern_normals[index])
					surface.add_vertex(fitted_pattern[index])
		var panel_arrays := []
		for surface in panels:
			panel_arrays.append(surface.commit_to_arrays())
		generated.append(panel_arrays)
	var mesh := ArrayMesh.new()
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	for shape_name in shape_names:
		mesh.add_blend_shape(shape_name)
	for panel in 2:
		var shapes: Array[Array] = []
		for i in shape_names.size():
			var shape := []
			shape.resize(Mesh.ARRAY_MAX)
			shape[Mesh.ARRAY_VERTEX] = generated[i+1][panel][Mesh.ARRAY_VERTEX]
			shape[Mesh.ARRAY_NORMAL] = generated[i+1][panel][Mesh.ARRAY_NORMAL]
			shapes.append(shape)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,generated[0][panel],shapes)
		var cloth := StandardMaterial3D.new()
		cloth.albedo_color = Color("354d62") if panel == 0 else Color("c1a269")
		cloth.roughness = .95
		cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.surface_set_material(panel,cloth)
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.skin = skin
	instance.skeleton = NodePath("..")
	skeleton.add_child(instance)
	instance.owner = parent

func make_rig(parent: Node3D) -> void:
	var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(core.path_join("rigs/default.mhskel")))
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	parent.add_child(skeleton)
	skeleton.owner = parent
	var heads := {}
	for bone in definition.bones:
		var point := Vector3.ZERO
		var refs: Array = definition.joints[definition.bones[bone].head]
		for index in refs:
			point += body[index]*.1
		heads[bone] = point/refs.size()
		skeleton.add_bone(bone)
	skin = Skin.new()
	for bone in definition.bones:
		var index := skeleton.find_bone(bone)
		var parent_name: Variant = definition.bones[bone].parent
		var origin: Vector3 = heads[bone]
		if parent_name != null:
			skeleton.set_bone_parent(index,skeleton.find_bone(parent_name))
			origin -= heads[parent_name]
		skeleton.set_bone_rest(index,Transform3D(Basis.IDENTITY,origin))
		skin.add_bind(index,Transform3D(Basis.IDENTITY,-heads[bone]))
	skeleton.reset_bone_poses()
	vertex_weights.clear()
	for i in body.size():
		vertex_weights.append({})
	var weights: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(core.path_join("rigs/default_weights.mhw"))).weights
	for bone in weights:
		var index := skeleton.find_bone(bone)
		if index < 0:
			fail("Unknown source weight bone")
			continue
		for pair in weights[bone]:
			vertex_weights[int(pair[0])][index] = float(pair[1])
func body_height_samples(sex: String) -> Dictionary:
	var fit := proxy_data(source.path_join("proxymeshes/%s_generic/%s_generic.proxy" % [sex,sex]))
	var positions: Array[PackedVector3Array] = [fitted(fit,body)]
	for variant in body_variants:
		positions.append(fitted(fit,variant))
	var rows := []
	var intervals := []
	var least_upper := INF
	var greatest_lower := -INF
	for i in positions[0].size():
		var y := positions[0][i].y
		var row := [y]
		var lower := y
		var upper := y
		for variant in positions.slice(1):
			var delta: float = variant[i].y-y
			row.append(delta)
			lower += minf(0,delta)
			upper += maxf(0,delta)
		rows.append(row)
		intervals.append(Vector2(lower,upper))
		least_upper = minf(least_upper,upper)
		greatest_lower = maxf(greatest_lower,lower)
	# Retain every vertex that could be either vertical extreme for any set
	# of independent 0..1 morph weights. Other vertices cannot set stature.
	var samples := []
	for i in rows.size():
		if intervals[i].x <= least_upper or intervals[i].y >= greatest_lower:
			samples.append(rows[i])
	for variant in positions.size():
		var full := Vector2(INF,-INF)
		var reduced := Vector2(INF,-INF)
		for point in positions[variant]:
			full.x = minf(full.x,point.y)
			full.y = maxf(full.y,point.y)
		for row in samples:
			var y: float = row[0]+(row[variant] if variant > 0 else 0.0)
			reduced.x = minf(reduced.x,y)
			reduced.y = maxf(reduced.y,y)
		if full.distance_to(reduced) > .000001:
			fail("Reduced body measurement lost a source extreme")
	print("Verified ",sex," rest-height envelope: ",samples.size()," of ",rows.size()," source vertices retained.")
	return {"kind":"rest-body-height-envelope","morphs":shape_names,"samples":samples}

func build(sex: String) -> void:
	body = add_target(read_vertices(core.path_join("base.obj")),core.path_join("targets/macrodetails/caucasian-"+sex+"-young.target"))
	body_variants = [add_target(body,core.path_join("targets/macrodetails/universal-"+sex+"-young-averagemuscle-minweight.target")),add_target(body,core.path_join("targets/macrodetails/universal-"+sex+"-young-maxmuscle-averageweight.target"))]
	for control in FACE_TARGETS:
		var variant := body.duplicate()
		for target in FACE_TARGETS[control]:
			variant = add_target(variant,core.path_join("targets/"+target))
		body_variants.append(variant)
	var character := Node3D.new()
	character.name = "Character"
	root.add_child(character)
	make_rig(character)
	for number in ["01","02"]:
		var outfit_name: String = sex+"_casualsuit"+number
		var deleted: Dictionary = proxy_data(source.path_join("clothes/%s/%s.mhclo" % [outfit_name,outfit_name])).delete
		deleted.merge(proxy_data(source.path_join("clothes/shoes01/shoes01.mhclo")).delete)
		add_part(character,"Body"+number,"proxymeshes/%s_generic/%s_generic.obj" % [sex,sex],"skins/young_caucasian_%s/young_caucasian_%s.mhmat" % [sex,sex],deleted)
		add_part(character,"Outfit"+number,"clothes/%s/%s.obj" % [outfit_name,outfit_name],"clothes/%s/%s.mhmat" % [outfit_name,outfit_name])
	var hair_name := "ponytail01" if sex == "female" else "short01"
	var formal: String = sex+"_elegantsuit01"
	var formal_path := "clothes/"+formal+"/"+formal
	var top_seed := 430 if sex == "female" else 7262
	var bottom_seed := 240 if sex == "female" else 309
	var top_vertices := connected_vertices(source.path_join(formal_path+".obj"),top_seed)
	var bottom_vertices := connected_vertices(source.path_join(formal_path+".obj"),bottom_seed)
	if top_vertices.has(bottom_seed) or top_vertices.size()+bottom_vertices.size() != read_vertices(source.path_join(formal_path+".obj")).size():
		fail("Formal clothing components do not partition the source mesh")
	var formal_mask: Dictionary = proxy_data(source.path_join(formal_path+".mhclo")).delete
	formal_mask.merge(proxy_data(source.path_join("clothes/shoes01/shoes01.mhclo")).delete)
	add_part(character,"Body03","proxymeshes/%s_generic/%s_generic.obj" % [sex,sex],"skins/young_caucasian_%s/young_caucasian_%s.mhmat" % [sex,sex],formal_mask)
	# Seeds identify disconnected, inspected components of the pinned source OBJ.
	add_part(character,"FormalTop",formal_path+".obj",formal_path+".mhmat",{},top_seed)
	add_part(character,"FormalBottom",formal_path+".obj",formal_path+".mhmat",{},bottom_seed)
	add_part(character,"Hat","clothes/fedora01/fedora.obj","clothes/fedora01/fedora.mhmat",{},-1,"clothes/fedora01/fedora01.mhclo")
	add_part(character,"Hair","hair/%s/%s.obj" % [hair_name,hair_name],"hair/%s/%s.mhmat" % [hair_name,hair_name])
	add_part(character,"Eyes","eyes/low-poly/low-poly.obj","eyes/materials/brown.mhmat")
	for number in ["001","005"]:
		var brow_path: String = "eyebrows/eyebrow"+number+"/eyebrow"+number
		add_part(character,"Brows"+number,brow_path+".obj",brow_path+".mhmat")
	for number in ["01","04"]:
		var lash_path: String = "eyelashes/eyelashes"+number+"/eyelashes"+number
		add_part(character,"Lashes"+number,lash_path+".obj",lash_path+".mhmat")
	add_part(character,"Shoes","clothes/shoes01/shoes01.obj","clothes/shoes01/shoes01.mhmat")
	add_cloak(character,"ShortCloak",sex,.52)
	add_cloak(character,"LongCloak",sex,1.05)
	if failure:
		character.free()
		return
	# Source meshes retain one common authoring space; do not center parts separately.
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var model_path := destination.path_join(sex+"-source.glb")
	if document.append_from_scene(character,state) != OK or document.write_to_filesystem(state,model_path) != OK:
		fail("Could not export source assembly")
		character.free()
		return
	var profile := {"schemaVersion":1,"sourceSha256":FileAccess.get_sha256(model_path),
		"slots":{"Clothes":{"Casual 01":{"meshes":["Skeleton3D/Outfit01","Skeleton3D/Body01"],"hides":[]},"Casual 02":{"meshes":["Skeleton3D/Outfit02","Skeleton3D/Body02"],"hides":[]}}},
		"morphs":{"Lean":[],"Muscular":[]},"dyes":{"Clothing":[{"mesh":"Skeleton3D/Outfit01","surface":0},{"mesh":"Skeleton3D/Outfit02","surface":0}],"Hair":[{"mesh":"Skeleton3D/Hair","surface":0}]}}
	profile.slots.Clothes["Formal separates"] = {"meshes":["Skeleton3D/Body03","Skeleton3D/FormalTop","Skeleton3D/FormalBottom"],"hides":[]}
	profile.slots.Headwear = {"Bare head":{"meshes":[],"hides":[]},"Felt hat":{"meshes":["Skeleton3D/Hat"],"hides":["Skeleton3D/Hair"]}}
	profile.dyes["Formal top"] = [{"mesh":"Skeleton3D/FormalTop","surface":0}]
	profile.dyes["Formal bottom"] = [{"mesh":"Skeleton3D/FormalBottom","surface":0}]
	profile.dyes.Hat = [{"mesh":"Skeleton3D/Hat","surface":0}]
	profile.slots.Outerwear = {"No cloak":{"meshes":[],"hides":[]},"Short travelling cloak":{"meshes":["Skeleton3D/ShortCloak"],"hides":[]},"Long travelling cloak":{"meshes":["Skeleton3D/LongCloak"],"hides":[]}}
	profile.dyes.Cloak = [{"mesh":"Skeleton3D/ShortCloak","surface":0},{"mesh":"Skeleton3D/LongCloak","surface":0}]
	profile.dyes["Cloak border"] = [{"mesh":"Skeleton3D/ShortCloak","surface":1},{"mesh":"Skeleton3D/LongCloak","surface":1}]
	profile.slots.Eyebrows = {"Brow 01":{"meshes":["Skeleton3D/Brows001"],"hides":[]},"Brow 05":{"meshes":["Skeleton3D/Brows005"],"hides":[]},"No eyebrows":{"meshes":[],"hides":[]}}
	profile.slots.Eyelashes = {"Lashes 01":{"meshes":["Skeleton3D/Lashes01"],"hides":[]},"Lashes 04":{"meshes":["Skeleton3D/Lashes04"],"hides":[]},"No eyelashes":{"meshes":[],"hides":[]}}
	profile.dyes.Eyebrows = [{"mesh":"Skeleton3D/Brows001","surface":0},{"mesh":"Skeleton3D/Brows005","surface":0}]
	profile.dyes.Eyelashes = [{"mesh":"Skeleton3D/Lashes01","surface":0},{"mesh":"Skeleton3D/Lashes04","surface":0}]
	profile.measurement = body_height_samples(sex)
	profile.variationCaps = {"Defined cheekbones":.22,"Full cheeks":.35,"Larger eyes":.5,"Broad jaw":.55}
	profile.variationChoices = {"Eyebrows":["Brow 01","Brow 05"],"Eyelashes":["Lashes 01","Lashes 04"]}
	profile.shadowlessMeshes = []
	for mesh in skeleton.get_children():
		if mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			profile.shadowlessMeshes.append("Skeleton3D/"+str(mesh.name))
	for shape in shape_names:
		profile.morphs[shape] = []
	for mesh in skeleton.get_children():
		for shape in shape_names:
			profile.morphs[shape].append("Skeleton3D/"+str(mesh.name)+"::"+shape)
	var file := FileAccess.open(destination.path_join(sex+"-profile.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(profile,"  ",true,true))
	file.close()
	print("Prepared ",sex," fitted source geometry, ",skeleton.get_bone_count()," bones and ",shape_names.size()," linked morphology targets.")
	character.free()
func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		quit(2)
		return
	source = args[0]
	core = source.get_base_dir().path_join("makehuman-core")
	destination = args[1]
	if not source.is_absolute_path() or not destination.is_absolute_path():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(destination)
	for sex in ["female","male"]:
		build(sex)
	if not failure:
		var records := []
		for sex in ["female","male"]:
			for suffix in ["-source.glb","-profile.json"]:
				var filename: String = sex+suffix
				records.append({"path":filename,"sha256":FileAccess.get_sha256(destination.path_join(filename))})
		var receipt := {"schemaVersion":1,"status":"development-source-assembly-not-approved-game-art",
			"license":"CC0-1.0","engine":Engine.get_version_info().string,
			"compilerSha256":FileAccess.get_sha256("res://prepare-character-model.gd"),
			"systemManifestSha256":FileAccess.get_sha256(source.path_join("source-manifest.json")),
			"coreManifestSha256":FileAccess.get_sha256(core.path_join("source-manifest.json")),
			"textureMaxDimension":1024,"bones":163,"linkedMorphs":shape_names,"files":records,
			"limitations":["Global-axis rest frames, not source bone-roll conventions","Modern sample wardrobe, not period art","Not a complete character builder or production crowd asset"]}
		var receipt_file := FileAccess.open(destination.path_join("build-receipt.json"),FileAccess.WRITE)
		if receipt_file == null:
			fail("Cannot write build receipt")
		else:
			receipt_file.store_string(JSON.stringify(receipt,"  ",true,true))
			receipt_file.close()
	quit(1 if failure else 0)
