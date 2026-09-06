extends RefCounted
## Original deterministic tiled weave. No photographs, paid generation or source edits.
## Material study, not a measured textile or a replacement for proper garment cuts.

static func thread_variation(index: int, seed_value: int) -> float:
	var mixed := posmod(index*7919+seed_value*104729,65521)
	return .94+.12*float(mixed)/65520.0

static func height_at(x: float, y: float, threads: int, seed_value: int) -> float:
	var u := fposmod(x,1.0)*threads
	var v := fposmod(y,1.0)*threads
	var column := int(floor(u))
	var row := int(floor(v))
	var cross_u := (fposmod(u,1.0)-.5)/.48
	var cross_v := (fposmod(v,1.0)-.5)/.48
	var warp := sqrt(maxf(0,1-cross_u*cross_u))*thread_variation(column,seed_value)
	var weft := sqrt(maxf(0,1-cross_v*cross_v))*thread_variation(row,seed_value+31)
	# Smooth alternating over/under crossings; thread profiles vanish at cell edges.
	warp *= .60+.25*cos(PI*(v-.5))*cos(PI*column)
	weft *= .60-.25*cos(PI*(u-.5))*cos(PI*row)
	return maxf(warp,weft)

static func generate(size: int = 512, threads: int = 64, seed_value: int = 17) -> Dictionary:
	if size < 64 or size > 2048 or threads < 4 or threads % 2 != 0 or threads > size/4:
		return {"error":"Require 64..2048 pixels, even thread count and at least four pixels per thread."}
	var heights := PackedFloat32Array()
	heights.resize(size*size)
	for y in size:
		for x in size:
			heights[y*size+x] = height_at((x+.5)/size,(y+.5)/size,threads,seed_value)
	var albedo := Image.create(size,size,false,Image.FORMAT_RGB8)
	var normal := Image.create(size,size,false,Image.FORMAT_RGB8)
	var roughness := Image.create(size,size,false,Image.FORMAT_L8)
	# Relative relief versus a thread width; artist parameter, not physical calibration.
	var slope_scale := float(size)/threads*.18
	for y in size:
		for x in size:
			var h := heights[y*size+x]
			var dx := (heights[y*size+posmod(x+1,size)]-heights[y*size+posmod(x-1,size)])*slope_scale
			var dy := (heights[posmod(y+1,size)*size+x]-heights[posmod(y-1,size)*size+x])*slope_scale
			var n := Vector3(-dx,-dy,1).normalized()
			normal.set_pixel(x,y,Color(n.x*.5+.5,n.y*.5+.5,n.z*.5+.5))
			var shade := .90+.10*h
			albedo.set_pixel(x,y,Color(shade,shade,shade))
			var rough := .89+.07*(1-h)
			roughness.set_pixel(x,y,Color(rough,rough,rough))
	return {"error":"","albedo":albedo,"normal":normal,"roughness":roughness,"threads":threads,"seed":seed_value,"status":"procedural-weave-material-study"}

static func material(maps: Dictionary, color: Color, repeats: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 1.0
	result.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not maps.get("error", "Missing maps").is_empty():
		return result
	if not maps.has("_textures"):
		maps._textures = {}
	for channel in ["albedo","normal","roughness"]:
		if not maps._textures.has(channel):
			var image: Image = maps[channel].duplicate()
			image.generate_mipmaps(channel == "normal")
			maps._textures[channel] = ImageTexture.create_from_image(image)
		var texture: ImageTexture = maps._textures[channel]
		if channel == "albedo":
			result.albedo_texture = texture
		elif channel == "normal":
			result.normal_enabled = true
			result.normal_texture = texture
		else:
			result.roughness_texture = texture
			result.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	result.uv1_scale = Vector3(repeats,repeats,1)
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return result
