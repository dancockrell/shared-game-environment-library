extends SceneTree
## Offline conversion of inspected source geometry; no invented anatomy or rig.
var source := ""
var destination := ""
var failure := false
var core := ""
var body := PackedVector3Array()
var body_variants: Array[PackedVector3Array] = []
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
		if fields[0] == "transparent" and fields.size() == 2 and fields[1] == "True":
			result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			result.alpha_scissor_threshold = .3
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

func mesh_from_obj(path: String, fit_path: String, deleted: Dictionary = {}) -> ArrayMesh:
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
	result.add_blend_shape("Lean")
	result.add_blend_shape("Muscular")
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
func add_part(parent: Node3D, part_name: String, obj_path: String, material_path: String, deleted: Dictionary = {}) -> void:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var extension := ".proxy" if obj_path.begins_with("proxymeshes/") else ".mhclo"
	instance.mesh = mesh_from_obj(source.path_join(obj_path),source.path_join(obj_path.get_basename()+extension),deleted)
	if instance.mesh == null:
		instance.free()
		return
	instance.mesh.surface_set_material(0,material(source.path_join(material_path)))
	skeleton.add_child(instance)
	instance.owner = parent
	instance.skin = skin
	instance.skeleton = NodePath("..")

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
func build(sex: String) -> void:
	body = add_target(read_vertices(core.path_join("base.obj")),core.path_join("targets/macrodetails/caucasian-"+sex+"-young.target"))
	body_variants = [add_target(body,core.path_join("targets/macrodetails/universal-"+sex+"-young-averagemuscle-minweight.target")),add_target(body,core.path_join("targets/macrodetails/universal-"+sex+"-young-maxmuscle-averageweight.target"))]
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
	add_part(character,"Hair","hair/%s/%s.obj" % [hair_name,hair_name],"hair/%s/%s.mhmat" % [hair_name,hair_name])
	add_part(character,"Eyes","eyes/low-poly/low-poly.obj","eyes/materials/brown.mhmat")
	add_part(character,"Shoes","clothes/shoes01/shoes01.obj","clothes/shoes01/shoes01.mhmat")
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
	for mesh in skeleton.get_children():
		for shape in ["Lean","Muscular"]:
			profile.morphs[shape].append("Skeleton3D/"+str(mesh.name)+"::"+shape)
	var file := FileAccess.open(destination.path_join(sex+"-profile.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(profile,"  ",true,true))
	file.close()
	print("Prepared ",sex," fitted source geometry, ",skeleton.get_bone_count()," bones and 2 linked morphology targets.")
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
			"textureMaxDimension":1024,"bones":163,"linkedMorphs":["Lean","Muscular"],"files":records,
			"limitations":["Global-axis rest frames, not source bone-roll conventions","Modern sample wardrobe, not period art","Not a complete character builder or production crowd asset"]}
		var receipt_file := FileAccess.open(destination.path_join("build-receipt.json"),FileAccess.WRITE)
		if receipt_file == null:
			fail("Cannot write build receipt")
		else:
			receipt_file.store_string(JSON.stringify(receipt,"  ",true,true))
			receipt_file.close()
	quit(1 if failure else 0)
