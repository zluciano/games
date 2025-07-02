@tool
extends Marker3D
class_name SpawnPoint

## Spawn Point - Marks where the player should spawn when entering a scene
## Add to "spawn_points" group automatically

@export var spawn_name: String = "default":
	set(value):
		spawn_name = value
		name = value if value != "" else "SpawnPoint"

@export var look_direction: float = 0.0:  ## Y rotation in degrees
	set(value):
		look_direction = value
		set_meta("look_direction", deg_to_rad(value))

# Editor visualization
@export var show_direction: bool = true
@export var gizmo_color: Color = Color(0.2, 0.8, 0.2, 0.8)


func _ready() -> void:
	add_to_group("spawn_points")
	set_meta("look_direction", deg_to_rad(look_direction))

	if Engine.is_editor_hint():
		return

	# Hide visual in game
	visible = false


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if spawn_name == "":
		warnings.append("Spawn point should have a name")

	return warnings
