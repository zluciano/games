extends Node2D
## NPC controller - idle/patrol behavior with dialog interaction.

@export var character_id: String = ""
@export var idle_direction: int = 0  # Direction enum: 0=S, 1=SW, 2=W, 3=NW, 4=N, 5=NE, 6=E, 7=SE
@export var patrol_points: Array[Vector2] = []
@export var patrol_speed: float = 30.0

var dialog_lines: Array = []
var _patrol_index: int = 0
var _is_patrolling: bool = false

@onready var character: Node2D = $OverworldCharacter
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	add_to_group("npcs")

	# Load sprite
	var sla_path := CharacterDB.get_sla_path(character_id)
	if not sla_path.is_empty():
		character.load_sprite(sla_path)

	character.idle(idle_direction)

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

	# Update sprite direction (8-way)
	var dir := character._vector_to_direction(direction)
	character.walk(dir)


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
