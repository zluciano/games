extends CharacterBody3D
class_name PlayerController

## Player movement controller - Persona 5 style third-person movement
## Works with GDQuest Sophia character model

# Movement settings
@export_group("Movement")
@export var walk_speed: float = 7.0
@export var sprint_speed: float = 12.0
@export var acceleration: float = 10.0
@export var deceleration: float = 15.0
@export var rotation_speed: float = 10.0

# Physics
@export_group("Physics")
@export var gravity: float = 20.0
@export var jump_velocity: float = 5.0

# References (found dynamically for skin compatibility)
var skin: Node3D
var mesh: Node3D  # Alias for compatibility

# State
var current_speed: float = 0.0
var is_sprinting: bool = false
var input_direction: Vector2 = Vector2.ZERO
var movement_direction: Vector3 = Vector3.ZERO

# Camera reference (set by camera controller)
var camera_basis: Basis = Basis.IDENTITY


func _ready() -> void:
	# Find skin - try common names
	if has_node("SophiaSkin"):
		skin = $SophiaSkin
	elif has_node("JudaiSkin"):
		skin = $JudaiSkin
	else:
		# Find first Node3D child that looks like a skin (has idle/move methods)
		for child in get_children():
			if child is Node3D and (child.has_method("idle") or child.has_method("move")):
				skin = child
				break
	mesh = skin  # Alias for compatibility

	# Lock mouse for camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Add to player group for scene manager
	add_to_group("player")


func _physics_process(delta: float) -> void:
	# Don't process input during transitions or cutscenes
	if not _can_process_input():
		# Still apply gravity and idle animation
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.x = lerp(velocity.x, 0.0, deceleration * delta)
			velocity.z = lerp(velocity.z, 0.0, deceleration * delta)
			if skin.has_method("idle"):
				skin.idle()
		move_and_slide()
		return

	# Get input
	input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	is_sprinting = Input.is_action_pressed("sprint")

	# Calculate movement direction relative to camera
	var forward = -camera_basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = camera_basis.x
	right.y = 0
	right = right.normalized()

	movement_direction = (forward * -input_direction.y + right * input_direction.x).normalized()

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		# Fall animation
		if skin.has_method("fall"):
			skin.fall()

	# Handle movement
	if movement_direction != Vector3.ZERO:
		var target_speed = sprint_speed if is_sprinting else walk_speed
		current_speed = lerp(current_speed, target_speed, acceleration * delta)

		# Rotate skin to face movement direction
		var target_rotation = atan2(movement_direction.x, movement_direction.z)
		skin.rotation.y = lerp_angle(skin.rotation.y, target_rotation, rotation_speed * delta)

		# Apply horizontal velocity
		velocity.x = movement_direction.x * current_speed
		velocity.z = movement_direction.z * current_speed

		# Play move animation via Sophia skin
		if is_on_floor() and skin.has_method("move"):
			skin.move()
			# Set run tilt based on speed
			if skin.has_method("_set_run_tilt"):
				var tilt = 0.0
				var local_dir = skin.global_transform.basis.inverse() * movement_direction
				tilt = local_dir.x * 0.5
				skin.run_tilt = tilt
	else:
		# Decelerate
		current_speed = lerp(current_speed, 0.0, deceleration * delta)
		velocity.x = lerp(velocity.x, 0.0, deceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, deceleration * delta)

		# Idle animation
		if is_on_floor() and skin.has_method("idle"):
			skin.idle()

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse capture with Escape
	if event.is_action_pressed("pause_menu"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func set_camera_basis(basis: Basis) -> void:
	camera_basis = basis


func _can_process_input() -> bool:
	# Check if GameManager allows input
	if GameManager:
		var state = GameManager.current_state
		return state == GameManager.GameState.EXPLORATION
	return true
