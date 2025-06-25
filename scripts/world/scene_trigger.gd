@tool
extends Area3D
class_name SceneTrigger

## Scene Trigger - Area3D that triggers scene transitions when player enters
## Place at doorways, exits, and transition points

# Target configuration
@export_category("Transition")
@export var target_location: SceneManagerClass.Location = SceneManagerClass.Location.COURTYARD
@export var target_spawn_point: String = "default"
@export var use_custom_path: bool = false
@export_file("*.tscn") var custom_scene_path: String = ""
@export var custom_location_name: String = ""

# Behavior
@export_category("Behavior")
@export var require_interaction: bool = false  ## If true, requires E key instead of auto-trigger
@export var one_way: bool = false  ## If true, only triggers when entering from one side
@export var trigger_delay: float = 0.1  ## Small delay to prevent accidental triggers

# Visual (editor only)
@export_category("Editor Visual")
@export var door_color: Color = Color(0.2, 0.6, 1.0, 0.5)

# State
var _player_in_area: bool = false
var _can_trigger: bool = true
var _player_ref: Node3D = null


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Set collision
	collision_layer = 0
	collision_mask = 2  # Player layer

	# Create collision shape if not present
	if get_child_count() == 0 or not has_node("CollisionShape3D"):
		_create_default_collision()


func _create_default_collision() -> void:
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2, 3, 1)
	collision.shape = box
	collision.name = "CollisionShape3D"
	add_child(collision)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Handle interaction-based triggers
	if require_interaction and _player_in_area and _can_trigger:
		if Input.is_action_just_pressed("interact"):
			_trigger_transition()


func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return

	if body.is_in_group("player") or body is PlayerController:
		_player_in_area = true
		_player_ref = body

		# Auto-trigger if not requiring interaction
		if not require_interaction and _can_trigger:
			# Small delay to prevent immediate re-triggers
			await get_tree().create_timer(trigger_delay).timeout
			if _player_in_area and _can_trigger:
				_trigger_transition()


func _on_body_exited(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return

	if body.is_in_group("player") or body is PlayerController:
		_player_in_area = false
		_player_ref = null


func _trigger_transition() -> void:
	if not _can_trigger:
		return

	_can_trigger = false

	# Get scene manager
	var scene_manager = get_node_or_null("/root/SceneManager")
	if not scene_manager:
		push_error("[SceneTrigger] SceneManager autoload not found!")
		_can_trigger = true
		return

	print("[SceneTrigger] Triggering transition to %s (spawn: %s)" % [
		SceneManagerClass.LOCATION_NAMES.get(target_location, custom_location_name),
		target_spawn_point
	])

	# Trigger the transition
	if use_custom_path and custom_scene_path != "":
		scene_manager.change_scene_path(custom_scene_path, custom_location_name, target_spawn_point)
	else:
		scene_manager.change_scene(target_location, target_spawn_point)


# Editor visualization
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if use_custom_path and custom_scene_path == "":
		warnings.append("Custom path enabled but no scene path set")

	var has_collision = false
	for child in get_children():
		if child is CollisionShape3D:
			has_collision = true
			break

	if not has_collision:
		warnings.append("No CollisionShape3D child - one will be created at runtime")

	return warnings
