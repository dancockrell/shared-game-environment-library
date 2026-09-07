"""Reproducible look-development study on the canonical workshop's fitted GLB.
Does not generate anatomy or clothing topology; hardware is static review geometry.
"""
import hashlib
import json
import sys
import struct
from pathlib import Path
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.geometry import barycentric_transform


def attach_groom_audit(source, destination):
    """Bind guide and growth coordinates together; test actual evaluated strands."""
    from mathutils import Matrix
    destination.mkdir(parents=True, exist_ok=False)
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(source))
    groom = bpy.data.objects['cyberpunk hair']
    scalp = bpy.data.objects['cyber punk growth mesh']
    rigs = {m.object for m in bpy.data.objects['Eyes'].modifiers if m.type == 'ARMATURE'}
    assert len(rigs) == 1
    rig = next(iter(rigs))
    bone = rig.pose.bones['head']
    def points():
        bpy.context.view_layer.update()
        obj = groom.evaluated_get(bpy.context.evaluated_depsgraph_get())
        assert len(obj.data.points) < 500000
        return [obj.matrix_world @ p.position for p in obj.data.points]
    baseline = points()
    # Both guide and scalp coordinates move rigidly together in this study.
    # Surface deformation is reserved for actual scalp-shape changes.
    groom.modifiers['Surface Deform'].show_viewport = False
    groom.modifiers['Surface Deform'].show_render = False
    anchor = bpy.data.objects.new('Study_groom_head_attachment', None)
    bpy.context.scene.collection.objects.link(anchor)
    follow = anchor.constraints.new('COPY_TRANSFORMS')
    follow.target, follow.subtarget = rig, bone.name
    bpy.context.view_layer.update()
    for obj in (groom, scalp):
        original = obj.matrix_world.copy()
        obj.parent = anchor
        obj.matrix_parent_inverse = anchor.matrix_world.inverted()
        obj.matrix_world = original
    bound = points()
    assert len(bound) == len(baseline)
    bind_error = max((a-b).length for a,b in zip(bound, baseline))
    rest_head = rig.matrix_world @ bone.matrix
    saved = bone.matrix_basis.copy()
    tests = []
    try:
        for axis, angle in [('X',.3), ('X',-.3), ('Y',.3), ('Z',.4), ('Z',-.4)]:
            bone.matrix_basis = saved @ Matrix.Rotation(angle,4,axis)
            actual = points()
            assert len(actual) == len(bound), 'Pose changed groom topology'
            transform = rig.matrix_world @ bone.matrix @ rest_head.inverted()
            error = max((a-transform@b).length for a,b in zip(actual,bound))
            tests.append({'axis':axis,'radians':angle,'maximum_error_m':error})
    finally:
        bone.matrix_basis = saved
        bpy.context.view_layer.update()
    worst = max([bind_error]+[t['maximum_error_m'] for t in tests])
    receipt = {'source_sha256':digest,'points':len(bound),'binding_error_m':bind_error,
        'poses':tests,'maximum_error_m':worst,'threshold_m':.00005,
        'passed':worst <= .00005,'attachment':'shared head-bone transform for guides and growth mesh',
        'limitations':['rigid hair only; no secondary motion','scalp fit and collision unvalidated',
                        'Blender-only; no game export','source CC-BY-SA; research only']}
    assert hashlib.sha256(source.read_bytes()).hexdigest() == digest
    (destination/'attachment-audit.json').write_text(json.dumps(receipt,indent=2))
    assert receipt['passed'], 'Groom attachment rigid-motion gate failed'
    bpy.ops.wm.save_as_mainfile(filepath=str(destination/'attached-groom.blend'))
    print('GROOM_ATTACHMENT_PASS', worst)


def append_demo_groom():
    """Quarantined CC-BY-SA author groom; never an admitted CC0 catalog asset."""
    from mathutils import Matrix
    source = Path(__file__).resolve().parents[1]/'generated/reviews/hair_nodes-female_hair_styles.blend'
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    assert digest == '1ad6202095c1793678fee7d69a7e9f8b5fdb6e5c293d300eb1062d2d437e8d48'
    with bpy.data.libraries.load(str(source)) as (_,data):
        data.objects = ['cyberpunk hair','cyber punk growth mesh','eyes']
    groom,scalp,donor_eyes = data.objects
    assert groom.type == 'CURVES' and groom.data.surface == scalp
    donor_matrix = Matrix.LocRotScale(donor_eyes.location,
        donor_eyes.rotation_euler.to_quaternion(),donor_eyes.scale)
    donor_center = sum((donor_matrix@v.co for v in donor_eyes.data.vertices),Vector())/len(donor_eyes.data.vertices)
    target = bpy.data.objects['Eyes']
    target_center = sum((target.matrix_world@v.co for v in target.data.vertices),Vector())/len(target.data.vertices)
    scale = .1  # Author demo's decimetre-scale head; align paired eye centres.
    fit = Matrix.Translation(target_center-scale*donor_center)@Matrix.Scale(scale,4)
    scalp.data.calc_loop_triangles()
    area = sum((scalp.data.vertices[t.vertices[1]].co-scalp.data.vertices[t.vertices[0]].co).cross(
        scalp.data.vertices[t.vertices[2]].co-scalp.data.vertices[t.vertices[0]].co).length/2
        for t in scalp.data.loop_triangles)
    interpolation = groom.modifiers['Interpolate Hair Curves']
    density_before = interpolation['Input_15']
    interpolation['Input_15'] = 20000/area
    for obj in (groom,scalp):
        obj.parent = None
        obj.matrix_world = fit
        bpy.context.scene.collection.objects.link(obj)
    scalp.hide_render = True
    old = bpy.data.objects['Hair_braid01']
    old.hide_render = True
    old.hide_set(True)
    bpy.context.view_layer.update()
    evaluated = groom.evaluated_get(bpy.context.evaluated_depsgraph_get())
    count,points = len(evaluated.data.curves),len(evaluated.data.points)
    assert 1000<count<40000 and points<500000, 'Author groom exceeded study geometry bound'
    return {'experiment':'author guide-based cyberpunk groom, fit study only',
        'author':'Daniel Bystedt','license':'CC-BY-SA (official demo listing)',
        'source_url':'https://download.blender.org/demo/geometry-nodes/hair_nodes-female_hair_styles.blend',
        'source_sha256':digest,'source_guides':len(groom.data.curves),
        'evaluated_curves':count,'evaluated_points':points,
        'density_before':density_before,'density_after':interpolation['Input_15'],
        'fit_matrix':[list(row) for row in fit],
        'limitations':['not admitted to CC0 catalog','approximate head fit, no scalp collision certification',
            'not attached to character rig','no game export validation']}


