extends Control
class_name Minimap

## Minimap - Shows top-down view of current location with player position

# Map data for each location (simplified polygons)
# Format: Array of Vector2 points defining walkable area outline
const LOCATION_MAPS: Dictionary = {
	"courtyard": {
		"name": "Courtyard",
		"bounds": Rect2(-20, -15, 40, 30),  # World bounds (x, z, width, depth)
		"floor": [Vector2(-20, -15), Vector2(20, -15), Vector2(20, 15), Vector2(-20, 15)],
		"buildings": [
			{"rect": Rect2(-15, -17, 30, 5), "name": "Academy"},  # Academy building
		],
		"exits": [
			{"pos": Vector2(0, -7), "name": "Academy", "dir": "N"},
			{"pos": Vector2(-20, 5), "name": "Dorms", "dir": "W"},
			{"pos": Vector2(0, 15), "name": "Harbor", "dir": "S"},
		],
		"features": [
			{"pos": Vector2(-12, 5), "type": "tree"},
			{"pos": Vector2(12, 5), "type": "tree"},
			{"pos": Vector2(-15, 10), "type": "tree"},
			{"pos": Vector2(15, 10), "type": "tree"},
		]
	},
	"academy_hallway": {
		"name": "Academy Hallway",
		"bounds": Rect2(-4, -20, 8, 40),
		"floor": [Vector2(-4, -20), Vector2(4, -20), Vector2(4, 20), Vector2(-4, 20)],
		"buildings": [],
		"exits": [
			{"pos": Vector2(0, 20), "name": "Courtyard", "dir": "S"},
			{"pos": Vector2(-4, -10), "name": "Classroom", "dir": "W"},
			{"pos": Vector2(4, 5), "name": "Card Shop", "dir": "E"},
		],
		"features": []
	},
	"classroom": {
		"name": "Classroom",
		"bounds": Rect2(-6, -5, 12, 10),
		"floor": [Vector2(-6, -5), Vector2(6, -5), Vector2(6, 5), Vector2(-6, 5)],
		"buildings": [],
		"exits": [
			{"pos": Vector2(6, 0), "name": "Hallway", "dir": "E"},
		],
		"features": []
	},
	"card_shop": {
		"name": "Card Shop",
		"bounds": Rect2(-4, -4, 8, 8),
		"floor": [Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)],
		"buildings": [],
		"exits": [
			{"pos": Vector2(-4, 0), "name": "Hallway", "dir": "W"},
		],
		"features": [
			{"pos": Vector2(0, -3), "type": "counter"},
		]
	},
	"slifer_dorm": {
		"name": "Slifer Red Dorm",
		"bounds": Rect2(-4, -5, 8, 10),
		"floor": [Vector2(-4, -5), Vector2(4, -5), Vector2(4, 5), Vector2(-4, 5)],
		"buildings": [],
		"exits": [
			{"pos": Vector2(-4, 0), "name": "Outside", "dir": "W"},
		],
		"features": [
			{"pos": Vector2(2, -3), "type": "bed"},
			{"pos": Vector2(-2, -3), "type": "desk"},
		]
	},
}

# Colors
const COLOR_FLOOR := Color(0.2, 0.35, 0.2, 0.8)  # Dark green
const COLOR_BUILDING := Color(0.3, 0.3, 0.35, 0.9)  # Gray
const COLOR_PATH := Color(0.4, 0.35, 0.25, 0.8)  # Brown
const COLOR_PLAYER := Color(1.0, 0.3, 0.3, 1.0)  # Red
const COLOR_EXIT := Color(1.0, 0.9, 0.3, 0.9)  # Yellow
const COLOR_TREE := Color(0.15, 0.4, 0.15, 0.9)  # Dark green
const COLOR_WATER := Color(0.2, 0.4, 0.6, 0.8)  # Blue
const COLOR_BORDER := Color(0.1, 0.1, 0.1, 0.9)  # Black

@export var map_size: Vector2 = Vector2(150, 150)
@export var player_dot_size: float = 6.0
@export var exit_dot_size: float = 4.0

var current_location: String = "courtyard"
var player_world_pos: Vector2 = Vector2.ZERO
var player_node: Node3D = null

