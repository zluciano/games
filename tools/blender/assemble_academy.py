"""
Blender Python script to assemble Kenney modular pieces into a grand academy building.
Run with: blender --background --python assemble_academy.py
"""
import bpy
import math
import os

def clear_scene():
    """Remove all objects from scene"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

def import_glb(filepath, name_prefix=""):
    """Import a GLB file and return the imported objects"""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=filepath)
    after = set(bpy.data.objects)
    imported = list(after - before)
    for i, obj in enumerate(imported):
        obj.name = f"{name_prefix}_{obj.name}" if name_prefix else obj.name
    return imported

def create_material(name, color, metallic=0.0, roughness=0.5):
    """Create a simple material"""
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat

def create_dome(radius, location, color):
    """Create a colored dome - location is (X, Y_forward, Z_up) in Blender coords"""
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=radius,
        segments=24,
        ring_count=12,
        location=location
    )
    dome = bpy.context.active_object
    dome.scale.z = 0.6
    bpy.ops.object.transform_apply(scale=True)

    # Cut bottom half
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='DESELECT')
    import bmesh
    bm = bmesh.from_edit_mesh(dome.data)
    for v in bm.verts:
        if v.co.z < 0:
            v.select = True
    bmesh.update_edit_mesh(dome.data)
    bpy.ops.mesh.delete(type='VERT')
    bpy.ops.object.mode_set(mode='OBJECT')

    mat = create_material(f"Dome_{color[0]}", color, metallic=0.2, roughness=0.4)
    dome.data.materials.append(mat)
    return dome

def assemble_academy():
    """Assemble a grand academy building from modular pieces"""
    clear_scene()

    project_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    kenney_dir = os.path.join(project_dir, "assets", "models", "buildings", "kenney")

    all_objects = []

    # Main scale factor - make buildings bigger
    SCALE = 4.0

    # Import and arrange tower samples for the main structure
    tower_a_path = os.path.join(kenney_dir, "building-sample-tower-a.glb")
    tower_b_path = os.path.join(kenney_dir, "building-sample-tower-b.glb")
    tower_c_path = os.path.join(kenney_dir, "building-sample-tower-c.glb")
    house_path = os.path.join(kenney_dir, "building-sample-house-c.glb")

    if os.path.exists(tower_a_path):
        # Center main tower - tallest
        center_tower = import_glb(tower_a_path, "center")
        for obj in center_tower:
            obj.location = (0, 0, 0)
            obj.scale = (SCALE * 1.2, SCALE * 1.2, SCALE * 1.5)
        all_objects.extend(center_tower)

        # Side towers - slightly shorter
        left_tower = import_glb(tower_a_path, "left")
        for obj in left_tower:
            obj.location = (-12 * SCALE / 3, 0, 0)
            obj.scale = (SCALE, SCALE, SCALE * 1.2)
        all_objects.extend(left_tower)

        right_tower = import_glb(tower_a_path, "right")
        for obj in right_tower:
            obj.location = (12 * SCALE / 3, 0, 0)
            obj.scale = (SCALE, SCALE, SCALE * 1.2)
        all_objects.extend(right_tower)

    if os.path.exists(tower_b_path):
        # Outer towers
        far_left = import_glb(tower_b_path, "far_left")
        for obj in far_left:
            obj.location = (-20 * SCALE / 3, 0, 0)
            obj.scale = (SCALE * 0.9, SCALE * 0.9, SCALE)
        all_objects.extend(far_left)

        far_right = import_glb(tower_b_path, "far_right")
        for obj in far_right:
            obj.location = (20 * SCALE / 3, 0, 0)
            obj.scale = (SCALE * 0.9, SCALE * 0.9, SCALE)
        all_objects.extend(far_right)

    if os.path.exists(house_path):
        # Wing buildings - connect the towers
        left_wing = import_glb(house_path, "wing_left")
        for obj in left_wing:
            obj.location = (-6 * SCALE / 3, 0, 0)
            obj.scale = (SCALE * 0.8, SCALE * 0.8, SCALE * 0.7)
        all_objects.extend(left_wing)

        right_wing = import_glb(house_path, "wing_right")
        for obj in right_wing:
            obj.location = (6 * SCALE / 3, 0, 0)
            obj.scale = (SCALE * 0.8, SCALE * 0.8, SCALE * 0.7)
        all_objects.extend(right_wing)

    # Add colored domes on TOP of the towers (Z is up in Blender)
    # Kenney towers are about 4 units tall, scaled by SCALE*1.2 = ~19 units
    tower_top_z = 4 * SCALE * 1.2  # About 19 units

    # Ra Yellow dome - on left tower
    dome_yellow = create_dome(2.5 * SCALE / 3, (-12 * SCALE / 3, 0, tower_top_z * 0.9), (0.95, 0.8, 0.2))
    dome_yellow.name = "Dome_RaYellow"
    all_objects.append(dome_yellow)

    # Slifer Red dome - on center tower (tallest)
    dome_red = create_dome(3 * SCALE / 3, (0, 0, tower_top_z * 1.1), (0.85, 0.15, 0.1))
    dome_red.name = "Dome_SliferRed"
    all_objects.append(dome_red)

    # Obelisk Blue dome - on right tower
    dome_blue = create_dome(2.5 * SCALE / 3, (12 * SCALE / 3, 0, tower_top_z * 0.9), (0.15, 0.35, 0.75))
    dome_blue.name = "Dome_ObeliskBlue"
    all_objects.append(dome_blue)

    # Create entrance steps (in front, Y is forward in Blender)
    mat_stone = create_material("Stone", (0.75, 0.73, 0.7), metallic=0.05, roughness=0.85)

    for i in range(4):
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 4 + i * 1.5, 0.3 + i * 0.4)
        )
        step = bpy.context.active_object
        step.name = f"Step_{i}"
        step.scale = (15 - i * 1.5, 2, 0.5)
        bpy.ops.object.transform_apply(scale=True)
        step.data.materials.append(mat_stone)
        all_objects.append(step)

    return all_objects

def export_gltf(filepath):
    """Export scene to glTF"""
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format='GLB',
        export_materials='EXPORT',
        use_selection=False
    )

if __name__ == "__main__":
    objects = assemble_academy()

    output_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    output_path = os.path.join(output_dir, "assets", "models", "buildings", "academy_assembled.glb")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    export_gltf(output_path)
    print(f"Exported to: {output_path}")