def construct_surface_strands(destination):
    """Confidence-gated texture streamlines on the existing upper hair surface."""
    sys.path.insert(0,str(Path(__file__).parent))
    from hair_field import direction_field,trace_line
    import numpy as np
    hair = bpy.data.objects['Hair_braid01']
    e = hair.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = e.to_mesh()
    mesh.calc_loop_triangles()
    world = [e.matrix_world@v.co for v in mesh.vertices]
    uv = mesh.uv_layers.active.data
    eye = bpy.data.objects['Eyes']
    min_z = sum((eye.matrix_world@v.co).z for v in eye.data.vertices)/len(eye.data.vertices)+.025
    triangles = [t for t in mesh.loop_triangles if min(world[i].z for i in t.vertices)>min_z]
    atlas,faces,spatial,normals = [],[],[],[]
    normal_transform = e.matrix_world.to_3x3().inverted().transposed()
    for t in triangles:
        offset = len(atlas)
        atlas.extend(Vector((*uv[i].uv,0)) for i in t.loops)
        faces.append((offset,offset+1,offset+2))
        spatial.append([world[i].copy() for i in t.vertices])
        normals.append([(normal_transform@mesh.vertices[i].normal).normalized() for i in t.vertices])
    e.to_mesh_clear()
    tree = BVHTree.FromPolygons(atlas,faces,all_triangles=True)
    image = next(n.image for n in hair.data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE')
    width,height = image.size
    pixels = np.array(image.pixels[:],dtype=np.float32).reshape(height,width,4)
    field,confidence = direction_field(pixels[:,:,:3] @ np.array([.2126,.7152,.0722]))
    rng = np.random.default_rng(23)
    strands,uv_strands = [],[]
    for _ in range(768):
        f = faces[int(rng.integers(len(faces)))]
        b = rng.dirichlet([1,1,1])
        seed = sum((atlas[i]*float(w) for i,w in zip(f,b)),Vector())
        line = trace_line(field,confidence,(seed.x*width,seed.y*height))
        points,retained_uv = [],[]
        for x,y in line:
            point = Vector((x/width,y/height,0))
            hit,_,index,distance = tree.find_nearest(point,.000001)
            if hit is None:
                break
            tri = spatial[index]
            pos = barycentric_transform(hit,*(atlas[i] for i in faces[index]),*tri)
            normal = barycentric_transform(hit,*(atlas[i] for i in faces[index]),
                                           *normals[index]).normalized()
            pos += normal*.0003
            if points and (pos-points[-1]).length>.003:
                break
            points.append(pos)
            retained_uv.append((x/width,y/height))
        if len(points)>=12:
            strands.append(points)
            uv_strands.append(retained_uv)
    assert 0<len(strands)<=768
    curves = bpy.data.hair_curves.new('Source_surface_hair_study')
    curves.add_curves([len(s) for s in strands])
    positions = [v for strand in strands for p in strand for v in p]
    curves.attributes['position'].data.foreach_set('vector',positions)
    radius = curves.attributes.new('radius','FLOAT','POINT')
    radii = [0.000035*(.2+.8*np.sin(np.pi*i/(len(s)-1))) for s in strands for i in range(len(s))]
    radius.data.foreach_set('value',radii)
    obj = bpy.data.objects.new(curves.name,curves)
    bpy.context.scene.collection.objects.link(obj)
    material = bpy.data.materials.new('Surface_fiber_study')
    material.use_nodes = True
    nodes,links = material.node_tree.nodes,material.node_tree.links
    shader = nodes.new('ShaderNodeBsdfHairPrincipled')
    shader.parametrization = 'COLOR'
    shader.inputs['Color'].default_value = (.025,.014,.008,1)
    shader.inputs['Roughness'].default_value = .3
    links.new(shader.outputs[0],nodes.get('Material Output').inputs['Surface'])
    curves.materials.append(material)
    record = {'method':'structure-tensor confidence-gated upper-surface streamlines',
        'seed':23,'attempts':768,'accepted':len(strands),'point_count':len(radii),
        'source_image':image.name,'source_image_size':[width,height],
        'surface_offset_m':.0003,'maximum_radius_m':.000035,
        'offset_normal':'barycentric interpolation of source vertex normals',
        'minimum_source_z_m':min_z,'curves_world_m':[[list(p) for p in s] for s in strands],
        'curves_uv':uv_strands,
        'limitations':['surface overlays, not rooted full-length groom',
            'no braid topology reconstruction','no rig binding or engine export',
            'UV overlap ambiguity and surface penetration not certified']}
    (destination/'strand-construction.json').write_text(json.dumps(record))
    return {k:v for k,v in record.items() if not k.startswith('curves_')}


def audit_eye_motion(source, destination):
    """Measure optical-part deformation against rigid eye motion; no art approval."""
    destination.mkdir(parents=True, exist_ok=False)
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene = bpy.context.scene
    objects = [o for o in scene.objects if o.name.startswith('Study_eye_')]
    assert len(objects) == 6
    rigs = {m.object for o in objects for m in o.modifiers if m.type == 'ARMATURE'}
    assert len(rigs) == 1
    rig = next(iter(rigs))
    assert rig is not None
    saved = {b.name:b.matrix_basis.copy() for b in rig.pose.bones}
    rest = {o.name:[o.matrix_world@v.co for v in o.data.vertices] for o in objects}
    tests = []
    try:
        for name, axis, angle in [('eye_L',2,.25),('eye_L',2,-.25),
                                  ('eye_R',0,.2),('eye_R',0,-.2),('head',2,.2)]:
            for b in rig.pose.bones:
                b.matrix_basis = saved[b.name]
            from mathutils import Matrix
            rig.pose.bones[name].matrix_basis = saved[name] @ Matrix.Rotation(angle,4,'XYZ'[axis])
            bpy.context.view_layer.update()
            dg = bpy.context.evaluated_depsgraph_get()
            parts = []
            for obj in objects:
                bone = rig.pose.bones[obj['source_eye_bone']]
                transform = (rig.matrix_world @ bone.matrix @
                             bone.bone.matrix_local.inverted() @ rig.matrix_world.inverted())
                evaluated = obj.evaluated_get(dg)
                mesh = evaluated.to_mesh()
                error = max(((evaluated.matrix_world@v.co)-(transform@p)).length
                            for v,p in zip(mesh.vertices,rest[obj.name]))
                evaluated.to_mesh_clear()
                parts.append({'object':obj.name,'max_rigid_departure_m':error})
            tests.append({'bone':name,'local_axis':axis,'angle_radians':angle,'parts':parts})
    finally:
        for b in rig.pose.bones:
            b.matrix_basis = saved[b.name]
        bpy.context.view_layer.update()
    assert hashlib.sha256(source.read_bytes()).hexdigest() == digest
    worst = max(p['max_rigid_departure_m'] for t in tests for p in t['parts'])
    (destination/'pose-audit.json').write_text(json.dumps({
        'source_sha256':digest,'source_unchanged':True,'poses':tests,
        'maximum_rigid_departure_m':worst,'rigid_gate_m':.00005,
        'rigid_gate_passed':worst <= .00005,
        'scope':'five local-axis poses; optical rigidity only, not eyelid collision or art approval'},indent=2))
    print('EYE_POSE_AUDIT_COMPLETE',worst,'rigid_gate_passed',worst <= .00005)


def construct_fitted_eyes(eyes):
    """Exercise analytic eye geometry against this verified rest-pose source."""
    sys.path.insert(0, str(Path(__file__).parent))
    from eye_geometry import construct_eye
    evaluated = eyes.evaluated_get(bpy.context.evaluated_depsgraph_get())
    assert len(eyes.data.vertices) == len(evaluated.data.vertices) == 96
    points = [eyes.matrix_world @ v.co for v in eyes.data.vertices]
    assert max((p-evaluated.matrix_world @ v.co).length
               for p,v in zip(points,evaluated.data.vertices)) < 1e-5, 'Rest pose required'
    eyes.data.calc_loop_triangles()
    triangles = list(eyes.data.loop_triangles)
    tree = BVHTree.FromPolygons(points, [tuple(t.vertices) for t in triangles],
                               all_triangles=True)
    source_uv = eyes.data.uv_layers.active.data

    def uv_at(point):
        hit, _, index, _ = tree.ray_cast(Vector((point.x, -.3, point.z)), Vector((0,1,0)))
        if hit is None:
            return (0.5,0.5)
        t = triangles[index]
        uv = [Vector((*source_uv[i].uv,0)) for i in t.loops]
        return barycentric_transform(hit, *(points[i] for i in t.vertices), *uv)[:2]

    iris_mat = eyes.data.materials[0].copy()
    iris_mat.name = 'Study_iris_source_pigment'
    p = next(n for n in iris_mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Specular IOR Level'].default_value = 0
    outer_mat = eyes.data.materials[0].copy()
    outer_mat.name = 'Study_sclera_limbus_cornea'
    nodes, links = outer_mat.node_tree.nodes, outer_mat.node_tree.links
    sclera = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
    # The legacy eye atlas includes a painted iris. Reusing it on the outer
    # surface duplicates that iris beside the refracted internal one.
    # Neutral pigment isolates region separation; vein synthesis is not yet here.
    for link in list(sclera.inputs['Base Color'].links):
        links.remove(link)
    sclera.inputs['Base Color'].default_value = (.62,.60,.55,1)
    sclera.inputs['Roughness'].default_value = .22
    sclera.inputs['IOR'].default_value = 1.37
    glass = nodes.new('ShaderNodeBsdfGlass')
    glass.inputs['Roughness'].default_value = .025
    glass.inputs['IOR'].default_value = 1.37
    weight = nodes.new('ShaderNodeAttribute')
    weight.attribute_name = 'corneal_transmission'
    mix = nodes.new('ShaderNodeMixShader')
    links.new(weight.outputs['Fac'], mix.inputs[0])
    links.new(sclera.outputs[0], mix.inputs[1])
    links.new(glass.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], next(n for n in nodes if n.type == 'OUTPUT_MATERIAL').inputs['Surface'])
    black = bpy.data.materials.new('Study_pupil_backing')
    black.use_nodes = True
    p = black.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (.001,.001,.001,1)
    p.inputs['Specular IOR Level'].default_value = 0
    records = []
    for sign in (-1,1):
        indices = [i for i,p in enumerate(points) if p.x*sign > 0]
        front = sorted(indices, key=lambda i:points[i].y)[:8]
        apex = sum((points[i] for i in front),Vector())/len(front)
        apex.y = min(points[i].y for i in indices)
        groups = [{(g.group, round(g.weight,6)) for g in eyes.data.vertices[i].groups}
                  for i in indices]
        group = max(groups[0], key=lambda item:item[1])[0]
        assert eyes.vertex_groups[group].name.startswith('eye_')
        assert all(dict(g).get(group,0) > .96 for g in groups), 'Unexpected eye weighting'
        radius = (max(points[i].x for i in indices)-min(points[i].x for i in indices))/2
        model = construct_eye(radius=radius)
        for part, material in [('outer',outer_mat),('iris',iris_mat),('pupil',black)]:
            data = model[part]
            world = [apex+Vector(v) for v in data['vertices']]
            inverse = eyes.matrix_world.inverted()
            mesh = bpy.data.meshes.new(f'Study_eye_{sign}_{part}')
            mesh.from_pydata([inverse@v for v in world],[],data['faces'])
            mesh.update()
            mesh.materials.append(material)
            obj = eyes.copy()
            obj.data = mesh
            obj.name = mesh.name
            bpy.context.scene.collection.objects.link(obj)
            assert len(obj.vertex_groups) == 0
            for source_group in eyes.vertex_groups:
                obj.vertex_groups.new(name=source_group.name)
            # Optical components must move together. Source eyelid blends made
            # the new surfaces deform differently in the measured pose audit.
            # Keep the original source untouched; bind constructed optics rigidly.
            obj.vertex_groups[group].add(list(range(len(world))),1,'REPLACE')
            uvs = [uv_at(v) for v in world]
            uv = mesh.uv_layers.new(name='Source_projected_UV')
            for poly in mesh.polygons:
                poly.use_smooth = True
                for loop in poly.loop_indices:
                    uv.data[loop].uv = uvs[mesh.loops[loop].vertex_index]
            obj['eye_region'] = part
            obj['construction_parameters'] = json.dumps(model['parameters'])
            obj['source_eye_bone'] = eyes.vertex_groups[group].name
            if part == 'outer':
                attribute = mesh.attributes.new('corneal_transmission','FLOAT','POINT')
                for item,w in zip(attribute.data,data['transmission']):
                    item.value = w
                region = mesh.attributes.new('eye_region','INT','FACE')
                for item,label in zip(region.data,data['regions']):
                    item.value = {'cornea':1,'limbus':2,'sclera':3}[label]
        records.append({'side':sign,'apex_world_m':list(apex),
            'source_bone':eyes.vertex_groups[group].name,
            'weight_transfer':'rigid optical parts on verified dominant source eye bone',
            'parameters':model['parameters'],
            'minimum_axial_iris_clearance_m':model['minimum_axial_iris_clearance_m']})
    eyes.hide_render = True
    eyes.hide_set(True)
    return {'experiment':'continuous corneal cap and recessed iris', 'eyes':records,
            'sclera_albedo_linear':[.62,.60,.55],
            'limitations':['generic analytic shape, not captured anatomy',
                'iris projection retains baked source texture shading',
                'neutral sclera lacks veins and regional pigmentation',
                'rigid eye attachment; eyelid contact and export not validated']}

def review_saved(source, destination, eye_study=False, layered_eye=False, geometry_eye=False,
                 eye_light=False, render_review=True, hair_texture=False, hair_strands=False,
                 demo_groom=False, groom_pose=False, scalp_isolation=False, source_skin=False,
                 skin_transport=False, diagnostic_light=False, skin_detail=False,
                 skin_normals=False):
    """Review saved geometry; record every optional experimental modification."""
    destination.mkdir(parents=True, exist_ok=False)
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene = bpy.context.scene
    assert json.loads(scene['requested_character'])['age'] == 18
    bpy.context.view_layer.update()
    cam = scene.camera
    height = cam.data.ortho_scale / 1.16
    ground = bpy.data.objects['Plane'].location.z + 0.005
    eyes = next(o for o in scene.objects if o.type == 'MESH' and o.name == 'Eyes')
    changes = []
    if skin_normals:
        mesh = bpy.data.objects['Body03'].data
        original = [tuple(v.co) for v in mesh.vertices]
        custom = mesh.attributes.get('custom_normal')
        assert custom is not None
        mesh.attributes.remove(custom)
        for edge in mesh.edges:
            edge.use_edge_sharp = False
        for face in mesh.polygons:
            face.use_smooth = True
        mesh.update()
        # GLB seams duplicate positions for UVs/attributes. Average geometric
        # normals across those positions without merging skin/UV vertices.
        keys = [tuple(round(c,6) for c in v.co) for v in mesh.vertices]
        sums = {}
        for face in mesh.polygons:
            for index in face.vertices:
                key = keys[index]
                sums[key] = sums.get(key,Vector()) + face.normal * face.area
        mesh.normals_split_custom_set([sums[keys[loop.vertex_index]].normalized()
                                       for loop in mesh.loops])
        assert [tuple(v.co) for v in mesh.vertices] == original
        changes.append({'experiment':'area-weighted skin normals shared across coincident positions',
            'vertices_unchanged':True,'vertices':len(mesh.vertices),'faces':len(mesh.polygons),
            'limitation':'split vertices and topology unchanged; not anatomical remodeling'})
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'skin-normals.blend'))
    if skin_detail:
        body = bpy.data.objects['Body03']
        mesh = body.data
        attr = mesh.attributes.get('study_skin_rest_m') or mesh.attributes.new(
            'study_skin_rest_m','FLOAT_VECTOR','POINT')
        for v, value in zip(mesh.vertices,attr.data):
            value.vector = body.matrix_world @ v.co
        mat = body.data.materials[0]
        nodes,links = mat.node_tree.nodes,mat.node_tree.links
        p = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
        assert not p.inputs['Normal'].is_linked and not p.inputs['Roughness'].is_linked
        coordinates = nodes.new('ShaderNodeAttribute')
        coordinates.attribute_name = attr.name
        pores = nodes.new('ShaderNodeTexVoronoi')
        pores.inputs['Scale'].default_value = 1800
        links.new(coordinates.outputs['Vector'],pores.inputs['Vector'])
        profile = nodes.new('ShaderNodeValToRGB')
        profile.color_ramp.interpolation = 'EASE'
        profile.color_ramp.elements[0].position = .04
        profile.color_ramp.elements[1].position = .26
        links.new(pores.outputs['Distance'],profile.inputs[0])
        bump = nodes.new('ShaderNodeBump')
        bump.inputs['Strength'].default_value = .35
        bump.inputs['Distance'].default_value = .00006
        links.new(profile.outputs['Color'],bump.inputs['Height'])
        links.new(bump.outputs['Normal'],p.inputs['Normal'])
        rough = nodes.new('ShaderNodeTexNoise')
        rough.inputs['Scale'].default_value = 120
        rough.inputs['Detail'].default_value = 2
        links.new(coordinates.outputs['Vector'],rough.inputs['Vector'])
        remap = nodes.new('ShaderNodeMapRange')
        remap.inputs['To Min'].default_value = .35
        remap.inputs['To Max'].default_value = .5
        links.new(rough.outputs['Fac'],remap.inputs['Value'])
        links.new(remap.outputs['Result'],p.inputs['Roughness'])
        changes.append({'experiment':'editable rest-coordinate skin microrelief',
            'coordinate_attribute':attr.name,'pore_frequency_per_m':1800,
            'bump_distance_m':.00006,'bump_strength':.35,'roughness_range':[.35,.5],
            'limitations':['synthetic isotropic pores, not measured skin',
                'no regional lips/eyelids mask','not baked or game-export validated']})
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'skin-detail.blend'))
    if diagnostic_light:
        before = []
        for obj in scene.objects:
            if obj.type != 'LIGHT':
                continue
            before.append({'name':obj.name,'energy':obj.data.energy,
                'color':list(obj.data.color),'size':obj.data.size,
                'position':list(obj.location)})
            obj.data.energy = 0
        light = bpy.data.objects['Neutral portrait softbox']
        light.data.energy = 45
        light.data.color = (1,1,1)
        light.data.size = .45
        light.location = (-.8,-1.2,2.1)
        light.rotation_euler = (Vector((0,0,1.55))-light.location).to_track_quat('-Z','Y').to_euler()
        world = scene.world.node_tree.nodes['Background']
        world.inputs[0].default_value = (.18,.18,.18,1)
        world.inputs[1].default_value = .04
        changes.append({'experiment':'neutral directional skin diagnostic','previous_lights':before,
            'key_watts':45,'key_size_m':.45,'world_strength':.04,
            'limitation':'diagnostic light, not final presentation or calibrated capture'})
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'diagnostic-light.blend'))
    if skin_transport:
        mat = bpy.data.objects['Body03'].data.materials[0]
        p = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        before = {'method':p.subsurface_method,
            'weight':p.inputs['Subsurface Weight'].default_value,
            'scale':p.inputs['Subsurface Scale'].default_value,
            'radius':list(p.inputs['Subsurface Radius'].default_value)}
        p.subsurface_method = 'RANDOM_WALK_SKIN'
        p.inputs['Subsurface Weight'].default_value = 1
        p.inputs['Subsurface Scale'].default_value = .001
        p.inputs['Subsurface Radius'].default_value = (1,.45,.2)
        changes.append({'experiment':'millimetre-scale skin transport', 'before':before,
            'after':{'method':p.subsurface_method,'weight':1,'scale':.001,'radius':[1,.45,.2]},
            'limitation':'hypothesis parameters, not measured subject optical properties'})
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'skin-transport.blend'))
    if source_skin:
        path = Path(__file__).resolve().parents[2]/'assets/character-sources/makehuman-system/skins/young_caucasian_female/young_lightskinned_female_diffuse.png'
        body = bpy.data.objects['Body03']
        textures = [n for n in body.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE']
        assert len(textures) == 1
        before = list(textures[0].image.size)
        textures[0].image = bpy.data.images.load(str(path),check_existing=True)
        textures[0].image.pack()
        changes.append({'experiment':'original-resolution source skin',
            'before_size':before,'after_size':list(textures[0].image.size),
            'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'license':'CC0, source mhmat declaration',
            'limitation':'source contains painted scalp stubble and baked shading; not calibrated skin'})
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'source-skin.blend'))
    if scalp_isolation:
        bpy.data.objects['cyberpunk hair'].hide_render = True
        changes.append({'experiment':'isolate underlying head without author groom',
            'only_change':'cyberpunk hair hide_render=True'})
    if groom_pose:
        from mathutils import Matrix
        anchor = bpy.data.objects['Study_groom_head_attachment']
        constraint = anchor.constraints[0]
        bone = constraint.target.pose.bones[constraint.subtarget]
        bone.matrix_basis = bone.matrix_basis @ Matrix.Rotation(.4,4,'Z')
        bpy.context.view_layer.update()
        changes.append({'experiment':'saved groom attachment posed closeups',
            'bone':bone.name,'local_axis':'Z','radians':.4,
            'limitation':'single rigid pose; no collision or export certification'})
    if demo_groom:
        changes.append(append_demo_groom())
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'author-groom-study.blend'))
    if hair_strands:
        changes.append(construct_surface_strands(destination))
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'hair-strands-study.blend'))
    if hair_texture:
        hair = bpy.data.objects['Hair_braid01']
        material = hair.data.materials[0]
        nodes, links = material.node_tree.nodes, material.node_tree.links
        p = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
        incoming = list(p.inputs['Base Color'].links)
        assert len(incoming) == 1 and incoming[0].from_node.type == 'MIX'
        mix = incoming[0].from_node
        assert mix.blend_type == 'MULTIPLY'
        texture = next(n for n in nodes if n.type == 'TEX_IMAGE')
        before = list(mix.inputs[7].default_value)
        links.new(texture.outputs['Color'],p.inputs['Base Color'])
        changes.append({'experiment':'restore original hair texture without dark dye',
            'object':hair.name,'removed_linear_multiplier':before,
            'image':texture.image.name,'size':list(texture.image.size),
            'roughness_unchanged':p.inputs['Roughness'].default_value,
            'limitation':'original texture contains baked highlights; not physical fiber shading'})
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'hair-texture-study.blend'))
    if geometry_eye:
        changes.append(construct_fitted_eyes(eyes))
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'geometry-eye-study.blend'))
    if eye_light:
        assert any(o.name.startswith('Study_eye_') for o in scene.objects)
        for obj in scene.objects:
            if obj.type == 'LIGHT' and obj.data.type == 'AREA':
                changes.append({'light':obj.name,'size_before':obj.data.size,
                                'size_after':obj.data.size/3,
                                'power_unchanged':obj.data.energy})
                obj.data.size /= 3
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'eye-light-study.blend'))
    if layered_eye:
        # Isolate the optical-layer hypothesis; this is not captured corneal
        # anatomy or an iris reconstruction. Preserve the source rig/UVs.
        assert len(eyes.data.vertices) == 96, 'Reassess construction for changed eye source'
        shell = eyes.copy()
        shell.data = eyes.data.copy()
        shell.name = 'Eye_surface_study'
        scene.collection.objects.link(shell)
        shell.data.materials.clear()
        material = bpy.data.materials.new('Eye_clear_surface_study')
        material.use_nodes = True
        p = material.node_tree.nodes.get('Principled BSDF')
        p.inputs['Base Color'].default_value = (1, 1, 1, 1)
        p.inputs['Roughness'].default_value = 0.025
        p.inputs['IOR'].default_value = 1.37
        p.inputs['Transmission Weight'].default_value = 1
        shell.data.materials.append(material)
        # Positive offset keeps the clear shell outside the opaque source.
        offset = shell.modifiers.new('Surface clearance 0.05 mm', 'DISPLACE')
        offset.strength = 0.00005
        offset.mid_level = 0
        thickness = shell.modifiers.new('Clear layer 0.15 mm', 'SOLIDIFY')
        thickness.thickness = 0.00015
        thickness.offset = 1
        for material in eyes.data.materials:
            p = next(n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
            # Do not add a second specular lobe on the buried pigment surface.
            p.inputs['Specular IOR Level'].default_value = 0
        changes.append({'experiment':'clear shell over existing pigment mesh',
            'clearance_m':0.00005,'thickness_m':0.00015,'ior':1.37,
            'roughness':0.025,'buried_specular_ior_level':0,
            'limitations':['not anatomical cornea','no recessed iris',
                'no limbus transition','no engine export validation']})
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'layered-eye-study.blend'))
    if eye_study:
        for mat in eyes.data.materials:
            p = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
            assert not p.inputs['Roughness'].is_linked
            changes.append({'material':mat.name, 'parameter':'roughness',
                'before':p.inputs['Roughness'].default_value, 'after':0.12})
            p.inputs['Roughness'].default_value = 0.12
        bpy.ops.wm.save_as_mainfile(filepath=str(destination/'eye-material-study.blend'))
    evaluated = eyes.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    points = [evaluated.matrix_world @ v.co for v in mesh.vertices]
    eye_center = sum(points, Vector()) / len(points)
    evaluated.to_mesh_clear()
    full_target = Vector((0, 0, ground + height * 0.52))
    views = [
        ('face-front', eye_center + Vector((0, 0, -0.035)), Vector((0, -1, 0)), 0.43),
        ('three-quarter', full_target, Vector((0.8, -1, 0.08)), height * 1.16),
        ('back', full_target, Vector((0, 1, 0.06)), height * 1.16),
    ]
    if eye_study or layered_eye:
        views = views[:1]
    if source_skin or skin_transport or diagnostic_light or skin_detail or skin_normals:
        views = views[:1]
    if skin_detail or skin_normals:
        views.append(('skin-cheek',eye_center+Vector((-.035,-.005,-.035)),
                      Vector((-.15,-1,0)),.075))
    if groom_pose:
        target = eye_center + Vector((0,0,.03))
        views = [('head-turned', target, Vector((0,-1,.05)),.38),
                 ('head-rear', target, Vector((0,1,.1)),.38)]
        if scalp_isolation:
            views = views[1:]
    if geometry_eye or eye_light:
        front = sorted([p for p in points if p.x > 0],key=lambda p:p.y)[:8]
        target = sum(front,Vector())/len(front)
        target.y = min(p.y for p in points)
        views = views[:1] + [
            ('eye-front',target,Vector((0,-1,0)),.085),
            ('eye-oblique',target,Vector((.55,-1,.06)),.085)]
    diagnostics = []
    for obj in scene.objects:
        if obj.type != 'MESH' or not obj.visible_get() or obj.name == 'Plane':
            continue
        for mat in obj.data.materials:
            if not mat or not mat.use_nodes:
                continue
            p = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
            diagnostics.append({'object': obj.name, 'material': mat.name,
                'roughness': p.inputs['Roughness'].default_value if p else None,
                'subsurface_scale': p.inputs['Subsurface Scale'].default_value if p else None,
                'textures': [{'name': n.image.name, 'size': list(n.image.size),
                    'color_space': n.image.colorspace_settings.name}
                    for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image]})
    scene.cycles.samples = 24
    scene.cycles.time_limit = 40
    scene.cycles.device = 'CPU'
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 2
    records = []
    if not render_review:
        views = []
    for name, target, direction, scale in views:
        cam.location = target + direction.normalized() * height * 2.5
        cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
        cam.data.ortho_scale = scale
        scene.render.resolution_x = 640
        scene.render.resolution_y = 640 if name == 'face-front' else 850
        scene.render.filepath = str(destination / (name + '.png'))
        bpy.ops.render.render(write_still=True)
        records.append({'view':name, 'camera_position':list(cam.location),
            'target':list(target), 'orthographic_scale':scale})
    assert hashlib.sha256(source.read_bytes()).hexdigest() == digest
    (destination/'review.json').write_text(json.dumps({'source_blend_sha256':digest,
        'views':records,'materials':diagnostics,'source_unchanged':True,
        'changes':changes,
        'rendered':render_review,
        'scope':'fixed-light saved-asset review; only explicitly listed changes',
        'art_approval':'pending'},indent=2))
    print('CHARACTER_SAVED_REVIEW_PASS' if render_review else 'CHARACTER_BUILD_PASS')

