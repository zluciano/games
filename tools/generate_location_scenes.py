#!/usr/bin/env python3
"""Generate all location .tscn files for Tag Force Evolution.

Reads map_registry.json and produces a complete .tscn for each location
with rendered backgrounds, exits, spawn points, and player/UI nodes.
"""

import json
import os
from PIL import Image

PROJ_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY_PATH = os.path.join(PROJ_ROOT, "data", "maps", "map_registry.json")
SCENES_DIR = os.path.join(PROJ_ROOT, "scenes", "locations")
RENDERED_DIR = os.path.join(PROJ_ROOT, "assets", "tagforce", "backgrounds", "maps_rendered")

# Default size for maps without rendered backgrounds (matches PS2 viewport)
DEFAULT_W = 640
DEFAULT_H = 480

# Spawn margin from edge (in pixels)
_SP = 60


def get_map_dimensions(map_id):
    """Read actual rendered background dimensions for a map."""
    bg_path = os.path.join(RENDERED_DIR, f"{map_id.lower()}_bg.png")
    if os.path.isfile(bg_path):
        img = Image.open(bg_path)
        return img.size[0], img.size[1]
    return DEFAULT_W, DEFAULT_H


def get_side_config(map_w, map_h):
    """Compute exit zone positions and shapes for a given map size."""
    mid_x = map_w // 2
    mid_y = map_h // 2
    return {
        "left":         {"pos": (25, mid_y),                     "shape": "v",    "label": (25, -20, 300, 20),   "align": 0},
        "right":        {"pos": (map_w - 25, mid_y),             "shape": "v",    "label": (-250, -20, -25, 20), "align": 2},
        "top":          {"pos": (mid_x, 25),                     "shape": "h",    "label": (-125, 25, 125, 65),  "align": 1},
        "bottom":       {"pos": (mid_x, map_h - 18),             "shape": "h",    "label": (-75, -45, 75, 0),    "align": 1},
        "left_top":     {"pos": (25, map_h // 4),                "shape": "v_sm", "label": (25, -20, 300, 20),   "align": 0},
        "left_bottom":  {"pos": (25, map_h * 3 // 4),            "shape": "v_sm", "label": (25, -20, 300, 20),   "align": 0},
        "right_top":    {"pos": (map_w - 25, map_h // 4),        "shape": "v_sm", "label": (-250, -20, -25, 20), "align": 2},
        "right_bottom": {"pos": (map_w - 25, map_h * 3 // 4),    "shape": "v_sm", "label": (-250, -20, -25, 20), "align": 2},
        "top_left":     {"pos": (mid_x // 2, 25),                "shape": "h_sm", "label": (-125, 25, 125, 65),  "align": 1},
        "top_right":    {"pos": (mid_x + mid_x // 2, 25),        "shape": "h_sm", "label": (-125, 25, 125, 65),  "align": 1},
        "bottom_left":  {"pos": (mid_x // 2, map_h - 18),        "shape": "h_sm", "label": (-125, -45, 125, 0),  "align": 1},
        "bottom_right": {"pos": (mid_x + mid_x // 2, map_h - 18),"shape": "h_sm", "label": (-125, -45, 125, 0),  "align": 1},
    }


def get_spawn_for_side(map_w, map_h):
    """Compute spawn positions for each exit side."""
    mid_x = map_w // 2
    mid_y = map_h // 2
    return {
        "left":         (_SP, mid_y),
        "right":        (map_w - _SP, mid_y),
        "top":          (mid_x, _SP),
        "bottom":       (mid_x, map_h - _SP),
        "left_top":     (_SP, map_h // 4),
        "left_bottom":  (_SP, map_h * 3 // 4),
        "right_top":    (map_w - _SP, map_h // 4),
        "right_bottom": (map_w - _SP, map_h * 3 // 4),
        "top_left":     (mid_x // 2, _SP),
        "top_right":    (mid_x + mid_x // 2, _SP),
        "bottom_left":  (mid_x // 2, map_h - _SP),
        "bottom_right": (mid_x + mid_x // 2, map_h - _SP),
    }

# Short name for each map (used for spawn point naming: "from_{short_name}")
SHORT_NAMES = {
    "BG_01_01": "courtyard",
    "BG_01_02": "entrance",
    "BG_02_01": "hallway_1f",
    "BG_02_02": "hallway_2f",
    "BG_02_03": "classroom",
    "BG_02_04": "card_shop",
    "BG_02_05": "library",
    "BG_02_06": "staff_room",
    "BG_02_07": "chancellor",
    "BG_02_08": "arena",
    "BG_03_01": "slifer",
    "BG_04_01": "ra_yellow",
    "BG_05_01": "obelisk",
    "BG_06_01": "girls_dorm",
    "BG_07_01": "harbor",
    "BG_08_01": "lighthouse",
    "BG_09_01": "forest",
    "BG_10_01": "abandoned",
    "BG_11_01": "volcano",
    "BG_14_01": "beach",
    "BG_15_01": "hot_spring",
    "BG_16_01": "cliff",
    "BG_18_01": "cave",
    "BG_19_01": "lake",
    "BG_20_01": "bridge",
    "BG_21_01": "rooftop",
    "BG_22_01": "dorm_slifer",
    "BG_22_02": "dorm_obelisk",
}

# Display labels for exits (what the player sees next to the exit zone)
EXIT_LABELS = {
    "BG_01_01": "Courtyard",
    "BG_01_02": "Entrance",
    "BG_02_01": "Hallway 1F",
    "BG_02_02": "Hallway 2F",
    "BG_02_03": "Classroom",
    "BG_02_04": "Card Shop",
    "BG_02_05": "Library",
    "BG_02_06": "Staff Room",
    "BG_02_07": "Chancellor",
    "BG_02_08": "Duel Arena",
    "BG_03_01": "Slifer Dorm",
    "BG_04_01": "Ra Yellow",
    "BG_05_01": "Obelisk Dorm",
    "BG_06_01": "Girls' Dorm",
    "BG_07_01": "Harbor",
    "BG_08_01": "Lighthouse",
    "BG_09_01": "Forest",
    "BG_10_01": "Abandoned Dorm",
    "BG_11_01": "Volcano",
    "BG_14_01": "Beach",
    "BG_15_01": "Hot Spring",
    "BG_16_01": "Cliff",
    "BG_18_01": "Cave",
    "BG_19_01": "Lake",
    "BG_20_01": "Bridge",
    "BG_21_01": "Rooftop",
    "BG_22_01": "Dorm Room",
    "BG_22_02": "Dorm Room",
}

# Exit side assignments for each map: map_id -> {target_id: side}
# Sides: left, right, top, bottom, left_top, left_bottom, right_top, right_bottom
EXIT_SIDES = {
    "BG_01_01": {"BG_01_02": "left", "BG_02_01": "top", "BG_03_01": "right", "BG_07_01": "bottom_left", "BG_14_01": "bottom_right"},
    "BG_01_02": {"BG_01_01": "right", "BG_09_01": "left"},
    "BG_02_01": {"BG_01_01": "bottom", "BG_02_02": "top", "BG_02_03": "left", "BG_02_04": "right", "BG_02_08": "right_top"},
    "BG_02_02": {"BG_02_01": "bottom", "BG_02_05": "left", "BG_02_06": "right", "BG_02_07": "top_left", "BG_21_01": "top_right"},
    "BG_02_03": {"BG_02_01": "bottom"},
    "BG_02_04": {"BG_02_01": "bottom"},
    "BG_02_05": {"BG_02_02": "bottom"},
    "BG_02_06": {"BG_02_02": "bottom"},
    "BG_02_07": {"BG_02_02": "bottom"},
    "BG_02_08": {"BG_02_01": "bottom"},
    "BG_03_01": {"BG_01_01": "left", "BG_04_01": "right", "BG_22_01": "top"},
    "BG_04_01": {"BG_03_01": "left", "BG_05_01": "right"},
    "BG_05_01": {"BG_04_01": "left", "BG_06_01": "right", "BG_22_02": "top"},
    "BG_06_01": {"BG_05_01": "left"},
    "BG_07_01": {"BG_01_01": "right", "BG_08_01": "left"},
    "BG_08_01": {"BG_07_01": "right"},
    "BG_09_01": {"BG_01_02": "right", "BG_10_01": "left", "BG_11_01": "top", "BG_16_01": "top_left", "BG_19_01": "bottom_left", "BG_20_01": "bottom"},
    "BG_10_01": {"BG_09_01": "right"},
    "BG_11_01": {"BG_09_01": "bottom", "BG_18_01": "top"},
    "BG_14_01": {"BG_01_01": "right", "BG_15_01": "left"},
    "BG_15_01": {"BG_14_01": "right"},
    "BG_16_01": {"BG_09_01": "bottom"},
    "BG_18_01": {"BG_11_01": "bottom"},
    "BG_19_01": {"BG_09_01": "right"},
    "BG_20_01": {"BG_01_01": "left", "BG_09_01": "right"},
    "BG_21_01": {"BG_02_02": "bottom"},
    "BG_22_01": {"BG_03_01": "bottom"},
    "BG_22_02": {"BG_05_01": "bottom"},
}

# Fallback colors for maps without rendered backgrounds
FALLBACK_COLORS = {
    "BG_09_01": "Color(0.12, 0.25, 0.08, 1)",  # Forest green
    "BG_15_01": "Color(0.35, 0.5, 0.65, 1)",    # Hot spring blue
}
DEFAULT_FALLBACK = "Color(0.15, 0.15, 0.2, 1)"


def get_opposite_side(side):
    """Given the side where an exit exits FROM, return which side it arrives AT."""
    opposites = {
        "left": "right", "right": "left", "top": "bottom", "bottom": "top",
        "left_top": "right_bottom", "left_bottom": "right_top",
        "right_top": "left_bottom", "right_bottom": "left_top",
        "top_left": "bottom_right", "top_right": "bottom_left",
        "bottom_left": "top_right", "bottom_right": "top_left",
    }
    return opposites.get(side, "bottom")


def generate_tscn(map_id, info, registry):
    """Generate the .tscn file content for a location scene."""
    name = info["name"]
    is_interior = info["is_interior"]
    connections = info["connections"]
    map_lower = map_id.lower()

    # Get actual map dimensions from rendered background
    map_w, map_h = get_map_dimensions(map_id)
    mid_x = map_w // 2
    mid_y = map_h // 2

    # Check for rendered background
    bg_path = os.path.join(RENDERED_DIR, f"{map_lower}_bg.png")
    has_bg = os.path.isfile(bg_path)

    # Build per-map exit config and spawn positions
    side_config = get_side_config(map_w, map_h)
    spawn_for_side = get_spawn_for_side(map_w, map_h)

    # Determine exit sides
    exits_config = EXIT_SIDES.get(map_id, {})

    # Build spawn points: for each map that connects TO this map, add a spawn marker
    # When arriving from other_id, spawn near THIS map's exit back to other_id
    spawn_points = {}  # spawn_name -> (x, y)
    this_exits = EXIT_SIDES.get(map_id, {})
    for other_id, other_info in registry.items():
        if map_id in other_info.get("connections", []):
            short = SHORT_NAMES.get(other_id, other_id.lower())
            spawn_name = f"from_{short}"
            # Spawn near this map's exit that leads back to other_id
            if other_id in this_exits:
                exit_side = this_exits[other_id]
                spawn_pos = spawn_for_side.get(exit_side, (240, 180))
            else:
                spawn_pos = (mid_x, mid_y)
            spawn_points[spawn_name] = spawn_pos

    # Count resources
    need_v = any(side_config[exits_config.get(t, "bottom")]["shape"] == "v" for t in connections if t in exits_config)
    need_h = any(side_config[exits_config.get(t, "bottom")]["shape"] == "h" for t in connections if t in exits_config)
    need_v_sm = any(side_config[exits_config.get(t, "bottom")]["shape"] == "v_sm" for t in connections if t in exits_config)
    need_h_sm = any(side_config[exits_config.get(t, "bottom")]["shape"] == "h_sm" for t in connections if t in exits_config)

    ext_count = 4  # scene_script, player_script, char_script, exit_script
    if has_bg:
        ext_count += 1
    sub_count = 1  # player_shape
    if need_v:
        sub_count += 1
    if need_h:
        sub_count += 1
    if need_v_sm:
        sub_count += 1
    if need_h_sm:
        sub_count += 1

    load_steps = ext_count + sub_count

    lines = []
    lines.append(f'[gd_scene load_steps={load_steps} format=3]')
    lines.append('')

    # Ext resources
    lines.append('[ext_resource type="Script" path="res://src/maps/location_scene.gd" id="scene_script"]')
    lines.append('[ext_resource type="Script" path="res://src/characters/player_controller.gd" id="player_script"]')
    lines.append('[ext_resource type="Script" path="res://src/characters/overworld_character.gd" id="char_script"]')
    lines.append('[ext_resource type="Script" path="res://src/maps/location_exit.gd" id="exit_script"]')
    if has_bg:
        lines.append(f'[ext_resource type="Texture2D" path="res://assets/tagforce/backgrounds/maps_rendered/{map_lower}_bg.png" id="bg_texture"]')
    lines.append('')

    # Sub resources
    lines.append('[sub_resource type="CircleShape2D" id="player_shape"]')
    lines.append('radius = 24.0')
    lines.append('')

    if need_v:
        lines.append('[sub_resource type="RectangleShape2D" id="exit_shape_v"]')
        lines.append(f'size = Vector2(50, {map_h - 100})')
        lines.append('')
    if need_h:
        lines.append('[sub_resource type="RectangleShape2D" id="exit_shape_h"]')
        lines.append(f'size = Vector2({map_w}, 50)')
        lines.append('')
    if need_v_sm:
        lines.append('[sub_resource type="RectangleShape2D" id="exit_shape_v_sm"]')
        lines.append(f'size = Vector2(50, {map_h // 3})')
        lines.append('')
    if need_h_sm:
        lines.append('[sub_resource type="RectangleShape2D" id="exit_shape_h_sm"]')
        lines.append(f'size = Vector2({map_w // 3}, 50)')
        lines.append('')

    # Root node
    lines.append(f'[node name="{map_id}" type="Node2D"]')
    lines.append('script = ExtResource("scene_script")')
    lines.append(f'map_id = "{map_id}"')
    lines.append(f'display_name = "{name}"')
    lines.append(f'is_interior = {"true" if is_interior else "false"}')
    lines.append('')

    # Background (Sprite2D at native size; Camera2D shows 640x480 window)
    if has_bg:
        lines.append('[node name="Background" type="Sprite2D" parent="."]')
        lines.append('centered = false')
        lines.append('texture = ExtResource("bg_texture")')
    else:
        color = FALLBACK_COLORS.get(map_id, DEFAULT_FALLBACK)
        lines.append('[node name="Background" type="ColorRect" parent="."]')
        lines.append(f'offset_right = {map_w}')
        lines.append(f'offset_bottom = {map_h}')
        lines.append(f'color = {color}')
    lines.append('')

    # Player
    lines.append('[node name="Player" type="Node2D" parent="." groups=["player"]]')
    lines.append(f'position = Vector2({mid_x}, {mid_y})')
    lines.append('script = ExtResource("player_script")')
    lines.append('')
    lines.append('[node name="OverworldCharacter" type="Node2D" parent="Player"]')
    lines.append('script = ExtResource("char_script")')
    lines.append('')
    lines.append('[node name="Sprite2D" type="Sprite2D" parent="Player/OverworldCharacter"]')
    lines.append('')
    lines.append('[node name="AnimTimer" type="Timer" parent="Player/OverworldCharacter"]')
    lines.append('wait_time = 0.12')
    lines.append('')
    lines.append('[node name="Camera2D" type="Camera2D" parent="Player"]')
    lines.append('')
    lines.append('[node name="InteractionArea" type="Area2D" parent="Player"]')
    lines.append('collision_layer = 2')
    lines.append('collision_mask = 4')
    lines.append('')
    lines.append('[node name="Shape" type="CollisionShape2D" parent="Player/InteractionArea"]')
    lines.append('shape = SubResource("player_shape")')
    lines.append('')

    # Exits
    for target in connections:
        side = exits_config.get(target, "bottom")
        cfg = side_config[side]
        px, py = cfg["pos"]
        shape_type = cfg["shape"]
        lbl_off = cfg["label"]
        align = cfg["align"]
        label_text = EXIT_LABELS.get(target, target)

        # The spawn point name at the TARGET map for players coming from THIS map
        source_short = SHORT_NAMES.get(map_id, map_id.lower())
        target_spawn = f"from_{source_short}"

        shape_id = f"exit_shape_{shape_type}"

        lines.append(f'[node name="Exit_{target}" type="Area2D" parent="."]')
        lines.append(f'position = Vector2({px}, {py})')
        lines.append('collision_layer = 0')
        lines.append('collision_mask = 2')
        lines.append('script = ExtResource("exit_script")')
        lines.append(f'target_map_id = "{target}"')
        lines.append(f'target_spawn_point = "{target_spawn}"')
        lines.append('')
        lines.append(f'[node name="Shape" type="CollisionShape2D" parent="Exit_{target}"]')
        lines.append(f'shape = SubResource("{shape_id}")')
        lines.append('')
        lines.append(f'[node name="Label" type="Label" parent="Exit_{target}"]')
        lines.append(f'offset_left = {lbl_off[0]}')
        lines.append(f'offset_top = {lbl_off[1]}')
        lines.append(f'offset_right = {lbl_off[2]}')
        lines.append(f'offset_bottom = {lbl_off[3]}')
        lines.append(f'text = "{label_text}"')
        if align != 0:
            lines.append(f'horizontal_alignment = {align}')
        lines.append('add_theme_font_size_override/font_size = 14')
        lines.append('modulate = Color(1, 1, 0.6, 0.6)')
        lines.append('')

    # Spawn points
    for spawn_name, (sx, sy) in sorted(spawn_points.items()):
        lines.append(f'[node name="{spawn_name}" type="Marker2D" parent="."]')
        lines.append(f'position = Vector2({sx}, {sy})')
        lines.append('')

    return '\n'.join(lines)


def main():
    with open(REGISTRY_PATH) as f:
        registry = json.load(f)

    os.makedirs(SCENES_DIR, exist_ok=True)

    generated = 0
    for map_id, info in sorted(registry.items()):
        map_w, map_h = get_map_dimensions(map_id)
        out_path = os.path.join(SCENES_DIR, f"{map_id}.tscn")
        content = generate_tscn(map_id, info, registry)
        with open(out_path, 'w') as f:
            f.write(content)
        print(f"  Generated: {map_id} ({map_w}x{map_h}) -> {os.path.basename(out_path)}")
        generated += 1

    print(f"\nDone! Generated {generated} location scenes in {SCENES_DIR}")


if __name__ == "__main__":
    main()
