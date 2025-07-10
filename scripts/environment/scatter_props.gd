@tool
class_name ScatterProps
extends Node3D

## Scatters props (flowers, bushes, rocks) around the scene

@export_category("Area")
@export var area_size: Vector2 = Vector2(80, 60)
@export var center_offset: Vector3 = Vector3.ZERO

@export_category("Props")
@export var prop_scenes: Array[PackedScene] = []
@export var prop_count: int = 100
@export var prop_scale_min: float = 0.8
@export var prop_scale_max: float = 1.5

@export_category("Distribution")
@export var exclude_center_radius: float = 10.0
@export var exclude_path_width: float = 12.0
@export var min_distance: float = 2.0
@export var random_seed: int = 54321

@export_category("Generation")
@export var regenerate: bool = false:
	set(value):
		if value:
			generate_props()
		regenerate = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		generate_props()

func generate_props() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()

	if prop_scenes.is_empty():
		push_warning("[ScatterProps] No prop scenes assigned")
		return

	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed

	var half_size = area_size / 2.0
	var placed_positions: Array[Vector3] = []
	var attempts = 0
	var max_attempts = prop_count * 10

	while placed_positions.size() < prop_count and attempts < max_attempts:
		attempts += 1

		var x = rng.randf_range(-half_size.x, half_size.x)
		var z = rng.randf_range(-half_size.y, half_size.y)
		var pos = Vector3(x, 0, z) + center_offset

		# Check exclusion zones
		if _is_excluded(x, z):
			continue

		# Check minimum distance from other props
		var too_close = false
		for existing_pos in placed_positions:
			if pos.distance_to(existing_pos) < min_distance:
				too_close = true
				break

		if too_close:
			continue

		# Place prop
		var prop_scene = prop_scenes[rng.randi() % prop_scenes.size()]
		if prop_scene:
			var instance = prop_scene.instantiate()
			add_child(instance)

			# Random transform
			var rot = rng.randf() * TAU
			var scale_val = rng.randf_range(prop_scale_min, prop_scale_max)

			instance.position = pos
			instance.rotation.y = rot
			instance.scale = Vector3.ONE * scale_val

			placed_positions.append(pos)

	print("[ScatterProps] Placed %d props" % placed_positions.size())

func _is_excluded(x: float, z: float) -> bool:
	# Exclude center area
	var dist_from_center = sqrt(x * x + z * z)
	if dist_from_center < exclude_center_radius:
		return true

	# Exclude main path
	if abs(x) < exclude_path_width / 2.0 and z > -5 and z < 50:
		return true

	# Exclude near building
	if z < 0 and abs(x) < 30:
		return true

	# Exclude hedges area
	if abs(x) > 14 and abs(x) < 24:
		return true

	return false