args = sys.argv[sys.argv.index('--') + 1:]
if len(args) == 3 and args[2] == '--skin-normals-review':
    review_saved(Path(args[0]),Path(args[1]),skin_normals=True)
    sys.exit(0)
if len(args) == 3 and args[2] == '--skin-detail-review':
    review_saved(Path(args[0]),Path(args[1]),skin_detail=True)
    sys.exit(0)
if len(args) == 3 and args[2] == '--skin-light-review':
    review_saved(Path(args[0]),Path(args[1]),diagnostic_light=True)
    sys.exit(0)
if len(args) == 3 and args[2] == '--skin-transport-review':
    review_saved(Path(args[0]),Path(args[1]),skin_transport=True)
    sys.exit(0)
if len(args) == 3 and args[2] == '--source-skin-review':
    review_saved(Path(args[0]),Path(args[1]),source_skin=True)
    sys.exit(0)
if len(args) == 3 and args[2] == '--scalp-isolation-review':
    review_saved(Path(args[0]),Path(args[1]),groom_pose=True,scalp_isolation=True)
    sys.exit(0)
if len(args) == 3 and args[2] == '--groom-pose-review':
    review_saved(Path(args[0]),Path(args[1]),groom_pose=True)
    sys.exit(0)
if len(args) == 3 and args[2] == '--groom-attachment-audit':
    attach_groom_audit(Path(args[0]),Path(args[1]))
    sys.exit(0)
