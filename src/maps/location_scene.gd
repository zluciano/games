extends Node2D
## Root controller for a location scene. Manages NPCs, exits, and player spawning.

const DIALOG_BOX_SCENE := preload("res://scenes/components/dialog_box.tscn")
const NPC_SCENE := preload("res://scenes/components/npc.tscn")
const CARD_SHOP_SCENE := preload("res://scenes/card_shop/card_shop.tscn")
const MAP_HUD_SCENE := preload("res://scenes/components/map_hud.tscn")

@export var map_id: String = ""
@export var display_name: String = ""
@export var is_interior: bool = false

var _spawn_point: String = "default"
## Background texture size, used for dynamic spawn/NPC positioning.
var _bg_size: Vector2 = Vector2(1440, 816)
var _map_hud: Node = null

@onready var player: Node2D = $Player


func _ready() -> void:
	GameManager.change_state(GameManager.State.LOCATION)

	# Enable y-sorting so characters closer to bottom render in front
	y_sort_enabled = true

	# Read background size for camera bounds and position scaling
	var bg = $Background
	if bg is Sprite2D and bg.texture:
		_bg_size = bg.texture.get_size()
		player.set_map_bounds(Rect2(0, 0, _bg_size.x, _bg_size.y))
	else:
		player.set_map_bounds(Rect2(0, 0, _bg_size.x, _bg_size.y))

	# Add dialog box to scene
	var dialog_box := DIALOG_BOX_SCENE.instantiate()
	dialog_box.add_to_group("dialog_box")
	add_child(dialog_box)

	# Add HUD overlay
	_map_hud = MAP_HUD_SCENE.instantiate()
	_map_hud.set_location(display_name)
	add_child(_map_hud)

	# Hide the old generated LocationLabel if present
	var old_label := find_child("LocationLabel")
	if old_label:
		old_label.visible = false

	# Spawn NPCs based on schedule
	_spawn_npcs()

	# Position player at spawn point
	_apply_spawn_point()

	# Auto-open card shop when entering the Card Shop location
	if map_id == "BG_02_04":
		_open_card_shop()


func set_spawn_point(point: String) -> void:
	_spawn_point = point
	_apply_spawn_point()


func _apply_spawn_point() -> void:
	# Default spawn: center of background
	var default_pos := Vector2(_bg_size.x / 2.0, _bg_size.y / 2.0)
	match _spawn_point:
		"default":
			player.position = default_pos
		_:
			var marker := find_child(_spawn_point)
			if marker:
				player.position = marker.position
			else:
				player.position = default_pos


func _spawn_npcs() -> void:
	# NPC schedule positions are in legacy 480x272 coordinate space (offset from center).
	# Map them to the background pixel space with a spread factor.
	var center := _bg_size / 2.0
	# Spread: bg_size / legacy_viewport. Cap at 5.0 so NPCs stay reachable.
	var spread_x: float = minf(_bg_size.x / 480.0, 5.0)
	var spread_y: float = minf(_bg_size.y / 272.0, 5.0)
	var time := TimeManager.time_of_day
	var npc_list: Array = CharacterDB.get_characters_at_location(map_id, time)
	for npc_data in npc_list:
		var npc := NPC_SCENE.instantiate()
		npc.character_id = npc_data.get("id", "")
		var pos: Array = npc_data.get("position", [240, 136])
		# Convert viewport-space position to offset from center, then spread
		var offset := Vector2((pos[0] - 240.0) * spread_x, (pos[1] - 136.0) * spread_y)
		npc.position = center + offset
		npc.idle_direction = npc_data.get("direction", 0)
		add_child(npc)


func _open_card_shop() -> void:
	player.set_movement_enabled(false)
	GameManager.change_state(GameManager.State.SHOP)
	var shop := CARD_SHOP_SCENE.instantiate()
	shop.shop_closed.connect(_on_shop_closed)
	add_child(shop)


func _on_shop_closed() -> void:
	GameManager.change_state(GameManager.State.LOCATION)
	SceneManager.goto_location("BG_02_01", "from_card_shop")