# Cached map data
var current_map_data: Dictionary = {}
var scale_factor: float = 1.0
var offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = map_size
	_load_location("courtyard")


func _process(_delta: float) -> void:
	_update_player_position()
	queue_redraw()


func _update_player_position() -> void:
	if not player_node:
		# Try to find player
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0]

	if player_node:
		# Convert 3D position to 2D (X, Z -> X, Y on minimap)
		player_world_pos = Vector2(player_node.global_position.x, player_node.global_position.z)


func set_location(location_key: String) -> void:
	if location_key in LOCATION_MAPS:
		_load_location(location_key)


func _load_location(location_key: String) -> void:
	current_location = location_key
	if location_key in LOCATION_MAPS:
		current_map_data = LOCATION_MAPS[location_key]
		_calculate_scale()
	else:
		current_map_data = {}


func _calculate_scale() -> void:
	if current_map_data.is_empty():
		return

	var bounds: Rect2 = current_map_data.get("bounds", Rect2(0, 0, 40, 40))

	# Calculate scale to fit map in the minimap area with padding
	var padding := 10.0
	var available_size := map_size - Vector2(padding * 2, padding * 2)

	var scale_x := available_size.x / bounds.size.x
	var scale_y := available_size.y / bounds.size.y
	scale_factor = min(scale_x, scale_y)

	# Calculate offset to center the map
	offset = map_size / 2.0 - Vector2(bounds.position.x + bounds.size.x / 2.0,
									   bounds.position.y + bounds.size.y / 2.0) * scale_factor


func _world_to_minimap(world_pos: Vector2) -> Vector2:
	return world_pos * scale_factor + offset


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, map_size), Color(0.05, 0.05, 0.08, 0.9))
	draw_rect(Rect2(Vector2.ZERO, map_size), COLOR_BORDER, false, 2.0)

	if current_map_data.is_empty():
		return

	# Draw floor
	var floor_points: Array = current_map_data.get("floor", [])
	if floor_points.size() >= 3:
		var minimap_points: PackedVector2Array = PackedVector2Array()
		for point in floor_points:
			minimap_points.append(_world_to_minimap(point))
		draw_colored_polygon(minimap_points, COLOR_FLOOR)
		draw_polyline(minimap_points, COLOR_BORDER, 1.0, true)

	# Draw buildings
	var buildings: Array = current_map_data.get("buildings", [])
	for building in buildings:
		var rect: Rect2 = building.get("rect", Rect2())
		var top_left := _world_to_minimap(rect.position)
		var size := rect.size * scale_factor
		draw_rect(Rect2(top_left, size), COLOR_BUILDING)
		draw_rect(Rect2(top_left, size), COLOR_BORDER, false, 1.0)

	# Draw features (trees, etc.)
	var features: Array = current_map_data.get("features", [])
	for feature in features:
		var pos: Vector2 = _world_to_minimap(feature.get("pos", Vector2.ZERO))
		var feature_type: String = feature.get("type", "")
		match feature_type:
			"tree":
				draw_circle(pos, 4.0, COLOR_TREE)
			"counter", "desk", "bed":
				draw_rect(Rect2(pos - Vector2(3, 2), Vector2(6, 4)), COLOR_BUILDING)

	# Draw exits
	var exits: Array = current_map_data.get("exits", [])
	for exit_data in exits:
		var pos: Vector2 = _world_to_minimap(exit_data.get("pos", Vector2.ZERO))
		draw_circle(pos, exit_dot_size, COLOR_EXIT)

	# Draw player
	var player_minimap_pos := _world_to_minimap(player_world_pos)
	# Clamp to minimap bounds
	player_minimap_pos.x = clamp(player_minimap_pos.x, 5, map_size.x - 5)
	player_minimap_pos.y = clamp(player_minimap_pos.y, 5, map_size.y - 5)
	draw_circle(player_minimap_pos, player_dot_size, COLOR_PLAYER)
	draw_circle(player_minimap_pos, player_dot_size + 1, Color.WHITE, false, 1.5)

	# Draw location name
	var location_name: String = current_map_data.get("name", "Unknown")
	draw_string(ThemeDB.fallback_font, Vector2(8, 18), location_name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
