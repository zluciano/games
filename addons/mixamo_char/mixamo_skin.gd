extends Node3D

## Mixamo Character Skin Controller
## Animated humanoid with idle, walk, run animations
## Compatible interface with Sophia skin

@onready var animation_player: AnimationPlayer = null

var current_state: String = "idle"


func _ready() -> void:
	# Find animation player - could be direct child or nested in model
	animation_player = _find_animation_player(self)

	if animation_player:
		print("[MixamoSkin] Found AnimationPlayer with animations: ", animation_player.get_animation_list())
	else:
		print("[MixamoSkin] No AnimationPlayer found - model will be static")

	# Debug: Print model info
	_print_debug_info()

	idle()


func _print_debug_info() -> void:
	print("[MixamoSkin] Position: ", global_position)
	print("[MixamoSkin] Scale: ", scale)

	# Find any mesh instances and print their info
	var meshes = _find_all_meshes(self)
	print("[MixamoSkin] Found ", meshes.size(), " mesh instances")
	for mesh in meshes:
		if mesh is MeshInstance3D:
			print("  - Mesh: ", mesh.name, " visible: ", mesh.visible)
			if mesh.mesh:
				var aabb = mesh.mesh.get_aabb()
				print("    AABB size: ", aabb.size)


func _find_all_meshes(node: Node) -> Array:
	var result = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_meshes(child))
	return result


func _find_animation_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var found = _find_animation_player(child)
		if found:
			return found
	return null


func idle() -> void:
	if current_state != "idle":
		current_state = "idle"
		_play_animation_containing(["idle", "Idle", "IDLE", "stand", "Stand"])


func move() -> void:
	if current_state != "move":
		current_state = "move"
		_play_animation_containing(["walk", "Walk", "WALK", "run", "Run", "RUN", "locomotion"])


func fall() -> void:
	if current_state != "fall":
		current_state = "fall"
		_play_animation_containing(["fall", "Fall", "FALL", "Falling"])


func jump() -> void:
	if current_state != "jump":
		current_state = "jump"
		_play_animation_containing(["jump", "Jump", "JUMP"])


func _play_animation_containing(keywords: Array) -> void:
	if not animation_player:
		return

	var anims = animation_player.get_animation_list()

	# Try to find animation matching keywords
	for keyword in keywords:
		for anim in anims:
			if keyword in anim:
				animation_player.play(anim)
				return

	# If no matching animation found, try first one
	if anims.size() > 0:
		animation_player.play(anims[0])


# Compatibility with Sophia's run_tilt property
var run_tilt: float = 0.0:
	set(value):
		run_tilt = clamp(value, -1.0, 1.0)
