#!/usr/bin/env python3
"""
Create a proper Duel Academy building for Yu-Gi-Oh GX game.

The Duel Academy is characterized by:
- Large white/cream colored main building
- Central tower structure
- Three prominent colored domes (Obelisk Blue, Ra Yellow, Slifer Red)
- Grand entrance with steps
- Overall imposing, institutional architecture

Run with: blender --background --python create_duel_academy.py
"""

import bpy
import math
import os

def clear_scene():
    """Remove all objects from the scene."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

def create_material(name: str, color: tuple, metallic: float = 0.0, roughness: float = 0.5) -> bpy.types.Material:
    """Create a material with the given color."""
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat

def add_cube(name: str, location: tuple, scale: tuple, material: bpy.types.Material) -> bpy.types.Object:
    """Add a cube with given parameters."""
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    return obj

def add_cylinder(name: str, location: tuple, radius: float, depth: float, material: bpy.types.Material) -> bpy.types.Object:
    """Add a cylinder with given parameters."""
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.data.materials.append(material)
    return obj

def add_dome(name: str, location: tuple, radius: float, material: bpy.types.Material) -> bpy.types.Object:
    """Add a hemisphere dome."""
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location, segments=32, ring_count=16)
    obj = bpy.context.active_object
    obj.name = name

    # Cut the bottom half to make a dome
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='DESELECT')
    bpy.ops.object.mode_set(mode='OBJECT')

    # Select vertices below center
    mesh = obj.data
    for vert in mesh.vertices:
        if vert.co.z < 0:
            vert.select = True

    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.delete(type='VERT')
    bpy.ops.object.mode_set(mode='OBJECT')

    obj.data.materials.append(material)
    return obj

def create_duel_academy():
    """Create the main Duel Academy building."""

    # Materials
    mat_white = create_material("Academy_White", (0.95, 0.93, 0.88), roughness=0.6)
    mat_cream = create_material("Academy_Cream", (0.92, 0.88, 0.78), roughness=0.7)
    mat_gray = create_material("Academy_Gray", (0.7, 0.7, 0.72), roughness=0.5)
    mat_dark = create_material("Academy_Dark", (0.3, 0.3, 0.32), roughness=0.4)
    mat_gold = create_material("Academy_Gold", (0.85, 0.7, 0.3), metallic=0.6, roughness=0.3)

    # Dome colors for the three dorms
    mat_blue = create_material("Dome_ObeliskBlue", (0.15, 0.35, 0.75), roughness=0.4)
    mat_yellow = create_material("Dome_RaYellow", (0.95, 0.8, 0.2), roughness=0.4)
    mat_red = create_material("Dome_SliferRed", (0.85, 0.15, 0.1), roughness=0.4)

    # Window material
    mat_window = create_material("Academy_Window", (0.3, 0.4, 0.5), metallic=0.1, roughness=0.1)

    objects = []

    # === MAIN BUILDING BASE ===
    # Central main block
    main_base = add_cube("MainBase", (0, 0, 4), (15, 8, 4), mat_white)
    objects.append(main_base)

    # Second tier (stepped back)
    tier2 = add_cube("Tier2", (0, 0, 10), (12, 6, 2), mat_white)
    objects.append(tier2)

    # === CENTRAL TOWER ===
    # Main tower body
    tower_base = add_cylinder("TowerBase", (0, 0, 6), 4, 12, mat_white)
    objects.append(tower_base)

    # Tower upper section
    tower_mid = add_cylinder("TowerMid", (0, 0, 14), 3.5, 4, mat_cream)
    objects.append(tower_mid)

    # Tower top section
    tower_top = add_cylinder("TowerTop", (0, 0, 18), 3, 4, mat_white)
    objects.append(tower_top)

    # Central dome base ring
    dome_ring = add_cylinder("CentralDomeRing", (0, 0, 20.5), 3.5, 1, mat_gold)
    objects.append(dome_ring)

    # Central large dome (Gold/Main Academy)
    central_dome = add_dome("CentralDome", (0, 0, 21), 3.2, mat_gold)
    objects.append(central_dome)

    # === WING BUILDINGS ===
    # Left wing
    left_wing = add_cube("LeftWing", (-18, 0, 3.5), (6, 6, 3.5), mat_white)
    objects.append(left_wing)

    left_wing_top = add_cube("LeftWingTop", (-18, 0, 8.5), (5, 5, 1.5), mat_cream)
    objects.append(left_wing_top)

    # Right wing
    right_wing = add_cube("RightWing", (18, 0, 3.5), (6, 6, 3.5), mat_white)
    objects.append(right_wing)

    right_wing_top = add_cube("RightWingTop", (18, 0, 8.5), (5, 5, 1.5), mat_cream)
    objects.append(right_wing_top)

    # === CONNECTING CORRIDORS ===
    left_corridor = add_cube("LeftCorridor", (-9, 0, 2.5), (3, 3, 2.5), mat_cream)
    objects.append(left_corridor)

    right_corridor = add_cube("RightCorridor", (9, 0, 2.5), (3, 3, 2.5), mat_cream)
    objects.append(right_corridor)

    # === THREE DORM TOWERS WITH COLORED DOMES ===

    # OBELISK BLUE - Right tower (highest rank, tallest)
    blue_tower = add_cylinder("BlueTower", (18, 0, 12), 2.5, 6, mat_white)
    objects.append(blue_tower)

    blue_tower_top = add_cylinder("BlueTowerTop", (18, 0, 16), 2.2, 2, mat_cream)
    objects.append(blue_tower_top)

    blue_dome_ring = add_cylinder("BlueDomeRing", (18, 0, 17.5), 2.5, 0.5, mat_gray)
    objects.append(blue_dome_ring)

    blue_dome = add_dome("BlueDome_ObeliskBlue", (18, 0, 18), 2.3, mat_blue)
    objects.append(blue_dome)

    # RA YELLOW - Center-left tower (middle rank)
    yellow_tower = add_cylinder("YellowTower", (-8, -6, 10), 2, 6, mat_white)
    objects.append(yellow_tower)

    yellow_tower_top = add_cylinder("YellowTowerTop", (-8, -6, 14), 1.8, 2, mat_cream)
    objects.append(yellow_tower_top)

    yellow_dome_ring = add_cylinder("YellowDomeRing", (-8, -6, 15.5), 2, 0.5, mat_gray)
    objects.append(yellow_dome_ring)

    yellow_dome = add_dome("YellowDome_RaYellow", (-8, -6, 16), 1.9, mat_yellow)
    objects.append(yellow_dome)

    # SLIFER RED - Left tower (lowest rank, smallest)
    red_tower = add_cylinder("RedTower", (-18, 0, 11), 2, 4, mat_white)
    objects.append(red_tower)

    red_tower_top = add_cylinder("RedTowerTop", (-18, 0, 14), 1.7, 1.5, mat_cream)
    objects.append(red_tower_top)

    red_dome_ring = add_cylinder("RedDomeRing", (-18, 0, 15.25), 1.9, 0.5, mat_gray)
    objects.append(red_dome_ring)

    red_dome = add_dome("RedDome_SliferRed", (-18, 0, 15.5), 1.7, mat_red)
    objects.append(red_dome)

    # === ENTRANCE ===
    # Grand entrance portico
    entrance_base = add_cube("EntranceBase", (0, 10, 2), (5, 2, 2), mat_cream)
    objects.append(entrance_base)

    # Entrance columns
    for i, x in enumerate([-3.5, -1.5, 1.5, 3.5]):
        col = add_cylinder(f"EntranceColumn{i}", (x, 11, 3), 0.5, 6, mat_white)
        objects.append(col)

    # Entrance roof/pediment
    entrance_roof = add_cube("EntranceRoof", (0, 11, 6.5), (5.5, 2, 0.5), mat_gray)
    objects.append(entrance_roof)

    # === ENTRANCE STEPS ===
    for i in range(4):
        step = add_cube(f"Step{i}", (0, 13 + i * 1.2, 0.2 - i * 0.4), (6 - i * 0.3, 0.6, 0.2), mat_gray)
        objects.append(step)

    # === WINDOWS (decorative) ===
    # Main building windows
    for i in range(5):
        for j in range(2):
            x_pos = -10 + i * 5
            z_pos = 3 + j * 3
            win = add_cube(f"Window_{i}_{j}", (x_pos, 8.1, z_pos), (0.8, 0.05, 1), mat_window)
            objects.append(win)

    # === ROOF DETAILS ===
    # Decorative trim on main building
    roof_trim = add_cube("RoofTrim", (0, 0, 8.2), (15.2, 8.2, 0.2), mat_gray)
    objects.append(roof_trim)

    # === JOIN ALL OBJECTS ===
    # Select all objects
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)

    # Set active object
    bpy.context.view_layer.objects.active = objects[0]

    # Join all objects
    bpy.ops.object.join()

    # Rename the joined object
    academy = bpy.context.active_object
    academy.name = "DuelAcademy"

    # Center origin
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')

    # Move to ground level
    academy.location = (0, 0, 0)

    return academy

def export_glb(filepath: str):
    """Export the scene as GLB."""
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_materials='EXPORT'
    )

def main():
    clear_scene()

    print("Creating Duel Academy...")
    academy = create_duel_academy()

    # Export path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(os.path.dirname(script_dir))
    output_path = os.path.join(project_dir, "assets", "models", "buildings", "duel_academy.glb")

    # Ensure directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    print(f"Exporting to: {output_path}")
    export_glb(output_path)

    print("Done! Duel Academy created successfully.")

if __name__ == "__main__":
    main()
