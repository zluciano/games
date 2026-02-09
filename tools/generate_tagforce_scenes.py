#!/usr/bin/env python3
"""Generate Godot .tscn scene files for all Tag Force Evolution maps.

Creates a playable scene for each map with:
- TagForceLocation node (loads TMS geometry + textures)
- Player instance
- ThirdPersonCamera
- HUD
- WorldEnvironment (exterior/interior)
- SpawnPoints
- SceneTriggers to connected maps
"""

import os
import sys

# Map registry: (id, display_name, tms_filename, is_interior, connections)
MAPS = [
    ("BG_01_01", "Academy Courtyard", "bg_01_01.tms", False,
     ["BG_01_02", "BG_02_01", "BG_03_01"]),
    ("BG_01_02", "Academy Entrance", "bg_01_02.tms", False,
     ["BG_01_01", "BG_09_01"]),
    ("BG_02_01", "Academy Hallway 1F", "bg_02_01.tms", True,
     ["BG_01_01", "BG_02_02", "BG_02_03", "BG_02_04"]),
    ("BG_02_02", "Academy Hallway 2F", "bg_02_02.tms", True,
     ["BG_02_01", "BG_02_05", "BG_02_06"]),
    ("BG_02_03", "Classroom", "bg_02_03.tms", True,
     ["BG_02_01"]),
    ("BG_02_04", "Card Shop", "bg_02_04.tms", True,
     ["BG_02_01"]),
    ("BG_02_05", "Library", "bg_02_05.tms", True,
     ["BG_02_02"]),
    ("BG_02_06", "Staff Room", "bg_02_06.tms", True,
     ["BG_02_02"]),
    ("BG_02_07", "Chancellor's Office", "bg_02_07.tms", True,
     ["BG_02_02"]),
    ("BG_02_08", "Duel Arena", "bg_02_08.tms", True,
     ["BG_02_01"]),
    ("BG_03_01", "Slifer Red Dorm", "bg_03_01.tms", False,
     ["BG_01_01", "BG_04_01"]),
    ("BG_04_01", "Ra Yellow Dorm", "bg_04_01.tms", False,
     ["BG_03_01", "BG_05_01"]),
    ("BG_05_01", "Obelisk Blue Boys' Dorm", "bg_05_01.tms", False,
     ["BG_04_01", "BG_06_01"]),
    ("BG_06_01", "Obelisk Blue Girls' Dorm", "bg_06_01.tms", False,
     ["BG_05_01"]),
    ("BG_07_01", "Harbor", "bg_07_01.tms", False,
     ["BG_01_01"]),
    ("BG_08_01", "Lighthouse", "bg_08_01.tms", False,
     ["BG_07_01"]),
    ("BG_09_01", "Forest Path", "bg_09_01.tms", False,
     ["BG_01_02", "BG_10_01", "BG_11_01"]),
    ("BG_10_01", "Abandoned Dorm", "bg_10_01.tms", False,
     ["BG_09_01"]),
    ("BG_11_01", "Volcano", "bg_11_01.tms", False,
     ["BG_09_01"]),
    ("BG_14_01", "Beach", "bg_14_01.tms", False,
     ["BG_01_01"]),
    ("BG_15_01", "Hot Spring", "bg_15_01.tms", False,
     ["BG_14_01"]),
    ("BG_16_01", "Cliff", "bg_16_01.tms", False,
     ["BG_09_01"]),
    ("BG_18_01", "Cave", "bg_18_01.tms", True,
     ["BG_11_01"]),
    ("BG_19_01", "Lake", "bg_19_01.tms", False,
     ["BG_09_01"]),
    ("BG_20_01", "Bridge", "bg_20_01.tms", False,
     ["BG_01_01", "BG_09_01"]),
    ("BG_21_01", "Academy Rooftop", "bg_21_01.tms", False,
     ["BG_02_02"]),
    ("BG_22_01", "Dorm Room (Slifer)", "bg_22_01.tms", True,
     ["BG_03_01"]),
    ("BG_22_02", "Dorm Room (Obelisk)", "bg_22_02.tms", True,
     ["BG_05_01"]),
]

# Map display names for trigger labels
MAP_NAMES = {m[0]: m[1] for m in MAPS}


