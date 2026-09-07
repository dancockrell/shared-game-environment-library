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

def review_saved(source, destination, eye_study=False, layered_eye=False):
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
        'scope':'fixed-light saved-asset review; only explicitly listed changes',
        'art_approval':'pending'},indent=2))
    print('CHARACTER_SAVED_REVIEW_PASS')

args = sys.argv[sys.argv.index('--') + 1:]
if len(args) == 3 and args[2] in ('--review-only', '--eye-study', '--layered-eye-study'):
    review_saved(Path(args[0]), Path(args[1]), args[2] == '--eye-study',
                 args[2] == '--layered-eye-study')
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
