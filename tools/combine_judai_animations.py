"""
Blender Script: Combine Judai model with Mixamo animations

HOW TO USE:
1. Open Blender
2. Go to the "Scripting" tab at the top
3. Click "New" to create a new script
4. Paste this entire script
5. Click the "Run Script" button (play icon)
6. The animated GLB will be saved to your Downloads folder

This script:
1. Imports the base Judai model
2. Imports all animation FBX files
3. Exports as a single GLB with all animations
"""

import bpy
import os
from pathlib import Path

# Configuration - UPDATE THESE PATHS IF NEEDED
DOWNLOADS_PATH = "/Users/joselucianodemoraisneto/Downloads"
BASE_MODEL = os.path.join(DOWNLOADS_PATH, "Judai", "Judai.fbx")
OUTPUT_PATH = os.path.join(DOWNLOADS_PATH, "Judai_Animated.glb")

# Animation files to import - add/remove as needed
ANIMATION_FILES = [
    "Idle.fbx",
    "Slow Run.fbx",
]

def clear_scene():
    """Clear all objects from the scene"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    # Clear orphan data
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.armatures:
        if block.users == 0:
            bpy.data.armatures.remove(block)
    for block in bpy.data.actions:
        if block.users == 0:
            bpy.data.actions.remove(block)

def import_base_model():
    """Import the base character model"""
    print(f"Importing base model: {BASE_MODEL}")
    if not os.path.exists(BASE_MODEL):
        print(f"ERROR: Base model not found at {BASE_MODEL}")
        print("Make sure you have Judai/Judai.fbx in your Downloads folder")
        return None

    bpy.ops.import_scene.fbx(filepath=BASE_MODEL)

    # Find the armature
    armature = None
    for obj in bpy.context.selected_objects:
        if obj.type == 'ARMATURE':
            armature = obj
            break

    if not armature:
        for obj in bpy.data.objects:
            if obj.type == 'ARMATURE':
                armature = obj
                break

    if not armature:
        print("WARNING: No armature found in base model")
        return None

    # Remove vertex colors from all meshes (fixes sepia/green tint)
    print("Removing vertex colors from meshes...")
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            mesh = obj.data
            # Remove all vertex color layers
            while mesh.vertex_colors:
                mesh.vertex_colors.remove(mesh.vertex_colors[0])
            # Also remove color attributes (Blender 3.2+)
            if hasattr(mesh, 'color_attributes'):
                while mesh.color_attributes:
                    mesh.color_attributes.remove(mesh.color_attributes[0])

    # IMPORTANT: Clear ALL existing actions from base model
    # This removes any old animations so only our new FBX animations are used
    print("Clearing existing animations from base model...")
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)

    if armature.animation_data:
        armature.animation_data_clear()

    return armature

def import_animation(armature, anim_file, anim_name):
    """Import an animation and add it to the armature"""
    filepath = os.path.join(DOWNLOADS_PATH, anim_file)

    if not os.path.exists(filepath):
        print(f"  Skipping (not found): {anim_file}")
        return False

    print(f"  Importing: {anim_file} -> {anim_name}")

    # Store existing objects, actions, and materials
    existing_objects = set(bpy.data.objects.keys())
    existing_actions = set(bpy.data.actions.keys())
    existing_materials = set(bpy.data.materials.keys())

    # Import the FBX (ignore materials to preserve original colors)
    bpy.ops.import_scene.fbx(filepath=filepath, use_image_search=False)

    # Find new actions
    new_actions = set(bpy.data.actions.keys()) - existing_actions

    # Rename the new action
    for action_name in new_actions:
        action = bpy.data.actions[action_name]
        action.name = anim_name
        print(f"    Renamed action to: {anim_name}")

    # Delete ALL imported objects (meshes, armatures, everything)
    new_objects = set(bpy.data.objects.keys()) - existing_objects
    for obj_name in new_objects:
        if obj_name in bpy.data.objects:
            obj = bpy.data.objects[obj_name]
            bpy.data.objects.remove(obj, do_unlink=True)

    # Delete any new materials from Mixamo (keep original Jaden materials)
    new_materials = set(bpy.data.materials.keys()) - existing_materials
    for mat_name in new_materials:
        if mat_name in bpy.data.materials:
            bpy.data.materials.remove(bpy.data.materials[mat_name])

    return len(new_actions) > 0

def push_all_actions_to_nla(armature):
    """Push all actions to NLA tracks so they export properly"""
    if not armature.animation_data:
        armature.animation_data_create()

    for action in bpy.data.actions:
        if action.name == "RESET":
            continue

        # Create NLA track
        track = armature.animation_data.nla_tracks.new()
        track.name = action.name

        # Add the action as a strip
        strip = track.strips.new(action.name, int(action.frame_range[0]), action)
        strip.name = action.name

def export_glb():
    """Export the scene as GLB"""
    print(f"\nExporting to: {OUTPUT_PATH}")

    bpy.ops.object.select_all(action='SELECT')

    bpy.ops.export_scene.gltf(
        filepath=OUTPUT_PATH,
        export_format='GLB',
        export_animations=True,
        export_animation_mode='ACTIONS',
        export_nla_strips=True,
        export_all_influences=True,
        export_skins=True,
        export_image_format='AUTO',
        export_materials='EXPORT',
    )
    print("Export complete!")

def main():
    print("\n" + "="*50)
    print("JUDAI ANIMATION COMBINER")
    print("="*50 + "\n")

    # Clear scene
    print("Clearing scene...")
    clear_scene()

    # Import base model
    armature = import_base_model()
    if not armature:
        print("\nERROR: Failed to import base model!")
        print("Make sure Judai/Judai.fbx exists in Downloads")
        return

    print(f"Base model loaded: {armature.name}\n")

    # Import animations
    print("Importing animations...")
    for anim_file in ANIMATION_FILES:
        anim_name = Path(anim_file).stem
        import_animation(armature, anim_file, anim_name)

    # Push to NLA for proper export
    print("\nPreparing animations for export...")
    push_all_actions_to_nla(armature)

    # List all animations
    print("\nAnimations included:")
    for action in bpy.data.actions:
        if action.name != "RESET":
            print(f"  - {action.name}")

    # Export
    export_glb()

    print("\n" + "="*50)
    print("SUCCESS! Your animated model is at:")
    print(OUTPUT_PATH)
    print("\nCopy this file to your Godot project:")
    print("addons/judai_char/Judai.glb")
    print("="*50 + "\n")

# Run
main()
