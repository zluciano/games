extends Node2D
## Player controller - input-driven movement using overworld character sprite.
## Camera2D child follows the player and shows a 640x480 window into the map.

const DEFAULT_SPRITE := "res://assets/tagforce/characters/sprites_sla/sd_play_sla.png"

@export var speed: float = 180.0

var _can_move: bool = true
var _nearby_npcs: Array = []
var _map_bounds: Rect2 = Rect2(0, 0, 1440, 816)

@onready var character: Node2D = $OverworldCharacter
@onready var interaction_area: Area2D = $InteractionArea
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	character.load_sprite(DEFAULT_SPRITE)
	character.idle(character.Direction.S)

	interaction_area.area_entered.connect(_on_npc_entered)
	interaction_area.area_exited.connect(_on_npc_exited)

	# Camera2D setup: show native 640x480 window
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0


func set_map_bounds(bounds: Rect2) -> void:
	_map_bounds = bounds
	# Set camera limits so it doesn't show beyond the map background
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)


func _physics_process(delta: float) -> void:
	if not _can_move:
		return

	var input := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		input.x -= 1
	if Input.is_action_pressed("ui_right"):
		input.x += 1
	if Input.is_action_pressed("ui_up"):
		input.y -= 1
	if Input.is_action_pressed("ui_down"):
		input.y += 1

	if input != Vector2.ZERO:
		input = input.normalized()
		position += input * speed * delta

		# Determine 8-way facing direction from raw input axes
		var dir: int = character._vector_to_direction(input)
		character.walk(dir)

		# Clamp to map bounds (with margin for sprite)
		var margin := 16.0
		position.x = clampf(position.x, _map_bounds.position.x + margin, _map_bounds.end.x - margin)
		position.y = clampf(position.y, _map_bounds.position.y + margin, _map_bounds.end.y - margin)
	else:
		character.idle()


func _input(event: InputEvent) -> void:
	if not _can_move:
		return

	if event.is_action_pressed("interact") and not _nearby_npcs.is_empty():
		var npc = _nearby_npcs[0]
		if npc.has_method("interact"):
			_can_move = false
			npc.interact(self)

	if event.is_action_pressed("map_open"):
		SceneManager.goto_big_map()


func set_movement_enabled(enabled: bool) -> void:
	_can_move = enabled
	if not enabled:
		character.idle()


func _on_npc_entered(area: Area2D) -> void:
	var npc := area.get_parent()
	if npc.is_in_group("npcs") and npc not in _nearby_npcs:
		_nearby_npcs.append(npc)


func _on_npc_exited(area: Area2D) -> void:
	var npc := area.get_parent()
	_nearby_npcs.erase(npc)
