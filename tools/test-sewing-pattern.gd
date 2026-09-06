extends SceneTree
const Sewing = preload("res://sewing-pattern.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:
		failures += 1

func _init() -> void:
	var pattern := {"schemaVersion":1,"units":"metres","panels":[
		{"id":"left","boundary":[[0,0],[.3,0],[.3,.4],[0,.4]],"origin":[0,0,0],"u":[1,0,0],"v":[0,1,0]},
		{"id":"right","boundary":[[0,0],[.3,0],[.3,.4],[0,.4]],"origin":[.4,0,0],"u":[1,0,0],"v":[0,1,0]}],
		"stitches":[{"a":["left",1],"b":["right",3],"reverse":true}]}
	var before := JSON.stringify(pattern)
	var compiled: Dictionary = Sewing.compile(pattern,2)
	check(compiled.error.is_empty(),"compile two independently placed fabric panels")
	if not compiled.error.is_empty():
		printerr(compiled.error)
		quit(1)
		return
	check(compiled.positions.size() == 50 and compiled.triangles.size() == 192,"conforming shared-midpoint refinement")
	check(compiled.panels.left.edges[1].size() == 5,"refinement preserves named edge samples")
	check(compiled.fabric.size() == compiled.positions.size(),"each vertex retains metric fabric coordinates")
	var area := 0.0
	for i in range(0,compiled.triangles.size(),3):
		var a: Vector2 = compiled.fabric[compiled.triangles[i]]
		var b: Vector2 = compiled.fabric[compiled.triangles[i+1]]
		var c: Vector2 = compiled.fabric[compiled.triangles[i+2]]
		area += absf((b-a).cross(c-a))*.5
	check(is_equal_approx(area,.24),"triangulation conserves cut fabric area")
	var initial: PackedVector3Array = compiled.positions.duplicate()
	var sewn: Dictionary = Sewing.relax(compiled,500)
	check(sewn.error.is_empty() and sewn.maxSeamGapMetres < .0001,"sewing closes the initial 100 mm gap to below 0.1 mm")
	check(sewn.maxRelativeEdgeStretch < .001,"sewn coupon edge strain remains below 0.1 percent")
	check(compiled.positions == initial and JSON.stringify(pattern) == before,"solve preserves editable pattern and initial placement")
	var repeated: Dictionary = Sewing.relax(Sewing.compile(pattern,2),500)
	check(repeated.positions == sewn.positions,"sewing is deterministic for identical inputs")
	var mesh: ArrayMesh = Sewing.build_mesh(compiled,sewn.positions)
	check(mesh != null and mesh.get_surface_count() == 2,"cut panels produce separate renderable mesh surfaces")
	var mesh_valid := true
	var max_position_error := 0.0
	var max_uv_error := 0.0
	var max_normal_error := 0.0
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var offset: int = compiled.panels[mesh.surface_get_name(surface)].vertexStart
		for vertex in arrays[Mesh.ARRAY_VERTEX].size():
			max_position_error = maxf(max_position_error,arrays[Mesh.ARRAY_VERTEX][vertex].distance_to(sewn.positions[offset+vertex]))
			max_uv_error = maxf(max_uv_error,arrays[Mesh.ARRAY_TEX_UV][vertex].distance_to(compiled.fabric[offset+vertex]))
			max_normal_error = maxf(max_normal_error,arrays[Mesh.ARRAY_NORMAL][vertex].distance_to(Vector3.BACK))
		mesh_valid = mesh_valid and arrays[Mesh.ARRAY_TANGENT].size() == arrays[Mesh.ARRAY_VERTEX].size()*4
	print("Mesh errors: position=",max_position_error," UV=",max_uv_error," normal=",max_normal_error)
	check(mesh_valid and max_position_error < .000001 and max_uv_error < .000001 and max_normal_error < .0001,"mesh preserves sewn positions, metric fabric UVs, outward normals and tangents (normal packing tolerance)")
	var concave := pattern.duplicate(true)
	concave.panels.resize(1)
	concave.stitches = []
	concave.panels[0].boundary = [[0,0],[.3,0],[.3,.2],[.15,.2],[.15,.4],[0,.4]]
	check(Sewing.compile(concave,3).error.is_empty(),"concave cut pattern refines without missing boundary samples")
	concave.panels[0].boundary.reverse()
	check(Sewing.compile(concave,3).error.is_empty(),"reversed input winding also triangulates and refines")
	var analytic := {"error":"","positions":PackedVector3Array([Vector3.ZERO,Vector3(2,0,0)]),"inverse_mass":PackedFloat32Array([0,1]),"constraints":[{"a":0,"b":1,"rest":1.0,"kind":"stretch"}]}
	var one: Dictionary = Sewing.relax(analytic,1,.01,.1)
	var many: Dictionary = Sewing.relax(analytic,40,.01,.1)
	check(one.positions[0] == Vector3.ZERO and is_equal_approx(one.positions[1].x,1.5),"XPBD matches independent single-constraint closed form and respects pin")
	check(one.positions == many.positions,"compliance is not re-stiffened by repeated multiplier reset")
	check(not Sewing.relax(analytic,0).error.is_empty() and not Sewing.relax(analytic,1,-1).error.is_empty(),"invalid solver settings reject")
	check(not Sewing.relax({"error":""}).error.is_empty(),"missing compiled arrays reject without a runtime exception")
	var corrupt := analytic.duplicate(true)
	corrupt.constraints[0].a = 100
	check(not Sewing.relax(corrupt).error.is_empty(),"out-of-range constraint indices reject")
	corrupt = analytic.duplicate(true)
	corrupt.positions[0] = Vector3(NAN,0,0)
	check(not Sewing.relax(corrupt).error.is_empty(),"nonfinite solver positions reject")
	for invalid in [null,{}, {"schemaVersion":1,"units":"centimetres","panels":[]}]:
		check(not Sewing.compile(invalid).error.is_empty(),"invalid pattern contract rejects")
	var invalid: Dictionary = pattern.duplicate(true)
	invalid.panels[1].id = "left"
	check(not Sewing.compile(invalid).error.is_empty(),"duplicate panel IDs reject")
	invalid = pattern.duplicate(true)
	invalid.panels[0].u = [2,0,0]
	check(not Sewing.compile(invalid).error.is_empty(),"placement cannot stretch the cutting pattern")
	invalid = pattern.duplicate(true)
	invalid.panels[0].boundary = [[0,0],[1,1],[0,1],[1,0]]
	check(not Sewing.compile(invalid).error.is_empty(),"crossed boundaries reject")
	invalid = pattern.duplicate(true)
	invalid.panels[0].boundary = [[0,0],[.1,0],[.3,0],[.3,.4],[0,.4]]
	check(not Sewing.compile(invalid).error.is_empty(),"redundant collinear corners reject before refinement")
	invalid = pattern.duplicate(true)
	invalid.stitches[0].a[1] = .5
	check(not Sewing.compile(invalid).error.is_empty(),"fractional seam edge indices reject")
	invalid = pattern.duplicate(true)
	invalid.stitches.append(invalid.stitches[0].duplicate(true))
	check(not Sewing.compile(invalid).error.is_empty(),"an edge cannot be stitched twice")
	var args := OS.get_cmdline_user_args()
	if args.size() == 1:
		var mesh_path := args[0]+".res"
		check(ResourceSaver.save(mesh,mesh_path) == OK,"save actual sewn mesh")
		var reloaded := ResourceLoader.load(mesh_path,"ArrayMesh",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
		check(reloaded != null and reloaded.get_surface_count() == 2,"fresh sewn mesh reload retains both panels")
		var report := {"schemaVersion":1,"status":"sewing-coupon-not-garment-art","vertices":compiled.positions.size(),"triangles":compiled.triangles.size()/3,"maxSeamGapMetres":sewn.maxSeamGapMetres,"maxRelativeEdgeStretch":sewn.maxRelativeEdgeStretch,"bodyPenetration":null,"selfIntersections":null,"pattern":pattern,"solverSha256":FileAccess.get_sha256("res://sewing-pattern.gd")}
		var output := FileAccess.open(args[0]+".json",FileAccess.WRITE)
		check(output != null,"create sewing evidence receipt")
		if output != null:
			output.store_string(JSON.stringify(report,"  ",true,true))
			output.close()
	print("Sewing failures: ",failures)
	print("Sewing metrics: gap=",sewn.maxSeamGapMetres," m; relative edge stretch=",sewn.maxRelativeEdgeStretch)
	quit(1 if failures else 0)
