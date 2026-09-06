# SPDX-License-Identifier: GPL-3.0-or-later
"""Bounded Blender reference renderer for the existing Scene Forge scene.

Run Blender --background --factory-startup --threads 2 --python this_file --
compiled_scene.json new_output_directory. No source assets are overwritten.
The explicit food-reference material treatment is not a game material export.
"""
import array
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import material_profiles


def linear(value):
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def material(spec, profiles):
    result = bpy.data.materials.new(spec["name"])
    result.use_nodes = True
    nodes = result.node_tree.nodes
    links = result.node_tree.links
    shader = nodes.get("Principled BSDF")
    # Review palette contract: authored RGB and painted bytes are sRGB.
    shader.inputs["Base Color"].default_value = [linear(v) for v in spec["color"][:3]] + [spec["color"][3]]
    finish = spec.get("material", {})
    shader.inputs["Roughness"].default_value = finish.get("roughness", 0.85)
    shader.inputs["Metallic"].default_value = finish.get("metallic", 0)
    paint = spec.get("paint_texture")
    if paint:
        image = bpy.data.images.new(spec["name"] + " albedo", paint["width"], paint["height"], float_buffer=True)
        image.colorspace_settings.name = "Non-Color"
        image.pixels.foreach_set(array.array("f", (
            v / 255 if i % 4 == 3 else linear(v / 255)
            for i, v in enumerate(paint["rgba"])
        )))
        image.pack()
        texture = nodes.new("ShaderNodeTexImage")
        texture.image = image
        links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    profile = material_profiles.resolve(profiles, spec["name"])
    for key, value in profile.get("principled", {}).items():
        shader.inputs[key].default_value = value
    settings = profile.get("noise")
    if settings:
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = settings["scale"]
        noise.inputs["Detail"].default_value = settings["detail"]
        coordinates = nodes.new("ShaderNodeTexCoord")
        coordinate_socket = "Object" if settings.get("coordinates") == "object" else "Generated"
        links.new(coordinates.outputs[coordinate_socket], noise.inputs["Vector"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = settings["strength"]
        bump.inputs["Distance"].default_value = settings["distance"]
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], shader.inputs["Normal"])
        ramp = nodes.new("ShaderNodeMapRange")
        ramp.inputs["To Min"].default_value, ramp.inputs["To Max"].default_value = settings["roughness"]
        links.new(noise.outputs["Fac"], ramp.inputs["Value"])
        links.new(ramp.outputs["Result"], shader.inputs["Roughness"])
        if "colors" in settings:
            pigment_noise = noise
            if "pigment_scale" in settings:
                pigment_noise = nodes.new("ShaderNodeTexNoise")
                pigment_noise.inputs["Scale"].default_value = settings["pigment_scale"]
                pigment_noise.inputs["Detail"].default_value = settings["detail"]
                links.new(coordinates.outputs[coordinate_socket], pigment_noise.inputs["Vector"])
            pigment = nodes.new("ShaderNodeValToRGB")
            pigment.color_ramp.elements.new(0.5)
            for element, position, color in zip(pigment.color_ramp.elements, [0, 0.5, 1], settings["colors"]):
                element.position = position
                element.color = [linear(v) for v in color] + [1]
            contrast = nodes.new("ShaderNodeMath")
            contrast.operation = "MULTIPLY_ADD"
            amount = settings.get("pigment_contrast", 1)
            contrast.inputs[1].default_value = amount
            contrast.inputs[2].default_value = 0.5 - 0.5 * amount
            links.new(pigment_noise.outputs["Fac"], contrast.inputs[0])
            links.new(contrast.outputs[0], pigment.inputs["Fac"])
            links.new(pigment.outputs["Color"], shader.inputs["Base Color"])
    result["scene_forge_reference_profile"] = json.dumps(profile, sort_keys=True)
    result["scene_forge_original_material"] = json.dumps(finish)
    return result