def exterior_environment():
    """Godot sub_resource for outdoor environment."""
    return """[sub_resource type="ProceduralSkyMaterial" id="sky_mat"]
sky_top_color = Color(0.15, 0.4, 0.85, 1)
sky_horizon_color = Color(0.95, 0.8, 0.6, 1)
sky_curve = 0.12
ground_bottom_color = Color(0.3, 0.45, 0.3, 1)
ground_horizon_color = Color(0.6, 0.65, 0.5, 1)

[sub_resource type="Sky" id="sky"]
sky_material = SubResource("sky_mat")

[sub_resource type="Environment" id="env"]
background_mode = 2
sky = SubResource("sky")
ambient_light_source = 3
ambient_light_color = Color(0.55, 0.65, 0.9, 1)
ambient_light_energy = 0.4
tonemap_mode = 2
ssao_enabled = true
fog_enabled = true
fog_light_color = Color(0.95, 0.9, 0.82, 1)
fog_density = 0.00015"""


def interior_environment():
    """Godot sub_resource for indoor environment."""
    return """[sub_resource type="Environment" id="env"]
background_mode = 1
background_color = Color(0.12, 0.12, 0.15, 1)
ambient_light_source = 3
ambient_light_color = Color(0.8, 0.85, 0.95, 1)
ambient_light_energy = 1.2
tonemap_mode = 2
ssao_enabled = true"""


def trigger_shape():
    """Collision shape for scene triggers."""
    return """[sub_resource type="BoxShape3D" id="trigger_shape"]
size = Vector3(4, 4, 2)"""


