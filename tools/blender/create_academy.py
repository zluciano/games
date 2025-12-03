"""
Blender Python script to create a stylized Duel Academy building.
Run with: blender --background --python create_academy.py
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

def create_building_base(width, height, depth, name="BuildingBase"):
    """Create the main building body with window indents"""
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, height/2))
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = (width, depth, height)
    bpy.ops.object.transform_apply(scale=True)

    # Add bevel for softer edges
    bevel = obj.modifiers.new(name="Bevel", type='BEVEL')
    bevel.width = 0.1
    bevel.segments = 2
    bpy.ops.object.modifier_apply(modifier="Bevel")

    return obj

def create_windows_row(building_width, building_depth, y_pos, num_windows=8, window_height=2.5, window_width=1.8):
    """Create a row of window indents using boolean operations"""
    windows = []
    spacing = (building_width - 4) / (num_windows + 1)

    for i in range(num_windows):
        x = -building_width/2 + 2 + spacing * (i + 1)

        # Front window
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, building_depth/2 + 0.3, y_pos))
        window = bpy.context.active_object
        window.scale = (window_width, 0.8, window_height)
        windows.append(window)

        # Back window
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, -building_depth/2 - 0.3, y_pos))
        window = bpy.context.active_object
        window.scale = (window_width, 0.8, window_height)
        windows.append(window)

    return windows

def create_dome(radius, height, segments=32, location=(0, 0, 0)):
    """Create a dome/hemisphere"""
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=radius,
        segments=segments,
        ring_count=16,
        location=location
    )
    dome = bpy.context.active_object
    dome.name = "Dome"

    # Cut bottom half
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='DESELECT')
    bm = bmesh.from_edit_mesh(dome.data)

    for v in bm.verts:
        if v.co.z < 0:
            v.select = True

    bmesh.update_edit_mesh(dome.data)
    bpy.ops.mesh.delete(type='VERT')
    bpy.ops.object.mode_set(mode='OBJECT')

    # Scale to make it more dome-like
    dome.scale.z = height / radius
    bpy.ops.object.transform_apply(scale=True)

    return dome

def create_dome_ring(inner_radius, outer_radius, height, location, segments=32):
    """Create a ring/collar for the dome"""
    bpy.ops.mesh.primitive_cylinder_add(
        radius=outer_radius,
        depth=height,
        vertices=segments,
        location=location
    )
    outer = bpy.context.active_object
    outer.name = "DomeRing"

    # Create inner cutout
    bpy.ops.mesh.primitive_cylinder_add(
        radius=inner_radius,
        depth=height + 0.2,
        vertices=segments,
        location=location
    )
    inner = bpy.context.active_object

    # Boolean difference
    bool_mod = outer.modifiers.new(name="Boolean", type='BOOLEAN')
    bool_mod.operation = 'DIFFERENCE'
    bool_mod.object = inner
    bpy.context.view_layer.objects.active = outer
    bpy.ops.object.modifier_apply(modifier="Boolean")

    # Delete inner
    bpy.data.objects.remove(inner)

    return outer

def create_pillar(radius, height, location, segments=12):
    """Create a classical pillar"""
    # Main shaft
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius,
        depth=height,
        vertices=segments,
        location=(location[0], location[1], location[2] + height/2)
    )
    shaft = bpy.context.active_object
    shaft.name = "PillarShaft"

    # Base
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius * 1.3,
        depth=height * 0.08,
        vertices=segments,
        location=(location[0], location[1], location[2] + height * 0.04)
    )
    base = bpy.context.active_object

    # Capital
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius * 1.4,
        depth=height * 0.1,
        vertices=segments,
        location=(location[0], location[1], location[2] + height - height * 0.05)
    )
    capital = bpy.context.active_object

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    shaft.select_set(True)
    base.select_set(True)
    capital.select_set(True)
    bpy.context.view_layer.objects.active = shaft
    bpy.ops.object.join()

    return shaft

def create_trim(width, depth, height, thickness, y_offset):
    """Create decorative trim/molding"""
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, height))
    trim = bpy.context.active_object
    trim.name = "Trim"
    trim.scale = (width + thickness*2, depth + thickness*2, thickness)
    bpy.ops.object.transform_apply(scale=True)

    # Add bevel
    bevel = trim.modifiers.new(name="Bevel", type='BEVEL')
    bevel.width = 0.05
    bevel.segments = 2
    bpy.ops.object.modifier_apply(modifier="Bevel")

    return trim

def create_colored_dome_small(radius, color_name, location):
    """Create a small colored dome (for Ra Yellow, Slifer Red, Obelisk Blue)"""
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=radius,
        segments=24,
        ring_count=12,
        location=location
    )
    dome = bpy.context.active_object
    dome.name = f"Dome_{color_name}"
    dome.scale.z = 0.7
    bpy.ops.object.transform_apply(scale=True)
    return dome

def create_academy_building():
    """Main function to create the complete academy building"""
    clear_scene()

    # Materials
    mat_wall = create_material("Wall", (0.92, 0.9, 0.85), metallic=0.0, roughness=0.9)
    mat_metal = create_material("Metal", (0.7, 0.72, 0.75), metallic=0.3, roughness=0.4)
    mat_gold = create_material("Gold", (0.85, 0.7, 0.3), metallic=0.8, roughness=0.3)
    mat_red = create_material("SliferRed", (0.8, 0.15, 0.1), metallic=0.1, roughness=0.5)
    mat_yellow = create_material("RaYellow", (0.95, 0.8, 0.2), metallic=0.1, roughness=0.5)
    mat_blue = create_material("ObeliskBlue", (0.1, 0.3, 0.7), metallic=0.1, roughness=0.5)
    mat_window = create_material("Window", (0.2, 0.3, 0.4), metallic=0.0, roughness=0.1)

    all_objects = []

    # Main building - Tier 1 (base)
    base = create_building_base(55, 14, 35, "Academy_Base")
    base.data.materials.append(mat_wall)
    all_objects.append(base)

    # Tier 2
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 14 + 4))
    tier2 = bpy.context.active_object
    tier2.name = "Academy_Tier2"
    tier2.scale = (45, 28, 8)
    bpy.ops.object.transform_apply(scale=True)
    tier2.data.materials.append(mat_metal)
    all_objects.append(tier2)

    # Add trim between tiers
    trim1 = create_trim(55, 35, 14, 0.5, 0)
    trim1.data.materials.append(mat_metal)
    all_objects.append(trim1)

    trim2 = create_trim(45, 28, 22, 0.4, 0)
    trim2.data.materials.append(mat_metal)
    all_objects.append(trim2)

    # Tier 3
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 22 + 3))
    tier3 = bpy.context.active_object
    tier3.name = "Academy_Tier3"
    tier3.scale = (35, 22, 6)
    bpy.ops.object.transform_apply(scale=True)
    tier3.data.materials.append(mat_metal)
    all_objects.append(tier3)

    # Main dome structure - rings
    ring1 = create_dome_ring(14, 18, 3, (0, 0, 28 + 1.5))
    ring1.data.materials.append(mat_metal)
    all_objects.append(ring1)

    ring2 = create_dome_ring(11, 14, 3, (0, 0, 31 + 1.5))
    ring2.data.materials.append(mat_metal)
    all_objects.append(ring2)

    ring3 = create_dome_ring(7, 11, 3.5, (0, 0, 34 + 1.75))
    ring3.data.materials.append(mat_metal)
    all_objects.append(ring3)

    # Main dome cap
    main_dome = create_dome(10, 10, 32, (0, 0, 38))
    main_dome.data.materials.append(mat_metal)
    all_objects.append(main_dome)

    # Colored domes (Ra Yellow, Slifer Red, Obelisk Blue)
    dome_yellow = create_colored_dome_small(5.5, "RaYellow", (-12, 10, 24))
    dome_yellow.data.materials.append(mat_yellow)
    all_objects.append(dome_yellow)

    dome_red = create_colored_dome_small(5.5, "SliferRed", (0, 14, 24))
    dome_red.data.materials.append(mat_red)
    all_objects.append(dome_red)

    dome_blue = create_colored_dome_small(5.5, "ObeliskBlue", (12, 10, 24))
    dome_blue.data.materials.append(mat_blue)
    all_objects.append(dome_blue)

    # Front pillars
    pillar_positions = [(-14, 16, 0), (-8, 18, 0), (8, 18, 0), (14, 16, 0)]
    for i, pos in enumerate(pillar_positions):
        pillar = create_pillar(2.0, 18, pos)
        pillar.name = f"Pillar_{i}"
        pillar.data.materials.append(mat_metal)
        all_objects.append(pillar)

    # Entrance steps
    for i in range(4):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 17 + i*2.5, 0.6 + i*1.2))
        step = bpy.context.active_object
        step.name = f"Step_{i}"
        step.scale = (28, 5, 1.2)
        bpy.ops.object.transform_apply(scale=True)
        step.data.materials.append(mat_wall)
        all_objects.append(step)

    # Join all objects
    bpy.ops.object.select_all(action='DESELECT')
    for obj in all_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = all_objects[0]
    bpy.ops.object.join()

    final = bpy.context.active_object
    final.name = "DuelAcademy"

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
    # Create the academy building
    academy = create_academy_building()

    # Select for export
    bpy.ops.object.select_all(action='DESELECT')
    academy.select_set(True)

    # Export
    output_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    output_path = os.path.join(output_dir, "assets", "models", "buildings", "duel_academy.glb")

    # Create output directory if needed
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    export_gltf(output_path)
    print(f"Exported to: {output_path}")