if len(args) == 3 and args[2] == '--eye-pose-audit':
    audit_eye_motion(Path(args[0]),Path(args[1]))
    sys.exit(0)
if len(args) == 3 and args[2] in ('--review-only', '--eye-study', '--layered-eye-study', '--geometry-eye-study', '--eye-light-study', '--geometry-eye-build', '--hair-texture-study', '--hair-strands-study', '--author-groom-study'):
    review_saved(Path(args[0]), Path(args[1]), args[2] == '--eye-study',
                 args[2] == '--layered-eye-study', args[2] in ('--geometry-eye-study','--geometry-eye-build'),
                 args[2] == '--eye-light-study', args[2] != '--geometry-eye-build',
                 args[2] == '--hair-texture-study', args[2] == '--hair-strands-study',
                 args[2] == '--author-groom-study')
    sys.exit(0)
if len(args) != 2:
    raise ValueError('Expected source, fresh output directory and optional --review-only')
source, destination = map(Path, args)
destination.mkdir(parents=True, exist_ok=False)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
raw = source.read_bytes()
document = json.loads(raw[20:20+struct.unpack_from('<I', raw, 12)[0]])
# Blender 4.5 does not understand Godot's visibility extension. Only remove it
# from empty leaf alternatives that cannot affect any rendered geometry.
for node in document.get('nodes', []):
    extensions = node.get('extensions', {})
    if 'KHR_node_visibility' in extensions:
        if 'mesh' in node or node.get('children') or 'camera' in node:
            raise ValueError('Cannot discard visibility from a populated node')
        del extensions['KHR_node_visibility']
