extends Node3D
class_name ThirdPersonCamera

## Third-person camera controller - Persona 5 style orbiting camera

@export_group("Target")
@export var target: NodePath
@export var height_offset: float = 1.5

@export_group("Distance")
@export var min_distance: float = 2.0
@export var max_distance: float = 8.0
@export var default_distance: float = 5.0
@export var zoom_speed: float = 2.0

@export_group("Rotation")
@export var mouse_sensitivity: float = 0.003
@export var controller_sensitivity: float = 2.5
@export var min_pitch: float = -40.0
@export var max_pitch: float = 60.0
@export var rotation_smoothing: float = 15.0

@export_group("Collision")
@export var collision_margin: float = 0.3
@export var collision_mask: int = 1

# Internal state
var _target_node: Node3D
var _camera: Camera3D
var _spring_arm: SpringArm3D

var _yaw: float = 0.0
var _pitch: float = 15.0
var _current_distance: float = 5.0
var _target_distance: float = 5.0


func _ready() -> void:
	# Create camera setup first
	_setup_camera()

	_current_distance = default_distance
	_target_distance = default_distance

	# Get target - try NodePath first, then search for player group
	if target and has_node(target):
		_target_node = get_node(target)
	else:
		# Fallback: find player in group
		await get_tree().process_frame
		_find_player()


func _find_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player is Node3D:
		_target_node = player
		print("[ThirdPersonCamera] Found player: %s" % player.name)


## Set the camera target dynamically
func set_target(new_target: Node3D, reset_rotation: bool = true) -> void:
	_target_node = new_target

	if reset_rotation and new_target:
		# Reset camera to look at player from behind based on skin rotation
		var skin_rotation = 0.0
		if new_target.get("skin") and new_target.skin:
			skin_rotation = new_target.skin.rotation.y
		elif new_target.has_node("SophiaSkin"):
			skin_rotation = new_target.get_node("SophiaSkin").rotation.y
		elif new_target.has_node("JudaiSkin"):
			skin_rotation = new_target.get_node("JudaiSkin").rotation.y

		# Camera yaw should be behind player (skin rotation in degrees + 180)
		_yaw = rad_to_deg(skin_rotation) + 180.0
		_pitch = 15.0  # Reset to default pitch

	print("[ThirdPersonCamera] Target set to: %s, yaw: %s" % [new_target.name if new_target else "null", _yaw])


func _setup_camera() -> void:
	# Create spring arm for collision detection
	_spring_arm = SpringArm3D.new()
	_spring_arm.collision_mask = collision_mask
	_spring_arm.margin = collision_margin
	_spring_arm.spring_length = default_distance
	add_child(_spring_arm)

	# Create camera
	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 70.0
	_spring_arm.add_child(_camera)

	# Add post-process outline effect (anime-style black outlines)
	# DISABLED: The MeshInstance3D approach doesn't work correctly with Forward+ renderer
	# TODO: Implement using CompositorEffect or SubViewport for proper post-processing
	#_setup_outline_post_process()


func _process(delta: float) -> void:
	if not _target_node:
		return

	# Handle controller right stick look
	var look_input = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look_input != Vector2.ZERO:
		_yaw -= look_input.x * controller_sensitivity
		_pitch += look_input.y * controller_sensitivity  # Inverted Y axis
		_pitch = clamp(_pitch, min_pitch, max_pitch)

	# Follow target position
	var target_pos = _target_node.global_position + Vector3.UP * height_offset
	global_position = target_pos

	# Smooth distance changes
	_current_distance = lerp(_current_distance, _target_distance, zoom_speed * delta)
	_spring_arm.spring_length = _current_distance

	# Apply rotation
	rotation_degrees = Vector3(-_pitch, _yaw, 0)

	# Update player's camera reference
	if _target_node.has_method("set_camera_basis"):
		_target_node.set_camera_basis(global_transform.basis)


func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity * 100
		_pitch -= event.relative.y * mouse_sensitivity * 100
		_pitch = clamp(_pitch, min_pitch, max_pitch)

	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_distance = max(_target_distance - 0.5, min_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_distance = min(_target_distance + 0.5, max_distance)


func _setup_outline_post_process() -> void:
	# Load outline material
	var outline_material = load("res://materials/outline_post_process.tres")
	if not outline_material:
		push_warning("[ThirdPersonCamera] Could not load outline post-process material")
		return

	# Create fullscreen quad for post-processing
	var quad = MeshInstance3D.new()
	quad.name = "OutlinePostProcess"

	# Create 2x2 quad mesh (covers clip space)
	var mesh = QuadMesh.new()
	mesh.size = Vector2(2, 2)
	mesh.flip_faces = true  # Render on inside
	quad.mesh = mesh

	# Set extra cull margin to ensure it's always visible
	quad.extra_cull_margin = 16384.0

	# Apply outline material
	quad.material_override = outline_material

	# Add as child of camera
	_camera.add_child(quad)
