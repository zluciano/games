"""
Blender Python script to create a stylized fountain.
Run with: blender --background --python create_fountain.py
"""
import bpy
import bmesh
import math
import os

def clear_scene():
    """Remove all objects from scene"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

def create_material(name, color, metallic=0.0, roughness=0.8):
    """Create a simple material with given color"""
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat

def create_fountain():
    """Create an ornate fountain"""
    clear_scene()

    # Materials
    mat_stone = create_material("Stone", (0.85, 0.83, 0.8), metallic=0.05, roughness=0.9)
    mat_water = create_material("Water", (0.3, 0.5, 0.7), metallic=0.0, roughness=0.1)
    mat_gold = create_material("GoldAccent", (0.85, 0.7, 0.3), metallic=0.8, roughness=0.3)

    all_objects = []

    # Base pool - outer ring
    bpy.ops.mesh.primitive_cylinder_add(radius=8, depth=1.5, vertices=32, location=(0, 0, 0.75))
    base_outer = bpy.context.active_object
    base_outer.name = "FountainBaseOuter"

    # Add bevel for softer edges
    bevel = base_outer.modifiers.new(name="Bevel", type='BEVEL')
    bevel.width = 0.15
    bevel.segments = 3
    bpy.ops.object.modifier_apply(modifier="Bevel")
    base_outer.data.materials.append(mat_stone)
    all_objects.append(base_outer)

    # Base pool - inner (water surface)
    bpy.ops.mesh.primitive_cylinder_add(radius=7, depth=0.3, vertices=32, location=(0, 0, 1.2))
    water = bpy.context.active_object
    water.name = "FountainWater"
    water.data.materials.append(mat_water)
    all_objects.append(water)

    # Decorative rim
    bpy.ops.mesh.primitive_torus_add(
        major_radius=8,
        minor_radius=0.25,
        major_segments=32,
        minor_segments=12,
        location=(0, 0, 1.5)
    )
    rim = bpy.context.active_object
    rim.name = "FountainRim"
    rim.data.materials.append(mat_gold)
    all_objects.append(rim)

    # Central pillar base
    bpy.ops.mesh.primitive_cylinder_add(radius=1.5, depth=0.8, vertices=8, location=(0, 0, 1.6))
    pillar_base = bpy.context.active_object
    pillar_base.name = "PillarBase"

    bevel = pillar_base.modifiers.new(name="Bevel", type='BEVEL')
    bevel.width = 0.1
    bevel.segments = 2
    bpy.ops.object.modifier_apply(modifier="Bevel")
    pillar_base.data.materials.append(mat_stone)
    all_objects.append(pillar_base)

    # Central pillar shaft
    bpy.ops.mesh.primitive_cylinder_add(radius=0.8, depth=4, vertices=12, location=(0, 0, 4))
    pillar = bpy.context.active_object
    pillar.name = "PillarShaft"
    pillar.data.materials.append(mat_stone)
    all_objects.append(pillar)

    # Upper bowl
    bpy.ops.mesh.primitive_cylinder_add(radius=2.5, depth=1.2, vertices=24, location=(0, 0, 6.6))
    upper_bowl = bpy.context.active_object
    upper_bowl.name = "UpperBowl"

    # Taper the bowl
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='DESELECT')
    bm = bmesh.from_edit_mesh(upper_bowl.data)

    for v in bm.verts:
        if v.co.z < 0:  # Bottom verts
            v.co.x *= 0.6
            v.co.y *= 0.6

    bmesh.update_edit_mesh(upper_bowl.data)
    bpy.ops.object.mode_set(mode='OBJECT')

    bevel = upper_bowl.modifiers.new(name="Bevel", type='BEVEL')
    bevel.width = 0.08
    bevel.segments = 2
    bpy.ops.object.modifier_apply(modifier="Bevel")
    upper_bowl.data.materials.append(mat_stone)
    all_objects.append(upper_bowl)

    # Upper bowl water
    bpy.ops.mesh.primitive_cylinder_add(radius=2.2, depth=0.2, vertices=24, location=(0, 0, 7.0))
    upper_water = bpy.context.active_object
    upper_water.name = "UpperWater"
    upper_water.data.materials.append(mat_water)
    all_objects.append(upper_water)

    # Top ornament - sphere
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, segments=16, ring_count=12, location=(0, 0, 8.2))
    orb = bpy.context.active_object
    orb.name = "TopOrb"
    orb.data.materials.append(mat_gold)
    all_objects.append(orb)

    # Decorative spouts around the base (4 positions)
    for i in range(4):
        angle = math.pi/4 + i * math.pi/2
        x = math.cos(angle) * 6.5
        y = math.sin(angle) * 6.5

        bpy.ops.mesh.primitive_cone_add(
            radius1=0.4,
            radius2=0.1,
            depth=0.8,
            vertices=8,
            location=(x, y, 1.8)
        )
        spout = bpy.context.active_object
        spout.name = f"Spout_{i}"
        # Rotate to point outward
        spout.rotation_euler = (math.pi/2, 0, angle + math.pi)
        spout.data.materials.append(mat_gold)
        all_objects.append(spout)

    # Join all objects
    bpy.ops.object.select_all(action='DESELECT')
    for obj in all_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = all_objects[0]
    bpy.ops.object.join()

    final = bpy.context.active_object
    final.name = "Fountain"

    # Center and apply transforms
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    final.location = (0, 0, 0)

    return final

def export_gltf(filepath):
    """Export scene to glTF"""
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format='GLB',
        export_materials='EXPORT',
        use_selection=True
    )

if __name__ == "__main__":
    fountain = create_fountain()

    bpy.ops.object.select_all(action='DESELECT')
    fountain.select_set(True)

    output_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    output_path = os.path.join(output_dir, "assets", "models", "props", "fountain.glb")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    export_gltf(output_path)
    print(f"Exported to: {output_path}")
