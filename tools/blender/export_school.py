#!/usr/bin/env python3
"""
Export the Haruhi School model to GLB format.
Run with: blender "path/to/file.blend" --background --python export_school.py
"""

import bpy
import os

def export_to_glb():
    output_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    output_path = os.path.join(output_dir, "assets", "models", "buildings", "anime_school.glb")

    # Ensure directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    print(f"Exporting to: {output_path}")

    # Select all mesh objects
    bpy.ops.object.select_all(action='SELECT')

    # Export as GLB
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_materials='EXPORT'
    )

    print(f"Export complete: {output_path}")

if __name__ == "__main__":
    export_to_glb()
