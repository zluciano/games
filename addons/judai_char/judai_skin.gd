extends Node3D

## Judai (Jaden) Character Skin Controller
## Animated character with idle, walk, run animations
## Compatible interface with Sophia skin

@onready var animation_player: AnimationPlayer = null
@onready var animation_tree: AnimationTree = null

var current_state: String = "idle"


func _ready() -> void:
	# Find animation player - could be direct child or nested in model
	animation_player = _find_node_of_type(self, "AnimationPlayer")
	animation_tree = _find_node_of_type(self, "AnimationTree")

	if animation_player:
		print("[JudaiSkin] Found AnimationPlayer with animations: ", animation_player.get_animation_list())
	else:
		print("[JudaiSkin] No AnimationPlayer found")

	if animation_tree:
		print("[JudaiSkin] Found AnimationTree")

	# Apply toon shader material to all meshes
	_apply_toon_material()

	# Debug: Print model info
	_print_debug_info()

	idle()


func _apply_toon_material() -> void:
	# Don't override the original materials - keep the character's textures
	# Just add a subtle outline via the CelShaderApplier in the scene
	print("[JudaiSkin] Keeping original character materials (no toon override)")

	# Per-character light (Guilty Gear technique)
	# This is the ONLY light that should affect the character significantly
	# Keep energy LOW - the shader handles most of the coloring
	var fill_light = OmniLight3D.new()
	fill_light.name = "CharacterFillLight"
	fill_light.light_color = Color(1.0, 0.98, 0.95)  # Slightly warm
	fill_light.light_energy = 0.25  # Low energy, just for subtle face fill
	fill_light.omni_range = 8.0  # Larger range for gradual falloff (no visible circle)
	fill_light.omni_attenuation = 2.0  # Faster falloff at distance
	fill_light.shadow_enabled = false
	fill_light.position = Vector3(0, 1.5, 0.8)  # Higher and more forward for face
	add_child(fill_light)
	print("[JudaiSkin] Added character fill light (energy: 0.25)")


func _print_debug_info() -> void:
	print("[JudaiSkin] Position: ", global_position)
	print("[JudaiSkin] Scale: ", scale)

	var meshes = _find_all_meshes(self)
	print("[JudaiSkin] Found ", meshes.size(), " mesh instances")
	for mesh in meshes:
		if mesh is MeshInstance3D:
			print("  - Mesh: ", mesh.name, " visible: ", mesh.visible)


func _find_all_meshes(node: Node) -> Array:
	var result = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_meshes(child))
	return result


func _find_node_of_type(node: Node, type_name: String):
	for child in node.get_children():
		if child.get_class() == type_name:
			return child
		var found = _find_node_of_type(child, type_name)
		if found:
			return found
	return null


func idle() -> void:
	if current_state != "idle":
		current_state = "idle"
		_play_animation_containing(["Idle", "idle", "IDLE", "stand", "Stand", "wait"])


func move() -> void:
	if current_state != "move":
		current_state = "move"
		_play_animation_containing(["Run", "run", "RUN", "Slow", "Walk", "walk", "locomotion", "move"])


func fall() -> void:
	if current_state != "fall":
		current_state = "fall"
		_play_animation_containing(["Fall", "fall", "FALL", "Falling", "falling"])


func jump() -> void:
	if current_state != "jump":
		current_state = "jump"
		_play_animation_containing(["Jump", "jump", "JUMP"])


func _play_animation_containing(keywords: Array) -> void:
	if not animation_player:
		return

	var anims = animation_player.get_animation_list()

	# Try to find animation matching keywords
	for keyword in keywords:
		for anim in anims:
			if keyword in anim:
				_play_looped(anim)
				return

	# If no matching animation found, try first non-RESET animation
	for anim in anims:
		if anim != "RESET":
			_play_looped(anim)
			return


func _play_looped(anim_name: String) -> void:
	# Get the animation and set it to loop
	var anim = animation_player.get_animation(anim_name)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR
	animation_player.play(anim_name)


# Compatibility with Sophia's run_tilt property
var run_tilt: float = 0.0:
	set(value):
		run_tilt = clamp(value, -1.0, 1.0)