for key in ['extensionsRequired', 'extensionsUsed']:
    document[key] = [e for e in document.get(key, []) if e != 'KHR_node_visibility']
encoded = json.dumps(document, separators=(',', ':')).encode()
encoded += b' ' * (-len(encoded) % 4)
tail = raw[20+struct.unpack_from('<I', raw, 12)[0]:]
compatible = destination/'blender-import.glb'
compatible.write_bytes(struct.pack('<III', 0x46546c67, 2, 20+len(encoded)+len(tail)) + struct.pack('<II',len(encoded),0x4e4f534a) + encoded + tail)
bpy.ops.import_scene.gltf(filepath=str(compatible))
bpy.context.view_layer.update()
actors = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.visible_get()]
assert actors and any(o.type == 'ARMATURE' for o in bpy.context.scene.objects)
for obj in actors:
    for mat in obj.data.materials:
        if not mat or not mat.use_nodes:
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if bsdf is None:
            continue
        if 'Body' in obj.name:
            bsdf.inputs['Roughness'].default_value = 0.48
            bsdf.inputs['Subsurface Weight'].default_value = 0.075
            bsdf.inputs['Subsurface Scale'].default_value = 0.012
        if 'Formal' in obj.name or 'Shoes' in obj.name:
            # Retain fitted garment topology and UVs, replace source costume print.
            for socket in ['Base Color', 'Roughness']:
                for link in list(bsdf.inputs[socket].links):
                    mat.node_tree.links.remove(link)
            bsdf.inputs['Base Color'].default_value = (0.022, 0.029, 0.043, 1)
            bsdf.inputs['Roughness'].default_value = 0.7
            bsdf.inputs['Coat Weight'].default_value = 0.025
            noise = mat.node_tree.nodes.new('ShaderNodeTexNoise')
            noise.inputs['Scale'].default_value = 210
            bump = mat.node_tree.nodes.new('ShaderNodeBump')
            bump.inputs['Strength'].default_value = 0.16
            bump.inputs['Distance'].default_value = 0.00015
            mat.node_tree.links.new(noise.outputs['Fac'], bump.inputs['Height'])
            mat.node_tree.links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])