def verify_saved(data, output, profiles):
    bpy.ops.wm.open_mainfile(filepath=str(output / "reference.blend"))
    scene = bpy.context.scene
    assert scene["scene_forge_recipe_json"] == data["recipe_json"]
    assert scene["scene_forge_reference_profiles"] == json.dumps(profiles, sort_keys=True)
    objects = [o for o in scene.objects if o.type == "MESH"]
    assert len(objects) == len(data["instances"])
    assert len({o.data.name for o in objects}) == len(data["meshes"])
    for spec in data["meshes"]:
        mesh = bpy.data.meshes[spec["name"]]
        assert len(mesh.vertices) * 3 == len(spec["positions"])
        assert len(mesh.polygons) * 3 == len(spec["indices"])
        for i, vertex in enumerate(mesh.vertices):
            p = spec["positions"][i * 3:i * 3 + 3]
            assert (vertex.co - Vector((p[0], -p[2], p[1]))).length < 0.000001
        shader = mesh.materials[0].node_tree.nodes.get("Principled BSDF")
        profile = material_profiles.resolve(profiles, spec["name"])
        assert mesh.materials[0]["scene_forge_reference_profile"] == json.dumps(profile, sort_keys=True)
        for key, value in profile.get("principled", {}).items():
            assert abs(shader.inputs[key].default_value - value) < 0.00001
        if spec.get("paint_texture"):
            assert bpy.data.images[spec["name"] + " albedo"].packed_file is not None
    print("SCENE_FORGE_BLEND_RELOAD_PASS", len(objects), "instances", len(data["meshes"]), "meshes")


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    verify_only = len(args) == 3 and args[2] == "--verify-only"
    if len(args) != 2 and not verify_only:
        raise ValueError("Expected compiled scene, output directory and optional --verify-only")
    source, output = Path(args[0]), Path(args[1])
    if source.stat().st_size > 32 * 1024 * 1024:
        raise ValueError("Reference input exceeds 32 MiB")
    profiles = material_profiles.load(Path(__file__).with_name("reference_materials.json"))
    raw = source.read_bytes()
    data = json.loads(raw)
    if data["version"] != 2 or data["coordinate_system"] != "right-handed-y-up-ccw-metres":
        raise ValueError("Unsupported coordinate contract")
    if not 1 <= len(data["meshes"]) <= 128 or not 1 <= len(data["instances"]) <= 1000:
        raise ValueError("Reference scene count budget exceeded")
    if sum(len(m["positions"]) // 3 for m in data["meshes"]) > 500000:
        raise ValueError("Reference mesh budget exceeded")
    if verify_only:
        verify_saved(data, output, profiles)
        return
    output.mkdir(parents=True, exist_ok=False)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    axis = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
    meshes = []
    for spec in data["meshes"]:
        p, n, uv, indices = (spec[k] for k in ("positions", "normals", "uvs", "indices"))
        vertices = [(p[i], -p[i + 2], p[i + 1]) for i in range(0, len(p), 3)]
        faces = [indices[i:i + 3] for i in range(0, len(indices), 3)]
        mesh = bpy.data.meshes.new(spec["name"])
        mesh.from_pydata(vertices, [], faces)
        mesh.update()
        for polygon in mesh.polygons:
            polygon.use_smooth = True
        layer = mesh.uv_layers.new(name="UVMap")
        for loop in mesh.loops:
            i = loop.vertex_index * 2
            layer.data[loop.index].uv = (uv[i], uv[i + 1])
        mesh.normals_split_custom_set_from_vertices(
            [(n[i], -n[i + 2], n[i + 1]) for i in range(0, len(n), 3)]
        )
        mesh.materials.append(material(spec, profiles))
        meshes.append(mesh)
    bounds = []
    for entry in data["instances"]:
        obj = bpy.data.objects.new(meshes[entry["mesh"]].name, meshes[entry["mesh"]])
        bpy.context.collection.objects.link(obj)
        b, p = entry["basis"], entry["position"]
        authored = Matrix(((b[0], b[3], b[6], p[0]), (b[1], b[4], b[7], p[1]),
                           (b[2], b[5], b[8], p[2]), (0, 0, 0, 1)))
        obj.matrix_world = axis @ authored @ axis.inverted()
        obj["scene_forge_source"] = json.dumps(entry.get("source"))
        bounds.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    lower = Vector(tuple(min(p[i] for p in bounds) for i in range(3)))
    upper = Vector(tuple(max(p[i] for p in bounds) for i in range(3)))
    center = (lower + upper) / 2
    radius = max((upper - lower).length, 0.1)
    scene = bpy.context.scene
    scene["scene_forge_recipe_json"] = data["recipe_json"]
    scene["scene_forge_reference_profiles"] = json.dumps(profiles, sort_keys=True)
    camera_data = bpy.data.cameras.new("Reference camera")
    camera = bpy.data.objects.new("Reference camera", camera_data)
    bpy.context.collection.objects.link(camera)
    direction = Vector((0.3, -0.8, 0.68)).normalized()
    camera.location = center + direction * radius * 3
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = radius * 1.05
    scene.camera = camera
    for name, location, energy, size in [
        ("Large softbox", (-0.6, -0.7, 1), 55, 0.7),
        ("Glaze edge", (0.6, 0.4, 0.8), 75, 0.4),
        ("Soft fill", (0.4, -0.5, 0.3), 8, 0.5),
    ]:
        light = bpy.data.lights.new(name, "AREA")
        light.energy, light.shape, light.size = energy, "DISK", size
        obj = bpy.data.objects.new(name, light)
        bpy.context.collection.objects.link(obj)
        obj.location = center + Vector(location)
        obj.rotation_euler = (center - obj.location).to_track_quat("-Z", "Y").to_euler()
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.18, 0.21, 0.25, 1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.25
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.cycles.time_limit = 60
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 2
    scene.render.resolution_x, scene.render.resolution_y = 1100, 900
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "AgX"
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(output / "reference.png")
    bpy.ops.wm.save_as_mainfile(filepath=str(output / "reference.blend"))
    bpy.ops.render.render(write_still=True)
    verify_saved(data, output, profiles)
    receipt = {"source_sha256": hashlib.sha256(raw).hexdigest(),
               "blender": bpy.app.version_string, "engine": "CYCLES", "device": "CPU",
               "threads": 2, "samples_limit": 32, "render_time_limit_seconds": 60,
               "meshes": len(meshes), "instances": len(data["instances"]),
               "scope": "reference material and lighting; not game parity or final art"}
    (output / "receipt.json").write_text(json.dumps(receipt, indent=2), encoding="utf8")
    print("SCENE_FORGE_BLENDER_REFERENCE_PASS", json.dumps(receipt))


main()
