extends Node2D
## Root controller for a location scene. Manages NPCs, exits, and player spawning.

@export var map_id: String = ""
@export var display_name: String = ""
@export var is_interior: bool = false

var _spawn_point: String = "default"

@onready var player: Node2D = $Player
@onready var location_label: Label = $UI/LocationLabel


func _ready() -> void:
	GameManager.change_state(GameManager.State.LOCATION)

	# Position player at spawn point
	_apply_spawn_point()

	# Show location name briefly
	if location_label:
		location_label.text = display_name
		location_label.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_interval(1.5)
		tween.tween_property(location_label, "modulate:a", 0.0, 0.5)


func set_spawn_point(point: String) -> void:
	_spawn_point = point


func _apply_spawn_point() -> void:
	# Default spawn points based on connection direction
	match _spawn_point:
		"default":
			player.position = Vector2(240, 180)
		_:
			# Try to find a Marker2D spawn point node
			var marker := find_child(_spawn_point)
			if marker:
				player.position = marker.position
			else:
				player.position = Vector2(240, 180)
