extends Node2D
## Player controller - input-driven movement using overworld character sprite.

const DEFAULT_SPRITE := "res://assets/tagforce/characters/sprites_sla/sd_boy_sla.png"

@export var speed: float = 60.0

var _can_move: bool = true
var _nearby_npcs: Array = []

@onready var character: Node2D = $OverworldCharacter
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	character.load_sprite(DEFAULT_SPRITE)
	character.idle(character.Direction.DOWN)

	interaction_area.area_entered.connect(_on_npc_entered)
	interaction_area.area_exited.connect(_on_npc_exited)


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

		# Determine facing direction
		if abs(input.x) > abs(input.y):
			character.walk(character.Direction.RIGHT if input.x > 0 else character.Direction.LEFT)
		else:
			character.walk(character.Direction.DOWN if input.y > 0 else character.Direction.UP)

		# Clamp to viewport
		position.x = clampf(position.x, 16, 464)
		position.y = clampf(position.y, 16, 256)
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
