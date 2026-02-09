extends Control
## Island overview map with cursor navigation between connected locations.

const MAP_REGISTRY_PATH := "res://data/maps/map_registry.json"
const MAP_POSITIONS_PATH := "res://data/maps/map_positions.json"
const BIG_MAP_BASE := "res://assets/tagforce/backgrounds/big_map/"

var _map_data: Dictionary = {}
var _positions: Dictionary = {}
var _location_ids: Array = []
var _current_index: int = 0
var _can_input: bool = false

@onready var island_texture: TextureRect = $IslandTexture
@onready var cursor_sprite: Node2D = $CursorSprite
@onready var location_label: Label = $InfoPanel/HBox/LocationLabel
@onready var time_label: Label = $InfoPanel/HBox/TimeLabel


func _ready() -> void:
	GameManager.change_state(GameManager.State.BIG_MAP)
	_load_data()
	_update_island_texture()
	_select_current_location()

	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished
	_can_input = true

	TimeManager.time_changed.connect(_on_time_changed)


func _load_data() -> void:
	# Load map registry
	var reg_file := FileAccess.open(MAP_REGISTRY_PATH, FileAccess.READ)
	if reg_file:
		var json := JSON.new()
		if json.parse(reg_file.get_as_text()) == OK:
			_map_data = json.data
		reg_file.close()

	# Load positions
	var pos_file := FileAccess.open(MAP_POSITIONS_PATH, FileAccess.READ)
	if pos_file:
		var json := JSON.new()
		if json.parse(pos_file.get_as_text()) == OK:
			_positions = json.data
		pos_file.close()

	# Build location list (sorted)
	_location_ids = _map_data.keys()
	_location_ids.sort()

	# Start at player's current location
	var current_loc: String = GameManager.game_data.get("location", "BG_01_01")
	var idx := _location_ids.find(current_loc)
	if idx >= 0:
		_current_index = idx


func _update_island_texture() -> void:
	var folder := TimeManager.get_big_map_folder()
	var path := BIG_MAP_BASE + folder + "/bm_island_full.png"
	if ResourceLoader.exists(path):
		island_texture.texture = load(path)


func _select_current_location() -> void:
	var loc_id: String = _location_ids[_current_index]
	var loc_data: Dictionary = _map_data.get(loc_id, {})
	var pos_data: Dictionary = _positions.get(loc_id, {})

	# Move cursor
	var target := Vector2(pos_data.get("x", 240), pos_data.get("y", 136))
	var tween := create_tween()
	tween.tween_property(cursor_sprite, "position", target, 0.1)

	# Update label
	location_label.text = loc_data.get("name", loc_id)

	# Update time display
	time_label.text = TimeManager.time_of_day.capitalize() + " - Day " + str(TimeManager.day_number)


func _input(event: InputEvent) -> void:
	if not _can_input:
		return

	var loc_id: String = _location_ids[_current_index]
	var loc_data: Dictionary = _map_data.get(loc_id, {})
	var connections: Array = loc_data.get("connections", [])

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_can_input = false
		SceneManager.goto_location(loc_id)
	elif event.is_action_pressed("ui_cancel"):
		# Return to current location without map selection
		_can_input = false
		var current_loc: String = GameManager.game_data.get("location", "BG_01_01")
		SceneManager.goto_location(current_loc)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		_navigate_connections(connections, 1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		_navigate_connections(connections, -1)


func _navigate_connections(connections: Array, direction: int) -> void:
	if connections.is_empty():
		return

	# Find the best connection in the given direction
	var current_pos := cursor_sprite.position

	# Sort connections by direction preference
	var best_id := ""
	var best_score := -INF

	for conn_id in connections:
		var pos_data: Dictionary = _positions.get(conn_id, {})
		var conn_pos := Vector2(pos_data.get("x", 240), pos_data.get("y", 136))
		var delta := conn_pos - current_pos

		var score: float
		if direction > 0:
			score = delta.x + delta.y  # favor right/down
		else:
			score = -delta.x - delta.y  # favor left/up

		if score > best_score:
			best_score = score
			best_id = conn_id

	if not best_id.is_empty():
		var idx := _location_ids.find(best_id)
		if idx >= 0:
			_current_index = idx
			_select_current_location()


func _on_time_changed(_new_time: String) -> void:
	_update_island_texture()
	_select_current_location()
