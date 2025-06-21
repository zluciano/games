ASSET DOWNLOAD INSTRUCTIONS
============================

Download free 3D models from these sources and place them in the appropriate folders:

RECOMMENDED SOURCES:
- Quaternius (https://quaternius.com/) - Free stylized game assets
- Poly Pizza (https://poly.pizza/) - 10,500+ free low poly models
- Sketchfab (https://sketchfab.com/) - Many free downloadable models
- itch.io (https://itch.io/game-assets/free/tag-3d) - Indie game assets

FOLDER STRUCTURE:
- trees/      - Tree and plant models (.glb, .gltf)
- buildings/  - Building and structure models
- props/      - Furniture, decorations, signs, etc.
- characters/ - Character models (NPCs, etc.)

SUPPORTED FORMATS:
- .glb (recommended - binary glTF)
- .gltf (text glTF with separate files)
- .obj (with .mtl)
- .fbx (may need import settings)

HOW TO USE:
1. Download model (preferably .glb format)
2. Place in appropriate subfolder
3. In Godot, the model will auto-import
4. Use AssetPlacer script to place in scenes:

   var placer = AssetPlacer.new()
   placer.model_path = "res://assets/models/trees/my_tree.glb"
   placer.apply_toon_material = true
   placer.toon_material = preload("res://materials/toon_leaves.tres")
   add_child(placer)

Or batch place:
   AssetPlacer.place_models_at_positions(
       self,
       "res://assets/models/trees/tree.glb",
       [Vector3(10, 0, 5), Vector3(-10, 0, 5)],
       toon_material
   )

RECOMMENDED DOWNLOADS FOR THIS PROJECT:
1. Quaternius "Stylized Nature MegaKit" - trees, bushes, flowers
2. Quaternius "Ultimate Furniture Pack" - for interior scenes
3. Low poly school building from Sketchfab
4. Anime/stylized character bases