def material(name, color, metallic=0.0, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    p = mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Metallic'].default_value = metallic
    p.inputs['Roughness'].default_value = 0.3
    p.inputs['Emission Color'].default_value = (*color, 1)
    p.inputs['Emission Strength'].default_value = emission
    return mat

alloy = material('Brushed graphite hardware', (0.055,0.072,0.095), 0.75)
cyan = material('Cyan status lights', (0.015,0.65,0.8), 0.25, 2)
def block(name, location, scale, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new('Manufactured edge radius', 'BEVEL')
    bevel.width = min(scale)*0.22
    bevel.segments = 3
    obj.modifiers.new('Weighted corner normals', 'WEIGHTED_NORMAL')
    obj.data.materials.append(mat)
    obj['study_role'] = 'static hard-surface costume accessory; not skinned'
    return obj

# Seat chest hardware on the actual fitted garment, not guessed body depth.
top = next(o for o in actors if 'FormalTop' in o.name)
world = [top.matrix_world @ Vector(c) for c in top.bound_box]
z0, z1 = min(p.z for p in world), max(p.z for p in world)
def front_surface(x, z):
    inv = top.matrix_world.inverted()
    origin = inv @ Vector((x,-2,z))
    direction = (inv.to_3x3() @ Vector((0,1,0))).normalized()
    hit, point, normal, face = top.ray_cast(origin, direction)
    if not hit:
        raise ValueError('Requested hardware anchor misses fitted garment')
    return top.matrix_world @ point
for x in [-0.085, 0.085]:
    anchor = front_surface(x, z0+(z1-z0)*0.63)
    block('Garment-mounted interface', anchor+Vector((0,-0.007,0)), (0.043,0.012,0.083), alloy)
    for dz in [-0.025,0,0.025]:
        block('Interface light', anchor+Vector((0,-0.014,dz)), (0.029,0.003,0.003), cyan)
    # A second smaller fastener has its own independently checked support anchor.
    anchor2 = front_surface(x, z0+(z1-z0)*0.35)
    block('Lower utility fastening', anchor2+Vector((0,-0.005,0)), (0.026,0.008,0.018), alloy)

scene = bpy.context.scene
scene['requested_character'] = json.dumps({'species':'human','gender':'woman','age':18,'style':'cyberpunk','admission':'unapproved realism study'})
scene['source_sha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
bpy.context.view_layer.update()
depsgraph = bpy.context.evaluated_depsgraph_get()
bounds = []
for obj in actors:
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    # Skin modifiers change the rest-space bounds: frame actual rendered vertices.
    used = {index for face in mesh.polygons for index in face.vertices}
    bounds.extend(evaluated.matrix_world @ mesh.vertices[i].co for i in used)
    evaluated.to_mesh_clear()
lo = Vector(tuple(min(p[i] for p in bounds) for i in range(3)))
hi = Vector(tuple(max(p[i] for p in bounds) for i in range(3)))
height = hi.z-lo.z
ground = material('Studio floor', (0.022,0.026,0.035))
bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,lo.z-0.005))
bpy.context.object.data.materials.append(ground)
target = Vector((0,0,lo.z+height*0.52))
bpy.ops.object.camera_add(location=(height*0.22,-height*2.5,lo.z+height*0.66))
cam = bpy.context.object
cam.rotation_euler = (target-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.type='ORTHO'
cam.data.ortho_scale=height*1.16
cam.data.clip_start=0.01
scene.camera=cam
for name, pos, power, color, size in [
    ('Neutral portrait softbox',(-2,-3,3),420,(1,0.86,0.76),2.1),
    ('Cyan rim',(1,1,2),180,(0.15,0.65,1),1.3),
    ('Soft frontal fill',(1,-2,1.3),90,(0.7,0.8,1),1.8),
]:
    light=bpy.data.lights.new(name,'AREA')
    light.energy=power; light.color=color; light.shape='DISK'; light.size=size
    obj=bpy.data.objects.new(name,light); scene.collection.objects.link(obj)
    obj.location=pos; obj.rotation_euler=(target-obj.location).to_track_quat('-Z','Y').to_euler()
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(0.15,0.18,0.23,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=0.2
scene.render.engine='CYCLES'; scene.cycles.device='CPU'
scene.cycles.samples=48; scene.cycles.time_limit=60; scene.cycles.use_denoising=True
scene.render.threads_mode='FIXED'; scene.render.threads=2
scene.render.resolution_x=800; scene.render.resolution_y=1100
scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG'
scene.render.filepath=str(destination/'full-body.png')
bpy.ops.wm.save_as_mainfile(filepath=str(destination/'character-study.blend'))
bpy.ops.render.render(write_still=True)
(destination/'receipt.json').write_text(json.dumps({'source_sha256':scene['source_sha256'],'requested_age':18,'source_meshes':len(actors),'device':'CPU','threads':2,'art_approval':'pending','limitations':['static accessories not rig-bound','new procedural finish not baked to portable textures','no age-estimation claim']},indent=2))
print('CHARACTER_LOOK_STUDY_RENDER_PASS')
