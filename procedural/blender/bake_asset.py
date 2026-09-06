# SPDX-License-Identifier: GPL-3.0-or-later
"""Bake one shared mesh from an existing reference.blend into a portable GLB.

Blender --background --threads 2 --python-exit-code 1 --python bake_asset.py
  -- reference.blend mesh_name fresh_output_directory
Original authoring file is never modified. Pilot export, not engine parity.
"""
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import glb_geometry


def world_bounds(obj):
    points = [obj.matrix_world @ v.co for v in obj.data.vertices]
    return [[f(p[i] for p in points) for i in range(3)] for f in (min, max)]


def main():
    source, mesh_name, destination = sys.argv[sys.argv.index("--") + 1:]
    source, destination = Path(source).resolve(), Path(destination).resolve()
    if source.stat().st_size > 128 * 1024 * 1024:
        raise ValueError("Authoring file exceeds 128 MiB")
    destination.mkdir(parents=True, exist_ok=False)
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene = bpy.context.scene
    candidates = [o for o in scene.objects if o.type == "MESH" and o.data.name == mesh_name]
    if not candidates:
        raise ValueError("No instance of requested source mesh")
    obj = candidates[0]
    mesh = obj.data
    if len(mesh.vertices) > 100000 or len(mesh.materials) != 1:
        raise ValueError("Pilot requires one material and at most 100000 vertices")
    original = mesh.materials[0]
    source_profile = original.get("scene_forge_reference_profile", "{}")
    source_recipe = scene["scene_forge_recipe_json"]
    source_vertices = [tuple(v.co) for v in mesh.vertices]
    source_triangles = len(mesh.polygons)
    # Blender Z-up -> glTF Y-up. Preserve directed triangle corners, allowing
    # exporter vertex splitting but not winding changes or changed surfaces.
    expected_triangles = [[(mesh.vertices[i].co.x, mesh.vertices[i].co.z, -mesh.vertices[i].co.y)
                           for i in polygon.vertices] for polygon in mesh.polygons]
    source_bounds = world_bounds(obj)
    # Keep original UV sampling explicit before selecting a new non-overlapping
    # export layout; otherwise albedo would silently change under a new unwrap.
    old_uv = mesh.uv_layers.active.name
    uv_node = original.node_tree.nodes.new("ShaderNodeUVMap")
    uv_node.uv_map = old_uv
    for node in list(original.node_tree.nodes):
        if node.type == "TEX_IMAGE" and not node.inputs["Vector"].is_linked:
            original.node_tree.links.new(uv_node.outputs["UV"], node.inputs["Vector"])
    mesh.uv_layers.new(name="SceneForgeBake")
    mesh.uv_layers.active_index = len(mesh.uv_layers) - 1
    mesh.uv_layers.active.active_render = True
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.025)
    bpy.ops.object.mode_set(mode="OBJECT")
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 8
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 2
    scene.render.bake.margin = 4
    scene.render.bake.use_selected_to_active = False
    nodes, links = original.node_tree.nodes, original.node_tree.links
    shader = nodes.get("Principled BSDF")
    if shader is None or shader.inputs["Alpha"].is_linked or shader.inputs["Alpha"].default_value != 1:
        raise ValueError("Pilot requires opaque Principled materials")
    if shader.inputs["Transmission Weight"].is_linked or shader.inputs["Transmission Weight"].default_value != 0:
        raise ValueError("Transmission requires a separate validated export contract")
    output = next(n for n in nodes if n.type == "OUTPUT_MATERIAL" and n.is_active_output)
    emission = nodes.new("ShaderNodeEmission")
    images = {}
    for channel, socket in [("base_color", "Base Color"), ("roughness", "Roughness"), ("normal", None)]:
        image = bpy.data.images.new(mesh_name + "_" + channel, 512, 512, alpha=False)
        image.colorspace_settings.name = "sRGB" if channel == "base_color" else "Non-Color"
        image.filepath_raw = str(destination / (channel + ".png"))
        image.file_format = "PNG"
        target = nodes.new("ShaderNodeTexImage")
        target.image = image
        nodes.active = target
        for node in nodes:
            node.select = node == target
        if socket:
            for link in list(emission.inputs["Color"].links):
                links.remove(link)
            value = shader.inputs[socket]
            if value.is_linked:
                links.new(value.links[0].from_socket, emission.inputs["Color"])
            elif socket == "Roughness":
                emission.inputs["Color"].default_value = [value.default_value] * 3 + [1]
            else:
                emission.inputs["Color"].default_value = value.default_value
            links.new(emission.outputs[0], output.inputs["Surface"])
            bpy.ops.object.bake(type="EMIT", uv_layer="SceneForgeBake")
        else:
            links.new(shader.outputs[0], output.inputs["Surface"])
            bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT", uv_layer="SceneForgeBake")
        image.save()
        images[channel] = image
        nodes.remove(target)
    links.new(shader.outputs[0], output.inputs["Surface"])
    nodes.remove(emission)
    # This is an export material, derived from the existing authoring graph.
    material = bpy.data.materials.new(mesh_name + " baked")
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    for key in ["Metallic", "Coat Weight", "Coat Roughness", "Coat IOR", "IOR"]:
        bsdf.inputs[key].default_value = shader.inputs[key].default_value
    for channel, image in images.items():
        tex = material.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = image
        uv = material.node_tree.nodes.new("ShaderNodeUVMap")
        uv.uv_map = "SceneForgeBake"
        material.node_tree.links.new(uv.outputs[0], tex.inputs[0])
        if channel == "normal":
            normal = material.node_tree.nodes.new("ShaderNodeNormalMap")
            normal.uv_map = "SceneForgeBake"
            material.node_tree.links.new(tex.outputs["Color"], normal.inputs["Color"])
            material.node_tree.links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
        else:
            material.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color" if channel == "base_color" else "Roughness"])
    material["scene_forge_reference_profile"] = source_profile
    material["scene_forge_export_losses"] = "Subsurface scattering and independent coat IOR not exported; lighting is not baked"
    mesh.materials[0] = material
    assert source_vertices == [tuple(v.co) for v in mesh.vertices]
    assert source_triangles == len(mesh.polygons)
    obj["scene_forge_recipe_json"] = source_recipe
    obj["scene_forge_source_mesh"] = mesh_name
    glb = destination / "asset.glb"
    bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB", use_selection=True,
                              export_extras=True, export_texcoords=True, export_normals=True,
                              export_tangents=True, export_cameras=False, export_lights=False)
    raw = glb.read_bytes()
    document, binary = glb_geometry.read(raw)
    geometry_receipt = glb_geometry.compare(document, binary, expected_triangles)
    assert len(document["meshes"]) == 1
    exported = document["materials"][0]
    assert "baseColorTexture" in exported["pbrMetallicRoughness"]
    assert "metallicRoughnessTexture" in exported["pbrMetallicRoughness"]
    assert "normalTexture" in exported
    assert exported["extras"]["scene_forge_reference_profile"] == source_profile
    if bsdf.inputs["Coat Weight"].default_value > 0:
        coat = exported["extensions"]["KHR_materials_clearcoat"]
        assert abs(coat["clearcoatFactor"] - bsdf.inputs["Coat Weight"].default_value) < 0.000001
        assert abs(coat["clearcoatRoughnessFactor"] - bsdf.inputs["Coat Roughness"].default_value) < 0.000001
    assert any(n.get("extras", {}).get("scene_forge_recipe_json") == source_recipe for n in document["nodes"])
    for image in document["images"]:
        assert "bufferView" in image and "uri" not in image
    # Native import is independent of exporter return status.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(glb))
    imported = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    assert len(imported) == 1
    imported[0].data.calc_loop_triangles()
    assert len(imported[0].data.loop_triangles) == source_triangles
    assert imported[0]["scene_forge_recipe_json"] == source_recipe
    restored_bounds = world_bounds(imported[0])
    assert max(abs(a - b) for x, y in zip(source_bounds, restored_bounds) for a, b in zip(x, y)) < 0.000001
    # Inspect the actual reimported portable file, not the richer source graph.
    scene = bpy.context.scene
    center = (Vector(restored_bounds[0]) + Vector(restored_bounds[1])) / 2
    radius = (Vector(restored_bounds[1]) - Vector(restored_bounds[0])).length / 2
    camera_data = bpy.data.cameras.new("Export inspection")
    camera = bpy.data.objects.new("Export inspection", camera_data)
    scene.collection.objects.link(camera)
    camera.location = center + Vector((0.3, -0.8, 0.8)).normalized() * radius * 3
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type, camera_data.ortho_scale = "ORTHO", radius * 2.3
    camera_data.clip_start = max(radius * 0.01, 0.00001)
    camera_data.clip_end = max(radius * 10, 1)
    scene.camera = camera
    light = bpy.data.lights.new("Softbox", "AREA")
    light.energy, light.size = 45, 0.7
    lamp = bpy.data.objects.new("Softbox", light)
    scene.collection.objects.link(lamp)
    lamp.location = center + Vector((-0.4, -0.5, 0.6))
    lamp.rotation_euler = (center - lamp.location).to_track_quat("-Z", "Y").to_euler()
    scene.world = bpy.data.worlds.new("Review world")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.18, 0.21, 0.25, 1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.3
    scene.render.engine, scene.cycles.device = "CYCLES", "CPU"
    scene.cycles.samples, scene.cycles.time_limit = 16, 30
    scene.cycles.use_denoising = True
    scene.render.threads_mode, scene.render.threads = "FIXED", 2
    scene.render.resolution_x, scene.render.resolution_y = 640, 512
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "AgX"
    scene.render.filepath = str(destination / "reimport.png")
    bpy.ops.render.render(write_still=True)
    receipt = {"source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
               "glb_sha256": hashlib.sha256(raw).hexdigest(), "mesh": mesh_name,
               "texture_size": 512, "triangles": source_triangles, "bytes": len(raw),
               "world_bounds": restored_bounds,
               "geometry_audit": geometry_receipt,
               "device": "CPU", "threads": 2, "native_reimport": "passed",
               "limitations": ["single shared-mesh pilot", "subsurface and independent coat IOR omitted", "engine parity not tested",
                               "UV packing not formally overlap-certified"]}
    (destination / "receipt.json").write_text(json.dumps(receipt, indent=2), encoding="utf8")
    print("SCENE_FORGE_BAKED_ASSET_PASS", json.dumps(receipt))


if __name__ == "__main__":
    main()