def generate_scene(map_id, display_name, tms_filename, is_interior, connections):
    """Generate a complete .tscn file for a Tag Force map."""
    # Count resources needed
    ext_resources = [
        ('Script', 'res://scripts/world/tagforce_location.gd', 'tf_loc'),
        ('PackedScene', 'res://scenes/player/player.tscn', 'player'),
        ('Script', 'res://scripts/camera/third_person_camera.gd', 'camera'),
        ('PackedScene', 'res://scenes/ui/hud.tscn', 'hud'),
        ('Script', 'res://scripts/world/spawn_point.gd', 'spawn'),
        ('Script', 'res://scripts/world/scene_trigger.gd', 'trigger'),
    ]

    load_steps = len(ext_resources) + 5  # ext + sub resources

    lines = []

    # Header
    lines.append(f'[gd_scene load_steps={load_steps} format=3]')
    lines.append('')

    # External resources
    for i, (rtype, path, rid) in enumerate(ext_resources):
        lines.append(f'[ext_resource type="{rtype}" path="{path}" id="{rid}"]')
    lines.append('')

    # Sub-resources (environment + trigger shape)
    if is_interior:
        lines.append(interior_environment())
    else:
        lines.append(exterior_environment())
    lines.append('')
    lines.append(trigger_shape())
    lines.append('')

    # Root node
    lines.append(f'[node name="{map_id}" type="Node3D"]')
    lines.append('')

    # Environment
    lines.append('[node name="WorldEnvironment" type="WorldEnvironment" parent="."]')
    lines.append('environment = SubResource("env")')
    lines.append('')

    # Lighting
    if is_interior:
        # Indoor: omni lights
        for i, z in enumerate([-5, 5, 15]):
            lines.append(f'[node name="Light{i+1}" type="OmniLight3D" parent="."]')
            lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4, {z})')
            lines.append('light_color = Color(1, 0.98, 0.95, 1)')
            lines.append('light_energy = 4.0')
            lines.append('omni_range = 20.0')
            lines.append('')
    else:
        # Outdoor: directional sun + fill
        lines.append('[node name="Sun" type="DirectionalLight3D" parent="."]')
        lines.append('transform = Transform3D(0.75, -0.5, 0.43, 0, 0.65, 0.76, -0.66, -0.57, 0.49, 0, 80, 0)')
        lines.append('light_color = Color(1.0, 0.95, 0.85, 1)')
        lines.append('light_energy = 2.2')
        lines.append('shadow_enabled = true')
        lines.append('directional_shadow_max_distance = 200.0')
        lines.append('')
        lines.append('[node name="FillLight" type="DirectionalLight3D" parent="."]')
        lines.append('transform = Transform3D(-0.7, 0.3, -0.65, 0, 0.9, 0.44, 0.71, 0.31, -0.63, 0, 50, 0)')
        lines.append('light_color = Color(0.7, 0.8, 1.0, 1)')
        lines.append('light_energy = 0.4')
        lines.append('')

    # TagForceLocation node (loads TMS map)
    lines.append('[node name="TagForceMap" type="Node3D" parent="."]')
    lines.append('script = ExtResource("tf_loc")')
    lines.append(f'map_id = "{map_id}"')
    lines.append(f'is_interior = {str(is_interior).lower()}')
    lines.append('')

    # Player
    lines.append('[node name="Player" parent="." groups=["player"] instance=ExtResource("player")]')
    lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 5)')
    lines.append('')

    # Camera
    lines.append('[node name="ThirdPersonCamera" type="Node3D" parent="."]')
    lines.append('script = ExtResource("camera")')
    lines.append('target = NodePath("../Player")')
    lines.append('')

    # HUD
    lines.append('[node name="HUD" parent="." instance=ExtResource("hud")]')
    lines.append('')

    # Spawn Points
    lines.append('[node name="SpawnPoints" type="Node3D" parent="."]')
    lines.append('')

    # Default spawn
    lines.append('[node name="DefaultSpawn" type="Marker3D" parent="SpawnPoints" groups=["spawn_points"]]')
    lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 5)')
    lines.append('script = ExtResource("spawn")')
    lines.append('spawn_name = "default"')
    lines.append('')

    # Spawn points for each connection
    for i, conn_id in enumerate(connections):
        conn_name = MAP_NAMES.get(conn_id, conn_id)
        angle = (i * 90) % 360  # Spread spawn points around
        x = [-5, 5, 0, 0][i % 4]
        z = [0, 0, -5, 5][i % 4]
        spawn_id = f"from_{conn_id.lower()}"

        lines.append(f'[node name="{spawn_id}" type="Marker3D" parent="SpawnPoints" groups=["spawn_points"]]')
        lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, 1, {z})')
        lines.append('script = ExtResource("spawn")')
        lines.append(f'spawn_name = "{spawn_id}"')
        lines.append(f'look_direction = {float(angle)}')
        lines.append('')

    # Scene Triggers to connected maps
    lines.append('[node name="Triggers" type="Node3D" parent="."]')
    lines.append('')

    for i, conn_id in enumerate(connections):
        conn_name = MAP_NAMES.get(conn_id, conn_id)
        conn_scene = f"res://scenes/tagforce/{conn_id}.tscn"
        # Place triggers at edges of the map
        x = [-10, 10, 0, 0, -8, 8, -4, 4][i % 8]
        z = [0, 0, -10, 10, -8, 8, -4, 4][i % 8]
        spawn_target = f"from_{map_id.lower()}"

        lines.append(f'[node name="To{conn_id}" type="Area3D" parent="Triggers"]')
        lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, 2, {z})')
        lines.append('collision_layer = 0')
        lines.append('collision_mask = 2')
        lines.append('script = ExtResource("trigger")')
        lines.append('use_custom_path = true')
        lines.append(f'custom_scene_path = "{conn_scene}"')
        lines.append(f'custom_location_name = "{conn_name}"')
        lines.append(f'target_spawn_point = "{spawn_target}"')
        lines.append('')

        lines.append(f'[node name="CollisionShape3D" type="CollisionShape3D" parent="Triggers/To{conn_id}"]')
        lines.append('shape = SubResource("trigger_shape")')
        lines.append('')

    return '\n'.join(lines)


def main():
    # Determine output directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)  # tools/ -> project root
    output_dir = os.path.join(project_dir, 'scenes', 'tagforce')
    os.makedirs(output_dir, exist_ok=True)

    print(f"Generating {len(MAPS)} Tag Force map scenes...")
    print(f"Output: {output_dir}\n")

    for map_id, name, tms, interior, connections in MAPS:
        scene_content = generate_scene(map_id, name, tms, interior, connections)
        output_path = os.path.join(output_dir, f"{map_id}.tscn")

        with open(output_path, 'w') as f:
            f.write(scene_content)

        conn_str = ', '.join(connections) if connections else 'none'
        env = 'interior' if interior else 'exterior'
        print(f"  {map_id}: {name} ({env}) -> {conn_str}")

    print(f"\nDone! Generated {len(MAPS)} scene files in {output_dir}")


if __name__ == '__main__':
    main()
