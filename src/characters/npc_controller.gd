extends Node2D
## NPC controller - idle/patrol behavior with dialog interaction.

@export var character_id: String = ""
@export var idle_direction: int = 0  # Legacy: 0=S, 1=N, 2=W, 3=E
@export var patrol_points: Array[Vector2] = []
@export var patrol_speed: float = 30.0

# Convert legacy 4-dir (0=down,1=up,2=left,3=right) to 8-dir enum
const LEGACY_DIR: Array[int] = [0, 4, 2, 6]  # S, N, W, E

var dialog_lines: Array = []
var _patrol_index: int = 0
var _is_patrolling: bool = false

@onready var character: Node2D = $OverworldCharacter
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	add_to_group("npcs")

	# Load both sprite sheets
	var sla_path := CharacterDB.get_sla_path(character_id)
	var ver_path := CharacterDB.get_ver_path(character_id)
	if not ver_path.is_empty() or not sla_path.is_empty():
		character.load_sprites(ver_path, sla_path)

	var dir8 := LEGACY_DIR[idle_direction] if idle_direction < LEGACY_DIR.size() else idle_direction
	character.idle(dir8)

	# Start patrol if points exist
	if patrol_points.size() > 1:
		_is_patrolling = true

	# Load dialog
	_load_dialog()


func _physics_process(delta: float) -> void:
	if not _is_patrolling or patrol_points.is_empty():
		return

	var target: Vector2 = patrol_points[_patrol_index]
	var delta_pos := target - position
	var distance := delta_pos.length()

	if distance < 2.0:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		return

	var direction := delta_pos.normalized()
	position += direction * patrol_speed * delta

	# 8-way direction from movement vector
	character.walk(character.vector_to_direction(direction))


func interact(player: Node2D) -> void:
	_is_patrolling = false
	character.face_towards(player.global_position)

	if dialog_lines.is_empty():
		# Generic greeting
		dialog_lines = [{
			"speaker": character_id,
			"expression": 0,
			"text": "Hey there!"
		}]

	# Find dialog box in the scene tree
	var dialog_box := _find_dialog_box()
	if dialog_box:
		dialog_box.start_dialog(dialog_lines)
		await dialog_box.dialog_finished
	player.set_movement_enabled(true)

	# Resume patrol
	if patrol_points.size() > 1:
		_is_patrolling = true
	else:
		character.idle(idle_direction)


func _load_dialog() -> void:
	# Load greetings from JSON
	var path := "res://data/dialog/npc_greetings.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var all_greetings: Dictionary = json.data
		var char_lines: Array = all_greetings.get(character_id, [])
		if not char_lines.is_empty():
			dialog_lines = char_lines
	file.close()


func _find_dialog_box() -> Node:
	var boxes := get_tree().get_nodes_in_group("dialog_box")
	if not boxes.is_empty():
		return boxes[0]
	return null
